// Quadratic forms -- the same check as the Python, in Rust.  No crates.  Two assets,
// monthly returns in percentage points, variances 4 and 9 and covariance 1, so the
// matrix is [[4, 1], [1, 9]].  The variance of a mix is reached by two roads that share
// no arithmetic: the matrix product x^T A x, and the average of the squared departures
// of the blended table.  The top eigenvalue is reached twice too: the quadratic formula
// on trace and determinant, then repeated multiplying.
type Mat = [[f64; 2]; 2];
const A: Mat = [[4.0, 1.0], [1.0, 9.0]];
const INDEP: Mat = [[4.0, 0.0], [0.0, 9.0]];      // the same variances, covariance dropped
const B: Mat = [[1.0, 2.0], [2.0, 1.0]];          // positive diagonal, not positive definite
const NEG: Mat = [[-4.0, -1.0], [-1.0, -9.0]];    // never zero off the origin, always negative
const P: [i64; 8] = [2, 2, 2, 2, -2, -2, -2, -2]; // asset one, departures from its average
const R: [i64; 8] = [5, 1, -1, -3, -5, -1, 1, 3]; // asset two, departures from its average
fn dot(u: [f64; 2], v: [f64; 2]) -> f64 { u[0] * v[0] + u[1] * v[1] }
fn form(a: Mat, x: [f64; 2]) -> f64 { dot(x, [dot(a[0], x), dot(a[1], x)]) }   // road one
fn det(a: Mat) -> f64 { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn from_table(x: [f64; 2]) -> f64 {               // road two: average squared departure
    let mut total = 0.0;
    for i in 0..P.len() { let d = x[0] * P[i] as f64 + x[1] * R[i] as f64; total += d * d; }
    total / P.len() as f64
}
fn eigs(a: Mat) -> [f64; 2] {                     // roots of lam^2 - trace lam + det
    let tr = a[0][0] + a[1][1];
    let gap = (tr * tr - 4.0 * det(a)).sqrt();
    [(tr + gap) / 2.0, (tr - gap) / 2.0]
}
fn top_by_multiplying(a: Mat, steps: usize) -> f64 {   // second road to the top eigenvalue
    let mut v = [1.0, 1.0];
    for _ in 0..steps {
        v = [dot(a[0], v), dot(a[1], v)];
        v = [v[0] / v[0].abs().max(v[1].abs()), v[1] / v[0].abs().max(v[1].abs())];
    }
    form(a, v) / dot(v, v)                        // the score per unit of squared length
}
fn row(name: &str, vals: &[f64]) {
    let mut line = format!("{:<23}", name);
    for v in vals { line.push_str(&format!("{:>7.2}", v)); }
    println!("{}", line);
}
fn ints(name: &str, vals: [i64; 8]) {
    let mut line = String::from(name);
    for v in vals { line.push_str(&format!("{:>4}", v)); }
    println!("{}", line);
}
fn main() {
    let (grid, lam, best) = ((0..=10).map(|i| i as f64 / 10.0).collect::<Vec<f64>>(), eigs(A), 8.0 / 11.0);
    let scan: Vec<f64> = (0..=10000).map(|i| form(A, [i as f64 / 10000.0, 1.0 - i as f64 / 10000.0])).collect();
    let (mut low, mut argw) = (scan[0], 0.0);
    for i in 0..scan.len() { if scan[i] < low { low = scan[i]; argw = i as f64 / 10000.0; } }
    let (q2, q1, q0) = (A[0][0] - 2.0 * A[0][1] + A[1][1], 2.0 * A[0][1] - 2.0 * A[1][1], A[1][1]);
    println!("matrix rows: (4, 1) and (1, 9), in percent squared");
    ints("asset one departures:", P);   ints("asset two departures:", R);
    println!("from the table: variances {:.6} and {:.6}, covariance {:.6}", from_table([1.0, 0.0]),
             from_table([0.0, 1.0]), (from_table([1.0, 1.0]) - from_table([1.0, 0.0]) - from_table([0.0, 1.0])) / 2.0);
    println!("half and half: matrix road {:.6}, table road {:.6}", form(A, [0.5, 0.5]), from_table([0.5, 0.5]));
    row("blended half and half", &(0..8).map(|i| 0.5 * P[i] as f64 + 0.5 * R[i] as f64).collect::<Vec<f64>>());
    println!("eigenvalues {:.6} and {:.6}, sum {:.6}, product {:.6}", lam[0], lam[1], lam[0] + lam[1], lam[0] * lam[1]);
    println!("top eigenvalue by repeated multiplying {:.6}, and for [[4, 0], [0, 9]] {:.6}",
             top_by_multiplying(A, 60), top_by_multiplying(INDEP, 60));
    println!("three tests: entry {:.6} > 0, determinant {:.6} > 0, smaller eigenvalue {:.6} > 0", A[0][0], det(A), lam[1]);
    println!("fully invested coefficients: w^2 {:.6}, w {:.6}, constant {:.6}", q2, q1, q0);
    println!("best fully invested mix {:.6} and {:.6}, in whole parts 8 to 3", best, 1.0 - best);
    println!("smallest variance: 35/11 is {:.6}, matrix road {:.6}, scan of 10001 mixes {:.6} at weight {:.6}",
             35.0 / 11.0, form(A, [best, 1.0 - best]), low, argw);
    row("weight in asset one", &grid);
    row("variance, covariance 1", &grid.iter().map(|&w| form(A, [w, 1.0 - w])).collect::<Vec<f64>>());
    row("variance, covariance 0", &grid.iter().map(|&w| form(INDEP, [w, 1.0 - w])).collect::<Vec<f64>>());
    println!("wrong: covariance dropped {:.6}, cross term counted once {:.6}, hold nothing at all {:.6}",
             form(INDEP, [0.5, 0.5]), 4.0 * 0.25 + 0.25 + 9.0 * 0.25, form(A, [0.0, 0.0]));
    println!("positive diagonal is not enough: [[1, 2], [2, 1]] eigenvalues {:.6} and {:.6}, score at (1, -1) {:.6}",
             eigs(B)[0], eigs(B)[1], form(B, [1.0, -1.0]));
    println!("never zero is not enough: [[-4, -1], [-1, -9]] scores {:.6} at half and half", form(NEG, [0.5, 0.5]));
    assert!(grid.iter().all(|&w| (from_table([w, 1.0 - w]) - form(A, [w, 1.0 - w])).abs() < 1e-12));
    assert!((top_by_multiplying(A, 60) - lam[0]).abs() < 1e-9 && (top_by_multiplying(INDEP, 60) - 9.0).abs() < 1e-9);
    assert!((low - 35.0 / 11.0).abs() < 1e-7 && (argw - best).abs() < 1e-3
            && scan.iter().all(|&v| v >= 35.0 / 11.0 - 1e-12));
    assert!([A, INDEP, B, NEG].iter().all(|&m| (eigs(m)[1] > 0.0) == (m[0][0] > 0.0 && det(m) > 0.0))
            && form(B, [1.0, -1.0]) == -2.0 && eigs(B)[1] < 0.0 && eigs(B)[0] > 0.0 && form(NEG, [0.5, 0.5]) < 0.0);
    println!("ALL CHECKS PASS");
}
