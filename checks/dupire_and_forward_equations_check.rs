// Dupire's equation -- the check behind the card.  std only, no crates.
// An index at 100, rates and dividends zero (illustrative).  60 call quotes:
// strikes 70..125 step 5, expiries 0.2..1.0 step 0.2 years.  The forward
// equation C_T = 1/2 sig(K)^2 K^2 C_KK is marched in strike and expiry
// (Crank-Nicolson, four implicit half-steps first, Thomas solve written out).
// Roads: the Black formula (normal CDF by series); one backward solve per
// strike; Dupire's inversion against the known volatility; a two-number fit.
const S0: f64 = 100.0;
const TS: [f64; 5] = [0.2, 0.4, 0.6, 0.8, 1.0];

fn ks() -> Vec<f64> { (0..12).map(|i| 70.0 + 5.0 * i as f64).collect() }

fn ncdf(x: f64) -> f64 { // Marsaglia's series for the normal CDF
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 { t *= x * x / (2.0 * k + 1.0); s += t; k += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt()
}

fn black(k: f64, t: f64, sg: f64) -> f64 {
    let d1 = ((S0 / k).ln() + 0.5 * sg * sg * t) / (sg * t.sqrt());
    S0 * ncdf(d1) - k * ncdf(d1 - sg * t.sqrt())
}

fn skew(a: f64, b: f64, x: f64) -> f64 {
    if x > 0.0 { (a + b * (x / 100.0).ln()).min(1.0).max(0.05) } else { 0.0 }
}

// u_t = 1/2 sig(x)^2 x^2 u_xx on [0, 300]
fn march(sig: &dyn Fn(f64) -> f64, init: &dyn Fn(f64) -> f64, dx: f64, n: usize) -> Vec<Vec<f64>> {
    let (m, dt) = ((300.0 / dx).round() as usize, 0.2 / n as f64);
    let a: Vec<f64> = (0..=m).map(|i| { let x = i as f64 * dx; 0.5 * (sig(x) * x).powi(2) / (dx * dx) }).collect();
    let mut u: Vec<f64> = (0..=m).map(|i| init(i as f64 * dx)).collect();
    let (mut out, mut steps) = (Vec::new(), vec![(dt / 2.0, 1.0); 4]);
    steps.extend(vec![(dt, 0.5); 5 * n - 2]);
    for (s, &(h, th)) in steps.iter().enumerate() {
        let (mut l, mut d, mut r) = (vec![0.0; m + 1], vec![1.0; m + 1], u.clone());
        for i in 1..m {
            let lam = a[i] * h;
            r[i] = u[i] + (1.0 - th) * lam * (u[i - 1] - 2.0 * u[i] + u[i + 1]);
            (l[i], d[i]) = (-th * lam, 1.0 + 2.0 * th * lam);
        }
        r[1] -= l[1] * u[0]; r[m - 1] -= l[m - 1] * u[m];
        let (mut c, mut y) = (vec![0.0; m], vec![0.0; m]); // Thomas: sweep down, then back up
        for i in 1..m {
            let mm = d[i] - l[i] * c[i - 1];
            (c[i], y[i]) = (l[i] / mm, (r[i] - l[i] * y[i - 1]) / mm);
        }
        u[m - 1] = y[m - 1];
        for i in (1..m - 1).rev() { u[i] = y[i] - c[i] * u[i + 1]; }
        if s >= 4 && (s - 1) % n == 0 { out.push(u.clone()); }
    }
    out
}

fn at(g: &[f64], dx: f64, k: f64) -> f64 { g[(k / dx).round() as usize] }
fn fwd(sig: &dyn Fn(f64) -> f64, dx: f64, n: usize) -> Vec<Vec<f64>> { march(sig, &|x| (S0 - x).max(0.0), dx, n) }
fn table(g: &[Vec<f64>], dx: f64) -> Vec<Vec<f64>> {
    (0..5).map(|j| ks().iter().map(|&k| at(&g[j], dx, k)).collect()).collect()
}

// a quote: true price, uniform noise +-2 cents, to the cent; SplitMix64, seed 2026
fn noisy(st: &mut u64, c: f64) -> f64 {
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *st;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    let un = ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0;
    (100.0 * (c + 0.04 * un - 0.02) + 0.5).floor() / 100.0
}

fn lv(c: &[f64], dt: f64, h: f64, k: f64) -> f64 { // Dupire's inversion, centred differences
    2.0 * (c[2] - c[0]) / (2.0 * dt) / (k * k * ((c[3] - 2.0 * c[1] + c[4]) / (h * h)))
}
fn vol(v: f64) -> f64 { if v > 0.0 { v.sqrt() } else { f64::NAN } }
fn pct(v: f64) -> String { if v > 0.0 { format!("{:6.2}", 100.0 * v.sqrt()) } else { "  none".to_string() } }
fn sci(x: f64) -> String { // Python's .2e
    let e = x.abs().log10().floor() as i32;
    let (mut mt, mut e2) = (x / 10f64.powi(e), e);
    if format!("{:.2}", mt.abs()) == "10.00" { mt /= 10.0; e2 += 1; }
    format!("{:.2}e{}{:02}", mt, if e2 < 0 { "-" } else { "+" }, e2.abs())
}
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let kv = ks();
    let flat = |_x: f64| 0.2;
    let (mut err, mut q) = (Vec::new(), Vec::new());
    for &(dx, n) in &[(0.5, 20usize), (0.25, 40usize)] {
        q = table(&fwd(&flat, dx, n), dx);
        let mut e: f64 = 0.0;
        for j in 0..5 { for i in 0..12 { e = e.max((q[j][i] - black(kv[i], TS[j], 0.2)).abs()); } }
        err.push(e);
        println!("flat 20%: dK = {} $, dT = {:.3} y, max |forward - Black| = {} $", dx, 0.2 / n as f64, sci(e));
    }
    let order = (err[0] / err[1]).log2();
    println!("observed order {:.2}; K = 100, T = 1: forward {:.4} $, Black {:.4} $", order, q[4][6], black(100.0, 1.0, 0.2));
    assert!(err[1] < 1e-3 && 1.5 < order && order < 2.5);

    let truth = |x: f64| skew(0.20, -0.15, x);
    let (gdx, gn) = (0.25, 40usize);
    let g = fwd(&truth, gdx, gn);
    let q = table(&g, gdx);
    for &k in &[80.0, 100.0, 120.0] { // one backward solve per strike
        let b = march(&truth, &|x| (x - k).max(0.0), gdx, gn);
        let (b6, b10) = (at(&b[2], gdx, S0), at(&b[4], gdx, S0));
        let (f6, f10) = (q[2][((k - 70.0) / 5.0) as usize], q[4][((k - 70.0) / 5.0) as usize]);
        println!("backward K={}: T=0.6 {:.4} vs forward {:.4}; T=1.0 {:.4} vs {:.4}", k, b6, f6, b10, f10);
        assert!((b6 - f6).abs() < 2e-3 && (b10 - f10).abs() < 2e-3);
    }

    let mut st: u64 = 2026;
    let r: Vec<Vec<f64>> = q.iter().map(|rw| rw.iter().map(|&c| noisy(&mut st, c)).collect()).collect();
    println!("the 60 quotes ($), strikes 70..125 across, expiries 0.2..1.0 down:");
    for j in 0..5 { println!("  T={:.1} {}", TS[j], row(&r[j])); }
    let surface = |c: &Vec<Vec<f64>>| -> Vec<Vec<f64>> {
        (1..4).map(|j| (1..11).map(|i| lv(&[c[j - 1][i], c[j][i], c[j + 1][i], c[j][i - 1], c[j][i + 1]], 0.2, 5.0, kv[i])).collect()).collect()
    };
    let (le, lr) = (surface(&q), surface(&r));
    println!("local vol at T = 0.6 (%), strikes 75..120:");
    println!("  truth {}", row(&kv[1..11].iter().map(|&k| 100.0 * truth(k)).collect::<Vec<_>>()));
    println!("  exact {}", row(&le[1].iter().map(|&v| 100.0 * vol(v)).collect::<Vec<_>>()));
    println!("  noisy {}", row(&lr[1].iter().map(|&v| 100.0 * vol(v)).collect::<Vec<_>>()));
    let worst = |s: &Vec<Vec<f64>>| s.iter().flat_map(|rw| rw.iter().enumerate().map(|(i, &v)| (vol(v) - truth(kv[i + 1])).abs())).fold(0.0, f64::max);
    let (we, wn) = (worst(&le), worst(&lr));
    println!("30 readings, worst error: exact quotes {:.2} points, noisy quotes {:.2}", 100.0 * we, 100.0 * wn);
    assert!(we < 0.012 && wn < 0.03);

    let c = [q[1][6], q[2][6], q[3][6], q[2][5], q[2][7]];
    let cq = [r[1][6], r[2][6], r[3][6], r[2][5], r[2][7]];
    for (name, cc) in [("exact", c), ("quoted", cq)] {
        let (ct, ckk) = ((cc[2] - cc[0]) / 0.4, (cc[3] - 2.0 * cc[1] + cc[4]) / 25.0);
        let s: Vec<String> = cc.iter().map(|x| format!("{:.4}", x)).collect();
        println!("by hand {}: {}; C_T {:.4} C_KK {:.6} var {:.6}", name, s.join(" "), ct, ckk, 2.0 * ct / (1e4 * ckk));
    }
    let (ct, ckk) = ((c[2] - c[0]) / 0.4, (c[3] - 2.0 * c[1] + c[4]) / 25.0);
    println!("mistakes, exact quotes: no 1/2 {:.4}; one-sided C_T {:.4}", (ct / (1e4 * ckk)).sqrt(), (2.0 * (c[1] - c[0]) / 0.2 / (1e4 * ckk)).sqrt());
    println!("strike spacing h at K=100, T=0.6 (dT = 0.2): local vol (%) from exact and noisy quotes");
    let (mut e, mut t) = (0.0, 0.0);
    for &h in &[10.0, 5.0, 2.5, 1.0, 0.5] {
        let cc = [at(&g[1], gdx, 100.0), at(&g[2], gdx, 100.0), at(&g[3], gdx, 100.0), at(&g[2], gdx, 100.0 - h), at(&g[2], gdx, 100.0 + h)];
        let cn: Vec<f64> = cc.iter().map(|&x| noisy(&mut st, x)).collect();
        (e, t) = (lv(&cc, 0.2, h, 100.0), lv(&cn, 0.2, h, 100.0));
        println!("  h={:<4} exact {:.2} bend {:.4} noisy {} variance {:7.4} bend noise up to {:.4}", h, 100.0 * vol(e), (cc[3] - 2.0 * cc[1] + cc[4]) / (h * h), pct(t), t, 0.1 / (h * h));
    }
    assert!((vol(e) - 0.2).abs() < 0.003 && t < 0.0);

    let resid = |p: &[f64; 2]| -> Vec<f64> { // the fit: Gauss-Newton on (a, b)
        let (a, b) = (p[0], p[1]);
        let mm = table(&fwd(&|x| skew(a, b, x), 0.5, 20), 0.5);
        (0..60).map(|k| mm[k / 12][k % 12] - r[k / 12][k % 12]).collect()
    };
    let (mut p, mut rms) = ([0.25, 0.0], 0.0);
    for it in 0..4 {
        let r0 = resid(&p);
        let jac: Vec<Vec<f64>> = (0..2).map(|k| {
            let pp = [p[0] + if k == 0 { 1e-4 } else { 0.0 }, p[1] + if k == 1 { 1e-4 } else { 0.0 }];
            resid(&pp).iter().zip(&r0).map(|(x, y)| (x - y) / 1e-4).collect()
        }).collect();
        let dot = |u: &[f64], v: &[f64]| u.iter().zip(v).map(|(x, y)| x * y).sum::<f64>();
        let (a00, a01, a11) = (dot(&jac[0], &jac[0]), dot(&jac[0], &jac[1]), dot(&jac[1], &jac[1]));
        let (g0, g1) = (dot(&jac[0], &r0), dot(&jac[1], &r0));
        let det = a00 * a11 - a01 * a01;
        p = [p[0] - (a11 * g0 - a01 * g1) / det, p[1] - (a00 * g1 - a01 * g0) / det];
        rms = (resid(&p).iter().map(|x| x * x).sum::<f64>() / 60.0).sqrt();
        println!("fit step {}: a = {:.4}, b = {:.4}, rms price error {:.4} $", it + 1, p[0], p[1], rms);
    }
    println!("fitted local vol (%), strikes 75..120: {}", row(&kv[1..11].iter().map(|&k| 100.0 * skew(p[0], p[1], k)).collect::<Vec<_>>()));
    assert!((p[0] - 0.20).abs() < 0.003 && (p[1] + 0.15).abs() < 0.01 && rms < 0.03);
    println!("ALL CHECKS PASS");
}
