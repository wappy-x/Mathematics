// Hyperelliptic curves and the canonical map -- the check behind the card.  std only, no crates.
// Polynomials are integer vectors, lowest power first.  Roads to the genus: pole orders of differentials
// and branch points from an exact discriminant.  Point counts mod 13 and 13^2 are a consistency check.
use std::collections::BTreeSet;
const P: i128 = 13;
fn ipow(b: i128, e: u32) -> i128 { b.checked_pow(e).expect("overflow") }
fn disc_formula(n: i128) -> i128 { // discriminant of x^n + x + 1, the trinomial formula
    let s = if (n * (n - 1) / 2) % 2 == 0 { 1 } else { -1 };
    let t = if (n - 1) % 2 == 0 { 1 } else { -1 };
    s * (ipow(n, n as u32) + t * ipow(n - 1, (n - 1) as u32))
}
fn det(mut m: Vec<Vec<i128>>) -> i128 { // Bareiss elimination: exact integer determinant
    let n = m.len(); let (mut sign, mut prev) = (1i128, 1i128);
    for k in 0..n - 1 {
        if m[k][k] == 0 {
            match (k + 1..n).find(|&i| m[i][k] != 0) { None => return 0, Some(s) => { m.swap(k, s); sign = -sign; } }
        }
        for i in k + 1..n {
            for j in k + 1..n {
                m[i][j] = (m[i][j].checked_mul(m[k][k]).unwrap() - m[i][k].checked_mul(m[k][j]).unwrap()) / prev;
            }
        }
        prev = m[k][k];
    }
    sign * m[n - 1][n - 1]
}
fn disc_sylvester(f: &[i128]) -> i128 { // (-1)^(n(n-1)/2) Res(f, f') for monic f, by the Sylvester matrix
    let n = f.len() - 1; let d: Vec<i128> = (1..=n).map(|i| i as i128 * f[i]).collect();
    let (fr, dr): (Vec<i128>, Vec<i128>) = (f.iter().rev().cloned().collect(), d.iter().rev().cloned().collect());
    let mut s = vec![];
    for r in 0..n - 1 { let mut row = vec![0; r]; row.extend(&fr); row.extend(vec![0; n - 2 - r]); s.push(row); }
    for r in 0..n { let mut row = vec![0; r]; row.extend(&dr); row.extend(vec![0; n - 1 - r]); s.push(row); }
    (if (n * (n - 1) / 2) % 2 == 0 { 1 } else { -1 }) * det(s)
}
fn orders_at_infinity(n: i128) -> (i128, i128, i128, i128) { // (points, ord x, ord y, ord dx) on y^2 = f
    if n % 2 == 1 { (1, -2, -n, -3) } else { (2, -1, -n / 2, -2) }
}
fn holomorphic(n: i128) -> Vec<i128> { // the i with x^i dx/y finite at infinity (it is finite elsewhere)
    let (_, ox, oy, odx) = orders_at_infinity(n);
    (0..n).filter(|&i| i * ox + odx - oy >= 0).collect()
}
fn show(v: &[i128]) -> String { format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }
fn ev(f: &[i128], x: i128) -> i128 { f.iter().enumerate().map(|(i, c)| c * ipow(x, i as u32)).sum() }
fn powm(mut b: i128, mut e: i128) -> i128 { let mut r = 1; b = b.rem_euclid(P); while e > 0 { if e & 1 == 1 { r = r * b % P; } b = b * b % P; e >>= 1; } r }
fn chi(a: i128) -> i128 { // Euler's criterion: +1 square, -1 non-square, 0 zero
    let a = a.rem_euclid(P); if a == 0 { 0 } else if powm(a, (P - 1) / 2) == 1 { 1 } else { -1 }
}
fn hyper_points(f: &[i128]) -> Vec<(i128, i128)> { // affine points of y^2 = f over F_p
    let mut v = vec![];
    for x in 0..P { for y in 0..P { if (y * y - ev(f, x)).rem_euclid(P) == 0 { v.push((x, y)); } } }
    assert_eq!(v.len() as i128, (0..P).map(|x| 1 + chi(ev(f, x))).sum::<i128>()); // enumeration against Euler
    v
}
fn canonical_image(pts: &[(i128, i128)], g: u32) -> BTreeSet<Vec<i128>> { // (1 : x : ... : x^(g-1)), infinity to (0 : ... : 1)
    let mut s: BTreeSet<Vec<i128>> = pts.iter().map(|&(x, _)| (0..g).map(|k| ipow(x, k) % P).collect()).collect();
    let mut inf = vec![0; g as usize]; inf[g as usize - 1] = 1; s.insert(inf); s
}
fn mirror_rank(pts: &[(i128, i128)], g: u32) -> Vec<((i128, i128), (i128, i128), i128)> {
    let mut out = vec![];
    for &a in pts { for &b in pts { if a < b {
        let r0: Vec<i128> = (0..g).map(|k| ipow(a.0, k) % P).collect();
        let r1: Vec<i128> = (0..g).map(|k| ipow(b.0, k) % P).collect();
        let g = g as usize;
        let full = (0..g).any(|i| (i + 1..g).any(|j| (r0[i] * r1[j] - r0[j] * r1[i]).rem_euclid(P) != 0));
        out.push((a, b, if full { 2 } else { 1 }));
    } } }
    out
}
fn m2(a: (i128, i128), b: (i128, i128), nr: i128) -> (i128, i128) { ((a.0 * b.0 + nr * a.1 * b.1) % P, (a.0 * b.1 + a.1 * b.0) % P) }
fn pw(mut a: (i128, i128), mut e: i128, nr: i128) -> (i128, i128) { let mut r = (1, 0); while e > 0 { if e & 1 == 1 { r = m2(r, a, nr); } a = m2(a, a, nr); e >>= 1; } r }
fn rem(mut a: Vec<i128>, u: &[i128]) -> Vec<i128> { // remainder of a on division by the monic u, mod p
    while a.len() >= u.len() { let (c, s) = (a.pop().unwrap(), a.len() + 1 - u.len()); for i in s..a.len() { a[i] = (a[i] - c * u[i - s]).rem_euclid(P); } }
    a
}
fn main() {
    println!("y^2 = x^n + x + 1: discriminant two ways, branch points, genus two ways");
    for n in 3..9i128 {
        let mut f = vec![1, 1]; f.extend(vec![0; n as usize - 2]); f.push(1);
        let (d1, d2) = (disc_formula(n), disc_sylvester(&f));
        assert!(d1 == d2 && d1 != 0); // squarefree, so the affine curve is smooth
        let branch = n + n % 2; // n roots, plus infinity when n is odd
        let g_rh = (branch - 2) / 2; // Riemann-Hurwitz for a 2-to-1 map to the line
        let hol = holomorphic(n); let (pts, _, oy, odx) = orders_at_infinity(n);
        let deg_k = pts * (odx - oy); // zeros of dx/y, all at infinity
        assert!(hol.len() as i128 == g_rh && deg_k == 2 * g_rh - 2);
        println!("n = {}: disc {}, branch points {}, genus {}, differentials x^i dx/y for i in {}, deg K {}", n, d1, branch, g_rh, show(&hol), deg_k);
    }
    println!("genus-2 curve y^2 = x^5 + x + 1 = (x^2 + x + 1)(x^3 - x^2 + 1)");
    let (a, b) = ([1i128, 1, 1], [1i128, 0, -1, 1]); let mut prod = vec![0i128; 6];
    for i in 0..3 { for j in 0..4 { prod[i + j] += a[i] * b[j]; } }
    assert_eq!(prod, vec![1, 1, 0, 0, 0, 1]);
    let (_, ox, oy, odx) = orders_at_infinity(5);
    for i in 0..3 { println!("  order at infinity of x^{} dx/y: {}", i, i * ox + odx - oy); }
    println!("  div(dx/y) = 2*inf, div(x dx/y) = (0, 1) + (0, -1): degrees 2 and 2 = 2g - 2");
    let f2 = [1i128, 1, 0, 0, 0, 1];
    let p2 = hyper_points(&f2); let n1 = p2.len() as i128 + 1; let img2 = canonical_image(&p2, 2);
    let roots2: Vec<i128> = (0..P).filter(|&x| ev(&f2, x) % P == 0).collect();
    let bad2: Vec<_> = mirror_rank(&p2, 2).into_iter().filter(|r| r.2 == 1).collect();
    assert!(bad2.len() as i128 == (n1 - 1 - roots2.len() as i128) / 2 && bad2.iter().all(|r| r.0 .0 == r.1 .0));
    assert_eq!(2 * img2.len() as i128 - roots2.len() as i128 - 1, n1); // two-to-one except at branch points
    println!("mod {}: {} points, roots of f at x = {}, canonical image {} of {} points of the line", P, n1, show(&roots2), img2.len(), P + 1);
    println!("  pairs not separated: {}, every one a mirror pair (x, y), (x, -y); l(K - P - P') = 1 = g - 1", bad2.len());
    let nr = (2..P).find(|&a| chi(a) == -1).unwrap(); // F_169 = F_13 with a square root of nr
    let mut n2 = 1i128;
    for a in 0..P { for b in 0..P {
        let v = pw((a, b), 5, nr); let v = ((v.0 + a + 1) % P, (v.1 + b) % P);
        n2 += if v == (0, 0) { 1 } else if pw(v, (P * P - 1) / 2, nr) == (1, 0) { 2 } else { 0 };
    } }
    let (s1, s2) = (P + 1 - n1, P * P + 1 - n2); let e2 = (s1 * s1 - s2) / 2;
    assert_eq!((s1 * s1 - s2) % 2, 0);
    let d = s1 * s1 - 4 * (e2 - 2 * P); let sd = (d as f64).sqrt();
    let (b1, b2) = ((s1 as f64 + sd) / 2.0, (s1 as f64 - sd) / 2.0);
    assert!(d > 0 && b1.abs().max(b2.abs()) <= 2.0 * (P as f64).sqrt()); // four Frobenius roots of size sqrt(13): fits genus 2
    let g1_n2 = P * P + 1 - (s1 * s1 - 2 * P);
    assert!(g1_n2 != n2);
    println!("mod {}^2: {} points; L(T) = 1 + {}T + {}T^2 + {}T^3 + {}T^4", P, n2, -s1, e2, -P * s1, P * P);
    println!("  alpha + {}/alpha = {:.6} and {:.6}, both within 2 sqrt({}) = {:.6}", P, b1, b2, P, 2.0 * (P as f64).sqrt());
    println!("  a genus-1 curve with {} points mod {} would have {} points mod {}^2", n1, P, g1_n2, P);
    let mut pairs = 0i128; // Mumford pairs (u, v): u monic, deg v < deg u <= 2, u divides f - v^2
    for d in 0..3u32 { for k in 0..ipow(P, d) { for m in 0..ipow(P, d) {
        let (u, v): (Vec<i128>, Vec<i128>) = ((0..d).map(|i| k / ipow(P, i) % P).chain([1]).collect(), (0..d).map(|i| m / ipow(P, i) % P).collect());
        let mut w = f2.to_vec(); for i in 0..v.len() { for j in 0..v.len() { w[i + j] = (w[i + j] - v[i] * v[j]).rem_euclid(P); } }
        if rem(w, &u).iter().all(|&c| c == 0) { pairs += 1; }
    } } }
    let l1 = 1 - s1 + e2 - P * s1 + P * P;
    assert_eq!(pairs, l1);
    println!("  divisor classes of degree 0 mod {} (the Jacobian group): L(1) = {}; reduced pairs (u, v) by search: {}", P, l1, pairs);
    println!("Fermat curves x^d + y^d = z^d: genus formula against differentials x^i y^j dx/y^(d-1)");
    let mut h4: Vec<(i128, i128)> = vec![];
    for d in 3..7i128 {
        let hol: Vec<(i128, i128)> = (0..d).flat_map(|i| (0..d).map(move |j| (i, j))).filter(|&(i, j)| -i - j - 2 + (d - 1) >= 0).collect();
        assert_eq!(hol.len() as i128, (d - 1) * (d - 2) / 2);
        println!("  d = {}: genus {}, differentials {}, deg K {}", d, (d - 1) * (d - 2) / 2, hol.len(), d * (-2 + (d - 1))); if d == 4 { h4 = hol; }
    }
    let mut q: Vec<[i128; 3]> = vec![];
    for x in 0..P { for y in 0..P { if (ipow(x, 4) + ipow(y, 4) - 1) % P == 0 { q.push([x, y, 1]); } } }
    for y in 0..P { if (1 + ipow(y, 4)) % P == 0 { q.push([1, y, 0]); } }
    q.sort();
    let img4: BTreeSet<Vec<i128>> = q.iter().map(|u| { // x^i y^j dx/y^3, homogenised, first nonzero entry scaled to 1
        let w: Vec<i128> = h4.iter().map(|&(i, j)| ipow(u[0], i as u32) * ipow(u[1], j as u32) * ipow(u[2], (1 - i - j) as u32) % P).collect();
        let c = powm(*w.iter().find(|&&a| a != 0).unwrap(), P - 2); w.iter().map(|a| a * c % P).collect() }).collect();
    assert_eq!(img4.len(), q.len()); // one image per point: nothing folds
    let list: Vec<String> = q.iter().map(|u| format!("({}, {}, {})", u[0], u[1], u[2])).collect();
    println!("x^4 + y^4 = z^4 mod {}: {} points [{}]", P, q.len(), list.join(", "));
    println!("  canonical map from the differentials x^i y^j dx/y^3, (i, j) in {:?}: {} images, all {} pairs separated", h4, img4.len(), q.len() * (q.len() - 1) / 2);
    let f7 = [1i128, 1, 0, 0, 0, 0, 0, 1];
    assert!(disc_sylvester(&f7) % P != 0);
    let p7 = hyper_points(&f7); let img7 = canonical_image(&p7, 3);
    let bad7 = mirror_rank(&p7, 3).into_iter().filter(|r| r.2 == 1).count();
    assert!(img7.iter().all(|u| (u[0] * u[2] - u[1] * u[1]).rem_euclid(P) == 0)); // the conic u0 u2 = u1^2
    println!("y^2 = x^7 + x + 1 mod {}: {} points, canonical image {} points on the conic u0 u2 = u1^2", P, p7.len() + 1, img7.len());
    println!("  mirror pairs not separated: {}, l(K - P - P') = 2 = g - 1: hyperelliptic, not a plane quartic", bad7);
    println!("what breaks");
    let mut proj = vec![(1, 0, 2, 3)]; // y^2 z^3 - x^5 - x z^4 - z^5 as (c, a, b, e)
    for (i, &c) in f2.iter().enumerate() { if c != 0 { proj.push((-c, i as i128, 0, 5 - i as i128)); } }
    let mult = proj.iter().map(|&(_, a, _, e)| a + e).min().unwrap(); // set y = 1: lowest degree at (0 : 1 : 0)
    println!("  plane genus formula on degree 5: {}; y^2 z^3 = x^5 + x z^4 + z^5 at (0 : 1 : 0) has multiplicity {}", (5 - 1) * (5 - 2) / 2, mult);
    println!("  counting x^2 dx/y too: {} differentials, order at infinity {}", holomorphic(5).len() + 1, 2 * ox + odx - oy);
    let nodal = [0i128, 0, 1, 1]; // y^2 = x^2 (x + 1): x = 0 is a double root
    assert_eq!(disc_sylvester(&nodal), 0);
    let odd = (-3..4).filter(|&r| ev(&nodal, r) == 0 && ev(&[0, 2, 3], r) != 0).count() as i128; // simple roots
    assert!((-5..6i128).all(|t| ipow(t * (t * t - 1), 2) == ev(&nodal, t * t - 1))); // smooth model x = t^2 - 1
    println!("  nodal cubic: disc 0, branch points {}, genus {}; dx/y = 2 dt/(t^2 - 1), poles at t = 1 and -1", odd + 1, (odd + 1 - 2) / 2);
    let (mut lo, mut hi) = (-1.0f64, 0.0f64); // real branch point: root of x^3 - x^2 + 1, by bisection
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if mid * mid * mid - mid * mid + 1.0 < 0.0 { lo = mid; } else { hi = mid; } }
    assert!((lo * lo * lo * lo * lo + lo + 1.0).abs() < 1e-12);
    let (y1, y12) = (3.0f64.sqrt(), (1.2f64 * 1.2 * 1.2 * 1.2 * 1.2 + 2.2).sqrt());
    println!("figure,branch,{:.6},0,mirror,0,1,0,-1,x=1,{:.6},x=1.2,{:.6}", lo, y1, y12);
    println!("ALL CHECKS PASS");
}
