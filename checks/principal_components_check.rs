// Principal components -- the same check as principal_components_check.py, in Rust.
// Standard library only, no crates.  500 simulated trading days of yield-curve
// changes at 10 tenors (3m 6m 1y 2y 3y 5y 7y 10y 20y 30y), in basis points,
// built from three hidden shapes plus noise.  PCA must find them.  Seed 2026.
const D: usize = 10; const N: usize = 500; const REPS: usize = 200;
const SDS: [f64; 3] = [3.0, 0.2, 0.15]; const NOISE: f64 = 0.5;
type Mat = Vec<Vec<f64>>;
struct Rng { s: u64 }                                        // SplitMix64
impl Rng {
    fn unif(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                            // Box-Muller, cosine half
        let u1 = self.unif(); let u2 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
fn add(xs: impl Iterator<Item = f64>) -> f64 { let mut s = 0.0; for x in xs { s += x; } s }
fn dot(a: &[f64], b: &[f64]) -> f64 { add(a.iter().zip(b).map(|(x, y)| x * y)) }
fn unit(v: &[f64]) -> Vec<f64> { let n = dot(v, v).sqrt(); v.iter().map(|x| x / n).collect() }
fn trace(m: &Mat) -> f64 { add((0..D).map(|i| m[i][i])) }
fn row(label: &str, vals: &[f64], dp: usize) {
    println!("{:<30}{}", label, vals.iter().map(|v| format!("{:8.*}", dp, v)).collect::<String>());
}
fn fix_sign(v: Vec<f64>) -> Vec<f64> { if v[D - 1] >= 0.0 { v } else { v.iter().map(|x| -x).collect() } }
fn shapes() -> [Vec<f64>; 3] {
    let s: Vec<f64> = (0..D).map(|j| 2.0 * j as f64 - 9.0).collect();
    [vec![1.0; D], s.clone(), s.iter().map(|x| (x * x - 33.0) / 8.0).collect()]
}
fn one_day(rng: &mut Rng, sh: &[Vec<f64>; 3]) -> Vec<f64> {   // three shape shocks, then noise
    let f: Vec<f64> = SDS.iter().map(|sd| rng.normal() * sd).collect();
    (0..D).map(|j| f[0] * sh[0][j] + f[1] * sh[1][j] + f[2] * sh[2][j] + NOISE * rng.normal()).collect()
}
fn simulate(rng: &mut Rng, sh: &[Vec<f64>; 3], n: usize) -> Mat { (0..n).map(|_| one_day(rng, sh)).collect() }
fn covariance(days: &Mat, centre: bool) -> (Vec<f64>, Mat) {  // divide by n - 1
    let n = days.len() as f64; let mut mean = vec![0.0; D];
    for x in days { for j in 0..D { mean[j] += x[j] / n; } }
    let off = if centre { mean.clone() } else { vec![0.0; D] };
    let mut c = vec![vec![0.0; D]; D];
    for x in days {
        let y: Vec<f64> = (0..D).map(|j| x[j] - off[j]).collect();
        for i in 0..D { for j in 0..D { c[i][j] += y[i] * y[j]; } }
    }
    (mean, c.iter().map(|r| r.iter().map(|v| v / (n - 1.0)).collect()).collect())
}
fn jacobi(m: &Mat) -> (Vec<f64>, Vec<Vec<f64>>) {           // road 1: rotate until diagonal
    let mut a = m.clone();
    let mut v: Mat = (0..D).map(|i| (0..D).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    for _ in 0..60 {
        let off = add((0..D).flat_map(|i| (0..D).map(move |j| (i, j))).filter(|&(i, j)| i != j).map(|(i, j)| a[i][j] * a[i][j]));
        if off < 1e-24 { break; }
        for p in 0..D {
            for q in p + 1..D {
                if a[p][q] == 0.0 { continue; }
                let th = (a[q][q] - a[p][p]) / (2.0 * a[p][q]);
                let t = (if th >= 0.0 { 1.0 } else { -1.0 }) / (th.abs() + (th * th + 1.0).sqrt());
                let c = 1.0 / (t * t + 1.0).sqrt(); let s = t * c;
                for k in 0..D { let (x, y) = (a[k][p], a[k][q]); a[k][p] = c * x - s * y; a[k][q] = s * x + c * y; }
                for k in 0..D { let (x, y) = (a[p][k], a[q][k]); a[p][k] = c * x - s * y; a[q][k] = s * x + c * y; }
                for k in 0..D { let (x, y) = (v[k][p], v[k][q]); v[k][p] = c * x - s * y; v[k][q] = s * x + c * y; }
            }
        }
    }
    let mut order: Vec<usize> = (0..D).collect();
    order.sort_by(|&i, &j| a[j][j].partial_cmp(&a[i][i]).unwrap());
    (order.iter().map(|&k| a[k][k]).collect(), order.iter().map(|&k| fix_sign((0..D).map(|i| v[i][k]).collect())).collect())
}
fn power_top(m: &Mat, k: usize) -> Vec<(f64, Vec<f64>)> {  // road 2: multiply and deflate
    let mut a = m.clone(); let mut out = Vec::new();
    for _ in 0..k {
        let mut v: Vec<f64> = (0..D).map(|j| j as f64 + 1.0).collect();
        for _ in 0..1000 {
            let w: Vec<f64> = a.iter().map(|r| dot(r, &v)).collect();
            let nw = dot(&w, &w).sqrt(); v = w.iter().map(|x| x / nw).collect();
        }
        let av: Vec<f64> = a.iter().map(|r| dot(r, &v)).collect(); let lam = dot(&v, &av);
        for i in 0..D { for j in 0..D { a[i][j] -= lam * v[i] * v[j]; } }
        out.push((lam, fix_sign(v)));
    }
    out
}
fn main() {
    let sh = shapes();
    // ---- exact: the model's own covariance, and its eigenvalues by hand ----
    let sigma: Mat = (0..D).map(|i| (0..D).map(|j| (if i == j { NOISE * NOISE } else { 0.0 })
        + add((0..3).map(|k| SDS[k] * SDS[k] * sh[k][i] * sh[k][j]))).collect()).collect();
    let mut exact: Vec<f64> = (0..3).map(|k| SDS[k] * SDS[k] * dot(&sh[k], &sh[k]) + NOISE * NOISE).collect(); exact.push(NOISE * NOISE);
    let lam_sigma = jacobi(&sigma).0; row("exact, eigenvalues (bp^2)", &exact, 4);
    row("jacobi on the model, top four", &lam_sigma[..4], 4);
    let ts = trace(&sigma);
    row("exact, shares 1-3 and top two %", &[100.0 * exact[0] / ts, 100.0 * exact[1] / ts, 100.0 * exact[2] / ts, 100.0 * (exact[0] + exact[1]) / ts], 2);
    let parts: Vec<f64> = (0..3).map(|k| dot(&sh[k], &sh[k])).chain((0..3).map(|k| SDS[k] * SDS[k] * dot(&sh[k], &sh[k]))).collect();
    row("exact, length^2 and shape part", &parts, 2);
    println!("exact, total variance (trace)  {:.4}", ts);
    for k in 0..4 { assert!((lam_sigma[k] - exact[k]).abs() < 1e-9); }
    // ---- simulated: 200 samples of 500 days; the first is the card's sample ----
    let mut rng = Rng { s: 2026 }; let (mut lam1s, mut top2s) = (Vec::new(), Vec::new());
    let (mut days0, mut mean0, mut s0, mut lam0, mut vec0, mut vec1) = (vec![], vec![], vec![], vec![], vec![], vec![]);
    for rep in 0..REPS {
        let days = simulate(&mut rng, &sh, N); let (mean, s) = covariance(&days, true); let (lam, vec) = jacobi(&s);
        lam1s.push(lam[0]); top2s.push((lam[0] + lam[1]) / trace(&s));
        if rep == 0 { days0 = days; mean0 = mean; s0 = s; lam0 = lam; vec0 = vec; } else if rep == 1 { vec1 = vec; }
    }
    row("sample, variance by tenor", &(0..D).map(|j| s0[j][j]).collect::<Vec<_>>(), 2);
    row("sample, eigenvalues 1-10", &lam0, 3);
    let tot = trace(&s0); row("sample, share % (chart)", &lam0.iter().map(|l| 100.0 * l / tot).collect::<Vec<_>>(), 2);
    row("sample, cumulative %", &(0..D).map(|k| 100.0 * add(lam0[..k + 1].iter().copied()) / tot).collect::<Vec<_>>(), 2);
    let lsum = add(lam0.iter().copied()); println!("sample, trace {:.4} = eigenvalue sum {:.4}", tot, lsum);
    assert!((tot - lsum).abs() < 1e-9);
    let se: Vec<f64> = exact[..3].iter().map(|e| e * (2.0 / (N as f64 - 1.0)).sqrt()).collect(); row("sample vs exact, formula SE", &se, 3);
    row("sample vs exact, gap in SEs", &(0..3).map(|k| (lam0[k] - exact[k]) / se[k]).collect::<Vec<_>>(), 2);
    for k in 0..3 { assert!((lam0[k] - exact[k]).abs() < 4.0 * se[k]); }
    let r = REPS as f64;
    let m1 = add(lam1s.iter().copied()) / r; let sd1 = (add(lam1s.iter().map(|x| (x - m1) * (x - m1))) / (r - 1.0)).sqrt();
    let m2 = add(top2s.iter().copied()) / r; let sd2 = (add(top2s.iter().map(|x| (x - m2) * (x - m2))) / (r - 1.0)).sqrt();
    println!("replicates, lambda1 mean {:.3}  sd {:.3}  formula SE {:.3}", m1, sd1, se[0]);
    println!("replicates, top-two share mean {:.3}%  sd {:.3}%", 100.0 * m2, 100.0 * sd2);
    assert!((sd1 / se[0] - 1.0).abs() < 0.15);
    // ---- the directions: loadings, bp moves, and agreement with the hidden shapes ----
    for k in 0..3 { row(&format!("loadings, PC{}", k + 1), &vec0[k], 3); }
    for k in 0..3 { row(&format!("chart, PC{} one-SD day (bp)", k + 1), &vec0[k].iter().map(|x| lam0[k].sqrt() * x).collect::<Vec<_>>(), 2); }
    let cos: Vec<f64> = (0..3).map(|k| dot(&vec0[k], &unit(&sh[k])).abs()).collect();
    row("cosine with hidden shape 1-3", &cos, 4);
    assert!(cos.iter().all(|&c| c > 0.98));
    let pw = power_top(&s0, 2);
    println!("power iteration, top two {:.6} {:.6}", pw[0].0, pw[1].0);
    let mut gap: f64 = 0.0;
    for k in 0..2 { for j in 0..D { gap = gap.max((pw[k].1[j] - vec0[k][j]).abs()); } }
    println!("power vs jacobi, largest loading gap below 1e-9: {}", if gap < 1e-9 { "yes" } else { "no" });
    for k in 0..2 { assert!((pw[k].0 - lam0[k]).abs() < 1e-8); }
    assert!(gap < 1e-9);
    // ---- reduce 10 numbers a day to 2 scores, and rebuild ----
    let ys: Mat = days0.iter().map(|x| (0..D).map(|j| x[j] - mean0[j]).collect()).collect();
    let z: Mat = ys.iter().map(|y| (0..2).map(|k| dot(&vec0[k], y)).collect()).collect();
    let nm = N as f64 - 1.0;
    let var1 = add(z.iter().map(|s| s[0] * s[0])) / nm; let cov12 = add(z.iter().map(|s| s[0] * s[1])) / nm;
    println!("scores, variance of PC1 scores {:.6}; PC1-PC2 covariance {:.6}", var1, cov12.abs());
    assert!((var1 - lam0[0]).abs() < 1e-8);
    let err = add(ys.iter().zip(&z).flat_map(|(y, s)| (0..D).map(|j| (y[j] - s[0] * vec0[0][j] - s[1] * vec0[1][j]).powi(2)).collect::<Vec<_>>())) / nm;
    let rest = add(lam0[2..].iter().copied());
    println!("reduce, rebuild error per day {:.6} vs eigenvalues 3-10 {:.6}", err, rest);
    assert!((err - rest).abs() < 1e-8);
    row("day 1, actual change (bp)", &days0[0], 2);
    println!("day 1, scores PC1 {:.2}  PC2 {:.2}", z[0][0], z[0][1]);
    row("day 1, rebuilt from 2 scores", &(0..D).map(|j| mean0[j] + z[0][0] * vec0[0][j] + z[0][1] * vec0[1][j]).collect::<Vec<_>>(), 2);
    let mut best: f64 = 0.0;
    for _ in 0..2000 {
        let u = unit(&(0..D).map(|_| rng.normal()).collect::<Vec<_>>());
        best = best.max(dot(&u, &s0.iter().map(|r| dot(r, &u)).collect::<Vec<_>>()));
    }
    println!("random directions, best of 2000 {:.3} vs lambda1 {:.3}", best, lam0[0]);
    assert!(best <= lam0[0]);
    // ---- what breaks ----
    let pct: Mat = days0.iter().map(|x| { let mut y = x.clone(); y[D - 1] /= 100.0; y }).collect();
    let sp = covariance(&pct, true).1; let (lp, vp) = jacobi(&sp);
    println!("breaks, 30y in percent: top-two share {:.2}%, PC1 30y loading {:.4}", 100.0 * (lp[0] + lp[1]) / trace(&sp), vp[0][D - 1]);
    let mut level: Vec<f64> = sh[1].iter().map(|s| 400.0 + 5.0 * s).collect(); let mut lev: Mat = Vec::new();
    for x in &days0 { level = (0..D).map(|j| level[j] + x[j]).collect(); lev.push(level.clone()); }
    let (avg, mu) = covariance(&lev, false); let (lu, vu) = jacobi(&mu);
    println!("breaks, levels uncentred: PC1 share {:.3}%, cosine with average curve {:.4}", 100.0 * lu[0] / trace(&mu), dot(&vu[0], &unit(&avg)).abs());
    row("breaks, sample 1 vs 2: cosine PC1-5", &(0..5).map(|k| dot(&vec0[k], &vec1[k]).abs()).collect::<Vec<_>>(), 4);
    println!("ALL CHECKS PASS");
}
