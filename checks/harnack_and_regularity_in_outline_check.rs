// Harnack and regularity: the same check as harnack_and_regularity_in_outline_check.py, in Rust.
// A 10 cm round plate, faces insulated, rim 100 C on its top half and 0 C on its bottom half.
// Temperatures are rises above the 0 C clamp; positions scaled by R. Standard library only.
use std::f64::consts::PI;

const R: f64 = 0.1; // plate radius in m
const HOT: f64 = 100.0; // hot clamp in C
const M: f64 = HOT / 2.0; // largest |u - 50| anywhere: the size the slope bounds use

fn u(x: f64, y: f64) -> f64 {
    // closed form: 50 + (100/pi) * angle, inside the unit disc
    HOT / 2.0 + HOT / PI * (2.0 * y).atan2(1.0 - x * x - y * y)
}

fn poisson(x: f64, y: f64, a: f64, b: f64) -> f64 {
    // rim held at HOT on angles a..b, 0 elsewhere: kernel sum
    let n = 20000;
    let w = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 0..n {
        let t = a + (k as f64 + 0.5) * w;
        s += (1.0 - x * x - y * y) / ((x - t.cos()).powi(2) + (y - t.sin()).powi(2));
    }
    HOT * s * w / (2.0 * PI)
}

fn series(x: f64, y: f64) -> f64 {
    // 50 + (200/pi) sum over odd k of r^k sin(k t) / k, to k = 21
    let (r, t) = ((x * x + y * y).sqrt(), y.atan2(x));
    let s: f64 = (1..22).step_by(2).map(|k| r.powi(k) * (k as f64 * t).sin() / k as f64).sum();
    HOT / 2.0 + 2.0 * HOT / PI * s
}

fn arc(x: f64, y: f64, w: f64) -> f64 {
    // rim held at 1 on angles pi/2-w..pi/2+w: harmonic measure
    let (a, b) = (PI / 2.0 - w, PI / 2.0 + w);
    let (px, py, qx, qy) = (b.cos() - x, b.sin() - y, a.cos() - x, a.sin() - y);
    (py * qx - px * qy).atan2(px * qx + py * qy) / PI - w / PI
}

