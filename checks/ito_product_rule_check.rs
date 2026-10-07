// Ito's product rule -- the same check as ito_product_rule_check.py, in Rust.
// Standard library only, no crates.  Same generator, same seed, same order of
// draws, same plain left-to-right additions, so the output matches line for line.
// Compile: rustc --edition 2021 -O ito_product_rule_check.rs -o /tmp/ito_product_rule_check
use std::f64::consts::PI;

const S0: f64 = 100.0;
const SIG: f64 = 0.20;
const R: f64 = 0.05;
const MU: f64 = 0.08;
const T: f64 = 1.0;

struct Rng { s: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {                     // SplitMix64, top 53 bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {                      // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn share(mu: f64, t: f64, w: f64) -> f64 { S0 * ((mu - 0.5 * SIG * SIG) * t + SIG * w).exp() }

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let mut m = 0.0;
    for x in xs { m += x; }
    m /= xs.len() as f64;
    let mut v = 0.0;
    for x in xs { v += (x - m) * (x - m); }
    (m, (v / (xs.len() - 1) as f64 / xs.len() as f64).sqrt())
}

fn row(label: &str, v: f64) { println!("{:<46}{:>11.4}", label, v); }
fn row_se(label: &str, m: f64, se: f64) { println!("{:<46}{:>11.4}  se {:.4}", label, m, se); }

fn main() {
    let mut rng = Rng { s: 20260930 };
    println!("A  formulas");
    let (fd8, fd5) = (S0 * ((MU - R) * T).exp(), S0 * ((R - R) * T).exp());
    let (fs2, fs2_wrong) = (S0 * S0 * ((2.0 * R + SIG * SIG) * T).exp(), S0 * S0 * (2.0 * R * T).exp());
    let fgap = SIG * SIG * S0 * S0 * (((2.0 * MU + SIG * SIG) * T).exp() - 1.0) / (2.0 * MU + SIG * SIG);
    row("E[D_1], mu = 0.08", fd8);
    row("E[D_1], mu = r = 0.05", fd5);
    row("E[S_1^2], mu = 0.05, product rule", fs2);
    row("E[S_1^2], mu = 0.05, covariation dropped", fs2_wrong);
    row("E[W_1^2], product rule", T);
    row("E[W_1^2], ordinary rule", 0.0);
    row("mu = 0.08: sigma^2 E[integral of S^2 dt]", fgap);
    row("try: E[S_1^2], sigma = 0.40, product rule", S0 * S0 * ((2.0 * R + 0.16) * T).exp());
    println!("hand: mu - r {:.4}, 2r + sigma^2 {:.4}, e^(mu - r) {:.4}", MU - R, 2.0 * R + SIG * SIG, (MU - R).exp());

    const NF: usize = 4096;
    let dtf = T / NF as f64;
    let mut w = vec![0.0f64];
    for k in 0..NF { let next = w[k] + dtf.sqrt() * rng.normal(); w.push(next); }
    let s: Vec<f64> = (0..=NF).map(|k| share(R, k as f64 * dtf, w[k])).collect();
    let mut target = 0.0;                              // sigma^2 times the integral of S^2 dt (trapezoids)
    for k in 0..NF { target += SIG * SIG * 0.5 * (s[k] * s[k] + s[k + 1] * s[k + 1]) * dtf; }
    println!("B  one path, mu = 0.05: steps, sum dS d(e^-rt), sum (dS)^2, identity gap");
    let (mut cross_b, mut sq_b, mut gap_b) = (Vec::new(), Vec::new(), 0.0f64);
    for n in [16usize, 64, 256, 1024, 4096] {
        let p: Vec<f64> = s.iter().step_by(NF / n).cloned().collect();
        let b: Vec<f64> = (0..=n).map(|k| (-R * k as f64 * T / n as f64).exp()).collect();
        let (mut xdy, mut ydx, mut cross, mut sq) = (0.0f64, 0.0f64, 0.0f64, 0.0f64);
        for k in 0..n {
            let (ds, db) = (p[k + 1] - p[k], b[k + 1] - b[k]);
            xdy += p[k] * db; ydx += b[k] * ds; cross += ds * db; sq += ds * ds;
        }
        let gap = ((p[n] * b[n] - p[0] * b[0]) - (xdy + ydx + cross)).abs();
        cross_b.push(cross); sq_b.push(sq); gap_b = gap_b.max(gap);
        println!("   n {:>5}   {:>10.6}   {:>10.4}   {:.9}", n, cross, sq, gap);
    }
    row("   sigma^2 * integral of S^2 dt, this path", target);
    row("   share at t = 1, this path", s[NF]);
    row("   discounted share at t = 1, this path", s[NF] * (-R * T).exp());

    const NP: usize = 20000;
    let mut dq = vec![vec![Vec::with_capacity(NP); 4]; 2];
    let (mut fair, mut s2, mut w2) = (vec![Vec::new(), Vec::new()], Vec::new(), Vec::new());
    for _ in 0..NP {
        let (mut wq, mut ws) = ([0.0f64; 4], 0.0f64);
        for j in 0..4 { ws += 0.5 * rng.normal(); wq[j] = ws; }   // quarter-year steps: sd = sqrt(0.25)
        for (a, mu) in [R, MU].iter().enumerate() {
            let d: Vec<f64> = (0..4).map(|j| share(*mu, 0.25 * (j + 1) as f64, wq[j]) * (-R * 0.25 * (j + 1) as f64).exp()).collect();
            for j in 0..4 { dq[a][j].push(d[j]); }
            fair[a].push(if d[1] > 100.0 { d[3] - d[1] } else { 0.0 });
        }
        let s1 = share(R, 1.0, wq[3]);
        s2.push(s1 * s1); w2.push(wq[3] * wq[3]);
    }
    println!("C  20000 paths: mean discounted share each quarter");
    let (mut ch5, mut ch8) = (vec![100.0f64], vec![100.0f64]);
    for j in 0..4 {
        let ((m5, e5), (m8, e8)) = (mean_se(&dq[0][j]), mean_se(&dq[1][j]));
        ch5.push(m5); ch8.push(m8);
        println!("   t {:.2}   mu 0.05 {:9.4} se {:.4}   mu 0.08 {:9.4} se {:.4}", 0.25 * (j + 1) as f64, m5, e5, m8, e8);
    }
    let (fg5, fg8, ms2, mw2) = (mean_se(&fair[0]), mean_se(&fair[1]), mean_se(&s2), mean_se(&w2));
    row_se("fair game, mu 0.05: E[(D_1 - D_.5) if D_.5>100]", fg5.0, fg5.1);
    row_se("fair game, mu 0.08: E[(D_1 - D_.5) if D_.5>100]", fg8.0, fg8.1);
    row_se("E[S_1^2], mu = 0.05, simulated", ms2.0, ms2.1);
    row_se("E[W_1^2], simulated", mw2.0, mw2.1);
    let fmt = |v: &Vec<f64>| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, mean D, mu 0.05 {}", fmt(&ch5));
    println!("chart, mean D, mu 0.08 {}", fmt(&ch8));

    let ns = [16usize, 64, 256, 1024, 4096];
    let (mut errd, mut erry, mut errn) = ([0.0f64; 5], [0.0f64; 5], [0.0f64; 5]);
    for _ in 0..200 {
        let mut wc = vec![0.0f64];
        for k in 0..NF { let next = wc[k] + dtf.sqrt() * rng.normal(); wc.push(next); }
        let sp: Vec<f64> = (0..=NF).map(|k| share(MU, k as f64 * dtf, wc[k])).collect();
        let (d_exact, y_exact) = (sp[NF] * (-R * T).exp(), sp[NF] * sp[NF]);
        for (a, &n) in ns.iter().enumerate() {
            let (h, st) = (T / n as f64, NF / n);
            let (mut d, mut y, mut yn) = (S0, S0 * S0, S0 * S0);
            for k in 0..n {
                let (x0, x1) = (sp[k * st], sp[(k + 1) * st]);
                d += d * ((MU - R) * h + SIG * (wc[(k + 1) * st] - wc[k * st]));
                y += 2.0 * x0 * (x1 - x0) + SIG * SIG * x0 * x0 * h;
                yn += 2.0 * x0 * (x1 - x0);
            }
            errd[a] += (d - d_exact).abs() / 200.0;
            erry[a] += (y - y_exact).abs() / 200.0;
            errn[a] += (yn - y_exact).abs() / 200.0;
        }
    }
    println!("D  200 paths, mu = 0.08: mean |error| at t = 1; steps, D, S^2 with term, S^2 without");
    for (a, n) in ns.iter().enumerate() {
        println!("   n {:>5}   {:8.4}   {:9.2}   {:9.2}", n, errd[a], erry[a], errn[a]);
    }

    assert!((ch5[4] - fd5).abs() < 4.0 * mean_se(&dq[0][3]).1, "mu = r: discounted share keeps its mean");
    assert!((ch8[4] - fd8).abs() < 4.0 * mean_se(&dq[1][3]).1, "mu = 0.08: mean grows at mu - r");
    assert!(fg5.0.abs() < 4.0 * fg5.1 && fg8.0 > 4.0 * fg8.1, "fair game only when mu = r");
    assert!((ms2.0 - fs2).abs() < 4.0 * ms2.1, "E[S^2] needs the covariation term");
    assert!((mw2.0 - T).abs() < 4.0 * mw2.1, "E[W^2] = T, not 0");
    assert!(gap_b < 1e-9, "algebra check of Step 1: the grid identity is exact");
    assert!((sq_b[4] - target).abs() < 0.05 * target, "(dS)^2 sums to the covariation term");
    assert!(cross_b[4].abs() < 0.01 * cross_b[0].abs(), "share times discount: no covariation");
    assert!(erry[4] < erry[0] / 4.0 && errd[4] < errd[0] / 4.0, "Euler errors shrink with the term");
    assert!((errn[4] - fgap).abs() < 0.1 * fgap, "without the term the error stays at the covariation");
    println!("ALL CHECKS PASS");
}
