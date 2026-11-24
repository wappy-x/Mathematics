// Sufficient statistics -- the same check as the Python, in Rust.  No crates.
// Every number on the card is printed here.  Roads: brute force over all 1,024
// answer lists, the factorisation formula, a likelihood-ratio grouping that never
// mentions the count, and a seeded simulation (SplitMix64, same draws as Python).
use std::collections::BTreeMap;

const N: usize = 10; const T: usize = 7;              // the poll in miniature: 10 answers, 7 yes
type Groups = BTreeMap<Vec<i64>, Vec<Vec<u8>>>;

fn chance(x: &[u8], p: f64) -> f64 {              // one exact list: p per yes, 1 - p per no
    x.iter().fold(1.0, |out, &a| out * if a == 1 { p } else { 1.0 - p })
}

fn comb(n: u64, k: u64) -> u64 { (0..k).fold(1, |c, i| c * (n - i) / (i + 1)) }
fn count(x: &[u8]) -> usize { x.iter().map(|&a| a as usize).sum() }

fn fisher(groups: &Groups, p: f64) -> f64 {     // information kept by a summary
    let (h, mut info) = (1e-6, 0.0);
    for xs in groups.values() {
        let sum = |q: f64| -> f64 { xs.iter().map(|x| chance(x, q)).sum() };
        let dq = (sum(p + h) - sum(p - h)) / (2.0 * h);
        info += dq * dq / sum(p);
    }
    info
}

fn group_by(lists: &[Vec<u8>], key: &dyn Fn(&[u8]) -> Vec<i64>) -> Groups {
    let mut g: Groups = BTreeMap::new();
    for x in lists { g.entry(key(x)).or_default().push(x.clone()) } g
}

struct SplitMix(u64);
impl SplitMix { fn unif(&mut self) -> f64 {        // SplitMix64: a uniform number in [0, 1)
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
} }

fn lik(w: &[f64], th: f64) -> f64 {               // independent waits multiply: 1/theta each in [0, theta]
    w.iter().fold(1.0, |out, &v| out * if 0.0 <= v && v <= th { 1.0 / th } else { 0.0 })
}

