// Lebesgue measure -- the check behind the card.  Rust std only.
// The cycle path is the open stretch (0, 1) km with a pothole at every fraction
// p/q strictly between 0 and 1.  Every length is an exact integer count of
// 1/D km, with D = 840 * 4000 * 2^22, so each pothole and gap edge is a whole
// count.  The darts come from the same SplitMix64 as the Python check.
use std::collections::{BTreeMap, BTreeSet};

const D: i128 = 840 * 4000 * (1 << 22);

fn dec(num: i128, den: i128, d: u32) -> String { // exact decimal, rounded half up
    let n = (num * 10i128.pow(d) * 2 + den) / (2 * den);
    let s = format!("{:0>w$}", n, w = d as usize + 1);
    let k = s.len() - d as usize;
    if d == 0 { s } else { format!("{}.{}", &s[..k], &s[k..]) }
}
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a } else { gcd(b, a % b) } }
fn potholes() -> Vec<(i128, i128)> {             // p/q in lowest terms, by q then p
    let mut v = Vec::new();
    for q in 2..=8 { for p in 1..q { if gcd(p, q) == 1 { v.push((p, q)); } } }
    v
}
// eps = 1/e km.  Gap k is (eps/2) * 2^-k wide, or eps/2 wide when flat.
fn cuts(e: i128, n: usize, halving: bool) -> Vec<(i128, i128)> {
    potholes().iter().take(n).enumerate().map(|(i, &(p, q))| {
        let half = if halving { D / (4 * e) >> (i + 1) } else { D / (4 * e) };
        (D * p / q - half, D * p / q + half)
    }).collect()
}
fn inner_by_merging(e: i128, n: usize, halving: bool) -> i128 { // road 1
    let (a, b) = (D / (4 * e), D - D / (4 * e));
    let mut c = cuts(e, n, halving);
    c.sort();
    let (mut covered, mut end) = (0, a);
    for (lo, hi) in c {
        let (lo, hi) = (lo.max(end), hi.min(b));
        if hi > lo { covered += hi - lo; end = hi; }
    }
    (b - a) - covered
}
fn inner_by_formula(e: i128, n: usize, halving: bool) -> i128 { // road 2
    let half = D / (2 * e);
    D - half - if halving { half - (half >> n) } else { n as i128 * half }
}
fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn inner_by_darts(e: i128, n: usize, draws: u32, seed: u64) -> u32 { // road 3
    let fl = |x: i128| ((x as u128) << 64) / D as u128;
    let ce = |x: i128| (((x as u128) << 64) + D as u128 - 1) / D as u128;
    let (lo_a, hi_b) = (ce(D / (4 * e)), fl(D - D / (4 * e)));
    let gaps: Vec<(u128, u128)> = cuts(e, n, true).iter().map(|&(l, h)| (fl(l), ce(h))).collect();
    let (mut hits, mut s) = (0, seed);
    for _ in 0..draws {
        let r = splitmix(&mut s) as u128;
        if lo_a <= r && r <= hi_b && !gaps.iter().any(|&(t, u)| t < r && r < u) { hits += 1; }
    }
    hits
}
fn main() {
    let (e, n, draws, seed) = (1000i128, 21usize, 200000u32, 20260929u64);
    let q = potholes();
    println!("Lebesgue measure: the cycle path (0, 1) km minus a pothole at every fraction");
    let first: Vec<String> = q[..8].iter().map(|(p, q)| format!("{}/{}", p, q)).collect();
    println!("potholes, first 8 in order: {}", first.join(" "));
    println!("potholes with denominator up to 8: {}", q.len());
    let g: Vec<String> = (1..5).map(|k| dec(100000, 2 * e * (1 << k), 3)).collect();
    println!("gap around pothole k, k = 1..4 (cm): {}", g.join(" "));
    println!("outer, G = (-{}, {}) km: length {} km; G minus path {} km",
        dec(1, 2 * e, 4), dec(2 * e + 1, 2 * e, 4), dec(e + 1, e, 3), dec(1, e, 3));
    println!("inner, ends trimmed {} m each: [{}, {}] = {} km",
        dec(1000, 4 * e, 2), dec(1, 4 * e, 5), dec(4 * e - 1, 4 * e, 5), dec(2 * e - 1, 2 * e, 4));
    println!("inner, all gaps together: at most {} km, so K has length at least {} km",
        dec(1, 2 * e, 4), dec(e - 1, e, 3));
    println!("squeeze, eps = {}: {} km <= length of path <= {} km; shrinking eps leaves {} km",
        dec(1, e, 3), dec(e - 1, e, 3), dec(e + 1, e, 3), dec(1, 1, 0));
    for &k in &[1usize, 2, 3, 5, 10, 21] {
        let (m, f) = (inner_by_merging(e, k, true), inner_by_formula(e, k, true));
        assert_eq!(m, f);                        // no two gaps overlap
        assert!(m * e >= D * (e - 1));           // above the proved floor 1 - eps
        println!("stage n={}: merging {} km, formula {} km", k, dec(m, D, 13), dec(f, D, 13));
    }
    let hits = inner_by_darts(e, n, draws, seed);
    let exact = inner_by_merging(e, n, true) as f64 / D as f64;
    let se = (exact * (1.0 - exact) / draws as f64).sqrt();
    assert!((hits as f64 / draws as f64 - exact).abs() < 4.0 * se);
    println!("darts, {} throws, seed {}: {} hits, estimate {} km, standard error {:.6}",
        draws, seed, hits, dec(hits as i128, draws as i128, 5), se);
    let mm: Vec<String> = (0..11).map(|k| dec((D - inner_by_merging(e, k, true)) * 1000000, D, 2)).collect();
    println!("chart, mm cut away after n = 0..10 potholes: {}", mm.join(" "));
    let fig: Vec<String> = q.iter().map(|&(p, q)| dec(20 * q + 320 * p, q, 1)).collect(); // 0 km at 20 px, 1 km at 340 px
    println!("figure, px: G {} to {}, K {} to {}, potholes {}", dec(40 * e - 320, 2 * e, 2), dec(680 * e + 320, 2 * e, 2),
        dec(80 * e + 320, 4 * e, 2), dec(1360 * e - 320, 4 * e, 2), fig.join(" "));
    let mut d = 1i128;
    while !(10000 * ((3 * d) / 10 + 1) < 3001 * d) { d += 1; }
    let p = (3 * d) / 10 + 1;
    let inside = |a: i128, b: i128| 3 * b < 10 * a && 10000 * a < 3001 * b;
    assert!(inside(p, d) && !(1..d).any(|b| (0..=b).any(|a| inside(a, b))));
    println!("breaks, intervals only: pothole {}/{} sits inside (0.3, 0.3001), so no interval fits and inside length is 0 km", p, d);
    let (fm, ff) = (inner_by_merging(e, n, false), inner_by_formula(e, n, false));
    assert_eq!(fm, ff);
    println!("breaks, flat {} m gaps: {} potholes cut {} m, K is {} km; gap every fraction and K is empty",
        dec(1000, 2 * e, 1), n, dec(1000 * n as i128, 2 * e, 1), dec(fm, D, 3));
    let (mu, nu) = ([1i128, 1, 1, 1], [2i128, 0, 0, 2]); // in quarters
    let size = |m: &[i128; 4], s: u8| (0..4).filter(|i| s >> i & 1 == 1).map(|i| m[i]).sum::<i128>();
    let mut sig: BTreeSet<u8> = [0u8, 15, 0b0011, 0b0101].iter().copied().collect();
    loop {
        let mut grow: BTreeSet<u8> = sig.iter().map(|s| 15 ^ s).collect();
        for s in &sig { for t in &sig { grow.insert(s | t); } }
        if grow.is_subset(&sig) { break; }
        sig.extend(grow);
    }
    let bad = sig.iter().filter(|&&s| size(&mu, s) != size(&nu, s)).count();
    assert!([3u8, 5].iter().all(|&c| size(&mu, c) == size(&nu, c))); // they agree on the class C
    assert!(sig.len() == 16 && bad == 16 - [1usize, 2, 1].iter().map(|c| c * c).sum::<usize>());
    println!("breaks, four points: sigma(C) has {} sets; on {{1,2}} and {{1,3}} both give {}; on {{1}} {} vs {}; disagree on {}",
        sig.len(), dec(size(&mu, 3), 4, 1), dec(size(&mu, 1), 4, 2), dec(size(&nu, 1), 4, 1), bad);
    let f: BTreeMap<u8, i128> = [(0u8, 0i128), (3, 0), (12, 2), (15, 2)].iter().copied().collect();
    let nulls: Vec<u8> = f.iter().filter(|(_, &m)| m == 0).map(|(&s, _)| s).collect();
    let mut done: BTreeMap<u8, BTreeSet<i128>> = BTreeMap::new();
    let mut reps = 0;
    for x in 0u8..16 {
        for (&b, &m) in &f {
            if nulls.iter().any(|z| (x ^ b) & (15 ^ z) == 0) { done.entry(x).or_default().insert(m); reps += 1; }
        }
    }
    let two_block: Vec<u8> = (0u8..16).filter(|x| x & 12 == 0 || x & 12 == 12).collect();
    assert!(done.keys().copied().collect::<Vec<u8>>() == two_block && reps == 16);
    assert!(done.values().all(|v| v.len() == 1));
    println!("completion, four points: {} old sets, {} completed, {} representatives, {{3}} included: {}",
        f.len(), done.len(), reps, if done.contains_key(&4) { "True" } else { "False" });
    println!("try, eps = {}: stage n=21 closed set {} km, floor {} km",
        dec(1, 100, 2), dec(inner_by_merging(100, n, true), D, 13), dec(99, 100, 2));
    println!("All checks passed.");
}
