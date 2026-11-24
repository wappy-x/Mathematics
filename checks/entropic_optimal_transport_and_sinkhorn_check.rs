// Entropic optimal transport and Sinkhorn -- the check behind the card.  std only, no crates.
// The same roads as the Python check, printing the same lines.
type M = Vec<Vec<f64>>;
fn psum(xs: &[f64]) -> f64 { // compensated sum, as Python's sum() does it
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for &x in xs { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s } s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn kernel(c: &M, eps: f64) -> M { c.iter().map(|r| r.iter().map(|x| (-x / eps).exp()).collect()).collect() }
fn plan(u: &[f64], k: &M, v: &[f64]) -> M { (0..u.len()).map(|i| (0..v.len()).map(|j| u[i] * k[i][j] * v[j]).collect()).collect() }
fn tr(p: &M) -> M { (0..p[0].len()).map(|j| p.iter().map(|r| r[j]).collect()).collect() }
fn rowerr(p: &M, a: &[f64]) -> f64 { psum(&(0..a.len()).map(|i| (psum(&p[i]) - a[i]).abs()).collect::<Vec<_>>()) }
fn cost(c: &M, p: &M) -> f64 { psum(&(0..p.len()).flat_map(|i| (0..p[0].len()).map(move |j| (i, j))).map(|(i, j)| c[i][j] * p[i][j]).collect::<Vec<_>>()) }
fn ent(p: &[f64]) -> f64 { -psum(&p.iter().filter(|&&x| x > 0.0).map(|&x| x * x.ln()).collect::<Vec<_>>()) }
fn hh(p: &M) -> f64 { ent(&p.concat()) }
fn sinkhorn(a: &[f64], b: &[f64], k: &M, iters: usize, tol: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let (mut u, mut v, mut errs) = (vec![], vec![1.0; b.len()], vec![]);
    for _ in 0..iters {
        u = (0..a.len()).map(|i| a[i] / psum(&(0..b.len()).map(|j| k[i][j] * v[j]).collect::<Vec<_>>())).collect();
        v = (0..b.len()).map(|j| b[j] / psum(&(0..a.len()).map(|i| k[i][j] * u[i]).collect::<Vec<_>>())).collect();
        errs.push(rowerr(&plan(&u, k, &v), a));
        if *errs.last().unwrap() < tol { break; }
    }
    (u, v, errs)
}
fn dot(x: &[f64], y: &[f64]) -> f64 { psum(&x.iter().zip(y).map(|(p, q)| p * q).collect::<Vec<_>>()) }
fn dual(a: &[f64], b: &[f64], c: &M, u: &[f64], v: &[f64], eps: f64) -> f64 {
    let phi: Vec<f64> = u.iter().map(|x| eps * (x.ln() + 1.0)).collect();
    let psi: Vec<f64> = v.iter().map(|x| eps * x.ln()).collect();
    let ex: Vec<f64> = (0..a.len()).flat_map(|i| (0..b.len()).map(move |j| (i, j))).map(|(i, j)| ((phi[i] + psi[j] - c[i][j]) / eps - 1.0).exp()).collect();
    dot(&phi, a) + dot(&psi, b) - eps * psum(&ex)
}
fn sci(x: f64) -> String {
    let s = format!("{:.1e}", x); let (m, e) = s.split_once('e').unwrap(); let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn f6(m: &M) -> String { format!("[{}]", m.iter().map(|r| format!("[{}]", r.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(", "))).collect::<Vec<_>>().join(", ")) }
fn lse(xs: &[f64]) -> f64 { let m = xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max); m + psum(&xs.iter().map(|x| (x - m).exp()).collect::<Vec<_>>()).ln() }
fn logsink(a: &[f64], b: &[f64], c: &M, ep: f64, tol: f64) -> (usize, M) {
    let mut g = vec![0.0; 3];
    for k in 1..100000 {
        let f: Vec<f64> = (0..3).map(|i| ep * a[i].ln() - ep * lse(&(0..3).map(|j| (g[j] - c[i][j]) / ep).collect::<Vec<_>>())).collect();
        g = (0..3).map(|j| ep * b[j].ln() - ep * lse(&(0..3).map(|i| (f[i] - c[i][j]) / ep).collect::<Vec<_>>())).collect();
        let p: M = (0..3).map(|i| (0..3).map(|j| ((f[i] + g[j] - c[i][j]) / ep).exp()).collect()).collect();
        if rowerr(&p, a) < tol { return (k, p); }
    }
    panic!("no convergence")
}
fn main() {
    // 1. the 2-by-2 example: down days and up days, half each, both years; eps = 1
    let (a2, c2, eps) = (vec![0.5, 0.5], vec![vec![0.0, 1.0], vec![1.0, 0.0]], 1.0f64);
    let k = kernel(&c2, eps); let (u, v, e) = sinkhorn(&a2, &a2, &k, 1, 0.0);
    let p = plan(&u, &k, &v); let val = cost(&c2, &p) - eps * hh(&p);
    println!("2x2, eps = 1: K = {}; after sweep 1: u = ({:.6}, {:.6}), v = ({:.6}, {:.6})", f6(&k), u[0], u[1], v[0], v[1]);
    println!("  row sums of K v_0 = K (1, 1): {:.6}, {:.6}", psum(&k[0]), psum(&k[1]));
    println!("  plan {}, row error {}", f6(&p), sci(e[0]));
    println!("  cost {:.6}, entropy {:.6} nats, value {:.6}; dual value {:.6}", cost(&c2, &p), hh(&p), val, dual(&a2, &a2, &c2, &u, &v, eps));
    let q2 = |t: f64| vec![vec![0.5 - t, t], vec![t, 0.5 - t]];
    let val2 = |t: f64, eps: f64| { let q = q2(t); cost(&c2, &q) - eps * hh(&q) };
    let (mut lo, mut hi, r) = (1e-12, 0.5 - 1e-12, (5.0f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (x1, x2) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if val2(x1, eps) <= val2(x2, eps) { hi = x2 } else { lo = x1 }
    }
    let t = (lo + hi) / 2.0; let closed = 0.5 / (1.0 + (1.0 / eps).exp());
    println!("  search: off-diagonal {:.6}; closed form 0.5/(1 + e^(1/eps)) = {:.6}; value {:.6}", t, closed, val2(t, eps));
    let cr = |q: &M| q[0][0] * q[1][1] / (q[0][1] * q[1][0]);
    println!("  cross-ratio P00 P11/(P01 P10): Sinkhorn {:.6}, search {:.5}, e^2 = {:.6}", cr(&p), cr(&q2(t)), 2.0f64.exp());
    assert!((t - p[0][1]).abs() < 1e-7 && (closed - p[0][1]).abs() < 1e-12 && (cr(&p) - 2.0f64.exp()).abs() < 1e-9);
    assert!((dual(&a2, &a2, &c2, &u, &v, eps) - val).abs() < 1e-12 && val < val2(0.0, eps));
    println!("  exact plan [[0.5, 0], [0, 0.5]]: cost 0, value {:.6}; bias bound eps*min(H(a), H(b)) = {:.6}", -(2.0f64.ln()), ent(&a2));
    for ep in [1.0, 0.5, 0.25, 0.1] {
        let k = kernel(&c2, ep); let (u, v, _) = sinkhorn(&a2, &a2, &k, 1, 0.0); let c = cost(&c2, &plan(&u, &k, &v));
        println!("  eps = {:<4}: cost {:.6}, 1/(1 + e^(1/eps)) = {:.6}, bound {:.6}", format!("{}", ep), c, 1.0 / (1.0 + (1.0 / ep).exp()), ep * ent(&a2));
        assert!((c - 1.0 / (1.0 + (1.0 / ep).exp())).abs() < 1e-12 && c <= ep * ent(&a2));
    }
    // 2. the tracker's returns in three bins (down, flat, up), last year a, this year b
    let (a, b) = (vec![0.3, 0.4, 0.3], vec![0.2, 0.3, 0.5]);
    let days = |x: &[f64]| x.iter().map(|y| format!("{:.0}", 250.0 * y)).collect::<Vec<_>>().join(" ");
    println!("returns: last year days {} of 250; this year {}", days(&a), days(&b));
    let c: M = (0..3).map(|i| (0..3).map(|j| (i as f64 - j as f64).abs()).collect()).collect();
    let p0: M = vec![vec![0.2, 0.1, 0.0], vec![0.0, 0.2, 0.2], vec![0.0, 0.0, 0.3]];
    let (phi, psi) = ([0.0, -1.0, -2.0], [0.0, 1.0, 2.0]);
    let ok = (0..3).all(|i| (0..3).all(|j| phi[i] + psi[j] <= c[i][j]));
    let lpdual = dot(&phi, &a) + dot(&psi, &b);
    let runs = psum(&(0..2).map(|k| (psum(&a[..k + 1]) - psum(&b[..k + 1])).abs()).collect::<Vec<_>>());
    println!("3 bins: exact plan {} costs {:.6}; dual prices give {:.6} (fair: {}); running sums {:.6}", f6(&p0), cost(&c, &p0), lpdual, if ok { "yes" } else { "no" }, runs);
    assert!(ok && (cost(&c, &p0) - lpdual).abs() < 1e-12 && (runs - lpdual).abs() < 1e-12);
    assert!(rowerr(&p0, &a) < 1e-12 && rowerr(&tr(&p0), &b) < 1e-12);
    let hmin = ent(&a).min(ent(&b));
    println!("  H(a) = {:.6}, H(b) = {:.6} nats", ent(&a), ent(&b));
    println!("  eps    sweeps  cost      bias bound  |dual gap|");
    for ep in [1.0, 0.5, 0.2, 0.1, 0.05] {
        let k = kernel(&c, ep); let (u, v, e) = sinkhorn(&a, &b, &k, 100000, 1e-12); let p = plan(&u, &k, &v);
        let gap = cost(&c, &p) - ep * hh(&p) - dual(&a, &b, &c, &u, &v, ep);
        println!("  {:<5}  {:>6}  {:.6}  {:.6}    {}", format!("{}", ep), e.len(), cost(&c, &p), ep * hmin, sci(gap.abs()));
        assert!(-1e-9 < cost(&c, &p) - 0.3 && cost(&c, &p) - 0.3 <= ep * hmin && gap.abs() < 1e-8);
    }
    // 3. the linear rate at eps = 1: Hilbert distance of v_k to its limit, against the bound
    let k = kernel(&c, 1.0); let vs = sinkhorn(&a, &b, &k, 200, 0.0).1;
    let dh = |x: &[f64], y: &[f64]| { let r: Vec<f64> = x.iter().zip(y).map(|(p, q)| p / q).collect();
        r.iter().cloned().fold(f64::NEG_INFINITY, f64::max).ln() - r.iter().cloned().fold(f64::INFINITY, f64::min).ln() };
    let mut theta = f64::NEG_INFINITY;
    for i in 0..3 { for j in 0..3 { for kk in 0..3 { for l in 0..3 { theta = theta.max(c[i][l] + c[j][kk] - c[i][kk] - c[j][l]); } } } }
    let kap = (theta / 4.0).tanh(); let kap2 = kap * kap; let (mut v, mut d) = (vec![1.0; 3], vec![]);
    for _ in 0..7 {
        d.push(dh(&v, &vs));
        let u: Vec<f64> = (0..3).map(|i| a[i] / psum(&(0..3).map(|j| k[i][j] * v[j]).collect::<Vec<_>>())).collect();
        v = (0..3).map(|j| b[j] / psum(&(0..3).map(|i| k[i][j] * u[i]).collect::<Vec<_>>())).collect();
    }
    let ratios: Vec<f64> = (0..6).map(|k| d[k + 1] / d[k]).collect();
    println!("rate, eps = 1: swap saving {:.0}, bound tanh(1)^2 = {:.6}; ratios {}", theta, kap2, ratios.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" "));
    assert!(ratios.iter().all(|&x| x <= kap2) && (ratios[5] - ratios[4]).abs() < 0.01);
    for ep in [1.0, 0.5, 0.2] {
        let e = sinkhorn(&a, &b, &kernel(&c, ep), 12, 0.0).2;
        println!("chart, eps = {}: log10 row error after sweeps 1..12: {}", ep, e.iter().map(|x| format!("{:.2}", x.log10())).collect::<Vec<_>>().join(" "));
    }
    // 4. a row scaling is a KL projection: Pythagoras D(R||Q) = D(R||P) + D(P||Q) for R with row sums a
    let dkl = |x: &M, y: &M| psum(&(0..3).flat_map(|i| (0..3).map(move |j| (i, j))).filter(|&(i, j)| x[i][j] > 0.0).map(|(i, j)| x[i][j] * (x[i][j] / y[i][j]).ln()).collect::<Vec<_>>());
    let q: M = kernel(&c, 0.5).iter().map(|r| r.iter().map(|x| x / 3.0).collect()).collect();
    let pr: M = (0..3).map(|i| (0..3).map(|j| q[i][j] * a[i] / psum(&q[i])).collect()).collect();
    let rr: M = vec![vec![0.1, 0.1, 0.1], vec![0.1, 0.2, 0.1], vec![0.0, 0.1, 0.2]];
    println!("KL projection: D(R||Q) = {:.6}, D(R||P) + D(P||Q) = {:.6}", dkl(&rr, &q), dkl(&rr, &pr) + dkl(&pr, &q));
    assert!((dkl(&rr, &q) - dkl(&rr, &pr) - dkl(&pr, &q)).abs() < 1e-12);
    // 5. what breaks
    let e = sinkhorn(&a, &[0.2, 0.3, 0.6], &kernel(&c, 0.5), 1000, 0.0).2;
    println!("unequal totals (b sums to 1.1): row error after 1000 sweeps {:.6}", e[e.len() - 1]);
    let k = kernel(&c, 0.001); let e = sinkhorn(&a, &b, &k, 1000, 0.0).2;
    println!("eps = 0.001, plain kernel: K[0][1] = {:.1}, row error after 1000 sweeps {:.6}", k[0][1], e[e.len() - 1]);
    assert!((e[e.len() - 1] - 0.4).abs() < 1e-12);
    for ep in [0.5, 0.01, 0.001] {
        let (k, p) = logsink(&a, &b, &c, ep, 1e-12);
        println!("log-domain, eps = {}: {} sweeps, cost {:.6}, plan {}", ep, k, cost(&c, &p), f6(&p));
        assert!(rowerr(&tr(&p), &b) < 1e-12 && (ep > 0.01 || (cost(&c, &p) - lpdual).abs() < 1e-8));
    }
    let k = kernel(&c, 0.5); let (u, v, _) = sinkhorn(&a, &b, &k, 100000, 1e-12); let pl = plan(&u, &k, &v);
    let (_, p) = logsink(&a, &b, &c, 0.5, 1e-12);
    assert!((0..3).all(|i| (0..3).all(|j| (p[i][j] - pl[i][j]).abs() < 1e-12)));
    println!("ALL CHECKS PASS");
}
