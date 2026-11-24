// Hopf bifurcation -- the same check as the Python, in Rust, std only.  Normal forms
// r' = mu r + a r^3 (+ ...), and the Brusselator x' = 1 - (B + 1) x + x^2 y, y' = B x - x^2 y.
type V = Vec<f64>;
fn rk4(f: &dyn Fn(&V) -> V, s0: &V, dt: f64, n: usize) -> V { // n Runge-Kutta 4 steps of s' = f(s)
    let mut s = s0.clone();
    let add = |a: &V, b: &V, h: f64| -> V { a.iter().zip(b).map(|(x, y)| x + h * y).collect() };
    for _ in 0..n {
        let k1 = f(&s); let k2 = f(&add(&s, &k1, dt / 2.0)); let k3 = f(&add(&s, &k2, dt / 2.0)); let k4 = f(&add(&s, &k3, dt));
        s = (0..s.len()).map(|i| s[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    s
}
fn sup(mu: f64) -> impl Fn(&V) -> V { move |s: &V| vec![mu * s[0] - s[0].powi(3)] } // r' = mu r - r^3
fn sub(mu: f64) -> impl Fn(&V) -> V { move |s: &V| vec![mu * s[0] + s[0].powi(3) - s[0].powi(5)] }
fn plane(mu: f64) -> impl Fn(&V) -> V {
    move |s: &V| { let q = s[0] * s[0] + s[1] * s[1]; vec![mu * s[0] - s[1] - s[0] * q, s[0] + mu * s[1] - s[1] * q] }
}
fn big(mu: f64) -> f64 { ((1.0 + (1.0 + 4.0 * mu).sqrt()) / 2.0).sqrt() }
fn small(mu: f64) -> f64 { ((1.0 - (1.0 + 4.0 * mu).sqrt()) / 2.0).sqrt() }
fn bf(b: f64) -> impl Fn(&V) -> V { move |s: &V| vec![1.0 - (b + 1.0) * s[0] + s[0] * s[0] * s[1], b * s[0] - s[0] * s[0] * s[1]] }
fn fg(u: f64, w: f64) -> [f64; 2] { // nonlinear parts in u = x - 1, w = -(u + y - 2), at B = 2: u' = -w + f, w' = u + g
    let d = bf(2.0)(&vec![1.0 + u, 2.0 - w - u]); [d[0] + w, -(d[0] + d[1]) - u]
}
fn dd(k: usize, ax: &[usize], p: (f64, f64)) -> f64 { // nested central differences: exact for cubics
    if ax.is_empty() { return fg(p.0, p.1)[k]; }
    let h = 0.01; let e = if ax[0] == 0 { (h, 0.0) } else { (0.0, h) };
    (dd(k, &ax[1..], (p.0 + e.0, p.1 + e.1)) - dd(k, &ax[1..], (p.0 - e.0, p.1 - e.1))) / (2.0 * h)
}
fn main() {
    let (r1, r2, xy) = (rk4(&sup(0.04), &vec![0.01], 0.05, 8000)[0], rk4(&sup(0.04), &vec![0.5], 0.05, 8000)[0], rk4(&plane(0.04), &vec![0.01, 0.0], 0.05, 8000));
    let rxy = (xy[0] * xy[0] + xy[1] * xy[1]).sqrt();
    println!("super mu 0.04: radius sqrt(mu) {:.4}; RK4 from 0.01 {:.4}, from 0.5 {:.4}; x-y plane {:.4}", 0.04f64.sqrt(), r1, r2, rxy);
    assert!((r1 - 0.2).abs() < 1e-6 && (r2 - 0.2).abs() < 1e-6 && (rxy - 0.2).abs() < 1e-6);
    let (lin, r150) = (0.01 * (0.04f64 * 150.0).exp(), rk4(&sup(0.04), &vec![0.01], 0.05, 3000)[0]);
    println!("super mu 0.04 from 0.01 at t 150: linear guess {:.4}, true {:.4}; mu 0 at t 1000 from 0.2: {:.4} (1/sqrt(25 + 2000) = {:.4})",
             lin, r150, rk4(&sup(0.0), &vec![0.2], 0.05, 20000)[0], 1.0 / 2025f64.sqrt());
    println!("sub: big cycle at mu 0 {:.4}, at 0.04 {:.4}, at -0.10 {:.4}, at -0.25 {:.4}; small unstable at -0.04 {:.4}",
             big(0.0), big(0.04), big(-0.1), big(-0.25), small(-0.04));
    for mu in [-0.1, -0.04] { // both cycles are rests of r' found by RK4: start just off each
        assert!((rk4(&sub(mu), &vec![big(mu) + 0.05], 0.05, 4000)[0] - big(mu)).abs() < 1e-6 && rk4(&sub(mu), &vec![small(mu) - 0.01], 0.05, 4000)[0] < 1e-3);
    }
    let mus: Vec<f64> = (0..21).map(|i| ((-0.30 + 0.02 * i as f64) * 100.0).round() / 100.0).collect();
    let (mut r, mut up, mut down) = (0.0f64, vec![], vec![]);
    for &mu in &mus { r = rk4(&sub(mu), &vec![r.max(0.01)], 0.05, 20000)[0]; up.push(r); } // settle 1000 time units; noise floor 0.01
    for &mu in mus.iter().rev() { r = rk4(&sub(mu), &vec![r.max(0.01)], 0.05, 20000)[0]; down.push(r); }
    down.reverse();
    let sq: V = mus.iter().map(|m| m.max(0.0).sqrt()).collect();
    for (name, row) in [("mu", &mus), ("sweep up", &up), ("sweep down", &down), ("super sqrt(mu)", &sq)] {
        println!("chart {}: {}", name, row.iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    }
    let jump = mus.iter().zip(&up).filter(|(_, v)| **v > 0.5).map(|(m, _)| *m).fold(f64::MAX, f64::min);
    let drop = mus.iter().zip(&down).filter(|(_, v)| **v < 0.5).map(|(m, _)| *m).fold(f64::MIN, f64::max);
    println!("hysteresis: up-sweep jumps at mu {:.2}, down-sweep drops at mu {:.2}", jump, drop);
    assert!(jump == 0.02 && drop == -0.26 && mus.iter().zip(&down).all(|(m, v)| *m <= -0.25 || (v - big(*m)).abs() < 1e-3));
    let f = |ax: &[usize]| dd(0, ax, (0.0, 0.0)); let g = |ax: &[usize]| dd(1, ax, (0.0, 0.0)); // f_uw is f(&[0, 1])
    let cubic = f(&[0, 0, 0]) + f(&[0, 1, 1]) + g(&[0, 0, 1]) + g(&[1, 1, 1]);
    let quad = f(&[0, 1]) * (f(&[0, 0]) + f(&[1, 1])) - g(&[0, 1]) * (g(&[0, 0]) + g(&[1, 1])) - f(&[0, 0]) * g(&[0, 0]) + f(&[1, 1]) * g(&[1, 1]);
    let a = (cubic + quad) / 16.0;
    println!("Brusselator B 2: f_uuu {:.3}, f_uw {:.3}, others 0; 16a = {:.3} + {:.3}; a = {:.4}", f(&[0, 0, 0]), f(&[0, 1]), cubic, quad, a);
    let (mut s, mut t, mut laps, dt) = (vec![1.05, 1.95], 0.0, vec![], 0.01); // start u = 0.05, w = 0; time each pass up through w = 0
    while t < 1000.0 {
        let n = rk4(&bf(2.0), &s, dt, 1); let (w0, w1) = (-(s[0] + s[1] - 3.0), -(n[0] + n[1] - 3.0));
        if w0 < 0.0 && 0.0 <= w1 && n[0] > 1.0 { laps.push((t, s[0] - 1.0 + (n[0] - s[0]) * (-w0) / (w1 - w0))); }
        s = n; t += dt;
    }
    let (tl, ul) = laps[laps.len() - 1]; let a_sim = -(1.0 / (ul * ul) - 400.0) / (2.0 * tl); // 1/r^2 grows at rate -2a
    println!("simulated at B 2: {} laps, u from 0.05 to {:.4}; a from 1/r^2 growth {:.4}", laps.len(), ul, a_sim);
    assert!((a_sim - a).abs() < 0.01 && (a + 0.375).abs() < 1e-6);
    for beta in [0.04, 0.01] { // dial d = 1/2 per unit of B: radius sqrt(-(beta/2)/a)
        let mut s = rk4(&bf(2.0 + beta), &vec![1.01, 2.0 + beta], 0.01, 300000); let mut xs = vec![s[0]];
        for _ in 0..700 { s = rk4(&bf(2.0 + beta), &s, 0.01, 1); xs.push(s[0]); }
        let (mx, mn) = (xs.iter().cloned().fold(f64::MIN, f64::max), xs.iter().cloned().fold(f64::MAX, f64::min));
        let (pred, half) = ((-(beta / 2.0) / a).sqrt(), (mx - mn) / 2.0);
        println!("B {:.2}: predicted radius {:.4}, simulated half-swing of x {:.4}, ratio {:.3}", 2.0 + beta, pred, half, half / pred);
        assert!((half / pred - 1.0).abs() < 0.08 * beta / 0.04);
    }
    println!("mistakes: no 1/2 dial speed {:.4}; no 1/16 {:.4}; sub back at mu -0.10 swing {:.4}", (-0.04 / a).sqrt(), (-0.02 / (16.0 * a)).sqrt(), down[10]);
    println!("ALL CHECKS PASS");
}
