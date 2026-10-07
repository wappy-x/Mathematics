// Conditional probability -- the same check as the Python, in Rust.  No
// crates.  A screening test: 1% of people have the disease, the test flags
// 90% of those who have it and 5% of those who do not.  Three roads to the
// chance of disease given a positive result: the formula, a town of 10,000
// people counted one by one, and a seeded simulation of 1,000,000 people.
const PREV: f64 = 0.01; // P(D)
const SENS: f64 = 0.90; // P(T | D)
const FPOS: f64 = 0.05; // P(T | not D)
const TOWN: usize = 10_000;
const SIMS: u64 = 1_000_000;
const SEED: u64 = 20260928;

fn by_formula(prev: f64, sens: f64, fpos: f64) -> (f64, f64, f64) {
    let both = prev * sens; // multiplication rule: P(D and T)
    let pos = both + (1.0 - prev) * fpos; // total probability: P(T)
    (both, pos, both / pos) // the definition: P(D | T)
}

fn gcd(mut a: usize, mut b: usize) -> usize {
    while b != 0 {
        (a, b) = (b, a % b);
    }
    a
}

struct SplitMix64 {
    s: u64,
}

impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        // a number in [0, 1) from 53 random bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn row(label: &str, value: String) {
    println!("  {:<40} {}", label, value);
}

