// Two-asset portfolio: mean and spread of a 60-40 mix of shares and bonds.
// Rust std only.  Three roads to the 60-40 spread: the variance formula,
// a four-state ledger in dollars, and a simulation with home-made random
// numbers.  The least-risk weight is found by formula and by search.
const MA: f64 = 0.08; const SA: f64 = 0.20; // shares: mean return, spread
const MB: f64 = 0.04; const SB: f64 = 0.06; // bonds: mean return, spread
const RHO: f64 = 0.2; const W: f64 = 0.6;   // correlation, weight in shares

fn formula_var(w: f64, rho: f64) -> f64 {   // road 1
    w * w * SA * SA + (1.0 - w).powi(2) * SB * SB + 2.0 * w * (1.0 - w) * rho * SA * SB
}

// road 2: four states, each asset one spread up or down;
// P(both up) = P(both down) = (1+rho)/4, the mixed states (1-rho)/4
fn ledger(w: f64, rho: f64) -> (Vec<[f64; 6]>, f64, f64) {
    let money = 1000.0;
    let mut states = Vec::new();
    for &(sa, sb) in &[(1.0, 1.0), (1.0, -1.0), (-1.0, 1.0), (-1.0, -1.0)] {
        let p: f64 = (1.0 + rho * sa * sb) / 4.0;
        let (ra, rb) = (MA + sa * SA, MB + sb * SB);
        let (shares, bonds) = (w * money * (1.0 + ra), (1.0 - w) * money * (1.0 + rb));
        states.push([p, ra, rb, shares, bonds, (shares + bonds) / money - 1.0]);
    }
    let mean: f64 = states.iter().map(|s| s[0] * s[5]).sum();
    let var: f64 = states.iter().map(|s| s[0] * (s[5] - mean).powi(2)).sum();
    (states, mean, var)
}

