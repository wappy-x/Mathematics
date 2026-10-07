// Rougher than Brownian: fractional Brownian motion and what breaks in Ito calculus.
// The same check as the Python, std only.  Log-volatility X_t = nu * B^H_t, time t
// in days, nu = 0.3, H = 0.1, volatility 20% * exp(X_t).  Roads: the formulas; exact
// sums over the covariance; seeded simulation by Davies-Harte (SplitMix64, seed
// 20260930, Box-Muller, own FFT), with standard errors.
use std::f64::consts::PI;

struct Rng { state: u64, spare: Option<f64> }

impl Rng {
    fn uniform(&mut self) -> f64 {      // SplitMix64 -> a number in (0, 1]
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {       // Box-Muller, both values of each pair used
        if let Some(z) = self.spare.take() { return z; }
        let r = (-2.0 * self.uniform().ln()).sqrt();
        let th = 2.0 * PI * self.uniform();
        self.spare = Some(r * th.sin());
        r * th.cos()
    }
}

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }           // a complex number, by hand

fn mul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }

fn total(xs: &[f64]) -> f64 { let mut s = 0.0; for x in xs { s += x; } s }

fn gam(k: i64, h: f64) -> f64 {         // covariance of unit-step increments k steps apart
    let k = k.abs() as f64;
    0.5 * ((k + 1.0).powf(2.0 * h) - 2.0 * k.powf(2.0 * h) + (k - 1.0).abs().powf(2.0 * h))
}

fn fft(a: &[C]) -> Vec<C> {             // radix-2 Fourier transform, written out
    let n = a.len();
    if n == 1 { return a.to_vec(); }
    let ev = fft(&a.iter().step_by(2).copied().collect::<Vec<C>>());
    let od = fft(&a.iter().skip(1).step_by(2).copied().collect::<Vec<C>>());
    let mut out = vec![C { re: 0.0, im: 0.0 }; n];
    for k in 0..n / 2 {
        let ang = 2.0 * PI * k as f64 / n as f64;
        let t = mul(C { re: ang.cos(), im: -ang.sin() }, od[k]);
        out[k] = C { re: ev[k].re + t.re, im: ev[k].im + t.im };
        out[k + n / 2] = C { re: ev[k].re - t.re, im: ev[k].im - t.im };
    }
    out
}

fn eigen(n: usize, h: f64) -> Vec<f64> { // circulant embedding of the covariance
    let mut c: Vec<f64> = (0..=n as i64).map(|k| gam(k, h)).collect();
    c.extend((1..n as i64).rev().map(|k| gam(k, h)));
    fft(&c.iter().map(|&x| C { re: x, im: 0.0 }).collect::<Vec<C>>()).iter().map(|z| z.re).collect()
}

fn fgn(n: usize, lam: &[f64], rng: &mut Rng) -> Vec<f64> { // Davies-Harte increments
    let m = 2 * n;
    let mut w = vec![C { re: 0.0, im: 0.0 }; m];
    w[0] = C { re: (lam[0] / m as f64).sqrt() * rng.normal(), im: 0.0 };
    w[n] = C { re: (lam[n] / m as f64).sqrt() * rng.normal(), im: 0.0 };
    for j in 1..n {
        let s = (lam[j] / (2 * m) as f64).sqrt();
        let a = s * rng.normal();
        w[j] = C { re: a, im: s * rng.normal() };
        w[m - j] = C { re: w[j].re, im: -w[j].im };
    }
    fft(&w)[..n].iter().map(|z| z.re).collect()
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = total(xs) / n;
    let v: Vec<f64> = xs.iter().map(|x| (x - m) * (x - m)).collect();
    (m, (total(&v) / (n - 1.0) / n).sqrt())
}

