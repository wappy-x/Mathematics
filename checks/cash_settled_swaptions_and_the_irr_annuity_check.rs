// Cash-settled swaptions and the IRR annuity -- the same check as the Python, in Rust.  std only.
// The bell-curve area, the integrator and the random numbers are all written here.
use std::f64::consts::PI;

const FWD: [f64; 6] = [0.050, 0.046, 0.043, 0.041, 0.040, 0.039]; // one-year forwards, years 1..6
const L: f64 = 10_000_000.0; // notional, dollars
const K: f64 = 0.043; // strike
const SIG: f64 = 0.30; // volatility of the swap rate
const T: f64 = 1.0; // expiry, years
const N: i32 = 5; // swap length, years

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

fn irr(s: f64) -> f64 { (1..=N).map(|i| (1.0 + s).powi(-i)).sum() } // cash annuity a(s)
fn irr1(s: f64) -> f64 { (1..=N).map(|i| -(i as f64) * (1.0 + s).powi(-i - 1)).sum() }
fn irr2(s: f64) -> f64 { (1..=N).map(|i| (i * (i + 1)) as f64 * (1.0 + s).powi(-i - 2)).sum() }

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
    let a: f64 = d[2..7].iter().sum(); // physical annuity from the curve
    let fsw = (d[1] - d[6]) / a; // forward swap rate
    let al0 = 1.0 / N as f64; // linear TSR: 1/A_T = al0 + b s
    let b = (d[1] / a - al0) / fsw;
    let m = |s: f64| irr(s) * (al0 + b * s);
    let m1 = |s: f64| irr1(s) * (al0 + b * s) + irr(s) * b;
    let m2 = |s: f64| irr2(s) * (al0 + b * s) + 2.0 * irr1(s) * b;
    let avg = |g: &dyn Fn(f64) -> f64, sig: f64, n: usize| { // road 1: average under the annuity measure,
        let v = sig * T.sqrt(); // split at zk, where S = K and the payoff kinks
        let zk = ((K / fsw).ln() + 0.5 * v * v) / v;
        let f = |z: f64| g(fsw * (-0.5 * v * v + v * z).exp()) * phi(z);
        simpson(f, -10.0, zk, n / 2) + simpson(f, zk, 10.0, n / 2)
    };
    let black = |k: f64| { // physical payer, receiver per unit annuity
        let v = SIG * T.sqrt();
        let d1 = ((fsw / k).ln() + 0.5 * v * v) / v;
        let d2 = d1 - v;
        (fsw * ncdf(d1) - k * ncdf(d2), k * ncdf(-d2) - fsw * ncdf(-d1))
    };

    let pay_c = L * a * avg(&|s| m(s) * (s - K).max(0.0), SIG, 20000);
    let rec_c = L * a * avg(&|s| m(s) * (K - s).max(0.0), SIG, 20000);
    let (pay_p, rec_p) = (L * a * black(K).0, L * a * black(K).1);
    let swap = L * a * (fsw - K);
    // road 2: static replication by physical swaptions
    let pay_r = L * a * (m(K) * black(K).0 + simpson(|k| (m2(k) * (k - K) + 2.0 * m1(k)) * black(k).0, K, 0.30, 1200));
    let rec_r = L * a * (m(K) * black(K).1 + simpson(|k| (m2(k) * (K - k) - 2.0 * m1(k)) * black(k).1, 1e-6, K, 600));

    let mut rng = Rng(20261123); // road 3: simulation of cash minus physical, plus the physical payer's Black price
    let paths = 200_000usize;
    let v = SIG * T.sqrt();
    let (mut tot, mut tot2) = (0.0_f64, 0.0_f64);
    for _ in 0..paths {
        let u1 = rng.uniform();
        let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let s = fsw * (-0.5 * v * v + v * z).exp();
        let p = (m(s) - 1.0) * (s - K).max(0.0);
        tot += p; tot2 += p * p;
    }
    let mu = tot / paths as f64;
    let mc = L * a * (black(K).0 + mu);
    let se = L * a * ((tot2 / paths as f64 - mu * mu) / paths as f64).sqrt();

    let gap = (pay_c - rec_c) - swap;
    let bp = L * a * 1e-4;
    let (h, h2) = (1e-5, 1e-4); // nudges for slope and bend
    let mkt = L * d[1] * irr(fsw);
    let zero_vol = L * a * (m(fsw) - 1.0) * (fsw - K);
    let (mut lo, mut hi) = (0.0_f64, 0.10_f64); // peak of m: bisect for the zero of its slope m'
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if m1(mid) > 0.0 { lo = mid; } else { hi = mid; }
    }
    let tilt = L * a * avg(&|s| m(s) * (s - fsw), SIG, 20000);
    let bend = L * a * (fsw - K) * (avg(&|s| m(s), SIG, 20000) - m(fsw));
    let tsr_check = a * avg(&|s| al0 + b * s, SIG, 20000);
    let rows: Vec<(&str, f64)> = vec![
        ("annuity A, curve", a), ("F, forward swap rate", fsw), ("TSR intercept 1/n", al0), ("TSR slope b", b),
        ("cash annuity a(F)", irr(fsw)), ("forward annuity A/D(1)", a / d[1]), ("multiplier m(F)", m(fsw)),
        ("a'(F), formula", irr1(fsw)), ("a'(F), nudge", (irr(fsw + h) - irr(fsw - h)) / (2.0 * h)),
        ("a''(F), formula", irr2(fsw)), ("a''(F), nudge", (irr(fsw + h2) - 2.0 * irr(fsw) + irr(fsw - h2)) / (h2 * h2)),
        ("TSR check: A x avg of 1/A_T", tsr_check), ("  D(1)", d[1]),
        ("average multiplier E[m]", avg(&|s| m(s), SIG, 20000)), ("peak of m, swap rate", lo),
        ("physical payer, Black", pay_p), ("physical receiver, Black", rec_p),
        ("1 cash payer, Simpson", pay_c), ("2 cash payer, replication", pay_r), ("3 cash payer, simulation", mc),
        ("  simulation std error", se), ("  simulation gap, std errors", (pay_c - mc) / se),
        ("cash receiver, Simpson", rec_c), ("cash receiver, replication", rec_r),
        ("cash payer - receiver, Simpson", pay_c - rec_c), ("  same, replication", pay_r - rec_r),
        ("L A times one bp", bp), ("forward swap L A (F - K)", swap), ("parity gap, dollars", gap), ("parity gap, bp", gap / bp),
        ("  zero-vol part L A (m(F)-1)(F-K)", zero_vol), ("  volatility part", gap - zero_vol),
        ("    tilt: L A E[m(S)(S - F)]", tilt), ("    bend: L A (F - K)(E[m] - m(F))", bend),
        ("cash premium over physical, payer", pay_c - pay_p),
        ("market formula payer", mkt * black(K).0), ("market formula receiver", mkt * black(K).1),
        ("  market minus TSR, payer", mkt * black(K).0 - pay_c),
        ("wrong: cash annuity not discounted", L * irr(fsw) * black(K).0),
        ("wrong: annuity from i = 0", L * a * avg(&|s| irr(s) * (1.0 + s) * (al0 + b * s) * (s - K).max(0.0), SIG, 20000)),
        ("wrong: receiver = payer - swap", pay_c - swap),
        ("try: strike = F, cash pay - rec", L * a * avg(&|s| m(s) * (s - fsw), SIG, 20000)),
        ("try: intercept 0, cash payer", L * a * avg(&|s| irr(s) * d[1] / (a * fsw) * s * (s - K).max(0.0), SIG, 20000)),
    ];
    for (name, x) in &rows { println!("{:<36} {:>16.6}", name, x); }
    for sg in [0.1, 0.2, 0.3, 0.4, 0.5, 0.6] {
        let g = L * a * avg(&|s| m(s) * (s - K), sg, 8000) - swap;
        println!("sigma {:.1}: gap dollars, bp       {:>12.2} {:>9.4}", sg, g, g / bp);
    }
    let ss: Vec<f64> = (0..7).map(|i| 0.02 + 0.01 * i as f64).collect();
    let row = |label: &str, xs: Vec<String>| println!("{:<31}{}", label, xs.join(" "));
    row("chart, swap rate at expiry %", ss.iter().map(|s| format!("{:6.1}", 100.0 * s)).collect());
    row("chart, cash annuity a(S)", ss.iter().map(|s| format!("{:6.3}", irr(*s))).collect());
    row("chart, TSR annuity 1/(1/n+bS)", ss.iter().map(|s| format!("{:6.3}", 1.0 / (al0 + b * s))).collect());
    row("chart, m(S) - 1, percent", ss.iter().map(|s| format!("{:6.3}", 100.0 * (m(*s) - 1.0))).collect());

    assert!((pay_r - pay_c).abs() < 0.001, "cash payer: replication = direct average");
    assert!((rec_r - rec_c).abs() < 0.001, "cash receiver: replication = direct average");
    assert!((mc - pay_c).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((mc - pay_p).abs() > 20.0 * se, "simulation tells the cash price from the physical");
    assert!((tilt + bend - (gap - zero_vol)).abs() < 1e-3, "volatility part = tilt + bend");
    assert!(lo < fsw && m(lo) > m(lo - 1e-3).max(m(lo + 1e-3)), "m peaks just below the forward");
    assert!((irr1(fsw) - (irr(fsw + h) - irr(fsw - h)) / (2.0 * h)).abs() < 1e-6, "IRR annuity slope");
    assert!((irr2(fsw) - (irr(fsw + h2) - 2.0 * irr(fsw) + irr(fsw - h2)) / (h2 * h2)).abs() < 1e-3, "IRR annuity bend");
    assert!((tsr_check - d[1]).abs() < 1e-9, "TSR reprices the expiry bond");
    assert!(((pay_p - rec_p) - swap).abs() < 0.01, "physical parity holds");
    assert!(gap < -100.0, "cash parity misses the forward swap");
    println!("ALL CHECKS PASS");
}
