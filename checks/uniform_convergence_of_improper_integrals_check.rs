// Uniform convergence of improper integrals -- the same check as the Python, in
// Rust.  No crates; exp, sin, atan, ln and pi come from std, and every integral
// is the script's own Simpson sum.  Road one integrates directly; road two takes
// the derivative through the integral sign; road three is the closed form.
use std::f64::consts::PI;
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {   // parabolas through equal steps
    let w = (b - a) / m as f64;
    let s: f64 = (0..=m).map(|i| (if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 })
        * g(a + i as f64 * w)).sum();
    w / 3.0 * s
}
fn area(n: i32, t: f64, a: f64, b: f64) -> f64 { simpson(&|x: f64| x.powi(n) * (-t * x).exp(), a, b, 6000) }
fn sinc(x: f64) -> f64 { if x == 0.0 { 1.0 } else { x.sin() / x } }
fn dirichlet(t: f64) -> f64 { simpson(&|x: f64| (-t * x).exp() * sinc(x), 0.0, 60.0 / t, (6000.0 / t) as usize) }
fn cap_tail(b: f64) -> f64 { (-b).exp() * (b.powi(3) + 3.0 * b * b + 6.0 * b + 6.0) }  // x^3 e^(-x) beyond B
fn drip(t: f64, b: f64) -> f64 { simpson(&|x: f64| t * (-t * x).exp(), b, b + 60.0 / t, 6000) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (a1, a2) = (area(3, 1.0, 0.0, 60.0), area(3, 2.0, 0.0, 60.0));
    println!("x^3 e^(-tx) on [0, 60]: t=1 Simpson {:.6}, 6/t^4 {:.6}; t=2 Simpson {:.6}, 6/t^4 {:.6}", a1, 6.0, a2, 6.0 / 16.0);
    let caps: Vec<f64> = (1..=3).map(|n| area(n, 1.0, 0.0, 60.0)).collect();
    println!("caps for t >= 1: area of x e^(-x), x^2 e^(-x), x^3 e^(-x): {}", join(&caps, 6));
    let h = 1e-4;
    let dq = (area(2, 1.5 + h, 0.0, 60.0) - area(2, 1.5 - h, 0.0, 60.0)) / (2.0 * h);
    println!("slope of the x^2 integral at t=1.5 by difference quotient {:.6}; minus the x^3 integral {:.6}; -6/t^4 {:.6}",
             dq, -area(3, 1.5, 0.0, 60.0), -6.0 / 1.5f64.powi(4));
    let grid: Vec<f64> = (0..9).map(|k| 1.0 + k as f64 / 2.0).collect();
    let tails: Vec<f64> = grid.iter().map(|&t| area(3, t, 20.0, 100.0)).collect();
    let mut iw = 0;
    for i in 0..tails.len() { if tails[i] > tails[iw] { iw = i } }
    let worst = tails[iw];
    println!("tail beyond B=20, worst over t = 1, 1.5, ..., 5: {:.7} at t={:.2}; cap's tail {:.7}", worst, grid[iw], cap_tail(20.0));
    let bs: Vec<f64> = (0..9).map(|k| 5.0 * k as f64).collect();
    let capped: Vec<f64> = bs.iter().map(|&b| [1.0, 2.0, 4.0].iter().map(|&t| area(3, t, b, b + 80.0)).fold(f64::MIN, f64::max)).collect();
    let ts: Vec<f64> = (0..7).map(|k| 10f64.powi(-k)).collect();
    let uncapped: Vec<f64> = bs.iter().map(|&b| ts.iter().map(|&t| drip(t, b)).fold(f64::MIN, f64::max)).collect();
    println!("chart capped:   {}", join(&capped, 2));
    println!("chart uncapped: {}", join(&uncapped, 2));
    println!("tail beyond B=100 of t e^(-tx) at t=0.1, 0.01, 0.001: {}", join(&[drip(0.1, 100.0), drip(0.01, 100.0), drip(0.001, 100.0)], 6));
    let whole = simpson(&|x: f64| 0.001 * (-0.001 * x).exp(), 0.0, 60000.0, 6000);
    println!("integral of t e^(-tx) at t=0.001: {:.6}; at t=0 the integrand is 0, integral 0", whole);
    let (d1, d01) = (dirichlet(1.0), dirichlet(0.1));
    println!("I(t) = integral of e^(-tx) sin x / x: t=1 Simpson {:.6}, pi/2 - arctan t {:.6}", d1, PI / 2.0 - 1f64.atan());
    println!("  t=0.1 Simpson {:.6}, pi/2 - arctan t {:.6}", d01, PI / 2.0 - 0.1f64.atan());
    let di = (dirichlet(1.0 + h) - dirichlet(1.0 - h)) / (2.0 * h);
    let inside = simpson(&|x: f64| -(-x).exp() * x.sin(), 0.0, 60.0, 6000);
    println!("I'(1) by difference quotient {:.6}; integral of -e^(-x) sin x {:.6}; -1/(1+t^2) {:.6}", di, inside, -0.5);
    let bb = [10.0, 100.0, 1000.0];
    let si: Vec<f64> = bb.iter().map(|&b| simpson(&sinc, 0.0, b, 100 * b as usize)).collect();
    println!("t=0: integral of sin x / x up to B = 10, 100, 1000: {}", join(&si, 6));
    let miss: Vec<f64> = si.iter().map(|v| (PI / 2.0 - v).abs()).collect();
    println!("  miss from pi/2: {}; bound 2/B: 0.200000 0.020000 0.002000", join(&miss, 6));
    let ab: Vec<f64> = [10usize, 100, 1000].iter().map(|&n| simpson(&|x: f64| sinc(x).abs(), 0.0, n as f64 * PI, 200 * n)).collect();
    println!("no cap at t=0: integral of |sin x|/x up to 10pi, 100pi, 1000pi: {}", join(&ab, 6));
    println!("mistakes: constant dropped, I(0) = -arctan 0 = 0, not {:.6}; cap x^3 for t >= 0 has no area, and 6/t^4 at t=0.1 is {:.0}",
             PI / 2.0, 6.0 / 0.1f64.powi(4));
    let gam = |s: f64| simpson(&|u: f64| 2.0 * u.powf(2.0 * s - 1.0) * (-u * u).exp(), 0.0, 10.0, 20000);  // x = u^2
    let dg = (gam(1.0 + h) - gam(1.0 - h)) / (2.0 * h);
    let lnin = simpson(&|u: f64| if u > 0.0 { 4.0 * u * u.ln() * (-u * u).exp() } else { 0.0 }, 0.0, 10.0, 20000);
    println!("gamma'(1) by difference quotient {:.6}; integral of ln x e^(-x) {:.6}; minus Euler's constant -0.577216", dg, lnin);
    let (cap0, cap1) = (simpson(&|u: f64| if u > 0.0 { -16.0 * u * u.ln() } else { 0.0 }, 0.0, 1.0, 6000),
                        simpson(&|x: f64| x * x.ln() * (-x).exp(), 1.0, 60.0, 6000));   // x = u^4 near 0
    println!("caps on gamma's s-rate, s from 1/2 to 2: x^(-1/2)|ln x| on (0, 1], area {:.6}; x ln x e^(-x) beyond 1, area {:.6}", cap0, cap1);
    assert!((dg - lnin).abs() < 1e-6 && (lnin + 0.5772156649).abs() < 1e-6);     // gamma: slope inside
    assert!((cap0 - 4.0).abs() < 1e-6 && (cap1 - (-1f64).exp() - simpson(&|x: f64| (-x).exp() / x, 1.0, 60.0, 6000)).abs() < 1e-6);  // caps: by hand; by parts
    assert!((a1 - 6.0).abs() < 1e-6 && (a2 - 6.0 / 16.0).abs() < 1e-6);         // direct vs 6/t^4
    assert!((dq + area(3, 1.5, 0.0, 60.0)).abs() < 1e-5 && (dq + 6.0 / 1.5f64.powi(4)).abs() < 1e-5);
    assert!(iw == 0 && (worst - cap_tail(20.0)).abs() < 1e-9);                   // the cap bounds every tail
    assert!((d1 - PI / 4.0).abs() < 1e-6 && (d01 - (PI / 2.0 - 0.1f64.atan())).abs() < 1e-6 && (di + 0.5).abs() < 1e-5);
    assert!(si.iter().zip(bb.iter()).all(|(v, b)| (PI / 2.0 - v).abs() <= 2.0 / b)); // the uniform tail bound
    assert!(uncapped.iter().cloned().fold(f64::MAX, f64::min) > 0.99 && capped[8] < 1e-9 && ab[2] - ab[1] > 1.4);
    println!("ALL CHECKS PASS");
}
