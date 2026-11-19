// Regular curve and arc length -- the same check as the Python, in Rust.  No
// crates; sqrt, ln, cos, sin and pi are primitives, every sum and solver is here.
// A coaster's airtime hill: rail centre line y = 20 (1 - (x/30)^2) metres over
// ground positions x = -30 .. 30 m.  Its length, and its rail-metre marks.
use std::f64::consts::PI;

const H: f64 = 20.0; // hill height, metres
const W: f64 = 30.0; // half-width, metres
const K: f64 = 2.0 * H / (W * W); // slope per metre of x: 2/45

fn y(x: f64) -> f64 { H * (1.0 - (x / W).powi(2)) }
fn yp(x: f64) -> f64 { -K * x } // slope dy/dx
fn asinh(z: f64) -> f64 { (z + (1.0 + z * z).sqrt()).ln() }
fn f(x: f64) -> f64 { (K * x * (1.0 + (K * x).powi(2)).sqrt() + asinh(K * x)) / (2.0 * K) }
fn s_of_x(x: f64) -> f64 { f(x) - f(-W) } // rail metres from the left foot

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

fn speed_u(u: f64) -> f64 { // second clock u: x = 15u + 15u^3, regular
    let x = 15.0 * u + 15.0 * u.powi(3);
    (1.0 + yp(x).powi(2)).sqrt() * (15.0 + 45.0 * u * u)
}

fn x_newton(s: f64, l: f64) -> f64 { // invert s(x) by Newton: ds/dx >= 1, never 0
    let mut x = -W + 2.0 * W * s / l;
    for _ in 0..50 {
        x -= (s_of_x(x) - s) / (1.0 + yp(x).powi(2)).sqrt();
    }
    x
}

fn x_bisect(s: f64) -> f64 { // invert on the u clock by bisection
    let (mut lo, mut hi) = (-1.0, 1.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if simpson(&speed_u, -1.0, mid, 200) < s { lo = mid; } else { hi = mid; }
    }
    let u = (lo + hi) / 2.0;
    15.0 * u + 15.0 * u.powi(3)
}

fn t_unit(x: f64) -> (f64, f64) { // unit tangent, travelling left to right
    let r = (1.0 + yp(x).powi(2)).sqrt();
    (1.0 / r, yp(x) / r)
}

fn chords(n: usize) -> f64 { // road four: n straight chords
    let xs: Vec<f64> = (0..=n).map(|i| -W + 2.0 * W * i as f64 / n as f64).collect();
    (1..=n).map(|i| ((xs[i] - xs[i - 1]).powi(2) + (y(xs[i]) - y(xs[i - 1])).powi(2)).sqrt()).sum()
}

fn turn_chords(n: usize) -> f64 { // corkscrew: n chords per turn
    let pts: Vec<[f64; 3]> = (0..=n).map(|i| {
        let a = 2.0 * PI * i as f64 / n as f64;
        [3.0 * a.cos(), 3.0 * a.sin(), 12.0 * i as f64 / n as f64]
    }).collect();
    (1..=n).map(|i| (0..3).map(|c| (pts[i][c] - pts[i - 1][c]).powi(2)).sum::<f64>().sqrt()).sum()
}

fn cusp_v(t: f64) -> (f64, f64) { (2.0 * t, 3.0 * t * t) } // velocity of (t^2, t^3)
fn cusp_speed(t: f64) -> f64 { let (a, b) = cusp_v(t); (a * a + b * b).sqrt() }
fn cusp_t(t: f64) -> (f64, f64) { let (a, b) = cusp_v(t); (a / cusp_speed(t), b / cusp_speed(t)) }

