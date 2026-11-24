// Model reduction -- the same check as minimal_realisations_and_balanced_truncation_check.py, in Rust.
// Standard library only, no crates. Room heated by a radiator: states are temperatures above the
// outside air (degC), x = (pipe water, radiator, room air, walls); input u = heat into the pipe (kW);
// output y = room air (degC). Time in minutes. Capacities in kW*min/degC, links in kW/degC.
type M = Vec<Vec<f64>>;
fn mm(x: &M, y: &M) -> M { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn tr(x: &M) -> M { (0..x[0].len()).map(|j| (0..x.len()).map(|i| x[i][j]).collect()).collect() }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn mv(a: &M, v: &[f64]) -> Vec<f64> { a.iter().map(|r| r.iter().zip(v).map(|(p, q)| p * q).sum()).collect() }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| p * q).sum() }
fn solve(m: &M, b: &[f64]) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = m.len(); let mut a: M = (0..n).map(|i| { let mut r = m[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c; for r in c..n { if a[r][c].abs() > a[p][c].abs() { p = r; } } a.swap(c, p);
        for r in c + 1..n { let f = a[r][c] / a[c][c]; for k in c..=n { a[r][k] -= f * a[c][k]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { let s: f64 = (i + 1..n).map(|k| a[i][k] * x[k]).sum(); x[i] = (a[i][n] - s) / a[i][i]; }
    x
}
fn rank(m: &M) -> usize { // rows reduced one by one, relative tolerance
    let mut a = m.clone(); let big = a.iter().flatten().fold(0.0f64, |s, v| s.max(v.abs())); let mut rk = 0;
    for c in 0..a[0].len() {
        if rk >= a.len() { break; }
        let mut p = rk; for r in rk..a.len() { if a[r][c].abs() > a[p][c].abs() { p = r; } }
        if a[p][c].abs() < 1e-9 * big { continue; }
        a.swap(rk, p);
        for r in rk + 1..a.len() { let f = a[r][c] / a[rk][c]; for k in 0..a[0].len() { a[r][k] -= f * a[rk][k]; } }
        rk += 1;
    }
    rk
}
fn lyap(a: &M, w: &M) -> M { // road 1: solve A X + X A^T + W = 0 as n*n equations
    let n = a.len(); let mut m = vec![vec![0.0; n * n]; n * n];
    for i in 0..n { for j in 0..n { for k in 0..n { m[i*n+j][k*n+j] += a[i][k]; m[i*n+j][i*n+k] += a[j][k]; } } }
    let rhs: Vec<f64> = (0..n * n).map(|q| -w[q / n][q % n]).collect(); let v = solve(&m, &rhs);
    (0..n).map(|i| v[i*n..(i+1)*n].to_vec()).collect()
}
fn gram_by_time(a: &M, b: &[f64], t: f64, h: f64) -> M { // road 2: integral of e^{At} b b^T e^{A^T t}, Simpson
    let n = a.len(); let mut e = eye(n); let mut term = eye(n);
    for k in 1..30 { term = mm(&term, a).iter().map(|r| r.iter().map(|v| v * h / k as f64).collect()).collect(); for i in 0..n { for j in 0..n { e[i][j] += term[i][j]; } } }
    let mut v = b.to_vec(); let mut x = vec![vec![0.0; n]; n]; let nn = (t / h).round() as usize;
    for s in 0..=nn {
        let w = (if s == 0 || s == nn { 1.0 } else if s % 2 == 1 { 4.0 } else { 2.0 }) * h / 3.0;
        for i in 0..n { for j in 0..n { x[i][j] += w * v[i] * v[j]; } } v = mv(&e, &v);
    }
    x
}
fn chol(p: &M) -> M {
    let n = p.len(); let mut l = vec![vec![0.0; n]; n];
    for i in 0..n { for j in 0..=i { let s = p[i][j] - (0..j).map(|k| l[i][k] * l[j][k]).sum::<f64>(); l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] }; } }
    l
}
fn jacobi(s0: &M) -> (Vec<f64>, M) { // eigenvalues and eigenvectors of a symmetric matrix
    let n = s0.len(); let mut s = s0.clone(); let mut v = eye(n);
    for _ in 0..60 { for p in 0..n { for q in p + 1..n {
        let th = 0.5 * (2.0 * s[p][q]).atan2(s[q][q] - s[p][p]); let (c, sn) = (th.cos(), th.sin());
        for m in [&mut s, &mut v] { for k in 0..n { let (x, y) = (m[k][p], m[k][q]); m[k][p] = c * x - sn * y; m[k][q] = sn * x + c * y; } }
        for k in 0..n { let (x, y) = (s[p][k], s[q][k]); s[p][k] = c * x - sn * y; s[q][k] = sn * x + c * y; }
    } } }
    let mut o: Vec<usize> = (0..n).collect(); o.sort_by(|&i, &j| s[j][j].partial_cmp(&s[i][i]).unwrap());
    (o.iter().map(|&i| s[i][i]).collect(), (0..n).map(|k| o.iter().map(|&i| v[k][i]).collect()).collect())
}
fn gain(a: &M, b: &[f64], c: &[f64], w: f64) -> (f64, f64) { // G(jw) from the real 2n system for (jwI - A) x = b
    let n = a.len(); let mut m = vec![vec![0.0; 2 * n]; 2 * n];
    for i in 0..n { for j in 0..n { m[i][j] = -a[i][j]; m[n+i][n+j] = -a[i][j]; } m[i][n+i] = -w; m[n+i][i] = w; }
    let mut rhs = b.to_vec(); rhs.extend(vec![0.0; n]); let x = solve(&m, &rhs);
    (dot(c, &x[..n]), dot(c, &x[n..]))
}
struct Room { cp: f64, cr: f64, ca: f64, cw: f64, gpr: f64, gra: f64, gaw: f64, gwo: f64, gao: f64 }
const BASE: Room = Room { cp: 0.1, cr: 1.0, ca: 1.0, cw: 50.0, gpr: 0.5, gra: 0.05, gaw: 0.4, gwo: 0.1, gao: 0.02 };
fn room(r: &Room) -> (M, Vec<f64>, Vec<f64>) {
    let a = vec![vec![-r.gpr / r.cp, r.gpr / r.cp, 0.0, 0.0], vec![r.gpr / r.cr, -(r.gpr + r.gra) / r.cr, r.gra / r.cr, 0.0],
        vec![0.0, r.gra / r.ca, -(r.gra + r.gaw + r.gao) / r.ca, r.gaw / r.ca], vec![0.0, 0.0, r.gaw / r.cw, -(r.gaw + r.gwo) / r.cw]];
    (a, vec![1.0 / r.cp, 0.0, 0.0, 0.0], vec![0.0, 0.0, 1.0, 0.0])
}
fn outer(v: &[f64]) -> M { v.iter().map(|x| v.iter().map(|y| x * y).collect()).collect() }
fn hsv(p: &M, q: &M) -> Vec<f64> { let l = chol(p); jacobi(&mm(&mm(&tr(&l), q), &l)).0.iter().map(|e| e.max(0.0).sqrt()).collect() }
fn gramians(a: &M, b: &[f64], c: &[f64]) -> (M, M) { (lyap(a, &outer(b)), lyap(&tr(a), &outer(c))) }
fn balance(a: &M, b: &[f64], c: &[f64], p: &M, q: &M) -> (M, Vec<f64>, Vec<f64>) { // T P T^T = T^-T Q T^-1 = diag(sigma)
    let n = a.len(); let l = chol(p); let (ev, v) = jacobi(&mm(&mm(&tr(&l), q), &l)); let s: Vec<f64> = ev.iter().map(|e| e.powf(0.25)).collect();
    let linv = tr(&(0..n).map(|j| solve(&l, &(0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>())).collect());
    let t: M = mm(&tr(&v), &linv).iter().enumerate().map(|(i, r)| r.iter().map(|x| s[i] * x).collect()).collect();
    let ti: M = mm(&l, &v).iter().map(|r| (0..n).map(|j| r[j] / s[j]).collect()).collect();
    (mm(&mm(&t, a), &ti), mv(&t, b), (0..n).map(|j| (0..n).map(|k| c[k] * ti[k][j]).sum()).collect())
}
fn cut(a: &M, b: &[f64], c: &[f64], r: usize) -> (M, Vec<f64>, Vec<f64>) { (a[..r].iter().map(|row| row[..r].to_vec()).collect(), b[..r].to_vec(), c[..r].to_vec()) }
fn worst(a1: &M, b1: &[f64], c1: &[f64], a2: &M, b2: &[f64], c2: &[f64]) -> (f64, f64) { // H-infinity norm of the difference
    let d = |w: f64| { let (g1, g2) = (gain(a1, b1, c1, w), gain(a2, b2, c2, w)); (g1.0 - g2.0).hypot(g1.1 - g2.1) };
    let ws: Vec<f64> = (0..=600).map(|k| 10f64.powf(-4.0 + 6.0 * k as f64 / 600.0)).collect();
    let mut k = 0; for i in 0..=600 { if d(ws[i]) > d(ws[k]) { k = i; } }
    let (mut lo, mut hi) = (ws[k.saturating_sub(1)], ws[(k + 1).min(600)]);
    for _ in 0..60 { let (m1, m2) = (lo + (hi - lo) * 0.382, lo + (hi - lo) * 0.618); if d(m1) > d(m2) { hi = m2; } else { lo = m1; } }
    if d(0.0) >= d(lo) { (d(0.0), 0.0) } else { (d(lo), lo) }
}
fn step(a: &M, b: &[f64], c: &[f64], ts: &[f64]) -> Vec<f64> { // RK4 on x' = A x + b u, u = 1 kW from t = 0
    let (n, dt) = (a.len(), 0.05); let mut x = vec![0.0; n]; let mut t = 0.0; let mut out = vec![];
    let f = |x: &[f64]| -> Vec<f64> { (0..n).map(|i| dot(&a[i], x) + b[i]).collect() };
    let add = |x: &[f64], k: &[f64], h: f64| -> Vec<f64> { (0..n).map(|i| x[i] + h * k[i]).collect() };
    for &tt in ts {
        while t < tt - 1e-9 { let k1 = f(&x); let k2 = f(&add(&x, &k1, dt / 2.0)); let k3 = f(&add(&x, &k2, dt / 2.0)); let k4 = f(&add(&x, &k3, dt));
            x = (0..n).map(|i| x[i] + dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect(); t += dt; }
        out.push(dot(c, &x));
    }
    out
}
fn dc(a: &M, b: &[f64], c: &[f64]) -> f64 { -dot(c, &solve(a, b)) }
fn f4(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }
fn f6(v: &[f64]) -> String { v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (a, b, c) = room(&BASE); let n = 4;
    // ---- 1. Kalman decomposition: the 5-state draft adds the thermostat bulb (1 min lag), driven by the air, logged by nobody ----
    let mut a5: M = a.iter().map(|r| { let mut r = r.clone(); r.push(0.0); r }).collect(); a5.push(vec![0.0, 0.0, 1.0, 0.0, -1.0]);
    let (mut b5, mut c5) = (b.clone(), c.clone()); b5.push(0.0); c5.push(0.0);
    let (mut cols, mut rows) = (vec![b5.clone()], vec![c5.clone()]); // columns b, Ab, ..., A^4 b and rows c, cA, ..., cA^4
    for _ in 0..4 { let v = mv(&a5, cols.last().unwrap()); cols.push(v); let w = mv(&tr(&a5), rows.last().unwrap()); rows.push(w); }
    let bulb: Vec<f64> = rows.iter().map(|r| r[4]).collect(); let (rc, ro) = (rank(&tr(&cols)), rank(&rows));
    println!("5-state draft: reachable rank {}, seeable rank {}; bulb column of the seeable matrix: {}", rc, ro, f4(&bulb));
    let (p5, q5) = gramians(&a5, &b5, &c5); let h5 = hsv(&p5, &q5);
    println!("5-state Hankel singular values (degC/kW): {}", f6(&h5));
    assert!(rc == 5 && ro == 4 && h5[4] < 1e-6 * h5[0]);
    for (w, ws) in [(0.01, "0.01"), (0.1, "0.1"), (1.0, "1.0")] {
        let (g4, g5) = (gain(&a, &b, &c, w), gain(&a5, &b5, &c5, w));
        println!("  w = {} rad/min: |G| 4-state {:.6}, 5-state {:.6} degC/kW", ws, g4.0.hypot(g4.1), g5.0.hypot(g5.1)); assert!((g4.0 - g5.0).abs() + (g4.1 - g5.1).abs() < 1e-12);
    }
    // ---- 2. the minimal 4-state room: time constants, Gramians two ways ----
    let dd: [f64; 4] = [0.1, 1.0, 1.0, 50.0]; let sym: M = (0..n).map(|i| (0..n).map(|j| a[i][j] * (dd[i] / dd[j]).sqrt()).collect()).collect();
    println!("time constants (min): {}", f4(&jacobi(&sym).0.iter().map(|e| -1.0 / e).collect::<Vec<f64>>()));
    let (p, q) = gramians(&a, &b, &c); let (pt, qt) = (gram_by_time(&a, &b, 4000.0, 0.05), gram_by_time(&tr(&a), &c, 4000.0, 0.05));
    let (sig, sig_t) = (hsv(&p, &q), hsv(&pt, &qt));
    println!("Hankel singular values (degC/kW), Lyapunov:      {}", f6(&sig)); println!("Hankel singular values (degC/kW), time integral: {}", f6(&sig_t));
    assert!((0..n).all(|i| (sig[i] - sig_t[i]).abs() < 1e-6));
    println!("reachability P diagonal: {}", f4(&(0..n).map(|i| p[i][i]).collect::<Vec<f64>>())); println!("seeability Q diagonal: {}", f4(&(0..n).map(|i| q[i][i]).collect::<Vec<f64>>()));
    // ---- 3. balance: both Gramians become diag(sigma) ----
    let (ab, bb, cb) = balance(&a, &b, &c, &p, &q); let (pb, qb) = gramians(&ab, &bb, &cb); let off = (0..n).flat_map(|i| (0..n).map(move |j| (i, j))).filter(|(i, j)| i != j).fold(0.0f64, |s, (i, j)| s.max(pb[i][j].abs() + qb[i][j].abs()));
    println!("balanced P diagonal: {}; largest off-diagonal {:.6}", f6(&(0..n).map(|i| pb[i][i]).collect::<Vec<f64>>()), off); println!("balanced b: {}; balanced c: {}", f4(&bb), f4(&cb));
    assert!((0..n).all(|i| (0..n).all(|j| (pb[i][j] - qb[i][j]).abs() + (pb[i][i] - sig[i]).abs() < 1e-8)) && (0..n).all(|i| (bb[i] * bb[i] - cb[i] * cb[i]).abs() < 1e-8));
    // ---- 4. truncate to 2 states and check the bound ----
    let (ar, br, cr) = cut(&ab, &bb, &cb, 2); let (err, werr) = worst(&a, &b, &c, &ar, &br, &cr); let bound = 2.0 * (sig[2] + sig[3]);
    println!("2-state model: A = [[{:.4}, {:.4}], [{:.4}, {:.4}]], b = ({}), c = ({})", ar[0][0], ar[0][1], ar[1][0], ar[1][1], f4(&br), f4(&cr));
    let leak = 0.4 * 0.1 / (0.4 + 0.1) + 0.02; // walls in series with the outside, plus the windows (kW/degC)
    println!("steady gain: full {:.4}, 2-state {:.4} degC/kW; leak {:.4} kW/degC, so 1/leak = {:.4}; 1.5 kW holds the air {:.4} degC above outside", dc(&a, &b, &c), dc(&ar, &br, &cr), leak, 1.0 / leak, 1.5 * dc(&a, &b, &c));
    println!("worst gain error {:.4} degC/kW at {:.4} rad/min (a {:.1} min cycle); lower limit sigma3 {:.4}; bound 2(sigma3 + sigma4) {:.4}", err, werr, 2.0 * std::f64::consts::PI / werr, sig[2], bound);
    println!("sigma3/sigma1 = {:.4}; for a 1.5 kW valve swing: error {:.4} degC, bound {:.4} degC", sig[2] / sig[0], 1.5 * err, 1.5 * bound);
    assert!(sig[2] - 1e-9 <= err && err <= bound && (1.0 / leak - dc(&a, &b, &c)).abs() < 1e-9);
    let ts: Vec<f64> = (0..=12).map(|i| 40.0 * i as f64).collect(); let (yf, yr) = (step(&a, &b, &c, &ts), step(&ar, &br, &cr, &ts));
    println!("chart, minutes      {}", ts.iter().map(|t| format!("{:7}", *t as i64)).collect::<Vec<_>>().join(" "));
    println!("chart, full 4-state {}", yf.iter().map(|v| format!("{:7.3}", v)).collect::<Vec<_>>().join(" ")); println!("chart, 2-state      {}", yr.iter().map(|v| format!("{:7.3}", v)).collect::<Vec<_>>().join(" "));
    let fine: Vec<f64> = (0..=480).map(|t| t as f64).collect(); let (sf, sr) = (step(&a, &b, &c, &fine), step(&ar, &br, &cr, &fine));
    let d = (0..fine.len()).fold(0.0f64, |s, i| s.max((sf[i] - sr[i]).abs())); let (y_f, y_r) = (step(&a, &b, &c, &[8000.0])[0], step(&ar, &br, &cr, &[8000.0])[0]);
    println!("largest step gap in the first 8 h: {:.4} degC; after 8000 min: full {:.4}, 2-state {:.4}, gap {:.4} degC", d, y_f, y_r, y_r - y_f);
    assert!((y_f - dc(&a, &b, &c)).abs() < 1e-3 && ((y_r - y_f) - (dc(&ar, &br, &cr) - dc(&a, &b, &c))).abs() < 1e-3 && d < err);
    // ---- 5. what breaks ----
    let an: M = [2, 3].iter().map(|&i| [2, 3].iter().map(|&j| a[i][j]).collect()).collect(); let (en, _) = worst(&a, &b, &c, &an, &[0.0, 0.0], &[1.0, 0.0]);
    println!("keep air and walls as they stand: worst gain error {:.4} degC/kW (the heat input lands on the dropped pipe)", en); assert!((en - dc(&a, &b, &c)).abs() < 1e-6);
    let (_, vp) = jacobi(&p); let w: M = (0..n).map(|i| vp[i][..2].to_vec()).collect();
    let ap = mm(&mm(&tr(&w), &a), &w); let bp = mv(&tr(&w), &b); let cp = mv(&tr(&w), &c);
    let (ep, _) = worst(&a, &b, &c, &ap, &bp, &cp); println!("keep the 2 most reachable directions only: worst gain error {:.4} degC/kW, steady gain {:.4}", ep, dc(&ap, &bp, &cp)); assert!(ep > bound);
    let (a1, b1, c1) = cut(&ab, &bb, &cb, 1); let (e1, _) = worst(&a, &b, &c, &a1, &b1, &c1); let s1: f64 = sig[1..].iter().sum();
    println!("truncate to 1 state: worst error {:.4}, bound {:.4} degC/kW", e1, 2.0 * s1);
    let (a3, b3, c3) = cut(&ab, &bb, &cb, 3); let (e3, _) = worst(&a, &b, &c, &a3, &b3, &c3);
    println!("truncate to 3 states: worst error {:.6}, bound {:.6} degC/kW", e3, 2.0 * sig[3]); assert!(e3 <= 2.0 * sig[3] + 1e-9 && e1 <= 2.0 * s1);
    let (ai, bi, _) = room(&Room { gwo: 0.0, gao: 0.0, ..BASE }); let g: Vec<f64> = [1000.0, 2000.0, 4000.0].iter().map(|&hh| gram_by_time(&ai, &bi, hh, 0.1)[2][2]).collect();
    println!("perfectly insulated room: P air entry over 1000, 2000, 4000 min = {} (no limit: no Gramian)", f4(&g)); assert!(g[2] - g[1] > 1.9 * (g[1] - g[0]) && 1.9 * (g[1] - g[0]) > 0.6);
    for (name, r) in [("walls 10 times lighter, Cw = 5", Room { cw: 5.0, ..BASE }), ("pipe link 10 times weaker, Gpr = 0.05", Room { gpr: 0.05, ..BASE }), ("radiator link doubled, Gra = 0.1", Room { gra: 0.1, ..BASE })] {
        let (av, bv, cv) = room(&r); let (pv, qv) = gramians(&av, &bv, &cv); let sv = hsv(&pv, &qv);
        println!("try {}: sigma {}, 2-state bound {:.4} degC/kW", name, f4(&sv), 2.0 * (sv[2] + sv[3]));
    }
    println!("ALL CHECKS PASS");
}
