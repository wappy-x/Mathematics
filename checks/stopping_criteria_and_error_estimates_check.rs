// When to stop -- the same check as the Python, in Rust.  No crates.
// Two roots.  The yield of a 7-day bill, where the price curve is nearly flat,
// and the rate of a 25-year mortgage, reached by slow fixed-point steps.  The
// iterations use only + - * /, so Python and Rust print the same digits.
const TA: f64 = 1e-12; // absolute floor
const TR: f64 = 1e-9; // relative tolerance
const L: f64 = 300000.0;
const N: usize = 300;
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn pw(b: f64, n: usize) -> f64 { let mut r = 1.0; for _ in 0..n { r *= b; } r }
// ---- the flat curve: a bill paying $100 after `days` days, simple yield y a year ----
fn bill(y: f64, days: f64) -> f64 { 100.0 / (1.0 + y * days / 365.0) }
fn bill_slope(y: f64, days: f64) -> f64 {
    let t = days / 365.0; -100.0 * t / ((1.0 + y * t) * (1.0 + y * t))
}
fn residual_stop(days: f64, quote: f64, cent: f64) -> (f64, Vec<(f64, f64)>) {
    let (mut lo, mut hi, mut rows) = (0.0, 0.10, Vec::new()); // bisection, residual test only
    loop {
        let m = (lo + hi) / 2.0; let r = bill(m, days) - quote; rows.push((m, r));
        if r.abs() <= cent { return (m, rows); }
        if r > 0.0 { lo = m; } else { hi = m; }
    }
}
fn newton(days: f64, quote: f64, mut y: f64, ta: f64, tr: f64) -> (f64, usize, f64) {
    let mut s = 0.0; // Newton, stopped on the step
    for k in 1..=50 {
        s = -(bill(y, days) - quote) / bill_slope(y, days); y += s;
        if s.abs() <= ta + tr * y.abs() { return (y, k, s); }
    }
    (y, 50, s)
}
fn g(m: f64, i: f64) -> f64 { m / L * (1.0 - 1.0 / pw(1.0 + i, N)) } // the fixed-point form
struct Run { i: f64, q: f64, x: Vec<f64>, slope: f64, kp: usize, rp: f64, over: f64, kc: usize, qc: f64, rc: f64 }
fn mortgage(m: f64, tr: f64) -> Run {
    let f = |i: f64| m * (1.0 - 1.0 / pw(1.0 + i, N)) / i - L; // dollars over or short
    let fp = |i: f64| { let v = 1.0 / pw(1.0 + i, N); m * (N as f64 * v / (1.0 + i) / i - (1.0 - v) / (i * i)) };
    let mut i = 0.002; // road 1: Newton on the dollar residual
    for _ in 0..8 { i -= f(i) / fp(i); }
    let (mut lo, mut hi) = (0.001, 0.008); // road 2: bisection, 60 halvings
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if f(mid) < 0.0 { hi = mid; } else { lo = mid; } }
    let q = m / L * N as f64 / pw(1.0 + i, N + 1); // g'(i*), the slow factor
    let mut x = vec![m / L]; // road 3: the fixed-point steps
    for _ in 0..160 { let last = x[x.len() - 1]; x.push(g(m, last)); }
    assert!((lo - i).abs() < 1e-12 * i && (x[160] - i).abs() < 1e-12 * i);
    let stop = |corrected: bool| -> (usize, f64) { // first k whose error estimate passes
        for k in 2..161 {
            let s = x[k] - x[k - 1]; let qh = s / (x[k - 1] - x[k - 2]);
            let est = if corrected { qh / (1.0 - qh) * s } else { s };
            if est.abs() <= TA + tr * x[k].abs() { return (k, qh); }
        }
        (0, 0.0)
    };
    let (kp, _) = stop(false);
    let (kc, qc) = stop(true);
    let (rp, rc) = ((x[kp] - i).abs() / i, (x[kc] - i).abs() / i);
    let over = (x[kp] - i).abs() / (TA + tr * i); // true error over the error promised
    Run { i, q, slope: fp(i), kp, rp, over, kc, qc, rc, x }
}
fn main() {
    let q_bill = bill(0.04, 7.0);
    let ystar = (100.0 - q_bill) / q_bill * 365.0 / 7.0; // road 1: the closed form
    println!("bill: 7 days, pays 100, quote {:.9} at 4% (illustrative), t = {:.9} years", q_bill, 7.0 / 365.0);
    let (ys, rows) = residual_stop(7.0, q_bill, 0.01);
    for (k, (m, r)) in rows.iter().enumerate() {
        println!("bisection step {}: yield {:.6} %, price {:.6}, residual {:.6}", k + 1, 100.0 * m, bill(*m, 7.0), r);
    }
    let sl = bill_slope(ys, 7.0); let est = (rows[rows.len() - 1].1 / sl).abs();
    println!("one-cent residual test stops at {:.6} %, true {:.6} %, error {:.6} points", 100.0 * ys, 100.0 * ystar, 100.0 * (ystar - ys));
    println!("slope at the stop {:.6} $ per unit yield; residual/slope estimates {:.6} points", sl, 100.0 * est);
    let (yn, kn, _) = newton(7.0, q_bill, ys, TA, TR); // road 2: Newton, stopped on its step
    println!("Newton from the stop: first step to {:.6} %; {} steps in all, yield {:.9} %, error {}", 100.0 * (ys + est), kn, 100.0 * yn, sci(yn - ystar));
    assert!((ys - 0.0375).abs() < 1e-15 && ((ystar - ys) - 0.0025).abs() < 1e-12); // the false stop
    assert!((yn - ystar).abs() < 1e-14 && (est - (ystar - ys)).abs() < 1e-6);
    // ---- the house example: a 25-year mortgage, 300 monthly payments ----
    let m = 1271.56;
    let r = mortgage(m, 1e-6);
    let (istar, x) = (r.i, &r.x);
    println!("mortgage: loan 300000, 300 payments of {:.2}; rate {:.15} a month, {:.6} % a year", m, istar, 1200.0 * istar);
    println!("slope {:.1} $ per unit monthly rate; one cent of residual moves the annual rate {} points", r.slope, sci(0.01 / r.slope.abs() * 1200.0));
    let bs = bill_slope(ystar, 7.0).abs();
    println!("same cent on the bill: {:.6} points, {:.0} times as much", 100.0 * 0.01 / bs, (0.01 / bs) / (0.01 / r.slope.abs() * 12.0));
    println!("q = g'(i*) = {:.6}, q/(1-q) = {:.6}", r.q, r.q / (1.0 - r.q));
    println!("error promised at tau_r 1e-6: {}; condition number: bill {:.1}, mortgage {:.2}", sci(TA + 1e-6 * istar), q_bill / (ystar * bs), L / (istar * r.slope.abs()));
    for k in [1, 2, 3, 10, 20, 30, 40] {
        let st = x[k] - x[k - 1];
        println!("k={}: rate {:.9} %, error {}, step {}, error/step {:.4}", k, 1200.0 * x[k], sci(x[k] - istar), sci(st), (x[k] - istar) / st);
    }
    let kp = r.kp;
    let s = x[kp] - x[kp - 1]; let qh = s / (x[kp - 1] - x[kp - 2]);
    println!("plain step test, tau_r 1e-6: stops at k={}, step {}, q-hat {:.6}, estimate {}, true {}", kp, sci(s), qh, sci(-qh / (1.0 - qh) * s), sci(x[kp] - istar));
    println!("  relative error {}, {:.2} times the error promised", sci(r.rp), r.over);
    println!("corrected test: stops at k={}, q-hat {:.6}, relative error {}", r.kc, r.qc, sci(r.rc));
    assert!(r.over > 1.0 && r.rp > 1e-6 && r.rc <= 1e-6 && (r.qc - r.q).abs() < 1e-4);
    let aitken = |k: usize| -> f64 { // from x_k, x_k+1, x_k+2
        let (d1, d2) = (x[k + 1] - x[k], x[k + 2] - x[k + 1]); let den = d2 - d1;
        if den != 0.0 { x[k + 2] - d2 * d2 / den } else { f64::NAN }
    };
    for k in [0, 10, 20, 30] {
        println!("Aitken from x{}, x{}, x{}: error {}; plain x{}: {}", k, k + 1, k + 2, sci(aitken(k) - istar), k + 2, sci(x[k + 2] - istar));
    }
    assert!((aitken(20) - istar).abs() < (x[22] - istar).abs() / 100.0);
    let (mut z, mut ev, zn); // Steffensen: Aitken, then restart from it
    z = m / L; ev = 0;
    loop {
        let g1 = g(m, z); let g2 = g(m, g1); ev += 2;
        let (d1, d2) = (g1 - z, g2 - g1); let next = g2 - d2 * d2 / (d2 - d1);
        if (next - z).abs() <= TA + 1e-6 * next.abs() { zn = next; break; }
        z = next;
    }
    println!("Steffensen: {} evaluations of g, relative error {}; plain needs {}", ev, sci((zn - istar).abs() / istar), r.kc);
    assert!((zn - istar).abs() / istar < 1e-9 && (ev as f64) < r.kc as f64 / 3.0);
    let d112 = (x[114] - x[113]) - (x[113] - x[112]);
    println!("Aitken in the noise, k=104: error {}; plain x106: {}; k=112 divides by {}", sci(aitken(104) - istar), sci(x[106] - istar), sci(d112));
    let ks: Vec<usize> = (5..41).step_by(5).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart k: {}", join(ks.iter().map(|k| k.to_string()).collect()));
    println!("chart log10 error: {}", join(ks.iter().map(|&k| format!("{:.2}", (x[k] - istar).abs().log10())).collect()));
    println!("chart log10 step: {}", join(ks.iter().map(|&k| format!("{:.2}", (x[k] - x[k - 1]).abs().log10())).collect()));
    println!("chart log10 Aitken: {}", join(ks.iter().map(|&k| format!("{:.2}", (aitken(k - 2) - istar).abs().log10())).collect()));
    let (_, kz, sz) = newton(7.0, 100.0, 0.04, 0.0, TR);
    let (_, kb, _) = newton(7.0, 100.0, 0.04, TA, TR);
    println!("zero-yield quote, relative test only: {} steps (the cap), last step {}; with the floor: {} steps", kz, sci(sz), kb);
    assert!(kz == 50 && kb < 10);
    let (y91, _) = residual_stop(91.0, bill(0.04, 91.0), 0.01);
    println!("try 91 days: one-cent residual test stops at {:.6} %, error {:.6} points", 100.0 * y91, 100.0 * (0.04 - y91));
    let r6 = mortgage(1932.90, 1e-6);
    println!("try 6 %, payment 1932.90: q {:.6}, plain stops k={} at {:.2} times the error promised, corrected k={}", r6.q, r6.kp, r6.over, r6.kc);
    let r9 = mortgage(m, 1e-9);
    println!("try tau_r 1e-9: plain stops k={} at {:.2} times the error promised, corrected k={}", r9.kp, r9.over, r9.kc);
    println!("ALL CHECKS PASS");
}
