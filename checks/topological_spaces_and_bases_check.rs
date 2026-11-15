// Topological spaces and bases -- the check behind the card.  Rust std only.
// The circle of compass headings is cut into 48 pieces: 24 marks, one every 15 degrees
// (piece 2k is the heading 15k), and the 24 open gaps between them (piece 2k + 1).
// A set of pieces is a 48-bit integer, so every count below is exact.
use std::collections::{BTreeSet, HashSet};

const FULL: u64 = (1u64 << 48) - 1;

fn arc(a: i64, b: i64) -> u64 { // open arc: the headings strictly between a and b, going clockwise
    let (s, n) = (a.rem_euclid(360) / 15, (b - a).rem_euclid(360) / 15);
    let mut m = 0u64;
    for i in 0..n {
        m |= 1u64 << ((2 * (s + i) + 1) % 48); // a gap
        if i > 0 { m |= 1u64 << ((2 * (s + i)) % 48); } // a mark inside the arc
    }
    m
}
fn mark(h: i64) -> u64 { 1u64 << ((2 * (h / 15)) % 48) }
fn closed(a: i64, b: i64) -> u64 { arc(a, b) | mark(a) | mark(b) }

fn basis(step: i64, length: i64) -> Vec<u64> { // every open arc whose ends sit on the dial's marks
    let lengths: Vec<i64> = if length > 0 { vec![length] } else { (step..360).step_by(step as usize).collect() };
    let mut s = BTreeSet::new();
    for a in (0..360).step_by(step as usize) { for &l in &lengths { s.insert(arc(a, a + l)); } }
    s.into_iter().collect()
}
fn generate(b: &[u64]) -> HashSet<u64> { // road 1: every union of basis arcs, the empty union included
    let (mut opens, mut todo) = (HashSet::from([0u64]), vec![0u64]);
    while let Some(u) = todo.pop() {
        for &x in b { if opens.insert(u | x) { todo.push(u | x); } }
    }
    opens
}
fn lucas(n: u32) -> u64 { // road 2: walk round the n gaps; a mark between two kept gaps is kept or not
    let (mut a, mut b, mut c, mut d) = (1u64, 0u64, 0u64, 1u64); // M^n with M = [[1, 1], [1, 2]]
    for _ in 0..n { (a, b, c, d) = (a + b, a + 2 * b, c + d, c + 2 * d); }
    a + d
}
fn by_definition(step: i64) -> usize { // road 3: test every set of the dial's own pieces, one by one
    let (b, n) = (basis(step, 0), 360 / step);
    let mut pieces: Vec<u64> = (0..n).map(|j| mark(step * j)).collect();
    pieces.extend((0..n).map(|j| arc(step * j, step * (j + 1))));
    let mut count = 0;
    for pick in 0u64..(1u64 << (2 * n)) {
        let chosen: Vec<u64> = pieces.iter().enumerate().filter(|(i, _)| pick >> i & 1 == 1).map(|(_, &p)| p).collect();
        let u = chosen.iter().fold(0u64, |acc, &p| acc | p);
        // U is open when every piece in it has a basis arc round it lying inside U
        if chosen.iter().all(|&p| b.iter().any(|&x| p & x != 0 && x & !u == 0)) { count += 1; }
    }
    count
}
fn axioms(t: &HashSet<u64>, whole: u64) -> bool { // empty and whole set in; pairs' unions and intersections stay in
    t.contains(&0) && t.contains(&whole) && t.iter().all(|&u| t.iter().all(|&v| t.contains(&(u | v)) && t.contains(&(u & v))))
}
fn pieces_of(m: u64) -> usize { // how many separate arcs a set of pieces falls into
    (0..48).filter(|&i| m >> i & 1 == 1 && m >> ((i + 47) % 48) & 1 == 0).count()
}
fn finer(bf: &[u64], bc: &[u64]) -> bool { // basis test: round every point of every coarse arc, a fine arc inside it
    bc.iter().all(|&c| (0..48).filter(|&i| c >> i & 1 == 1).all(|i| bf.iter().any(|&b| b >> i & 1 == 1 && b & !c == 0)))
}
fn inside(m: u64, b: &[u64]) -> u64 { b.iter().filter(|&&x| x & !m == 0).fold(0, |u, &x| u | x) } // union of arcs inside m
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn main() {
    let (b90, b60, b45, b30, b15) = (basis(90, 0), basis(60, 0), basis(45, 0), basis(30, 0), basis(15, 0));
    let (t90, t60, t45, t30) = (generate(&b90), generate(&b60), generate(&b45), generate(&b30));
    println!("wrap: 330 and 30 are {} apart round the circle, {} along a ruler", (30 - 330i64).rem_euclid(360).min((330 - 30i64).rem_euclid(360)), 330 - 30);
    println!("dial      marks  basis arcs  by generation  by Lucas count  by definition");
    for (name, b, t, d) in [("90 deg", &b90, &t90, by_definition(90).to_string()), ("60 deg", &b60, &t60, by_definition(60).to_string()),
                            ("45 deg", &b45, &t45, by_definition(45).to_string()),
                            ("30 deg", &b30, &t30, "-".to_string())] {
        let n = 360 / name[..2].parse::<u32>().unwrap();
        println!("{:<9} {:>5}  {:>10}  {:>13}  {:>14}  {:>13}", name, n, b.len(), t.len(), lucas(n), d);
        assert!(t.len() as u64 == lucas(n) && (d == "-" || d == t.len().to_string()));
    }
    println!("15 deg       24  {:>10}  {:>13}  {:>14}  {:>13}", b15.len(), "-", lucas(24), "-");
    let mut by_hand = std::collections::BTreeMap::new(); // 90 deg dial by hand: each mark between two kept gaps doubles
    for g in 0u32..16 {
        let adj = (0..4).filter(|&i| g >> i & 1 == 1 && g >> ((i + 1) % 4) & 1 == 1).count() as u32;
        *by_hand.entry((g.count_ones(), 2u64.pow(adj))).or_insert(0u64) += 1;
    }
    let parts: Vec<String> = by_hand.iter().map(|(&(k, w), &n)| format!("{} kept {} way(s) x {}", k, n, w)).collect();
    println!("by hand, kept gaps: {}", parts.join("; "));
    let (mut m, mm) = ([[1u64, 0], [0, 1]], [[1u64, 1], [1, 2]]);
    for _ in 0..4 { m = [[m[0][0] * mm[0][0] + m[0][1] * mm[1][0], m[0][0] * mm[0][1] + m[0][1] * mm[1][1]],
                         [m[1][0] * mm[0][0] + m[1][1] * mm[1][0], m[1][0] * mm[0][1] + m[1][1] * mm[1][1]]]; }
    println!("M^4 = {} {} / {} {}, trace {}", m[0][0], m[0][1], m[1][0], m[1][1], m[0][0] + m[1][1]);
    let hand: u64 = by_hand.iter().map(|(&(_, w), &n)| n * w).sum();
    assert!(hand == m[0][0] + m[1][1] && hand == t90.len() as u64);

    let (ax90, ax45) = (axioms(&t90, FULL), axioms(&t45, FULL));
    println!("axioms on every pair: 90 deg dial {} ({} pairs), 45 deg dial {} ({} pairs)", py(ax90), t90.len().pow(2), py(ax45), t45.len().pow(2));
    assert!(ax90 && ax45);

    let pairs: Vec<(u64, u64)> = b30.iter().flat_map(|&b| b30.iter().map(move |&c| (b, c))).collect();
    let unions_ok = pairs.iter().filter(|&&(b, c)| inside(b & c, &b30) == b & c).count();
    let cover = b30.iter().fold(0u64, |u, &b| u | b);
    let two = pairs.iter().filter(|&&(b, c)| pieces_of(b & c) == 2).count();
    println!("30 deg basis: covers circle {}, pairs {}, overlap a union of arcs {}, two-piece overlaps {}", py(cover == FULL), pairs.len(), unions_ok, two);
    assert!(cover == FULL && unions_ok == pairs.len());

    let (a, b) = (arc(330, 210), arc(150, 30));
    println!("example: A=(330,210) B=(150,30) lengths {} {}, overlap pieces {} of 60 and 60, equals (330,30)+(150,210) {}", (210 - 330i64).rem_euclid(360), (30 - 150i64).rem_euclid(360), pieces_of(a & b), py(a & b == arc(330, 30) | arc(150, 210)));
    assert!(a & b == arc(330, 30) | arc(150, 210) && pieces_of(a & b) == 2);

    let (c90_30, c45_30, c30_45) = (t90.is_subset(&t30), t45.is_subset(&t30), t30.is_subset(&t45));
    let shared: HashSet<u64> = t45.intersection(&t30).copied().collect();
    println!("fineness by sets: 90 in 30 {}, 45 in 30 {}, 30 in 45 {}; shared by 45 and 30 {}, all of the 90-dial {}", py(c90_30), py(c45_30), py(c30_45), shared.len(), py(shared == t90));
    assert!(shared == t90);
    println!("fineness by basis test: 30 finer than 90 {}, 30 finer than 45 {}, 45 finer than 30 {}, 15 finer than both {}",
             py(finer(&b30, &b90)), py(finer(&b30, &b45)), py(finer(&b45, &b30)), py(finer(&b15, &b45) && finer(&b15, &b30)));
    assert!((c90_30, c45_30, c30_45) == (finer(&b30, &b90), finer(&b30, &b45), finer(&b45, &b30)) && (c90_30, c45_30, c30_45) == (true, false, false));
    println!("witnesses: (0,45) in 45-dial not 30-dial {}, (0,30) in 30-dial not 45-dial {}", py(!t30.contains(&arc(0, 45))), py(!t45.contains(&arc(0, 30))));

    let h = basis(30, 180);
    let th = generate(&h);
    let bad = th.iter().map(|&u| th.iter().filter(|&&v| !th.contains(&(u & v))).count()).sum::<usize>();
    println!("wrong: half-circles only: {} arcs, {} unions, axioms {}, failing pairs {}; (0,180)&(90,270) is (90,180) {}, in family {}",
             h.len(), th.len(), py(axioms(&th, FULL)), bad, py(arc(0, 180) & arc(90, 270) == arc(90, 180)), py(th.contains(&arc(90, 180))));
    assert!(bad > 0 && !th.contains(&arc(90, 180)));
    let p = closed(0, 90) & closed(90, 180);
    println!("wrong: closed arcs [0,90]&[90,180]: pieces {}, just the mark at 90 {}", p.count_ones(), py(p == mark(90)));
    assert!(p == mark(90));
    println!("wrong: count as fineness: 30 deg has {} sets, 45 deg {}, yet 45 in 30 is {}", t30.len(), t45.len(), py(c45_30));
    let pts: Vec<String> = [330.0f64, 30.0, 150.0, 210.0].iter()
        .map(|&h| format!("{}:{:.2},{:.2}", h as i64, 150.0 + 110.0 * h.to_radians().sin(), 150.0 - 110.0 * h.to_radians().cos())).collect();
    println!("figure,centre 150,150 radius 110 {}", pts.join(" "));
    let end = |r: f64, h: f64| format!("{:.2},{:.2}", 150.0 + r * h.to_radians().sin(), 150.0 - r * h.to_radians().cos());
    println!("figure,A radius 128 from {} to {}; B radius 92 from {} to {}", end(128.0, 330.0), end(128.0, 210.0), end(92.0, 150.0), end(92.0, 30.0));
    println!("ALL CHECKS PASS");
}
