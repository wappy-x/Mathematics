// Linearisation about an equilibrium -- the check behind the card.  std only, no crates.
// Road 1: the slopes (Jacobians) written out by hand.  Road 2: the same slopes by nudging
// the curved model.  Road 3: the curved model stepped by RK4 against the straight one.
use std::f64::consts::PI;
const G: f64 = 9.81;
const L: f64 = 0.613125; // gravity m/s^2; pole length m, so G/L = 16 per s^2

fn f(x: &[f64; 4], u: f64) -> [f64; 4] { // curved model: state (p, v, th, w), input u = cart accel
    [x[1], u, x[3], (G * x[2].sin() - u * x[2].cos()) / L]
}
fn h(x: &[f64; 4]) -> [f64; 2] { [x[2], x[0] + L * x[2].sin()] } // encoder angle; tip position

type M4 = [[f64; 4]; 4];
type M2 = [[f64; 4]; 2];
fn by_hand(te: f64) -> (f64, M4, [f64; 4], M2) { // Road 1, at lean te held by ue = G tan te
    let ue = G * te.tan();
    let mut a = [[0.0; 4]; 4];
    a[0][1] = 1.0; a[2][3] = 1.0; a[3][2] = (G * te.cos() + ue * te.sin()) / L;
    (ue, a, [0.0, 1.0, 0.0, -te.cos() / L], [[0.0, 0.0, 1.0, 0.0], [1.0, 0.0, L * te.cos(), 0.0]])
}
fn by_nudge(te: f64) -> (M4, [f64; 4], M2) { // Road 2: central differences
    let e = 1e-6;
    let (xe, ue) = ([0.0, 0.0, te, 0.0], G * te.tan());
    let (mut a, mut c) = ([[0.0; 4]; 4], [[0.0; 4]; 2]);
    for j in 0..4 {
        let (mut xp, mut xm) = (xe, xe);
        xp[j] += e; xm[j] -= e;
        for i in 0..4 { a[i][j] = (f(&xp, ue)[i] - f(&xm, ue)[i]) / (2.0 * e); }
        for i in 0..2 { c[i][j] = (h(&xp)[i] - h(&xm)[i]) / (2.0 * e); }
    }
    let (fp, fm) = (f(&xe, ue + e), f(&xe, ue - e));
    let mut b = [0.0; 4];
    for i in 0..4 { b[i] = (fp[i] - fm[i]) / (2.0 * e); }
    (a, b, c)
}
fn gap(p: &[[f64; 4]], q: &[[f64; 4]]) -> f64 {
    let mut g: f64 = 0.0;
    for (r, s) in p.iter().zip(q) { for k in 0..4 { g = g.max((r[k] - s[k]).abs()); } }
    g
}
fn fmt(v: &[f64]) -> String { v.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(" ") }

