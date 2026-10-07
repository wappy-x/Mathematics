// Trace and determinant -- the same check as the Python, in Rust.  No crates.  Four
// systems x' = Ax are classified twice: road one reads trace and determinant off the
// chart; road two steps the motion with Euler's rule from eight starts and watches it.
use std::f64::consts::PI;
type M = [[i64; 2]; 2];
const STARTS: [(f64, f64); 8] = [(1.0, 0.0), (1.0, 1.0), (0.0, 1.0), (-1.0, 1.0), (-1.0, 0.0), (-1.0, -1.0), (0.0, -1.0), (1.0, -1.0)];

fn eig(t: i64, d: i64) -> (f64, f64, f64) {            // roots of L^2 - tL + d = 0
    let (tf, q) = (t as f64, (t * t - 4 * d) as f64);
    if q >= 0.0 { ((tf + q.sqrt()) / 2.0, (tf - q.sqrt()) / 2.0, 0.0) } else { (tf / 2.0, tf / 2.0, (-q).sqrt() / 2.0) }
}
fn chart(t: i64, d: i64) -> (String, &'static str) {  // road one: where (trace, det) sits
    if d < 0 { return ("saddle".into(), "unstable") }
    if t == 0 { return ("centre".into(), "stable, not asymptotically stable") }
    let shape = if t * t - 4 * d < 0 { "spiral" } else { "node" };
    if t < 0 { (format!("stable {}", shape), "asymptotically stable") } else { (format!("unstable {}", shape), "unstable") }
}
fn euler(a: &M, mut x: f64, mut y: f64, h: f64, n: usize) -> (f64, f64) {   // n small steps along the slope
    let [[p, q], [r, s]] = a.map(|row| row.map(|v| v as f64));
    for _ in 0..n { (x, y) = (x + h * (p * x + q * y), y + h * (r * x + s * y)) }
    (x, y)
}
fn motion(a: &M) -> (usize, usize, usize, usize, String) {   // road two: eight starts, 6 time units
    let (h, n) = (0.001, 6000);
    let ratios: Vec<f64> = STARTS.iter().map(|&(x, y)| { let (u, v) = euler(a, x, y, h, n); (u * u + v * v).sqrt() / (x * x + y * y).sqrt() }).collect();
    let shrink = ratios.iter().filter(|&&r| r < 0.5).count();
    let grow = ratios.iter().filter(|&&r| r > 2.0).count();
    let (mut x, mut y, mut turns) = (1.0, 0.0, 0);
    for _ in 0..n {                                     // count sign changes of x from (1, 0)
        let (nx, ny) = euler(a, x, y, h, 1);
        if (nx > 0.0) != (x > 0.0) { turns += 1 }
        (x, y) = (nx, ny);
    }
    let label = if shrink > 0 && grow > 0 { "saddle".to_string() }
        else if shrink == 8 || grow == 8 { format!("{} {}", if shrink > 0 { "stable" } else { "unstable" }, if turns >= 2 { "spiral" } else { "node" }) }
        else { "centre".to_string() };
    (shrink, grow, 8 - shrink - grow, turns, label)
}
fn px(t: f64, d: f64) -> String { format!("({:.0}, {:.0})", 180.0 + 30.0 * t, 180.0 - 24.0 * d) }   // figure: 30 px per unit of trace, 24 per unit of det

fn main() {
    let cases: [(&str, M); 4] = [("rooms", [[-2, 1], [1, -2]]), ("absorber", [[0, 1], [-5, -2]]),
        ("spring", [[0, 1], [-1, 0]]), ("saddle", [[1, 0], [0, -1]])];
    let mut figure: Vec<String> = Vec::new();
    for (name, a) in &cases {
        let (t, d) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
        let (l1, l2, im) = eig(t, d);
        for (re, ii) in [(l1, im), (l2, -im)] {         // det(A - L I) = 0, from the entries
            let (u, w, bc) = (a[0][0] as f64 - re, a[1][1] as f64 - re, (a[0][1] * a[1][0]) as f64);
            let (dr, di) = (u * w - ii * ii - bc, -ii * (u + w));
            assert!((dr * dr + di * di).sqrt() < 1e-12);
        }
        let ev = if im != 0.0 { format!("{:.4} +/- {:.4}i", l1, im) } else { format!("{:.4} and {:.4}", l1, l2) };
        let (kind, stab) = chart(t, d);
        let (s, g, st, turns, label) = motion(a);
        println!("{} {:?}: trace {}, det {}, trace^2 - 4det {}, eigenvalues {} -> chart: {}, {}", name, a, t, d, t * t - 4 * d, ev, kind, stab);
        println!("  motion, 8 starts over 6 time units: shrink {}, grow {}, stay {}, sign changes {} -> {}", s, g, st, turns, label);
        assert_eq!(kind, label);                        // two roads, one verdict
        figure.push(format!("{} {}", name, px(t as f64, d as f64)));
    }
    let closed = 20.0 * (-1.0f64).exp() + 10.0 * (-3.0f64).exp();
    let errs: Vec<f64> = [(0.01, 100), (0.001, 1000)].iter().map(|&(h, n)| (euler(&cases[0].1, 30.0, 10.0, h, n).0 - closed).abs()).collect();
    println!("rooms, room 1 after 1 h from (30, 10): closed form {:.4} C; Euler error {:.4} at h = 0.01, {:.4} at h = 0.001", closed, errs[0], errs[1]);
    println!("periods: absorber 2pi/2 = {:.4} s, shrinking by e^-pi = {:.4} each turn; spring 2pi/1 = {:.4} s", PI, (-PI).exp(), 2.0 * PI);
    let spring: Vec<String> = (0..13).map(|k| format!("{:.2}", (k as f64 / 2.0).cos())).collect();
    let absorber: Vec<String> = (0..13).map(|k| { let t = k as f64; format!("{:.2}", (-t / 2.0).exp() * (t.cos() + 0.5 * t.sin())) }).collect();
    println!("chart spring x(t): {}", spring.join(", "));
    println!("chart absorber x(t): {}", absorber.join(", "));
    println!("figure, {}, parabola ends {} and {}, control {}", figure.join(", "), px(-5.0, 6.25), px(5.0, 6.25), px(0.0, -6.25));
    let (u, v) = euler(&cases[2].1, 1.0, 0.0, 0.1, 600);
    let r = (u * u + v * v).sqrt();
    let (b1, b2, _) = eig(4, 3);
    println!("mistake 1, trace -1 read as stable: [[1, 0], [0, -2]] has det -2, a saddle; from (1, 1) x reaches e^6 = {:.2} after 6 units", 6.0f64.exp());
    println!("mistake 2, Euler at h = 0.1 on the spring for 60 s: radius {:.2} (1.01^300 = {:.2}); the true radius stays 1", r, 1.01f64.powi(300));
    println!("hypothesis dropped, det 0: [[-1, 0], [0, 0]] reads {}, yet (0, 1) goes to {:?}: never returns", chart(-1, 0).0, euler(&[[-1, 0], [0, 0]], 0.0, 1.0, 0.001, 6000));
    println!("mistake 3, sign slip L^2 + trace L + det on the rooms: eigenvalues {:.4} and {:.4}, a false unstable node", b1, b2);
    assert!(errs[0] / errs[1] > 8.0 && errs[0] / errs[1] < 12.0 && errs[1] < 0.01);   // Euler closes on the closed form at first order
    assert!((r - 1.01f64.powi(300)).abs() < 1e-9 * r);                                // stepping agrees with (1 + h^2)^(n/2)
    println!("ALL CHECKS PASS");
}
