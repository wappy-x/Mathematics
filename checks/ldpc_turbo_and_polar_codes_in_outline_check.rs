// LDPC, turbo and polar codes in outline -- the same check as the Python, in Rust.  No crates.
// Same four parts: belief propagation on the Hamming (7,4) Tanner graph against all 16
// codewords; Viterbi on the (7,5) convolutional code against all 256 messages; polar
// channels on an erasure channel against all 256 erasure patterns; a (3,6) LDPC code of
// 504 bits against Hamming frames, simulated with SplitMix64, seed 2026.
struct Gen(u64);
impl Gen {
    fn draw(&mut self) -> u64 {                   // SplitMix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.draw() >> 11) as f64 / 9007199254740992.0 } fn below(&mut self, m: u64) -> usize { (((self.draw() >> 32) * m) >> 32) as usize }
}
type Rule = dyn Fn(&[f64]) -> Vec<f64>;
// belief propagation on a Tanner graph: returns decisions, messages, totals
fn bp(checks: &[Vec<usize>], l: &[f64], rounds: usize, rule: &Rule, stop: bool) -> (Vec<u8>, Vec<Vec<f64>>, Vec<f64>) {
    let mut msg: Vec<Vec<f64>> = checks.iter().map(|r| vec![0.0; r.len()]).collect();
    for it in 0..=rounds {
        let mut tot = l.to_vec();
        for (c, row) in checks.iter().enumerate() { for (t, &v) in row.iter().enumerate() { tot[v] += msg[c][t] } }
        let hard: Vec<u8> = tot.iter().map(|&x| (x < 0.0) as u8).collect();
        let ok = checks.iter().all(|r| r.iter().map(|&v| hard[v] as usize).sum::<usize>() % 2 == 0);
        if it == rounds || (stop && ok) { return (hard, msg, tot) }
        msg = checks.iter().enumerate().map(|(c, row)| rule(&row.iter().enumerate().map(|(t, &v)| tot[v] - msg[c][t]).collect::<Vec<_>>())).collect();
    }
    unreachable!()
}
fn minsum(off: f64) -> impl Fn(&[f64]) -> Vec<f64> {   // sign of the others times (smallest other size - off)
    move |ins: &[f64]| (0..ins.len()).map(|t| {
        let o: Vec<f64> = ins.iter().enumerate().filter(|&(u, _)| u != t).map(|(_, &x)| x).collect();
        let neg = o.iter().filter(|&&x| x < 0.0).count();
        let m = o.iter().fold(f64::INFINITY, |a, &x| a.min(x.abs()));
        (if neg % 2 == 1 { -1.0 } else { 1.0 }) * (m - off).max(0.0)
    }).collect()
}
fn sumprod(ins: &[f64]) -> Vec<f64> {
    (0..ins.len()).map(|t| 2.0 * ins.iter().enumerate().filter(|&(u, _)| u != t).fold(1.0, |a, (_, &x)| a * (x / 2.0).tanh()).atanh()).collect()
}
fn s(v: &[u8]) -> String { v.iter().map(|b| b.to_string()).collect() }   // bits as a string
fn f2(v: &[f64]) -> String { v.iter().map(|x| format!("{:+.2}", x)).collect::<Vec<_>>().join(" ") }
fn ints(v: &[f64]) -> String { format!("{:?}", v.iter().map(|&x| x as i64).collect::<Vec<_>>()) }
fn conv(u: &[u8]) -> Vec<u8> {                   // (7,5): outputs u+a+b and u+b, a and b the last two inputs
    let (mut a, mut b, mut out) = (0u8, 0u8, vec![]); for &x in u.iter().chain([0u8, 0].iter()) { out.push(x ^ a ^ b); out.push(x ^ b); b = a; a = x; }
    out
}
fn viterbi(r: &[u8]) -> (Vec<u8>, Vec<[u32; 4]>) {
    let (mut m, mut back, mut rows) = ([0u32, 99, 99, 99], vec![], vec![]);   // state 2a + b
    for t in 0..r.len() / 2 {
        let (mut new, mut arg) = ([99u32; 4], [(0usize, 0u8); 4]);
        for st in 0..4 {
            let (a, b) = ((st >> 1) as u8, (st & 1) as u8);
            for x in 0..2u8 {
                let d = m[st] + ((x ^ a ^ b) != r[2 * t]) as u32 + ((x ^ b) != r[2 * t + 1]) as u32;
                let ns = (2 * x + a) as usize; if d < new[ns] { new[ns] = d; arg[ns] = (st, x) }
            }
        }
        m = new; back.push(arg); rows.push(m);
    }
    let (mut st, mut u) = (0usize, vec![]);
    for arg in back.iter().rev() { let (p, x) = arg[st]; st = p; u.insert(0, x) }
    u.truncate(u.len() - 2); (u, rows)
}
fn polar(n: u32, e: f64) -> Vec<f64> { let mut z = vec![e]; for _ in 0..n { z = z.iter().flat_map(|&q| [2.0 * q - q * q, q * q]).collect() } z }   // worse, better
fn h(p: f64) -> f64 { -p * p.log2() - (1.0 - p) * (1.0 - p).log2() } fn se(f: f64, m: f64) -> f64 { ((f * (1.0 - f)).max(1.0 / m) / m).sqrt() }
fn marg(checks: &[Vec<usize>], llr: &[f64]) -> (Vec<Vec<u8>>, Vec<f64>, Vec<f64>) {   // exact confidences: every word meeting the checks, weighted by L
    let words: Vec<Vec<u8>> = (0..128u32).map(|x| (0..7).map(|v| ((x >> (6 - v)) & 1) as u8).collect::<Vec<u8>>())
        .filter(|w| checks.iter().all(|r| r.iter().map(|&v| w[v]).sum::<u8>() % 2 == 0)).collect();
    let wt: Vec<f64> = words.iter().map(|w| (0..7).map(|v| llr[v] / 2.0 * (1.0 - 2.0 * w[v] as f64)).sum::<f64>().exp()).collect();
    let side = |v: usize, b: u8| words.iter().zip(&wt).filter(|(w, _)| w[v] == b).map(|(_, &q)| q).sum::<f64>();
    let exact = (0..7).map(|v| (side(v, 0) / side(v, 1)).ln()).collect();
    (words, wt, exact)
}

fn main() {
    // ---- part 1 ----
    let hm: Vec<Vec<usize>> = vec![vec![0, 2, 4, 6], vec![1, 2, 5, 6], vec![3, 4, 5, 6]];
    let (sent, llr): (Vec<u8>, Vec<f64>) = (vec![0, 1, 1, 0, 0, 1, 1], vec![4.0, -5.0, 1.0, 3.0, -1.0, -4.0, -6.0]);
    let wrong = |v: &[u8]| v.iter().zip(&sent).filter(|(a, b)| a != b).count();
    let hard0: Vec<u8> = llr.iter().map(|&x| (x < 0.0) as u8).collect();
    let syn: Vec<u8> = hm.iter().map(|r| (r.iter().map(|&v| hard0[v]).sum::<u8>()) % 2).collect();
    let pos = (syn[0] + 2 * syn[1] + 4 * syn[2]) as usize;
    let hamfix: Vec<u8> = hard0.iter().enumerate().map(|(v, &b)| b ^ (v + 1 == pos) as u8).collect();
    let (ms, msg1, tot1) = bp(&hm, &llr, 1, &minsum(0.0), false);
    let sp1 = bp(&hm, &llr, 1, &sumprod, false).2; let sp5 = bp(&hm, &llr, 5, &sumprod, false).2;
    let (words, wt, exact) = marg(&hm, &llr);
    let mut bi = 0; for i in 1..words.len() { if wt[i] > wt[bi] { bi = i } } let ml = words[bi].clone();
    let exact_dec: Vec<u8> = exact.iter().map(|&x| (x < 0.0) as u8).collect();
    let one = |r: &Vec<usize>| format!("{:?}", r.iter().map(|v| v + 1).collect::<Vec<_>>());
    println!("Tanner graph: checks A, B, C on bits [{}]; {} edges; {} codewords", hm.iter().map(one).collect::<Vec<_>>().join(", "), hm.iter().map(|r| r.len()).sum::<usize>(), words.len());
    println!("sent {}; confidences L = {}; hard decisions {}, wrong at bits {:?}", s(&sent), ints(&llr), s(&hard0), (0..7).filter(|&v| hard0[v] != sent[v]).map(|v| v + 1).collect::<Vec<_>>());
    println!("Hamming syndrome {} -> flips bit {} -> {}, wrong bits {}", s(&syn), pos, s(&hamfix), wrong(&hamfix));
    for c in 0..3 { println!("min-sum round 1, check {} to bits {}: {}", ["A", "B", "C"][c], one(&hm[c]), ints(&msg1[c])) }
    println!("min-sum totals {} -> {}, wrong bits {}", ints(&tot1), s(&ms), wrong(&ms));
    println!("sum-product totals, 1 round  {}\nsum-product totals, 5 rounds {}\nexact, all 16 codewords      {}", f2(&sp1), f2(&sp5), f2(&exact));
    println!("most likely codeword {}; bitwise exact decisions {}", s(&ml), s(&exact_dec));
    let tree: Vec<Vec<usize>> = vec![hm[0].clone(), vec![1, 2, 5], vec![3, 4]];   // less edges 7B, 6C, 7C: no loop
    let tr = (bp(&tree, &llr, 5, &sumprod, false).2, marg(&tree, &llr).2);
    println!("tree, checks on bits [{}]: sum-product, 5 rounds {}; exact {}", tree.iter().map(one).collect::<Vec<_>>().join(", "), f2(&tr.0), f2(&tr.1));
    // ---- part 2 ----
    let msgb: Vec<u8> = vec![0, 0, 0, 1, 0, 1, 1, 1]; let cw = conv(&msgb);
    let allm: Vec<Vec<u8>> = (0..256u32).map(|m| (0..8).map(|i| ((m >> (7 - i)) & 1) as u8).collect()).collect();
    let dfree = allm[1..].iter().map(|m| conv(m).iter().map(|&b| b as u32).sum::<u32>()).min().unwrap();
    println!("message {} (23 degrees C); codeword {}; free distance by enumeration {}", s(&msgb), s(&cw), dfree);
    let mut vres = vec![];
    for ps in [vec![4usize, 13], vec![7, 8, 9]] {
        let r: Vec<u8> = cw.iter().enumerate().map(|(i, &x)| x ^ ps.contains(&(i + 1)) as u8).collect();
        let (dec, rows) = viterbi(&r);
        let ds: Vec<usize> = allm.iter().map(|m| conv(m).iter().zip(&r).filter(|(a, b)| a != b).count()).collect();
        let best = *ds.iter().min().unwrap(); let (bidx, ties) = (ds.iter().position(|&d| d == best).unwrap(), ds.iter().filter(|&&d| d == best).count());
        let val = dec.iter().fold(0u32, |a, &b| 2 * a + b as u32);
        println!("errors at {:?}: received {}; Viterbi {} (={}), metric {}; enumeration best {} at distance {}, {} tied", ps, s(&r), s(&dec), val, rows[rows.len() - 1][0], s(&allm[bidx]), best, ties);
        let txt: Vec<String> = rows.iter().map(|row| row.iter().map(|&m| if m < 99 { m.to_string() } else { "-".to_string() }).collect::<Vec<_>>().join(" ")).collect();
        if ps.len() == 2 { println!("  path metrics by step, states 00 01 10 11: {}", txt.join(" | ")) }
        vres.push((dec, allm[bidx].clone(), ties));
    }
    // ---- part 3 ----
    let g: Vec<u32> = (0..8u32).map(|i| (0..8u32).filter(|&j| j & !i == 0).map(|j| 1 << j).sum()).collect();
    let mut cnt = [0u32; 8];                      // erasure patterns (each 1 in 256) that leave u_i undecided
    for er in 0..256u32 { for i in 0..8 { for tail in 0..(1u32 << (7 - i)) {
        let mut x = g[i]; for k in 0..7 - i { x ^= g[i + 1 + k] * ((tail >> k) & 1) }
        if x & !er & 255 == 0 { cnt[i] += 1; break }
    } } }
    let z8 = polar(3, 0.5);
    let mut order: Vec<usize> = (0..8).collect(); order.sort_by(|&a, &b| z8[a].partial_cmp(&z8[b]).unwrap()); let mut info = order[..4].to_vec(); info.sort();
    println!("polar N = 8, erasure 0.5: recursion x 256 {:?}; enumeration {:?}; best 4 channels {:?}", z8.iter().map(|q| (q * 256.0) as i64).collect::<Vec<_>>(), cnt, info.iter().map(|i| i + 1).collect::<Vec<_>>());
    for n in [10u32, 20] {
        let z = polar(n, 0.5); let all = (1u64 << n) as f64;
        let share = |f: &dyn Fn(f64) -> bool| z.iter().filter(|&&q| f(q)).count() as f64 / all;
        println!("polar N = 2^{}: share nearly perfect (z < 0.001) {:.4}, nearly useless (z > 0.999) {:.4}, in between {:.4}", n, share(&|q| q < 1e-3), share(&|q| q > 0.999), share(&|q| (1e-3..=0.999).contains(&q)));
    }
    // ---- part 4 ----
    let (nb, kk, mut gen, mut ld) = (504usize, 6usize, Gen(2026), Vec::<Vec<usize>>::new());
    for band in 0..3 {                            // Gallager's construction: three shuffled bands
        let mut perm: Vec<usize> = (0..nb).collect();
        if band > 0 { for i in (1..nb).rev() { let j = gen.below(i as u64 + 1); perm.swap(i, j) } }
        for c in 0..nb / kk { ld.push(perm[c * kk..(c + 1) * kk].to_vec()) } }
    let lead = |r: &[u64; 8]| (0..8).rev().find(|&w| r[w] != 0).map(|w| 64 * w + 63 - r[w].leading_zeros() as usize);
    let mut basis: Vec<Option<[u64; 8]>> = vec![None; nb];
    for row in &ld {
        let mut r = [0u64; 8]; for &v in row { r[v / 64] |= 1 << (v % 64) }
        while let Some(t) = lead(&r) { match basis[t] { Some(bv) => { for w in 0..8 { r[w] ^= bv[w] } } None => { basis[t] = Some(r); break } } }
    }
    let rank = basis.iter().filter(|b| b.is_some()).count(); let kb = nb - rank;
    let (mut lo, mut hi) = (0.01f64, 0.5f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if h(mid) < 0.5 { lo = mid } else { hi = mid } }
    println!("LDPC: {} bits, {} checks, 3 per bit, 6 per check, rank {}, {} data bits, rate {:.4}; Hamming frame: 63 blocks, 252 data bits, 441 bits sent; rate-1/2 limit p = {:.4}", nb, ld.len(), rank, kb, kb as f64 / nb as f64, lo);
    let (bl, fr, ms1, ms0) = (100usize, 1000usize, minsum(1.0), minsum(0.0)); let mut res = vec![];
    for p in [0.02, 0.04, 0.06, 0.08, 0.10, 0.12] {
        let fail = (0..bl).filter(|_| { let l: Vec<f64> = (0..nb).map(|_| if gen.unif() < p { -4.0 } else { 4.0 }).collect(); bp(&ld, &l, 50, &ms1, true).0.iter().any(|&b| b == 1) }).count();
        let hf = (0..fr).filter(|_| (0..63).map(|_| (0..7).filter(|_| gen.unif() < p).count() > 1).fold(false, |a, b| a || b)).count();
        let exact_h = 1.0 - ((1.0f64 - p).powi(7) + 7.0 * p * (1.0f64 - p).powi(6)).powi(63);
        res.push((fail as f64 / bl as f64, hf as f64 / fr as f64, exact_h));
        println!("p {:.2}  capacity {:.4}  LDPC 504-bit frames failed {}/{}  Hamming 63-block frames failed {}/{} = {:.3} (exact {:.3})", p, 1.0 - h(p), fail, bl, hf, fr, hf as f64 / fr as f64, exact_h);
    }
    let plain = (0..bl).filter(|_| { let l: Vec<f64> = (0..nb).map(|_| if gen.unif() < 0.04 { -4.0 } else { 4.0 }).collect(); bp(&ld, &l, 50, &ms0, true).0.iter().any(|&b| b == 1) }).count();
    println!("what breaks, min-sum without the offset at p 0.04: {}/{} frames failed", plain, bl);
    println!("chart, LDPC {}; Hamming exact {}", res.iter().map(|r| format!("{:.2}", r.0)).collect::<Vec<_>>().join(", "), res.iter().map(|r| format!("{:.3}", r.2)).collect::<Vec<_>>().join(", "));
    let edges: Vec<String> = (0..3).flat_map(|c| hm[c].iter().map(move |v| format!("{}{}", v + 1, ["A", "B", "C"][c]))).collect();
    println!("figure, bits at x = {:?}, y = 50; checks A, B, C at x = [87, 181, 275], y = 190; edges {}", (0..7).map(|v| 40 + 47 * v).collect::<Vec<_>>(), edges.join(" "));
    assert!(ms == sent && ml == sent && exact_dec == sent && hamfix != sent);
    assert!(tr.0.iter().zip(&tr.1).all(|(a, b)| (a - b).abs() < 1e-9));   // on a tree, belief propagation meets the exact confidences
    assert!(vres[0].0 == msgb && vres[0].1 == msgb && vres[0].2 == 1 && dfree == 5 && vres[1].0 == vres[1].1 && vres[1].0 != msgb);
    assert!((0..8).all(|i| cnt[i] as f64 == (z8[i] * 256.0).round()) && (lo - 0.110028).abs() < 1e-5);
    assert!(res.iter().all(|r| (r.1 - r.2).abs() < 4.0 * se(r.2, fr as f64)) && res[1].0 < res[1].2 / 10.0);
    let pe: Vec<f64> = (0..2u32).map(|q| (0..8u32).filter(|b| b.count_ones() % 2 == q).map(|b| [1usize, 5, 6].iter().enumerate().map(|(j, &v)| (if (b >> j) & 1 == 1 { 1.0 } else { llr[v].exp() }) / (1.0 + llr[v].exp())).product::<f64>()).sum()).collect();
    assert!((sumprod(&hm[1].iter().map(|&v| llr[v]).collect::<Vec<_>>())[1] - (pe[0] / pe[1]).ln()).abs() < 1e-9);   // check B to bit 3: rule against its 8 parity cases
    println!("ALL CHECKS PASS");
}
