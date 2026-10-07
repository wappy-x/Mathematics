// Replication and self-financing -- the same check as the Python, in Rust.  No crates.
// Acme starts at 100.00, a call struck at 100.00 runs one year, the bank pays 5 percent,
// jumpiness is 20 percent, and the year is cut into equal steps.  Rust has no erf, so the
// bell-curve area is built the honest way: add up thin slices under the curve (Simpson).
use std::f64::consts::PI;

const S0: f64 = 100.0;  const K: f64 = 100.0;  const R: f64 = 0.05;
const SIG: f64 = 0.20;  const T: f64 = 1.0;

/// One step of n: up and down factors, the bank's growth over a step, and the factor a
/// share holding grows by when its dividends are put back in.
fn lattice(n: usize, q: f64) -> (f64, f64, f64, f64) {
    let u = (SIG * (T / n as f64).sqrt()).exp();
    (u, 1.0 / u, (R * T / n as f64).exp(), (q * T / n as f64).exp())
}

fn payoff(s: f64) -> f64 { (s - K).max(0.0) }   // the call: the gap above the strike, or nothing
/// Every price Acme can reach: row m is the date m steps in, j ups so far.
fn tree(n: usize, q: f64) -> Vec<Vec<f64>> {
    let (u, d, _, _) = lattice(n, q);
    let mut rows = vec![vec![S0]];
    for m in 1..=n {
        let mut row = vec![rows[m - 1][0] * d];
        for j in 1..=m { row.push(rows[m - 1][j - 1] * u); }
        rows.push(row);
    }
    rows
}

/// Road 1.  Work backwards.  At each node two demands -- match the option if Acme rises,
/// match it if Acme falls -- fix the share count h and the bank balance c.  What that
/// pair costs is the node's wealth.  No probability anywhere in it.
fn replicate(n: usize, q: f64) -> (f64, Vec<Vec<(f64, f64)>>, Vec<Vec<f64>>) {
    let (_, _, grow, div) = lattice(n, q);
    let price = tree(n, q);
    let mut v: Vec<f64> = price[n].iter().map(|&s| payoff(s)).collect();
    let mut ledger: Vec<Vec<(f64, f64)>> = Vec::new();
    for m in (0..n).rev() {
        let (mut w, mut row) = (Vec::new(), Vec::new());
        for j in 0..=m {
            let (su, sd) = (price[m + 1][j + 1], price[m + 1][j]);
            let h = (v[j + 1] - v[j]) / (su - sd) / div;
            let c = (v[j + 1] - h * div * su) / grow;
            row.push((h, c));
            w.push(h * price[m][j] + c);
        }
        ledger.push(row);
        v = w;
    }
    ledger.reverse();
    (v[0], ledger, price)
}

/// Road 2.  No hedging at all.  Weight each ending price by the number that reproduces
/// today's share price, average the payoff over those weights, discount it.
fn by_weights(n: usize, q: f64) -> f64 {
    let (u, d, grow, div) = lattice(n, q);
    let p = (grow / div - d) / (u - d);
    let ends = &tree(n, q)[n];
    let (mut total, mut coeff) = (0.0, 1.0);
    for j in 0..=n {
        total += coeff * p.powi(j as i32) * (1.0 - p).powi((n - j) as i32) * payoff(ends[j]);
        coeff = coeff * (n - j) as f64 / (j + 1) as f64;
    }
    total / grow.powi(n as i32)
}

/// Road 3.  Run the ledger forward down every path.  At each trading date, compare what
/// the holdings arriving are worth with what the new ones cost: the difference is money
/// from outside, and self-financing means it is zero.
fn walk(n: usize, q: f64) -> (f64, f64, f64, Vec<(String, f64, f64)>) {
    let (_, _, grow, div) = lattice(n, q);
    let (v0, ledger, price) = replicate(n, q);
    let (mut gap, mut outside) = (0.0_f64, 0.0_f64);
    let mut rows = Vec::new();
    for path in 0..(1usize << n) {
        let (mut j, mut name) = (0usize, String::new());
        let (mut h, mut c) = ledger[0][0];
        let mut marked = v0;
        for m in 1..=n {
            let up = (path >> (n - m)) & 1;
            j += up;
            if m > 1 { name.push('-'); }
            name.push_str(if up == 1 { "up" } else { "down" });
            marked = h * div * price[m][j] + c * grow;
            if m < n {
                let (h2, c2) = ledger[m][j];
                outside = outside.max((h2 * price[m][j] + c2 - marked).abs());
                h = h2;
                c = c2;
            }
        }
        gap = gap.max((marked - payoff(price[n][j])).abs());
        rows.push((name, marked, payoff(price[n][j])));
    }
    (v0, gap, outside, rows)
}