fn simulate(w: f64, rho: f64, n: usize, seed: u64) -> (f64, f64) { // road 3
    let mut x = seed;
    let mut uniform = || {                  // xorshift64: shift-and-xor random bits
        x ^= x << 13; x ^= x >> 7; x ^= x << 17;
        ((x >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let (mut s, mut s2) = (0.0, 0.0);
    let two_pi = 2.0 * std::f64::consts::PI;
    for _ in 0..n {
        let (u1, u2, u3, u4) = (uniform(), uniform(), uniform(), uniform());
        let z1 = (-2.0 * u1.ln()).sqrt() * (two_pi * u2).cos(); // Box-Muller
        let z2 = (-2.0 * u3.ln()).sqrt() * (two_pi * u4).cos();
        let (za, zb) = (z1, rho * z1 + (1.0 - rho * rho).sqrt() * z2);
        let rp = w * (MA + SA * za) + (1.0 - w) * (MB + SB * zb);
        s += rp; s2 += rp * rp;
    }
    let m = s / n as f64;
    (m, (s2 / n as f64 - m * m).sqrt())
}

fn pct(v: f64) -> String { format!("{:.2}%", 100.0 * v) }

fn main() {
    let cov = RHO * SA * SB;
    let mean60 = W * MA + (1.0 - W) * MB;
    let v_f = formula_var(W, RHO);
    let (states, mean_l, v_l) = ledger(W, RHO);
    let (m_sim, sd_sim) = simulate(W, RHO, 200000, 20260928);
    let avg_sd = W * SA + (1.0 - W) * SB;
    println!("inputs: shares 8.00% mean, 20.00% spread; bonds 4.00%, 6.00%; correlation 0.2");
    println!("covariance rho*sA*sB            {:.6}", cov);
    println!("variances vA, vB; d = vA+vB-2c   {:.6} {:.6} {:.6}", SA * SA, SB * SB, SA * SA + SB * SB - 2.0 * cov);
    println!("60-40 pieces w^2vA, (1-w)^2vB, 2w(1-w)c  {:.6} {:.6} {:.6}",
             W * W * SA * SA, (1.0 - W).powi(2) * SB * SB, 2.0 * W * (1.0 - W) * cov);
    println!("60-40 mean, weighted average    {}", pct(mean60));
    println!("60-40 variance, formula         {:.6}", v_f);
    println!("60-40 variance, ledger          {:.6}", v_l);
    println!("60-40 spread, formula           {}", pct(v_f.sqrt()));
    println!("60-40 spread, ledger            {}", pct(v_l.sqrt()));
    println!("60-40 mean and spread, simulated {} {} (200000 draws)", pct(m_sim), pct(sd_sim));
    println!("simulation gap in mean, std error {:.2} {:.2} points",
             100.0 * (m_sim - mean60).abs(), 100.0 * (v_f / 200000.0).sqrt());
    println!("weighted average of spreads     {}", pct(avg_sd));
    println!("diversification saves           {:.2} points", 100.0 * (avg_sd - v_f.sqrt()));
    println!("one-spread range for the year   {} to {}", pct(mean60 - v_f.sqrt()), pct(mean60 + v_f.sqrt()));
    println!("ledger on $1,000: prob, shares ret, bonds ret, shares $, bonds $, total $, portfolio ret");
    for s in &states {
        println!("  {:.2}  {:>7} {:>7}  {:7.2} {:7.2} {:8.2}  {:>7}", s[0], pct(s[1]), pct(s[2]), s[3], s[4], s[3] + s[4], pct(s[5]));
    }
    assert!((v_l - v_f).abs() < 1e-12 && (mean_l - mean60).abs() < 1e-12);
    assert!((sd_sim - v_f.sqrt()).abs() < 0.002 && (m_sim - mean60).abs() < 0.003);

    // least-risk weight: completing the square, then a search on the ledger
    let d = SA * SA + SB * SB - 2.0 * cov;
    let w_star = (SB * SB - cov) / d;
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..200 {                       // ternary search: keep the lower third
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if ledger(a, RHO).2 < ledger(b, RHO).2 { hi = b; } else { lo = a; }
    }
    let w_search = (lo + hi) / 2.0;
    assert!((w_search - w_star).abs() < 1e-7);
    let v_star = formula_var(w_star, RHO);
    println!("least-risk weight, formula      {:.6} ({})", w_star, pct(w_star));
    println!("w* > 0 needs rho below sB/sA    {:.6}", SB / SA);
    println!("least-risk weight, search       {:.6}", w_search);
    println!("least-risk mix mean, spread     {} {}", pct(w_star * MA + (1.0 - w_star) * MB), pct(v_star.sqrt()));
    println!("variance check V(w*)+d(0.6-w*)^2 {:.6}", v_star + d * (W - w_star).powi(2));
    let w_hedge = SB / (SA + SB);           // perfect negative correlation: spreads cancel
    let v_hedge = ledger(w_hedge, -1.0).2;
    assert!(v_hedge < 1e-15);
    println!("rho=-1 zero-risk weight         {:.6} ({}), mean {}, ledger variance {:.6}",
             w_hedge, pct(w_hedge), pct(w_hedge * MA + (1.0 - w_hedge) * MB), v_hedge);

    println!("curve: shares %, mean, spread at rho=1, rho=0.2, rho=-1");
    for k in 0..11 {
        let w = k as f64 / 10.0;
        let row: Vec<f64> = [1.0, 0.2, -1.0].iter().map(|&r| ledger(w, r).2.sqrt()).collect();
        assert!((row[1].powi(2) - formula_var(w, 0.2)).abs() < 1e-12 && row[1] <= row[0] + 1e-12);
        println!("  {:3}  {}  {}  {}  {}", 10 * k, pct(w * MA + (1.0 - w) * MB), pct(row[0]), pct(row[1]), pct(row[2]));
    }
    println!("60-40 spread by correlation");
    for &r in &[-1.0, -0.5, 0.0, 0.2, 0.5, 1.0] {
        println!("  rho {:+.1}  {}", r, pct(formula_var(W, r).sqrt()));
    }

    let (va, vb) = (SA * SA, SB * SB);
    println!("what breaks, 60-40:");
    println!("  average the spreads            {}", pct(avg_sd));
    println!("  drop the cross term            {}", pct((W * W * va + (1.0 - W).powi(2) * vb).sqrt()));
    println!("  cross term without the 2       {}", pct((W * W * va + (1.0 - W).powi(2) * vb + W * (1.0 - W) * cov).sqrt()));
    println!("  weights not squared            {}", pct((W * va + (1.0 - W) * vb + 2.0 * W * (1.0 - W) * cov).sqrt()));
    println!("try changing:");
    println!("  50-50 mix                      {} {}", pct(0.5 * MA + 0.5 * MB), pct(formula_var(0.5, RHO).sqrt()));
    println!("  80-20 mix                      {} {}", pct(0.8 * MA + 0.2 * MB), pct(formula_var(0.8, RHO).sqrt()));
    println!("  least-risk weight at rho=0.5   {:.6}", (vb - 0.5 * SA * SB) / (va + vb - SA * SB));
    println!("All checks passed.");
}
