// Hyperbolic functions -- the Python check again, in Rust, std only.  exp, ln and sqrt are
// primitives; sinh, cosh, rates and inverses are built here.  Chain y = 8 cosh(x / 8), hooks 16 m apart.
const A: f64 = 8.0; // chain parameter a, m
const HOOK: f64 = 8.0; // hook's distance from the middle, m

fn cosh(t: f64) -> f64 { (t.exp() + (-t).exp()) / 2.0 } // road one: exp's even half
fn sinh(t: f64) -> f64 { (t.exp() - (-t).exp()) / 2.0 } // and its odd half
fn tanh(t: f64) -> f64 { sinh(t) / cosh(t) }
fn chain(x: f64) -> f64 { A * cosh(x / A) }

fn series(t: f64, parity: usize) -> f64 { // road two: e^t's own terms, even or odd powers only
    let (mut total, mut term) = (0.0, 1.0);
    for n in 0..40 {
        if n % 2 == parity { total += term; }
        term *= t / (n as f64 + 1.0);
    }
    total
}

fn slope(f: &dyn Fn(f64) -> f64, t: f64, h: f64) -> f64 { (f(t + h) - f(t)) / h } // rise over run
fn central(f: &dyn Fn(f64) -> f64, t: f64) -> f64 { (f(t + 1e-5) - f(t - 1e-5)) / 2e-5 }

fn bisect(f: fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 { // halve a bracket
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if f(mid) < target { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn main() {
    println!("exp halves at t = 1: e^t = {:.6}, e^-t = {:.6}; cosh = {:.6}, sinh = {:.6}, tanh = {:.6}",
             1f64.exp(), (-1f64).exp(), cosh(1.0), sinh(1.0), tanh(1.0));
    for t in [1.0_f64, 3.0, -2.0] {
        let (c, s) = (series(t, 0), series(t, 1));
        assert!((c - cosh(t)).abs().max((s - sinh(t)).abs()) < 1e-12 * cosh(t)); // series against exp halves
        assert!((c * c - s * s - 1.0).abs() < 1e-11); // the identity, on road two
        println!("t = {:.0}: series cosh = {:.6}, sinh = {:.6}; cosh^2 = {:.6}, sinh^2 = {:.6}, difference = {:.6}",
                 t, c, s, c * c, s * s, c * c - s * s);
    }
    let rates: [(&str, fn(f64) -> f64, f64, f64); 4] = [("sinh at 1", sinh, 1.0, cosh(1.0)), ("cosh at 1", cosh, 1.0, sinh(1.0)),
        ("tanh at 1", tanh, 1.0, 1.0 / cosh(1.0).powi(2)), ("chain at the hook", chain, HOOK, sinh(HOOK / A))];
    for (name, f, at, rule) in rates {
        let q: Vec<f64> = [0.1, 0.01, 0.001].iter().map(|&h| slope(&f, at, h)).collect();
        println!("rate of {}: rule {:.6}; quotients h = 0.1, 0.01, 0.001: {:.6}, {:.6}, {:.6}", name, rule, q[0], q[1], q[2]);
    }
    let (n, dx) = (100000, 2.0 * HOOK / 100000.0);
    let pieces: f64 = (0..n).map(|k| dx.hypot(chain(-HOOK + (k + 1) as f64 * dx) - chain(-HOOK + k as f64 * dx))).sum();
    let length = 2.0 * A * sinh(HOOK / A);
    let mut roads: Vec<(f64, f64)> = rates.iter().map(|&(_, f, at, rule)| (central(&f, at), rule)).collect();
    roads.push((pieces, length));
    for (numeric, rule) in roads {
        assert!((numeric - rule).abs() < 1e-6 * rule.abs().max(1.0)); // formula against brute force
    }
    println!("chain: bottom {:.6} m, hooks {:.6} m, sag {:.6} m; slope's rate {:.6} = sqrt(1 + slope^2) / 8 = {:.6}",
             chain(0.0), chain(HOOK), chain(HOOK) - chain(0.0), cosh(1.0) / A, (1.0 + sinh(1.0).powi(2)).sqrt() / A);
    println!("chain length: 16 sinh 1 = {:.6} m; {} straight pieces = {:.6} m", length, n, pieces);
    let inverses: [(&str, f64, f64, fn(f64) -> f64, f64, f64); 3] = [
        ("arcosh 1.25", 1.25, (1.25 + (1.25f64 * 1.25 - 1.0).sqrt()).ln(), cosh, 0.0, 1.0 / (1.25f64 * 1.25 - 1.0).sqrt()),
        ("arsinh 1.00", 1.0, (1.0 + 2f64.sqrt()).ln(), sinh, -5.0, 1.0 / 2f64.sqrt()),
        ("artanh 0.50", 0.5, 0.5 * (1.5f64 / 0.5).ln(), tanh, -5.0, 1.0 / (1.0 - 0.25))];
    let mut found = Vec::new();
    for (name, x, formula, f, lo, rate) in inverses {
        let b = bisect(f, x, lo, 5.0);
        let q = central(&|u| bisect(f, u, lo, 5.0), x);
        assert!((b - formula).abs().max((q - rate).abs()) < 1e-6); // log formula against bisection
        found.push(b);
        println!("{}: log formula {:.6}; bisection {:.6}; rate rule {:.6}, quotient {:.6}", name, formula, b, rate, q);
    }
    println!("chain 2 m above its bottom at x = -{:.6} and {:.6} m; slope 1 at x = {:.6} m", A * found[0], A * found[0], A * found[1]);
    println!("mistakes: trig sign on cosh's rate {:.6}; cosh^2 + sinh^2 at 1 = {:.6}; cosh at -{:.6} = {:.6} too",
             -sinh(1.0), cosh(1.0).powi(2) + sinh(1.0).powi(2), found[0], cosh(-found[0]));
    let (xs, sag) = ((-8..=8).step_by(2).collect::<Vec<i32>>(), chain(HOOK) - chain(0.0));
    let join = |v: Vec<String>| v.join(", ");
    println!("chart x m: {}", join(xs.iter().map(|x| x.to_string()).collect()));
    println!("chart catenary m: {}", join(xs.iter().map(|&x| format!("{:.2}", chain(x as f64) - A)).collect()));
    println!("chart parabola m: {}; gap at 6 m {:.2}", join(xs.iter().map(|&x| format!("{:.2}", sag * (x as f64 / 8.0).powi(2))).collect()),
             sag * 0.5625 - chain(6.0) + A);
    println!("ALL CHECKS PASS");
}
