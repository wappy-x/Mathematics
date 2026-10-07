// Brownian martingales -- the same check as brownian_martingales_and_exponential_martingale_check.py.
// Std only, no crates.  Walls at -2 and +3 micrometres, time in seconds, W_t has variance t.
// Roads: formulas; exact first-step equations on a lattice walk; Simpson on the
// reflection-principle density; a seeded simulation (SplitMix64 + Box-Muller).
use std::f64::consts::PI;

const A: f64 = 2.0;
const B: f64 = 3.0;
const LAM: f64 = 0.02;

fn lap(lam: f64) -> f64 {
    let th = (2.0 * lam).sqrt();
    (th * (B - A) / 2.0).cosh() / (th * (A + B) / 2.0).cosh()
}

// -(c/2) v[k-1] + v[k] - (c/2) v[k+1] = r for k = 1..K-1, v[0] = left, v[K] = right (Thomas)
fn tridiag(kk: usize, c: f64, r: f64, left: f64, right: f64) -> Vec<f64> {
    let (n, s) = (kk - 1, -c / 2.0);
    let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]);
    for i in 0..n {
        let d = r - if i == 0 { s * left } else { 0.0 } - if i == n - 1 { s * right } else { 0.0 };
        let den = 1.0 - if i > 0 { s * cp[i - 1] } else { 0.0 };
        cp[i] = s / den;
        dp[i] = (d - if i > 0 { s * dp[i - 1] } else { 0.0 }) / den;
    }
    let mut v = vec![0.0; n];
    v[n - 1] = dp[n - 1];
    for i in (0..n - 1).rev() { v[i] = dp[i] - cp[i] * v[i + 1]; }
    let mut out = vec![left];
    out.extend(v);
    out.push(right);
    out
}

fn lattice(h: f64) -> (f64, f64, f64, f64) {
    let (kk, k0, q) = (((A + B) / h).round() as usize, (A / h).round() as usize, (-LAM * h * h).exp());
    let side = tridiag(kk, 1.0, 0.0, 0.0, 1.0)[k0];
    let time = tridiag(kk, 1.0, h * h, 0.0, 0.0)[k0];
    let disc = tridiag(kk, q, 0.0, 1.0, 1.0)[k0];
    let k1 = ((100.0 + B) / h).round() as usize;
    let one = tridiag(k1, q, 0.0, 0.0, 1.0)[(100.0 / h).round() as usize];
    (side, time, disc, one)
}

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let w = (hi - lo) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * w); }
    (f(lo) + f(hi) + s) * w / 3.0
}

fn dens_u(u: f64, power: i32) -> f64 {   // t = e^u; t^power * density(t) * dt/du
    let t = u.exp();
    t.powi(power) * B / (2.0 * PI * t.powi(3)).sqrt() * (-B * B / (2.0 * t)).exp() * t
}

struct Rng { s: u64, spare: Option<f64> }
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 {
        if let Some(z) = self.spare.take() { return z; }
        let r = (-2.0 * (1.0 - self.u()).ln()).sqrt();
        let a = 2.0 * PI * self.u();
        self.spare = Some(r * a.sin());
        r * a.cos()
    }
}

fn simulate(dt: f64, paths: usize, seed: u64, th: f64) -> (Vec<f64>, Vec<f64>, Option<(Vec<f64>, f64)>) {
    let mut g = Rng { s: seed, spare: None };
    let (sd, every) = (dt.sqrt(), (0.25 / dt).round() as u64);
    let (mut s, mut q, mut pic) = (vec![0.0; 6], vec![0.0; 6], None);
    for _ in 0..paths {
        let (mut x, mut n, mut trace) = (0.0_f64, 0u64, vec![0.0]);
        while -A < x && x < B {
            x += sd * g.normal();
            n += 1;
            if n % every == 0 { trace.push(x); }
        }
        let tau = n as f64 * dt;
        let vals = [if x >= B { 1.0 } else { 0.0 }, tau, x, x * x - tau, (th * x - LAM * tau).exp(), (-LAM * tau).exp()];
        for i in 0..6 { s[i] += vals[i]; q[i] += vals[i] * vals[i]; }
        if pic.is_none() && (tau - 6.0).abs() <= 0.5 {
            if n % every != 0 { trace.push(x); }
            pic = Some((trace, tau));
        }
    }
    let m: Vec<f64> = s.iter().map(|v| v / paths as f64).collect();
    let se = (0..6).map(|i| ((q[i] / paths as f64 - m[i] * m[i]) / paths as f64).sqrt()).collect();
    (m, se, pic)
}

