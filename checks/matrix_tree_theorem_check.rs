// The matrix-tree theorem -- the same check as the Python, in Rust.  No crates.  Switches P, Q, R, W, cables every
// pair but R-W: trees by listing, cut determinant, Cauchy-Binet, eigenvalues; then the R-W resistance.
type Mat = Vec<Vec<i64>>;
type Cable = (usize, usize);

fn minor(m: &Mat, i: usize, j: usize) -> Mat {     // drop row i and column j
    m.iter().enumerate().filter(|(k, _)| *k != i).map(|(_, r)| r.iter().enumerate().filter(|(c, _)| *c != j).map(|(_, x)| *x).collect()).collect()
}
fn det(m: &Mat) -> i64 {                           // cofactor expansion along the top row
    if m.is_empty() { 1 } else { (0..m.len()).map(|j| if j % 2 == 0 { 1 } else { -1 } * m[0][j] * det(&minor(m, 0, j))).sum() }
}
fn choose<T: Clone>(items: &[T], k: usize) -> Vec<Vec<T>> { // every k-element subset, in order
    if k == 0 || items.len() < k { return if k == 0 { vec![vec![]] } else { vec![] } }
    let mut out: Vec<Vec<T>> = choose(&items[1..], k - 1).into_iter().map(|mut c| { c.insert(0, items[0].clone()); c }).collect();
    out.extend(choose(&items[1..], k));
    out
}
fn is_tree(n: usize, cables: &[Cable]) -> bool {   // n - 1 cables, and a flood from switch 0 reaches all
    let (mut seen, mut todo) = ((0..n).map(|v| v == 0).collect::<Vec<bool>>(), vec![0]);
    while let Some(u) = todo.pop() {
        for (x, y) in cables.iter().flat_map(|&(a, b)| [(a, b), (b, a)]) { if x == u && !seen[y] { seen[y] = true; todo.push(y) } }
    }
    cables.len() == n - 1 && seen.iter().all(|&s| s)
}
fn laplacian(n: usize, cables: &[Cable]) -> Mat {  // L = D - A
    let mut l = vec![vec![0; n]; n];
    for &(a, b) in cables { l[a][a] += 1; l[b][b] += 1; l[a][b] -= 1; l[b][a] -= 1 }
    l
}
fn charpoly(l: &Mat) -> Vec<i64> {                 // Faddeev-LeVerrier: coefficients of det(xI - L)
    let (n, mut c, mut m) = (l.len(), vec![1i64], vec![vec![0i64; l.len()]; l.len()]);
    for k in 1..=n as i64 {
        let last = *c.last().unwrap();
        m = (0..n).map(|i| (0..n).map(|j| (0..n).map(|t| l[i][t] * m[t][j]).sum::<i64>() + if i == j { last } else { 0 }).collect()).collect();
        c.push(-(0..n).map(|i| (0..n).map(|t| l[i][t] * m[t][i]).sum::<i64>()).sum::<i64>() / k);
    }
    c
}
fn name(s: &[Cable]) -> String { s.iter().map(|&(a, b)| format!("{}{}", &"PQRW"[a..a + 1], &"PQRW"[b..b + 1])).collect::<Vec<_>>().join(" ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn complete(k: usize) -> Vec<Cable> { choose(&(0..k).collect::<Vec<_>>(), 2).iter().map(|p| (p[0], p[1])).collect() }
fn main() {
    let (n, cables): (usize, Vec<Cable>) = (4, vec![(0, 1), (0, 2), (0, 3), (1, 2), (1, 3)]);
    let (l, sets) = (laplacian(n, &cables), choose(&cables, n - 1));
    let (l0, trees): (Mat, Vec<&Vec<Cable>>) = (minor(&l, 0, 0), sets.iter().filter(|s| is_tree(n, s)).collect());
    let m0: Mat = cables.iter().map(|&(a, b)| (1..n).map(|j| if j == a { 1 } else if j == b { -1 } else { 0 }).collect()).collect(); // column P cut
    let squares: Vec<i64> = sets.iter().map(|s| det(&s.iter().map(|e| m0[cables.iter().position(|c| c == e).unwrap()].clone()).collect()).pow(2)).collect();
    let mtm: Mat = (0..n - 1).map(|i| (0..n - 1).map(|j| m0.iter().map(|r| r[i] * r[j]).sum()).collect()).collect();
    let eig: Vec<(i64, Vec<i64>)> = vec![(0, vec![1, 1, 1, 1]), (2, vec![0, 0, 1, -1]), (4, vec![1, -1, 0, 0]), (4, vec![1, 1, -1, -1])];
    let eig_ok = eig.iter().all(|(lam, v)| (0..n).all(|i| (0..n).map(|t| l[i][t] * v[t]).sum::<i64>() == lam * v[i]));
    let (prod, cp) = (eig[1].0 * eig[2].0 * eig[3].0, charpoly(&l));
    let k4 = laplacian(4, &complete(4)); let (cp4, unsigned) = (charpoly(&k4), det(&minor(&k4.iter().map(|r| r.iter().map(|x| x.abs()).collect()).collect(), 0, 0)));
    let (merged, amps): (i64, Vec<i64>) = (det(&minor(&minor(&l, 3, 3), 2, 2)), l.iter().map(|r| r[2] - r[3]).collect()); // R, W cut; 1 V, -1 V
    let terms: Vec<i64> = (0..3).map(|j| if j % 2 == 0 { 1 } else { -1 } * l0[0][j] * det(&minor(&l0, 0, j))).collect();
    let (cuts, nt): (Vec<i64>, i64) = ((0..n).map(|i| det(&minor(&l, i, i))).collect(), trees.len() as i64);
    let loops: Vec<String> = sets.iter().filter(|s| !is_tree(n, s)).map(|s| name(s)).collect();
    println!("switches P Q R W; cables {}; degrees {:?}", name(&cables), (0..n).map(|i| l[i][i]).collect::<Vec<_>>());
    println!("Laplacian L = D - A, rows {:?}; row sums {:?}", l, l.iter().map(|r| r.iter().sum::<i64>()).collect::<Vec<_>>());
    println!("cut row and column P: {:?}; determinant {} - {} - {} = {}", l0, terms[0], -terms[1], -terms[2], det(&l0));
    println!("cut P, Q, R, W in turn: {:?}; nothing cut: {}", cuts, det(&l));
    println!("listing: {} choices of 3 cables, {} trees; loops: {}", sets.len(), trees.len(), loops.join(", "));
    println!("signed incidence M, column P cut: M^T M equals the cut Laplacian: {}", yn(mtm == l0));
    println!("Cauchy-Binet, det(M_S)^2 over the {} sets: {:?}, total {}", sets.len(), squares, squares.iter().sum::<i64>());
    println!("eigenvalues {:?} checked by L v = lambda v: {}; {}/{} = {}", eig.iter().map(|e| e.0).collect::<Vec<_>>(), yn(eig_ok), prod, n, prod / n as i64);
    println!("det(xI - L) coefficients {:?}; x coefficient {}, so {}/{} = {}", cp, cp[3], -cp[3], n, -cp[3] / n as i64);
    println!("add R-W, the full K4: cut determinant {}; det(xI - L) coefficients {:?}, so {}/4 = {}", det(&minor(&k4, 0, 0)), cp4, -cp4[3], -cp4[3] / 4);
    let rows: Vec<(usize, i64, i64, Vec<i64>, Vec<i64>)> = (2..8).map(|k| (k, det(&minor(&laplacian(k, &complete(k)), 0, 0)), choose(&complete(k), k - 1).iter().filter(|s| is_tree(k, s)).count() as i64,
        charpoly(&laplacian(k, &complete(k))), (0..k).map(|j| choose(&(0..k - 1).collect::<Vec<_>>(), j).len() as i64 * (-(k as i64)).pow(j as u32)).chain([0]).collect())).collect(); // x(x - k)^(k-1)
    for (k, d, t, c, e) in &rows { println!("K{}: cut determinant {}, listed {}, n^(n-2) {}; det(xI - L) = x(x - {})^{}: {}", k, d, t, (*k as i64).pow(*k as u32 - 2), k, k - 1, yn(c == e)) }
    println!("1-ohm cables, R to W: trees with R and W merged {}, over {} trees = {} ohm; 1 V at R, -1 V at W: currents {:?}, 2 V / {} A = {} ohm", merged, nt, merged as f64 / nt as f64, amps, amps[2], 2.0 / amps[2] as f64);
    println!("mistake 1, diagonal only {}*{}*{} = {}; mistake 2, eigenvalues not divided by n: {}", l0[0][0], l0[1][1], l0[2][2], l0[0][0] * l0[1][1] * l0[2][2], prod);
    println!("mistake 3, Cayley's 4^2 here: {}, not {}; mistake 4, signs dropped on K4: {}, not {}", 4i64.pow(2), trees.len(), unsigned, det(&minor(&k4, 0, 0)));
    assert!(det(&l0) == nt && squares.iter().sum::<i64>() == nt && mtm == l0);   // three roads agree
    assert!(cuts.iter().all(|&c| c == nt));                                       // any row and column
    assert!(eig_ok && prod == -cp[3] && -cp[3] == n as i64 * nt);                 // the eigenvalue roads, exactly
    assert!(rows.iter().all(|(k, d, t, c, e)| d == t && *t == (*k as i64).pow(*k as u32 - 2) && c == e && (-1i64).pow(*k as u32 - 1) * c[k - 1] == *k as i64 * t)); // Cayley, three roads
    assert!(det(&minor(&k4, 0, 0)) == rows[2].2 && -cp4[3] == 4 * rows[2].2 && unsigned == 20);
    assert!(amps == vec![0, 0, amps[2], -amps[2]] && merged * amps[2] == 2 * nt);     // resistance, two roads
    println!("ALL CHECKS PASS");
}
