// Joint distributions and covariance -- the same check as the Python, in Rust,
// std only.  A street stall logs 100 days: X = 1 on a wet day, 0 on a dry day;
// Y = umbrellas sold that day.  Profit = $8 per umbrella minus a $5 canopy fee
// on each wet day.  Covariance is reached four ways, the profit variance two.
const COUNTS: [[u32; 4]; 2] = [[30, 20, 8, 2], [4, 8, 12, 16]];
const XS: [f64; 2] = [0.0, 1.0]; // the values of X (rows)
const YS: [f64; 4] = [0.0, 1.0, 2.0, 3.0]; // the values of Y (columns)
const N: usize = 100;
const PRICE: f64 = 8.0;
const FEE: f64 = 5.0;
const SEED: u64 = 2026;
const DRAWS: usize = 10000;

struct Moments { r: Vec<f64>, c: Vec<f64>, ex: f64, ey: f64, vx: f64, vy: f64, exy: f64, cov: f64 }

// road 1: margins, then E[XY] - E[X]E[Y]
fn moments(table: &[Vec<f64>], xs: &[f64], ys: &[f64]) -> Moments {
    let tot: f64 = table.iter().map(|row| row.iter().sum::<f64>()).sum();
    let p: Vec<Vec<f64>> = table.iter().map(|row| row.iter().map(|v| v / tot).collect()).collect();
    let (ni, nj) = (xs.len(), ys.len());
    let r: Vec<f64> = p.iter().map(|row| row.iter().sum()).collect();
    let c: Vec<f64> = (0..nj).map(|j| (0..ni).map(|i| p[i][j]).sum()).collect();
    let ex: f64 = (0..ni).map(|i| xs[i] * r[i]).sum();
    let ey: f64 = (0..nj).map(|j| ys[j] * c[j]).sum();
    let vx = (0..ni).map(|i| xs[i].powi(2) * r[i]).sum::<f64>() - ex * ex;
    let vy = (0..nj).map(|j| ys[j].powi(2) * c[j]).sum::<f64>() - ey * ey;
    let mut exy = 0.0;
    for i in 0..ni { for j in 0..nj { exy += xs[i] * ys[j] * p[i][j]; } }
    Moments { r, c, ex, ey, vx, vy, exy, cov: exy - ex * ey }
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    let table: Vec<Vec<f64>> = COUNTS.iter().map(|row| row.iter().map(|&v| v as f64).collect()).collect();
    let m = moments(&table, &XS, &YS);
    let (ex, ey, vx, vy, exy, cov) = (m.ex, m.ey, m.vx, m.vy, m.exy, m.cov);
    let (sx, sy) = (vx.sqrt(), vy.sqrt());
    let rho = cov / (sx * sy);
    let mut days: Vec<(f64, f64)> = Vec::new();
    for x in 0..2 { for y in 0..4 { for _ in 0..COUNTS[x][y] { days.push((x as f64, y as f64)); } } }
    let nf = N as f64;
    let mx = days.iter().map(|d| d.0).sum::<f64>() / nf; // road 2: the 100 days, centred
    let my = days.iter().map(|d| d.1).sum::<f64>() / nf;
    let cov_days = days.iter().map(|&(x, y)| (x - mx) * (y - my)).sum::<f64>() / nf;
    let avg = |row: usize| (0..4).map(|j| (j as u32 * COUNTS[row][j]) as f64).sum::<f64>()
        / COUNTS[row].iter().sum::<u32>() as f64;
    let (dry_avg, wet_avg) = (avg(0), avg(1));
    let cov_yesno = vx * (wet_avg - dry_avg); // road 3: a yes/no X
    let profit: Vec<f64> = days.iter().map(|&(x, y)| PRICE * y - FEE * x).collect();
    let pm = profit.iter().sum::<f64>() / nf;
    let var_days = profit.iter().map(|v| (v - pm).powi(2)).sum::<f64>() / nf;
    let var_formula = PRICE * PRICE * vy + FEE * FEE * vx - 2.0 * PRICE * FEE * cov;
    let var_no_cross = PRICE * PRICE * vy + FEE * FEE * vx;

    let mut rng = SplitMix(SEED); // road 4: SplitMix64 draws
    let sample: Vec<(f64, f64)> = (0..DRAWS)
        .map(|_| days[(((rng.next() >> 11) * N as u64) >> 53) as usize]).collect();
    let df = DRAWS as f64;
    let ax = sample.iter().map(|d| d.0).sum::<f64>() / df;
    let ay = sample.iter().map(|d| d.1).sum::<f64>() / df;
    let prods: Vec<f64> = sample.iter().map(|&(x, y)| (x - ax) * (y - ay)).collect();
    let cov_sim = prods.iter().sum::<f64>() / df;
    let se = (prods.iter().map(|q| (q - cov_sim).powi(2)).sum::<f64>() / (df - 1.0) / df).sqrt();

    let indep: Vec<Vec<f64>> = (0..2).map(|i| (0..4).map(|j| m.r[i] * m.c[j] * nf).collect()).collect();
    let mi = moments(&indep, &XS, &YS);
    let cov_indep = mi.cov;
    let var_indep = PRICE * PRICE * mi.vy + FEE * FEE * mi.vx - 2.0 * PRICE * FEE * cov_indep;
    // wind: rows W = -1, 0, +1; columns: upright, blown over (= W^2)
    let wind = vec![vec![0.0, 1.0], vec![1.0, 0.0], vec![0.0, 1.0]];
    let mw = moments(&wind, &[-1.0, 0.0, 1.0], &[0.0, 1.0]);
    let cov_wind = mw.cov;
    let both_calm = wind[1][0] / 3.0; // calm and upright: one day in three
    let calm_times_calm = mw.r[1] * mw.c[0]; // what independence would give
    let dz = moments(&table, &XS, &YS.map(|y| y / 12.0)); // Y counted in dozens
    let (dozens, rho_dz) = (dz.cov, dz.cov / (dz.vx * dz.vy).sqrt());

    println!("joint counts, dry row: {:?}  wet row: {:?}", COUNTS[0], COUNTS[1]);
    println!("margin of X (dry, wet): {:.2}, {:.2}", m.r[0], m.r[1]);
    let cs: Vec<String> = m.c.iter().map(|v| format!("{:.2}", v)).collect();
    println!("margin of Y (0,1,2,3 sold): {}", cs.join(", "));
    println!("E[X] = {:.4}   E[Y] = {:.4}   E[XY] = {:.4}", ex, ey, exy);
    println!("E[Y^2] = {:.4}   E[Y]^2 = {:.4}   E[X]E[Y] = {:.4}", vy + ey * ey, ey * ey, ex * ey);
    println!("Var(X) = {:.4}   Var(Y) = {:.4}", vx, vy);
    println!("sd(X) = {:.4}   sd(Y) = {:.4}", sx, sy);
    println!("covariance, road 1 (E[XY] - E[X]E[Y]):    {:.4}", cov);
    println!("covariance, road 2 (centred, 100 days):   {:.4}", cov_days);
    println!("average sold: dry days {:.4}, wet days {:.4}, gap {:.4}", dry_avg, wet_avg, wet_avg - dry_avg);
    println!("covariance, road 3 (Var(X) x gap):        {:.4}", cov_yesno);
    println!("covariance, road 4 (simulated, {} days, seed {}): {:.4}, standard error {:.4}", DRAWS, SEED, cov_sim, se);
    println!("correlation = {:.4}", rho);
    println!("profit: mean ${:.2}", pm);
    println!("profit variance, formula with cross term: {:.4}  (sd ${:.4})", var_formula, var_formula.sqrt());
    println!("profit variance, brute force over 100 days: {:.4}", var_days);
    println!("pieces: 64 Var(Y) = {:.4}, 25 Var(X) = {:.4}", PRICE * PRICE * vy, FEE * FEE * vx);
    println!("cross term 2 x 8 x (-5) x Cov = {:.4}", -2.0 * PRICE * FEE * cov);
    println!("mistake 1, cross term dropped: {:.4}  (sd ${:.4})", var_no_cross, var_no_cross.sqrt());
    println!("mistake 2, E[XY] read as covariance: {:.4}", exy);
    println!("mistake 3, wind: Cov(W, W^2) = {:.4}; P(calm and upright) = {:.4} vs product {:.4}",
             cov_wind, both_calm, calm_times_calm);
    println!("independent table (margins multiplied): Cov = {:.4}, profit variance {:.4}", cov_indep.abs(), var_indep);
    println!("Var(X/sd + Y/sd) = 2 + 2 rho = {:.4};  Var(X/sd - Y/sd) = 2 - 2 rho = {:.4}", 2.0 + 2.0 * rho, 2.0 - 2.0 * rho);
    println!("try: umbrellas in dozens: Cov = {:.4}, correlation {:.4}", dozens, rho_dz);
    println!("try: fee $5 as a rainy-day bonus: variance {:.4}", var_no_cross + 2.0 * PRICE * FEE * cov);
    println!("try: no fee at all: variance {:.4}", PRICE * PRICE * vy);
    let mut pl: Vec<(i64, u32)> = Vec::new();
    for x in 0..2 { for y in 0..4 { pl.push((8 * y as i64 - 5 * x as i64, COUNTS[x][y])); } }
    pl.sort();
    let bars: Vec<String> = pl.iter().map(|(v, k)| format!("{}: {}", v, k)).collect();
    println!("figure, profit bars ($: days): {}", bars.join(", "));
    let radii: Vec<String> = COUNTS.iter().flatten().map(|&k| format!("{:.1}", 3.0 * (k as f64).sqrt())).collect();
    println!("figure, disc radii 3 x sqrt(days): {}", radii.join(", "));
    assert!((cov - cov_days).abs() < 1e-12); // margins vs centred days
    assert!((cov - cov_yesno).abs() < 1e-12); // vs the yes/no gap
    assert!((var_formula - var_days).abs() < 1e-9); // formula vs brute force
    assert!((cov_sim - cov).abs() < 4.0 * se); // simulation, within 4 SE
    assert!(cov_indep.abs() < 1e-12); // independence -> zero
    assert!(cov_wind.abs() < 1e-12); // wind: zero covariance
    assert!(both_calm - calm_times_calm > 0.2); // ...yet dependent
    assert!((rho_dz - rho).abs() < 1e-12 && (12.0 * dozens - cov).abs() < 1e-12); // units: rho unchanged
    println!("ALL CHECKS PASS");
}
