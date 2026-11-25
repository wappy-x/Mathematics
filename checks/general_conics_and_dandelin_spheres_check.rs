// Every conic -- the same check as the Python, in Rust.  No crates.
// Flower bed x^2 + xy + y^2 = 3 (metres); a lamp with a 30-degree half-angle beam, aimed 45 degrees off vertical.
use std::f64::consts::PI;
fn turn(a: f64, b: f64, c: f64, t: f64) -> (f64, f64, f64) { // the x^2, xy, y^2 numbers after turning the axes by t
    let (co, s) = (t.cos(), t.sin());
    (a * co * co + b * s * co + c * s * s, b * (co * co - s * s) - 2.0 * (a - c) * s * co, a * s * s - b * s * co + c * co * co)
}
fn halve(f: impl Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // road two: find where f changes sign
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if (f(mid) > 0.0) == (f(lo) > 0.0) { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn name(co: [i64; 4]) -> (i64, &'static str, f64, f64, f64) { // A x^2 + B xy + C y^2 + F = 0, centred
    let [a, b, c, f] = co; let d = b * b - 4 * a * c;
    let t = (b as f64).atan2((a - c) as f64) / 2.0;
    let (p, _, q) = turn(a as f64, b as f64, c as f64, t);
    let kd = if d == 0 { "parabola or parallel lines" } else if f == 0 { if d > 0 { "two crossing lines" } else { "one point" } } else if d > 0 { "hyperbola" } else if -(f as f64) / p > 0.0 { "ellipse" } else { "no points" };
    (d, kd, p, q, t.to_degrees())
}
fn scan(co: [i64; 4]) -> &'static str { // road five, no B^2 - 4AC: the signs A x^2 + B xy + C y^2 takes over a half-turn
    let [a, b, c, f] = co.map(|v| v as f64);
    let g: Vec<i32> = (0..1800).map(|i| (i as f64 / 10.0).to_radians()).map(|t| a * t.cos() * t.cos() + b * t.cos() * t.sin() + c * t.sin() * t.sin()).map(|v| (v > 1e-9) as i32 - (v < -1e-9) as i32).collect();
    if g.contains(&1) && g.contains(&-1) { if f == 0.0 { "two crossing lines" } else { "hyperbola" } } else if g.contains(&0) { "parabola or parallel lines" }
    else if f == 0.0 { "one point" } else if g[0] == (f < 0.0) as i32 - (f > 0.0) as i32 { "ellipse" } else { "no points" }
}
fn main() {
    let t = 1f64.atan2(0.0) / 2.0; let s2 = 2f64.sqrt(); // road one: cot 2t = (A - C)/B
    let th = halve(|u| turn(1.0, 1.0, 1.0, u).1, 0.0, PI / 2.0); let (p, b2, q) = turn(1.0, 1.0, 1.0, t);
    let (sa, la) = ((3.0 / p).sqrt(), (3.0 / q).sqrt()); let c = (la * la - sa * sa).sqrt(); // semi-axes; centre to each peg
    let r: Vec<(f64, f64)> = (0..1800).map(|i| { let a = (i as f64 / 10.0).to_radians(); ((3.0 / (1.0 + a.cos() * a.sin())).sqrt(), i as f64 / 10.0) }).collect();
    let (mn, mx) = (r.iter().cloned().fold((f64::MAX, 0.0), |m, x| if x.0 < m.0 { x } else { m }), r.iter().cloned().fold((f64::MIN, 0.0), |m, x| if x.0 > m.0 { x } else { m }));
    println!("bed: B^2 - 4AC = {} -> {}; cot 2t = 0, t = {:.2} deg; halving on B' = 0: {:.2} deg", name([1, 1, 1, -3]).0, name([1, 1, 1, -3]).1, t.to_degrees(), th.to_degrees());
    println!("turned: {:.2} X^2 + {:.2} XY + {:.2} Y^2 = 3, so X^2/{:.2} + Y^2/{:.2} = 1, semi-axes {:.3} and {:.3}", p, b2.abs(), q, 3.0 / p, 3.0 / q, sa, la);
    println!("polar scan, 1800 directions: nearest {:.3} at {:.1} deg, farthest {:.3} at {:.1} deg", mn.0, mn.1, mx.0, mx.1);
    println!("pegs ({:.3}, {:.3}) and ({:.3}, {:.3}), c = {:.3}, string tied to both 2a = {:.3}, loop round both 2a + 2c = {:.3}, e = {:.4}, area {:.2} m^2",
             -c / s2, c / s2, c / s2, -c / s2, c, 2.0 * la, 2.0 * la + 2.0 * c, c / la, PI * sa * la);
    let eqs = [[1, 1, 1, -3], [0, 1, 0, -1], [2, 4, 5, -6], [1, 2, 1, 0], [1, 0, -1, 0], [1, 1, 1, 3]];
    for co in eqs {
        let (d, kd, pp, qq, ang) = name(co);
        println!("  ({}, {}, {}, {}): B^2 - 4AC = {}, {}, turn {:.2} deg, X^2 and Y^2 numbers {:.2}, {:.2}", co[0], co[1], co[2], co[3], d, kd, ang, pp, qq);
    }
    let inv: Vec<(f64, f64, f64)> = [0.0, 20.0, 45.0, 63.43494882, 100.0].iter().map(|a: &f64| turn(2.0, 4.0, 5.0, a.to_radians())).collect();
    let (ds, tr): (Vec<String>, Vec<String>) = inv.iter().map(|&(a, b, cc)| (format!("{:.2}", b * b - 4.0 * a * cc), format!("{:.2}", a + cc))).unzip();
    println!("2x^2 + 4xy + 5y^2 turned 0, 20, 45, 63.43, 100 deg: B'^2 - 4A'C' = {} | A' + C' = {}", ds.join(" "), tr.join(" "));
    let k = 30f64.to_radians().tan(); // cone x^2 + y^2 = k^2 z^2 cut by the plane z = m x + 1
    let cv: Vec<(f64, f64)> = [1.0, 1.0 / k, 3.0].iter().map(|&m: &f64| (m, (-4.0 * (1.0 - k * k * m * m) * 1e9).round() / 1e9 + 0.0)).collect();
    let cs: Vec<String> = cv.iter().map(|&(m, v)| format!("m = {:.3}: B^2 - 4AC = {:.3}", m, v)).collect();
    println!("cone slice, plane slope m: {}", cs.join("; "));
    let (al, be) = (30f64.to_radians(), 45f64.to_radians()); let tilt = PI / 2.0 - be; // beam half-angle, ground's angle to axis, tilt from vertical
    let hh = 2.0 * la / ((tilt + al).tan() - (tilt - al).tan()); let (x1, x2) = (hh * (tilt - al).tan(), hh * (tilt + al).tan()); // patch 2a long
    println!("lamp: height {:.3}, lit patch from {:.3} to {:.3}, length {:.3}, e = cos 45 / cos 30 = {:.4}", hh, x1, x2, x2 - x1, be.cos() / al.cos());
    let sph: Vec<(f64, f64, f64, f64)> = [1.0, -1.0].iter().map(|&s: &f64| hh / (tilt.cos() + s * al.sin())) // the two Dandelin spheres
        .map(|d| (d * tilt.sin(), hh - d * tilt.cos(), d * al.sin(), d * al.cos())).collect(); // centre x, z; radius; touch distance
    let sp: Vec<String> = sph.iter().map(|&(x, z, q, g)| format!("centre ({:.3}, {:.3}), radius {:.3}, touches the beam {:.3} from the lamp", x, z, q, g)).collect();
    println!("spheres: {}; gap {:.3}", sp.join("; "), sph[1].3 - sph[0].3);
    let (u, e1) = ([tilt.sin(), 0.0, -tilt.cos()], [tilt.cos(), 0.0, tilt.sin()]); let (mut lo, mut hi, mut half, mut tang) = (f64::MAX, f64::MIN, 0f64, 0f64); // beam axis; a direction square to it
    for i in 0..3600 { // road four: 3600 points on the lit patch's rim, in 3-D
        let f = (i as f64 / 10.0).to_radians();
        let w: Vec<f64> = (0..3).map(|j| al.cos() * u[j] + al.sin() * (f.cos() * e1[j] + if j == 1 { f.sin() } else { 0.0 })).collect();
        let l = -hh / w[2]; let (px, py) = (l * w[0], l * w[1]);
        let (f1, f2) = (((px - sph[0].0).powi(2) + py * py).sqrt(), ((px - sph[1].0).powi(2) + py * py).sqrt());
        lo = lo.min(f1 + f2); hi = hi.max(f1 + f2); half = half.max(py.abs());
        tang = tang.max((f1 - (l - sph[0].3)).abs()).max((f2 - (sph[1].3 - l)).abs());
    }
    println!("3600 rim points: PF1 + PF2 from {:.3} to {:.3}, half-width {:.3}", lo, hi, half);
    println!("mistakes: turn -45 deg gives {:.2} X^2 + {:.2} Y^2; (1.732, 1.732) gives {:.2}; drop xy: circle radius {:.3}; B^2 - AC = {}; r1 + r2 = {:.3}",
             turn(1.0, 1.0, 1.0, -t).0, turn(1.0, 1.0, 1.0, -t).2, 3.0 * 3f64.sqrt().powi(2), 3f64.sqrt(), 1 - 1, sph[0].2 + sph[1].2);
    let (fx, fz) = (|x: f64| 30.0 + 40.0 * x, |z: f64| 90.0 - 40.0 * z);
    let (pg, ci): (Vec<String>, Vec<String>) = sph.iter().map(|s| (format!("({:.2}, 90.00)", fx(s.0)), format!("({:.2}, {:.2}) r {:.2}", fx(s.0), fz(s.1), 40.0 * s.2))).unzip();
    println!("figure, 1 m = 40 units: lamp ({:.2}, {:.2}), patch ({:.2}, 90.00) ({:.2}, 90.00), pegs {}, circles {}", fx(0.0), fz(hh), fx(x1), fx(x2), pg.join(" "), ci.join(" "));
    let mut ends = Vec::new(); for s in [-1.0, 1.0] { let (a, b) = ((tilt + s * al).sin(), -(tilt + s * al).cos()); for l in [8.6, sph[0].3, sph[1].3] { ends.push(format!("({:.2}, {:.2})", fx(l * a), fz(hh + l * b))); } }
    println!("figure, beam ends and touch points: {}", ends.join(" "));
    assert!((th - t).abs() < 1e-12 && b2.abs() < 1e-12); // halving agrees with cot 2t; xy term gone
    assert!((mn.0 - sa).abs() + (mx.0 - la).abs() < 1e-9); // polar scan meets the turned semi-axes
    assert!(inv.iter().all(|&(a, b, cc)| (b * b - 4.0 * a * cc - (4.0 * 4.0 - 4.0 * 2.0 * 5.0)).abs() + (a + cc - (2.0 + 5.0)).abs() < 1e-9)); // B^2 - 4AC and A + C unchanged by every turn
    assert!((hi - 2.0 * la).abs() + (lo - 2.0 * la).abs() + (half - sa).abs() < 1e-6 && tang < 1e-9); // cone slice = bed
    assert!((c / la - be.cos() / al.cos()).abs() < 1e-12); // eccentricity two ways
    assert!(eqs.iter().all(|&co| name(co).1 == scan(co))); // B^2 - 4AC names each curve as the sign scan does
    assert!(cv.iter().all(|&(m, v)| (v > 0.0) as i32 - (v < 0.0) as i32 == (m > 1.0 / k) as i32 - (m < 1.0 / k) as i32)); // shallower, parallel, steeper than the cone's side
    println!("ALL CHECKS PASS");
}
