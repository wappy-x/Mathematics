// A random hazard (Cox process): the same check as stochastic_hazard_cox_process_check.py, in Rust.
// Standard library only, no crates. Random numbers, ODE stepper and integrator are written here.
const K: f64 = 0.5; const TH: f64 = 0.02; const SIG: f64 = 0.10; const L0: f64 = 0.02; const T: f64 = 5.0;
const R: f64 = 0.05; const REC: f64 = 0.40; const DELTA: f64 = 0.25;
const PI: f64 = std::f64::consts::PI;

fn cir_ab(t: f64, k: f64, th: f64, s: f64, two: f64, power: bool) -> (f64, f64, f64) {   // road 1
    let g = (k * k + two * s * s).sqrt();
    let e = (g * t).exp(); let den = (g + k) * (e - 1.0) + 2.0 * g;
    let base = 2.0 * g * ((g + k) * t / 2.0).exp() / den;
    (if power { base.powf(2.0 * k * th / (s * s)) } else { base }, 2.0 * (e - 1.0) / den, g)
}
fn qf(t: f64, l0: f64, k: f64, s: f64, two: f64, power: bool) -> f64 {
    if t == 0.0 { return 1.0; }
    let (a, b, _) = cir_ab(t, k, TH, s, two, power);
    a * (-b * l0).exp()
}
fn q(t: f64) -> f64 { qf(t, L0, K, SIG, 2.0, true) }
fn riccati_q(t: f64, n: usize) -> f64 {                        // road 2: the two Riccati equations, stepped
    let f = |b: f64| 1.0 - K * b - 0.5 * SIG * SIG * b * b;
    let (h, mut b, mut lna) = (t / n as f64, 0.0_f64, 0.0_f64);
    for _ in 0..n {
        let k1 = f(b); let k2 = f(b + h * k1 / 2.0); let k3 = f(b + h * k2 / 2.0); let k4 = f(b + h * k3);
        lna -= K * TH * h * (b + 2.0 * (b + h * k1 / 2.0) + 2.0 * (b + h * k2 / 2.0) + (b + h * k3)) / 6.0;
        b += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
    }
    (lna - b * L0).exp()
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
struct Rng { s: u64 }                                          // splitmix64 + Box-Muller
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2.0_f64.powi(-53)
    }
    fn pair(&mut self) -> (f64, f64) {
        let a = 1.0 - self.u(); let b = self.u();
        let rad = (-2.0 * a.ln()).sqrt();
        (rad * (2.0 * PI * b).cos(), rad * (2.0 * PI * b).sin())
    }
    fn draws(&mut self, n: usize) -> Vec<f64> {
        let mut zs = Vec::with_capacity(2 * n);
        for _ in 0..n { let (x, y) = self.pair(); zs.push(x); zs.push(y); }
        zs
    }
}
fn path(zs: &[f64], sign: f64, dt: f64) -> (f64, Vec<f64>) {  // one hazard path from the SDE
    let (mut l, mut area, mut ls) = (L0, 0.0_f64, vec![L0]);
    for z in zs {
        let nl = (l + K * (TH - l) * dt + SIG * l.sqrt() * sign * z * dt.sqrt()).max(0.0);
        area += 0.5 * (l + nl) * dt; l = nl; ls.push(l);
    }
    (area, ls)
}
fn tot(xs: &[f64]) -> f64 { let mut s = 0.0; for x in xs { s += x; } s }
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let m = tot(xs) / xs.len() as f64;
    let sq: Vec<f64> = xs.iter().map(|x| (x - m) * (x - m)).collect();
    (m, (tot(&sq) / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}
fn par_bp<F: Fn(f64) -> f64>(qq: F) -> f64 {                   // par spread from the Simpson legs
    let ann: Vec<f64> = (1..=20).map(|j| DELTA * (-R * DELTA * j as f64).exp() * qq(DELTA * j as f64)).collect();
    let prot = (1.0 - REC) * (1.0 - (-R * T).exp() * qq(T) - R * simpson(|t| (-R * t).exp() * qq(t), 0.0, T, 2000));
    prot / tot(&ann) * 1e4
}
fn par_flat(lam: f64) -> f64 {                                 // the flat closed form from the CDS card
    let c = R + lam; let x = (-c * DELTA).exp();
    (1.0 - REC) * lam * (1.0 - (-c * T).exp()) / c / (DELTA * x * (1.0 - x.powf(20.0)) / (1.0 - x)) * 1e4
}
fn mean_l(s: f64) -> f64 { TH + (L0 - TH) * (-K * s).exp() }
fn var_l(s: f64) -> f64 {
    let a = 1.0 - (-K * s).exp();
    L0 * (SIG * SIG) / K * ((-K * s).exp() - (-2.0 * K * s).exp()) + TH * (SIG * SIG) / (2.0 * K) * (a * a)
}
fn main() {
    let (a5, b5, g) = cir_ab(T, K, TH, SIG, 2.0, true);
    let e5 = (g * T).exp(); let den5 = (g + K) * (e5 - 1.0) + 2.0 * g; let base5 = 2.0 * g * ((g + K) * T / 2.0).exp() / den5;
    let (q1, q2, flat) = (q(T), riccati_q(T, 1000), (-0.02 * T).exp());
    let (pairs, steps) = (50000usize, 100usize); let dt = T / steps as f64;
    let mut rng = Rng { s: 20260928 };
    let (mut avg, mut alive, mut l1, mut frz) = (Vec::new(), 0usize, Vec::new(), Vec::new());
    for _ in 0..pairs {                                        // roads 3 and 4
        let zs = rng.draws(steps / 2);
        let es = [-(1.0 - rng.u()).ln(), -(1.0 - rng.u()).ln()];
        let mut pv = 0.0;
        for (sign, e) in [1.0_f64, -1.0].iter().zip(es.iter()) {
            let (area, ls) = path(&zs, *sign, dt);
            pv += 0.5 * (-area).exp(); if area < *e { alive += 1; }
            l1.push(ls[steps / 5]); frz.push((-T * ls[steps]).exp());
        }
        avg.push(pv);
    }
    let (q3, se3) = mean_se(&avg); let q4 = alive as f64 / (2 * pairs) as f64;
    let se4 = (q4 * (1.0 - q4) / 100000.0).sqrt();
    let el = simpson(mean_l, 0.0, T, 2000);
    let vl = 2.0 * simpson(|s| var_l(s) * (1.0 - (-K * (T - s)).exp()) / K, 0.0, T, 2000);
    let m1 = tot(&l1) / l1.len() as f64;
    let sq: Vec<f64> = l1.iter().map(|x| (x - m1) * (x - m1)).collect();
    let sd1 = (tot(&sq) / (l1.len() - 1) as f64).sqrt();
    let ct = SIG * SIG * (1.0 - (-K * T).exp()) / (4.0 * K);   // frozen-hazard mistake: E[exp(-T lam_T)]
    let frozen = (1.0 + 2.0 * T * ct).powf(-2.0 * K * TH / (SIG * SIG)) * (-T * L0 * (-K * T).exp() / (1.0 + 2.0 * T * ct)).exp();
    let (s_flat, s_cf, s_cox) = (par_bp(|t| (-0.02 * t).exp()), par_flat(0.02), par_bp(q));
    let rows: Vec<(&str, f64)> = vec![("gamma", g), ("e^(gamma T)", e5), ("denominator (g+k)(e^gT - 1) + 2g", den5), ("B(5)", b5),
        ("bracket inside A", base5), ("A(5)", a5), ("e^(-B(5) lambda0)", (-b5 * L0).exp()), ("Feller ratio nu = 2 k theta / sigma^2", 2.0 * K * TH / (SIG * SIG)),
        ("shock size at 2%, sigma sqrt(lambda0)", SIG * L0.sqrt()),
        ("1 closed form Q(5)", q1), ("2 Riccati stepped Q(5)", q2), ("3 simulated mean of e^-area", q3),
        ("  standard error", se3), ("4 simulated share never defaulting", q4), ("  standard error", se4),
        ("flat 2% survival e^-0.1", flat), ("E[area] by Simpson", el), ("Var[area] by Simpson", vl),
        ("Jensen gap Q - e^-E[area]", q1 - (-el).exp()), ("  half Var times e^-E[area]", 0.5 * vl * (-el).exp()),
        ("  ln Q + E - Var/2 (the rest)", q1.ln() + el - 0.5 * vl),
        ("sd of hazard at 1 year, formula", var_l(1.0).sqrt()), ("sd of hazard at 1 year, simulated", sd1),
        ("par spread bp, flat 2%, Simpson", s_flat), ("par spread bp, flat 2%, closed form", s_cf),
        ("par spread bp, random hazard", s_cox), ("  difference bp", s_cox - s_flat),
        ("wrong: power nu dropped", qf(T, L0, K, SIG, 2.0, false)), ("wrong: sigma^2 not 2 sigma^2 in gamma", qf(T, L0, K, SIG, 1.0, true)),
        ("wrong: hazard frozen at year 5, formula", frozen), ("  simulated", tot(&frz) / frz.len() as f64),
        ("try: kappa = 2", qf(T, L0, 2.0, SIG, 2.0, true)), ("try: sigma = 0.20, Feller ratio 0.5", qf(T, L0, K, 0.2, 2.0, true))];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    println!("gap by maturity, bp of survival, 1..10 years:");
    let gaps: Vec<String> = (1..=10).map(|t| format!("{:.2}", (q(t as f64) - (-0.02 * t as f64).exp()) * 1e4)).collect();
    println!("{}", gaps.join(" "));
    println!("sigma, Feller ratio, five-year survival gain over flat (bp):");
    for s in [0.05_f64, 0.10, 0.15, 0.20] {
        println!("  {:.2}  {:5.2}  {:6.2}", s, 2.0 * K * TH / (s * s), (qf(T, L0, K, s, 2.0, true) - flat) * 1e4);
    }
    println!("start hazard %, par spread bp random, par spread bp flat:");
    for i in 0..6 {
        let l0 = i as f64 / 100.0;
        let fl = if l0 > 0.0 { par_flat(l0) } else { 0.0 };
        println!("  {}  {:7.2}  {:7.2}", i, par_bp(|t| qf(t, l0, K, SIG, 2.0, true)), fl);
    }
    println!("three hazard paths, % a year, every half year 0..5:");
    let mut rng = Rng { s: 7 };
    for _ in 0..3 {
        let zs = rng.draws(50);
        let ls = path(&zs, 1.0, 0.05).1;
        let pts: Vec<String> = ls.iter().step_by(10).map(|x| format!("{:.2}", 100.0 * x)).collect();
        println!("{}", pts.join(" "));
    }
    assert!((q1 - 0.9056646181).abs() < 1e-9, "closed form vs the card's worked number");
    assert!((q2 - q1).abs() < 1e-10, "stepped Riccati equations must land on the closed form");
    assert!((q3 - q1).abs() < 4.0 * se3 && (q4 - q1).abs() < 4.0 * se4, "both simulations within four standard errors");
    assert!(q1 > (-el).exp() && (q1 - (-el).exp() - 0.5 * vl * (-el).exp()).abs() < 3e-5, "Jensen: above, by about half the variance");
    assert!((s_flat - s_cf).abs() < 1e-6, "Simpson legs vs the flat closed form");
    assert!((frozen - tot(&frz) / frz.len() as f64).abs() < 2e-4, "frozen-hazard formula vs the simulated paths");
    println!("ALL CHECKS PASS");
}
