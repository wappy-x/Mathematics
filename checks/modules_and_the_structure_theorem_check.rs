// Modules and the structure theorem -- the same check as the Python, in Rust.  No crates.
// M is Z^3 modulo two relations.  Road 1: Smith form by moves whole numbers undo (Bezout's
// 2-by-2 move where an entry fails to divide).  Road 2: gcds of minors.  Road 3: the size of
// M/qM, by listing every mix of the relations mod q.  Then put the answer back in.
type Mat = Vec<Vec<i64>>;
const R1: [i64; 3] = [2, 2, 2];
const R2: [i64; 3] = [4, -2, -2];

fn fdiv(a: i64, b: i64) -> i64 { a.div_euclid(b) - if b < 0 && a % b != 0 { 1 } else { 0 } }   // Python's //

fn bezout(mut a: i64, mut b: i64) -> (i64, i64, i64) {   // s*a + t*b = g = gcd(a, b)
    let (mut s0, mut s1, mut t0, mut t1) = (1, 0, 0, 1);
    while b != 0 {
        let q = fdiv(a, b);
        (a, b, s0, s1, t0, t1) = (b, a - q * b, s1, s0 - q * s1, t1, t0 - q * t1);
    }
    if a > 0 { (s0, t0, a) } else { (-s0, -t0, -a) }
}

fn gcd(a: i64, b: i64) -> i64 { bezout(a, b).2 }

fn mv(a: i64, b: i64) -> [i64; 4] {                // a 2-by-2 move of determinant 1: (a, b) -> (g, 0)
    if b % a == 0 { return [1, 0, -(b / a), 1]; }  // plain subtraction
    let (s, t, g) = bezout(a, b);                  // Bezout's move: the pivot shrinks to g
    [s, t, -b / g, a / g]
}

fn rows(m: &mut Mat, i: usize, j: usize, c: [i64; 4]) {  // rows i, j -> s*i + t*j, u*i + v*j
    let (ri, rj) = (m[i].clone(), m[j].clone());
    m[i] = ri.iter().zip(&rj).map(|(x, y)| c[0] * x + c[1] * y).collect();
    m[j] = ri.iter().zip(&rj).map(|(x, y)| c[2] * x + c[3] * y).collect();
}

fn cols(m: &mut Mat, i: usize, j: usize, c: [i64; 4]) {  // the same move on columns
    for r in m.iter_mut() { (r[i], r[j]) = (c[0] * r[i] + c[1] * r[j], c[2] * r[i] + c[3] * r[j]) }
}

fn eye(n: usize) -> Mat { (0..n).map(|i| (0..n).map(|j| (i == j) as i64).collect()).collect() }

fn smith(a: &Mat) -> (Mat, Mat, Mat) {             // returns S, D, T with S A T = D
    let (m, n) = (a.len(), a[0].len());
    let (mut d, mut s, mut t) = (a.clone(), eye(m), eye(n));
    for k in 0..m.min(n) {
        loop {
            let mut best: Option<(i64, usize, usize)> = None;
            for i in k..m { for j in k..n {
                if d[i][j] != 0 && best.map_or(true, |b| d[i][j].abs() < b.0) { best = Some((d[i][j].abs(), i, j)) }
            } }
            let Some((_, p, q)) = best else { return (s, d, t) };   // smallest entry is the pivot
            rows(&mut d, k, p, [0, 1, 1, 0]); rows(&mut s, k, p, [0, 1, 1, 0]);
            cols(&mut d, k, q, [0, 1, 1, 0]); cols(&mut t, k, q, [0, 1, 1, 0]);
            for i in k + 1..m { let c = mv(d[k][k], d[i][k]); rows(&mut d, k, i, c); rows(&mut s, k, i, c); }
            for j in k + 1..n { let c = mv(d[k][k], d[k][j]); cols(&mut d, k, j, c); cols(&mut t, k, j, c); }
            if (k + 1..m).any(|i| d[i][k] != 0) { continue }   // a Bezout column move refilled it
            let bad: Vec<usize> = (k + 1..m).filter(|&i| (k + 1..n).any(|j| d[i][j] % d[k][k] != 0)).collect();
            if bad.is_empty() { break }            // else fold the offending row into the pivot row
            rows(&mut d, k, bad[0], [1, 1, 0, 1]); rows(&mut s, k, bad[0], [1, 1, 0, 1]);
        }
        if d[k][k] < 0 { rows(&mut d, k, k, [-1, 0, -1, 0]); rows(&mut s, k, k, [-1, 0, -1, 0]); }   // -1 is a unit
    }
    (s, d, t)
}

