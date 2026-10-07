// Digital Greeks and pin risk -- the check behind the card.  Rust std only, no crates.
// Bell-curve area by a series, brute-force prices by Simpson's rule, cut-off by bisection.
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T0: f64 = 1.0; const DAY: f64 = 1.0 / 365.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut i) = (x, x, 1.0);
    while t.abs() > 1e-16 * s.abs() { t *= x * x / (2.0 * i + 1.0); s += t; i += 1.0; }
    0.5 + s * phi(x)
}
fn dd(s: f64, sg: f64, t: f64, rr: f64) -> (f64, f64, f64) {
    let v = sg * t.sqrt();
    let d1 = ((s / K).ln() + (rr - Q + 0.5 * sg * sg) * t) / v;
    (d1, d1 - v, v)
}
// road 1: the closed forms, differentiated by hand. [price, delta, gamma, vega, theta, rho]
fn cash_greeks(s: f64, sg: f64, t: f64) -> [f64; 6] {
    let (d1, d2, v) = dd(s, sg, t, R);
    let c = (-R * t).exp() * n_cdf(d2); let g = (-R * t).exp() * phi(d2);
    [c, g / (s * v), -g * d1 / (s * s * v * v), -g * d1 / sg,
     R * c + g * (d1 / (2.0 * t) - (R - Q) / v), -t * c + g * t.sqrt() / sg]
}
fn asset_greeks(s: f64, sg: f64, t: f64) -> [f64; 6] {
    let (d1, d2, v) = dd(s, sg, t, R);
    let a = s * (-Q * t).exp() * n_cdf(d1); let h = s * (-Q * t).exp() * phi(d1);
    [a, (-Q * t).exp() * n_cdf(d1) + h / (s * v), -h * d2 / (s * s * v * v), -h * d2 / sg,
     Q * a - h * ((R - Q) / v - d2 / (2.0 * t)), h * t.sqrt() / sg]
}
// road 2: average the payoffs over the bell curve by Simpson's rule; no d1, no d2
fn by_integral(s: f64, sg: f64, t: f64, rr: f64) -> [f64; 2] {
    let (mu, v, n) = ((rr - Q - 0.5 * sg * sg) * t, sg * t.sqrt(), 4000usize);
    let (mut lo, mut hi) = (-12.0, 12.0);
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if s * (mu + v * mid).exp() > K { hi = mid; } else { lo = mid; }
    }
    let h = (12.0 - hi) / n as f64;
    let (mut cs, mut asum) = (0.0, 0.0);
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let z = hi + i as f64 * h;
        cs += w * phi(z); asum += w * s * (mu + v * z).exp() * phi(z);
    }
    [(-rr * t).exp() * cs * h / 3.0, (-rr * t).exp() * asum * h / 3.0]
}
fn bumped(s: f64, sg: f64, t: f64) -> [[f64; 6]; 2] {
    let p = |s_: f64, g_: f64, t_: f64, r_: f64| by_integral(s_, g_, t_, r_);
    let mut out = [[0.0; 6]; 2];
    for j in 0..2 {
        let (f0, up, dn) = (p(s, sg, t, R)[j], p(s + 0.1, sg, t, R)[j], p(s - 0.1, sg, t, R)[j]);
        out[j] = [f0, (p(s + 0.01, sg, t, R)[j] - p(s - 0.01, sg, t, R)[j]) / 0.02,
                  (up - 2.0 * f0 + dn) / 0.01,
                  (p(s, sg + 1e-4, t, R)[j] - p(s, sg - 1e-4, t, R)[j]) / 2e-4,
                  -(p(s, sg, t + 1e-4, R)[j] - p(s, sg, t - 1e-4, R)[j]) / 2e-4,
                  (p(s, sg, t, R + 1e-4)[j] - p(s, sg, t, R - 1e-4)[j]) / 2e-4];
    }
    out
}
// road 3: the ordinary call's own Greeks. [price, delta, gamma, vega]
fn call_greeks(s: f64, sg: f64, t: f64) -> [f64; 4] {
    let (d1, d2, v) = dd(s, sg, t, R);
    [s * (-Q * t).exp() * n_cdf(d1) - K * (-R * t).exp() * n_cdf(d2), (-Q * t).exp() * n_cdf(d1),
     (-Q * t).exp() * phi(d1) / (s * v), s * (-Q * t).exp() * phi(d1) * t.sqrt()]
}
fn root(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn out(label: &str, vals: &[f64]) {
    println!("{:<30}{}", label, vals.iter().map(|x| format!("{:>12.6}", x)).collect::<String>());
}
fn row(label: &str, xs: &[f64], f: &dyn Fn(f64) -> f64, dec: usize) {
    println!("chart {:<8}{}", label, xs.iter().map(|&x| format!("{:>8.*}", dec, f(x))).collect::<String>());
}

fn main() {
    let (d1, d2, _) = dd(S0, SIG, T0, R);
    let (cg, ag, cl) = (cash_greeks(S0, SIG, T0), asset_greeks(S0, SIG, T0), call_greeks(S0, SIG, T0));
    let [bc, ba] = bumped(S0, SIG, T0);
    out("d1, d2, N(d1), N(d2)", &[d1, d2, n_cdf(d1), n_cdf(d2)]);
    out("phi(d1), phi(d2), e^-qT, e^-rT", &[phi(d1), phi(d2), (-Q * T0).exp(), (-R * T0).exp()]);
    println!("{:<30}{:>12}{:>12}{:>12}{:>12}", "", "cash,form", "cash,bump", "asset,form", "asset,bump");
    for (k, name) in ["price", "delta", "gamma", "vega", "theta", "rho"].iter().enumerate() {
        out(name, &[cg[k], bc[k], ag[k], ba[k]]);
    }
    let pde: Vec<f64> = [cg, ag].iter()
        .map(|g| g[4] + (R - Q) * S0 * g[1] + 0.5 * SIG * SIG * S0 * S0 * g[2] - R * g[0]).collect();
    out("PDE balance cash, asset", &pde);
    out("call gamma, call delta", &[cl[2], cl[1]]);
    out("call + K x cash: price, delta", &[cl[0] + K * cg[0], cl[1] + K * cg[1]]);
    out("call + K x cash: gamma, vega", &[cl[2] + K * cg[2], cl[3] + K * cg[3]]);
    out("vega per vol point cash, asset", &[cg[3] / 100.0, ag[3] / 100.0]);
    let xc = root(&|s| cash_greeks(s, SIG, T0)[3], 80.0, 120.0);
    let xa = root(&|s| asset_greeks(s, SIG, T0)[3], 80.0, 120.0);
    let turn_c = K * (-(R - Q + 0.5 * SIG * SIG) * T0).exp();
    out("cash turn: search, formula", &[xc, turn_c]);
    out("asset turn: search, formula", &[xa, K * (-(R - Q - 0.5 * SIG * SIG) * T0).exp()]);
    let mut best = (f64::MIN, 0.0);
    for i in 0..=4000 {
        let s = 80.0 + i as f64 / 100.0; let d = cash_greeks(s, SIG, T0)[1]; if d > best.0 { best = (d, s); }
    }
    out("cash delta peak by scan", &[best.1]);
    let (c90, c97) = (cash_greeks(90.0, SIG, T0), cash_greeks(97.0, SIG, T0));
    out("cash vega, gamma at 90 and 97", &[c90[3], c97[3], c90[2], c97[2]]);
    println!("delta at S = 100 by time left:  delta, stock $ per $1 paid");
    let times = [("1 year", 1.0), ("3 months", 0.25), ("1 month", 1.0 / 12.0), ("1 week", 7.0 * DAY),
                 ("1 day", DAY), ("1 hour", DAY / 24.0)];
    let mut bars = String::from("bars, stock $ per $1 paid");
    for (i, &(lab, t)) in times.iter().enumerate() {
        let dl = cash_greeks(S0, SIG, t)[1]; out(&format!("  {}", lab), &[dl, S0 * dl]);
        if i < 5 { bars += &format!("{:>8.2}", S0 * dl); }
    }
    println!("{}", bars);
    out("1 day: gamma, bump delta, turn", &[cash_greeks(S0, SIG, DAY)[2], bumped(S0, SIG, DAY)[0][1],
        K * (-(R - Q + 0.5 * SIG * SIG) * DAY).exp()]);
    println!("1 day left, delta across the strike");
    for s in [98.0, 99.0, 99.5, 100.0, 100.5, 101.0, 102.0] {
        let g = cash_greeks(s, SIG, DAY); out(&format!("  S = {:.1}", s), &[g[1], g[0]]);
    }
    // ---- pin risk: short one cash digital, hedged daily in shares, Acme pinned near 100 ----
    let path = [100.00, 100.60, 99.50, 100.30, 99.90];
    println!("hedge trace, days left: S, digital, shares held, trade");
    for end in [100.20, 99.80] {
        let prem = cash_greeks(path[0], SIG, 5.0 * DAY)[0];
        let (mut held, mut bank) = (0.0, prem);
        for (day, &s) in path.iter().enumerate() {
            let left = (5 - day) as f64 * DAY;
            let g = cash_greeks(s, SIG, left);
            bank -= (g[1] - held) * s;
            if end == 100.20 { out(&format!("  with {} left", 5 - day), &[s, g[0], g[1], g[1] - held]); }
            held = g[1]; bank = bank * (R * DAY).exp() + held * s * ((Q * DAY).exp() - 1.0);
        }
        let pay = if end > K { 1.0 } else { 0.0 };
        out(&format!("  end {:.2}: pays, hedge P&L", end), &[pay, bank + held * end - pay]);
    }
    // ---- charts and what breaks ----
    let xs: Vec<f64> = (0..11).map(|i| 90.0 + 2.0 * i as f64).collect();
    row("S     ", &xs, &|x| x, 0);
    for (lab, t) in [("Dx100 1y", 1.0), ("Dx100 1m", 1.0 / 12.0), ("Dx100 1w", 7.0 * DAY)] {
        row(lab, &xs, &|x| 100.0 * cash_greeks(x, SIG, t)[1], 2);
    }
    let vs: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    row("S     ", &vs, &|x| x, 0);
    row("vega 1y", &vs, &|x| cash_greeks(x, SIG, T0)[3], 2);
    let g0 = (-R * T0).exp() * phi(d2);
    out("wrong: no chain rule, delta", &[g0]);
    out("wrong: asset delta as a call", &[(-Q * T0).exp() * n_cdf(d1)]);
    out("wrong: rho, discount frozen", &[g0 * T0.sqrt() / SIG]);
    out("wrong: 1-year delta at 1 day", &[cg[1]]);

    assert!((cg[0] - 0.494581).abs() < 5e-7, "house cash digital");
    assert!((ag[0] - 58.685115).abs() < 5e-7, "house asset digital");
    for k in 0..6 {
        assert!((cg[k] - bc[k]).abs() < 1e-6 * (1.0 + cg[k].abs()), "cash Greek {}: formula vs bumped integral", k);
        assert!((ag[k] - ba[k]).abs() < 1e-6 * (1.0 + ag[k].abs()), "asset Greek {}: formula vs bumped integral", k);
    }
    assert!((cg[1] - cl[2]).abs() < 1e-12, "at S = K the cash delta equals the call's gamma");
    assert!((cl[3] + K * cg[3] - ag[3]).abs() < 1e-9, "asset vega = call vega + K cash vegas");
    assert!(pde.iter().all(|x| x.abs() < 1e-9), "theta balances the pricing equation for both digitals");
    assert!((xc - turn_c).abs() < 1e-9, "vega turns at d1 = 0");
    assert!(c90[3] > 0.0 && 0.0 > cg[3], "cash vega changes sign below the strike");
    assert!(c97[2] < 0.0 && 0.0 < c90[2], "cash gamma changes sign below the strike");
    println!("ALL CHECKS PASS");
}
