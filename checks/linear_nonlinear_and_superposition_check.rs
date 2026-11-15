// Linear or not -- the same check as the Python, in Rust, std only.
// Plate: u_t = KAPPA (u_xx + u_yy) on a 1 m square, edges held at the frame's
// 20 C, u = temperature above the frame.  Burgers: u_t + u u_x = 0, u in m/s.
// Roads: closed forms; an explicit grid; residuals by centred differences;
// characteristics by bisection; a probe test that grades an equation.
use std::f64::consts::PI;

const KAPPA: f64 = 1.2e-5; // m^2/s (illustrative)
const HOUR: f64 = 3600.0;
const X0: f64 = 0.25;
const Y0: f64 = 0.5;

fn mode(amp: f64, m: f64, n: f64, x: f64, y: f64, t: f64) -> f64 {
    amp * (m * PI * x).sin() * (n * PI * y).sin() * (-(m * m + n * n) * PI * PI * KAPPA * t).exp()
}
fn ua(x: f64, y: f64, t: f64) -> f64 { mode(30.0, 1.0, 1.0, x, y, t) } // warm middle, 30 C up
fn ub(x: f64, y: f64, t: f64) -> f64 { mode(10.0, 2.0, 1.0, x, y, t) } // left half up, right half down
fn us(x: f64, y: f64, t: f64) -> f64 { ua(x, y, t) + ub(x, y, t) } // the sum

fn heat_res(f: fn(f64, f64, f64) -> f64, x: f64, y: f64, t: f64, h: f64, k: f64) -> f64 {
    let ut = (f(x, y, t + k) - f(x, y, t - k)) / (2.0 * k);
    let lap = (f(x + h, y, t) + f(x - h, y, t) + f(x, y + h, t) + f(x, y - h, t) - 4.0 * f(x, y, t)) / h.powi(2);
    ut - KAPPA * lap
}

fn grid(n: usize, dt: f64) -> f64 { // explicit scheme from the summed start
    let h = 1.0 / n as f64;
    let mut u = vec![vec![0.0; n + 1]; n + 1];
    for i in 1..n { for j in 1..n { u[i][j] = us(i as f64 * h, j as f64 * h, 0.0); } }
    let r = KAPPA * dt / h.powi(2);
    assert!(r <= 0.25); // stability limit of the scheme
    for _ in 0..(HOUR / dt).round() as usize {
        let mut v = u.clone();
        for i in 1..n {
            for j in 1..n {
                v[i][j] = u[i][j] + r * (u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] - 4.0 * u[i][j]);
            }
        }
        u = v;
    }
    u[(X0 * n as f64).round() as usize][(Y0 * n as f64).round() as usize]
}

fn sci(v: f64, d: usize) -> String { // Python's e-format: two-digit exponent
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_at(s.find('e').unwrap());
    let e: i32 = e[1..].parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn z(v: f64) -> f64 { if v.abs() < 0.005 { 0.0 } else { v } } // print a rounding speck at an edge as 0

fn v1(x: f64, t: f64) -> f64 { x / (1.0 + t) } // cloud that left x = 0 one second ago
fn v2(x: f64, t: f64) -> f64 { x / (0.5 + t) } // cloud that left half a second ago
fn vs(x: f64, t: f64) -> f64 { v1(x, t) + v2(x, t) }
fn v1x2(x: f64, t: f64) -> f64 { 2.0 * v1(x, t) }
fn burg_res(f: fn(f64, f64) -> f64, x: f64, t: f64, h: f64) -> f64 {
    (f(x, t + h) - f(x, t - h)) / (2.0 * h) + f(x, t) * (f(x + h, t) - f(x - h, t)) / (2.0 * h)
}
fn charac(u0: &dyn Fn(f64) -> f64, x: f64, t: f64) -> f64 { // solve x = x0 + u0(x0) t by bisection
    let (mut lo, mut hi) = (-100.0, 100.0);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if mid + u0(mid) * t < x { lo = mid } else { hi = mid }
    }
    u0((lo + hi) / 2.0)
}

