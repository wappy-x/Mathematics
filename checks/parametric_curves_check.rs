// Parametric curves -- the same check as the Python, in Rust.  No crates.
// A bicycle wheel of radius R = 0.35 m rolls along a flat road; its valve sits
// b = 0.30 m from the hub.  Road one: the formula x = R th - b sin th,
// y = R - b cos th.  Road two: turn the wheel in 100000 small clicks and add up.
use std::f64::consts::PI;
const R: f64 = 0.35;
const B: f64 = 0.30;
const TURN: f64 = 2.0 * PI;
const N: usize = 100000;

fn valve(th: f64, r: f64) -> (f64, f64) {          // road one: hub (R th, R) plus the spoke
    (R * th - r * th.sin(), R - r * th.cos())
}

fn eliminated(y: f64) -> f64 {                      // x from y alone, first half turn only
    let u = ((R - y) / B).max(-1.0).min(1.0);
    R * u.acos() - B * (1.0 - u * u).sqrt()
}

fn chord(p: (f64, f64), q: (f64, f64)) -> f64 {     // straight-line distance, Pythagoras
    ((q.0 - p.0).powi(2) + (q.1 - p.1).powi(2)).sqrt()
}

fn fmt(p: (f64, f64)) -> String { format!("({:.4}, {:.4})", p.0, p.1) }

fn ratio(t: f64, r: f64) -> f64 { chord(valve(t - 0.005, r), valve(t + 0.005, r)) / (R * 0.01) }

fn main() {
    let (c, s) = ((TURN / N as f64).cos(), (TURN / N as f64).sin());
    let (mut hx, mut ox, mut oy) = (0.0, 0.0, -B);
    let mut clicked = vec![(0.0, R - B)];
    for k in 1..=N {                                // road two: one click at a time
        hx += R * TURN / N as f64;                  // the hub rolls on by one click of tyre
        (ox, oy) = (ox * c + oy * s, -ox * s + oy * c);   // the spoke turns one click clockwise
        if k % (N / 4) == 0 { clicked.push((hx + ox, R + oy)) }
    }
    let quarters: Vec<(f64, f64)> = (0..5).map(|k| valve(k as f64 * TURN / 4.0, B)).collect();
    let spoke: Vec<(f64, f64)> = (0..=360).map(|k| { let a = k as f64 * TURN / 360.0; (-B * a.sin(), R - B * a.cos()) }).collect();
    let far = spoke.iter().map(|&q| chord(spoke[0], q)).fold(0.0, f64::max);   // hub left out: spoke only
    let th = (-0.5f64).acos();
    let gap = (1..12).map(|k| { let p = valve(k as f64 * PI / 12.0, B); (eliminated(p.1) - p.0).abs() })
        .fold(0.0, f64::max);
    let pts: Vec<(f64, f64)> = (0..=N).map(|k| valve(k as f64 * TURN / N as f64, R)).collect();
    let arch: f64 = (0..N).map(|k| chord(pts[k], pts[k + 1])).sum();
    let join = |v: &Vec<(f64, f64)>| v.iter().map(|&p| fmt(p)).collect::<Vec<_>>().join(" ");
    println!("one turn rolls {:.4} m, taking {:.4} s at 3.5 m/s", R * TURN, R * TURN / 3.5);
    println!("quarter turns by the formula: {}", join(&quarters));
    println!("quarter turns by 100000 clicks: {}", join(&clicked));
    let row = |f: f64| (0..5).map(|k| format!("{:.4}", f * k as f64 * TURN / 4.0)).collect::<Vec<_>>().join(" ");
    println!("quarter-turn angles, rad: {} | hub x, m: {}", row(1.0), row(R));
    println!("valve lowest {:.4} m, highest {:.4} m", R - B, quarters[2].1);
    println!("eliminated: y = 0.5000 gives x = {:.4} - {:.4} = {:.4}; formula at theta {:.4} gives {}", R * th, B * 0.75f64.sqrt(), eliminated(0.5), th, fmt(valve(th, B)));
    println!("eliminated and formula agree to 1e-9 at 11 points of the first half turn: {}", if gap < 1e-9 { "yes" } else { "no" });
    println!("tread pebble (b = R): arch by {} slices {:.4} m, 8R = {:.4} m, top {:.4} m", N, arch, 8.0 * R, valve(PI, R).1);
    println!("over a 0.01 rad click: valve at top moves {:.4} x the hub, height / R = {:.4}", ratio(PI, B), (R + B) / R);
    println!("valve at bottom moves {:.4} x the hub, height / R = {:.4}; pebble at bottom {:.4}", ratio(0.0, B), (R - B) / R, ratio(0.0, R));
    println!("mistake, sine sign flipped: quarter-turn x {:.4} m, not {:.4} m", R * TURN / 4.0 + B, quarters[1].0);
    println!("mistake, hub left out: valve stays within {:.4} m of the start, never reaching {:.4} m", far, R * TURN);
    println!("mistake, degrees for theta: hub after a quarter turn {:.4} m, not {:.4} m", 90.0 * R, R * TURN / 4.0);
    println!("mistake, eliminated past half a turn: y = 0.3500 gives x = {:.4} m, not {:.4} m", eliminated(0.35), quarters[3].0);
    let (xs, ys) = (|x: f64| 24.0 + 140.0 * x, |y: f64| 200.0 - 140.0 * y);
    let v = quarters[1];
    println!("figure, 1 m = 140 units, road at y = 200: hub ({:.2}, {:.2}), valve ({:.2}, {:.2}), turn ends x = {:.2}",
             xs(R * TURN / 4.0), ys(R), xs(v.0), ys(v.1), xs(R * TURN));
    for (name, r) in [("valve", B), ("pebble", R)] {
        let pts: Vec<String> = (0..25).map(|k| { let p = valve(k as f64 * TURN / 24.0, r); format!("{:.1},{:.1}", xs(p.0), ys(p.1)) }).collect();
        println!("figure, {}: {}", name, pts.join(" "));
    }
    assert!(quarters.iter().zip(&clicked).map(|(&p, &q)| chord(p, q)).fold(0.0, f64::max) < 1e-9);  // two roads
    assert!(gap < 1e-9);                                                  // the eliminated form holds
    assert!((arch - 8.0 * R).abs() < 1e-6);                               // slices against Wren's 8R
    assert!((ratio(PI, B) - (R + B) / R).abs() < 1e-4 && (ratio(0.0, B) - (R - B) / R).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
