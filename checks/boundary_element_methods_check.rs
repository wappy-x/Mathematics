// Boundary elements -- the check behind the card.  Rust std only, no crates.
// A heated duct: the inside of an ellipse with semi-axes 2 m and 1 m, rim
// temperature g = x^2 - y^2 (degrees above ambient), exact u = x^2 - y^2.
// Roads: (1) Nystrom with the trapezoid rule, (2) flat-panel collocation,
// (3) a finite-difference grid on the same region, (4) GMRES against
// elimination, all read against the exact harmonic function at (0.5, 0.3).
use std::{collections::HashMap, f64::consts::PI};
const TAU: f64 = 2.0 * PI; const A: f64 = 2.0; const B: f64 = 1.0; const PX: P = (0.5, 0.3);
type P = (f64, f64); type Mat = Vec<Vec<f64>>; type F = fn(f64, f64) -> f64;
type Node = (P, P, f64, f64); // rim point, outward unit normal, speed, curvature
fn g1(x: f64, y: f64) -> f64 { x * x - y * y } fn g2(x: f64, y: f64) -> f64 { x.exp() * y.cos() } // duct; second test
fn ell(t: f64) -> Node {
    let j = (A * A * t.sin().powi(2) + B * B * t.cos().powi(2)).sqrt();
    ((A * t.cos(), B * t.sin()), (B * t.cos() / j, A * t.sin() / j), j, A * B / (j * j * j))
}
fn dk(x: P, y: P, n: P) -> f64 { let (dx, dy) = (x.0 - y.0, x.1 - y.1); (dx * n.0 + dy * n.1) / (dx * dx + dy * dy) / TAU }
fn solve(m0: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Mat = m0.iter().enumerate().map(|(i, r)| { let mut v = r.clone(); v.push(b[i]); v }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, r| if m[r][c].abs() > m[p][c].abs() { r } else { p });
        m.swap(c, p);
        for r in c + 1..n { let f = m[r][c] / m[c][c]; for k in c..=n { m[r][k] -= f * m[c][k]; } }
    }
    let mut x = vec![0.0; n];
    for r in (0..n).rev() { x[r] = (m[r][n] - (r + 1..n).map(|k| m[r][k] * x[k]).sum::<f64>()) / m[r][r]; }
    x
}
fn nystrom(n: usize, g: F, half: f64, diag: bool) -> (Mat, Vec<f64>, Vec<Node>) { // half*I + K, data, nodes
    let nd: Vec<Node> = (0..n).map(|j| ell(TAU * j as f64 / n as f64)).collect();
    let mut m = vec![vec![0.0; n]; n];
    for (i, &(xi, _, _, _)) in nd.iter().enumerate() {
        for (j, &(yj, nj, jj, kj)) in nd.iter().enumerate() {
            let kern = if i == j { if diag { -kj / (2.0 * TAU) } else { 0.0 } } else { dk(xi, yj, nj) };
            m[i][j] = kern * jj * TAU / n as f64 + if i == j { half } else { 0.0 };
        }
    }
    let b = nd.iter().map(|q| g(q.0 .0, q.0 .1)).collect(); (m, b, nd)
}
fn ny_eval(nd: &[Node], mu: &[f64], x: P) -> f64 { nd.iter().zip(mu).map(|(q, m)| dk(x, q.0, q.1) * m * q.2 * TAU / nd.len() as f64).sum() }
fn ny_x(n: usize, g: F, x: P, half: f64, diag: bool) -> f64 { let (m, b, nd) = nystrom(n, g, half, diag); ny_eval(&nd, &solve(&m, &b), x) }
fn ny_u(n: usize, g: F) -> f64 { ny_x(n, g, PX, -0.5, true) }
fn angle(x: P, p: P, q: P) -> f64 { // signed angle that the panel p -> q subtends at x
    let (ax, ay, bx, by) = (p.0 - x.0, p.1 - x.1, q.0 - x.0, q.1 - x.1); (ax * by - ay * bx).atan2(ax * bx + ay * by)
}
fn panel_u(n: usize, g: F) -> f64 { // N flat panels, constant density, midpoint collocation
    let v: Vec<P> = (0..=n).map(|j| ell(TAU * j as f64 / n as f64).0).collect();
    let mid: Vec<P> = (0..n).map(|j| ((v[j].0 + v[j + 1].0) / 2.0, (v[j].1 + v[j + 1].1) / 2.0)).collect();
    let m: Mat = (0..n).map(|i| (0..n).map(|j| if i == j { -0.5 } else { -angle(mid[i], v[j], v[j + 1]) / TAU }).collect()).collect();
    let b: Vec<f64> = (0..n).map(|j| { let p = ell(TAU * (j as f64 + 0.5) / n as f64).0; g(p.0, p.1) }).collect();
    let mu = solve(&m, &b); (0..n).map(|j| -angle(PX, v[j], v[j + 1]) / TAU * mu[j]).sum()
}
fn gmres(m: &[Vec<f64>], b: &[f64], tol: f64) -> (usize, Vec<f64>) { // GMRES from zero
    let n = b.len(); let beta = b.iter().map(|v| v * v).sum::<f64>().sqrt();
    let mut q: Mat = vec![b.iter().map(|v| v / beta).collect()]; let mut hs: Mat = vec![];
    for k in 1..=n {
        let last = q.last().unwrap().clone(); let mut h = vec![];
        let mut w: Vec<f64> = (0..n).map(|i| (0..n).map(|j| m[i][j] * last[j]).sum()).collect();
        for qq in &q {
            let c: f64 = w.iter().zip(qq).map(|(a, e)| a * e).sum(); h.push(c);
            w = w.iter().zip(qq).map(|(a, e)| a - c * e).collect();
        }
        let nw = w.iter().map(|v| v * v).sum::<f64>().sqrt(); h.push(nw); hs.push(h); q.push(w.iter().map(|v| v / nw).collect());
        let hh: Mat = (0..=k).map(|r| (0..k).map(|c| if r < hs[c].len() { hs[c][r] } else { 0.0 }).collect()).collect();
        let nm: Mat = (0..k).map(|a| (0..k).map(|c| (0..=k).map(|r| hh[r][a] * hh[r][c]).sum()).collect()).collect();
        let y = solve(&nm, &(0..k).map(|a| beta * hh[0][a]).collect::<Vec<_>>()); // normal equations
        let x: Vec<f64> = (0..n).map(|i| (0..k).map(|c| q[c][i] * y[c]).sum()).collect();
        let res = (0..n).map(|i| (b[i] - (0..n).map(|j| m[i][j] * x[j]).sum::<f64>()).powi(2)).sum::<f64>().sqrt() / beta;
        if res < tol { return (k, x); }
    }
    panic!("GMRES did not converge")
}
fn inside(i: i64, j: i64, h: f64) -> bool { let (a, b) = (i as f64 * h / A, j as f64 * h / B); a * a + b * b < 1.0 - 1e-12 }
fn grid_pts(h: f64) -> Vec<(i64, i64)> {
    let (ii, jm) = ((A / h) as i64 + 1, (B / h) as i64 + 1);
    (-ii..=ii).flat_map(|i| (-jm..=jm).map(move |j| (i, j))).filter(|&(i, j)| inside(i, j, h)).collect()
}
fn grid_u(h: f64, g: F, omega: f64) -> (f64, usize, usize, usize) { // 5-point grid, Shortley-Weller arms, SOR
    let pts = grid_pts(h); let idx: HashMap<(i64, i64), usize> = pts.iter().enumerate().map(|(k, &p)| (p, k)).collect();
    let (mut u, mut nnz, mut arms) = (vec![0.0; pts.len()], pts.len(), vec![]);
    for &(i, j) in &pts {
        let mut a: Vec<(f64, Option<usize>, f64)> = vec![];
        for (di, dj) in [(1i64, 0i64), (-1, 0), (0, 1), (0, -1)] {
            if inside(i + di, j + dj, h) { a.push((h, Some(idx[&(i + di, j + dj)]), 0.0)); nnz += 1; continue; }
            let (x0, y0, fi, fj) = (i as f64 * h, j as f64 * h, di as f64, dj as f64); // distance s to the rim
            let (qa, qb) = (fi * fi / (A * A) + fj * fj / (B * B), 2.0 * (x0 * fi / (A * A) + y0 * fj / (B * B)));
            let qc = x0 * x0 / (A * A) + y0 * y0 / (B * B) - 1.0;
            let s = (-qb + (qb * qb - 4.0 * qa * qc).sqrt()) / (2.0 * qa);
            a.push((s, None, g(x0 + s * fi, y0 + s * fj)));
        }
        arms.push(a);
    }
    let mut sweep = 0;
    for sw in 1..100000 {
        sweep = sw; let mut change: f64 = 0.0;
        for k in 0..pts.len() {
            let a = &arms[k]; let val = |t: &(f64, Option<usize>, f64)| match t.1 { Some(p) => u[p], None => t.2 };
            let (se, sw_, sn, ss) = (a[0].0, a[1].0, a[2].0, a[3].0);
            let (we, ww, wn, ws) = (1.0 / (se * (se + sw_)), 1.0 / (sw_ * (se + sw_)), 1.0 / (sn * (sn + ss)), 1.0 / (ss * (sn + ss)));
            let new = (we * val(&a[0]) + ww * val(&a[1]) + wn * val(&a[2]) + ws * val(&a[3])) / (we + ww + wn + ws);
            change = change.max((new - u[k]).abs()); u[k] += omega * (new - u[k]);
        }
        if change < 1e-13 { break; }
    }
    (u[idx[&((PX.0 / h).round() as i64, (PX.1 / h).round() as i64)]], pts.len(), nnz, sweep)
}
fn e(v: f64) -> String { // Python's "%.1e"
    let s = format!("{:.1e}", v); let (m, x) = s.split_once('e').unwrap(); let x: i32 = x.parse().unwrap();
    format!("{}e{}{:02}", m, if x < 0 { '-' } else { '+' }, x.abs())
}
fn row(v: &[f64], f: fn(f64) -> String) -> String { v.iter().map(|x| format!(" {}", f(*x))).collect::<Vec<_>>().join(",") }

