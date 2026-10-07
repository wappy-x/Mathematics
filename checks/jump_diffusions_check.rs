// Jump diffusions -- the same check as jump_diffusions_check.py, in Rust.  Std only, no crates.
// An electricity price, $50 a megawatt-hour, follows Merton's rule with time in days:
// dS = mu S dt + sigma S dW + S(Y - 1) dN, spikes at 0.1 a day, log Y ~ normal(0.30, 0.10^2).
// Roads: Ito's lemma with a jump term; the Poisson mixture (condition on the number
// of spikes, no jump term from Ito); 4000 seeded paths on nested grids, checked path by path.
use std::f64::consts::PI;

const S0: f64 = 50.0;
const SIG: f64 = 0.03;
const LAM: f64 = 0.1;
const MJ: f64 = 0.30;
const DJ: f64 = 0.10;
const T: f64 = 30.0;
const SEED: u64 = 20260930;
const PATHS: usize = 4000;
const FINE: usize = 480;
const GRIDS: [usize; 3] = [30, 120, 480];

struct SplitMix64 { s: u64 }                      // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                 // Box-Muller, cosine half
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn ncdf(x: f64) -> f64 {                          // bell-curve area left of x, Simpson's rule
    let n = 2000;
    let h = x / n as f64;
    let mut s = phi(0.0) + phi(x);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * phi(i as f64 * h); }
    0.5 + s * h / 3.0
}

