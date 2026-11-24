// Multi-armed bandits -- the same check as the Python, in Rust.  No crates.
// Three release rules for a hydro plant; each hour one is used, and it succeeds
// (meets the grid's order inside the level band) with unknown chance 0.3, 0.5 or
// 0.6.  Maximise successes; regret = successes lost against always using the best.
// Roads: (1) closed forms: UCB index, KL, the Lai-Robbins constant, the UCB1 bound;
// (2) 100 seeded simulated runs of 10000 hours for each method, regret counted two
// ways; (3) Thompson's choice chances by numerical integration against its sampler.
use std::f64::consts::PI;
const MU: [f64; 3] = [0.3, 0.5, 0.6];
const SWAP: [f64; 3] = [0.6, 0.5, 0.3];
const T: usize = 10000;
const RUNS: usize = 100;
struct Rng { x: u64 }                            // SplitMix64, seeded
impl Rng {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.x ^ (self.x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
}
fn normal(g: &mut Rng) -> f64 {
    let r = (-2.0 * (1.0 - g.unif()).ln()).sqrt();
    r * (2.0 * PI * g.unif()).cos()
}
fn gamma(g: &mut Rng, a: f64) -> f64 {           // Marsaglia-Tsang, shape a >= 1
    let d = a - 1.0 / 3.0;
    let c = 1.0 / (9.0 * d).sqrt();
    loop {
        let x = normal(g);
        let w = 1.0 + c * x;
        if w <= 0.0 { continue; }
        let v = w * w * w;
        if (1.0 - g.unif()).ln() < 0.5 * x * x + d - d * v + d * v.ln() { return d * v; }
    }
}
fn beta(g: &mut Rng, a: f64, b: f64) -> f64 { let x = gamma(g, a); x / (x + gamma(g, b)) }
fn kl(p: f64, q: f64) -> f64 { p * (p / q).ln() + (1.0 - p) * ((1.0 - p) / (1.0 - q)).ln() }
fn argmax(v: &[f64]) -> usize { (0..v.len()).fold(0, |b, i| if v[i] > v[b] { i } else { b }) }
fn comb(n: u64, k: u64) -> f64 { (0..k).fold(1u64, |c, i| c * (n - i) / (i + 1)) as f64 }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(",") }
fn run(method: &str, seed: u64, marks: &[usize], eps: f64, swap: bool) -> ([usize; 3], usize, Vec<f64>, f64) {
    let gap: Vec<f64> = MU.iter().map(|m| 0.6 - m).collect();
    let (mut g, mut n, mut s, mut got, mut out, mut late) = (Rng { x: seed }, [0usize; 3], [0usize; 3], 0, vec![], 0.0);
    for t in 1..=T {
        let mu = if swap && t > T / 2 { SWAP } else { MU };
        let i = if method == "ts" {
            let v: Vec<f64> = (0..3).map(|j| beta(&mut g, (1 + s[j]) as f64, (1 + n[j] - s[j]) as f64)).collect();
            argmax(&v)
        } else if t <= 3 { t - 1 }                // the others try each rule once first
        else if method == "ucb" {
            let v: Vec<f64> = (0..3).map(|j| s[j] as f64 / n[j] as f64
                + (2.0 * ((t - 1) as f64).ln() / n[j] as f64).sqrt()).collect();
            argmax(&v)
        } else if g.unif() < eps { (g.next() % 3) as usize }   // explore
        else { argmax(&(0..3).map(|j| s[j] as f64 / n[j] as f64).collect::<Vec<_>>()) };
        let win = if g.unif() < mu[i] { 1 } else { 0 };
        n[i] += 1; s[i] += win; got += win;
        if t > T / 2 { late += 0.6 - mu[i]; }
        if marks.contains(&t) { out.push((0..3).fold(0.0, |a, j| a + gap[j] * n[j] as f64)); }
    }
    (n, got, out, late)
}
fn pdf(x: f64, a: u64, b: u64) -> f64 {
    (a + b - 1) as f64 * comb(a + b - 2, a - 1) * x.powf((a - 1) as f64) * (1.0 - x).powf((b - 1) as f64)
}
fn cdf(x: f64, a: u64, b: u64) -> f64 {          // integer a, b: a binomial tail
    let m = a + b - 1;
    (a..=m).fold(0.0, |t, k| t + comb(m, k) * x.powf(k as f64) * (1.0 - x).powf((m - k) as f64))
}
fn main() {
    let gap: Vec<f64> = MU.iter().map(|m| 0.6 - m).collect();
    let l30 = 30f64.ln();
    println!("ln 30 = {:.4}", l30);
    for &(name, k, m) in [("A", 6.0, 1.0), ("B", 10.0, 5.0), ("C", 14.0, 8.0)].iter() {
        let b = (2.0 * l30 / k).sqrt();
        println!("index,rule {},tries {},mean {:.4},bonus {:.4},index {:.4}", name, k, m / k, b, m / k + b);
    }
    let kls = [kl(MU[0], 0.6), kl(MU[1], 0.6)];
    let lr = 0.0 + gap[0] / kls[0] + gap[1] / kls[1];
    println!("KL(0.3,0.6) {:.5}, KL(0.5,0.6) {:.5}; terms {:.3} + {:.3} = {:.4}", kls[0], kls[1], gap[0] / kls[0], gap[1] / kls[1], lr);
    let c3 = 1.0 + PI * PI / 3.0;
    let ub = |h: f64| (0..2).fold(0.0, |a, i| a + (8.0 * h.ln() / gap[i] + c3 * gap[i]));
    let tf = T as f64;
    println!("at T={}: Lai-Robbins {:.2}, UCB1 bound {:.2}, pull bounds A {:.0} B {:.0}", T, lr * tf.ln(), ub(tf),
             8.0 * tf.ln() / 0.09 + c3, 8.0 * tf.ln() / 0.01 + c3);
    let mut cross = 2usize;
    while 0.1 * (0.3 + 0.1) / 3.0 * cross as f64 <= ub(cross as f64) { cross += 1; }
    println!("epsilon-greedy floor 0.1 x 0.4/3 x T passes the UCB1 bound from T = {}", cross);
    let marks = [100, 200, 500, 1000, 2000, 5000, 10000];
    let mut res = vec![];
    for &meth in ["eps", "greedy", "ucb", "ts"].iter() {
        let (mut reg, mut real, mut pulls, mut lost) = (vec![0.0; marks.len()], vec![], [0usize; 3], 0);
        for r in 0..RUNS {
            let (n, got, out, _) = run(meth, 1000 + r as u64, &marks, if meth == "greedy" { 0.0 } else { 0.1 }, false);
            for k in 0..marks.len() { reg[k] = reg[k] + out[k] / RUNS as f64; }
            real.push(0.6 * tf - got as f64);
            for j in 0..3 { pulls[j] += n[j]; }
            if (n[2] as f64) < tf / 2.0 { lost += 1; }
        }
        let mr = real.iter().fold(0.0, |a, x| a + x) / RUNS as f64;
        let se = (real.iter().fold(0.0, |a, x| a + (x - mr) * (x - mr)) / (RUNS - 1) as f64 / RUNS as f64).sqrt();
        let pm: Vec<f64> = pulls.iter().map(|&p| p as f64 / RUNS as f64).collect();
        println!("{}: regret {}; realised {:.1} (se {:.1}); mean pulls {}; runs with C under half {}", meth, join(&reg, 1), mr, se, join(&pm, 1), lost);
        res.push((reg, mr, se, lost, pulls));
    }
    println!("Lai-Robbins 6.53 ln T: {}", join(&marks.iter().map(|&h| lr * (h as f64).ln()).collect::<Vec<_>>(), 1));
    let (ep, u, th) = (res[0].0.clone(), res[2].0.clone(), res[3].0.clone());
    println!("growth 5000->10000: eps {:.1}, ucb {:.1}, ts {:.1}", ep[6] - ep[5], u[6] - u[5], th[6] - th[5]);
    let bon: Vec<f64> = (0..2).map(|j| (2.0 * tf.ln() * RUNS as f64 / res[2].4[j] as f64).sqrt()).collect();   // UCB1 bonus at the mean pulls
    println!("ucb bonus at T={}, mean pulls: rule A {:.3} (gap {:.1}), rule B {:.3} (gap {:.1})", T, bon[0], gap[0], bon[1], gap[1]);
    let mut lates = vec![];
    for &meth in ["ucb", "ts"].iter() {             // the world changes: A and C swap after T/2
        let late = (0..20).fold(0.0, |a, r| a + run(meth, 1000 + r, &[], 0.1, true).3) / 20.0;
        println!("swap at hour {}: {} regret over the second half {:.1}", T / 2, meth, late);
        lates.push(late);
    }
    let post = [(2u64, 6u64), (6, 6), (9, 7)];   // Thompson's posteriors at the hand state
    let nn = 2000usize;
    let mut win = vec![];
    for i in 0..3 {                              // Simpson's rule on f_i(x) F_j(x) F_k(x)
        let mut tot = 0.0;
        for k in 0..=nn {
            let x = k as f64 / nn as f64;
            let wt = if k == 0 || k == nn { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
            let mut f = pdf(x, post[i].0, post[i].1);
            for j in 0..3 { if j != i { f *= cdf(x, post[j].0, post[j].1); } }
            tot += wt * f;
        }
        win.push(tot / (3 * nn) as f64);
    }
    let (mut g, mut cnt, d) = (Rng { x: 7 }, [0usize; 3], 60000usize);
    let first: Vec<f64> = post.iter().map(|&(a, b)| beta(&mut g, a as f64, b as f64)).collect();
    cnt[argmax(&first)] += 1;
    for _ in 0..d - 1 {
        let v: Vec<f64> = post.iter().map(|&(a, b)| beta(&mut g, a as f64, b as f64)).collect();
        cnt[argmax(&v)] += 1;
    }
    let fr: Vec<f64> = cnt.iter().map(|&c| c as f64 / d as f64).collect();
    println!("thompson draw {}; win chance by integral {}; by sampling {}", join(&first, 4), join(&win, 4), join(&fr, 4));
    let zs: Vec<String> = (0..3).map(|i| format!("{:+.2}", (fr[i] - win[i]) / (win[i] * (1.0 - win[i]) / d as f64).sqrt())).collect();
    println!("sampling minus integral, in standard errors: {}", zs.join(","));
    assert!((5.0 / 10.0 + (2.0 * l30 / 10.0).sqrt() - 1.3248).abs() < 5e-5 && (lr - 6.53).abs() < 5e-3); // road 1
    for k in [0usize, 2, 3] { assert!((res[k].1 - res[k].0[6]).abs() < 4.0 * res[k].2); }                 // road 2
    assert!(u[6] < ub(tf) && th[6] < u[6] && ep[6] - ep[5] > 50.0 && u[6] - u[5] < (ep[6] - ep[5]) / 2.0);
    assert!(bon[0] > gap[0] && bon[1] > gap[1] && lates[1] > 3.0 * lates[0] && lates[0] > 0.0 && res[1].3 > 0 && res[2].3 == 0 && res[3].3 == 0);
    for i in 0..3 { assert!((win[i] - fr[i]).abs() < 4.0 * (win[i] * (1.0 - win[i]) / d as f64).sqrt()); } // road 3
    assert!((win.iter().fold(0.0, |a, w| a + w) - 1.0).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
