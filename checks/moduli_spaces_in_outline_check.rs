// Moduli spaces in outline -- the same check as the Python, in Rust.  No crates.
// The j-line: exact j of four curves, against the j of four lattice shapes by a
// q-series and by a direct lattice sum; every j reached by one family; a twist
// with equal j but a different point count.  The Grassmannian G(2, 4): lines in
// 3-space counted over F_5 as subspaces and as points of the Plucker quadric,
// and the two lines meeting four given lines, by substitution and by search.
use std::collections::BTreeSet;
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
fn mul(a: Q, b: Q) -> Q {                          // cancel across first, then multiply
    let (g, h) = (gcd(a.n, b.d).max(1), gcd(b.n, a.d).max(1));
    q((a.n / g).checked_mul(b.n / h).unwrap(), (a.d / h).checked_mul(b.d / g).unwrap())
}
fn add(a: Q, b: Q) -> Q { q(a.n.checked_mul(b.d).unwrap() + b.n.checked_mul(a.d).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn div(a: Q, b: Q) -> Q { mul(a, q(b.d, b.n)) }
fn s(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn j_ab(a: Q, b: Q) -> Q {                         // j of y^2 = x^3 + ax + b, exact
    let a3 = mul(z(4), mul(a, mul(a, a)));
    div(mul(z(1728), a3), add(a3, mul(z(27), mul(b, b))))
}
fn family(j: Q) -> (Q, Q) {                        // a curve with j-invariant j
    let k = add(z(1728), mul(z(-1), j));
    (mul(z(3), mul(j, k)), mul(z(2), mul(j, mul(k, k))))
}
fn count(p: i64, a: i64, b: i64) -> i64 {          // points mod p, O included
    let mut n = 1;
    for x in 0..p { for y in 0..p { if (y * y - x * x * x - a * x - b).rem_euclid(p) == 0 { n += 1 } } }
    n
}
type C = (f64, f64);
fn cmul(z: C, w: C) -> C { (z.0 * w.0 - z.1 * w.1, z.0 * w.1 + z.1 * w.0) }
fn cadd(z: C, w: C) -> C { (z.0 + w.0, z.1 + w.1) }
fn cdiv(z: C, w: C) -> C {
    let d = w.0 * w.0 + w.1 * w.1;
    ((z.0 * w.0 + z.1 * w.1) / d, (z.1 * w.0 - z.0 * w.1) / d)
}
fn j_from(e4: C, e6: C, k: f64) -> C {             // k e4^3 / (e4^3 - e6^2), complex
    let c = cmul(e4, cmul(e4, e4));
    cdiv(cmul((k, 0.0), c), cadd(c, cmul((-1.0, 0.0), cmul(e6, e6))))
}
fn j_qseries(t: C) -> C {                          // road 1: Eisenstein q-series
    let pi = std::f64::consts::PI;
    let r = (-2.0 * pi * t.1).exp();
    let qq = (r * (2.0 * pi * t.0).cos(), r * (2.0 * pi * t.0).sin());
    let (mut e4, mut e6, mut qn) = ((1.0, 0.0), (1.0, 0.0), (1.0, 0.0));
    for n in 1..30i64 {
        qn = cmul(qn, qq);
        let s3: i64 = (1..=n).filter(|d| n % d == 0).map(|d| d.pow(3)).sum();
        let s5: i64 = (1..=n).filter(|d| n % d == 0).map(|d| d.pow(5)).sum();
        e4 = cadd(e4, (240.0 * s3 as f64 * qn.0, 240.0 * s3 as f64 * qn.1));
        e6 = cadd(e6, (-504.0 * s5 as f64 * qn.0, -504.0 * s5 as f64 * qn.1));
    }
    j_from(e4, e6, 1728.0)
}
fn j_lattice(t: C, r: i64) -> C {                  // road 2: sum over lattice points
    let (mut g4, mut g6, top) = ((0.0, 0.0), (0.0, 0.0), (r as f64 / t.1) as i64 + 1);
    for m in -r..=r { for n in -top..=top {
        let w = (m as f64 + n as f64 * t.0, n as f64 * t.1);
        if (m == 0 && n == 0) || w.0 * w.0 + w.1 * w.1 > (r * r) as f64 { continue }
        let w2 = cmul(w, w); let w4 = cmul(w2, w2);
        g4 = cadd(g4, cdiv((1.0, 0.0), w4)); g6 = cadd(g6, cdiv((1.0, 0.0), cmul(w4, w2)));
    } }
    let (g2, g3) = ((60.0 * g4.0, 60.0 * g4.1), (140.0 * g6.0, 140.0 * g6.1));
    j_from(g2, (27f64.sqrt() * g3.0, 27f64.sqrt() * g3.1), 1728.0)
}
const IDX: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
fn plucker(u: [i64; 4], v: [i64; 4], p: i64) -> Vec<i64> {   // six 2 x 2 minors, mod p if p
    IDX.iter().map(|&(i, k)| { let x = u[i] * v[k] - u[k] * v[i]; if p > 0 { x.rem_euclid(p) } else { x } }).collect()
}
fn meet(a: &[i64], b: &[i64]) -> i64 {             // zero exactly when the lines meet
    a[0]*b[5] - a[1]*b[4] + a[2]*b[3] + a[3]*b[2] - a[4]*b[1] + a[5]*b[0]
}
fn quad(a: &[i64]) -> i64 { a[0] * a[5] - a[1] * a[4] + a[2] * a[3] }
fn normal(v: &[i64], p: i64) -> Vec<i64> {         // scale so the first nonzero is 1
    let lead = *v.iter().find(|&&x| x != 0).unwrap();
    let mut inv = 1; for _ in 0..p - 2 { inv = inv * lead % p }
    v.iter().map(|x| x * inv % p).collect()
}
fn tup(v: &[i64]) -> String { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn main() {
    let r3 = 3f64.sqrt() / 2.0;
    let curves = [("x^3 - 2", 0, -2, (-0.5, r3), "rho"), ("x^3 - x", -1, 0, (0.0, 1.0), "i"),
        ("x^3 - 30x + 56", -30, 56, (0.0, 2f64.sqrt()), "i sqrt2"),
        ("x^3 - 11x + 14", -11, 14, (0.0, 2.0), "2i"), ("x^3 - 11x + 14", -11, 14, (0.0, 0.5), "i/2")];
    for (name, a, b, t, tn) in curves {
        let (jq, jl, je) = (j_qseries(t), j_lattice(t, 400), j_ab(z(a), z(b)));
        println!("y^2 = {}: j = {}; tau = {}: q-series {:.6}, lattice sum {:.2}", name, s(je), tn, jq.0, jl.0);
        let jf = je.n as f64 / je.d as f64;
        assert!((jq.0 - jf).abs() < 1e-6 * (1.0 + jf.abs()) && jq.1.abs() < 1e-6);
        assert!((jl.0 - jf).abs() < 2e-6 * (1.0 + jf.abs()));
    }
    let qv = (-4.0 * std::f64::consts::PI).exp();
    println!("by hand: 4a^3 = 4 x {} = {}; 27b^2 = 27 x {} = {}; sum {}", (-11i64).pow(3), 4 * (-11i64).pow(3), 14 * 14, 27 * 14 * 14, 4 * (-11i64).pow(3) + 27 * 14 * 14);
    println!("tau = 2i: q = e^(-4 pi) = {:.10} x 10^-6; 1/q = {:.2}; 1/q + 744 + 196884 q = {:.3}", qv * 1e6, 1.0 / qv, 1.0 / qv + 744.0 + 196884.0 * qv);
    println!("1728 = 12^3 = {}; 8000 = 20^3 = {}; 287496 = 66^3 = {}", 12i64.pow(3), 20i64.pow(3), 66i64.pow(3));
    for j in [z(1), z(8000), z(287496), z(-3375), q(6912, 31)] {
        let (a, b) = family(j);
        assert!(j_ab(a, b) == j);                  // every j is reached
    }
    let (fa, fb) = family(z(8000));
    println!("family at j = 8000: a = {}, b = {}; j back = {}", s(fa), s(fb), s(j_ab(fa, fb)));
    println!("rescale to x^3 - 30x + 56: u^4 = {}, u^6 = {}, u^2 = 2240, 2240^3 = {}", s(div(fa, z(-30))), s(div(fb, z(56))), 2240i128.pow(3));
    let fam: Vec<(i128, Q, Q)> = [1, 2, 5].iter().map(|&t| (t, q(6912 * t, 4 * t + 27), j_ab(z(t), z(t)))).collect();
    println!("family y^2 = x^3 + tx + t: {}", fam.iter().map(|(t, f, d)| format!("t = {}: 6912t/(4t+27) = {}, direct {}", t, s(*f), s(*d))).collect::<Vec<_>>().join("; "));
    assert!(fam.iter().all(|(_, f, d)| f == d));
    println!("family at t = 0: the cusp y^2 = x^3, 4t^3 + 27t^2 = {}, yet 6912t/(4t+27) = {}", 4 * 0i64.pow(3) + 27 * 0i64.pow(2), s(q(6912 * 0, 4 * 0 + 27)));
    let (c1, c2) = (count(11, -30, 56), count(11, -30, -56));
    println!("twist: x^3 - 30x + 56 and x^3 - 30x - 56 both j = {}; points mod 11: {} and {}, sum {} = 2 x 11 + 2", s(j_ab(z(-30), z(-56))), c1, c2, c1 + c2);
    assert!(c1 != c2 && c1 + c2 == 24);
    let p = 5i64;
    let vecs: Vec<[i64; 4]> = (0..p.pow(4)).map(|n| [n / 125, n / 25 % 5, n / 5 % 5, n % 5]).collect();
    let mut subspaces = BTreeSet::new();
    for u in &vecs { for v in &vecs { let w = plucker(*u, *v, p); if w.iter().any(|&x| x != 0) { subspaces.insert(normal(&w, p)); } } }
    let mut pts = BTreeSet::new();
    for n in 1..p.pow(6) {
        let v: Vec<i64> = (0..6).map(|k| n / p.pow(5 - k) % p).collect();
        let w = normal(&v, p); if quad(&w) % p == 0 { pts.insert(w); }
    }
    println!("G(2, 4) over F_5: planes in F_5^4 = {}; points on the Plucker quadric = {}; (p^2 + 1)(p^2 + p + 1) = {}", subspaces.len(), pts.len(), (p * p + 1) * (p * p + p + 1));
    println!("all of P^5 over F_5, relation dropped = {}", (p.pow(6) - 1) / (p - 1));
    assert!(subspaces.len() == 806 && pts.len() == 806 && pts == subspaces);
    let l = [([0, 0, 0, 1], [1, 0, 0, 1]), ([0, 0, 1, 1], [0, 1, 1, 1]), ([-1, -1, 0, 1], [2, 1, 1, 1]), ([-1, 0, 2, 1], [0, 1, -1, 1])];
    let pl: Vec<Vec<i64>> = l.iter().map(|(u, v)| plucker(*u, *v, 0)).collect();
    let skew: Vec<i64> = (0..4).flat_map(|i| (i + 1..4).map(move |k| (i, k))).map(|(i, k)| meet(&pl[i], &pl[k])).collect();
    println!("four lines, Plucker: {:?}; pairwise meet values {:?}, none 0, so no two meet", pl, skew);
    assert!(skew.iter().all(|&x| x != 0));
    let (a, b) = (plucker([1, 0, 0, 1], [0, 0, 1, 1], 0), plucker([0, 0, 0, 1], [0, -1, 1, 1], 0));
    let a2 = plucker([2, 0, -1, 1], [-1, 0, 2, 1], 0);
    println!("line A through (2,0,-1), (-1,0,2) instead: {:?} = {} x A", a2, s(q(a2[1] as i128, a[1] as i128)));
    assert!(a.iter().zip(&a2).all(|(x, y)| x * a2[1] == y * a[1]));
    for (nm, x, pts_) in [("A", &a, "(1,0,0), (0,0,1)"), ("B", &b, "(0,0,0), (0,-1,1)")] {
        println!("line {} through {}: {:?}; relation {}; meets L1..L4: {:?}", nm, pts_, x, quad(x), pl.iter().map(|y| meet(x, y)).collect::<Vec<_>>());
        assert!(quad(x) == 0 && pl.iter().all(|y| meet(x, y) == 0));
    }
    let col = [a[1], a[3], 0, -a[5]];                 // column 3 of the table: p13, p23, p33 = 0, p43 = -p34
    println!("line A, column 3 (p13, p23, p33, p43) = {}: the point (1, 0, 0)", tup(&col));
    assert!(col.iter().any(|&x| x != 0) && (0..4).all(|k| { let mut e = [0i64; 4]; e[k] = 1; meet(&a, &plucker(col, e, 0)) == 0 }));
    let plp: Vec<Vec<i64>> = pl.iter().map(|y| y.iter().map(|v| v.rem_euclid(p)).collect()).collect();
    let found: Vec<&Vec<i64>> = pts.iter().filter(|w| plp.iter().all(|y| meet(w, y).rem_euclid(p) == 0)).collect();
    let ab: Vec<Vec<i64>> = [&a, &b].iter().map(|x| normal(&x.iter().map(|v| v.rem_euclid(p)).collect::<Vec<_>>(), p)).collect();
    println!("search over all 806 lines mod 5 meeting all four: {}; A, B mod 5 = [{}]", found.len(), ab.iter().map(|v| tup(v)).collect::<Vec<_>>().join(", "));
    assert!(found.len() == 2 && found.iter().all(|w| ab.contains(w)));
    println!("mistake, node y^2 = x^3 - 3x + 2: 4a^3 + 27b^2 = {}, so j has no value", 4 * (-3i64).pow(3) + 27 * 2i64.pow(2));
    println!("figure, rho (-0.5, {:.6}); i (0, 1); i sqrt2 (0, {:.6}); 2i (0, 2); i/2 (0, 0.5)", r3, 2f64.sqrt());
    println!("ALL CHECKS PASS");
}
