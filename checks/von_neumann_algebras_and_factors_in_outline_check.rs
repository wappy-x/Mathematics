// Factors in outline -- the same check as the Python, in Rust.  No crates.
// Projections in the 2^n x 2^n matrices with the normalised trace, their sizes,
// the one-third projection of the infinite tensor product, centres of small
// algebras, and the truncated shift.  Exact fractions wherever the answer is.
use std::collections::BTreeSet;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 } // a fraction in lowest terms, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
impl Q { fn f(&self) -> f64 { self.n as f64 / self.d as f64 } }
type M = Vec<Vec<Q>>;
fn z() -> Q { q(0, 1) }
fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|i| (0..b[0].len()).map(|j| (0..b.len()).fold(z(), |s, k| s + a[i][k] * b[k][j])).collect()).collect()
}
fn adj(a: &M) -> M { (0..a.len()).map(|i| (0..a.len()).map(|j| a[j][i]).collect()).collect() }
fn kron(a: &M, b: &M) -> M {
    let m = b.len();
    (0..a.len() * m).map(|i| (0..a.len() * m).map(|j| a[i / m][j / m] * b[i % m][j % m]).collect()).collect()
}
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| q((i == j) as i128, 1)).collect()).collect() }
fn unit(n: usize, i: usize, j: usize) -> M {
    (0..n).map(|r| (0..n).map(|c| q((r == i && c == j) as i128, 1)).collect()).collect()
}
fn sub(a: &M, b: &M) -> M { a.iter().zip(b).map(|(r, s)| r.iter().zip(s).map(|(x, y)| *x - *y).collect()).collect() }
fn tr(a: &M) -> Q { (0..a.len()).fold(z(), |s, i| s + a[i][i]) }
fn tau(a: &M) -> Q { tr(a) / q(a.len() as i128, 1) }
fn is_proj(p: &M) -> bool { mul(p, p) == *p && adj(p) == *p }
fn rank(a: &M) -> usize {
    let mut m = a.clone();
    let mut r = 0;
    for c in 0..m[0].len() {
        let p = match (r..m.len()).find(|&i| m[i][c] != z()) { Some(p) => p, None => continue };
        m.swap(r, p);
        for i in 0..m.len() {
            if i != r && m[i][c] != z() {
                let f = m[i][c] / m[r][c];
                let row = m[r].clone();
                for (x, y) in m[i].iter_mut().zip(row) { *x = *x - f * y; }
            }
        }
        r += 1;
    }
    r
}
fn dec(x: Q) -> String { format!("{:.6}", x.f()) }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn centre_dim(basis: &[M]) -> usize {
    let mut rows: M = vec![];
    for bj in basis {
        let comms: Vec<M> = basis.iter().map(|bk| sub(&mul(bk, bj), &mul(bj, bk))).collect();
        let n = bj.len();
        for r in 0..n { for c in 0..n { rows.push(comms.iter().map(|cm| cm[r][c]).collect()); } }
    }
    basis.len() - rank(&rows)
}

