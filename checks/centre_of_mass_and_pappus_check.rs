// Centre of mass and Pappus -- the same check as the Python, in Rust.  No
// crates: sqrt and PI come from std, and every integral is this file's own
// Simpson sum.  A swim ring's tube is a circle of radius r = 0.1 m whose centre
// sits R = 0.3 m from the axis it spins round.  Metres in, litres out.
use std::f64::consts::PI;
const R: f64 = 0.3;
const RT: f64 = 0.1; // the tube radius r
const L: f64 = 1000.0; // litres per m^3
const N: usize = 20000; // panels

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h);
    }
    s * h / 3.0
}

fn w(y: f64) -> f64 { (RT * RT - y * y).max(0.0).sqrt() } // half-chord at offset y

fn washers(c: f64, n: usize) -> f64 { // road two: rings stacked along the axis
    simpson(&|y: f64| PI * ((c + w(y)).powi(2) - (c - w(y)).max(0.0).powi(2)), -RT, RT, n)
}

fn main() {
    let r = RT;
    let area = simpson(&|x: f64| 2.0 * w(x - R), R - r, R + r, N); // vertical strips
    let xbar = simpson(&|x: f64| x * 2.0 * w(x - R), R - r, R + r, N) / area;
    let pappus = area * 2.0 * PI * xbar; // road one
    let exact = 2.0 * PI * PI * R * r * r;
    let half = simpson(&|y: f64| 2.0 * w(y), 0.0, r, N); // half-disc, flat side down
    let moment = simpson(&|y: f64| y * 2.0 * w(y), 0.0, r, N);
    let ybar = moment / half;
    let sphere = half * 2.0 * PI * ybar;
    let c = 0.05; // axis cuts the circle
    let (cross_pappus, cross_true) = (area * 2.0 * PI * c, washers(c, N));

    println!("swim ring: tube radius r = {} m, {:.1} m across, centre R = {} m from the axis, strips from a = {:.1} m to b = {:.1} m",
             r, 2.0 * r, R, R - r, R + r);
    println!("area by strips {:.7} m^2, pi r^2 = {:.7} m^2", area, PI * r * r);
    println!("centroid by integration: xbar = {:.6} m, path 2 pi xbar = {:.6} m", xbar, 2.0 * PI * xbar);
    println!("road one, Pappus: area x path = {:.7} m^3 = {:.4} L", pappus, pappus * L);
    for n in [10, 100, 1000] {
        let v = washers(R, n);
        println!("road two, washers, {:4} panels: {:.4} L, error {:.6} L", n, v * L, (v - exact).abs() * L);
    }
    println!("closed form 2 pi^2 R r^2 = {:.4} L", exact * L);
    println!("half-disc moment by strips {:.9} m^3, antiderivative 2 r^3 / 3 = {:.9} m^3", moment, 2.0 * r.powi(3) / 3.0);
    println!("half-disc: area {:.7} m^2, ybar = {:.6} m, 4r/(3 pi) = {:.6} m", half, ybar, 4.0 * r / (3.0 * PI));
    println!("half-disc spun on its flat side, Pappus: {:.4} L, 4/3 pi r^3 = {:.4} L", sphere * L, 4.0 / 3.0 * PI * r.powi(3) * L);
    println!("mistake, outer edge R + r as the distance: {:.4} L", area * 2.0 * PI * (R + r) * L);
    println!("mistake, inner edge R - r as the distance: {:.4} L", area * 2.0 * PI * (R - r) * L);
    println!("mistake, half-disc centroid halfway up at r/2: {:.4} L", half * 2.0 * PI * (r / 2.0) * L);
    println!("axis through the circle, centre {} m out: Pappus {:.4} L, solid {:.4} L", c, cross_pappus * L, cross_true * L);
    println!("figure, ring at 1 m = 400: axis x = 180, tube centre ({:.0}, 120), radius {:.0}, mirror ({:.0}, 120)",
             180.0 + 400.0 * R, 400.0 * r, 180.0 - 400.0 * R);
    println!("figure, half-disc at 1 m = 1000: flat side y = 200, centroid y = {:.2}, strip 0.08 m up at y = 120, half-width {:.2} m = {:.2}",
             200.0 - 1000.0 * ybar, w(0.08), 1000.0 * w(0.08));
    assert!((pappus - washers(R, N)).abs() < 1e-7); // two roads, one volume
    assert!((washers(R, N) - exact).abs() < 1e-7); // refining sum against the closed form
    assert!((sphere - 4.0 / 3.0 * PI * r.powi(3)).abs() < 1e-8); // Pappus against the sphere formula
    assert!(cross_true - cross_pappus > 0.0005); // the dropped hypothesis bites
    println!("ALL CHECKS PASS");
}
