// ADMM on a split lasso: copy an index with few of five assets.  Standard library only.
// Minimise f(x) + g(z) = 1/2 |Ax - b|^2 + lam*|z|_1 subject to x = z.  Returns in percent a month.
const N: usize = 5;
const A: [[f64; 5]; 8] = [[2., 3., -1., 1., 2.], [-1., 1., 2., 0., -2.], [3., 2., -2., 2., 1.], [1., -2., 1., -1., 3.],
    [-2., -1., 3., 1., -1.], [0., 2., 0., -2., 1.], [2., 0., -1., 3., 0.], [1., 1., 1., 0., 2.]]; // 8 months x 5 assets
const B: [f64; 8] = [1.8, 0.1, 1.6, 0.3, -0.6, 0.5, 0.9, 1.1]; // the index, same 8 months
const RHO: f64 = 3.0;
const EPS: f64 = 5e-7;

struct P { ata: Vec<Vec<f64>>, atb: Vec<f64>, lam: f64 }
type Round = (usize, Vec<f64>, Vec<f64>, Vec<f64>, f64, f64);

fn solve(m: &[Vec<f64>], v: &[f64]) -> Vec<f64> { // Gauss-Jordan elimination with row swaps
    let k = v.len();
    let mut m: Vec<Vec<f64>> = (0..k).map(|i| { let mut r = m[i].clone(); r.push(v[i]); r }).collect();
    for c in 0..k {
        let mut p = c;
        for r in c + 1..k { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in 0..k {
            if r != c {
                let f = m[r][c] / m[c][c];
                let pivot = m[c].clone();
                for j in 0..=k { m[r][j] = m[r][j] - f * pivot[j]; }
            }
        }
    }
    (0..k).map(|i| m[i][k] / m[i][i]).collect()
}
fn norm(v: &[f64]) -> f64 { v.iter().fold(0.0, |a, t| a + t * t).sqrt() }
fn soft(v: f64, t: f64) -> f64 { if v.abs() <= t { 0.0 } else if v > 0.0 { v - t } else { v + t } }
fn diff(a: &[f64], b: &[f64]) -> Vec<f64> { (0..a.len()).map(|i| a[i] - b[i]).collect() }
fn show(v: &[f64]) -> String { v.iter().map(|t| format!("{:9.6}", t)).collect::<Vec<_>>().join(" ") }
fn fitted(x: &[f64]) -> Vec<f64> { A.iter().map(|r| (0..N).fold(0.0, |a, j| a + r[j] * x[j])).collect() }
impl P {
    fn grad(&self, x: &[f64]) -> Vec<f64> {
        (0..N).map(|i| (0..N).fold(0.0, |a, j| a + self.ata[i][j] * x[j]) - self.atb[i]).collect()
    }
    fn cost(&self, x: &[f64]) -> f64 {
        let f = fitted(x);
        0.5 * (0..8).fold(0.0, |a, r| a + (f[r] - B[r]).powi(2)) + self.lam * x.iter().fold(0.0, |a, t| a + t.abs())
    }
    fn admm(&self, rho: f64, rounds: usize, shrink: Option<f64>, dual: bool) -> Vec<Round> {
        let m: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| self.ata[i][j] + if i == j { rho } else { 0.0 }).collect()).collect();
        let (mut z, mut u, mut hist) = (vec![0.0; N], vec![0.0; N], Vec::new());
        for k in 1..=rounds {
            let rhs: Vec<f64> = (0..N).map(|i| self.atb[i] + rho * (z[i] - u[i])).collect();
            let x = solve(&m, &rhs); // fit half
            let t = shrink.unwrap_or(self.lam / rho);
            let z_new: Vec<f64> = (0..N).map(|i| soft(x[i] + u[i], t)).collect(); // penalty half
            if dual { u = (0..N).map(|i| u[i] + x[i] - z_new[i]).collect(); } // reconcile
            let r = norm(&diff(&x, &z_new));
            let s = rho * norm(&diff(&z_new, &z));
            z = z_new;
            hist.push((k, x, z.clone(), u.clone(), r, s));
            if r < EPS && s < EPS { break; }
        }
        hist
    }
}

