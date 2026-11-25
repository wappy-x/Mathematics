// Geometric invariant theory in outline -- the same check as the Python, in Rust.
// No crates.  Quotients by group actions, decided exactly: the sign group on
// the plane, the scalars giving P^2, a torus whose fibre over 0 holds orbits that
// are not closed, an additive group that breaks the rule, and four points on a
// line, whose quotient coordinate j is reached by three roads and counted mod 37.
use std::collections::{BTreeMap, BTreeSet};
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Debug, Hash)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
fn mul(a: Q, b: Q) -> Q {                          // cancel across first, then multiply
    let (g, h) = (gcd(a.n, b.d).max(1), gcd(b.n, a.d).max(1));
    q((a.n / g).checked_mul(b.n / h).unwrap(), (a.d / h).checked_mul(b.d / g).unwrap()) }
fn add(a: Q, b: Q) -> Q {
    let l = (a.d / gcd(a.d, b.d)).checked_mul(b.d).unwrap();
    q((l / a.d).checked_mul(a.n).unwrap().checked_add((l / b.d).checked_mul(b.n).unwrap()).unwrap(), l) }
fn sub(a: Q, b: Q) -> Q { add(a, mul(z(-1), b)) }
fn div(a: Q, b: Q) -> Q { mul(a, q(b.d, b.n)) }
fn pw(a: Q, k: u32) -> Q { (0..k).fold(z(1), |acc, _| mul(acc, a)) }
fn s(a: Q) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn ls(v: &[Q]) -> String { format!("[{}]", v.iter().map(|&x| s(x)).collect::<Vec<_>>().join(", ")) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn orbits<P: Ord + Clone>(pts: &[P], all: impl Fn(&P) -> Vec<P>) -> Vec<Vec<P>> {
    let (mut seen, mut out) = (BTreeSet::new(), Vec::new());
    for pt in pts {
        if !seen.contains(pt) {
            let orb: BTreeSet<P> = all(pt).into_iter().collect();
            seen.extend(orb.iter().cloned());
            out.push(orb.into_iter().collect::<Vec<P>>());
        }
    }
    out.sort(); out }
fn classes<P: Ord + Clone, K: Ord>(pts: &[P], key: impl Fn(&P) -> K) -> Vec<Vec<P>> {
    let mut m: BTreeMap<K, Vec<P>> = BTreeMap::new();
    for pt in pts { m.entry(key(pt)).or_default().push(pt.clone()) }
    let mut out: Vec<Vec<P>> = m.into_values().map(|mut c| { c.sort(); c }).collect();
    out.sort(); out }
fn pmod(b: i64, e: i64, m: i64) -> i64 { (0..e).fold(1, |acc, _| acc * b.rem_euclid(m) % m) }
fn cross(z1: Q, z2: Q, z3: Q, z4: Q) -> Q {        // send z1, z2, z3 to 0, infinity, 1: lambda is where z4 lands
    div(mul(sub(z4, z1), sub(z3, z2)), mul(sub(z4, z2), sub(z3, z1))) }
fn jl(l: Q) -> Q {                                 // j as a function of the cross-ratio
    div(mul(z(256), pw(add(sub(mul(l, l), l), z(1)), 3)), mul(mul(l, l), pw(sub(l, z(1)), 2))) }
fn quartic(roots: &[Q]) -> Vec<Q> {                // coefficients of prod (x - r y), from x^4 down to y^4
    let mut c = vec![z(1)];
    for &r in roots {
        c = (0..=c.len()).map(|i| sub(if i < c.len() { c[i] } else { z(0) }, if i > 0 { mul(r, c[i - 1]) } else { z(0) })).collect();
    }
    c }
fn ij(c: &[Q]) -> (Q, Q) {                         // I, J of a0 x^4 + 4a1 x^3y + 6a2 x^2y^2 + 4a3 xy^3 + a4 y^4
    let (a, b, cc, d, e) = (c[0], div(c[1], z(4)), div(c[2], z(6)), div(c[3], z(4)), c[4]);
    let i = add(sub(mul(a, e), mul(z(4), mul(b, d))), mul(z(3), mul(cc, cc)));
    let j = sub(sub(sub(add(mul(a, mul(cc, e)), mul(z(2), mul(b, mul(cc, d)))), mul(a, mul(d, d))), mul(mul(b, b), e)), pw(cc, 3));
    (i, j) }
fn j_ij(c: &[Q]) -> Q { let (i, j) = ij(c); div(mul(z(1728), pw(i, 3)), sub(pw(i, 3), mul(z(27), mul(j, j)))) }
fn j_legendre(l: Q) -> Q {                         // y^2 = x(x - 1)(x - lam), moved to short Weierstrass form
    let (p, qq) = (mul(z(-1), add(z(1), l)), l);
    let a = sub(qq, div(mul(p, p), z(3)));
    let b = add(div(mul(z(-1), mul(p, qq)), z(3)), div(mul(z(2), pw(p, 3)), z(27)));
    div(mul(z(1728 * 4), pw(a, 3)), add(mul(z(4), pw(a, 3)), mul(z(27), mul(b, b)))) }
fn act(c: &[Q], g: [Q; 4]) -> Vec<Q> {             // substitute x -> g0 x + g1 y, y -> g2 x + g3 y
    let mut out = vec![z(0); 5];
    for (k, &ck) in c.iter().enumerate() {
        let mut term = vec![z(1)];
        for m in 0..4 {
            let lin = if m < 4 - k { (g[0], g[1]) } else { (g[2], g[3]) };
            term = (0..=term.len()).map(|i| add(if i < term.len() { mul(term[i], lin.0) } else { z(0) },
                                                 if i > 0 { mul(term[i - 1], lin.1) } else { z(0) })).collect();
        }
        for i in 0..5 { out[i] = add(out[i], mul(ck, term[i])) }
    }
    out }
fn main() {
    let p: i64 = 7;
    let plane: Vec<(i64, i64)> = (0..p).flat_map(|x| (0..p).map(move |y| (x, y))).collect();
    let signs = orbits(&plane, |v| vec![*v, ((-v.0).rem_euclid(p), (-v.1).rem_euclid(p))]);
    let sign_cls = classes(&plane, |v| (v.0 * v.0 % p, v.0 * v.1 % p, v.1 * v.1 % p));
    println!("signs on F_7^2: {} orbits, {} classes of equal (x^2, xy, y^2); same split: {}", signs.len(), sign_cls.len(), yn(signs == sign_cls));
    let cone7: BTreeSet<(i64, i64, i64)> = (0..p * p * p).map(|n| (n / (p * p), n / p % p, n % p)).filter(|&(u, v, w)| (v * v - u * w) % p == 0).collect();
    println!("cone v^2 = uw over F_7: {} points; values of (x^2, xy, y^2) on F_7^2: {} of them", cone7.len(), sign_cls.len());
    let inv_deg: Vec<i64> = (0..9).map(|d| if d % 2 == 0 { d + 1 } else { 0 }).collect();
    let cone_deg: Vec<i64> = (0..9).map(|d: i64| if d % 2 == 1 { 0 } else {
        let h = d / 2;
        (0..=h).map(|i| [0, 1].iter().map(|e| (0..=h).filter(|k| i + e + k == h).count() as i64).sum::<i64>()).sum() }).collect();
    println!("invariants of degree 0 to 8: {:?}; cone uw = v^2 by degree: {:?}", inv_deg, cone_deg);
    let space: Vec<(i64, i64, i64)> = (0..125).map(|n| (n / 25, n / 5 % 5, n % 5)).filter(|&v| v != (0, 0, 0)).collect();
    let lines5 = orbits(&space, |v| (1..5).map(|t| (t * v.0 % 5, t * v.1 % 5, t * v.2 % 5)).collect());
    println!("scalars on F_5^3 minus 0: {} orbits; P^2 over F_5 by charts: 25 + 5 + 1 = {}", lines5.len(), 25 + 5 + 1);
    println!("degrees 0 to 4 whose monomials in x, y, z are fixed by t = 2: {:?}", (0..5).filter(|&d| pw(z(2), d) == z(1)).collect::<Vec<u32>>());
    let torus = orbits(&plane, |v| (1..p).map(|t| (t * v.0 % p, pmod(t, p - 2, p) * v.1 % p)).collect());
    let mut fibre0: Vec<usize> = torus.iter().filter(|o| o[0].0 * o[0].1 % p == 0).map(|o| o.len()).collect(); fibre0.sort();
    let xy_vals: BTreeSet<i64> = plane.iter().map(|v| v.0 * v.1 % p).collect();
    println!("torus (tx, y/t) on F_7^2: {} orbits, {} values of xy; orbit sizes over xy = 0: {:?}", torus.len(), xy_vals.len(), fibre0);
    let fixed: Vec<(i32, i32)> = (0..5).flat_map(|a| (0..5 - a).map(move |b| (a, b))).filter(|&(a, b): &(i32, i32)| pw(z(2), (a - b).unsigned_abs()) == z(1)).collect();
    println!("monomials x^a y^b, a + b <= 4, fixed by t = 2: {:?}", fixed);
    let add_orbs = orbits(&plane, |v| (0..p).map(|s| (v.0, (v.1 + s * v.0) % p)).collect());
    println!("additive group (x, y + sx) on F_7^2: {} orbits, all closed; the invariant x takes {} values", add_orbs.len(), p);
    let posts: Vec<Q> = [0, 10, 20, 30].iter().map(|&v| z(v)).collect();
    let photo: Vec<Q> = posts.iter().map(|&v| div(mul(z(600), v), add(v, z(20)))).collect();
    let lam = cross(posts[0], posts[1], posts[2], posts[3]);
    let perms: Vec<[usize; 4]> = (0..256).map(|n| [n / 64, n / 16 % 4, n / 4 % 4, n % 4]).filter(|o| BTreeSet::from(*o).len() == 4).collect();
    let mut six: Vec<Q> = Vec::new();
    for o in &perms { let v = cross(posts[o[0]], posts[o[1]], posts[o[2]], posts[o[3]]); if !six.contains(&v) { six.push(v) } }
    six.sort_by(|x, y| (x.n * y.d).cmp(&(y.n * x.d)));
    println!("posts at {} m; photo at {} px", ls(&posts), ls(&photo));
    println!("cross-ratio of the posts {}, of the photo {}", s(lam), s(cross(photo[0], photo[1], photo[2], photo[3])));
    println!("24 orderings give {} values: {}", six.len(), ls(&six));
    let mut js: Vec<Q> = six.iter().map(|&v| jl(v)).collect(); js.dedup();
    println!("j of the six: {}", ls(&js));
    let top = add(sub(mul(lam, lam), lam), z(1));
    println!("by hand at 3/4: lambda^2 - lambda + 1 = {}, cubed {}, times 256 = {}; lambda^2 (lambda - 1)^2 = {}",
             s(top), s(pw(top, 3)), s(mul(z(256), pw(top, 3))), s(mul(mul(lam, lam), pw(sub(lam, z(1)), 2))));
    println!("j by the formula {}; by I and J of the posts {}, of the photo {}; by the Legendre curve {}",
             s(jl(lam)), s(j_ij(&quartic(&posts))), s(j_ij(&quartic(&photo))), s(j_legendre(lam)));
    let (i0, j0) = ij(&quartic(&posts));
    let (i1, j1) = ij(&act(&quartic(&posts), [z(2), z(1), z(1), z(1)]));
    println!("posts quartic: coefficients {}; a0..a4 = {}", ls(&quartic(&posts)), ls(&quartic(&posts).iter().zip([1, 4, 6, 4, 1]).map(|(&v, k)| div(v, z(k))).collect::<Vec<Q>>()));
    println!("posts quartic: I = {}, J = {}; after x -> 2x + y, y -> x + y: I = {}, J = {}", s(i0), s(j0), s(i1), s(j1));
    let hq = [z(0), z(1), z(0), z(-1), z(0)]; let h = z(-1);
    println!("harmonic lambda = -1, 2, 1/2: j = {}; at -1: 256 x {}; xy(x - y)(x + y) has J = {}, j = {}",
             ls(&[jl(z(-1)), jl(z(2)), jl(q(1, 2))]), s(div(pw(add(sub(mul(h, h), h), z(1)), 3), mul(mul(h, h), pw(sub(h, z(1)), 2)))), s(ij(&hq).1), s(j_ij(&hq)));
    let hs = [z(-3), z(0), z(1), z(3)]; // a harmonic set: lambda = -1 in some order
    let hv: Vec<Q> = perms.iter().map(|o| cross(hs[o[0]], hs[o[1]], hs[o[2]], hs[o[3]])).collect();
    let hset: Vec<Q> = { let mut v = hv.clone(); v.sort_by(|x, y| sub(*x, *y).n.cmp(&0)); v.dedup(); v };
    let hcnt: Vec<usize> = hset.iter().map(|v| hv.iter().filter(|w| *w == v).count()).collect();
    println!("harmonic set -3, 0, 1, 3: {} orderings give {}, orderings per value {:?}", hv.len(), ls(&hset), hcnt);
    let m: i64 = 37;
    let inv = |l: i64| pmod(l, m - 2, m);
    let lams: Vec<i64> = (2..m).collect();
    let lam_orbs = orbits(&lams, |&l| vec![l, inv(l), (1 - l).rem_euclid(m), inv((1 - l).rem_euclid(m)), l * inv(l - 1) % m, (l - 1) * inv(l) % m]);
    let jm = |l: i64| 256 * pmod(l * l - l + 1, 3, m) % m * inv(l * l % m * (l - 1) % m * (l - 1) % m) % m;
    let j_cls = classes(&lams, |&l| jm(l));
    let mut osz: Vec<usize> = lam_orbs.iter().map(|o| o.len()).collect(); osz.sort();
    println!("mod {}: {} orbits of the six moves on lambda = 2..{}, {} values of j; same split: {}; orbit sizes {:?}",
             m, lam_orbs.len(), m - 1, j_cls.len(), yn(lam_orbs == j_cls), osz);
    let w3 = (2..m).find(|&x| pmod(x, 3, m) == 1).unwrap(); let eq = [0, 1, w3, w3 * w3 % m]; // 0 and the three cube roots of 1
    let ev: Vec<i64> = perms.iter().map(|o| (eq[o[3]] - eq[o[0]]) * (eq[o[2]] - eq[o[1]]) % m * inv(((eq[o[3]] - eq[o[1]]) * (eq[o[2]] - eq[o[0]])).rem_euclid(m)) % m).map(|v| v.rem_euclid(m)).collect();
    let eset: Vec<i64> = ev.iter().cloned().collect::<BTreeSet<i64>>().into_iter().collect();
    let ecnt: Vec<usize> = eset.iter().map(|v| ev.iter().filter(|w| *w == v).count()).collect();
    let jeq: Vec<i64> = ev.iter().map(|&l| jm(l)).collect::<BTreeSet<i64>>().into_iter().collect();
    println!("mod {}: equianharmonic set {:?}: values {:?}, orderings per value {:?}, j = {:?}", m, eq, eset, ecnt, jeq);
    for (name, c) in [("x y^3, triple root", [0, 0, 0, 1, 0]), ("x^2 y^2, two double roots", [0, 0, 1, 0, 0]),
                      ("x^2 y^2 - x^3 y, one double root", [0, -1, 1, 0, 0])] {
        let cq: Vec<Q> = c.iter().map(|&v| z(v)).collect();
        let (i, j) = ij(&cq);
        let wts: Vec<i64> = (0..5).filter(|&k| c[k] != 0).map(|k| 4 - 2 * k as i64).collect();
        println!("{}: I = {}, J = {}, I^3 - 27J^2 = {}; torus weights {:?}", name, s(i), s(j), s(sub(pw(i, 3), mul(z(27), mul(j, j)))), wts);
    }
    let t = q(1, 10);
    println!("x^2 y^2 - x^3 y moved by x -> tx, y -> y/t at t = 1/10: x^3 y coefficient {}, x^2 y^2 coefficient 1", s(mul(z(-1), mul(t, t))));
    println!("mistake 1, Spec of the scalars' invariants: 1 point, not the {} points of P^2 over F_5", lines5.len());
    println!("mistake 2, every torus orbit a point: {} points, not {}", torus.len(), p);
    println!("mistake 3, lambda as the coordinate of unordered points: {} values for one photo, not 1", six.len());
    println!("mistake 4, a non-reductive group: {} closed orbits, {} values of the invariant", add_orbs.len(), p);
    println!("figure, square -3 to 3 at 60 px per unit; (1, 1) at (270, 150); (1, -1) at (270, 270); origin at (210, 210)");
    assert!(signs == sign_cls && signs.len() as i64 == (p * p - 1) / 2 + 1);    // finite group: classes = orbits
    assert!(inv_deg == cone_deg);                                               // two counts of invariants
    assert!(lines5.len() == 31 && torus.len() as i64 == p + 2 && fibre0 == vec![1, 6, 6]);
    assert!(add_orbs.len() as i64 == 2 * p - 1 && torus.iter().all(|o| o.iter().all(|v| v.0 * v.1 % p == o[0].0 * o[0].1 % p)));
    assert!(lam == cross(photo[0], photo[1], photo[2], photo[3]) && lam == q(3, 4) && six.len() == 6);
    assert!(jl(lam) == j_ij(&quartic(&posts)) && jl(lam) == j_ij(&quartic(&photo)) && jl(lam) == j_legendre(lam));
    assert!(js.len() == 1 && (i0, j0) == (i1, j1));                             // j forgets the order
    assert!(jl(z(-1)) == z(1728) && j_legendre(z(-1)) == z(1728));
    assert!(hset == vec![z(-1), q(1, 2), z(2)] && hcnt == vec![8, 8, 8]);       // harmonic: 3 values
    assert!(ecnt == vec![12, 12] && jeq == vec![0]);                             // equianharmonic: 2 values
    assert!(cone7.len() as i64 == p * p && plane.iter().all(|v| cone7.contains(&(v.0 * v.0 % p, v.0 * v.1 % p, v.1 * v.1 % p))) && cone7.len() > sign_cls.len());
    assert!(lam_orbs == j_cls);                                                 // fibres of j are orbits
    println!("ALL CHECKS PASS");
}
