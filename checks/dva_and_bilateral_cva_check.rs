// DVA and bilateral CVA -- the check behind the card.  Rust std only.
// Three roads: closed forms; Simpson integrals over the bell curve and over time;
// a simulation of both default dates with a home-made random number generator.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0;
const LAM_N: f64 = 0.02; const RN: f64 = 0.40; const LAM_B: f64 = 0.01; const RB: f64 = 0.40; // Northwind, the bank: hazard, recovery

fn erf_series(y: f64) -> f64 {                     // 2/sqrt(pi) * sum (-1)^n y^(2n+1) / (n! (2n+1))
    let (mut term, mut sum, mut n) = (y, y, 0.0);
    while term.abs() > 1e-17 * sum.abs() {
        n += 1.0;
        term *= -y * y / n;
        sum += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * sum
}
fn erfc_cf(y: f64) -> f64 {                        // continued fraction for the far tail, y > 2.5
    let mut f = 0.0;
    for k in (1..=80).rev() { f = (k as f64 / 2.0) / (y + f); }
    (-y * y).exp() / PI.sqrt() / (y + f)
}
fn n_cdf(x: f64) -> f64 {
    let y = x.abs() / 2f64.sqrt();
    if y < 2.5 { 0.5 * (1.0 + x.signum() * erf_series(y)) }
    else if x > 0.0 { 1.0 - 0.5 * erfc_cf(y) } else { 0.5 * erfc_cf(y) }
}
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn fwd_price() -> f64 { S * ((R - Q) * T).exp() }  // forward delivery price: forward worth 0 today

fn call(s: f64, tau: f64) -> f64 {                 // Black-Scholes call, tau years left
    if tau <= 0.0 { return (s - K).max(0.0); }
    let v = SIG * tau.sqrt();
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * tau) / v;
    s * (-Q * tau).exp() * n_cdf(d1) - K * (-R * tau).exp() * n_cdf(d1 - v)
}
fn fwd(s: f64, tau: f64) -> f64 { s * (-Q * tau).exp() - fwd_price() * (-R * tau).exp() }
fn sold(s: f64, tau: f64) -> f64 { -call(s, tau) }  fn sfwd(s: f64, tau: f64) -> f64 { -fwd(s, tau) }

