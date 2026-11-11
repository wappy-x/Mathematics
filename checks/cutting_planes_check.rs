// Cutting planes -- the same check as the Python, in Rust.  No crates; a small
// exact-fraction type.  Festival: x1 headliners (60 thousand pounds, 4 hours,
// 5,500 tickets), x2 smaller acts (5 thousand, 2 hours, 1,000 tickets); 290
// thousand pounds, 24 stage hours.  Money in 5-thousand units, time in 2-hour
// slots; tickets in hundreds; maximise.  Same three roads as the Python.
use std::cmp::Ordering;
#[derive(Clone, Copy, PartialEq, Eq, Debug)]
struct Q(i64, i64); // numerator, denominator > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
fn z(n: i64) -> Q { Q(n, 1) }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
fn floor(v: Q) -> i64 { v.0.div_euclid(v.1) }
fn frac(v: Q) -> Q { v - z(floor(v)) } // fractional part: frac(-0.1) = 0.9
fn show(v: Q) -> String {
    if v.1 == 1 { return format!("{}", v.0) }
    format!("{:.2}", v.0 as f64 / v.1 as f64).trim_end_matches('0').to_string()
}
type P = (Q, Q);
type Row = (Vec<Q>, Q);
const C: [i64; 2] = [55, 10];
fn val(p: P) -> Q { z(C[0]) * p.0 + z(C[1]) * p.1 } // tickets, in hundreds
fn pt(p: P) -> String { format!("({}, {})", show(p.0), show(p.1)) }
fn tk(p: P) -> String { show(z(100) * val(p)) }
fn pts_str(ps: &[P]) -> String { ps.iter().map(|&p| pt(p)).collect::<Vec<_>>().join(" ") }
fn wp(p: (i64, i64)) -> P { (z(p.0), z(p.1)) }

fn simplex(a: &[Vec<Q>], b: &[Q]) -> (Vec<Vec<Q>>, Vec<Q>, Vec<usize>, usize) { // maximise C.x, Ax <= b
    let (m, n) = (a.len(), 2);
    let mut t: Vec<Vec<Q>> = (0..m).map(|i| {
        let mut r = a[i].clone();
        r.extend((0..m).map(|j| z((i == j) as i64))); r.push(b[i]); r }).collect();
    let mut zr: Vec<Q> = C.iter().map(|&c| z(-c)).collect(); zr.extend(vec![z(0); m + 1]);
    let (mut basis, mut piv): (Vec<usize>, usize) = ((n..n + m).collect(), 0);
    loop {
        let col = match (0..n + m).find(|&j| zr[j] < z(0)) { Some(c) => c, None => return (t, zr, basis, piv) }; // Bland
        let r = (0..m).filter(|&i| t[i][col] > z(0))
            .min_by(|&i, &k| (t[i][n + m] / t[i][col], basis[i]).cmp(&(t[k][n + m] / t[k][col], basis[k]))).unwrap();
        let p = t[r][col];
        t[r] = t[r].iter().map(|&v| v / p).collect();
        let pr = t[r].clone();
        for i in 0..m { if i != r { let f = t[i][col]; t[i] = t[i].iter().zip(&pr).map(|(&x, &c)| x - f * c).collect(); } }
        let f = zr[col]; zr = zr.iter().zip(&pr).map(|(&x, &c)| x - f * c).collect();
        basis[r] = col; piv += 1;
    }
}
fn corners(a: &[Vec<Q>], b: &[Q], extra: &[Row]) -> Vec<P> { // road 2: every crossing of two edges
    let mut rows: Vec<Row> = a.iter().cloned().zip(b.iter().cloned()).collect();
    rows.push((vec![z(-1), z(0)], z(0))); rows.push((vec![z(0), z(-1)], z(0)));
    rows.extend(extra.iter().cloned());
    let mut pts: Vec<P> = vec![];
    for i in 0..rows.len() { for j in i + 1..rows.len() {
        let ((p, e), (r, f)) = (&rows[i], &rows[j]);
        let d = p[0] * r[1] - p[1] * r[0];
        if d == z(0) { continue }
        let x = ((*e * r[1] - p[1] * *f) / d, (p[0] * *f - *e * r[0]) / d);
        if rows.iter().all(|(g, c)| g[0] * x.0 + g[1] * x.1 <= *c) && !pts.contains(&x) { pts.push(x) }
    } }
    pts.sort(); pts
}
fn lp_best(a: &[Vec<Q>], b: &[Q], extra: &[Row]) -> Option<P> { // None when the region is empty
    corners(a, b, extra).into_iter().max_by_key(|&p| (val(p), p.0, p.1))
}
fn plans(a: &[Vec<Q>], b: &[Q]) -> Vec<(i64, i64)> { // road 3: every whole-number booking
    let mut v = vec![];
    for i in 0..13 { for j in 0..13 { if a.iter().zip(b).all(|(r, &c)| r[0] * z(i) + r[1] * z(j) <= c) { v.push((i, j)) } } }
    v
}
fn gomory(row: &[Q], a: &[Vec<Q>], b: &[Q]) -> (Vec<Q>, Q, [i64; 2], i64) {
    let m = a.len();
    let fs: Vec<Q> = row[2..2 + m].iter().map(|&v| frac(v)).collect();
    let cx: Vec<Q> = (0..2).map(|k| (0..m).fold(z(0), |s, i| s + fs[i] * a[i][k]) - frac(row[k])).collect();
    let rhs = (0..m).fold(z(0), |s, i| s + fs[i] * b[i]) - frac(row[row.len() - 1]);
    let vals = [cx[0], cx[1], rhs];
    let scale = vals.iter().fold(1, |s, v| s * v.1 / gcd(s, v.1));
    let ints: Vec<i64> = vals.iter().map(|v| v.0 * (scale / v.1)).collect();
    let g = gcd(gcd(ints[0], ints[1]), ints[2]);
    (fs, frac(row[row.len() - 1]), [ints[0] / g, ints[1] / g], ints[2] / g)
}
struct St { best: Option<(Q, P)>, nodes: usize, log: Vec<(usize, Option<P>)> }
fn bnb(a: &[Vec<Q>], b: &[Q], extra: Vec<Row>, st: &mut St, depth: usize) { // depth first, x <= floor first
    let x = lp_best(a, b, &extra);
    st.nodes += 1; st.log.push((depth, x));
    let x = match x { Some(x) => x, None => return };
    if let Some((v, _)) = st.best { if val(x) <= v { return } } // cannot beat the best booking found
    let k = match (0..2).find(|&k| [x.0, x.1][k].1 > 1) { Some(k) => k, None => { st.best = Some((val(x), x)); return } };
    let fl = floor([x.0, x.1][k]);
    let (mut lo, mut hi) = (vec![z(0), z(0)], vec![z(0), z(0)]);
    lo[k] = z(1); hi[k] = z(-1);
    let (mut e1, mut e2) = (extra.clone(), extra);
    e1.push((lo, z(fl))); e2.push((hi, z(-fl - 1)));
    bnb(a, b, e1, st, depth + 1); bnb(a, b, e2, st, depth + 1);
}
fn cut_row(c: [i64; 2], r: i64) -> Row { (vec![z(c[0]), z(c[1])], z(r)) }
fn qv(v: &[i64]) -> Vec<Q> { v.iter().map(|&x| z(x)).collect() }

