// Charm -- the same check as charm_check.py, in Rust.  Standard library only,
// no crates.  The bell-curve area N(x) is built a different way from the Python:
// add up thin slices under the curve (Simpson), not a power series.
// Compile: rustc --edition 2021 -O charm_check.rs -o /tmp/charm_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }     // bell-curve height at x
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                                // bell-curve area left of x
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn dd(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> (f64, f64) {
    let d1 = ((s0 / k).ln() + (r - q + 0.5 * s * s) * t) / (s * t.sqrt());
    (d1, d1 - s * t.sqrt())
}
fn call(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    let (d1, d2) = dd(s0, k, r, q, s, t);
    s0 * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 { (-q * t).exp() * n_cdf(dd(s0, k, r, q, s, t).0) }
fn put_delta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 { -(-q * t).exp() * n_cdf(-dd(s0, k, r, q, s, t).0) }
fn theta(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {     // the theta card's formula, per year
    let (d1, d2) = dd(s0, k, r, q, s, t);
    -s0 * (-q * t).exp() * phi(d1) * s / (2.0 * t.sqrt()) - r * k * (-r * t).exp() * n_cdf(d2)
        + q * s0 * (-q * t).exp() * n_cdf(d1)
}
fn charm(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {     // Road 1: the formula, per year
    let (d1, d2) = dd(s0, k, r, q, s, t);
    let slide = (2.0 * (r - q) * t - d2 * s * t.sqrt()) / (2.0 * t * s * t.sqrt());
    q * (-q * t).exp() * n_cdf(d1) - (-q * t).exp() * phi(d1) * slide
}
fn put_charm(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 { charm(s0, k, r, q, s, t) - q * (-q * t).exp() }
fn delta_integral(s0: f64, k: f64, r: f64, q: f64, s: f64, t: f64) -> f64 {
    // Road 5: delta as an average: e^-rT E[(S_T / S) when S_T > K], by Simpson.  No N, no d1.
    let lo = ((k / s0).ln() - (r - q - 0.5 * s * s) * t) / (s * t.sqrt());
    let f = |z: f64| ((r - q - 0.5 * s * s) * t + s * t.sqrt() * z).exp() * phi(z);
    (-r * t).exp() * simpson(f, lo, 12.0, 4000)
}

fn main() {
    let (s0, k, r, q, s, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d1, d2) = dd(s0, k, r, q, s, t);
    let (d, ch, chp) = (delta(s0, k, r, q, s, t), charm(s0, k, r, q, s, t), put_charm(s0, k, r, q, s, t));
    let (h, e) = (1e-4, 0.01);
    let c_delta = -(delta(s0, k, r, q, s, t + h) - delta(s0, k, r, q, s, t - h)) / (2.0 * h);
    let c_price = -(call(s0 + e, k, r, q, s, t + h) - call(s0 - e, k, r, q, s, t + h)
        - call(s0 + e, k, r, q, s, t - h) + call(s0 - e, k, r, q, s, t - h)) / (4.0 * e * h);
    let c_theta = (theta(s0 + e, k, r, q, s, t) - theta(s0 - e, k, r, q, s, t)) / (2.0 * e);
    let c_int = -(delta_integral(s0, k, r, q, s, t + h) - delta_integral(s0, k, r, q, s, t - h)) / (2.0 * h);
    let p_bump = -(put_delta(s0, k, r, q, s, t + h) - put_delta(s0, k, r, q, s, t - h)) / (2.0 * h);
    let m = 1.0 / 12.0;                                                  // one month, in years
    let drift = delta(s0, k, r, q, s, t - m) - d;
    let drift_int = simpson(|u| charm(s0, k, r, q, s, t - u), 0.0, m, 200);   // charm added up over the month
    let (book, day) = (10000.0, 1.0 / 365.0);                            // 10,000 calls hedged; one day

    let mut rows: Vec<(String, f64)> = vec![
        ("d1", d1), ("d2", d2), ("e^-qT", (-q * t).exp()), ("N(d1)", n_cdf(d1)), ("phi(d1)", phi(d1)),
        ("slide  d(d1)/dT", (2.0 * (r - q) * t - d2 * s * t.sqrt()) / (2.0 * t * s * t.sqrt())), ("call delta", d),
        ("dividend piece  q e^-qT N(d1)", q * d), ("bell piece  e^-qT phi(d1) slide", q * d - ch),
        ("1 charm, formula", ch), ("2 delta bumped in time", c_delta), ("3 price bumped in S and T", c_price),
        ("4 theta bumped in S", c_theta), ("5 integral delta, bumped", c_int),
        ("put delta", put_delta(s0, k, r, q, s, t)), ("put charm, formula", chp),
        ("  put delta bumped in time", p_bump), ("  q e^-qT", q * (-q * t).exp()),
        ("month: charm x 1/12", ch * m), ("  delta drift, repriced", drift), ("  charm added up", drift_int),
        ("  delta after a month", d + drift),
        ("night: charm per day", ch * day), ("  hedge change, charm", book * ch * day),
        ("  hedge change, repriced", book * (delta(s0, k, r, q, s, t - day) - d)),
        ("  shares held tonight", book * d), ("  weekend, 3 days, charm", 3.0 * book * ch * day),
    ].into_iter().map(|(a, b)| (a.to_string(), b)).collect();
    for (s1, lab) in [(100.0_f64, "2 days left, S 100"), (101.0, "2 days left, S 101")] {
        let pr = book * charm(s1, k, r, q, s, 2.0 * day) * day;
        let ex = book * (delta(s1, k, r, q, s, day) - delta(s1, k, r, q, s, 2.0 * day));
        rows.push((format!("{}: delta", lab), delta(s1, k, r, q, s, 2.0 * day)));
        rows.push(("  night, charm".to_string(), pr));
        rows.push(("  night, repriced".to_string(), ex));
        rows.push(("  charm misses by".to_string(), ex - pr));
    }
    let gam = (-q * t).exp() * phi(d1) / (s0 * s * t.sqrt());          // the gamma card's formula
    rows.push(("gamma".to_string(), gam));
    rows.push(("  delta change, 1-sd day move".to_string(), gam * s0 * s * day.sqrt()));
    for (a, b) in [("wrong: no dividend piece", ch - q * d), ("wrong: time-left sign", -ch),
        ("wrong: per-year used per day", book * ch), ("wrong: put charm = call charm", ch),
        ("try: q = 0, call charm", charm(s0, k, r, 0.0, s, t)), ("try: q = 0, put charm", put_charm(s0, k, r, 0.0, s, t)),
        ("try: sigma = 0.40", charm(s0, k, r, q, 0.40, t)), ("try: S 105, 1 month", charm(105.0, k, r, q, s, m))] {
        rows.push((a.to_string(), b));
    }
    for (name, x) in &rows { println!("{:<32} {:>13.6}", name, x); }

    let left = [("1 yr", 1.0), ("6 mo", 0.5), ("3 mo", 0.25), ("1 mo", m), ("1 wk", 7.0 / 365.0), ("1 day", day), ("1 hr", day / 24.0)];
    println!("\nshares per 100 calls   {}", left.iter().map(|(a, _)| format!("{:>6}", a)).collect::<Vec<_>>().join(" "));
    for s1 in [95.0_f64, 100.0, 105.0] {
        let v: Vec<String> = left.iter().map(|(_, tt)| format!("{:6.2}", 100.0 * delta(s1, k, r, q, s, *tt))).collect();
        println!("chart, delta at {:3.0}    {}", s1, v.join(" "));
    }
    println!("chart, Acme price      {}", (0..9).map(|i| format!("{:>6}", 80 + 5 * i)).collect::<Vec<_>>().join(" "));
    for (lab, tt) in [("charm x100, 1 yr", 1.0), ("charm x100, 3 mo", 0.25), ("charm x100, 1 mo", m)] {
        let v: Vec<String> = (0..9).map(|i| format!("{:6.2}", 100.0 * charm(80.0 + 5.0 * i as f64, k, r, q, s, tt))).collect();
        println!("{:<22} {}", lab, v.join(" "));
    }

    assert!((d - 0.586851).abs() < 5e-7, "the delta card's house number");
    assert!((ch - -0.035639).abs() < 5e-7, "the shelf's house charm");
    assert!((c_delta - ch).abs() < 1e-8, "delta bumped in time");
    assert!((c_price - ch).abs() < 1e-6, "price bumped in S and T: no delta formula used");
    assert!((c_theta - ch).abs() < 1e-8, "theta bumped in S: mixed partials agree");
    assert!((c_int - ch).abs() < 1e-7, "integral delta: no N, no d1");
    assert!((p_bump - chp).abs() < 1e-8, "put charm vs put delta bumped");
    assert!((drift_int - drift).abs() < 1e-10, "charm added up over a month = repriced drift");
    assert!((delta(s0, k, r, q, s, 1e-8) - 0.5).abs() < 1e-4, "at-the-money delta ends near one half");
    println!("ALL CHECKS PASS");
}