fn join(xs: &[f64], f: &dyn Fn(f64) -> String) -> String {
    xs.iter().map(|&x| f(x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let mut rng = Rng { state: 20260930, spare: None };
    let (hh, nu, t, n) = (0.1f64, 0.3f64, 64.0f64, 1024usize); let h = t / n as f64; // grid 1/16 day
    println!("log-vol X_t = 0.3 B^H_t, t in days, H = 0.1; SplitMix64 seed 20260930");
    println!("increment correlation rho(n), n = 1 2 4 16:");
    for hv in [0.1f64, 0.5, 0.7] {
        let r: Vec<f64> = [1i64, 2, 4, 16].iter().map(|&k| gam(k, hv)).collect();
        println!("  H = {}: {}", hv, join(&r, &|x| format!("{:+.4}", x)));
    }
    println!("H = 1.2 would need rho(1) = {:.4}, above 1: impossible", gam(1, 1.2));
    println!("share of the next step forecast by the last one, rho(1)^2: {:.4}", gam(1, hh).powi(2));
    let days = [1.0f64, 32.0, 1024.0];
    println!("sd of X over 1, 32, 1024 days, rough: {}; Brownian, same daily size: {}",
             join(&days, &|d| format!("{:.4}", nu * d.powf(hh))), join(&days, &|d| format!("{:.4}", nu * d.powf(0.5))));
    println!("hand: 2^0.2 {:.4}, 64^0.2 {:.4}, 16^0.8 {:.4}; vol from 20% after one sd: 1 day up {:.2} down {:.2}, 1024 days up {:.2}",
             2f64.powf(0.2), 64f64.powf(0.2), 16f64.powf(0.8), 20.0 * nu.exp(), 20.0 * (-nu).exp(), 20.0 * (2.0 * nu).exp());
    let cells: Vec<f64> = (0..64i64).flat_map(|i| (0..64i64).map(move |j| gam(i - j, 0.1))).collect();
    let dbl = total(&cells);
    println!("exact: double sum of rho over 64 steps {:.10}, formula 64^(2H) {:.10}", dbl, 64f64.powf(2.0 * hh));
    let lam = eigen(n, hh);
    let lmin = lam.iter().cloned().fold(f64::INFINITY, f64::min);
    println!("exact: smallest circulant eigenvalue {:.6} (must be >= 0)", lmin);
    assert!((dbl - 64f64.powf(2.0 * hh)).abs() < 1e-9, "covariance sums do not rebuild the variance law");
    assert!(lmin > 0.0, "embedding not valid");

    let m_paths = 1000;
    let (mut lag1, mut lag2, mut xt2, mut lft, mut rgt, mut hest) = (vec![], vec![], vec![], vec![], vec![], vec![]);
    let mut qv: Vec<Vec<f64>> = vec![vec![], vec![], vec![]]; // f = 1, 4, 16 fine steps
    let (fs, mut path_r) = ([1usize, 4, 16], vec![]);
    for p in 0..m_paths {
        let g = fgn(n, &lam, &mut rng);
        lag1.push(total(&(0..n - 1).map(|i| g[i] * g[i + 1]).collect::<Vec<_>>()) / (n - 1) as f64);
        lag2.push(total(&(0..n - 2).map(|i| g[i] * g[i + 2]).collect::<Vec<_>>()) / (n - 2) as f64);
        let mut x = vec![0.0f64];
        for v in &g { let last = *x.last().unwrap(); x.push(last + nu * h.powf(hh) * v); }
        let dx: Vec<f64> = (0..n).map(|i| x[i + 1] - x[i]).collect();
        xt2.push(x[n].powi(2));
        for (q, &f) in qv.iter_mut().zip(&fs) {
            q.push(total(&(0..n).step_by(f).map(|i| (x[i + f] - x[i]).powi(2)).collect::<Vec<_>>()));
        }
        lft.push(total(&(0..n).map(|i| x[i] * dx[i]).collect::<Vec<_>>()));
        rgt.push(total(&(0..n).map(|i| x[i + 1] * dx[i]).collect::<Vec<_>>()));
        let (mut lx, mut ly) = (vec![], vec![]);
        for e in 0..5 {                 // lags 1/16 day up to 1 day
            let k = 1usize << e;
            lx.push((k as f64 * h).ln());
            ly.push((total(&(0..n - k).map(|i| (x[i + k] - x[i]).powi(2)).collect::<Vec<_>>()) / (n - k) as f64).ln());
        }
        let (mx, my) = (total(&lx) / 5.0, total(&ly) / 5.0);
        let num: Vec<f64> = lx.iter().zip(&ly).map(|(a, b)| (a - mx) * (b - my)).collect();
        let den: Vec<f64> = lx.iter().map(|a| (a - mx).powi(2)).collect();
        hest.push(total(&num) / total(&den) / 2.0);
        if p == 0 { path_r = (0..33).map(|i| 20.0 * x[32 * i].exp()).collect(); }
    }

    println!("-- simulation, {} paths, 64 days, grid 1/16 day --", m_paths);
    let qf = |f: usize| nu * nu * t * (f as f64 * h).powf(2.0 * hh - 1.0);
    let rows: Vec<(&str, &Vec<f64>, f64)> = vec![
        ("rho(1)", &lag1, gam(1, hh)), ("rho(2)", &lag2, gam(2, hh)), ("E X_64^2", &xt2, nu * nu * t.powf(2.0 * hh)),
        ("sum dX^2, step 1 day", &qv[2], qf(16)), ("sum dX^2, step 1/4 day", &qv[1], qf(4)),
        ("sum dX^2, step 1/16 day", &qv[0], qf(1)),
        ("left-point sum", &lft, 0.5 * nu * nu * (t.powf(2.0 * hh) - t * h.powf(2.0 * hh - 1.0))),
        ("right-point sum", &rgt, 0.5 * nu * nu * (t.powf(2.0 * hh) + t * h.powf(2.0 * hh - 1.0))),
        ("H fitted per path", &hest, hh)];
    for (lab, xs, fm) in &rows {
        let (m, se) = mean_se(xs);
        println!("{:<22} sim {:9.4} +- {:7.4}   formula {:9.4}", lab, m, se, fm);
        assert!((m - fm).abs() < 4.0 * se + if lab.starts_with('H') { 0.005 } else { 0.0 }, "{}", lab); // the fit's log bias
    }
    println!("sum dX^2 by step, Brownian with the same daily size: {}", join(&[0.0; 3], &|_| format!("{:.4}", nu * nu * t)));

    // ---- Brownian with the same 64-day spread, for the picture: nu_B = 0.3 * 64^0.1 / 8 ----
    let nub = nu * t.powf(hh) / t.sqrt();
    let gb = fgn(n, &eigen(n, 0.5), &mut rng);
    let mut xb = vec![0.0f64];
    for v in &gb { let last = *xb.last().unwrap(); xb.push(last + nub * h.sqrt() * v); }
    println!("Brownian nu matched over 64 days: {:.4} per root day; daily sd ratio {:.4}", nub, nu / nub);
    println!("chart, day          {}", (0..33).map(|i| format!("{}", 2 * i)).collect::<Vec<_>>().join(" "));
    println!("chart, rough vol %  {}", join(&path_r, &|v| format!("{:.2}", v)));
    let vb: Vec<f64> = (0..33).map(|i| 20.0 * xb[32 * i].exp()).collect();
    println!("chart, Brownian %   {}", join(&vb, &|v| format!("{:.2}", v)));
    println!("chart, sum dX^2 sim {}", join(&[2usize, 1, 0].iter().map(|&i| mean_se(&qv[i]).0).collect::<Vec<_>>(), &|v| format!("{:.2}", v)));
    println!("chart, formula      {}", join(&[16usize, 4, 1].iter().map(|&f| qf(f)).collect::<Vec<_>>(), &|v| format!("{:.2}", v)));
    println!("ALL CHECKS PASS");
}
