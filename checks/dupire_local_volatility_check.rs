// Dupire local volatility -- the same check as the Python, in Rust.  No crates.
// The normal CDF is Marsaglia's series written out; the forward equation is marched
// with a tridiagonal solver written out.  Nothing imported knows the answer.
use std::f64::consts::PI;

const S0: f64 = 100.0; // the house market, every call at 20%
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const H: f64 = 1.0; // grid steps: $1 in strike, 0.01 year in expiry
const DT: f64 = 0.01;

fn n_cdf(x: f64) -> f64 { // bell-curve area left of x, summed as a series
    if x < -10.0 { return 0.0; }
    if x > 10.0 { return 1.0; }
    let (mut s, mut t, mut b, q, mut i) = (x, 0.0, x, x * x, 1.0);
    while s != t { i += 2.0; b *= q / i; t = s; s = t + b; }
    0.5 + s * (-0.5 * q - 0.91893853320467274178).exp()
}

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } // bell-curve height at x

fn bs(s: f64, k: f64, t: f64, sig: f64) -> f64 { // the house call price at one volatility
    let v = sig * t.sqrt();
    let d1 = ((s / k).ln() + (R - Q + 0.5 * sig * sig) * t) / v;
    s * (-Q * t).exp() * n_cdf(d1) - k * (-R * t).exp() * n_cdf(d1 - v)
}

fn slopes<F: Fn(f64, f64) -> f64>(c: &F, k: f64, t: f64, h: f64, dt: f64) -> [f64; 4] { // road 1
    [c(k, t), (c(k, t + dt) - c(k, t - dt)) / (2.0 * dt), (c(k + h, t) - c(k - h, t)) / (2.0 * h),
     (c(k + h, t) - 2.0 * c(k, t) + c(k - h, t)) / (h * h)]
}

fn closed(k: f64, t: f64) -> ([f64; 4], f64) { // road 2: the house formula's own slopes
    let v = SIG * t.sqrt();
    let d1 = ((S0 / k).ln() + (R - Q + 0.5 * SIG * SIG) * t) / v;
    let d2 = d1 - v;
    let c = S0 * (-Q * t).exp() * n_cdf(d1) - k * (-R * t).exp() * n_cdf(d2);
    let ct = S0 * (-Q * t).exp() * phi(d1) * SIG / (2.0 * t.sqrt()) - Q * S0 * (-Q * t).exp() * n_cdf(d1)
        + R * k * (-R * t).exp() * n_cdf(d2);
    let gamma = (-Q * t).exp() * phi(d1) / (S0 * v); // spot gamma, for the mistake table
    ([c, ct, -(-R * t).exp() * n_cdf(d2), (-R * t).exp() * phi(d2) / (k * v)], gamma)
}

fn parts(p: &[f64; 4], k: f64) -> [f64; 4] { // carry terms, numerator, denominator
    [(R - Q) * k * p[2], Q * p[0], p[1] + (R - Q) * k * p[2] + Q * p[0], 0.5 * k * k * p[3]]
}

fn dupire(p: &[f64; 4], k: f64) -> f64 { let a = parts(p, k); a[2] / a[3] } // local variance

fn march(sig: f64, per: usize, half: usize, steps: usize) -> (Vec<f64>, Vec<Vec<f64>>, f64, f64) { // road 3
    let dx = 1.1_f64.ln() / per as f64; // log-strike step; $100 and $110 are both nodes
    let x: Vec<f64> = (0..=2 * half).map(|j| S0.ln() + (j as f64 - half as f64) * dx).collect();
    let mut u: Vec<f64> = x.iter().map(|xj| (S0 - xj.exp()).max(0.0)).collect(); // the payoff
    let (a, dt) = (0.5 * sig * sig, 1.0 / steps as f64);
    let b = a + (R - Q); // C_T = a (u_xx - u_x) - (r - q) u_x - q u
    let (lo, di, up) = (a / dx / dx + b / (2.0 * dx), -2.0 * a / dx / dx - Q, a / dx / dx - b / (2.0 * dx));
    let mut snaps = vec![u.clone()];
    for n in 1..steps + 2 {
        let (th, t) = (if n <= 4 { 1.0 } else { 0.5 }, n as f64 * dt); // implicit, then Crank-Nicolson
        let mut rhs: Vec<f64> = (1..u.len() - 1)
            .map(|j| u[j] + (1.0 - th) * dt * (lo * u[j - 1] + di * u[j] + up * u[j + 1])).collect();
        let left = S0 * (-Q * t).exp() - x[0].exp() * (-R * t).exp();
        let (aa, bb, cc) = (-th * dt * lo, 1.0 - th * dt * di, -th * dt * up);
        rhs[0] -= aa * left;
        let (mut cp, mut dp) = (vec![cc / bb], vec![rhs[0] / bb]); // Thomas algorithm
        for i in 1..rhs.len() {
            let m = bb - aa * cp[i - 1];
            cp.push(cc / m);
            dp.push((rhs[i] - aa * dp[i - 1]) / m);
        }
        for i in (0..rhs.len() - 1).rev() { dp[i] -= cp[i] * dp[i + 1]; }
        u = [vec![left], dp, vec![0.0]].concat();
        snaps.push(u.clone());
    }
    (x, snaps, dx, dt)
}

