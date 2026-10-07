// Certainty equivalent and risk premium -- the check behind the card.  Rust std only.
// Every number quoted on the card is printed here.  Road 1 is each closed form.  Road 2 solves
// u(c) = E[u(W)] by bisection, using only the utility itself.  Road 3 (the fund) is a Monte Carlo
// with its own random numbers.  The normal average is Simpson's rule written out.
use std::f64::consts::PI;

fn u_crra(g: f64, w: f64) -> f64 { if g == 1.0 { w.ln() } else { w.powf(1.0 - g) / (1.0 - g) } }
fn u_cara(a: f64, w: f64) -> f64 { -(-a * w).exp() }
fn eu(u: &dyn Fn(f64) -> f64, outs: &[(f64, f64)]) -> f64 {
    let mut s = 0.0;
    for &(p, w) in outs { s += p * u(w); }
    s
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    for _ in 0..n {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn ce_bisect(u: &dyn Fn(f64) -> f64, outs: &[(f64, f64)]) -> f64 {
    let t = eu(u, outs);
    let lo = outs.iter().map(|o| o.1).fold(f64::INFINITY, f64::min);
    let hi = outs.iter().map(|o| o.1).fold(f64::NEG_INFINITY, f64::max);
    bisect(&|c| u(c) - t, lo, hi, 200)
}
fn ce_crra(g: f64, outs: &[(f64, f64)]) -> f64 {
    if g == 1.0 { return eu(&|w: f64| w.ln(), outs).exp(); }
    eu(&|w: f64| w.powf(1.0 - g), outs).powf(1.0 / (1.0 - g))
}
fn ce_cara(a: f64, outs: &[(f64, f64)]) -> f64 { -eu(&|w: f64| (-a * w).exp(), outs).ln() / a }
fn arrow_pratt(outs: &[(f64, f64)]) -> f64 {   // half of -u''/u' at the mean (1/w for the log), times the variance
    let mn = eu(&|w| w, outs);
    0.5 * (1.0 / mn) * eu(&|w| (w - mn) * (w - mn), outs)
}
fn row(name: &str, v: f64, d: usize) { println!("{:<40} {:>12.*}", name, d, v); }
fn simpson(f: &dyn Fn(f64) -> f64) -> f64 {
    let (a, b, n) = (-10.0, 10.0, 4000);
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}

fn main() {
    // ---- the coin flip: all of $100 staked, ends at $150 or $50 ----
    let coin = [(0.5, 150.0), (0.5, 50.0)];
    let mean = eu(&|w| w, &coin);
    let var = eu(&|w| (w - mean) * (w - mean), &coin);
    let (ce1, ce2) = ((150.0f64 * 50.0).sqrt(), ce_bisect(&|w| u_crra(1.0, w), &coin));
    row("mean wealth", mean, 4); row("variance", var, 2);
    row("E[ln W]", eu(&|w| w.ln(), &coin), 4); row("ln of the mean", mean.ln(), 4);
    row("CE log, geometric mean", ce1, 4); row("CE log, bisection", ce2, 4);
    row("risk premium, log", mean - ce1, 4);
    row("Arrow-Pratt premium, log", arrow_pratt(&coin), 2);
    assert!((ce1 - ce2).abs() < 1e-9);
    println!("\nladder: g, CE power mean, CE bisection, premium");
    let mut ladder = vec![];
    for (g, lab) in [(0.0, "0"), (0.5, "0.5"), (1.0, "1"), (2.0, "2"), (4.0, "4"), (10.0, "10")] {
        let a_ = ce_crra(g, &coin);
        let b_ = ce_bisect(&|w| u_crra(g, w), &coin);
        ladder.push(a_);
        println!("  g = {:<5} {:>12.2} {:>12.2} {:>10.2}", lab, a_, b_, mean - a_);
        assert!((a_ - b_).abs() < 1e-8);
    }
    assert!(ladder.windows(2).all(|p| p[0] > p[1]));             // more curvature, lower CE: Jensen
    assert!((ladder[3] - 2.0 / (1.0 / 150.0 + 1.0 / 50.0)).abs() < 1e-9); // g = 2: harmonic mean
    row("CE cara a = 0.01", ce_cara(0.01, &coin), 4);
    row("CE cara, bisection", ce_bisect(&|w| u_cara(0.01, w), &coin), 4);
    row("premium cara, wealth 100", mean - ce_cara(0.01, &coin), 4);
    assert!((ce_cara(0.01, &coin) - ce_bisect(&|w| u_cara(0.01, w), &coin)).abs() < 1e-9);
    row("premium cara, wealth 200", 200.0 - ce_cara(0.01, &[(0.5, 250.0), (0.5, 150.0)]), 4);
    row("CE log, wealth 200", (250.0f64 * 150.0).sqrt(), 4);
    row("premium log, wealth 200", 200.0 - (250.0f64 * 150.0).sqrt(), 4);
    row("CE log, 10x scale", (1500.0f64 * 500.0).sqrt(), 2);
    assert!((ce_bisect(&|w| w.ln(), &[(0.5, 1500.0), (0.5, 500.0)]) - 10.0 * ce1).abs() < 1e-9); // power scales
    assert!((ce_bisect(&|w| u_cara(0.01, w), &[(0.5, 250.0), (0.5, 150.0)]) - 100.0 - ce_cara(0.01, &coin)).abs() < 1e-9); // CARA shifts

    // ---- the premium against the stake: exact 100 - sqrt(100^2 - x^2), Arrow-Pratt x^2/200 ----
    let (mut l1, mut l2, mut l3) = (String::from("stake x   "), String::from("exact     "), String::from("A-P x^2/200"));
    for i in 0..10 {
        let x = 10.0 * i as f64;
        let ex = if i > 0 { 100.0 - ce_bisect(&|w| w.ln(), &[(0.5, 100.0 + x), (0.5, 100.0 - x)]) } else { 0.0 };
        l1 += &format!("{:>7}", 10 * i);
        l2 += &format!("{:>7.2}", ex);
        let ap = format!("{:>7.2}", arrow_pratt(&[(0.5, 100.0 + x), (0.5, 100.0 - x)]));
        l3 += if i == 0 { &ap[1..] } else { &ap };
    }
    println!("\n{}\n{}\n{}", l1, l2, l3);
    let small = 100.0 - ce_bisect(&|w| w.ln(), &[(0.5, 105.0), (0.5, 95.0)]);
    let ap5 = arrow_pratt(&[(0.5, 105.0), (0.5, 95.0)]);
    row("stake 5: exact", small, 4); row("stake 5: Arrow-Pratt", ap5, 4);
    assert!((small / ap5 - 1.0).abs() < 0.01);      // the approximation is exact in the limit

    let (mut c1, mut c2, mut c3) = (String::from("chart W   "), String::from("ln W      "), String::from("chord     "));
    for w in (50..160).step_by(10) {
        let wf = w as f64;
        c1 += &format!("{:>6}", w);
        c2 += &format!("{:>6.2}", wf.ln());
        c3 += &format!("{:>6.2}", 50f64.ln() + (wf - 50.0) / 100.0 * (150f64.ln() - 50f64.ln()));
    }
    println!("\n{}\n{}\n{}", c1, c2, c3);

    // ---- insurance: wealth $100, a 10% chance of losing $60 ----
    let risk = [(0.9, 100.0), (0.1, 40.0)];
    let (ce_i, ce_ib) = (100.0 * 0.4f64.powf(0.1), ce_bisect(&|w| w.ln(), &risk));
    let el = 0.1 * 60.0;
    row("insurance CE, closed form", ce_i, 4); row("insurance CE, bisection", ce_ib, 4);
    row("most the owner pays, 100 - CE", 100.0 - ce_i, 4); row("expected loss", el, 2);
    row("risk premium, insurance", 100.0 - ce_i - el, 4);
    row("Arrow-Pratt, insurance", arrow_pratt(&risk), 4);
    assert!((ce_i - ce_ib).abs() < 1e-9);
    assert!((100.0f64 - 8.0).ln() > eu(&|w| w.ln(), &risk));   // insuring at $8.00 beats keeping the risk
    row("buy at 8.00: E[ln], insured", 92f64.ln(), 4); row("E[ln], uninsured", eu(&|w| w.ln(), &risk), 4);

    // ---- the house fund: gross return lognormal, mean 1.08, spread 0.15; deposit 1.04 ----
    let (m, sd, dep) = (1.08f64, 0.15f64, 1.04f64);
    let s2 = (1.0 + (sd / m) * (sd / m)).ln();
    let mu = m.ln() - s2 / 2.0;
    let rr = |z: f64| (mu + s2.sqrt() * z).exp();
    let dens = |z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt();
    assert!((simpson(&|z| rr(z) * dens(z)) - m).abs() < 1e-9);                    // the fund's mean is 1.08
    assert!((simpson(&|z| (rr(z) - m).powi(2) * dens(z)).sqrt() - sd).abs() < 1e-9); // and its spread 0.15
    let ce_fund = |g: f64| {
        let t = simpson(&|z| u_crra(g, rr(z)) * dens(z));
        bisect(&|c| u_crra(g, c) - t, 0.5, 2.0, 200)
    };
    row("fund s^2", s2, 6); row("fund mu", mu, 6);
    let (ce_f1, ce_f2) = (mu.exp(), ce_fund(1.0));
    row("fund CE log, closed form", ce_f1, 4); row("fund CE log, Simpson", ce_f2, 4);
    let mut seed: u64 = 20260928;
    let mut rnd = || {                  // 64-bit linear congruential generator, top 53 bits
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((seed >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let (mut acc, n_mc) = (0.0, 200000);
    for _ in 0..n_mc / 2 {
        let r_ = (-2.0 * rnd().ln()).sqrt();
        let t_ = 2.0 * PI * rnd();
        acc += rr(r_ * t_.cos()).ln() + rr(r_ * t_.sin()).ln();
    }
    let ce_mc = (acc / n_mc as f64).exp();
    row("fund CE log, Monte Carlo", ce_mc, 4);
    assert!((ce_f1 - ce_f2).abs() < 1e-9);
    assert!((ce_f1 - ce_mc).abs() < 1e-3);
    row("fund premium log, in points", 100.0 * (m - ce_f1), 4);
    row("Arrow-Pratt, fund, in points", 100.0 * 0.5 * sd * sd / m, 4);
    let g_star = 1.0 - 2.0 * (dep.ln() - mu) / s2;
    let g_bis = bisect(&|g| dep - ce_fund(g), 1.5, 8.0, 60);
    row("gamma where fund = deposit, closed", g_star, 4);
    row("gamma where fund = deposit, bisection", g_bis, 4);
    assert!((g_star - g_bis).abs() < 1e-6);
    row("fund CE g = 2, in percent", 100.0 * (ce_fund(2.0) - 1.0), 4);
    row("fund CE g = 6, in percent", 100.0 * (ce_fund(6.0) - 1.0), 4);
}