fn close(a: f64, b: f64, tol: f64) {
    assert!((a - b).abs() <= tol, "{} {}", a, b);
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    println!("centre: closed form {:.4}, Poisson sum {:.4}, series {:.4} C", u(0.0, 0.0), poisson(0.0, 0.0, 0.0, PI), series(0.0, 0.0));
    for y in [0.5, -0.5] {
        let v = [u(0.0, y), poisson(0.0, y, 0.0, PI), series(0.0, y)];
        println!("at y = {:+.0} cm: closed form {:.4}, Poisson sum {:.4}, series {:.4} C", y * 10.0, v[0], v[1], v[2]);
        close(v[0], v[1], 1e-6);
        close(v[0], v[2], 1e-6); // inside the tail bound
    }
    let tail = 2.0 * HOT / PI * 0.5f64.powi(23) / 23.0 / 0.75; // odd terms from k = 23 on, a geometric tail
    println!("series to k = 21, tail bound at r = 5 cm: {:.7} C", tail);
    let ring: Vec<f64> = (0..3600).map(|k| {
        let t = 2.0 * PI * k as f64 / 3600.0;
        u(0.5 * t.cos(), 0.5 * t.sin())
    }).collect();
    let lo = ring.iter().cloned().fold(f64::MAX, f64::min);
    let hi = ring.iter().cloned().fold(f64::MIN, f64::max);
    let c = u(0.0, 0.0); // centre value: Harnack needs nothing else
    println!("Harnack on the 5 cm circle: floor u(0)/3 = {:.4}, cap 3u(0) = {:.4} C", c / 3.0, 3.0 * c);
    println!("actual on the 5 cm circle: min {:.4}, max {:.4}, ratio {:.4} <= 9", lo, hi, hi / lo);
    assert!(c / 3.0 <= lo && hi <= 3.0 * c && hi / lo <= 9.0);
    let pts: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    let cm: Vec<String> = pts.iter().map(|r| format!("{}", (10.0 * r) as i64)).collect();
    println!("chart, distance down, cm: {}", cm.join(", "));
    println!("chart, true temperature:  {}", join(&pts.iter().map(|&r| u(0.0, -r)).collect::<Vec<_>>(), 2));
    println!("chart, Harnack floor:     {}", join(&pts.iter().map(|&r| c * (1.0 - r) / (1.0 + r)).collect::<Vec<_>>(), 2));
    assert!(pts.iter().all(|&r| u(0.0, -r) >= c * (1.0 - r) / (1.0 + r) - 1e-12));
    for deg in [90.0, 10.0, 1.0, 0.1] {
        // a narrower hot arc pushes the ratio down to the floor 1/3
        let w = deg * PI / 180.0;
        let q = arc(0.0, -0.5, w) / arc(0.0, 0.0, w);
        let q2 = poisson(0.0, -0.5, PI / 2.0 - w, PI / 2.0 + w) / poisson(0.0, 0.0, PI / 2.0 - w, PI / 2.0 + w);
        println!("hot arc half-width {:4.1} deg: u(5 cm down)/u(centre) = {:.6} (kernel sum {:.6})", deg, q, q2);
        close(q, q2, 1e-6);
        assert!(q >= 1.0 / 3.0);
    }
    let pk2 = |y: f64| (1.0 - y * y) / (1.0 - y).powi(2); // 2-D Poisson kernel, pole at the top
    let pk3 = |y: f64| (1.0 - y * y) / (1.0 - y).abs().powi(3); // 3-D Poisson kernel, pole at the top
    let r3 = [1.5 / 0.5, pk2(0.5) / pk2(-0.5), pk3(0.5) / pk3(-0.5)];
    println!("Harnack max/min on the half ball, 3^d: d=1 {:.4}, d=2 {:.4}, d=3 {:.4}", r3[0], r3[1], r3[2]);
    close(r3[1], 9.0, 1e-9);
    close(r3[2], 27.0, 1e-9);
    let h = 1e-5; // slopes in K per m: scaled slope / R
    let g0 = 2.0 * HOT / PI / R;
    let fd = (u(0.0, h) - u(0.0, -h)) / (2.0 * h) / R;
    println!("slope at centre: exact {:.4}, centred difference {:.4}, bound 2M/R = {:.4} K/m", g0, fd, 2.0 * M / R);
    close(g0, fd, 1e-3);
    assert!(g0 <= 2.0 * M / R);
    for d in [0.05, 0.01, 0.001] {
        // approaching the rim point where 100 C meets 0 C
        let s = 1.0 - d / R;
        let ex = 2.0 * HOT / PI / (1.0 - s * s) / R;
        let fd = (u(s, h) - u(s, -h)) / (2.0 * h) / R;
        println!("slope {:5.1} mm from the jump: exact {:.1}, centred difference {:.1}, bound 2M/d = {:.1} K/m", d * 1000.0, ex, fd, 2.0 * M / d);
        close(ex, fd, 1e-3 * ex);
        assert!(ex <= 2.0 * M / d);
    }
    let mut exk = vec![]; // the formula's k-th slopes, checked by differences below
    for k in [1i32, 3, 5, 7] {
        // k-th slope up the middle at the centre, scaled (per R^k)
        let fact: f64 = (1..k).map(|i| i as f64).product();
        let (ex, bd) = (2.0 * HOT / PI * fact, M * ((2 * k) as f64).powi(k));
        exk.push(ex);
        println!("k = {}: |d^k u/dy^k| at centre exact {:.2}, bound M(2k)^k = {:.0}", k, ex, bd);
        assert!(ex <= bd);
    }
    let d3 = (u(0.0, 2e-2) - 2.0 * u(0.0, 1e-2) + 2.0 * u(0.0, -1e-2) - u(0.0, -2e-2)) / (2.0 * 1e-6);
    let d5 = (u(0.0, 3e-2) - 4.0 * u(0.0, 2e-2) + 5.0 * u(0.0, 1e-2) - 5.0 * u(0.0, -1e-2) + 4.0 * u(0.0, -2e-2) - u(0.0, -3e-2)) / (2.0 * 1e-10);
    println!("third and fifth slopes by differences, step 0.01: {:.2} and {:.2} (formula {:.2} and {:.2})", -d3, d5, exk[1], exk[2]);
    close(-d3, exk[1], 0.1);
    close(d5, exk[2], 5e-3 * exk[2]); // step^2 error: 0.1 % at k = 5
    let ty: f64 = (1..200).step_by(2).map(|k| 2.0 * HOT / PI * (if (k / 2) % 2 == 0 { 1.0 } else { -1.0 }) * 0.5f64.powi(k) / k as f64).sum();
    println!("Taylor series up the middle at y = 5 cm: {:.6}, closed form {:.6}", HOT / 2.0 + ty, u(0.0, 0.5));
    close(HOT / 2.0 + ty, u(0.0, 0.5), 1e-9);
    for big in [10.0f64, 100.0, 1000.0] {
        // Liouville by Harnack in 3-D: bounds at 1 m from the centre
        println!("3-D Harnack, ball of {:4} m, point 1 m out: {:.6} <= u/u(0) <= {:.6}", big as i64, big * (big - 1.0) / (big + 1.0).powi(2), big * (big + 1.0) / (big - 1.0).powi(2));
    }
    println!("Liouville slope bound d*M/r, M = {:.0} C, d = 2: r = 1 m {:.4}, r = 1 km {:.4} K/m", M, 2.0 * M / 1.0, 2.0 * M / 1000.0);
    let (x0, y0, rho) = (0.3, 0.2, 0.3);
    let (mut num, mut den, mut nq) = (0.0, 0.0, 0.0);
    for i in 0..200 {
        // Weyl: a radial smoothing bump leaves a harmonic function unchanged
        let s = (i as f64 + 0.5) / 200.0;
        let eta = (-1.0 / (1.0 - s * s)).exp() * s;
        for j in 0..64 {
            let t = 2.0 * PI * j as f64 / 64.0;
            let (xx, yy) = (x0 + rho * s * t.cos(), y0 + rho * s * t.sin());
            num += eta * u(xx, yy);
            nq += eta * (xx * xx + yy * yy);
            den += eta;
        }
    }
    println!("Weyl smoothing at (3, 2) cm, radius 3 cm: smoothed {:.6}, point value {:.6} C", num / den, u(x0, y0));
    println!("same smoothing of |x|^2 (not harmonic): smoothed {:.6}, point value {:.6}", nq / den, x0 * x0 + y0 * y0);
    close(num / den, u(x0, y0), 1e-9);
    assert!(nq / den - 0.13 > 0.01);
    println!("breaks, sign: u = 100y/R has centre 0, Harnack forces 0, true value at 5 cm {:.1} C", 100.0 * 0.5);
    let ph = |r: f64| 10.0 * (R / r).ln(); // point heater at the centre, rim 0 C
    println!("breaks, point heater: {:.4} C at 5 cm, {:.4} C at 1 micron, ratio {:.2} > 9", ph(0.05), ph(1e-6), ph(1e-6) / ph(0.05));
    assert!(ph(1e-6) / ph(0.05) > 9.0);
    let (a, b) = (u(0.0, 0.99), u(0.0, -0.99));
    println!("breaks, circle reaching 9.9 cm: {:.4} and {:.4} C, ratio {:.1} > 9", a, b, a / b);
    let sch = |x: f64, y: f64| (x * x - y * y) * (-(x * x + y * y).sqrt().ln()).sqrt(); // scaled, near 0
    for e in [2, 4, 8, 16] {
        let s = e as f64 * 10f64.ln();
        println!("breaks, continuous f at r = 10^-{}: f = {:.4}, u_x1x1 = {:.4}", e, 2.0 / s.sqrt() + 0.25 * s.powf(-1.5), 2.0 * s.sqrt() + 0.5 / s.sqrt());
    }
    let (hh, y1) = (1e-4, 1e-2);
    let uxx = (sch(hh, y1) - 2.0 * sch(0.0, y1) + sch(-hh, y1)) / (hh * hh);
    let lap = uxx + (sch(0.0, y1 + hh) - 2.0 * sch(0.0, y1) + sch(0.0, y1 - hh)) / (hh * hh);
    println!("breaks, differences at r = 0.01: u_x1x1 {:.4}, f {:.4}", uxx, lap);
    let l = 100f64.ln();
    close(uxx, 2.0 * l.sqrt() + 0.5 / l.sqrt(), 1e-3);
    close(lap, 2.0 / l.sqrt() + 0.25 * l.powf(-1.5), 1e-3);
    println!("ALL CHECKS PASS");
}
