// Swaptions, payer and receiver -- the same check as the Python, in Rust.  std only, no crates.
// The bell-curve area, the integrator and the random numbers are all written here.
use std::f64::consts::PI;

const FWD: [f64; 6] = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039]; // one-year forwards, years 1..6
const L: f64 = 10_000_000.0; // notional, dollars
const K: f64 = 0.043; // strike
const SIG: f64 = 0.30; // volatility of the forward swap rate
const T: f64 = 1.0; // expiry, years

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

// payer and receiver per unit notional, then d1 and d2
fn black(f: f64, k: f64, sig: f64, t: f64, a: f64) -> (f64, f64, f64, f64) {
    let v = sig * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    let d2 = d1 - v;
    (a * (f * ncdf(d1) - k * ncdf(d2)), a * (k * ncdf(-d2) - f * ncdf(-d1)), d1, d2)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // xorshift64*, then a number in (0, 1)
        self.0 ^= self.0 >> 12;
        self.0 ^= self.0 << 25;
        self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0 + 1.0 / 18014398509481984.0
    }
}

fn main() {
    let mut d = vec![1.0_f64]; // d[i]: today's price of 1 dollar at year i
    for f in FWD { let last = d[d.len() - 1]; d.push(last / (1.0 + f)); }
    let a: f64 = d[2..7].iter().sum();
    let fsw = (d[1] - d[6]) / a;
    let f_avg: f64 = (2..7).map(|i| d[i] * FWD[i - 1]).sum::<f64>() / a;
    let (p1, r1, d1, d2) = black(fsw, K, SIG, T, a);
    let (pay, rec) = (L * p1, L * r1);

    let v = SIG * T.sqrt();
    let by_integral = |payoff: &dyn Fn(f64) -> f64| {
        L * a * simpson(|z| payoff(fsw * (-0.5 * v * v + v * z).exp()) * phi(z), -10.0, 10.0, 40000)
    };
    let pay_int = by_integral(&|s| (s - K).max(0.0));
    let rec_int = by_integral(&|s| (K - s).max(0.0));
    let swap_cc = L * (2..7).map(|i| d[i] * (FWD[i - 1] - K)).sum::<f64>();

    let mut rng = Rng(20260928);
    let paths = 200_000usize;
    let (mut tot, mut tot2, mut ex, mut exw) = (0.0_f64, 0.0_f64, 0.0_f64, 0.0_f64);
    for _ in 0..paths {
        let u1 = rng.uniform();
        let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let s = fsw * (-0.5 * v * v + v * z).exp();
        let p = (s - K).max(0.0);
        tot += p; tot2 += p * p;
        if s > K { ex += 1.0; exw += s / fsw; }
    }
    let m = tot / paths as f64;
    let mc = L * a * m;
    let se = L * a * ((tot2 / paths as f64 - m * m) / paths as f64).sqrt();

    let h = 1e-6;
    let delta_f = L * a * ncdf(d1) * 1e-4;
    let delta_b = L * (black(fsw + h, K, SIG, T, a).0 - black(fsw - h, K, SIG, T, a).0) / (2.0 * h) * 1e-4;
    let vega_f = L * a * fsw * phi(d1) * T.sqrt() * 0.01;
    let vega_b = L * (black(fsw, K, SIG + h, T, a).0 - black(fsw, K, SIG - h, T, a).0) / (2.0 * h) * 0.01;

    let a_early: f64 = d[1..6].iter().sum();
    let s_spot = (1.0 - d[5]) / a_early;
    println!("D(1) to D(6){}", d[1..].iter().map(|x| format!(" {:.6}", x)).collect::<String>());
    let rows: Vec<(&str, f64)> = vec![
        ("annuity A", a), ("F, telescope", fsw), ("F, weighted forwards", f_avg),
        ("F minus K, bp", 1e4 * (fsw - K)), ("ln(F/K)", (fsw / K).ln()), ("half sigma^2 T", 0.5 * SIG * SIG * T), ("d1", d1), ("d2", d2), ("N(d1)", ncdf(d1)), ("N(d2)", ncdf(d2)), ("N(-d1)", ncdf(-d1)),
        ("F N(d1), bp", 1e4 * fsw * ncdf(d1)), ("K N(d2), bp", 1e4 * K * ncdf(d2)), ("bracket, bp", 1e4 * (fsw * ncdf(d1) - K * ncdf(d2))),
        ("1 payer, formula", pay), ("2 payer, Simpson", pay_int), ("3 payer, simulation", mc),
        ("  simulation std error", se), ("  simulation gap, std errors", (pay - mc) / se), ("  payer, percent of notional", 100.0 * pay / L),
        ("  payer, bp a year of annuity", 1e4 * pay / (L * a)), ("L A times one bp", L * a * 1e-4),
        ("receiver, formula", rec), ("receiver, Simpson", rec_int),
        ("4 payer - receiver", pay_int - rec_int), ("  swap, coupon by coupon", swap_cc),
        ("  L A (F - K)", L * a * (fsw - K)),
        ("exercise share, simulated", ex / paths as f64), ("rate-weighted share, sim.", exw / paths as f64),
        ("5 payer delta per bp, formula", delta_f), ("  payer delta per bp, nudge", delta_b),
        ("  receiver delta per bp", -L * a * ncdf(-d1) * 1e-4),
        ("  vega per vol point, formula", vega_f), ("  vega per vol point, nudge", vega_b),
        ("wrong: D(1) in place of the annuity", L * d[1] * (fsw * ncdf(d1) - K * ncdf(d2))),
        ("wrong: spot 5-year swap rate as F", L * black(s_spot, K, SIG, T, a).0),
        ("wrong: annuity over years 1 to 5", L * black((d[1] - d[6]) / a_early, K, SIG, T, a_early).0),
        ("wrong: N(d2) on both halves", L * a * (fsw - K) * ncdf(d2)),
        ("spot 5-year swap rate", s_spot),
        ("try: sigma 0.20 payer", L * black(fsw, K, 0.20, T, a).0),
        ("try: sigma 0.40 payer", L * black(fsw, K, 0.40, T, a).0),
        ("try: strike = F, payer", L * black(fsw, fsw, SIG, T, a).0),
        ("try: strike = F, receiver", L * black(fsw, fsw, SIG, T, a).1),
    ];
    for (name, x) in &rows { println!("{:<36} {:>16.6}", name, x); }

    let row = |label: &str, xs: Vec<String>| println!("{:<31}{}", label, xs.join(" "));
    println!();
    row("chart, swap rate at expiry %", (0..9).map(|i| format!("{:6.1}", 3.5 + 0.2 * i as f64)).collect());
    row("chart, payer payoff, bp a year", (0..9).map(|i| format!("{:6.0}", (3.5 + 0.2 * i as f64 - 4.3).max(0.0) * 100.0)).collect());
    row("chart, receiver payoff, bp", (0..9).map(|i| format!("{:6.0}", (4.3 - 3.5 - 0.2 * i as f64).max(0.0) * 100.0)).collect());
    let ks: Vec<f64> = (0..7).map(|i| 0.036 + 0.002 * i as f64).collect();
    row("chart, strike %", ks.iter().map(|k| format!("{:6.1}", 100.0 * k)).collect());
    row("chart, payer, $ thousands", ks.iter().map(|k| format!("{:6.2}", L * black(fsw, *k, SIG, T, a).0 / 1e3)).collect());
    row("chart, receiver, $ thousands", ks.iter().map(|k| format!("{:6.2}", L * black(fsw, *k, SIG, T, a).1 / 1e3)).collect());

    assert!((pay - 191290.0).abs() < 50.0, "the card's worked number, 1.9 percent of notional");
    assert!((pay_int - pay).abs() < 0.01, "Simpson road lands on the formula to the cent");
    assert!((mc - pay).abs() < 4.0 * se, "simulation road within four standard errors");
    assert!(((pay_int - rec_int) - swap_cc).abs() < 0.01, "parity: payer - receiver = the forward swap");
    assert!((fsw - f_avg).abs() < 1e-12, "forward swap rate: telescope = weighted forwards");
    assert!((delta_f - delta_b).abs() < 1e-3, "delta: formula = nudge");
    assert!((rec - rec_int).abs() < 0.01, "receiver formula = Simpson road");
    assert!((vega_f - vega_b).abs() < 1e-3, "vega: formula = nudge");
    println!("ALL CHECKS PASS");
}
