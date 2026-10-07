// The eigenvalue method -- the same check as the Python, in Rust.  No crates.
// Two rooms, heating off, outside 0 C, time in hours: T1' = -2 T1 + T2,
// T2' = T1 - 2 T2, start (30, 10).  Road one: eigenvalues, eigenvectors, modes
// fitted to the start.  Road two: Euler steps on the coupled rates.
type M = [[f64; 2]; 2];
type V = [f64; 2];

fn eigen(a: M) -> (V, [V; 2]) { // roots of L^2 - trace L + det = 0, and a direction for each
    let (tr, det) = (a[0][0] + a[1][1], a[0][0] * a[1][1] - a[0][1] * a[1][0]);
    let l = [(tr + (tr * tr - 4.0 * det).sqrt()) / 2.0, (tr - (tr * tr - 4.0 * det).sqrt()) / 2.0];
    (l, [[a[0][1], l[0] - a[0][0]], [a[0][1], l[1] - a[0][0]]]) // from row 1 of (A - L I) v = 0
}
fn fit(vs: [V; 2], x0: V) -> V { // c1 v1 + c2 v2 = x0, solved by Cramer's rule
    let ([p, q], [r, s]) = (vs[0], vs[1]);
    [(x0[0] * s - r * x0[1]) / (p * s - r * q), (p * x0[1] - q * x0[0]) / (p * s - r * q)]
}
fn modes(l: V, vs: [V; 2], c: V, t: f64) -> V {
    let f = |i: usize| (0..2).map(|k| c[k] * (l[k] * t).exp() * vs[k][i]).sum::<f64>();
    [f(0), f(1)]
}
fn rate(a: M, x: V) -> V { [a[0][0] * x[0] + a[0][1] * x[1], a[1][0] * x[0] + a[1][1] * x[1]] }
fn euler(a: M, mut x: V, t_end: f64, h: f64) -> V { // new state = old state + h x rate, repeated
    for _ in 0..(t_end / h).round() as usize { let r = rate(a, x); x = [x[0] + h * r[0], x[1] + h * r[1]]; }
    x
}
fn peak(a: M, mut x: V, h: f64) -> (f64, f64) { // step until room 2 stops warming
    let mut t = 0.0;
    while rate(a, x)[1] > 0.0 { x = euler(a, x, h, h); t += h; }
    (t, x[1])
}
fn vec(v: V, d: usize) -> String { format!("({:.*}, {:.*})", d, v[0], d, v[1]) }
fn diff(x: V, y: V) -> f64 { (x[0] - y[0]).abs().max((x[1] - y[1]).abs()) }

