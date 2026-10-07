// The Basel credit formula (IRB risk weight from one-factor Vasicek) -- the same check in Rust.
// Std only, no crates. Rust has no erf, so N(x) is a power series in the middle and a continued
// fraction in the tails; its inverse is bisection; the random numbers are hand-written.
use std::f64::consts::PI;

fn erf_series(t: f64) -> f64 {
    let (mut term, mut sum, mut n) = (t, t, 0.0);
    while term.abs() > 1e-17 * sum.abs().max(1e-300) {
        n += 1.0;
        term *= -t * t / n;
        sum += term / (2.0 * n + 1.0);
    }
    2.0 / PI.sqrt() * sum
}
fn erfc_cf(t: f64) -> f64 {                                   // t > 2.5
    let mut k = t;
    for i in (1..=80).rev() { k = t + (i as f64 / 2.0) / k; }
    (-t * t).exp() / (PI.sqrt() * k)
}
fn n_cdf(x: f64) -> f64 {
    let t = x / 2f64.sqrt();
    if t.abs() < 2.5 { 0.5 * (1.0 + erf_series(t)) }
    else if t > 0.0 { 1.0 - 0.5 * erfc_cf(t) } else { 0.5 * erfc_cf(-t) }
}
fn ninv(u: f64) -> f64 {
    let (mut lo, mut hi) = (-40.0_f64, 40.0_f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if n_cdf(mid) < u { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn q_stress(pd: f64, r: f64, z: f64) -> f64 { n_cdf((ninv(pd) + r.sqrt() * z) / (1.0 - r).sqrt()) }
fn b_slope(pd: f64) -> f64 { (0.11852 - 0.05478 * pd.ln()).powi(2) }
fn mat_adj(pd: f64, m: f64) -> f64 { (1.0 + (m - 2.5) * b_slope(pd)) / (1.0 - 1.5 * b_slope(pd)) }
fn k_cap(pd: f64, lgd: f64, r: f64, m: Option<f64>, z: f64) -> f64 {
    let k = lgd * (q_stress(pd, r, z) - pd);
    match m { Some(mm) => k * mat_adj(pd, mm), None => k }
}
fn r_corp(pd: f64) -> f64 {
    let w = (1.0 - (-50.0 * pd).exp()) / (1.0 - (-50.0_f64).exp());
    0.12 * w + 0.24 * (1.0 - w)
}
fn r_other(pd: f64) -> f64 {
    let w = (1.0 - (-35.0 * pd).exp()) / (1.0 - (-35.0_f64).exp());
    0.03 * w + 0.16 * (1.0 - w)
}
fn r_sme(pd: f64, sales: f64) -> f64 { r_corp(pd) - 0.04 * (1.0 - (sales.max(5.0).min(50.0) - 5.0) / 45.0) }

fn main() {
    let z999 = ninv(0.999);
    let rw = |pd: f64, lgd: f64, r: f64, m: Option<f64>, z: f64| 100.0 * 12.5 * k_cap(pd, lgd, r, m, z);
    let (pd, lgd, ead, r_mort) = (0.02_f64, 0.40_f64, 200000.0_f64, 0.15_f64);
    let c = ninv(pd);
    let q = q_stress(pd, r_mort, z999);
    let k = k_cap(pd, lgd, r_mort, None, z999);
    let w = rw(pd, lgd, r_mort, None, z999);
    let mut rows: Vec<(String, f64, usize)> = Vec::new();
    let mut add = |n: &str, v: f64, d: usize| rows.push((n.to_string(), v, d));
    add("threshold N^-1(PD)", c, 6); add("bad economy N^-1(0.999)", z999, 6);
    add("shared weight sqrt(R)", r_mort.sqrt(), 6); add("private weight sqrt(1-R)", (1.0 - r_mort).sqrt(), 6);
    add("stress argument", (c + r_mort.sqrt() * z999) / (1.0 - r_mort).sqrt(), 6);
    add("bad-year default rate q", q, 6); add("expected loss rate PD*LGD", pd * lgd, 6);
    add("bad-year loss rate LGD*q", lgd * q, 6); add("K, capital per dollar", k, 6);
    add("1 risk weight by formula %", w, 4); add("RWA on the $200,000 loan", ead * w / 100.0, 2);
    add("capital at 8% $", 0.08 * ead * w / 100.0, 2); add("expected loss $", ead * pd * lgd, 2);
    add("loss if the family defaults $", ead * lgd, 2);

    // ---- road 2: the Basel Committee's published illustrative risk weights, CRE99 Table 1, PD 2% ----
    let table = [("mortgage, LGD 25%", 48.85, rw(pd, 0.25, r_mort, None, z999)),
        ("mortgage, LGD 45%", 87.94, rw(pd, 0.45, r_mort, None, z999)),
        ("corporate, LGD 40%, M 2.5", 102.09, rw(pd, 0.40, r_corp(pd), Some(2.5), z999)),
        ("SME sales 5m, LGD 40%, M 2.5", 78.71, rw(pd, 0.40, r_sme(pd, 5.0), Some(2.5), z999)),
        ("other retail, LGD 45%", 57.99, rw(pd, 0.45, r_other(pd), None, z999)),
        ("QRRE, LGD 85%", 54.63, rw(pd, 0.85, 0.04, None, z999))];
    let interp = 0.25 * 48.85 + 0.75 * 87.94;
    add("2 risk weight from the table %", interp, 4);

    // ---- road 3: simulate the economy for the house bank's $1bn book, loss by loss ----
    let (mort, corp) = (600e6_f64, 400e6_f64);
    let r_c = r_corp(pd);
    let mut state: u64 = 0x2545F4914F6CDD1D;
    let mut unif = || {
        state ^= state >> 12; state ^= state << 25; state ^= state >> 27;
        (state.wrapping_mul(0x2545F4914F6CDD1D) >> 11) as f64 / 9007199254740992.0 + 1e-17
    };
    let draws: usize = 2000000;
    let (mut mort_rate, mut book) = (Vec::with_capacity(draws), Vec::with_capacity(draws));
    for _ in 0..draws {
        let (u1, u2) = (unif(), unif());
        let m = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let qm = n_cdf((c - r_mort.sqrt() * m) / (1.0 - r_mort).sqrt());
        let qc = n_cdf((c - r_c.sqrt() * m) / (1.0 - r_c).sqrt());
        mort_rate.push(qm);
        book.push(lgd * (mort * qm + corp * qc));
    }
    mort_rate.sort_by(|a, b| a.partial_cmp(b).unwrap());
    book.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let idx = (0.999 * draws as f64) as usize;
    let sim_rw = 100.0 * 12.5 * lgd * (mort_rate[idx] - pd);
    let sim_cap = book[idx] - lgd * pd * (mort + corp);
    let loan_cap = mort * k + corp * k_cap(pd, lgd, r_c, None, z999);
    add("3 simulated risk weight %", sim_rw, 4);
    add("$1bn book: mortgages alone, capital", mort * k, 2); add("$1bn book: capital, loan by loan", loan_cap, 2);
    add("$1bn book: capital, simulated", sim_cap, 2); add("  simulated / loan by loan - 1", sim_cap / loan_cap - 1.0, 6);
    add("$1bn book: RWA, loan by loan", 12.5 * loan_cap, 2);

    // ---- the prescribed inputs, one at a time ----
    add("maturity slope b(2%)", b_slope(pd), 6);
    add("maturity adj M = 2.5", mat_adj(pd, 2.5), 6); add("maturity adj M = 5", mat_adj(pd, 5.0), 6);
    add("corporate weight w at 2%", (1.0 - (-50.0 * pd).exp()) / (1.0 - (-50.0_f64).exp()), 6);
    add("corporate correlation at 2%", r_c, 6); add("bars: QRRE, R 4%", rw(pd, lgd, 0.04, None, z999), 2);
    add("bars: other retail", rw(pd, lgd, r_other(pd), None, z999), 2);
    add("bars: SME, M 2.5", rw(pd, lgd, r_sme(pd, 5.0), Some(2.5), z999), 2);
    add("bars: mortgage, R 15%", w, 2); add("bars: corporate, M 1", rw(pd, lgd, r_c, Some(1.0), z999), 2);
    add("bars: corporate, M 2.5", rw(pd, lgd, r_c, Some(2.5), z999), 2);
    add("bars: large bank, M 2.5", rw(pd, lgd, 1.25 * r_c, Some(2.5), z999), 2);
    for (lab, a) in [("99", 0.99), ("99.5", 0.995), ("99.9", 0.999), ("99.97", 0.9997)] {
        add(&format!("conf {}%: risk weight", lab), rw(pd, lgd, r_mort, None, ninv(a)), 2);
    }
    add("wrong: expected loss left in %", 100.0 * 12.5 * lgd * q, 2);
    add("wrong: M 2.5 adjustment on a mortgage %", rw(pd, lgd, r_mort, Some(2.5), z999), 2);
    add("wrong: N^-1(0.001), capital $", ead * k_cap(pd, lgd, r_mort, None, -z999), 2);
    add("try: LGD 20% %", rw(pd, 0.20, r_mort, None, z999), 2); add("try: PD 0.5% %", rw(0.005, lgd, r_mort, None, z999), 2);
    add("try: PD 10% %", rw(0.10, lgd, r_mort, None, z999), 2); add("try: R 25% %", rw(pd, lgd, 0.25, None, z999), 2);
    for (name, v, d) in &rows { println!("{:<40} {:>16.*}", name, *d, v); }
    println!("CRE99 Table 1, PD 2%                    published    formula");
    for (name, publ, mine) in &table { println!("  {:<36} {:>9.2} {:>10.4}", name, publ, mine); }
    let pds = [0.001, 0.0025, 0.005, 0.01, 0.02, 0.03, 0.05, 0.10, 0.20];
    let line = |f: &dyn Fn(f64) -> f64| pds.iter().map(|&p| format!("{:6.2}", f(p))).collect::<Vec<_>>().join(" ");
    println!("chart, PD %        {}", line(&|p| 100.0 * p));
    println!("chart, mortgage    {}", line(&|p| rw(p, lgd, r_mort, None, z999)));
    println!("chart, corporate   {}", line(&|p| rw(p, lgd, r_corp(p), Some(2.5), z999)));

    for (name, publ, mine) in &table {
        assert!((mine - publ).abs() < 0.006, "formula must reproduce the published weight: {}", name);
    }
    assert!((interp - w).abs() < 0.01, "table road vs formula road");
    assert!((sim_rw - w).abs() < 1.5, "simulated 99.9% mortgage weight within noise of the formula");
    assert!((sim_cap / loan_cap - 1.0).abs() < 0.02, "book capital from the simulated loss equals the loan-by-loan sum");
    println!("ALL CHECKS PASS");
}
