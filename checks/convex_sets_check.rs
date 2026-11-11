// Convex sets: the three-bean blends costing at most £9 a kilo.  No crates.
use std::fmt;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q(i64, i64);                                  // an exact fraction, bottom kept positive
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> std::cmp::Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { Some(self.cmp(o)) } }
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result { if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) } }
}
fn z(n: i64) -> Q { q(n, 1) }
fn fl(x: Q) -> f64 { x.0 as f64 / x.1 as f64 }
type V = [Q; 3];
type Wall = ([i64; 3], i64, &'static str);           // a . x <= b, x = shares (Robusta, Brazil, Ethiopian)
const PRICE: [i64; 3] = [6, 8, 14];                  // £ a kilo
const WALLS: [Wall; 4] = [([-1, 0, 0], 0, "no Robusta"), ([0, -1, 0], 0, "no Brazil"),
    ([0, 0, -1], 0, "no Ethiopian"), (PRICE, 9, "cost 9")];
const SUM: Wall = ([1, 1, 1], 1, "sum 1");          // the shares add to 1: a wall that must hold exactly
fn dot(a: [i64; 3], x: V) -> Q { (0..3).fold(z(0), |s, i| s + z(a[i]) * x[i]) }
fn show(x: V) -> String { format!("({}, {}, {})", x[0], x[1], x[2]) }
fn solve(rows: &[([Q; 3], Q)]) -> Option<V> {        // three walls held tight: elimination, exact fractions
    let mut m: Vec<Vec<Q>> = rows.iter().map(|(a, b)| vec![a[0], a[1], a[2], *b]).collect();
    for c in 0..3 {
        let p = (c..3).find(|&r| m[r][c] != z(0))?;  // None: the walls do not meet in a single point
        m.swap(c, p);
        for r in 0..3 { if r != c { let f = m[r][c] / m[c][c]; for k in 0..4 { m[r][k] = m[r][k] - f * m[c][k] } } }
    }
    Some([m[0][3] / m[0][0], m[1][3] / m[1][1], m[2][3] / m[2][2]])
}
fn combos(n: usize, k: usize) -> Vec<Vec<usize>> {
    if k == 0 { return vec![vec![]] }
    (0..n).flat_map(|i| combos(n, k - 1).into_iter().filter(move |c| c.iter().all(|&j| j > i)).map(move |c| [vec![i], c].concat())).collect()
}
fn corners(walls: &[Wall], eqs: &[Wall], log: &mut Vec<String>) -> Vec<V> { // road one: every choice of three tight walls
    let mut found: Vec<V> = Vec::new();
    for pick in combos(walls.len(), 3 - eqs.len()) {
        let rows: Vec<Wall> = pick.iter().map(|&i| walls[i]).chain(eqs.iter().copied()).collect();
        let x = solve(&rows.iter().map(|w| (w.0.map(z), z(w.1))).collect::<Vec<_>>());
        let good = x.map_or(false, |x| walls.iter().all(|w| dot(w.0, x) <= z(w.1)));
        let names = pick.iter().map(|&i| walls[i].2).collect::<Vec<_>>().join(" + ");
        log.push(match x { None => format!("{}: no single point", names),
            Some(x) => format!("{}: {} cost {} -> {}", names, show(x), dot(PRICE, x), if good { "corner" } else { "outside" }) });
        if good && !found.contains(&x.unwrap()) { found.push(x.unwrap()) }
    }
    found
}
type P = (Q, Q);
fn turn(a: P, b: P, c: P) -> Q { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) }
fn hull(mut pts: Vec<P>) -> Vec<P> {                 // monotone chain on (Robusta, Brazil); anticlockwise
    pts.sort(); pts.dedup();
    let mut out = Vec::new();
    for seq in [pts.clone(), pts.iter().rev().copied().collect()] {
        let mut h: Vec<P> = Vec::new();
        for &p in &seq {
            while h.len() >= 2 && turn(h[h.len() - 2], h[h.len() - 1], p) <= z(0) { h.pop(); }
            h.push(p);
        }
        h.pop(); out.extend(h);
    }
    out
}
fn area(h: &[P]) -> Q { (0..h.len()).fold(z(0), |s, i| s + turn((z(0), z(0)), h[(i + h.len() - 1) % h.len()], h[i])) / z(2) }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    let mut log = Vec::new();
    let c = corners(&WALLS, &[SUM], &mut log);
    println!("road one, three walls tight at a time:");
    for l in &log { println!("  {}", l) }
    let n: i64 = 24;                                 // road two: every blend in 24ths, then its hull
    let grid: Vec<[i64; 3]> = (0..=n).flat_map(|i| (0..=n - i).map(move |j| [i, j, n - i - j])).collect();
    let good: Vec<[i64; 3]> = grid.iter().copied().filter(|g| (0..3).map(|k| PRICE[k] * g[k]).sum::<i64>() <= 9 * n).collect();
    let h: Vec<V> = hull(good.iter().map(|g| (z(g[0]), z(g[1]))).collect()).iter().map(|p| [p.0 / z(n), p.1 / z(n), z(1) - (p.0 + p.1) / z(n)]).collect();
    println!("road two: {} of {} blends in 24ths pass; their hull has corners {}", good.len(), grid.len(), h.iter().map(|&x| show(x)).collect::<Vec<_>>().join(" "));
    let (mut pairs, mut inside) = (0, 0);
    for i in 0..good.len() { for y in &good[i + 1..] { let x = good[i]; pairs += 1;
        if (1..10).all(|k| (0..3).map(|m| PRICE[m] * ((10 - k) * x[m] + k * y[m])).sum::<i64>() <= 90 * n) { inside += 1 } } }
    println!("segment test: {} pairs, 9 points on each, pairs staying inside: {}", pairs, inside);
    let a = area(&h.iter().map(|x| (x[0], x[1])).collect::<Vec<_>>());
    let m = 480;
    let tri: Vec<(f64, f64)> = (0..m).flat_map(|i| (0..m - i).map(move |j| (i as f64 + 0.5, j as f64 + 0.5))).collect(); // cell centres in the triangle
    let cells = tri.iter().filter(|&&(r, b)| 8.0 * r + 6.0 * b >= 5.0 * m as f64).count() as f64 / tri.len() as f64;
    println!("area of the passing set 1/2 - {} = {} of the triangle's 1/2: {:.1}%; fine grid, {} cell centres: {:.1}%", q(1, 2) - a, a, fl(z(2) * a) * 100.0, tri.len(), cells * 100.0);
    let pc = |r, b, e| [q(r, 100), q(b, 100), q(e, 100)];
    let blend: [(&str, V); 5] = [("Dark", pc(50, 50, 0)), ("Espresso", pc(60, 30, 10)), ("Bright", pc(50, 20, 30)), ("Breakfast", pc(20, 70, 10)), ("House", pc(40, 40, 20))];
    for (k, x) in &blend { println!("{}: shares {}, £{:.2} a kilo", k, show(*x), fl(dot(PRICE, *x))) }
    let name = |p: P| blend.iter().find(|b| (b.1[0], b.1[1]) == p).unwrap().0;
    let h5: Vec<&str> = hull(blend.iter().map(|b| (b.1[0], b.1[1])).collect()).into_iter().map(name).collect();
    println!("hull of the five blends: {}; House inside: {}", h5.join(" "), tf(!h5.contains(&"House")));
    let (d, bt, bk, ho) = (blend[0].1, blend[2].1, blend[3].1, blend[4].1);
    let mix: Vec<[i64; 3]> = (0..7).flat_map(|i| (0..7 - i).map(move |j| [i, j, 6 - i - j])).collect();
    let vals: Vec<Q> = mix.iter().map(|w| dot(PRICE, [0, 1, 2].map(|k| (z(w[0]) * d[k] + z(w[1]) * bt[k] + z(w[2]) * bk[k]) / z(6)))).collect();
    println!("{} tip-togethers of Dark, Bright, Breakfast in sixths: £{:.2} to £{:.2}", mix.len(), fl(*vals.iter().min().unwrap()), fl(*vals.iter().max().unwrap()));
    let w = solve(&[([d[0], bt[0], bk[0]], ho[0]), ([d[1], bt[1], bk[1]], ho[1]), ([z(1), z(1), z(1)], z(1))]).unwrap();
    let rebuilt: V = [0, 1, 2].map(|k| w[0] * d[k] + w[1] * bt[k] + w[2] * bk[k]);
    println!("House = {} Dark + {} Bright + {} Breakfast: shares {}, cost {:.2} = {:.2}", w[0], w[1], w[2], show(rebuilt),
        fl(dot(PRICE, rebuilt)), fl(w[0] * dot(PRICE, d) + w[1] * dot(PRICE, bt) + w[2] * dot(PRICE, bk)));
    let rule = |x: V| x.iter().all(|&s| s == z(0) || s >= q(3, 10));
    let (p, r) = ([q(7, 10), q(3, 10), z(0)], [q(7, 10), z(0), q(3, 10)]);
    let mid: V = [0, 1, 2].map(|k| (p[k] + r[k]) / z(2));
    println!("30% rule: {} £{:.2} {}, {} £{:.2} {}, midpoint {} £{:.2} {}", show(p), fl(dot(PRICE, p)), tf(rule(p)),
        show(r), fl(dot(PRICE, r)), tf(rule(r)), show(mid), fl(dot(PRICE, mid)), tf(rule(mid)));
    let g30: Vec<[i64; 3]> = good.iter().copied().filter(|g| rule(g.map(|s| q(s, n)))).collect();
    let mut bad = 0;
    for i in 0..g30.len() { for y in &g30[i + 1..] { if !rule([0, 1, 2].map(|k| q(g30[i][k] + y[k], 2 * n))) { bad += 1 } } }
    println!("30% rule on the grid: {} blends pass both rules; pairs whose midpoint breaks the rule: {}", g30.len(), bad);
    let free = corners(&WALLS, &[], &mut Vec::new());
    println!("mistake, no sum-to-1 wall: corners {}; cheapest point £{}", free.iter().map(|&x| show(x)).collect::<Vec<_>>().join(" "),
        free.iter().map(|&x| dot(PRICE, x)).min().unwrap());
    println!("mistake, corners taken as the passing pure beans: hull of (1, 0, 0) and (0, 1, 0), area {:.1}; House has Ethiopian share {}, so it is left out",
        fl(area(&hull(vec![(z(1), z(0)), (z(0), z(1))]))), ho[2]);
    let strong: Wall = ([24, 12, 12], 18, "caffeine 1.8%"); // caffeine in tenths of a percent: 2.4, 1.2, 1.2
    let c2 = corners(&[WALLS.to_vec(), vec![strong]].concat(), &[SUM], &mut Vec::new());
    println!("try: add caffeine at most 1.8%: {} corners {}", c2.len(), c2.iter().map(|&x| show(x)).collect::<Vec<_>>().join(" "));
    let fig = |x: V| format!("({:.1}, {:.1})", 95.0 + 200.0 * fl(x[0]), 230.0 - 200.0 * fl(x[1]));
    println!("figure, 1 share = 200: corners {}; blends {}", c.iter().map(|&x| fig(x)).collect::<Vec<_>>().join(" "),
        blend.iter().map(|(k, x)| format!("{} {}", k, fig(*x))).collect::<Vec<_>>().join(" "));
    let (mut cs, mut hs) = (c.clone(), h.clone());
    cs.sort(); hs.sort();
    assert!(cs == hs);                                       // walls against the grid's hull
    assert!(inside == pairs && c.len() == 4);                // no segment leaves the set
    assert!(w.iter().all(|&x| x > z(0)) && rebuilt == ho);   // House really is a mix of the three
    assert!((cells - fl(z(2) * a)).abs() < 0.005);           // area: shoelace against counting
    assert!(rule(p) && rule(r) && !rule(mid) && bad > 0);    // the 30% rule dents the set
    println!("ALL CHECKS PASS");
}
