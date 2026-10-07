// Risk limits and the appetite behind them -- the check behind the card.  Rust std only.
// Book: long Acme shares, each hedged by one sold one-year call (house market).  Roads: Greeks
// by formula and by bumping; VaR by the exact quantile and by 40,000 simulated days; largest size
// by the min rule and by a scan; days to the stop by exact count, simulation and square law.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const DT: f64 = 1.0 / 252.0; // one trading day, in years
const NAMES: [&str; 5] = ["notional", "delta", "vega", "stress", "VaR"];

fn n_cdf(x: f64) -> f64 { // normal CDF, Marsaglia's positive series
    if x < 0.0 { return 1.0 - n_cdf(-x); }
    let (mut t, mut s, mut i) = (x, x, 1.0);
    while t > 1e-17 * s { t *= x * x / (2.0 * i + 1.0); s += t; i += 1.0; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn call(s: f64, sig: f64) -> (f64, f64) {
    let d1 = ((s / K).ln() + (R - Q + 0.5 * sig * sig) * T) / (sig * T.sqrt());
    (s * (-Q * T).exp() * n_cdf(d1) - K * (-R * T).exp() * n_cdf(d1 - sig * T.sqrt()), d1)
}
fn call_int(s: f64, sig: f64) -> f64 { // road 2: Simpson on the discounted payoff
    let n = 4000;
    let g = |z: f64| (s * ((R - Q - 0.5 * sig * sig) * T + sig * T.sqrt() * z).exp() - K).max(0.0) * phi(z);
    let w = |i: usize| if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    (-R * T).exp() * 20.0 / n as f64 / 3.0 * (0..=n).map(|i| w(i) * g(-10.0 + 20.0 * i as f64 / n as f64)).sum::<f64>()
}
fn unit(s: f64, sig: f64) -> f64 { s - call(s, sig).0 } // one share minus one sold call
fn delta_pct(s: f64, sig: f64) -> f64 { (1.0 - (-Q * T).exp() * n_cdf(call(s, sig).1)) * s * 0.01 }
fn vega_pt(s: f64, sig: f64) -> f64 { -s * (-Q * T).exp() * phi(call(s, sig).1) * T.sqrt() * 0.01 }
fn z_low(p: f64) -> f64 { // N(z) = p by bisection
    let (mut lo, mut hi) = (-10.0, 10.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < p { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn var_exact(s: f64, sig: f64, z01: f64) -> f64 { // unit value rises with S: 1% spot quantile
    let s1 = s * (-0.5 * sig * sig * DT + z01 * sig * DT.sqrt()).exp();
    unit(s, sig) - unit(s1, sig)
}
struct Rng { x: u64 } // xorshift64 and Box-Muller
impl Rng {
    fn u(&mut self) -> f64 {
        let mut x = self.x;
        x ^= x << 13; x ^= x >> 7; x ^= x << 17;
        self.x = x;
        ((x >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn z(&mut self) -> f64 { (-2.0 * self.u().ln()).sqrt() * (2.0 * PI * self.u()).cos() }
}
fn var_mc(s: f64, sig: f64, n: usize, rng: &mut Rng) -> f64 {
    let v0 = unit(s, sig);
    let mut losses: Vec<f64> = (0..n)
        .map(|_| v0 - unit(s * (-0.5 * sig * sig * DT + sig * DT.sqrt() * rng.z()).exp(), sig))
        .collect();
    losses.sort_by(|a, b| a.partial_cmp(b).unwrap());
    losses[(0.99 * n as f64) as usize - 1]
}
fn coin_exact(n: u64) -> u64 { n * (n + 1) }
fn coin_mc(n: i64, paths: usize, rng: &mut Rng) -> f64 {
    let mut tot: u64 = 0;
    for _ in 0..paths {
        let (mut d, mut t) = (0i64, 0u64);
        while d < n { t += 1; d = if rng.u() < 0.5 { 0.max(d - 1) } else { d + 1 }; }
        tot += t;
    }
    tot as f64 / paths as f64
}
fn show(name: &str, v: String) { println!("{:<40}{}", name, v); }
fn f(v: f64, p: usize) -> String { format!("{:>16.*}", p, v) }

fn main() {
    let z01 = z_low(0.01);
    // ---- the appetite, and the caps derived from it ----
    let (cap, stop_frac, patience) = (50e6, 0.03, 100.0);
    let l = stop_frac * cap;
    let caps = [0.40 * cap, l / 2.0 / 20.0, l / 2.0 / 15.0, l, (-z01 * l / f64::sqrt(patience) / 1e4).round() * 1e4];
    // ---- per-unit measures at today's market ----
    let c0 = call(S0, SIG).0;
    let h = 1e-4;
    let d_bump = (unit(S0 + h, SIG) - unit(S0 - h, SIG)) / (2.0 * h) * S0 * 0.01;
    let v_bump = (unit(S0, SIG + h) - unit(S0, SIG - h)) / (2.0 * h) * 0.01;
    let stress = unit(S0, SIG) - unit(80.0, 0.35); // loss per unit, -20% spot, +15 vol points
    let per = [S0 + K, delta_pct(S0, SIG), vega_pt(S0, SIG).abs(), stress, var_exact(S0, SIG, z01)];
    let v_mc = var_mc(S0, SIG, 40000, &mut Rng { x: 88172645463325252 });
    let stress_int = (S0 - call_int(S0, SIG)) - (80.0 - call_int(80.0, 0.35));
    let bind: Vec<f64> = (0..5).map(|k| caps[k] / per[k]).collect();
    let qstar = bind.iter().cloned().fold(f64::INFINITY, f64::min);
    let mut scan: u64 = 0; // road 2: grow the book one unit at a time
    while (0..5).all(|k| (scan + 1) as f64 * per[k] <= caps[k]) { scan += 1; }

    show("house call C(100, 20%)", f(c0, 4)); show("stop L = 3% of capital", f(l, 2));
    show("z, 1% point of the bell curve", f(z01, 4)); show("VaR cap before rounding, z L / 10", f(-z01 * l / f64::sqrt(patience), 2));
    show("half the stop, L/2", f(l / 2.0, 2));
    for k in 0..5 { show(&format!("cap {}", NAMES[k]), f(caps[k], 2)); }
    show("unit delta $/1%: formula, bump", format!("{:>16.6}{:>12.6}", per[1], d_bump));
    show("unit vega $/pt: formula, bump", format!("{:>16.6}{:>12.6}", vega_pt(S0, SIG), v_bump));
    show("unit stress loss: formula, integral", format!("{:>16.4}{:>12.4}", stress, stress_int)); show("call after shock C(80, 35%)", f(call(80.0, 0.35).0, 4));
    show("unit VaR99: exact, 40,000 days", format!("{:>16.4}{:>12.4}", per[4], v_mc));
    for k in 0..5 { show(&format!("binding size, {}", NAMES[k]), f(bind[k], 1)); }
    show("largest size: min rule, scan", format!("{:>16.1}{:>12}", qstar, scan));

    // ---- scenario A: a proposed trade from 75,000 to 95,000 units; scenario B: the shock day ----
    let (q0, qnew, dd0) = (75000.0, 95000.0, 300000.0);
    let post = [80.0 + K, delta_pct(80.0, 0.35), vega_pt(80.0, 0.35).abs(),
                unit(80.0, 0.35) - unit(64.0, 0.50), var_exact(80.0, 0.35, z01)];
    println!("utilisation %          today   proposed   after shock");
    for k in 0..5 {
        println!("  {:<18}{:>9.2}{:>11.2}{:>14.2}", NAMES[k], 100.0 * q0 * per[k] / caps[k],
                 100.0 * qnew * per[k] / caps[k], 100.0 * q0 * post[k] / caps[k]);
    }
    let loss_b = q0 * stress;
    show("shock loss, drawdown after", format!("{:>16.2}{:>12.2}", loss_b, dd0 + loss_b));
    show("stop utilisation %: before, after", format!("{:>16.2}{:>12.2}", 100.0 * dd0 / l, 100.0 * (dd0 + loss_b) / l));
    show("stop left L - D; stress use of it %", format!("{:>16.2}{:>12.2}", l - dd0, 100.0 * loss_b / (l - dd0)));
    show("post-shock unit delta $/1%", f(post[1], 4)); show("post-shock unit VaR99", f(post[4], 4));

    // ---- what breaks ----
    let taylor = -(per[1] * -20.0 + vega_pt(S0, SIG) * 15.0); // delta and vega only
    show("wrong: stress by delta+vega, per unit", f(taylor, 4)); show("  its binding size", f(l / taylor, 1));
    show("wrong: net notional per unit", f(S0 - K, 2));
    show("wrong: patience linear, VaR cap", f(-z01 * l / patience, 2));
    let mut eq = vec![0.0f64];
    for p in [600000.0, -1700000.0] { let last = *eq.last().unwrap(); eq.push(last + p); }
    let peak = eq.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let last = *eq.last().unwrap();
    show("path: loss from start, from peak", format!("{:>16.2}{:>12.2}", -last, peak - last));

    // ---- days to the stop: coin walk, simulation, Brownian square law ----
    let mc10 = coin_mc(10, 20000, &mut Rng { x: 2463534242 });
    let sd_now = q0 * per[4] / -z01; // daily sd implied by today's VaR
    show("L/sigma = 10: coin walk, exact days", f(coin_exact(10) as f64, 0));
    show("L/sigma = 10: coin walk, 20,000 walks", f(mc10, 2));
    show("L/sigma = 10: Brownian (L/sigma)^2", f(100.0, 0));
    show("book today: VaR99", f(q0 * per[4], 2)); show("book today: daily sd = VaR/2.3263", f(sd_now, 2));
    show("book today: L/sigma, Brownian days", format!("{:>16.2}{:>12.0}", l / sd_now, (l / sd_now).powi(2)));
    let sizes: Vec<u64> = (0..=120).step_by(20).collect();
    println!("chart, size (thousand units)  {}", sizes.iter().map(|s| format!("{:>7}", s)).collect::<Vec<_>>().join(" "));
    for k in 0..5 {
        let row: Vec<String> = sizes.iter().map(|&s| format!("{:>7.2}", 100.0 * s as f64 * 1000.0 * per[k] / caps[k])).collect();
        println!("chart, {:<23}{}", NAMES[k], row.join(" "));
    }
    let ns: Vec<u64> = (2..=12).step_by(2).collect();
    let row = |g: &dyn Fn(u64) -> u64| ns.iter().map(|&n| format!("{:>5}", g(n))).collect::<Vec<_>>().join(" ");
    println!("chart, L/sigma               {}", row(&|n| n));
    println!("chart, coin n(n+1)           {}", row(&coin_exact));
    println!("chart, Brownian n^2          {}", row(&|n| n * n));

    assert!((c0 - 9.227005508154).abs() < 1e-9, "house call from another card");
    assert!((d_bump - per[1]).abs() < 1e-6, "delta: bump vs formula");
    assert!((v_bump - vega_pt(S0, SIG)).abs() < 1e-6, "vega: bump vs formula");
    assert!((stress_int - stress).abs() < 1e-4, "stress: integral vs formula");
    assert!((0..5).all(|k| bind[1] <= bind[k]), "delta binds first");
    assert!(dd0 + loss_b > l, "the shock day breaches the stop");
    assert!((v_mc - per[4]).abs() < 0.03 * per[4], "VaR: simulation vs exact quantile");
    assert!(scan == qstar as u64, "largest size: scan vs min rule");
    assert!((mc10 - coin_exact(10) as f64).abs() < 3.0, "days to stop: simulation vs exact count");
    println!("ALL CHECKS PASS");
}
