// Piecewise-flat hazard curve -- the same check as the Python, in Rust.  No
// crates.  A used van's breakdown hazard is 2% a year in year 1, 4% in years
// 2-3 and 6% in years 4-5.  Survival is reached four ways: e to the minus the
// area under the steps, a slice product with no exp in it, Simpson's rule on
// the default density, and 100,000 simulated vans flipping a monthly coin
// drawn from a hand-written random number generator.
const NODES: [f64; 4] = [0.0, 1.0, 3.0, 5.0]; // node dates, in years
const RATES: [f64; 3] = [0.02, 0.04, 0.06]; // the flat hazard on each piece, per year

fn rate(t: f64, rates: &[f64]) -> f64 {
    // the hazard at date t; the last rate runs on past year 5
    for i in 0..rates.len() - 1 {
        if t < NODES[i + 1] { return rates[i]; }
    }
    rates[rates.len() - 1]
}

fn area(t: f64, rates: &[f64]) -> f64 {
    // road 1: cumulative hazard, rate times overlap, piece by piece
    let mut total = 0.0;
    for (i, lam) in rates.iter().enumerate() {
        let lo = NODES[i];
        let hi = if i < rates.len() - 1 { NODES[i + 1] } else { 1e9 };
        if t > lo { total += lam * (t.min(hi) - lo); }
    }
    total
}

fn s(t: f64, rates: &[f64]) -> f64 { (-area(t, rates)).exp() } // survival to date t

