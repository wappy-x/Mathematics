// Lanczos and Rayleigh-Ritz -- the check behind the card.  Rust std only.
// Road one: diag(1, 2, 3) by hand, by Sturm bisection and by a direct Rayleigh-Ritz.
// Road two: the 1,000-cell bar matrix L = tridiag(-1, 2, -1) against its known
// eigenvalues 4 sin^2(j pi / 2002).  Road three: shift-invert, with and without
// full reorthogonalisation, against the Kaniel-Paige bound and recomputed residuals.
use std::f64::consts::PI;

fn nxt(st: &mut u64) -> u64 { // SplitMix64, written out
    *st = st.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*st ^ (*st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn unif(st: &mut u64) -> f64 { (nxt(st) >> 11) as f64 / 9007199254740992.0 }
fn sci(v: f64) -> String { format!("{:.3e}", v) }
fn commas(v: usize) -> String {
    let (d, mut out) = (v.to_string(), String::new());
    for (i, ch) in d.chars().enumerate() { if i > 0 && (d.len() - i) % 3 == 0 { out.push(','); } out.push(ch); } out
}
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut acc = 0.0; for (a, b) in u.iter().zip(v) { acc += a * b; } acc }
type Run = (Vec<f64>, Vec<f64>, Vec<Vec<f64>>);
fn lanczos(op: &dyn Fn(&[f64]) -> Vec<f64>, b: &[f64], m: usize, full: bool) -> Run {
    let nb = dot(b, b).sqrt(); // alphas, betas, Lanczos vectors
    let mut q: Vec<Vec<f64>> = vec![b.iter().map(|v| v / nb).collect()];
    let (mut al, mut be): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    for k in 0..m {
        let mut w = op(&q[k]); let a = dot(&w, &q[k]); al.push(a);
        let km = if k > 0 { k - 1 } else { q.len() - 1 };
        w = (0..w.len()).map(|i| w[i] - a * q[k][i] - (if k > 0 { be[k - 1] * q[km][i] } else { 0.0 })).collect();
        if full { // full reorthogonalisation
            for v in &q { let h = dot(&w, v); w = w.iter().zip(v).map(|(x, y)| x - h * y).collect(); }
        }
        be.push(dot(&w, &w).sqrt());
        if k < m - 1 { let bk = be[k]; q.push(w.iter().map(|v| v / bk).collect()); }
    }
    (al, be, q)
}
fn below(al: &[f64], be: &[f64], x: f64) -> usize { // Sturm count: eigenvalues of T_k below x
    let (mut c, mut d) = (0, 1.0);
    for i in 0..al.len() {
        d = al[i] - x - (if i > 0 { be[i - 1] * be[i - 1] / d } else { 0.0 });
        if d == 0.0 { d = 1e-300; } if d < 0.0 { c += 1; }
    }
    c
}
fn ritz(al: &[f64], be: &[f64], j: usize, mut lo: f64, mut hi: f64) -> f64 { // j-th smallest, bisection
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if below(al, be, mid) > j { hi = mid; } else { lo = mid; } }
    0.5 * (lo + hi)
}
fn ritzvec(al: &[f64], be: &[f64], th: f64) -> Vec<f64> { // Ritz vector of T_k: two inverse
    let k = al.len(); let mut s = vec![1.0; k];               // steps on (th + d) I - T
    for _ in 0..2 {
        let (mut c, mut g) = (vec![0.0; k], vec![0.0; k]);
        for i in 0..k {
            let m = th * (1.0 + 1e-13) - al[i] + (if i > 0 { be[i - 1] * c[i - 1] } else { 0.0 });
            c[i] = -be[i] / m; g[i] = (s[i] + (if i > 0 { be[i - 1] * g[i - 1] } else { 0.0 })) / m;
        }
        for i in (0..k - 1).rev() { g[i] -= c[i] * g[i + 1]; }
        let ns = dot(&g, &g).sqrt(); s = g.iter().map(|v| v / ns).collect();
    }
    s
}
fn cheb(x: f64, k: usize) -> f64 { let (mut t0, mut t1) = (1.0, x); // Chebyshev T_{k-1}(x)
    for _ in 0..k - 2 { let t2 = 2.0 * x * t1 - t0; t0 = t1; t1 = t2; }
    t1
}
fn tan2f(b: &[f64], v: &[f64]) -> f64 { let c2 = dot(b, v).powf(2.0) / dot(v, v); (dot(b, b) - c2) / c2 }