// Grade by probing F(u, u_x, u_y, u_xx, u_xy, u_yy) at fixed jets; y is time in an evolution
// equation; constants are 1 (a grade depends on where u sits).  Order 1: top = (u_x, u_y).
type Op = fn(&[f64; 6]) -> f64;
const P: [[f64; 6]; 3] = [[1.0, 2.0, -1.0, 3.0, 1.0, -2.0], [-2.0, 1.0, 3.0, -1.0, 2.0, 1.0], [2.0, -3.0, 1.0, 1.0, -1.0, 2.0]];
fn lin(g: &dyn Fn(&[f64; 6]) -> f64) -> bool { // g additive and 3g(p) = g(3p)?
    P.iter().all(|p| P.iter().all(|q| {
        let mut s = [0.0; 6];
        let mut t = [0.0; 6];
        for i in 0..6 { s[i] = p[i] + q[i]; t[i] = 3.0 * p[i]; }
        (g(&s) - g(p) - g(q)).abs() < 1e-9 && (g(&t) - 3.0 * g(p)).abs() < 1e-9
    }))
}
fn grade(k: usize, f: Op) -> &'static str {
    let top: Vec<usize> = if k == 1 { vec![1, 2] } else { vec![3, 4, 5] };
    let split = |l: &[f64; 6], t: &[f64; 6]| {
        let mut j = [0.0; 6];
        for i in 0..6 { j[i] = if top.contains(&i) { t[i] } else if i < top[0] { l[i] } else { 0.0 }; }
        j
    };
    let d = |l: &[f64; 6], t: &[f64; 6]| f(&split(l, t)) - f(&split(l, &[0.0; 6]));
    if lin(&|j| f(j) - f(&[0.0; 6])) { return "linear"; }
    if !P.iter().all(|l| lin(&|t| d(l, t))) { return "fully nonlinear"; }
    let same = P.iter().all(|l| P.iter().all(|t| (d(l, t) - d(&P[0], t)).abs() < 1e-9));
    if same { "semilinear" } else { "quasilinear" }
}

