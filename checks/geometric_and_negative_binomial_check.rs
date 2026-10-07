// Geometric and negative binomial -- the same check as the Python, in Rust.  Std only, no crates.
// Rolling a fair die until the first six (X), and until the third six (T3).
// Roads: the formula; a count over all 6^6 sequences of six rolls; the masses summed
// term by term; the binomial count of sixes; a seeded simulation (SplitMix64).
const P: f64 = 1.0 / 6.0;
const Q: f64 = 5.0 / 6.0;

fn pw(x: f64, n: u32) -> f64 {        // x to the power n, by repeated multiplication
    let mut out = 1.0;
    for _ in 0..n { out *= x; }
    out
}
fn comb(n: u64, k: u64) -> u64 {      // C(n, k), exact in integers
    let mut out = 1u64;
    for j in 1..=k { out = out * (n - k + j) / j; }
    out
}
fn geo(k: u32) -> f64 {               // P(X = k): k-1 misses, then a six
    pw(Q, k - 1) * P
}
fn negbin(r: u32, k: u32) -> f64 {    // P(T_r = k): r-1 sixes in the first k-1 rolls, then a six
    if k >= r { comb((k - 1) as u64, (r - 1) as u64) as f64 * pw(P, r) * pw(Q, k - r) } else { 0.0 }
}
fn row(label: &str, v: f64) {
    println!("{:<46}{:>12.6}", label, v);
}

struct SplitMix(u64);
impl SplitMix {
    fn die(&mut self) -> u64 {            // a face from 1 to 6
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        (((z as u128) * 6) >> 64) as u64 + 1
    }
    fn wait_for(&mut self, r: u32) -> u64 {
        let (mut n, mut got) = (0u64, 0u32);
        while got < r {
            n += 1;
            if self.die() == 6 { got += 1; }
        }
        n
    }
}
fn mean_se(s: u64, s2: u64, n: u64) -> (f64, f64) {
    let (sf, nf) = (s as f64, n as f64);
    (sf / nf, ((s2 as f64 - sf * sf / nf) / (nf - 1.0) / nf).sqrt())
}

