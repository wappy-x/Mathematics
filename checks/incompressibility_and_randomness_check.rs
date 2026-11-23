// Incompressibility and randomness -- the same check as the Python, in Rust.  No
// crates.  Four roads: count descriptions by a sum and by a closed form; run a tiny
// decompressor D on every 16-bit file; zip a text twice with LZ78, written out below
// (the Lempel-Ziv card explains it); price lopsided strings.
use std::collections::HashMap;

struct SplitMix64 { s: u64 }                       // small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn blen(v: usize) -> usize { (usize::BITS - v.leading_zeros()) as usize }

fn lz78_pack(data: &[u8]) -> Vec<u8> {             // 32-bit length, then (index, byte) pairs
    let mut bits: Vec<u8> = Vec::new();
    let put = |bits: &mut Vec<u8>, v: usize, k: usize| for j in 0..k { bits.push(((v >> (k - 1 - j)) & 1) as u8) };
    let mut book: HashMap<Vec<u8>, usize> = HashMap::new();
    book.insert(Vec::new(), 0);
    let (mut w, mut i): (Vec<u8>, usize) = (Vec::new(), 1);
    put(&mut bits, data.len(), 32);
    for &b in data {
        let mut wb = w.clone();
        wb.push(b);
        if book.contains_key(&wb) { w = wb; continue; }
        put(&mut bits, book[&w], blen(i - 1));
        put(&mut bits, b as usize, 8);
        book.insert(wb, i);
        w.clear();
        i += 1;
    }
    if !w.is_empty() { put(&mut bits, book[&w], blen(i - 1)); }
    while bits.len() % 8 != 0 { bits.push(0); }
    bits.chunks(8).map(|c| c.iter().fold(0u8, |a, &b| (a << 1) | b)).collect()
}

fn lz78_unpack(blob: &[u8]) -> Vec<u8> {           // the decompressor: a program that reads the packed file
    let mut pos = 0usize;
    let mut get = |k: usize| { let mut v = 0usize; for _ in 0..k {
        v = (v << 1) | ((blob[pos >> 3] >> (7 - (pos & 7))) & 1) as usize; pos += 1; } v };
    let n = get(32);
    let (mut book, mut out, mut i): (Vec<Vec<u8>>, Vec<u8>, usize) = (vec![Vec::new()], Vec::new(), 1);
    while out.len() < n {
        let mut w = book[get(blen(i - 1))].clone();
        if out.len() + w.len() == n { out.extend(&w); break; }
        w.push(get(8) as u8);
        out.extend(&w);
        book.push(w);
        i += 1;
    }
    out
}

fn byte_entropy(data: &[u8]) -> f64 {              // bits per byte if each byte were coded by its own frequency
    let mut f = [0usize; 256];
    for &b in data { f[b as usize] += 1; }
    let n = data.len() as f64;
    -f.iter().filter(|&&c| c > 0).map(|&c| c as f64 / n * (c as f64 / n).log2()).sum::<f64>()
}

fn d(desc: u64, l: u32) -> Option<u64> {           // reads a description of l bits; prints a 16-bit file
    if l == 17 && desc >> 16 == 0 { return Some(desc); }             // 0 then 16 bits: the file written out
    if l >= 4 && desc >> (l - 1) == 1 {                               // 1, two bits for period p, then p bits
        let p = 1u32 << ((desc >> (l - 3)) & 3);
        if l == 3 + p {
            let pat = desc & ((1u64 << p) - 1);
            return Some((0..16 / p).map(|j| pat << (p * j)).sum());
        }
    }
    None                                                              // not a valid description
}

const X0: u64 = 0b0110100110010110;
fn d2(desc: u64, l: u32) -> Option<u64> {          // D with file x0 built in: '1' prints x0, '0' + d runs D
    if l == 1 { return if desc == 1 { Some(X0) } else { None }; }
    if l >= 2 && desc >> (l - 1) == 0 { d(desc, l - 1) } else { None }
}

