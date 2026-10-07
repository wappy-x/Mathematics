// Cointegration in outline -- the same check as the Python, in Rust.  No crates.
// Two petrol stations on one crossroads, a year of daily pump prices in dollars
// per gallon.  South follows the wholesale market; both stations answer a gap.
// Engle-Granger: fit the tie, test the leftover; then the error-correction model.
const DAYS: usize = 365;
const C: f64 = 0.06; const SHOCK: f64 = 10.0;
const A_N: f64 = -0.12; const A_S: f64 = 0.03;

struct Rng { s: u64 }                            // SplitMix64, then Box-Muller
impl Rng {
    fn bits(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn normal(&mut self) -> f64 {
        let u1 = ((self.bits() >> 11) as f64 + 0.5) / 2f64.powi(53);
        let u2 = (self.bits() >> 11) as f64 / 2f64.powi(53);
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

fn stations(rng: &mut Rng) -> (Vec<f64>, Vec<f64>) {   // the built world: beta = 1, c = 6 cents
    let (mut north, mut south) = (vec![3.40 + C], vec![3.40]);
    for _ in 0..DAYS - 1 {
        let (n, s) = (*north.last().unwrap(), *south.last().unwrap());
        let gap = n - C - s;
        let (eta, e_n, e_s) = (0.02 * rng.normal(), 0.015 * rng.normal(), 0.015 * rng.normal());
        north.push(n + A_N * gap + eta + e_n);
        south.push(s + A_S * gap + eta + e_s);
    }
    (north, south)
}

fn walk(rng: &mut Rng, sd: f64) -> Vec<f64> {   // a price with no home and no partner
    let mut x = vec![3.40];
    for _ in 0..DAYS - 1 { let last = *x.last().unwrap(); x.push(last + sd * rng.normal()); }
    x
}

fn diff(x: &[f64]) -> Vec<f64> { (1..x.len()).map(|t| x[t] - x[t - 1]).collect() }
fn mean(x: &[f64]) -> f64 { x.iter().sum::<f64>() / x.len() as f64 }

fn fit_line(y: &[f64], x: &[f64]) -> (f64, f64, Vec<f64>, f64) {   // y = c + b x, and R^2
    let (mx, my) = (mean(x), mean(y));
    let sxy: f64 = x.iter().zip(y).map(|(a, b)| (a - mx) * (b - my)).sum();
    let sxx: f64 = x.iter().map(|a| (a - mx).powi(2)).sum();
    let syy: f64 = y.iter().map(|b| (b - my).powi(2)).sum();
    let b = sxy / sxx;
    let z = x.iter().zip(y).map(|(u, v)| v - my - b * (u - mx)).collect();
    (my - b * mx, b, z, sxy * sxy / (sxx * syy))
}

fn slope0(y: &[f64], x: &[f64]) -> (f64, f64) { // y = r x, no constant: slope, standard error
    let sxx: f64 = x.iter().map(|a| a * a).sum();
    let r = x.iter().zip(y).map(|(a, b)| a * b).sum::<f64>() / sxx;
    let s2 = x.iter().zip(y).map(|(a, b)| (b - r * a).powi(2)).sum::<f64>() / (x.len() - 1) as f64;
    (r, (s2 / sxx).sqrt())
}

struct Eg { c: f64, b: f64, z: Vec<f64>, rho: f64, se: f64, tau: f64, r2: f64 }
fn eg(y: &[f64], x: &[f64]) -> Eg {              // Engle-Granger, both steps
    let (c, b, z, r2) = fit_line(y, x);
    let (rho, se) = slope0(&diff(&z), &z[..z.len() - 1]);
    Eg { c, b, z, rho, se, tau: rho / se, r2 }
}

fn search_ratio(y: &[f64], x: &[f64]) -> f64 {  // road two: shrink a bracket on the misfit
    let (my, mx) = (mean(y), mean(x));
    let miss = |b: f64| x.iter().zip(y).map(|(u, v)| ((v - my) - b * (u - mx)).powi(2)).sum::<f64>();
    let (mut lo, mut hi) = (0.0f64, 2.0f64);
    for _ in 0..100 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if miss(m1) < miss(m2) { hi = m2 } else { lo = m1 }
    }
    (lo + hi) / 2.0
}

fn mackinnon(b: [f64; 4], t: f64) -> f64 { b[0] + b[1] / t + b[2] / (t * t) + b[3] / (t * t * t) }   // MacKinnon (2010)
fn f2(xs: &[f64], days: &[usize]) -> String {
    days.iter().map(|&d| format!("{:.2}", xs[d])).collect::<Vec<_>>().join(" ")
}

fn main() {
    let (north, south) = stations(&mut Rng { s: 2025 });
    let y = eg(&north, &south);
    let beta_search = search_ratio(&north, &south);
    let t = (DAYS - 1) as f64;
    let cut2 = mackinnon([-3.33613, -6.1101, -6.823, 0.0], t);   // two prices, ratio fitted
    let cut1 = mackinnon([-2.86154, -2.8903, -4.234, -40.040], t);    // one series, nothing fitted
    let lag = &y.z[..DAYS - 1];
    let (a_n, se_n) = slope0(&diff(&north), lag);
    let (a_s, se_s) = slope0(&diff(&south), lag);
    let o = eg(&north, &walk(&mut Rng { s: 52 }, 0.025));   // one unrelated price, picked to show the trap
    let days: Vec<usize> = (0..DAYS).step_by(14).collect();
    println!("year of {} days; built with beta 1, c 0.06, alpha_N {}, alpha_S {}, phi {:.2}", DAYS, A_N, A_S, 1.0 + A_N - A_S);
    println!("figure, days {}", days.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(" "));
    for (name, xs) in [("north", &north), ("south", &south), ("tied leftover", &y.z), ("unrelated leftover", &o.z)] {
        println!("figure, {} {}", name, f2(xs, &days));
    }
    println!("step 1: beta_hat {:.4}, c_hat {:.4}; by bracket search {:.4}", y.b, y.c, beta_search);
    println!("step 2: rho_hat {:.4}, se {:.4}, tau {:.2}, phi {:.4}", y.rho, y.se, y.tau, 1.0 + y.rho);
    println!("half-life of a gap, fitted: {:.2} days; built: {:.2} days",
             0.5f64.ln() / (1.0 + y.rho).ln(), 0.5f64.ln() / (1.0 + A_N - A_S).ln());
    println!("5% cutoff, two prices: {:.3}; one series: {:.3}; tied: {}", cut2, cut1, if y.tau < cut2 { "yes" } else { "no" });
    println!("ecm: alpha_N {:.4} (se {:.4}), alpha_S {:.4} (se {:.4})", a_n, se_n, a_s, se_s);
    println!("alpha_N - beta_hat alpha_S = {:.4}, the step-2 rho {:.4}", a_n - y.b * a_s, y.rho);
    let (mut gap, mut moves) = (SHOCK, Vec::new());   // a 10-cent jump at North, traced
    for _ in 0..400 {
        moves.push((gap, A_N * gap, A_S * gap));
        gap += (A_N - A_S) * gap;
    }
    for d in 0..6 {
        println!("shock, day {}: excess gap {:.2} cents, North {:+.2}, South {:+.2}", d, moves[d].0, moves[d].1, moves[d].2);
    }
    let tot_n: f64 = moves.iter().map(|m| m.1).sum();
    let tot_s: f64 = moves.iter().map(|m| m.2).sum();
    let (form_n, form_s) = (A_N * SHOCK / (A_S - A_N), A_S * SHOCK / (A_S - A_N));
    println!("shock totals, summed: North {:+.2}, South {:+.2}; by formula {:+.2}, {:+.2}", tot_n, tot_s, form_n, form_s);
    let toy: Vec<i64> = vec![4, 3, 1, 2, 0, -1, 0];   // the by-hand table, in cents
    let cross: i64 = (1..7).map(|t| toy[t - 1] * (toy[t] - toy[t - 1])).sum();
    let square: i64 = (0..6).map(|t| toy[t] * toy[t]).sum();
    let toy_f: Vec<f64> = toy.iter().map(|&v| v as f64).collect();
    let (toy_rho, _) = slope0(&diff(&toy_f), &toy_f[..6]);
    println!("toy: sum lag*change {}, sum lag^2 {}, rho {:.4}", cross, square, toy_rho);
    let (m, k, mut rng) = (4000usize, 500usize, Rng { s: 99 });   // unrelated pairs, then tied years
    let (mut taus, mut r2s) = (Vec::new(), Vec::new());
    for _ in 0..m {
        let (x, w) = (walk(&mut rng, 1.0), walk(&mut rng, 1.0));
        let out = eg(&x, &w);
        taus.push(out.tau);
        r2s.push(out.r2);
    }
    for v in [&mut taus, &mut r2s] { v.sort_by(|a, b| a.partial_cmp(b).unwrap()) }
    let p2 = taus.iter().filter(|&&v| v < cut2).count() as f64 / m as f64;
    let p1 = taus.iter().filter(|&&v| v < cut1).count() as f64 / m as f64;
    println!("{} unrelated pairs: simulated 5% cutoff {:.3}; median R^2 {:.2}", m, taus[m / 20], r2s[m / 2]);
    for (cut, p) in [(cut2, p2), (cut1, p1)] {
        println!("passed at {:.3}: {:.2}% (se {:.2})", cut, 100.0 * p, 100.0 * (p * (1.0 - p) / m as f64).sqrt());
    }
    let (mut betas, mut hits) = (Vec::new(), 0usize);
    for _ in 0..k {
        let (n_k, s_k) = stations(&mut rng);
        let out = eg(&n_k, &s_k);
        betas.push(out.b);
        if out.tau < cut2 { hits += 1 }
    }
    let mb = mean(&betas);
    let sb = (betas.iter().map(|b| (b - mb).powi(2)).sum::<f64>() / (k - 1) as f64).sqrt();
    println!("{} tied years: judged tied {:.2}%; beta_hat mean {:.4}, spread {:.4}", k, 100.0 * hits as f64 / k as f64, mb, sb);
    let ms = mean(&south);
    let se_naive = (y.z.iter().map(|v| v * v).sum::<f64>() / (DAYS - 2) as f64
        / south.iter().map(|s| (s - ms).powi(2)).sum::<f64>()).sqrt();
    let (_, b_d, _, _) = fit_line(&diff(&north), &diff(&south));
    println!("break 1, one-series cutoff on unrelated pairs: {:.2}% pass, not 5%", 100.0 * p1);
    println!("break 2, unrelated price against North: R^2 {:.2}, ratio {:.2}, tau {:.2}", o.r2, o.b, o.tau);
    println!("break 3, textbook se of beta_hat {:.4}, against the spread {:.4} over {} years", se_naive, sb, k);
    println!("break 4, changes on changes: slope {:.2}, not 1", b_d);
    assert!((y.b - beta_search).abs() < 1e-6);                        // two roads to the ratio
    assert!((a_n - A_N).abs() < 3.0 * se_n && (a_s - A_S).abs() < 3.0 * se_s);   // near the build
    assert!((p2 - 0.05).abs() < 3.0 * (0.05 * 0.95 / m as f64).sqrt());   // simulated vs published
    assert!((tot_n - form_n).abs() < 1e-9);                           // summed trace vs geometric series
    assert!((toy_rho + 14.0 / 31.0).abs() < 1e-12);                   // the by-hand fraction
    assert!(y.tau < cut2 && (a_n - y.b * a_s - y.rho).abs() < 1e-12);   // the verdict; pulls rebuild rho
    assert!(p1 > 0.05 + 3.0 * (0.05 * 0.95 / m as f64).sqrt());      // break 1: one-series cutoff over-passes
    println!("ALL CHECKS PASS");
}
