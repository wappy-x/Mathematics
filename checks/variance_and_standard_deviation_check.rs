// Variance and standard deviation -- the check behind the card, in Rust, std
// only.  The raffle ticket pays $100 with chance 0.01 and $0 otherwise.  Its
// variance is reached four ways: the definition, the shortcut, a count over a
// raffle of 100 real tickets, and a seeded simulation of a million tickets.
const LAW: [(f64, f64); 2] = [(0.0, 0.99), (100.0, 0.01)]; // (payout in dollars, chance)

fn mean(law: &[(f64, f64)]) -> f64 {
    law.iter().map(|&(x, p)| p * x).sum()
}

fn var_definition(law: &[(f64, f64)]) -> f64 {
    // road 1: average squared distance
    let m = mean(law);
    law.iter().map(|&(x, p)| p * (x - m).powf(2.0)).sum()
}

fn var_shortcut(law: &[(f64, f64)]) -> f64 {
    // road 2: E[X^2] minus the mean squared
    law.iter().map(|&(x, p)| p * x * x).sum::<f64>() - mean(law).powf(2.0)
}

fn sqrt(v: f64) -> f64 {
    // Newton's method, written out here
    if v == 0.0 {
        return 0.0;
    }
    let mut r = if v > 1.0 { v } else { 1.0 };
    for _ in 0..100 {
        r = 0.5 * (r + v / r);
    }
    r
}

fn splitmix64(state: u64) -> (u64, u64) {
    // the generator both languages share
    let state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (state, z ^ (z >> 31))
}

fn enumerate_tickets(pay: i64, a: i64, b: i64) -> (f64, f64) {
    // road 3: 100 tickets, ticket 37 wins; whole numbers, no rounding at all
    let vals: Vec<i64> = (0..100).map(|t| a * (if t == 37 { pay } else { 0 }) + b).collect();
    let total: i64 = vals.iter().sum();
    let sq: i64 = vals.iter().map(|&v| (100 * v - total) * (100 * v - total)).sum();
    (total as f64 / 100.0, sq as f64 / 1_000_000.0)
}

fn row(label: &str, v: f64) {
    println!("{:<40} {:>14.6}", label, v);
}

fn main() {
    let (mu, v_def, v_short) = (mean(&LAW), var_definition(&LAW), var_shortcut(&LAW));
    let ex2: f64 = LAW.iter().map(|&(x, p)| p * x * x).sum();
    let (m_enum, v_enum) = enumerate_tickets(100, 1, 0);
    let v_indicator = 100f64.powf(2.0) * (0.01 * (1.0 - 0.01)); // a = 100 times a 0-or-1 indicator
    let sd = sqrt(v_def);

    // road 4: a seeded simulation, one million tickets, variance by the definition
    let (n, mut state) = (1_000_000usize, 20260928u64);
    let mut draws = Vec::with_capacity(n);
    for _ in 0..n {
        let (s, z) = splitmix64(state);
        state = s;
        draws.push(if ((z >> 11) as f64) * 2f64.powf(-53.0) < 0.01 { 100.0 } else { 0.0 });
    }
    let nf = n as f64;
    let m_sim = draws.iter().sum::<f64>() / nf;
    let v_sim = draws.iter().map(|d| (d - m_sim).powf(2.0)).sum::<f64>() / nf;
    let m4_sim = draws.iter().map(|d| (d - m_sim).powf(4.0)).sum::<f64>() / nf;
    let se_v = sqrt((m4_sim - v_sim.powf(2.0)) / nf); // standard error of the variance
    let sd_sim = sqrt(v_sim);
    let se_sd = se_v / (2.0 * sd_sim); // and of its square root

    row("mean E[X]", mu);
    row("E[X^2]", ex2);
    row("1 definition: sum p (x - mean)^2", v_def);
    row("2 shortcut: E[X^2] - mean^2", v_short);
    row("3 count, 100 tickets: mean", m_enum);
    row("3 count, 100 tickets: variance", v_enum);
    row("4 simulated, 1,000,000: mean", m_sim);
    row("4 simulated: variance", v_sim);
    row("4 simulated: standard error of it", se_v);
    row("5 indicator alone: p(1 - p)", 0.01 * (1.0 - 0.01));
    row("5 prize^2 times p(1 - p)", v_indicator);
    row("standard deviation sqrt(99)", sd);
    row("simulated standard deviation", sd_sim);
    row("  its standard error", se_sd);
    row("mean +/- one sd: low end", mu - sd);
    row("mean +/- one sd: high end", mu + sd);
    println!();
    println!("scaled ticket aX + b     a      b    mean  var by count   a^2 Var(X)      sd");
    for &(name, a, b) in [("net of a $2 price", 1i64, -2i64), ("organiser: 2 - X", -1, 2),
                          ("double prize: 2X", 2, 0), ("in cents: 100X", 100, 0)].iter() {
        let (m_ab, v_ab) = enumerate_tickets(100, a, b);
        let af = a as f64;
        println!("{:<20} {:>6} {:>6} {:>7.2} {:>14.2} {:>12.2} {:>7.2}", name, a, b, m_ab, v_ab, af * af * v_def, sqrt(v_ab));
        assert!((v_ab - af * af * v_def).abs() < 1e-6 * (1.0 + af * af * v_def), "{}", name);
    }
    println!();
    row("wrong: no square, sum p (x - mean)", LAW.iter().map(|&(x, p)| p * (x - mu)).sum());
    row("wrong: average distance, no square", LAW.iter().map(|&(x, p)| p * (x - mu).abs()).sum());
    row("wrong: Var(2X) = 2 Var(X)", 2.0 * v_def);
    row("wrong: 2X, E[Y^2] - E[Y] not E[Y]^2", 4.0 * ex2 - 2.0 * mu);
    row("wrong: Var(2 - X) = -Var(X) + 2", -v_def + 2.0);
    let big = [(0.0, 0.999), (1000.0, 0.001)];
    row("try: $1,000 prize, chance 0.001: var", var_definition(&big));
    row("try: $1,000 prize, chance 0.001: sd", sqrt(var_definition(&big)));
    row("try: $2 prize, chance 0.5: var", var_definition(&[(0.0, 0.5), (2.0, 0.5)]));
    row("chart, contribution of a loss", 0.99 * (0.0 - mu).powf(2.0));
    row("chart, contribution of a win", 0.01 * (100.0 - mu).powf(2.0));
    let f: Vec<f64> = [0.0, mu, 100.0, mu - sd, mu + sd].iter().map(|v| (v + 10.0) * 3.0).collect();
    println!("figure, x of $0 {:.2}, $1 {:.2}, $100 {:.2}, band {:.2} to {:.2}", f[0], f[1], f[2], f[3], f[4]);

    assert!((v_def - v_enum).abs() < 1e-9, "definition vs whole-number count");
    assert!((m_enum - mu).abs() < 1e-12, "mean vs whole-number count");
    assert!((v_short - v_enum).abs() < 1e-9, "shortcut vs whole-number count");
    assert!((var_shortcut(&[(0.0, 0.99), (200.0, 0.01)]) - enumerate_tickets(100, 2, 0).1).abs() < 1e-9, "shortcut, 2X");
    assert!((v_indicator - v_def).abs() < 1e-9, "indicator road vs definition");
    assert!((v_sim - v_enum).abs() < 4.0 * se_v, "simulation within four standard errors");
    assert!((sd * sd - v_enum).abs() < 1e-9, "Newton square root vs the count");
    println!("ALL CHECKS PASS");
}
