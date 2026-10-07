// Limit cycles and van der Pol -- the same check as the Python, in Rust, std only.  RK4 is
// written out.  Road one: the polar model against its closed form.  Road two: van der Pol
// settled from two starts, then its loop found again by a return map and bisection.
type P = [f64; 2];
const S: f64 = 0.12;                                // seconds of heartbeat per model time unit
fn rk4(f: &dyn Fn(P) -> P, p: P, h: f64) -> P {
    let k1 = f(p); let k2 = f([p[0] + h / 2.0 * k1[0], p[1] + h / 2.0 * k1[1]]);
    let k3 = f([p[0] + h / 2.0 * k2[0], p[1] + h / 2.0 * k2[1]]); let k4 = f([p[0] + h * k3[0], p[1] + h * k3[1]]);
    [0, 1].map(|i| p[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]))
}
fn polar(p: P) -> P { let s = 1.0 - p[0] * p[0] - p[1] * p[1]; [p[0] * s - p[1], p[1] * s + p[0]] }
fn vdp(mu: f64) -> impl Fn(P) -> P { move |p: P| [p[1], mu * (1.0 - p[0] * p[0]) * p[1] - p[0]] }
fn run(f: &dyn Fn(P) -> P, p: P, t: f64, h: f64) -> Vec<P> {   // step from p for time t, keeping the path
    let mut path = vec![p];
    for _ in 0..(t / h).round() as usize { let q = rk4(f, *path.last().unwrap(), h); path.push(q) }
    path
}
fn lap(f: &dyn Fn(P) -> P, mut p: P, mu: f64) -> (f64, f64, f64) {   // x where v turns + to -, time, integral
    let (h, mut t, mut div) = (0.001, 0.0, 0.0);
    loop {
        let q = rk4(f, p, h); t += h;
        if p[1] > 0.0 && q[1] <= 0.0 {               // Newton on the last part-step lands v on 0
            let mut s = 0.0;
            for _ in 0..4 { let r = rk4(f, p, s); s -= r[1] / f(r)[1] }
            let r = rk4(f, p, s);
            return (r[0], t - h + s, div + s * mu * (1.0 - (p[0] * p[0] + r[0] * r[0]) / 2.0));
        }
        div += h * mu * (1.0 - (p[0] * p[0] + q[0] * q[0]) / 2.0); p = q;
    }
}
fn sci(x: f64, d: usize) -> String {                 // 3.17e-06, the way Python prints it
    let s = format!("{:.*e}", d, x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn pts(path: &[P], k: usize) -> String {
    path.iter().step_by(k).map(|p| format!("{:.1},{:.1}", 120.0 + 34.0 * p[0], 120.0 - 34.0 * p[1])).collect::<Vec<_>>().join(" ")
}
fn main() {
    let closed = |r0: f64, t: f64| 1.0 / (1.0 + (1.0 / (r0 * r0) - 1.0) * (-2.0 * t).exp()).sqrt();
    let err: Vec<f64> = [0.1, 0.05].iter().map(|&h| { let e = *run(&polar, [0.1, 0.0], 5.0, h).last().unwrap(); (e[0].hypot(e[1]) - closed(0.1, 5.0)).abs() }).collect();
    println!("polar model at t = 5, from r0 = 0.1: 99 x e^-10 = 99 x {} = {:.6}, r = {:.5}; from r0 = 2: r = {:.6}", sci((-10.0f64).exp(), 3), 99.0 * (-10.0f64).exp(), closed(0.1, 5.0), closed(2.0, 5.0));
    println!("RK4 error at h = 0.1 and 0.05: {}, {}; ratio {:.1} (fourth order: 16)", sci(err[0], 2), sci(err[1], 2), err[0] / err[1]);
    let (d, v1) = (1e-6, vdp(1.0));
    let (c0, c1) = (v1([d, 0.0]), v1([0.0, d]));    // columns of the Jacobian at the origin
    let (tr, det) = ((c0[0] + c1[1]) / d, (c0[0] * c1[1] - c1[0] * c0[1]) / (d * d));
    println!("van der Pol origin: trace {:.3}, det {:.3}, eigenvalues {:.3} +/- {:.3}i", tr, det, tr / 2.0, (det - tr * tr / 4.0).sqrt());
    let (mut paths, mut got) = (Vec::new(), Vec::new());
    for s in [0.1, 4.0] {
        paths.push(run(&v1, [s, 0.0], 60.0, 0.001));
        let g = lap(&v1, [lap(&v1, *paths.last().unwrap().last().unwrap(), 1.0).0, 0.0], 1.0);
        println!("start ({:.1}, 0), after t = 60: amplitude {:.4}, period {:.4}", s, g.0, g.1); got.push(g);
    }
    let (mut lo, mut hi) = (1.0, 3.0);              // road two: the x the return map sends to itself
    for _ in 0..40 { let m = (lo + hi) / 2.0; if lap(&v1, [m, 0.0], 1.0).0 > m { lo = m } else { hi = m } }
    let (a, t, div) = lap(&v1, [lo, 0.0], 1.0);
    let slope = (lap(&v1, [a + 1e-3, 0.0], 1.0).0 - lap(&v1, [a - 1e-3, 0.0], 1.0).0) / 2e-3;
    println!("return map fixed point by bisection: amplitude {:.4}, period {:.4}; x {} s = {:.3} s, {:.1} beats/min", a, t, S, t * S, 60.0 / (t * S));
    println!("pull per lap: exp(integral) = {}, return-map slope = {}; polar exp(-4 pi) = {}", sci(div.exp(), 3), sci(slope, 3), sci((-4.0 * std::f64::consts::PI).exp(), 2));
    let v0 = vdp(0.0);
    let amp0: Vec<f64> = [0.1, 4.0].iter().map(|&s| lap(&v0, *run(&v0, [s, 0.0], 60.0, 0.001).last().unwrap(), 0.0).0).collect();
    let lin = run(&|p: P| [p[1], p[1] - p[0]], [0.1, 0.0], 20.0, 0.001);
    println!("mistake 1, mu = 0: amplitudes stay {:.4} and {:.4}; every circle is a loop", amp0[0], amp0[1]);
    println!("mistake 2, linearised law from (0.1, 0): largest |x| by t = 20 is {:.0}, not 2", lin.iter().map(|p| p[0].abs()).fold(0.0, f64::max));
    let tau = 2.0 * std::f64::consts::PI;
    println!("mistake 3, period taken as 2 pi = {:.4}: {:.1}% short, {:.1} beats/min", tau, 100.0 * (1.0 - tau / t), 60.0 / (tau * S));
    println!("figure, 34 px per unit; origin (120, 120); x = 4 at {:.0}; x = {:.4} at {:.1}", 120.0 + 34.0 * 4.0, a, 120.0 + 34.0 * a);
    println!("figure, start 0.1: {}", pts(&paths[0][..16001], 400));
    println!("figure, start 4.0: {}", pts(&paths[1][..7001], 250));
    let cyc = run(&v1, [a, 0.0], t, t / 24000.0);
    println!("figure, loop: {}", pts(&cyc[..24000], 1000));
    assert!(err[1] < 1e-6 && 12.0 < err[0] / err[1] && err[0] / err[1] < 20.0);   // RK4 meets the closed form at order 4
    assert!(got.iter().all(|g| (g.0 - a).abs() < 1e-4 && (g.1 - t).abs() < 1e-3)); // settling agrees with bisection
    assert!((div.exp() / slope - 1.0).abs() < 1e-3 && slope < 1.0);             // two measures of the pull agree
    assert!((tr - 1.0).abs() < 1e-6 && (det - 1.0).abs() < 1e-6 && (amp0[1] - 4.0).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
