// Can you steer every state, and can you see every state -- the check behind the card.
// std only. Cart on a rail, motor sets its acceleration u (m/s^2), rod upright on a hinge.
// State x = (p cart m, v cart m/s, th lean rad, om lean rate rad/s): p'' = u, th'' = 16 th - u/l.
type M = Vec<Vec<f64>>;
const L: f64 = 0.613125;
const G: f64 = 9.81;
fn f(x: f64, d: usize) -> String { let y = if x.abs() < 0.5 * 10f64.powi(-(d as i32)) { 0.0 } else { x }; format!("{:.*}", d, y) }
fn sci(x: f64) -> String {
    if x.abs() < 1e-15 { return "0".to_string(); }
    let e = x.abs().log10().floor(); format!("{:.3}e{}", x / 10f64.powf(e), e as i32)
}
fn mm(x: &M, y: &M) -> M { (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect() }
fn tr(x: &M) -> M { (0..x[0].len()).map(|j| x.iter().map(|r| r[j]).collect()).collect() }
fn mv(x: &M, v: &[f64]) -> Vec<f64> { x.iter().map(|r| r.iter().zip(v).map(|(a, b)| a * b).sum()).collect() }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn eye(n: usize) -> M { (0..n).map(|i| (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect() }
fn m(r: &[&[f64]]) -> M { r.iter().map(|x| x.to_vec()).collect() }
fn expm(x: &M, t: f64) -> M { // e^(Xt): scale down by 256, Taylor series, square 8 times
    let n = x.len(); let mut e = eye(n); let mut p = eye(n);
    let y: M = x.iter().map(|r| r.iter().map(|v| v * t / 256.0).collect()).collect();
    for k in 1..20 { p = mm(&p, &y).iter().map(|r| r.iter().map(|v| v / k as f64).collect()).collect();
        for i in 0..n { for j in 0..n { e[i][j] += p[i][j]; } } }
    for _ in 0..8 { e = mm(&e, &e); }
    e
}
fn rank(m0: &M) -> usize { // road 1 to a rank: Gaussian elimination
    let mut a = m0.clone(); let mut r = 0;
    for j in 0..a[0].len() {
        if r == a.len() { break; }
        let mut p = r; for i in r..a.len() { if a[i][j].abs() > a[p][j].abs() { p = i; } }
        if a[p][j].abs() < 1e-9 { continue; }
        a.swap(r, p);
        for i in 0..a.len() { if i != r { let q = a[i][j] / a[r][j]; let ar = a[r].clone(); for (x, y) in a[i].iter_mut().zip(&ar) { *x -= q * y; } } }
        r += 1;
    }
    r
}
fn jacobi(s0: &M) -> (Vec<f64>, M) { // eigenvalues (ascending) and eigenvectors of symmetric S
    let n = s0.len(); let mut s = s0.clone(); let mut v = eye(n);
    for _ in 0..40 { for p in 0..n { for q in p + 1..n {
        if s[p][q] == 0.0 { continue; }
        let t = 0.5 * (2.0 * s[p][q]).atan2(s[q][q] - s[p][p]); let (co, si) = (t.cos(), t.sin());
        for k in 0..n { let (a, b) = (s[k][p], s[k][q]); s[k][p] = co * a - si * b; s[k][q] = si * a + co * b; }
        for k in 0..n { let (a, b) = (s[p][k], s[q][k]); s[p][k] = co * a - si * b; s[q][k] = si * a + co * b; }
        for k in 0..n { let (a, b) = (v[k][p], v[k][q]); v[k][p] = co * a - si * b; v[k][q] = si * a + co * b; }
    } } }
    let mut o: Vec<usize> = (0..n).collect(); o.sort_by(|&i, &j| s[i][i].partial_cmp(&s[j][j]).unwrap());
    (o.iter().map(|&i| s[i][i]).collect(), o.iter().map(|&i| (0..n).map(|k| v[k][i]).collect()).collect())
}
fn svrank(x: &M) -> usize { jacobi(&mm(&tr(x), x)).0.iter().filter(|&&s| s > 1e-9).count() } // road 2: nonzero singular values
fn ctrb(a: &M, b: &[f64]) -> M { let mut cols = vec![b.to_vec()]; for _ in 1..a.len() { let n = mv(a, cols.last().unwrap()); cols.push(n); } tr(&cols) }
fn obsv(a: &M, c: &[f64]) -> M { tr(&ctrb(&tr(a), c)) } // duality: rows C, CA, CA^2, CA^3
fn gram(a: &M, b: &[f64], t: f64) -> M { // integral of e^(At) B B^T e^(A^T t), Simpson's rule
    let (n, nn) = (a.len(), 400); let h = t / nn as f64; let e1 = expm(a, h); let mut e = eye(n); let mut w = vec![vec![0.0; n]; n];
    for k in 0..=nn {
        let wt = (if k == 0 || k == nn { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * h / 3.0; let v = mv(&e, b);
        for i in 0..n { for j in 0..n { w[i][j] += wt * v[i] * v[j]; } } e = mm(&e, &e1);
    }
    w
}
fn solve(m0: &M, b: &[f64]) -> Vec<f64> {
    let n = m0.len(); let mut a: M = m0.iter().zip(b).map(|(r, &x)| { let mut r = r.clone(); r.push(x); r }).collect();
    for i in 0..n {
        let mut p = i; for r in i..n { if a[r][i].abs() > a[p][i].abs() { p = r; } } a.swap(i, p);
        for r in 0..n { if r != i { let q = a[r][i] / a[i][i]; let ai = a[i].clone(); for (x, y) in a[r].iter_mut().zip(&ai) { *x -= q * y; } } }
    }
    (0..n).map(|i| a[i][n] / a[i][i]).collect()
}
fn quad(x: &[f64], w: &M) -> f64 { dot(x, &mv(w, x)) }
fn plant() -> (M, Vec<f64>) { (m(&[&[0., 1., 0., 0.], &[0., 0., 0., 0.], &[0., 0., 0., 1.], &[0., 0., G / L, 0.]]), vec![0., 1., 0., -1.0 / L]) }
fn push(t: f64, eta: &[f64], tt: f64) -> f64 { // u(t) = B^T e^(A^T (T-t)) eta, written out for this A
    let (s, c) = (tt - t, 1.0 / L); eta[0] * s + eta[1] - c * eta[2] * (4.0 * s).sinh() / 4.0 - c * eta[3] * (4.0 * s).cosh()
}
fn fly(tt: f64) -> (Vec<f64>, f64, f64, Vec<f64>) { // road 2: fly the cheapest push through the plant with RK4
    let (a, b) = plant(); let eta = solve(&gram(&a, &b, tt), &[1., 0., 0., 0.]); let nn = 4000; let h = tt / nn as f64;
    let (aa, c) = (G / L, 1.0 / L); let fx = |x: &[f64], u: f64| vec![x[1], u, x[3], aa * x[2] - c * u];
    let ad = |x: &[f64], k: &[f64], s: f64| -> Vec<f64> { x.iter().zip(k).map(|(p, q)| p + s * q).collect() };
    let (mut x, mut e, mut peak) = (vec![0.0; 4], 0.0, 0.0f64);
    for k in 0..nn {
        let t = k as f64 * h; let (u0, u1, u2) = (push(t, &eta, tt), push(t + h / 2.0, &eta, tt), push(t + h, &eta, tt));
        let k1 = fx(&x, u0); let k2 = fx(&ad(&x, &k1, h / 2.0), u1); let k3 = fx(&ad(&x, &k2, h / 2.0), u1); let k4 = fx(&ad(&x, &k3, h), u2);
        x = (0..4).map(|i| x[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
        e += h / 6.0 * (u0 * u0 + 4.0 * u1 * u1 + u2 * u2); peak = peak.max(x[2].abs());
    }
    (x, e, peak, eta)
}
fn row(v: &[f64], d: usize) -> String { v.iter().map(|&x| f(x, d)).collect::<Vec<_>>().join(" ") }
fn rows(o: &M, d: usize) -> String { o.iter().map(|r| row(r, d)).collect::<Vec<_>>().join(" | ") }
fn main() {
    let (a, b) = plant(); let (aa, c) = (G / L, 1.0 / L); let at = tr(&a);
    let (cart, pivot, tip, lean) = ([1., 0., 0., 0.], [0., 0., 1., 0.], [1., 0., L, 0.], [0., 0., 0.05, 0.]);
    // ---- 1. the two rank tests ----
    let cm = ctrb(&a, &b); println!("columns B, AB, A2B, A3B: {}", rows(&tr(&cm), 4));
    println!("controllability rank {} by elimination, {} by singular values", rank(&cm), svrank(&cm));
    assert!(rank(&cm) == 4 && svrank(&cm) == 4 && (cm[3][2] + aa * c).abs() < 1e-12);
    for (name, cc, k) in [("cart encoder", cart, 2), ("pivot encoder", pivot, 2), ("tip sensor", tip, 4)] { // k: rank by hand
        let o = obsv(&a, &cc); let r3 = mm(&mm(&mm(&vec![cc.to_vec()], &a), &a), &a)[0].clone(); // C A^3 as row times A, not from the dual
        assert!((0..4).all(|j| (o[3][j] - r3[j]).abs() < 1e-12) && rank(&o) == svrank(&o) && rank(&o) == k);
        println!("{}: observability rank {}; rows {}", name, rank(&o), rows(&o, 2));
    }
    // ---- 2. what the cart encoder cannot see: rod upright vs rod leaning 0.05 rad, no push ----
    for t in [0.25, 0.5] {
        let (x1, x2) = (mv(&expm(&a, t), &[0.; 4]), mv(&expm(&a, t), &lean));
        println!("t {} s: encoder {} m and {} m; lean {} and {} rad", t, f(x1[0], 4), f(x2[0], 4), f(x1[2], 4), f(x2[2], 4));
        assert!(x1[0] == 0.0 && x2[0] == 0.0 && (x2[2] - 0.05 * (4.0 * t).cosh()).abs() < 1e-12);
    }
    // ---- 3. PBH, mode by mode: eigenvalues 0, 0, +4, -4 ----
    for lam in [0i32, 4, -4] {
        let mm0: M = (0..4).map(|i| (0..4).map(|j| if i == j { lam as f64 } else { 0.0 } - a[i][j]).collect()).collect();
        let ro: Vec<usize> = [cart, pivot, tip].iter().map(|cc| { let mut x = mm0.clone(); x.push(cc.to_vec()); rank(&x) }).collect();
        let st: M = mm0.iter().zip(&b).map(|(r, &x)| { let mut r = r.clone(); r.push(x); r }).collect();
        println!("PBH at {}: steer rank {}; see rank cart {}, pivot {}, tip {}", lam, rank(&st), ro[0], ro[1], ro[2]);
        assert!(ro[0] == if lam == 0 { 4 } else { 3 } && ro[1] == if lam == 0 { 3 } else { 4 } && ro[2] == 4);
    }
    // ---- 4. transfer functions: the cart encoder's hides the +4 pole ----
    for s in [1.0f64, 2.0] {
        let r = solve(&(0..4).map(|i| (0..4).map(|j| if i == j { s } else { 0.0 } - a[i][j]).collect()).collect(), &b); let (gc, gt) = (r[0], r[0] + L * r[2]);
        println!("G at s = {:.0}: cart {}, 1/s^2 = {}; tip {}, -16/(s^2(s^2-16)) = {}", s, f(gc, 4), f(1.0 / (s * s), 4), f(gt, 4), f(-16.0 / (s * s * (s * s - 16.0)), 4));
        assert!((gc - 1.0 / (s * s)).abs() < 1e-12 && (gt + aa / (s * s * (s * s - aa))).abs() < 1e-12);
    }
    // ---- 5. controllability Gramian: the price of moving the cart 1 m, rod upright and still at both ends ----
    let tt = 2.0; let w = gram(&a, &b, tt);
    println!("Wc(2 s) diagonal {} ; p-v entry {} ; lean entry {} x {}", row(&(0..4).map(|i| w[i][i]).collect::<Vec<_>>(), 4), f(w[0][1], 4), f(c * c / 16.0, 5), f((8.0 * tt).sinh() / 16.0 - tt / 2.0, 0));
    assert!((w[2][2] - c * c / 16.0 * ((8.0 * tt).sinh() / 16.0 - tt / 2.0)).abs() < 1e-6 * w[2][2]);
    let bare = m(&[&[0., 1.], &[0., 0.]]);
    for t in [2.0f64, 1.0, 3.0] {
        let (er, eb) = (solve(&gram(&a, &b, t), &[1., 0., 0., 0.])[0], solve(&gram(&bare, &[0., 1.], t), &[1., 0.])[0]);
        println!("1 m in {:.0} s: price {} with rod, {} bare cart (12/T^3 = {}), ratio {}", t, f(er, 3), f(eb, 3), f(12.0 / t.powi(3), 3), f(er / eb, 2));
        assert!((eb - 12.0 / t.powi(3)).abs() < 1e-9);
    }
    for t in [2.0f64, 1.0] {
        let (x, e, peak, eta) = fly(t);
        println!("flown {:.0} s: lands {} ; energy {}; peak lean {} rad = {} deg; sin off by {}%", t, row(&x, 4), f(e, 3), f(peak, 4), f(peak.to_degrees(), 1), f(100.0 * (1.0 - peak.sin() / peak), 1));
        assert!((x[0] - 1.0).abs() < 1e-4 && x[1..].iter().all(|v| v.abs() < 1e-3) && (e - eta[0]).abs() < 1e-4 * eta[0]);
    }
    let eta = solve(&w, &[1., 0., 0., 0.]);
    println!("chart t: {}", row(&(0..9).map(|k| k as f64 * 0.25).collect::<Vec<_>>(), 2));
    println!("chart push with rod: {}", row(&(0..9).map(|k| push(k as f64 * 0.25, &eta, tt)).collect::<Vec<_>>(), 3));
    println!("chart push bare cart: {}", row(&(0..9).map(|k| 6.0 / (tt * tt) * (1.0 - 2.0 * k as f64 * 0.25 / tt)).collect::<Vec<_>>(), 3));
    for st in [lean, [0., 1., 0., 0.]] { println!("price to reach {} in 2 s: {}", row(&st, 2), f(dot(&st, &solve(&w, &st)), 4)); }
    let (ev, vec) = jacobi(&w);
    println!("Wc eigenvalues {} ; hardest {}", ev.iter().map(|&e| sci(e)).collect::<Vec<_>>().join(" "), row(&vec[0], 3));
    assert!((quad(&vec[0], &w) - ev[0]).abs() < 1e-9 && (ev.iter().sum::<f64>() - (0..4).map(|i| w[i][i]).sum::<f64>()).abs() < 1e-6);
    let sc = [1.0, 1.0, 180.0 / std::f64::consts::PI, 180.0 / std::f64::consts::PI];
    let (evd, vecd) = jacobi(&(0..4).map(|i| (0..4).map(|j| sc[i] * w[i][j] * sc[j]).collect()).collect());
    println!("same, angles in degrees: smallest {} ; hardest {}", sci(evd[0]), row(&vecd[0], 3));
    // ---- 6. observability Gramian by duality: Wo(A, C) = Wc(A^T, C^T), window 0.5 s ----
    let to = 0.5;
    for (name, cc) in [("cart encoder", cart), ("tip sensor", tip), ("sensor 1 cm up the rod", [1., 0., 0.01, 0.])] {
        let wo = gram(&at, &cc, to);
        println!("Wo(0.5 s) {}: eigenvalues {} ; lean 0.05 rad gives {} m^2 s", name, jacobi(&wo).0.iter().map(|&e| sci(e)).collect::<Vec<_>>().join(" "), sci(quad(&lean, &wo)));
    }
    let direct = L * L * 0.0025 * ((8.0 * to).sinh() / 16.0 + to / 2.0); // integral of (l 0.05 cosh 4t)^2, by hand
    assert!((quad(&lean, &gram(&at, &tip, to)) - direct).abs() < 1e-9 && quad(&lean, &gram(&at, &cart, to)) < 1e-15);
    // ---- 7. outside the model, and what breaks ----
    let xp = mv(&expm(&a, 2.0), &[0., 0.1, 0., 0.]);
    println!("pivot encoder, cart drifting 0.1 m/s: after 2 s cart {} m off, lean still {} rad", f(xp[0], 4), f(xp[2], 4));
    let (bm, sm) = (1.0, 0.1); let af = m(&[&[0., 1., 0., 0.], &[0., 0., -sm * G / bm, 0.], &[0., 0., 0., 1.], &[0., 0., (bm + sm) * G / (bm * L), 0.]]);
    let wf = af[3][2].sqrt(); let pf = mv(&expm(&af, 0.5), &lean)[0];
    println!("force-driven 1 kg cart, 0.1 kg bob: cart-encoder rank {}; lean 0.05 rad moves cart {} mm in 0.5 s", rank(&obsv(&af, &cart)), f(1000.0 * pf, 2));
    assert!((pf + sm * G / bm * 0.05 * ((wf * 0.5).cosh() - 1.0) / (wf * wf)).abs() < 1e-12);
    println!("Wc lean-lean entry: T = 2 s {} ; T = 4 s {}", sci(w[2][2]), sci(gram(&a, &b, 4.0)[2][2]));
    println!("ALL CHECKS PASS");
}
