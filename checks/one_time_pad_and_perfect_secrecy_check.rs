// One-time pad -- the check behind the card.  std only, no crates.
// The pad bytes come from SplitMix64 so Python and Rust print the same thing.
// That makes this pad INSECURE: a real pad needs bytes nobody can predict.
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn byte(&mut self) -> u8 { (self.next() & 0xFF) as u8 }
}

fn xor(a: &[u8], b: &[u8]) -> Vec<u8> { a.iter().zip(b).map(|(x, y)| x ^ y).collect() }
fn hx(b: &[u8]) -> String { b.iter().map(|x| format!("{:02X}", x)).collect::<Vec<_>>().join(" ") }
fn txt(b: &[u8]) -> String { String::from_utf8(b.to_vec()).unwrap() }

// exhaustive toy: 4 messages (2 bits), prior in eighths; pk[key] = chance of that key
fn leak(prior8: &[u32; 4], pk: &[f64; 4]) -> (f64, f64, usize) {
    let pm: Vec<f64> = prior8.iter().map(|&p| p as f64 / 8.0).collect();
    let joint: Vec<Vec<f64>> = (0..4).map(|mm| (0..4).map(|cc| pm[mm] * pk[mm ^ cc]).collect()).collect();
    let pc: Vec<f64> = (0..4).map(|cc| (0..4).fold(0.0, |s, mm| s + joint[mm][cc])).collect();
    let (mut i1, mut hc, mut hc_m, mut zeros) = (0.0, 0.0, 0.0, 0);
    for mm in 0..4 { for cc in 0..4 {
        let j = joint[mm][cc];
        if j > 0.0 { i1 += j * (j / (pm[mm] * pc[cc])).log2(); }
    } }
    for &p in &pc { if p > 0.0 { hc += p * p.log2(); } }
    for mm in 0..4 { for &q in pk { if q > 0.0 { hc_m += pm[mm] * q * q.log2(); } } }
    for mm in 0..4 { for cc in 0..4 { if pc[cc] > 0.0 && joint[mm][cc] == 0.0 { zeros += 1; } } }
    (i1, -hc - -hc_m, zeros)
}