fn main() {
    let l = s_of_x(W); // road one: closed form
    let l_x = simpson(&|x| (1.0 + yp(x).powi(2)).sqrt(), -W, W, 1000); // road two
    let l_u = simpson(&speed_u, -1.0, 1.0, 1000); // road three
    let (l_c1, l_c) = (chords(1024), chords(4096)); // road four: chords

    println!("hill {:.0} m high, {:.0} m of ground, y = 20(1 - (x/30)^2), slope -2x/45", H, 2.0 * W);
    println!("at the right foot: slope {:.6}, stretch sqrt(1 + 16/9) = {:.6}, ln 3 = {:.6}",
             yp(W), (1.0 + yp(W).powi(2)).sqrt(), 3f64.ln());
    println!("20/9 = {:.6}; 20/9 + ln 3 = {:.6}; 45/4 = {:.2}", (4.0 / 3.0) * (5.0 / 3.0), 20.0 / 9.0 + 3f64.ln(), 1.0 / (2.0 * K));
    println!("half hill 45/4 x (20/9 + ln 3) = {:.6} m; whole hill closed form {:.6} m, {:.2} m more than the ground",
             f(W), l, l - 2.0 * W);
    println!("Simpson on the x clock, 1000 strips: {:.6} m", l_x);
    println!("Simpson on the u clock, x = 15u + 15u^3, 1000 strips: {:.6} m", l_u);
    println!("1024 chords: {:.6} m, short by {:.3} micrometres", l_c1, (l - l_c1) * 1e6);
    println!("4096 chords: {:.6} m, short by {:.3} micrometres, {:.2} times less", l_c, (l - l_c) * 1e6, (l - l_c1) / (l - l_c));
    let chart: Vec<String> = (-3..=3).map(|i| format!("{:.2}", s_of_x(10.0 * i as f64))).collect();
    println!("chart, rail metres s at ground x = -30..30 step 10: {}", chart.join(" "));
    let mut marks: Vec<(f64, f64, f64, f64)> = Vec::new();
    let mut prev = (-W, 0.0);
    for j in 1..8 {
        let s = 10.0 * j as f64;
        let (xa, xb) = (x_newton(s, l), x_bisect(s));
        let h = 1e-3;
        let (p1, p2) = (x_newton(s + h, l), x_newton(s - h, l));
        let sp = ((p1 - p2).powi(2) + (y(p1) - y(p2)).powi(2)).sqrt() / (2.0 * h);
        let ch = ((xa - prev.0).powi(2) + (y(xa) - prev.1).powi(2)).sqrt();
        let (tx, ty) = t_unit(xa);
        println!("mark {:4.1} m: x = {:8.4} (bisection {:8.4}), height {:7.4}, T = ({:.4}, {:.4}), speed {:.6}, chord from last {:.4}",
                 s, xa, xb, y(xa), tx, ty, sp, ch);
        marks.push((xa, xb, sp, ch));
        prev = (xa, y(xa));
    }
    let gap = marks.iter().map(|m| (m.0 - m.1).abs()).fold(0.0, f64::max);
    println!("largest gap between the two inversions: {:.1} micrometres", gap * 1e6);
    let (tx, ty) = t_unit(W);
    println!("unit tangent at the right foot: ({:.6}, {:.6})", tx, ty);
    let steps: Vec<String> = (0..6)
        .map(|i| format!("{:.3}", s_of_x(-W + 10.0 * (i + 1) as f64) - s_of_x(-W + 10.0 * i as f64))).collect();
    println!("mistake 1, equal 10 m ground steps, rail in each: {}", steps.join(" "));
    let err = (1..8).map(|j| (s_of_x(-W + 2.0 * W * 10.0 * j as f64 / l) - 10.0 * j as f64).abs())
        .fold(0.0, f64::max);
    println!("mistake 2, marks spaced in proportion to ground: worst error {:.3} m of rail", err);
    let (a, b) = (cusp_t(-0.001), cusp_t(0.001));
    let cusp_len = (13f64.powf(1.5) - 8.0) / 27.0;
    let cusp_simp = simpson(&cusp_speed, 0.0, 1.0, 1000);
    println!("cusp (t^2, t^3): speed at t = 0 is {:.1}; T at t = -0.001 ({:.4}, {:.4}), at t = +0.001 ({:.4}, {:.4})",
             cusp_speed(0.0), a.0, a.1, b.0, b.1);
    println!("cusp: dt/ds at t = 0.001 is {:.1}; length t = 0..1 closed {:.6}, Simpson {:.6}",
             1.0 / cusp_speed(0.001), cusp_len, cusp_simp);
    println!("one straight rail, two clocks: (t, t) speed at 0 {:.6}; (t^3, t^3) speed at 0 {:.6}",
             (1.0f64 + 1.0).sqrt(), (2.0 * (3.0 * 0.0f64.powi(2)).powi(2)).sqrt());
    let turn = ((2.0 * PI * 3.0).powi(2) + 12.0f64.powi(2)).sqrt(); // corkscrew: closed form
    let (turn_c1, turn_c) = (turn_chords(90), turn_chords(360));
    println!("corkscrew, radius 3 m, 12 m per turn: circle part {:.4} m, {:.4} m of rail per turn", 2.0 * PI * 3.0, turn);
    println!("corkscrew chords: 90 give {:.4} m, short by {:.2} mm; 360 give {:.4} m, short by {:.2} mm",
             turn_c1, (turn - turn_c1) * 1e3, turn_c, (turn - turn_c) * 1e3);
    println!("try: 24 m per turn gives {:.2} m of rail per turn, not twice {:.4} = {:.2} m",
             ((2.0 * PI * 3.0).powi(2) + 24.0f64.powi(2)).sqrt(), turn, 2.0 * turn);
    assert!((l - l_x).abs() < 1e-9); // closed form against Simpson
    assert!((l - l_u).abs() < 1e-9); // a second clock, the same length
    assert!(l - l_c > 0.0 && l - l_c < 1e-4); // chords close in from below,
    assert!(((l - l_c1) / (l - l_c) - 16.0).abs() < 0.1); // 16 times closer for 4 times the chords
    assert!(gap < 1e-6); // two inversions agree
    assert!(marks.iter().all(|m| (m.2 - 1.0).abs() < 1e-6)); // unit speed in rail metres
    assert!(marks.iter().all(|m| m.3 > 9.9 && m.3 < 10.0)); // a chord undershoots its arc
    assert!((cusp_len - cusp_simp).abs() < 1e-9); // cusp length: closed form, Simpson
    assert!(a.0 < -0.99); // the cusp flips the tangent:
    assert!(b.0 > 0.99); // back, then forward
    assert!(turn - turn_c > 0.0 && turn - turn_c < 1e-3); // corkscrew: chords from below,
    assert!(((turn - turn_c1) / (turn - turn_c) - 16.0).abs() < 0.1); // again 16 times closer
    println!("ALL CHECKS PASS");
}
