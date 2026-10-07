// Feynman-Kac -- the same check as feynman_kac_formula_check.py, in Rust.  Std only, no crates.
// A $100 share, sigma 0.20, real drift 0.08, bank rate 0.05; a one-year call at $100.
// Roads to its price: closed form; heat-kernel average (Simpson); the Black-Scholes
// equation solved backwards on four grids; 200000 seeded draws under Q.  Then the
// martingale inside the proof, and an equation's solution that is not the expectation.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const MU: f64 = 0.08;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const SEED: u64 = 20260930;
const DRAWS: usize = 200000;

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

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 { 0.5 + simpson(phi, 0.0, x, 2000) }         // area left of x

fn closed_form(s: f64, tau: f64, drift: f64) -> f64 {   // e^(-R tau) E[(S_T - K)+], S growing at drift
    if tau <= 0.0 { return (s - K).max(0.0); }
    let v = SIG * tau.sqrt();
    let d2 = ((s / K).ln() + (drift - 0.5 * SIG * SIG) * tau) / v;
    (-R * tau).exp() * (s * (drift * tau).exp() * ncdf(d2 + v) - K * ncdf(d2))
}

fn heat_kernel(s: f64, tau: f64) -> f64 {         // the heat equation's bell-curve average, discounted
    let y = s.ln() + (R - 0.5 * SIG * SIG) * tau;
    let f = |z: f64| ((y + SIG * tau.sqrt() * z).exp() - K).max(0.0) * phi(z);
    (-R * tau).exp() * simpson(f, -10.0, 10.0, 40000)
}

fn grid(n: usize, lam: f64) -> (f64, f64, usize, (f64, f64, f64)) {   // explicit scheme in x = log s
    let dx = 2.4 / n as f64;
    let m = (SIG * SIG * T / (lam * dx * dx)).ceil() as usize;
    let dt = T / m as f64;
    let a = 0.5 * SIG * SIG * dt / (dx * dx);
    let b = (R - 0.5 * SIG * SIG) * dt / (2.0 * dx);
    let (pu, pm, pd) = (a + b, 1.0 - 2.0 * a, a - b);
    let xs: Vec<f64> = (0..=n).map(|i| S0.ln() + (i as f64 - (n / 2) as f64) * dx).collect();
    let mut v: Vec<f64> = xs.iter().map(|x| (x.exp() - K).max(0.0)).collect();
    for j in 1..=m {                              // each value: a weighted average of three, minus interest
        let mut new = vec![0.0; n + 1];
        for i in 1..n { new[i] = pu * v[i + 1] + pm * v[i] + pd * v[i - 1] - R * dt * v[i]; }
        new[n] = xs[n].exp() - K * (-R * j as f64 * dt).exp();
        v = new;
    }
    let big = v.iter().fold(0.0_f64, |acc, x| acc.max(x.abs()));
    (v[n / 2], big, m, (pu, pm, pd))
}

fn mean_se(s1: f64, s2: f64) -> (f64, f64) {
    let d = DRAWS as f64;
    (s1 / d, ((s2 / d - (s1 / d) * (s1 / d)) / d).sqrt())
}

