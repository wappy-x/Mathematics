// Integer programs and relaxations: the festival's headliners h and smaller acts t.
// Maximise tickets 5500h + 1000t with fees 60h + 5t <= 290 (in £k) and stage
// hours 4h + 2t <= 24, h and t whole. Exact fractions throughout.
use std::cmp::Ordering;

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q { n: i64, d: i64 }       // a fraction n/d, d > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q {
    let g = gcd(n, d).max(1); let s = if d < 0 { -1 } else { 1 };
    Q { n: s * n / g, d: s * d / g }
}
fn z(n: i64) -> Q { q(n, 1) }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }

type Row = (i64, i64, i64);       // a*h + b*t <= r
type P2 = (Q, Q);
const C: (i64, i64) = (5500, 1000);
const BUDGET: Row = (60, 5, 290);
const HOURS: Row = (4, 2, 24);
const SIGNS: [Row; 2] = [(-1, 0, 0), (0, -1, 0)];

fn show(x: Q) -> String {          // exact fraction -> decimal text, at most 2 places
    let n = (x.n.abs() * 100 * 2 + x.d) / (2 * x.d);
    let frac = format!(".{:02}", n % 100);
    let frac = frac.trim_end_matches('0').trim_end_matches('.');
    format!("{}{}{}", if x.n < 0 { "-" } else { "" }, n / 100, frac)
}
fn pt(p: P2) -> String { format!("({}, {})", show(p.0), show(p.1)) }
fn tickets(p: P2) -> Q { z(C.0) * p.0 + z(C.1) * p.1 }
fn obeys(rows: &[Row], p: P2) -> bool { rows.iter().all(|&(a, b, r)| z(a) * p.0 + z(b) * p.1 <= z(r)) }

fn corners(rows: &[Row]) -> Vec<P2> {   // every crossing of two limits that obeys all limits
    let mut out: Vec<P2> = Vec::new();
    for i in 0..rows.len() {
        for j in i + 1..rows.len() {
            let ((a1, b1, r1), (a2, b2, r2)) = (rows[i], rows[j]);
            let det = a1 * b2 - a2 * b1;
            if det == 0 { continue; }
            let p = (q(r1 * b2 - r2 * b1, det), q(a1 * r2 - a2 * r1, det));
            if obeys(rows, p) && !out.contains(&p) { out.push(p); }
        }
    }
    out.sort(); out
}
fn relax(rows: &[Row]) -> (Q, P2) {     // the LP relaxation: best corner (road 1)
    let mut best = corners(rows)[0];
    for p in corners(rows) { if tickets(p) > tickets(best) { best = p; } }
    (tickets(best), best)
}
fn whole_plans(rows: &[Row]) -> Vec<(i64, i64)> {   // road 3: list every whole plan
    let mut v = Vec::new();
    for h in 0..30 { for t in 0..30 { if obeys(rows, (z(h), z(t))) { v.push((h, t)); } } }
    v
}
fn wt(p: (i64, i64)) -> i64 { C.0 * p.0 + C.1 * p.1 }
fn hull(points: &[(i64, i64)]) -> Vec<(i64, i64)> {   // convex hull, monotone chain
    let mut pts = points.to_vec(); pts.sort(); pts.dedup();
    let cross = |o: (i64, i64), a: (i64, i64), b: (i64, i64)| (a.0 - o.0) * (b.1 - o.1) - (a.1 - o.1) * (b.0 - o.0);
    let (mut lower, mut upper): (Vec<(i64, i64)>, Vec<(i64, i64)>) = (vec![], vec![]);
    for &p in pts.iter() {
        while lower.len() >= 2 && cross(lower[lower.len() - 2], lower[lower.len() - 1], p) <= 0 { lower.pop(); }
        lower.push(p);
    }
    for &p in pts.iter().rev() {
        while upper.len() >= 2 && cross(upper[upper.len() - 2], upper[upper.len() - 1], p) <= 0 { upper.pop(); }
        upper.push(p);
    }
    lower.pop(); upper.pop(); lower.extend(upper); lower.sort(); lower
}
fn zp(p: (i64, i64)) -> P2 { (z(p.0), z(p.1)) }
fn down(x: Q) -> i64 { x.n.div_euclid(x.d) }   // round down to a whole number
fn join(v: &[P2]) -> String { v.iter().map(|&p| pt(p)).collect::<Vec<_>>().join(" ") }

