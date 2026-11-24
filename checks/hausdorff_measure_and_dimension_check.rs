// Hausdorff measure and dimension -- the check behind the card.  std only.  The
// Cantor set C on the road [0, 1] km.  Stage k keeps 2^k pieces of length 3^-k;
// their ends are whole numbers over D = 3^10, so they are exact.
use std::collections::HashSet;

const K: u32 = 10;
const D: i64 = 59049; // 3^10

fn stage(k: u32) -> Vec<(i64, i64)> { // road one: cut the middle third of every piece, k times
    let mut pieces = vec![(0i64, D)];
    for _ in 0..k {
        let mut next = Vec::new();
        for &(lo, hi) in &pieces {
            let w = (hi - lo) / 3;
            next.push((lo, lo + w));
            next.push((hi - w, hi));
        }
        pieces = next;
    }
    pieces
}

fn solve_dim(copies: f64, ratio: f64) -> f64 { // road two: bisection for copies * ratio^s = 1
    let (mut lo, mut hi) = (0.0f64, 10.0f64);
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if copies * ratio.powf(mid) > 1.0 { lo = mid } else { hi = mid }
    }
    lo
}

// cheapest cover: each set spans a run of whole pieces, no wider than cap (in units of 1/D)
fn cheapest(pieces: &[(i64, i64)], s: f64, cap: i64, scale: f64) -> f64 {
    let mut best = vec![f64::INFINITY; pieces.len() + 1];
    best[0] = 0.0;
    for j in 1..=pieces.len() {
        for i in (1..=j).rev() {
            let span = pieces[j - 1].1 - pieces[i - 1].0;
            if span > cap { break; }
            let c = best[i - 1] + (span as f64 / D as f64 * scale).powf(s);
            if c < best[j] { best[j] = c; }
        }
    }
    best[pieces.len()]
}

fn cantor_f(mut p: i64, q: i64) -> f64 { // Cantor function at p/q: base-3 digits read in base 2
    if p >= q { return 1.0; }
    let (mut total, mut half) = (0.0f64, 0.5f64);
    for _ in 0..50 {
        let d = 3 * p / q;
        p = 3 * p - d * q;
        if d == 1 { return total + half; } // inside a removed gap: flat from here
        total += half * (d / 2) as f64;
        half /= 2.0;
    }
    total
}

