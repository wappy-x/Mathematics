// Algebraic statistics and identifiability -- the same check as the Python, in Rust.  No crates.
// Two-coin mixture, 4 flips.  Road 1: elimination by a linear recurrence, fibre solved exactly.
// Road 2: every cubic vanishing on the model, by interpolation mod a prime.  Road 3: a grid search.
#[derive(Clone, Copy, PartialEq, PartialOrd, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }  fn sub(a: Q, b: Q) -> Q { add(a, mul(z(-1), b)) }
fn mul(a: Q, b: Q) -> Q {
    let (g, h) = (gcd(a.n, b.d).max(1), gcd(b.n, a.d).max(1));
    q((a.n / g).checked_mul(b.n / h).unwrap(), (a.d / h).checked_mul(b.d / g).unwrap())
}
fn add(a: Q, b: Q) -> Q {
    let g = gcd(a.d, b.d);
    q(a.n.checked_mul(b.d / g).unwrap() + b.n.checked_mul(a.d / g).unwrap(), (a.d / g).checked_mul(b.d).unwrap())
}
fn div(a: Q, b: Q) -> Q { mul(a, q(b.d, b.n)) }  fn pw(a: Q, k: usize) -> Q { (0..k).fold(z(1), |acc, _| mul(acc, a)) }
fn s(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }  fn f(a: Q) -> f64 { a.n as f64 / a.d as f64 }
fn comb(n: usize, k: usize) -> i128 { (0..k).fold(1i128, |c, i| c * (n - i) as i128 / (i as i128 + 1)) }
fn list(v: &[Q]) -> String { format!("[{}]", v.iter().map(|x| format!("'{}'", s(*x))).collect::<Vec<_>>().join(", ")) }
fn dist(pi: Q, a: Q, b: Q, n: usize) -> Vec<Q> {        // chance of k heads in n flips
    (0..=n).map(|k| mul(z(comb(n, k)), add(mul(pi, mul(pw(a, k), pw(sub(z(1), a), n - k))),
        mul(sub(z(1), pi), mul(pw(b, k), pw(sub(z(1), b), n - k)))))).collect()
}
fn hankel_det(q: &[Q]) -> Q {                            // det [[q0,q1,q2],[q1,q2,q3],[q2,q3,q4]]
    let t1 = mul(q[0], sub(mul(q[2], q[4]), mul(q[3], q[3])));
    let t2 = mul(q[1], sub(mul(q[1], q[4]), mul(q[3], q[2])));
    add(sub(t1, t2), mul(q[2], sub(mul(q[1], q[3]), mul(q[2], q[2]))))
}
fn qs(p: &[Q]) -> Vec<Q> { (0..5).map(|k| div(p[k], z(comb(4, k)))).collect() }
fn isqrt(x: i128) -> i128 { let mut r = (x as f64).sqrt() as i128; while r * r > x { r -= 1 } while (r + 1) * (r + 1) <= x { r += 1 } r }
fn fsqrt(x: Q) -> Option<Q> {                            // exact square root of a rational
    if x.n < 0 { return None } let (a, b) = (isqrt(x.n), isqrt(x.d));
    if a * a == x.n && b * b == x.d { Some(q(a, b)) } else { None }
}
type Pt = (Q, Q, Q);
fn fibre(p: &[Q]) -> (Q, Q, (Q, Q, Q), Q, Vec<Pt>) {  // every (pi, a, b) giving p, by elimination
    let q = qs(p);
    let d = sub(mul(q[0], q[2]), mul(q[1], q[1]));       // solve q2 = s q1 - r q0, q3 = s q2 - r q1
    let s_ = div(sub(mul(q[0], q[3]), mul(q[1], q[2])), d);
    let r = div(sub(mul(q[1], q[3]), mul(q[2], q[2])), d);
    let (a2, b1, c0) = (add(z(1), add(s_, r)), mul(z(-1), add(s_, mul(z(2), r))), r);
    let disc = sub(mul(b1, b1), mul(z(4), mul(a2, c0)));
    let mut pts = vec![];
    if let Some(root) = fsqrt(disc) {
        let (r1, r2) = (div(sub(root, b1), mul(z(2), a2)), div(sub(mul(z(-1), b1), root), mul(z(2), a2)));
        for (a, b) in [(r1, r2), (r2, r1)] {
            let (x, y) = (div(a, sub(z(1), a)), div(b, sub(z(1), b)));
            pts.push((mul(div(sub(q[1], mul(y, q[0])), sub(x, y)), pw(add(z(1), x), 4)), a, b));
        }
    }
    (s_, r, (a2, b1, c0), disc, pts)
}
fn rank(mut m: Vec<Vec<Q>>) -> usize {                   // exact Gaussian elimination
    let mut rk = 0;
    for c in 0..m[0].len() {
        let Some(piv) = (rk..m.len()).find(|&i| m[i][c].n != 0) else { continue };
        m.swap(rk, piv);
        for i in 0..m.len() {
            if i != rk && m[i][c].n != 0 { let fct = div(m[i][c], m[rk][c]);
                m[i] = (0..m[i].len()).map(|j| sub(m[i][j], mul(fct, m[rk][j]))).collect(); } }
        rk += 1;
    }
    rk
}
fn jac_rank(pi: Q, a: Q, b: Q, n: usize) -> usize {      // rank of d(p_1..p_n)/d(pi, a, b)
    let dk = |t: Q, k: usize| { let lo = if k > 0 { mul(z(k as i128), mul(pw(t, k - 1), pw(sub(z(1), t), n - k))) } else { z(0) };
        let hi = if k < n { mul(z((n - k) as i128), mul(pw(t, k), pw(sub(z(1), t), n - k - 1))) } else { z(0) }; sub(lo, hi) };
    rank((1..=n).map(|k| { let c = z(comb(n, k));
        vec![mul(c, sub(mul(pw(a, k), pw(sub(z(1), a), n - k)), mul(pw(b, k), pw(sub(z(1), b), n - k)))),
             mul(c, mul(pi, dk(a, k))), mul(c, mul(sub(z(1), pi), dk(b, k)))] }).collect())
}
const P: u64 = (1 << 31) - 1;
fn powm(mut b: u64, mut e: u64) -> u64 { let mut r = 1; b %= P; while e > 0 { if e & 1 == 1 { r = r * b % P } b = b * b % P; e >>= 1 } r }
struct Rng(u64);
impl Rng { fn next(&mut self) -> u64 {                    // SplitMix64, seed 20261117
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut x = self.0;
    x = (x ^ (x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
    (x ^ (x >> 31)) % P } }
fn monos(deg: u32, n: usize) -> Vec<Vec<u32>> {          // exponent vectors of degree deg
    if n == 0 { return if deg == 0 { vec![vec![]] } else { vec![] } }
    (0..=deg).rev().flat_map(|e| monos(deg - e, n - 1).into_iter().map(move |r| [vec![e], r].concat())).collect()
}
fn ev(e: &[u32], v: &[u64]) -> u64 { e.iter().zip(v).fold(1, |acc, (&k, &x)| acc * powm(x, k as u64) % P) }
fn hdet_mod(v: &[u64]) -> u64 {
    let m = |a: u64, b: u64| a * b % P; let sb = |a: u64, b: u64| (a + P - b) % P;
    let t1 = m(v[0], sb(m(v[2], v[4]), m(v[3], v[3]))); let t2 = m(v[1], sb(m(v[1], v[4]), m(v[3], v[2])));
    (sb(t1, t2) + m(v[2], sb(m(v[1], v[3]), m(v[2], v[2])))) % P
}
fn kernel_mod(mut m: Vec<Vec<u64>>, ncol: usize) -> Vec<Vec<u64>> {   // null space basis mod P
    let (mut piv, mut rk) = (vec![], 0);
    for c in 0..ncol {
        let Some(i) = (rk..m.len()).find(|&i| m[i][c] != 0) else { continue };
        m.swap(rk, i); let inv = powm(m[rk][c], P - 2);
        m[rk] = m[rk].iter().map(|v| v * inv % P).collect();
        for j in 0..m.len() { if j != rk && m[j][c] != 0 { let fc = m[j][c];
            m[j] = (0..ncol).map(|t| (m[j][t] + P - fc * m[rk][t] % P) % P).collect(); } }
        piv.push(c); rk += 1;
    }
    (0..ncol).filter(|c| !piv.contains(c)).map(|fr| (0..ncol).map(|c| match piv.iter().position(|&p| p == c) {
        None => if c == fr { 1 } else { 0 }, Some(i) => (P - m[i][fr]) % P }).collect()).collect()
}
fn tri(v: &[Pt]) -> String { format!("[{}]", v.iter().map(|t| format!("('{}', '{}', '{}')", s(t.0), s(t.1), s(t.2))).collect::<Vec<_>>().join(", ")) }
fn main() {
    let (pi0, a0, b0) = (q(2, 5), q(4, 5), q(1, 2)); let p = dist(pi0, a0, b0, 4); let qv = qs(&p);
    let (pa, pb) = (dist(z(1), a0, b0, 4), dist(z(0), a0, b0, 4)); println!("example: pi = 2/5, coin A heads 4/5, coin B heads 1/2, 4 flips");
    for k in 0..5 { println!("k={}  p = {:<12} {:7.3}%   one sequence q = {}", k, s(p[k]), f(p[k]) * 100.0, s(qv[k])); }
    let row = |v: Vec<f64>| v.iter().map(|x| format!("{:6.2}", x * 100.0)).collect::<Vec<_>>().join(" ");
    println!("chart, mixture %  {}", row(p.iter().map(|x| f(*x)).collect()));
    println!("chart, coin A part {}", row(pa.iter().map(|x| f(mul(pi0, *x))).collect()));
    println!("chart, coin B part {}", row(pb.iter().map(|x| f(mul(sub(z(1), pi0), *x))).collect()));
    let (s0, r0, eli, disc, pts) = fibre(&p);
    println!("road 1: s = {}, r = {}; third equation leaves {}", s(s0), s(r0), s(sub(qv[4], sub(mul(s0, qv[3]), mul(r0, qv[2])))));
    println!("        Hankel determinant at the example = {}", s(hankel_det(&qv)));
    println!("        eliminant {} a^2 + ({}) a + {}, discriminant {}", s(eli.0), s(eli.1), s(eli.2), s(disc));
    let u = z(50000 * 50000);                              // the worked numbers, in units of 1/50000 squared
    println!("        x U: q0q3-q1q2 = {}, q0q2-q1^2 = {}, q1q3-q2^2 = {}", s(mul(sub(mul(qv[0], qv[3]), mul(qv[1], qv[2])), u)),
        s(mul(sub(mul(qv[0], qv[2]), mul(qv[1], qv[1])), u)), s(mul(sub(mul(qv[1], qv[3]), mul(qv[2], qv[2])), u)));
    for t in &pts { println!("        fibre point pi = {}, a = {}, b = {} (alpha = {})", s(t.0), s(t.1), s(t.2), s(mul(t.0, pw(sub(z(1), t.1), 4)))); }
    let mut rng = Rng(20261117);
    let pts_mod: Vec<Vec<u64>> = (0..60).map(|_| { let (al, be, x, y) = (rng.next(), rng.next(), rng.next(), rng.next());
        (0..6).map(|k| (al * powm(x, k) + be * powm(y, k)) % P).collect() }).collect();
    let mut kern = vec![]; for deg in 1..=3u32 {
        let ms = monos(deg, 5);
        let kk = kernel_mod(pts_mod.iter().map(|v| ms.iter().map(|e| ev(e, v)).collect()).collect(), ms.len());
        println!("road 2: degree {}: {} monomials, vanishing combinations {}", deg, ms.len(), kk.len());
        kern.push(kk); }
    let (ms, vec) = (monos(3, 5), kern[2][0].clone());
    let inv = powm(*vec.iter().find(|&&c| c != 0).unwrap(), P - 2);
    let coef: Vec<i64> = vec.iter().map(|c| { let v = c * inv % P; if v > P / 2 { v as i64 - P as i64 } else { v as i64 } }).collect();
    let terms: Vec<(i64, &Vec<u32>)> = coef.iter().zip(&ms).filter(|(c, _)| **c != 0).map(|(c, e)| (*c, e)).collect();
    let name = |e: &Vec<u32>| e.iter().enumerate().filter(|(_, &k)| k > 0)
        .map(|(i, &k)| if k > 1 { format!("q{}^{}", i, k) } else { format!("q{}", i) }).collect::<Vec<_>>().join("*");
    let txt = terms.iter().map(|(c, e)| format!("{}{}{}", if *c > 0 { "+" } else { "-" },
        if c.abs() > 1 { c.abs().to_string() } else { String::new() }, name(e))).collect::<Vec<_>>().join(" ");
    println!("        the cubic: {}", txt.trim_start_matches('+'));
    let m6 = monos(3, 6); let k5 = kernel_mod(pts_mod.iter().map(|v| m6.iter().map(|e| ev(e, v)).collect()).collect(), m6.len()).len();   // 5 flips: q0..q5
    println!("road 2, 5 flips: degree 3 in q0..q5: {} monomials, vanishing combinations {}", m6.len(), k5);
    let agree = (0..20).all(|_| { let v: Vec<u64> = (0..5).map(|_| rng.next()).collect();   // same function as det H
        terms.iter().map(|(c, e)| (*c + P as i64) as u64 % P * ev(e, &v) % P).sum::<u64>() % P == hdet_mod(&v) });
    let mut g4: Vec<((i128, i128, i128), Vec<Q>)> = vec![];
    for i in 1..10 { for j in 0..11 { for l in 0..11 { g4.push(((i, j, l), dist(q(i, 10), q(j, 10), q(l, 10), 4))); } } }
    let hits: Vec<_> = g4.iter().filter(|(_, v)| *v == p).map(|(t, _)| *t).collect();
    let fairp = dist(pi0, q(1, 2), q(1, 2), 4); let fair = g4.iter().filter(|(_, v)| *v == fairp).count();
    println!("road 3: grid of {} points; same p as the example: [{}]; same p as two fair coins: {}", g4.len(),
        hits.iter().map(|t| format!("({}, {}, {})", t.0, t.1, t.2)).collect::<Vec<_>>().join(", "), fair);
    println!("flips n  outcomes  free coords  Jacobian rank  codimension");
    for n in [2usize, 3, 4, 5] { let rk = jac_rank(pi0, a0, b0, n); println!("{:>7} {:>9} {:>12} {:>14} {:>12}", n, n + 1, n, rk, n - rk); }
    let alt = (q(27, 125), q(9, 10), q(19, 35)); println!("break, 2 flips: {} vs {}", list(&dist(alt.0, alt.1, alt.2, 2)), list(&dist(pi0, a0, b0, 2)));
    println!("break, 2 flips at 4 flips: {}", list(&dist(alt.0, alt.1, alt.2, 4)));
    let avg = [mul(add(pts[0].0, pts[1].0), q(1, 2)), mul(add(pts[0].1, pts[1].1), q(1, 2)), mul(add(pts[0].2, pts[1].2), q(1, 2))];
    println!("break, a = b = 1/2: Jacobian rank {}; average of the two fibre points {}", jac_rank(pi0, q(1, 2), q(1, 2), 4), list(&avg));
    let pc: Vec<Q> = [1, 12, 48, 72, 28].iter().map(|&v| q(v, 161)).collect();
    let (sc, rc, _, _, ptc) = fibre(&pc); let dc = sub(mul(sc, sc), mul(z(4), rc));
    println!("break, complex coins: sum {}, det {}, s = {}, r = {}, odds discriminant {}, fibre points {}",
        s(pc.iter().fold(z(0), |a, b| add(a, *b))), s(hankel_det(&qs(&pc))), s(sc), s(rc), s(dc), ptc.len());
    println!("break, binomials left in: det of p-Hankel = {}", s(hankel_det(&p)));
    println!("try, b = 1/5: {}", tri(&fibre(&dist(pi0, a0, q(1, 5), 4)).4));
    println!("try, a = 3/4, b = 1/4, pi = 1/2: {}", tri(&fibre(&dist(q(1, 2), q(3, 4), q(1, 4), 4)).4));

    let (one, oneb) = (sub(z(1), a0), sub(z(1), b0)); assert!(p.iter().fold(z(0), |a, b| add(a, *b)) == z(1) && (s0, r0) == (add(div(a0, one), div(b0, oneb)), mul(div(a0, one), div(b0, oneb))));
    assert!(hankel_det(&qv) == z(0) && hankel_det(&p) != z(0));
    assert!(pts.contains(&(pi0, a0, b0)) && pts.contains(&(sub(z(1), pi0), b0, a0)) && pts.len() == 2);
    assert!(hits == vec![(4, 8, 5), (6, 5, 8)] && fair == 9);
    assert!(kern.iter().map(|k| k.len()).collect::<Vec<_>>() == vec![0, 0, 1] && agree && k5 as i128 == comb(4, 3)); // 3 x 3 minors of 3 x 4
    assert!(dist(alt.0, alt.1, alt.2, 2) == dist(pi0, a0, b0, 2) && dist(alt.0, alt.1, alt.2, 4) != p);
    assert!([2, 3, 4].iter().map(|&n| jac_rank(pi0, a0, b0, n)).collect::<Vec<_>>() == vec![2, 3, 3]);
    assert!(hankel_det(&qs(&pc)) == z(0) && ptc.is_empty() && dc.n < 0);
    println!("ALL CHECKS PASS");
}
