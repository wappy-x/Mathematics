// Generated sigma-algebras and Borel sets -- the same check as the Python, in
// Rust, std only.  Part 1: a world of four whole-degree readings, each generated
// sigma-algebra built by three roads.  Part 2: the real-line steps at exact
// rational points, written as integer numerator and denominator pairs.
use std::collections::{BTreeMap, BTreeSet};

const R: [i64; 4] = [17, 18, 19, 20]; // the four readings; a set is a 4-bit mask
const FULL: u32 = 15;

fn show(m: u32) -> String {
    let v: Vec<String> = (0..4).filter(|i| m >> i & 1 == 1).map(|i| R[i].to_string()).collect();
    format!("{{{}}}", v.join(", "))
}
fn mask<F: Fn(i64) -> bool>(test: F) -> u32 {
    (0..4).filter(|&i| test(R[i])).map(|i| 1u32 << i).sum()
}
// road 1: add complements and unions until nothing new
fn closure(c: &[u32]) -> (BTreeSet<u32>, Vec<usize>) {
    let mut s: BTreeSet<u32> = c.iter().copied().collect();
    let mut rounds = vec![s.len()];
    loop {
        let mut new = s.clone();
        for &a in &s {
            new.insert(FULL ^ a);
            for &b in &s { new.insert(a | b); }
        }
        if new == s { return (s, rounds); }
        s = new;
        rounds.push(s.len());
    }
}
// road 2: group readings no generator can tell apart
fn by_atoms(c: &[u32]) -> (BTreeSet<u32>, Vec<u32>) {
    let mut groups: BTreeMap<Vec<u32>, u32> = BTreeMap::new();
    for i in 0..4 {
        let sig: Vec<u32> = c.iter().map(|g| g >> i & 1).collect();
        *groups.entry(sig).or_insert(0) |= 1 << i;
    }
    let mut atoms: Vec<u32> = groups.values().copied().collect();
    atoms.sort();
    let unions = (0..1u32 << atoms.len())
        .map(|k| (0..atoms.len()).filter(|j| k >> j & 1 == 1).map(|j| atoms[j]).sum())
        .collect();
    (unions, atoms)
}
// the three rules, on a family of subsets
fn is_sigma(f: u32) -> bool {
    let mem: Vec<u32> = (0..16).filter(|s| f >> s & 1 == 1).collect();
    f & 1 == 1 && mem.iter().all(|&m| f >> (FULL ^ m) & 1 == 1)
        && mem.iter().all(|&a| mem.iter().all(|&b| f >> (a | b) & 1 == 1))
}
// road 3: intersect every sigma-algebra holding C
fn by_intersection(c: &[u32], sigmas: &[u32]) -> BTreeSet<u32> {
    let mut out: u32 = 0xFFFF;
    for &f in sigmas {
        if c.iter().all(|&g| f >> g & 1 == 1) { out &= f; }
    }
    (0..16).filter(|s| out >> s & 1 == 1).collect()
}
// x = (num, den) with den > 0: is x below t + 1/n?
fn below(x: (i64, i64), t: i64, n: i64) -> bool { x.0 * n < (t * n + 1) * x.1 }
fn open_below(x: (i64, i64), t: i64) -> bool { x.0 < t * x.1 }
fn closed_below(x: (i64, i64), t: i64) -> bool { (1..=10000).all(|n| below(x, t, n)) }

