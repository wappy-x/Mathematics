// Double integrals -- the same check as the Python, in Rust.  No crates.
// Rain depth f(x, y) = 6 + 3y + xy mm on the catchment 0 <= y <= x/2, 0 <= x <= 4 (km).
// Roads: hand antiderivatives both orders; nested midpoint sums (vertical = north strips,
// horizontal = east strips); a grid of cells with no slicing; the lower/upper bracket.
fn depth(x: f64, y: f64) -> f64 { 6.0 + 3.0 * y + x * y }
fn mid(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint sum, n pieces
    let h = (b - a) / n as f64;
    (0..n).map(|k| g(a + (k as f64 + 0.5) * h)).sum::<f64>() * h
}

fn vertical(f: fn(f64, f64) -> f64, n: usize) -> f64 {           // x from 0 to 4, y from 0 to x/2
    mid(&|x| mid(&|y| f(x, y), 0.0, x / 2.0, n), 0.0, 4.0, n)
}

fn horizontal(f: fn(f64, f64) -> f64, n: usize) -> f64 {         // y from 0 to 2, x from 2y to 4
    mid(&|y| mid(&|x| f(x, y), 2.0 * y, 4.0, n), 0.0, 2.0, n)
}

fn grid(f: fn(f64, f64) -> f64, n: usize) -> f64 {               // cells on the edge count half
    let (w, h) = (4.0 / n as f64, 2.0 / n as f64);
    let mut s = 0.0;
    for i in 0..n {
        for j in 0..=i {
            let part = if j < i { 1.0 } else { 0.5 };
            s += f((i as f64 + 0.5) * w, (j as f64 + 0.5) * h) * w * h * part;
        }
    }
    s
}

fn bracket(f: fn(f64, f64) -> f64, n: usize) -> (f64, f64) {   // extremes at cell corners
    let (w, h) = (4.0 / n as f64, 2.0 / n as f64);
    let (mut lo, mut hi) = (0.0, 0.0);
    for i in 0..n {
        for j in 0..=i {                                        // an edge cell's lowest value is 0
            hi += f((i + 1) as f64 * w, (j + 1) as f64 * h) * w * h;
            if j < i { lo += f(i as f64 * w, j as f64 * h) * w * h; }
        }
    }
    (lo, hi)
}

fn spike(x: f64, y: f64) -> f64 { (x * x - y * y) / (x * x + y * y).powi(2) }   // unbounded at the corner

fn main() {
    let inner_v = |x: f64| 3.0 * x + 3.0 * x * x / 8.0 + x.powi(3) / 8.0;     // hand: north strip at x
    let inner_h = |y: f64| 24.0 + 8.0 * y - 6.0 * y * y - 2.0 * y.powi(3);     // hand: east strip at y
    let v_exact: f64 = 3.0 * 16.0 / 2.0 + 3.0 * 64.0 / 24.0 + 256.0 / 32.0;           // integral of inner_v, 0 to 4
    let h_exact = 24.0 * 2.0 + 8.0 * 4.0 / 2.0 - 6.0 * 8.0 / 3.0 - 2.0 * 16.0 / 4.0; // integral of inner_h, 0 to 2
    println!("corners: depth {:.0}, {:.0}, {:.0} mm; area {:.0} km^2", depth(0.0, 0.0), depth(4.0, 0.0), depth(4.0, 2.0), 4.0 * 2.0 / 2.0);
    println!("vertical slice at x = 2: {:.3}; midpoint {:.3}", inner_v(2.0), mid(&|y| depth(2.0, y), 0.0, 1.0, 64));
    println!("horizontal slice at y = 1: {:.3}; midpoint {:.3}", inner_h(1.0), mid(&|x| depth(x, 1.0), 2.0, 4.0, 64));
    println!("exact: vertical order {:.4}, horizontal order {:.4} mm km^2", v_exact, h_exact);
    assert!([0.3, 1.0, 1.7].iter().all(|&t| (inner_v(2.0 * t) - mid(&|y| depth(2.0 * t, y), 0.0, t, 8)).abs() < 1e-9
        && (inner_h(t) - mid(&|x| depth(x, t), 2.0 * t, 4.0, 8)).abs() < 1e-9));   // hand strips match
    for n in [4usize, 16, 64] {
        let (v, hz, g) = (vertical(depth, n), horizontal(depth, n), grid(depth, n));
        let bound = 10.0 / (n * n) as f64;
        println!("n = {}: vertical {:.4}, horizontal {:.4}, grid {:.4}; errors {:+.4}, {:+.4}, {:+.4}",
                 n, v, hz, g, v - v_exact, hz - v_exact, g - v_exact);
        assert!((v - v_exact).abs() < bound && (hz - h_exact).abs() < bound && (g - v_exact).abs() < bound);
    }
    let (lo, hi) = bracket(depth, 336);
    println!("bracket n = 336: lower {:.4}, upper {:.4}, gap {:.4}; bound (22 x 8 + 20 x 8)/n = {:.4}", lo, hi, hi - lo, (22.0 * 8.0 + 20.0 * 8.0) / 336.0);
    assert!(lo <= v_exact && v_exact <= hi && hi - lo <= (22.0 * 8.0 + 20.0 * 8.0) / 336.0);   // the tolerance game, played
    println!("volume: {:.0} mm km^2 = {:.0} m^3 = {:.0} million litres", v_exact, v_exact * 1000.0, v_exact);
    let rect = mid(&|x| mid(&|y| depth(x, y), 0.0, 2.0, 64), 0.0, 4.0, 64);
    let wrong = mid(&|y| mid(&|x| depth(x, y), 0.0, 2.0 * y, 64), 0.0, 2.0, 64);
    println!("mistake, rectangle limits 0..4 and 0..2: {:.2}; wrong side of the edge: {:.2}", rect, wrong);
    println!("mistake, n = 4 grid depths added without the cell area: {:.2}", grid(depth, 4) / 0.5);
    let dy_first = mid(&|x| 1.0 / (1.0 + x * x), 0.0, 1.0, 1000);         // inner y-integral = 1/(1 + x^2)
    let dx_first = mid(&|y| -1.0 / (1.0 + y * y), 0.0, 1.0, 1000);        // inner x-integral = -1/(1 + y^2)
    let at_half = mid(&|y| spike(0.5, y), 0.0, 1.0, 4000);
    println!("spike at x = 0.5: inner closed form {:.6}, midpoint {:.6}", 1.0 / 1.25, at_half);
    assert!((at_half - 1.0 / 1.25).abs() < 1e-6);
    println!("spike on the unit square: dy first {:.6}, dx first {:.6}", dy_first, dx_first);
    println!("figure, 70 px per km; corners (40,200), (320,200), (320,60); vertical strip x = {:.0} to {:.0}, top y = {:.1}; horizontal strip y = {:.0} to {:.0}, x = {:.0} to 320",
             40.0 + 70.0 * 2.4, 40.0 + 70.0 * 2.6, 200.0 - 70.0 * 1.25, 200.0 - 70.0 * 0.6, 200.0 - 70.0 * 0.4, 40.0 + 70.0 * 1.0);
    println!("ALL CHECKS PASS");
}
