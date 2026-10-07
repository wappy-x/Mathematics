// Linearisation and the Jacobian -- the same check as the Python, in Rust, no
// crates.  The swing: theta'' + 0.5 theta' + sin theta = 0, written as the pair
// theta' = w, w' = -sin(theta) - 0.5 w; time in units of 0.5 s.  An optional
// air drag k w|w| makes the centre case.  Runge-Kutta 4 is written out here.
use std::f64::consts::PI;
type S = (f64, f64);
fn rate(s: S, c: f64, k: f64) -> S { (s.1, -s.0.sin() - c * s.1 - k * s.1 * s.1.abs()) }
fn rk4(mut s: S, t: f64, c: f64, k: f64) -> Vec<S> {    // every state along the way
    let h = 0.01;
    let mut path = vec![s];
    for _ in 0..(t / h).round() as usize {
        let a = rate(s, c, k);
        let b = rate((s.0 + h / 2.0 * a.0, s.1 + h / 2.0 * a.1), c, k);
        let d = rate((s.0 + h / 2.0 * b.0, s.1 + h / 2.0 * b.1), c, k);
        let e = rate((s.0 + h * d.0, s.1 + h * d.1), c, k);
        s = (s.0 + h / 6.0 * (a.0 + 2.0 * b.0 + 2.0 * d.0 + e.0), s.1 + h / 6.0 * (a.1 + 2.0 * b.1 + 2.0 * d.1 + e.1));
        path.push(s);
    }
    path
}
fn nudged(p: S) -> [[f64; 2]; 2] {                       // road two: slopes by nudging each variable
    let e = 1e-5;
    let (fx, bx) = (rate((p.0 + e, p.1), 0.5, 0.0), rate((p.0 - e, p.1), 0.5, 0.0));
    let (fy, by) = (rate((p.0, p.1 + e), 0.5, 0.0), rate((p.0, p.1 - e), 0.5, 0.0));
    [[(fx.0 - bx.0) / (2.0 * e), (fy.0 - by.0) / (2.0 * e)], [(fx.1 - bx.1) / (2.0 * e), (fy.1 - by.1) / (2.0 * e)]]
}
fn classify(j: [[f64; 2]; 2]) -> (f64, f64, f64, f64, f64) {  // road one: trace, det, eigenvalues
    let (tr, det) = (j[0][0] + j[1][1], j[0][0] * j[1][1] - j[0][1] * j[1][0]);
    let disc = tr * tr - 4.0 * det;
    if disc < 0.0 { (tr, det, disc, tr / 2.0, (-disc).sqrt() / 2.0) }
    else { (tr, det, disc, (tr + disc.sqrt()) / 2.0, (tr - disc.sqrt()) / 2.0) }
}
fn energy(s: S) -> f64 { s.1 * s.1 / 2.0 + 1.0 - s.0.cos() }
fn px(p: S) -> String { format!("{:.1},{:.1}", 95.0 + 55.0 * p.0, 95.0 - 55.0 * p.1) }
fn main() {
    println!("swing theta'' + 0.5 theta' + sin theta = 0, time unit 0.5 s; rests where w = 0 and sin theta = 0");
    for (name, th) in [("hanging (0, 0)", 0.0), ("inverted (pi, 0)", PI)] {
        let j = [[0.0, 1.0], [-f64::cos(th), -0.5]];            // the partial derivatives, by hand
        let (tr, det, disc, l1, l2) = classify(j);
        let n = nudged((th, 0.0));
        let err = (0..4).map(|m| (j[m / 2][m % 2] - n[m / 2][m % 2]).abs()).fold(0.0, f64::max);
        assert!(err < 1e-8);                                     // the two roads to J agree
        let kind = if disc < 0.0 { format!("{:.6} +/- {:.6}i: stable spiral", l1, l2) } else { format!("{:.6} and {:.6}: {}", l1, l2, if det < 0.0 { "saddle" } else { "node" }) };
        println!("{}: J = [[{}, {}], [{}, {}]], trace {}, det {}, disc {}; eigenvalues {}", name, j[0][0], j[0][1], j[1][0], j[1][1], tr, det, disc, kind);
    }
    let b = classify([[0.0, 1.0], [-1.0, -0.5]]).4;             // road one's eigenvalues, tested below
    println!("hanging: one swing {:.4} units = {:.4} s; amplitude kept per swing {:.4}", 2.0 * PI / b, PI / b, (-0.25 * 2.0 * PI / b).exp());
    let lin = 0.01 * (-2.5f64).exp() * ((10.0 * b).cos() + 0.25 / b * (10.0 * b).sin());  // the linear model, exact
    let non = rk4((0.01, 0.0), 10.0, 0.5, 0.0).last().unwrap().0;                         // the true swing, stepped
    assert!((non - lin).abs() < 1e-3 * lin.abs());
    println!("road two, hanging: released at 0.01 rad, theta at t = 10 in 1e-4 rad: swing {:.6}, linear {:.6}", non * 1e4, lin * 1e4);
    let lu = classify([[0.0, 1.0], [1.0, -0.5]]).3;
    let end = *rk4((PI + 1e-6, 1e-6 * lu), 10.0, 0.5, 0.0).last().unwrap();
    let grow = (((end.0 - PI).powi(2) + end.1 * end.1).sqrt() / (1e-6 * (1.0 + lu * lu).sqrt())).ln() / 10.0;
    assert!((grow - lu).abs() < 1e-3);                           // measured escape rate = eigenvalue
    println!("road two, inverted: nudged 1e-6 along the out-direction, escape rate {:.6} per unit; doubling time {:.4} units", grow, 2f64.ln() / lu);
    println!("centre case, air drag k w|w|: its slope at w = 0 is 0, so J = [[0, 1], [-1, 0]], trace 0, det 1");
    let (e0, ef) = (energy((0.5, 0.0)), energy(*rk4((0.5, 0.0), 60.0, 0.0, 0.0).last().unwrap()));
    let ed = energy(*rk4((0.5, 0.0), 60.0, 0.0, 0.5).last().unwrap());
    let a = 0.5 / (1.0 + 4.0 * 0.5 * 0.5 * 60.0 / (3.0 * PI));
    assert!((ed - (1.0 - a.cos())).abs() < 0.01 * ed);          // stepped drag swing vs averaged loss
    println!("released at 0.5 rad, energy {:.6}; at t = 60: no drag {:.6}, drag 0.5 {:.6}, averaged estimate {:.6}", e0, ef, ed, 1.0 - a.cos());
    let m = classify([[0.0, 1.0], [-1.0, -0.5]]);
    println!("mistake 1, cos(pi) read as +1: det {}, disc {}, a spiral, not the saddle", m.1, m.2);
    let r = rate((PI / 2.0, 0.0), 0.5, 0.0);
    println!("mistake 2, linearising at (pi/2, 0): rates there are {} and {}, not a rest", r.0, r.1);
    println!("figure, rests {} {}; out-line {} {}; in-line {} {}", px((0.0, 0.0)), px((PI, 0.0)), px((PI - 0.6, -0.6 * lu)), px((PI + 0.6, 0.6 * lu)),
             px((PI - 0.5, 0.5 * (lu + 0.5))), px((PI + 0.5, -0.5 * (lu + 0.5))));
    let pts: Vec<String> = rk4((2.0, 0.0), 12.0, 0.5, 0.0).iter().step_by(25).map(|&p| px(p)).collect();
    println!("figure, path released at (2, 0), every 0.25 up to t = 12: {}", pts.join(" "));
    println!("ALL CHECKS PASS");
}
