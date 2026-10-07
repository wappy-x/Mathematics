// The exchange option (Margrabe) -- the same check as exchange_option_margrabe_check.py, in Rust.
// Std only, no crates.  Normal CDF as a written-out series, Simpson's rule, splitmix64 +
// Box-Muller random numbers, correlated by Cholesky.
// Compile: rustc --edition 2021 -O exchange_option_margrabe_check.rs -o /tmp/margrabe_check
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 2.0; term *= x * x / k; total += term;
    }
    0.5 + phi(x) * total
}
fn eff_vol(s1: f64, s2: f64, rho: f64) -> f64 { (s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2).max(0.0).sqrt() }

// road 1: the formula, no r in it
fn margrabe(x1: f64, x2: f64, q1: f64, q2: f64, s1: f64, s2: f64, rho: f64, t: f64) -> f64 {
    let v = eff_vol(s1, s2, rho) * t.sqrt();
    let (a, b) = (x1 * (-q1 * t).exp(), x2 * (-q2 * t).exp());
    if v == 0.0 { return (a - b).max(0.0); }
    let d1 = ((a / b).ln() + 0.5 * v * v) / v;
    a * n_cdf(d1) - b * n_cdf(d1 - v)
}
fn bs_call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - sig * t.sqrt())
}

struct Mkt { s1: f64, s2: f64, q1: f64, q2: f64, v1: f64, v2: f64, t: f64 }

