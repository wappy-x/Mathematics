// Baker-Campbell-Hausdorff in outline -- the same check as the Python, in Rust.
// No crates.  A camera gimbal pans 10 deg (about its down axis) and tilts
// 5 deg down (about its right axis), each about the camera's own current axes,
// in both orders.  Axes north, east, down; a turn is a rotation vector w, its
// generator the skew matrix [w]x.  Roads: exp by power series against the closed
// form; log by power series against the closed form; the BCH series against the
// exact log, with errors that shrink by 4, 8, 32 when the nudges are halved.
use std::f64::consts::PI;
type M3 = [[f64; 3]; 3];
type V3 = [f64; 3];
const D: f64 = PI / 180.0;
const AS: f64 = 3600.0 * 180.0 / PI;
const I3: M3 = [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]];

fn mul(a: &M3, b: &M3) -> M3 {
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { c[i][j] = (0..3).map(|k| a[i][k] * b[k][j]).sum() } }
    c
}
fn lin(a: &M3, b: &M3, s: f64) -> M3 {
    let mut c = *a;
    for i in 0..3 { for j in 0..3 { c[i][j] += s * b[i][j] } }
    c
}
fn tp(a: &M3) -> M3 {
    let mut c = *a;
    for i in 0..3 { for j in 0..3 { c[i][j] = a[j][i] } }
    c
}
fn hat(w: V3) -> M3 { [[0.0, -w[2], w[1]], [w[2], 0.0, -w[0]], [-w[1], w[0], 0.0]] }
fn vee(k: &M3) -> V3 { [(k[2][1] - k[1][2]) / 2.0, (k[0][2] - k[2][0]) / 2.0, (k[1][0] - k[0][1]) / 2.0] }
fn cross(u: V3, v: V3) -> V3 { [u[1] * v[2] - u[2] * v[1], u[2] * v[0] - u[0] * v[2], u[0] * v[1] - u[1] * v[0]] }
fn add(u: V3, v: V3) -> V3 { [u[0] + v[0], u[1] + v[1], u[2] + v[2]] }
fn sc(s: f64, v: V3) -> V3 { [s * v[0], s * v[1], s * v[2]] }
fn norm(v: V3) -> f64 { (v[0] * v[0] + v[1] * v[1] + v[2] * v[2]).sqrt() }
fn gap(a: &M3, b: &M3) -> f64 {
    let mut g: f64 = 0.0;
    for i in 0..3 { for j in 0..3 { g = g.max((a[i][j] - b[i][j]).abs()) } }
    g
}
fn br(a: &M3, b: &M3) -> M3 { lin(&mul(a, b), &mul(b, a), -1.0) } // the bracket [A, B] = AB - BA

