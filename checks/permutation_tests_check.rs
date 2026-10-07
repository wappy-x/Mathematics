// Permutation tests -- the same check as the Python, in Rust.  No crates.
// A shop's pilot A/B test: 16 visitors, a lottery shows 8 the old product page and 8 the new one.
// Road 1: all 12,870 ways the lottery could have split them.  Road 2: a count of groups of 8 by
// their total, which never lists a split.  Road 3: 20,000 random shuffles from SplitMix64.
// Then the moments of the shuffle law by formula, the t-test, and what breaks.
use std::f64::consts::PI;

const OLD: [i64; 8] = [0, 8, 0, 12, 0, 8, 0, 8];      // dollars spent by each visitor, old page
const NEW: [i64; 8] = [22, 0, 95, 0, 22, 27, 0, 22];  // dollars spent by each visitor, new page
const N: usize = 16;
const K: usize = 8;
const EPS: f64 = 1e-9;
const R: usize = 20000;

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {                       // SplitMix64: the one source of randomness
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn normal(&mut self) -> f64 {                     // Box-Muller
        let a = (-2.0 * self.uniform().ln()).sqrt();
        a * (2.0 * PI * self.uniform()).cos()
    }
}

fn gap(s: f64, total: f64, k: f64, m: f64) -> f64 { s / k - (total - s) / m }   // new mean - old mean

fn phi(x: f64) -> f64 {                               // standard normal area left of x, Taylor series
    let (mut term, mut s, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= -x * x * (2.0 * k - 1.0) / (2.0 * k * (2.0 * k + 1.0));
        s += term;
    }
    0.5 + s / (2.0 * PI).sqrt()
}

