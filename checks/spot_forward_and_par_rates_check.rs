// Spot, forward and par rates -- the same check as the Python, in Rust.  No
// crates, std only, and nothing borrowed that already knows an answer: the
// root finder is a bisection written out here, and every power is a loop of
// multiplications.  One annual-compounding curve, five maturities.  The
// forward rate and the par rate are each reached by roads that share no
// arithmetic: algebra on the discount factors, a bisection that matches two
// investments, and a ladder run backwards that recovers the spot curve from
// the par curve alone.
const YEARS: [usize; 5] = [1, 2, 3, 4, 5];
const SPOT: [f64; 5] = [0.04, 0.05, 0.055, 0.058, 0.06];
const FACE: f64 = 100.0;

fn grow(rate: f64, n: usize) -> f64 {
    // (1 + rate) multiplied in n times: what one dollar in the bank becomes.
    let mut out = 1.0;
    for _ in 0..n {
        out *= 1.0 + rate;
    }
    out
}

fn bisect<F: Fn(f64) -> f64>(f: F, lo0: f64, hi0: f64) -> f64 {
    // The root finder, written out: halve the bracket 200 times.
    let (mut lo, mut hi) = (lo0, hi0);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if f(lo) * f(mid) <= 0.0 {
            hi = mid;
        } else {
            lo = mid;
        }
    }
    0.5 * (lo + hi)
}

fn price(coupon: f64, n: usize, factors: &[f64]) -> f64 {
    // An n-year annual bond, coupon in dollars, priced off given factors.
    (1..=n).map(|t| coupon * factors[t - 1]).sum::<f64>() + FACE * factors[n - 1]
}

fn bootstrap(par_rates: &[f64]) -> Vec<f64> {
    // Road 3: spot rates out of the par curve alone, shortest maturity first.
    let mut z: Vec<f64> = Vec::new();
    for (i, c) in par_rates.iter().enumerate() {
        let n = YEARS[i];
        let cpn = c * FACE;
        let known: f64 = (1..n).map(|t| cpn / grow(z[t - 1], t)).sum();
        z.push(bisect(|x| known + (cpn + FACE) / grow(x, n) - FACE, -0.5, 1.0));
    }
    z
}

