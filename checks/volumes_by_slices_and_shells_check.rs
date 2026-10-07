// Volumes by discs, washers and shells -- the same check as the Python, in
// Rust, std only.  Every sum and root is written out here.  The wine glass:
// its inside wall stands y = r^2/2 cm above the bowl's bottom at r cm from the
// stem's axis; the bowl is 10 cm deep, so the rim radius is sqrt(20).
use std::f64::consts::PI;
const H: f64 = 10.0; // depth
const T: f64 = 0.3; // how far the outer wall sits below the inner one

fn discs(n: usize) -> (f64, f64) { // cylinders inside and outside each slice
    let h = H / n as f64; // radius^2 is 2y: smallest at a slice's bottom
    let lo: f64 = (0..n).map(|i| PI * 2.0 * (i as f64 * h) * h).sum();
    let hi: f64 = (0..n).map(|i| PI * 2.0 * ((i + 1) as f64 * h) * h).sum();
    (lo, hi)
}

fn shells(n: usize, c: f64) -> (f64, f64) { // exact tubes, length at each edge
    let (w, mut lo, mut hi) = (c / n as f64, 0.0, 0.0);
    for i in 0..n {
        let (u, v) = (i as f64 * w, (i + 1) as f64 * w);
        lo += PI * (v * v - u * u) * (H - v * v / 2.0);
        hi += PI * (v * v - u * u) * (H - u * u / 2.0);
    }
    (lo, hi)
}

fn midpoint(f: impl Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // slices sampled at their middles
    (0..n).map(|i| f(a + (i as f64 + 0.5) * (b - a) / n as f64)).sum::<f64>() * (b - a) / n as f64
}

fn main() {
    let c = (2.0 * H).sqrt(); // rim radius
    let disc_exact = PI * H * H; // antiderivative pi y^2 at 10
    let shell_exact = 2.0 * PI * (H / 2.0 * c.powi(2) - c.powi(4) / 8.0); // 2 pi (5 p^2 - p^4/8) at sqrt(20)
    println!("bowl: wall y = r^2/2 cm, depth {:.0} cm, rim radius {:.6} cm", H, c);
    println!("discs: pi x {:.0}^2 = {:.0} pi = {:.6}; shells: 2 pi ({:.0} - {:.0}) = {:.6}",
             H, disc_exact / PI, disc_exact, H / 2.0 * c.powi(2), c.powi(4) / 8.0, shell_exact);
    println!("the can round the bowl: pi x {:.0} x 10 = {:.6} cm^3, half of it {:.6}", c * c, PI * c * c * H, PI * c * c * H / 2.0);
    for n in [10, 100, 1000] {
        let ((a, b), (s, d)) = (discs(n), shells(n, c));
        println!("n = {:>4}: discs [{:.6}, {:.6}] gap {:.6}; shells [{:.6}, {:.6}] gap {:.6}", n, a, b, b - a, s, d, d - s);
    }
    println!("fill height cm: 0 1 2 3 4 5 6 7 8 9 10");
    let vols: Vec<String> = (0..11).map(|h| format!("{:.2}", PI * (h * h) as f64)).collect();
    println!("volume cm^3: {}", vols.join(" "));
    let (mut lo, mut hi) = (0.0, H); // bisection: fill height for 150 ml
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if midpoint(|y| 2.0 * PI * y, 0.0, mid, 8) < 150.0 { lo = mid } else { hi = mid }
    }
    println!("150 ml fills to {:.6} cm by bisection; sqrt(150/pi) = {:.6} cm", lo, (150.0 / PI).sqrt());
    let wall_exact = PI * (2.0 * T * H + T * T); // washers: constant 2 pi T, plus the cap
    let washer = midpoint(|y| PI * (2.0 * (y + T) - 2.0 * y.max(0.0)), -T, H, 103000);
    let top = (2.0 * (H + T)).sqrt();
    let shell_wall = midpoint(|p| 2.0 * PI * p * ((p * p / 2.0).min(H) - (p * p / 2.0 - T)), 0.0, top, 200000);
    println!("glass in the bowl: washers exact {:.2} pi = {:.6}, washer sum {:.6}, shell sum {:.6} cm^3",
             wall_exact / PI, wall_exact, washer, shell_wall);
    println!("each washer 2 pi T = {:.6} cm^2; shells need two pieces: rim at r = {:.6}, outer wall ends at r = {:.6} cm",
             2.0 * PI * T, c, top);
    let bad_ring = midpoint(|y| PI * ((2.0 * (y + T)).sqrt() - (2.0 * y.max(0.0)).sqrt()).powi(2), -T, H, 103000);
    let wrong_axis = midpoint(|r| PI * (r * r / 2.0).powi(2), 0.0, c, 100000);
    let double = midpoint(|p| 2.0 * PI * p.abs() * (H - p * p / 2.0), -c, c, 100000);
    println!("mistake, (R - r)^2 for the glass: {:.6} cm^3", bad_ring);
    println!("mistake, wall height as the radius: {:.6} cm^3", wrong_axis);
    println!("mistake, shells from -sqrt(20) to sqrt(20): {:.6} cm^3", double);
    println!("mistake, half the depth: {:.6} cm^3, a fraction {:.2} of the bowl", PI * 25.0, PI * 25.0 / disc_exact);
    let (k, m) = (16.0 * c, 16.0 * 12.5f64.sqrt()); // figure: 16 units per cm, y runs down
    println!("figure, bottom y 200, rim y {:.2}, control y {:.2}, stem to y 224; rim x {:.2} {:.2} {:.2} {:.2}; disc x {:.2} to {:.2}, y {:.2} to {:.2}; shells x 230-238, 302-310, y 40 to {:.2}",
             200.0 - 16.0 * H, 200.0 + 16.0 * H, 90.0 - k, 90.0 + k, 270.0 - k, 270.0 + k, 90.0 - m, 90.0 + m,
             200.0 - 16.0 * 6.5, 200.0 - 16.0 * 6.0, 200.0 - 16.0 * 2.25 * 2.25 / 2.0);
    assert!((midpoint(|p| 2.0 * PI * p * (H - p * p / 2.0), 0.0, c, 1000) - shell_exact).abs() < 1e-3); // shell sum vs antiderivative
    let ((a, b), (s, d)) = (discs(1000), shells(1000, c));
    assert!(a <= disc_exact && disc_exact <= b && s <= disc_exact && disc_exact <= d && b - a < 0.9 && d - s < 0.9);
    assert!((washer - wall_exact).abs() < 1e-6 && (shell_wall - wall_exact).abs() < 1e-6);
    assert!((lo - (150.0 / PI).sqrt()).abs() < 1e-9); // bisection against the formula
    println!("ALL CHECKS PASS");
}
