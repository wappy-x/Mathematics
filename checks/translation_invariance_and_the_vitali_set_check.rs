// Translation invariance and the Vitali set: what a computer can check.
// Exact work in whole units: interval ends in twentieths, the grid in 400ths.
// Road 1 merges intervals; road 2 counts grid cells. Road 1 counts distinct
// reduced fractions; road 2 sums Euler's totient from a sieve.
use std::collections::HashSet;

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }

fn length_by_merging(pieces: &[(i64, i64)]) -> i64 { // ends in twentieths, [a, b)
    let mut p = pieces.to_vec();
    p.sort();
    let (mut total, mut reach) = (0, i64::MIN);
    for (a, b) in p {
        if a >= reach { total += b - a; reach = b; }
        else if b > reach { total += b - reach; reach = b; }
    }
    total
}

fn length_by_grid(pieces: &[(i64, i64)]) -> i64 { // cells of width 1/400 = 1/20 of a twentieth
    let lo = pieces.iter().map(|p| p.0.min(p.1)).min().unwrap() * 20;
    let hi = pieces.iter().map(|p| p.0.max(p.1)).max().unwrap() * 20;
    let mut hits = 0;
    for k in (lo - 1)..(hi + 1) {
        let mid = 2 * k + 1; // midpoint in 800ths; an end a/20 is 40a/800
        if pieces.iter().any(|&(a, b)| 40 * a.min(b) <= mid && mid < 40 * a.max(b)) { hits += 1; }
    }
    hits // in 400ths
}

fn rotate(pieces: &[(i64, i64)], q: i64) -> Vec<(i64, i64)> { // wheel of 20 twentieths
    let mut out = vec![];
    for &(a, b) in pieces {
        let (a2, b2) = (a + q, b + q);
        if b2 <= 20 { out.push((a2, b2)); }
        else if a2 >= 20 { out.push((a2 - 20, b2 - 20)); }
        else { out.push((a2, 20)); out.push((0, b2 - 20)); }
    }
    out
}

fn tw(x: i64) -> f64 { x as f64 / 20.0 }
fn show(p: &[(i64, i64)], l: &str, r: &str) -> String {
    p.iter().map(|&(a, b)| format!("{}{},{}{}", l, tw(a), tw(b), r)).collect::<Vec<_>>().join(" ")
}

fn by_fractions(n: i64) -> usize {
    let mut seen = HashSet::new();
    for d in 1..=n { for a in 0..d { let g = gcd(a, d); seen.insert((a / g, d / g)); } }
    seen.len()
}

fn by_totient(n: usize) -> usize {
    let mut phi: Vec<usize> = (0..=n).collect();
    for p in 2..=n {
        if phi[p] == p { let mut m = p; while m <= n { phi[m] -= phi[m] / p; m += p; } }
    }
    phi[1..].iter().sum()
}

fn pt(r: f64, x: f64) -> String {
    let t = 2.0 * std::f64::consts::PI * x;
    format!("({:.1},{:.1})", 180.0 + r * t.sin(), 120.0 - r * t.cos())
}

