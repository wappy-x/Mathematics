// Ricci flow on a dumbbell surface -- the check behind the card.  Rust std only.
// The metric is g = e^(2u) (round unit sphere), u a function of the polar angle phi.
// On a surface Ric = K g, so the flow dg/dt = -2 Ric is du/dt = -K, stepped on a grid.
use std::f64::consts::PI;
const R: f64 = 2.0; // two balls of radius 2 cm, joined; D sets the neck
const D: f64 = 2.0;
fn rho_x(x: f64) -> f64 { R / (x - D).cosh() + R / (x + D).cosh() }
fn k_x(x: f64) -> f64 { // Gaussian curvature of the exact profile, -rho''/rho in arc length
    let (a, b) = (1.0 / (x - D).cosh(), 1.0 / (x + D).cosh());
    let r = R * (a + b);
    let r1 = -R * (a * (x - D).tanh() + b * (x + D).tanh());
    let r2 = R * (a * (1.0 - 2.0 * a * a) + b * (1.0 - 2.0 * b * b));
    -(r2 / r - (r1 / r) * (r1 / r)) / (r * r)
}
fn neck_rates(d: f64) -> (f64, f64, f64, f64) { // neck radius, K, d(rho^2)/dt in 2D and 3D
    let q = 2.0 * R / d.cosh();
    let r2 = q * q;
    let k = -(1.0 - r2 / (2.0 * R * R)) / r2;
    (r2.sqrt(), k, -2.0 * r2 * k, -2.0 * r2 * (k + 1.0 / r2))
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 { // road 1: the exact profile
    let n = 6000;
    let h = (hi - lo) / n as f64;
    let mut acc = 0.0;
    for i in 1..n {
        acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h);
    }
    (f(lo) + f(hi) + acc) * h / 3.0
}
struct Grid { h: f64, phi: Vec<f64>, w: Vec<f64>, f: Vec<f64>, u: Vec<f64> }
fn grid(n: usize, u0: Option<f64>) -> Grid { // road 2: n cells in phi, each of exact weight w
    let h = PI / n as f64;
    let phi: Vec<f64> = (0..n).map(|i| (i as f64 + 0.5) * h).collect();
    let w = (0..n).map(|i| (i as f64 * h).cos() - ((i + 1) as f64 * h).cos()).collect();
    let f = (0..=n).map(|i| (i as f64 * h).sin() / h).collect(); // zero at both poles
    let u = phi.iter().map(|&p| match u0 {
        None => (rho_x((p / 2.0).tan().ln()) / p.sin()).ln(),
        Some(c) => c,
    }).collect();
    Grid { h, phi, w, f, u }
}
fn curv(g: &Grid) -> Vec<f64> { // K = e^(-2u) (1 - Laplacian_round u), cell by cell
    let n = g.u.len();
    (0..n).map(|i| {
        let up = if i < n - 1 { g.f[i + 1] * (g.u[i + 1] - g.u[i]) } else { 0.0 };
        let dn = if i > 0 { g.f[i] * (g.u[i] - g.u[i - 1]) } else { 0.0 };
        (-2.0 * g.u[i]).exp() * (1.0 - (up - dn) / g.w[i])
    }).collect()
}
fn area(g: &Grid) -> f64 {
    let mut s = 0.0;
    for i in 0..g.u.len() { s += (2.0 * g.u[i]).exp() * g.w[i]; }
    2.0 * PI * s
}
fn flow(mut g: Grid, tt: f64, norm: bool, c: f64) -> Grid { // dg/dt = -c Ric; norm keeps the area
    let mut t = 0.0;
    while tt - t > 1e-12 {
        let k = curv(&g);
        let umin = g.u.iter().cloned().fold(f64::INFINITY, f64::min);
        let dt = (0.2 * g.h * g.h * (2.0 * umin).exp()).min(tt - t);
        let kbar = if norm { 4.0 * PI / area(&g) } else { 0.0 };
        for i in 0..g.u.len() { g.u[i] = g.u[i] + dt * (c / 2.0) * (kbar - k[i]); }
        t += dt;
    }
    g
}
fn neck(g: &Grid) -> f64 { let m = g.u.len() / 2; ((g.u[m - 1] + g.u[m]) / 2.0).exp() }
fn shape(g: &Grid) -> (f64, f64, f64) { // pole-to-pole length, widest radius, roundness
    let mut l = 0.0;
    for a in &g.u { l += a.exp(); }
    l = g.h * l;
    let wide = (0..g.u.len()).map(|i| g.u[i].exp() * g.phi[i].sin()).fold(f64::NEG_INFINITY, f64::max);
    (l, wide, l / (PI * wide))
}
fn profile(g: &Grid) -> Vec<f64> { // circle radius at each tenth of the way from pole to pole
    let (mut s, mut acc) = (vec![0.0], 0.0);
    for a in &g.u { s.push(acc + g.h * a.exp() / 2.0); acc += g.h * a.exp(); }
    s.push(acc);
    let mut r = vec![0.0];
    for i in 0..g.u.len() { r.push(g.u[i].exp() * g.phi[i].sin()); }
    r.push(0.0);
    let (mut out, mut j) = (vec![], 0);
    for q in 0..=10 {
        let x = acc * q as f64 / 10.0;
        while j < s.len() - 2 && s[j + 1] < x { j += 1; }
        out.push(r[j] + (r[j + 1] - r[j]) * (x - s[j]) / (s[j + 1] - s[j]));
    }
    out
}
fn show(label: &str, v: f64) { println!("{:<44} {:12.6}", label, v); }
fn kmin(k: &[f64]) -> f64 { k.iter().cloned().fold(f64::INFINITY, f64::min) }
fn kmax(k: &[f64]) -> f64 { k.iter().cloned().fold(f64::NEG_INFINITY, f64::max) }
fn main() {
    // ---- the surface before the flow ----
    let a_ex = simpson(&|x| 2.0 * PI * (rho_x(x) * rho_x(x)), -40.0, 40.0);
    let l_ex = simpson(&rho_x, -40.0, 40.0);
    let gb = simpson(&|x| 2.0 * PI * k_x(x) * (rho_x(x) * rho_x(x)), -40.0, 40.0);
    let chi = 6.0 - 12.0 + 8.0; // octahedron: vertices - edges + faces
    let (rho0, k0, rate2, rate3) = neck_rates(D);
    show("area, exact profile (cm^2)", a_ex); show("pole-to-pole length (cm)", l_ex);
    show("neck radius (cm)", rho0);
    show("bulb radius, widest (cm)", (0..400).map(|i| rho_x(i as f64 / 100.0)).fold(f64::NEG_INFINITY, f64::max));
    show("total curvature, integral of K dA", gb); show("2 pi chi, chi = 6 - 12 + 8", 2.0 * PI * chi);
    show("neck K, closed form (1/cm^2)", k0);
    show("cosh D", D.cosh()); show("neck radius squared (cm^2)", rho0 * rho0);
    show("rho^2 / (2 R^2)", rho0 * rho0 / (2.0 * R * R)); show("area lost per unit time, 8 pi (cm^2)", 8.0 * PI);
    let (g60, g120) = (grid(60, None), grid(120, None));
    for (n, g) in [(60, &g60), (120, &g120)] {
        let kg = curv(g);
        show(&format!("N={}: area (cm^2)", n), area(g));
        show(&format!("N={}: neck K (1/cm^2)", n), (kg[n / 2 - 1] + kg[n / 2]) / 2.0);
    }
    let a0 = area(&g120);
    // ---- the neck in 2D and in 3D: same profile, d(rho^2)/dt at the neck ----
    let early = flow(grid(120, None), 0.001, false, 2.0);
    let rate_sim = (neck(&early) * neck(&early) - neck(&g120) * neck(&g120)) / 0.001;
    show("2D neck, d(rho^2)/dt, formula", rate2); show("2D neck, d(rho^2)/dt, flow to t=0.001", rate_sim);
    show("3D neck, same profile, d(rho^2)/dt", rate3);
    show("3D thin neck rho=0.5: pinch time (cm^2)", 0.5 * 0.5 / 2.0); show("3D ball R=2: vanishing time (cm^2)", R * R / 4.0);
    show("3D dumbbell neck at its start rate: t (cm^2)", rho0 * rho0 / -rate3);
    // ---- the true flow: area falls by 8 pi per unit time, whatever the shape ----
    let ball = flow(grid(120, Some(R.ln())), 1.0, false, 2.0);
    show("round ball R=2 at t=1: radius^2, flow", (2.0 * ball.u[0]).exp()); show("  closed form R^2 - 2t", R * R - 2.0);
    let mut st = grid(120, None);
    println!("t     area        A0 - 8 pi t   neck radius");
    for t in 1..=3 {
        st = flow(st, 1.0, false, 2.0);
        println!("{}  {:11.6} {:11.6} {:11.6}", t, area(&st), a0 - 8.0 * PI * t as f64, neck(&st));
    }
    show("vanishing time A0 / (8 pi) (cm^2)", a0 / (8.0 * PI)); show("  exact area: A / (8 pi) (cm^2)", a_ex / (8.0 * PI));
    // ---- the normalised flow: same area, watch the shape go round ----
    println!("t   neck rho  widest    K min     K max   roundness");
    let (mut st, mut prof, mut done) = (grid(120, None), vec![], 0);
    for t in [0, 1, 2, 5, 10, 20, 40] {
        st = flow(st, (t - done) as f64, true, 2.0); done = t;
        let (k, (_, wide, rnd)) = (curv(&st), shape(&st));
        println!("{:<3} {:8.4} {:8.4} {:8.5} {:8.5} {:8.5}", t, neck(&st), wide, kmin(&k), kmax(&k), rnd);
        if t == 0 || t == 2 || t == 40 { prof.push((t, profile(&st))); }
    }
    for (t, p) in &prof {
        let v: Vec<String> = p.iter().map(|x| format!("{:.2}", x)).collect();
        println!("chart t={:<2} {}", t, v.join(", "));
    }
    show("round limit: radius sqrt(A/4pi) (cm)", (area(&st) / (4.0 * PI)).sqrt());
    show("round limit: K = 4 pi / A (1/cm^2)", 4.0 * PI / area(&st)); show("  exact area: radius sqrt(A/4pi) (cm)", (a_ex / (4.0 * PI)).sqrt());
    let lo = flow(grid(60, None), 40.0, true, 2.0);
    show("N=60 at t=40: roundness", shape(&lo).2);
    // ---- what breaks ----
    show("drop the 2: area at t=1 (cm^2)", area(&flow(grid(120, None), 1.0, false, 1.0)));
    let flip = flow(grid(60, Some(R.ln())), 1.0, false, -2.0).u[0].exp();
    show("flip the sign: ball R=2 radius at t=1", flip); show("  closed form sqrt(R^2 + 2t)", (R * R + 2.0).sqrt());
    show("3D rule on the surface: pinch t (cm^2)", rho0 * rho0 / 2.0);
    for d in [1.5, 2.5] { // try changing: a fatter and a thinner neck
        let (r, k, a, b) = neck_rates(d);
        println!("try D={}: neck {:.6} cm, K {:.6}, 2D rate {:.6}, 3D rate {:.6}", d, r, k, a, b);
    }
    assert!((gb - 2.0 * PI * chi).abs() < 1e-6); // Gauss-Bonnet: integral against a count
    assert!((area(&g120) - a_ex).abs() < (area(&g60) - a_ex).abs() && (area(&g60) - a_ex).abs() < 1.0);
    let kg = curv(&g120);
    assert!(((kg[59] + kg[60]) / 2.0 - k0).abs() < 2e-3);
    assert!((rate_sim - rate2).abs() < 0.02); // neck rate: closed form against the flow
    assert!(rate3 < 0.0 && 0.0 < rate2); // widens in 2D, shrinks in 3D
    assert!(((2.0 * ball.u[0]).exp() - (R * R - 2.0)).abs() < 1e-3);
    assert!((area(&flow(grid(120, None), 1.0, false, 2.0)) - (a0 - 8.0 * PI)).abs() < 0.01);
    let kf = curv(&st);
    assert!(shape(&st).2 < 1.001 && kmax(&kf) / kmin(&kf) < 1.0001);
    assert!((area(&st) - a0).abs() < 0.05); // the normalised flow keeps the area
    assert!((shape(&st).1 - (a0 / (4.0 * PI)).sqrt()).abs() < 2e-3 && (flip - (R * R + 2.0).sqrt()).abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
