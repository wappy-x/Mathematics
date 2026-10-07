// Vanna -- the same check as the Python, in Rust.  std only, no crates: the
// normal CDF (a power series), the integrator (Simpson's rule) and the root
// finder (bisection) are written here.  House market: Acme at S = 100, strike
// K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year.  Five roads to vanna.
const S: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIGMA: f64 = 0.20;
const T: f64 = 1.0;
const SKEW: f64 = 0.005; // assumed: vol falls 0.5 points per $1 rise

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }

fn n_cdf(x: f64) -> f64 { // bell-curve area left of x, by its power series
    if x.abs() > 6.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-18 {
        n += 1.0;
        term *= -x * x / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * std::f64::consts::PI).sqrt()
}

fn d12(s: f64, v: f64, t: f64, qq: f64, k: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (R - qq + 0.5 * v * v) * t) / (v * t.sqrt());
    (d1, d1 - v * t.sqrt())
}

fn delta(s: f64, v: f64, t: f64, k: f64) -> f64 { (-Q * t).exp() * n_cdf(d12(s, v, t, Q, k).0) }
fn put_delta(s: f64, v: f64) -> f64 { -(-Q * T).exp() * n_cdf(-d12(s, v, T, Q, K).0) }
fn vega(s: f64, v: f64, t: f64) -> f64 { s * (-Q * t).exp() * phi(d12(s, v, t, Q, K).0) * t.sqrt() }
fn gamma(s: f64, v: f64, k: f64) -> f64 { (-Q * T).exp() * phi(d12(s, v, T, Q, k).0) / (s * v * T.sqrt()) }

fn vanna(s: f64, v: f64, t: f64, qq: f64, k: f64) -> f64 { // road 1: the formula
    let (d1, d2) = d12(s, v, t, qq, k);
    -(-qq * t).exp() * phi(d1) * d2 / v
}

fn call_by_integral(s: f64, v: f64) -> f64 { // price with no N at all: Simpson over the bell curve
    let n = 4000;
    let lo = ((K / s).ln() - (R - Q - 0.5 * v * v) * T) / (v * T.sqrt()); // below this draw, no payoff
    let (hi, h) = (lo + 12.0, 12.0 / n as f64);
    let f = |z: f64| (s * ((R - Q - 0.5 * v * v) * T + v * T.sqrt() * z).exp() - K) * (-0.5 * z * z).exp();
    let mut tot = f(lo) + f(hi);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    (-R * T).exp() * tot * h / 3.0 / (2.0 * std::f64::consts::PI).sqrt()
}

