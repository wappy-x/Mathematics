// Differentiating under the integral sign -- the same check as the Python, in
// Rust.  No crates.  A bakery sells N e^(-z p) loaves at price p (in pounds)
// on a day whose price sensitivity is z; z is random with density
// 4 z e^(-2z), rate 2.  Profit that day: (p - c) N e^(-z p).
// The marginal average profit at p = 3 is found four ways: a formula worked
// by hand, the derivative of the average, the average of the derivative, and
// a simulation.  Then the dominating bound, the Gaussian moment trick, and
// two cases where the swap fails.
const N: f64 = 500.0;
const C: f64 = 1.0;
const RATE: f64 = 2.0;
const P0: f64 = 3.0;

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    // composite Simpson rule, n even
    let w = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n {
        acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * w);
    }
    (f(a) + f(b) + acc) * w / 3.0
}

fn dens(z: f64) -> f64 { RATE * RATE * z * (-RATE * z).exp() } // sensitivity density, per pound
fn avg(g: &dyn Fn(f64) -> f64) -> f64 { simpson(&|z| g(z) * dens(z), 0.0, 40.0, 16000) }
fn profit(p: f64, z: f64) -> f64 { (p - C) * N * (-z * p).exp() }
fn dprofit(p: f64, z: f64) -> f64 { N * (-z * p).exp() * (1.0 - (p - C) * z) } // partial in p, by hand
fn avg_profit(p: f64) -> f64 { avg(&|z| profit(p, z)) }
fn avg_dprofit(p: f64) -> f64 { avg(&|z| dprofit(p, z)) }

fn root(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    // bisection: f > 0 at lo, f < 0 at hi
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if f(mid) > 0.0 { lo = mid; } else { hi = mid; }
    }
    lo
}

fn two(v: f64) -> String { format!("{:.2}", if v.abs() < 0.005 { 0.0 } else { v }) }

