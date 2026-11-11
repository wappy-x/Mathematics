// Newton's laws on a thrown cricket ball: the check behind the card. Rust std only.
// The equation of motion m dv/dt = m g + drag is stepped with RK4 written out. The drag work
// rides along as an extra state; the drag impulse is added up apart, by Simpson's rule.
use std::f64::consts::PI;

const G: f64 = 9.80665; const RHO: f64 = 1.225; // standard gravity, m/s^2; air density, kg/m^3
const M: f64 = 0.160; const DIAM: f64 = 0.072; const CD: f64 = 0.40; // mass kg, diameter m, drag coefficient
const V0: f64 = 30.0; const DEG: f64 = 45.0; // the throw: 30 m/s at 45 degrees, from ground level

type S = [f64; 5]; // x, y, vx, vy, drag work W

fn drag(s: &S, k: f64, lin: bool) -> [f64; 2] { // drag deceleration across and up, m/s^2: straight against v
    let f = if lin { k * V0 } else { k * (s[2] * s[2] + s[3] * s[3]).sqrt() }; // per m/s, 1/s
    [-f * s[2], -f * s[3]]
}

fn deriv(s: &S, k: f64, lin: bool) -> S {
    let [ax, ay] = drag(s, k, lin);
    [s[2], s[3], ax, ay - G, M * (ax * s[2] + ay * s[3])]
}

fn add(s: &S, h: f64, d: &S) -> S { let mut r = *s; for i in 0..5 { r[i] += h * d[i]; } r }

fn rk4(s: &S, h: f64, k: f64, lin: bool) -> S {
    let a = deriv(s, k, lin);
    let b = deriv(&add(s, h / 2.0, &a), k, lin);
    let c = deriv(&add(s, h / 2.0, &b), k, lin);
    let d = deriv(&add(s, h, &c), k, lin);
    let mut r = *s;
    for i in 0..5 { r[i] += h / 6.0 * (a[i] + 2.0 * b[i] + 2.0 * c[i] + d[i]); }
    r
}

fn to_zero(mut s: S, mut t: f64, i: usize, k: f64, lin: bool) -> (S, f64) {
    for _ in 0..4 { // Newton steps in time until s[i] is zero
        let hh = -s[i] / deriv(&s, k, lin)[i];
        s = rk4(&s, hh, k, lin); t += hh;
    }
    (s, t)
}

struct Flight { land: S, t: f64, top: S, ttop: f64, path: Vec<S> }

fn fly(v0: f64, deg: f64, k: f64, lin: bool, h: f64, y0: f64) -> Flight {
    let th = deg.to_radians();
    let mut s: S = [0.0, y0, v0 * th.cos(), v0 * th.sin(), 0.0];
    let (mut t, mut top, mut path) = (0.0, None, Vec::new());
    loop {
        path.push(s);
        let n = rk4(&s, h, k, lin);
        if top.is_none() && n[3] <= 0.0 { top = Some(to_zero(s, t, 3, k, lin)); }
        if n[1] < 0.0 {
            let (land, tl) = to_zero(s, t, 1, k, lin);
            let (tp, ttop) = top.unwrap();
            return Flight { land, t: tl, top: tp, ttop, path };
        }
        s = n;
        t += h;
    }
}

// Drag impulse by Simpson's rule: drag at the start, middle and end of each step, weighted
// 1, 4, 1. It never uses the RK4 velocity update, so it is a second road to the momentum change.
fn impulse(f: &Flight, k: f64) -> [f64; 2] {
    let (h, n, mut j) = (1e-3, f.path.len() - 1, [0.0; 2]);
    for i in 0..=n {
        let (p, q) = (&f.path[i], if i < n { &f.path[i + 1] } else { &f.land });
        let dt = if i < n { h } else { f.t - n as f64 * h }; // the last step is cut short at the landing
        let (f0, fm, f1) = (drag(p, k, false), drag(&rk4(p, dt / 2.0, k, false), k, false), drag(q, k, false));
        for c in 0..2 { j[c] += M * dt / 6.0 * (f0[c] + 4.0 * fm[c] + f1[c]); }
    }
    j
}

