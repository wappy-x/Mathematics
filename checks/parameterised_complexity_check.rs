// Parameterised complexity -- the same check as the Python, in Rust.  No crates.
// A festival street plan: 60 junctions, 84 streets, at most 10 officers.  An officer at a
// junction watches every street that meets it.  Roads to the answer: (1) the bounded search
// tree; (2) the kernel, then the same tree on what is left; (3) certificates: a cover checked
// street by street, and 10 streets sharing no junction, which force at least 10 officers;
// (4) brute force over every set of junctions, on 300 small random plans.
type St = Vec<(usize, usize)>;

fn festival(n: usize) -> St {     // hubs 0-9, partners 10-19, junction 20 meets every hub, 21.. side streets
    let mut st = Vec::new();
    for j in 21..n {
        if j < 33 { st.push((0, j)) }                            // 12 side streets off square 0
        else if j < 45 { st.push((1, j)) }                       // 12 off square 1
        else { st.push((2 + j % 8, j)); st.push((2 + (j + 3) % 8, j)) }   // the rest join two smaller hubs
    }
    for h in 0..10 { st.push((20, h)) }
    for h in 0..10 { st.push((h, (h + 1) % 10)) }
    for h in 0..10 { st.push((h, 10 + h)) }
    st
}

fn tree(st: &St, k: usize, on: &mut Vec<bool>, cnt: &mut [u64; 2]) -> bool {   // ROAD 1
    cnt[0] += 1;                                                 // nodes of the search tree
    let mut open = None;
    for &(u, v) in st {
        cnt[1] += 1;                                             // steps: streets looked at
        if !on[u] && !on[v] { open = Some((u, v)); break }
    }
    let (u, v) = match open { None => return true, Some(e) => e };   // None: every street is watched
    if k == 0 { return false }                                   // a street unwatched and nobody left
    for w in [u, v] {
        on[w] = true;
        if tree(st, k - 1, on, cnt) { return true }
        on[w] = false;
    }
    false
}

fn kernel(n: usize, st0: &St, k0: usize, at_least: bool) -> (Vec<usize>, St, usize, u64, bool) {
    let (mut forced, mut steps, mut st, mut k) = (Vec::new(), 0u64, st0.clone(), k0);
    loop {                                                       // ROAD 2, part one: shrink the plan first
        let mut deg = vec![0usize; n];
        for &(u, v) in &st { deg[u] += 1; deg[v] += 1 }
        steps += st.len() as u64;
        let b: Vec<usize> = (0..n).filter(|&w| deg[w] > 0 && (deg[w] > k || (at_least && deg[w] == k))).collect();
        if b.is_empty() || b.len() > k { let alive = b.len() <= k && st.len() <= k * k; return (forced, st, k, steps, alive) }
        forced.extend(&b); k -= b.len();
        st.retain(|&(u, v)| !b.contains(&u) && !b.contains(&v));
    }
}

fn solve(n: usize, st: &St, k: usize, at_least: bool) -> (bool, Vec<usize>, Vec<usize>, usize, usize, u64, u64) {
    let (forced, rest, k2, steps, alive) = kernel(n, st, k, at_least);   // ROAD 2: kernel, then the tree
    let mut on: Vec<bool> = (0..n).map(|w| forced.contains(&w)).collect();
    let mut cnt = [0u64; 2];
    let ok = alive && tree(&rest, k2, &mut on, &mut cnt);
    (ok, (0..n).filter(|&w| on[w]).collect(), forced, rest.len(), k2, steps + cnt[1], cnt[0])
}

