// SSVI surface -- the check behind the card.  Rust std only.  Power-law SSVI on a stylized at-the-money
// term structure, its arbitrage tests by two roads, SSVI fitted to the Acme quotes, and separate SVI slices.
use std::f64::consts::PI;
const ETA: f64 = 1.0; const GAM: f64 = 0.5; const RHO: f64 = -0.7; // phi = eta theta^-gamma; one skew number
type P = [f64; 5];

fn n_cdf(x: f64) -> f64 { // normal CDF from its own series, as on the SVI card
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let y = x.abs() / 2f64.sqrt(); let (mut term, mut s, mut n) = (y, y, 0.0);
    while term > 1e-17 * s { n += 1.0; term *= 2.0 * y * y / (2.0 * n + 1.0); s += term; }
    let e = 2.0 / PI.sqrt() * (-y * y).exp() * s;
    if x >= 0.0 { 0.5 * (1.0 + e) } else { 0.5 * (1.0 - e) }
}
fn theta(t: f64) -> f64 { 0.04 * t } // stylized at-the-money total variance: 20% vol at the forward at every expiry
fn phi(th: f64, eta: f64, gam: f64) -> f64 { eta * th.powf(-gam) }
fn ssvi(k: f64, th: f64, rho: f64, eta: f64, gam: f64) -> f64 {
    let x = phi(th, eta, gam) * k; th / 2.0 * (1.0 + rho * x + ((x + rho).powi(2) + 1.0 - rho * rho).sqrt())
}
fn w0(k: f64, th: f64) -> f64 { ssvi(k, th, RHO, ETA, GAM) }
fn g_ssvi(k: f64, th: f64, rho: f64, eta: f64, gam: f64) -> f64 { // Gatheral's g from w, w', w'' in closed form
    let f = phi(th, eta, gam); let r = ((f * k + rho).powi(2) + 1.0 - rho * rho).sqrt(); let w = ssvi(k, th, rho, eta, gam);
    let (w1, w2) = (th * f / 2.0 * (rho + (f * k + rho) / r), th * f * f / 2.0 * (1.0 - rho * rho) / r.powi(3)); // w' and w''
    (1.0 - k * w1 / (2.0 * w)).powi(2) - w1 * w1 / 4.0 * (1.0 / w + 0.25) + w2 / 2.0
}
fn dw_dtheta(k: f64, th: f64, gam: f64) -> f64 { // calendar road A: 1/2 [gam (h - x h') + (1 - gam) h]
    let x = phi(th, ETA, gam) * k; let r = ((x + RHO).powi(2) + 1.0 - RHO * RHO).sqrt();
    let (h, h1) = (1.0 + RHO * x + r, RHO + (x + RHO) / r); 0.5 * (gam * (h - x * h1) + (1.0 - gam) * h)
}
fn call(k: f64, w: f64) -> f64 { // call per unit of forward, undiscounted: N(d1) - e^k N(d2)
    let d1 = -k / w.sqrt() + w.sqrt() / 2.0; n_cdf(d1) - k.exp() * n_cdf(d1 - w.sqrt())
}
fn put(k: f64, w: f64) -> f64 { call(k, w) - 1.0 + k.exp() } // put-call parity per unit of forward
fn dens_g(k: f64, w: f64, g: f64) -> f64 { g * (-0.5 * (-k / w.sqrt() - w.sqrt() / 2.0).powi(2)).exp() / (2.0 * PI * w).sqrt() }
fn dens_fd(wf: &dyn Fn(f64) -> f64, k: f64) -> f64 { // butterfly road B: e^-k (c'' - c') from call prices alone
    let h = 1e-3; let c = |x: f64| call(x, wf(x));
    let (c2, c1) = ((c(k + h) - 2.0 * c(k) + c(k - h)) / (h * h), (c(k + h) - c(k - h)) / (2.0 * h)); (-k).exp() * (c2 - c1)
}
fn solve(a: &Vec<Vec<f64>>, y: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = y.len(); let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(y[i]); r }).collect();
    for c in 0..n {
        let piv = (c..n).max_by(|&i, &j| m[i][c].abs().partial_cmp(&m[j][c].abs()).unwrap()).unwrap(); m.swap(c, piv);
        for i in c + 1..n { let f = m[i][c] / m[c][c]; for j in c..=n { m[i][j] -= f * m[c][j]; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - (i + 1..n).map(|j| m[i][j] * x[j]).sum::<f64>()) / m[i][i]; }
    x
}
fn svi(p: &P, k: f64) -> f64 { let [a, b, rho, m, s] = *p; a + b * (rho * (k - m) + ((k - m).powi(2) + s * s).sqrt()) }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }
fn minby<I: Iterator<Item = (f64, f64)>>(it: I) -> (f64, f64) { it.fold((f64::MAX, 0.0), |b, x| if x.0 < b.0 { x } else { b }) }
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:6.2}", x)).collect::<Vec<_>>().join(" ") }
fn bis(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // bisection: f changes sign once on [lo, hi]
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if f(mid) * f(hi) < 0.0 { lo = mid } else { hi = mid } } 0.5 * (lo + hi)
}
fn fit_svi(q: &[f64], t: f64) -> (P, Vec<f64>, f64) { // nine quotes at $80..$120; spot 100, rate 5%, dividend yield 2%
    let ks: Vec<f64> = (0..9).map(|i| ((80.0 + 5.0 * i as f64) / (100.0 * (0.03 * t).exp())).ln()).collect();
    let ws: Vec<f64> = q.iter().map(|v| t * (v / 100.0f64).powi(2)).collect();
    let sse = |p: &P| -> f64 { ks.iter().zip(&ws).map(|(&k, &w)| (svi(p, k) - w).powi(2)).sum() };
    let inner = |m: f64, s: f64| -> P { // SVI card's trick: for fixed (m, s) the fit is linear in (a, b rho, b)
        let cols = vec![vec![1.0; 9], ks.iter().map(|k| k - m).collect::<Vec<f64>>(), ks.iter().map(|k| ((k - m).powi(2) + s * s).sqrt()).collect()];
        let a: Vec<Vec<f64>> = cols.iter().map(|ci| cols.iter().map(|cj| dot(ci, cj)).collect()).collect();
        let x = solve(&a, &cols.iter().map(|ci| dot(ci, &ws)).collect::<Vec<f64>>()); [x[0], x[2], x[1] / x[2], m, s]
    };
    let (mut pp, mut first, mut cm, mut cs, mut hm, mut hs) = ([0.0; 5], true, 0.0, 0.3, 0.5, 0.29);
    for _ in 0..60 {
        for i in -5..=5 { for j in -5..=5 { if cs + hs * j as f64 / 5.0 > 0.0 {
            let p = inner(cm + hm * i as f64 / 5.0, cs + hs * j as f64 / 5.0); if first || sse(&p) < sse(&pp) { pp = p; first = false; } } } }
        cm = pp[3]; cs = pp[4]; hm *= 0.6; hs *= 0.6;
    }
    let miss = ks.iter().zip(q).map(|(&k, &v)| (100.0 * (svi(&pp, k) / t).sqrt() - v).abs()).fold(0.0, f64::max); (pp, ks, miss)
}

