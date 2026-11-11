// LP duality -- the same check as the Python, in Rust.  No crates, exact fractions.
// Workshop: maximise profit 19x1 + 20x2 pounds (x1 tables, x2 chairs) subject to
// timber 4x1 + 2x2 <= 160 m, labour 3x1 + x2 <= 120 h, finish x1 + 2x2 <= 64 litres, x >= 0.
// Dual: minimise 160y1 + 120y2 + 64y3 subject to 4y1 + 3y2 + y3 >= 19, 2y1 + y2 + 2y3 >= 20, y >= 0.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q(i64, i64); // numerator, denominator > 0, in lowest terms
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q(n / g, d / g) }
fn z(n: i64) -> Q { Q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.0 * o.1 + o.0 * self.1, self.1 * o.1) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.0 * o.1 - o.0 * self.1, self.1 * o.1) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.0 * o.0, self.1 * o.1) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.0 * o.1, self.1 * o.0) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.0 * o.1).cmp(&(o.0 * self.1)) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl std::fmt::Display for Q {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.1 == 1 { f.pad(&self.0.to_string()) } else { f.pad(&format!("{:.2}", self.0 as f64 / self.1 as f64)) }
    }
}
type V = Vec<Q>;
fn dot(u: &[Q], v: &[Q]) -> Q { u.iter().zip(v).fold(z(0), |s, (a, b)| s + *a * *b) }
fn col(m: &[V], j: usize) -> V { m.iter().map(|r| r[j]).collect() }
fn vz(v: &[i64]) -> V { v.iter().map(|&x| z(x)).collect() }
fn show(v: &[Q]) -> String { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn solve(m: &[V], v: &[Q]) -> Option<V> { // Gauss-Jordan elimination in fractions; None if singular
    let n = v.len();
    let mut t: Vec<V> = m.iter().zip(v).map(|(r, w)| { let mut r = r.clone(); r.push(*w); r }).collect();
    for i in 0..n {
        let p = (i..n).find(|&r| t[r][i] != z(0))?;
        t.swap(i, p);
        for r in 0..n {
            let f = t[r][i] / t[i][i];
            if r != i && f != z(0) { let ti = t[i].clone(); for k in 0..=n { t[r][k] = t[r][k] - f * ti[k]; } }
        }
    }
    Some((0..n).map(|i| t[i][n] / t[i][i]).collect())
}
fn combos(m: usize, n: usize, start: usize, cur: &mut Vec<usize>, out: &mut Vec<Vec<usize>>) {
    if cur.len() == n { out.push(cur.clone()); return; }
    for i in start..m { cur.push(i); combos(m, n, i + 1, cur, out); cur.pop(); }
}
fn corners(g: &[V], h: &[Q]) -> Vec<V> { // every point where n walls of G z <= h meet and all hold
    let (mut sets, mut out) = (vec![], vec![]);
    combos(g.len(), g[0].len(), 0, &mut vec![], &mut sets);
    for rows in sets {
        let gm: Vec<V> = rows.iter().map(|&r| g[r].clone()).collect();
        let hv: V = rows.iter().map(|&r| h[r]).collect();
        if let Some(p) = solve(&gm, &hv) {
            if g.iter().zip(h).all(|(gr, w)| dot(gr, &p) <= *w) && !out.contains(&p) { out.push(p); }
        }
    }
    out
}
fn simplex(a: &[V], b: &[Q], c: &[Q]) -> (V, V, Q, Vec<V>) { // max c.x, Ax <= b, b >= 0; Dantzig's rule
    let (m, n) = (a.len(), c.len());
    let mut t: Vec<V> = (0..m).map(|i| { let mut r = a[i].clone();
        r.extend((0..m).map(|k| z((i == k) as i64))); r.push(b[i]); r }).collect();
    let mut zr: V = c.iter().map(|&x| z(0) - x).collect(); zr.extend(vec![z(0); m + 1]);
    let (mut basis, mut path): (Vec<usize>, Vec<V>) = ((n..n + m).collect(), vec![]);
    let mut x = vec![z(0); n];
    loop {
        let mn = *zr[..n + m].iter().min().unwrap();
        if mn >= z(0) { break; }
        let j = zr.iter().position(|&v| v == mn).unwrap(); // entering column: most negative reduced cost
        let mut r = usize::MAX;
        for i in 0..m { if t[i][j] > z(0) && (r == usize::MAX || t[i][n + m] / t[i][j] < t[r][n + m] / t[r][j]) { r = i; } }
        let p = t[r][j]; t[r] = t[r].iter().map(|&v| v / p).collect();
        let tr = t[r].clone();
        for i in 0..m { if i != r { let f = t[i][j]; for k in 0..=n + m { t[i][k] = t[i][k] - f * tr[k]; } } }
        let f = zr[j]; for k in 0..=n + m { zr[k] = zr[k] - f * tr[k]; } basis[r] = j;
        x = vec![z(0); n];
        for (i, &v) in basis.iter().enumerate() { if v < n { x[v] = t[i][n + m]; } }
        path.push(x.clone());
    }
    (x, zr[n..n + m].to_vec(), zr[n + m], path) // plan, prices on the slack columns, value, corners visited
}

fn main() {
    let a: Vec<V> = vec![vz(&[4, 2]), vz(&[3, 1]), vz(&[1, 2])];
    let (b, c) = (vz(&[160, 120, 64]), vz(&[19, 20]));
    let (res, prod) = (["timber", "labour", "finish"], ["tables", "chairs"]);
    let mut g = a.clone(); g.push(vz(&[-1, 0])); g.push(vz(&[0, -1]));
    let pc = corners(&g, &vz(&[160, 120, 64, 0, 0]));
    let pcs: Vec<String> = pc.iter().map(|p| format!("{} {}", show(p), dot(&c, p))).collect();
    println!("primal corners (tables, chairs) and profit: {}", pcs.join(" | "));
    let (x, y, val, path) = simplex(&a, &b, &c);
    let ps: Vec<String> = path.iter().map(|p| show(p)).collect();
    println!("road 1, simplex (Dantzig's rule): {} pivots, path (0, 0) -> {}", path.len(), ps.join(" -> "));
    println!("road 1, best plan {} tables, {} chairs, profit {}", x[0], x[1], val);
    let yr: Vec<String> = (0..3).map(|i| format!("{} {}", res[i], y[i])).collect();
    println!("road 1, prices read off the final tableau: {}", yr.join(", "));
    let mut dg: Vec<V> = (0..2).map(|j| col(&a, j).iter().map(|&v| z(0) - v).collect()).collect();
    for i in 0..3 { dg.push((0..3).map(|k| z(-((i == k) as i64))).collect()); }
    let dc = corners(&dg, &vz(&[-19, -20, 0, 0, 0]));
    let yb = dc.iter().fold(dc[0].clone(), |m, v| if dot(&b, v) < dot(&b, &m) { v.clone() } else { m });
    println!("road 2, dual corners checked: {}; cheapest price list {} worth {}", dc.len(), show(&yb), dot(&b, &yb));
    let y3 = solve(&[vz(&[4, 3, 1]), vz(&[2, 1, 2]), vz(&[0, 1, 0])], &vz(&[19, 20, 0])).unwrap();
    println!("road 3, slackness equations 4y1 + 3y2 + y3 = 19, 2y1 + y2 + 2y3 = 20, y2 = 0: y = {}", show(&y3));
    println!("duality gap at the best pair: {} - {} = {}", dot(&b, &y), val, dot(&b, &y) - val);
    let used: V = a.iter().map(|r| dot(r, &x)).collect();
    let s8: V = (0..3).map(|i| b[i] - used[i]).collect();
    println!("resource  used  limit  slack  price  price x slack");
    for i in 0..3 { println!("{:8}  {:>4}  {:>5}  {:>5}  {:>5}  {:>13}", res[i], used[i], b[i], s8[i], y[i], y[i] * s8[i]); }
    println!("product  made  inputs at prices  profit  surplus  made x surplus");
    for j in 0..2 {
        let v = dot(&col(&a, j), &y);
        println!("{:7}  {:>4}  {:>16}  {:>6}  {:>7}  {:>14}", prod[j], x[j], v, c[j], v - c[j], x[j] * (v - c[j]));
    }
    let yt = vz(&[3, 1, 7]);
    let vt: V = (0..2).map(|j| dot(&col(&a, j), &yt)).collect();
    let r: V = (0..2).map(|j| vt[j] - c[j]).collect();
    println!("trial prices {}: table inputs {}, chair inputs {}, total {}", show(&yt), vt[0], vt[1], dot(&b, &yt));
    let mut terms: Vec<String> = (0..3).filter(|&i| s8[i] != z(0)).map(|i| format!("{} x {}", yt[i], s8[i])).collect();
    terms.extend((0..2).map(|j| format!("{} x {}", x[j], r[j])));
    println!("gap identity: {} - {} = {} = {}", dot(&b, &yt), val, dot(&b, &yt) - val, terms.join(" + "));
    let ai = [[4i64, 2], [3, 1], [1, 2]]; let (bi, ci) = ([160i64, 120, 64], [19i64, 20]);
    let mut plans = vec![];
    for t in 0..41i64 { for ch in 0..33i64 { if (0..3).all(|i| ai[i][0] * t + ai[i][1] * ch <= bi[i]) { plans.push((t, ch)); } } }
    let mut prices = vec![];
    for p in 0..11i64 { for l in 0..11i64 { for f in 0..11i64 {
        if (0..2).all(|j| ai[0][j] * p + ai[1][j] * l + ai[2][j] * f >= ci[j]) { prices.push((p, l, f)); } } } }
    let (mut gmin, mut zeros) = (i64::MAX, 0);
    for &(t, ch) in &plans { for &(p, l, f) in &prices {
        let gap = 160 * p + 120 * l + 64 * f - 19 * t - 20 * ch; gmin = gmin.min(gap); if gap == 0 { zeros += 1; } } }
    println!("weak duality grid: {} whole-number plans x {} price lists, smallest gap {}, zero gaps {}", plans.len(), prices.len(), gmin, zeros);
    for bad in [vz(&[2, 0, 7]), vz(&[8, -6, 5])] {
        println!("break, prices {}: inputs {} and {}, total {}, below {} by {}", show(&bad), dot(&col(&a, 0), &bad),
                 dot(&col(&a, 1), &bad), dot(&b, &bad), val, val - dot(&b, &bad));
    }
    println!("break, negative labour price: -6 x {} spare hours = {}", s8[1], z(-6) * s8[1]);
    let mut a4 = a.clone(); a4.push(vz(&[0, -1])); let b4 = vz(&[160, 120, 64, -40]); let w = vz(&[0, 0, 1, 2]);
    let mut g4 = a4.clone(); g4.push(vz(&[-1, 0])); g4.push(vz(&[0, -1]));
    let none = corners(&g4, &vz(&[160, 120, 64, -40, 0, 0]));
    let wa: V = (0..2).map(|j| dot(&col(&a4, j), &w)).collect();
    println!("break, order for 40 chairs: {} feasible corners; finish + 2 x order reads {}x1 + {}x2 <= {}", none.len(), wa[0], wa[1], dot(&b4, &w));
    let mut y4 = y.clone(); y4.push(z(0));
    let yk = |k: i64| -> V { y4.iter().zip(&w).map(|(&p, &d)| p + z(k) * d).collect() };
    println!("break, its dual: prices {} + k x {} stay valid, value {} - {}k: k = 10 -> {}, k = 100 -> {}", show(&y4), show(&w),
             dot(&b, &y), z(0) - dot(&b4, &w), dot(&b4, &yk(10)), dot(&b4, &yk(100)));
    let y0 = solve(&[vz(&[1, 0, 0]), vz(&[0, 1, 0]), vz(&[2, 1, 2])], &vz(&[0, 0, 20])).unwrap();
    println!("break, corner (0, 32): slackness prices {}, tables valued {} < 19, total {}", show(&y0), dot(&col(&a, 0), &y0), dot(&b, &y0));
    let cs: Vec<String> = pc.iter().map(|p| show(p)).collect();
    let tips: Vec<String> = [(0..2).map(|k| x[k] + y[0] * a[0][k]).collect::<V>(), (0..2).map(|k| x[k] + y[2] * a[2][k]).collect(),
        (0..2).map(|k| x[k] + c[k]).collect()].iter().map(|t| show(t)).collect();
    println!("figure, corners {}; profit (19, 20) = {} x (4, 2) + {} x (1, 2); arrow tips {}", cs.join(" "), y[0], y[2], tips.join(" "));
    let fin = simplex(&a, &vz(&[160, 120, 65]), &c); let lab = simplex(&a, &vz(&[160, 111, 64]), &c);
    println!("try, finish 65 litres: plan {}, profit {}, prices {}", show(&fin.0), fin.2, show(&fin.1));
    println!("try, labour 112 hours: profit {}; labour 111: plan {}, profit {}, prices {}",
             simplex(&a, &vz(&[160, 112, 64]), &c).2, show(&lab.0), lab.2, show(&lab.1));
    let chp = simplex(&a, &b, &vz(&[19, 40]));
    println!("try, chair profit 40: plan {}, profit {}, prices {}", show(&chp.0), chp.2, show(&chp.1));
    assert!(val == z(928) && x == vz(&[32, 16]) && dot(&b, &y) == val);           // strong duality: equal values
    assert!(pc.iter().map(|p| dot(&c, p)).max().unwrap() == val && yb == y && y3 == y); // three roads agree
    assert!(gmin == 0 && zeros == 1);                                             // weak duality on the grid
    assert!((0..3).all(|i| y[i] * s8[i] == z(0)) && dot(&b, &yt) - val == z(120));     // the trial gap, by hand
    assert!((0..3).map(|i| yt[i] * s8[i]).chain((0..2).map(|j| x[j] * r[j])).collect::<V>() == vz(&[0, 8, 0, 96, 16])); // its terms
    assert!(dot(&b, &vz(&[8, -6, 5])) < val && dot(&col(&a, 0), &y0) < z(19));     // the broken certificates
    assert!(none.is_empty() && wa.iter().all(|&v| v >= z(0)) && dot(&b4, &w) < z(0)); // Farkas: no plan fills the order
    assert!((0..2).all(|j| [10, 100].iter().all(|&k| dot(&col(&a4, j), &yk(k)) >= c[j])));
    println!("ALL CHECKS PASS");
}