fn matching(st: &St) -> St {      // ROAD 3: streets sharing no junction; each needs an officer of its own
    let (mut used, mut m) = (Vec::new(), Vec::new());
    for &(u, v) in st { if !used.contains(&u) && !used.contains(&v) { m.push((u, v)); used.push(u); used.push(v) } }
    m
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn sets_up_to(n: u128, k: u128) -> u128 {                        // sets of at most k junctions out of n
    let (mut c, mut total) = (1u128, 1u128);
    for i in 1..=k { c = c * (n - i + 1) / i; total += c }
    total
}
fn splitmix(s: u64) -> (u64, u64) {  // SplitMix64, written out, so Python and Rust draw the same plans
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn main() {
    let (n, kk) = (60usize, 10usize);
    let st = festival(n);
    let deg: Vec<usize> = (0..n).map(|w| st.iter().filter(|&&(u, v)| u == w || v == w).count()).collect();
    let (mut on, mut c10) = (vec![false; n], [0u64; 2]);
    let yes10 = tree(&st, kk, &mut on, &mut c10);
    let cover: Vec<usize> = (0..n).filter(|&w| on[w]).collect();
    let watched = st.iter().all(|(u, v)| cover.contains(u) || cover.contains(v));   // separate verifier
    let mut c9 = [0u64; 2];
    let yes9 = tree(&st, kk - 1, &mut vec![false; n], &mut c9);
    let (ok, kcov, forced, left, k2, ksteps, knodes) = solve(n, &st, kk, false);
    let (ok9, _, forced9, left9, k29, ksteps9, _) = solve(n, &st, kk - 1, false);
    let mt = matching(&st);
    println!("plan: {} junctions, {} streets, budget k = {} officers", n, st.len(), kk);
    println!("streets meeting junctions 0, 1, 20: {}, {}, {}; largest elsewhere {}", deg[0], deg[1], deg[20], deg[2..20].iter().max().unwrap());
    println!("road 1, tree, k = 10: {}, officers at {:?}; {} nodes, {} steps; bound 2^11 - 1 = {}", yn(yes10), cover, c10[0], c10[1], (1u64 << 11) - 1);
    println!("road 1, tree, k = 9:  {}; {} nodes, {} steps; bound 2^10 - 1 = {}", yn(yes9), c9[0], c9[1], (1u64 << 10) - 1);
    println!("road 2, kernel, k = 10: forced {:?}; {} streets removed, {} left for k = {}, limit {}", forced, st.len() - left, left, k2, k2 * k2);
    println!("road 2, kernel then tree, k = 10: {}, {:?}; {} nodes, {} steps; ceiling (k+1)m + 2^(k+1) k^2 = {}",
        yn(ok), kcov, knodes, ksteps, (kk + 1) * st.len() + (1usize << (kk + 1)) * kk * kk);
    println!("road 2, kernel, k = 9: forced {:?}; {} streets left for k = {}: {}; {} steps", forced9, left9, k29, yn(ok9), ksteps9);
    println!("road 3, verifier: every street watched by {} officers: {}", cover.len(), yn(watched));
    println!("road 3, {} streets sharing no junction: {:?}", mt.len(), mt);
    println!("other parameter: largest set of junctions with no street between any two = {} - {} = {}", n, cover.len(), n - cover.len());
    println!("brute force: sets of at most 10 junctions out of 60 = {}, times {} streets each", sets_up_to(60, 10), st.len());

    let (mut seed, mut agree, mut hist, mut worst) = (2026u64, 0, [0usize; 11], 0.0f64);
    for _trial in 0..300 {        // ROAD 4: 300 random plans on 10 junctions, each pair a street 30% of the time
        let mut sm: St = Vec::new();
        for u in 0..10 { for v in u + 1..10 {
            let (s, z) = splitmix(seed); seed = s;
            if z % 100 < 30 { sm.push((u, v)) }
        } }
        let brute = (0..1024u32).filter(|m| sm.iter().all(|&(u, v)| m >> u & 1 == 1 || m >> v & 1 == 1))
            .map(|m| m.count_ones() as usize).min().unwrap();
        let mut t = 0;
        loop {
            let mut cnt = [0u64; 2];
            if tree(&sm, t, &mut vec![false; 10], &mut cnt) { break }
            worst = worst.max(cnt[0] as f64 / ((1u64 << (t + 1)) - 1) as f64); t += 1;
        }
        let kt = (0..11).find(|&t| solve(10, &sm, t, false).0).unwrap();
        if brute == t && t == kt { agree += 1 }
        hist[brute] += 1;
    }
    println!("road 4, 300 random plans: brute force, tree and kernel agree on {}; covers of size 0-10: {:?}", agree, hist);
    println!("road 4, largest tree as a share of its bound 2^(k+1) - 1: {:.3}", worst);

    println!("growth at k = 10: before saying yes, every road must see that every street is watched");
    println!("     n     m  tree nodes  tree steps  kernel+tree steps  log10 brute-force sets");
    let mut rows = Vec::new();
    for size in [60usize, 120, 240, 480, 960] {
        let s2 = festival(size);
        let mut c = [0u64; 2];
        tree(&s2, kk, &mut vec![false; size], &mut c);
        let r = solve(size, &s2, kk, false);
        let lb = (sets_up_to(size as u128, 10) as f64).log10();
        println!("{:>6}{:>6}{:>12}{:>12}{:>19}{:>24.2}", size, s2.len(), c[0], c[1], r.5, lb);
        rows.push((size, s2.len() as u64, c[0], c[1], r.5, lb));
    }
    let line = |f: &dyn Fn(&(usize, u64, u64, u64, u64, f64)) -> f64| rows.iter().map(|r| format!("{:.2}", f(r))).collect::<Vec<_>>().join(" ");
    println!("chart, log10 tree steps: {}", line(&|r| (r.3 as f64).log10()));
    println!("chart, log10 kernel+tree steps: {}", line(&|r| (r.4 as f64).log10()));
    println!("chart, log10 brute-force sets: {}", line(&|r| r.5));

    let wrong = solve(n, &st, kk, true);                        // mistake: force a junction meeting exactly k streets
    println!("mistake, force at >= k streets: forced {:?}, answer {}", wrong.2, yn(wrong.0));
    println!("mistake, both ends of {} separate streets: {} officers", mt.len(), 2 * mt.len());
    println!("mistake, branch on every junction in or out: 2^60 = {} leaves", 1u64 << 60);
    let ring: St = (0..200).map(|i| (i, (i + 1) % 200)).collect();   // hypothesis fails: k is not small
    let rm = matching(&ring);
    let fine = ring.iter().all(|&(u, v)| u % 2 == 0 || v % 2 == 0);
    println!("k not small: a ring of 200 needs {}; tree bound 2^101 - 1 = {} nodes; two-sided, so the matching settles it; the 100 even junctions watch all: {}",
        rm.len(), (1u128 << 101) - 1, yn(fine));

    assert!(yes10 && watched && cover.len() == kk);              // tree's cover passes a separate check
    let mut ends: Vec<usize> = mt.iter().flat_map(|&(u, v)| [u, v]).collect();
    ends.sort(); ends.dedup();
    assert!(mt.len() == kk && ends.len() == 2 * kk && !yes9);    // 10 separate streets: 9 cannot do
    assert!(ok && !ok9 && kcov == cover);                        // kernel road agrees with the tree road
    assert!(agree == 300 && worst <= 1.0 && c9[0] <= (1 << kk) - 1);   // brute force agrees; trees under 2^(k+1) - 1
    let k64 = kk as u64;
    assert!(rows.iter().all(|r| r.4 <= (k64 + 1) * r.1 + (1u64 << (k64 + 1)) * k64 * k64));   // within (k+1)m + 2^(k+1) k^2
    assert!(!wrong.0 && rm.len() == 100 && fine);                // the wrong rule says no; the ring needs 100
    println!("ALL CHECKS PASS");
}
