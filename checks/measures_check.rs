// Measures -- the same check as the Python, in Rust.  No crates; exact fractions
// are written by hand.  A city of three districts, N, C and S.  Every set of
// districts gets a size under several rules.  Road one adds the pieces'
// weights; road two measures each union directly (a 0.1 km grid, a random
// sample of residents, the town hall's position); road three checks
// additivity on every pair of disjoint sets, for rules that pass and fail.
const NAMES: [&str; 3] = ["N", "C", "S"];
const PEOPLE: [i128; 3] = [40000, 25000, 10000]; // residents per district
const AREA: [i128; 3] = [12, 5, 8]; // square km per district
const EDGE: [i128; 4] = [0, 48, 68, 100]; // district edges along the strip, in 0.1 km
const HALL: i128 = 58; // town hall at 5.8 km, inside C
const TOTAL: i128 = PEOPLE[0] + PEOPLE[1] + PEOPLE[2];
const DRAWS: u64 = 20000;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 } // a fraction n/d in lowest terms; d = 0 means infinity

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    if d == 0 { return Q { n: 1, d: 0 }; }
    let g = gcd(n, d).max(1);
    Q { n: n / g, d: d / g }
}
fn add(a: Q, b: Q) -> Q { if a.d == 0 || b.d == 0 { q(1, 0) } else { q(a.n * b.d + b.n * a.d, a.d * b.d) } }
fn f(x: Q) -> f64 { x.n as f64 / x.d as f64 }
fn has(m: usize, i: usize) -> bool { m >> i & 1 == 1 }
fn label(m: usize) -> String {
    let v: Vec<&str> = (0..3).filter(|&i| has(m, i)).map(|i| NAMES[i]).collect();
    if v.is_empty() { "empty".to_string() } else { v.join(",") }
}
fn weighted(w: [i128; 3], m: usize) -> i128 { (0..3).filter(|&i| has(m, i)).map(|i| w[i]).sum() }
fn rule(name: &str, m: usize) -> Q { // road one: add the weights of the points
    match name {
        "districts" => q(weighted([1, 1, 1], m), 1),
        "residents" => q(weighted(PEOPLE, m), 1),
        "share" => q(weighted(PEOPLE, m), TOTAL),
        "area" => q(weighted(AREA, m), 1),
        "town hall" => q(weighted([0, 1, 0], m), 1),
        "never-finite" => if m == 0 { q(0, 1) } else { q(1, 0) },
        "density" => if m == 0 { q(0, 1) } else { q(weighted(PEOPLE, m), weighted(AREA, m)) },
        "largest district" => q((0..3).filter(|&i| has(m, i)).map(|i| PEOPLE[i]).max().unwrap_or(0), 1),
        _ => q(weighted(PEOPLE, m) - 30000, 1), // residents minus 30000
    }
}
fn district_of(x: i128) -> usize { (0..3).find(|&i| EDGE[i] <= x && x < EDGE[i + 1]).unwrap() }
fn grid_area(m: usize) -> Q { // road two for area: count 0.01 km2 cells
    let mut cells = 0;
    for col in 0..100 { for _row in 0..25 { if has(m, district_of(col)) { cells += 1; } } }
    q(cells, 100)
}
fn show(x: Q) -> String { if x.d == 0 { "inf".to_string() } else if x.d == 1 { x.n.to_string() } else { format!("{}/{}", x.n, x.d) } }

