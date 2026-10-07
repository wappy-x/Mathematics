// Ridge and lasso -- the same check as the Python, in Rust; std only.
// A used-car dealer prices cars from 20 intake measurements that move together
// (every pair correlated 0.8).  Truth: price = 15 + 4 x1 + 3 x2 + 2 x3, in
// $ thousand, plus noise of SD 3.  40 cars to fit, 100 more to validate.
const P: usize = 20; const N: usize = 40; const NV: usize = 100; const R: usize = 2000;
const RHO: f64 = 0.8; const SIG: f64 = 3.0; const A0: f64 = 15.0;
const LAMS: [f64; 10] = [0.0, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0];
type Mat = Vec<Vec<f64>>;

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 { // SplitMix64: a draw in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 * 2f64.powi(-53)
    }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine half only
        let u = self.uniform();
        (-2.0 * u.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.uniform()).cos()
    }
    fn car(&mut self) -> Vec<f64> { // 20 readings sharing one factor
        let f = self.normal();
        (0..P).map(|_| RHO.sqrt() * f + (1.0 - RHO).sqrt() * self.normal()).collect()
    }
    fn price(&mut self, x: &[f64]) -> f64 { A0 + dot(&BETA, x) + SIG * self.normal() }
}

const BETA: [f64; P] = [4.0, 3.0, 2.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];

fn dot(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| a * b).sum() }

fn solve(a: &Mat, b: &[f64]) -> Vec<f64> { // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: Mat = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for k in 0..n {
        let mut p = k;
        for r in k + 1..n { if m[r][k].abs() > m[p][k].abs() { p = r; } }
        m.swap(k, p);
        for r in k + 1..n { let f = m[r][k] / m[k][k]; for c in k..=n { let t = f * m[k][c]; m[r][c] -= t; } }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (m[i][n] - (i + 1..n).map(|c| m[i][c] * x[c]).sum::<f64>()) / m[i][i]; }
    x
}

fn ridge(g: &Mat, c: &[f64], lam: f64) -> Vec<f64> { // road 1: solve (G + lam I) b = c
    let a: Mat = (0..c.len()).map(|i| (0..c.len()).map(|j| g[i][j] + if i == j { lam } else { 0.0 }).collect()).collect();
    solve(&a, c)
}

fn descent(g: &Mat, c: &[f64], lam: f64, lasso: bool, sweeps: usize) -> Vec<f64> { // road 2
    let (p, mut b) = (c.len(), vec![0.0; c.len()]);
    for _ in 0..sweeps { for j in 0..p {
        let r = c[j] - (0..p).filter(|&k| k != j).map(|k| g[j][k] * b[k]).sum::<f64>();
        b[j] = if lasso { (r.abs() - lam / 2.0).max(0.0).copysign(r) / g[j][j] + 0.0 } else { r / (g[j][j] + lam) };
    } }
    b
}

fn snorm(v: &[f64]) -> f64 { (1.0 - RHO) * dot(v, v) + RHO * v.iter().sum::<f64>().powi(2) } // v' Sigma v

fn risk(g: &Mat, lam: f64) -> (f64, f64) { // exact bias^2 and variance, fixed design
    let ai: Mat = (0..P).map(|k| ridge(g, &(0..P).map(|i| if i == k { 1.0 } else { 0.0 }).collect::<Vec<_>>(), lam)).collect();
    let bias: Vec<f64> = (0..P).map(|i| -lam * dot(&ai[i], &BETA)).collect();
    let ag: Mat = (0..P).map(|i| (0..P).map(|j| (0..P).map(|m| ai[i][m] * g[m][j]).sum()).collect()).collect();
    let c: Mat = (0..P).map(|i| (0..P).map(|j| (0..P).map(|m| ag[i][m] * ai[m][j]).sum()).collect()).collect();
    let (tr, all) = ((0..P).map(|i| c[i][i]).sum::<f64>(), c.iter().map(|r| r.iter().sum::<f64>()).sum::<f64>());
    (snorm(&bias), SIG * SIG * ((1.0 - RHO) * tr + RHO * all))
}

fn fit(xc: &Mat, g: &Mat, mx: &[f64], y: &[f64], lam: f64, lasso: bool) -> (f64, Vec<f64>) {
    let c: Vec<f64> = xc.iter().map(|col| dot(col, y)).collect(); // centred fit, free intercept
    let b = if lasso { descent(g, &c, lam, true, 3000) } else { ridge(g, &c, lam) };
    (y.iter().sum::<f64>() / N as f64 - dot(mx, &b), b)
}

