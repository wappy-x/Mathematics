// The Hodge conjecture in degree 4, on the Fermat cubic fourfold -- the check behind the card.
// std only.  X: x0^3 + x1^3 + ... + x5^3 = 0 in P^5, a smooth cubic fourfold.
//   road 1 (Hodge side): h^(p,q) by counting monomials, against the Euler number and the signature
//   road 2 (cycle side): its 405 planes, how each pair meets (exact algebra in Z[w], w^3 = 1),
//                        and the rank of their intersection matrix, mod a prime and exactly
//   road 3 (one class two ways): h^2 as three planes in one 3-space, for all 405 such triples
use std::collections::BTreeSet;
type W = (i64, i64); // a + b w in Z[w], with w^2 = -1 - w
type Plane = Vec<(usize, usize, W)>; // forms x_i - c x_j
const Z0: W = (0, 0); const ONE: W = (1, 0); const PRIME: i64 = (1 << 31) - 1;
const ROOTS: [W; 3] = [(-1, 0), (0, -1), (1, 1)]; // -1, -w, -w^2: the three cube roots of -1

fn mul(x: W, y: W) -> W { (x.0 * y.0 - x.1 * y.1, x.0 * y.1 + x.1 * y.0 - x.1 * y.1) }
fn sub(x: W, y: W) -> W { (x.0 - y.0, x.1 - y.1) }
fn comb(n: i64, k: i64) -> i64 { (0..k).fold(1, |a, i| a * (n - i) / (i + 1)) }

fn matchings(s: &[usize]) -> Vec<Vec<(usize, usize)>> {
    if s.is_empty() { return vec![vec![]]; } let mut out = vec![];
    for k in 1..s.len() {
        let rest: Vec<usize> = s[1..].iter().cloned().filter(|&x| x != s[k]).collect();
        for m in matchings(&rest) {
            out.push([vec![(s[0], s[k])], m].concat());
        }
    }
    out
}

fn meet_dim(p: &Plane, q: &Plane) -> usize {
    let coord = |k: usize, l: usize, b: W, t: usize| if t == l { ONE } else if t == k { b } else { Z0 };
    let m: Vec<Vec<W>> = p.iter().map(|&(i, j, a)| q.iter()
        .map(|&(k, l, b)| sub(coord(k, l, b, i), mul(a, coord(k, l, b, j)))).collect()).collect();
    let minor = |r: usize, s: usize, c: usize, e: usize| sub(mul(m[r][c], m[s][e]), mul(m[r][e], m[s][c]));
    let mut det = Z0;
    for c in 0..3 {
        let t = mul(m[0][c], minor(1, 2, (c + 1) % 3, (c + 2) % 3));
        det = (det.0 + t.0, det.1 + t.1);
    }
    if det != Z0 { return 0 }
    let pairs = [(0, 1), (0, 2), (1, 2)];
    if pairs.iter().any(|&(r, s)| pairs.iter().any(|&(c, e)| minor(r, s, c, e) != Z0)) { return 1; }
    if m.iter().flatten().any(|&x| x != Z0) { 2 } else { 3 }
}

fn rank_mod(g: &Vec<Vec<i64>>) -> usize {
    let p = PRIME;
    let mut m: Vec<Vec<i64>> = g.iter().map(|row| row.iter().map(|x| x.rem_euclid(p)).collect()).collect();
    let mut r = 0;
    for c in 0..m[0].len() {
        let Some(piv) = (r..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, piv);
        let (mut inv, mut b, mut e) = (1i64, m[r][c], p - 2);
        while e > 0 { if e & 1 == 1 { inv = inv * b % p; } b = b * b % p; e >>= 1; }
        for i in r + 1..m.len() {
            if m[i][c] != 0 {
                let f = m[i][c] * inv % p;
                let top = m[r].clone();
                for (x, y) in m[i].iter_mut().zip(top) { *x = (*x - f * y).rem_euclid(p); }
            }
        }
        r += 1;
    }
    r
}

fn bareiss_det(a: Vec<Vec<i128>>) -> i128 {
    let (n, mut m, mut prev, mut sign) = (a.len(), a, 1i128, 1i128);
    for c in 0..n {
        let Some(piv) = (c..n).find(|&i| m[i][c] != 0) else { return 0 };
        if piv != c { m.swap(c, piv); sign = -sign; }
        for i in c + 1..n {
            for j in c + 1..n {
                m[i][j] = (m[c][c].checked_mul(m[i][j]).unwrap() - m[i][c].checked_mul(m[c][j]).unwrap()) / prev;
            }
        }
        prev = m[c][c];
    }
    sign * prev
}

fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- road 1: Hodge numbers of a smooth cubic fourfold ----
    let (n, d) = (4i64, 3i64);
    let deg: Vec<i64> = (0..=n).map(|p| (p + 1) * d - (n + 2)).collect();
    let digits = |e: i64| (0..6).map(|k| e / (d - 1).pow(k) % (d - 1)).sum::<i64>(); // exponents below d - 1
    let jac: Vec<i64> = deg.iter().map(|&t| (0..(d - 1).pow(6)).filter(|&e| digits(e) == t).count() as i64).collect();
    let hodge: Vec<i64> = jac.iter().enumerate().map(|(p, &x)| x + (p == 2) as i64).collect(); // + the class h^2
    let b4: i64 = hodge.iter().sum();
    let chern: i64 = (0..=n).map(|i| comb(n + 2, i) * (-d).pow((n - i) as u32)).sum();
    let euler = d * chern;
    let (p1, p2) = (comb(6, 1) - d * d, comb(6, 2) - 6 * d * d + d.pow(4));
    assert!(d * (7 * p2 - p1 * p1) % 45 == 0);
    let sig = d * (7 * p2 - p1 * p1) / 45;
    let sig_hodge: i64 = (0..=4).map(|p| (-1i64).pow(p as u32) * hodge[p]).sum::<i64>()
        + [0u32, 1, 3, 4].iter().map(|&k| (-1i64).pow(k)).sum::<i64>(); // + h^k,k
    println!("road 1, the Hodge side of a smooth fourfold of degree {}", d);
    println!("monomials with exponents at most {}, of degree {}: {}", d - 2, join(&deg), join(&jac));
    println!("h^4,0 = {}, h^3,1 = {}, h^2,2 = {} + 1 = {}, h^1,3 = {}, h^0,4 = {}; b4 = {}",
        hodge[0], hodge[1], jac[2], hodge[2], hodge[3], hodge[4], b4);
    println!("Euler number {} x {} = {}, so b4 = {} - 4 = {}", d, chern, euler, euler, euler - 4);
    println!("signature from p1 = {}, p2 = {}: {} x (7 x {} - {}) / 45 = {}; from Hodge numbers: {}; so H^4 has signature ({}, {})",
        p1, p2, d, p2, p1 * p1, sig, sig_hodge, (b4 + sig) / 2, (b4 - sig) / 2);

    // ---- road 2: the 405 planes and their intersection matrix ----
    let mut planes: Vec<Plane> = vec![];
    for mt in matchings(&[0, 1, 2, 3, 4, 5]) {
        for a in ROOTS { for b in ROOTS { for c in ROOTS {
            planes.push(mt.iter().zip([a, b, c]).map(|(&(i, j), r)| (i, j, r)).collect());
        } } }
    }
    assert!(ROOTS.iter().all(|&r| mul(mul(r, r), r) == (-1, 0))); // c^3 = -1: each plane lies on X
    let nn = planes.len();
    let val = |x: usize| [0i64, 1, -1, 3][x]; // empty, a point, a line, same plane
    let mut dims = vec![vec![3usize; nn]; nn];
    for r in 0..nn { for c in r + 1..nn { let x = meet_dim(&planes[r], &planes[c]); dims[r][c] = x; dims[c][r] = x; } }
    let g: Vec<Vec<i64>> = dims.iter().map(|row| row.iter().map(|&x| val(x)).collect()).collect();
    let kinds: Vec<BTreeSet<usize>> = [2usize, 1, 0].iter()
        .map(|&k| dims.iter().map(|row| row.iter().filter(|&&x| x == k).count()).collect()).collect();
    let first = |s: &BTreeSet<usize>| *s.iter().next().unwrap();
    println!("road 2, the cycle side: {} pairings x 3^3 roots = {} planes on the Fermat cubic fourfold", matchings(&[0, 1, 2, 3, 4, 5]).len(), nn);
    println!("each plane meets {} others in a line, {} in a point, misses {}; P.P = {}",
        first(&kinds[0]), first(&kinds[1]), first(&kinds[2]), g[0][0]);
    let r405 = rank_mod(&g);
    println!("rank of the {} x {} intersection matrix modulo the prime {}: {}", nn, nn, PRIME, r405);
    let (mut basis, mut minors): (Vec<usize>, Vec<i128>) = (vec![], vec![1]);
    for c in 0..nn {
        let idx = [basis.clone(), vec![c]].concat();
        let dt = bareiss_det(idx.iter().map(|&a| idx.iter().map(|&b| g[a][b] as i128).collect()).collect());
        if dt != 0 { basis = idx; minors.push(dt); }
    }
    let neg = minors.windows(2).filter(|w| (w[0] > 0) != (w[1] > 0)).count();
    println!("independent planes found: {}; exact Gram determinant of the {}: {}", basis.len(), basis.len(), minors.last().unwrap());
    println!("signature of the intersection form on them: ({}, {})", basis.len() - neg, neg);

    // ---- road 3: h^2 as three planes in one 3-space ----
    let mut tset: BTreeSet<Vec<usize>> = BTreeSet::new();
    for (s, v) in (0..nn).flat_map(|s| (0..3).map(move |v| (s, v))) {
        tset.insert((0..nn).filter(|&t| (0..3).all(|q| q == v || planes[t][q] == planes[s][q])).collect());
    }
    let triples: Vec<Vec<usize>> = tset.into_iter().collect();
    let rows: BTreeSet<Vec<i64>> = triples.iter()
        .map(|t| (0..nn).map(|c| t.iter().map(|&m| g[m][c]).sum()).collect()).collect();
    let row = rows.iter().next().unwrap().clone();
    let h2sq: i64 = triples[0].iter().map(|&m| row[m]).sum();
    let rowset: Vec<i64> = row.iter().cloned().collect::<BTreeSet<i64>>().into_iter().collect();
    println!("road 3, h^2 as three planes sharing a line: {} triples; distinct rows h^2.P: {}", triples.len(), rows.len());
    println!("h^2.P for every plane: {}; h^2.h^2 = 3 x 3 + 6 x (-1) = {}", join(&rowset), h2sq);

    // ---- what breaks ----
    let wrong: Vec<Vec<i64>> = (0..nn).map(|r| (0..nn).map(|c| if r == c { 1 } else { g[r][c] }).collect()).collect();
    let flip: Vec<Vec<i64>> = g.iter().map(|row| row.iter().map(|&x| if x == -1 { 1 } else { x }).collect()).collect();
    let (rw, rf) = (rank_mod(&wrong), rank_mod(&flip));
    println!("mistake 1, a plane meets itself once (P.P = 1): rank {}, more than b4 = {}", rw, b4);
    println!("mistake 2, a line meeting counted +1, not -1: rank {}, more than b4 = {}", rf, b4);
    println!("mistake 3, every rational class in H^4 algebraic: {} claimed, {} algebraic here", b4, basis.len());
    println!("mistake 4, every (2,2) class algebraic: h^2,2 = {} claimed, 1 for a very general cubic (quoted)", hodge[2]);
    for k in 1..=6i64 { // degrees 2p left open by Lefschetz (p = 0, 1, n-1, n)
        let left: Vec<i64> = (0..=k).filter(|&p| ![0, 1, k - 1, k].contains(&p)).collect();
        println!("dimension {}: codimensions p not covered by Lefschetz: {}", k,
            if left.is_empty() { "none".to_string() } else { join(&left) });
    }
    assert!(hodge == vec![0, 1, 21, 1, 0] && b4 == euler - 4 && b4 == 23); // road 1 against the Euler number
    assert!(sig == sig_hodge && sig == 19 && kinds.iter().all(|k| k.len() == 1)); // road 1 against the signature
    assert!(r405 == basis.len() && r405 as i64 == hodge[2] && r405 == 21); // road 2 meets road 1
    assert!(neg == 0 && *minors.last().unwrap() > 0); // positive definite, as (2,2) classes are
    assert!(rows.len() == 1 && rowset == vec![1] && h2sq == 3); // road 3: h^2.P = 1, h^4 = 3 = degree
    assert!(rw as i64 > b4 && rf as i64 > b4); // the wrong forms are impossible
    println!("ALL CHECKS PASS");
}
