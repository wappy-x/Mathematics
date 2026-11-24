// Discontinuous Galerkin for u_t + u_x = 0 on a 1 m loop -- the same check in Rust, std only.
// Road 1: after one lap the exact answer is the starting bump.  Road 2: DG with p = 0, 1, 2
// on 10, 20, 40 cells, and the observed orders.  Road 3: p = 0 against the upwind step of
// the Flow problems card, and the energy identity against the summed squared jumps.
use std::f64::consts::PI;
type Dg = Vec<Vec<f64>>;

fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn leg(k: usize, x: f64) -> f64 {              // Legendre polynomial P_k(x), by recurrence
    if k == 0 { return 1.0; }
    let (mut p0, mut p1) = (1.0, x);
    for n in 1..k { let p2 = ((2 * n + 1) as f64 * x * p1 - n as f64 * p0) / (n + 1) as f64; p0 = p1; p1 = p2; }
    p1
}
fn gauss(n: usize) -> (Vec<f64>, Vec<f64>) {   // Gauss-Legendre nodes and weights, by Newton
    let (mut xs, mut ws) = (vec![], vec![]);
    let nf = n as f64;
    for i in 0..n {
        let mut x = (PI * (i as f64 + 0.75) / (nf + 0.5)).cos();
        for _ in 0..50 { x -= leg(n, x) * (x * x - 1.0) / (nf * (x * leg(n, x) - leg(n - 1, x))); }
        let dp = nf * (x * leg(n, x) - leg(n - 1, x)) / (x * x - 1.0);
        xs.push(x); ws.push(2.0 / ((1.0 - x * x) * dp * dp));
    }
    (xs, ws)
}
fn bump(x: f64) -> f64 { (PI * x).sin().powi(2) }
fn square(x: f64) -> f64 { let y = x.rem_euclid(1.0); if 0.25 <= y && y < 0.75 { 1.0 } else { 0.0 } }