struct SplitMix(u64);
impl SplitMix {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = self.0;
        x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((x ^ (x >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn main() {
    println!("density: total {:.6}, mean sensitivity {:.6} per pound", avg(&|_| 1.0), avg(&|z| z));
    let formula = N * RATE.powi(2) * (RATE + 2.0 * C - P0) / (RATE + P0).powi(3);
    println!("road 1, formula: Pi(3) = {:.4}, Pi'(3) = 2000(4 - p)/(2 + p)^3 = {:.4}", N * (P0 - C) * (RATE / (RATE + P0)).powi(2), formula);
    let mut q = 0.0;
    for h in [0.1, 0.01, 0.001] {
        q = (avg_profit(P0 + h) - avg_profit(P0 - h)) / (2.0 * h);
        println!("road 2, derivative of the average: h = {}: (Pi(3 + h) - Pi(3 - h))/2h = {:.6}", h, q);
    }
    assert!((q - formula).abs() < 1e-5);
    let road3 = avg_dprofit(P0);
    let (e0, e1) = (avg(&|z| (-z * P0).exp()), avg(&|z| z * (-z * P0).exp()));
    println!("road 3, average of the derivative: 500 x ({:.6} - 2 x {:.6}) = {:.6}", e0, e1, road3);
    assert!((road3 - formula).abs() < 1e-6);

    let mut rng = SplitMix(20260929); // SplitMix64, seed 20260929
    let n = 200000usize;
    let (mut s1, mut s2, mut fd) = (0.0f64, 0.0f64, 0.0f64);
    for _ in 0..n {
        let u1 = rng.unif();
        let u2 = rng.unif();
        let z = (-u1.ln() - u2.ln()) / RATE; // sum of two exponentials
        let d = dprofit(P0, z);
        s1 += d;
        s2 += d * d;
        fd += (profit(P0 + 0.001, z) - profit(P0 - 0.001, z)) / 0.002;
    }
    let nf = n as f64;
    let (mean, se) = (s1 / nf, ((s2 / nf - (s1 / nf).powi(2)) / nf).sqrt());
    println!("road 4, simulation of {} days: average of the derivative {:.2} (standard error {:.2}); difference quotient, same days {:.2}", n, mean, se, fd / nf);
    assert!((mean - formula).abs() < 4.0 * se);

    let g = |z: f64| N * (1.0 + 3.0 * z) * (-2.0 * z).exp(); // bound for p in [2, 4]
    let mut worst: f64 = 0.0;
    for i in 0..101 {
        for j in 0..801 {
            let (p, z) = (2.0 + i as f64 / 50.0, j as f64 / 20.0);
            worst = worst.max(dprofit(p, z).abs() / g(z));
        }
    }
    let bound = avg(&g);
    println!("bound on [2, 4]: g(z) = 500(1 + 3z)e^(-2z); largest |dy/dp|/g on a grid {:.4}; integral of g = {:.4}", worst, bound);
    assert!(worst <= 1.0);
    assert!((bound - N * (RATE.powi(2) / (RATE + 2.0).powi(2) + 3.0 * 2.0 * RATE.powi(2) / (RATE + 2.0).powi(3))).abs() < 1e-6);

    let lo = root(&avg_dprofit, 2.0, 7.0); // best price: where the average derivative is zero
    println!("best price: average derivative zero at p = {:.4}, Pi = {:.4}; formula rate + 2c = {:.4}", lo, avg_profit(lo), RATE + 2.0 * C);
    assert!((lo - (RATE + 2.0 * C)).abs() < 1e-6);

    let ps: Vec<f64> = (0..11).map(|k| 2.0 + k as f64 / 2.0).collect();
    let row = |f: &dyn Fn(f64) -> String| ps.iter().map(|&p| f(p)).collect::<Vec<_>>().join(", ");
    println!("chart, price: {}", row(&|p| format!("{:.1}", p)));
    println!("chart, average profit: {}", row(&|p| two(avg_profit(p))));
    println!("chart, marginal profit: {}", row(&|p| two(avg_dprofit(p))));
    println!("average day, z = 1: profit {}, derivative {}, best price {:.2}", two(profit(P0, 1.0)), two(dprofit(P0, 1.0)), root(&|p| dprofit(p, 1.0), 1.0, 7.0));

    let gg = |t: f64| simpson(&|x| (-t * x * x).exp(), -12.0, 12.0, 2400);
    let m2 = simpson(&|x| x * x * (-x * x).exp(), -12.0, 12.0, 2400);
    let m4 = simpson(&|x| x.powf(4.0) * (-x * x).exp(), -12.0, 12.0, 2400);
    let d1 = -(gg(1.001) - gg(0.999)) / 0.002;
    let d2 = (gg(1.0001) - 2.0 * gg(1.0) + gg(0.9999)) / 1e-8;
    let rp = std::f64::consts::PI.sqrt();
    println!("gauss: G(1) = {:.6}, sqrt(pi) = {:.6}", gg(1.0), rp);
    println!("gauss: -G'(1) = {:.6}; integral of x^2 e^(-x^2) = {:.6}; sqrt(pi)/2 = {:.6}", d1, m2, rp / 2.0);
    println!("gauss: G''(1) = {:.6}; integral of x^4 e^(-x^2) = {:.6}; 3 sqrt(pi)/4 = {:.6}", d2, m4, 3.0 * rp / 4.0);
    assert!((d1 - m2).abs() < 1e-6);
    assert!((m2 - rp / 2.0).abs() < 1e-10);
    assert!((d2 - m4).abs() < 1e-6);
    assert!((m4 - 3.0 * rp / 4.0).abs() < 1e-10);

    // breaks 1: a buyer with willingness to pay W, uniform on [1, 6], buys one loaf if W >= p
    let k = 500000usize;
    let w = |i: usize| 1.0 + (i as f64 + 0.5) * 5.0 / k as f64;
    let per_buyer = |p: f64| {
        // average of (p - 1) 1{W >= p}, midpoint rule
        let mut acc = 0.0;
        for i in 0..k { if w(i) >= p { acc += p - C; } }
        acc / k as f64
    };
    let true_d = (per_buyer(3.001) - per_buyer(2.999)) / 0.002;
    let inside = (0..k).filter(|&i| w(i) > 3.0).count() as f64 / k as f64;
    println!("breaks, threshold buyer: average profit {:.4}; derivative of the average {:.4}; average of the derivative {:.4}", per_buyer(3.0), true_d, inside);
    for h in [0.1, 0.01, 0.001] {
        let qa = (per_buyer(3.0 + h) - per_buyer(3.0)) / h;
        let strip = (0..k).filter(|&i| 3.0 <= w(i) && w(i) < 3.0 + h).count() as f64 / k as f64;
        println!("breaks, threshold buyer: h = {}: quotient -2/h = {:.0} on a strip of probability {:.4}, carrying {:.4}; average quotient {:.4}", h, -2.0 / h, strip, strip * -2.0 / h, qa);
    }
    assert!((true_d - 0.2).abs() < 1e-3);
    assert!((inside - true_d).abs() > 0.3);

    // breaks 2: f(t, x) = t^3 e^(-t^2 x) on [0, inf): F(t) = t, but df/dt(0, x) = 0
    for h in [0.1f64, 0.01, 0.001] {
        let area = simpson(&|x| h * h * (-h * h * x).exp(), 0.0, 40.0 / h.powi(2), 4000);
        println!("breaks, spreading: h = {}: quotient h^2 e^(-h^2 x) has integral {:.6}, value at x = 1 {:.8}", h, area, h * h * (-h * h).exp());
        assert!((area - 1.0).abs() < 1e-6);
    }
    let env = (1..1001).map(|k| (k as f64 / 1000.0).powi(2) * (-(k as f64 / 1000.0).powi(2) * 100.0).exp()).fold(0.0f64, f64::max);
    let e = std::f64::consts::E;
    println!("breaks, spreading: largest quotient at x = 100 over h in (0, 1]: {:.6}; 1/(100 e) = {:.6}", env, 1.0 / (100.0 * e));
    assert!((env - 1.0 / (100.0 * e)).abs() < 1e-6);
    for x in [100u64, 10000, 1000000] {
        println!("breaks, spreading: 1/(e x) integrated from 1 to {} = {:.4}", x, (x as f64).ln() / e);
    }
    println!("ALL CHECKS PASS");
}
