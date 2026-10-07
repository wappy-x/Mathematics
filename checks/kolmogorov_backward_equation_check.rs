// Kolmogorov backward equation -- the check behind the card.  Rust std only, no crates.
// u(tau, x) = expected payoff of a $100-strike call, tau years before it pays, share at $x today,
// share moving as Brownian motion with sigma = $20 per root-year.  Roads: the closed-form solution,
// a Simpson average over the bell curve, the coin-flip tree (the backward equation stepped exactly),
// and seeded Monte Carlo (SplitMix64 + Box-Muller, written out).  Then the generalisation (drift,
// a barrier, the house OU rate on 1,000 steps) and the what-breaks numbers.
use std::f64::consts::PI;

const X0: f64 = 100.0; const K: f64 = 100.0; const SIG: f64 = 20.0; const T: f64 = 1.0;
const MU: f64 = 5.0; const BAR: f64 = 80.0; const SEED: u64 = 20260930;
const KAP: f64 = 0.5; const THE: f64 = 0.04; const R0: f64 = 0.06; const SOU: f64 = 0.02;

fn ncdf(x: f64) -> f64 {                        // bell-curve area left of x, by its Taylor series
    let (mut term, mut tot, mut n) = (x, x, 0.0);
    while term.abs() > 1e-18 {
        n += 1.0;
        term *= -x * x / (2.0 * n);
        tot += term / (2.0 * n + 1.0);
    }
    0.5 + tot / (2.0 * PI).sqrt()
}
fn pdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn call(y: f64) -> f64 { (y - K).max(0.0) }
fn square(y: f64) -> f64 { (y - K) * (y - K) }

fn bach(x: f64, tau: f64, mu: f64, sig: f64) -> f64 {   // road 1: the solution of the backward equation
    if tau == 0.0 { return call(x); }
    let s = sig * tau.sqrt(); let m = x + mu * tau; let d = (m - K) / s;
    (m - K) * ncdf(d) + s * pdf(d)
}
fn simpson(pay: fn(f64) -> f64, x: f64, tau: f64, mu: f64) -> f64 {   // road 2: Simpson's rule
    let (a, b, n) = (-10.0, 10.0, 20000usize); let h = (b - a) / n as f64; let s = SIG * tau.sqrt();
    let g = |z: f64| pay(x + mu * tau + s * z) * pdf(z);
    let mut tot = g(a) + g(b);
    for i in 1..n { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    tot * h / 3.0
}
fn tree(x: f64, tau: f64, n: usize, mu: f64, bar: Option<f64>) -> f64 {   // road 3: the coin-flip tree
    let h = tau / n as f64; let dl = SIG * h.sqrt(); let p = 0.5 + 0.5 * mu * h.sqrt() / SIG;
    let mut v: Vec<f64> = (0..=n).map(|j| call(x + (2.0 * j as f64 - n as f64) * dl)).collect();
    for k in (1..=n).rev() {
        v = (0..k).map(|j| p * v[j + 1] + (1.0 - p) * v[j]).collect();
        if let Some(bb) = bar {
            for j in 0..k { if x + (2.0 * j as f64 - k as f64 + 1.0) * dl <= bb + 1e-9 { v[j] = 0.0; } }
        }
    }
    v[0]
}

struct SplitMix64 { s: u64 }                    // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {               // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}
fn mean_se(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = xs.iter().sum::<f64>() / n;
    (m, (xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0) / n).sqrt())
}
fn ou2(tau: f64, x: f64) -> f64 {               // OU: u = E[r_T^2] solves the general backward equation
    let m = THE + (x - THE) * (-KAP * tau).exp();
    m * m + SOU * SOU * (1.0 - (-2.0 * KAP * tau).exp()) / (2.0 * KAP)
}