fn main() {
    let (t6, t1) = (theta(0.5), theta(1.0));
    println!("theta at 6 months, 1 year     {:.4} {:.4};  SSVI at k = 0 returns {:.4} {:.4}", t6, t1, w0(0.0, t6), w0(0.0, t1));
    println!("phi at 6 months, 1 year       {:.4} {:.4}", phi(t6, ETA, GAM), phi(t1, ETA, GAM));
    let sk = (w0(1e-5, t1) - w0(-1e-5, t1)) / 2e-5; let p1 = phi(t1, ETA, GAM);
    println!("1-year ATM skew dw/dk: rho*theta*phi, finite difference  {:.6} {:.6}", RHO * t1 * p1, sk);
    println!("  as vol skew dsigma/dk = skew / (2 sigma t)  {:.4};  rho read back  {:.4}", sk / (2.0 * t1.sqrt()), sk / (t1 * p1));
    let (lee, c2) = (ETA * (1.0 + RHO.abs()), ETA * ETA * (1.0 + RHO.abs())); let cap = (4.0 / lee).powi(2);
    println!("butterfly: eta(1+|rho|) {:.4} <= 2;  theta phi^2 (1+|rho|) {:.4} <= 4", lee, c2);
    println!("  theta phi (1+|rho|) at 1 year {:.4} < 4, holds while theta < {:.4}, t < {:.1} years", t1 * p1 * (1.0 + RHO.abs()), cap, cap / 0.04);
    let ub = (1.0 + (1.0 - RHO * RHO).sqrt()) / (RHO * RHO);
    println!("calendar: d(theta phi)/dtheta / phi = 1 - gamma = {:.4}, inside [0, {:.4}]", 1.0 - GAM, ub);
    for (lab, th) in [("6 months", t6), ("1 year", t1)] {
        let f = th * phi(th, ETA, GAM); let (sl, sr) = (f * (1.0 - RHO) / 2.0, f * (1.0 + RHO) / 2.0); // road 2: the slice's own slope far out
        assert!((sl - w0(-1e3 - 1.0, th) + w0(-1e3, th)).abs() < 1e-6 && (sr - w0(1e3 + 1.0, th) + w0(1e3, th)).abs() < 1e-6, "wing slopes");
        assert!((lee - 2.0 * sl.max(sr) / th.powf(1.0 - GAM)).abs() < 1e-9 && (c2 - th * phi(th, ETA, GAM).powi(2) * (1.0 + RHO.abs())).abs() < 1e-9, "eta(1+|rho|) from the wing slopes");
        println!("wing slopes {:<8} left theta phi (1-rho)/2, right (1+rho)/2  {:.4} {:.4}", lab, sl, sr);
    }
    let kg: Vec<f64> = (0..301).map(|i| -1.5 + 0.01 * i as f64).collect(); let kw: Vec<f64> = (0..4501).map(|i| -3.0 + 0.001 * i as f64).collect();
    let mut gm = (f64::MAX, 0.0, 0.0);
    for th in [t6, t1, 0.4, 2.0] { for &k in &kg { let g = g_ssvi(k, th, RHO, ETA, GAM); if g < gm.0 { gm = (g, k, th); } } }
    let s2 = 2.0 * phi(2.0, ETA, GAM) * (1.0 - RHO) / 2.0; let lim = 0.25 - s2 * s2 / 16.0;
    println!("min g over k in [-1.5, 1.5], theta in 0.02 0.04 0.4 2:  {:.6} at k {:+.2}, theta {:.2}", gm.0, gm.1, gm.2);
    println!("  far left wing at theta 2: slope {:.4}, g tends to 1/4 - slope^2/16 = {:.4};  g at k -10000 {:.4}", s2, lim, g_ssvi(-1e4, 2.0, RHO, ETA, GAM));
    let wf1 = |x: f64| w0(x, t1);
    for k in [-0.7, 0.0, 0.3] {
        println!("1-year density of k at {:+.1}: from g, from call prices  {:.6} {:.6}", k, dens_g(k, w0(k, t1), g_ssvi(k, t1, RHO, ETA, GAM)), dens_fd(&wf1, k));
    }
    let ths: Vec<f64> = (0..25).map(|j| 0.005 * 1.25f64.powi(j)).collect();
    let dmin = kg.iter().flat_map(|&k| ths.iter().map(move |&th| dw_dtheta(k, th, GAM))).fold(f64::MAX, f64::min);
    let fd = (w0(-0.7, 0.03 + 1e-6) - w0(-0.7, 0.03 - 1e-6)) / 2e-6;
    println!("calendar: min dw/dtheta on the grid {:.6};  at k -0.7, theta 0.03: formula, difference  {:.6} {:.6}", dmin, dw_dtheta(-0.7, 0.03, GAM), fd);
    let fd3 = (ssvi(-0.7, 0.03 + 1e-6, RHO, ETA, 0.3) - ssvi(-0.7, 0.03 - 1e-6, RHO, ETA, 0.3)) / 2e-6;
    println!("  same at gamma 0.3 (u = {:.1}): formula, difference  {:.6} {:.6};  u at gamma 1.2 {:+.1}", 1.0 - 0.3, dw_dtheta(-0.7, 0.03, 0.3), fd3, 1.0 - 1.2);
    let cmin = kg.iter().map(|&k| w0(k, t1) - w0(k, t6)).fold(f64::MAX, f64::min);
    println!("calendar: min over k of w(1 year) - w(6 months)  {:.6}", cmin);
    let q6 = [27.43, 24.38, 21.84, 19.73, 18.00, 16.59, 15.47, 14.60, 13.95]; // the surface card's 6-month row
    let qh = [27.79, 25.33, 23.24, 21.48, 20.00, 18.76, 17.74, 16.90, 16.22]; // the surface card's 1-year row
    let ((p6, ks, miss), (ph, kh, missh), f6, f1) = (fit_svi(&q6, 0.5), fit_svi(&qh, 1.0), 100.0 * (0.03f64 * 0.5).exp(), 100.0 * 0.03f64.exp());
    let q1: P = [0.016719, 0.126769, -0.912282, -0.118207, 0.248954]; // the SVI card's 1-year fit, to its own crash-market quotes
    println!("6-month SVI a b rho m s  {}  max miss {:.4} vol points", p6.iter().map(|x| format!("{:+.5}", x)).collect::<Vec<_>>().join(" "), miss);
    println!("6-month SVI left slope b(1-rho) {:.4};  1-year SVI left slope {:.4}", p6[1] * (1.0 - p6[2]), q1[1] * (1.0 - q1[2]));
    let (kx, kss) = (bis(&|k: f64| svi(&q1, k) - svi(&p6, k), -1.0, -0.3), bis(&|kk: f64| svi(&q1, (kk / f1).ln()) - svi(&p6, (kk / f6).ln()), 40.0, 80.0));
    let (k6s, k1s) = (f6 * kx.exp(), f1 * kx.exp()); // the crossing's strikes at the two expiries' own forwards
    println!("SVI slices cross at k {:.4}: strikes {:.2} (6 months), {:.2} (1 year);  compared at the same strike instead {:.2}", kx, k6s, k1s, kss);
    let nq = ((ks[8] - ks[0]) / 0.001) as usize + 1; let qmin = (0..nq).map(|i| { let k = ks[0] + 0.001 * i as f64; svi(&q1, k) - svi(&p6, k) }).fold(f64::MAX, f64::min);
    println!("inside the quoted range k {:.4} to {:.4}: min w(1y) - w(6m) {:.6}", ks[0], ks[8], qmin);
    let g_svi = |p: &P, k: f64| -> f64 { // Gatheral's g for one raw SVI slice, closed form
        let [_a, b, r, m, s] = *p; let q = ((k - m).powi(2) + s * s).sqrt(); let w = svi(p, k); let (w1, w2) = (b * (r + (k - m) / q), b * s * s / q.powi(3));
        (1.0 - k * w1 / (2.0 * w)).powi(2) - w1 * w1 / 4.0 * (1.0 / w + 0.25) + w2 / 2.0 };
    let g6 = minby(kg.iter().map(|&k| (g_svi(&p6, k), k))); let g1 = kg.iter().map(|&k| g_svi(&q1, k)).fold(f64::MAX, f64::min);
    let kn: Vec<f64> = kw.iter().cloned().filter(|&k| g_svi(&p6, k) < 0.0).collect(); let d6 = dens_fd(&|x: f64| svi(&p6, x), g6.1);
    println!("SVI slices alone: min g 6m {:.4} at k {:+.2} (below 0 for k from {:+.2} to {:+.2}), density from prices {:.4}; min g 1y {:.4}", g6.0, g6.1, kn[0], kn[kn.len() - 1], d6, g1);
    let hg = minby(kw.iter().map(|&k| (svi(&ph, k) - svi(&p6, k), k))); let m1 = kh.iter().zip(&qh).map(|(&k, &v)| (100.0 * svi(&q1, k).sqrt() - v).abs()).fold(0.0, f64::max);
    println!("surface card's 1-year row, same fitter: max miss {:.4}, left slope {:.4};  SVI card's 1-year curve misses it by up to {:.2}", missh, ph[1] * (1.0 - ph[2]), m1);
    println!("  against the 6-month slice on k -3 to 1.5: min w(1y) - w(6m) {:.6} at k {:+.2};  at k -0.7 {:+.6}", hg.0, hg.1, svi(&ph, -0.7) - svi(&p6, -0.7));
    let (th6, th1) = (svi(&p6, 0.0), svi(&ph, 0.0)); // Acme's at-the-money total variances: each SVI fit read at k = 0
    let sets = [(th6, 0.5, &ks, &q6), (th1, 1.0, &kh, &qh)];
    let fq = |r: f64| -> f64 { sets.iter().map(|&(th, t, kq, q)| kq.iter().zip(q).map(|(&k, &v)| (ssvi(k, th, r, ETA, GAM) - t * (v / 100.0f64).powi(2)).powi(2)).sum::<f64>()).sum() };
    let mut ra = -0.5; // one skew number by least squares on the 18 quotes, eta 1, gamma 1/2
    for h in [0.05, 0.005, 5e-4, 5e-5, 5e-6] { let c = ra; for i in -9..=9 { let x = c + h * i as f64; if i == -9 || fq(x) < fq(ra) { ra = x; } } }
    let mq = |r: f64, a: f64, b: f64| -> String { [(a, 0.5, &ks, &q6), (b, 1.0, &kh, &qh)].iter().map(|&(th, t, kq, q)|
        format!("{:.2}", kq.iter().zip(q).map(|(&k, &v)| (100.0 * (ssvi(k, th, r, ETA, GAM) / t).sqrt() - v).abs()).fold(0.0, f64::max))).collect::<Vec<_>>().join(" ") };
    println!("SSVI fitted to Acme: theta 6m, 1y {:.6} {:.6} (vols {:.2}% {:.2}%), rho {:.4}, eta(1+|rho|) {:.4}", th6, th1, 100.0 * (th6 / 0.5).sqrt(), 100.0 * th1.sqrt(), ra, ETA * (1.0 + ra.abs()));
    println!("  max miss in vol points, 6m 1y: fitted SSVI {};  stylized SSVI {}", mq(ra, th6, th1), mq(RHO, t6, t1));
    println!("forwards 6m, 1y {:.2} {:.2};  1-year SVI b {:.6};  eta 1.5: eta(1+|rho|) {:.2}, eta^2(1+|rho|) {:.3}", f6, f1, q1[1], 1.5 * (1.0 + RHO.abs()), 1.5f64.powi(2) * (1.0 + RHO.abs()));
    let k7 = -0.7; let (a6, a1, s6, s1) = (svi(&p6, k7), svi(&q1, k7), w0(k7, t6), w0(k7, t1)); let fv = 100.0 * ((s1 - s6) / 0.5).sqrt();
    println!("at k -0.7: SVI w 6m, 1y, forward variance  {:.6} {:.6} {:+.6}", a6, a1, a1 - a6);
    println!("at k -0.7: SSVI w 6m, 1y, forward variance {:.6} {:.6} {:+.6}, forward vol {:.2}%", s6, s1, s1 - s6, fv);
    println!("at k -0.7: puts per unit forward, SVI 6m, 1y, spread  {:.6} {:.6} {:+.6}", put(k7, a6), put(k7, a1), put(k7, a1) - put(k7, a6));
    println!("at k -0.7: puts per unit forward, SSVI 6m, 1y, spread {:.6} {:.6} {:+.6}", put(k7, s6), put(k7, s1), put(k7, s1) - put(k7, s6));
    let hand = |th: f64| { let x = phi(th, ETA, GAM) * k7; format!("{:.4} {:.4} {:.4}", x, RHO * x, ((x + RHO).powi(2) + 1.0 - RHO * RHO).sqrt()) };
    println!("by hand 6m: x = phi k, rho x, root  {};  1y: {}", hand(t6), hand(t1));
    let gb = minby(kg.iter().map(|&k| (g_ssvi(k, t1, RHO, 3.0, GAM), k))); let db = dens_fd(&|x: f64| ssvi(x, t1, RHO, 3.0, GAM), gb.1);
    let cb = minby(kg.iter().map(|&k| (ssvi(k, t1, RHO, ETA, 1.2) - ssvi(k, t6, RHO, ETA, 1.2), k)));
    println!("wrong: eta 3, theta phi^2 (1+|rho|) {:.2}: min g at 1 year {:.4} at k {:+.2}, density from prices {:.4}", 3.0f64.powi(2) * (1.0 + RHO.abs()), gb.0, gb.1, db);
    println!("wrong: gamma 1.2 (theta phi falls): min w(1y) - w(6m) {:.6} at k {:+.2}", cb.0, cb.1);
    for (lab, rho, eta, gam) in [("rho -0.95", -0.95, ETA, GAM), ("eta 1.5", RHO, 1.5, GAM), ("gamma 0.3", RHO, ETA, 0.3)] {
        let gt = [t6, t1].iter().flat_map(|&th| kg.iter().map(move |&k| g_ssvi(k, th, rho, eta, gam))).fold(f64::MAX, f64::min);
        let ct = kg.iter().map(|&k| ssvi(k, t1, rho, eta, gam) - ssvi(k, t6, rho, eta, gam)).fold(f64::MAX, f64::min);
        println!("try: {:<10} min g {:.4}  min w(1y) - w(6m) {:.6}  vol at k -0.7, 1y {:.2}%", lab, gt, ct, 100.0 * ssvi(k7, t1, rho, eta, gam).sqrt());
    }
    let kc: Vec<f64> = (0..8).map(|i| -1.0 + 0.2 * i as f64).collect();
    println!("chart, k              {}", row(&kc));
    let fns: [(&str, Box<dyn Fn(f64) -> f64>); 5] = [("SVI 6m", Box::new(|k| svi(&p6, k))), ("SVI 1y", Box::new(|k| svi(&q1, k))), ("SVI 1y row", Box::new(|k| svi(&ph, k))),
        ("SSVI 6m", Box::new(move |k| w0(k, t6))), ("SSVI 1y", Box::new(move |k| w0(k, t1)))];
    for (lab, f) in fns.iter() { println!("chart, 100 w {:<10}{}", lab, row(&kc.iter().map(|&k| 100.0 * f(k)).collect::<Vec<_>>())); }
    assert!((sk - RHO * t1 * p1).abs() < 1e-6 && (w0(0.0, t1) - t1).abs() < 1e-12 && miss < 0.05 && missh < 0.05 && fq(ra) < fq(ra - 1e-4).min(fq(ra + 1e-4)), "read-backs; fits tight; SSVI fit at a minimum");
    assert!(sets.iter().all(|&(th, t, kq, q)| (th - t * (q[4] * q[4] + (q[5] * q[5] - q[4] * q[4]) * kq[4] / (kq[4] - kq[5])) / 1e4).abs() < 3e-4), "theta = straight line between the quotes either side of the forward");
    assert!(lee <= 2.0 && c2 <= 4.0 && t1 * p1 * (1.0 + RHO.abs()) < 4.0 && 0.0 <= 1.0 - GAM && 1.0 - GAM <= ub && (ub - 1.0 / (1.0 - (1.0 - RHO * RHO).sqrt())).abs() < 1e-12 && (cap * phi(cap, ETA, GAM) * (1.0 + RHO.abs()) - 4.0).abs() < 1e-9, "Gatheral-Jacquier inequalities");
    assert!(gm.0 > 0.0 && [-0.7, 0.0, 0.3].iter().all(|&k| (dens_g(k, w0(k, t1), g_ssvi(k, t1, RHO, ETA, GAM)) - dens_fd(&wf1, k)).abs() < 1e-4) && 0.0 < lim && lim < gm.0 && (g_ssvi(-1e4, 2.0, RHO, ETA, GAM) - lim).abs() < 1e-3, "g road = price road; far-wing limit");
    assert!(dmin > 0.0 && cmin > 0.0 && (fd - dw_dtheta(-0.7, 0.03, GAM)).abs() < 1e-6 && (fd3 - dw_dtheta(-0.7, 0.03, 0.3)).abs() < 1e-6, "SSVI never crosses: formula and difference agree");
    assert!((svi(&q1, kx) - svi(&p6, kx)).abs() < 1e-9 && a6 > a1 && qmin > 0.0 && g6.0 < 0.0 && (dens_g(g6.1, svi(&p6, g6.1), g6.0) - d6).abs() < 1e-4 && g1 > 0.0 && hg.0 > 0.0, "SVI slices cross; 6m slice has negative density; Acme's own 1-year row does not cross");
    assert!((svi(&p6, (k6s / f6).ln()) - svi(&q1, (k1s / f1).ln())).abs() < 1e-9 && (svi(&q1, (kss / f1).ln()) - svi(&p6, (kss / f6).ln())).abs() < 1e-9 && (s6 + 0.5 * (fv / 100.0).powi(2) - s1).abs() < 1e-12, "crossing strikes; forward vol");
    assert!([a6, a1, s6, s1].iter().all(|&w| (put(k7, w) - k7.exp() * n_cdf(k7 / w.sqrt() + w.sqrt() / 2.0) + n_cdf(k7 / w.sqrt() - w.sqrt() / 2.0)).abs() < 1e-12) && gb.0 < 0.0 && db < 0.0 && cb.0 < 0.0, "puts: parity = direct formula; broken surfaces fail");
    println!("ALL CHECKS PASS");
}
