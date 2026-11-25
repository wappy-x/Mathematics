// Mean curvature flow -- the check behind the card.  Rust std only.
// Each shape moves down the gradient of its own size: a polygon down the gradient of its
// length, a profile spun round the z-axis down the gradient of its surface area.  A vertex
// moves by minus that gradient over its share of the size, the discrete kappa N or 2H n.
use std::f64::consts::PI;
type Pt = (f64, f64);
#[derive(Clone, Copy)]
struct X { v0: f64, v1: f64, cv: bool, k2: f64 } // curve: length, -, convex, int kappa^2 ds; surface: neck, bulb
fn f(x: f64) -> String { format!("{:.4}", x) }
fn curve(p: &[Pt]) -> (Vec<Pt>, f64, f64, X) {   // closed polygon, counterclockwise
    let n = p.len();
    let e: Vec<(f64, f64, f64)> = (0..n).map(|i| {
        let dx = p[(i + 1) % n].0 - p[i].0; let dy = p[(i + 1) % n].1 - p[i].1; (dx, dy, (dx * dx + dy * dy).sqrt()) }).collect();
    let (mut v, mut l, mut a, mut lmin, mut convex, mut k2) = (Vec::new(), 0.0, 0.0, e[0].2, true, 0.0);
    for i in 0..n {
        let ea = e[(i + n - 1) % n]; let b = e[i]; let m = (ea.2 + b.2) / 2.0; // the vertex's share of the length
        let vx = (b.0 / b.2 - ea.0 / ea.2) / m; let vy = (b.1 / b.2 - ea.1 / ea.2) / m;
        v.push((vx, vy)); k2 += (vx * vx + vy * vy) * m; // adds kappa^2 ds
        l += b.2; lmin = f64::min(lmin, b.2); convex = convex && ea.0 * b.1 - ea.1 * b.0 > 0.0;
        a += (p[i].0 * p[(i + 1) % n].1 - p[(i + 1) % n].0 * p[i].1) / 2.0;
    }
    (v, a, 0.2 * lmin * lmin, X { v0: l, v1: 0.0, cv: convex, k2 })
}
fn surface(p: &[Pt]) -> (Vec<Pt>, f64, f64, X) { // profile (z, r) from pole to pole, spun round the z-axis
    let n = p.len() - 1; let mut e = Vec::new(); let mut a = 0.0; let mut lmin = 1e9;
    for i in 0..n {
        let dz = p[i + 1].0 - p[i].0; let dr = p[i + 1].1 - p[i].1; let l = (dz * dz + dr * dr).sqrt();
        e.push((dz / l, dr / l, l, PI * (p[i].1 + p[i + 1].1))); a += e[i].3 * l; lmin = f64::min(lmin, l);
    }
    let mut v = Vec::new(); let rneck = p[n / 2].1; let mut rmax: f64 = 0.0;
    for i in 0..=n {
        let (mut gz, mut gr, mut m) = (0.0, 0.0, 0.0); // gradient of area, share of area
        if i > 0 {
            let q = e[i - 1]; gz += q.3 * q.0; gr += q.3 * q.1 + PI * q.2;
            m += PI * (1.5 * p[i].1 + 0.5 * p[i - 1].1) * q.2 / 2.0; // half-band next to the vertex
        }
        if i < n {
            let q = e[i]; gz -= q.3 * q.0; gr += PI * q.2 - q.3 * q.1;
            m += PI * (1.5 * p[i].1 + 0.5 * p[i + 1].1) * q.2 / 2.0;
        }
        v.push((-gz / m, if i == 0 || i == n { 0.0 } else { -gr / m })); rmax = f64::max(rmax, p[i].1);
    }
    (v, a, 0.1 * f64::min(lmin * lmin, rneck * rneck), X { v0: rneck, v1: rmax, cv: false, k2: 0.0 })
}
fn law(p: &[Pt], c: bool) -> (Vec<Pt>, f64, f64, X) { if c { curve(p) } else { surface(p) } }
fn edges(p: &[Pt], closed: bool) -> Vec<f64> {
    let mut q = p.to_vec(); if closed { q.push(p[0]); }
    q.windows(2).map(|w| ((w[1].0 - w[0].0) * (w[1].0 - w[0].0) + (w[1].1 - w[0].1) * (w[1].1 - w[0].1)).sqrt()).collect()
}
fn even(p: &[Pt], closed: bool) -> Vec<Pt> {   // re-space the vertices evenly along the shape
    let mut q = p.to_vec(); if closed { q.push(p[0]); }
    let mut s = vec![0.0]; for l in edges(p, closed) { let last = s[s.len() - 1]; s.push(last + l); }
    let n = if closed { p.len() } else { p.len() - 1 }; let mut out = Vec::new(); let mut j = 0;
    for k in 0..p.len() {
        let g = s[s.len() - 1] * k as f64 / n as f64;
        while j < q.len() - 2 && s[j + 1] < g { j += 1; }
        let w = (g - s[j]) / (s[j + 1] - s[j]);
        out.push((q[j].0 + w * (q[j + 1].0 - q[j].0), q[j].1 + w * (q[j + 1].1 - q[j].1)));
    }
    if !closed { let k = out.len() - 1; out[k] = p[p.len() - 1]; }
    out
}
fn lmin(p: &[Pt], c: bool) -> f64 { edges(p, c).into_iter().fold(f64::INFINITY, f64::min) }
fn lmean(p: &[Pt], c: bool) -> f64 { let e = edges(p, c); let mut s = 0.0; for l in &e { s += l; } s / e.len() as f64 }
type Seen = Vec<(f64, f64, X)>;
fn flow(mut p: Vec<Pt>, c: bool, marks: &[f64], stop: &mut dyn FnMut(f64, f64, &X, f64) -> bool)
        -> (Seen, f64, f64, f64, f64, X, X) {          // explicit steps; readings at marks, stop time
    let mut t = 0.0; let mut steps = 0; let (mut v, mut a, mut dt, mut x) = law(&p, c); let a0 = a;
    let mut seen: Seen = Vec::new(); let mut mk: Vec<f64> = marks.to_vec();
    loop {
        if !mk.is_empty() && t >= mk[0] - 1e-12 { seen.push((mk.remove(0), a, x)); }
        let h = if !mk.is_empty() { f64::min(dt, mk[0] - t) } else { dt };
        let mut q: Vec<Pt> = p.iter().zip(v.iter()).map(|(pp, vv)| (pp.0 + h * vv.0, pp.1 + h * vv.1)).collect();
        steps += 1;
        if steps % 10 == 0 && lmin(&q, c) < 0.6 * lmean(&q, c) { q = even(&q, c); }
        let (v2, a2, dt2, x2) = law(&q, c);
        if stop(a0, a2, &x2, t + h) { return (seen, t, h, a, a2, x, x2); }
        p = q; v = v2; a = a2; dt = dt2; x = x2; t += h;
    }
}
fn at_one_percent(p: Vec<Pt>, c: bool, marks: &[f64]) -> (f64, Seen, Vec<f64>) {
    let mut cv: Vec<f64> = Vec::new(); let target = 0.01 * law(&p, c).1;
    let (seen, t, h, a, a2, _, _) = flow(p, c, marks, &mut |a0, a2, x, t| {
        if c && x.cv && cv.is_empty() { cv.push(t); return false; }
        a2 < 0.01 * a0 });
    (t + h * (a - target) / (a - a2), seen, cv)
}
fn ring(n: usize) -> Vec<Pt> { (0..n).map(|k| (10.0 * (2.0 * PI * k as f64 / n as f64).cos(), 10.0 * (2.0 * PI * k as f64 / n as f64).sin())).collect() }
fn ball(n: usize) -> Vec<Pt> { (0..=n).map(|k| (10.0 * (PI * k as f64 / n as f64).cos(), 10.0 * (PI * k as f64 / n as f64).sin())).collect() }
fn peanut(n: usize) -> Vec<Pt> {
    (0..n).map(|k| { let a = 2.0 * PI * k as f64 / n as f64; let r = 10.0 * (1.0 + 0.5 * (2.0 * a).cos()); (r * a.cos(), r * a.sin()) }).collect()
}
fn smooth(n: usize) -> (f64, f64) {             // the smooth peanut by Simpson's rule in the polar angle: L, int kappa^2 ds
    let (mut l, mut k2) = (0.0, 0.0);
    for k in 0..=n {
        let a = 2.0 * PI * k as f64 / n as f64; let (r, r1, r2) = (10.0 + 5.0 * (2.0 * a).cos(), -10.0 * (2.0 * a).sin(), -20.0 * (2.0 * a).cos());
        let w = (if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * 2.0 * PI / (3.0 * n as f64); let v = (r * r + r1 * r1).sqrt();
        let q = r * r + 2.0 * r1 * r1 - r * r2; l += w * v; k2 += w * q * q / (v * v * v * v * v);
    }
    (l, k2)
}
fn dumbbell(h: f64) -> Vec<Pt> {               // two 10 cm bulbs, centres 24 cm apart, a 3 cm neck
    let tj = PI - 0.3f64.asin(); let m = (10.0 * tj / h).round() as usize; let zj = 12.0 - 10.0 * 0.3f64.asin().cos();
    let q = 2 * (zj / h).round() as usize;
    let right: Vec<Pt> = (0..=m).map(|k| (12.0 + 10.0 * (tj * k as f64 / m as f64).cos(), 10.0 * (tj * k as f64 / m as f64).sin())).collect();
    let mut out = right.clone();
    for k in 1..q { out.push((zj - 2.0 * zj * k as f64 / q as f64, 3.0)); }
    for &(z, r) in right.iter().rev() { out.push((-z, r)); }
    out
}
fn join(v: &[String]) -> String { v.join(", ") }
fn main() {
    println!("closed forms, radius 10 cm: sphere r^2 = 100 - 4t, circle r^2 = 100 - 2t");
    println!("chart sphere {}", join(&(0..11).map(|i| format!("{:.2}", f64::max(0.0, 100.0 - 4.0 * (5 * i) as f64).sqrt())).collect::<Vec<_>>()));
    println!("chart circle {}", join(&(0..11).map(|i| format!("{:.2}", (100.0 - 2.0 * (5 * i) as f64).sqrt())).collect::<Vec<_>>()));
    println!("sphere area {} cm^2, rate -16 pi = {} -> gone at {}", f(400.0 * PI), f(-16.0 * PI), f(400.0 * PI / (16.0 * PI)));
    println!("circle area {} cm^2, rate -2 pi = {} -> gone at {}", f(100.0 * PI), f(-2.0 * PI), f(100.0 * PI / (2.0 * PI)));
    println!("closed form at t=16: sphere {} circle {}", f((100.0f64 - 64.0).sqrt()), f((100.0f64 - 32.0).sqrt()));
    println!("circle length rate -2pi/r at r=10: {}  sphere speed 2/r: {}", f(-2.0 * PI / 10.0), f(0.2));
    for (name, c, n1, exact) in [("sphere", false, 40usize, 24.75), ("circle", true, 64, 49.5)] {
        let mut res = Vec::new();
        for n in [n1, 2 * n1] {
            let (t1, seen, _) = at_one_percent(if c { ring(n) } else { ball(n) }, c, &[16.0]);
            let r16 = if c { (seen[0].1 / PI).sqrt() } else { seen[0].2.v1 };
            res.push(t1);
            println!("{} N={}: 1% of size left at t = {} (exact {}); radius at t=16: {}", name, n, f(t1), f(exact), f(r16));
        }
        assert!((res[1] - exact).abs() < (res[0] - exact).abs() + 1e-9 && (res[1] - exact).abs() < 0.05);
    }
    let a_exact = 112.5 * PI;
    println!("peanut area {} exact, {} polygon; gone at A/2pi = {}", f(a_exact), f(curve(&peanut(200)).1), f(a_exact / (2.0 * PI)));
    let (ls, k2s) = smooth(2000); let mut gap = Vec::new(); let mut l = 0.0;
    for n in [100usize, 200] {
        let (_, _, _, x0) = curve(&peanut(n)); let k2 = x0.k2; l = x0.v0; gap.push((k2 - k2s).abs());
        println!("peanut N={} start: length {}; length lost per unit time: speed kappa {}, even speed of equal size {}", n, f(l), f(k2), f(2.0 * PI * (k2 / l).sqrt()));
        assert!(k2 > 2.0 * PI * (k2 / l).sqrt() * 1.05 && !x0.cv);
    }
    println!("smooth peanut start: length {}; length lost per unit time: speed kappa {}, even speed of equal size {}", f(ls), f(k2s), f(2.0 * PI * (k2s / ls).sqrt()));
    assert!(gap[1] < gap[0] && gap[0] < 0.1 && (l - ls).abs() < 0.05);
    for n in [100usize, 200] {
        let marks = [0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 55.0];
        let (t1, seen, cv) = at_one_percent(peanut(n), true, &marks);
        let ratio: Vec<f64> = seen.iter().map(|s| s.2.v0 * s.2.v0 / (4.0 * PI * s.1)).collect();
        let law20 = curve(&peanut(n)).1 - 40.0 * PI;
        println!("peanut N={}: area at t=20 {} (law {}), 1% at t = {} (law {})", n, f(seen[2].1), f(law20), f(t1), f(0.99 * a_exact / (2.0 * PI)));
        println!("  chart L^2/(4 pi A): {} ; convex from t = {}", join(&ratio.iter().map(|r| format!("{:.3}", r)).collect::<Vec<_>>()), f(cv[0]));
        assert!((seen[2].1 - law20).abs() < 0.5 && (t1 - 0.99 * a_exact / (2.0 * PI)).abs() < 0.3);
        assert!(ratio[0] > 1.3 && ratio[6] < 1.01 && !seen[0].2.cv && 0.0 < cv[0] && cv[0] < 50.0);
    }
    let mut tp = Vec::new();
    for h in [0.5, 0.25] {
        let (seen, t, hh, _, _, x, x2) = flow(dumbbell(h), false, &[0.0, 1.0, 2.0, 3.0, 4.0], &mut |_, _, x, _| x.v0 < 0.3);
        let p = t + hh * (x.v0 - 0.3) / (x.v0 - x2.v0); tp.push(p);
        println!("dumbbell h={}: neck/bulb radius at t=0..4: {}", h, seen.iter().map(|s| format!("{}/{}", f(s.2.v0), f(s.2.v1))).collect::<Vec<_>>().join("; "));
        println!("  neck 0.3 cm at t = {}; bulbs then {} cm, a lone sphere {}", f(p), f(x2.v1), f((100.0 - 4.0 * p).sqrt()));
        assert!(4.5 < p && p < 25.0 && (x2.v1 - (100.0 - 4.0 * p).sqrt()).abs() < 0.1);
    }
    assert!((tp[0] - tp[1]).abs() < 0.1);
    println!("lone sphere r=10 at t=0..4: {}", join(&[0.0, 1.0, 2.0, 3.0, 4.0].iter().map(|t: &f64| f((100.0 - 4.0 * t).sqrt())).collect::<Vec<_>>()));
    println!("lone cylinder r=3 at t=0..4: {} ; gone at {}", join(&[0.0, 1.0, 2.0, 3.0, 4.0].iter().map(|t: &f64| f((9.0 - 2.0 * t).sqrt())).collect::<Vec<_>>()), f(4.5));
    println!("wrong: speed H = average, sphere gone at {} not 25", f(100.0 / 2.0));
    println!("wrong: surface speed 2/r on a circle, gone at {} not 50", f(100.0 / 4.0));
    println!("Ricci flow, sphere radius 10: R^2 = 100 - 2t, gone at {} ; circle and cylinder: Ric = 0, never move; this flow: cylinder r=10 gone at {}", f(100.0 / 2.0), f(100.0 / 2.0));
    println!("try: sphere radius 5 gone at {} ; 3-sphere radius 10 gone at {} ; circle area 300 gone at {}", f(25.0 / 4.0), f(100.0 / 6.0), f(300.0 / (2.0 * PI)));
    println!("ALL CHECKS PASS");
}