fn read_marched(snaps: &[Vec<f64>], n: usize, j: usize, k: f64, dx: f64, dt: f64) -> f64 {
    let u = &snaps[n]; // Dupire on the marched grid, in log strike
    let (ux, uxx) = ((u[j + 1] - u[j - 1]) / (2.0 * dx), (u[j + 1] - 2.0 * u[j] + u[j - 1]) / (dx * dx));
    let ct = (snaps[n + 1][j] - snaps[n - 1][j]) / (2.0 * dt);
    dupire(&[u[j], ct, ux / k, (uxx - ux) / (k * k)], k)
}

fn row(name: &str, vals: &[f64], d: usize, w: usize) {
    let mut s = format!("{:<42}", name);
    for v in vals { s.push_str(&format!("{:>w$.d$}", v, w = w, d = d)); }
    println!("{}", s);
}

fn main() {
    let flat = |k: f64, t: f64| bs(S0, k, t, SIG);
    let pts = [(100.0, 1.0), (110.0, 0.5)];
    let g1: Vec<[f64; 4]> = pts.iter().map(|&(k, t)| slopes(&flat, k, t, H, DT)).collect();
    let g2: Vec<[f64; 4]> = pts.iter().map(|&(k, t)| closed(k, t).0).collect();
    println!("house market: S 100, r 0.05, q 0.02, every call at 20%; grid steps h {}, dt {}", H, DT);
    println!("{:<42}{:>12}{:>12}", "", "(100, 1)", "(110, 0.5)");
    let calls: [(&str, f64, f64); 5] = [("call C(K - h, T)", -H, 0.0), ("call C(K, T)", 0.0, 0.0),
        ("call C(K + h, T)", H, 0.0), ("call C(K, T - dt)", 0.0, -DT), ("call C(K, T + dt)", 0.0, DT)];
    for (name, dk, dt) in calls { row(name, &pts.map(|(k, t)| flat(k + dk, t + dt)), 6, 12); }
    println!("road 1: differences on the grid above; road 2: the house formula's own slopes");
    for (road, g) in [("road 1", &g1), ("road 2", &g2)] {
        for (i, nm) in [(1, "C_T"), (2, "C_K"), (3, "C_KK")] {
            row(&format!("{}: {}", road, nm), &[g[0][i], g[1][i]], 6, 12);
        }
        for (i, nm) in [(0, "(r - q) K C_K"), (1, "q C"), (2, "numerator"), (3, "denominator 0.5 K^2 C_KK")] {
            row(&format!("{}: {}", road, nm), &[parts(&g[0], 100.0)[i], parts(&g[1], 110.0)[i]], 6, 12);
        }
        row(&format!("{}: local variance", road), &[dupire(&g[0], 100.0), dupire(&g[1], 110.0)], 6, 12);
        row(&format!("{}: local vol", road), &[dupire(&g[0], 100.0).sqrt(), dupire(&g[1], 110.0).sqrt()], 6, 12);
    }
    row("road 1: local vol to four places", &[dupire(&g1[0], 100.0).sqrt(), dupire(&g1[1], 110.0).sqrt()], 4, 12);
    row("density p = e^{rT} C_KK, closed form", &[(R * 1.0).exp() * g2[0][3], (R * 0.5).exp() * g2[1][3]], 6, 12);

    let (x, snaps, dx, dt) = march(SIG, 40, 600, 400); // 1,201 log strikes, 600 either side of $100
    let jm = [600usize, 640]; // the nodes at $100 and $110
    let ns: Vec<usize> = pts.iter().map(|&(_, t)| (t / dt).round() as usize).collect();
    println!("road 3: forward equation marched from the payoff at 20%, {} strikes, {} steps a year",
             x.len(), (1.0 / dt).round());
    row("road 3: call, marched", &[snaps[ns[0]][jm[0]], snaps[ns[1]][jm[1]]], 6, 12);
    row("road 3: call, house formula", &pts.map(|(k, t)| flat(k, t)), 6, 12);
    let lv3: Vec<f64> = (0..2).map(|i| read_marched(&snaps, ns[i], jm[i], x[jm[i]].exp(), dx, dt).sqrt()).collect();
    row("road 3: local vol read off marched prices", &lv3, 6, 12);

    let (dsh, sd) = (100.0_f64, 0.10_f64); // second case: stock + $100 cushion moves like the house at 10%
    let cushion = |k: f64, t: f64| bs(S0 + dsh, k + dsh * ((R - Q) * t).exp(), t, sd);
    let truth = |k: f64, t: f64| sd * (k + dsh * ((R - Q) * t).exp()) / k;
    let ks = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0];
    let read2: Vec<f64> = ks.iter().map(|&k| dupire(&slopes(&cushion, k, 1.0, H, DT), k).sqrt()).collect();
    let read_flat: Vec<f64> = ks.iter().map(|&k| dupire(&slopes(&flat, k, 1.0, H, DT), k).sqrt()).collect();
    println!("second case: local vol in percent at T = 1, strikes 70 to 130 in steps of 10");
    row("cushioned stock, read off its call prices", &read2.iter().map(|v| 100.0 * v).collect::<Vec<_>>(), 2, 7);
    row("cushioned stock, known in advance", &ks.map(|k| 100.0 * truth(k, 1.0)), 2, 7);
    row("flat 20% surface, read off its call prices", &read_flat.iter().map(|v| 100.0 * v).collect::<Vec<_>>(), 2, 7);

    let (p100, _) = closed(100.0, 1.0);
    let (c, ct, ck) = (p100[0], p100[1], p100[2]);
    let a = parts(&p100, 100.0);
    let (num, den) = (a[2], a[3]);
    let (p110, gam110) = closed(110.0, 0.5);
    row("wrong: drop the 1/2 in the denominator", &[(num / (2.0 * den)).sqrt()], 6, 12);
    row("wrong: zero-rate formula on today's prices", &[(ct / den).sqrt()], 6, 12);
    row("wrong: leave out q C", &[((num - Q * c) / den).sqrt()], 6, 12);
    row("wrong: flip the sign of (r - q) K C_K", &[((num - 2.0 * (R - Q) * 100.0 * ck) / den).sqrt()], 6, 12);
    row("wrong: spot gamma for C_KK at (110, 0.5)", &[(parts(&p110, 110.0)[2] / (0.5 * 110.0_f64.powi(2) * gam110)).sqrt()], 6, 12);
    row("try: desk grid h 5, dt 0.25, at (100, 1)", &[dupire(&slopes(&flat, 100.0, 1.0, 5.0, 0.25), 100.0).sqrt()], 6, 12);
    row("try: half the steps, h 0.5, dt 0.005", &[dupire(&slopes(&flat, 100.0, 1.0, 0.5, 0.005), 100.0).sqrt()], 6, 12);
    let vol30 = |k: f64, t: f64| bs(S0, k, t, 0.3);
    row("try: every call at 30%, read at (110, 0.5)", &[dupire(&slopes(&vol30, 110.0, 0.5, H, DT), 110.0).sqrt()], 6, 12);
    let edge = slopes(&flat, 60.0, 0.1, H, DT);
    println!("{:<42}{:>12}", "edge: C_KK by differences at (60, 0.1)", format!("{:.3e}", edge[3]));
    row("edge: local variance there", &[dupire(&edge, 60.0)], 2, 12);

    assert!((dupire(&g1[0], 100.0).sqrt() - SIG).abs() < 1e-4, "road 1 at (100, 1) hands back 20%");
    assert!((dupire(&g1[1], 110.0).sqrt() - SIG).abs() < 1e-4, "road 1 at (110, 0.5) hands back 20%");
    assert!((0..2).all(|i| (dupire(&g2[i], pts[i].0) - SIG * SIG).abs() < 1e-12), "road 2: exact");
    assert!((0..2).all(|i| (snaps[ns[i]][jm[i]] - flat(pts[i].0, pts[i].1)).abs() < 5e-4), "road 3 prices");
    assert!(lv3.iter().all(|v| (v - SIG).abs() < 1e-4), "road 3: read back off marched prices");
    assert!(read2.iter().zip(ks.iter()).all(|(v, &k)| (v - truth(k, 1.0)).abs() < 1e-4), "second case");
    println!("ALL CHECKS PASS");
}
