// Digital signatures -- the check behind the card.  std only, no crates.
// SHA-256 (FIPS 180-4) and ECDSA (FIPS 186-5) are written out.
// The curve is a TOY, insecure on purpose: about 2^20 points, where P-256 has about 2^256.
use std::collections::HashMap;

fn primes(c: usize) -> Vec<u64> {
    let mut out: Vec<u64> = Vec::new();
    let mut x = 2u64;
    while out.len() < c { if out.iter().filter(|&&p| p * p <= x).all(|&p| x % p != 0) { out.push(x); } x += 1; }
    out
}
fn root_bits(r: u32, x: u64) -> u32 { // 32 bits after the point of x^(1/r), integers only
    let (mut lo, mut hi) = (0u128, 1u128 << 40);
    while lo < hi {
        let mid = (lo + hi + 1) / 2;
        if mid.pow(r) <= (x as u128) << (32 * r) { lo = mid; } else { hi = mid - 1; }
    }
    lo as u32
}
fn sha256(msg: &[u8]) -> [u8; 32] {
    let k: Vec<u32> = primes(64).iter().map(|&p| root_bits(3, p)).collect();
    let mut st: Vec<u32> = primes(8).iter().map(|&p| root_bits(2, p)).collect();
    let mut m = msg.to_vec();
    m.push(0x80);
    while m.len() % 64 != 56 { m.push(0); }
    m.extend_from_slice(&(8 * msg.len() as u64).to_be_bytes());
    for blk in m.chunks(64) {
        let mut w: Vec<u32> = (0..16).map(|i| u32::from_be_bytes([blk[4 * i], blk[4 * i + 1], blk[4 * i + 2], blk[4 * i + 3]])).collect();
        for i in 16..64 {
            let (a, b) = (w[i - 15], w[i - 2]);
            let s0 = a.rotate_right(7) ^ a.rotate_right(18) ^ (a >> 3);
            let s1 = b.rotate_right(17) ^ b.rotate_right(19) ^ (b >> 10);
            w.push(w[i - 16].wrapping_add(s0).wrapping_add(w[i - 7]).wrapping_add(s1));
        }
        let (mut a, mut b, mut c, mut d, mut e, mut f, mut g, mut h) = (st[0], st[1], st[2], st[3], st[4], st[5], st[6], st[7]);
        for i in 0..64 {
            let t1 = h.wrapping_add(e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25))
                .wrapping_add((e & f) ^ (!e & g)).wrapping_add(k[i]).wrapping_add(w[i]);
            let t2 = (a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22)).wrapping_add((a & b) ^ (a & c) ^ (b & c));
            h = g; g = f; f = e; e = d.wrapping_add(t1); d = c; c = b; b = a; a = t1.wrapping_add(t2);
        }
        for (x, y) in st.iter_mut().zip([a, b, c, d, e, f, g, h]) { *x = x.wrapping_add(y); }
    }
    let mut out = [0u8; 32];
    for i in 0..8 { out[4 * i..4 * i + 4].copy_from_slice(&st[i].to_be_bytes()); }
    out
}
fn hex(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }

// ---- the toy curve: y^2 = x^3 + 7 mod p, the equation Bitcoin uses, at 20 bits ----
const P: i64 = 1_000_003;
const N: i64 = 999_007; // number of multiples of G
const G: (i64, i64) = (100, 2);
type Pt = Option<(i64, i64)>; // None is the point at infinity
fn md(a: i64, m: i64) -> i64 { a.rem_euclid(m) }
fn inv(a: i64, m: i64) -> i64 { // 1/a mod m by Euclid's algorithm
    let (mut r0, mut r1, mut t0, mut t1) = (m, md(a, m), 0i64, 1i64);
    while r1 != 0 { let q = r0 / r1; (r0, r1, t0, t1) = (r1, r0 - q * r1, t1, t0 - q * t1); }
    assert!(r0 == 1);
    md(t0, m)
}
fn add(a: Pt, b: Pt) -> Pt {
    let (p1, q1) = match (a, b) { (None, _) => return b, (_, None) => return a, (Some(x), Some(y)) => (x, y) };
    if p1.0 == q1.0 && md(p1.1 + q1.1, P) == 0 { return None; }
    let lam = if p1 == q1 { md(3 * p1.0 * p1.0 % P * inv(2 * p1.1, P), P) }
              else { md(md(q1.1 - p1.1, P) * inv(q1.0 - p1.0, P), P) };
    let x = md(lam * lam - p1.0 - q1.0, P);
    Some((x, md(lam * (p1.0 - x) - p1.1, P)))
}
fn mul(mut k: i64, mut pt: Pt) -> Pt { // kP by double-and-add
    let mut r: Pt = None;
    while k > 0 {
        if k & 1 == 1 { r = add(r, pt); }
        pt = add(pt, pt); k >>= 1;
    }
    r
}
fn z_of(msg: &[u8]) -> i64 { // leftmost 20 bits of the hash
    let h = sha256(msg);
    (((h[0] as i64) << 24 | (h[1] as i64) << 16 | (h[2] as i64) << 8 | h[3] as i64) >> (32 - 20)) as i64
}
fn sign(d: i64, k: i64, msg: &[u8]) -> (i64, i64) {
    let (z, r) = (z_of(msg), mul(k, Some(G)).unwrap().0 % N);
    (r, inv(k, N) * md(z + r * d, N) % N)
}
fn verify(q: Pt, msg: &[u8], sig: (i64, i64)) -> bool {
    let (r, s) = sig;
    if !(0 < r && r < N && 0 < s && s < N) { return false; }
    let w = inv(s, N);
    match add(mul(z_of(msg) * w % N, Some(G)), mul(r * w % N, q)) { Some(x) => x.0 % N == r, None => false }
}
fn sp(p: Pt) -> String { let (x, y) = p.unwrap(); format!("({}, {})", x, y) }
fn commas(x: i64) -> String {
    let s = x.to_string();
    s.chars().enumerate().fold(String::new(), |mut o, (i, ch)| { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(ch); o })
}