fn main() {
    let (i2, e11, e12, e22) = (eye(2), unit(2, 0, 0), unit(2, 0, 1), unit(2, 1, 1));
    println!("1. the 2 x 2 matrices, tau = trace / 2");
    let u = [q(3, 5), q(4, 5)];
    let p: M = (0..2).map(|i| (0..2).map(|j| u[i] * u[j]).collect()).collect();
    let v: M = vec![vec![u[0], z()], vec![u[1], z()]];
    println!("P = [[{}, {}], [{}, {}]]; P^2 = P and P* = P: {}", dec(p[0][0]), dec(p[0][1]), dec(p[1][0]), dec(p[1][1]), py(is_proj(&p)));
    println!("tau(P) = {}, rank(P) / 2 = {}; V*V = E11: {}; VV* = P: {}", tau(&p), q(rank(&p) as i128, 2),
        py(mul(&adj(&v), &v) == e11), py(mul(&v, &adj(&v)) == p));
    assert!(is_proj(&p) && tau(&p) == q(rank(&p) as i128, 2) && tau(&p) == q(1, 2));
    assert!(mul(&adj(&v), &v) == e11 && mul(&v, &adj(&v)) == p);

    println!("2. the 4 x 4 matrices: size = trace / 4 = rank / 4");
    let pp = kron(&p, &p);
    let cases: Vec<(&str, M)> = vec![("E11 (x) 1", kron(&e11, &i2)), ("P (x) P", pp.clone()), ("1 - P (x) P", sub(&eye(4), &pp)),
        ("E11 (x) E11", kron(&e11, &e11)), ("E11 (x) E22", kron(&e11, &e22)), ("1 (x) 1", eye(4))];
    for (name, m) in &cases {
        println!("{:12} projection {}, tau = {}, rank / 4 = {}", name, py(is_proj(m)), tau(m), q(rank(m) as i128, 4));
        assert!(is_proj(m) && tau(m) == q(rank(m) as i128, 4));
    }
    let w = kron(&e11, &e12);
    println!("halving: W*W = E11 (x) E22: {}; WW* = E11 (x) E11: {}", py(mul(&adj(&w), &w) == kron(&e11, &e22)), py(mul(&w, &adj(&w)) == kron(&e11, &e11)));
    assert!(mul(&adj(&w), &w) == kron(&e11, &e22) && mul(&w, &adj(&w)) == kron(&e11, &e11));
    assert!(tau(&kron(&p, &i2)) == tau(&p) && tau(&pp) == tau(&p) * tau(&p));
    println!("embedding A -> A (x) 1 keeps tau: tau(P (x) 1) = {} = tau(P)", tau(&kron(&p, &i2)));
    for n in 1..5u32 {
        let d = 1i128 << n;
        let ks: BTreeSet<u32> = (0..1u64 << d).map(|m| m.count_ones()).collect();
        let sizes: Vec<Q> = ks.iter().map(|&k| q(k as i128, d)).collect();
        let third = sizes.contains(&q(1, 3));
        println!("level n = {}: {} sizes, smallest non-zero {}, one third among them: {}", n, sizes.len(), sizes[1], py(third));
        assert!(sizes.len() as i128 == d + 1 && sizes[1] == q(1, d) && !third);
    }
    assert!((1..64u32).all(|n| (1u128 << n) % 3 != 0)); // the arithmetic fact behind Step 2, n up to 63
    let d10 = (0..9).fold(vec![q(1, 1), z()], |d, _| d.iter().flat_map(|&x| [x, z()]).collect::<Vec<Q>>()); // E11 (x) ... (x) E11
    let s10 = d10.iter().fold(z(), |s, &x| s + x) / q(d10.len() as i128, 1); // rank 1: the smallest non-zero size
    println!("level n = 10: smallest non-zero size {} = {}", s10, dec(s10));
    assert!(d10.len() == 1 << 10 && s10 == q(1, 1024));

    println!("3. the limit: the projection 'binary digits below t' in the weak closure");
    for nn in [2u32, 4, 8, 12, 16] {
        let two = 1i128 << nn;
        let cnt = (0..two).filter(|k| 3 * k < two).count() as i128;
        let t_n = q(cnt, two);
        let dist = (t_n - q(1, 3)).f().sqrt();
        println!("t = 1/3, N = {:2}: tau(f_N) = {}, GNS distance to f = {:.6}", nn, dec(t_n), dist);
        assert!(t_n == q(two + 2, 3 * two) && (dist - (2.0 / (3.0 * two as f64)).sqrt()).abs() < 1e-12);
        assert!((0..4 * two).filter(|k| 3 * k < 4 * two).all(|k| 3 * (k >> 2) < two)); // f_{N+2} <= f_N
    }
    for nn in [4u32, 8, 16] {
        let two = 1i128 << nn;
        let cnt = (0..two).filter(|k| 2 * k * k < two * two).count() as i128;
        let gap = cnt as f64 / two as f64 - 1.0 / 2f64.sqrt();
        println!("t = 1/sqrt 2 = {:.6}, N = {:2}: tau = {}, gap {:.6}", 1.0 / 2f64.sqrt(), nn, dec(q(cnt, two)), gap);
        assert!(0.0 < gap && gap <= 1.0 / two as f64);
    }

    println!("4. centres: X in the algebra with XB = BX for every basis member B");
    let mut m2 = vec![]; let mut m4 = vec![]; let mut m2x1 = vec![]; let mut m21 = vec![];
    for i in 0..2 { for j in 0..2 { m2.push(unit(2, i, j)); m2x1.push(kron(&unit(2, i, j), &i2)); m21.push(unit(3, i, j)); } }
    m21.push(unit(3, 2, 2));
    for i in 0..4 { for j in 0..4 { m4.push(unit(4, i, j)); } }
    let algebras: Vec<(&str, Vec<M>, usize)> = vec![("M_2", m2, 1), ("M_4 = M_2 (x) M_2", m4, 1), ("M_2 (x) 1 in M_4", m2x1, 1),
        ("diagonal 2 x 2", vec![e11.clone(), e22.clone()], 2), ("M_2 (+) M_1 in M_3", m21, 2),
        ("diagonal 4 x 4", (0..4).map(|i| unit(4, i, i)).collect(), 4)];
    for (name, basis, blocks) in &algebras {
        let zd = centre_dim(basis);
        println!("{:20} dimension {:2}, centre dimension {}, factor: {}", name, basis.len(), zd, py(zd == 1));
        assert!(zd == *blocks);
    }
    let (mut found, mut normal, mut tested) = (0, 0, 0); // the reason: a diagonal V has V*V = VV*
    for a in -2..3 { for b in -2..3 {
        let x: M = vec![vec![q(a, 1), z()], vec![z(), q(b, 1)]]; let (l, r) = (mul(&adj(&x), &x), mul(&x, &adj(&x)));
        found += (l == e11 && r == e22) as usize; normal += (l == r) as usize; tested += 1;
    } }
    println!("diagonal V = diag(a, b) with V*V = E11 and VV* = E22, a and b in -2..2: {} found; V*V = VV* for {} of {}", found, normal, tested);
    assert!(found == 0 && normal == tested);

    println!("5. the shift on l2, cut to N x N");
    for n in [4usize, 8, 16] {
        let s: M = (0..n).map(|r| (0..n).map(|c| q((r == c + 1) as i128, 1)).collect()).collect();
        let (a, b) = (mul(&adj(&s), &s), mul(&s, &adj(&s)));
        println!("N = {:2}: tr(S*S) = {}, tr(SS*) = {}, tr(1) = {}, S*S = 1: {}", n, tr(&a), tr(&b), n, py(a == eye(n)));
        assert!(a == sub(&eye(n), &unit(n, n - 1, n - 1)) && b == sub(&eye(n), &unit(n, 0, 0)));
    }

    println!("6. what breaks");
    let om = |a: &M| q(3, 4) * a[0][0] + q(1, 4) * a[1][1];
    println!("biased state p = 3/4: w(E11) = {}, w(E22) = {}, ratio lambda = {}, though E12 links them", dec(om(&e11)), dec(om(&e22)), om(&e22) / om(&e11));
    assert!(mul(&e12, &adj(&e12)) == e11 && mul(&adj(&e12), &e12) == e22 && om(&e11) != om(&e22));
    let k2 = kron(&e11, &i2);
    let raw = [tr(&e11), tr(&k2), tr(&kron(&k2, &i2))];
    let d = (0..9).fold(vec![q(1, 1), z()], |d, _| d.iter().flat_map(|&x| [x, x]).collect::<Vec<Q>>()); // E11 (x) 1 (x) ... (x) 1
    let raw10 = d.iter().fold(z(), |s, &x| s + x);
    println!("unnormalised trace of E11 at levels 1, 2, 3: {}, {}, {}; at level 10: {}", raw[0], raw[1], raw[2], raw10);
    assert!(raw == [q(1, 1), q(2, 1), q(4, 1)] && raw10 == q(1 << 9, 1));
    println!("ALL CHECKS PASS");
}
