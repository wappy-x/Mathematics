// Hamming (7,4) and Reed-Solomon -- the same check as the Python, in Rust.  No crates.
// A disc track holds the text "CD": two bytes, four nibbles (4-bit halves).  Code A:
// each nibble becomes 7 bits by Hamming (7,4).  Code B: the four nibbles are symbols
// of GF(16), and the disc stores 8 values of the polynomial they define.
type V = Vec<u32>;
fn bits(v: u32, n: u32) -> V { (0..n).map(|i| (v >> (n - 1 - i)) & 1).collect() }
fn mat_vec(m: &[V], v: &[u32]) -> V { m.iter().map(|r| r.iter().zip(v).map(|(a, b)| a * b).sum::<u32>() % 2).collect() }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn g() -> Vec<V> { vec![vec![1, 1, 0, 1], vec![1, 0, 1, 1], vec![1, 0, 0, 0], vec![0, 1, 1, 1],
                        vec![0, 1, 0, 0], vec![0, 0, 1, 0], vec![0, 0, 0, 1]] }   // chk1 chk2 m1 chk4 m2 m3 m4
fn h() -> Vec<V> { (0..3).map(|k| (1..8).map(|j| (j >> k) & 1).collect()).collect() } // column j is j in binary
fn ham_enc(n: u32) -> V { mat_vec(&g(), &bits(n, 4)) }
fn syndrome(r: &[u32]) -> u32 { let s = mat_vec(&h(), r); s[0] + 2 * s[1] + 4 * s[2] }
fn ham_dec(r: &[u32]) -> (u32, u32) {                          // road 1: the syndrome
    let mut r = r.to_vec(); let s = syndrome(&r);
    if s > 0 { r[s as usize - 1] ^= 1; }
    (8 * r[2] + 4 * r[4] + 2 * r[5] + r[6], s)
}
fn dist(a: &[u32], b: &[u32]) -> usize { a.iter().zip(b).filter(|(x, y)| x != y).count() }
fn flip(w: &[u32], places: &[usize]) -> V { w.iter().enumerate().map(|(i, b)| b ^ places.contains(&(i + 1)) as u32).collect() }
fn gmul(mut a: u32, mut b: u32) -> u32 {      // GF(16): shift and add, wrap by x^4 + x + 1
    let mut p = 0;
    for _ in 0..4 {
        if b & 1 == 1 { p ^= a; }
        b >>= 1; a <<= 1;
        if a & 16 != 0 { a ^= 0b10011; }
    }
    p
}
fn ginv(a: u32) -> u32 { (1..16).find(|&b| gmul(a, b) == 1).unwrap() }
fn peval(c: &[u32], x: u32, modular: bool) -> u32 {           // Horner's rule
    let mut y = 0;
    for &co in c.iter().rev() { y = if modular { (y * x + co) % 16 } else { gmul(y, x) ^ co }; }
    y
}
fn rs_enc(m: &[u32], pts: &[u32]) -> V { pts.iter().map(|&x| peval(m, x, false)).collect() }
fn interp(xs: &[u32], ys: &[u32]) -> V {      // the one cubic through 4 points, by Lagrange
    let mut out = vec![0u32; 4];
    for i in 0..4 {
        let (mut num, mut den) = (vec![1u32], 1u32);
        for j in 0..4 {
            if j != i {                           // multiply num by (x + xs[j]); minus is plus here
                num = (0..=num.len()).map(|k| (if k > 0 { num[k - 1] } else { 0 })
                    ^ (if k < num.len() { gmul(num[k], xs[j]) } else { 0 })).collect();
                den = gmul(den, xs[i] ^ xs[j]);
            }
        }
        let f = gmul(ys[i], ginv(den));
        for k in 0..4 { out[k] ^= gmul(f, num[k]); }
    }
    out
}
fn rs_fit(r: &[u32], pts: &[u32]) -> Option<V> {   // road 2: fit every 4 of the 8 values
    for s in 0..256u32 {
        let idx: Vec<usize> = (0..8).filter(|i| s >> i & 1 == 1).collect();
        if idx.len() == 4 {
            let xs: V = idx.iter().map(|&i| pts[i]).collect();
            let ys: V = idx.iter().map(|&i| r[i]).collect();
            let m = interp(&xs, &ys);
            if dist(&rs_enc(&m, pts), r) <= 2 { return Some(m); }
        }
    }
    None
}
fn cut(t: &[u32], w: usize) -> Vec<V> { t.chunks(w).map(|c| c.to_vec()).collect() }
fn show(n: &[u32]) -> String {
    let bs: V = n.chunks(2).map(|p| 16 * p[0] + p[1]).collect();
    let txt: String = bs.iter().map(|&b| if (32..127).contains(&b) { b as u8 as char } else { '?' }).collect();
    format!("{:?} {}", bs, txt)
}
fn join(v: &[u32], sep: &str) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(sep) }
struct Rng(u64);                              // SplitMix64, seed 2026: the same flips as Python
impl Rng { fn next(&mut self) -> f64 {
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }

fn main() {
    let book: Vec<V> = (0..16).map(ham_enc).collect();
    let msg: V = b"CD".iter().flat_map(|&c| [c as u32 >> 4, c as u32 & 15]).collect();
    println!("track text CD = bytes {} = nibbles {:?}", show(&msg), msg);
    println!("nibble 4 = data bits {:?} -> Hamming codeword {:?}", bits(4, 4), ham_enc(4));
    let r = flip(&ham_enc(4), &[6]);
    println!("flip position 6: {:?}; checks (1,3,5,7) (2,3,6,7) (4,5,6,7) = {:?}; syndrome {}", r, mat_vec(&h(), &r), syndrome(&r));
    let mut dmin = 7;
    for a in 0..16 { for b in a + 1..16 { dmin = dmin.min(dist(&book[a], &book[b])); } }
    let words: Vec<V> = book.iter().flat_map(|c| (0..8).map(move |p| flip(c, &[p]))).collect();
    let near = |w: &V| (0..16).min_by_key(|&m| dist(&book[m as usize], w)).unwrap();
    let agree = words.iter().all(|w| ham_dec(w).0 == near(w));
    println!("Hamming: H times every codeword = 0: {}; min distance {}, fixes {}, detects {}",
             yn(book.iter().all(|c| syndrome(c) == 0)), dmin, (dmin - 1) / 2, dmin - 1);
    println!("Hamming: 16 codewords x 8 words within one flip, all different: {} = 2^7; syndrome = nearest on all {}: {}", words.iter().collect::<std::collections::BTreeSet<_>>().len(), words.len(), yn(agree));
    println!("Hamming: flip positions 1, 2, 3 of codeword 4: syndrome {}, a weight-3 codeword", syndrome(&flip(&ham_enc(4), &[1, 2, 3])));
    let track: V = msg.iter().flat_map(|&n| ham_enc(n)).collect();
    println!("Hamming track, 28 bits: {}", join(&track, ""));
    let scars: Vec<(&str, Vec<usize>)> = vec![("speck at bit 6", vec![6]), ("scratch, bits 12-13", vec![12, 13]),
        ("scratch, bits 10-14", vec![10, 11, 12, 13, 14]), ("three symbols, case 1", vec![1, 13, 25]),
        ("three symbols, case 2", vec![1, 6, 25])];
    for (name, places) in &scars[..3] {
        let out: Vec<(u32, u32)> = cut(&flip(&track, places), 7).iter().map(|b| ham_dec(b)).collect();
        let s: V = out.iter().map(|o| o.1).collect();
        let n: V = out.iter().map(|o| o.0).collect();
        println!("  {:<20} syndromes {:?} -> {}", name, s, show(&n));
    }
    let b2 = flip(&track, &[12, 13])[7..14].to_vec();
    let fixed = flip(&b2, &[syndrome(&b2) as usize]);
    println!("  block 2 under the scratch: sent {:?}, read {:?}, 'repaired' to {:?} = nibble {}", &track[7..14], b2, fixed, ham_dec(&b2).0);
    let mut pts = vec![1u32];
    while pts.len() < 8 { let last = *pts.last().unwrap(); pts.push(gmul(last, 2)); }
    let code = rs_enc(&msg, &pts);
    let terms: V = msg.iter().zip([1, 2, 4, 8]).map(|(&c, x)| gmul(c, x)).collect();
    println!("GF(16): points a^0..a^7 = {:?}; 1/a = {}; m(1) = {} = {}; m(a) = {} = {}", pts, ginv(2),
             join(&msg, " + "), code[0], join(&terms, " + "), code[1]);
    println!("RS(8,4): message {:?} -> codeword {:?}, 32 bits", msg, code);
    let all: Vec<V> = (0..1u32 << 16).map(|m| vec![m >> 12, (m >> 8) & 15, (m >> 4) & 15, m & 15]).collect();
    let rsbook: Vec<V> = all.iter().map(|m| rs_enc(m, &pts)).collect();
    let least = rsbook[1..].iter().map(|c| c.iter().filter(|&&v| v != 0).count()).min().unwrap();
    println!("RS: {} codewords; least weight of the {} nonzero ones = {} = 8 - 4 + 1, so fixes 2 symbols", rsbook.len(), rsbook.len() - 1, least);
    let rs_track: V = code.iter().flat_map(|&s| bits(s, 4)).collect();
    let mut found: Vec<(V, Option<V>)> = Vec::new();
    for (name, places) in &scars {
        let got: V = cut(&flip(&rs_track, places), 4).iter().map(|s| s.iter().fold(0, |a, b| 2 * a + b)).collect();
        let ds: Vec<usize> = rsbook.iter().map(|c| dist(c, &got)).collect();   // road 1: nearest of all
        let d = *ds.iter().min().unwrap();
        let first = ds.iter().position(|&x| x == d).unwrap();
        let ties = ds.iter().filter(|&&x| x == d).count();
        let fit = rs_fit(&got, &pts);
        println!("  {:<21} reads {:?}: nearest at {} ({} tied) {}; fit within 2: {}", name, got, d, ties,
                 show(&all[first]), match &fit { None => "none".to_string(), Some(m) => show(m) });
        found.push((all[first].clone(), fit));
    }
    let modbook: Vec<V> = all.iter().map(|m| pts.iter().map(|&x| peval(m, x, true)).collect()).collect();
    let zero: Vec<usize> = (1..1usize << 16).filter(|&i| modbook[i].iter().all(|&v| v == 0)).collect();
    println!("mistake, nibbles as hours mod 16: message {:?} also writes {:?}; {} such messages", all[zero[0]], modbook[0], zero.len());

    let mut rng = Rng(2026);
    let (p, trials) = (0.01f64, 200000u32);
    let mut wrong = 0u32;
    for t in 0..trials {
        let got: V = ham_enc(t % 16).iter().map(|b| b ^ (rng.next() < p) as u32).collect();
        if ham_dec(&got).0 != t % 16 { wrong += 1; }
    }
    let fail = 1.0 - (1.0 - p).powi(7) - 7.0 * p * (1.0 - p).powi(6);
    let se = (fail * (1.0 - fail) / trials as f64).sqrt();
    let rate = wrong as f64 / trials as f64;
    println!("flip chance {}: raw nibble wrong {:.6}; Hamming block wrong {:.6} by formula, {:.6} in {} blocks",
             p, 1.0 - (1.0 - p).powi(4), fail, rate, trials);
    println!("rate 4/7 = {:.4}; capacity at p = {} is {:.4}; CD: C1 RS(32,28) and C2 RS(28,24) have distance {} and {}, fix {} each",
             4.0 / 7.0, p, 1.0 + p * p.log2() + (1.0 - p) * (1.0 - p).log2(), 32 - 28 + 1, 28 - 24 + 1, (32 - 28) / 2);
    let block_fail = |q: f64| 1.0 - (1.0 - q).powi(7) - 7.0 * q * (1.0 - q).powi(6);
    println!("try: Hamming block wrong at flip chance 0.001 is {:.6}, at 0.1 is {:.6}", block_fail(0.001), block_fail(0.1));
    let s916: Vec<usize> = (9..17).collect();
    let got: V = cut(&flip(&rs_track, &s916), 4).iter().map(|s| s.iter().fold(0, |a, b| 2 * a + b)).collect();
    let hn: V = cut(&flip(&track, &s916), 7).iter().map(|b| ham_dec(b).0).collect();
    let ds: Vec<usize> = rsbook.iter().map(|c| dist(c, &got)).collect();
    let first = ds.iter().position(|&x| x == *ds.iter().min().unwrap()).unwrap();
    println!("try: scratch, bits 9-16: Hamming reads {}; RS nearest {}, fit {}", show(&hn), show(&all[first]), show(&rs_fit(&got, &pts).unwrap()));

    assert!(dmin == 3 && agree);                                   // exhaustive vs syndrome
    assert!(words.iter().collect::<std::collections::BTreeSet<_>>().len() == 1 << 7);   // the 16 balls fill all 7-bit words
    let back: V = cut(&flip(&track, &[6]), 7).iter().map(|b| ham_dec(b).0).collect();
    assert!(back == msg);
    assert!(least == 8 - 4 + 1);                                   // exhaustive vs n - k + 1
    for f in &found[..3] { assert!(f.0 == msg && f.1.as_ref() == Some(&msg)); }   // two decoders
    assert!(found[3].1.is_none() && found[4].1.is_some() && found[4].1.as_ref() != Some(&msg));
    assert!((rate - fail).abs() < 4.0 * se);                       // simulation vs formula
    println!("ALL CHECKS PASS");
}
