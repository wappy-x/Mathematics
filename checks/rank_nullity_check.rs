// Rank and nullity -- the same check as rank_nullity_check.py, in Rust.  No crates.
// P is the projector: a 3D model in, a flat screen picture out; B flattens harder.
// Two roads to the rank: the staircase's pivots, or the biggest square block whose
// determinant is not zero.  Same rows, same labels, same numbers as the Python.
type Mat = Vec<Vec<f64>>;
fn combos(xs: &[usize], k: usize) -> Vec<Vec<usize>> {   // every k of the items, in order
    if k == 0 || xs.len() < k { return if k == 0 { vec![vec![]] } else { vec![] }; }
    let mut out: Vec<Vec<usize>> = combos(&xs[1..], k - 1).into_iter()
        .map(|c| [vec![xs[0]], c].concat()).collect();
    out.extend(combos(&xs[1..], k)); out
}
fn det(m: &Mat) -> f64 {                                 // determinant, expanding the top row
    if m.len() == 1 { return m[0][0]; }
    (0..m.len()).map(|j| {
        let minor: Mat = m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect();
        (if j % 2 == 0 { 1.0 } else { -1.0 }) * m[0][j] * det(&minor)
    }).sum()
}
fn staircase(a: &Mat) -> (Mat, Vec<usize>) {             // legal row moves, until a pivot stands alone
    let (mut m, mut piv, mut r) = (a.clone(), Vec::new(), 0usize);
    for c in 0..a[0].len() {
        let s = match (r..m.len()).find(|&i| m[i][c].abs() > 1e-9) {
            None => continue, Some(i) => i };             // no pivot in this column: it is free
        m.swap(r, s);
        let pv = m[r][c]; for x in m[r].iter_mut() { *x /= pv; }
        for i in 0..m.len() {
            let f = m[i][c];
            if i != r { for j in 0..m[i].len() { m[i][j] -= f * m[r][j]; } }
        }
        piv.push(c); r += 1;
    }
    (m, piv) }
fn killed(a: &Mat) -> Mat {                              // one direction per column with no pivot
    let ((m, piv), n, mut out) = (staircase(a), a[0].len(), Vec::new());
    for j in (0..n).filter(|c| !piv.contains(c)) {
        let mut v = vec![0.0; n]; v[j] = 1.0;
        for (i, &c) in piv.iter().enumerate() { v[c] = 0.0 - m[i][j]; }
        out.push(v); }
    out
}
fn rank_by_blocks(a: &Mat) -> usize {                    // road 2: no elimination in here at all
    let (rows, cols): (Vec<usize>, Vec<usize>) = ((0..a.len()).collect(), (0..a[0].len()).collect());
    for k in (1..=rows.len().min(cols.len())).rev() {
        for rs in combos(&rows, k) { for cs in combos(&cols, k) {
            let blk: Mat = rs.iter().map(|&i| cs.iter().map(|&j| a[i][j]).collect()).collect();
            if det(&blk).abs() > 1e-9 { return k; }
        } }
    }
    0
}
fn apply(a: &Mat, v: &[f64]) -> Vec<f64> { a.iter().map(|r| r.iter().zip(v).map(|(x, y)| x * y).sum()).collect() }
fn show(v: &[f64]) -> String { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn report(name: &str, a: &Mat) -> (usize, Mat) {
    let (piv, ks, n) = (staircase(a).1, killed(a), a[0].len());
    println!("{}: {} rows x {} columns", name, a.len(), n);
    println!("  pivot columns             {}", piv.iter().map(|c| (c + 1).to_string()).collect::<Vec<_>>().join(", "));
    println!("  rank, by pivots           {}", piv.len());
    println!("  rank, by biggest block    {}", rank_by_blocks(a));
    println!("  nullity                   {}", ks.len());
    println!("  killed directions         {}", ks.iter().map(|v| show(v)).collect::<Vec<_>>().join(", "));
    println!("  rank + nullity            {} + {} = {} = columns", piv.len(), ks.len(), piv.len() + ks.len());
    (piv.len(), ks)
}
fn main() {
    let p: Mat = vec![vec![1.0, 0.0, 0.0], vec![0.0, 1.0, 0.0]];   // keeps across and up, kills depth
    let b: Mat = vec![vec![1.0, 2.0, 3.0], vec![2.0, 4.0, 6.0]];   // row 2 is twice row 1
    let (r_p, k_p) = report("projector P = [[1, 0, 0], [0, 1, 0]]", &p);
    let (r_b, k_b) = report("flattener B = [[1, 2, 3], [2, 4, 6]]", &b);
    let (front, back) = ([3.0, 4.0, 5.0], [3.0, 4.0, 9.0]);
    println!("two model points            {} and {} both land on {}", show(&front), show(&back), show(&apply(&p, &front)));
    println!("their difference            {} = 4 x {}, a killed direction", show(&[0.0, 0.0, 4.0]), show(&k_p[0]));
    println!("every model point there     x = {} + t x {}", show(&[3.0, 4.0, 0.0]), show(&k_p[0]));
    println!("mistakes: rows - rank gives nullity {} for P; B's {} nonzero rows read as rank {} give {} + {} = {}, not {}",
             p.len() - r_p, b.len(), b.len(), b.len(), k_b.len(), b.len() + k_b.len(), b[0].len());
    assert!(r_p == rank_by_blocks(&p) && r_b == rank_by_blocks(&b));           // two roads, one rank
    assert!(r_p + k_p.len() == p[0].len() && r_b + k_b.len() == b[0].len());   // the theorem itself
    for (a, ks) in [(&p, &k_p), (&b, &k_b)] { for v in ks { assert!(apply(a, v).iter().all(|x| x.abs() < 1e-9)); } }
    assert!(apply(&p, &front) == apply(&p, &back) && apply(&p, &front) == vec![3.0, 4.0]);
    println!("ALL CHECKS PASS");
}
