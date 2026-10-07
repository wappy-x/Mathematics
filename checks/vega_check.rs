// Vega -- the same check as vega_check.py, in Rust.  Standard library only,
// no crates.  Rust has no erf, so the bell-curve area N(x) is built by adding
// thin slices under the curve (Simpson); the random numbers are home-made.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn n_cdf(x: f64) -> f64 {                                             // area left of x
    if x.abs() > 8.5 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}
fn d1d2(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    (d1, d1 - v * t.sqrt())
}
fn call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d1d2(s, k, r, q, v, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn vega(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {       // the card's formula
    s * (-q * t).exp() * phi(d1d2(s, k, r, q, v, t).0) * t.sqrt()
}
fn simpson_price<F: Fn(f64) -> f64>(s: f64, r: f64, q: f64, v: f64, t: f64, pay: F) -> f64 {
    let f = |z: f64| pay(s * ((r - q - 0.5 * v * v) * t + v * t.sqrt() * z).exp()) * phi(z);
    (-r * t).exp() * simpson(f, -10.0, 10.0, 20000)                    // no d1, no d2, no N
}
struct Rng(u64);                                                      // splitmix64
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn curve<F: Fn(f64) -> f64>(f: F, x: f64, e: f64) -> f64 {           // second difference, Richardson-refined
    let d = |e: f64| (f(x + e) - 2.0 * f(x) + f(x - e)) / (e * e);
    (4.0 * d(e) - d(2.0 * e)) / 3.0
}
fn argmax<F: Fn(f64) -> f64>(f: F, xs: impl Iterator<Item = f64>) -> f64 {
    let (mut best, mut arg) = (f64::MIN, 0.0);
    for x in xs { let y = f(x); if y > best { best = y; arg = x; } }
    arg
}

fn main() {
    let (s, k, r, q, v, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    let (d1, d2) = d1d2(s, k, r, q, v, t);
    let vg = vega(s, k, r, q, v, t);
    let v_cash = k * (-r * t).exp() * phi(d2) * t.sqrt();
    let h = 1e-4;
    let bump = (call(s, k, r, q, v + h, t) - call(s, k, r, q, v - h, t)) / (2.0 * h);
    let cpay = |x: f64| (x - k).max(0.0);
    let ppay = |x: f64| (k - x).max(0.0);
    let bump_int = (simpson_price(s, r, q, v + h, t, cpay) - simpson_price(s, r, q, v - h, t, cpay)) / (2.0 * h);
    let bump_put = (simpson_price(s, r, q, v + h, t, ppay) - simpson_price(s, r, q, v - h, t, ppay)) / (2.0 * h);

    let mut rng = Rng(20260919);
    let (paths, mut acc, mut acc2) = (200000usize, 0.0_f64, 0.0_f64);
    for _ in 0..paths {                                               // pathwise: d(payoff)/d(sigma)
        let u1 = rng.uniform();
        let u2 = rng.uniform();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let st = s * ((r - q - 0.5 * v * v) * t + v * t.sqrt() * z).exp();
        let g = if st > k { (-r * t).exp() * st * (t.sqrt() * z - v * t) } else { 0.0 };
        acc += g; acc2 += g * g;
    }
    let mc = acc / paths as f64;
    let mc_se = ((acc2 / paths as f64 - mc * mc) / paths as f64).sqrt();

    let gamma = curve(|y| call(y, k, r, q, v, t), s, 0.1);
    let volga = curve(|y| call(s, k, r, q, y, t), v, 2e-3);
    let (c20, c21) = (call(s, k, r, q, 0.20, t), call(s, k, r, q, 0.21, t));
    let carry = -s * (-q * t).exp() + k * (-r * t).exp();
    let peak_s = argmax(|x| vega(x, k, r, q, v, t), (0..60001).map(|i| 70.0 + i as f64 / 1000.0));
    let peak_k = argmax(|x| vega(s, x, r, q, v, t), (0..60001).map(|i| 70.0 + i as f64 / 1000.0));
    let peak_t = argmax(|x| vega(s, k, r, q, v, x), (1..3001).map(|i| i as f64 / 100.0));
    let mut grid = f64::MAX;
    for kk in (60..161).step_by(5) { for tt in [0.25, 1.0, 5.0, 30.0] { grid = grid.min(vega(s, kk as f64, r, q, v, tt)); } }

    let (quote, mut x, mut steps) = (12.0, 0.20_f64, Vec::new());   // implied vol: Newton steers by vega
    for _ in 0..4 { x -= (call(s, k, r, q, x, t) - quote) / vega(s, k, r, q, x, t); steps.push(x); }
    let (mut lo, mut hi) = (0.01_f64, 2.0_f64);                        // a second road: bisection
    for _ in 0..60 {
        let mid = 0.5 * (lo + hi);
        if call(s, k, r, q, mid, t) < quote { lo = mid; } else { hi = mid; }
    }
    let far_q = call(s, 150.0, r, q, 0.40, t);                         // a far strike, a poor start
    let far_v = vega(s, 150.0, r, q, 0.10, t);
    let far_step = 0.10 - (call(s, 150.0, r, q, 0.10, t) - far_q) / far_v;
    let far_step20 = 0.20 - (call(s, 150.0, r, q, 0.20, t) - far_q) / vega(s, 150.0, r, q, 0.20, t);

    let rows: Vec<(&str, f64)> = vec![("d1", d1), ("d2", d2), ("phi(d1)", phi(d1)), ("phi(d2)", phi(d2)),
        ("S e^-qT", s * (-q * t).exp()), ("K e^-rT", k * (-r * t).exp()),
        ("1 vega, S e^-qT phi(d1) rootT", vg), ("2 vega, K e^-rT phi(d2) rootT", v_cash),
        ("3 bump the formula price", bump), ("4 bump the Simpson call", bump_int),
        ("5 bump the Simpson put", bump_put), ("6 pathwise Monte Carlo", mc), ("  standard error", mc_se),
        ("7 gamma by bump", gamma), ("  sigma T S^2 gamma", v * t * s * s * gamma),
        ("per vol point", vg / 100.0), ("call at 20%", c20), ("call at 21%", c21),
        ("  full reprice, 20% to 21%", c21 - c20), ("  vega times 0.01", vg * 0.01),
        ("volga by bump", volga), ("  plus half volga times 0.01^2", vg * 0.01 + 0.5 * volga * 1e-4),
        ("put at 20%, by parity", c20 + carry), ("put at 21%, by parity", c21 + carry),
        ("forward S e^(r-q)T", s * ((r - q) * t).exp()),
        ("peak in spot, K e^-(r-q-s^2/2)T", k * (-(r - q - 0.5 * v * v) * t).exp()), ("  grid search", peak_s),
        ("peak in strike, S e^(r-q+s^2/2)T", s * ((r - q + 0.5 * v * v) * t).exp()), ("  grid search", peak_k),
        ("peak in maturity, grid (years)", peak_t), ("  vega there", vega(s, k, r, q, v, peak_t)),
        ("smallest vega on an 84-point grid", grid),
        ("wrong: N(d1) for phi(d1)", s * (-q * t).exp() * n_cdf(d1) * t.sqrt()),
        ("wrong: S e^-qT with phi(d2)", s * (-q * t).exp() * phi(d2) * t.sqrt()),
        ("wrong: no rootT, 4 years", vega(s, k, r, q, v, 4.0) / 2.0), ("  right, 4 years", vega(s, k, r, q, v, 4.0)),
        ("wrong: 20% to 20.2%, vega x 0.002", vg * 0.002),
        ("Newton, quote 12.00, step 1", steps[0]), ("  step 2", steps[1]), ("  step 4", steps[3]),
        ("  bisection, 60 halvings", 0.5 * (lo + hi)),
        ("far: K 150 call at 40% vol", far_q), ("  vega at a 10% start", far_v), ("  first Newton step", far_step),
        ("  first step from a 20% start", far_step20), ("call at 1e-6 vol, the floor", call(s, k, r, q, 1e-6, t)),
        ("try: vega at 10% vol", vega(s, k, r, q, 0.10, t)), ("try: vega at 30% vol", vega(s, k, r, q, 0.30, t)),
        ("try: vega at 3 months", vega(s, k, r, q, v, 0.25)), ("phi(0), top of the bell curve", phi(0.0))];
    for (name, val) in &rows { println!("{:<34} {:>16.6}", name, val); }
    let spots: Vec<i32> = (70..131).step_by(5).collect();
    println!("chart spot {}", spots.iter().map(|x| format!("{:6}", x)).collect::<Vec<_>>().join(" "));
    for (lab, tt) in [("chart T=1.0 ", 1.0), ("chart T=0.25", 0.25)] {
        println!("{}{}", lab, spots.iter().map(|x| format!("{:6.2}", vega(*x as f64, k, r, q, v, tt))).collect::<Vec<_>>().join(" "));
    }
    let mats = [0.25, 0.5, 1.0, 2.0, 4.0, 10.0, 20.0, 30.0];
    println!("bars {}", mats.iter().map(|m| format!("{}y {:.2}", m, vega(s, k, r, q, v, *m))).collect::<Vec<_>>().join(" "));

    assert!((vg - 37.901157510017).abs() < 1e-9, "formula vs the shelf's house vega");
    assert!((v_cash - vg).abs() < 1e-12, "share side vs cash side, Step 1");
    assert!((bump - vg).abs() < 1e-6, "bumped formula price vs vega");
    assert!(((call(s, k, r, q, v + h, 4.0) - call(s, k, r, q, v - h, 4.0)) / (2.0 * h)
        - vega(s, k, r, q, v, 4.0)).abs() < 1e-6, "bumped price vs vega at four years");
    assert!((bump_int - vg).abs() < 1e-4, "bumped Simpson call vs vega");
    assert!((bump_put - vg).abs() < 1e-4, "put vega by its own integral vs call vega");
    assert!((mc - vg).abs() < 3.0 * mc_se, "pathwise Monte Carlo within three standard errors");
    assert!((v * t * s * s * gamma - vg).abs() < 1e-4, "gamma link");
    assert!((peak_s - k * (-(r - q - 0.5 * v * v) * t).exp()).abs() < 2e-3, "peak in spot");
    assert!((peak_k - s * ((r - q + 0.5 * v * v) * t).exp()).abs() < 2e-3, "peak in strike");
    assert!(grid > 0.0, "vega positive everywhere on the grid");
    assert!((steps[3] - 0.5 * (lo + hi)).abs() < 1e-9, "Newton vs bisection");
    println!("ALL CHECKS PASS");
}
