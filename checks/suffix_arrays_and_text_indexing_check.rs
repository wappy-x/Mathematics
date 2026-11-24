// Suffix arrays -- the check behind the card.  std only: no sort, no binary_search.
// Roads: suffixes sorted by a written-out merge sort against prefix doubling;
// neighbour LCPs compared directly against Kasai's method; distinct substrings by
// formula against a brute-force set; pattern counts by binary search, full scan and BWT.
use std::collections::HashSet;

fn splitmix(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn msort<T: Clone>(a: &[T], less: &mut dyn FnMut(&T, &T) -> bool) -> Vec<T> {
    if a.len() <= 1 { return a.to_vec(); }
    let (l, r) = (msort(&a[..a.len() / 2], less), msort(&a[a.len() / 2..], less));
    let (mut out, mut i, mut j) = (Vec::new(), 0, 0);
    while i < l.len() && j < r.len() {
        if less(&r[j], &l[i]) { out.push(r[j].clone()); j += 1; } else { out.push(l[i].clone()); i += 1; }
    }
    out.extend_from_slice(&l[i..]); out.extend_from_slice(&r[j..]); out
}

fn lcp_direct(t: &[u8], a: usize, b: usize) -> usize { // letters shared, one by one
    let mut h = 0; while a.max(b) + h < t.len() && t[a + h] == t[b + h] { h += 1; } h }

fn naive_sa(t: &[u8], cnt: &mut usize) -> Vec<usize> {
    let n = t.len(); let idx: Vec<usize> = (0..n).collect();
    msort(&idx, &mut |&i: &usize, &j: &usize| {
        let h = lcp_direct(t, i, j); *cnt += (h + 1).min(n - i.max(j));
        i + h == n || (j + h < n && t[i + h] < t[j + h])
    })
}

fn bucket(idx: &[usize], key: &dyn Fn(usize) -> usize, size: usize) -> Vec<usize> {
    let mut b: Vec<Vec<usize>> = vec![Vec::new(); size]; for &i in idx { b[key(i)].push(i); }
    b.concat()
}

fn doubling(t: &[u8]) -> (Vec<usize>, Vec<(usize, Vec<usize>)>) {
    let (n, mut k, mut log, mut rank) = (t.len(), 1, Vec::new(), t.iter().map(|&c| c as usize).collect::<Vec<_>>());
    loop {
        let r = rank.clone(); let mx = *r.iter().max().unwrap();
        let key = |i: usize| (r[i] as i64, if i + k < n { r[i + k] as i64 } else { -1 });
        let sa = bucket(&(0..n).collect::<Vec<_>>(), &|i| (key(i).1 + 1) as usize, mx + 2);
        let sa = bucket(&sa, &|i| r[i], mx + 1); rank = vec![0; n];
        for a in 1..n { rank[sa[a]] = rank[sa[a - 1]] + (key(sa[a]) != key(sa[a - 1])) as usize; }
        log.push((2 * k, rank.clone()));
        if rank[sa[n - 1]] == n - 1 { return (sa, log); } k *= 2;
    }
}

fn kasai(t: &[u8], sa: &[usize], cnt: &mut usize) -> Vec<usize> {
    let (n, mut h, mut rank, mut lcp) = (t.len(), 0, vec![0; t.len()], vec![0; t.len()]);
    for (a, &i) in sa.iter().enumerate() { rank[i] = a; }
    for i in 0..n {
        if rank[i] == 0 { h = 0; continue; }
        let (j, h0) = (sa[rank[i] - 1], h);
        while i.max(j) + h < n && t[i + h] == t[j + h] { h += 1; }
        *cnt += h - h0 + (i.max(j) + h < n) as usize;
        lcp[rank[i]] = h; h = h.saturating_sub(1); // the next suffix keeps all but one letter
    }
    lcp
}

fn bound(t: &[u8], sa: &[usize], p: &[u8], upper: bool, cnt: &mut usize) -> (usize, usize) {
    let (mut lo, mut hi, mut looks) = (0, sa.len(), 0);
    while lo < hi {
        let mid = (lo + hi) / 2; looks += 1;
        let s = &t[sa[mid]..(sa[mid] + p.len()).min(t.len())];
        let q = (0..s.len()).find(|&q| s[q] != p[q]).unwrap_or(s.len());
        *cnt += (q + 1).min(s.len());
        let c = if q == p.len() { 0 } else if q == s.len() || s[q] < p[q] { -1 } else { 1 };
        if c < 0 || (upper && c == 0) { lo = mid + 1; } else { hi = mid; }
    }
    (lo, looks)
}

fn scan(t: &[u8], p: &[u8], cnt: &mut usize) -> usize {
    let mut hits = 0;
    for i in 0..=t.len() - p.len() {
        let q = (0..p.len()).find(|&q| t[i + q] != p[q]).unwrap_or(p.len());
        *cnt += (q + 1).min(p.len()); hits += (q == p.len()) as usize;
    }
    hits
}

fn bwt(t: &[u8]) -> Vec<u8> {
    let s = [t, b"$"].concat(); let n = s.len();
    doubling(&s).0.iter().map(|&i| s[(i + n - 1) % n]).collect()
}

fn smaller(l: &[u8], c: u8) -> usize { l.iter().filter(|&&x| x < c).count() }
fn occ(l: &[u8], c: u8, upto: usize) -> usize { l[..upto].iter().filter(|&&x| x == c).count() }
fn backward_count(l: &[u8], p: &[u8]) -> usize { // FM-index style: pattern right to left
    let (mut lo, mut hi) = (0, l.len());
    for &c in p.iter().rev() {
        let cc = smaller(l, c); lo = cc + occ(l, c, lo); hi = cc + occ(l, c, hi);
        if lo >= hi { return 0; }
    }
    hi - lo
}

fn inverse_bwt(l: &[u8]) -> String { // walk last-to-first from the "$" row
    let (mut row, mut out) = (0, Vec::new());
    for _ in 0..l.len() - 1 { let c = l[row]; out.push(c); row = smaller(l, c) + occ(l, c, row); }
    out.reverse(); String::from_utf8(out).unwrap()
}

fn index_report(t: &[u8], p: &[u8]) -> (Vec<usize>, Vec<usize>, usize, [usize; 4], usize, usize, usize) {
    let mut c = [0usize; 4]; let (sa, log) = doubling(t);
    assert!(naive_sa(t, &mut c[0]) == sa, "doubling and merge sort disagree");
    let lcp = kasai(t, &sa, &mut c[1]); assert!(c[1] <= 2 * t.len(), "Kasai compared over 2n letters");
    for a in 1..t.len() { assert!(lcp[a] == lcp_direct(t, sa[a - 1], sa[a]), "Kasai"); }
    let (lo, l1) = bound(t, &sa, p, false, &mut c[2]); let (hi, l2) = bound(t, &sa, p, true, &mut c[2]);
    let h = scan(t, p, &mut c[3]); assert!(hi - lo == h && h == backward_count(&bwt(t), p), "pattern counts disagree");
    (sa, lcp, log.len(), c, lo, hi, l1 + l2)
}

fn join(v: &[usize]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn s(v: &[u8]) -> String { String::from_utf8(v.to_vec()).unwrap() }
fn distinct(t: &[u8]) -> usize { // brute force: every substring into a set, then count
    let mut set = HashSet::new(); for i in 0..t.len() { for j in i + 1..=t.len() { set.insert(&t[i..j]); } } set.len()
}

fn main() {
    let w = b"banana"; let n = w.len();
    let (sa, lcp, rounds, c, lo, hi, looks) = index_report(w, b"ana");
    let (sufs, sum): (Vec<String>, usize) = (sa.iter().map(|&i| s(&w[i..])).collect(), lcp.iter().sum());
    println!("banana suffix array: {} | suffixes: {}", join(&sa), sufs.join(" "));
    println!("banana LCP: {} | sum {}", join(&lcp), sum);
    for (k, r) in doubling(w).1 { println!("doubling: ranks by first {} letters: {}", k, join(&r)); }
    println!("rounds {}; merge sort letters compared {}; Kasai letters compared {}", rounds, c[0], c[1]);
    assert!(sa == vec![5, 3, 1, 0, 4, 2] && lcp == vec![0, 1, 3, 0, 0, 2]);
    let brute = distinct(w); println!("distinct substrings: {} - {} = {}; brute force {}", n * (n + 1) / 2, sum, n * (n + 1) / 2 - sum, brute);
    assert!(n * (n + 1) / 2 - sum == brute && brute == 15);
    let starts = msort(&sa[lo..hi], &mut |a: &usize, b: &usize| a < b);
    println!("search 'ana': ranks {} to {}, count {}, starts {} | looks {}, letters {} (promise {}); scan letters {}", lo, hi - 1, hi - lo, join(&starts), looks, c[2], 2 * 3 * ((n as f64).log2() as usize + 1), c[3]);
    let b = bwt(w); println!("BWT of banana$: {} | inverse: {} | backward count 'ana': {}", s(&b), inverse_bwt(&b), backward_count(&b, b"ana"));
    assert!(s(&b) == "annb$aa" && inverse_bwt(&b) == "banana");
    let words: Vec<&str> = "love night blue river fire home dream summer road heart rain gold city moon light song".split(' ').collect();
    let (mut st, mut cat, mut plays) = (2026u64, Vec::new(), Vec::new());
    for _ in 0..50 { let a = splitmix(&mut st); let b = splitmix(&mut st); cat.push(format!("{} {}", words[(a % 16) as usize], words[(b % 16) as usize])); }
    for _ in 0..2000 { let z = splitmix(&mut st); plays.push(cat[(z % 50) as usize].clone()); }
    let t = plays.join("|").into_bytes(); let nn = t.len();
    let (_, lcp, rounds, c, lo, hi, looks) = index_report(&t, b"love"); let sum: usize = lcp.iter().sum();
    println!("play log: 2000 plays of 50 titles, seed 2026, {} characters, {} doubling rounds", nn, rounds);
    println!("merge sort letters compared {} ({:.2} per n log2 n); Kasai {} (2n = {}); longest repeat {}", c[0], c[0] as f64 / (nn as f64 * (nn as f64).log2()), c[1], 2 * nn, lcp.iter().max().unwrap());
    println!("distinct substrings: {} - {} = {}", nn * (nn + 1) / 2, sum, nn * (nn + 1) / 2 - sum);
    let p3 = &t[..300]; let l3 = kasai(p3, &doubling(p3).0, &mut 0); let f3 = 300 * 301 / 2 - l3.iter().sum::<usize>(); let b3 = distinct(p3);
    println!("first 300 characters: formula {}, brute force {}", f3, b3); assert!(f3 == b3);
    let pr = 2 * 4 * ((nn as f64).log2() as usize + 1); assert!(c[2] <= pr, "search broke its promise");
    println!("search 'love': count {}, looks {}, letters {} (promise {}); scan letters {}", hi - lo, looks, c[2], pr, c[3]);
    for m in [250, 500, 1000, 2000] {
        let u = plays[..m].join("|").into_bytes(); let r = index_report(&u, b"love");
        println!("chart, {} plays, {} characters, count {}, suffix array letters {}, scan letters {}", m, u.len(), r.5 - r.4, r.3[2], r.3[3]);
    }
    let big = 1_000_000 * (nn as f64 / 2000.0).round() as usize; let lk = (big as f64).log2() as usize + 1; // titles as long as the log's own plays
    println!("library: 1000000 titles x {} characters ({} / 2000 plays, rounded) = {}; looks per boundary {}; letters at most {}; array bytes {}", big / 1_000_000, nn, big, lk, 2 * lk * 4, 4 * big);
    println!("breaks: n(n+1)/2 without LCP = {}, true 15", n * (n + 1) / 2);
    let id: Vec<usize> = (0..n).collect(); let u0 = bound(w, &id, b"na", false, &mut 0).0; let u1 = bound(w, &id, b"na", true, &mut 0).0;
    println!("breaks: binary search on unsorted starts 0..5 for 'na': count {}, true {}", u1 - u0, scan(w, b"na", &mut 0));
    let rot = |x: &str| -> String {
        let r: Vec<String> = (0..x.len()).map(|i| format!("{}{}", &x[i..], &x[..i])).collect(); msort(&r, &mut |a: &String, b: &String| a < b).iter().map(|r| r.chars().last().unwrap()).collect()
    };
    println!("breaks: rotations without $: banana -> {}, nanaba -> {}", rot("banana"), rot("nanaba"));
    for m in [250, 500, 1000] {
        let (a, mut c) = (vec![b'a'; m], 0); naive_sa(&a, &mut c); println!("breaks: merge sort on {} a's: letters compared {}, doubling rounds {}", m, c, doubling(&a).1.len());
    }
    println!("ALL CHECKS PASS");
}
