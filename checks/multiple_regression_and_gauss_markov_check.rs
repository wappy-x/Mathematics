// Multiple regression and Gauss-Markov -- the same check as the Python, in Rust.  No
// crates: solver, Gram-Schmidt residuals and random numbers are written out here.  Twelve
// sales: price ($ thousand) from floor area (m2), age (years), distance to station (km).
const N: usize = 12; const P: usize = 4;
type Mat = Vec<Vec<f64>>;
fn dot(u: &[f64], v: &[f64]) -> f64 {           // plain running sum, same order as the Python
    let mut s = 0.0;
    for (a, b) in u.iter().zip(v) { s += a * b; } s
}
fn solve(m: &Mat, rhs: &[f64]) -> Vec<f64> {    // Gaussian elimination with partial pivoting
    let k_max = m.len();
    let mut a: Mat = m.iter().zip(rhs).map(|(r, &b)| { let mut v = r.clone(); v.push(b); v }).collect();
    for k in 0..k_max {
        let mut piv = k;
        for i in k + 1..k_max { if a[i][k].abs() > a[piv][k].abs() { piv = i; } }
        a.swap(k, piv);
        for i in k + 1..k_max {
            let f = a[i][k] / a[k][k];
            for j in k..=k_max { a[i][j] -= f * a[k][j]; }
        }
    }
    let mut x = vec![0.0; k_max];
    for k in (0..k_max).rev() {                  // back substitution
        x[k] = (a[k][k_max] - dot(&a[k][k + 1..k_max], &x[k + 1..])) / a[k][k];
    }
    x
}
fn col(x: &Mat, i: usize) -> Vec<f64> { x.iter().map(|c| c[i]).collect() }
fn eye(j: usize, k: usize) -> f64 { if j == k { 1.0 } else { 0.0 } }
fn weights(cols: &Mat, wt: &[f64]) -> (Mat, Mat) {   // rows of (X^T W X)^-1 X^T W, W = diag(wt)
    let xw: Mat = cols.iter().map(|c| (0..N).map(|i| c[i] * wt[i]).collect()).collect();
    let xtwx: Mat = xw.iter().map(|a| cols.iter().map(|b| dot(a, b)).collect()).collect();
    let g: Mat = (0..P).map(|j| solve(&xtwx, &(0..P).map(|i| eye(i, j)).collect::<Vec<_>>())).collect();
    let h: Mat = (0..P).map(|j| (0..N).map(|i| dot(&g[j], &col(&xw, i))).collect()).collect();
    (h, g)
}
fn residual(v: &[f64], others: &[Vec<f64>]) -> Vec<f64> {  // v minus its shadow on the others
    let mut basis: Mat = Vec::new();
    let strip = |u: &[f64], basis: &Mat| {
        let mut w = u.to_vec();
        for q in basis { let c = dot(&w, q); w = w.iter().zip(q).map(|(a, b)| a - c * b).collect(); }
        w
    };
    for u in others {
        let w = strip(u, &basis);
        let size = dot(&w, &w).sqrt();
        basis.push(w.iter().map(|a| a / size).collect());
    }
    strip(v, &basis)
}
fn row(label: &str, v: &[f64], prec: usize) {
    println!("{:<36}{}", label, v.iter().map(|x| format!("{:>12.*}", prec, x)).collect::<String>());
}
fn spread(e: &[f64]) -> f64 { (dot(e, e) / (N - P) as f64).sqrt() }  // s: divide by n - p, not n
struct SplitMix(u64);                            // SplitMix64, seed 20260928
impl SplitMix {
    fn draw(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    let area = [62.0, 75.0, 80.0, 88.0, 95.0, 104.0, 110.0, 118.0, 125.0, 136.0, 148.0, 160.0];
    let age = [35.0, 12.0, 28.0, 5.0, 40.0, 18.0, 8.0, 30.0, 15.0, 22.0, 10.0, 3.0];
    let dist = [0.5, 1.8, 0.6, 1.4, 0.9, 2.6, 1.0, 1.5, 3.0, 2.2, 2.4, 3.6];
    let y = vec![124.0, 140.0, 172.0, 200.0, 180.0, 171.0, 260.0, 210.0, 226.0, 250.0, 301.0, 298.0];
    let x: Mat = vec![vec![1.0; N], area.to_vec(), age.to_vec(), dist.to_vec()];  // the columns of X
    // road 1: the normal equations X^T X b = X^T y, solved by elimination
    let xtx: Mat = x.iter().map(|a| x.iter().map(|b| dot(a, b)).collect()).collect();
    let beta = solve(&xtx, &x.iter().map(|a| dot(a, &y)).collect::<Vec<_>>());
    let (l, g) = weights(&x, &[1.0; N]);         // L = (X^T X)^-1 X^T, G = (X^T X)^-1
    let fit: Vec<f64> = (0..N).map(|i| dot(&col(&x, i), &beta)).collect();
    let res: Vec<f64> = y.iter().zip(&fit).map(|(a, b)| a - b).collect();
    let (rss, s_hat) = (dot(&res, &res), spread(&res));
    // road 2: partial out the other columns; each coefficient is then a one-column slope
    let rj: Mat = (0..P).map(|j| {
        let others: Mat = (0..P).filter(|&k| k != j).map(|k| x[k].clone()).collect();
        residual(&x[j], &others)
    }).collect();
    let beta2: Vec<f64> = rj.iter().map(|r| dot(r, &y) / dot(r, r)).collect();
    for j in 0..P { row(&format!("X^T X row {}   | X^T y {:.0}", j + 1, dot(&x[j], &y)), &xtx[j], 2); }
    println!("{:<36}{:>12}{:>12}{:>12}{:>12}", "", "intercept", "area", "age", "distance");
    row("road 1, normal equations", &beta, 6);
    row("road 2, partialling out", &beta2, 6);
    row("standard error, from (X^T X)^-1", &(0..P).map(|j| s_hat * g[j][j].sqrt()).collect::<Vec<_>>(), 6);
    row("standard error, from residual sizes", &rj.iter().map(|r| s_hat / dot(r, r).sqrt()).collect::<Vec<_>>(), 6);
    println!("residual sum of squares {:.4}; spread s = sqrt(RSS / {}) = {:.6}", rss, N - P, s_hat);
    let house = [1.0, 100.0, 20.0, 1.5];         // holding the others fixed, and leaving them out
    let ra = residual(&x[1], &x[..1]);
    let alone = dot(&ra, &y) / dot(&ra, &ra);
    println!("house 100 m2, 20 years, 1.5 km: {:.4}; at 110 m2: {:.4}; 10 m2 alone: {:.4}", dot(&house, &beta), dot(&house, &beta) + 10.0 * beta[1], 10.0 * alone);
    let drift = [dot(&ra, &x[2]) / dot(&ra, &ra), dot(&ra, &x[3]) / dot(&ra, &ra)];
    let rebuilt = beta[1] + beta[2] * drift[0] + beta[3] * drift[1];
    println!("area alone: slope {:.6}; age drift {:.6}, distance drift {:.6}", alone, drift[0], drift[1]);
    println!("area alone, rebuilt from the full fit: {:.6}", rebuilt);
    // Gauss-Markov: OLS weights L against A, the least-squares fit of the first 8 sales only
    let (a, _) = weights(&x, &(0..N).map(|i| if i < 8 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
    let mut miss: f64 = 0.0;
    for m in [&l, &a] { for j in 0..P { for k in 0..P { miss = miss.max((dot(&m[j], &x[k]) - eye(j, k)).abs()); } } }
    let d: Vec<f64> = a[1].iter().zip(&l[1]).map(|(p, q)| p - q).collect();
    let (ll, aa) = (dot(&l[1], &l[1]), dot(&a[1], &a[1]));
    println!("LX = I and AX = I to 1e-9: {}; (X^T X)^-1 area entry {:.9}", if miss < 1e-9 { "yes" } else { "no" }, g[1][1]);
    println!("area variance / sigma^2: OLS {:.9}, first 8 {:.9}, gap {:.9}, D D^T {:.9}, ratio {:.4}", ll, aa, aa - ll, dot(&d, &d), aa / ll);
    let mut rng = SplitMix(20260928);
    let hat: Mat = (0..N).map(|i| (0..N).map(|k| dot(&col(&x, i), &col(&l, k))).collect()).collect();  // H = X L
    let (mut excess, mut bias): (Vec<f64>, f64) = (Vec::new(), 0.0);
    for _ in 0..200 {                            // 200 random rivals L + M(I - H): unbiased by design
        let m: Mat = (0..P).map(|_| (0..N).map(|_| 0.02 * rng.draw() - 0.01).collect()).collect();
        let r: Mat = (0..P).map(|j| (0..N).map(|k| l[j][k] + m[j][k] - dot(&m[j], &col(&hat, k))).collect()).collect();
        for j in 0..P { for k in 0..P { bias = bias.max((dot(&r[j], &x[k]) - eye(j, k)).abs()); } }
        excess.push(dot(&r[1], &r[1]) - ll);
    }
    let (lo, hi) = excess.iter().fold((f64::INFINITY, f64::NEG_INFINITY), |(l, u), &e| (l.min(e), u.max(e)));
    println!("200 random rivals, all unbiased to 1e-9: {}; area-variance excess {:.9} to {:.9}", if bias < 1e-9 { "yes" } else { "no" }, lo, hi);
    let (sigma, reps) = (7.6, 20000usize);
    let (mut est, mut s2): (Mat, Vec<f64>) = (vec![Vec::new(), Vec::new()], Vec::new());
    for _ in 0..reps {                           // truth = the fit above; uniform noise, not normal
        let ys: Vec<f64> = fit.iter().map(|f| f + (2.0 * rng.draw() - 1.0) * sigma * 3.0f64.sqrt()).collect();
        est[0].push(dot(&l[1], &ys));
        est[1].push(dot(&a[1], &ys));
        s2.push(spread(&(0..N).map(|i| ys[i] - dot(&hat[i], &ys)).collect::<Vec<_>>()).powi(2));  // s^2 of this market
    }
    let (mut sim, mut bins) = (Vec::new(), vec![vec![0usize; 10]; 2]);  // mean and sd of each rule
    for (k, (lab, v)) in [("OLS", ll), ("first 8", aa)].iter().enumerate() {
        let mean = dot(&est[k], &vec![1.0; reps]) / reps as f64;
        let sd = (dot(&est[k], &est[k]) / reps as f64 - mean * mean).sqrt();
        sim.push((mean, sd, sigma * v.sqrt()));
        for b in 0..10 { bins[k][b] = est[k].iter().filter(|&&e| ((e - 1.8) / 0.1).floor() == b as f64).count(); }
        println!("simulated {:<8} mean {:.6} +/- {:.6}, sd {:.6}, exact sd {:.6}", lab, mean, sd / (reps as f64).sqrt(), sd, sigma * v.sqrt());
    }
    let v2 = dot(&s2, &vec![1.0; reps]) / reps as f64;
    let e2 = (dot(&s2, &s2) / reps as f64 - v2 * v2).sqrt() / (reps as f64).sqrt();
    println!("simulated s^2 mean {:.4} +/- {:.4}; sigma^2 {:.4}", v2, e2, sigma * sigma);
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, bin centres {}", join((0..10).map(|b| format!("{:.2}", 1.85 + 0.1 * b as f64)).collect()));
    println!("chart, OLS counts {}", join(bins[0].iter().map(|c| c.to_string()).collect()));
    println!("chart, first 8 counts {}", join(bins[1].iter().map(|c| c.to_string()).collect()));
    let sp2: Vec<f64> = dist.iter().map(|d| (4.0 * d) * (4.0 * d)).collect();  // what breaks: spread 4 x distance
    let (w, gw) = weights(&x, &sp2.iter().map(|s| 1.0 / s).collect::<Vec<_>>());
    let sq = |r: &[f64]| r.iter().map(|v| v * v).collect::<Vec<_>>();
    let (ols_var, gls_var) = (dot(&sq(&l[1]), &sp2), dot(&sq(&w[1]), &sp2));
    println!("unequal spreads, area sd: OLS {:.6}, weighted {:.6}, from inverse {:.6}", ols_var.sqrt(), gls_var.sqrt(), gw[1][1].sqrt());
    let rw = residual(&dist.iter().map(|d| 12.0 * d).collect::<Vec<_>>(), &x);
    println!("walking minutes = 12 x km: length left after the other columns {:.6}", dot(&rw, &rw).sqrt());
    let px = |a: f64| 50.0 + (a - 60.0) * 2.9;    // figure: area 60..160 -> x 50..340
    let py = |v: f64| 200.0 - (v - 100.0) * 0.8;  // price 100..320 -> y 200..24
    println!("figure, points {}", join((0..N).map(|i| format!("{:.1},{:.1}", px(area[i]), py(y[i]))).collect()));
    let (ma, my) = (dot(&x[0], &x[1]) / N as f64, dot(&x[0], &y) / N as f64);
    let held = beta[0] + beta[2] * dot(&x[0], &x[2]) / N as f64 + beta[3] * dot(&x[0], &x[3]) / N as f64;
    println!("figure, area alone {:.1} to {:.1}; held fixed {:.1} to {:.1}; centre {:.1},{:.1}",
             py(my + (60.0 - ma) * alone), py(my + (160.0 - ma) * alone),
             py(held + 60.0 * beta[1]), py(held + 160.0 * beta[1]), px(ma), py(my));
    assert!(beta.iter().zip(&beta2).all(|(p, q)| (p - q).abs() < 1e-9));  // two roads, one fit
    assert!((alone - rebuilt).abs() < 1e-9);                              // the left-out-column identity
    assert!((ll - g[1][1]).abs() < 1e-12);                                // L L^T = (X^T X)^-1
    assert!(((aa - ll) - dot(&d, &d)).abs() < 1e-12);                     // cross terms vanish
    assert!(miss < 1e-9 && bias < 1e-9);                                 // L and every rival unbiased
    assert!(lo > 0.0);                                                    // every rival loses
    for &(mean, sd, exact) in &sim {                                      // simulation within 4 SE
        assert!((mean - beta[1]).abs() < 4.0 * sd / (reps as f64).sqrt());         // unbiased
        assert!((sd - exact).abs() < 4.0 * exact / (2.0 * reps as f64).sqrt());   // spread as the formula says
    }
    assert!((v2 - sigma * sigma).abs() < 4.0 * e2);                      // s^2 right on average
    assert!((gls_var - gw[1][1]).abs() < 1e-12);                          // two roads, weighted sd
    assert!(gls_var < ols_var);                                           // the theorem fails here
    println!("ALL CHECKS PASS");
}
