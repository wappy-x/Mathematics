// Pricing a CDS -- the same check as the Python, in Rust.  No crates.
// Northwind five-year CDS: notional $10m, quarterly premiums, hazard 2% flat,
// recovery 40%, riskless rate 5% continuously compounded.  Nothing imported
// knows the answer: the integrator, root finder and random numbers are below.
const NOTIONAL: f64 = 10_000_000.0;
const T: f64 = 5.0;
const DELTA: f64 = 0.25;
const LAM: f64 = 0.02;
const R: f64 = 0.40;
const RATE: f64 = 0.05;
const BP: f64 = 1e4;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // area under f, n even
    let h = (b - a) / n as f64;
    let mut inner = 0.0;
    for i in 1..n { inner += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    (f(a) + f(b) + inner) * h / 3.0
}

fn dates(delta: f64) -> Vec<f64> {                // premium dates delta, 2 delta, ..., T
    (0..(T / delta).round() as usize).map(|j| delta * (j + 1) as f64).collect()
}

// road 2: dated sum and quadrature, any curves
fn legs(d: &dyn Fn(f64) -> f64, q: &dyn Fn(f64) -> f64, h: &dyn Fn(f64) -> f64) -> (f64, f64, f64) {
    let mut a = 0.0;
    for t in dates(DELTA) { a += DELTA * d(t) * q(t); }
    let p = (1.0 - R) * simpson(&|t| h(t) * q(t) * d(t), 0.0, T, 2000);
    let mut acc = 0.0;
    for t in dates(DELTA) {
        let s = t - DELTA;
        acc += simpson(&|u| (u - s) * h(u) * q(u) * d(u), s, s + DELTA, 200);
    }
    (a, p, acc)
}

