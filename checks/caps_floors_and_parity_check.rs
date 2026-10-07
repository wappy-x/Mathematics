// Caps and floors: a 2-year cap at 5% on 3-month rates, 30% lognormal volatility.
// Roads: Black-76 per caplet; Simpson integral of each payoff; Monte Carlo; parity from discount factors.
use std::f64::consts::PI;

const NOTIONAL: f64 = 10_000_000.0;
const TAU: f64 = 0.25;
const K: f64 = 0.05;
const SIG: f64 = 0.30;

fn ncdf(x: f64) -> f64 {
    // N(x) = 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        term *= x * x / (2.0 * k + 1.0);
        total += term;
        k += 1.0;
    }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * total
}

fn black(f: f64, strike: f64, sig: f64, t: f64, call: bool) -> f64 {
    let v = sig * t.sqrt();
    let d1 = ((f / strike).ln() + 0.5 * v * v) / v;
    let d2 = d1 - v;
    if call { f * ncdf(d1) - strike * ncdf(d2) } else { strike * ncdf(-d2) - f * ncdf(-d1) }
}

struct Curve { fwd: Vec<f64>, d: Vec<f64> }

impl Curve {
    fn strip(&self, strike: f64, sig: f64, call: bool, bump: f64, pay_lag: usize, vol_lag: f64) -> Vec<f64> {
        (1..8).map(|i| NOTIONAL * TAU * self.d[i + pay_lag]
            * black(self.fwd[i] + bump, strike, sig, TAU * (i as f64 + vol_lag), call)).collect()
    }
    fn total(&self, strike: f64, sig: f64, call: bool, bump: f64) -> f64 {
        self.strip(strike, sig, call, bump, 1, 0.0).iter().sum()
    }
    fn by_integral(&self, i: usize, call: bool) -> f64 {
        let (f, v) = (self.fwd[i], SIG * (TAU * i as f64).sqrt());
        let zk = ((K / f).ln() + 0.5 * v * v) / v;
        let payoff = |z: f64| {
            let rate = f * (-0.5 * v * v + v * z).exp();
            let dens = (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
            (if call { rate - K } else { K - rate }) * dens
        };
        let val = if call { simpson(&payoff, zk, 10.0) } else { simpson(&payoff, -10.0, zk) };
        NOTIONAL * TAU * self.d[i + 1] * val
    }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 2000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for j in 1..n { s += (if j % 2 == 1 { 4.0 } else { 2.0 }) * f(a + j as f64 * h); }
    h / 3.0 * s
}

struct Lcg(u64);
impl Lcg {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((self.0 >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn monte_carlo(c: &Curve, paths: usize) -> f64 {
    let mut rng = Lcg(20260928);
    let mut total = 0.0;
    for _ in 0..paths / 2 {
        let u1 = rng.uniform();
        let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        for i in 1..8 {
            let (f, v) = (c.fwd[i], SIG * (TAU * i as f64).sqrt());
            for s in [z, -z] {
                total += TAU * c.d[i + 1] * (f * (-0.5 * v * v + v * s).exp() - K).max(0.0);
            }
        }
    }
    NOTIONAL * total / paths as f64
}

fn p(label: &str, v: f64) { println!("{:<40}{:>16.2}", label, v); }
fn q(label: &str, v: f64) { println!("{:<40}{:>16.6}", label, v); }

fn main() {
    let fwd: Vec<f64> = (0..8).map(|i| 0.044 + 0.0005 * i as f64).collect();
    let mut d = vec![1.0];
    for f in &fwd { let last = *d.last().unwrap(); d.push(last / (1.0 + TAU * f)); }
    let c = Curve { fwd, d };
    let (cl, fl) = (c.strip(K, SIG, true, 0.0, 1, 0.0), c.strip(K, SIG, false, 0.0, 1, 0.0));
    let (cap, floor): (f64, f64) = (cl.iter().sum(), fl.iter().sum());
    let cap_int: f64 = (1..8).map(|i| c.by_integral(i, true)).sum();
    let floor_int: f64 = (1..8).map(|i| c.by_integral(i, false)).sum();
    let cap_mc = monte_carlo(&c, 200_000);
    let a: f64 = (1..8).map(|i| TAU * c.d[i + 1]).sum();
    let s = (c.d[1] - c.d[8]) / a;
    let swap = NOTIONAL * ((c.d[1] - c.d[8]) - K * a);
    let (cap_s, floor_s) = (c.total(s, SIG, true, 0.0), c.total(s, SIG, false, 0.0));

    let bp = 0.0001;
    let dcap: f64 = (1..8).map(|i| {
        let t = TAU * i as f64;
        NOTIONAL * TAU * c.d[i + 1] * ncdf(((c.fwd[i] / K).ln() + 0.5 * SIG * SIG * t) / (SIG * t.sqrt())) * bp
    }).sum();
    let dcap_b = c.total(K, SIG, true, bp / 2.0) - c.total(K, SIG, true, -bp / 2.0);
    let dfl_b = c.total(K, SIG, false, bp / 2.0) - c.total(K, SIG, false, -bp / 2.0);
    let vcap_b = c.total(K, SIG + 0.005, true, 0.0) - c.total(K, SIG - 0.005, true, 0.0);
    let vfl_b = c.total(K, SIG + 0.005, false, 0.0) - c.total(K, SIG - 0.005, false, 0.0);

    for i in 1..8 {
        println!("caplet {}  fix {:.2}y  F {:.2}%  D {:.6}{:>11.2}{:>11.2}",
            i, TAU * i as f64, 100.0 * c.fwd[i], c.d[i + 1], cl[i - 1], fl[i - 1]);
    }
    let v7 = SIG * 1.75f64.sqrt();
    let d1 = ((c.fwd[7] / K).ln() + 0.5 * v7 * v7) / v7;
    q("caplet 7: sigma sqrt(T)", v7); q("caplet 7: d1", d1); q("caplet 7: d2", d1 - v7);
    q("caplet 7: N(d1)", ncdf(d1)); q("caplet 7: N(d2)", ncdf(d1 - v7));
    q("caplet 7: F N(d1) - K N(d2), percent", 100.0 * black(c.fwd[7], K, SIG, 1.75, true));
    p("1 cap, Black strip", cap); p("2 cap, Simpson integral", cap_int); p("3 cap, Monte Carlo 200000", cap_mc);
    q("cap, percent of notional", 100.0 * cap / NOTIONAL);
    p("floor, Black strip", floor); p("floor, Simpson integral", floor_int);
    q("annuity A", a); q("forward swap rate S, percent", 100.0 * s);
    p("cap - floor (integral road)", cap_int - floor_int); p("4 payer swap from D(T)", swap);
    p("cap at strike S", cap_s); p("floor at strike S", floor_s);
    q("running premium, percent a year", 100.0 * cap / NOTIONAL / a);
    q("worst all-in rate, percent", 100.0 * (K + cap / NOTIONAL / a));
    p("delta cap per 1bp, N(d1)", dcap); p("delta cap per 1bp, bump", dcap_b); p("delta floor per 1bp, bump", dfl_b);
    p("  delta difference", dcap_b - dfl_b); p("  annuity x 1bp x notional", a * bp * NOTIONAL);
    p("vega cap per vol point, bump", vcap_b); p("vega floor per vol point, bump", vfl_b);
    p("wrong: discount to the reset date", c.strip(K, SIG, true, 0.0, 0, 0.0).iter().sum());
    p("wrong: volatility to the payment date", c.strip(K, SIG, true, 0.0, 1, 1.0).iter().sum());
    p("wrong: one option, swaption at 0.25y", NOTIONAL * a * black(s, K, SIG, 0.25, true));
    p("wrong: parity read as receiver swap", -swap);
    let fix = [3.0, 3.5, 4.0, 4.5, 5.0, 5.5, 6.0, 6.5, 7.0];
    let row = |f: &dyn Fn(f64) -> f64| fix.iter().map(|&x| format!("{:>9.2}", f(x))).collect::<String>();
    println!("chart fixing, %  {}", fix.iter().map(|x| format!("{:>9.1}", x)).collect::<String>());
    println!("chart cap pays   {}", row(&|x| NOTIONAL * TAU * (x / 100.0 - K).max(0.0)));
    println!("chart floor pays {}", row(&|x| NOTIONAL * TAU * (K - x / 100.0).max(0.0)));
    for ks in [3.5, 4.0, 4.5, 5.0, 5.5, 6.0] {
        let (cs, fs) = (c.total(ks / 100.0, SIG, true, 0.0), c.total(ks / 100.0, SIG, false, 0.0));
        println!("chart strike {:.1}%  cap {:.2}%  floor {:.2}%", ks, 100.0 * cs / NOTIONAL, 100.0 * fs / NOTIONAL);
    }
    p("try: volatility 20%", c.total(K, 0.20, true, 0.0)); p("try: strike 6%", c.total(0.06, SIG, true, 0.0));
    p("try: every forward up 1%", c.total(K, SIG, true, 0.01));

    assert!((cap - cap_int).abs() < 1e-4, "Black strip vs integral of the payoff");
    assert!((cap_mc - cap).abs() < 0.01 * cap, "Monte Carlo within 1 percent");
    assert!(((cap_int - floor_int) - swap).abs() < 1e-4, "parity: integral cap minus floor vs swap");
    assert!((cap_s - floor_s).abs() < 1e-6, "cap equals floor at the swap rate");
    assert!(((dcap_b - dfl_b) - a * bp * NOTIONAL).abs() < 1e-3, "delta gap equals the annuity");
    assert!((dcap - dcap_b).abs() < 1e-3, "N(d1) delta vs bump");
    println!("ALL CHECKS PASS");
}
