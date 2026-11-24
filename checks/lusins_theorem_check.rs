// Lusin's theorem -- the check behind the card.  std only.
// Exact fractions (i128) throughout; the same two roads as the Python:
// Dirichlet: merge the deleted intervals, against the geometric sum minus
//   the parts outside [0, 1].
// Tariff: the triangle formula |J| w / 4 per jump, against a midpoint sum on
//   a grid that every corner of |s - g| lines up with.
use std::cmp::Ordering;
use std::ops::{Add, Div, Mul, Sub};

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, Debug, PartialEq, Eq)]
struct Q { n: i128, d: i128 }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q { n: n / g, d: d / g } }
fn z(n: i128) -> Q { q(n, 1) }
impl Add for Q { type Output = Q; fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) } }
impl Sub for Q { type Output = Q; fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) } }
impl Mul for Q { type Output = Q; fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) } }
impl Div for Q { type Output = Q; fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) } }
impl PartialOrd for Q { fn partial_cmp(&self, o: &Q) -> Option<Ordering> { Some(self.cmp(o)) } }
impl Ord for Q { fn cmp(&self, o: &Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) } }
fn abs(x: Q) -> Q { q(x.n.abs(), x.d) }
fn mx(a: Q, b: Q) -> Q { if a > b { a } else { b } }
fn mn(a: Q, b: Q) -> Q { if a < b { a } else { b } }

fn dec(x: Q) -> String {                     // exact decimal, rounded half up
    let sign = if x.n < 0 { "-" } else { "" };
    let p = 10i128.pow(10);
    let m = (x.n.abs() * p * 2 + x.d) / (2 * x.d);
    let s = format!("{}.{:010}", m / p, m % p);
    format!("{}{}", sign, s.trim_end_matches('0').trim_end_matches('.'))
}
fn qstr(x: Q) -> String { if x.d == 1 { format!("{}", x.n) } else { format!("{}/{}", x.n, x.d) } }

fn rationals(qmax: i128) -> Vec<Q> {         // 0, 1, then p/q by denominator
    let mut out = vec![z(0), z(1)];
    for b in 2..=qmax { for a in 1..b { if gcd(a, b) == 1 { out.push(q(a, b)); } } }
    out
}
fn merged_length(c: &[Q], width: &dyn Fn(usize) -> Q) -> Q {
    let half = z(2);
    let mut iv: Vec<(Q, Q)> = c.iter().enumerate()
        .map(|(k, &x)| (mx(z(0), x - width(k + 1) / half), mn(z(1), x + width(k + 1) / half))).collect();
    iv.sort();
    let (mut total, mut lo, mut hi) = (z(0), iv[0].0, iv[0].1);
    for &(a, b) in &iv[1..] {
        if a > hi { total = total + hi - lo; lo = a; hi = b; } else { hi = mx(hi, b); }
    }
    total + hi - lo
}
fn totient(n: i128) -> i128 {
    let (mut r, mut m, mut p) = (n, n, 2);
    while p * p <= m {
        if m % p == 0 { r -= r / p; while m % p == 0 { m /= p; } }
        p += 1;
    }
    if m > 1 { r - r / m } else { r }
}
fn farey(n: i128) -> (i128, i128) {
    let (mut a, mut b, mut c, mut d, mut count, mut small) = (0, 1, 1, n, 2, n);
    while (c, d) != (1, 1) {
        let k = (n + b) / d;
        let (na, nb, nc, nd) = (c, d, k * c - a, k * d - b);
        a = na; b = nb; c = nc; d = nd;
        count += 1; small = small.min(b * d);
    }
    (count, small)
}
fn s_at(x: Q, base: Q, j: &[(Q, Q)]) -> Q { j.iter().fold(base, |t, &(c, jj)| if x >= c { t + jj } else { t }) }
fn g_at(x: Q, base: Q, j: &[(Q, Q)], w: Q) -> Q {
    j.iter().fold(base, |t, &(c, jj)| t + jj * mn(z(1), mx(z(0), (x - c + w / z(2)) / w)))
}
fn gap_by_grid(base: Q, j: &[(Q, Q)], w: Q, lo: Q, hi: Q, h: Q) -> (Q, Q, i128) {
    let r = (hi - lo) / h;
    let n = r.n / r.d;
    let (mut area, mut top) = (z(0), z(0));
    for k in 0..n {
        let x = lo + (z(k) + q(1, 2)) * h;
        area = area + abs(s_at(x, base, j) - g_at(x, base, j, w));
    }
    for k in 0..=n {
        let x = lo + z(k) * h;
        top = mx(top, abs(s_at(x, base, j) - g_at(x, base, j, w)));
    }
    (area * h, top, n)
}
fn gap_by_formula(j: &[(Q, Q)], w: Q) -> (Q, Q) {
    let sum = j.iter().fold(z(0), |t, &(_, jj)| t + abs(jj));
    let top = j.iter().fold(z(0), |t, &(_, jj)| mx(t, abs(jj)));
    (sum * w / z(4), top / z(2))
}