fn bell(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height at x
fn normal_cdf(x: f64) -> f64 {                                        // area to the left of x
    let (a, b, n) = (0.0_f64, x, 4000);
    let hh = (b - a) / n as f64;
    let mut s = bell(a) + bell(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * bell(a + i as f64 * hh); }
    0.5 + s * hh / 3.0
}

fn black_scholes(q: f64) -> f64 {                     // the limit a refined tree walks toward
    let wiggle = SIG * T.sqrt();
    let d1 = ((S0 / K).ln() + (R - q + 0.5 * SIG * SIG) * T) / wiggle;
    S0 * (-q * T).exp() * normal_cdf(d1) - K * (-R * T).exp() * normal_cdf(d1 - wiggle)
}

fn main() {
    let (u, d, grow, _) = lattice(2, 0.0);
    let (v0, gap, outside, paths) = walk(2, 0.0);
    let (price, ledger) = (tree(2, 0.0), replicate(2, 0.0).1);
    println!("Acme {:.2}, call struck at {:.2}, one year, bank {:.0} percent, jumpiness {:.0} percent", S0, K, R * 100.0, SIG * 100.0);
    println!("two six-month steps: up factor {:.6}, down factor {:.6}, bank factor per step {:.6}", u, d, grow);
    println!("Acme after six months: up {:.6}, down {:.6}", price[1][1], price[1][0]);
    println!("Acme at expiry: up-up {:.6}, up-down {:.6}, down-down {:.6}", price[2][2], price[2][1], price[2][0]);
    println!("call payoff at expiry: up-up {:.6}, up-down {:.6}, down-down {:.6}",
             payoff(price[2][2]), payoff(price[2][1]), payoff(price[2][0]));
    println!();
    println!("{:<13}{:>12}{:>11}{:>13}{:>12}", "the ledger", "Acme", "shares", "bank", "wealth");
    for (label, m, j) in [("start", 0, 0), ("after an up", 1, 1), ("after a down", 1, 0)] {
        let (h, c) = ledger[m][j];
        println!("{:<13}{:>12.6}{:>11.6}{:>13.6}{:>12.6}", label, price[m][j], h, c, h * price[m][j] + c)
    }
    println!();
    println!("{:<13}{:>18}{:>17}", "path", "wealth at expiry", "the payoff owed");
    for (name, wealth, owed) in &paths { println!("{:<13}{:>18.6}{:>17.6}", name, wealth, owed); }
    println!();
    println!("road 1, backward replication, cost today       {:>12.6}", v0);
    println!("road 2, binomial weights, no hedging at all    {:>12.6}", by_weights(2, 0.0));
    println!("road 3, worst gap between wealth and payoff    {:>12.6}", gap);
    println!("road 3, worst money from outside at a trade    {:>12.6}", outside);
    println!("\nthe same recipe, the year cut into more steps");
    for n in [2usize, 4, 16, 64, 256, 1024] {
        println!("  {:>4} steps: no dividend {:>10.6}    2 percent dividend {:>10.6}", n, replicate(n, 0.0).0, replicate(n, 0.02).0)
    }
    println!("  the limit: no dividend {:>10.6}    2 percent dividend {:>10.6}", black_scholes(0.0), black_scholes(0.02));
    let ((h0, c0), (hu, cu)) = (ledger[0][0], ledger[1][1]);
    let frozen: Vec<f64> = price[2].iter().map(|s| h0 * s + c0 * (R * T).exp()).collect();
    let ratio = (hu * price[1][1] + cu) / price[1][1];
    let deposit = -(cu - c0 * grow);
    println!("\nwhat breaks");
    println!("  never rebalanced: expiry wealth {:.6} / {:.6} / {:.6}, payoff owed {:.6} / {:.6} / {:.6}",
             frozen[0], frozen[1], frozen[2], payoff(price[2][0]), payoff(price[2][1]), payoff(price[2][2]));
    println!("  hedge by value over price at the up node, {:.6} shares and no loan: pays {:.6} at up-up and {:.6} at up-down",
             ratio, ratio * price[2][2], ratio * price[2][1]);
    println!("  new money at the trade: {:.6} deposited, up-up ends at {:.6}, {:.6} of it the deposit grown",
             deposit, hu * price[2][2] + c0 * grow * grow, deposit * grow);
    println!();
    let spots: Vec<f64> = (0..9).map(|i| 60.0 + 10.0 * i as f64).collect();
    let row = |label: &str, f: &dyn Fn(f64) -> f64| {
        println!("{:<25}{}", label,
                 spots.iter().map(|&s| format!("{:7.2}", f(s))).collect::<Vec<_>>().join(" "));
    };
    row("chart, Acme at expiry", &|s| s);
    row("chart, call payoff", &|s| payoff(s));
    row("chart, never rebalanced", &|s| h0 * s + c0 * (R * T).exp());
    assert!((v0 - by_weights(2, 0.0)).abs() < 1e-10);      // hedge ledger against probability weights
    assert!(gap < 1e-9);                                   // the copy pays what the call pays, every path
    assert!(outside < 1e-9);                               // and never takes a cent from outside
    assert!((replicate(1024, 0.0).0 - black_scholes(0.0)).abs() < 0.01);   // refinement reaches the limit
    assert!((replicate(1024, 0.02).0 - 9.227005508154).abs() < 0.01);      // and the wing's house call
    assert!((frozen[2] - payoff(price[2][2])).abs() > 5.0);                // a frozen hedge really fails
    println!("ALL CHECKS PASS");
}