fn main() {
    let th = (2.0 * LAM).sqrt();
    let (p_right, mean_exit, lap_int, level) = (A / (A + B), A * B, lap(LAM), (-B * th).exp());
    let quad_level = simpson(|u| (-LAM * u.exp()).exp() * dens_u(u, 0), -6.0, 3000f64.ln(), 4000);
    let partial: Vec<(f64, f64)> = [1e2_f64, 1e4, 1e6].iter().map(|&t| (t, simpson(|u| dens_u(u, 1), -6.0, t.ln(), 4000))).collect();

    println!("walls -{:.0} and +{:.0} um, lambda {} per s, theta {:.4}", A, B, LAM, th);
    println!("formula   P(leave at +3) {:.6}   E[tau] {:.6}   E[e^-lam tau] {:.6}   level price {:.6}", p_right, mean_exit, lap_int, level);
    let (mid, half) = ((B - A) / 2.0, (A + B) / 2.0);
    println!("by hand   theta*{} = {:.1}, cosh {:.6}   theta*{} = {:.1}, cosh {:.6}", mid, th * mid, (th * mid).cosh(), half, th * half, (th * half).cosh());
    println!("lattice   h      P(+3)      E[tau]   E[e^-lam tau]       error  level price       error");
    let mut lat = vec![];
    for h in [1.0, 0.5, 0.25, 0.125, 0.0625] {
        let (s1, t1, d1, o1) = lattice(h);
        lat.push((s1, t1, d1, o1));
        println!("lattice {:6.4} {:10.6} {:10.6} {:12.6} {:+11.7} {:12.6} {:+11.7}", h, s1, t1, d1, d1 - lap_int, o1, o1 - level);
    }
    println!("Simpson on the first-passage density: level price {:.6}", quad_level);
    for (t, m) in &partial {
        println!("mean of tau_3 cut at {:9.0} s: {:10.2}   3 sqrt(2T/pi) - 9 = {:10.2}", t, m, B * (2.0 * t / PI).sqrt() - B * B);
    }
    println!("(1 - E[e^-lam tau]) / lam at lam = 1e-6: {:.4}", (1.0 - lap(1e-6)) / 1e-6);
    println!("wrong theta = sqrt(lam), no 1/2: level price {:.6}", (-B * LAM.sqrt()).exp());
    println!("wrong side b/(a+b): {:.6}", B / (A + B));
    println!("E[W_tau^2] = 0.4*9 + 0.6*4 = {:.6}", p_right * B * B + (1.0 - p_right) * A * A);
    for a in [2.0, 20.0, 200.0, 2000.0] {
        println!("left wall at -{:.0}: E[tau] = {:.0} s, P(+3 first) = {:.6}", a, a * B, a / (a + B));
    }
    let labels = ["P(leave at +3)", "E[tau]", "E[W_tau]", "E[W_tau^2 - tau]", "E[exp(th W - lam tau)]", "E[e^-lam tau]"];
    let mut pic = None;
    for (dt, paths) in [(0.04, 10000usize), (0.01, 10000)] {
        let (m, se, p) = simulate(dt, paths, 20260930, th);
        pic = p;
        println!("simulation dt {} s, {} paths, seed 20260930", dt, paths);
        for i in 0..6 { println!("  {:<24} {:10.4}  se {:.4}", labels[i], m[i], se[i]); }
        assert!(m[2].abs() < 4.0 * se[2], "W is fair at the grid exit time");
        assert!(m[3].abs() < 4.0 * se[3], "W^2 - t is fair at the grid exit time");
        assert!((m[4] - 1.0).abs() < 4.0 * se[4], "exponential martingale averages 1 at the grid exit time");
    }
    let (trace, tau) = pic.expect("a path near 6 s");   // first dt = 0.01 path leaving within 0.5 s of 6 s
    let ts: Vec<String> = (0..trace.len()).map(|i| format!("{:.2}", (0.25 * i as f64).min(tau))).collect();
    let ws: Vec<String> = trace.iter().map(|w| format!("{:.2}", w)).collect();
    println!("figure, t {}", ts.join(" "));
    println!("figure, W {}", ws.join(" "));

    let (s5, t5, d5, o5) = lat[4];
    assert!((s5 - p_right).abs() < 1e-9, "lattice side vs a/(a+b)");
    assert!((t5 - mean_exit).abs() < 1e-9, "lattice time vs ab");
    assert!((d5 - lap_int).abs() < 1e-5, "lattice discount vs cosh formula");
    assert!((lat[0].2 - lap_int).abs() > 100.0 * (d5 - lap_int).abs(), "lattice error shrinks like h^2");
    assert!((o5 - level).abs() < 1e-5, "lattice one-level price vs exp(-b sqrt(2 lam))");
    assert!((quad_level - level).abs() < 1e-6, "reflection density vs exponential martingale");
    assert!((partial[2].1 - (B * (2.0 * 1e6 / PI).sqrt() - B * B)).abs() < 0.1, "partial means grow like sqrt(T)");
    println!("ALL CHECKS PASS");
}
