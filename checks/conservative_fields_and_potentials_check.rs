// Conservative fields -- the same check as the Python, in Rust.  No crates;
// sqrt, sin and cos are primitives.  Road one adds F(r(t)).r'(t) by a Simpson
// sum written here; road two is the potential difference found by hand.
type P = (f64, f64);
type Leg = (Box<dyn Fn(f64) -> P>, Box<dyn Fn(f64) -> P>); // position, velocity on clock t

fn simpson(f: &dyn Fn(f64) -> f64) -> f64 { // integral of f over the clock t, from 0 to 1
    let n = 200;
    let mut s = f(0.0) + f(1.0);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 / n as f64) }
    s / (3.0 * n as f64)
}
fn work(f: &dyn Fn(f64, f64) -> P, legs: &[Leg]) -> f64 { // road one
    legs.iter().map(|(r, v)| simpson(&|t| { let (p, w) = (r(t), v(t)); let q = f(p.0, p.1); q.0 * w.0 + q.1 * w.1 })).sum()
}
fn line(p: P, q: P) -> Leg {
    (Box::new(move |t| (p.0 + (q.0 - p.0) * t, p.1 + (q.1 - p.1) * t)), Box::new(move |_| (q.0 - p.0, q.1 - p.1)))
}
fn arc(rho: f64, a: f64, b: f64) -> Leg {
    (Box::new(move |t: f64| (rho * (a + (b - a) * t).cos(), rho * (a + (b - a) * t).sin())),
     Box::new(move |t: f64| (-rho * (b - a) * (a + (b - a) * t).sin(), rho * (b - a) * (a + (b - a) * t).cos())))
}
fn sq(cx: f64, s: f64) -> Vec<Leg> {
    let c = [(cx - s, -s), (cx + s, -s), (cx + s, s), (cx - s, s)];
    (0..4).map(|i| line(c[i], c[(i + 1) % 4])).collect()
}
fn z(v: f64) -> f64 { (v * 1e6).round() / 1e6 + 0.0 } // prints a rounding-sized -0 as 0
fn curl_parts(f: &dyn Fn(f64, f64) -> P, x: f64, y: f64) -> P { // difference quotients: dQ/dx and dP/dy
    let h = 1e-5;
    ((f(x + h, y).1 - f(x - h, y).1) / (2.0 * h), (f(x, y + h).0 - f(x, y - h).0) / (2.0 * h))
}

