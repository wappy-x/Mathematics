// CAPM and beta -- the same check as capm_and_beta_check.py, in Rust.  Std only, no crates.
// Same roads: covariance beta and the SML, solved tangency, a grid of mixes, least squares.
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |s, (x, y)| s + x * y) }
fn matvec(a: &[[f64; 3]; 3], v: &[f64]) -> Vec<f64> { a.iter().map(|r| dot(r, v)).collect() }

fn solve(a: &[[f64; 3]; 3], b: &[f64]) -> Vec<f64> {
    // Gaussian elimination with row swaps
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].to_vec(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for r in k..n { if m[r][k].abs() > m[p][k].abs() { p = r; } }
        m.swap(k, p);
        for r in k + 1..n {
            let f = m[r][k] / m[k][k];
            let pivot = m[k].clone();
            for c in 0..=n { m[r][c] -= f * pivot[c]; }
        }
    }
    let mut x = vec![0.0; n];
    for k in (0..n).rev() { x[k] = (m[k][n] - dot(&m[k][k + 1..n], &x[k + 1..])) / m[k][k]; }
    x
}

// intercept, slope, slope standard error, intercept standard error, Sxx, Sxy
fn fit(x: &[f64], y: &[f64]) -> (f64, f64, f64, f64, f64, f64) {
    let n = x.len() as f64;
    let xb = x.iter().fold(0.0, |s, v| s + v) / n;
    let yb = y.iter().fold(0.0, |s, v| s + v) / n;
    let sxx = x.iter().fold(0.0, |s, a| s + (a - xb).powi(2));
    let sxy = x.iter().zip(y).fold(0.0, |s, (a, b)| s + (a - xb) * (b - yb));
    let b = sxy / sxx;
    let a = yb - b * xb;
    let s2 = x.iter().zip(y).fold(0.0, |s, (u, v)| s + (v - a - b * u).powi(2)) / (n - 2.0);
    (a, b, (s2 / sxx).sqrt(), (s2 * (1.0 / n + xb * xb / sxx)).sqrt(), sxx, sxy)
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        // xorshift64*, top 53 bits
        self.0 ^= self.0 >> 12; self.0 ^= self.0 << 25; self.0 ^= self.0 >> 27;
        (self.0.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let vol = [0.30, 0.20, 0.25];
    let rho = [[1.0, 0.5, 0.6], [0.5, 1.0, 0.5], [0.6, 0.5, 1.0]];
    let w_mkt = [0.2, 0.4, 0.4];
    let (rf, prem) = (0.04, 0.04);
    let mut c = [[0.0; 3]; 3];
    for i in 0..3 { for j in 0..3 { c[i][j] = rho[i][j] * vol[i] * vol[j]; } }

    // road 1: covariance beta and the security market line
    let cov_im = matvec(&c, &w_mkt);
    let var_m = dot(&w_mkt, &cov_im);
    let beta: Vec<f64> = cov_im.iter().map(|x| x / var_m).collect();
    let mu: Vec<f64> = beta.iter().map(|b| rf + b * prem).collect();
    let resid: Vec<f64> = (0..3).map(|i| {
        let a: Vec<f64> = (0..3).map(|j| (if j == i { 1.0 } else { 0.0 }) - beta[i] * w_mkt[j]).collect();
        dot(&a, &matvec(&c, &a)).sqrt()
    }).collect();

    // road 2: solved tangency; road 3: grid of mixes in 1% steps
    let tangency = |m: &[f64]| -> Vec<f64> {
        let u = solve(&c, &m.iter().map(|x| x - rf).collect::<Vec<f64>>());
        let s = u.iter().fold(0.0, |s, v| s + v);
        u.iter().map(|x| x / s).collect()
    };
    let sharpe = |w: &[f64], m: &[f64]| (dot(w, m) - rf) / dot(w, &matvec(&c, w)).sqrt();
    let w_tan = tangency(&mu);
    let mut w_grid = [0.0, 0.0, 1.0];
    let mut best = f64::NEG_INFINITY;
    for a in 0..=100 {
        for b in 0..=(100 - a) {
            let w = [a as f64 / 100.0, b as f64 / 100.0, (100 - a - b) as f64 / 100.0];
            let s = sharpe(&w, &mu);
            if s > best { best = s; w_grid = w; }
        }
    }
    let w_bad = tangency(&[0.10, mu[1], mu[2]]);
    let lam: Vec<f64> = (0..3).map(|i| (mu[i] - rf) / cov_im[i]).collect();

    // four quarters: formula, and a direct search on the slope
    let (qx, qy) = ([-2.0, -1.0, 1.0, 2.0], [-0.9, -2.7, 3.7, 1.9]);
    let (qa, qb, _, _, sxx, sxy) = fit(&qx, &qy);
    let sse = |b: f64| {
        let a = qy.iter().fold(0.0, |s, v| s + v) / 4.0 - b * qx.iter().fold(0.0, |s, v| s + v) / 4.0;
        qx.iter().zip(&qy).fold(0.0, |s, (u, v)| s + (v - a - b * u).powi(2))
    };
    let (mut lo, mut hi) = (-5.0, 5.0);
    for _ in 0..200 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if sse(m1) < sse(m2) { hi = m2; } else { lo = m1; }
    }
    let qb_search = (lo + hi) / 2.0;
    let mixed = (sxy / 3.0) / (sxx / 4.0);
    let (ra, rb, _, _, _, _) = fit(&qx.map(|v| v + 1.0), &qy.map(|v| v + 1.0));

    // road 4: 240 simulated months
    let mut rng = Rng(0x9E3779B97F4A7C15);
    let mut l = [[0.0; 3]; 3];
    for i in 0..3 {
        for j in 0..=i {
            let s = c[i][j] / 12.0 - (0..j).fold(0.0, |s, k| s + l[i][k] * l[j][k]);
            l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] };
        }
    }
    let (mut xs, mut ys) = (Vec::new(), Vec::new());
    for _ in 0..240 {
        let z = [rng.normal(), rng.normal(), rng.normal()];
        let r: Vec<f64> = (0..3).map(|i| mu[i] / 12.0 + dot(&l[i], &z)).collect();
        xs.push(dot(&w_mkt, &r) - rf / 12.0);
        ys.push(r[0] - rf / 12.0);
    }
    let (sa, sb, sb_se, sa_se, _, _) = fit(&xs, &ys);
    let windows: Vec<f64> = (0..4).map(|k| fit(&xs[60 * k..60 * k + 60], &ys[60 * k..60 * k + 60]).1).collect();

    let k3 = " (K, O, P)";
    let pc = |v: &[f64], k: f64| -> Vec<f64> { v.iter().map(|x| k * x).collect() };
    let rows: Vec<(String, Vec<f64>)> = vec![
        ("covariances K-K, K-O, K-P, %^2".into(), pc(&c[0], 1e4)),
        ("covariances O-O, O-P, P-P, %^2".into(), vec![1e4 * c[1][1], 1e4 * c[1][2], 1e4 * c[2][2]]),
        (format!("cov with market, %^2{}", k3), pc(&cov_im, 1e4)),
        ("market variance %^2, volatility %".into(), vec![1e4 * var_m, 100.0 * var_m.sqrt()]),
        (format!("beta{}", k3), beta.clone()), (format!("SML expected return, %{}", k3), pc(&mu, 100.0)),
        ("Kestrel premium, market return, %".into(), vec![100.0 * beta[0] * prem, 100.0 * dot(&w_mkt, &mu)]),
        ("Kestrel var split: market, private".into(), vec![1e4 * beta[0].powi(2) * var_m, 1e4 * resid[0].powi(2)]),
        ("Kestrel market-part vol, corr".into(), vec![100.0 * beta[0] * var_m.sqrt(), cov_im[0] / (vol[0] * var_m.sqrt())]),
        (format!("private volatility, %{}", k3), pc(&resid, 100.0)),
        (format!("excess per unit vol{}", k3), (0..3).map(|i| (mu[i] - rf) / vol[i]).collect()),
        (format!("excess / cov with market{}", k3), lam.clone()),
        (format!("tangency by solve, %{}", k3), pc(&w_tan, 100.0)),
        (format!("tangency by grid, %{}", k3), pc(&w_grid, 100.0)),
        ("market Sharpe ratio".into(), vec![sharpe(&w_mkt, &mu)]),
        (format!("if Kestrel paid 10%, %{}", k3), pc(&w_bad, 100.0)),
        ("quarters: mean x, mean y".into(), vec![qx.iter().fold(0.0, |s, v| s + v) / 4.0, qy.iter().fold(0.0, |s, v| s + v) / 4.0]),
        ("quarters: Sxx, Sxy".into(), vec![sxx, sxy]),
        ("quarters: beta, formula and search".into(), vec![qb, qb_search]),
        ("quarters: alpha per quarter, %".into(), vec![qa]),
        ("wrong: CML, total vol for Kestrel, %".into(), vec![100.0 * (rf + vol[0] / var_m.sqrt() * prem)]),
        ("wrong: correlation for beta, %".into(), vec![100.0 * (rf + cov_im[0] / (vol[0] * var_m.sqrt()) * prem)]),
        ("wrong: beta x market return, %".into(), vec![100.0 * beta[0] * (rf + prem)]),
        ("wrong: cov over n-1, var over n".into(), vec![mixed]),
        ("wrong: raw returns, alpha % and beta".into(), vec![ra, rb]),
        ("sim 240 months: beta, std error".into(), vec![sb, sb_se]),
        ("sim: alpha per year %, std error".into(), vec![1200.0 * sa, 1200.0 * sa_se]),
        ("sim: beta by 5-year window".into(), windows),
        ("try: premium 6%, Kestrel %".into(), vec![100.0 * (rf + beta[0] * 0.06)]),
        ("try: rf 2%, market 8%, Kestrel %".into(), vec![100.0 * (0.02 + beta[0] * 0.06)]),
        ("try: beta -0.5, %".into(), vec![100.0 * (rf - 0.5 * prem)])];
    for (n, v) in &rows { println!("{:<40}{}", n, v.iter().map(|x| format!("{:10.4}", x)).collect::<String>()); }
    let chart: String = (0..9).map(|b| format!("{:6.2}", 100.0 * (rf + b as f64 / 5.0 * prem))).collect();
    println!("chart, SML at beta 0.0 to 1.6:{}", chart);

    assert!((mu[0] - 0.088).abs() < 1e-12, "Kestrel on the SML: 8.8%");
    assert!((0..3).all(|i| (w_tan[i] - w_mkt[i]).abs() < 1e-12), "solved tangency = market");
    assert!((0..3).all(|i| (w_grid[i] - w_mkt[i]).abs() < 1e-9), "grid search finds the market");
    assert!((qb - qb_search).abs() < 1e-6, "two roads to the fitted slope");
    assert!(lam.iter().fold(f64::MIN, |m, &v| m.max(v)) - lam.iter().fold(f64::MAX, |m, &v| m.min(v)) < 1e-12, "same reward per unit covariance for every share");
    assert!((ra - (qa + 1.0 * (1.0 - rb))).abs() < 1e-12, "raw returns: intercept absorbs rf x (1 - beta)");
    assert!((sb - beta[0]).abs() < 2.0 * sb_se, "simulated regression within 2 standard errors");
    assert!((c[0][0] - (beta[0].powi(2) * var_m + resid[0].powi(2))).abs() < 1e-12, "variance split 900 = 576 + 324");
    println!("ALL CHECKS PASS");
}