fn main() {
    let s0 = 2f64.ln() / 3f64.ln();
    let kd = 4f64.ln() / 3f64.ln();
    println!("Cantor: log 2 / log 3 = {:.6}; bisection of 2 x (1/3)^s = 1 gives {:.6}; 3^s = {:.6}",
             s0, solve_dim(2.0, 1.0 / 3.0), 3f64.powf(s0));
    println!("Koch: log 4 / log 3 = {:.6}; bisection of 4 x (1/3)^s = 1 gives {:.6}", kd, solve_dim(4.0, 1.0 / 3.0));
    let sum = |k: i32, s: f64| 2f64.powi(k) * 3f64.powf(-(k as f64) * s);
    println!("stage k         pieces  sum s=0.5  sum s=0.6309  sum s=0.75");
    for k in [0, 1, 2, 5, 10, 20, 40] {
        println!("{:>7}  {:>13}  {:>9.4}  {:>12.4}  {:>10.4}", k, 1u64 << k, sum(k, 0.5), sum(k, s0), sum(k, 0.75));
    }
    let p10 = stage(K);
    let built: f64 = p10.iter().map(|&(lo, hi)| ((hi - lo) as f64 / D as f64).powf(s0)).sum();
    println!("stage 10 built by cutting: {} pieces; sum of (length)^0.6309 over the list = {:.6}", p10.len(), built);
    for (s, name) in [(0.5, "0.5"), (s0, "0.6309"), (0.75, "0.75")] {
        let row: Vec<String> = (0..13).map(|k| format!("{:.2}", sum(k, s))).collect();
        println!("chart s={}: {}", name, row.join(", "));
    }
    println!("cheapest cover of the stage-10 pieces, sets no wider than 3^-j km");
    println!("    j  width (m)  s=0.5   s=0.6309  s=0.75");
    let mut dp = Vec::new();
    for j in 0..9u32 {
        let cap = 3i64.pow(K - j);
        let row = [cheapest(&p10, 0.5, cap, 1.0), cheapest(&p10, s0, cap, 1.0), cheapest(&p10, 0.75, cap, 1.0)];
        println!("{:>5}  {:>9.2}  {:.4}  {:.4}    {:.4}", j, 1000.0 / 3f64.powi(j as i32), row[0], row[1], row[2]);
        dp.push(row);
    }
    let h1 = cheapest(&p10, 1.0, D, 1.0);
    println!("s=1, any width: cheapest cover {:.4}; length of stage 10 = (2/3)^10 = {:.4}", h1, (2.0f64 / 3.0).powi(10));
    let lefts: Vec<(i64, i64)> = p10.iter().cloned().filter(|p| p.1 <= D / 3).collect();
    let rights: Vec<(i64, i64)> = p10.iter().cloned().filter(|p| p.0 >= 2 * D / 3).collect();
    let (left, hl, hr) = (cheapest(&lefts, s0, D, 1.0), cheapest(&lefts, 0.5, D, 1.0), cheapest(&rights, 0.5, D, 1.0));
    println!("left third of C (scale r = 1/3): cheapest {:.4}; r^s = {:.4}; r alone would say {:.4}",
             left, 3f64.powf(-s0), 1.0 / 3.0);
    println!("s=0.5, no cap: whole {:.4}; halves {:.4} + {:.4} = {:.4}, more than the whole", dp[0][0], hl, hr, hl + hr);
    let metres = cheapest(&p10, s0, D, 1000.0);
    println!("same set measured in metres: cheapest {:.2}; 1000^0.6309 = {:.2}", metres, 1000f64.powf(s0));
    let q: i64 = 729;
    let vals: Vec<f64> = (0..=q).map(|i| cantor_f(i, q)).collect();
    let (mut top, mut beat, mut count) = (0.0f64, 0, 0);
    for a in 0..q {
        for b in a + 1..=q {
            let r = (vals[b as usize] - vals[a as usize]) / ((b - a) as f64 / q as f64).powf(s0);
            if r > top { top = r; }
            if r > 1.0 + 1e-9 { beat += 1; }
            count += 1;
        }
    }
    println!("mass test: {} intervals with ends on multiples of 1/729; largest mu(U)/|U|^0.6309 = {:.4}; above 1: {}",
             count, top, beat);
    println!("proved bound mu(U) <= 2 |U|^0.6309 gives H^0.6309(C) >= 1/2 = {:.4}; stage covers give <= {:.4}", 0.5, built);
    let (fa, fb) = (cantor_f(1, 5), cantor_f(3, 10));
    let w = 0.1f64.powf(s0);
    println!("U = [200 m, 300 m]: F = {:.4} and {:.4}, mu(U) = {:.4}; |U|^0.6309 = {:.4}; 2|U|^0.6309 = {:.4}",
             fa, fb, fb - fa, w, 2.0 * w);
    let hit: Vec<(i64, i64)> = stage(2).into_iter().filter(|&(lo, hi)| (lo as f64) < 0.3 * D as f64 && hi as f64 > 0.2 * D as f64).collect();
    println!("U meets {} stage-2 piece: {:.2} to {:.2} m", hit.len(), 1000.0 * hit[0].0 as f64 / D as f64, 1000.0 * hit[0].1 as f64 / D as f64);
    println!("stage-5 piece: length {:.2} m, weight (length in km)^0.6309 = {:.5}", 1000.0 / 243.0, (1.0f64 / 243.0).powf(s0));
    println!("mistake, weigh by length (s=1): stage 10 sum {:.4}, stage 20 sum {:.6}",
             (2.0f64 / 3.0).powi(10), (2.0f64 / 3.0).powi(20));
    println!("mistake, weigh by count (s=0): stage 10 sum {}, stage 20 sum {}", 1 << 10, 1 << 20);
    let mut boxes = Vec::new();
    for n in [3i64, 9, 27, 81] {
        let mut hit = HashSet::new();
        for b in 1..=n { for a in 0..b { hit.insert(n * a / b); } }
        boxes.push(hit.len());
    }
    let bs: Vec<String> = boxes.iter().map(|b| b.to_string()).collect();
    println!("mistake, box counting on the fractions in [0, 1): boxes touched at widths 1/3, 1/9, 1/27, 1/81: {}; slope {:.4}",
             bs.join(", "), (boxes[3] as f64 / boxes[0] as f64).ln() / 27f64.ln());
    let weight: f64 = (1..61).map(|n| 0.01 / 2f64.powi(n)).sum();
    println!("fractions listed, n-th given width (0.01/2^n)^(1/s): total weight at any s > 0 is {:.4}", weight);
    println!("constant in H^2 = c x area on the plane (cited): 4/pi = {:.4}", 4.0 / std::f64::consts::PI);
    println!("figure, x = 18 + 324 t for t in km; stage k drawn at y = 22 + 42 k, bars 12 high");
    for k in 0..4u32 {
        let xs: Vec<String> = stage(k).iter().map(|&(lo, _)| format!("{:.2}", 18.0 + 324.0 * lo as f64 / D as f64)).collect();
        println!("figure, stage {}: width {:.2} at x {}", k, 324.0 / 3f64.powi(k as i32), xs.join(", "));
    }
    println!("figure, U from x = {:.2} to {:.2}", 18.0 + 324.0 * 0.2, 18.0 + 324.0 * 0.3);
    assert!((solve_dim(2.0, 1.0 / 3.0) - s0).abs() < 1e-9 && (solve_dim(4.0, 1.0 / 3.0) - kd).abs() < 1e-9);
    assert!((built - 1.0).abs() < 1e-9 && p10.len() == 1 << K); // built list vs 2^k 3^-ks
    for j in 0..9usize { // search vs stage-j covers
        assert!((dp[j][1] - 1.0).abs() < 1e-9 && (dp[j][0] - (2.0 / 3f64.sqrt()).powi(j as i32)).abs() < 1e-9);
        assert!((dp[j][2] - (2.0 * 3f64.powf(-0.75)).powi(K as i32)).abs() < 1e-9);
    }
    assert!((h1 - (2.0f64 / 3.0).powi(10)).abs() < 1e-12 && (left - 0.5).abs() < 1e-9);
    assert!((metres - 1000f64.powf(s0)).abs() < 1e-6);
    assert!((hl - 3f64.powf(-0.5)).abs() < 1e-9 && (hr - hl).abs() < 1e-9 && hl + hr > dp[0][0] + 0.1); // halves need not add
    assert!(1.0 - 1e-12 < top && top <= 2.0 && beat == 0); // mass test
    assert!((fa - 0.25).abs() < 1e-12 && (fb - 0.4).abs() < 1e-12 && boxes == vec![3, 9, 27, 81] && hit.len() == 1);
    println!("ALL CHECKS PASS");
}
