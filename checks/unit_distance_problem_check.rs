// The unit-distance problem -- the same check as the Python, in Rust.  No
// crates.  Grid counts are made pair by pair and again by the two-squares formula;
// r2(m) is counted on the circle and again by divisors; a 4-D set shows what the
// plane forbids; a sieve follows the grid's extra exponent as n grows.
use std::collections::{BTreeMap, BTreeSet};

fn grid(k: i64) -> Vec<Vec<i64>> {
    let mut out = Vec::new();
    for x in 0..k { for y in 0..k { out.push(vec![x, y]) } }
    out
}

fn sq(p: &[i64], q: &[i64]) -> i64 { p.iter().zip(q).map(|(a, b)| (a - b) * (a - b)).sum() }

fn histogram(pts: &[Vec<i64>]) -> BTreeMap<i64, i64> {   // road one: every unordered pair
    let mut h = BTreeMap::new();
    for i in 0..pts.len() {
        for j in i + 1..pts.len() { *h.entry(sq(&pts[i], &pts[j])).or_insert(0) += 1 }
    }
    h
}

fn isqrt(m: i64) -> i64 {
    let mut s = (m as f64).sqrt() as i64;
    while s * s > m { s -= 1 }
    while (s + 1) * (s + 1) <= m { s += 1 }
    s
}

fn reps(m: i64) -> Vec<(i64, i64)> {                   // road one: whole (a, b) on the circle
    let mut out = Vec::new();
    for a in -isqrt(m)..=isqrt(m) {
        let b = isqrt(m - a * a);
        if b * b == m - a * a {
            if b != 0 { out.push((a, b)); out.push((a, -b)) } else { out.push((a, 0)) }
        }
    }
    out
}

fn r2_divisors(m: i64) -> i64 {                        // road two: 4 x (d1 - d3)
    let d1 = (1..=m).filter(|d| m % d == 0 && d % 4 == 1).count() as i64;
    let d3 = (1..=m).filter(|d| m % d == 0 && d % 4 == 3).count() as i64;
    4 * (d1 - d3)
}

fn by_formula(k: i64, m: i64) -> i64 {                 // road two for grids
    reps(m).iter().filter(|(a, b)| a.abs() < k && b.abs() < k)
        .map(|(a, b)| (k - a.abs()) * (k - b.abs())).sum::<i64>() / 2
}

fn most_shared(pts: &[Vec<i64>], m: i64) -> usize {
    let nb: Vec<BTreeSet<usize>> = pts.iter()
        .map(|p| (0..pts.len()).filter(|&j| sq(p, &pts[j]) == m).collect()).collect();
    let mut best = 0;
    for i in 0..pts.len() {
        for j in i + 1..pts.len() { best = best.max(nb[i].intersection(&nb[j]).count()) }
    }
    best
}

fn plane_cap(n: i64) -> i64 {
    let mut u = 0;
    let nf = n as f64;
    while (2.0 * (u + 1) as f64 / nf) * (2.0 * (u + 1) as f64 / nf - 1.0) <= 2.0 * (nf - 1.0) { u += 1 }
    u
}

fn sci(v: f64) -> String {
    let ex = v.log10().floor() as i32;
    format!("{:.3}e{}", v / 10f64.powi(ex), ex)
}

