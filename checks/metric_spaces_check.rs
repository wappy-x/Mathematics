// Metric space -- the same check as metric_spaces_check.py, in Rust, std only.
// A corner of the city grid is (east, north), counted in blocks from home.
// Every candidate returns the SQUARE of its distance as a whole number, so a
// root is never rounded: sqrt(A) <= sqrt(B) + sqrt(C) is tested exactly.
// Compile: rustc --edition 2021 -O metric_spaces_check.rs -o /tmp/metric_spaces
use std::collections::HashMap;
type P = (i64, i64);
const HOME: P = (0, 0);
const CAFE: P = (3, 4);
const ANA: i64 = 7;
const BEN: i64 = 3;

fn walk(p: P, q: P) -> i64 { (p.0 - q.0).abs() + (p.1 - q.1).abs() }
fn line2(p: P, q: P) -> i64 { (p.0 - q.0).pow(2) + (p.1 - q.1).pow(2) }
fn isqrt(s: i64) -> i64 {
    let mut r = 0;
    while (r + 1) * (r + 1) <= s { r += 1; }
    r
}
fn show(s: i64) -> String {
    let r = isqrt(s);
    if r * r == s { r.to_string() } else { format!("sqrt({})", s) }
}
fn le_root(a: i64, b: i64, c: i64) -> bool { let t = a - b - c; t <= 0 || t * t <= 4 * b * c }
fn eq_root(a: i64, b: i64, c: i64) -> bool { let t = a - b - c; t >= 0 && t * t == 4 * b * c }
fn lab(p: P, lp: bool) -> String {
    if lp { ["A", "B", "C", "D"][p.0 as usize].to_string() } else { format!("({}, {})", p.0, p.1) }
}

type R = (Option<(P, P)>, Option<(P, P)>, Option<(P, P, P)>);
fn rules(pts: &[P], d2: &dyn Fn(P, P) -> i64) -> R {
    let (mut r1, mut r2, mut r3) = (None, None, None);
    for &x in pts { for &y in pts {
        if r1.is_none() && (d2(x, y) == 0) != (x == y) { r1 = Some((x, y)); }
        if r2.is_none() && d2(x, y) != d2(y, x) { r2 = Some((x, y)); }
    } }
    'o: for &x in pts { for &z in pts { for &y in pts {
        if !le_root(d2(x, z), d2(x, y), d2(y, z)) { r3 = Some((x, y, z)); break 'o; }
    } } }
    (r1, r2, r3)
}

fn gaps(a: i64, b: i64) -> (usize, usize, i64, i64) {
    let mut bx = vec![];
    for e in -10..=10 { for n in -10..=10 { bx.push((e, n)); } }
    let at_a: Vec<P> = bx.iter().cloned().filter(|&p| walk(p, (0, 0)) == a).collect();
    let at_b: Vec<P> = bx.iter().cloned().filter(|&p| walk(p, (0, 0)) == b).collect();
    let g: Vec<i64> = at_a.iter().flat_map(|&p| at_b.iter().map(move |&q| walk(p, q))).collect();
    (at_a.len(), at_b.len(), *g.iter().min().unwrap(), *g.iter().max().unwrap())
}
fn fact(k: i64) -> i64 { if k == 0 { 1 } else { k * fact(k - 1) } }

