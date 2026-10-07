// Lognormal distribution -- the check behind the card.  Rust std only.
// A share at $50 today.  Its log return over the year, X = ln(S/S0), is
// normal with centre MU = 0.08 and spread SIGMA = 0.30, so the price in a
// year is S = S0 e^X.  Roads: the closed forms; Simpson's rule on the
// density; a seeded simulation of 200,000 years; an exact enumeration of a
// 252-day coin-flip year.  Nothing imported holds the answer.
use std::f64::consts::PI;

const S0: f64 = 50.0;
const MU: f64 = 0.08;
const SIGMA: f64 = 0.30;
const DAYS: usize = 252;

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }

fn big_phi(z: f64) -> f64 {                  // standard normal area, Taylor series
    let (mut term, mut total) = (z, z);
    for n in 1..200 {
        let n = n as f64;
        term *= -z * z / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn f(s: f64) -> f64 { phi(((s / S0).ln() - MU) / SIGMA) / (SIGMA * s) }

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 40000;
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n {
        acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h);
    }
    (g(a) + g(b) + acc) * h / 3.0
}

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {                // SplitMix64
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn normal_pair(&mut self) -> (f64, f64) {  // Marsaglia polar method
        loop {
            let (u, v) = (2.0 * self.uniform() - 1.0, 2.0 * self.uniform() - 1.0);
            let q = u * u + v * v;
            if q > 0.0 && q < 1.0 {
                let k = (-2.0 * q.ln() / q).sqrt();
                return (u * k, v * k);
            }
        }
    }
}

