// Huffman codes -- the same check as source_coding_and_huffman_check.py, in Rust.  std only.
// A weather station sends one 4-way forecast a day.  Roads: Huffman merging; brute force
// over every code of words up to 3 bits; the entropy bound; Kraft's sum; McMillan's counting
// argument on a code that breaks the rule; and 10,000 synthetic days drawn with SplitMix64.
const NAMES: [&str; 4] = ["Sun", "Cloud", "Rain", "Snow"];

fn entropy(p: &[f64]) -> f64 { -p.iter().map(|q| q * q.log2()).sum::<f64>() }
fn avg(p: &[f64], lens: &[usize]) -> f64 { p.iter().zip(lens).map(|(q, l)| q * *l as f64).sum() }
fn kraft(lens: &[usize]) -> f64 { lens.iter().map(|l| 2f64.powi(-(*l as i32))).sum() }

fn huffman(p: &[f64], log: &mut Vec<(f64, f64, f64)>) -> Vec<String> {
    // each node: (weight, creation number, [(symbol, code so far)]); merge the two lightest
    let mut nodes: Vec<(f64, usize, Vec<(usize, String)>)> =
        p.iter().enumerate().map(|(i, q)| (*q, i, vec![(i, String::new())])).collect();
    let mut made = p.len();
    while nodes.len() > 1 {
        let mut pair = Vec::new();
        for _ in 0..2 {                          // linear scan: lightest, ties to the older node
            let mut best = 0;
            for j in 1..nodes.len() {
                let (a, b) = (&nodes[j], &nodes[best]);
                if a.0 < b.0 || (a.0 == b.0 && a.1 < b.1) { best = j; }
            }
            pair.push(nodes.remove(best));
        }
        let (wa, wb) = (pair[0].0, pair[1].0);
        let mut codes: Vec<(usize, String)> = pair[0].2.iter().map(|(s, c)| (*s, format!("0{}", c))).collect();
        codes.extend(pair[1].2.iter().map(|(s, c)| (*s, format!("1{}", c))));
        log.push((wa, wb, wa + wb));
        nodes.push((wa + wb, made, codes));
        made += 1;
    }
    (0..p.len()).map(|i| nodes[0].2.iter().find(|(s, _)| *s == i).unwrap().1.clone()).collect()
}

fn brute(p: &[f64]) -> (f64, usize, usize) {
    // every ordered choice of 4 distinct words of 1 to 3 bits; keep the prefix-free ones
    let mut words = Vec::new();
    for n in 1..=3usize { for v in 0..(1usize << n) { words.push(format!("{:0width$b}", v, width = n)); } }
    let (mut tried, mut free, mut best) = (0, 0, 99.0f64);
    for a in &words { for b in &words { for c in &words { for d in &words {
        let code = [a, b, c, d];
        let distinct = (0..4).all(|i| (0..4).all(|j| i == j || code[i] != code[j]));
        if !distinct { continue; }
        tried += 1;
        if code.iter().any(|x| code.iter().any(|y| x != y && y.starts_with(x.as_str()))) { continue; }
        free += 1;
        let lens: Vec<usize> = code.iter().map(|w| w.len()).collect();
        best = best.min(avg(p, &lens));
    } } } }
    (best, tried, free)
}

fn decode(bits: &str, code: &[String]) -> Vec<usize> {
    let (mut out, mut word) = (Vec::new(), String::new());
    for b in bits.chars() {
        word.push(b);
        if let Some(i) = code.iter().position(|c| *c == word) { out.push(i); word.clear(); }
    }
    out
}

fn splitmix(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, (z ^ (z >> 31)) >> 11)
}

fn counts(lens: &[usize], k: usize) -> Vec<u64> {     // k-forecast messages, counted by total bits
    let mut a = vec![1u64];
    for _ in 0..k {
        let mut b = vec![0u64; a.len() + 3];
        for (m, c) in a.iter().enumerate() { for l in lens { b[m + l] += c; } }
        a = b;
    }
    a
}

fn line(label: &str, v: f64) { println!("{:<44}{:>12.6}", label, v); }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn lens_of(code: &[String]) -> Vec<usize> { code.iter().map(|c| c.len()).collect() }

