// Stirling's approximation -- the same check as the Python, in Rust, on 20!.
// No crates; ln, exp, sqrt and sin are primitives; pi is built from Machin's series.
fn atan_inv(q: f64) -> f64 {           // arctan(1/q) from its own alternating series
    let (mut total, mut k, mut term) = (0.0, 0.0, 1.0 / q);
    while term > 1e-18 {
        let sign = if (k as i64) % 2 == 0 { 1.0 } else { -1.0 };
        total += sign * term / (2.0 * k + 1.0);
        k += 1.0;
        term /= q * q;
    }
    total
}

fn sci(x: f64) -> String {             // 2.4329 x 10^18, printed the same in Python
    let s = format!("{:.4e}", x);
    let (m, e) = s.split_once('e').unwrap();
    format!("{} x 10^{}", m, e)
}

fn ln_fact(n: u64) -> f64 {            // ln n! as a sum of logs, one per factor
    (2..=n).map(|k| (k as f64).ln()).sum()
}

fn d(n: u64) -> f64 {                  // ln n! minus the trapezoid shape
    ln_fact(n) - (n as f64 + 0.5) * (n as f64).ln() + n as f64
}

fn main() {
    let pi = 16.0 * atan_inv(5.0) - 4.0 * atan_inv(239.0);
    let n: u64 = 20;
    let fact: u64 = (2..=n).product();                  // road one: the exact integer
    let (nf, e) = (n as f64, 1f64.exp());
    let (lo, hi) = (nf * nf.ln() - nf + 1.0, (nf + 1.0) * (nf + 1.0).ln() - nf);
    let est = (2.0 * pi * nf).sqrt() * (nf / e).powi(20);
    let factf = fact as f64;
    println!("pi from Machin's series: {:.12}", pi);
    println!("20! exact: {}", fact);
    println!("integral bounds on ln 20!: {:.6} < {:.6} < {:.6}", lo, ln_fact(n), hi);
    println!("so 20! lies between {} and {}", sci(lo.exp()), sci(hi.exp()));
    println!("20/e = {:.6}; (20/e)^20 = {}; sqrt(40 pi) = {:.6}", nf / e, sci((nf / e).powi(20)), (2.0 * pi * nf).sqrt());
    println!("Stirling estimate: {}; ratio to 20! = {:.6}", sci(est), est / factf);
    let corr = est * (1.0 + 1.0 / (12.0 * nf));
    println!("with the 1/(12n) factor: {}; ratio = {:.8}", sci(corr), corr / factf);
    for m in [1u64, 2, 6, 10, 15, 20] {
        println!("chart, n = {}: d(n) = {:.4}, d(n) - 1/(12n) = {:.4}", m, d(m), d(m) - 1.0 / (12.0 * m as f64));
    }
    let big = 100u64;                                   // road two: squeeze the constant C
    let (c_hi, c_lo) = (d(big), d(big) - 1.0 / (12.0 * big as f64));
    println!("C, squeezed at n = 100: between {:.8} and {:.8}; ln sqrt(2 pi) = {:.8}", c_lo, c_hi, 0.5 * (2.0 * pi).ln());
    let h = pi / 2.0 / 200.0;                           // Simpson's rule on sin^20 over 0 to pi/2
    let simpson: f64 = (0..=200u32)
        .map(|j| (if j == 0 || j == 200 { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) * (j as f64 * h).sin().powi(20))
        .sum::<f64>() * h / 3.0;
    let mut reduction = pi / 2.0;
    for k in (2..=20).rev().step_by(2) {
        reduction *= (k as f64 - 1.0) / k as f64;       // parts: W_k = (k - 1)/k times W_(k-2)
    }
    println!("W_20 by Simpson: {:.10}; by the parts formula: {:.10}", simpson, reduction);
    let m = 1000u64;                                    // road three: Wallis's integrals of sin^k
    let mf = m as f64;
    let wallis = 4.0 * mf * 2f64.ln() + 4.0 * ln_fact(m) - 2.0 * ln_fact(2 * m) - (2.0 * mf + 1.0).ln();
    let (w_lo, w_hi) = (wallis.exp(), wallis.exp() * (2.0 * mf + 1.0) / (2.0 * mf));
    println!("Wallis, m = 1000: {:.6} < pi/2 < {:.6}; pi/2 = {:.6}", w_lo, w_hi, pi / 2.0);
    let bare = (nf / e).powi(20);
    println!("mistake 1, drop sqrt(2 pi n): {}, ratio {:.4}", sci(bare), bare / factf);
    println!("mistake 2, subtract instead of divide: 20! - estimate = {}", sci(factf - est));
    println!("mistake 3, stop at the lower integral: e (20/e)^20 = {}, ratio {:.4}", sci(lo.exp()), lo.exp() / factf);
    assert!(lo < factf.ln() && factf.ln() < hi);                         // integrals sandwich the product
    assert!(c_lo < 0.5 * (2.0 * pi).ln() && 0.5 * (2.0 * pi).ln() < c_hi); // squeeze meets Machin's pi
    assert!(w_lo < pi / 2.0 && pi / 2.0 < w_hi);                         // Wallis meets Machin's pi
    assert!((simpson - reduction).abs() < 1e-9);                         // parts formula meets Simpson
    assert!(est < factf && factf < est * (1.0 / (12.0 * nf)).exp());    // the card's 1/(12n) sandwich
    println!("ALL CHECKS PASS");
}
