// Gauss composition and genus theory for positive binary quadratic forms (a, b, c) = a x^2 + b x y + c y^2.
// Road A composes forms by Dirichlet's united forms; road B multiplies the matching ideals as lattices.
use std::collections::BTreeSet;
type F = (i64, i64, i64);
type E = (i64, i64);

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn red(f: F, trail: &mut Vec<F>) -> F { // reduce: -a < b <= a <= c, b >= 0 when a = c (Reduced forms card)
    let (mut a, mut b, mut c) = f;
    while !(-a < b && b <= a && a <= c) {
        let k = (a - b).div_euclid(2 * a); let (nb, nc) = (b + 2 * a * k, a * k * k + b * k + c); b = nb; c = nc;
        if k != 0 { trail.push((a, b, c)); }
        if c < a { let t = a; a = c; c = t; b = -b; trail.push((a, b, c)); }
    }
    if a == c && b < 0 { (a, -b, c) } else { (a, b, c) }
}
fn rd(f: F) -> F { red(f, &mut vec![]) }
fn forms(d: i64) -> Vec<F> { // the reduced primitive forms of discriminant d < 0
    let mut out = vec![];
    for a in 1..=((-d as f64 / 3.0).sqrt() as i64) { for b in -a + 1..=a {
        if (b * b - d) % (4 * a) != 0 { continue; }
        let f = (a, b, (b * b - d) / (4 * a));
        if rd(f) == f && gcd(gcd(a, b), f.2) == 1 { out.push(f); }
    } }
    out
}
fn val(f: F, x: i64, y: i64) -> i64 { f.0 * x * x + f.1 * x * y + f.2 * y * y }
fn egcd(a: i64, b: i64) -> (i64, i64) { if b == 0 { (1, 0) } else { let (u, v) = egcd(b, a % b); (v, u - a / b * v) } }
fn mv(g: F, m: i64) -> F { // an equivalent form whose first number shares no factor with m
    let (x, y) = (0..20).flat_map(|y| (0..20).map(move |x| (x, y))).find(|&(x, y)| gcd(x, y) == 1 && gcd(val(g, x, y), m) == 1).unwrap();
    let (s, r) = egcd(x, y); let r = -r; // x s - y r = 1, so (X, Y) -> (x X + r Y, y X + s Y) can be undone
    (val(g, x, y), 2 * g.0 * x * r + g.1 * (x * s + y * r) + 2 * g.2 * y * s, val(g, r, s))
}
fn unite(f: F, g0: F) -> (F, i64, F) { // road A: Dirichlet composition, after making gcd(a1, a2, (b1 + b2)/2) = 1
    let g = if gcd(gcd(f.0, g0.0), (f.1 + g0.1) / 2) > 1 { mv(g0, f.0) } else { g0 };
    let ((a1, b1, c1), (a2, b2, _)) = (f, g); let d = b1 * b1 - 4 * a1 * c1; let aa = a1 * a2;
    let bb = (b1.rem_euclid(2 * a1)..2 * aa).step_by((2 * a1) as usize)
        .find(|&bq| (bq - b2) % (2 * a2) == 0 && (bq * bq - d) % (4 * aa) == 0).unwrap();
    (g, bb, (aa, bb, (bb * bb - d) / (4 * aa)))
}
fn comp(f: F, g: F) -> F { rd(unite(f, g).2) }
// Road B: the order of discriminant d is Z[t], t^2 = d/4 or t^2 = t + (d - 1)/4; x + y t is the pair (x, y).
fn emul(d: i64, u: E, v: E) -> E { let r = d.rem_euclid(4); let s = (d - r) / 4; let t = u.1 * v.1; (u.0 * v.0 + t * s, u.0 * v.1 + u.1 * v.0 + t * r) }
fn hnf(vs: Vec<E>) -> F { // the lattice spanned by integer vectors, as (A, K, C): basis A and K + C t
    let mut vs: Vec<E> = vs.into_iter().filter(|v| *v != (0, 0)).collect();
    while vs.iter().filter(|v| v.1 != 0).count() > 1 {
        vs.sort_by_key(|v| (v.1 == 0, v.1.abs())); let p = vs[0];
        let rest: Vec<E> = vs[1..].iter().map(|v| { let k = v.1.div_euclid(p.1); (v.0 - k * p.0, v.1 - k * p.1) }).collect();
        vs = vec![p]; vs.extend(rest);
    }
    let mut p = *vs.iter().find(|v| v.1 != 0).unwrap(); if p.1 < 0 { p = (-p.0, -p.1); }
    let a = vs.iter().filter(|v| v.1 == 0).fold(0, |g, v| gcd(g, v.0));
    (a, p.0.rem_euclid(a), p.1)
}
fn to_ideal(d: i64, f: F) -> F { hnf(vec![(f.0, 0), ((-f.1 - d.rem_euclid(4)).div_euclid(2), 1)]) } // [a, (-b + sqrt D)/2]
fn imul(d: i64, i: F, j: F) -> F { let mut v = vec![]; for u in [(i.0, 0), (i.1, i.2)] { for w in [(j.0, 0), (j.1, j.2)] { v.push(emul(d, u, w)); } } hnf(v) }
fn to_form(d: i64, i: F) -> F { // N(A x - beta y) / N(I), with beta = K + C t
    let (a, k, c) = i; let tr = d.rem_euclid(4); let nb = k * k + k * c * tr + c * c * (tr - d) / 4;
    assert!(a % c == 0 && (2 * k + c * tr) % c == 0 && nb % (a * c) == 0);
    rd((a / c, -(2 * k + c * tr) / c, nb / (a * c)))
}
fn comp_b(d: i64, f: F, g: F) -> F { to_form(d, imul(d, to_ideal(d, f), to_ideal(d, g))) }
fn mu(d: i64) -> u32 { // Gauss's count: the number of genera is 2^(mu - 1)
    let n = if d.rem_euclid(4) == 1 { -d } else { -d / 4 };
    let r = (3..=n).step_by(2).filter(|&p| n % p == 0 && (3..).step_by(2).take_while(|q| q * q <= p).all(|q| p % q != 0)).count() as u32;
    if d.rem_euclid(4) == 1 { r } else { r + if n % 4 == 3 { 0 } else if n % 8 == 0 { 2 } else { 1 } }
}
fn residues(d: i64, f: F) -> BTreeSet<i64> {
    let mut s = BTreeSet::new();
    for x in 0..-d { for y in 0..-d { let v = val(f, x, y); if gcd(v, d) == 1 { s.insert(v.rem_euclid(-d)); } } }
    s
}
fn genera(d: i64) -> usize { let fs = forms(d); fs.len() / fs.iter().map(|&f| comp(f, f)).collect::<BTreeSet<F>>().len() }
fn yn(t: bool) -> &'static str { if t { "yes" } else { "no" } }
fn first<T: std::fmt::Debug>(v: &[T], k: usize) -> String { format!("{:?}", &v[..k.min(v.len())]) }

