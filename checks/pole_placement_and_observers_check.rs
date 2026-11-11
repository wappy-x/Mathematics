// Pole placement and an observer for the cart and pendulum -- the check behind the card.
// std only.  State x = (p, v, theta, w): cart position m, cart speed m/s, lean rad, lean rate rad/s.
// Input u = cart acceleration the motor commands, m/s^2.  p'' = u, theta'' = 16 theta - c u, c = 1/l.
type M = Vec<Vec<f64>>;
#[derive(Clone, Copy)]
struct C64 { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> C64 { C64 { re, im } }
fn add(a: C64, b: C64) -> C64 { cx(a.re + b.re, a.im + b.im) }
fn sub(a: C64, b: C64) -> C64 { cx(a.re - b.re, a.im - b.im) }
fn mul(a: C64, b: C64) -> C64 { cx(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn div(a: C64, b: C64) -> C64 { let d = b.re * b.re + b.im * b.im; cx((a.re * b.re + a.im * b.im) / d, (a.im * b.re - a.re * b.im) / d) }
fn powi(z: C64, k: usize) -> C64 { let mut r = cx(1.0, 0.0); for _ in 0..k { r = mul(r, z); } r }
fn plant(l: f64) -> (M, Vec<f64>) {
    (vec![vec![0.0, 1.0, 0.0, 0.0], vec![0.0; 4], vec![0.0, 0.0, 0.0, 1.0], vec![0.0, 0.0, 9.81 / l, 0.0]], vec![0.0, 1.0, 0.0, -1.0 / l])
}
fn mm(x: &M, y: &M) -> M {
    (0..x.len()).map(|i| (0..y[0].len()).map(|j| (0..y.len()).fold(0.0, |s, k| s + x[i][k] * y[k][j])).collect()).collect()
}
fn tr(x: &M) -> M { (0..x[0].len()).map(|j| x.iter().map(|r| r[j]).collect()).collect() }
fn poly(roots: &[C64]) -> Vec<f64> {          // coefficients of (s - r1)(s - r2)..., highest power first
    let mut p = vec![cx(1.0, 0.0)];
    for &r in roots {
        let n = p.len(); let mut q = vec![cx(0.0, 0.0); n + 1];
        for i in 0..=n { let a = if i < n { p[i] } else { cx(0.0, 0.0) }; let b = if i > 0 { p[i - 1] } else { cx(0.0, 0.0) }; q[i] = sub(a, mul(r, b)); }
        p = q;
    }
    p.iter().map(|z| z.re).collect()
}
fn charpoly(m: &M) -> Vec<f64> {              // Faddeev-LeVerrier: det(sI - M)
    let n = m.len(); let mut mk = vec![vec![0.0; n]; n]; let mut cf = vec![1.0];
    for k in 1..=n {
        let last = cf[cf.len() - 1];
        let shifted: M = (0..n).map(|i| (0..n).map(|j| mk[i][j] + if i == j { last } else { 0.0 }).collect()).collect();
        mk = mm(m, &shifted);
        cf.push(-(0..n).fold(0.0, |s, i| s + mk[i][i]) / k as f64);
    }
    cf
}
fn roots(cf: &[f64]) -> Vec<C64> {           // Durand-Kerner
    let n = cf.len() - 1; let mut z: Vec<C64> = (0..n).map(|k| powi(cx(0.4, 0.9), k)).collect();
    for _ in 0..500 { for i in 0..n {
        let mut num = cx(0.0, 0.0); for (k, &a) in cf.iter().enumerate() { num = add(num, mul(cx(a, 0.0), powi(z[i], n - k))); }
        let mut den = cx(1.0, 0.0); for j in 0..n { if j != i { den = mul(den, sub(z[i], z[j])); } }
        z[i] = sub(z[i], div(num, den));
    } }
    let key = |w: &C64| ((w.re * 1e6).round() / 1e6, w.im);
    z.sort_by(|a, b| key(a).partial_cmp(&key(b)).unwrap()); z
}
fn stable(cf: &[f64]) -> bool {               // Routh's first column all positive
    let mut r0: Vec<f64> = cf.iter().step_by(2).cloned().collect();
    let mut r1: Vec<f64> = cf.iter().skip(1).step_by(2).cloned().collect();
    while r1.len() < r0.len() { r1.push(0.0); }
    while r1.iter().any(|v| v.abs() > 0.0) {
        if r1[0] <= 0.0 || r0[0] <= 0.0 { return false; }
        let mut nx: Vec<f64> = (0..r1.len() - 1).map(|i| r0[i + 1] - r0[0] * r1[i + 1] / r1[0]).collect(); nx.push(0.0);
        r0 = r1; r1 = nx;
    }
    r0[0] > 0.0
}
fn ackermann(a: &M, b: &[f64], target: &[f64]) -> Vec<f64> {   // last row of Ctrb^-1, times target(A)
    let n = a.len(); let mut cols: M = vec![]; let mut v: M = b.iter().map(|&x| vec![x]).collect();
    for _ in 0..n { cols.push(v.iter().map(|r| r[0]).collect()); v = mm(a, &v); }
    let mut m: M = (0..n).map(|j| { let mut r = cols[j].clone(); r.push(if j == n - 1 { 1.0 } else { 0.0 }); r }).collect();
    for i in 0..n {
        let mut piv = i; for r in i..n { if m[r][i].abs() > m[piv][i].abs() { piv = r; } } m.swap(i, piv);
        for r in 0..n { if r != i { let f = m[r][i] / m[i][i]; let mi = m[i].clone(); for (x, y) in m[r].iter_mut().zip(mi) { *x -= f * y; } } }
    }
    let q = vec![(0..n).map(|i| m[i][n] / m[i][i]).collect::<Vec<f64>>()]; let mut p = vec![vec![0.0; n]; n];
    for &t in target { let pa = mm(&p, a); p = (0..n).map(|i| (0..n).map(|j| pa[i][j] + t * if i == j { 1.0 } else { 0.0 }).collect()).collect(); }
    mm(&q, &p)[0].clone()
}
fn hand_k(t: &[f64], c: f64) -> Vec<f64> { let (k1, k2) = (-t[4] / 16.0, -t[3] / 16.0); vec![k1, k2, (k1 - 16.0 - t[2]) / c, (k2 - t[1]) / c] }
fn joined(k: &[f64], lg: &M, cm: &M, l: f64, a: &M, b: &[f64]) -> M {   // true x, estimate xh
    let (at, bt) = plant(l); let lc = mm(lg, cm); let mut out = vec![];
    for i in 0..4 { let mut r = at[i].clone(); for j in 0..4 { r.push(-bt[i] * k[j]); } out.push(r); }
    for i in 0..4 { let mut r = lc[i].clone(); for j in 0..4 { r.push(a[i][j] - b[i] * k[j] - lc[i][j]); } out.push(r); }
    out
}
struct Run { out: M, ts: f64, tp: f64, umax: f64, z: Vec<f64> }
fn simulate(m: &M, z0: &[f64], t: f64, k: Option<&[f64]>) -> Run { simulate_h(m, z0, t, k, 0.001) }
fn simulate_h(m: &M, z0: &[f64], t: f64, k: Option<&[f64]>, h: f64) -> Run {
    let f = |z: &Vec<f64>| -> Vec<f64> { m.iter().map(|r| r.iter().zip(z).fold(0.0, |s, (a, b)| s + a * b)).collect() };
    let (mut out, mut ts, mut tp, mut umax, mut z) = (vec![], 0.0, 0.0, 0.0f64, z0.to_vec());
    for i in 0..((t / h).round() as usize) {
        if i % 250 == 0 { out.push(z.clone()); }
        if z[2].abs() > 0.001 { ts = i as f64 * h; }
        if z[0].abs() > 0.01 { tp = i as f64 * h; }
        if let Some(k) = k { let n = z.len(); umax = umax.max(k.iter().zip(&z[n - 4..]).fold(0.0, |s, (a, b)| s + a * b).abs()); }
        let k1 = f(&z); let k2 = f(&z.iter().zip(&k1).map(|(a, b)| a + h / 2.0 * b).collect());
        let k3 = f(&z.iter().zip(&k2).map(|(a, b)| a + h / 2.0 * b).collect()); let k4 = f(&z.iter().zip(&k3).map(|(a, b)| a + h * b).collect());
        z = (0..z.len()).map(|i| z[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect();
    }
    Run { out, ts, tp, umax, z }
}
fn show(name: &str, v: &[f64], d: usize) { let s: Vec<String> = v.iter().map(|x| format!("{:9.*}", d, x)).collect(); println!("{:<38}{}", name, s.join("  ")); }
fn cl(k: &[f64], a: &M, b: &[f64]) -> M { (0..4).map(|i| (0..4).map(|j| a[i][j] - b[i] * k[j]).collect()).collect() }
fn blocks(o: &[C64]) -> M {                  // observer by duality: Ackermann on (A^T, C^T), transposed back
    let lc = ackermann(&tr(&vec![vec![0.0, 1.0], vec![0.0, 0.0]]), &[1.0, 0.0], &poly(o));
    let lp = ackermann(&tr(&vec![vec![0.0, 1.0], vec![16.0, 0.0]]), &[1.0, 0.0], &poly(o));
    vec![vec![lc[0], 0.0], vec![lc[1], 0.0], vec![0.0, lp[0]], vec![0.0, lp[1]]]
}
fn minus(a: &M, b: &M) -> M { (0..a.len()).map(|i| (0..a[0].len()).map(|j| a[i][j] - b[i][j]).collect()).collect() }
fn main() {
    let l0 = 9.81 / 16.0; let (a, b) = plant(l0); let c = 1.0 / l0;
    let c2: M = vec![vec![1.0, 0.0, 0.0, 0.0], vec![0.0, 0.0, 1.0, 0.0]];   // cart position, lean
    let ctrl = [cx(-3.0, 3.0), cx(-3.0, -3.0), cx(-6.0, 6.0), cx(-6.0, -6.0)]; let obs = [cx(-10.0, 0.0), cx(-10.0, 0.0)];
    let target = poly(&ctrl); let k = hand_k(&target, c); let k_ack = ackermann(&a, &b, &target);
    show("model rod l m, c 1/m, knock deg", &[l0, c, 0.05 * 180.0 / 3.141592653589793], 6);
    show("hand: k1 - 16 - a2, k2 - a3", &[k[0] - 16.0 - target[2], k[1] - target[1]], 4);
    show("target polynomial s^4..s^0", &target, 4); show("K by matching coefficients", &k, 3); show("K by Ackermann", &k_ack, 3);
    show("charpoly of A - BK", &charpoly(&cl(&k, &a, &b)), 4);
    for z in roots(&charpoly(&cl(&k, &a, &b))) { println!("  closed-loop pole  {:8.4} {:+8.4}j", z.re, z.im); }
    show("rod alone, poles -4,-4: l*32, l*8", &[(16.0 + 16.0) * l0, 8.0 * l0], 4);
    let lg = blocks(&obs); show("L, cart rows", &[lg[0][0], lg[1][0]], 4); show("L, rod rows", &[lg[2][1], lg[3][1]], 4);
    let ho = poly(&obs); let hand_l = [ho[1], ho[2], ho[1], ho[2] + 16.0]; show("L by hand: cart l1 l2, rod l1 l2", &hand_l, 4);
    show("charpoly of A - LC", &charpoly(&minus(&a, &mm(&lg, &c2))), 4);
    let j8 = joined(&k, &lg, &c2, l0, &a, &b); let all: Vec<C64> = ctrl.iter().chain(obs.iter()).chain(obs.iter()).cloned().collect();
    let prod = poly(&all); let cj = charpoly(&j8);
    show("joined charpoly, s^8..s^4", &cj[..5], 2); show("joined charpoly, s^3..s^0", &cj[5..], 2);
    show("controller x observer, s^8..s^4", &prod[..5], 2); show("controller x observer, s^3..s^0", &prod[5..], 2);
    let x0 = [0.0, 0.0, 0.05, 0.0]; let x08 = [0.0, 0.0, 0.05, 0.0, 0.0, 0.0, 0.0, 0.0];
    let sf = simulate(&cl(&k, &a, &b), &x0, 4.0, Some(&k)); let sj = simulate(&j8, &x08, 4.0, Some(&k));
    show("state fed back: rod, cart, push", &[sf.ts, sf.tp, sf.umax], 3); show("observer in loop: rod, cart, push", &[sj.ts, sj.tp, sj.umax], 3);
    let row = |name: &str, v: Vec<String>| println!("{}{}", name, v.join(" "));
    row("chart, t s      ", (0..13).map(|i| format!("{:6.2}", 0.25 * i as f64)).collect());
    row("chart, lean mrad", sj.out[..13].iter().map(|z| format!("{:6.1}", 1000.0 * z[2])).collect());
    row("chart, estimate ", sj.out[..13].iter().map(|z| format!("{:6.1}", 1000.0 * z[6])).collect());
    row("chart, exact x  ", sf.out[..13].iter().map(|z| format!("{:6.1}", 1000.0 * z[2])).collect());
    let neg: Vec<f64> = k.iter().map(|x| -x).collect();
    show("sign flipped u = +Kx, poles real", &roots(&charpoly(&cl(&neg, &a, &b))).iter().map(|z| z.re).collect::<Vec<_>>(), 3);
    let kw = ackermann(&a, &[0.0, 1.0, 0.0, c], &target);
    show("designed with +c, real poles", &roots(&charpoly(&cl(&kw, &a, &b))).iter().map(|z| z.re).collect::<Vec<_>>(), 3);
    let l1: M = vec![vec![0.0, 0.0], vec![0.0, 0.0], vec![0.0, lg[2][1]], vec![0.0, lg[3][1]]];   // angle only
    let cpa: Vec<f64> = charpoly(&minus(&a, &mm(&l1, &c2))).iter().map(|&x| if x.abs() > 1e-9 { x } else { 0.0 }).collect();
    show("angle only: charpoly A - LC", &cpa, 2);
    let bump = [0.0, 0.1, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    let zb = simulate(&joined(&k, &l1, &c2, l0, &a, &b), &bump, 10.0, None).z; let zg = simulate(&j8, &bump, 10.0, None).z;
    show("cart bumped 0.1 m/s: p, v at 10 s", &[zb[0], zb[1], zg[0], zg[1]], 4);
    let s1 = simulate(&joined(&k, &blocks(&[cx(-1.0, 0.0), cx(-1.0, 0.0)]), &c2, l0, &a, &b), &x08, 12.0, Some(&k));
    show("observer poles at -1: rod, cart, push", &[s1.ts, s1.tp, s1.umax], 3);
    let st = |l: f64| stable(&charpoly(&joined(&k, &lg, &c2, l, &a, &b)));
    let edge = |mut lo: f64, mut hi: f64| { for _ in 0..60 { let mid = (lo + hi) / 2.0; if st(mid) == st(lo) { lo = mid; } else { hi = mid; } } lo };
    let (lmin, lmax) = (edge(l0, 0.05), edge(l0, 50.0)); let mr = |l: f64| roots(&charpoly(&joined(&k, &lg, &c2, l, &a, &b))).iter().fold(f64::MIN, |m, z| m.max(z.re));
    let sl = simulate(&joined(&k, &lg, &c2, 1.1 * l0, &a, &b), &x08, 10.0, Some(&k));
    show("stable for true rod, m: from, to", &[lmin, lmax], 4); show("true rod 10% long: rod, cart, push", &[sl.ts, sl.tp, sl.umax], 3);
    let k2 = hand_k(&poly(&ctrl.iter().map(|z| mul(cx(2.0, 0.0), *z)).collect::<Vec<_>>()), c); let s2 = simulate(&cl(&k2, &a, &b), &x0, 4.0, Some(&k2));
    show("try: controller twice as fast", &[s2.ts, s2.tp, s2.umax], 3);
    let l40 = blocks(&[cx(-40.0, 0.0), cx(-40.0, 0.0)]); let s3 = simulate(&joined(&k, &l40, &c2, l0, &a, &b), &x08, 4.0, Some(&k));
    show("try: observer at -40: rod, cart, push", &[s3.ts, s3.tp, s3.umax], 3); show("  its L, rod rows", &l40[3], 1);
    let k4 = hand_k(&poly(&ctrl.iter().map(|z| cx(z.re / 2.0, z.im / 2.0)).collect::<Vec<_>>()), c); let s4 = simulate(&cl(&k4, &a, &b), &x0, 8.0, Some(&k4));
    show("try: controller half as fast", &[s4.ts, s4.tp, s4.umax], 3);
    let px = |z: C64| format!("({:.0}, {:.0})", 30.0 + 25.0 * (z.re + 11.0), 200.0 - 25.0 * z.im);
    println!("figure, 25 px per 1/s, damping {:.4}, open loop 0 0 {:.0} {:.0}; in px: controller {}, observer {}, open loop {}",
             3.0 / (ctrl[0].re * ctrl[0].re + ctrl[0].im * ctrl[0].im).sqrt(), a[3][2].sqrt(), -a[3][2].sqrt(), ctrl.iter().map(|z| px(*z)).collect::<Vec<_>>().join(" "), px(obs[0]),
             [0.0, 4.0, -4.0].iter().map(|r| px(cx(*r, 0.0))).collect::<Vec<_>>().join(" "));

    assert!(k.iter().zip(&k_ack).all(|(x, y)| (x - y).abs() < 1e-9), "matching coefficients vs Ackermann");
    assert!(charpoly(&cl(&k, &a, &b)).iter().zip(&target).all(|(x, y)| (x - y).abs() < 1e-8), "Faddeev-LeVerrier finds the chosen poles");
    assert!(cj.iter().zip(&prod).all(|(x, y)| (x - y).abs() / y.abs().max(1.0) < 1e-9), "separation: product polynomial");
    assert!(hand_l.iter().zip([lg[0][0], lg[1][0], lg[2][1], lg[3][1]]).all(|(x, y)| (x - y).abs() < 1e-9), "duality vs hand");
    let hs: Vec<f64> = [(cl(&k, &a, &b), x0.to_vec()), (j8.clone(), x08.to_vec())].iter().flat_map(|(m, z)| { let r = simulate_h(m, z, 4.0, Some(&k), 0.0005); [r.ts, r.tp] }).collect();
    assert!(sj.ts < 2.0 && sj.tp < 2.0 && sf.ts < sj.ts && hs.iter().zip([sf.ts, sf.tp, sj.ts, sj.tp]).all(|(x, y)| (x - y).abs() < 2e-3), "settles inside 2 s, observer costs time, same at half the step");
    assert!((zb[0] - 0.1 * 10.0).abs() < 1e-9 && (zb[1] - 0.1).abs() < 1e-6 && zg[0].abs() < 1e-3, "angle-only observer never sees the bump");
    assert!(!stable(&charpoly(&cl(&kw, &a, &b))) && mr(lmin + 5e-4) < 0.0 && 0.0 < mr(lmin - 5e-4) && mr(lmax - 5e-4) < 0.0 && 0.0 < mr(lmax + 5e-4) && sl.ts < 10.0, "wrong sign fails; Routh edges match the roots");
    println!("ALL CHECKS PASS");
}
