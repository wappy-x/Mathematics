// Randomness extractors -- the same check as the Python, in Rust.  No crates.
// Part 1: von Neumann's trick on a coin that lands heads 70% of the time.
// Part 2: 16-bit sensor readings with min-entropy 8, hashed to 2 bits by a random
// Toeplitz matrix (a 17-bit seed), measured against the leftover hash lemma.
const N16: usize = 1 << 16;

struct SplitMix64 { s: u64 }                         // small seeded generator, written out
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn flips(rng: &mut SplitMix64, n: usize, p1: f64, p2: f64) -> Vec<u8> {   // 1 = heads
    (0..n).map(|i| {
        let u = (rng.next() >> 11) as f64 / 9007199254740992.0;
        if u < (if i % 2 == 0 { p1 } else { p2 }) { 1 } else { 0 }
    }).collect()
}

fn von_neumann(f: &[u8], step: usize) -> Vec<u8> {   // HT -> 0, TH -> 1, else nothing
    let mut out = Vec::new();
    let mut i = 0;
    while i + 1 < f.len() {
        if f[i] != f[i + 1] { out.push(f[i + 1]); }
        i += step;
    }
    out
}

fn parity(v: usize) -> usize { (v.count_ones() & 1) as usize }

fn wht(a: &[i64], size: usize) -> Vec<i64> {         // out[r] = sum_x a[x] * (-1)^parity(r AND x)
    let mut a = a.to_vec();
    let mut h = 1;
    while h < size {
        for i in (0..size).step_by(2 * h) {
            for j in i..i + h { let (x, y) = (a[j], a[j + h]); a[j] = x + y; a[j + h] = x - y; }
        }
        h *= 2;
    }
    a
}

fn cells(f: &[i64], z: usize, m: usize) -> Vec<i64> { // 2^m * weight in each output cell
    let rows: Vec<usize> = (0..m).map(|j| (z >> j) & 0xFFFF).collect();
    let mut comb = vec![0usize; 1 << m];
    for s in 1..(1usize << m) {
        let low = s & s.wrapping_neg();
        comb[s] = comb[s ^ low] ^ rows[low.trailing_zeros() as usize];
    }
    let vals: Vec<i64> = comb.iter().map(|&c| f[c]).collect();
    wht(&vals, 1 << m)
}

fn dist(c: &[i64], w: i64, m: usize) -> f64 {
    c.iter().map(|&v| (v - w).abs()).sum::<i64>() as f64 / (2 * w * (1i64 << m)) as f64
}

fn bits(v: &[u8]) -> String { v.iter().map(|b| b.to_string()).collect() }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }
fn share(v: &[u8]) -> f64 { v.iter().map(|&b| b as f64).sum::<f64>() / v.len() as f64 }