fn rk4(rate: &dyn Fn([f64; 2]) -> [f64; 2], mut y: [f64; 2], dt: f64, n: usize) -> [f64; 2] {
    let add = |y: [f64; 2], k: [f64; 2], s: f64| [y[0] + s * k[0], y[1] + s * k[1]];
    for _ in 0..n {
        let k1 = rate(y); let k2 = rate(add(y, k1, dt / 2.0));
        let k3 = rate(add(y, k2, dt / 2.0)); let k4 = rate(add(y, k3, dt));
        for i in 0..2 { y[i] += dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    y
}
fn curved(u: impl Fn([f64; 2]) -> f64) -> impl Fn([f64; 2]) -> [f64; 2] {
    move |y| [y[1], (G * y[0].sin() - u(y) * y[0].cos()) / L]
}
fn straight(a: f64) -> impl Fn([f64; 2]) -> [f64; 2] { move |y| [y[1], a * y[0]] } // input held at ue
fn rule(y: [f64; 2]) -> f64 { L * (32.0 * y[0] + 8.0 * y[1]) } // u = L (32 th + 8 w), poles -4, -4
fn root(k: f64, hi: f64) -> f64 { // where tan th = k th
    let (mut a, mut b) = (0.5, hi);
    for _ in 0..60 { let m = (a + b) / 2.0; if m.tan() < k * m { a = m } else { b = m } }
    a
}

fn main() {
    // ---- the upright operating point ----
    let (_, a, b, c) = by_hand(0.0);
    let (an, bn, cn) = by_nudge(0.0);
    println!("equilibrium: rates at upright, u = 0: {}", fmt(&f(&[0.0; 4], 0.0)));
    println!("A row 4 by hand {} | by nudging {}", fmt(&a[3]), fmt(&an[3]));
    println!("B by hand {} | by nudging {}", fmt(&b), fmt(&bn));
    println!("C by hand {} / {} | D = 0", fmt(&c[0]), fmt(&c[1]));
    println!("eigenvalues 0, 0, +-{:.4} per s; doubling ln2/4 = {:.4} s", a[3][2].sqrt(), 2f64.ln() / a[3][2].sqrt());
    assert!(gap(&a, &an) < 1e-6 && gap(&[b], &[bn]) < 1e-6 && gap(&c, &cn) < 1e-6);

    // ---- the leaning operating point, held by a steady push ----
    let te = 0.3;
    let (ue, al, bl, cl) = by_hand(te);
    let (aln, bln, cln) = by_nudge(te);
    println!("lean {:.1} rad ({:.2} deg): ue = {:.4} m/s^2; lean rates there {}", te, te * 180.0 / PI, ue, fmt(&f(&[0.0, 0.0, te, 0.0], ue)[2..]));
    println!("lean: a = {:.4} per s^2 (16/cos 0.3 = {:.4}), b = {:.4}, C tip row {}, growth {:.4} per s",
             al[3][2], 16.0 / te.cos(), bl[3], fmt(&cl[1]), al[3][2].sqrt());
    assert!(gap(&al, &aln) < 1e-6 && (bl[3] - bln[3]).abs() < 1e-6 && (al[3][2] - 16.0 / te.cos()).abs() < 1e-9 && gap(&cl, &cln) < 1e-6);
    let gt = (G * G + ue * ue).sqrt();
    println!("tilted gravity sqrt(g^2 + ue^2) = {:.4} m/s^2, over L = {:.4} per s^2", gt, gt / L);
    for t in [0.1f64, 0.5] {
        println!("straight model off at {:.1} rad: gravity term {:.2}%, motor term {:.2}%", t, 100.0 * (1.0 - t.sin() / t), 100.0 * (1.0 - t.cos()));
    }

    // ---- road 3: let go with the motor off; straight versus curved ----
    let off = |_: [f64; 2]| 0.0;
    let lin = rk4(&straight(16.0), [0.001, 0.0], 0.001, 1000)[0];
    let tru = rk4(&curved(off), [0.001, 0.0], 0.001, 1000)[0];
    println!("from 1 mrad, at 1 s: cosh {:.4} mrad, straight RK4 {:.4}, curved RK4 {:.4}", 4f64.cosh(), 1000.0 * lin, 1000.0 * tru);
    assert!((lin - 0.001 * 4f64.cosh()).abs() < 1e-9);
    let (mut y, mut tc) = ([0.05, 0.0], 0.0);
    while y[0] < 0.5 { y = rk4(&curved(off), y, 1e-4, 1); tc += 1e-4; }
    println!("from 0.05 rad to 0.5 rad: straight acosh(10)/4 = {:.4} s, curved {:.4} s", 10f64.acosh() / 4.0, tc);

    let err = |te0: f64, a: f64, u0: f64, d: f64| { // curved minus straight at 0.5 s
        let yc = rk4(&curved(move |_| u0), [te0 + d, 0.0], 0.001, 500);
        let ys = rk4(&straight(a), [d, 0.0], 0.001, 500);
        (yc[0] - te0 - ys[0]).abs()
    };
    let (e1, e2) = (err(0.0, 16.0, 0.0, 0.02), err(0.0, 16.0, 0.0, 0.01));
    let (g1, g2) = (err(te, al[3][2], ue, 0.02), err(te, al[3][2], ue, 0.01));
    println!("error at 0.5 s in microrad, start 0.02 vs 0.01 rad: upright {:.3} {:.3} ratio {:.2} | lean {:.3} {:.3} ratio {:.2}",
             1e6 * e1, 1e6 * e2, e1 / e2, 1e6 * g1, 1e6 * g2, g1 / g2);
    assert!(7.5 < e1 / e2 && e1 / e2 < 8.5 && 7.5 < g1 / g2 && g1 / g2 < 8.5); // leftover is cubic at both points

    // ---- the balancing rule designed on the straight model, run on the curved one ----
    let caught = |t0: f64| {
        let mut y = [t0, 0.0];
        for _ in 0..1000 { y = rk4(&curved(rule), y, 0.005, 1); if y[0].abs() > PI / 2.0 { return false; } }
        y[0].abs() < 0.01
    };
    let (mut lo, mut hi) = (0.5, 1.5);
    for _ in 0..30 { let m = (lo + hi) / 2.0; if caught(m) { lo = m } else { hi = m } }
    let r2 = root(2.0, 1.5); // independent road: where 16 sin th = 32 th cos th
    println!("largest lean caught: by simulation {:.4} rad ({:.1} deg), root of tan th = 2 th {:.4} rad", lo, lo * 180.0 / PI, r2);
    assert!((lo - r2).abs() < 1e-3);
    let s = rk4(&curved(rule), [0.3, 0.0], 0.005, 200)[0];
    println!("from 0.3 rad at 1 s: straight 0.3(1+4t)e^-4t = {:.5} rad, curved {:.5} rad", 0.3 * 5.0 * (-4f64).exp(), s);

    let ts = [0.3f64, 0.6, 0.9, 1.2];
    println!("bars, th 0.3 0.6 0.9 1.2: gravity 16 sin th {} | rule 32 th cos th {}",
             fmt(&ts.map(|t| 16.0 * t.sin())), fmt(&ts.map(|t| 32.0 * t * t.cos())));
    // ---- what breaks ----
    println!("wrong: absolute th, u in the lean model: rate at the held point {:.4} rad/s^2", al[3][2] * te + bl[3] * ue);
    println!("wrong: upright model used at the lean: a {:.4} vs {:.4}, b {:.4} vs {:.4}", a[3][2], al[3][2], b[3], bl[3]);
    println!("wrong: motor grip at the lean is {:.2}% weaker; lean in degrees: B entry x {:.2} = {:.2}, eigenvalues still +-{:.4}",
             100.0 * (1.0 - bl[3] / b[3]), 180.0 / PI, b[3] * 180.0 / PI, a[3][2].sqrt());
    println!("wrong: slopes taken at 0.3 rad with u = 0, not a rest: lean rate {:.4} rad/s^2", 16.0 * te.sin());

    // ---- try changing ----
    println!("try: L = 1.0 m: growth {:.4} per s, doubling {:.4} s", G.sqrt(), 2f64.ln() / G.sqrt());
    println!("try: lean 0.6 rad: ue {:.4} m/s^2, a {:.4}, b {:.4}", G * 0.6f64.tan(), 16.0 / 0.6f64.cos(), -0.6f64.cos() / L);
    let r4 = root(4.0, 1.55);
    println!("try: gains doubled (64, 16): largest lean caught {:.4} rad ({:.1} deg)", r4, r4 * 180.0 / PI);

    // ---- chart points ----
    let ks: Vec<f64> = (0..17).step_by(2).map(|k| k as f64 / 10.0).collect();
    println!("chart, th rad:         {}", ks.iter().map(|t| format!("{:.1}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, 16 sin th:      {}", ks.iter().map(|t| format!("{:.2}", 16.0 * t.sin())).collect::<Vec<_>>().join(" "));
    println!("chart, 16 th:          {}", ks.iter().map(|t| format!("{:.2}", 16.0 * t)).collect::<Vec<_>>().join(" "));
    for t0 in [1.0, 1.2] {
        let (mut y, mut row) = ([t0, 0.0], vec![format!("{:.3}", t0)]);
        for _ in 0..10 { y = rk4(&curved(rule), y, 0.005, 20); row.push(format!("{:.3}", y[0].min(PI / 2.0))); }
        println!("chart, curved from {:.1}: {}", t0, row.join(" "));
    }
    let st: Vec<String> = (0..11).map(|k| { let t = 0.4 * k as f64; format!("{:.3}", (1.0 + t) * (-t).exp()) }).collect();
    println!("chart, straight 1.0:   {}", st.join(" "));
    println!("ALL CHECKS PASS");
}
