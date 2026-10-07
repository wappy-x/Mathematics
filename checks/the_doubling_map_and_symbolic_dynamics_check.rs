// The doubling map -- the same check as the Python, in Rust.  No crates.  A place
// on the 1 m strip is an exact fraction p/q, so "double, drop the whole metre" is
// p -> 2p mod q (road one); road two shifts the binary digits.  They must agree.
use std::collections::BTreeSet;

fn digits(mut p: u128, q: u128, k: usize) -> Vec<u128> {   // road two: first k binary digits of p/q
    let mut out = Vec::new();
    for _ in 0..k { out.push(2 * p / q); p = 2 * p % q }
    out
}
fn orbit(mut p: u128, q: u128, n: usize) -> u128 {          // road one: n exact steps of p -> 2p mod q
    for _ in 0..n { p = 2 * p % q }
    p
}
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }   // Euclid, written out
fn returners(n: usize) -> usize {                           // every fraction p/q, q <= 64, back after n steps
    let mut s = BTreeSet::new();
    for q in 1..65u128 { for p in 0..q { if orbit(p, q, n) == p { s.insert((p / gcd(p, q), q / gcd(p, q))); } } }
    s.len()
}
fn join(v: &[u128]) -> String { v.iter().map(|b| b.to_string()).collect::<String>() }

fn main() {
    let m: u128 = 1 << 30;
    let d = digits(7, 10, 70);
    let agree = (0..31).all(|n| digits(orbit(7, 10, n), 10, 40) == d[n..n + 40].to_vec());
    let (bp, bq) = (7 * (7 * m / 10) + 1, 7 * m);          // neighbour: 0.7's first 30 digits, then 1/7's
    let (g0n, g0d) = (49 * m - 10 * bp, 70 * m);            // gap at the start, exact: 0.7 - neighbour
    let (p30, b30) = (orbit(7, 10, 30), orbit(bp, bq, 30));
    let (g30n, g30d) = (p30 * bq - 10 * b30, 10 * bq);      // gap after 30 steps, exact
    let (g0, g30) = (g0n as f64 / g0d as f64, g30n as f64 / g30d as f64);
    let words: String = (1..5usize).flat_map(|l| (0..(1u32 << l)).map(move |w| format!("{:0width$b}", w, width = l))).collect();
    let len = words.len();
    let cells_digits: BTreeSet<u128> = (0..len - 3).map(|i| u128::from_str_radix(&words[i..i + 4], 2).unwrap()).collect();
    let (big_p, big_q) = (u128::from_str_radix(&words, 2).unwrap(), 1u128 << len);
    let cells_exact: BTreeSet<u128> = (0..len - 3).map(|i| orbit(big_p, big_q, i) / (big_q / 16)).collect();
    let (mut x, mut drop) = (0.7f64, 0);
    while x != 0.0 { x = (2.0 * x) % 1.0; drop += 1 }
    let (mut ra, mut rb) = (147 * m, 30 * bp);              // rotation by a third, over the denominator 210 m
    for _ in 0..30 { ra = (ra + 70 * m) % (210 * m); rb = (rb + 70 * m) % (210 * m) }
    println!("0.7 m in binary: 0.{}...", join(&d[..16]));
    let orb: Vec<String> = (0..9).map(|n| format!("{:.1}", orbit(7, 10, n) as f64 / 10.0)).collect();
    println!("orbit of 0.7 m, steps 0 to 8: {}", orb.join(" "));
    let dbl: Vec<String> = (0..5).map(|n| format!("{:.1}", 2.0 * orbit(7, 10, n) as f64 / 10.0)).collect();
    println!("doubled, before the cut, rounds 1 to 5: {}", dbl.join(" "));
    let halves: Vec<String> = d[..9].iter().map(|b| b.to_string()).collect();
    println!("half it lands in (1 = right), steps 0 to 8: {}", halves.join(" "));
    println!("exact fractions and shifted digits agree for 30 steps: {}", if agree { "yes" } else { "no" });
    println!("neighbour: 0.7's first 30 digits, then 1/7's; gap at the start {:.3} nm", g0 * 1e9);
    println!("digit 31: 0.7 has {}, the neighbour has {}", d[30], digits(bp, bq, 31)[30]);
    println!("after 30 steps: 0.7 -> {:.1}, neighbour -> {:.6} = 1/7; gap {:.3} m", p30 as f64 / 10.0, b30 as f64 / bq as f64, g30);
    let flip = orbit(7 * 2 * m - 10, 20 * m, 30) as f64 / (20 * m) as f64;   // 0.7 with digit 31 flipped from 1 to 0
    println!("flip digit 31 alone: after 30 steps 0.7 -> {:.1}, flipped -> {:.1}; gap {:.1} m", p30 as f64 / 10.0, flip, p30 as f64 / 10.0 - flip);
    println!("gap multiplied per step: {:.6}; Lyapunov exponent ln 2 = {:.6}", (g30 / g0).powf(1.0 / 30.0), (g30 / g0).ln() / 30.0);
    println!("period-3 orbit: 1/7 -> 2/7 -> 4/7 -> {}/7, binary 0.{}...; the other: 3/7 -> {}/7 -> {}/7 -> {}/7",
             orbit(4, 7, 1), join(&digits(1, 7, 9)), orbit(3, 7, 1), orbit(3, 7, 2), orbit(3, 7, 3));
    for n in [3usize, 4] {
        println!("points back after {} steps, brute force over q <= 64: {}; formula 2^{} - 1 = {}", n, returners(n), n, (1 << n) - 1);
    }
    println!("all words of length 1 to 4 in a row: {} digits; 1/16 m cells visited: {} by digits, {} by fractions",
             len, cells_digits.len(), cells_exact.len());
    let mut tent: Vec<u128> = vec![2];                      // tent map on sevenths: 2x left of 1/2, 2 - 2x right
    while tent.len() < 4 { let t = tent[tent.len() - 1]; tent.push(if 2 * t <= 7 { 2 * t } else { 14 - 2 * t }) }
    let tv: Vec<String> = tent.iter().map(|t| format!("{}/7", t)).collect();
    println!("tent map period 3: {}", tv.join(" -> "));
    println!("mistake 1, floating point: 0.7 as a double reaches exactly 0 after {} steps", drop);
    println!("mistake 2, no mod 1: 0.7 m doubled 30 times = {:.1} m", 7.0 * m as f64 / 10.0);
    println!("mistake 3, rotation by a third: period 3 everywhere, gap after 30 steps {:.3} nm",
             ((ra + 210 * m - rb) % (210 * m)) as f64 / (210 * m) as f64 * 1e9);
    let fig: Vec<String> = [1.0, 2.0, 4.0].iter().map(|k: &f64| format!("({:.2}, {:.2})", 60.0 + 180.0 * k / 7.0, 210.0 - 180.0 * k / 7.0)).collect();
    println!("figure, 1 m = 180 units, (x, y) of 1/7 2/7 4/7: {}", fig.join(" "));
    assert!(agree && u128::from_str_radix(&join(&d[..40]), 2).unwrap() == 7 * (1u128 << 40) / 10);   // digits right, roads agree
    assert!(g30n * g0d == m * g0n * g30d && digits(bp, bq, 60)[30..].to_vec() == digits(1, 7, 30));
    assert!([returners(3), returners(4)] == [(1 << 3) - 1, (1 << 4) - 1]);
    assert!(cells_digits == cells_exact && cells_exact == (0..16u128).collect::<BTreeSet<u128>>());
    println!("ALL CHECKS PASS");
}