fn main() {
    let (mut lo, mut hi) = (1.0f64, 2.0f64); // pi built, not imported: cos crosses 0 at pi/2
    for _ in 0..60 { let m = (lo + hi) / 2.0; if m.cos() > 0.0 { lo = m } else { hi = m } }
    let pi = lo + hi;
    let bottle = |_x: f64, _y: f64| (0.0, -2.0 * 9.8); // 2 kg, g = 9.8 m/s^2
    let (a, b) = ((0.0, 0.0), (400.0, 300.0));
    let curve: Leg = (Box::new(|t| (400.0 * t, 300.0 * t * t)), Box::new(|t| (400.0, 600.0 * t)));
    let trails: Vec<(&str, Vec<Leg>)> = vec![("straight", vec![line(a, b)]), ("curve (400t, 300t^2)", vec![curve]),
        ("three switchbacks", vec![line(a, (400.0, 100.0)), line((400.0, 100.0), (0.0, 200.0)), line((0.0, 200.0), b)])];
    let drop = -2.0 * 9.8 * b.1 - (-2.0 * 9.8 * a.1); // road two: phi = -19.6 y, end minus start
    println!("bottle, 2 kg: gravity (0, -19.6) N; trailhead A (0, 0) m to hut B (400, 300) m");
    for (name, legs) in &trails { println!("{}: Simpson {:.6} J; potential difference {:.6} J", name, work(&bottle, legs), drop) }
    let (g, r) = (9.8f64, 6371000.0f64);
    let k = g * r * r; // planet, per kg: F = -k (x, y) / r^3, phi = k / r
    let planet = |x: f64, y: f64| { let d = (x * x + y * y).sqrt().powi(3); (-k * x / d, -k * y / d) };
    let (out, far) = (work(&planet, &[line((r, 0.0), (2.0 * r, 0.0))]), k / (2.0 * r) - k / r);
    let detour = work(&planet, &[arc(r, 0.0, pi / 2.0), line((0.0, r), (0.0, 2.0 * r)), arc(2.0 * r, pi / 2.0, 0.0)]);
    println!("planet, per kg, R = {:.0} m, R to 2R: straight out {:.4} MJ; arc, out, arc back {:.4} MJ; k/2R - k/R {:.4} MJ", r, out / 1e6, detour / 1e6, far / 1e6);
    println!("planet, 2 kg lifted 300 m: 2 (k/(R + 300) - k/R) = {:.2} J; m g h = {:.2} J", 2.0 * (k / (r + 300.0) - k / r), -2.0 * g * 300.0);
    let whirl = |x: f64, y: f64| (-y / (x * x + y * y), x / (x * x + y * y));
    let unit = |x: f64, y: f64| { let d = (x * x + y * y).sqrt().powi(3); (-x / d, -y / d) };
    let (cp, cw) = (curl_parts(&unit, 1.0, 2.0), curl_parts(&whirl, 1.0, 2.0));
    let (hand_p, hand_w) = (3.0 * 1.0 * 2.0 / 5f64.sqrt().powi(5), (2.0 * 2.0 - 1.0 * 1.0) / 25.0);
    println!("curl test at (1, 2), planet with k = 1: dQ/dx {:.6}, dP/dy {:.6}; by hand 3xy/r^5 = {:.6}", cp.0, cp.1, hand_p);
    println!("curl test at (1, 2), whirlpool: dQ/dx {:.6}, dP/dy {:.6}; by hand (y^2 - x^2)/r^4 = {:.6}", cw.0, cw.1, hand_w);
    let (round1, round2, beside) = (work(&whirl, &sq(0.0, 1.0)), work(&whirl, &sq(0.0, 2.0)), work(&whirl, &sq(4.0, 1.0)));
    println!("whirlpool, square round the drain, half-side 1: {:.6}; half-side 2: {:.6}; 2 pi = {:.6}", round1, round2, 2.0 * pi);
    println!("whirlpool, square beside the drain, centre (4, 0), half-side 1: {:.6}", z(beside));
    println!("mistake 1, zero curl so every loop gives 0: predicts 0, the square gives {:.6}", round1);
    println!("mistake 2, integrate P in x and stop: potential {:.0}, work 0 J, not {:.0} J", z(simpson(&|t| 400.0 * bottle(400.0 * t, 0.0).0)), drop);
    println!("mistake 3, potential energy U = 19.6 y used as phi: {:.0} J, not {:.0} J", 2.0 * 9.8 * 300.0, drop);
    println!("mistake 4, g h per kg for a climb of h = R: {:.4} MJ, not {:.4} MJ", -g * r / 1e6, far / 1e6);
    let (sx, sy) = (|x: f64| 50.0 + 0.6 * x, |y: f64| 210.0 - 0.6 * y);
    let pts: Vec<String> = (0..9).map(|t| format!("({:.1},{:.1})", sx(400.0 * t as f64 / 8.0), sy(300.0 * (t as f64 / 8.0).powi(2)))).collect();
    println!("figure 1, 0.6 units per m, curve: {}", pts.join(" "));
    println!("figure 1, switchback corners: ({:.0},{:.0}) ({:.0},{:.0}); arrows 1 unit per N: ({:.0},{:.0})->({:.0},{:.1}) ({:.0},{:.0})->({:.0},{:.1})",
             sx(400.0), sy(100.0), sx(0.0), sy(200.0), sx(100.0), sy(250.0), sx(100.0), sy(250.0) + 19.6, sx(350.0), sy(60.0), sx(350.0), sy(60.0) + 19.6);
    let arrows: Vec<String> = [(1.5, 0.0), (0.0, 1.5), (-1.5, 0.0), (0.0, -1.5)].iter().map(|&(x, y): &(f64, f64)| {
        let w = whirl(x, y);
        format!("({:.0},{:.0})->({:.0},{:.0})", 120.0 + 20.0 * x, 120.0 - 20.0 * y, 120.0 + 20.0 * x + 30.0 * w.0, 120.0 - 20.0 * y - 30.0 * w.1)
    }).collect();
    println!("figure 2, drain at (120,120), 20 units per m, arrows 30 units per m/s: {}", arrows.join(" "));
    assert!(trails.iter().all(|(_, legs)| (work(&bottle, legs) - drop).abs() < 1e-6)); // road one against road two
    assert!((out / far - 1.0).abs() < 1e-9 && (detour / far - 1.0).abs() < 1e-9); // the planet, both routes
    assert!([(cp.0, hand_p), (cp.1, hand_p), (cw.0, hand_w), (cw.1, hand_w)].iter().all(|&(c, h)| (c - h).abs() < 1e-7));
    assert!((round1 - 2.0 * pi).abs() < 1e-8 && (round2 - 2.0 * pi).abs() < 1e-8 && beside.abs() < 1e-8);
    println!("ALL CHECKS PASS");
}