fn errs(xs: &Mat, ys: &[f64], a: f64, b: &[f64]) -> Vec<f64> { xs.iter().zip(ys).map(|(x, yy)| (yy - a - dot(x, b)).powi(2)).collect() }
fn mean_se(e: &[f64]) -> (f64, f64) {
    let (n, m) = (e.len() as f64, e.iter().sum::<f64>() / e.len() as f64);
    (m, (e.iter().map(|t| (t - m).powi(2)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn gap(b: &[f64]) -> Vec<f64> { BETA.iter().zip(b).map(|(u, v)| u - v).collect() }
fn truth(a: f64, b: &[f64]) -> f64 { SIG * SIG + (A0 - a).powi(2) + snorm(&gap(b)) } // exact error per new car
fn unit(v: Vec<f64>) -> Vec<f64> { let n = dot(&v, &v).sqrt(); v.iter().map(|t| t / n).collect() }
fn gram(xc: &Mat) -> Mat { (0..P).map(|i| (0..P).map(|j| dot(&xc[i], &xc[j])).collect()).collect() }
fn row(v: &[f64], w: usize) -> String { v.iter().map(|t| format!("{:w$.2}", t, w = w)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mut rng = Rng(20260928);
    let x: Mat = (0..N).map(|_| rng.car()).collect();
    let y: Vec<f64> = x.iter().map(|r| rng.price(r)).collect();
    let xv: Mat = (0..NV).map(|_| rng.car()).collect();
    let yv: Vec<f64> = xv.iter().map(|r| rng.price(r)).collect();
    let mut mx: Vec<f64> = (0..P).map(|j| x.iter().map(|r| r[j]).sum::<f64>() / N as f64).collect();
    let mut xc: Mat = (0..P).map(|j| (0..N).map(|k| x[k][j] - mx[j]).collect()).collect();
    let mut g = gram(&xc);
    let (mut v, mut w) = (vec![1.0; P], (0..P).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect::<Vec<f64>>());
    for _ in 0..300 { v = unit(g.iter().map(|r| dot(r, &v)).collect()); w = unit(solve(&g, &w)); }
    let quad = |u: &Vec<f64>| dot(u, &g.iter().map(|r| dot(r, u)).collect::<Vec<_>>());
    let (dmax, dmin) = (quad(&v), quad(&w));
    println!("lambda  bias^2  variance  risk | ridge: val   true | lasso: val   true  kept");
    let mut rows: Vec<(f64, f64, f64, f64, f64, Vec<f64>, f64, Vec<f64>)> = Vec::new();
    for &lam in LAMS.iter() {
        let (b2, var) = risk(&g, lam);
        let (ar, br) = fit(&xc, &g, &mx, &y, lam, false);
        let (al, bl) = fit(&xc, &g, &mx, &y, lam, true);
        let (vr, vl) = (mean_se(&errs(&xv, &yv, ar, &br)).0, mean_se(&errs(&xv, &yv, al, &bl)).0);
        println!("{:>6} {:7.2} {:9.2} {:5.2} | {:11.2} {:6.2} | {:11.2} {:6.2} {:5}", lam, b2, var, b2 + var,
                 vr, truth(ar, &br), vl, truth(al, &bl), bl.iter().filter(|&&t| t != 0.0).count());
        rows.push((lam, b2 + var, vr, vl, ar, br, al, bl));
    }
    let (pr, pl, ols) = (rows.iter().min_by(|a, b| a.2.partial_cmp(&b.2).unwrap()).unwrap().clone(),
                         rows.iter().min_by(|a, b| a.3.partial_cmp(&b.3).unwrap()).unwrap().clone(), rows[0].clone());
    println!("G's strongest direction {:.1}, weakest {:.2}; slope variance along the weakest: OLS {:.2}, ridge {:.2}",
             dmax, dmin, SIG * SIG / dmin, SIG * SIG * dmin / (dmin + pr.0).powi(2));
    println!("ridge picked lambda {}: validation {:.2} +- {:.2}", pr.0, pr.2, mean_se(&errs(&xv, &yv, pr.4, &pr.5)).1);
    println!("lasso picked lambda {}: validation {:.2} +- {:.2}", pl.0, pl.3, mean_se(&errs(&xv, &yv, pl.6, &pl.7)).1);
    println!("true error per new car: OLS {:.2}, ridge {:.2}, lasso {:.2}, floor {:.2}",
             truth(ols.4, &ols.5), truth(pr.4, &pr.5), truth(pl.6, &pl.7), SIG * SIG);
    let xn: Mat = (0..20000).map(|_| rng.car()).collect();
    let yn: Vec<f64> = xn.iter().map(|r| rng.price(r)).collect(); let sim = mean_se(&errs(&xn, &yn, pr.4, &pr.5));
    println!("ridge pick on 20000 fresh cars: {:.2} +- {:.2}", sim.0, sim.1);
    for (name, b) in [("OLS  ", &ols.5), ("ridge", &pr.5), ("lasso", &pl.7)] {
        println!("{} b1..b6: {} | sum of all 20: {:.2}", name, row(&b[..6], 6), b.iter().sum::<f64>());
    }
    let kept: Vec<String> = pl.7.iter().enumerate().filter(|(_, &t)| t != 0.0).map(|(j, t)| format!("x{} {:.2}", j + 1, t)).collect();
    println!("lasso keeps: {}", kept.join(", "));
    let kkt = (0..P).map(|j| { let (r, t) = (dot(&xc[j], &y) - dot(&g[j], &pl.7), pl.7[j]);
        if t != 0.0 { (r - (pl.0 / 2.0).copysign(t)).abs() } else { (r.abs() - pl.0 / 2.0).max(0.0) } }).fold(0.0, f64::max);
    println!("lasso optimality conditions, worst violation: {:.9}", kkt);
    let cd = descent(&g, &xc.iter().map(|col| dot(col, &y)).collect::<Vec<_>>(), pr.0, false, 3000);
    let cd_gap = pr.5.iter().zip(&cd).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("ridge by elimination vs by descent, largest gap: {:.9}", cd_gap);
    let mut sims = Vec::new();
    for (lam, exact) in [(0.0, ols.1), (pr.0, pr.1)] {
        let e: Vec<f64> = (0..R).map(|_| { let ys: Vec<f64> = x.iter().map(|r| rng.price(r)).collect();
            snorm(&gap(&fit(&xc, &g, &mx, &ys, lam, false).1)) }).collect();
        let s = mean_se(&e);
        println!("risk at lambda {}: exact {:.2}, {} redrawn noises {:.2} +- {:.2}", lam, exact, R, s.0, s.1);
        sims.push((s, exact));
    }
    let tw: Mat = vec![vec![2.0, 2.0], vec![2.0, 2.0]];
    let (tw_r, tw_l) = (ridge(&tw, &[4.0, 4.0], 2.0), descent(&tw, &[4.0, 4.0], 2.0, true, 3000));
    let tw_cost = |b: &[f64]| 2.0 * (2.0 - b[0] - b[1]).powi(2) + 2.0 * (b[0].abs() + b[1].abs());
    println!("twins: ridge {:.4} {:.4}, fit error {:.4}, penalty {:.4}; lasso {:.4} {:.4}, cost {:.4}; split 0.75 0.75 costs {:.4}",
             tw_r[0], tw_r[1], 2.0 * (2.0 - tw_r[0] - tw_r[1]).powi(2), 2.0 * dot(&tw_r, &tw_r), tw_l[0], tw_l[1], tw_cost(&tw_l), tw_cost(&[0.75, 0.75]));
    let zs: Vec<f64> = (0..7).map(|k| 0.5 * k as f64).collect();
    let sr: Vec<f64> = zs.iter().map(|z| ridge(&vec![vec![40.0]], &[40.0 * z], 40.0)[0]).collect();
    let sl: Vec<f64> = zs.iter().map(|z| descent(&vec![vec![40.0]], &[40.0 * z], 40.0, true, 5)[0]).collect();
    println!("chart, OLS slope  {}", row(&zs, 5));
    println!("chart, ridge      {}", row(&sr, 5));
    println!("chart, lasso      {}", row(&sl, 5));
    let by_train = LAMS.iter().map(|&lam| { let (a, b) = fit(&xc, &g, &mx, &y, lam, false); (mean_se(&errs(&x, &y, a, &b)).0, lam) })
        .fold((f64::INFINITY, 0.0), |m, t| if t.0 < m.0 { t } else { m }).1;
    let zt: Mat = std::iter::once(vec![1.0; N]).chain((0..P).map(|j| x.iter().map(|r| r[j]).collect())).collect(); // raw columns plus ones
    let pen = ridge(&zt.iter().map(|u| zt.iter().map(|v| dot(u, v)).collect()).collect(), &zt.iter().map(|u| dot(u, &y)).collect::<Vec<_>>(), pr.0); // charge on a too
    xc[0] = xc[0].iter().map(|t| t * 0.1).collect(); g = gram(&xc); mx[0] *= 0.1;
    let (a_sc, mut b_sc) = fit(&xc, &g, &mx, &y, pr.0, false); b_sc[0] *= 0.1;
    println!("mistake, lambda by training error: picks {}, true error {:.2}", by_train, truth(ols.4, &ols.5));
    println!("mistake, penalised intercept: {:.2} not {:.2}, true error {:.2}", pen[0], pr.4, truth(pen[0], &pen[1..]));
    println!("mistake, x1 recorded divided by 10: b1 {:.2}, true error {:.2}", b_sc[0], truth(a_sc, &b_sc));
    assert!((sim.0 - truth(pr.4, &pr.5)).abs() < 4.0 * sim.1); // formula vs fresh cars
    let sp = mean_se(&errs(&xn, &yn, pen[0], &pen[1..])); assert!((sp.0 - truth(pen[0], &pen[1..])).abs() < 4.0 * sp.1); // intercept part
    assert!(sims.iter().all(|((m, se), exact)| (m - exact).abs() < 4.0 * se));
    assert!(kkt < 1e-6 && cd_gap < 1e-9); // lasso certified; two ridge roads
    assert!((tw_r[0] - 2.0 / 3.0).abs() < 1e-12 && (tw_l[0] + tw_l[1] - 1.5).abs() < 1e-12);
    assert!(zs.iter().zip(&sr).zip(&sl).all(|((z, a), b)| (a - z / 2.0).abs() < 1e-12 && (b - (z - 0.5).max(0.0)).abs() < 1e-12));
    println!("ALL CHECKS PASS");
}
