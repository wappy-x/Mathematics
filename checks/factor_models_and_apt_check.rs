// Factor models and APT -- the check behind the card.  Rust std only.
// An invented eight-month record: each factor is up or down by a fixed step and
// every up/down combination appears once.  Returns: percent per month, over the bank.
const LAM: [f64; 3] = [0.5, 0.2, 0.3]; // average market, size, value returns in the record
const STEP: [f64; 3] = [4.0, 2.0, 2.0]; // each factor sits this far above or below its average
const TA: [f64; 4] = [0.2, 1.2, 0.4, -0.3]; // fund A: alpha, bM, bS, bH
const TB: [f64; 4] = [-0.1, 0.8, -0.2, 0.5]; // fund B

fn solve(a: &Vec<Vec<f64>>, b: &Vec<f64>) -> Vec<f64> {
    // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let p = (c..n).max_by(|&x, &y| m[x][c].abs().partial_cmp(&m[y][c].abs()).unwrap()).unwrap();
        assert!(m[p][c].abs() > 1e-12, "factor columns not independent");
        m.swap(c, p);
        for r in 0..n {
            if r != c {
                let k = m[r][c] / m[c][c];
                let pivot = m[c].clone();
                for (x, z) in m[r].iter_mut().zip(pivot.iter()) { *x -= k * z; }
            }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}
fn ols(x: &Vec<Vec<f64>>, y: &[f64]) -> Vec<f64> {
    // road 1: normal equations  X'X theta = X'y
    let k = x[0].len();
    let xtx = (0..k).map(|i| (0..k).map(|j| x.iter().map(|r| r[i] * r[j]).sum()).collect()).collect();
    let xty = (0..k).map(|i| x.iter().zip(y).map(|(r, v)| r[i] * v).sum()).collect();
    solve(&xtx, &xty)
}
fn mean(u: &[f64]) -> f64 { u.iter().sum::<f64>() / u.len() as f64 }
fn z(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }
fn cov(u: &[f64], v: &[f64]) -> f64 {
    let (mu, mv) = (mean(u), mean(v));
    u.iter().zip(v).map(|(a, b)| (a - mu) * (b - mv)).sum::<f64>() / u.len() as f64
}
fn quad(u: &[f64], m: &Vec<Vec<f64>>, v: &[f64]) -> f64 {
    let mut s = 0.0;
    for i in 0..u.len() { for j in 0..v.len() { s += u[i] * m[i][j] * v[j]; } }
    s
}
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // xorshift64: same bits in Python and Rust
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn main() {
    let mut signs = vec![];
    for m in [1.0, -1.0] { for s in [1.0, -1.0] { for h in [1.0, -1.0] { signs.push([m, s, h]); } } }
    let f: Vec<[f64; 3]> = signs.iter().map(|sg| [0, 1, 2].map(|j| LAM[j] + STEP[j] * sg[j])).collect();
    let fund = |t: &[f64; 4], i: usize, own: f64| t[0] + t[1] * f[i][0] + t[2] * f[i][1] + t[3] * f[i][2] + own;
    let ya: Vec<f64> = (0..8).map(|i| fund(&TA, i, 1.0 * signs[i][0] * signs[i][1])).collect();
    let yb: Vec<f64> = (0..8).map(|i| fund(&TB, i, 0.5 * signs[i][0] * signs[i][2])).collect();
    let x: Vec<Vec<f64>> = (0..8).map(|t| vec![1.0, f[t][0], f[t][1], f[t][2]]).collect();
    println!("month   MKT    SMB    HML   fund A  fund B");
    for t in 0..8 {
        println!("{:>5} {:6.1} {:6.1} {:6.1} {:8.2} {:7.2}", t + 1, f[t][0], f[t][1], f[t][2], ya[t], yb[t]);
    }
    let cols: Vec<Vec<f64>> = (0..3).map(|j| (0..8).map(|t| f[t][j]).collect()).collect();
    let fbar: Vec<f64> = cols.iter().map(|c| mean(c)).collect();
    println!("average   {:.2}   {:.2}   {:.2} {:8.2} {:7.2}", fbar[0], fbar[1], fbar[2], mean(&ya), mean(&yb));
    let mut fit = vec![]; let mut res = vec![];
    for (key, y, tr) in [("A", &ya, TA), ("B", &yb, TB)] {
        let r1 = ols(&x, y);
        // road 2: up-month average minus down-month average, over the gap in the factor
        let mut r2 = vec![0.0; 4];
        for j in 0..3 {
            let (up, dn): (Vec<usize>, Vec<usize>) = (0..8).partition(|&t| signs[t][j] > 0.0);
            let avg = |ix: &Vec<usize>, v: &dyn Fn(usize) -> f64| ix.iter().map(|&t| v(t)).sum::<f64>() / ix.len() as f64;
            let gap = avg(&up, &|t| f[t][j]) - avg(&dn, &|t| f[t][j]);
            r2[j + 1] = (avg(&up, &|t| y[t]) - avg(&dn, &|t| y[t])) / gap;
        }
        r2[0] = mean(y) - (0..3).map(|j| r2[j + 1] * mean(&cols[j])).sum::<f64>();
        println!("fund {} road 1 normal equations  alpha {:6.3}  bM {:6.3}  bS {:6.3}  bH {:6.3}", key, r1[0], r1[1], r1[2], r1[3]);
        println!("fund {} road 2 up minus down     alpha {:6.3}  bM {:6.3}  bS {:6.3}  bH {:6.3}", key, r2[0], r2[1], r2[2], r2[3]);
        assert!((0..4).all(|i| (r1[i] - r2[i]).abs() < 1e-9), "two fitting roads disagree");
        assert!((0..4).all(|i| (r1[i] - tr[i]).abs() < 1e-9), "fit misses the loadings that built the record");
        let e: Vec<f64> = (0..8).map(|t| y[t] - (0..4).map(|i| r1[i] * x[t][i]).sum::<f64>()).collect();
        let worst = (0..3).map(|j| (0..8).map(|t| e[t] * f[t][j]).sum::<f64>().abs()).fold(0.0, f64::max);
        println!("fund {} month-1 residual {:6.3}; each month's residual times each factor sums to {:.3}", key, e[0], worst);
        fit.push(r1); res.push(e);
    }
    let ud: Vec<f64> = (0..6).map(|k| { let g = if k % 2 == 0 { 1.0 } else { -1.0 };
        let v: Vec<f64> = (0..8).filter(|&t| signs[t][k / 2] * g > 0.0).map(|t| ya[t]).collect(); mean(&v) }).collect();
    println!("fund A up / down month averages: market {:.2} / {:.2}  size {:.2} / {:.2}  value {:.2} / {:.2}", ud[0], ud[1], ud[2], ud[3], ud[4], ud[5]);
    let fitted: Vec<String> = (0..8).map(|t| format!("{:.2}", ya[t] - res[0][t])).collect();
    println!("chart, fund A factor fit {}", fitted.join(" "));
    let om: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|j| cov(&cols[i], &cols[j])).collect()).collect();
    let bm: Vec<Vec<f64>> = vec![fit[0][1..].to_vec(), fit[1][1..].to_vec()];
    let fac: Vec<Vec<f64>> = (0..2).map(|a| (0..2).map(|b| quad(&bm[a], &om, &bm[b])).collect()).collect();
    let d: Vec<Vec<f64>> = (0..2).map(|p| (0..2).map(|q| cov(&res[p], &res[q])).collect()).collect();
    let ys = [&ya, &yb];
    let direct: Vec<Vec<f64>> = (0..2).map(|p| (0..2).map(|q| cov(ys[p], ys[q])).collect()).collect();
    let sum: Vec<Vec<f64>> = (0..2).map(|i| (0..2).map(|j| fac[i][j] + d[i][j]).collect()).collect();
    println!("factor covariance Omega diagonal {:.2} {:.2} {:.2}; off-diagonal {:.2}", om[0][0], om[1][1], om[2][2], z(om[0][1]));
    for (lab, m) in [("factor part B Omega B'", &fac), ("specific part D", &d), ("sum", &sum), ("direct from the months", &direct)] {
        println!("{:<24} {:7.2} {:7.2} {:7.2}", lab, m[0][0], z(m[0][1]), m[1][1]);
    }
    assert!((0..4).all(|k| (sum[k / 2][k % 2] - direct[k / 2][k % 2]).abs() < 1e-9), "decomposition fails");
    assert!((direct[0][0] - (0..3).map(|j| TA[1 + j] * TA[1 + j] * STEP[j] * STEP[j]).sum::<f64>() - 1.0).abs() < 1e-9, "A variance: loading^2 x step^2 + 1");
    let ba = bm[0].clone();
    println!("fund A variance by source: market {:.2}  size {:.2}  value {:.2}  specific {:.2}",
        ba[0] * ba[0] * om[0][0], ba[1] * ba[1] * om[1][1], ba[2] * ba[2] * om[2][2], d[0][0]);
    println!("fund A R-squared {:.4}; fund B {:.4}; correlation {:.4}", fac[0][0] / direct[0][0], fac[1][1] / direct[1][1],
        direct[0][1] / (direct[0][0] * direct[1][1]).sqrt());
    println!("numbers to estimate for 500 funds: every covariance {}; three-factor model {}", 500 * 501 / 2, 500 * 3 + 6 + 500);
    let w = [0.5, 0.5];
    let bp: Vec<f64> = (0..3).map(|j| w[0] * bm[0][j] + w[1] * bm[1][j]).collect();
    let pv_fac = quad(&bp, &om, &bp) + quad(&w, &d, &w);
    let port: Vec<f64> = (0..8).map(|t| w[0] * ya[t] + w[1] * yb[t]).collect();
    let pv_dir = cov(&port, &port);
    println!("half-and-half portfolio loadings {:.2} {:.2} {:.2}; variance from 3 exposures {:.4}; from its own months {:.4}", bp[0], bp[1], bp[2], pv_fac, pv_dir);
    assert!((pv_fac - pv_dir).abs() < 1e-9, "portfolio variance by exposures disagrees with the direct series");

    let xm: Vec<Vec<f64>> = (0..8).map(|t| vec![1.0, f[t][0]]).collect();
    let capm = ols(&xm, &ya);
    let cr: Vec<f64> = (0..8).map(|t| ya[t] - capm[0] - capm[1] * f[t][0]).collect();
    println!("wrong: market only  beta {:.3}  alpha {:.3}  'specific' variance {:.2}  A-B covariance {:.2}",
        capm[1], capm[0], cov(&cr, &cr), capm[1] * ols(&xm, &yb)[1] * om[0][0]);
    let yb2: Vec<f64> = (0..8).map(|i| fund(&TB, i, 0.5 * signs[i][0] * signs[i][2] + 0.5 * signs[i][0] * signs[i][1])).collect();
    let fb2 = ols(&x, &yb2);
    println!("wrong: residuals assumed unrelated  model covariance {:.2}  true {:.2}", quad(&ba, &om, &fb2[1..]), cov(&ya, &yb2));
    println!("wrong: alpha read as average excess return  {:.2} instead of {:.2}", mean(&ya), fit[0][0]);

    let imp: Vec<f64> = (0..2).map(|k| (0..3).map(|j| fit[k][1 + j] * fbar[j]).sum()).collect();
    for (k, key, tr) in [(0, "A", TA), (1, "B", TB)] {
        let avg = mean(ys[k]);
        println!("APT fund {}: premia-implied excess {:.2}; average excess {:.2}; gap {:.2}", key, imp[k], avg, avg - imp[k]);
        assert!(((avg - imp[k]) - tr[0]).abs() < 1e-9, "gap to APT line should equal the alpha that built the record");
    }
    let q = 0.80;
    let pay: Vec<f64> = (0..8).map(|t| (q + (0..3).map(|j| ba[j] * (f[t][j] - fbar[j])).sum::<f64>())
        - (0..3).map(|j| ba[j] * f[t][j]).sum::<f64>()).collect();
    let (lo, hi) = (pay.iter().cloned().fold(f64::MAX, f64::min), pay.iter().cloned().fold(f64::MIN, f64::max));
    println!("arbitrage: portfolio Q at {:.2} long, factor copy short; monthly payoff min {:.4} max {:.4}; price gap {:.4}", q, lo, hi, q - imp[0]);
    assert!(hi - lo < 1e-9, "a factor-neutral payoff must not move with the months");
    assert!((mean(&pay) - (q - (0..3).map(|j| TA[1 + j] * LAM[j]).sum::<f64>())).abs() < 1e-9, "payoff must be the price gap");

    let mut rng = Rng(0x9E3779B97F4A7C15);
    println!("specific volatility of an equal-weight basket of N funds, each 1.00 on its own");
    for n in [1usize, 4, 16, 64, 400] {
        let draws: Vec<f64> = (0..2000).map(|_| { let v: Vec<f64> = (0..n).map(|_| rng.normal()).collect(); mean(&v) }).collect();
        let sim = (draws.iter().map(|x| x * x).sum::<f64>() / draws.len() as f64).sqrt();
        println!("  N = {:>3}   formula 1/sqrt(N) {:.3}   simulated {:.3}", n, 1.0 / (n as f64).sqrt(), sim);
        assert!((sim * (n as f64).sqrt() - 1.0).abs() < 0.06, "diversification simulation off the 1/sqrt(N) law");
    }
    let fl: Vec<Vec<f64>> = (0..600).map(|_| (0..3).map(|j| LAM[j] + STEP[j] * rng.normal()).collect()).collect();
    let yl: Vec<f64> = fl.iter().map(|g| 0.2 + 1.2 * g[0] + 0.4 * g[1] - 0.3 * g[2] + rng.normal()).collect();
    let xl: Vec<Vec<f64>> = fl.iter().map(|g| vec![1.0, g[0], g[1], g[2]]).collect();
    let el = ols(&xl, &yl);
    println!("second case, 600 random months: alpha {:.3}  bM {:.3}  bS {:.3}  bH {:.3}", el[0], el[1], el[2], el[3]);
    assert!((0..4).all(|i| (el[i] - TA[i]).abs() < 0.15), "long random record should land near the true loadings");
    println!("try: fund A specific 2.00, R-squared {:.4}", fac[0][0] / (fac[0][0] + 4.0));
    println!("try: fund A value loading +0.3, A-B covariance {:.2}", quad(&[1.2, 0.4, 0.3], &om, &bm[1]));
    let b1 = [1.0, 0.4, -0.3];
    println!("try: fund A market loading 1.0, variance {:.2}", quad(&b1, &om, &b1) + d[0][0]);
    println!("ALL CHECKS PASS");
}
