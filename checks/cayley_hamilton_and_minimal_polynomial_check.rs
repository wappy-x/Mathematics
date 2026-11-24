// Cayley-Hamilton and the minimal polynomial -- the same check in Rust.  No crates; whole numbers only.
type Mat = Vec<Vec<i64>>;
fn eye(n: usize, c: i64) -> Mat { (0..n).map(|i| (0..n).map(|j| if i == j { c } else { 0 }).collect()).collect() }
fn mul(x: &Mat, y: &Mat) -> Mat { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn add(x: &Mat, y: &Mat, c: i64) -> Mat { x.iter().zip(y).map(|(r, s)| r.iter().zip(s).map(|(a, b)| a + c * b).collect()).collect() }
fn big(x: &Mat) -> i64 { x.iter().flatten().map(|v| v.abs()).max().unwrap() }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn at(p: &[i64], x: &Mat) -> Mat {     // Horner: put the matrix in for x; a constant c becomes c I
    if p.len() == 1 { eye(x.len(), p[0]) } else { add(&mul(&at(&p[..p.len() - 1], x), x), &eye(x.len(), p[p.len() - 1]), 1) } }
fn charpoly(x: &Mat) -> Vec<i64> {     // road one, Faddeev-LeVerrier: traces only, no roots
    let (n, mut p, mut nn) = (x.len(), vec![1i64], eye(x.len(), 0));
    for k in 1..=n {
        nn = add(&mul(x, &nn), &eye(n, *p.last().unwrap()), 1);
        let xn = mul(x, &nn);
        p.push(-(0..n).map(|i| xn[i][i]).sum::<i64>() / k as i64);
    }
    p
}
fn det(x: &Mat) -> i64 {               // road two, expansion along the top row
    if x.len() == 1 { return x[0][0] }
    (0..x.len()).map(|j| (1 - 2 * (j % 2) as i64) * x[0][j] * det(&x[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect())).sum()
}
fn pmul(p: &[i64], q: &[i64]) -> Vec<i64> {
    (0..p.len() + q.len() - 1).map(|k| (0..p.len()).filter(|&i| k >= i && k - i < q.len()).map(|i| p[i] * q[k - i]).sum()).collect() }
fn pdiv(p: &[i64], m: &[i64]) -> (Vec<i64>, Vec<i64>) {   // long division by a monic m: quotient, remainder
    let (mut p, mut q) = (p.to_vec(), vec![]);
    while p.len() >= m.len() { q.push(p[0]); p = (1..p.len()).map(|i| p[i] - p[0] * if i < m.len() { m[i] } else { 0 }).collect() }
    (q, p)
}
fn repeated(p: &[i64]) -> bool {
    let slope: Vec<i64> = p[..p.len() - 1].iter().enumerate().map(|(i, c)| c * (p.len() - 1 - i) as i64).collect();
    [2, 3].iter().any(|&t| big(&at(p, &vec![vec![t]])) == 0 && big(&at(&slope, &vec![vec![t]])) == 0)
}
fn rank(rows: &Mat) -> usize {         // elimination in whole numbers: cross-multiply, never divide
    let rows: Mat = rows.iter().filter(|r| r.iter().any(|v| *v != 0)).cloned().collect();
    if rows.is_empty() { return 0 }; let (p, c) = (&rows[0], rows[0].iter().position(|v| *v != 0).unwrap());
    1 + rank(&rows[1..].iter().map(|r| r.iter().zip(p).map(|(x, y)| p[c] * x - r[c] * y).collect()).collect())
}
fn tri() -> Vec<i64> { pmul(&[1, -2], &pmul(&[1, -2], &[1, -3])) }
fn minpoly(x: &Mat) -> Vec<i64> {      // road one: divisors of (x - 2)^2 (x - 3), lowest degree first
    [pmul(&[1, -2], &[1, -3]), tri()].into_iter().find(|p| big(&at(p, x)) == 0).unwrap()
}
fn krylov(x: &Mat) -> usize {          // road two: the first power that is a mix of the lower ones
    let mut pw = vec![eye(3, 1)];
    while rank(&pw.iter().map(|q| q.concat()).collect()) == pw.len() { let nx = mul(x, pw.last().unwrap()); pw.push(nx) }
    pw.len() - 1
}
fn vecs(x: &Mat) -> Vec<usize> { [2, 3].iter().map(|&t| 3 - rank(&add(x, &eye(3, 1), -t))).collect() }
fn main() {
    let a: Mat = vec![vec![2, 1, 0], vec![0, 2, 0], vec![0, 0, 3]];
    let d: Mat = vec![vec![2, 0, 0], vec![0, 2, 0], vec![0, 0, 3]];
    let m: Mat = vec![vec![2, -1, 0, 3], vec![1, 0, 4, 1], vec![0, 5, -2, 2], vec![3, 1, 1, 1]];   // no pattern
    let f: Mat = vec![vec![8, 3], vec![2, 7]];                                                   // the fleet times 10
    let (pa, pd, pm, ma, md) = (charpoly(&a), charpoly(&d), charpoly(&m), minpoly(&a), minpoly(&d));
    let (s, t, (q, r), x4) = (add(&a, &eye(3, 1), -2), add(&a, &eye(3, 1), -3), pdiv(&pd, &md), pdiv(&[1, 0, 0, 0, 0], &md).1);
    let cols: Vec<usize> = [s.clone(), mul(&s, &s), mul(&mul(&s, &s), &t)].iter().map(|x| (0..3).filter(|&j| x.iter().all(|row| row[j] == 0)).count()).collect();
    let (inv12, fleet, d4, p10) = (at(&[1, -7, 16], &a), add(&mul(&f, &f), &f, -15), mul(&mul(&d, &d), &mul(&d, &d)), [&[1][..], &[0; 10]].concat());
    let (va, vd) = (vecs(&a), vecs(&d));
    println!("A: characteristic polynomial by traces {:?}; from the diagonal 2, 2, 3: {:?}", pa, tri());
    println!("zero columns: after (A - 2I) {}, after (A - 2I)^2 {}, after (A - 2I)^2 (A - 3I) {}; p(A) largest entry: {}", cols[0], cols[1], cols[2], big(&at(&pa, &a)));
    println!("4 by 4 M: characteristic polynomial {:?}, det by expansion {}; p(M) largest entry: {}", pm, det(&m), big(&at(&pm, &m)));
    println!("D: characteristic polynomial {:?}; p_D divided by m_D: quotient {:?}, remainder {:?}", pd, q, r);
    println!("minimal polynomial by divisor search: A {:?}, D {:?}; degree by first repeating power: A {}, D {}", ma, md, krylov(&a), krylov(&d));
    println!("repeated root in the minimal polynomial: A {}, D {}", yn(repeated(&ma)), yn(repeated(&md)));
    println!("eigenvectors for 2 and 3, by 3 minus rank: A {:?}, D {:?}; diagonalisable: A {}, D {}", va, vd, yn(va.iter().sum::<usize>() == 3), yn(vd.iter().sum::<usize>() == 3));
    println!("x^4 divided by m_D leaves {:?}; D^4 = 65D - 114I: {}", x4, yn(d4 == add(&eye(3, -114), &d, 65)));
    println!("12 A^-1 = A^2 - 7A + 16I = {:?}; times A gives 12 I: {}", inv12, yn(mul(&inv12, &a) == eye(3, 12)));
    println!("tenth powers, top row: A^10 {:?}, D^10 {:?}", at(&p10, &a)[0], at(&p10, &d)[0]);
    let fc: Vec<f64> = charpoly(&f).iter().enumerate().map(|(k, c)| *c as f64 / 10f64.powi(k as i32)).collect();
    println!("fleet F: characteristic polynomial {:?}; F^2 - 1.5F + 0.5I largest entry: {:?}", fc, big(&add(&fleet, &eye(2, 50), 1)) as f64 / 100.0);
    println!("mistake 1, (A - 2I)(A - 3I) = {:?}, not zero", mul(&s, &t));
    println!("mistake 2, the trace through the same substitution: 3A - 7I = {:?}", add(&eye(3, -7), &a, 3));
    println!("mistake 3, fleet with 0.5 added to every entry: {:?}", fleet.iter().map(|r| r.iter().map(|x| (x + 50) as f64 / 100.0).collect::<Vec<f64>>()).collect::<Vec<_>>());
    assert!(pa == tri() && pm[4] == det(&m) && pm[1] == -(0..4).map(|i| m[i][i]).sum::<i64>());   // traces against diagonal, det, trace
    assert!(big(&at(&pa, &a)) == 0 && big(&at(&pm, &m)) == 0 && cols == vec![1, 2, 3] && big(&add(&fleet, &eye(2, 50), 1)) == 0); // Cayley-Hamilton
    assert!([ma.len() - 1, md.len() - 1] == [krylov(&a), krylov(&d)] && krylov(&d) == 2 && krylov(&a) == 3 && r == vec![0, 0]);
    assert!([va.iter().sum::<usize>() == 3, vd.iter().sum::<usize>() == 3] == [!repeated(&ma), !repeated(&md)]);
    assert!(d4 == add(&eye(3, x4[1]), &d, x4[0]) && mul(&inv12, &a) == eye(3, 12));             // remainders against brute force
    println!("ALL CHECKS PASS");
}