fn mul(a: &Mat, b: &Mat) -> Mat { a.iter().map(|r| (0..b[0].len()).map(|j| r.iter().zip(b).map(|(x, br)| x * br[j]).sum()).collect()).collect() }

fn det(m: &Mat) -> i64 {
    if m.len() == 1 { return m[0][0] }
    (0..m.len()).map(|j| {
        let minor: Mat = m[1..].iter().map(|r| [&r[..j], &r[j + 1..]].concat()).collect();
        (if j % 2 == 0 { 1 } else { -1 }) * m[0][j] * det(&minor)
    }).sum()
}

fn subsets(n: usize, k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]] }
    (0..n).flat_map(|x| subsets(x, k - 1).into_iter().map(move |mut p| { p.push(x); p })).collect()
}

fn invariants(a: &Mat) -> Vec<i64> {               // road 2: d_k = g_k / g_(k-1), g_k = gcd of k-by-k minors
    let (mut out, mut prev) = (vec![], 1);
    for k in 1..=a.len().min(a[0].len()) {
        let mut g = 0;
        for rs in subsets(a.len(), k) { for cs in subsets(a[0].len(), k) {
            g = gcd(g, det(&rs.iter().map(|&r| cs.iter().map(|&c| a[r][c]).collect()).collect()));
        } }
        if g == 0 { break }
        out.push(g / prev); prev = g;
    }
    out
}

fn size_mod(r1: [i64; 3], r2: [i64; 3], n: i64) -> i64 {   // road 3: |(Z/n)^3 / span|, by listing
    let mut span: Vec<Vec<i64>> = vec![];
    for a in 0..n { for b in 0..n {
        let v: Vec<i64> = (0..3).map(|i| (a * r1[i] + b * r2[i]).rem_euclid(n)).collect();
        if !span.contains(&v) { span.push(v) }
    } }
    n.pow(3) / span.len() as i64
}

fn in_span(v: [i64; 3]) -> bool { (-12..=12).any(|a: i64| (-12..=12).any(|b: i64| (0..3).all(|i| a * R1[i] + b * R2[i] == v[i]))) }   // a whole-number mix?

fn order(v: [i64; 3]) -> i64 { (1..31).find(|&k| in_span([k * v[0], k * v[1], k * v[2]])).unwrap_or(0) }   // 0: none up to 30

fn phi(v: [i64; 3]) -> (i64, i64, i64) { (v[0].rem_euclid(2), (v[0] - v[1]).rem_euclid(6), v[2] - v[1]) }

fn diag(d: &Mat) -> Vec<i64> { (0..2).map(|i| d[i][i]).filter(|&x| x != 0).collect() }

