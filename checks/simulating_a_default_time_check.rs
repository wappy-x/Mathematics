// Simulating a default time -- the same check as simulating_a_default_time_check.py, in Rust.
// Standard library only, no crates.  The uniform numbers come from the recurrence on
// the Monte Carlo card, the root finder is bisection written out, and every survival
// number is exp of minus an area.
const SEED: u64 = 20260914;
const PIECES: usize = 100000;
const MARKS: [usize; 7] = [1000, 2000, 5000, 10000, 20000, 50000, 100000];
const LAM: f64 = 0.02; // the game: 2% a round, flat
const NODES: [f64; 4] = [0.0, 1.0, 3.0, 5.0]; // the van: hazard flat between nodes
const RATES: [f64; 3] = [0.02, 0.04, 0.06]; // the last rate carries on past year 5
const R: f64 = 0.05; // Northwind: riskless rate
const REC: f64 = 40.0; // $ recovered per $100

fn uniform(state: &mut u64) -> f64 { // one step of the recurrence, whole numbers
    *state = (1664525 * *state + 1013904223) % (1u64 << 32);
    (*state as f64 + 0.5) / 4294967296.0 // strictly inside 0 and 1
}

fn seg_end(i: usize, rates: &[f64]) -> f64 {
    if i + 1 < rates.len() { NODES[i + 1] } else { f64::INFINITY }
}

fn area(t: f64, rates: &[f64]) -> f64 { // cumulative hazard: area under the steps up to t
    let mut total = 0.0;
    for (i, lam) in rates.iter().enumerate() {
        total += lam * (t.min(seg_end(i, rates)) - NODES[i]).max(0.0);
    }
    total
}

fn surv(t: f64, rates: &[f64]) -> f64 { (-area(t, rates)).exp() }

fn invert_steps(u: f64) -> (f64, usize, f64) { // road A: walk the steps until the area reaches -ln u
    let mut need = -u.ln();
    for (i, lam) in RATES.iter().enumerate() {
        let width = seg_end(i, &RATES) - NODES[i];
        if need <= lam * width { return (NODES[i] + need / lam, i, need); } // date, step, budget left
        need -= lam * width;
    }
    unreachable!()
}

