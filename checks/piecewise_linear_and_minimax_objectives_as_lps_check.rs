// Modelling tricks -- the same check as the Python, in Rust.  No crates.
// A workshop makes t tables (£19 each) and c chairs (£20 each) from 160 m of timber,
// 92 regular hours of labour and 64 l of finish.  Overtime costs £2 an hour extra for
// the first 10 hours and £5 an hour after that.  Maximise profit, £.  Every LP is
// solved by listing every corner in exact fractions, with a small fraction type.
#[derive(Clone, Copy, Debug, PartialEq)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { Q { n, d: 1 } }
impl std::ops::Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl std::ops::Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl std::ops::Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl std::ops::Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<std::cmp::Ordering> { (self.n * o.d).partial_cmp(&(o.n * self.d)) } }
fn mx(a: Q, b: Q) -> Q { if a > b { a } else { b } }
fn mn(a: Q, b: Q) -> Q { if a < b { a } else { b } }
fn dot(a: &[Q], b: &[Q]) -> Q { a.iter().zip(b).fold(z(0), |s, (x, y)| s + *x * *y) }
fn qv(v: &[i128]) -> Vec<Q> { v.iter().map(|&x| z(x)).collect() }

fn solve(a: &[Vec<Q>], b: &[Q]) -> Option<Vec<Q>> {    // Gauss-Jordan; None if singular
    let n = a.len();
    let mut m: Vec<Vec<Q>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for i in 0..n {
        let p = (i..n).find(|&r| m[r][i].n != 0)?;
        m.swap(i, p);
        for r in 0..n {
            if r != i && m[r][i].n != 0 {
                let f = m[r][i] / m[i][i];
                for k in 0..=n { let v = m[i][k]; m[r][k] = m[r][k] - f * v; }
            }
        }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}
fn best_corner(c: &[Q], a: &[Vec<Q>], b: &[Q]) -> (Q, Vec<Q>) {   // maximise c.x over Ax <= b
    let mut best: Option<(Q, Vec<Q>)> = None;
    for mask in 0u32..(1 << a.len()) {
        if mask.count_ones() as usize != c.len() { continue; }
        let rows: Vec<usize> = (0..a.len()).filter(|&i| mask >> i & 1 == 1).collect();
        let sa: Vec<Vec<Q>> = rows.iter().map(|&i| a[i].clone()).collect();
        let sb: Vec<Q> = rows.iter().map(|&i| b[i]).collect();
        if let Some(x) = solve(&sa, &sb) {
            if (0..a.len()).any(|i| dot(&a[i], &x) > b[i]) { continue; }
            let val = dot(c, &x);
            if best.as_ref().map_or(true, |bb| val > bb.0) { best = Some((val, x)); }
        }
    }
    best.unwrap()
}
fn m(x: Q) -> String {                              // money to the penny, rounded half up
    let s = if x.n < 0 { "-" } else { "" };
    let p = (x.n.abs() * 200 + x.d).div_euclid(2 * x.d);
    format!("{}{}.{:02}", s, p / 100, p % 100)
}
fn nums(xs: &[Q]) -> String {
    xs.iter().map(|&x| if x.d > 1 { m(x) } else { x.n.to_string() }).collect::<Vec<_>>().join(" ")
}
const HOURS: i128 = 92;
fn segment_lp(p1: i128, p2: i128, cap: i128) -> (Q, Vec<Q>) {   // t, c, h1, h2
    let a: Vec<Vec<Q>> = [[4, 2, 0, 0], [3, 1, -1, -1], [1, 2, 0, 0], [0, 0, 1, 0],
        [-1, 0, 0, 0], [0, -1, 0, 0], [0, 0, -1, 0], [0, 0, 0, -1]].iter().map(|r| qv(r)).collect();
    best_corner(&qv(&[19, 20, -p1, -p2]), &a, &qv(&[160, HOURS, 64, cap, 0, 0, 0, 0]))
}
fn epigraph_lp(lines: &[(i128, i128)]) -> (Q, Vec<Q>) {        // t, c, h, z
    let mut a: Vec<Vec<Q>> = [[4, 2, 0, 0], [3, 1, -1, 0], [1, 2, 0, 0], [-1, 0, 0, 0],
        [0, -1, 0, 0], [0, 0, -1, 0]].iter().map(|r| qv(r)).collect();
    let mut b = qv(&[160, HOURS, 64, 0, 0, 0]);
    for &(s, k) in lines { a.push(qv(&[0, 0, s, -1])); b.push(z(k)); }
    best_corner(&qv(&[19, 20, 0, -1]), &a, &b)
}
fn true_cost(h: Q, p1: i128, p2: i128, cap: i128) -> Q { z(p1) * mn(h, z(cap)) + z(p2) * mx(h - z(cap), z(0)) }
fn kinked(p1: i128, p2: i128, cap: i128) -> (Q, Vec<Q>, Q) {   // road 3: every crossing
    let l = [([4, 2], 160), ([1, 2], 64), ([1, 0], 0), ([0, 1], 0), ([3, 1], HOURS), ([3, 1], HOURS + cap)];
    let mut best: Option<(Q, Vec<Q>, Q)> = None;
    for i in 0..l.len() { for j in i + 1..l.len() {
        if let Some(x) = solve(&[qv(&l[i].0), qv(&l[j].0)], &[z(l[i].1), z(l[j].1)]) {
            if x[0] < z(0) || x[1] < z(0) || z(4) * x[0] + z(2) * x[1] > z(160) || x[0] + z(2) * x[1] > z(64) { continue; }
            let h = mx(z(0), z(3) * x[0] + x[1] - z(HOURS));
            let val = z(19) * x[0] + z(20) * x[1] - true_cost(h, p1, p2, cap);
            if best.as_ref().map_or(true, |bb| val > bb.0) { best = Some((val, x, h)); }
        }
    } }
    best.unwrap()
}
const WEEKS: [(i128, i128); 5] = [(10, 30), (30, 90), (20, 80), (25, 75), (15, 46)];
fn total(a: Q) -> Q { WEEKS.iter().fold(z(0), |s, &(t, h)| { let e = z(h) - a * z(t); s + mx(e, z(0) - e) }) }
fn worst(a: Q) -> Q { WEEKS.iter().fold(z(0), |s, &(t, h)| { let e = z(h) - a * z(t); mx(s, mx(e, z(0) - e)) }) }
fn fits(w: &[(i128, i128)]) -> ((Q, Vec<Q>), (Q, Vec<Q>)) {
    let n = w.len(); let (mut a, mut b) = (vec![], vec![]);
    for (i, &(t, h)) in w.iter().enumerate() {           // -e_i <= H_i - a q_i <= e_i
        let mut e = vec![z(0); n]; e[i] = z(-1);
        let mut r1 = vec![z(-t)]; r1.extend(e.clone()); let mut r2 = vec![z(t)]; r2.extend(e);
        a.push(r1); a.push(r2); b.push(z(-h)); b.push(z(h));
    }
    let mut c = vec![z(0)]; c.extend(vec![z(-1); n]);
    let a2: Vec<Vec<Q>> = a.iter().map(|r| vec![r[0], z(-1)]).collect();
    (best_corner(&c, &a, &b), best_corner(&[z(0), z(-1)], &a2, &b))
}
fn main() {
    let (v1, x1) = segment_lp(2, 5, 10);
    let (v2, x2) = epigraph_lp(&[(2, 0), (5, 30)]);
    let (v3, x3, h3) = kinked(2, 5, 10);
    println!("tiers as two variables  t c h1 h2: {}  profit {}", nums(&x1), m(v1));
    println!("cost as z above lines   t c h z:   {}  profit {}", nums(&x2), m(v2));
    println!("kinked cost, crossings  t c hours: {}  profit {}", nums(&[x3[0], x3[1], h3 + z(HOURS)]), m(v3));
    let base: Vec<Vec<Q>> = [[4, 2], [3, 1], [1, 2], [-1, 0], [0, -1]].iter().map(|r| qv(r)).collect();
    let (v0, x0) = best_corner(&qv(&[19, 20]), &base, &qv(&[160, HOURS, 64, 0, 0]));
    println!("no overtime             t c: {}  profit {}", nums(&x0), m(v0));
    println!("all 20 hours            t c: 32 16  profit {}", m(z(19 * 32 + 20 * 16) - true_cost(z(20), 2, 5, 10)));
    let (dt, dc) = (q(2, 5), q(-1, 5));
    println!("one more hour: tables {} chairs {} gained {} lost {} worth {}", m(dt), m(dc), m(z(19) * dt), m(z(-20) * dc), m(z(19) * dt + z(20) * dc));
    let y = solve(&[qv(&[3, 1, 0]), qv(&[1, 2, 0]), qv(&[-1, 0, 1])], &qv(&[19, 20, -2])).unwrap();
    let cols = [(19, [4, 3, 1, 0]), (20, [2, 1, 2, 0]), (-2, [0, -1, 0, 1]), (-5, [0, -1, 0, 0])];
    let yy = vec![z(0), y[0], y[1], y[2]];
    let red: Vec<Q> = cols.iter().map(|(cj, col)| dot(&qv(col), &yy) - z(*cj)).collect();
    let bound = dot(&yy, &qv(&[160, HOURS, 64, 10]));
    println!("prices timber labour finish cap: {}  shortfalls {}  bound {}", nums(&yy), nums(&red), m(bound));
    println!("timber used {}  bound parts {}  against no overtime {}  against all 20 hours {}", nums(&[z(4) * x1[0] + z(2) * x1[1]]),
             nums(&[yy[1] * z(HOURS), yy[2] * z(64), yy[3] * z(10)]), m(v1 - v0), m(v1 - z(858)));
    let hs: Vec<i128> = (0..=20).step_by(2).collect();
    let row = |f: &dyn Fn(i128) -> Q| nums(&hs.iter().map(|&h| f(h)).collect::<Vec<_>>());
    println!("chart hours   {}", row(&|h| z(h)));
    println!("chart 2h      {}", row(&|h| z(2 * h)));
    println!("chart 5h-30   {}", row(&|h| z(5 * h - 30)));
    println!("chart 3.6h    {}", row(&|h| q(18, 5) * z(h)));
    let (b1, xb1) = segment_lp(2, 1, 10);
    println!("falling tiers 2 then 1:  h1 h2 {}  real bill {}  LP says {}  bill says {}", nums(&xb1[2..]), nums(&[true_cost(z(20), 2, 1, 10)]), m(b1),
             m(z(19) * xb1[0] + z(20) * xb1[1] - true_cost(xb1[2] + xb1[3], 2, 1, 10)));
    let (b2, xb2) = segment_lp(2, 5, 1000);
    println!("tier-1 cap dropped:      hours {}  LP says {}  bill says {}", nums(&xb2[2..3]), m(b2),
             m(z(19) * xb2[0] + z(20) * xb2[1] - true_cost(xb2[2], 2, 5, 10)));
    let (b3, xb3) = epigraph_lp(&[(0, 0), (5, 30)]);
    println!("only the 5h-30 line:     hours {}  LP says {}  bill says {}", nums(&xb3[2..3]), m(b3),
             m(z(19) * xb3[0] + z(20) * xb3[1] - true_cost(xb3[2], 2, 5, 10)));
    let (t1, t2, t3) = (segment_lp(2, 3, 10), segment_lp(4, 5, 10), kinked(2, 5, 20));
    println!("try tier 2 at 3: t c {} {} | tier 1 at 4: {} {} | cap 20: {} {}", nums(&t1.1[..2]), m(t1.0),
             nums(&t2.1[..2]), m(t2.0), nums(&t3.1), m(t3.0));
    let ((l1, la), (mm, ma)) = fits(&WEEKS);
    let mut ak = z(1000);
    for &(t, h) in WEEKS.iter() { let r = q(h, t); if total(r) < total(ak) || (total(r) == total(ak) && r < ak) { ak = r; } }
    let mut am = z(1000);
    for &(ti, hi) in WEEKS.iter() { for &(tj, hj) in WEEKS.iter() { for s in [1i128, -1] {
        if ti + s * tj == 0 { continue; }
        let r = q(hi + s * hj, ti + s * tj);
        if worst(r) < worst(am) || (worst(r) == worst(am) && r < am) { am = r; }
    } } }
    println!("absolute: LP a {} total {} | every kink a {} total {}", m(la[0]), m(z(0) - l1), m(ak), m(total(ak)));
    println!("errors at a = 3: {}  rates {}  tables in exact weeks {} others {}",
             nums(&WEEKS.iter().map(|&(t, h)| z(h - 3 * t)).collect::<Vec<_>>()),
             nums(&WEEKS.iter().map(|&(t, h)| q(h, t)).collect::<Vec<_>>()),
             WEEKS.iter().filter(|&&(t, h)| h == 3 * t).map(|w| w.0).sum::<i128>(), WEEKS.iter().filter(|&&(t, h)| h != 3 * t).map(|w| w.0).sum::<i128>());
    let below: i128 = -WEEKS.iter().map(|w| w.0).sum::<i128>();
    let above: i128 = WEEKS.iter().map(|&(t, h)| if q(h, t) <= z(3) { t } else { -t }).sum();
    println!("slopes of the total just below and above 3: {} {}", below, above);
    println!("minimax:  LP a {} worst {} | every crossing a {} worst {}", m(ma[0]), m(z(0) - mm), m(am), m(worst(am)));
    let cert = q(3, 5) * z(80) - q(2, 5) * z(90);
    println!("weights 3/5 on week 3, 2/5 on week 2 give, for every a: {} - {} = {}", m(q(3, 5) * z(80)), m(q(2, 5) * z(90)), m(cert));
    let ls = q(WEEKS.iter().map(|&(t, h)| t * h).sum(), WEEKS.iter().map(|&(t, _)| t * t).sum());
    let ((_, la2), (mm2, ma2)) = fits(&[(10, 30), (30, 90), (20, 100), (25, 75), (15, 46)]);
    println!("least squares a {} | bad week at 100 h: absolute a {} minimax a {} worst {}", m(ls), m(la2[0]), m(ma2[0]), m(z(0) - mm2));

    assert!(v1 == z(872) && v2 == v1 && v3 == v1 && x1 == qv(&[28, 18, 10, 0]) && h3 == z(10));   // three roads
    assert!(bound == v1 && yy.iter().all(|&p| p >= z(0)) && red.iter().all(|&r| r >= z(0)));    // prices certify
    assert!(v0 == z(856) && z(19) * dt + z(20) * dc == y[0]);                                      // labour 3.60
    assert!(b1 - (z(19) * xb1[0] + z(20) * xb1[1] - true_cost(xb1[2] + xb1[3], 2, 1, 10)) == z(10));
    assert!(la[0] == z(3) && ak == z(3) && z(0) - l1 == total(z(3)) && ma[0] == q(17, 5) && am == ma[0] && z(0) - mm == worst(am) && worst(am) == z(12));
    assert!(cert == z(0) - mm);                                                                    // weights certify 12
    println!("ALL CHECKS PASS");
}
