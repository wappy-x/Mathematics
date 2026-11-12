// Nash equilibrium -- the same check as the Python, in Rust.  No crates.
// Game 1: a penalty kick.  Kicker and goalkeeper each pick Left or Right (both
// named from the kicker's side).  Entries are the kicker's chance of scoring, in
// percent: illustrative round numbers of the size measured in professional
// football.  The goalkeeper wants the opposite, so this is a zero-sum game.
// Game 2: two bakeries set a loaf price, High or Low; synthetic profits in pounds.
// Roads to the mixed equilibrium: (1) the indifference formula, (2) a brute-force
// grid over every mix in steps of 1/600, (3) fictitious play, 100,000 rounds.
const A: i64 = 58; // kick L, dive L
const B: i64 = 95; // kick L, dive R
const C: i64 = 93; // kick R, dive L
const D: i64 = 70; // kick R, dive R
const N: i64 = 600;

fn pen(k: usize, g: usize) -> i64 { [[A, B], [C, D]][k][g] }

/// Every cell where neither player gains by switching alone.
fn pure_equilibria(names: [&'static str; 2], row: &dyn Fn(usize, usize) -> i64,
                   col: &dyn Fn(usize, usize) -> i64) -> Vec<(&'static str, &'static str)> {
    let mut found = Vec::new();
    for r in 0..2 {
        for c in 0..2 {
            let row_ok = (0..2).all(|r2| row(r, c) >= row(r2, c));
            let col_ok = (0..2).all(|c2| col(r, c) >= col(r, c2));
            if row_ok && col_ok { found.push((names[r], names[c])) }
        }
    }
    found
}

fn kicker_floor(k: i64) -> i64 { (A * k + C * (N - k)).min(B * k + D * (N - k)) }
fn keeper_ceiling(j: i64) -> i64 { (A * j + B * (N - j)).max(C * j + D * (N - j)) }
fn keeper_reply_score(p: f64) -> f64 {
    (p * A as f64 + (1.0 - p) * C as f64).min(p * B as f64 + (1.0 - p) * D as f64)
}
fn kicker_reply_score(q: f64) -> f64 {
    (q * A as f64 + (1.0 - q) * B as f64).max(q * C as f64 + (1.0 - q) * D as f64)
}

fn main() {
    let s = ["L", "R"];
    // best responses in the penalty, cell by cell
    for g in 0..2 {
        let best = if pen(0, g) >= pen(1, g) { 0 } else { 1 };
        println!("goalkeeper dives {}: kicker's best reply is {} ({}% against {}%)", s[g], s[best], pen(best, g), pen(1 - best, g));
    }
    for k in 0..2 {
        let best = if pen(k, 0) <= pen(k, 1) { 0 } else { 1 };
        println!("kicker shoots {}: goalkeeper's best reply is {} (lets in {}%)", s[k], s[best], pen(k, best));
    }
    let pen_pure = pure_equilibria(s, &|r, c| pen(r, c), &|r, c| -pen(r, c));
    println!("penalty, pure equilibria: {}", if pen_pure.is_empty() { "none".to_string() } else { format!("{:?}", pen_pure) });

    // road 1: the indifference formula
    let den = B + C - A - D;
    let p_star = (C - D) as f64 / den as f64;
    let q_star = (B - D) as f64 / den as f64;
    let value = (B * C - A * D) as f64 / den as f64;
    println!("denominator b + c - a - d = {}; bc - ad = {} - {} = {}", den, B * C, A * D, B * C - A * D);
    println!("road 1, formula: kicker Left p* = {}/{} = {:.4}; keeper Left q* = {}/{} = {:.4}; scoring {:.4}%", C - D, den, p_star, B - D, den, q_star, value);
    let (af, bf, cf, df) = (A as f64, B as f64, C as f64, D as f64);
    let kick_l = q_star * af + (1.0 - q_star) * bf;
    let kick_r = q_star * cf + (1.0 - q_star) * df;
    let dive_l = p_star * af + (1.0 - p_star) * cf;
    let dive_r = p_star * bf + (1.0 - p_star) * df;
    println!("1 - q* = {:.4}; 1 - p* = {:.4}", 1.0 - q_star, 1.0 - p_star);
    println!("against q*, kicker scores {:.4}% going L and {:.4}% going R", kick_l, kick_r);
    println!("against p*, keeper lets in {:.4}% diving L and {:.4}% diving R", dive_l, dive_r);

    // road 2: brute force over every mix k/600 (integers, so no rounding)
    let (mut k_best, mut j_best) = (0, 0);
    for i in 0..=N {
        if kicker_floor(i) > kicker_floor(k_best) { k_best = i }
        if keeper_ceiling(i) < keeper_ceiling(j_best) { j_best = i }
    }
    println!("road 2, grid: kicker's best guaranteed mix {}/600 = {:.4}, scoring at least {:.4}%", k_best, k_best as f64 / N as f64, kicker_floor(k_best) as f64 / N as f64);
    println!("road 2, grid: keeper's best mix {}/600 = {:.4}, conceding at most {:.4}%", j_best, j_best as f64 / N as f64, keeper_ceiling(j_best) as f64 / N as f64);

    // road 3: fictitious play -- each round, each side best-replies to the other's past frequencies
    let (mut kl, mut kr, mut gl, mut gr) = (0i64, 0i64, 0i64, 0i64);
    let rounds = 100000i64;
    for _ in 0..rounds {
        let k_left = A * gl + B * gr >= C * gl + D * gr;
        let g_left = A * kl + C * kr <= B * kl + D * kr;
        if k_left { kl += 1 } else { kr += 1 }
        if g_left { gl += 1 } else { gr += 1 }
    }
    let (fk, fg) = (kl as f64 / rounds as f64, gl as f64 / rounds as f64);
    println!("road 3, fictitious play over {} rounds: kicker Left {:.4}, keeper Left {:.4}", rounds, fk, fg);
    println!("road 3 misses the formula by {:.4} and {:.4}", (fk - p_star).abs(), (fg - q_star).abs());

    // what breaks
    let half = keeper_reply_score(0.5);
    let swapped = keeper_reply_score(q_star);
    let pure_best = A.min(B).max(C.min(D));
    let keeper_half = kicker_reply_score(0.5);
    println!("mistake, kicker goes 50-50: keeper lets in {:.4}% diving L, {:.4}% diving R; scoring {:.4}%", 0.5 * af + 0.5 * cf, 0.5 * bf + 0.5 * df, half);
    println!("mistake, kicker uses the keeper's number {:.4}: scoring {:.4}%", q_star, swapped);
    println!("mistake, kicker always picks one side: best is always R, scoring {}%", pure_best);
    println!("mistake, keeper goes 50-50: kicker always shoots R, scoring {:.4}%", keeper_half);
    println!("mixing beats one side by {:.4} points; the 50-50 keeper gives away {:.4}", value - pure_best as f64, keeper_half - value);

    // game 2: the bakery price war (row = our bakery, column = the rival), profits in pounds a day
    let ours = [[1200, 700], [1500, 900]]; // [our price][their price], High = 0, Low = 1
    let bake_pure = pure_equilibria(["High", "Low"], &|r, c| ours[r][c], &|r, c| ours[c][r]);
    let p = ["High", "Low"];
    for c in 0..2 {
        let best = if ours[0][c] >= ours[1][c] { 0 } else { 1 };
        println!("rival prices {}: our best reply is {} ({} against {})", p[c], p[best], ours[best][c], ours[1 - best][c]);
    }
    let shown: Vec<String> = bake_pure.iter().map(|(r, c)| format!("({}, {})", r, c)).collect();
    println!("bakeries, pure equilibria: {}", shown.join(", "));
    println!("at (Low, Low) each makes {}; at (High, High) each would make {}", ours[1][1], ours[0][0]);
    println!("from (High, High), our bakery gains {} by cutting alone", ours[1][0] - ours[0][0]);

    // the figure: best-reply lines in a 200 by 200 square, origin at (60, 230)
    let (fx, fy) = (60.0 + 200.0 * p_star, 230.0 - 200.0 * q_star);
    println!("figure, crossing at ({:.1}, {:.1}); kicker's jump at y = {:.1}; keeper's jump at x = {:.1}", fx, fy, fy, fx);

    assert!(pen_pure.is_empty() && bake_pure == vec![("Low", "Low")]); // exhaustive cell search
    assert!(k_best * den == (C - D) * N && j_best * den == (B - D) * N); // grid meets formula
    assert!((kicker_floor(k_best) as f64 / N as f64 - value).abs() < 1e-9 && (keeper_ceiling(j_best) as f64 / N as f64 - value).abs() < 1e-9);
    assert!((kick_l - kick_r).abs() < 1e-9 && (dive_l - dive_r).abs() < 1e-9); // indifference holds
    assert!((kl as f64 / rounds as f64 - p_star).abs() < 0.01 && (gl as f64 / rounds as f64 - q_star).abs() < 0.01);
    assert!(half < value && swapped < value && (pure_best as f64) < value && keeper_half > value);
    println!("ALL CHECKS PASS");
}
