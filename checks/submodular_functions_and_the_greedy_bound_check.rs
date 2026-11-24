// Submodular functions -- the same check as the Python, in Rust.  No crates.
// Part 1 maximises: book k = 2 of 3 acts to reach the most fan groups; greedy against every pair and the 1 - (1 - 1/k)^k promise.
// Part 2 minimises: which acts move to the tent (costs in £ thousand), by the Lovasz extension, against all 8 sets and a dual certificate.
// A set of acts is a bit mask: A = 1, B = 2, C = 4.  A set of fan groups is a bit mask too: group g is bit g.
fn word(s: u8, names: &str) -> String {
    let w: String = names.chars().enumerate().filter(|(i, _)| s >> i & 1 == 1).map(|(_, c)| c).collect();
    if w.is_empty() { "none".to_string() } else { w }
}
fn cover(s: u8, acts: &[u32]) -> i64 { acts.iter().enumerate().filter(|(i, _)| s >> i & 1 == 1).fold(0u32, |u, (_, a)| u | a).count_ones() as i64 }
fn bits(groups: &[u32]) -> u32 { groups.iter().fold(0, |u, g| u | 1 << g) }

fn lattice_and_dr(f: &dyn Fn(u8) -> i64) -> (usize, usize) {   // both definitions of submodular, over every pair of sets
    let (mut lat, mut dr) = (0, 0);
    for s in 0..8u8 { for t in 0..8u8 {
        if f(s) + f(t) >= f(s | t) + f(s & t) { lat += 1 }
        if s & t == s { for x in 0..3 { let b = 1u8 << x; if t & b == 0 && f(s | b) - f(s) >= f(t | b) - f(t) { dr += 1 } } }
    } }
    (lat, dr)
}

fn greedy(f: &dyn Fn(u8) -> i64, k: usize, names: &str, log: bool) -> (u8, i64, Vec<u8>) {   // ties to the act listed first
    let (mut s, mut best_bound, mut path) = (0u8, i64::MAX, vec![0u8]);
    for i in 0..k {
        let gains: Vec<(usize, i64)> = (0..names.len()).filter(|&x| s >> x & 1 == 0).map(|x| (x, f(s | 1 << x) - f(s))).collect();
        let mut top: Vec<i64> = gains.iter().map(|g| g.1).collect(); top.sort_by(|a, b| b.cmp(a)); top.truncate(k);
        let run = f(s) + top.iter().sum::<i64>(); best_bound = best_bound.min(run);   // OPT <= f(S) + the k largest gains
        let x = gains.iter().fold(gains[0], |b, &g| if g.1 > b.1 { g } else { b }).0;
        if log {
            let gl: Vec<String> = gains.iter().map(|&(a, g)| format!("{} {}", &names[a..a + 1], g)).collect();
            println!("greedy step {}: gains {}; take {}; run bound {}", i + 1, gl.join(", "), &names[x..x + 1], run);
        }
        s |= 1 << x; path.push(s);
    }
    (s, best_bound, path)
}
fn best_of_size(f: &dyn Fn(u8) -> i64, k: u32) -> u8 { (0..8u8).filter(|s| s.count_ones() == k).fold(None, |b: Option<u8>, s| match b { Some(t) if f(t) >= f(s) => Some(t), _ => Some(s) }).unwrap() }
fn promise(k: usize) -> f64 { 1.0 - (1.0 - 1.0 / k as f64).powf(k as f64) }

fn lovasz(f: &dyn Fn(u8) -> i64, x: [f64; 3]) -> (f64, [i64; 3]) {   // sort coordinates high to low, weight each new set's increase
    let mut order = [0usize, 1, 2]; order.sort_by(|&a, &b| x[b].partial_cmp(&x[a]).unwrap().then(a.cmp(&b)));
    let (mut s, mut total, mut prev, mut grad) = (0u8, 0.0, 0i64, [0i64; 3]);
    for i in order { s |= 1 << i; let g = f(s) - prev; prev += g; total += x[i] * g as f64; grad[i] = g }
    (total, grad)
}
fn by_threshold(f: &dyn Fn(u8) -> i64, x: [f64; 3], n: usize) -> f64 {   // average of f over the level sets {x_j >= t}
    (0..n).map(|j| { let t = (j as f64 + 0.5) / n as f64; f((0..3).filter(|&i| x[i] >= t).fold(0u8, |s, i| s | 1 << i)) }).sum::<i64>() as f64 / n as f64
}
struct Rng(u64);
impl Rng { fn next(&mut self) -> f64 {                     // SplitMix64, seed 2026, uniform on [0, 1)
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 } }
fn worst_midpoint(f: &dyn Fn(u8) -> i64, rng: &mut Rng) -> f64 {   // largest amount the midpoint value rises above the chord
    let mut worst = -1.0f64;
    for _ in 0..2000 {
        let p = [rng.next(), rng.next(), rng.next()]; let q = [rng.next(), rng.next(), rng.next()];
        let m = [(p[0] + q[0]) / 2.0, (p[1] + q[1]) / 2.0, (p[2] + q[2]) / 2.0];
        worst = worst.max(lovasz(f, m).0 - (lovasz(f, p).0 + lovasz(f, q).0) / 2.0);
    }
    worst
}

