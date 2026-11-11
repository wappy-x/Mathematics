// State space: cart and pendulum, x' = Ax + Bu, y = Cx + Du.  std only, no crates.
// Every number on the card is printed here.  Four roads to the state at 0.5 s:
// closed form (cosh, sinh), series e^(At) plus Simpson's rule, exact 100 Hz steps, RK4.
type V = [f64; 4];
type M = [[f64; 4]; 4];
const G: f64 = 9.81; // gravity, m/s^2
const L: f64 = 0.613125; // rod length, m
const C: V = [0.0, 0.0, 1.0, 0.0]; // the encoder reads the tilt only
const D: f64 = 0.0;
const T: f64 = 0.5; // read the state at 0.5 s

fn a() -> f64 { G / L } // 16 per s^2
fn c() -> f64 { 1.0 / L } // 1.631 rad per m
fn w() -> f64 { a().sqrt() } // 4 per s: the falling rod's growth rate
fn am() -> M { [[0.0, 1.0, 0.0, 0.0], [0.0; 4], [0.0, 0.0, 0.0, 1.0], [0.0, 0.0, a(), 0.0]] }
fn bv() -> V { [0.0, 1.0, 0.0, -c()] } // input u: cart acceleration, m/s^2
fn mm(x: &M, y: &M) -> M {
    let mut r = [[0.0; 4]; 4];
    for i in 0..4 { for j in 0..4 { for k in 0..4 { r[i][j] += x[i][k] * y[k][j]; } } }
    r
}
fn mv(x: &M, v: &V) -> V {
    let mut r = [0.0; 4];
    for i in 0..4 { for k in 0..4 { r[i] += x[i][k] * v[k]; } }
    r
}
fn add(p: &V, q: &V) -> V { [p[0] + q[0], p[1] + q[1], p[2] + q[2], p[3] + q[3]] }
fn scale(s: f64, v: &V) -> V { [s * v[0], s * v[1], s * v[2], s * v[3]] }
// shift 0: e^(At); shift 1: integral of e^(As) ds from 0 to t
fn series(t: f64, shift: usize) -> M {
    let d = if shift == 1 { t } else { 1.0 };
    let mut s = [[0.0; 4]; 4];
    for i in 0..4 { s[i][i] = d; }
    let mut term = s;
    for k in 1..60 {
        term = mm(&term, &am());
        for i in 0..4 { for j in 0..4 { term[i][j] *= t / (k + shift) as f64; s[i][j] += term[i][j]; } }
    }
    s
}
// road 1: e^(At) by blocks, convolution done by hand; returns (free, forced)
fn closed(t: f64, x: &V, u: f64, sign: f64) -> (V, V) {
    let (ch, sh) = ((w() * t).cosh(), (w() * t).sinh());
    let free = [x[0] + t * x[1], x[1], ch * x[2] + sh / w() * x[3], w() * sh * x[2] + ch * x[3]];
    let forced = [u * t * t / 2.0, u * t, -sign * c() * u * (ch - 1.0) / a(), -sign * c() * u * sh / w()];
    (free, forced)
}
// road 2: the formula itself, integral by Simpson's rule
fn simpson(t: f64, x: &V, u: f64) -> V {
    let n = 200;
    let h = t / n as f64;
    let mut acc = [0.0; 4];
    for i in 0..=n {
        let wt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        acc = add(&acc, &scale(wt * h / 3.0 * u, &mv(&series(t - i as f64 * h, 0), &bv())));
    }
    add(&mv(&series(t, 0), x), &acc)
}
// road 3: exact 100 Hz steps, x_{k+1} = Phi x_k + Gam u
fn stepped(t: f64, x0: &V, u: f64) -> V {
    let dt = 0.01;
    let (phi, gam) = (series(dt, 0), mv(&series(dt, 1), &bv()));
    let mut x = *x0;
    for _ in 0..(t / dt).round() as usize { x = add(&mv(&phi, &x), &scale(u, &gam)); }
    x
}
fn f_lin(x: &V, u: f64) -> V { add(&mv(&am(), x), &scale(u, &bv())) }
fn f_non(x: &V, u: f64) -> V { [x[1], u, x[3], (G * x[2].sin() - u * x[2].cos()) / L] }
// road 4: a plain numerical integrator
fn rk4(f: fn(&V, f64) -> V, u: f64, t: f64, x0: &V, dt: f64) -> V {
    let mut x = *x0;
    for _ in 0..(t / dt).round() as usize {
        let k1 = f(&x, u);
        let k2 = f(&add(&x, &scale(dt / 2.0, &k1)), u);
        let k3 = f(&add(&x, &scale(dt / 2.0, &k2)), u);
        let k4 = f(&add(&x, &scale(dt, &k3)), u);
        let sum = add(&add(&k1, &scale(2.0, &k2)), &add(&scale(2.0, &k3), &k4));
        x = add(&x, &scale(dt / 6.0, &sum));
    }
    x
}
// Gaussian elimination, for G(s) = C (sI - A)^-1 B + D
fn solve(m0: &M, b: &V) -> V {
    let mut m = [[0.0; 5]; 4];
    for i in 0..4 { for j in 0..4 { m[i][j] = m0[i][j]; } m[i][4] = b[i]; }
    for i in 0..4 {
        let mut p = i;
        for r in i..4 { if m[r][i].abs() > m[p][i].abs() { p = r; } }
        m.swap(i, p);
        for r in 0..4 {
            if r != i { let f = m[r][i] / m[i][i]; for j in 0..5 { m[r][j] -= f * m[i][j]; } }
        }
    }
    [m[0][4] / m[0][0], m[1][4] / m[1][1], m[2][4] / m[2][2], m[3][4] / m[3][3]]
}
// constant push that brings the tilt to 0 at time t
fn push_for(t: f64, th0: f64, rod: f64) -> f64 {
    let ch = (t * (G / rod).sqrt()).cosh();
    th0 * G * ch / (ch - 1.0)
}
fn row(name: &str, v: &[f64]) {
    let mut s = format!("{:<38}", name);
    for &z in v { s += &format!("{:>11.6}", if z.abs() > 5e-7 { z } else { 0.0 }); }
    println!("{}", s);
}
fn dot(p: &V, q: &V) -> f64 { (0..4).map(|i| p[i] * q[i]).sum() }

