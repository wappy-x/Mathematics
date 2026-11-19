// Dimension and tangent space -- the same check as the Python, in Rust, no crates.
// The variety is the cone x^2 + y^2 = z^2 over the reals; F_p only where named.
// A polynomial maps (i, j, k) to the whole-number coefficient of x^i y^j z^k.
// Dimension: independent coordinates, a chain of primes, points over F_p.
// Tangent space: Jacobian rank, dual numbers over F_p, the secant identity.
use std::collections::{BTreeMap, BTreeSet};
type Poly = BTreeMap<(u32, u32, u32), i64>;
type Pt = (i64, i64, i64);
const P: i64 = 1000003; // a prime, for ranks of value tables

fn poly(terms: &[((u32, u32, u32), i64)]) -> Poly { add(&Poly::new(), &terms.iter().cloned().collect(), 1) }

fn add(a: &Poly, b: &Poly, s: i64) -> Poly {
    let mut out = a.clone();
    for (&m, &c) in b { *out.entry(m).or_insert(0) += s * c }
    out.retain(|_, c| *c != 0);
    out
}

fn mul(a: &Poly, b: &Poly) -> Poly {
    let mut out = Poly::new();
    for (&(i, j, k), &c) in a { for (&(u, v, w), &d) in b { out = add(&out, &poly(&[((i + u, j + v, k + w), c * d)]), 1) } }
    out
}

fn ev(g: &Poly, p: Pt, m: i64) -> i64 { // m = 0: exact
    let mut s = 0;
    for (&(i, j, k), &c) in g { s += c * p.0.pow(i) * p.1.pow(j) * p.2.pow(k) }
    if m > 0 { s.rem_euclid(m) } else { s }
}

fn grad(g: &Poly, p: Pt) -> Vec<i64> { // the Jacobian row of g at p
    (0..3).map(|v| {
        let mut d = Poly::new();
        for (&m, &c) in g {
            let e = [m.0, m.1, m.2];
            if e[v] > 0 {
                let mut f = e;
                f[v] -= 1;
                *d.entry((f[0], f[1], f[2])).or_insert(0) += c * e[v] as i64;
            }
        }
        ev(&d, p, 0)
    }).collect()
}

fn rank_mod(rows: &[Vec<i64>]) -> usize { // Gaussian elimination mod P
    let mut rows: Vec<Vec<i64>> = rows.iter().map(|r| r.iter().map(|v| v.rem_euclid(P)).collect()).collect();
    let mut r = 0;
    for col in 0..rows[0].len() {
        let piv = match (r..rows.len()).find(|&i| rows[i][col] != 0) { Some(p) => p, None => continue };
        rows.swap(r, piv);
        let (mut inv, mut b, mut e) = (1i64, rows[r][col], P - 2);
        while e > 0 { if e & 1 == 1 { inv = inv * b % P } b = b * b % P; e >>= 1 }
        rows[r] = rows[r].iter().map(|v| v * inv % P).collect();
        let pivot = rows[r].clone();
        for i in 0..rows.len() {
            if i != r && rows[i][col] != 0 {
                let c = rows[i][col];
                rows[i] = rows[i].iter().zip(&pivot).map(|(v, w)| (v - c * w).rem_euclid(P)).collect();
            }
        }
        r += 1;
    }
    r
}

fn dual_ev(g: &Poly, pt: Pt, v: Pt, p: i64) -> (i64, i64) { // g(pt + eps v), eps^2 = 0, mod p
    let (mut a, mut b) = (0, 0);
    for (&(i, j, k), &c) in g {
        let (mut ta, mut tb) = (c.rem_euclid(p), 0);
        for (q, d, e) in [(pt.0, v.0, i), (pt.1, v.1, j), (pt.2, v.2, k)] {
            for _ in 0..e { let na = ta * q.rem_euclid(p) % p; tb = (ta * d + tb * q).rem_euclid(p); ta = na; }
        }
        (a, b) = ((a + ta) % p, (b + tb) % p);
    }
    (a, b)
}

fn tangent_count(gens: &[Poly], pt: Pt, p: i64) -> usize {
    (0..p * p * p).filter(|t| gens.iter().all(|g| dual_ev(g, pt, (t / (p * p), t / p % p, t % p), p) == (0, 0))).count()
}

fn vals(ms: &[(u32, u32, u32)], pts: &[Pt]) -> Vec<Vec<i64>> {
    pts.iter().map(|&q| ms.iter().map(|&m| ev(&poly(&[(m, 1)]), q, P)).collect()).collect()
}

