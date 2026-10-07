// Reserving check in Rust: chain ladder, Bornhuetter-Ferguson and Mack's standard error.
// Standard library only, no crates.  Amounts in thousands of dollars.
// Compile: rustc --edition 2021 -O reserving_chain_ladder_and_bornhuetter_ferguson_check.rs
type Tri = Vec<Vec<f64>>;
fn tri(rows: &[&[f64]]) -> Tri { rows.iter().map(|r| r.to_vec()).collect() }
// Age-to-age factors: "volume" (the chain ladder), "simple" and "zeros" (two mistakes).
fn factors(t: &Tri, how: &str) -> Vec<f64> {
    (0..t.len() - 1).map(|k| {
        let rows: Vec<&Vec<f64>> = t.iter().filter(|r| r.len() > k + 1).collect();
        match how {
            "simple" => rows.iter().map(|r| r[k + 1] / r[k]).sum::<f64>() / rows.len() as f64,
            "zeros" => rows.iter().map(|r| r[k + 1]).sum::<f64>()
                / t.iter().filter(|r| r.len() > k).map(|r| r[k]).sum::<f64>(),
            _ => rows.iter().map(|r| r[k + 1]).sum::<f64>() / rows.iter().map(|r| r[k]).sum::<f64>(),
        }
    }).collect()
}
fn to_ult(f: &[f64], a: usize) -> f64 { f[a..].iter().product() }
fn sigmas(t: &Tri, f: &[f64]) -> Vec<f64> {
    let mut s2: Vec<f64> = (0..t.len() - 2).map(|k| {
        let rows: Vec<&Vec<f64>> = t.iter().filter(|r| r.len() > k + 1).collect();
        rows.iter().map(|r| r[k] * (r[k + 1] / r[k] - f[k]).powi(2)).sum::<f64>() / (rows.len() - 1) as f64
    }).collect();
    let (a, b) = (s2[s2.len() - 2], s2[s2.len() - 1]);
    s2.push((b * b / a).min(a).min(b));                   // Mack's rule for the last age
    s2
}
fn col_sums(t: &Tri) -> Vec<f64> { (0..t.len() - 1).map(|k| t.iter().filter(|r| r.len() > k + 1).map(|r| r[k]).sum()).collect() }
// Road 1: Mack's closed formula.  Returns ultimates, mse by year, process variance by year, cross term.
fn mack(t: &Tri, f: &[f64], s2: &[f64]) -> (Vec<f64>, Vec<f64>, Vec<f64>, f64) {
    let (n, s) = (t.len(), col_sums(t));
    let (mut u, mut mse, mut proc) = (vec![], vec![], vec![]);
    for r in t {
        let (mut c, mut pe, mut pa) = (*r.last().unwrap(), 0.0, 0.0);
        for k in r.len() - 1..n - 1 { pe += s2[k] / f[k].powi(2) / c; pa += s2[k] / f[k].powi(2) / s[k]; c *= f[k]; }
        u.push(c); mse.push(c * c * (pe + pa)); proc.push(c * c * pe);
    }
    let mut cross = 0.0;
    for i in 0..n { for j in i + 1..n {          // pairs of years share the factors from the older one's age on
        cross += 2.0 * u[i] * u[j] * (t[i].len() - 1..n - 1).map(|k| s2[k] / f[k].powi(2) / s[k]).sum::<f64>();
    } }
    (u, mse, proc, cross)
}
// Road 2: process variance carried forward a year at a time, factor error from summed sensitivities.
fn mack_recursive(t: &Tri, f: &[f64], s2: &[f64]) -> f64 {
    let (n, s) = (t.len(), col_sums(t));
    let (mut total, mut grad) = (0.0, vec![0.0; n - 1]);
    for r in t {
        let (mut c, mut v) = (*r.last().unwrap(), 0.0);
        for k in r.len() - 1..n - 1 { v = f[k] * f[k] * v + s2[k] * c; c *= f[k]; }
        total += v;
        for k in r.len() - 1..n - 1 { grad[k] += c / f[k]; }
    }
    total + (0..n - 1).map(|k| grad[k] * grad[k] * s2[k] / s[k]).sum::<f64>()
}
// Road 2 for CL and BF: fit row level x_i times column share y_k to the increments.
fn marginal_totals(t: &Tri, e: Option<&[f64]>) -> Vec<f64> {
    let n = t.len();
    let inc: Tri = t.iter().map(|r| (0..r.len()).map(|k| if k == 0 { r[0] } else { r[k] - r[k - 1] }).collect()).collect();
    let rs: Vec<f64> = inc.iter().map(|r| r.iter().sum()).collect();
    let cs: Vec<f64> = (0..n).map(|k| inc.iter().filter(|r| r.len() > k).map(|r| r[k]).sum()).collect();
    let (mut y, mut x) = (vec![1.0 / n as f64; n], vec![0.0; n]);
    for _ in 0..4000 {
        x = (0..n).map(|i| rs[i] / y[..inc[i].len()].iter().sum::<f64>()).collect();
        y = (0..n).map(|k| cs[k] / (0..n).filter(|&i| inc[i].len() > k).map(|i| x[i]).sum::<f64>()).collect();
    }
    let ys: f64 = y.iter().sum(); y = y.iter().map(|v| v / ys).collect();
    for i in 0..n { x[i] = rs[i] / y[..inc[i].len()].iter().sum::<f64>(); }
    let base = e.unwrap_or(&x);
    (0..n).map(|i| base[i] * y[inc[i].len()..].iter().sum::<f64>()).collect()
}
// Road 1 for CL and BF: the formulas.
fn cl_bf(t: &Tri, e: &[f64]) -> (Vec<f64>, Vec<f64>, Vec<f64>, Vec<f64>) {
    let f = factors(t, "volume");
    let big_f: Vec<f64> = t.iter().map(|r| to_ult(&f, r.len() - 1)).collect();
    let cl = t.iter().zip(&big_f).map(|(r, fi)| r.last().unwrap() * (fi - 1.0)).collect();
    let bf = e.iter().zip(&big_f).map(|(ei, fi)| ei * (1.0 - 1.0 / fi)).collect();
    (f, big_f, cl, bf)
}
fn total(v: &[f64]) -> f64 { v.iter().sum() }
fn main() {
    let t = tri(&[&[3616., 6170., 6846., 7304., 7832., 8130., 8305., 8382., 8437., 8464.],
        &[3533., 4868., 5650., 6167., 6581., 6875., 7053., 7133., 7174.], &[3476., 4613., 5100., 5596., 5869., 6038., 6189., 6259.],
        &[3772., 5320., 5880., 6386., 6644., 6858., 7040.], &[3975., 5516., 6749., 7584., 8097., 8441.],
        &[4171., 6842., 7869., 8959., 9658.], &[3918., 6369., 7638., 8379.], &[4308., 6531., 8018.], &[4438., 7358.], &[4486.]]);
    let ta = tri(&[&[357848., 1124788., 1735330., 2218270., 2745596., 3319994., 3466336., 3606286., 3833515., 3901463.],
        &[352118., 1236139., 2170033., 3353322., 3799067., 4120063., 4647867., 4914039., 5339085.],
        &[290507., 1292306., 2218525., 3235179., 3985995., 4132918., 4628910., 4909315.],
        &[310608., 1418858., 2195047., 3757447., 4029929., 4381982., 4588268.],
        &[443160., 1136350., 2128333., 2897821., 3402672., 3873311.], &[396132., 1333217., 2180715., 2985752., 3691712.],
        &[440832., 1288463., 2419861., 3483130.], &[359480., 1421128., 2864498.], &[376686., 1363294.], &[344014.]]);
    let prem: Vec<f64> = (0..10).map(|i| 11000.0 + 500.0 * i as f64).collect();
    let e: Vec<f64> = prem.iter().map(|p| 0.70 * p).collect();
    let (f, big_f, r_cl, r_bf) = cl_bf(&t, &e);
    let s2 = sigmas(&t, &f); let (u, mse, proc, cross) = mack(&t, &f, &s2);
    let (r_cl2, r_bf2) = (marginal_totals(&t, None), marginal_totals(&t, Some(&e)));
    let (mse_tot, mse_rec) = (total(&mse) + cross, mack_recursive(&t, &f, &s2));
    // Road 3: simulate the process part of Mack's model, factors held fixed.
    let mut seed: u64 = 20260928;
    let mut unif = || {
        seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((seed >> 11) as f64 + 0.5) / 9007199254740992.0
    };
    let (n_sim, mut s_sum, mut s_sq) = (40000, 0.0, 0.0);
    for _ in 0..n_sim {
        let mut tot = 0.0;
        for r in &t {
            let mut c = *r.last().unwrap();
            for k in r.len() - 1..9 {
                let a = (-2.0 * unif().ln()).sqrt();
                let z = a * (2.0 * std::f64::consts::PI * unif()).cos();
                c = f[k] * c + (s2[k] * c).sqrt() * z;
            }
            tot += c - r.last().unwrap();
        }
        s_sum += tot; s_sq += tot * tot;
    }
    let nf = n_sim as f64; let (sim_mean, sim_sd) = (s_sum / nf, ((s_sq - s_sum * s_sum / nf) / (nf - 1.0)).sqrt());
    println!("age   f_k      F to ult  % reported  sigma_k^2");
    for k in 0..10 {
        let fk = to_ult(&f, k);
        let sig = if k < 9 { format!("{:9.4}", s2[k]) } else { "        -".to_string() };
        println!("{:>3}  {:7.4}  {:8.4}  {:9.2}  {}", k + 1, if k < 9 { f[k] } else { 1.0 }, fk, 100.0 / fk, sig);
    }
    println!("year  latest   F      CL ult   CL IBNR   prior E   BF IBNR  Mack se");
    for (i, r) in t.iter().enumerate() {
        println!("{}  {:6}  {:6.4} {:8.1}  {:8.2}  {:7.1}  {:8.2}  {:6.1}", 2016 + i, *r.last().unwrap() as i64,
            big_f[i], u[i], r_cl[i], e[i], r_bf[i], mse[i].sqrt());
    }
    let sd_proc = total(&proc).sqrt();
    let wrong: Vec<f64> = ["simple", "zeros"].iter().map(|how| {
        let fw = factors(&t, how);
        t.iter().map(|r| r.last().unwrap() * (to_ult(&fw, r.len() - 1) - 1.0)).sum()
    }).collect();
    let mut shock = t.clone(); shock[9][0] = (1.2 * t[9][0]).round();  // a large claim lands in 2025
    let (_, _, rc_s, rb_s) = cl_bf(&shock, &e);
    let (_, _, _, r_bf60) = cl_bf(&t, &prem.iter().map(|p| 0.60 * p).collect::<Vec<f64>>());
    let bk_prior: Vec<f64> = t.iter().zip(&r_bf).map(|(r, b)| r.last().unwrap() + b).collect();
    let (_, _, _, r_bk) = cl_bf(&t, &bk_prior);          // Benktander: BF ultimate as the prior
    let ft = factors(&ta, "volume"); let (ut, mt, _, ct) = mack(&ta, &ft, &sigmas(&ta, &ft));
    let (ta_r, ta_se) = (ut.iter().zip(&ta).map(|(x, r)| x - r.last().unwrap()).sum::<f64>(), (total(&mt) + ct).sqrt());
    let rows: Vec<(&str, f64)> = vec![("f_1: age-2 total, 2016-2024", t[..9].iter().map(|r| r[1]).sum()),
        ("f_1: age-1 total, 2016-2024", t[..9].iter().map(|r| r[0]).sum()), ("CL IBNR, factors", total(&r_cl)), ("CL IBNR, marginal totals", total(&r_cl2)),
        ("BF IBNR, formula", total(&r_bf)), ("BF IBNR, marginal totals", total(&r_bf2)),
        ("Mack se total, closed form", mse_tot.sqrt()), ("Mack se total, recursion", mse_rec.sqrt()),
        ("  cross-year term in mse", cross), ("  process se, formula", sd_proc),
        ("  process se, 40000 sims", sim_sd), ("  mean reserve, 40000 sims", sim_mean),
        ("  se as % of CL IBNR", 100.0 * mse_tot.sqrt() / total(&r_cl)),
        ("wrong: simple-average factors", wrong[0]), ("wrong: empty cells as zeros", wrong[1]),
        ("wrong: BF with reported share", e.iter().zip(&big_f).map(|(a, b)| a / b).sum()),
        ("wrong: se, process only", sd_proc), ("wrong: se, no cross term", total(&mse).sqrt()),
        ("wrong: se, ten se's added", mse.iter().map(|m| m.sqrt()).sum()),
        ("try: 2025 reported 5383, CL IBNR", total(&rc_s)), ("try: 2025 reported 5383, BF IBNR", total(&rb_s)),
        ("try: ELR 0.60, BF IBNR", total(&r_bf60)), ("try: Benktander IBNR", total(&r_bk)),
        ("Taylor-Ashe CL reserve", ta_r), ("Taylor-Ashe Mack se", ta_se), ("Taylor-Ashe se, % of reserve", 100.0 * ta_se / ta_r)];
    for (name, v) in &rows { println!("{:<34} {:14.1}", name, v); }
    assert!((total(&r_cl) - total(&r_cl2)).abs() < 1e-3, "marginal totals must reproduce chain ladder");
    assert!((total(&r_bf) - total(&r_bf2)).abs() < 1e-3, "marginal-totals pattern must reproduce BF");
    assert!((mse_tot - mse_rec).abs() < 1e-6 * mse_tot, "recursion must reproduce Mack's closed form");
    assert!((sim_sd / sd_proc - 1.0).abs() < 0.02, "simulated process se within 2%");
    assert!((sim_mean / total(&r_cl) - 1.0).abs() < 0.002, "simulated mean reserve within 0.2%");
    let ta_k: Vec<i64> = (1..10).map(|i| ((ut[i] - ta[i].last().unwrap()) / 1000.0).round() as i64).collect();
    let ta_pct: Vec<i64> = (1..10).map(|i| (100.0 * mt[i].sqrt() / (ut[i] - ta[i].last().unwrap())).round() as i64).collect();
    assert_eq!(ta_k, vec![95, 470, 710, 985, 1419, 2178, 3920, 4279, 4626], "Mack (1993) Table 2, reserves in $000");
    assert_eq!(ta_pct, vec![80, 26, 19, 27, 29, 26, 22, 23, 29], "Mack (1993) Table 3, se as % of reserve");
    assert_eq!((100.0 * ta_se / ta_r).round(), 13.0, "Mack (1993) Table 3, overall 13%");
    assert!((total(&rb_s) - total(&r_bf)).abs() < 1e-9, "a 2025 surprise leaves BF where it was");
    println!("ALL CHECKS PASS");
}