fn main() {
    let a = vec![qv(&[12, 1]), qv(&[2, 1])];
    let b = qv(&[58, 12]);
    let (t, zr, basis, piv) = simplex(&a, &b);
    let x: P = (basis.iter().position(|&v| v == 0).map_or(z(0), |i| t[i][4]), basis.iter().position(|&v| v == 1).map_or(z(0), |i| t[i][4]));
    let top = lp_best(&a, &b, &[]).unwrap();
    println!("relaxation by simplex: {}, {} acts, {} tickets, {} pivots", pt(x), show(x.0 + x.1), show(z(100) * zr[4]), piv);
    println!("relaxation by corners: {} -> best {}, {} tickets", pts_str(&corners(&a, &b, &[])), pt(top), tk(top));
    for (i, bv) in basis.iter().enumerate() {
        println!("tableau row x{}: s1 {}, s2 {}, right side {}", bv + 1, show(t[i][2]), show(t[i][3]), show(t[i][4]));
    }
    let pts = plans(&a, &b);
    let best = *pts.iter().max_by_key(|&&p| val(wp(p))).unwrap();
    println!("whole-number bookings: {}; best {}, {} tickets; gap {}", pts.len(), pt(wp(best)), tk(wp(best)), show(z(100) * (val(top) - val(wp(best)))));
    let mut cuts = vec![([0i64; 2], 0i64); 2];
    for (i, &bv) in basis.iter().enumerate() {
        let (fs, f0, c, r) = gomory(&t[i], &a, &b);
        cuts[bv] = (c, r);
        let nw = lp_best(&a, &b, &[cut_row(c, r)]).unwrap();
        println!("cut from row x{}: {} s1 + {} s2 >= {}  ->  {} x1 + {} x2 <= {}; corner gives {}; new best {}, {} tickets",
            bv + 1, show(fs[0]), show(fs[1]), show(f0), c[0], c[1], r, show(z(c[0]) * top.0 + z(c[1]) * top.1), pt(nw), tk(nw));
        assert!(pts.iter().all(|p| c[0] * p.0 + c[1] * p.1 <= r)); // keeps every whole booking
        assert!(z(c[0]) * top.0 + z(c[1]) * top.1 > z(r)); // removes the 7.4-act corner
    }
    let w = [q(1, 10), q(9, 10)]; // the x1 cut as a blend of the two limits, rounded
    let rb = w[0] * z(58) + w[1] * z(12);
    println!("blend 0.1 x budget + 0.9 x slots: {} x1 + {} x2 <= {}, round down to {}", show(w[0] * z(12) + w[1] * z(2)), show(w[0] + w[1]), show(rb), floor(rb));
    let (_, z2, _, piv2) = simplex(&[a[0].clone(), a[1].clone(), qv(&cuts[0].0)], &[b[0], b[1], z(cuts[0].1)]);
    println!("re-solve with the cut by simplex: {} tickets, gap {}, {} pivots", show(z(100) * z2[5]), show(z(100) * (z2[5] - val(wp(best)))), piv2);
    let mut found = (z(0), (z(0), z(0)));
    for (name, extra) in [("branch and bound, no cut", vec![]), ("branch and cut, x1-row cut at root", vec![cut_row(cuts[0].0, cuts[0].1)])] {
        let mut st = St { best: None, nodes: 0, log: vec![] };
        bnb(&a, &b, extra, &mut st, 0);
        found = st.best.unwrap();
        println!("{}: nodes {}, best {}, {} tickets", name, st.nodes, pt(found.1), tk(found.1));
        for (d, p) in &st.log {
            match p { None => println!("  node at depth {}: empty", d), Some(p) => println!("  node at depth {}: {}, {} tickets", d, pt(*p), tk(*p)) }
        }
    }
    let (mut ac, mut bc, mut cur, mut rounds) = (a.clone(), b.clone(), top, 0); // pure cutting, round after round
    while cur.0.1 > 1 || cur.1.1 > 1 {
        let (t3, _, b3, _) = simplex(&ac, &bc);
        let want = if cur.0.1 > 1 { 0 } else { 1 };
        let (_, _, c3, r3) = gomory(&t3[b3.iter().position(|&v| v == want).unwrap()], &ac, &bc);
        assert!(pts.iter().all(|p| c3[0] * p.0 + c3[1] * p.1 <= r3) && z(c3[0]) * cur.0 + z(c3[1]) * cur.1 > z(r3)); // keeps every booking, removes the corner
        ac.push(qv(&c3)); bc.push(z(r3)); rounds += 1;
        let extra: Vec<Row> = (2..ac.len()).map(|i| (ac[i].clone(), bc[i])).collect();
        cur = lp_best(&a, &b, &extra).unwrap();
        println!("  pure cutting, round {}: {} x1 + {} x2 <= {}; best {}, {} tickets", rounds, c3[0], c3[1], r3, pt(cur), tk(cur));
    }
    println!("mistake 1, round the corner to (5, 3): budget {} > 290, hours {} > 24", 60 * 5 + 5 * 3, 4 * 5 + 2 * 3);
    println!("mistake 2, round down to (4, 2): {} tickets, {} short", tk(wp((4, 2))), show(z(100) * (val(wp(best)) - val(wp((4, 2))))));
    let am = vec![vec![q(6, 100), q(5, 1000)], qv(&[4, 2])]; // budget in millions of pounds
    let bm = vec![q(29, 100), z(24)];
    let (tm, _, bms, _) = simplex(&am, &bm);
    let (_, _, c5, r5) = gomory(&tm[bms.iter().position(|&v| v == 0).unwrap()], &am, &bm);
    let lost: Vec<(i64, i64)> = pts.iter().filter(|p| c5[0] * p.0 + c5[1] * p.1 > r5).cloned().collect();
    let left = *pts.iter().filter(|p| !lost.contains(p)).max_by_key(|&&p| val(wp(p))).unwrap();
    println!("mistake 3, budget in millions, 0.06 x1 + 0.005 x2 <= 0.29: cut {} x1 + {} x2 <= {} throws out {:?}; best left {}, {} tickets",
        c5[0], c5[1], r5, lost, pt(wp(left)), tk(wp(left)));
    println!("figure, region: {}", pts_str(&corners(&a, &b, &[])));
    println!("figure, after the cut: {}", pts_str(&corners(&a, &b, &[cut_row(cuts[0].0, cuts[0].1)])));
    assert!(x == top && z(100) * zr[4] == z(28100) && z(100) * val(top) == z(28100)); // simplex agrees with corners
    assert!(best == (4, 4) && found == (val(wp(best)), wp(best)) && val(wp(best)) == z(260)); // search agrees with the list
    assert!(cuts[0] == ([3, 1], 16) && Some(z2[5]) == lp_best(&a, &b, &[cut_row(cuts[0].0, cuts[0].1)]).map(val));
    assert!(lost.contains(&(4, 4)) && val(wp(left)) < val(wp(best))); // fractional data breaks it
    assert!(cur == wp(best) && rounds == 4); // pure cutting ends at the listed best
    println!("ALL CHECKS PASS");
}
