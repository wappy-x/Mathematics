// Cramer's rule and the adjugate -- the same check as the Python, in Rust.  No crates.  The cafe's
// prices come out three ways: Cramer's ratios of determinants, the adjugate times the takings over
// det A, and plain elimination.  Every multiply and divide is counted, to compare the costs.
use std::sync::atomic::{AtomicU64, Ordering::Relaxed};
type Mat = Vec<Vec<f64>>;
static OPS: AtomicU64 = AtomicU64::new(0);  // multiplies and divides done so far
fn det(m: &Mat) -> f64 {                    // cofactor expansion along the top row
    if m.len() == 1 { return m[0][0]; }
    OPS.fetch_add(m.len() as u64, Relaxed);
    (0..m.len()).map(|j| {
        let sub: Mat = m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect();
        (if j % 2 == 0 { 1.0 } else { -1.0 }) * m[0][j] * det(&sub)
    }).sum()
}
fn with_col(m: &Mat, j: usize, v: &[f64]) -> Mat { m.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r[j] = v[i]; r }).collect() }
fn minor(m: &Mat, i: usize, j: usize) -> Mat { m.iter().enumerate().filter(|(k, _)| *k != i).map(|(_, r)| [&r[..j], &r[j + 1..]].concat()).collect() }
fn cofactors(m: &Mat, s: usize) -> Mat { (0..m.len()).map(|i| (0..m.len()).map(|j| (if s * (i + j) % 2 == 0 { 1.0 } else { -1.0 }) * det(&minor(m, i, j))).collect()).collect() }
fn flip(m: &Mat) -> Mat { (0..m[0].len()).map(|j| m.iter().map(|r| r[j]).collect()).collect() }
fn mul(p: &Mat, q: &Mat) -> Mat { p.iter().map(|r| (0..q[0].len()).map(|j| (0..q.len()).map(|k| r[k] * q[k][j]).sum()).collect()).collect() }
fn mv(p: &Mat, v: &[f64]) -> Vec<f64> { p.iter().map(|r| r.iter().zip(v).map(|(a, b)| a * b).sum()).collect() }
fn cramer(m: &Mat, v: &[f64]) -> Vec<f64> {   // road 1: one determinant over another, n times
    let d = det(m); OPS.fetch_add(m.len() as u64, Relaxed);
    (0..m.len()).map(|j| det(&with_col(m, j, v)) / d).collect()
}
fn eliminate(m: &Mat, v: &[f64]) -> Vec<f64> {   // road 3: elimination, then back-substitution
    let n = m.len();
    let mut t: Mat = m.iter().enumerate().map(|(i, r)| { let mut r = r.clone(); r.push(v[i]); r }).collect();
    for k in 0..n { for i in k + 1..n {
        let f = t[i][k] / t[k][k]; OPS.fetch_add((1 + n - k) as u64, Relaxed);
        for j in k + 1..n + 1 { t[i][j] -= f * t[k][j]; } } }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { OPS.fetch_add((n - i) as u64, Relaxed); x[i] = (t[i][n] - (i + 1..n).map(|j| t[i][j] * x[j]).sum::<f64>()) / t[i][i]; }
    x
}
fn g(x: f64) -> String { if x.fract() == 0.0 { format!("{}", x as i64) } else { format!("{}", x) } }
fn vec_s(v: &[f64]) -> String { format!("({})", v.iter().map(|x| g(*x)).collect::<Vec<_>>().join(", ")) }
fn mat(m: &Mat) -> String { format!("[{}]", m.iter().map(|r| { let s = vec_s(r); format!("[{}]", &s[1..s.len() - 1]) }).collect::<Vec<_>>().join(", ")) }
fn p(n: u128) -> u128 { if n == 1 { 0 } else { n * (p(n - 1) + 1) } }   // products in one expansion
fn cost(n: u128) -> (u128, u128) { ((n + 1) * p(n) + n, (1..=n).map(|m| m * m - 1).sum::<u128>() + n * (n + 1) / 2) }
fn sci(x: f64) -> String { let e = format!("{}", x as u128).len() as i32 - 1; format!("{:.2} x 10^{}", x / 10f64.powi(e), e) }
fn ops() -> u64 { OPS.swap(0, Relaxed) }
fn main() {
    let a: Mat = vec![vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 2.0], vec![1.0, 2.0, 1.0]];
    let b = [13.0, 11.0, 12.0];   // a row per day: coffee, pastry, juice; takings in dollars
    let (d, x1, c, dets): (f64, Vec<f64>, Mat, Vec<f64>) = (det(&a), cramer(&a, &b), cofactors(&a, 1), (0..3).map(|j| det(&with_col(&a, j, &b))).collect());
    let adj = flip(&c); let x2: Vec<f64> = mv(&adj, &b).iter().map(|v| v / d).collect();
    let (x3, inv): (Vec<f64>, Mat) = (eliminate(&a, &b), adj.iter().map(|r| r.iter().map(|v| v / d).collect()).collect());
    println!("cafe A = {}   takings b = {}   det A = {}", mat(&a), vec_s(&b), g(d));
    let tops: Vec<String> = [("A".to_string(), a.clone())].into_iter().chain((0..3).map(|j| (format!("A_{}", j + 1), with_col(&a, j, &b))))
        .map(|(k, m)| format!("{} {}", k, (0..3).map(|j| format!("{:+}", (if j == 1 { -1.0 } else { 1.0 }) * m[0][j] * det(&minor(&m, 0, j)))).collect::<Vec<_>>().join(" "))).collect();
    println!("takings put in column 1, 2, 3: determinants {}; Cramer: prices {}\ntop-row terms: {}", vec_s(&dets), vec_s(&x1), tops.join("; "));
    println!("cofactor table C = {}   adjugate = C flipped = {}", mat(&c), mat(&adj));
    println!("adj(A) b = {}   A adj(A) = {} = adj(A) A", vec_s(&mv(&adj, &b)), mat(&mul(&a, &adj)));
    println!("inverse = adj(A) / det A = {}", mat(&inv));
    println!("adjugate road: prices {}   elimination road: {}   A x = {}", vec_s(&x2), vec_s(&x3), vec_s(&mv(&a, &x1)));
    for n in [3usize, 4, 6] {               // count the work on a test system, then match the formulas
        let m: Mat = (0..n).map(|i| (0..n).map(|j| if i == j { n as f64 } else { 1.0 }).collect()).collect();
        let v: Vec<f64> = (1..=n).map(|k| k as f64).collect();
        ops(); cramer(&m, &v); let cr = ops(); eliminate(&m, &v); let el = ops(); assert!((cr as u128, el as u128) == cost(n as u128));
        println!("n = {}: Cramer by cofactors {} products, elimination {} (counted = formula)", n, cr, el);
    }
    let (c10, c20, y) = (cost(10), cost(20), 1e9 * 31557600.0);
    println!("n = 10: Cramer {}, elimination {}; at a billion a second {:.3} seconds", sci(c10.0 as f64), c10.1, c10.0 as f64 / 1e9);
    println!("n = 20: Cramer {}, elimination {}; Cramer {:.0} years", sci(c20.0 as f64), c20.1, c20.0 as f64 / y);
    let (s, bs, z) = (vec![vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 1.0], vec![1.0, 2.0, 1.0]], [17.0, 13.0, 16.0], vec![vec![2.0, 1.0, 1.0], vec![1.0, 1.0, 2.0], vec![3.0, 2.0, 3.0]]);
    let plain: Vec<f64> = mv(&flip(&cofactors(&a, 0)), &b).iter().map(|v| v / d).collect();
    let wrong: Vec<f64> = mv(&cofactors(&s, 1), &bs).iter().map(|v| v / det(&s)).collect();
    println!("mistakes: minors with no signs {}; sandwich cafe, table not flipped {} not {}", vec_s(&plain), vec_s(&wrong), vec_s(&cramer(&s, &bs)));
    println!("singular cafe {}, takings (13, 11, 24): det {}, column determinants {}", mat(&z), g(det(&z)),
        vec_s(&(0..3).map(|j| det(&with_col(&z, j, &[13.0, 11.0, 24.0]))).collect::<Vec<f64>>()));
    let sw: Mat = vec![a[0].clone(), a[2].clone(), a[1].clone()];
    println!("try changing: Monday $14 {}; Tue and Wed swapped det {} prices {}; n = 25 Cramer {} years",
        vec_s(&cramer(&a, &[14.0, 11.0, 12.0])), g(det(&sw)), vec_s(&cramer(&sw, &[13.0, 12.0, 11.0])), sci(cost(25).0 as f64 / y));
    assert!(d == -4.0 && dets == vec![-16.0, -12.0, -8.0] && x1 == vec![4.0, 3.0, 2.0] && mv(&a, &x1) == b.to_vec());
    assert!(mv(&adj, &b) == dets && x2 == x1 && x3.iter().zip(&x1).all(|(p, q)| (p - q).abs() < 1e-12));
    let id = |k: f64| -> Mat { (0..3).map(|i| (0..3).map(|j| if i == j { k } else { 0.0 }).collect()).collect() };
    assert!(mul(&a, &adj) == id(d) && mul(&adj, &a) == id(d) && cramer(&s, &bs) == vec![4.0, 3.0, 6.0] && det(&z) == 0.0 && mul(&a, &inv) == id(1.0));
    assert!(mul(&s, &flip(&cofactors(&s, 1))) == id(-1.0));   // s is lopsided: the flip matters
    println!("ALL CHECKS PASS");
}