fn main() {
    let g3 = histogram(&grid(3));
    println!("3x3 grid: n = 9, pairs at distance 1: {} by brute force ({} across, {} up), {} by 2k(k-1)", g3[&1], g3[&1] / 2, g3[&1] / 2, 2 * 3 * 2);
    let g5 = histogram(&grid(5));
    println!("5x5 grid, pairs by squared distance: 1 -> {}, 2 -> {}, 5 -> {}, 25 -> {}", g5[&1], g5[&2], g5[&5], g5[&25]);
    let dc = |r: i64| (1..6).filter(|d| 5 % d == 0 && d % 4 == r).count();
    println!("5x5 knight steps: {} steps x (5-1)(5-2) = {} ordered, {} pairs; divisors of 5: d1 = {}, d3 = {}",
             reps(5).len(), reps(5).len() * 12, by_formula(5, 5), dc(1), dc(3));
    println!("best squared distance m in a k x k grid (brute force, then formula):");
    let mut best = BTreeMap::new();
    for k in [5i64, 10, 20, 30] {
        let h = histogram(&grid(k));
        let top = *h.values().max().unwrap();
        let m = *h.iter().find(|(_, &c)| c == top).unwrap().0;
        best.insert(k, (m, h[&m]));
        println!("  k={:2} n={:3} best m={:2} pairs {:5} formula {:5} distance-1 pairs {:5} pairs/n {:.2}",
                 k, k * k, m, h[&m], by_formula(k, m), h[&1], h[&m] as f64 / (k * k) as f64);
        assert!(by_formula(k, m) == h[&m] && h[&1] == 2 * k * (k - 1));
    }
    let r2s: Vec<(i64, i64, i64)> = [5, 15, 25, 45, 65, 325, 1105].iter().map(|&m| (m, reps(m).len() as i64, r2_divisors(m))).collect();
    let txt: Vec<String> = r2s.iter().map(|(m, a, b)| format!("{}: {} {}", m, a, b)).collect();
    println!("r2(m) on the circle and by divisors: {}", txt.join("; "));
    assert!(r2s.iter().all(|(_, a, b)| a == b));
    let m10 = best[&10].0;
    let g10 = grid(10);
    let sc2: i64 = g10.iter().map(|p| g10.iter().filter(|q| sq(p, q) == m10).count() as i64)
        .map(|d| d * (d - 1) / 2).sum();
    let ms10 = most_shared(&g10, m10);
    println!("plane rule, 10x10 grid at m={}: most shared neighbours {}; sum C(d,2) = {} <= n(n-1) = {}", m10, ms10, sc2, 100 * 99);
    let circ = reps(25);
    let mut four: Vec<Vec<i64>> = circ.iter().map(|&(a, b)| vec![a, b, 0, 0]).collect();
    four.extend(circ.iter().map(|&(a, b)| vec![0, 0, a, b]));
    let h4 = histogram(&four);
    println!("4-D, two circles of radius 5: n = {}, pairs at squared distance 50: {}; most shared neighbours {}",
             four.len(), h4[&50], most_shared(&four, 50));
    println!("plane cap for n = 24 when no two points share 3 neighbours: {}", plane_cap(24));
    assert!(ms10 <= 2 && sc2 <= 100 * 99 && h4[&50] > plane_cap(24));
    println!("mistake, 10x10 grid with distance 1 only: {} not {}", 2 * 10 * 9, best[&10].1);
    println!("mistake, ordered pairs in the 5x5 grid: {} not {}", 2 * g5[&5], g5[&5]);
    println!("mistake, 3x3 grid read as an exponent: log 12 / log 9 = {:.4}", 12f64.ln() / 9f64.ln());
    let primes1: Vec<i64> = (5..200).filter(|&p| p % 4 == 1 && (2..=isqrt(p)).all(|q| p % q != 0)).collect();
    let p6: Vec<String> = primes1[..6].iter().map(|p| p.to_string()).collect();
    println!("Erdos grid: m = first t primes 1 mod 4 ({}) multiplied, side k = 2s, s = isqrt(m) + 1:", p6.join(", "));
    let mut m = 1i64;
    for t in 1..7u32 {
        m *= primes1[t as usize - 1];
        let k = 2 * (isqrt(m) + 1);
        let u = by_formula(k, m);
        let r2 = reps(m).len() as i64;
        println!("  t={} m={} r2={} s={} k={} pairs {} >= 2^(t-1) n = {}; log u / log n - 1 = {:.4}",
                 t, m, r2, k / 2, k, u, 2i64.pow(t - 1) * k * k, (u as f64).ln() / ((k * k) as f64).ln() - 1.0);
        assert!(r2 == 4 * 2i64.pow(t) && u >= 2i64.pow(t - 1) * k * k);
    }
    let limit = 1_000_000usize;
    let mut sieve = vec![true; limit + 1];
    sieve[0] = false;
    sieve[1] = false;
    for p in 2..=1000 {
        if sieve[p] { let mut q = p * p; while q <= limit { sieve[q] = false; q += p } }
    }
    println!("the grid bound further out (extra exponent = (t-1) log 2 / log n, log n = log 4 + log m):");
    let (mut t, mut logm, mut mark) = (0i64, 0.0f64, 100usize);
    let mut p = 5usize;
    while p <= limit {
        if sieve[p] { t += 1; logm += (p as f64).ln() }
        if p + 4 > mark {
            let logn = 4f64.ln() + logm;
            let (e, est) = ((t - 1) as f64 * 2f64.ln() / logn, 2f64.ln() / logn.ln());
            println!("  primes below {:>7}: t = {:5}, log10 n = {:9.1}, extra exponent {:.4}, estimate log 2 / log log n {:.4}",
                     mark, t, logn / 10f64.ln(), e, est);
            assert!(e > 0.014 && (e / est - 1.0).abs() < 0.1);
            mark *= 10;
        }
        p += 4;
    }
    println!("estimate: c near log 2 = {:.4}; the grid's extra exponent falls to 0.014 near log10 n = {}", 2f64.ln(), sci((2f64.ln() / 0.014).exp() / 10f64.ln()));
    println!("quoted: Erdos 1946 grid and 3/2 ceiling; Golod-Shafarevich 1964; 4/3 ceiling 1984, Szekely 1997; disproof announced 2026-05-20; explicit eps 6.24e-38; Sawin exponent 1.014; u(9) = 18, u(21) = 57");
    println!("log10 n where n^eps reaches 2: eps 6.24e-38 -> {}, eps 0.014 -> {:.2}", sci(2f64.log10() / 6.24e-38), 2f64.log10() / 0.014);
    let mut segs = Vec::new();
    for pt in grid(5) {
        for (a, b) in reps(5) {
            let (x, y) = (pt[0], pt[1]);
            if (a > 0 || (a == 0 && b > 0)) && 0 <= x + a && x + a < 5 && 0 <= y + b && y + b < 5 { segs.push((x, y, x + a, y + b)) }
        }
    }
    let (x0, y0, x1, y1) = segs[0];
    println!("figure, 5x5 grid, step 60, origin (40, 40); {} segments of squared length 5; first ({}, {})-({}, {}); unit {:.2}",
             segs.len(), 40 + 60 * x0, 40 + 60 * y0, 40 + 60 * x1, 40 + 60 * y1, 60.0 * 5f64.sqrt());
    println!("ALL CHECKS PASS");
}
