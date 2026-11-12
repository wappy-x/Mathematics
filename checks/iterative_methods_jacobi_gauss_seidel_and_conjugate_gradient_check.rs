// Iterating instead of factoring -- the check behind the card.  std only; nothing used holds an
// answer.  A 10-by-25 grid of junctions joined by 465 pipes, fed by 35 more pipes from a main at
// 50 m: 500 pipes, 250 unknown pressure heads.  Each pipe passes 1 L/s per metre of head
// difference; customers draw 0.1 L/s per metre of head (illustrative numbers).
use std::f64::consts::PI;
const R: usize = 10; const C: usize = 25; const H0: f64 = 50.0; const DRAW: f64 = 0.1;
const TOL: f64 = 1e-8; const CHART: usize = 480;
struct Sys { off: Vec<Vec<(usize, f64)>>, diag: Vec<f64>, b: Vec<f64> }
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut s = 0.0; for i in 0..u.len() { s += u[i] * v[i]; } s } // plain left-to-right sum
fn ax(m: &Sys, x: &[f64]) -> Vec<f64> {
    (0..x.len()).map(|i| { let mut s = m.diag[i] * x[i]; for &(j, a) in &m.off[i] { s += a * x[j]; } s }).collect()
}
fn sweep(m: &Sys, x: &[f64], w: f64, gs: bool) -> Vec<f64> { // one Jacobi (gs false) or Gauss-Seidel/SOR sweep
    let src = x.to_vec(); let mut new = if gs { x.to_vec() } else { vec![0.0; x.len()] };
    for i in 0..x.len() {
        let mut s = m.b[i];
        for &(j, a) in &m.off[i] { s -= a * if gs { new[j] } else { src[j] }; }
        new[i] = x[i] + w * (s / m.diag[i] - x[i]);
    }
    new
}
fn cholesky_solve(m: &Sys) -> Vec<f64> { // road 1, the direct solve: dense L L^T, then two sweeps
    let n = m.b.len(); let mut a = vec![vec![0.0; n]; n];
    for i in 0..n { a[i][i] = m.diag[i]; for &(j, v) in &m.off[i] { a[i][j] = v; } }
    let (mut l, mut y, mut x) = (vec![vec![0.0; n]; n], vec![0.0; n], vec![0.0; n]);
    for j in 0..n {
        let mut s = a[j][j]; for k in 0..j { s -= l[j][k] * l[j][k]; } l[j][j] = s.sqrt();
        for i in j + 1..n { let mut t = a[i][j]; for k in 0..j { t -= l[i][k] * l[j][k]; } l[i][j] = t / l[j][j]; }
    }
    for i in 0..n { let mut s = m.b[i]; for k in 0..i { s -= l[i][k] * y[k]; } y[i] = s / l[i][i]; }
    for i in (0..n).rev() { let mut s = y[i]; for k in i + 1..n { s -= l[k][i] * x[k]; } x[i] = s / l[i][i]; }
    x
}
fn sci(x: f64) -> String { format!("{:.3e}", x) }
fn comma(k: usize) -> String {
    let (s, mut out) = (k.to_string(), String::new());
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); } out.push(ch); }
    out
}
fn mu(m: usize, k: usize) -> f64 { 2.0 - 2.0 * (((2 * k - 1) as f64) * PI / ((2 * m + 1) as f64)).cos() }
fn main() {
    let n = R * C;
    let (mut off, mut diag, mut b, mut pipes) = (vec![Vec::new(); n], vec![DRAW; n], vec![0.0; n], 0);
    for r in 0..R { for c in 0..C {
        let i = r * C + c;
        for (rr, cc) in [(r, c + 1), (r + 1, c)] {
            if rr < R && cc < C {
                let j = rr * C + cc; off[i].push((j, -1.0)); off[j].push((i, -1.0));
                diag[i] += 1.0; diag[j] += 1.0; pipes += 1;
            }
        }
        for fed in [r == 0, c == 0] { if fed { diag[i] += 1.0; b[i] += H0; pipes += 1; } } // pipes from the main
    } }
    let nnz = n + off.iter().map(|o| o.len()).sum::<usize>();
    let m = Sys { off, diag, b };
    let xs = cholesky_solve(&m); let ones = vec![1.0; n];
    let (bn, xn) = (dot(&m.b, &m.b).sqrt(), dot(&xs, &xs).sqrt());
    let err = |x: &[f64]| (0..n).map(|i| (x[i] - xs[i]).abs()).fold(0.0, f64::max);
    let ena = |x: &[f64]| { let e: Vec<f64> = (0..n).map(|i| x[i] - xs[i]).collect(); dot(&e, &ax(&m, &e)).sqrt() };
    let rel2 = |x: &[f64]| { let e: Vec<f64> = (0..n).map(|i| x[i] - xs[i]).collect(); dot(&e, &e).sqrt() / xn };
    let relres = |x: &[f64]| { let r: Vec<f64> = ax(&m, x).iter().enumerate().map(|(i, t)| m.b[i] - t).collect(); dot(&r, &r).sqrt() / bn };
    let stationary = |w: f64, gs: bool, steps: usize, stop: f64| {
        let (mut x, mut k, mut hist) = (vec![0.0; n], 0usize, vec![vec![0.0; n]]);
        while (if steps > 0 { k < steps } else { relres(&x) > TOL }) && k < 20000 {
            let old = x.clone(); x = sweep(&m, &x, w, gs); k += 1; hist.push(x.clone());
            if stop > 0.0 && (0..n).map(|i| (x[i] - old[i]).abs()).fold(0.0, f64::max) < stop { break; }
        }
        (k, x, hist)
    };
    let cg = |steps: usize| {
        let (mut x, mut r) = (vec![0.0; n], m.b.clone());
        let (mut d, mut rr, mut k, mut hist) = (r.clone(), dot(&r, &r), 0usize, vec![vec![0.0; n]]);
        while (if steps > 0 { k < steps } else { rr.sqrt() / bn > TOL }) && k < 20000 {
            let ad = ax(&m, &d); let al = rr / dot(&d, &ad);
            x = (0..n).map(|i| x[i] + al * d[i]).collect(); r = (0..n).map(|i| r[i] - al * ad[i]).collect();
            let rn = dot(&r, &r); d = (0..n).map(|i| r[i] + rn / rr * d[i]).collect(); rr = rn; k += 1; hist.push(x.clone());
        }
        (k, x, hist)
    };
    let (j1, g1) = (sweep(&m, &vec![0.0; n], 1.0, false), sweep(&m, &vec![0.0; n], 1.0, true));
    let wts: Vec<f64> = (0..n).map(|i| if i == 0 { 2.0 } else if i < C || i % C == 0 { 1.0 } else { 0.0 }).collect();
    let inflow = dot(&wts, &xs.iter().map(|t| H0 - t).collect::<Vec<_>>());
    println!("network: {} junctions, {} pipes, {} nonzeros of {} ({:.2}%), diagonal {:.1} to {:.1}", n, pipes, nnz, n * n, 100.0 * nnz as f64 / (n * n) as f64,
             m.diag.iter().fold(f64::MAX, |a, &b| a.min(b)), m.diag.iter().fold(0.0, |a: f64, &b| a.max(b)));
    println!("Jacobi sweep 1 at (0,0) (0,1) (1,0) (1,1): {:.6} {:.6} {:.6} {:.6}", j1[0], j1[1], j1[C], j1[C + 1]);
    println!("Gauss-Seidel sweep 1 at the same four:    {:.6} {:.6} {:.6} {:.6}", g1[0], g1[1], g1[C], g1[C + 1]);
    println!("settled heads, m: corner (0,0) {:.6}  far corner {:.6}  mean {:.6}", xs[0], xs[n - 1], dot(&xs, &ones) / n as f64);
    println!("mass balance, L/s: in from the main {:.6}  drawn by customers {:.6}", inflow, DRAW * dot(&xs, &ones));
    let mut xsp = vec![0.0; n]; // road 2: the spectral theorem, eigenvectors in closed form
    for kc in 1..=C { for kr in 1..=R {
        let mut q = Vec::new();
        for r in 0..R { for c in 0..C {
            q.push((((2 * kc - 1) as f64) * PI * ((c + 1) as f64) / ((2 * C + 1) as f64)).sin()
                * (((2 * kr - 1) as f64) * PI * ((r + 1) as f64) / ((2 * R + 1) as f64)).sin());
        } }
        let cf = dot(&q, &m.b) / (dot(&q, &q) * (mu(C, kc) + mu(R, kr) + DRAW));
        for i in 0..n { xsp[i] += cf * q[i]; }
    } }
    println!("spectral road: corner {:.6}  far corner {:.6}  agrees with Cholesky to 1e-10: {}", xsp[0], xsp[n - 1], if err(&xsp) < 1e-10 { "yes" } else { "no" });
    let (lmin, lmax) = (mu(C, 1) + mu(R, 1) + DRAW, mu(C, C) + mu(R, R) + DRAW);
    let kap = lmax / lmin; let rcg = (kap.sqrt() - 1.0) / (kap.sqrt() + 1.0);
    let qd = (0..n).map(|i| m.off[i].iter().map(|&(_, a)| a.abs()).sum::<f64>() / m.diag[i]).fold(0.0, f64::max);
    let z = Sys { off: m.off.clone(), diag: m.diag.clone(), b: vec![0.0; n] }; // rho of the Jacobi matrix G, by power iteration
    let mut v = vec![1.0; n];
    for _ in 0..3000 { v = sweep(&z, &v, 1.0, false); let s = dot(&v, &v).sqrt(); v = v.iter().map(|t| t / s).collect(); }
    let g2 = sweep(&z, &sweep(&z, &v, 1.0, false), 1.0, false); let rhoj = dot(&g2, &g2).sqrt().sqrt();
    let wy = 2.0 / (1.0 + (1.0 - rhoj * rhoj).sqrt());
    println!("lambda min {:.6}  max {:.6}  kappa {:.4}  sqrt kappa {:.4}  CG factor {:.4}", lmin, lmax, kap, kap.sqrt(), rcg);
    println!("dominance q {:.6}  rho Jacobi {:.6}  rho^2 {:.6}  Young omega {:.4}", qd, rhoj, rhoj * rhoj, wy);
    let (fj, fcg) = (2 * (nnz - n) + n, (2 * nnz - n) + 2 * (2 * n - 1) + 3 * 2 * n + 2);
    let scan: Vec<(f64, usize)> = (10..20).map(|w| (w as f64 / 10.0, stationary(w as f64 / 10.0, true, 0, 0.0).0)).collect();
    let mut wb = scan[0]; for &s in &scan { if s.1 < wb.1 { wb = s; } }
    let runs = [("Jacobi".to_string(), stationary(1.0, false, 0, 0.0), fj), ("Gauss-Seidel".to_string(), stationary(1.0, true, 0, 0.0), fj),
        (format!("SOR omega {:.1}", wb.0), stationary(wb.0, true, 0, 0.0), fj + 3 * n), ("conjugate gradient".to_string(), cg(0), fcg)];
    for (name, (k, x, _), f) in &runs {
        println!("{:<19} steps {:>4}  flops {:>9}  max error {:>9} m  rel residual {}", name, k, comma(k * f), sci(err(x)), sci(relres(x)));
    }
    println!("flops: dense Cholesky {}; per step: sweep {}, SOR {}, CG {}; Cholesky / CG {:.1}", comma((2 * n * n * n + 3 * n * n + n) / 6), comma(fj), comma(fj + 3 * n), comma(fcg),
             ((2 * n * n * n + 3 * n * n + n) / 6) as f64 / (runs[3].1 .0 * fcg) as f64);
    let band = |p: usize| -> usize { (0..n).map(|j| (j..=(j + p).min(n - 1)).map(|i| 2 * (j - i.saturating_sub(p)) + 1).sum::<usize>()).sum::<usize>()
        + 2 * (0..n).map(|i| 2 * i.min(p) + 1).sum::<usize>() }; // band Cholesky + two solves, half-bandwidth p
    let cgf = (runs[3].1 .0 * fcg) as f64;
    println!("flops: band Cholesky and two solves, half-bandwidth {} (row by row) {}, {} (column by column) {}; CG / band {:.2}, {:.2}", C, comma(band(C)), R, comma(band(R)),
             cgf / band(C) as f64, cgf / band(R) as f64);
    println!("SOR scan, omega:steps {}", scan.iter().map(|(w, k)| format!("{:.1}:{}", w, k)).collect::<Vec<_>>().join(" "));
    let (hj, hg, hc) = (&runs[0].1 .2, &runs[1].1 .2, &runs[3].1 .2);
    let (e0, a0) = (err(&vec![0.0; n]), ena(&vec![0.0; n]));
    for k in [100, 200, 300, 400] {
        let (t, bd) = (err(&hj[k]), qd.powi(k as i32) * e0);
        println!("Jacobi sweep {}: true max error {} m  bound q^k e0 {} m  ratio {:.1}", k, sci(t), sci(bd), bd / t);
    }
    for k in [10, 20, 30, 40, 50] {
        let (t, bd) = (ena(&hc[k]), 2.0 * rcg.powi(k as i32) * a0);
        println!("CG step {}: true A-norm error {}  bound {}  ratio {:.1}", k, sci(t), sci(bd), bd / t);
    }
    let obs = ((err(&hj[400]) / err(&hj[300])).powf(0.01), (err(&hg[200]) / err(&hg[100])).powf(0.01), (ena(&hc[50]) / ena(&hc[10])).powf(0.025));
    println!("observed factor per step: Jacobi {:.4}  Gauss-Seidel {:.4}  CG {:.4}", obs.0, obs.1, obs.2);
    let xc = &runs[3].1 .1; let rc: Vec<f64> = ax(&m, xc).iter().enumerate().map(|(i, t)| m.b[i] - t).collect(); let e2 = rel2(xc) * xn;
    println!("CG certificate: |error| {} <= |residual| / lambda min {}  ratio {:.1}", sci(e2), sci(dot(&rc, &rc).sqrt() / lmin), dot(&rc, &rc).sqrt() / lmin / e2);
    println!("CG forward: rel error {} <= kappa x rel residual {}  ratio {:.1}", sci(rel2(xc)), sci(kap * relres(xc)), kap * relres(xc) / rel2(xc));
    let (fjc, fgc, fcc) = (stationary(1.0, false, CHART, 0.0).2, stationary(1.0, true, CHART, 0.0).2, cg(CHART).2);
    for k in (0..=CHART).step_by(40) {
        println!("figure, step {}, log10 max error J {:.2} GS {:.2} CG {:.2}", k, err(&fjc[k]).log10(), err(&fgc[k]).log10(), err(&fcc[k]).log10());
    }
    let (ks, xstop, hs) = stationary(1.0, false, 0, 1e-3);
    let mv = (0..n).map(|i| (hs[hs.len() - 1][i] - hs[hs.len() - 2][i]).abs()).fold(0.0, f64::max);
    println!("wrong: stop Jacobi when a sweep moves < 1e-3 m: sweep {}, true max error {:.6} m; last move {:.6} m x rho/(1-rho) {:.4} = {:.6} m",
             ks, err(&xstop), mv, rhoj / (1.0 - rhoj), mv * rhoj / (1.0 - rhoj));
    let t = Sys { off: vec![vec![(1, 0.8), (2, 0.8)], vec![(0, 0.8), (2, 0.8)], vec![(0, 0.8), (1, 0.8)]], diag: vec![1.0; 3], b: vec![2.6; 3] };
    let (mut tj, mut tg, mut tp) = (vec![0.0; 3], vec![0.0; 3], vec![0.0; 3]);
    for _ in 0..30 { tp = tj.clone(); tj = sweep(&t, &tj, 1.0, false); tg = sweep(&t, &tg, 1.0, true); }
    let worst = |u: &[f64]| u.iter().map(|v| (v - 1.0).abs()).fold(0.0, f64::max);
    let (ej, eg, ep) = (worst(&tj), worst(&tg), worst(&tp));
    let ev: Vec<(Vec<f64>, f64)> = [vec![1.0; 3], vec![1.0, -1.0, 0.0], vec![1.0, 1.0, -2.0]].into_iter()
        .map(|v| { let l = dot(&v, &ax(&t, &v)) / dot(&v, &v); (v, l) }).collect(); // three eigenvectors
    println!("3x3: eigenvalues {} at (1,1,1) (1,-1,0) (1,1,-2); Jacobi error grows {:.4} per sweep",
             ev.iter().map(|(_, l)| format!("{:.1}", l)).collect::<Vec<_>>().join(" "), ej / ep);
    println!("wrong: Jacobi on [[1,.8,.8],[.8,1,.8],[.8,.8,1]], 30 sweeps: error {:.1}; Gauss-Seidel {}", ej, sci(eg));
    assert!(err(&xsp) < 1e-10 && (inflow - DRAW * dot(&xs, &ones)).abs() < 1e-9); // roads 1 and 2 agree; water balances
    assert!(runs.iter().all(|(_, (_, x, _), _)| relres(x) <= TOL && rel2(x) <= kap * relres(x)));
    assert!((0..hj.len()).all(|k| qd.powi(k as i32) * e0 >= err(&hj[k]))); // dominance bound, every sweep
    assert!((0..hc.len()).all(|k| 2.0 * rcg.powi(k as i32) * a0 >= ena(&hc[k]))); // CG bound, every step
    assert!(rhoj < qd && (obs.0 - rhoj).abs() < 2e-3 && (obs.1 - rhoj * rhoj).abs() < 2e-3 && (wy - wb.0).abs() < 0.05);
    assert!(e2 <= dot(&rc, &rc).sqrt() / lmin && runs[3].1 .0 < runs[1].1 .0 && runs[1].1 .0 < runs[0].1 .0);
    assert!(band(n - 1) == (2 * n * n * n + 3 * n * n + n) / 6 + 2 * n * n); // full band = the dense count, plus two solves
    assert!(err(&xstop) > 10.0 * 1e-3 && ej > 1e3 && eg < 1e-3
        && ev.iter().all(|(v, l)| *l > 0.0 && ax(&t, v).iter().zip(v).map(|(a, c)| (a - l * c).abs()).fold(0.0, f64::max) < 1e-12));
    println!("ALL CHECKS PASS");
}
