// Kelly criterion -- the same check as kelly_criterion_and_growth_check.py, in Rust.
// Standard library only, no crates.  The search, the log series, the random
// numbers, the ruin sums and the integral are all written out below.
use std::f64::consts::PI;

const P: f64 = 0.55;
const Q: f64 = 0.45;
const B: f64 = 1.0;

fn g(f: f64) -> f64 { P * (1.0 + B * f).ln() + Q * (1.0 - f).ln() }   // expected log growth per bet

fn ln_series(x: f64) -> f64 {                     // ln x = 2(z + z^3/3 + ...), z = (x-1)/(x+1)
    let z = (x - 1.0) / (x + 1.0);
    2.0 * (0..40).map(|k| z.powi(2 * k + 1) / (2 * k + 1) as f64).sum::<f64>()
}

fn golden_max<F: Fn(f64) -> f64>(func: F, mut lo: f64, mut hi: f64) -> f64 {   // road 2: no calculus
    let r = (5.0_f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 {
        let (a, c) = (hi - r * (hi - lo), lo + r * (hi - lo));
        if func(a) < func(c) { lo = a } else { hi = c }
    }
    (lo + hi) / 2.0
}

fn median_wins(n: usize) -> usize {               // exact binomial median, summed in logs
    let mut lp = vec![0.0_f64];
    for k in 0..n {
        let last = lp[k];
        lp.push(last + ((n - k) as f64 / (k + 1) as f64).ln() + (P / Q).ln());
    }
    let top = lp.iter().cloned().fold(f64::MIN, f64::max);
    let w: Vec<f64> = lp.iter().map(|v| (v - top).exp()).collect();
    let tot: f64 = w.iter().sum();
    let mut run = 0.0;
    for k in 0..=n {
        run += w[k] / tot;
        if run >= 0.5 { return k; }
    }
    n
}

fn splitmix(state: &mut u64) -> f64 {             // road 3's random numbers, same as Python
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}

fn chance_ever_below(f: f64, x: f64, horizon: usize) -> f64 {   // exact: sum surviving paths
    let (up, dn, bar) = ((1.0 + B * f).ln(), (1.0 - f).ln(), x.ln());
    let (mut alive, mut hit) = (vec![1.0_f64], 0.0_f64);
    for n in 1..=horizon {
        let mut new = vec![0.0_f64; n + 1];
        for (k, m) in alive.iter().enumerate() { new[k + 1] += P * m; new[k] += Q * m; }
        for k in 0..=n {
            if new[k] > 0.0 && k as f64 * up + (n - k) as f64 * dn <= bar { hit += new[k]; new[k] = 0.0; }
        }
        alive = new;
    }
    hit
}

fn brownian_ever_below(f: f64, x: f64) -> f64 {  // approximation: log wealth as drift plus noise
    let s2 = P * Q * ((1.0 + B * f) / (1.0 - f)).ln().powi(2);
    (-2.0 * g(f) * (1.0 / x).ln() / s2).exp().min(1.0)
}

fn main() {
    let f_star = P - Q / B;
    let f_gold = golden_max(g, 0.0, 0.99);
    let n = 1000_usize;
    let k_med = median_wins(n);
    let kf = k_med as f64;
    let score = |f: f64| kf * (1.0 + B * f).ln() + (n as f64 - kf) * (1.0 - f).ln();
    let mut f_med = 0.0;
    for i in 0..300 { let f = i as f64 / 1000.0; if score(f) > score(f_med) { f_med = f; } }
    let (g_log, g_ser) = (g(f_star), P * ln_series(1.0 + B * f_star) + Q * ln_series(1.0 - f_star));
    let (mut state, paths) = (20260928_u64, 2000_usize);
    let mut wins = Vec::new();
    for _ in 0..paths {
        let mut k = 0_u32;
        for _ in 0..n { if splitmix(&mut state) < P { k += 1; } }
        wins.push(k as f64);
    }
    let g_sim = wins.iter().map(|k| k * 1.1_f64.ln() + (n as f64 - k) * 0.9_f64.ln()).sum::<f64>() / (paths * n) as f64;
    let se = (P * Q).sqrt() * (1.1_f64 / 0.9).ln() / ((paths * n) as f64).sqrt();
    let rows: Vec<(&str, f64)> = vec![
        ("f* road 1, formula p - q/b", f_star), ("f* road 2, golden-section search", f_gold),
        ("f* road 3, best median, 1000 bets", f_med), ("median wins in 1000 bets", kf),
        ("ln(1 + b f*), a win", (1.0 + B * f_star).ln()), ("ln(1 - f*), a loss", (1.0 - f_star).ln()),
        ("p ln(1 + b f*)", P * (1.0 + B * f_star).ln()), ("q ln(1 - f*)", Q * (1.0 - f_star).ln()),
        ("g(f*) per bet, library log", g_log), ("g(f*) per bet, own log series", g_ser),
        ("g(f*) simulated, 2000 x 1000 bets", g_sim), ("  its standard error", se),
        ("bets to double at f*, ln 2 / g", 2.0_f64.ln() / g_log),
        ("simple mean return per bet at f*", f_star * (B * P - Q)),
        ("mean wealth x after 1000 bets", (n as f64 * (1.0 + f_star * (B * P - Q)).ln()).exp()),
        ("median wealth x after 1000 bets", (kf * (1.0 + B * f_star).ln() + (n as f64 - kf) * (1.0 - f_star).ln()).exp()),
        ("$100, win then loss, full Kelly", 100.0 * (1.0 + B * f_star) * (1.0 - f_star)),
        ("$100, win then loss, half Kelly", 100.0 * (1.0 + B * f_star / 2.0) * (1.0 - f_star / 2.0)),
    ];
    for (name, v) in &rows { println!("{:<36} {:>16.12}", name, v); }

    // ---- fractional Kelly: c times the Kelly stake ----
    println!();
    println!("{:>5} {:>6} {:>9} {:>8} {:>7} {:>7} {:>11} {:>7} {:>11}", "c", "stake", "g x1000", "of best", "c(2-c)", "spread", "halve,exact", "approx", "0.5^(2/c-1)");
    let mut frac = Vec::new();
    for c in [0.25_f64, 0.5, 1.0, 1.5, 2.0] {
        let f = c * f_star;
        let (gf, ex, ap) = (g(f), chance_ever_below(f, 0.5, 4000), brownian_ever_below(f, 0.5));
        frac.push((c, gf, ex, ap));
        let spread = (P * Q).sqrt() * ((1.0 + B * f) / (1.0 - f)).ln();
        println!("{:>5.2} {:>6.3} {:>9.4} {:>8.4} {:>7.4} {:>7.4} {:>11.3} {:>7.3} {:>11.3}",
                 c, f, 1000.0 * gf, gf / g_log, c * (2.0 - c), spread, ex, ap, 0.5_f64.powf(2.0 / c - 1.0).min(1.0));
    }

    // ---- what breaks ----
    println!();
    println!("{:<36} {:>16.12}", "wrong: bet it all, survive 20 bets", P.powi(20));
    println!("{:<36} {:>16.12}", "wrong: believe 60%, stake 0.20, g", g(0.20));
    println!("{:<36} {:>16.12}", "wrong: mean wealth, 20 bets all in", (1.0 + (B * P - Q)).powi(20));
    let xs: Vec<String> = (0..13).map(|i| format!("{:5.2}", i as f64 * 0.02)).collect();
    println!("chart f      {}", xs.join(" "));
    let ys: Vec<String> = (0..13).map(|i| format!("{:5.2}", 1000.0 * g(i as f64 * 0.02))).collect();
    println!("chart g x1000{}", ys.join(" "));

    // ---- the saver: deposit 4%, fund mean 8%, spread 15%, rebalanced daily ----
    let (r, mu, sig) = (0.04_f64, 0.08_f64, 0.15_f64);
    let big_f = (mu - r) / (sig * sig);
    let gc = |f: f64| r + f * (mu - r) - 0.5 * f * f * sig * sig;
    let g_quad = |f: f64| {                       // road 2: average ln(new/old) over one day
        let (dt, m) = (1.0 / 252.0, 4000_usize);
        let (h, mut tot) = (20.0 / m as f64, 0.0);
        for i in 0..=m {
            let z = -10.0 + i as f64 * h;
            let rr = ((mu - 0.5 * sig * sig) * dt + sig * dt.sqrt() * z).exp() - 1.0;
            let wt = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
            tot += wt * (-z * z / 2.0).exp() / (2.0 * PI).sqrt() * (1.0 + f * rr + (1.0 - f) * r * dt).ln();
        }
        tot * h / 3.0 / dt
    };
    let big_f_gold = golden_max(&g_quad, 0.0, 4.0);
    println!();
    for (name, v) in [("saver f* = (mu - r)/sigma^2", big_f), ("saver f*, search on daily quadrature", big_f_gold), ("saver g at f*, formula", gc(big_f)),
                      ("saver g at f*, daily quadrature", g_quad(big_f)), ("saver half Kelly stake", big_f / 2.0), ("saver g at half Kelly", gc(big_f / 2.0)),
                      ("saver g all in the fund", gc(1.0)), ("saver twice Kelly stake", 2.0 * big_f),
                      ("saver g at twice Kelly", gc(2.0 * big_f))] {
        println!("{:<36} {:>16.12}", name, v);
    }

    assert!((f_gold - f_star).abs() < 1e-6, "search lands on p - q/b");
    assert!((f_med - f_star).abs() < 5e-4, "median path peaks at p - q/b");
    assert!((g_ser - g_log).abs() < 1e-13, "log series agrees with ln");
    assert!((g_sim - g_log).abs() < 4.0 * se, "simulation agrees with g(f*)");
    assert!((frac[1].1 / g_log - 0.75).abs() < 0.01, "half Kelly keeps about 3/4 of the growth");
    assert!((frac[2].2 - frac[2].3).abs() < 0.03, "exact halving chance near the Brownian one");
    assert!((g_quad(big_f) - gc(big_f)).abs() < 1e-5, "daily rebalancing near the continuous formula");
    assert!((big_f_gold - big_f).abs() < 1e-3, "daily search lands on (mu - r)/sigma^2");
    println!("ALL CHECKS PASS");
}
