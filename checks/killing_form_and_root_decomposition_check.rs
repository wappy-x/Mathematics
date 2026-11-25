// The Killing form and roots -- the same check as the Python, in Rust.  No
// crates.  The algebra is sl(3): traceless 3 by 3 matrices, the eight gluon
// directions of the strong force.  Exact fractions are a small struct below.
// The Killing form comes from 8 by 8 ad matrices and is checked against 6 tr(XY)
// and a sum over roots; roots come from ad(H) and from a torus element.
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128);                                // numerator, denominator > 0, lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { self + (-o) } }
impl Neg for Q { type Output = Q; fn neg(self) -> Q { Q(-self.0, self.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
const Z: Q = Q(0, 1);
fn n(x: i128) -> Q { Q(x, 1) }
type M = Vec<Vec<Q>>;
fn e(i: usize, j: usize) -> M { (0..3).map(|r| (0..3).map(|c| n((r == i && c == j) as i128)).collect()).collect() }
fn diag(d: [Q; 3]) -> M { (0..3).map(|r| (0..3).map(|c| if r == c { d[r] } else { Z }).collect()).collect() }
fn mul(a: &M, b: &M) -> M {
    (0..a.len()).map(|r| (0..b[0].len()).map(|c| (0..b.len()).fold(Z, |s, k| s + a[r][k] * b[k][c])).collect()).collect()
}
fn add(a: &M, b: &M, s: Q) -> M { a.iter().zip(b).map(|(x, y)| x.iter().zip(y).map(|(u, v)| *u + s * *v).collect()).collect() }
fn br(a: &M, b: &M) -> M { add(&mul(a, b), &mul(b, a), n(-1)) }       // the bracket [a, b] = ab - ba
fn tr(a: &M) -> Q { (0..a.len()).fold(Z, |s, i| s + a[i][i]) }
fn flat(a: &M) -> Vec<Q> { a.iter().flatten().copied().collect() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn solve(cols: &[Vec<Q>], v: &[Q]) -> Vec<Q> {      // coordinates of v in the span of cols
    let (nc, m) = (cols.len(), v.len());
    let mut rows: Vec<Vec<Q>> = (0..m).map(|i| { let mut r: Vec<Q> = cols.iter().map(|c| c[i]).collect(); r.push(v[i]); r }).collect();
    let (mut piv, mut r) = (vec![], 0);
    for c in 0..nc {
        let p = match (r..m).find(|&i| rows[i][c] != Z) { Some(p) => p, None => continue };
        rows.swap(r, p);
        let lead = rows[r][c];
        rows[r] = rows[r].iter().map(|&x| x / lead).collect();
        for i in 0..m {
            let f = rows[i][c];
            if i != r && f != Z { rows[i] = (0..=nc).map(|k| rows[i][k] - f * rows[r][k]).collect() }
        }
        piv.push(c); r += 1;
    }
    assert!((r..m).all(|i| rows[i][nc] == Z), "bracket left the span");
    let mut out = vec![Z; nc];
    for (i, &c) in piv.iter().enumerate() { out[c] = rows[i][nc] }
    out
}
fn ad(x: &M, basis: &[M]) -> M {                     // the matrix of ad x = [x, .] in the basis
    let cols: Vec<Vec<Q>> = basis.iter().map(flat).collect();
    let image: Vec<Vec<Q>> = basis.iter().map(|b| solve(&cols, &flat(&br(x, b)))).collect();
    (0..basis.len()).map(|i| (0..basis.len()).map(|j| image[j][i]).collect()).collect()
}
fn killing(x: &M, y: &M, b: &[M]) -> Q { tr(&mul(&ad(x, b), &ad(y, b))) }
fn gram(b: &[M]) -> M { b.iter().map(|x| b.iter().map(|y| killing(x, y, b)).collect()).collect() }
fn reduce(m0: &M) -> (Q, usize) {                    // row-reduce a copy: (determinant, kernel dimension)
    let (mut m, mut d, mut r, mut free) = (m0.clone(), n(1), 0, 0);
    for c in 0..m[0].len() {
        let p = match (r..m.len()).find(|&i| m[i][c] != Z) { Some(p) => p, None => { free += 1; d = Z; continue } };
        if p != r { m.swap(r, p); d = -d }
        d = d * m[r][c];
        for i in 0..m.len() {
            let f = m[i][c] / m[r][c];
            if i != r { m[i] = (0..m[0].len()).map(|k| m[i][k] - f * m[r][k]).collect() }
        }
        r += 1;
    }
    (d, free)
}

fn main() {
    let pairs = [(0, 1), (0, 2), (1, 0), (1, 2), (2, 0), (2, 1)];
    let name = |p: (usize, usize)| format!("E{}{}", p.0 + 1, p.1 + 1);
    let (h1, h2, s) = (diag([n(1), n(-1), Z]), diag([Z, n(1), n(-1)]), diag([n(1), n(1), n(-2)]));
    let mut sl3: Vec<M> = pairs.iter().map(|&(i, j)| e(i, j)).collect();
    sl3.push(h1.clone()); sl3.push(h2.clone());
    let g = gram(&sl3);
    let six = (0..8).all(|i| (0..8).all(|j| g[i][j] == n(6) * tr(&mul(&sl3[i], &sl3[j]))));
    println!("sl(3): dimension {} = 2 diagonal + 6 off-diagonal", sl3.len());
    println!("B(X,Y) = tr(ad X ad Y) by 8x8 ad matrices equals 6 tr(XY) on all 64 basis pairs: {}", yn(six));
    println!("B(H1,H1) = {}  B(H2,H2) = {}  B(H1,H2) = {}  B(E12,E21) = {}  B(E12,E12) = {}", g[6][6], g[7][7], g[6][7], g[0][2], g[0][0]);
    let dg = reduce(&g).0;
    println!("Cartan's criterion: det of the 8x8 Killing matrix = {} -> semisimple: {}", dg, yn(dg != Z));
    let hb = g[6][6] * g[7][7] - g[6][7] * g[6][7];
    println!("by blocks: three E_ij, E_ji pairs give {} each, the H block {} : {} x {} = {}", -(g[0][2] * g[2][0]), hb, n(-36) * n(-36) * n(-36), hb, n(-36) * n(-36) * n(-36) * hb);
    let adh = ad(&h1, &sl3);
    println!("ad(H) for H = diag(1,-1,0) is diagonal in this basis: {}", yn((0..8).all(|i| (0..8).all(|j| i == j || adh[i][j] == Z))));
    let (t, t_inv) = (diag([n(2), q(1, 2), n(1)]), diag([q(1, 2), n(2), n(1)]));   // the torus element 2^H
    for (k, &p) in pairs.iter().enumerate() {
        let scale = mul(&mul(&t, &e(p.0, p.1)), &t_inv)[p.0][p.1];
        let diff = h1[p.0][p.0] - h1[p.1][p.1];
        println!("{}: ad(H) eigenvalue {}, h{} - h{} = {}, torus 2^H scales it by {} = 2^{}", name(p), adh[k][k], p.0 + 1, p.1 + 1, diff, scale, adh[k][k]);
        let a = adh[k][k].0 as i32;
        assert!(scale == if a >= 0 { n(1 << a) } else { q(1, 1 << -a) } && adh[k][k] == diff);
    }
    println!("H1, H2: ad(H) eigenvalues {} {} ; so ad(H) has 8 eigenvalues but {} roots", adh[6][6], adh[7][7],
             (0..8).filter(|&k| adh[k][k] != Z).count());
    let roots_sq = (0..6).fold(Z, |acc, k| acc + adh[k][k] * adh[k][k]);
    let trh2 = tr(&mul(&h1, &h1));
    println!("B(H,H) as a sum of root squares: 4+4+1+1+1+1 = {} ; as 6 tr(H^2) = 6 x {} = {}", roots_sq, trh2, n(6) * trh2);
    let cent = [reduce(&ad(&h1, &sl3)).1, reduce(&ad(&s, &sl3)).1];
    println!("centralizer of regular diag(1,-1,0): dimension {} ; of singular diag(1,1,-2): dimension {}", cent[0], cent[1]);
    let ok = pairs.iter().all(|&(i, j)| {
        let h = add(&e(i, i), &e(j, j), n(-1));
        br(&e(i, j), &e(j, i)) == h && br(&h, &e(i, j)) == add(&e(i, j), &e(i, j), n(1))
    });
    println!("each root gives an sl(2): [e,f] = h and [h,e] = 2e for all six: {}", yn(ok));
    let (ip_aa, ip_ab) = (n(4) / g[6][6], n(4) * g[6][7] / (g[6][6] * g[7][7]));
    println!("root lengths by the Killing form: (a,a) = {}  (a,b) = {}  cos = {} -> 120 degrees", ip_aa, ip_ab, ip_ab / ip_aa);
    let (t3, y) = (diag([q(1, 2), q(-1, 2), Z]), diag([q(1, 3), q(1, 3), q(-2, 3)]));
    let charges: Vec<String> = pairs.iter().map(|&p| format!("{} ({}, {})", name(p), t3[p.0][p.0] - t3[p.1][p.1], y[p.0][p.0] - y[p.1][p.1])).collect();
    println!("gluon colour charges (T3, y): {}", charges.join(", "));
    let t1 = add(&e(0, 1), &e(1, 0), n(1));
    let ca = [killing(&t1, &t1, &sl3) / n(4), killing(&h1, &h1, &sl3) / n(4), killing(&s, &s, &sl3) / n(12)];
    println!("B(T1,T1) = {}  B(T3,T3) = {}  B(T8,T8) = {} = C_A, the 3 of three colours", ca[0], ca[1], ca[2]);
    let nf = 6;                                                     // quark flavours
    println!("QCD beta0 = 11 C_A/3 - 2 n_f/3 with n_f = {} flavours: {}", nf, n(11) * ca[2] / n(3) - n(2) * n(nf) / n(3));
    let gl3: Vec<M> = (0..9).map(|k| e(k / 3, k % 3)).collect();
    let b3: Vec<M> = (0..9).filter(|k| k / 3 <= k % 3).map(|k| e(k / 3, k % 3)).collect();
    let n3: Vec<M> = (0..9).filter(|k| k / 3 < k % 3).map(|k| e(k / 3, k % 3)).collect();
    let (dgl, db) = (reduce(&gram(&gl3)).0, reduce(&gram(&b3)).0);
    let id = diag([n(1), n(1), n(1)]);
    println!("mistake 1, trace form for the Killing form: tr(H^2) = {} not {}", trh2, g[6][6]);
    println!("mistake 2, gl(3): det of 9x9 Killing matrix = {} ; B(I,X) = 0 for all 9 basis X: {}", dgl, yn(gl3.iter().all(|x| killing(&id, x, &gl3) == Z)));
    println!("mistake 3, upper triangular b: det of 6x6 Killing matrix = {} ; B(b,[b,b]) = 0, solvable: {}", db, yn(b3.iter().all(|x| n3.iter().all(|y| killing(x, y, &b3) == Z))));
    println!("mistake 4, splitting by singular diag(1,1,-2): zero part of dimension {} ; it holds [E12,E21] = diag(1,-1,0), not 0: {}",
             cent[1], yn(br(&e(0, 1), &e(1, 0)) == h1));
    let block = n(-36) * n(-36) * n(-36) * hb;
    assert!(six && dg == n(-5038848) && dg == block);              // brute force against block formula
    assert!(roots_sq == g[6][6] && g[6][6] == n(6) * trh2 && roots_sq == n(12));   // three roads to 12
    assert!(cent == [2, 4] && ok && ip_ab / ip_aa == q(-1, 2) && ca == [n(3), n(3), n(3)]);
    assert!(dgl == Z && db == Z);
    println!("ALL CHECKS PASS");
}
