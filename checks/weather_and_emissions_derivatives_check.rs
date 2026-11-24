// Weather and emissions derivatives -- the same check as the Python script, in
// Rust.  Standard library only, no crates: the normal CDF, the integrator and
// the random numbers are written here, with the same seed and the same order of
// operations, so the output matches line for line.
use std::f64::consts::PI;

const R: f64 = 0.03; const BASE: f64 = 65.0; const K: f64 = 3000.0; const TICK: f64 = 5000.0;
const CAP: f64 = 2.0e6; const TW: f64 = 0.5; const LIM: f64 = CAP / TICK;
const DAYS: usize = 151; const M: f64 = 57.0; const B: f64 = 15.0; const PHI: f64 = 0.7;
const SD_A: f64 = 7.0; const SD_W: f64 = 1.5; const WARM: f64 = 0.10;

fn n_cdf(x: f64) -> f64 {                   // normal CDF, Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut i) = (x, x, 1.0_f64);
    while t.abs() > 1e-17 { i += 2.0; t *= x * x / i; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn tot<I: Iterator<Item = f64>>(xs: I) -> f64 { let mut t = 0.0; for x in xs { t += x; } t }
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {          // xorshift64: own random numbers
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 {            // Box-Muller, one normal per call
        let a = (-2.0 * self.uniform().ln()).sqrt();
        a * (2.0 * PI * self.uniform()).cos()
    }
}
fn row(label: &str, v: f64, d: usize) { println!("{:<44}{:>16.*}", label, d, v); }
fn hdd(ts: &[f64]) -> f64 { tot(ts.iter().map(|t| (BASE - t).max(0.0))) }
fn cdd(ts: &[f64]) -> f64 { tot(ts.iter().map(|t| (t - BASE).max(0.0))) }
fn pay(x: f64) -> f64 { TICK * (x - K).max(0.0).min(LIM) }     // the capped call, in USD
fn seasonal(d: usize) -> f64 { M - B * (2.0 * PI * (d as f64 - 76.0) / 365.0).cos() }
fn winter(rng: &mut Rng, shift: f64, start: usize, days: usize) -> Vec<f64> {
    let (lvl, mut a, mut ts) = (SD_W * rng.gauss(), SD_A * rng.gauss(), Vec::with_capacity(days));
    for d in 0..days {
        a = PHI * a + SD_A * (1.0 - PHI * PHI).sqrt() * rng.gauss();
        ts.push(seasonal(start + d) + shift + lvl + a);
    }
    ts
}
fn g(m: f64, s: f64, k: f64) -> f64 { let z = (m - k) / s; (m - k) * n_cdf(z) + s * phi(z) }
fn capped_normal(m: f64, s: f64) -> f64 { TICK * (g(m, s, K) - g(m, s, K + LIM)) }
fn simpson<F: Fn(f64) -> f64>(f: &F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h / 3.0 * (f(a) + f(b) + tot((1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h))))
}
fn capped_simpson(m: f64, s: f64) -> f64 {
    let f = |x: f64| pay(x) * phi((x - m) / s) / s;
    simpson(&f, K, K + LIM, 2000) + simpson(&f, K + LIM, (m + 12.0 * s).max(K + LIM + 1.0), 2000)
}
fn join(xs: &[f64], w: usize) -> String { xs.iter().map(|x| format!("{:w$.0}", x, w = w)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mut rng = Rng(88172645463325252);
    // 1. one shoulder-season week by hand
    let week = [58.0, 62.0, 67.0, 71.0, 64.0, 55.0, 60.0];
    println!("week, daily mean F  {}", join(&week, 4));
    println!("week, HDD           {}", join(&week.map(|t: f64| (BASE - t).max(0.0)), 4));
    println!("week, CDD           {}", join(&week.map(|t: f64| (t - BASE).max(0.0)), 4));
    row("week: HDD total", hdd(&week), 2); row("week: CDD total", cdd(&week), 2);
    let wsum = tot(week.iter().map(|t| BASE - t));
    row("week: sum of (65 - T)", wsum, 2);
    println!("one day: high 72, low 52, mean {:.1}, HDD {:.1}", (72.0 + 52.0) / 2.0, (BASE - (72.0 + 52.0) / 2.0).max(0.0));
    // 2. thirty simulated past winters, 1996-97 to 2025-26
    let (mut idx, mut gap) = (Vec::new(), 0.0_f64);
    for y in 0..30 {
        let ts = winter(&mut rng, WARM * (y as f64 - 30.0), 0, DAYS);
        idx.push(hdd(&ts));
        gap = gap.max((hdd(&ts) - cdd(&ts) - tot(ts.iter().map(|t| BASE - t))).abs());
    }
    row("identity: max |HDD - CDD - sum(65 - T)|", gap, 9);
    let (ybar, xbar) = (14.5, tot(idx.iter().copied()) / 30.0);
    let slope = tot(idx.iter().enumerate().map(|(y, x)| (y as f64 - ybar) * (x - xbar)))
        / tot((0..30).map(|y| (y as f64 - ybar).powf(2.0)));
    let det: Vec<f64> = idx.iter().enumerate().map(|(y, x)| x + slope * (30.0 - y as f64)).collect();
    let (sy, syy) = (tot((0..30).map(|y| y as f64)), tot((0..30).map(|y| (y * y) as f64)));
    let (sx, sxy) = (tot(idx.iter().copied()), tot(idx.iter().enumerate().map(|(y, x)| y as f64 * x)));
    let dn = 30.0 * syy - sy * sy; let (b0, b1) = ((sx * syy - sy * sxy) / dn, (30.0 * sxy - sy * sx) / dn); // road 2: line by Cramer's rule
    println!("chart, raw index  {}", idx.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, trend line {}", (0..30).map(|y| format!("{:.0}", xbar + slope * (y as f64 - ybar))).collect::<Vec<_>>().join(" "));
    row("raw index: mean", xbar, 2); row("trend: HDD per year, fitted", slope, 2);
    row("trend: HDD per year, true -0.10 x 151", -WARM * DAYS as f64, 2);
    let mu = tot(det.iter().copied()) / 30.0;
    let sd = (tot(det.iter().map(|x| (x - mu).powf(2.0))) / 29.0).sqrt();
    row("detrended: mean", mu, 2); row("detrended: standard deviation", sd, 2);
    let mut pays: Vec<f64> = det.iter().copied().filter(|&x| x > K).collect();
    pays.sort_by(|a, b| b.partial_cmp(a).unwrap());
    println!("burn: paying winters {}", pays.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(" "));
    println!("burn: payoffs USD k  {}", pays.iter().map(|&x| format!("{:.1}", pay(x) / 1000.0)).collect::<Vec<_>>().join(" "));
    row("burn: sum of payoffs, USD k", tot(pays.iter().map(|&x| pay(x))) / 1000.0, 1);
    let (z1, z2) = ((mu - K) / sd, (mu - K - LIM) / sd);
    println!("fit: z {:.4} {:.4}, excess over 3,000 {:.4}, over 3,400 {:.4}", z1, z2, g(mu, sd, K), g(mu, sd, K + LIM));
    let above = |k: f64| det.iter().filter(|&&x| x > k).count();
    println!("detrended: winters above 3,000, 3,200, 3,400: {}, {}, {}", above(K), above(3200.0), above(K + LIM));
    // 3. the price, five roads
    let dd = (-R * TW).exp();
    let burn_p: Vec<f64> = det.iter().map(|&x| pay(x)).collect();
    let burn = dd * tot(burn_p.iter().copied()) / 30.0;
    let bmean = tot(burn_p.iter().copied()) / 30.0;
    let bsd = (tot(burn_p.iter().map(|p| (p - bmean).powf(2.0))) / 29.0).sqrt();
    let (fit, fit_s) = (dd * capped_normal(mu, sd), dd * capped_simpson(mu, sd));
    row("cap in degree-days, 2,000,000 / 5,000", LIM, 2); row("discount e^(-0.03 x 0.5)", dd, 6);
    row("price 1 burn, 30 detrended winters", burn, 2); row("price 2 normal fit, formula", fit, 2);
    row("price 3 normal fit, Simpson integral", fit_s, 2);
    let sdt = (SD_A.powf(2.0) + SD_W.powf(2.0)).sqrt();
    let mean_ex = tot((0..DAYS).map(|d| g(BASE, sdt, seasonal(d))));
    let var_ex = (DAYS as f64 * SD_W).powf(2.0)
        + SD_A.powf(2.0) * tot((0..DAYS).flat_map(|i| (0..DAYS).map(move |j| PHI.powf((i as f64 - j as f64).abs()))));
    let true_mc: Vec<f64> = (0..20000).map(|_| hdd(&winter(&mut rng, 0.0, 0, DAYS))).collect();
    let tm = tot(true_mc.iter().copied()) / 20000.0;
    let tp: Vec<f64> = true_mc.iter().map(|&x| pay(x)).collect();
    let tpm = dd * tot(tp.iter().copied()) / 20000.0;
    let tse = dd * (tot(tp.iter().map(|p| (p - tpm / dd).powf(2.0))) / 19999.0 / 20000.0).sqrt();
    row("model: exact mean index", mean_ex, 2); row("model: index sd, if no day is above 65F", var_ex.sqrt(), 2);
    row("model: mean index, 20,000 winters", tm, 2);
    row("price 4 model, 20,000 fresh winters", tpm, 2); row("price 4 standard error", tse, 2);
    let p5 = dd * capped_normal(mean_ex, var_ex.sqrt());
    row("price 5 model moments, normal formula", p5, 2);
    row("burn: sd of payoff", bsd, 2); row("seller's quote, burn + 0.2 sd", burn + 0.2 * dd * bsd, 2);
    // 4. what breaks
    let raw_burn = dd * tot(idx.iter().map(|&x| pay(x))) / 30.0;
    row("wrong: burn on raw winters, no detrending", raw_burn, 2);
    row("wrong: no cap, normal fit", dd * TICK * g(mu, sd, K), 2); row("wrong: no discount, burn", burn / dd, 2);
    row("wrong: payoff at the mean winter", dd * pay(mu), 2);
    // 5. carbon: an allowance costs nothing to keep and can be banked, so it carries
    let (s, t, vol) = (70.0_f64, 1.0_f64, 0.5_f64);
    let f = s * (R * t).exp();
    row("EUA forward, 70 e^0.03", f, 4);
    for n in [2.0_f64, 3.0] { row(&format!("EUA forward, {} years", n), s * (R * n).exp(), 4); }
    row("carry trade profit if quoted 74.00", 74.0 - f, 4); row("reverse trade profit if quoted 70.00", f - 70.0, 4);
    let mut sims = Vec::with_capacity(50000);
    for _ in 0..50000 {
        let z = rng.gauss(); let m = (R - 0.5 * vol * vol) * t;
        sims.push(0.5 * s * ((m + vol * t.sqrt() * z).exp() + (m - vol * t.sqrt() * z).exp()));
    }
    let ms = tot(sims.iter().copied()) / 50000.0;
    let mse = (tot(sims.iter().map(|v| (v - ms).powf(2.0))) / 49999.0 / 50000.0).sqrt();
    row("EUA forward, simulated average", ms, 4); row("EUA simulation standard error", mse, 4);
    let (mut lo, mut hi, debt) = (0.0_f64, 10.0 * s, (0..12).fold(s, |a, _| a * (R / 12.0).exp())); // road 2: the loan, rolled monthly
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if mid - debt > 0.0 { hi = mid; } else { lo = mid; } }
    let fb = (lo + hi) / 2.0; row("EUA forward, carry ledger break-even", fb, 4); // buy, bank, deliver at the quote, repay
    row("wrong: 70 x 1.03, simple interest", s * 1.03, 4);
    row("clean spark: 0.37 t/MWh x forward", 0.37 * f, 2);
    let (summer, cmean) = (winter(&mut rng, 0.0, 181, 153), tot((181..334).map(|d| g(seasonal(d), sdt, BASE))));
    println!("summer CDD index, May-Sep: simulated {:.2}, model mean {:.2}", cdd(&summer), cmean); // CDD: 1 May to 30 September
    // 6. try changing
    row("try: strike 3,200, burn", dd * tot(det.iter().map(|&x| TICK * (x - 3200.0).max(0.0).min(LIM))) / 30.0, 2);
    row("try: cap 1 million, normal fit", dd * TICK * (g(mu, sd, K) - g(mu, sd, K + 200.0)), 2);
    row("try: EUA rate 4 percent", s * 0.04_f64.exp(), 4);
    let xs: Vec<f64> = (0..11).map(|i| 2600.0 + 100.0 * i as f64).collect();
    println!("chart, index at expiry {}", xs.iter().map(|x| format!("{:5.0}", x)).collect::<Vec<_>>().join(" "));
    println!("chart, payoff USD k    {}", xs.iter().map(|&x| format!("{:5.0}", pay(x) / 1000.0)).collect::<Vec<_>>().join(" "));

    assert!((wsum - 18.0).abs() < 1e-12 && (hdd(&week) - cdd(&week) - 18.0).abs() < 1e-12);
    assert!(gap < 1e-9, "HDD - CDD must equal sum(65 - T) every winter");
    assert!((fit - fit_s).abs() < 1e-3, "normal-fit formula against Simpson integral");
    assert!((tm - mean_ex).abs() < 3.0 * (var_ex / 20000.0).sqrt(), "simulated mean against the exact model mean");
    assert!((f - 72.1318).abs() < 1e-4 && (fb - f).abs() < 1e-9, "spec's forward 70 e^0.03 = 72.13, where the carry ledger breaks even");
    assert!((ms - f).abs() < 3.0 * mse, "simulated EUA average within three standard errors of the carry forward");
    assert!((p5 - tpm).abs() < 3.0 * tse, "model-moment normal price within three standard errors of the simulation");
    assert!(raw_burn > burn, "undetrended history must overprice the call in a warming climate");
    assert!((slope - b1).abs() < 1e-9 && (mu - (b0 + 30.0 * b1)).abs() < 1e-6, "trend by Cramer's rule; moved mean = the line at 2026-27");
    assert!((sd - (tot(idx.iter().enumerate().map(|(y, x)| (x - b0 - b1 * y as f64).powf(2.0))) / 29.0).sqrt()).abs() < 1e-6, "moved sd = sd of misses from the line");
    assert!((dd - 0.985112).abs() < 1e-6 && (burn - 9310.7e3 / 30.0 * 0.985112).abs() < 2.0, "burn price against the hand table");
    println!("ALL CHECKS PASS");
}
