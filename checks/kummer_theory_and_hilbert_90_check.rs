// Kummer and Artin-Schreier -- the same check as the Python, in Rust.  No crates.
// 1. Hilbert 90 in Q(i)/Q, against a brute-force list of Pythagorean triples.
// 2. Kummer over K = Q(omega): x^3 - 2, and the resolvent that turns the cyclic
//    cubic x^3 - 3x + 1 into a cube root.  3. Artin-Schreier in F_27 over F_3.
use std::collections::BTreeSet;
use std::f64::consts::PI;

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr { n: i64, d: i64 }
fn fr(n: i64, d: i64) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn add(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap() + b.n * a.d, a.d * b.d) }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.n).unwrap(), a.d * b.d) }
fn neg(a: Fr) -> Fr { Fr { n: -a.n, d: a.d } }
fn fs(x: Fr) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }
fn term(c: Fr, v: &str) -> String { if c == fr(1, 1) { v.into() } else if c == fr(-1, 1) { format!("-{v}") } else { format!("{}{v}", fs(c)) } }
fn cs(p: Fr, q: Fr, v: &str) -> String {                 // p + q v, zero parts dropped
    if q.n == 0 { return fs(p) }
    if p.n == 0 { return term(q, v) }
    format!("{} {} {}", fs(p), if q.n < 0 { "-" } else { "+" }, term(Fr { n: q.n.abs(), d: q.d }, v))
}
type G = (Fr, Fr);
fn g(a: i64, b: i64) -> G { (fr(a, 1), fr(b, 1)) }
fn gs(a: G) -> String { cs(a.0, a.1, "i") }
fn gm(a: G, b: G) -> G { (add(mul(a.0, b.0), neg(mul(a.1, b.1))), add(mul(a.0, b.1), mul(a.1, b.0))) }
fn gc(a: G) -> G { (a.0, neg(a.1)) }                     // sigma: i -> -i
fn gn(a: G) -> Fr { add(mul(a.0, a.0), mul(a.1, a.1)) }  // the norm
fn gd(a: G, b: G) -> G { let (t, n) = (gm(a, gc(b)), gn(b)); let iv = fr(n.d, n.n); (mul(t.0, iv), mul(t.1, iv)) }
fn h90(al: G, th: G) -> G { let t = gm(al, gc(th)); (add(th.0, t.0), add(th.1, t.1)) }
fn recipe(al: G) -> G { let b = h90(al, g(1, 0)); if b != g(0, 0) { b } else { h90(al, g(0, 1)) } }
fn prim(b: G) -> (i64, i64) {
    let d = b.0.d * b.1.d; let (m, n) = (b.0.n * (d / b.0.d), b.1.n * (d / b.1.d));
    let k = gcd(m, n); (m / k, n / k)
}
fn trip(m: i64, n: i64) -> (i64, i64, i64) { let (x, y) = (m * m - n * n, 2 * m * n); (x.min(y), x.max(y), m * m + n * n) }
fn tb(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn isqrt(x: i64) -> i64 { let mut r = (x as f64).sqrt() as i64; while r * r > x { r -= 1 } while (r + 1) * (r + 1) <= x { r += 1 } r }

type K = (Fr, Fr);                                       // p + q omega, omega^2 = -1 - omega
type L = [K; 3];                                         // c0 + c1 t + c2 t^2 over K
const KZ: K = (Fr { n: 0, d: 1 }, Fr { n: 0, d: 1 });
fn km(a: K, b: K) -> K { (add(mul(a.0, b.0), neg(mul(a.1, b.1))), add(add(mul(a.0, b.1), mul(a.1, b.0)), neg(mul(a.1, b.1)))) }
fn ka(a: K, b: K) -> K { (add(a.0, b.0), add(a.1, b.1)) }
fn ws(a: K) -> String { cs(a.0, a.1, "w") }
fn lm(x: &L, y: &L, c: &[K; 2]) -> L {                   // L = K[t] / (t^3 - c0 - c1 t)
    let mut t = [KZ; 5];
    for i in 0..3 { for j in 0..3 { t[i + j] = ka(t[i + j], km(x[i], y[j])) } }
    for d in [4, 3] { for k in 0..2 { t[d - 3 + k] = ka(t[d - 3 + k], km(t[d], c[k])) } t[d] = KZ }
    [t[0], t[1], t[2]]
}
fn la(x: &L, y: &L) -> L { [ka(x[0], y[0]), ka(x[1], y[1]), ka(x[2], y[2])] }
fn ks(k: K, x: &L) -> L { [km(k, x[0]), km(k, x[1]), km(k, x[2])] }
fn sub(x: &L, img: &L, c: &[K; 2]) -> L {                // apply sigma: t -> img, K fixed
    let (mut out, mut p) = ([KZ; 3], [(fr(1, 1), fr(0, 1)), KZ, KZ]);
    for j in 0..3 { out = la(&out, &ks(x[j], &p)); p = lm(&p, img, c) }
    out
}
fn ls(x: &L) -> String {
    let v: Vec<String> = (0..3).filter(|&j| x[j] != KZ).map(|j| format!("({}){}", ws(x[j]), ["", " t", " t^2"][j])).collect();
    if v.is_empty() { "0".into() } else { v.join(" + ") }
}
fn order(x: &L, img: &L, c: &[K; 2]) -> usize { let (mut k, mut y) = (1, sub(x, img, c)); while y != *x && k < 9 { k += 1; y = sub(&y, img, c) } k }

type E = [i64; 3];                                       // F_27: c0 + c1 alpha + c2 alpha^2
fn fm(x: E, y: E) -> E {
    let mut t = [0i64; 5];
    for i in 0..3 { for j in 0..3 { t[i + j] += x[i] * y[j] } }
    for d in [4, 3] { t[d - 3] += t[d]; t[d - 2] += t[d]; t[d] = 0 }
    [t[0] % 3, t[1] % 3, t[2] % 3]
}
fn fp(x: E, k: u32) -> E { let mut o = [1, 0, 0]; for _ in 0..k { o = fm(o, x) } o }
fn fa(x: E, y: E, s: i64) -> E { [(x[0] + s * y[0]).rem_euclid(3), (x[1] + s * y[1]).rem_euclid(3), (x[2] + s * y[2]).rem_euclid(3)] }
fn fe(x: E) -> String {
    let mut t: Vec<String> = [(x[2], "alpha^2"), (x[1], "alpha")].iter().filter(|p| p.0 != 0)
        .map(|p| format!("{}{}", if p.0 > 1 { p.0.to_string() } else { String::new() }, p.1)).collect();
    if x[0] > 0 { t.push(x[0].to_string()) }
    if t.is_empty() { "0".into() } else { t.join(" + ") }
}
fn tr(x: E) -> E { fa(fa(x, fp(x, 3), 1), fp(x, 9), 1) }

fn main() {
    println!("1. Hilbert 90 in Q(i)/Q");
    let al = (fr(3, 5), fr(4, 5)); let be = h90(al, g(1, 0));
    println!("alpha = {}, norm {}; theta = 1 gives beta = 1 + alpha = {}", gs(al), fs(gn(al)), gs(be));
    let pb = prim(be);
    println!("beta / sigma(beta) = {}; beta scaled to a Gaussian integer: {}", gs(gd(be, gc(be))), gs(g(pb.0, pb.1)));
    println!("(2 + i)^2 = {}; norm of 2 + i = {}: the triple 3, 4, 5", gs(gm(g(2, 1), g(2, 1))), fs(gn(g(2, 1))));
    let mut pts: Vec<G> = vec![];
    for c in 1..=100i64 { for p in -c..=c { for s in [1i64, -1] {
        let q = isqrt(c * c - p * p);
        if q * q == c * c - p * p && gcd(gcd(p, q), c) == 1 && (s == 1 || p * p != c * c) { pts.push((fr(p, c), fr(s * q, c))) }
    } } }
    let ok = pts.iter().all(|&a| gd(recipe(a), gc(recipe(a))) == a);
    let mut search = vec![];
    for c in 1..=100i64 { for a in 1..c { for b in a + 1..c { if a * a + b * b == c * c && gcd(a, b) == 1 { search.push((a, b, c)) } } } }
    search.sort();
    let mut by_h90: Vec<(i64, i64, i64)> = search.iter().map(|&(a, b, c)| {
        let (odd, even) = if a % 2 == 1 { (a, b) } else { (b, a) };
        let (m, n) = prim(recipe((fr(odd, c), fr(even, c)))); trip(m, n) }).collect();
    by_h90.sort();
    let mut euclid = vec![];
    for m in 2..11i64 { for n in 1..m { if gcd(m, n) == 1 && (m - n) % 2 == 1 && m * m + n * n <= 100 { euclid.push(trip(m, n)) } } }
    euclid.sort();
    let units = pts.iter().filter(|a| a.0.d == 1 && a.1.d == 1).count();
    println!("norm-1 points with denominator at most 100, by brute force: {} = {} x 8 + {}; each is beta/sigma(beta): {}", pts.len(), search.len(), units, tb(ok));
    println!("primitive triples with hypotenuse at most 100, by search: {}", search.len());
    println!("the same list from Hilbert 90's u + vi: {}; from Euclid's u, v: {}", tb(by_h90 == search), tb(euclid == search));
    println!("first four: {:?}", &search[..4]);

    println!("2. Kummer over K = Q(omega), omega^2 = -1 - omega");
    let (o, w) = ((fr(1, 1), fr(0, 1)), (fr(0, 1), fr(1, 1)));
    let kc = |n: i64| (fr(n, 1), fr(0, 1));
    let (c2, t, w2) = ([kc(2), KZ], [KZ, o, KZ], km(w, w));
    let (sa, b2) = ([KZ, w, KZ], [KZ, KZ, o]);
    println!("x^3 - 2: sigma(b) = omega b has order {}; beta = b^2 has beta = omega sigma(beta): {}",
             order(&t, &sa, &c2), tb(b2 == ks(w, &sub(&b2, &sa, &c2))));
    let (c3, sr) = ([kc(-1), kc(3)], [kc(-2), KZ, o]);
    let s1 = sub(&t, &sr, &c3); let s2 = sub(&s1, &sr, &c3);
    println!("x^3 - 3x + 1 = 0 at t: sigma(t) = t^2 - 2, sigma^2(t) = {}; order of sigma {}", ls(&s2), order(&t, &sr, &c3));
    let th = la(&la(&t, &ks(w2, &s1)), &ks(w, &s2)); let th3 = lm(&lm(&th, &th, &c3), &th, &c3);
    println!("resolvent b = t + omega^2 sigma(t) + omega sigma^2(t) = {}", ls(&th));
    println!("sigma(b) = omega b: {}; b^3 = {}; equals 27 omega^2: {}", tb(sub(&th, &sr, &c3) == ks(w, &th)), ls(&th3), tb(th3 == [km(kc(27), w2), KZ, KZ]));
    let r = 2.0 * (2.0 * PI / 9.0).cos(); let rs = [r, r * r - 2.0, 2.0 - r - r * r];
    let wn: Vec<(f64, f64)> = (0..3).map(|k| ((2.0 * PI * k as f64 / 3.0).cos(), (2.0 * PI * k as f64 / 3.0).sin())).collect();
    let tn = [(0..3).map(|j| rs[j] * wn[(3 - j) % 3].0).sum::<f64>(), (0..3).map(|j| rs[j] * wn[(3 - j) % 3].1).sum::<f64>()];
    let k9 = ((tn[1].atan2(tn[0]) * 9.0 / (2.0 * PI)).round() as i64).rem_euclid(9);
    println!("numerically: t = {:.10}; |b| = {:.10}; b / 3 = zeta_9^{}", r, (tn[0] * tn[0] + tn[1] * tn[1]).sqrt(), k9);

    println!("3. Artin-Schreier over F_3, alpha^3 = alpha + 1");
    let f: Vec<E> = (0..27).map(|k| [k % 3, k / 3 % 3, k / 9]).collect();
    let (a, one) = ([0, 1, 0], [1, 0, 0]);
    println!("x^3 - x - 1 at 0, 1, 2 mod 3: {:?}; Frobenius alpha^3 = {}", (0..3i64).map(|x| (x * x * x - x - 1).rem_euclid(3)).collect::<Vec<_>>(), fe(fp(a, 3)));
    let roots: Vec<E> = f.iter().copied().filter(|&x| fa(fa(fp(x, 3), x, -1), one, -1) == [0, 0, 0]).collect();
    println!("roots in F_27, trying all 27: {}; Frobenius order on alpha: {}", roots.iter().map(|&x| fe(x)).collect::<Vec<_>>().join(", "),
             (1..4u32).find(|&k| fp(a, 3u32.pow(k)) == a).unwrap());
    let ap: BTreeSet<E> = f.iter().map(|&x| fa(fp(x, 3), x, -1)).collect();
    let tz: BTreeSet<E> = f.iter().copied().filter(|&x| tr(x) == [0, 0, 0]).collect();
    println!("values of beta^3 - beta: {}; trace-zero elements: {}; same set: {}", ap.len(), tz.len(), tb(ap == tz));
    let nz: Vec<E> = f.iter().copied().filter(|&x| x != [0, 0, 0]).collect();
    let n1: BTreeSet<E> = nz.iter().copied().filter(|&x| fp(x, 13) == one).collect();
    let q1: BTreeSet<E> = nz.iter().map(|&x| fm(x, fp(fp(x, 3), 25))).collect();
    println!("norm-1 elements, x^13 = 1: {}; values of beta / beta^3: {}; same set: {}", n1.len(), q1.len(), tb(n1 == q1));
    let (a2, tt) = ([2, 0, 0], fp(a, 2));
    let iv = tr(tt)[0];
    let s = fa(fm(a2, fp(tt, 3)), fm(fa(a2, a2, 1), fp(tt, 9)), 1);
    let bb = [iv * s[0] % 3, iv * s[1] % 3, iv * s[2] % 3];
    println!("additive recipe, Tr(alpha^2) = {}: beta = {}; sigma(beta) - beta = {}", tr(tt)[0], fe(bb), fe(fa(fp(bb, 3), bb, -1)));

    println!("4. what breaks");
    println!("alpha = -1 with theta = 1: beta = {}; theta = i gives {}", gs(h90(g(-1, 0), g(1, 0))), gs(h90(g(-1, 0), g(0, 1))));
    let small: Vec<G> = (-5..6).flat_map(|x| (-5..6).map(move |y| g(x, y))).filter(|&b| b != g(0, 0)).collect();
    let norms: BTreeSet<String> = small.iter().map(|&b| fs(gn(gd(b, gc(b))))).collect();
    println!("norm of 1 + i: {}; norms of beta/sigma(beta) over {} small beta: {}", fs(gn(g(1, 1))), small.len(), norms.into_iter().collect::<Vec<_>>().join(", "));
    let real = (0..3).filter(|&k| (2.0 * PI * k as f64 / 3.0).sin().abs() < 1e-12).count();
    println!("x^3 - 2 over Q: real roots {} of 3, so Q(2^(1/3)) has {} automorphism", real, real);
    let cubes: BTreeSet<E> = f.iter().map(|&x| fp(x, 3)).collect();
    let binom = (0..3i64).all(|c| [(-c * c * c).rem_euclid(3), 3 * c * c % 3, (-3 * c).rem_euclid(3)] == [(-c).rem_euclid(3), 0, 0]);
    println!("cubes in F_27: {} distinct; (x - c)^3 = x^3 - c mod 3 for c = 0, 1, 2: {}", cubes.len(), tb(binom));
    let asr: Vec<usize> = (0..3i64).map(|q| (0..3i64).filter(|x| (x * x * x - x - q).rem_euclid(3) == 0).count()).collect();
    println!("roots of x^3 - x - a in F_3 for a = 0, 1, 2: {:?}", asr);
    assert!(ok && pts.len() == 132 && pts.len() == 8 * search.len() + units && gs(g(pb.0, pb.1)) == "2 + i");     // recipe against brute force
    assert!(by_h90 == search && search == euclid && search.len() == 16);  // three roads to the triples
    assert!(th3 == [(fr(-27, 1), fr(-27, 1)), KZ, KZ] && 3 * k9 % 9 == 6); // exact resolvent against floats
    assert!(roots == vec![a, [1, 1, 0], [2, 1, 0]] && ap == tz && n1 == q1);
    assert!(fa(fp(bb, 3), bb, -1) == one && asr == vec![3, 0, 0]);
    assert!(sub(&th, &sr, &c3) == ks(w, &th) && order(&t, &sr, &c3) == 3 && order(&t, &sa, &c2) == 3 && b2 == ks(w, &sub(&b2, &sa, &c2))); // Kummer
    println!("ALL CHECKS PASS");
}
