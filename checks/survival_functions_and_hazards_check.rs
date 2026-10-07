// Survival functions and hazards -- the same check as the Python, in Rust.  No crates.
// Patients followed from diagnosis.  Model: a hazard of 0.30, 0.20, 0.15, 0.10, 0.10
// deaths per patient-year in years 1 to 5 (0.10 after).  Roads: S = exp(-H); a product
// of survived slices that never calls exp; ten censored records fitted by the formula
// D/E and by a search over the log-likelihood; and 2,000 simulated patients, each
// living slice by slice, observed through entry, dropout and the study's close.
const RATES: [f64; 5] = [0.30, 0.20, 0.15, 0.10, 0.10];
const W: f64 = 0.01;

fn h(t: f64) -> f64 { RATES[(t as usize).min(4)] }          // hazard at age t, in years

fn big_h(t: f64, rates: &[f64]) -> f64 {                     // cumulative hazard: the area under h
    let mut s = 0.10 * (t - 5.0).max(0.0);
    for (j, r) in rates.iter().enumerate() { s += r * (t - j as f64).max(0.0).min(1.0); }
    s
}

fn slices(t: f64, d: f64) -> f64 {                           // survive each slice of d years in turn
    let mut s = 1.0;
    for i in 0..(t / d).round() as usize { s *= 1.0 - h((i as f64 + 0.5) * d) * d; }
    s
}

struct SplitMix64 { s: u64 }                                 // the same random numbers in both languages
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                           // strictly between 0 and 1
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
}

fn yearly_rates(recs: &[(f64, u32)]) -> Vec<(u32, f64)> {   // deaths / person-years inside each year
    (0..5).map(|j| {
        let jf = j as f64;
        let d = recs.iter().filter(|&&(y, e)| e == 1 && jf < y && y <= jf + 1.0).count() as u32;
        let ex: f64 = recs.iter().map(|&(y, _)| (y - jf).max(0.0).min(1.0)).sum();
        (d, ex)
    }).collect()
}

fn s_hat(fit: &[(u32, f64)], t: f64) -> f64 {                // survival from the fitted yearly rates
    let r: Vec<f64> = fit.iter().map(|&(d, ex)| d as f64 / ex).collect();
    (-big_h(t.min(5.0), &r)).exp()
}

fn se_s5(fit: &[(u32, f64)]) -> f64 {                        // standard error of S(5), by the delta method
    s_hat(fit, 5.0) * fit.iter().map(|&(d, ex)| d as f64 / (ex * ex)).sum::<f64>().sqrt()
}

fn row(label: &str, f: impl Fn(f64) -> f64) {
    let v: Vec<String> = (0..11).map(|i| format!("{:.2}", f(0.5 * i as f64))).collect();
    println!("{}{}", label, v.join(" "));
}

