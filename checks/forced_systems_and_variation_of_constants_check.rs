// Forced systems -- the same check as the Python, in Rust.  No crates.
// Two rooms, C above outdoors, t in hours: x' = Ax + b, heater b = (15, 0).
// Road one: modes, xeq + e^(At)(x0 - xeq).  Road two: e^(At) x0 + integral of
// e^(A(t-s)) b, Simpson's rule, e^(Aw) by power series.  Road three: Euler.
type V = [f64; 2];
type M = [[f64; 2]; 2];
const A: M = [[-2.0, 1.0], [1.0, -2.0]];
const INS: M = [[-1.0, 1.0], [1.0, -1.0]];
const B: V = [15.0, 0.0];

fn mv(m: M, v: V) -> V { [m[0][0] * v[0] + m[0][1] * v[1], m[1][0] * v[0] + m[1][1] * v[1]] }
fn add(a: V, b: V) -> V { [a[0] + b[0], a[1] + b[1]] }
fn modes(t: f64, v: V) -> V {             // e^(At) v by the eigenvectors (1, 1) and (1, -1)
    let (p, m) = ((v[0] + v[1]) / 2.0 * (-t).exp(), (v[0] - v[1]) / 2.0 * (-3.0 * t).exp());
    [p + m, p - m]
}
fn series(m: M, w: f64, v: V) -> V {      // e^(Mw) v = v + Mwv + (Mw)^2 v / 2! + ...
    let (mut out, mut term) = (v, v);
    for k in 1..40 { let n = mv(m, term); term = [n[0] * w / k as f64, n[1] * w / k as f64]; out = add(out, term) }
    out
}
fn pushed(m: M, t: f64, s1: f64, s2: f64) -> V { // input from s1 to s2, each moment carried to t
    let n = 200;
    let (h, mut tot) = ((s2 - s1) / n as f64, [0.0, 0.0]);
    for i in 0..=n {
        let wt = h / 3.0 * if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let c = series(m, t - s1 - i as f64 * h, B);
        tot = [tot[0] + wt * c[0], tot[1] + wt * c[1]];
    }
    tot
}
fn det(m: M) -> f64 { m[0][0] * m[1][1] - m[0][1] * m[1][0] }
fn xeq() -> V { let d = det(A); [-(A[1][1] * B[0] - A[0][1] * B[1]) / d, -(A[0][0] * B[1] - A[1][0] * B[0]) / d] }
fn closed(t: f64, x0: V) -> V { let e = xeq(); add(e, modes(t, [x0[0] - e[0], x0[1] - e[1]])) }
fn road2(t: f64, x0: V) -> V { add(series(A, t, x0), pushed(A, t, 0.0, t)) }
fn euler(t: f64, h: f64, mut x: V) -> V {
    for _ in 0..(t / h).round() as usize { let r = add(mv(A, x), B); x = [x[0] + h * r[0], x[1] + h * r[1]] }
    x
}
fn f(v: V) -> String { format!("({:.4}, {:.4})", v[0], v[1]) }
fn gap(a: V, b: V) -> f64 { (a[0] - b[0]).abs().max((a[1] - b[1]).abs()) }

fn main() {
    let (cold, house) = ([0.0, 0.0], [30.0, 10.0]);
    let (c2, h2) = (closed(2.0, cold), closed(2.0, house));
    let errs: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(2.0, h, cold)[0] - c2[0]).abs()).collect();
    let slices: Vec<f64> = [0.0, 0.5, 1.0, 1.5].iter().map(|&s| pushed(A, 2.0, s, s + 0.5)[0]).collect();
    let (hi, lo) = (closed(1.001, cold), closed(0.999, cold));
    let fd = [(hi[0] - lo[0]) / 0.002, (hi[1] - lo[1]) / 0.002];
    let law = add(mv(A, closed(1.0, cold)), B);
    let row = |i: usize| (0..9).map(|k| format!("{:.2}", closed(k as f64 / 2.0, cold)[i])).collect::<Vec<_>>().join(", ");
    println!("det A = {:.0}; settles at xeq = -A^(-1) b = {}", det(A), f(xeq()));
    println!("t (h)      {}", (0..9).map(|k| format!("{:.1}", k as f64 / 2.0)).collect::<Vec<_>>().join(", "));
    println!("room 1 (C) {}", row(0));
    println!("room 2 (C) {}", row(1));
    let g = [(xeq()[0] + xeq()[1]) / 2.0, (xeq()[0] - xeq()[1]) / 2.0];
    let (e2, e6) = ((-2.0f64).exp(), (-6.0f64).exp());
    println!("cold gap = -{:.1}(1, 1) - {:.1}(1, -1); e^(-2) = {:.5}, e^(-6) = {:.5}; {:.1}e^(-2) = {:.5}, {:.1}e^(-6) = {:.5}", g[0], g[1], e2, e6, g[0], g[0] * e2, g[1], g[1] * e6);
    println!("cold start, t = 2: modes {}; integral {}; Euler {}", f(c2), f(road2(2.0, cold)), f(euler(2.0, 0.0025, cold)));
    println!("house start (30, 10), t = 2: free decay {}; total {}; integral {}", f(modes(2.0, house)), f(h2), f(road2(2.0, house)));
    let sl: Vec<String> = slices.iter().map(|v| format!("{:.4}", v)).collect();
    println!("half-hour slices of heat, carried to t = 2, room 1: {} sum {:.4}; each slice puts in {:.1}", sl.join(" "), slices.iter().sum::<f64>(), B[0] / 2.0);
    let e: Vec<String> = errs.iter().map(|x| format!("{:.5}", x)).collect();
    println!("Euler error, room 1 at t = 2, h = 0.01, 0.005, 0.0025: {}", e.join(" "));
    println!("error ratios on halving h: {:.3} {:.3}", errs[0] / errs[1], errs[1] / errs[2]);
    println!("rate at t = 1: finite difference {}; law Ax + b {}", f(fd), f(law));
    println!("mistake, heat added unpropagated: room 1 = {:.2}", B[0] * 2.0);
    println!("mistake, all heat aged from t = 0: room 1 = {:.4}", 2.0 * modes(2.0, B)[0]);
    println!("mistake, settled state only: room 1 = {:.2} at every t, even t = 0", xeq()[0]);
    let ins = pushed(INS, 2.0, 0.0, 2.0);
    let insf = 15.0 + 3.75 * (1.0 - (-4.0f64).exp());
    let r = add(mv(INS, ins), B);
    println!("insulated walls, det = {:.0}: room 1 at t = 2 = {:.4}; formula 15 + 3.75(1 - e^(-4)) = {:.4}; average climbs {:.1} per hour", det(INS), ins[0], insf, (r[0] + r[1]) / 2.0);
    assert!(gap(road2(2.0, house), h2) < 1e-7);                        // road two meets road one
    assert!(errs.windows(2).all(|w| w[0] / w[1] > 1.9 && w[0] / w[1] < 2.1)); // road three, order one
    assert!(gap(fd, law) < 1e-5);                                      // the answer obeys the law
    assert!((ins[0] - insf).abs() < 1e-6);                             // insulated: no settling
    println!("ALL CHECKS PASS");
}
