// Fundamental theorem of curves -- the same check as the Python, in Rust.  No
// crates.  A ski run is known only by its bend kappa and twist tau (1/m) along
// the distance s skied (m).  The frame equations T' = kN, N' = -kT + tB,
// B' = -tN, r' = T are stepped by RK4 to rebuild it.  Roads: the helix formula,
// bend and twist measured back off the rebuilt points, and a second start.
use std::f64::consts::PI;
type V = [f64; 3];
type St = [V; 4]; // position r, then the frame T, N, B
const K0: f64 = 0.012;
const TW: f64 = 0.0024;

fn add(u: V, v: V, k: f64) -> V { [u[0] + k * v[0], u[1] + k * v[1], u[2] + k * v[2]] }
fn dot(u: V, v: V) -> f64 { u[0] * v[0] + u[1] * v[1] + u[2] * v[2] }
fn cross(u: V, v: V) -> V { [u[1]*v[2] - u[2]*v[1], u[2]*v[0] - u[0]*v[2], u[0]*v[1] - u[1]*v[0]] }
fn dist(u: V, v: V) -> f64 { dot(add(u, v, -1.0), add(u, v, -1.0)).sqrt() }
fn scale(k: f64, u: V) -> V { [k * u[0], k * u[1], k * u[2]] }
fn f(x: f64, d: i32) -> String {
    let y = if x.abs() < 0.5 * 10f64.powi(-d) { 0.0 } else { x };
    format!("{:.*}", d as usize, y)
}
fn pt(p: V) -> String { format!("({}, {}, {})", f(p[0], 2), f(p[1], 2), f(p[2], 2)) }

fn rates(st: &St, k: f64, t: f64) -> St { // the Frenet-Serret equations
    [st[1], scale(k, st[2]), add(scale(-k, st[1]), st[3], t), scale(-t, st[2])]
}
fn shift(st: &St, d: &St, h: f64) -> St {
    [add(st[0], d[0], h), add(st[1], d[1], h), add(st[2], d[2], h), add(st[3], d[3], h)]
}
fn step(st: &St, kap: &dyn Fn(f64) -> f64, tau: &dyn Fn(f64) -> f64, s: f64, h: f64, euler: bool) -> St {
    let k1 = rates(st, kap(s), tau(s));
    if euler { return shift(st, &k1, h); }
    let k2 = rates(&shift(st, &k1, h / 2.0), kap(s + h / 2.0), tau(s + h / 2.0));
    let k3 = rates(&shift(st, &k2, h / 2.0), kap(s + h / 2.0), tau(s + h / 2.0));
    let k4 = rates(&shift(st, &k3, h), kap(s + h), tau(s + h));
    let mut out = *st;
    for j in 0..4 { for i in 0..3 {
        out[j][i] = st[j][i] + h / 6.0 * (k1[j][i] + 2.0 * k2[j][i] + 2.0 * k3[j][i] + k4[j][i]);
    } }
    out
}
fn rebuild(st0: St, kap: &dyn Fn(f64) -> f64, tau: &dyn Fn(f64) -> f64, length: f64, n: usize, euler: bool) -> (St, Vec<V>) {
    let h = length / n as f64;
    let (mut st, mut pts) = (st0, vec![st0[0]]);
    for i in 0..n {
        st = step(&st, kap, tau, i as f64 * h, h, euler);
        pts.push(st[0]);
    }
    (st, pts)
}
fn start(r0: V, t0: V, n0: V) -> St { [r0, t0, n0, cross(t0, n0)] }
fn vol(p: [V; 4]) -> f64 { dot(cross(add(p[1], p[0], -1.0), add(p[2], p[0], -1.0)), add(p[3], p[0], -1.0)) }