struct Q { gx: Vec<f64>, gw: Vec<f64> }
impl Q {
    fn project(&self, f: fn(f64) -> f64, n: usize, p: usize) -> Dg {
        (0..n).map(|j| (0..=p).map(|k| (2 * k + 1) as f64 / 2.0 * self.gx.iter().zip(&self.gw)
            .map(|(&x, &w)| w * f((j as f64 + (1.0 + x) / 2.0) / n as f64) * leg(k, x)).sum::<f64>()).collect()).collect()
    }
    fn l2err(&self, a: &Dg, f: fn(f64) -> f64) -> f64 {
        let n = a.len(); let mut s = 0.0;
        for j in 0..n { for (&x, &w) in self.gx.iter().zip(&self.gw) {
            let uh: f64 = a[j].iter().enumerate().map(|(k, &c)| c * leg(k, x)).sum();
            s += w / (2 * n) as f64 * (uh - f((j as f64 + (1.0 + x) / 2.0) / n as f64)).powi(2);
        } }
        s.sqrt()
    }
}
fn sgn(k: usize) -> f64 { if k % 2 == 0 { 1.0 } else { -1.0 } }
fn edges(a: &Dg) -> (Vec<f64>, Vec<f64>) {     // values at each cell's right and left edge
    (a.iter().map(|c| c.iter().sum()).collect(),
     a.iter().map(|c| c.iter().enumerate().map(|(k, &v)| v * sgn(k)).sum()).collect())
}
fn jumps(a: &Dg) -> f64 {                      // sum over edges of (jump in u)^2
    let (r, l) = edges(a); let n = a.len();
    (0..n).map(|j| (r[j] - l[(j + 1) % n]).powi(2)).sum()
}
fn rhs(a: &Dg, beta: f64) -> Dg {              // da/dt; beta = 1 upwind, 0 central, -1 downwind
    let n = a.len(); let (r, l) = edges(a);
    let f: Vec<f64> = (0..n).map(|j| 0.5 * (r[j] + l[(j + 1) % n]) + 0.5 * beta * (r[j] - l[(j + 1) % n])).collect();
    (0..n).map(|j| (0..a[0].len()).map(|k| {
        let vol: f64 = (0..k).filter(|m| (k - m) % 2 == 1).map(|m| 2.0 * a[j][m]).sum();
        (2 * k + 1) as f64 * n as f64 * (vol - (f[j] - f[(j + n - 1) % n] * sgn(k)))
    }).collect()).collect()
}
fn lin(s: f64, a: &Dg, t: f64, b: &Dg) -> Dg {
    a.iter().zip(b).map(|(r, q)| r.iter().zip(q).map(|(x, y)| s * x + t * y).collect()).collect()
}
fn minmod(a: f64, b: f64, c: f64) -> f64 {
    if a > 0.0 && b > 0.0 && c > 0.0 { return a.min(b).min(c); }
    if a < 0.0 && b < 0.0 && c < 0.0 { return a.max(b).max(c); }
    0.0
}
fn limit(a: Dg) -> Dg {                        // p = 1 slope limiter: keep the mean, clip the slope
    let n = a.len();
    (0..n).map(|j| vec![a[j][0], minmod(a[j][1], a[(j + 1) % n][0] - a[j][0], a[j][0] - a[(j + n - 1) % n][0])]).collect()
}
fn run(q: &Q, p: usize, n: usize, beta: f64, laps: f64, f: fn(f64) -> f64, euler: bool, lim: bool, nu: f64) -> (Dg, f64) {
    let mut a = q.project(f, n, p);
    let steps = (laps * n as f64 / nu).round() as usize; let dt = laps / steps as f64; let mut lost = 0.0;
    let g = |b: Dg| if lim { limit(b) } else { b };
    for _ in 0..steps {
        let j0 = jumps(&a);
        if euler { a = lin(1.0, &a, dt, &rhs(&a, beta)); } else {   // three-stage, third-order Runge-Kutta
            let u1 = g(lin(1.0, &a, dt, &rhs(&a, beta)));
            let u2 = g(lin(0.75, &a, 0.25, &lin(1.0, &u1, dt, &rhs(&u1, beta))));
            a = g(lin(1.0 / 3.0, &a, 2.0 / 3.0, &lin(1.0, &u2, dt, &rhs(&u2, beta))));
        }
        lost += dt * (j0 + jumps(&a)) / 2.0;       // trapezoid rule for the integral of the jumps
    }
    (a, lost)
}
fn energy(a: &Dg) -> f64 {
    a.iter().flat_map(|c| c.iter().enumerate().map(|(k, &v)| v * v / (a.len() * (2 * k + 1)) as f64)).sum()
}
fn mx(v: &[f64]) -> f64 { v.iter().fold(f64::MIN, |m, &x| m.max(x)) }
fn mn(v: &[f64]) -> f64 { v.iter().fold(f64::MAX, |m, &x| m.min(x)) }
fn join(v: Vec<String>, s: &str) -> String { v.join(s) }

