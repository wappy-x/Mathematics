// Caplets on compounded SOFR -- the check behind the card.  std only, no crates.
// Nothing used knows the answer: the normal CDF is the Taylor series of erf written out,
// the integrals are Simpson's rule, the random numbers come from a xorshift generator.
use std::f64::consts::PI;

fn n_cdf(x: f64) -> f64 {
    if x.abs() > 8.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let y = x / 2f64.sqrt();
    let (mut term, mut s, mut n) = (y, y, 0.0);
    while term.abs() > 1e-17 { n += 1.0; term *= -y * y / n; s += term / (2.0 * n + 1.0); }
    0.5 + s / PI.sqrt()
}
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn black(f: f64, k: f64, sig: f64, t: f64) -> f64 { // caplet per unit of rate, before discounting
    let v = sig * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * v * v) / v;
    f * n_cdf(d1) - k * n_cdf(d1 - v)
}
fn bachelier(f: f64, k: f64, sn: f64, t: f64) -> f64 { // normal model: m N(d) + s phi(d)
    let s = sn * t.sqrt();
    let d = (f - k) / s;
    (f - k) * n_cdf(d) + s * phi(d)
}
fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}
fn show(label: &str, x: f64, d: usize) { println!("{:<44}{:>14.*}", label, d, x); }
fn g_fmt(x: f64) -> String { // like Python's :g for these short numbers
    let s = format!("{:.4}", x);
    s.trim_end_matches('0').trim_end_matches('.').to_string()
}

const F: f64 = 0.05; const K: f64 = 0.05; const SIG: f64 = 0.30; const TS: f64 = 1.75; const TE: f64 = 2.0;
const TAU: f64 = TE - TS;
fn g(t: f64) -> f64 { if t <= TS { 1.0 } else { (TE - t).max(0.0) / TAU } } // flat, then a straight fall

