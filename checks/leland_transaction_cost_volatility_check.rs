// Leland's volatility -- the same check as leland_transaction_cost_volatility_check.py, in Rust.
// Standard library only, no crates.  The bell-curve area comes from an error-function series
// written out below; the random numbers are splitmix64 and Box-Muller, as in the Python.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const T: f64 = 1.0; const R: f64 = 0.05;
const Q: f64 = 0.02; const SIG: f64 = 0.20; const K_RT: f64 = 0.002; const DAY: f64 = 1.0 / 252.0;

fn erf(x: f64) -> f64 {                         // 2/sqrt(pi) e^(-x^2) sum 2^n x^(2n+1)/(2n+1)!!
    let y = x.abs();
    if y > 6.0 { return x.signum(); }
    let (mut term, mut sum, mut n) = (y, y, 0.0);
    while term > 1e-17 * sum { term *= 2.0 * y * y / (2.0 * n + 3.0); sum += term; n += 1.0; }
    x.signum() * 2.0 / PI.sqrt() * (-y * y).exp() * sum
}
fn ncdf(x: f64) -> f64 { 0.5 * (1.0 + erf(x / 2f64.sqrt())) }
fn call(s: f64, k: f64, t: f64, r: f64, q: f64, v: f64) -> (f64, f64) {   // price and delta
    if t <= 0.0 { return ((s - k).max(0.0), if s > k { 1.0 } else { 0.0 }); }
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    let d2 = d1 - v * t.sqrt();
    (s * (-q * t).exp() * ncdf(d1) - k * (-r * t).exp() * ncdf(d2), (-q * t).exp() * ncdf(d1))
}
fn price(v: f64) -> f64 { call(S0, K, T, R, Q, v).0 }
fn leland(dt: f64) -> f64 { (2.0 / PI).sqrt() * K_RT / (SIG * dt.sqrt()) }
fn marks(dt: f64) -> (f64, f64) {
    let le = leland(dt);
    (SIG * (1.0 + le).sqrt(), SIG * (1.0 - le).max(0.0).sqrt())
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn stats(xs: &[f64]) -> (f64, f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let sd = (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0)).sqrt();
    (m, sd, sd / n.sqrt())
}
fn simulate(rng: &mut Rng, days: f64, paths: usize) -> [(f64, f64, f64); 4] {
    let dt = days * DAY; let steps = (T / dt).round() as usize; let (hs, hl) = marks(dt);
    let (mut bills, mut sbills, mut shorts, mut longs) = (vec![], vec![], vec![], vec![]);
    for _ in 0..paths {
        let (mut s, mut t) = (S0, T);
        let (mut a, mut b, mut c) = (call(s, K, t, R, Q, SIG).1, call(s, K, t, R, Q, hs).1, call(s, K, t, R, Q, hl).1);
        let (mut bill, mut sbill, mut cash_s, mut cash_l) = (0.0, 0.0, price(hs) - b * s, -price(hl) + c * s);
        for i in 1..=steps {
            let (u1, u2) = (rng.unif(), rng.unif());
            let z = (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos();
            s *= ((R - Q - 0.5 * SIG * SIG) * dt + SIG * dt.sqrt() * z).exp(); t = T - i as f64 * dt;
            cash_s = cash_s * (R * dt).exp() + b * s * ((Q * dt).exp() - 1.0);
            cash_l = cash_l * (R * dt).exp() - c * s * ((Q * dt).exp() - 1.0);
            if i == steps { break; }                  // expiry: the call settles in shares
            let (a2, b2, c2) = (call(s, K, t, R, Q, SIG).1, call(s, K, t, R, Q, hs).1, call(s, K, t, R, Q, hl).1);
            bill += 0.5 * K_RT * (a2 - a).abs() * s * (-R * i as f64 * dt).exp();
            sbill += 0.5 * K_RT * (b2 - b).abs() * s * (-R * i as f64 * dt).exp();
            cash_s -= (b2 - b) * s + 0.5 * K_RT * (b2 - b).abs() * s;
            cash_l += (c2 - c) * s - 0.5 * K_RT * (c2 - c).abs() * s;
            a = a2; b = b2; c = c2;
        }
        let pay = (s - K).max(0.0);
        bills.push(bill); sbills.push(sbill);
        shorts.push((cash_s + b * s - pay) * (-R * T).exp());
        longs.push((cash_l - c * s + pay) * (-R * T).exp());
    }
    [stats(&bills), stats(&shorts), stats(&longs), stats(&sbills)]
}

fn main() {
    // ---- road 1: the closed form ----
    let le = leland(DAY); let (vs, vl) = marks(DAY);
    let (mid, cs, cl) = (price(SIG), price(vs), price(vl));
    println!("Leland number, daily: sqrt(2/pi) x {} / ({} x sqrt(1/252)) = {:.5}", K_RT, SIG, le);
    println!("short mark: 20% x sqrt(1 + Le) = {:.4}%, price {:.4}", 100.0 * vs, cs);
    println!("long mark:  20% x sqrt(1 - Le) = {:.4}%, price {:.4}", 100.0 * vl, cl);
    println!("mid price at 20%: {:.4}; markup {:.4}, markdown {:.4}, gap {:.4}", mid, cs - mid, mid - cl, cs - cl);
    println!("volatility gap: up {:.4} points, down {:.4} points", 100.0 * (vs - SIG), 100.0 * (SIG - vl));

    // ---- road 2: E|Z| by Simpson, and one day's cost against one day's gamma rent ----
    let (n, h) = (20000usize, 10.0 / 20000.0);
    let mut acc = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let x = i as f64 * h; acc += w * x * (-0.5 * x * x).exp();
    }
    let ez = 2.0 * acc * h / 3.0 / (2.0 * PI).sqrt();
    let g = (call(S0 + 0.01, K, T, R, Q, SIG).1 - call(S0 - 0.01, K, T, R, Q, SIG).1) / 0.02;
    let mv = ez * SIG * S0 * DAY.sqrt();
    let cost = 0.5 * K_RT * S0 * g * mv;
    let rent = 0.5 * g * S0 * S0 * SIG * SIG * DAY;
    let vega = (price(SIG + 0.0001) - price(SIG - 0.0001)) / 0.0002 / 100.0;
    println!("E|Z| by Simpson: {:.6}; sqrt(2/pi) = {:.6}", ez, (2.0 / PI).sqrt());
    println!("gamma {:.6}; typical daily move ${:.4}, average size ${:.5}; shares traded {:.6}",
             g, SIG * S0 * DAY.sqrt(), mv, g * mv);
    println!("expected cost per day ${:.6}; gamma rent per day ${:.6}; ratio {:.5}", cost, rent, cost / rent);
    println!("vega per point {:.6}; vega x (21.2289 - 20) = {:.4}", vega, vega * 100.0 * (vs - SIG));
    assert!((ez - (2.0 / PI).sqrt()).abs() < 1e-9, "Simpson against the closed form of E|Z|");
    let d1 = ((S0 / K).ln() + (R - Q + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    assert!((g - (-Q * T - 0.5 * d1 * d1).exp() / (2.0 * PI).sqrt() / (S0 * SIG * T.sqrt())).abs() < 1e-7, "gamma, closed form");
    assert!((cost / rent - le).abs() < 1e-6, "the day's cost over the day's rent is the Leland number");
    assert!((vega * 100.0 * (vs - SIG) / (cs - mid) - 1.0).abs() < 0.01, "markup is about vega x vol gap");
    assert!(format!("{:.5} {:.2} {:.2}", le, 100.0 * vs, 100.0 * vl) == "0.12666 21.23 18.69");
    assert!(format!("{:.3} {:.3} {:.3}", cs, cl, mid) == "9.693 8.731 9.227");

    // ---- road 3: hedge simulated years.  Shares follow the risk-neutral drift r - q. ----
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let [bill, short, long, sbill] = simulate(&mut rng, 1.0, 10000);
    println!("10,000 simulated years, hedged daily (mean, spread, standard error):");
    println!("  bill, hedging at 20%:            {:.4} {:.4} {:.4} vs markup {:.4}", bill.0, bill.1, bill.2, cs - mid);
    println!("  bill, hedging at 21.23%:         {:.4} {:.4} {:.4} vs markup {:.4}", sbill.0, sbill.1, sbill.2, cs - mid);
    println!("  seller at 21.23%, hedging there: {:.4} {:.4} {:.4}", short.0, short.1, short.2);
    println!("  buyer at 18.69%, hedging there:  {:.4} {:.4} {:.4}", long.0, long.1, long.2);
    assert!((bill.0 / (cs - mid) - 1.0).abs() < 0.08, "simulated bill against Leland's markup");
    assert!(short.0.abs() < 4.0 * short.2 + 0.01, "the seller's markup pays the bill on average");
    assert!(long.0.abs() < 4.0 * long.2 + 0.01, "the buyer's markdown pays the bill on average");
    assert!((sbill.0 / (cs - mid) - 1.0).abs() < 0.015, "hedging at 21.23%, the seller's own bill is the markup");

    println!("interval trade-off (days, Le, short mark %, markup, simulated bill, seller spread):");
    for d in [1.0, 2.0, 3.0, 6.0, 12.0, 21.0] {
        let vsd = marks(d * DAY).0; let r3 = simulate(&mut rng, d, 4000);
        println!("  {:2}  {:.5}  {:.4}  {:.4}  {:.4}  {:.4}", d as i32, leland(d * DAY), 100.0 * vsd,
                 price(vsd) - mid, r3[0].0, r3[1].1);
    }

    // ---- the inverse: the most frequent hedging that keeps the short mark within 21% ----
    let target = 0.21; let le_t = (target / SIG).powi(2) - 1.0;
    let dt_closed = ((2.0 / PI).sqrt() * K_RT / (SIG * le_t)).powi(2);
    let (want, mut lo, mut hi) = (price(target) - mid, 0.01 * DAY, 100.0 * DAY);
    for _ in 0..200 {
        let m = 0.5 * (lo + hi);
        if price(marks(m).0) - mid > want { lo = m; } else { hi = m; }
    }
    println!("target 21%: Le = {:.6}; interval {:.5} days by formula, {:.5} by bisection on the markup {:.4}",
             le_t, dt_closed / DAY, lo / DAY, want);
    println!("every 2 days: Le {:.5}, mark {:.4}%", leland(2.0 * DAY), 100.0 * marks(2.0 * DAY).0);
    let dt_zero = ((2.0 / PI).sqrt() * K_RT / SIG).powi(2);
    println!("long mark hits zero at Le = 1: interval {:.6} days = {:.2} minutes", dt_zero / DAY, dt_zero / DAY * 390.0);
    assert!((dt_closed - lo).abs() < 1e-9, "closed-form interval against bisection");
    assert!((marks(dt_closed).0 - target).abs() < 1e-12, "the interval reproduces the target");

    // ---- what breaks if you drop a piece ----
    let mark = |l: f64| SIG * (1.0 + l).sqrt();
    let wrongs = [("calendar days, dt = 1/365", mark((2.0 / PI).sqrt() * K_RT / (SIG * (1.0f64 / 365.0).sqrt()))),
                  ("Le on the vol, not the variance", SIG * (1.0 + le)),
                  ("drop sqrt(2/pi)", mark(K_RT / (SIG * DAY.sqrt())))];
    for (label, v) in wrongs { println!("wrong: {}: mark {:.4}%, price {:.4}", label, 100.0 * v, price(v)); }
    println!("wrong: long call marked up too: buyer pays {:.4}, overpays {:.4}", cs, cs - cl);

    println!("chart, interval in days -> short and long mark (%):");
    for d in [0.25, 0.5, 1.0, 2.0, 5.0, 10.0, 21.0] {
        let (u, w) = marks(d * DAY); println!("  {:5.2}  {:.2}  {:.2}", d, 100.0 * u, 100.0 * w);
    }
    println!("ALL CHECKS PASS");
}
