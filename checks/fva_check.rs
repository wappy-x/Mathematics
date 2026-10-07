// FVA -- the same check as fva_check.py, in Rust.  Standard library only, no crates.
// The Acme call (S = K = 100, r = 5%, q = 2%, sigma = 20%, T = 1) bought from Northwind with
// no collateral.  The bank funds at 100 bp over the collateral rate r; Northwind's hazard is
// 2% a year, the bank's own 1%, recovery 40% each.  The normal CDF is a series, integrals are
// Simpson's rule, random numbers are splitmix64.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const RATE: f64 = 0.05;
const Q_DIV: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const SF: f64 = 0.01; // funding spread
const LC: f64 = 0.02; // Northwind's hazard
const LO: f64 = 0.01; // the bank's own hazard
const RO: f64 = 0.40; // the bank's recovery

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }  // bell-curve height
fn n_cdf(x: f64) -> f64 {                                         // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { k += 2.0; term *= x * x / k; total += term; }
    0.5 + phi(x) * total
}

fn bs(s: f64, left: f64, put: bool) -> f64 {                      // Acme option with `left` years to run
    if left <= 1e-12 { return if put { (K - s).max(0.0) } else { (s - K).max(0.0) }; }
    let v = SIG * left.sqrt();
    let d1 = ((s / K).ln() + (RATE - Q_DIV + 0.5 * SIG * SIG) * left) / v;
    if put { return K * (-RATE * left).exp() * n_cdf(v - d1) - s * (-Q_DIV * left).exp() * n_cdf(-d1); }
    s * (-Q_DIV * left).exp() * n_cdf(d1) - K * (-RATE * left).exp() * n_cdf(d1 - v)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // area under f, n even
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

// discounted expected funding need D(t) E[need(V(t))], integrated over Acme's price at t
fn dee<G: Fn(f64) -> f64>(t: f64, need: G) -> f64 {
    let (drift, vol) = ((RATE - Q_DIV - 0.5 * SIG * SIG) * t, SIG * t.sqrt());
    let lo = if t < T { -8.0 } else { ((K / S).ln() - drift) / vol };   // at expiry, start at the kink
    let f = |z: f64| need(bs(S * (drift + vol * z).exp(), T - t, false)) * phi(z);
    (-RATE * t).exp() * simpson(f, lo, 8.0, 2000)
}
fn pos(v: f64) -> f64 { v.max(0.0) }
fn surv(t: f64, lam: f64) -> f64 { (-lam * t).exp() }              // survival to t

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
    }
    fn acme_at(&mut self, t: f64) -> f64 {
        let (u1, u2) = (self.uniform(), self.uniform());
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        S * ((RATE - Q_DIV - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp()
    }
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    (m, ((xs.iter().map(|x| x * x).sum::<f64>() / n - m * m) / n).sqrt())
}

fn main() {
    let (c0, p0) = (bs(S, T, false), bs(S, T, true));
    let fca_closed = SF * c0 * (1.0 - surv(T, LC)) / LC;          // road 1: flat exposure, integrated
    let weekly: Vec<f64> = (0..52).map(|i| {                       // road 2: 52 weekly buckets
        SF * dee((i as f64 + 0.5) / 52.0, pos) * (surv(i as f64 / 52.0, LC) - surv((i + 1) as f64 / 52.0, LC)) / LC
    }).collect();
    let fca_52: f64 = weekly.iter().sum();

    let mut rng = Rng(20260928);                                   // road 3: simulation
    let m = 400000;
    let mut draws = Vec::with_capacity(m);
    for _ in 0..m {                        // a date u in the year, Acme at u, Northwind's default date
        let u = rng.uniform() * T;
        let s_u = rng.acme_at(u);
        let alive = -rng.uniform().ln() / LC > u;
        draws.push(if alive { SF * T * (-RATE * u).exp() * bs(s_u, T - u, false) } else { 0.0 });
    }
    let (fca_mc, se_fca) = mean_se(&draws);

    // the sold call: the bank holds Northwind's premium, a negative exposure worth C0 in today's money
    let fba = SF * simpson(|t| dee(t, pos) * surv(t, LC), 0.0, T, 8);
    let fca_sold = SF * simpson(|t| dee(t, |v| (-v).max(0.0)) * surv(t, LC), 0.0, T, 8);
    let s_credit = (1.0 - RO) * LO;                                // the part of the spread that is default
    let fba_credit = s_credit * c0 * (1.0 - surv(T, LC)) / LC;
    let fba_credit2 = s_credit * c0 * (1.0 - surv(T, LC + LO)) / (LC + LO);
    let fba_liquid = (SF - s_credit) * c0 * (1.0 - surv(T, LC)) / LC;
    let pd_o = 1.0 - surv(T, LO);
    draws.clear();
    for _ in 0..m {                        // DVA by simulation: the bank defaults first, owing V
        let tau = -(1.0 - rng.uniform() * pd_o).ln() / LO;
        let s_tau = rng.acme_at(tau);
        let first = -rng.uniform().ln() / LC > tau;
        draws.push(if first { (1.0 - RO) * pd_o * (-RATE * tau).exp() * bs(s_tau, T - tau, false) } else { 0.0 });
    }
    let (dva_mc, se_dva) = mean_se(&draws);
    // collateralised twin: Step 1 says V(0) = E[D(T) X] at the collateral rate; simulate the payoff
    let pay: Vec<f64> = (0..m).map(|_| (-RATE * T).exp() * (rng.acme_at(T) - K).max(0.0)).collect();
    let (dx_mc, se_dx) = mean_se(&pay);

    let (c, y, rs) = (100000.0, 5, 0.02);                          // folded example: a bought cash stream
    let d = |t: f64, rate: f64| (-rate * t).exp();
    let stream_exact: f64 = (1..=y).map(|k| c * (d(k as f64, rs) - d(k as f64, rs + SF))).sum();
    let stream_200: f64 = (1..=y).map(|k| c * (d(k as f64, rs) - d(k as f64, rs + 2.0 * SF))).sum();
    let stream_lin = SF * (1..=y).map(|k| k as f64 * c * d(k as f64, rs)).sum::<f64>();
    let n = 5000;
    let stream_lin2 = SF * (0..n).map(|j| {
        let mid = (j as f64 + 0.5) * y as f64 / n as f64;
        (1..=y).filter(|k| *k as f64 > mid).map(|k| c * d(k as f64, rs)).sum::<f64>() * y as f64 / n as f64
    }).sum::<f64>();

    let rows: Vec<(&str, f64)> = vec![
        ("clean call C0", c0), ("clean put P0", p0), ("funding spread s_F", SF),
        ("discount factor D(1)", (-RATE * T).exp()), ("Northwind survival Q_C(1)", surv(T, LC)),
        ("expected years alive (1-e^-lam T)/lam", (1.0 - surv(T, LC)) / LC),
        ("1 closed form s C0 (1-e^-lam T)/lam", fca_closed), ("2 bucketed sum, 52 weeks", fca_52),
        ("3 simulated, 400000 draws", fca_mc), ("  standard error", se_fca),
        ("funded call C0 - FVA", c0 - fca_closed), ("collateral-rate value E[D(T)X], sim.", dx_mc), ("  standard error", se_dx), ("FCA at 200 bp", 2.0 * fca_52),
        ("sold call: FCA", fca_sold), ("sold call: FBA", fba),
        ("  credit part of spread (1-R_O)lam_O", s_credit), ("  FBA, credit part", fba_credit),
        ("  FBA, credit part, both survivals", fba_credit2),
        ("  FBA, liquidity part", fba_liquid), ("  bank DVA, simulated", dva_mc), ("  standard error", se_dva),
        ("wrong: no survival weight", SF * c0 * T), ("wrong: full funding rate r+s_F", (RATE + SF) * fca_52 / SF),
        ("wrong: funding-rate discount, collat.", c0 * (1.0 - (-SF * T).exp())), ("wrong: FBA plus DVA", fba + fba_credit2),
        ("compounded, not linear", SF * c0 * (1.0 - surv(T, LC + SF)) / (LC + SF)),
        ("try: long put", SF * p0 * (1.0 - surv(T, LC)) / LC), ("try: 5-year call", SF * bs(S, 5.0, false) * (1.0 - surv(5.0, LC)) / LC),
        ("stream: FVA, discount at 3% vs 2%", stream_exact), ("stream: same at 200 bp", stream_200),
        ("stream: linear, closed form", stream_lin), ("stream: linear, integrated", stream_lin2),
        ("stream: integral of discounted need", stream_lin2 / SF), ("stream: linear minus exact", stream_lin - stream_exact),
    ];
    for (name, v) in &rows { println!("{:<38}{:14.6}", name, v); }
    println!();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, quarter end    {}", join([0.0, 0.25, 0.5, 0.75, 1.0].iter().map(|t: &f64| format!("{:6.2}", t)).collect()));
    let mut cum = vec![0.0];
    for j in 1..5 { cum.push(100.0 * weekly[..13 * j].iter().sum::<f64>()); }
    println!("chart, FCA cents 100bp{}", join(cum.iter().map(|c| format!("{:6.2}", c)).collect()));
    println!("chart, FCA cents 200bp{}", join(cum.iter().map(|c| format!("{:6.2}", 2.0 * c)).collect()));
    println!("bars, cents: FBA credit, liquidity; credit both surv., DVA {}",
        join([fba_credit, fba_liquid, fba_credit2, dva_mc].iter().map(|x| format!("{:.2}", 100.0 * x)).collect()));

    assert!((c0 - 9.227005508154).abs() < 1e-9, "own normal CDF reproduces the house call");
    assert!((fca_52 - fca_closed).abs() < 1e-6, "weekly sum with integrated exposure matches the flat-exposure integral");
    assert!((fca_mc - fca_closed).abs() < 4.0 * se_fca, "simulation within four standard errors");
    assert!((dva_mc - fba_credit2).abs() < 4.0 * se_dva, "credit part of the FBA is the bank's DVA");
    assert!((dx_mc - c0).abs() < 4.0 * se_dx, "collateralised twin: payoff discounted at r averages to C0");
    assert!((stream_lin2 - stream_lin).abs() < 1e-6 * stream_lin, "stream: two roads to the linear FVA");
    println!("ALL CHECKS PASS");
}
