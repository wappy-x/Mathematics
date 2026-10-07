// Term premium and expectations -- the same check as term_premium_and_expectations_check.py.
// Standard library only, no crates.  Rates are decimals, continuously compounded;
// the printout shows them in percent.
// Compile: rustc --edition 2021 -O term_premium_and_expectations_check.rs -o /tmp/tp_check

fn pct(x: f64) -> String { format!("{:.4}", 100.0 * x) }
fn row(name: &str, text: String) { println!("{:<44} {}", name, text); }
fn d(t: f64, y: f64) -> f64 { (-y * t).exp() }                        // discount factor
fn fwd(a: f64, ya: f64, b: f64, yb: f64) -> f64 { (b * yb - a * ya) / (b - a) }

fn bisect<G: Fn(f64) -> f64>(g: G, mut lo: f64, mut hi: f64) -> f64 { // root finder on a sign change
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) < 0.0) == (g(mid) < 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

struct Lcg(u64);                                                        // own random numbers
impl Lcg {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.0 >> 11) as f64 / (1u64 << 53) as f64
    }
}

fn mc_premium(f: f64, cases: &[(f64, f64)], n: usize, span: f64) -> f64 {
    let mut u = Lcg(20260928);
    let mut total = 0.0;
    for _ in 0..n {
        let v = u.next();
        let mut acc = 0.0;
        let mut r = cases[cases.len() - 1].1;
        for &(p, rr) in cases { acc += p; if v < acc { r = rr; break; } }
        total += span * (f - r);                                        // excess log return, long over roll
    }
    total / n as f64 / span
}

fn one_year_fwds(curve: &[(f64, f64)]) -> Vec<f64> {
    let mut prev = (0.0, 0.0);
    curve.iter().map(|&(t, y)| { let f = fwd(prev.0, prev.1, t, y); prev = (t, y); f }).collect()
}

