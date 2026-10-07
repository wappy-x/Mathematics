// Minimum-variance hedge ratio -- the check behind the card.  std only, no crates.
// Jet fuel bought in three months, hedged with heating oil futures.  Prices in dollars
// per gallon; S_S, S_F = spread (standard deviation) of the three-month price changes.
const S_S: f64 = 0.18;
const S_F: f64 = 0.20;
const RHO: f64 = 0.943;
const Q: f64 = 2_000_000.0;
const LOT: f64 = 42_000.0;

fn var_hedged(h: f64) -> f64 { S_S * S_S - 2.0 * h * RHO * S_S * S_F + h * h * S_F * S_F }

fn grid_min<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, step: f64) -> f64 {
    let n = ((hi - lo) / step).round() as usize;
    let (mut best_h, mut best_v) = (lo, f(lo));
    for i in 1..=n {
        let h = lo + i as f64 * step;
        let v = f(h);
        if v < best_v { best_h = h; best_v = v; }
    }
    best_h
}

struct Rng { x: u64 }
impl Rng {
    fn u(&mut self) -> f64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.x;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let r = (-2.0 * self.u().ln()).sqrt();
        r * (2.0 * std::f64::consts::PI * self.u()).cos()
    }
}

fn draws(seed: u64, n: usize) -> Vec<(f64, f64)> {
    let mut g = Rng { x: seed };
    (0..n).map(|_| {
        let z1 = g.normal();
        let z2 = g.normal();
        (S_S * (RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2), S_F * z1)
    }).collect()
}

// least squares of dS on dF: slope, R^2, residual spread, slope's standard error
fn ols(d: &[(f64, f64)]) -> (f64, f64, f64, f64) {
    let n = d.len() as f64;
    let ms = d.iter().map(|p| p.0).sum::<f64>() / n;
    let mf = d.iter().map(|p| p.1).sum::<f64>() / n;
    let (mut sxx, mut syy, mut sxy) = (0.0, 0.0, 0.0);
    for &(s, f) in d {
        sxx += (f - mf) * (f - mf);
        syy += (s - ms) * (s - ms);
        sxy += (f - mf) * (s - ms);
    }
    let b = sxy / sxx;
    let ssr = syy - b * sxy;
    (b, 1.0 - ssr / syy, (ssr / (n - 1.0)).sqrt(), (ssr / (n - 2.0) / sxx).sqrt())
}

fn sample_var(d: &[(f64, f64)], h: f64) -> f64 {
    let xs: Vec<f64> = d.iter().map(|&(s, f)| s - h * f).collect();
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() as f64 - 1.0)
}

