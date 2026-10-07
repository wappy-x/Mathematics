// Hazard rate and survival probability -- the same check as the Python, in Rust.  Std only, no crates.
// The slice product is a loop, the integral is Simpson's rule, the inverse is bisection,
// and the coin flips come from a hand-written random number generator.
// Compile: rustc --edition 2021 -O hazard_rate_and_survival_probability_check.rs -o /tmp/hazard_check

const LAM: f64 = 0.02; // Northwind's flat hazard, per year

fn flat(_t: f64) -> f64 { LAM }
fn rising(t: f64) -> f64 { 0.01 + 0.004 * t } // 1% a year now, 3% a year at year 5

fn surv(lam: f64, t: f64) -> f64 { (-lam * t).exp() } // road 1: the formula, flat hazard

fn slices(hazard: fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // road 2: slice and multiply
    let dt = (b - a) / n as f64;
    let mut s = 1.0;
    for i in 0..n { s *= 1.0 - hazard(a + (i as f64 + 0.5) * dt) * dt; }
    s
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut tot = f(a) + f(b);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    tot * h / 3.0
}

fn surv_general(hazard: fn(f64) -> f64, t: f64) -> f64 { (-simpson(hazard, 0.0, t, 2000)).exp() }

fn invert(s: f64, t: f64) -> Option<f64> { // flat hazard giving survival s at t, by bisection
    if !(s > 0.0 && s <= 1.0) { return None; } // s = 0 or outside (0, 1]: no answer
    if s == 1.0 { return Some(0.0); }
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64);
    while (-hi * t).exp() > s { hi *= 2.0; }
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (-mid * t).exp() > s { lo = mid; } else { hi = mid; }
    }
    Some(0.5 * (lo + hi))
}

struct Rng { x: u64 } // 64-bit linear congruential generator
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.x >> 11) as f64 / 9007199254740992.0
    }
}

fn coin_flips(firms: usize, months: usize, seed: u64) -> Vec<f64> { // road 4: monthly flips
    let mut rng = Rng { x: seed };
    let mut dead = vec![0usize; months / 12 + 1];
    for _ in 0..firms {
        for m in 0..months {
            if rng.u() < LAM / 12.0 { dead[m / 12 + 1] += 1; break; }
        }
    }
    dead.iter().map(|&d| d as f64 / firms as f64).collect()
}

