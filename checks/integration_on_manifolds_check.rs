// Integration on an oriented manifold -- the check behind the card.
// std only, no crates.  A bowl-shaped valley (part of a sphere, radius 5 km,
// rim radius 3 km, 1 km deep) catches a storm whose rain rate grows with height.
// The rain is the 2-form p dx^dy.  It is integrated three ways: closed form,
// two overlapping charts glued by a partition of unity, and a triangle mesh.
use std::f64::consts::PI;
type V3 = [f64; 3];

const R: f64 = 5.0; // sphere radius, km
const A: f64 = 3.0; // rim radius on the plan, km
const P0: f64 = 10.0; // rain rate on the floor, mm/h
const H0: f64 = 1.0; // km of height per extra P0
const LO: f64 = 1.0; // chart V starts at this plan radius, km
const HI: f64 = 2.0; // chart U stops at this plan radius, km

fn height(rho: f64) -> f64 { R - (R * R - rho * rho).sqrt() } // km above the valley floor
fn rain(rho: f64) -> f64 { P0 * (1.0 + height(rho) / H0) } // mm/h, measured on level ground
fn f(t: f64) -> f64 { if t > 0.0 { (-1.0 / t).exp() } else { 0.0 } }
fn psi(rho: f64, lo: f64, hi: f64) -> f64 { f(hi - rho) / (f(hi - rho) + f(rho - lo)) } // 1 inside lo, 0 outside hi
fn psi_u(rho: f64) -> f64 { psi(rho, LO, HI) }
fn psi_v(rho: f64) -> f64 { 1.0 - psi_u(rho) }
fn det2(a: f64, b: f64, c: f64, d: f64) -> f64 { a * d - b * c }

fn simpson2<G: Fn(f64, f64) -> f64>(g: G, a: f64, b: f64, c: f64, d: f64, n: usize) -> f64 {
    // Simpson's rule on an n-by-n grid, n even
    let (hu, hv) = ((b - a) / n as f64, (d - c) / n as f64);
    let w = |i: usize| -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } };
    let mut s = 0.0;
    for i in 0..=n {
        for j in 0..=n {
            s += w(i) * w(j) * g(a + i as f64 * hu, c + j as f64 * hv);
        }
    }
    s * hu * hv / 9.0
}

fn chart_v(ph: f64, th: f64) -> (f64, f64) {
    // slope chart: polar angle ph from the floor, longitude th
    let (x, y) = (R * ph.sin() * th.cos(), R * ph.sin() * th.sin());
    let (xp, xt) = (R * ph.cos() * th.cos(), -R * ph.sin() * th.sin());
    let (yp, yt) = (R * ph.cos() * th.sin(), R * ph.sin() * th.cos());
    (x.hypot(y), det2(xp, xt, yp, yt)) // plan radius, coefficient of dph^dth
}
fn u_part<W: Fn(f64) -> f64>(x: f64, y: f64, weight: &W) -> f64 {
    // floor chart: plan x, y; dx^dy pulls back to itself
    let rho = x.hypot(y);
    if rho < HI { weight(rho) * rain(rho) } else { 0.0 }
}
fn v_part<W: Fn(f64) -> f64>(ph: f64, th: f64, weight: &W, order: f64) -> f64 {
    // order -1: the chart read as (th, ph)
    let (rho, j) = chart_v(ph, th);
    weight(rho) * rain(rho) * j * order
}

fn mesh(n: usize) -> f64 {
    // flat triangles on the bowl, vertices in anticlockwise order
    let m = 4 * n;
    let pt = |i: usize, j: usize| -> V3 {
        let (r, t) = (A * i as f64 / n as f64, 2.0 * PI * j as f64 / m as f64);
        [r * t.cos(), r * t.sin(), height(r)]
    };
    let mut tot = 0.0;
    for i in 0..n {
        for j in 0..m {
            let (p, q, r, s) = (pt(i, j), pt(i + 1, j), pt(i + 1, j + 1), pt(i, j + 1));
            for (a, b, c) in [(p, q, r), (p, r, s)] {
                let proj = det2(b[0] - a[0], c[0] - a[0], b[1] - a[1], c[1] - a[1]) / 2.0; // signed dx^dy
                tot += proj * P0 * (1.0 + (a[2] + b[2] + c[2]) / 3.0 / H0);
            }
        }
    }
    tot
}

