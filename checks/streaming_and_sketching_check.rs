// Streaming and sketching -- the same check as the Python, in Rust.  No crates.
// One day's visitor log is read once.  An exact count keeps every visitor; a
// HyperLogLog sketch keeps 4,096 small registers.  Random numbers and the hash
// are SplitMix64, written out, so both programs print the same lines.
use std::collections::{HashMap, HashSet};

fn mix64(z: u64) -> u64 { // SplitMix64's scrambler: the hash
    let mut z = z.wrapping_add(0x9E3779B97F4A7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
struct Gen { s: u64 } // SplitMix64 generator, seed stated
impl Gen {
    fn next(&mut self) -> u64 { let z = self.s; self.s = self.s.wrapping_add(0x9E3779B97F4A7C15); mix64(z) }
}
fn alpha(m: usize) -> f64 {
    match m { 16 => 0.673, 32 => 0.697, 64 => 0.709, _ => 0.7213 / (1.0 + 1.079 / m as f64) }
}
fn add(reg: &mut [u32], b: u32, h: u64) { // first b bits pick a register; the rest give a rank
    let rest = h & ((1u64 << (64 - b)) - 1);
    let rank = (64 - b) - (64 - rest.leading_zeros()) + 1; // leading zeros of the rest, plus 1
    let j = (h >> (64 - b)) as usize;
    if rank > reg[j] { reg[j] = rank; }
}
fn estimate(reg: &[u32], correct: bool) -> f64 { // harmonic mean of 2^rank, scaled by alpha m^2
    let m = reg.len() as f64;
    let mut s = 0.0;
    for &r in reg { s += 2f64.powi(-(r as i32)); }
    let raw = alpha(reg.len()) * m * m / s;
    let zeros = reg.iter().filter(|&&r| r == 0).count();
    if correct && raw <= 2.5 * m && zeros > 0 { return m * (m / zeros as f64).ln(); }
    raw
}
fn toy(stream: &[u64]) -> u32 { // a 9-bit bitmap: visitor v sets bit v mod 9
    let mut state = 0u32;
    for &v in stream { state |= 1 << (v % 9); }
    state
}
fn distinct(s: &[u64]) -> usize { s.iter().collect::<HashSet<_>>().len() }

fn main() {
    // ---- the day: 1,000,000 requests; half from 1,000 regulars, half from 999,000 others ----
    let (n, salt, b) = (1_000_000u64, 2026u64, 12u32);
    let (mut g, mut seen, mut reg) = (Gen { s: 2026 }, HashSet::new(), vec![0u32; 1 << b]);
    for _ in 0..n {
        let r = g.next();
        let v = if r & 1 == 1 { (r >> 1) % 1000 } else { 1000 + (r >> 1) % 999_000 };
        seen.insert(v);                    // road 1: the exact count keeps every visitor
        add(&mut reg, b, mix64(v ^ salt)); // road 2: the sketch keeps 4,096 registers
    }
    let (d, m) = (seen.len(), 1usize << b);
    let df = d as f64;
    let est = estimate(&reg, true);
    let se = 1.04 / (m as f64).sqrt();
    println!("requests read once {}", n);
    println!("distinct visitors, exact {}", d);
    println!("sketch: {} registers of 6 bits = {} bytes", m, m * 6 / 8);
    println!("sketch estimate {:.0}, error {:+.2}%", est, 100.0 * (est - df) / df);
    println!("promised typical error 1.04/sqrt({}) = {:.2}%", m, 100.0 * se);
    let mean_rank = reg.iter().map(|&r| r as f64).sum::<f64>() / m as f64;
    println!("one register sees about D/{} = {:.1} visitors; log2 of that {:.2}, mean rank {:.2}",
             m, df / m as f64, (df / m as f64).log2(), mean_rank);
    let (lo, hi) = (est / (1.0 + 2.0 * se), est / (1.0 - 2.0 * se));
    println!("95% error bar: {:.0} to {:.0}", lo, hi);
    assert!((est - df).abs() / df < 3.0 * se && lo <= df && df <= hi);
    assert!(390_000 < d && d < 400_000);

    // ---- what exact counting costs: the visitor set itself must fit in memory ----
    let u = 1u64 << 32;
    let mut floor_bits = 0.0;
    for i in 0..d as u64 { floor_bits += ((u - i) as f64 / (d as u64 - i) as f64).log2(); }
    println!("exact count, floor log2 C(2^32, D) = {:.0} bytes, {:.2} bits each", floor_bits / 8.0, floor_bits / df);
    println!("per visitor: log2(2^32 / D) = {:.2}, plus log2 e = {:.2}", (u as f64 / df).log2(), 1.0 / 2f64.ln());
    println!("exact count, plain list of 4-byte addresses = {} bytes", 4 * d);
    println!("floor over sketch: {:.0} times the memory", floor_bits / 8.0 / (m * 6 / 8) as f64);
    let approx = df * ((u as f64 / df).log2() + 1.0 / 2f64.ln()); // D (log2(U/D) + log2 e)
    assert!((approx - floor_bits).abs() < 1e-3 * floor_bits);

    // ---- the proof run on a toy: 10 possible visitors, a summary of 9 bits ----
    let mut first: HashMap<u32, Vec<u64>> = HashMap::new();
    let mut pair: Option<(Vec<u64>, Vec<u64>)> = None;
    for mask in 0u32..1 << 10 {            // all 1,024 sets of the 10 visitors
        let s: Vec<u64> = (0..10).filter(|v| mask >> v & 1 == 1).collect();
        let st = toy(&s);
        if pair.is_none() { if let Some(f) = first.get(&st) { pair = Some((f.clone(), s.clone())); } }
        first.entry(st).or_insert(s);
    }
    let (s1, t1) = pair.unwrap();
    let x = *s1.iter().chain(t1.iter()).find(|v| s1.contains(v) != t1.contains(v)).unwrap();
    let (mut sx, mut tx) = (s1.clone(), t1.clone());
    sx.push(x); tx.push(x);
    println!("toy: {} memory states for 1024 visitor sets", first.len());
    println!("toy: sets {:?} and {:?} leave the same memory", s1, t1);
    println!("toy: add visitor {}; true counts {} and {}, summary answers {} for both",
             x, distinct(&sx), distinct(&tx), toy(&sx).count_ones());
    assert!(first.len() == 512 && toy(&sx) == toy(&tx) && distinct(&sx) != distinct(&tx));
    let mut dec = 0;                       // an exact 10-bit bitmap: probing recovers every set
    for mask in 0u32..1 << 10 {
        let cnt = mask.count_ones();       // feed each visitor to a copy; count unchanged means seen
        let got: u32 = (0..10).filter(|v| (mask | 1 << v).count_ones() == cnt).map(|v| 1 << v).sum();
        if got == mask { dec += 1; }
    }
    println!("toy: a 10-bit exact counter is decoded back to its set {} times in 1024", dec);
    assert!(dec == 1024);

    // ---- accuracy bought by memory: 100 days of 40,000 fresh visitors each ----
    let (trials, dd, bs) = (100u64, 40_000u64, [6u32, 8, 10, 12]);
    let (mut sq, mut out2) = ([0.0f64; 4], [0u32; 4]);
    for t in 0..trials {
        let mut sks: Vec<Vec<u32>> = bs.iter().map(|&b| vec![0u32; 1 << b]).collect();
        let salt = Gen { s: 7 + t }.next();
        for i in 0..dd {
            let h = mix64((t * 1_000_000 + i) ^ salt);
            for k in 0..4 { add(&mut sks[k], bs[k], h); }
        }
        for k in 0..4 {
            let e = (estimate(&sks[k], true) - dd as f64) / dd as f64;
            sq[k] += e * e;
            if e.abs() > 2.0 * 1.04 / ((1u64 << bs[k]) as f64).sqrt() { out2[k] += 1; }
        }
    }
    println!("registers  bytes  promised  measured  misses past 2x promise");
    for k in 0..4 {
        let mm = 1usize << bs[k];
        let rms = (sq[k] / trials as f64).sqrt();
        let p = 1.04 / (mm as f64).sqrt();
        println!("{:9}{:7}{:9.2}%{:9.2}%{:8} of {}", mm, mm * 6 / 8, 100.0 * p, 100.0 * rms, out2[k], trials);
        assert!((rms / p - 1.0).abs() < 0.3);
        assert!(out2[k] <= 12);
    }

    // ---- turning a typical error into a guarantee: the median of k sketches ----
    for delta in [0.05f64, 0.01, 0.001] {
        let k = (8.0 * (1.0 / delta).ln()).ceil() as usize;
        println!("fail chance {}: median of {} sketches, {} bytes", delta, k, k * m * 6 / 8);
    }

    // ---- what breaks ----
    let mut small = vec![0u32; 1 << b];
    for i in 0..1000u64 { add(&mut small, b, mix64(i ^ salt)); }
    let mut a = 0.0;
    for &r in &reg { a += 2f64.powi(r as i32); }
    let arith = alpha(m) * m as f64 * a / m as f64;
    println!("break: count requests, not visitors: {}", n);
    println!("break: 1000 visitors, no small-count correction: {:.0} (with it {:.0})",
             estimate(&small, false), estimate(&small, true));
    println!("break: plain average of 2^rank, not harmonic: {:.0}", arith);
    assert!((estimate(&small, true) - 1000.0).abs() < 50.0 && estimate(&small, false) > 2000.0 && arith > 2.0 * df);
    println!("ALL CHECKS PASS");
}