fn main() {
    let (s1, s2, s3, s5) = (surv(LAM, 1.0), surv(LAM, 2.0), surv(LAM, 3.0), surv(LAM, 5.0));
    let year3 = s2 - s3;
    let year3_int = simpson(|t| LAM * surv(LAM, t), 2.0, 3.0, 2000);
    let year3_cond = 1.0 - s3 / s2;
    let s5_slices = slices(flat, 0.0, 5.0, 100000);
    let pd5_int = simpson(|t| LAM * surv(LAM, t), 0.0, 5.0, 2000);
    let mc = coin_flips(100000, 60, 20260928);
    let mc5: f64 = mc.iter().sum();
    let se5 = (mc5 * (1.0 - mc5) / 100000.0).sqrt();
    let lam_85 = invert(0.85, 5.0).unwrap();
    let ln2 = 2.0_f64.ln();
    let rows: Vec<(&str, f64)> = vec![
        ("S(1)  survive one year", s1), ("S(2)", s2), ("S(3)", s3), ("S(5)  survive five years", s5),
        ("1 default chance by 5, 1 - S(5)", 1.0 - s5),
        ("2 slice product, 100000 slices, S(5)", s5_slices),
        ("3 integral of lambda S(t), 0 to 5", pd5_int),
        ("4 coin flips, 100000 firms, by 5", mc5), ("  one standard error", se5),
        ("year 3 default, S(2) - S(3)", year3), ("year 3 default, integral 2 to 3", year3_int),
        ("year 3 default given alive at 2", year3_cond), ("year 3 default, coin flips", mc[3]),
        ("mean default time 1/lambda", 1.0 / LAM), ("median default time ln2/lambda", ln2 / LAM),
        ("carbon-14 rate, ln2/5730", ln2 / 5730.0),
        ("S(15)/S(10)  next 5 years at year 10", surv(LAM, 15.0) / surv(LAM, 10.0)),
        ("invert S(5) = 0.904837 (bisection)", invert(s5, 5.0).unwrap()),
        ("invert S(5) = 0.85 (bisection)", lam_85), ("  -ln(0.85)/5", -(0.85_f64).ln() / 5.0),
        ("invert S(5) = 1", invert(1.0, 5.0).unwrap()), ("invert S(5) = 1e-12", invert(1e-12, 5.0).unwrap()),
        ("wrong: 1 - lambda T, 5 years", 1.0 - LAM * 5.0), ("wrong: 1 - lambda T, 30 years", 1.0 - LAM * 30.0),
        ("  right: S(30)", surv(LAM, 30.0)), ("wrong: 0.98^5, default by 5", 1.0 - 0.98_f64.powi(5)),
        ("wrong: lambda = (1 - S)/T from 0.85", 0.15 / 5.0),
        ("rising: S(5), exp(-area)", surv_general(rising, 5.0)),
        ("rising: S(5), slice product", slices(rising, 0.0, 5.0, 100000)),
        ("rising: next 5 years at year 5", surv_general(rising, 10.0) / surv_general(rising, 5.0)),
        ("try: flat 4%, S(5)", surv(0.04, 5.0)), ("try: flat 2%, S(10)", surv(LAM, 10.0)),
    ];
    for (name, v) in &rows { println!("{:<38} {:>12.6}", name, v); }
    println!("{:<38} {:>12}", "invert S(5) = 0", if invert(0.0, 5.0).is_none() { "no answer" } else { "BUG" });
    println!("slices  n     S(5) by slice product");
    for n in [5usize, 60, 1825] { println!("{:>12}  {:.6}", n, slices(flat, 0.0, 5.0, n)); }
    println!("year   flat %   rising %");
    for k in 1..6 {
        let (a, b) = ((k - 1) as f64, k as f64);
        let f = 100.0 * (surv(LAM, a) - surv(LAM, b));
        let g = 100.0 * (surv_general(rising, a) - surv_general(rising, b));
        println!("{:>4} {:8.2} {:10.2}", k, f, g);
    }
    let grid: Vec<f64> = (0..11).map(|i| 5.0 * i as f64).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, years      {}", join(grid.iter().map(|t| format!("{:6}", *t as i32)).collect()));
    println!("chart, exp(-lt)   {}", join(grid.iter().map(|t| format!("{:6.2}", surv(LAM, *t))).collect()));
    println!("chart, 1 - lt     {}", join(grid.iter().map(|t| format!("{:6.2}", 1.0 - LAM * t)).collect()));
    println!("chart, flat 0-10  {}", join((0..11).map(|t| format!("{:6.2}", surv(LAM, t as f64))).collect()));
    println!("chart, rising     {}", join((0..11).map(|t| format!("{:6.2}", surv_general(rising, t as f64))).collect()));

    assert!((s5_slices - s5).abs() < 1e-7, "slice product must converge on exp(-lambda T)");
    assert!((year3_int - year3).abs() < 1e-12, "integrated density must equal the survival drop");
    assert!((mc5 - (1.0 - s5)).abs() < 4.0 * se5, "coin flips within four standard errors");
    assert!((lam_85 - (-(0.85_f64).ln() / 5.0)).abs() < 1e-14, "bisection inverse must match -ln S / T");
    assert!((surv_general(rising, 5.0) - slices(rising, 0.0, 5.0, 100000)).abs() < 1e-7, "general case, two roads");
    assert!((pd5_int - (1.0 - s5)).abs() < 1e-12, "area under lambda S(t) must equal 1 - S(5)");
    assert!(invert(0.0, 5.0).is_none() && (invert(1e-12, 5.0).unwrap() + (1e-12_f64).ln() / 5.0).abs() < 1e-12, "inverse boundary cases");
    println!("ALL CHECKS PASS");
}
