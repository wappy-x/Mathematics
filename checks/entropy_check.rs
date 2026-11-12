// Entropy -- the same check as the Python, in Rust.  No crates; f64's log2
// and ln are the only maths used, and neither knows what entropy is.
// A weather station sends one forecast a day: sunny, cloudy, rain or snow.
// The entropy of its forecast is reached four ways: the formula, the question
// tree played outcome by outcome, one yes-or-no question at a time, and a
// seeded simulation that counts the questions it actually asks.
const NAMES: [&str; 4] = ["sunny", "cloudy", "rain", "snow"];
const P: [f64; 4] = [0.5, 0.25, 0.125, 0.125];       // the station's forecast chances
const WINTER: [f64; 4] = [0.125, 0.125, 0.25, 0.5];  // a snowy month, same four outcomes
const SEED: u64 = 2026;                              // the simulation's starting state

fn term(p: f64) -> f64 {                     // one outcome's share: p x log2(1/p), 0 when p = 0
    if p == 0.0 { 0.0 } else { p * (1.0 / p).log2() }
}

fn entropy(ps: &[f64]) -> f64 {              // road 1: the formula
    ps.iter().map(|&p| term(p)).sum()
}

fn h(p: f64) -> f64 {                        // binary entropy: a yes-or-no with chance p
    term(p) + term(1.0 - p)
}

fn questions(k: usize) -> u64 {              // play the tree: sunny? then cloudy? then rain?
    let mut asked = 0;
    for guess in 0..3 {
        asked += 1;
        if k == guess || guess == 2 { return asked; }   // a no to "rain?" means snow
    }
    asked
}

