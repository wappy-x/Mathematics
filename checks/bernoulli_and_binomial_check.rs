// Binomial: the number of successes in n independent tries -- the check behind
// the card.  Rust std only.  Ten coin flips: the fair coin (p = 0.5) and a
// bent coin that lands heads 60% of the time (p = 0.6).  Four roads: the
// formula, weighing all 1024 head-tail strings, adding one flip at a time
// (Pascal's rule), and a seeded simulation (SplitMix64).
const N: usize = 10;
const RUNS: usize = 100000;

fn choose(n: u64, k: u64) -> u64 {           // C(n, k) by the multiplicative rule
    let mut c = 1;
    for j in 1..=k { c = c * (n + 1 - j) / j; }
    c
}

fn formula(n: usize, p: f64) -> Vec<f64> {   // road 1: C(n, k) p^k (1 - p)^(n - k)
    (0..=n).map(|k| choose(n as u64, k as u64) as f64 * p.powi(k as i32) * (1.0 - p).powi((n - k) as i32)).collect()
}

fn strings(n: usize, p: f64) -> (Vec<f64>, Vec<u64>) {   // road 2: weigh every string
    let (mut law, mut count) = (vec![0.0; n + 1], vec![0u64; n + 1]);
    for s in 0..(1u32 << n) {
        let (mut w, mut heads) = (1.0, 0);
        for i in 0..n {
            if s >> i & 1 == 1 { w *= p; heads += 1; } else { w *= 1.0 - p; }
        }
        law[heads] += w;
        count[heads] += 1;
    }
    (law, count)
}

fn one_flip_at_a_time(n: usize, p: f64) -> Vec<f64> {   // road 3: new[k] = p old[k-1] + (1-p) old[k]
    let mut law = vec![1.0];
    for _ in 0..n {
        let mut old = vec![0.0];
        old.extend(&law);
        old.push(0.0);
        law = (0..=law.len()).map(|k| p * old[k] + (1.0 - p) * old[k + 1]).collect();
    }
    law
}

struct SplitMix64 { state: u64 }            // road 4: SplitMix64 with a stated seed
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn simulate(rng: &mut SplitMix64, p: f64, runs: usize) -> Vec<usize> {   // tally heads per run
    let mut tally = vec![0usize; N + 1];
    for _ in 0..runs {
        let heads = (0..N).filter(|_| rng.uniform() < p).count();
        tally[heads] += 1;
    }
    tally
}

fn moments(law: &[f64]) -> (f64, f64) {
    let mean: f64 = law.iter().enumerate().map(|(k, w)| k as f64 * w).sum();
    let second: f64 = law.iter().enumerate().map(|(k, w)| (k * k) as f64 * w).sum();
    (mean, second - mean * mean)
}

fn row(label: &str, v: f64) { rowd(label, v, 6); }
fn rowd(label: &str, v: f64, d: usize) { println!("{:<44}{:>12.*}", label, d, v); }
fn tail(law: &[f64], from: usize) -> f64 { law[from..].iter().sum() }

