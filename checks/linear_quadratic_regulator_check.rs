// The LQR -- the same check as linear_quadratic_regulator_check.py, in Rust.  std only, no crates.
// Cart and pendulum, linearised upright.  State x, stored as z = (cart position p in m, cart speed v in m/s,
// angle theta in rad, angle rate w in rad/s); input u = cart acceleration the motor commands, m/s^2.
// p'' = u and theta'' = 16 theta - c u, with c = 1/(rod length) = 16/9.81 per m.
// Roads: (1) the Riccati equation stepped backward in time left (tau); (2) Newton's method on Lyapunov
// equations, from a pole-placement gain; (3) poles from Kalman's identity; (4) simulating the loop.
type M4 = [[f64; 4]; 4]; type V4 = [f64; 4]; type C = (f64, f64);
const AA: f64 = 16.0; fn cc() -> f64 { 16.0 / 9.81 }
fn amat() -> M4 { [[0.0, 1.0, 0.0, 0.0], [0.0; 4], [0.0, 0.0, 0.0, 1.0], [0.0, 0.0, AA, 0.0]] }
fn bvec() -> V4 { [0.0, 1.0, 0.0, -cc()] }
fn mv(m: &M4, v: &V4) -> V4 { let mut o = [0.0; 4]; for i in 0..4 { for k in 0..4 { o[i] += m[i][k] * v[k]; } } o }
fn quad(p: &M4, z: &V4) -> f64 { let mut s = 0.0; for i in 0..4 { for j in 0..4 { s += z[i] * p[i][j] * z[j]; } } s }
fn closed(k: &V4) -> M4 { let (a, b) = (amat(), bvec()); [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| a[i][j] - b[i] * k[j])) }
fn gain(p: &M4, r: f64) -> V4 { mv(p, &bvec()).map(|x| x / r) } fn scaled(k: &V4, m: f64) -> V4 { k.map(|x| m * x) }
fn ric_rhs(p: &M4, q: &M4, r: f64) -> M4 {          // dP/dtau = A'P + PA + Q - P B B' P / r
    let (a, pb) = (amat(), mv(p, &bvec()));
    [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| { let mut s = 0.0; for k in 0..4 { s += p[i][k] * a[k][j] + a[k][i] * p[k][j]; }
        s + q[i][j] - pb[i] * pb[j] / r }))
}
fn add(x: &M4, y: &M4, f: f64) -> M4 { [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| x[i][j] + f * y[i][j])) }
fn ric_ode(q: &M4, r: f64, marks: &[f64]) -> (M4, f64, Vec<V4>) {   // road 1: RK4 from P = 0 backward
    let (h, mut p, mut s, mut seen) = (0.002, [[0.0; 4]; 4], 0.0, vec![[0.0; 4]; marks.len()]);
    loop {
        let k1 = ric_rhs(&p, q, r); let k2 = ric_rhs(&add(&p, &k1, h / 2.0), q, r);
        let k3 = ric_rhs(&add(&p, &k2, h / 2.0), q, r); let k4 = ric_rhs(&add(&p, &k3, h), q, r);
        let nw = [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| p[i][j] + h / 6.0 * (k1[i][j] + 2.0 * k2[i][j] + 2.0 * k3[i][j] + k4[i][j])));
        let step = (0..16).map(|n| (nw[n / 4][n % 4] - p[n / 4][n % 4]).abs()).fold(0.0, f64::max);
        p = nw; s += h; assert!(s < 40.0, "the Riccati equation did not settle in 40 s of time left");
        for (n, m) in marks.iter().enumerate() { if (s - m).abs() < h / 2.0 { seen[n] = gain(&p, r); } }
        if step < 1e-13 { return (p, s, seen); }
    }
}
fn solve(mut m: Vec<Vec<f64>>, y: &[f64]) -> Vec<f64> {   // Gaussian elimination with row swaps
    let n = y.len(); for i in 0..n { m[i].push(y[i]); }
    for i in 0..n {
        let mut p = i; for k in i..n { if m[k][i].abs() > m[p][i].abs() { p = k; } }
        m.swap(i, p); for k in i + 1..n { let f = m[k][i] / m[i][i]; for j in i..=n { m[k][j] -= f * m[i][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { let mut s = 0.0; for j in i + 1..n { s += m[i][j] * x[j]; } x[i] = (m[i][n] - s) / m[i][i]; }
    x
}
fn cost_matrix(k: &V4, q: &M4, r: f64) -> M4 {       // P_K with F'P + PF + Q + r K'K = 0
    let (f, mut m, mut y) = (closed(k), vec![vec![0.0; 16]; 16], vec![0.0; 16]);
    for i in 0..4 { for j in 0..4 { y[4 * i + j] = -(q[i][j] + r * k[i] * k[j]);
        for l in 0..4 { m[4 * i + j][4 * l + j] += f[l][i]; m[4 * i + j][4 * i + l] += f[l][j]; } } }
    let x = solve(m, &y); [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| x[4 * i + j]))
}
fn newton(k0: &V4, q: &M4, r: f64) -> (M4, V4, usize) {   // road 2: cost the gain, improve it, repeat
    let mut k = *k0;
    for n in 1..50 { let p = cost_matrix(&k, q, r); let k2 = gain(&p, r);
        if (0..4).map(|i| (k2[i] - k[i]).abs()).fold(0.0, f64::max) < 1e-10 { return (p, k2, n); } k = k2; }
    panic!("Newton did not settle")
}
fn charpoly(f: &M4) -> Vec<f64> {                    // Faddeev-LeVerrier: coefficients of det(sI - F)
    let (mut cf, mut m) = (vec![1.0], [[0.0; 4]; 4]);
    for k in 1..5 {
        let last = cf[cf.len() - 1];
        m = [0, 1, 2, 3].map(|i| [0, 1, 2, 3].map(|j| { let mut s = 0.0; for l in 0..4 { s += f[i][l] * m[l][j]; } if i == j { s + last } else { s } }));
        let mut tr = 0.0; for i in 0..4 { let mut s = 0.0; for l in 0..4 { s += f[i][l] * m[l][i]; } tr += s; }
        cf.push(-tr / k as f64);
    }
    cf
}
fn cm(a: C, b: C) -> C { (a.0 * b.0 - a.1 * b.1, a.0 * b.1 + a.1 * b.0) } fn cd(a: C, b: C) -> C { let d = b.0 * b.0 + b.1 * b.1; ((a.0 * b.0 + a.1 * b.1) / d, (a.1 * b.0 - a.0 * b.1) / d) }
fn csqrt(w: C) -> C { let m = (w.0 * w.0 + w.1 * w.1).sqrt(); let im = ((m - w.0) / 2.0).sqrt(); (((m + w.0) / 2.0).sqrt(), if w.1 < 0.0 { -im } else { im }) }
fn rnd(x: f64) -> f64 { (x * 1e9).round() / 1e9 }
fn tidy(z: Vec<C>) -> Vec<C> { let mut t: Vec<C> = z.iter().map(|w| (rnd(w.0), rnd(w.1).abs())).collect(); t.sort_by(|p, q| p.partial_cmp(q).unwrap()); t }
fn roots(cf: &[f64]) -> Vec<C> {                     // Durand-Kerner on a monic quartic
    let mut z: Vec<C> = vec![(1.0, 0.0)];
    for k in 1..4 { let last = z[k - 1]; z.push(cm(last, (0.4, 0.9))); }
    for _ in 0..300 {
        z = (0..4).map(|i| {
            let mut d = (1.0, 0.0); for j in 0..4 { if j != i { d = cm(d, (z[i].0 - z[j].0, z[i].1 - z[j].1)); } }
            let mut v = (z[i].0 + cf[1], z[i].1); for c in &cf[2..] { v = cm(v, z[i]); v.0 += c; }
            let corr = cd(v, d); (z[i].0 - corr.0, z[i].1 - corr.1) }).collect();
    }
    tidy(z)
}
fn kalman_poles(qp: f64, qt: f64, r: f64) -> Vec<C> { // road 3: left roots, as a quartic in w = s^2
    let (al, be) = (qp / r, qt * cc() * cc() / r);
    let ws = roots(&[1.0, -2.0 * AA, AA * AA + al + be, -2.0 * AA * al, al * AA * AA]);
    tidy(ws.iter().map(|w| { let s = csqrt(*w); if s.0 > 0.0 { (-s.0, -s.1) } else { s } }).collect())
}
fn hurwitz(cf: &[f64]) -> bool {                     // every root of a quartic in the left half-plane
    let (a3, a2, a1, a0) = (cf[1], cf[2], cf[3], cf[4]);
    cf.iter().cloned().fold(f64::INFINITY, f64::min) > 0.0 && a3 * a2 > a1 && a3 * a2 * a1 > a1 * a1 + a3 * a3 * a0
}
struct Run { j: f64, pu: f64, px: f64, st: f64, sx: f64, th: Vec<f64>, z: V4 }
fn curved(k: &V4, z: &V4) -> V4 { let u = -(0..4).map(|j| k[j] * z[j]).sum::<f64>(); [z[1], u, z[3], AA * z[2].sin() - cc() * u * z[2].cos()] }
fn simulate(k: &V4, qp: f64, qt: f64, r: f64, z0: &V4, bend: bool) -> Run {   // road 4: RK4 on the loop, cost by trapezoids
    let (h, f) = (0.001, closed(k)); let d = |z: &V4| if bend { curved(k, z) } else { mv(&f, z) };
    let mut o = Run { j: 0.0, pu: 0.0, px: 0.0, st: 0.0, sx: 0.0, th: vec![], z: *z0 };
    let run = |z: &V4, u: f64| qp * (z[0] * z[0]) + qt * (z[2] * z[2]) + r * u * u;
    let push = |z: &V4| { let mut s = 0.0; for j in 0..4 { s += k[j] * z[j]; } -s };
    let step = |z: &V4, d: &V4, g: f64| [z[0] + g * d[0], z[1] + g * d[1], z[2] + g * d[2], z[3] + g * d[3]];
    for n in 0..((10.0 / h) as usize + 1) {
        let (z, u) = (o.z, push(&o.z));
        if n % 100 == 0 && n <= 2000 { o.th.push(1000.0 * z[2]); }
        o.pu = o.pu.max(u.abs()); o.px = o.px.max(z[0].abs());
        if z[2].abs() > 0.005 { o.st = n as f64 * h; } if z[2].abs() > std::f64::consts::FRAC_PI_2 { break; }   // fallen past horizontal
        if z[0].abs() > 0.01 { o.sx = n as f64 * h; }
        let k1 = d(&z); let k2 = d(&step(&z, &k1, h / 2.0));
        let k3 = d(&step(&z, &k2, h / 2.0)); let k4 = d(&step(&z, &k3, h));
        let mut z2 = z; for i in 0..4 { z2[i] = z[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        o.j += h / 2.0 * (run(&z, u) + run(&z2, push(&z2))); o.z = z2;
    }
    o
}
fn qm(qp: f64, qt: f64) -> M4 { let mut q = [[0.0; 4]; 4]; q[0][0] = qp; q[2][2] = qt; q }
fn fmt(v: &[f64], w: usize, d: usize) -> String { v.iter().map(|x| format!("{:w$.d$}", x, w = w, d = d)).collect::<Vec<_>>().join(" ") } fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn pole(ps: &[C]) -> String {
    let mut s: Vec<String> = ps.iter().map(|p| { let re = format!("{:.4}", p.0); let re = if re == "-0.0000" { "0.0000".to_string() } else { re };
        if p.1 > 5e-5 { format!("{} +- {:.4}j", re, p.1) } else { re } }).collect(); s.dedup(); s.join("  ") }
fn main() {
    let (a, c, z0) = (AA, cc(), [0.0, 0.0, 0.05, 0.0]);   // pendulum knocked 0.05 rad (2.9 degrees) off upright
    let k0: V4 = [-16.0 / a, -32.0 / a, -(16.0 / a + a + 24.0) / c, -(32.0 / a + 8.0) / c];   // all poles at -2
    println!("rod l = {:.6} m | open-loop poles: {} | det(sI - A + B K0): {}", 1.0 / c, pole(&roots(&charpoly(&amat()))), fmt(&charpoly(&closed(&k0)), 0, 4));
    let designs = [("base (Bryson)", "4", "100", "0.04", 4.0, 100.0, 0.04), ("cheap motor", "4", "100", "0.004", 4.0, 100.0, 0.004),
                   ("tight angle", "4", "1000", "0.04", 4.0, 1000.0, 0.04)];
    let mut res = vec![];
    for (name, sx_, sq, sr, qp, qt, r) in designs {
        let q = qm(qp, qt);
        let (p1, s_end, fin) = ric_ode(&q, r, &[0.25, 0.5, 1.0, 2.0, 5.0]);
        let (p, k, its) = newton(&k0, &q, r);
        let (pa, pk) = (roots(&charpoly(&closed(&k))), kalman_poles(qp, qt, r));
        let o = simulate(&k, qp, qt, r, &z0, false);
        let (mut lo, mut hi) = (0.0, 1.0); for _ in 0..50 { let m = (lo + hi) / 2.0; if hurwitz(&charpoly(&closed(&scaled(&k, m)))) { hi = m } else { lo = m } }
        let gap = (0..16).map(|n| (p1[n / 4][n % 4] - p[n / 4][n % 4]).abs()).fold(0.0, f64::max); let safe = [0.5, 1000.0].iter().all(|m| hurwitz(&charpoly(&closed(&scaled(&k, *m)))));
        println!("{}: qp = {}, qt = {}, r = {}", name, sx_, sq, sr);
        println!("  K by Riccati ODE ({:.2} s to go): {}", s_end, fmt(&gain(&p1, r), 9, 3));
        println!("  K by Newton ({} rounds):          {}   same P to 1e-8: {}", its, fmt(&k, 9, 3), yn(gap < 1e-8));
        println!("  poles of A - BK:      {}", pole(&pa));
        println!("  poles, Kalman's identity: {}", pole(&pk));
        println!("  J = x0'P x0 = {:.6}; simulated {:.6}", quad(&p, &z0), o.j);
        println!("  peak push {:.2} m/s^2, peak cart {:.1} cm, angle inside 5 mrad after {:.3} s, cart inside 1 cm after {:.3} s", o.pu, 100.0 * o.px, o.st, o.sx);
        println!("  smallest safe gain scale {:.3}; stable at 0.5 and at 1000: {}", hi, yn(safe));
        let pg = (0..4).map(|i| ((pa[i].0 - pk[i].0).powi(2) + (pa[i].1 - pk[i].1).powi(2)).sqrt()).fold(0.0, f64::max);
        assert!((quad(&p, &z0) - o.j).abs() < 1e-4 * o.j && gap < 1e-8);
        assert!(pg < 1e-6 && (k[0] + (qp / r).sqrt()).abs() < 1e-8 && hi < 0.5);
        res.push((name, q, r, p, k, quad(&p, &z0), o.th, fin));
    }
    let (_, q, r, p, k, j, _, fin) = res[0].clone();
    println!("base P, rows:"); for row in &p { println!("  {}", fmt(row, 10, 4)); }
    println!("base gain on theta = (P[theta][v] - c P[theta][w]) / r = ({:.4} - {:.4} x {:.4}) / {} = {:.3}", p[2][1], c, p[2][3], r, (p[2][1] - c * p[2][3]) / r);
    for (n, m) in ["0.25", "0.5", "1.0", "2.0", "5.0"].iter().enumerate() { println!("base, finite horizon {} s to go: K = {}", m, fmt(&fin[n], 9, 3)); }
    let mut nudged = f64::INFINITY;
    for m in 0..4 { for e in [-0.05, 0.05] { let kn: V4 = [0, 1, 2, 3].map(|i| if i == m { k[i] * (1.0 + e) } else { k[i] * 1.0 });
        nudged = nudged.min(quad(&cost_matrix(&kn, &q, r), &z0)); } }
    println!("base, cheapest of 8 gains nudged 5%: J = {:.6} (optimum {:.6})", nudged, j);
    println!("chart, angle in mrad at t = 0 to 2 s by 0.1 s:");
    for row in &res { println!("  {:<14}{}", row.0, fmt(&row.6, 0, 1)); }
    for (label, kb) in [("K = B'P, R^-1 forgotten", scaled(&k, r)), ("u = +Kx, sign flipped", scaled(&k, -1.0)), ("k_p alone flipped", [-k[0], k[1], k[2], k[3]])] {
        println!("mistake, {}: poles {}", label, pole(&roots(&charpoly(&closed(&kb))))); }
    let k_q0 = gain(&ric_ode(&qm(0.0, 100.0), r, &[]).0, r); let zend = simulate(&k_q0, 0.0, 100.0, r, &z0, false).z;
    println!("mistake, angle-only weight: K = {}; after 10 s cart at {:.3} m, still moving {:.4} m/s", fmt(&k_q0, 9, 3), zend[0], zend[1]);
    let (_, k_deg, _) = newton(&k0, &qm(4.0, 100.0 * (180.0 / 3.141592653589793_f64).powi(2)), r);
    println!("mistake, angle weight meant for degrees: opening push {:.1} m/s^2", -(k_deg[2] * z0[2]));
    let (_, k10, _) = newton(&k0, &qm(40.0, 1000.0), 0.4); let dear = simulate(&newton(&k0, &q, 0.4).1, 4.0, 100.0, 0.4, &z0, false);
    let big = simulate(&k, 4.0, 100.0, r, &scaled(&z0, 2.0), false); let dk = (0..4).map(|i| (k10[i] - k[i]).abs()).fold(0.0, f64::max);
    println!("try, all weights x10: same gains to 1e-8: {}", yn(dk < 1e-8));
    println!("try, r = 0.4: peak push {:.2} m/s^2, angle inside 5 mrad after {:.3} s", dear.pu, dear.st);
    println!("try, start at 0.10 rad: J = {:.6}, peak push {:.2} m/s^2", big.j, big.pu);
    assert!(nudged > j && (big.j - 4.0 * j).abs() < 1e-4 * big.j && dk < 1e-8);
    assert!(roots(&charpoly(&closed(&scaled(&k, r)))).iter().any(|p| p.0 > 0.0) && zend[1].abs() > 0.01);
    let cv: Vec<Run> = [0.05, 1.1].iter().map(|&x| simulate(&k, 4.0, 100.0, r, &[0.0, 0.0, x, 0.0], true)).collect();   // the real, curved rod
    println!("curved rod, base gain: from 0.05 rad angle inside 5 mrad after {:.3} s; from 1.10 rad the angle passes 90 degrees after {:.3} s", cv[0].st, cv[1].st);
    assert!(cv[0].th.iter().zip(&res[0].6).all(|(p, q)| (p - q).abs() < 0.1) && cv[1].z[2].abs() > std::f64::consts::FRAC_PI_2);
    println!("ALL CHECKS PASS");
}
