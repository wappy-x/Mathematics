// Two default probabilities -- the same check as the Python, in Rust.  Standard library only, no crates.
// Q (market): Northwind's CDS curve, bootstrapped two ways, then re-priced by simulation.
// P (history): the rating table's Solid row, by matrix power and by first-step recursion.
const RATE: f64 = 0.05;
const REC: f64 = 0.40;
const NOTIONAL: f64 = 10_000_000.0;
const KNOTS: [f64; 4] = [0.0, 1.0, 3.0, 5.0];
const QUOTES: [f64; 3] = [0.0120, 0.0200, 0.0250];
const TABLE: [[f64; 3]; 3] = [[0.90, 0.09, 0.01], [0.10, 0.80, 0.10], [0.00, 0.00, 1.00]];

fn cum_hazard(t: f64, lams: &[f64], knots: &[f64]) -> f64 {
    let mut h = 0.0;
    for (i, lam) in lams.iter().enumerate() {
        let (a, b) = (knots[i], if i < lams.len() - 1 { knots[i + 1] } else { 1e9 });
        if t > a { h += lam * (t.min(b) - a); }
    }
    h
}
fn survival(t: f64, lams: &[f64], knots: &[f64]) -> f64 { (-cum_hazard(t, lams, knots)).exp() }
fn annuity(t: f64, lams: &[f64], knots: &[f64]) -> f64 {
    (1..=(4.0 * t).round() as usize).map(|j| 0.25 * (-RATE * 0.25 * j as f64).exp() * survival(0.25 * j as f64, lams, knots)).sum()
}
fn prot_exact(t: f64, lams: &[f64], knots: &[f64], rec: f64) -> f64 {
    let mut v = 0.0;
    for (i, &lam) in lams.iter().enumerate() {
        let (a, b) = (knots[i], knots[i + 1].min(t));
        if b <= a { break; }
        v += (1.0 - rec) * lam / (lam + RATE) * (-RATE * a).exp() * survival(a, lams, knots) * (1.0 - (-(lam + RATE) * (b - a)).exp());
    }
    v
}
fn prot_simpson(t: f64, lams: &[f64], knots: &[f64], rec: f64) -> f64 {
    let n = 200;
    let mut v = 0.0;
    for (i, &lam) in lams.iter().enumerate() {
        let (a, b) = (knots[i], knots[i + 1].min(t));
        if b <= a { break; }
        let h = (b - a) / n as f64;
        let f = |x: f64| lam * survival(x, lams, knots) * (-RATE * x).exp();
        let mut s = f(a) + f(b);
        for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h); }
        v += (1.0 - rec) * s * h / 3.0;
    }
    v
}
fn bisect<F: Fn(f64) -> f64>(f: F) -> f64 {
    let (mut lo, mut hi) = (1e-9, 2.0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(mid) > 0.0 { hi = mid; } else { lo = mid; }
    }
    0.5 * (lo + hi)
}
fn secant<F: Fn(f64) -> f64>(f: F) -> f64 {
    let (mut x0, mut x1) = (0.01, 0.05);
    for _ in 0..60 {
        let (f0, f1) = (f(x0), f(x1));
        if f1 == f0 { break; }
        let x2 = x1 - f1 * (x1 - x0) / (f1 - f0);
        x0 = x1; x1 = x2;
    }
    x1
}
type Prot = fn(f64, &[f64], &[f64], f64) -> f64;
fn bootstrap(prot: Prot, use_bisect: bool, rec: f64) -> Vec<f64> {
    let mut lams: Vec<f64> = Vec::new();
    for (k, &s) in QUOTES.iter().enumerate() {
        let t = KNOTS[k + 1];
        let base = lams.clone();
        let f = |x: f64| { let mut l = base.clone(); l.push(x); prot(t, &l, &KNOTS, rec) - s * annuity(t, &l, &KNOTS) };
        lams.push(if use_bisect { bisect(f) } else { secant(f) });
    }
    lams
}
fn default_time(mut e: f64, lams: &[f64]) -> f64 {
    for (i, &lam) in lams.iter().enumerate() {
        let (a, b) = (KNOTS[i], if i < lams.len() - 1 { KNOTS[i + 1] } else { 1e9 });
        if e <= lam * (b - a) { return a + e / lam; }
        e -= lam * (b - a);
    }
    f64::INFINITY
}

