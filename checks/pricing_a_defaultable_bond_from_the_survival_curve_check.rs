// A risky bond from the hazard curve -- the same check as the Python, in Rust.  Std only, no crates.
// Northwind's five-year bond: face 100, 6% annual coupon, riskless rate 5% continuously
// compounded, hazard 2% a year, recovery 40% of face paid at default.
// Compile: rustc --edition 2021 -O pricing_a_defaultable_bond_from_the_survival_curve_check.rs
const F: f64 = 100.0;
const CPN: f64 = 6.0;
const T: usize = 5;
const R: f64 = 0.40;
const RATE: f64 = 0.05;
const LAM: f64 = 0.02;
const FLAT: [(f64, f64); 1] = [(1e9, LAM)];                        // hazard curve: (end of piece, rate)
const BOOT: [(f64, f64); 3] = [(1.0, 0.019826), (3.0, 0.040440), (1e9, 0.056837)];

fn cum_hazard(curve: &[(f64, f64)], t: f64) -> f64 {              // area under the hazard from 0 to t
    let (mut area, mut start) = (0.0, 0.0);
    for &(end, lam) in curve {
        area += lam * (t.min(end) - start);
        if t <= end { return area; }
        start = end;
    }
    area
}
fn hazard(curve: &[(f64, f64)], t: f64) -> f64 { curve.iter().find(|p| t < p.0).unwrap().1 }
fn q(curve: &[(f64, f64)], t: f64) -> f64 { (-cum_hazard(curve, t)).exp() }   // survival to t
fn d(t: f64) -> f64 { (-RATE * t).exp() }                          // riskless discount factor

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64) -> f64 {       // area under f, 200 slices
    let n = 200;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn flows<G: Fn(f64) -> f64>(disc: G) -> f64 {
    (1..=T).map(|t| CPN * disc(t as f64)).sum::<f64>() + F * disc(T as f64)
}
fn closed_form(lam: f64, rec: f64) -> (f64, f64) {                  // road 1: flat curves, recovery of face
    let k = RATE + lam;
    (flows(|t| (-k * t).exp()), rec * F * lam * (1.0 - (-k * T as f64).exp()) / k)
}
fn dated_sum(curve: &[(f64, f64)], rec: f64) -> f64 {              // road 2: any curve, dated sum + quadrature
    let promised = flows(|t| d(t) * q(curve, t));
    promised + (0..T).map(|a| simpson(|t| rec * F * hazard(curve, t) * q(curve, t) * d(t), a as f64, a as f64 + 1.0)).sum::<f64>()
}
fn riskless_minus_loss(curve: &[(f64, f64)]) -> f64 {              // road 2b: riskless price less expected loss
    let still_owed = |t: f64, a: usize| -> f64 {                   // value at t of what is still promised, in year a+1
        (a + 1..=T).map(|u| CPN * (-RATE * (u as f64 - t)).exp()).sum::<f64>() + F * (-RATE * (T as f64 - t)).exp()
    };
    let loss: f64 = (0..T).map(|a| simpson(|t| hazard(curve, t) * q(curve, t) * d(t) * (still_owed(t, a) - R * F),
                                            a as f64, a as f64 + 1.0)).sum();
    flows(d) - loss
}

struct SplitMix { s: u64 }                                         // the splitmix64 generator, written out
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn default_time(curve: &[(f64, f64)], u: f64) -> f64 {             // spend the hazard budget -ln u piece by piece
    let (mut budget, mut start) = (-u.ln(), 0.0);
    for &(end, lam) in curve {
        if budget <= lam * (end - start) { return start + budget / lam; }
        budget -= lam * (end - start);
        start = end;
    }
    f64::INFINITY
}
fn rmv_value(t: f64) -> f64 {                                      // pre-default value at t, recovery of market value
    let k = RATE + LAM * (1.0 - R);
    (1..=T).filter(|&u| u as f64 > t).map(|u| CPN * (-k * (u as f64 - t)).exp()).sum::<f64>() + F * (-k * (T as f64 - t)).exp()
}
fn simulate(curve: &[(f64, f64)], n: usize, seed: u64) -> (f64, f64, f64, f64, f64) {   // road 3
    let mut rng = SplitMix { s: seed };
    let (mut tot, mut tot2, mut early, mut dif, mut dif2) = (0.0, 0.0, 0usize, 0.0, 0.0);
    for _ in 0..n {
        let tau = default_time(curve, rng.uniform());
        let mut v: f64 = (1..=T).filter(|&t| (t as f64) < tau).map(|t| CPN * d(t as f64)).sum();
        if tau > T as f64 { v += F * d(T as f64); } else {       // x: extra cash if recovery is R x value, not R x face
            early += 1;
            v += d(tau) * R * F;
            let x = d(tau) * R * (rmv_value(tau) - F);
            dif += x; dif2 += x * x;
        }
        tot += v;
        tot2 += v * v;
    }
    let (mean, dm) = (tot / n as f64, dif / n as f64);           // same draws price both rules, so their gap is sharp
    (mean, ((tot2 / n as f64 - mean * mean) / n as f64).sqrt(), early as f64 / n as f64, dm, ((dif2 / n as f64 - dm * dm) / n as f64).sqrt())
}
fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {   // halve the bracket 200 times
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn cont_yield(price: f64) -> f64 { bisect(|y| flows(|t| (-y * t).exp()) - price, 0.0, 1.0) }
fn total(p: (f64, f64)) -> f64 { p.0 + p.1 }

fn main() {
    let n = 100_000;
    let (coup, rec) = closed_form(LAM, R);
    let p1 = coup + rec;
    let (p2, p2b) = (dated_sum(&FLAT, R), riskless_minus_loss(&FLAT));
    let (p3, se3, dflt, gap, se_gap) = simulate(&FLAT, n, 2026);
    let rf = flows(d);
    let p_rmv = flows(|t| (-(RATE + LAM * (1.0 - R)) * t).exp());
    let s_rmv = p3 + gap;                                          // RMV priced on the same default dates
    let (y_rf, y1, y_rmv) = (cont_yield(rf), cont_yield(p1), cont_yield(p_rmv));
    let k = RATE + LAM;
    let e = (-k * T as f64).exp();
    let dp_dlam = -(1..=T).map(|t| CPN * t as f64 * (-k * t as f64).exp()).sum::<f64>() - T as f64 * F * e
        + R * F * ((1.0 - e) / k + LAM * (T as f64 * e / k - (1.0 - e) / (k * k)));
    let bump_lam = (total(closed_form(LAM + 1e-5, R)) - total(closed_form(LAM - 1e-5, R))) / 2e-5;
    let dp_dr = F * LAM * (1.0 - e) / k;
    let bump_r = (dated_sum(&FLAT, R + 0.01) - dated_sum(&FLAT, R - 0.01)) / 0.02;
    let b2 = dated_sum(&BOOT, R);
    let (b3, seb3, bdflt, _, _) = simulate(&BOOT, n, 44);
    let y_b = cont_yield(b2);

    let (face_rf, face_1) = (F * d(T as f64), F * e);
    let rows: Vec<(&str, f64)> = vec![("riskless coupons", rf - face_rf), ("riskless face", face_rf), ("riskless price", rf),
        ("road 1 coupons, survival-weighted", coup - face_1), ("road 1 face, survival-weighted", face_1),
        ("road 1 recovery leg", rec), ("road 1 price, closed form", p1), ("road 2 price, dated sum + Simpson", p2),
        ("road 2b riskless less expected loss", p2b), ("  expected discounted loss", rf - p2b),
        ("road 3 price, 100,000 default dates", p3), ("  standard error", se3),
        ("  share defaulting by year 5", dflt), ("  formula: 1 - Q(5)", 1.0 - q(&FLAT, 5.0)),
        ("price at yield 0, the cash added up", flows(|_| 1.0)), ("yield, riskless (cont.)", y_rf),
        ("yield, face recovery (cont.)", y1),
        ("spread, face recovery (bp)", 1e4 * (y1 - y_rf)), ("RMV price, rate r + lam(1-R)", p_rmv),
        ("RMV simulated, R x value at default", s_rmv), ("  RMV less face, simulated", gap),
        ("  RMV less face, formula", p_rmv - p1), ("  standard error of the gap", se_gap), ("RMV yield (cont.)", y_rmv),
        ("RMV spread (bp)", 1e4 * (y_rmv - y_rf)), ("dP/dlam, formula", dp_dlam), ("dP/dlam, bump", bump_lam),
        ("  per 1 bp of hazard", dp_dlam * 1e-4), ("dP/dR, formula", dp_dr), ("dP/dR, bump", bump_r),
        ("  per 10 points of recovery", dp_dr * 0.1), ("boot curve price, road 2", b2),
        ("boot curve price, road 3", b3), ("  standard error", seb3), ("  share defaulting by year 5", bdflt),
        ("boot curve spread (bp)", 1e4 * (y_b - y_rf)), ("wrong: no default at all", rf), ("wrong: no recovery", coup),
        ("wrong: recovery paid at year 5", coup + R * F * (1.0 - q(&FLAT, T as f64)) * d(T as f64)),
        ("wrong: 60% recovery for 40%", total(closed_form(LAM, 0.60)))];
    for (name, v) in &rows { println!("{:<38} {:>12.6}", name, v); }
    let w = |g: &dyn Fn(f64) -> f64| (1..=T).map(|t| format!("{:.6}", g(t as f64))).collect::<Vec<_>>().join(" ");
    println!("weights D(t), years 1..5      {}", w(&d));
    println!("weights D(t)Q(t), years 1..5  {}", w(&|t| d(t) * q(&FLAT, t)));
    println!("bars, $ riskless {:.2} {:.2}  risky {:.2} {:.2} {:.2}", rf - face_rf, face_rf, coup - face_1, face_1, rec);
    let line = |label: &str, vals: Vec<f64>, p: usize| {
        println!("{}{}", label, vals.iter().map(|v| format!(" {:6.*}", p, v)).collect::<String>());
    };
    let hz: Vec<f64> = (0..11).map(|i| 0.01 * i as f64).collect();
    line("chart, hazard %     ", hz.iter().map(|h| 100.0 * h).collect(), 0);
    line("chart, price RFV    ", hz.iter().map(|&h| total(closed_form(h, R))).collect(), 2);
    line("chart, price RMV    ", hz.iter().map(|&h| flows(|t| (-(RATE + h * (1.0 - R)) * t).exp())).collect(), 2);
    let rc: Vec<f64> = (0..9).map(|i| 0.1 * i as f64).collect();
    line("chart, recovery %   ", rc.iter().map(|x| 100.0 * x).collect(), 0);
    line("chart, spread RFV bp", rc.iter().map(|&x| 1e4 * (cont_yield(total(closed_form(LAM, x))) - y_rf)).collect(), 2);
    line("chart, spread RMV bp", rc.iter().map(|&x| 1e4 * LAM * (1.0 - x)).collect(), 2);

    assert!((p2 - p1).abs() < 1e-8, "dated sum with quadrature must land on the closed form");
    assert!((p2b - p1).abs() < 1e-6, "riskless-less-loss road must land on the closed form");
    assert!((p3 - p1).abs() < 3.0 * se3, "simulation within three standard errors");
    assert!((gap - (p_rmv - p1)).abs() < 3.0 * se_gap, "RMV: simulated gap between the rules vs the adjusted rate");
    assert!((y_rmv - (RATE + LAM * (1.0 - R))).abs() < 1e-9, "RMV yield is r + lam(1 - R)");
    assert!((bump_lam - dp_dlam).abs() < 1e-5, "hazard sensitivity: formula vs bump");
    assert!((b3 - b2).abs() < 3.0 * seb3, "stepped curve: simulation vs dated sum");
    println!("ALL CHECKS PASS");
}
