// The Lorenz system -- the same check as the Python, in Rust, std only; RK4 written out.  Two roads each time:
// formula vs Newton, eigenvalue cubic vs Jacobian trace and det, divergence vs a flowed box, separation vs tangent rate.
const S: f64 = 10.0; const R: f64 = 28.0; const B: f64 = 8.0 / 3.0;
type V = Vec<f64>;
fn fr(p: &[f64], r: f64) -> V { vec![S * (p[1] - p[0]), p[0] * (r - p[2]) - p[1], p[0] * p[1] - B * p[2]] }
fn f(p: &[f64]) -> V { fr(p, R) }
fn jac(p: &[f64]) -> [[f64; 3]; 3] { [[-S, S, 0.0], [R - p[2], -1.0, -p[0]], [p[1], p[0], -B]] }
fn ax(p: &[f64], k: &[f64], c: f64) -> V { (0..p.len()).map(|i| p[i] + c * k[i]).collect() }
fn rk4(g: &dyn Fn(&[f64]) -> V, p0: &[f64], h: f64, n: usize) -> V {   // Runge-Kutta 4, four slopes weighted 1-2-2-1
    let mut p = p0.to_vec();
    for _ in 0..n {
        let k1 = g(&p); let k2 = g(&ax(&p, &k1, h / 2.0)); let k3 = g(&ax(&p, &k2, h / 2.0)); let k4 = g(&ax(&p, &k3, h));
        p = (0..p.len()).map(|i| p[i] + h * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]) / 6.0).collect();
    }
    p
}
fn det(m: &[[f64; 3]; 3]) -> f64 { m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0]) + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0]) }
fn solve(m: &[[f64; 3]; 3], v: &[f64]) -> V { let d = det(m); (0..3).map(|k| { let mut a = *m; for i in 0..3 { a[i][k] = v[i]; } det(&a) / d }).collect() }
fn dist(a: &[f64], b: &[f64]) -> f64 { ((a[0] - b[0]) * (a[0] - b[0]) + (a[1] - b[1]) * (a[1] - b[1]) + (a[2] - b[2]) * (a[2] - b[2])).sqrt() }
fn f6(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn e1(x: f64) -> String { let s = format!("{:.1e}", x); let (m, e) = s.split_once('e').unwrap(); let k: i32 = e.parse().unwrap(); format!("{}e{}{:02}", m, if k < 0 { '-' } else { '+' }, k.abs()) }
fn main() {
    println!("Lorenz system, sigma = 10, rho = 28, beta = 8/3 = {:.6}; RK4 throughout", B);
    let c = (B * (R - 1.0)).sqrt(); let mut cp = vec![8.0, 8.0, 25.0];
    for _ in 0..8 { cp = ax(&cp, &solve(&jac(&cp), &f(&cp)), -1.0); }      // Newton: p -> p - J^-1 F
    println!("lobe centres, formula x^2 = beta (rho - 1) = {:.6}, so (+/-{:.6}, +/-{:.6}, {:.6}); Newton from (8, 8, 25): {}", B * (R - 1.0), c, c, R - 1.0, f6(&cp));
    let (a2, a1, a0) = (S + B + 1.0, B * (S + R), 2.0 * S * B * (R - 1.0)); let (mut lo, mut hi) = (-100.0f64, 0.0f64);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if ((mid + a2) * mid + a1) * mid + a0 < 0.0 { lo = mid } else { hi = mid } }
    let l1 = lo; let re = -(a2 + l1) / 2.0; let im = (a0 / -l1 - re * re).sqrt(); let g = ((S + 1.0) * (S + 1.0) + 4.0 * S * (R - 1.0)).sqrt();
    println!("eigenvalues at the origin, roots of l^2 + {:.0} l - {:.0} and -beta: {}", S + 1.0, S * (R - 1.0), f6(&[(-(S + 1.0) + g) / 2.0, (-(S + 1.0) - g) / 2.0, -B]));
    println!("eigenvalues at a lobe centre: {:.6} and {:.6} +/- {:.6}i; spiral turns outward above rho = {:.6}", l1, re, im, S * (S + B + 3.0) / (S - B - 1.0));
    let jc = jac(&cp); let tr = jc[0][0] + jc[1][1] + jc[2][2]; let q0 = rk4(&f, &[1.0, 1.0, 1.0], 0.001, 10000); let e = 1e-6;
    let mi = jc[0][0] * jc[1][1] - jc[0][1] * jc[1][0] + jc[0][0] * jc[2][2] - jc[0][2] * jc[2][0] + jc[1][1] * jc[2][2] - jc[1][2] * jc[2][1]; let pairs = 2.0 * l1 * re + re * re + im * im;
    println!("Jacobian at Newton's point: trace {:.6}, 2x2 minors {:.6}, det {:.6}; from the roots: sum {:.6}, pairs {:.6}, product {:.6}", tr, mi, det(&jc), l1 + 2.0 * re, pairs, l1 * (re * re + im * im));
    let base = rk4(&f, &q0, 0.001, 500); let mut bx = [[0.0; 3]; 3];
    for (r, u) in [[1.0, 0.0, 0.0], [0.0, 1.0, 0.0], [0.0, 0.0, 1.0]].iter().enumerate() { let d = ax(&rk4(&f, &ax(&q0, u, e), 0.001, 500), &base, -1.0); for i in 0..3 { bx[r][i] = d[i]; } }
    let vol = det(&bx) / (e * e * e);
    println!("box of side 1e-6 at t = 10, after 0.5: volume x {:.6}, exp(0.5 x trace) = {:.6}", vol, (0.5 * tr).exp());
    let (mut a, mut b, mut s) = (vec![1.0, 1.0, 1.0], vec![1.0 + 1e-8, 1.0, 1.0], vec![1.0, 1.0, 1.0]); let (mut sep, mut gap) = (vec![], vec![]);
    for _ in 0..41 {
        sep.push(dist(&a, &b)); gap.push(dist(&a, &s));
        a = rk4(&f, &a, 0.001, 1000); b = rk4(&f, &b, 0.001, 1000); s = rk4(&f, &s, 0.0005, 2000);
    }
    println!("separation at t = 0, 5, ..., 40: {}", (0..41).step_by(5).map(|t| e1(sep[t])).collect::<Vec<_>>().join(" "));
    println!("chart, log10 separation at t = 0, 2, ..., 40: {}", (0..41).step_by(2).map(|t| format!("{:.2}", sep[t].log10())).collect::<Vec<_>>().join(" "));
    println!("step check, h = 0.001 vs 0.0005, gap at t = 10, 20, 25, 30: {}", [10, 20, 25, 30].iter().map(|&t| e1(gap[t])).collect::<Vec<_>>().join(" "));
    let slope = (sep[30].ln() - sep[15].ln()) / 15.0;
    let tan = |s6: &[f64]| -> V { let mut o = f(&s6[..3]); for m in jac(&s6[..3]).iter() { o.push(m[0] * s6[3] + m[1] * s6[4] + m[2] * s6[5]); } o };
    let (mut w, mut v, mut tot) = (rk4(&f, &[1.0, 1.0, 1.0], 0.01, 1000), vec![1.0, 0.0, 0.0], 0.0);
    for _ in 0..500 {                                  // tangent road: stretch a unit arrow, renormalise each unit
        let mut st = w.clone(); st.extend_from_slice(&v); let s6 = rk4(&tan, &st, 0.01, 100); w = s6[..3].to_vec();
        let n = (s6[3] * s6[3] + s6[4] * s6[4] + s6[5] * s6[5]).sqrt(); tot += n.ln(); v = s6[3..].iter().map(|x| x / n).collect();
    }
    let lam = tot / 500.0;
    println!("growth rate: separation slope t = 15..30 {:.6}; tangent over 500 units {:.6}; dimension 2 + {:.4}/{:.4} = {:.4}; 1e-8 to 10 takes {:.2}, one digit {:.2}", slope, lam, lam, lam - tr, 2.0 + lam / (lam - tr), (10.0f64 / 1e-8).ln() / lam, 10f64.ln() / lam);
    let mut p = rk4(&f, &[1.0, 1.0, 1.0], 0.002, 5000); let mut pr = f(&p)[2]; let mut tops: Vec<f64> = vec![];
    for _ in 0..50000 { let q = rk4(&f, &p, 0.002, 1); let d = f(&q)[2]; if pr > 0.0 && 0.0 >= d { tops.push(q[2]) } p = q; pr = d; }   // Poincare section
    let low: Vec<bool> = tops.windows(2).filter(|w| w[0] < 38.5).map(|w| w[1] > w[0]).collect();
    let (mn, mx) = (tops.iter().cloned().fold(f64::INFINITY, f64::min), tops.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    println!("section z' = 0, t = 10..110: {} tops, {:.2} to {:.2}; below 38.5 then higher: {} of {}", tops.len(), mn, mx, low.iter().filter(|&&x| x).count(), low.len());
    println!("first pairs (top > next top): {}", (0..5).map(|i| format!("{:.2}>{:.2}", tops[i], tops[i + 1])).collect::<Vec<_>>().join(" "));
    let mut zbar = vec![];
    for s0 in [[1.0, 1.0, 1.0], [30.0, -40.0, 90.0], [-0.01, 0.0, 0.0]] {   // basin: far and near starts
        let mut q = rk4(&f, &s0, 0.01, 2000); let mut t = 0.0;
        for _ in 0..2000 { q = rk4(&f, &q, 0.01, 10); t += q[2]; }
        zbar.push(t / 2000.0);
    }
    println!("basin: mean z over t = 20..220 from (1,1,1), (30,-40,90), (-0.01,0,0): {}", f6(&zbar));
    println!("mistake, rho = 20: from (1,1,1) at t = 150 {}; formula {:.6}", f6(&rk4(&|s: &[f64]| fr(s, 20.0), &[1.0, 1.0, 1.0], 0.01, 15000)), (B * 19.0).sqrt());
    let mut fig = rk4(&f, &[1.0, 1.0, 1.0], 0.001, 15000); let mut pts = vec![];
    for _ in 0..400 { pts.push(format!("{:.0},{:.0}", 180.0 + 4.0 * fig[0], 220.0 - 4.0 * fig[2])); fig = rk4(&f, &fig, 0.001, 25); }
    println!("figure, x-z plane, 4 units per unit, t = 15 to 25 every 0.025: lobes at {:.1},{:.1} and {:.1},{:.1}; {}", 180.0 - 4.0 * c, 220.0 - 4.0 * (R - 1.0), 180.0 + 4.0 * c, 220.0 - 4.0 * (R - 1.0), pts.join(" "));
    assert!(dist(&cp, &[c, c, R - 1.0]) < 1e-9);                                            // Newton meets the formula
    assert!((mi - pairs).abs() < 1e-6 && (det(&jc) - l1 * (re * re + im * im)).abs() < 1e-6);         // matrix meets the cubic's roots
    assert!((vol - (0.5 * tr).exp()).abs() < 1e-5);                                          // flowed box shrinks at the divergence
    assert!((slope - lam).abs() < 0.1);                                                      // two roads to the growth rate
    println!("ALL CHECKS PASS");
}
