// Martingales -- the same check as the Python, in Rust.  No crates.
// A gambler starts with $10 and bets $1 a round on a fair coin.  The fortune
// X_n and the process X_n^2 - n are checked to be martingales three ways: the
// one-step forecast by formula, every history of 10 rounds enumerated in exact
// integers, and 20000 simulated gamblers drawn from SplitMix64, seed 2026.
// Roulette odds (red wins 18 times in 37) give the supermartingale.
const X0: i64 = 10;
const N: usize = 10;
const G: usize = 20000;
const R: usize = 100;
const P_RED: f64 = 18.0 / 37.0;

struct SplitMix(u64);
impl SplitMix {
    fn draw(&mut self) -> u64 {                          // SplitMix64, written out
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { (self.draw() >> 11) as f64 / 9007199254740992.0 }
}

// ---- road 1: the one-step forecast, by formula, from a fortune of x ----
fn fair_next(x: f64) -> f64 { 0.5 * (x + 1.0) + 0.5 * (x - 1.0) }
fn fair_next_sq(x: f64) -> f64 { 0.5 * (x + 1.0).powi(2) + 0.5 * (x - 1.0).powi(2) }
fn red_next(x: f64) -> f64 { P_RED * (x + 1.0) + (1.0 - P_RED) * (x - 1.0) }

fn mean_se(s: f64, ss: f64, k: usize) -> (f64, f64) {
    let kf = k as f64;
    let m = s / kf;
    (m, ((ss - kf * m * m) / (kf - 1.0) / kf).sqrt())
}

fn join<T: std::fmt::Display>(v: &[T]) -> String {
    v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")
}

fn main() {
    // ---- road 2: every history of N rounds, exact integer sums ----
    // path p: bit k (first round = highest bit) is 1 for a win.  x[p][m] = fortune after m rounds.
    let np = 1usize << N;
    let mut x: Vec<Vec<i64>> = Vec::new();
    let mut w_red: Vec<i128> = Vec::new();            // roulette weights, total 37^N
    for p in 0..np {
        let mut row = vec![X0];
        for k in 0..N {
            let step = if (p >> (N - 1 - k)) & 1 == 1 { 1 } else { -1 };
            row.push(row[k] + step);
        }
        x.push(row);
        let wins = p.count_ones();
        w_red.push(18i128.pow(wins) * 19i128.pow(N as u32 - wins));
    }
    let (mut checks, mut fair_ok, mut sq_ok, mut sub_ok, mut red_ok, mut steps, mut agree) = (0, 0, 0, 0, 0, 0, 0);
    for n in 0..=N {
        let size = 1usize << (N - n);                 // paths sharing one history of n rounds
        for cell in 0..(1usize << n) {
            let paths = cell * size..(cell + 1) * size;
            let xn = x[cell * size][n];
            let (s, xi) = (size as i64, xn as i128);
            let wsum: i128 = paths.clone().map(|p| w_red[p]).sum();
            for m in n..=N {
                checks += 1;
                let sx: i64 = paths.clone().map(|p| x[p][m]).sum();
                let sq: i64 = paths.clone().map(|p| x[p][m] * x[p][m]).sum();
                if sx == s * xn { fair_ok += 1 }                                   // E[X_m | F_n] = X_n
                if sq - s * m as i64 == s * (xn * xn - n as i64) { sq_ok += 1 }    // X^2 - n keeps its forecast
                if sq - s * xn * xn == s * (m - n) as i64 { sub_ok += 1 }          // X^2 alone rises by m - n
                let swx: i128 = paths.clone().map(|p| w_red[p] * x[p][m] as i128).sum();
                if 37 * swx == 37 * wsum * xi - (m - n) as i128 * wsum { red_ok += 1 }
                if m == n + 1 {                                                    // road 1 against road 2
                    steps += 1;
                    let a = (sx as f64 / s as f64 - fair_next(xn as f64)).abs() < 1e-12;
                    let b = (swx as f64 / wsum as f64 - red_next(xn as f64)).abs() < 1e-12;
                    if a && b { agree += 1 }
                }
            }
        }
    }
    let mean_sq_10 = (0..np).map(|p| x[p][N] * x[p][N]).sum::<i64>() as f64 / np as f64;
    let half = 1usize << (N - 1);              // the insider knows toss 1 at round 0: two cells of 512 paths
    let ins_sum: Vec<i64> = (0..2).map(|c| (c * half..(c + 1) * half).map(|q| x[q][1]).sum()).collect();   // 512 E[X_1 | toss 1]
    let insider_off = (0..np).filter(|&p| ins_sum[p >> (N - 1)] != half as i64 * x[p][0]).count();   // forecast vs X_0

    // ---- road 3: simulated gamblers ----
    let mut rng = SplitMix(2026);
    let mut path0: Vec<i64> = vec![X0];
    let (mut s1, mut s2, mut s3, mut s4) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
    let (mut c14, mut c14n, mut c14nsq) = (0usize, 0.0f64, 0.0f64);
    for g in 0..G {
        let (mut xv, mut x50) = (X0, 0);
        for r in 1..=R {
            xv += if rng.draw() >> 63 == 1 { 1 } else { -1 };
            if g == 0 && r <= 40 { path0.push(xv) }
            if r == 50 { x50 = xv }
            if r == 51 && x50 == 14 { c14 += 1; c14n += xv as f64; c14nsq += (xv * xv) as f64 }
        }
        let y = xv * xv - R as i64;
        s1 += xv as f64; s2 += (xv * xv) as f64; s3 += y as f64; s4 += (y * y) as f64;
    }
    let (mut red_s1, mut red_s2) = (0.0f64, 0.0f64);
    for _ in 0..G {
        let mut xv = X0;
        for _ in 0..R { xv += if rng.uniform() < P_RED { 1 } else { -1 } }
        red_s1 += xv as f64; red_s2 += (xv * xv) as f64;
    }
    let (mx, sex) = mean_se(s1, s2, G);
    let (my, sey) = mean_se(s3, s4, G);
    let (m51, se51) = mean_se(c14n, c14nsq, c14);
    let (mred, sered) = mean_se(red_s1, red_s2, G);
    let exact_red = X0 as f64 - R as f64 / 37.0;

    println!("road 1, from $12 the next fortune is 13 or 11, averaging {:.4}", fair_next(12.0));
    println!("road 1, its square is 169 or 121, averaging {:.4}  (= 144 + 1)", fair_next_sq(12.0));
    println!("road 1, forecast of the next fortune from $12, roulette:  {:.4}  (= 12 - 1/37)", red_next(12.0));
    println!("road 2, {} histories, {} (cell, later time) pairs checked", np, checks);
    println!("  E[X_m | F_n] = X_n held:            {} of {}", fair_ok, checks);
    println!("  E[X_m^2 - m | F_n] = X_n^2 - n held: {} of {}", sq_ok, checks);
    println!("  X^2 forecast rose by exactly m - n:  {} of {}", sub_ok, checks);
    println!("  roulette forecast fell by (m - n)/37: {} of {}", red_ok, checks);
    println!("  one-round cell averages equal road 1: {} of {}", agree, steps);
    println!("  E[X_10^2] = {:.4}, so Var(X_10) = {:.4}", mean_sq_10, mean_sq_10 - (X0 * X0) as f64);
    println!("road 3, {} gamblers, {} rounds each, seed 2026", G, R);
    println!("  mean X_100          {:.4}  se {:.4}  (exact 10)", mx, sex);
    println!("  mean X_100^2 - 100  {:.4}  se {:.4}  (exact 100)", my, sey);
    println!("  mean X_100^2        {:.4}  se {:.4}  (exact 200, so Var = 100, sd 10)", my + R as f64, sey);
    println!("  {} gamblers at $14 after round 50: mean X_51 {:.4}  se {:.4}", c14, m51, se51);
    println!("roulette, mean X_100  {:.4}  se {:.4}  (exact {:.4})", mred, sered, exact_red);
    println!("roulette, one-round forecast factor of (19/18)^X: {:.12}", P_RED * 19.0 / 18.0 + (1.0 - P_RED) * 18.0 / 19.0);
    println!("what breaks:");
    println!("  house edge, forecast after one round from $10: {:.4}; after 100 rounds {:.4}", red_next(10.0), exact_red);
    println!("  squared fortune without the -n: E[X_100^2] = {}, not {}", X0 * X0 + R as i64, X0 * X0);
    println!("  insider who sees the next toss: forecast differs from X_0 on {} of {} paths", insider_off, np);
    println!("figure, path of gambler 0, rounds 0 to 40: {}", join(&path0));
    let up: Vec<String> = (0..41).map(|n| format!("{:.2}", X0 as f64 + (n as f64).sqrt())).collect();
    let lo: Vec<String> = (0..41).map(|n| format!("{:.2}", X0 as f64 - (n as f64).sqrt())).collect();
    println!("figure, upper band 10 + sqrt(n): {}", join(&up));
    println!("figure, lower band 10 - sqrt(n): {}", join(&lo));
    println!("figure, parabola s^2 from s = -2 to 2: M 50 40 Q 150 360 250 40; s = -1, 0, 1 at (100,160) (150,200) (200,160); chord midpoint (150,160); gap 1 = 40 px");

    assert!(fair_ok == checks);                                        // the fortune: enumeration vs X_n
    assert!(sq_ok == checks);                                          // X^2 - n: enumeration vs X_n^2 - n
    assert!(sub_ok == checks);                                         // X^2 rises by exactly m - n
    assert!(red_ok == checks);                                         // roulette drops by exactly 1/37
    assert!(agree == steps);                                           // road 1 against road 2
    assert!(mean_sq_10 == (X0 * X0) as f64 + N as f64);                // E[X_10^2] against 100 + 10
    assert!((mx - X0 as f64).abs() < 4.0 * sex);                       // road 3 against exact values
    assert!((my - (X0 * X0) as f64).abs() < 4.0 * sey);
    assert!((m51 - 14.0).abs() < 4.0 * se51);
    assert!((mred - exact_red).abs() < 4.0 * sered);
    println!("ALL CHECKS PASS");
}
