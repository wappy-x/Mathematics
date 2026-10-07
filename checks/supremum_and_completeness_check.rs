// No gaps: least upper bounds -- the same check as the Python, in Rust.  No
// crates.  S is every number strictly between 0 and 1.  Road one plays the
// ceiling game in exact ten-thousandths: every proposed maximum, and every
// proposed ceiling below 1, is beaten by a member.  Road two scans finer and
// finer grids of members: the largest climbs toward 1 and never lands on it.
const U: i64 = 10000; // one unit, in ten-thousandths

fn dec(n: i64, places: u32) -> String { // dec(9500, 4) -> "0.95", exact
    let (sign, m, p) = (if n < 0 { "-" } else { "" }, n.abs(), 10_i64.pow(places));
    let s = format!("{}.{:0w$}", m / p, m % p, w = places as usize);
    format!("{}{}", sign, s.trim_end_matches('0').trim_end_matches('.'))
}

fn in_s(x: i64) -> bool { 0 < x && x < U } // is x (in ten-thousandths) in S?

fn beat(t: i64) -> i64 { if t > 0 { (t + U) / 2 } else { U / 2 } } // a member above t

fn main() {
    println!("S = every number strictly between 0 and 1");
    let (maxes, lows) = ([9000_i64, 9900, 9990], [9990_i64, 5000, -30000]);
    assert!(maxes.iter().chain(lows.iter()).all(|&x| in_s(beat(x)) && beat(x) > x)); // road one
    for m in maxes { // no largest member
        println!("proposed maximum {}: ({} + 1)/2 = {}, a larger member", dec(m, 4), dec(m, 4), dec(beat(m), 4));
    }
    for t in lows { // no ceiling below 1
        println!("proposed ceiling {}: member {} passes it", dec(t, 4), dec(beat(t), 4));
    }
    let mut tops: Vec<f64> = Vec::new();
    for n in 1..=20_u32 { // road two: grids of step 1/2^n
        let d = 2_i64.pow(n);
        let k = (0..=2 * d).filter(|&j| 0 < j && j < d).max().unwrap();
        assert!(k == d - 1); // scan agrees with 1 - 1/2^n
        tops.push(k as f64 / d as f64);
    }
    println!("road two, largest member on the grid of step 1/2^n, n = 1 to 8:");
    let shown: Vec<String> = tops[..8].iter().map(|x| format!("{}", x)).collect();
    println!("  {}", shown.join(", "));
    let two: Vec<String> = tops[..8].iter().map(|x| format!("{:.2}", x)).collect();
    println!("  to two places: {}", two.join(", "));
    println!("  n = 20: gap to 1 is 1/{}; every grid member stays below 1", 2_i64.pow(20));
    println!("ceiling 1.2 holds, and so does 1, which is lower: sup S = 1, no max S");
    println!("same set with 1 put in, (0, 1]: sup = 1 = max, a member");
    let (mut p, mut r, mut trims) = (3_i64, 2_i64, Vec::<(i64, i64)>::new()); // fraction ceilings
    for _ in 0..5 {
        assert!(p * p > 2 * r * r && trims.last().map_or(true, |&(a, b)| p * b < a * r)); // lower ceiling
        trims.push((p, r));
        let (np, nr) = (2 * p + 2 * r, p + 2 * r); // q -> (2q + 2)/(q + 2), lower
        let g = (1..=np.min(nr)).rev().find(|x| np % x == 0 && nr % x == 0).unwrap();
        p = np / g;
        r = nr / g;
    }
    println!("fraction ceilings over the fractions whose square is under 2:");
    let tr: Vec<String> = trims.iter().map(|&(a, b)| format!("{}/{} = {:.6}", a, b, a as f64 / b as f64)).collect();
    println!("  {}", tr.join(", "));
    let (mut lo, mut hi, mut den) = (1_i64, 2_i64, 1_i64); // halving: where the gap sits
    for _ in 0..20 {
        lo *= 2; hi *= 2; den *= 2;
        let mid = (lo + hi) / 2;
        if mid * mid < 2 * den * den { lo = mid } else { hi = mid }
    }
    assert!(trims.iter().all(|&(a, b)| a * den > hi * b)); // every fraction ceiling sits above
    println!("halving 20 times: the lowest ceiling is between {:.7} and {:.7}", lo as f64 / den as f64, hi as f64 / den as f64);
    let c = 10005_i64; // a ceiling over 1, 2, 3, ... ?
    println!("no ceiling over 1, 2, 3, ...: proposed ceiling {} is passed by {}", dec(c, 1), c / 10 + 1);
    let xs: Vec<String> = [0_i64, 5, 10, 12].iter().map(|&t| format!("{} -> {}", dec(t, 1), 40 + 25 * t)).collect();
    println!("figure, x = 40 + 250 t: {}", xs.join(", "));
    println!("ALL CHECKS PASS");
}