fn main() {
    let (a, b, j, x0): (M, M, M, V) = ([[-2.0, 1.0], [1.0, -2.0]], [[-3.0, 1.0], [2.0, -4.0]], [[-1.0, 1.0], [0.0, -1.0]], [30.0, 10.0]);
    let (lams, vs) = eigen(a);
    let cs = fit(vs, x0);
    let tt = |t: f64| modes(lams, vs, cs, t);
    let ts: Vec<f64> = (0..13).map(|k| k as f64 / 4.0).collect();
    let fig = [0.0, 0.1, 0.2, 0.3, 0.5, 0.75, 1.0, 1.5, 2.0, 3.0];
    let errs: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(a, x0, 1.0, h)[0] - tt(1.0)[0]).abs()).collect();
    let (eu1, pk) = (euler(a, x0, 1.0, 1e-4), peak(a, x0, 1e-5));
    let row = |f: &dyn Fn(f64) -> f64| ts.iter().map(|&t| format!("{:.2}", f(t))).collect::<Vec<_>>().join(" ");
    let tp = 1.5f64.ln() / 2.0;
    println!("eigenvalues {:.0}, {:.0} per hour; eigenvectors {}, {}", lams[0], lams[1], vec(vs[0], 0), vec(vs[1], 0));
    println!("A times them: {}, {}; weights c1 = {:.0}, c2 = {:.0}", vec(rate(a, vs[0]), 0), vec(rate(a, vs[1]), 0), cs[0], cs[1]);
    println!("t (h)   {}", row(&|t| t));
    println!("T1 (C)  {}", row(&|t| tt(t)[0]));
    println!("T2 (C)  {}", row(&|t| tt(t)[1]));
    println!("at 1 h: slow piece {:.4}, fast piece {:.4}; modes {}; Euler h = 0.0001 {}", cs[0] * lams[0].exp(), cs[1] * lams[1].exp(), vec(tt(1.0), 4), vec(eu1, 4));
    println!("Euler error in T1 at 1 h, h = 0.01, 0.005, 0.0025: {:.5} {:.5} {:.5} ; ratios {:.3} {:.3}", errs[0], errs[1], errs[2], errs[0] / errs[1], errs[1] / errs[2]);
    println!("average {:.0} e^-t, half-life {:.3} h; difference {:.0} e^-3t, half-life {:.3} h", cs[0], 2f64.ln(), 2.0 * cs[1], 2f64.ln() / 3.0);
    println!("rooms within 1 C of each other at ln 20 / 3 = {:.3} h; average within 1 C of outside at ln 20 = {:.3} h", 20f64.ln() / 3.0, 20f64.ln());
    println!("room 2 peak: formula t = ln 1.5 / 2 = {:.4} h, {:.3} C; Euler {:.4} h, {:.3} C", tp, tt(tp)[1], pk.0, pk.1);
    let path: Vec<String> = fig.iter().map(|&t| format!("{:.1},{:.1}", 50.0 + 9.0 * tt(t)[0], 170.0 - 9.0 * tt(t)[1])).collect();
    println!("figure, path at 9 px per C, origin (50, 170): {}", path.join(" "));
    let (lb, vb) = eigen(b); // second case: room 2 half the size
    let cb = fit(vb, x0);
    println!("half-size room: eigenvalues {:.0}, {:.0}; eigenvectors {}, {}; weights {:.3}, {:.3}", lb[0], lb[1], vec(vb[0], 0), vec(vb[1], 0), cb[0], cb[1]);
    println!("half-size room at 1 h: modes {}; Euler {}", vec(modes(lb, vb, cb, 1.0), 4), vec(euler(b, x0, 1.0, 1e-4), 4));
    let w = [x0[0] + x0[1], x0[0] - x0[1]]; // P times the start, not P inverse
    println!("mistake, P for its inverse: weights {} rebuild the start as {}", vec(w, 0), vec([w[0] + w[1], w[0] - w[1]], 0));
    println!("mistake, rates swapped: T1(1) = {:.4}, not {:.4}", cs[0] * (-3f64).exp() + cs[1] * (-1f64).exp(), tt(1.0)[0]);
    let d: V = [0, 1].map(|k| (x0[0] * vb[k][0] + x0[1] * vb[k][1]) / (vb[k][0].powi(2) + vb[k][1].powi(2)));
    println!("mistake, dot products on the half-size room: weights {} rebuild {}", vec(d, 0), vec([d[0] + d[1], d[0] * vb[0][1] + d[1] * vb[1][1]], 0));
    let (lj, vj) = eigen(j);
    println!("mistake, J: eigenvalues {:.0}, {:.0}, one direction {}; Euler T1(1) = {:.4}, (30 + 10t) e^-t = {:.4}", lj[0], lj[1], vec(vj[0], 0), euler(j, x0, 1.0, 1e-5)[0], 40.0 / std::f64::consts::E);
    for k in 0..2 { assert!(diff(rate(a, vs[k]), [lams[k] * vs[k][0], lams[k] * vs[k][1]]) < 1e-12); } // row 2 agrees too
    assert!(diff(eu1, tt(1.0)) < 1e-3 && (pk.0 - tp).abs() < 1e-4);
    assert!([errs[0] / errs[1], errs[1] / errs[2]].iter().all(|&r| r > 1.8 && r < 2.2)); // Euler is order one
    assert!(diff(euler(b, x0, 1.0, 1e-4), modes(lb, vb, cb, 1.0)) < 1e-3);
    println!("ALL CHECKS PASS");
}
