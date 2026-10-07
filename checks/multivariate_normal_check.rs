// Multivariate normal -- the same check as the Python, in Rust.  No crates.
// Three daily share returns in percent (bank, insurer, miner) are built as
// X = MU + L Z from three independent standard normal draws Z.  Roads: the
// covariance by L times L-transpose, by simulation, and L recovered from the
// covariance alone by Cholesky; the portfolio's bad-day chance by the normal
// formula and by counting simulated days; the density by two routes.
use std::f64::consts::PI;

type M = Vec<Vec<f64>>;
const NAMES: [&str; 3] = ["bank", "insurer", "miner"];
const N: usize = 200000;
const LOSS: f64 = -200.0;

fn tr(a: &M) -> M { (0..a[0].len()).map(|j| a.iter().map(|r| r[j]).collect()).collect() }
fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).fold(0.0, |s, (a, b)| s + a * b) }
fn mv(a: &M, v: &[f64]) -> Vec<f64> { a.iter().map(|r| dot(r, v)).collect() }
fn mul(a: &M, b: &M) -> M { let bt = tr(b); a.iter().map(|r| bt.iter().map(|c| dot(r, c)).collect()).collect() }
fn row(v: &[f64]) -> String { v.iter().map(|x| format!("{:8.4}", x)).collect::<Vec<_>>().join(" ") }
fn row2(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ") }

fn cholesky(s: &M) -> (Option<M>, Vec<f64>) { // the factor, and each pivot before its root
    let n = s.len();
    let (mut c, mut piv) = (vec![vec![0.0; n]; n], Vec::new());
    for j in 0..n {
        let p = s[j][j] - (0..j).fold(0.0, |t, k| t + c[j][k] * c[j][k]);
        piv.push(p);
        if p <= 1e-9 * s[j][j] { return (None, piv); }
        c[j][j] = p.sqrt();
        for i in j + 1..n {
            c[i][j] = (s[i][j] - (0..j).fold(0.0, |t, k| t + c[i][k] * c[j][k])) / c[j][j];
        }
    }
    (Some(c), piv)
}

fn solve(s: &M, b: &[f64]) -> Vec<f64> { // Gaussian elimination, no inverse formed
    let n = b.len();
    let mut a: M = (0..n).map(|i| { let mut r = s[i].clone(); r.push(b[i]); r }).collect();
    for j in 0..n {
        for i in j + 1..n {
            let m = a[i][j] / a[j][j];
            a[i] = a[i].iter().zip(&a[j]).map(|(x, c)| x - m * c).collect();
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        x[i] = (a[i][n] - (i + 1..n).fold(0.0, |t, k| t + a[i][k] * x[k])) / a[i][i];
    }
    x
}

fn det3(s: &M) -> f64 { // cofactor expansion along the top row
    s[0][0] * (s[1][1] * s[2][2] - s[1][2] * s[2][1]) - s[0][1] * (s[1][0] * s[2][2] - s[1][2] * s[2][0])
        + s[0][2] * (s[1][0] * s[2][1] - s[1][1] * s[2][0])
}

fn phi_cdf(x: f64) -> f64 { // standard normal area left of x, Taylor series
    let (mut term, mut total) = (x, x);
    for n in 1..80 {
        term *= -x * x / (2 * n) as f64;
        total += term / (2 * n + 1) as f64;
    }
    0.5 + total / (2.0 * PI).sqrt()
}

struct SplitMix(u64); // SplitMix64, seed 20260928
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn normal_pair(&mut self) -> (f64, f64) { // Marsaglia's polar method
        loop {
            let u = 2.0 * (((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53)) - 1.0;
            let v = 2.0 * (((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53)) - 1.0;
            let s = u * u + v * v;
            if s > 0.0 && s < 1.0 { let k = (-2.0 * s.ln() / s).sqrt(); return (u * k, v * k); }
        }
    }
}

fn main() {
    let mu = [0.04, 0.03, 0.05]; // average daily return, percent
    let l: M = vec![vec![1.0, 0.0, 0.0], vec![0.9, 1.2, 0.0], vec![1.2, 0.0, 1.6]];
    let w = [50.0, 30.0, 20.0]; // dollars per 1% move: $5,000, $3,000, $2,000
    let z_day = [1.0, -0.5, 0.25]; // one day's three draws
    let bins: Vec<f64> = (0..13).map(|k| -300.0 + 50.0 * k as f64).collect();
    let s = mul(&l, &tr(&l)); // road 1: Sigma = L L^T
    let sd: Vec<f64> = (0..3).map(|i| s[i][i].sqrt()).collect();
    let (c, piv) = cholesky(&s); // road 2: L back from Sigma alone
    let c = c.expect("Sigma is positive definite");
    let mut cond = vec![s[0][0]];
    for j in 1..3 {
        let block: M = s[..j].iter().map(|r| r[..j].to_vec()).collect();
        cond.push(s[j][j] - dot(&s[j][..j], &solve(&block, &s[j][..j])));
    }
    let x_day: Vec<f64> = mu.iter().zip(mv(&l, &z_day)).map(|(m, d)| m + d).collect();
    let dev: Vec<f64> = x_day.iter().zip(&mu).map(|(a, m)| a - m).collect();
    let q_elim = dot(&dev, &solve(&s, &dev));
    let (d_cof, d_diag) = (det3(&s), (l[0][0] * l[1][1] * l[2][2]).powf(2.0));
    let norm = (2.0 * PI).powf(1.5) * d_cof.sqrt();
    let (p_mean, p_var, cw) = (dot(&w, &mu), dot(&w, &mv(&s, &w)), mv(&tr(&l), &w));
    let (p_sd, sw) = (p_var.sqrt(), mv(&s, &w));
    let tail = phi_cdf((LOSS - p_mean) / p_sd);
    println!("model: daily returns in percent; means {}", row(&mu));
    for (nm, r) in NAMES.iter().zip(&l) { println!("L       {:8}{}", nm, row(r)); }
    for (nm, r) in NAMES.iter().zip(&s) { println!("Sigma   {:8}{}", nm, row(r)); }
    println!("sd {}; correlations {:.4}, {:.4}, {:.4}", row(&sd), s[0][1] / sd[0] / sd[1], s[0][2] / sd[0] / sd[2], s[1][2] / sd[1] / sd[2]);
    for (nm, r) in NAMES.iter().zip(&c) { println!("Cholesky of Sigma {:8}{}", nm, row(r)); }
    println!("pivots under each root {}; conditional variances by regression {}", row(&piv), row(&cond));
    let zd: Vec<String> = z_day.iter().map(|x| format!("{:.2}", x)).collect();
    println!("one day: draws {} -> returns {}; portfolio ${:.2}", zd.join(" "), row(&x_day), dot(&w, &x_day));
    println!("det Sigma by cofactors {:.6}; (product of L's diagonal)^2 {:.6}", d_cof, d_diag);
    println!("(x-mu)^T Sigma^-1 (x-mu) by elimination {:.6}; |z|^2 {:.6}", q_elim, dot(&z_day, &z_day));
    println!("density at the mean {:.6}; on that day {:.6}", 1.0 / norm, (-q_elim / 2.0).exp() / norm);
    println!("portfolio: mean ${:.2}; w^T Sigma w {:.2}; L^T w = {}, |L^T w|^2 {:.2}; sd ${:.2}", p_mean, p_var, row2(&cw), dot(&cw, &cw), p_sd);
    println!("P(loss worse than $200) = Phi({:.4}) = {:.4}, 1 day in {:.0}", (LOSS - p_mean) / p_sd, tail, 1.0 / tail);

    let (mut sp, mut sp2, mut hist) = ([[0.0f64; 3]; 3], [[0.0f64; 3]; 3], [0usize; 12]);
    let (mut hits, mut pv, mut pv2, mut zeros, mut cy, mut y_low) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    let mut rng = SplitMix(20260928);
    for _ in 0..N {
        let ((z1, z2), (z3, z4)) = (rng.normal_pair(), rng.normal_pair());
        let d = mv(&l, &[z1, z2, z3]); // X - MU
        for i in 0..3 { for j in 0..3 { sp[i][j] += d[i] * d[j]; sp2[i][j] += (d[i] * d[j]).powf(2.0); } }
        let p = dot(&w, &mu.iter().zip(&d).map(|(m, e)| m + e).collect::<Vec<f64>>());
        if p < LOSS { hits += 1.0; }
        (pv, pv2) = (pv + (p - p_mean).powf(2.0), pv2 + (p - p_mean).powf(4.0));
        if p >= bins[0] && p < bins[12] { hist[((p - bins[0]) / 50.0).floor() as usize] += 1; }
        let y = if z4 > 0.0 { z1 } else { -z1 }; // mistake 4: coin-flipped copy of the bank draw
        if z1 + y == 0.0 { zeros += 1.0; }
        if y < -1.0 { y_low += 1.0; }
        cy += z1 * y;
    }
    let nf = N as f64;
    let cov: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|j| sp[i][j] / nf).collect()).collect();
    let se: Vec<Vec<f64>> = (0..3).map(|i| (0..3).map(|j| ((sp2[i][j] / nf - cov[i][j].powf(2.0)) / nf).sqrt()).collect()).collect();
    println!("simulation, {} days, SplitMix64 seed 20260928, polar method", N);
    for i in 0..3 { println!("sample cov {:8}{}  SE{}", NAMES[i], row(&cov[i]), row(&se[i])); }
    let (ph, vh, tail_se) = (hits / nf, pv / nf, (tail * (1.0 - tail) / nf).sqrt()); let vh_se = ((pv2 / nf - vh * vh) / nf).sqrt();
    println!("portfolio variance simulated {:.2} (SE {:.2}); loss worse than $200 on {:.4} of days (SE {:.4})", vh, vh_se, ph, tail_se);
    println!("chart, $50 bins from -300 to 300, percent of days: formula | simulated");
    let fb: Vec<f64> = (0..12).map(|k| 100.0 * (phi_cdf((bins[k + 1] - p_mean) / p_sd) - phi_cdf((bins[k] - p_mean) / p_sd))).collect();
    let sb: Vec<f64> = hist.iter().map(|&h| 100.0 * h as f64 / nf).collect();
    println!("formula   {}\nsimulated {}", row2(&fb), row2(&sb));
    let sd_ind = w.iter().zip(&sd).fold(0.0, |t, (a, b)| t + (a * b).powf(2.0)).sqrt();
    let ind = phi_cdf((LOSS - p_mean) / sd_ind);
    println!("mistake 1, correlations dropped: sd ${:.2}, chance {:.4}, 1 day in {:.0}", sd_ind, ind, 1.0 / ind);
    println!("mistake 2, L^T L for L L^T: bank variance {:.4}, not {:.4}", mul(&tr(&l), &l)[0][0], s[0][0]);
    let bad: M = vec![vec![1.0, 0.9, 0.9], vec![0.9, 1.0, 0.0], vec![0.9, 0.0, 1.0]];
    let (bad_c, bad_piv) = cholesky(&bad);
    let bad_var = dot(&[1.0, -1.0, -1.0], &mv(&bad, &[1.0, -1.0, -1.0]));
    println!("mistake 3, correlations 0.9, 0.9, 0: pivots {}; mix (1, -1, -1) variance {:.4}", row(&bad_piv), bad_var);
    println!("mistake 4, coin-flipped copy: P(copy < -1) {:.4} vs Phi(-1) {:.4}; correlation {:.4}; sum exactly 0 on {:.4} of days", y_low / nf, phi_cdf(-1.0), cy / nf, zeros / nf);
    let mut s4: M = (0..3).map(|i| { let mut r = s[i].clone(); r.push(sw[i]); r }).collect();
    s4.push({ let mut r = sw.clone(); r.push(p_var); r });
    let s4_piv = cholesky(&s4).1[3].abs(); println!("singular: portfolio added as a fourth reading, pivot left {:.6}", s4_piv);
    assert!((0..3).all(|i| (0..3).all(|j| (c[i][j] - l[i][j]).abs() < 1e-12)));
    assert!(piv.iter().zip(&cond).all(|(p, v)| (p - v).abs() < 1e-12));
    assert!((d_cof - d_diag).abs() < 1e-12 && (q_elim - dot(&z_day, &z_day)).abs() < 1e-12 && (dot(&cw, &cw) - p_var).abs() < 1e-9);
    assert!((0..3).all(|i| (0..3).all(|j| (cov[i][j] - s[i][j]).abs() < 4.0 * se[i][j])));
    assert!((ph - tail).abs() < 4.0 * tail_se && (vh - p_var).abs() < 4.0 * vh_se);
    assert!(fb.iter().zip(&sb).all(|(f, h)| (f / 100.0 - h / 100.0).abs() < 4.0 * (f / 100.0 * (1.0 - f / 100.0) / nf).sqrt()));
    assert!(bad_c.is_none() && (bad_piv[0] * bad_piv[1] * bad_piv[2] - det3(&bad)).abs() < 1e-12 && s4_piv < 1e-9 * p_var);
    assert!((zeros / nf - 0.5).abs() < 4.0 * (0.25 / nf).sqrt() && (y_low / nf - phi_cdf(-1.0)).abs() < 4.0 * (0.16 / nf).sqrt());
    println!("ALL CHECKS PASS");
}