fn c3(r: f64, t: f64) -> [f64; 9] { [t.cos(), -r * t.sin(), 0.0, t.sin(), r * t.cos(), 0.0, 0.0, 0.0, 1.0] } // d(x,y,z)/d(rho,theta,z)
fn det3(m: [f64; 9]) -> f64 { m[0] * (m[4] * m[8] - m[5] * m[7]) - m[1] * (m[3] * m[8] - m[5] * m[6]) + m[2] * (m[3] * m[7] - m[4] * m[6]) }
fn swap(m: [f64; 9]) -> [f64; 9] { [m[0], m[2], m[1], m[3], m[5], m[4], m[6], m[8], m[7]] } // columns reordered to (rho, z, theta)

fn mob(s: f64, t: f64) -> V3 {
    // Mobius strip of mid-radius 1 km, width 1 km
    let w = 1.0 + t / 2.0 * (s / 2.0).cos();
    [w * s.cos(), w * s.sin(), t / 2.0 * (s / 2.0).sin()]
}
fn normal(s: f64, t: f64) -> V3 {
    let e = 1e-6;
    let a: Vec<f64> = (0..3).map(|k| (mob(s + e, t)[k] - mob(s - e, t)[k]) / (2.0 * e)).collect();
    let b: Vec<f64> = (0..3).map(|k| (mob(s, t + e)[k] - mob(s, t - e)[k]) / (2.0 * e)).collect();
    [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]]
}
fn sign(u: V3, v: V3) -> i32 { if u[0] * v[0] + u[1] * v[1] + u[2] * v[2] > 0.0 { 1 } else { -1 } }