fn lnratio(x: &[f64], y: &[f64], mu: f64, s2: f64) -> f64 {   // ln of L(mu; x) / L(mu; y)
    let ss = |v: &[f64]| -> f64 { v.iter().map(|a| (a - mu) * (a - mu)).sum() };
    (ss(y) - ss(x)) / (2.0 * s2)
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let lists: Vec<Vec<u8>> = (0..1024u32).map(|i| (0..N).map(|j| ((i >> (9 - j)) & 1) as u8).collect()).collect();
    let mut rng = SplitMix(20261123);

    // ---- road 1: the conditional law of the list, given the count 7 ----
    let seven: Vec<&Vec<u8>> = lists.iter().filter(|x| count(x) == T).collect();
    println!("lists with 7 yes out of 10: {}; C(10, 7) = {}", seven.len(), comb(10, 7));
    let mut worst: f64 = 0.0;
    for p in [0.3, 0.52, 0.9] {
        let (one, total) = (chance(seven[0], p), seven.iter().map(|x| chance(x, p)).sum::<f64>());
        for x in &seven { worst = worst.max((chance(x, p) / total - 1.0 / 120.0).abs()) }
        println!("p = {:.2}: one list {:.8}; count 7 {:.6}; one list given 7 {:.6}", p, one, total, one / total);
    }
    assert!(seven.len() as u64 == comb(10, 7) && worst < 1e-12);

    // ---- road 2: the factorisation g(t, p) h(x), h = 1, against brute force ----
    let mut gap: f64 = 0.0;
    for x in &lists {
        let t = count(x) as f64; gap = gap.max((chance(x, 0.52) - 0.52f64.powf(t) * 0.48f64.powf(N as f64 - t)).abs());
    }
    let by_count = group_by(&lists, &|x| vec![count(x) as i64]);   // rebuild: draw the count, then shuffle it
    let mut rebuilt: f64 = 0.0;
    for x in &lists {
        let xs = &by_count[&vec![count(x) as i64]];
        let law_t: f64 = xs.iter().map(|y| chance(y, 0.52)).sum();
        rebuilt = rebuilt.max((law_t / xs.len() as f64 - chance(x, 0.52)).abs());
    }
    println!("all 1,024 lists: brute chance = g(t,p)h(x): {}; law rebuilt from the count = real law: {}",
             yn(gap < 1e-15), yn(rebuilt < 1e-15));
    assert!(gap < 1e-15 && rebuilt < 1e-15);

    // ---- road 3: simulate. Given 7 yes, is the first answer yes 70% of the time? ----
    for p in [0.52, 0.9] {
        let (mut hits, mut first) = (0u32, 0u32);
        for _ in 0..200000 {
            let x: Vec<u8> = (0..N).map(|_| if rng.unif() < p { 1 } else { 0 }).collect();
            if count(&x) == T { hits += 1; first += x[0] as u32 }
        }
        let share = first as f64 / hits as f64;
        println!("simulated, p = {:.2}: {} polls with 7 yes; first answer yes in {:.4}", p, hits, share);
        assert!((share - 0.7).abs() < 0.02);
    }

    // ---- what a summary keeps: Fisher information at p = 0.7 ----
    let keys: Vec<(&str, Box<dyn Fn(&[u8]) -> Vec<i64>>)> = vec![
        ("whole list", Box::new(|x: &[u8]| x.iter().map(|&a| a as i64).collect())),
        ("count of yes", Box::new(|x: &[u8]| vec![count(x) as i64])),
        ("counts in each half", Box::new(|x: &[u8]| vec![count(&x[..5]) as i64, count(&x[5..]) as i64])),
        ("count in first half", Box::new(|x: &[u8]| vec![count(&x[..5]) as i64])),
        ("majority yes or not", Box::new(|x: &[u8]| vec![(count(x) >= 6) as i64])),
        ("first answer only", Box::new(|x: &[u8]| vec![x[0] as i64])),
    ];
    let mut infos = Vec::new();
    for (name, key) in &keys {
        let g = group_by(&lists, key.as_ref());
        let i = fisher(&g, 0.7);
        println!("information kept, {:<20} {:10.6}   ({} values)", name, i, g.len());
        infos.push(i);
    }
    println!("formula n / (p(1 - p)) = {:.6}", N as f64 / (0.7 * 0.3));
    assert!((infos[0] - N as f64 / 0.21).abs() < 1e-4 && (infos[1] - N as f64 / 0.21).abs() < 1e-4);
    assert!(infos[4] < 0.5 * N as f64 / 0.21);

    // ---- minimal: group lists whose likelihood ratio does not move with p ----
    let ratio_key = |x: &[u8]| -> Vec<i64> {      // ln P(x; p) - ln P(x; 0.5) on a grid, never the count
        (1..10).map(|i| {
            let p = i as f64 / 10.0;
            ((chance(x, p).ln() - chance(x, 0.5).ln()) * 1e9).round() as i64
        }).collect()
    };
    let classes = group_by(&lists, &ratio_key);
    let same = classes.values().all(|xs| xs.iter().all(|x| count(x) == count(&xs[0])));
    println!("classes of equal likelihood ratio: {}; each class is one count: {}", classes.len(), yn(same));
    assert!(classes.len() == 11 && same);

    // ---- the shuttle: waits Uniform(0, theta), observed 2.1, 4.7, 3.3 minutes ----
    let (waits, twin, same_sum) = ([2.1, 4.7, 3.3], [0.4, 4.7, 1.0], [3.3, 3.4, 3.4]);
    for th in [4.5, 4.7, 5.0, 6.0, 8.0] {
        println!("theta = {:.1}: likelihood {:.6}; same-maximum twin {:.6}", th, lik(&waits, th), lik(&twin, th));
    }
    let pts: Vec<f64> = (0..21).map(|i| 4.0 + 0.1 * i as f64).collect();
    let chart: Vec<String> = pts.iter().map(|&t| format!("{:.2}", 1000.0 * lik(&waits, t))).collect();
    println!("chart, likelihood x 1000, theta 4.0 to 6.0: {}", chart.join(" "));
    let mut best = pts[0];
    for &t in pts.iter().chain([4.7].iter()) { if lik(&waits, t) > lik(&waits, best) { best = t } }
    let (s1, s2sum): (f64, f64) = (waits.iter().sum(), same_sum.iter().sum());
    println!("peak at theta = {:.1}; sums {:.1} and {:.1}; at theta = 4.0: {:.6} vs {:.6}",
             best, s1, s2sum, lik(&waits, 4.0), lik(&same_sum, 4.0));
    let mut wrong: f64 = 0.1;
    for i in 1..101 { let t = 0.1 * i as f64; if t.powf(-3.0) > wrong.powf(-3.0) { wrong = t } }
    println!("indicator dropped, theta^-3 alone: peak at the search floor {:.1}", wrong);
    assert!(pts.iter().all(|&t| lik(&waits, t) == lik(&twin, t)) && (best - 4.7).abs() < 1e-12);
    assert!(lik(&waits, 4.0) == 0.0 && lik(&same_sum, 4.0) > 0.0);
    for th in [5.0, 9.0] {                        // given a maximum near 4.7, the rest ignore theta
        let (mut hits, mut rest) = (0u32, 0.0);
        for _ in 0..400000 {
            let mut w: Vec<f64> = (0..3).map(|_| th * rng.unif()).collect();
            w.sort_by(|a, b| a.partial_cmp(b).unwrap());
            if 4.6 <= w[2] && w[2] <= 4.8 { hits += 1; rest += (w[0] + w[1]) / 2.0 }
        }
        let m = rest / hits as f64;
        println!("simulated, theta = {:.0}: {} samples with maximum in 4.6-4.8; mean of the other two {:.4}", th, hits, m);
        assert!((m - 2.35).abs() < 0.05);
    }

    // ---- the normal with known spread 0.02: the median is not sufficient ----
    let (a, b) = ([0.49, 0.51, 0.52, 0.54, 0.54], [0.51, 0.51, 0.52, 0.52, 0.59]);
    let (c, s2) = ([0.50, 0.50, 0.50, 0.55, 0.55], 0.02f64 * 0.02);
    let mean = |v: &[f64]| v.iter().sum::<f64>() / 5.0;
    println!("medians A, B, C: {:.2} {:.2} {:.2}; means {:.3} {:.3} {:.3}", a[2], b[2], c[2], mean(&a), mean(&b), mean(&c));
    for mu in [0.50, 0.52, 0.54] {
        println!("mu = {:.2}: L(A)/L(B) = {:.4}; L(A)/L(C) = {:.4}", mu,
                 lnratio(&a, &b, mu, s2).exp(), lnratio(&a, &c, mu, s2).exp());
    }
    assert!((lnratio(&a, &b, 0.50, s2) - lnratio(&a, &b, 0.54, s2)).abs() > 1.0);
    assert!((lnratio(&a, &c, 0.50, s2) - lnratio(&a, &c, 0.54, s2)).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