fn main() {
    // ---- road one: diag(1, 2, 3), start (1, 1, 1)/sqrt(3) ----
    let dm = |x: &[f64]| vec![1.0 * x[0], 2.0 * x[1], 3.0 * x[2]];
    let (al, be, _) = lanczos(&dm, &[1.0, 1.0, 1.0], 3, false);
    println!("small,alpha={:.4},{:.4},{:.4},beta={:.4},{:.4},beta3={}", al[0], al[1], al[2], be[0], be[1], sci(be[2]));
    let t2: Vec<f64> = (0..2).map(|j| ritz(&al[..2], &be, j, 0.0, 4.0)).collect();
    let q1 = vec![1.0 / 3.0f64.sqrt(); 3]; let aq = dm(&q1); // direct Rayleigh-Ritz on span{b, Ab}
    let v: Vec<f64> = aq.iter().zip(&q1).map(|(x, y)| x - dot(&aq, &q1) * y).collect();
    let q2: Vec<f64> = v.iter().map(|x| x / dot(&v, &v).sqrt()).collect();
    let (h11, h12, h22) = (dot(&q1, &dm(&q1)), dot(&q1, &dm(&q2)), dot(&q2, &dm(&q2)));
    let disc = ((h11 - h22).powf(2.0) + 4.0 * h12 * h12).sqrt();
    let direct = [0.5 * (h11 + h22 - disc), 0.5 * (h11 + h22 + disc)];
    assert!((be[0] - (2.0f64 / 3.0).sqrt()).abs() < 1e-15 && (be[1] - (1.0f64 / 3.0).sqrt()).abs() < 1e-15 && be[2].abs() < 1e-14);
    let closed = [2.0 - be[0], 2.0 + be[0]];
    for i in 0..2 { assert!((t2[i] - direct[i]).abs() < 1e-14 && (t2[i] - closed[i]).abs() < 1e-14); }
    let t3: Vec<f64> = (0..3).map(|j| ritz(&al, &be, j, 0.0, 4.0)).collect();
    for i in 0..3 { assert!((t3[i] - (i + 1) as f64).abs() < 1e-14); }
    assert!(1.0 <= t2[0] && t2[0] <= 2.0 && 2.0 <= t2[1] && t2[1] <= 3.0); // interlacing
    println!("small,T2_ritz={:.4},{:.4},direct={:.4},{:.4}", t2[0], t2[1], direct[0], direct[1]);
    println!("small,T3_ritz={:.6},{:.6},{:.6}", t3[0], t3[1], t3[2]);
    // ---- road two: the bar, n = 1,000 cells, plain Lanczos ----
    let n = 1000usize;
    let lop = |x: &[f64]| -> Vec<f64> { (0..n).map(|i| 2.0 * x[i] - (if i > 0 { x[i - 1] } else { 0.0 })
        - (if i < n - 1 { x[i + 1] } else { 0.0 })).collect() };
    let lam: Vec<f64> = (1..=n).map(|j| 4.0 * (j as f64 * PI / 2002.0).sin().powf(2.0)).collect(); // exact
    let (top, bot) = (2.0 + 2.0 * (PI / 1001.0).cos(), lam[0]);
    let mut st = 20261124u64;
    let b: Vec<f64> = (0..n).map(|_| unif(&mut st) - 0.5).collect();
    println!("bar,lambda_max={:.12},spec_form={:.12},second={:.12}", top, 4.0 - 2.0 * (1.0 - (PI / 1001.0).cos()), lam[n - 2]);
    println!("bar,lambda_min={:.15},kappa={:.1}", bot, top / bot);
    let vt: Vec<f64> = (1..=n).map(|j| ((j * 1000) as f64 * PI / 1001.0).sin()).collect(); // top eigenvector
    let (tan2, gam) = (tan2f(&b, &vt), (top - lam[n - 2]) / (lam[n - 2] - bot));
    let (al, be, _) = lanczos(&lop, &b, 800, false);
    println!("bar,tan2_theta0={:.2},gamma={}", tan2, sci(gam));
    println!("k,top_ritz,top_error,bottom_error,kaniel_paige_bound,bound/true");
    let ks = [10usize, 25, 50, 100, 200, 300, 400, 500, 600, 700, 800];
    let (mut prev, mut chart, mut th50, mut tl50) = (0.0, vec![], 0.0, 0.0);
    for &k in &ks {
        let (th, tl) = (ritz(&al[..k], &be, k - 1, 0.0, 4.5), ritz(&al[..k], &be, 0, 0.0, 4.5));
        let t = cheb(1.0 + 2.0 * gam, k);
        let bound = (top - bot) * tan2 / (t * t);
        assert!(prev - 1e-13 <= th && th <= top + 1e-13 && top - th <= bound && tl >= bot - 1e-13 && top - th < match k { 50 => 2e-3, 800 => 1e-6, _ => 1.0 });
        prev = th; chart.push(format!("{:.2}", (top - th).log10()));
        if k == 50 { th50 = th; tl50 = tl; }
        println!("{},{:.10},{},{},{},{}", k, th, sci(top - th), sci(tl - bot), sci(bound), sci(bound / (top - th)));
    }
    let kss: Vec<String> = ks.iter().map(|k| k.to_string()).collect();
    println!("chart,k,{}", kss.join(","));
    println!("chart,log10_top_error,{}", chart.join(","));
    // ---- road three: shift-invert, solve with L by the Thomas algorithm ----
    let solve = |d: &[f64]| -> Vec<f64> {
        let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]); cp[0] = -0.5; dp[0] = d[0] / 2.0;
        for i in 1..n { let m = 2.0 + cp[i - 1]; cp[i] = -1.0 / m; dp[i] = (d[i] + dp[i - 1]) / m; }
        let mut x = vec![0.0; n]; x[n - 1] = dp[n - 1];
        for i in (0..n - 1).rev() { x[i] = dp[i] - cp[i] * x[i + 1]; }
        x
    };
    let mu = [1.0 / lam[0], 1.0 / lam[1]]; // 1/lambda_1, 1/lambda_2
    let v1: Vec<f64> = (1..=n).map(|j| (j as f64 * PI / 1001.0).sin()).collect(); // bottom eigenvector
    let (tan2, gam) = (tan2f(&b, &v1), (mu[0] - mu[1]) / (mu[1] - 1.0 / top));
    println!("invert,mu1={:.6},mu2={:.6},tan2_theta0={:.2},gamma={:.4}", mu[0], mu[1], tan2, gam);
    let runs: Vec<Run> = [false, true].iter().map(|&f| lanczos(&solve, &b, 40, f)).collect();
    println!("k,rel_error,bound,bound/true,residual_estimate,residual_recomputed,copies_plain,copies_full,orth_plain,orth_full");
    let mut last = (vec![], 0.0);
    for k in [2usize, 3, 4, 5, 6, 8, 10, 15, 20, 30, 40] {
        let row: Vec<(f64, usize, f64)> = runs.iter().map(|(al, be, q)| {
            let th = ritz(&al[..k], be, k - 1, 0.0, 2e5);
            let cop = k - below(&al[..k], be, mu[0] * (1.0 - 1e-8));
            let orth = (0..k - 1).map(|i| dot(&q[k - 1], &q[i]).abs()).fold(f64::MIN, f64::max);
            (th, cop, orth)
        }).collect();
        let (al, be, q) = &runs[1]; let th = row[1].0; let s = ritzvec(&al[..k], be, th);
        let y: Vec<f64> = (0..n).map(|i| dot(&s, &(0..k).map(|j| q[j][i]).collect::<Vec<f64>>())).collect();
        let r: Vec<f64> = solve(&y).iter().zip(&y).map(|(p, q)| p - th * q).collect();
        let (tr, est) = (dot(&r, &r).sqrt(), be[k - 1] * s[k - 1].abs());
        let err = (mu[0] - th) / mu[0];
        let t = cheb(1.0 + 2.0 * gam, k);
        let bnd = (mu[0] - 1.0 / top) * tan2 / (t * t) / mu[0];
        assert!((row[0].0 - row[1].0).abs() < 1e-12 * mu[0] && (tr - est).abs() < 1e-13 * mu[0] + 1e-6 * est);
        assert!((err <= bnd || err < 1e-12) && err.abs() < match k { 5 => 1e-8, 6 => 1e-11, _ if k > 6 => 1e-12, _ => 1.0 }); // both sides; the floor
        let ratio = if err > 1e-12 { format!("{:.1}", bnd / err) } else { "-".to_string() };
        println!("{},{},{},{},{},{},{},{},{},{}", k, sci(err), sci(bnd), ratio, sci(est), sci(tr), row[0].1, row[1].1, sci(row[0].2), sci(row[1].2));
        if k == 8 || k == 10 { println!("paige,k={},u*mu1/estimate={},orth_plain={}", k, sci(2f64.powi(-53) * mu[0] / est), sci(row[0].2)); }
        last = (row.iter().map(|r| r.1).collect(), err);
    }
    assert!(last.0[0] >= 3 && last.0[1] == 1);
    println!("invert,error_floor={},kappa_u={}", sci(last.1), sci(top / bot * 2f64.powi(-53)));

    // ---- what it is for: the bar's time step and cooling time (alpha illustrative) ----
    let (h, alpha) = (1e-3, 1.2e-5); // 1 mm cells; steel, m^2/s, illustrative
    println!("use,dt_max_s={:.7},r_max={:.7},cooling_time_s={:.1}", 2.0 * h * h / (alpha * top), 2.0 / top, h * h / (alpha * bot));
    let (g, mut amp) = (1.0 - (2.0 / th50) * top, 1.0f64); // step set from the Ritz value th50 < lambda_max
    for _ in 0..10000 { amp *= g.abs(); }
    assert!(g < -1.0 && amp > 1.0);
    println!("break,ritz50={:.7},r_from_ritz={:.7},g={:.7},growth_10000_steps={:.1}", th50, 2.0 / th50, g, amp);
    println!("break,plain_bottom_ritz50={:.7},relative_error={:.1}", tl50, (tl50 - bot) / bot);
    let reo: usize = (0..40).map(|k| 4 * n * (k + 1)).sum();
    println!("cost,plain_50_steps={},invert_6_steps={},full_reorth_extra_40={},dense_tridiagonalise={}", commas(50 * 12 * n),
             commas(6 * 15 * n), commas(reo), commas(4 * n * n * n / 3));
    println!("ALL CHECKS PASS");
}