fn main() {
    let w2 = K0 * K0 + TW * TW;
    let (a, c, rad) = (K0 / w2, TW / w2, 1.0 / w2.sqrt()); // radius, drop per radian, m per radian
    let l = 2.0 * PI * rad; // one full turn of the run, m
    let helix = |s: f64| -> V { [a * (s / rad).sin(), -a * (1.0 - (s / rad).cos()), -c * s / rad] };
    let chord = |dt: f64| (2.0 * a * a * (1.0 - dt.cos()) + c * c * dt * dt).sqrt();
    let kc = |_s: f64| K0;
    let tc = |_s: f64| TW;
    let s0 = start([0.0, 0.0, 0.0], [a / rad, 0.0, -c / rad], [0.0, -1.0, 0.0]);
    println!("survey: bend {} 1/m, twist {} 1/m, turn radius 1/bend {} m", f(K0, 4), f(TW, 4), f(1.0 / K0, 2));
    println!("helix: radius {} m, drop per radian {} m, grade twist/bend {} = {} deg",
             f(a, 3), f(c, 3), f(TW / K0, 3), f((TW / K0).atan().to_degrees(), 2));
    println!("bend^2 + twist^2 = {} 1/m^2; {} m per radian; one turn: length {} m, drop {} m", f(w2, 8), f(rad, 3), f(l, 2), f(2.0 * PI * c, 2));
    println!("start frame: T {}, N {}, B {}", pt(s0[1]), pt(s0[2]), pt(s0[3]));
    let (t1, n1, b1) = (add(s0[1], s0[2], 10.0 * K0), add(s0[2], add(scale(-K0, s0[1]), s0[3], TW), 10.0), add(s0[3], s0[2], -10.0 * TW));
    let r1 = add(scale(10.0, s0[1]), s0[2], 50.0 * K0); // one 10 m step by hand; r'' = T' = kN gives the 50 k N
    println!("one 10 m step by hand: T {}, N {}, B {}; r = 10 T + 50 k N = {}, helix {}, {} m apart", pt(t1), pt(n1), pt(b1), pt(r1), pt(helix(10.0)), f(dist(r1, helix(10.0)), 3));
    let (mut end, mut fine) = (s0, vec![]);
    for n in [52usize, 512] {
        let (e, pts) = rebuild(s0, &kc, &tc, l, n, false);
        let mut err: f64 = 0.0;
        for i in (0..=n).step_by(n / 4) { err = err.max(dist(pts[i], helix(i as f64 * l / n as f64))); }
        println!("RK4, step {} m: finish {}, worst miss at quarter points {} mm", f(l / n as f64, 3), pt(e[0]), f(1000.0 * err, 4));
        end = e;
        fine = pts;
    }
    for q in 0..5 {
        println!("s = {} m: rebuilt {}, helix formula {}", f(q as f64 * l / 4.0, 2), pt(fine[q * 128]), pt(helix(q as f64 * l / 4.0)));
    }
    println!("frame still orthonormal at finish: |T| = {}, T.N = {}", f(dot(end[1], end[1]).sqrt(), 9), f(dot(end[1], end[2]), 9));
    let s2 = start([350.0, 120.0, -40.0], [0.0, a / rad, -c / rad], [1.0, 0.0, 0.0]); // another place, heading north
    let (end2, pts2) = rebuild(s2, &kc, &tc, l, 512, false);
    println!("second start (350, 120, -40) heading north: finish {}", pt(end2[0]));
    for (i, j) in [(0usize, 128usize), (0, 256), (128, 384), (0, 512)] {
        let (c1, c2, c3) = (dist(fine[i], fine[j]), dist(pts2[i], pts2[j]), chord(PI * (j - i) as f64 / 256.0));
        println!("chord quarter {} to {}: run 1 {} m, run 2 {} m, formula {} m", i / 128, j / 128, f(c1, 3), f(c2, 3), f(c3, 3));
        assert!((c1 - c3).abs() < 1e-6 && (c2 - c3).abs() < 1e-6); // rigid copies, one shape
    }
    let kt = |s: f64| 0.006 + 0.00002 * s; // a run whose bend tightens
    let (e10, _) = rebuild(s0, &kt, &tc, 500.0, 50, false);
    let (e1, p1) = rebuild(s0, &kt, &tc, 500.0, 500, false);
    println!("tightening run, 500 m: finish at step 10 m {}, at 1 m {}, gap {} mm", pt(e10[0]), pt(e1[0]), f(1000.0 * dist(e10[0], e1[0]), 3));
    for s in [100usize, 250, 400] { // measure back: any-speed formulas, 1 m differences
        let (m2, m1, z, q1, q2) = (p1[s - 2], p1[s - 1], p1[s], p1[s + 1], p1[s + 2]);
        let mut d1 = [0.0; 3];
        let mut d2 = [0.0; 3];
        let mut d3 = [0.0; 3];
        for i in 0..3 {
            d1[i] = (q1[i] - m1[i]) / 2.0;
            d2[i] = q1[i] - 2.0 * z[i] + m1[i];
            d3[i] = (q2[i] - 2.0 * q1[i] + 2.0 * m1[i] - m2[i]) / 2.0;
        }
        let x = cross(d1, d2);
        let (km, tm) = (dot(x, x).sqrt() / dot(d1, d1).powf(1.5), dot(x, d3) / dot(x, x));
        println!("measured back at s = {} m: bend {} (asked {}), twist {} (asked {})", s, f(km, 6), f(kt(s as f64), 6), f(tm, 7), f(TW, 7));
        assert!((km - kt(s as f64)).abs() < 1e-6 && (tm - TW).abs() < 1e-7); // the asked bend and twist
    }
    let (mir, pm) = rebuild(s0, &kc, &|_s: f64| -TW, l, 512, false);
    let (flat, _) = rebuild(s0, &kc, &|_s: f64| 0.0, l, 512, false);
    let (eul, _) = rebuild(s0, &kc, &tc, l, 512, true);
    let fin = helix(l);
    let (v1, v2) = (vol([fine[0], fine[128], fine[256], fine[384]]), vol([pm[0], pm[128], pm[256], pm[384]]));
    println!("handedness, signed volume of quarter-point chords: run {} m^3, twist flipped {} m^3", f(v1, 0), f(v2, 0));
    println!("mistake 1, twist dropped: finish {}, {} m from the bottom station", pt(flat[0]), f(dist(flat[0], fin), 2));
    println!("mistake 2, twist sign flipped: finish {}, {} m from the bottom station", pt(mir[0]), f(dist(mir[0], fin), 2));
    println!("mistake 3, Euler steps of {} m: finish {}, {} m off, |T| = {}", f(l / 512.0, 3), pt(eul[0]), f(dist(eul[0], fin), 2), f(dot(eul[1], eul[1]).sqrt(), 4));
    for spin in [0, 90] { // mistake 4: a straight 60 m schuss, where bend = 0
        let (mut st, _) = rebuild(s0, &kc, &tc, l / 4.0, 128, false);
        st[0] = add(st[0], st[1], 60.0);
        if spin != 0 { // bend 0: N and B are free to turn about T
            let n = st[2];
            st[2] = st[3];
            st[3] = scale(-1.0, n);
        }
        let (st, _) = rebuild(st, &kc, &tc, l / 4.0, 128, false);
        println!("mistake 4, turn, 60 m straight, turn, frame spun {} deg on the straight: finish {}, {} m from the top", spin, pt(st[0]), f(dist(st[0], [0.0, 0.0, 0.0]), 2));
    }
    println!("figure, plan centre (0.00, {}), radius {}; side: x = {} sin(s/{}), z = -{} s/{}", f(-a, 2), f(a, 2), f(a, 2), f(rad, 3), f(c, 3), f(rad, 3));
    assert!(dist(fine[512], fin) < 1e-5 && dist(fine[256], helix(l / 2.0)) < 1e-5); // RK4 against the formula
    assert!(v1 > 1000.0 && (v1 + v2).abs() < 1e-3 * v1.abs()); // a mirror flips handedness
    assert!(dist(mir[0], fin) > 1.0 && dist(flat[0], fin) > 1.0); // the twist matters
    println!("ALL CHECKS PASS");
}
