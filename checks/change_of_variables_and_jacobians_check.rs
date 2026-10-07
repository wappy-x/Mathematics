// Change of variables -- the same check in Rust, std only.  Rain on a fan: radius
// 3 km, opening 60 degrees, 20 + 10 r mm deep at r km from the outlet.  Road 1: polar,
// with the factor r.  Road 2: an x-y grid that never mentions r.  Then the Jacobians.
use std::f64::consts::PI;
const R: f64 = 3.0;                              // the fan's radius in km
const TH: f64 = PI / 3.0; const DEG: f64 = PI / 180.0;   // its opening, and one degree, in radians
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // Simpson's rule, 100 strips
    let (n, mut s) = (100, f(a) + f(b));
    let h = (b - a) / n as f64;
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h); }
    s * h / 3.0
}
fn depth(r: f64) -> f64 { 20.0 + 10.0 * r }      // mm of rain at r km from the outlet
fn grid(n: usize) -> f64 {                       // road 2: n x n midpoint cells on the square 0..3 km
    let (h, mut s) = (R / n as f64, 0.0);
    for i in 0..n {
        for j in 0..n {
            let (x, y) = ((i as f64 + 0.5) * h, (j as f64 + 0.5) * h);
            if x * x + y * y <= R * R && y <= 3f64.sqrt() * x { s += depth((x * x + y * y).sqrt()); }
        }
    }
    s * h * h
}
fn pol(p: &[f64]) -> Vec<f64> { vec![p[0] * p[1].cos(), p[0] * p[1].sin()] }
fn sph(p: &[f64]) -> Vec<f64> { vec![p[0] * p[1].sin() * p[2].cos(), p[0] * p[1].sin() * p[2].sin(), p[0] * p[1].cos()] }
fn jac(t: &dyn Fn(&[f64]) -> Vec<f64>, p: &[f64]) -> Vec<Vec<f64>> {   // one central difference per input
    let h = 1e-6; let cols: Vec<Vec<f64>> = (0..p.len()).map(|k| {
        let (mut a, mut b) = (p.to_vec(), p.to_vec());
        a[k] += h; b[k] -= h;
        t(&a).iter().zip(t(&b).iter()).map(|(u, v)| (u - v) / (2.0 * h)).collect()
    }).collect();
    (0..p.len()).map(|i| (0..p.len()).map(|j| cols[j][i]).collect()).collect()
}
fn det2(m: &Vec<Vec<f64>>) -> f64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn det3(m: &Vec<Vec<f64>>) -> f64 {
    (0..3).map(|j| m[0][j] * (m[1][(j + 1) % 3] * m[2][(j + 2) % 3] - m[1][(j + 2) % 3] * m[2][(j + 1) % 3])).sum()
}
fn patch(r1: f64, r2: f64, t1: f64, t2: f64) -> f64 {   // a fan patch's area, as a polygon hugging both arcs
    let m = 400;
    let mut pts: Vec<Vec<f64>> = (0..=m).map(|k| pol(&[r2, t1 + (t2 - t1) * k as f64 / m as f64])).collect();
    pts.extend((0..=m).map(|k| pol(&[r1, t2 - (t2 - t1) * k as f64 / m as f64])));
    let mut s = 0.0;
    for k in 0..pts.len() { let (a, b) = (&pts[k], &pts[(k + 1) % pts.len()]); s += a[0] * b[1] - b[0] * a[1]; }
    s / 2.0
}
fn px(r: f64, t: f64) -> String { format!("({:.2}, {:.2})", 40.0 + 60.0 * r * t.cos(), 215.0 - 60.0 * r * t.sin()) }
fn main() {
    let exact = 60.0 * PI;                        // by hand: (pi/3) x (90 + 90)
    let polar = simpson(&|_t| simpson(&|r| depth(r) * r, 0.0, R), 0.0, TH);
    println!("road 1, polar with factor r: {:.6} mm km2; by hand (pi/3) x (90 + 90) = {:.6}", polar, exact);
    let mut g = 0.0;
    for n in [100usize, 400, 1600] {
        g = grid(n);
        println!("road 2, x-y grid {:4}: {:.6} mm km2, error {:+.6}", n, g, g - exact);
    }
    let area = TH * simpson(&|r| r, 0.0, R);
    println!("area {:.6} km2; mean depth {:.6} mm; water {:.0} m3", area, polar / area, polar * 1000.0);
    let (dp, ds) = (det2(&jac(&pol, &[2.25, 25.0 * DEG])), det3(&jac(&sph, &[2.0, 60.0 * DEG, 0.7])));
    println!("Jacobian by difference quotients: polar at r 2.25 {:.6}; spherical at rho 2, phi 60 deg {:.6} (rho^2 sin phi {:.6})", dp, ds, 4.0 * (60.0 * DEG).sin());
    let areas: Vec<f64> = [0.5, 2.0].iter().map(|&r1| patch(r1, r1 + 0.5, 20.0 * DEG, 30.0 * DEG)).collect();
    for (r1, a) in [0.5, 2.0].iter().zip(areas.iter()) {
        println!("patch r {:.1}..{:.1} km, 20..30 deg: polygon {:.6} km2; r dr dtheta {:.6}", r1, r1 + 0.5, a, (r1 + 0.25) * 0.5 * 10.0 * DEG);
    }
    let drop = 2.0 * PI * simpson(&|p| p * p, 0.0, 2.0) * simpson(&|f: f64| f.sin(), 0.0, PI);
    println!("raindrop radius 2 mm: {:.6} mm3; 4/3 pi 2^3 = {:.6}; sin phi dropped {:.6}", drop, 32.0 * PI / 3.0, 2.0 * PI * PI * 8.0 / 3.0);
    let per_m = 2.0 * PI * simpson(&|r| r, 0.0, 100.0);
    println!("round tank radius 100 m: {:.3} m3 per metre (theta run twice round: {:.3}); the storm fills it to {:.6} m", per_m, 2.0 * per_m, polar * 1000.0 / per_m);
    println!("mistakes: r dropped {:.6}; rim-outlet average x area {:.6}; degrees {:.6}", TH * simpson(&depth, 0.0, R), 35.0 * area, 60.0 * simpson(&|r| depth(r) * r, 0.0, R));
    println!("figure, 60 px per km, outlet (40, 215), rim ends {} {}", px(3.0, 0.0), px(3.0, TH));
    for r1 in [0.5, 2.0] {
        let c: Vec<String> = [(r1, 20.0), (r1 + 0.5, 20.0), (r1 + 0.5, 30.0), (r1, 30.0)].iter().map(|&(r, t)| px(r, t * DEG)).collect();
        println!("figure, patch r {:.1}..{:.1}: {}", r1, r1 + 0.5, c.join(" "));
    }
    assert!((polar - exact).abs() < 1e-9);                            // polar Simpson meets the hand answer
    assert!((g - exact).abs() < 0.05);                                // the grid, blind to r, closes on it
    assert!((dp - 2.25).abs() < 1e-6 && (ds - 4.0 * (60.0 * DEG).sin()).abs() < 1e-6);
    assert!((areas[1] - 2.25 * 0.5 * 10.0 * DEG).abs() < 1e-6 && (drop - 32.0 * PI / 3.0).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