fn main() {
    // ---- the example: one 20-character order from a laptop to a bank ----
    let mut rng = SplitMix64 { s: 2026 };
    let m = b"TRANSFER 750 TO BOB.".to_vec();
    let k: Vec<u8> = (0..20).map(|_| rng.byte()).collect();
    let c = xor(&m, &k);
    let back = xor(&c, &k);
    println!("pad from SplitMix64, seed 2026: a stand-in, insecure as a real pad");
    println!("m   {}", txt(&m));
    println!("m   {}", hx(&m));
    println!("k   {}", hx(&k));
    println!("c   {}", hx(&c));
    assert!(back == m);
    println!("c xor k: {}", txt(&back));
    // char 10 (index 9), bit by bit: XOR is addition mod 2 in each bit
    let mut sum_mod2 = 0u8;
    for b in (0..8).rev() { sum_mod2 = sum_mod2 * 2 + (((m[9] >> b) & 1) + ((k[9] >> b) & 1)) % 2; }
    println!("char 10: m {:08b} k {:08b} c {:08b}", m[9], k[9], c[9]);
    assert!(sum_mod2 == c[9]);

    // ---- every other message fits the same ciphertext under exactly one key ----
    let alt = b"TRANSFER 950 TO EVE.".to_vec();
    let k_alt = xor(&c, &alt);
    println!("key that turns c into {}: {}", txt(&alt), hx(&k_alt));
    assert!(xor(&alt, &k_alt) == c && k_alt != k);
    let keys = 256f64.powi(20);
    let e = keys.log10().floor() as i32;
    println!("keys of 20 bytes: 256^20 = 2^160 = {:.4} x 10^{}", keys / 10f64.powi(e), e);
    assert!(keys == 2f64.powi(160));

    // ---- exhaustive toy: 4 messages (2 bits), prior 1/2, 1/4, 1/8, 1/8 ----
    let prior8 = [4u32, 2, 1, 1];
    let hm = -prior8.iter().fold(0.0, |s, &p| s + p as f64 / 8.0 * (p as f64 / 8.0).log2());
    println!("toy: H(M) = {:.4} bits", hm);
    // uniform key, exact in 32nds: posterior P(m|c) must equal prior P(m) for all 16 pairs
    let key4 = [1u32, 1, 1, 1]; // each key has chance 1/4
    let joint32: Vec<Vec<u32>> = (0..4).map(|mm| (0..4).map(|cc| prior8[mm] * key4[mm ^ cc]).collect()).collect();
    let pc32: Vec<u32> = (0..4).map(|cc| (0..4).map(|mm| joint32[mm][cc]).sum()).collect();
    let same = (0..4).all(|mm| (0..4).all(|cc| joint32[mm][cc] * 8 == prior8[mm] * pc32[cc]));
    println!("uniform key: posterior equals prior in all 16 cells: {}", if same { "True" } else { "False" });
    assert!(same && pc32 == vec![8, 8, 8, 8]);
    let rows: [(&str, [f64; 4]); 4] = [("uniform key", [0.25; 4]), ("biased key", [0.4, 0.3, 0.2, 0.1]),
        ("3 keys only", [1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0, 0.0]), ("1 key only", [1.0, 0.0, 0.0, 0.0])];
    let mut res = Vec::new();
    for (name, pk) in rows.iter() {
        let (i1, i2, z) = leak(&prior8, pk);
        res.push((i1, z));
        println!("{:11}: I(M;C) = {:.4} bits, H(M|C) = {:.4}, impossible cells = {}", name, i1, hm - i1, z);
        assert!((i1 - i2).abs() < 1e-12);
    }
    assert!(res[0].0.abs() < 1e-12 && res[0].1 == 0);
    assert!(res[1].0 > 0.01 && res[2].1 > 0);
    assert!((res[3].0 - hm).abs() < 1e-12);

    // ---- simulation: is it 750 or 950?  The guesser sees only c ----
    let n = 100_000;
    let mut sim = SplitMix64 { s: 7 };
    let (mut win_fresh, mut win_weak, mut win_reuse) = (0u32, 0u32, 0u32);
    let old_m = b"TRANSFER 200 TO ANN.".to_vec();
    let rule = |c9: u8| if (c9 ^ m[9]) & 0x0E == 0 { m.clone() } else { alt.clone() }; // reads bits 1-3, where '7' and '9' differ
    for _ in 0..n {
        let sent = if sim.byte() & 1 == 1 { &m } else { &alt };
        let key: Vec<u8> = (0..20).map(|_| sim.byte()).collect();
        let ct = xor(sent, &key);
        if rule(ct[9]) == *sent { win_fresh += 1; }
        if rule(sent[9] ^ (sim.byte() & sim.byte())) == *sent { win_weak += 1; } // weak pad byte: each bit 1 with chance 1/4
        let old_c = xor(&old_m, &key);
        if xor(&xor(&ct, &old_c), &old_m) == *sent { win_reuse += 1; } // an XOR identity: shows the attack, tests only XOR
    }
    let p = win_fresh as f64 / n as f64;
    let se = (0.25 / n as f64).sqrt();
    let weak = 0.5 * 0.75f64.powi(3) + 0.5 * (1.0 - 0.25f64.powi(3)); // exact: right if bits 1-3 are 000 (750 sent) or not 111 (950)
    println!("guessing 750 or 950 over {} trials: fresh pad {:.4} (se {:.4}), reused pad {:.4}", n, p, se, win_reuse as f64 / n as f64);
    println!("same guesser, weak pad (each bit 1 with chance 1/4): {:.4}, exact {:.4}", win_weak as f64 / n as f64, weak);
    assert!((p - 0.5).abs() < 4.0 * se); // fails for any pad that is not uniform in those bits
    assert!((win_weak as f64 / n as f64 - weak).abs() < 4.0 * se); // fails if the guesser is blind to the message
    assert!(win_reuse == n);

    // ---- what breaks: the same pad used twice ----
    let c2 = xor(&old_m, &k);
    let leak2 = xor(&c, &c2);
    println!("c xor c2: {}", hx(&leak2));
    println!("bytes equal to 00: {} of 20", leak2.iter().filter(|&&x| x == 0).count());
    assert!(leak2 == xor(&m, &old_m));
    println!("c2 xor c xor m: {}", txt(&xor(&leak2, &m)));
    assert!(xor(&leak2, &m) == old_m);

    // ---- what breaks: a short key repeated to fill 20 bytes ----
    let ok = b"ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ."; // 38 readable characters
    let mut counts: Vec<u64> = Vec::new();
    for l in 1..6usize {
        let ct: Vec<u8> = m.iter().enumerate().map(|(i, x)| x ^ k[i % l]).collect();
        let mut n_read = 1u64; // key positions are independent
        for j in 0..l {
            let col: Vec<u8> = ct.iter().skip(j).step_by(l).cloned().collect();
            n_read *= (0..=255u8).filter(|&b| col.iter().all(|&x| ok.contains(&(x ^ b)))).count() as u64;
        }
        counts.push(n_read);
    }
    let shown: Vec<String> = counts.iter().map(|x| x.to_string()).collect();
    println!("repeated key of 1 to 5 bytes, readable decryptions: {}", shown.join(", "));
    let ct2: Vec<u8> = m.iter().enumerate().map(|(i, x)| x ^ k[i % 2]).collect(); // all 65,536 two-byte keys
    let mut brute2 = 0u64;
    for a in 0..=255u8 { for b in 0..=255u8 {
        if ct2.iter().enumerate().all(|(i, &x)| ok.contains(&(x ^ if i % 2 == 0 { a } else { b }))) { brute2 += 1; }
    } }
    assert!(counts[0] == 1 && brute2 == counts[1] && counts.windows(2).all(|w| w[0] < w[1]));
    println!("pad of 20 bytes: every string of those 38 characters fits, 38^20 = {:.4} x 10^31", 38f64.powi(20) / 1e31);

    // ---- what breaks: secrecy is not integrity ----
    let mut tampered = c.clone();
    tampered[9] ^= b'7' ^ b'9';
    println!("flip c[9] by {:02X} -> bank reads: {}", b'7' ^ b'9', txt(&xor(&tampered, &k)));
    assert!(xor(&tampered, &k) == b"TRANSFER 950 TO BOB.".to_vec());

    // ---- the price: pad bytes the bank must hold in advance ----
    let per_day: u64 = 10_000_000 * 20;
    println!("pad for 10,000,000 orders a day: {} bytes a day, {} a year", commas(per_day), commas(per_day * 365));
    println!("ALL CHECKS PASS");
}

fn commas(x: u64) -> String {
    let s = x.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