fn main() {
    println!("setup: x {:.0}, K {:.0}, sigma {:.0} dollars per root-year, T {:.0} year, seed {}", X0, K, SIG, T, SEED);
    let u = bach(X0, T, 0.0, SIG); let u_s = simpson(call, X0, T, 0.0);
    println!("1 closed form u(1, 100)       {:.6}", u);
    println!("2 Simpson average             {:.6}", u_s);
    let mut errs = vec![];
    for n in [100usize, 400, 1600, 6400] {
        let t = tree(X0, T, n, 0.0, None); errs.push((t - u).abs());
        println!("3 tree n {:<5} step {:.6} y, move {:.2}  {:.6}  error {:+.6}", n, T / n as f64, SIG * (T / n as f64).sqrt(), t, t - u);
    }
    let mut g = SplitMix64 { s: SEED }; let m = 200000usize;
    let zs: Vec<f64> = (0..m).map(|_| g.normal()).collect();
    let (mc, se) = mean_se(&zs.iter().map(|z| call(X0 + SIG * T.sqrt() * z)).collect::<Vec<f64>>());
    println!("4 Monte Carlo {} paths   {:.6}  SE {:.6}  gap {:+.2} SE", m, mc, se, (mc - u) / se);
    println!("hand: phi(0) {:.6}, N(0.5) {:.6}, phi(0.5) {:.6}, half sigma^2 {:.0}", pdf(0.0), ncdf(0.5), pdf(0.5), 0.5 * SIG * SIG);
    println!("hand x 110: 10 N(0.5) {:.6} + 20 phi(0.5) {:.6} = {:.6}", 10.0 * ncdf(0.5), 20.0 * pdf(0.5), bach(110.0, T, 0.0, SIG));
    let (e1, e2) = (1e-4, 1e-2);
    let u_tau = (bach(X0, T + e1, 0.0, SIG) - bach(X0, T - e1, 0.0, SIG)) / (2.0 * e1);
    let u_xx = (bach(X0 + e2, T, 0.0, SIG) - 2.0 * u + bach(X0 - e2, T, 0.0, SIG)) / (e2 * e2);
    println!("equation at (1, 100): u_tau {:.6}, half sigma^2 u_xx {:.6}", u_tau, 0.5 * SIG * SIG * u_xx);
    let sq = simpson(square, X0, T, 0.0);
    let sq_mc = mean_se(&zs.iter().map(|z| square(X0 + SIG * T.sqrt() * z)).collect::<Vec<f64>>());
    println!("squared payoff: hand sigma^2 tau {:.6}, Simpson {:.6}, MC {:.6} SE {:.6}", SIG * SIG * T, sq, sq_mc.0, sq_mc.1);
    let (ud, ud_s, ud_t) = (bach(X0, T, MU, SIG), simpson(call, X0, T, MU), tree(X0, T, 6400, MU, None));
    println!("drift 5: formula {:.6}, Simpson {:.6}, tree n 6400 {:.6}", ud, ud_s, ud_t);
    let ub = u - bach(2.0 * BAR - X0, T, 0.0, SIG);
    let (ub1, ub2) = (tree(X0, T, 1600, 0.0, Some(BAR)), tree(X0, T, 6400, 0.0, Some(BAR)));
    println!("barrier 80: value from 60 {:.6}, reflection {:.6}, tree n 1600 {:.6}, tree n 6400 {:.6}", bach(2.0 * BAR - X0, T, 0.0, SIG), ub, ub1, ub2);
    println!("breaks: ordinary chain rule {:.6} (drift 5: {:.6})", call(X0), call(X0 + MU * T));
    println!("breaks: generator without the half {:.6}", bach(X0, T, 0.0, SIG * 2f64.sqrt()));
    println!("breaks: drift sign flipped {:.6} (right {:.6})", bach(X0, T, -MU, SIG), ud);
    println!("breaks: barrier ignored {:.6} (right {:.6})", u, ub);
    let (a, b) = (1e-4, 1e-3);
    let lhs = (ou2(T + a, R0) - ou2(T - a, R0)) / (2.0 * a);
    let rhs = KAP * (THE - R0) * (ou2(T, R0 + b) - ou2(T, R0 - b)) / (2.0 * b)
        + 0.5 * SOU * SOU * (ou2(T, R0 + b) - 2.0 * ou2(T, R0) + ou2(T, R0 - b)) / (b * b);
    println!("OU: kappa {}, theta {}, r0 {}, sigma {}; equation at (1, 0.06): u_tau {:.9}, L u {:.9}", KAP, THE, R0, SOU, lhs, rhs);
    let mut g = SplitMix64 { s: SEED + 1 }; let (pp, ns) = (4000usize, 1000usize); let hh = T / ns as f64;
    let mut fin = vec![];
    for _ in 0..pp {
        let mut r = R0;
        for _ in 0..ns { r += KAP * (THE - r) * hh + SOU * hh.sqrt() * g.normal(); }
        fin.push(r);
    }
    let m1 = mean_se(&fin); let m2 = mean_se(&fin.iter().map(|r| r * r).collect::<Vec<f64>>());
    let e_r = THE + (R0 - THE) * (-KAP * T).exp();
    println!("OU 1,000 steps, {} paths: E[r_1] formula {:.6}, MC {:.6} SE {:.6}", pp, e_r, m1.0, m1.1);
    println!("OU E[r_1^2] formula {:.7}, MC {:.7} SE {:.7}", ou2(T, R0), m2.0, m2.1);
    for x in (70..=130).step_by(5) {
        let xf = x as f64;
        println!("chart, x {}: tau 1 {:.2}, tau 0.25 {:.2}, payoff {:.2}", x, bach(xf, 1.0, 0.0, SIG), bach(xf, 0.25, 0.0, SIG), call(xf));
    }

    assert!((u - u_s).abs() < 1e-9 && (sq - SIG * SIG * T).abs() < 1e-6);   // formula and square vs Simpson
    assert!(errs[3] < 0.002 && errs[1] < errs[0] / 3.0 && errs[3] < errs[2] / 3.0);   // error ~ step
    assert!((mc - u).abs() < 4.0 * se && (sq_mc.0 - SIG * SIG * T).abs() < 4.0 * sq_mc.1);
    assert!((u_tau - 0.5 * SIG * SIG * u_xx).abs() < 1e-5 && (lhs - rhs).abs() < 1e-9);   // formulas solve the PDEs
    assert!((ud - ud_s).abs() < 1e-9 && (ud_t - ud).abs() < 0.005 && (ub2 - ub).abs() < 0.005);
    assert!((m1.0 - e_r).abs() < 4.0 * m1.1 && (m2.0 - ou2(T, R0)).abs() < 4.0 * m2.1);
    println!("all checks passed");
}
