// Determinants -- the same check as determinants_check.py, in Rust.  No crates.  The sprite is
// the unit square, area 1, and each matrix moves its four corners.  Every determinant is found
// twice: cofactor expansion along the top row, and elimination to a staircase whose diagonal is
// multiplied.  The moved square's area is then measured a third way, off its corners.  Compile:
// rustc --edition 2021 -O determinants_check.rs -o determinants_check
type Mat = Vec<Vec<f64>>;
fn cofactor(m: &Mat) -> f64 {           // road 1: entry x its knocked-out minor
    if m.len() == 1 { return m[0][0]; }
    let mut total = 0.0;
    for j in 0..m.len() {
        let minor: Mat = m[1..].iter().map(|row| [&row[..j], &row[j + 1..]].concat()).collect();
        let sign = if j % 2 == 0 { 1.0 } else { -1.0 };
        total += sign * m[0][j] * cofactor(&minor);
    }
    total
}
fn staircase(m: &Mat) -> (f64, Mat) {   // road 2: eliminate, multiply the diagonal
    let mut a = m.clone();
    let n = a.len();
    let mut sign = 1.0f64;
    for c in 0..n {
        match (c..n).find(|&r| a[r][c].abs() > 1e-12) {
            None => return (0.0, a),    // a column of zeros: the box is already flat
            Some(p) => if p != c { a.swap(c, p); sign = -sign; },
        }
        for r in c + 1..n {
            let f = a[r][c] / a[c][c];
            for k in 0..n { a[r][k] -= f * a[c][k]; }
        }
    }
    for i in 0..n { sign *= a[i][i]; }
    (sign, a)
}
fn area(a: f64, b: f64, c: f64, d: f64) -> f64 {   // the moved square, from its corners
    let p = [(0.0, 0.0), (a, c), (a + b, c + d), (b, d)];
    let s: f64 = (0..4).map(|i| p[i].0 * p[(i + 1) % 4].1 - p[(i + 1) % 4].0 * p[i].1).sum();
    s.abs() / 2.0
}
fn mul(a: &Mat, b: &Mat) -> Mat {
    (0..2).map(|i| (0..2).map(|j| (0..2).map(|k| a[i][k] * b[k][j]).sum::<f64>()).collect()).collect()
}
fn mat(r: [[f64; 2]; 2]) -> Mat { vec![r[0].to_vec(), r[1].to_vec()] }
fn show2(m: &Mat) -> String { format!("[[{:.0}, {:.0}], [{:.0}, {:.0}]]", m[0][0], m[0][1], m[1][0], m[1][1]) }
fn row3(r: &[f64]) -> String { format!("[{}]", r.iter().map(|x| format!("{:.1}", x)).collect::<Vec<String>>().join(", ")) }
fn main() {
    let named: Vec<(&str, Mat)> = vec![
        ("shear", mat([[1.0, 1.0], [0.0, 1.0]])), ("cafe", mat([[2.0, 1.0], [1.0, 1.0]])),
        ("stretch", mat([[3.0, 0.0], [0.0, 2.0]])), ("mirror", mat([[0.0, 1.0], [1.0, 0.0]])),
        ("flattener", mat([[2.0, 4.0], [1.0, 2.0]]))];
    let m3: Mat = vec![vec![2.0, 1.0, 1.0], vec![0.0, 1.0, 1.0], vec![1.0, 0.0, 4.0]];
    println!("the sprite is the unit square, area 1; each matrix moves its four corners");
    for (name, m) in &named {
        let (a, b, c, d) = (m[0][0], m[0][1], m[1][0], m[1][1]);
        println!("  {:<10}{:<20}ad - bc = {:>2.0}   cofactor {:>5.1}   staircase {:>5.1}   area {:>4.1}",
                 name, show2(m), a * d - b * c, cofactor(m), staircase(m).0, area(a, b, c, d));
    }
    let (s, d, ds) = (&named[0].1, &named[2].1, mul(&named[2].1, &named[0].1));
    let sum: Mat = (0..2).map(|i| (0..2).map(|j| d[i][j] + s[i][j]).collect()).collect();
    println!("stretch after shear {:<20}det = {:.1} = 6 x 1", show2(&ds), cofactor(&ds));
    println!("stretch plus shear  {:<20}det = {:.1}, not 6 + 1 = 7", show2(&sum), cofactor(&sum));
    let t1 = m3[0][0] * (m3[1][1] * m3[2][2] - m3[1][2] * m3[2][1]);
    let t2 = -m3[0][1] * (m3[1][0] * m3[2][2] - m3[1][2] * m3[2][0]);
    let t3 = m3[0][2] * (m3[1][0] * m3[2][1] - m3[1][1] * m3[2][0]);
    let (d3, tri) = staircase(&m3);
    println!("3 by 3 [[2, 1, 1], [0, 1, 1], [1, 0, 4]]");
    println!("  cofactor along the top row: {:.1} {:+.1} {:+.1} = {:.1}", t1, t2, t3, cofactor(&m3));
    println!("  staircase rows: {} {} {}", row3(&tri[0]), row3(&tri[1]), row3(&tri[2]));
    println!("  diagonal: {:.1} x {:.1} x {:.1} = {:.1}", tri[0][0], tri[1][1], tri[2][2], d3);
    println!("mistakes on the cafe matrix: ad + bc gives {}, the diagonal gives {}", 2 * 1 + 1 * 1, 2 * 1);
    println!("mistake on the 3 by 3: all three cofactor terms added gives {:.1}", t1 - t2 + t3);
    println!("try changing: rows swapped {:.1}, corner 2.1 {:.1}, 3 by 3 top row doubled {:.1}",
             cofactor(&mat([[1.0, 1.0], [2.0, 1.0]])), cofactor(&mat([[2.0, 4.0], [1.0, 2.1]])),
             cofactor(&vec![vec![4.0, 2.0, 2.0], m3[1].clone(), m3[2].clone()]));
    assert!(named.iter().map(|(_, m)| cofactor(m)).collect::<Vec<f64>>() == vec![1.0, 1.0, 6.0, -1.0, 0.0]);
    assert!(named.iter().all(|(_, m)| (staircase(m).0 - cofactor(m)).abs() < 1e-12
        && (area(m[0][0], m[0][1], m[1][0], m[1][1]) - cofactor(m).abs()).abs() < 1e-12));
    assert!(cofactor(&m3) == 8.0 && (d3 - 8.0).abs() < 1e-12 && tri[2][2] == 4.0);
    assert!(cofactor(&ds) == 6.0 && cofactor(&ds) == cofactor(d) * cofactor(s) && cofactor(&sum) == 12.0);
    println!("ALL CHECKS PASS");
}
