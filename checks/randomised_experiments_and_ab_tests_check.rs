// Randomised experiments and A/B tests -- the same check as the Python, in Rust.  No crates.
// Checkout pages A (old) and B (new), 10,000 visitors each, assigned by lottery.  Road 1: exact
// formulas on a model table of both outcomes for 20,000 visitors.  Road 2: all 70 lotteries on an
// 8-visitor table.  Road 3: 1,000 seeded lotteries (SplitMix64).  Sizing: formula against exact count.
use std::f64::consts::PI;
const SEED: u64 = 20260929;
const R: usize = 1000; const NA: usize = 10000; const NB: usize = 10000;
fn phi_cdf(z: f64) -> f64 {                    // bell area left of z, by its Taylor series
    let (mut term, mut total) = (z, z);
    for k in 1..300 { let k = k as f64; term *= -z * z / (2.0 * k); total += term / (2.0 * k + 1.0) }
    0.5 + total / (2.0 * PI).sqrt()
}
fn phi_inv(p: f64) -> f64 {                    // normal quantile by Newton's method from 0
    let mut z = 0.0;
    for _ in 0..50 { z -= (phi_cdf(z) - p) / ((-z * z / 2.0).exp() / (2.0 * PI).sqrt()) }
    z
}
fn neyman(ya: &[i64], yb: &[i64], na: f64, nb: f64) -> (f64, f64, f64, f64) {   // road 1
    let n = ya.len() as f64;
    let s2 = |col: &[i64]| {
        let m = col.iter().sum::<i64>() as f64 / n; col.iter().map(|&v| (v as f64 - m).powi(2)).sum::<f64>() / (n - 1.0)
    };
    let eff: Vec<i64> = ya.iter().zip(yb).map(|(a, b)| b - a).collect();
    let (sa, sb, st) = (s2(ya), s2(yb), s2(&eff));
    (sa, sb, st, sb / nb + sa / na - st / n)
}
struct Rng(u64);                                // SplitMix64
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn spreads(p0: f64, p1: f64) -> (f64, f64) {
    let pb = (p0 + p1) / 2.0;
    ((2.0 * pb * (1.0 - pb)).sqrt(), (p0 * (1.0 - p0) + p1 * (1.0 - p1)).sqrt())
}
fn power(n: f64, p0: f64, p1: f64, za: f64) -> f64 {          // normal formula, both tails
    let (s0, s1) = spreads(p0, p1);
    phi_cdf(((p1 - p0) * n.sqrt() - za * s0) / s1) + phi_cdf((-(p1 - p0) * n.sqrt() - za * s0) / s1)
}
fn n_need(p0: f64, p1: f64, za: f64, zb: f64) -> usize {
    let (s0, s1) = spreads(p0, p1);
    ((za * s0 + zb * s1) / (p1 - p0)).powi(2).ceil() as usize
}
fn pmf_window(n: usize, p: f64) -> Vec<(usize, f64)> {        // binomial chances within 12 SDs, by logs
    let (m, s) = (n as f64 * p, (n as f64 * p * (1.0 - p)).sqrt());
    let lo = if m - 12.0 * s > 0.0 { (m - 12.0 * s) as usize } else { 0 };
    let hi = ((m + 12.0 * s) as usize).min(n);
    let lg = (1..=lo).map(|k| (k as f64).ln()).sum::<f64>() - (n - lo + 1..=n).map(|k| (k as f64).ln()).sum::<f64>();
    let (mut out, mut lp) = (Vec::new(), 0.0);
    for k in lo..=hi {
        lp = if k == lo { -lg + lo as f64 * p.ln() + (n - lo) as f64 * (1.0 - p).ln() }
             else { lp + ((n - k + 1) as f64 / k as f64 * p / (1.0 - p)).ln() };
        out.push((k, lp.exp()));
    }
    out
}
fn power_exact(n: usize, p0: f64, p1: f64, za: f64) -> f64 {  // road 2 for sizing: every rejecting pair
    let (f0, f1, nf) = (pmf_window(n, p0), pmf_window(n, p1), n as f64);
    let mut tot = 0.0;
    for &(x1, q1) in &f1 {
        for &(x0, q0) in &f0 {
            let pl = (x0 + x1) as f64 / (2.0 * nf);
            if (x1 as f64 - x0 as f64).abs() / nf > za * (pl * (1.0 - pl) * 2.0 / nf).sqrt() { tot += q1 * q0 }
        }
    }
    tot
}
fn main() {
    let kinds: [(i64, usize, i64, i64); 8] = [(1, 700, 1, 1), (1, 60, 0, 1), (1, 20, 1, 0), (1, 3220, 0, 0),
        (0, 200, 1, 1), (0, 200, 0, 1), (0, 80, 1, 0), (0, 15520, 0, 0)];
    let (mut ret, mut ya, mut yb) = (Vec::new(), Vec::new(), Vec::new());
    for &(r, c, a, b) in &kinds { for _ in 0..c { ret.push(r); ya.push(a); yb.push(b) } }
    let n = ya.len();
    let (sum_a, sum_b) = (ya.iter().sum::<i64>(), yb.iter().sum::<i64>());
    let tau = (sum_b - sum_a) as f64 / n as f64;
    let kind = |a: i64, b: i64| kinds.iter().filter(|k| (k.2, k.3) == (a, b)).map(|k| k.1).sum::<usize>();
    let (na, nb) = (NA as f64, NB as f64);
    let (xa, xb) = (500.0, 580.0);                               // the observed test
    let gap = xb / nb - xa / na;
    let pool = (xa + xb) / (na + nb);
    let se0 = (pool * (1.0 - pool) * (1.0 / na + 1.0 / nb)).sqrt();
    let se1 = (xa / na * (1.0 - xa / na) / na + xb / nb * (1.0 - xb / nb) / nb).sqrt();
    let (za, zb) = (phi_inv(0.975), phi_inv(0.80));
    println!("observed: A {} of {} = {:.4}, B {} of {} = {:.4}, gap {:.4}", xa, NA, xa / na, xb, NB, xb / nb, gap);
    println!("observed: pooled rate {:.4}, pooled SE {:.6}, z {:.4}, two-sided p-value {:.4}", pool, se0, gap / se0, 2.0 * (1.0 - phi_cdf(gap / se0)));
    println!("observed: arm variances {:.8} + {:.8}, unpooled SE {:.6}, 95% interval {:.4} to {:.4}", xa / na * (1.0 - xa / na) / na, xb / nb * (1.0 - xb / nb) / nb, se1, gap - za * se1, gap + za * se1);
    println!("model: N {}; always {}, helped {}, hurt {}, never {}", n, kind(1, 1), kind(0, 1), kind(1, 0), kind(0, 0));
    println!("model: y(A) rate {:.4}, y(B) rate {:.4}, true effect tau {:.4}", sum_a as f64 / n as f64, sum_b as f64 / n as f64, tau);
    let nret = ret.iter().sum::<i64>() as f64;
    let ra = (0..n).filter(|&i| ret[i] == 1).map(|i| ya[i]).sum::<i64>() as f64;
    let rb = (0..n).filter(|&i| ret[i] == 1).map(|i| yb[i]).sum::<i64>() as f64;
    let nnew = n as f64 - nret;
    println!("model: returning {} (A {:.4}, B {:.4}), new {} (A {:.4}, B {:.4})", nret, ra / nret, rb / nret, nnew,
             (sum_a as f64 - ra) / nnew, (sum_b as f64 - rb) / nnew);
    let (sa, sb, st, v) = neyman(&ya, &yb, na, nb);
    println!("exact: S_A^2 {:.6}, S_B^2 {:.6}, S_tau^2 {:.6}", sa, sb, st);
    println!("exact: SD of tau hat over all lotteries {:.6}; usual SE formula {:.6}", v.sqrt(), (sa / na + sb / nb).sqrt());
    let (sa8, sb8): ([i64; 8], [i64; 8]) = ([1, 0, 0, 1, 0, 0, 0, 0], [1, 1, 1, 0, 0, 0, 0, 0]);  // road 2
    let (mut gaps8, mut in_b, mut total8) = (Vec::new(), 0, 0i64);
    for mask in 0u32..256 {
        if mask.count_ones() != 4 { continue }   // every way to put 4 of the 8 into B
        let b: i64 = (0..8).filter(|i| mask >> i & 1 == 1).map(|i| sb8[i]).sum();
        let a: i64 = (0..8).filter(|i| mask >> i & 1 == 0).map(|i| sa8[i]).sum();
        gaps8.push((b - a) as f64 / 4.0); total8 += b - a; in_b += mask & 1;
    }
    let len8 = gaps8.len() as f64; let (tau8, m8) = ((sb8.iter().sum::<i64>() - sa8.iter().sum::<i64>()) as f64 / 8.0, gaps8.iter().sum::<f64>() / len8);
    let v8 = gaps8.iter().map(|g| (g - m8).powi(2)).sum::<f64>() / len8;
    let f8 = neyman(&sa8, &sb8, 4.0, 4.0).3;
    let (mn8, mx8) = gaps8.iter().fold((f64::MAX, f64::MIN), |(l, h), &g| (l.min(g), h.max(g)));
    println!("enumeration, 8 visitors: {} lotteries; visitor 1 lands in B in {} of {}", gaps8.len(), in_b, gaps8.len());
    println!("enumeration: tau {:.4}, mean of all gaps {:.4}; variance {:.6}, formula {:.6}", tau8, m8, v8, f8);
    println!("enumeration: smallest gap {:.4}, largest {:.4}", mn8, mx8);
    let mut rng = Rng(SEED);                                     // road 3: seeded lotteries
    let (mut perm, mut sims, mut cover, mut bins): (Vec<usize>, Vec<f64>, usize, [usize; 10]) = ((0..n).collect(), Vec::new(), 0, [0; 10]);
    for t in 0..R {
        for i in 0..NB {                                        // the first NB places of a Fisher-Yates shuffle go to B
            let j = i + (rng.next() % (n - i) as u64) as usize; perm.swap(i, j);
        }
        let b = perm[..NB].iter().map(|&k| yb[k]).sum::<i64>();
        let a = perm[NB..].iter().map(|&k| ya[k]).sum::<i64>();
        let (af, bf) = (a as f64, b as f64);
        let g = bf / nb - af / na;
        let se = (af / na * (1.0 - af / na) / na + bf / nb * (1.0 - bf / nb) / nb).sqrt();
        if (g - tau).abs() <= za * se { cover += 1 }
        sims.push(g);
        bins[(b - a + 20).div_euclid(20).clamp(0, 9) as usize] += 1;   // 0.2-point bins; the end bins take the tails
        if t == 0 {
            println!("simulation: first lottery, returning share in B {:.4}, in A {:.4}",
                     perm[..NB].iter().map(|&k| ret[k]).sum::<i64>() as f64 / nb, perm[NB..].iter().map(|&k| ret[k]).sum::<i64>() as f64 / na);
        }
    }
    let rf = R as f64;
    let ms = sims.iter().sum::<f64>() / rf;
    let sd = (sims.iter().map(|g| (g - ms).powi(2)).sum::<f64>() / (rf - 1.0)).sqrt();
    let (mn, mx) = sims.iter().fold((f64::MAX, f64::MIN), |(l, h), &g| (l.min(g), h.max(g)));
    println!("simulation: {} lotteries, seed {}: mean gap {:.5} +- {:.5}, SD {:.6}", R, SEED, ms, sd / rf.sqrt(), sd);
    println!("simulation: the 95% interval caught tau in {} of {} ({:.4})", cover, R, cover as f64 / rf);
    println!("simulation: smallest gap {:.4}, largest {:.4}", mn, mx);
    println!("breaks, B shown to returning visitors only: gap {:.4}", rb / nret - (sum_a as f64 - ra) / nnew);
    println!("breaks, B shown to new visitors only: gap {:.4}", (sum_b as f64 - rb) / nnew - ra / nret);
    let (s0, s1) = spreads(0.05, 0.058);                         // sizing
    let (mut lo, mut hi) = (0.05, 0.07);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if power(na, 0.05, mid, za) < 0.80 { lo = mid } else { hi = mid } }
    let (pf, pe) = (power(na, 0.05, 0.058, za), power_exact(NA, 0.05, 0.058, za));
    let need = n_need(0.05, 0.058, za, zb);
    println!("sizing: z(0.975) {:.6}, z(0.80) {:.6}, sigma0 {:.6}, sigma1 {:.6}", za, zb, s0, s1);
    println!("sizing: 0.0500 -> 0.0580: (({:.6} + {:.6}) / 0.008)^2 = {:.1}, needs {} per arm", za * s0, zb * s1, ((za * s0 + zb * s1) / 0.008).powi(2), need);
    println!("sizing: power at {} per arm, formula {:.4}, exact count {:.4}", NA, pf, pe);
    println!("sizing: smallest lift found with 80% power at {} per arm: 0.0500 -> {:.5}", NA, hi);
    println!("sizing: 0.0500 -> 0.0550 needs {} per arm; power at {} per arm {:.4}", n_need(0.05, 0.055, za, zb), NA, power(na, 0.05, 0.055, za));
    let ns: Vec<usize> = (1..=10).map(|i| 2000 * i).collect();
    let starts: Vec<String> = (0..10).map(|i| format!("{:.1}", -0.2 + 0.2 * i as f64)).collect();
    println!("figure, gap bin starts (points) {}", starts.join(" "));
    println!("figure, lotteries per bin {}", bins.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    println!("figure, visitors per arm {}", ns.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    println!("figure, power at 0.8-point lift {}", ns.iter().map(|&m| format!("{:.2}", power(m as f64, 0.05, 0.058, za))).collect::<Vec<_>>().join(" "));
    let diff8 = sb8.iter().sum::<i64>() - sa8.iter().sum::<i64>(); assert!(total8 * 8 == gaps8.len() as i64 * 4 * diff8);  // vs tau
    assert!((v8 - f8).abs() < 1e-12 && 2 * in_b as usize == gaps8.len());   // enumeration vs variance formula; Step 1
    let s8 = neyman(&sa8, &sb8, 4.0, 4.0); assert!(v8 < s8.0 / 4.0 + s8.1 / 4.0);  // usual variance errs on the safe side
    assert!((ms - tau).abs() < 4.0 * sd / rf.sqrt() && (sd / v.sqrt() - 1.0).abs() < 0.15);  // simulation vs exact
    assert!((pf - pe).abs() < 0.01);                                        // formula vs exact count
    assert!(power(need as f64, 0.05, 0.058, za) >= 0.80 && 0.80 > power((need - 1) as f64, 0.05, 0.058, za));
    assert!((za - 1.959963984540054).abs() < 1e-9);                         // published 97.5% point
    assert!(cover as f64 / rf > 0.93);                                      // coverage by lottery
    println!("all checks passed");
}