fn main() {
    let d: Vec<f64> = YEARS.iter().map(|&t| 1.0 / grow(SPOT[t - 1], t)).collect(); // D(t)
    let ann: Vec<f64> = YEARS.iter().map(|&n| d[..n].iter().sum()).collect(); // A_n
    let mut fwd: Vec<f64> = vec![SPOT[0]]; // road 1
    for &t in YEARS[1..].iter() {
        fwd.push(d[t - 2] / d[t - 1] - 1.0);
    }
    let par: Vec<f64> = YEARS.iter().map(|&n| (1.0 - d[n - 1]) / ann[n - 1]).collect(); // road 1

    let one_year = FACE * grow(SPOT[0], 1); // 100 lent for one year
    let two_year = FACE * grow(SPOT[1], 2); // 100 lent for two years
    let rolled = one_year * (1.0 + fwd[1]); // 100 lent for one year, then rolled
    let f12_bisect = bisect(|x| one_year * (1.0 + x) - two_year, -0.5, 0.5); // road 2
    let par_bisect: Vec<f64> = YEARS // road 2
        .iter()
        .map(|&n| bisect(|c| price(c, n, &d) - FACE, 0.0, 50.0) / FACE)
        .collect();

    let spot_back = bootstrap(&par);
    let mut fwd_back: Vec<f64> = vec![spot_back[0]];
    for &t in YEARS[1..].iter() {
        fwd_back.push(grow(spot_back[t - 1], t) / grow(spot_back[t - 2], t - 1) - 1.0);
    }
    let mut chain = 1.0;
    for f in fwd.iter() {
        chain /= 1.0 + f; // the forwards multiplied back into D(5)
    }
    let gap = spot_back
        .iter()
        .zip(SPOT.iter())
        .map(|(a, b)| (a - b).abs())
        .fold(0.0_f64, f64::max);
    let par_gap = par_bisect
        .iter()
        .zip(par.iter())
        .map(|(a, b)| (a - b).abs())
        .fold(0.0_f64, f64::max);

    let g1 = grow(SPOT[0], 1); // what one dollar becomes in one year
    let g2 = grow(SPOT[1], 2); // what one dollar becomes in two years
    let fake = 0.065; // a forward quoted too high
    let arb_end = one_year * (1.0 + fake); // what the rolled 100 dollars would come to
    let roll_short = FACE * grow(SPOT[0], 2); // mistake: roll at today's 1-year rate
    let spot_as_fwd = one_year * (1.0 + SPOT[1]); // mistake: 2-year spot for year two
    let average = 0.5 * (SPOT[0] + SPOT[1]); // mistake: average the two spots
    let linear = 2.0 * SPOT[1] - SPOT[0]; // the continuous-compounding shortcut
    let zero_true = FACE * d[4]; // 5-year zero, priced on the spot curve
    let zero_par = FACE / grow(par[4], 5); // mistake: par yield read as a spot rate

    println!("one curve, annual compounding, five maturities");
    println!("{:>4}{:>11}{:>11}{:>11}{:>11}", "year", "spot %", "D(t)", "forward %", "par %");
    for &t in YEARS.iter() {
        println!("{:>4}{:>11.4}{:>11.6}{:>11.4}{:>11.4}",
                 t, 100.0 * SPOT[t - 1], d[t - 1], 100.0 * fwd[t - 1], 100.0 * par[t - 1]);
    }
    println!();
    println!("the two-year question, on 100 dollars");
    println!("  lend for two years at {:.2} percent      {:>10.4}", 100.0 * SPOT[1], two_year);
    println!("  lend one year at {:.2} percent           {:>10.4}", 100.0 * SPOT[0], one_year);
    println!("  then roll at the forward {:.4} percent  {:>10.4}", 100.0 * fwd[1], rolled);
    println!("  forward by bisection, not by algebra    {:>10.4}", 100.0 * f12_bisect);
    println!("  forward from the bootstrapped curve     {:>10.4}", 100.0 * fwd_back[1]);
    println!("  D(1)/D(2) - 1                           {:>10.4}", 100.0 * (d[0] / d[1] - 1.0));
    println!();
    println!("by hand, from the two quotes");
    println!("  one dollar for one year               {:>10.6}", g1);
    println!("  one dollar for two years              {:>10.6}", g2);
    println!("  the ratio: year two on its own        {:>10.6}", g2 / g1);
    println!("  annuity A(2) = D(1) + D(2)            {:>10.6}", ann[1]);
    println!("  one dollar less D(2)                  {:>10.6}", 1.0 - d[1]);
    println!();
    println!("the par rate, two roads");
    println!("{:>4}{:>12}{:>12}{:>12}", "year", "formula %", "bisected %", "bond price");
    for &n in YEARS.iter() {
        println!("{:>4}{:>12.4}{:>12.4}{:>12.6}",
                 n, 100.0 * par[n - 1], 100.0 * par_bisect[n - 1], price(par[n - 1] * FACE, n, &d));
    }
    println!();
    println!("the ladder backwards: spot rates recovered from the par curve alone");
    println!("  {}", spot_back.iter().map(|z| format!("{:.4}", 100.0 * z))
             .collect::<Vec<String>>().join("  "));
    println!("  largest gap from the curve we started with: {:.12}", gap);
    println!("  forwards multiplied back into D(5): {:.6} against {:.6}", chain, d[4]);
    println!();
    println!("what breaks");
    println!("  roll at today's 1-year rate twice        {:>10.4}  short {:.4}",
             roll_short, two_year - roll_short);
    println!("  use the 2-year spot for year two         {:>10.4}  short {:.4}",
             spot_as_fwd, two_year - spot_as_fwd);
    println!("  average the two spots, as a rate         {:>10.4}  against {:.4}",
             100.0 * average, 100.0 * fwd[1]);
    println!("  2 x 2-year minus 1-year, as a rate       {:>10.4}  against {:.4}",
             100.0 * linear, 100.0 * fwd[1]);
    println!("  5-year zero on the spot curve            {:>10.4}", zero_true);
    println!("  5-year zero on the par yield             {:>10.4}  over by {:.4}",
             zero_par, zero_par - zero_true);
    println!("  roll at a forward quoted {:.2} percent  {:>10.4}  free {:.4}",
             100.0 * fake, arb_end, arb_end - two_year);
    println!();
    println!("{:<22}{}", "chart, year",
             YEARS.iter().map(|t| format!("{:6}", t)).collect::<Vec<String>>().join(" "));
    for (label, series) in [("chart, spot %", &SPOT[..]), ("chart, forward %", &fwd[..]),
                            ("chart, par %", &par[..])] {
        println!("{:<22}{}", label,
                 series.iter().map(|v| format!("{:6.2}", 100.0 * v)).collect::<Vec<String>>().join(" "));
    }

    assert!((rolled - two_year).abs() < 1e-9, "rolled deposit must land on the two-year deposit");
    assert!((f12_bisect - fwd[1]).abs() < 1e-9, "bisected forward vs the algebra");
    assert!((price(par[4] * FACE, 5, &d) - FACE).abs() < 1e-9, "par coupon must price the bond at 100");
    assert!(par_gap < 1e-9, "bisected par rates vs the algebra");
    assert!(gap < 1e-9, "the ladder must recover the curve");
    assert!((chain - d[4]).abs() < 1e-12, "the forwards must multiply back into D(5)");
    assert!(par[4] < SPOT[4], "on a rising curve the par rate sits below the spot rate");
    println!("ALL CHECKS PASS");
}