fn main() {
    let (d1, d2) = d12(S, SIGMA, T, Q, K);
    let v1 = vanna(S, SIGMA, T, Q, K);
    let v2 = (delta(S, SIGMA + 1e-4, T, K) - delta(S, SIGMA - 1e-4, T, K)) / 2e-4; // delta bumped in vol
    let v3 = (vega(S + 0.01, SIGMA, T) - vega(S - 0.01, SIGMA, T)) / 0.02; // vega bumped in spot
    let (a, b) = (0.05, 0.0005); // price bumped both ways
    let v4 = (call_by_integral(S + a, SIGMA + b) - call_by_integral(S + a, SIGMA - b)
        - call_by_integral(S - a, SIGMA + b) + call_by_integral(S - a, SIGMA - b)) / (4.0 * a * b);
    let v5 = (put_delta(S, SIGMA + 1e-4) - put_delta(S, SIGMA - 1e-4)) / 2e-4; // the put's delta

    let (mut lo_s, mut hi_s) = (80.0, 120.0); // zero of vanna, by bisection
    for _ in 0..100 {
        let mid = 0.5 * (lo_s + hi_s);
        if vanna(mid, SIGMA, T, Q, K) > 0.0 { lo_s = mid } else { hi_s = mid }
    }
    let zero_closed = K * (-(R - Q - 0.5 * SIGMA * SIGMA) * T).exp();
    let (mut x, mut y) = (80.0, 120.0); // top of vega, by ternary search
    for _ in 0..200 {
        let (m1, m2) = (x + (y - x) / 3.0, y - (y - x) / 3.0);
        if vega(m1, SIGMA, T) < vega(m2, SIGMA, T) { x = m1 } else { y = m2 }
    }
    let dl = |s: f64, v: f64| delta(s, v, T, K);
    let vg = |s: f64| vega(s, SIGMA, T);
    let price = S * (-Q * T).exp() * n_cdf(d1) - K * (-R * T).exp() * n_cdf(d2);
    let mut rows: Vec<(String, String)> = vec![
        ("d1, d2".into(), format!("{:.6}  {:.6}", d1, d2)),
        ("phi(d1), e^-qT, their product".into(),
         format!("{:.6}  {:.6}  {:.6}", phi(d1), (-Q * T).exp(), (-Q * T).exp() * phi(d1))),
        ("call price, formula N".into(), format!("{:.6}", price)),
        ("call price, Simpson integral".into(), format!("{:.6}", call_by_integral(S, SIGMA))),
        ("delta, vega, gamma".into(), format!("{:.6}  {:.6}  {:.6}", dl(S, SIGMA), vg(S), gamma(S, SIGMA, K))),
        ("road 1 formula".into(), format!("{:.6}", v1)),
        ("road 2 delta bumped in vol".into(), format!("{:.6}", v2)),
        ("road 3 vega bumped in spot".into(), format!("{:.6}", v3)),
        ("road 4 price bumped both ways".into(), format!("{:.6}", v4)),
        ("road 5 put delta bumped in vol".into(), format!("{:.6}", v5)),
        ("d1 and delta at $100, 30% vol".into(), format!("{:.6}  {:.6}", d12(S, 0.30, T, Q, K).0, dl(S, 0.30))),
        ("delta at 19.5% / 20.5% vol".into(), format!("{:.6}  {:.6}", dl(S, 0.195), dl(S, 0.205))),
        ("  change, and vanna x 0.01".into(), format!("{:.6}  {:.6}", dl(S, 0.205) - dl(S, 0.195), v1 * 0.01)),
        ("vega at $99.50 / $100.50".into(), format!("{:.6}  {:.6}", vg(S - 0.5), vg(S + 0.5))),
        ("  change, and vanna x 1".into(), format!("{:.6}  {:.6}", vg(S + 0.5) - vg(S - 0.5), v1)),
        ("one-sided: delta 20% -> 21% vol".into(), format!("{:.6}", dl(S, 0.21) - dl(S, 0.20))),
        ("one-sided: vega $100 -> $101".into(), format!("{:.6}", vg(S + 1.0) - vg(S))),
        ("vanna zero, bisection".into(), format!("{:.6}", lo_s)),
        ("vanna zero, K e^-(r-q-sig^2/2)T".into(), format!("{:.6}", zero_closed)),
        ("vega top, ternary search".into(), format!("{:.6}", x)),
        ("vanna at $80, $120".into(), format!("{:.6}  {:.6}", vanna(80.0, SIGMA, T, Q, K), vanna(120.0, SIGMA, T, Q, K))),
    ];
    for (k, s_k) in [(80.0, "80 put"), (100.0, "100 call"), (120.0, "120 call")] {
        let (g, va) = (gamma(S, SIGMA, k), vanna(S, SIGMA, T, Q, k));
        rows.push((format!("skew {}: gamma, vanna, x skew", s_k),
                   format!("{:.6}  {:.6}  {:.6}  {:+.0}%", g, va, -va * SKEW, -va * SKEW / g * 100.0)));
    }
    let (d_now, d_after) = (delta(S, SIGMA, T, 120.0), delta(S + 5.0, SIGMA - 5.0 * SKEW, T, 120.0));
    let (g120, va120) = (gamma(S, SIGMA, 120.0), vanna(S, SIGMA, T, Q, 120.0));
    let (d1q, rest) = (-(-Q * T).exp() * phi(d1) * d1 / SIGMA, -phi(d1) * d2 / SIGMA);
    rows.push(("120 call, $5 up, vol 20% -> 17.5%".into(),
               format!("{:.6} -> {:.6}  change {:.6}", d_now, d_after, d_after - d_now)));
    rows.push(("  gamma only / gamma + vanna".into(),
               format!("{:.6}  {:.6}", 5.0 * g120, 5.0 * g120 - 5.0 * SKEW * va120)));
    rows.push(("wrong: d1 in place of d2".into(), format!("{:.6}", d1q)));
    rows.push(("wrong: no e^-qT".into(), format!("{:.6}", rest)));
    rows.push(("try: q = 4%".into(), format!("{:.6}", vanna(S, SIGMA, T, 0.04, K))));
    rows.push(("try: sigma = 30%".into(), format!("{:.6}", vanna(S, 0.30, T, Q, K))));
    rows.push(("try: T = 3 months".into(), format!("{:.6}", vanna(S, SIGMA, 0.25, Q, K))));
    for (name, val) in &rows { println!("{:<36} {}", name, val); }

    let spots: Vec<f64> = (0..13).map(|i| 70.0 + 5.0 * i as f64).collect();
    let line = |name: &str, vals: Vec<String>| {
        let cells: Vec<String> = vals.iter().map(|v| format!("{:>6}", v)).collect();
        println!("{:<22}{}", name, cells.join(" "));
    };
    line("chart, Acme price", spots.iter().map(|s| format!("{:.0}", s)).collect());
    line("chart, delta at 20%", spots.iter().map(|&s| format!("{:.2}", dl(s, 0.20))).collect());
    line("chart, delta at 30%", spots.iter().map(|&s| format!("{:.2}", dl(s, 0.30))).collect());
    line("chart, vega at 20%", spots.iter().map(|&s| format!("{:.2}", vg(s))).collect());
    line("chart, vanna 1 year", spots.iter().map(|&s| format!("{:.2}", vanna(s, 0.20, T, Q, K))).collect());
    line("chart, vanna 3 months", spots.iter().map(|&s| format!("{:.2}", vanna(s, 0.20, 0.25, Q, K))).collect());

    assert!((v1 - (-0.094753)).abs() < 5e-7, "formula vs the shelf's house number");
    assert!((v2 - v1).abs() < 1e-7 && (v3 - v1).abs() < 1e-7, "both bumped readings land on the formula");
    assert!((v4 - v1).abs() < 1e-6, "price-only integral road, no N used");
    assert!((v5 - v1).abs() < 1e-7, "the put's vanna equals the call's");
    assert!((lo_s - zero_closed).abs() < 1e-9 && (x - zero_closed).abs() < 1e-5, "zero of vanna = top of vega");
    let (actual, with_vanna) = (d_after - d_now, 5.0 * g120 - 5.0 * SKEW * va120);
    assert!((actual - with_vanna).abs() < (actual - 5.0 * g120).abs(), "vanna improves the skewed hedge");
    println!("ALL CHECKS PASS");
}