fn main() {
    let c = closed_form(S0, T, R);
    let v = SIG * T.sqrt();
    let d2 = ((S0 / K).ln() + (R - 0.5 * SIG * SIG) * T) / v;
    println!("share {:.0}, strike {:.0}, r {:.2}, real drift {:.2}, sigma {:.2}, T {:.0} year", S0, K, R, MU, SIG, T);
    println!("log drift {:.6}   d2 {:.6}   d1 {:.6}   N(d2) {:.6}   N(d1) {:.6}", R - 0.5 * SIG * SIG, d2, d2 + v, ncdf(d2), ncdf(d2 + v));
    println!("share half {:.6}   cash half {:.6}", S0 * ncdf(d2 + v), K * (-R * T).exp() * ncdf(d2));
    println!("road 1, closed form                       {:.6}", c);
    let hk = heat_kernel(S0, T);
    println!("road 2, heat-kernel average (Simpson)     {:.6}", hk);
    println!("road 3, the equation solved backwards on a grid:");
    let mut errs = Vec::new();
    for n in [60usize, 120, 240, 480] {
        let (val, _, m, (pu, pm, pd)) = grid(n, 0.5);
        errs.push(val - c);
        println!("  dx {:.4}  steps {:5}  price {:.6}  error {:+.6}  weights {:.4} {:.4} {:.4}",
                 2.4 / n as f64, m, val, val - c, pu, pm, pd);
    }
    println!("chart, grid error in cents {}", errs.iter().map(|e| format!("{:.2}", -100.0 * e)).collect::<Vec<_>>().join(" "));
    println!("  error ratio at each halving of dx {}", (0..3).map(|i| format!("{:.2}", errs[i] / errs[i + 1])).collect::<Vec<_>>().join(" "));
    let mut g = SplitMix64 { s: SEED };
    let (mut q_sum, mut q_sq, mut p_sum, mut p_sq) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..DRAWS {                           // one normal, the payoff under Q and under the real drift
        let z = g.normal();
        let pay = |d: f64| (S0 * ((d - 0.5 * SIG * SIG) * T + v * z).exp() - K).max(0.0) * (-R * T).exp();
        let (pq, pp) = (pay(R), pay(MU));
        q_sum += pq; q_sq += pq * pq; p_sum += pp; p_sq += pp * pp;
    }
    let ((mq, se_q), (mp, se_p)) = (mean_se(q_sum, q_sq), mean_se(p_sum, p_sq));
    println!("road 4, {} draws under Q (seed {})  {:.4} (se {:.4})", DRAWS, SEED, mq, se_q);

    println!("the martingale e^(-rt) V(t, S_t), averaged over S_t (Simpson) and by closed form:");
    let times = [0.0_f64, 0.25, 0.5, 0.75, 1.0];
    let mut lines: Vec<Vec<(f64, f64)>> = Vec::new();
    for (name, drift) in [("Q", R), ("P", MU)] {
        let mut row = Vec::new();
        for &t in &times {
            let sd = SIG * t.sqrt();
            let f = |z: f64| closed_form(S0 * ((drift - 0.5 * SIG * SIG) * t + sd * z).exp(), T - t, R) * phi(z);
            let quad = if t == 0.0 { c } else { (-R * t).exp() * simpson(f, -10.0, 10.0, if t < T { 400 } else { 40000 }) };
            let blend = closed_form(S0, T, (drift * t + R * (T - t)) / T);
            row.push((quad, blend));
            println!("  {}  t {:.2}   quadrature {:.6}   closed form {:.6}", name, t, quad, blend);
        }
        lines.push(row);
    }
    println!("chart, t {}", times.iter().map(|t| format!("{:6.2}", t)).collect::<Vec<_>>().join(" "));
    for (k, name) in ["Q", "P"].iter().enumerate() {
        println!("chart, {} {}", name, lines[k].iter().map(|(q, _)| format!("{:6.2}", q)).collect::<Vec<_>>().join(" "));
    }

    println!("what breaks:");
    println!("  average under the real drift 0.08     {:.6}  draws {:.4} (se {:.4})", closed_form(S0, T, MU), mp, se_p);
    println!("  real drift, discounted at 0.08 too    {:.6}", closed_form(S0, T, MU) * ((R - MU) * T).exp());
    println!("  curvature term dropped: (S - Ke^-rT)+ {:.6}", (S0 - K * (-R * T).exp()).max(0.0));
    let (_, big, m_bad, (_, pm, _)) = grid(120, 1.2);
    println!("  grid step too long: dx 0.0200, steps {}, middle weight {:.4}, largest |V| 10^{:.1}", m_bad, pm, big.log10());
    // dX = X^2 dW from X = 1: X_t = 1/|a + B_t|, B a 3-d Brownian motion, |a| = 1.
    let u_star = 2.0 * ncdf(1.0) - 1.0;
    let (mut s_sum, mut s_sq) = (0.0, 0.0);
    for _ in 0..DRAWS {
        let b1 = 1.0 + g.normal();
        let b2 = g.normal();
        let b3 = g.normal();
        let x = 1.0 / (b1 * b1 + b2 * b2 + b3 * b3).sqrt();
        s_sum += x; s_sq += x * x;
    }
    let (ms, se_s) = mean_se(s_sum, s_sq);
    let us = |tau: f64, x: f64| x * (2.0 * ncdf(1.0 / (x * tau.sqrt())) - 1.0);
    let h = 1e-3;                                 // residual of u_tau = (1/2) x^4 u_xx at x = 1 and at two x != 1
    let res: Vec<f64> = [(1.0_f64, 1.0_f64), (0.5, 2.0), (2.0, 0.7)].iter().map(|&(t, x)| ((us(t + h, x) - us(t - h, x)) / (2.0 * h)
        - 0.5 * x.powi(4) * (us(t, x + h) - 2.0 * us(t, x) + us(t, x - h)) / (h * h)).abs()).collect();
    println!("  dX = X^2 dW, payoff x, T 1: the solution u = x gives 1.000000");
    println!("    expectation 2N(1) - 1 {:.6}   draws {:.4} (se {:.4})   its equation residual {:.6}", u_star, ms, se_s,
             res.iter().cloned().fold(0.0_f64, f64::max));

    assert!((hk - c).abs() < 1e-6, "heat-kernel road lands on the closed form");
    assert!(errs[3].abs() < 2e-3 && errs[0].abs() > errs[1].abs() && errs[1].abs() > errs[2].abs()
            && errs[2].abs() > errs[3].abs(), "grid closes in");
    assert!((mq - c).abs() < 4.0 * se_q, "draws under Q within 4 se");
    assert!(lines[0][1..].iter().all(|(q, _)| (q - c).abs() < 1e-5), "under Q the discounted price is a martingale");
    assert!(lines[1][1..].iter().all(|(q, b)| (q - b).abs() < 1e-5), "under P the tower property gives the blend");
    assert!(lines[1][4].0 > c + 2.0, "under P the discounted price drifts up");
    assert!((mp - closed_form(S0, T, MU)).abs() < 4.0 * se_p, "real-drift draws match their own formula");
    assert!(big.log10() > 3.0, "too long a step blows up");
    assert!((ms - u_star).abs() < 4.0 * se_s, "draws land on the expectation 2N(1) - 1");
    assert!(res.iter().all(|&r| r < 1e-5), "the expectation also solves dX = X^2 dW's equation, at x != 1 too");
    println!("ALL CHECKS PASS");
}