fn splitmix64(state: u64) -> (u64, u64) {    // small seeded generator, written out
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn draw(u: f64, ps: &[f64]) -> usize {       // which outcome a uniform number u picks
    let mut acc = 0.0;
    for (k, &p) in ps.iter().enumerate() {
        acc += p;
        if u < acc { return k; }
    }
    ps.len() - 1
}

fn main() {
    let h1 = entropy(&P);
    let qs: Vec<u64> = (0..4).map(questions).collect();
    let tree: f64 = P.iter().zip(&qs).map(|(&p, &q)| p * q as f64).sum();       // road 2
    let chain = h(0.5) + 0.5 * (h(0.5) + 0.5 * h(0.5));                           // road 3
    let (mut state, n, mut total, mut total_sq, mut year) = (SEED, 100000u64, 0u64, 0u64, 0u64);
    for day in 0..n {                                                            // road 4
        let (s, z) = splitmix64(state);
        state = s;
        let q = questions(draw((z >> 11) as f64 / 2f64.powi(53), &P));
        total += q;
        total_sq += q * q;
        if day == 364 { year = total; }
    }
    let mean = total as f64 / n as f64;
    let se = ((total_sq as f64 / n as f64 - mean * mean) / n as f64).sqrt();
    let gap: f64 = P.iter().map(|&p| p * (p / 0.25).log2()).sum();
    let (mut grid, mut best, mut best_at) = (0, -1.0f64, [0usize; 4]);
    for a in 0..21 {
        for b in 0..21 - a {
            for c in 0..21 - a - b {
                let ks = [a, b, c, 20 - a - b - c];
                grid += 1;
                let v = entropy(&ks.map(|k| k as f64 / 20.0));
                if v > best { best = v; best_at = ks; }
            }
        }
    }
    let curve: Vec<f64> = (0..21).map(|i| h(i as f64 / 20.0)).collect();
    let climates: [(&str, [f64; 4]); 5] = [("every day sunny", [1.0, 0.0, 0.0, 0.0]),
        ("desert", [0.85, 0.1, 0.04, 0.01]), ("our station", P),
        ("four-way spread", [0.4, 0.3, 0.2, 0.1]), ("all four equal", [0.25; 4])];
    let winter_cost: f64 = WINTER.iter().zip(&qs).map(|(&p, &q)| p * q as f64).sum();
    let winter_kl: f64 = WINTER.iter().zip(&qs).map(|(&p, &q)| p * (p / 2f64.powi(-(q as i32))).log2()).sum();

    let f: Vec<String> = NAMES.iter().zip(P).map(|(a, p)| format!("{} {}", a, p)).collect();
    println!("forecast: {}", f.join(", "));
    let s: Vec<String> = NAMES.iter().zip(P).map(|(a, p)| format!("{} {:.4}", a, (1.0 / p).log2())).collect();
    println!("surprise log2(1/p), bits: {}", s.join(", "));
    println!("road 1, the formula: H = {:.4} bits", h1);
    println!("road 2, the question tree: questions {:?}, weighted average {:.4}", qs, tree);
    println!("road 3, one question at a time: h(0.5) + 0.5 x (h(0.5) + 0.5 x h(0.5)) = {:.4}", chain);
    println!("road 4, {} simulated days, seed {}: {} questions, {:.4} a day, standard error {:.4}", n, SEED, total, mean, se);
    println!("first simulated year, 365 days: {} questions, against {} for two fixed bits a day", year, 2 * 365);
    println!("expected over 365 days: {:.2} bits by questions, {:.2} by two fixed bits", 365.0 * h1, 365.0 * 2.0);
    println!("all four equal: H = {:.4} bits; log2 4 = {:.4}", entropy(&[0.25; 4]), 4f64.log2());
    println!("gap to all-equal, sum of p log2(p / 0.25): {:.4}; 2 - H = {:.4}", gap, 2.0 - h1);
    println!("grid search, {} forecasts in steps of 0.05: largest H {:.4} at {:?}", grid, best,
             best_at.map(|k| k as f64 / 20.0));
    println!("binary entropy h(p), p = 0, 0.05, ..., 1:");
    let c: Vec<String> = curve.iter().map(|v| format!("{:.3}", v)).collect();
    println!("{}", c.join(" "));
    println!("h(0.5) sunny or not {:.4}; h(0.125) snow or not {:.4}; h(0.05) {:.4}; h(0.95) {:.4}",
             h(0.5), h(0.125), h(0.05), h(0.95));
    for (name, ps) in climates.iter() {
        let v = entropy(ps);
        println!("{:<16} {:<40} {:.4}", name, "#".repeat((v * 20.0 + 0.5) as usize), v);
    }
    println!("mistake 1, natural log in place of log2: {:.4}", P.iter().map(|&p| p * (1.0 / p).ln()).sum::<f64>());
    println!("mistake 2, questions averaged without weights: {:.4}", qs.iter().sum::<u64>() as f64 / 4.0);
    println!("mistake 3, usual tree on winter weather: {:.4} a day; winter's own H {:.4}; extra {:.4}",
             winter_cost, entropy(&WINTER), winter_kl);
    println!("mistake 4, counting outcomes, log2 4: {:.4}, {:.4} too many", 4f64.log2(), 4f64.log2() - h1);
    println!("sunny then snow: chance {}, surprise {:.4} = 1 + 3", 0.5 * 0.125, (1.0 / (0.5 * 0.125f64)).log2());
    println!("asides: 1 nat = {:.4} bits; log2 26 = {:.4}; log2 3 = {:.4}; h(0.01) = {:.4}; 2^20 = {}",
             1.0 / 2f64.ln(), 26f64.log2(), 3f64.log2(), h(0.01), 1u64 << 20);

    assert!((h1 - tree).abs() < 1e-12 && (h1 - chain).abs() < 1e-12);         // roads 1, 2, 3 agree
    assert!((mean - h1).abs() < 4.0 * se);                                      // road 4, within 4 errors
    assert!(best_at == [5, 5, 5, 5] && (best - 4f64.log2()).abs() < 1e-12);     // all-equal is the top
    assert!((0..21).all(|a| (entropy(&[a as f64 / 20.0, 1.0 - a as f64 / 20.0, 0.0, 0.0]) - h(a as f64 / 20.0)).abs() < 1e-12));
    assert!((gap - (2.0 - h1)).abs() < 1e-12);                                  // the gap is the divergence
    assert!((0..21).all(|i| (curve[i] - curve[20 - i]).abs() < 1e-12)
        && curve.iter().cloned().fold(f64::MIN, f64::max) == curve[10]);
    assert!((winter_cost - (entropy(&WINTER) + winter_kl)).abs() < 1e-12 && winter_cost > 2.0);
    println!("ALL CHECKS PASS");
}
