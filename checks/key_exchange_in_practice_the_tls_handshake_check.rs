// The TLS handshake -- the check behind the card.  std only, no crates.  INSECURE TOY SIZES: a 62-bit
// group stands in for X25519, 64-bit RSA for 2048-bit RSA, an HMAC stream for AES-GCM, SplitMix64 for a CSPRNG.
type Bytes = Vec<u8>;
fn iroot(x: u128, k: u32) -> u128 { // largest r with r^k <= x, bit by bit
    (0..=40).rev().fold(0, |r, i| if (r | 1 << i).pow(k) <= x { r | 1 << i } else { r })
}
fn primes() -> Vec<u128> { (2..312u128).filter(|n| (2..*n).all(|d| n % d != 0)).collect() }
fn sha256(msg: &[u8]) -> Bytes {
    let pr = primes(); // SHA-256 constants: square and cube roots of the first primes
    let (mut h, kk): (Vec<u32>, Vec<u32>) = (pr[..8].iter().map(|p| iroot(p << 64, 2) as u32).collect(),
        pr[..64].iter().map(|p| iroot(p << 96, 3) as u32).collect());
    let mut m = [msg, &[0x80u8][..]].concat();
    while m.len() % 64 != 56 { m.push(0); }
    m.extend_from_slice(&(msg.len() as u64 * 8).to_be_bytes());
    for blk in m.chunks(64) {
        let mut w: Vec<u32> = blk.chunks(4).map(|c| u32::from_be_bytes([c[0], c[1], c[2], c[3]])).collect();
        for j in 16..64 {
            let s0 = w[j - 15].rotate_right(7) ^ w[j - 15].rotate_right(18) ^ (w[j - 15] >> 3);
            let s1 = w[j - 2].rotate_right(17) ^ w[j - 2].rotate_right(19) ^ (w[j - 2] >> 10);
            w.push(w[j - 16].wrapping_add(s0).wrapping_add(w[j - 7]).wrapping_add(s1));
        }
        let mut v = h.clone();
        for j in 0..64 {
            let (a, b, c, d, e, f, g, hh) = (v[0], v[1], v[2], v[3], v[4], v[5], v[6], v[7]);
            let t1 = hh.wrapping_add(e.rotate_right(6) ^ e.rotate_right(11) ^ e.rotate_right(25))
                .wrapping_add((e & f) ^ (!e & g)).wrapping_add(kk[j]).wrapping_add(w[j]);
            let t2 = (a.rotate_right(2) ^ a.rotate_right(13) ^ a.rotate_right(22)).wrapping_add((a & b) ^ (a & c) ^ (b & c));
            v = vec![t1.wrapping_add(t2), a, b, c, d.wrapping_add(t1), e, f, g];
        }
        for i in 0..8 { h[i] = h[i].wrapping_add(v[i]); }
    }
    h.iter().flat_map(|x| x.to_be_bytes()).collect()
}
fn hmac(key: &[u8], msg: &[u8]) -> Bytes { // keys here are at most 64 bytes
    let pad = |c: u8| (0..64).map(|i| key.get(i).unwrap_or(&0) ^ c).collect::<Bytes>();
    sha256(&[pad(0x5C), sha256(&[pad(0x36), msg.to_vec()].concat())].concat())
}
fn expand(prk: &[u8], info: &[u8], n: usize) -> Bytes { // HKDF-Expand, RFC 5869
    let (mut t, mut out) = (Bytes::new(), Bytes::new());
    for i in 1..=(n / 32 + 1) { t = hmac(prk, &[&t[..], info, &[i as u8]].concat()); out.extend(&t); }
    out.truncate(n);
    out
}
fn hx(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }
fn mpow(x: u128, mut e: u128, m: u128) -> u128 { let (mut r, mut x) = (1u128, x % m);
    while e > 0 { if e & 1 == 1 { r = r * x % m; } x = x * x % m; e >>= 1; }
    r
}
fn is_prime(n: u128) -> bool { // Miller-Rabin, exact below 3.3 x 10^24
    let pr = &primes()[..12];
    if n < 2 || pr.iter().any(|s| n % s == 0) { return pr.contains(&n); }
    let (s, d) = ((n - 1).trailing_zeros(), (n - 1) >> (n - 1).trailing_zeros()); // n - 1 = d * 2^s, d odd
    pr.iter().all(|&a| mpow(a, d, n) == 1 || (0..s).any(|r| mpow(a, d << r, n) == n - 1))
}
fn inv(a: u128, m: u128) -> u128 { // extended Euclid
    let (mut r0, mut r1, mut s0, mut s1) = (m as i128, (a % m) as i128, 0i128, 1i128);
    while r1 != 0 { let k = r0 / r1; (r0, r1, s0, s1) = (r1, r0 - k * r1, s1, s0 - k * s1); }
    assert!(r0 == 1);
    s0.rem_euclid(m as i128) as u128
}
fn splitmix(s: u64) -> (u64, u64) { // the next 64-bit output after state s
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn rsa(x: u128, y: u128) -> (u128, u128) { // the first primes above x and y
    let (a, b) = ((x..).find(|&i| is_prime(i)).unwrap(), (y..).find(|&i| is_prime(i)).unwrap());
    (a * b, inv(65537, (a - 1) * (b - 1)))
}
fn hnum(data: &[u8], n: u128) -> u128 { sha256(data).iter().fold(0, |r, &x| (r * 256 + x as u128) % n) }
fn sign(d: u128, n: u128, data: &[u8]) -> u128 { mpow(hnum(data, n), d, n) }
fn verify(n: u128, data: &[u8], s: u128) -> bool { mpow(s, 65537, n) == hnum(data, n) }
fn cert(name: &str, n: u128, d_by: u128, n_by: u128) -> (Bytes, u128) {
    let body = format!("subject={};n={};e=65537;issuer=Root", name, n).into_bytes();
    (body.clone(), sign(d_by, n_by, &body)) }
fn check(crt: &(Bytes, u128), t: &[u8], cv: u128, names: bool, n_root: u128) -> &'static str { // the laptop's three checks
    if !verify(n_root, &crt.0, crt.1) { return "rejected: root signature fails"; }
    let body = String::from_utf8(crt.0.clone()).unwrap();
    let f: Vec<(&str, &str)> = body.split(';').map(|x| x.split_once('=').unwrap()).collect();
    if names && f[0].1 != "bank.example" { return "rejected: name is not bank.example"; }
    if verify(f[1].1.parse().unwrap(), &[t, &crt.0[..]].concat(), cv) { "accepted" } else { "rejected: transcript signature fails" }
}
fn b8(x: u128) -> Bytes { (x as u64).to_be_bytes().to_vec() }
fn kdf(z: u128, label: &[u8], t: &[u8]) -> Bytes { expand(&hmac(&[0u8; 32], &b8(z)), &[label, &sha256(t)[..]].concat(), 32) }
fn stream(k: &[u8], m: &[u8]) -> Bytes { m.iter().zip(expand(k, b"stream", m.len())).map(|(x, y)| x ^ y).collect() }
fn seal(k: &[u8], m: &[u8]) -> Bytes { let c = stream(k, m); [&c[..], &hmac(k, &[b"tag", &c[..]].concat())[..16]].concat() } // the DEM, with a tag
fn unseal(k: &[u8], ct: &[u8]) -> Option<Bytes> { let (c, tag) = ct.split_at(ct.len() - 16);
    if hmac(k, &[b"tag", c].concat())[..16] == *tag { Some(stream(k, c)) } else { None }
}
fn txt(b: Option<Bytes>) -> String { String::from_utf8(b.unwrap()).unwrap() }
fn main() {
    assert_eq!(hx(&sha256(b"abc")), "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad");
    assert_eq!(hx(&expand(&hmac(&(0..13).collect::<Bytes>(), &[0x0b; 22]), &(0xF0..0xFA).collect::<Bytes>(), 42)),
        "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865");
    println!("SHA-256 'abc' vector and RFC 5869 HKDF test 1: both match");
    let mut q: u128 = 1 << 60; // the group: p = 2q + 1, both prime
    while !(is_prime(q) && is_prime(2 * q + 1)) { q += 1; }
    let (p, g) = (2 * q + 1, 4u128); // g = 2^2 lies in the order-q subgroup
    assert!(mpow(g, q, p) == 1);
    println!("group: p = {} ({} bits), g = {}, order q = {}", p, 128 - p.leading_zeros(), g, q);
    let (n_r, d_r) = rsa(3_000_000_000, 3_500_000_000); // the root, in the laptop's trust store
    let (n_b, d_b) = rsa(2_500_000_000, 2_800_000_000); // the bank's long-term signing key
    let (n_x, d_x) = rsa(2_600_000_000, 3_200_000_000); // the attacker's own key
    let party = |seed: u64| -> (Bytes, u128, u128) { // a fresh random and a fresh secret exponent
        let (s, rnd) = splitmix(seed); let x = (splitmix(s).1 as u128) % (q - 1) + 1;
        (b8(rnd as u128), x, mpow(g, x, p))
    };
    let hello = |tag: &[u8], r: &[u8], share: u128| [tag, r, &b8(share)[..]].concat();
    let m = b"TRANSFER 750 TO BOB."; // ---- the honest handshake ----
    let (rc, a, aa) = party(0x1A97_0B5E_ED00_2026);
    let (rs, b, bb) = party(0xBA4C_0B5E_ED00_2026);
    let (ch, sh) = (hello(b"CH", &rc, aa), hello(b"SH", &rs, bb));
    let (zc, zs) = (mpow(bb, a, p), mpow(aa, b, p));
    assert!(zc == zs && zs == mpow(g, a * b % q, p)); // both sides, and the exponent road
    let crt = cert("bank.example", n_b, d_r, n_r);
    let chsh = [&ch[..], &sh[..]].concat();
    let cv = sign(d_b, n_b, &[&chsh[..], &crt.0[..]].concat());
    println!("laptop: a = {}, A = {}\nbank:   b = {}, B = {}\nshared: Z = B^a = A^b = {}", a, aa, b, bb, zc);
    println!("bank's n = {}, root's signature = {}, CertificateVerify = {}", n_b, crt.1, cv);
    let verdict = check(&crt, &chsh, cv, true, n_r); println!("laptop's verdict: {}", verdict);
    let (t, td) = ([&chsh[..], &crt.0[..], &b8(cv)[..]].concat(), [&[ch[0] ^ 1][..], &ch[1..], &sh[..], &crt.0[..], &b8(cv)[..]].concat()); // td: one ClientHello bit changed
    let (fin, fin_d) = (hmac(&kdf(zs, b"s fin", &t), &sha256(&t)), hmac(&kdf(zs, b"s fin", &td), &sha256(&td))); // the bank's Finished
    let tf = [&t[..], &fin[..]].concat();
    let (kc, kb) = (kdf(zc, b"c app", &tf), kdf(zs, b"c app", &tf));
    assert!(verdict == "accepted" && fin_d != fin && kdf(zs, b"c app", &[&td[..], &fin_d[..]].concat()) != kc); // Finished and K follow T
    let ct = seal(&kc, m);
    println!("K starts {}; order on the wire: {}..., {} bytes = {} of order + {} of tag", hx(&kc[..8]), hx(&ct[..8]), ct.len(), m.len(), ct.len() - m.len());
    let bad: Bytes = ct.iter().enumerate().map(|(i, &c)| if i == 3 { c ^ 1 } else { c }).collect();
    assert!(unseal(&kb, &ct).unwrap() == m && unseal(&kb, &bad).is_none());
    println!("bank opens: {} | one bit flipped on the wire: rejected", txt(unseal(&kb, &ct)));
    println!("one ClientHello bit changed in transit: the bank's Finished starts {}, not {}; K changes too", hx(&fin_d[..4]), hx(&fin[..4]));
    let (_, x, xx) = party(0xE7E_2026); // ---- a man in the middle, secret x ----
    let (chx, shx) = (hello(b"CH", &rc, xx), hello(b"SH", &rs, xx)); // what the bank and the laptop now see
    let (tl, tb) = ([&ch[..], &shx[..]].concat(), [&chx[..], &sh[..]].concat()); // the laptop's view, the bank's
    let read = txt(unseal(&kdf(mpow(aa, x, p), b"c app", &tl), &seal(&kdf(mpow(xx, a, p), b"c app", &tl), m)));
    let fwd = seal(&kdf(mpow(bb, x, p), b"c app", &tb), b"TRANSFER 950 TO EVE.");
    println!("no certificate: attacker reads {} | bank receives {}", read, txt(unseal(&kdf(mpow(xx, b, p), b"c app", &tb), &fwd)));
    assert!(read.as_bytes() == m);
    let evil = cert("evil.example", n_x, d_r, n_r); // a real certificate, for the wrong name
    let fake = cert("bank.example", n_x, d_x, n_x); // made by the attacker, not the root
    let with = |c: &(Bytes, u128)| [&tl[..], &c.0[..]].concat();
    let tries = [("relay the bank's signature", &crt, sign(d_b, n_b, &[&tb[..], &crt.0[..]].concat())),
        ("sign with his own key", &crt, sign(d_x, n_x, &with(&crt))),
        ("real certificate for evil.example", &evil, sign(d_x, n_x, &with(&evil))),
        ("self-made certificate", &fake, sign(d_x, n_x, &with(&fake)))];
    for (name, c, s) in tries.iter() {
        let v = check(c, &tl, *s, true, n_r);
        println!("  {}: {}", name, v);
        assert!(v != "accepted");
    }
    let lax = check(&evil, &tl, sign(d_x, n_x, &with(&evil)), false, n_r);
    println!("  evil.example with the name check skipped: {}", lax);
    assert!(lax == "accepted");
    let pm = splitmix(7).1 as u128 % n_b; // ---- the bank's key d leaks later ----
    let e = mpow(pm, 65537, n_b); // old style: RSA carries the laptop's secret
    let old = seal(&kdf(pm, b"c app", &chsh), m);
    println!("RSA key transport, recorded, d leaked: {}", txt(unseal(&kdf(mpow(e, d_b, n_b), b"c app", &chsh), &old)));
    assert!(mpow(e, d_b, n_b) == pm);
    let stolen = check(&crt, &tl, sign(d_b, n_b, &with(&crt)), true, n_r);
    println!("ephemeral DH, d leaked: a new session in the middle is {}", stolen);
    assert!(stolen == "accepted");
    println!("the recorded session needs Z from A and B alone: about 2^{} generic steps here (index calculus needs fewer), 2^126 for X25519", 127 - iroot(q, 2).leading_zeros());
    let pid = 23451; let (_, _, a_bad) = party(pid); // ---- a predictable seed ----
    let seed = (0..32768u64).find(|&s| party(s).2 == a_bad).unwrap();
    println!("seed from a process number, {} bits, not 128: found in {} of 32768 tries, a = {}", 32768u32.trailing_zeros(), seed + 1, party(seed).1);
    assert!(seed == pid && mpow(bb, party(seed).1, p) == mpow(a_bad, b, p)); // attacker's Z = the bank's Z
    println!("figure, arrows at y = 62, 102, 142, 182, 222 on a 360 x 250 panel (schematic)");
    println!("ALL CHECKS PASS");
}