fn main() {
    let k = (MJ + 0.5 * DJ * DJ).exp() - 1.0;    // the average spike adds k of the price
    let mu = -LAM * k;                            // the compensator: average price stays flat
    let c = mu - 0.5 * SIG * SIG;                 // log drift between spikes, per day
    let ey2 = (2.0 * MJ + 2.0 * DJ * DJ).exp();   // average squared spike factor
    let pf = PATHS as f64;
    println!("price: S0 {:.0} dollars/MWh, sigma {:.2} per root day, T {:.0} days", S0, SIG, T);
    println!("spikes: rate {:.1} a day, log size mean {:.2} sd {:.2}; k = E[Y] - 1 = {:.6}", LAM, MJ, DJ, k);
    println!("compensated drift mu = -lambda k {:.6} a day; log drift between spikes {:.6}", mu, c);
    let m1 = c * T + LAM * T * MJ;
    let v1 = SIG * SIG * T + LAM * T * (MJ * MJ + DJ * DJ);
    let mean1 = S0 * ((mu + LAM * k) * T).exp();
    let sq1 = S0 * S0 * ((2.0 * mu + SIG * SIG + LAM * (ey2 - 1.0)) * T).exp();
    println!("road 1, Ito with jumps: E log(S_T/S0) {:.6}  Var {:.6}  typical price {:.2}", m1, v1, S0 * m1.exp());
    println!("road 1, Ito with jumps: E S_T {:.4}  E S_T^2 {:.4}  sd S_T {:.4}", mean1, sq1, (sq1 - mean1 * mean1).sqrt());

    println!("by hand: delta^2/2 {:.6}  sigma^2/2 {:.6}  c T {:.6}  lambda T {:.1}  lambda T mu_J {:.6}  lambda k {:.6}",
             0.5 * DJ * DJ, 0.5 * SIG * SIG, c * T, LAM * T, LAM * T * MJ, LAM * k);
    println!("by hand: sigma^2 T {:.6}  mu_J^2 {:.6}  delta^2 {:.6}  lambda T (mu_J^2 + delta^2) {:.6}",
             SIG * SIG * T, MJ * MJ, DJ * DJ, LAM * T * (MJ * MJ + DJ * DJ));
    println!("by hand: E[Y^2] {:.6}  2 mu {:.6}  sigma^2 {:.6}  lambda (E[Y^2] - 1) {:.6}  E S_T^2 exponent {:.6}  S0^2 {:.0}",
             ey2, 2.0 * mu, SIG * SIG, LAM * (ey2 - 1.0), (2.0 * mu + SIG * SIG + LAM * (ey2 - 1.0)) * T, S0 * S0);
    println!("by hand: per spike E[Y - 1 - J] {:.6}  E[(Y - 1)^2] {:.6}", k - MJ, ey2 - 2.0 * (1.0 + k) + 1.0);

    let (mut w, mut m2, mut e2, mut mean2, mut sq2, mut up2) = ((-LAM * T).exp(), 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    let (mut weights, mut cond) = (Vec::new(), Vec::new());
    for n in 0..40 {                              // condition on n spikes: log S_T is normal
        let (mn, vn) = (c * T + n as f64 * MJ, SIG * SIG * T + n as f64 * DJ * DJ);
        weights.push(w); cond.push(S0 * (mn + 0.5 * vn).exp());
        m2 += w * mn; e2 += w * (vn + mn * mn);
        mean2 += w * S0 * (mn + 0.5 * vn).exp(); sq2 += w * S0 * S0 * (2.0 * mn + 2.0 * vn).exp();
        up2 += w * ncdf(mn / vn.sqrt());
        w *= LAM * T / (n + 1) as f64;
    }
    let v2 = e2 - m2 * m2;
    let wl: Vec<String> = weights[..5].iter().map(|x| format!("{:.4}", x)).collect();
    println!("road 2, Poisson mixture: chance of 0, 1, 2, 3, 4 spikes {}", wl.join(" "));
    println!("road 2, Poisson mixture: E log(S_T/S0) {:.6}  Var {:.6}", m2, v2);
    println!("road 2, Poisson mixture: E S_T {:.4}  E S_T^2 {:.4}  chance S_T > 50 {:.4}", mean2, sq2, up2);
    println!("road 2, Poisson mixture: 5 or more spikes: chance {:.4}, share of E S_T {:.4}", weights[5..].iter().sum::<f64>(),
             weights[5..].iter().zip(&cond[5..]).map(|(a, b)| a * b).sum::<f64>() / mean2);

    let ey1 = (MJ + 0.5 * DJ * DJ).exp();
    println!("what breaks, E log(S_T/S0):");
    println!("  drop the jump term                {:+.6}", c * T);
    println!("  slope times the jump, Y - 1       {:+.6}", c * T + LAM * T * k);
    println!("  Taylor to second order on a jump  {:+.6}", c * T + LAM * T * (k - 0.5 * (ey2 - 2.0 * ey1 + 1.0)));
    println!("  no compensator, mu = 0: E S_T {:.2} instead of {:.2}", S0 * (LAM * k * T).exp(), mean2);
    let cut: Vec<String> = [1e-2f64, 1e-4, 1e-6, 1e-8].iter().map(|e| format!("{:.1}", 2.0 * (e.powf(-0.5) - 1.0))).collect();
    println!("  infinitely many jumps, nu = x^-2.5 dx on (0,1), no compensator, mean jump sum a day, cut 1e-2 to 1e-8: {}", cut.join(" "));

    let mut g = SplitMix64 { s: SEED };
    let mut gap = [[0.0f64; 4]; 3];               // |Euler log - Ito with jumps|, |Euler log - slope rule|, squares
    let mut tot = [0.0f64; 5];                    // S, S^2, log, log^2, count above 50
    let (mut daily, mut qv, mut qv_target) = (Vec::new(), 0.0f64, 0.0f64);
    let mut spikes1: Vec<(f64, f64)> = Vec::new();
    for p in 0..PATHS {
        let (mut jumps, mut t): (Vec<(f64, f64)>, f64) = (Vec::new(), 0.0);
        loop {                                    // spike times: exponential gaps at rate lambda
            t += -(1.0 - g.uniform()).ln() / LAM;
            if t >= T { break; }
            jumps.push((t, MJ + DJ * g.normal()));
        }
        let dw: Vec<f64> = (0..FINE).map(|_| g.normal() * (T / FINE as f64).sqrt()).collect();
        let wt: f64 = dw.iter().sum();
        let ito = c * T + SIG * wt + jumps.iter().map(|&(_, j)| j).sum::<f64>();
        let slope = c * T + SIG * wt + jumps.iter().map(|&(_, j)| j.exp() - 1.0).sum::<f64>();
        let (mut s, mut lg) = (S0, 0.0f64);
        for (gi, &n) in GRIDS.iter().enumerate() {
            let (m, dt) = (FINE / n, T / n as f64);
            s = S0;
            let mut jstep = vec![0.0f64; n];
            for &(tj, j) in jumps.iter() { jstep[(tj * n as f64 / T) as usize] += j; }
            for kk in 0..n {
                let before = s;
                let step: f64 = dw[kk * m..(kk + 1) * m].iter().sum();
                s *= (1.0 + mu * dt + SIG * step) * jstep[kk].exp();
                if p == 0 && n == FINE {
                    qv += (s / before).ln().powi(2);
                    if kk % 16 == 0 { daily.push(before); }
                }
            }
            lg = (s / S0).ln();
            let (d1, d2) = ((lg - ito).abs(), (lg - slope).abs());
            gap[gi][0] += d1; gap[gi][1] += d2; gap[gi][2] += d1 * d1; gap[gi][3] += d2 * d2;
        }
        if p == 0 {
            daily.push(s);
            qv_target = SIG * SIG * T + jumps.iter().map(|&(_, j)| j * j).sum::<f64>();
            spikes1 = jumps.clone();
        }
        tot[0] += s; tot[1] += s * s; tot[2] += lg; tot[3] += lg * lg; tot[4] += if s > S0 { 1.0 } else { 0.0 };
    }

    let se = |s: f64, s2: f64| ((s2 / pf - (s / pf) * (s / pf)) / pf).sqrt();   // standard error of an average
    println!("road 3, {} seeded paths (seed {}), Euler steps with spikes applied exactly:", PATHS, SEED);
    for (gi, &n) in GRIDS.iter().enumerate() {
        println!("  {:2} steps a day   |gap to Ito with jumps| {:.5} (se {:.5})   |gap to slope rule| {:.5} (se {:.5})",
                 n / 30, gap[gi][0] / pf, se(gap[gi][0], gap[gi][2]), gap[gi][1] / pf, se(gap[gi][1], gap[gi][3]));
    }
    let (ms, ml, se_s, se_l) = (tot[0] / pf, tot[2] / pf, se(tot[0], tot[1]), se(tot[2], tot[3]));
    let fr = tot[4] / pf;
    let se_f = (fr * (1.0 - fr) / pf).sqrt();
    println!("  16 steps a day: mean S_T {:.2} (se {:.2})", ms, se_s);
    println!("  16 steps a day: mean log {:.4} (se {:.4}), above 50 {:.4} (se {:.4})", ml, se_l, fr, se_f);
    let sp: Vec<String> = spikes1.iter().map(|&(tj, j)| format!("{:.2} {:+.4}", tj, j)).collect();
    println!("path 1 spikes, day and log size: {}", sp.join("  "));
    println!("path 1 quadratic variation of log S: grid sum {:.5}, sigma^2 T + sum J^2 {:.5}", qv, qv_target);
    let days: Vec<String> = (0..31).map(|d| format!("{:6}", d)).collect();
    println!("chart, day   {}", days.join(" "));
    let pr: Vec<String> = daily.iter().map(|x| format!("{:6.2}", x)).collect();
    println!("chart, price {}", pr.join(" "));
    let gi: Vec<String> = (0..3).map(|i| format!("{:.2}", 1000.0 * gap[i][0] / pf)).collect();
    let gs: Vec<String> = (0..3).map(|i| format!("{:.2}", 1000.0 * gap[i][1] / pf)).collect();
    println!("chart, gap to Ito x1000   {}", gi.join(" "));
    println!("chart, gap to slope x1000 {}", gs.join(" "));

    assert!((m1 - m2).abs() < 1e-9 && (v1 - v2).abs() < 1e-9, "the averaged log matches the Poisson mixture");
    assert!((mean1 - mean2).abs() < 1e-9 * mean2 && (sq1 - sq2).abs() < 1e-6 * sq2, "Ito on S and S^2 matches the mixture");
    assert!((ms - mean2).abs() < 4.0 * se_s, "simulated mean price within 4 se of the mixture's 50");
    assert!((ml - m1).abs() < 4.0 * se_l, "simulated mean log within 4 se of Ito with jumps");
    assert!((fr - up2).abs() < 4.0 * se_f, "simulated chance above 50 matches the mixture");
    assert!(gap[2][0] < gap[0][0] / 3.0, "the path-by-path gap to Ito shrinks with the step");
    assert!(gap[2][1] / pf > 0.1, "the slope rule stays far off on every grid");
    assert!((qv - qv_target).abs() < 0.1 * qv_target, "the jumps' squares sit in the quadratic variation");
    println!("ALL CHECKS PASS");
}
