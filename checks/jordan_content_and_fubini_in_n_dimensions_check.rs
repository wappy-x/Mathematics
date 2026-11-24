// Jordan content and Fubini in n dimensions -- the same check as the Python, in Rust.  No crates.
// Catchment T: the triangle (0, 0), (4, 0), (0, 3) km; slanted edge y = 3 - 3x/4.  Rain depth 10 + 2x mm.
// Roads to 76: hand antiderivatives in both orders; the centroid; square counts and lower/upper sums
// on a grid; column strips trapped between those sums; horizontal layers of the 3D body of water.
fn depth(x: f64) -> f64 { 10.0 + 2.0 * x }
fn mid(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // midpoint sum, n pieces
    let h = (b - a) / n as f64;
    (0..n).map(|k| g(a + (k as f64 + 0.5) * h)).sum::<f64>() * h
}
fn grid(n: i64) -> (i64, i64, f64, f64) {      // squares of side 1/N km on the box [0, 4] x [0, 3]
    let h = 1.0 / n as f64;
    let (mut cin, mut cout, mut lo, mut hi) = (0, 0, 0.0, 0.0);
    for i in 0..4 * n {
        for j in 0..3 * n {
            if 3 * (i + 1) + 4 * (j + 1) <= 12 * n {     // far corner in T: whole square inside
                cin += 1;
                lo += depth(i as f64 * h) * h * h;
            }
            if 3 * i + 4 * j <= 12 * n {                 // near corner in T: square meets T
                cout += 1;
                hi += depth(((i + 1) as f64 * h).min(4.0 - 4.0 * j as f64 * h / 3.0)) * h * h;
            }
        }
    }
    (cin, cout, lo, hi)
}
fn brute(n: i64, m: i64) -> (f64, f64) {      // lowest and highest F over 16 sample points per square
    let (mut lo, mut hi) = (0.0, 0.0);
    for i in 0..4 * n { for j in 0..3 * n {
        let v: Vec<f64> = (0..=m).flat_map(|a| (0..=m).map(move |b| (a, b))).map(|(a, b)|
            if 3 * (m * i + a) + 4 * (m * j + b) <= 12 * n * m { depth((m * i + a) as f64 / (n * m) as f64) } else { 0.0 }).collect();
        lo += v.iter().cloned().fold(f64::MAX, f64::min); hi += v.iter().cloned().fold(f64::MIN, f64::max);
    } }
    (lo / (n * n) as f64, hi / (n * n) as f64)
}
fn layer(z: f64) -> f64 {                      // area of the water's horizontal slice at height z mm
    if z <= 10.0 { 6.0 } else { 3.0 / 8.0 * (4.0 - (z - 10.0) / 2.0).powi(2) }
}
fn main() {
    let column = |x: f64| 30.0 - 1.5 * x - 1.5 * x * x;                       // hand: north strip
    let row = |y: f64| 10.0 * (4.0 - 4.0 * y / 3.0) + (4.0 - 4.0 * y / 3.0).powi(2); // hand: east strip
    let x_first: f64 = 30.0 * 4.0 - 1.5 * 16.0 / 2.0 - 1.5 * 64.0 / 3.0;          // integral of column, 0 to 4
    let y_first: f64 = 10.0 * 6.0 + 16.0 * 3.0 / 3.0;                              // 10 x area + (4 - 4y/3)^2
    let centroid = 10.0 * 6.0 + 2.0 * 6.0 * 4.0 / 3.0;                        // depth at x = 4/3, times 6
    println!("catchment: area {:.0} km^2, centroid x = {:.4} km; depth {:.0} to {:.0} mm", 4.0 * 3.0 / 2.0, 4.0 / 3.0, depth(0.0), depth(4.0));
    println!("strips: north at x = 2 carries {:.3}, east at y = 1.5 carries {:.3}", column(2.0), row(1.5));
    assert!([0.5, 2.0, 3.5].iter().all(|&t| (column(t) - mid(&|_y| depth(t), 0.0, 3.0 - 0.75 * t, 8)).abs() < 1e-9
        && (row(t / 4.0 * 3.0) - mid(&depth, 0.0, 4.0 - t, 8)).abs() < 1e-9));
    println!("exact: north strips {:.4}, east strips {:.4}, centroid {:.4} mm km^2", x_first, y_first, centroid);
    assert!((x_first - y_first).abs() < 1e-9 && (x_first - centroid).abs() < 1e-9);
    let (mut cin, mut cout, mut nn) = (0, 0, 1);
    for n in [10i64, 100, 1000] {
        let (ci, co, lo, hi) = grid(n);
        let nf = n as f64;
        let s_lo = (0..4 * n).map(|i| column((i + 1) as f64 / nf)).sum::<f64>() / nf; // column rain falls
        let s_hi = (0..4 * n).map(|i| column(i as f64 / nf)).sum::<f64>() / nf;       // with x
        println!("N = {}: squares inside {}, touching {}; content {:.6} to {:.6}", n, ci, co, ci as f64 / (nf * nf), co as f64 / (nf * nf));
        println!("  rain: lower {:.4} <= strips {:.4} to {:.4} <= upper {:.4}; gap {:.4}", lo, s_lo, s_hi, hi, hi - lo);
        assert!(ci == 6 * n * n - 3 * n && co == 6 * n * n + 4 * n - 1);       // the edge costs 7N - 1 squares
        assert!(lo <= s_lo && s_lo <= x_first && x_first <= s_hi && s_hi <= hi && hi - lo <= 138.0 / nf);
        (cin, cout, nn) = (ci, co, n);
    }
    let (b_lo, b_hi) = brute(10, 3);                                           // brute force, no corner formulas
    println!("brute force, N = 10, 16 points per square: lower {:.4}, upper {:.4}", b_lo, b_hi);
    assert!((b_lo - grid(10).2).abs() < 1e-9 && (b_hi - grid(10).3).abs() < 1e-9);
    let nf = nn as f64;
    println!("edge squares at N = 1000: {}, area {:.6} km^2, under 7/N = {:.6}", cout - cin, (cout - cin) as f64 / (nf * nf), 7.0 / nf);
    let layers = mid(&layer, 0.0, 18.0, 1800);
    println!("layers: slice area at z = 14 mm is {:.4} km^2; layers added {:.4} mm km^2", layer(14.0), layers);
    assert!((layers - x_first).abs() < 1e-3);
    println!("water: {:.0} mm km^2 = {:.0} m^3", x_first, x_first * 1000.0);
    let wit: Vec<f64> = [0.0f64, 0.5].into_iter().filter(|b| 2.0 * b * b <= 1.0).collect();  // points ((i + b sqrt 2)/N, j/N): in square (i, j) iff 2b^2 <= 1; a fraction iff b = 0
    println!("rational points, any N: each square holds a fraction point and a point that is not: upper {}, lower {}", wit.iter().any(|&b| b == 0.0) as i32, wit.iter().all(|&b| b == 0.0) as i32);
    println!("mistake, box limits 0..4 by 0..3: {:.2}; every layer the whole triangle: {:.2}",
             mid(&|x| 3.0 * depth(x), 0.0, 4.0, 64), 6.0 * 18.0);
    let g4 = grid(4);
    println!("figure, 80 px per km, N = 4; corners (40,280), (360,280), (40,40); inside {} ({:.4} km^2), meeting T {} ({:.4} km^2), on the edge {}",
             g4.0, g4.0 as f64 / 16.0, g4.1, g4.1 as f64 / 16.0, g4.1 - g4.0);
    println!("ALL CHECKS PASS");
}
