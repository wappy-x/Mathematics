// Prices as geometric Brownian motion -- the same check as the Python, in Rust.  No crates,
// and nothing borrowed that already holds an answer: the bell curve's area, the percentiles,
// the random draws and the option price are built here.  Acme: 100 dollars, drift 5% a year,
// volatility 20% a year, one year ahead.
const S0: f64 = 100.0; const MU: f64 = 0.05; const SIG: f64 = 0.20; const T: f64 = 1.0;
const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;   // the shelf's market
const TWO_PI: f64 = 6.283185307179586;
const PATHS: usize = 20000; const STEPS: usize = 52; const NLAT: usize = 400;
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / TWO_PI.sqrt() }      // bell-curve height at z
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;                    // area under f from a to b, n panels
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn ncdf(x: f64) -> f64 {                           // bell-curve area to the left of x
    if x < -12.0 { return 0.0 }
    if x > 12.0 { return 1.0 }
    0.5 + simpson(phi, 0.0, x, 4000)
}
fn bisect<F: Fn(f64) -> f64>(f: F, lo0: f64, hi0: f64) -> f64 {     // crossing point of a rising f
    let (mut lo, mut hi) = (lo0, hi0);
    let mut flo = f(lo);
    for _ in 0..80 {
        let mid = 0.5 * (lo + hi);
        let fmid = f(mid);
        if flo * fmid <= 0.0 { hi = mid } else { lo = mid; flo = fmid }
    }
    0.5 * (lo + hi)
}
fn logdrift(mu: f64, sig: f64) -> f64 { mu - 0.5 * sig * sig }      // the log's own growth rate
fn mlog() -> f64 { logdrift(MU, SIG) * T }
fn slog() -> f64 { SIG * T.sqrt() }
fn median_of(mu: f64, sig: f64, t: f64) -> f64 { S0 * (logdrift(mu, sig) * t).exp() }
fn mean_of(mu: f64, t: f64) -> f64 { S0 * (mu * t).exp() }
fn quantile(sig: f64, t: f64, z: f64) -> f64 { S0 * (logdrift(MU, sig) * t + sig * t.sqrt() * z).exp() }
fn below(t: f64, level: f64) -> f64 { ncdf(((level / S0).ln() - logdrift(MU, SIG) * t) / (SIG * t.sqrt())) }
fn dens(x: f64) -> f64 { phi(((x / S0).ln() - mlog()) / slog()) / (x * slog()) }
struct Rng { s: u64 }                              // a 64-bit multiply-and-add generator
impl Rng {
    fn new(seed: u64) -> Rng { Rng { s: seed } }
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        (self.s >> 11) as f64 * (1.0 / 9007199254740992.0)
    }
    fn normal(&mut self) -> f64 {                  // Marsaglia's polar method, no trig
        loop {
            let u = 2.0 * self.uniform() - 1.0;
            let v = 2.0 * self.uniform() - 1.0;
            let q = u * u + v * v;
            if q > 0.0 && q < 1.0 { return u * (-2.0 * q.ln() / q).sqrt() }
        }
    }
}
fn walk(rng: &mut Rng, steps: usize, keep: usize) -> (Vec<f64>, f64) {
    let (a, b) = (logdrift(MU, SIG) * T / steps as f64, SIG * (T / steps as f64).sqrt());
    let (mut s, mut low, mut out) = (S0, S0, vec![S0]);      // one exact path, every keep'th price
    for i in 0..steps {
        s *= (a + b * rng.normal()).exp();
        if s < low { low = s }
        if (i + 1) % keep == 0 { out.push(s) }
    }
    (out, low)
}
fn row(name: &str, a: f64) { println!("{:<44}{:>14.6}", name, a); }
fn two(name: &str, a: f64, b: f64) { println!("{:<44}{:>14.6}{:>14.6}", name, a, b); }
fn grid(name: &str, vals: &[f64]) {
    let mut line = format!("{:<20}", name);
    for v in vals { line.push_str(&format!("{:>7.2}", v)); }
    println!("{}", line);
}
fn main() {
    let (m, s) = (logdrift(MU, SIG) * T, SIG * T.sqrt());        // road 1: the formulas
    let (med, mean) = (median_of(MU, SIG, T), mean_of(MU, T));
    let sd = (S0 * S0 * (2.0 * MU * T).exp() * ((SIG * SIG * T).exp() - 1.0)).sqrt();
    let z05 = bisect(|z| ncdf(z) - 0.05, -12.0, 12.0);
    let z95 = bisect(|z| ncdf(z) - 0.95, -12.0, 12.0);
    let (lo, hi) = (1e-9, 1000.0);                                // road 2: the density, in price space
    let mean_i = simpson(|x| x * dens(x), lo, hi, 4000);
    let med_i = bisect(|x| simpson(dens, lo, x, 2000) - 0.5, lo, hi);
    let below_i = simpson(dens, lo, K, 2000);
    let (x, dt) = (SIG * (T / NLAT as f64).sqrt(), T / NLAT as f64);  // road 3: up-or-down steps
    let p = 0.5 * (1.0 + logdrift(MU, SIG) * dt / x);
    let lat_mean = S0 * (p * x.exp() + (1.0 - p) * (-x).exp()).powf(NLAT as f64);
    let lat_spread = 2.0 * (NLAT as f64 * p * (1.0 - p)).sqrt() * x;
    let mut rng = Rng::new(20260919);                            // road 4: simulate the years
    let (mut ends, mut low): (Vec<f64>, f64) = (Vec::new(), S0);
    for _ in 0..PATHS {
        let (path, plow) = walk(&mut rng, STEPS, STEPS);
        ends.push(path[path.len() - 1]);
        low = low.min(plow);
    }
    let n = PATHS as f64;
    let mc_mean = ends.iter().sum::<f64>() / n;
    let mc_sd = (ends.iter().map(|e| (e - mc_mean) * (e - mc_mean)).sum::<f64>() / (n - 1.0)).sqrt();
    let mut order = ends.clone();
    order.sort_by(|a, b| a.total_cmp(b));
    let mc_med = 0.5 * (order[PATHS / 2 - 1] + order[PATHS / 2]);
    let logs: Vec<f64> = ends.iter().map(|e| (e / S0).ln()).collect();
    let mc_logmean = logs.iter().sum::<f64>() / n;
    let mc_logsd = (logs.iter().map(|v| (v - mc_logmean) * (v - mc_logmean)).sum::<f64>() / (n - 1.0)).sqrt();
    let mc_below = ends.iter().filter(|&&e| e < K).count() as f64 / n;
    let (se_mean, se_med) = (mc_sd / n.sqrt(), mc_med * s * TWO_PI.sqrt() / (2.0 * n.sqrt()));
    let fwd = S0 * ((R - Q) * T).exp();                          // the same law with the pricing drift
    let call = (-R * T).exp() * simpson(|z| (S0 * ((R - Q - 0.5 * SIG * SIG) * T + SIG * T.sqrt() * z).exp() - K).max(0.0) * phi(z), -10.0, 10.0, 40000);
    println!("Acme: {:.2} dollars today, drift 5% a year, volatility 20% a year, horizon 1 year", S0);
    println!("road 1, the formulas");
    println!("{:<38}{:>14.6}{:>14.6}{:>14.6}", "half variance, log drift, log spread", 0.5 * SIG * SIG * T, m, s);
    row("median  S0 e^((mu - sigma^2/2) T)", med);
    row("mean    S0 e^(mu T)", mean);
    two("mean / median, then e^(sigma^2 T / 2)", mean / med, (0.5 * SIG * SIG * T).exp());
    row("standard deviation of S_T", sd);
    row("mode, the peak of the density", S0 * ((MU - 1.5 * SIG * SIG) * T).exp());
    row("chance S_T lands below 100", below(T, K));
    two("5th and 95th percentile of S_T", quantile(SIG, T, z05), quantile(SIG, T, z95));
    two("the bell curve's own 5% and 95% points", z05, z95);
    println!("road 2, slices of the density added up in price space");
    row("mean", mean_i);
    row("median, the price with half the area below", med_i);
    row("chance S_T lands below 100", below_i);
    println!("road 3, {} multiplicative up-or-down steps", NLAT);
    row("mean", lat_mean);
    two("spread of the log return, then sigma sqrt(T)", lat_spread, s);
    println!("road 4, {} simulated years, {} steps each", PATHS, STEPS);
    two("mean, then three standard errors", mc_mean, 3.0 * se_mean);
    two("median, then three standard errors", mc_med, 3.0 * se_med);
    two("spread of the log return, then sigma sqrt(T)", mc_logsd, s);
    row("share of years landing below 100", mc_below);
    two("lowest tick, then years ending at or below 0", low, 0.0);
    println!("the shelf's market: the drift swapped for r - q = 3% a year");
    row("forward price, the mean of S_T", fwd);
    two("call by this law, then the shelf's price", call, 9.227005508154);
    println!("volatility drag at one year, mean {:.6} in every row", mean);
    for sg in [0.10, 0.20, 0.30, 0.40] {
        row(&format!("sigma {:.0}%   median", sg * 100.0), median_of(MU, sg, T));
    }
    grid("drag, mean - median", &[0.10, 0.20, 0.30, 0.40].map(|sg| mean - median_of(MU, sg, T)));
    println!("{:<20}{:>7}{:>7}{:>7}{:>7}{:>7}", "horizon", "median", "mean", "5th", "95th", "under%");
    for (t, name) in [(1.0 / 12.0, "1 month"), (1.0, "1 year"), (5.0, "5 years"), (10.0, "10 years")] {
        grid(name, &[median_of(MU, SIG, t), mean_of(MU, t), quantile(SIG, t, z05), quantile(SIG, t, z95), 100.0 * below(t, K)]);
    }
    let (one, _) = walk(&mut Rng::new(7), 252, 21);
    println!("chart 1, one simulated year of Acme, month 0 to month 12");
    grid("chart 1, price", &one);
    println!("chart 2, density x 1000, at prices 40 to 180 in tens");
    let prices: Vec<f64> = (0..15).map(|i| 40.0 + 10.0 * i as f64).collect();
    grid("chart 2, lognormal", &prices.iter().map(|&v| 1000.0 * dens(v)).collect::<Vec<f64>>());
    grid("chart 2, bell curve", &prices.iter().map(|&v| 1000.0 * phi((v - mean) / sd) / sd).collect::<Vec<f64>>());
    println!("chart 3, the fan, year 0 to year 10");
    for (name, z) in [("chart 3, 5th", z05), ("chart 3, median", 0.0), ("chart 3, 95th", z95)] {
        grid(name, &(0..11).map(|y| quantile(SIG, y as f64, z)).collect::<Vec<f64>>());
    }
    println!("what breaks if you drop a piece");
    two("drift as the middle, then the real middle", mean, med);
    two("+20% then -20% on 100, then its log drag", S0 * 1.20 * 0.80, 0.5 * (0.96_f64).ln());
    two("95th at four years with sigma T, then right", S0 * (m * 4.0 + SIG * 4.0 * z95).exp(), quantile(SIG, 4.0, z95));
    println!("{:<44}{:>14.9}", "a bell curve on the price, chance below zero", ncdf(-mean / sd));
    assert!((mean_i - mean).abs() < 1e-6, "the density's own mean must land on S0 e^(mu T)");
    assert!((med_i - med).abs() < 1e-6, "half the area below must land on S0 e^((mu - sigma^2/2) T)");
    assert!((below_i - below(T, K)).abs() < 1e-6, "two roads to the chance of ending below 100");
    assert!((lat_mean - mean).abs() < 0.02, "400 up-or-down steps must reach the same mean");
    assert!((lat_spread - s).abs() < 1e-3, "the lattice's log spread must be sigma sqrt(T)");
    assert!((mc_mean - mean).abs() < 3.0 * se_mean, "the simulated mean, inside three standard errors");
    assert!((mc_med - med).abs() < 3.0 * se_med, "the simulated median, inside three standard errors");
    assert!((call - 9.227005508154).abs() < 1e-6, "this law prices the shelf's call");
    assert!(low > 0.0 && order[0] > 0.0, "no simulated price ever reaches zero");
    assert!(mean - med > 2.0, "the mean must sit clearly above the median");
    println!("ALL CHECKS PASS");
}