fn main() {
    let acts = [bits(&[1, 2, 3, 4]), bits(&[1, 2, 5]), bits(&[3, 4, 6])];
    let cov = |s: u8| cover(s, &acts);
    let reunion = |s: u8| cover(s, &acts) + if s & 6 == 6 { 4 } else { 0 };   // B and C draw 4 more groups only together
    let all = |f: &dyn Fn(u8) -> i64| (0..8u8).map(|s| format!("{} {}", word(s, "ABC"), f(s))).collect::<Vec<_>>().join(", ");
    let (lat, dr) = lattice_and_dr(&cov);
    println!("coverage: lattice inequality holds for {} of 64 pairs; diminishing returns for {} of 27 cases", lat, dr);
    println!("coverage of every set: {}", all(&cov));
    let (g, bound, path) = greedy(&cov, 2, "ABC", true);
    let o = best_of_size(&cov, 2);
    println!("greedy books {}, {} groups; best of all 3 pairs {}, {} groups; run bound {}", word(g, "ABC"), cov(g), word(o, "ABC"), cov(o), bound);
    println!("ratio {:.3}; promise 1 - (1 - 1/2)^2 = {:.3}; 1 - 1/e = {:.3}", cov(g) as f64 / cov(o) as f64, promise(2), 1.0 - 1.0 / std::f64::consts::E);
    let gaps: Vec<i64> = path.iter().map(|&s| cov(o) - cov(s)).collect();
    println!("gap to the best after 0, 1, 2 picks: {}, {}, {}; proof allows {}, {}, {}", gaps[0], gaps[1], gaps[2], cov(o), cov(o) as f64 / 2.0, cov(o) as f64 / 4.0);
    let steps: Vec<String> = path.windows(2).map(|w| format!("{} <= {} + 2 x {} = {}", cov(o), cov(w[0]), cov(w[1]) - cov(w[0]), cov(w[0]) + 2 * (cov(w[1]) - cov(w[0])))).collect();
    println!("step inequality OPT <= f(S) + k x gain: {}", steps.join("; "));
    println!("promise by k: {}", (1..=10).map(|k| format!("{:.3}", promise(k))).collect::<Vec<_>>().join(" "));
    let tight = [bits(&[1, 3]), bits(&[2]), bits(&[1, 2]), bits(&[3, 4])];   // G, H, P, Q; ties go against greedy
    let tf = |s: u8| cover(s, &tight);
    let ts = greedy(&tf, 2, "GHPQ", false).0;
    println!("tight case: greedy {} {}, best PQ {}, ratio {:.3}", word(ts, "GHPQ"), tf(ts), tf(12), tf(ts) as f64 / tf(12) as f64);
    let (rl, rd) = lattice_and_dr(&reunion);
    let (rg, ro) = (greedy(&reunion, 2, "ABC", false).0, best_of_size(&reunion, 2));
    println!("reunion bonus: lattice holds {} of 64, diminishing returns {} of 27; C adds {} to none, {} to B; greedy {} {}, best {} {}, ratio {:.3}",
             rl, rd, reunion(4), reunion(6) - reunion(2), word(rg, "ABC"), reunion(rg), word(ro, "ABC"), reunion(ro), reunion(rg) as f64 / reunion(ro) as f64);

    let cost = [-3i64, -1, 3];                // fixed change in running cost when the act moves, before split groups, £ thousand
    let w = [(0usize, 1usize, (acts[0] & acts[1]).count_ones() as i64), (0, 2, (acts[0] & acts[2]).count_ones() as i64), (1, 2, (acts[1] & acts[2]).count_ones() as i64)];
    let cut = |s: u8| w.iter().filter(|&&(a, b, _)| (s >> a & 1) != (s >> b & 1)).map(|t| t.2).sum::<i64>();
    let f = |s: u8| (0..3).filter(|&i| s >> i & 1 == 1).map(|i| cost[i]).sum::<i64>() + cut(s);
    println!("shared groups A-B {}, A-C {}, B-C {}; f of every set: {}", w[0].2, w[1].2, w[2].2, all(&f));
    let (fl, fd) = lattice_and_dr(&f);
    println!("stage cost: lattice holds {} of 64, diminishing returns {} of 27", fl, fd);
    let x = [0.2, 0.9, 0.5];
    let (l, gx) = lovasz(&f, x);
    println!("Lovasz extension at A 0.2, B 0.9, C 0.5: sorted sum {:.3}; threshold average {:.3}; greedy vector {} {} {}", l, by_threshold(&f, x, 100000), gx[0], gx[1], gx[2]);
    let mut rng = Rng(2026);
    let (wf, wr) = (worst_midpoint(&f, &mut rng), worst_midpoint(&reunion, &mut rng));
    println!("midpoint test, 2000 random pairs: stage cost worst rise {:.3}; reunion worst rise {:.3}", wf.max(0.0), wr);
    let (mut xk, mut best) = ([0.5f64; 3], (f(0), 0u8));
    for k in 0..60 {                          // projected subgradient descent on the cube [0, 1]^3, step 0.5 / sqrt(k + 1)
        let (val, gr) = lovasz(&f, xk);
        for t in xk {                         // every level set of the iterate is a candidate answer
            let s = (0..3).filter(|&i| xk[i] >= t).fold(0u8, |s, i| s | 1 << i);
            if f(s) < best.0 { best = (f(s), s) }
        }
        if [0, 1, 2, 59].contains(&k) {
            println!("descent k = {}: x = {:.3} {:.3} {:.3}, extension {:.3}, best level set {} {}", k, xk[0], xk[1], xk[2], val, word(best.1, "ABC"), best.0);
        }
        for i in 0..3 { xk[i] = (xk[i] - 0.5 / ((k + 1) as f64).sqrt() * gr[i] as f64).max(0.0).min(1.0) }
    }
    let (y1, y2) = (lovasz(&f, [1.0, 0.9, 0.0]).1, lovasz(&f, [0.9, 1.0, 0.0]).1);
    let y: Vec<f64> = (0..3).map(|i| (y1[i] + y2[i]) as f64 / 2.0).collect();
    let floor: f64 = y.iter().map(|&v| v.min(0.0)).sum();
    let ys = |s: u8| (0..3).filter(|&i| s >> i & 1 == 1).map(|i| y[i]).sum::<f64>();
    let fits = (0..8u8).filter(|&s| ys(s) <= f(s) as f64).count();
    println!("certificate: greedy vectors {} {} {} and {} {} {}, average {} {} {}; floor {}; y(S) <= f(S) for {} of 8 sets", y1[0], y1[1], y1[2], y2[0], y2[1], y2[2], y[0], y[1], y[2], floor, fits);
    let fmin = (0..8u8).fold(0u8, |b, s| if f(s) < f(b) { s } else { b });
    println!("all 8 sets: least f is {} at {}; single moves from none: A {}, B {}, C {}, none improves on 0", word(fmin, "ABC"), f(fmin), f(1), f(2), f(4));

    assert!((lat, dr) == (64, 27) && (fl, fd) == (64, 27));                // both definitions agree, on both functions
    assert!(cov(g) == 5 && cov(o) == 6 && cov(g) as f64 >= promise(2) * cov(o) as f64 && bound == 6);   // the theorem against enumeration
    assert!(gaps.iter().enumerate().all(|(i, &v)| v as f64 <= cov(o) as f64 * 0.5f64.powi(i as i32)));  // the gap halves at least
    assert!(tf(ts) as f64 / tf(12) as f64 == promise(2));                   // the promise is reached
    assert!(rl < 64 && rd < 27 && (reunion(rg) as f64 / reunion(ro) as f64) < promise(2));   // no diminishing returns, no promise
    assert!((l - by_threshold(&f, x, 100000)).abs() < 1e-3 && worst_midpoint(&f, &mut rng) < 1e-12 && 1e-12 < worst_midpoint(&reunion, &mut rng));
    assert!(best == (f(fmin), fmin) && floor == f(fmin) as f64 && fits == 8);
    let c7 = [acts[0], acts[1], bits(&[3, 4, 6, 7])];                       // try: act C reaches a seventh group
    let c7f = |s: u8| cover(s, &c7);
    let (s7, o7) = (greedy(&c7f, 2, "ABC", false).0, best_of_size(&c7f, 2));
    println!("try C reaching group 7: greedy {} {}, best {} {}, ratio {:.3}", word(s7, "ABC"), c7f(s7), word(o7, "ABC"), c7f(o7), c7f(s7) as f64 / c7f(o7) as f64);
    let s3 = greedy(&cov, 3, "ABC", false).0;
    println!("try k = 3: greedy {} {}, best {}, ratio {:.3}", word(s3, "ABC"), cov(s3), cov(7), cov(s3) as f64 / cov(7) as f64);
    let f2 = |s: u8| f(s) + cut(s);           // try: £2 thousand per split group
    let m2 = (0..8u8).fold(0u8, |b, s| if f2(s) < f2(b) { s } else { b });
    println!("try £2 thousand per split group: {}; least {} at {}", all(&f2), word(m2, "ABC"), f2(m2));
    println!("ALL CHECKS PASS");
}
