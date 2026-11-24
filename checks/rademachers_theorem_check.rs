// Rademacher's theorem -- the same check as the Python, in Rust.  No crates.
// d(p) = | |p| - 1 | is the distance from p to the unit circle (a round fence of
// radius 1 m); f1(p) = |x| + |y|.  Both are Lipschitz.  The program checks the
// Lipschitz bounds, the gradient two ways, the size of the bad set, the
// test-function identity of Step 2, and the uniform error of Step 3.
use std::f64::consts::PI;

fn hyp(x: f64, y: f64) -> f64 { (x * x + y * y).sqrt() }       // length of (x, y)
fn d(x: f64, y: f64) -> f64 { (hyp(x, y) - 1.0).abs() }
fn f1(x: f64, y: f64) -> f64 { x.abs() + y.abs() }
fn grad_d(x: f64, y: f64) -> (f64, f64) {      // the formula, valid off the circle and origin
    let r = hyp(x, y);
    let s = if r > 1.0 { 1.0 } else { -1.0 };
    (s * x / r, s * y / r)
}
fn central(f: fn(f64, f64) -> f64, x: f64, y: f64) -> (f64, f64) {     // road two: difference quotients only
    let h = 1e-6;
    ((f(x + h, y) - f(x - h, y)) / (2.0 * h), (f(x, y + h) - f(x, y - h)) / (2.0 * h))
}
fn fmt(p: (f64, f64)) -> String { format!("({:.6}, {:.6})", p.0, p.1) }
fn takagi(x: f64) -> f64 {
    let mut s = 0.0;
    for k in 0..60 {
        let p = 2f64.powi(k);
        s += (p * x - (p * x).round()).abs() / p;
    }
    s
}
fn join(v: &[f64]) -> String { v.iter().map(|q| format!("{:.6}", q)).collect::<Vec<_>>().join(", ") }

