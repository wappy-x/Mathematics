// Weighted Gauss rules -- the same check as gauss_hermite_and_weighted_rules_check.py.
// Standard library only, no crates.  Nodes are roots of the three-term recurrences,
// found by a scan and bisection; weights come from the closed weight formulas.
// Road 1: closed forms.  Road 2: the weighted Gauss rule at many sizes, with the
// first-missed-term estimate.  Road 3: Simpson's rule on a fine grid, no weights.
use std::f64::consts::PI;
const S0: f64 = 50.0; const MU: f64 = 0.08; const SIG: f64 = 0.60; const T: f64 = 2.0; const K: f64 = 50.0;

fn sci(x: f64) -> String { format!("{:.2e}", x) }               // 1.23e-5, the same digits as Python
fn herm(n: usize, x: f64) -> (f64, f64) {                        // physicists' H_n(x) and H_(n-1)(x)
    let (mut a, mut b) = (0.0, 1.0);
    for k in 0..n { let c = 2.0 * x * b - 2.0 * k as f64 * a; a = b; b = c; }
    (b, a)
}
fn lag(n: usize, x: f64) -> (f64, f64) {                         // Laguerre L_n(x) and L_(n-1)(x)
    let (mut a, mut b) = (0.0, 1.0);
    for k in 0..n { let c = ((2 * k + 1) as f64 - x) * b - k as f64 * a; a = b; b = c / (k + 1) as f64; }
    (b, a)
}
fn roots(p: fn(usize, f64) -> (f64, f64), n: usize, lo: f64, count: usize) -> Vec<f64> {
    let (mut out, mut x0, mut f0) = (Vec::new(), lo, p(n, lo).0);  // scan in steps of 0.001, then bisect
    for i in 1..=count {
        let x1 = lo + i as f64 * 0.001;
        let f1 = p(n, x1).0;
        if (f0 < 0.0) != (f1 < 0.0) {
            let (mut a, mut b) = (x0, x1);
            for _ in 0..60 {
                let m = 0.5 * (a + b);
                if (p(n, m).0 < 0.0) == (f0 < 0.0) { a = m; } else { b = m; }
            }
            out.push(0.5 * (a + b));
        }
        x0 = x1; f0 = f1;
    }
    out
}
fn fact(n: usize) -> f64 { let mut f = 1.0; for k in 2..=n { f *= k as f64; } f }
fn pw(x: f64, k: usize) -> f64 { let mut r = 1.0; for _ in 0..k { r *= x; } r }
fn dot(ws: &[f64], vs: &[f64]) -> f64 { let mut s = 0.0; for (w, v) in ws.iter().zip(vs) { s += w * v; } s }
fn hermite(n: usize) -> (Vec<f64>, Vec<f64>) {                  // nodes x_i, probabilities p_i = w_i / sqrt(pi)
    let xs = roots(herm, n, -7.000123, 14000);
    let ps = xs.iter().map(|&x| pw(2.0, n - 1) * fact(n) / ((n * n) as f64 * pw(herm(n - 1, x).0, 2))).collect();
    (xs, ps)
}
fn laguerre(n: usize) -> (Vec<f64>, Vec<f64>) {                 // nodes x_i, weights w_i for the weight e^(-x)
    let xs = roots(lag, n, 0.000123, 60000);
    let ws = xs.iter().map(|&x| x / ((n * n) as f64 * pw(lag(n - 1, x).0, 2))).collect();
    (xs, ws)
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ncdf(d: f64) -> f64 {                                         // normal area left of d, from the erf series
    let (x, mut t, mut s) = (d / 2f64.sqrt(), d / 2f64.sqrt(), 0.0);
    for k in 0..40 { s += t / (2 * k + 1) as f64; t *= -x * x / (k + 1) as f64; }
    0.5 + s / PI.sqrt()
}
fn mv() -> (f64, f64) { ((MU - 0.5 * SIG * SIG) * T, SIG * T.sqrt()) }   // centre and spread of log(S_T / S0)
fn share(z: f64) -> f64 { let (m, v) = mv(); S0 * (m + v * z).exp() }     // the share's price at draw z
fn call(z: f64) -> f64 { (share(z) - K).max(0.0) }              // the option's payoff: kinked at the strike
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn gh(f: &dyn Fn(f64) -> f64, n: usize, r2: f64, twice: bool) -> f64 {   // E[f(Z)] by n Gauss-Hermite nodes
    let (xs, ps) = hermite(n);
    let vs: Vec<f64> = xs.iter().map(|&x| (if twice { (-x * x).exp() } else { 1.0 }) * f(r2 * x)).collect();
    dot(&ps, &vs)
}

fn main() {
    let (m, v) = mv();
    let r2 = 2f64.sqrt();
    let exact = S0 * (MU * T).exp();
    let d2 = ((S0 / K).ln() + m) / v;
    let c_exact = exact * ncdf(d2 + v) - K * ncdf(d2);
    let (xs, ps) = hermite(7);
    println!("log-price centre m = {:.6}, spread v = {:.10}, slope a = v sqrt2 = {:.10}", m, v, v * r2);
    println!("i  node x_i       z = sqrt2 x_i  probability p_i  share at node  p_i x share");
    for i in 0..7 {
        let s = share(r2 * xs[i]);
        println!("{}  {:+.10}  {:+.6}      {:.10}  {:12.6}  {:11.6}", i + 1, xs[i], r2 * xs[i], ps[i], s, ps[i] * s);
    }
    let psum = dot(&ps, &[1.0; 7]);
    let z12 = dot(&ps, &xs.iter().map(|&x| pw(r2 * x, 12)).collect::<Vec<_>>());
    let z14 = dot(&ps, &xs.iter().map(|&x| pw(r2 * x, 14)).collect::<Vec<_>>());
    println!("sum of probabilities {:.15}; E[Z^12] rule {:.6} (true 10395); E[Z^14] rule {:.6} (true 135135, short {:.6})", psum, z12, z14, 135135.0 - z14);
    let g7 = gh(&share, 7, r2, false);
    let simp = simpson(&|z| phi(z) * share(z), -10.0, 10.0, 2000);
    println!("expected share price: closed form {:.10}; 7 nodes {:.10} err {}", exact, g7, sci(g7 - exact));
    println!("Simpson, 2000 steps on [-10, 10]: {:.10} err {}", simp, sci(simp - exact));
    let se: Vec<f64> = (0..=100).map(|n| if n >= 2 && n % 2 == 0 { simpson(&|z| phi(z) * share(z), -10.0, 10.0, n) - exact } else { 0.0 }).collect();
    let ns = (2..=100).step_by(2).filter(|&n| se[n].abs() > (g7 - exact).abs()).max().unwrap() + 2; // from here on Simpson stays within the 7-node error
    println!("Simpson on [-10, 10] stays within the 7-node error from {} steps, {} payoffs: err {}", ns, ns + 1, sci(se[ns]));
    println!(" n  rule E[S_T]      true err   estimate   ratio  log10|err|  call err  log10|err|");
    let (mut ratio, mut cerr) = (vec![0.0; 13], vec![0.0; 13]);
    for n in 1..13 {
        let g = gh(&share, n, r2, false);
        let est = -S0 * m.exp() * pw(v * r2, 2 * n) * fact(n) / (fact(2 * n) * pw(2.0, n));
        ratio[n] = if g != exact { est / (g - exact) } else { 0.0 };
        cerr[n] = gh(&call, n, r2, false) - c_exact;
        println!("{:2}  {:15.10}  {:>9}  {:>9}  {:6.3}  {:6.2}  {:>9}  {:6.2}", n, g, sci(g - exact), sci(est), ratio[n],
                 (g - exact).abs().max(1e-16).log10(), sci(cerr[n]), cerr[n].abs().log10());
    }
    let zk = ((K / S0).ln() - m) / v;                              // where the payoff kinks
    let c_simp = simpson(&|z| phi(z) * call(z), zk, 10.0, 2000);
    println!("call, strike 50: closed form {:.10}; Simpson from the kink {:.10}; 7 nodes {:.6}", c_exact, c_simp, c_exact + cerr[7]);
    let (no_r2, no_pi, twice) = (gh(&share, 7, 1.0, false), g7 * PI.sqrt(), gh(&share, 7, r2, true));
    println!("wrong: no sqrt2 {:.6}; no 1/sqrt(pi) {:.6}; weight counted twice {:.6}", no_r2, no_pi, twice);
    let refund = |x: f64| 1.0 / (1.0 + x);                         // warranty refund fraction for a failure at year x
    let w_simp = simpson(&|x: f64| (-x).exp() * refund(x), 0.0, 40.0, 40000);
    println!("warranty, Simpson on [0, 40], 40000 steps: {:.12}", w_simp);
    let mut lag_err = vec![0.0; 15];
    for n in [3usize, 7, 14] {
        let (lx, lw) = laguerre(n);
        let q = dot(&lw, &lx.iter().map(|&x| refund(x)).collect::<Vec<_>>());
        lag_err[n] = q - w_simp;
        let lm = (0..2 * n).map(|k| (dot(&lw, &lx.iter().map(|&x| pw(x, k)).collect::<Vec<_>>()) / fact(k) - 1.0).abs()).fold(0.0, f64::max); // exact: k! up to degree 2n - 1
        println!("Laguerre {:2} nodes: {:.12} err {}; weights sum {:.12}; moments k! to degree {} within {}", n, q, sci(q - w_simp), dot(&lw, &vec![1.0; n]), 2 * n - 1, sci(lm));
        assert!(lm < 1e-10, "Laguerre moments match k!");
    }
    let (mut i0, mut t) = (0.0, 1.0);
    for k in 0..30 { i0 += t; t /= 4.0 * (k + 1) as f64 * (k + 1) as f64; }
    let cv: Vec<f64> = (1..8).map(|i| (((2 * i - 1) as f64 * PI / 14.0).cos()).exp()).collect();
    let ch = dot(&[PI / 7.0; 7], &cv);
    println!("Chebyshev 7 nodes on e^x/sqrt(1-x^2): {:.12}; pi I0(1) series {:.12}; err {}", ch, PI * i0, sci(ch - PI * i0));
    for (lab, sg, tt) in [("volatility 30%", 0.30, 2.0), ("8 years", 0.60, 8.0)] {
        let (m2, v2): (f64, f64) = ((MU - 0.5 * sg * sg) * tt, sg * f64::sqrt(tt));
        let gg = gh(&|z| S0 * (m2 + v2 * z).exp(), 7, r2, false);
        println!("try {}: exact {:.10}; 7 nodes {:.10} err {}", lab, S0 * (MU * tt).exp(), gg, sci(gg - S0 * (MU * tt).exp()));
    }
    assert!((psum - 1.0).abs() < 1e-13, "probabilities must sum to 1");
    assert!((z12 - 10395.0).abs() < 1e-8, "exact for the degree-12 moment");
    assert!((z14 - (135135.0 - 5040.0)).abs() < 1e-7, "short by exactly 7! at degree 14");
    assert!((g7 - exact).abs() < 1e-6, "7 nodes meet the closed form to a millionth of a dollar");
    assert!((simp - exact).abs() < 1e-9, "Simpson meets the closed form");
    assert!((2..11).all(|n| 0.8 < ratio[n] && ratio[n] < 0.86), "the first missed term explains most of the error");
    assert!((c_simp - c_exact).abs() < 1e-8, "kinked payoff: Simpson from the kink meets the closed form");
    assert!(0.01 < cerr[7].abs() && cerr[7].abs() < 0.1, "kinked payoff: 7 Gauss nodes are off by cents, not dollars");
    assert!(lag_err[7].abs() < 1e-3 && lag_err[14].abs() < lag_err[7].abs(), "Laguerre closes in on Simpson");
    assert!((ch - PI * i0).abs() < 1e-9, "Chebyshev against the I0 series");
    println!("ALL CHECKS PASS");
}
