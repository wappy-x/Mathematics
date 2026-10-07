// Spread options and Kirk's approximation -- the same check as the Python, in Rust.  Std only, no crates.
// Two house shares, each at 100, 20% volatility, 2% dividend; correlation 0.5; r = 5%; one year.
// Same series for the bell-curve area, same Simpson rule, same splitmix64 draws, same rows.
use std::f64::consts::PI;

const S1: f64 = 100.0; const S2: f64 = 100.0; const V1: f64 = 0.20; const V2: f64 = 0.20;
const Q1: f64 = 0.02; const Q2: f64 = 0.02; const R: f64 = 0.05; const T: f64 = 1.0;
const RHO: f64 = 0.5; const K: f64 = 5.0;

fn disc() -> f64 { (-R * T).exp() }

fn n_cdf(x: f64) -> f64 {                   // area left of x: Marsaglia's series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0_f64, x, 1.0_f64);
    while s != t {
        i += 2.0;
        b *= x * x / i;
        t = s; s = s + b;
    }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}

// road 1: fold the strike into asset 2.  fold = Some(Y) forces the forward of "asset 2 plus strike".
fn kirk(k: f64, rho: f64, a: f64, b: f64, fold: Option<f64>, w_one: bool) -> (f64, f64, f64, f64, f64, f64, f64) {
    let (f1, f2) = (a * ((R - Q1) * T).exp(), b * ((R - Q2) * T).exp());
    let y = match fold { None => f2 + k, Some(v) => v };
    let w = if w_one { 1.0 } else { f2 / y };
    let vk = ((V1 * V1 - 2.0 * rho * V1 * V2 * w + V2 * V2 * w * w) * T).sqrt();
    let d1 = ((f1 / y).ln() + 0.5 * vk * vk) / vk;
    (disc() * (f1 * n_cdf(d1) - y * n_cdf(d1 - vk)), w, vk, d1, f1, f2, y)
}
fn kp(k: f64, rho: f64) -> f64 { kirk(k, rho, S1, S2, None, false).0 }

fn margrabe(rho: f64) -> f64 {              // the K = 0 closed form, in spot terms (sibling card 01)
    let v = (V1 * V1 + V2 * V2 - 2.0 * rho * V1 * V2).sqrt();
    let d1 = ((S1 / S2).ln() + (Q2 - Q1 + 0.5 * v * v) * T) / (v * T.sqrt());
    S1 * (-Q1 * T).exp() * n_cdf(d1) - S2 * (-Q2 * T).exp() * n_cdf(d1 - v * T.sqrt())
}

// road 2: fix asset 2's draw z, price asset 1 by Black-Scholes, average over z by Simpson's rule
fn exact(k: f64, rho: f64, a: f64, b: f64, put: bool) -> f64 {
    let (f1, f2, rt) = (a * ((R - Q1) * T).exp(), b * ((R - Q2) * T).exp(), T.sqrt());
    let s = V1 * rt * (1.0 - rho * rho).sqrt();
    let f = |z: f64| {
        let x = f2 * (-0.5 * V2 * V2 * T + V2 * rt * z).exp() + k;
        let g = f1 * (-0.5 * V1 * V1 * rho * rho * T + V1 * rt * rho * z).exp();
        let d1 = ((g / x).ln() + 0.5 * s * s) / s;
        let c = if put { x * n_cdf(s - d1) - g * n_cdf(-d1) } else { g * n_cdf(d1) - x * n_cdf(d1 - s) };
        c * (-0.5 * z * z).exp() / (2.0 * PI).sqrt()
    };
    let n = 400;
    let h = 18.0 / n as f64;
    let mut tot = f(-9.0) + f(9.0);
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(-9.0 + i as f64 * h); }
    disc() * tot * h / 3.0
}
fn ex(k: f64, rho: f64) -> f64 { exact(k, rho, S1, S2, false) }

struct Rng(u64);                            // splitmix64: 64-bit integer mixing
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0) + 0.5 / 9007199254740992.0
    }
}

