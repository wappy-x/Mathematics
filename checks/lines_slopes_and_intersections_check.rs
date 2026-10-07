// Lines, slopes and intersections -- the same check as the Python, in Rust.
// No crates.  A city grid in km, x east and y north, the depot D at (0, 0).
// Route A runs D to E; route B runs Q to R; ring road C runs beside route A.
// The junction is found by two roads that share no arithmetic.
type P = (f64, f64);
type L = (f64, f64, f64);                 // a, b, p in ax + by = p

fn slope(p1: P, p2: P) -> f64 { (p2.1 - p1.1) / (p2.0 - p1.0) }   // rise over run
fn cross(l1: L, l2: L) -> f64 { l1.0 * l2.1 - l1.1 * l2.0 }       // ad - bc
fn meet(l1: L, l2: L) -> P {                                       // road one: the formula
    let ((a, b, p), (c, d, q)) = (l1, l2);
    ((p * d - b * q) / cross(l1, l2), (a * q - c * p) / cross(l1, l2))
}
fn side(l: L, x: f64, y: f64) -> f64 { l.0 * x + l.1 * y - l.2 } // which side of line l
fn sq(p1: P, p2: P) -> f64 { (p2.0 - p1.0).powi(2) + (p2.1 - p1.1).powi(2) }
fn px(p: P) -> String {
    let r = |v: f64| (v * 10.0).round() / 10.0;
    format!("({}, {})", r(40.0 + 20.0 * p.0), r(210.0 - 20.0 * p.1))
}

fn main() {
    let (d, e, q, r, c0, c1): (P, P, P, P, P, P) =
        ((0.0, 0.0), (10.0, 5.0), (3.0, 9.0), (7.0, 1.0), (0.0, 5.0), (10.0, 10.0));
    let (a, b, c): (L, L, L) = ((1.0, -2.0, 0.0), (2.0, 1.0, 15.0), (1.0, -2.0, -10.0));
    let (mut lo, mut hi) = (0.0_f64, 1.0_f64);  // road two: halve route A until B is crossed
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if side(b, 0.0, 0.0) * side(b, 10.0 * mid, 5.0 * mid) > 0.0 { lo = mid } else { hi = mid }
    }
    let t = (lo + hi) / 2.0;
    let j = meet(a, b);
    let s = (j.0 - q.0) / (r.0 - q.0);
    let (ma, mb, mc) = (slope(d, e), slope(q, r), slope(c0, c1));
    let (ka, kb, kc) = (d.1 - ma * d.0, q.1 - mb * q.0, c0.1 - mc * c0.0);
    let gaps: Vec<f64> = [0.0, 4.0, 8.0].iter().map(|&x| (mc * x + kc) - (ma * x + ka)).collect();
    let (dj, jq, dq) = (sq(d, j), sq(j, q), sq(d, q));
    let u = 0.4 / 5f64.sqrt();                  // 8 drawing units along each road, in km
    let mark = [(j.0 + 2.0 * u, j.1 + u), (j.0 + u, j.1 + 3.0 * u), (j.0 - u, j.1 + 2.0 * u)];
    let (cb, st, wrong) = (meet(c, b), meet(a, (1.0, 0.0, 2.0)), meet((2.0, -1.0, 0.0), b));
    println!("slopes from two points: A {}, B {}, C {}; north-axis crossings {}, {}, {}", ma, mb, mc, ka, kb, kc);
    println!("slopes from general form, -a/b: A {}, B {}, C {}", -a.0 / a.1, -b.0 / b.1, -c.0 / c.1);
    println!("crossing number A with B: {}; A with ring road C: {}", cross(a, b), cross(a, c));
    println!("junction by the formula: x = {}/{} = {}, y = {}/{} = {}", a.2 * b.1 - a.1 * b.2,
             cross(a, b), j.0, a.0 * b.2 - b.0 * a.2, cross(a, b), j.1);
    println!("junction by halving route A: t = {:.6}, point ({:.6}, {:.6})", t, 10.0 * t, 5.0 * t);
    println!("route A put into B: {}t = {}, t = {}; on route B s = {}", b.0 * e.0 + b.1 * e.1, b.2, b.2 / (b.0 * e.0 + b.1 * e.1), s);
    println!("slope product A x B: {}; step dot product (10, 5).(4, -8) = {}", ma * mb,
             (e.0 - d.0) * (r.0 - q.0) + (e.1 - d.1) * (r.1 - q.1));
    println!("Pythagoras: DJ^2 = {}, JQ^2 = {}, DQ^2 = {}", dj, jq, dq);
    println!("ring road C above route A at x = 0, 4, 8: {}, {}, {} km", gaps[0], gaps[1], gaps[2]);
    println!("ring road C meets route B at ({}, {}), s = {}", cb.0, cb.1, (cb.0 - q.0) / (r.0 - q.0));
    println!("street x = 2 meets route A at ({}, {}); crossing number {}", st.0, st.1, cross(a, (1.0, 0.0, 2.0)));
    println!("mistake 1, run over rise: slope {}, junction ({}, {})", 10.0 / 5.0, wrong.0, wrong.1);
    println!("mistake 2, perpendicular to B as 1/m: slope {}, step dot product (1, -2).(1, -0.5) = {}", 1.0 / mb, 1.0 + mb * (1.0 / mb));
    println!("mistake 3, point order mixed on B: {}/{} = {}", r.1 - q.1, q.0 - r.0, (r.1 - q.1) / (q.0 - r.0));
    println!("figure, 20 units per km: D {} E {} Q {} R {} J {} C {} to {}", px(d), px(e), px(q), px(r), px(j), px(c0), px((8.0, 9.0)));
    println!("figure, right-angle marker {}", mark.iter().map(|&m| px(m)).collect::<Vec<_>>().join(" "));
    assert!((j.0 - 10.0 * t).abs() < 1e-9 && (j.1 - 5.0 * t).abs() < 1e-9);   // two roads, one junction
    assert!(ma * mb == -1.0 && dj + jq == dq);                                // right angle two ways
    assert!(cross(a, c) == 0.0 && gaps == vec![5.0, 5.0, 5.0]);               // parallel two ways
    assert!([ma, mb, mc] == [-a.0 / a.1, -b.0 / b.1, -c.0 / c.1]);            // two points vs general form
    println!("ALL CHECKS PASS");
}
