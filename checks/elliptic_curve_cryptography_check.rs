// Elliptic-curve cryptography -- the check behind the card.  std only, no crates.
// The toy curves are INSECURE: sized so every step can be followed and checked.
// Curve25519 runs on RFC 7748's test vectors, 256-bit numbers as four 64-bit limbs.
use std::collections::HashMap;
type Pt = Option<(u64, u64)>; // None is the zero point O
fn inv(x: u64, m: u64) -> u64 { // reciprocal mod m, by the extended Euclid method
    let (mut r0, mut r1, mut s0, mut s1) = ((x % m) as i128, m as i128, 1i128, 0i128);
    while r1 != 0 { let q = r0 / r1; (r0, r1, s0, s1) = (r1, r0 - q * r1, s1, s0 - q * s1); }
    assert!(r0 == 1);
    s0.rem_euclid(m as i128) as u64
}
fn mm(x: u64, y: u64, p: u64) -> u64 { ((x as u128 * y as u128) % p as u128) as u64 }
fn slope(a: (u64, u64), b: (u64, u64), p: u64, c: u64) -> u64 {
    if a == b { mm((3 * mm(a.0, a.0, p) + c) % p, inv(2 * a.1 % p, p), p) }
    else { mm((b.1 + p - a.1) % p, inv((b.0 + p - a.0) % p, p), p) }
}
fn add(pp: Pt, qq: Pt, p: u64, c: u64) -> Pt { // chord and tangent
    let (a, b) = match (pp, qq) { (None, _) => return qq, (_, None) => return pp, (Some(a), Some(b)) => (a, b) };
    if a.0 == b.0 && (a.1 + b.1) % p == 0 { return None; }
    let m = slope(a, b, p, c);
    let x = (mm(m, m, p) + 2 * p - a.0 - b.0) % p;
    Some((x, (mm(m, (a.0 + p - x) % p, p) + p - a.1) % p))
}
fn mul(k: u64, g: Pt, p: u64, c: u64, trace: &mut Vec<(&'static str, u64, Pt)>) -> (Pt, [u64; 2]) {
    let (mut r, mut ops) = (g, [0u64; 2]);
    if k == 0 { return (None, ops); }
    for t in (0..63 - k.leading_zeros()).rev() {
        for op in ["double", "add G"].into_iter().take(1 + ((k >> t) & 1) as usize) {
            let q = if op == "double" { r } else { g };
            let m = if trace.capacity() > 0 { slope(r.unwrap(), q.unwrap(), p, c) } else { 0 };
            r = add(r, q, p, c); ops[(op == "add G") as usize] += 1;
            if trace.capacity() > 0 { trace.push((op, m, r)); }
        }
    }
    (r, ops)
}
fn m0(k: u64, g: Pt, p: u64, c: u64) -> Pt { mul(k, g, p, c, &mut Vec::new()).0 }
fn rep(k: u64, g: Pt, p: u64, c: u64) -> Pt { let mut r = None; for _ in 0..k { r = add(r, g, p, c); } r }
fn sh(q: Pt) -> String { match q { Some((x, y)) => format!("({}, {})", x, y), None => "O".into() } }
type F = [u64; 4]; // ---- 256-bit arithmetic mod p = 2^255 - 19 ----
const P25: F = [0xffffffffffffffed, u64::MAX, u64::MAX, 0x7fffffffffffffff];
fn geq(a: &F, b: &F) -> bool { for i in (0..4).rev() { if a[i] != b[i] { return a[i] > b[i]; } } true }
fn sub_raw(a: &F, b: &F) -> F { // a - b, for a >= b
    let (mut r, mut br) = ([0u64; 4], false);
    for i in 0..4 { let (d1, o1) = a[i].overflowing_sub(b[i]); let (d2, o2) = d1.overflowing_sub(br as u64); r[i] = d2; br = o1 | o2; } r
}
fn fold(t: &[u64; 8]) -> F { // low half + 38 * high half, since 2^256 = 38 mod p
    let (mut r, mut c) = ([0u64; 4], 0u128);
    for i in 0..4 { c += t[i] as u128 + 38 * t[i + 4] as u128; r[i] = c as u64; c >>= 64; }
    while c > 0 { let mut d = c * 38; for i in 0..4 { d += r[i] as u128; r[i] = d as u64; d >>= 64; } c = d; }
    while geq(&r, &P25) { r = sub_raw(&r, &P25); } r
}
fn fadd(a: &F, b: &F) -> F {
    let (mut t, mut c) = ([0u64; 8], 0u128);
    for i in 0..4 { c += a[i] as u128 + b[i] as u128; t[i] = c as u64; c >>= 64; } t[4] = c as u64; fold(&t)
}
fn fsub(a: &F, b: &F) -> F { fadd(a, &sub_raw(&P25, b)) }
fn fmul(a: &F, b: &F) -> F {
    let mut t = [0u64; 8];
    for i in 0..4 { let mut c = 0u128;
        for j in 0..4 { c += t[i + j] as u128 + a[i] as u128 * b[j] as u128; t[i + j] = c as u64; c >>= 64; }
        t[i + 4] = c as u64; }
    fold(&t)
}
fn finv(x: &F) -> F { // x^(p-2), square-and-multiply
    let (mut e, mut r): (F, F) = (P25, [1, 0, 0, 0]); e[0] -= 2;
    for t in (0..255).rev() { r = fmul(&r, &r); if (e[t / 64] >> (t % 64)) & 1 == 1 { r = fmul(&r, x); } } r
}
fn ladder(k: &F, u: &F) -> F { // Montgomery ladder: one doubling and one addition per bit
    let (x1, mut x2, mut z2, mut x3, mut z3) = (*u, [1u64, 0, 0, 0], [0u64; 4], *u, [1u64, 0, 0, 0]);
    for t in (0..255).rev() {
        let bit = (k[t / 64] >> (t % 64)) & 1 == 1;
        if bit { std::mem::swap(&mut x2, &mut x3); std::mem::swap(&mut z2, &mut z3); }
        let (a, b, c, d) = (fadd(&x2, &z2), fsub(&x2, &z2), fadd(&x3, &z3), fsub(&x3, &z3));
        let (aa, bb, da, cb) = (fmul(&a, &a), fmul(&b, &b), fmul(&d, &a), fmul(&c, &b));
        let (e, s, df) = (fsub(&aa, &bb), fadd(&da, &cb), fsub(&da, &cb));
        x3 = fmul(&s, &s); z3 = fmul(&x1, &fmul(&df, &df));
        x2 = fmul(&aa, &bb); z2 = fmul(&e, &fadd(&aa, &fmul(&[121665, 0, 0, 0], &e)));
        if bit { std::mem::swap(&mut x2, &mut x3); std::mem::swap(&mut z2, &mut z3); }
    }
    fmul(&x2, &finv(&z2)) // O has z = 0, and 0^(p-2) = 0, as in RFC 7748
}
fn from_hex(h: &str) -> [u8; 32] { let mut b = [0u8; 32]; for i in 0..32 { b[i] = u8::from_str_radix(&h[2 * i..2 * i + 2], 16).unwrap(); } b }
fn limbs(b: &[u8; 32]) -> F { let mut r = [0u64; 4]; for i in 0..32 { r[i / 8] |= (b[i] as u64) << (8 * (i % 8)); } r }
fn clamp(h: &str) -> F { let mut b = from_hex(h); b[0] &= 248; b[31] = (b[31] & 127) | 64; limbs(&b) }
fn hex(f: &F) -> String { (0..32).map(|i| format!("{:02x}", (f[i / 8] >> (8 * (i % 8))) as u8)).collect() }
fn ux(h: &str) -> F { let mut f = limbs(&from_hex(h)); f[3] &= 0x7fffffffffffffff; f }
fn x25519(h: &str, u: &F) -> String { hex(&ladder(&clamp(h), u)) }

fn main() {
    // ---- toy curve: y^2 = x^3 + 2x + 2 mod 17, base point G = (5, 1) ----
    let ((p, c, b, g), mut count): ((u64, u64, u64, Pt), u64) = ((17, 2, 2, Some((5, 1))), 1);
    for x in 0..p { for y in 0..p { if (y * y) % p == (x * x * x + c * x + b) % p { count += 1; } } }
    let n = (1..100).find(|&k| rep(k, g, p, c).is_none()).unwrap();
    println!("toy curve mod 17: points {}  order of G {}", count, n);
    assert!(count == 19 && n == 19);
    // ---- ECDH on the toy: laptop key 13, bank key 7 ----
    let (dl, db, mut tr) = (13u64, 7u64, Vec::with_capacity(8));
    let (ql, ops) = mul(dl, g, p, c, &mut tr);
    for t in &tr { println!("  {:6} slope {:2} -> {}", t.0, t.1, sh(t.2)); }
    let qb = m0(db, g, p, c);
    let (sl, sb) = (m0(dl, qb, p, c), m0(db, ql, p, c)); // each side uses its own key on the other's point
    println!("QL = 13G {}  QB = 7G {}  doublings, additions [{}, {}]", sh(ql), sh(qb), ops[0], ops[1]);
    println!("laptop 13*QB {}  bank 7*QL {}  91 mod 19 = {}", sh(sl), sh(sb), 91 % 19);
    assert!(ql == rep(13, g, p, c) && sl == sb && sb == rep(91 % 19, g, p, c));
    let tries = (1..n).find(|&k| rep(k, g, p, c) == ql).unwrap();
    println!("exhaustive search: laptop key found on try {} of at most {}", tries, n - 1);
    assert!(tries == dl);
    // ---- ECDSA on the toy: signing key dS = 9, nonce k = 10, hash stand-in z = 5 ----
    let (ds, k, z) = (9u64, 10u64, 5u64);
    let qs = m0(ds, g, p, c);
    let sign = |z: u64, k: u64, d: u64| { let r = m0(k, g, p, c).unwrap().0 % n; (r, mm(inv(k, n), (z + r * d) % n, n)) };
    let verify = |z: u64, r: u64, s: u64| {
        let (u1, u2) = (z * inv(s, n) % n, r * inv(s, n) % n);
        let rr = add(m0(u1, g, p, c), m0(u2, qs, p, c), p, c);
        (rr.map_or(false, |q| q.0 % n == r), u1, u2, rr)
    };
    let ((r, s), qk) = (sign(z, k, ds), m0(k, g, p, c));
    let (ok, u1, u2, rr) = verify(z, r, s);
    println!("QS = 9G {}  kG {}  r {}  s {}  1/k {}", sh(qs), sh(qk), r, s, inv(k, n));
    println!("verify: 1/s {}  u1 {}  u2 {}  u1 G + u2 QS {}  valid {}", inv(s, n), u1, u2, sh(rr), if ok { "True" } else { "False" });
    assert!(ok && rr == qk && qk == rep(k, g, p, c) && s * k % n == (z + r * ds) % n);
    println!("same signature, hash stand-in 6 instead of 5: valid {}", if verify(6, r, s).0 { "True" } else { "False" });
    assert!(!verify(6, r, s).0);
    // ---- what breaks: one nonce, two messages ----
    let (z2, s2) = (11u64, sign(11, k, ds).1);
    let kk = mm((z + n - z2) % n, inv((s + n - s2) % n, n), n);
    let dd = mm((s * kk + n - z) % n, inv(r, n), n);
    println!("nonce reused: s2 {}  recovered k {}  recovered key {}", s2, kk, dd);
    assert!((kk, dd) == (k, ds));
    // ---- a generic attack on a 32-bit toy curve: baby step, giant step ----
    let (p, c, g, n): (u64, u64, Pt, u64) = (4294967291, 3, Some((2, 6)), 4294956467);
    let (gx, gy) = g.unwrap(); // G on y^2 = x^3 + 3x + 22, and nG = O
    assert!((mm(gy, gy, p) + p - (mm(mm(gx, gx, p), gx, p) + c * gx + 22) % p) % p == 0 && m0(n, g, p, c).is_none());
    let mut q = 2u64; while q * q <= n { assert!(n % q != 0); q += 1; }
    let secret = 3141592653u64;
    let qq = m0(secret, g, p, c);
    let m = { let mut s = 0u64; while s * s < n { s += 1; } s };
    let (mut table, mut rr): (HashMap<Pt, u64>, Pt) = (HashMap::new(), None);
    for j in 0..m { table.entry(rr).or_insert(j); rr = add(rr, g, p, c); }
    let step = rr.map(|(x, y)| (x, (p - y) % p)); // -mG
    let (mut t, mut i) = (qq, 0u64);
    while !table.contains_key(&t) { t = add(t, step, p, c); i += 1; }
    let found = i * m + table[&t];
    println!("32-bit toy: n {}  baby steps {}  giant steps {}  total {}", n, m, i, m + i);
    println!("found key {}  exhaustive search would need up to {} additions", found, n - 1);
    assert!(found == secret && m + i <= 2 * m);
    // ---- Curve25519, X25519 as in RFC 7748 ----
    let n25: F = [0x5812631a5cf5d3ed, 0x14def9dea2f79cd6, 0, 0x1000000000000000];
    let ahex = "77076d0a7318a57d3c16c17251b26645df4c2f87ebc0992ab177fba51db92c2a";
    let bhex = "5dab087e624a8a4b79e17f8b83800ee66f3bb1292618b6fd1c2f8b27ff88e0eb";
    let (nine, n1): (F, F) = ([9, 0, 0, 0], [n25[0] + 1, n25[1], n25[2], n25[3]]);
    let (ka, kb) = (x25519(ahex, &nine), x25519(bhex, &nine));
    let (k1, k2) = (x25519(ahex, &ux(&kb)), x25519(bhex, &ux(&ka)));
    println!("laptop public {}", ka); println!("bank public   {}", kb); println!("shared, both  {}", k1);
    assert!(ka == "8520f0098930a754748b7ddcb43ef75a0dbf3a0d26381af4eba4a98eaa9b4e6a");
    assert!(kb == "de9edb7d7b7dc1b4d35b61c2ece435373f8343c85b78674dadfc7e146f882b4f");
    assert!(k1 == k2 && k2 == "4a5d9d5ba4ce2de1728e3bf480350f25e07e21c947d19e3376f09b3c1e161742");
    let (o0, o1) = (ladder(&n25, &nine), ladder(&n1, &nine));
    println!("order check: u of nG {}  u of (n+1)G {}", o0[0], o1[0]);
    assert!(o0 == [0u64; 4] && o1 == nine);
    let (sa, nbits) = (clamp(ahex), 256 - n25[3].leading_zeros());
    let (bits, ones) = (256 - sa[3].leading_zeros(), sa.iter().map(|w| w.count_ones()).sum::<u32>());
    println!("laptop scalar bits {}  double-and-add: doublings {}  additions {}  ladder steps {}", bits, bits - 1, ones - 1, 255);
    println!("bank sends u = 0, a point of order 2: shared {}", x25519(ahex, &[0u64; 4]));
    assert!(x25519(ahex, &[0u64; 4]) == "0".repeat(64));
    println!("bytes: public key 32, RSA-3072 modulus {}  n has {} bits  A {}", 3072 / 8, nbits, 4 * 121665 + 2);
    println!("generic attack, about sqrt(pi n / 4) steps: 2^{:.1}", ((std::f64::consts::PI / 4.0).log2() + (nbits - 1) as f64) / 2.0);
    println!("ALL CHECKS PASS");
}