fn main() {
    let s_of = |t: f64| (-big_h(t, &RATES)).exp();
    println!("year  hazard  H(t)    S(t)=exp(-H)  slices of 0.0001  one-year death chance q");
    for j in 1..6 {
        let jf = j as f64;
        println!("{:>4}  {:.2}   {:.4}  {:.6}      {:.6}          {:.4}", j, RATES[j - 1], big_h(jf, &RATES),
                 s_of(jf), slices(jf, 0.0001), 1.0 - (-RATES[j - 1]).exp());
    }
    let s5 = s_of(5.0);
    println!("hazard limit at t = 1.5: P(die within 0.001 | alive) / 0.001 = {:.6}", (1.0 - s_of(1.501) / s_of(1.5)) / 0.001);
    println!("alive at 2, reaches 5: S(5)/S(2) = {:.6}; fresh patient S(5) = {:.6}", s5 / s_of(2.0), s5);
    let flat = [0.17f64; 5];                                     // a constant hazard with the same H(5)
    let sf = |t: f64| (-big_h(t, &flat)).exp();
    println!("constant 0.17: S(5) = {:.6}; alive at 2, reaches 5 = {:.6}", sf(5.0), sf(5.0) / sf(2.0));
    println!("jump: 5% die on the day of surgery: 1 - 0.05 = {:.4}, exp(-0.05) = {:.4}", 1.0 - 0.05, (-0.05f64).exp());
    let ts: Vec<String> = (0..11).map(|i| format!("{:.1}", 0.5 * i as f64)).collect();
    println!("chart, t in years {}", ts.join(" "));
    row("chart, true S(t)   ", s_of);

    // ---- ten patients, a constant hazard fitted to their records ----
    let ten: [(f64, u32); 10] = [(0.4, 1), (1.0, 0), (1.3, 1), (2.1, 1), (2.5, 0), (3.0, 0), (3.6, 1), (4.2, 0), (5.0, 0), (5.0, 0)];
    let d = ten.iter().map(|r| r.1).sum::<u32>() as f64;
    let e: f64 = ten.iter().map(|r| r.0).sum();
    let lam = d / e;
    let loglik = |l: f64| ten.iter().map(|&(y, ev)| ev as f64 * l.ln() - l * y).sum::<f64>();
    let (mut lo, mut hi) = (0.001f64, 2.0f64);                  // golden-section search for the peak
    for _ in 0..200 {
        let (a, b) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo));
        if loglik(a) > loglik(b) { hi = b } else { lo = a }
    }
    let lam_search = (lo + hi) / 2.0;
    println!("ten patients: deaths D = {}, person-years E = {:.2}", d, e);
    println!("  rate D/E = {:.6} per year, se {:.6}; by log-likelihood search {:.6}", lam, lam / d.sqrt(), lam_search);
    let s5_ten = (-5.0 * lam).exp();
    println!("  S(5) = exp(-5 D/E) = {:.4} (se {:.4}); death by 5 = {:.4}", s5_ten, s5_ten * 5.0 * lam / d.sqrt(), 1.0 - s5_ten);
    let known: Vec<u32> = ten.iter().filter(|r| r.1 == 1 || r.0 >= 5.0).map(|r| r.1).collect();
    let alive_known = known.iter().filter(|&&x| x == 0).count() as f64 / known.len() as f64;
    println!("wrong: fraction not seen to die          {:.4}", 1.0 - d / 10.0);
    println!("wrong: drop those censored before 5      {:.4}", alive_known);
    println!("wrong: censored counted as deaths        {:.4} (rate {:.4})", (-5.0 * 10.0 / e).exp(), 10.0 / e);
    println!("wrong: hazard x 5 years read as a chance {:.4}", 5.0 * lam);

    // ---- 2,000 simulated patients: entry over 3 years, study closes at year 6, dropouts ----
    let mut g = SplitMix64 { s: 2026 };
    let (mut recs, mut lives): (Vec<(f64, u32)>, Vec<f64>) = (Vec::new(), Vec::new());
    for _ in 0..2000 {
        let close = 6.0 - 3.0 * g.uniform();                     // follow-up until the study closes
        let c = close.min(-g.uniform().ln() / 0.08);              // dropout at 0.08 per year, whichever first
        let mut t = 99.0;                                        // alive past year 6
        for i in 0..600 {                                        // live slice by slice: die with chance h * W
            if g.uniform() < h((i as f64 + 0.5) * W) * W { t = (i + 1) as f64 * W; break; }
        }
        lives.push(t);
        recs.push((t.min(c), if t <= c { 1 } else { 0 }));
    }
    let fit = yearly_rates(&recs);
    let truth = slices(5.0, W);                                  // the simulated patients' exact S(5)
    let seen = recs.iter().map(|r| r.1).sum::<u32>();
    println!("simulation, 2000 patients, seed 2026: {} deaths seen, {} censored", seen, 2000 - seen);
    for (j, &(dj, ex)) in fit.iter().enumerate() {
        println!("  year {}: deaths {:>3}, person-years {:8.2}, rate {:.4} (se {:.4}), true {:.2}",
                 j + 1, dj, ex, dj as f64 / ex, (dj as f64).sqrt() / ex, RATES[j]);
    }
    let alive = lives.iter().filter(|&&t| t > 5.0).count() as f64 / 2000.0;
    println!("  S(5) from censored records {:.4} (se {:.4}); truth {:.4}", s_hat(&fit, 5.0), se_s5(&fit), truth);
    println!("  every lifetime known: fraction alive at 5 = {:.4} (se {:.4})", alive, (alive * (1.0 - alive) / 2000.0).sqrt());

    // ---- informative dropout: half the patients about to die leave half a year before ----
    let mut inf: Vec<(f64, u32)> = Vec::new();
    for (&(y, ev), &t) in recs.iter().zip(lives.iter()) {
        let leave = g.uniform() < 0.5;
        inf.push(if ev == 1 && t > 0.5 && leave { (t - 0.5, 0) } else { (y, ev) });
    }
    let fit_inf = yearly_rates(&inf);
    println!("  informative dropout: S(5) estimate {:.4} (se {:.4}); truth {:.4}", s_hat(&fit_inf, 5.0), se_s5(&fit_inf), truth);
    row("chart, estimate    ", |t| s_hat(&fit, t));
    row("chart, informative ", |t| s_hat(&fit_inf, t));

    assert!((slices(5.0, 0.0001) - s5).abs() < 1e-4);                     // slice product vs exp(-H)
    assert!((lam_search - lam).abs() < 1e-6);                              // search vs the formula D/E
    assert!(((1.0 - s_of(1.501) / s_of(1.5)) / 0.001 - RATES[1]).abs() < 1e-3);  // slice chance / slice vs h
    assert!((yearly_rates(&ten).iter().map(|r| r.1).sum::<f64>() - e).abs() < 1e-9);  // exposure year by year vs in one sum
    assert!((s_hat(&fit, 5.0) - truth).abs() < 4.0 * se_s5(&fit));        // censored records vs truth
    assert!((alive - truth).abs() < 4.0 * (truth * (1.0 - truth) / 2000.0).sqrt());
    assert!(s_hat(&fit_inf, 5.0) - truth > 4.0 * se_s5(&fit_inf));        // informative dropout is biased
    println!("ALL CHECKS PASS");
}
