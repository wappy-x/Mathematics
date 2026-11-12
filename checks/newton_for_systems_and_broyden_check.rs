// Newton for systems and Broyden: the same check as the Python, in Rust.  No crates.
// Two mixing tanks: find the stock flow p and water flow q (L/s) that hold tank 1 at
// 4 mg/L and tank 2 at 2.5 mg/L.  A closed form, Newton and Broyden must all agree.
type V = [f64; 2];
type M = [[f64; 2]; 2];
const C0: f64 = 10.0; const C1: f64 = 4.0; const C2: f64 = 2.5;   // mg/L
const K: f64 = 0.002; const B1: f64 = 4.0; const B2: f64 = 40.0;  // decay 1/s, tank sizes s^2/L
fn sci(v: f64) -> String { format!("{:.2e}", v) }                // 1.25e-9
fn f(v: V) -> V {                             // the two balances, mg/s: in - out - decayed
    let s = v[0] + v[1];
    [C0 * v[0] - C1 * s * (1.0 + K * B1 * s), C1 * s - C2 * s * (1.0 + K * B2 * s)]
}
fn jac(v: V) -> M {                           // Jacobian: one row per balance, one column per flow
    let s = v[0] + v[1];
    let (h, g) = (C1 * (1.0 + 2.0 * K * B1 * s), C1 - C2 * (1.0 + 2.0 * K * B2 * s));
    [[C0 - h, -h], [g, g]]
}
fn det(a: M) -> f64 { a[0][0] * a[1][1] - a[0][1] * a[1][0] }
fn inv(a: M) -> M { let d = det(a); [[a[1][1] / d, -a[0][1] / d], [-a[1][0] / d, a[0][0] / d]] }
fn mv(a: M, v: V) -> V { [a[0][0] * v[0] + a[0][1] * v[1], a[1][0] * v[0] + a[1][1] * v[1]] }
fn mm(a: M, b: M) -> M {
    let mut c = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { c[i][j] = a[i][0] * b[0][j] + a[i][1] * b[1][j] } }
    c
}
fn sub(a: V, b: V) -> V { [a[0] - b[0], a[1] - b[1]] }
fn nrm(v: V) -> f64 { (v[0] * v[0] + v[1] * v[1]).sqrt() }
fn norm2(a: M) -> f64 {                       // largest stretch of a 2x2 matrix
    let t = a[0][0] * a[0][0] + a[0][1] * a[0][1] + a[1][0] * a[1][0] + a[1][1] * a[1][1];
    ((t + (t * t - 4.0 * det(a) * det(a)).sqrt()) / 2.0).sqrt()
}
fn newton(mut v: V, n: usize) -> Vec<V> {
    let mut out = vec![v];
    for _ in 0..n {
        if f(v) == [0.0, 0.0] { break }
        v = sub(v, mv(inv(jac(v)), f(v))); out.push(v);
    }
    out
}
fn broyden(mut v: V, mut h: M, n: usize) -> (Vec<V>, f64, M, V, f64, Vec<(M, V)>) {  // h: inverse of B
    let (mut out, mut fv, mut b, mut hb) = (vec![v], f(v), inv(h), 0.0f64);
    let (mut sec, mut s3, mut tab) = ([0.0; 2], 0.0, Vec::new());
    for _ in 0..n {
        let d0 = mv(h, fv); let d = [-d0[0], -d0[1]];
        let w = [v[0] + d[0], v[1] + d[1]]; let fw = f(w); let y = sub(fw, fv);
        if d == [0.0, 0.0] || y == [0.0, 0.0] { break }
        let hy = mv(h, y); tab.push((b, d));                    // each B_k with its step s_k
        let sh = [d[0] * h[0][0] + d[1] * h[1][0], d[0] * h[0][1] + d[1] * h[1][1]];
        let (den, u, r) = (d[0] * hy[0] + d[1] * hy[1], sub(d, hy), sub(y, mv(b, d)));
        for i in 0..2 { for j in 0..2 {
            h[i][j] += u[i] * sh[j] / den;
            b[i][j] += r[i] * d[j] / (d[0] * d[0] + d[1] * d[1]);
        } }
        let p = mm(h, b);
        hb = hb.max((p[0][0] - 1.0).abs() + p[0][1].abs() + p[1][0].abs() + (p[1][1] - 1.0).abs());
        if out.len() == 3 { sec = sub(mv(b, d), y); s3 = nrm(y) }   // secant condition B s = y
        v = w; fv = fw; out.push(v);
    }
    (out, hb, b, sec, s3, tab)
}
fn order(e: &[f64], k: usize) -> f64 { (e[k + 1] / e[k]).ln() / (e[k] / e[k - 1]).ln() }
fn closed(c2: f64, k: f64) -> (f64, f64) {    // road 1: tank 2 fixes the total, tank 1 the split
    let u = (C1 / c2 - 1.0) / (k * B2);
    (u, C1 * u * (1.0 + k * B1 * u) / C0)
}
fn first(e: &[f64]) -> usize { e.iter().position(|&v| v < 1e-9).unwrap() }
fn commas(n: u64) -> String {
    let s = n.to_string(); let mut o = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(',') } o.push(ch) }
    o
}
fn pts(e: &[f64]) -> String {
    (0..10).map(|k| format!("{:.2}", e.get(k).copied().unwrap_or(0.0).max(1e-16).log10()))
        .collect::<Vec<_>>().join(", ")
}
fn main() {
    let (s_, x_) = closed(C2, K);
    let root = [x_, s_ - x_];
    let err = |v: V| nrm(sub(v, root));
    println!("closed form: total {:.4} L/s, stock p* = {:.4}, water q* = {:.4} L/s", s_, root[0], root[1]);
    println!("tanks at the answer: {:.1} L and {:.1} L, stays {:.1} s and {:.1} s", B1 * s_ * s_, B2 * s_ * s_, B1 * s_, B2 * s_);
    let js = jac(root);
    println!("J(x*) = [[{:.2}, {:.2}], [{:.2}, {:.2}]], det {:.2}, ||J^-1|| = {:.4}, kappa = {:.2}",
             js[0][0], js[0][1], js[1][0], js[1][1], det(js), norm2(inv(js)), norm2(js) * norm2(inv(js)));
    let (m1, m2) = (2.0 * C1 * K * B1, 2.0 * C2 * K * B2);
    let l = 2.0 * (m1 * m1 + m2 * m2).sqrt();  // Lipschitz constant of J
    let x0 = [2.0, 6.0];                       // yesterday's settings
    let j0 = jac(x0); let st = mv(inv(j0), f(x0));
    println!("Newton step 1 by hand: J(x0) = [[{:.3}, {:.3}], [{:.3}, {:.3}]], det {:.3}, step ({:.6}, {:.6})",
             j0[0][0], j0[0][1], j0[1][0], j0[1][1], det(j0), -st[0], -st[1]);
    let s0 = x0[0] + x0[1]; let c = C0 * x0[0] / (s0 * (1.0 + K * B1 * s0));
    println!("yesterday's flows (2, 6) give tanks {:.4} and {:.4} mg/L; residual F = ({:.4}, {:.4}) mg/s",
             c, c / (1.0 + K * B2 * s0), f(x0)[0], f(x0)[1]);
    let nw = newton(x0, 6); let en: Vec<f64> = nw.iter().map(|&v| err(v)).collect();
    println!("Newton from (2, 6)  k  stock p   water q   residual   error     e_k/e_(k-1)^2  bound");
    for k in 0..5 {
        let rat = if k == 0 { "-".to_string() } else if k < 4 { format!("{:.4}", en[k] / (en[k - 1] * en[k - 1])) } else { "floor".to_string() };
        let bd = if k > 0 && k < 4 { l / 2.0 * norm2(inv(jac(nw[k - 1]))) * en[k - 1] * en[k - 1] } else { 0.0 };
        if bd != 0.0 { assert!(en[k] <= bd) }  // the theorem's bound holds at every step above the floor
        println!("{:19} {}  {:.6}  {:.6}  {:>9}  {:>9}  {:>13}  {:>8}", "", k, nw[k][0], nw[k][1], sci(nrm(f(nw[k]))),
                 sci(en[k]), rat, if bd != 0.0 { sci(bd) } else { "-".to_string() });
    }
    println!("order at steps 2, 3: {:.3}, {:.3}; constant (L/2)||J*^-1|| = {:.4}, L = 2 sqrt({:.3}^2 + {:.3}^2) = {:.4}",
             order(&en, 1), order(&en, 2), l / 2.0 * norm2(inv(js)), m1, m2, l);
    println!("guaranteed start radius 1/(2 L ||J*^-1||) = {:.2} L/s; yesterday's start is {} away", 1.0 / (2.0 * l * norm2(inv(js))), sci(en[0]));
    let bt = |k: usize| l / 2.0 * norm2(inv(jac(nw[k - 1]))) * en[k - 1] * en[k - 1] / en[k];
    println!("bound / true error at steps 2, 3: {:.4}, {:.4}", bt(2), bt(3));
    let est = nrm(f(nw[3])) * norm2(inv(jac(nw[3])));
    println!("error estimate at step 3: residual x ||J^-1|| = {}, true error {}, ratio {:.4}", sci(est), sci(en[3]), est / en[3]);
    assert!(en[3] <= est && est < 1.1 * en[3]);
    let (bs, hb, b, sec, s3, tab) = broyden(x0, inv(jac(x0)), 7);
    let eb: Vec<f64> = bs.iter().map(|&v| err(v)).collect();
    println!("Broyden from (2, 6) k  stock p   water q   residual   error     e_k/e_(k-1)");
    for k in 0..6 {
        println!("{:19} {}  {:.6}  {:.6}  {:>9}  {:>9}  {:>11}", "", k, bs[k][0], bs[k][1], sci(nrm(f(bs[k]))),
                 sci(eb[k]), if k > 0 { sci(eb[k] / eb[k - 1]) } else { "-".to_string() });
    }
    println!("orders at steps 3, 4: {:.3}, {:.3}; secant miss |B s - y| = {} of |y| = {}",
             order(&eb, 2), order(&eb, 3), sci(nrm(sec)), sci(s3));
    let dm: Vec<f64> = tab.iter().map(|&(bk, d)| nrm(sub(mv(bk, d), mv(js, d))) / nrm(d)).collect();
    let gap: Vec<f64> = tab.iter().map(|&(bk, _)| norm2([[bk[0][0] - js[0][0], bk[0][1] - js[0][1]],
                                                         [bk[1][0] - js[1][0], bk[1][1] - js[1][1]]])).collect();
    let b5 = tab[5].0;
    println!("Sherman-Morrison: largest |H B - I| over the run = {}; B_5 = [[{:.2}, {:.2}], [{:.2}, {:.2}]] against J(x*) above",
             sci(hb), b5[0][0], b5[0][1], b5[1][0], b5[1][1]);
    println!("Dennis-More, k = 0-5: |(B_k - J*) s_k|/|s_k| = {}; ||B_k - J*|| = {}", dm[..6].iter().map(|&v| sci(v)).collect::<Vec<_>>().join(", "),
             gap[..6].iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(", "));
    println!("at the floor, k = 5, 6: |s_k| = {}, {}; after them B_7 = [[{:.2}, {:.2}], [{:.2}, {:.2}]]",
             sci(nrm(tab[5].1)), sci(nrm(tab[6].1)), b[0][0], b[0][1], b[1][0], b[1][1]);
    assert!((det(js) - C0 * (C1 - C2 * (1.0 + 2.0 * K * B2 * s_))).abs() < 1e-12);  // det J = c0 g
    assert!(nrm(f(root)) < 1e-12 && err(nw[5]) < 1e-14 && err(bs[6]) < 1e-14);     // three roads meet
    assert!((order(&en, 2) - 2.0).abs() < 0.05);
    assert!((en[3] / (en[2] * en[2]) - en[2] / (en[1] * en[1])).abs() < 0.01);
    assert!(eb[5] / eb[4] < eb[4] / eb[3] && eb[4] / eb[3] < eb[3] / eb[2] && eb[3] / eb[2] < 0.2);
    assert!(nrm(sec) < 1e-14 * s3 && hb < 1e-12 && dm[4] < 1e-3 * dm[2] && gap[4] > 0.05);  // B fits its steps, not J*
    let hc = inv(jac(x0));                     // break: freeze the first Jacobian
    let mut ch = vec![x0];
    while err(ch[ch.len() - 1]) >= 1e-9 { let v = ch[ch.len() - 1]; ch.push(sub(v, mv(hc, f(v)))) }
    let ec: Vec<f64> = ch.iter().map(|&v| err(v)).collect();
    let (nn, nb, nc) = (first(&en), first(&eb), ch.len() - 1);
    println!("to an error under 1e-9 L/s: Newton {} steps, Broyden {}, frozen Jacobian {} (ratio {:.4})",
             nn, nb, nc, ec[nc] / ec[nc - 1]);
    println!("evaluations of F, a Jacobian column costing one: Newton {}, Broyden {}, frozen {}", 3 * nn, nb + 2, nc + 2);
    assert!(nn == 4 && nb == 5 && 0.1 < ec[nc] / ec[nc - 1] && ec[nc] / ec[nc - 1] < 0.13 && nc > 2 * nn);
    let sg = (C1 / C2 - 1.0) / (2.0 * K * B2); // where the tank-2 row of J vanishes
    println!("break 1, start total {:.2} L/s, e.g. (1, {:.2}): det J = {:.1}, no Newton step", sg, sg - 1.0, det(jac([1.0, sg - 1.0])));
    let z = newton([1.0, 2.0], 40); let zl = z[z.len() - 1];
    println!("break 2, start (1, 2): Newton ends at ({:.1}, {:.1}) after {} steps, the empty plant, residual {}",
             zl[0].abs(), zl[1].abs(), z.len() - 1, sci(nrm(f(zl))));
    assert!(det(jac([1.0, sg - 1.0])).abs() < 1e-12 && err(zl) > 5.0 && nrm(zl) < 1e-12);
    let bi = broyden(x0, [[1.0, 0.0], [0.0, 1.0]], 20).0;
    println!("break 3, Broyden with B0 = I: errors {}, {} at steps 1, 5; step 20 at ({:.4}, {:.4}), error {}",
             sci(err(bi[1])), sci(err(bi[5])), bi[20][0].abs(), bi[20][1].abs(), sci(err(bi[20])));
    assert!(err(bi[20]) > 5.0 && nrm(bi[20]) < 1e-3);
    let ((u2, p2), (u3, p3)) = (closed(2.0, K), closed(C2, K / 2.0));
    let n3: Vec<f64> = newton([3.0, 3.0], 9).iter().map(|&v| err(v)).collect();
    let b3: Vec<f64> = broyden([3.0, 3.0], inv(jac([3.0, 3.0])), 9).0.iter().map(|&v| err(v)).collect();
    println!("try: tank 2 at 2.0 mg/L gives total {:.2}, p {:.4}, q {:.4}; decay k halved gives total {:.2}, p {:.4}, q {:.4}",
             u2, p2, u2 - p2, u3, p3, u3 - p3);
    println!("try: from (3, 3), Newton {} steps, Broyden {}", first(&n3), first(&b3));
    assert!((p2 - 5.5).abs() < 1e-12 && (u3 - 2.0 * s_).abs() < 1e-12);
    for n in [2u64, 500] {
        println!("cost per step at n = {}: Newton {} evaluations + about {} flops; Broyden 1 evaluation + about {} flops",
                 n, n + 1, commas(((2 * n * n * n) as f64 / 3.0).round() as u64), commas(8 * n * n));
    }
    println!("chart, log10 error, steps 0-9: Newton {}", pts(&en));
    println!("chart, Broyden {}", pts(&eb));
    println!("chart, frozen  {}", pts(&ec));
    println!("ALL CHECKS PASS");
}
