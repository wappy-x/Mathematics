// Mordell-Weil for y^2 = x^3 - 2: torsion, a 2-descent, and the generator (3, 5).
// Standard library only: fractions in i128 (overflow stops the run) and big whole numbers written here.
#[derive(Clone, Copy, PartialEq, Debug)]
struct R { n: i128, d: i128 }                           // n/d in lowest terms, d > 0
fn ri(n: i128) -> R { r(n, 1) }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> R { let g = gcd(n, d) * d.signum(); R { n: n / g, d: d / g } }
fn ml(a: R, b: R) -> R { r(a.n.checked_mul(b.n).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn dv(a: R, b: R) -> R { r(a.n.checked_mul(b.d).unwrap(), a.d.checked_mul(b.n).unwrap()) }
fn ad(a: R, b: R) -> R { r((a.n.checked_mul(b.d).unwrap()).checked_add(b.n.checked_mul(a.d).unwrap()).unwrap(), a.d.checked_mul(b.d).unwrap()) }
fn sb(a: R, b: R) -> R { ad(a, R { n: -b.n, d: b.d }) }
fn fs(a: R) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
type P = Option<(R, R)>;                                 // None is the point O
fn add(p: P, q: P) -> P {                                // chord-tangent rule on y^2 = x^3 + b
    let (p, q) = match (p, q) { (None, _) => return q, (_, None) => return p, (Some(p), Some(q)) => (p, q) };
    if p.0 == q.0 && p.1.n == -q.1.n && p.1.d == q.1.d { return None; }
    let m = if p == q { dv(ml(ri(3), ml(p.0, p.0)), ml(ri(2), p.1)) } else { dv(sb(q.1, p.1), sb(q.0, p.0)) };
    let x = sb(sb(ml(m, m), p.0), q.0);
    Some((x, sb(ml(m, sb(p.0, x)), p.1)))
}
fn show(p: P) -> String { let (x, y) = p.unwrap(); format!("({}, {})", fs(x), fs(y)) }
fn isqrt(v: i128) -> i128 { let mut s = (v as f64).sqrt() as i128; while s * s > v { s -= 1; } while (s + 1) * (s + 1) <= v { s += 1; } s }
fn is_sq(v: i128) -> bool { v >= 0 && isqrt(v) * isqrt(v) == v }
fn hgt(x: R) -> i128 { x.n.abs().max(x.d) }               // the naive height of x
// Big whole numbers: sign and base-10^9 digits, lowest first
#[derive(Clone, PartialEq)]
struct B { neg: bool, m: Vec<u64> }
const BASE: u64 = 1_000_000_000;
fn trim(mut m: Vec<u64>) -> Vec<u64> { while m.len() > 1 && *m.last().unwrap() == 0 { m.pop(); } m }
fn bi(v: i128) -> B { let (mut m, mut a) = (vec![], v.unsigned_abs()); loop { m.push((a % BASE as u128) as u64); a /= BASE as u128; if a == 0 { break; } } B { neg: v < 0, m } }
fn cmpm(a: &[u64], b: &[u64]) -> std::cmp::Ordering { a.len().cmp(&b.len()).then_with(|| a.iter().rev().cmp(b.iter().rev())) }
fn addm(a: &[u64], b: &[u64]) -> Vec<u64> {
    let (mut o, mut c) = (vec![], 0);
    for i in 0..a.len().max(b.len()) { let s = a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0) + c; o.push(s % BASE); c = s / BASE; }
    o.push(c); trim(o)
}
fn subm(a: &[u64], b: &[u64]) -> Vec<u64> {                // needs a >= b
    let (mut o, mut br) = (vec![], 0i64);
    for i in 0..a.len() { let mut s = a[i] as i64 - *b.get(i).unwrap_or(&0) as i64 - br; br = 0; if s < 0 { s += BASE as i64; br = 1; } o.push(s as u64); }
    trim(o)
}
fn badd(a: &B, b: &B) -> B {
    if a.neg == b.neg { return B { neg: a.neg, m: addm(&a.m, &b.m) }; }
    if cmpm(&a.m, &b.m) != std::cmp::Ordering::Less { B { neg: a.neg, m: subm(&a.m, &b.m) } } else { B { neg: b.neg, m: subm(&b.m, &a.m) } }
}
fn bsub(a: &B, b: &B) -> B { badd(a, &B { neg: !b.neg, m: b.m.clone() }) }
fn bmul(a: &B, b: &B) -> B {
    let mut o = vec![0u128; a.m.len() + b.m.len() + 1];
    for (i, &x) in a.m.iter().enumerate() { for (j, &y) in b.m.iter().enumerate() { o[i + j] += x as u128 * y as u128; let c = o[i + j] / BASE as u128; o[i + j] %= BASE as u128; o[i + j + 1] += c; } }
    B { neg: a.neg != b.neg, m: trim(o.iter().map(|&v| v as u64).collect()) }
}
fn bdiv(a: &B, s: u64) -> B {                              // exact division by a small number
    let (mut o, mut rem) = (vec![0; a.m.len()], 0u64);
    for i in (0..a.m.len()).rev() { let cur = rem * BASE + a.m[i]; o[i] = cur / s; rem = cur % s; }
    assert!(rem == 0); B { neg: a.neg, m: trim(o) }
}
fn bstr(a: &B) -> String { let mut s = a.m.last().unwrap().to_string(); for v in a.m.iter().rev().skip(1) { s += &format!("{:09}", v); } s }
fn lnbig(a: &B) -> f64 { let s = bstr(a); let k = s.len().min(17); s[..k].parse::<f64>().unwrap().ln() + (s.len() - k) as f64 * 10f64.ln() }
fn divs(v: i128) -> Vec<i128> {
    let v = v.abs(); let lo: Vec<i128> = (1..=isqrt(v)).filter(|d| v % d == 0).collect();
    lo.iter().cloned().chain(lo.iter().map(|d| v / d)).collect()
}
fn halves(xq: R, a: i128, b: i128) -> Vec<R> {           // rational roots x(R) of the halving quartic
    let (n, d) = (xq.n, xq.d); let co = [d, -4 * n, -2 * a * d, -8 * b * d - 4 * a * n, a * a * d - 4 * b * n];
    let mut roots: Vec<R> = vec![];
    for &rr in &(if co[4] == 0 { vec![0] } else { divs(co[4]) }) { for &s in &divs(co[0]) { for &x in &[r(rr, s), r(-rr, s)] {
        let mut v = bi(0);
        for (i, &c) in co.iter().enumerate() {
            let mut t = bi(c);
            for _ in 0..(4 - i) { t = bmul(&t, &bi(x.n)); }
            for _ in 0..i { t = bmul(&t, &bi(x.d)); }
            v = badd(&v, &t);
        }
        if v.m == vec![0] && !roots.contains(&x) { roots.push(x); }
    } } }
    roots.sort_by(|p, q| (p.n * q.d).cmp(&(q.n * p.d))); roots
}
fn m3(u: [i128; 3], v: [i128; 3]) -> [i128; 3] {
    let ([a, b, c], [d, e, f]) = (u, v);
    [a * d + 2 * (b * f + c * e), a * e + b * d + 2 * c * f, a * f + b * e + c * d]
}
fn norm(u: [i128; 3]) -> i128 { let [a, b, c] = u; a.pow(3) + 2 * b.pow(3) + 4 * c.pow(3) - 6 * a * b * c }
fn join<T: ToString>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }

fn main() {
    let p: P = Some((ri(3), ri(5)));
    // Torsion, road 1: Nagell-Lutz
    let ys: Vec<i128> = (0..11).filter(|&y| y == 0 || 108 % (y * y) == 0).collect();
    let rhs: Vec<i128> = ys.iter().map(|y| y * y + 2).collect();
    println!("Nagell-Lutz: 4a^3 + 27b^2 = {}, |discriminant| = {}; allowed y {:?}; x^3 = y^2 + 2 = {:?}; none is a cube", 27 * 4, 16 * 108, ys, rhs);
    assert!(rhs.iter().all(|&v| (0..=v).all(|c| c * c * c != v)));
    // Torsion, road 2: point counts mod good primes
    let cs: Vec<(i128, i128)> = [5i128, 7, 11, 13, 17].iter().map(|&q| (q, 1 + (0..q).map(|x| (0..q).filter(|y| (y * y - x * x * x + 2).rem_euclid(q) == 0).count() as i128).sum::<i128>())).collect();
    let g = cs.iter().fold(0, |g, &(_, c)| gcd(g, c));
    println!("points mod p: {}; gcd {}, so the torsion is O alone", cs.iter().map(|(q, c)| format!("{}:{}", q, c)).collect::<Vec<_>>().join(", "), g);
    assert!(g == 1 && cs.iter().all(|&(q, c)| q % 3 != 2 || c == q + 1));
    let mut mult: Vec<P> = vec![None];
    for _ in 0..4 { let l = *mult.last().unwrap(); mult.push(add(l, p)); }
    let (px, py) = p.unwrap(); println!("tangent slope at P = {}; 2P = {}, 3P = {}", fs(dv(ml(ri(3), ml(px, px)), ml(ri(2), py))), show(mult[2]), show(mult[3]));
    assert!(mult[2] == Some((r(129, 100), r(-383, 1000))));
    // The descent map x - t in Z[t], t^3 = 2
    let (u, t, t1, s) = ([-1, 1, 0], [0, 1, 0], [1, 1, 0], [1, 0, 1]);
    assert!(m3(u, [1, 1, 1]) == [1, 0, 0] && m3(t, m3(t, t)) == [2, 0, 0] && m3(u, m3(t1, m3(t1, t1))) == [3, 0, 0]);
    let us = m3(u, m3(s, s));
    println!("u (1 + t^2)^2 = ({}) = 3 - t, of norm {}: P lands on the class of u", join(&us), norm([3, -1, 0]));
    assert!(us == [3, -1, 0] && norm([3, -1, 0]) == 25 && norm([1, 1, 1]) == 1);
    let mut ok = vec![]; for sg in [1i128, -1] { for i in 0..2u32 { for j in 0..2u32 { for k in 0..2u32 {
        if is_sq(sg * norm(u).pow(i) * norm(t).pow(j) * norm(t1).pow(k)) { ok.push((sg, i, j, k)); }
    } } } }
    println!("norms of -1, u, t, t + 1: -1, {}, {}, {}", norm(u), norm(t), norm(t1));
    println!("classes: 16 before the norm test, {} after: 1 and u; so 2^r <= {} and r <= 1", ok.len(), ok.len());
    assert!(ok.len() == 2 && ok.contains(&(1, 1, 0, 0)));
    // Halving, from 4P down
    let (mut q, mut lh) = (mult[4], vec![]);
    println!("descent from {}P, x = {}:", mult.iter().position(|&m| m == q).unwrap(), fs(q.unwrap().0));
    loop {
        let x = q.unwrap().0; let h = halves(x, 0, -2); lh.push((hgt(x) as f64).ln());
        let hs = if h.is_empty() { "none".to_string() } else { h.iter().map(|&v| fs(v)).collect::<Vec<_>>().join(", ") };
        println!("  ln H(x) = {:.4}; rational halves x(R): {}", (hgt(x) as f64).ln(), hs);
        if h.is_empty() { break; }
        let y2 = sb(ml(h[0], ml(h[0], h[0])), ri(2)); let y = r(isqrt(y2.n), isqrt(y2.d));
        q = [Some((h[0], y)), Some((h[0], R { n: -y.n, d: y.d }))].into_iter().find(|&c| add(c, c) == q).unwrap();
    }
    println!("stop at {}: no rational half, so it is not in 2E(Q){}", show(q), if lh.len() > 1 { format!("; ln H fell by {} times", lh.windows(2).map(|w| format!("{:.2}", w[0] / w[1])).collect::<Vec<_>>().join(", then ")) } else { String::new() });
    assert!(q == p);
    // Second road: the points nP worked mod 17 directly, a separate group law over GF(17)
    let md = |v: i128| v.rem_euclid(17); let inv = |v: i128| (1..17).find(|&w| md(v * w) == 1).unwrap();
    let (mut cx, mut cy, mut sq) = (3i128, 5i128, vec![]); for n in 1..9 {
        if n > 1 {
            let m = if n == 2 { md(3 * cx * cx * inv(2 * cy)) } else { md((cy - 5) * inv(cx - 3)) };
            let nx = md(m * m - cx - if n == 2 { cx } else { 3 });
            cy = md(m * (cx - nx) - cy); cx = nx;
        }
        sq.push(if (1..17).any(|w| md(w * w) == md(cx - 8)) { "yes" } else { "no" });
    }
    println!("mod 17, is x(nP) - 8 a square, n = 1..8: {}", sq.join(" "));
    assert!(sq.iter().enumerate().all(|(i, &v)| (v == "yes") == (i % 2 == 1)));
    // P generates: Silverman's height bounds and a search box
    let (lo, up) = (1728f64.ln() / 12.0 + 0.973, 1728f64.ln() / 12.0 + 1.07);
    let hmax = (3f64.ln() + 2.0 * up) / 9.0 + 2.0 * lo;
    println!("ln 1728 / 12 = {:.5}; h-hat(P) <= ln 3 + {:.5} = {:.4}", 1728f64.ln() / 12.0, 2.0 * up, 3f64.ln() + 2.0 * up);
    println!("a G with P = kG, k >= 3, has ln H(x(G)) <= {:.4}/9 + {:.5} = {:.4}, so H <= {:.1}", 3f64.ln() + 2.0 * up, 2.0 * lo, hmax, hmax.exp());
    let mut bx: Vec<R> = vec![]; for e in 1..32i128 { for m in -1000..=1000i128 { if gcd(m, e) == 1 && is_sq(m.pow(3) - 2 * e.pow(6)) { bx.push(r(m, e * e)); } } }
    let small: Vec<String> = bx.iter().filter(|&&x| hgt(x) <= 39).map(|&x| fs(x)).collect();
    println!("search H <= 1000 finds x = {}; with H <= 39 only x = {}", bx.iter().map(|&x| fs(x)).collect::<Vec<_>>().join(", "), small.join(", "));
    assert!(bx == vec![ri(3), r(129, 100)] && hmax.exp() > 39.0 && hmax.exp() < 40.0);
    // Canonical height by division polynomials, in big whole numbers
    let mut ps: Vec<B> = [0i128, 1, 10, 171, -7660].iter().map(|&v| bi(v)).collect();
    while ps.len() < 67 {
        let (k, cube, sqr) = (ps.len(), |v: &B| bmul(v, &bmul(v, v)), |v: &B| bmul(v, v)); let m = k / 2;
        let nv = if k % 2 == 1 { bsub(&bmul(&ps[m + 2], &cube(&ps[m])), &bmul(&ps[m - 1], &cube(&ps[m + 1]))) }
                 else { bdiv(&bmul(&ps[m], &bsub(&bmul(&ps[m + 2], &sqr(&ps[m - 1])), &bmul(&ps[m - 2], &sqr(&ps[m + 1])))), 10) };
        ps.push(nv);
    }
    let xn = |n: usize| (bsub(&bmul(&bi(3), &bmul(&ps[n], &ps[n])), &bmul(&ps[n + 1], &ps[n - 1])), bmul(&ps[n], &ps[n]));
    for n in 1..5 { let (a, b) = xn(n); let x = mult[n].unwrap().0; assert!(bstr(&a) == x.n.abs().to_string() && a.neg == (x.n < 0) && bstr(&b) == x.d.to_string()); }
    let dg: Vec<usize> = (1..13).map(|n| bstr(&xn(n).1).len()).collect();
    println!("digits of the denominator of x(nP), n = 1..12: {:?}", dg);
    let hh: Vec<f64> = (0..7).map(|k| { let (a, b) = xn(1 << k); lnbig(&a).max(lnbig(&b)) / 4f64.powi(k as i32) }).collect();
    println!("ln H(x(nP)) / n^2 at n = 1, 2, 4, ..., 64: {}; x(64P) has a {}-digit denominator", hh.iter().map(|v| format!("{:.5}", v)).collect::<Vec<_>>().join(", "), bstr(&xn(64).1).len());
    let tr: Vec<i64> = (1..13).map(|n| (1.34958 * (n * n) as f64 / 10f64.ln()).round() as i64).collect();
    println!("trend line 1.34958 n^2 / ln 10, n = 1..12: {:?}", tr);
    assert!((hh[6] - 1.34958).abs() < 0.002);
    // What breaks
    let two: Vec<usize> = [-1i128, 0, 1].iter().map(|&x| halves(ri(x), -1, 0).len()).collect();
    println!("y^2 = x^3 - x: rational halves of (-1, 0), (0, 0), (1, 0): {:?}, so |E/2E| = 4, yet r = 0", two);
    assert!(two == vec![0, 0, 0]); // every non-zero point is a non-double
    println!("search box H <= 2 on y^2 = x^3 - 2 finds {} points; P has H = 3", bx.iter().filter(|&&x| hgt(x) <= 2).count());
    println!("ALL CHECKS PASS");
}
