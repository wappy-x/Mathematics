// Reflection principle for the fair walk -- the same check as reflection_principle_for_walks_check.py.
// Standard library only, no crates.  A gambler holds 10 chips and bets 1 chip a round at fair odds.
// Road 1: the reflection formula.  Road 2: all 2^20 paths.  Road 3: a seeded SplitMix64 simulation.
// Road 4: a round-by-round recursion, which also prices the cases where the mirror does not apply.
use std::collections::HashMap;

const N: usize = 20;
const X0: i64 = 10;
const L: i64 = 15;
const A: i64 = L - X0;

fn comb(n: usize, k: usize) -> u128 {                // exact, as Python's comb; u128 holds C(100, 50)
    if k > n { return 0; }
    let mut c = 1u128;
    for i in 0..k { c = c * (n - i) as u128 / (i + 1) as u128; }
    c
}
fn tail(n: usize, x: i64, p: f64) -> f64 {           // P(X_n >= x), counting wins h
    (0..=n).filter(|&h| X0 + 2 * h as i64 - n as i64 >= x)
        .map(|h| comb(n, h) as f64 * p.powi(h as i32) * (1.0 - p).powi((n - h) as i32)).fold(0.0, |s, v| s + v)
}
fn p_end(n: usize, x: i64) -> f64 {                  // P(X_n = x), fair walk
    let h2 = x - X0 + n as i64;
    if h2 % 2 == 0 && h2 >= 0 && h2 <= 2 * n as i64 { comb(n, (h2 / 2) as usize) as f64 / 2f64.powi(n as i32) } else { 0.0 }
}
fn reach(n: usize, level: i64, p: f64) -> f64 { tail(n, level, p) + tail(n, level + 1, p) }
fn recursion(n: usize, level: i64, p: f64, floor: Option<i64>) -> f64 {
    let lo = floor.unwrap_or(X0 - n as i64 - 1);
    let mut w = vec![0.0f64; (level - lo + 1) as usize];
    w[(X0 - lo) as usize] = 1.0;
    let mut hit = 0.0;
    for _ in 0..n {
        let mut new = vec![0.0f64; w.len()];
        for i in 1..w.len() - 1 { new[i + 1] += p * w[i]; new[i - 1] += (1.0 - p) * w[i]; }
        let last = new.len() - 1;
        hit += new[last]; new[last] = 0.0; new[0] = 0.0;
        w = new;
    }
    hit
}
fn join<T, F: Fn(T) -> String>(it: impl Iterator<Item = T>, f: F) -> String { it.map(f).collect::<Vec<_>>().join(" ") }