fn r2(x: f64) -> f64 { (x * 100.0).round() / 100.0 + 0.0 }

fn main() {
    let d = disc();
    // road 3: simulate 1,000,000 expiries; Cholesky turns two independent draws into correlated ones
    let cells = [(0.5_f64, 0.0_f64), (0.5, 5.0), (-0.5, 20.0)];
    let (f1, f2) = (S1 * ((R - Q1) * T).exp(), S2 * ((R - Q2) * T).exp());
    let (mut sm, mut sq, paths) = ([0.0_f64; 3], [0.0_f64; 3], 1000000usize);
    let mut rng = Rng(20260924);
    for _ in 0..paths {
        let rad = (-2.0 * rng.uniform().ln()).sqrt();
        let ang = 2.0 * PI * rng.uniform();
        let (g1, g2) = (rad * ang.cos(), rad * ang.sin());
        for (c, &(rho, k)) in cells.iter().enumerate() {
            let z1 = rho * g1 + (1.0 - rho * rho).sqrt() * g2;
            let a = f1 * (-0.5 * V1 * V1 * T + V1 * T.sqrt() * z1).exp();
            let b = f2 * (-0.5 * V2 * V2 * T + V2 * T.sqrt() * g1).exp();
            let p = d * (a - b - k).max(0.0);
            sm[c] += p; sq[c] += p * p;
        }
    }
    let pf = paths as f64;
    let mc: Vec<f64> = (0..3).map(|c| sm[c] / pf).collect();
    let se: Vec<f64> = (0..3).map(|c| ((sq[c] / pf - mc[c] * mc[c]) / (pf - 1.0)).sqrt()).collect();

    let (ck, w, vk, d1, f1, f2, y) = kirk(K, RHO, S1, S2, None, false);
    let (ce, pe, mg) = (ex(K, RHO), exact(K, RHO, S1, S2, true), margrabe(RHO));
    let bump = |f: &dyn Fn(f64) -> f64, h: f64| (f(h) - f(-h)) / (2.0 * h);
    let g = [
        ("delta, asset 1", bump(&|h| kirk(K, RHO, S1 + h, S2, None, false).0, 0.01), bump(&|h| exact(K, RHO, S1 + h, S2, false), 0.01)),
        ("delta, asset 2", bump(&|h| kirk(K, RHO, S1, S2 + h, None, false).0, 0.01), bump(&|h| exact(K, RHO, S1, S2 + h, false), 0.01)),
        ("correlation, per 0.01", bump(&|h| kp(K, RHO + h), 0.001) * 0.01, bump(&|h| ex(K, RHO + h), 0.001) * 0.01),
    ];
    let mut rows: Vec<(String, f64)> = vec![
        ("forward of each share, F1 = F2".into(), f1), ("asset 2 plus strike, F2 + K".into(), y), ("weight w = F2/(F2+K)".into(), w),
        ("Kirk volatility sigma_K".into(), vk), ("Kirk d1".into(), d1), ("Kirk d2".into(), d1 - vk),
        ("N(d1)".into(), n_cdf(d1)), ("N(d2)".into(), n_cdf(d1 - vk)),
        ("share leg  e^-rT F1 N(d1)".into(), d * f1 * n_cdf(d1)), ("cash leg   e^-rT (F2+K) N(d2)".into(), d * y * n_cdf(d1 - vk)),
        ("1 Kirk, K = 5".into(), ck), ("2 exact integral, K = 5".into(), ce), ("3 simulation, K = 5".into(), mc[1]),
        ("  simulation error bar".into(), se[1]), ("  Kirk minus exact, cents".into(), 100.0 * (ck - ce)),
        ("Margrabe closed form, K = 0".into(), mg), ("  ratio volatility, K = 0".into(), kirk(0.0, RHO, S1, S2, None, false).2),
        ("  exact integral, K = 0".into(), ex(0.0, RHO)),
        ("  simulation, K = 0".into(), mc[0]), ("  simulation error bar".into(), se[0]),
        ("put by integral, K = 5".into(), pe), ("  C - P".into(), ce - pe), ("  e^-rT (F1 - F2 - K)".into(), d * (f1 - f2 - K)),
    ];
    for (name, gk, ge) in g.iter() { rows.push((format!("{}, Kirk", name), *gk)); rows.push((format!("  {}, exact", name), *ge)); }
    rows.extend(vec![
        ("wrong: Margrabe minus e^-rT K".to_string(), mg - d * K), ("wrong: Kirk with w = 1".into(), kirk(K, RHO, S1, S2, None, true).0),
        ("wrong: strike added to spot".into(), kirk(K, RHO, S1, S2, Some((S2 + K) * ((R - Q2) * T).exp()), false).0),
        ("wrong: correlation left out".into(), ex(K, 0.0)), ("simulation, rho -0.5, K = 20".into(), mc[2]),
        ("  simulation error bar".into(), se[2]), ("  Kirk, rho -0.5, K = 20".into(), kp(20.0, -0.5)),
    ]);
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }

    let ks = [0.0_f64, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    let rhos = [-0.5_f64, 0.0, 0.5, 0.9];
    let grid: Vec<Vec<(f64, f64)>> = rhos.iter().map(|&p| ks.iter().map(|&k| (kp(k, p), ex(k, p))).collect()).collect();
    let line = |p: f64, vals: Vec<f64>| format!("  rho {:>5.1}      {}", p, vals.iter().map(|v| format!("{:>8.2}", v)).collect::<String>());
    println!("exact price    K:{}", ks.iter().map(|k| format!("{:>8.0}", k)).collect::<String>());
    for (i, &p) in rhos.iter().enumerate() { println!("{}", line(p, grid[i].iter().map(|c| c.1).collect())); }
    println!("Kirk - exact, cents");
    for (i, &p) in rhos.iter().enumerate() { println!("{}", line(p, grid[i].iter().map(|c| r2(100.0 * (c.0 - c.1))).collect())); }
    println!("Kirk - exact, percent of exact");
    for (i, &p) in rhos.iter().enumerate() { println!("{}", line(p, grid[i].iter().map(|c| r2(100.0 * (c.0 / c.1 - 1.0))).collect())); }
    let xs = [-10.0_f64, -5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0];
    println!("chart, spread at expiry{}", xs.iter().map(|x| format!("{:>7.0}", x)).collect::<String>());
    let prof: String = xs.iter().map(|x| format!("{:>7.2}", (x - K).max(0.0) - r2(ce))).collect();
    println!("chart, profit after 5.67{}", &prof[1..]);

    assert!((ex(0.0, RHO) - 7.807839).abs() < 1e-6, "integral at K = 0 must land on Margrabe's house number");
    assert!((mg - ex(0.0, RHO)).abs() < 1e-9, "Margrabe formula vs the conditional integral");
    for (c, &(p, k)) in cells.iter().enumerate() { assert!((mc[c] - ex(k, p)).abs() < 3.0 * se[c], "simulation within 3 error bars"); }
    assert!((ck - ce).abs() < 0.001 * ce, "Kirk within a tenth of a percent at the house strike");
    assert!(((ce - pe) - d * (f1 - f2 - K)).abs() < 1e-9, "put-call parity with an independently priced put");
    for i in 0..3 { for j in 1..ks.len() - 1 {
        assert!(grid[i][j].0 / grid[i][j].1 < grid[i][j + 1].0 / grid[i][j + 1].1, "Kirk's percent error grows with the strike at correlation 0.5 and below");
    } }
    for j in 1..ks.len() { for i in 0..2 {
        assert!(grid[i][j].0 - grid[i][j].1 > grid[i + 1][j].0 - grid[i + 1][j].1, "Kirk's error in cents shrinks as correlation rises to 0.5");
    } }
    println!("ALL CHECKS PASS");
}
