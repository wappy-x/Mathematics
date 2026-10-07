// The inverse matrix -- the same check as the Python, in Rust.  No crates.  The cafe's counts
// matrix is inverted two ways: by the 2 by 2 swap-negate-divide formula, and by Gauss-Jordan
// on [A | I], the road that also handles the three-item matrix.
type Mat = Vec<Vec<f64>>;
fn num(v: f64) -> String { format!("{:.0}", if v.abs() > 1e-9 { v } else { 0.0 }) }   // no float dust
fn mat(m: &Mat) -> String {
    let rows: Vec<String> = m.iter().map(|r|
        format!("[{}]", r.iter().map(|v| num(*v)).collect::<Vec<_>>().join(", "))).collect();
    format!("[{}]", rows.join(", "))
}
fn vec_s(v: &[f64]) -> String { format!("({})", v.iter().map(|x| num(*x)).collect::<Vec<_>>().join(", ")) }
fn near(u: &[f64], w: &[f64]) -> bool { u.iter().zip(w).all(|(a, b)| (a - b).abs() < 1e-9) }
fn mul(a: &Mat, b: &Mat) -> Mat {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn mv(a: &Mat, v: &[f64]) -> Vec<f64> {
    (0..a.len()).map(|i| (0..v.len()).map(|k| a[i][k] * v[k]).sum()).collect()
}
fn det2(m: &Mat) -> f64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn flip(m: &Mat) -> Mat { vec![vec![m[1][1], -m[0][1]], vec![-m[1][0], m[0][0]]] }   // swap and negate
fn det3(m: &Mat) -> f64 { m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] *
    (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]) }

fn inverse(a: &Mat) -> Option<Mat> {                       // Gauss-Jordan on [A | I]
    let n = a.len();
    let mut m: Mat = (0..n).map(|i| { let mut row = a[i].clone();
        for j in 0..n { row.push(if i == j { 1.0 } else { 0.0 }); } row }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c + 1..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        if m[p][c].abs() < 1e-12 { return None; }          // a flattened column: no inverse
        m.swap(c, p);
        let d = m[c][c];
        for k in 0..2 * n { m[c][k] /= d; }
        for r in 0..n {
            if r == c { continue; }
            let f = m[r][c];
            for k in 0..2 * n { m[r][k] -= f * m[c][k]; }
        }
    }
    Some((0..n).map(|i| m[i][n..].to_vec()).collect())
}

fn main() {
    let a2: Mat = vec![vec![2.0, 1.0], vec![1.0, 1.0]];    // Mon: 2 coffees + 1 pastry
    let b2 = vec![11.0, 7.0];                              // the two days' takings
    let a3: Mat = vec![vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 1.0], vec![1.0, 2.0, 1.0]];
    let b3 = vec![17.0, 13.0, 16.0];                       // three days, three items
    let s: Mat = vec![vec![2.0, 4.0], vec![1.0, 2.0]];     // the singular one
    let (d2, gj2) = (det2(&a2), inverse(&a2).unwrap());    // road two: Gauss-Jordan
    let formula: Mat = flip(&a2).iter().map(|r| r.iter().map(|v| v / d2).collect()).collect();
    let x2 = mv(&formula, &b2);                            // road one: swap, negate, divide
    let cram = vec![det2(&vec![vec![b2[0], a2[0][1]], vec![b2[1], a2[1][1]]]) / d2,
                    det2(&vec![vec![a2[0][0], b2[0]], vec![a2[1][0], b2[1]]]) / d2];
    println!("cafe matrix A = {}   determinant = {}", mat(&a2), num(d2));
    println!("A^-1 by swap, negate, divide  = {}", mat(&formula));
    println!("A^-1 by Gauss-Jordan on [A|I] = {}", mat(&gj2));
    println!("A times A^-1 = {}   A^-1 times A = {}", mat(&mul(&a2, &formula)), mat(&mul(&formula, &a2)));
    println!("takings {} -> prices x = A^-1 b = {}", vec_s(&b2), vec_s(&x2));
    println!("the same prices by Cramer's rule: {}", vec_s(&cram));
    println!("and back the other way, A x = {}", vec_s(&mv(&a2, &x2)));
    let (d3, gj3) = (det3(&a3), inverse(&a3).unwrap());
    let x3 = mv(&gj3, &b3);
    println!("three items, A = {}   determinant = {}", mat(&a3), num(d3));
    println!("A^-1 by Gauss-Jordan on [A|I] = {}", mat(&gj3));
    println!("A times A^-1 = {}", mat(&mul(&a3, &gj3)));
    println!("takings {} -> prices x = {}", vec_s(&b3), vec_s(&x3));
    println!("mistake, no swap: prices come out {}", vec_s(&mv(&vec![vec![2.0, -1.0], vec![-1.0, 1.0]], &b2)));
    println!("mistake, no minus signs: prices come out {}", vec_s(&mv(&vec![vec![1.0, 1.0], vec![1.0, 2.0]], &b2)));
    let undivided: Mat = gj3.iter().map(|r| r.iter().map(|v| v * d3).collect()).collect();
    println!("mistake, no divide by the determinant: prices come out {}", vec_s(&mv(&undivided, &b3)));
    println!("singular {}: determinant = {}, swap-and-flip times it = {}, no inverse",
             mat(&s), num(det2(&s)), mat(&mul(&flip(&s), &s)));
    assert!(near(&x2, &[4.0, 3.0]) && near(&cram, &[4.0, 3.0]) && near(&mv(&a2, &x2), &b2));
    assert!(near(&formula.concat(), &gj2.concat()) && near(&mul(&a2, &gj2).concat(), &[1.0, 0.0, 0.0, 1.0]));
    assert!(near(&x3, &[4.0, 3.0, 6.0]) && near(&mv(&a3, &x3), &b3) && d3 == -1.0);
    assert!(inverse(&s).is_none() && det2(&s) == 0.0);
    println!("ALL CHECKS PASS");
}
