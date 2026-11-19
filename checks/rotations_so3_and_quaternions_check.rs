// Rotation group: three-dimensional turns and the four-number shortcut -- the same check as the
// Python, in Rust.  No crates.  A drone camera's orientation, axes north, east, down, is held three
// ways: a 3 x 3 rotation matrix R, an axis and angle, and a unit quaternion q = (w, x, y, z), scalar
// first, with ij = k, turning a vector v to q v q-bar.  The pan between two shots is blended by slerp.
// Roads: matrix and quaternion built separately from the same angles; the quaternion read back from
// the matrix and from axis-angle; slerp against the matrix route R_A exp(t log(R_A^T R_B)); slerp
// against many small gyro-style steps q <- q (1 + w h / 2), renormalised.
use std::f64::consts::PI;
type M = [[f64; 3]; 3];
type Q = [f64; 4];
const D: f64 = PI / 180.0;

fn mul(a: &M, b: &M) -> M {
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { c[i][j] = (0..3).map(|k| a[i][k] * b[k][j]).sum(); } }
    c
}
fn tp(a: &M) -> M { let mut c = [[0.0; 3]; 3]; for i in 0..3 { for j in 0..3 { c[i][j] = a[j][i]; } } c }
fn rx(a: f64) -> M { [[1.0, 0.0, 0.0], [0.0, a.cos(), -a.sin()], [0.0, a.sin(), a.cos()]] }
fn ry(a: f64) -> M { [[a.cos(), 0.0, a.sin()], [0.0, 1.0, 0.0], [-a.sin(), 0.0, a.cos()]] }
fn rz(a: f64) -> M { [[a.cos(), -a.sin(), 0.0], [a.sin(), a.cos(), 0.0], [0.0, 0.0, 1.0]] }
fn euler(s: [f64; 3]) -> M { mul(&rz(s[0] * D), &mul(&ry(s[1] * D), &rx(s[2] * D))) }  // heading, tilt, roll (degrees)
fn det3(a: &M) -> f64 {
    a[0][0] * (a[1][1] * a[2][2] - a[1][2] * a[2][1]) - a[0][1] * (a[1][0] * a[2][2] - a[1][2] * a[2][0])
        + a[0][2] * (a[1][0] * a[2][1] - a[1][1] * a[2][0])
}
fn qmul(a: Q, b: Q) -> Q {                        // Hamilton's product, from i^2 = j^2 = k^2 = ijk = -1
    [a[0] * b[0] - a[1] * b[1] - a[2] * b[2] - a[3] * b[3], a[0] * b[1] + a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
     a[0] * b[2] - a[1] * b[3] + a[2] * b[0] + a[3] * b[1], a[0] * b[3] + a[1] * b[2] - a[2] * b[1] + a[3] * b[0]]
}
fn qbar(q: Q) -> Q { [q[0], -q[1], -q[2], -q[3]] }
fn neg(q: Q) -> Q { [-q[0], -q[1], -q[2], -q[3]] }
fn qaxis(u: [f64; 3], t: f64) -> Q { let s = (t / 2.0).sin(); [(t / 2.0).cos(), u[0] * s, u[1] * s, u[2] * s] }
fn qeuler(s: [f64; 3]) -> Q {
    qmul(qaxis([0.0, 0.0, 1.0], s[0] * D), qmul(qaxis([0.0, 1.0, 0.0], s[1] * D), qaxis([1.0, 0.0, 0.0], s[2] * D)))
}
fn turn(q: Q, v: [f64; 3]) -> [f64; 3] {          // v -> q v q-bar
    let r = qmul(qmul(q, [0.0, v[0], v[1], v[2]]), qbar(q));
    [r[1], r[2], r[3]]
}
fn qmat(q: Q) -> M {                              // column j of R is where axis j goes under q v q-bar
    let cols = [turn(q, [1.0, 0.0, 0.0]), turn(q, [0.0, 1.0, 0.0]), turn(q, [0.0, 0.0, 1.0])];
    tp(&cols)
}
fn rodrigues(u: [f64; 3], t: f64) -> M {          // R = I + sin t [u]x + (1 - cos t) [u]x^2
    let k = [[0.0, -u[2], u[1]], [u[2], 0.0, -u[0]], [-u[1], u[0], 0.0]];
    let k2 = mul(&k, &k);
    let mut r = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { r[i][j] = (if i == j { 1.0 } else { 0.0 }) + t.sin() * k[i][j] + (1.0 - t.cos()) * k2[i][j]; } }
    r
}
fn axis_angle(r: &M) -> ([f64; 3], f64) {         // trace gives the angle, the skew part the axis (0 < t < 180 deg)
    let t = ((r[0][0] + r[1][1] + r[2][2] - 1.0) / 2.0).acos();
    let s = 2.0 * t.sin();
    ([(r[2][1] - r[1][2]) / s, (r[0][2] - r[2][0]) / s, (r[1][0] - r[0][1]) / s], t)
}
fn q_from_mat(r: &M) -> Q {                       // valid while the trace is above -1
    let w = (1.0 + r[0][0] + r[1][1] + r[2][2]).sqrt() / 2.0;
    [w, (r[2][1] - r[1][2]) / (4.0 * w), (r[0][2] - r[2][0]) / (4.0 * w), (r[1][0] - r[0][1]) / (4.0 * w)]
}
fn dot4(a: Q, b: Q) -> f64 { (0..4).map(|i| a[i] * b[i]).sum() }
fn slerp(a: Q, b: Q, t: f64) -> Q {               // flip b if needed, so the blend takes the short way
    let b = if dot4(a, b) < 0.0 { neg(b) } else { b };
    let om = dot4(a, b).min(1.0).acos();
    let mut q = [0.0; 4];
    for i in 0..4 { q[i] = (((1.0 - t) * om).sin() * a[i] + (t * om).sin() * b[i]) / om.sin(); }
    q
}
fn gap(a: Q, b: Q) -> f64 { 2.0 * dot4(a, b).abs().min(1.0).acos() / D }   // angle of the turn from a to b, degrees
fn hpr(r: &M) -> [f64; 3] { [r[1][0].atan2(r[0][0]) / D, (-r[2][0]).asin() / D, r[2][1].atan2(r[2][2]) / D] }
fn mgap(a: &M, b: &M) -> f64 { let mut g: f64 = 0.0; for i in 0..3 { for j in 0..3 { g = g.max((a[i][j] - b[i][j]).abs()); } } g }
fn f4(x: f64) -> String { format!("{:.4}", if x.abs() < 5e-5 { 0.0 } else { x }) }
fn f2(x: f64) -> String { format!("{:.2}", if x.abs() < 5e-3 { 0.0 } else { x }) }
fn fl(v: &[f64]) -> String { v.iter().map(|&x| f4(x)).collect::<Vec<_>>().join(" ") }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn shot(s: [f64; 3]) -> String { format!("({}, {}, {})", s[0], s[1], s[2]) }
fn mid3(a: [f64; 3], b: [f64; 3], t: f64) -> [f64; 3] { [a[0] + t * (b[0] - a[0]), a[1] + t * (b[1] - a[1]), a[2] + t * (b[2] - a[2])] }

