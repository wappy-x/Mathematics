// SHA-3 and ChaCha20-Poly1305 -- the check behind the card.  std only, no crates: Keccak-f[1600], the sponge,
// ChaCha20, Poly1305 (26-bit limbs modulo 2^130 - 5) and the AEAD are written out.  Toy sizes are insecure on purpose.
use std::{collections::HashMap, f64::consts::PI};
static mut PERMS: u64 = 0; // permutations run: the unit of cost
fn round_constants() -> [u64; 24] { // FIPS 202's 8-bit LFSR
    let (mut rc, mut r) = ([0u64; 24], 1u32);
    for i in 0..24 { for j in 0..7 { r = ((r << 1) ^ ((r >> 7) * 0x71)) & 0xFF; rc[i] |= ((r >> 1 & 1) as u64) << ((1 << j) - 1); } } rc
}
type St = [[u64; 5]; 5]; // A[x][y]: 25 lanes of 64 bits
fn keccak_f(mut a: St, rc: &[u64; 24]) -> St {
    unsafe { PERMS += 1; }
    for &k in rc.iter() {
        let c: Vec<u64> = (0..5).map(|x| a[x][0] ^ a[x][1] ^ a[x][2] ^ a[x][3] ^ a[x][4]).collect();
        for x in 0..5 { let d = c[(x + 4) % 5] ^ c[(x + 1) % 5].rotate_left(1); for y in 0..5 { a[x][y] ^= d; } } // theta
        let (mut x, mut y, mut cur) = (1usize, 0usize, a[1][0]);
        for t in 0..24 { // rho and pi: offsets (t+1)(t+2)/2
            let nx = y; y = (2 * x + 3 * y) % 5; x = nx; let tmp = a[x][y]; a[x][y] = cur.rotate_left(((t + 1) * (t + 2) / 2 % 64) as u32); cur = tmp;
        }
        let b = a; for x in 0..5 { for y in 0..5 { a[x][y] = b[x][y] ^ (!b[(x + 1) % 5][y] & b[(x + 2) % 5][y]); } } // chi
        a[0][0] ^= k; // iota
    }
    a
}
fn absorb(mut a: St, blk: &[u8], rc: &[u64; 24]) -> St { // XOR a block into the rate part, then permute
    for (i, w) in blk.chunks(8).enumerate() { let mut v = [0u8; 8]; v[..w.len()].copy_from_slice(w); a[i % 5][i / 5] ^= u64::from_le_bytes(v); } keccak_f(a, rc)
}
fn state_bytes(a: &St) -> Vec<u8> { (0..25).flat_map(|i| a[i % 5][i / 5].to_le_bytes()).collect() }
fn sponge(m: &[u8], rate: usize, zero_pad: bool, rc: &[u64; 24]) -> Vec<u8> { // capacity = 200 - rate; 32 bytes out
    let mut m = m.to_vec(); if zero_pad { m.resize(m.len() + (rate - m.len() % rate) % rate, 0); } // the broken padding
    else { m.push(0x06); m.resize(m.len() + (rate - m.len() % rate) % rate, 0); *m.last_mut().unwrap() |= 0x80; }
    let mut a = [[0u64; 5]; 5]; for blk in m.chunks(rate) { a = absorb(a, blk, rc); } state_bytes(&a)[..32].to_vec()
}
fn hex(b: &[u8]) -> String { b.iter().map(|x| format!("{:02x}", x)).collect() }
fn ljust(mut v: Vec<u8>, n: usize) -> Vec<u8> { v.resize(n.max(v.len()), b'.'); v }
fn inner_hunt(cap: usize, label: &str, rc: &[u64; 24]) -> (usize, (Vec<u8>, Vec<u8>), (Vec<u8>, Vec<u8>)) {
    let (rate, mut seen) = (200 - cap, HashMap::<Vec<u8>, (Vec<u8>, Vec<u8>)>::new());
    for i in 0.. {
        let blk = ljust(format!("{} #{}", label, i).into_bytes(), rate); let s = state_bytes(&absorb([[0; 5]; 5], &blk, rc));
        if let Some(p) = seen.get(&s[rate..]) { return (i + 1, p.clone(), (blk, s)); } seen.insert(s[rate..].to_vec(), (blk, s));
    }
    unreachable!()
}
fn exact_mean(d: f64) -> f64 { let (mut s, mut p, mut k) = (0.0, 1.0, 0.0); while p > 1e-18 { s += p; p *= 1.0 - k / d; k += 1.0; } s }
fn qr(a: u32, b: u32, c: u32, d: u32, trace: &mut Vec<String>) -> [u32; 4] { // add word j into i, xor i into k, rotate k left by n
    let mut v = [a, b, c, d];
    for (i, j, k, n) in [(0, 1, 3, 16), (2, 3, 1, 12), (0, 1, 3, 8), (2, 3, 1, 7)] { v[i] = v[i].wrapping_add(v[j]); v[k] = (v[k] ^ v[i]).rotate_left(n); trace.push(format!("{:08x} {:08x}", v[i], v[k])); }
    v
}
fn qr_inv(mut a: u32, mut b: u32, mut c: u32, mut d: u32) -> [u32; 4] { // every step undone, in reverse order
    b = b.rotate_left(25) ^ c; c = c.wrapping_sub(d); d = d.rotate_left(24) ^ a; a = a.wrapping_sub(b);
    b = b.rotate_left(20) ^ c; c = c.wrapping_sub(d); d = d.rotate_left(16) ^ a; a = a.wrapping_sub(b); [a, b, c, d]
}
const IDX: [[usize; 4]; 8] = [[0, 4, 8, 12], [1, 5, 9, 13], [2, 6, 10, 14], [3, 7, 11, 15], [0, 5, 10, 15], [1, 6, 11, 12], [2, 7, 8, 13], [3, 4, 9, 14]];
fn rounds(s: &[u32], n: usize, inv: bool) -> Vec<u32> { // odd rounds use columns, even rounds diagonals
    let mut s = s.to_vec(); let order: Vec<usize> = if inv { (0..n).rev().collect() } else { (0..n).collect() };
    for r in order {
        let mut qs: Vec<[usize; 4]> = IDX[4 * (r % 2)..4 * (r % 2) + 4].to_vec(); if inv { qs.reverse(); }
        for q in qs { let v = if inv { qr_inv(s[q[0]], s[q[1]], s[q[2]], s[q[3]]) } else { qr(s[q[0]], s[q[1]], s[q[2]], s[q[3]], &mut vec![]) }; for j in 0..4 { s[q[j]] = v[j]; } }
    }
    s
}
fn words(b: &[u8]) -> Vec<u32> { b.chunks(4).map(|w| u32::from_le_bytes(w.try_into().unwrap())).collect() }
fn setup(key: &[u8], ctr: u32, nonce: &[u8]) -> Vec<u32> { [words(b"expand 32-byte k"), words(key), vec![ctr], words(nonce)].concat() }
fn block(key: &[u8], ctr: u32, nonce: &[u8]) -> Vec<u8> {
    let s = setup(key, ctr, nonce); rounds(&s, 20, false).iter().zip(&s).flat_map(|(x, y)| x.wrapping_add(*y).to_le_bytes()).collect()
}
fn chacha20(key: &[u8], ctr: u32, nonce: &[u8], data: &[u8]) -> Vec<u8> { // keystream blocks ctr, ctr+1, ... XORed onto the data
    let ks: Vec<u8> = (0..(data.len() + 63) / 64).flat_map(|i| block(key, ctr + i as u32, nonce)).collect(); data.iter().zip(&ks).map(|(x, y)| x ^ y).collect()
}
type Fe = [u128; 5]; // a number modulo p = 2^130 - 5, as five 26-bit limbs
const MK: u128 = (1 << 26) - 1;
const CL: u128 = 0x0ffffffc0ffffffc0ffffffc0fffffff;
fn carry(mut h: Fe) -> Fe { while h.iter().any(|&x| x > MK) { for i in 0..5 { let c = h[i] >> 26; h[i] &= MK; if i < 4 { h[i + 1] += c; } else { h[0] += 5 * c; } } } h }
fn fe(lo: u128, top: u128) -> Fe { carry([lo & MK, lo >> 26 & MK, lo >> 52 & MK, lo >> 78 & MK, (lo >> 104) | (top << 24)]) }
fn add(a: Fe, b: Fe) -> Fe { carry(std::array::from_fn(|i| a[i] + b[i])) }
fn sub(a: Fe, b: Fe) -> Fe { let p4 = [4 * (MK - 4), 4 * MK, 4 * MK, 4 * MK, 4 * MK]; carry(std::array::from_fn(|i| a[i] + p4[i] - b[i])) }
fn mul(a: Fe, b: Fe) -> Fe { carry(std::array::from_fn(|i| (0..5).map(|j| if j <= i { a[j] * b[i - j] } else { 5 * a[j] * b[i + 5 - j] }).sum())) }
fn canon(h: Fe) -> (u128, u128) { // fully reduced: (low 128 bits, top 2 bits)
    let mut g = carry(h); g[0] += 5; for i in 0..4 { let c = g[i] >> 26; g[i] &= MK; g[i + 1] += c; }
    let h = if g[4] > MK { g[4] &= MK; g } else { carry(h) }; (h[0] | h[1] << 26 | h[2] << 52 | h[3] << 78 | h[4] << 104, h[4] >> 24)
}
fn chunks(m: &[u8]) -> Vec<Fe> { m.chunks(16).map(|c| { let mut b = c.to_vec(); b.resize(16, 0); let lo = u128::from_le_bytes(b.try_into().unwrap());
    if c.len() == 16 { fe(lo, 1) } else { fe(lo | 1 << (8 * c.len()), 0) } }).collect() }