fn simpson(v: &[f64], h: f64) -> f64 {
    let n = v.len() - 1;
    h / 3.0 * (v[0] + v[n] + (1..n).fold(0.0, |acc, i| acc + if i % 2 == 1 { 4.0 } else { 2.0 } * v[i]))
}
fn ee(value: fn(f64, f64) -> f64, t: f64, side: f64) -> f64 {   // discounted expected exposure
    if t == 0.0 { return (side * value(S, T)).max(0.0); }
    let g = |z: f64| side * value(S * ((R - Q - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp(), T - t);
    let (mut a, mut b) = (-8.0, 8.0);
    if g(a) <= 0.0 && g(b) <= 0.0 { return 0.0; }
    if g(a) <= 0.0 || g(b) <= 0.0 {                 // exposure starts at a kink: bisection finds it
        let (mut lo, mut hi) = (a, b);
        for _ in 0..80 {
            let mid = 0.5 * (lo + hi);
            if (g(mid) > 0.0) == (g(hi) > 0.0) { hi = mid; } else { lo = mid; }
        }
        if g(b) > 0.0 { a = hi; } else { b = lo; }
    }
    let h = (b - a) / 400.0;
    let v: Vec<f64> = (0..=400).map(|i| g(a + i as f64 * h).max(0.0) * phi(a + i as f64 * h)).collect();
    (-R * t).exp() * simpson(&v, h)
}
const NT: usize = 200;                               // time grid t = u^2 smooths the sqrt(t) start
fn over_time(p: &[f64], lam_def: f64, lam_other: f64, rec: f64) -> f64 {
    let hu = T.sqrt() / NT as f64;
    let v: Vec<f64> = (0..=NT).map(|i| { let t = (i as f64 * hu).powi(2);
        (1.0 - rec) * lam_def * (-(lam_def + lam_other) * t).exp() * p[i] * 2.0 * t.sqrt() }).collect();
    simpson(&v, hu)
}
struct Rng(u64);
impl Rng {                                         // splitmix64, then a uniform strictly inside (0, 1)
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let hu = T.sqrt() / NT as f64;
    let ts: Vec<f64> = (0..=NT).map(|i| (i as f64 * hu).powi(2)).collect();
    let prof = |f: fn(f64, f64) -> f64, sd: f64| -> Vec<f64> { ts.iter().map(|&t| ee(f, t, sd)).collect() };
    let c0 = call(S, T);
    // road 1: closed forms
    let cva_uni = (1.0 - RN) * c0 * (1.0 - (-LAM_N * T).exp());
    let cva_bil = (1.0 - RN) * c0 * LAM_N / (LAM_N + LAM_B) * (1.0 - (-(LAM_N + LAM_B) * T).exp());
    let fwd_pe: Vec<f64> = ts.iter().map(|&t| S * (-Q * T).exp() * (2.0 * n_cdf(0.5 * SIG * t.sqrt()) - 1.0)).collect();
    let (f_cva1, f_dva1) = (over_time(&fwd_pe, LAM_N, LAM_B, RN), over_time(&fwd_pe, LAM_B, LAM_N, RB));
    // road 2: exposure profiles by integrating over the bell curve at every date
    let (call_pe, call_ne, f_pe2, f_ne2) = (prof(call, 1.0), prof(call, -1.0), prof(fwd, 1.0), prof(fwd, -1.0));
    let cva_uni2 = over_time(&call_pe, LAM_N, 0.0, RN);
    let (cva_bil2, dva_call_b) = (over_time(&call_pe, LAM_N, LAM_B, RN), over_time(&call_ne, LAM_B, LAM_N, RB));
    let (f_cva2, f_dva2) = (over_time(&f_pe2, LAM_N, LAM_B, RN), over_time(&f_ne2, LAM_B, LAM_N, RB));
    // Northwind's own books: sold call and sold forward, values the other way round
    let nw_cva = over_time(&prof(sold, 1.0), LAM_B, 0.0, RB);
    let nw_dva_uni = over_time(&prof(sold, -1.0), LAM_N, 0.0, RN);
    let nw_dva_bil = over_time(&prof(sold, -1.0), LAM_N, LAM_B, RN);
    let nw_f_cva = over_time(&prof(sfwd, 1.0), LAM_B, LAM_N, RB);
    let nw_f_dva = over_time(&prof(sfwd, -1.0), LAM_N, LAM_B, RN);

    // road 3: simulate both default dates; close out at the first one if it comes before T
    let mut rng = Rng(20260928);
    let paths = 4_000_000usize;
    let (mut sc, mut scc, mut sf, mut sff) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let t_n = -rng.next().ln() / LAM_N;
        let t_b = -rng.next().ln() / LAM_B; let t = t_n.min(t_b);
        if t >= T { continue; }
        let u1 = rng.next(); let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * rng.next()).cos();
        let st = S * ((R - Q - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp();
        let (vc, vf, d) = (call(st, T - t), fwd(st, T - t), (-R * t).exp());
        let (xc, xf) = if t_n < t_b { ((1.0 - RN) * d * vc.max(0.0), (1.0 - RN) * d * vf.max(0.0)) }
                       else { (-(1.0 - RB) * d * (-vc).max(0.0), -(1.0 - RB) * d * (-vf).max(0.0)) };
        sc += xc; scc += xc * xc; sf += xf; sff += xf * xf;
    }
    let np = paths as f64; let (mc_c, mc_f) = (sc / np, sf / np);
    let (se_c, se_f) = (((scc / np - mc_c * mc_c) / np).sqrt(), ((sff / np - mc_f * mc_f) / np).sqrt());

    let bil_f = f_cva1 - f_dva1; let rows: Vec<(&str, f64)> = vec![
        ("call C0", c0), ("forward price F", fwd_price()), ("discount D(1)", (-R * T).exp()),
        ("Northwind defaults by 1y", 1.0 - (-LAM_N * T).exp()), ("Northwind defaults first by 1y", LAM_N / (LAM_N + LAM_B) * (1.0 - (-(LAM_N + LAM_B) * T).exp())),
        ("call, bank CVA unilateral, closed", cva_uni), ("call, bank CVA unilateral, integral", cva_uni2),
        ("call, bank risky price unilateral", c0 - cva_uni),
        ("call, Northwind CVA", nw_cva), ("call, Northwind DVA unilateral", nw_dva_uni),
        ("call, bank CVA bilateral, closed", cva_bil), ("call, bank CVA bilateral, integral", cva_bil2),
        ("call, bank DVA", dva_call_b), ("call, Northwind DVA bilateral", nw_dva_bil),
        ("call, price both agree on", c0 - cva_bil),
        ("call, bank BCVA simulated", mc_c), ("  standard error", se_c),
        ("fwd EPE at 1y, closed", fwd_pe[NT]), ("fwd EPE at 1y, integral", f_pe2[NT]),
        ("fwd ENE at 1y, integral", f_ne2[NT]),
        ("fwd, bank CVA, road 1", f_cva1), ("fwd, bank CVA, road 2", f_cva2),
        ("fwd, bank DVA, road 1", f_dva1), ("fwd, bank DVA, road 2", f_dva2),
        ("fwd, bank BCVA", bil_f), ("fwd, bank BCVA simulated", mc_f), ("  standard error", se_f),
        ("fwd, Northwind CVA", nw_f_cva), ("fwd, Northwind DVA", nw_f_dva),
        ("fwd, Northwind BCVA", nw_f_cva - nw_f_dva),
    ];
    for (name, v) in &rows { println!("{:<38}{:>12.6}", name, v); }
    println!();
    for lam in [0.0, 0.01, 0.02, 0.04, 0.08] {     // Northwind's own credit worsens: sold call on its books
        let dva = (1.0 - RN) * c0 * (1.0 - (-lam * T).exp());
        println!("own hazard {:4.2}  Northwind DVA {:8.4}  sold call booked at {:9.4}", lam, dva, -c0 + dva);
    }
    for lb in [0.01, 0.02, 0.03] {                       // the bank's own credit worsens: the forward on its books
        let b = over_time(&fwd_pe, LAM_N, lb, RN) - over_time(&fwd_pe, lb, LAM_N, RB);
        println!("bank hazard {:4.2}  fwd BCVA {:8.4}  forward booked at {:8.4}", lb, b, -b);
    }
    println!();
    let wrong: Vec<(&str, f64)> = vec![
        ("wrong: fwd, CVA alone, DVA left out", over_time(&fwd_pe, LAM_N, 0.0, RN)),
        ("wrong: fwd, DVA added not subtracted", f_cva1 + f_dva1),
        ("wrong: call, undiscounted exposure", (1.0 - RN) * LAM_N * c0 * (((R - LAM_N) * T).exp() - 1.0) / (R - LAM_N)),
        ("wrong: call, buyer charged a DVA", cva_bil - (1.0 - RB) * c0 * LAM_B / (LAM_N + LAM_B) * (1.0 - (-(LAM_N + LAM_B) * T).exp())),
    ];
    for (name, v) in &wrong { println!("{:<38}{:>12.6}", name, v); }
    println!();
    let grid: Vec<f64> = (0..=10).map(|i| i as f64 / 10.0).collect();
    let line = |v: Vec<String>| v.join(" ");
    println!("chart, years      {}", line(grid.iter().map(|t| format!("{:5.1}", t)).collect()));
    for (lab, f, sd) in [("chart, call EPE   ", call as fn(f64, f64) -> f64, 1.0), ("chart, fwd EPE    ", fwd, 1.0), ("chart, fwd ENE    ", fwd, -1.0), ("chart, call ENE   ", call, -1.0)] {
        println!("{}{}", lab, line(grid.iter().map(|&t| format!("{:5.2}", ee(f, t, sd))).collect()));
    }

    assert!((cva_uni - 0.1096).abs() < 5e-5, "house CVA from the shelf");
    assert!((cva_uni2 - cva_uni).abs() < 1e-7 && (cva_bil2 - cva_bil).abs() < 1e-7, "flat exposure: integral meets closed form");
    assert!((f_cva2 - f_cva1).abs() < 1e-7 && (f_dva2 - f_dva1).abs() < 1e-7, "forward: bell-curve road meets closed-form road");
    assert!((nw_dva_bil - cva_bil).abs() < 1e-7 && (nw_f_cva - f_dva2).abs() < 1e-7 && nw_cva + dva_call_b < 1e-12, "mirror: one side's CVA is the other's DVA");
    assert!((mc_c - cva_bil).abs() < 4.0 * se_c && (mc_f - bil_f).abs() < 4.0 * se_f, "simulation within 4 standard errors");
    println!("ALL CHECKS PASS");
}
