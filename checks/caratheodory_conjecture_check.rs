// Caratheodory's conjecture -- the same check as caratheodory_conjecture_check.py, in Rust.
// Standard library only, no crates.  Umbilics of an ellipsoid and an egg found two ways,
// their indices by walking a loop, Euler characteristics by Gauss-Bonnet, a torus with none,
// and the October 2026 seed.  Compile: rustc --edition 2021 -O caratheodory_conjecture_check.rs
use std::f64::consts::PI;
const A: f64 = 3.0; const B: f64 = 2.0; const C: f64 = 1.0; // ellipsoid semi-axes, cm
const EB: f64 = 2.2; const EC: f64 = 3.0;                    // egg width scale, half-length, cm
type V3 = [f64; 3];
#[derive(Clone, Copy)]
enum Surf { Ell, Egg(f64) }                                  // Egg(k): skew k per cm
fn surf(s: Surf, p: V3) -> (V3, V3, f64) {                   // gradient, Hessian diagonal, F
    match s {
        Surf::Ell => ([2.0*p[0]/(A*A), 2.0*p[1]/(B*B), 2.0*p[2]/(C*C)], [2.0/(A*A), 2.0/(B*B), 2.0/(C*C)],
            p[0]*p[0]/(A*A) + p[1]*p[1]/(B*B) + p[2]*p[2]/(C*C) - 1.0),
        Surf::Egg(k) => {
            let z = p[2]; let (u, u1, u2) = (1.0 - z*z/(EC*EC), -2.0*z/(EC*EC), -2.0/(EC*EC));
            let (w, w1, w2) = ((1.0 + k*z)*(1.0 + k*z), 2.0*k*(1.0 + k*z), 2.0*k*k);
            ([2.0*p[0], 2.0*p[1], -EB*EB*(u1*w + u*w1)], [2.0, 2.0, -EB*EB*(u2*w + 2.0*u1*w1 + u*w2)],
             p[0]*p[0] + p[1]*p[1] - EB*EB*u*w)
        }
    }
}
fn rho(k: f64, th: f64) -> f64 { EB*th.sin()*(1.0 + k*EC*th.cos()) }
fn dot(u: V3, v: V3) -> f64 { u[0]*v[0] + u[1]*v[1] + u[2]*v[2] }
fn crs(u: V3, v: V3) -> V3 { [u[1]*v[2]-u[2]*v[1], u[2]*v[0]-u[0]*v[2], u[0]*v[1]-u[1]*v[0]] }
fn unit(u: V3) -> V3 { let s = dot(u, u).sqrt(); [u[0]/s, u[1]/s, u[2]/s] }
fn frame(n: V3, t: V3) -> (V3, V3) { let d = dot(t, n); let t1 = unit([t[0] - d*n[0], t[1] - d*n[1], t[2] - d*n[2]]); (t1, crs(n, t1)) }
fn helper(n: V3) -> V3 { if n[2].abs() < 0.9 { [0.0, 0.0, 1.0] } else { [1.0, 0.0, 0.0] } }
fn shape(s: Surf, p: V3, t: Option<V3>) -> [f64; 3] {        // 2x2 shape matrix: m11, m12, m22
    let (g, h, _) = surf(s, p); let n = unit(g); let ng = dot(g, g).sqrt();
    let (t1, t2) = frame(n, t.unwrap_or(helper(n)));
    let q = |u: V3, v: V3| (u[0]*h[0]*v[0] + u[1]*h[1]*v[1] + u[2]*h[2]*v[2])/ng;
    [q(t1, t1), q(t1, t2), q(t2, t2)]
}
fn gap(m: [f64; 3]) -> f64 { ((m[0] - m[2]).powi(2) + 4.0*m[1]*m[1]).sqrt() }
fn epoint(th: f64, ph: f64) -> V3 { [A*th.sin()*ph.cos(), B*th.sin()*ph.sin(), C*th.cos()] }
fn rem(a: f64, b: f64) -> f64 { let r = a % b; if r < 0.0 { r + b } else { r } } // Python's %
fn turns(a: &[f64]) -> f64 { a.windows(2).map(|w| rem(w[1] - w[0] + PI/2.0, PI) - PI/2.0).sum::<f64>()/(2.0*PI) }
fn index(s: Surf, p0: V3) -> f64 {
    let (r, nn) = (0.01, 720); let n0 = unit(surf(s, p0).0); let (e1, e2) = frame(n0, helper(n0));
    let mut angs = vec![];
    for k in 0..=nn {
        let (c, sn) = ((2.0*PI*k as f64/nn as f64).cos(), (2.0*PI*k as f64/nn as f64).sin());
        let mut q = [0.0; 3]; for i in 0..3 { q[i] = p0[i] + r*(c*e1[i] + sn*e2[i]); }
        for _ in 0..30 { let (gq, _, f) = surf(s, q); let d = f/dot(gq, n0); for i in 0..3 { q[i] -= d*n0[i]; } }
        let m = shape(s, q, Some(e1)); angs.push(0.5*(2.0*m[1]).atan2(m[0] - m[2]));
    }
    turns(&angs)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    (b - a)/n as f64/3.0*(0..=n).map(|k| (if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 })
        * f(a + k as f64*(b - a)/n as f64)).sum::<f64>()
}
fn f6(x: f64) -> String { format!("{:.6}", x) }
fn degs(v: &[f64]) -> String {
    format!("[{}]", v.iter().map(|i| format!("'{:.2}'", 360.0*i)).collect::<Vec<_>>().join(", "))
}
fn profile(k: f64) -> Vec<(f64, f64)> {                       // (meridian, round) curvature pairs
    (0..2000).map(|j| { let t = PI*(j as f64 + 0.5)/2000.0;
        let m = shape(Surf::Egg(k), [rho(k, t), 0.0, EC*t.cos()], Some([0.0, 0.0, 1.0])); (m[0], m[2]) }).collect()
}
fn main() {
    let ux = A*((A*A - B*B)/(A*A - C*C)).sqrt(); let uz = C*((B*B - C*C)/(A*A - C*C)).sqrt();
    println!("ellipsoid {} x {} x {} cm: closed form umbilics at x = +-{}, y = 0, z = +-{}", A, B, C, f6(ux), f6(uz));
    let (nt, np) = (60usize, 120usize);
    let g: Vec<Vec<f64>> = (0..nt).map(|i| (0..np).map(|j| gap(shape(Surf::Ell,
        epoint((i as f64 + 0.5)*PI/nt as f64, j as f64*2.0*PI/np as f64), None)).powi(2)).collect()).collect();
    let mut found: Vec<V3> = vec![];
    for i in 1..nt - 1 { for j in 0..np {
        let mut ismin = true;
        for di in [-1i64, 0, 1] { for dj in [-1i64, 0, 1] {
            if g[i][j] > g[(i as i64 + di) as usize][((j as i64 + dj).rem_euclid(np as i64)) as usize] { ismin = false; }
        } }
        if !ismin { continue; }
        let (mut th, mut ph, mut st, mut best) = ((i as f64 + 0.5)*PI/nt as f64, j as f64*2.0*PI/np as f64, 0.05, g[i][j]);
        while st > 1e-12 {
            let mut moved = false;
            for (dt, dp) in [(st, 0.0), (-st, 0.0), (0.0, st), (0.0, -st)] {
                let v = gap(shape(Surf::Ell, epoint(th + dt, ph + dp), None)).powi(2);
                if v < best { best = v; th += dt; ph += dp; moved = true; }
            }
            if !moved { st /= 2.0; }
        }
        let p = epoint(th, ph);
        if best.sqrt() < 1e-6 && found.iter().all(|q| (0..3).map(|k| (p[k] - q[k]).powi(2)).sum::<f64>() > 1e-6) { found.push(p); }
    } }
    found.sort_by(|p, q| (-p[0]).partial_cmp(&-q[0]).unwrap().then((-p[2]).partial_cmp(&-q[2]).unwrap()));
    println!("blind search: {} grid points, umbilics found {}", nt*np, found.len());
    for p in &found {
        let m = shape(Surf::Ell, *p, None);
        println!("  umbilic ({}, {}, {}), both curvatures {} per cm, gap {:.9}", f6(p[0]), f6(p[1].abs()), f6(p[2]), f6(m[0]), gap(m));
        assert!((p[0].abs() - ux).abs() < 1e-6 && (p[2].abs() - uz).abs() < 1e-6 && p[1].abs() < 1e-6);
        assert!((m[0] - A*C/(B*B*B)).abs() < 1e-9 && (m[2] - A*C/(B*B*B)).abs() < 1e-9);  // a c / b^3
    }
    assert_eq!(found.len(), 4);
    let eidx: Vec<f64> = found.iter().map(|p| index(Surf::Ell, *p)).collect();
    println!("ellipsoid: principal line turns per loop, degrees {}", degs(&eidx));
    let ell_kda = |th: f64| (0..64).map(|j| {
        let ph = 2.0*PI*j as f64/64.0; let m = shape(Surf::Ell, epoint(th, ph), None);
        let rt = [A*th.cos()*ph.cos(), B*th.cos()*ph.sin(), -C*th.sin()];
        let rp = [-A*th.sin()*ph.sin(), B*th.sin()*ph.cos(), 0.0];
        (m[0]*m[2] - m[1]*m[1])*dot(crs(rt, rp), crs(rt, rp)).sqrt()*2.0*PI/64.0 }).sum::<f64>();
    let chi_e = simpson(ell_kda, 0.0, PI, 200)/(2.0*PI);
    let half = (2.0*eidx.iter().sum::<f64>()).round() as i64; let sum_s = if half % 2 == 0 { format!("{}", half/2) } else { format!("{}/2", half) };
    println!("ellipsoid: Gauss-Bonnet total curvature / 2 pi = {}; index sum {}", f6(chi_e), sum_s);
    assert!(eidx.iter().all(|i| (i - 0.5).abs() < 1e-6) && (chi_e - 2.0).abs() < 1e-6);

    let k0 = 0.04; let egg = Surf::Egg(k0);                  // blunt end up, pointed end down
    let rho1 = |th: f64| EB*th.cos()*(1.0 + k0*EC*th.cos()) - EB*k0*EC*th.sin().powi(2);
    let poles = [[0.0, 0.0, EC], [0.0, 0.0, -EC]];
    for p in poles {
        let m = shape(egg, p, None); let r = EB*EB*(1.0 + k0*p[2]).powi(2)/EC;
        println!("egg pole z = {:+.0} cm: curvature {} = 1/{} per cm, gap {:.9}", p[2], f6(m[0]), f6(r), gap(m));
        assert!((m[0] - 1.0/r).abs() < 1e-12 && gap(m) < 1e-12);
    }
    let prof = profile(k0);
    let (widest, kmin) = ((0..=2000).map(|j| rho(k0, PI*j as f64/2000.0)).fold(f64::MIN, f64::max), prof.iter().map(|(a, b)| a*b).fold(f64::MAX, f64::min));
    println!("egg: length {} cm, widest {} cm; smallest Gaussian curvature {} per cm2", 2.0*EC, f6(2.0*widest), f6(kmin));
    let beats = prof.iter().filter(|(a, b)| b > a).count();
    println!("egg: round-the-circle curvature beats meridian curvature at {} of 2000 profile points", beats);
    assert_eq!(beats, 2000);
    let gidx: Vec<f64> = poles.iter().map(|p| index(egg, *p)).collect();
    let egg_kda = |th: f64| { let m = shape(egg, [rho(k0, th), 0.0, EC*th.cos()], None);
        (m[0]*m[2] - m[1]*m[1])*rho(k0, th)*(rho1(th).powi(2) + (EC*th.sin()).powi(2)).sqrt()*2.0*PI };
    let chi_g = simpson(egg_kda, 0.0, PI, 2000)/(2.0*PI);
    println!("egg: line turns per loop {}; Gauss-Bonnet / 2 pi = {}", degs(&gidx), f6(chi_g));
    assert!(gidx.iter().all(|i| (i - 1.0).abs() < 1e-6) && (chi_g - 2.0).abs() < 1e-6);
    // What breaks 1: a blunter egg (skew 0.06 per cm) grows a whole circle of umbilics
    let p6 = profile(0.06); let flips: Vec<usize> = (0..1999).filter(|&k| (p6[k].1 > p6[k].0) != (p6[k+1].1 > p6[k+1].0)).collect();
    println!("blunter egg: the two curvatures swap order {} time, near z = {:.3} cm: a whole circle of umbilics there",
        flips.len(), EC*(PI*(flips[0] + 1) as f64/2000.0).cos());
    assert_eq!(flips.len(), 1);
    // What breaks 2: a torus (the pasta ring, a = 1.5 mm tube, b = 4 mm ring) has no umbilic
    let (ta, tb) = (1.5, 4.0);
    let tg = (0..3600).map(|k| { let v = 2.0*PI*k as f64/3600.0; 1.0/ta - v.cos()/(tb + ta*v.cos()) }).fold(f64::MAX, f64::min);
    let chi_t = simpson(|v: f64| (1.0/ta)*v.cos()/(tb + ta*v.cos())*ta*(tb + ta*v.cos())*2.0*PI, 0.0, 2.0*PI, 200)/(2.0*PI);
    println!("torus: smallest kappa1 - kappa2 = {} per mm, umbilics 0; Gauss-Bonnet / 2 pi = {:.6}", f6(tg), chi_t.abs());
    assert!((tg - (1.0/ta - 1.0/(ta + tb))).abs() < 1e-12 && chi_t.abs() < 1e-9);
    // Model umbilics on z = (x2 + y2)/2 + cubic: the line of the Hessian, walked round the origin
    let germ = |d: &dyn Fn(f64, f64) -> f64, e: &dyn Fn(f64, f64) -> f64| turns(&(0..=720).map(|k| {
        let (x, y) = ((2.0*PI*k as f64/720.0).cos(), (2.0*PI*k as f64/720.0).sin());
        0.5*(2.0*e(x, y)).atan2(d(x, y)) }).collect::<Vec<f64>>());
    let (lemon, star) = (germ(&|x, _| 4.0*x, &|_, y| 2.0*y), germ(&|x, _| 12.0*x, &|_, y| -6.0*y)); // x^3 + xy^2, x^3 - 3xy^2
    println!("model germs: lemon x^3 + xy^2 index {:+.6}, star x^3 - 3xy^2 index {:+.6}", lemon, star);
    assert!((lemon - 0.5).abs() < 1e-9 && (star + 0.5).abs() < 1e-9);
    // Exact arithmetic, in halves: Poincare-Hopf sums and the fewest umbilics each bound allows
    println!("sums: {} = 4 x 1/2 (ellipsoid); {} = 2 x 1 (egg); 5 lemons + 1 star: {}", 4*1/2, 2*1, (5 - 1)/2);
    for (name, mh, ms) in [("Loewner, index <= 1", 2i64, "1"), ("index < 2, so <= 3/2", 3, "3/2"), ("no bound but 2", 4, "2")] {
        println!("  {}: fewest umbilics = ceil(2 / {}) = {}", name, ms, (4 + mh - 1)/mh); }  // 2 = 4 halves
    // The October 2026 seed F = a(x) - a(y) + sin x sin y, a(t) = sin^4 t + 3 sin^2 t
    let app = |t: f64| 6.0 - 16.0*t.sin().powi(4);
    let aa = |t: f64| t.sin().powi(4) + 3.0*t.sin().powi(2); let h = 1e-4;
    assert!((0..315).map(|t| { let t = t as f64/100.0; (app(t) - (aa(t + h) - 2.0*aa(t) + aa(t - h))/h/h).abs() })
        .fold(0.0, f64::max) < 1e-5);
    let m = 400; let mut mz = f64::MAX;
    for i in 0..m { for j in 0..m {
        let (x, y) = (PI*i as f64/m as f64, PI*j as f64/m as f64);
        mz = mz.min(((app(x) + app(y)).powi(2) + 4.0*(x.cos()*y.cos()).powi(2)).sqrt()/4.0);
    } }
    println!("seed: smallest |F_zz| on a {} x {} grid of one period = {}; a'' runs from {} to {}", m, m, f6(mz), app(PI/2.0), app(0.0));
    assert!(mz > 0.17);
    let s = 50.0; let pts: Vec<String> = found.iter().map(|p| format!("{:.1} {:.1}", 200.0 + s*p[0], 190.0 - s*p[2])).collect();
    println!("figure,{};560 {:.0};560 {:.0}", pts.join(";"), 190.0 - s*EC, 190.0 + s*EC);
    println!("ALL CHECKS PASS");
}