fn range(v0: f64, deg: f64, k: f64) -> f64 { fly(v0, deg, k, false, 1e-3, 0.0).land[0] }
fn ke(s: &S) -> f64 { 0.5 * M * (s[2] * s[2] + s[3] * s[3]) }
fn speed(s: &S) -> f64 { (s[2] * s[2] + s[3] * s[3]).sqrt() }

fn height_at(path: &[S], land: &S, x: f64) -> f64 { // straight-line read-off between steps; 0 m once landed
    if x >= land[0] { return 0.0; }
    for i in 0..path.len() {
        let (p, q) = (&path[i], if i + 1 < path.len() { &path[i + 1] } else { land });
        if p[0] <= x && x <= q[0] { return p[1] + (q[1] - p[1]) * (x - p[0]) / (q[0] - p[0]); }
    }
    f64::NAN
}

fn line(name: &str, vals: &[f64], unit: &str, d: usize) {
    let v: String = vals.iter().map(|v| format!("{:>11.*}", d, v)).collect();
    println!("{:<38}{} {}", name, v, unit);
}

fn main() {
    let area = PI * DIAM * DIAM / 4.0; // frontal area, m^2
    let k = RHO * CD * area / (2.0 * M); // drag deceleration per (m/s)^2, 1/m
    let th = DEG.to_radians();
    let (r0, t0, h0) = (V0 * V0 * (2.0 * th).sin() / G, 2.0 * V0 * th.sin() / G, (V0 * th.sin()).powi(2) / (2.0 * G));
    let vac = fly(V0, DEG, 0.0, false, 1e-3, 0.0);
    let dr = fly(V0, DEG, k, false, 1e-3, 0.0);
    let dr2 = fly(V0, DEG, k, false, 5e-4, 0.0);
    let up = fly(V0, 90.0, k, false, 1e-3, 0.0);
    let h_up = (1.0 + k * V0 * V0 / G).ln() / (2.0 * k);
    let t_up = (V0 * (k / G).sqrt()).atan() / (G * k).sqrt();
    let (land, top, s0) = (dr.land, dr.top, dr.path[0]);
    let [jx, jy] = impulse(&dr, k);
    let (lob, lob0) = (range(10.0, DEG, k), 100.0 / G);
    let best = (31..=50).fold(30, |b, a| if range(V0, a as f64, k) > range(V0, b as f64, k) { a } else { b });

    line("frontal area A", &[area], "m^2", 6);
    line("drag constant k = rho Cd A / 2m", &[k], "1/m", 6);
    line("weight m g / drag at release m k v0^2", &[M * G, M * k * V0 * V0], "N", 4);
    line("terminal speed sqrt(g/k)", &[(G / k).sqrt()], "m/s", 4);
    line("launch velocity across / up", &[s0[2], s0[3]], "m/s", 4);
    line("Reynolds number v0 D / nu, nu=1.46e-5", &[V0 * DIAM / 1.46e-5], "(pure number)", 0);
    println!("{:<38}{:>11}{:>11}", "", "formula", "RK4");
    line("1 no air: range", &[r0, vac.land[0]], "m", 4);
    line("  no air: flight time", &[t0, vac.t], "s", 4);
    line("  no air: peak height", &[h0, vac.top[1]], "m", 4);
    line("2 straight up, drag: peak height", &[h_up, up.top[1]], "m", 4);
    line("  straight up, drag: time to peak", &[t_up, up.ttop], "s", 4);
    println!("{:<38}{:>11}{:>11}", "3 with drag", "step 1 ms", "step 0.5ms");
    line("  range", &[land[0], dr2.land[0]], "m", 4);
    line("  range lost to the air, vs no air", &[r0 - land[0]], "m", 4);
    line("  landing velocity across / up", &[land[2], land[3]], "m/s", 4);
    line("  flight time / landing speed", &[dr.t, speed(&land)], "s, m/s", 4);
    line("  peak height / time of peak", &[top[1], dr.ttop], "m, s", 4);
    line("4 kinetic energy at release / landing", &[ke(&s0), ke(&land)], "J", 4);
    line("  change in KE / drag work on path", &[ke(&land) - ke(&s0), land[4]], "J", 4);
    line("  at peak: change in KE / -mgH + W", &[ke(&top) - ke(&s0), -M * G * top[1] + top[4]], "J", 4);
    line("5 across: momentum change / impulse", &[M * (land[2] - s0[2]), jx], "kg m/s", 4);
    line("  up: momentum change / impulse", &[M * (land[3] - s0[3]), jy - M * G * dr.t], "kg m/s", 4);
    line("  up: drag impulse / gravity impulse", &[jy, -M * G * dr.t], "kg m/s", 4);
    line("wrong: no air, range", &[r0], "m", 4);
    line("wrong: drag without the 1/2, range", &[range(V0, DEG, 2.0 * k)], "m", 4);
    line("wrong: drag linear in v, range", &[fly(V0, DEG, k, true, 1e-3, 0.0).land[0]], "m", 4);
    line("wrong: energy kept, landing speed", &[V0], "m/s", 4);
    line("lob 10 m/s: range with drag / no air", &[lob, lob0], "m", 4);
    line("try: best angle / range there", &[best as f64, range(V0, best as f64, k)], "deg, m", 4);
    line("try: Cd = 0.5, range", &[range(V0, DEG, k * 0.5 / CD)], "m", 4);
    line("try: 40 m/s, range drag / no air", &[range(40.0, DEG, k), 1600.0 / G], "m", 4);
    line("try: release 2 m up, range", &[fly(V0, DEG, k, false, 1e-3, 2.0).land[0]], "m", 4);

    println!("{:>8}{:>10}{:>11}{:>8}{:>8}{:>8}{:>9}", "time s", "height m", "speed m/s", "KE J", "PE J", "lost J", "total J");
    for i in [0usize, 500, 1000, 1500, 2000, 2500, 3000, 3500, usize::MAX] {
        let (s, t) = if i == usize::MAX { (land, dr.t) } else { (dr.path[i], i as f64 * 1e-3) };
        let (pe, lost) = (M * G * s[1].abs(), 0.0 - s[4]);
        println!("{:>8.2}{:>10.2}{:>11.2}{:>8.2}{:>8.2}{:>8.2}{:>9.2}", t, s[1].abs(), speed(&s), ke(&s), pe, lost, ke(&s) + pe + lost);
    }
    let xs: Vec<f64> = (0..10).map(|i| 10.0 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64, d: usize| xs.iter().map(|&x| format!("{:5.*}", d, f(x))).collect::<Vec<_>>().join(" ");
    println!("chart, distance m      {}", row(&|x| x, 0));
    println!("chart, height no air m {}", row(&|x| height_at(&vac.path, &vac.land, x), 1));
    println!("chart, height drag m   {}", row(&|x| height_at(&dr.path, &land, x), 1));

    assert!((vac.land[0] - r0).abs() < 1e-6);
    assert!((vac.t - t0).abs() < 1e-9);
    assert!((vac.top[1] - h0).abs() < 1e-6);
    assert!((up.top[1] - h_up).abs() < 1e-6);
    assert!((up.ttop - t_up).abs() < 1e-9);
    assert!((land[0] - dr2.land[0]).abs() < 1e-6);
    assert!(((ke(&land) - ke(&s0)) - land[4]).abs() < 1e-6);
    assert!(((ke(&top) - ke(&s0)) - (-M * G * top[1] + top[4])).abs() < 1e-6);
    assert!((M * (land[2] - s0[2]) - jx).abs() < 1e-9);
    assert!((M * (land[3] - s0[3]) - (jy - M * G * dr.t)).abs() < 1e-9);
    assert!(land[0] < 0.8 * r0);
    assert!((lob - lob0).abs() / lob0 < 0.05);
    println!("ALL CHECKS PASS");
}