fn main() {
    let mut rng = SplitMix64 { state: 20260928 };
    let count = strings(N, 0.5).1;               // the tally of strings does not depend on p
    let cs: Vec<String> = count.iter().map(|c| c.to_string()).collect();
    println!("strings with k = 0..10 heads  {}", cs.join(" "));
    println!("{:<44}{:>12}", "strings with exactly 7 heads, of 1024", count[7]);
    println!("{:<44}{:>12}", "strings with 7 or more heads", count[7..].iter().sum::<u64>());
    let mut res = Vec::new();
    for (name, p) in [("fair", 0.5), ("bent", 0.6)] {
        let (f1, f2, f3) = (formula(N, p), strings(N, p).0, one_flip_at_a_time(N, p));
        let tally = simulate(&mut rng, p, RUNS);
        let (mean, var) = moments(&f3);
        let r = RUNS as f64;
        let (s7, s_tail) = (tally[7] as f64 / r, tally[7..].iter().sum::<usize>() as f64 / r);
        let s_mean = tally.iter().enumerate().map(|(k, t)| (k * t) as f64).sum::<f64>() / r;
        let s_var = tally.iter().enumerate().map(|(k, t)| (k * k * t) as f64).sum::<f64>() / r - s_mean * s_mean;
        println!("--- {} coin, p = {}", name, p);
        rowd("one string with 7 heads, p^7 (1-p)^3", p.powi(7) * (1.0 - p).powi(3), 10);
        row("P(X = 7)  1 formula", f1[7]);
        row("P(X = 7)  2 all strings", f2[7]);
        row("P(X = 7)  3 one flip at a time", f3[7]);
        row(&format!("P(X = 7)  4 simulated, {} runs", RUNS), s7);
        row("          standard error", (s7 * (1.0 - s7) / r).sqrt());
        row("P(X >= 7) 1 formula", tail(&f1, 7));
        row("P(X >= 7) 3 one flip at a time", tail(&f3, 7));
        row("P(X >= 7) 4 simulated", s_tail);
        row("          standard error", (s_tail * (1.0 - s_tail) / r).sqrt());
        row("mean: n p", N as f64 * p);
        row("mean: sum of k P(X = k)", mean);
        row("mean: simulated", s_mean);
        row("          standard error", (s_var / r).sqrt());
        row("variance: n p (1 - p)", N as f64 * p * (1.0 - p));
        row("variance: sum of k^2 P(X = k) - mean^2", var);
        row("variance: simulated", s_var);
        let pts: Vec<String> = f1.iter().map(|w| format!("{:.4}", w)).collect();
        println!("chart, {}  {}", name, pts.join(" "));
        res.push((p, f1, f2, f3, s7, s_tail, mean, var));
    }
    println!("--- what breaks, fair coin");
    row("no C(10,7): one string only", 0.5f64.powi(10));
    row("every count equally likely, 1/11", 1.0 / 11.0);
    row("tail without 7 itself, P(X > 7)", tail(&formula(N, 0.5), 8));
    let mut copy = vec![0.0; N + 1];             // one flip copied ten times: all heads or none
    copy[0] = 0.5;
    copy[N] = 0.5;
    row("one flip copied ten times: P(X = 7)", copy[7]);
    row("one flip copied ten times: P(X >= 7)", tail(&copy, 7));
    row("one flip copied ten times: variance", moments(&copy).1);
    println!("--- try changing");
    row("try: 20 fair flips, exactly 14 heads", formula(20, 0.5)[14]);
    row("try: p = 0.4, exactly 3 heads", formula(N, 0.4)[3]);
    row("try: 100 fair flips, 60 or more heads", tail(&one_flip_at_a_time(100, 0.5), 60));
    row("try: p = 0.7, variance", moments(&one_flip_at_a_time(N, 0.7)).1);

    for (p, f1, f2, f3, s7, s_tail, mean, var) in &res {
        for k in 0..=N { assert!((f1[k] - f2[k]).abs() < 1e-12 && (f1[k] - f3[k]).abs() < 1e-12, "three exact roads"); }
        assert!((mean - N as f64 * p).abs() < 1e-12 && (var - N as f64 * p * (1.0 - p)).abs() < 1e-12, "moments vs np, np(1-p)");
        let (e7, et) = (f1[7], tail(f1, 7));
        let r = RUNS as f64;
        assert!((s7 - e7).abs() < 4.0 * (e7 * (1.0 - e7) / r).sqrt(), "simulation within 4 SE");
        assert!((s_tail - et).abs() < 4.0 * (et * (1.0 - et) / r).sqrt(), "simulation within 4 SE");
    }
    assert!(count[7] == choose(N as u64, 7) && count[7..].iter().sum::<u64>() == 176, "strings vs C(10, k)");
    assert!((moments(&copy).1 - 25.0).abs() < 1e-12, "copied flip: variance n^2 p (1-p)");
    println!("ALL CHECKS PASS");
}
