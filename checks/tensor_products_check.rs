// Tensor products -- the same check as the Python, in Rust.  No crates.  V
// holds week counts (2 weeks), W holds shopping lists (3 goods), and a tensor
// in V (x) W is a 2-by-3 table: how many of each good were bought each week.
type M = Vec<Vec<i64>>;
fn tensor(v: &[i64], w: &[i64]) -> M {     // v (x) w: every entry of v times every entry of w
    v.iter().map(|a| w.iter().map(|b| a * b).collect()).collect()
}
fn rank(rows: &M) -> usize {               // road one: count pivots, whole numbers only
    let (mut rows, mut r) = (rows.clone(), 0);
    for c in 0..rows[0].len() {
        let Some(p) = (r..rows.len()).find(|&i| rows[i][c] != 0) else { continue };
        rows.swap(r, p);
        for i in 0..rows.len() {
            if i != r {
                let (a, b) = (rows[r][c], rows[i][c]);
                rows[i] = (0..rows[0].len()).map(|k| rows[i][k] * a - rows[r][k] * b).collect();
            }
        }
        r += 1;
    }
    r
}
fn minors(t: &M) -> Vec<i64> {             // road two: every 2-by-2 cross-difference
    let mut out = vec![];
    for j in 0..3 { for k in j + 1..3 { out.push(t[0][j] * t[1][k] - t[0][k] * t[1][j]) } }
    out
}
fn kron(a: &M, b: &M) -> M {               // the Kronecker product, block by block
    a.iter().flat_map(|ra| b.iter().map(move |rb| ra.iter().flat_map(|x| rb.iter().map(move |y| x * y)).collect())).collect()
}
fn mat(a: &M, v: &[i64]) -> Vec<i64> { a.iter().map(|r| r.iter().zip(v).map(|(x, y)| x * y).sum()).collect() }
fn flat(t: &M) -> Vec<i64> { t.concat() }

fn found(t: &M) -> usize {                 // road three: search every small product
    let mut n = 0;
    for a in -3..4 { for b in -3..4 { for c in -3..4 { for d in -3..4 { for h in -3..4 {
        if tensor(&[a, b], &[c, d, h]) == *t { n += 1 }
    } } } } }
    n
}

fn main() {
    let (e, f): (M, M) = (vec![vec![1, 0], vec![0, 1]], vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, 1]]);
    let (v, w, p): (Vec<i64>, Vec<i64>, M) = (vec![1, 2], vec![3, 0, 1], vec![vec![3, 2, 4], vec![3, 2, 5]]);
    let t = tensor(&v, &w);
    let (s1, s2) = (tensor(&e[0], &f[0]), tensor(&e[1], &f[1]));
    let s: M = (0..2).map(|i| (0..3).map(|j| s1[i][j] + s2[i][j]).collect()).collect();
    let basis: M = e.iter().flat_map(|a| f.iter().map(|b| flat(&tensor(a, b)))).collect();
    let tables: Vec<M> = (0..729).map(|n: i64| (0..2).map(|i| (0..3).map(|j| n / 3_i64.pow(3 * i + j) % 3).collect()).collect()).collect();
    let simple = tables.iter().filter(|t| rank(t) <= 1).count();
    let beta = |x: &[i64], y: &[i64]| -> i64 { (0..2).map(|i| (0..3).map(|j| p[i][j] * x[i] * y[j]).sum::<i64>()).sum() };
    let bill = |t: &M| -> i64 { (0..2).map(|i| (0..3).map(|j| p[i][j] * t[i][j]).sum::<i64>()).sum() };
    let basis_bills: M = e.iter().map(|a| f.iter().map(|b| beta(a, b)).collect()).collect();
    let (a, b): (M, M) = (vec![vec![1, 0], vec![1, 1]], vec![vec![1, 0, 0], vec![0, 1, 0], vec![0, 0, 12]]);
    let k = kron(&a, &b);
    let (via_k, via_sides) = (mat(&k, &flat(&t)), flat(&tensor(&mat(&a, &v), &mat(&b, &w))));
    let q: Vec<Vec<f64>> = e.iter().map(|r| r.iter().map(|&x| 0.5_f64.sqrt() * x as f64).collect()).collect();
    let wrong = tensor(&[1, 1], &[1, 1, 0]);
    println!("basis tables e_i (x) f_j: {}; their rank: {}; 2 x 3 = {}", basis.len(), rank(&basis), 2 * 3);
    println!("(1, 2) (x) (3, 0, 1) = {:?}; rank {}; minors {:?}", t, rank(&t), minors(&t));
    println!("e1 (x) f1 + e2 (x) f2 = {:?}; rank {}; minors {:?}", s, rank(&s), minors(&s));
    println!("product search, entries -3 to 3: first table {} ways, second {}", found(&t), found(&s));
    println!("tables with entries 0, 1, 2: {}; simple (rank 0 or 1): {}", tables.len(), simple);
    println!("basis bills beta(e_i, f_j): {:?}", basis_bills);
    println!("bill from the pair: {}; from the table: {} (weeks {}, {}); second table: {}", beta(&v, &w), bill(&t),
             bill(&vec![t[0].clone(), vec![0; 3]]), bill(&vec![vec![0; 3], t[1].clone()]), bill(&s));
    println!("A (x) B is {} x {}; times the flat table: {:?}", k.len(), k[0].len(), via_k);
    println!("(Av) (x) (Bw) = {:?} (x) {:?} -> {:?}", mat(&a, &v), mat(&b, &w), via_sides);
    println!("qubit pair (e1 (x) e1 + e2 (x) e2)/sqrt 2: product test {:.4}, rank {}", q[0][0] * q[1][1] - q[0][1] * q[1][0], rank(&e));
    println!("mistake 1, dimension as 2 + 3: {}, not {}", 2 + 3, basis.len());
    println!("mistake 2, (e1 + e2) (x) (f1 + f2) = {:?}, rank {}", wrong, rank(&wrong));
    println!("mistake 3, B (x) A in place of A (x) B: {:?}", mat(&kron(&b, &a), &flat(&t)));
    assert!(rank(&basis) == basis.len() && basis.len() == 2 * 3);
    assert!(rank(&t) == 1 && minors(&t) == vec![0, 0, 0] && found(&t) > 0);
    assert!(rank(&s) == 2 && minors(&s)[0] != 0 && found(&s) == 0);
    assert!(simple == tables.iter().filter(|t| minors(t).iter().all(|&m| m == 0)).count());
    assert!(beta(&v, &w) == 41 && bill(&t) == 41);
    assert!(via_k == via_sides && via_k == vec![3, 0, 12, 9, 0, 36]);
    println!("ALL CHECKS PASS");
}
