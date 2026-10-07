// Swaption Greeks and the forward-swap hedge -- the check behind the card.  std only, no crates.
// Normal CDF, integrator and random numbers are written here; nothing imported knows a swaption.
use std::f64::consts::PI;

const Y: f64 = 0.044; const K: f64 = 0.0435; const SIG: f64 = 0.30; const TAU: f64 = 1.0;
const NOT: f64 = 1e7; const BP: f64 = 1e-4;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 {                          // bell-curve area left of x, by its series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + phi(x) * s
}
fn curve(y: f64, tau: f64) -> (f64, f64) {     // annuity and forward swap rate of the 5y swap starting at tau
    let d = |t: f64| (1.0 + y).powf(-t);
    let a: f64 = (1..6).map(|i| d(tau + i as f64)).fold(0.0, |s, v| s + v);
    (a, (d(tau) - d(tau + 5.0)) / a)
}
fn black(f: f64, s: f64, tau: f64) -> (f64, f64, f64) {
    let v = s * tau.sqrt(); let d1 = ((f / K).ln() + 0.5 * v * v) / v;
    (f * n(d1) - K * n(d1 - v), d1, d1 - v)
}
fn val(y: f64, tau: f64, s: f64) -> f64 { let (a, f) = curve(y, tau); NOT * a * black(f, s, tau).0 }
fn vv(y: f64) -> f64 { val(y, TAU, SIG) }
fn swap(y: f64, f0: f64) -> f64 { let (a, f) = curve(y, TAU); NOT * a * (f - f0) }
fn b_int(f: f64, s: f64, tau: f64) -> f64 {    // road 2: Simpson's rule over the bell curve; no d1, no d2
    let nn = 4000;
    let g = |z: f64| f * (-0.5 * s * s * tau + s * tau.sqrt() * z).exp() - K;
    let (mut lo, mut hi) = (-10.0, 10.0);      // exercise boundary by bisection
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if g(mid) > 0.0 { hi = mid } else { lo = mid } }
    let (a, h) = (lo, (10.0 - lo) / nn as f64);
    let mut tot = 0.0;
    for i in 0..=nn {
        let w = if i == 0 || i == nn { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let z = a + i as f64 * h; tot += w * g(z) * phi(z);
    }
    tot * h / 3.0
}
fn da(y: f64, tau: f64) -> f64 { -(1..6).map(|i| (tau + i as f64) * (1.0 + y).powf(-(tau + i as f64) - 1.0)).fold(0.0, |s, v| s + v) }
fn dh(y: f64, tau: f64) -> f64 {               // full hedge ratio: N(d1) plus the annuity's own sensitivity
    let (a, f) = curve(y, tau); let (b, d1, _) = black(f, SIG, tau);
    n(d1) + da(y, tau) / a * b
}
fn out(label: &str, vals: &[f64], w: usize, p: usize) {
    let mut s = format!("{:<34}", label);
    for v in vals { s += &format!("{:>w$.p$}", v, w = w, p = p); }
    println!("{}", s);
}
struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn main() {
    let (a, f) = curve(Y, TAU); let (b, d1, d2) = black(f, SIG, TAU);
    let fwd: Vec<f64> = (1..6).map(|i| (1.0 + Y).powf(-(TAU + i as f64 - 1.0)) / (1.0 + Y).powf(-(TAU + i as f64)) - 1.0).collect();
    let f_avg = (1..6).map(|i| (1.0 + Y).powf(-(TAU + i as f64)) * fwd[i - 1]).fold(0.0, |s, v| s + v) / a;
    let bi = b_int(f, SIG, TAU);
    out("annuity A, forward F (ratio)", &[a, f], 14, 6); out("forward F (weighted forwards)", &[f_avg], 14, 6);
    out("d1, d2", &[d1, d2], 14, 6); out("N(d1), N(d2)", &[n(d1), n(d2)], 14, 6);
    out("1 Black price, dollars", &[NOT * a * b], 14, 2); out("2 Simpson price, dollars", &[NOT * a * bi], 14, 2);
    out("price, percent of notional", &[100.0 * a * b], 14, 6); out("value per unit of annuity B", &[b], 14, 7);
    // ---- delta: in forward swaps, then with the annuity moving too ----
    let e = 1e-6;
    let nd1_int = (b_int(f + e, SIG, TAU) - b_int(f - e, SIG, TAU)) / (2.0 * e);
    let d_a = da(Y, TAU);
    let h_cf = dh(Y, TAU);
    let h_fd = (vv(Y + BP) - vv(Y - BP)) / (swap(Y + BP, f) - swap(Y - BP, f));
    out("N(d1) formula, by integral", &[n(d1), nd1_int], 14, 6);
    out("annuity slope A', A'/A, (A'/A) B", &[d_a, d_a / a, d_a / a * b], 14, 6);
    out("hedge ratio: formula, bumped curve", &[h_cf, h_fd], 14, 6);
    out("hedge: forward swap notional, $", &[NOT * h_cf], 14, 2);
    out("swaption DV01, swap DV01 ($/bp)", &[(vv(Y + BP) - vv(Y - BP)) / 2.0, (swap(Y + BP, f) - swap(Y - BP, f)) / 2.0], 14, 2);
    // ---- gamma, vega, theta ----
    let g_cf = phi(d1) / (f * SIG * TAU.sqrt()) * 10.0 * BP;
    let g_int = (b_int(f + 1e-5, SIG, TAU) - 2.0 * bi + b_int(f - 1e-5, SIG, TAU)) / 1e-10 * 10.0 * BP;
    out("gamma: N(d1) change per 10bp, x2", &[g_cf, g_int], 14, 6);
    out("hedge ratio at -10bp, +10bp", &[dh(Y - 10.0 * BP, TAU), dh(Y + 10.0 * BP, TAU)], 14, 6);
    let vg_cf = NOT * a * f * phi(d1) * TAU.sqrt() * 0.01;
    let vg_int = NOT * a * (b_int(f, SIG + 1e-4, TAU) - b_int(f, SIG - 1e-4, TAU)) / 2e-4 * 0.01;
    out("vega per vol point: formula, integral", &[vg_cf, vg_int], 14, 2);
    let decay = -NOT * a * f * phi(d1) * SIG / (2.0 * TAU.sqrt()) / 365.0;
    let carry = vv(Y) * (1.0 + Y).ln() / 365.0;
    let th_fd = (val(Y, TAU - 1e-4, SIG) - val(Y, TAU + 1e-4, SIG)) / 2e-4 / 365.0;
    out("theta/day: decay, carry, sum", &[decay, carry, decay + carry], 14, 2);
    out("theta/day: rolled date; one day", &[th_fd, val(Y, TAU - 1.0 / 365.0, SIG) - vv(Y)], 14, 2);
    // ---- the hedge at work: short h forward swaps against the long payer ----
    println!("move bp   swaption P&L      hedge P&L    net P&L   half-gamma guess");
    let gam_d = 0.5 * NOT * a * phi(d1) / (f * SIG * TAU.sqrt());
    let (mut cu, mut cn) = (vec![], vec![]);
    for bp in (-50..=50).step_by(10) {
        let dy = bp as f64 * BP; let pv = vv(Y + dy) - vv(Y); let hv = h_cf * swap(Y + dy, f) + 0.0;
        cu.push(pv / 1000.0); cn.push((pv - hv) / 1000.0);
        println!("{:>7}{:>15.2}{:>15.2}{:>11.2}{:>12.2}", bp, pv, 0.0 - hv, pv - hv, gam_d * dy * dy);
    }
    out("chart, $000 unhedged", &cu, 8, 2); out("chart, $000 hedged", &cn, 8, 2);
    // ---- what breaks ----
    let spot = |dy: f64| NOT * (1..6).map(|i| (1.0 + Y + dy).powf(-(i as f64))).fold(0.0, |s, v| s + v) * dy;
    for bp in [-30i32, 30] {
        let dy = bp as f64 * BP; let pv = vv(Y + dy) - vv(Y);
        out(&format!("wrong at {:+}bp: N(d1) hedge; spot swap", bp), &[pv - n(d1) * swap(Y + dy, f), pv - h_cf * spot(dy)], 14, 2);
    }
    out("wrong: N(d1) hedge, bet in $ per bp", &[(n(d1) - h_cf) * NOT * a * BP], 14, 2);
    out("wrong: theta without carry", &[decay], 14, 2);
    out("wrong: price with no annuity", &[NOT * b], 14, 2);
    // ---- how the hedge moves ----
    let grid: Vec<f64> = (0..11).map(|i| 0.039 + 0.001 * i as f64).collect();
    out("chart, forward rate %", &grid.iter().map(|g| 100.0 * g).collect::<Vec<_>>(), 7, 1);
    out("chart, hedge ratio 12m left", &grid.iter().map(|&g| dh(g, 1.0)).collect::<Vec<_>>(), 7, 2);
    out("chart, hedge ratio 3m left", &grid.iter().map(|&g| dh(g, 0.25)).collect::<Vec<_>>(), 7, 2);
    for m in [12, 6, 3, 1] {
        let t = m as f64 / 12.0; let tl = (val(Y, t - 1e-4, SIG) - val(Y, t + 1e-4, SIG)) / 2e-4 / 365.0;
        out(&format!("bars, {:>2} months left: value, theta", m), &[val(Y, t, SIG), tl], 14, 2);
    }
    // ---- road 4: replicate by hedging, counted in annuity units (F has no drift there) ----
    let mut rng = Rng(0x2545F4914F6CDD1D);
    let mut sim = vec![];
    for steps in [52usize, 260] {
        let dt = TAU / steps as f64; let mut errs = vec![];
        for _ in 0..2000 {
            let (mut fp, mut cash) = (f, b);
            for i in 0..steps {
                let v = SIG * (TAU - i as f64 * dt).sqrt();
                let dlt = n(((fp / K).ln() + 0.5 * v * v) / v);
                let (u1, u2) = (rng.u(), rng.u());
                let fnew = fp * (-0.5 * SIG * SIG * dt + SIG * dt.sqrt() * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()).exp();
                cash += dlt * (fnew - fp); fp = fnew;
            }
            errs.push(NOT * a * (cash - (fp - K).max(0.0)));
        }
        let m = errs.iter().sum::<f64>() / errs.len() as f64;
        let sd = (errs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (errs.len() - 1) as f64).sqrt();
        sim.push((m, sd)); out(&format!("hedge error, {} rebalances: mean, sd", steps), &[m, sd], 14, 2);
    }
    // ---- try changing ----
    let (b20, d20, _) = black(f, 0.20, TAU);
    out("try: vol 20%: price; hedge ratio", &[NOT * a * b20, n(d20) + d_a / a * b20], 14, 4);
    out("try: 3 months left: hedge ratio", &[dh(Y, 0.25)], 14, 6);
    out("try: strike 4.40%: hedge ratio", &[n(0.15) + d_a / a * (f * n(0.15) - f * n(-0.15))], 14, 6);
    assert!((f - f_avg).abs() < 1e-12, "forward: ratio vs weighted forwards");
    assert!((bi - b).abs() < 1e-9, "Black formula vs Simpson integral");
    assert!((nd1_int - n(d1)).abs() < 1e-6, "delta in swaps: N(d1) vs bumped integral");
    assert!((h_cf - h_fd).abs() < 1e-5, "hedge ratio: formula vs full curve bump");
    assert!((g_cf - g_int).abs() < 1e-5, "gamma: formula vs integral");
    assert!((vg_cf - vg_int).abs() < 1e-3, "vega: formula vs integral");
    assert!(((decay + carry) - th_fd).abs() < 1e-3, "theta formula vs rolled date");
    assert!(sim[1].0.abs() < 3.0 * sim[1].1 / 2000f64.sqrt(), "hedging costs the premium on average");
    assert!(sim[1].1 < 0.6 * sim[0].1, "five times the rebalancing, under 0.6 the spread");
    println!("ALL CHECKS PASS");
}