fn main() {
    let a: Mat = (0..3).map(|i| vec![R1[i], R2[i]]).collect();   // the relations as columns
    let (s, d, t) = smith(&a);
    let dg = diag(&d);
    println!("relations r1 = ({}, {}, {}), r2 = ({}, {}, {}); relation matrix A = {:?}", R1[0], R1[1], R1[2], R2[0], R2[1], R2[2], a);
    println!("S = {:?}, det {}; T = {:?}, det {}", s, det(&s), t, det(&t));
    println!("S A T = {:?}; diagonal {:?}; free rank {}", mul(&mul(&s, &a), &t), dg, 3 - dg.len());
    let inv = invariants(&a);
    println!("road 2, minors: invariant factors {:?}; g1 = {}, g2 = {}", inv, inv[0], inv[0] * inv[1]);
    println!("M = Z (+) Z/2 (+) Z/6 = Z (+) Z/2 (+) Z/2 (+) Z/3, through (x, y, z) -> (x mod 2, (x - y) mod 6, z - y)");
    let sizes: Vec<i64> = (1..13).map(|n| size_mod(R1, R2, n)).collect();
    let pred: Vec<i64> = (1..13).map(|n| n * gcd(n, 2) * gcd(n, 6)).collect();
    println!("road 3, |M/qM| for q = 1..12 by listing: {:?}", sizes);
    println!("predicted q * gcd(q, 2) * gcd(q, 6):      {:?}", pred);
    let boxed: Vec<[i64; 3]> = (0..2197).map(|c| [c / 169 - 6, c / 13 % 13 - 6, c % 13 - 6]).collect();
    let zero_mix: Vec<[i64; 3]> = boxed.iter().copied().filter(|&v| in_span(v)).collect();
    let zero_phi: Vec<[i64; 3]> = boxed.iter().copied().filter(|&v| phi(v) == (0, 0, 0)).collect();
    println!("triples in the box -6..6 that are mixes: {}; sent to zero: {}", zero_mix.len(), zero_phi.len());
    println!("phi(r1) = {:?}, phi(r2) = {:?}; phi(e1), phi(e2), phi(e3) = {:?}, {:?}, {:?}",
             phi(R1), phi(R2), phi([1, 0, 0]), phi([0, 1, 0]), phi([0, 0, 1]));
    let tests = [[1, 0, 0], [3, 3, 3], [0, 1, 1], [0, 0, 1]];
    for v in tests {
        let o = order(v);
        let shown = if o == 0 { "infinite (none up to 30)".to_string() } else { o.to_string() };
        println!("order of ({}, {}, {}): {}", v[0], v[1], v[2], shown);
    }
    let mut tors: Vec<(i64, i64)> = vec![];
    for x in 0..12 { for y in 0..12 { let p = phi([x, y, y]); if !tors.contains(&(p.0, p.1)) { tors.push((p.0, p.1)) } } }
    let orders: Vec<i64> = tors.iter().map(|&(a, b)| (1..13).find(|k| k * a % 2 == 0 && k * b % 6 == 0).unwrap()).collect();
    let maxo = *orders.iter().max().unwrap();
    println!("torsion part: {} members, largest order {}", tors.len(), maxo);
    let (mut w, mut qrank) = (a.clone(), 0);       // rank over Q, by fraction-free elimination
    for c in 0..2 {
        if let Some(p) = (qrank..3).find(|&r| w[r][c] != 0) {
            w.swap(qrank, p);
            for r in qrank + 1..3 {
                let (top, low) = (w[qrank].clone(), w[r].clone());
                w[r] = low.iter().zip(&top).map(|(x, y)| top[c] * x - low[c] * y).collect();
            }
            qrank += 1;
        }
    }
    println!("mistake 1, Smith over Q: rank {}, diagonal {:?}; M reads Q^{}, torsion lost", qrank, vec![1; qrank], 3 - qrank);
    println!("mistake 2, torsion read as Z/12: Z/12 has order 12, M only {}; |M/2M| = {}, Z (+) Z/12 gives {}",
             maxo, sizes[1], 2 * gcd(2, 12));
    let dd = invariants(&vec![vec![2, 4], vec![2, 4], vec![2, 4]]);
    println!("mistake 3, free rank 3 - 2 = 1: r2 = (4, 4, 4) gives diagonal {:?}, free rank {}", dd, 3 - dd.len());
    for r2 in [[2, 4, -2], [6, 3, 0], [3, 5, 7]] {
        let b: Mat = (0..3).map(|i| vec![R1[i], r2[i]]).collect();
        let road1 = diag(&smith(&b).1);
        println!("r2 = ({}, {}, {}): Smith diagonal {:?}, minors {:?}, |M/2M| = {}",
                 r2[0], r2[1], r2[2], road1, invariants(&b), size_mod(R1, r2, 2));
        assert!(road1 == invariants(&b));                          // road 1 = road 2
    }
    assert!(mul(&mul(&s, &a), &t) == d && det(&s).abs() == 1 && det(&t).abs() == 1);   // substitution
    assert!(dg == invariants(&a) && dg == vec![2, 6]);             // road 1 = road 2
    assert!(sizes == pred);                                        // road 3, the count
    assert!(zero_mix == zero_phi && zero_mix.len() > 1);           // mixes = what phi kills
    assert!(tests.iter().map(|&v| order(v)).collect::<Vec<i64>>() == vec![6, 2, 6, 0]);
    println!("ALL CHECKS PASS");
}
