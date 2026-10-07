// Longstaff-Schwartz least-squares Monte Carlo -- the same check as the Python, in Rust.  No crates: the
// random numbers, the regression, the integral and the tree are written out here.  Four roads to the
// American put on Acme: this method over 100,000 futures; a 2,000-step tree on the same fifty exercise
// dates; that tree exercising at every step; and the European put.
use std::f64::consts::PI;
fn uniform(s: &mut u64) -> f64 {                  // 64-bit congruential generator, wrapping
    *s = s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
    ((*s >> 11) as f64) * (1.0 / 9007199254740992.0)
}
fn normal(s: &mut u64) -> f64 {                   // Box-Muller: two uniforms, one bell draw
    let mut u1 = uniform(s); if u1 == 0.0 { u1 = 1e-300 }
    (-2.0 * u1.ln()).sqrt() * (2.0 * PI * uniform(s)).cos()
}
fn euro_put(s0: f64, k0: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {  // average the payoff over
    let n = 40000usize; let h = 20.0 / n as f64; let mut total = 0.0;     // the bell curve, by
    for i in 0..=n {                                   // Simpson's rule: no d1, no d2, no N(x)
        let z = -10.0 + i as f64 * h; let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let bell = (-0.5 * z * z).exp() / (2.0 * PI).sqrt();          // bell-curve height at z
        total += w * bell * (k0 - s0 * ((r - q - 0.5 * sig * sig) * t + sig * t.sqrt() * z).exp()).max(0.0);
    } (-r * t).exp() * total * h / 3.0
}
fn fit(xs: &[f64], ys: &[f64], m: usize) -> Vec<f64> {   // least squares: the sums of powers that
    let mut mom = vec![0.0; 2 * m - 1]; let mut rhs = vec![0.0; 2 * m - 1];  // make up the normal
    for (x, y) in xs.iter().zip(ys.iter()) { let mut p = 1.0;    // equations, then Gaussian
        for k in 0..2 * m - 1 { mom[k] += p; rhs[k] += p * y; p *= x } }               // elimination
    let mut mm: Vec<Vec<f64>> = (0..m).map(|i| (0..=m).map(|j| if j < m { mom[i + j] } else { rhs[i] }).collect()).collect();
    for c in 0..m {
        let mut p = c; for k in c + 1..m { if mm[k][c].abs() > mm[p][c].abs() { p = k } } mm.swap(c, p);
        for k in c + 1..m { let f = mm[k][c] / mm[c][c];
            let row: Vec<f64> = (0..=m).map(|j| mm[k][j] - f * mm[c][j]).collect(); mm[k] = row }
    }
    let mut b = vec![0.0; m];
    for i in (0..m).rev() { let mut s = 0.0; for j in i + 1..m { s += mm[i][j] * b[j] } b[i] = (mm[i][m] - s) / mm[i][i] }
    b
}
// the fitted hold value at x = S / K, by Horner: b0 + x(b1 + x(b2 + x b3))
fn curve(b: &[f64], x: f64) -> f64 { let mut o = 0.0; for c in b.iter().rev() { o = o * x + c } o }
fn make_paths(s0: f64, r: f64, q: f64, sig: f64, t: f64, l: usize, n: usize, seed: u64) -> Vec<Vec<f64>> {
    let dt = t / l as f64; let mu = (r - q - 0.5 * sig * sig) * dt; let vol = sig * dt.sqrt();
    let mut s = seed; let mut out = Vec::with_capacity(n);   // one future at a time, date by date
    for _ in 0..n {
        let mut x = s0; let mut row = vec![x];
        for _ in 0..l { x *= (mu + vol * normal(&mut s)).exp(); row.push(x) } out.push(row);
    }
    out
}
fn lsm(p: &[Vec<f64>], k0: f64, r: f64, t: f64, l: usize, m: usize, peek: bool, onsight: bool,
       nodisc: bool, keep: usize, got: &mut (Vec<f64>, usize)) -> (f64, f64, Vec<usize>) {
    let n = p.len(); let disc = if nodisc { 1.0 } else { (-r * t / l as f64).exp() };
    let mut cash: Vec<f64> = p.iter().map(|row| (k0 - row[l]).max(0.0)).collect();
    let mut stop = vec![l; n];
    for k in (1..l).rev() {
        for i in 0..n { cash[i] *= disc }         // roll every future's money back one date
        let idx: Vec<usize> = (0..n).filter(|&i| p[i][k] < k0).collect();   // in the money
        if peek || onsight {                      // the two mistakes that fit nothing
            for &i in &idx { if onsight || k0 - p[i][k] > cash[i] { cash[i] = k0 - p[i][k]; stop[i] = k } }
            continue }
        if idx.len() <= m { continue }
        let xs: Vec<f64> = idx.iter().map(|&i| p[i][k] / k0).collect();
        let ys: Vec<f64> = idx.iter().map(|&i| cash[i]).collect();
        let b = fit(&xs, &ys, m); if k == keep { *got = (b.clone(), idx.len()) }
        for &i in &idx { if k0 - p[i][k] > curve(&b, p[i][k] / k0) { cash[i] = k0 - p[i][k]; stop[i] = k } }
    }
    let v: Vec<f64> = cash.iter().map(|c| c * disc).collect();
    let mean = v.iter().fold(0.0, |a, y| a + y) / n as f64;
    let var = v.iter().fold(0.0, |a, y| a + (y - mean) * (y - mean));
    (mean, (var / (n - 1) as f64 / n as f64).sqrt(), stop)
}
fn tree_put(s0: f64, k0: f64, r: f64, q: f64, sig: f64, t: f64, n: usize, every: usize,
            at: i64) -> (f64, f64) {              // exercise on rows that are multiples of `every`
    let dt = t / n as f64; let u = (sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let disc = (-r * dt).exp();
    let mut px: Vec<f64> = (0..=n).map(|k| s0 * u.powf(k as f64) * d.powf((n - k) as f64)).collect();
    let mut v: Vec<f64> = px.iter().map(|x| (k0 - x).max(0.0)).collect(); let mut front = 0.0_f64;
    for j in (0..n).rev() {
        let can = every > 0 && j > 0 && j % every == 0; let mut row = Vec::with_capacity(j + 1);
        for k in 0..=j {
            px[k] *= u; let mut c = disc * (p * v[k + 1] + (1.0 - p) * v[k]);
            if can && k0 - px[k] > c { c = k0 - px[k]; front = if j as i64 == at { front.max(px[k]) } else { front } }
            row.push(c);
        } v = row;
    }
    (v[0], front)
}
fn num(label: &str, v: f64) { println!("  {:<40}{:>12.6}", label, v) }
fn row(label: &str, vals: &[f64], w: usize, p: usize) {
    let mut s = String::from(label);                 // one printed row: a label then the values
    for v in vals { s.push_str(&format!("{:>w$.p$}", v, w = w, p = p)) } println!("{}", s) }
fn main() {
    let (s0, k0, r, q, sig, t) = (100.0_f64, 100.0_f64, 0.05_f64, 0.02_f64, 0.20_f64, 1.0_f64);
    println!("Acme: S = 100, K = 100, r = 5%, q = 2%, sigma = 20%, T = 1 year; an American put");
    let put_eu = euro_put(s0, k0, r, q, sig, t); num("European put, payoff averaged by Simpson", put_eu);
    println!("--- eight made-up futures for Acme, exercise at months 4, 8 and 12 ---");
    let toy: Vec<Vec<f64>> = vec![vec![100.0, 106.0, 112.0, 118.0], vec![100.0, 98.0, 94.0, 91.0],
        vec![100.0, 103.0, 99.0, 101.0], vec![100.0, 95.0, 101.0, 97.0], vec![100.0, 88.0, 90.0, 96.0],
        vec![100.0, 100.0, 96.0, 89.0], vec![100.0, 97.0, 93.0, 99.0], vec![100.0, 109.0, 104.0, 107.0]];
    let step = (-r / 3.0).exp();                  // one four-month discount factor
    for k in 1..4 { row(&format!("  Acme at month {:>2}      ", 4 * k),
                        &toy.iter().map(|p| p[k]).collect::<Vec<f64>>(), 7, 0) }
    let mut cash: Vec<f64> = toy.iter().map(|p| (k0 - p[3]).max(0.0)).collect();
    row("  cash at month 12        ", &cash, 7, 2);
    for k in [2usize, 1] {
        cash = cash.iter().map(|c| c * step).collect();
        let idx: Vec<usize> = (0..8).filter(|&i| toy[i][k] < k0).collect();
        let xs: Vec<f64> = idx.iter().map(|&i| toy[i][k] / k0).collect();
        let ys: Vec<f64> = idx.iter().map(|&i| cash[i]).collect();
        let (nn, mut sx, mut sxx, mut sy, mut sxy) = (idx.len() as f64, 0.0, 0.0, 0.0, 0.0);
        for (x, y) in xs.iter().zip(ys.iter()) { sx += x; sxx += x * x; sy += y; sxy += x * y }
        let det = nn * sxx - sx * sx;             // the two-term fit, in closed form
        let b0 = (sy * sxx - sx * sxy) / det; let b1 = (nn * sxy - sx * sy) / det;
        println!("  month {}: normal equations [{:.0} {:.4} | {:.4}] [{:.4} {:.4} | {:.4}]",
                 4 * k, nn, sx, sy, sx, sxx, sxy);
        println!("  month {}: fitted hold h(x) = {:.4} {:+.4} x,  x = S / 100", 4 * k, b0, b1);
        for (j, &i) in idx.iter().enumerate() {
            let h = b0 + b1 * xs[j]; let now = k0 - toy[i][k];
            println!("  month {}  future {}  Acme {:>5.0}  carried {:>7.4}  hold {:>7.4}  cash now {:>5.2}  -> {}",
                     4 * k, i + 1, toy[i][k], ys[j], h, now, if now > h { "take" } else { "hold" });
            if now > h { cash[i] = now }
        }
    }
    let toy_hand = cash.iter().fold(0.0, |a, c| a + c * step) / 8.0; let mut got = (vec![0.0; 3], 0usize);
    let toy_run = lsm(&toy, k0, r, 1.0, 3, 2, false, false, false, 0, &mut got).0;
    let toy_euro = toy.iter().fold(0.0, |a, p| a + (k0 - p[3]).max(0.0)) / 8.0 * (-r).exp();
    for (lb, v) in [("eight futures, by hand", toy_hand), ("eight futures, by the routine", toy_run),
        ("eight futures, no early exercise", toy_euro), ("eight futures, early-exercise premium", toy_hand - toy_euro)] { num(lb, v) }
    let (l, n, seed) = (50usize, 100000usize, 20260919u64);
    println!("--- {} simulated futures, {} exercise dates, three-term fit, in the money only ---", n, l);
    let pp = make_paths(s0, r, q, sig, t, l, n, seed);
    let eu: Vec<f64> = pp.iter().map(|p| (-r * t).exp() * (k0 - p[l]).max(0.0)).collect();
    let eu_mc = eu.iter().fold(0.0, |a, x| a + x) / n as f64;
    let ev = eu.iter().fold(0.0, |a, x| a + (x - eu_mc) * (x - eu_mc)); let eu_se = (ev / (n - 1) as f64 / n as f64).sqrt();
    let (price, se, stop) = lsm(&pp, k0, r, t, l, 3, false, false, false, 25, &mut got);
    let (b25, n25) = (got.0.clone(), got.1);   // the fit kept from date 25, six months in
    let early: Vec<usize> = stop.iter().copied().filter(|&s| s < l).collect();
    let (berm, front_berm) = tree_put(s0, k0, r, q, sig, t, 2000, 2000 / l, 1000);
    let (amer, front_amer) = tree_put(s0, k0, r, q, sig, t, 2000, 1, 1000);
    let mut cents = 0usize;                       // the highest price where cash now wins
    for i in 7200..=10000 { if k0 - i as f64 / 100.0 > curve(&b25, i as f64 / 100.0 / k0) { cents = i } }
    let front_fit = cents as f64 / 100.0;         // in cents, so both languages step alike
    println!("  {:<40}{:>12.6}  +/- {:.6}", "European put off the same futures", eu_mc, eu_se);
    println!("  {:<40}{:>12.6}  +/- {:.6}", "LSM American put", price, se);
    for (lb, v) in [("tree, the same fifty dates, 2,000 steps", berm), ("tree, exercise at every step", amer),
                    ("LSM minus the same-schedule tree", price - berm)] { num(lb, v) }
    let mdate = early.iter().fold(0usize, |a, s| a + s) as f64 / early.len() as f64 / l as f64;
    println!("  {:<40}{:>12.6}    {:.6} years", "exercised early: share, mean date", early.len() as f64 / n as f64, mdate);
    println!("  six-month fit, {} futures in money   h(x) = {:.4} {:+.4} x {:+.4} x^2", n25, b25[0], b25[1], b25[2]);
    println!("  {:<40}{:>12.2}    {:.2}    {:.2}", "take the cash below: fit, two trees", front_fit, front_berm, front_amer);
    println!("--- the same futures, with fewer or more terms in the fit ---");
    let mut run = |m: usize, pk: bool, os: bool, nd: bool| lsm(&pp, k0, r, t, l, m, pk, os, nd, 0, &mut got).0;
    let mut terms = vec![0.0; 5]; terms[3] = price;
    for (m, lb) in [(1usize, "1 term, a flat number"), (2, "2 terms, a line"), (3, "3 terms, a parabola"), (4, "4 terms, a cubic")] {
        if terms[m] == 0.0 { terms[m] = run(m, false, false, false) } num(lb, terms[m]) }
    println!("--- what breaks ---");
    for (lb, v) in [("peeking at each future's own outcome", run(3, true, false, false)),
                    ("exercising the moment it pays", run(3, false, true, false)),
                    ("no discounting between dates", run(3, false, false, true)),
                    ("fitted hold at 70, cash now 30.00", curve(&b25, 0.70))] { num(lb, v) }
    println!("--- the curve at six months, as drawn on the card ---");
    let grid: Vec<f64> = (0..7).map(|i| 75.0 + 5.0 * i as f64).collect();
    row("  Acme price                              ", &grid, 8, 0);
    row("  fitted hold value                       ", &grid.iter().map(|g| curve(&b25, g / k0)).collect::<Vec<f64>>(), 8, 2);
    row("  cash now, max(100 - S, 0)               ", &grid.iter().map(|g| (k0 - g).max(0.0)).collect::<Vec<f64>>(), 8, 2);
    assert!((toy_hand - toy_run).abs() < 1e-12 && toy_hand > toy_euro, "the hand road vs the routine");
    assert!((put_eu - 6.330080627550).abs() < 1e-6 && (eu_mc - put_eu).abs() < 3.0 * eu_se, "the house put");
    assert!(price < berm && berm - price < 0.10, "LSM sits just below the same-schedule tree");
    assert!(put_eu < price && price < amer && berm < amer, "European < LSM < Bermudan tree < American");
    assert!((front_fit - front_berm).abs() < 2.0 && terms[1] < terms[2] && terms[2] < terms[3], "boundary, terms");
    println!("ALL CHECKS PASS");
}