fn invert_bisect(u: f64) -> f64 { // road B: solve S(t) = u by halving an interval
    let (mut lo, mut hi) = (0.0, 1000.0);
    for _ in 0..64 {
        let mid = 0.5 * (lo + hi);
        if surv(mid, &RATES) > u { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}

fn gone(times: &[f64], t: f64, n: usize) -> f64 {
    times[..n].iter().filter(|&&x| x <= t).count() as f64 / n as f64
}

fn se(p: f64, n: usize) -> f64 { (p * (1.0 - p) / n as f64).sqrt() }

fn main() {
    // ---- one uniform per piece, read off both curves ----
    let (mut state, mut flat, mut van, mut misfits) = (SEED, Vec::new(), Vec::new(), 0usize);
    for _ in 0..PIECES {
        let u = uniform(&mut state);
        flat.push(-u.ln() / LAM);
        van.push(invert_steps(u).0);
        if (van[van.len() - 1] - invert_bisect(u)).abs() > 1e-9 { misfits += 1; }
    }
    // ---- road C for the game: tick by tick, knocked out with chance rate x tick ----
    let mut tick_out = 0usize;
    for _ in 0..PIECES {
        for _ in 0..50 { // 50 ticks of 0.1 round
            if uniform(&mut state) < LAM * 0.1 { tick_out += 1; break; }
        }
    }
    let tick = tick_out as f64 / PIECES as f64;

    let (f_exact, f_sim) = (1.0 - (-LAM * 5.0).exp(), gone(&flat, 5.0, PIECES));
    let (v_exact, v_sim) = (1.0 - surv(5.0, &RATES), gone(&van, 5.0, PIECES));
    let life = flat.iter().sum::<f64>() / PIECES as f64;
    let pays: Vec<f64> = flat.iter()
        .map(|&x| if x <= 5.0 { REC * (-R * x).exp() } else { 100.0 * (-R * 5.0).exp() }).collect();
    let bond_draws = pays.iter().sum::<f64>() / PIECES as f64;
    let var = pays.iter().map(|p| (p - bond_draws).powi(2)).sum::<f64>() / (PIECES - 1) as f64;
    let bond_se = (var / PIECES as f64).sqrt();
    let bond_formula = 100.0 * (-(R + LAM) * 5.0).exp()
        + REC * LAM / (R + LAM) * (1.0 - (-(R + LAM) * 5.0).exp());
    println!("hand draws: U, -ln U, game round, van year");
    for u in [0.97_f64, 0.90, 0.85, 0.50] {
        let (tau, i, left) = invert_steps(u);
        println!("  U = {:.2}   -ln U {:.6}   game {:8.4}   van {:8.4} = {:.0} + {:.6} / {:.2} = {:.0} + {:.4}",
            u, -u.ln(), -u.ln() / LAM, tau, NODES[i], left, RATES[i], NODES[i], left / RATES[i]);
    }
    let three = |f: &dyn Fn(f64) -> f64| [1.0, 3.0, 5.0].iter().map(|&t| format!("{:.6}", f(t))).collect::<Vec<_>>().join(" ");
    println!("van: area at years 1, 3, 5     {}", three(&|t| area(t, &RATES)));
    println!("van: survival at years 1, 3, 5 {}", three(&|t| surv(t, &RATES)));
    let rows: Vec<(&str, f64)> = vec![
        ("game: % gone by round 5, formula", 100.0 * f_exact),
        ("game: % gone by round 5, inverted draws", 100.0 * f_sim),
        ("game: % gone by round 5, tick by tick", 100.0 * tick),
        ("game: gap, draws minus formula, % points", 100.0 * (f_sim - f_exact)),
        ("game: survival at round 5", (-LAM * 5.0).exp()),
        ("game: standard error, % points", 100.0 * se(f_sim, PIECES)),
        ("game: average lifetime, draws", life), ("game: average lifetime, 1/rate", 1.0 / LAM),
        ("van: % gone by year 5, formula", 100.0 * v_exact),
        ("van: % gone by year 5, inverted draws", 100.0 * v_sim),
        ("van: standard error, % points", 100.0 * se(v_sim, PIECES)),
        ("van: % of tickets dated past year 5", 100.0 * (1.0 - v_sim)),
        ("Northwind $100 in 5y, alive only, formula", 100.0 * (-R * 5.0).exp() * (-LAM * 5.0).exp()),
        ("Northwind $100 in 5y, alive only, draws", 100.0 * (-R * 5.0).exp() * (1.0 - f_sim)),
        ("Northwind, $40 at default date, draws", bond_draws),
        ("Northwind, $40 at default date, formula", bond_formula),
        ("Northwind, standard error of the draws", bond_se),
        ("wrong: rate times -ln U, % gone by 5",
            100.0 * flat.iter().filter(|&&x| x * LAM * LAM <= 5.0).count() as f64 / PIECES as f64),
        ("wrong: 2% per round as a coin, % gone", 100.0 * (1.0 - 0.98_f64.powi(5))),
        ("wrong: van at its average 4.4%, year-1 %", 100.0 * (1.0 - (-0.044_f64).exp())),
        ("  right: van year-1 %", 100.0 * (1.0 - surv(1.0, &RATES))),
        ("wrong: van at 6% throughout, % gone by 5", 100.0 * (1.0 - (-0.30_f64).exp())),
        ("try: van years 4-5 at 3%, % gone by 5", 100.0 * (1.0 - surv(5.0, &[0.02, 0.04, 0.03]))),
        ("try: 1,000 pieces, % gone by round 5", 100.0 * gone(&flat, 5.0, 1000)),
    ];
    for (name, v) in &rows { println!("{:<44} {:>10.4}", name, v); }
    println!("van: draws where steps and bisection split {:>6} of {}", misfits, PIECES);
    println!("van, year by year: % defaulting, draws vs formula");
    for y in 1..=5 {
        let yf = y as f64;
        let sim = gone(&van, yf, PIECES) - gone(&van, yf - 1.0, PIECES);
        let exact = surv(yf - 1.0, &RATES) - surv(yf, &RATES);
        println!("  year {}   draws {:6.2}   formula {:6.2}", y, 100.0 * sim, 100.0 * exact);
    }
    println!("chart, % alive at 0, 0.5, ..., 5 years");
    let half: Vec<f64> = (0..11).map(|i| 0.5 * i as f64).collect();
    let line = |f: &dyn Fn(f64) -> f64| half.iter().map(|&t| format!("{:6.2}", f(t))).collect::<Vec<_>>().join(" ");
    println!("  van formula {}", line(&|t| 100.0 * surv(t, &RATES)));
    println!("  van draws   {}", line(&|t| 100.0 * (1.0 - gone(&van, t, PIECES))));
    println!("  flat 2%     {}", line(&|t| 100.0 * (-LAM * t).exp()));
    println!("chart, game % gone by round 5 after n pieces");
    println!("  {}", MARKS.iter().map(|m| format!("{:>6}", m)).collect::<Vec<_>>().join(" "));
    println!("  {}", MARKS.iter().map(|&m| format!("{:6.2}", 100.0 * gone(&flat, 5.0, m))).collect::<Vec<_>>().join(" "));

    assert!((f_sim - f_exact).abs() < 4.0 * se(f_sim, PIECES), "inverted draws vs the flat formula");
    assert!((tick - f_exact).abs() < 4.0 * se(tick, PIECES), "tick-by-tick game vs the flat formula");
    assert!((v_sim - v_exact).abs() < 4.0 * se(v_sim, PIECES), "van draws vs e^-area");
    assert!((v_exact - (1.0 - (-(0.02 * 1.0 + 0.04 * 2.0 + 0.06 * 2.0_f64)).exp())).abs() < 1e-12, "area by the steps vs by hand");
    assert!(misfits == 0, "stepwise inversion vs bisection on S");
    assert!((life - 1.0 / LAM).abs() < 4.0 * (1.0 / LAM) / (PIECES as f64).sqrt(), "average lifetime vs 1/rate");
    assert!((bond_draws - bond_formula).abs() < 4.0 * bond_se, "priced by draws vs priced by formula");
    println!("ALL CHECKS PASS");
}
