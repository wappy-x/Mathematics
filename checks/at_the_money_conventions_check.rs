// Three meanings of at-the-money on EURUSD: spot, forward, delta-neutral straddle.
// Road 1: closed forms. Road 2: prices by integrating the payoff, deltas by nudging spot,
// strikes by bisection on those nudged deltas. Road 3: the cheapest straddle by golden section.
const S: f64 = 1.10;
const RD: f64 = 0.05;
const RF: f64 = 0.03;
const VOL: f64 = 0.10;
const T: f64 = 1.0;

fn ncdf(x: f64) -> f64 {
    // normal CDF from its Taylor series, no library erf
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        n += 1.0;
        term *= x * x / (2.0 * n + 1.0);
        total += term;
    }
    0.5 + (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() * total
}

fn d1d2(s: f64, k: f64, vol: f64) -> (f64, f64) {
    let w = vol * T.sqrt();
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * vol * vol) * T) / w;
    (d1, d1 - w)
}

fn gk(s: f64, k: f64) -> (f64, f64) {
    // road 1: Garman-Kohlhagen call and put, USD per EUR
    let (d1, d2) = d1d2(s, k, VOL);
    let c = s * (-RF * T).exp() * ncdf(d1) - k * (-RD * T).exp() * ncdf(d2);
    (c, c - s * (-RF * T).exp() + k * (-RD * T).exp())
}

fn net_delta(k: f64) -> f64 {
    (-RF * T).exp() * (2.0 * ncdf(d1d2(S, k, VOL).0) - 1.0)
}

fn net_pa(k: f64) -> f64 {
    k * (-RD * T).exp() / S * (2.0 * ncdf(d1d2(S, k, VOL).1) - 1.0)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 1200;
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h)).sum();
    h / 3.0 * (f(a) + f(b) + inner)
}