fn main() {
    println!("PART 1: a coin with Pr[heads] = 0.7");
    let (p, q) = (0.7f64, 0.3f64);
    println!("one pair: HH {:.4}, HT {:.4}, TH {:.4}, TT {:.4}, discarded {:.4}", p * p, p * q, q * p, q * q, p * p + q * q);
    println!("von Neumann, exact: a pair gives a bit with chance {:.4}; Pr[bit = 1] = {:.4}; bits per flip {:.4}", 2.0 * p * q, q * p / (2.0 * p * q), p * q);
    println!("per flip: min-entropy {:.4} bits, Shannon entropy {:.4} bits", -p.log2(), -(p * p.log2() + q * q.log2()));
    let f = flips(&mut SplitMix64 { s: 2026 }, 200000, p, p);
    let hs: String = f[..12].iter().map(|&b| if b == 1 { 'H' } else { 'T' }).collect();
    println!("first 12 flips: {} -> bits {}", hs, bits(&von_neumann(&f[..12], 2)));
    let out = von_neumann(&f, 2);
    let se = (0.25 / out.len() as f64).sqrt();
    println!("simulated, 200000 flips, seed 2026: {} bits, {:.4} per flip, share of 1s {:.4}, standard error {:.4}", out.len(), out.len() as f64 / 200000.0, share(&out), se);
    let same = (0..out.len() - 1).filter(|&i| out[i] == out[i + 1]).count() as f64 / (out.len() - 1) as f64;
    println!("simulated: next bit equals the last one with share {:.4} (fair coins: 0.5000)", same);
    let ov = von_neumann(&f, 1);
    let alt = (0..ov.len() - 1).filter(|&i| ov[i] != ov[i + 1]).count() as f64 / (ov.len() - 1) as f64;
    println!("mistake, overlapping pairs: {} bits, each bit differs from the last with share {:.4}", ov.len(), alt);
    let dr_exact = p * 0.4 / (p * 0.4 + q * 0.6);
    let dr = von_neumann(&flips(&mut SplitMix64 { s: 7 }, 200000, 0.7, 0.6), 2);
    let dr_se = (dr_exact * (1.0 - dr_exact) / dr.len() as f64).sqrt();
    println!("mistake, bias drifts 0.7 then 0.6 inside a pair: HT {:.4}, TH {:.4}, Pr[bit = 0] exact {:.4}, simulated {:.4}", p * 0.4, q * 0.6, dr_exact, 1.0 - share(&dr));

    println!("PART 2: 16-bit readings = 32768 + a - b, with a, b uniform on 0..255");
    let mut w = vec![0i64; N16];
    for d in -255i64..256 { w[(32768 + d) as usize] = 256 - d.abs(); }
    let ww: i64 = w.iter().sum();
    let sq: i64 = w.iter().map(|v| v * v).sum();
    let mx = *w.iter().max().unwrap();
    println!("readings {}, most likely chance {}/{} = 1/{}, min-entropy {:.4} bits", w.iter().filter(|&&v| v > 0).count(), mx, ww, ww / mx, -(mx as f64 / ww as f64).log2());
    let hsh: f64 = -w.iter().filter(|&&v| v > 0).map(|&v| { let r = v as f64 / ww as f64; r * r.log2() }).sum::<f64>();
    println!("collision probability {:.6} = 1/{:.1}, Shannon entropy {:.4} bits", sq as f64 / (ww * ww) as f64, (ww * ww) as f64 / sq as f64, hsh);
    let ff = wht(&w, N16);
    let (z0, x0) = (0b10110010011000101usize, 32768usize + 37);
    let (r0, r1) = (z0 & 0xFFFF, (z0 >> 1) & 0xFFFF);
    println!("worked seed {:017b}: row 0 {:016b}, row 1 {:016b}", z0, r0, r1);
    println!("reading {} = {:016b}: AND row 0 has {} ones, AND row 1 has {} ones -> output {}{}", x0, x0, (r0 & x0).count_ones(), (r1 & x0).count_ones(), parity(r1 & x0), parity(r0 & x0));
    let c0 = cells(&ff, z0, 2);
    println!("worked seed: weight in cells 00, 01, 10, 11 = {:?} of {}, distance {:.6}", c0.iter().map(|v| v / 4).collect::<Vec<_>>(), ww, dist(&c0, ww, 2));
    let (mut tot, mut worst, mut over, mut sumsq) = (0i64, 0i64, 0usize, 0i64);
    for z in 0..(1usize << 17) {                     // every seed of the family, by the Fourier road
        let c = cells(&ff, z, 2);
        let s: i64 = c.iter().map(|&v| (v - ww).abs()).sum();
        tot += s; worst = worst.max(s); if 2 * s > ww { over += 1; }
        sumsq += c.iter().map(|v| v * v).sum::<i64>();
    }
    let avg2 = tot as f64 / (8 * ww * (1 << 17)) as f64;
    let bound2 = 0.5 * 2f64.powf(-(8.0 - 2.0) / 2.0);
    let cpb = 0.5 * (3.0 * sq as f64 / (ww * ww) as f64).sqrt();
    println!("all 131072 seeds, m = 2: average distance {:.6}, worst {:.6}, seeds above 1/16: {} ({:.2}%)", avg2, worst as f64 / (8 * ww) as f64, over, 100.0 * over as f64 / (1 << 17) as f64);
    println!("leftover hash lemma: min-entropy bound {:.6}, collision-probability bound {:.6}", bound2, cpb);
    let pred = (1i64 << 17) * (12 * sq + 4 * ww * ww);
    println!("universality: sum over seeds of squared cell weights {}, predicted {}: {}", sumsq, pred, if sumsq == pred { "equal" } else { "different" });
    let mut rng = SplitMix64 { s: 11 };
    let sup: Vec<usize> = (0..N16).filter(|&x| w[x] > 0).collect();
    let mut agree = 0;
    for _ in 0..200 {                                // direct count over the 511 readings, no Fourier
        let z = (rng.next() >> 47) as usize;
        let mut direct = vec![0i64; 4];
        for &x in &sup { direct[2 * parity(((z >> 1) & 0xFFFF) & x) + parity((z & 0xFFFF) & x)] += w[x]; }
        if direct.iter().map(|v| 4 * v).collect::<Vec<_>>() == cells(&ff, z, 2) { agree += 1; }
    }
    println!("direct count against Fourier road, 200 sampled seeds: {} agree", agree);
    println!("m | bound 0.5 * 2^(-(8 - m)/2) | sampled average over 1000 seeds");
    let (mut sweep, mut bnds, mut rng) = (Vec::new(), Vec::new(), SplitMix64 { s: 5 });
    for m in 1..=8usize {
        let mut sum = 0.0;
        for _ in 0..1000 { sum += dist(&cells(&ff, (rng.next() >> (64 - 15 - m)) as usize, m), ww, m); }
        sweep.push(sum / 1000.0);
        bnds.push(0.5 * 2f64.powf(-(8.0 - m as f64) / 2.0));
        println!("{} | {:.4} | {:.4}", m, bnds[m - 1], sweep[m - 1]);
    }
    println!("figure, bound: {}", join(&bnds));
    println!("figure, sampled: {}", join(&sweep));
    let dead: Vec<i64> = (0..N16).map(|x| if (0x3000..0x3400).contains(&x) && x % 4 == 0 { 1 } else { 0 }).collect();
    let fixed: Vec<i64> = (0..4).map(|c| (0..N16).filter(|&x| x & 3 == c).map(|x| dead[x]).sum()).collect();
    println!("mistake, dead low bits (readings 12288, 12292, ..., 13308) with fixed 'keep the low 2 bits': cells {:?}, distance {:.4}", fixed, fixed.iter().map(|&v| (4 * v - 256).abs()).sum::<i64>() as f64 / 2048.0);
    let fd = wht(&dead, N16);
    let avgd = (0..(1usize << 17)).map(|z| dist(&cells(&fd, z, 2), 256, 2)).sum::<f64>() / (1 << 17) as f64;
    println!("same dead-bit readings, random seed: average distance {:.6}", avgd);
    let to00: Vec<usize> = (0..N16).filter(|&x| parity(r0 & x) == 0 && parity(r1 & x) == 0).collect();
    let bad: Vec<usize> = to00[..256].to_vec();
    let mut bw = vec![0i64; N16];
    for &x in &bad { bw[x] = 1; }
    println!("mistake, worked seed fixed in advance: it sends {} readings to 00; the first 256 as a source, distance {:.4}", to00.len(), dist(&cells(&wht(&bw, N16), z0, 2), 256, 2));
    let mut st = vec![1i64; N16];
    st[0] = N16 as i64 - 1;                          // stuck at 0 half the time, else any other reading
    let ws: i64 = st.iter().sum();
    let hs2: f64 = -st.iter().map(|&v| { let r = v as f64 / ws as f64; r * r.log2() }).sum::<f64>();
    let fs = wht(&st, N16);
    let avgs = (0..(1usize << 17)).map(|z| dist(&cells(&fs, z, 2), ws, 2)).sum::<f64>() / (1 << 17) as f64;
    println!("mistake, stuck sensor: Shannon entropy {:.4} bits, min-entropy {:.4} bits, average distance {:.6}", hs2, -(st[0] as f64 / ws as f64).log2(), avgs);
    println!("real size: k = 256 bits, eps = 2^-64 -> m = 256 - 2 * 64 + 2 = {} bits", 256 - 128 + 2);
    assert!((out.len() as f64 / 200000.0 - p * q).abs() < 4.0 * (p * q / 200000.0).sqrt()); // rate against pq
    assert!((share(&out) - 0.5).abs() < 4.0 * se);                                     // bits against 1/2
    assert!(alt == 1.0);                                                               // overlapping pairs alternate
    assert!((1.0 - share(&dr) - dr_exact).abs() < 4.0 * dr_se);                        // drift against formula
    assert!(sumsq == pred && agree == 200);                                            // universality; two roads
    assert!(avg2 <= cpb && cpb <= bound2 && (sweep[1] - avg2).abs() < 0.003);          // bound; sampling meets exact
    assert!(sweep.iter().zip(&bnds).all(|(s, b)| s <= b));                             // bound at every m
    assert!(fixed == vec![256, 0, 0, 0] && bad.len() == 256 && avgs > 0.25);           // no seed, or low min-entropy
    assert!(ww == 256 * mx && sq == 256 * 256 + 255 * 256 * 511 / 3);                  // min-entropy 8; squares by formula
    println!("ALL CHECKS PASS");
}
