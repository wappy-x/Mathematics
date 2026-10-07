// Symmetry and tilings: the same four counts as the Python, two roads each.  No crates.
use std::collections::BTreeSet;
type M = [f64; 4];
fn turn(t: f64) -> M { let (s, c) = t.to_radians().sin_cos(); [c, -s, s, c] }          // R_theta
fn flip(p: f64) -> M { let (s, c) = (2.0 * p).to_radians().sin_cos(); [c, s, s, -c] }  // F_phi
fn mul(a: M, b: M) -> M { [a[0]*b[0] + a[1]*b[2], a[0]*b[1] + a[1]*b[3], a[2]*b[0] + a[3]*b[2], a[2]*b[1] + a[3]*b[3]] }
fn imul(a: [i64; 4], b: [i64; 4]) -> [i64; 4] { [a[0]*b[0] + a[1]*b[2], a[0]*b[1] + a[1]*b[3], a[2]*b[0] + a[3]*b[2], a[2]*b[1] + a[3]*b[3]] }
fn key(m: M) -> [i64; 4] { m.map(|v| (v * 1e6).round() as i64) }
fn angle(m: M) -> i64 { (m[2].atan2(m[0]).to_degrees().round() as i64).rem_euclid(360) }
fn imp(a: bool, b: bool) -> bool { b || !a }
fn has(s: u32, g: fn(i64, i64, i64) -> (i64, i64), cs: &[i64]) -> bool {   // is strip s unchanged by g, for some c?
    cs.iter().any(|&c| { let mut o = 0u32;
        for i in 0..12i64 { if s >> i & 1 == 1 { let (x, y) = g(i % 6, i / 6, c); o |= 1u32 << (y * 6 + x.rem_euclid(6)); } }
        o == s })
}
fn name(k: [bool; 4]) -> String { let s: String = "VHRG".chars().zip(k).filter(|p| p.1).map(|p| p.0).collect(); if s.is_empty() { "-".into() } else { s } }
fn order(m: [i64; 4]) -> i64 { let mut q = m; for k in 1..13 { if q == [1, 0, 0, 1] { return k } q = imul(m, q) } 0 }
const L: i64 = 55440;                                                   // costs counted in 55440ths
fn cost(n: i64, on: bool) -> i64 { if on { L * (n - 1) / (2 * n) } else { L * (n - 1) / n } }  // centre on / off mirrors
fn bags(on: bool, budget: i64, low: i64) -> Vec<(Vec<i64>, i64)> {     // multisets of turn orders fitting the budget
    let mut out = vec![(vec![], 0)];
    for n in low..13 { if cost(n, on) <= budget { for (b, k) in bags(on, budget - cost(n, on), n) {
        let mut v = vec![n]; v.extend(b); out.push((v, cost(n, on) + k)); } } }
    out
}
fn digits(v: &[i64]) -> String { v.iter().rev().map(|d| d.to_string()).collect() }
fn main() {
    let (mut moves, mut todo) = (vec![(key(turn(0.0)), turn(0.0))], vec![turn(0.0)]);   // road 1: close up R_60, F_0
    while let Some(q) = todo.pop() {
        for m in [mul(turn(60.0), q), mul(flip(0.0), q)] { if !moves.iter().any(|e| e.0 == key(m)) { moves.push((key(m), m)); todo.push(m); } }
    }
    let turns = moves.iter().filter(|e| e.1[0] * e.1[3] - e.1[1] * e.1[2] > 0.0).count();  // a turn keeps clockwise order
    let tipmaps = (0..46656i64).filter(|c| { let f: Vec<i64> = (0..6).map(|i| c / 6i64.pow(i) % 6).collect();   // road 2
        f.iter().collect::<BTreeSet<_>>().len() == 6 && (0..6).all(|i| [1, 5].contains(&(f[(i + 1) % 6] - f[i]).rem_euclid(6))) }).count();
    let mut found = BTreeSet::new();                                    // strips: 6 cells long, 2 rows, repeating
    for s in 0..4096u32 {                                               // road 1: every strip, read off
        let p = [1, 2, 3, 6].into_iter().find(|&d| has(s, |x, y, c| (x + c, y), &[d])).unwrap();
        let glides: Vec<i64> = (1..6).filter(|t| t % p != 0).collect();
        found.insert([has(s, |x, y, c| (c - x, y), &[0, 1, 2, 3, 4, 5]), has(s, |x, y, c| (x + c, 1 - y), &[0]),
                      has(s, |x, y, c| (c - x, 1 - y), &[0, 1, 2, 3, 4, 5]), has(s, |x, y, c| (x + c, 1 - y), &glides)]);
    }
    let mut rules = BTreeSet::new();                                    // road 2: the composition rules alone
    for code in 0..16 { let [v, h, r, g] = [0, 1, 2, 3].map(|i| code >> i & 1 == 1);
        if !(h && g) && imp(v && h, r) && imp(h && r, v) && imp(v && r, h || g) && imp(v && g, r) && imp(r && g, v) { rules.insert([v, h, r, g]); } }
    let names = |k: &BTreeSet<[bool; 4]>| { let mut n: Vec<String> = k.iter().map(|&x| name(x)).collect(); n.sort(); n.join(", ") };
    let mut lat = BTreeSet::new();                                      // every whole-number turn matrix
    for a in -2..3 { for b in -2..3 { for c in -2..3 { for d in -2..3 { if a * d - b * c == 1 && order([a, b, c, d]) > 0 { lat.insert(order([a, b, c, d])); } } } } }
    let lattice: Vec<i64> = lat.into_iter().collect();
    let trace: Vec<i64> = (1..13).filter(|&n| { let t = 2.0 * (360.0 / n as f64).to_radians().cos(); (t - t.round()).abs() < 1e-9 }).collect();
    let mut walls: Vec<String> = Vec::new();
    for h in 0..2 { for s in 0..3 { for x in 0..3 { if 2 * h + s + x > 2 { continue } let left = L * (2 - 2 * h - s - x);
        for (a, ca) in bags(false, left, 2) { for (b, cb) in if s == 1 { bags(true, left - ca, 2) } else { vec![(vec![], 0)] } {
            if ca + cb == left { walls.push(format!("{}{}{}{}{}", "o".repeat(h as usize), digits(&a), "*".repeat(s as usize), digits(&b), "x".repeat(x as usize))); } } } } } }
    walls.sort();
    let used: Vec<i64> = walls.iter().flat_map(|w| w.chars().filter_map(|c| c.to_digit(10))).map(|d| d as i64).collect::<BTreeSet<_>>().into_iter().collect();
    let top: Vec<i64> = walls.iter().map(|w| w.chars().filter_map(|c| c.to_digit(10)).max().unwrap_or(1) as i64).collect();
    let (r60, f) = (turn(60.0), |n: i64, on: bool| cost(n, on) as f64 / L as f64);
    println!("snowflake moves, closing up R_60 and F_0: {} ({} turns, {} flips)", moves.len(), turns, moves.len() - turns);
    println!("tip relabellings keeping neighbours, of 6^6 = 46656: {}", tipmaps);
    println!("R_60 = ({:.4}, {:.4}; {:.4}, {:.4}), trace {:.4}", r60[0], r60[1], r60[2], r60[3], r60[0] + r60[3]);
    println!("F_0 then F_30: turn by {} deg; F_30 then F_0: turn by {} deg", angle(mul(flip(30.0), flip(0.0))), angle(mul(flip(0.0), flip(30.0))));
    println!("strip kinds from all 4096 strips: {}: {}", found.len(), names(&found));
    println!("strip kinds from the rules, of 16 on-off lists: {}: {}", rules.len(), names(&rules));
    println!("turn orders of whole-number matrices: {:?}; by the trace 2cos: {:?}", lattice, trace);
    println!("5-fold: 2cos(72 deg) = {:.4}, not whole", 2.0 * 72f64.to_radians().cos());
    println!("cost of 632 = {:.4} + {:.4} + {:.4} = {:.4}; of *632 = 1 + {:.4} + {:.4} + {:.4} = {:.4}", f(6, false), f(3, false), f(2, false),
             (cost(6, false) + cost(3, false) + cost(2, false)) as f64 / L as f64, f(6, true), f(3, true), f(2, true), 1.0 + (cost(6, true) + cost(3, true) + cost(2, true)) as f64 / L as f64);
    println!("wall signatures costing exactly 2: {}\n  {}", walls.len(), walls.join(" "));
    println!("turn orders used: {:?}; count by largest turn: {}", used, [1, 2, 3, 4, 6].map(|n| format!("{}: {}", n, top.iter().filter(|&&t| t == n).count())).join(", "));
    println!("figure, centre (130, 120), 1 mm = 90 units, tips {}", (0..6).map(|k| { let a = (90.0 + 60.0 * k as f64).to_radians();
        format!("({:.2}, {:.2})", 130.0 + 90.0 * a.cos(), 120.0 - 90.0 * a.sin()) }).collect::<Vec<_>>().join(" "));
    assert!(moves.len() == 12 && tipmaps == 12);                        // matrices against relabelled tips
    assert!(found == rules && rules.len() == 7);                        // brute force against the rules
    assert!(lattice == trace && lattice == vec![1, 2, 3, 4, 6]);         // whole-number matrices against the trace
    assert!(walls.len() == 17 && used == lattice[1..].to_vec());        // costs against the lattice
    println!("ALL CHECKS PASS");
}