fn main() {
    let mut state: u64 = 20260929; // SplitMix64, seed 20260929
    let mut draw = || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    };
    let mut hits = [0u64; 3];
    for _ in 0..DRAWS { // a resident picked at random, by register number
        let k = (draw() % TOTAL as u64) as i128;
        hits[if k < PEOPLE[0] { 0 } else if k < PEOPLE[0] + PEOPLE[1] { 1 } else { 2 }] += 1;
    }
    println!("{:<8}{:>10}{:>11}{:>8}{:>10}{:>11}", "set", "districts", "residents", "share", "area km2", "town hall");
    for m in 0..8 {
        println!("{:<8}{:>10}{:>11}{:>8.4}{:>10}{:>11}", label(m), show(rule("districts", m)), show(rule("residents", m)),
                 f(rule("share", m)), show(rule("area", m)), show(rule("town hall", m)));
    }
    let grid: Vec<Q> = (0..8).map(grid_area).collect();
    assert!((0..8).all(|m| grid[m] == rule("area", m)));
    println!("area counted on a 0.1 km grid: {}", grid.iter().map(|&g| show(g)).collect::<Vec<_>>().join(", "));
    let est: Vec<f64> = (0..8).map(|m| (0..3).filter(|&i| has(m, i)).map(|i| hits[i]).sum::<u64>() as f64 / DRAWS as f64).collect();
    for m in 0..8 {
        let p = f(rule("share", m));
        assert!((est[m] - p).abs() <= 4.0 * (p * (1.0 - p) / DRAWS as f64).sqrt() + 1e-12);
    }
    println!("share from {} random residents: {}", DRAWS, est.iter().map(|e| format!("{:.4}", e)).collect::<Vec<_>>().join(", "));
    let hall: Vec<i128> = (0..8).map(|m| has(m, district_of(HALL)) as i128).collect();
    assert!((0..8).all(|m| q(hall[m], 1) == rule("town hall", m)));
    println!("town hall found by position: {}", hall.iter().map(|h| h.to_string()).collect::<Vec<_>>().join(", "));
    println!("city strip: 10 km by 2.5 km; edges at {} km; town hall at {} km; draws from SplitMix64, seed 20260929",
             EDGE.iter().map(|&e| (e as f64 / 10.0).to_string()).collect::<Vec<_>>().join(", "), HALL as f64 / 10.0);
    let survey = [0usize, 1, 6, 7]; // a survey that records only "lives in North?"
    assert!(survey.iter().all(|&a| survey.contains(&(7 ^ a)) && survey.iter().all(|&b| survey.contains(&(a | b)))));
    println!("survey recording only North: sets {}; residents {}", survey.iter().map(|&m| label(m)).collect::<Vec<_>>().join(", "),
             survey.iter().map(|&m| rule("residents", m).n.to_string()).collect::<Vec<_>>().join(", "));

    let pairs: Vec<(usize, usize)> = (0..8).flat_map(|a| (0..8).map(move |b| (a, b))).filter(|&(a, b)| a & b == 0).collect();
    let failures = |r: &str| pairs.iter().filter(|&&(a, b)| rule(r, a | b) != add(rule(r, a), rule(r, b))).count();
    let good = ["districts", "residents", "share", "area", "town hall", "never-finite"];
    let bad = ["density", "largest district", "residents minus 30000"];
    println!("disjoint pairs checked per rule: {}", pairs.len());
    let line = |rs: &[&str]| rs.iter().map(|r| format!("{} {}", r, failures(r))).collect::<Vec<_>>().join(", ");
    println!("additivity failures: {}", line(&good));
    println!("additivity failures: {}", line(&bad));
    assert!(good.iter().all(|r| failures(r) == 0));
    assert_eq!(bad.iter().map(|r| failures(r)).collect::<Vec<_>>(), vec![12, 12, 27]);
    let d = |m| rule("density", m);
    println!("density of N, C and N,C: {:.2}, {:.2}, {:.2} (parts add to {:.2})", f(d(1)), f(d(2)), f(d(3)), f(add(d(1), d(2))));
    let g = |m| rule("largest district", m).n;
    println!("largest district in N, C and N,C: {}, {}, {} (parts add to {})", g(1), g(2), g(3), g(1) + g(2));
    println!("residents minus 30000 on the empty set: {}", rule("residents minus 30000", 0).n);
    println!("residents of N,C plus residents of C,S: {} against the whole city {}",
             rule("residents", 3).n + rule("residents", 6).n, rule("residents", 7).n);

    // finite-or-not rule on whole numbers.  A set is stored exactly in 18 bits: bits
    // 0-11 are its members below 12; bits 12-17 are the remainders mod 6 of its
    // members from 12 on.  It is infinite exactly when one of bits 12-17 is set.
    let finite_or_not = |s: u64| if s >> 12 != 0 { f64::INFINITY } else { 0.0 };
    let (mut kinds, mut fails) = ([0u32; 3], 0);
    for _ in 0..3000 { // random disjoint pairs, finite and infinite
        let (x, y, u, v) = (draw(), draw(), draw(), draw());
        let a = x % (1u64 << (12 + 6 * (u % 2)));
        let b = y % (1u64 << (12 + 6 * (v % 2))) & !a;
        kinds[(a >> 12 > 0) as usize + (b >> 12 > 0) as usize] += 1;
        if finite_or_not(a | b) != finite_or_not(a) + finite_or_not(b) { fails += 1; }
    }
    assert!(fails == 0 && kinds.iter().all(|&k| k > 0));
    println!("finite-or-not rule: 3000 random disjoint pairs (both finite {}, one infinite {}, both infinite {}), additivity failures {}",
             kinds[0], kinds[1], kinds[2], fails);
    println!("finite-or-not rule: each singleton {}, union of {{0}} to {{11}} {}, all whole numbers {}",
             finite_or_not(1), finite_or_not((1 << 12) - 1), finite_or_not((1 << 18) - 1));
    let finite: Vec<usize> = (0..8).filter(|&m| rule("never-finite", m).d != 0).collect();
    let cover = finite.iter().fold(0, |c, &m| c | m);
    assert!(cover != 7);
    println!("never-finite rule: sets of finite size: {}; their union: {}, not the whole city",
             finite.iter().map(|&m| label(m)).collect::<Vec<_>>().join(", "), label(cover));

    for k in [1i64, 2, 3, 5, 10, 100] { // unit intervals [n, n+1), n = -k .. k-1
        let pieces: Vec<(i64, i64)> = (-k..k).map(|n| (n, n + 1)).collect();
        let mut runs: Vec<(i64, i64)> = Vec::new();
        for &(a, b) in &pieces { // merge touching pieces into runs
            match runs.last_mut() { Some(r) if r.1 == a => r.1 = b, _ => runs.push((a, b)) }
        }
        let sum: i64 = pieces.iter().map(|&(a, b)| b - a).sum();
        assert!(runs.len() == 1 && runs[0].1 - runs[0].0 == sum && sum == 2 * k);
        println!("unit intervals from {} to {}: {} pieces, lengths add to {}, merged run [{}, {}) has length {}",
                 -k, k, pieces.len(), 2 * k, runs[0].0, runs[0].1, runs[0].1 - runs[0].0);
    }
    println!("figure, city strip: 30 units per km, edges x = {}; town hall x = {}; height 75 = 2.5 km",
             EDGE.iter().map(|e| (30 + 3 * e).to_string()).collect::<Vec<_>>().join(", "), 30 + 3 * HALL);
    println!("ALL CHECKS PASS");
}