fn main() {
    let abc = hex(&sha256(b"abc"));
    println!("sha256('abc') = {} ... {}", &abc[..16], &abc[56..]);
    assert!(abc == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    assert!((2..1000).all(|f| N % f != 0) && mul(N, Some(G)).is_none() && G.1 * G.1 % P == md(G.0 * G.0 * G.0 + 7, P));
    println!("toy curve y^2 = x^3 + 7 mod {}, G = {}, n = {} (prime, 20 bits), nG = infinity", P, sp(Some(G)), N);
    // ---- the example: the bank signs a 65,536-byte laptop update (synthetic bytes) ----
    let upd1: Vec<u8> = (0..65536usize).map(|i| ((i * 37 + (i >> 8)) & 0xFF) as u8).collect();
    let mut upd2 = upd1.clone(); upd2[65535] = 1; // the next release: last byte changed
    let (d, k) = (512_377i64, 90_210i64); // private key; nonce (must be fresh each time)
    let q = mul(d, Some(G));
    let (z1, z2) = (z_of(&upd1), z_of(&upd2));
    println!("public key Q = dG = {}", sp(q));
    println!("update 1: 65,536 bytes; h(update 1) starts {} -> z1 = {}", &hex(&sha256(&upd1))[..16], z1);
    assert!(z1 == i64::from_str_radix(&hex(&sha256(&upd1))[..5], 16).unwrap()); // leftmost 20 bits = first 5 hex digits
    let (r1, s1) = sign(d, k, &upd1);
    println!("kG = {}, r = {}, 1/k mod n = {}, z1 + r d mod n = {}, s = {}", sp(mul(k, Some(G))), r1, inv(k, N), md(z1 + r1 * d, N), s1);
    let w = inv(s1, N); let (u1, u2) = (z1 * w % N, r1 * w % N);
    println!("verify: w = {}, u1 = {}, u2 = {}, u1G + u2Q = {}", w, u1, u2, sp(add(mul(u1, Some(G)), mul(u2, q))));
    assert!(add(mul(u1, Some(G)), mul(u2, q)) == mul(k, Some(G)) && verify(q, &upd1, (r1, s1)));
    let mut bad = upd1.clone(); bad[1000] ^= 1;
    println!("one bit flipped in byte 1000: z = {} verifies: {}", z_of(&bad), if verify(q, &bad, (r1, s1)) { "True" } else { "False" });
    assert!(!verify(q, &bad, (r1, s1)));
    // ---- what breaks: the same nonce for two updates ----
    let (r2, s2) = sign(d, k, &upd2);
    println!("update 2 with the same nonce: z2 = {}, r = {}, s = {}", z2, r2, s2);
    println!("s1 - s2 = {}, z1 - z2 = {} (mod n)", md(s1 - s2, N), md(z1 - z2, N));
    let k_found = md(z1 - z2, N) * inv(md(s1 - s2, N), N) % N;
    let d_found = md(s1 * k_found - z1, N) * inv(r1, N) % N;
    println!("recovered nonce k = {}, recovered key d = {}", k_found, d_found);
    assert!(r2 == r1 && k_found == k && d_found == d);
    let (mut x, mut steps) = (Some(G), 1i64); // road 2: brute-force discrete log, one add per step
    while x != q { x = add(x, Some(G)); steps += 1; }
    println!("brute force: walked G, 2G, 3G, ... and met Q = {} G after {} additions (average about n/2 = {})", commas(steps), commas(steps - 1), commas(N / 2));
    assert!(steps == d_found);
    let evil = b"update 4.2.2: also install remote-access tool";
    let sig_e = sign(d_found, 777, evil); // check: the stolen key signs anything
    println!("forged signature on a new update: ({}, {}) verifies: {}", sig_e.0, sig_e.1, if verify(q, evil, sig_e) { "True" } else { "False" });
    assert!(verify(q, evil, sig_e));
    let s_leak = md(s1 * k - z1, N) * inv(r1, N) % N;
    println!("one signature plus its leaked nonce gives d = {}", s_leak);
    assert!(s_leak == d);
    // ---- what breaks: no hash.  Public key only, a signature on a number nobody chose ----
    let (a, b) = (1234i64, 5678i64);
    let rr = add(mul(a, Some(G)), mul(b, q)).unwrap();
    let r_f = rr.0 % N; let s_f = r_f * inv(b, N) % N; let z_f = a * s_f % N;
    let w = inv(s_f, N);
    let xf = add(mul(z_f * w % N, Some(G)), mul(r_f * w % N, q)).unwrap();
    println!("no hash: a = {}, b = {} give r = {}, s = {} on 'message' {}: verifies {}", a, b, r_f, s_f, z_f, if xf.0 % N == r_f { "True" } else { "False" });
    assert!(xf.0 % N == r_f && z_f != z1);
    // ---- what breaks: a hash cut too short.  A chosen-message attack by birthday collision ----
    let (mut seen, drafts) = (HashMap::<i64, String>::new(), 2048);
    for i in 0..drafts {
        let msg = format!("update 4.2.1 notes, build {}: fix typo in help page", i);
        seen.insert(z_of(msg.as_bytes()), msg);
    }
    let mut j = 0;
    let harm = loop {
        let h = format!("update 4.2.1 notes, build {}: add remote-access tool", j);
        j += 1;
        if seen.contains_key(&z_of(h.as_bytes())) { break h; }
    };
    let benign = seen[&z_of(harm.as_bytes())].clone();
    println!("collision: {} harmless drafts, {} distinct z; {} harmful drafts; z = {}", drafts, seen.len(), j, z_of(harm.as_bytes()));
    println!("  signer signs: {}", benign);
    let sig_b = sign(d, 424_242, benign.as_bytes());
    let ok = verify(q, harm.as_bytes(), sig_b);
    println!("  attacker attaches it to: {} -> verifies: {}", harm, if ok { "True" } else { "False" });
    assert!(ok && harm != benign);
    println!("expected harmful drafts: 2^20 / {} = {:.0}", seen.len(), 1048576.0 / seen.len() as f64);
    println!("real sizes: P-256 with SHA-256, n and digest about 2^256; best known attacks, collision or key, about 2^128 operations");
    println!("ALL CHECKS PASS");
}
