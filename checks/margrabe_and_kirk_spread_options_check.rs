// Spread options on futures: Margrabe (zero strike) and Kirk (with a strike), in Rust.
// Standard library only, no crates.  Same roads, same random numbers, same rows
// as margrabe_and_kirk_spread_options_check.py.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn n_cdf(x: f64) -> f64 {                                              // area left of x
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    0.5 + simpson(phi, 0.0, x, 400)
}

fn black(f: f64, k: f64, v: f64, d: f64) -> f64 {    // Black-76 call; v = vol times root-time
    if v <= 0.0 { return d * (f - k).max(0.0); }
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    d * (f * n_cdf(d1) - k * n_cdf(d1 - v))
}

fn ratio_vol(s1: f64, s2: f64, rho: f64) -> f64 { (s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2).max(0.0).sqrt() }

fn margrabe(f1: f64, f2: f64, s1: f64, s2: f64, rho: f64, t: f64, d: f64) -> f64 {   // road 1
    black(f1, f2, ratio_vol(s1, s2, rho) * t.sqrt(), d)
}

fn kirk_vol(f2: f64, k: f64, s1: f64, s2: f64, rho: f64) -> f64 {
    let a = f2 / (f2 + k);                // crude's share of "crude plus strike"
    ratio_vol(s1, s2 * a, rho)
}

fn kirk(f1: f64, f2: f64, k: f64, s1: f64, s2: f64, rho: f64, t: f64, d: f64) -> f64 {   // road 2
    black(f1, f2 + k, kirk_vol(f2, k, s1, s2, rho) * t.sqrt(), d)
}

fn by_integral(f1: f64, f2: f64, k: f64, s1: f64, s2: f64, rho: f64, t: f64, d: f64) -> f64 {
    // Road 3: fix crude's shock z, gasoline is then lognormal on its own; average over z.
    let (rt, c) = (t.sqrt(), (1.0 - rho * rho).sqrt());
    let f = |z: f64| {
        let f2t = f2 * (-0.5 * s2 * s2 * t + s2 * rt * z).exp();
        let m = f1 * (-0.5 * s1 * s1 * t * rho * rho + s1 * rt * rho * z).exp();   // gasoline's mean given z
        black(m, f2t + k, s1 * rt * c, 1.0) * phi(z)
    };
    d * simpson(f, -8.0, 8.0, 2000)
}

struct Rng { s: u64 }                                                   // splitmix64, written out
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn monte_carlo(f1: f64, f2: f64, strikes: &[f64], s1: f64, s2: f64, rho: f64, t: f64, d: f64, n: usize, seed: u64) -> Vec<(f64, f64)> {
    // Road 4: correlated terminal prices, z2 = rho g1 + sqrt(1 - rho^2) g2 (Cholesky).
    let (mut rng, rt, c) = (Rng { s: seed }, t.sqrt(), (1.0 - rho * rho).sqrt());
    let (mut sums, mut sq) = (vec![0.0f64; strikes.len()], vec![0.0f64; strikes.len()]);
    for _ in 0..n {
        let r = (-2.0 * rng.u().ln()).sqrt();
        let w = 2.0 * PI * rng.u();
        let (g1, g2) = (r * w.cos(), r * w.sin());
        let a = f1 * (-0.5 * s1 * s1 * t + s1 * rt * g1).exp();
        let b = f2 * (-0.5 * s2 * s2 * t + s2 * rt * (rho * g1 + c * g2)).exp();
        for (j, k) in strikes.iter().enumerate() {
            let p = (a - b - k).max(0.0);
            sums[j] += p;
            sq[j] += p * p;
        }
    }
    (0..strikes.len()).map(|j| {
        let mean = sums[j] / n as f64;
        (d * mean, d * ((sq[j] / n as f64 - mean * mean) / n as f64).sqrt())
    }).collect()
}

fn row(xs: &[f64], w: usize, p: usize) -> String {
    xs.iter().map(|x| format!("{:>w$.p$}", x, w = w, p = p)).collect::<Vec<_>>().join(" ")
}