fn main() {
    let x0: V = [0.0, 0.0, 0.05, 0.0];
    let e = series(T, 0);
    row("g/l, 1/l, rate; degrees 0.05, 0.5 rad", &[a(), c(), w(), 0.05f64.to_degrees(), 0.5f64.to_degrees()]);
    row("e^(At) at 0.5 s, tilt rows", &[e[2][2], e[2][3], e[3][2], e[3][3]]);
    row("  closed form cosh, sinh/4, 4 sinh", &[2f64.cosh(), 2f64.sinh() / 4.0, 4.0 * 2f64.sinh()]);
    let (free, per) = closed(T, &x0, 1.0, 1.0);
    row("free part (p, v, tilt, rate)", &free);
    row("forced part per 1 m/s^2", &per);
    let u = -free[2] / per[2];
    row("push u that zeroes tilt at 0.5 s", &[u, push_for(T, 0.05, L)]);
    let (fr, fo) = closed(T, &x0, u, 1.0);
    let r1 = add(&fr, &fo);
    let (r2, r3, r4) = (simpson(T, &x0, u), stepped(T, &x0, u), rk4(f_lin, u, T, &x0, 0.001));
    for (name, r) in [("1 closed form", r1), ("2 series + Simpson", r2), ("3 exact 100 Hz steps", r3), ("4 RK4, 1 ms", r4)] {
        row(name, &r);
    }
    for r in [r2, r3, r4] { assert!((0..4).all(|i| (r[i] - r1[i]).abs() < 1e-9)); }
    assert!((u - push_for(T, 0.05, L)).abs() < 1e-12);
    let y = dot(&C, &r1) + D * u;
    let (phi, gam) = (series(0.01, 0), mv(&series(0.01, 1), &bv()));
    row("encoder y at 0.5 s; hold push g*tilt", &[y, a() * 0.05 / c()]);
    row("one 0.01 s step: Phi tilt row, Gamma", &[phi[2][2], phi[2][3], gam[1], gam[2]]);
    let s = 5.0;
    let mut sia = [[0.0; 4]; 4];
    for i in 0..4 { for j in 0..4 { sia[i][j] = if i == j { s } else { 0.0 } - am()[i][j]; } }
    let gs = dot(&C, &solve(&sia, &bv())) + D;
    row("G(5): by (sI-A)^-1, by -c/(s^2-16)", &[gs, -c() / (s * s - 16.0)]);
    assert!((gs + c() / (s * s - 16.0)).abs() < 1e-12);
    let nl = rk4(f_non, u, T, &x0, 0.001);
    row("nonlinear rod, same push, 0.5 s", &nl);
    let big = rk4(f_non, push_for(T, 0.5, L), T, &[0.0, 0.0, 0.5, 0.0], 0.001);
    row("start 0.5 rad: linear push, rod tilt", &[push_for(T, 0.5, L), big[2], big[2].to_degrees()]);
    assert!(nl[2].abs() < 0.001 && big[2] > 0.1); // second road for both: the same runs at half the step
    assert!((rk4(f_non, u, T, &x0, 0.0005)[2] - nl[2]).abs() < 1e-6 && (rk4(f_non, push_for(T, 0.5, L), T, &[0.0, 0.0, 0.5, 0.0], 0.0005)[2] - big[2]).abs() < 1e-6);
    // ---- what breaks ----
    let (f2, p2) = closed(T, &x0, u, -1.0);
    let lump = mv(&e, &scale(u * T, &bv())); // all 0.5 s of push delivered as one kick at t = 0
    let mut ew = [[0.0; 4]; 4];
    for i in 0..4 { for j in 0..4 { ew[i][j] = (am()[i][j] * T).exp(); } }
    row("wrong: no convolution term", &[free[2]]);
    row("wrong: whole push as a kick at 0", &[free[2] + lump[2]]);
    row("wrong: e^(a_ij t) entry by entry", &[mv(&ew, &x0)[2]]);
    row("wrong: B sign flipped", &[f2[2] + p2[2]]);
    assert!((free[2] + lump[2] - r2[2]).abs() > 0.1 && (f2[2] + p2[2] - r4[2]).abs() > 0.1);
    // ---- how it moves, and the chart ----
    for tt in [0.1, 0.2, 0.3, 0.4, 0.5] {
        let (fr, fo) = closed(tt, &x0, u, 1.0);
        row(&format!("t={:.1}: free, forced, total tilt", tt), &[fr[2], fo[2], fr[2] + fo[2]]);
    }
    for (name, uu) in [("chart, motor off", 0.0), ("chart, hold push", a() * 0.05 / c()), ("chart, push u", u)] {
        let mut line = format!("{:<17}", name);
        for k in 0..11 {
            let (fr, fo) = closed(k as f64 / 10.0, &x0, uu, 1.0);
            line += &format!("{:>7.2}", fr[2] + fo[2]);
        }
        println!("{}", line);
    }
    // ---- try changing ----
    row("try: tilt 0.1; by 0.25 s; by 1 s", &[push_for(T, 0.1, L), push_for(0.25, 0.05, L), push_for(1.0, 0.05, L)]);
    row("try: rod 1.2 m", &[push_for(T, 0.05, 1.2)]);
    println!("ALL CHECKS PASS");
}
