// Expectation -- the same check as the Python, in Rust.  No crates.  A raffle
// sells 100 tickets at $2; one ticket, drawn at random, wins $100.  One
// ticket's payout X is 0 with chance 0.99 and 100 with chance 0.01.  E[X] is
// reached three ways: the weighted sum, a count over all 100 draws, and a
// seeded simulation.  Linearity is checked on five tickets in one draw
// (dependent) and five tickets in five draws (independent).
struct SplitMix64 { s: u64 }

impl SplitMix64 {                                  // the random numbers, written out here
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.next() >> 11) as f64 / 9007199254740992.0 }
}

const PRICE: f64 = 2.0;
const PRIZE: f64 = 100.0;
const SOLD: usize = 100;
const LAW: [(f64, f64); 2] = [(0.0, 0.99), (PRIZE, 0.01)];   // value, chance

fn expect(g: impl Fn(f64) -> f64) -> f64 {         // road one: the weighted sum
    LAW.iter().map(|&(x, p)| g(x) * p).sum()
}

fn sqrt(v: f64) -> f64 {                           // Newton's method, as in the Python
    let mut r = if v > 1.0 { v } else { 1.0 };
    for _ in 0..60 { r = 0.5 * (r + v / r) }
    r
}

fn main() {
    let e_x = expect(|x| x);
    let mode = if LAW[0].1 >= LAW[1].1 { LAW[0].0 } else { LAW[1].0 };
    // road two: count every draw.  Our ticket is number 0; the winning number w is
    // any of 100, each equally likely.  Our payout in draw w:
    let payouts: Vec<f64> = (0..SOLD).map(|w| if w == 0 { PRIZE } else { 0.0 }).collect();
    let e_count = payouts.iter().sum::<f64>() / SOLD as f64;
    let e_net = payouts.iter().map(|x| x - PRICE).sum::<f64>() / SOLD as f64;
    println!("payout law: 0 with chance {:.2}, 100 with chance {:.2}", LAW[0].1, LAW[1].1);
    println!("E[X], weighted sum             {:.2}", e_x);
    println!("E[X], count over 100 draws     {:.2}", e_count);
    println!("E[X - 2], net per ticket       {:.2} (count: {:.2})", expect(|x| x - PRICE), e_net);
    println!("organiser: takes {:.0}, pays {:.0}, keeps {:.0}", SOLD as f64 * PRICE, PRIZE, SOLD as f64 * PRICE - PRIZE);
    let exact_one = LAW.iter().filter(|&&(x, _)| x == e_x).fold(0.0, |acc, &(_, p)| acc + p);
    println!("most likely payout {:.0} (chance 0.99); chance a ticket pays exactly 1: {:.2}", mode, exact_one);
    let tail: f64 = (0..PRIZE as usize)                // levels t = 0..99
        .map(|t| LAW.iter().filter(|&&(x, _)| x > t as f64).map(|&(_, p)| p).sum::<f64>()).sum();
    println!("E[X], tail sum of P(X > t)     {:.2}", tail);

    // road three: one ticket in each of N separate raffles, seed 2026
    let mut rng = SplitMix64 { s: 2026 };
    let (mut total, mut total_sq, mut n) = (0.0f64, 0.0f64, 0usize);
    let marks = [1000, 2000, 5000, 10000, 20000, 50000, 100000, 200000];
    let mut running = Vec::new();
    for &m in &marks {
        while n < m {
            let x = if rng.uniform() < 0.01 { PRIZE } else { 0.0 };
            total += x; total_sq += x * x; n += 1;
        }
        running.push(total / n as f64);
    }
    let mean_sim = total / n as f64;
    let se = sqrt((total_sq / n as f64 - mean_sim.powi(2)) / n as f64);
    println!("running average after N tickets:");
    for (m, r) in marks.iter().zip(&running) { println!("  N = {:>6}   {:.2}", m, r) }
    println!("simulated E[X] = {:.4}, standard error {:.4}", mean_sim, se);

    // linearity: five tickets, bought two ways
    let five_same = (0..SOLD).filter(|&w| w < 5).map(|_| PRIZE).sum::<f64>() / SOLD as f64;
    let p_zero_same = (0..SOLD).filter(|&w| w >= 5).count() as f64 / SOLD as f64;
    let mut dist_indep = [0.0f64; 6];                 // all 32 win/lose patterns
    for mask in 0u32..32 {
        let wins = mask.count_ones() as usize;
        dist_indep[wins] += 0.01f64.powi(wins as i32) * 0.99f64.powi(5 - wins as i32);
    }
    let five_indep: f64 = (0..6).map(|k| PRIZE * k as f64 * dist_indep[k]).sum();
    println!("5 tickets, one draw:   E[T] = {:.2}, P(T = 0) = {:.2}, at most one wins", five_same, p_zero_same);
    println!("5 tickets, five draws, 32 patterns: E[T] = {:.2}, P(T = 0) = {:.4}, P(T = 100) = {:.4}, P(T = 200) = {:.5}",
             five_indep, dist_indep[0], dist_indep[1], dist_indep[2]);
    println!("5 x E[X]              = {:.2}", 5.0 * e_x);
    let (mut rng5, mut hits) = (SplitMix64 { s: 7 }, 0u32);
    for _ in 0..100000 { if ((rng5.uniform() * SOLD as f64) as usize) < 5 { hits += 1 } }
    let q = hits as f64 / 100000.0;
    let se5 = PRIZE * sqrt(q * (1.0 - q) / 100000.0);
    println!("5 tickets, one draw, simulated 100000 draws: E[T] = {:.3}, standard error {:.3}", PRIZE * q, se5);

    // what breaks
    let both_same_draw = (0..SOLD).map(|w| (if w == 0 { PRIZE } else { 0.0 }) * (if w == 1 { PRIZE } else { 0.0 }))
        .sum::<f64>() / SOLD as f64;
    let both_indep: f64 = LAW.iter().flat_map(|&(a, pa)| LAW.iter().map(move |&(b, pb)| a * b * pa * pb)).sum();
    println!("two tickets, one draw: E[X1 X2] = {:.2}, E[X1] E[X2] = {:.2}", both_same_draw, e_x * e_x);
    println!("two tickets, two draws: E[X1 X2] = {:.2}", both_indep);
    let e_sq = payouts.iter().map(|x| x * x).sum::<f64>() / SOLD as f64;   // E[X^2] by counting draws
    println!("E[X^2] = {:.2}, E[X]^2 = {:.2}", expect(|x| x * x), e_x.powi(2));
    println!("E[sqrt X] = {:.2}, sqrt E[X] = {:.2}", expect(sqrt), sqrt(e_x));
    let mut trunc = Vec::new();
    for k in [10, 20, 40] {                           // St Petersburg: pays 2^j with chance 2^-j
        let t: f64 = (1..=k).map(|j| 2f64.powi(j) * 0.5f64.powi(j)).sum();
        println!("St Petersburg, levels 1..{}: truncated mean {:.2}", k, t);
        trunc.push((k, t));
    }
    let (mut rng_sp, mut sp_total, mut sp_n) = (SplitMix64 { s: 99 }, 0.0f64, 0usize);
    for m in [1000usize, 10000, 100000, 1000000] {
        while sp_n < m {
            let z = rng_sp.next();
            sp_total += 2f64.powi(z.trailing_zeros() as i32 + 1);
            sp_n += 1;
        }
        println!("  St Petersburg running average, N = {:>7}: {:.2}", m, sp_total / sp_n as f64);
    }
    println!("figure, x = 30 + 3v; bar at 0: x 30, height {:.1}; bar at 100: x 330, height {:.1}; balance point x {:.0}",
             150.0 * 0.99, 150.0 * 0.01, 30.0 + 3.0 * e_x);
    assert!((e_x - e_count).abs() < 1e-12);                        // weighted sum = count
    assert!((mean_sim - e_x).abs() < 4.0 * se);                     // simulation within 4 SE
    assert!((five_same - 5.0 * e_x).abs() < 1e-9);                  // linearity, dependent tickets
    assert!((five_indep - 5.0 * e_x).abs() < 1e-9);                 // linearity, independent tickets
    assert!(both_same_draw < both_indep);                           // products need independence
    assert!((tail - e_x).abs() < 1e-12);                            // tail sum = weighted sum
    assert!(mode != e_x && exact_one == 0.0);                       // the mean is never paid
    assert!((PRIZE * q - five_same).abs() < 4.0 * se5);             // simulated five tickets
    assert!((e_sq - expect(|x| x * x)).abs() < 1e-9 && e_sq > e_x.powi(2)); // E[X^2] vs E[X]^2
    assert!(trunc.iter().all(|&(k, t)| (t - k as f64).abs() < 1e-9)); // each level adds $1: no mean
    println!("ALL CHECKS PASS");
}
