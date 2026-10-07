// A digital from a call spread, and the skew term -- the check behind the card.
// std only. The normal CDF is a series written out, the integral is Simpson's
// rule, the random numbers come from a 64-bit xorshift written here.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const SL: f64 = -0.0004;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 { // 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-18 && k < 999.0 { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + phi(x) * total
}
fn d12(s: f64, k: f64, v: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (R - Q + 0.5 * v * v) * t) / (v * t.sqrt());
    (d1, d1 - v * t.sqrt())
}
fn call_s(s: f64, k: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, v, t); s * (-Q * t).exp() * n(d1) - k * (-R * t).exp() * n(d2)
}
fn call(k: f64, v: f64) -> f64 { call_s(S, k, v, T) }
fn put(k: f64, v: f64) -> f64 {
    let (d1, d2) = d12(S, k, v, T); k * (-R * T).exp() * n(-d2) - S * (-Q * T).exp() * n(-d1)
}
fn digital(k: f64, v: f64, t: f64) -> f64 { (-R * t).exp() * n(d12(S, k, v, t).1) }
fn vega(k: f64, v: f64, t: f64) -> f64 { S * (-Q * t).exp() * phi(d12(S, k, v, t).0) * t.sqrt() }
fn smile(k: f64, s: f64) -> f64 { SIG + s * (k - 100.0) } // vol falls 0.04 points per $1 of strike
fn mcall(k: f64) -> f64 { call(k, smile(k, SL)) }
fn mput(k: f64) -> f64 { put(k, smile(k, SL)) }
fn skewed(k: f64, s: f64, t: f64) -> f64 { digital(k, smile(k, s), t) - vega(k, smile(k, s), t) * s }
fn spread(f: &dyn Fn(f64) -> f64, k: f64, h: f64) -> f64 { (f(k - h) - f(k + h)) / (2.0 * h) }
fn flat(k: f64) -> f64 { call(k, SIG) }