fn main() {
    let a = vec![(2, 6), (10, 18)];
    let len_a = length_by_merging(&a);
    println!("set A {}, length by merging {}, by grid {}", show(&a, "[", ")"), tw(len_a), length_by_grid(&a) as f64 / 400.0);
    let r = rotate(&a, 5);
    println!("A rotated by 0.25: {}, length by merging {}, by grid {}", show(&r, "[", ")"), tw(length_by_merging(&r)), length_by_grid(&r) as f64 / 400.0);
    assert!(length_by_grid(&a) == 20 * len_a && length_by_grid(&r) == 20 * len_a);
    let spread: HashSet<i64> = (0..20).map(|k| length_by_grid(&rotate(&a, k))).collect();
    let (mn, mx) = (*spread.iter().min().unwrap(), *spread.iter().max().unwrap());
    println!("A rotated by k/20, k = 0..19: {} distinct length(s), {} to {}", spread.len(), mn as f64 / 400.0, mx as f64 / 400.0);
    assert!(spread.len() == 1 && mn == 20 * len_a);
    let s3: Vec<(i64, i64)> = a.iter().map(|&(x, y)| (3 * x, 3 * y)).collect();
    println!("A stretched by 3: {}, length {} = 3 x {}", show(&s3, "[", ")"), tw(length_by_merging(&s3)), tw(len_a));
    assert!(length_by_grid(&s3) == 3 * length_by_grid(&a));
    let sm: Vec<(i64, i64)> = a.iter().map(|&(x, y)| (-2 * y, -2 * x)).collect();
    println!("A stretched by -2: {}, length {}; c times length gives {}", show(&sm, "(", "]"), tw(length_by_merging(&sm)), tw(-2 * len_a));
    assert!(length_by_merging(&sm) == 2 * len_a && length_by_grid(&sm) == 40 * len_a);

    // A finite wheel of 360 positions and 12 rotations (steps of 30): choice sets tile it.
    let (n, step) = (360usize, 30usize);
    let picks: [(&str, fn(usize) -> usize); 2] = [("smallest in each group", |r| r), ("scrambled choice", |r| r + 30 * ((7 * r) % 12))];
    for (name, pick) in picks.iter() {
        let v: Vec<usize> = (0..step).map(|r| pick(r)).collect();
        let mut cover = vec![0; n];
        for j in 0..n / step { for &x in &v { cover[(x + step * j) % n] += 1; } }
        assert!(cover.iter().all(|&c| c == 1));
        let g = gcd((12 * v.len()) as i64, n as i64);
        let (tn, td) = ((12 * v.len()) as i64 / g, n as i64 / g);
        let total = if td == 1 { format!("{}", tn) } else { format!("{}/{}", tn, td) };
        println!("finite wheel, {}: {} points, size {:.4}, 12 copies cover every position exactly {} time(s), total {}",
            name, v.len(), v.len() as f64 / n as f64, cover.iter().min().unwrap(), total);
    }
    let d0: Vec<u32> = (0..12).map(|j| if (0..step).any(|x| (x + step * j) % n == 0) { 1 } else { 0 }).collect();
    println!("point mass at 0: gives V {}, V rotated by 30 {}, sum over 12 copies {}", d0[0], d0[1], d0.iter().sum::<u32>());

    // The real wheel: rational rotations with denominator <= n that fit as disjoint copies.
    for m in (1..=10).chain(std::iter::once(100)) {
        let (k1, k2) = (by_fractions(m as i64), by_totient(m));
        assert_eq!(k1, k2);
        println!("denominators <= {}: {} disjoint copies of V fit, so a measurable V would have length <= 1/{} = {:.6}", m, k1, k1, 1.0 / k1 as f64);
    }

    // Any positive size c: total of the copies passes 1; size 0: total stays 0.
    for (num, den) in [(1i64, 10i64), (1, 100), (1, 1000)] {
        let (mut total, mut copies) = (0i64, 0i64); // total in units of 1/den
        while total <= den { total += num; copies += 1; }
        assert_eq!(copies, den / num + 1);
        println!("size {}: total passes 1 after {} copies, and grows without bound", num as f64 / den as f64, copies);
    }
    let zero: i64 = (0..1_000_000).map(|_| 0i64).sum();
    println!("size 0: total after 1000000 copies {}", zero);

    // figure: wheel of radius 75 at (180,120); A on radius 60, A rotated by 0.25 on radius 90.
    for (rad, arcs) in [(60.0, [(0.1, 0.3), (0.5, 0.9)]), (90.0, [(0.35, 0.55), (0.75, 1.15)])] {
        let parts: Vec<String> = arcs.iter().map(|&(x, y)| format!(" r={} arc {}-{} from {} to {}", rad, x, y, pt(rad, x), pt(rad, y))).collect();
        println!("figure,{}", parts.join(","));
    }
}
