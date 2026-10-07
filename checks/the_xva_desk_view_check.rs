// The XVA desk view -- the same check as the_xva_desk_view_check.py, in Rust.
// Standard library only, no crates.  Road 1: closed forms on the exposure annuity.
// Road 2: 52 weekly buckets, each week's exposure integrated over Acme's price.
// Margin: the 99% ten-day move by bisection, and again by simulation.
use std::f64::consts::PI;

const S0: f64 = 100.0; const K: f64 = 100.0; const R_: f64 = 0.05; const QD: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;
const LAM: f64 = 0.02; const REC: f64 = 0.40; const SF: f64 = 0.01; const HURDLE: f64 = 0.10;
const KCAP: f64 = 0.08 * 1.00 * 1.4; // 8% of a 100% weight on 1.4 x exposure
const SIM: f64 = 0.005; const FDF: f64 = 0.10;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn ncdf(x: f64) -> f64 { // 1/2 + phi(x) (x + x^3/3 + x^5/(3*5) + ...)
    if x > 10.0 { return 1.0; }
    if x < -10.0 { return 0.0; }
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        n += 1.0; term *= x * x / (2.0 * n + 1.0); total += term;
    }
    0.5 + phi(x) * total
}
fn call_r(s: f64, t: f64, rr: f64) -> f64 { // Black-Scholes value with t years left
    if t <= 0.0 { return (s - K).max(0.0); }
    let v = SIG * t.sqrt();
    let d1 = ((s / K).ln() + (rr - QD + 0.5 * SIG * SIG) * t) / v;
    s * (-QD * t).exp() * ncdf(d1) - K * (-rr * t).exp() * ncdf(d1 - v)
}
fn call(s: f64, t: f64) -> f64 { call_r(s, t, R_) }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn dee(t: f64, m: usize) -> f64 { // discounted expected exposure at t, by brute force
    let g = |z: f64| call(S0 * ((R_ - QD - 0.5 * SIG * SIG) * t + SIG * t.sqrt() * z).exp(), T - t) * phi(z);
    (-R_ * t).exp() * simpson(g, -8.0, 8.0, m)
}
fn q(t: f64, h: f64) -> f64 { (-h * t).exp() } // survival chance to t

