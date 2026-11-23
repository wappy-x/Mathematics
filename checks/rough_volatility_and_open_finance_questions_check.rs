// Rough Bergomi: skew power law, skew-stickiness ratio; Ross recovery.  Standard library only, no crates.
// Same roads, inputs and printed lines as the Python check; the bell-curve area is its Taylor series.
use std::f64::consts::PI;
const H: f64 = 0.1; const RHO: f64 = -0.9; const XI0: f64 = 0.04; const S0: f64 = 0.2; const KAP: f64 = 2.0;
const N: usize = 32; const N2: usize = 64; const M: usize = 20000; const NB: usize = 10;
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
    fn gauss(&mut self) -> f64 { let u1 = self.unif(); let u2 = self.unif(); (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }
}
fn ncdf(x: f64) -> f64 {                                   // bell-curve area by its Taylor series
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut s, mut k) = (x, x, 1.0_f64);
    while term.abs() > 1e-17 * s.abs() { term = term * x * x / (2.0 * k + 1.0); s += term; k += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn bs(f: f64, k: f64, w: f64) -> f64 {
    let sd = w.sqrt(); let d1 = ((f / k).ln() + 0.5 * w) / sd;
    f * ncdf(d1) - k * ncdf(d1 - sd)
}
fn implied(c: f64, k: f64, t: f64) -> f64 {
    let (mut lo, mut hi) = (0.001, 2.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if bs(100.0, k, mid * mid * t) > c { hi = mid } else { lo = mid }
    }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn skew_rough(t: f64, eta: f64) -> f64 { RHO * eta * (2.0 * H).sqrt() / (2.0 * (H + 0.5) * (H + 1.5)) * t.powf(H - 0.5) }
fn hi_(t: f64) -> f64 { t / KAP - (1.0 - (-KAP * t).exp()) / (KAP * KAP) }
fn ssr_heston(t: f64) -> f64 { t * (1.0 - (-KAP * t).exp()) / KAP / hi_(t) }
fn cov_yy(a: f64, b: f64) -> f64 {
    if b - a <= 0.0 { return a.powf(2.0 * H); }
    let p = 1.0 / (H + 0.5);
    2.0 * H * simpson(|w: f64| p * (w.powf(p) + b - a).powf(H - 0.5), 0.0, a.powf(H + 0.5), 400)
}
fn cov_yw(a: f64, lo: f64, hi: f64) -> f64 { (2.0 * H).sqrt() / (H + 0.5) * ((a - lo).powf(H + 0.5) - (a - hi).powf(H + 0.5)) }
fn skew_grid(t: f64, n: usize, eta: f64) -> f64 {
    let mut tot = 0.0; let nf = n as f64;
    for j in 1..n { for i in 0..j { tot += cov_yw(j as f64 / nf, i as f64 / nf, (i + 1) as f64 / nf); } }
    RHO * eta * tot / nf * t.powf(H - 0.5) / 2.0
}
fn main() {
    let eta_full = 0.6 * 252f64.powf(H);
    let xih = skew_rough(1.0, eta_full) / (RHO / (2.0 * S0) * hi_(1.0));
    let skew_heston = |t: f64| RHO * xih / (2.0 * S0 * t * t) * hi_(t);
    println!("H {}  rho {}  eta {:.6}  xi0 {}  sqrt(2H) {:.4}  (H+1/2)(H+3/2) {:.4}", H, RHO, eta_full, XI0, (2.0 * H).sqrt(), (H + 0.5) * (H + 1.5));
    println!("Heston kappa {:.1}  vol of vol matched at 1y {:.6}", KAP, xih);
    println!("maturity   years     rough   Heston  rough/1y Heston/1y");
    for (name, t) in [("1w", 1.0 / 52.0), ("2w", 1.0 / 26.0), ("1m", 1.0 / 12.0), ("2m", 1.0 / 6.0), ("3m", 0.25), ("6m", 0.5), ("1y", 1.0)] {
        let (r, h) = (skew_rough(t, eta_full), skew_heston(t));
        println!("{:>8} {:7.4} {:9.4} {:8.4} {:9.4} {:9.4}", name, t, r, h, r / skew_rough(1.0, eta_full), h / skew_heston(1.0));
    }
    println!("52^(1/2-H) {:.4}   H = 0.3: {:.4}   H = 0.5: {:.4}", 52f64.powf(0.5 - H), 52f64.powf(0.2), 52f64.powf(0.0));
    let heston_lim = RHO * xih / (4.0 * S0); println!("Heston skew at T = 1e-4: formula {:.6}  limit rho*xi/(4 sigma0) {:.6}", skew_heston(1e-4), heston_lim);
    let i1 = |s: f64| s.powf(H + 0.5) / (H + 0.5); let ssr_quad = i1(1.0) / simpson(i1, 0.0, 1.0, 4000);
    println!("SSR rough by quadrature {:.6}  H + 3/2 = {:.6}   Heston 1w {:.4}  1y {:.4}  T = 1e-4 {:.4}",
        ssr_quad, H + 1.5, ssr_heston(1.0 / 52.0), ssr_heston(1.0), ssr_heston(1e-4));
    let rules: [fn(f64, f64) -> f64; 3] = [|k, s| 0.2 - 0.04 * (k / s - 1.0), |k, _s| 0.2 - 0.0004 * (k - 100.0), |k, s| 0.2 - 0.0004 * (k + s - 200.0)];
    let u = 100.0 * 1e-4f64.exp(); let rs: Vec<String> = rules.iter().map(|r| format!("{:.4}", (r(100.0, 100.0) - r(u, u)) / (r(100.0, 100.0) - r(u, 100.0)))).collect();
    println!("SSR of the smile card's rules (moneyness, strike, local vol): {}", rs.join(" "));
    let (g32, g1024) = (skew_grid(1.0, 32, eta_full), skew_grid(1.0, 1024, eta_full));
    println!("first-order 1y skew: 32-step grid {:.6}  1024-step grid {:.6}  formula {:.6}", g32, g1024, skew_rough(1.0, eta_full));
    // ---- simulation: exact Gaussian grid by Cholesky ----
    let nf = N as f64;
    let mut c = vec![vec![0.0f64; N2]; N2];
    for i in 0..N {
        c[i][i] = 1.0 / nf;
        for j in i..N { let v = cov_yw((j + 1) as f64 / nf, i as f64 / nf, (i + 1) as f64 / nf); c[N + j][i] = v; c[i][N + j] = v; }
        for j in i..N { let v = cov_yy((i + 1) as f64 / nf, (j + 1) as f64 / nf); c[N + i][N + j] = v; c[N + j][N + i] = v; }
    }
    let mut l = vec![vec![0.0f64; N2]; N2];  // lower-triangular Cholesky factor
    for i in 0..N2 {
        for j in 0..=i {
            let mut s = c[i][j];
            for k in 0..j { s -= l[i][k] * l[j][k]; }
            l[i][j] = if i == j { s.sqrt() } else { s / l[j][j] };
        }
    }
    let (ts, etas) = ([1.0f64 / 52.0, 1.0], [0.0f64, 0.05, eta_full]);
    let mut acc = vec![[0.0f64; 3]; 2 * 3 * NB];   // per maturity, vol of vol, batch: low call, forward, high call
    let (mut vmean, mut vnocomp, mut rng) = (0.0, 0.0, Rng(20261123));
    for m in 0..M {
        let z: Vec<f64> = (0..N2).map(|_| rng.gauss()).collect();
        for sgn in [1.0, -1.0] {
            let mut g = vec![0.0f64; N2];
            for i in 0..N2 { for k in 0..=i { g[i] += sgn * l[i][k] * z[k]; } }
            for (ti, &t) in ts.iter().enumerate() {
                let (sw, sy, dk) = (t.sqrt(), t.powf(H), 0.1 * S0 * t.sqrt());
                for (ei, &e) in etas.iter().enumerate() {
                    let (mut i1s, mut i2s, mut v) = (0.0, 0.0, XI0);
                    for i in 0..N {
                        i1s += v.sqrt() * g[i] * sw; i2s += v * t / nf;
                        v = XI0 * (e * g[N + i] * sy - 0.5 * e * e * ((i + 1) as f64 * t / nf).powf(2.0 * H)).exp();
                    }
                    let (f, w) = (100.0 * (RHO * i1s - 0.5 * RHO * RHO * i2s).exp(), (1.0 - RHO * RHO) * i2s);
                    let a = &mut acc[(ti * 3 + ei) * NB + m % NB];
                    a[0] += bs(f, 100.0 * (-dk).exp(), w); a[1] += f; a[2] += bs(f, 100.0 * dk.exp(), w);
                    if t == 1.0 && e == eta_full { vmean += v; vnocomp += XI0 * (e * g[N2 - 1]).exp(); }
                }
            }
        }
    }
    let batch_skew = |ti: usize, ei: usize, b: usize| -> f64 {
        let (a, n, t) = (acc[(ti * 3 + ei) * NB + b], 2.0 * M as f64 / NB as f64, ts[ti]); let (dk, f) = (0.1 * S0 * t.sqrt(), a[1] / n);
        let lo = implied(a[0] / n * 100.0 / f, 100.0 * (-dk).exp() * 100.0 / f, t);
        let hi = implied(a[2] / n * 100.0 / f, 100.0 * dk.exp() * 100.0 / f, t);
        (hi - lo) / (2.0 * dk)
    };
    let mut sim = [[(0.0f64, 0.0f64); 3]; 2];
    for ti in 0..2 {
        for ei in 1..3 {
            let xs: Vec<f64> = (0..NB).map(|b| batch_skew(ti, ei, b) - batch_skew(ti, 0, b)).collect();
            let (mut mu, mut var) = (0.0, 0.0);
            for x in &xs { mu += x / NB as f64; }
            for x in &xs { var += (x - mu) * (x - mu); }
            sim[ti][ei] = (mu, (var / (NB - 1) as f64 / NB as f64).sqrt());
            println!("simulated skew T {:.4} eta {:.4}: {:.4} +- {:.4}   grid {:.4}  formula {:.4}",
                ts[ti], etas[ei], mu, sim[ti][ei].1, skew_grid(ts[ti], N, etas[ei]), skew_rough(ts[ti], etas[ei]));
        }
    }
    let r_sim = sim[0][2].0 / sim[1][2].0; println!("simulated 1w/1y skew ratio {:.4}   power law {:.4}", r_sim, 52f64.powf(0.5 - H));
    let (vm, vn, vn_exact) = (vmean / (2 * M) as f64, vnocomp / (2 * M) as f64, XI0 * (0.5 * eta_full * eta_full).exp());
    println!("mean variance at 1y: simulated {:.5}  no compensator: simulated {:.5}  exact {:.5}  vol {:.4}", vm, vn, vn_exact, vn_exact.sqrt());
    // ---- Ross recovery on a 3-state chain (down, flat, up) ----
    let (p, zz, ww, delta) = ([[0.6f64, 0.3, 0.1], [0.2, 0.6, 0.2], [0.1, 0.3, 0.6]], [1.25f64, 1.0, 0.8], [1.3f64, 1.0, 0.85], 0.97f64);
    let mut a = [[0.0f64; 3]; 3];
    for i in 0..3 { for j in 0..3 { a[i][j] = delta * p[i][j] * zz[j] / zz[i]; } }
    let (mut e, mut lam) = ([1.0f64; 3], 0.0);
    for _ in 0..500 {
        let mut e2 = [0.0f64; 3];
        for i in 0..3 { e2[i] = a[i][0] * e[0] + a[i][1] * e[1] + a[i][2] * e[2]; }
        lam = e2[1] / e[1]; for i in 0..3 { e[i] = e2[i] / e2[1]; }
    }
    let (mut r, mut pb, mut ab) = ([[0.0f64; 3]; 3], [[0.0f64; 3]; 3], [[0.0f64; 3]; 3]);
    let cc: Vec<f64> = (0..3).map(|i| p[i][0] / ww[0] + p[i][1] / ww[1] + p[i][2] / ww[2]).collect();
    for i in 0..3 {
        for j in 0..3 {
            r[i][j] = a[i][j] * e[j] / (lam * e[i]);
            pb[i][j] = p[i][j] / (cc[i] * ww[j]);
            ab[i][j] = pb[i][j] * delta * zz[j] / zz[i] * cc[i] * ww[j];
        }
    }
    println!("recovery: discount {:.6}   from flat, recovered {:.4} {:.4} {:.4}", lam, r[1][0], r[1][1], r[1][2]);
    println!("true chances from flat: world A {:.4} {:.4} {:.4}   world B {:.4} {:.4} {:.4}", p[1][0], p[1][1], p[1][2], pb[1][0], pb[1][1], pb[1][2]);
    let maxdiff = |x: &[[f64; 3]; 3], y: &[[f64; 3]; 3]| { let mut d: f64 = 0.0; for i in 0..3 { for j in 0..3 { d = d.max((x[i][j] - y[i][j]).abs()); } } d };
    assert!((heston_lim - skew_heston(1e-4)).abs() < 1e-4, "Heston skew formula vs its short-maturity limit");
    assert!((ssr_quad - (H + 1.5)).abs() < 1e-5, "skew-stickiness ratio by quadrature vs H + 3/2");
    assert!((ssr_heston(1e-4) - 2.0).abs() < 1e-3, "Heston SSR tends to 2 at short maturity");
    assert!((g1024 / skew_rough(1.0, eta_full) - 1.0).abs() < 2e-3, "grid sum of covariances converges to the closed form");
    for ti in 0..2 {   // small vol of vol: simulation matches first order
        let (mu, se) = sim[ti][1]; assert!((mu - skew_grid(ts[ti], N, 0.05)).abs() < 4.0 * se + 0.03 * mu.abs(), "simulated skew vs first order"); }
    assert!(4.0 < r_sim && r_sim < 6.5, "rough skew steepens like a power law at full vol of vol");
    assert!((vm - XI0).abs() < 0.002, "compensator keeps the mean variance at 0.04");
    assert!((vn / vn_exact - 1.0).abs() < 0.05, "without it the mean is 0.04 e^(eta^2/2)");
    assert!(maxdiff(&r, &p) < 1e-12, "recovery returns world A");
    assert!(maxdiff(&a, &ab) < 1e-14, "worlds A and B: same prices");
    assert!((pb[1][0] - p[1][0]).abs() > 0.04, "world B's true chance of down differs from the recovered one");
    println!("ALL CHECKS PASS");
}