fn main() {
    let d = -20; let fs = forms(d); let (f0, f1) = (fs[0], fs[1]);
    println!("D = -20: reduced forms {:?} ; ideal of (2, 2, 3) as (A, K, C): {:?} = (2, 1 + sqrt-5); back to a form: {:?}", fs, to_ideal(d, f1), to_form(d, to_ideal(d, f1)));
    let (g, bb, u) = unite(f1, f1); let mut tr = vec![]; let r = red(u, &mut tr);
    println!("compose (2, 2, 3) with itself: gcd(2, 2, 2) = {} ; second form moved to {:?} ; B = {} ; composite {:?} ; reduction {:?} -> {:?}", gcd(gcd(2, 2), 2), g, bb, u, tr, r);
    let i2 = imul(d, to_ideal(d, f1), to_ideal(d, f1));
    println!("ideal road: (2, 1 + sqrt-5)^2 = {:?} = (2) as a lattice, form {:?} ; united forms (2, 10, 15) and (3, 10, 10): {:?} {:?}", i2, to_form(d, i2), rd((2, 10, 15)), rd((3, 10, 10)));
    assert!(r == f0 && f0 == to_form(d, i2) && i2 == hnf(vec![(2, 0), emul(d, (2, 0), (0, 1))]) && to_form(d, to_ideal(d, f1)) == f1);
    let (mut ok1, mut ok2) = (true, true);
    for x in -6..7 { for y in -6..7 { for z in -6..7 { for w in -6..7 {
        let (p, q) = (2 * x * z + x * w + y * z - 2 * y * w, x * w + y * z + y * w);
        ok1 &= val(f1, x, y) * val(f1, z, w) == p * p + 5 * q * q;
        ok2 &= val((2, 10, 15), x, y) * val((3, 10, 10), z, w) == val((6, 10, 5), x * z - 5 * y * w, 2 * x * w + 3 * y * z + 10 * y * w);
    } } } }
    let (x, y, z, w) = (0, 1, 1, 1);
    println!("product identities on all 13^4 inputs: {}, {}; 3 x 7 = f(0, 1) f(1, 1) = ({})^2 + 5 ({})^2 = {}", yn(ok1), yn(ok2),
        2 * x * z + x * w + y * z - 2 * y * w, x * w + y * z + y * w, val(f1, x, y) * val(f1, z, w));
    assert!(ok1 && ok2);
    for d in [-20, -56, -84] {
        let fs = forms(d);
        let tab: Vec<Vec<usize>> = fs.iter().map(|&f| fs.iter().map(|&g| fs.iter().position(|&h| h == comp(f, g)).unwrap()).collect()).collect();
        assert!(fs.iter().all(|&f| fs.iter().all(|&g| comp(f, g) == comp_b(d, f, g))));
        println!("D = {}: classes {:?}; composition table by index (roads A and B agree): {:?}", d, fs, tab);
    }
    let n = 10000usize; let mut isp = vec![true; n + 1]; isp[0] = false; isp[1] = false;
    for i in 2..101 { if isp[i] { let mut j = i * i; while j <= n { isp[j] = false; j += i; } } }
    let ps: Vec<i64> = (0..=n).filter(|&p| isp[p]).map(|p| p as i64).collect();
    let reps = |f: F| -> BTreeSet<i64> { let mut s = BTreeSet::new(); for x in -120..121 { for y in 0..121 { let v = val(f, x, y); if v > 0 && v <= n as i64 { s.insert(v); } } } s };
    let (r15, r223, r114, r207, r325) = (reps((1, 0, 5)), reps((2, 2, 3)), reps((1, 0, 14)), reps((2, 0, 7)), reps((3, 2, 5)));
    let c19: Vec<i64> = ps.iter().cloned().filter(|p| r15.contains(p)).collect(); let c37: Vec<i64> = ps.iter().cloned().filter(|p| r223.contains(p)).collect();
    println!("primes below 10,000: {} ; x^2 + 5y^2: {} ; 2x^2 + 2xy + 3y^2: {} ; first {} {} ; 3^2 + 5 x 2^2 = {}", ps.len(), c19.len(), c37.len(), first(&c19, 4), first(&c37, 5), val((1, 0, 5), 3, 2));
    assert!(c19 == ps.iter().cloned().filter(|&p| p == 5 || [1, 9].contains(&(p % 20))).collect::<Vec<i64>>());
    assert!(c37 == ps.iter().cloned().filter(|&p| p == 2 || [3, 7].contains(&(p % 20))).collect::<Vec<i64>>());
    for d in [-20, -56] {
        let all: Vec<Vec<i64>> = forms(d).iter().map(|&f| residues(d, f).into_iter().collect()).collect();
        println!("D = {}: values prime to {}, mod {}, of each class: {:?}", d, -d, -d, all);
    }
    let h = residues(-56, (1, 0, 14)); let pg: Vec<i64> = ps.iter().cloned().filter(|p| h.contains(&(p % 56))).collect();
    let a14: Vec<i64> = pg.iter().cloned().filter(|p| r114.contains(p)).collect(); let b27: Vec<i64> = pg.iter().cloned().filter(|p| r207.contains(p)).collect();
    let c35 = ps.iter().filter(|p| r325.contains(p)).count();
    println!("D = -56, primes below 10,000 in the principal genus: {} ; x^2 + 14y^2: {} ; 2x^2 + 7y^2: {} ; 3x^2 + 2xy + 5y^2: {}", pg.len(), a14.len(), b27.len(), c35);
    println!("same residue, different forms: 3^2 + 14 x 1^2 = {} and 2 x 6^2 + 7 x 1^2 = {} ; both {} mod 56; first of each {} {}", val((1, 0, 14), 3, 1), val((2, 0, 7), 6, 1), 79 % 56, first(&a14, 5), first(&b27, 5));
    let mut ab: Vec<i64> = a14.iter().chain(b27.iter()).cloned().collect(); ab.sort();
    let pw = |b: i64, e: i64, m: i64| -> i64 { let (mut r, mut b, mut e) = (1i64, b % m, e); while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r };
    assert!(ab == pg && !a14.iter().any(|p| b27.contains(p)) && pg == ps.iter().cloned().filter(|&p| p > 7 && pw((-14i64).rem_euclid(p), (p - 1) / 2, p) == 1 && pw(p, 3, 7) == 1).collect::<Vec<i64>>());
    let quart: Vec<i64> = ps.iter().cloned().filter(|&p| p > 7 && pw((-14i64).rem_euclid(p), (p - 1) / 2, p) == 1 && (0..p).any(|t| ((t * t + 1) * (t * t + 1) - 8) % p == 0)).collect();
    println!("Cox's test, (-14/p) = 1 and (t^2 + 1)^2 = 8 mod p solvable, picks {} primes; equal to the x^2 + 14y^2 list: {}", quart.len(), yn(quart == a14));
    assert!(quart == a14);
    println!("D, h, genera by squares (Gauss), by Gauss's count 2^(mu - 1), by residue sets, classes per genus, squares = principal genus");
    for d in [-15, -20, -23, -56, -84, -96, -260, -420] {
        let fs = forms(d); let rs: Vec<BTreeSet<i64>> = fs.iter().map(|&f| residues(d, f)).collect();
        let sq: BTreeSet<F> = fs.iter().map(|&f| comp(f, f)).collect();
        let pgen: BTreeSet<F> = fs.iter().zip(rs.iter()).filter(|(_, s)| **s == rs[0]).map(|(f, _)| *f).collect();
        let (g1, g2, g3) = (genera(d), 1usize << (mu(d) - 1), rs.iter().collect::<BTreeSet<_>>().len());
        println!("{} {} {} {} {} {} {}", d, fs.len(), g1, g2, g3, fs.len() / g1, yn(sq == pgen));
        assert!(g1 == g2 && g2 == g3 && sq == pgen);
    }
    let mut ido = vec![];
    for n in 1..2001i64 {
        let g1 = genera(-4 * n); assert!(g1 == 1usize << (mu(-4 * n) - 1));
        if g1 == forms(-4 * n).len() { ido.push(n); }
    }
    println!("n up to 2,000 with one class in each genus of -4n (Euler's convenient numbers): {} ; largest {} ; first {}", ido.len(), ido[ido.len() - 1], first(&ido, 12));
    assert!(ido.len() == 65 && ido[64] == 1848);
    let (a, b) = (2i64, 2i64); println!("what breaks: multiply the first numbers without uniting: (4, 2, c) needs c = {}", (b * b + 20) as f64 / (4 * a * a) as f64);
    println!("what breaks: every square principal, as at -20? at -56 {:?} composed with itself is {:?}", (3, 2, 5), comp((3, 2, 5), (3, 2, 5)));
    println!("what breaks: 79 is {} mod 56, like 23; is it x^2 + 14y^2? {} ; Gauss's count with 2^mu at -20: {} genera, truth {}", 79 % 56, yn(r114.contains(&79)), 1 << mu(-20), genera(-20));
    println!("ALL CHECKS PASS");
}
