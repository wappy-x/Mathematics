// Krein-Milman: find the corners of a transport plan's feasible set and rebuild a plan
// from them.  No crates; a small fraction type keeps every plan exact.  Two depots (30 and
// 20 pallets) ship to three shops (15, 25 and 10).  A plan is fixed by u = depot 1 -> shop 1
// and v = depot 1 -> shop 2; the other four entries follow from the totals.
use std::cmp::Ordering;
use std::collections::BTreeMap;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q { n: i64, d: i64 }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i64) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
fn fr(x: Q) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }
type P = (Q, Q);
fn pt(p: P) -> String { format!("({}, {})", fr(p.0), fr(p.1)) }
const ROWS: [(i64, i64, i64); 6] = [(1, 0, 0), (0, 1, 0), (-1, -1, 30), (-1, 0, 15), (0, -1, 25), (1, 1, -20)];
const COST: [i64; 6] = [4, 6, 9, 5, 3, 7];
fn entries(p: P) -> Vec<Q> { ROWS.iter().map(|&(a, b, c)| z(a) * p.0 + z(b) * p.1 + z(c)).collect() }
fn feasible(p: P) -> bool { entries(p).iter().all(|&e| e >= z(0)) }
fn cost(p: P) -> Q { entries(p).iter().zip(COST.iter()).fold(z(0), |s, (&e, &c)| s + z(c) * e) }
fn row(p: P, r: usize) -> String {
    let e = entries(p);
    format!("[{}]", e[3 * r..3 * r + 3].iter().map(|&x| fr(x)).collect::<Vec<_>>().join(", "))
}
fn peel(x: P, corners: &Vec<P>) -> BTreeMap<P, Q> { // the proof of Minkowski's theorem, run
    let mut out = BTreeMap::new();
    if corners.contains(&x) { out.insert(x, z(1)); return out; }
    let ex = entries(x);
    let face: Vec<P> = corners.iter().cloned()
        .filter(|&c| (0..6).all(|k| ex[k] != z(0) || entries(c)[k] == z(0))).collect();
    let v = face[0];
    let d = (x.0 - v.0, x.1 - v.1);
    let mut t: Option<Q> = None; // walk from v through x until a limit binds
    for (&e, &(a, b, _)) in entries(v).iter().zip(ROWS.iter()) {
        let rate = z(a) * d.0 + z(b) * d.1;
        if rate < z(0) { let s = e / (z(0) - rate); if t.map_or(true, |m| s < m) { t = Some(s) } }
    }
    let t = t.unwrap();
    let y = (v.0 + t * d.0, v.1 + t * d.1);
    for (c, w) in peel(y, &face) { out.insert(c, w / t); }
    let old = *out.get(&v).unwrap_or(&z(0));
    out.insert(v, old + z(1) - z(1) / t);
    out
}
fn bary(p: P, a: P, b: P, c: P) -> Option<[Q; 3]> {
    let det = (b.0 - a.0) * (c.1 - a.1) - (c.0 - a.0) * (b.1 - a.1);
    if det == z(0) { return None; }
    let wb = ((p.0 - a.0) * (c.1 - a.1) - (c.0 - a.0) * (p.1 - a.1)) / det;
    let wc = ((b.0 - a.0) * (p.1 - a.1) - (p.0 - a.0) * (b.1 - a.1)) / det;
    Some([z(1) - wb - wc, wb, wc])
}

