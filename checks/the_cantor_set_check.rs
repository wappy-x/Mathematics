// The Cantor set -- the same check as the Python, in Rust.  No crates.  The road
// is [0, 1] km.  Stretch ends are whole numbers over D = 3^12; staircase values
// are exact fractions written by hand on i128; coin flips are SplitMix64.
const N: u32 = 12;
const D: i128 = 531441; // 3^12
#[derive(Clone, Copy, PartialEq)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); Q { n: n / g, d: d / g } }
fn add(a: Q, b: Q) -> Q { q(a.n * b.d + b.n * a.d, a.d * b.d) }
fn sub(a: Q, b: Q) -> Q { q(a.n * b.d - b.n * a.d, a.d * b.d) }
fn mulk(a: Q, k: i128) -> Q { q(a.n * k, a.d) }
fn divk(a: Q, k: i128) -> Q { q(a.n, a.d * k) }
fn below(a: Q, b: Q) -> bool { a.n * b.d < b.n * a.d }
fn p3(k: u32) -> i128 { 3i128.pow(k) }
fn dec(a: Q, places: u32) -> String {        // exact fraction as a decimal, half up
    let s = 10i128.pow(places);
    let v = (a.n * s * 2 + a.d) / (2 * a.d);
    if places == 0 { v.to_string() } else { format!("{}.{:0w$}", v / s, v % s, w = places as usize) }
}

fn nights(n: u32) -> (Vec<(i128, i128)>, Vec<(i128, i128)>) {   // road one: cut every middle third
    let (mut pieces, mut gaps) = (vec![(0, D)], Vec::new());
    for _ in 0..n {
        let mut nxt = Vec::new();
        for &(lo, hi) in &pieces {
            let w = (hi - lo) / 3;
            nxt.extend([(lo, lo + w), (hi - w, hi)]);
            gaps.push((lo + w, hi - w));
        }
        pieces = nxt;
    }
    (pieces, gaps)
}

fn by_digits(n: u32) -> Vec<(i128, i128)> {  // road two: keep stretches whose address has no 1
    let w = p3(N - n);
    (0..p3(n)).filter(|&k| (0..n).all(|j| k / p3(j) % 3 != 1)).map(|k| (k * w, k * w + w)).collect()
}

fn f_digits(mut x: Q, m: u32) -> Q {         // staircase, road A: ternary digits read in binary
    if !below(x, q(1, 1)) { return q(1, 1); }
    let (mut total, mut half) = (q(0, 1), q(1, 2));
    for _ in 0..m {
        x = mulk(x, 3);
        let d = x.n / x.d;
        x = sub(x, q(d, 1));
        if d == 1 { return add(total, half); }   // inside a resurfaced gap: flat from here
        total = add(total, mulk(half, d / 2));
        half = divk(half, 2);
    }
    total
}

