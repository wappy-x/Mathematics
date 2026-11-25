// Plunnecke-Ruzsa and Freiman -- the same check as the Python, in Rust.  No crates.
// A = {0..4} with {100..104}.  Every sumset is counted by brute force and set beside
// a block-count formula, the Plunnecke-Ruzsa bound, Petridis's best subset, Ruzsa's
// injection, the progression Freiman predicts, and 300 random sets as evidence.
use std::collections::{BTreeMap, BTreeSet};

fn plus(x: &[i64], y: &[i64]) -> Vec<i64> {
    let s: BTreeSet<i64> = x.iter().flat_map(|a| y.iter().map(move |b| a + b)).collect();
    s.into_iter().collect()
}
fn minus(x: &[i64], y: &[i64]) -> Vec<i64> {
    let s: BTreeSet<i64> = x.iter().flat_map(|a| y.iter().map(move |b| a - b)).collect();
    s.into_iter().collect()
}
fn copies(x: &[i64], k: u32) -> Vec<i64> {     // kA: k copies of X added; 0A = {0}
    let mut out = vec![0];
    for _ in 0..k { out = plus(&out, x) }
    out
}
fn dec(num: u128, den: u128) -> String {       // exact decimal of num/den when den divides 10^8
    let k = (0..9).find(|&k| 10u128.pow(k) % den == 0).unwrap() as usize;
    if k == 0 { return (num / den).to_string() }
    let mut s = (num * 10u128.pow(k as u32) / den).to_string();
    while s.len() < k + 1 { s.insert(0, '0') }
    let t = format!("{}.{}", &s[..s.len() - k], &s[s.len() - k..]);
    t.trim_end_matches('0').trim_end_matches('.').to_string()
}
fn name(k: u32, l: u32) -> String {
    let a = if k > 1 { format!("{}A", k) } else { "A".to_string() };
    let b = if l > 1 { format!("-{}A", l) } else if l == 1 { "-A".to_string() } else { String::new() };
    a + &b
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn best_subsets(a: &[i64], b: &[i64]) -> (u128, u128, Vec<Vec<i64>>) {   // Petridis's best X
    let mut subs: Vec<Vec<i64>> = (1u32..(1 << a.len()))
        .map(|m| (0..a.len()).filter(|i| m >> i & 1 == 1).map(|i| a[i]).collect()).collect();
    subs.sort_by(|p, q| (p.len(), p).cmp(&(q.len(), q)));
    let (mut num, mut den) = (0u128, 0u128);
    for x in &subs {
        let (s, t) = (plus(x, b).len() as u128, x.len() as u128);
        if den == 0 || s * den < num * t { num = s; den = t }
    }
    let best = subs.into_iter().filter(|x| plus(x, b).len() as u128 * den == num * x.len() as u128).collect();
    (num, den, best)
}
fn fmt(v: &[i64]) -> String { format!("{:?}", v) }

fn main() {
    let a: Vec<i64> = (0..5).chain(100..105).collect();
    let (n, s2) = (a.len() as u128, plus(&a, &a).len() as u128);
    println!("|A| = {}, |A+A| = {}, K = {}; floor 2|A|-1 = {}, most possible {}", n, s2, dec(s2, n), 2 * n - 1, n * (n + 1) / 2);
    for (k, l) in [(1u32, 1u32), (2, 0), (2, 1), (3, 0), (2, 2), (4, 0), (3, 3)] {
        let size = minus(&copies(&a, k), &copies(&a, l)).len() as u128;
        let m = k + l;
        let blocks = (4 * m as u128 + 1) * (m as u128 + 1);    // road two: m+1 blocks of 4m+1
        let bound = dec(s2.pow(m), n.pow(m - 1));               // K^(k+l)|A| = 27^m / 10^(m-1)
        println!("|{}| = {}; blocks (4*{}+1)({}+1) = {}; bound K^{}|A| = {}", name(k, l), size, m, m, blocks, m, bound);
        assert!(size == blocks && size * n.pow(m - 1) <= s2.pow(m));
    }
    let (num, den, best) = best_subsets(&a, &a);
    println!("Petridis: least |X+A|/|X| = {}/{} = {}, among {} subsets, reached by {}; it is A itself: {}",
             num, den, dec(num, den), (1u128 << n) - 1, best.len(), yn(best[0] == a));
    let x = best[0].clone();
    for (cname, c) in [("A", a.clone()), ("2A", copies(&a, 2)), ("3A", copies(&a, 3)), ("-A", minus(&[0], &a))] {
        let (lhs, rhs) = (plus(&plus(&x, &a), &c).len() as u128, plus(&x, &c).len() as u128);
        println!("lemma with C = {}: |X+A+C| = {} <= K'|X+C| = {}", cname, lhs, dec(num * rhs, den));
        assert!(lhs * den <= num * rhs);
    }
    let y = copies(&a, 2);                     // Ruzsa: (x, d) -> (x + y_d, x + z_d), d = y_d - z_d
    let mut pick: BTreeMap<i64, (i64, i64)> = BTreeMap::new();
    for &p in &y { for &q in &y { pick.entry(p - q).or_insert((p, q)); } }
    let image: BTreeSet<(i64, i64)> = a.iter().flat_map(|&u| pick.values().map(move |&(p, q)| (u + p, u + q))).collect();
    let xy: BTreeSet<i64> = plus(&a, &y).into_iter().collect();
    let pairs = n * pick.len() as u128;
    let xy2 = (xy.len() as u128).pow(2);
    println!("Ruzsa map on A x (2A-2A): {} x {} = {} pairs, {} distinct images, all in (A+2A)x(A+2A): {}",
             n, pick.len(), pairs, image.len(), yn(image.iter().all(|(p, q)| xy.contains(p) && xy.contains(q))));
    println!("triangle: |A||2A-2A| = {} <= |A+2A|^2 = {} <= (K^2|A|)^2 = {}", pairs, xy2, dec(s2.pow(4), n.pow(2)));
    println!("so |2A-2A| <= {} <= K^4|A| = {}", dec(xy2, n), dec(s2.pow(4), n.pow(3)));
    assert!(image.len() as u128 == pairs && pairs <= xy2);
    let p: Vec<i64> = (0..5).flat_map(|u| (0..2).map(move |v| u + 100 * v)).collect::<BTreeSet<i64>>().into_iter().collect();
    println!("Freiman: P = a + 100b (0<=a<=4, 0<=b<=1) has {} members = 5 x 2, equals A: {}", p.len(), yn(p == a));
    let mut g = 0i64;
    for &u in &a {                             // Euclid's algorithm on the gaps from the least member
        let mut h = u - a[0];
        while h != 0 { (g, h) = (h, g % h) }
    }
    let line = ((a[a.len() - 1] - a[0]) / g + 1) as u128;
    println!("shortest 1-D progression holding A: step {}, {} terms = {} x |A|", g, line, dec(line, n));
    println!("3k-4 test: |A+A| = {} vs 3|A|-4 = {}; its promise, length <= {}, would fail: {} terms", s2, 3 * n - 4, s2 - n + 1, line);
    println!("Chang: |A+A| < alpha|A| for alpha just above {} gives dimension <= {}", dec(s2, n), s2 / n - 1);
    assert!(p == a && line == 105 && s2 > 3 * n - 4);
    let v: Vec<u32> = (0..1u32 << 10).collect();   // all 1,024 vectors of 0s and 1s, added by XOR
    let xs: BTreeSet<u32> = v.iter().flat_map(|&p| v.iter().map(move |&q| p ^ q)).collect();
    println!("mod-2 vectors: |A| = {}, |A+A| = {}, K = {}; a step v has v+v = 0, so dimension >= {}",
             v.len(), xs.len(), xs.len() / v.len(), v.len().trailing_zeros());
    assert!(xs.len() == v.len());
    let t = vec![0i64, 1, 3];
    println!("mistake, A-A taken as no bigger than A+A: T = {} has |T+T| = {}, |T-T| = {}", fmt(&t), plus(&t, &t).len(), minus(&t, &t).len());
    assert!(minus(&t, &t).len() > plus(&t, &t).len());
    let d: BTreeSet<i64> = a.iter().map(|u| 2 * u).collect();
    println!("mistake, kA read as k times each member: 2*A has {} members, 2A has {}", d.len(), s2);
    let (a2, b2, c2) = (vec![0i64, 2, 5, 7, 17], vec![0i64, 2], vec![0i64, 5]);
    let (lhs, rhs, ab) = (plus(&plus(&a2, &b2), &c2).len() as u128, plus(&a2, &c2).len() as u128, plus(&a2, &b2).len() as u128);
    println!("mistake, Petridis step with X = all of S = {}, B = {}, C = {}: |S+B+C| = {} > (|S+B|/|S|)|S+C| = ({}/{}) x {} = {}",
             fmt(&a2), fmt(&b2), fmt(&c2), lhs, ab, a2.len(), rhs, dec(ab * rhs, a2.len() as u128));
    let (num2, den2, best2) = best_subsets(&a2, &b2);
    for xb in &best2 {
        let (l2, r2) = (plus(&plus(xb, &b2), &c2).len() as u128, plus(xb, &c2).len() as u128);
        println!("  best X = {}, ratio {}: |X+B+C| = {} <= {}", fmt(xb), dec(num2, den2), l2, dec(num2 * r2, den2));
        assert!(l2 * den2 <= num2 * r2);
    }
    assert!(lhs * a2.len() as u128 > ab * rhs);
    let mut state: u64 = 2026;                 // SplitMix64, seed 2026: random sets as evidence
    let mut rnd = || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    };
    let (mut tests, mut worst) = (0u32, (0u128, 1u128));
    for _ in 0..300 {
        let mut r: BTreeSet<i64> = BTreeSet::new();
        while r.len() < 6 { r.insert((rnd() % 50) as i64); }
        let r: Vec<i64> = r.into_iter().collect();
        let r2s = plus(&r, &r).len() as u128;
        for k in 0..5u32 {
            for l in 0..(5 - k) {
                if k + l < 2 || (l == 0 && k == 2) || k == 0 { continue }
                let sz = minus(&copies(&r, k), &copies(&r, l)).len() as u128;
                let (top, bot) = (sz * 6u128.pow(k + l - 1), r2s.pow(k + l));
                assert!(top <= bot);
                tests += 1;
                if top * worst.1 > worst.0 * bot { worst = (top, bot) }
            }
        }
    }
    println!("random sets: 300 sets of 6 from 0..49, {} bounds with k+l = 2 to 4 checked, worst size/bound = {:.4}",
             tests, worst.0 as f64 / worst.1 as f64);
    println!("ALL CHECKS PASS");
}
