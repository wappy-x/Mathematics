// Monte Carlo pricing -- the same check as the Python, in Rust.  No crates.
// The uniform numbers come from the recurrence printed on the card, the normals
// from Box-Muller, and the bell-curve area and the reference integral from
// Simpson's rule written out here.  Nothing already knows the answer.
use std::f64::consts::PI;

const S: f64 = 100.0;                                      // the house market
const K: f64 = 100.0;
const R: f64 = 0.05;
const Q: f64 = 0.02;
const SIG: f64 = 0.20;
const T: f64 = 1.0;
const SEED: u64 = 20260914;
const PATHS: usize = 100000;
const MARKS: [usize; 7] = [1000, 5000, 10000, 25000, 50000, 75000, 100000];
const PREFIX: [usize; 4] = [1000, 10000, 25000, 100000];
const EXACT: f64 = 9.227005508154;     // the formula's price, from the call card
const MOD: u64 = 1 << 32;

fn uniform(state: &mut u64) -> f64 {   // one step of the recurrence, whole numbers
    *state = (1664525 * *state + 1013904223) % MOD;
    (*state as f64 + 0.5) / MOD as f64                  // lands strictly inside 0, 1
}

fn normal_pair(state: &mut u64) -> (f64, f64) {   // two uniforms -> two normals
    let u = uniform(state);
    let v = uniform(state);
    let (radius, angle) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * v);
    (radius * angle.cos(), radius * angle.sin())
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                   // the integrator, written out here
    let mut total = f(a) + f(b);
    for i in 1..n {
        total += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    total * h / 3.0
}