fn main() {
    let (gx, gw) = gauss(5); let q = Q { gx, gw };
    let sm = |p: usize, n: usize| run(&q, p, n, 1.0, 1.0, bump, false, false, 0.1);
    println!("loop 1 m, speed c = 1 m/s, one lap T = 1 s, dye u0 = sin(pi x)^2; exact answer after one lap = u0");
    println!("Gauss 5-point nodes: {}; weights add to {:.12}", join(q.gx.iter().map(|x| format!("{:.6}", x)).collect(), " "), q.gw.iter().sum::<f64>());
    let g8: f64 = q.gx.iter().zip(&q.gw).map(|(&x, &w)| w * x.powi(8)).sum();
    let b0 = q.project(bump, 10, 0); let mut u: Vec<f64> = b0.iter().map(|c| c[0]).collect(); let mut dg = b0.clone();
    for _ in 0..13 {                           // road 3: p = 0 with Euler steps at nu = 0.8
        u = (0..10).map(|j| u[j] - 0.8 * (u[j] - u[(j + 9) % 10])).collect();
        dg = lin(1.0, &dg, 0.08, &rhs(&dg, 1.0));
    }
    let d_up = u.iter().zip(&dg).fold(0.0f64, |m, (x, c)| m.max((x - c[0]).abs()));
    println!("p = 0, Euler steps, nu = 0.8, 13 steps: largest gap from the upwind step u - nu(u - u_left) = {}", sci(d_up));
    println!("L2 error after one lap, upwind flux, third-order Runge-Kutta, nu = 0.1:");
    let mut e = [[0.0f64; 3]; 3]; let ns = [10usize, 20, 40];
    for p in 0..3 { for i in 0..3 {
        e[p][i] = q.l2err(&sm(p, ns[i]).0, bump);
        let tail = if i > 0 { format!("  ratio {:.2}  observed order {:.2}", e[p][i - 1] / e[p][i], (e[p][i - 1] / e[p][i]).log2()) } else { String::new() };
        println!("  p = {}  N = {:<3} h = {:<6} error {}{}", p, ns[i], 1.0 / ns[i] as f64, sci(e[p][i]), tail);
    } }
    let (a1, lost) = sm(1, 10); let (r, l) = edges(&a1);
    println!("10 cells after one lap: p = 0 peak cell {:.4}; p = 1 at x = 0.5 left {:.4}, right {:.4}, jump {:.4}",
             mx(&sm(0, 10).0.iter().map(|c| c[0]).collect::<Vec<_>>()), r[4], l[5], l[5] - r[4]);
    let a = q.project(bump, 10, 1); let (r, _l) = edges(&a); let da = rhs(&a, 1.0);
    let (xl, xr) = (0.4, 0.5);
    let avg = 0.5 - ((2.0 * PI * xr).sin() - (2.0 * PI * xl).sin()) / (4.0 * PI * (xr - xl));
    println!("hand step, p = 1, 10 cells, t = 0: cell [0.3, 0.4] a0 {:.6} a1 {:.6}; cell [0.4, 0.5] a0 {:.6} a1 {:.6}", a[3][0], a[3][1], a[4][0], a[4][1]);
    println!("  closed-form average of cell [0.4, 0.5] {:.6}; edge values: 0.4 from the left {:.6}, 0.5 from the left {:.6}", avg, r[3], r[4]);
    println!("  da0/dt = -({:.6} - {:.6}) / 0.1 = {:.6}; da1/dt = 30 x (2 x {:.6} - {:.6} - {:.6}) = {:.6}",
             r[4], r[3], da[4][0], a[4][0], r[4], r[3], da[4][1]);
    let e0 = energy(&a); let (a05, lost05) = run(&q, 1, 10, 1.0, 1.0, bump, false, false, 0.05); let (gap, gap05) = (e0 - energy(&a1) - lost, e0 - energy(&a05) - lost05);
    println!("energy, p = 1, 10 cells: exact 3/8 = {:.6}; projected {:.6}; after one lap {:.6}", 0.375, e0, energy(&a1));
    println!("  lost over the lap {:.6}; time integral of the summed squared jumps {:.6}; gap {}; at nu = 0.05 the gap is {}, {:.2} times smaller",
             e0 - energy(&a1), lost, sci(gap), sci(gap05), gap / gap05);
    let mut worst = 0.0f64;
    for (beta, name) in [(1.0, "upwind"), (0.0, "central"), (-1.0, "downwind")] {
        let rr = rhs(&a, beta); let mut rate = 0.0;
        for j in 0..10 { for k in 0..2 { rate += 2.0 * a[j][k] * rr[j][k] / (10 * (2 * k + 1)) as f64; } }
        worst = worst.max((rate + beta * jumps(&a)).abs());
        println!("  t = 0, {:<8} flux: d/dt of the energy {:+.8}; -beta x sum of squared jumps {:+.8}", name, rate, -beta * jumps(&a) + 0.0);
    }
    let dn = energy(&run(&q, 1, 10, -1.0, 1.0, bump, false, false, 0.1).0);
    let eu1 = energy(&run(&q, 1, 10, 1.0, 1.0, bump, true, false, 0.1).0);
    let eu10 = energy(&run(&q, 1, 10, 1.0, 10.0, bump, true, false, 0.1).0);
    println!("what breaks: downwind flux, p = 1, 10 cells: energy after one lap 10^{:.1}", dn.log10());
    println!("what breaks: Euler steps, p = 1, 10 cells, nu = 0.1: energy {:.4} -> {:.4} after one lap, {:.4} after ten", e0, eu1, eu10);
    let (rs, ls) = edges(&run(&q, 1, 20, 1.0, 1.0, square, false, false, 0.1).0); let s1 = [rs, ls].concat();
    let (r2, l2) = edges(&run(&q, 1, 20, 1.0, 1.0, square, false, true, 0.1).0); let s2 = [r2, l2].concat();
    println!("what breaks: square pulse, p = 1, 20 cells: highest {:.4}, lowest {:.4}; with the minmod limiter {:.4} and {:.4}", mx(&s1), mn(&s1), mx(&s2), mn(&s2));
    let lim40 = q.l2err(&run(&q, 1, 40, 1.0, 1.0, bump, false, true, 0.1).0, bump);
    println!("what breaks: limiter left on for the smooth bump, p = 1, 40 cells: error {} against {}", sci(lim40), sci(e[1][2]));
    let cen: Vec<String> = ns.iter().map(|&n| sci(q.l2err(&run(&q, 1, n, 0.0, 1.0, bump, false, false, 0.1).0, bump))).collect();
    println!("central flux, p = 1, N = 10, 20, 40: errors {}", cen.join(", "));
    let need = e[0][2] * 40.0 / e[1][2];
    println!("cost: p = 1 on 40 cells is 80 unknowns for {}; p = 0 at order 1 would need about {:.0} cells (estimate)", sci(e[1][2]), need);
    println!("chart, log10 h: {}", join(ns.iter().map(|&n| format!("{:.2}", (1.0 / n as f64).log10())).collect(), ", "));
    for p in 0..3 { println!("chart, p = {} log10 error: {}", p, join(e[p].iter().map(|x| format!("{:.2}", x.log10())).collect(), ", ")); }
    let xp = |x: f64| 40.0 + 280.0 * x; let yp = |v: f64| 200.0 - 160.0 * v;
    let (r, l) = edges(&a1);
    println!("figure, p = 1 segments: {}", join((0..10).map(|j| format!("({:.1},{:.1})-({:.1},{:.1})",
        xp(j as f64 / 10.0), yp(l[j]), xp((j + 1) as f64 / 10.0), yp(r[j]))).collect(), " "));
    println!("figure, exact curve y at x = 0, 0.05, ..., 1: {}", join((0..21).map(|i| format!("{:.1}", yp(bump(i as f64 / 20.0)))).collect(), " "));
    println!("figure, p = 0 steps y: {}", join(sm(0, 10).0.iter().map(|c| format!("{:.1}", yp(c[0]))).collect(), " "));

    assert!((q.gw.iter().sum::<f64>() - 2.0).abs() < 1e-14 && (g8 - 2.0 / 9.0).abs() < 1e-14); // Gauss: exact to degree 9
    assert!(d_up < 1e-15);                                     // p = 0 is the upwind step
    assert!((a[4][0] - avg).abs() < 1e-12);                    // projection meets the closed form
    assert!(e[0][1] / e[0][2] > 1.2 && e[0][1] / e[0][2] < 2.2); // p = 0: order toward 1
    assert!(e[1][1] / e[1][2] > 3.6 && e[1][1] / e[1][2] < 4.6 && e[2][1] / e[2][2] > 7.2 && e[2][1] / e[2][2] < 8.8);
    assert!(worst < 1e-12);                                    // energy rate = -beta x jumps
    assert!(gap.abs() < 5e-3 * lost && 6.0 < gap / gap05 && gap / gap05 < 10.0 && energy(&a1) < e0);   // gap: the time step's own error
    assert!(dn > 1e10 && eu1 > e0 && eu10 > 10.0 * e0);        // the failures really fail
    assert!(mx(&s1) > 1.05 && -1e-12 < mn(&s2) && mx(&s2) < 1.0 + 1e-12);
    println!("ALL CHECKS PASS");
}
