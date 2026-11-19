// Lie bracket and Frobenius theorem -- the check behind the card.  std only, no crates.
// A car's state q = (x, y, th): rear-axle middle x along the street, y toward the curb (m),
// heading th (rad, anticlockwise).  A = drive on full left lock, B = drive on full right lock.
use std::f64::consts::PI;
type V = [f64; 3];
const R: f64 = 5.0; // rear-axle turning radius at full lock, m
fn a_f(q: V) -> V { [q[2].cos(), q[2].sin(), 1.0 / R] }
fn b_f(q: V) -> V { [q[2].cos(), q[2].sin(), -1.0 / R] }
fn arc(q: V, k: f64, s: f64) -> V { // exact flow: drive s metres along curvature k
    [q[0] + ((q[2] + k * s).sin() - q[2].sin()) / k, q[1] - ((q[2] + k * s).cos() - q[2].cos()) / k, q[2] + k * s]
}
fn fa(q: V, s: f64) -> V { arc(q, 1.0 / R, s) }
fn fb(q: V, s: f64) -> V { arc(q, -1.0 / R, s) }
fn sub(u: V, v: V) -> V { [u[0] - v[0], u[1] - v[1], u[2] - v[2]] }
fn axpy(u: V, k: f64, v: V) -> V { [u[0] + k * v[0], u[1] + k * v[1], u[2] + k * v[2]] }
// [X,Y]^i = X^j d_j Y^i - Y^j d_j X^i, central differences
fn bracket(x: &dyn Fn(V) -> V, y: &dyn Fn(V) -> V, q: V) -> V {
    let h = 1e-5;
    let (xq, yq) = (x(q), y(q));
    let mut out = [0.0; 3];
    for j in 0..3 {
        let (mut qp, mut qm) = (q, q);
        qp[j] += h;
        qm[j] -= h;
        let (yp, ym, xp, xm) = (y(qp), y(qm), x(qp), x(qm));
        for i in 0..3 {
            let dy = (yp[i] - ym[i]) / (2.0 * h);
            let dx = (xp[i] - xm[i]) / (2.0 * h);
            out[i] = out[i] + xq[j] * dy - yq[j] * dx;
        }
    }
    out
}
fn closed(q: V) -> V { [-2.0 / R * q[2].sin(), 2.0 / R * q[2].cos(), 0.0] } // by hand
fn side(q: V, v: V) -> f64 { -q[2].sin() * v[0] + q[2].cos() * v[1] } // the no-skid form
fn z(a: f64, n: i32) -> f64 { if a.abs() < 0.5 * 10f64.powi(-n) { 0.0 } else { a } }
fn fmt(v: V, n: usize) -> String {
    let parts: Vec<String> = v.iter().map(|&a| format!("{:.*}", n, z(a, n as i32))).collect();
    format!("({})", parts.join(", "))
}
fn rk4(f: fn(V) -> V, mut q: V, s: f64, n: usize) -> V {
    let h = s / n as f64;
    for _ in 0..n {
        let k1 = f(q);
        let k2 = f(axpy(q, h / 2.0, k1));
        let k3 = f(axpy(q, h / 2.0, k2));
        let k4 = f(axpy(q, h, k3));
        for i in 0..3 { q[i] += h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    q
}
fn cart(p: V) -> V { [p[0] * p[1].cos(), p[0] * p[1].sin(), p[2]] }
fn to_polar(f: fn(V) -> V, p: V) -> V {
    let c = cart(p);
    let v = f(c);
    let rho2 = c[0] * c[0] + c[1] * c[1];
    [(c[0] * v[0] + c[1] * v[1]) / rho2.sqrt(), (c[0] * v[1] - c[1] * v[0]) / rho2, v[2]]
}
fn main() {
    let q0 = [0.0; 3];
    // Overview: parallel parking, two reverse moves of 3.5 m, in both orders
    let s = 3.5;
    let (lr, rl) = (fb(fa(q0, -s), -s), fa(fb(q0, -s), -s));
    println!("park, left lock then right lock, back {} m each: end {}", s, fmt(lr, 2));
    println!("park, right lock then left lock, back {} m each: end {}", s, fmt(rl, 2));
    println!("swap gap {:.2} m sideways; bracket estimate s^2 x 2/r = {:.2} m", lr[1] - rl[1], s * s * 2.0 / R);
    // Road 1 and 2: the bracket by hand and by the coordinate formula
    let br = bracket(&a_f, &b_f, q0);
    println!("[A,B] at the start: by hand {}, by formula {}", fmt(closed(q0), 4), fmt(br, 4));
    println!("A {}, B {}; first term only {}", fmt(a_f(q0), 4), fmt(b_f(q0), 4), fmt([0.0, a_f(q0)[2], 0.0], 4));
    let q30 = [0.0, 0.0, PI / 6.0];
    println!("[A,B] at heading 30 deg: by hand {}, by formula {}", fmt(closed(q30), 4), fmt(bracket(&a_f, &b_f, q30), 4));
    // Road 3: swap gap over s^2 as the moves shrink (the chart's points)
    let mut gaps = Vec::new();
    for k in 1..9 {
        let s = 0.5 * k as f64;
        let g = sub(fb(fa(q0, s), s), fa(fb(q0, s), s));
        gaps.push(g[1] / (s * s));
        assert!((g[1] - 4.0 * R * (1.0 - (s / R).cos())).abs() < 1e-12 && g[0].abs() < 1e-12);
    }
    let gs: Vec<String> = gaps.iter().map(|v| format!("{:.4}", v)).collect();
    println!("swap gap / s^2, s = 0.5 to 4.0 m: {}", gs.join(", "));
    println!("errors from 0.4 at s = 1 and 0.5 m: {:.6}, {:.6}", 0.4 - gaps[1], 0.4 - gaps[0]);
    println!("wrong: gap / s, s = 1 and 0.5 m: {:.4}, {:.4}", gaps[1] * 1.0, gaps[0] * 0.5);
    // Road 4: the four-move loop: left s, right s, left back s, right back s
    let lp = |s: f64| fb(fa(fb(fa(q0, s), s), -s), -s);
    for s in [1.0, 0.5] {
        let e = lp(s);
        println!("loop of {:.1} m moves: end {}; y / s^2 = {:.4}", s, fmt(e, 4), e[1] / (s * s));
    }
    // Road 5: a second chart, polar about a lamp post: (rho, al, th), car at x = 4, y = 3
    let p = [5.0, 3.0f64.atan2(4.0), 0.0];
    let pa = |p: V| to_polar(a_f, p);
    let pb = |p: V| to_polar(b_f, p);
    let bp = bracket(&pa, &pb, p);
    let back = [p[1].cos() * bp[0] - p[0] * p[1].sin() * bp[1], p[1].sin() * bp[0] + p[0] * p[1].cos() * bp[1], bp[2]];
    println!("polar chart at (4, 3): A {}, [A,B] {}, back in x, y {}", fmt(pa(p), 4), fmt(bp, 4), fmt(back, 4));
    // Road 6: Lie derivative: pull B back along A's flow, then take the rate
    let pulled = |t: f64| -> V {
        let e = 1e-6;
        let m = fa(q0, t);
        let v = b_f(m);
        let (hi, lo) = (fa(axpy(m, e, v), -t), fa(axpy(m, -e, v), -t));
        [0, 1, 2].map(|i| (hi[i] - lo[i]) / (2.0 * e))
    };
    let t = 1e-3;
    let (pp, pm) = (pulled(t), pulled(-t));
    let lie = [0, 1, 2].map(|i| (pp[i] - pm[i]) / (2.0 * t));
    println!("Lie derivative L_A B at the start: {}", fmt(lie, 4));
    // Frobenius, car: is [A,B] inside the no-skid plane?
    let (a0, b0) = (a_f(q0), b_f(q0));
    let det = a0[0] * (b0[1] * br[2] - b0[2] * br[1]) - a0[1] * (b0[0] * br[2] - b0[2] * br[0])
        + a0[2] * (b0[0] * br[1] - b0[1] * br[0]);
    println!("car: sideways part of A {:.4}, of B {:.4}, of [A,B] {:.4}", z(side(q0, a0), 4), z(side(q0, b0), 4), side(q0, br));
    println!("car: det(A, B, [A,B]) = {:.4}; 4/r^2 = {:.4}", det, 4.0 / (R * R));
    for n in [10, 20] {
        println!("park by RK4, {} steps per move: y {:.8}; exact {:.8}", n, rk4(b_f, rk4(a_f, q0, -3.5, n), -3.5, n)[1], lr[1]);
    }
    // Frobenius, roof: planes dz = (y dx + x dy)/20, and the twisted planes dz = y dx/20
    let u = |q: V| -> V { [1.0, 0.0, q[1] / 20.0] };
    let v = |q: V| -> V { [0.0, 1.0, q[0] / 20.0] };
    let v2 = |_q: V| -> V { [0.0, 1.0, 0.0] };
    let w = |q: V| -> V { let c = 1.0 + q[0] / 4.0; [0.0, c, c * q[0] / 20.0] };
    let om = |q: V, v: V| v[2] - (q[1] * v[0] + q[0] * v[1]) / 20.0;
    let om2 = |q: V, v: V| v[2] - q[1] * v[0] / 20.0;
    let p0 = [4.0, 2.0, 0.4];
    let cases: [(&str, &dyn Fn(V) -> V, &dyn Fn(V, V) -> f64); 3] =
        [("roof [U,V]", &v, &om), ("roof [U,W]", &w, &om), ("twisted [U,V2]", &v2, &om2)];
    for (name, y, wf) in cases {
        let b = bracket(&u, y, p0);
        println!("{}: {}, out-of-plane part {:.4}", name, fmt(b, 4), z(wf(p0, b), 4));
    }
    let gu = |q: V, s: f64| -> V { [q[0] + s, q[1], q[2] + q[1] * s / 20.0] };
    let gv = |q: V, t: f64| -> V { [q[0], q[1] + t, q[2] + q[0] * t / 20.0] };
    let gv2 = |q: V, t: f64| -> V { [q[0], q[1] + t, q[2]] };
    let (uv, vu) = (gv(gu(p0, 4.0), 4.0), gu(gv(p0, 4.0), 4.0));
    let (uv2, v2u) = (gv2(gu(p0, 4.0), 4.0), gu(gv2(p0, 4.0), 4.0));
    println!("roof, U then V: {}; V then U: {}; xy/20 there = {:.2}", fmt(uv, 2), fmt(vu, 2), uv[0] * uv[1] / 20.0);
    println!("twisted, U then V2: {}; V2 then U: {}; gap {:.2} m", fmt(uv2, 2), fmt(v2u, 2), uv2[2] - v2u[2]);

    let c0 = closed(q0);
    assert!((0..3).all(|i| (br[i] - c0[i]).abs() < 1e-8)); // formula = hand bracket
    let (b30, c30) = (bracket(&a_f, &b_f, q30), closed(q30));
    assert!((0..3).all(|i| (b30[i] - c30[i]).abs() < 1e-8)); // and at 30 deg
    assert!((0..3).all(|i| (back[i] - c0[i]).abs() < 1e-8)); // polar chart agrees
    assert!((0..3).all(|i| (lie[i] - c0[i]).abs() < 1e-5)); // Lie derivative = bracket
    assert!(((0.4 - gaps[1]) / (0.4 - gaps[0]) - 4.0).abs() < 0.01); // swap gap -> s^2 [A,B]
    assert!((lp(0.5)[1] / 0.25 - 0.4).abs() < 0.01 && (det - 4.0 / (R * R)).abs() < 1e-8);
    assert!((rk4(b_f, rk4(a_f, q0, -3.5, 20), -3.5, 20)[1] - lr[1]).abs() < 1e-7); // RK4 = exact arcs
    assert!(om(p0, bracket(&u, &v, p0)).abs() < 1e-9 && (uv[2] - vu[2]).abs() < 1e-12);
    assert!(((uv2[2] - v2u[2]) - 16.0 * bracket(&u, &v2, p0)[2]).abs() < 1e-9); // gap = s t [U,V2]
    println!("ALL CHECKS PASS");
}