fn f_self(x: Q, depth: u32) -> Q {           // staircase, road B: each outer third is a half-size copy
    if x.n <= 0 || depth == 0 { return q(0, 1); }
    if !below(x, q(1, 1)) { return q(1, 1); }
    let x3 = mulk(x, 3);
    if below(x3, q(1, 1)) { return divk(f_self(x3, depth - 1), 2); }
    if !below(q(2, 1), x3) { q(1, 2) } else { add(q(1, 2), divk(f_self(sub(x3, q(2, 1)), depth - 1), 2)) }
}

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn main() {
    println!("night  stretches  still waiting (m)  resurfaced (m)");
    for n in [0u32, 1, 2, 3, 4, 5, 10, 12, 18, 20] {
        let wait = q(1000 * 2i128.pow(n), p3(n));
        println!("{:>5}  {:>9}  {:>17}  {:>14}", n, 1u64 << n, dec(wait, 2), dec(sub(q(1000, 1), wait), 2));
    }
    let under = (0..60u32).find(|&n| 1000 * 2i128.pow(n) < p3(n)).unwrap();
    println!("first night the waiting length drops under 1 m: {}", under);
    let (pieces, gaps) = nights(N);
    let (plen, glen): (i128, i128) = (pieces.iter().map(|p| p.1 - p.0).sum(), gaps.iter().map(|p| p.1 - p.0).sum());
    println!("road one, night 12 built by cutting: {} stretches totalling {} m, {} gaps totalling {} m",
             pieces.len(), dec(q(1000 * plen, D), 2), gaps.len(), dec(q(1000 * glen, D), 2));
    let same = (0..9).all(|n| nights(n).0 == by_digits(n));
    println!("road two, stretches read from ternary addresses: same list as road one, nights 0 to 8: {}", if same { "yes" } else { "no" });
    let tern = |x: Q, n: u32| (1..=n).map(|k| (x.n * p3(k) / x.d % 3).to_string()).collect::<String>();   // base-3 digits
    let inside = (0..=N).all(|n| nights(n).0.iter().any(|&(lo, hi)| 4 * lo < D && D < 4 * hi));
    println!("250 m = 1/4 km = 0.{}... in base 3; strictly inside a waiting stretch after each night 0 to 12: {}",
             tern(q(1, 4), N), if inside { "yes" } else { "no" });
    let g800 = *nights(2).1.iter().find(|g| 5 * g.0 < 4 * D && 4 * D < 5 * g.1).unwrap();
    println!("800 m = 4/5 km = 0.{}... in base 3; its first 1 is digit 2, and it lies in the night-2 gap from {} to {} m",
             tern(q(4, 5), 8), dec(q(1000 * g800.0, D), 2), dec(q(1000 * g800.1, D), 2));
    let xs: Vec<Q> = (0..28).map(|k| q(k, 27)).collect();
    let fa: Vec<Q> = xs.iter().map(|&x| f_digits(x, 40)).collect();
    let fb: Vec<Q> = xs.iter().map(|&x| f_self(x, 40)).collect();
    println!("chart x (m): {}", xs.iter().map(|&x| dec(mulk(x, 1000), 0)).collect::<Vec<_>>().join(", "));
    println!("chart F (%): {}", fa.iter().map(|&f| dec(mulk(f, 100), 2)).collect::<Vec<_>>().join(", "));
    let (p6, g6) = nights(6);
    let flat = g6.iter().all(|&(l, h)| f_self(q(l, D), 40) == f_self(q(h, D), 40));
    let rises: Vec<Q> = p6.iter().map(|&(l, h)| sub(f_self(q(h, D), 40), f_self(q(l, D), 40))).collect();
    let one_rise = rises.iter().all(|&r| r == rises[0]);
    println!("F equal at both ends of all {} gaps of night 6: {}; rise across each of the {} waiting stretches: {}/{}",
             g6.len(), if flat { "yes" } else { "no" }, p6.len(), rises[0].n, rises[0].d);
    let (qa, qb) = (f_digits(q(1, 4), 40), f_self(q(1, 4), 40));
    println!("F(1/4) by digits and by copies, 40 steps: {} and {}", dec(qa, 9), dec(qb, 9));
    let slopes: Vec<Q> = [1u32, 5, 10, 20].iter().map(|&n| mulk(f_digits(q(1, p3(n)), 40), p3(n))).collect();
    println!("slope of F from 0 to 3^-n, which is (3/2)^n: {}", [1, 5, 10, 20].iter().zip(&slopes)
             .map(|(n, &s)| format!("n={}: {}", n, dec(s, 2))).collect::<Vec<_>>().join(", "));
    let (t, mut state, d30) = (20000i128, 2026u64, p3(30));
    let (marks, mut cnt, mut in12, mut unif6) = ([250i128, 500, 800], [0i128; 3], 0i128, 0i128);
    let mut first: Vec<Vec<i128>> = Vec::new();
    for i in 0..t {
        let r = splitmix(&mut state);
        let num: i128 = (0..30).map(|j| 2 * ((r >> j) & 1) as i128 * p3(29 - j)).sum();  // X times 3^30
        for (c, &m) in cnt.iter_mut().zip(&marks) { if num * 1000 <= m * d30 { *c += 1; } }
        let k = pieces.partition_point(|p| p.0 * p3(18) <= num) - 1;   // binary search, road one
        if pieces[k].0 * p3(18) <= num && num <= pieces[k].1 * p3(18) { in12 += 1; }
        if i < 6 { first.push((0..6).map(|j| 2 * ((r >> j) & 1) as i128).collect()); }
        let u = (splitmix(&mut state) % D as u64) as i128;
        if p6.iter().any(|&(l, h)| l <= u && u <= h) { unif6 += 1; }
    }
    println!("coin-flip points X (SplitMix64, seed 2026, 30 ternary digits each): {}", t);
    for (c, &m) in cnt.iter().zip(&marks) {
        println!("share with X <= {} m: {}; F({} m) = {}", m, dec(q(*c, t), 4), m, dec(f_digits(q(m, 1000), 40), 4));
    }
    println!("X inside a night-12 stretch of road one: {} of {}", in12, t);
    println!("uniform points inside a night-6 stretch: {} of {}, share {}; (2/3)^6 = {}", unif6, t, dec(q(unif6, t), 4), dec(q(64, 729), 4));
    let diag: Vec<i128> = (0..6).map(|k| 2 - first[k][k]).collect();
    let addr = |a: &Vec<i128>| a.iter().map(|d| d.to_string()).collect::<String>();
    let value = |a: &Vec<i128>| a.iter().enumerate().fold(q(0, 1), |s, (k, &d)| add(s, q(d, p3(k as u32 + 1))));
    println!("diagonal, listed addresses: {}", first.iter().map(|a| format!("0.{}", addr(a))).collect::<Vec<_>>().join(", "));
    let gapmin = first.iter().map(|a| { let g = sub(value(&diag), value(a)); q(g.n.abs(), g.d) })
        .fold(q(1, 1), |m, g| if below(g, m) { g } else { m });
    println!("diagonal, new address 0.{}; nearest listed point {} m away", addr(&diag), dec(mulk(gapmin, 1000), 2));
    let mut fat: Vec<(i64, i64)> = vec![(0, 1 << 24)];   // the fat version: at night n cut 1/4^n from each middle
    for n in 1..=10 {
        let half = (1i64 << 24) >> (2 * n + 1);
        fat = fat.iter().flat_map(|&(lo, hi)| { let m = (lo + hi) / 2; [(lo, m - half), (m + half, hi)] }).collect();
    }
    let fat_left = q(fat.iter().map(|p| (p.1 - p.0) as i128).sum(), 1 << 24);
    println!("mistake, cut 1/4^n instead of a third: after 10 nights {} stretches, {} m still waiting; the limit is 500.00 m",
             fat.len(), dec(mulk(fat_left, 1000), 2));
    println!("mistake, count points for length: night 12 keeps {} stretches and {} end points, all in the set, on {} m",
             pieces.len(), 2 * pieces.len(), dec(q(1000 * 2i128.pow(12), p3(12)), 2));
    println!("mistake, add up the slope: F' = 0 on gaps totalling {} m after 20 nights, 1000 m in the limit; slope integral 0, yet F rises from 0 to 1",
             dec(sub(q(1000, 1), q(1000 * 2i128.pow(20), p3(20))), 2));
    println!("figure, x = 18 + 324 t for t in km; night n drawn at y = 22 + 42 n, bars 12 high");
    for n in 0..5u32 {
        let xs: Vec<String> = nights(n).0.iter().map(|&(l, _)| (18 + 324 * l / D).to_string()).collect();
        println!("figure, night {}: width {} at x {}", n, 324 / p3(n), xs.join(", "));
    }
    assert!(same && inside && flat && in12 == t);                  // the roads agree, stretch by stretch
    assert!(plen * p3(N) == 2i128.pow(N) * D && glen == D - 2i128.pow(N));
    assert!(fa == fb && one_rise && rises[0] == q(1, 64));
    assert!([1u32, 5, 10, 20].iter().zip(&slopes).all(|(&n, &s)| s == q(p3(n), 2i128.pow(n))));
    let dist = |a: Q, b: Q| { let e = sub(a, b); q(e.n.abs(), e.d) };
    assert!(below(dist(qa, q(1, 3)), q(1, 1 << 39)) && below(dist(qb, q(1, 3)), q(1, 1 << 39)));
    for (c, &m) in cnt.iter().zip(&marks) {                        // simulation within 4 standard errors
        let f = f_digits(q(m, 1000), 40);
        let p = f.n as f64 / f.d as f64;
        assert!((*c as f64 / t as f64 - p).abs() < 4.0 * (p * (1.0 - p) / t as f64).sqrt());
    }
    let p = 64.0 / 729.0;
    assert!((unif6 as f64 / t as f64 - p).abs() < 4.0 * (p * (1.0 - p) / t as f64).sqrt());
    assert!(!below(mulk(gapmin, p3(6)), q(1, 1)));
    assert!(fat_left == add(q(1, 2), q(1, 1 << 11)));
    println!("ALL CHECKS PASS");
}
