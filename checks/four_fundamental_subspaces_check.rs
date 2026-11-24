// The four fundamental subspaces -- the same check as the Python, in Rust.  No crates.
// A bakery: a small batch uses 1 kg butter, 2 sugar, 3 flour; a double batch twice that.
// Bases by elimination and by brute force; each stock report b is judged three ways.
type M = Vec<Vec<f64>>;
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn times(m: &M, v: &[f64]) -> Vec<f64> { m.iter().map(|row| dot(row, v)).collect() }
fn staircase(a: &M) -> (M, Vec<usize>) {           // row moves until each pivot stands alone
    let (mut m, mut piv, mut r) = (a.clone(), Vec::new(), 0);
    for c in 0..m[0].len() {
        let s = match (r..m.len()).find(|&i| m[i][c].abs() > 1e-9) { Some(s) => s, None => continue };
        m.swap(r, s);
        let lead = m[r][c]; m[r] = m[r].iter().map(|x| x / lead).collect();
        for i in 0..m.len() {
            if i != r { let f = m[i][c]; m[i] = m[i].iter().zip(&m[r]).map(|(a, b)| a - f * b).collect(); }
        }
        piv.push(c); r += 1;
    }
    (m, piv)
}
fn null_basis(a: &M) -> M {                        // one killed direction per free column
    let ((r, piv), n) = (staircase(a), a[0].len());
    (0..n).filter(|c| !piv.contains(c)).map(|j| {
        let mut v = vec![0.0; n]; v[j] = 1.0;
        for (i, &c) in piv.iter().enumerate() { v[c] = -r[i][j]; }
        v
    }).collect()
}
fn num(x: f64) -> String {
    if (x - x.round()).abs() < 1e-9 { format!("{}", x.round() as i64) } else { format!("{:.4}", x) }
}
fn show(v: &[f64]) -> String { format!("({})", v.iter().map(|&x| num(x)).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn main() {
    let a: M = vec![vec![1.0, 2.0], vec![2.0, 4.0], vec![3.0, 6.0]];
    let t: M = (0..2).map(|j| a.iter().map(|row| row[j]).collect()).collect();   // A^T
    let (r, piv) = staircase(&a); let rank = piv.len();
    let rows: M = r[..rank].to_vec();                                       // row space
    let cols: M = piv.iter().map(|&c| a.iter().map(|row| row[c]).collect()).collect();
    let (nul, lnul) = (null_basis(&a), null_basis(&t));                      // null, left null
    let grid: Vec<f64> = (-3..4).map(|k| k as f64).collect();             // road 2: brute force
    let (mut nul_bf, mut lnul_bf): (M, M) = (Vec::new(), Vec::new());
    for &p in &grid { for &q in &grid {
        if (p, q) != (0.0, 0.0) && times(&a, &[p, q]) == vec![0.0; 3] { nul_bf.push(vec![p, q]); }
        for &w in &grid {
            if (p, q, w) != (0.0, 0.0, 0.0) && times(&t, &[p, q, w]) == vec![0.0; 2] { lnul_bf.push(vec![p, q, w]); }
        }
    } }
    let on_nul = nul_bf.iter().all(|v| *v == nul[0].iter().map(|x| v[1] * x).collect::<Vec<f64>>());
    let on_lnul = lnul_bf.iter().all(|v| *v == (0..3).map(|i| v[1] * lnul[0][i] + v[2] * lnul[1][i]).collect::<Vec<f64>>());
    let mut perp: Vec<f64> = rows.iter().flat_map(|r| nul.iter().map(move |z| dot(r, z))).collect();
    perp.extend(cols.iter().flat_map(|c| lnul.iter().map(move |y| dot(c, y))));
    let ashow: Vec<String> = a.iter().map(|row| format!("[{}]", row.iter().map(|&x| num(x)).collect::<Vec<_>>().join(", "))).collect();
    println!("A = [{}]: rank {}; row space {}; null space {}", ashow.join(", "), rank, show(&rows[0]), show(&nul[0]));
    println!("column space {}; left null space {}, {}", show(&cols[0]), show(&lnul[0]), show(&lnul[1]));
    println!("sizes: {} + {} = {} inputs, {} + {} = {} outputs", rank, nul.len(), t.len(), rank, lnul.len(), a.len());
    println!("perpendicular pairs, every dot product: {}", show(&perp));
    println!("brute force -3..3: {} null, {} left null, all built from the bases: {}", nul_bf.len(), lnul_bf.len(), yn(on_nul && on_lnul));
    let x = [3.0, 1.0];
    let part: Vec<f64> = rows[0].iter().map(|tt| dot(&x, &rows[0]) / dot(&rows[0], &rows[0]) * tt).collect();
    let rest: Vec<f64> = x.iter().zip(&part).map(|(p, q)| p - q).collect();
    println!("order {} = row part {} + null part {}; kg used {} and {}", show(&x), show(&part), show(&rest), show(&times(&a, &x)), show(&times(&a, &part)));
    let mut verdicts = Vec::new();
    for b in [[1.0, 0.0, 0.0], [5.0, 10.0, 15.0], [1.0, 2.0, 0.0]] {
        let tests: Vec<f64> = lnul.iter().map(|y| dot(y, &b)).collect();
        let augm: M = a.iter().zip(&b).map(|(row, &bi)| { let mut r = row.clone(); r.push(bi); r }).collect();
        let aug = staircase(&augm).1.len();
        let p: Vec<f64> = cols[0].iter().map(|tt| dot(&b, &cols[0]) / dot(&cols[0], &cols[0]) * tt).collect();
        let left: Vec<f64> = b.iter().zip(&p).map(|(bi, pi)| bi - pi).collect(); let gap = dot(&left, &left).sqrt();
        assert!(times(&t, &left).iter().all(|v| v.abs() < 1e-9)); verdicts.push((tests.iter().all(|t| t.abs() < 1e-9), aug == rank, gap < 1e-9));
        println!("b = {}: tests {}, rank [A | b] {}, nearest {}", show(&b), show(&tests), aug, show(&p));
        println!("   leftover {}, length {}, A^T leftover {}", show(&left), num(gap), show(&times(&t, &left)));
    }
    println!("mistake, a column as the test: {} . (5, 10, 15) = {}", show(&cols[0]), num(dot(&cols[0], &[5.0, 10.0, 15.0])));
    println!("mistake, counting rows as the rank: nullity {} - {} = {}", t.len(), a.len(), t.len() as i64 - a.len() as i64);
    assert!(rank == 1 && staircase(&nul_bf).1.len() + rank == t.len() && lnul.len() + rank == a.len());
    assert!(on_nul && on_lnul && nul_bf.len() == 2 && perp.iter().all(|p| p.abs() < 1e-12));
    assert!(verdicts == vec![(false, false, false), (true, true, true), (false, false, false)]);
    assert!(times(&a, &x) == times(&a, &[1.0, 2.0]) && dot(&lnul[0], &[1.0, 0.0, 0.0]) == -2.0);
    println!("ALL CHECKS PASS");
}