// Brute force: average n daily rates set by a random walk, rate j set at the start of day j
// (end = 1: set at the end of day j); Ts + (1/n^2) * sum of min(j, k) * h.
fn fixings_time(n: usize, end: usize) -> f64 {
    let h = TAU / n as f64;
    let mut s = 0.0;
    for j in end..n + end { for k in end..n + end { s += j.min(k) as f64 * h; } }
    TS + s / (n * n) as f64
}

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 ^= self.0 << 13; self.0 ^= self.0 >> 7; self.0 ^= self.0 << 17;
        ((self.0 >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}

fn main() {
    let notional = 10_000_000.0; let days = 63usize;
    let sq = |t: f64| g(t) * g(t);
    // Road 1: the one-third rule.  Road 2: Simpson on the squared shape.  Road 3: brute force.
    let (t_fwd, t_bwd) = (TS, TS + TAU / 3.0);
    let t_simp = simpson(sq, 0.0, TS, 2000) + simpson(sq, TS, TE, 2000);
    let (t_day, t_end) = (fixings_time(days, 0), fixings_time(days, 1));
    let dn = days as f64;
    assert!((t_simp - t_bwd).abs() < 1e-9 && (t_day - (TS + TAU * (dn - 1.0) * (2.0 * dn - 1.0) / (6.0 * dn * dn))).abs() < 1e-12);
    assert!((t_end - (TS + TAU * (dn + 1.0) * (2.0 * dn + 1.0) / (6.0 * dn * dn))).abs() < 1e-12 && t_day < t_bwd && t_bwd < t_end);
    assert!((fixings_time(1, 0) - t_fwd).abs() < 1e-15 && (fixings_time(400, 0) - t_bwd).abs() < 5e-4);
    show("variance time, forward-looking (years)", t_fwd, 6);
    show("variance time, Ts + tau/3 (years)", t_bwd, 6);
    show("variance time, Simpson on g squared", t_simp, 6);
    show("variance time, 63 daily fixings", t_day, 6);
    show("variance time, 63 fixings set at day end", t_end, 6);
    for n in [1usize, 3, 13] { show(&format!("variance time, {} fixings", n), fixings_time(n, 0), 6); }
    show("share of variance inside the period, %", 100.0 * (TAU / 3.0) / t_bwd, 2);
    show("log-sd still to come at Ts", SIG * (TAU / 3.0).sqrt(), 6);
    show("rate move of one sd at Ts, % points", 100.0 * F * SIG * (TAU / 3.0).sqrt(), 4);

    // Prices per unit notional, before discounting.  Road 4: Simpson over the lognormal, no N.
    let p_fwd = TAU * black(F, K, SIG, t_fwd);
    let p_bwd = TAU * black(F, K, SIG, t_bwd);
    let v = SIG * t_bwd.sqrt();
    let kink = ((K / F).ln() + 0.5 * v * v) / v; // payoff starts above the kink
    let p_int = TAU * simpson(|z| (F * (-0.5 * v * v + v * z).exp() - K) * phi(z), kink, 10.0, 8000);
    assert!((p_int - p_bwd).abs() < 1e-10 && (p_bwd / p_fwd - 1.0 - 0.0232).abs() < 1e-3);
    for (lab, t) in [("forward", t_fwd), ("backward", t_bwd)] {
        let sd = SIG * t.sqrt(); let d1 = ((F / K).ln() + 0.5 * sd * sd) / sd;
        show(&format!("sd of log rate, {}", lab), sd, 6); show(&format!("d1, {}", lab), d1, 6); show(&format!("d2, {}", lab), d1 - sd, 6);
        show(&format!("N(d1), {}", lab), n_cdf(d1), 6);
    }
    show("Black caplet, forward-looking", p_fwd, 7);
    show("Black caplet, backward-looking", p_bwd, 7);
    show("Black caplet, backward, Simpson", p_int, 7);
    show("Black caplet, 63 daily fixings", TAU * black(F, K, SIG, t_day), 7);
    show("Black uplift, %", 100.0 * (p_bwd / p_fwd - 1.0), 2);
    show("on $10m, forward-looking, $", notional * p_fwd, 2);
    show("on $10m, backward-looking, $", notional * p_bwd, 2);
    show("on $10m, difference, $", notional * (p_bwd - p_fwd), 2);

    // Bachelier: the normal volatility that matches the forward-looking price, then the one-third clock.
    let sn = p_fwd / TAU * (2.0 * PI / t_fwd).sqrt(); // at the money: price = tau * sN * sqrt(T / 2 pi)
    let q_fwd = TAU * bachelier(F, K, sn, t_fwd);
    let q_bwd = TAU * bachelier(F, K, sn, t_bwd);
    assert!((q_fwd - p_fwd).abs() < 1e-12 && (q_bwd / q_fwd - (t_bwd / t_fwd).sqrt()).abs() < 1e-12);
    show("normal volatility matched, bp", 1e4 * sn, 2);
    show("Bachelier caplet, forward-looking", q_fwd, 7);
    show("Bachelier caplet, backward-looking", q_bwd, 7);
    show("Bachelier uplift, %", 100.0 * (q_bwd / q_fwd - 1.0), 2);

    // Road 5: Monte Carlo of the rate itself, one shock a day; during day j its log-volatility is
    // sig times the share of days still unset.  Antithetic pairs; no variance formula used.
    let mut rng = Rng(88172645463325252);
    let h = TAU / dn;
    let mut vols = vec![SIG * TS.sqrt()];
    for j in 1..=days { vols.push(SIG * (days - j) as f64 / dn * h.sqrt()); }
    let drift = -0.5 * vols.iter().map(|s| s * s).sum::<f64>();
    let pairs = 100_000usize;
    let (mut total, mut total2) = (0.0, 0.0);
    for _ in 0..pairs {
        let (mut x, mut y) = (drift, drift);
        let mut k = 0;
        while k < vols.len() {
            let r = (-2.0 * rng.uniform().ln()).sqrt();
            let a = 2.0 * PI * rng.uniform();
            x += vols[k] * r * a.cos(); y -= vols[k] * r * a.cos();
            if k + 1 < vols.len() { x += vols[k + 1] * r * a.sin(); y -= vols[k + 1] * r * a.sin(); }
            k += 2;
        }
        let pay = 0.5 * TAU * ((F * x.exp() - K).max(0.0) + (F * y.exp() - K).max(0.0));
        total += pay; total2 += pay * pay;
    }
    let mc = total / pairs as f64;
    let se = ((total2 / pairs as f64 - mc * mc) / pairs as f64).sqrt();
    assert!((mc - TAU * black(F, K, SIG, t_day)).abs() < 3.0 * se && (mc - p_fwd).abs() > 3.0 * se);
    show("Monte Carlo caplet, 63 daily shocks", mc, 7);
    show("Monte Carlo standard error", se, 7);

    // What breaks, and the experiments on the card.
    show("wrong: full vol to the period end", TAU * black(F, K, SIG, TE), 7);
    show("wrong: average the vol, Ts + tau/2", TAU * black(F, K, SIG, TS + TAU / 2.0), 7);
    show("wrong: discount D(Ts), overprice %", 100.0 * TAU * F, 2); // D(Ts) / D(Te) = 1 + tau F
    show("wrong: discount D(Ts), in D(Te) units", (1.0 + TAU * F) * p_bwd, 7);
    show("try: first caplet, 0.25 to 0.5, fwd", TAU * black(F, K, SIG, 0.25), 7);
    show("try: first caplet, 0.25 to 0.5, bwd", TAU * black(F, K, SIG, 0.25 + TAU / 3.0), 7);
    show("try: period starting today, bwd", TAU * black(F, K, SIG, TAU / 3.0), 7);
    show("try: six-month period 1.75 to 2.25, bwd", 0.5 * black(F, K, SIG, TS + 0.5 / 3.0), 7);
    show("try: six-month period, fwd", 0.5 * black(F, K, SIG, TS), 7);
    let mut times: Vec<f64> = (0..8).map(|i| 0.25 * i as f64).collect();
    times.extend([1.8125, 1.875, 1.9375, 2.0]);
    let row = |f: &dyn Fn(f64) -> String| times.iter().map(|&t| f(t)).collect::<Vec<_>>().join(" ");
    println!("chart, time     {}", row(&|t| g_fmt(t)));
    println!("chart, term vol {}", row(&|t| g_fmt(100.0 * SIG * if t <= TS { 1.0 } else { 0.0 })));
    println!("chart, sofr vol {}", row(&|t| g_fmt(100.0 * SIG * g(t))));
    let cum: Vec<f64> = times[7..].iter().map(|&u| TS + simpson(sq, TS, u, 2000)).collect();
    println!("moves, var time {}", cum.iter().map(|c| format!("{:.6}", c)).collect::<Vec<_>>().join(" "));
    println!("moves, added    {}", cum.windows(2).map(|w| format!("{:.6}", w[1] - w[0])).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