fn main() {
    // ---- road 1: the formula ----
    for (label, v) in [
        ("formula  P(X=1)", geo(1)), ("formula  P(X=5)", geo(5)),
        ("formula  P(X>3)  no six in 3 rolls", pw(Q, 3)),
        ("formula  P(X<=4) a six within 4 rolls", 1.0 - pw(Q, 4)),
        ("formula  P(X<=6) a six within 6 rolls", 1.0 - pw(Q, 6)),
        ("formula  P(X>20) no six in 20 rolls", pw(Q, 20)),
        ("formula  E[X] = 1/p", 1.0 / P), ("formula  Var(X) = q/p^2", Q / (P * P)),
        ("formula  sd(X)", (Q / (P * P)).sqrt()), ("formula  P(T3=5)", negbin(3, 5)),
        ("formula  E[T3] = 3/p", 3.0 / P), ("formula  Var(T3) = 3q/p^2", 3.0 * Q / (P * P)),
        ("formula  sd(T3)", (3.0 * Q / (P * P)).sqrt()),
        ("formula  P(T3>3 | T3>2) = 1 - p^3", 1.0 - pw(P, 3)),
    ] {
        row(label, v);
    }

    // ---- road 2: count every sequence of six rolls (6^6 = 46656, all equally likely) ----
    let (mut first5, mut third5, mut none2, mut none3, mut none5) = (0u64, 0u64, 0u64, 0u64, 0u64);
    for code in 0..6u64.pow(6) {
        let (mut sixes, mut c) = (Vec::new(), code);
        for i in 1..=6u32 {
            if c % 6 == 5 { sixes.push(i); }
            c /= 6;
        }
        let first = if sixes.is_empty() { 99 } else { sixes[0] };
        first5 += (first == 5) as u64;
        third5 += (sixes.len() >= 3 && sixes[2] == 5) as u64;
        none2 += (first > 2) as u64;
        none3 += (first > 3) as u64;
        none5 += (first > 5) as u64;
    }
    println!("{:<46}{:>12}", "count  of 46656 sequences, first six on roll 5", first5);
    println!("{:<46}{:>12}", "count  of 46656 sequences, third six on roll 5", third5);
    row("count  P(X=5)", first5 as f64 / 46656.0);
    row("count  P(T3=5)", third5 as f64 / 46656.0);
    row("count  P(X>5 | X>2)", none5 as f64 / none2 as f64);
    row("count  P(X>3)", none3 as f64 / 46656.0);

    // ---- road 3: sum the masses term by term, out to roll 600 ----
    let (mut tx, mut m1, mut m2, mut tt, mut t1, mut t2) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    for k in 1..=600u32 {
        let (gx, gt, kf) = (geo(k), negbin(3, k), k as f64);
        tx += gx; m1 += kf * gx; m2 += kf * kf * gx;
        tt += gt; t1 += kf * gt; t2 += kf * kf * gt;
    }
    for (label, v) in [("series  total mass of X, rolls 1 to 600", tx), ("series  E[X]", m1), ("series  Var(X)", m2 - m1 * m1),
                       ("series  total mass of T3", tt), ("series  E[T3]", t1), ("series  Var(T3)", t2 - t1 * t1)] {
        row(label, v);
    }

    // ---- road 4: the third six comes after roll n exactly when n rolls hold fewer than 3 sixes ----
    let mut tails = Vec::new();
    for n in [12u32, 18] {
        let by_binom = (0..3u32).fold(0.0, |a, j| a + comb(n as u64, j as u64) as f64 * pw(P, j) * pw(Q, n - j));
        let by_mass = 1.0 - (3..=n).fold(0.0, |a, k| a + negbin(3, k));
        row(&format!("binomial  P(fewer than 3 sixes in {} rolls)", n), by_binom);
        row(&format!("negbin    P(T3 > {})", n), by_mass);
        tails.push((by_binom, by_mass));
    }

    // ---- road 5: seeded simulation, SplitMix64 ----
    let mut rng = SplitMix(20260928);
    let (n1, nt) = (200000u64, 100000u64);
    let (mut s, mut s2, mut past4, mut past7) = (0u64, 0u64, 0u64, 0u64);
    for _ in 0..n1 {
        let x = rng.wait_for(1);
        s += x; s2 += x * x; past4 += (x > 4) as u64; past7 += (x > 7) as u64;
    }
    let (mx, sex) = mean_se(s, s2, n1);
    let frac = past7 as f64 / past4 as f64;
    let se_frac = (frac * (1.0 - frac) / past4 as f64).sqrt();
    let (mut s, mut s2) = (0u64, 0u64);
    for _ in 0..nt {
        let t = rng.wait_for(3);
        s += t; s2 += t * t;
    }
    let (mt, set3) = mean_se(s, s2, nt);
    for (label, v) in [("sim  mean wait for first six, 200000 runs", mx), ("sim    standard error", sex),
                       ("sim  P(X>7 | X>4)", frac), ("sim    standard error", se_frac),
                       ("sim  mean wait for third six, 100000 runs", mt), ("sim    standard error", set3)] {
        row(label, v);
    }

    // ---- what breaks, then try changing ----
    let deal = (0..6).fold(0.0, |a, j| a + (6 - j) as f64 / 6.0);   // six cards, no replacement
    for (label, v) in [
        ("wrong: count misses only, mean q/p", Q / P),
        ("wrong: T3 as 3 copies of one wait, Var 9q/p^2", 9.0 * Q / (P * P)),
        ("wrong: deal 6 cards, mean draws to the 6", deal),
        ("wrong: deal, P(6 next | 5 misses)", (1.0 / 6.0) / ((6.0 - 5.0) / 6.0)),
        ("try: coin, p=1/2, mean", 1.0 / 0.5), ("try: coin, p=1/2, variance", 0.5 / (0.5 * 0.5)),
        ("try: r=10 sixes, mean", 10.0 / P), ("try: r=10 sixes, sd", (10.0 * Q / (P * P)).sqrt()),
        ("try: p=1/100, mean", 1.0 / 0.01), ("try: p=1/100, sd", (0.99f64 / (0.01 * 0.01)).sqrt()),
        ("house: emails 12/3600 a second, mean wait s", 1.0 / (12.0 / 3600.0)),
    ] {
        row(label, v);
    }

    // ---- chart points, rolls 1 to 25 ----
    let ks: Vec<String> = (1..=25u32).map(|k| format!("{}", k)).collect();
    let gs: Vec<String> = (1..=25u32).map(|k| format!("{:.4}", geo(k))).collect();
    let ns: Vec<String> = (1..=25u32).map(|k| format!("{:.4}", negbin(3, k))).collect();
    println!("chart, k       {}", ks.join(" "));
    println!("chart, P(X=k)  {}", gs.join(" "));
    println!("chart, P(T3=k) {}", ns.join(" "));

    assert!(first5 == 5u64.pow(4) * 6, "count of sequences vs 4 misses, a six, any sixth roll");
    assert!((third5 as f64 / 46656.0 - negbin(3, 5)).abs() < 1e-15, "count vs negative binomial mass");
    assert!((none5 as f64 / none2 as f64 - none3 as f64 / 46656.0).abs() < 1e-15
        && (none3 as f64 / 46656.0 - pw(Q, 3)).abs() < 1e-12, "memoryless and tail, by counting");
    assert!((m1 - 1.0 / P).abs() < 1e-9 && (m2 - m1 * m1 - Q / (P * P)).abs() < 1e-9, "series mean and variance vs 1/p, q/p^2");
    assert!((t2 - t1 * t1 - 3.0 * Q / (P * P)).abs() < 1e-9, "series variance vs rq/p^2");
    assert!(tails.iter().all(|&(a, b)| (a - b).abs() < 1e-12), "binomial tail vs negative binomial tail");
    assert!((mx - 6.0).abs() < 4.0 * sex, "simulated first-six wait within 4 standard errors");
    assert!((mt - 18.0).abs() < 4.0 * set3, "simulated third-six wait within 4 standard errors");
    assert!((frac - 125.0 / 216.0).abs() < 4.0 * se_frac, "simulated memorylessness vs (5/6)^3");
    println!("ALL CHECKS PASS");
}
