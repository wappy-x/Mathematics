// Bloom filters and a distinct-count sketch -- the check behind the card.
// std only. Hashes and random numbers are written out below.
fn mix64(z: u64) -> u64 { // SplitMix64's scrambler: 64 bits in, 64 well-mixed bits out
    let mut z = z.wrapping_add(0x9E3779B97F4A7C15);
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn url_hash(s: &str) -> u64 { // FNV-1a over the bytes, then scrambled
    let mut h: u64 = 0xCBF29CE484222325;
    for b in s.bytes() { h = (h ^ b as u64).wrapping_mul(0x100000001B3); }
    mix64(h)
}
fn positions(s: &str, k: u64, m: u64) -> Vec<usize> { // k bit positions from two hashes
    let h1 = url_hash(s); let h2 = mix64(h1) | 1;
    (0..k).map(|i| (h1.wrapping_add(i.wrapping_mul(h2)) % m) as usize).collect()
}
fn fp_formula(n: f64, m: f64, k: f64) -> f64 { (1.0 - (-k * n / m).exp()).powf(k) }
fn url(i: usize) -> String { format!("https://shop.example/item/{}", i) }
fn grp(x: f64, dec: usize) -> String { // thousands separators, like Python's {:,}
    let s = format!("{:.*}", dec, x);
    let (int, frac) = match s.find('.') { Some(p) => (&s[..p], &s[p..]), None => (&s[..], "") };
    let (sign, digits) = if int.starts_with('-') { ("-", &int[1..]) } else { ("", int) };
    let mut out = String::new();
    for (i, c) in digits.chars().enumerate() {
        if i > 0 && (digits.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    format!("{}{}{}", sign, out, frac)
}
fn hit(bits: &[u8], s: &str, k: u64) -> bool { positions(s, k, bits.len() as u64).iter().all(|&q| bits[q] == 1) }
fn false_alarms(bits: &[u8], k: u64, tests: usize) -> usize {
    (0..tests).filter(|&j| hit(bits, &url(10_000_000 + j), k)).count()
}
fn kmv(hashes: &[u64], t: usize) -> Vec<u64> { // the t smallest different values seen, smallest first
    let mut low: Vec<u64> = Vec::new();
    for &h in hashes {
        if (low.len() == t && h >= low[t - 1]) || low.contains(&h) { continue; }
        let mut j = low.len();
        while j > 0 && low[j - 1] > h { j -= 1; }
        low.insert(j, h);
        if low.len() > t { low.pop(); }
    }
    low
}
fn estimate(low: &[u64], t: usize) -> f64 { (t - 1) as f64 / (low[t - 1] as f64 / 2f64.powi(64)) }

fn main() {
    let ln2 = 2f64.ln();
    println!("== sizing: 10 million URLs, 1 in 100 false alarms ==");
    let (n, p) = (10_000_000f64, 0.01f64);
    let bpi = (1.0 / p).ln() / (ln2 * ln2);
    println!("bits per URL ln(1/p)/(ln 2)^2 = {:.4}   m = {} bits = {:.2} MB", bpi, grp(n * bpi, 0), n * bpi / 8e6);
    println!("best k = (m/n) ln 2 = {:.4}   floor log2(1/p) = {:.4} bits per URL", bpi * ln2, (1.0 / p).log2());
    let (m, k) = (96_000_000f64, 7u64);
    let kf = k as f64;
    println!("12 MB = {} bits, {:.1} per URL; k = {}: kn/m = {:.6}   zeros e^-kn/m = {:.6}   false alarms = {:.6}",
        grp(m, 0), m / n, k, kf * n / m, (-kf * n / m).exp(), fp_formula(n, m, kf));
    println!("one 8-byte fingerprint per URL = {:.0} MB   filter bytes per URL = {:.1}   filter over floor = 1/ln 2 = {:.4}",
        8.0 * n / 1e6, m / 8.0 / n, 1.0 / ln2);
    let c1: Vec<String> = (0..11).map(|j| format!("{:.2}", 100.0 * fp_formula(2e6 * j as f64, m, kf))).collect();
    println!("chart1 (n = 0..20M),{}", c1.join(","));
    let c2: Vec<String> = (1..13).map(|j| format!("{:.2}", 100.0 * fp_formula(n, m, j as f64))).collect();
    println!("chart2 (k = 1..12),{}", c2.join(","));
    assert!((fp_formula(n, m, kf) - 0.01).abs() < 0.0005, "12 MB with 7 hashes should give about 1 in 100");
    let mut best = 1;
    for j in 2..13 { if fp_formula(n, m, j as f64) < fp_formula(n, m, best as f64) { best = j; } }
    assert!(best as f64 == (m / n * ln2).round(), "best k is (m/n) ln 2");

    println!("== road 2: every arrangement of a tiny filter, m = 8, k = 2, n = 3 ==");
    let (tm, tk, tn) = (8u64, 2u32, 3u32);
    let total = tm.pow(tk * tn);
    let (mut tot_fp, mut tot_set) = (0f64, 0f64);
    for c0 in 0..total { // every choice of 6 bit positions
        let (mut c, mut bits) = (c0, 0u64);
        for _ in 0..tk * tn { bits |= 1 << (c % tm); c /= tm; }
        let s = bits.count_ones() as f64;
        tot_set += s; tot_fp += (s / tm as f64).powi(tk as i32);
    }
    let (ex_fp, ex_set) = (tot_fp / total as f64, tot_set / total as f64);
    let q0 = (1.0 - 1.0 / tm as f64).powi((tk * tn) as i32);
    println!("exact false alarms {:.6}   (1-(1-1/m)^kn)^k {:.6}   (1-e^-kn/m)^k {:.6}",
        ex_fp, (1.0 - q0).powi(tk as i32), fp_formula(tn as f64, tm as f64, tk as f64));
    println!("average bits set: counted {:.6}   m(1-(1-1/m)^kn) {:.6}", ex_set, tm as f64 * (1.0 - q0));
    assert!((ex_set - tm as f64 * (1.0 - q0)).abs() < 1e-12, "each bit stays 0 with chance (1-1/m)^kn");
    assert!(ex_fp > (1.0 - q0).powi(tk as i32), "the exact rate sits just above the textbook product");

    println!("== road 3: a real filter at 1/1000 scale: 10,000 URLs in 96,000 bits ==");
    let (sn, sm, tests) = (10_000usize, 96_000usize, 100_000usize);
    let mut bits = vec![0u8; sm];
    for i in 0..sn { for q in positions(&url(i), k, sm as u64) { bits[q] = 1; } }
    let filled: usize = bits.iter().map(|&b| b as usize).sum();
    let fr = filled as f64 / sm as f64;
    println!("bits set {} of {} = {:.6}   predicted {:.6}", filled, sm, fr, 1.0 - (-kf * sn as f64 / sm as f64).exp());
    let fa = false_alarms(&bits, k, tests);
    let rate = fa as f64 / tests as f64;
    let f1 = fp_formula(sn as f64, sm as f64, kf);
    let se = (f1 * (1.0 - f1) / tests as f64).sqrt();
    println!("unseen URLs tested {}: false alarms {} = {:.6}   formula {:.6}   (set fraction)^{} {:.6}   standard error {:.6}",
        tests, fa, rate, f1, k, fr.powi(k as i32), se);
    assert!((rate - f1).abs() < 4.0 * se, "measured false alarms disagree with the formula");
    assert!((0..sn).all(|i| hit(&bits, &url(i), k)), "a stored URL was missed");
    let mut kept = bits.clone();
    for q in positions(&url(0), k, sm as u64) { kept[q] = 0; }
    let lost = (1..sn).filter(|&i| !hit(&kept, &url(i), k)).count();
    println!("delete URL 0 by clearing its {} bits: other stored URLs now missed = {}", k, lost);
    for i in sn..2 * sn { for q in positions(&url(i), k, sm as u64) { bits[q] = 1; } }
    let fa2 = false_alarms(&bits, k, tests) as f64 / tests as f64;
    let f2 = fp_formula(2.0 * sn as f64, sm as f64, kf);
    println!("overfilled with 20,000 URLs: false alarms {:.6}   formula {:.6}", fa2, f2);
    assert!((fa2 - f2).abs() < 0.005, "overfilled rate disagrees with the formula");

    println!("== what breaks (full size, formula) ==");
    println!("20 million URLs, same filter: {:.6}", fp_formula(2.0 * n, m, kf));
    println!("one hash, k = 1: {:.6}   twenty hashes: {:.6}", fp_formula(n, m, 1.0), fp_formula(n, m, 20.0));
    println!("12 MB read as 12 million bits, k = 7: {:.6}", fp_formula(n, 12e6, kf));
    let fm = (n * (1.0 / p).log2()).round(); let fk = (fm / n * ln2).round();
    println!("only log2(1/p) bits per URL ({} bits), best k = {}: {:.6}", grp(fm, 0), fk, fp_formula(n, fm, fk));

    println!("== distinct visitors: keep the t smallest hash values ==");
    let (t, pool, reqs, salt) = (1024usize, 500_000usize, 1_000_000usize, 0x5EEDu64);
    let mut seen = vec![false; pool]; let mut stream = Vec::with_capacity(reqs); let mut rng: u64 = 2026;
    for _ in 0..reqs { // synthetic: a few visitors return often, most rarely
        rng = rng.wrapping_add(0x9E3779B97F4A7C15);
        let x = (mix64(rng) >> 11) as f64 / 2f64.powi(53);
        let v = (pool as f64 * x * x) as usize; seen[v] = true; stream.push(mix64(v as u64 ^ salt));
    }
    let true_d = seen.iter().filter(|&&b| b).count() as f64;
    let low = kmv(&stream, t); let est = estimate(&low, t);
    let u = low[t - 1] as f64 / 2f64.powi(64);
    println!("requests {}   true distinct visitors {}   sketch {} values = {} bytes", grp(reqs as f64, 0), grp(true_d, 0), t, grp(8.0 * t as f64, 0));
    println!("exact list of visitors at 8 bytes each = {} bytes", grp(8.0 * true_d, 0));
    println!("t-th smallest / 2^64 = {:.8}   estimate (t-1)/U = {}   error {:+.2}%   promised spread 1/sqrt(t-2) = {:.2}%",
        u, grp(est, 0), 100.0 * (est / true_d - 1.0), 100.0 / ((t - 2) as f64).sqrt());
    println!("wrong: t/U = {}   wrong: one smallest only, 1/U = {}", grp(t as f64 / u, 0), grp(1.0 / (low[0] as f64 / 2f64.powi(64)), 0));
    let (b3, e256) = (1000f64.ln() / (ln2 * ln2), estimate(&kmv(&stream, 256), 256));
    println!("try: p = 0.001: {:.4} bits per URL = {:.2} MB   t = 256: estimate {}, error {:+.2}%, promised spread {:.2}%",
        b3, n * b3 / 8e6, grp(e256, 0), 100.0 * (e256 / true_d - 1.0), 100.0 / 254f64.sqrt());
    assert!((est / true_d - 1.0).abs() < 4.0 / ((t - 2) as f64).sqrt(), "estimate outside four promised spreads");

    println!("== road 2 for the sketch: 100 independent hashes of 10,000 visitors, t = 64 ==");
    let (d2, t2, runs) = (10_000u64, 64usize, 100u64);
    let ests: Vec<f64> = (1..=runs).map(|s| {
        let hs: Vec<u64> = (0..d2).map(|v| mix64(v ^ s.wrapping_mul(0xA24BAED4963EE407))).collect();
        estimate(&kmv(&hs, t2), t2)
    }).collect();
    let d2f = d2 as f64;
    let mean = ests.iter().sum::<f64>() / runs as f64;
    let rms = (ests.iter().map(|e| (e / d2f - 1.0).powi(2)).sum::<f64>() / runs as f64).sqrt();
    let theory = ((d2f - 1.0) * (t2 - 1) as f64 / (d2f * (t2 - 2) as f64) - 1.0).sqrt();
    println!("mean estimate {}   rms error {:.2}%   exact theory {:.2}%   1/sqrt(t-2) {:.2}%",
        grp(mean, 1), 100.0 * rms, 100.0 * theory, 100.0 / ((t2 - 2) as f64).sqrt());
    assert!((mean - d2f).abs() < 4.0 * d2f * theory / (runs as f64).sqrt(), "estimator looks biased");
    assert!((rms / theory - 1.0).abs() < 0.3, "spread disagrees with theory");

    println!("== road 3 for the sketch: the average, 400 more hashes of 10,000 visitors, t = 4 ==");
    let (t4, runs4) = (4usize, 400u64); // few marks: dropping the -1 would show as a 1/(t-1) = 33% bias
    let m4 = (runs + 1..=runs + runs4).map(|s| {
        let hs: Vec<u64> = (0..d2).map(|v| mix64(v ^ s.wrapping_mul(0xA24BAED4963EE407))).collect();
        estimate(&kmv(&hs, t4), t4)
    }).sum::<f64>() / runs4 as f64;
    let tol4 = 4.0 * d2f * ((d2f - 1.0) * (t4 - 1) as f64 / (d2f * (t4 - 2) as f64) - 1.0).sqrt() / (runs4 as f64).sqrt();
    let wrong4 = m4 * t4 as f64 / (t4 - 1) as f64;
    println!("mean (t-1)/U {}   allowed {} +/- {}   wrong: mean t/U {}, {:.0}% high", grp(m4, 1), grp(d2f, 0), grp(tol4, 1), grp(wrong4, 1), 100.0 / (t4 - 1) as f64);
    assert!((m4 - d2f).abs() < tol4 && tol4 < (wrong4 - d2f).abs(), "estimator biased, or the test cannot see a bias of 1/(t-1)");
    println!("ALL CHECKS PASS");
}
