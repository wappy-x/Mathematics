// Daubechies D4: the four-tap filter from its conditions, and a day of air temperature.
// std only.  Roads to the filter: the quadratic solved by hand, Newton's method on the raw
// conditions, and the factored form multiplied out.  Roads to the coefficients: filtering,
// the Taylor prediction, and the energy ledger with exact rebuilding.
use std::f64::consts::PI;
fn fx(v: f64, d: i32) -> String { format!("{:.*}", d as usize, if v.abs() >= 0.5 * 10f64.powi(-d) { v } else { 0.0 }) }
fn row(xs: &[f64], d: i32) -> String { xs.iter().map(|&v| fx(v, d)).collect::<Vec<_>>().join(" ") }
fn solve(a: &[[f64; 4]; 4], b: &[f64; 4]) -> [f64; 4] { // Gaussian elimination with partial pivoting
    let n = 4;
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].to_vec(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in (c + 1)..n {
            let f = m[r][c] / m[c][c];
            for i in 0..=n { m[r][i] -= f * m[c][i]; }
        }
    }
    let mut x = [0.0; 4];
    for r in (0..n).rev() {
        x[r] = (m[r][n] - ((r + 1)..n).map(|i| m[r][i] * x[i]).sum::<f64>()) / m[r][r];
    }
    x
}
fn temp(t: f64) -> f64 { let u = 2.0 * PI * (t - 9.0) / 24.0; 16.0 + 6.0 * u.sin() + 1.5 * (2.0 * u).sin() }
fn temp2(t: f64) -> f64 { let (u, w) = (2.0 * PI * (t - 9.0) / 24.0, 2.0 * PI / 24.0); -w * w * (6.0 * u.sin() + 6.0 * (2.0 * u).sin()) }
fn step(z: &[f64], lo: &[f64], hi: &[f64]) -> (Vec<f64>, Vec<f64>) {
    let n = z.len();
    let f = |c: &[f64], k: usize| -> f64 { let mut s = 0.0; for m in 0..c.len() { s += c[m] * z[(2 * k + m) % n]; } s };
    ((0..n / 2).map(|k| f(lo, k)).collect(), (0..n / 2).map(|k| f(hi, k)).collect())
}
fn inv(a: &[f64], d: &[f64], lo: &[f64], hi: &[f64]) -> Vec<f64> {
    let n = 2 * a.len();
    let mut y = vec![0.0; n];
    for k in 0..a.len() { for m in 0..lo.len() { y[(2 * k + m) % n] += lo[m] * a[k] + hi[m] * d[k]; } }
    y
}
fn maxabs(v: &[f64]) -> f64 { v.iter().fold(0.0, |m: f64, x| m.max(x.abs())) }
fn count(v: &[f64], c: f64) -> usize { v.iter().filter(|x| x.abs() > c).count() }
fn main() {
    let (r2, r3) = (2f64.sqrt(), 3f64.sqrt());
    // road 1: h0 + h2 = h1 + h3 = s, moment gives h1 = h0 + s/2, orthogonality 2 h0^2 - s h0 - s^2/4 = 0
    let s = 1.0 / r2;
    let h0 = (s + (s * s + 2.0 * s * s).sqrt()) / 4.0;
    let h = [h0, h0 + s / 2.0, s - h0, s - h0 - s / 2.0];
    println!("D4 h, by the quadratic: {}", row(&h, 6));
    // road 2: Newton's method on the four conditions, from a rough start
    let mut v = [0.7, 0.0, 0.0, 0.0];
    for _ in 0..8 {
        let fv = [v.iter().sum::<f64>() - r2, v[0] - v[1] + v[2] - v[3], -3.0 * v[0] + 2.0 * v[1] - v[2], v[0] * v[2] + v[1] * v[3]];
        let j = [[1.0, 1.0, 1.0, 1.0], [1.0, -1.0, 1.0, -1.0], [-3.0, 2.0, -1.0, 0.0], [v[2], v[3], v[0], v[1]]];
        let dv = solve(&j, &fv); for i in 0..4 { v[i] -= dv[i]; }
    }
    println!("D4 h, by Newton's method: {}", row(&v, 6));
    assert!((0..4).all(|i| (h[i] - v[i]).abs() < 1e-12));
    // road 3: H(z) = sqrt2 ((1 + 1/z)/2)^2 (a + b/z), a = (1 + sqrt3)/2, b = (1 - sqrt3)/2
    let (a, b) = ((1.0 + r3) / 2.0, (1.0 - r3) / 2.0);
    let fac: Vec<f64> = [a, 2.0 * a + b, a + 2.0 * b, b].iter().map(|c| r2 / 4.0 * c).collect();
    println!("D4 h, factored form: {}", row(&fac, 6));
    assert!((0..4).all(|i| (h[i] - fac[i]).abs() < 1e-12));
    let g = [h[3], -h[2], h[1], -h[0]]; // g_n = (-1)^n h_(3-n)
    println!("g: {}", row(&g, 6));
    println!("sum h {:.9}  sum h^2 {:.9}  h0h2+h1h3 {}", h.iter().sum::<f64>(), h.iter().map(|x| x * x).sum::<f64>(),
             fx(h[0] * h[2] + h[1] * h[3], 9));
    let mom: Vec<f64> = (0..3).map(|p| (0..4).map(|m| g[m] * (m as f64).powi(p)).sum()).collect();
    println!("moments of g, p = 0, 1, 2: {}  C = half the p=2 moment {}", row(&mom, 6), fx(mom[2] / 2.0, 6));
    assert!(mom[0].abs() < 1e-12 && mom[1].abs() < 1e-12);
    assert!((mom[2] + 6f64.sqrt() / 2.0).abs() < 1e-12);
    // the scaling function at whole numbers: eigenvector of the refinement equation, by power iteration
    let (mut p1, mut p2) = (0.5, 0.5);
    for _ in 0..60 {
        let (q1, q2) = (r2 * (h[1] * p1 + h[0] * p2), r2 * (h[3] * p1 + h[2] * p2));
        p1 = q1 / (q1 + q2); p2 = q2 / (q1 + q2);
    }
    let mut phi = [0.0f64; 25]; // index in eighths
    phi[8] = p1; phi[16] = p2;
    let get = |ph: &[f64; 25], i: i64| -> f64 { if (0..25).contains(&i) { ph[i as usize] } else { 0.0 } };
    for st in [4usize, 2, 1] {
        for m in (st..24).step_by(2 * st) { phi[m] = r2 * (0..4).map(|n| h[n] * get(&phi, 2 * m as i64 - 8 * n as i64)).sum::<f64>(); }
    }
    let psi: Vec<f64> = (0..25).map(|m| r2 * (0..4).map(|n| g[n] * get(&phi, 2 * m as i64 - 8 * n as i64)).sum::<f64>()).collect();
    let (area, spsi) = (phi.iter().sum::<f64>() / 8.0, psi.iter().sum::<f64>());
    println!("phi(1) {:.6} closed form {:.6}   phi(2) {:.6} closed form {:.6}   eighths: area of phi {:.6}, sum of psi {}", p1, (1.0 + r3) / 2.0, p2, (1.0 - r3) / 2.0, area, fx(spsi, 6));
    assert!((p1 - (1.0 + r3) / 2.0).abs() < 1e-12);
    assert!((area - 1.0).abs() < 1e-12 && spsi.abs() < 1e-12 && (psi[12] - r3).abs() < 1e-12); // area 1, moment 0, psi(1.5) = sqrt3
    println!("chart t: {}", row(&(0..25).map(|m| m as f64 / 8.0).collect::<Vec<_>>(), 3));
    println!("chart phi: {}", row(&phi, 3));
    println!("chart psi: {}", row(&psi, 3));
    // the day: air temperature every 15 minutes, 96 readings, illustrative
    let dt = 0.25;
    let x: Vec<f64> = (0..96).map(|n| temp(n as f64 * dt)).collect();
    let (ha, ga) = ([s, s], [s, -s]);
    let ramp = [12.0, 12.5, 13.0, 13.5];
    println!("straight line 12.0 12.5 13.0 13.5: D4 detail {}  Haar details {} {}",
             fx((0..4).map(|m| g[m] * ramp[m]).sum(), 6), fx((ramp[0] - ramp[1]) * s, 6), fx((ramp[2] - ramp[3]) * s, 6));
    let q = &x[36..40];
    let prods: Vec<f64> = (0..4).map(|m| g[m] * q[m]).collect();
    println!("readings 9:00 to 9:45: {}  products g_m x_m: {}", row(q, 4), row(&prods, 6));
    println!("     D4 detail {}  Haar {}  prediction C x''(9.375) dt^2 {}", fx(prods.iter().sum(), 6), fx((q[0] - q[1]) * s, 6),
             fx(mom[2] / 2.0 * temp2(9.375) * dt * dt, 6));
    println!("day: {} readings every {} h, min {:.2} C  max {:.2} C  energy {:.4}", x.len(), dt, x.iter().cloned().fold(f64::MAX, f64::min),
             x.iter().cloned().fold(f64::MIN, f64::max), x.iter().map(|v| v * v).sum::<f64>());
    println!("j | D4 max|d|, Taylor error, count > 0.1 actual, predicted | Haar max|d|, count > 0.1");
    let full = |lo: &[f64], hi: &[f64]| -> (Vec<f64>, Vec<Vec<f64>>) {
        let (mut z, mut ds) = (x.clone(), Vec::new());
        for _ in 0..4 { let (a2, d2) = step(&z, lo, hi); z = a2; ds.push(d2); }
        (z, ds)
    };
    let (cd, ch) = (full(&h, &g), full(&ha, &ga));
    let (zd, zh) = (&cd.1, &ch.1);
    let nc = count(&cd.0, 0.1); let mut tot = [nc, nc]; // coarse averages count in both
    for j in 1..5 {
        let w = 2f64.powi(j - 1) * dt;
        let ju = j as usize;
        let pred: Vec<f64> = (0..zd[ju - 1].len()).map(|k| 2f64.powf((j - 1) as f64 / 2.0) * mom[2] / 2.0
            * temp2((2f64.powi(j) * k as f64 + 1.5 * (2f64.powi(j) - 1.0)) * dt) * w * w).collect();
        let err = maxabs(&pred.iter().zip(&zd[ju - 1]).map(|(p, q)| p - q).collect::<Vec<_>>());
        if j <= 2 { assert!(err < 0.01); }
        let (ca, cp) = (count(&zd[ju - 1], 0.1), count(&pred, 0.1)); tot = [tot[0] + ca, tot[1] + cp];
        println!("{} | {:.4} {:.4} {} {} | {:.4} {}", j, maxabs(&zd[ju - 1]), err, ca, cp,
                 maxabs(&zh[ju - 1]), count(&zh[ju - 1], 0.1));
    }
    println!("D4 coefficients above 0.1 C, the {} coarse averages included: actual {}, predicted {}", nc, tot[0], tot[1]);
    // fewest largest coefficients that rebuild every reading within 0.1 C
    let kterm = |c: &(Vec<f64>, Vec<Vec<f64>>), lo: &[f64], hi: &[f64]| -> (usize, f64, f64) {
        let mut all: Vec<f64> = c.1.iter().flatten().chain(c.0.iter()).map(|v| v.abs()).collect();
        all.sort_by(|p, q| q.partial_cmp(p).unwrap());
        let en: f64 = all.iter().map(|v| v * v).sum();
        for k in 1..97 {
            let cut = all[k - 1];
            let keep = |v: &[f64]| -> Vec<f64> { v.iter().map(|&u| if u.abs() >= cut { u } else { 0.0 }).collect() };
            let mut y = keep(&c.0);
            for d in c.1.iter().rev() { y = inv(&y, &keep(d), lo, hi); }
            let e = maxabs(&x.iter().zip(&y).map(|(p, q)| p - q).collect::<Vec<_>>());
            if e <= 0.1 { return (k, e, en); }
        }
        (0, 0.0, en)
    };
    let (kd, kh) = (kterm(&cd, &h, &g), kterm(&ch, &ha, &ga));
    for (name, kk) in [("D4", kd), ("Haar", kh)] {
        println!("{}: energy of coefficients {:.4}; keep the {} largest of 96, worst error {:.4} C", name, kk.2, kk.0, kk.1);
        assert!((kk.2 - x.iter().map(|v| v * v).sum::<f64>()).abs() < 1e-9);
    }
    assert!((kd.0 as f64) < kh.0 as f64 / 2.0);
    let x2: Vec<f64> = (0..192).map(|n| temp(n as f64 * dt / 2.0)).collect();
    let (m4, mh) = (maxabs(&step(&x2, &h, &g).1), maxabs(&step(&x2, &ha, &ga).1));
    println!("every 7.5 min: level-1 max D4 {:.4} (ratio {:.2})  Haar {:.4} (ratio {:.2})", m4, maxabs(&zd[0]) / m4, mh, maxabs(&zh[0]) / mh);
    assert!((maxabs(&zd[0]) / m4 - 4.0).abs() < 0.3 && (maxabs(&zh[0]) / mh - 2.0).abs() < 0.1);
    println!("chart hour: {}", row(&(0..48).map(|k| k as f64 / 2.0).collect::<Vec<_>>(), 1));
    println!("chart level-1 Haar: {}", row(&zh[0], 3));
    println!("chart level-1 D4: {}", row(&zd[0], 3));
    // what breaks
    let shower: Vec<f64> = x.iter().enumerate().map(|(n, v)| v - if (61..=64).contains(&n) { 3.0 } else { 0.0 }).collect();
    let ch4: Vec<f64> = step(&shower, &h, &g).1.iter().zip(&zd[0]).map(|(p, q)| (p - q).abs()).collect();
    let chh: Vec<f64> = step(&shower, &ha, &ga).1.iter().zip(&zh[0]).map(|(p, q)| (p - q).abs()).collect();
    println!("shower 15:15-16:00, 3 C colder: level-1 details changed by > 0.1: D4 {} (largest {:.4}), Haar {} (largest {:.4})",
             count(&ch4, 0.1), maxabs(&ch4), count(&chh, 0.1), maxabs(&chh));
    assert!(count(&ch4, 0.1) == 4 && count(&chh, 0.1) == 2);
    let dm = step(&x[24..48], &h, &g).1;
    println!("6:00-11:45 alone, wrapped: D4 level-1 largest inside {:.4}, wrap-around {}", maxabs(&dm[..11]), fx(dm[11], 4));
    assert!(dm[11].abs() > 10.0 * maxabs(&dm[..11]));
    let h3 = solve(&[[1.0, 1.0, 1.0, 1.0], [1.0, -1.0, 1.0, -1.0], [-3.0, 2.0, -1.0, 0.0], [-9.0, 4.0, -1.0, 0.0]], &[r2, 0.0, 0.0, 0.0]);
    println!("four taps, three moments: h {}  h0h2+h1h3 {}", row(&h3, 6), fx(h3[0] * h3[2] + h3[1] * h3[3], 6));
    assert!((h3[0] * h3[2] + h3[1] * h3[3]).abs() > 0.01);
    let gw = [h[0], -h[1], h[2], -h[3]]; // signs alternated, order not reversed
    let wrong = |y: &[f64]| { let (aw, dw) = step(y, &h, &gw); maxabs(&inv(&aw, &dw, &h, &gw).iter().zip(y).map(|(p, q)| p - q).collect::<Vec<_>>()) };
    println!("g not reversed: <h, g> {}  worst rebuild error {:.4} C, shower day {:.4} C", fx((0..4).map(|i| h[i] * gw[i]).sum(), 6), wrong(&x), wrong(&shower));
    println!("ALL CHECKS PASS");
}