fn exp_series(k: &M3) -> M3 {                         // road one: I + K + K^2/2! + ...
    let (mut s, mut p) = (I3, I3);
    for n in 1..40 {
        p = mul(&p, k);
        for row in p.iter_mut() { for x in row.iter_mut() { *x /= n as f64 } }
        s = lin(&s, &p, 1.0);
    }
    s
}
fn exp_closed(w: V3) -> M3 {                          // road two: Rodrigues' formula
    let (t, k) = (norm(w), hat(w));
    if t == 0.0 { return I3 }
    lin(&lin(&I3, &k, t.sin() / t), &mul(&k, &k), (1.0 - t.cos()) / (t * t))
}
fn log_closed(r: &M3) -> V3 {                         // road one: angle from the trace, axis from the skew part
    let t = ((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0).clamp(-1.0, 1.0).acos();
    if t > 1e-12 { sc(t / t.sin(), vee(r)) } else { vee(r) }
}
fn log_series(r: &M3, n: usize) -> M3 {               // road two: M - M^2/2 + M^3/3 - ..., M = R - I
    let m = lin(r, &I3, -1.0);
    let (mut s, mut p) = ([[0.0; 3]; 3], I3);
    for k in 1..=n {
        p = mul(&p, &m);
        let sign = if k % 2 == 1 { 1.0 } else { -1.0 };
        s = lin(&s, &p, sign / k as f64);
    }
    s
}
fn bch(u: V3, v: V3, order: usize) -> V3 {            // the series, with [[u]x, [v]x] = [u x v]x
    let terms = [add(u, v), sc(0.5, cross(u, v)),
                 sc(1.0 / 12.0, add(cross(u, cross(u, v)), cross(v, cross(v, u))))];
    terms[..order].iter().fold([0.0; 3], |acc, t| add(acc, *t))
}
fn miss(z: V3, r: &M3) -> f64 { norm(log_closed(&mul(&exp_closed(sc(-1.0, z)), r))) * AS } // turn angle, arcsec
fn v3(w: V3) -> String { format!("({:.6}, {:.6}, {:.6})", w[0] / D, w[1] / D, w[2] / D) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let (a, b) = (10.0 * D, 5.0 * D);
    let (u, v): (V3, V3) = ([0.0, 0.0, a], [0.0, -b, 0.0]); // pan right 10 deg, tilt down 5 deg
    let scaled = |s: f64, k: usize| -> f64 {          // order-k miss with both nudges times s, arcsec
        let (us, vs) = (sc(s, u), sc(s, v));
        miss(bch(us, vs, k), &mul(&exp_closed(us), &exp_closed(vs)))
    };
    let (x, y) = (hat(u), hat(v));
    let (p, t) = (exp_series(&x), exp_series(&y));
    let (pt, tpm) = (mul(&p, &t), mul(&t, &p));       // pan then tilt; tilt then pan
    println!("pan {:.6} rad, tilt {:.6} rad; exp series = closed form below 1e-12: {}", a, -b,
             yn(gap(&p, &exp_closed(u)) < 1e-12 && gap(&t, &exp_closed(v)) < 1e-12));
    for (name, r) in [("pan then tilt", &pt), ("tilt then pan", &tpm)] {
        println!("{}: camera points ({:.6}, {:.6}, {:.6}), horizon lean {:.6} deg",
                 name, r[0][0], r[1][0], r[2][0], r[2][1].atan2(r[2][2]) / D);
    }
    let aim = (0..3).map(|i| pt[i][0] * tpm[i][0]).sum::<f64>().acos();
    println!("the two aims differ by {:.6} deg; the orders differ by a turn of {:.6} deg",
             aim / D, norm(log_closed(&mul(&tp(&tpm), &pt))) / D);
    let (z, zs) = (log_closed(&pt), vee(&log_series(&pt, 40)));
    println!("Z = log(pan then tilt), deg: {}; log series agrees below 1e-12: {}", v3(z), yn(norm(add(z, sc(-1.0, zs))) < 1e-12));
    println!("exp(Z) rebuilds pan then tilt below 1e-12: {}", yn(gap(&exp_series(&hat(z)), &pt) < 1e-12));
    println!("[X, Y] as matrices equals [u x v]x below 1e-15: {}", yn(gap(&br(&x, &y), &hat(cross(u, v))) < 1e-15));
    println!("u x v, deg: {}; a times b = {:.6} deg of roll", v3(cross(u, v)), a * b / D);
    let err: Vec<f64> = (1..=3).map(|k| miss(bch(u, v, k), &pt)).collect();
    for k in 1..=3 {
        println!("BCH to order {}, deg {}: misses by {:.4} arcsec", k, v3(bch(u, v, k)), err[k - 1]);
    }
    println!("Z for tilt then pan, deg: {}", v3(log_closed(&tpm)));
    let c = mul(&pt, &mul(&exp_series(&hat(sc(-1.0, u))), &exp_series(&hat(sc(-1.0, v))))); // pan, tilt, unpan, untilt
    println!("pan, tilt, unpan, untilt leaves, deg: {}; [X, Y] predicts {}", v3(log_closed(&c)), v3(cross(u, v)));
    let mut rat: Vec<Vec<f64>> = Vec::new();
    for s in [1.0, 0.5, 0.25] {
        rat.push((1..=3).map(|k| scaled(s, k)).collect());
        let q = &rat[rat.len() - 1];
        println!("nudges x {:.2}: orders 1, 2, 3 miss by {:.4}, {:.4}, {:.4} arcsec", s, q[0], q[1], q[2]);
    }
    let r: Vec<f64> = (0..3).map(|k| rat[0][k] / rat[1][k]).collect();
    println!("halving the nudges divides the misses by {:.3}, {:.3}, {:.3}; order-4 term -[Y, [X, [X, Y]]]/24 here: {:.6}",
             r[0], r[1], r[2], norm(cross(v, cross(u, cross(u, v)))) / 24.0);
    for (k, label) in [(1, "X + Y misses"), (2, "with the bracket")] {
        let pts: Vec<String> = (0..=20).step_by(4).map(|p| format!("{:.4}", scaled(p as f64 / 10.0, k) / 3600.0)).collect();
        println!("chart, pan 0..20 by 4, {}, deg: {}", label, pts.join(", "));
    }
    let u2: V3 = [0.0, 0.0, 5.0 * D];
    println!("mistake 1, two pans 10 and 5 deg: bracket {:.6}, X + Y misses by {:.4} arcsec",
             norm(cross(u, u2)), miss(add(u, u2), &mul(&p, &exp_closed(u2))));
    println!("mistake 2, bracket dropped: misses by {:.4} arcsec", err[0]);
    println!("mistake 3, bracket sign flipped: misses by {:.4} arcsec", miss(add(add(u, v), sc(-0.5, cross(u, v))), &pt));
    let (uu, vv): (V3, V3) = ([0.0, 0.0, 90.0 * D], [0.0, -90.0 * D, 0.0]);
    let bb = mul(&exp_closed(uu), &exp_closed(vv));
    let grow: Vec<f64> = [5, 10, 20].iter().map(|&n| norm(vee(&log_series(&bb, n))) / D).collect();
    println!("mistake 4, pan 90 then tilt 90: one turn of {:.4} deg; BCH order 3 misses by {:.4} deg; log series after 5, 10, 20 terms: {:.1}, {:.1}, {:.1} deg",
             norm(log_closed(&bb)) / D, miss(bch(uu, vv, 3), &bb) / 3600.0, grow[0], grow[1], grow[2]);
    let rad: Vec<f64> = [&pt, &bb].iter().map(|r| 2.0 * (norm(log_closed(r)) / 2.0).sin()).collect(); // size of each eigenvalue of R - I
    println!("log series needs 2 sin(angle/2) below 1: house {:.4}, 90 then 90 {:.4}; pan + tilt {:.6} rad against ln 2 = {:.6}",
             rad[0], rad[1], a + b, 2f64.ln());
    assert!(norm(add(z, sc(-1.0, zs))) < 1e-12);                     // two roads to the log agree
    assert!(gap(&br(&x, &y), &hat(cross(u, v))) < 1e-15);            // matrix bracket = cross product
    assert!(err[0] > 10.0 * err[1] && err[1] > 100.0 * err[2]);      // each order shrinks the miss
    assert!((err[0] / 3600.0 - a * b / 2.0 / D).abs() < 0.001);      // first miss is half the bracket
    assert!(3.8 < r[0] && r[0] < 4.2 && 7.6 < r[1] && r[1] < 8.4 && 30.0 < r[2] && r[2] < 34.0); // s^2, s^3, s^5
    assert!((log_closed(&c)[0] - a * b).abs() < 0.01 * a * b);       // the loop leaves the bracket's roll
    assert!(grow[2] > 10.0 * grow[1] && grow[1] > 2.0 * grow[0] && rad[1] > 1.0); // past the radius the series runs away
    println!("ALL CHECKS PASS");
}
