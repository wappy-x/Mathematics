// Constant rank theorem -- the same check as the Python, in Rust.  No crates.
// Two valves feed one pipe: x, y in litres per second.  F(x, y) = (x + y, (x + y)^2)
// gives total flow s and pressure drop t.  Road 1: the charts by hand.  Road 2: the
// proof's recipe run blind (Newton undo, R sampled at one v).  Ranks by a determinant test.
type M = [[f64; 2]; 2];
fn f(x: f64, y: f64) -> (f64, f64) { (x + y, (x + y) * (x + y)) }
fn phi(x: f64, y: f64) -> (f64, f64) { (x + y, y) } // the recipe: keep the first output, then y
fn fold(x: f64, y: f64) -> (f64, f64) { (x, y * y) }
fn bad(x: f64, y: f64) -> (f64, f64) { (x + y, x + y) }
fn jac(g: fn(f64, f64) -> (f64, f64), x: f64, y: f64) -> M { // central differences
    let h = 1e-5;
    let (a, b, c, d) = (g(x + h, y), g(x - h, y), g(x, y + h), g(x, y - h));
    [[(a.0 - b.0) / (2.0 * h), (c.0 - d.0) / (2.0 * h)], [(a.1 - b.1) / (2.0 * h), (c.1 - d.1) / (2.0 * h)]]
}
fn det(j: &M) -> f64 { j[0][0] * j[1][1] - j[0][1] * j[1][0] }
fn rank(j: &M) -> i32 {                    // determinant test on a 2 by 2 matrix
    if j.iter().flatten().all(|e| e.abs() < 1e-6) { return 0; }
    let scale = 1f64.max((j[0][0] * j[1][1]).abs()).max((j[0][1] * j[1][0]).abs());
    if det(j).abs() > 1e-6 * scale { 2 } else { 1 }
}
fn mul(a: [[i64; 2]; 2], b: [[i64; 2]; 2]) -> [[i64; 2]; 2] { std::array::from_fn(|i| std::array::from_fn(|j| a[i][0] * b[0][j] + a[i][1] * b[1][j])) }
fn undo(u: f64, v: f64) -> (f64, f64, i32) { // Newton's method on phi(x, y) = (u, v)
    let (mut x, mut y) = (0.0, 0.0);
    for k in 1..50 {
        let (j, (p, q)) = (jac(phi, x, y), phi(x, y));
        let dx = ((u - p) * j[1][1] - (v - q) * j[0][1]) / det(&j);
        let dy = ((v - q) * j[0][0] - (u - p) * j[1][0]) / det(&j);
        x += dx; y += dy;
        if dx.abs() + dy.abs() < 1e-13 { return (x, y, k); }
    }
    (x, y, 49)
}
fn r(u: f64, v: f64) -> f64 { let (x, y, _) = undo(u, v); f(x, y).1 } // leftover output
fn psi(s: f64, t: f64) -> (f64, f64) { (s, t - r(s, 2.0)) } // road 2, R sampled at v = 2 only
fn psi_hand(s: f64, t: f64) -> (f64, f64) { (s, t - s * s) } // road 1 output chart
fn main() {
    let a = jac(f, 1.0, 2.0);
    println!("point (1, 2): F = ({}, {}); Jacobian [[{:.6}, {:.6}], [{:.6}, {:.6}]]", f(1.0, 2.0).0, f(1.0, 2.0).1, a[0][0], a[0][1], a[1][0], a[1][1]);
    let grid: Vec<(f64, f64)> = (0..441).map(|n| (-5.0 + (n / 21) as f64 / 2.0, -5.0 + (n % 21) as f64 / 2.0)).collect();
    let mut ranks: Vec<i32> = grid.iter().map(|&(x, y)| rank(&jac(f, x, y))).collect();
    ranks.sort(); ranks.dedup();
    println!("rank by determinant test at {} grid points in [-5, 5] by [-5, 5]: {:?}", grid.len(), ranks);
    let j0 = a.map(|row| row.map(|e| e.round() as i64)); // Step 1: Q and P read off the computed Jacobian
    let (q, p) = ([[1, 0], [-j0[1][0] / j0[0][0], 1]], [[1, -j0[0][1] / j0[0][0]], [0, 1]]);
    let d = mul(mul(q, j0), p);
    println!("linear case: J = {:?}, Q = {:?}, P = {:?}, Q J P = {:?}", j0, q, p, d);
    let (x, y, k) = undo(3.0, 2.0);
    println!("input chart: phi(1, 2) = ({}, {}), Jacobian {:?}, det {:.6}; Newton undo of (3, 2): ({:.6}, {:.6}) in {} steps", phi(1.0, 2.0).0, phi(1.0, 2.0).1,
             jac(phi, 1.0, 2.0).map(|r| r.map(|e| e.round() as i64)), det(&jac(phi, 1.0, 2.0)), x, y, k);
    let drdv = (r(3.0, 2.0 + 1e-4) - r(3.0, 2.0 - 1e-4)) / 2e-4;
    println!("in the new chart: G(3, 2) = (3, {:.6}); dR/dv at (3, 2) = {:.6}", r(3.0, 2.0), drdv.abs());
    println!("output chart: recipe psi(3, 9) = (3, {:.6}); by hand ({}, {})", psi(3.0, 9.0).1, psi_hand(3.0, 9.0).0, psi_hand(3.0, 9.0).1);
    let (mut err, mut gap) = (0f64, 0f64);
    for &(u, v) in &grid {
        let (px, py, _) = undo(u, v);
        let (fs, ft) = f(px, py);
        let p = psi(fs, ft);
        err = err.max((p.0 - u).abs()).max(p.1.abs());
        let (gs, gt) = f(u, v);
        gap = gap.max((psi(gs, gt).1 - psi_hand(gs, gt).1).abs());
    }
    println!("projection form on the grid: max error {:.9}; recipe vs hand chart {:.9}", err, gap);
    println!("ignored direction: F(1.5, 1.5) = ({:.1}, {:.1}), F(3, 0) = ({}, {})", f(1.5, 1.5).0, f(1.5, 1.5).1, f(3.0, 0.0).0, f(3.0, 0.0).1);
    println!("meter reading (3, 9.4): corrected output (3, {:.1})", psi_hand(3.0, 9.4).1);
    let lv: Vec<(f64, f64)> = [1.0, 2.0, 3.0].iter().map(|&v| { let (p, q, _) = undo(3.0, v); (p, q) }).collect();
    let pts: Vec<String> = lv.iter().map(|(p, q)| format!("({:.6}, {:.6})", p, q)).collect();
    println!("level set s = 3: {}; slope -Fx/Fy = {:.6}", pts.join(", "), -a[0][0] / a[0][1]);
    println!("fold (x, y) to (x, y^2): rank {} at (1, 0.1), {} at (1, 0); (1, 0.1) goes to (1, {:.6}), (1, -0.1) goes to (1, {:.6})",
             rank(&jac(fold, 1.0, 0.1)), rank(&jac(fold, 1.0, 0.0)), fold(1.0, 0.1).1, fold(1.0, -0.1).1);
    let tan: Vec<f64> = [3.0, 4.0].iter().map(|s: &f64| s * s - 6.0 * s + 9.0).collect();
    println!("mistakes: t - s gives (3, {}); tangent fix t - 6s + 9 at s = 3, 4 gives {}, {}; v = x + y gives det {:.6}",
             f(1.0, 2.0).1 - f(1.0, 2.0).0, tan[0], tan[1], det(&jac(bad, 1.0, 2.0)).abs());
    assert!(ranks == vec![1] && rank(&jac(fold, 1.0, 0.1)) == 2 && rank(&jac(fold, 1.0, 0.0)) == 1); // determinant test
    assert!(j0 == [[1, 1], [6, 6]] && d == [[1, 0], [0, 0]] && a.iter().flatten().zip(j0.iter().flatten()).all(|(e, n)| (e - *n as f64).abs() < 1e-6)); // linear form of F
    assert!(drdv.abs() < 1e-6);                                      // R ignores v
    assert!(err < 1e-9 && gap < 1e-9);                               // blind recipe = projection = hand
    assert!((x - 1.0).abs() < 1e-12 && (y - 2.0).abs() < 1e-12);     // Newton undoes phi
    assert!(lv.iter().all(|(p, q)| (p + q - 3.0).abs() < 1e-12));   // level set x + y = 3
    println!("ALL CHECKS PASS");
}
