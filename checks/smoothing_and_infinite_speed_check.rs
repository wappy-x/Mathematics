// Smoothing and infinite speed -- the same check as the Python, in Rust.  No crates.
// A 1 m copper rod, kappa = 1.11e-4 m^2/s, ends held at room temperature.  Start: a
// tent-shaped hot spot, 50 C above room at x = 0.5 m, falling to 0 at 0.4 and 0.6 m.
// Roads: kernel closed form; sine series on the rod; direct Simpson convolution;
// the equation's residual by centred differences; log-space integral for the far end.
use std::f64::consts::PI;
const K: f64 = 1.11e-4;
const H: f64 = 50.0;
const W: f64 = 0.1;
const L: f64 = 1.0;
const KINKS: [(f64, f64); 3] = [(0.4, 1.0), (0.5, -2.0), (0.6, 1.0)]; // f'' = (H/W) sum c delta

fn sci(x: f64, p: usize) -> String {             // e-notation with the same digits as Python
    let mut e = x.abs().log10().floor();
    let mut m: f64 = format!("{:.*}", p, x.abs() / 10f64.powf(e)).parse().unwrap();
    if m >= 10.0 { m /= 10.0; e += 1.0; }
    format!("{}{:.*}e{}", if x < 0.0 { "-" } else { "" }, p, m, e as i64)
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn cf(z: f64) -> f64 {                           // T = 1/(z + 2/(z + 3/(z + ...))), z >= 3
    let mut t = 0.0;
    for k in (2..=300).rev() { t = k as f64 / (z + t); }
    1.0 / (z + t)
}
fn erf(z: f64) -> f64 {                          // Maclaurin series, |z| <= 2.2
    let (mut s, mut term, mut n) = (0.0, z, 0.0);
    while term.abs() > 1e-17 { s += term / (2.0 * n + 1.0); n += 1.0; term *= -z * z / n; }
    2.0 / PI.sqrt() * s
}
fn r(x: f64, t: f64) -> f64 {                    // a ramp max(x, 0) after time t
    let s = (2.0 * K * t).sqrt();
    let z = x / s;
    if z < -3.0 { let tt = cf(-z); return s * phi(z) * tt / (-z + tt); }
    if z > 3.0 { return x + r(-x, t); }
    x * 0.5 * (1.0 + erf(z / 2f64.sqrt())) + s * phi(z)
}
fn g(x: f64, t: f64) -> f64 { (-x * x / (4.0 * K * t)).exp() / (4.0 * PI * K * t).sqrt() }
fn gxx(x: f64, t: f64) -> f64 { (x * x / (4.0 * K * K * t * t) - 1.0 / (2.0 * K * t)) * g(x, t) }
fn u(x: f64, t: f64) -> f64 {                    // rod = line plus odd images at the ends
    let mut s = 0.0;
    for (xk, c) in KINKS { for m in -3..4 { let m = m as f64;
        s += (H / W) * c * (r(x - xk - 2.0 * m, t) - r(-x - xk - 2.0 * m, t)); } }
    s
}
fn uxx(x: f64, t: f64) -> f64 { (H / W) * KINKS.iter().map(|&(xk, c)| c * g(x - xk, t)).sum::<f64>() }
fn uxxxx(x: f64, t: f64) -> f64 { (H / W) * KINKS.iter().map(|&(xk, c)| c * gxx(x - xk, t)).sum::<f64>() }
fn series(x: f64, t: f64, n: usize, p: i32) -> f64 { // sine series: p-th x-derivative (p = 0, 2, 4)
    let mut tot = 0.0;
    for n in 1..=n {
        let k = n as f64 * PI / L;
        let bk2 = -(2.0 / L) * (H / W) * KINKS.iter().map(|&(xk, c)| c * (k * xk).sin()).sum::<f64>();
        let sign = if (p / 2) % 2 == 0 { 1.0 } else { -1.0 };
        tot += bk2 * k.powi(p - 2) * sign * (-K * k * k * t).exp() * (k * x).sin();
    }
    tot
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn tent(y: f64) -> f64 { (H * (1.0 - (y - 0.5).abs() / W)).max(0.0) }
fn cd(d: i32) -> f64 { match d { 1 => 1.0 / PI.sqrt(), 2 => PI.sqrt() / 2.0, _ => 2.0 / PI.sqrt() } }
fn cone(d: i32, t: f64) -> f64 {                 // several dimensions: a cone of radius W
    let sa = match d { 1 => 2.0, 2 => 2.0 * PI, _ => 4.0 * PI };
    let s = (2.0 * K * t).sqrt();
    simpson(&|r: f64| sa * r.powi(d - 1) * (-r * r / (4.0 * K * t)).exp() / (4.0 * PI * K * t).powf(d as f64 / 2.0) * H * (1.0 - r / W), 0.0, 30.0 * s, 4000)
}
fn log10_far(x: f64, t: f64) -> f64 {            // dominant kink at 0.6 m; R(-a) in logs
    let (a, s) = (x - 0.6, (2.0 * K * t).sqrt());
    let z = a / s;
    let tt = cf(z);
    (H / W).log10() + s.log10() + (-z * z / 2.0 - 0.5 * (2.0 * PI).ln()) / 10f64.ln() + (tt / (z + tt)).log10()
}
fn log10_simpson(x: f64, t: f64, n: usize) -> f64 { // log-sum-exp of Simpson's sum near 0.6 m
    let wdt = 60.0 * 2.0 * K * t / (x - 0.6);
    let hh = wdt / n as f64;
    let lg: Vec<f64> = (0..=n).map(|i| { let y = 0.6 - wdt + i as f64 * hh;
        let wt: f64 = if i > 0 && i < n { if i % 2 == 1 { 4.0 } else { 2.0 } } else { 1.0 };
        -(x - y).powi(2) / (4.0 * K * t) - 0.5 * (4.0 * PI * K * t).ln() + tent(y).max(1e-300).ln() + wt.ln() }).collect();
    let mx = lg.iter().cloned().fold(f64::MIN, f64::max);
    (mx + lg.iter().map(|v| (v - mx).exp()).sum::<f64>().ln() + (hh / 3.0).ln()) / 10f64.ln()
}

fn main() {
    let t1 = 1e-3;
    let s1 = (2.0 * K * t1).sqrt();
    println!("kappa t = {} m^2, rounding width sqrt(kappa t) = {:.4} mm at 1 ms", sci(K * t1, 3), (K * t1).sqrt() * 1e3);
    let pk = [u(0.5, t1), series(0.5, t1, 8000, 0), simpson(&|y| g(0.5 - y, t1) * tent(y), 0.5 - 30.0 * s1, 0.5 + 30.0 * s1, 4000)];
    println!("peak at 1 ms, C: kernel {:.6}, sine series {:.6}, Simpson {:.6}", pk[0], pk[1], pk[2]);
    println!("drop of the peak at 1 ms, C: formula 2 (H/W) c_1 sqrt(kappa t) = {:.6}, kernel 50 - peak = {:.6}", 2.0 * H / W / PI.sqrt() * (K * t1).sqrt(), H - pk[0]);
    let c2 = [uxx(0.5, t1), series(0.5, t1, 8000, 2)];
    println!("curvature at the peak, 1 ms, C/m^2: kernel {}, series {}", sci(c2[0], 4), sci(c2[1], 4));
    println!("series tail: first omitted term of u_xx at N = 8000 below {}", sci(4.0 * 2.0 * H / W * (-K * (8001.0 * PI).powi(2) * t1).exp(), 3));
    let (h, hx) = (1e-6, 1e-5);                  // residual: u_t against kappa u_xx at the peak
    let ut = (u(0.5, t1 + h) - u(0.5, t1 - h)) / (2.0 * h);
    let kuxx = K * (u(0.5 + hx, t1) - 2.0 * u(0.5, t1) + u(0.5 - hx, t1)) / (hx * hx);
    println!("at the peak, 1 ms, C/s: u_t = {:.2}, kappa u_xx (differences) = {:.2}, kappa u_xx (kernel) = {:.2}", ut, kuxx, K * c2[0]);
    let mut rows = vec![];
    for t in [1e-3, 4e-3, 16e-3, 64e-3] {
        rows.push((t, H - u(0.5, t), uxx(0.5, t), uxxxx(0.5, t)));
        println!("t = {:4.0} ms: drop {:.4} C, u_xx {} C/m^2, u_xxxx {} C/m^4", t * 1e3, H - u(0.5, t), sci(uxx(0.5, t), 3), sci(uxxxx(0.5, t), 3));
    }
    println!("ratios per 4x time: u_xx {:.4}, u_xxxx {:.4}, drop {:.4}", rows[0].2 / rows[1].2, rows[0].3 / rows[1].3, rows[1].1 / rows[0].1);
    let c1n = simpson(&|x: f64| x.abs() / (2.0 * K * t1) * g(x, t1), -30.0 * s1, 30.0 * s1, 4000) * (K * t1).sqrt();
    let c2n = simpson(&|x| gxx(x, t1).abs(), -30.0 * s1, 30.0 * s1, 4000) * K * t1;
    println!("c_1: Simpson {:.6}, 1/sqrt(pi) {:.6};  c_2: Simpson {:.6}, 2 phi(1) {:.6}", c1n, 1.0 / PI.sqrt(), c2n, 2.0 * phi(1.0));
    println!("bound sup|f'| c_1 / sqrt(kappa t) at 1 ms: {} C/m^2", sci(H / W * c1n / (K * t1).sqrt(), 4));
    for t in [0.0, 1e-3, 16e-3] {
        let v: Vec<String> = (-6..=6).map(|i| { let x = 0.5 + i as f64 * 5e-4; format!("{:.3}", if t == 0.0 { tent(x) } else { u(x, t) }) }).collect();
        println!("figure, t = {:.0} ms, x - 0.5 m = -3..3 mm: {}", t * 1e3, v.join(", "));
    }
    let mut lap = [0.0; 4];
    for d in 1..=3 {
        lap[d as usize] = (cone(d, t1 + h) - cone(d, t1 - h)) / (2.0 * h) / K;
        println!("d = {}: tip drop {:.4} C (formula {:.4}), Laplacian {} (formula {}) C/m^2", d, H - cone(d, t1), 2.0 * H / W * cd(d) * (K * t1).sqrt(), sci(lap[d as usize], 3), sci(-H / W * cd(d) / (K * t1).sqrt(), 3));
    }
    for t in [1e-3, 1.0, 10.0] {
        println!("far point x = 0.9 m, t = {} s: log10 of u in C, formula {:.4}, Simpson {:.4}", t, log10_far(0.9, t), log10_simpson(0.9, t, 4000));
    }
    println!("first omitted kink (0.5 m) at t = 10 s, relative size: e^{:.2}", -(0.4f64.powi(2) - 0.3f64.powi(2)) / (4.0 * K * 10.0));
    for t in [100.0, 1000.0] {
        println!("far point x = 0.9 m, t = {} s: kernel with images {:.6} C, sine series {:.6} C", t, u(0.9, t), series(0.9, t, 200, 0));
    }
    println!("series tail at x = 0.9 m, N = 200, t = 100 s: first omitted term below 10^{:.1} C", (4.0 * 2.0 * H / W / (201.0 * PI).powi(2)).log10() - K * (201.0 * PI).powi(2) * 100.0 / 10f64.ln());
    println!("image tail at x = 0.9 m, t = 1000 s: nearest omitted image (m = -4) below {} C", sci(2.0 * W * H * g(2.0 * 4.0 * L - 0.9 - 0.6, 1000.0), 3));
    println!("rounding width sqrt(kappa t) at t = 100 s: {:.2} cm, against 30 cm to the far point", (K * 100.0).sqrt() * 100.0);
    for t in [1e-3, 1.0, 100.0] {
        println!("terms for e^-40 damping at t = {} s: {:.0}", t, (40.0 / (K * PI * PI * t)).sqrt());
    }
    let amp = (K * (5000.0 * PI).powi(2) * t1).exp();
    println!("mistake 1, backward 1 ms: a 1e-6 C error in mode 5000 becomes {} C", sci(1e-6 * amp, 3));
    println!("mistake 2, curvature at 1 microsecond: {} C/m^2, and no finite value at t = 0", sci(uxx(0.5, 1e-6), 3));
    println!("mistake 3, 1/t per derivative predicts u_xx {} at 4 ms; true {} C/m^2", sci(rows[0].2 / 4.0, 3), sci(rows[1].2, 3));
    assert!((pk[0] - pk[1]).abs() < 1e-9 && (pk[0] - pk[2]).abs() < 1e-9 && (c2[0] - c2[1]).abs() < 1e-6 * c2[0].abs());
    assert!((ut - kuxx).abs() < 1e-3 * ut.abs() && (ut - K * c2[0]).abs() < 1e-6 * ut.abs());
    assert!((c1n - 1.0 / PI.sqrt()).abs() < 1e-9 && (c2n - 2.0 * phi(1.0)).abs() < 1e-6 && (rows[0].2 / rows[1].2 - 2.0).abs() < 1e-9);
    assert!((1..=3).all(|d| (H - cone(d, t1) - 2.0 * H / W * cd(d) * (K * t1).sqrt()).abs() < 1e-8 && (lap[d as usize] / (-H / W * cd(d) / (K * t1).sqrt()) - 1.0).abs() < 1e-5));
    assert!([1e-3, 1.0, 10.0].iter().all(|&t| (log10_far(0.9, t) - log10_simpson(0.9, t, 4000)).abs() < 1e-6));
    assert!([100.0, 1000.0].iter().all(|&t| (u(0.9, t) - series(0.9, t, 200, 0)).abs() < 1e-9));
    println!("ALL CHECKS PASS");
}