fn shortest(dec: fn(u64, u32) -> Option<u64>, top: u32) -> Vec<u32> {   // shortest description of each file
    let mut best = vec![u32::MAX; 1 << 16];
    for l in 0..=top { for desc in 0..(1u64 << l) {
        if let Some(x) = dec(desc, l) { if best[x as usize] == u32::MAX { best[x as usize] = l; } }
    } }
    best
}

fn main() {
    let n = 16u32;
    println!("files of {} bits: 2^{} = {}", n, n, 1u64 << n);
    for c in [1u32, 2, 4, 8] {
        let short: u64 = (0..n - c).map(|l| 1u64 << l).sum();
        println!("c = {}: descriptions shorter than {} bits: {} = 2^{} - 1; at least {} files ({:.4}%) need {} bits or more",
            c, n - c, short, n - c, (1u64 << n) - short, 100.0 * (1.0 - short as f64 / (1u64 << n) as f64), n - c);
        assert!(short == (1u64 << (n - c)) - 1);                     // the sum against the closed form
    }
    let m = 8 * 1048576u64;
    println!("a file of 1048576 bytes is {} bits; shrink by more than 8 bits: fewer than 1 file in 2^8 = 256, share < {:.8}; shrink by 1%: share < 2^-{}", m, 1.0 / 256.0, m / 100);
    let best = shortest(d, 17);
    let mut hist: Vec<(u32, usize)> = Vec::new();
    for l in 0..=17u32 { let k = best.iter().filter(|&&b| b == l).count(); if k > 0 { hist.push((l, k)); } }
    println!("D: every one of {} files gets a description; shortest lengths in bits: {:?}", best.iter().filter(|&&b| b != u32::MAX).count(), hist);
    let want: Vec<(u32, usize)> = [1u32, 2, 4, 8].iter().map(|&p| (3 + p, (1usize << p) - (if p > 1 { 1usize << (p / 2) } else { 0 })))
        .chain([(17, (1usize << n) - (1 << 8))]).collect();
    assert!(hist == want);                                           // files by period
    for c in [1u32, 5, 8, 12] {
        let k = best.iter().filter(|&&b| b < n - c).count();
        println!("D: files with a description shorter than {} bits: {}, bound 2^{} - 1 = {}", n - c, k, n - c, (1usize << (n - c)) - 1);
        assert!(k <= (1usize << (n - c)) - 1);                      // brute force under the count
    }
    println!("D: share of 16-bit files that shrink at all: {:.6}", best.iter().filter(|&&b| b < 16).count() as f64 / 65536.0);
    println!("D: file 0101010101010101 (eight 1s, balanced) has shortest description {} bits; file 0110100110010110 has {}", best[0x5555], best[X0 as usize]);
    let best2 = shortest(d2, 18);
    let k2 = best2.iter().filter(|&&b| b < 15).count();
    println!("mistake, file built into the decompressor: x0 now {} bit, 0101010101010101 now {}; shorter than 15 bits: {}, bound 32767", best2[X0 as usize], best2[0x5555], k2);
    assert!(k2 <= (1 << 15) - 1 && best2[0x5555] == best[0x5555] + 1);
    let mut keep8 = [0usize; 256];
    for x in 0..(1usize << 16) { keep8[x >> 8] += 1; }               // a 'compressor' that keeps the first 8 bits
    println!("mistake, keep the first 8 bits: every file shrinks to 8 bits, {} outputs, {} files share each", keep8.iter().filter(|&&v| v > 0).count(), keep8.iter().min().unwrap());

    let words: Vec<&str> = "the a of to and in is it that for on was with as at by this from or be we file data zip code bit byte short long once again table".split(' ').collect();
    let mut rng = SplitMix64 { s: 2026 };
    let text: Vec<u8> = (0..4000).map(|_| words[(rng.next() % words.len() as u64) as usize]).collect::<Vec<_>>().join(" ").into_bytes();
    println!("text: 4000 words drawn from {} by SplitMix64 seed 2026, starting '{}'", words.len(), String::from_utf8_lossy(&text[..40]));
    let gen = format!("w=\"{}\".split()\ns=2026;M=2**64-1;t=[]\nfor _ in range(4000):s=s+0x9E3779B97F4A7C15&M;z=(s^s>>30)*0xBF58476D1CE4E5B9&M;z=(z^z>>27)*0x94D049BB133111EB&M;t.append(w[(z^z>>31)%32])\nprint(\" \".join(t),end=\"\")\n", words.join(" "));
    println!("named program for the text: {} bytes of Python (word list, SplitMix64, seed 2026), so K(text) <= {} bits", gen.len(), 8 * gen.len());
    let (z1, z2, z3) = { let a = lz78_pack(&text); let b = lz78_pack(&a); let c = lz78_pack(&b); (a, b, c) };
    let noise: Vec<u8> = (0..z1.len()).map(|_| (rng.next() & 255) as u8).collect();
    let zn = lz78_pack(&noise);
    for (name, a, b) in [("text -> zip 1", &text, &z1), ("zip 1 -> zip 2", &z1, &z2), ("zip 2 -> zip 3", &z2, &z3), ("coin bytes -> zip", &noise, &zn)] {
        println!("{}: {} bytes -> {} bytes, change {}, ratio {:.4}", name, a.len(), b.len(), b.len() as i64 - a.len() as i64, b.len() as f64 / a.len() as f64);
    }
    let b1 = 8 * z1.len();
    println!("zip 1 is {} bits; any second coder shrinks it by more than 8 bits for a share < 2^-8 of files that size, by 10% for < 2^-{}", b1, b1 / 10);
    println!("byte entropy: text {:.4}, zip 1 {:.4}, zip 2 {:.4}, coin bytes {:.4} bits per byte", byte_entropy(&text), byte_entropy(&z1), byte_entropy(&z2), byte_entropy(&noise));
    println!("a coder using byte frequencies alone could bring zip 1 to about {:.4} of its size", byte_entropy(&z1) / 8.0);
    let ok = lz78_unpack(&z1) == text && lz78_unpack(&lz78_unpack(&z2)) == text && lz78_unpack(&zn) == noise;
    println!("every zip unpacks to its input exactly: {}", if ok { "yes" } else { "no" });
    assert!(ok);                                                     // lossless: the zipped file is a description
    assert!(z1.len() < text.len() / 2 && z2.len() > z1.len() && zn.len() > noise.len());

    let big_n = 1000usize;
    let log2_choose = |k: usize| (0..k).map(|j| ((big_n - j) as f64 / (j + 1) as f64).log2()).sum::<f64>();
    let mut row = vec![0.0f64; big_n + 1];                          // n choose k by Pascal's triangle
    row[0] = 1.0;
    for r in 1..=big_n { for k in (1..=r).rev() { row[k] += row[k - 1]; } }
    for k in [500usize, 450, 400, 300, 100] {
        let cost = 10 + log2_choose(k).ceil() as i64;
        println!("{} bits with {} ones: count in 10 bits, then which one of 2^{:.4} such strings: {} bits, saves {}", big_n, k, log2_choose(k), cost, big_n as i64 - cost);
        assert!((log2_choose(k) - row[k].log2()).abs() < 1e-9);     // sum of logs against Pascal's triangle
    }
    let tail: f64 = 2.0 * row[..=400].iter().sum::<f64>();
    let hoeff = 1.0 - 2.0 * 100.0f64.powi(2) / big_n as f64 * std::f64::consts::E.log2();
    println!("strings of {} bits with at most 400 or at least 600 ones: share 2^{:.2}; Hoeffding bound 2^{:.2}", big_n, tail.log2() - big_n as f64, hoeff);
    assert!(tail.log2() - (big_n as f64) < hoeff);                  // exact count under an independent bound
    println!("ALL CHECKS PASS");
}
