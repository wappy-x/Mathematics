// Arithmetic and Lempel-Ziv coding -- the same check as the Python, in Rust.  No
// crates; f64's log2 and powf know nothing about compression.  A weather station
// sends C (cloudy), S (sunny) or R (rain) each day.  Arithmetic coding turns a month
// into one interval and one binary fraction; LZ78 builds a dictionary of phrases.
const NAMES: [char; 3] = ['C', 'S', 'R'];               // cloudy, sunny, rain
const F: [u128; 3] = [8, 1, 1];                         // chances in tenths: 0.8, 0.1, 0.1
const CUM: [u128; 3] = [0, 8, 9];                       // where each slice starts, in tenths
const MONTH: &str = "CCSCCCCCRCCCCCCSCCCCRCCCCCCSCR";   // 30 days: 24 cloudy, 3 sunny, 3 rain
const HUFF: [u64; 3] = [1, 2, 2];                       // Huffman lengths for 0.8, 0.1, 0.1
const SEED: u64 = 2026;
const NONE: usize = usize::MAX;                         // "no new symbol" on the last phrase

fn idx(c: char) -> usize { NAMES.iter().position(|&n| n == c).unwrap() }

fn encode(msg: &str) -> (u128, u128, u128, u32, u128) { // interval [L/D, (L+W)/D), then the code
    let (mut l, mut w, mut d) = (0u128, 1u128, 1u128);
    for s in msg.chars().map(idx) { (l, w, d) = (10 * l + w * CUM[s], w * F[s], 10 * d); }
    let mut k = 0;
    while (w << k) < d { k += 1; }                      // smallest k with 2^-k <= width
    let x = ((l << k) + d - 1) / d;                     // first k-bit fraction at or above L/D
    assert!(x * d < (l + w) << k);                      // ... and it lies inside the interval
    (l, w, d, k, x)
}

fn decode(x: u128, k: u32, n: usize) -> String {       // follow the point x/2^k down the splits;
    let (mut num, mut den, mut out) = (x, 1u128 << k, String::new()); // num/den = place in interval
    for _ in 0..n {
        let s = [2, 1, 0].into_iter().find(|&s| CUM[s] * den <= 10 * num).unwrap();
        (num, den) = (10 * num - CUM[s] * den, F[s] * den);
        out.push(NAMES[s]);
    }
    out
}

fn lz78(x: &[usize]) -> (Vec<(usize, usize)>, u64) {   // phrases = earlier phrase + one new symbol
    let (mut trie, mut i, mut bits, mut out) = (vec![[0usize; 3]], 0, 0u64, Vec::new());
    while i < x.len() {
        let mut node = 0;
        while i < x.len() && trie[node][x[i]] != 0 { (node, i) = (trie[node][x[i]], i + 1); }
        bits += (usize::BITS - (trie.len() - 1).leading_zeros()) as u64; // index bits
        if i < x.len() {
            let next = trie.len();
            trie[node][x[i]] = next;
            trie.push([0; 3]);
            out.push((node, x[i]));
            (bits, i) = (bits + 2, i + 1);              // new symbol: 2 bits
        } else {
            out.push((node, NONE));                     // last phrase already known
        }
    }
    (out, bits)
}

fn unlz78(pairs: &[(usize, usize)]) -> Vec<Vec<usize>> { // rebuild the phrases from the pairs
    let mut phrases: Vec<Vec<usize>> = vec![vec![]];
    for &(j, s) in pairs {
        phrases.push([phrases[j].clone(), if s == NONE { vec![] } else { vec![s] }].concat());
    }
    phrases.split_off(1)
}

