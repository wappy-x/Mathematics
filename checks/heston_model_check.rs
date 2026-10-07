// The Heston model -- the same check as the Python, in Rust.  No crates: the normal CDF is its
// own series, random numbers are splitmix64 made normal by the polar method, implied vols come
// from bisection.  rho = 0 by three roads: (1) Black-Scholes averaged over simulated average
// variance, (2) plain Monte Carlo, (3) the Hull-White expansion.  rho = -0.7 by two roads.
use std::f64::consts::PI;
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
const V0: f64 = 0.04; const THETA: f64 = 0.04; const KAPPA: f64 = 2.0; const XI: f64 = 0.3; const RHO: f64 = -0.7;
const STRIKES: [f64; 7] = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0];
const PATHS: usize = 100000; const STEPS: usize = 50; const DT: f64 = T / STEPS as f64;
fn mean_vbar(v0: f64, k: f64, t: f64) -> f64 { THETA + (v0 - THETA) * (1.0 - (-k * t).exp()) / (k * t) }
fn stepped_vbar(v0: f64, k: f64, t: f64) -> f64 {  // the same, by stepping d E[v] = kappa (theta - E[v]) dt
    let h = t / 100000.0;
    (0..100000).fold((v0, 0.0), |(m, acc), _| (m + k * (THETA - m) * h, acc + m * h)).1 / t
}
fn n_cdf(x: f64) -> f64 {                          // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut term, mut total, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 { term *= x * x / (2.0 * n + 1.0); total += term; n += 1.0; }
    0.5 + (-0.5 * x * x).exp() / (2.0 * PI).sqrt() * total
}
fn bs(s: f64, k: f64, w: f64, put: bool) -> f64 {  // Black-Scholes; w = total variance over the life
    let sd = w.sqrt();
    let d1 = ((s / k).ln() + (R - Q) * T + 0.5 * w) / sd;
    let call = s * (-Q * T).exp() * n_cdf(d1) - k * (-R * T).exp() * n_cdf(d1 - sd);
    if put { call - s * (-Q * T).exp() + k * (-R * T).exp() } else { call }
}
fn implied(price: f64, k: f64, put: bool) -> f64 {  // bisection: price rises with sigma, so one sigma fits
    assert!(bs(S, k, 1e-4 * T, put) < price && price < bs(S, k, T, put), "price inside the bracket, 1% to 100%");
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if bs(S, k, mid * mid * T, put) < price { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
struct Normals { state: u64, spare: Option<f64> }  // splitmix64 uniforms on (-1, 1), polar method
impl Normals {
    fn uniform(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.state ^ (self.state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        2.0 * ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 - 1.0
    }
    fn next(&mut self) -> f64 {
        if let Some(b) = self.spare.take() { return b; }
        loop {
            let (a, b) = (self.uniform(), self.uniform()); let s = a * a + b * b;
            if s > 0.0 && s < 1.0 { let f = (-2.0 * s.ln() / s).sqrt(); self.spare = Some(b * f); return a * f; }
        }
    }
}
#[derive(Clone, Copy)] struct Acc { n: f64, s: f64, s2: f64 }              // running mean and standard error
impl Acc {
    fn new() -> Acc { Acc { n: 0.0, s: 0.0, s2: 0.0 } }
    fn add(&mut self, x: f64) { self.n += 1.0; self.s += x; self.s2 += x * x; }
    fn mean(&self) -> f64 { self.s / self.n }
    fn se(&self) -> f64 { ((self.s2 - self.n * self.mean() * self.mean()) / (self.n - 1.0) / self.n).sqrt() }
}
fn variance_path(g: &mut Normals, xi: f64) -> (f64, f64, usize) {  // full-truncation Euler
    let (mut v, mut i, mut cut) = (V0, 0.0, 0);
    for _ in 0..STEPS {
        let vp = if v > 0.0 { v } else { 0.0 }; if v <= 0.0 { cut += 1; }
        i += vp * DT;
        v += KAPPA * (THETA - vp) * DT + xi * (vp * DT).sqrt() * g.next();
    }
    (v, i, cut)
}
struct Mix { mix0: Vec<Acc>, mix7: Vec<Acc>, plus7: Vec<Acc>, atm: Acc, term: Acc, avg: Acc, hist: [usize; 7], cut: usize }
fn mixing_road(seed: u64, xi: f64, paths: usize, fwd: f64) -> Mix {  // road 1: variance paths, then Black-Scholes
    let mut g = Normals { state: seed, spare: None };
    let mut m = Mix { mix0: vec![Acc::new(); 7], mix7: vec![Acc::new(); 7], plus7: vec![Acc::new(); 2],
                      atm: Acc::new(), term: Acc::new(), avg: Acc::new(), hist: [0; 7], cut: 0 };
    for _ in 0..paths {
        let (vt, i, c) = variance_path(&mut g, xi); m.cut += c;
        let j_noise = (vt - V0 - KAPPA * THETA * T + KAPPA * i) / xi;   // the variance's own noise
        m.avg.add(i / T); m.atm.add(bs(S, 100.0, i, false)); m.term.add(bs(S, 100.0, vt.max(1e-10) * T, false));
        m.hist[((((i / T).sqrt() * 100.0 - 13.0) / 2.0) as i64).max(0).min(6) as usize] += 1;
        let s7 = S * (RHO * j_noise - 0.5 * RHO * RHO * i).exp();       // rho = -0.7: the shifted spot
        for (j, &k) in STRIKES.iter().enumerate() {
            m.mix0[j].add(bs(S, k, i, k < fwd)); m.mix7[j].add(bs(s7, k, (1.0 - RHO * RHO) * i, k < fwd));
        }
        for (j, &k) in [80.0, 120.0].iter().enumerate() { m.plus7[j].add(bs(S * (0.7 * j_noise - 0.245 * i).exp(), k, 0.51 * i, k < fwd)); }  // try: rho = +0.7
    }
    m
}
fn var_i(xi: f64) -> (f64, f64) {                  // exact variance of I when v0 = theta (the house case)
    let (e1, e2) = ((-KAPPA * T).exp(), (-2.0 * KAPPA * T).exp());
    let bracket = T - (1.0 - e2) / (2.0 * KAPPA) - (1.0 - e1) / KAPPA + e1 * (1.0 - e1) / KAPPA;
    (THETA * xi * xi / (KAPPA * KAPPA) * bracket, bracket)
}
fn hull_white(k: f64, put: bool, var: f64) -> (f64, f64, f64, f64) {  // road 3: bend times var
    let w = THETA * T; let sd = w.sqrt();
    let d1 = ((S / k).ln() + (R - Q) * T + 0.5 * w) / sd;
    let cw = S * (-Q * T).exp() * (-0.5 * d1 * d1).exp() / (2.0 * PI).sqrt() / (2.0 * sd);
    let cww = cw * (d1 * (d1 - sd) - 1.0) / (2.0 * w);
    (bs(S, k, w, put) + 0.5 * cww * var, d1, cw, cww)
}
fn main() {
    let fwd = S * ((R - Q) * T).exp();
    let m = mixing_road(1, XI, PATHS, fwd);
    let (atm6, cut5) = (mixing_road(4, 0.6, 20000, fwd).atm, mixing_road(3, 0.5, 20000, fwd).cut);
    let (mut g, c, disc) = (Normals { state: 2, spare: None }, (1.0 - RHO * RHO).sqrt(), (-R * T).exp());
    let (mut pl0, mut pl7, mut atm_plain) = (vec![Acc::new(); 7], vec![Acc::new(); 7], Acc::new());
    for _ in 0..PATHS {                                // road 2: price and variance simulated together
        let (mut v, mut x0, mut x7) = (V0, S.ln(), S.ln());
        for _ in 0..STEPS {
            let vp = if v > 0.0 { v } else { 0.0 };
            let (sd, z2, zp) = ((vp * DT).sqrt(), g.next(), g.next());
            x0 += (R - Q - 0.5 * vp) * DT + sd * zp;                     // rho = 0: its own noise only
            x7 += (R - Q - 0.5 * vp) * DT + sd * (RHO * z2 + c * zp);    // rho = -0.7: shares the variance's
            v += KAPPA * (THETA - vp) * DT + XI * sd * z2;
        }
        let (s0, s7) = (x0.exp(), x7.exp()); atm_plain.add(disc * (s0 - 100.0).max(0.0));
        for (j, &k) in STRIKES.iter().enumerate() {
            pl0[j].add(disc * if k < fwd { (k - s0).max(0.0) } else { (s0 - k).max(0.0) });
            pl7[j].add(disc * if k < fwd { (k - s7).max(0.0) } else { (s7 - k).max(0.0) });
        }
    }
    let ((vi, bracket), sd_sim) = (var_i(XI), m.avg.se() * (PATHS as f64).sqrt());
    let (hw, d1, cw, cww) = hull_white(100.0, false, vi);
    let toy: Vec<f64> = [0.02, 0.04, 0.06].iter().map(|&w| bs(S, 100.0, w, false)).collect();
    println!("house call at 20%, own normal CDF; forward    {:10.6}; {:.4}", bs(S, 100.0, 0.04, false), fwd);
    println!("Feller 2 kappa theta, xi^2; half-life, years  {:10.4} {:.4}; {:.4}", 2.0 * KAPPA * THETA, XI * XI, 2.0f64.ln() / KAPPA);
    println!("average variance: formula, simulated, se      {:10.6} {:.6} {:.6}", mean_vbar(V0, KAPPA, T), m.avg.mean(), m.avg.se());
    println!("its sd: formula, simulated                    {:10.6} {:.6}", vi.sqrt() / T, sd_sim);
    println!("truncated steps, %: xi = 0.3, xi = 0.5        {:10.4} {:.4}", 100.0 * m.cut as f64 / (PATHS * STEPS) as f64, 100.0 * cut5 as f64 / (20000 * STEPS) as f64);
    println!("average vol over the year, % of {} years:", PATHS);
    let labels = ["below 15%", "15 to 17%", "17 to 19%", "19 to 21%", "21 to 23%", "23 to 25%", "25% and up"];
    for j in 0..7 { println!("  {:<12}{:6.2}", labels[j], 100.0 * m.hist[j] as f64 / PATHS as f64); }
    println!("years at variance 0.02, 0.04, 0.06; average   {:10.4} {:.4} {:.4}; {:.4}", toy[0], toy[1], toy[2], (toy[0] + toy[1] + toy[2]) / 3.0);
    println!("rho = 0, 100 call: mixing, plain; se          {:10.4} {:.4}; {:.4} {:.4}", m.atm.mean(), atm_plain.mean(), m.atm.se(), atm_plain.se());
    println!("Hull-White: d1, d2, phi(d1), C_w, C_ww        {:10.4} {:.4} {:.4} {:.2} {:.1}", d1, d1 - (THETA * T).sqrt(), (-0.5 * d1 * d1).exp() / (2.0 * PI).sqrt(), cw, cww);
    println!("Hull-White: bracket, var I, correction, price {:10.6} {:.8} {:.4} {:.4}", bracket, vi, 0.5 * cww * vi, hw);
    let (mut iv0, mut iv7): (Vec<Vec<f64>>, Vec<Vec<f64>>) = (vec![], vec![]);
    for (rho, mix, pl, ivs) in [(0.0, &m.mix0, &pl0, &mut iv0), (RHO, &m.mix7, &pl7, &mut iv7)] {
        println!("rho = {:4.1}:  K opt    mixing     se    plain     se   vol: mix plain{}", rho, if rho == 0.0 { "   H-W" } else { "" });
        for (j, &k) in STRIKES.iter().enumerate() {
            let (p, a, b) = (k < fwd, mix[j], pl[j]);
            let mut row = vec![implied(a.mean(), k, p), implied(b.mean(), k, p)];
            if rho == 0.0 { row.push(implied(hull_white(k, p, vi).0, k, p)); }
            let vols: String = row.iter().map(|v| format!(" {:6.2}", 100.0 * v)).collect();
            println!("          {:4.0} {} {:8.4} {:.4} {:8.4} {:.4}{}", k, if p { "put " } else { "call" }, a.mean(), a.se(), b.mean(), b.se(), vols);
            ivs.push(row);
        }
    }
    println!("root of expected average variance, %: T; v0 .09 kappa 2; v0 .09 kappa .5; v0 .01 kappa 2");
    for t in [0.25, 0.5, 1.0, 2.0, 3.0, 5.0] {
        let ts: Vec<f64> = [(0.09, 2.0), (0.09, 0.5), (0.01, 2.0)].iter().map(|&(v, k)| 100.0 * mean_vbar(v, k, t).sqrt()).collect();
        println!("  {:4.2} {:6.2} {:6.2} {:6.2}", t, ts[0], ts[1], ts[2]);
    }
    let gap = [0.25, 0.5, 1.0, 2.0, 3.0, 5.0].iter().flat_map(|&t| [(0.09, 2.0), (0.09, 0.5), (0.01, 2.0)].map(|(v, k)| (mean_vbar(v, k, t) - stepped_vbar(v, k, t)).abs())).fold(0.0, f64::max);
    println!("term structure: formula against stepping, largest gap  {:.8}", gap);
    println!("wrong: Black-Scholes at the average variance  {:.4}", bs(S, 100.0, mean_vbar(V0, KAPPA, T) * T, false));
    println!("wrong: terminal variance, not the average     {:.4}", m.term.mean());
    println!("wrong: rho ignored, vol at 80 and 120         {:.2} {:.2}", 100.0 * iv0[1][0], 100.0 * iv0[5][0]);
    println!("wrong: variance 0.04 fed in as the vol        {:.4}", bs(S, 100.0, 0.04 * 0.04 * T, false));
    println!("try: rho = +0.7, vol at 80 and 120            {:.2} {:.2}", 100.0 * implied(m.plus7[0].mean(), 80.0, true), 100.0 * implied(m.plus7[1].mean(), 120.0, false));
    println!("try: xi = 0.6: sd of average variance; mixing, se, Hull-White  {:.6}; {:.4} {:.4} {:.4}", var_i(0.6).0.sqrt() / T, atm6.mean(), atm6.se(), hull_white(100.0, false, var_i(0.6).0).0);
    assert!((bs(S, 100.0, 0.04, false) - 9.227005508154).abs() < 1e-9, "own normal CDF against the house call");
    assert!((m.avg.mean() - mean_vbar(V0, KAPPA, T)).abs() < 3.0 * m.avg.se(), "simulated average variance against its formula");
    assert!(gap < 1e-6, "term structure: formula against stepping the averaged equation");
    assert!((sd_sim / (vi.sqrt() / T) - 1.0).abs() < 0.02, "simulated spread of average variance against its formula");
    assert!((m.atm.mean() - atm_plain.mean()).abs() < 3.0 * (m.atm.se().powi(2) + atm_plain.se().powi(2)).sqrt(), "road 1 against road 2");
    for (mix, pl) in [(&m.mix0, &pl0), (&m.mix7, &pl7)] {
        for (a, b) in mix.iter().zip(pl.iter()) { assert!((a.mean() - b.mean()).abs() < 3.0 * (a.se().powi(2) + b.se().powi(2)).sqrt(), "mixing against plain"); }
    }
    assert!((hw - m.atm.mean()).abs() < 0.05, "road 3, the Hull-White expansion, against road 1");
    assert!(m.atm.se() < atm_plain.se() / 5.0, "mixing removes most of the noise");
    assert!((0..6).all(|j| iv7[j][0] > iv7[j + 1][0] && iv7[j][1] > iv7[j + 1][1]), "rho = -0.7: vol falls with strike");
    assert!(iv0[0][0] > iv0[3][0] && iv0[3][0] < iv0[6][0], "rho = 0: both wings above the middle");
    println!("ALL CHECKS PASS");
}
