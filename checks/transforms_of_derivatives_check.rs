// Transforming a derivative -- the same check as the Python, in Rust.  No
// crates.  The car body: y'' + 2y' + 5y = 0, released from 1 cm at rest.
// Road one steps the motion with Runge-Kutta 4 and adds up e^(-st) times the
// height, velocity and acceleration as it goes, never using the rule.  Road two
// is the rule: multiply by s, subtract the starting values, solve for Y.
const Y0: f64 = 1.0; const V0: f64 = 0.0; const T_END: f64 = 30.0;

fn acc(y: f64, v: f64) -> f64 { -2.0 * v - 5.0 * y }       // the rate law, per unit mass

fn f(s: f64, t: f64, u: &[f64; 5]) -> [f64; 5] {
    let w = (-s * t).exp();
    [u[1], acc(u[0], u[1]), w * u[0], w * u[1], w * acc(u[0], u[1])]
}

fn step(u: &[f64; 5], k: &[f64; 5], c: f64) -> [f64; 5] {
    let mut out = *u;
    for i in 0..5 { out[i] += c * k[i] }
    out
}

fn road_one(s: f64, h: f64) -> ([f64; 5], Vec<[f64; 5]>) { // totals every 0.5 s of cutoff
    let (mut u, mut marks) = ([Y0, V0, 0.0, 0.0, 0.0], Vec::new());
    let every = (0.5 / h).round() as usize;
    for n in 0..(T_END / h).round() as usize {
        if n % every == 0 { marks.push(u) }
        let t = n as f64 * h;
        let k1 = f(s, t, &u);
        let k2 = f(s, t + h / 2.0, &step(&u, &k1, h / 2.0));
        let k3 = f(s, t + h / 2.0, &step(&u, &k2, h / 2.0));
        let k4 = f(s, t + h, &step(&u, &k3, h));
        for i in 0..5 { u[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) }
    }
    (u, marks)
}

fn road_two(s: f64) -> f64 { (s * Y0 + V0 + 2.0 * Y0) / (s * s + 2.0 * s + 5.0) }

fn sci(x: f64) -> String {                                   // 1.8e-07, as Python prints it
    let t = format!("{:.1e}", x);
    let (m, e) = t.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn main() {
    let mut errs: Vec<f64> = Vec::new();
    for s in [2.0_f64, 0.0] {
        let y = road_two(s);
        println!("s = {}: rule and algebra give Y = {:.6}, sY - y(0) = {:.6}, s^2 Y - s y(0) - y'(0) = {:.6}",
                 s, y, s * y - Y0, s * s * y - s * Y0 - V0);
        let mut last = [0.0; 5];
        for h in [0.05_f64, 0.025] {
            last = road_one(s, h).0;
            errs.push((last[2] - y).abs());
            println!("  RK4 h = {}: L[y] = {:.6}, L[y'] = {:.6}, L[y''] = {:.6}, error in Y {}",
                     h, last[2], last[3], last[4], sci(errs[errs.len() - 1]));
        }
        let (i0, i1, i2) = (last[2], last[3], last[4]);
        assert!((i0 - y).abs() < 1e-6);                              // stepped motion = algebra
        assert!((i1 - (s * i0 - Y0)).abs() < 1e-6 && (i2 - (s * s * i0 - s * Y0 - V0)).abs() < 1e-6);
        println!("  transformed equation L[y''] + 2 L[y'] + 5 L[y] = {}", sci(i2 + 2.0 * i1 + 5.0 * i0));
    }
    let r1 = errs[0] / errs[1];
    println!("error ratio at s = 2, h halved: {:.1}, near 2^4 = 16 for order 4", r1);
    assert!(12.0 < r1 && r1 < 20.0);                                 // RK4's order, seen in the run
    let marks = road_one(2.0, 0.025).1;
    let m = marks[1];                                                // the totals at cutoff R = 0.5 s
    println!("cutoff R = 0.5: J = {:.6}, sI - y(0) = {:.6}, end term e^(-sR) y(R) = {:.6}",
             m[3], 2.0 * m[2] - Y0, (-1.0_f64).exp() * m[0]);
    let row = |v: Vec<f64>| v.iter().map(|x| format!("{:5.2}", x)).collect::<Vec<_>>().join(" ");
    println!("figure, R      {}", row((0..7).map(|k| 0.5 * k as f64).collect()));
    println!("figure, J_R    {}", row(marks[..7].iter().map(|mk| mk[3]).collect()));
    println!("figure, sI_R-1 {}", row(marks[..7].iter().map(|mk| 2.0 * mk[2] - Y0).collect()));
    println!("mistake 1, drop y(0): sY = {:.6}, and (s^2+2s+5)Y = 0 forces Y = 0", 2.0 * road_two(2.0));
    println!("mistake 2, drop the s on y(0): Y = {:.6} instead of {:.6}", (Y0 + V0 + 2.0 * Y0) / 13.0, road_two(2.0));
    let big_f: f64 = (0..29000).map(|k| 0.001 * (-2.0 * (1.0 + (k as f64 + 0.5) * 0.001)).exp()).sum();
    println!("mistake 3, step at t = 1: L[f'] = 0 but sF - f(0) = {:.6}", 2.0 * big_f);
    assert!((2.0 * big_f - (-2.0_f64).exp()).abs() < 1e-6);          // midpoint sum vs e^(-2)
    println!("ALL CHECKS PASS");
}
