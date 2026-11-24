// Index theory in the plane -- the same check as the Python, in Rust.  No crates.
// The index of a loop is the net number of turns the field's arrow makes while a
// point walks once anticlockwise round the loop.  Roads: (1) add up the arrow's
// small turns, (2) count signed passes of the arrow through "due east",
// (3) the sign of the Jacobian's determinant, (4) the linear-field integral.
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
type P = (f64, f64);
fn pp(x: f64, y: f64) -> P { (x - x * y, -y + x * y) }                  // predator-prey, rates 1
fn sq(x: f64, y: f64) -> P { (x * x - y * y, 2.0 * x * y) }             // the field z^2
fn swing(x: f64, y: f64) -> P { (y, -0.5 * y - x.sin()) }               // the damped swing
fn circle(cx: f64, cy: f64, r: f64, off: f64) -> Vec<P> {               // off 0.25: starts just past due east
    (0..=3600).map(|k| { let t = TAU * (k as f64 + off) / 3600.0; (cx + r * t.cos(), cy + r * t.sin()) }).collect()
}
fn turns(f: fn(f64, f64) -> P, pts: &[P]) -> f64 {                      // road 1
    let ang: Vec<f64> = pts.iter().map(|p| { let v = f(p.0, p.1); v.1.atan2(v.0) }).collect();
    ang.windows(2).map(|w| (w[1] - w[0] + PI).rem_euclid(TAU) - PI).sum::<f64>() / TAU + 0.0
}
fn passes(f: fn(f64, f64) -> P, pts: &[P]) -> i64 {                     // road 2
    let v: Vec<P> = pts.iter().map(|p| f(p.0, p.1)).collect();
    v.windows(2).filter(|w| w[0].0 > 0.0 && w[1].0 > 0.0)
        .map(|w| (w[0].1 < 0.0 && 0.0 <= w[1].1) as i64 - (w[1].1 < 0.0 && 0.0 <= w[0].1) as i64).sum()
}
fn jac(f: fn(f64, f64) -> P, x: f64, y: f64) -> [f64; 4] {             // the Jacobian, by differences
    let e = 1e-6;
    let (a, b, c, d) = (f(x + e, y), f(x - e, y), f(x, y + e), f(x, y - e));
    [(a.0 - b.0) / (2.0 * e), (c.0 - d.0) / (2.0 * e), (a.1 - b.1) / (2.0 * e), (c.1 - d.1) / (2.0 * e)]
}
fn det_sign(j: [f64; 4]) -> i64 { let d = j[0] * j[3] - j[1] * j[2]; (d > 1e-9) as i64 - (d < -1e-9) as i64 }  // road 3
fn linear_index(j: [f64; 4]) -> f64 {                                   // road 4, midpoint rule
    let n = 20000;
    let s: f64 = (0..n).map(|k| { let t = TAU * (k as f64 + 0.5) / n as f64;
        1.0 / ((j[0] * t.cos() + j[1] * t.sin()).powi(2) + (j[2] * t.cos() + j[3] * t.sin()).powi(2)) }).sum();
    (j[0] * j[3] - j[1] * j[2]) / n as f64 * s
}
fn lap(h: f64) -> (f64, Vec<P>) {                                       // RK4 once round the orbit from (2, 1)
    let (mut p, mut t, mut pts) = ((2.0, 1.0), 0.0, vec![(2.0, 1.0)]);
    loop {
        let k1 = pp(p.0, p.1); let k2 = pp(p.0 + h / 2.0 * k1.0, p.1 + h / 2.0 * k1.1);
        let k3 = pp(p.0 + h / 2.0 * k2.0, p.1 + h / 2.0 * k2.1); let k4 = pp(p.0 + h * k3.0, p.1 + h * k3.1);
        let q = (p.0 + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0), p.1 + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1));
        if t > 1.0 && p.1 < 1.0 && 1.0 <= q.1 { pts.push((2.0, 1.0)); return (t + h * (1.0 - p.1) / (q.1 - p.1), pts); }
        p = q; t += h; pts.push(p);
    }
}
fn main() {
    let loops: [(&str, fn(f64, f64) -> P, f64, f64, f64, i64); 5] = [("z^2 field, r 1 round (0, 0)", sq, 0.0, 0.0, 1.0, 2),
        ("predator-prey, r 0.5 round (1, 1)", pp, 1.0, 1.0, 0.5, 1), ("predator-prey, r 0.5 round (0, 0)", pp, 0.0, 0.0, 0.5, -1),
        ("predator-prey, r 3 round both rests", pp, 0.5, 0.5, 3.0, 0), ("predator-prey, r 1 round (3, 3)", pp, 3.0, 3.0, 1.0, 0)];
    for (name, f, cx, cy, r, want) in loops {
        let (t1, t2) = (turns(f, &circle(cx, cy, r, 0.25)), passes(f, &circle(cx, cy, r, 0.25)));
        let arrows: Vec<String> = [(1.0, 0.0), (0.0, 1.0), (-1.0, 0.0), (0.0, -1.0)].iter()
            .map(|&(c, d)| { let v = f(cx + r * c, cy + r * d); format!("({:.2}, {:.2})", v.0 + 0.0, v.1 + 0.0) }).collect();
        println!("{}: arrows at E N W S {}; turns {:.6}, passes due east {}", name, arrows.join(" "), t1, t2);
        assert!((t1 - want as f64).abs() < 1e-6 && t2 == want);         // roads 1 and 2 agree
    }
    let rests: [(&str, fn(f64, f64) -> P, f64, f64, i64); 4] = [("predator-prey (0, 0)", pp, 0.0, 0.0, -1), ("predator-prey (1, 1)", pp, 1.0, 1.0, 1),
        ("swing hanging (0, 0)", swing, 0.0, 0.0, 1), ("swing upside down (pi, 0)", swing, PI, 0.0, -1)];
    for (name, f, x, y, want) in rests {
        let j = jac(f, x, y); let (s, t1, v) = (det_sign(j), turns(f, &circle(x, y, 0.01, 0.25)), linear_index(j));
        println!("{}: sign of det J {:+}; turns on a circle of radius 0.01 {:.6}; linear integral {:.6}", name, s, t1, v);
        assert!(s == want && (t1 - s as f64).abs() < 1e-6 && (v - s as f64).abs() < 1e-6);  // roads 3, 1 and 4 agree
    }
    let (t, orbit) = lap(0.001);
    println!("orbit from (2, 1): lap {:.4} years, {} points; arrow turns {:.6}", t, orbit.len() - 1, turns(pp, &orbit));
    assert!((turns(pp, &orbit) - 1.0).abs() < 1e-6 && (t - 6.6085).abs() < 1e-4);
    println!("chart, turns so far after every 30 degrees of the walk:");
    let charts: [(&str, fn(f64, f64) -> P, f64, f64, f64); 3] = [("round (1, 1)", pp, 1.0, 1.0, 0.5), ("round (0, 0)", pp, 0.0, 0.0, 0.5), ("z^2, round (0, 0)", sq, 0.0, 0.0, 1.0)];
    for (name, f, cx, cy, r) in charts {
        let c = circle(cx, cy, r, 0.25);
        println!("  {}: {}", name, (0..13).map(|k| format!("{:.2}", turns(f, &c[..300 * k + 1]))).collect::<Vec<_>>().join(" "));
    }
    let c = circle(1.0, 1.0, 0.5, 0.25);
    let rev: Vec<P> = c.iter().rev().cloned().collect();
    println!("mistake 1, walking clockwise round (1, 1): turns {:.6}", turns(pp, &rev));
    println!("mistake 2, stopping halfway round (1, 1), due east to due west: turns {:.6}", turns(pp, &circle(1.0, 1.0, 0.5, 0.0)[..1801]));
    println!("mistake 3, sign of det J for z^2 at (0, 0): {}, true index 2", det_sign(jac(sq, 0.0, 0.0)));
    println!("ALL CHECKS PASS");
}
