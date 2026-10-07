// Estimation error and Ledoit-Wolf shrinkage -- the same check as the Python, in Rust.
// No crates.  A made-up market of 20 stocks whose true covariance is known; 60-month
// histories are drawn from it with the same home-made generator, and the minimum-variance
// portfolio is rebuilt from each.  Returns are in percent per month.
const P: usize = 20; const N: usize = 60; const H: usize = 300; const B: usize = 300;
const MKT: f64 = 16.0; const MU: f64 = 0.8;               // market risk % a year; mean % a month
type Mat = Vec<Vec<f64>>;
struct Rng(u64);
impl Rng {
    fn rand(&mut self) -> f64 {                   // splitmix64, then a uniform in (0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53) + 2f64.powi(-54)
    }
    fn normal(&mut self) -> f64 {                 // Box-Muller, one draw per pair of uniforms
        let (u1, u2) = (self.rand(), self.rand());
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
fn beta(i: usize) -> f64 { 0.6 + 0.8 * i as f64 / 19.0 }
fn idio(i: usize) -> f64 { 10.0 + 5.0 * (i % 4) as f64 }
fn history(rng: &mut Rng, n: usize) -> Mat {      // r = mean + beta * market shock + own shock
    (0..n).map(|_| { let f = MKT / 12f64.sqrt() * rng.normal();
        (0..P).map(|i| MU + beta(i) * f + idio(i) / 12f64.sqrt() * rng.normal()).collect() }).collect()
}
fn cov(x: &Mat) -> (Mat, Mat) {                   // centre each stock, divide by n (as Ledoit-Wolf)
    let n = x.len() as f64;
    let m: Vec<f64> = (0..P).map(|i| x.iter().map(|r| r[i]).sum::<f64>() / n).collect();
    let xc: Mat = x.iter().map(|r| (0..P).map(|i| r[i] - m[i]).collect()).collect();
    let s = (0..P).map(|i| (0..P).map(|j| xc.iter().map(|r| r[i] * r[j]).sum::<f64>() / n).collect()).collect();
    (s, xc)
}
fn eye(i: usize, j: usize) -> f64 { if i == j { 1.0 } else { 0.0 } }
fn ledoit_wolf(s: &Mat, xc: &Mat) -> (Mat, f64, f64, f64, f64, f64) {  // target tau*I, intensity b2/d2
    let (n, tau) = (xc.len() as f64, (0..P).map(|i| s[i][i]).sum::<f64>() / P as f64);
    let (mut d2, mut b2bar) = (0.0, 0.0);
    for i in 0..P { for j in 0..P {
        d2 += (s[i][j] - tau * eye(i, j)).powi(2);
        for x in xc { b2bar += (x[i] * x[j] - s[i][j]).powi(2); }
    } }
    d2 /= P as f64; b2bar = b2bar / P as f64 / (n * n);
    let b2 = b2bar.min(d2); let a = b2 / d2;
    let l = (0..P).map(|i| (0..P).map(|j| (1.0 - a) * s[i][j] + a * tau * eye(i, j)).collect()).collect();
    (l, a, tau, d2, b2bar, b2)
}
fn gmv(m: &Mat) -> Vec<f64> {                     // road 1: solve M w = 1 by elimination, rescale
    let mut a: Mat = m.iter().map(|r| { let mut v = r.clone(); v.push(1.0); v }).collect();
    for c in 0..P {
        let p = (c..P).max_by(|&x, &y| a[x][c].abs().partial_cmp(&a[y][c].abs()).unwrap()).unwrap();
        a.swap(c, p);
        for r in c + 1..P { let f = a[r][c] / a[c][c]; for k in 0..=P { a[r][k] -= f * a[c][k]; } }
    }
    let mut x = vec![0.0; P];
    for c in (0..P).rev() { x[c] = (a[c][P] - (c + 1..P).map(|k| a[c][k] * x[k]).sum::<f64>()) / a[c][c]; }
    unit(x)
}
fn unit(x: Vec<f64>) -> Vec<f64> { let tot: f64 = x.iter().sum(); x.iter().map(|v| v / tot).collect() }
fn jacobi(m: &Mat) -> (Vec<f64>, Mat) {           // eigenvalues and eigenvectors by Jacobi rotations
    let mut a = m.clone();
    let mut v: Mat = (0..P).map(|i| (0..P).map(|j| eye(i, j)).collect()).collect();
    for _ in 0..100 {
        let off: f64 = (0..P).flat_map(|i| (0..P).map(move |j| (i, j))).filter(|(i, j)| i != j)
            .map(|(i, j)| a[i][j] * a[i][j]).sum();
        if off < 1e-22 { break; }
        for p in 0..P { for q in p + 1..P {
            if a[p][q].abs() < 1e-300 { continue; }
            let th = 0.5 * (a[q][q] - a[p][p]) / a[p][q];
            let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
            let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
            for mm in [&mut a, &mut v] {           // rotate columns p, q
                for k in 0..P { let (x, y) = (mm[k][p], mm[k][q]); mm[k][p] = c * x - s * y; mm[k][q] = s * x + c * y; }
            }
            for k in 0..P { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
        } }
    }
    ((0..P).map(|i| a[i][i]).collect(), v)
}
fn gmv_eigen(m: &Mat) -> Vec<f64> {               // road 2: w ~ sum over directions of (v.1) v / lambda
    let (lam, v) = jacobi(m);
    unit((0..P).map(|i| (0..P).map(|k| v[i][k] * (0..P).map(|j| v[j][k]).sum::<f64>() / lam[k]).sum()).collect())
}
fn quad(w: &[f64], m: &Mat) -> f64 { (0..P).map(|i| (0..P).map(|j| w[i] * m[i][j] * w[j]).sum::<f64>()).sum() }
fn vol(v: f64) -> f64 { (12.0 * v).sqrt() }       // monthly variance in %^2 -> % a year
fn sorted_eig(m: &Mat) -> Vec<f64> { let mut e = jacobi(m).0; e.sort_by(|a, b| a.partial_cmp(b).unwrap()); e }
fn stats(v: &[f64]) -> (f64, f64, f64, f64) {
    let m = v.iter().sum::<f64>() / v.len() as f64; let sd = (v.iter().map(|x| (x - m).powi(2)).sum::<f64>() / v.len() as f64).sqrt();
    (m, sd, v.iter().cloned().fold(f64::MAX, f64::min), v.iter().cloned().fold(f64::MIN, f64::max))
}
fn row(label: &str, vals: &[f64], w: usize, d: usize) {
    println!("{:<30}{}", label, vals.iter().map(|v| format!("{:w$.d$}", v, w = w, d = d)).collect::<Vec<_>>().join(" "));
}
fn main() {
    let sig: Mat = (0..P).map(|i| (0..P).map(|j| MKT * MKT / 12.0 * beta(i) * beta(j) + eye(i, j) * idio(i).powi(2) / 12.0).collect()).collect();
    let mut rng = Rng(20260928);
    let w_true = gmv(&sig); let true_min = quad(&w_true, &sig);
    let x1 = history(&mut rng, N); let (s1, xc1) = cov(&x1);
    let (l1, a1, tau1, d21, bb1, b21) = ledoit_wolf(&s1, &xc1);
    let (ws1, wl1) = (gmv(&s1), gmv(&l1));
    let (e_true, e_s, e_l) = (sorted_eig(&sig), sorted_eig(&s1), sorted_eig(&l1));
    let r2: Vec<f64> = gmv_eigen(&s1).into_iter().chain(gmv_eigen(&l1)).collect();
    let road2 = ws1.iter().chain(wl1.iter()).zip(r2.iter()).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max);
    let half = gmv(&s1.iter().map(|r| r.iter().map(|v| 0.5 * v).collect()).collect());
    let (mut loss, mut num, mut den) = (vec![0.0; 101], 0.0, 0.0);
    let mut keep: Vec<Vec<f64>> = vec![Vec::new(); 11];   // w1s w1l gs gl rs ts rl tl a fs fl
    for h in 0..H {
        let (s, xc) = if h == 0 { (s1.clone(), xc1.clone()) } else { cov(&history(&mut rng, N)) };
        let (l, a, tau, ..) = ledoit_wolf(&s, &xc); let (ws, wl) = (gmv(&s), gmv(&l));
        let (mut fs, mut fl, mut lh) = (0.0, 0.0, vec![0.0; 101]);
        for i in 0..P { for j in 0..P {
            let e = s[i][j] - sig[i][j];                // sample error
            let d = s[i][j] - tau * eye(i, j);          // sample minus target
            num += e * d; den += d * d; fs += e * e; fl += (l[i][j] - sig[i][j]).powi(2);
            for k in 0..101 { lh[k] += (e - k as f64 / 100.0 * d).powi(2); }   // brute force: every intensity
        } }
        for k in 0..101 { loss[k] += lh[k] / P as f64 / H as f64; }
        let vals = [ws[0], wl[0], ws.iter().map(|v| v.abs()).sum(), wl.iter().map(|v| v.abs()).sum(),
                    quad(&ws, &s), quad(&ws, &sig), quad(&wl, &l), quad(&wl, &sig), a, fs / P as f64, fl / P as f64];
        for (k, v) in vals.iter().enumerate() { keep[k].push(*v); }
    }
    let boot: Vec<f64> = (0..B).map(|_| {                // resample history 1's months
        let xb: Mat = (0..N).map(|_| x1[(rng.rand() * N as f64) as usize].clone()).collect();
        gmv(&cov(&xb).0)[0]
    }).collect();
    let mean: Vec<f64> = keep.iter().map(|v| v.iter().sum::<f64>() / H as f64).collect();
    let a_grid = (0..101).min_by(|&x, &y| loss[x].partial_cmp(&loss[y]).unwrap()).unwrap() as f64 / 100.0;
    let (s240, xc240) = cov(&history(&mut rng, 240)); let (l240, a240, ..) = ledoit_wolf(&s240, &xc240);
    let (s15, xc15) = cov(&history(&mut rng, 15)); let (l15, a15, ..) = ledoit_wolf(&s15, &xc15);
    let pct = |w: &[f64]| -> Vec<f64> { w.iter().map(|v| 100.0 * v).collect() };
    println!("market: {} stocks, {} months, {} fresh histories, {} bootstrap resamples", P, N, H, B);
    row("weights %, true", &pct(&w_true), 5, 0);
    row("weights %, history 1 sample", &pct(&ws1), 5, 0);
    row("weights %, history 1 shrunk", &pct(&wl1), 5, 0);
    println!("road 2, eigen expansion vs elimination, agree to 1e-9: {}", if road2 < 1e-9 { "yes" } else { "no" });
    row("eigenvalues, true", &e_true, 7, 2);
    row("eigenvalues, history 1 sample", &e_s, 7, 2);
    row("eigenvalues, history 1 shrunk", &e_l, 7, 2);
    println!("history 1: tau {:.4}  d2 {:.4}  b2bar {:.4}  b2 {:.4}  intensity a {:.4}", tau1, d21, bb1, b21, a1);
    println!("smallest eigenvalue: true {:.2}  sample {:.2}  shrunk {:.2}  check (1-a)*{:.2}+a*tau = {:.2}",
             e_true[0], e_s[0], e_l[0], e_s[0], (1.0 - a1) * e_s[0] + a1 * tau1);
    println!("largest over smallest: true {:.1}  sample {:.1}  shrunk {:.1}", e_true[P - 1] / e_true[0], e_s[P - 1] / e_s[0], e_l[P - 1] / e_l[0]);
    println!("true minimum variance {:.4} %^2 a month = {:.2}% a year", true_min, vol(true_min));
    println!("history 1 sample portfolio: reported {:.2}%  true {:.2}%", vol(quad(&ws1, &s1)), vol(quad(&ws1, &sig)));
    println!("history 1 shrunk portfolio: reported {:.2}%  true {:.2}%", vol(quad(&wl1, &l1)), vol(quad(&wl1, &sig)));
    println!("average over {}: sample reported {:.2}%  sample true {:.2}%", H, vol(mean[4]), vol(mean[5]));
    println!("average over {}: shrunk reported {:.2}%  shrunk true {:.2}%", H, vol(mean[6]), vol(mean[7]));
    println!("equal weights (intensity 1): true {:.2}%", vol(quad(&vec![1.0 / P as f64; P], &sig)));
    for (lab, k) in [("stock 1 weight %, sample", 0), ("stock 1 weight %, shrunk", 1)] {
        let (m, s, lo, hi) = stats(&pct(&keep[k]));
        println!("{}: mean {:.1}  sd {:.1}  min {:.1}  max {:.1}  (true {:.1})", lab, m, s, lo, hi, 100.0 * w_true[0]);
    }
    println!("stock 1 weight %, sd over bootstrap of history 1: {:.1}", 100.0 * stats(&boot).1);
    println!("gross exposure sum|w|: true {:.2}  sample {:.2}  shrunk {:.2}", w_true.iter().map(|v| v.abs()).sum::<f64>(), mean[2], mean[3]);
    println!("intensity: Ledoit-Wolf average {:.3}  oracle from the truth {:.3}  grid best {:.2}", mean[8], num / den, a_grid);
    println!("covariance loss per stock: sample {:.2}  shrunk {:.2}", mean[9], mean[10]);
    row("loss curve a=0,0.1..1", &(0..11).map(|k| loss[10 * k]).collect::<Vec<f64>>(), 7, 2);
    println!("mistake, shrink toward zero (S/2): largest weight change {:.4}", ws1.iter().zip(half.iter()).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max));
    println!("try 240 months: intensity {:.3}  stock 1 sample {:.1}%  shrunk {:.1}%", a240, 100.0 * gmv(&s240)[0], 100.0 * gmv(&l240)[0]);
    println!("try 15 months: smallest sample eigenvalue {:.4}  intensity {:.3}  shrunk stock 1 {:.1}%", sorted_eig(&s15)[0].abs(), a15, 100.0 * gmv(&l15)[0]);
    assert!(road2 < 1e-9, "eigen expansion must reproduce elimination");
    assert!((e_s.iter().sum::<f64>() - (0..P).map(|i| s1[i][i]).sum::<f64>()).abs() < 1e-8, "eigenvalues must add to the trace");
    assert!((e_l[0] - ((1.0 - a1) * e_s[0] + a1 * tau1)).abs() < 1e-8, "shrinkage moves each eigenvalue toward tau");
    assert!(mean[4] < true_min, "reported risk of the sample optimum sits below the true minimum");
    assert!(mean[5] > true_min, "its true risk sits above the true minimum");
    assert!((mean[8] - num / den).abs() < 0.05, "one-history estimate vs the oracle built from the truth");
    assert!((a_grid - num / den).abs() < 0.02, "brute-force grid vs the oracle formula");
    assert!(mean[7] < mean[5], "shrinkage must lower the true risk on average");
    println!("ALL CHECKS PASS");
}