fn splitmix64(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn weather(n: usize, rows: &[[f64; 3]; 3]) -> Vec<usize> { // synthetic days; rows[t] = chances after t
    let (mut state, mut today, mut out) = (SEED, 0usize, Vec::new());
    for _ in 0..n {
        let z;
        (state, z) = splitmix64(state);
        let u = (z >> 11) as f64 / 2f64.powi(53);       // uniform in [0, 1); first slice past u
        today = (0..3).find(|&s| u < rows[today][..s + 1].iter().fold(0.0, |a, b| a + b)).unwrap_or(2);
        out.push(today);
    }
    out
}

fn by_formula(n: i32) -> f64 {                          // expected bits per day, grouped by counts
    let (mut e, mut coef) = (0.0, 2f64.powi(n));
    for a in 0..=n {                                    // a cloudy days: coef = C(n, a) 2^(n-a)
        let bits = (a as f64 * 1.25f64.log2() + (n - a) as f64 * 10f64.log2()).ceil();
        e += coef * 0.8f64.powf(a as f64) * 0.1f64.powf((n - a) as f64) * bits;
        coef = coef * (n - a) as f64 / (a + 1) as f64 / 2.0;
    }
    e / n as f64
}

fn text(p: &[usize]) -> String { p.iter().map(|&s| NAMES[s]).collect() }

fn main() {
    let p: Vec<f64> = F.iter().map(|&f| f as f64 / 10.0).collect();
    let h: f64 = p.iter().map(|&q| q * (1.0 / q).log2()).sum();
    let (_, w, d, k, x) = encode(MONTH);
    let ideal: f64 = MONTH.chars().map(|c| (10.0 / F[idx(c)] as f64).log2()).sum();
    let huff: u64 = MONTH.chars().map(|c| HUFF[idx(c)]).sum();
    let count = |ch: char| MONTH.chars().filter(|&c| c == ch).count();
    println!("chances 0.8, 0.1, 0.1: surprise {:.4}, {:.4} bits; H = {:.4} bits a day; Huffman lengths {:?}, {:.4} a day",
        1.25f64.log2(), 10f64.log2(), h, HUFF, p.iter().zip(HUFF).map(|(q, l)| q * l as f64).sum::<f64>());
    println!("month: {}: {} C, {} S, {} R", MONTH, count('C'), count('S'), count('R'));
    println!("width = 0.8^24 x 0.1^6 = {}/10^30, 1 in {:.1}; log2(1/width) = {:.4}", w, d as f64 / w as f64, ideal);
    println!("arithmetic code: {} bits, {:0w$b}; bits per day {:.4}", k, x, k as f64 / 30.0, w = k as usize);
    println!("Huffman {} bits; two fixed bits a day {}; 30 x H = {:.4}; 10^30 is about 2^{:.1}", huff, 2 * 30, 30.0 * h, (d as f64).log2());
    let (mut lo, mut hi, mut rows5) = (0.0f64, 1.0f64, Vec::new());
    for c in MONTH.chars().take(5) {
        let s = idx(c);
        (lo, hi) = (lo + (hi - lo) * CUM[s] as f64 / 10.0, lo + (hi - lo) * (CUM[s] + F[s]) as f64 / 10.0);
        rows5.push((c, lo, hi));
    }
    let r: Vec<String> = rows5.iter().map(|(c, a, b)| format!("{} [{:.5}, {:.5})", c, a, b)).collect();
    println!("first 5 days: {}", r.join("; "));
    let (_, w5, d5, k5, x5) = encode(&MONTH[..5]);
    let h5: u64 = MONTH.chars().take(5).map(|c| HUFF[idx(c)]).sum();
    println!("5 days: width {:.5}, log2(1/width) {:.4}, code {:0w$b} = {:.5}, Huffman {} bits", w5 as f64 / d5 as f64,
        (d5 as f64 / w5 as f64).log2(), x5, x5 as f64 / 2f64.powi(k5 as i32), h5, w = k5 as usize);
    let fig: Vec<String> = rows5.iter().map(|(_, a, b)| format!("{:.1}-{:.1}", 30.0 + 300.0 * a, 30.0 + 300.0 * b)).collect();
    println!("figure, x = 30 + 300 v: {} code {:.1}", fig.join(" "), 30.0 + 300.0 * x5 as f64 / 2f64.powi(k5 as i32));
    let (mut total, mut ok) = (0.0f64, 0);              // every 5-day message, encoded and decoded
    for m in 0..243usize {
        let msg: String = (0..5).map(|j| NAMES[m / 3usize.pow(j) % 3]).collect();
        let (_, wm, dm, km, xm) = encode(&msg);
        total += wm as f64 / dm as f64 * km as f64;
        if decode(xm, km, 5) == msg { ok += 1; }
    }
    println!("all 243 five-day messages: {} decode; average {:.4} bits a day; formula {:.4}", ok, total / 5.0, by_formula(5));
    let ns = [1, 2, 5, 10, 30, 100];
    let e: Vec<String> = ns.iter().map(|&n| format!("n={} {:.4}", n, by_formula(n))).collect();
    println!("expected bits a day, coding n days as one: {}", e.join(", "));
    let month: Vec<usize> = MONTH.chars().map(idx).collect();
    let (pairs, bits) = lz78(&month);
    let show: Vec<String> = unlz78(&pairs).iter().zip(&pairs).enumerate().map(|(i, (q, &(j, s)))| format!("{}=({},{}):{}", // phrase = (earlier, new):bits
        text(q), j, if s == NONE { '-' } else { NAMES[s] }, usize::BITS - i.leading_zeros() + if s == NONE { 0 } else { 2 })).collect();
    println!("LZ78 on the month: {} phrases, {} bits: {}", pairs.len(), bits, show.join(" "));
    let spell = [[0.95, 0.025, 0.025], [0.2, 0.8, 0.0], [0.2, 0.0, 0.8]]; // weather in spells
    let indep = [[0.8, 0.1, 0.1]; 3];                                     // every day fresh
    let ent = |r: &[f64; 3]| r.iter().filter(|&&q| q > 0.0).map(|&q| q * (1.0 / q).log2()).sum::<f64>();
    let rate = 0.8 * ent(&spell[0]) + 0.2 * ent(&spell[1]);
    let (mut lo, mut hi, mut day) = (0.0f64, 1.0f64, 0); // mistake: ordinary floats for the interval
    while lo < hi {
        let s = month[day % 30];
        (lo, hi, day) = (lo + (hi - lo) * CUM[s] as f64 / 10.0, lo + (hi - lo) * (CUM[s] + F[s]) as f64 / 10.0, day + 1);
    }
    println!("mistakes: one day at a time {:.0} bits; no length sent, 33 days decode as {}; floats collapse to zero width on day {}",
        by_formula(1) * 30.0, decode(x, k, 33), day);
    println!("spells: after C, C 0.95, S 0.025, R 0.025; S or R stays 0.8, else C; entropy rate {:.4} bits a day", rate);
    let (mut bs, mut bi, mut model, mut nn) = (0.0, 0.0, 0.0, 0.0);
    for n in [1000usize, 10000, 100000, 300000] {
        let (sp, iid) = (weather(n, &spell), weather(n, &indep));
        let ((ps, b1), (pi, b2)) = (lz78(&sp), lz78(&iid));
        assert!(unlz78(&ps).concat() == sp && unlz78(&pi).concat() == iid);
        let mut prev = 0;                               // start after a cloudy day
        model = 0.0;
        for &s in &sp { (model, prev) = (model + (1.0 / spell[prev][s]).log2(), s); }
        let hs: u64 = sp.iter().map(|&s| HUFF[s]).sum();
        (nn, bs, bi) = (n as f64, b1 as f64, b2 as f64);
        println!("n={}: LZ78 spells {:.4}, independent {:.4}; Huffman spells {:.4}; spell-model ideal {:.4}",
            n, bs / nn, bi / nn, hs as f64 / nn, model / nn);
    }
    assert!(w == 8u128.pow(24) && d == 10u128.pow(30) && k as f64 == (30.0 * 5f64.log2() - 42.0).ceil()); // width = product
    assert!(decode(x, k, 30) == MONTH && (k as u64) < huff && huff < 60);           // round trip; beats Huffman
    assert!(ok == 243 && (total / 5.0 - by_formula(5)).abs() < 1e-12);               // brute force = formula
    assert!(ns.iter().all(|&n| h <= by_formula(n) && by_formula(n) < h + 1.0 / n as f64)); // never below H, within 1 bit
    assert!(unlz78(&pairs).concat() == month && bits > k as u64 && bits == (1..=pairs.len())    // LZ78 formula
        .map(|i| (i as f64).log2().ceil() as u64 + 2).sum::<u64>() - 2 * (pairs[pairs.len() - 1].1 == NONE) as u64);
    assert!(model / nn < bs / nn && bs / nn < h && bi / nn > h && (model / nn - rate).abs() < 0.01 && rate < bs / nn);
    println!("ALL CHECKS PASS");
}
