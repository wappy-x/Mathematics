// The Henon map -- the same check as the Python, in Rust.  No crates.  The rule (x, y) ->
// (1 - a x^2 + y, b x) at a = 1.4, b = 0.3: fixed points, area, stretch and dimension, two roads each.
use std::collections::HashSet;
const A: f64 = 1.4; const B: f64 = 0.3; const M: usize = 10_000_000;
fn step(x: f64, y: f64) -> (f64, f64) { (1.0 - A * x * x + y, B * x) }
fn newton(mut x: f64, mut y: f64) -> (f64, f64) {     // road two: solve step(x, y) = (x, y) by Newton
    for _ in 0..40 {
        let (f, g, p) = (1.0 - A * x * x + y - x, B * x - y, -2.0 * A * x - 1.0);
        (x, y) = (x + (f + g) / (-p - B), y + (B * f - p * g) / (-p - B));
    }
    (x, y)
}
fn shoelace(p: &[(f64, f64)]) -> f64 {                // signed area; negative means the order flipped
    (0..p.len()).map(|i| { let q = p[(i + p.len() - 1) % p.len()]; q.0 * p[i].1 - p[i].0 * q.1 }).sum::<f64>() / 2.0
}
fn slope(cs: &[usize]) -> f64 {                       // least-squares slope of ln(count) against ln(1/side)
    let xs: Vec<f64> = (7..13).map(|k| k as f64 * 2f64.ln()).collect();
    let ys: Vec<f64> = cs.iter().map(|&c| (c as f64).ln()).collect();
    let (mx, my) = (xs.iter().sum::<f64>() / 6.0, ys.iter().sum::<f64>() / 6.0);
    let top: f64 = xs.iter().zip(&ys).map(|(u, v)| (u - mx) * (v - my)).sum();
    top / xs.iter().map(|u| (u - mx) * (u - mx)).sum::<f64>()
}
fn count(pts: &[(f64, f64)]) -> Vec<usize> {
    (7..13).map(|k| {
        let s = (1u64 << k) as f64;
        pts.iter().map(|&(x, y)| ((x * s).floor() as i64, (y * s).floor() as i64)).collect::<HashSet<_>>().len()
    }).collect()
}
fn main() {
    let root = ((1.0 - B) * (1.0 - B) + 4.0 * A).sqrt();
    let fx = [(-(1.0 - B) + root) / (2.0 * A), (-(1.0 - B) - root) / (2.0 * A)];   // road one: formula
    let nw = [newton(0.5, 0.0), newton(-1.0, 0.0)];
    let mut orb: Vec<(f64, f64)> = vec![(0.0, 0.0)];              // the orbit from (0, 0); pts drops 1000 steps
    for _ in 0..10_001_001 { let (x, y) = *orb.last().unwrap(); orb.push(step(x, y)) }
    let pts = &orb[1001..];
    let eig: Vec<(f64, f64)> = fx.iter().map(|&u| { let r = (A * A * u * u + B).sqrt(); (-A * u + r, -A * u - r) }).collect();
    println!("Henon map, a = {}, b = {}; from (0, 0): {}", A, B, orb[1..5].iter().map(|p| format!("({:.4}, {:.4})", p.0, p.1)).collect::<Vec<_>>().join(" "));
    println!("fixed points, formula: (1 - b)^2 + 4a = {:.2}, root {:.6}; x = {:.6}, {:.6}; y = b x = {:.6}, {:.6}",
             (1.0 - B) * (1.0 - B) + 4.0 * A, root, fx[0], fx[1], B * fx[0], B * fx[1]);
    println!("fixed points, Newton: ({:.6}, {:.6}), ({:.6}, {:.6})", nw[0].0, nw[0].1, nw[1].0, nw[1].1);
    println!("eigenvalues: {:.6} and {:.6}; {:.6} and {:.6}", eig[0].0, eig[0].1, eig[1].0, eig[1].1);
    let t: Vec<f64> = (0..4000).map(|i| -1.5 + (3 * i) as f64 / 4000.0).collect();
    let sq: Vec<(f64, f64)> = t.iter().map(|&u| (u, -1.5)).chain(t.iter().map(|&u| (1.5, u)))
        .chain(t.iter().map(|&u| (-u, 1.5))).chain(t.iter().map(|&u| (-1.5, -u))).collect();
    let image = |p: &[(f64, f64)]| -> Vec<(f64, f64)> { p.iter().map(|&(x, y)| step(x, y)).collect() };
    let (im1, im2) = (image(&sq), image(&image(&sq)));
    let ar = [shoelace(&sq), shoelace(&im1), shoelace(&im2)];
    println!("signed area of the square [-1.5, 1.5]^2, then 1 and 2 steps: {:.6} {:.6} {:.6}; times -b, b^2: {:.6} {:.6}",
             ar[0], ar[1], ar[2], ar[0] * -B, ar[0] * B * B);
    let (mut vx, mut vy, d0, mut s_tan, mut s_two, mut s_eig) = (1.0f64, 0.0f64, 1e-8, 0.0f64, 0.0f64, 0.0f64);
    let (mut px, mut py) = (pts[0].0 + 1e-8, pts[0].1);
    for k in 0..M {
        let ((x, _), (nx, ny)) = (pts[k], pts[k + 1]);
        (vx, vy) = (-2.0 * A * x * vx + vy, B * vx);       // road one: carry an arrow by the Jacobian
        let nv = (vx * vx + vy * vy).sqrt();
        (s_tan, vx, vy) = (s_tan + nv.ln(), vx / nv, vy / nv);
        s_eig += ((A * x).abs() + (A * A * x * x + B).sqrt()).ln();
        (px, py) = step(px, py);                           // road two: a shadow run 1e-8 away
        let dd = ((px - nx) * (px - nx) + (py - ny) * (py - ny)).sqrt();
        (s_two, px, py) = (s_two + (dd / d0).ln(), nx + (px - nx) * d0 / dd, ny + (py - ny) * d0 / dd);
    }
    let (l1, l2) = (s_tan / M as f64, B.ln() - s_tan / M as f64);
    println!("largest Lyapunov exponent, steps 1001 to {}, carried arrow: {:.4}; shadow run: {:.4}", M + 1000, l1, s_two / M as f64);
    println!("second exponent ln 0.3 - {:.4} = {:.4}; Kaplan-Yorke 1 + {:.4}/{:.4} = {:.4}", l1, l2, l1, -l2, 1.0 - l1 / l2);
    let (many, few) = (count(&pts[..10_000_000]), count(&pts[..100_000]));
    println!("boxes of side 1/128 to 1/4096 hit by 10^7 points: {:?}; slope {:.4}", many, slope(&many));
    println!("mistakes, exponent from one fixed point: ln {:.6} = {:.4}; from each step's biggest eigenvalue: {:.4}",
             -eig[0].1, (-eig[0].1).ln(), s_eig / M as f64);
    println!("mistake, only 10^5 points: {:?}; slope {:.4}", few, slope(&few));
    let mut path = vec![(2.0f64, 0.0f64)];
    while path.last().unwrap().0.abs() < 1e6 { let (a, b) = *path.last().unwrap(); path.push(step(a, b)) }
    println!("mistake, start (2, 0): x runs {}", path.iter().map(|p| format!("{:.1}", p.0)).collect::<Vec<_>>().join(", "));
    let fig: Vec<String> = fx.iter().map(|u| format!("({:.1}, {:.1})", 210.0 + 150.0 * u, 110.0 - 150.0 * B * u)).collect();
    println!("figure, 150 px per unit, origin at (210, 110), orbit points 1001 to 6000, fixed points at {} and {}", fig[0], fig[1]);
    assert!((0..2).all(|i| (fx[i] - nw[i].0).abs() < 1e-9 && (B * fx[i] - nw[i].1).abs() < 1e-9));
    assert!(eig.iter().zip(&fx).all(|(e, &u)| ((e.0.abs() > 1.0 && 1.0 > e.1.abs()) || (e.1.abs() > 1.0 && 1.0 > e.0.abs())) && [e.0, e.1].iter().all(|&m| ((-2.0 * A * u - m) * -m - B).abs() < 1e-12)));  // saddles; det(J - mu I) = 0
    assert!((ar[0] - 9.0).abs() < 1e-9 && (ar[1] + B * ar[0]).abs() < 1e-5 && (ar[2] - B * B * ar[0]).abs() < 1e-5);
    assert!((l1 - s_two / M as f64).abs() < 0.002 && (slope(&many) - (1.0 - l1 / l2)).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
