// Unit roots and differencing -- the check behind the card.  Rust std only, no crates.
// Same SplitMix64 draws as the Python check; least squares solved by hand; nothing knows the answer.
use std::f64::consts::PI;
struct Rng(u64);
impl Rng {
    fn u64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.u64() >> 11) as f64 + 0.5) / 9007199254740992.0 }
    fn normal(&mut self) -> f64 { let (u1, u2) = (self.unif(), self.unif()); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}
// road 1: least squares of v on a constant and x, from sums -> (slope, se, [n, mx, mv, sxx, sxv, svv])
fn reg1(x: &[f64], v: &[f64]) -> (f64, f64, [f64; 6]) {
    let n = x.len() as f64;
    let (mx, mv) = (x.iter().sum::<f64>() / n, v.iter().sum::<f64>() / n);
    let (mut sxx, mut sxv, mut svv) = (0.0, 0.0, 0.0);
    for (a, b) in x.iter().zip(v) { sxx += (a - mx) * (a - mx); sxv += (a - mx) * (b - mv); svv += (b - mv) * (b - mv); }
    let g = sxv / sxx;
    (g, ((svv - g * sxv) / (n - 2.0) / sxx).sqrt(), [n, mx, mv, sxx, sxv, svv])
}
fn diffs(y: &[f64]) -> Vec<f64> { (1..y.len()).map(|t| y[t] - y[t - 1]).collect() }
fn df0(y: &[f64]) -> (f64, f64, [f64; 6]) { reg1(&y[..y.len() - 1], &diffs(y)) }
// road 2: normal equations by Gauss-Jordan, with standard errors from the inverse
fn ols(x: &[Vec<f64>], v: &[f64]) -> (Vec<f64>, Vec<f64>) {
    let k = x[0].len();
    let mut a = vec![vec![0.0; 2 * k + 1]; k];
    for i in 0..k {
        for j in 0..k { a[i][j] = x.iter().map(|r| r[i] * r[j]).sum(); }
        a[i][k] = x.iter().zip(v).map(|(r, b)| r[i] * b).sum();
        a[i][k + 1 + i] = 1.0;
    }
    for c in 0..k {
        let mut p = c;
        for i in c + 1..k { if a[i][c].abs() > a[p][c].abs() { p = i; } }
        a.swap(c, p); let piv = a[c][c];
        for q in 0..2 * k + 1 { a[c][q] /= piv; }
        for i in 0..k {
            if i == c { continue; } let f = a[i][c];
            for q in 0..2 * k + 1 { a[i][q] -= f * a[c][q]; }
        }
    }
    let b: Vec<f64> = (0..k).map(|i| a[i][k]).collect();
    let fit = |r: &Vec<f64>| -> f64 { b.iter().zip(r).map(|(bi, xi)| bi * xi).sum() };
    let s2 = x.iter().zip(v).map(|(r, u)| (u - fit(r)) * (u - fit(r))).sum::<f64>() / (v.len() - k) as f64;
    (b, (0..k).map(|i| (s2 * a[i][k + 1 + i]).sqrt()).collect())
}
fn adf(y: &[f64], p: usize) -> (Vec<f64>, Vec<f64>, f64) {
    let d: Vec<f64> = [vec![0.0], diffs(y)].concat();
    let x: Vec<Vec<f64>> = (p + 1..y.len())
        .map(|t| [vec![1.0, y[t - 1]], (1..=p).map(|j| d[t - j]).collect()].concat()).collect();
    let (b, se) = ols(&x, &d[p + 1..]);
    let tau = b[1] / se[1]; (b, se, tau)
}
// road 3 for p = 1: partial the constant and the lagged change out of both sides
fn adf1_fwl(y: &[f64]) -> (f64, f64) {
    let d: Vec<f64> = [vec![0.0], diffs(y)].concat();
    let z = &d[1..d.len() - 1];
    let resid = |v: &[f64]| -> Vec<f64> {
        let (g, _, s) = reg1(z, v);
        z.iter().zip(v).map(|(a, b)| b - s[2] - g * (a - s[1])).collect()
    };
    let (ex, ed) = (resid(&y[1..y.len() - 1]), resid(&d[2..]));
    let sxx: f64 = ex.iter().map(|a| a * a).sum();
    let g = ex.iter().zip(&ed).map(|(a, b)| a * b).sum::<f64>() / sxx;
    let rss: f64 = ex.iter().zip(&ed).map(|(a, b)| (b - g * a) * (b - g * a)).sum();
    (g, g / (rss / (z.len() as f64 - 3.0) / sxx).sqrt())
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn phi_left(c: f64) -> f64 {
    let (n, mut s, h) = (2000, phi(c) + phi(0.0), -c / 2000.0);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(c + i as f64 * h); }
    0.5 - s * h / 3.0
}
fn cv5(t: f64) -> f64 { -2.86154 - 2.8903 / t - 4.234 / (t * t) - 40.040 / (t * t * t) }
fn pr(label: &str, v: f64, f: usize) { println!("{:<44} {:>12.*}", label, f, v); }
fn line(label: &str, v: &[f64], f: usize) { println!("{}{}", label, v.iter().map(|x| format!("{:.*}", f, x)).collect::<Vec<_>>().join(", ")); }
fn se(p: f64, n: f64) -> f64 { (p * (1.0 - p) / n).sqrt() }
fn main() {
    // ---- the share: $100, 250 trading days, daily log-return shocks of 1% ----
    let (mut g, n) = (Rng(7), 250);
    let e: Vec<f64> = (0..n).map(|_| g.normal()).collect();
    let (mut y, mut u) = (vec![100f64.ln()], vec![0.0]);
    for z in &e { let (a, b) = (y[y.len() - 1], u[u.len() - 1]); y.push(a + 0.01 * z); u.push(0.9 * b + 0.01 * z); }
    let (price, ret): (Vec<f64>, _) = (y.iter().map(|v| v.exp()).collect(), diffs(&y));
    let (gam, se0, st) = df0(&y);
    let (sxx, sxd, sdd) = (st[3], st[4], st[5]);
    let ((_, _, tau0g), (b1, s1, tau1)) = (adf(&y, 0), adf(&y, 1));
    let ((_, tau1f), (_, _, taur)) = (adf1_fwl(&y), adf(&ret, 1));
    let dr = diffs(&ret); let m = dr.iter().sum::<f64>() / dr.len() as f64;
    let num: f64 = (1..dr.len()).map(|t| (dr[t] - m) * (dr[t - 1] - m)).sum();
    let ac1 = num / dr.iter().map(|a| (a - m) * (a - m)).sum::<f64>();
    pr("price on day 0 ($)", price[0], 2); pr("price on day 250 ($)", price[n], 2);
    pr("  lowest ($)", price.iter().cloned().fold(f64::MAX, f64::min), 2);
    pr("  highest ($)", price.iter().cloned().fold(f64::MIN, f64::max), 2);
    pr("DF by hand: n", st[0], 0); pr("  mean level x-bar", st[1], 6); pr("  mean change d-bar", st[2], 8);
    pr("  Sxx", sxx, 6); pr("  Sxd", sxd, 8); pr("  Sdd", sdd, 8);
    pr("  gamma-hat = Sxd/Sxx", gam, 6); pr("  rho-hat = 1 + gamma-hat", 1.0 + gam, 6);
    pr("  RSS = Sdd - gamma-hat Sxd", sdd - gam * sxd, 8); pr("  s^2 = RSS/(n-2)", (sdd - gam * sxd) / (st[0] - 2.0), 8);
    pr("  se(gamma-hat) = sqrt(s^2/Sxx)", se0, 6);
    pr("  tau = gamma-hat / se  (road 1, sums)", gam / se0, 4); pr("  tau  (road 2, Gauss-Jordan)", tau0g, 4);
    pr("ADF p=1 on log price: gamma-hat", b1[1], 6); pr("  lag coefficient delta-hat", b1[2], 4);
    pr("  se(delta-hat)", s1[2], 4); pr("  tau  (road 2, Gauss-Jordan)", tau1, 4); pr("  tau  (road 3, partialling out)", tau1f, 4);
    pr("ADF p=1 on daily returns: tau", taur, 4);
    pr("5% cutoff, MacKinnon, T = 250", cv5(250.0), 4);
    pr("  normal area left of -1.645 (Simpson)", phi_left(-1.645), 6);
    pr("half-life if rho-hat were real (days)", 0.5f64.ln() / (1.0 + gam).ln(), 1);
    pr("over-differenced returns: lag-1 autocorr", ac1, 4); pr("  exact for white-noise returns", -0.5, 4);
    pr("  its standard error sqrt(0.5/n)", (0.5 / dr.len() as f64).sqrt(), 4);
    line("figure, price every 10 days: ", &(0..=n).step_by(10).map(|t| price[t]).collect::<Vec<_>>(), 2);
    // ---- 10,000 simulated random walks of 250 days, and AR(0.95) paths driven by the same shocks ----
    let (r, rho) = (10000usize, 0.95f64);
    let (mut g, cut) = (Rng(2029), cv5(250.0));
    let (mut ssw, mut ssa, mut bins, mut taus) = ([0.0f64; 11], [0.0f64; 11], [0usize; 16], Vec::new());
    let (mut rej, mut naive, mut power, mut sp_lvl, mut sp_ret) = (0, 0, 0, 0, 0);
    let (mut pw, mut pe): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for k in 0..r {
        let (mut w, mut a, mut e) = (vec![0.0], vec![0.0], Vec::with_capacity(n));
        for _ in 0..n {
            let z = g.normal();
            e.push(z); w.push(w[w.len() - 1] + z); a.push(rho * a[a.len() - 1] + z);
        }
        for i in 0..11 { ssw[i] += w[25 * i] * w[25 * i]; ssa[i] += a[25 * i] * a[25 * i]; }
        let (t0, ta) = (df0(&w), df0(&a));
        let tau = t0.0 / t0.1;
        taus.push(tau);
        rej += (tau < cut) as usize; naive += (tau < -1.645) as usize; power += (ta.0 / ta.1 < cut) as usize;
        let j = ((tau + 5.0) / 0.5).floor();
        if j >= 0.0 && j < 16.0 { bins[j as usize] += 1; }
        if k % 2 == 1 {
            let (s, q) = (reg1(&pw, &w), reg1(&pe, &e));
            sp_lvl += ((s.0 / s.1).abs() > 1.96) as usize; sp_ret += ((q.0 / q.1).abs() > 1.96) as usize;
        }
        pw = w; pe = e;
    }
    taus.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let (rf, pf) = (r as f64, (r / 2) as f64);
    pr("sim: walks rejected at MacKinnon cutoff", rej as f64 / rf, 4); pr("  standard error", se(0.05, rf), 4);
    pr("sim: 5% quantile of tau", taus[r / 20 - 1], 4); pr("sim: mean of tau", taus.iter().sum::<f64>() / rf, 4);
    pr("sim: walks rejected at normal cutoff", naive as f64 / rf, 4); pr("  standard error", se(naive as f64 / rf, rf), 4);
    pr("sim: AR(0.95) rejected (power)", power as f64 / rf, 4); pr("  standard error", se(power as f64 / rf, rf), 4);
    pr("sim: walk-on-walk |t| > 1.96 (spurious)", sp_lvl as f64 / pf, 4); pr("  standard error", se(sp_lvl as f64 / pf, pf), 4);
    pr("try: returns-on-returns |t| > 1.96", sp_ret as f64 / pf, 4); pr("  standard error", se(sp_ret as f64 / pf, pf), 4);
    let v250 = ssw[10] / rf;
    pr("sim: variance of walk at day 250", v250, 2); pr("  exact t sigma^2", 250.0, 2); pr("  standard error", 250.0 * (2.0 / rf).sqrt(), 2);
    line("figure, walk sd exact: ", &(0..11).map(|i| (25.0 * i as f64).sqrt()).collect::<Vec<_>>(), 2);
    line("figure, walk sd sim:   ", &(0..11).map(|i| (ssw[i] / rf).sqrt()).collect::<Vec<_>>(), 2);
    line("figure, AR sd exact:   ", &(0..11).map(|i| ((1.0 - rho.powi(50 * i as i32)) / (1.0 - rho * rho)).sqrt()).collect::<Vec<_>>(), 2);
    line("figure, AR sd sim:     ", &(0..11).map(|i| (ssa[i] / rf).sqrt()).collect::<Vec<_>>(), 2);
    line("figure, tau density:    ", &bins.iter().map(|&c| c as f64 / (rf * 0.5)).collect::<Vec<_>>(), 2);
    line("figure, normal density: ", &(0..16).map(|i| phi(-4.75 + 0.5 * i as f64)).collect::<Vec<_>>(), 2);
    let (_, _, tau9) = adf(&u, 1);
    pr("try: rho = 0.9 share, ADF p=1 tau", tau9, 4); pr("try: 5% cutoff, MacKinnon, T = 1000", cv5(1000.0), 4);
    // ---- asserts: each compares two independent computations ----
    assert!((gam / se0 - tau0g).abs() < 1e-8, "sums and Gauss-Jordan disagree");
    assert!((tau1 - tau1f).abs() < 1e-8, "Gauss-Jordan and partialling out disagree");
    assert!((rej as f64 / rf - 0.05).abs() < 4.0 * se(0.05, rf), "simulation does not match MacKinnon's cutoff");
    assert!((v250 - 250.0).abs() < 4.0 * 250.0 * (2.0 / rf).sqrt(), "random-walk variance is not t sigma^2");
    assert!((ac1 + 0.5).abs() < 4.0 * (0.5 / dr.len() as f64).sqrt(), "over-differencing did not give -0.5");
    assert!(naive as f64 / rf > phi_left(-1.645) + 10.0 * se(naive as f64 / rf, rf), "normal cutoff was not too lenient");
    println!("all checks passed");
}