fn main() {
    let mut state: u64 = 12345;                // a hand-written random number generator
    let mut rnd = || {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (state >> 11) as f64 / 9007199254740992.0 * 4.0 - 2.0
    };
    let (mut best_d, mut best_f) = (0.0f64, 0.0f64);
    for _ in 0..200000 {                       // Lipschitz ratios over random pairs in [-2, 2]^2
        let (px, py, qx, qy) = (rnd(), rnd(), rnd(), rnd());
        let dist = hyp(px - qx, py - qy);
        best_d = best_d.max((d(px, py) - d(qx, qy)).abs() / dist);
        best_f = best_f.max((f1(px, py) - f1(qx, qy)).abs() / dist);
    }
    let r2 = 2f64.sqrt();
    println!("d = distance to the unit circle; f1 = |x| + |y|");
    println!("largest ratio |f(p) - f(q)| / |p - q| over 200000 pairs: d {:.6} (L = 1), f1 {:.6} (L = {:.6})", best_d, best_f, r2);
    assert!(0.99 < best_d && best_d <= 1.0 + 1e-12 && 1.40 < best_f && best_f <= r2 + 1e-12);

    for (name, xs, ys, x, y) in [("A", "1.5", "2.0", 1.5, 2.0), ("B", "0.3", "0.4", 0.3, 0.4)] {
        let (g, c) = (grad_d(x, y), central(d, x, y));
        println!("mower {} = ({}, {}): |p| {:.6}, d {:.6}, grad by formula {}, by difference quotients {}, length {:.6}",
                 name, xs, ys, hyp(x, y), d(x, y), fmt(g), fmt(c), hyp(g.0, g.1));
        assert!((g.0 - c.0).abs() < 1e-6 && (g.1 - c.1).abs() < 1e-6);
    }
    for h in [0.1, 0.01] {                     // the tangent-plane error at A, divided by the step
        let plane = 1.5 + 0.6 * h;
        println!("step ({}, 0) from A: d {:.6}, plane {:.6}, error/step {:.6}", h, d(1.5 + h, 2.0), plane, (d(1.5 + h, 2.0) - plane).abs() / h);
    }
    println!("fence point P = (1, 0), steps +0.1 and -0.1 along x: d {:.6} and {:.6}; every plane misses one by at least {:.6}, error/step {:.6}",
             d(1.1, 0.0), d(0.9, 0.0), (d(1.1, 0.0) + d(0.9, 0.0)) / 2.0, (d(1.1, 0.0) + d(0.9, 0.0)) / 0.2);
    println!("centre O = (0, 0), step 0.1 in any direction: d {:.6}, slope {:.6} every way", d(0.1, 0.0), (d(0.06, 0.08) - d(0.0, 0.0)) / 0.1);
    let t0 = (1.0f64 - 0.25).sqrt();          // the line y = 0.5 meets the circle at x = +-t0
    let g = |t: f64| d(t, 0.5);
    println!("line y = 0.5 meets the bad set at x = {:.6} and {:.6}; slopes at x = {:.6}: left {:.6}, right {:.6}",
             -t0, t0, t0, (g(t0) - g(t0 - 1e-7)) / 1e-7, (g(t0 + 1e-7) - g(t0)) / 1e-7);
    let (lf, rf) = ((f1(0.0, 0.5) - f1(-1e-3, 0.5)) / 1e-3, (f1(1e-3, 0.5) - f1(0.0, 0.5)) / 1e-3);
    let cf = central(f1, 0.5, -0.3);           // off the axes the formula is (sign x, sign y) = (1, -1)
    println!("f1 on the line y = 0.5 at the axis x = 0: slope left {:.6}, right {:.6}; at (0.5, -0.3), off the axes: grad (1, -1) by formula, {} by difference quotients",
             lf, rf, fmt(cf));
    assert!((lf + 1.0).abs() < 1e-9 && (rf - 1.0).abs() < 1e-9 && (cf.0 - 1.0).abs() < 1e-6 && (cf.1 + 1.0).abs() < 1e-6);

    let m = 1000usize;                         // grid fraction of [-2, 2]^2 within h of the bad set
    for h in [0.2, 0.1, 0.05] {
        let mut hits = 0usize;
        for i in 0..m {
            for j in 0..m {
                let x = -2.0 + 4.0 * (i as f64 + 0.5) / m as f64;
                let y = -2.0 + 4.0 * (j as f64 + 0.5) / m as f64;
                let r = hyp(x, y);
                if (r - 1.0).abs() < h || r < h { hits += 1 }
            }
        }
        let exact = (4.0 * PI * h + PI * h * h) / 16.0;
        let share = hits as f64 / (m * m) as f64;
        println!("share of the 4 m x 4 m yard within {} m of circle or centre: grid {:.6}, formula {:.6}", h, share, exact);
        assert!((share - exact).abs() < 1e-3);
    }

    let (cx, cy, rr, vx, vy, k) = (1.2f64, 0.0f64, 0.5f64, 1.0f64, 0.0f64, 800usize); // Step 2: bump at C
    let phi = |x: f64, y: f64| {
        let s = ((x - cx).powi(2) + (y - cy).powi(2)) / rr.powi(2);
        if s < 1.0 { (-1.0 / (1.0 - s)).exp() } else { 0.0 }
    };
    let dphi_v = |x: f64, y: f64| {            // v . grad phi, from the chain rule
        let s = ((x - cx).powi(2) + (y - cy).powi(2)) / rr.powi(2);
        if s >= 1.0 { return 0.0 }
        phi(x, y) * (-1.0 / (1.0 - s).powi(2)) * 2.0 * (vx * (x - cx) + vy * (y - cy)) / rr.powi(2)
    };
    let ts = [0.1, 0.01, 0.001];
    let (mut lhs, mut rhs, mut quot) = (0.0f64, 0.0f64, [0.0f64; 3]);
    let w = (2.0 * rr / k as f64).powi(2);
    for i in 0..k {
        for j in 0..k {
            let x = cx - rr + 2.0 * rr * (i as f64 + 0.5) / k as f64;
            let y = cy - rr + 2.0 * rr * (j as f64 + 0.5) / k as f64;
            let p = phi(x, y);
            if p == 0.0 { continue }
            let (gx, gy) = grad_d(x, y);
            lhs += (vx * gx + vy * gy) * p * w;
            rhs -= d(x, y) * dphi_v(x, y) * w;
            for (q, t) in quot.iter_mut().zip(ts) { *q += (d(x + t * vx, y + t * vy) - d(x, y)) / t * p * w }
        }
    }
    println!("Step 2, bump of radius 0.5 at C = (1.2, 0), v = (1, 0): integral of (v . grad d) phi {:.5}; minus integral of d (v . grad phi) {:.5}", lhs, rhs);
    let qs: Vec<String> = ts.iter().zip(quot).map(|(t, q)| format!("t = {}: {:.5}", t, q)).collect();
    println!("  integral of the difference quotient times phi: {}", qs.join(", "));
    assert!((lhs - rhs).abs() < 1e-5 && (quot[2] - lhs).abs() < 1e-3 && (quot[0] - lhs).abs() > 1e-4);

    let dirs: Vec<(f64, f64)> = (0..3600).map(|j| { let a = 2.0 * PI * j as f64 / 3600.0; (a.cos(), a.sin()) }).collect();
    let worst = |px: f64, py: f64, gx: f64, gy: f64, t: f64| {   // largest |error/step| over 3600 directions
        dirs.iter().map(|&(u, v)| ((d(px + t * u, py + t * v) - d(px, py)) / t - (gx * u + gy * v)).abs()).fold(0.0f64, f64::max)
    };
    let wa: Vec<f64> = ts.iter().map(|&t| worst(1.5, 2.0, 0.6, 0.8, t)).collect();
    let wp: Vec<f64> = ts.iter().map(|&t| worst(1.0, 0.0, 0.0, 0.0, t)).collect();
    println!("Step 3, worst error/step over 3600 directions, t = 0.1, 0.01, 0.001:");
    println!("  at A with grad (0.6, 0.8): {}", join(&wa));
    println!("  at P with the flat plane:  {}", join(&wp));
    assert!(wa[0] > wa[1] && wa[1] > wa[2] && wa[2] < 1e-3 && wp.iter().all(|&q| q > 1.0 - 1e-9));

    let gxy = |x: f64, y: f64| if x == 0.0 && y == 0.0 { 0.0 } else { x * x * y / (x * x + y * y) };
    let u = 1.0 / 2f64.sqrt();                 // slope of gxy at O along v, from both sides: v1^2 v2
    let (fwd, bwd) = (gxy(1e-3 * u, 1e-3 * u) / 1e-3, gxy(-1e-3 * u, -1e-3 * u) / -1e-3);
    println!("mistake 1, g = x^2 y/(x^2 + y^2) at O: partials {:.6} and {:.6}, slope along ({:.6}, {:.6}) is {:.6} forward and {:.6} backward, the plane predicts 0",
             gxy(1e-3, 0.0) / 1e-3, gxy(0.0, 1e-3) / 1e-3, u, u, fwd, bwd);
    println!("mistake 2, f1 with L taken as 1: ratio along the diagonal {:.6}", (f1(1e-3, 1e-3) - f1(0.0, 0.0)) / hyp(1e-3, 1e-3));
    println!("mistake 3, a derivative expected at P: slope outward {:.6}, slope inward {:.6}; a plane needs them to cancel",
             (d(1.001, 0.0) - d(1.0, 0.0)) / 0.001, (d(0.999, 0.0) - d(1.0, 0.0)) / 0.001);
    let mut slopes: Vec<i64> = Vec::new();
    for n in 1..7 {                            // cells of width 2^-n holding 1/3
        let a = (2f64.powi(n) / 3.0).floor() / 2f64.powi(n);
        slopes.push(((takagi(a + 2f64.powi(-n)) - takagi(a)) * 2f64.powi(n)).round() as i64);
    }
    println!("mistake 4, Lipschitz dropped, Takagi T(x) on the plane: slopes across the cells holding x = 1/3: {:?}", slopes);
    assert!((fwd - u.powi(3)).abs() < 1e-12 && (bwd - u.powi(3)).abs() < 1e-12 && slopes == vec![1, 0, 1, 0, 1, 0]);

    let px = |x: f64, y: f64| format!("({:.2}, {:.2})", 180.0 + 60.0 * x, 165.0 - 60.0 * y);
    println!("figure, circle r 60px at {}; A {} to {}; B {} to {}; line y = 0.5 bad points {} {}",
             px(0.0, 0.0), px(1.5, 2.0), px(1.74, 2.32), px(0.3, 0.4), px(0.06, 0.08), px(-t0, 0.5), px(t0, 0.5));
    println!("ALL CHECKS PASS");
}