fn main() {
    // ---- road 1: the formula ----
    let (both, pos, answer) = by_formula(PREV, SENS, FPOS);
    println!("inputs: P(D) = {:.6}, P(T | D) = {:.6}, P(T | not D) = {:.6}", PREV, SENS, FPOS);
    println!("road 1, the formula");
    row("P(D and T) = P(D) P(T | D)", format!("{:.6}", both));
    row("P(not D and T) = P(not D) P(T | not D)", format!("{:.6}", (1.0 - PREV) * FPOS));
    row("P(T), by total probability", format!("{:.6}", pos));
    row("P(D | T) = P(D and T) / P(T)", format!("{:.6}", answer));
    row("P(not D | T) = 1 - P(D | T)", format!("{:.6}", 1.0 - answer));

    // ---- road 2: a town of 10,000 people, listed and counted ----
    let sick_n = (TOWN as f64 * PREV).round() as usize;
    let sick_pos_n = (TOWN as f64 * PREV * SENS).round() as usize;
    let well_pos_n = (TOWN as f64 * (1.0 - PREV) * FPOS).round() as usize;
    let people: Vec<(bool, bool)> = (0..TOWN) // (has the disease, tests positive)
        .map(|i| if i < sick_n { (true, i < sick_pos_n) } else { (false, i - sick_n < well_pos_n) })
        .collect();
    let sick = people.iter().filter(|p| p.0).count();
    let sick_pos = people.iter().filter(|p| p.0 && p.1).count();
    let well_pos = people.iter().filter(|p| !p.0 && p.1).count();
    let positives: Vec<bool> = people.iter().filter(|p| p.1).map(|p| p.0).collect();
    let n_pos = positives.len();
    let g = gcd(sick_pos, n_pos);
    let sick_among_pos = positives.iter().filter(|&&d| d).count();
    println!("road 2, a town of {} people counted one by one", TOWN);
    row("have the disease", sick.to_string());
    row("  and test positive", sick_pos.to_string());
    row("  and test negative", (sick - sick_pos).to_string());
    row("do not have it", (TOWN - sick).to_string());
    row("  and test positive", well_pos.to_string());
    row("  and test negative", (TOWN - sick - well_pos).to_string());
    row("test positive in all", n_pos.to_string());
    row(&format!("P(D | T) = {} / {} = {} / {}", sick_pos, n_pos, sick_pos / g, n_pos / g),
        format!("{:.6}", sick_among_pos as f64 / n_pos as f64));
    row(&format!("P(not D | T) = {} / {}", well_pos, n_pos), format!("{:.6}", well_pos as f64 / n_pos as f64));

    // ---- road 3: simulate 1,000,000 people ----
    let mut rng = SplitMix64 { s: SEED };
    let (mut s_pos, mut s_both) = (0u64, 0u64);
    for _ in 0..SIMS {
        let d = rng.uniform() < PREV;
        let t = rng.uniform() < if d { SENS } else { FPOS };
        s_pos += t as u64;
        s_both += (d && t) as u64;
    }
    let est_pos = s_pos as f64 / SIMS as f64;
    let est_ans = s_both as f64 / s_pos as f64;
    let se_pos = (est_pos * (1.0 - est_pos) / SIMS as f64).sqrt(); // standard error of each estimate
    let se_ans = (est_ans * (1.0 - est_ans) / s_pos as f64).sqrt();
    let miss_pos = (est_pos - pos).abs() / se_pos;
    let miss_ans = (est_ans - answer).abs() / se_ans;
    println!("road 3, a simulation of {} people, SplitMix64 seed {}", SIMS, SEED);
    row("tested positive", s_pos.to_string());
    row("  of whom have the disease", s_both.to_string());
    row("P(T) estimate", format!("{:.6}  standard error {:.6}", est_pos, se_pos));
    row("P(D | T) estimate", format!("{:.6}  standard error {:.6}", est_ans, se_ans));
    row("misses, in standard errors", format!("{:.2} and {:.2}", miss_pos, miss_ans));

    // ---- what breaks ----
    println!("what breaks (right answer P(D | T) = {:.6})", answer);
    row("swap the condition: P(T | D)", format!("{:.6}", SENS));
    row("divide by everyone: P(D and T)", format!("{:.6}", both));
    row("equal weights: P(T) = (0.90 + 0.05) / 2", format!("{:.6}", (SENS + FPOS) / 2.0));
    row("  so P(D | T) comes out at", format!("{:.6}", both / ((SENS + FPOS) / 2.0)));
    row("drop the healthy branch: P(T)", format!("{:.6}", both));
    row("  so P(D | T) comes out at", format!("{:.6}", both / both));
    row("multiply as if independent: P(D) P(T)", format!("{:.6}", PREV * pos));
    println!("try: one input moved, P(D | T) by the formula");
    row("false-alarm rate 5% -> 1%", format!("{:.6}", by_formula(PREV, SENS, 0.01).2));
    row("hit rate 90% -> 99%", format!("{:.6}", by_formula(PREV, 0.99, FPOS).2));

    // ---- the chart: P(D | T) as the disease gets commoner, formula against count ----
    println!("P(D | T) in percent as prevalence changes, formula and count of 100000");
    let sweep: [(&str, f64, usize); 8] = [("0.1", 0.001, 100), ("0.5", 0.005, 500), ("1", 0.01, 1000),
        ("2", 0.02, 2000), ("5", 0.05, 5000), ("10", 0.10, 10000), ("20", 0.20, 20000), ("50", 0.50, 50000)];
    let mut worst: f64 = 0.0;
    for (name, prev, sick_k) in sweep {
        let f = 100.0 * by_formula(prev, SENS, FPOS).2;
        let (sp, wp) = (sick_k * 9 / 10, (100000 - sick_k) / 20); // integer counts: 90% and 5%
        let c = 100.0 * sp as f64 / (sp + wp) as f64;
        worst = worst.max((f - c).abs());
        row(&format!("prevalence {}%", name), format!("{:6.2}  {:6.2}", f, c));
    }

    assert!((answer - sick_pos as f64 / n_pos as f64).abs() < 1e-12); // formula = count
    assert!((pos - n_pos as f64 / TOWN as f64).abs() < 1e-12); // total probability = count
    assert!(((1.0 - answer) - well_pos as f64 / n_pos as f64).abs() < 1e-12); // complement inside T
    assert!(miss_pos < 4.0 && miss_ans < 4.0); // simulation within 4 SE
    assert!(worst < 1e-9); // sweep: formula = count
    println!("ALL CHECKS PASS");
}