fn main() {
    // ---- road 1: every charge is a rate times one exposure annuity ----
    let c0 = call(S0, T);
    let ae1 = c0 * (1.0 - (-LAM * T).exp()) / LAM;
    let (cva1, fva1, kva1) = ((1.0 - REC) * LAM * ae1, SF * ae1, HURDLE * KCAP * ae1);
    let v1 = c0 - cva1 + 0.0 - fva1 - 0.0 - kva1;
    // ---- road 2: 52 weekly buckets ----
    let n = 52; let dt = T / n as f64;
    let wk: Vec<f64> = (0..n).map(|i| dee((i as f64 + 0.5) * dt, 800)).collect();
    let bucket_pd = |h: f64| -> f64 { (0..n).map(|i| wk[i] * (q(i as f64 * dt, h) - q((i as f64 + 1.0) * dt, h))).sum() };
    let bucket_q = |h: f64| -> f64 { (0..n).map(|i| wk[i] * q((i as f64 + 0.5) * dt, h) * dt).sum() };
    let cva2 = (1.0 - REC) * bucket_pd(LAM);
    let ae2 = bucket_q(LAM);
    let (fva2, kva2) = (SF * ae2, HURDLE * KCAP * ae2);
    let v2 = c0 - cva2 - fva2 - kva2;
    let c0int = dee(T, 20000);

    // ---- cleared: initial margin, MVA, default-fund contribution ----
    let hday: f64 = 10.0 / 252.0;
    let d1 = ((S0 / K).ln() + (R_ - QD + 0.5 * SIG * SIG) * T) / (SIG * T.sqrt());
    let delta = (-QD * T).exp() * ncdf(d1);
    let (mut lo, mut hi) = (0.0_f64, 5.0_f64);
    for _ in 0..60 { // bisection: N(z) = 0.99
        let mid = 0.5 * (lo + hi);
        if ncdf(mid) < 0.99 { lo = mid; } else { hi = mid; }
    }
    let z99 = 0.5 * (lo + hi);
    let im1 = delta * S0 * SIG * hday.sqrt() * z99;
    let mut state: u64 = 88172645463325252;
    let mut unif = || { // xorshift64, then scale to (0, 1)
        state ^= state << 13; state ^= state >> 7; state ^= state << 17;
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let mut zs: Vec<f64> = (0..200000).map(|_| { let u1 = unif(); let u2 = unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos() }).collect();
    zs.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let zmc = -zs[1999]; // 1% of 200,000 draws lie below minus this
    let dfd = (call(S0 + 0.01, T) - call(S0 - 0.01, T)) / 0.02;
    let im1b = dfd * S0 * SIG * hday.sqrt() * zmc;
    let sdn = S0 * ((R_ - QD - 0.5 * SIG * SIG) * hday + SIG * hday.sqrt() * -zmc).exp();
    let im2 = c0 - call(sdn, T - hday);
    let mva = SIM * im1 * T;
    let dfund = FDF * im1;
    let dfc = HURDLE * dfund * T;
    let vclr = c0 - mva - dfc;

    // ---- the overlap: the mirror trade, bank sells the call, own spread 100 bp ----
    let lamb = SF / (1.0 - REC);
    let dva1 = (1.0 - REC) * c0 * (1.0 - (-lamb * T).exp());
    let fba1 = SF * c0 * (1.0 - (-lamb * T).exp()) / lamb;
    let dva2 = (1.0 - REC) * bucket_pd(lamb);
    let fba2 = SF * bucket_q(lamb);
    let dva200 = (1.0 - REC) * c0 * (1.0 - (-0.02 / (1.0 - REC) * T).exp());

    let rows: Vec<(&str, f64)> = vec![
        ("clean price, formula", c0), ("clean price, payoff integral", c0int),
        ("exposure annuity A_E, road 1", ae1), ("exposure annuity A_E, road 2", ae2),
        ("CVA, road 1", cva1), ("CVA, road 2", cva2), ("FVA, road 1", fva1), ("FVA, road 2", fva2),
        ("KVA, road 1", kva1), ("KVA, road 2", kva2),
        ("bilateral charges, total", cva1 + fva1 + kva1),
        ("adjusted price, road 1", v1), ("adjusted price, road 2", v2),
        ("z99 by bisection", z99), ("z99 by simulation", zmc), ("delta", delta), ("delta by bump", dfd),
        ("IM, delta-normal", im1), ("IM, delta-normal, simulated", im1b), ("IM, full revaluation", im2),
        ("MVA", mva), ("default-fund contribution", dfund), ("default-fund cost", dfc),
        ("cleared charges, total", mva + dfc), ("cleared price", vclr),
        ("cleared minus bilateral", vclr - v1),
        ("mirror: bank hazard", lamb), ("mirror: DVA, road 1", dva1), ("mirror: FBA, road 1", fba1),
        ("mirror: DVA, road 2", dva2), ("mirror: FBA, road 2", fba2),
        ("mirror: DVA + FBA, double counted", dva1 + fba1),
        ("mirror: DVA at 200 bp own spread", dva200), ("mirror: DVA gain, 100 -> 200 bp", dva200 - dva1),
        ("wrong: Black-Scholes at 6% funding", call_r(S0, T, 0.06)),
        ("wrong: no survival weighting", c0 - ((1.0 - REC) * LAM + SF + HURDLE * KCAP) * c0 * T),
        ("try: FVA at 200 bp", 0.02 * ae1), ("try: cleared charges, fund share 20%", mva + HURDLE * 0.20 * im1 * T),
    ];
    for (name, v) in &rows { println!("{:<36} {:>12.6}", name, v); }
    println!();
    let hz: Vec<String> = (0..11).map(|h| format!("{:6}", h)).collect();
    println!("chart, hazard %      {}", hz.join(" "));
    let line: Vec<f64> = (0..11).map(|h| {
        let lm = h as f64 / 100.0;
        let a = if h == 0 { c0 * T } else { c0 * (1.0 - (-lm * T).exp()) / lm };
        100.0 * ((1.0 - REC) * lm + SF + HURDLE * KCAP) * a
    }).collect();
    let bil: Vec<String> = line.iter().map(|v| format!("{:6.2}", v)).collect();
    println!("chart, bilateral c   {}", bil.join(" "));
    let clr: Vec<String> = (0..11).map(|_| format!("{:6.2}", 100.0 * (mva + dfc))).collect();
    println!("chart, cleared c     {}", clr.join(" "));

    assert!((c0int - c0).abs() < 1e-6, "payoff integral must land on the formula");
    assert!((ae2 - ae1).abs() < 1e-5, "weekly exposures must rebuild the closed-form annuity");
    assert!((v2 - v1).abs() < 1e-5, "bucket road and closed-form road must agree on the adjusted price");
    assert!((dva2 - fba2).abs() < 1e-6 && (dva2 - dva1).abs() < 1e-5, "DVA and FBA are one amount when spread = (1-R) x hazard");
    assert!((im1b - im1).abs() < 0.03, "simulated delta-normal margin near the bisection one");
    assert!(0.0 < im2 && im2 < im1, "curvature cushions a bought call: full revaluation loses less than delta says");
    assert!((line[2] / 100.0 - (c0 - v2)).abs() < 1e-5, "chart at a 2% hazard must equal the bucket road's charges");
    assert!((mva - 0.027).abs() < 5e-4 && (im1 - 5.4).abs() < 0.05, "margin and MVA must land on the house example");
    println!("ALL CHECKS PASS");
}