fn main() {
    // road 1: the formula.  road 2: brute-force grid on the variance
    let h_star = RHO * S_S / S_F;
    let h_grid = grid_min(var_hedged, 0.0, 1.5, 1e-4);
    let resid = S_S * (1.0 - RHO * RHO).sqrt();
    // road 3: regression on 200,000 simulated quarters.  road 4: grid on the same sample
    let mc = draws(20260928, 200_000);
    let (b_mc, r2_mc, res_mc, _) = ols(&mc);
    let sub = &mc[..20_000];
    let h_sub_ols = ols(sub).0;
    let h_sub_grid = grid_min(|h| sample_var(sub, h), 0.7, 1.0, 1e-4);
    // a short history: 40 quarters, as a desk would actually have
    let (b_40, r2_40, _, se_40) = ols(&draws(7, 40));

    let n_exact = h_star * Q / LOT;
    let n = n_exact.round();
    let h_used = n * LOT / Q;
    let res_used = var_hedged(h_used).sqrt();

    let rows: Vec<(&str, f64, usize)> = vec![
        ("1 formula  rho sS / sF", h_star, 6), ("2 grid minimum of variance", h_grid, 6),
        ("3 regression, 200,000 quarters", b_mc, 6), ("4 grid on 20,000 quarters", h_sub_grid, 6),
        ("  regression, same 20,000", h_sub_ols, 6),
        ("covariance  rho sS sF", RHO * S_S * S_F, 6), ("1 - rho^2", 1.0 - RHO * RHO, 6),
        ("sqrt(1 - rho^2)", (1.0 - RHO * RHO).sqrt(), 6), ("unhedged spread, $/gal", S_S, 6), ("residual spread  sS sqrt(1-rho^2)", resid, 6),
        ("  simulated residual spread", res_mc, 6), ("spread cut, fraction", 1.0 - resid / S_S, 6),
        ("variance cut  rho^2", RHO * RHO, 6), ("  simulated R^2", r2_mc, 6),
        ("contracts, exact  h Q / LOT", n_exact, 4), ("contracts, rounded", n, 0),
        ("hedge ratio actually held", h_used, 4), ("residual spread at 40 contracts", res_used, 6),
        ("unhedged spread, $ on 2m gal", S_S * Q, 2), ("hedged spread, $ on 2m gal", res_used * Q, 2),
        ("40 quarters: slope", b_40, 4), ("40 quarters: std error of slope", se_40, 4),
        ("40 quarters: R^2", r2_40, 4), ("40 quarters: two std errors", 2.0 * se_40, 4),
        ("gap, road 3 minus road 1", b_mc - h_star, 6),
        ("basis-change spread (h = 1)", var_hedged(1.0).sqrt(), 6),
        ("penalty check  resid^2 + sF^2 (1-h*)^2",
         (resid * resid + S_F * S_F * (1.0 - h_star) * (1.0 - h_star)).sqrt(), 6),
        ("wrong: sign flipped, h = -h*, spread", var_hedged(-h_star).sqrt(), 6),
        ("wrong: h = rho, spread", var_hedged(RHO).sqrt(), 6),
        ("wrong: h = sS / sF, spread", var_hedged(S_S / S_F).sqrt(), 6),
        ("wrong: reversed regression h", RHO * S_F / S_S, 6),
        ("  its spread", var_hedged(RHO * S_F / S_S).sqrt(), 6),
        ("story: futures gain per gal, 2.50 to 2.90", h_used * (2.90 - 2.50), 4),
        ("story: net cost per gal, jet 2.40 to 2.75", 2.75 - h_used * (2.90 - 2.50), 4),
        ("story: net cost minus today's 2.40", 2.75 - h_used * (2.90 - 2.50) - 2.40, 4),
        ("beta hedge: 1.2 x 10,000,000 / 250,000", 1.2 * 10_000_000.0 / 250_000.0, 2),
        ("try: rho = 0.8, hedge ratio", 0.8 * S_S / S_F, 4), ("try: sF = 0.40, hedge ratio", RHO * S_S / 0.40, 4),
        ("try: 400 quarters, std error of slope", ols(&draws(7, 400)).3, 4),
        ("try: 48 contracts, ratio held", 48.0 * LOT / Q, 4),
        ("try: 48 contracts, spread", var_hedged(48.0 * LOT / Q).sqrt(), 6),
    ];
    for (lab, v, d) in &rows { println!("{:<42}{:>16.*}", lab, *d, v); }

    let hs: [f64; 8] = [0.0, 0.25, 0.5, 0.75, 0.85, 1.0, 1.25, 1.5];
    let row = |v: Vec<String>| v.concat();
    println!("chart, hedge ratio      {}", row(hs.iter().map(|h| format!("{:>7.2}", h)).collect()));
    println!("chart, spread in cents  {}", row(hs.iter().map(|&h| format!("{:>7.2}", 100.0 * var_hedged(h).sqrt())).collect()));
    let rs: [f64; 7] = [0.5, 0.7, 0.8, 0.9, 0.943, 0.97, 0.99];
    println!("chart, correlation      {}", row(rs.iter().map(|r| format!("{:>7.3}", r)).collect()));
    println!("chart, spread cut, %    {}", row(rs.iter().map(|&r| format!("{:>7.2}", 100.0 * (1.0 - (1.0 - r * r).sqrt()))).collect()));

    assert!((h_grid - h_star).abs() < 1e-4, "grid disagrees with the formula");
    assert!((b_mc - h_star).abs() < 0.005, "simulated regression disagrees with the formula");
    assert!((h_sub_grid - h_sub_ols).abs() < 1e-4, "least squares is not the minimum-variance hedge");
    assert!((res_mc - resid).abs() < 0.001, "simulated residual spread disagrees");
    assert!((sample_var(&mc, 1.0).sqrt() - var_hedged(1.0).sqrt()).abs() < 0.001, "h = 1 spread disagrees");
    println!("ALL CHECKS PASS");
}