fn closed(delta: f64, lam: f64) -> (f64, f64, f64) {   // road 1: flat curves, geometric series
    let c = RATE + lam;
    let x = (-c * delta).exp();
    let n = (T / delta).round();
    let a = delta * x * (1.0 - x.powf(n)) / (1.0 - x);
    let p = (1.0 - R) * lam * (1.0 - (-c * T).exp()) / c;
    (a, p, (1.0 - (-c * T).exp()) / c)             // last: the continuous-premium annuity
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // halve the bracket 100 times
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                 // splitmix64, then 53 bits into (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

// road 3: draw default dates, pay cash
fn monte_carlo(rng: &mut Rng, d: &dyn Fn(f64) -> f64, tau_of: &dyn Fn(f64) -> f64) -> (f64, f64, f64) {
    let paths = 400_000.0;
    let (mut a, mut p, mut aa, mut pp, mut ap) = (0.0, 0.0, 0.0, 0.0, 0.0);
    let ds = dates(DELTA);
    for _ in 0..400_000 {
        let tau = tau_of(-rng.uniform().ln());     // cumulative hazard reached at default
        let mut prem = 0.0;
        for &t in &ds { if t < tau { prem += DELTA * d(t); } }
        let pay = if tau <= T { (1.0 - R) * d(tau) } else { 0.0 };
        a += prem;
        p += pay;
        aa += prem * prem;
        pp += pay * pay;
        ap += prem * pay;
    }
    let s = p / a;                                 // std error of the spread P/A, from pay - s * prem
    let se = (pp - 2.0 * s * ap + s * s * aa).sqrt() / a;   // = sqrt(variance / paths) / mean annuity
    (a / paths, p / paths, se)
}

fn main() {
    let flat_d = |t: f64| (-RATE * t).exp();
    let flat_q = |t: f64| (-LAM * t).exp();
    let flat_h = |_t: f64| LAM;
    let (a1, p1, ac) = closed(DELTA, LAM);
    let (a2, p2, acc) = legs(&flat_d, &flat_q, &flat_h);
    let (s1, s2) = (p1 / a1, p2 / a2);
    let s_root = bisect(&|s| p2 - s * a2, 0.0, 1.0);
    let a_int = simpson(&|t| flat_d(t) * flat_q(t), 0.0, T, 2000);   // premiums paid every instant
    let mut rng = Rng(20260928);
    let (a3, p3, se3) = monte_carlo(&mut rng, &flat_d, &|e| e / LAM);
    let a_rl: f64 = dates(DELTA).iter().fold(0.0, |s, &t| s + DELTA * flat_d(t));
    let mut rows: Vec<(String, f64)> = vec![
        ("annuity, closed form", a1), ("annuity, dated sum", a2), ("annuity, simulation", a3),
        ("protection, closed form", p1), ("protection, Simpson", p2), ("protection, simulation", p3),
        ("par spread bp, closed form", s1 * BP), ("par spread bp, dated/Simpson", s2 * BP),
        ("par spread bp, root finder", s_root * BP), ("par spread bp, simulation", p3 / a3 * BP),
        ("  simulation std error, bp", se3 * BP), ("  simulation paths", 400_000.0),
        ("continuous annuity, closed form", ac), ("continuous annuity, Simpson", a_int),
        ("par spread bp, continuous", p1 / a_int * BP),
        ("(1-R) x hazard, bp", (1.0 - R) * LAM * BP),
        ("accrual per unit spread", acc), ("par spread bp, with accrual", p2 / (a2 + acc) * BP),
        ("D(5) e^-rT", flat_d(T)), ("Q(5) e^-lambda T", flat_q(T)), ("default chance by 5y", 1.0 - flat_q(T)),
        ("D(5)Q(5) e^-(r+lambda)T", (-(RATE + LAM) * T).exp()), ("1 - e^-(r+lambda)T", 1.0 - (-(RATE + LAM) * T).exp()),
        ("x = e^-(r+lambda)/4", (-(RATE + LAM) * DELTA).exp()), ("1 - x", 1.0 - (-(RATE + LAM) * DELTA).exp()),
        ("$ protection leg on $10m", p1 * NOTIONAL), ("$ one bp of premium, PV", a1 * NOTIONAL / BP),
        ("$ quarterly premium at par", s1 * DELTA * NOTIONAL),
        ("wrong: no survival in annuity", p1 / a_rl * BP), ("  riskless annuity", a_rl),
        ("wrong: protection undiscounted", (1.0 - R) * (1.0 - flat_q(T)) / a1 * BP),
        ("wrong: R in place of 1-R", R / (1.0 - R) * s1 * BP),
        ("wrong: full spread each quarter", p1 / (a1 / DELTA) * BP),
    ].into_iter().map(|(n, v)| (n.to_string(), v)).collect();
    for (name, delta) in [("annual", 1.0), ("semiannual", 0.5), ("quarterly", 0.25), ("monthly", 1.0 / 12.0)] {
        let (af, pf, _) = closed(delta, LAM);
        rows.push((format!("spread bp, {} premiums", name), pf / af * BP));
    }
    for (name, lam) in [("try: hazard 4%", 0.04), ("try: hazard 0", 0.0)] {
        let (af, pf, _) = closed(DELTA, lam);
        rows.push((name.to_string(), pf / af * BP));
    }
    // a general curve: zero rate 3% rising 0.6% a year, hazard 1% rising 0.4% a year
    let g_d = |t: f64| (-(0.03 + 0.006 * t) * t).exp();
    let g_q = |t: f64| (-(0.01 * t + 0.002 * t * t)).exp();
    let g_h = |t: f64| 0.01 + 0.004 * t;
    let (ga2, gp2, _) = legs(&g_d, &g_q, &g_h);
    let (ga3, gp3, gse3) = monte_carlo(&mut rng, &g_d, &|e| (-0.01 + (0.0001 + 0.008 * e).sqrt()) / 0.004);
    for (n, v) in [("curve: annuity, dated sum", ga2), ("curve: annuity, simulation", ga3),
                   ("curve: protection, Simpson", gp2), ("curve: protection, simulation", gp3),
                   ("curve: par spread bp", gp2 / ga2 * BP), ("curve: spread bp, simulation", gp3 / ga3 * BP),
                   ("  simulation std error, bp", gse3 * BP)] {
        rows.push((n.to_string(), v));
    }
    for (name, v) in &rows { println!("{:<34} {:>16.6}", name, v); }
    println!();
    let spreads: Vec<f64> = (0..7).map(|i| 40.0 * i as f64).collect();
    let line = |label: &str, vals: Vec<String>| println!("{:<23}{}", label, vals.join(" "));
    line("chart, spread bp", spreads.iter().map(|s| format!("{:7}", *s as i64)).collect());
    line("chart, premium leg $k", spreads.iter().map(|s| format!("{:7.2}", s / BP * a1 * NOTIONAL / 1e3)).collect());
    line("chart, protection $k", spreads.iter().map(|_| format!("{:7.2}", p1 * NOTIONAL / 1e3)).collect());
    line("chart, year", (1..6).map(|y| format!("{:7}", y)).collect());
    line("chart, D(t)Q(t)", (1..6).map(|y| format!("{:7.2}", flat_d(y as f64) * flat_q(y as f64))).collect());
    line("chart, D(t)", (1..6).map(|y| format!("{:7.2}", flat_d(y as f64))).collect());
    assert!((a2 - a1).abs() < 1e-12 && (p2 - p1).abs() < 1e-10, "dated sum and Simpson vs closed form");
    assert!((s_root - s1).abs() < 1e-12, "root finder lands on protection / annuity");
    assert!((p3 / a3 - s1).abs() < 4.0 * se3, "simulation within four standard errors");
    assert!((gp3 / ga3 - gp2 / ga2).abs() < 4.0 * gse3, "general curve: simulation vs quadrature");
    assert!((p1 / a_int - (1.0 - R) * LAM).abs() < 1e-12, "closed protection / Simpson annuity = (1-R) x hazard");
    println!("ALL CHECKS PASS");
}