fn main() {
    // the house crack spread: gasoline 100, crude 90 USD/bbl, vols 30% and 25%, rho 0.5, six months, 5%
    let (f1, f2, s1, s2, rho, t, r) = (100.0_f64, 90.0_f64, 0.30_f64, 0.25_f64, 0.5_f64, 0.5_f64, 0.05_f64);
    let d = (-r * t).exp();
    let sig = ratio_vol(s1, s2, rho);
    let v = sig * t.sqrt();
    let d1 = ((f1 / f2).ln() + 0.5 * v * v) / v;
    let d2 = d1 - v;
    let m = margrabe(f1, f2, s1, s2, rho, t, d);
    let m_int = by_integral(f1, f2, 0.0, s1, s2, rho, t, d);
    let kv = kirk_vol(f2, 10.0, s1, s2, rho);
    let kk = kirk(f1, f2, 10.0, s1, s2, rho, t, d);
    let k_int = by_integral(f1, f2, 10.0, s1, s2, rho, t, d);
    let mc = monte_carlo(f1, f2, &[0.0, 10.0], s1, s2, rho, t, d, 400000, 20260927);
    let ((mc0, se0), (mc10, se10)) = (mc[0], mc[1]);
    let h = 0.01;
    let dg_bump = (margrabe(f1 + h, f2, s1, s2, rho, t, d) - margrabe(f1 - h, f2, s1, s2, rho, t, d)) / (2.0 * h);
    let dc_bump = (margrabe(f1, f2 + h, s1, s2, rho, t, d) - margrabe(f1, f2 - h, s1, s2, rho, t, d)) / (2.0 * h);
    let drho = (margrabe(f1, f2, s1, s2, rho + 0.01, t, d) - margrabe(f1, f2, s1, s2, rho - 0.01, t, d)) / 2.0;
    let drho_an = d * f1 * phi(d1) * t.sqrt() * (-s1 * s2 / sig) * 0.01;   // vega times d(sigma)/d(rho), per 0.01
    let rows: Vec<(&str, f64)> = vec![("ratio vol sigma", sig), ("discount D = e^-rT", d), ("d1", d1), ("d2", d2),
        ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("gasoline half D F1 N(d1)", d * f1 * n_cdf(d1)),
        ("crude half    D F2 N(d2)", d * f2 * n_cdf(d2)),
        ("1 Margrabe, K = 0", m), ("3 integral, K = 0", m_int), ("4 Monte Carlo, K = 0", mc0), ("  MC std error", se0),
        ("margined quote, K = 0 (no D)", m / d),
        ("Kirk weight a = F2/(F2+K)", f2 / (f2 + 10.0)), ("Kirk vol", kv),
        ("2 Kirk, K = 10", kk), ("3 integral, K = 10", k_int), ("4 Monte Carlo, K = 10", mc10), ("  MC std error", se10),
        ("  Kirk minus integral", kk - k_int), ("  Kirk minus MC", kk - mc10),
        ("  (MC - integral) / std error", (mc10 - k_int) / se10),
        ("delta gasoline D N(d1)", d * n_cdf(d1)), ("  by bump", dg_bump),
        ("delta crude -D N(d2)", -d * n_cdf(d2)), ("  by bump", dc_bump),
        ("per +0.01 correlation, formula", drho_an), ("  by bump", drho),
        ("wrong: +2 rho in the ratio vol", black(f1, f2, (s1 * s1 + s2 * s2 + 2.0 * rho * s1 * s2).sqrt() * t.sqrt(), d)),
        ("wrong: correlation dropped (rho 0)", margrabe(f1, f2, s1, s2, 0.0, t, d)),
        ("wrong: Kirk, crude vol not scaled", black(f1, f2 + 10.0, sig * t.sqrt(), d)),
        ("wrong: Margrabe minus D K", m - d * 10.0),
        ("try: rho = 0.9, K = 0", margrabe(f1, f2, s1, s2, 0.9, t, d)),
        ("try: T = 1, K = 10, Kirk", kirk(f1, f2, 10.0, s1, s2, rho, 1.0, (-r).exp())),
        ("try: T = 1, K = 10, integral", by_integral(f1, f2, 10.0, s1, s2, rho, 1.0, (-r).exp())),
        ("try: vols 30/30, rho = 1", margrabe(f1, f2, s1, s1, 1.0, t, d)),
        ("try: rho -0.5, K=20, Kirk - exact", kirk(f1, f2, 20.0, s1, s2, -0.5, t, d) - by_integral(f1, f2, 20.0, s1, s2, -0.5, t, d))];
    for (name, x) in &rows { println!("{:<36} {:>12.6}", name, x); }
    println!("strike  Kirk      integral  Kirk-int(cents)");
    for k in [0.0_f64, 5.0, 10.0, 20.0, 30.0] {
        let (a, b) = (kirk(f1, f2, k, s1, s2, rho, t, d), by_integral(f1, f2, k, s1, s2, rho, t, d));
        println!("{:>6.0}  {:8.4}  {:8.4}  {:+8.4}", k, a, b, 100.0 * (a - b));
    }
    let rhos = [-0.9_f64, -0.6, -0.3, 0.0, 0.3, 0.5, 0.6, 0.9];
    println!("chart, rho      {}", row(&rhos, 6, 1));
    println!("chart, K = 0    {}", row(&rhos.map(|x| margrabe(f1, f2, s1, s2, x, t, d)), 6, 2));
    println!("chart, K = 10   {}", row(&rhos.map(|x| kirk(f1, f2, 10.0, s1, s2, x, t, d)), 6, 2));
    let xs = [-10.0_f64, -5.0, 0.0, 5.0, 10.0, 15.0, 20.0, 25.0, 30.0];
    println!("chart, spread   {}", row(&xs, 6, 0));
    println!("chart, pay K=0  {}", row(&xs.map(|x| x.max(0.0)), 6, 2));
    println!("chart, pay K=10 {}", row(&xs.map(|x| (x - 10.0).max(0.0)), 6, 2));
    println!("chart, profit   {}", row(&xs.map(|x| (x - 10.0).max(0.0) - kk / d), 6, 2));
    assert!((m - 13.153108728969).abs() < 1e-6, "Margrabe vs the shelf's house number");
    assert!((m_int - m).abs() < 1e-6, "integral road lands on Margrabe at zero strike");
    assert!((mc0 - m).abs() < 4.0 * se0, "simulation within four standard errors of Margrabe");
    assert!((kk - k_int).abs() < 1e-5, "Kirk within a thousandth of a cent of the integral at strike 10");
    assert!((mc10 - k_int).abs() < 4.0 * se10, "simulation within four standard errors of the integral");
    assert!((dg_bump - d * n_cdf(d1)).abs() < 1e-6, "bumped gasoline delta vs D N(d1)");
    assert!((drho - drho_an).abs() < 1e-4, "bumped correlation sensitivity vs vega times d(sigma)/d(rho)");
    println!("ALL CHECKS PASS");
}
