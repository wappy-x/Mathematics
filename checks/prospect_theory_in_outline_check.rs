// Prospect theory in outline -- the check behind the card.  Rust std only.
// Parameters are Tversky and Kahneman's 1992 median estimates.  The normal CDF, its
// inverse, Simpson's rule and the root finder are written out; nothing imported knows the answer.
const A: f64 = 0.88; const LAM: f64 = 2.25; const GP: f64 = 0.61; const GM: f64 = 0.69;

fn v(x: f64, lam: f64) -> f64 { if x >= 0.0 { x.powf(A) } else { -lam * (-x).powf(A) } }

fn w(p: f64, g: f64) -> f64 {
    if p <= 0.0 { return 0.0; }
    if p >= 1.0 { return 1.0; }
    p.powf(g) / (p.powf(g) + (1.0 - p).powf(g)).powf(1.0 / g)
}

// road 2: rank the tickets, weight cumulative chances
fn cpt(t: &[(f64, f64)], lam: f64, gp: f64, gm: f64) -> f64 {
    let mut gains: Vec<(f64, f64)> = t.iter().cloned().filter(|a| a.0 > 0.0).collect();
    let mut losses: Vec<(f64, f64)> = t.iter().cloned().filter(|a| a.0 < 0.0).collect();
    gains.sort_by(|a, b| b.0.partial_cmp(&a.0).unwrap());
    losses.sort_by(|a, b| a.0.partial_cmp(&b.0).unwrap());
    let mut total = 0.0;
    for (side, g) in [(&gains, gp), (&losses, gm)] {
        let mut cum = 0.0; // chance of doing at least this well (gains) or this badly
        for &(x, p) in side.iter() {
            total += (w(cum + p, g) - w(cum, g)) * v(x, lam);
            cum += p;
        }
    }
    total
}
fn cpt0(t: &[(f64, f64)]) -> f64 { cpt(t, LAM, GP, GM) }

// the prospect "x with chance p, else 0" as n equal tickets
fn tickets(x: f64, p: f64, n: usize) -> Vec<(f64, f64)> {
    let k = (p * n as f64).round() as usize;
    let mut t = vec![(x, 1.0 / n as f64); k];
    t.extend(vec![(0.0, 1.0 / n as f64); n - k]);
    t
}

fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt() }
// normal CDF by Marsaglia's all-positive series
fn big_phi(z: f64) -> f64 {
    if z < -9.0 { return 0.0; }
    if z > 9.0 { return 1.0; }
    let (mut s, mut term, mut n) = (z, z, 1.0);
    while term.abs() > 1e-17 * s.abs() + 1e-300 {
        term *= z * z / (2.0 * n + 1.0); s += term; n += 1.0;
    }
    0.5 + phi(z) * s
}
// root of an increasing f between lo and hi
fn bisect<F: Fn(f64) -> f64>(f: F, mut lo: f64, mut hi: f64, it: usize) -> f64 {
    for _ in 0..it {
        let mid = 0.5 * (lo + hi);
        if f(mid) < 0.0 { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
// road 1: weighted tails, integrated
fn fund_simpson(m: f64, s: f64, lam: f64, gp: f64, gm: f64) -> f64 {
    let top = v(m + 10.0 * s, LAM);
    let gain = simpson(|y| w(1.0 - big_phi((y.powf(1.0 / A) - m) / s), gp), 0.0, top, 4000);
    let loss = simpson(|y| w(big_phi((-y.powf(1.0 / A) - m) / s), gm), 0.0, top, 4000);
    gain - lam * loss
}
// road 2: n equally likely quantiles
fn fund_tickets(m: f64, s: f64, n: usize) -> f64 {
    let t: Vec<(f64, f64)> = (1..=n).map(|k| {
        let u = (k as f64 - 0.5) / n as f64;
        (m + s * bisect(|z| big_phi(z) - u, -10.0, 10.0, 60), 1.0 / n as f64)
    }).collect();
    cpt0(&t)
}
// sure dollars with value V
fn ce(val: f64) -> f64 { if val >= 0.0 { val.powf(1.0 / A) } else { -(-val / LAM).powf(1.0 / A) } }

fn main() {
    // ---- the four classic menus (Kahneman and Tversky 1979, problems 3, 4, 3', 4') ----
    let menus = [("sure +3000", 3000.0, 1.0), ("80% of +4000", 4000.0, 0.8), ("20% of +4000", 4000.0, 0.2),
        ("25% of +3000", 3000.0, 0.25), ("sure -3000", -3000.0, 1.0), ("80% of -4000", -4000.0, 0.8),
        ("20% of -4000", -4000.0, 0.2), ("25% of -3000", -3000.0, 0.25)];
    let mut r1 = Vec::new(); let mut r2 = Vec::new();
    println!("inputs: A 0.88, lambda 2.25, gamma 0.61, delta 0.69; fund $10000, mean 8% (+$800), spread 15% ($1500); deposit 4% (+$400)");
    println!("1979 majorities (percent, N = 95): problem 3 80, problem 4 65, problem 3' 92, problem 4' 58");
    println!("{:<22}{:>14}{:>14}", "menu", "formula", "20 tickets");
    for &(name, x, p) in menus.iter() {
        let a = w(p, if x > 0.0 { GP } else { GM }) * v(x, LAM); // road 1: the binary formula
        let b = cpt0(&tickets(x, p, 20));                        // road 2: twenty ranked tickets
        println!("{:<22}{:>14.6}{:>14.6}", name, a, b);
        r1.push(a); r2.push(b);
    }
    let ratio = 0.75f64.powf(A); // v(3000)/v(4000) = (3/4)^A
    let coin = bisect(|x| cpt0(&[(x, 0.5), (-100.0, 0.5)]), 100.0, 1000.0, 100);
    let coin_closed = 100.0 * (LAM * w(0.5, GM) / w(0.5, GP)).powf(1.0 / A);
    let f1 = fund_simpson(800.0, 1500.0, LAM, GP, GM);
    let f2 = fund_tickets(800.0, 1500.0, 20000);
    let rows: Vec<(&str, f64)> = vec![
        ("expected dollars, 80% of +4000", 0.8 * 4000.0), ("v(3000)", v(3000.0, LAM)), ("v(4000)", v(4000.0, LAM)), ("(3/4)^0.88", ratio),
        ("w+(0.20)", w(0.2, GP)), ("w+(0.25)", w(0.25, GP)), ("w-(0.20)", w(0.2, GM)), ("w-(0.25)", w(0.25, GM)),
        ("w+(0.80)", w(0.8, GP)), ("w+(0.20)/w+(0.25)", w(0.2, GP) / w(0.25, GP)),
        ("w-(0.80)", w(0.8, GM)), ("w-(0.20)/w-(0.25)", w(0.2, GM) / w(0.25, GM)),
        ("w+(0.50)", w(0.5, GP)), ("w-(0.50)", w(0.5, GM)),
        ("coin: heads needed, bisection", coin), ("coin: heads needed, closed form", coin_closed),
        ("coin: no weighting", 100.0 * LAM.powf(1.0 / A)), ("coin: straight lines", 100.0 * LAM),
        ("fund: Simpson on tails", f1), ("fund: 20000 tickets", f2),
        ("fund: chance of a loss", big_phi(-800.0 / 1500.0)), ("fund: sure-dollar equal", ce(f1)),
        ("deposit: v(400)", v(400.0, LAM)),
        ("wrong: no weights, 80% of +4000", 0.8 * v(4000.0, LAM)),
        ("wrong: no weights, 20% of +4000", 0.2 * v(4000.0, LAM)),
        ("wrong: no weights, 25% of +3000", 0.25 * v(3000.0, LAM)),
        ("wrong: 16 ticket weights, total", 16.0 * w(0.05, GP)),
        ("wrong: 16 tickets weighted apart", 16.0 * w(0.05, GP) * v(4000.0, LAM)),
        ("wrong: coin with no loss multiplier", 100.0 * (w(0.5, GM) / w(0.5, GP)).powf(1.0 / A)),
        ("try: fund, multiplier 1", fund_simpson(800.0, 1500.0, 1.0, GP, GM).powf(1.0 / A)),
        ("try: fund against the deposit", ce(fund_simpson(400.0, 1500.0, LAM, GP, GM))),
        ("try: fund, spread 10%", ce(fund_simpson(800.0, 1000.0, LAM, GP, GM))),
        ("try: fund, no weighting", ce(fund_simpson(800.0, 1500.0, LAM, 1.0, 1.0))),
    ];
    for (name, val) in rows.iter() { println!("{:<36}{:>14.6}", name, val); }
    // ---- chart points ----
    let xs: Vec<f64> = (0..9).map(|i| -1000.0 + 250.0 * i as f64).collect();
    let ps = [0.0, 0.05, 0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 0.95, 1.0];
    let join = |v: Vec<String>| v.join(" ");
    println!("chart x ($)   {}", join(xs.iter().map(|x| format!("{:>8}", *x as i64)).collect()));
    println!("chart v(x)    {}", join(xs.iter().map(|x| format!("{:>8.2}", v(*x, LAM))).collect()));
    println!("chart p       {}", join(ps.iter().map(|p| format!("{:>5.2}", p)).collect()));
    println!("chart w+(p)   {}", join(ps.iter().map(|p| format!("{:>5.2}", w(*p, GP))).collect()));
    println!("chart w-(p)   {}", join(ps.iter().map(|p| format!("{:>5.2}", w(*p, GM))).collect()));

    assert!(r1[0] > r1[1] && r1[2] > r1[3], "gain reversal");
    assert!(r1[5] > r1[4] && r1[7] > r1[6], "loss reflection");
    assert!(r1.iter().zip(r2.iter()).all(|(a, b)| (a - b).abs() < 1e-9), "formula vs ranked tickets");
    assert!(w(0.8, GP) < ratio && ratio < w(0.2, GP) / w(0.25, GP), "the reversal's bracket condition");
    assert!((coin - coin_closed).abs() < 1e-6, "bisection vs closed-form break-even");
    assert!((f1 - f2).abs() < 0.05, "fund: integral vs quantile tickets");
    assert!(f1 < v(400.0, LAM), "the deposit outscores the fund");
    assert!(0.8 * v(4000.0, LAM) > v(3000.0, LAM), "without weights the certainty effect vanishes");
    println!("ALL CHECKS PASS");
}
