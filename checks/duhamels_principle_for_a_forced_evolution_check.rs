// Duhamel's principle for a forced evolution -- the check behind the card.  std only.
// A room heated by a radiator on 06:00-07:00 and 09:00-12:00 (t = 0 is 06:00, t in hours).
// Rehearsal: one number u = temperature above 12 C, u' = -k u + q on(t).
// Profile: u(x, t) across a 4 m room, u' = kappa u'' + f, walls held at 12 C.
// Roads: Duhamel in closed form, a sum of nudges, RK4 and Crank-Nicolson steppers.
use std::f64::consts::PI;
const K: f64 = 0.5;
const Q: f64 = 5.0;
const U0: f64 = 4.0;
const BLOCKS: [(f64, f64); 2] = [(0.0, 1.0), (3.0, 6.0)];
const L: f64 = 4.0;
const KAP: f64 = 0.8;
const QR: f64 = 40.0;
const RA: f64 = 0.25;
const RB: f64 = 0.75;

fn close(a: f64, b: f64, tol: f64) {
    assert!((a - b).abs() <= tol, "{} {}", a, b);
}
// integral over [a, min(b, t)] of size e^(-rate (t - s)) ds
fn block_part(rate: f64, a: f64, b: f64, t: f64, size: f64) -> f64 {
    if t <= a {
        return 0.0;
    }
    let e = b.min(t);
    size / rate * ((-rate * (t - e)).exp() - (-rate * (t - a)).exp())
}
fn duhamel(t: f64) -> f64 {
    U0 * (-K * t).exp() + BLOCKS.iter().map(|&(a, b)| block_part(K, a, b, t, Q)).sum::<f64>()
}
fn on(s: f64) -> f64 {
    if BLOCKS.iter().any(|&(a, b)| a <= s && s < b) { 1.0 } else { 0.0 }
}
fn rk4(rate_of: &dyn Fn(f64) -> f64, steps: usize) -> f64 {
    let (dt, mut u) = (0.01, U0);
    for j in 0..steps {
        let s = (j as f64 + 0.5) * dt; // switches fall on step edges
        let (w, a) = (on(s) * Q, rate_of(s));
        let k1 = a * u + w;
        let k2 = a * (u + dt / 2.0 * k1) + w;
        let k3 = a * (u + dt / 2.0 * k2) + w;
        let k4 = a * (u + dt * k3) + w;
        u += dt / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
    }
    u
}
fn lam(n: usize) -> f64 { KAP * (n as f64 * PI / L).powi(2) }
fn qn(n: usize) -> f64 {
    let m = n as f64 * PI;
    2.0 * QR / m * ((m * RA / L).cos() - (m * RB / L).cos())
}
fn coef(n: usize, t: f64) -> f64 {
    let un0 = 2.0 * U0 / (n as f64 * PI) * (1.0 - (n as f64 * PI).cos());
    un0 * (-lam(n) * t).exp() + BLOCKS.iter().map(|&(a, b)| block_part(lam(n), a, b, t, qn(n))).sum::<f64>()
}
fn profile(x: f64, t: f64, nmax: usize) -> f64 {
    (1..=nmax).map(|n| coef(n, t) * (n as f64 * PI * x / L).sin()).sum()
}
fn join(v: &[f64], d: usize, add: f64) -> String {
    v.iter().map(|x| format!("{:.*}", d, x + add)).collect::<Vec<_>>().join(", ")
}

