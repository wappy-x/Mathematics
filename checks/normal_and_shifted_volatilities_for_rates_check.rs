// Rate volatilities: one 1-into-5 payer swaption quoted lognormal, normal and shifted,
// converted at the money and away from it. std only; N(x), the root finder and the
// integrator are written here.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

// bell-curve area left of x: 1/2 + phi(x) * sum x^(2n+1)/(1*3*...*(2n+1))
fn n_cdf(x: f64) -> f64 {
    if x < 0.0 { return 1.0 - n_cdf(-x); }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut n) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        n += 1.0;
        term *= x * x / (2.0 * n + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}

fn bisect<G: Fn(f64) -> f64>(f: G, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn simpson<G: Fn(f64) -> f64>(g: G, a: f64, b: f64) -> f64 {
    let n = 4000;
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    s * h / 3.0
}

// Road 1: closed forms, payer premium in rate units
fn black(f: f64, k: f64, s: f64, t: f64) -> f64 {
    let w = s * t.sqrt();
    let d1 = ((f / k).ln() + 0.5 * w * w) / w;
    f * n_cdf(d1) - k * n_cdf(d1 - w)
}
fn bachelier(f: f64, k: f64, sn: f64, t: f64) -> f64 {
    let v = sn * t.sqrt();
    let d = (f - k) / v;
    (f - k) * n_cdf(d) + v * phi(d)
}
fn shifted(f: f64, k: f64, s: f64, t: f64, a: f64) -> f64 { black(f + a, k + a, s, t) }

// Road 2: the same premiums as averages of the payoff over each model's spread of outcomes
fn black_int(f: f64, k: f64, s: f64, t: f64) -> f64 {
    let w = s * t.sqrt();
    let z0 = ((k / f).ln() + 0.5 * w * w) / w;
    simpson(|z| (f * (-0.5 * w * w + w * z).exp() - k) * phi(z), z0, z0 + 16.0)
}
fn bachelier_int(f: f64, k: f64, sn: f64, t: f64) -> f64 {
    let v = sn * t.sqrt();
    let z0 = (k - f) / v;
    simpson(|z| (f + v * z - k) * phi(z), z0, z0 + 16.0)
}

fn implied_normal(f: f64, k: f64, p: f64, t: f64) -> f64 { bisect(|s| bachelier(f, k, s, t) - p, 1e-9, 0.5) }
fn implied_black(f: f64, k: f64, p: f64, t: f64) -> f64 { bisect(|s| black(f, k, s, t) - p, 1e-9, 20.0) }
fn implied_shifted(f: f64, k: f64, p: f64, t: f64, a: f64) -> f64 { bisect(|s| shifted(f, k, s, t, a) - p, 1e-9, 20.0) }
fn log_mean(x: f64, y: f64) -> f64 { if (x - y).abs() < 1e-14 { x } else { (x - y) / (x / y).ln() } }

fn show(label: &str, v: f64) { println!("{:<40}{:>14.6}", label, v); }
fn show2(label: &str, v: f64) { println!("{:<40}{:>14.2}", label, v); }

fn main() {
    // 1-year expiry into a 5-year swap, annual fixed payments, flat curve at 4.4% annual
    let (t, sig, a, notional) = (1.0_f64, 0.30_f64, 0.02_f64, 10_000_000.0_f64);
    let d: Vec<f64> = (0..7).map(|i| 1.044_f64.powi(-i)).collect();
    let ann: f64 = d[2..7].iter().sum();
    let f = (d[1] - d[6]) / ann;
    let bp = 1e4;

    show("annuity A, years", ann);
    show("forward swap rate F, bp", f * bp);
    let p = black(f, f, sig, t);
    show("  N(w/2), w = sigma*sqrt(T) = 0.30", n_cdf(0.5 * sig * t.sqrt()));
    show("  bracket 2N(w/2) - 1", 2.0 * n_cdf(0.5 * sig * t.sqrt()) - 1.0);
    show("  sqrt(2 pi / T)", (2.0 * PI / t).sqrt());
    show("  shrink 1 - w^2/24", 1.0 - sig * sig * t / 24.0);
    show("1 ATM premium, Black formula, bp", p * bp);
    show("2 ATM premium, Black integral, bp", black_int(f, f, sig, t) * bp);
    show2("  premium, dollars", notional * ann * p);
    let sn_root = implied_normal(f, f, p, t);
    let sn_exact = f * (2.0 * PI / t).sqrt() * (2.0 * n_cdf(0.5 * sig * t.sqrt()) - 1.0);
    show("3 normal vol, root finder, bp", sn_root * bp);
    show("4 normal vol, exact ATM formula, bp", sn_exact * bp);
    show("  rule F*sigma, bp", f * sig * bp);
    show("  rule F*sigma*(1 - w^2/24), bp", f * sig * (1.0 - sig * sig * t / 24.0) * bp);
    show("5 Bachelier integral at that vol, bp", bachelier_int(f, f, sn_root, t) * bp);
    for sh in [0.01, 0.02, 0.03] {
        show(&format!("  shifted vol, shift {:.0} bp, %", sh * bp), implied_shifted(f, f, p, t, sh) * 100.0);
        show(&format!("  rule sigma*F/(F+a), shift {:.0} bp, %", sh * bp), sig * f / (f + sh) * 100.0);
    }
    let ss = implied_shifted(f, f, p, t, a);
    show("  shifted bracket p/(F+a), 200 bp", p / (f + a));
    show("  log mean of F and K = 540, bp", log_mean(f, 0.054) * bp);

    println!();
    println!("flat 30% lognormal, by strike (bp; vols: normal in bp, shifted 200 bp in %)");
    println!("{:>6}{:>9}{:>10}{:>9}{:>10}{:>9}{:>15}", "K", "premium", "sN exact", "sN rule", "sS exact", "sS rule", "sB if sN flat");
    let (mut sn_by_k, mut worst) = (Vec::new(), 0.0_f64);
    for i in 0..9 {
        let k = 0.024 + 0.005 * i as f64;
        let pk = black(f, k, sig, t);
        let snk = implied_normal(f, k, pk, t);
        let rule_n = sig * log_mean(f, k) * (1.0 - sig * sig * t / 24.0);
        let ssk = implied_shifted(f, k, pk, t, a);
        let rule_s = sig * log_mean(f, k) / log_mean(f + a, k + a);
        let sbk = implied_black(f, k, bachelier(f, k, sn_root, t), t);
        worst = worst.max((rule_n - snk).abs());
        sn_by_k.push(snk);
        println!("{:>6.0}{:>9.2}{:>10.2}{:>9.2}{:>10.2}{:>9.2}{:>15.2}", k * bp, pk * bp, snk * bp, rule_n * bp, ssk * 100.0, rule_s * 100.0, sbk * 100.0);
    }
    show("worst gap, log-mean rule vs exact, bp", worst * bp);

    println!();
    let k_lo = bisect(|k| f - bachelier(f, k, sn_root, t), 1e-9, f);
    show("flat normal: no lognormal vol below K, bp", k_lo * bp);
    let r1 = notional * ann * (bachelier(f, 0.024, f * sig, t) - (f - 0.024)); // receiver = payer - (F - K)
    let r0 = notional * ann * (black(f, 0.024, sig, t) - (f - 0.024));
    show2("wrong: 132 bp receiver at K = 240, $", r1);
    show2("  right: 30% lognormal receiver, $", r0);
    show2("wrong: 2%-shift vol used with 1% shift, $", notional * ann * shifted(f, f, ss, t, 0.01));
    show2("wrong: 1.3151% read as lognormal, $", notional * ann * black(f, f, sn_root, t));
    let p10 = black(f, f, sig, 10.0);
    show("wrong: F*sigma at 10 years, bp", f * sig * bp);
    show("  right: exact at 10 years, bp", implied_normal(f, f, p10, 10.0) * bp);
    show("try: F = 100 bp, 30% lognormal -> sN, bp", implied_normal(0.01, 0.01, black(0.01, 0.01, sig, t), t) * bp);
    show("try: F = 340 bp, 30% lognormal -> sN, bp", implied_normal(0.034, 0.034, black(0.034, 0.034, sig, t), t) * bp);
    show("try: sN held at 131.51, F = 340 -> sB, %", implied_black(0.034, 0.034, bachelier(0.034, 0.034, sn_root, t), t) * 100.0);

    assert!((f - 0.044).abs() < 1e-15, "the curve prices the forward at 4.4%");
    assert!((black_int(f, f, sig, t) - p).abs() < 1e-12, "Black integral road meets the formula");
    assert!((sn_root - sn_exact).abs() < 1e-12, "root finder meets the exact ATM conversion");
    assert!((bachelier_int(f, f, sn_root, t) - p).abs() < 1e-12, "normal model at the implied vol reprices by integral");
    assert!((black_int(f + a, f + a, ss, t) - p).abs() < 1e-12, "shifted model at the implied vol reprices by integral");
    assert!(worst < 1e-6, "log-mean rule within 0.01 bp, 240 to 640");
    assert!(sn_by_k.windows(2).all(|w| w[0] < w[1]), "flat lognormal means normal vol rising with strike");
    println!("ALL CHECKS PASS");
}