fn main() {
    let mut grid: Vec<P> = vec![];
    for e in 0..6 { for n in 0..6 { grid.push((e, n)); } }
    let lp: Vec<P> = (0..4).map(|i| (i, 0)).collect();
    println!("home {} to cafe {}: walk {} blocks, straight line {} blocks; at 100 m a block, {} m against {} m",
             lab(HOME, false), lab(CAFE, false), walk(HOME, CAFE), show(line2(HOME, CAFE)),
             100 * walk(HOME, CAFE), 100 * isqrt(line2(HOME, CAFE)));
    let mut routes: HashMap<P, i64> = HashMap::new(); // road 1: routes corner by corner
    for e in 0..4 { for n in 0..5 {
        let v = if e == 0 || n == 0 { 1 } else { routes[&(e - 1, n)] + routes[&(e, n - 1)] };
        routes.insert((e, n), v);
    } }
    let binom = fact(7) / (fact(3) * fact(4));
    println!("shortest walking routes: {} counted, {} by 7!/(3!4!)", routes[&(3, 4)], binom);
    let free_w = grid.iter().filter(|&&y| walk(HOME, y) + walk(y, CAFE) == walk(HOME, CAFE)).count();
    let free_l = grid.iter().filter(|&&y| eq_root(line2(HOME, CAFE), line2(HOME, y), line2(y, CAFE))).count();
    println!("corners on the way at no extra cost: walk {}, straight line {}", free_w, free_l);

    let mut same = true; // road 2: walking distance by breadth-first search
    for &s in &grid {
        let mut seen: HashMap<P, i64> = HashMap::new();
        seen.insert(s, 0);
        let (mut frontier, mut k) = (vec![s], 0);
        while !frontier.is_empty() {
            k += 1;
            let mut nxt = vec![];
            for &(e, n) in &frontier {
                for q in [(e + 1, n), (e - 1, n), (e, n + 1), (e, n - 1)] {
                    if grid.contains(&q) && !seen.contains_key(&q) { seen.insert(q, k); nxt.push(q); }
                }
            }
            frontier = nxt;
        }
        for &q in &grid { if seen[&q] != walk(s, q) { same = false; } }
    }
    println!("search on the street graph equals the block formula on all {} pairs of the {} corners: {}",
             grid.len() * grid.len(), grid.len(), if same { "yes" } else { "no" });

    let walk2 = |p: P, q: P| walk(p, q).pow(2);
    let sq = |p: P, q: P| line2(p, q).pow(2);
    let ew = |p: P, q: P| (p.0 - q.0).pow(2);
    let drive2 = |p: P, q: P| (q.0 - p.0).rem_euclid(4).pow(2);
    let cap = |p: P, q: P| walk(p, q).min(3).pow(2);
    let cands: Vec<(&str, &Vec<P>, &dyn Fn(P, P) -> i64, bool)> = vec![
        ("walking distance", &grid, &walk2, false),
        ("straight line", &grid, &line2, false),
        ("straight line squared", &grid, &sq, false),
        ("east-west blocks only", &grid, &ew, false),
        ("one-way driving", &lp, &drive2, true),
        ("try: root of walking", &grid, &walk, false),
        ("try: flat fare, cap 3", &grid, &cap, false),
    ];
    let mut passes = vec![];
    let mut sq_fail = None;
    for (name, pts, d2, l) in &cands {
        let (r1, r2, r3) = rules(pts, *d2);
        let ok = r1.is_none() && r2.is_none() && r3.is_none();
        passes.push(ok);
        if *name == "straight line squared" { sq_fail = r3; }
        println!("{}: {} triples, {}", name, pts.len().pow(3), if ok { "a metric" } else { "NOT a metric" });
        if let Some((x, y)) = r1 {
            println!("  rule 1 fails: {} and {} are {} apart", lab(x, *l), lab(y, *l), show(d2(x, y)));
        }
        if let Some((x, y)) = r2 {
            println!("  rule 2 fails: {} to {} is {}, back is {}", lab(x, *l), lab(y, *l),
                     show(d2(x, y)), show(d2(y, x)));
        }
        if let Some((x, y, z)) = r3 {
            println!("  rule 3 fails: {} to {} is {}, via {} is {} + {}", lab(x, *l), lab(z, *l),
                     show(d2(x, z)), lab(y, *l), show(d2(x, y)), show(d2(y, z)));
        }
    }

    let dr = |p: P, q: P| isqrt(drive2(p, q)); // one-way loop: does the lower bound survive?
    let mut lb = None;
    'l: for &x in &lp { for &y in &lp { for &z in &lp {
        if (dr(x, y) - dr(y, z)).abs() > dr(x, z) { lb = Some((x, y, z)); break 'l; }
    } } }
    let (bx, by, bz) = lb.unwrap();
    println!("one-way lower bound fails: {} to {} is {}, {} to {} is {}, so {} to {} is at least {}, yet it is {}",
             lab(bx, true), lab(by, true), dr(bx, by), lab(by, true), lab(bz, true), dr(by, bz),
             lab(bx, true), lab(bz, true), (dr(bx, by) - dr(by, bz)).abs(), dr(bx, bz));

    let (na, nb, lo, hi) = gaps(ANA, BEN);
    println!("Ana {}, Ben {} blocks from the park: bound {} to {} blocks, {} m to {} m", ANA, BEN,
             (ANA - BEN).abs(), ANA + BEN, 100 * (ANA - BEN).abs(), 100 * (ANA + BEN));
    println!("  brute force over {} x {} = {} placings: {} to {}", na, nb, na * nb, lo, hi);
    let (_, _, tlo, thi) = gaps(ANA, 7);
    println!("try: Ben also 7 out: bound {} to {}, brute force {} to {}", (ANA - 7).abs(), ANA + 7, tlo, thi);
    println!("wrong: bound without the bars, {} - {} = {}", BEN, ANA, BEN - ANA);
    println!("wrong: the sum read as the answer, {}; the truth can be {}", ANA + BEN, lo);
    println!("figure, 1 block = 60 units: home (60, 360), turn (240, 360), cafe (240, 120)");

    assert!(routes[&(3, 4)] == binom && binom == 35); // two roads to 35
    assert!(same && walk(HOME, CAFE) == 7 && line2(HOME, CAFE) == 25);
    assert_eq!((free_w, free_l), (20, 2));
    assert_eq!(passes, vec![true, true, false, false, false, true, true]);
    assert_eq!(sq_fail, Some(((0, 0), (0, 1), (0, 2))));
    assert!(lb == Some(((0, 0), (1, 0), (0, 0))) && (dr((0, 0), (1, 0)), dr((1, 0), (0, 0))) == (1, 3));
    assert!((lo, hi) == ((ANA - BEN).abs(), ANA + BEN) && (tlo, thi) == (0, 14));
    println!("ALL CHECKS PASS");
}
