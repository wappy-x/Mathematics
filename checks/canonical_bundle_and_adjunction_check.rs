// The canonical bundle and adjunction -- the same check as the Python, in Rust.  No crates.
// Road 1: the top form of projective space, moved between charts by an exact Jacobian.
// Road 2: adjunction arithmetic.  Road 3: Riemann-Hurwitz, branch points counted from an
// exact discriminant modulo a prime.  Road 4: points of the Hermitian curve over GF(16).
use std::collections::HashMap;
const P: i128 = 1000000007;                       // the prime for road 3

#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i128, d: i128 }                    // exact fraction; checked_mul stops on overflow
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Fr { let g = gcd(n, d) * d.signum(); Fr { n: n / g, d: d / g } }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn div(a: Fr, b: Fr) -> Fr { fr(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn sub(a: Fr, b: Fr) -> Fr { fr(a.n * b.d - b.n * a.d, a.d.checked_mul(b.d).unwrap()) }
fn add(a: Fr, b: Fr) -> Fr { sub(a, fr(-b.n, b.d)) }
fn show(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
#[derive(Clone, Copy)]
struct Dual { a: Fr, b: Fr }                      // a + b e with e^2 = 0: exact first derivatives
fn ddiv(s: Dual, o: Dual) -> Dual {
    Dual { a: div(s.a, o.a), b: div(sub(mul(s.b, o.a), mul(s.a, o.b)), mul(o.a, o.a)) }
}
fn pw(mut b: i128, mut e: i128) -> i128 {        // b^e mod P, by repeated squaring
    let mut r = 1; b = b.rem_euclid(P);
    while e > 0 { if e & 1 == 1 { r = r * b % P } b = b * b % P; e >>= 1 } r
}
fn inv(a: i128) -> i128 { pw(a.rem_euclid(P), P - 2) }
fn detp(mut m: Vec<Vec<i128>>) -> i128 {          // determinant mod P, by Gaussian elimination
    let n = m.len(); let mut d: i128 = 1;
    for c in 0..n {
        let p = match (c..n).find(|&r| m[r][c] % P != 0) { Some(p) => p, None => return 0 };
        if p != c { m.swap(c, p); d = -d }
        d = d * m[c][c] % P; let iv = inv(m[c][c]);
        for r in c + 1..n {
            let f = m[r][c] * iv % P;
            for k in 0..n { m[r][k] = (m[r][k] - f * m[c][k]).rem_euclid(P) } } }
    d.rem_euclid(P)
}

fn jacobian(n: usize, b: &[i128]) -> Fr {         // chart x1 = 1 -> chart x0 = 1, at b = (b0, b2.., bn)
    let mut m = vec![vec![fr(0, 1); n]; n];
    for j in 0..n {
        let v: Vec<Dual> = (0..n).map(|k| Dual { a: fr(b[k], 1), b: fr(if k == j { 1 } else { 0 }, 1) }).collect();
        let one = Dual { a: fr(1, 1), b: fr(0, 1) };
        let mut a = vec![ddiv(one, v[0])];         // a1 = 1/b0, ak = bk/b0
        for k in 1..n { a.push(ddiv(v[k], v[0])) }
        for i in 0..n { m[i][j] = a[i].b } }
    let mut out = fr(1, 1);                       // exact determinant over fractions
    for c in 0..n {
        let p = (c..n).find(|&r| m[r][c].n != 0).unwrap();
        if p != c { m.swap(c, p); out = fr(-out.n, out.d) }
        out = mul(out, m[c][c]);
        for r in c + 1..n {
            let f = div(m[r][c], m[c][c]);
            for k in 0..n { m[r][k] = sub(m[r][k], mul(f, m[c][k])) } } }
    out
}

fn disc(f: &HashMap<(i128, i128), i128>, d: usize, x0: i128) -> i128 {   // Res_y(F, F_y) at x0, mod P
    let a: Vec<i128> = (0..=d).rev().map(|k| f.iter().filter(|(&(_, j), _)| j == k as i128)
        .map(|(&(i, _), &c)| c * pw(x0, i)).sum::<i128>().rem_euclid(P)).collect();
    let b: Vec<i128> = (0..d).map(|k| (d - k) as i128 * a[k] % P).collect();
    let nn = 2 * d - 1; let mut rows = Vec::new();
    for k in 0..d - 1 { let mut r = vec![0; k]; r.extend(&a); r.resize(nn, 0); rows.push(r) }
    for k in 0..d { let mut r = vec![0; k]; r.extend(&b); r.resize(nn, 0); rows.push(r) }
    detp(rows)
}
fn trim(p: &mut Vec<i128>) { while p.len() > 1 && *p.last().unwrap() == 0 { p.pop(); } }
fn interpolate(ys: &[i128]) -> Vec<i128> {        // Newton form through x = 0, 1, 2, ..., mod P
    let n = ys.len(); let mut c = ys.to_vec();
    for j in 1..n { for i in (j..n).rev() { c[i] = (c[i] - c[i - 1]).rem_euclid(P) * inv(j as i128) % P } }
    let mut poly = vec![0i128];
    for i in (0..n).rev() {                       // poly = poly * (x - i) + c[i], low terms first
        let mut q = vec![0i128; poly.len() + 1];
        for k in 0..poly.len() { q[k + 1] = (q[k + 1] + poly[k]) % P; q[k] = (q[k] - i as i128 * poly[k]).rem_euclid(P) }
        q[0] = (q[0] + c[i]) % P; poly = q; }
    trim(&mut poly); poly
}

fn euclid(mut a: Vec<i128>, mut b: Vec<i128>) -> (Vec<i128>, i128) {   // Euclid mod P, low terms first: (gcd, resultant)
    let mut out = 1;
    while b.iter().any(|&x| x != 0) {
        let (m, n, iv) = (a.len() as i128 - 1, b.len() as i128 - 1, inv(*b.last().unwrap()));
        while a.len() >= b.len() {
            let (f, s) = (a[a.len() - 1] * iv % P, a.len() - b.len());
            for k in s..a.len() { a[k] = (a[k] - f * b[k - s]).rem_euclid(P) }
            a.pop(); }
        trim(&mut a);
        out = out * if n == 0 { pw(b[0], m) } else { (if m * n % 2 == 1 { P - 1 } else { 1 }) * pw(*b.last().unwrap(), m - a.len() as i128 + 1) % P } % P;
        std::mem::swap(&mut a, &mut b); }
    let r = if a.len() == 1 { out } else { 0 }; (a, r)
}

fn branch(f: &HashMap<(i128, i128), i128>, d: usize) -> (i128, i128, i128) {
    let fy: HashMap<(i128, i128), i128> = f.iter().filter(|(&(_, j), _)| j > 0).map(|(&(i, j), &c)| ((i, j - 1), j * c)).collect();
    let col = |g: &HashMap<(i128, i128), i128>, x: i128, n: i128| -> Vec<i128> { (0..n).map(|k| g.iter().filter(|(&(_, j), _)| j == k).map(|(&(i, _), &c)| c * pw(x, i)).sum::<i128>().rem_euclid(P)).collect() };
    let ys: Vec<i128> = (0..(d * (d - 1) + 2) as i128).map(|x| disc(f, d, x)).collect();
    assert!((0..ys.len()).all(|x| ys[x] == euclid(col(f, x as i128, d as i128 + 1), col(&fy, x as i128, d as i128)).1));   // Sylvester against Euclid
    let dd = interpolate(&ys);
    let der: Vec<i128> = (1..dd.len()).map(|k| k as i128 * dd[k] % P).collect();
    let g = euclid(dd.clone(), der).0;
    let (deg, rep) = (dd.len() as i128 - 1, g.len() as i128 - 1);
    (deg, rep, deg - 2 * rep)
}

fn gmul(mut a: u32, mut b: u32) -> u32 {          // GF(16) as bit-polynomials mod t^4 + t + 1
    let mut r = 0;
    for _ in 0..4 { if b & 1 == 1 { r ^= a } b >>= 1; a = (a << 1) ^ (if a & 8 != 0 { 0b10011 } else { 0 }) } r
}
fn gpw(a: u32, k: u32) -> u32 { let mut r = 1; for _ in 0..k { r = gmul(r, a) } r }
fn main() {
    println!("road 1, the top form of P^n moved from chart x1 = 1 to chart x0 = 1");
    for n in 1..5usize {
        let rest = &[5i128, 7, 11][..n - 1];
        let (mut b2, mut b3) = (vec![2i128], vec![3i128]); b2.extend(rest); b3.extend(rest);
        let (j2, j3) = (jacobian(n, &b2), jacobian(n, &b3));
        let e = (0..10u32).find(|&e| mul(j2, fr(2i128.pow(e), 1)) == mul(j3, fr(3i128.pow(e), 1))).unwrap();
        let c = mul(j2, fr(2i128.pow(e), 1));
        println!("P^{}: Jacobian at b0 = 2, 3: {}, {}; equals {}/b0^{}: pole of order {}, K = O({})", n, show(j2), show(j3), show(c), e, e, -(e as i64));
        assert!(e as usize == n + 1 && c == fr(-1, 1));
    }
    println!("P^2 at (t, s) = (2, 3): dx ^ dy = {} dt ^ ds", show(jacobian(2, &[2, 3])));
    println!("road 2, adjunction on a plane curve of degree d: K_C = O(d - 3) on C");
    let mut genus = [0i128; 6];
    for d in 1..6i128 {
        let degk = d * (d - 3);
        genus[d as usize] = degk.div_euclid(2) + 1;
        let mono: i128 = (0..(d - 2).max(0)).map(|i| d - 2 - i).sum();    // x^i y^j, i + j <= d - 3
        println!("d = {}: deg K_C = {}({} - 3) = {} = 2g - 2, g = {}; differentials h dx/F_y: {}", d, d, d, degk, genus[d as usize], mono);
        assert!(degk % 2 == 0 && genus[d as usize] == (d - 1) * (d - 2) / 2 && genus[d as usize] == mono);
    }
    println!("road 3, Riemann-Hurwitz: project to x, count simple roots of the discriminant mod 1000000007");
    let mut curves: Vec<(usize, HashMap<(i128, i128), i128>, String)> = (2..6usize).map(|d| {
        let di = d as i128;
        (d, HashMap::from([((di, 0), 1), ((0, di), 1), ((1, 1), 1), ((1, 0), 1), ((0, 0), 1)]), format!("x^{} + y^{} + xy + x + 1", d, d))
    }).collect();
    curves.push((4, HashMap::from([((4, 0), 1), ((2, 0), -1), ((0, 4), 1), ((0, 3), 1), ((0, 2), 1), ((0, 0), -1)]), "x^4 - x^2 + y^4 + y^3 + y^2 - 1".to_string()));
    for (d, f, name) in &curves {
        let (deg, rep, b) = branch(f, *d);
        let di = *d as i128;
        let g = 1 - di + b / 2;                   // 2 - 2g = 2d - b
        println!("{}: discriminant degree {}, repeated {}, branch points {}; 2 - 2g = {} - {}, g = {}", name, deg, rep, b, 2 * di, b, g);
        assert!(deg == b && b == di * (di - 1) && g == genus[*d]);
    }
    println!("road 4, the Hermitian curve x^5 = y^4 + y over GF(16), a smooth quintic");
    let nn = 1 + (0..16u32).flat_map(|x| (0..16u32).map(move |y| (x, y))).filter(|&(x, y)| gpw(x, 5) == gpw(y, 4) ^ y).count() as i128;
    println!("points: {} affine + 1 at infinity = {}; Hasse-Weil N <= 17 + 8g gives g >= {}; adjunction g = {}", nn - 1, nn, (nn - 17) / 8, genus[5]);
    assert!(nn == 65 && (nn - 17) / 8 == genus[5]);
    println!("surfaces of degree e in P^3: K = O(e - 4); a line L has L.L = 2g - 2 - K.L = -2 - (e - 4)");
    for e in 1..6i128 {
        let (ll, hh) = (-2 - (e - 4), e);         // H.H = e: a line meets the surface e times
        println!("e = {}: K = O({}), L.L = {}; plane section H.H = {}, K.H = {}, sum {} = 2g - 2 for g = {}", e, e - 4, ll, hh, (e - 4) * e, hh + (e - 4) * e, genus[e as usize]);
        assert!(hh + (e - 4) * e == 2 * genus[e as usize] - 2);
    }
    println!("quintic threefold in P^4: K = O(5 - 4 - 1) = O(0)");
    println!("what breaks");
    let d: i128 = 4;                              // the smooth quartic, true genus 3
    println!("mistake 1, K of P^2 taken as O(-2): g = 1 + d(d - 2)/2 = {:.1} for d = 3, {} for d = 4", 1.0 + 3.0 * 1.0 / 2.0, 1 + d * (d - 2) / 2);
    println!("mistake 2, twist O(C) dropped: deg K_C = -3d = {} for d = 4, g = {}", -3 * d, (-3 * d).div_euclid(2) + 1);
    println!("mistake 3, twist with the wrong sign: deg K_C = d(-3 - d) = {} for d = 4, g = {}", d * (-3 - d), (d * (-3 - d)).div_euclid(2) + 1);
    let nodal = HashMap::from([((3, 0), 1), ((0, 3), 1), ((2, 0), 1), ((0, 2), -4)]);
    let (deg, rep, b) = branch(&nodal, 3);
    let t = fr(1, 1);
    let xt = div(sub(mul(fr(4, 1), mul(t, t)), fr(1, 1)), add(fr(1, 1), mul(t, mul(t, t))));
    let yt = mul(xt, t);
    let fv = sub(add(add(mul(xt, mul(xt, xt)), mul(yt, mul(yt, yt))), mul(xt, xt)), mul(fr(4, 1), mul(yt, yt)));
    println!("mistake 4, nodal cubic x^3 + y^3 + x^2 - 4y^2: adjunction says 1; discriminant degree {}, repeated {}, branch points {}, g = {}; t = 1 gives ({}, {}), F = {}",
             deg, rep, b, 1 - 3 + b / 2, show(xt), show(yt), show(fv));
    assert!((deg, rep, b) == (6, 1, 4) && fv == fr(0, 1));
    println!("ALL CHECKS PASS");
}
