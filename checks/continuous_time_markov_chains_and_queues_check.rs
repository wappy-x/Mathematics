// Continuous-time chains and the M/M/1 queue -- the check behind the card.  std only.
// One server; calls arrive at 4 an hour; a service ends at rate 5 an hour.  Time is in hours.
// Roads: closed forms; Euler steps; uniformization; a generic solve of pi G = 0; the jump chain
// reweighted by holding times; seeded simulations with standard errors.
const LAM: f64 = 4.0;
const MU: f64 = 5.0;
const SEED: u64 = 20260929;
const RHO: f64 = LAM / MU;
type M = Vec<Vec<f64>>;
struct SplitMix64(u64);
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn expo(&mut self, rate: f64) -> f64 { -(1.0 - self.uniform()).ln() / rate } // a holding time, in hours
}
fn gen(cap: usize, lam: f64, mu: f64) -> M { // generator G of one server with room for cap in the system
    let mut g = vec![vec![0.0; cap + 1]; cap + 1];
    for n in 0..=cap {
        if n < cap { g[n][n + 1] = lam; }
        if n > 0 { g[n][n - 1] = mu; }
        g[n][n] = -g[n].iter().fold(0.0, |s, x| s + x);
    }
    g
}
fn solve(a: &M, b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = a.len();
    let mut m: M = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut piv = c;
        for r in c + 1..n { if m[r][c].abs() > m[piv][c].abs() { piv = r; } }
        m.swap(c, piv);
        for r in c + 1..n {
            let f = m[r][c] / m[c][c];
            if f != 0.0 { for k in c..=n { m[r][k] -= f * m[c][k]; } }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let s = (i + 1..n).fold(0.0, |s, k| s + m[i][k] * x[k]);
        x[i] = (m[i][n] - s) / m[i][i];
    }
    x
}
fn stationary(g: &M) -> Vec<f64> { // pi G = 0, last equation swapped for "shares add to 1"
    let n = g.len();
    let mut a: M = (0..n).map(|j| (0..n).map(|i| g[i][j]).collect()).collect();
    a[n - 1] = vec![1.0; n];
    let mut b = vec![0.0; n]; b[n - 1] = 1.0;
    solve(&a, &b)
}
fn unif(lam: f64, mu: f64, cap: usize, times: &[f64], kmax: usize) -> M { // sum_k e^(-Ct) (Ct)^k / k! p(0) K^k
    let c = lam + mu;
    let mut v = vec![0.0; cap + 1];
    v[0] = 1.0; // start empty
    let mut w: Vec<f64> = times.iter().map(|t| (-c * t).exp()).collect();
    let mut out: M = w.iter().map(|wi| v.iter().map(|x| wi * x).collect()).collect();
    for k in 1..=kmax {
        v = (0..=cap).map(|n| v[n] * (1.0 - (if n < cap { lam } else { 0.0 }) / c - (if n > 0 { mu } else { 0.0 }) / c)
            + (if n > 0 { v[n - 1] * lam / c } else { 0.0 }) + (if n < cap { v[n + 1] * mu / c } else { 0.0 })).collect();
        for i in 0..times.len() {
            w[i] *= c * times[i] / k as f64;
            for n in 0..=cap { out[i][n] = out[i][n] + w[i] * v[n]; }
        }
    }
    out
}
fn exact(t: f64) -> f64 { LAM / (LAM + MU) * (1.0 - (-(LAM + MU) * t).exp()) }
fn mean(p: &[f64]) -> f64 { p.iter().enumerate().fold(0.0, |s, (k, x)| s + k as f64 * x) }
fn mse(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64;
    let m = xs.iter().fold(0.0, |s, x| s + x) / n;
    (m, (xs.iter().fold(0.0, |s, x| s + (x - m).powi(2)) / (n - 1.0) / n).sqrt())
}
fn j(v: &[f64], scale: f64) -> String { v.iter().map(|x| format!("{:.2}", scale * x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let g2 = gen(1, LAM, MU);
    println!("two-state G, rows idle, busy: {}", g2.iter().map(|r| r.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(", ")).collect::<Vec<_>>().join("; "));
    println!("road 1, closed form, busy from idle: 6 min {:.4}, 15 min {:.4}, long run 4/9 = {:.4}", exact(0.1), exact(0.25), LAM / (LAM + MU));
    println!("half-way to 4/9 after ln 2 / 9 hours = {:.2} min; served per hour {:.2}", 60.0 * 2f64.ln() / (LAM + MU), LAM * MU / (LAM + MU));
    let mut errs = Vec::new();
    for steps in [5usize, 10, 20, 40, 80] {
        let (h, mut p) = (0.25 / steps as f64, [1.0, 0.0]);
        for _ in 0..steps { p = [p[0] + h * (p[0] * g2[0][0] + p[1] * g2[1][0]), p[1] + h * (p[0] * g2[0][1] + p[1] * g2[1][1])]; }
        errs.push((p[1] - exact(0.25)).abs());
        println!("road 2, Euler step {:.4} min: busy at 15 min {:.6}, error {:.6}", 60.0 * h, p[1], errs[errs.len() - 1]);
    }
    assert!(errs[4] < errs[0] / 10.0); // first-order method, step 16 times smaller
    let u2 = unif(LAM, MU, 1, &[0.25], 40)[0][1];
    println!("road 3, uniformization, busy at 15 min: {:.10}; closed form {:.10}", u2, exact(0.25));
    assert!((u2 - exact(0.25)).abs() < 1e-12);
    let (mut g, r, mut busy) = (SplitMix64(SEED), 100000usize, 0usize);
    for _ in 0..r {
        let (mut t, mut s) = (0.0, 0usize);
        loop {
            t += g.expo(if s == 0 { LAM } else { MU });
            if t > 0.25 { break; }
            s = 1 - s;
        }
        busy += s;
    }
    let ph = busy as f64 / r as f64;
    let se = (busy as f64 / r as f64 * (1.0 - busy as f64 / r as f64) / r as f64).sqrt();
    println!("road 4, simulated busy at 15 min, {} runs: {:.4} +- {:.4}", r, ph, se);
    assert!((ph - exact(0.25)).abs() < 4.0 * se);
    let nu2 = stationary(&(0..2).map(|i| (0..2).map(|k| g2[i][k] / -g2[i][i]).collect()).collect());
    println!("jump chain of the two-state server, visit shares: {:.4}, {:.4}; divided by leaving rates and rescaled: {:.4}, {:.4}",
        nu2[0], nu2[1], nu2[0] / LAM / (nu2[0] / LAM + nu2[1] / MU), nu2[1] / MU / (nu2[0] / LAM + nu2[1] / MU));
    let (cap, gm) = (119usize, gen(119, LAM, MU));
    let pi = stationary(&gm);
    let geo: Vec<f64> = (0..=cap).map(|n| (1.0 - RHO) * RHO.powf(n as f64)).collect();
    println!("figure, road 1, geometric law per 100, n = 0..10: {}", j(&geo[..11], 100.0));
    println!("road 2, generic solve of pi G = 0 on 120 states, per 100: {}", j(&pi[..11], 100.0));
    assert!((0..=cap).fold(0.0f64, |m, n| m.max((pi[n] - geo[n]).abs())) < 1e-9);
    let q: Vec<f64> = (0..=cap).map(|i| -gm[i][i]).collect();
    let nu = stationary(&(0..=cap).map(|i| (0..=cap).map(|k| gm[i][k] / q[i]).collect()).collect());
    let tot = (0..=cap).fold(0.0, |s, i| s + nu[i] / q[i]);
    println!("road 3, jump chain: idle share of visits {:.4}, of time after dividing by leaving rates {:.4}", nu[0], nu[0] / q[0] / tot);
    assert!((nu[0] / q[0] / tot - (1.0 - RHO)).abs() < 1e-9);
    let (l, tail) = (mean(&pi), 1.0 - pi[..10].iter().fold(0.0, |s, x| s + x));
    println!("busy {:.4}; mean in system L: formula {:.4}, solve {:.4}; waiting (not in service) {:.4}", 1.0 - pi[0], RHO / (1.0 - RHO), l, l - (1.0 - pi[0]));
    println!("P(X >= 5) {:.4}; P(X >= 10): formula {:.4}, solve {:.4}; Little: W = L / lam = {:.4} h", RHO.powf(5.0), RHO.powf(10.0), tail, l / LAM);
    let (mut g, mut n, bn, tt) = (SplitMix64(SEED + 1), 0usize, 100usize, 1000.0);
    let (mut bb, mut bl, mut bt, mut occ) = (Vec::new(), Vec::new(), Vec::new(), (0..bn).map(|_| [0.0f64; 11]).collect::<Vec<_>>());
    for b in 0..bn {
        let (mut t, mut sb, mut sl, mut st) = (0.0, 0.0, 0.0, 0.0);
        loop {
            let rate = LAM + if n > 0 { MU } else { 0.0 };
            let mut h = g.expo(rate);
            let last = h >= tt - t;
            if last { h = tt - t; }
            sb += if n > 0 { h } else { 0.0 }; sl += h * n as f64; st += if n >= 10 { h } else { 0.0 };
            if n <= 10 { occ[b][n] += h; }
            if last { break; }
            t += h;
            if n == 0 || g.uniform() < LAM / rate { n += 1; } else { n -= 1; }
        }
        bb.push(sb / tt); bl.push(sl / tt); bt.push(st / tt);
    }
    let ((mb, sb), (ml, sl), (mt, st)) = (mse(&bb), mse(&bl), mse(&bt));
    println!("road 4, simulated {:.0} hours ({} blocks of {:.0}): busy {:.4} +- {:.4}, L {:.3} +- {:.3}, P(X >= 10) {:.4} +- {:.4}", bn as f64 * tt, bn, tt, mb, sb, ml, sl, mt, st);
    println!("figure, road 4, simulated share of time per 100, n = 0..10: {}", (0..11).map(|k| format!("{:.2}", 100.0 * occ.iter().map(|o| o[k]).sum::<f64>() / (bn as f64 * tt))).collect::<Vec<_>>().join(", "));
    println!("road 4, block standard error of each share, per 100, n = 0..10: {}", j(&(0..11).map(|k| mse(&occ.iter().map(|o| o[k] / tt).collect::<Vec<_>>()).1).collect::<Vec<_>>(), 100.0));
    assert!((mb - RHO).abs() < 4.0 * sb);
    assert!((ml - RHO / (1.0 - RHO)).abs() < 4.0 * sl);
    println!("push lam to 4.5, 4.75, 4.9: rho {}", [4.5, 4.75, 4.9].iter().map(|a| format!("{:.2} gives L {:.2}", a / MU, a / MU / (1.0 - a / MU))).collect::<Vec<_>>().join(", "));
    let times = [0.0, 0.5, 1.0, 2.0, 4.0, 8.0, 12.0, 16.0, 24.0];
    let tr = unif(LAM, MU, 450, &times, 420);
    println!("figure, M/M/1 from empty, busy per 100 at hours 0, 0.5, 1, 2, 4, 8, 12, 16, 24: {}", tr.iter().map(|p| format!("{:.2}", 100.0 * (1.0 - p[0]))).collect::<Vec<_>>().join(", "));
    println!("figure, two-state from idle, busy per 100 at the same hours: {}", times.iter().map(|&t| format!("{:.2}", 100.0 * exact(t))).collect::<Vec<_>>().join(", "));
    println!("M/M/1 from empty, mean in system at 8 h {:.2}, at 24 h {:.2}", mean(&tr[5]), mean(&tr[8]));
    let un = unif(5.5, MU, 450, &[12.0, 24.0], 450);
    println!("mistake, lam 5.5 > mu: formula L = {:.2}; true mean from empty at 12 h {:.2}, at 24 h {:.2}", 5.5 / MU / (1.0 - 5.5 / MU), mean(&un[0]), mean(&un[1]));
    for (lam, refp, t) in [(LAM, &tr[5], 8.0), (LAM, &tr[8], 24.0), (5.5, &un[0], 12.0), (5.5, &un[1], 24.0)] { // road 2 for the transient: Euler on the same 451 states
        let mut p = vec![0.0f64; 451]; p[0] = 1.0;
        for _ in 0..(500.0 * t) as usize { p = (0..451).map(|n| p[n] + 0.002 * ((if n > 0 { p[n - 1] * lam } else { 0.0 }) + (if n < 450 { p[n + 1] * MU } else { 0.0 }) - p[n] * ((if n < 450 { lam } else { 0.0 }) + (if n > 0 { MU } else { 0.0 })))).collect(); }
        let gap = p.iter().zip(refp.iter()).fold(0.0f64, |m, (x, y)| m.max((x - y).abs()));
        println!("road 2 for the transient, Euler step 0.002 h, arrivals {:.2}, empty to {:.0} h: mean in system {:.2}, largest gap to uniformization in any state's chance {:.6}", lam, t, mean(&p), gap);
        assert!(gap < 1e-4 && (mean(&p) - mean(refp)).abs() < 1e-3);
    }
    println!("mistake, I + G read as one-hour chances, idle row: {:.1}, {:.1}; true one-hour row {:.4}, {:.4}", 1.0 + g2[0][0], g2[0][1], 1.0 - exact(1.0), exact(1.0));
    println!("mistake, rho as the busy share with no waiting room: {:.4}; true {:.4}", RHO, LAM / (LAM + MU));
    let rr: Vec<f64> = (0..5).map(|k| 24.0 * (pi[k] / pi[0]).sqrt()).collect();
    println!("figure, circle radius 24 sqrt(pi_n / pi_0), n = 0..4: {}; centres x 32, 102, 172, 242, 312, y 110", j(&rr, 1.0));
    println!("ALL CHECKS PASS");
}
