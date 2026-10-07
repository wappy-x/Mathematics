// Taylor series -- the same check as the Python, in Rust.  No crates.
// Road one: partial sums T_n(x), built term by term here.  Road two: the
// closed form (exp, sin, cos, ln).  Road three: the remainder bound from
// Taylor's theorem, which must cover the gap between the first two.
fn taylor(pattern: [f64; 4], x: f64, n: usize) -> f64 {  // sign pattern times x^k/k!
    let (mut total, mut p) = (0.0, 1.0);
    for k in 0..=n {
        total += pattern[k % 4] * p;
        p = p * x / (k + 1) as f64;
    }
    total
}
fn ln_taylor(x: f64, n: usize) -> f64 {                   // ln(1 + x) = x - x^2/2 + ...
    let (mut total, mut p) = (0.0, 1.0);
    for k in 1..=n {
        p *= x;
        total += if k % 2 == 1 { 1.0 } else { -1.0 } * p / k as f64;
    }
    total
}
fn bound(x: f64, n: usize, top: f64) -> f64 {             // top * |x|^(n+1) / (n+1)!
    let mut b = top;
    for j in 1..=n + 1 {
        b = b * x.abs() / j as f64;
    }
    b
}
fn g(x: f64) -> f64 { if x == 0.0 { 0.0 } else { (-1.0 / (x * x)).exp() } }  // the smooth impostor
fn sci(v: f64) -> String {                                // 1.234e-05, as Python prints it
    let s = format!("{:.3e}", v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn main() {
    let (exp_p, sin_p, cos_p) = ([1.0, 1.0, 1.0, 1.0], [0.0, 1.0, 0.0, -1.0], [1.0, 0.0, -1.0, 0.0]);
    let e2x = 2.0f64.exp();
    let mut rows = vec![];
    for n in [2, 5, 10, 15, 20] {
        let t = taylor(exp_p, 2.0, n);
        rows.push(((e2x - t).abs(), bound(2.0, n, 9.0)));
        let (err, b) = rows[rows.len() - 1];
        println!("exp(2), n = {:2}: T_n = {:.10}, error {}, bound {}", n, t, sci(err), sci(b));
    }
    let need = (0..50).find(|&n| bound(2.0, n, 9.0) < 0.001).unwrap();
    println!("exp(2) = {:.10}; first n with bound under 0.001: {} (bound {})", e2x, need, sci(bound(2.0, need, 9.0)));
    let es = (taylor(sin_p, 2.0, 19) - 2.0f64.sin()).abs();
    let ec = (taylor(cos_p, 2.0, 18) - 2.0f64.cos()).abs();
    println!("sin(2), n = 19: error {}, bound {}", sci(es), sci(bound(2.0, 19, 1.0)));
    println!("cos(2), n = 18: error {}, bound {}", sci(ec), sci(bound(2.0, 18, 1.0)));
    let el = (ln_taylor(0.5, 20) - 1.5f64.ln()).abs();
    let bl = 0.5f64.powf(21.0) / (21.0 * 0.5);
    println!("ln(1.5), n = 20: error {}, bound {}", sci(el), sci(bl));
    let e2 = (ln_taylor(1.0, 1000) - 2.0f64.ln()).abs();
    println!("ln(2), n = 1000: error {}, bound {}", sci(e2), sci(1.0 / 1001.0));
    let far: Vec<f64> = [10, 20, 40].iter().map(|&n| ln_taylor(1.5, n)).collect();
    println!("ln(2.5) = {:.4}, but T_10, T_20, T_40 at x = 1.5: {:.1}, {:.1}, {:.1}", 2.5f64.ln(), far[0], far[1], far[2]);
    println!("impostor g(0.5) = {:.10}; every T_n(0.5) = 0, so the error stays {:.10}", g(0.5), g(0.5));
    let hs = [0.2, 0.1, 0.05];
    let q1: Vec<String> = hs.iter().map(|&h| sci(g(h) / h)).collect();
    println!("g(h)/h at h = 0.2, 0.1, 0.05: {}", q1.join(", "));
    let q10: Vec<f64> = hs.iter().map(|&h| g(h) / h.powf(10.0)).collect();
    let q10s: Vec<String> = q10.iter().map(|&v| sci(v)).collect();
    println!("g(h)/h^10 at h = 0.2, 0.1, 0.05: {}", q10s.join(", "));
    println!("second difference at 0, h = 0.1: {}", sci((g(0.1) - 2.0 * g(0.0) + g(-0.1)) / 0.01));
    let chart: Vec<String> = (0..9).map(|i| format!("{:.2}", g(i as f64 / 4.0))).collect();
    println!("chart, g(x) at x = 0, 0.25, ..., 2: {}", chart.join(" "));
    println!("mistake, factorials dropped: 1 + 2 + 4 + ... + 2^20 = {}", (0..21).map(|k| 1u64 << k).sum::<u64>());
    assert!(rows.iter().all(|&(err, b)| err <= b) && rows[4].0 < 1e-12);  // roads one, two, three agree
    assert!(es <= bound(2.0, 19, 1.0) && ec <= bound(2.0, 18, 1.0) && el <= bl && e2 <= 1.0 / 1001.0);
    assert!(far[2].abs() > 1000.0 * 2.5f64.ln().abs());                     // beyond radius 1: no convergence
    assert!(g(0.5) > 0.018 && q10[0] > q10[1] && q10[1] > q10[2] && q10[2] < 1e-150); // flat, yet not zero
    println!("ALL CHECKS PASS");
}
