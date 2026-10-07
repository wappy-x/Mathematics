// Implied correlation from a spread option -- the same check as the Python file, in Rust.
// Standard library only, no crates.  The normal CDF is a series, and the root finders, the
// integrator and the random numbers are written out here.
use std::f64::consts::PI;
const F1: f64 = 100.0; const F2: f64 = 90.0; const S1: f64 = 0.30; const S2: f64 = 0.25;
const T: f64 = 0.5; const R: f64 = 0.05;
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }      // bell-curve height at x
fn n_cdf(x: f64) -> f64 {                // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + phi(x) * total
}
fn black(f: f64, k: f64, w: f64) -> f64 { // undiscounted Black call, total swing w = vol * sqrt(T)
    if w < 1e-12 { return (f - k).max(0.0); }
    let a = ((f / k).ln() + 0.5 * w * w) / w;
    f * n_cdf(a) - k * n_cdf(a - w)
}
fn disc() -> f64 { (-R * T).exp() }
fn spread_vol(rho: f64, a: f64, b: f64) -> f64 { (a * a + b * b - 2.0 * rho * a * b).max(0.0).sqrt() }
fn margrabe(rho: f64, a: f64, b: f64) -> f64 { disc() * black(F1, F2, spread_vol(rho, a, b) * T.sqrt()) }
fn kirk(rho: f64, k: f64) -> f64 {        // crude plus strike treated as one lognormal leg
    let b = F2 / (F2 + k);
    let v = (S1 * S1 - 2.0 * rho * S1 * S2 * b + S2 * S2 * b * b).max(0.0).sqrt();
    disc() * black(F1, F2 + k, v * T.sqrt())
}
fn by_integral(rho: f64, k: f64, n: usize) -> f64 {   // road 4: fix crude's shock z; gasoline is lognormal
    let (a, bb) = (-8.0, 8.0); let h = (bb - a) / n as f64; let st = T.sqrt();
    let f = |z: f64| {
        let crude = F2 * (-0.5 * S2 * S2 * T + S2 * st * z).exp();
        let gas = F1 * (-0.5 * rho * rho * S1 * S1 * T + rho * S1 * st * z).exp();
        black(gas, crude + k, S1 * (1.0 - rho * rho).max(0.0).sqrt() * st) * phi(z)
    };
    let mut tot = f(a) + f(bb);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    disc() * tot * h / 3.0
}
fn bisect(price: &dyn Fn(f64) -> f64, quote: f64, mut lo: f64, mut hi: f64, steps: usize) -> f64 {
    for _ in 0..steps { let mid = 0.5 * (lo + hi); if price(mid) > quote { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
fn implied_rho(quote: f64, price: &dyn Fn(f64) -> f64) -> Option<f64> {   // refuse quotes outside the range
    if !(price(1.0) <= quote && quote <= price(-1.0)) { return None; }
    Some(bisect(price, quote, -1.0, 1.0, 50))
}
fn corr_vega(rho: f64) -> f64 {           // dC/drho = -vega s1 s2 / sigma
    let v = spread_vol(rho, S1, S2); let a = ((F1 / F2).ln() + 0.5 * v * v * T) / (v * T.sqrt());
    -disc() * F1 * phi(a) * T.sqrt() * S1 * S2 / v
}
fn txt(v: Option<f64>) -> String { match v { None => "none".to_string(), Some(x) => format!("{:.6}", x) } }
struct Lcg(u64);
impl Lcg {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn pair(&mut self) -> (f64, f64) {    // Box-Muller: two independent normals
        let (u1, u2) = (self.unif(), self.unif()); let rad = (-2.0 * u1.ln()).sqrt();
        (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2).sin())
    }
}
fn main() {
    let d = disc();
    let m = |p: f64| margrabe(p, S1, S2);
    let q = (m(0.5) * 1e6).round() / 1e6;                                // the screen quote, six decimals
    println!("house crack: gasoline 100, crude 90, vols 30% and 25%, six months, 5%");
    let mut rows: Vec<(&str, f64)> = vec![("discount D", d), ("floor D (F1 - F2)", d * (F1 - F2)),
        ("spread vol at rho 0.5", spread_vol(0.5, S1, S2)), ("quote = Margrabe at rho 0.5", q),
        ("price at rho +1 (lowest)", m(1.0)), ("  same by integral", by_integral(1.0, 0.0, 20000)),
        ("price at rho -1 (highest)", m(-1.0)), ("  same by integral", by_integral(-1.0, 0.0, 20000))];
    let r1 = implied_rho(q, &m).unwrap();
    let vimp = bisect(&|v: f64| d * black(F1, F2, v * T.sqrt()), q, 1.0, 1e-9, 60);   // price rises with vol
    let r2 = (S1 * S1 + S2 * S2 - vimp * vimp) / (2.0 * S1 * S2);
    let (mut x, mut its) = (0.0_f64, 0);
    while its < 50 { its += 1; let step = (m(x) - q) / corr_vega(x); x -= step; if step.abs() < 1e-13 { break; } }
    let r4 = implied_rho(q, &|p| by_integral(p, 0.0, 2000)).unwrap();
    let (cv, bump) = (corr_vega(0.5), (m(0.501) - m(0.499)) / 0.002);
    rows.extend([("1 implied rho, bisection", r1), ("  implied spread vol", vimp), ("2 rho from the spread vol", r2),
        ("3 implied rho, Newton from 0", x), ("  Newton steps", its as f64), ("4 implied rho, integral price", r4),
        ("corr vega dC/drho at 0.5", cv), ("  same by bump", bump), ("rho moved by a 0.01 price error", 0.01 / cv.abs())]);
    let w5 = spread_vol(0.5, S1, S2) * T.sqrt(); let a5 = ((F1 / F2).ln() + 0.5 * w5 * w5) / w5;
    rows.extend([("d1 at rho 0.5", a5), ("d2 = d1 - sigma sqrt T", a5 - w5), ("N(d1)", n_cdf(a5)), ("N(d2)", n_cdf(a5 - w5))]);
    for (name, v) in &rows { println!("  {:<32} {:>11.6}", name, v); }
    println!("  by hand: s1^2 + s2^2 {:.6}   2 s1 s2 {:.6}   vimp^2 {:.6}", S1 * S1 + S2 * S2, 2.0 * S1 * S2, vimp * vimp);
    println!("  spread vol can run from |s1 - s2| {:.6} to s1 + s2 {:.6}", (S1 - S2).abs(), S1 + S2);
    println!("  quote 20.00: rho {}    quote 9.70: rho {}", txt(implied_rho(20.0, &m)), txt(implied_rho(9.70, &m)));
    println!("\nchart: price against correlation, quote lines 13.15 and 20.00");
    let grid: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    println!("  rho    {}", grid.iter().map(|g| format!("{:6.2}", g)).collect::<Vec<_>>().join(" "));
    println!("  price  {}", grid.iter().map(|g| format!("{:6.2}", m(*g))).collect::<Vec<_>>().join(" "));
    let mut rng = Lcg(20260927);
    let pay = |z1: f64, z2: f64| {        // the spread's payoff for one pair of shocks, at rho 0.5
        let w2 = 0.5 * z1 + 0.75_f64.sqrt() * z2;
        (F1 * (-0.5 * S1 * S1 * T + S1 * T.sqrt() * z1).exp() - F2 * (-0.5 * S2 * S2 * T + S2 * T.sqrt() * w2).exp()).max(0.0)
    };
    let (paths, mut tot, mut tot2) = (500000usize, 0.0_f64, 0.0_f64);    // road 5: each draw used twice, z and -z
    for _ in 0..paths { let (z1, z2) = rng.pair(); let p = 0.5 * (pay(z1, z2) + pay(-z1, -z2)); tot += p; tot2 += p * p; }
    let np = paths as f64;
    let mc = d * tot / np; let se = d * (tot2 / np - (tot / np).powi(2)).sqrt() / np.sqrt();
    println!("\nsimulation, {} mirrored pairs: price {:.6}  std error {:.6}  implied rho {:.6}", paths, mc, se, implied_rho(mc, &m).unwrap());
    let (days, true_rho, dt) = (126usize, 0.70_f64, 1.0 / 252.0_f64);  // a six-month history of daily moves
    let mut rng = Lcg(777); let (mut xs, mut ys) = (Vec::new(), Vec::new());
    for _ in 0..days {
        let (z1, z2) = rng.pair();
        xs.push(S1 * dt.sqrt() * z1); ys.push(S2 * dt.sqrt() * (true_rho * z1 + (1.0 - true_rho * true_rho).sqrt() * z2));
    }
    let nd = days as f64;
    let (mx, my) = (xs.iter().sum::<f64>() / nd, ys.iter().sum::<f64>() / nd);
    let sxy: f64 = xs.iter().zip(&ys).map(|(a, b)| (a - mx) * (b - my)).sum();
    let sxx: f64 = xs.iter().map(|a| (a - mx).powi(2)).sum(); let syy: f64 = ys.iter().map(|b| (b - my).powi(2)).sum();
    let rr = sxy / (sxx * syy).sqrt(); let half = 1.96 / (nd - 3.0).sqrt();
    let (lo, hi) = ((rr.atanh() - half).tanh(), (rr.atanh() + half).tanh());
    println!("realised, {} days drawn at rho {:.2}: vols {:.4} {:.4}  rho {:.4}  95% band {:.4} to {:.4}", days, true_rho,
        (sxx / (nd - 1.0) / dt).sqrt(), (syy / (nd - 1.0) / dt).sqrt(), rr, lo, hi);
    println!("  price at realised rho {:.6}   quote minus that {:.6}", m(rr), q - m(rr));
    println!("\nimplied rho from the same quote, by the vols assumed (gasoline down, crude across)");
    println!("  gas \\ crude    0.23      0.25      0.27");
    for a in [0.26_f64, 0.28, 0.30, 0.32, 0.34] {
        let cells: Vec<String> = [0.23_f64, 0.25, 0.27].iter().map(|b| format!("{:8.4}", (a * a + b * b - vimp * vimp) / (2.0 * a * b))).collect();
        println!("  {:.2}      {}", a, cells.join("  "));
    }
    let need = (0.55_f64.powi(2) + S2 * S2 - vimp * vimp) / (2.0 * 0.55 * S2);
    println!("  gasoline vol 0.55: rho needed {:.4}, solver says {}", need, txt(implied_rho(q, &|p| margrabe(p, 0.55, S2))));
    let kq = (kirk(0.5, 10.0) * 1e6).round() / 1e6;
    let (rk, rx) = (implied_rho(kq, &|p| kirk(p, 10.0)).unwrap(), implied_rho(kq, &|p| by_integral(p, 10.0, 2000)).unwrap());
    println!("\nstrike 10: Kirk quote {:.6}  rho by Kirk {:.6}  rho by exact integral {:.6}", kq, rk, rx);
    println!("\nwhat breaks");
    let und = bisect(&|p| black(F1, F2, spread_vol(p, S1, S2) * T.sqrt()), q, -1.0, 1.0, 50);
    let wrong: Vec<(&str, f64)> = vec![("no 2 on the cross term", (S1 * S1 + S2 * S2 - vimp * vimp) / (S1 * S2)),
        ("plus sign on the cross term", (vimp * vimp - S1 * S1 - S2 * S2) / (2.0 * S1 * S2)),
        ("forgot the discount D", und), ("quote 20.00, bare solver", bisect(&m, 20.0, -1.0, 1.0, 50))];
    for (name, v) in &wrong { println!("  {:<32} {:>11.6}", name, v); }
    assert!((r1 - 0.5).abs() < 1e-6 && (r2 - r1).abs() < 1e-6 && (x - r1).abs() < 1e-9, "three roads on Margrabe");
    assert!((r4 - r1).abs() < 1e-6, "a price built without Margrabe gives the same correlation");
    assert!((by_integral(-1.0, 0.0, 20000) - m(-1.0)).abs() < 1e-4 && (by_integral(1.0, 0.0, 20000) - m(1.0)).abs() < 1e-4, "bounds by two roads");
    assert!((mc - q).abs() < 3.0 * se, "simulated spread payoff matches the quote within noise");
    assert!((cv - bump).abs() < 1e-4 && cv < 0.0, "correlation vega by formula and by bump, and negative");
    assert!(implied_rho(20.0, &m).is_none() && implied_rho(9.70, &m).is_none() && need > 1.0, "no correlation outside the range");
    assert!(lo < true_rho && true_rho < hi, "realised band covers the correlation the history was drawn with");
    println!("ALL CHECKS PASS");
}