fn t_area(t: f64, g: f64) -> f64 {                    // area under the t density (14 df) from 0 to t
    let steps = 2000;
    let h = t / steps as f64;
    let f = |x: f64| g / (14.0 * PI).sqrt() * (1.0 + x * x / 14.0).powf(-7.5);
    let mut s = 0.0;
    for i in 0..=steps {
        let w = if i == 0 || i == steps { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(i as f64 * h);
    }
    h / 3.0 * s
}

fn subsets(n: usize, k: usize, start: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == k { out.push(cur.clone()); return }
    for i in start..n { cur.push(i); subsets(n, k, i + 1, cur, out); cur.pop(); }
}

fn main() {
    let pool: Vec<i64> = OLD.iter().chain(NEW.iter()).copied().collect();
    let total: i64 = pool.iter().sum();
    let (tf, kf, mf) = (total as f64, K as f64, (N - K) as f64);
    let sq: i64 = pool.iter().map(|x| x * x).sum();
    let mut rng = Rng(20260929);
    let mut g = 0.5 * PI.sqrt();                      // Gamma(7.5) / Gamma(7)
    for j in 1..7 { g *= (j as f64 + 0.5) / j as f64 }
    let t_stat = |s: f64, q: f64| {
        let ss = (q - s * s / kf) + (sq as f64 - q - (tf - s) * (tf - s) / mf);
        gap(s, tf, kf, mf) / (ss / (N as f64 - 2.0) * (1.0 / kf + 1.0 / mf)).sqrt()
    };
    let (so, sn) = (OLD.iter().sum::<i64>() as f64, NEW.iter().sum::<i64>() as f64);
    let obs = gap(sn, tf, kf, mf);
    println!("old page mean {:.2}, new page mean {:.2}, observed gap {:.2}", so / kf, sn / kf, obs);
    let sd = |v: &[i64]| { let m = v.iter().sum::<i64>() as f64 / kf;
        (v.iter().map(|&x| (x as f64 - m).powi(2)).sum::<f64>() / (kf - 1.0)).sqrt() };
    println!("standard error of the gap {:.2}", (sd(&OLD).powi(2) / kf + sd(&NEW).powi(2) / kf).sqrt());

    let mut idx = Vec::new();                         // Road 1: every split
    subsets(N, K, 0, &mut Vec::new(), &mut idx);
    let splits: Vec<(f64, f64)> = idx.iter().map(|c| (c.iter().map(|&i| pool[i]).sum::<i64>() as f64,
        c.iter().map(|&i| pool[i] * pool[i]).sum::<i64>() as f64)).collect();
    let gaps: Vec<f64> = splits.iter().map(|&(s, _)| gap(s, tf, kf, mf)).collect();
    let m = gaps.len();
    let two = gaps.iter().filter(|g| g.abs() >= obs - EPS).count();
    let one = gaps.iter().filter(|&&g| g >= obs - EPS).count();
    let strict = gaps.iter().filter(|g| g.abs() > obs + EPS).count();
    println!("pooled total {}; new-page total {}; old-page total {}", total, sn, so);
    println!("road 1, all {} splits: {} at +{:.2} or more, {} at -{:.2} or less, p = {:.4}", m, one, obs, two - one, obs, two as f64 / m as f64);

    let tu = total as usize;                          // Road 2: groups of k counted by their total
    let mut ways = vec![vec![0u64; tu + 1]; K + 1];
    ways[0][0] = 1;
    for &x in &pool {
        let x = x as usize;
        for k in (1..=K).rev() { for s in (0..=tu - x).rev() { ways[k][s + x] += ways[k - 1][s] } }
    }
    let groups: u64 = ways[K].iter().sum();
    let two_dp: u64 = (0..=tu).filter(|&s| gap(s as f64, tf, kf, mf).abs() >= obs - EPS).map(|s| ways[K][s]).sum();
    println!("road 2, groups of 8 counted by total: {} groups, {} as extreme, p = {:.4}", groups, two_dp, two_dp as f64 / m as f64);

    let mut hits = 0;                                 // Road 3: Fisher-Yates shuffles
    for _ in 0..R {
        let mut deck = pool.clone();
        for i in (1..N).rev() { let j = (rng.next() % (i as u64 + 1)) as usize; deck.swap(i, j) }
        if gap(deck[..K].iter().sum::<i64>() as f64, tf, kf, mf).abs() >= obs - EPS { hits += 1 }
    }
    let ph = hits as f64 / R as f64;
    println!("road 3, {} shuffles: {} as extreme, p = {:.4}, standard error {:.4}", R, hits, ph, (ph * (1.0 - ph) / R as f64).sqrt());
    println!("  shuffles with the observed split counted in: (hits + 1) / (R + 1) = {:.4}", (hits + 1) as f64 / (R + 1) as f64);

    let mean_g = gaps.iter().sum::<f64>() / m as f64;
    let var_g = gaps.iter().map(|g| (g - mean_g).powi(2)).sum::<f64>() / m as f64;
    let s2 = (sq as f64 - tf * tf / N as f64) / (N as f64 - 1.0); let var_f = s2 * (1.0 / kf + 1.0 / mf);
    println!("shuffle law: mean {:.4}, sd by enumeration {:.4}, sd by formula {:.4} from S^2 {:.4} about the mean {:.4}", mean_g, var_g.sqrt(), var_f.sqrt(), s2, tf / N as f64);
    let z = obs / var_f.sqrt();
    println!("bell curve laid over the shuffle law: z = {:.4}, p = {:.4}", z, 2.0 * (1.0 - phi(z)));

    let t_obs = t_stat(sn, NEW.iter().map(|x| x * x).sum::<i64>() as f64);
    let p_t = 1.0 - 2.0 * t_area(t_obs, g);
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if t_area(mid, g) < 0.475 { lo = mid } else { hi = mid } }
    let t_rej = splits.iter().filter(|&&(s, q)| t_stat(s, q).abs() >= lo).count();
    println!("t-test: t = {:.4}, p = {:.4}; 5% cut-off {:.4}", t_obs, p_t, lo);
    let mut absg: Vec<f64> = gaps.iter().map(|g| g.abs()).collect();
    absg.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let perm_rej = gaps.iter().filter(|g| {
        let below = absg.partition_point(|&a| a < g.abs() - EPS);
        (m - below) as f64 / m as f64 <= 0.05 }).count();
    println!("false alarms over all {} splits at 5%: shuffle test {} = {:.4}, t-test {} = {:.4}",
             m, perm_rej, perm_rej as f64 / m as f64, t_rej, t_rej as f64 / m as f64);

    let mut bars = [0usize; 11];                      // chart: bars of $5, an edge value goes inward
    for &g in &gaps {
        let k = if g.abs() <= 2.5 + EPS { 0 } else { ((g.abs() - 2.5 - EPS) / 5.0).floor() as i64 + 1 };
        bars[(5 + if g > 0.0 { k } else { -k }) as usize] += 1;
    }
    println!("chart, gap centre ($) {}", (0..11).map(|i| format!("{:5}", 5 * (i - 5))).collect::<Vec<_>>().join(" "));
    println!("chart, splits         {}", bars.iter().map(|b| format!("{:5}", b)).collect::<Vec<_>>().join(" "));

    let strict_rej = gaps.iter().filter(|g| {         // ties dropped
        (m - absg.partition_point(|&a| a < g.abs() + EPS)) as f64 / m as f64 <= 0.05 }).count();
    println!("wrong: strictly larger only, {} splits, p = {:.4}; as a 5% test it fires on {} = {:.4}",
             strict, strict as f64 / m as f64, strict_rej, strict_rej as f64 / m as f64);
    println!("wrong: one side reported as the two-sided answer, p = {:.4}", one as f64 / m as f64);
    let (reps, mut rej) = (2000, 0);
    let mut c4 = Vec::new();
    subsets(N, 4, 0, &mut Vec::new(), &mut c4);
    for _ in 0..reps {                                // equal means, 4 visitors spread 4x, 12 spread 1x
        let mut x = Vec::new();
        for _ in 0..4 { x.push(4.0 * rng.normal()) }
        for _ in 0..12 { x.push(rng.normal()) }
        let tot: f64 = x.iter().sum();
        let o = gap(x[..4].iter().sum(), tot, 4.0, 12.0).abs();
        let c = c4.iter().filter(|c| gap(x[c[0]] + x[c[1]] + x[c[2]] + x[c[3]], tot, 4.0, 12.0).abs() >= o - EPS).count();
        if c as f64 / c4.len() as f64 <= 0.05 { rej += 1 }
    }
    let pr = rej as f64 / reps as f64;
    println!("wrong: shuffling groups of unequal spread, equal means: rejects {} of {} = {:.4}, standard error {:.4}",
             rej, reps, pr, (pr * (1.0 - pr) / reps as f64).sqrt());

    assert!(two as u64 == two_dp && m as u64 == groups && m == 12870);   // enumeration vs sum count
    assert!((ph - two as f64 / m as f64).abs() < 4.0 * (ph * (1.0 - ph) / R as f64).sqrt());
    assert!((var_g - var_f).abs() < 1e-9 && mean_g.abs() < 1e-9);       // spread by formula
    assert!(perm_rej as f64 / m as f64 <= 0.05 && strict_rej as f64 / m as f64 > 0.05);
    assert!(pr > 0.05 + 4.0 * (pr * (1.0 - pr) / reps as f64).sqrt());
    assert!((phi(1.959963984540054) - 0.975).abs() < 1e-12 && (lo - 2.1447866879).abs() < 1e-6);   // tables
    println!("ALL CHECKS PASS");
}