fn main() {
    let shots = [("A", [30.0, -10.0, 0.0]), ("B", [120.0, -40.0, 0.0])];  // heading, tilt (negative = down), roll
    let (sa, sb) = (shots[0].1, shots[1].1);
    let mut worst: f64 = 0.0;
    for (s, a) in shots.iter() {
        let (r, q) = (euler(*a), qeuler(*a));
        let (u, t) = axis_angle(&r);
        println!("shot {} {}: R rows {}", s, shot(*a), r.iter().map(|row| fl(row)).collect::<Vec<_>>().join(" | "));
        println!("shot {}: q from angles {}; q from R {}", s, fl(&q), fl(&q_from_mat(&r)));
        println!("shot {}: axis {}, angle {} deg; q from axis-angle {}", s, fl(&u), f4(t / D), fl(&qaxis(u, t)));
        let look = turn(q, [1.0, 0.0, 0.0]);
        println!("shot {}: camera looks along {}", s, fl(&look));
        let (qr, qa) = (q_from_mat(&r), qaxis(u, t));
        for i in 0..4 { worst = worst.max((qr[i] - q[i]).abs()).max((qa[i] - q[i]).abs()); }
        for i in 0..3 { worst = worst.max((look[i] - r[i][0]).abs()); }
        worst = worst.max(mgap(&qmat(q), &r));
    }
    println!("matrix, axis-angle and quaternion agree, worst gap below 1e-12: {}", yn(worst < 1e-12));
    let (ra, rb, qa, qb) = (euler(sa), euler(sb), qeuler(sa), qeuler(sb));
    let d = dot4(qa, qb);
    let total = gap(qa, qb);
    println!("qA . qB = {} = {}; half-angle {} deg; the pan turns the camera {} deg", (0..4).map(|i| f4(qa[i] * qb[i])).collect::<Vec<_>>().join(" + "), f4(d), f4(d.acos() / D), f4(total));
    let mid = slerp(qa, qb, 0.5);
    let sum = [qa[0] + qb[0], qa[1] + qb[1], qa[2] + qb[2], qa[3] + qb[3]];
    let n = dot4(sum, sum).sqrt();
    println!("shot A pieces: heading 30 gives {}; tilt -10 gives {}", fl(&qaxis([0.0, 0.0, 1.0], 30.0 * D)), fl(&qaxis([0.0, 1.0, 0.0], -10.0 * D)));
    println!("qA + qB = {}, length {}; 2 cos(half-angle / 2) = {}", fl(&sum), f4(n), f4(2.0 * (d.acos() / 2.0).cos()));
    let (ur, tr) = axis_angle(&mul(&tp(&ra), &rb));
    let mut road: f64 = 0.0;
    for t in [0.0, 0.25, 0.5, 0.75, 1.0] {
        let q = slerp(qa, qb, t);
        let rm = mul(&ra, &rodrigues(ur, t * tr));  // the matrix route, R_A exp(t log(R_A^T R_B))
        road = road.max(mgap(&qmat(q), &rm));
        println!("slerp t = {:.2}: q {}; heading, tilt, roll {}", t, fl(&q), fl(&hpr(&qmat(q))));
    }
    println!("slerp against the matrix route, worst gap below 1e-12: {}", yn(road < 1e-12));
    let mgap4 = (0..4).map(|i| ((qa[i] + qb[i]) / n - mid[i]).abs()).fold(0.0, f64::max);
    println!("midpoint is (qA + qB) / |qA + qB|, gap below 1e-12: {}", yn(mgap4 < 1e-12));
    let times: Vec<f64> = (0..9).map(|k| k as f64 / 8.0).collect();
    let blend = |t: f64| qeuler(mid3(sa, sb, t));
    let s_ang: Vec<f64> = times.iter().map(|&t| gap(qa, slerp(qa, qb, t))).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("seconds into a 4 s pan:     {}", join(times.iter().map(|t| format!("{:.1}", 4.0 * t)).collect()));
    println!("slerp horizon roll, deg:    {}", join(times.iter().map(|&t| f2(hpr(&qmat(slerp(qa, qb, t)))[2])).collect()));
    println!("slerp to blended, deg:      {}", join(times.iter().map(|&t| f2(gap(slerp(qa, qb, t), blend(t)))).collect()));
    let paths: Vec<f64> = [1000usize, 2000].iter().map(|&m| (1..=m).map(|k| gap(blend((k - 1) as f64 / m as f64), blend(k as f64 / m as f64))).sum()).collect();
    println!("turning done by blended angles, 1000 and 2000 samples: {} {} deg; slerp {} deg", f4(paths[0]), f4(paths[1]), f4(total));
    let rel = qmul(qbar(qa), qb);
    let w: Vec<f64> = (1..4).map(|i| 2.0 * d.acos() * rel[i] / (1.0 - d * d).sqrt()).collect();  // body rate, rad per pan
    let mut errs = Vec::new();
    for nn in [100usize, 1000] {
        let mut q = qa;
        let h = 2.0 * nn as f64;
        for _ in 0..nn / 2 {
            q = qmul(q, [1.0, w[0] / h, w[1] / h, w[2] / h]);
            let l = dot4(q, q).sqrt();
            q = [q[0] / l, q[1] / l, q[2] / l, q[3] / l];
        }
        errs.push(gap(q, mid));
        println!("gyro steps, {} per pan, at mid-pan: off slerp by {:.7} deg", nn, errs[errs.len() - 1]);
    }
    let mut avg = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { avg[i][j] = (ra[i][j] + rb[i][j]) / 2.0; } }
    println!("mistake 1, matrices averaged entry by entry: det {}", f4(det3(&avg)));
    println!("mistake 2, blend toward -qB unflipped: swings {} deg; (qA + (-qA)) / 2 = {}", f4(2.0 * (-d).acos() / D),
             fl(&qa.iter().map(|x| (x - x) / 2.0).collect::<Vec<_>>()));
    let em = qeuler(mid3(sa, sb, 0.5));
    println!("mistake 3, heading, tilt, roll blended: mid-pan is {} deg off slerp", f4(gap(em, mid)));
    let (b1, b2) = ([120.0, -90.0, 0.0], [30.0, -90.0, 90.0]);
    let (l1, l2) = (qeuler(mid3(sa, b1, 0.5)), qeuler(mid3(sa, b2, 0.5)));
    println!("  shot B straight down, named (120, -90, 0) or (30, -90, 90): same shot, gap {} deg; blended midpoints {} deg apart",
             f4(gap(qeuler(b1), qeuler(b2))), f4(gap(l1, l2)));
    let nl: Q = [0, 1, 2, 3].map(|i| qa[i] + 0.25 * (qb[i] - qa[i]));
    let ln = dot4(nl, nl).sqrt();
    println!("mistake 4, straight blend at 1 s: length {}; rescaled, {} deg from A; slerp {} deg", f4(ln),
             f4(gap(qa, nl.map(|c| c / ln))), f4(s_ang[2]));
    let wrong = turn(qbar(qa), [1.0, 0.0, 0.0]);
    println!("mistake 5, q-bar v q for shot A: camera heading {} deg, tilt {} deg", f4(wrong[1].atan2(wrong[0]) / D), f4((-wrong[2]).asin() / D));
    let (ua, ta) = axis_angle(&ra);
    let full = axis_angle(&qmat(qaxis(ua, 2.0 * ta))).1;
    println!("mistake 6, shot A built from cos t and sin t, not the half angles: turns {} deg", f4(full / D));
    println!("q and -q give the same matrix: {}; 360 deg turn q = {}; 720 deg q = {}", yn(mgap(&qmat(qa), &qmat(neg(qa))) < 1e-12),
             fl(&qaxis([0.0, 0.0, 1.0], 2.0 * PI)), fl(&qaxis([0.0, 0.0, 1.0], 4.0 * PI)));
    assert!(worst < 1e-12 && road < 1e-12);                                   // three representations, two blend routes
    assert!(s_ang.iter().zip(&times).all(|(a, t)| (a - total * t).abs() < 1e-9));  // slerp turns at a constant rate
    assert!(errs[1] < errs[0] / 50.0 && errs[1] < 1e-3);                      // gyro steps close in on slerp
    assert!((n - 2.0 * (d.acos() / 2.0).cos()).abs() < 1e-12);                // the midpoint by hand
    assert!((full - 2.0 * ta).abs() < 1e-9);                                  // q carries half the angle
    assert!(det3(&avg).abs() < 0.9 && gap(em, mid) > 1.0 && gap(l1, l2) > 1.0 && paths[1] > total + 1.0);
    println!("ALL CHECKS PASS");
}
