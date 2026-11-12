// Newton's bad days: the same check as the Python, in Rust.  No crates.
// A triple root (x^3) slows Newton to a crawl; arctan makes it overshoot, cycle and
// run away.  Diagnose, cure, damp, and test the conditions that guarantee convergence.
fn sci(v: f64) -> String { format!("{:.2e}", v) }          // 1.23e-10
fn fx(v: f64) -> String { if v.abs() < 1000.0 { format!("{:.3}", v) } else { sci(v) } }
fn newton(f: &dyn Fn(f64) -> f64, df: &dyn Fn(f64) -> f64, x: f64, steps: usize, m: f64) -> Vec<f64> {
    let mut xs = vec![x];                                  // m = 1 plain; m > 1 modified
    for _ in 0..steps {
        let x = xs[xs.len() - 1];
        if f(x) == 0.0 { break }
        xs.push(x - m * f(x) / df(x));
    }
    xs
}
fn nstep(x: f64) -> f64 { x - (1.0 + x * x) * x.atan() }    // Newton's step on arctan
fn cyc(x: f64) -> f64 { (1.0 + x * x) * x.atan() - 2.0 * x } // zero where N(x) = -x
fn damped(mut x: f64, c1: f64) -> Vec<(f64, f64)> {        // backtracking on |f|
    let mut path = vec![];
    while x.atan().abs() > 1e-15 && path.len() < 50 {
        let (d, mut lam) = (-(1.0 + x * x) * x.atan(), 1.0f64);
        while (x + lam * d).atan().abs() > (1.0 - c1 * lam) * x.atan().abs() { lam /= 2.0; }
        x += lam * d;
        path.push((lam, x));
    }
    path
}
fn main() {
    let (cube, dcube) = (|x: f64| x * x * x, |x: f64| 3.0 * x * x);
    let xs = newton(&cube, &dcube, 1.0, 60, 1.0);
    let k9 = xs.iter().position(|x| x.abs() < 1e-9).unwrap();
    println!("1. Newton on f(x) = x^3 from 1 (root 0, slope 0 there)");
    for k in [0, 1, 2, 3, 10, k9 - 1, k9] {
        let q = if k > 0 { format!("{:.6}", xs[k] / xs[k - 1]) } else { "-".to_string() };
        println!("   k = {:2}  x_k = error = {}  ratio e_k/e_(k-1) = {}", k, sci(xs[k]), q);
    }
    let mut cf = vec![1.0f64];                              // road two: (2/3)^k by multiplication
    for _ in 0..k9 { let v = cf[cf.len() - 1] * (2.0 / 3.0); cf.push(v); }
    let gap = (0..=k9).map(|k| (xs[k] / cf[k] - 1.0).abs()).fold(0.0, f64::max);
    let kf = (9.0 / 1.5f64.log10()).ceil() as usize;
    println!("   closed form x_k = (2/3)^k: largest relative gap {}", sci(gap));
    println!("   steps to error < 1e-9: run {}, formula ceil(9/log10(1.5)) = {}, {:.3} digits a step", k9, kf, 1.5f64.log10());
    assert!(k9 == kf && gap < 1e-14);
    assert!((0..k9).all(|k| 0.0 < xs[k + 1] && xs[k + 1] < xs[k]));   // monotone
    let q = xs[k9] / xs[k9 - 1];
    println!("   multiplicity read off the ratio: m = 1/(1 - q) = {:.4}", 1.0 / (1.0 - q));
    assert!((1.0 / (1.0 - q) - 3.0).abs() < 1e-9);
    println!("   last step {}, true error after it {}: error = 2 x step", sci(xs[k9 - 1] - xs[k9]), sci(xs[k9]));
    let mx = newton(&cube, &dcube, 1.0, 5, 3.0);
    println!("2. modified Newton, 3 f/f', on x^3 from 1: x_1 = {}, done in {} step", sci(mx[1]), mx.len() - 1);
    assert!(mx == vec![1.0, 0.0]);
    let m2 = newton(&cube, &dcube, 1.0, 60, 2.0);          // too small an m: still linear
    let k2 = m2.iter().position(|x| x.abs() < 1e-9).unwrap();
    println!("   with m = 2 instead: ratio {:.6}, {} steps to error < 1e-9", m2[1] / m2[0], k2);
    assert!(k2 == (9.0 / 3f64.log10()).ceil() as usize);
    let (g, dg) = (|x: f64| x.powi(3) + x.powi(4), |x: f64| 3.0 * x * x + 4.0 * x.powi(3));
    let (gp, gm) = (newton(&g, &dg, 1.0, 80, 1.0), newton(&g, &dg, 1.0, 6, 3.0));
    let kp = gp.iter().position(|x| x.abs() < 1e-9).unwrap();
    println!("   on x^3 + x^4 from 1: plain Newton {} steps, last ratio {:.4}", kp, gp[kp] / gp[kp - 1]);
    println!("   modified:  k  error e_k   e_k/e_(k-1)^2   law 1/(3 + 4 e_(k-1))");
    for k in 1..5 {
        let law = 1.0 / (3.0 + 4.0 * gm[k - 1]);
        println!("              {}  {:>9}   {:.6}        {:.6}", k, sci(gm[k]), gm[k] / (gm[k - 1] * gm[k - 1]), law);
        assert!((gm[k] / (gm[k - 1] * gm[k - 1]) - law).abs() < 1e-9);
    }
    assert!((gm[4] / (gm[3] * gm[3]) - 1.0 / 3.0).abs() < 1e-5 && gm[4] < 1e-10 && 1e-10 < gm[3]);
    let (p, dp) = (|x: f64| ((x - 3.0) * x + 3.0) * x - 1.0, |x: f64| (3.0 * x - 6.0) * x + 3.0);
    let pe = newton(&p, &dp, 2.0, 200, 1.0);
    let (pl, u) = (pe[pe.len() - 1], 2f64.powi(-53));
    println!("3. (x-1)^3 multiplied out, from 2: stops after {} steps with p(x) = {}", pe.len() - 1, sci(p(pl)));
    println!("   true error {}; u = {}, estimate cbrt(u) = {}", sci((pl - 1.0).abs()), sci(u), sci(u.powf(1.0 / 3.0)));
    assert!(p(pl) == 0.0 && 1e-6 < (pl - 1.0).abs() && (pl - 1.0).abs() < 2.0 * u.powf(1.0 / 3.0));
    let (mut lo, mut hi) = (1.0f64, 2.0f64);
    while lo < (lo + hi) / 2.0 && (lo + hi) / 2.0 < hi {
        let m = (lo + hi) / 2.0;
        if cyc(m) < 0.0 { lo = m } else { hi = m }
    }
    let (mut a, mut b) = (1.0f64, 2.0f64);                 // road two: secant on c
    for _ in 0..40 {
        if cyc(b) == cyc(a) { break }
        let nb = b - cyc(b) * (b - a) / (cyc(b) - cyc(a));
        a = b; b = nb;
    }
    let xc = lo;
    println!("4. Newton on arctan: cycle point x_c, bisection {:.11}, secant {:.11}", xc, b);
    assert!((xc - b).abs() < 1e-12 && (nstep(xc) + xc).abs() < 1e-12);
    println!("   N(x_c) = {:.11}; slope of the step map there N'(x_c) = -2 x_c atan(x_c) = {:.4}", nstep(xc), -2.0 * xc * xc.atan());
    for (lab, x0) in [("1.39", 1.39f64), ("1.5", 1.5), ("10", 10.0)] {
        let mut s = vec![x0];
        while s.len() < 7 && s[s.len() - 1].abs() < 1e30 && s[s.len() - 1].abs() > 1e-12 { let v = nstep(s[s.len() - 1]); s.push(v); }
        let parts: Vec<String> = s.iter().map(|&v| fx(v)).collect();
        println!("   from {:<4}: {}", lab, parts.join(", "));
    }
    assert!([0.1, 0.5, 1.0, 2.0, -3.0].iter().all(|&x| nstep(x) * x < 0.0));   // overshoots
    let mut s = vec![xc];
    while (s[s.len() - 1].abs() - xc).abs() < 1e-3 { let v = nstep(s[s.len() - 1]); s.push(v); }
    println!("   from x_c in floats: the 2-cycle holds to 1e-3 for {} steps, then x = {:.4}", s.len() - 1, s[s.len() - 1]);
    let amp = (2.0 * xc * xc.atan()).powi(2);              // growth of a slip per round trip
    let est = 2.0 * (1e-3f64 / 1e-16).ln() / amp.ln();
    println!("   a slip grows x{:.4} per round trip; from 1e-16 to 1e-3 takes about {:.1} steps", amp, est);
    assert!((est - (s.len() - 1) as f64).abs() < 3.0);
    let dp10 = damped(10.0, 1e-4);
    println!("5. damped Newton from 10: {} steps, end x = {}", dp10.len(), sci(dp10[dp10.len() - 1].1));
    let ls: Vec<String> = dp10.iter().map(|&(l, _)| format!("{}", l)).collect();
    println!("   step lengths: {}", ls.join(" "));
    let ll = 3.0 * 3f64.sqrt() / 8.0;                      // largest |f''| for arctan
    let ls_ = (0..30001).map(|i| { let x = i as f64 / 10000.0; 2.0 * x / ((1.0 + x * x) * (1.0 + x * x)) }).fold(0.0, f64::max);
    println!("   largest |f''| = 2|x|/(1+x^2)^2: scan {:.6}, formula 3 sqrt(3)/8 = {:.6}", ls_, ll);
    assert!((ls_ - ll).abs() < 1e-6);
    let lam_bound = (1.0 - 1e-4) * (1.0f64 / 101.0).powi(2) / (ll * 10f64.atan());
    let lmin = dp10.iter().map(|&(l, _)| l).fold(1.0, f64::min);
    println!("   theorem's floor on the step length {}; smallest taken {}, {:.0} times the floor", sci(lam_bound), lmin, lmin / lam_bound);
    assert!(dp10[dp10.len() - 1].1.abs() < 1e-15 && lmin >= lam_bound);
    assert!(dp10[dp10.len() - 3..].iter().all(|&(l, _)| l == 1.0));
    for c1 in [1e-4, 0.5] {                                // the miss must fall at every step
        let path: Vec<f64> = std::iter::once(10.0).chain(damped(10.0, c1).iter().map(|&(_, x)| x)).collect();
        assert!(path.windows(2).all(|w| w[1].atan().abs() < w[0].atan().abs()));
    }
    let h = |x: f64| ll * x.atan() * (1.0 + x * x).powi(2); // Kantorovich h at a start x
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..100 { let m = (lo + hi) / 2.0; if h(m) <= 0.5 { lo = m } else { hi = m } }
    let tstar = 1.0 / ((1.0 + lo * lo) * ll);
    println!("6. Kantorovich on arctan: h <= 1/2 for |x0| <= {:.4}; true basin |x0| < {:.4}, ratio {:.3}", lo, xc, xc / lo);
    let dat = |x: f64| 1.0 / (1.0 + x * x);                // road two: beta and eta from the slope
    let (beta, eta) = (1.0 / dat(lo), (lo.atan() / dat(lo)).abs());
    println!("   at that edge beta L eta = {:.6}; the root is promised within t* = {:.4} of x0; true distance {:.4}", beta * ll * eta, tstar, lo);
    assert!((beta * ll * eta - 0.5).abs() < 1e-9);
    let kn = newton(&|x: f64| x.atan(), &|x: f64| 1.0 / (1.0 + x * x), lo, 8, 1.0);
    assert!((h(lo) - 0.5).abs() < 1e-9 && tstar > lo && kn[kn.len() - 1] < 1e-15);
    let c1: Vec<String> = (0..6).map(|k| format!("{:.2}", xs[k].log10())).collect();
    let c2: Vec<String> = (0..6).map(|k| format!("{:.2}", gm[k].log10())).collect();
    println!("chart, log10 error: plain x^3 {}; modified x^3+x^4 {}", c1.join(" "), c2.join(" "));
    let (xp, yp) = (|x: f64| 180.0 + 70.0 * x, |y: f64| 120.0 - 70.0 * y);
    println!("figure, cycle points ({:.1}, {:.1}) and ({:.1}, {:.1}), tangents land at ({:.1}, {:.1}) and ({:.1}, {:.1}), curve ends ({:.1}, {:.1}) ({:.1}, {:.1})",
             xp(xc), yp(xc.atan()), xp(-xc), yp(-xc.atan()), xp(-xc), yp(0.0), xp(xc), yp(0.0),
             xp(-2.4), yp((-2.4f64).atan()), xp(2.4), yp(2.4f64.atan()));
    println!("ALL CHECKS PASS");
}
