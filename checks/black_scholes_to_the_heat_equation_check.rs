// Black-Scholes is the heat equation after a change of variables -- the same
// check as the Python, in Rust.  No crates.  A 3-month call on a 100 share is
// turned into a rod: log price, time to expiry in heat units, and one
// exponential factor.  The price is then found three ways: the Black-Scholes
// formula, the heat kernel by quadrature, and an explicit grid on the plain
// heat equation.
use std::f64::consts::PI;

const S: f64 = 100.0;
const K: f64 = 100.0;
const T: f64 = 0.25;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const KAPPA: f64 = 1.11e-4; // copper diffusivity, m^2/s
const HALF_M: f64 = 0.5; // metres per log unit
const LQ: f64 = 1.5; // quadrature reach either side of x, in log units

fn fe(v: f64, d: usize) -> String { // e-notation with the same digits in Python and Rust
    if v == 0.0 { return format!("0.{}e0", "0".repeat(d)); }
    let (mut m, mut e) = (v.abs(), 0);
    while m >= 10.0 { m /= 10.0; e += 1; }
    while m < 1.0 { m *= 10.0; e -= 1; }
    format!("{}{:.*}e{}", if v < 0.0 { "-" } else { "" }, d, m, e)
}

fn ncdf(z: f64) -> f64 { // normal CDF by its all-positive series
    let (mut term, mut total, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        n += 1.0;
        term *= z * z / (2.0 * n + 1.0);
        total += term;
    }
    0.5 + (-z * z / 2.0).exp() / (2.0 * PI).sqrt() * total
}

struct P { tau: f64, x0: f64, c1: f64, c2: f64, al: f64 }

fn u0(p: &P, x: f64) -> f64 { // the payoff in strikes, with the factor divided out
    (-p.al * x).exp() * (x.exp() - 1.0).max(0.0)
}

fn heat_exp(c: f64, x: f64, t: f64) -> f64 { // e^(cy) for y > 0, run through the heat kernel
    (c * x + c * c * t).exp() * ncdf((x + 2.0 * c * t) / (2.0 * t).sqrt())
}

fn u_exact(p: &P, x: f64, t: f64) -> f64 { heat_exp(p.c1, x, t) - heat_exp(p.c2, x, t) }

fn bs_call(s: f64, t: f64) -> (f64, f64, f64) { // road 1: the Black-Scholes formula
    let d1 = ((s / K).ln() + (R - Q + SIG * SIG / 2.0) * t) / (SIG * t.sqrt());
    let d2 = d1 - SIG * t.sqrt();
    (s * (-Q * t).exp() * ncdf(d1) - K * (-R * t).exp() * ncdf(d2), d1, d2)
}

fn kernel_conv(p: &P, x: f64, t: f64) -> f64 { // road 2: Simpson's rule on u0 times the kernel
    let (l, n) = (LQ, 3000);
    let (a, b) = ((x - l).max(0.0), x + l);
    let h = (b - a) / n as f64;
    let f = |y: f64| u0(p, y) * (-(x - y).powi(2) / (4.0 * t)).exp() / (4.0 * PI * t).sqrt();
    let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (f(a) + f(b) + acc) * h / 3.0
}

fn grid(p: &P, h: f64) -> (f64, usize) { // road 3: explicit steps of u_tau = u_xx
    let (nu, xl, xr) = (0.4, -1.0, 1.0);
    let m = ((xr - xl) / h).round() as usize;
    let dt = nu * h * h;
    let steps = (p.tau / dt).round() as usize;
    let mut u: Vec<f64> = (0..=m).map(|i| u0(p, xl + i as f64 * h)).collect();
    for k in 1..=steps {
        let mut new = vec![0.0; m + 1];
        for i in 1..m { new[i] = u[i] + nu * (u[i + 1] - 2.0 * u[i] + u[i - 1]); }
        let t = k as f64 * dt; // far right: both exponentials run exactly
        new[m] = (p.c1 * xr + p.c1 * p.c1 * t).exp() - (p.c2 * xr + p.c2 * p.c2 * t).exp();
        u = new;
    }
    (u[((p.x0 - xl) / h).round() as usize], steps)
}