fn main() {
    let (a0, b0, a1, b1) = (ua(X0, Y0, 0.0), ub(X0, Y0, 0.0), ua(X0, Y0, HOUR), ub(X0, Y0, HOUR));
    let s1 = a1 + b1;
    println!("plate start at (0.25 m, 0.5 m): A {:.2} C, B {:.2} C, sum {:.2} C", a0, b0, a0 + b0);
    println!("plate after 1 h: A {:.2} C, B {:.2} C, sum {:.2} C", a1, b1, s1);
    let (ea, eb) = (2.0 * PI * PI * KAPPA * HOUR, 5.0 * PI * PI * KAPPA * HOUR);
    println!("time constants: A {:.0} s ({:.1} min), B {:.0} s ({:.1} min)", HOUR / ea, HOUR / ea / 60.0, HOUR / eb, HOUR / eb / 60.0);
    println!("by hand: sin(pi/4) {:.4}; exponents {:.4} and {:.4}; factors {:.4} and {:.4}", (PI / 4.0).sin(), ea, eb, (-ea).exp(), (-eb).exp());
    let ut = (us(X0, Y0, HOUR + 10.0) - us(X0, Y0, HOUR - 10.0)) / 20.0;
    println!("rate of change of the sum after 1 h: {} C/s", sci(ut, 3));
    let rs = [heat_res(us, X0, Y0, HOUR, 0.02, 10.0), heat_res(us, X0, Y0, HOUR, 0.01, 10.0)];
    println!("residual of the sum, h = 0.02 m and 0.01 m: {} and {} C/s, ratio {:.1}", sci(rs[0], 1), sci(rs[1], 1), rs[0] / rs[1]);
    assert!(rs[0].abs() < 1e-3 * ut.abs() && 3.5 < rs[0] / rs[1] && rs[0] / rs[1] < 4.5); // step error only: falls as h^2
    let (g1, g2) = (grid(20, 40.0), grid(40, 10.0));
    println!("grid from the summed start: h = 0.05 m {:.3} C, h = 0.025 m {:.3} C, exact {:.3} C", g1, g2, s1);
    println!("grid errors {:.4} C and {:.4} C, ratio {:.1}", g1 - s1, g2 - s1, (g1 - s1) / (g2 - s1));
    assert!((g1 - s1).abs() < 0.05 && (g2 - s1).abs() < 0.015);
    let frame = (20.0 + a1) + (20.0 + b1);
    println!("mistake, add whole temperatures: {:.2} C, right: {:.2} C", frame, 20.0 + s1);
    for i in 0..11 {
        let x = i as f64 / 10.0;
        println!("chart, x = {:.1} m, A {:.2}, B {:.2}, sum {:.2}", x, z(ua(x, Y0, HOUR)), z(ub(x, Y0, HOUR)), z(us(x, Y0, HOUR)));
    }

    println!("Burgers flows at (1 m, 1 s): v1 {:.4} m/s, v2 {:.4} m/s", v1(1.0, 1.0), v2(1.0, 1.0));
    let (xi, ti): (i64, i64) = (1, 1); // the point (1 m, 1 s), in whole units
    let (cn, cd) = (4 * xi, (1 + ti) * (1 + 2 * ti)); // (v1 v2)_x = 2x/((1+t)(0.5+t)) = 4x/((1+t)(1+2t))
    for h in [1e-2, 1e-3] {
        println!("Burgers residual of v1 + v2 at (1 m, 1 s), h = {}: {:.4} m/s^2", h, burg_res(vs, 1.0, 1.0, h));
        assert!(burg_res(v1, 1.0, 1.0, h).abs() < 1e-4 && burg_res(v2, 1.0, 1.0, h).abs() < 1e-4);
        assert!((burg_res(vs, 1.0, 1.0, h) - cn as f64 / cd as f64).abs() < 1e-3); // the sum's residual is the cross term
    }
    let gg = gcd(cn, cd);
    println!("cross term (v1 v2)_x at (1 m, 1 s): {}/{} m/s^2", cn / gg, cd / gg);
    let truth = charac(&|x| 3.0 * x, 1.0, 1.0);
    println!("flow from the summed start at (1 m, 1 s): {:.4} m/s; v1 + v2 gives {:.4} m/s", truth, vs(1.0, 1.0));
    assert!((truth - 3.0 / (1.0 + 3.0 * 1.0)).abs() < 1e-9);
    let dbl = charac(&|x| 2.0 * x, 1.0, 1.0);
    println!("flow from the doubled start: {:.4} m/s; 2 v1 gives {:.4} m/s", dbl, 2.0 * v1(1.0, 1.0));
    assert!((dbl - 2.0 / (1.0 + 2.0 * 1.0)).abs() < 1e-9);
    println!("Burgers residual of 2 v1 at (1 m, 1 s): {:.4} m/s^2", burg_res(v1x2, 1.0, 1.0, 1e-3));

    let eqs: [(&str, usize, Op, &str); 8] = [
        ("heat u_t = u_xx", 2, |j| j[2] - j[3], "linear"),
        ("heat with a torch, source 5", 2, |j| j[2] - j[3] - 5.0, "linear"),
        ("heat with radiation u^4", 2, |j| j[2] - j[3] + j[0].powi(4), "semilinear"),
        ("viscous Burgers", 2, |j| j[2] + j[0] * j[1] - j[3], "semilinear"),
        ("conductivity 1 - u", 2, |j| j[2] - (1.0 - j[0]) * j[3] + j[1].powi(2), "quasilinear"),
        ("Burgers u_t + u u_x", 1, |j| j[2] + j[0] * j[1], "quasilinear"),
        ("eikonal u_x^2 + u_y^2 = 1", 1, |j| j[1].powi(2) + j[2].powi(2) - 1.0, "fully nonlinear"),
        ("Monge-Ampere u_xx u_yy - u_xy^2 = 1", 2, |j| j[3] * j[5] - j[4].powi(2) - 1.0, "fully nonlinear"),
    ];
    for (name, k, f, want) in eqs {
        let g = grade(k, f);
        println!("grade: {}: {}", name, g);
        assert_eq!(g, want);
    }
    println!("ALL CHECKS PASS");
}