fn main() {
    let lam1 = bootstrap(prot_exact, true, REC);     // road 1: closed-form legs, bisection
    let lam2 = bootstrap(prot_simpson, false, REC);  // road 2: Simpson legs, secant
    let sq: Vec<f64> = (0..6).map(|t| survival(t as f64, &lam1, &KNOTS)).collect();

    // road 3: 200,000 simulated default times, 5-year legs priced path by path
    let mut state: u64 = 20260928;
    let mut disc = vec![0.0_f64];
    for j in 1..=20 { let last = disc[j - 1]; disc.push(last + 0.25 * (-RATE * 0.25 * j as f64).exp()); }
    let (paths, mut dead, mut ann_sum, mut prot_sum) = (200_000usize, 0usize, 0.0_f64, 0.0_f64);
    for _ in 0..paths {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        let u = ((state >> 11) as f64 + 0.5) / 9007199254740992.0;
        let tau = default_time(-u.ln(), &lam1);
        ann_sum += disc[20.min((4.0 * tau) as usize)];
        if tau <= 5.0 { dead += 1; prot_sum += (1.0 - REC) * (-RATE * tau).exp(); }
    }
    let (pd_mc, spread_mc) = (dead as f64 / paths as f64, prot_sum / ann_sum);

    // history: Solid row to the fifth power (road 1), first-step recursion (road 2)
    let mut row = [1.0_f64, 0.0, 0.0];
    let mut sp = vec![1.0_f64];
    for _ in 0..5 {
        let mut nx = [0.0_f64; 3];
        for j in 0..3 { nx[j] = (0..3).map(|i| row[i] * TABLE[i][j]).sum(); }
        row = nx; sp.push(1.0 - row[2]);
    }
    let (mut pd_s, mut pd_h) = (0.0_f64, 0.0_f64);
    for _ in 0..5 {
        let ns = TABLE[0][2] + TABLE[0][0] * pd_s + TABLE[0][1] * pd_h;
        let nh = TABLE[1][2] + TABLE[1][0] * pd_s + TABLE[1][1] * pd_h;
        pd_s = ns; pd_h = nh;
    }
    let (pd_q, pd_p) = (1.0 - sq[5], 1.0 - sp[5]);
    let (h_q, h_p) = (-sq[5].ln() / 5.0, -sp[5].ln() / 5.0);
    let flat_q = bisect(|h| (1.0 - (-5.0 * h).exp()) - pd_q);
    let flat_p = bisect(|h| (1.0 - (-5.0 * h).exp()) - pd_p);
    let knots_p = [0.0, 1.0, 2.0, 3.0, 4.0, 5.0];
    let lam_p: Vec<f64> = (0..5).map(|k| (sp[k] / sp[k + 1]).ln()).collect();
    let spread_p = prot_exact(5.0, &lam_p, &knots_p, REC) / annuity(5.0, &lam_p, &knots_p);
    let spread_q = prot_simpson(5.0, &lam1, &KNOTS, REC) / annuity(5.0, &lam1, &KNOTS);
    let odds = (pd_q / (1.0 - pd_q)) / (pd_p / (1.0 - pd_p));
    let mark_p = (spread_p - QUOTES[2]) * annuity(5.0, &lam_p, &knots_p) * NOTIONAL;
    let tri_pd = 1.0 - (-5.0 * QUOTES[2] / (1.0 - REC)).exp();
    let pd_at = |rec: f64| 1.0 - survival(5.0, &bootstrap(prot_exact, true, rec), &KNOTS);
    let (pd_r20, pd_r60) = (pd_at(0.20), pd_at(0.60));
    let h_h = -(1.0 - pd_h).ln() / 5.0;

    let cum = vec![-sq[5].ln(), -sp[5].ln()];
    let lists: [(&str, &Vec<f64>); 3] = [("lambda 1y, 3y, 5y  road 1 (exact, bisect)", &lam1), ("lambda 1y, 3y, 5y  road 2 (Simpson, secant)", &lam2),
        ("cumulative hazard H_Q(5), H_P(5)", &cum)];
    for (name, v) in lists.iter() {
        println!("{:<44}{}", name, v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join("  "));
    }
    let rows: Vec<(&str, f64)> = vec![
        ("Q survival S_Q(5)", sq[5]), ("Q default by 5y", pd_q), ("  road 3 simulated, 200,000 paths", pd_mc),
        ("  road 3 simulated 5y par spread", spread_mc), ("  5y par spread re-priced, Simpson", spread_q),
        ("P survival S_P(5)", sp[5]), ("P default by 5y  matrix power", pd_p), ("  first-step recursion", pd_s),
        ("Q average hazard -ln S_Q(5)/5", h_q), ("  flat hazard by bisection", flat_q),
        ("P average hazard -ln S_P(5)/5", h_p), ("  flat hazard by bisection", flat_p),
        ("hazard ratio hQ/hP", h_q / h_p), ("  ln S_Q(5) / ln S_P(5)", sq[5].ln() / sp[5].ln()),
        ("gap in default chance (points)", pd_q - pd_p), ("cumulative ratio pdQ/pdP (not rho)", pd_q / pd_p),
        ("actuarial 5y spread from P curve", spread_p), ("risk premium 250 bp - actuarial", QUOTES[2] - spread_p),
        ("triangle premium (1-R)(hQ - hP)", (1.0 - REC) * (h_q - h_p)), ("pricing odds ratio, default vs survive", odds),
        ("expected loss on $10m, P", NOTIONAL * (1.0 - REC) * pd_p), ("expected loss on $10m, Q", NOTIONAL * (1.0 - REC) * pd_q),
        ("wrong: mark 250 bp protection with P", mark_p), ("wrong: triangle 250/0.6 flat, default 5y", tri_pd),
        ("try: recovery 20%, Q default 5y", pd_r20), ("  hazard ratio", -(1.0 - pd_r20).ln() / 5.0 / h_p),
        ("try: recovery 60%, Q default 5y", pd_r60), ("  hazard ratio", -(1.0 - pd_r60).ln() / 5.0 / h_p),
        ("try: Shaky start, P default 5y", pd_h), ("  hazard ratio hQ/hP(Shaky)", h_q / h_h),
    ];
    for (name, v) in &rows { println!("{:<44}{:.6}", name, v); }
    println!("year  Q default %  P default %  Q hazard %  P hazard %  ratio");
    for t in 1..6 {
        let hq = cum_hazard(t as f64, &lam1, &KNOTS) - cum_hazard((t - 1) as f64, &lam1, &KNOTS);
        println!("{:>4}  {:>11.2}  {:>11.2}  {:>10.2}  {:>10.2}  {:>5.2}", t, 100.0 * (1.0 - sq[t]), 100.0 * (1.0 - sp[t]), 100.0 * hq, 100.0 * lam_p[t - 1], hq / lam_p[t - 1]);
    }

    assert!(lam1.iter().zip(&lam2).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) < 1e-9, "two bootstraps, two integrators, two root finders");
    assert!((pd_mc - pd_q).abs() < 0.003 && (spread_mc - QUOTES[2]).abs() < 0.0008, "simulation re-prices the 5y quote");
    assert!((pd_p - pd_s).abs() < 1e-12, "matrix power vs first-step recursion");
    assert!((pd_p - 0.10805311).abs() < 1e-12, "rating card's exact five-year Solid default chance");
    assert!((h_q / h_p - flat_q / flat_p).abs() < 1e-9, "hazard ratio by logs vs by bisection");
    assert!((spread_q - QUOTES[2]).abs() < 1e-9, "curve built with exact legs re-prices 250 bp with Simpson legs");
    assert!((0..6).map(|t| (survival(t as f64, &lam_p, &knots_p) - sp[t]).abs()).fold(0.0, f64::max) < 1e-12, "yearly P hazards rebuild the table's survivals");
    assert!((prot_simpson(5.0, &lam_p, &knots_p, REC) / annuity(5.0, &lam_p, &knots_p) - spread_p).abs() < 1e-9, "actuarial spread, exact vs Simpson legs");
    println!("ALL CHECKS PASS");
}
