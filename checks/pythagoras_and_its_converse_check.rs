// Pythagoras and its converse -- the same check as the Python, in Rust.  No crates.
// Truss: rafters 3 m and 4 m, square at the ridge.  Roads: the rule, the dissection,
// the tilted square's corner coordinates; the converse by a search round a circle.

fn root(x: f64) -> f64 {                          // square root by halving an interval
    let (mut lo, mut hi) = (0.0, x.max(1.0));
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if mid * mid < x { lo = mid } else { hi = mid }
    }
    lo
}

fn shoelace(p: &[(i64, i64)]) -> f64 {            // area of a polygon from its corners
    let mut s = 0;
    for j in 0..p.len() {
        let ((x, y), (u, v)) = (p[j], p[(j + 1) % p.len()]);
        s += x * v - y * u;
    }
    s.abs() as f64 / 2.0
}

fn centre(a: i64, b: i64) -> Vec<(i64, i64)> {    // the tilted square inside the (a+b) square
    vec![(a, 0), (a + b, a), (b, a + b), (0, b)]
}

fn corner_x(a: f64, b: f64, c: f64) -> f64 {      // search for the far end of rafter b
    let (mut lo, mut hi, mut x) = (0.0, 1000.0, 0.0); // t walks it round a circle of radius b
    for _ in 0..200 {
        let t: f64 = (lo + hi) / 2.0;
        x = b * (1.0 - t * t) / (1.0 + t * t);
        let y = 2.0 * b * t / (1.0 + t * t);
        if (x - a).powi(2) + y * y < c * c { lo = t } else { hi = t }
    }
    x                                             // x = 0 means the corner is square
}

fn main() {
    for (a, b) in [(3i64, 4i64), (3, 3)] {
        let (rule, sq) = (a * a + b * b, (a + b) * (a + b));
        let boxed = sq as f64 - 4.0 * (a * b) as f64 / 2.0;
        let area = shoelace(&centre(a, b));
        println!("rafters {} and {}: rule {}^2 + {}^2 = {}, span {:.10}", a, b, a, b, rule, root(rule as f64));
        println!("  dissection: outer {} x {} = {}, four triangles 4 x {} = {}, left {:.0}; corner coordinates give {:.0}; root {:.10}",
                 a + b, a + b, sq, a * b / 2, 2 * a * b, boxed, area, root(area));
        assert!(rule as f64 == area && boxed == area);  // three roads to one area
    }
    let leg = root(5.0 * 5.0 - 3.0 * 3.0);
    println!("missing rafter, span 5 and rafter 3: {:.10}", leg);
    assert!((leg - 4.0).abs() < 1e-9);                  // the rafter actually cut
    let c = root(25.0);
    let (p, q) = (9.0 / c, 16.0 / c);                   // the altitude's two pieces
    println!("altitude from C: pieces {:.1} + {:.1} = {:.1}, height {:.1}; 5 x {:.1} = {:.0}, 5 x {:.1} = {:.0}",
             p, q, p + q, 12.0 / c, p, c * p, q, c * q);
    for c in [5.0f64, 5.1, 4.9, 5.001] {
        let res = 3.0 * 3.0 + 4.0 * 4.0 - c * c;
        let mut x = corner_x(3.0, 4.0, c);
        if x.abs() < 1e-12 { x = 0.0 }
        let verdict = if x == 0.0 { "square".to_string() }
            else { format!("{} by {:.4} m", if x < 0.0 { "opened" } else { "closed" }, x.abs()) };
        println!("corner test, diagonal {:.3}: 9 + 16 - {:.6} = {:.6}; search: {}", c, c * c, res, verdict);
        assert!((x - res / 6.0).abs() < 1e-9);          // the search agrees with the residual
    }
    println!("mistakes: add the rafters {}; stop before the root {}; 4 m rafter as the span {:.10}; 3, 5, 4 in place {}",
             3 + 4, 3 * 3 + 4 * 4, root(4.0 * 4.0 - 3.0 * 3.0), 9 + 25 - 16);
    println!("try: rafters 6 and 8 span {:.4}; 5 and 12 span {:.4}; diagonal 5.01 opened by {:.4} m",
             root(6.0 * 6.0 + 8.0 * 8.0), root(5.0 * 5.0 + 12.0 * 12.0), -corner_x(3.0, 4.0, 5.01));
    let k = 60.0;                                       // truss figure: 1 m = 60 units
    let (cx, cy) = (30.0 + k * 16.0 / 5.0, 200.0 - k * 12.0 / 5.0);
    println!("figure, truss 1 m = {}: A (30, 200) B ({}, 200) C ({:.0}, {:.0})", k, 30.0 + 5.0 * k, cx, cy);
    println!("figure, square marker ({:.1}, {:.1}) ({:.1}, {:.1}) ({:.1}, {:.1})",
             cx - 9.6, cy + 7.2, cx - 2.4, cy + 16.8, cx + 7.2, cy + 9.6);
    let pts: Vec<(i64, i64)> = centre(3, 4).iter().map(|&(x, y)| (20 + 30 * x, 220 - 30 * y)).collect();
    println!("figure, dissection 1 m = 30: outer (20, 10) to (230, 220); centre {:?}", pts);
    println!("ALL CHECKS PASS");
}