fn join(v: &[f64]) -> String { v.iter().map(|&x| pct(x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let (a, b, ya, yb) = (2.0_f64, 4.0_f64, 0.03_f64, 0.045_f64);
    let (d2, d4) = (d(a, ya), d(b, yb));
    let f1 = fwd(a, ya, b, yb);
    let face4 = 1_000_000.0_f64;                                        // road 2: two trades lock the rate
    let cost4 = face4 * d4;
    let face2 = cost4 / d2;
    let f2 = (face4 / face2).ln() / (b - a);
    let f3 = bisect(|f: f64| 100.0 * (a * ya).exp() * ((b - a) * f).exp() - 100.0 * (b * yb).exp(), -1.0, 1.0);
    let curve = [(1.0, 0.025), (2.0, 0.030), (3.0, 0.038), (4.0, 0.045)];
    let one_year = one_year_fwds(&curve);
    let f4 = (one_year[2] + one_year[3]) / 2.0;

    let scen = [(0.25, 0.01), (0.50, 0.04), (0.25, 0.07)];
    let big_a: f64 = scen.iter().map(|&(p, r)| p * r).sum();
    let tp = f1 - big_a;
    let mut hold = Vec::new();
    for &(p, r) in &scen {
        let long_val = (100.0 / d4) * (-(b - a) * r).exp();             // 4-year zero, sold in year 2
        let roll_val = 100.0 / d2;                                      // 2-year zero, repaid in year 2
        hold.push((p, r, long_val, roll_val, (long_val / roll_val).ln()));
    }
    let tp_hold = hold.iter().map(|h| h.0 * h.4).sum::<f64>() / (b - a);
    let tp_mc = mc_premium(f1, &scen, 200_000, b - a);
    let f0 = -scen.iter().map(|&(p, r)| p * (-(b - a) * r).exp()).sum::<f64>().ln() / (b - a);
    let f0_root = bisect(|f: f64| scen.iter().map(|&(p, r)| p * ((b - a) * (f - r)).exp()).sum::<f64>() - 1.0, -1.0, 1.0);

    let (y1, y2) = (0.05_f64, 0.04_f64);
    let finv = (d(1.0, y1) / d(2.0, y2)).ln() / 1.0;
    let inv_curve = [(1.0, 0.050), (2.0, 0.040), (3.0, 0.036), (4.0, 0.035), (5.0, 0.035)];
    let inv_fwd = one_year_fwds(&inv_curve);

    row("zero rate y(2), y(4)", format!("{} {}", pct(ya), pct(yb)));
    row("discount D(2), D(4)", format!("{:.6} {:.6}", d2, d4));
    row("D(2)/D(4)", format!("{:.6}", d2 / d4));
    row("1 forward F(2,4), weighted formula", pct(f1));
    row("2 forward, replication: cost of $1m 4y", format!("{:.2}", cost4));
    row("  2y face sold, paid back in year 2", format!("{:.2}", face2));
    row("  rate from year 2 to year 4", pct(f2));
    row("3 forward, bisection on growth", pct(f3));
    row("4 forward, mean of one-year forwards", pct(f4));
    row("chart, zero curve y(1..4)", join(&curve.iter().map(|c| c.1).collect::<Vec<_>>()));
    row("chart, one-year forwards", join(&one_year));
    for &(p, r, lv, rv, x) in &hold {
        row(&format!("scenario R = {}, p = {:.2}", pct(r), p), format!("long {:.2} roll {:.2} excess {}", lv, rv, pct(x)));
    }
    row("expected rate A = E[R]", pct(big_a));
    row("1 term premium F - A", pct(tp));
    row("2 premium, expected excess / 2 years", pct(tp_hold));
    row("3 premium, simulated, 200000 draws", pct(tp_mc));
    row("no-premium forward -ln E[e^-2R] / 2", pct(f0));
    row("  convexity gap A - F0", pct(big_a - f0));
    row("inversion y(1), y(2)", format!("{} {}", pct(y1), pct(y2)));
    row("  forward F(1,2)", pct(finv));
    row("  y(2) - y(1)", pct(y2 - y1));
    row("  (1/2)(F(1,2) - y(1))", pct(0.5 * (finv - y1)));
    for tpx in [0.01_f64, 0.0, -0.01, -0.02] {
        row(&format!("  premium {} -> expected rate", pct(tpx)), pct(finv - tpx));
    }
    row("chart, inverted zero curve y(1..5)", join(&inv_curve.iter().map(|c| c.1).collect::<Vec<_>>()));
    row("chart, inverted one-year forwards", join(&inv_fwd));
    row("wrong: average the two zero rates", pct((ya + yb) / 2.0));
    row("wrong: divide by b, not b - a", pct((b * yb - a * ya) / b));
    row("wrong: read slope y(4) - y(2) as premium", pct(yb - ya));
    row("wrong: read F as the forecast, gap", pct(f1 - big_a));
    row("try: y(4) = 5%, forward", pct(fwd(a, ya, b, 0.05)));
    row("try: y(4) = 5%, premium", pct(fwd(a, ya, b, 0.05) - big_a));
    let wide = [(0.25, 0.0), (0.50, 0.04), (0.25, 0.08)];
    row("try: scenarios 0/4/8, expected", pct(wide.iter().map(|&(p, r)| p * r).sum::<f64>()));
    row("try: scenarios 0/4/8, no-premium fwd", pct(-wide.iter().map(|&(p, r)| p * (-2.0 * r).exp()).sum::<f64>().ln() / 2.0));
    row("try: y(2) = 4.5% in the inversion, F(1,2)", pct(fwd(1.0, y1, 2.0, 0.045)));
    row("try: simulated premium, 1000 draws", pct(mc_premium(f1, &scen, 1000, b - a)));

    assert!((f1 - 0.06).abs() < 1e-12, "formula vs the card's worked 6%");
    assert!((f2 - f1).abs() < 1e-12, "replication trades land on the formula");
    assert!((f3 - f1).abs() < 1e-10, "root finder lands on the formula");
    assert!((f4 - f1).abs() < 1e-12, "one-year forwards average to the two-year forward");
    assert!((tp_hold - tp).abs() < 1e-12, "holding-return premium equals F - A");
    assert!((tp_mc - tp).abs() < 5e-4, "simulated premium within 0.05 pp");
    assert!(((y2 - y1) - 0.5 * (finv - y1)).abs() < 1e-12, "inversion identity from discount factors");
    assert!((f0_root - f0).abs() < 1e-10, "no-premium forward: closed form vs root finder");
    assert!(f0 < big_a, "with no premium the forward sits below the expectation");
    println!("ALL CHECKS PASS");
}