fn slice_curve(per_year: usize, rates: &[f64]) -> Vec<f64> {
    // road 2: survive each thin slice in turn; no exp
    let dt = 1.0 / per_year as f64;
    let (mut p, mut out) = (1.0_f64, vec![1.0_f64]);
    for year in 0..5 {
        for k in 0..per_year {
            p *= 1.0 - rate(year as f64 + (k as f64 + 0.5) * dt, rates) * dt;
        }
        out.push(p);
    }
    out
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    // road 3: area under a smooth curve, parabola by parabola
    let h = (b - a) / n as f64;
    let mut sum = f(a) + f(b);
    for i in 1..n { sum += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    sum * h / 3.0
}

fn vans(n: usize, seed: u64) -> [u64; 5] {
    // road 4: monthly coin flips; no exp, no log
    let p: Vec<f64> = (0..60).map(|m| rate((m as f64 + 0.5) / 12.0, &RATES) / 12.0).collect();
    let (mut died, mut x) = ([0u64; 5], seed);
    for _ in 0..n {
        for m in 0..60 {
            x = x.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            if (x >> 11) as f64 / 9007199254740992.0 < p[m] {
                died[m / 12] += 1;
                break;
            }
        }
    }
    died
}

fn loglin(t: f64, a: f64, b: f64) -> f64 {
    // survival read between nodes a and b along a straight line in ln S
    let w = (t - a) / (b - a);
    ((1.0 - w) * s(a, &RATES).ln() + w * s(b, &RATES).ln()).exp()
}

fn linear(t: f64, a: f64, b: f64) -> f64 {
    // the mistake: a straight line in S itself
    let w = (t - a) / (b - a);
    (1.0 - w) * s(a, &RATES) + w * s(b, &RATES)
}

fn row(xs: &[f64], width: usize, prec: usize) -> String {
    xs.iter().map(|v| format!("{:w$.p$}", v, w = width, p = prec)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let surv: Vec<f64> = (0..6).map(|y| s(y as f64, &RATES)).collect();
    let slc = slice_curve(100000, &RATES);
    let died: Vec<f64> = (1..6).map(|y| surv[y - 1] - surv[y]).collect();
    let simp: Vec<f64> = (1..6)
        .map(|y| { let lam = rate(y as f64 - 1.0, &RATES); simpson(|t| lam * s(t, &RATES), y as f64 - 1.0, y as f64, 200) })
        .collect();
    let n_vans = 100000usize;
    let counts = vans(n_vans, 1);
    let mc: Vec<f64> = (0..6).map(|y| 1.0 - counts[..y].iter().sum::<u64>() as f64 / n_vans as f64).collect();
    let se5 = (mc[5] * (1.0 - mc[5]) / n_vans as f64).sqrt();
    let node_s: Vec<f64> = NODES.iter().map(|&t| s(t, &RATES)).collect();
    let avg: Vec<f64> = (1..4).map(|i| -node_s[i].ln() / NODES[i]).collect();
    let spot_from_s: Vec<f64> = (0..3).map(|i| -(node_s[i + 1] / node_s[i]).ln() / (NODES[i + 1] - NODES[i])).collect();
    let spot_from_avg: Vec<f64> = (0..3)
        .map(|i| (avg[i] * NODES[i + 1] - if i > 0 { avg[i - 1] * NODES[i] } else { 0.0 }) / (NODES[i + 1] - NODES[i]))
        .collect();

    println!("year  Lambda(t)  S(t)      S slices  avg rate  spot rate  died in yr  Simpson   vans");
    for y in 0..6usize {
        let yf = y as f64;
        if y == 0 {
            println!("{:>4}  {:.6}  {:.6}  {:.6}  {:>8}  {:>9}  {:>10}  {:>8}  {:.6}", y, area(yf, &RATES), surv[y], slc[y], "", "", "", "", mc[y]);
        } else {
            println!("{:>4}  {:.6}  {:.6}  {:.6}  {:.6}  {:.6}   {:.6}  {:.6}  {:.6}", y, area(yf, &RATES), surv[y], slc[y],
                     area(yf, &RATES) / yf, rate(yf - 0.5, &RATES), died[y - 1], simp[y - 1], mc[y]);
        }
    }
    let flat = [avg[2]; 3];
    let rev = [RATES[2], RATES[1], RATES[0]];
    let rows: Vec<(&str, f64)> = vec![
        ("vans: one standard error at 5 years", se5),
        ("default by 5, 1 - S(5)", 1.0 - surv[5]),
        ("year 4 given alive at 3, 1 - e^-0.06", 1.0 - s(4.0, &RATES) / s(3.0, &RATES)),
        ("vans: died in year 4", counts[3] as f64 / n_vans as f64),
        ("log-linear S(2) from S(1), S(3)", loglin(2.0, 1.0, 3.0)),
        ("log-linear S(4) from S(3), S(5)", loglin(4.0, 3.0, 5.0)),
        ("piece areas: 1", RATES[0] * (NODES[1] - NODES[0])), ("  2", RATES[1] * (NODES[2] - NODES[1])),
        ("  3", RATES[2] * (NODES[3] - NODES[2])),
        ("Lambda(2.5)", area(2.5, &RATES)), ("w at 2 years, from node 1 to node 3", (2.0 - 1.0) / (3.0 - 1.0)),
        ("S(2.5) on the curve", s(2.5, &RATES)),
        ("average rate to 1, 3, 5: 1", avg[0]), ("  3", avg[1]), ("  5", avg[2]),
        ("spots from node survivals: 1", spot_from_s[0]), ("  2", spot_from_s[1]), ("  3", spot_from_s[2]),
        ("spots from the averages: 1", spot_from_avg[0]), ("  2", spot_from_avg[1]), ("  3", spot_from_avg[2]),
        ("ageing: alive at 3, survives to 5", s(5.0, &RATES) / s(3.0, &RATES)),
        ("ageing: new van survives 2 years", s(2.0, &RATES)),
        ("wrong: linear S(2)", linear(2.0, 1.0, 3.0)),
        ("wrong: linear S(4)", linear(4.0, 3.0, 5.0)),
        ("wrong: year 5 hazard = 4.4% average, given alive", 1.0 - (-avg[2]).exp()),
        ("  right: 1 - e^-0.06", 1.0 - (-0.06_f64).exp()),
        ("wrong: died in year 4 = hazard", rate(3.5, &RATES)),
        ("try: flat 4.4%, S(5)", s(5.0, &flat)),
        ("try: flat 4.4%, died in year 1", 1.0 - s(1.0, &flat)),
        ("try: rates reversed, S(5)", s(5.0, &rev)),
        ("try: one slice a year, S(5)", slice_curve(1, &RATES)[5]),
        ("try: 6% held on, S(7)", s(7.0, &RATES)),
    ];
    for (name, v) in &rows { println!("{:<50} {:.6}", name, v); }
    let half: Vec<f64> = (0..11).map(|i| 0.5 * i as f64).collect();
    println!("chart, years           {}", row(&half, 5, 1));
    println!("chart, piecewise S(t)  {}", row(&half.iter().map(|&t| s(t, &RATES)).collect::<Vec<_>>(), 5, 2));
    println!("chart, flat 4.4% S(t)  {}", row(&half.iter().map(|&t| (-avg[2] * t).exp()).collect::<Vec<_>>(), 5, 2));
    println!("chart, spot % by year  {}", row(&(1..6).map(|y| 100.0 * rate(y as f64 - 0.5, &RATES)).collect::<Vec<_>>(), 5, 2));
    println!("chart, average % to yr {}", row(&(1..6).map(|y| 100.0 * area(y as f64, &RATES) / y as f64).collect::<Vec<_>>(), 5, 2));
    println!("bars, died in yr %     {}", row(&died.iter().map(|d| 100.0 * d).collect::<Vec<_>>(), 5, 2));

    assert!((0..6).all(|y| (slc[y] - surv[y]).abs() < 1e-6), "slice product must reach exp(-area)");
    assert!((0..5).all(|i| (simp[i] - died[i]).abs() < 1e-10), "density area must equal S(a) - S(b)");
    assert!((mc[5] - surv[5]).abs() < 4.0 * se5, "simulated vans within four standard errors");
    assert!([(1.5, 1.0, 3.0), (2.0, 1.0, 3.0), (2.5, 1.0, 3.0), (4.5, 3.0, 5.0)].iter().all(|&(t, a, b)| (loglin(t, a, b) - s(t, &RATES)).abs() < 1e-12), "log-linear = flat");
    assert!((0..3).all(|i| (spot_from_avg[i] - RATES[i]).abs() < 1e-12), "spots recovered from averages");
    assert!((surv[5] - 0.8025).abs() < 5e-5 && (surv[3] - 0.9048).abs() < 5e-5, "the card's hand-worked survivals");
    assert!((died[3] - 0.0527).abs() < 5e-5 && (s(7.0, &RATES) - 0.7118).abs() < 5e-5, "year-four deaths and the flat tail");
    println!("ALL CHECKS PASS");
}
