// SVD and the pseudoinverse -- the same check as the Python, in Rust.  No crates.
// A greenhouse logs 20 sensors every hour for 10 days (240 rows, 10 more days to test);
// the readings carry three hidden signals (sun, night heating, watering) plus noise.
// Road one: a one-sided Jacobi SVD.  Road two: power iteration, normal equations and
// Penrose's four conditions.  Road three: the known signal and noise the log was built from.
type M = Vec<Vec<f64>>;

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {                      // SplitMix64, seed 2026
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
    fn gauss(&mut self) -> f64 { let a = 2.0 * self.unif() - 1.0; let b = 2.0 * self.unif() - 1.0; a + b + (2.0 * self.unif() - 1.0) }
}
fn dot(x: &[f64], y: &[f64]) -> f64 { let mut s = 0.0; for (a, b) in x.iter().zip(y) { s += a * b; } s }
fn nrm(x: &[f64]) -> f64 { dot(x, x).sqrt() }
fn col(m: &M, j: usize) -> Vec<f64> { m.iter().map(|r| r[j]).collect() }
fn mv(m: &M, x: &[f64]) -> Vec<f64> { m.iter().map(|r| dot(r, x)).collect() }
fn mtv(m: &M, y: &[f64]) -> Vec<f64> { (0..m[0].len()).map(|j| dot(&col(m, j), y)).collect() }
fn fro(m: &M) -> f64 { let d: Vec<f64> = m.iter().map(|r| dot(r, r)).collect(); dot(&d, &vec![1.0; m.len()]).sqrt() }
fn sub(p: &M, q: &M) -> M { p.iter().zip(q).map(|(a, b)| a.iter().zip(b).map(|(x, y)| x - y).collect()).collect() }
fn tr(m: &M) -> M { (0..m[0].len()).map(|j| col(m, j)).collect() }
fn norm2(m: &M) -> f64 {                             // largest singular value by power iteration
    let mut x = vec![1.0; m[0].len()];
    for _ in 0..400 { let z = mtv(m, &mv(m, &x)); let nz = nrm(&z); x = z.iter().map(|v| v / nz).collect(); }
    nrm(&mv(m, &x))
}
fn svd(a: &M) -> (Vec<f64>, M, M, u32, u64) {       // one-sided Jacobi: rotate columns until orthogonal
    let (m, n) = (a.len(), a[0].len());
    let mut w = tr(a);
    let mut v: M = (0..n).map(|j| (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect()).collect();
    let (mut fl, mut sweeps, mut rot) = (0u64, 0u32, 1u32);
    while rot > 0 {
        sweeps += 1; rot = 0;
        for p in 0..n - 1 {
            for q in p + 1..n {
                let (a, b, c) = (dot(&w[p], &w[p]), dot(&w[q], &w[q]), dot(&w[p], &w[q])); fl += 6 * m as u64;
                if c.abs() <= 1e-15 * (a * b).sqrt() { continue; }
                let z = (b - a) / (2.0 * c);
                let t = (if z >= 0.0 { 1.0 } else { -1.0 }) / (z.abs() + (1.0 + z * z).sqrt());
                let cs = 1.0 / (1.0 + t * t).sqrt(); let sn = cs * t; rot += 1; fl += 6 * (m + n) as u64;
                for x in [&mut w, &mut v] {
                    let (xp, xq) = (x[p].clone(), x[q].clone());
                    x[p] = xp.iter().zip(&xq).map(|(u, v)| cs * u - sn * v).collect();
                    x[q] = xp.iter().zip(&xq).map(|(u, v)| sn * u + cs * v).collect();
                }
            }
        }
    }
    let s: Vec<f64> = w.iter().map(|c| nrm(c)).collect();
    let mut o: Vec<usize> = (0..n).collect();
    o.sort_by(|&i, &j| s[j].partial_cmp(&s[i]).unwrap());
    (o.iter().map(|&j| s[j]).collect(), o.iter().map(|&j| w[j].iter().map(|x| x / s[j]).collect()).collect(),
     o.iter().map(|&j| v[j].clone()).collect(), sweeps, fl)
}
fn chol_solve(g: &M, bs: &M) -> M {                 // G x = b for each b, G symmetric positive definite
    let n = g.len(); let mut l = vec![vec![0.0; n]; n];
    for i in 0..n {
        for j in 0..=i {
            let s = g[i][j] - dot(&l[i][..j], &l[j][..j]);
            if i == j { l[i][i] = s.sqrt(); } else { l[i][j] = s / l[j][j]; }
        }
    }
    let mut xs = bs.clone();
    for y in xs.iter_mut() {                          // forward with L, then back with L transposed
        for i in 0..n { y[i] = (y[i] - dot(&l[i][..i], &y[..i])) / l[i][i]; }
        for i in (0..n).rev() { y[i] = (y[i] - dot(&col(&l, i)[i + 1..], &y[i + 1..])) / l[i][i]; }
    }
    xs
}
fn lowrank(s: &[f64], u: &M, v: &M, k: usize) -> M {
    (0..u[0].len()).map(|r| (0..v[0].len()).map(|j| dot(&(0..k).map(|i| s[i] * u[i][r]).collect::<Vec<_>>(),
        &(0..k).map(|i| v[i][j]).collect::<Vec<_>>())).collect()).collect()
}
fn e(x: f64) -> String {                             // Python's 1.234e-05 form: sign and two digits
    let t = format!("{:.3e}", x); let (a, p) = t.split_once('e').unwrap(); let p: i32 = p.parse().unwrap();
    format!("{}e{}{:02}", a, if p < 0 { '-' } else { '+' }, p.abs())
}
fn rms(x: &[f64], m: &M, b: &[f64]) -> f64 { let r: Vec<f64> = mv(m, x).iter().zip(b).map(|(p, q)| p - q).collect(); (dot(&r, &r) / b.len() as f64).sqrt() }
fn gap(x: &[f64], y: &[f64]) -> f64 { nrm(&x.iter().zip(y).map(|(a, b)| a - b).collect::<Vec<_>>()) / nrm(y) }
fn amax(x: &[f64]) -> f64 { x.iter().fold(0.0, |m, v| m.max(v.abs())) }
fn join(x: &[f64], d: usize) -> String { x.iter().map(|v| format!("{:.*}", d, v)).collect::<Vec<_>>().join(" ") }

fn main() {
    let mut g = Rng(2026);
    let base: Vec<[f64; 3]> = [([1.0, 0.8, -0.2], 8), ([-0.6, -0.2, 1.0], 6), ([1.2, 0.0, 0.0], 4), ([0.0, 0.0, 1.2], 2)]
        .iter().flat_map(|&(b, k)| vec![b; k]).collect();
    let ld: M = (0..3).map(|k| (0..20).map(|j| base[j][k] + 0.3 * (2.0 * g.unif() - 1.0)).collect()).collect();
    let days: Vec<(f64, f64)> = (0..20).map(|_| { let a = 0.6 + 0.4 * g.unif(); (a, 0.5 + g.unif()) }).collect();
    let mut sig: M = vec![];
    for t in 0..480usize {
        let (h, (cl, co)) = (t % 24, days[t / 24]);
        let k = if (6..15).contains(&h) { h - 6 } else if h >= 15 { h - 15 } else { h + 9 };
        let mut w = 1.0; for _ in 0..k { w *= 0.6; }  // moisture decays 40% an hour after watering
        let d = (h as f64 - 13.0) / 6.0;
        sig.push(vec![cl * (1.0 - d * d).max(0.0), if h < 7 || h >= 19 { co } else { 0.0 }, w]);
    }
    let dlt = 0.01;                                   // sensor noise, standard units (illustrative)
    let s0m: M = sig.iter().map(|sg| (0..20).map(|j| dot(sg, &col(&ld, j))).collect()).collect();   // A0 on the card
    let em: M = (0..480).map(|_| (0..20).map(|_| dlt * g.gauss()).collect()).collect();
    let a: M = s0m.iter().zip(&em).map(|(p, q)| p.iter().zip(q).map(|(x, y)| x + y).collect()).collect();
    let y: Vec<f64> = sig.iter().map(|s| 3.0 * s[0] + s[1] + 5.0 * s[2] + 0.3 * g.gauss()).collect();
    let (at, ate, yt, yte) = (a[..240].to_vec(), a[240..].to_vec(), &y[..240], &y[240..]);
    let (st, et, m, n) = (s0m[..240].to_vec(), em[..240].to_vec(), 240usize, 20usize);
    let (s, u, v, sweeps, fl) = svd(&at);
    let (s0, ne, eps) = (svd(&st).0, norm2(&et), 2f64.powi(-52));
    println!("log: m = {} hours, n = {} sensors, noise sd {}; Jacobi sweeps {}, flops {}", m, n, dlt, sweeps, fl);
    let qr = 2 * m * n * n - 2 * n * n * n / 3;
    println!("Householder QR of the same table: 2mn^2 - 2n^3/3 = {} flops; Jacobi / QR = {:.1}", qr, fl as f64 / qr as f64);
    println!("singular values 1-5: {}\nsingular values 16-20: {}", join(&s[..5], 4), join(&s[15..], 4));
    println!("chart, log10 sigma_i: {}", join(&s.iter().map(|x| x.log10()).collect::<Vec<_>>(), 2));
    let (trr, tn) = (m.max(n) as f64 * eps * s[0], dlt * ((m as f64).sqrt() + (n as f64).sqrt()));
    let (r_round, r_noise) = (s.iter().filter(|&&x| x > trr).count(), s.iter().filter(|&&x| x > tn).count());
    println!("rank, rounding tolerance max(m,n) eps sigma1 = {}: {}", e(trr), r_round);
    println!("rank, noise tolerance delta(sqrt m + sqrt n) = {:.4} (log10 {:.2}): {}", tn, tn.log10(), r_noise);
    println!("noise-free log: sigma_4 = {}, rank at rounding tolerance {}", e(s0[3]), s0.iter().filter(|&&x| x > trr).count());
    let wey = s.iter().zip(&s0).fold(0.0f64, |mx, (a, b)| mx.max((a - b).abs()));
    println!("||E||_2 = {:.4}; Weyl: largest shift |sigma_i(A) - sigma_i(A0)| = {:.4}, bound / shift {:.3}; tolerance / ||E||_2 {:.3}", ne, wey, ne / wey, tn / ne);
    println!("kappa_2(A) = sigma1/sigma20 = {:.1}; rank-3 part sigma1/sigma3 = {:.2}", s[0] / s[19], s[0] / s[2]);
    let a3 = lowrank(&s, &u, &v, 3);
    let cols: M = [0usize, 8, 14].iter().map(|&j| col(&at, j)).collect();   // temperature, humidity, light
    let gm: M = cols.iter().map(|a| cols.iter().map(|b| dot(a, b)).collect()).collect();
    let z = chol_solve(&gm, &(0..n).map(|j| cols.iter().map(|c| dot(c, &col(&at, j))).collect()).collect());
    let csub: M = (0..m).map(|i| (0..n).map(|j| dot(&col(&cols, i), &z[j])).collect()).collect();
    let (fs, f3s, kept) = (fro(&st), fro(&sub(&a3, &st)), 3 * (m + n + 1));
    let (fa, fbest, ftrue, fsub, sp) = (fro(&at), fro(&sub(&at, &a3)), fro(&et), fro(&sub(&at, &csub)), norm2(&sub(&at, &a3)));
    println!("Eckart-Young, ||A - B||_F over rank-3 B: SVD {:.4} (formula {:.4}), true signal {:.4}, three sensors {:.4}",
             fbest, nrm(&s[3..]), ftrue, fsub);
    println!("spectral: ||A - A_3||_2 by power iteration {:.4}, sigma_4 = {:.4}", sp, s[3]);
    println!("compression: {} numbers for {} ({:.1}%); error {}", kept, m * n, 100.0 * kept as f64 / (m * n) as f64, e(fbest / fa));
    println!("distance to the true signal: raw log {}, rank-3 fit {}", e(ftrue / fs), e(f3s / fs));
    let c: Vec<f64> = u.iter().map(|ui| dot(ui, yt)).collect();
    let trunc = |k: usize| -> Vec<f64> { (0..n).map(|j| dot(&(0..k).map(|i| c[i] / s[i]).collect::<Vec<_>>(),
        &(0..k).map(|i| v[i][j]).collect::<Vec<_>>())).collect() };
    let (xf, x3, x1, x6) = (trunc(20), trunc(3), trunc(1), trunc(6));
    let att = tr(&at);                                // normal equations: (A^T A) x = A^T y
    let xs = chol_solve(&att.iter().map(|a| att.iter().map(|b| dot(a, b)).collect()).collect(), &vec![mtv(&at, yt)]);
    let pm: M = (0..3).map(|i| mv(&at, &v[i])).collect();      // scores road: regress on A v_1, A v_2, A v_3
    let zs = chol_solve(&pm.iter().map(|a| pm.iter().map(|b| dot(a, b)).collect()).collect(),
                        &vec![pm.iter().map(|a| dot(a, yt)).collect()]);
    let x3b: Vec<f64> = (0..n).map(|j| dot(&zs[0], &(0..3).map(|i| v[i][j]).collect::<Vec<_>>())).collect();
    for (lab, x) in [("all 20", &xf), ("rank 3", &x3)] { println!("{}: |x| = {:.3}, largest |x_j| {:.3}; fit rms {:.4}, test rms {:.4} L/h",
        lab, nrm(x), amax(x), rms(x, &at, yt), rms(x, &ate, yte)); }
    println!("normal equations vs SVD, all 20: relative gap {:.1e}; kappa^2 u = {}", gap(&xs[0], &xf), e((s[0] / s[19]).powi(2) * eps / 2.0));
    println!("rank 3 by the scores road: relative gap {:.1e}", gap(&x3b, &x3));
    println!("sensor 6 drifts +0.5: prediction moves {:+.3} L/h all 20, {:+.3} L/h rank 3", 0.5 * xf[5], 0.5 * x3[5]);
    let ii = [0usize, 2, 3, 19]; println!("i = 1, 3, 4, 20: c_i = u_i.y {} | 1/sigma_i {} | c_i/sigma_i {}", join(&ii.map(|i| c[i]), 4),
             join(&ii.map(|i| 1.0 / s[i]), 4), join(&ii.map(|i| c[i] / s[i]), 4));
    let x3m: M = (0..n).map(|j| (0..m).map(|r| dot(&(0..3).map(|i| v[i][j] / s[i]).collect::<Vec<_>>(),
        &(0..3).map(|i| u[i][r]).collect::<Vec<_>>())).collect()).collect();
    let (xa, x3t): (M, M) = ((0..n).map(|i| (0..n).map(|j| dot(&x3m[i], &col(&a3, j))).collect()).collect(), tr(&x3m));
    let (ax, axa): (M, M) = (a3.iter().map(|r| x3t.iter().map(|x| dot(r, x)).collect()).collect(), a3.iter().map(|r| mtv(&xa, r)).collect());
    let xax: M = xa.iter().map(|r| x3t.iter().map(|x| dot(r, x)).collect()).collect();
    let pen = [fro(&sub(&axa, &a3)), fro(&sub(&xax, &x3m)), fro(&sub(&ax, &tr(&ax))), fro(&sub(&xa, &tr(&xa)))];
    println!("Penrose conditions on A_3^+, residuals: {}", pen.iter().map(|&x| e(x)).collect::<Vec<_>>().join(" "));
    let pos = |x: &[f64]| x.iter().filter(|&&t| t > 0.0).count(); println!("break, rank = count of sigma > 0: {}; noise-free log: {}", pos(&s), pos(&s0));
    println!("break, keep 1 value: test rms {:.4}; keep 6: test rms {:.4}", rms(&x1, &ate, yte), rms(&x6, &ate, yte));

    assert!((fbest - nrm(&s[3..])).abs() < 1e-10 * fa && fbest < ftrue && ftrue < fsub);   // Eckart-Young, Frobenius
    assert!((sp - s[3]).abs() < 1e-6 && (s[0] - norm2(&at)).abs() < 1e-9);                // Eckart-Young, spectral
    assert!((fa * fa - dot(&s, &s)).abs() < 1e-9 * fa * fa);                               // squares of entries
    assert!(wey <= ne && s[2] > tn && tn > ne && ne > s[3] && r_noise == 3 && r_round == 20);   // Weyl, the gap
    assert!(gap(&xs[0], &xf) < 1e-8 && gap(&x3b, &x3) < 1e-12);                              // two roads to each fit
    assert!(pen.iter().all(|&x| x < 1e-10) && f3s < ftrue && rms(&x3, &ate, yte) < rms(&xf, &ate, yte));
    println!("ALL CHECKS PASS");
}
