// Expected utility and risk aversion -- the check behind the card.  Rust std only.
// The same rows as the Python check.  Normal density, Simpson's rule, bisection and
// the random numbers are written out here; nothing is imported that knows the answer.
use std::f64::consts::PI;

const W0: f64 = 10000.0;
const DEP: f64 = 10400.0;
const UP: f64 = 12300.0;
const DN: f64 = 9300.0;

fn u(w: f64, g: f64) -> f64 { if g == 1.0 { w.ln() } else { w.powf(1.0 - g) / (1.0 - g) } }
fn u_inv(y: f64, g: f64) -> f64 { if g == 1.0 { y.exp() } else { (y * (1.0 - g)).powf(1.0 / (1.0 - g)) } }
fn ce_coin(g: f64) -> f64 { u_inv(0.5 * u(UP, g) + 0.5 * u(DN, g), g) }
fn vnm_p(w: f64, g: f64) -> f64 { (u(w, g) - u(DN, g)) / (u(UP, g) - u(DN, g)) }

fn ce_monte_carlo(g: f64, n: usize) -> f64 {
    let mut s: u64 = 88172645463325252;
    let mut total = 0.0;
    for _ in 0..n {
        s ^= s << 13; s ^= s >> 7; s ^= s << 17;
        let x = (s >> 11) as f64 / 2f64.powi(53);
        total += u(if x < 0.5 { UP } else { DN }, g);
    }
    u_inv(total / n as f64, g)
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn s2() -> f64 { (1.0 + (0.15f64 / 1.08).powi(2)).ln() }
fn m() -> f64 { 1.08f64.ln() - 0.5 * s2() }
fn ce_lognormal_formula(g: f64) -> f64 { W0 * (m() + 0.5 * (1.0 - g) * s2()).exp() }
fn ce_lognormal_simpson(g: f64) -> f64 {
    let n = 2000;
    let (a, b) = (-10.0, 10.0);
    let h = (b - a) / n as f64;
    let mut tot = 0.0;
    for i in 0..=n {
        let z = a + i as f64 * h;
        let wgt = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += wgt * u(W0 * (m() + s2().sqrt() * z).exp(), g) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt();
    }
    u_inv(tot * h / 3.0, g)
}

fn row(label: &str, v: f64, d: usize) { println!("{:<40}{:>14.*}", label, d, v); }

fn main() {
    let mean = 0.5 * UP + 0.5 * DN;
    let var = 0.5 * (UP - mean).powi(2) + 0.5 * (DN - mean).powi(2);
    row("deposit, sure wealth", DEP, 2);
    row("fund, expected wealth", mean, 2);
    row("fund, spread of wealth (dollars)", var.sqrt(), 2);
    row("fund, variance (dollars squared)", var, 2);
    row("spread / expected wealth", var.sqrt() / mean, 4);
    row("E[ln W], fund", 0.5 * UP.ln() + 0.5 * DN.ln(), 6);
    row("ln W, deposit", DEP.ln(), 6);
    for g in [1.0, 5.0] {
        println!("gamma = {}", g);
        row("  certainty equivalent, exact", ce_coin(g), 2);
        row("  certainty equivalent, simulated", ce_monte_carlo(g, 200000), 2);
        row("  vNM chance matching the deposit", vnm_p(DEP, g), 4);
        println!("{:<40}{:>14}", "  takes", if ce_coin(g) > DEP { "fund" } else { "deposit" });
    }
    row("log saver, CE minus deposit", ce_coin(1.0) - DEP, 2);

    // Arrow-Pratt by finite differences, on two differently scaled utilities
    let (w, h) = (mean, 1.0);
    let ap = |f: &dyn Fn(f64) -> f64| {
        let d1 = (f(w + h) - f(w - h)) / (2.0 * h);
        let d2 = (f(w + h) - 2.0 * f(w) + f(w - h)) / (h * h);
        (-d2 / d1, d2)
    };
    let (a_log, d2_log) = ap(&|x: f64| x.ln());
    let (a_pts, d2_pts) = ap(&|x: f64| 100.0 * (x / 10000.0).ln() + 7.0);
    row("A(10800), log, by differences", a_log, 9);
    row("A(10800), 100 ln(w/10000)+7", a_pts, 9);
    row("A(10800) = 1/w", 1.0 / w, 9);
    row("second derivative x 1e9, log", d2_log * 1e9, 4);
    row("same, 100 ln(w/10000)+7", d2_pts * 1e9, 4);

    // Pratt's rule against exact premiums
    let pratt = 0.5 * (1.0 / mean) * var;
    row("premium, log, exact", mean - ce_coin(1.0), 2);
    row("premium, log, Pratt 0.5 A var", pratt, 2);
    row("Pratt error, log", mean - ce_coin(1.0) - pratt, 2);
    let rich = 100000.0;
    let ce_rich = (0.5 * (rich + 2300.0f64).ln() + 0.5 * (rich - 700.0f64).ln()).exp();
    row("premium, same bet on 100,000, exact", rich + 800.0 - ce_rich, 2);
    let g_star = bisect(|g| ce_coin(g) - DEP, 1.5, 10.0);
    row("break-even gamma, coin fund, exact", g_star, 4);
    row("break-even gamma, Pratt rule", (mean - DEP) / pratt, 4);

    // the lognormal fund, formula and brute force
    let gl_formula = 1.0 + 2.0 * (m() - 1.04f64.ln()) / s2();
    let gl_simpson = bisect(|g| ce_lognormal_simpson(g) - DEP, 1.5, 10.0);
    println!("{:<26}{:>14.4}{:>14.4}", "lognormal, log-return mean, variance", m(), s2());
    row("lognormal CE, log, formula", ce_lognormal_formula(1.0), 2);
    row("lognormal CE, log, Simpson", ce_lognormal_simpson(1.0), 2);
    row("lognormal break-even gamma, formula", gl_formula, 4);
    row("lognormal break-even gamma, Simpson", gl_simpson, 4);

    // what breaks
    row("wrong: rank by expected wealth", mean, 2);
    row("wrong: u(E W) in place of E u(W)", u_inv(u(mean, 1.0), 1.0), 2);
    row("wrong: spread not squared, premium", 0.5 * (0.15 / 1.08) * mean, 2);
    row("wrong: gamma used as A, premium", 0.5 * 1.0 * var, 2);

    println!("chart, certainty equivalent for gamma 0 to 5, then 6 to 10");
    println!("{}", (0..6).map(|g| format!("{:>10.2}", ce_coin(g as f64))).collect::<String>());
    println!("{}", (6..11).map(|g| format!("{:>10.2}", ce_coin(g as f64))).collect::<String>());
    let xs: Vec<f64> = (0..7).map(|i| DN + 500.0 * i as f64).collect();
    let chord = |x: f64| 100.0 * (DN / W0).ln() + (x - DN) / (UP - DN) * 100.0 * ((UP / W0).ln() - (DN / W0).ln());
    println!("{:<14}{}", "chart, wealth", xs.iter().map(|x| format!("{:>8.0}", x)).collect::<String>());
    println!("{:<14}{}", "  100 ln(w/1e4)", xs.iter().map(|x| format!("{:>8.2}", 100.0 * (x / W0).ln())).collect::<String>());
    println!("{:<14}{}", "  chord", xs.iter().map(|x| format!("{:>8.2}", chord(*x))).collect::<String>());

    assert!((ce_coin(1.0) - (UP * DN).sqrt()).abs() < 1e-6, "log CE must be the geometric mean");
    assert!((ce_coin(2.0) - 2.0 / (1.0 / UP + 1.0 / DN)).abs() < 1e-6, "gamma 2 CE: harmonic mean");
    assert!((ce_monte_carlo(1.0, 200000) - ce_coin(1.0)).abs() < 10.0, "simulation within $10");
    assert!((a_log - 1.0 / w).abs() < 1e-9, "-u''/u' by differences vs 1/w");
    assert!((a_pts - 1.0 / w).abs() < 1e-9, "-u''/u' ignores rescaling and shifting");
    assert!((pratt - (mean - ce_coin(1.0))).abs() < 1.0, "Pratt's rule within $1 on this bet");
    assert!((ce_lognormal_simpson(1.0) - ce_lognormal_formula(1.0)).abs() < 1e-6, "lognormal CE two roads");
    assert!((gl_simpson - gl_formula).abs() < 1e-6, "break-even gamma two roads");
    assert!((ce_lognormal_simpson(0.0) - mean).abs() < 1e-6, "lognormal fund really has mean 10,800");
    assert!((vnm_p(DEP, 1.0) < 0.5) == (ce_coin(1.0) > DEP), "calibration and CE agree, log saver");
    assert!((vnm_p(DEP, 5.0) < 0.5) == (ce_coin(5.0) > DEP), "calibration and CE agree, gamma 5");
    assert!(ce_coin(1.0) > DEP && DEP > ce_coin(5.0), "log: fund; gamma 5: deposit");
    assert!(vnm_p(DEP, 1.0) < 0.5 && 0.5 < vnm_p(DEP, 5.0), "vNM chances either side of one half");
    assert!(ce_coin(3.9) > DEP && DEP > ce_coin(4.0) && (g_star - 3.9454).abs() < 5e-5, "crossing between 3.9 and 4");
    assert!((ap(&|x: f64| u(x, 5.0)).0 * w - 5.0).abs() < 1e-5, "power utility: w A(w) = gamma");
}
