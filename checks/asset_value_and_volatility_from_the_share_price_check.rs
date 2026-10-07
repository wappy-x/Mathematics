// Asset value and asset volatility from the share price -- the same check as the Python, in Rust.
// No crates: normal CDF, root finders, Newton and random numbers are written here.
use std::f64::consts::PI;

const B: f64 = 80.0; // debt face ($m)
const T: f64 = 1.0; // years
const R: f64 = 0.05; // riskless rate

fn kd() -> f64 { B * (-R * T).exp() } // the debt's face, discounted to today
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n(x: f64) -> f64 { // bell-curve area left of x, by its power series
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}
fn merton_t(v: f64, u: f64, t: f64) -> (f64, f64, f64) { // equity = call on assets v, asset vol u
    let a = u * t.sqrt();
    let d1 = (v / (B * (-R * t).exp())).ln() / a + 0.5 * a;
    (v * n(d1) - B * (-R * t).exp() * n(d1 - a), d1, d1 - a)
}
fn merton(v: f64, u: f64) -> (f64, f64, f64) { merton_t(v, u, T) }
fn by_integral(v: f64, u: f64) -> f64 { // road 0: equity as the average payoff, Simpson's rule
    let (m, drift, vol) = (200000usize, (R - 0.5 * u * u) * T, u * T.sqrt());
    let h = 20.0 / m as f64;
    let f = |z: f64| (v * (drift + vol * z).exp() - B).max(0.0) * phi(z);
    let w = |i: usize| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    (-R * T).exp() * h / 3.0 * (0..=m).map(|i| w(i) * f(-10.0 + i as f64 * h)).sum::<f64>()
}
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 { // f rises through zero
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn assets_for_price(e: f64, u: f64) -> f64 { bisect(|v| merton(v, u).0 - e, e, e + kd()) }
fn assets_for_vol(e: f64, s: f64, u: f64) -> f64 { bisect(|v| u * v * n(merton(v, u).1) - s * e, 1e-9, 1e6) }
fn g(e: f64, u: f64) -> (f64, f64) { // currency volatility along the price curve
    let v = assets_for_price(e, u);
    (v, u * v * n(merton(v, u).1))
}
fn road_bisect(e: f64, s: f64) -> (f64, f64) { // road 3: nested bisection, no derivatives
    let u = bisect(|x| g(e, x).1 - s * e, 1e-9, 5.0);
    (g(e, u).0, u)
}
fn misses(e: f64, s: f64, v: f64, u: f64) -> (f64, f64) {
    let (c, d1, _) = merton(v, u);
    (c - e, u * v * n(d1) - s * e)
}
fn road_newton(e: f64, s: f64, show: bool) -> (f64, f64, usize) { // road 1: damped Newton
    let (mut v, mut u) = (e + kd(), s * e / (e + kd()));
    for k in 0..50 {
        let (f1, f2) = misses(e, s, v, u);
        if show { println!("newton step {}   V {:12.6}   sigma_V {:9.6}   miss {:11.6}", k, v, u, f1.abs() + f2.abs()); }
        if f1.abs() + f2.abs() < 1e-11 { return (v, u, k); }
        let (_, d1, d2) = merton(v, u);
        let (a11, a12) = (n(d1), v * phi(d1) * T.sqrt());
        let (a21, a22) = (u * n(d1) + phi(d1) / T.sqrt(), v * (n(d1) - phi(d1) * d2));
        let det = a11 * a22 - a12 * a21;
        let (dv, du) = ((f1 * a22 - f2 * a12) / det, (a11 * f2 - a21 * f1) / det);
        let mut lam = 1.0;
        loop {
            let (vn, un) = (v - lam * dv, u - lam * du);
            if vn > 0.0 && un > 0.0 {
                let (m1, m2) = misses(e, s, vn, un);
                if m1.abs() + m2.abs() <= f1.abs() + f2.abs() { break; }
            }
            lam *= 0.5;
        }
        v -= lam * dv;
        u -= lam * du;
    }
    panic!("Newton did not converge")
}
fn road_fixed_point(e: f64, s: f64) -> (f64, f64, usize) { // road 2: the fixed-point iteration
    let mut u = s * e / (e + kd());
    for k in 1..500 {
        let v = assets_for_price(e, u);
        let u_new = s * e / (v * n(merton(v, u).1));
        if (u_new - u).abs() < 1e-13 { return (v, u_new, k); }
        u = u_new;
    }
    panic!("fixed point did not converge")
}
struct Rng(u64);
impl Rng { // splitmix64, written out
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}
fn simulated_equity_vol(v: f64, u: f64) -> f64 { // road 4: one-day moves, measured
    let (dt, e0) = (1.0 / 252.0, merton(v, u).0);
    let mut rng = Rng(20260928);
    let mut xs: Vec<f64> = Vec::new();
    for _ in 0..100000 { // Box-Muller: two bell-curve draws per pair
        let rad = (-2.0 * (1.0 - rng.unif()).ln()).sqrt();
        let ang = 2.0 * PI * rng.unif();
        for z in [rad * ang.cos(), rad * ang.sin()] {
            let v1 = v * ((R - 0.5 * u * u) * dt + u * dt.sqrt() * z).exp();
            xs.push((merton_t(v1, u, T - dt).0 / e0).ln());
        }
    }
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() as f64 - 1.0) / dt).sqrt()
}
fn lev(v: f64, u: f64) -> f64 { let (e, d1, _) = merton(v, u); v * n(d1) / e }
fn row(label: &str, xs: &[f64], dp: usize) -> String {
    let cells: Vec<String> = xs.iter().map(|x| format!("{:7.*}", dp, x)).collect();
    format!("{}{}", label, cells.join(" "))
}
fn main() {
    let (e0, d1, d2) = merton(100.0, 0.20);
    let (l0, s0, e_int) = (100.0 * n(d1) / e0, 20.0 * n(d1) / e0, by_integral(100.0, 0.20));
    println!("debt face B e^-rT                  {:12.6}", kd());
    for (name, v) in [("ln(V / B e^-rT)", (100.0 / kd()).ln()), ("d1", d1), ("d2", d2), ("N(d1)", n(d1)), ("N(d2)", n(d2)), ("phi(d1)", phi(d1)), ("asset half V N(d1)", 100.0 * n(d1)), ("debt half B e^-rT N(d2)", kd() * n(d2)), ("equity E", e0), ("equity E by integral", e_int),
                      ("debt V - E", 100.0 - e0), ("leverage L = V N(d1) / E", l0), ("equity vol L x 0.20", s0)] {
        println!("{:<34} {:12.6}", name, v);
    }
    let (e, s) = (24.59, 0.755);
    let (v1, u1, k1) = road_newton(e, s, true);
    let ((v2, u2, k2), (v3, u3)) = (road_fixed_point(e, s), road_bisect(e, s));
    let (vx, ux, _) = road_newton(e0, s0, false);
    let sim = simulated_equity_vol(100.0, 0.20);
    println!("road 1 Newton        V {:12.6}   sigma_V {:9.6}   steps {}", v1, u1, k1);
    println!("road 2 fixed point   V {:12.6}   sigma_V {:9.6}   steps {}", v2, u2, k2);
    println!("road 3 bisection     V {:12.6}   sigma_V {:9.6}", v3, u3);
    println!("round trip, exact quotes   V {:12.6}   sigma_V {:9.6}", vx, ux);
    println!("road 4 simulated equity vol, 200000 one-day moves {:9.4}   (L x 0.20 = {:.4})", sim, s0);
    let grid: Vec<f64> = (0..9).map(|i| 0.12 + 0.02 * i as f64).collect();
    println!("{}", row("chart1 sigma_V   ", &grid, 2));
    println!("{}", row("chart1 price V   ", &grid.iter().map(|&x| assets_for_price(e, x)).collect::<Vec<f64>>(), 2));
    println!("{}", row("chart1 vol V     ", &grid.iter().map(|&x| assets_for_vol(e, s, x)).collect::<Vec<f64>>(), 2));
    let vs: Vec<f64> = (0..11).map(|i| 60.0 + 10.0 * i as f64).collect();
    println!("{}", row("chart2 assets V  ", &vs, 0));
    println!("{}", row("chart2 eq vol %  ", &vs.iter().map(|&v| 20.0 * lev(v, 0.2)).collect::<Vec<f64>>(), 2));
    println!("assets  equity E   equity vol   % move in sigma_V   % move in V   (per 1% error in equity vol)");
    for v in [120.0, 100.0, 80.0, 60.0, 50.0, 40.0] {
        let ec = merton(v, 0.20).0;
        let sc = 0.20 * lev(v, 0.20);
        let (vb, ub) = road_bisect(ec, sc * 1.01);
        println!("{:6.0} {:10.5} {:12.4} {:19.2} {:13.3}", v, ec, sc, 100.0 * (ub / 0.20 - 1.0), 100.0 * (vb / v - 1.0));
    }
    let (vl, ul, _) = road_newton(e, 0.10, false);
    let ll = vl * n(merton(vl, ul).1) / e;
    println!("equity vol 10%: V {:10.6}  sigma_V {:9.6}  leverage L {:8.4}", vl, ul, ll);
    println!("fixed sigma_V 0.20: L at V = 1000 {:9.6}", lev(1000.0, 0.2));
    println!("wrong: equity vol used as asset vol, V {:10.4}", assets_for_price(e, s));
    println!("wrong: share-of-value shortcut, V {:10.4}  sigma_V {:8.4}", e + kd(), s * e / (e + kd()));
    println!("wrong: undiscounted debt, V = E + B {:10.4}", e + B);
    println!("wrong: price equation only, guess sigma_V 0.30, V {:10.4}", assets_for_price(e, 0.30));

    assert!((vx - 100.0).abs() < 1e-7 && (ux - 0.20).abs() < 1e-9, "round trip returns the generating firm");
    assert!((v1 - v3).abs() < 1e-7 && (u1 - u3).abs() < 1e-9, "Newton and bisection agree");
    assert!(k1 <= 5, "Newton with the true Jacobian converges in a handful of steps");
    assert!((v2 - v3).abs() < 1e-7 && (u2 - u3).abs() < 1e-9, "fixed point and bisection agree");
    assert!((sim - s0).abs() < 0.006, "simulated equity vol matches leverage x asset vol");
    assert!((e_int - e0).abs() < 1e-8, "average payoff matches the call formula");
    assert!(grid.windows(2).all(|w| g(e, w[0]).1 < g(e, w[1]).1), "G rises: one crossing");
    assert!(ul > 0.0 && ul < 0.10 && ll > 1.0, "10% equity vol solves, with equity vol above asset vol");
    println!("ALL CHECKS PASS");
}