fn main() {
    println!("duct: ellipse 2 m by 1 m, rim temperature x^2 - y^2 K, read at (0.5, 0.3) m");
    println!("exact u = 0.25 - 0.09 = {:.6} K", g1(PX.0, PX.1));
    let (m, b, nd) = nystrom(8, g1, -0.5, true); let (n0, n2) = (nd[0], nd[2]);
    println!("N=8, row 0 of -I/2 + K:{}", row(&m[0], |v| format!("{:.6}", v)));
    println!("N=8, row 0 adds up to {:.6} (the double layer of 1 is -1 inside)", m[0].iter().sum::<f64>());
    println!("N=8, data at nodes 0 and 2: {:.6}, {:.6}; weight at node 0: {:.6}", b[0], b[2], TAU / 8.0);
    println!("N=8, node 2 weight {:.6}; kernel from node 2 at node 0 {:.6}; node 0 curvature {:.6}, self-pull {:.6}; N=64 spacing at node 0 {:.6} m",
             n2.2 * TAU / 8.0, dk(n0.0, n2.0, n2.1), n0.3, -n0.3 / (2.0 * TAU) * n0.2 * TAU / 8.0, n0.2 * TAU / 64.0);
    let mu = solve(&m, &b); println!("N=8, density mu at nodes 0, 1, 2: {:.6}, {:.6}, {:.6}", mu[0], mu[1], mu[2]);
    let (mut ny, mut pa) = (HashMap::new(), HashMap::new());
    for n in [8, 16, 32, 64] {
        ny.insert(n, (ny_u(n, g1) - 0.16).abs()); pa.insert(n, (panel_u(n, g1) - 0.16).abs());
        println!("N={}: Nystrom error {} K, panels error {} K", n, e(ny[&n]), e(pa[&n]));
    }
    for n in [128, 256] { pa.insert(n, (panel_u(n, g1) - 0.16).abs()); println!("N={}: panels error {} K", n, e(pa[&n])); }
    let order = (pa[&128] / pa[&256]).log2();
    println!("panel order, log2 of the error ratio from 128 to 256: {:.2}", order);
    println!("Nystrom N=64 gives u = {:.6} K", ny_u(64, g1));
    assert!(ny[&64] < 1e-9 && ny[&32] < 1e-4 && 1e-4 < ny[&16] && 1.9 < order && order < 2.1); // exponential; a power
    let lg = |v: f64| format!("{:.2}", v.log10()); println!("chart,N, 8, 16, 32, 64");
    println!("chart,log10 error Nystrom,{}", row(&[8, 16, 32, 64].map(|n| ny[&n]), lg));
    println!("chart,log10 error panels,{}", row(&[8, 16, 32, 64].map(|n| pa[&n]), lg));

    let ex = 0.5f64.exp() * 0.3f64.cos(); println!("second test: rim data e^x cos y, exact u at (0.5, 0.3) = {:.6}", ex);
    for n in [16, 32, 64] { println!("Nystrom N={}: error {}", n, e((ny_u(n, g2) - ex).abs())); }
    let mut last = (0, 0.0, 0.0);
    for n in [16, 32, 64, 128] {
        let (m, b, nd) = nystrom(n, g2, -0.5, true); let (k, x) = gmres(&m, &b, 1e-10);
        println!("GMRES N={}: {} steps to residual 1e-10", n, k);
        last = (k, ny_eval(&nd, &x, PX), ny_eval(&nd, &solve(&m, &b), PX));
    }
    assert!(last.0 <= 10 && (last.1 - last.2).abs() < 1e-9); // GMRES = elimination
    let p: f64 = (0..1000).map(|j| ell(TAU * j as f64 / 1000.0).2 * TAU / 1000.0).sum();
    println!("rim length {:.6} m; dense matrix N=32: {} entries", p, 32 * 32);
    let mut gr = vec![];
    for (h, om) in [(0.1, 1.7), (0.05, 1.8), (0.025, 1.9)] {
        let (v, n, nnz, sw) = grid_u(h, g2, om); gr.push((v - ex).abs());
        println!("grid h={:.3} m: {} unknowns, {} nonzeros, {} sweeps, error {}", h, n, nnz, sw, e(gr[gr.len() - 1]));
    }
    let go = (gr[1] / gr[2]).log2(); println!("grid order, log2 of the error ratio from h=0.05 to 0.025: {:.2}", go);
    assert!(1.8 < go && go < 2.2 && gr[2] > 10.0 * (ny_u(32, g2) - ex).abs());
    let v = grid_u(0.1, g1, 1.7).0; println!("grid h=0.1 on x^2 - y^2: u = {:.6} K, exact on quadratics", v); assert!((v - 0.16).abs() < 1e-11);
    for n in [32, 64] { println!("grid with spacing = rim length / {}: {} unknowns", n, grid_pts(p / n as f64).len()); }

    println!("near the rim, N=64, points (2 - d, 0): error in K, against the exact (2 - d)^2");
    for d in [0.25, 0.1, 0.05, 0.02] {
        let x: P = (2.0 - d, 0.0);
        println!("d={:.2} m: u exact {:.4}, error {}", d, x.0 * x.0, e((ny_x(64, g1, x, -0.5, true) - x.0 * x.0).abs()));
    }
    assert!((ny_x(64, g1, (1.98, 0.0), -0.5, true) - 1.98 * 1.98).abs() > 1.0);
    println!("what breaks");
    for n in [32, 64] { println!("curvature diagonal dropped, N={}: error {}", n, e((ny_x(n, g1, PX, -0.5, false) - 0.16).abs())); }
    assert!((ny_x(64, g1, PX, -0.5, false) - 0.16).abs() > 1e5 * ny[&64]);
    let ok = nystrom(32, g1, 0.5, true).0.iter().map(|r| r.iter().sum::<f64>().abs()).fold(0.0, f64::max) < 1e-12;
    println!("sign flipped, +I/2 + K, N=32: every row sums to 0 within 1e-12: {}", if ok { "yes" } else { "no" });
    println!("ALL CHECKS PASS");
}
