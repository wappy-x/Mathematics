// The circle's fundamental group -- the same check as the Python, in Rust.  No
// crates.  Metres.  A lamp post at (0, 0); a dog on a lead starts and ends at (2, 0).
// A loop is a list of pieces; a piece turns a*s + c*sin(2 pi k s) turns round the
// post as s runs 0 to 1, at distance 2 + r*sin(2 pi 5 s), run backwards if rev.
// Three roads to the number of turns: lift the loop by adding small turns (atan2);
// read 8 compass sectors by atan2, then walk and cancel steps in integers only;
// and the contour integral of dz/z, divided by 2 pi i, from the winding-number card.
use std::f64::consts::PI;
const TAU: f64 = 2.0 * PI;
const N: usize = 2000; // samples per piece
type Piece = (f64, f64, f64, f64, bool);
type Pt = (f64, f64);

fn clean(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn piece_at(p: Piece, s: f64) -> Pt {
    let (a, c, k, r, rev) = p;
    let s = if rev { 1.0 - s } else { s };
    let (turns, dist) = (a * s + c * (TAU * k * s).sin(), 2.0 + r * (TAU * 5.0 * s).sin());
    (dist * (TAU * turns).cos(), dist * (TAU * turns).sin())
}
fn points(lp: &[Piece], n: usize) -> Vec<Pt> { // run the pieces one after the other
    let mut pts = vec![piece_at(lp[0], 0.0)];
    for &p in lp { for j in 1..=n { pts.push(piece_at(p, j as f64 / n as f64)) } }
    pts
}
fn lift(pts: &[Pt]) -> (Vec<f64>, f64) { // road 1: add up each small step's turn
    let (mut out, mut big) = (vec![0.0], 0.0f64);
    for w in pts.windows(2) {
        let ((x1, y1), (x2, y2)) = (w[0], w[1]);
        let step = (x1 * y2 - y1 * x2).atan2(x1 * x2 + y1 * y2) / TAU;
        out.push(out[out.len() - 1] + step);
        big = big.max(step.abs());
    }
    (out, big)
}
fn compass(pts: &[Pt]) -> (Vec<i64>, Vec<i64>, Vec<i64>) { // road 2: sectors 0..7, east in the middle of 0
    let secs: Vec<i64> = pts.iter().map(|&(x, y)| ((8.0 * y.atan2(x) / TAU + 0.5).floor() as i64).rem_euclid(8)).collect();
    let (mut word, mut rays) = (Vec::new(), Vec::new());
    for w in secs.windows(2) {
        let d = (w[1] - w[0] + 4).rem_euclid(8) - 4;
        assert!(d.abs() <= 1); // samples close enough: one sector at a time
        if d != 0 { word.push(d) }
        if (w[0] == 7 && w[1] == 0) || (w[0] == 0 && w[1] == 7) { rays.push(d) } // crossing the ray 1/16 turn south of east
    }
    let mut stack: Vec<i64> = Vec::new();
    for &d in &word { // cancel a step and its undo
        if stack.last() == Some(&-d) { stack.pop(); } else { stack.push(d) }
    }
    (word, stack, rays)
}
fn contour(pts: &[Pt]) -> f64 { // road 3: trapezoid sum of dz/z, over 2 pi i; the real part
    let inv = |(x, y): Pt| { let m = x * x + y * y; (x / m, -y / m) };
    let mut im = 0.0;
    for w in pts.windows(2) {
        let (a, b) = (inv(w[0]), inv(w[1]));
        let (fx, fy) = ((a.0 + b.0) / 2.0, (a.1 + b.1) / 2.0);
        let (dx, dy) = (w[1].0 - w[0].0, w[1].1 - w[0].1);
        im += fx * dy + fy * dx;
    }
    im / TAU
}
fn circle(h: &[f64]) -> Vec<Pt> { h.iter().map(|&x| ((TAU * x).cos(), (TAU * x).sin())).collect() }
fn back(p: Piece) -> Piece { (p.0, p.1, p.2, p.3, !p.4) }
fn plain(m: f64) -> Piece { (m, 0.0, 0.0, 0.0, false) }

fn main() {
    let (alpha, beta): (Piece, Piece) = ((2.0, 0.15, 3.0, 0.5, false), (3.0, 0.1, 2.0, 0.4, false));
    let loops: Vec<(&str, Vec<Piece>, i64)> = vec![("alpha, 2 turns", vec![alpha], 2), ("beta, 3 turns", vec![beta], 3),
        ("alpha then beta", vec![alpha, beta], 5), ("beta then alpha", vec![beta, alpha], 5),
        ("beta reversed", vec![back(beta)], -3), ("beta then alpha reversed", vec![beta, back(alpha)], 1),
        ("beta then beta reversed", vec![beta, back(beta)], 0)];
    println!("post at (0, 0) m; the dog starts and ends at (2, 0) m");
    for (name, lp, hand) in &loops {
        let pts = points(lp, N);
        let (l, big) = lift(&pts);
        let (word, red, _) = compass(&pts);
        let w = contour(&pts);
        let (end, net) = (l[l.len() - 1], word.iter().sum::<i64>());
        println!("{}: lift ends at {:.6}; compass steps {}, net {} = {} x 8; after cancelling {} steps; integral {:.3}",
                 name, clean(end), word.len(), net, net.div_euclid(8), red.len(), clean(w));
        assert!(end.round() as i64 == *hand && (end - *hand as f64).abs() < 1e-9 && big < 0.25); // road 1 = hand count
        assert!(net == 8 * hand && red.len() as i64 == 8 * hand.abs() && red.iter().all(|&d| d == red[0])); // road 2: pure laps
        assert!((w - *hand as f64).abs() < 1e-3); // road 3 agrees
        if *name == "alpha then beta" {
            println!("biggest single step of the lift: {:.6} turn (it must stay under 1/2)", big);
            let ch: Vec<String> = (0..11).map(|i| format!("{:.3}", clean(l[2 * N * i / 10]))).collect();
            println!("chart, lift of alpha then beta at s = 0, 0.1, ..., 1: {}", ch.join(", "));
        }
        if *name == "alpha, 2 turns" {
            let gap = (0..=N).map(|j| { let s = j as f64 / N as f64; (l[j] - (2.0 * s + 0.15 * (TAU * 3.0 * s).sin())).abs() })
                .fold(0.0f64, f64::max);
            println!("lift against the designed angle at {} samples: largest gap under 1e-9: {}", N + 1, if gap < 1e-9 { "yes" } else { "no" });
            assert!(gap < 1e-9); // the lift is the angle
            let stages: Vec<f64> = (0..11).map(|u| { let u = u as f64 / 10.0;
                let h: Vec<f64> = l.iter().enumerate().map(|(j, &x)| (1.0 - u) * x + u * 2.0 * j as f64 / N as f64).collect();
                let e = lift(&circle(&h)).0; e[e.len() - 1] }).collect();
            let st: Vec<String> = stages.iter().map(|e| format!("{}", e.round() as i64)).collect();
            println!("slide alpha to the plain loop s -> 2s turns, 11 stages, each re-lifted: {}", st.join(" "));
            assert!(stages.iter().all(|e| (e - 2.0).abs() < 1e-9)); // the count never moves
        }
        if *name == "beta then beta reversed" {
            let ends: Vec<f64> = (0..11).map(|u| { let u = u as f64 / 10.0;
                let h: Vec<f64> = l.iter().map(|&x| (1.0 - u) * x).collect();
                let e = lift(&circle(&h)).0; e[e.len() - 1] }).collect();
            let st: Vec<String> = ends.iter().map(|e| format!("{}", clean(*e).round() as i64)).collect();
            println!("shrink it to the start, 11 stages, each re-lifted: {}", st.join(" "));
            assert!(ends.iter().all(|e| e.abs() < 1e-9));
        }
    }
    let mut ok = 0;
    for m in -3..=3 { for n in -3..=3 {
        let e = lift(&points(&[plain(m as f64), plain(n as f64)], N)).0;
        if (e[e.len() - 1] - (m + n) as f64).abs() < 1e-9 { ok += 1 }
    } }
    println!("plain loops m then n, m and n from -3 to 3: count is m + n in {} of 49 cases", ok);
    assert!(ok == 49);
    let five = points(&[plain(5.0)], N);
    let last = five[five.len() - 1];
    println!("mistake 1, 5 turns read by the final angle only: {:.6} turns, not 5", clean(last.1.atan2(last.0) / TAU));
    let c = lift(&points(&[plain(5.0)], 8)).0;
    let coarse = c[c.len() - 1];
    println!("mistake 2, 5 turns sampled at 8 points: each step 5/8 turn reads as -3/8; total {:.6}, not 5", coarse);
    let rays = compass(&points(&[beta, back(alpha)], N)).2;
    println!("mistake 3, beta then alpha reversed, ray crossings counted without sign: {}, not {}", rays.len(), rays.iter().sum::<i64>());
    let pa = points(&[alpha], N);
    let pl = lift(&pa[..7 * N / 8 + 1]).0;
    let part = pl[pl.len() - 1];
    println!("mistake 4, alpha stopped at s = 0.875, not closed: lift ends at {:.6}, no whole number", part);
    assert!((coarse + 3.0).abs() < 1e-9 && rays.iter().sum::<i64>() == 1 && rays.len() == 5 && (part - part.round()).abs() > 0.1);
    println!("ALL CHECKS PASS");
}
