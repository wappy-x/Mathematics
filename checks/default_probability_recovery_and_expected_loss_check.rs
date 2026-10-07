// Default probability, recovery and expected loss -- the same check in Rust.
// Standard library only, no crates.  Same roads: the product, the list of
// outcomes, a simulation with our own random numbers, and a bisection root
// finder for the fair rate and every back-solve.
// Compile: rustc --edition 2021 -O default_probability_recovery_and_expected_loss_check.rs

fn el(pd: f64, lgd: f64, ead: f64) -> f64 { pd * lgd * ead }                  // road 1

fn el_by_outcomes(outcomes: &[(f64, f64)]) -> f64 {                           // road 2
    outcomes.iter().map(|(chance, loss)| chance * loss).sum()
}

struct Rng { x: u64 }                                                          // 64-bit LCG
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.x >> 11) as f64 / 9007199254740992.0                             // 2^53
    }
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64) -> f64 {
    let mut flo = f(lo);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        let fm = f(mid);
        if (fm > 0.0) == (flo > 0.0) { lo = mid; flo = fm; } else { hi = mid; }
        if hi - lo < 1e-13 { break; }
    }
    0.5 * (lo + hi)
}

fn main() {
    let (ead, pd, rec, r) = (10000.0_f64, 0.05_f64, 0.40_f64, 0.05_f64);
    let lgd = 1.0 - rec;
    let el1 = el(pd, lgd, ead);
    let el2 = el_by_outcomes(&[(1.0 - pd, 0.0), (pd, ead * (1.0 - rec))]);
    let mut rng = Rng { x: 20260928 };
    let n = 400000;
    let (mut tot, mut tot2) = (0.0_f64, 0.0_f64);
    for _ in 0..n {                                   // road 3: recovery varies, 10% to 70%, mean 40%
        let loss = if rng.u() < pd { ead * (1.0 - (0.10 + 0.60 * rng.u())) } else { 0.0 };
        tot += loss;
        tot2 += loss * loss;
    }
    let el3 = tot / n as f64;
    let se = ((tot2 / n as f64 - el3 * el3) / n as f64).sqrt();

    // fair loan rate: (1 + y)(1 - PD LGD) = 1 + r, recovery on everything owed
    let ell = pd * lgd;
    let y_closed = (1.0 + r) / (1.0 - ell) - 1.0;
    let pv = |y: f64| ((1.0 - pd) * ead * (1.0 + y) + pd * rec * ead * (1.0 + y)) / (1.0 + r) - ead;
    let y_root = bisect(pv, 0.0, 1.0);
    let y_zero = 1.0 / (1.0 - ell) - 1.0;

    // back-solves
    let pd_back = 0.09 / (1.0 - 0.40);
    let pd_root = bisect(|p| el(p, 0.60, 1.0) - 0.09, 0.0, 1.0);
    let lgd_back = 300.0 / (pd * ead);
    let lgd_root = bisect(|g| el(pd, g, ead) - 300.0, 0.0, 1.0);
    let ead_back = 300.0 / (pd * lgd);
    let ead_root = bisect(|a| el(pd, lgd, a) - 300.0, 0.0, 1e6);
    let pd_impossible = 0.09 / (1.0 - 0.95);

    // two kinds of year: (chance of year, PD, recovery)
    let states = [(0.8_f64, 0.025_f64, 0.55_f64), (0.2, 0.15, 0.30)];
    let pd_avg: f64 = states.iter().map(|(w, p, _)| w * p).sum();
    let rec_year: f64 = states.iter().map(|(w, _, rc)| w * rc).sum();
    let rec_dflt: f64 = states.iter().map(|(w, p, rc)| w * p * rc).sum::<f64>() / pd_avg;
    let outs: Vec<(f64, f64)> = states.iter().map(|(w, p, rc)| (w * p, ead * (1.0 - rc))).collect();
    let el_true = el_by_outcomes(&outs);
    let el_naive = el(pd_avg, 1.0 - rec_year, ead);

    // what breaks
    let wrong_rec = el(pd, rec, ead);
    let wrong_nopd = el(1.0, lgd, ead);
    let short_8 = ead * 1.08 * (1.0 - ell) / (1.0 + r) - ead;
    let nw_pd5 = 1.0 - (-0.02_f64 * 5.0).exp();
    let nw_el = el(nw_pd5, 0.60, 100e6);

    let rows: Vec<(&str, f64)> = vec![
        ("LGD = 1 - R", lgd), ("EL rate PD x LGD", ell),
        ("1 EL, product", el1), ("2 EL, list the outcomes", el2),
        ("3 EL, 400000 simulated cafes", el3), ("  standard error", se),
        ("loss if default", ead * lgd), ("recovered if default", ead * rec),
        ("fair rate, closed form", y_closed), ("fair rate, root finder", y_root),
        ("  spread over 5%", y_closed - r), ("  spread, riskless rate 0", y_zero),
        ("PD from 9% at R 40%", pd_back), ("  by root finder", pd_root),
        ("LGD from EL 300", lgd_back), ("  by root finder", lgd_root),
        ("EAD from EL 300", ead_back), ("  by root finder", ead_root),
        ("PD from 9% at R 95%", pd_impossible),
        ("two-state PD", pd_avg), ("  recovery, year-averaged", rec_year),
        ("  recovery, default-weighted", rec_dflt),
        ("  EL, true", el_true), ("  EL, year-averaged recovery", el_naive),
        ("wrong: recovery as the loss", wrong_rec), ("wrong: default certain", wrong_nopd),
        ("wrong: charge 8%, PV shortfall", short_8),
        ("Northwind 5y default chance", nw_pd5), ("Northwind 5y EL, undiscounted", nw_el),
        ("try: PD 10%", el(0.10, lgd, ead)), ("try: R 0%", el(pd, 1.0, ead)),
        ("try: fair rate, PD 20%", (1.0 + r) / (1.0 - 0.20 * lgd) - 1.0),
    ];
    for (name, v) in &rows { println!("{:<32} {:>16.6}", name, v); }

    println!();
    let recs = [0.0_f64, 0.2, 0.4, 0.6, 0.8, 1.0];
    let mut head = format!("{:<22}", "chart, recovery %");
    for x in &recs { head.push_str(&format!("{:>9.0}", 100.0 * x)); }
    println!("{}", head);
    for p in [0.05_f64, 0.10, 0.15] {
        let mut line = format!("{:<22}", format!("chart, EL at PD {}%", (100.0 * p).round() as i64));
        for x in &recs { line.push_str(&format!("{:>9.2}", el(p, 1.0 - x, ead))); }
        println!("{}", line);
    }

    assert!((el1 - el2).abs() < 1e-9, "product vs list of outcomes");
    assert!((el3 - el1).abs() < 4.0 * se, "simulation within four standard errors");
    assert!((y_root - y_closed).abs() < 1e-10, "root finder vs closed-form fair rate");
    assert!((pd_root - 0.15).abs() < 1e-10, "back-solved PD vs the card's 15%");
    assert!((lgd_root - lgd_back).abs() < 1e-10 && (ead_root - ead_back).abs() < 1e-6, "LGD, EAD back-solves");
    assert!((el_true - el1).abs() < 1e-9 && (rec_dflt - rec).abs() < 1e-12, "two kinds of year give the cafe's EL");
    assert!(el_true - el_naive > 40.0, "year-averaged recovery must understate the loss");
    println!("ALL CHECKS PASS");
}