fn main() {
    // ---- Dirichlet: delete width eps * 2^-n around the n-th rational ----
    let eps = q(1, 100);
    let width = move |k: usize| eps / z(1i128 << k);
    let q8 = rationals(8);
    let first: Vec<String> = q8[..5].iter().map(|&x| qstr(x)).collect();
    let d_merge = merged_length(&q8, &width);
    let outside = width(1) / z(2) + width(2) / z(2);
    let d_sum = eps * (z(1) - q(1, 1i128 << q8.len())) - outside;
    let bound = |e: Q| e - e / z(4) - e / z(8);
    assert!(d_merge == d_sum && bound(eps) - d_merge == eps / z(1i128 << q8.len()));
    println!("Dirichlet on [0, 1]: delete width 0.01 * 2^-n around the n-th rational");
    println!("denominator up to 8: {} rationals; first five {}", q8.len(), first.join(", "));
    let ws: Vec<String> = (1..6).map(|k| dec(width(k))).collect();
    println!("widths of the first five: {}", ws.join(", "));
    println!("deleted, first 23, by merging: {}; by the sum: {}", dec(d_merge), dec(d_sum));
    println!("deleted, every rational, at most {}; closed set left at least {}", dec(bound(eps)), dec(z(1) - bound(eps)));

    // ---- the tariff: 10, then 30 from 1/3, then 20 from 2/3 cents per kWh ----
    let w = q(1, 2000);
    let tariff = [(q(1, 3), z(20)), (q(2, 3), z(-10))];
    let (area, top, n) = gap_by_grid(z(10), &tariff, w, z(0), z(1), q(1, 12000));
    let (f_area, f_top) = gap_by_formula(&tariff, w);
    assert!(area == f_area && top == f_top);
    println!("tariff: gaps {} at 1/3 and 2/3, kept length {}", dec(w), dec(z(1) - z(2) * w));
    println!("integral |s - g|: triangles {}; grid of {} cells {}", dec(f_area), n, dec(area));
    println!("largest |s - g|: J/2 gives {}; grid gives {}", dec(f_top), dec(top));

    // ---- continuous with compact support, close in L1: the tariff on the line ----
    let line = [(z(0), z(10)), tariff[0], tariff[1], (z(1), z(-20))];
    let (l_area, _, _) = gap_by_grid(z(0), &line, w, q(-1, 1000), q(1001, 1000), q(1, 12000));
    assert!(l_area == gap_by_formula(&line, w).0 && l_area < z(60) * z(4) * w);
    println!("line: h is 0 outside [{}, {}]; integral |s - h| {}; grid {}; proof's bound 60 x {} = {}",
        dec(z(0) - w / z(2)), dec(z(1) + w / z(2)), dec(gap_by_formula(&line, w).0), dec(l_area),
        dec(z(4) * w), dec(z(60) * z(4) * w));

    // ---- what breaks ----
    let q100 = rationals(100);
    let (f_count, small) = farey(100);
    let tot = 1 + (1..=100).map(totient).sum::<i128>();
    let fixed = merged_length(&q100, &move |_| eps);
    assert!(f_count == tot && tot == q100.len() as i128 && small >= 100 && fixed == z(1));
    println!("break, width 0.01 for all: {} rationals with denominator up to 100, widest neighbour gap {}, deleted {}",
        tot, dec(q(1, small)), dec(fixed));
    let cut: Vec<(Q, Q)> = q8.iter().enumerate()
        .map(|(k, &c)| (c - width(k + 1) / z(2), c + width(k + 1) / z(2))).collect();
    let left = q100.iter().filter(|&&x| !cut.iter().any(|&(a, b)| a < x && x < b)).count() as i128;
    assert!(left == tot - q8.len() as i128);
    println!("break, first 23 only: rationals up to denominator 100 left {} = {} - 23", left, tot);
    let fine = gap_by_grid(z(10), &tariff, w / z(10), z(0), z(1), q(1, 120000));
    assert!((fine.0, fine.1) == gap_by_formula(&tariff, w / z(10)));
    println!("break, sup reading: largest |s - g| {} at gap 0.0005, {} at gap 0.00005", dec(top), dec(fine.1));

    // ---- try changing ----
    let e2 = q(1, 1000);
    println!("try, eps 0.001: deleted at most {}, left at least {}", dec(bound(e2)), dec(z(1) - bound(e2)));
    println!("try, gap 0.00005: integral |s - g| {}", dec(fine.0));
    let w3 = q(1, 1000) / z(15);
    let a3 = gap_by_grid(z(0), &line, w3, q(-1, 1000), q(1001, 1000), q(1, 30000)).0;
    assert!(a3 == q(1, 1000));
    println!("try, target 0.001 on the line: gap 1/15000 = {}, integral |s - h| {}", dec(w3), dec(a3));
    let peak = [(q(1, 3), z(40)), (q(2, 3), z(-30))];
    let (a4, t4, _) = gap_by_grid(z(10), &peak, w, z(0), z(1), q(1, 12000));
    assert!((a4, t4) == gap_by_formula(&peak, w));
    println!("try, peak 50: integral |s - g| {}, largest gap {}", dec(a4), dec(t4));
    println!("ALL CHECKS PASS");
}