fn main() {
    let total = 1u64 << N;
    let tot = total as f64;
    // ---- road 2: every path.  Bit i of w set = the gambler wins round i+1 ----
    let mut first = vec![0u64; N + 1];
    let (mut touched_end, mut end_count, mut max_count) = (HashMap::new(), HashMap::new(), HashMap::new());
    for w in 0..total {
        let (mut x, mut top, mut t) = (X0, X0, 0usize);
        for i in 0..N {
            x += if w >> i & 1 == 1 { 1 } else { -1 };
            if x > top { top = x; }
            if x == L && t == 0 { t = i + 1; }
        }
        *end_count.entry(x).or_insert(0u64) += 1;
        *max_count.entry(top).or_insert(0u64) += 1;
        if t > 0 { first[t] += 1; *touched_end.entry(x).or_insert(0u64) += 1; }
    }
    let get = |m: &HashMap<i64, u64>, k: i64| *m.get(&k).unwrap_or(&0);
    let reach_count: u64 = first.iter().sum();
    let mirror_levels = (0..L).filter(|&b| get(&touched_end, b) == get(&end_count, 2 * L - b)).count();

    // ---- road 3: simulation.  One 64-bit draw per game; its top 20 bits are the 20 rounds ----
    let (mut state, games, mut hits) = (20260929u64, 200000u64, 0u64);
    for _ in 0..games {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        let mut x = X0;
        for i in 0..N {
            x += if z >> (63 - i) & 1 == 1 { 1 } else { -1 };
            if x == L { hits += 1; break; }
        }
    }
    let p_sim = hits as f64 / games as f64;
    let se = (p_sim * (1.0 - p_sim) / games as f64).sqrt();

    let p_form = reach(N, L, 0.5);
    let never = (X0 - A..L).map(|x| p_end(N, x)).fold(0.0, |s, v| s + v);
    let mirror_count = 2 * (13..=N).map(|h| comb(N, h)).sum::<u128>() as u64;
    for (name, v) in [("paths in 20 rounds", total), ("paths ending at 15 or more", mirror_count / 2),
                      ("paths touching 15, counted", reach_count), ("paths touching 15, 2 x C(20,13..20)", mirror_count)] {
        println!("{:<40} {:>12}", name, v);
    }
    let r = 18.0 / 38.0;
    let rows: Vec<(&str, f64)> = vec![
        ("1 reflection formula", p_form), ("2 all paths", reach_count as f64 / tot),
        ("3 simulation, 200000 games", p_sim), ("  standard error", se),
        ("4 recursion, broke at 0 ends play", recursion(N, L, 0.5, Some(0))),
        ("P(5 <= X_20 <= 14), by counting ends", never),
        ("wrong: count only ends >= 15", tail(N, L, 0.5)),
        ("wrong: gap 4, 2 x P(X_20 >= 14)", 2.0 * tail(N, 14, 0.5)), ("  right, gap 4", reach(N, 14, 0.5)),
        ("wrong: mirror at p = 18/38", reach(N, L, r)), ("  right, recursion at p = 18/38", recursion(N, L, r, None)),
        ("wrong: mirror, 100 rounds, no floor", reach(100, L, 0.5)), ("  right, 100 rounds, broke at 0", recursion(100, L, 0.5, Some(0))),
        ("try: target 11", reach(N, 11, 0.5)), ("try: target 20", reach(N, 20, 0.5)), ("try: 24 rounds", reach(24, L, 0.5)),
    ];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    println!("mirror check: touch 15 and end at b, versus end at 30 - b: equal at {} of 15 ends b = 0..14", mirror_levels);
    println!("end b = 12: {} paths touch 15 and end at 12; {} paths end at 18", get(&touched_end, 12), get(&end_count, 18));
    println!("first passage  round   all paths   (5/n) P(X_n = 15)");
    for n in (A as usize..N).step_by(2) {
        println!("{:<15}{:>5}   {:.6}    {:.6}", "", n, first[n] as f64 / tot, A as f64 / n as f64 * p_end(n, L));
    }
    println!("ballot, 19 rounds: {} paths end at 15, {} first reach it at round 19", comb(19, 12), first[19] / 2);
    println!("chart, best pile m      {}", join(X0..X0 + 15, |m| format!("{:>6}", m)));
    println!("chart, P(M_20 = m) %    {}", join(X0..X0 + 15, |m| format!("{:6.2}", 100.0 * (p_end(N, m) + p_end(N, m + 1)))));
    println!("chart, counted %        {}", join(X0..X0 + 15, |m| format!("{:6.2}", 100.0 * get(&max_count, m) as f64 / tot)));
    println!("chart, rounds n         {}", join(0..=N, |n| format!("{:>6}", n)));
    println!("chart, P(M_n >= 15) %   {}", join(0..=N, |n| format!("{:6.2}", 100.0 * reach(n, L, 0.5))));
    println!("chart, counted %        {}", join(0..=N, |n| format!("{:6.2}", 100.0 * first[..=n].iter().sum::<u64>() as f64 / tot)));
    println!("chart, P(X_n >= 15) %   {}", join(0..=N, |n| format!("{:6.2}", 100.0 * tail(n, L, 0.5))));
    let mut path = vec![X0];                          // one fixed path: first reaches 15 at round 9, ends at 12
    for c in "WWLWWWLWWLLWLLWLWLLW".chars() { let last = *path.last().unwrap(); path.push(last + if c == 'W' { 1 } else { -1 }); }
    let t9 = path.iter().position(|&v| v == L).unwrap();
    println!("figure, path            {}", join(path.iter(), |v| format!("{:>3}", v)));
    println!("figure, mirrored        {}", join(path.iter().enumerate(), |(i, v)| format!("{:>3}", if i <= t9 { *v } else { 2 * L - v })));

    assert_eq!(reach_count, mirror_count, "every path, counted, vs the mirror count");
    assert_eq!(mirror_levels, L as usize, "touch-and-end-at-b must match end-at-30-b at every b");
    assert!((reach(N, 14, 0.5) - max_count.iter().filter(|(m, _)| **m >= 14).map(|(_, c)| *c).sum::<u64>() as f64 / tot).abs() < 1e-12, "formula, even gap");
    assert!((X0..=X0 + N as i64).all(|m| get(&max_count, m) as f64 == tot * (p_end(N, m) + p_end(N, m + 1))), "max law");
    assert!((1..=N).all(|n| (first[n] as f64 / tot - A as f64 / n as f64 * p_end(n, L)).abs() < 1e-15), "ballot form of first passage");
    assert!((never - (1.0 - p_form)).abs() < 1e-12, "never reaching 15 = ending 5..14");
    assert!((recursion(N, L, 0.5, Some(0)) - p_form).abs() < 1e-12, "recursion, with ruin at 0, vs the formula");
    assert!((p_sim - p_form).abs() < 4.0 * se, "simulation within four standard errors");
    println!("ALL CHECKS PASS");
}
