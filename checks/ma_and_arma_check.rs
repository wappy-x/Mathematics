// Moving average and ARMA -- the check behind the card.  Rust std only.
// Monthly sales after an advert: X_t = 500 + e_t + 0.6 e_(t-1) + 0.3 e_(t-2), surprises of sd 40.
// Every random draw comes from SplitMix64 (seed stated), turned normal by Box-Muller.
struct Rng(u64);
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 {
        let u1 = 1.0 - self.u();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.u()).cos()
    }
}
const MU: f64 = 500.0; const SIG: f64 = 40.0; const TH: [f64; 3] = [1.0, 0.6, 0.3];
const PHI: f64 = 0.5; const TA: f64 = 0.3; // ARMA(1,1): loyalty carries half of last month
fn acov_formula(th: &[f64], h: usize, s2: f64) -> f64 { // road 1: count the shocks two months share
    if h >= th.len() { 0.0 } else { s2 * (0..th.len() - h).fold(0.0, |a, j| a + th[j] * th[j + h]) }
}
fn acov_enum(th: &[f64], h: usize, s: f64) -> f64 { // road 2: every surprise is +s or -s; list all
    let w = th.len() + h; let mut tot = 0.0;
    for word in 0..(1usize << w) {
        let e: Vec<f64> = (0..w).map(|i| if (word >> i) & 1 == 1 { s } else { -s }).collect();
        tot += (0..th.len()).fold(0.0, |a, j| a + th[j] * e[j]) * (0..th.len()).fold(0.0, |a, j| a + th[j] * e[j + h]);
    }
    tot / (1usize << w) as f64
}
fn arma_rho(h: usize) -> f64 {
    if h == 0 { 1.0 } else { (1.0 + PHI * TA) * (PHI + TA) / (1.0 + 2.0 * PHI * TA + TA * TA) * PHI.powi(h as i32 - 1) }
}
fn arma_psi_acov(h: usize) -> f64 { // road 2 for ARMA: weights on past surprises
    let n = 400; let psi: Vec<f64> = (0..n + h).map(|j| if j == 0 { 1.0 } else { PHI.powi(j as i32 - 1) * (PHI + TA) }).collect();
    SIG * SIG * (0..n).fold(0.0, |a, j| a + psi[j] * psi[j + h])
}
fn pacf(rho: &[f64], hmax: usize) -> Vec<f64> { // Durbin-Levinson: last coefficient of best AR(k)
    let (mut out, mut a): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    for k in 1..=hmax {
        let num = rho[k] - (0..k - 1).fold(0.0, |s, j| s + a[j] * rho[k - 1 - j]);
        let den = 1.0 - (0..k - 1).fold(0.0, |s, j| s + a[j] * rho[j + 1]);
        let kk = num / den; let mut na: Vec<f64> = (0..k - 1).map(|j| a[j] - kk * a[k - 2 - j]).collect();
        na.push(kk); a = na; out.push(kk);
    }
    out
}
fn yw_last(rho: &[f64], k: usize) -> f64 { // road 2 for the PACF: the k-by-k Yule-Walker system, by elimination
    let mut a: Vec<Vec<f64>> = (0..k).map(|i| (0..=k).map(|j| if j < k { rho[i.abs_diff(j)] } else { rho[i + 1] }).collect()).collect();
    for c in 0..k { for i in c + 1..k { let f = a[i][c] / a[c][c]; for j in 0..=k { a[i][j] -= f * a[c][j]; } } }
    a[k - 1][k] / a[k - 1][k - 1] // the last unknown: the partial autocorrelation at lag k
}
fn sample_acf(x: &[f64], hmax: usize) -> Vec<f64> {
    let m = x.iter().fold(0.0, |a, v| a + v) / x.len() as f64;
    let d: Vec<f64> = x.iter().map(|v| v - m).collect();
    let c0 = d.iter().fold(0.0, |a, v| a + v * v); let mut out = vec![1.0];
    for h in 1..=hmax { out.push((0..d.len() - h).fold(0.0, |a, t| a + d[t] * d[t + h]) / c0); }
    out
}
fn ma2_path(rng: &mut Rng, n: usize, th: &[f64]) -> (Vec<f64>, Vec<f64>) {
    let e: Vec<f64> = (0..n + 2).map(|_| SIG * rng.normal()).collect();
    ((0..n).map(|t| MU + e[t + 2] + th[1] * e[t + 1] + th[2] * e[t]).collect(), e[2..].to_vec())
}
fn resid(x: &[f64], t1: f64, t2: f64, m: f64) -> (Vec<f64>, Vec<f64>, Vec<f64>) { // recover surprises, start from 0
    let (mut e, mut a, mut b) = (vec![0.0, 0.0], vec![0.0, 0.0], vec![0.0, 0.0]);
    for v in x {
        let k = e.len();
        a.push(-e[k - 1] - t1 * a[k - 1] - t2 * a[k - 2]); b.push(-e[k - 2] - t1 * b[k - 1] - t2 * b[k - 2]);
        e.push(v - m - t1 * e[k - 1] - t2 * e[k - 2]);
    }
    (e[2..].to_vec(), a[2..].to_vec(), b[2..].to_vec())
}
fn dot(p: &[f64], q: &[f64]) -> f64 { p.iter().zip(q).fold(0.0, |s, (a, b)| s + a * b) }
fn fit(x: &[f64]) -> (f64, f64, f64, f64, f64, f64, Vec<f64>) { // least squares, Gauss-Newton
    let m = x.iter().fold(0.0, |a, v| a + v) / x.len() as f64; let (mut t1, mut t2) = (0.0, 0.0);
    for _ in 0..30 {
        let (e, a, b) = resid(x, t1, t2, m);
        let (saa, sab, sbb, sae, sbe) = (dot(&a, &a), dot(&a, &b), dot(&b, &b), dot(&a, &e), dot(&b, &e));
        let (det, sse, mut step) = (saa * sbb - sab * sab, dot(&e, &e), 1.0);
        let (d1, d2) = ((sbb * sae - sab * sbe) / det, (saa * sbe - sab * sae) / det);
        while step > 1e-6 { let r = resid(x, t1 - step * d1, t2 - step * d2, m).0; if dot(&r, &r) > sse { step /= 2.0; } else { break; } }
        t1 -= step * d1; t2 -= step * d2; // halve the step until the squares shrink
    }
    let (e, a, b) = resid(x, t1, t2, m);
    let s2 = dot(&e, &e) / (x.len() - 3) as f64;
    let (saa, sab, sbb) = (dot(&a, &a), dot(&a, &b), dot(&b, &b)); let det = saa * sbb - sab * sab;
    (m, t1, t2, (s2 * sbb / det).sqrt(), (s2 * saa / det).sqrt(), s2, e)
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let g: Vec<f64> = (0..7).map(|h| acov_formula(&TH, h, SIG * SIG)).collect();
    let rho: Vec<f64> = g.iter().map(|v| v / g[0]).collect();
    println!("MA(2) sales: mean 500, surprise sd 40, echo weights 1, 0.6, 0.3");
    println!("lag  gamma by formula  gamma by enumeration     rho");
    for h in 0..4 {
        let ge = acov_enum(&TH, h, SIG); println!("{:>3} {:>17.4} {:>21.4} {:>7.4}", h, g[h], ge, rho[h]);
        assert!((ge - g[h]).abs() < 1e-9);
    }
    println!("variance {:.4}, sd {:.4}", g[0], g[0].sqrt());
    let ga0 = SIG * SIG * (1.0 + 2.0 * PHI * TA + TA * TA) / (1.0 - PHI * PHI);
    let arho: Vec<f64> = (0..7).map(arma_rho).collect();
    println!("ARMA(1,1) phi 0.5 theta 0.3: gamma0 closed form {:.4}, by weights {:.4}", ga0, arma_psi_acov(0));
    for h in 1..4 {
        let pr = arma_psi_acov(h) / arma_psi_acov(0); println!("  lag {}: rho closed form {:.4}, by weights {:.4}", h, arho[h], pr);
        assert!((pr - arho[h]).abs() < 1e-9);
    }
    let em: Vec<f64> = (0..6).map(|j| 100.0 * if j < 3 { TH[j] } else { 0.0 }).collect();
    let ea: Vec<f64> = (0..6).map(|j| 100.0 * if j == 0 { 1.0 } else { PHI.powi(j as i32 - 1) * (PHI + TA) }).collect();
    println!("chart, echo of a +100 surprise, MA(2)  {}", join(&em, 2));
    println!("chart, echo of a +100 surprise, ARMA   {}", join(&ea, 2));
    let ar1: Vec<f64> = (0..7).map(|h| PHI.powi(h)).collect(); let p2 = |r: &Vec<f64>| (r[2] - r[1] * r[1]) / (1.0 - r[1] * r[1]);
    assert!(pacf(&ar1, 6)[1..].iter().all(|v| v.abs() < 1e-12) && [&rho, &arho].iter().all(|r| (pacf(r, 6)[1] - p2(r)).abs() < 1e-12));
    for (name, r) in [("AR(1)", &ar1), ("MA(2)", &rho), ("ARMA", &arho)] {
        println!("chart, ACF  {:<6}{}", name, join(&r[1..], 2));
        println!("chart, PACF {:<6}{}", name, join(&pacf(r, 6), 2));
    }
    // road 3: a long simulated run, autocorrelations in 60 batches of 2,000 months
    let mut rng = Rng(20260929); let (xs, _) = ma2_path(&mut rng, 120000, &TH);
    let (mut y, mut prev, mut ep) = (vec![], 0.0, SIG * rng.normal());
    for t in 0..120100 {
        let en = SIG * rng.normal(); prev = PHI * prev + en + TA * ep; ep = en;
        if t >= 100 { y.push(MU + prev); }
    }
    println!("simulated 120000 months, 60 batches: lag, MA(2) sim (se) theory, ARMA sim (se) theory");
    for h in 1..4 {
        let mut row = vec![];
        for (s, th) in [(&xs, rho[h]), (&y, arho[h])] {
            let b: Vec<f64> = (0..60).map(|i| sample_acf(&s[i * 2000..(i + 1) * 2000], h)[h]).collect();
            let mb = b.iter().fold(0.0, |a, v| a + v) / 60.0;
            let se = (b.iter().fold(0.0, |a, v| a + (v - mb).powi(2)) / 59.0 / 60.0).sqrt();
            assert!((mb - th).abs() < 4.0 * se); row.push(format!("{:.4} ({:.4}) {:.4}", mb, se, th));
        }
        println!("  lag {}: {}", h, row.join("   "));
    }
    let a1 = sample_acf(&xs, 1)[1]; let mx = xs.iter().fold(0.0, |a, v| a + v) / xs.len() as f64;
    let r1: Vec<f64> = (1..xs.len()).map(|t| xs[t] - mx - a1 * (xs[t - 1] - mx)).collect();
    let v_th = g[0] * (1.0 - rho[1].powi(2)); let v_sim = dot(&r1, &r1) / r1.len() as f64;
    println!("wrong order, AR(1) on MA(2): error variance theory {:.4}, long run {:.4}, true 1600.0000", v_th, v_sim);
    assert!((v_sim - v_th).abs() < 0.02 * v_th && (v_sim - 1600.0).abs() > 0.02 * 1600.0);
    // identification and fit on one 240-month record
    let (rec, true_e) = ma2_path(&mut Rng(26), 240, &TH); let ra = sample_acf(&rec, 6); let rp = pacf(&ra, 6);
    println!("record of 240 months, band 2/sqrt(240) = {:.4}; beyond lag 2, Bartlett widens it by {:.4}", 2.0 / 240f64.sqrt(), (1.0 + 2.0 * (rho[1].powi(2) + rho[2].powi(2))).sqrt());
    assert!([(pacf(&rho, 6), &rho), (pacf(&arho, 6), &arho), (rp.clone(), &ra)].iter().all(|(p, r)| (1..7).all(|k| (p[k - 1] - yw_last(r, k)).abs() < 1e-9))); // two roads to every PACF
    println!("  sample ACF  {}", join(&ra[1..], 4)); println!("  sample PACF {}", join(&rp, 4)); println!("  first months {}", join(&rec[..4], 2));
    let (m, t1, t2, se1, se2, s2, e) = fit(&rec);
    println!("fit: mean {:.4} (se {:.4}), theta1 {:.4} (se {:.4}), theta2 {:.4} (se {:.4}), surprise sd {:.4}", m, s2.sqrt() * (1.0 + t1 + t2) / 240f64.sqrt(), t1, se1, t2, se2, s2.sqrt());
    println!("textbook se sqrt((1 - theta2^2)/n) = {:.4}", ((1.0 - TH[2].powi(2)) / 240.0).sqrt());
    assert!((t1 - 0.6).abs() < 3.0 * se1 && (t2 - 0.3).abs() < 3.0 * se2);
    println!("  residual ACF lags 1-3 {}", join(&sample_acf(&e, 3)[1..], 4));
    let mut mc = Rng(11); let (mut f1, mut f2) = (vec![], vec![]);
    for _ in 0..200 { let r = fit(&ma2_path(&mut mc, 240, &TH).0); f1.push(r.1); f2.push(r.2); }
    let mean = |v: &Vec<f64>| v.iter().fold(0.0, |a, w| a + w) / v.len() as f64;
    let sd = |v: &Vec<f64>| (v.iter().fold(0.0, |a, w| a + (w - mean(v)).powi(2)) / (v.len() - 1) as f64).sqrt();
    println!("200 simulated records: theta1 mean {:.4} sd {:.4}, theta2 mean {:.4} sd {:.4}", mean(&f1), sd(&f1), mean(&f2), sd(&f2));
    let tse = (0.91f64 / 240.0).sqrt(); assert!((sd(&f1) / tse - 1.0).abs() < 0.25 && (sd(&f2) / tse - 1.0).abs() < 0.25);
    // invertibility: the twin with echo weights 2 and 3.33 and surprises of sd 12 has the same correlogram
    let tw = [1.0, TH[1] / TH[2], 1.0 / TH[2]];
    println!("twin: weights 1, {:.4}, {:.4}, sd {:.4}; root size {:.4} vs {:.4}", tw[1], tw[2], SIG * TH[2], (1.0 / TH[2]).sqrt(), (1.0 / tw[2]).sqrt());
    for h in 0..3 {
        let gt = acov_enum(&tw, h, SIG * TH[2]); println!("  lag {}: twin gamma {:.4}, sales gamma {:.4}", h, gt, g[h]);
        assert!((gt - g[h]).abs() < 1e-9);
    }
    let ok = resid(&rec, 0.6, 0.3, MU).0; let bad = resid(&rec, tw[1], tw[2], MU).0;
    for t in [1, 2, 3, 6, 12, 24] {
        println!("  month {:>2}: true surprise {:>8.2}, recovered {:>8.2}, twin recursion {:>12.2}", t, true_e[t - 1], ok[t - 1], bad[t - 1]);
    }
    assert!((ok[23] - true_e[23]).abs() < 0.01 && bad[23].abs() > 1e6);
    let c = [1.0, 1.1, 0.6, 0.15]; // surprises sharing part of last month's: u = e + 0.5 e(-1)
    let (r3f, r3e) = (acov_formula(&c, 3, 1.0) / acov_formula(&c, 0, 1.0), acov_enum(&c, 3, 1.0) / acov_enum(&c, 0, 1.0)); assert!((r3f - r3e).abs() < 1e-12 && r3f > 0.05);
    println!("correlated surprises: rho3 formula {:.4}, enumerated {:.4}, independent 0.0000", r3f, r3e);
}
