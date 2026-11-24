// Mirror descent -- the check behind the card.  std only, no crates.
// Weights live on the simplex (non-negative, summing to 1).  Mirror descent with the
// entropy map multiplies each weight by exp(-step * slope), then rescales to sum 1.
// Roads: the closed-form step against a brute-force grid minimisation of
// step*g.x + KL(x||x0); the Bregman divergence from its definition against the KL sum;
// the three-point identity and Pinsker's bound; a constant-slope run against its
// closed form; on a 2,000-asset tracker, entropy against Euclidean steps, the one-step
// inequality, the certificate f >= 0 = f(index weights), and the first K with bound < f(x0).

fn kl(x: &[f64], y: &[f64]) -> f64 {
    x.iter().zip(y).filter(|(a, _)| **a > 0.0).map(|(a, b)| a * (a / b).ln()).sum()
}
fn h(x: &[f64]) -> f64 { x.iter().filter(|a| **a > 0.0).map(|a| a * a.ln()).sum() }
fn md_step(x: &[f64], g: &[f64], a: f64) -> Vec<f64> {
    let y: Vec<f64> = x.iter().zip(g).map(|(xi, gi)| xi * (-a * gi).exp()).collect();
    let z: f64 = y.iter().sum();
    y.iter().map(|v| v / z).collect()
}
fn proj(v: &[f64]) -> Vec<f64> { // nearest point of the simplex: subtract one level tau, clip at 0
    let mut u = v.to_vec();
    u.sort_by(|p, q| q.partial_cmp(p).unwrap());
    let (mut c, mut tau) = (0.0, 0.0);
    for (j, uj) in u.iter().enumerate() {
        c += uj;
        if uj - (c - 1.0) / (j as f64 + 1.0) > 0.0 { tau = (c - 1.0) / (j as f64 + 1.0); }
    }
    v.iter().map(|vi| (vi - tau).max(0.0)).collect()
}
fn show(x: &[f64]) -> String { x.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" ") }
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(p, q)| p * q).sum() }
fn fcost(x: &[f64]) -> f64 { x[0] + 2.0 * x[2] }

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn main() {
    // 1. one step on three assets: weights 1/3 each, slopes g = (1, 0, 2), step ln 2
    let (x0, g, a) = (vec![1.0 / 3.0; 3], vec![1.0, 0.0, 2.0], 2f64.ln());
    let mult: Vec<f64> = g.iter().map(|gi| (-a * gi).exp()).collect();
    let raw: Vec<f64> = x0.iter().zip(&mult).map(|(x, m)| x * m).collect();
    let x1 = md_step(&x0, &g, a);
    println!("multipliers 2^(-g): {}", show(&mult));
    println!("unnormalised: {} sum {:.4}", show(&raw), raw.iter().sum::<f64>());
    println!("mirror step x1: {}", show(&x1));
    let exact = [2.0 / 7.0, 4.0 / 7.0, 1.0 / 7.0];
    assert!((0..3).all(|i| (x1[i] - exact[i]).abs() < 1e-12));
    let n3 = 840usize;
    let (mut bv, mut bp) = (9.0, (0, 0, 0)); // brute force: every grid point, step 1/840
    for i in 0..=n3 {
        for j in 0..=(n3 - i) {
            let x = [i as f64 / n3 as f64, j as f64 / n3 as f64, (n3 - i - j) as f64 / n3 as f64];
            let val = a * (x[0] + 2.0 * x[2]) + kl(&x, &x0);
            if val < bv { bv = val; bp = (i, j, n3 - i - j); }
        }
    }
    println!("grid 1/840: best point {:?} / 840, value {:.6}; -ln(7/12) = {:.6}", bp, bv, -(7.0f64 / 12.0).ln());
    assert!(bp == (240, 480, 120) && (bv + (7.0f64 / 12.0).ln()).abs() < 1e-12);
    let d10 = kl(&x1, &x0);
    let d_def = h(&x1) - h(&x0) - (0..3).map(|i| (x0[i].ln() + 1.0) * (x1[i] - x0[i])).sum::<f64>();
    let l1: f64 = (0..3).map(|i| (x1[i] - x0[i]).abs()).sum();
    println!("D(x1,x0) by KL sum {:.6}, by definition {:.6}; D(x0,x1) = {:.6}", d10, d_def, kl(&x0, &x1));
    println!("Pinsker: |x1 - x0|_1 = {:.6}, half its square {:.6} <= {:.6}", l1, l1 * l1 / 2.0, d10);
    assert!((d10 - d_def).abs() < 1e-12 && l1 * l1 / 2.0 <= d10 && (kl(&x0, &x1) - d10).abs() > 0.01);
    let u = [0.0, 1.0, 0.0];
    let lhs = kl(&u, &x0) - kl(&u, &x1) - d10;
    let rhs = a * (0..3).map(|i| g[i] * (x1[i] - u[i])).sum::<f64>();
    println!("three-point: D(u,x0) {:.6} - D(u,x1) {:.6} - D(x1,x0) = {:.6}; a g.(x1-u) = {:.6}",
             kl(&u, &x0), kl(&u, &x1), lhs, rhs);
    assert!((lhs - rhs).abs() < 1e-12);
    let v: Vec<f64> = (0..3).map(|i| x0[i] - a * g[i]).collect();
    let xe = proj(&v);
    let tau2 = (v[0] + v[1] - 1.0) / 2.0; // by hand: two weights stay positive
    println!("Euclidean step, same size: {}", show(&xe));
    assert!((xe[0] - (v[0] - tau2)).abs() < 1e-12 && xe[2] == 0.0);

    // 2. the slopes held fixed: cost f(x) = x_A + 2 x_C, least value 0 at asset B
    let mut x = x0.clone();
    let (mut fs, mut path) = (vec![], vec![show(&x0)]);
    for k in 1..8 {
        x = md_step(&x, &g, a);
        let (p, q) = (2f64.powi(-k), 4f64.powi(-k));
        let z = p + 1.0 + q;
        let closed = [p / z, 1.0 / z, q / z];
        assert!((0..3).all(|i| (x[i] - closed[i]).abs() < 1e-12));
        fs.push(format!("{:.4}", fcost(&x)));
        path.push(show(&x));
    }
    println!("figure, mirror path k = 0..4: {} ; Euclidean step: {}", path[..5].join(" | "), show(&xe));
    println!("constant slopes, f(x_k) for k = 1..7: {}", fs.join(" "));
    let steps_to = |start: &[f64], tol: f64| -> usize {
        let mut x = start.to_vec();
        for k in 1..200 { x = md_step(&x, &g, a); if fcost(&x) < tol { return k; } }
        0
    };
    let xc = [0.998, 0.001, 0.001];
    let (ku, kc) = (steps_to(&x0, 0.01), steps_to(&xc, 0.01));
    println!("steps to f < 0.01: from equal weights {} (D(u,x0) = {:.4}), from (0.998, 0.001, 0.001) {} (D = {:.4})",
             ku, kl(&u, &x0), kc, kl(&u, &xc));
    let mut xz = vec![0.5, 0.0, 0.5];
    for _ in 0..20 { xz = md_step(&xz, &g, a); }
    println!("start (0.5, 0, 0.5), 20 steps: x = {}, f = {:.4}; least value 0", show(&xz), fcost(&xz));
    assert!(ku == 7 && kc > ku && xz[1] == 0.0 && fcost(&xz) > 0.99);

    // 3. the tracker: n = 2,000 assets, m = 250 days of returns (percent), SplitMix64 seed 2024
    let (n, m, kk) = (2000usize, 250usize, 400usize);
    let mut rng = Rng(2024);
    let beta: Vec<f64> = (0..n).map(|_| 0.5 + rng.unif()).collect();
    let mut rr: Vec<Vec<f64>> = vec![];
    for _ in 0..m {
        let mt = 2.0 * rng.unif() - 1.0;
        rr.push(beta.iter().map(|b| b * mt + 4.0 * rng.unif() - 2.0).collect());
    }
    let cols: Vec<Vec<f64>> = (0..n).map(|i| rr.iter().map(|r| r[i]).collect()).collect();
    let zw: f64 = (0..n).map(|i| 1.0 / (i as f64 + 1.0)).sum();
    let w: Vec<f64> = (0..n).map(|i| 1.0 / (i as f64 + 1.0) / zw).collect();
    let index: Vec<f64> = rr.iter().map(|r| dot(r, &w)).collect();
    let fg = |x: &[f64]| -> (f64, Vec<f64>) { // mean absolute daily miss, and a subgradient
        let e: Vec<f64> = rr.iter().zip(&index).map(|(r, it)| dot(r, x) - it).collect();
        let s: Vec<f64> = e.iter().map(|v| if *v > 0.0 { 1.0 } else if *v < 0.0 { -1.0 } else { 0.0 }).collect();
        (e.iter().map(|v| v.abs()).sum::<f64>() / m as f64, cols.iter().map(|c| dot(c, &s) / m as f64).collect())
    };
    let col_abs: Vec<f64> = cols.iter().map(|c| c.iter().map(|v| v.abs()).sum::<f64>() / m as f64).collect();
    let g_inf = col_abs.iter().cloned().fold(0.0, f64::max);
    let g_2 = col_abs.iter().map(|v| v * v).sum::<f64>().sqrt();
    let rad = (1.0 - 1.0 / n as f64).sqrt();
    let ln_n = (n as f64).ln();
    let (a_m, a_e) = ((2.0 * ln_n).sqrt() / (g_inf * (kk as f64).sqrt()), rad / (g_2 * (kk as f64).sqrt()));
    let (bound_m, bound_e) = (g_inf * (2.0 * ln_n / kk as f64).sqrt(), rad * g_2 / (kk as f64).sqrt());
    println!("tracker: G_inf = {:.4}, G_2 = {:.4}, R = {:.4}; steps: entropy {:.5}, Euclidean {:.6}", g_inf, g_2, rad, a_m, a_e);
    println!("certificate: f >= 0 everywhere and f(index weights) = {:.6}, so f* = 0", fg(&w).0);
    let (mut xm, mut xe) = (vec![1.0 / n as f64; n], vec![1.0 / n as f64; n]);
    let (mut bm, mut be, mut hist, mut bad) = (f64::INFINITY, f64::INFINITY, vec![], 0);
    for k in 0..=kk {
        let (fm, gm) = fg(&xm);
        let (fe, ge) = fg(&xe);
        bm = bm.min(fm); be = be.min(fe);
        if k % 25 == 0 { hist.push((k, bm, be)); }
        if k == kk { break; }
        let xn = md_step(&xm, &gm, a_m); // one-step inequality of the proof, with u = index weights
        let gmax = gm.iter().fold(0.0f64, |acc, v| acc.max(v.abs()));
        if a_m * fm > kl(&w, &xm) - kl(&w, &xn) + a_m * a_m * gmax * gmax / 2.0 + 1e-12 { bad += 1; }
        xe = proj(&xe.iter().zip(&ge).map(|(p, q)| p - a_e * q).collect::<Vec<f64>>());
        xm = xn;
    }
    for (k, p, q) in &hist {
        if [0, 50, 100, 200, 400].contains(k) { println!("k = {:3}: best miss entropy {:.6}, Euclidean {:.6}", k, p, q); }
    }
    let line = |sel: usize| hist.iter().map(|t| format!("{:.2}", (if sel == 0 { t.1 } else { t.2 }).log10())).collect::<Vec<_>>().join(" ");
    println!("chart, log10 best miss, entropy: {}", line(0));
    println!("chart, log10 best miss, Euclidean: {}", line(1));
    println!("bounds after {} steps: entropy {:.4}, Euclidean {:.4}; one-step inequality broken {} times", kk, bound_m, bound_e, bad);
    let (f0, c_m, c_e) = (hist[0].1, (2.0 * ln_n).sqrt(), (n as f64 - 1.0).sqrt()); // f0: the miss at equal weights
    let [km, ke] = [bound_m, bound_e].map(|b| (1..1_000_000usize).find(|&k| b * (kk as f64 / k as f64).sqrt() < f0).unwrap());
    println!("first budget K whose bound is below the starting miss {:.6}: entropy {}, Euclidean {}, ratio {:.1}", f0, km, ke, ke as f64 / km as f64);
    assert!(kk < km && km < ke && km == (2.0 * ln_n * (g_inf / f0).powi(2)) as usize + 1 && ke == (rad * g_2 / f0).powi(2) as usize + 1);
    println!("after {} steps, weight on asset 1: entropy {:.4}, Euclidean {:.4}, index {:.4}", kk, xm[0], xe[0], w[0]);
    assert!(fg(&w).0 < 1e-12 && bad == 0 && bm < be && xm.iter().all(|v| *v > 0.0));
    println!("worst-case constants for n = 2000: entropy sqrt(2 ln n) = {:.4}, Euclidean sqrt(n - 1) = {:.4}, ratio {:.2}, steps ratio {:.1}",
             c_m, c_e, c_e / c_m, (c_e / c_m).powi(2));
    assert!((c_m - 3.90).abs() < 0.005);
    println!("ALL CHECKS PASS");
}