fn main() {
    // road 1: a corner is where two limits bind -- intersect every pair of zero-lines
    let mut corners: Vec<P> = Vec::new();
    for i in 0..6 { for j in i + 1..6 {
        let ((a1, b1, c1), (a2, b2, c2)) = (ROWS[i], ROWS[j]);
        let det = a1 * b2 - a2 * b1;
        if det != 0 {
            let p = (q(-c1 * b2 + c2 * b1, det), q(-a1 * c2 + a2 * c1, det));
            if feasible(p) && !corners.contains(&p) { corners.push(p) }
        }
    } }
    corners.sort();
    // road 2: test every whole-pallet plan: a corner is not the midpoint of two other plans
    let dirs = [(1, 0), (0, 1), (1, -1), (1, 1)];
    let plans: Vec<P> = (0..16).flat_map(|u| (0..26).map(move |v| (z(u), z(v)))).filter(|&p| feasible(p)).collect();
    let road2: Vec<P> = plans.iter().cloned().filter(|&p| !dirs.iter().any(|&(a, b)|
        feasible((p.0 + q(a, 2), p.1 + q(b, 2))) && feasible((p.0 - q(a, 2), p.1 - q(b, 2))))).collect();
    let edge = plans.iter().filter(|&&p| entries(p).contains(&z(0))).count();
    assert!(road2 == corners && corners.len() == 5);
    println!("whole-pallet plans {}, on the boundary {}, corners {}, dimension (2-1)(3-1) = 2", plans.len(), edge, corners.len());
    for &c in &corners {
        println!("corner {}: depot 1 sends {}, depot 2 sends {}, cost {}", pt(c), row(c, 0), row(c, 1), fr(cost(c)));
    }
    let best = plans.iter().map(|&p| cost(p)).min().unwrap();
    assert!(best == corners.iter().map(|&c| cost(c)).min().unwrap() && best == z(240));

    let x: P = (q(30 * 15, 50), q(30 * 25, 50)); // proportional plan: a_i b_j / 50
    let w = peel(x, &corners);
    println!("proportional plan {}: depot 1 sends {}, depot 2 sends {}, cost {}", pt(x), row(x, 0), row(x, 1), fr(cost(x)));
    let (v0, y) = (corners[0], (z(15), q(35, 3))); // the stop, checked: on the line, on the edge, 3/5 of the way
    assert!(feasible(y) && entries(y)[3] == z(0) && x == (q(2, 5) * v0.0 + q(3, 5) * y.0, q(2, 5) * v0.1 + q(3, 5) * y.1));
    assert!(y == (q(1, 3) * z(15) + q(2, 3) * z(15), q(1, 3) * z(5) + q(2, 3) * z(15))); // the stop splits its edge 1/3 : 2/3
    println!("peel: walk from corner {} through {}, stop at {} on the edge u = 15, t = 5/3", pt(v0), pt(x), pt(y));
    println!("  plan = 2/5 x {} + 3/5 x stop; stop = 1/3 x (15, 5) + 2/3 x (15, 15)", pt(v0));
    for (&c, &a) in &w { println!("  weight {} on corner {}, cost {}", fr(a), pt(c), fr(cost(c))); }
    let mut mix = vec![z(0); 6];
    for (&c, &a) in &w { for k in 0..6 { mix[k] = mix[k] + a * entries(c)[k]; } }
    assert!(mix == entries(x) && w.values().fold(z(0), |s, &a| s + a) == z(1) && w.len() <= 3);
    assert!(w.iter().fold(z(0), |s, (&c, &a)| s + a * cost(c)) == cost(x) && cost(x) == z(268));
    // road 2 to the weights: Cramer's rule in every triangle of three corners
    let mut tri = Vec::new();
    for i in 0..5 { for j in i + 1..5 { for k in j + 1..5 { tri.push([i, j, k]) } } }
    let hold: Vec<([usize; 3], [Q; 3])> = tri.iter().filter_map(|t| {
        bary(x, corners[t[0]], corners[t[1]], corners[t[2]]).filter(|b| b.iter().all(|&e| e >= z(0))).map(|b| (*t, b))
    }).collect();
    println!("corner triangles holding the plan: {} of {}", hold.len(), tri.len());
    for (t, b) in &hold {
        let parts: Vec<String> = (0..3).map(|k| format!("{} x {}", fr(b[k]), pt(corners[t[k]]))).collect();
        println!("  {}", parts.join(" + "));
    }
    assert!(hold.len() > 1 && hold.iter().any(|(t, b)| {
        let m: BTreeMap<P, Q> = (0..3).filter(|&k| b[k] != z(0)).map(|k| (corners[t[k]], b[k])).collect();
        m == w
    }));
    let even = corners.iter().fold((z(0), z(0)), |s, &c| (s.0 + c.0 / z(5), s.1 + c.1 / z(5)));
    println!("mistake: equal weights 1/5 on all five corners give {}, not {}", pt(even), pt(x));
    let cs: Vec<String> = corners.iter().map(|&c| pt(c)).collect();
    println!("figure, corners {}; plan {}; stop {}", cs.join(" "), pt(x), pt(y));

    // N depots and N shops, one pallet each: the corners are the N! one-to-one plans
    for n in 2..5usize {
        let mut good = 0; // brute force over every 0/1 table with row and column sums 1
        for m in 0u64..(1u64 << (n * n)) {
            let bit = |i: usize, j: usize| ((m >> (n * i + j)) & 1) as usize;
            if (0..n).all(|i| (0..n).map(|j| bit(i, j)).sum::<usize>() == 1)
                && (0..n).all(|j| (0..n).map(|i| bit(i, j)).sum::<usize>() == 1) { good += 1 }
        }
        let fact: usize = (2..=n).product();
        let shift = |s: usize, i: usize, j: usize| ((i + s) % n == j) as i64;
        let ok = (0..n).all(|s| (0..n).all(|j| (0..n).map(|i| shift(s, i, j)).sum::<i64>() == 1
            && (0..n).map(|k| shift(s, j, k)).sum::<i64>() == 1))
            && (0..n).all(|i| (0..n).all(|j| (0..n).fold(z(0), |a, s| a + q(shift(s, i, j), n as i64)) == q(1, n as i64)));
        assert!(good == fact && ok);
        println!("N = {}: corners {}, dimension {}, even plan = average of {} shifts", n, fact, (n - 1) * (n - 1), n);
    }

    // the c0 ball: closed, bounded, convex, not compact -- every point can be wiggled
    for n in [4u32, 8, 16] {
        println!("N = {}: the cube [-1, 1]^N has {} corners; each has every entry +1 or -1", n, 1u64 << n);
    }
    let xs: Vec<Q> = (1..17).map(|k| q(1, k)).collect(); // x_n = 1/n, in the c0 ball; entry 2 is 1/2
    let (mut up, mut dn) = (xs.clone(), xs.clone());
    up[1] = xs[1] + q(1, 2);
    dn[1] = xs[1] - q(1, 2);
    let sup = |v: &Vec<Q>| v.iter().map(|&e| if e < z(0) { z(0) - e } else { e }).max().unwrap();
    assert!(sup(&up) == z(1) && sup(&dn) == z(1) && xs[1] == q(1, 2));
    println!("c0: x_n = 1/n is the midpoint of x + e_2/2 and x - e_2/2, both of sup norm 1");

    // one unit spread evenly over [0, 1] against N point masses at the midpoints (k - 1/2)/N
    for n in [1usize, 10, 100, 1000] {
        let (m, nf) = (10 * n, n as f64);
        let h = 1.0 / m as f64;
        let mut w1 = 0.0; // W1 = integral of |F_even - F_points|, midpoint rule, kinks on cell edges
        for i in 0..m {
            let s = (i as f64 + 0.5) * h;
            let g = ((s * nf + 0.5) as usize).min(n) as f64 / nf;
            w1 += (s - g).abs() * h;
        }
        let sq = (1..=n).map(|k| ((k as f64 - 0.5) / nf).powi(2)).sum::<f64>() / nf;
        let cuts: Vec<Q> = [z(0)].into_iter().chain((1..=n as i64).map(|k| q(2 * k - 1, 2 * n as i64))).chain([z(1)]).collect(); // 0, the n atoms, 1
        // total variation, summed over pieces: each atom (points 1/n, even spread 0) and each gap
        // between atoms (points 0, even spread its length); it can never exceed 1 + 1, the two masses
        let ab = |x: Q| if x < z(0) { z(0) - x } else { x };
        let tv = cuts[1..=n].iter().fold(z(0), |a, _| a + ab(q(1, n as i64) - z(0)))
            + cuts.windows(2).fold(z(0), |a, w| a + ab(z(0) - (w[1] - w[0])));
        assert!(tv == z(1) + z(1));
        assert!((w1 - 1.0 / (4.0 * nf)).abs() < 1e-12 && ((1.0 / 3.0 - sq) - 1.0 / (12.0 * nf * nf)).abs() < 1e-12);
        println!("N = {}: W1 = {:.6} (1/4N = {:.6}), x^2 error {:.12}, total variation {}", n, w1, 1.0 / (4.0 * nf), 1.0 / 3.0 - sq, fr(tv));
    }
    println!("ALL CHECKS PASS");
}
