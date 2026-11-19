// Minimal surfaces and soap films -- the check behind the card.  std only, no crates.
// A soap film spans two coaxial wire rings of radius 5 cm, 4 cm apart.  Mean curvature H
// comes from finite differences of any chart, not the catenoid's closed form; area by
// Simpson's rule; the first variation by pushing the film; a polygon profile minimised.
use std::f64::consts::PI;
type V = [f64; 3];
const RING: f64 = 5.0; // ring radius (cm)
const HALF: f64 = 2.0; // rings at z = -2 and z = +2 (cm)

fn f6(v: f64) -> String { format!("{:.6}", if v.abs() < 5e-7 { 0.0 } else { v }) }
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let flo = f(lo);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if (f(mid) < 0.0) == (flo < 0.0) { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn asinh(x: f64) -> f64 { (x + (x * x + 1.0).sqrt()).ln() }
fn add(a: V, b: V, k: f64) -> V { [a[0] + k * b[0], a[1] + k * b[1], a[2] + k * b[2]] }
fn sc(a: V, k: f64) -> V { [a[0] * k, a[1] * k, a[2] * k] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
type Chart<'a> = &'a dyn Fn(f64, f64) -> V;
fn shape(r: Chart, u: f64, v: f64) -> [f64; 7] { // E, F, G, H, K, k1, k2 from the chart alone
    let (d, p) = (1e-4, r(u, v));
    let ru = sc(add(r(u + d, v), r(u - d, v), -1.0), 1.0 / (2.0 * d));
    let rv = sc(add(r(u, v + d), r(u, v - d), -1.0), 1.0 / (2.0 * d));
    let ruu = sc(add(add(r(u + d, v), r(u - d, v), 1.0), p, -2.0), 1.0 / (d * d));
    let rvv = sc(add(add(r(u, v + d), r(u, v - d), 1.0), p, -2.0), 1.0 / (d * d));
    let ruv = sc(add(add(r(u + d, v + d), r(u - d, v - d), 1.0), add(r(u + d, v - d), r(u - d, v + d), 1.0), -1.0), 1.0 / (4.0 * d * d));
    let c = cross(ru, rv); let n = sc(c, 1.0 / dot(c, c).sqrt());
    let (e, f, g, l, m, nn) = (dot(ru, ru), dot(ru, rv), dot(rv, rv), dot(ruu, n), dot(ruv, n), dot(rvv, n));
    let w = e * g - f * f;
    let (h, k) = ((e * nn - 2.0 * f * m + g * l) / (2.0 * w), (l * nn - m * m) / w);
    let s = (h * h - k).max(0.0).sqrt();
    [e, f, g, h, k, h + s, h - s]
}
fn wt(i: usize, n: usize) -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }
fn area(r: Chart, u0: f64, u1: f64, v0: f64, v1: f64, n: usize) -> f64 { // Simpson's rule on sqrt(EG - F^2)
    let (hu, hv, d) = ((u1 - u0) / n as f64, (v1 - v0) / n as f64, 1e-5);
    let mut tot = 0.0;
    for i in 0..=n {
        for j in 0..=n {
            let (u, v) = (u0 + i as f64 * hu, v0 + j as f64 * hv);
            let c = cross(add(r(u + d, v), r(u - d, v), -1.0), add(r(u, v + d), r(u, v - d), -1.0));
            tot += wt(i, n) * wt(j, n) * dot(c, c).sqrt() / ((2.0 * d) * (2.0 * d));
        }
    }
    tot * hu * hv / 9.0
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, h) = (400, (b - a) / 400.0);
    h / 3.0 * (0..=n).map(|i| wt(i, n) * f(a + i as f64 * h)).sum::<f64>()
}
fn cat_area(a: f64, h: f64) -> f64 { PI * a * (2.0 * h + a * (2.0 * h / a).sinh()) }
fn waists(h: f64, t: f64) -> (f64, f64) { // the two catenoids a cosh(h/a) = R: fat, thin
    let f = |a: f64| a * (h / a).cosh() - RING;
    (bisect(&f, h / t, RING), bisect(&f, h / 30.0, h / t))
}
// area after moving each point eps*phi along n (toward the axis)
fn pushed(rho: &dyn Fn(f64) -> f64, drho: &dyn Fn(f64) -> f64, phi: &dyn Fn(f64) -> f64, eps: f64) -> f64 {
    let pt = |z: f64| { let w = (1.0 + drho(z).powi(2)).sqrt(); (rho(z) - eps * phi(z) / w, z + eps * phi(z) * drho(z) / w) };
    let band = |z: f64| { let ((r0, z0), (r1, z1)) = (pt(z - 1e-4), pt(z + 1e-4)); 2.0 * PI * pt(z).0 * (r1 - r0).hypot(z1 - z0) / 2e-4 };
    simpson(&band, -HALF, HALF)
}
fn polygon(n: usize, steps: usize) -> (f64, f64) { // least-area polygon profile, ends pinned on the rings
    let (dz, mut rho) = (2.0 * HALF / n as f64, vec![RING; n + 1]);
    for _ in 0..steps {
        let mut g = vec![0.0; n + 1];
        for i in 0..n {
            let l = dz.hypot(rho[i + 1] - rho[i]);
            let q = (rho[i] + rho[i + 1]) * (rho[i + 1] - rho[i]) / l;
            g[i] += PI * (l - q); g[i + 1] += PI * (l + q);
        }
        for i in 1..n { rho[i] -= 0.9 * dz / (4.0 * PI * RING) * g[i]; }
    }
    (rho[n / 2], (0..n).map(|i| PI * (rho[i] + rho[i + 1]) * dz.hypot(rho[i + 1] - rho[i])).sum())
}
fn least_radius(h: f64) -> f64 { // min over a of a cosh(h/a), by golden-section search
    let (mut lo, mut hi) = (h / 5.0, 5.0 * h);
    for _ in 0..200 {
        let (m1, m2) = (lo + 0.382 * (hi - lo), hi - 0.382 * (hi - lo));
        if m1 * (h / m1).cosh() < m2 * (h / m2).cosh() { hi = m2 } else { lo = m1 }
    }
    lo * (h / lo).cosh()
}
fn main() {
    let t = bisect(&|t: f64| t * t.tanh() - 1.0, 0.5, 2.0); // where a cosh(h/a) is least
    let (a, thin) = waists(HALF, t);
    println!("rings: radius {} cm, separation {} cm", f6(RING), f6(2.0 * HALF));
    println!("catenoid waists a: fat {} thin {} cm", f6(a), f6(thin));
    let cat1 = move |z: f64, th: f64| -> V { [a * (z / a).cosh() * th.cos(), a * (z / a).cosh() * th.sin(), z] };
    let cat2 = move |s: f64, th: f64| -> V { [(a * a + s * s).sqrt() * th.cos(), (a * a + s * s).sqrt() * th.sin(), a * asinh(s / a)] };
    let s_ring = a * (HALF / a).sinh(); // arc length from waist to ring along the profile
    let cases: [(&str, Chart, f64, f64); 4] = [
        ("chart 1 (z, theta) at ring ", &cat1, HALF, RING), ("chart 2 (s, theta) at ring ", &cat2, s_ring, RING),
        ("chart 1 (z, theta) at waist", &cat1, 0.0, a), ("chart 2 (s, theta) at waist", &cat2, 0.0, a)];
    for (name, r, u, rho) in cases {
        let [e, _f, g, h, k, k1, k2] = shape(r, u, 0.7);
        println!("{} E {} G {} k1 {} k2 {} H {} K {}", name, f6(e), f6(g), f6(k1), f6(k2), f6(h), f6(k));
        assert!((k1 - a / (rho * rho)).abs() < 1e-5 && h.abs() < 1e-5); // closed form k1 = a / rho^2 = -k2
    }
    println!("closed form a/rho^2: ring {} waist {}", f6(a / (RING * RING)), f6(1.0 / a));
    let (a1, a2, ac) = (area(&cat1, -HALF, HALF, 0.0, 2.0 * PI, 60), area(&cat2, -s_ring, s_ring, 0.0, 2.0 * PI, 60), cat_area(a, HALF));
    println!("film area: chart 1 {} chart 2 {} closed form {}", f6(a1), f6(a2), f6(ac));
    assert!((a1 - ac).abs() < 1e-4 && (a2 - ac).abs() < 1e-4);
    println!("hand: h/a {} cosh(h/a) {} a cosh(h/a) {} sinh(2h/a) {}", f6(HALF / a), f6((HALF / a).cosh()), f6(a * (HALF / a).cosh()), f6((2.0 * HALF / a).sinh()));
    println!("      s at ring {} cylinder minus film {} cylinder int phi dA {}", f6(s_ring), f6(2.0 * PI * RING * 2.0 * HALF - ac), f6(2.0 * PI * RING * HALF));
    println!("rivals: cylinder {} two discs {} thin catenoid {}", f6(2.0 * PI * RING * 2.0 * HALF), f6(2.0 * PI * RING * RING), f6(cat_area(thin, HALF)));
    let bump = |z: f64| (PI * z / (2.0 * HALF)).cos().powi(2); // 1 at the waist, 0 at both rings
    let (cat_rho, cat_d) = (move |z: f64| a * (z / a).cosh(), move |z: f64| (z / a).sinh());
    let (cyl_rho, cyl_d) = (|_z: f64| RING, |_z: f64| 0.0);
    let profiles: [(&str, &dyn Fn(f64) -> f64, &dyn Fn(f64) -> f64, f64); 2] =
        [("catenoid", &cat_rho, &cat_d, 0.0), ("cylinder", &cyl_rho, &cyl_d, 1.0 / (2.0 * RING))];
    for (name, rho, drho, hc) in profiles {
        let e = 1e-4;
        let slope = (pushed(rho, drho, &bump, e) - pushed(rho, drho, &bump, -e)) / (2.0 * e);
        let pred = -2.0 * simpson(&|z: f64| hc * bump(z) * 2.0 * PI * rho(z) * (1.0 + drho(z).powi(2)).sqrt(), -HALF, HALF);
        println!("first variation, {} dA/d(eps) {} predicted -2 int H phi dA {} H {}", name, f6(slope), f6(pred), f6(hc));
        assert!((slope - pred).abs() < 1e-5);
    }
    for (name, w) in [("fat", a), ("thin", thin)] {
        let (rho, drho) = (move |z: f64| w * (z / w).cosh(), move |z: f64| (z / w).sinh());
        let base = pushed(&rho, &drho, &bump, 0.0);
        let d = [pushed(&rho, &drho, &bump, 0.05) - base, pushed(&rho, &drho, &bump, -0.05) - base];
        println!("second variation, {} catenoid: change at eps +0.05 {} at -0.05 {}", name, f6(d[0]), f6(d[1]));
        assert!((d[0].min(d[1]) > 0.0) == (name == "fat"));
    }
    for n in [10, 20] {
        let (wst, ar) = polygon(n, 8000);
        println!("polygon, {} bands: waist {} error {} area {}", n, f6(wst), f6(wst - a), f6(ar));
    }
    let (e10, e20) = (polygon(10, 8000).0 - a, polygon(20, 8000).0 - a);
    println!("polygon waist error ratio {}", f6(e10 / e20));
    assert!(3.5 < e10 / e20 && e10 / e20 < 4.5);
    let gmax = 2.0 * t / t.cosh(); // widest gap a catenoid spans, in ring radii
    let gscan = 2.0 * bisect(&|h: f64| least_radius(h) - RING, 1.0, 5.0) / RING;
    println!("widest gap / radius: t tanh t = 1 gives {} t {} ; search gives {} ; gap {} cm", f6(gmax), f6(t), f6(gscan), f6(gmax * RING));
    assert!((gmax - gscan).abs() < 1e-6);
    println!("rings 7 cm apart: thinnest catenoid end radius {} > 5, so no film of that shape", f6(least_radius(3.5)));
    let gdisc = 2.0 * bisect(&|h: f64| cat_area(waists(h, t).0, h) - 2.0 * PI * RING * RING, 1.0, 3.3);
    println!("discs beat the catenoid beyond separation {} cm = {} radii", f6(gdisc), f6(gdisc / RING));
    for gap in [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 6.6] {
        let (fa, ta) = waists(gap / 2.0, t);
        println!("separation {} fat a {} area {} thin a {} area {}", f6(gap), f6(fa), f6(cat_area(fa, gap / 2.0)), f6(ta), f6(cat_area(ta, gap / 2.0)));
    }
    let c = 1.0 / 25.0; // wing 19's saddle z = (x^2 - y^2)/25 cm on a 5 cm loop
    let sad = move |x: f64, y: f64| -> V { [x, y, c * (x * x - y * y)] };
    for (x, y) in [(0.0, 0.0), (5.0, 0.0), (3.0, 4.0)] {
        let (fx, fy, fxx, fyy) = (2.0 * c * x, -2.0 * c * y, 2.0 * c, -2.0 * c);
        let hf = ((1.0 + fx * fx) * fyy + (1.0 + fy * fy) * fxx) / (2.0 * (1.0 + fx * fx + fy * fy).powf(1.5));
        let [_e, _f, _g, h, _k, k1, k2] = shape(&sad, x, y);
        println!("Laplace saddle at {} {} H {} formula {} k1 {} k2 {} Laplace fxx+fyy {}", f6(x), f6(y), f6(h), f6(hf), f6(k1), f6(k2), f6(fxx + fyy));
        assert!((h - hf).abs() < 1e-6);
    }
    let [_e, _f, _g, h, k, _k1, _k2] = shape(&|u: f64, v: f64| [v * u.cos(), v * u.sin(), u], 0.7, 2.0);
    println!("helicoid, rise 1 cm per radian, 2 cm out: H {} K {} closed form K {}", f6(h), f6(k), f6(-1.0 / 25.0));
    assert!(h.abs() < 1e-6 && (k + 1.0 / 25.0).abs() < 1e-6);
    let cyl = |z: f64, th: f64| -> V { [RING * th.cos(), RING * th.sin(), z] }; // n toward the axis; swap the grid and n points away
    let (h_in, h_out) = (shape(&cyl, 0.5, 0.7)[3], shape(&|th: f64, z: f64| cyl(z, th), 0.7, 0.5)[3]);
    println!("cylinder by finite differences: H {} with n toward the axis, {} with n away from it", f6(h_in), f6(h_out));
    assert!((h_in - 1.0 / (2.0 * RING)).abs() < 1e-6 && (h_out + 1.0 / (2.0 * RING)).abs() < 1e-6);
    println!("cylinder film, 0.025 N/m per face, H = 10 1/m: pressure 4 gamma H {} Pa", f6(4.0 * 0.025 * 10.0));
    let zs: Vec<f64> = (0..17).map(|k| k as f64 / 4.0 - 2.0).collect();
    for (label, w) in [("z", a), ("thin", thin)] {
        let pts: Vec<String> = zs.iter().map(|&z: &f64| format!("{:.1},{:.1}", 210.0 + 30.0 * z, 190.0 - 30.0 * w * (z / w).cosh())).collect();
        println!("figure, {} {}", label, pts.join(" "));
    }
    println!("ALL CHECKS PASS");
}
