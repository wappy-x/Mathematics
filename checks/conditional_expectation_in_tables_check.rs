// Conditional expectation on a claims table -- the check behind the card.
// Standard library only.  X is one claim's size in dollars, Y its region.  The
// table holds 100 claims' worth of counts, so each probability is a count / 100.
// Road 1 divides the table by P(region).  Road 2 walks a ledger of the 100
// claims with whole-number sums.  Road 3 draws claims with SplitMix64, seed 2026.
const SIZES: [f64; 3] = [1000.0, 5000.0, 20000.0];
const REGIONS: [&str; 3] = ["North", "Inland", "Coast"];
const COUNTS: [[u64; 3]; 3] = [[30, 15, 5], [15, 12, 3], [6, 6, 8]]; // rows: regions; columns: sizes
const N_TENTHS: [usize; 4] = [1, 3, 4, 2]; // P(N = 0) ... P(N = 3), in tenths
const N_LAW: [f64; 4] = [N_TENTHS[0] as f64 / 10.0, N_TENTHS[1] as f64 / 10.0, N_TENTHS[2] as f64 / 10.0, N_TENTHS[3] as f64 / 10.0];

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn below(state: &mut u64, n: u64) -> usize {
    // a whole number from 0 to n - 1
    let z = splitmix(state);
    (((z >> 11) as u128 * n as u128) >> 53) as usize
}

fn sqrt(v: f64) -> f64 {
    // Newton's method for a square root
    let mut r = if v > 1.0 { v } else { 1.0 };
    for _ in 0..60 {
        r = 0.5 * (r + v / r);
    }
    r
}

fn mean_and_se(s: f64, sq: f64, n: f64) -> (f64, f64) {
    // sample mean and its standard error
    let var = (sq - s * s / n) / (n - 1.0);
    (s / n, sqrt(var / n))
}

fn enum_total(law_for: &dyn Fn(usize) -> [f64; 3]) -> f64 {
    // E[S] by walking every month outcome
    let mut out = 0.0;
    for (k, pn) in N_LAW.iter().enumerate() {
        let mut combos: Vec<(f64, f64)> = vec![(1.0, 0.0)];
        let law = law_for(k);
        for _ in 0..k {
            combos = combos.iter().flat_map(|&(w, t)| (0..3).map(move |j| (w * law[j], t + SIZES[j]))).collect();
        }
        out += pn * combos.iter().map(|&(w, t)| w * t).sum::<f64>();
    }
    out
}

