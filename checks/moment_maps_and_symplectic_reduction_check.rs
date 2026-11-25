// Moment maps and symplectic reduction -- the check behind the card.  std only.
// Yaw turns (the circle group SO(2)) act on the plane's phase space z = (x, y, px, py).
// Road 1: the moment map from its definition, iota_X omega = dJ, by finite differences.
// Road 2: the planar Kepler problem stepped in all four coordinates (RK4): J and H stay put.
// Road 3: the reduced system at J = 6, one radial degree of freedom, against the full run
//         and against the closed-form turning points and period.
// Road 4: SO(3): the moment map r x p is equivariant; a tumbling drone's body momentum
//         stays on a sphere, its coadjoint orbit.
use std::f64::consts::PI;
const M: f64 = 1.0; const K: f64 = 12.0; const WIND: f64 = 0.05; // kg; N m^2; N
const Z0: [f64; 4] = [2.0, 0.0, 0.0, 3.0]; // x m, y m, px kg m/s, py kg m/s
const ZT: [f64; 4] = [1.3, -0.7, 0.4, 2.1]; // a second test point, nothing special about it
type V4 = [f64; 4];
type V3 = [f64; 3];

fn dot(a: &[f64], b: &[f64]) -> f64 { let mut t = 0.0; for i in 0..a.len() { t += a[i] * b[i]; } t }
fn jm(z: &V4) -> f64 { z[0] * z[3] - z[1] * z[2] }
fn ham(z: &V4, f: f64) -> f64 {
    (z[2].powf(2.0) + z[3].powf(2.0)) / (2.0 * M) - K / (z[0].powf(2.0) + z[1].powf(2.0)).sqrt() - f * z[0]
}
fn turn(z: &V4, s: f64, momenta: bool) -> V4 { // yaw by angle s; the momenta turn too unless told not to
    let (c, n) = (s.cos(), s.sin());
    let (px, py) = if momenta { (c * z[2] - n * z[3], n * z[2] + c * z[3]) } else { (z[2], z[3]) };
    [c * z[0] - n * z[1], n * z[0] + c * z[1], px, py]
}
fn grad(f: &dyn Fn(&V4) -> f64, z: &V4) -> V4 { // central differences
    let h = 1e-5; let mut out = [0.0; 4];
    for i in 0..4 { let (mut a, mut b) = (*z, *z); a[i] += h; b[i] -= h; out[i] = (f(&a) - f(&b)) / (2.0 * h); }
    out
}
fn gen(z: &V4, momenta: bool) -> V4 { // the generating field X: velocity of the turn at s = 0
    let h = 1e-6; let (a, b) = (turn(z, h, momenta), turn(z, -h, momenta));
    let mut out = [0.0; 4]; for i in 0..4 { out[i] = (a[i] - b[i]) / (2.0 * h); } out
}
fn iota(x: &V4) -> V4 { [-x[2], -x[3], x[0], x[1]] } // iota_X omega in (dx, dy, dpx, dpy) parts
fn curl(alpha: &dyn Fn(&V4) -> V4, z: &V4) -> f64 { // largest entry of d(alpha)
    let h = 1e-4; let mut g = [[0.0; 4]; 4];
    for i in 0..4 {
        let (mut a, mut b) = (*z, *z); a[i] = z[i] + h; b[i] = z[i] - h;
        let (fa, fb) = (alpha(&a), alpha(&b));
        for j in 0..4 { g[i][j] = (fa[j] - fb[j]) / (2.0 * h); }
    }
    let mut m: f64 = 0.0;
    for i in 0..4 { for j in 0..4 { m = m.max((g[i][j] - g[j][i]).abs()); } }
    m
}
fn rk4<const N: usize>(f: &dyn Fn(&[f64; N]) -> [f64; N], z: &[f64; N], dt: f64) -> [f64; N] {
    let step = |k: &[f64; N], w: f64| { let mut o = *z; for i in 0..N { o[i] = z[i] + w * k[i]; } o };
    let k1 = f(z); let k2 = f(&step(&k1, dt / 2.0)); let k3 = f(&step(&k2, dt / 2.0)); let k4 = f(&step(&k3, dt));
    let mut o = *z;
    for i in 0..N { o[i] = z[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    o
}
fn full(f: f64) -> impl Fn(&V4) -> V4 { // Hamilton's equations in x, y, px, py
    move |z: &V4| { let r = (z[0].powf(2.0) + z[1].powf(2.0)).sqrt(); let r3 = r * r * r;
        [z[2] / M, z[3] / M, -K * z[0] / r3 + f, -K * z[1] / r3] }
}
fn reduced(c: f64) -> impl Fn(&V3) -> V3 { // (r, pr, theta): one radial freedom plus the angle rebuilt
    move |s: &V3| [s[1] / M, c * c / (M * s[0].powf(3.0)) - K / s[0].powf(2.0), c / (M * s[0].powf(2.0))]
}
fn veff(r: f64, c: f64) -> f64 { c * c / (2.0 * M * r * r) - K / r }
fn cross(a: &V3, b: &V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn rot(v: &V3, n: &V3, t: f64) -> V3 { // Rodrigues: turn v by angle t about unit axis n
    let w = cross(n, v); let d = dot(n, v); let mut o = [0.0; 3];
    for i in 0..3 { o[i] = v[i] * t.cos() + w[i] * t.sin() + n[i] * d * (1.0 - t.cos()); } o
}
fn qrot(v: &V3, n: &V3, t: f64) -> V3 { // the same turn by the unit quaternion (cos t/2, n sin t/2)
    let q0 = (t / 2.0).cos(); let q = [n[0] * (t / 2.0).sin(), n[1] * (t / 2.0).sin(), n[2] * (t / 2.0).sin()];
    let w = cross(&q, v); let u = cross(&q, &w); [v[0] + 2.0 * q0 * w[0] + 2.0 * u[0], v[1] + 2.0 * q0 * w[1] + 2.0 * u[1], v[2] + 2.0 * q0 * w[2] + 2.0 * u[2]]
}
fn sci(x: f64) -> String { // Python's {:.1e}: two-digit exponent with a sign
    let t = format!("{:.1e}", x); let (m, e) = t.split_once('e').unwrap(); let v: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if v < 0 { '-' } else { '+' }, v.abs())
}
fn f3(v: &V3) -> String { format!("{:.6} {:.6} {:.6}", v[0], v[1], v[2]) }

fn main() {
    // Road 1: the moment map from its definition
    let c = jm(&Z0);
    let mut gap: f64 = 0.0;
    for z in [Z0, ZT] { let (a, b) = (iota(&gen(&z, true)), grad(&jm, &z)); for i in 0..4 { gap = gap.max((a[i] - b[i]).abs()); } }
    let d_full = curl(&|z: &V4| iota(&gen(z, true)), &ZT);
    let d_pos = curl(&|z: &V4| iota(&gen(z, false)), &ZT);
    let xh = |z: &V4, f: f64| { let g = grad(&|w: &V4| ham(w, f), z); [g[2], g[3], -g[0], -g[1]] };
    let pb0 = dot(&grad(&jm, &ZT), &xh(&ZT, 0.0));
    let pbw = dot(&grad(&jm, &ZT), &xh(&ZT, WIND));
    println!("moment map J at the start: {:.6} kg m^2/s", c);
    println!("iota_X omega minus dJ, largest gap at two points: {}", sci(gap));
    println!("d(iota_X omega): turn x and p {:.6}; turn x only {:.6}", d_full, d_pos);
    println!("dJ/dt = {{J, H}} at test point: no wind {}, wind 0.05 N {:.6}", sci(pb0.abs()), pbw);
    assert!(gap < 1e-6);
    assert!(d_full < 1e-5 && (d_pos - 1.0).abs() < 1e-5 && (pbw - 0.035).abs() < 1e-6);

    // closed forms for the reduced orbit at J = 6
    let e = ham(&Z0, 0.0); let disc = (K * K + 2.0 * e * c * c / M).sqrt();
    let (r_lo, r_hi) = ((-K + disc) / (2.0 * e), (-K - disc) / (2.0 * e));
    let a = -K / (2.0 * e); let p = 2.0 * PI * (M * a.powf(3.0) / K).sqrt(); let rc = c * c / (M * K);
    println!("energy E {:.6} J; Veff(2) {:.6} J; well bottom r {:.6} m, Veff {:.6} J", e, veff(2.0, c), rc, veff(rc, c));
    println!("kinetic {:.6} J, pull {:.6} J; turning points {:.6} m and {:.6} m",
        (Z0[2].powf(2.0) + Z0[3].powf(2.0)) / (2.0 * M), K / Z0[0], r_lo, r_hi);
    println!("semi-major axis {:.6} m; period {:.6} s", a, p);
    let ch: Vec<String> = (0..14).map(|i| format!("{:.2}", veff(1.5 + 0.5 * i as f64, c))).collect();
    println!("chart Veff r=1.5..8: {}", ch.join(" "));

    // Road 2 (full, four coordinates) against Road 3 (reduced, one radial freedom), at two steps
    let (fl, rd) = (full(0.0), reduced(c));
    let (mut rq, mut xhalf, mut th, mut s) = (Vec::new(), 0.0, 0.0, [2.0, 0.0, 0.0]);
    let (mut jd, mut gr): (f64, f64) = (0.0, 0.0);
    for n in [2000usize, 4000] {
        let dt = p / n as f64; let mut z = Z0; s = [Z0[0], Z0[2], 0.0]; // start on the x axis
        jd = 0.0; gr = 0.0; let mut hd: f64 = 0.0; rq.clear();
        for i in 1..=n {
            z = rk4(&fl, &z, dt); s = rk4(&rd, &s, dt);
            jd = jd.max((jm(&z) - c).abs()); hd = hd.max((ham(&z, 0.0) - e).abs());
            gr = gr.max(((z[0].powf(2.0) + z[1].powf(2.0)).sqrt() - s[0]).abs());
            if i % (n / 4) == 0 { rq.push(s[0]); }
            if i == n / 2 { xhalf = z[0]; th = s[2]; }
        }
        println!("N={}: J drift {}, H drift {}, full x at P/2 {:.6}, reduced r gap {}", n, sci(jd), sci(hd), xhalf, sci(gr));
    }
    let rs: Vec<String> = rq.iter().map(|v| format!("{:.6}", v)).collect();
    println!("reduced r at P/4, P/2, 3P/4, P: {}", rs.join(" "));
    println!("angle rebuilt from theta' = J/(m r^2): {:.6} rad at P/2, {:.6} rad at P", th, s[2]);
    let far = r_lo + r_hi - Z0[0]; // the turning point opposite the start
    assert!((xhalf + far).abs() < 1e-6 && jd < 1e-9 && gr < 1e-6);
    assert!((rq[1] - far).abs() < 1e-6 && (rq[3] - Z0[0]).abs() < 1e-6 && (s[2] - 2.0 * PI).abs() < 1e-6);

    // What breaks: a wind push breaks the symmetry; dropping J^2/(2 m r^2) lets the body fall in
    let fw = full(WIND); let (mut z, mut tq) = (Z0, 0.0); // tq: the wind's torque -y F summed over time, trapezoid rule
    for _ in 0..4000 { let y_ = z[1]; z = rk4(&fw, &z, p / 4000.0); tq -= WIND * (y_ + z[1]) / 2.0 * p / 4000.0; }
    let r0 = reduced(0.0); let (mut s, mut t) = ([2.0, 0.0, 0.0], 0.0);
    while s[0] > 0.05 { s = rk4(&r0, &s, 1e-5); t = t + 1e-5; }
    let u = (0.05f64 / 2.0).sqrt().asin();
    let tf = (M * 2.0f64.powf(3.0) / (2.0 * K)).sqrt() * (PI / 2.0 - u + u.sin() * u.cos());
    println!("wind 0.05 N: J after one period {:.6} kg m^2/s; 6 plus the torque's time integral {:.6}", jm(&z), c + tq);
    println!("no J^2/(2 m r^2) term: reaches r = 0.05 m at {:.4} s (closed form {:.4} s), r = 0 at {:.4} s",
        t, tf, PI / 2.0 * (M * 8.0 / (2.0 * K)).sqrt());
    println!("dimensions: phase space 4, level set J = 6 is 3, reduced 3 - 1 = 2; SO(3) on 6: 6 - 3 - 1 = 2");
    assert!((jm(&z) - c).abs() > 0.01 && (jm(&z) - (c + tq)).abs() < 1e-5 && (t - tf).abs() < 1e-4);

    // Road 4: SO(3). J = r x p is equivariant: J(R r, R p) = R J(r, p)
    let (rv, pv, ax): (V3, V3, V3) = ([2.0, 0.0, 0.5], [0.0, 3.0, 0.4], [1.0 / 3.0, 2.0 / 3.0, 2.0 / 3.0]);
    let j3 = cross(&rv, &pv); let rj = rot(&j3, &ax, 0.7); let jr = cross(&rot(&rv, &ax, 0.7), &rot(&pv, &ax, 0.7));
    println!("J(r, p) = {}; R J = {}; J(R r, R p) = {}", f3(&j3), f3(&rj), f3(&jr));
    let qj = qrot(&j3, &ax, 0.7);
    println!("R J by a unit quaternion instead: {}", f3(&qj));
    println!("|J| before and after the turn: {:.6} {:.6}", dot(&j3, &j3).sqrt(), dot(&jr, &jr).sqrt());
    assert!((0..3).map(|i| (rj[i] - jr[i]).abs()).fold(0.0, f64::max) < 1e-12 && (0..3).map(|i| (rj[i] - qj[i]).abs()).fold(0.0, f64::max) < 1e-12);

    // A drone tossed spinning about its middle axis: Euler's equations Pi' = Pi x Omega
    let im: V3 = [0.010, 0.012, 0.020]; // principal moments of inertia, kg m^2
    let ke = |q: &V3| dot(&[q[0] / (2.0 * im[0]), q[1] / (2.0 * im[1]), q[2] / (2.0 * im[2])], q); // J
    let body = |q: &V3| cross(q, &[q[0] / im[0], q[1] / im[1], q[2] / im[2]]);
    let mut pi = [im[0] * 0.05, im[1] * 3.0, im[2] * 0.05]; let l0 = dot(&pi, &pi).sqrt();
    let e0 = ke(&pi); let y0 = pi[1]; let mut ymin = pi[1]; let (mut ld, mut ed): (f64, f64) = (0.0, 0.0);
    for _ in 0..20000 {
        pi = rk4(&body, &pi, 1e-3); ymin = ymin.min(pi[1]);
        ld = ld.max((dot(&pi, &pi).sqrt() - l0).abs());
        ed = ed.max((ke(&pi) - e0).abs());
    }
    println!("tumbling drone: |Pi| {:.6} g m^2/s, drift {}; energy {:.6} mJ, drift {}", 1000.0 * l0, sci(1000.0 * ld), 1000.0 * e0, sci(1000.0 * ed));
    println!("Pi_y starts {:.6}, lowest {:.6} g m^2/s; a flip sends it near -|Pi|", 1000.0 * y0, 1000.0 * ymin);
    assert!(ld < 1e-9 && ed < 1e-9 && ymin < -0.9 * l0);
    println!("ALL CHECKS PASS");
}
