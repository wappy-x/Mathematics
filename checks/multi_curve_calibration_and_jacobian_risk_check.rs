// Multi-curve calibration and Jacobian risk -- the check behind the card.  std only.
// Two curves (overnight discount D, 3-month projection H), zero rates at 1, 2, 3 years,
// solved jointly by Newton on six quotes; then node risk -> quote risk by the inverse Jacobian.
const PIL: [f64; 3] = [1.0, 2.0, 3.0]; const BP: f64 = 1e-4;
const MKT: [f64; 6] = [0.0420, 0.0440, 0.0455, 0.0009, 0.00095, 0.0010]; // OIS 1y 2y 3y; basis 1y 2y 3y
const NAMES: [&str; 6] = ["OIS 1y", "OIS 2y", "OIS 3y", "basis 1y", "basis 2y", "basis 3y"];
const N: f64 = 10_000_000.0; const K: f64 = 0.045; // test swap: receive 3-month index, pay 4.5% twice a year, 2.5 years
type V6 = Vec<f64>;
fn zero(t: f64, n: &[f64]) -> f64 { // straight line between pillars, flat outside them
    if t <= PIL[0] || t >= PIL[2] { return if t <= PIL[0] { n[0] } else { n[2] }; }
    let k = if t <= PIL[1] { 0 } else { 1 };
    (1.0 - (t - PIL[k])) * n[k] + (t - PIL[k]) * n[k + 1]
}
fn df(t: f64, n: &[f64]) -> f64 { (-zero(t, n) * t).exp() }
fn qgrid(m: usize) -> V6 { (0..=4 * m).map(|i| 0.25 * i as f64).collect() }
fn index_leg(x: &[f64], ts: &[f64]) -> f64 { // forecast off H, discount off D
    let (d, h, mut s) = (&x[..3], &x[3..], 0.0);
    for i in 1..ts.len() { s += (df(ts[i - 1], h) / df(ts[i], h) - 1.0) * df(ts[i], d); }
    s
}
fn ann_y(x: &[f64], m: usize) -> f64 { let mut s = 0.0; for k in 1..=m { s += df(k as f64, &x[..3]); } s }
fn ann_q(x: &[f64], m: usize) -> f64 { let mut s = 0.0; for t in &qgrid(m)[1..] { s += 0.25 * df(*t, &x[..3]); } s }
fn quotes(x: &[f64]) -> V6 { // the six model quotes the curves imply
    let mut out: V6 = (1..=3).map(|m| (1.0 - df(m as f64, &x[..3])) / ann_y(x, m)).collect();
    for m in 1..=3 { out.push((index_leg(x, &qgrid(m)) - (1.0 - df(m as f64, &x[..3]))) / ann_q(x, m)); }
    out
}
fn jac(x: &[f64], rows: &[usize], cols: &[usize]) -> Vec<V6> { // central differences
    let (h, mut j) = (1e-7, vec![vec![0.0; cols.len()]; rows.len()]);
    for (c, &jj) in cols.iter().enumerate() {
        let (mut u, mut v) = (x.to_vec(), x.to_vec()); u[jj] += h; v[jj] -= h;
        let (fu, fv) = (quotes(&u), quotes(&v));
        for (r, &i) in rows.iter().enumerate() { j[r][c] = (fu[i] - fv[i]) / (2.0 * h); }
    }
    j
}
fn solve(a: &[V6], b: &[f64]) -> V6 { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<V6> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } } m.swap(c, p);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            for k in c..=n { m[r][k] -= f * m[c][k]; }
        }
    }
    let mut x = vec![0.0; n]; for r in (0..n).rev() {
        let mut s = 0.0; for k in r + 1..n { s += m[r][k] * x[k]; }
        x[r] = (m[r][n] - s) / m[r][r];
    } x
}
fn newton(mkt: &[f64], x0: &[f64], free: &[usize], stale: bool, log: &mut V6) -> (V6, usize) {
    let (mut x, mut j): (V6, Option<Vec<V6>>) = (x0.to_vec(), None);
    for it in 0..60 {
        let q = quotes(&x);
        let r: V6 = free.iter().map(|&i| q[i] - mkt[i]).collect();
        let e = r.iter().fold(0.0f64, |a, v| a.max(v.abs())); log.push(e / BP);
        if e < 1e-14 { return (x, it); }
        if j.is_none() || !stale { j = Some(jac(&x, free, free)); }
        let s = solve(j.as_ref().unwrap(), &r);
        for (k, &i) in free.iter().enumerate() { x[i] -= s[k]; }
    }
    panic!("Newton did not converge");
}
fn nt(mkt: &[f64], x0: &[f64]) -> V6 { newton(mkt, x0, &[0, 1, 2, 3, 4, 5], false, &mut vec![]).0 }
fn bisect(g: &mut dyn FnMut(f64) -> f64) -> f64 { // road 2: one node at a time, no derivatives
    let (mut lo, mut hi) = (-0.5, 0.5);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (g(lo) > 0.0) == (g(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn bootstrap(mkt: &[f64]) -> V6 {
    let mut x = vec![0.0; 6];
    for i in 0..6 {
        let z = bisect(&mut |z| { x[i] = z; quotes(&x)[i] - mkt[i] }); x[i] = z;
    }
    x
}
fn swap(x: &[f64]) -> f64 {
    let mut fx = 0.0; for j in 1..=5 { fx += 0.5 * K * df(0.5 * j as f64, &x[..3]); }
    N * (index_leg(x, &qgrid(3)[..11]) - fx)
}
fn node_risk(f: &dyn Fn(&[f64]) -> f64, x: &[f64]) -> V6 { // dollars per 1bp up at each node
    (0..6).map(|j| { let (mut u, mut v) = (x.to_vec(), x.to_vec()); u[j] += BP; v[j] -= BP; (f(&u) - f(&v)) / 2.0 }).collect()
}
fn show(label: &str, vals: &[f64], w: usize, p: usize) {
    let mut s = format!("{:<30}", label);
    for &v in vals { s += &format!("{:>w$.p$}", if v.abs() < 1e-6 { 0.0 } else { v }, w = w, p = p); }
    println!("{}", s);
}
fn sci(v: f64) -> String { // Python's {:.3e}: two-digit exponent with a sign
    let s = format!("{:.3e}", v); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn tot(v: &[f64]) -> f64 { let mut s = 0.0; for x in v { s += x; } s }
fn main() {
    let (all, mut misses) = ([0usize, 1, 2, 3, 4, 5], vec![]);
    let (x, iters) = newton(&MKT, &[0.0; 6], &all, false, &mut misses);
    for (it, e) in misses.iter().enumerate() { println!("Newton step {}: largest quote miss {} bp", it, sci(*e)); }
    let xb = bootstrap(&MKT);
    show("nodes, Newton (zero %)", &x.iter().map(|v| 100.0 * v).collect::<V6>(), 12, 6);
    show("nodes, bootstrap (zero %)", &xb.iter().map(|v| 100.0 * v).collect::<V6>(), 12, 6);
    let g1 = (x[0] / 4.0).exp(); // by hand: inside one year both curves are flat
    println!("D(1) {:.8}  e^(zD1/4) {:.8}  + s/4 = {:.8}  zH1 {:.6} %", df(1.0, &x[..3]), g1, g1 + MKT[3] / 4.0, 400.0 * (g1 + MKT[3] / 4.0).ln());
    let gap = (0..6).fold(0.0f64, |a, i| a.max((x[i] - xb[i]).abs())) / BP;
    let j = jac(&x, &all, &all);
    for i in 0..6 { show(&format!("Jacobian row {}", NAMES[i]), &j[i], 10, 5); }
    let (v0, rz) = (swap(&x), node_risk(&swap, &x));
    let jt: Vec<V6> = (0..6).map(|c| (0..6).map(|r| j[r][c]).collect()).collect();
    let rq = solve(&jt, &rz); // quote risk = J^-T times node risk
    let (mut fwd, mut cen) = (vec![], vec![]);
    for i in 0..6 {
        let (mut up, mut dn) = (MKT.to_vec(), MKT.to_vec()); up[i] += BP; dn[i] -= BP;
        let (vu, vd) = (swap(&nt(&up, &x)), swap(&nt(&dn, &x)));
        fwd.push(vu - v0); cen.push((vu - vd) / 2.0);
    }
    println!("test swap value {:.2}", v0);
    show("node risk ($ per bp)", &rz, 10, 2);
    for k in (0..6).rev() { // J is lower triangular, so J^T y = Rz solves from the bottom up
        let mut s = 0.0; for i in k + 1..6 { s += j[i][k] * rq[i]; }
        let num = rz[k] - s;
        println!("  back-substitute {:<9} ({:.2} -> {:.2}) / {:.5} = {:.2}", NAMES[k], rz[k], num, j[k][k], num / j[k][k]);
    }
    println!("totals: node D {:.2}  node H {:.2}  quote OIS {:.2}  quote basis {:.2}", tot(&rz[..3]), tot(&rz[3..]), tot(&rq[..3]), tot(&rq[3..]));
    show("quote risk, J^-T ($ per bp)", &rq, 10, 2);
    show("quote risk, rebuild +1bp", &fwd, 10, 2);
    show("quote risk, rebuild central", &cen, 10, 2);
    let ois2 = |x: &[f64]| N * ((1.0 - df(2.0, &x[..3])) - MKT[1] * ann_y(x, 2)); // 2y OIS, pay fixed at par
    let own = solve(&jt, &node_risk(&ois2, &x));
    show("2y OIS par swap, J^-T", &own, 10, 2);
    let mut annuity_bp: V6 = (1..=3).map(|m| ann_y(&x, m) * BP).collect(); for m in 1..=3 { annuity_bp.push(ann_q(&x, m) * BP); }
    let hedge: V6 = (0..6).map(|i| rq[i] / annuity_bp[i]).collect();
    show("hedge notionals (millions)", &hedge.iter().map(|h| h / 1e6).collect::<V6>(), 10, 4);
    let hedged = |x: &[f64]| { // test swap minus the six par instruments, sized by quote risk
        let mut v = swap(x);
        for (i, &m) in [1usize, 2, 3].iter().enumerate() {
            v -= hedge[i] * ((1.0 - df(m as f64, &x[..3])) - MKT[i] * ann_y(x, m));
            v -= hedge[3 + i] * (index_leg(x, &qgrid(m)) - (1.0 - df(m as f64, &x[..3])) - MKT[3 + i] * ann_q(x, m));
        }
        v
    };
    let hz = node_risk(&hedged, &x).iter().fold(0.0f64, |a, v| a.max(v.abs()));
    println!("hedged book, largest node risk {:.4}", hz);
    // ---- what breaks ----
    let mut frozen = vec![]; // rebuild only the OIS curve, hold projection nodes still
    for i in 0..3 {
        let (mut up, mut dn) = (MKT.to_vec(), MKT.to_vec()); up[i] += BP; dn[i] -= BP;
        let xu = newton(&up, &x, &[0, 1, 2], false, &mut vec![]).0;
        let xd = newton(&dn, &x, &[0, 1, 2], false, &mut vec![]).0;
        frozen.push((swap(&xu) - swap(&xd)) / 2.0);
    }
    show("wrong: projection frozen", &frozen, 10, 2);
    show("wrong: J^-1 not J^-T", &solve(&j, &rz), 10, 2);
    println!("wrong: node risk as quote risk, OIS risk missed {:.2}", tot(&rq[..3]) - tot(&rz[..3]));
    // ---- try changing ----
    let chord = newton(&MKT, &[0.0; 6], &all, true, &mut vec![]).1; println!("try: stale Jacobian, steps {}", chord);
    println!("try: start at 20% everywhere, steps {}", newton(&MKT, &[0.20; 6], &all, false, &mut vec![]).1);
    let xz = nt(&[MKT[0], MKT[1], MKT[2], 0.0, 0.0, 0.0], &x);
    println!("try: zero basis, largest gap H - D {:.6} bp", (0..3).fold(0.0f64, |a, k| a.max((xz[3 + k] - xz[k]).abs())) / BP);
    assert!(iters <= 5 && gap < 1e-8 && (x[3] - 4.0 * (g1 + MKT[3] / 4.0).ln()).abs() < 1e-12 && (df(1.0, &x) - 1.0 / 1.042).abs() < 1e-12);
    assert!((0..6).all(|i| (rq[i] - cen[i]).abs() < 1e-3)); // Jacobian risk = bump and rebuild
    assert!((0..6).all(|i| (rq[i] - fwd[i]).abs() < 0.1)); // forward bump differs only by convexity
    assert!((own[1] - N * ann_y(&x, 2) * BP).abs() < 1e-4 && [0, 2, 3, 4, 5].iter().all(|&k| own[k].abs() < 1e-4));
    assert!(hz < 1e-4 && chord > iters && (tot(&frozen) - tot(&rq[..3])).abs() > 1000.0);
    println!("ALL CHECKS PASS");
}