fn main() {
    let d0 = (-R * T).exp();
    let (d, h) = (digital(K, SIG, T), 0.01);
    let (cs1, cst, one) = (spread(&flat, K, 1.0), spread(&flat, K, h), flat(K) - flat(K + 1.0));
    let (d1, d2) = d12(S, K, SIG, T);
    let m = 4000; let (a, b) = (-d2, 8.0); let w = (b - a) / m as f64; // road 3: Simpson over z > -d2
    let mut acc = 0.0;
    for i in 0..=m { let c = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; acc += c * phi(a + i as f64 * w); }
    let simp = d0 * w / 3.0 * acc;
    let (mut x, mut hits, nn): (u64, u64, u64) = (88172645463325252, 0, 200000); // road 4: simulate S_T
    let mut rnd = || { x ^= x << 13; x ^= x >> 7; x ^= x << 17; ((x >> 11) as f64 + 0.5) / 9007199254740992.0 };
    for _ in 0..nn / 2 {
        let (u1, u2) = (rnd(), rnd()); let rad = (-2.0 * u1.ln()).sqrt();
        for z in [rad * (2.0 * PI * u2).cos(), -rad * (2.0 * PI * u2).cos()] {
            if S * ((R - Q - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp() > K { hits += 1; }
        }
    }
    let p = hits as f64 / nn as f64;
    let (mc, se) = (d0 * p, d0 * (p * (1.0 - p) / nn as f64).sqrt());
    let pflat = (put(K + 1.0, SIG) - put(K - 1.0, SIG)) / 2.0;

    let v = vega(K, SIG, T); let vb = (call(K, SIG + 1e-4) - call(K, SIG - 1e-4)) / 2e-4;
    let (corr, dsk) = (-v * SL, skewed(K, SL, T));
    let (mcs1, mcst) = (spread(&mcall, K, 1.0), spread(&mcall, K, h));
    let mpst = -spread(&mput, K, h);
    let (lo, hi) = (mcall(K) - mcall(K + 1.0), mcall(K - 1.0) - mcall(K));
    let ddelta = d0 * phi(d2) / (S * SIG * T.sqrt());
    let cdelta = |k: f64, s1: f64| (call_s(s1 + 1e-3, k, SIG, T) - call_s(s1 - 1e-3, k, SIG, T)) / 2e-3;
    let sdelta = (cdelta(K - 1.0, S) - cdelta(K + 1.0, S)) / 2.0;
    let dvega = -d0 * phi(d2) * d1 / SIG;
    let svega = (vega(K - 1.0, SIG, T) - vega(K + 1.0, SIG, T)) / 2.0;

    let rows: Vec<(&str, f64)> = vec![("d1", d1), ("d2", d2), ("N(d2)", n(d2)), ("discount e^-rT", d0),
        ("1 digital e^-rT N(d2)", d), ("2 spread (C(99)-C(101))/2", cs1), ("  C(99)", flat(99.0)), ("  C(101)", flat(101.0)),
        ("  spread, h = 0.01", cst), ("3 Simpson over z > -d2", simp), ("4 simulated, 200000 paths", mc), ("  std error", se),
        ("digital put e^-rT N(-d2)", d0 * n(-d2)), ("  put spread (P(101)-P(99))/2", pflat), ("  call + put", cs1 + pflat),
        ("vega at 100, formula", v), ("  vega by bump", vb), ("skew slope dsigma/dK", SL), ("skew term -vega x slope", corr),
        ("market vol at 99", smile(99.0, SL)), ("market vol at 101", smile(101.0, SL)),
        ("5 skewed digital, formula", dsk), ("6 market spread, h = 1", mcs1), ("  market spread, h = 0.01", mcst),
        ("  market digital put", mpst), ("  call + put", mcst + mpst), ("  lower C(100)-C(101)", lo), ("  upper C(99)-C(100)", hi),
        ("greek: digital delta", ddelta), ("  spread delta", sdelta), ("greek: digital vega", dvega), ("  spread vega", svega),
        ("wrong: strike vol, no skew", d), ("wrong: N(d1)", d0 * n(d1)), ("wrong: slope in points", d - v * (-0.04)),
        ("wrong: sign flipped", d + v * SL), ("wrong: no divide by width", mcall(99.0) - mcall(101.0)),
        ("wrong: one-sided 100/101", one),
        ("try: slope -0.0008", skewed(K, -0.0008, T)), ("try: K = 110, term", -vega(110.0, smile(110.0, SL), T) * SL),
        ("try: T = 0.25, term", -vega(K, SIG, 0.25) * SL), ("try: h = 5 spread", spread(&flat, K, 5.0))];
    for (name, val) in &rows { println!("{:<30} {:>12.6}", name, val); }
    println!("width     centered miss   one-sided miss");
    let mut miss = vec![];
    for hh in [2.0, 1.0, 0.5, 0.25] {
        miss.push(spread(&flat, K, hh) - d);
        println!("{:5.2} {:16.9} {:16.9}", hh, miss[miss.len() - 1], (flat(K) - flat(K + hh)) / hh - d);
    }
    let ks: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let line = |lab: &str, vals: Vec<String>| println!("{}{}", lab, vals.join(" "));
    line("chart, strike         ", ks.iter().map(|k| format!("{:6.0}", k)).collect());
    line("chart, flat, cents    ", ks.iter().map(|&k| format!("{:6.2}", 100.0 * digital(k, SIG, T))).collect());
    line("chart, strike vol     ", ks.iter().map(|&k| format!("{:6.2}", 100.0 * digital(k, smile(k, SL), T))).collect());
    line("chart, market, cents  ", ks.iter().map(|&k| format!("{:6.2}", 100.0 * skewed(k, SL, T))).collect());
    let xs = [97.0, 98.0, 99.0, 99.5, 100.0, 100.5, 101.0, 102.0, 103.0];
    line("chart, S_T            ", xs.iter().map(|v| format!("{:6.1}", v)).collect());
    line("chart, ramp           ", xs.iter().map(|&v: &f64| format!("{:6.2}", ((v - 99.0).max(0.0) - (v - 101.0).max(0.0)) / 2.0)).collect());
    line("chart, step           ", xs.iter().map(|&v| format!("{:6.2}", if v > K { 1.0 } else { 0.0 })).collect());

    assert!((cst - d).abs() < 1e-8, "tight flat spread vs e^-rT N(d2)");
    assert!((simp - d).abs() < 1e-10, "Simpson road vs the series CDF");
    assert!((mc - d).abs() < 4.0 * se, "simulation within 4 standard errors");
    assert!((vb - v).abs() < 1e-6, "bumped vega vs formula");
    assert!((mcst - dsk).abs() < 1e-7, "tight market spread vs digital + skew term");
    assert!((mcst + mpst - (-R * T).exp()).abs() < 1e-8, "market call + put digitals = one discounted dollar");
    assert!(lo < mcst && mcst < hi, "market digital inside the two one-sided spreads");
    assert!(flat(K) - flat(K + 1.0) < simp && simp < flat(K - 1.0) - flat(K), "flat digital inside the sandwich");
    assert!((0..3).all(|i| miss[i] / miss[i + 1] > 3.8 && miss[i] / miss[i + 1] < 4.1), "centered miss quarters");
    assert!((sdelta - ddelta).abs() < 1e-4, "spread delta near digital delta");
    assert!((svega - dvega).abs() < 1e-3, "spread vega near digital vega");
    println!("ALL CHECKS PASS");
}