fn main() {
    // road 1: the closed forms
    let (median, mean, mode) = (S0 * MU.exp(), S0 * (MU + SIGMA * SIGMA / 2.0).exp(), S0 * (MU - SIGMA * SIGMA).exp());
    let var = mean * mean * ((SIGMA * SIGMA).exp() - 1.0);
    let sd = var.sqrt();
    let p_loss = big_phi((1.0f64.ln() - MU) / SIGMA);
    let p_below_mean = big_phi(SIGMA / 2.0);
    println!("model: S0 = {:.2}, log return centre {:.2}, spread {:.2}", S0, MU, SIGMA);
    println!("formula: mode {:.4}, median {:.4}, mean {:.4}", mode, median, mean);
    println!("formula: variance {:.4}, spread of price {:.4}", var, sd);
    println!("formula: P(S < 50) = {:.4}, P(S < mean) = {:.4}", p_loss, p_below_mean);
    println!("by hand: e^0.08 = {:.4}, e^0.125 = {:.4}, e^-0.01 = {:.4}, e^0.09 - 1 = {:.4}, z for $50 = {:.4}",
             MU.exp(), (MU + SIGMA * SIGMA / 2.0).exp(), (MU - SIGMA * SIGMA).exp(), (SIGMA * SIGMA).exp() - 1.0, -MU / SIGMA);
    println!("by hand: sigma^2/2 = {:.4}, mean^2 = {:.2}, mean / median = {:.4}, mean - median = {:.4}",
             SIGMA * SIGMA / 2.0, mean * mean, mean / median, mean - median);
    println!("average simple return {:.4}; average log return {:.4}", mean / S0 - 1.0, MU);

    // road 2: Simpson's rule on the density itself, no moment formula used
    let (lo, hi) = (0.01, 1200.0);
    let area = simpson(&f, lo, hi);
    let mean_i = simpson(&|s: f64| s * f(s), lo, hi);
    let var_i = simpson(&|s: f64| (s - mean_i) * (s - mean_i) * f(s), lo, hi);
    let p_loss_i = simpson(&f, lo, S0);
    let p_below_mean_i = simpson(&f, lo, mean);
    let mut mode_i = 40.0;
    for i in 0..=20000 {                       // density peak searched on a $0.001 grid
        let s = 40.0 + i as f64 * 0.001;
        if f(s) > f(mode_i) { mode_i = s; }
    }
    println!("Simpson: area {:.9}, mean {:.4}, spread {:.4}", area, mean_i, var_i.sqrt());
    println!("Simpson: P(S < 50) = {:.4}, P(S < mean) = {:.4}", p_loss_i, p_below_mean_i);
    println!("grid search: density peaks at {:.3}, height {:.6} per dollar", mode_i, f(mode_i));
    let s2_back = (1.0 + var_i / (mean_i * mean_i)).ln();  // going back: mean and variance give sigma^2, then mu
    let mu_back = (mean_i / S0).ln() - s2_back / 2.0;
    println!("back from the Simpson mean and variance: sigma^2 = {:.6}, mu = {:.6}", s2_back, mu_back);

    // road 3: simulate 200,000 years (SplitMix64, seed 20260928; Marsaglia polar)
    let n = 200_000usize;
    let mut rng = Rng(20260928);
    let mut prices = Vec::with_capacity(n);
    for _ in 0..n / 2 {
        let (z1, z2) = rng.normal_pair();
        for z in [z1, z2] { prices.push(S0 * (MU + SIGMA * z).exp()); }
    }
    let nf = n as f64;
    let m_sim = prices.iter().sum::<f64>() / nf;
    let sd_sim = (prices.iter().map(|p| (p - m_sim) * (p - m_sim)).sum::<f64>() / (nf - 1.0)).sqrt();
    let se_mean = sd_sim / nf.sqrt();
    let fr_loss = prices.iter().filter(|&&p| p < S0).count() as f64 / nf;
    let fr_mean = prices.iter().filter(|&&p| p < mean).count() as f64 / nf;
    let se_loss = (fr_loss * (1.0 - fr_loss) / nf).sqrt();
    let se_fm = (fr_mean * (1.0 - fr_mean) / nf).sqrt();
    prices.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let med_sim = (prices[n / 2 - 1] + prices[n / 2]) / 2.0;
    let se_med = 1.0 / (2.0 * f(median) * nf.sqrt());
    println!("simulated {} years, seed 20260928; estimate (standard error)", n);
    println!("  mean {:.4} ({:.4}), spread {:.4}, median {:.4} ({:.4})", m_sim, se_mean, sd_sim, med_sim, se_med);
    println!("  P(S < 50) {:.4} ({:.4}), P(S < mean) {:.4} ({:.4})", fr_loss, se_loss, fr_mean, se_fm);
    let gaps = [(m_sim - mean) / se_mean, (med_sim - median) / se_med, (fr_loss - p_loss) / se_loss, (fr_mean - p_below_mean) / se_fm];
    println!("  gaps from the formulas, in standard errors: {}", gaps.iter().map(|g| format!("{:.1}", g)).collect::<Vec<_>>().join(", "));

    // road 4: a coin-flip year, enumerated exactly: each of 252 days the log price
    // moves MU/252 + or - SIGMA/sqrt(252), with chance 1/2 each
    let d = DAYS as f64;
    let (a, b) = (MU / d, SIGMA / d.sqrt());
    let mut pk = 0.5f64.powi(DAYS as i32);     // chance of k up-days, k = 0 first
    let (mut m_tree, mut cum) = (0.0, 0.0);
    let mut med_tree = f64::NAN;
    for k in 0..=DAYS {
        let s = S0 * (d * a + (2.0 * k as f64 - d) * b).exp();
        m_tree += pk * s;
        cum += pk;
        if med_tree.is_nan() && cum >= 0.5 { med_tree = s; }
        pk *= (d - k as f64) / (k as f64 + 1.0);
    }
    println!("coin-flip year, daily step {:.4}, 253 outcomes: mean {:.4}, median {:.4}", b, m_tree, med_tree);

    // what breaks
    let bare = simpson(&|s: f64| phi(((s / S0).ln() - MU) / SIGMA) / SIGMA, lo, hi);
    let g = |s: f64| phi(((s / S0).ln() - MU) / SIGMA);
    let bare_peak = (0..=20000).map(|i| 40.0 + i as f64 * 0.001).fold(40.0, |m, s| if g(s) > g(m) { s } else { m });
    println!("mistake, median quoted as the mean: {:.4} instead of {:.4}", median, mean);
    println!("mistake, drop the 1/s: area {:.4}; its peak sits at {:.3}, the median, not {:.4}", bare, bare_peak, mode);
    println!("mistake, price spread as S0 sigma: {:.4} instead of {:.4}", S0 * SIGMA, sd);
    println!("mistake, price normal with the same mean and spread: P(S < 50) = {:.4}, P(S < 0) = {:.5}",
             big_phi((S0 - mean) / sd), big_phi(-mean / sd));
    for (lab, mu, sg) in [("try: sigma = 0", MU, 0.0), ("try: sigma = 0.60", MU, 0.60), ("try: 4 years, mu = 0.32, variance 0.36", 4.0 * MU, 2.0 * SIGMA)] {
        println!("{}: mode {:.4}, median {:.4}, mean {:.4}", lab, S0 * (mu - sg * sg).exp(), S0 * mu.exp(), S0 * (mu + sg * sg / 2.0).exp());
    }
    let (up, down) = (S0 * (MU + SIGMA).exp(), S0 * (MU - SIGMA).exp());
    println!("a pair of years, Z = +1 and -1: e^{:.2} and e^{:.2}, prices {:.4} and {:.4}", MU + SIGMA, MU - SIGMA, up, down);
    println!("  gain over the median {:.4}, loss {:.4}, average price {:.4}", up - median, median - down, (up + down) / 2.0);

    // figure: the price density and a normal with the same mean and spread, percent per dollar
    let xs: Vec<f64> = (1..=12).map(|i| 10.0 * i as f64).collect();
    let join = |v: Vec<String>| v.join(", ");
    println!("figure, price $: {}", join(xs.iter().map(|x| format!("{}", x)).collect()));
    println!("figure, lognormal: {}", join(xs.iter().map(|&x| format!("{:.2}", 100.0 * f(x))).collect()));
    println!("figure, same-moment normal: {}", join(xs.iter().map(|&x| format!("{:.2}", 100.0 * phi((x - mean) / sd) / sd)).collect()));

    assert!((area - 1.0).abs() < 1e-8);
    assert!((mean_i - mean).abs() < 1e-6 && (var_i - var).abs() < 1e-5);
    assert!((p_loss_i - p_loss).abs() < 1e-8 && (p_below_mean_i - p_below_mean).abs() < 1e-8);
    assert!((mode_i - mode).abs() < 0.001);
    assert!((s2_back - SIGMA * SIGMA).abs() < 1e-7 && (mu_back - MU).abs() < 1e-7);
    assert!((m_sim - mean).abs() < 4.0 * se_mean && (med_sim - median).abs() < 4.0 * se_med);
    assert!((fr_loss - p_loss).abs() < 4.0 * se_loss && (fr_mean - p_below_mean).abs() < 4.0 * se_fm);
    assert!((m_tree - mean).abs() < 0.001);
    assert!((bare - mean).abs() < 1e-6 && (bare_peak - median).abs() < 0.001);
}
