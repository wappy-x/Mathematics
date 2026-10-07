// Merton's portfolio problem -- the same check as the Python, in Rust.  No crates.
// The optimiser, the integrator and the random numbers are written out here.
// Compile: rustc --edition 2021 -O mertons_portfolio_problem_check.rs -o /tmp/merton_check
use std::f64::consts::PI;

const R: f64 = 0.02;
const MU: f64 = 0.06;
const SIGMA: f64 = 0.20;
const GAMMA: f64 = 2.0;
const T: f64 = 3.0;
const W0: f64 = 100000.0;
const P: f64 = 1.0 - GAMMA;                       // the power in U(x) = x^p / p

fn merton(mu: f64, r: f64, sigma: f64, gamma: f64) -> f64 { (mu - r) / (gamma * sigma * sigma) }

fn g(a: f64) -> f64 { R + a * (MU - R) - 0.5 * GAMMA * SIGMA * SIGMA * a * a }

fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    s * h / 3.0
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }

fn ce_of<F: Fn(f64) -> f64>(wealth_at: F) -> f64 {  // certainty equivalent of W_T(z)
    let m = simpson(|z| wealth_at(z).powf(P) * phi(z), -10.0, 10.0, 4000);
    m.powf(1.0 / P)
}

fn ce_constant(a: f64) -> f64 {                   // road 2: exact law of a rebalanced account
    ce_of(|z| W0 * ((R + a * (MU - R) - 0.5 * a * a * SIGMA * SIGMA) * T + a * SIGMA * T.sqrt() * z).exp())
}

fn ce_buy_hold(z: f64) -> f64 {                   // 50/50 at the start, never traded again
    0.5 * W0 * (R * T).exp() + 0.5 * W0 * ((MU - 0.5 * SIGMA * SIGMA) * T + SIGMA * T.sqrt() * z).exp()
}

fn golden_max<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64) -> f64 {
    let k = (5.0_f64.sqrt() - 1.0) / 2.0;
    let (mut a, mut b) = (lo, hi);
    while b - a > 1e-9 {
        let (c, d) = (b - k * (b - a), a + k * (b - a));
        if f(c) > f(d) { b = d } else { a = c }
    }
    0.5 * (a + b)
}

