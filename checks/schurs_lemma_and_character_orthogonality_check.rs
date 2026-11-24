// Schur's lemma and character orthogonality -- the same check as the Python, in
// Rust.  No crates.  The tile's 8 moves are built from the quarter turn R and the
// flip F as 2 by 2 matrices; each move also shuffles the 4 corners, a 4 by 4 matrix.
type M = Vec<Vec<i64>>; type Ch = Box<dyn Fn(&M) -> i64>;
fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).map(|k| a[i][k] * b[k][j]).sum()).collect()).collect()
}
fn tr(m: &M) -> i64 { (0..m.len()).map(|i| m[i][i]).sum() }
fn det(g: &M) -> i64 { g[0][0] * g[1][1] - g[0][1] * g[1][0] }
const CORNERS: [(i64, i64); 4] = [(-1, 1), (1, 1), (1, -1), (-1, -1)]; // clockwise from top left
fn corner(g: &M) -> M {                          // column j: where corner j lands
    let act = |p: (i64, i64)| (g[0][0] * p.0 + g[0][1] * p.1, g[1][0] * p.0 + g[1][1] * p.1);
    (0..4).map(|i| (0..4).map(|j| (act(CORNERS[j]) == CORNERS[i]) as i64).collect()).collect()
}
fn diag_sign(g: &M) -> i64 {                     // how g acts on (1, -1, 1, -1)
    let s = vec![1, -1, 1, -1];
    let v: Vec<i64> = corner(g).iter().map(|row| row.iter().zip(&s).map(|(c, x)| c * x).sum()).collect();
    assert!(v == s || v == s.iter().map(|x| -x).collect::<Vec<i64>>());
    v[0]
}
fn name(g: &M) -> usize { if tr(g) == 2 { 0 } else if tr(g) == -2 { 1 } else if det(g) == 1 { 2 } else if g[0][0] == 0 { 3 } else { 4 } }
fn main() {
    let (i2, r, f): (M, M, M) = (vec![vec![1, 0], vec![0, 1]], vec![vec![0, -1], vec![1, 0]], vec![vec![1, 0], vec![0, -1]]);
    let (mut g_all, mut n): (Vec<M>, usize) = (vec![i2.clone()], 0);
    while n < g_all.len() {                      // close up under R and F
        for h in [mul(&r, &g_all[n]), mul(&f, &g_all[n])] { if !g_all.contains(&h) { g_all.push(h) } }
        n += 1;
    }
    let inv = |g: &M| -> M { g_all.iter().find(|h| mul(g, h) == i2).unwrap().clone() };
    let mut classes: Vec<Vec<M>> = Vec::new();
    for g in &g_all {
        let mut c: Vec<M> = Vec::new();
        for h in &g_all { let x = mul(&mul(h, g), &inv(h)); if !c.contains(&x) { c.push(x) } }
        c.sort();
        if !classes.contains(&c) { classes.push(c) }
    }
    classes.sort_by_key(|c| name(&c[0]));
    assert!(classes.iter().enumerate().all(|(k, c)| c.iter().all(|g| name(g) == k))); // conjugation agrees with names
    let (size, rep): (Vec<i64>, Vec<M>) = (classes.iter().map(|c| c.len() as i64).collect(), classes.iter().map(|c| c[0].clone()).collect());
    let chars: Vec<(&str, Ch)> = vec![("trivial", Box::new(|_: &M| 1)), ("flip sign", Box::new(det)),
        ("diagonal sign", Box::new(diag_sign)), ("edge sign", Box::new(|g: &M| det(g) * diag_sign(g))), ("floor", Box::new(tr))];
    let by_classes = |a: &dyn Fn(&M) -> i64, b: &dyn Fn(&M) -> i64| -> i64 { size.iter().zip(&rep).map(|(n, g)| n * a(g) * b(g)).sum() };
    let by_moves = |a: &dyn Fn(&M) -> i64, b: &dyn Fn(&M) -> i64| -> i64 { g_all.iter().map(|g| a(g) * b(&inv(g))).sum() };
    let chi = |g: &M| tr(&corner(g));
    let on = |a: &dyn Fn(&M) -> i64| -> Vec<i64> { rep.iter().map(|g| a(g)).collect() };
    println!("{} moves; classes by conjugation, sizes {:?}", g_all.len(), size);
    println!("corner character, trace of each shuffle: {:?}", on(&chi));
    for (k, (n, a)) in chars.iter().enumerate() {
        let row: Vec<i64> = chars.iter().map(|(_, b)| by_classes(a, b)).collect();
        assert!(row == chars.iter().map(|(_, b)| by_moves(a, b)).collect::<Vec<i64>>() && row == (0..5).map(|j| 8 * (j == k) as i64).collect::<Vec<i64>>()); // two roads; 8 x identity
        println!("{:13} {:?}  8 x inner products: {:?}", n, on(a), row);
    }
    let raw: Vec<i64> = chars.iter().map(|(_, b)| by_classes(&chi, b)).collect();
    let m: Vec<i64> = raw.iter().map(|x| x / 8).collect();
    assert!(chars.iter().map(|(_, b)| by_moves(&chi, b)).collect::<Vec<i64>>() == m.iter().map(|x| 8 * x).collect::<Vec<i64>>());
    println!("corner against each, by classes and by moves: {:?} / 8 = {:?}", raw, m);
    let dims: i64 = m.iter().zip(&chars).map(|(x, (_, a))| x * a(&i2)).sum();
    println!("<corner, corner> = {}/8 = {}; dimensions {}", by_classes(&chi, &chi), by_classes(&chi, &chi) / 8, dims);
    let (t, s): (M, M) = (vec![vec![3, 1], vec![4, 1]], vec![vec![5, 7]]);
    let avg: M = (0..2).map(|i| (0..2).map(|j| g_all.iter().map(|g| mul(&mul(g, &t), &inv(g))[i][j]).sum::<i64>() / 8).collect()).collect();
    println!("Schur average, floor to floor, of {:?}: {:?}, trace {}/2 = {}", t, avg, tr(&t), tr(&t) / 2);
    let avg_s: Vec<i64> = (0..2).map(|j| g_all.iter().map(|g| mul(&s, &inv(g))[0][j]).sum::<i64>()).collect(); // 8 x the average
    println!("Schur average, floor to trivial, of {:?}: {:?}", s[0], avg_s.iter().map(|v| v / 8).collect::<Vec<i64>>());
    let mut grid: Vec<M> = Vec::new();
    for a in -2..3 { for b in -2..3 { for c in -2..3 { for d in -2..3 { grid.push(vec![vec![a, b], vec![c, d]]) } } } }
    let comm: Vec<&M> = grid.iter().filter(|t| g_all.iter().all(|g| mul(t, g) == mul(g, t))).collect();
    let diag: Vec<i64> = comm.iter().map(|t| t[0][0]).collect();
    println!("of {} small matrices, {} commute with all 8 floor moves: {:?} times I", grid.len(), comm.len(), diag);
    let dropped: i64 = rep.iter().map(|g| chi(g)).sum();
    println!("mistake 1, class sizes dropped: {} / 8 = {}", dropped, dropped as f64 / 8.0);
    println!("mistake 2, divided by 5 classes: 8 / 5 = {}", by_classes(&chi, &chars[0].1) as f64 / 5.0);
    let pair = |g: &M| 1 + tr(g);                // trivial and floor together, not irreducible
    println!("mistake 3, against trivial + floor {:?}: {}", on(&pair), by_classes(&chi, &pair) / 8);
    assert!(size == vec![1, 1, 2, 2, 2] && m == vec![1, 0, 1, 0, 1] && dims == 4); // corner = trivial + diagonal sign + floor
    assert!(by_classes(&chi, &chi) == 8 * m.iter().map(|x| x * x).sum::<i64>()); // <chi, chi> = sum of squares
    assert!(avg == vec![vec![2, 0], vec![0, 2]] && avg_s == vec![0, 0] && diag == vec![-2, -1, 0, 1, 2]); // Schur: trace / 2, or 0
    assert!(comm.iter().all(|t| t[0][1] == 0 && t[1][0] == 0 && t[0][0] == t[1][1])); // only multiples of I commute
    println!("ALL CHECKS PASS");
}