fn rs(key: &[u8]) -> (u128, u128) { (u128::from_le_bytes(key[..16].try_into().unwrap()) & CL, u128::from_le_bytes(key[16..32].try_into().unwrap())) }
fn poly1305(key: &[u8], m: &[u8]) -> Vec<u8> { // road 1: Horner, as specified
    let ((r, s), mut acc) = (rs(key), fe(0, 0));
    for c in chunks(m) { acc = mul(add(acc, c), fe(r, 0)); } canon(acc).0.wrapping_add(s).to_le_bytes().to_vec()
}
fn poly_sum(key: &[u8], m: &[u8]) -> Vec<u8> { // road 2: sum of c_i times r^(q-i+1)
    let ((r, s), mut tot, mut rp) = (rs(key), fe(0, 0), fe(1, 0));
    for c in chunks(m).into_iter().rev() { rp = mul(rp, fe(r, 0)); tot = add(tot, mul(c, rp)); } canon(tot).0.wrapping_add(s).to_le_bytes().to_vec()
}
fn inv(mut x: Fe) -> Fe { let mut y = fe(1, 0); for i in 0..130 { if i != 1 && i != 2 { y = mul(y, x); } x = mul(x, x); } y } // x^(p-2), p-2 = 2^130-7
fn aead_tag(key: &[u8], nonce: &[u8], aad: &[u8], ct: &[u8]) -> Vec<u8> { // Poly1305 key = first 32 bytes of ChaCha20 block 0
    let z = |n: usize| vec![0u8; (16 - n % 16) % 16];
    let mac = [aad.to_vec(), z(aad.len()), ct.to_vec(), z(ct.len()), (aad.len() as u64).to_le_bytes().to_vec(), (ct.len() as u64).to_le_bytes().to_vec()].concat(); poly1305(&block(key, 0, nonce)[..32], &mac)
}
fn unhex(s: &str) -> Vec<u8> { (0..s.len()).step_by(2).map(|i| u8::from_str_radix(&s[i..i + 2], 16).unwrap()).collect() }
fn main() {
    let rc = round_constants();
    println!("== SHA3-256: the FIPS 202 sponge, against NIST's worked examples ==\nwidth 1600 bits, rate R = {}, capacity C = {}, block 136 bytes, {} rounds; RC[0] = {:016x}  RC[23] = {:016x}", 136 * 8, 1600 - 136 * 8, rc.len(), rc[0], rc[23]); assert!(rc[0] == 1 && rc[23] == 0x8000000080008008, "LFSR round constants against the iota steps of rounds 0 and 23 in NIST's example");
    unsafe { PERMS = 0; } let e = hex(&sponge(b"", 136, false, &rc)); println!("h('') = {}  ({} permutation)", e, unsafe { PERMS });
    assert!(e == "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", "NIST example: the 0-bit message"); assert!(hex(&sponge(&[0xa3; 200], 136, false, &rc)) == "79f38adec5c20307a98ef76e8324afbfd46cfd81b22e3973c65fa1bd9de31787", "NIST example: the 1600-bit message, two blocks");
    let order: &[u8] = b"from=laptop&pay=250000.00&to=12345678";
    println!("order, {} bytes: h = {}\nbits shown 256, bits kept hidden {}; collision 2^{}, preimage 2^{}", order.len(), hex(&sponge(order, 136, false, &rc)), 1600 - 256, 256 / 2, (512 / 2).min(256));
    let (z1, z2) = (sponge(b"abc", 136, true, &rc), sponge(b"abc\0", 136, true, &rc)); println!("zero padding: h(abc) = {}...  h(abc+00) = {}...  equal: {}", &hex(&z1)[..16], &hex(&z2)[..16], if z1 == z2 { "True" } else { "False" });
    assert!(z1 == z2 && sponge(b"abc", 136, false, &rc) != sponge(b"abc\0", 136, false, &rc), "zero padding merges messages");
    println!("== capacity sets the security: inner collisions (toy capacities, insecure) ==");
    let t: Vec<f64> = (0..40).map(|run| inner_hunt(2, &format!("order {}", run), &rc).0 as f64).collect(); let m = t.iter().sum::<f64>() / 40.0; let se = (t.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / 39.0 / 40.0).sqrt();
    println!("C=16 bits, 40 hunts: mean tries {:.2} (se {:.2}), exact {:.2}, sqrt(pi/2 2^16) {:.2}", m, se, exact_mean(65536.0), (PI / 2.0 * 65536.0).sqrt());
    assert!((m - exact_mean(65536.0)).abs() < 4.0 * se, "inner collisions arrive at the birthday count for c bits");
    let (tries, (b1, s1), (b2, s2)) = inner_hunt(3, "pay GBP 250,000 to account 12345678", &rc);
    let x = ljust(b"&memo=rent".to_vec(), 197); // second block; the other message cancels the rate difference
    let (m1, m2) = ([b1, x.clone()].concat(), [b2, (0..197).map(|i| x[i] ^ s1[i] ^ s2[i]).collect()].concat()); let (h1, h2) = (sponge(&m1, 197, false, &rc), sponge(&m2, 197, false, &rc));
    println!("C=24 bits: inner collision after {} tries; two {}-byte messages, 256-bit outputs\n  h1 = {}\n  h2 = {}  equal: {}", tries, m1.len(), hex(&h1), hex(&h2), if h1 == h2 { "True" } else { "False" });
    assert!(h1 == h2 && m1 != m2, "full collision from an inner collision");
    println!("== ChaCha20: add, rotate, xor, against RFC 8439 ==");
    let (qin, mut tr) = ([0x11111111u32, 0x01020304, 0x9b8d6f43, 0x01234567], vec![]); let qout = qr(qin[0], qin[1], qin[2], qin[3], &mut tr); println!("steps: {}", tr.join(" | "));
    let f8 = |v: &[u32]| v.iter().map(|x| format!("{:08x}", x)).collect::<Vec<_>>().join(" "); println!("quarter round: {} -> {}", f8(&qin), f8(&qout));
    assert!(qout == [0xea2a92f4, 0xcb1cf8ce, 0x4581472e, 0x5881c4bb], "RFC 8439 2.1.1 quarter-round vector");
    let back_q = qr_inv(qout[0], qout[1], qout[2], qout[3]); println!("inverse quarter round returns {}", f8(&back_q)); assert!(back_q == qin, "undone exactly");
    let (k, nonce): (Vec<u8>, Vec<u8>) = ((0..32).collect(), unhex("000000090000004a00000000"));
    let blk = hex(&block(&k, 1, &nonce)); println!("block, counter 1: {}...{}", &blk[..32], &blk[blk.len() - 16..]);
    assert!(blk == "10f1e7e4d13b5915500fdd1fa32071c4c7d1f4c733c068030422aa9ac3d46c4ed2826446079faa0914c2d705d98b02a2b5129cd1de164eb9cbd083e8a2503c4e", "RFC 8439 2.3.2");
    println!("diffusion: flip each of the 256 key bits, bits of the 512-bit state that change");
    let (base, mut spread) = (setup(&k, 1, &nonce), vec![]); for n in 1..9 {
        let f: Vec<u32> = (0..256).map(|i| { let mut s = base.clone(); s[4 + i / 32] ^= 1 << (i % 32);
            rounds(&base, n, false).iter().zip(rounds(&s, n, false)).map(|(x, y)| (x ^ y).count_ones()).sum() }).collect();
        spread.push(f.iter().sum::<u32>() as f64 / 256.0); println!("  rounds {}: mean {:6.2}, min {:3}", n, spread[n - 1], f.iter().min().unwrap());
    }
    assert!(spread[0] < 50.0 && (spread[7] - 256.0).abs() < 4.0 * 128f64.sqrt() / 16.0, "one round barely mixes; eight look random");
    println!("figure,rounds,{}", spread.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(","));
    let back = rounds(&rounds(&setup(&k, 1, &nonce), 20, false), 20, true); // the block WITHOUT the final addition, inverted
    println!("no final addition: inverting 20 rounds gives key {}", hex(&back[4..12].iter().flat_map(|x| x.to_le_bytes()).collect::<Vec<u8>>())); assert!(back[4..12] == words(&k)[..], "without the final addition the key comes straight back");
    println!("== Poly1305: a polynomial in r modulo p = 2^130 - 5 ==");
    let (pk, pm) = (unhex("85d6be7857556d337f4452fe42d506a80103808afb0db2fd4abff6af4149f51b"), b"Cryptographic Forum Research Group");
    let tag = hex(&poly1305(&pk, pm)); println!("RFC 8439 2.5.2 tag {}, sum-of-powers road {}", tag, hex(&poly_sum(&pk, pm)));
    assert!(tag == "a8061dc1305136c6c22b8baf0c0127a9" && hex(&poly_sum(&pk, pm)) == tag, "Poly1305 vector, two roads");
    let l = order.len() + (16 - order.len() % 16) % 16 + 16; println!("clamped r: {} free bits; order's MAC input {} bytes, forgery chance <= {}/2^106 = 1 in 2^{}", CL.count_ones(), l, 8 * (l / 16), 106 - ((8 * (l / 16)) as f64).log2().round() as i64);
    let aead = |key: &[u8], nonce: &[u8], aad: &[u8], pt: &[u8]| { let ct = chacha20(key, 1, nonce, pt); let t = aead_tag(key, nonce, aad, &ct); (ct, t) };
    let pt = b"Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";
    let (ct, tg) = aead(&(0x80..0xa0).collect::<Vec<u8>>(), &unhex("070000004041424344454647"), &unhex("50515253c0c1c2c3c4c5c6c7"), pt);
    println!("RFC 8439 2.8.2 AEAD: ciphertext {}... tag {}", hex(&ct[..8]), hex(&tg));
    assert!(hex(&ct[..16]) == "d31a8d34648e60db7b86afbc53ef7ec2" && hex(&tg) == "1ae10b594f09e26a7e902ecbd0600691", "AEAD vector");
    let nb = unhex("000000000000000000000001"); // toy key k above, printed: insecure on purpose
    let (c1, t1) = aead(&k, &nb, b"", order); let mut bad = c1.clone(); bad[0] ^= 1;
    println!("the order: ciphertext {}... tag {}, decrypts back: {}", &hex(&c1)[..24], hex(&t1), if chacha20(&k, 1, &nb, &c1) == order { "True" } else { "False" });
    let tb = aead_tag(&k, &nb, b"", &bad); println!("one bit flipped: decrypts to {}..., tag now {}..., bank {}", String::from_utf8_lossy(&chacha20(&k, 1, &nb, &bad)[..12]), &hex(&tb)[..16], if tb == t1 { "accepts" } else { "rejects" });
    assert!(tb != t1 && chacha20(&k, 1, &nb, &c1) == order, "tag catches a flipped bit");
    println!("== a reused Poly1305 key (what a repeated nonce causes) ==");
    let (otk, a1, a2, a3): (Vec<u8>, &[u8], &[u8], &[u8]) = (block(&k, 0, &nb)[..32].to_vec(), b"PAY GBP 250 #001", b"PAY GBP 120 #002", b"PAY GBP 950 #003");
    let tt = |a: &[u8]| u128::from_le_bytes(poly1305(&otk, a).try_into().unwrap());
    let (t1, t2, cc1, cc2) = (tt(a1), tt(a2), chunks(a1)[0], chunks(a2)[0]);
    let (d, dinv, two128) = (sub(fe(t1, 0), fe(t2, 0)), inv(sub(cc1, cc2)), fe(0, 1)); let mut found = vec![];
    for kk in -4i32..5 { // the mod 2^128 wrap hides a small multiple of 2^128
        let u = if kk >= 0 { add(d, mul(fe(kk as u128, 0), two128)) } else { sub(d, mul(fe((-kk) as u128, 0), two128)) };
        let (r, top) = canon(mul(u, dinv));
        if top == 0 && r & CL == r { found.push((r, t1.wrapping_sub(canon(mul(cc1, fe(r, 0))).0))); }
    }
    let (r, s) = found[0]; let forged = canon(mul(chunks(a3)[0], fe(r, 0))).0.wrapping_add(s);
    println!("candidates tried 9, of the clamped shape {}; r = {:032x}", found.len(), r); println!("forged tag for '{}' = {:032x}; bank's check: {}", String::from_utf8_lossy(a3), forged, if forged == tt(a3) { "accepted" } else { "rejected" });
    assert!(found.len() == 1 && r == rs(&otk).0, "two tags under one key give away r"); assert!(forged == tt(a3), "forgery made without the key");
    println!("ALL CHECKS PASS");
}