fn main() {
    let summer = [0.5, 0.25, 0.125, 0.125];
    let autumn = [0.4, 0.3, 0.2, 0.1];
    let mut log = Vec::new();
    let code = huffman(&summer, &mut log);
    let lens = lens_of(&code);
    for i in 0..4 { println!("{:<6} p {:.3}  code {:<4} length {}  p*length {:.3}  p*log2(1/p) {:.3}",
        NAMES[i], summer[i], code[i], lens[i], summer[i] * lens[i] as f64, -summer[i] * summer[i].log2()); }
    for (wa, wb, w) in &log { println!("merge {:.3} + {:.3} -> {:.3}", wa, wb, w); }
    let msum: f64 = log.iter().map(|t| t.2).sum(); line("sum of the merged weights", msum);
    let slots: Vec<String> = lens.iter().map(|l| (1 << (3 - l)).to_string()).collect();
    println!("slots at depth 3 claimed: {} of 8", slots.join(" "));
    let (h, l) = (entropy(&summer), avg(&summer, &lens));
    let (best, tried, free) = brute(&summer);
    line("entropy H, bits a day", h); line("Huffman average L, bits a day", l);
    line("brute force best prefix-free L", best); line("fixed 2-bit code, bits a day", 2.0);
    line("Kraft sum of the Huffman code", kraft(&lens));
    println!("codes tried {}, prefix-free {}", tried, free);
    println!("a year: fixed {} bits, Huffman {:.2} bits, saved {:.2}", 365 * 2, 365.0 * l, 365.0 * (2.0 - l));
    let week = [0usize, 0, 1, 2, 0, 3, 1];
    let bits: String = week.iter().map(|s| code[*s].as_str()).collect();
    println!("week Sun Sun Cloud Rain Sun Snow Cloud -> {} ({} bits, fixed 14)", bits, bits.len());
    let (mut state, mut days, cum) = (2026u64, Vec::new(), [0.5, 0.75, 0.875, 1.0]);
    for _ in 0..10000 {
        let (s, r) = splitmix(state); state = s;
        let u = r as f64 / 2f64.powi(53);
        days.push((0..4).find(|i| u < cum[*i]).unwrap());
    }
    let stream: String = days.iter().map(|s| code[*s].as_str()).collect();
    let sim = stream.len() as f64 / 10000.0;
    let se = (summer.iter().zip(&lens).map(|(q, k)| q * (k * k) as f64).sum::<f64>() - l * l).sqrt() / 100.0;
    println!("10000 synthetic days (seed 2026): {} bits, {:.4} a day, standard error {:.4}", stream.len(), sim, se);
    let back_ok = decode(&stream, &code) == days;
    println!("decoded back exactly: {}", tf(back_ok));
    let bad: Vec<String> = ["0", "1", "10", "11"].iter().map(|s| s.to_string()).collect();
    let blens = lens_of(&bad);
    line("wrong: code 0,1,10,11, Kraft sum", kraft(&blens)); line("wrong: code 0,1,10,11, average", avg(&summer, &blens));
    println!("  Rain -> {}, Cloud Sun -> {}{}", bad[2], bad[1], bad[0]);
    let (cb, cg) = (counts(&blens, 3), counts(&lens, 3));
    println!("  3 forecasts in 4 bits: {} messages, {} bit strings", cb[4], 1 << 4);
    let ratio = cg.iter().enumerate().filter(|(_, c)| **c > 0).map(|(m, c)| *c as f64 / 2f64.powi(m as i32)).fold(0.0, f64::max);
    println!("  Huffman code: 3-forecast messages per bit string, at most {:.6}", ratio);
    let rev: Vec<usize> = lens.iter().rev().cloned().collect();
    line("wrong: short codes to the rare days", avg(&summer, &rev));
    let shan: Vec<usize> = autumn.iter().map(|q: &f64| (-q.log2()).ceil() as usize).collect();
    let mut alog = Vec::new();
    let acode = huffman(&autumn, &mut alog);
    let alens = lens_of(&acode);
    let (ha, la) = (entropy(&autumn), avg(&autumn, &alens));
    let abest = brute(&autumn).0;
    println!("autumn odds 0.4 0.3 0.2 0.1, Huffman code {}", acode.join(" "));
    let am: Vec<String> = alog.iter().map(|(a, b, _)| format!("{:.1}+{:.1}", a, b)).collect();
    let asum: f64 = alog.iter().map(|t| t.2).sum(); println!("autumn merges {}, sum {:.6}", am.join(", "), asum);
    line("autumn entropy H", ha); line("autumn Huffman L", la); line("autumn brute force best L", abest);
    println!("autumn Shannon lengths {}, Kraft {:.4}", shan.iter().map(|s| s.to_string()).collect::<Vec<_>>().join(" "), kraft(&shan));
    line("autumn Shannon-length average", avg(&autumn, &shan));
    let pairs: Vec<f64> = autumn.iter().flat_map(|a| autumn.iter().map(move |b| a * b)).collect();
    let l2 = avg(&pairs, &lens_of(&huffman(&pairs, &mut Vec::new()))) / 2.0;
    line("autumn, two days per codeword, bits a day", l2);
    let desert = [0.9, 0.1];
    line("desert 0.9 dry 0.1 rain: entropy H", entropy(&desert));
    for k in 1..=3 {
        let mut blk = vec![1.0f64];
        for _ in 0..k { blk = blk.iter().flat_map(|a| desert.iter().map(move |b| a * b)).collect(); }
        let lb = avg(&blk, &lens_of(&huffman(&blk, &mut Vec::new()))) / k as f64;
        line(&format!("desert, {}-day blocks, bits a day", k), lb);
    }
    let mut pos: Vec<(String, (i32, i32))> = vec![(String::new(), (210, 40))];
    for c in ["0", "1", "10", "11", "110", "111"] {
        let (x, y) = pos.iter().find(|(k, _)| k.as_str() == &c[..c.len() - 1]).unwrap().1;
        let step = 100 / (1 << (c.len() - 1));
        pos.push((c.to_string(), (x + if c.ends_with('1') { step } else { -step }, y + 60)));
    }
    let fig: Vec<String> = pos.iter().map(|(c, (x, y))| format!("{}=({},{})", if c.is_empty() { "root" } else { c }, x, y)).collect();
    println!("figure, {}", fig.join(" "));

    assert!((l - best).abs() < 1e-12 && (la - abest).abs() < 1e-12, "Huffman must match brute force");
    assert!((msum - l).abs() < 1e-12 && (asum - la).abs() < 1e-12, "merges");
    assert!(h <= l + 1e-12 && l < h + 1.0 && ha <= la && la < ha + 1.0, "entropy bound");
    assert!((kraft(&lens) - 1.0).abs() < 1e-12 && kraft(&shan) <= 1.0, "Kraft");
    assert!((sim - h).abs() < 5.0 * se && back_ok, "simulation");
    assert!(cb[4] > 1 << 4 && ratio <= 1.0, "McMillan counting");
    assert!(ha <= l2 && l2 < la && (h - 1.75).abs() < 1e-12, "pairs close the gap");
    println!("ALL CHECKS PASS");
}
