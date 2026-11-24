// Compactness of [a, b] -- the same check as the Python, in Rust.  No crates.
// Part 1, Bolzano-Weierstrass: halve [-2, 2] and keep a half that still holds the list's
// far terms, then pick ever-later terms.  Part 2, Heine-Borel: walk right along [0, 1],
// each step jumping to the farthest right end of a cover set that holds the current point.
const M: i64 = 1_000_000;                           // far terms x_{M+1}, x_{M+2} witness "infinitely many"

fn x(n: i64) -> f64 { (if n % 2 == 0 { 1.0 } else { -1.0 }) * (1.0 + 1.0 / n as f64) }

fn holds_far_terms(lo: f64, hi: f64) -> bool { [M + 1, M + 2].iter().any(|&n| lo <= x(n) && x(n) <= hi) }

fn g(v: f64) -> String {                            // six significant digits, trailing zeros dropped
    let d = (5 - v.abs().log10().floor() as i64).max(0) as usize;
    let s = format!("{:.*}", d, v);
    if s.contains('.') { s.trim_end_matches('0').trim_end_matches('.').to_string() } else { s }
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (mut lo, mut hi, mut n) = (-2.0f64, 2.0f64, 0i64);
    let (mut kept, mut picks): (Vec<(f64, f64)>, Vec<i64>) = (vec![], vec![]);
    for stage in 0..21 {
        if stage > 0 {                              // halve; keep the left half if it still qualifies
            let mid = (lo + hi) / 2.0;
            if holds_far_terms(lo, mid) { hi = mid } else { lo = mid }
        }
        n += 1;
        while !(lo <= x(n) && x(n) <= hi) { n += 1 }   // first term later than the last pick
        kept.push((lo, hi));
        picks.push(n);
    }
    let join = |v: Vec<String>, sep: &str| v.join(sep);
    println!("x_1 to x_6: {}", join((1..7).map(|k| format!("{:.6}", x(k))).collect(), " "));
    println!("kept halves: {}", join(kept[..7].iter().map(|&(a, b)| format!("[{}, {}]", g(a), g(b))).collect(), " "));
    println!("picks n: {}  values: {}", join(picks[..7].iter().map(|k| k.to_string()).collect(), " "),
             join(picks[..7].iter().map(|&k| format!("{:.6}", x(k))).collect(), " "));
    println!("stage 20: kept [{:.6}, {:.6}], width {:.6}, pick n = {}, x_n = {:.6}", lo, hi, hi - lo, n, x(n));
    let road2 = picks.iter().all(|&k| k % 2 == 1 && (x(k) + 1.0 - (-1.0 / k as f64)).abs() < 1e-12);
    let inside = picks[2..].iter().zip(&kept[2..]).all(|(&k, &(a, b))| (x(k) + 1.0).abs() <= b - a);
    println!("every pick is an odd term, 1/n below -1: {}; within its half's width of -1: {}", yn(road2), yn(inside));

    let mut cover = vec![(-0.1f64, 0.1f64)];
    for k in 1..=1000 { cover.push((1.0 / k as f64, 2.0)) }
    let (mut point, mut used): (f64, Vec<(f64, f64)>) = (0.0, vec![]);
    while point <= 1.0 {                            // the supremum walk: reach as far right as one set allows
        let mut best = (0.0, f64::NEG_INFINITY);
        for &s in &cover { if s.0 < point && point < s.1 && s.1 > best.1 { best = s } }
        used.push(best);
        point = best.1;
    }
    println!("walk on [0, 1]: from 0 via {}: {} sets",
             join(used.iter().map(|&(a, b)| format!("({}, {})", g(a), g(b))).collect(), ", then "), used.len());
    println!("0.1 is not where the walk stops: (1/11, 2) holds it with room {:.6} on its left", 0.1 - 1.0 / 11.0);
    let grid = (0..=100000).all(|k| used.iter().any(|&(a, b)| a < k as f64 / 100000.0 && (k as f64 / 100000.0) < b));
    println!("those {} sets hold all 100001 points k/100000 of [0, 1]: {}", used.len(), yn(grid));
    let miss: Vec<f64> = [10i64, 100, 1000].iter().map(|&nn| (1..nn + 2).map(|m| 1.0 / m as f64)
        .find(|&p| !(1..=nn).any(|k| 1.0 / (k as f64) < p && p < 2.0)).unwrap()).collect();
    println!("(0, 1], first N sets (1/n, 2) for N = 10, 100, 1000 miss {}; x_n = 1/n heads for 0, outside",
             join(miss.iter().map(|&v| g(v)).collect(), ", "));
    let far: Vec<i64> = [10i64, 100, 1000].iter()
        .map(|&nn| (0..nn + 2).find(|&m| !(1..=nn).any(|k| -1 < m && m < k)).unwrap()).collect();
    println!("[0, infinity), first N sets (-1, n) miss {}; x_n = n: neighbours 1 apart, nothing settles",
             join(far.iter().map(|v| v.to_string()).collect(), ", "));
    println!("mistake, the whole list: x_1000 = {:.6}, x_1001 = {:.6}, gap {:.6}", x(1000), x(1001), x(1000) - x(1001));
    let first = (1..=M).filter(|&k| -2.0 <= x(k) && x(k) <= -1.5).count();
    println!("mistake, keep a half holding any term: [-2, -1.5] holds {} of the first {} terms", first, M);
    assert!(kept[3] == (-1.5, -1.0) && picks[..7] == [1, 3, 5, 7, 9, 11, 17]);   // halving as the card says
    assert!(road2 && inside && (x(n) + 1.0).abs() <= hi - lo);                  // picks settle on -1
    assert!(used.len() == 2 && grid && used[1].0 < used[0].1);                  // two sets cover [0, 1]
    assert!(miss == [0.1, 0.01, 0.001] && far == [10, 100, 1000] && first == 1); // failures
    println!("ALL CHECKS PASS");
}
