// Predictive control -- the same check as model_predictive_control_check.py, in Rust.  No crates.
// Same model, same four roads: active set, projected gradient, costate gradient, LQR with no limits.
type Mat = Vec<Vec<f64>>;
const T: f64 = 0.05; const NH: usize = 20; const UMAX: f64 = 1.0; const R: f64 = 0.1; const D: f64 = 0.125; const Q: [f64; 4] = [1.0, 0.1, 10.0, 0.1];
fn mm(x: &Mat, y: &Mat) -> Mat { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).fold(0.0, |s, k| s + x[i][k] * y[k][j])).collect()).collect() }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |s, (x, y)| s + x * y) }
fn mv(x: &Mat, v: &[f64]) -> Vec<f64> { x.iter().map(|r| dot(r, v)).collect() }
fn tr(x: &Mat) -> Mat { (0..x[0].len()).map(|j| x.iter().map(|r| r[j]).collect()).collect() }
fn eye(n: usize) -> Mat { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn qmat() -> Mat { (0..4).map(|i| (0..4).map(|j| if i == j { Q[i] } else { 0.0 }).collect()).collect() }
fn solve(x: &Mat, b: &[f64]) -> Vec<f64> {                       // Gauss-Jordan with partial pivoting
    let n = b.len();
    let mut x: Mat = (0..n).map(|i| { let mut r = x[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c; for r in c..n { if x[r][c].abs() > x[p][c].abs() { p = r; } } x.swap(c, p);
        for r in 0..n { if r != c { let f = x[r][c] / x[c][c]; for j in c..=n { x[r][j] -= f * x[c][j]; } } }
    }
    (0..n).map(|i| x[i][n] / x[i][i]).collect()
}
struct Sys { a: Mat, b: Vec<f64>, p: Mat, k: Vec<f64> }
fn build(s: &Sys, n: usize, pt: &Mat) -> (Mat, Mat) {          // condensed: cost = U'HU + 2 (F x0)'U + const
    let (mut ab, mut ak) = (vec![s.b.clone()], vec![eye(4)]);
    for _ in 0..n { let v = mv(&s.a, ab.last().unwrap()); ab.push(v); let m = mm(&s.a, ak.last().unwrap()); ak.push(m); }
    let w = |k: usize| if k == n { pt.clone() } else { qmat() };
    let h = (0..n).map(|i| (0..n).map(|j| {
        let sm = (i.max(j) + 1..=n).fold(0.0, |acc, k| acc + dot(&ab[k - 1 - i], &mv(&w(k), &ab[k - 1 - j])));
        (if i == j { R } else { 0.0 }) + sm }).collect()).collect();
    let f = (0..n).map(|i| (0..4).map(|c| (i + 1..=n).fold(0.0, |acc, k| {
        let col: Vec<f64> = (0..4).map(|a| ak[k][a][c]).collect(); acc + dot(&ab[k - 1 - i], &mv(&w(k), &col)) })).collect()).collect();
    (h, f)
}
fn active_set(h: &Mat, f: &[f64], lo: &[f64], hi: &[f64]) -> Vec<f64> {   // road 1
    let n = f.len(); let mut fix: Vec<(usize, f64)> = vec![];
    loop {
        let free: Vec<usize> = (0..n).filter(|i| !fix.iter().any(|&(j, _)| j == *i)).collect();
        let hm: Mat = free.iter().map(|&i| free.iter().map(|&j| h[i][j]).collect()).collect();
        let rhs: Vec<f64> = free.iter().map(|&i| -f[i] - fix.iter().fold(0.0, |s, &(j, v)| s + h[i][j] * v)).collect();
        let sl = if free.is_empty() { vec![] } else { solve(&hm, &rhs) };
        let mut u = vec![0.0; n]; for &(j, v) in &fix { u[j] = v; } for (&i, &v) in free.iter().zip(&sl) { u[i] = v; }
        let mut out: Option<(f64, usize)> = None;
        for &i in &free {
            let vi = (u[i] - hi[i]).max(lo[i] - u[i]);
            if (u[i] > hi[i] || u[i] < lo[i]) && out.map_or(true, |(bv, _)| vi >= bv) { out = Some((vi, i)); }
        }
        if let Some((_, i)) = out { fix.push((i, if u[i] > hi[i] { hi[i] } else { lo[i] })); continue; }
        let gr: Vec<f64> = (0..n).map(|i| dot(&h[i], &u) + f[i]).collect();
        let mut bad: Option<usize> = None;
        for (pos, &(i, v)) in fix.iter().enumerate() {
            if ((v == hi[i] && gr[i] > 0.0) || (v == lo[i] && gr[i] < 0.0)) && bad.map_or(true, |b| gr[i].abs() > gr[fix[b].0].abs()) { bad = Some(pos); }
        }
        match bad { None => return u, Some(b) => { fix.remove(b); } }
    }
}
fn fista(h: &Mat, f: &[f64], lo: &[f64], hi: &[f64], iters: usize) -> Vec<f64> {   // road 2
    let mut v = vec![1.0; f.len()]; let mut l = 0.0;
    for _ in 0..300 { let w = mv(h, &v); l = w.iter().fold(0.0_f64, |m, a| m.max(a.abs())); v = w.iter().map(|a| a / l).collect(); }
    let (mut x, mut y, mut t) = (vec![0.0; f.len()], vec![0.0; f.len()], 1.0_f64);
    for _ in 0..iters {
        let hy = mv(h, &y);
        let xn: Vec<f64> = (0..f.len()).map(|i| hi[i].min(lo[i].max(y[i] - (hy[i] + f[i]) / l))).collect();
        let tn = (1.0 + (1.0 + 4.0 * t * t).sqrt()) / 2.0;
        y = xn.iter().zip(&x).map(|(a, b)| a + (t - 1.0) / tn * (a - b)).collect(); x = xn; t = tn;
    }
    x
}
fn costate(s: &Sys, x0: &[f64], u: &[f64], pt: &Mat) -> (f64, Vec<f64>, Mat) {   // road 3
    let mut xs: Mat = vec![x0.to_vec()];
    for &uk in u { let nx: Vec<f64> = mv(&s.a, xs.last().unwrap()).iter().zip(&s.b).map(|(a, b)| a + b * uk).collect(); xs.push(nx); }
    let xn = xs.last().unwrap().clone(); let j = xs.iter().zip(u).fold(0.0, |acc, (x, &uk)| acc + (dot(&Q, &x.iter().map(|v| v * v).collect::<Vec<_>>()) + R * uk * uk)) + dot(&xn, &mv(pt, &xn));
    let (mut lam, mut grad): (Vec<f64>, Vec<f64>) = (mv(pt, &xn).iter().map(|v| 2.0 * v).collect(), vec![0.0; u.len()]);
    let at = tr(&s.a);
    for k in (0..u.len()).rev() {
        grad[k] = 2.0 * R * u[k] + dot(&s.b, &lam);
        let al = mv(&at, &lam); lam = (0..4).map(|i| 2.0 * Q[i] * xs[k][i] + al[i]).collect();
    }
    (j, grad, xs)
}
struct Tick { x: Vec<f64>, u: f64, dh: f64, xe: Vec<f64> }
fn run(s: &Sys, mode: &str, d: f64, ticks: usize, hf: Option<&(Mat, Mat)>, um: f64) -> Vec<Tick> {
    let (mut x, mut dh, mut prev, mut log): (Vec<f64>, f64, Option<(Vec<f64>, f64)>, Vec<Tick>) = (vec![0.0; 4], 0.0, None, vec![]);
    for _ in 0..ticks {
        if let (true, Some((px, pu))) = (mode == "free", &prev) {   // disturbance state: what the last move missed
            let e: Vec<f64> = (0..4).map(|i| x[i] - mv(&s.a, px)[i] - s.b[i] * pu).collect();
            dh += 0.2 * (dot(&s.b, &e) / dot(&s.b, &s.b) - dh);
        }
        let mut km: Mat = (0..4).map(|i| { let mut r: Vec<f64> = (0..4).map(|j| s.a[i][j] - if i == j { 1.0 } else { 0.0 }).collect(); r.push(s.b[i]); r }).collect();
        km.push(vec![1.0, 0.0, 0.0, 0.0, 0.0]); let mut rhs: Vec<f64> = s.b.iter().map(|b| -b * dh).collect(); rhs.push(2.0); let xsu = solve(&km, &rhs);
        let (xe, us): (Vec<f64>, f64) = ((0..4).map(|i| x[i] - xsu[i]).collect(), xsu[4]);
        let u = if mode == "clip" { (-um).max(um.min(us - dot(&s.k, &xe))) } else {
            let (h, f) = hf.unwrap(); let n = f.len();
            us + active_set(h, &mv(f, &xe), &vec![-um - us; n], &vec![um - us; n])[0] };
        log.push(Tick { x: x.clone(), u, dh, xe }); prev = Some((x.clone(), u));
        x = mv(&s.a, &x).iter().zip(&s.b).map(|(a, b)| a + b * (u + d)).collect();
    }
    log
}
fn sci(v: f64, p: usize) -> String {                             // Python-style 2.51e-04
    let s = format!("{:.*e}", p, v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap(); format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs()) }
fn f4(v: f64) -> String { format!("{:.4}", v) } fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|u| format!("{:.*}", p, u)).collect::<Vec<_>>().join(" ") }
fn fall(lg: &[Tick]) -> String { lg.iter().position(|t| t.x[2].abs() > 0.5).map_or("never".to_string(), |k| format!("{:.2} s", k as f64 * T)) }
fn peak(lg: &[Tick]) -> f64 { lg.iter().fold(0.0_f64, |m, t| m.max(t.x[2].abs())) }
fn main() {
    let (mm_, m, l, g, kf) = (1.0_f64, 0.2_f64, 0.735_f64, 9.8_f64, 4.0_f64);
    let ac = [[0.0, 1.0, 0.0, 0.0], [0.0, 0.0, -m * g / mm_, 0.0], [0.0, 0.0, 0.0, 1.0], [0.0, 0.0, (mm_ + m) * g / (mm_ * l), 0.0]];
    let bc = [0.0, kf / mm_, 0.0, -kf / (mm_ * l)];
    let mut z: Mat = (0..4).map(|i| { let mut r = ac[i].to_vec(); r.push(bc[i]); r }).collect(); z.push(vec![0.0; 5]);
    let (mut e, mut term) = (eye(5), eye(5));                        // Van Loan: exp([[A, B], [0, 0]] T)
    for k in 1..20 {
        term = mm(&term, &z).iter().map(|r| r.iter().map(|v| v * T / 256.0 / k as f64).collect()).collect();
        e = e.iter().zip(&term).map(|(r, s)| r.iter().zip(s).map(|(a, b)| a + b).collect()).collect();
    }
    for _ in 0..8 { e = mm(&e, &e); }
    let a: Mat = e[..4].iter().map(|r| r[..4].to_vec()).collect(); let b: Vec<f64> = e[..4].iter().map(|r| r[4]).collect();
    let (mut p, mut k, mut sweeps) = (qmat(), vec![0.0; 4], 0);     // LQR: Riccati iteration, stable form
    for it in 0..100000 {
        let pb = mv(&p, &b); let den = R + dot(&b, &pb);
        k = (0..4).map(|j| dot(&pb, &(0..4).map(|i| a[i][j]).collect::<Vec<_>>()) / den).collect();
        let acl: Mat = (0..4).map(|i| (0..4).map(|j| a[i][j] - b[i] * k[j]).collect()).collect();
        let pn: Mat = mm(&tr(&acl), &mm(&p, &acl)).iter().enumerate().map(|(i, r)| r.iter().enumerate()
            .map(|(j, v)| v + if i == j { Q[i] } else { 0.0 } + R * k[i] * k[j]).collect()).collect();
        let done = (0..4).all(|i| (0..4).all(|j| (pn[i][j] - p[i][j]).abs() < 1e-10)); p = pn; sweeps = it + 1; if done { break; }
    }
    let s = Sys { a, b, p: p.clone(), k };
    let hf = build(&s, NH, &s.p); let (h, f) = (&hf.0, &hf.1); let x0 = [-2.0, 0.0, 0.0, 0.0];
    let (lo, hi) = (vec![-UMAX; NH], vec![UMAX; NH]); let u = active_set(h, &mv(f, &x0), &lo, &hi); let uf = fista(h, &mv(f, &x0), &lo, &hi, 20000);
    let (j0, grad, plan) = costate(&s, &x0, &u, &s.p); let uu = solve(h, &mv(f, &x0).iter().map(|v| -v).collect::<Vec<_>>());
    let kkt_free = grad.iter().zip(&u).filter(|(_, x)| x.abs() < UMAX).fold(0.0_f64, |mx, (gv, _)| mx.max(gv.abs()));
    let kkt_sign = grad.iter().zip(&u).filter(|(_, x)| x.abs() == UMAX).fold(f64::INFINITY, |mn, (gv, x)| mn.min(-gv * x));
    let gap = u.iter().zip(&uf).fold(0.0_f64, |mx, (a, b)| mx.max((a - b).abs()));
    let (mpc, clip) = (run(&s, "mpc", 0.0, 120, Some(&hf), UMAX), run(&s, "clip", 0.0, 120, None, UMAX));
    let js: Vec<f64> = mpc.iter().map(|t| costate(&s, &t.xe, &active_set(h, &mv(f, &t.xe), &lo, &hi), &s.p).0).collect();
    let (plain, free) = (run(&s, "mpc", D, 200, Some(&hf), UMAX), run(&s, "free", D, 200, Some(&hf), UMAX));
    let mut ol = plan[0].clone(); for &uk in &u { ol = mv(&s.a, &ol).iter().zip(&s.b).map(|(a, b)| a + b * (uk + D)).collect(); }   // never replanned
    let (hf5, hf10) = (build(&s, 5, &qmat()), build(&s, 10, &s.p));
    let (short, m10) = (run(&s, "mpc", 0.0, 80, Some(&hf5), UMAX), run(&s, "mpc", 0.0, 120, Some(&hf10), UMAX));
    let (clip15, mpc05, free2) = (run(&s, "clip", 0.0, 120, None, 1.5), run(&s, "mpc", 0.0, 120, Some(&hf), 0.5), run(&s, "free", 2.0 * D, 200, Some(&hf), UMAX));
    let (pole, rises) = (s.a[2][2] + (s.a[2][3] * s.a[3][2]).sqrt(), js.windows(2).filter(|w| w[1] > w[0]).count()); let pend = plain.last().unwrap().x[0]; let fend = free.last().unwrap().x[0];
    println!("discrete pendulum pole e^(4T) {}  B {}", f4(pole), s.b.iter().map(|v| f4(*v)).collect::<Vec<_>>().join(" "));
    println!("LQR gain K {}  Riccati sweeps {}", s.k.iter().map(|v| f4(*v)).collect::<Vec<_>>().join(" "), sweeps);
    println!("tick-0 plan, A: {}", join(&u, 3));
    println!("road 2 projected gradient, largest gap {}", sci(gap, 2));
    println!("road 3 costate: free-move gradient below 1e-9 {}  limit push {}  plan cost {}", tf(kkt_free < 1e-9), f4(kkt_sign), f4(j0));
    println!("no limit: QP first move {}  LQR -K x0 {}", f4(uu[0]), f4(-dot(&s.k, &x0)));
    println!("plan angle peak rad {}  plan end p {}", f4(plan.iter().fold(0.0_f64, |mx, x| mx.max(x[2].abs()))), f4(plan.last().unwrap()[0] + 2.0));
    println!("MPC: peak angle {}  p at 5.95 s {}  moves = plan to 1e-9 {}", f4(peak(&mpc)), f4(mpc.last().unwrap().x[0]), tf(mpc.iter().zip(&u).all(|(t, b)| (t.u - b).abs() < 1e-9)));
    println!("MPC: optimal cost ticks 0,1,2,10 {}  rises {}", [0, 1, 2, 10].iter().map(|&k| f4(js[k])).collect::<Vec<_>>().join(" "), rises);
    let st: Vec<String> = mpc[..2].iter().map(|t| f4(dot(&Q, &t.xe.iter().map(|v| v * v).collect::<Vec<_>>()) + R * t.u * t.u)).collect();
    println!("MPC: cost drops {} {}  stage costs {}", f4(js[0] - js[1]), f4(js[1] - js[2]), st.join(" "));
    println!("clipped LQR: first moves {}  angle past 0.5 rad at {}", join(&clip[..6].iter().map(|t| t.u).collect::<Vec<_>>(), 3), fall(&clip));
    println!("push, plain MPC: p at 9.95 s {}  offset {}  formula d/K_p {}", f4(pend), f4(pend - 2.0), f4(D / s.k[0]));
    println!("push, offset-free: p at 9.95 s {}  d estimate {}  current {}", f4(fend), f4(free.last().unwrap().dh), f4(free.last().unwrap().u));
    println!("push, plan never replanned: angle at 1 s {}  planned {}", f4(ol[2]), f4(plan.last().unwrap()[2]));
    println!("N=5, no terminal cost: p at 2 s {}  angle past 0.5 rad at {}", f4(short[40].x[0]), fall(&short));
    println!("try: N=10 with P, peak angle {}  limit 1.5 A, clipped LQR falls: {}", f4(peak(&m10)), fall(&clip15));
    println!("try: limit 0.5 A, MPC peak angle {}  p at 5.95 s {}  falls: {}", f4(peak(&mpc05)), f4(mpc05.last().unwrap().x[0]), fall(&mpc05));
    println!("try: push 1 N, offset-free p at 9.95 s {}  current {}", f4(free2.last().unwrap().x[0]), f4(free2.last().unwrap().u));
    println!("chart current, MPC   {}", join(&mpc[..20].iter().map(|t| t.u).collect::<Vec<_>>(), 2));
    println!("chart current, clip  {}", join(&clip[..20].iter().map(|t| t.u).collect::<Vec<_>>(), 2));
    println!("chart p, plain       {}", join(&(0..200).step_by(10).map(|k| plain[k].x[0]).collect::<Vec<_>>(), 2));
    println!("chart p, offset-free {}", join(&(0..200).step_by(10).map(|k| free[k].x[0]).collect::<Vec<_>>(), 2));
    assert!((pole - (0.2_f64).exp()).abs() < 1e-9, "Van Loan pole vs e^(4T)");
    assert!(gap < 1e-3, "active set vs projected gradient");
    assert!(kkt_free < 1e-9 && kkt_sign > 0.0, "costate gradient certifies the plan");
    assert!((uu[0] + dot(&s.k, &x0)).abs() < 1e-8, "no limits: first planned move is the LQR move");
    assert!(mpc.iter().chain(&free).all(|t| t.u.abs() <= UMAX + 1e-12) && peak(&mpc) < 0.25, "MPC keeps limits");
    assert!((pend - 2.0 - D / s.k[0]).abs() < 1e-4 && (fend - 2.0).abs() < 1e-4, "offset, and its removal");
    assert!(js.windows(2).all(|w| w[1] <= w[0] + 1e-9), "optimal cost never rises");
    println!("ALL CHECKS PASS");
}