fn main() {
    // 1. The one-number room: the start and each heating block, carried forward to time t.
    println!("room, t (h), clock, start part, block 1, block 2, rise (C), temperature (C)");
    for t in 0..9 {
        let tf = t as f64;
        let (p0, p1, p2) = (U0 * (-K * tf).exp(), block_part(K, 0.0, 1.0, tf, Q), block_part(K, 3.0, 6.0, tf, Q));
        close(p0 + p1 + p2, rk4(&|_s| -K, 100 * t as usize), 1e-9); // against road three, hour by hour
        let s = p0 + p1 + p2;
        println!("room, {}, {:02}:00, {:.6}, {:.6}, {:.6}, {:.6}, {:.2}", t, 6 + t, p0, p1, p2, s, 12.0 + s);
    }
    let noon = duhamel(6.0);
    // Road two: add the nudges q on(s) ds slice by slice, each decayed by its age t - s (slice middle).
    println!("nudges, slice width ds (h), sum of nudges at noon, error");
    for (ds, lab) in [(0.5, "0.5"), (0.1, "0.1"), (0.01, "0.01"), (0.001, "0.001")] {
        let m = (6.0f64 / ds).round() as usize;
        let mut tot = U0 * (-K * 6.0f64).exp();
        for j in 0..m {
            let s = (j as f64 + 0.5) * ds;
            tot += (-K * (6.0 - s)).exp() * Q * on(s) * ds;
        }
        println!("nudges, {}, {:.6}, {:.9}", lab, tot, tot - noon);
        close(tot, noon, 0.2 * ds * ds); // midpoint slices: error falls like ds squared
    }
    // Road three: RK4 on u' = -k u + q on(t) itself, 0.01 h steps; rate and forcing fixed within a step.
    let r = rk4(&|_s| -K, 600);
    close(r, noon, 1e-9);
    close(noon, 4.0 * (-3.0f64).exp() + 10.0 * ((-2.5f64).exp() - (-3.0f64).exp()) + 10.0 * (1.0 - (-1.5f64).exp()), 1e-12);
    println!("room at noon, Duhamel {:.6}, RK4 {:.6}, temperature {:.2} C", noon, r, 12.0 + noon);
    let temps: Vec<f64> = (0..17).map(|j| duhamel(j as f64 / 2.0)).collect();
    let target: Vec<f64> = (0..17).map(|j| 10.0 * on(j as f64 / 2.0)).collect();
    println!("chart, temperature every half hour, {}", join(&temps, 2, 12.0));
    println!("chart, target, {}", join(&target, 0, 12.0));

    // 2. The profile: sine modes sin(n pi x / L) diagonalise the flow; mode n decays at lam_n.
    println!("flow, mode 1 decays at {:.6} per hour, mode 10 at {:.6} per hour", lam(1), lam(10));
    let xs = [0.5, 2.0, 3.5];
    let reference: Vec<f64> = xs.iter().map(|&x| profile(x, 6.0, 20000)).collect();
    println!("modes, N, error at 0.5 m, at 2.0 m, at 3.5 m (C, against N = 20000)");
    let mut err10 = 0.0;
    for nmax in [10, 40, 160, 640] {
        let err: Vec<f64> = xs.iter().zip(&reference).map(|(&x, &v)| profile(x, 6.0, nmax) - v).collect();
        println!("modes, {}, {}", nmax, join(&err, 9, 0.0));
        if nmax == 10 {
            err10 = err[0];
        }
    }
    assert!(err10.abs() > 0.05 && (profile(0.5, 6.0, 640) - reference[0]).abs() < 1e-5);
    // Crank-Nicolson on M cells: (I - dt/2 A) u_new = (I + dt/2 A) u + dt f, solved by the Thomas sweep.
    let (m, dt) = (160usize, 0.01);
    let h = L / m as f64;
    let mut u = vec![U0; m + 1];
    u[0] = 0.0;
    u[m] = 0.0;
    let src: Vec<f64> = (0..=m).map(|j| {
        let x = j as f64 * h;
        QR * if RA < x && x < RB { 1.0 } else if (x - RA).abs() < 1e-9 || (x - RB).abs() < 1e-9 { 0.5 } else { 0.0 }
    }).collect();
    let c = KAP * dt / (2.0 * h * h);
    for step in 0..600 {
        let w = on((step as f64 + 0.5) * dt);
        let rhs: Vec<f64> = (1..m).map(|j| u[j] + c * (u[j - 1] - 2.0 * u[j] + u[j + 1]) + dt * w * src[j]).collect();
        let (mut cp, mut dp) = (vec![0.0; m - 1], vec![0.0; m - 1]);
        for i in 0..m - 1 {
            let den = (1.0 + 2.0 * c) + if i > 0 { c * cp[i - 1] } else { 0.0 };
            cp[i] = -c / den;
            dp[i] = (rhs[i] + if i > 0 { c * dp[i - 1] } else { 0.0 }) / den;
        }
        for i in (0..m - 1).rev() {
            u[i + 1] = dp[i] - if i < m - 2 { cp[i] * u[i + 2] } else { 0.0 };
        }
    }
    let cn: Vec<f64> = xs.iter().map(|&x| u[(x / h).round() as usize]).collect();
    for (a, b) in cn.iter().zip(&reference) {
        close(*a, *b, 2e-3);
    }
    println!("profile at noon (C), x = 0.5 m, 2.0 m, 3.5 m: modes {}; Crank-Nicolson {}", join(&reference, 3, 12.0), join(&cn, 3, 12.0));
    // The forcing is not in the domain D(A); the mild solution at noon is.  Sizes as RMS over the room.
    println!("domain, N, RMS of A f_N (C/h^2), RMS of A u_N at noon (C/h)");
    let (mut aq, mut au) = (0.0, 0.0);
    for nmax in [10, 100, 1000, 10000] {
        aq = (0.5 * (1..=nmax).map(|n| (lam(n) * qn(n)).powi(2)).sum::<f64>()).sqrt();
        au = (0.5 * (1..=nmax).map(|n| (lam(n) * coef(n, 6.0)).powi(2)).sum::<f64>()).sqrt();
        println!("domain, {}, {:.3}, {:.6}", nmax, aq, au);
    }
    assert!(aq > 1e5 && au < 30.0);

    // 3. What breaks.
    let wrong_age = U0 * (-K * 6.0f64).exp() + BLOCKS.iter().map(|&(a, b)| Q / K * ((-K * a).exp() - (-K * b).exp())).sum::<f64>();
    close(wrong_age, 4.0 * (-3.0f64).exp() + 10.0 * (1.0 - (-0.5f64).exp()) + 10.0 * ((-1.5f64).exp() - (-3.0f64).exp()), 1e-12);
    println!("breaks, carry each nudge by its arrival time s, not its age: {:.2} C, true {:.2} C", 12.0 + wrong_age, 12.0 + noon);
    println!("breaks, add the nudges with no decay: {:.2} C", 12.0 + U0 + Q * 4.0);
    println!("breaks, drop the start term: {:.2} C", 12.0 + noon - U0 * (-3.0f64).exp());
    let win = rk4(&|s| if (1.0..3.0).contains(&s) { -1.5 } else { -K }, 600); // window open 07:00-09:00 triples the loss rate
    let step_by_step = duhamel(1.0) * (-3.0f64).exp() * (-1.5f64).exp() + block_part(K, 3.0, 6.0, 6.0, Q);
    close(win, step_by_step, 1e-9);
    println!("breaks, window open 07:00-09:00, one fixed flow: {:.2} C, true {:.2} C", 12.0 + noon, 12.0 + win);
    println!("breaks, 10 modes at the radiator: off by {:.3} C", err10);
    println!("ALL CHECKS PASS");
}
