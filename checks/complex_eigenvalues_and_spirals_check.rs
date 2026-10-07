// Complex eigenvalues and spirals -- the same check as the Python, in Rust.
// No crates.  The shock absorber y' = v, v' = -5y - 2v (y in cm, v in cm/s,
// start y = 10, v = 0) is solved by two roads: the real solutions built from
// w e^(lambda t), and Euler's small steps along the slope, which never call
// exp, cos or sin.  The stepped run's crossings of y = 0 time one turn.
use std::f64::consts::PI;
type M2 = [[f64; 2]; 2];

fn pair(m: &M2) -> (f64, f64, f64, f64) {   // eigenvalues alpha +/- i beta of a 2x2
    let (tr, det) = (m[0][0] + m[1][1], m[0][0] * m[1][1] - m[0][1] * m[1][0]);
    (tr / 2.0, (4.0 * det - tr * tr).sqrt() / 2.0, tr, det)
}

struct Sys { a: M2, al: f64, be: f64, p: [f64; 2], q: [f64; 2], c1: f64, c2: f64 }

impl Sys {
    fn closed(&self, t: f64) -> [f64; 2] {  // c1 Re(w e^(lambda t)) + c2 Im(w e^(lambda t))
        let (e, c, s) = ((self.al * t).exp(), (self.be * t).cos(), (self.be * t).sin());
        let f = |i: usize| e * (self.c1 * (self.p[i] * c - self.q[i] * s) + self.c2 * (self.p[i] * s + self.q[i] * c));
        [f(0), f(1)]
    }
    fn euler(&self, t_end: f64, n: usize) -> ([f64; 2], Vec<f64>) {  // new = old + h x (A state)
        let (mut y, mut v, mut t, mut down, h, a) = (10.0, 0.0, 0.0, Vec::new(), t_end / n as f64, self.a);
        for _ in 0..n {
            let (ny, nv) = (y + h * (a[0][0] * y + a[0][1] * v), v + h * (a[1][0] * y + a[1][1] * v));
            if y > 0.0 && 0.0 >= ny { down.push(t + h * y / (y - ny)) }  // passing rest, moving down
            y = ny; v = nv; t += h;
        }
        ([y, v], down)
    }
}

