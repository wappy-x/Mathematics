// The brachistochrone -- the same check as the Python, in Rust.  No crates.  A slide
// from (0, 0) to 2 m across, 1 m down; y points DOWN.  Road 1: the Beltrami cycloid.
// Road 2: the fastest n-chute slide by golden-section search.  Ramp and arc: two roads.
use std::f64::consts::PI;
const G: f64 = 9.81; const X: f64 = 2.0; const Y: f64 = 1.0;
fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // root finder written out here
    for _ in 0..200 {
        let m = (a + b) / 2.0;
        if f(a) * f(m) > 0.0 { a = m } else { b = m }
    }
    (a + b) / 2.0
}
fn chute(xa: f64, ya: f64, xb: f64, yb: f64) -> f64 {  // straight chute: length over mean speed
    2.0 * ((xb - xa).powi(2) + (yb - ya).powi(2)).sqrt() / ((2.0 * G * ya).sqrt() + (2.0 * G * yb).sqrt())
}
fn best_slide(n: usize) -> (f64, Vec<f64>, Vec<f64>) {  // road 2: sweep the corners 25n times
    let xs: Vec<f64> = (0..=n).map(|i| X * i as f64 / n as f64).collect();
    let mut ys: Vec<f64> = (0..=n).map(|i| Y * i as f64 / n as f64).collect();
    for _ in 0..25 * n {
        for i in 1..n {
            let f = |y: f64| chute(xs[i - 1], ys[i - 1], xs[i], y) + chute(xs[i], y, xs[i + 1], ys[i + 1]);
            let (mut a, mut b) = (1e-12, 2.0);
            for _ in 0..60 {
                let (m1, m2) = (a + 0.382 * (b - a), b - 0.382 * (b - a));
                if f(m1) < f(m2) { b = m2 } else { a = m1 }
            }
            ys[i] = (a + b) / 2.0;
        }
    }
    ((0..n).map(|i| chute(xs[i], ys[i], xs[i + 1], ys[i + 1])).sum(), xs, ys)
}
fn functional(y: &dyn Fn(f64) -> f64, dy: &dyn Fn(f64) -> f64) -> f64 { // x = X s^4, midpoint rule
    let (n, mut total) = (20000, 0.0);
    for k in 0..n {
        let s = (k as f64 + 0.5) / n as f64;
        let x = X * s.powi(4);
        total += 4.0 * X * s.powi(3) * ((1.0 + dy(x).powi(2)) / (2.0 * G * y(x))).sqrt() / n as f64;
    }
    total
}
fn main() {
    let th = bisect(&|t: f64| t - t.sin() - (X / Y) * (1.0 - t.cos()), 0.1, 6.2);
    let r = Y / (1.0 - th.cos());
    let t_cyc = th * (r / G).sqrt();
    let cyc = |t: f64| (r * (t - t.sin()), r * (1.0 - t.cos()));
    println!("cycloid: end angle {:.4} rad, rolling radius R = {:.4} m, lowest point {:.4} m down", th, r, 2.0 * r);
    println!("cycloid time, closed form theta*sqrt(R/g) = {:.4} x {:.4} = {:.4} s", th, (r / G).sqrt(), t_cyc);
    let bel: Vec<f64> = [0.5, 1.5, 2.5, 3.4].iter().map(|&t: &f64| {  // Beltrami's y(1+y'^2)
        let (p, q) = (cyc(t - 1e-6), cyc(t + 1e-6));
        cyc(t).1 * (1.0 + ((q.1 - p.1) / (q.0 - p.0)).powi(2))
    }).collect();
    let bs: Vec<String> = bel.iter().map(|b| format!("{:.6}", b)).collect();
    println!("Beltrami y(1+y'^2) at angles 0.5, 1.5, 2.5, 3.4: {}; 2R = {:.6}", bs.join(", "), 2.0 * r);
    let polys: Vec<(usize, (f64, Vec<f64>, Vec<f64>))> = [8, 16, 32].iter().map(|&n| (n, best_slide(n))).collect();
    for (n, p) in &polys { println!("fastest {:2}-chute slide: {:.4} s, above the cycloid by {:.4} s", n, p.0, p.0 - t_cyc) }
    let (_, xs, ys) = &polys[2].1;
    let gap = (0..33).map(|i| (ys[i] - cyc(bisect(&|t: f64| cyc(t).0 - xs[i], 0.0, th)).1).abs()).fold(0.0, f64::max);
    println!("32-chute corners vs cycloid depth at the same x: largest gap {:.2} cm", 100.0 * gap);
    let t_ramp = (2.0 * (X * X + Y * Y) / (G * Y)).sqrt();
    let t_ramp2 = functional(&|x: f64| Y * x / X, &|_x: f64| Y / X);
    println!("straight ramp: closed form {:.4} s, by the functional {:.4} s", t_ramp, t_ramp2);
    let c = (X * X + Y * Y) / (2.0 * X);
    let ang = PI - bisect(&|a: f64| a.cos() - (X - c) / c, 0.0, 3.14);
    let (m, h) = (20000, ang.sqrt() / 20000.0);
    let t_arc = (c / (2.0 * G)).sqrt() * (0..m).map(|k| { let u = (k as f64 + 0.5) * h; 2.0 * u / (u * u).sin().sqrt() }).sum::<f64>() * h;
    let t_arc2 = functional(&|x: f64| (x * (2.0 * c - x)).sqrt(), &|x: f64| (c - x) / (x * (2.0 * c - x)).sqrt());
    println!("circular arc, centre {:.2} m across, radius {:.2} m: by angle {:.4} s, by the functional {:.4} s", c, c, t_arc, t_arc2);
    println!("mistake, shortest = fastest: the ramp takes {:.4} s, {:.4} s slower", t_ramp, t_ramp - t_cyc);
    println!("mistake, speed sqrt(g y) not sqrt(2 g y): cycloid time comes out {:.4} s", t_cyc * 2f64.sqrt());
    println!("mistake, slide must end level (C = 1 m, R = 0.5 m): it bottoms out at x = {:.4} m, not 2", 0.5 * PI);
    let pts: Vec<String> = (0..13).map(|k| { let p = cyc(th * k as f64 / 12.0); format!("{:.1},{:.1}", 40.0 + 150.0 * p.0, 30.0 + 150.0 * p.1) }).collect();
    println!("figure, 150 px per m, origin (40, 30): cycloid {}", pts.join(" "));
    println!("figure, arc radius {:.1} px, lowest ({:.1}, {:.1}); cycloid lowest ({:.1}, {:.1})", 150.0 * c, 40.0 + 150.0 * c, 30.0 + 150.0 * c, 40.0 + 150.0 * PI * r, 30.0 + 300.0 * r);
    let d: Vec<f64> = polys.iter().map(|(_, p)| p.0 - t_cyc).collect();
    assert!(0.0 < d[2] && d[2] < d[1] && d[1] < d[0] && d[0] < 0.02);   // search never beats the cycloid
    assert!(bel.iter().all(|b| (b - 2.0 * r).abs() < 1e-5));            // Beltrami constant is 2R
    assert!((t_ramp - t_ramp2).abs() < 1e-4 && (t_arc - t_arc2).abs() < 1e-3); // two roads each
    assert!(t_cyc < t_arc && t_arc < t_ramp);                             // the order on the card
    println!("ALL CHECKS PASS");
}
