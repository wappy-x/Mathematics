// Surface area of revolution -- the same check as the Python, in Rust, std only.
// The glass's bowl is the lower 6 cm of a ball of radius 4 cm: at height x above
// the bottom its radius is f(x) = sqrt(8x - x^2).  Road one: S = 2 pi R h.
// Road two: bands swept by chords, with no derivative anywhere.

fn f(x: f64) -> f64 {
    (8.0 * x - x * x).max(0.0).sqrt()
}

// n frustums, each pi (r1 + r2) times its width (slant, or axial if slant is false)
fn bands(pi: f64, g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize, slant: bool) -> f64 {
    let w = (b - a) / n as f64;
    let mut total = 0.0;
    for k in 0..n {
        let (x0, x1) = (a + k as f64 * w, a + (k + 1) as f64 * w);
        let run = if slant { (w * w + (g(x1) - g(x0)).powi(2)).sqrt() } else { w };
        total += pi * (g(x0) + g(x1)) * run;
    }
    total
}

// a shrinking difference quotient for g'
fn dq(g: &dyn Fn(f64) -> f64, x: f64) -> f64 {
    let h = 1e-5;
    (g(x + h) - g(x - h)) / (2.0 * h)
}

fn main() {
    let (mut sides, mut s) = (6u64, 1.0f64); // Archimedes: a hexagon in a unit circle
    for _ in 0..26 {
        s = s / (2.0 + (4.0 - s * s).sqrt()).sqrt();
        sides *= 2;
    }
    let pi = sides as f64 * s / 2.0; // half the polygon's perimeter
    let (r, h) = (4.0f64, 6.0f64); // ball radius and bowl height, cm
    let exact = 2.0 * pi * r * h;
    let ball = 2.0 * pi * r * (2.0 * r);
    println!("pi, from a {}-sided polygon: {:.12}", sides, pi);
    println!("bowl: R = {} cm, h = {} cm, rim radius {:.6} cm", r, h, f(h));
    let mut factors = Vec::new();
    for x in [1.0, 3.0, 5.0] {
        let k = (1.0 + dq(&f, x).powi(2)).sqrt();
        factors.push(f(x) * k);
        println!("x = {}: radius {:.6}, slope {:.6}, slant factor {:.6}, product {:.6}", x, f(x), dq(&f, x), k, f(x) * k);
    }
    println!("road one, 2 pi R h: bowl {:.6}, whole ball {:.6}", exact, ball);
    let mut errs = Vec::new();
    for n in [6usize, 60, 600, 6000] {
        errs.push(exact - bands(pi, &f, 0.0, h, n, true));
        let e = errs[errs.len() - 1];
        println!("road two, {:4} bands: {:.6}, short by {:.6}", n, exact - e, e);
    }
    let ball2 = bands(pi, &f, 0.0, 2.0 * r, 6000, true);
    println!("road two, whole ball, 6000 bands: {:.6}", ball2);
    println!("one band, x 1 to 2: radii {:.4} and {:.4}, slant {:.4}, area {:.4}, exact {:.4}",
        f(1.0), f(2.0), (1.0 + (f(2.0) - f(1.0)).powi(2)).sqrt(), bands(pi, &f, 1.0, 2.0, 1, true), 2.0 * pi * r);
    println!("pole: start 0.01 cm up, lose {:.6}; to lose under 0.01, start below {:.6}",
        2.0 * pi * r * 0.01, 0.01 / (2.0 * pi * r));
    println!("silver 0.002 cm thick at 10.49 g per cm^3: {:.6} cm^3, {:.4} g", exact * 0.002, exact * 0.002 * 10.49);
    println!("figure, 25 per cm: centre (150, 120), band ({:.2}, 195) to ({:.2}, 170), rim ({:.2} to {:.2}, 70)",
        150.0 + 25.0 * f(1.0), 150.0 + 25.0 * f(2.0), 150.0 - 25.0 * f(h), 150.0 + 25.0 * f(h));
    let w = h / 6000.0;
    let disc: f64 = (0..6000).map(|k| pi * f((k as f64 + 0.5) * w).powi(2) * w).sum();
    let crinkle = |x: f64| f(x) + 0.01 * (100.0 * x).sin();
    println!("mistake, width not slant: {:.2}", bands(pi, &f, 0.0, h, 60000, false));
    println!("mistake, disc formula pi f^2 (a volume, cm^3): {:.2}", disc);
    println!("mistake, crinkled within 0.01 cm: {:.2}", bands(pi, &crinkle, 0.0, h, 60000, true));
    let signed = bands(pi, &|x: f64| x - 3.0, 0.0, 6.0, 6, true);
    println!("mistake, signed radius x - 3 on 0 to 6: {:.2}, true {:.2}",
        (signed * 100.0).round() / 100.0 + 0.0, bands(pi, &|x: f64| (x - 3.0).abs(), 0.0, 6.0, 6, true));
    assert!((exact - bands(pi, &f, 0.0, h, 6000, true)).abs() < 1e-3); // road two meets road one
    assert!(errs.windows(2).all(|p| p[0] > p[1] && p[1] > 0.0)); // and closes in from below
    assert!((ball2 - 4.0 * pi * r * r).abs() < 1e-3); // the sphere, 4 pi R^2
    assert!(factors.iter().all(|p| (p - r).abs() < 1e-6)); // radius x slant factor = R
    println!("ALL CHECKS PASS");
}
