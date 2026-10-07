// Trig substitution -- the same check as the Python, in Rust.  No crates; sin,
// cos, sqrt and ln are primitives, and no built-in pi is used.  A pond of radius
// 3 m: its area by x = 3 sin(theta) and by midpoint sums; a relative by x = 3 tan(theta).
const R: f64 = 3.0;

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // a root of f between lo and hi
    for _ in 0..200 {
        let m = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(m) > 0.0) { lo = m } else { hi = m }
    }
    (lo + hi) / 2.0
}

fn mid(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint sum
    let w = (b - a) / n as f64;
    w * (0..n).map(|k| f(a + (k as f64 + 0.5) * w)).sum::<f64>()
}

fn root(x: f64) -> f64 { (R * R - x * x).max(0.0).sqrt() }
fn f_theta(t: f64) -> f64 { R * R / 2.0 * (t + t.sin() * t.cos()) }   // antiderivative of 9 cos^2

fn main() {
    let quarter = bisect(&|t: f64| t.cos(), 1.0, 2.0);   // the quarter turn: cos first reaches 0
    let (mut s, mut sides) = (1.0f64, 6u64);            // hexagon in a circle of radius 1: side 1
    for _ in 0..20 {
        s = s / (2.0 + (4.0 - s * s).sqrt()).sqrt();
        sides *= 2;
    }
    let pi_poly = sides as f64 * s / 2.0;               // half the perimeter, square roots only
    let area = 2.0 * (f_theta(quarter) - f_theta(-quarter));
    println!("pond radius 3 m; quarter turn, first zero of cos: {:.12}", quarter);
    println!("pi from the zero of cos: {:.12}; from {} sides: {:.12}", 2.0 * quarter, sides, pi_poly);
    println!("road 1, substitution, 2 x (9/2)(pi/2 + pi/2) = {:.6} m^2", area);
    let mut errs = Vec::new();
    for n in [10usize, 100, 1000, 10000] {
        let v = mid(&|x| 2.0 * root(x), -R, R, n);
        errs.push(v - area);
        println!("road 2, midpoint sum in x, n = {:5}: {:.6}  error {:.9}", n, v, v - area);
    }
    let th = mid(&|t: f64| 2.0 * R * R * t.cos().powi(2), -quarter, quarter, 10);
    println!("road 3, midpoint sum in theta, n = 10: {:.6}  error {:.9}", th, th - area);
    let t1 = bisect(&|t: f64| R * t.sin() - 1.5, -quarter, quarter);   // the branch's own angle
    let (strip, sector, tri) = (f_theta(t1) - f_theta(0.0), R * R * t1 / 2.0, 1.5 * root(1.5) / 2.0);
    let xs = mid(&root, 0.0, 1.5, 10000);
    println!("strip x = 0 to 1.5: theta = {:.6}; formula {:.6} = sector {:.6} + triangle {:.6}; x sum {:.6}",
             t1, strip, sector, tri, xs);
    let other = 5.0 * quarter / 3.0;                    // 5 pi / 6, off the branch
    println!("branch: theta = 5pi/6 gives x = {:.6}; root {:.6}; 3 cos theta {:.6}",
             R * other.sin(), root(1.5), R * other.cos());
    let rel = mid(&|x: f64| 1.0 / (9.0 + x * x).sqrt(), 0.0, 4.0, 10000);
    let (sec, tan) = ((9.0f64 + 16.0).sqrt() / 3.0, 4.0 / 3.0);   // the 3-4-5 triangle at x = 4
    println!("relative, 1/sqrt(9 + x^2) from 0 to 4: sec {:.6} + tan {:.6}; ln 3 = {:.6}; x sum {:.6}",
             sec, tan, (sec + tan).ln(), rel);
    println!("mistake, dx factor dropped: {:.6}, not {:.6}", 2.0 * R * (quarter.sin() - (-quarter).sin()), area);
    println!("mistake, x limits -3 and 3 kept as angles: {:.6}", 2.0 * (f_theta(3.0) - f_theta(-3.0)));
    let naive = mid(&|t: f64| R * R * t.cos().powi(2), quarter, 3.0 * quarter, 1000);
    let truth = -mid(&root, -R, R, 100000);             // x runs from 3 back to -3
    println!("mistake, root read as 3 cos theta on theta from pi/2 to 3pi/2: {:.6}; true {:.6}", naive, truth);
    let (sc, cx, cy) = (32.0, 180.0, 124.0);            // figure: 32 px per metre, centre at (180, 124)
    println!("figure, centre ({}, {}), top ({}, {:.2}), P ({:.2}, {:.2}), Q ({:.2}, {}), arc end ({:.2}, {:.2})",
             cx, cy, cx, cy - sc * R, cx + sc * 1.5, cy - sc * root(1.5), cx + sc * 1.5, cy,
             cx + 24.0 * t1.sin(), cy - 24.0 * t1.cos());
    assert!((2.0 * quarter - pi_poly).abs() < 1e-9);                          // radian pi meets polygon pi
    assert!(errs[3].abs() < 1e-4 && (th - R * R * pi_poly).abs() < 1e-9);    // road 1 meets road 2; road 3 meets 9 pi
    assert!((xs - strip).abs() < 1e-6 && errs[3].abs() < errs[2].abs() / 20.0);
    assert!((rel - (sec + tan).ln()).abs() < 1e-6 && (naive + truth).abs() < 1e-6);   // tangent relative; off-branch sign flip
    println!("ALL CHECKS PASS");
}