fn main() {
    let ata: Vec<Vec<f64>> = (0..N).map(|i| (0..N).map(|j| A.iter().fold(0.0, |a, r| a + r[i] * r[j])).collect()).collect();
    let atb: Vec<f64> = (0..N).map(|i| (0..8).fold(0.0, |a, r| a + A[r][i] * B[r])).collect();
    let mut p = P { ata, atb, lam: 2.0 };
    // Road 1: ADMM from x = z = u = 0
    let hist = p.admm(RHO, 1000, None, true);
    let (kk, xk, z, _, _, _) = hist.last().unwrap().clone();
    // Road 2: every sign pattern (+, -, 0 for each asset); keep the one that passes the lasso's test
    let mut found: Vec<Vec<f64>> = Vec::new();
    for code in 0..243usize {
        let mut c = code;
        let mut sg = [0i32; N];
        for i in (0..N).rev() { sg[i] = [1, -1, 0][c % 3]; c /= 3; }
        let s: Vec<usize> = (0..N).filter(|&i| sg[i] != 0).collect();
        let mut w = vec![0.0; N];
        if !s.is_empty() {
            let m: Vec<Vec<f64>> = s.iter().map(|&i| s.iter().map(|&j| p.ata[i][j]).collect()).collect();
            let rhs: Vec<f64> = s.iter().map(|&i| p.atb[i] - p.lam * sg[i] as f64).collect();
            for (&i, t) in s.iter().zip(solve(&m, &rhs)) { w[i] = t; }
        }
        let g = p.grad(&w);
        if s.iter().all(|&i| w[i] * sg[i] as f64 > 0.0) && (0..N).all(|i| sg[i] != 0 || g[i].abs() <= p.lam + 1e-12) { found.push(w); }
    }
    assert!(found.len() == 1);
    let xs = found[0].clone();
    // Road 3: the certificate.  -grad f(z) must equal lam*sign on holdings and lie in [-lam, lam] elsewhere
    let gz = p.grad(&z);
    let ystar: Vec<f64> = p.grad(&xs).iter().map(|t| -t).collect();
    assert!((0..N).all(|i| z[i] == 0.0 || (gz[i] + p.lam * z[i].signum()).abs() < 1e-5));
    assert!((0..N).all(|i| z[i] != 0.0 || gz[i].abs() < p.lam));
    assert!(diff(&z, &xs).iter().all(|t| t.abs() < 1e-6) && kk == 60);
    // Road 4: the convergence proof's yardstick V falls every round by at least rho(|r|^2 + |dz|^2)
    let v = |zz: &[f64], uu: &[f64]| (0..N).fold(0.0, |a, i| a + (RHO * uu[i] - ystar[i]).powi(2)) / RHO
        + RHO * (0..N).fold(0.0, |a, i| a + (zz[i] - xs[i]).powi(2));
    let (mut pz, mut pu, mut worst) = (vec![0.0; N], vec![0.0; N], f64::INFINITY);
    for (_, _, zk, uk, rk, sk) in &hist {
        let drop = v(&pz, &pu) - v(zk, uk);
        let need = RHO * rk * rk + sk * sk / RHO;
        assert!(drop >= need - 1e-12);
        if need > 1e-20 { worst = worst.min(drop / need); }
        pz = zk.clone(); pu = uk.clone();
    }

    println!("A^T A rows:");
    for row in &p.ata { println!("   {}", show(row)); }
    println!("A^T b       {}", show(&p.atb));
    println!("round 1 x   {}  shrink lam/rho = {:.4}", show(&hist[0].1), p.lam / RHO);
    println!("round 60 x  {}", xk.iter().map(|t| format!("{:.9}", t)).collect::<Vec<_>>().join(" "));
    println!("rounds, k: z_UK z_US z_prop |r| |s|");
    for (k, _, zk, _, rk, sk) in &hist {
        if [1, 2, 3, 5, 10, 20, 40, 59, 60].contains(k) {
            println!("  {:3} {:.6} {:.6} {:.6} {:.9} {:.9}", k, zk[0], zk[1], zk[4], rk, sk);
        }
    }
    println!("ADMM z      {}", show(&z));
    println!("enumerated  {}", show(&xs));
    println!("-grad f(z)  {}   (lam = 2)", gz.iter().map(|t| format!("{:.5}", -t)).collect::<Vec<_>>().join(" "));
    let pen = p.lam * xs.iter().fold(0.0, |a, t| a + t.abs());
    println!("lasso cost at z {:.6}, at enumerated {:.6} = fit {:.6} + penalty {:.6}", p.cost(&z), p.cost(&xs), p.cost(&xs) - pen, pen);
    println!("least squares {}", show(&solve(&p.ata, &p.atb)));
    let fit = fitted(&xs);
    let gap = ((0..8).fold(0.0, |a, r| a + (fit[r] - B[r]).powi(2)) / 8.0).sqrt();
    println!("copy's returns {}  rms gap {:.4}", fit.iter().map(|t| format!("{:.4}", t)).collect::<Vec<_>>().join(" "), gap);
    let total = xs.iter().fold(0.0, |a, t| a + t);
    println!("per 1000000 pounds: UK shares {:.0}, US shares {:.0}, property {:.0}, cash {:.0}",
        xs[0] * 1e6, xs[1] * 1e6, xs[4] * 1e6, (1.0 - total) * 1e6);
    println!("V falls every round; smallest drop / proof's floor = {:.4}", worst);
    println!("chart, k: log10|r|, log10|s|, log10|z - z*|");
    for (k, _, zk, _, rk, sk) in &hist {
        if k % 5 == 0 {
            println!("  {:3} {:7.3} {:7.3} {:7.3}", k, rk.log10(), sk.log10(), norm(&diff(zk, &xs)).log10());
        }
    }
    let counts: Vec<String> = [0.5, 1.0, 3.0, 10.0, 30.0, 100.0].iter().map(|&rho| p.admm(rho, 1000, None, true).last().unwrap().0.to_string()).collect();
    println!("rounds to stop at rho 0.5, 1, 3, 10, 30, 100: {}", counts.join(" "));
    // What breaks
    let nd = p.admm(RHO, 2000, None, false).last().unwrap().clone();
    println!("no dual update, after {} rounds: x {}, z {}, |x - z| {:.6}", nd.0, show(&nd.1), show(&nd.2), nd.4);
    assert!(nd.4 > 0.01);
    let ws = p.admm(RHO, 1000, Some(p.lam), true).last().unwrap().clone();
    println!("shrink by lam not lam/rho: z {}, the lasso at weight rho*lam = {:.1}", show(&ws.2), RHO * p.lam);
    assert!((ws.2[1] - xs[1]).abs() > 0.05);
    // Three blocks: minimise 0 subject to B1 v1 + B2 v2 + B3 v3 = 0, sweeping one block at a time
    let bm = [[1.0, 1.0, 1.0], [1.0, 1.0, 2.0], [1.0, 2.0, 2.0]];
    let (mut vv, mut y) = ([1.0f64; 3], [0.0f64; 3]);
    println!("three blocks, round   0: |v| = {:.4}", norm(&vv));
    for k in 1..=200 {
        for j in 0..3 {
            let rest: Vec<f64> = (0..3).map(|i| (0..3).filter(|&m| m != j).fold(0.0, |a, m| a + bm[i][m] * vv[m]) + y[i]).collect();
            vv[j] = -(0..3).fold(0.0, |a, i| a + bm[i][j] * rest[i]) / (0..3).fold(0.0, |a, i| a + bm[i][j] * bm[i][j]);
        }
        for i in 0..3 { y[i] = y[i] + (0..3).fold(0.0, |a, m| a + bm[i][m] * vv[m]); }
        if [1, 50, 100, 200].contains(&k) { println!("three blocks, round {:3}: |v| = {:.4}", k, norm(&vv)); }
    }
    assert!(norm(&vv) > 10.0);
    for lam in [1.0, 4.0] {
        p.lam = lam;
        println!("try lam {:.1}: z {}", lam, show(&p.admm(RHO, 1000, None, true).last().unwrap().2));
    }
    println!("ALL CHECKS PASS");
}