// road 2: fix share 2's shock z; share 1 is then lognormal, so the inner average is exact.
fn conditional(m: &Mkt, r: f64, rho: f64, panels: usize) -> f64 {
    let w = m.v1 * ((1.0 - rho * rho) * m.t).sqrt();
    let f = |z: f64| {
        let x2 = m.s2 * ((r - m.q2 - 0.5 * m.v2 * m.v2) * m.t + m.v2 * m.t.sqrt() * z).exp();
        let mu = m.s1.ln() + (r - m.q1 - 0.5 * m.v1 * m.v1) * m.t + m.v1 * rho * m.t.sqrt() * z;
        let d = (mu - x2.ln()) / w;
        ((mu + 0.5 * w * w).exp() * n_cdf(d + w) - x2 * n_cdf(d)) * phi(z)
    };
    let (a, b) = (-10.0, 10.0);
    let h = (b - a) / panels as f64;
    let mut tot = f(a) + f(b);
    for i in 1..panels { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (-r * m.t).exp() * tot * h / 3.0
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
}

// road 3: correlated shares at expiry, z1 = rho z2 + sqrt(1 - rho^2) z_other (Cholesky).
fn simulate(m: &Mkt, r: f64, rho: f64, paths: usize) -> (f64, f64) {
    let mut rng = Rng(20260924);
    let c = (1.0 - rho * rho).sqrt();
    let (mut acc, mut acc2) = (0.0, 0.0);
    let m1 = (r - m.q1 - 0.5 * m.v1 * m.v1) * m.t;
    let m2 = (r - m.q2 - 0.5 * m.v2 * m.v2) * m.t;
    for _ in 0..paths {
        let rad = (-2.0 * rng.uniform().ln()).sqrt();
        let ang = 2.0 * PI * rng.uniform();
        let (z2, zo) = (rad * ang.cos(), rad * ang.sin());
        let z1 = rho * z2 + c * zo;
        let pay = (m.s1 * (m1 + m.v1 * m.t.sqrt() * z1).exp() - m.s2 * (m2 + m.v2 * m.t.sqrt() * z2).exp()).max(0.0);
        acc += pay; acc2 += pay * pay;
    }
    let mean = acc / paths as f64;
    ((-r * m.t).exp() * mean, (-r * m.t).exp() * ((acc2 / paths as f64 - mean * mean) / paths as f64).sqrt())
}

fn main() {
    let (s1, s2, q1, q2, v1, v2, rho, r, t) = (100.0, 100.0, 0.02, 0.02, 0.20, 0.20, 0.5, 0.05, 1.0);
    let m = Mkt { s1, s2, q1, q2, v1, v2, t };
    let sig = eff_vol(v1, v2, rho);
    let (a, b) = (s1 * (-q1 * t).exp(), s2 * (-q2 * t).exp());
    let d1 = ((a / b).ln() + 0.5 * sig * sig * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let v = margrabe(s1, s2, q1, q2, v1, v2, rho, t);
    let (v_cond, v_cond0, v_cond10) = (conditional(&m, r, rho, 4000), conditional(&m, 0.0, rho, 4000), conditional(&m, 0.10, rho, 4000));
    let (v_mc, se) = simulate(&m, r, rho, 1000000);
    let (v_mc1, _) = simulate(&m, r, 1.0, 20000);
    let cash = 100.0 * (-r * t).exp();                          // a zero-coupon bond paying $100 at T
    let v_cash = margrabe(s1, cash, q1, 0.0, v1, 0.0, 0.0, t);
    let c_bs = bs_call(s1, 100.0, r, q1, v1, t);
    let h = 0.01;
    let g = |x: f64, y: f64| margrabe(x, y, q1, q2, v1, v2, rho, t);
    let dl1 = (g(s1 + h, s2) - g(s1 - h, s2)) / (2.0 * h);
    let dl2 = (g(s1, s2 + h) - g(s1, s2 - h)) / (2.0 * h);
    let vega = (margrabe(s1, s2, q1, q2, v1 + h, v2, rho, t) - margrabe(s1, s2, q1, q2, v1 - h, v2, rho, t)) / 2.0;
    let corr = (margrabe(s1, s2, q1, q2, v1, v2, rho + h, t) - margrabe(s1, s2, q1, q2, v1, v2, rho - h, t)) / 2.0;
    let gam = g(s1 + 1.0, s2) - 2.0 * v + g(s1 - 1.0, s2);

    let rows: Vec<(&str, f64)> = vec![
        ("effective variance sigma^2", sig * sig), ("effective vol sigma", sig), ("effective vol, rho = -1", eff_vol(v1, v2, -1.0)),
        ("share 1 today, S1 e^-q1T", a), ("share 2 today, S2 e^-q2T", b),
        ("d1", d1), ("d2", d2), ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("Acme half", a * n_cdf(d1)), ("Birch half", b * n_cdf(d2)),
        ("1 Margrabe formula", v), ("2 conditional integral, r = 5%", v_cond),
        ("3 simulation, 1000000 pairs", v_mc), ("  standard error", se),
        ("  conditional integral, r = 0%", v_cond0), ("  conditional integral, r = 10%", v_cond10),
        ("rho = 1, formula", margrabe(s1, s2, q1, q2, v1, v2, 1.0, t)), ("rho = 1, simulation", v_mc1),
        ("cash case: Margrabe, bond S2 = 95.12", v_cash), ("cash case: Black-Scholes call", c_bs),
        ("delta 1, bump", dl1), ("  e^-q1T N(d1)", a / s1 * n_cdf(d1)),
        ("delta 2, bump", dl2), ("  -e^-q2T N(d2)", -b / s2 * n_cdf(d2)),
        ("S1 delta1 + S2 delta2", s1 * dl1 + s2 * dl2), ("gamma 1, per $1", gam),
        ("vega of share 1, per vol point", vega), ("correlation, per 0.01", corr),
        ("wrong: correlation left out", margrabe(s1, s2, q1, q2, v1, v2, 0.0, t)),
        ("wrong: +2 rho instead of -2 rho", margrabe(s1, s2, q1, q2, 0.12f64.sqrt(), 0.0, 0.0, t)),
        ("wrong: rho s1 s2 without the 2", margrabe(s1, s2, q1, q2, 0.06f64.sqrt(), 0.0, 0.0, t)),
        ("wrong: share 2 as a fixed $100 strike", c_bs),
        ("wrong: dividends dropped", margrabe(s1, s2, 0.0, 0.0, v1, v2, rho, t)),
        ("try: rho = -1", margrabe(s1, s2, q1, q2, v1, v2, -1.0, t)),
        ("try: S1 = 110", margrabe(110.0, s2, q1, q2, v1, v2, rho, t)),
        ("try: share 2 vol 30%", margrabe(s1, s2, q1, q2, v1, 0.30, rho, t)),
    ];
    for (name, x) in &rows { println!("{:<40} {:>12.6}", name, x); }
    let rhos: Vec<f64> = (0..9).map(|i| -1.0 + 0.25 * i as f64).collect();
    let row = |xs: Vec<String>| xs.join(" ");
    println!("chart, correlation {}", row(rhos.iter().map(|x| format!("{:6.2}", x)).collect()));
    println!("chart, price       {}", row(rhos.iter().map(|x| format!("{:6.2}", margrabe(s1, s2, q1, q2, v1, v2, *x, t))).collect()));
    let ends: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, share 1 end {}", row(ends.iter().map(|x| format!("{:6.0}", x)).collect()));
    for e2 in [100.0f64, 110.0] {
        println!("chart, profit {:.0}  {}", e2, row(ends.iter().map(|x| format!("{:6.2}", (x - e2).max(0.0) - v)).collect()));
    }

    assert!((v - 7.807839).abs() < 1e-6, "formula vs the shelf's house number");
    assert!((v_cond - v).abs() < 1e-8, "conditional integral lands on the formula");
    assert!((v_mc - v).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((v_cond10 - v).abs() < 1e-8, "bank rate 10%: same price");
    assert!((v_cond0 - v).abs() < 1e-8, "bank rate 0%: same price");
    assert!((v_cash - 9.227005508154).abs() < 1e-9, "cash case is the house vanilla");
    assert!(v_mc1 == 0.0, "perfect correlation: every simulated payoff is zero");
    assert!((s1 * dl1 + s2 * dl2 - v).abs() < 1e-6, "the price is shares only: Euler's identity");
    println!("ALL CHECKS PASS");
}