fn main() {
    let sigmas: Vec<u32> = (0..1u32 << 16).filter(|&f| is_sigma(f)).collect();
    let mut bell = vec![1u64]; // Bell numbers: ways to split a set into blocks
    for n in 0..4u64 {
        let mut row = vec![1u64];
        for k in 1..=n { let last = row[row.len() - 1]; row.push(last * (n - k + 1) / k); }
        bell.push((0..=n as usize).map(|k| row[k] * bell[k]).sum());
    }
    let rays: BTreeSet<u32> = (16..22).map(|t| mask(|r| r < t)).collect();
    let mut open = BTreeSet::new();
    for a in 32..43 { for b in (a + 1)..43 { open.insert(mask(|r| a < 2 * r && 2 * r < b)); } }
    let mut closed = BTreeSet::new();
    for &a in &R { for &b in &R { if a <= b { closed.insert(mask(|r| a <= r && r <= b)); } } }
    let families: Vec<(&str, Vec<u32>)> = vec![
        ("rays below t", rays.into_iter().collect()),
        ("open intervals", open.into_iter().collect()),
        ("closed intervals", closed.into_iter().collect()),
        ("gauge, t = 18, 20", vec![mask(|r| r < 18), mask(|r| r < 20)]),
    ];
    println!("four readings [17, 18, 19, 20]: subsets 16, sigma-algebras {}, Bell number {}", sigmas.len(), bell[4]);
    println!("family             | generators | closure | atoms | intersection | rounds");
    let (mut gs, mut gatoms) = (BTreeSet::new(), vec![]);
    for (name, c) in &families {
        let (s1, rounds) = closure(c);
        let (s2, atoms) = by_atoms(c);
        let s3 = by_intersection(c, &sigmas);
        assert!(s1 == s2 && s2 == s3, "{}", name); // three roads, one family
        let r: Vec<String> = rounds.iter().map(|x| x.to_string()).collect();
        println!("{:18} | {:10} | {:7} | {:5} | {:12} | {}", name, c.len(), s1.len(), s2.len(), s3.len(), r.join(" -> "));
        if name.starts_with("gauge") { gs = s1; gatoms = atoms; }
    }
    let a: Vec<String> = gatoms.iter().map(|&m| show(m)).collect();
    println!("gauge atoms: {}", a.join(" | "));
    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("gauge settles 'exactly 19': {}; 'exactly 20': {}",
             yn(gs.contains(&mask(|r| r == 19))), yn(gs.contains(&mask(|r| r == 20))));
    assert!(sigmas.len() as u64 == bell[4] && bell[4] == 15);
    assert!(!gs.contains(&mask(|r| r == 19)) && gs.contains(&mask(|r| r == 20)) && gs.len() == 1 << gatoms.len() && gs.len() == 8);

    // ---- Part 2: the real line, at exact rational points ----
    println!("closed ray (-inf, 20] from open rays (-inf, 20 + 1/n): first n that leaves each point out");
    for x in [(41i64, 2i64), (203, 10), (2001, 100), (200007, 10000)] {
        let mut n = 1;
        while below(x, 20, n) { n += 1; } // search: shrink the ray until x falls outside
        let (d_num, d_den) = (x.0 - 20 * x.1, x.1); // x - 20 as a fraction
        let formula = (d_den + d_num - 1) / d_num;  // ceiling of 1/(x - 20), integers only
        assert_eq!(n, formula);
        println!("  reading {}: search n = {}, formula n = {}", x.0 as f64 / x.1 as f64, n, formula);
    }
    println!("  by hand, reading 20.3: 20 + 1/3 = {:.4} is above it, 20 + 1/4 = {} is not", 20.0 + 1.0 / 3.0, 20.0 + 1.0 / 4.0);
    println!("  reading 20: inside every ray, so inside (-inf, 20]");
    let sl: Vec<String> = [1, 2, 4, 10, 100, 1000].iter().map(|&n| format!("n={} {}", n, 1.0 / n as f64)).collect();
    println!("sliver [20, 20 + 1/n) = (-inf, 20 + 1/n) minus (-inf, 20), length by n: {}", sl.join(", "));

    let mut grid: Vec<(i64, i64)> = (68..85).map(|k| (k, 4)).collect();
    for s in [-1, 1] { grid.push((18000 + s, 1000)); }
    for s in [-1, 1] { grid.push((20000 + s, 1000)); }
    type Test = Box<dyn Fn((i64, i64)) -> bool>;
    let built: Vec<(&str, Test, Test)> = vec![
        ("{20}", Box::new(|x: (i64, i64)| x.0 == 20 * x.1),
         Box::new(|x| closed_below(x, 20) && !open_below(x, 20))),
        ("(18, 20)", Box::new(|x: (i64, i64)| 18 * x.1 < x.0 && x.0 < 20 * x.1),
         Box::new(|x| open_below(x, 20) && !closed_below(x, 18))),
        ("[18, 20]", Box::new(|x: (i64, i64)| 18 * x.1 <= x.0 && x.0 <= 20 * x.1),
         Box::new(|x| closed_below(x, 20) && !open_below(x, 18))),
    ];
    for (name, direct, from_rays) in &built {
        let agree = grid.iter().filter(|&&x| direct(x) == from_rays(x)).count();
        assert_eq!(agree, grid.len(), "{}", name);
        println!("  {:9} built from rays agrees with its definition at {} of {} exact points", name, agree, grid.len());
    }
    println!("  (a closed ray (-inf, t] is tested as the rays (-inf, t + 1/n) for n = 1 to 10000)");

    let (mut lo, mut hi) = (1.0f64, 2.0f64); // square root of 2 by bisection, written out
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if mid * mid < 2.0 { lo = mid } else { hi = mid }
    }
    println!("band (0, sqrt 2), sqrt 2 = {:.6} by bisection; union of rational intervals (0, p/q) inside it", lo);
    for q in [1i64, 10, 100, 1000] {
        let mut p = 0i64;
        while (p + 1) * (p + 1) < 2 * q * q { p += 1; } // search: largest p with (p/q)^2 < 2
        assert_eq!(p, (q as f64 * lo).floor() as i64);  // the bisection root gives the same p
        let r = p as f64 / q as f64;
        println!("  q = {:4}: p = {:4}, reach p/q = {:.4}, uncovered [p/q, sqrt 2) length {:.6}", q, p, r, lo - r);
    }
    println!("  by hand, q = 100: 141*141 = {} < 2*100*100 = {} < 142*142 = {}", 141 * 141, 2 * 100 * 100, 142 * 142);
    let x = |t: f64| 40.0 + 120.0 * (t - 19.0); // the picture: 120 units per degree
    println!("figure, x(19) = {}, x(20) = {}, x(21) = {}, sliver right ends n=1,2,4: {}, {}, {}",
             x(19.0), x(20.0), x(21.0), x(21.0), x(20.5), x(20.25));
    println!("ALL CHECKS PASS");
}