fn main() {
    let (phi0, phi1) = ((A / R).asin(), (LO / R).asin()); // polar angle at the rim and at plan radius LO
    let one = |_: f64| 1.0;
    let plan = PI * A * A;
    let zint = PI * A * A * R - 2.0 * PI / 3.0 * (R.powi(3) - (R * R - A * A).powf(1.5));
    let closed = P0 * (plan + zint / H0);
    println!("rim polar angle rad {:.6} deg {:.6} rim height km {:.6} rim gauge mm/h {:.6}", phi0, phi0.to_degrees(), height(A), rain(A));
    println!("plan area km^2 {:.6} integral of z dA km^3 {:.6}", plan, zint);
    println!("closed form, mm/h x km^2 {:.6} m^3/h {:.6} 6 h storm m^3 {:.6}", closed, closed * 1000.0, closed * 6000.0);
    let rho = 1.5;
    let ph = (rho / R).asin();
    println!("at plan radius 1.5 km: sin phi {:.6} cos phi {:.6} z {:.6} p mm/h {:.6} psi_U {:.6} psi_V {:.6}", ph.sin(), ph.cos(), height(rho), rain(rho), psi_u(rho), psi_v(rho));
    let jv = chart_v(ph, 0.7).1;
    println!("  coefficient in chart U {:.6} in chart V {:.6} Jacobian {:.6} R^2 sin cos {:.6}", rain(rho), rain(rho) * jv, jv, R * R * ph.sin() * ph.cos());
    assert!((jv - R * R * ph.sin() * ph.cos()).abs() < 1e-12);
    let iu = simpson2(|x, y| u_part(x, y, &psi_u), -HI, HI, -HI, HI, 400);
    let iv = simpson2(|p, t| v_part(p, t, &psi_v, 1.0), phi1, phi0, 0.0, 2.0 * PI, 200);
    println!("chart U piece {:.6} chart V piece {:.6} sum {:.6} closed {:.6}", iu, iv, iu + iv, closed);
    assert!((iu + iv - closed).abs() < 1e-4);
    let whole_v = simpson2(|p, t| v_part(p, t, &one, 1.0), 0.0, phi0, 0.0, 2.0 * PI, 200);
    println!("chart V alone over the whole bowl (floor point is one point) {:.6}", whole_v);
    assert!((whole_v - closed).abs() < 1e-6);
    let dmin = (0..11).map(|k| chart_v(phi1 + k as f64 * ((HI / R).asin() - phi1) / 10.0, 0.3 * k as f64).1).fold(f64::INFINITY, f64::min);
    println!("overlap: smallest dph^dth coefficient {:.6} all positive {}", dmin, if dmin > 0.0 { "yes" } else { "no" });

    let (m1, m2) = (mesh(30), mesh(60));
    println!("mesh 30 rings {:.6} error {:.6}", m1, m1 - closed);
    println!("mesh 60 rings {:.6} error {:.6} ratio {:.6}", m2, m2 - closed, (m1 - closed) / (m2 - closed));
    assert!((m2 - closed).abs() < (m1 - closed).abs() / 3.5);

    println!("rim at (3, 0): outward d/dphi, along d/dtheta, dx^dy coefficient {:.6} rim length km {:.6}", chart_v(phi0, 0.0).1, 2.0 * PI * A);
    let lake = simpson2(|r, t| det3(c3(r, t)) * (height(A) - height(r)), 0.0, A, 0.0, 2.0 * PI, 200);
    let lake2 = simpson2(|r, t| det3(swap(c3(r, t))) * (height(A) - height(r)), 0.0, A, 0.0, 2.0 * PI, 200);
    println!("3-form dx^dy^dz, lake to the rim, km^3: order (rho, theta, z) {:.6} order (rho, z, theta) {:.6} closed 14 pi/3 {:.6}", lake, lake2, 14.0 * PI / 3.0);
    assert!((lake - 14.0 * PI / 3.0).abs() < 1e-6 && (lake2 + 14.0 * PI / 3.0).abs() < 1e-6);

    let flip = iu + simpson2(|p, t| v_part(p, t, &psi_v, -1.0), phi1, phi0, 0.0, 2.0 * PI, 200);
    let iu_all = simpson2(|r, _t| rain(r) * r, 0.0, HI, 0.0, 2.0 * PI, 200); // chart U at full weight, in plan polar form
    let iv_all = simpson2(|p, t| v_part(p, t, &one, 1.0), phi1, phi0, 0.0, 2.0 * PI, 200);
    let slope = simpson2(|p, _t| rain(R * p.sin()) * R * R * p.sin(), 0.0, phi0, 0.0, 2.0 * PI, 200);
    println!("breaks: chart V read as (theta, phi) {:.6}", flip);
    let ring = |r: f64| P0 * (PI * r * r * (1.0 + R / H0) + 2.0 * PI / (3.0 * H0) * (R * R - r * r).powf(1.5)); // rain on plan disc r
    println!("breaks: no partition of unity {:.6} excess {:.6} ring 1 to 2 km {:.6}", iu_all + iv_all, iu_all + iv_all - closed, ring(HI) - ring(LO));
    println!("breaks: slope area dS for dx^dy {:.6} closed 150 pi {:.6} ratio {:.6}", slope, 150.0 * PI, slope / closed);
    assert!(flip < closed / 2.0 && (slope - 150.0 * PI).abs() < 1e-6 && (iu_all + iv_all - closed - ring(HI) + ring(LO)).abs() < 1e-6);

    let same = (0..3).map(|k| (mob(4.0, 0.3)[k] - mob(4.0 - 2.0 * PI, -0.3)[k]).abs()).fold(0.0, f64::max);
    println!("mobius: chart B point (s - 2 pi, -t) is chart A point (s, t), gap {:.6}", same);
    let piece2 = sign(normal(4.0, 0.3), normal(4.0 - 2.0 * PI, -0.3));
    println!("mobius: orientation agreement on overlap piece 1 (same numbers in both charts) {} piece 2 {}", sign(normal(1.0, 0.3), normal(1.0, 0.3)), piece2);
    assert!(same < 1e-12 && piece2 == -1);

    let row = |g: &dyn Fn(f64) -> f64| (0..16).map(|k| format!("{:.3}", g(k as f64 / 5.0))).collect::<Vec<_>>().join(" ");
    println!("chart psi_U {}", row(&psi_u));
    println!("chart psi_V {}", row(&psi_v));
    let nu = |r: f64| psi(r, 1.25, 1.75);
    let nv = |r: f64| 1.0 - psi(r, 1.25, 1.75);
    let narrow = simpson2(|x, y| u_part(x, y, &nu), -HI, HI, -HI, HI, 400) + simpson2(|p, t| v_part(p, t, &nv, 1.0), phi1, phi0, 0.0, 2.0 * PI, 200);
    println!("try: H0 = 0.5 km {:.6} try: overlap 1.25 to 1.75 km {:.6}", P0 * (plan + zint / 0.5), narrow);
    println!("try: mesh 6 rings {:.6}", mesh(6));
    let px = 60.0; // figure scale, pixels per km
    println!("figure, {:.0} px per km: chart U radius {:.6} chart V from {:.6} to {:.6} rim height {:.6} radii px {:.1} {:.1} {:.1} section depth px {:.1}",
             px, HI, LO, A, height(A), px * LO, px * HI, px * A, px * height(A));
    println!("ALL CHECKS PASS");
}