struct Rng { s: u64 }                             // xorshift64* uniforms, Box-Muller normals
impl Rng {
    fn uniform(&mut self) -> f64 {
        let mut s = self.s;
        s ^= s >> 12; s ^= s << 25; s ^= s >> 27;
        self.s = s;
        (s.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let (u1, u2) = (self.uniform(), self.uniform());
        (-2.0 * (1.0 - u1).ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn monte_carlo(shares: &[f64], paths: usize, steps: usize) -> Vec<f64> {   // road 3: weekly rebalancing
    let dt = T / steps as f64;
    let bank = (R * dt).exp() - 1.0;
    let mut rng = Rng { s: 20260928 };
    let mut sums = vec![0.0; shares.len() + 1];
    for _ in 0..paths {
        let mut w = vec![W0; shares.len()];
        let (mut fund, mut cash) = (0.5 * W0, 0.5 * W0);
        for _ in 0..steps {
            let ret = ((MU - 0.5 * SIGMA * SIGMA) * dt + SIGMA * dt.sqrt() * rng.normal()).exp() - 1.0;
            for (i, a) in shares.iter().enumerate() { w[i] *= 1.0 + a * ret + (1.0 - a) * bank; }
            fund *= 1.0 + ret; cash *= 1.0 + bank;
        }
        for i in 0..shares.len() { sums[i] += w[i].powf(P); }
        sums[shares.len()] += (fund + cash).powf(P);
    }
    sums.iter().map(|s| (s / paths as f64).powf(1.0 / P)).collect()
}

fn v(t: f64, w: f64, g_star: f64) -> f64 { w.powf(P) / P * (P * g_star * (T - t)).exp() }

fn main() {
    let pi_star = merton(MU, R, SIGMA, GAMMA);
    let g_star = R + (MU - R).powi(2) / (2.0 * GAMMA * SIGMA * SIGMA);
    let ce_star = W0 * (g_star * T).exp();        // from the value function V(0, W0)
    let pi_golden = golden_max(ce_constant, -1.0, 3.0);
    println!("{:<44}{:>14.6}", "1 formula: share in the fund", pi_star);
    println!("{:<44}{:>14.6}", "2 golden search on exact certainty equiv.", pi_golden);
    println!("{:<44}{:>14.6}", "hand: gamma sigma^2", GAMMA * SIGMA * SIGMA);
    println!("{:<44}{:>14.6}", "hand: premium (mu-r)^2 / (2 gamma sigma^2)", g_star - R);
    println!("{:<44}{:>14.6}", "best certainty-equivalent rate g*", g_star);
    println!("{:<44}{:>14.6}", "hand: e^(g* T)", (g_star * T).exp());
    println!("{:<44}{:>14.6}", "account drift r + pi*(mu - r)", R + pi_star * (MU - R));
    println!("{:<44}{:>14.6}", "account volatility pi* sigma", pi_star * SIGMA);
    println!("{:<44}{:>14.2}", "certainty equivalent, value function", ce_star);
    println!("{:<44}{:>14.2}", "certainty equivalent, Simpson integral", ce_constant(pi_star));
    println!("{:<44}{:>14.2}", "  gain over all in the bank", ce_star - W0 * (R * T).exp());
    let ce_bh = ce_of(ce_buy_hold);
    println!("{:<44}{:>14.2}", "certainty equivalent, buy and hold 50/50", ce_bh);
    println!("{:<44}{:>14.2}", "  shortfall of buy and hold", ce_star - ce_bh);
    let grid = [0.0, 0.25, 0.5, 0.75, 1.0];
    let mc = monte_carlo(&grid, 20000, 156);
    println!("3 Monte Carlo, 20000 paths, weekly rebalancing, 3 years");
    for (a, c) in grid.iter().zip(&mc) {
        println!("  share {:4.2}   simulated CE {:10.2}   exact CE {:10.2}", a, c, ce_constant(*a));
    }
    println!("  buy and hold 50/50  simulated CE {:10.2}", mc[5]);
    // 4: the HJB equation, derivatives by finite differences, best share by brute-force grid
    let mut hjb_ok = true;
    for (t, w) in [(0.0_f64, 50000.0_f64), (1.5, 100000.0), (2.9, 200000.0)] {
        let (h, e) = (1e-3 * w, 1e-4);
        let vt = (v(t + e, w, g_star) - v(t - e, w, g_star)) / (2.0 * e);
        let vw = (v(t, w + h, g_star) - v(t, w - h, g_star)) / (2.0 * h);
        let vww = (v(t, w + h, g_star) - 2.0 * v(t, w, g_star) + v(t, w - h, g_star)) / (h * h);
        let gen = |a: f64| vt + (R + a * (MU - R)) * w * vw + 0.5 * a * a * SIGMA * SIGMA * w * w * vww;
        let mut best = -1.0;
        for i in -1000..=3000 { let a = i as f64 / 1000.0; if gen(a) > gen(best) { best = a; } }
        let res = gen(best) / vt.abs();
        hjb_ok &= (best - pi_star).abs() < 1e-3 && res.abs() < 1e-4;
        println!("4 HJB at t={:3.1}, w={:9.0}: best share {:5.3}, residual per million {:6.3}", t, w, best, 1e6 * res);
    }
    println!("chart: certainty-equivalent wealth after 3 years, $ thousands");
    let chart = [0.0, 0.25, 0.5, 0.75, 1.0, 1.25, 1.5];
    println!("  share {}", chart.iter().map(|a| format!("{:7.2}", a)).collect::<Vec<_>>().join(" "));
    println!("  CE    {}", chart.iter().map(|a| format!("{:7.2}", W0 * (g(*a) * T).exp() / 1000.0)).collect::<Vec<_>>().join(" "));
    println!("bars: Merton share (percent) as one input moves, others as in the example");
    for (lab, x) in [("gamma 1", merton(MU, R, SIGMA, 1.0)), ("gamma 2", pi_star), ("gamma 4", merton(MU, R, SIGMA, 4.0)),
                     ("sigma 15%", merton(MU, R, 0.15, GAMMA)), ("sigma 30%", merton(MU, R, 0.30, GAMMA)),
                     ("excess 2%", merton(0.04, R, SIGMA, GAMMA)), ("excess 6%", merton(0.08, R, SIGMA, GAMMA))] {
        println!("  {:<10}{:8.2}", lab, 100.0 * x);
    }
    println!("{:<44}{:>14.6}", "wrong: sigma for variance", (MU - R) / (GAMMA * SIGMA));
    println!("{:<44}{:>14.6}", "wrong: total return for excess", MU / (GAMMA * SIGMA * SIGMA));
    println!("{:<44}{:>14.6}", "wrong: aversion dropped (gamma = 1)", merton(MU, R, SIGMA, 1.0));
    println!("{:<44}{:>14.6}", "try: sigma = 0.10", merton(MU, R, 0.10, GAMMA));
    println!("{:<44}{:>14.6}", "try: mu = 0.10", merton(0.10, R, SIGMA, GAMMA));
    println!("story: one year, quarterly rebalancing to 50%, bank 2% a year");
    let (mut fund, mut cash) = (0.5 * W0, 0.5 * W0);
    println!("  start           fund {:9.2}  bank {:9.2}  wealth {:9.2}", fund, cash, W0);
    for (q, ret) in [0.10_f64, -0.15, 0.05, 0.02].iter().enumerate() {
        fund *= 1.0 + ret; cash *= (R / 4.0).exp();
        let w = fund + cash;
        let trade = 0.5 * w - fund;
        println!("  Q{} fund {:+4.0}%  fund {:9.2}  bank {:9.2}  wealth {:9.2}  trade {:+9.2}", q + 1, 100.0 * ret, fund, cash, w, trade);
        fund = 0.5 * w; cash = 0.5 * w;
    }
    assert!((pi_golden - pi_star).abs() < 1e-6, "numerical optimum vs the formula");
    assert!((ce_constant(pi_star) - ce_star).abs() < 1e-4, "integral vs value function");
    let best_mc = (0..grid.len()).fold(0, |b, i| if mc[i] > mc[b] { i } else { b });
    assert!(grid[best_mc] == 0.5 && (mc[2] - ce_star).abs() / ce_star < 0.005, "simulation picks 50%");
    assert!(hjb_ok, "HJB: same best share everywhere");
    println!("ALL CHECKS PASS");
}
