// Numerical derivatives -- the check behind the card.  Rust std only.  The
// function is the Black-Scholes call price C(S) on the library's finance
// example (K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year), bumped around
// S = 100.  Road one: difference quotients at 13 step sizes.  Road two: the
// exact delta from its closed form.  Truncation laws and rounding checked.
const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n(x: f64) -> f64 { // bell-curve area left of x, by its own series
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-18 * total.abs() {
        k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term;
    }
    0.5 + phi(x) * total
}
fn d1_of(s: f64) -> f64 { ((s / K).ln() + (R - Q + SIG * SIG / 2.0) * T) / (SIG * T.sqrt()) }
fn call(s: f64) -> f64 {
    let d1 = d1_of(s);
    s * (-Q * T).exp() * n(d1) - K * (-R * T).exp() * n(d1 - SIG * T.sqrt())
}
fn cents(s: f64) -> f64 { (call(s) * 100.0 + 0.5).floor() / 100.0 } // a quoted price
fn kink(s: f64) -> f64 { (s - K).max(0.0) } // value on expiry day
fn fwd(f: fn(f64) -> f64, h: f64) -> f64 { (f(S0 + h) - f(S0)) / h }
fn ctr(f: fn(f64) -> f64, h: f64) -> f64 { (f(S0 + h) - f(S0 - h)) / (2.0 * h) }
fn lg(x: f64) -> f64 { x.abs().ln() / 10f64.ln() }
fn main() {
    let d1 = d1_of(S0);
    let delta = (-Q * T).exp() * n(d1); // road two
    let c2 = (-Q * T).exp() * phi(d1) / (S0 * SIG * T.sqrt()); // C'' (gamma)
    let c3 = -c2 / S0 * (1.0 + d1 / (SIG * T.sqrt())); // C'''
    println!("call C(100) = {:.12}; exact delta e^(-qT)N(d1) = {:.12}", call(S0), delta);
    println!("C'' = {:.12}; C''' = {:.12}", c2, c3);
    let steps = [("1", 1.0), ("0.1", 0.1), ("0.01", 0.01), ("1e-3", 1e-3), ("1e-4", 1e-4),
        ("1e-5", 1e-5), ("1e-6", 1e-6), ("1e-7", 1e-7), ("1e-8", 1e-8), ("1e-9", 1e-9),
        ("1e-10", 1e-10), ("1e-11", 1e-11), ("1e-12", 1e-12)];
    let mut err_c = std::collections::HashMap::new();
    for (lab, h) in steps {
        let (f, c) = (fwd(call, h), ctr(call, h));
        err_c.insert(lab, (c - delta).abs());
        println!("h={}: forward {:.12} log10 err {:.2}; central {:.12} log10 err {:.2}", lab, f, lg(f - delta), c, lg(c - delta));
    }
    println!("h=1 by hand: C(101) = {:.12}; C(99) = {:.12}; forward err {:+.12} vs h C''/2 = {:+.12}; central err {:+.12} vs h^2 C'''/6 = {:+.12}",
        call(101.0), call(99.0), fwd(call, 1.0) - delta, c2 / 2.0, ctr(call, 1.0) - delta, c3 / 6.0);
    let rf = (fwd(call, 0.01) - delta) / (0.01 * c2 / 2.0); // observed over predicted
    let rc = (ctr(call, 0.1) - delta) / (0.1f64.powi(2) * c3 / 6.0);
    println!("truncation law: forward err / (h C''/2) at h=0.01 = {:.5}; central err / (h^2 C'''/6) at h=0.1 = {:.5}; kink max(S-100,0) at h=1, 1e-6: forward {:.3}, {:.3}; central {:.3}, {:.3}",
        rf, rc, fwd(kink, 1.0), fwd(kink, 1e-6), ctr(kink, 1.0), ctr(kink, 1e-6));
    let eta = 2f64.powi(-52) * call(S0); // one unit of rounding in C
    println!("best step: doubles (eta {:.2}e-15) forward {:.8}, central {:.5}; cents (eta 0.005) forward {:.2}, central {:.2}",
        eta * 1e15, 2.0 * (eta / c2).sqrt(), (3.0 * eta / -c3).powf(1.0 / 3.0),
        2.0 * (0.005 / c2).sqrt(), (3.0 * 0.005 / -c3).powf(1.0 / 3.0));
    let cq: Vec<(&str, f64)> = [("0.01", 0.01), ("0.1", 0.1), ("1", 1.0), ("3", 3.0)]
        .iter().map(|&(lab, h)| (lab, ctr(cents, h))).collect();
    let parts: Vec<String> = cq.iter().map(|(lab, v)| format!("h={} {:.4} err {:+.4}", lab, v, v - delta)).collect();
    println!("cent-rounded prices, central: {}", parts.join("; "));
    assert!((ctr(call, 1e-4) - delta).abs() < 1e-9); // the two roads meet
    assert!((rf - 1.0).abs() < 1e-3 && (rc - 1.0).abs() < 1e-3); // truncation shrinks as h, h^2
    assert!(err_c["1e-12"] > 1000.0 * err_c["1e-4"]); // too small a step: rounding wins
    assert!((cq[0].1 - delta).abs() > 100.0 * (cq[3].1 - delta).abs()); // coarse prices want a big step
    println!("ALL CHECKS PASS");
}
