// GARCH and volatility clustering -- the same check as the Python, in Rust.  No
// crates.  Returns are in percent a day, variances in percent-squared.  The share
// is simulated from a known GARCH(1,1), so every fitted number can be graded.
use std::f64::consts::PI;
const W: f64 = 0.05; const A: f64 = 0.08; const B: f64 = 0.90; const N: usize = 2500;
struct SplitMix64 { s: u64 }                  // random numbers, same in both languages
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {             // Box-Muller, the cosine half only
        let u1 = 1.0 - self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn path(sq: &[f64], s2: f64, w: f64, a: f64, b: f64) -> Vec<f64> {   // h_1 .. h_{N+1}
    let mut hs = vec![s2];
    for x2 in sq { let last = hs[hs.len() - 1]; hs.push(w + a * x2 + b * last); }
    hs
}
fn loglik(sq: &[f64], s2: f64, p: &[f64]) -> f64 {   // Gaussian log-likelihood of all N days
    let (w, a, b) = (p[0], p[1], p[2]);
    if w < 0.0 || a < 0.0 || b < 0.0 || a + b > 1.0 { return -1e300; }
    let (hs, mut s) = (path(sq, s2, w, a, b), 0.0);
    for t in 0..sq.len() { s += (2.0 * PI * hs[t]).ln() + sq[t] / hs[t]; }
    -0.5 * s
}
fn nelder_mead(f: &dyn Fn(&[f64]) -> f64, x0: [f64; 3], step: f64) -> ([f64; 3], f64) {
    let mut pts = vec![x0; 4];
    for i in 0..3 { pts[i + 1][i] += step; }
    let mut val: Vec<f64> = pts.iter().map(|p| f(p)).collect();
    for _ in 0..600 {
        let mut o: Vec<usize> = (0..4).collect();
        o.sort_by(|&i, &j| val[j].partial_cmp(&val[i]).unwrap());
        pts = o.iter().map(|&i| pts[i]).collect(); val = o.iter().map(|&i| val[i]).collect();
        let (mut c, p3) = ([0.0; 3], pts[3]);
        for j in 0..3 { c[j] = (pts[0][j] + pts[1][j] + pts[2][j]) / 3.0; }
        let mv = |k: f64| { let mut x = [0.0; 3]; for j in 0..3 { x[j] = c[j] + k * (p3[j] - c[j]); } x };
        let xr = mv(-1.0); let fr = f(&xr);
        if fr > val[0] {
            let xe = mv(-2.0); let fe = f(&xe);
            if fe > fr { pts[3] = xe; val[3] = fe; } else { pts[3] = xr; val[3] = fr; }
        } else if fr > val[2] { pts[3] = xr; val[3] = fr; }
        else {
            let xc = mv(0.5); let fc = f(&xc);
            if fc > val[3] { pts[3] = xc; val[3] = fc; }
            else {                            // shrink everything towards the best point
                for i in 1..4 { for j in 0..3 { pts[i][j] = (pts[0][j] + pts[i][j]) / 2.0; } val[i] = f(&pts[i]); }
            }
        }
    }
    (pts[0], val[0])
}
fn acf(xs: &[f64], k: usize) -> f64 {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    let dv: Vec<f64> = xs.iter().map(|x| x - m).collect();
    let mut num = 0.0; for i in k..dv.len() { num += dv[i] * dv[i - k]; }
    num / dv.iter().map(|v| v * v).sum::<f64>()
}
fn pr<T>(lab: &str, xs: &[T], f: &dyn Fn(&T) -> String) {
    println!("{:<29}{}", lab, xs.iter().map(|v| f(v)).collect::<String>());
}
fn main() {
    let mut rng = SplitMix64 { s: 2026 };
    let (mut h, mut r) = (W / (1.0 - A - B), Vec::new());
    for t in 0..250 + N {                     // road one: simulate; 250 warm-up days dropped
        let x = h.sqrt() * rng.normal();
        if t >= 250 { r.push(x); }
        h = W + A * x * x + B * h;
    }
    let sq: Vec<f64> = r.iter().map(|x| x * x).collect(); let s2 = sq.iter().sum::<f64>() / N as f64;   // variance about zero; also the seed h_1
    let ll = |p: &[f64]| loglik(&sq, s2, p);
    let (est, ll_g) = nelder_mead(&ll, [0.1, 0.1, 0.8], 0.05);
    let (w, a, b) = (est[0], est[1], est[2]); let phi = a + b; let lr = w / (1.0 - phi);
    let d: Vec<f64> = est.iter().map(|v| 1e-3 * v).collect();   // curvature of the peak
    let bump = |i: usize, j: usize, si: f64, sj: f64| { let mut q = est; q[i] += si * d[i]; q[j] += sj * d[j]; ll(&q) };
    let mut hm = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 {
        hm[i][j] = -(bump(i, j, 1.0, 1.0) - bump(i, j, 1.0, -1.0) - bump(i, j, -1.0, 1.0) + bump(i, j, -1.0, -1.0)) / (4.0 * d[i] * d[j]);
    } }
    let mut det = 0.0;
    for j in 0..3 { det += hm[0][j] * (hm[1][(j + 1) % 3] * hm[2][(j + 2) % 3] - hm[1][(j + 2) % 3] * hm[2][(j + 1) % 3]); }
    let mut v = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 {
        v[i][j] = (hm[(j + 1) % 3][(i + 1) % 3] * hm[(j + 2) % 3][(i + 2) % 3] - hm[(j + 1) % 3][(i + 2) % 3] * hm[(j + 2) % 3][(i + 1) % 3]) / det;
    } }
    let (se, se_phi): (Vec<f64>, f64) = ((0..3).map(|i| v[i][i].sqrt()).collect(), (v[1][1] + v[2][2] + 2.0 * v[1][2]).sqrt());
    let g = [1.0 / (1.0 - phi), lr / (1.0 - phi), lr / (1.0 - phi)];   // delta method
    let mut s = 0.0; for i in 0..3 { for j in 0..3 { s += g[i] * v[i][j] * g[j]; } } let se_lr = s.sqrt();
    let mut grid = (f64::NEG_INFINITY, 0.0, 0.0);   // road two: a grid, omega pinned by S2
    for i in 1..21 { for j in 0..30 {
        let (ga, gb) = (0.01 * i as f64, 0.70 + 0.01 * j as f64);
        if ga + gb < 1.0 { let l = ll(&[s2 * (1.0 - ga - gb), ga, gb]); if l > grid.0 { grid = (l, ga, gb); } }
    } }
    let ll_e = |lam: f64| ll(&[0.0, 1.0 - lam, lam]);   // EWMA's one knob, by golden section
    let (mut lo, mut hi) = (0.80, 0.999);
    for _ in 0..60 {
        let (m1, m2) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if ll_e(m1) < ll_e(m2) { lo = m1; } else { hi = m2; }
    }
    let lam = (lo + hi) / 2.0; let se_lam = (-1e-6 / (ll_e(lam + 1e-3) - 2.0 * ll_e(lam) + ll_e(lam - 1e-3))).sqrt();
    let ll_c = -0.5 * N as f64 * ((2.0 * PI * s2).ln() + 1.0);
    let mut shuf = sq.clone();
    for i in (1..N).rev() { let j = (rng.uniform() * (i + 1) as f64) as usize; shuf.swap(i, j); }
    let rho1 = a * (1.0 - a * b - b * b) / (1.0 - 2.0 * a * b - b * b);
    let psi: Vec<f64> = (0..4001).map(|j| if j == 0 { 1.0 } else { (phi - b) * phi.powf((j - 1) as f64) }).collect();
    let rho1_w = psi.windows(2).map(|p| p[0] * p[1]).sum::<f64>() / psi.iter().map(|p| p * p).sum::<f64>();
    let (hs, ew) = (path(&sq, s2, w, a, b), path(&sq, s2, 0.0, 1.0 - lam, lam));
    let fc = |h1: f64, k: usize| lr + phi.powf((k - 1) as f64) * (h1 - lr);   // the forecast formula
    let mut monte_carlo = |h1: f64, k: usize| {   // road three: simulate the future instead
        let (mut tot, mut tot2) = (0.0, 0.0);
        for _ in 0..20000 {
            let mut hh = h1;
            for _ in 0..k - 1 { let z = rng.normal(); hh = w + a * hh * z * z + b * hh; }
            tot += hh; tot2 += hh * hh;
        }
        (tot / 20000.0, ((tot2 / 20000.0 - (tot / 20000.0).powf(2.0)) / 20000.0).sqrt())
    };
    let weekly = |v: &[f64]| -> Vec<f64> { (0..N / 5).map(|i| (v[5 * i..5 * i + 5].iter().sum::<f64>() / 5.0).sqrt()).collect() };
    let (wk, wg) = (weekly(&sq), weekly(&hs));
    let mut top = 0; for i in 0..wk.len() { if wk[i] > wk[top] { top = i; } } let mut storm = 1; for t in 1..N + 1 { if hs[t] > hs[storm] { storm = t; } }   // evening of day t
    let hstorm = hs[storm]; let ks: Vec<usize> = std::iter::once(1).chain((10..130).step_by(10)).collect();
    let var20: f64 = (1..21).map(|k| fc(hstorm, k)).sum();
    let (mc5, mc20) = (monte_carlo(hstorm, 5), monte_carlo(hstorm, 20)); let hand = W + A * 36.0 + B * 2.5;   // by hand: a -6% day, long-run level
    let f2 = |x: &f64| format!("{:6.2}", x); let fd = |x: &usize| format!("{:6}", x);
    let lags: Vec<usize> = (1..11).collect();
    println!("share: {} days, seed 2026; true omega {:.2}, alpha {:.2}, beta {:.2}", N, W, A, B);
    println!("variance of returns {:.4}; daily vol {:.4}%; no-correlation band 2/sqrt(N) {:.4}", s2, s2.sqrt(), 2.0 / (N as f64).sqrt());
    pr("lag", &lags, &fd);
    pr("chart, acf of returns", &lags.iter().map(|&k| acf(&r, k)).collect::<Vec<_>>(), &f2);
    pr("chart, acf of squares", &lags.iter().map(|&k| acf(&sq, k)).collect::<Vec<_>>(), &f2);
    pr("chart, acf squares, model", &lags.iter().map(|&k| rho1 * phi.powf((k - 1) as f64)).collect::<Vec<_>>(), &f2);
    println!("rho_1 of squares: formula {:.6}, from the ARMA(1,1) weights {:.6}", rho1, rho1_w);
    pr("acf squares, days shuffled", &lags.iter().map(|&k| acf(&shuf, k)).collect::<Vec<_>>(), &f2);
    println!("GARCH fit: omega {:.4} (se {:.4}), alpha {:.4} (se {:.4}), beta {:.4} (se {:.4})", w, se[0], a, se[1], b, se[2]);
    println!("persistence {:.4} (se {:.4}); half-life {:.1} days, {:.1} to {:.1} at 2 se", phi, se_phi, 0.5f64.ln() / phi.ln(),
             0.5f64.ln() / (phi - 2.0 * se_phi).ln(), 0.5f64.ln() / (phi + 2.0 * se_phi).ln());
    println!("long-run variance {:.4} (se {:.4}); long-run vol {:.4}%", lr, se_lr, lr.sqrt());
    println!("grid, omega pinned: alpha {:.2}, beta {:.2}, log-likelihood {:.2}", grid.1, grid.2, grid.0);
    println!("EWMA fit: lambda {:.4} (se {:.4})", lam, se_lam);
    let ll_t = ll(&[W, A, B]);
    println!("log-likelihood: constant {:.2}, EWMA {:.2}, GARCH {:.2}, GARCH at the truth {:.2}", ll_c, ll_e(lam), ll_g, ll_t);
    println!("GARCH gain over constant {:.2}, over EWMA {:.2}", ll_g - ll_c, ll_g - ll_e(lam));
    pr("chart, week", &(top - 9..top + 21).collect::<Vec<_>>(), &fd);
    pr("chart, weekly rms return %", &wk[top - 10..top + 20], &f2);
    pr("chart, weekly GARCH vol %", &wg[top - 10..top + 20], &f2);
    println!("storm: evening of day {}, GARCH h {:.4}, EWMA h {:.4}", storm, hstorm, ew[storm]);
    pr("days ahead k", &ks, &fd);
    pr("chart, storm GARCH vol %", &ks.iter().map(|&k| fc(hstorm, k).sqrt()).collect::<Vec<_>>(), &f2);
    pr("chart, storm EWMA vol %", &vec![ew[storm].sqrt(); ks.len()], &f2);
    pr("chart, long-run vol %", &vec![lr.sqrt(); ks.len()], &f2);
    println!("storm k=5: formula {:.4}, simulated {:.4} (se {:.4})", fc(hstorm, 5), mc5.0, mc5.1);
    println!("storm k=20: formula {:.4}, simulated {:.4} (se {:.4})", fc(hstorm, 20), mc20.0, mc20.1);
    println!("storm 20-day vol: sum of forecasts {:.2}%, with no pull home {:.2}%", var20.sqrt(), (20.0 * hstorm).sqrt());
    println!("end of sample: GARCH h {:.4} -> k=20 {:.4}; EWMA h {:.4}", hs[N], fc(hs[N], 20), ew[N]);
    println!("hand: h after a -6% day {:.4}; k=10 {:.4}; half-life {:.1} days; that day's log-lik term {:.4}",
             hand, W / (1.0 - A - B) + (A + B).powf(9.0) * (hand - 2.5), 0.5f64.ln() / (A + B).ln(), -0.5 * ((2.0 * PI * 2.5).ln() + 36.0 / 2.5));
    println!("break: decay by beta alone, storm k=20: {:.4}", lr + b.powf(19.0) * (hstorm - lr));
    assert!((0..3).all(|i| (est[i] - [W, A, B][i]).abs() < 3.0 * se[i]));   // the truth is inside
    assert!((grid.1 - a).abs() < 0.02 && (grid.2 - b).abs() < 0.02 && grid.0 <= ll_g);   // two fits agree
    assert!(ll_c <= ll_e(lam) && ll_e(lam) <= ll_g && ll_t <= ll_g);   // the peak beats its nested rivals
    assert!(ll_e(lam) >= ll_e(lam - 0.01).max(ll_e(lam + 0.01)));       // and EWMA's peak its neighbours
    assert!((fc(hstorm, 5) - mc5.0).abs() < 4.0 * mc5.1 && (fc(hstorm, 20) - mc20.0).abs() < 4.0 * mc20.1);
    assert!(acf(&sq, 1) > 4.0 / (N as f64).sqrt() && (acf(&sq, 1) - rho1).abs() < 4.0 / (N as f64).sqrt() && [&r, &shuf].iter().all(|v| (1..11).all(|k| acf(v, k).abs() < 4.0 / (N as f64).sqrt())));
    assert!((rho1_w - rho1).abs() < 1e-9);   // Step 4's rho_1 against the squares' ARMA(1,1) as weights on past surprises
    println!("ALL CHECKS PASS");
}