fn phi(x: f64) -> f64 {                // bell-curve height at x
    (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

fn n_cdf(x: f64) -> f64 {              // bell-curve area to the left of x
    if x < -12.0 { 0.0 } else if x > 12.0 { 1.0 } else { 0.5 + simpson(phi, 0.0, x, 4000) }
}

fn call_formula(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let vt = sig * t.sqrt();                      // road 2: the closed form, own CDF
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / vt;
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d1 - vt)
}

fn payoff_integral(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let drift = (r - q - 0.5 * sig * sig) * t;    // road 3: the same average, by slices
    let f = |z: f64| (s * (drift + sig * t.sqrt() * z).exp() - k).max(0.0) * phi(z);
    (-r * t).exp() * simpson(f, -10.0, 10.0, 40000)
}

type Marked = Vec<(usize, f64, f64, f64)>;

fn run(drift: f64, disc: f64, paths: usize, marks: &[usize]) -> (f64, f64, Marked) {
    let (mut state, mut n, mut mean, mut m2, mut stock) = (SEED, 0usize, 0.0, 0.0, 0.0);
    let mut marked: Marked = Vec::new();          // road 1: the simulation
    while n < paths {
        let (z1, z2) = normal_pair(&mut state);
        for z in [z1, z2] {
            let st = S * (drift + SIG * T.sqrt() * z).exp();   // one simulated ending
            let pay = disc * (st - K).max(0.0);                // its discounted payoff
            stock += disc * st;
            n += 1;
            let delta = pay - mean;                            // running mean and spread
            mean += delta / n as f64;
            m2 += delta * (pay - mean);
            if marks.contains(&n) {
                let sd = (m2 / (n - 1) as f64).sqrt();
                marked.push((n, mean, sd, sd / (n as f64).sqrt()));
            }
        }
    }
    (mean, stock / n as f64, marked)
}

fn main() {
    let disc = (-R * T).exp();
    let drift = (R - Q - 0.5 * SIG * SIG) * T;
    let (mc, stock_mean, marked) = run(drift, disc, PATHS, &MARKS);
    let at = |want: usize| -> (f64, f64, f64) {
        let row = marked.iter().find(|r| r.0 == want).unwrap();
        (row.1, row.2, row.3)
    };
    let se_end = at(PATHS).2;
    let formula = call_formula(S, K, R, Q, SIG, T);
    let integral = payoff_integral(S, K, R, Q, SIG, T);
    let wrong_real = run((0.10 - Q - 0.5 * SIG * SIG) * T, disc, PATHS, &[]).0;
    let wrong_drag = run((R - Q) * T, disc, PATHS, &[]).0;
    let wrong_disc = run(drift, 1.0, PATHS, &[]).0;
    let wrong_one = disc * (S * ((R - Q) * T).exp() - K).max(0.0);

    println!("Acme: S = {:.2}  K = {:.2}  r = {:.0}%  q = {:.0}%  sigma = {:.0}%  T = {:.0} year",
             S, K, R * 100.0, Q * 100.0, SIG * 100.0, T);
    println!("{} draws from seed {}, in Box-Muller pairs from the printed recurrence", PATHS, SEED);
    println!();
    let (mut state, mut shown, mut first_mean) = (SEED, Vec::new(), 0.0);
    while shown.len() < 4 {                      // the first four draws, one by one
        let (za, zb) = normal_pair(&mut state);
        for z in [za, zb] {
            let st = S * (drift + SIG * T.sqrt() * z).exp();
            let pay = disc * (st - K).max(0.0);
            first_mean += (pay - first_mean) / (shown.len() + 1) as f64;
            shown.push((z, st, (st - K).max(0.0), pay, first_mean));
        }
    }
    println!("  draw           z   ending price       payoff    discounted   running mean");
    for (i, (z, st, raw, pay, avg)) in shown.iter().enumerate() {
        println!("{:>6}  {:>10.6}  {:>13.6}  {:>11.6}  {:>12.6}  {:>12.6}", i + 1, z, st, raw, pay, avg);
    }
    println!("one year's discount factor e^-rT                    {:>12.6}", disc);
    println!("pretend-world drift (r - q - sigma^2/2)T            {:>12.6}", drift);
    println!("one wiggle unit sigma sqrt(T)                       {:>12.6}", SIG * T.sqrt());
    println!();
    println!("road 1  simulation, {} paths                  {:>12.6}", PATHS, mc);
    println!("road 2  closed form, own bell-curve area          {:>12.6}", formula);
    println!("road 3  the same average by Simpson slices        {:>12.6}", integral);
    println!("sampler check  average of e^-rT S_T              {:>13.6}", stock_mean);
    println!("               the market's S e^-qT              {:>13.6}", S * (-Q * T).exp());
    println!();
    println!("  paths     estimate    payoff sd    std error   two-SE low  two-SE high   gap to road 2");
    for n in PREFIX {
        let (m, sd, se) = at(n);
        println!("{:>7}  {:>11.6}  {:>11.6}  {:>11.6}  {:>11.6}  {:>11.6}  {:>13.6}",
                 n, m, sd, se, m - 2.0 * se, m + 2.0 * se, m - formula);
    }
    println!();
    println!("root-n law, same draws:  SE(1000) / SE(100000) = {:>6.3}   (theory 10.000)", at(1000).2 / se_end);
    println!("                        SE(25000) / SE(100000) = {:>6.3}   (theory  2.000)", at(25000).2 / se_end);
    println!();
    println!("what breaks");
    println!("  a 10% real-world drift in place of r - q                   {:>12.6}", wrong_real);
    println!("  drift without the -sigma^2/2 drag                         {:>12.6}", wrong_drag);
    println!("  no discount factor e^-rT                                  {:>12.6}", wrong_disc);
    println!("  payoff of the average ending, not average of payoffs      {:>12.6}", wrong_one);
    println!();
    let counts: Vec<String> = PREFIX.iter().map(|n| n.to_string()).collect();
    let bars: Vec<String> = PREFIX.iter().map(|&n| format!("{:.2}", at(n).2)).collect();
    println!("bar, standard error in dollars at {} paths: {}", counts.join(", "), bars.join("  "));
    let paths_row: Vec<String> = MARKS.iter().map(|n| format!("{:>7}", n)).collect();
    let est_row: Vec<String> = MARKS.iter().map(|&n| format!("{:>7.2}", at(n).0)).collect();
    let ref_row: Vec<String> = MARKS.iter().map(|_| format!("{:>7.2}", formula)).collect();
    println!("chart, paths             {}", paths_row.join(" "));
    println!("chart, running estimate  {}", est_row.join(" "));
    println!("chart, road 2 price      {}", ref_row.join(" "));

    assert!((formula - EXACT).abs() < 1e-9, "closed form vs the call card's price");
    assert!((integral - EXACT).abs() < 1e-7, "Simpson average vs the call card's price");
    assert!((mc - formula).abs() < 3.0 * se_end, "simulation within three standard errors");
    assert!((stock_mean - S * (-Q * T).exp()).abs() < 0.5, "the sampler drifts as the pretend world does");
    assert!(at(25000).2 / se_end > 1.7 && at(25000).2 / se_end < 2.3, "four times the paths, half the error");
    assert!((wrong_one - 2.896925).abs() < 1e-6, "one average future prices the forward, not the option");
    assert!(wrong_real > wrong_drag && wrong_drag > mc, "each broken drift lifts the estimate");
    println!("ALL CHECKS PASS");
}