fn integ(s: f64, k: f64) -> (f64, f64) {
    // road 2: average the payoffs over the bell curve, split at the kink
    let (w, fwd) = (VOL * T.sqrt(), s * ((RD - RF) * T).exp());
    let st = move |z: f64| fwd * (w * z - 0.5 * w * w).exp();
    let phi = |z: f64| (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt();
    let zk = ((k / fwd).ln() + 0.5 * w * w) / w;
    let put = simpson(&|z| (k - st(z)) * phi(z), -12.0, zk);
    let call = simpson(&|z| (st(z) - k) * phi(z), zk, 12.0);
    ((-RD * T).exp() * call, (-RD * T).exp() * put)
}

fn bump(k: f64, adjusted: bool) -> f64 {
    // straddle delta by nudging spot, strike held fixed
    let h = 1e-4;
    let v = |s: f64| { let (c, p) = integ(s, k); (c + p) / if adjusted { s } else { 1.0 } };
    (if adjusted { S } else { 1.0 }) * (v(S + h) - v(S - h)) / (2.0 * h)
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..40 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn golden(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..50 {
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(a) < f(b) { hi = b } else { lo = a }
    }
    0.5 * (lo + hi)
}

fn row(label: &str, vals: &[f64], p: usize) {
    // a value that rounds to zero prints as 0, never -0
    let cut = 0.5 * 10f64.powi(-(p as i32));
    let cells: String = vals.iter().map(|&v| format!("{:>11.*}", p, if v.abs() >= cut { v } else { 0.0 })).collect();
    println!("{:<34}{}", label, cells);
}

fn main() {
    let f = S * ((RD - RF) * T).exp();
    let k_dns = f * (0.5 * VOL * VOL * T).exp();
    let k_pa = f * (-0.5 * VOL * VOL * T).exp();
    let k_dns2 = bisect(&|k| bump(k, false), 1.05, 1.20);
    let k_pa2 = bisect(&|k| bump(k, true), 1.05, 1.20);
    let k_min = golden(&|k| { let (c, p) = integ(S, k); c + p }, 1.05, 1.20);
    row("forward F = S e^(rd-rf)T", &[f], 6);
    row("strike: spot ATM, K = S", &[S], 6);
    row("strike: forward ATM, K = F", &[f], 6);
    row("strike: DNS, formula | bisection", &[k_dns, k_dns2], 6);
    row("strike: DNS p.a., formula | bisect", &[k_pa, k_pa2], 6);
    row("strike: cheapest straddle, golden", &[k_min], 6);
    row("e^.02, e^.005, e^-.005, e^-.03", &[f / S, k_dns / f, k_pa / f, (-RF * T).exp()], 6);
    row("gaps in pips: DNS-S DNS-F F-p.a.", &[1e4 * (k_dns - S), 1e4 * (k_dns - f), 1e4 * (f - k_pa)], 1);
    let names = [("spot ATM", S), ("forward ATM", f), ("DNS", k_dns), ("DNS p.a.", k_pa)];
    println!("at each strike                     d1         call       put        straddle   by integral");
    for (nm, k) in names {
        let ((c, p), (ci, pi)) = (gk(S, k), integ(S, k));
        row(&format!("  {nm}"), &[d1d2(S, k, VOL).0, c, p, c + p, ci + pi], 6);
    }
    println!("net straddle delta                 formula    by nudge   p.a. form  p.a. nudge");
    for (nm, k) in names {
        row(&format!("  {nm}"), &[net_delta(k), bump(k, false), net_pa(k), bump(k, true)], 6);
    }
    let dfr = (-RF * T).exp();
    row("DNS call, put spot delta", &[dfr * ncdf(0.0), -dfr * ncdf(0.0)], 4);
    let half = k_pa * (-RD * T).exp() / S * ncdf(0.0);
    row("p.a. call, put delta at DNS p.a.", &[half, -half], 4);
    row("  same by e^-rfT N(d1) - C/S", &[dfr * ncdf(d1d2(S, k_pa, VOL).0) - gk(S, k_pa).0 / S], 4);
    let k_wrong = S * (0.5 * VOL * VOL * T).exp();
    row("wrong: S in place of F, strike", &[k_wrong], 6);
    row("  its net delta", &[net_delta(k_wrong)], 4);
    row("wrong: p.a. strike, USD premium", &[net_delta(k_pa)], 4);
    let k_nosq = f * (0.5 * VOL * T).exp();
    row("wrong: vol not squared, strike", &[k_nosq], 6);
    row("  its net delta", &[net_delta(k_nosq)], 4);
    for v in [0.05, 0.20] {
        row(&format!("try: vol {v:.2}, DNS | DNS p.a."), &[f * (0.5 * v * v * T).exp(), f * (-0.5 * v * v * T).exp()], 6);
    }
    let f5 = S * ((RD - RF) * 5.0).exp();
    row("try: 5 years, F | DNS | DNS p.a.", &[f5, f5 * (0.5 * VOL * VOL * 5.0).exp(), f5 * (-0.5 * VOL * VOL * 5.0).exp()], 6);
    row("try: rd = rf = 3%, F | DNS", &[S, S * (0.5 * VOL * VOL * T).exp()], 6);
    let smile = |k: f64| 0.10 - 0.20 * (k / f).ln() + 1.0 * (k / f).ln().powi(2);
    let mut k_s = f;
    for _ in 0..60 { k_s = f * (0.5 * smile(k_s).powi(2) * T).exp(); }
    row("smile: ATM strike by iteration", &[k_s], 6);
    row("  vol there | vol at F", &[smile(k_s), smile(f)], 6);
    row("  formula at that quoted vol", &[f * (0.5 * smile(k_s).powi(2) * T).exp()], 6);
    row("  formula at vol read at F", &[f * (0.5 * smile(f).powi(2) * T).exp()], 6);
    let grid: Vec<f64> = (0..10).map(|i| 1.08 + 0.01 * i as f64).collect();
    let line = |lab: &str, g: &dyn Fn(f64) -> f64, p: usize| {
        println!("{lab}{}", grid.iter().map(|&k| format!("{:>8.*}", p, g(k))).collect::<String>());
    };
    line("chart, strike    ", &|k| k, 2);
    line("chart, net delta ", &|k| net_delta(k), 2);
    line("chart, p.a. net  ", &|k| net_pa(k), 2);
    line("chart, straddle  ", &|k| { let (c, p) = gk(S, k); c + p }, 4);
    assert!((k_dns - k_dns2).abs() < 1e-6 && (k_pa - k_pa2).abs() < 1e-6, "{} {}", k_dns2, k_pa2);
    assert!((k_min - k_pa).abs() < 1e-6, "{}", k_min);
    let (ci, pi) = integ(S, k_dns);
    let (c, p) = gk(S, k_dns);
    assert!((c + p - ci - pi).abs() < 1e-9);
    assert!((gk(S, f).0 - integ(S, f).1).abs() < 1e-9);
    assert!(bump(k_dns, false).abs() < 1e-6 && (net_delta(S) - bump(S, false)).abs() < 1e-6);
    assert!(net_pa(k_pa2).abs() < 1e-6 && (net_pa(S) - bump(S, true)).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
