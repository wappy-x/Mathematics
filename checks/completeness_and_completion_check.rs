// Complete space and completion -- the same check as the Python, in Rust.  No
// crates.  The space is the rationals with d(x, y) = |x - y|.  Every
// rational is held exactly as a pair of i128 integers (numerator, denominator).
// Decimals of root 2 are built two ways, a second Cauchy sequence (Newton's)
// is checked to sit at the same gap, and the "what breaks" numbers follow.
fn isqrt(n: i128) -> i128 {              // road one: largest r with r*r <= n, by halving
    let (mut lo, mut hi) = (0i128, 1i128);
    while hi * hi <= n { hi *= 2 }      // first find a power of 2 past the root
    while hi - lo > 1 {
        let mid = (lo + hi) / 2;
        if mid * mid <= n { lo = mid } else { hi = mid }
    }
    lo
}

fn digit_search(k: u32) -> i128 {        // road two: pick each decimal digit greedily
    let mut a: i128 = 1;
    for place in 1..=k {
        let d = (0..10).filter(|d| (a * 10 + d).pow(2) <= 2 * 100i128.pow(place)).max().unwrap();
        a = a * 10 + d;
    }
    a
}

fn gcd(mut a: i128, mut b: i128) -> i128 { // Euclid, so each fraction is counted once
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn dec(p: i128, q: i128, k: u32) -> String { // p/q >= 0, cut off (not rounded) to k places
    let s = format!("{:0>w$}", p * 10i128.pow(k) / q, w = k as usize + 1);
    if k == 0 { return s }
    let cut = s.len() - k as usize;
    format!("{}.{}", &s[..cut], &s[cut..])
}

fn exact(p: i128, k: u32) -> String {    // p / 10^k written out exactly, zeros trimmed
    if k == 0 { return p.to_string() }
    dec(p, 10i128.pow(k), k).trim_end_matches('0').trim_end_matches('.').to_string()
}

fn main() {
    let t = |k: u32| 10i128.pow(k);
    let a: Vec<i128> = (0..13).map(|n| isqrt(2 * 100i128.pow(n))).collect(); // a_n = a[n] / 10^n
    println!("a_n = root 2 cut off at n decimal places; every a_n is a fraction");
    for n in 0..7u32 {
        let an = a[n as usize];
        println!("a_{} = {:<9} 2 - a_{}^2 = {}", n, exact(an, n), n, exact(2 * 100i128.pow(n) - an * an, 2 * n));
    }
    let mut pairs = 0;
    let mut cauchy = true;
    for n in 0..13u32 {
        for m in n + 1..13u32 {
            pairs += 1;
            cauchy &= (a[m as usize] - a[n as usize] * t(m - n)).abs() < t(m - n);
        }
    }
    println!("Cauchy test |a_m - a_n| < 10^-n: {} on the {} pairs n < m <= 12", if cauchy { "holds" } else { "FAILS" }, pairs);
    let cut = (0..13usize).find(|&nn| (nn + 1..13).all(|n| (n + 1..13).all(|m|
        (a[m] * t(12 - m as u32) - a[n] * t(12 - n as u32)).abs() < t(9)))).unwrap();
    println!("smallest N with |a_m - a_n| < 10^-3 for all m, n > N (to 12): {}, so from a_{} = {} on",
             cut, cut + 1, exact(a[cut + 1], cut as u32 + 1));
    let mut hits = 0;
    for q in 1..=2000i128 {
        let r = isqrt(2 * q * q);
        for p in [r, r + 1] { if p * p == 2 * q * q { hits += 1 } }
    }
    println!("fractions p/q with q <= 2000 and p^2 = 2 q^2: {}", hits);

    let mut b: Vec<(i128, i128)> = vec![(1, 1)];        // Newton: b -> (b + 2/b) / 2
    for _ in 0..4 {
        let (p, q) = *b.last().unwrap();
        b.push((p * p + 2 * q * q, 2 * p * q));
    }
    for (k, &(p, q)) in b.iter().enumerate() {
        let gap = (a[k] * q - p * t(k as u32)).abs();
        println!("b_{} = {}/{} = {}   |a_{} - b_{}| = {}", k, p, q, dec(p, q, 8), k, k, dec(gap, q * t(k as u32), 8));
    }
    let cd: Vec<String> = (0..5).map(|k| dec(a[k], t(k as u32), 6)).collect();
    let cn: Vec<String> = b.iter().map(|&(p, q)| dec(p, q, 6)).collect();
    println!("chart, decimals: {}", cd.join(", "));
    println!("chart, Newton:   {}", cn.join(", "));
    let far_a = 3 * t(6) - 2 * a[6];                    // |a_6 - 3/2| = far_a / (2 * 10^6)
    let (p4, q4) = b[4];
    let far_b = 3 * q4 - 2 * p4;                        // |b_4 - 3/2| = far_b / (2 * q4)
    println!("distance from the new point to 3/2: via a_6 {}, via b_4 {}", dec(far_a, 2 * t(6), 8), dec(far_b, 2 * q4, 8));

    let mut stage: Vec<((i128, i128), Option<u32>)> = Vec::new(); // Cantor: nest [a_n, a_n + 10^-n]
    for q in 1..=100i128 {
        for p in q..=2 * q {
            if gcd(p, q) != 1 { continue }
            let s = (0..13u32).find(|&n| p * t(n) < a[n as usize] * q || p * t(n) > (a[n as usize] + 1) * q);
            stage.push(((p, q), s));
        }
    }
    let mut best = stage[0];
    for &e in &stage {
        if e.1 > best.1 || (e.1 == best.1 && e.0 .1 < best.0 .1) { best = e }
    }
    let ((lp, lq), last) = best;
    println!("Cantor nest in the rationals: {} fractions in [1, 2] with q <= 100, all thrown out by stage 12; the last, {}/{}, at stage {}",
             stage.len(), lp, lq, last.unwrap());
    let (gx, gy) = (3i128, 4i128);                      // street grid: corner (0, 0) to corner (3, 4)
    let (walk, line2) = (gx + gy, gx * gx + gy * gy);   // walking distance, and straight distance squared
    let st = isqrt(line2);
    println!("street grid, corner ({}, {}): walk {} blocks, straight {}; {}^2 = {} <= {}^2 = {} <= 2 x {}^2 = {}",
             gx, gy, walk, st, st, line2, walk, walk * walk, st, 2 * line2);
    let harmonic: f64 = (101..201).map(|k| 1.0 / k as f64).sum();
    println!("mistake 1, neighbours close but not Cauchy: 1/101 + ... + 1/200 = {:.6}, at least 100 x 1/200 = 0.5", harmonic);
    let p2 = 1000 - 10;                                 // 1/10 - 1/1000 = (1000 - 10) / (10 x 1000) = p2 / 10^4
    println!("mistake 2, 1/n in (0, 1]: d(1/10, 1/1000) = {}; the limit 0 is not in (0, 1]", exact(p2, 4));
    let leave = (0..100).find(|&n| n as f64 > 7.5).unwrap(); // first [n, inf) without 7.5
    println!("mistake 3, closed sets [n, inf) never shrink in width: x = 7.5 leaves at n = {}, so none is common", leave);
    let (lo, hi) = (10i128, 100i128);
    let (hp, hq) = (hi * (1 + lo) - lo * (1 + hi), (1 + lo) * (1 + hi)); // f(x) = x/(1+x): f(100) - f(10)
    println!("mistake 4, f(x) = x/(1+x): d({}, {}) = {}, d(f({}), f({})) = {}/{} = {}", lo, hi, hi - lo, lo, hi, hp, hq, dec(hp, hq, 7));

    assert!((0..13u32).all(|n| digit_search(n) == a[n as usize]));          // two roads to the decimals
    assert!(cauchy && hits == 0);                                         // Cauchy, and no square root in reach
    assert!(b[1..].iter().all(|&(p, q)| p * p - 2 * q * q == 1));        // Newton's squares land 1/q^2 above 2
    assert!(b.iter().enumerate().skip(1).all(|(k, &(p, q))|
        (a[k] * q - p * t(k as u32)).abs() * t(k as u32 - 1) <= q * t(k as u32)));
    assert!((far_a * q4 - far_b * t(6)).abs() * t(6) < 2 * t(6) * q4);   // one distance, two roads
    assert!(stage.iter().all(|e| e.1.is_some()));                      // every fraction leaves the nest
    let inside = |p: i128, q: i128, n: u32| {                          // nest test two: truncate p/q to n places
        let k = p * t(n) / q;
        k == a[n as usize] || (k == a[n as usize] + 1 && k * q == p * t(n))
    };
    assert!(stage.iter().all(|&((p, q), s)| s == (0..13u32).find(|&n| !inside(p, q, n))));
    println!("ALL CHECKS PASS");
}