fn main() {
    let joint: [[f64; 3]; 3] = COUNTS.map(|row| row.map(|c| c as f64 / 100.0)); // P(X = x, Y = y)
    let p_y: Vec<f64> = joint.iter().map(|row| row.iter().sum()).collect(); // row sums
    let g: Vec<f64> = (0..3).map(|r| (0..3).map(|j| SIZES[j] * joint[r][j]).sum::<f64>() / p_y[r]).collect();
    let col: [f64; 3] = [0, 1, 2].map(|j| (0..3).map(|r| joint[r][j]).sum::<f64>()); // column sums
    let mut ledger: Vec<(usize, u64)> = Vec::new();
    for r in 0..3 {
        for j in 0..3 {
            for _ in 0..COUNTS[r][j] {
                ledger.push((r, SIZES[j] as u64));
            }
        }
    }

    println!("Conditional expectation on a claims table, dollars");
    let fmt = |v: &[f64]| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ");
    for r in 0..3 {
        println!("joint, {}, {}", REGIONS[r], fmt(&joint[r]));
    }
    println!("P(X = x) for 1000, 5000, 20000, {}", fmt(&col));
    println!("region, P(region), E[X | region] by division, by ledger");
    for r in 0..3 {
        let tot: u64 = ledger.iter().filter(|e| e.0 == r).map(|e| e.1).sum();
        let cnt = ledger.iter().filter(|e| e.0 == r).count() as u64;
        println!("{}, {:.2}, {:.2}, {:.2}", REGIONS[r], p_y[r], g[r], tot as f64 / cnt as f64);
        assert!((tot as f64 / cnt as f64 - g[r]).abs() < 1e-9, "table road and ledger road disagree");
    }
    let coast_law = [0, 1, 2].map(|j| joint[2][j] / p_y[2]); // P(X = x | Coast)
    println!("Coast weights given Coast, {}", fmt(&coast_law));
    println!("tower terms, {}", fmt(&(0..3).map(|r| p_y[r] * g[r]).collect::<Vec<f64>>()));
    let e_tower: f64 = (0..3).map(|r| p_y[r] * g[r]).sum();
    let e_col: f64 = (0..3).map(|j| SIZES[j] * col[j]).sum();
    let e_ledger = ledger.iter().map(|e| e.1).sum::<u64>() as f64 / ledger.len() as f64;
    println!("tower, sum of P(region) times E[X | region], {:.2}", e_tower);
    println!("column, sum of x times P(X = x), {:.2}", e_col);
    println!("ledger, grand average of 100 claims, {:.2}", e_ledger);
    assert!((e_tower - e_col).abs() < 1e-9, "tower rule fails against the column road");
    assert!((e_tower - e_ledger).abs() < 1e-9, "tower rule fails against the ledger road");

    let (mut st, n) = (2026u64, 200000u64);
    let (mut s, mut sq, mut cs, mut csq, mut cn) = (0u64, 0u64, 0u64, 0u64, 0u64);
    for _ in 0..n {
        let (r, x) = ledger[below(&mut st, 100)];
        s += x;
        sq += x * x;
        if r == 2 {
            cs += x;
            csq += x * x;
            cn += 1;
        }
    }
    let (m, se) = mean_and_se(s as f64, sq as f64, n as f64);
    println!("sim, {} claims, E[X] {:.2}, se {:.2}", n, m, se);
    let (cm, cse) = mean_and_se(cs as f64, csq as f64, cn as f64);
    println!("sim, {} Coast claims, E[X | Coast] {:.2}, se {:.2}", cn, cm, cse);
    assert!((m - e_col).abs() < 4.0 * se, "simulation misses E[X]");
    assert!((cm - g[2]).abs() < 4.0 * cse, "simulation misses E[X | Coast]");

    // E[(X - h(Y))^2] for a guess h per region
    let mse = |h: &[f64]| -> f64 { (0..9).map(|i| (SIZES[i % 3] - h[i / 3]).powi(2) * joint[i / 3][i % 3]).sum() };
    let total = (0..3).map(|j| SIZES[j] * SIZES[j] * col[j]).sum::<f64>() - e_col.powi(2);
    let within = mse(&g);
    let between: f64 = (0..3).map(|r| p_y[r] * (g[r] - e_col).powi(2)).sum();
    let flat = mse(&[e_col; 3]);
    println!("variance, total {:.2}, within {:.2}, between {:.2}", total, within, between);
    println!("best guess, squared error with region means {:.2}, with E[X] alone {:.2}", within, flat);
    let up = mse(&g.iter().map(|v| v + 500.0).collect::<Vec<f64>>());
    let down = mse(&g.iter().map(|v| v - 500.0).collect::<Vec<f64>>());
    println!("best guess, region means + 500 {:.2}, region means - 500 {:.2}", up, down);
    println!("best guess, extra error from a 500 shift {:.2}", up - within);
    println!("share of squared error removed by the region {:.2}", between / total);
    assert!((within + between - total).abs() < 1e-3, "variance does not split");
    assert!(within < up.min(down), "shifted region means beat the region means");
    assert!(within <= flat + 1e-6, "one flat guess beats the region means");

    let e_n: f64 = N_LAW.iter().enumerate().map(|(k, p)| k as f64 * p).sum();
    let plain = enum_total(&|_k| col);
    println!("P(N = n) for n = 0 to 3, {}", fmt(&N_LAW));
    println!("random sum, E[N] {:.2}, E[N] x E[X] {:.2}, enumeration {:.2}", e_n, e_n * e_col, plain);
    println!("E[S | N = n] for n = 0 to 3, {}", fmt(&[0.0, 1.0, 2.0, 3.0].map(|k| k * e_col)));
    assert!((plain - e_n * e_col).abs() < 1e-6, "random-sum shortcut fails");
    let (months, mut s, mut sq) = (100000u64, 0u64, 0u64);
    st = 7;
    for _ in 0..months {
        let u = below(&mut st, 10);
        let mut k = 0;
        while u >= N_TENTHS[..k + 1].iter().sum::<usize>() {
            k += 1;
        }
        let mut t = 0u64;
        for _ in 0..k {
            t += ledger[below(&mut st, 100)].1;
        }
        s += t;
        sq += t * t;
    }
    let (m, se) = mean_and_se(s as f64, sq as f64, months as f64);
    println!("random sum sim, {} months, E[S] {:.2}, se {:.2}", months, m, se);
    assert!((m - e_n * e_col).abs() < 4.0 * se, "random-sum simulation misses");

    let storm = enum_total(&|k| if k == 3 { coast_law } else { col });
    let storm_tower: f64 = N_LAW.iter().enumerate().map(|(k, p)| p * k as f64 * if k == 3 { g[2] } else { e_col }).sum();
    println!("breaks, equal weights on the region means {:.2}", g.iter().sum::<f64>() / 3.0);
    let unscaled: f64 = (0..3).map(|j| SIZES[j] * joint[2][j]).sum();
    println!("breaks, Coast row not divided by P(Coast) {:.2}", unscaled);
    println!("breaks, storm months: enumeration {:.2}, tower {:.2}, E[N] x E[X] {:.2}", storm, storm_tower, e_n * e_col);
    assert!((storm - storm_tower).abs() < 1e-6, "tower misses the storm enumeration");
    assert!((storm - e_n * e_col).abs() > 1.0, "storm case should break the shortcut");
    println!("figure, bars North {:.2}, Inland {:.2}, Coast {:.2}, line {:.2}", g[0], g[1], g[2], e_col);
    println!("All checks passed.");
}
