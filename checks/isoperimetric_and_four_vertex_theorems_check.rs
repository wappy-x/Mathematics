// Isoperimetric and four-vertex theorems -- the same check as the Python, in Rust. No crates.
// Areas from closed forms, shoelace sums and exact Fourier coefficients;
// vertices counted from the curvature formula and from circles through three neighbouring points.
use std::collections::BTreeMap;
use std::f64::consts::PI;

const L: f64 = 400.0; // metres of fencing wire
const M: usize = 4000; // points round each smooth curve

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // complex number
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }  fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }  fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn div(a: C, b: C) -> C { let d = b.re * b.re + b.im * b.im; c((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn abs(a: C) -> f64 { a.re.hypot(a.im) }  fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
fn f(x: f64, d: usize) -> String { format!("{:.*}", d, x) }

fn shoelace(v: &[C]) -> f64 { // area of a polygon, corners anticlockwise
    0.5 * (0..v.len()).fold(0.0, |s, j| { let (p, q) = (v[j], v[(j + 1) % v.len()]); s + (p.re * q.im - p.im * q.re) })
}
fn regular(k: usize, side: f64) -> Vec<C> {
    let r = side / (2.0 * (PI / k as f64).sin());
    (0..k).map(|j| scale(cis(2.0 * PI * j as f64 / k as f64), r)).collect()
}
fn coeffs(v: &[C], n_max: i64) -> BTreeMap<i64, C> { // exact c_n of a polygon walked at constant speed
    let sides: Vec<C> = (0..v.len()).map(|j| sub(v[(j + 1) % v.len()], v[j])).collect();
    let p: f64 = sides.iter().map(|e| abs(*e)).sum();
    let mut ts = vec![0.0];
    for e in &sides { let last = *ts.last().unwrap(); ts.push(last + 2.0 * PI * abs(*e) / p); }
    let mut out = BTreeMap::new();
    for n in -n_max..=n_max {
        if n == 0 { continue; }
        let mut d = c(0.0, 0.0);  for (j, e) in sides.iter().enumerate() {
            let ae = abs(*e); let dir = c(e.re / ae * p / (2.0 * PI), e.im / ae * p / (2.0 * PI));
            d = add(d, mul(dir, sub(cis(-(n as f64) * ts[j]), cis(-(n as f64) * ts[j + 1]))));
        }  d = div(d, c(0.0, 2.0 * PI * n as f64));
        out.insert(n, div(d, c(0.0, n as f64))); // z' has coefficient i n c_n
    }
    out
}
fn weighted(cs: &BTreeMap<i64, C>, n_max: i64, w: fn(i64) -> i64) -> f64 {
    let mut s = 0.0;
    for (n, v) in cs { if n.abs() <= n_max { s += w(*n) as f64 * (abs(*v) * abs(*v)); } }
    PI * s
}
fn area_sum(cs: &BTreeMap<i64, C>, n_max: i64) -> f64 { weighted(cs, n_max, |n| n) }
fn lost_sum(cs: &BTreeMap<i64, C>, n_max: i64) -> f64 { weighted(cs, n_max, |n| n * n - n) }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, steps: usize) -> f64 {
    let h = (b - a) / steps as f64;
    let mut s = 0.0;  for i in 0..=steps { let w = if i == 0 || i == steps { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; s += w * g(a + i as f64 * h); }
    h / 3.0 * s
}
fn ell_len(a: f64, b: f64, t: f64, steps: usize) -> f64 { simpson(&|u: f64| (a * u.sin()).hypot(b * u.cos()), 0.0, t, steps) }
fn ellipse_for(ratio: f64) -> (f64, f64) { // semi-axes, a = ratio * b, perimeter exactly L
    let (mut lo, mut hi, mut b) = (1.0, L, 0.0);
    for _ in 0..100 { b = (lo + hi) / 2.0; if ell_len(ratio * b, b, 2.0 * PI, 2000) > L { hi = b; } else { lo = b; } }
    (ratio * b, b)
}
fn ell_kappa(a: f64, b: f64, t: f64) -> f64 { a * b / (a * a * t.sin().powi(2) + b * b * t.cos().powi(2)).powf(1.5) }
fn ell_pts(a: f64, b: f64) -> Vec<C> { (0..M).map(|i| { let t = 2.0 * PI * i as f64 / M as f64; c(a * t.cos(), b * t.sin()) }).collect() }
fn pol_r(p: f64, q: f64, w: f64, t: f64) -> f64 { p + q * t.cos() + w * (2.0 * t).sin() } // polar curve, metres
fn pol_pts(p: f64, q: f64, w: f64) -> Vec<C> { (0..M).map(|i| { let t = 2.0 * PI * i as f64 / M as f64; scale(cis(t), pol_r(p, q, w, t)) }).collect() }
fn pol_kappa(p: f64, q: f64, w: f64) -> Vec<f64> {
    (0..M).map(|i| { let t = 2.0 * PI * i as f64 / M as f64;
        let (r, r1, r2) = (pol_r(p, q, w, t), -q * t.sin() + 2.0 * w * (2.0 * t).cos(), -q * t.cos() - 4.0 * w * (2.0 * t).sin());
        (r * r + 2.0 * r1 * r1 - r * r2) / (r * r + r1 * r1).powf(1.5)
    }).collect()
}
fn kappa3(z0: C, z1: C, z2: C) -> f64 { // signed curvature of the circle through three points
    let (u, v) = (sub(z1, z0), sub(z2, z1));  2.0 * (u.re * v.im - u.im * v.re) / (abs(u) * abs(v) * abs(sub(z2, z0)))
}
fn discrete(z: &[C]) -> Vec<f64> { (0..M).map(|i| kappa3(z[(i + M - 1) % M], z[i], z[(i + 1) % M])).collect() }
fn extremes(k: &[f64]) -> usize { let n = k.len(); (0..n).filter(|&i| (k[i] - k[(i + n - 1) % n]) * (k[(i + 1) % n] - k[i]) < 0.0).count() }

fn main() {
    // 1. The circle and five other paddocks, all fenced with 400 m
    let r = L / (2.0 * PI); let a_circle = L * L / (4.0 * PI);
    println!("paddock, wire length L (m) {}  circle radius (m) {}  circle area (m^2) {}", f(L, 6), f(r, 6), f(a_circle, 6));
    let (a, b) = ellipse_for(2.0);
    let s4 = L / 4.0; let square = vec![c(0.0, 0.0), c(s4, 0.0), c(s4, s4), c(0.0, s4)]; // side L/4
    let shapes: Vec<(&str, Vec<C>)> = vec![("equilateral triangle", regular(3, L / 3.0)),
        ("2:1 rectangle", vec![c(0.0, 0.0), c(L / 3.0, 0.0), c(L / 3.0, L / 6.0), c(0.0, L / 6.0)]),
        ("square", square.clone()), ("2:1 ellipse", ell_pts(a, b)), ("regular hexagon", regular(6, L / 6.0))];
    for (name, v) in &shapes {
        let area = if *name != "2:1 ellipse" { shoelace(v) } else { PI * a * b };
        if *name != "2:1 ellipse" { assert!((area_sum(&coeffs(v, 1000), 1000) - area).abs() < 1e-6 * area, "{}", name); }
        else { assert!((shoelace(v) - area).abs() < 1e-6 * area); }
        assert!(area < a_circle);
        let bar = "#".repeat((area / 400.0).round() as usize);
        println!("bars, {:<20} {:<32} {:>9} m^2  ratio 4piA/L^2 = {}", name, bar, f(area, 1), f(4.0 * PI * area / (L * L), 4));
    }
    println!("bars, {:<20} {:<32} {:>9} m^2  ratio 4piA/L^2 = {}", "circle", "#".repeat((a_circle / 400.0).round() as usize), f(a_circle, 1), f(1.0, 4));

    // 2. The square, circle by circle
    let sq = coeffs(&square, 10000);
    let closed = |n: i64| L / (2.0 * PI) * 2.0 * 2f64.sqrt() / (PI * (n * n) as f64); // |c_n| for n = 1 mod 4
    for n in [1i64, -3, 5, -7] {
        let m = abs(sq[&n]);
        assert!((m - closed(n)).abs() < 1e-9);
        println!("square, n = {:>2}  |c_n| (m) {}  term pi (n^2 - n)|c_n|^2 (m^2) {}", n, f(m, 6), f(PI * (n * n - n) as f64 * (m * m), 2));
    }
    assert!(sq.iter().filter(|(n, _)| n.rem_euclid(4) != 1).all(|(_, v)| abs(*v) < 1e-9)); // only n = 1, -3, 5, -7, ...
    let exact = L * L / (4.0 * PI) - L * L / 16.0; // from the sums pi^2/8 and pi^3/32
    assert!((lost_sum(&sq, 10000) + PI * closed(1).powi(2) / 20000.0 - exact).abs() < 1e-3); // sum plus its 1/N tail
    println!("square, L/(2 pi) (m) {}  area from Fourier, N = 1000 (m^2) {}", f(L / (2.0 * PI), 6), f(area_sum(&sq, 1000), 6));
    for n in [10i64, 100, 1000, 10000] {
        let s = lost_sum(&sq, n);
        println!("square, lost area to the circle, sum to |n| = {:>5} (m^2) {}  short by {}", n, f(s, 4), f(exact - s, 4));
    }
    println!("square, lost area exact, L^2/(4 pi) - L^2/16 (m^2) {}", f(exact, 4));
    let ratio = (exact - lost_sum(&sq, 100)) / (exact - lost_sum(&sq, 1000));
    assert!(9.0 < ratio && ratio < 11.0); // tail falls like 1/N

    // 3. Four vertices on the 2:1 oval paddock
    let k: Vec<f64> = (0..M).map(|i| ell_kappa(a, b, 2.0 * PI * i as f64 / M as f64)).collect();
    let kd = discrete(&ell_pts(a, b));
    assert!(extremes(&k) == 4 && extremes(&kd) == 4);
    assert!((0..M).all(|i| (k[i] - kd[i]).abs() < 1e-6) && (kd[0] - a / (b * b)).abs() < 1e-6);
    println!("oval, semi-axes a, b (m) {} {}  perimeter, Simpson 20 and 2000 steps (m) {} {}",
        f(a, 4), f(b, 4), f(ell_len(a, b, 2.0 * PI, 20), 4), f(ell_len(a, b, 2.0 * PI, 2000), 4));
    println!("oval, kappa max a/b^2 (1/m) {}  radius {}  three-point circle {}", f(a / (b * b), 6), f(b * b / a, 3), f(kd[0], 6));
    println!("oval, kappa min b/a^2 (1/m) {}  radius {}  three-point circle {}", f(b / (a * a), 6), f(a * a / b, 3), f(kd[M / 4], 6));
    println!("oval, vertices from the formula {}  from three-point circles {}", extremes(&k), extremes(&kd));
    let (mut s_pts, mut k_pts) = (vec![], vec![]);
    for j in 0..17 {
        let (mut lo, mut hi) = (0.0, 2.0 * PI);
        for _ in 0..60 { let mid = (lo + hi) / 2.0; if ell_len(a, b, mid, 200) < 25.0 * j as f64 { lo = mid; } else { hi = mid; } }
        s_pts.push(format!("{}", 25 * j)); k_pts.push(f(1000.0 * ell_kappa(a, b, (lo + hi) / 2.0), 2));
    }
    println!("chart, arc length s (m)   {}", s_pts.join(" "));
    println!("chart, kappa (1/km)       {}", k_pts.join(" "));

    // 4. A lopsided egg, and the proof's identity: x and y weighted by d kappa total zero
    let (z, kl) = (pol_pts(60.0, 20.0, 4.0), pol_kappa(60.0, 20.0, 4.0));
    let (kmin, kmax) = kl.iter().fold((f64::MAX, f64::MIN), |(lo, hi), &x| (lo.min(x), hi.max(x)));
    assert!(kmin > 0.0 && extremes(&kl) == 4 && extremes(&discrete(&z)) == 4);
    println!("egg, r = 60 + 20 cos t + 4 sin 2t: vertices {}  three-point {}  kappa min, max (1/m) {} {}",
        extremes(&kl), extremes(&discrete(&z)), f(kmin, 6), f(kmax, 6));
    for (name, part) in [("x", (|w: C| w.re) as fn(C) -> f64), ("y", |w: C| w.im)] {
        let (mut tot, mut size) = (0.0, 0.0);
        for i in 0..M { tot += part(scale(add(z[i], z[(i + 1) % M]), 0.5)) * (kl[(i + 1) % M] - kl[i]); size += (part(z[i]) * (kl[(i + 1) % M] - kl[i])).abs(); }
        assert!(tot.abs() < 1e-6 * size);
        println!("identity, egg: sum {} d(kappa) = {}  against sum |{} d(kappa)| = {}", name, f(tot, 9), name, f(size, 6));
    }

    // 5. What breaks, and the experiments
    let semi: Vec<C> = (0..=M).map(|i| scale(cis(PI * i as f64 / M as f64), L / PI)).collect();
    assert!((shoelace(&semi) - L * L / (2.0 * PI)).abs() < 1e-7 * L * L);
    println!("breaks, fence ends on a straight river bank: semicircle (m^2) {}  4000-gon {}", f(L * L / (2.0 * PI), 2), f(shoelace(&semi), 2));
    let wrong = PI * (2.0 * (a * a + b * b)).sqrt();
    assert!(wrong > L);
    println!("breaks, oval's angle parameter, not constant speed: 'length' (m) {}  lost area {}  true {}",
        f(wrong, 2), f(wrong * wrong / (4.0 * PI) - PI * a * b, 2), f(a_circle - PI * a * b, 2));
    println!("breaks, square's sum cut at n = 1, -3, 5, -7 (m^2) {}  true {}", f(lost_sum(&sq, 7), 2), f(exact, 2));
    let lp = pol_kappa(30.0, 60.0, 0.0);
    assert!(lp.iter().all(|&k| k > 0.0) && extremes(&lp) == 2 && extremes(&discrete(&pol_pts(30.0, 60.0, 0.0))) == 2); // bends left throughout
    println!("breaks, loop r = 30 + 60 cos t crosses itself: vertices {}", extremes(&lp));
    let (a3, b3) = ellipse_for(3.0);
    assert!(extremes(&(0..M).map(|i| ell_kappa(a3, b3, 2.0 * PI * i as f64 / M as f64)).collect::<Vec<f64>>()) == 4);
    println!("try, 3:1 oval: a, b (m) {} {}  area (m^2) {}  vertices 4", f(a3, 4), f(b3, 4), f(PI * a3 * b3, 2));
    println!("try, 800 m of wire: square's lost area (m^2) {}  a 100 m circle (m^2) {}", f(800.0 * 800.0 / (4.0 * PI) - 200.0 * 200.0, 2), f(100.0 * 100.0 / (4.0 * PI), 2));
    let six = pol_kappa(60.0, 30.0, 12.0);
    assert!(extremes(&six) == 6 && extremes(&discrete(&pol_pts(60.0, 30.0, 12.0))) == 6);
    println!("try, egg r = 60 + 30 cos t + 12 sin 2t: vertices {}", extremes(&six));
    println!("ALL CHECKS PASS");
}