fn main() {
    let kq = 2.0 * (R - Q) / (SIG * SIG); // drift and discount, in heat units
    let kr = 2.0 * R / (SIG * SIG);
    let al = -(kq - 1.0) / 2.0; // the exponential factor's slope in x
    let be = -(kq - 1.0).powi(2) / 4.0 - kr; // and its rate in tau
    let p = P { tau: SIG * SIG * T / 2.0, x0: (S / K).ln(), c1: (kq + 1.0) / 2.0, c2: (kq - 1.0) / 2.0, al };
    let tau = p.tau;
    let (v1, d1, d2) = bs_call(S, T);
    let uq = kernel_conv(&p, p.x0, tau);
    let v2 = K * (al * p.x0 + be * tau).exp() * uq;
    let xa = 0.1; // a second price, off the strike: S = K e^0.1
    let (va1, va2) = (bs_call(K * f64::exp(xa), T).0, K * (al * xa + be * tau).exp() * kernel_conv(&p, xa, tau));
    let uh = u_exact(&p, p.x0, tau);
    let (g1, n1) = grid(&p, 0.01);
    let (g2, n2) = grid(&p, 0.005);
    let (e1, e2) = ((g1 - uh).abs(), (g2 - uh).abs());
    let zt = (LQ - 2.0 * p.c1 * tau) / (2.0 * tau).sqrt();
    let tail = (p.c1 * p.c1 * tau).exp() * (-zt * zt / 2.0).exp() / ((2.0 * PI).sqrt() * zt);
    let t_rod = tau * HALF_M * HALF_M / KAPPA;
    let disc = (be * tau).exp();

    println!("call: S {:.2}, K {:.2}, T {:.2} yr, r {:.2}, q {:.2}, sigma {:.2}", S, K, T, R, Q, SIG);
    println!("heat-unit rates: drift k' = {:.4}, discount k = {:.4}", kq, kr);
    println!("factor e^(alpha x + beta tau): alpha = {:.4}, beta = {:.4}", al, be);
    println!("heat clock tau = sigma^2 T / 2 = {:.4}; x = ln(S/K) = {:.4}", tau, p.x0);
    println!("start: u0(x) = e^({:.2} x) - e^({:.2} x) for x > 0, else 0", p.c1, p.c2);
    println!("d1 = {:.6}, d2 = {:.6}, N(d1) = {:.6}, N(d2) = {:.6}", d1, d2, ncdf(d1), ncdf(d2));
    println!("heat terms: e^(c1^2 tau) = {:.6}, e^(c2^2 tau) = {:.6}",
             (p.c1 * p.c1 * tau).exp(), (p.c2 * p.c2 * tau).exp());
    println!("u(0, tau), closed form       = {:.6}", uh);
    println!("u(0, tau), kernel quadrature = {:.6}  (tail past {} below {})", uq, LQ, fe(tail, 2));
    println!("discount e^(beta tau)        = {:.6}", disc);
    println!("road 1, Black-Scholes formula: {:.6}", v1);
    println!("road 2, heat kernel, times K e^(beta tau): {:.6}", v2);
    println!("roads 1 and 2 off the strike, S {:.2} (x = {:.1}): {:.6} and {:.6}  (tail below {})", K * f64::exp(xa), xa, va1, va2, fe((p.c1 * xa).exp() * tail, 2));
    println!("road 3, grid h 0.010, {} steps: {:.6}  error in u {}", n1, K * disc * g1, fe(e1, 2));
    println!("road 3, grid h 0.005, {} steps: {:.6}  error in u {}", n2, K * disc * g2, fe(e2, 2));
    println!("grid observed order: {:.2}", (e1 / e2).ln() / 2f64.ln());
    let mut res = 0.0;
    for dx in [0.002, 0.001] { // the residual u_tau - u_xx, by centred differences
        let dt = dx * dx / 4.0;
        res = (u_exact(&p, 0.05, tau + dt) - u_exact(&p, 0.05, tau - dt)) / (2.0 * dt)
            - (u_exact(&p, 0.05 + dx, tau) - 2.0 * u_exact(&p, 0.05, tau) + u_exact(&p, 0.05 - dx, tau)) / (dx * dx);
        println!("residual u_tau - u_xx at x 0.05, step {:.3}: {}", dx, fe(res, 2));
    }
    println!("rod: 1 m holds x from -1 to 1; copper kappa {} m^2/s", fe(KAPPA, 2));
    println!("rod time for tau: {:.2} s; spread sqrt(2 tau) = {:.4} log units = {:.2} cm",
             t_rod, (2.0 * tau).sqrt(), 100.0 * HALF_M * (2.0 * tau).sqrt());
    for x in [-0.3, -0.2, -0.1, 0.0, 0.1, 0.2, 0.3] {
        println!("chart, x {:+.1}, S {:.2}: start {:.4}, at tau {:.4}", x, K * f64::exp(x), u0(&p, x), u_exact(&p, x, tau));
    }
    let w1 = K * (be * T).exp() * u_exact(&p, p.x0, T); // mistake: years on the heat clock
    let w2 = K * uh; // mistake: drop e^(beta tau)
    let w3 = K * disc * (heat_exp(1.0 + al, p.x0, tau) - heat_exp(al, p.x0, tau)); // alpha flipped
    let amp = 1e-6 * (100.0f64.powi(2) * tau).exp();
    println!("mistake 1, years on the heat clock (tau = 0.25): {:.6}", w1);
    println!("mistake 2, drop the factor e^(beta tau): {:.6}", w2);
    println!("mistake 3, alpha's sign flipped in the start: {:.6}", w3);
    println!("mistake 4, calendar time kept: a 1e-6 ripple at mode 100 grows to {}", fe(amp, 2));
    assert!((v1 - v2).abs() < 1e-9); // formula against kernel quadrature
    assert!(e2 < 1e-4 && 3.5 < e1 / e2 && e1 / e2 < 4.5); // grid converges at second order
    assert!((uq - uh).abs() < 1e-10); // quadrature against completed square
    assert!((va1 - va2).abs() < 1e-9); // and off the strike, where e^(alpha x) is not 1
    assert!(res.abs() < 1e-4); // the closed form solves the heat equation
    assert!((w2 - v1).abs() > 0.05 && (w1 - v1).abs() > 1.0); // the mistakes really move the price
    println!("ALL CHECKS PASS");
}
