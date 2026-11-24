// Finding a pattern in text -- the same check as the Python, in Rust.  No crates.
// A synthetic play log: 1,000,000 plays, each written as one letter for the playlist it came
// from (A, B or C, coded 1, 2, 3), drawn by SplitMix64 with seed 2026.  Search it for ABABAC
// three ways.  Every cost counts letter comparisons, never time.
fn splitmix(s: u64) -> (u64, u64) {
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn code(w: &str) -> Vec<u64> { w.chars().map(|c| " ABC".find(c).unwrap() as u64).collect() }
fn commas(x: u64) -> String {
    let d = x.to_string(); let mut out = String::new();
    for (i, ch) in d.chars().enumerate() { if i > 0 && (d.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn commas1(x: f64) -> String { let t = (x * 10.0).round() as u64; format!("{}.{}", commas(t / 10), t % 10) }
fn join(v: &[u64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn failure(p: &[u64]) -> (Vec<usize>, u64) {   // pi[q]: longest proper border of p[0..q]
    let (mut pi, mut k, mut cost) = (vec![0usize; p.len()], 0usize, 0u64);
    for q in 1..p.len() {
        loop {
            cost += 1;
            if p[k] == p[q] { k += 1; break; }
            if k == 0 { break; }
            k = pi[k - 1];
        }
        pi[q] = k;
    }
    (pi, cost)
}
fn borders_brute(p: &[u64]) -> Vec<usize> {    // road 2: try every length, longest first
    (0..p.len()).map(|q| (0..=q).filter(|&l| p[..l] == p[q + 1 - l..q + 1]).max().unwrap()).collect()
}
fn kmp(t: &[u64], p: &[u64], pi: &[usize], mut trace: Option<&mut Vec<u64>>) -> (Vec<usize>, u64) {
    let (mut hits, mut q, mut cost) = (Vec::new(), 0usize, 0u64);
    for i in 0..t.len() {                        // the text index i only ever goes up
        loop {
            cost += 1;
            if p[q] == t[i] { q += 1; break; }
            if q == 0 { break; }
            q = pi[q - 1];
        }
        if let Some(tr) = trace.as_deref_mut() { tr.push(q as u64); }
        if q == p.len() { hits.push(i + 1 - p.len()); q = pi[q - 1]; }
    }
    (hits, cost)
}
fn naive(t: &[u64], p: &[u64]) -> (Vec<usize>, u64) {   // slide one place, re-read
    let (mut hits, mut cost) = (Vec::new(), 0u64);
    for s in 0..=t.len() - p.len() {
        let mut j = 0;
        while j < p.len() { cost += 1; if t[s + j] != p[j] { break; } j += 1; }
        if j == p.len() { hits.push(s); }
    }
    (hits, cost)
}
fn h(w: &[u64], b: u64, md: u64) -> u64 {        // fingerprint: w in base b, mod p
    w.iter().fold(0u64, |acc, &c| ((acc as u128 * b as u128 + c as u128) % md as u128) as u64)
}
fn rabin_karp(t: &[u64], p: &[u64], b: u64, md: u64, verify: bool) -> (Vec<usize>, u64, u64) {
    let m = p.len(); let mut top = 1u64;
    for _ in 0..m - 1 { top = ((top as u128 * b as u128) % md as u128) as u64; }
    let (hp, mut ht) = (h(p, b, md), h(&t[..m], b, md));
    let (mut hits, mut fals, mut cost) = (Vec::new(), 0u64, 0u64);
    for s in 0..=t.len() - m {
        if s > 0 {                                // the roll
            let drop = ((t[s - 1] as u128 * top as u128) % md as u128) as u64;
            ht = (((ht + md - drop) as u128 * b as u128 + t[s + m - 1] as u128) % md as u128) as u64;
        }
        if ht != hp { continue; }
        if !verify { hits.push(s); continue; }
        let mut j = 0;
        while j < m { cost += 1; if t[s + j] != p[j] { break; } j += 1; }
        if j == m { hits.push(s); } else { fals += 1; }
    }
    (hits, fals, cost)
}
fn main() {
    let (p, m) = (code("ABABAC"), 6usize);
    let (pi, build) = failure(&p);
    let piu: Vec<u64> = pi.iter().map(|&x| x as u64).collect();
    println!("pattern ABABAC; failure table {} ({} comparisons to build)", join(&piu), build);
    assert!(pi == borders_brute(&p) && pi == vec![0, 0, 1, 2, 3, 0]);
    let hand = code("ABABABACABABAC");
    let mut tr = Vec::new(); let (hk, ck) = kmp(&hand, &p, &pi, Some(&mut tr)); let (hn, cn) = naive(&hand, &p);
    println!("hand log ABABABACABABAC, state after each letter: {}", join(&tr));
    println!("hand log matches start at {:?}: KMP {} comparisons, naive {}", hk, ck, cn);
    let (hr, fr, cr) = rabin_karp(&hand, &p, 10, 101, true);
    let wins: Vec<u64> = (0..=hand.len() - m).map(|s| h(&hand[s..s + m], 10, 101)).collect();
    println!("hand fingerprints, base 10 mod 101: pattern {} windows {}", h(&p, 10, 101), join(&wins));
    let roll = (h(&hand[..m], 10, 1_000_000_000) - hand[0] * 100_000) * 10 + hand[m];   // no mod: digits show
    println!("hand roll, window 0 to 1: ({} - {} x 100000) x 10 + {} = {}", h(&hand[..m], 10, 1_000_000_000), hand[0], hand[m], roll);
    let (nt, _) = kmp(&hand, &p, &[0; 6], None);
    println!("hand Rabin-Karp: matches {:?}, false hits {}, check comparisons {}", hr, fr, cr);
    println!("hand log, no table (restart the pattern, keep the text): {:?}", nt);
    let (_, c1) = kmp(&code("ABABAA"), &p, &pi, None); let ap = code("AAAAAB"); let (_, c2) = kmp(&code("AAAAAC"), &ap, &failure(&ap).0, None);
    println!("one letter can cost more: ABABAA takes {}, {} on its last A; AAAAAC searched for AAAAAB takes {}, {} = m on the C", c1, c1 - 5, c2, c2 - 5);
    assert!(roll == h(&hand[1..m + 1], 10, 1_000_000_000) && roll == 212121);
    assert!(hk == vec![2, 8] && hn == hk && hr == hk && fr == 1 && nt == vec![8] && c1 == 9 && c2 == 11);
    let (mut s, mut log) = (2026u64, Vec::with_capacity(1_000_000));
    for _ in 0..1_000_000 { let (s2, z) = splitmix(s); s = s2; log.push(z % 3 + 1); }
    let n = log.len();
    let (s2, z) = splitmix(s); s = s2; let b0 = z % 101;
    let (_, z) = splitmix(s); let b1 = z % 1_000_000_007;
    let (hits_k, cost_k) = kmp(&log, &p, &pi, None); let (hits_n, cost_n) = naive(&log, &p);
    let (hits_r, false_r, ver_r) = rabin_karp(&log, &p, b1, 1_000_000_007, true);
    let nk = hits_k.len() as u64;
    println!("log of {} plays: {} matches; first at {}, last at {}", commas(n as u64), commas(nk), commas(hits_k[0] as u64), commas(hits_k[hits_k.len() - 1] as u64));
    println!("comparisons: KMP {} ({:.4} per play), naive {} ({:.4})", commas(cost_k), cost_k as f64 / n as f64, commas(cost_n), cost_n as f64 / n as f64);
    println!("Rabin-Karp, p = 1,000,000,007, base {}: false hits {}, check comparisons {}", commas(b1), false_r, commas(ver_r));
    println!("bound on expected false hits, (n - m + 1) x 5 / p = {:.4}", (n - m + 1) as f64 * 5.0 / 1_000_000_007.0);
    assert!(hits_k == hits_n && hits_k == hits_r && cost_k <= 2 * n as u64 && false_r == 0);
    let alt: Vec<u64> = (0..1_000_000).map(|i| (i % 2 + 1) as u64).collect();   // ABAB...
    let (ak, ca) = kmp(&alt, &p, &pi, None); let (an, cna) = naive(&alt, &p);
    println!("alternating log ABAB...: matches {}, KMP {}, naive {}", ak.len(), commas(ca), commas(cna));
    assert!(ak.is_empty() && an.is_empty() && ca <= 2 * n as u64 && cna == 6 * 499_998 + 499_997);
    let (mut count, mut idx) = (vec![0u64; 729], 0usize); // road 2 for the fingerprints: window types, exact
    for (i, &c) in log.iter().enumerate() {
        idx = (idx * 3 + c as usize - 1) % 729;
        if i >= m - 1 { count[idx] += 1; }
    }
    let allw: Vec<Vec<u64>> = (0..729).map(|v: usize| {
        let mut w = Vec::new(); let mut x = v;
        for _ in 0..m { w.push((x % 3 + 1) as u64); x /= 3; }
        w.reverse(); w
    }).collect();
    let tab = allw.iter().filter(|w| failure(w).0 == borders_brute(w)).count(); // road 2 for the table: every word
    println!("failure tables: linear build equals brute force for {} of {} six-letter words", tab, allw.len());
    let hpp: Vec<u64> = (0..101).map(|b| h(&p, b, 101)).collect();
    let bad: Vec<u64> = allw.iter().map(|w| if *w == p { 0 } else {
        (0..101).filter(|&b| h(w, b, 101) == hpp[b as usize]).count() as u64 }).collect();
    let worst = *bad.iter().max().unwrap();
    let wi = bad.iter().position(|&x| x == worst).unwrap();
    let name: String = allw[wi].iter().map(|&c| " ABC".as_bytes()[c as usize] as char).collect();
    println!("every 6-letter word against ABABAC, mod 101: at most {} bad bases of 101 (bound 5)", worst);
    println!("a word with the most: {} ; words with none: {}", name, bad.iter().filter(|&&x| x == 0).count() - 1);
    let (_, f0, _) = rabin_karp(&log, &p, b0, 101, true);
    let f0_types: u64 = (0..729).filter(|&v| allw[v] != p && h(&allw[v], b0, 101) == hpp[b0 as usize]).map(|v| count[v]).sum();
    let nonmatch = (n - m + 1) as u64 - nk;
    let mean_f = (0..729).map(|v| count[v] * bad[v]).sum::<u64>() as f64 / 101.0;
    println!("mod 101, base {}: false hits by rolling {}, by counting window types {}", b0, commas(f0), commas(f0_types));
    println!("mod 101, averaged over all 101 bases: {} false hits; bound 5/101 x {} = {}", commas1(mean_f), commas(nonmatch), commas1(5.0 * nonmatch as f64 / 101.0));
    assert!(worst <= (m - 1) as u64 && f0 == f0_types && mean_f <= 5.0 * nonmatch as f64 / 101.0 && tab == allw.len());
    let (_, f1, _) = rabin_karp(&log, &p, 1, 1_000_000_007, true); let (r2, _, _) = rabin_karp(&log, &p, b0, 101, false);
    println!("base 1 (fingerprint = letter sum): false hits {}", commas(f1));
    println!("mod 101 with no check: reports {} matches, true {}", commas(r2.len() as u64), commas(nk));
    let (nl, _) = kmp(&log, &p, &[0; 6], None);
    println!("no failure table on the log: finds {} of {}", commas(nl.len() as u64), commas(nk));
    let psum: u64 = p.iter().sum();
    let f1_sum: u64 = (0..729).filter(|&v| allw[v].iter().sum::<u64>() == psum && allw[v] != p).map(|v| count[v]).sum();
    assert!(f1 == f1_sum && r2.len() as u64 == nk + f0 && (nl.len() as u64) < nk);
    let mut rows = Vec::new();
    for mm in [50u64, 100, 150, 200, 250, 300] {   // worst case: AAA...A searched for AA...AB
        let tt = vec![1u64; 5000];
        let mut pp = vec![1u64; mm as usize - 1]; pp.push(2);
        let (_, ck2) = kmp(&tt, &pp, &failure(&pp).0, None); let (_, cn2) = naive(&tt, &pp);
        assert!(cn2 == mm * (5000 - mm + 1) && ck2 == 2 * 5000 - mm + 1);
        rows.push((mm, cn2, ck2));
    }
    let ms: Vec<String> = rows.iter().map(|r| format!("m={}", r.0)).collect();
    let ns: Vec<String> = rows.iter().map(|r| commas(r.1)).collect();
    let ks: Vec<String> = rows.iter().map(|r| commas(r.2)).collect();
    println!("growth, text A x 5,000, pattern A..AB of length m: {}", ms.join(" "));
    println!("  naive, m(n - m + 1): {}", ns.join(" "));
    println!("  KMP, 2n - m + 1: {}", ks.join(" "));
    println!("ALL CHECKS PASS");
}