fn main() {
    let p_rows: Vec<Row> = vec![BUDGET, HOURS, SIGNS[0], SIGNS[1]];
    println!("corners of the relaxed region P, with tickets:");
    for p in corners(&p_rows) { println!("  h, t = {}  tickets {}", pt(p), show(tickets(p))); }
    let (z_lp, x_lp) = relax(&p_rows);
    println!("relaxation: best corner {} = {} acts, tickets {}", pt(x_lp), show(x_lp.0 + x_lp.1), show(z_lp));
    println!("  fees {} of 290; hours {} of 24", show(z(60) * x_lp.0 + z(5) * x_lp.1), show(z(4) * x_lp.0 + z(2) * x_lp.1));

    // Road 2: prices y on the budget and the hours, from the two tight limits.
    let det = BUDGET.0 * HOURS.1 - HOURS.0 * BUDGET.1;
    let y1 = q(C.0 * HOURS.1 - HOURS.0 * C.1, det);
    let y2 = q(BUDGET.0 * C.1 - C.0 * BUDGET.1, det);
    let bound = y1 * z(BUDGET.2) + y2 * z(HOURS.2);
    println!("prices: y1 = {} tickets per £1k, y2 = {} tickets per hour", show(y1), show(y2));
    println!("  covers a headliner: {} >= 5500; a smaller act: {} >= 1000", show(z(60) * y1 + z(4) * y2), show(z(5) * y1 + z(2) * y2));
    println!("  price bound 290 x {} + 24 x {} = {}", show(y1), show(y2), show(bound));
    assert!(y1 >= z(0) && y2 >= z(0) && z(60) * y1 + z(4) * y2 >= z(C.0) && z(5) * y1 + z(2) * y2 >= z(C.1));
    assert!(bound == z_lp);                // certificate meets the corner search

    let s = whole_plans(&p_rows);
    let z_ip = s.iter().map(|&p| wt(p)).max().unwrap();
    let best: Vec<(i64, i64)> = s.iter().cloned().filter(|&p| wt(p) == z_ip).collect();
    println!("whole plans: {}; best {} = {} acts, tickets {}", s.len(), pt(zp(best[0])), best[0].0 + best[0].1, z_ip);
    println!("  fees {} of 290; hours {} of 24", 60 * best[0].0 + 5 * best[0].1, 4 * best[0].0 + 2 * best[0].1);
    assert!(best.len() == 1 && z_lp >= z(z_ip));
    let gap = z_lp - z(z_ip);
    println!("integrality gap: {} tickets = {}%", show(gap), show(z(100) * gap / z(z_ip)));

    let h: Vec<P2> = hull(&s).into_iter().map(zp).collect();
    println!("corners of conv S: {}", join(&h));
    assert!(s.iter().all(|p| p.0 <= 4));   // the listing agrees: no whole plan has 5 headliners
    println!("five headliners cost {} > {}, so every whole plan has h <= 4", BUDGET.0 * 5, BUDGET.2);
    let mut tight = p_rows.clone(); tight.push((1, 0, 4));   // at most 4 headliners: 5 would cost £300k
    assert!(corners(&tight) == h);         // inequalities give the hull
    let z_hull = h.iter().map(|&p| tickets(p)).max().unwrap();
    println!("formulations, same whole plans, different bounds:");
    let loose: Vec<Row> = vec![BUDGET, (4, 2, 25), SIGNS[0], SIGNS[1]];   // licence written as 25 hours
    let (z_loose, x_loose) = relax(&loose);
    assert!(whole_plans(&loose) == s);
    for (name, zz, x) in [("25-hour licence", z_loose, x_loose), ("as written, 24 hours", z_lp, x_lp),
                          ("plus h <= 4 (= conv S)", relax(&tight).0, relax(&tight).1)] {
        println!("  {:<23} bound {:>8} at {:<12} gap {}%", name, show(zz), pt(x), show(z(100) * (zz - z(z_ip)) / z(z_ip)));
    }
    assert!(z_hull == z(z_ip) && relax(&tight).0 == z(z_ip) && z_loose > z_lp);

    println!("what breaks:");
    let up = (down(x_lp.0 + q(1, 2)), down(x_lp.1 + q(1, 2)));   // the relaxed corner rounded to nearest
    let fee_up = BUDGET.0 * up.0 + BUDGET.1 * up.1;
    println!("  round {}, {} to nearest {}: fees {} > {}, not allowed", show(x_lp.0), show(x_lp.1), pt(zp(up)), fee_up, BUDGET.2);
    let dn = (down(x_lp.0), down(x_lp.1));   // rounded down
    println!("  round down to {}: tickets {}, {} short of best", pt(zp(dn)), wt(dn), z_ip - wt(dn));
    println!("  read the bound as the answer: promises {} tickets no plan sells", show(gap));
    let mut capped = p_rows.clone(); capped.push((1, 1, 7));
    let cap7 = whole_plans(&capped);
    let z7 = cap7.iter().map(|&p| wt(p)).max().unwrap();
    let b7 = *cap7.iter().find(|&&p| wt(p) == z7).unwrap();
    println!("  add the false cap h + t <= 7: best {}, tickets {}", pt(zp(b7)), z7);
    let mut most = corners(&p_rows)[0];
    for p in corners(&p_rows) { if p.0 + p.1 > most.0 + most.1 { most = p; } }
    println!("  (most acts anywhere in P: {}, at {})", show(most.0 + most.1), pt(most));
    assert!(fee_up > BUDGET.2);           // rounding to nearest breaks the budget
    assert!(wt(dn) < z_ip && z7 < z_ip);
    println!("figure, P {}; conv S {}; LP {}; best {}", join(&corners(&p_rows)), join(&h), pt(x_lp), pt(zp(best[0])));
    println!("ALL CHECKS PASS");
}
