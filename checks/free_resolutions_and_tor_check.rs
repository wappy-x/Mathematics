// Free resolutions and Tor -- the same check as the Python, in Rust.  No crates.  Over Z,
// tensoring a free resolution with N = Z/n turns each Z^k into (Z/n)^k and keeps the
// integer matrices, so every kernel and image is found by listing all vectors.  Over
// Q[x], multiplication by f on Q[x]/(g) is an integer matrix with an exact rank.
use std::collections::BTreeSet;
type M = Vec<Vec<i64>>;

fn vectors(k: usize, n: i64) -> M {                  // every vector of (Z/n)^k
    if k == 0 { return vec![vec![]] }
    vectors(k - 1, n).into_iter().flat_map(|v| (0..n).map(move |a| [v.clone(), vec![a]].concat())).collect()
}
fn apply(mat: &M, v: &[i64], n: i64) -> Vec<i64> {   // a matrix (list of rows) times v, mod n
    mat.iter().map(|row| row.iter().zip(v).map(|(a, b)| a * b).sum::<i64>().rem_euclid(n)).collect()
}
fn kernel(mat: &M, k: usize, n: i64) -> M {          // the vectors a matrix sends to 0, and all it hits
    vectors(k, n).into_iter().filter(|v| apply(mat, v, n).iter().all(|&x| x == 0)).collect()
}
fn image(mat: &M, k: usize, n: i64) -> BTreeSet<Vec<i64>> {
    vectors(k, n).iter().map(|v| apply(mat, v, n)).collect()
}
fn matmul(a: &M, b: &M) -> M {
    a.iter().map(|row| (0..b[0].len()).map(|j| row.iter().zip(b).map(|(x, r)| x * r[j]).sum()).collect()).collect()
}
fn tor(ranks: &[usize], ds: &[M], n: i64) -> Vec<usize> {   // sizes of Tor_0, Tor_1, ... against Z/n
    let mut sizes = Vec::new();
    for (i, &k) in ranks.iter().enumerate() {
        let d_out: M = if i > 0 { ds[i - 1].clone() } else { vec![] };   // d_i : F_i -> F_(i-1)
        let (d_in, k_in): (M, usize) = if i < ds.len() { (ds[i].clone(), ranks[i + 1]) } else { (vec![vec![]; k], 0) };
        sizes.push(kernel(&d_out, k, n).len() / image(&d_in, k_in, n).len());
    }
    sizes
}
fn gcd(xs: &[i64]) -> i64 {                          // Euclid's algorithm, over a whole list
    let mut a = 0;
    for &x in xs { let mut b = x; while b != 0 { let t = a % b; a = b; b = t } }
    a.abs()
}
fn pmul(a: &[i64], b: &[i64]) -> Vec<i64> {          // polynomials: coefficient lists, constant first
    let mut out = vec![0; a.len() + b.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { out[i + j] += x * y } }
    out
}
fn pmod(a: &[i64], g: &[i64]) -> Vec<i64> {          // remainder on dividing by the monic g
    let mut a = a.to_vec();
    while a.len() >= g.len() {
        let c = a.pop().unwrap();
        let base = a.len() + 1 - g.len();
        for i in 0..g.len() - 1 { a[base + i] -= c * g[i] }
    }
    while a.len() < g.len() - 1 { a.push(0) }
    a
}
fn mulmat(f: &[i64], g: &[i64]) -> M {              // multiplication by f on Q[x]/(g), basis 1, x, ...
    let d = g.len() - 1;
    let cols: M = (0..d).map(|j| { let mut m = vec![0; j]; m.push(1); pmod(&pmul(&m, f), g) }).collect();
    (0..d).map(|i| cols.iter().map(|c| c[i]).collect()).collect()
}
fn rank(m: &M) -> usize {                            // fraction-free elimination over the integers
    let (mut m, mut r) = (m.clone(), 0);
    for c in 0..m[0].len() {
        let p = match (r..m.len()).find(|&i| m[i][c] != 0) { Some(p) => p, None => continue };
        m.swap(r, p);
        for i in r + 1..m.len() {
            let (a, b) = (m[r][c], m[i][c]);
            m[i] = (0..m[i].len()).map(|j| a * m[i][j] - b * m[r][j]).collect();
        }
        r += 1;
    }
    r
}
fn prim(mut a: Vec<i64>) -> Vec<i64> {               // drop top zeros and the content; lead positive
    while a.last() == Some(&0) { a.pop(); }
    if a.is_empty() { return a }
    let (c, s) = (gcd(&a), a[a.len() - 1].signum());
    a.iter().map(|x| x / c * s).collect()
}
fn pgcd(a: &[i64], b: &[i64]) -> Vec<i64> {          // Euclid with pseudo-remainders
    let (mut a, mut b) = (prim(a.to_vec()), prim(b.to_vec()));
    while !b.is_empty() {
        let mut r = a.clone();
        while r.len() >= b.len() {
            let (k, lr, lb) = (r.len() - b.len(), r[r.len() - 1], b[b.len() - 1]);
            r = prim(r.iter().enumerate().map(|(j, x)| lb * x - lr * if j >= k { b[j - k] } else { 0 }).collect());
        }
        a = std::mem::replace(&mut b, r);
    }
    a
}
fn show(p: &[i64]) -> String {                       // a polynomial, leading term first
    let mut s = String::new();
    for e in (0..p.len()).rev() {
        let c = p[e]; if c == 0 { continue }
        let mut body = if c.abs() != 1 || e == 0 { c.abs().to_string() } else { String::new() };
        if e > 0 { body.push('x') }
        if e > 1 { body += &format!("^{}", e) }
        s += if !s.is_empty() { if c < 0 { " - " } else { " + " } } else if c < 0 { "-" } else { "" };
        s += &body;
    }
    s
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn name(size: usize) -> String { if size == 1 { "0".to_string() } else { format!("Z/{}", size) } }

fn main() {
    let (da, db1, db2): (M, M, M) = (vec![vec![4]], vec![vec![4, 4]], vec![vec![1], vec![-1]]);
    let (ta, tb) = (tor(&[1, 1], &[da.clone()], 6), tor(&[1, 2, 1], &[db1.clone(), db2.clone()], 6));
    let tn = tor(&[1, 1], &[vec![vec![6]]], 4);
    let lost: Vec<i64> = kernel(&da, 1, 6).iter().map(|v| v[0]).collect();
    let exact_b = matmul(&db1, &db2) == vec![vec![0]]
        && (-12..13).all(|a: i64| (-12..13).all(|b: i64| 4 * a + 4 * b != 0 || b == -a));
    let (phi1, psi1, h1): (M, M, M) = (vec![vec![1], vec![0]], vec![vec![1, 1]], vec![vec![0, -1]]);
    let one_minus_phipsi: M = matmul(&phi1, &psi1).iter().enumerate()
        .map(|(i, row)| row.iter().enumerate().map(|(j, x)| (i == j) as i64 - x).collect()).collect();
    let chain = [matmul(&db1, &phi1) == da, matmul(&da, &psi1) == db1, matmul(&psi1, &phi1) == vec![vec![1]]];
    let homotopy = [one_minus_phipsi == matmul(&db2, &h1), matmul(&h1, &db2) == vec![vec![1]]];
    let cls = apply(&phi1, &[3], 6);
    let cls_out = !image(&db2, 1, 6).contains(&cls);
    let sweep = (1..13).all(|m: i64| (1..13).all(|n: i64| {
        let g = gcd(&[m, n]) as usize;
        kernel(&vec![vec![m]], 1, n).len() == g && kernel(&vec![vec![n]], 1, m).len() == g
            && n as usize / image(&vec![vec![m]], 1, n).len() == g }));
    let d2: M = vec![vec![1, 1], vec![1, -1], vec![-1, -1]];   // Klein bottle: rows edges a, b, c; columns U, L
    let mut minors = Vec::new();
    for i in 0..3 { for j in i + 1..3 { minors.push(d2[i][0] * d2[j][1] - d2[i][1] * d2[j][0]) } }
    let (kg1, kg2) = (gcd(&d2.concat()), gcd(&minors));
    let (klein_mod2, klein_tor, klein_tensor) = (kernel(&d2, 2, 2).len(), kernel(&vec![vec![2]], 1, 2).len(), 1usize << (2 - rank(&d2)));
    let (f, g) = (vec![-1, 0, 1], vec![2, -3, 1]);
    let (mf, mg) = (mulmat(&f, &g), mulmat(&g, &f));
    let (dim1, dim1_other, h) = (2 - rank(&mf), 2 - rank(&mg), pgcd(&f, &g));
    let v = vec![-2, 1];
    let (kills, acts_as_1) = (pmod(&pmul(&v, &f), &g) == vec![0, 0], pmod(&pmul(&[0, 1], &v), &g) == v);
    let wrong1: Vec<i64> = (0..3).filter(|a| 4 * a % 6 == 0).collect();   // Z/3 --x4--> Z/6
    let hit: Vec<i64> = (0..3).map(|a| 4 * a % 12).collect::<BTreeSet<i64>>().into_iter().collect();
    let exact_wrong = hit == (0..12).filter(|b| b % 4 == 0).collect::<Vec<i64>>();
    let wrong2 = (0..6).filter(|a| a % 2 == 0).count() / (0..6).map(|a| 4 * a % 6).collect::<BTreeSet<i64>>().len();
    println!("M = Z/4, N = Z/6, over Z");
    println!("resolution A, 0 -> Z --x4--> Z: Tor_0 = {}, Tor_1 = {}", name(ta[0]), name(ta[1]));
    println!("  Tor_1 is the kernel of x4 on Z/6: {:?}; its image is {:?}", lost, image(&da, 1, 6).iter().map(|t| t[0]).collect::<Vec<i64>>());
    println!("resolution B, 0 -> Z --(1, -1)--> Z^2 --(4 4)--> Z: d1 d2 = 0 and exact on |a|, |b| <= 12: {}", yn(exact_b));
    println!("  tensored with Z/6: kernel of (4 4) has {} elements, image of (1, -1) has {}", kernel(&db1, 2, 6).len(), image(&db2, 1, 6).len());
    println!("  Tor_0 = {}, Tor_1 = {}, Tor_2 = {}", name(tb[0]), name(tb[1]), name(tb[2]));
    println!("resolve Z/6 instead, tensor with Z/4: kernel of x6 on Z/4 {:?}; Tor_0 = {}, Tor_1 = {}", kernel(&vec![vec![6]], 1, 4).iter().map(|v| v[0]).collect::<Vec<i64>>(), name(tn[0]), name(tn[1]));
    println!("gcd(4, 6) = {}", gcd(&[4, 6]));
    println!("comparison maps phi1 = (1, 0), psi1 = (1, 1): chain maps {}, {}; psi1 phi1 = 1: {}", yn(chain[0]), yn(chain[1]), yn(chain[2]));
    println!("  1 - phi1 psi1 = d2 h1 and 1 - phi2 psi2 = h1 d2, with h1 = (0, -1): {}, {}", yn(homotopy[0]), yn(homotopy[1]));
    println!("  phi1 sends the Tor_1 class 3 to ({}, {}), outside the image of (1, -1): {}", cls[0], cls[1], yn(cls_out));
    println!("sweep m, n = 1 to 12: kernel = other side = cokernel = gcd(m, n), all 144 pairs: {}", yn(sweep));
    println!("Klein bottle: d2 = {:?}; 2 by 2 minors {:?}", d2, minors);
    println!("  invariant factors {}, {}, so H_1 = Z + Z/2; a minor is nonzero, so H_2 over Z = 0", kg1, kg2 / kg1);
    println!("  H_2 with Z/2 coefficients, by listing chains: {} elements, so {}", klein_mod2, name(klein_mod2));
    println!("  universal coefficients: 0 + Tor_1(Z/2, Z/2), and Tor_1(Z/2, Z/2) has {} elements", klein_tor);
    println!("over Q[x]: f = {}, g = {}", show(&f), show(&g));
    println!("  multiplication by f on Q[x]/(g), basis 1, x: {:?}, rank {}", mf, rank(&mf));
    println!("  Tor_1 dimension {}, Tor_0 dimension {}; resolving the other side: {}", dim1, 2 - rank(&mf), dim1_other);
    println!("  gcd(f, g) by Euclid: {}, degree {}", show(&h), h.len() - 1);
    println!("  {} spans the kernel: f({}) = 0 mod g: {}; x acts on it as 1: {}", show(&v), show(&v), yn(kills), yn(acts_as_1));
    println!("mistake 1, non-free 0 -> Z/3 --x4--> Z/12 (exact: {}) tensored with Z/6: kernel {:?}, Tor_1 reads 0", yn(exact_wrong), wrong1);
    println!("mistake 2, keeping Z/4 in the tensored sequence: Tor_0 reads {}, truth {}", name(wrong2), name(ta[0]));
    println!("mistake 3, Z/4 x Z/6 taken as Z/24: {} elements, truth {}", 4 * 6, ta[0]);
    println!("mistake 4, Klein H_2 mod 2 by tensoring only: {}, truth {}", name(klein_tensor), name(klein_mod2));
    let g46 = gcd(&[4, 6]) as usize;
    assert!(ta[1] == g46 && tb[1] == g46 && tn[1] == g46 && ta[0] == g46 && tb[0] == g46 && tn[0] == g46);
    assert!(tb[2] == 1 && lost == vec![0, 3] && exact_b);                  // Tor_2 = 0; kernel {0, 3}
    assert!(chain.iter().all(|&c| c) && homotopy.iter().all(|&c| c) && cls_out);
    assert!(sweep && klein_mod2 == 2 && klein_tor == 2 && kg2 / kg1 == 2); // gcd rule; universal coefficients
    assert!(dim1 == 1 && dim1_other == 1 && h.len() - 1 == 1 && kills && acts_as_1);
    assert!(wrong1 == vec![0] && exact_wrong && wrong2 == 1 && klein_tensor == 1);   // the mistakes really differ
    println!("ALL CHECKS PASS");
}
