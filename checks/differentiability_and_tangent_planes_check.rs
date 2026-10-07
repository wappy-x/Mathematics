// Tangent planes -- the check behind the card.  A hill's height is
// f(x, y) = 80 - 0.001x^2 - 0.0005xy - 0.002y^2 metres, x metres east and y
// metres north of a survey peg.  Road one: slopes by formula, remainder expanded
// by hand.  Road two: slopes from difference quotients, heights evaluated
// directly.  Then the crease g(x, y) = xy / sqrt(x^2 + y^2), whose slopes lie.
use std::f64::consts::PI;

fn f(x: f64, y: f64) -> f64 { 80.0 - 0.001 * x * x - 0.0005 * x * y - 0.002 * y * y }
fn fx(x: f64, y: f64) -> f64 { -0.002 * x - 0.0005 * y } // slope east, by formula
fn fy(x: f64, y: f64) -> f64 { -0.0005 * x - 0.004 * y } // slope north, by formula
fn hand(h: f64, k: f64) -> f64 { -(0.001 * h * h + 0.0005 * h * k + 0.002 * k * k) }
fn g(x: f64, y: f64) -> f64 { if x == 0.0 && y == 0.0 { 0.0 } else { x * y / (x * x + y * y).sqrt() } }
fn join(v: &[f64], p: usize) -> String {
    v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (a, b) = (100.0, 50.0);
    let (z, sx, sy) = (f(a, b), fx(a, b), fy(a, b));
    let plane = |x: f64, y: f64| z + sx * (x - a) + sy * (y - b);
    println!("hill: f(100, 50) = {:.6} m; slopes by formula f_x = {:.6}, f_y = {:.6}", z, sx, sy);
    let steps = [1.0, 0.1, 0.01, 1e-6];
    let qx: Vec<f64> = steps.iter().map(|&s| (f(a + s, b) - z) / s).collect();
    let qy: Vec<f64> = steps.iter().map(|&s| (f(a, b + s) - z) / s).collect();
    println!("forward differences, steps 1, 0.1, 0.01: f_x {}; f_y {}", join(&qx[..3], 6), join(&qy[..3], 6));
    println!("normal (-f_x, -f_y, 1) = ({:.3}, {:.3}, 1)", -sx, -sy);
    let (east, north) = (f(110.0, 50.0) - z, f(110.0, 70.0) - f(110.0, 50.0));
    println!("two legs: east {:.6} = 10 x {:.6}, north {:.6} = 20 x {:.6}, total {:.6}",
             east, fx(105.0, 50.0), north, fy(110.0, 60.0), east + north);
    assert!((qx[3] - sx).abs() + (qy[3] - sy).abs() < 1e-5
            && (east - 10.0 * fx(105.0, 50.0)).abs() + (north - 20.0 * fy(110.0, 60.0)).abs() < 1e-9);
    for (h, k) in [(10.0_f64, 20.0_f64), (1.0, 2.0), (0.1, 0.2)] {
        let (rho, act) = ((h * h + k * k).sqrt(), f(a + h, b + k));
        let rem = act - plane(a + h, b + k);
        assert!((rem - hand(h, k)).abs() < 1e-9); // direct height minus plane = hand expansion
        println!("step ({}, {}): rho {:.6}, actual {:.6}, plane {:.6}, remainder {:.6}, by hand {:.6}, ratio {:.6}",
                 h, k, rho, act, plane(a + h, b + k), rem, hand(h, k), rem / rho);
    }
    let r0 = 0.44;
    let mut worst: f64 = 0.0;
    for i in 0..360 {
        let t = 2.0 * PI * i as f64 / 360.0;
        let (x, y) = (a + r0 * t.cos(), b + r0 * t.sin());
        worst = worst.max((f(x, y) - plane(x, y)).abs() / r0);
    }
    println!("worst ratio over 360 directions at rho 0.44 m: {:.6}; hand bound 0.00225 x 0.44 = {:.6}", worst, 0.00225 * r0);
    assert!(worst < 0.001 && worst <= 0.00225 * r0);
    for t in [0.1_f64, 0.01, 0.001] {
        let (ax, ay) = ((g(t, 0.0) - g(0.0, 0.0)) / t, (g(0.0, t) - g(0.0, 0.0)) / t);
        let rho = (2.0 * t * t).sqrt();
        let (ratio, slope) = (g(t, t) / rho, (g(t + t * 1e-6, t) - g(t, t)) / (t * 1e-6));
        println!("crease t = {}: axis quotients {:.1}, {:.1}; g(t, t) = {:.6}, rho {:.6}, ratio {:.6}; east slope at (t, t) {:.6}",
                 t, ax, ay, g(t, t), rho, ratio, slope);
        assert!(ax == 0.0 && ay == 0.0 && (ratio - 0.5).abs() < 1e-9 && (slope - 1.0 / (2.0 * 2f64.sqrt())).abs() < 1e-5);
    }
    let s: [i32; 6] = [-2, -1, 0, 1, 2, 3];
    let hill: Vec<f64> = s.iter().map(|&n| f(a + 10.0 * n as f64, b + 20.0 * n as f64)).collect();
    let flat: Vec<f64> = s.iter().map(|&n| plane(a + 10.0 * n as f64, b + 20.0 * n as f64)).collect();
    println!("chart, steps of (10 m east, 20 m north): {}", s.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, hill (m): {}", join(&hill, 2));
    println!("chart, plane (m): {}", join(&flat, 2));
    println!("mistake, plane without the shift, at (110, 70): {:.6} m", z + sx * 110.0 + sy * 70.0);
}