fn main() {
    let (x, y, z) = (poly(&[((1, 0, 0), 1)]), poly(&[((0, 1, 0), 1)]), poly(&[((0, 0, 1), 1)]));
    let c = |n: i64| poly(&[((0, 0, 0), n)]);
    let f = poly(&[((2, 0, 0), 1), ((0, 2, 0), 1), ((0, 0, 2), -1)]);
    let mut set = BTreeSet::new();
    for m in 1..6i64 { for n in 0..m {
        for (a, b) in [(m * m - n * n, 2 * m * n), (2 * m * n, m * m - n * n)] {
            for t in [1, 2] { for sx in [1, -1] { for sy in [1, -1] { for sz in [1, -1] {
                set.insert((sx * t * a, sy * t * b, sz * t * (m * m + n * n)));
            } } } }
        }
    } }
    let pts: Vec<Pt> = set.into_iter().collect();
    assert!(pts.iter().all(|&q| ev(&f, q, 0) == 0));
    println!("field: the real numbers; F_p only where named.  cone f = x^2 + y^2 - z^2");
    println!("integer test points on the cone: {}", pts.len());
    println!("-- dimension, road 1: independent coordinates --");
    let yz: Vec<_> = (0..5u32).flat_map(|a| (0..5 - a).map(move |b| (0, a, b))).collect();
    let r_yz = rank_mod(&vals(&yz, &pts));
    println!("monomials in y, z of degree <= 4: {}; rank of their values on the cone: {}", yz.len(), r_yz);
    let mut xyz = vec![];
    for i in 0..3u32 { for j in 0..3u32 { for k in 0..3u32 { if i + j + k <= 2 { xyz.push((i, j, k)) } } } }
    let r_xyz = rank_mod(&vals(&xyz, &pts));
    println!("monomials in x, y, z of degree <= 2: {}; rank: {}, so one relation: f", xyz.len(), r_xyz);
    println!("x over k(y, z): t^2 - (z^2 - y^2) = 0; (3, 4, 5) and (-3, 4, 5) share y, z: degree 2");
    assert!(r_yz == yz.len() && r_yz == 15 && r_xyz == xyz.len() - 1 && r_xyz == 9 && ev(&f, (-3, 4, 5), 0) == 0);
    println!("transcendence degree 2");
    println!("-- dimension, road 2: a chain of prime ideals --");
    let (g1, g2) = (add(&mul(&c(4), &x), &mul(&c(3), &y), -1), add(&mul(&c(5), &x), &mul(&c(3), &z), -1));
    let lhs = add(&mul(&add(&g1, &mul(&c(8), &x), -1), &g1), &mul(&add(&mul(&c(10), &x), &g2, -1), &g2), 1);
    let ok = lhs == mul(&c(9), &f);
    println!("9f = (g1 - 8x) g1 + (10x - g2) g2 with g1 = 4x - 3y, g2 = 5x - 3z: {}", if ok { "yes" } else { "no" });
    println!("g1 at the cone point (4, 3, 5): {}, not 0, so the line ideal is bigger than <f>", ev(&g1, (4, 3, 5), 0));
    let (w3, h): (i64, Vec<Vec<i64>>) = (ev(&add(&x, &c(3), -1), (6, 8, 10), 0), [(1, 0, 0), (0, 1, 0), (0, 0, 1)].iter().map(|&e| grad(&f, e)).collect());
    println!("x - 3 at the line point (6, 8, 10): {}, not 0, so the point ideal is bigger again", w3);
    println!("quadratic form of f: second-derivative matrix {:?}, rank {}: no linear factors, <f> prime", h, rank_mod(&h));
    assert!(ok && ev(&g1, (4, 3, 5), 0) == 7 && w3 != 0 && rank_mod(&h) == 3 && ev(&g1, (6, 8, 10), 0) == 0 && ev(&g2, (6, 8, 10), 0) == 0);
    println!("chain in k[V]: (0) < line ideal < point ideal, length 2; in k[x, y, z]: length 3");
    println!("-- dimension, road 3: points over F_p --");
    for p in [3i64, 5, 7, 11, 13] {
        let n = (0..p * p * p).filter(|&t| ev(&f, (t / (p * p), t / p % p, t % p), p) == 0).count() as i64;
        println!("cone over F_{}: {} points = {}^2", p, n, p);
        assert!(n == p * p);
    }
    let circ = (0..49i64).filter(|t| ((t / 7) * (t / 7) + (t % 7) * (t % 7) - 25).rem_euclid(7) == 0).count();
    println!("circle x^2 + y^2 = 25 at z = 5, over F_7: {} points = 7 + 1", circ);
    assert!(circ == 8);
    println!("-- tangent spaces: Jacobian rank against dual numbers over F_7 --");
    let (z5, zy) = (add(&z, &c(5), -1), add(&z, &y, -1));
    let cases: Vec<(&str, Vec<Poly>, Pt)> = vec![
        ("cone at (3, 4, 5)", vec![f.clone()], (3, 4, 5)), ("cone at the apex", vec![f.clone()], (0, 0, 0)),
        ("circle z = 5 at (3, 4, 5)", vec![f.clone(), z5], (3, 4, 5)), ("mistake <f^2> at (3, 4, 5)", vec![mul(&f, &f)], (3, 4, 5)),
        ("count <f, z f>: 3 - 2 = 1? at (3, 4, 5)", vec![f.clone(), mul(&z, &f)], (3, 4, 5)),
        ("try <f, z - y> at (0, 3, 3)", vec![f.clone(), zy], (0, 3, 3)), ("try cone at (5, 12, 13)", vec![f.clone()], (5, 12, 13))];
    for (name, gens, pt) in &cases {
        let j: Vec<Vec<i64>> = gens.iter().map(|g| grad(g, *pt)).collect();
        let (r, cnt) = (rank_mod(&j), tangent_count(gens, *pt, 7));
        let js: Vec<String> = j.iter().map(|row| format!("[{}, {}, {}]", row[0], row[1], row[2])).collect();
        println!("{}: J = [{}], rank {}, tangent dim {}; F_7 count {} = 7^{}", name, js.join(", "), r, 3 - r, cnt, 3 - r);
        assert!(cnt == 7usize.pow(3 - r as u32) && gens.iter().all(|g| ev(g, *pt, 0) == 0));
    }
    println!("try F_11: apex {}, (3, 4, 5) {}", tangent_count(&[f.clone()], (0, 0, 0), 11), tangent_count(&[f.clone()], (3, 4, 5), 11));
    println!("-- secants: grad f(P).(Q - P) = -f(Q - P) for every cone point Q --");
    let g = grad(&f, (3, 4, 5));
    assert!(pts.iter().map(|&q| (q.0 - 3, q.1 - 4, q.2 - 5)).all(|w| g[0] * w.0 + g[1] * w.1 + g[2] * w.2 == -ev(&f, w, 0)));
    println!("holds at all {} test points; tangent plane 6x + 8y - 10z = 0, or 3x + 4y - 5z = 0", pts.len());
    for n in [10i64, 100, 1000] {
        let w = (-2 * n - 1, 4 * n, 2 * n + 1); // N^2 (Q - P), Q from m = 2N, n = N + 1
        let gap = ev(&f, w, 0) as f64 / (n.pow(4)) as f64;
        let dist = ((w.0 * w.0 + w.1 * w.1 + w.2 * w.2) as f64).sqrt() / (n * n) as f64;
        assert!(ev(&f, (3 * n * n - 2 * n - 1, 4 * n * n + 4 * n, 5 * n * n + 2 * n + 1), 0) == 0 && (g[0] * w.0 + g[1] * w.1 + g[2] * w.2) * n * n == -ev(&f, w, 0));
        println!("N = {}: Q - P = ({}, {}, {})/{}; linear part {:.6}, distance {:.6}, ratio {:.6}",
                 n, w.0, w.1, w.2, n * n, -gap, dist, gap / dist);
    }
    let det = 3 * (3 * 5 - 5 * 4) - 4 * (4 * 5 - 5 * (-3)) + 5 * (4 * 4 - 3 * (-3));
    println!("apex: rulings through (3, 4, 5), (4, 3, 5), (-3, 4, 5); determinant {}, so they span all 3 directions", det);
    assert!(det == -30 && rank_mod(&[vec![3, 4, 5], vec![4, 3, 5], vec![-3, 4, 5]]) == 3);
    let boxn = (0..1331i64).map(|t| (t / 121 - 5, t / 11 % 11 - 5, t % 11 - 5)).filter(|w| w.0 * w.0 + w.1 * w.1 + w.2 * w.2 == 0).count();
    println!("mistake x^2 + y^2 + z^2 = 0 over the reals: {} point in the box, dimension 0, not 3 - 1 = 2", boxn);
    assert!(boxn == 1);
    println!("ALL CHECKS PASS");
}