fn pts(v: &[(f64, f64)]) -> String {
    v.iter().map(|(a, b)| format!("{:.1},{:.1}", a, b)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let a: M2 = [[0.0, 1.0], [-5.0, -2.0]];
    let (al, be, tr, det) = pair(&a);
    let (p, q) = ([1.0, (al - a[0][0]) / a[0][1]], [0.0, be / a[0][1]]);  // w = p + i q, from row 1
    let s = Sys { a, al, be, p, q, c1: 10.0, c2: -10.0 * p[1] / q[1] };   // start (10, 0) = c1 p + c2 q
    let tt = 2.0 * PI / be;
    let xt = s.closed(tt);
    let errs: Vec<f64> = [300, 600, 1200].iter().map(|&n| { let e = s.euler(tt, n).0; (e[0] - xt[0]).hypot(e[1] - xt[1]) }).collect();
    let (fine, down) = (s.euler(tt, 30000).0, s.euler(5.0, 50000).1);
    let (up, dn, x1) = (s.closed(1.0 + 1e-6), s.closed(1.0 - 1e-6), s.closed(1.0));
    let fd = [(up[0] - dn[0]) / 2e-6, (up[1] - dn[1]) / 2e-6];
    let law = [a[0][0] * x1[0] + a[0][1] * x1[1], a[1][0] * x1[0] + a[1][1] * x1[1]];
    let px = |x: [f64; 2]| (96.0 + 22.0 * x[0], 56.0 - 12.0 * x[1]);   // 22 px per cm, 12 px per cm/s
    let sp: Vec<(f64, f64)> = (0..49).map(|k| px(s.closed(k as f64 * tt / 48.0))).collect();
    let (dx, dy) = (sp[7].0 - sp[5].0, sp[7].1 - sp[5].1);
    let (dx, dy, (cx, cy)) = (dx / dx.hypot(dy), dy / dx.hypot(dy), sp[6]);  // unit direction of travel
    let arrow = vec![(cx + 7.0 * dx, cy + 7.0 * dy), (cx - 5.0 * dx + 5.0 * dy, cy - 5.0 * dy - 5.0 * dx), (cx - 5.0 * dx - 5.0 * dy, cy - 5.0 * dy + 5.0 * dx)];
    println!("A: trace {:.0}, det {:.0}, discriminant {:.0}; eigenvalues {:.0} +/- {:.0}i", tr, det, tr * tr - 4.0 * det, al, be);
    println!("eigenvector w = p + i q: p = ({:.0}, {:.0}), q = ({:.0}, {:.0}); start (10, 0) = {:.0} p + {:.0} q", p[0], p[1], q[0], q[1], s.c1, s.c2);
    println!("coefficients of cos 2t, sin 2t times e^(-t): y {:.0}, {:.0} cm; v {:.0}, {:.0} cm/s", s.c1 * p[0] + s.c2 * q[0], s.c2 * p[0] - s.c1 * q[0], s.c1 * p[1] + s.c2 * q[1], s.c2 * p[1] - s.c1 * q[1]);
    println!("rate at start: y' = {:.0} cm/s, v' = {:.0} cm/s^2, so the state turns clockwise", a[0][0] * 10.0, a[1][0] * 10.0);
    println!("one turn T = 2 pi / {:.0} = {:.4} s; shrink per turn e^(alpha T) = {:.4}", be, tt, (al * tt).exp());
    println!("y(T): closed form {:.4} cm; Euler, 30000 steps: {:.4} cm, ratio to start {:.4}", xt[0], fine[0], fine[0] / 10.0);
    println!("Euler error at T, 300, 600, 1200 steps: {:.4} {:.4} {:.4}; ratios {:.3} {:.3}", errs[0], errs[1], errs[2], errs[0] / errs[1], errs[1] / errs[2]);
    println!("first pass through rest: closed form (pi - atan 2) / 2 = {:.4} s; Euler {:.4} s", (PI - 2f64.atan()) / 2.0, down[0]);
    println!("one turn timed from the Euler run: {:.4} - {:.4} = {:.4} s", down[1], down[0], down[1] - down[0]);
    println!("law at t = 1: finite difference ({:.6}, {:.6}); A x = ({:.6}, {:.6})", fd[0], fd[1], law[0], law[1]);
    let (a2, b2, _, _) = pair(&[[0.0, 1.0], [-5.0, 2.0]]);
    println!("second case, damping -2: eigenvalues {:.0} +/- {:.0}i; grows by e^(alpha T) = {:.2} per turn", a2, b2, (a2 * 2.0 * PI / b2).exp());
    println!("mistake, T = 2 pi / |lambda| = 2 pi / sqrt 5 = {:.2} s, not {:.2} s", 2.0 * PI / (al * al + be * be).sqrt(), tt);
    println!("mistake, a turn taken as 2 pi s: shrink e^(-2 pi) = {:.4}, not {:.4}", (-2.0 * PI).exp(), (al * tt).exp());
    println!("mistake, real part alone: starts at ({:.0}, {:.0}), not (10, 0)", s.c1 * p[0], s.c1 * p[1]);
    println!("hypothesis dropped, complex x' = i x: Re e^(it) = cos t has rate {:.4} at t = 1; the law asks {:.4}i", -1f64.sin(), 1f64.cos());
    println!("figure, spiral px: {}", pts(&sp));
    println!("figure, arrow px: {}", pts(&arrow));
    assert!((fine[0] - xt[0]).abs() < 1e-3 && (fine[1] - xt[1]).abs() < 1e-3);   // road two meets road one
    assert!([errs[0] / errs[1], errs[1] / errs[2]].iter().all(|&r| r > 1.9 && r < 2.1));  // order one
    assert!(((down[1] - down[0]) - tt).abs() < 1e-3);                            // turn timed = 2 pi / beta
    assert!((fd[0] - law[0]).abs().max((fd[1] - law[1]).abs()) < 1e-6);          // the answer obeys the law
    println!("ALL CHECKS PASS");
}
