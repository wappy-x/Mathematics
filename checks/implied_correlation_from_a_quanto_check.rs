// Correlation from a quanto price -- the check behind the card.  Rust std only.
// Normal CDF, integrator, root finders and random numbers are all written here.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const XB: f64 = 1.10; const X0: f64 = 1.15;
const RD: f64 = 0.05; const RF: f64 = 0.03; const Q: f64 = 0.01;
const SS: f64 = 0.20; const SX: f64 = 0.10; const T: f64 = 1.0;
const HOUSE: f64 = 9.151629;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn n_cdf(x: f64) -> f64 {                                           // bell-curve area, by its Taylor series
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut t, mut s) = (x, x);
    for n in 1..400 {
        t *= x * x / (2 * n + 1) as f64; s += t;
        if t.abs() < 1e-17 * s.abs() { break; }
    }
    0.5 + s * phi(x)
}

#[derive(Clone, Copy)]
struct P { k: f64, xb: f64, vol: f64, sx: f64, sign: f64 }
const BASE: P = P { k: K, xb: XB, vol: SS, sx: SX, sign: -1.0 };

fn fwd(rho: f64) -> f64 { S * ((RF - Q - rho * SS * SX) * T).exp() }           // quanto forward, EUR
fn price(rho: f64, p: P) -> f64 {                                                // road 1: the closed form
    let f = S * ((RF - Q + p.sign * rho * SS * p.sx) * T).exp();
    let d1 = ((f / p.k).ln() + 0.5 * p.vol * p.vol * T) / (p.vol * T.sqrt()); let d2 = d1 - p.vol * T.sqrt();
    p.xb * (-RD * T).exp() * (f * n_cdf(d1) - p.k * n_cdf(d2))
}
fn slope(rho: f64, k: f64) -> f64 {                                              // dC/drho, by the chain rule
    let f = fwd(rho); let d1 = ((f / k).ln() + 0.5 * SS * SS * T) / (SS * T.sqrt());
    -XB * (-RD * T).exp() * f * n_cdf(d1) * SS * SX * T
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, log_rows: usize) -> f64 {
    for i in 0..80 {                                     // f(lo) > 0 > f(hi): the price falls as rho rises
        let mid = 0.5 * (lo + hi); let v = f(mid);
        if i < log_rows { println!("bisect step {}  rho {:+.6}  price minus quote {:+.6}", i + 1, mid, v); }
        if v > 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn implied(quote: f64, p: P) -> Option<f64> {         // existence first, then the unique root
    let (top, bottom) = (price(-1.0, p), price(1.0, p));
    if !(bottom <= quote && quote <= top) { return None; }
    Some(bisect(&|r| price(r, p) - quote, -1.0, 1.0, 0))
}
fn newton(quote: f64) -> f64 {                         // road 3: Newton, no bracket kept
    let mut rho = 0.0;
    for _ in 0..50 { rho -= (price(rho, BASE) - quote) / slope(rho, K); }
    rho
}
fn simpson_call_from_forward(f: f64) -> f64 {          // road 2: integrate the payoff over the bell curve
    let n = 2000; let v = SS * T.sqrt(); let a = ((K / f).ln() + 0.5 * v * v) / v; let b = 10.0;
    let h = (b - a) / n as f64;
    let g = |z: f64| (f * (-0.5 * v * v + v * z).exp() - K) * phi(z);
    let mut inner = 0.0;
    for i in 1..n { inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    XB * (-RD * T).exp() * (g(a) + g(b) + inner) * h / 3.0
}
fn forward_from_quote(quote: f64) -> f64 {             // secant on the forward, no correlation in sight
    let (mut f0, mut f1) = (100.0, 110.0);
    let (mut g0, mut g1) = (simpson_call_from_forward(f0) - quote, simpson_call_from_forward(f1) - quote);
    for _ in 0..60 {
        if g1 == g0 { break; }
        let f2 = f1 - g1 * (f1 - f0) / (g1 - g0);
        f0 = f1; f1 = f2; g0 = g1; g1 = simpson_call_from_forward(f1) - quote;
    }
    f1
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                     // splitmix64, then a number strictly inside (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal_pair(&mut self) -> (f64, f64) {          // Box-Muller
        let r = (-2.0 * self.uniform().ln()).sqrt(); let a = 2.0 * PI * self.uniform();
        (r * a.cos(), r * a.sin())
    }
}
fn mc_price(rho: f64, pairs: &[(f64, f64)]) -> (f64, f64) {   // road 4: simulate in the EURO world
    let (mut total, mut total2) = (0.0, 0.0); let c = (1.0 - rho * rho).sqrt();
    for &(z1, z2) in pairs {
        let mut pair = 0.0;
        for s in [1.0, -1.0] {                          // antithetic: each draw and its mirror
            let st = S * ((RF - Q - 0.5 * SS * SS) * T + SS * T.sqrt() * s * z1).exp();
            let xt = X0 * ((RD - RF + 0.5 * SX * SX) * T + SX * T.sqrt() * s * (rho * z1 + c * z2)).exp();
            pair += 0.5 * XB * (st - K).max(0.0) / xt;
        }
        total += pair; total2 += pair * pair;
    }
    let n = pairs.len() as f64; let m = total / n; let se = ((total2 / n - m * m) / n).sqrt();
    (X0 * (-RF * T).exp() * m, X0 * (-RF * T).exp() * se)
}
fn sample_corr(rng: &mut Rng) -> f64 {                   // one simulated year of daily returns
    let (n, rho) = (252, 0.30); let (mut xs, mut ys) = (Vec::new(), Vec::new());
    for _ in 0..n { let (z1, z2) = rng.normal_pair(); xs.push(z1); ys.push(rho * z1 + (1.0f64 - rho * rho).sqrt() * z2); }
    let mx = xs.iter().fold(0.0, |a, b| a + b) / n as f64; let my = ys.iter().fold(0.0, |a, b| a + b) / n as f64;
    let (mut sxy, mut sxx, mut syy) = (0.0, 0.0, 0.0);
    for i in 0..n { sxy += (xs[i] - mx) * (ys[i] - my); }
    for i in 0..n { sxx += (xs[i] - mx) * (xs[i] - mx); }
    for i in 0..n { syy += (ys[i] - my) * (ys[i] - my); }
    sxy / (sxx * syy).sqrt()
}
fn p(label: &str, v: Option<f64>) {
    match v { Some(x) => println!("{:<44} {:>12.6}", label, x), None => println!("{:<44} {:>12}", label, "none") }
}

fn main() {
    let mut rng = Rng(20260927);
    let pairs: Vec<(f64, f64)> = (0..100000).map(|_| rng.normal_pair()).collect();
    p("formula at rho 0.30: the house quote", Some(price(0.30, BASE)));
    p("ceiling: price at rho = -1", Some(price(-1.0, BASE))); p("floor: price at rho = +1", Some(price(1.0, BASE)));
    let r1 = bisect(&|r| price(r, BASE) - HOUSE, -1.0, 1.0, 6);
    let f2 = forward_from_quote(HOUSE); let r2 = (RF - Q - (f2 / S).ln() / T) / (SS * SX);
    let r3 = newton(HOUSE);
    p("1 bisection on the formula", Some(r1)); p("2 forward from quote, Simpson + secant", Some(f2));
    p("  ln(F/S)/T, the forward's growth", Some((f2 / S).ln() / T));
    p("  rho = (rf - q - ln(F/S)/T) / (sS sX)", Some(r2)); p("3 Newton from rho = 0", Some(r3));
    p("rho sS sX, the quanto adjustment", Some(r1 * SS * SX)); p("rho sX, all the quote pins down", Some(r1 * SX));
    let mc: Vec<(f64, (f64, f64))> = [-1.0, 0.30, 1.0].iter().map(|&r| (r, mc_price(r, &pairs))).collect();
    for &(rho, (m, se)) in &mc {
        println!("4 euro-world simulation, rho {:+.2}  {:>12.6}  one standard error {:.6}", rho, m, se);
    }
    p("quote 11.00: correlation", implied(11.00, BASE)); p("  Newton, unbracketed", Some(newton(11.00)));
    p("quote 8.20: correlation", implied(8.20, BASE)); p("quote 9.40: correlation", implied(9.40, BASE));
    p("quote 8.50: correlation", implied(8.50, BASE));
    p("slope dC/drho at 0.30", Some(slope(r1, K))); p("rho moved by a 1-cent quote error", Some(0.01 / slope(r1, K).abs()));
    let k140 = P { k: 140.0, ..BASE };
    p("  strike 140: ceiling", Some(price(-1.0, k140))); p("  strike 140: floor", Some(price(1.0, k140)));
    p("  strike 140: rho moved by 1 cent", Some(0.01 / slope(0.30, 140.0).abs()));
    for sx in [0.02, 0.03, 0.05, 0.15, 0.30] {
        p(&format!("FX vol {:.2} assumed: correlation", sx), implied(HOUSE, P { sx, ..BASE }));
    }
    let wide = P { vol: (SS * SS + SX * SX).sqrt(), ..BASE };
    p("wrong: spot 1.15 for the fixed 1.10", implied(HOUSE, P { xb: X0, ..BASE }));
    p("wrong: vol sqrt(sS^2 + sX^2)", implied(HOUSE, wide)); p("  the floor with that vol", Some(price(1.0, wide)));
    let plus = P { sign: 1.0, ..BASE };
    p("wrong: plus sign on rho", Some(bisect(&|r| HOUSE - price(r, plus), -1.0, 1.0, 0)));
    let est: Vec<f64> = (0..1000).map(|_| sample_corr(&mut rng)).collect();
    let mean = est.iter().fold(0.0, |a, b| a + b) / est.len() as f64;
    let sd = (est.iter().fold(0.0, |a, e| a + (e - mean) * (e - mean)) / (est.len() - 1) as f64).sqrt();
    let formula = (1.0 - 0.09) / 252f64.sqrt(); let r940 = implied(9.40, BASE).unwrap();
    p("history: first simulated year's estimate", Some(est[0])); p("history: average of 1000 years", Some(mean));
    p("history: spread of the estimates", Some(sd)); p("  formula (1 - rho^2) / sqrt(252)", Some(formula));
    p("  quote 9.40 sits this many spreads away", Some((0.30 - r940) / sd));
    println!("sweep: rho, price, quanto forward");
    for rho in [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0] {
        println!("  {:+.2}  {:.2}  {:.2}", rho, price(rho, BASE), fwd(rho));
    }
    assert!((r1 - 0.30).abs() < 1e-5); assert!((r2 - r1).abs() < 1e-6); assert!((r3 - r1).abs() < 1e-9);
    assert!((slope(r1, K) - (price(r1 + 1e-5, BASE) - price(r1 - 1e-5, BASE)) / 2e-5).abs() < 1e-6);   // slope = finite difference
    assert!((-8..8).all(|i| price(i as f64 / 8.0, BASE) > price((i + 1) as f64 / 8.0, BASE)));          // strictly falling
    for &(rho, (m, se)) in &mc { assert!((m - price(rho, BASE)).abs() < 4.0 * se); }
    assert!(implied(11.00, BASE).is_none()); assert!(newton(11.00) < -1.0); assert!(implied(8.20, BASE).is_none());
    let a = implied(HOUSE, P { sx: 0.05, ..BASE }).unwrap() * 0.05; let b = implied(HOUSE, P { sx: 0.15, ..BASE }).unwrap() * 0.15;
    assert!((a - b).abs() < 1e-6);
    assert!((sd / formula - 1.0).abs() < 0.15);
    println!("All checks passed.");
}
