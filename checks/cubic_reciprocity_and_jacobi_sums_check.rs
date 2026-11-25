// Cubic reciprocity and Jacobi sums: the same check as the Python, std only.
// A pair (a, b) is the Eisenstein integer a + b*omega, with omega^2 = -1 - omega.
// Road 1 adds up the Jacobi sum J directly.  Road 2 cubes the Gauss sum exactly in Z[zeta_3p]
// and in floating point.  Road 3 decides "is 2 a cube mod p" three ways: every cube by brute
// force, J mod 2, and a search for p = x^2 + 27y^2.  Reciprocity and Gauss's quartic rule are counts.
use std::collections::BTreeSet;
type E = (i64, i64);
const W: [E; 3] = [(1, 0), (0, 1), (-1, -1)]; // 1, omega, omega^2

fn primes(n: usize) -> Vec<i64> {
    let mut s = vec![true; n]; s[0] = false; s[1] = false;
    let mut i = 2;
    while i * i < n { if s[i] { let mut j = i * i; while j < n { s[j] = false; j += i; } } i += 1; }
    (0..n).filter(|&i| s[i]).map(|i| i as i64).collect()
}
fn md(x: i64, m: i64) -> i64 { x.rem_euclid(m) }
fn powm(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1; b = md(b, m);
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; }
    r
}
fn mul(x: E, y: E, m: i64) -> E { // (a + b w)(c + d w), w^2 = -1 - w; reduced mod m if m
    let r = (x.0 * y.0 - x.1 * y.1, x.0 * y.1 + x.1 * y.0 - x.1 * y.1);
    if m > 0 { (md(r.0, m), md(r.1, m)) } else { r }
}
fn wpow(mut x: E, mut e: i64, m: i64) -> E {
    let mut r = (1, 0);
    while e > 0 { if e & 1 == 1 { r = mul(r, x, m); } x = mul(x, x, m); e >>= 1; }
    r
}
fn isqrt(n: i64) -> i64 { let mut r = (n as f64).sqrt() as i64; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }
fn rep(p: i64, k: i64) -> Vec<E> { // every (x, y), y >= 1, with p = x^2 + k y^2
    (1..=isqrt(p / k)).filter(|y| { let t = p - k * y * y; isqrt(t) * isqrt(t) == t }).map(|y| (isqrt(p - k * y * y), y)).collect()
}
fn norm(x: E) -> i64 { x.0 * x.0 - x.0 * x.1 + x.1 * x.1 }
fn index(p: i64) -> (i64, Vec<i64>) { // discrete logs to the smallest primitive root
    let qs: Vec<i64> = primes(p as usize).into_iter().filter(|q| (p - 1) % q == 0).collect();
    let g = (2..p).find(|&g| qs.iter().all(|&q| powm(g, (p - 1) / q, p) != 1)).unwrap();
    let (mut ind, mut x) = (vec![0i64; p as usize], 1i64);
    for k in 0..p - 1 { ind[x as usize] = k; x = x * g % p; }
    (g, ind)
}
fn jacobi(p: i64, n: i64) -> (Vec<i64>, i64, Vec<i64>) { // J(chi, chi) as counts of each power of the n-th root
    let (g, ind) = index(p); let mut c = vec![0i64; n as usize];
    for a in 2..p { c[((ind[a as usize] + ind[md(1 - a, p) as usize]) % n) as usize] += 1; }
    (c, g, ind)
}
fn jac3(p: i64) -> E { let c = jacobi(p, 3).0; (c[0] - c[2], c[1] - c[2]) }
fn mod2(x: E) -> usize { W.iter().position(|w| md(w.0 - x.0, 2) == 0 && md(w.1 - x.1, 2) == 0).unwrap() }
fn fmt(x: E) -> String { if x.1 >= 0 { format!("{} + {} omega", x.0, x.1) } else { format!("{} - {} omega", x.0, -x.1) } }
fn jsum(p: i64, f: &dyn Fn(i64) -> Option<i64>, g: &dyn Fn(i64) -> Option<i64>) -> E { // sum over t = 0..p-1 of f(t) g(1 - t); f, g give a power of omega, or None for 0
    (0..p).filter_map(|t| Some(W[((f(t)? + g(md(1 - t, p))?) % 3) as usize])).fold((0, 0), |s, w| (s.0 + w.0, s.1 + w.1))
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn cubes(p: i64) -> BTreeSet<i64> { (1..p).map(|x| powm(x, 3, p)).collect() }
fn fourths(p: i64) -> BTreeSet<i64> { (1..p).map(|x| powm(x, 4, p)).collect() }
#[derive(Clone, Copy)]
struct C(f64, f64);
impl C {
    fn mul(self, o: C) -> C { C(self.0 * o.0 - self.1 * o.1, self.0 * o.1 + self.1 * o.0) }
    fn abs(self) -> f64 { (self.0 * self.0 + self.1 * self.1).sqrt() }
    fn s(self) -> String { format!("{:.9} {} {:.9}i", self.0, if self.1 >= 0.0 { "+" } else { "-" }, self.1.abs()) }
}
fn cz(x: E) -> C { C(x.0 as f64 - x.1 as f64 / 2.0, x.1 as f64 * 3f64.sqrt() / 2.0) }
fn gauss_cubed_exact(p: i64) -> Vec<Vec<i64>> { // grid z[i][j] = coefficient of omega^i zeta^j
    let (pu, ind) = (p as usize, index(p).1);
    let mut g = vec![vec![0i64; pu]; 3];
    for a in 1..pu { g[(ind[a] % 3) as usize][a] += 1; }
    let times = |x: &Vec<Vec<i64>>, y: &Vec<Vec<i64>>| {
        let mut z = vec![vec![0i64; pu]; 3];
        for i in 0..3 { for j in 0..pu { if x[i][j] != 0 { for k in 0..3 { for l in 0..pu {
            z[(i + k) % 3][(j + l) % pu] += x[i][j] * y[k][l]; } } } } }
        z
    };
    let mut z = times(&times(&g, &g), &g);
    for j in 0..pu { let t = z[2][j]; z[0][j] -= t; z[1][j] -= t; z[2][j] = 0; }
    for i in 0..2 { let v = z[i][pu - 1]; for t in z[i].iter_mut() { *t -= v; } }
    z
}
fn gauss_float(p: i64) -> C {
    let ind = index(p).1; let mut s = C(0.0, 0.0);
    for a in 1..p { let t = 2.0 * std::f64::consts::PI * (ind[a as usize] as f64 / 3.0 + a as f64 / p as f64); s = C(s.0 + t.cos(), s.1 + t.sin()); }
    s
}
fn chi(pi: E, alpha: E) -> usize { // cubic residue character of alpha mod primary pi, as 0, 1, 2
    let n = norm(pi); let m = if pi.1 != 0 { n } else { pi.0 };
    let v = wpow(alpha, (n - 1) / 3, m);
    if pi.1 == 0 { return W.iter().position(|w| md(w.0 - v.0, m) == 0 && md(w.1 - v.1, m) == 0).unwrap(); }
    let r = md(-pi.0 * powm(pi.1, m - 2, m), m); // omega -> r sends pi to 0 mod p
    W.iter().position(|w| md(w.0 + w.1 * r - v.0 - v.1 * r, m) == 0).unwrap()
}

fn main() {
    let (_, g7, ind7) = jacobi(7, 3);
    println!("cubic character mod 7, generator {}: power of omega for a = 1..6: {:?}", g7, (1..7).map(|a| ind7[a] % 3).collect::<Vec<_>>());
    println!("cubes mod 7: {:?}  terms a = 2..6: {:?}", cubes(7).iter().collect::<Vec<_>>(), (2..7).map(|a| (ind7[a] + ind7[md(1 - a as i64, 7) as usize]) % 3).collect::<Vec<_>>());
    let j7 = jac3(7);
    println!("J(chi, chi) mod 7 = {}, norm {}, a mod 3 = {}, b mod 3 = {}", fmt(j7), norm(j7), md(j7.0, 3), md(j7.1, 3));
    assert!(j7 == (-1, -3) && norm(j7) == 7);
    let g = gauss_float(7); let g3 = g.mul(g).mul(g); let c7 = cz(j7); let s7 = C(7.0 * c7.0, 7.0 * c7.1);
    println!("g(chi) mod 7 = {}, |g|^2 = {:.9}", g.s(), g.abs() * g.abs());
    println!("g^3 = {}, 7J = {}", g3.s(), s7.s());
    assert!((g.abs() * g.abs() - 7.0).abs() < 1e-9 && C(g3.0 - s7.0, g3.1 - s7.1).abs() < 1e-9);
    let small: Vec<i64> = primes(100).into_iter().filter(|p| p % 3 == 1).collect();
    let mut pts = vec![];
    for &p in &small {
        let (z, j) = (gauss_cubed_exact(p), jac3(p));
        let n3 = (0..p).map(|x| (0..p).filter(|y| (x * x * x + y * y * y) % p == 1).count() as i64).sum::<i64>(); // points on x^3 + y^3 = 1
        assert!(n3 == p - 2 + 2 * j.0 - j.1); pts.push(n3);
        let mut e0 = vec![0i64; p as usize]; let mut e1 = e0.clone(); e0[0] = p * j.0; e1[0] = p * j.1;
        assert!(z[0] == e0 && z[1] == e1 && z[2].iter().all(|&t| t == 0));
    }
    println!("exact: g^3 = pJ in Z[zeta_3p] for all {} primes p = 1 mod 3 below 100", small.len());
    println!("points on x^3 + y^3 = 1 mod p = p - 2 + 2a - b for all {}: p = 7: {}, p = 31: {}", small.len(), pts[0], pts[3]);
    for p in [7i64, 13, 31] {
        let (j, ind) = (jac3(p), index(p).1); let (l, m) = ((2 * j.0 - j.1).abs(), j.1.abs() / 3);
        println!("p = {}: J = {}, 4p = {} = {}^2 + 27*{}^2, chi(2) = omega^{}, J mod 2 = omega^{}, 2 a cube: {}", p, fmt(j), 4 * p, l, m, ind[2] % 3, mod2(j), py(cubes(p).contains(&2)));
    }
    println!("4^3 mod 31 = {}; x^3 = 2 mod 31 at x = {:?}; 31 = x^2 + 27y^2 at {:?}", powm(4, 3, 31), (0..31).filter(|&x| powm(x, 3, 31) == 2).collect::<Vec<_>>(), rep(31, 27));
    let n = 10000usize; let split: Vec<i64> = primes(n).into_iter().filter(|p| p % 3 == 1).collect();
    let (mut agree, mut cube) = (0, 0);
    for &p in &split {
        let (j, ind) = (jac3(p), index(p).1); let (a, b) = j;
        let mut reps = vec![];
        for m in 1..=isqrt(4 * p / 27) { for l in 1..=isqrt(4 * p) { if l * l + 27 * m * m == 4 * p { reps.push((l, m)); } } }
        let brute = cubes(p).contains(&2);
        let by_j = mod2(j) as i64 == ind[2] % 3; // J = chi(2) mod 2
        let form = !rep(p, 27).is_empty();
        assert!(norm(j) == p && md(a, 3) == 2 && md(b, 3) == 0 && reps == vec![((2 * a - b).abs(), b.abs() / 3)]);
        if by_j && brute == (md(b, 2) == 0) && brute == form && form == (ind[2] % 3 == 0) { agree += 1; } if brute { cube += 1; }
    }
    println!("primes p = 1 mod 3 below {}: {}; norm J = p, one 4p = L^2 + 27M^2, three tests agree: {}; 2 a cube: {}", n, split.len(), agree, cube);
    assert!(agree == split.len());

    let mut prim: Vec<E> = vec![];
    for p in primes(200) { if p % 3 == 1 { let j = jac3(p); prim.push(j); prim.push((j.0 - j.1, -j.1)); } }
    for q in primes(30) { if q % 3 == 2 { prim.push((q, 0)); } }
    let mut pairs = vec![];
    for &s in &prim { for &t in &prim { if s < t && norm(s) != norm(t) && (s.1 != 0 || t.1 != 0) { pairs.push((s, t)); } } } // skip two ordinary primes
    let same = pairs.iter().filter(|&&(s, t)| chi(s, t) == chi(t, s)).count();
    println!("cubic reciprocity, pi = J mod 7 and 2: chi_pi(2) = omega^{}, chi_2(pi) = omega^{}", chi(j7, (2, 0)), chi((2, 0), j7));
    println!("cubic reciprocity on {} pairs of primary primes: {} agree", pairs.len(), same);
    assert!(same == pairs.len() && same == 1092 && chi(j7, (2, 0)) == 2 && chi((2, 0), j7) == 2);
    let (c4, g73, _) = jacobi(73, 4); let j4 = (c4[0] - c4[2], c4[1] - c4[3]);
    println!("quartic J mod 73, generator {}: {} + {}i, norm {}; 73 = 3^2 + 64*1^2; x^4 = 2 mod 73 at x = {:?}", g73, j4.0, j4.1, j4.0 * j4.0 + j4.1 * j4.1, (1..73).filter(|&x| powm(x, 4, 73) == 2).collect::<Vec<_>>());
    let q4: Vec<i64> = primes(n).into_iter().filter(|p| p % 4 == 1).collect();
    let four: Vec<bool> = q4.iter().map(|&p| fourths(p).contains(&2)).collect();
    let form4: Vec<bool> = q4.iter().map(|&p| !rep(p, 64).is_empty()).collect();
    let cnt = |v: &Vec<bool>| v.iter().filter(|&&b| b).count();
    println!("primes p = 1 mod 4 below {}: {}; 2 a fourth power: {}; p = x^2 + 64y^2: {}; agree: {}", n, q4.len(), cnt(&four), cnt(&form4), four.iter().zip(&form4).filter(|(u, v)| u == v).count());
    assert!(four == form4);
    if n == 10000 { assert!((split.len(), cube, q4.len(), cnt(&four)) == (611, 200, 609, 143)); } // the counts on the card
    let (chi7, chibar) = (|t: i64| if t == 0 { None } else { Some(ind7[t as usize] % 3) }, |t: i64| if t == 0 { None } else { Some(2 * ind7[t as usize] % 3) });
    let (triv, chi1) = (|t: i64| if t == 0 { None } else { Some(0i64) }, |t: i64| Some(if t == 0 { 0 } else { ind7[t as usize] % 3 })); // chi1 counts chi(0) as 1
    let (jt, jbar, j0) = (jsum(7, &triv, &triv), jsum(7, &chi7, &chibar), jsum(7, &chi1, &chi1));
    println!("break: trivial character mod 7, J = {}, norm {}; J(chi, chi-bar) = {}, norm {}", jt.0, norm(jt), fmt(jbar), norm(jbar));
    println!("break: chi(0) = 1 counted, J + 2 = {}, norm {}", fmt(j0), norm(j0));
    assert!(jsum(7, &chi7, &chi7) == j7 && jt == (7 - 2, 0) && jbar == (-1, 0) && j0 == (j7.0 + 2, j7.1));
    let (x3, c11, f17) = (rep(7, 3), cubes(11), fourths(17));
    println!("break: 7 = x^2 + 3y^2 at {:?}, yet 2 is no cube mod 7; mod 11 every one of {} is a cube, 7^3 mod 11 = {}", x3, c11.len(), powm(7, 3, 11));
    println!("break: 17 = 1^2 + 16*1^2, fourth powers mod 17: {:?}", f17.iter().collect::<Vec<_>>());
    let (k1, k2) = (chi(j7, (5, 0)), chi((5, 0), mul((0, 1), j7, 0)));
    println!("break: non-primary omega*pi mod 7 and 5: chi_pi(5) = omega^{}, chi_5(omega pi) = omega^{}", k1, k2);
    assert!(x3 == vec![(2, 1)] && c11.len() == 10 && !f17.contains(&2) && k1 != k2 && k2 == (k1 + 2) % 3);
    let mut pts = vec![];
    for a in -4..5 { for b in -4..5 { if norm((a, b)) == 7 { let z = cz((a, b)); pts.push(format!("({:.3},{:.3})", z.0, z.1)); } } }
    println!("figure, norm 7: {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
