// Eigenvalues and eigenvectors -- the same check as the Python, in Rust.  No crates.  A fleet of
// 1,000 rental cars moves between two cities: each month 80% of city A's cars stay and 20% drive
// to B, 70% of B's stay and 30% drive to A, so the matrix is [[0.8, 0.3], [0.2, 0.7]].  Road 1:
// the characteristic quadratic, solved by the quadratic formula, each pattern read off a shifted
// row.  Road 2: run the fleet and read both stretch factors off the car counts, with no algebra.
type M = [[f64; 2]; 2];
fn times(m: M, v: (f64, f64)) -> (f64, f64) {            // a matrix times a column vector
    (m[0][0] * v.0 + m[0][1] * v.1, m[1][0] * v.0 + m[1][1] * v.1)
}
fn show(m: M) -> String {                                // a 2 by 2 matrix, row by row
    format!("[[{:.2}, {:.2}], [{:.2}, {:.2}]]", m[0][0], m[0][1], m[1][0], m[1][1])
}
fn whole(r: f64) -> (i64, i64) {                         // smallest whole pair with y / x = r
    let mut n = 1.0f64;
    while (r * n - (r * n).round()).abs() > 1e-9 { n += 1.0; }
    (n as i64, (r * n).round() as i64)
}
fn main() {
    let mat: M = [[0.8, 0.3], [0.2, 0.7]];
    let (a, b, c, d) = (mat[0][0], mat[0][1], mat[1][0], mat[1][1]);
    let (trace, det) = (a + d, a * d - b * c);
    let disc = trace * trace - 4.0 * det;
    if disc < 0.0 { println!("no real eigenvalue: this matrix turns every direction"); return; }
    let half = disc.sqrt() / 2.0;
    let (lam1, lam2) = (trace / 2.0 + half, trace / 2.0 - half);
    let vs = [whole((lam1 - a) / b), whole((lam2 - a) / b)];   // the shifted top row kills these
    let steady = 1000.0 * vs[0].0 as f64 / (vs[0].0 + vs[0].1) as f64;
    println!("fleet rules: each month 80% of city A's cars stay and 20% drive to B, \
              70% of B's stay and 30% drive to A");
    println!("matrix A = {}   trace a + d = {:.6}   determinant ad - bc = {:.6}",
             show(mat), trace, det);
    println!("characteristic quadratic  lambda^2 - {:.6} lambda + {:.6} = 0   \
              discriminant {:.6}", trace, det, disc);
    println!("road 1, the quadratic formula: eigenvalues {:.6} and {:.6}   \
              sum {:.6} = trace   product {:.6} = determinant",
             lam1, lam2, lam1 + lam2, lam1 * lam2);
    for (lam, v) in [(lam1, vs[0]), (lam2, vs[1])] {
        let shift: M = [[a - lam, b], [c, d - lam]];
        let w = (v.0 as f64, v.1 as f64);
        let (killed, av) = (times(shift, w), times(mat, w));
        println!("lambda = {:.6}:  A - lambda I = {}   eigenvector \
                  ({}, {})   A times it = ({:.6}, {:.6})",
                 lam, show(shift), v.0, v.1, av.0, av.1);
        assert!(killed.0.abs().max(killed.1.abs()) < 1e-12
            && (av.0 - lam * w.0).abs() < 1e-12 && (av.1 - lam * w.1).abs() < 1e-12);
    }
    println!("road 2, no algebra: 1000 cars start in city A, one month at a time");
    let (mut split, mut gaps) = ((1000.0f64, 0.0f64), Vec::new());
    for month in 0..61usize {
        if month <= 12 { gaps.push(split.0 - steady); }
        if month <= 6 {
            println!("   month {}   city A {:>7.2}   city B {:>7.2}   \
                      above the steady {:.2}: {:>7.2}",
                     month, split.0, split.1, steady, gaps[month]);
        }
        split = times(mat, split);
    }
    let settled = times(mat, split).0 / split.0;
    println!("the split settles at ({:.2}, {:.2}), whose factor is {:.6}; each gap halves, \
              factor {:.6}; gap after 12 months {:.2} cars",
             split.0, split.1, settled, gaps[1] / gaps[0], gaps[12]);
    assert!((settled - lam1).abs() < 1e-9
        && (0..12).all(|n| (gaps[n + 1] - lam2 * gaps[n]).abs() < 1e-9));
    assert!(((a - 2.0) * (d - 2.0) - b * c - (2.0 - lam1) * (2.0 - lam2)).abs() < 1e-12
        && (lam1 * lam2 - det).abs() < 1e-12 && (lam1 - 1.0).abs() < 1e-12 && (lam2 - 0.5).abs() < 1e-12);
    let sq: M = [[a * a + b * c, a * b + b * d], [c * a + d * c, c * b + d * d]];
    let mut ch = 0.0f64;
    for i in 0..2 {
        for j in 0..2 { ch = ch.max((sq[i][j] - trace * mat[i][j] + if i == j { det } else { 0.0 }).abs()); }
    }
    let bad = times(mat, (3.0, -2.0));
    println!("Cayley-Hamilton: A A - {:.6} A + {:.6} I is the zero matrix, largest entry {:.6}",
             trace, det, ch);
    println!("the four mistakes: root {:.6}, discriminant {:.6}, product {:.6} not {:.6}, \
              A (3, -2) = ({:.2}, {:.2})",
             det / d, trace * trace - 4.0 * (a * d + b * c), a * d, det, bad.0, bad.1);
    assert!(ch < 1e-12 && (bad.0 / 3.0 - bad.1 / -2.0).abs() > 0.1);
    println!("ALL CHECKS PASS");
}
