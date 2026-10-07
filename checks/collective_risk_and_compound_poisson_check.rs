// Aggregate claims: compound Poisson with lognormal sizes, and a Pareto fit to the large ones.
// Rust std only. Random numbers, integrals and the optimiser are written here.
use std::f64::consts::PI;

const POLICIES: f64 = 50_000.0;
const RATE: f64 = 0.05;
const MED: f64 = 3000.0; // lognormal sizes: median $3,000
const SIG: f64 = 1.2; // log-spread
const U: f64 = 25_000.0; // large-claim threshold
const YEARS: usize = 2000;

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }

// Simpson's rule, same slices as the Python road
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for k in 1..n {
        let w = if k % 2 == 1 { 4.0 } else { 2.0 };
        acc += w * f(a + k as f64 * h);
    }
    (f(a) + f(b) + acc) * h / 3.0
}

struct SplitMix(u64);
impl SplitMix {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54) // strictly inside (0, 1)
    }
}

fn main() {
    let lam = POLICIES * RATE;
    let m = MED.ln();
    // road 1: closed forms
    let mu = (m + SIG * SIG / 2.0).exp();
    let m2 = (2.0 * m + 2.0 * SIG * SIG).exp();
    let var_x = m2 - mu * mu;
    let (es, vs) = (lam * mu, lam * m2);
    let sd = vs.sqrt();
    // road 2: Simpson over the bell curve of log size
    let size = |z: f64| MED * (SIG * z).exp();
    let mu_int = simpson(&|z| size(z) * phi(z), -12.0, 12.0, 20000);
    let m2_int = simpson(&|z| size(z) * size(z) * phi(z), -12.0, 14.0, 20000);
    let zu = (U.ln() - m) / SIG;
    let pu_int = simpson(&phi, zu, 12.0, 20000);
    let elog_int = simpson(&|z| (m + SIG * z - U.ln()) * phi(z), zu, 12.0, 20000) / pu_int;
    let alpha_pop = 1.0 / elog_int;
    let big_mean_int = simpson(&|z| size(z) * phi(z), zu, 14.0, 20000) / pu_int;
    // road 3: simulation
    let mut rng = SplitMix(20260928);
    let (mut totals, mut counts) = (Vec::new(), Vec::new());
    let (mut big_n, mut big_logsum) = (0usize, 0.0f64);
    let (mut y1_n, mut y1_logsum) = (0usize, 0.0f64);
    for year in 0..YEARS {
        let mut n = 0usize;
        let mut t = -rng.unif().ln() / lam;
        while t <= 1.0 { n += 1; t += -rng.unif().ln() / lam; }
        let (mut s, mut k) = (0.0f64, 0usize);
        while k < n {
            let r = (-2.0 * rng.unif().ln()).sqrt();
            let th = 2.0 * PI * rng.unif();
            for z in [r * th.cos(), r * th.sin()] {
                if k < n {
                    let x = MED * (SIG * z).exp();
                    s += x;
                    k += 1;
                    if x > U {
                        big_n += 1; big_logsum += (x / U).ln();
                        if year == 0 { y1_n += 1; y1_logsum += (x / U).ln(); }
                    }
                }
            }
        }
        totals.push(s); counts.push(n as f64);
    }
    let yf = YEARS as f64;
    let mean_sim = totals.iter().sum::<f64>() / yf;
    let sd_sim = (totals.iter().map(|v| (v - mean_sim) * (v - mean_sim)).sum::<f64>() / (yf - 1.0)).sqrt();
    let n_mean = counts.iter().sum::<f64>() / yf;
    let n_var = counts.iter().map(|c| (c - n_mean) * (c - n_mean)).sum::<f64>() / (yf - 1.0);
    // road 4: Pareto fit, closed form against golden section
    let bn = big_n as f64;
    let alpha_hat = bn / big_logsum;
    let alpha_y1 = y1_n as f64 / y1_logsum;
    let loglik = |a: f64| bn * a.ln() - a * big_logsum;
    let (mut lo, mut hi, g) = (0.1f64, 20.0f64, (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (a1, a2) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if loglik(a1) > loglik(a2) { hi = a2 } else { lo = a1 }
    }
    let alpha_gold = (lo + hi) / 2.0;
    let pu_sim = bn / counts.iter().sum::<f64>();
    let pareto_big_mean = alpha_hat * U / (alpha_hat - 1.0);
    let tail_ln = |x: f64| simpson(&phi, (x.ln() - m) / SIG, 14.0, 4000);
    let tail_par = |x: f64| pu_int * (U / x).powf(alpha_hat);
    // what breaks
    let z50 = (5e4f64.ln() - m) / SIG;
    let rows: Vec<(&str, f64)> = vec![
        ("claims a year, lambda", lam), ("log centre m = ln 3000", m), ("exp(sigma^2 / 2)", (SIG * SIG / 2.0).exp()),
        ("exp(2 sigma^2)", (2.0 * SIG * SIG).exp()), ("threshold in bell-curve units", zu), ("mean claim E[X], formula", mu), ("mean claim E[X], integral", mu_int),
        ("E[X^2], formula", m2), ("E[X^2], integral", m2_int), ("sd of one claim", var_x.sqrt()),
        ("E[S], formula", es), ("sd(S), formula", sd), ("pure premium per policy", es / POLICIES),
        ("count part of Var(S), share", lam * mu * mu / vs), ("size part of Var(S), share", lam * var_x / vs),
        ("individual model: variance of count", POLICIES * RATE * (1.0 - RATE)),
        ("sim: mean claims a year", n_mean), ("sim: variance of claims a year", n_var),
        ("E[S], simulated", mean_sim), ("sd(S), simulated", sd_sim),
        ("P(X > 25,000), integral", pu_int), ("P(X > 25,000), simulated", pu_sim),
        ("large claims a year", lam * pu_int), ("large claims, all years", bn), ("large claims, year 1", y1_n as f64),
        ("alpha, closed form, all years", alpha_hat), ("alpha, golden section", alpha_gold),
        ("alpha, year 1 only", alpha_y1), ("alpha, endless data (integral)", alpha_pop),
        ("alpha standard error, all years", alpha_hat / bn.sqrt()), ("alpha standard error, year 1", alpha_y1 / (y1_n as f64).sqrt()),
        ("E[X | X > 25,000], lognormal", big_mean_int), ("E[X | X > 25,000], Pareto", pareto_big_mean),
        ("large-claim cost a year, lognormal", lam * pu_int * big_mean_int),
        ("large-claim cost a year, Pareto", lam * pu_int * pareto_big_mean),
        ("break: sd without count part", (lam * var_x).sqrt()), ("break: sd with sizes fixed", lam.sqrt() * mu),
        ("break: E[S] from median size", lam * MED), ("break: sd by adding sds", lam * var_x.sqrt()),
        ("sd(S) / E[S]", sd / es), ("try: rate 10%, sd(S) / E[S]", (2.0 * lam * m2).sqrt() / (2.0 * lam * mu)),
        ("try: log-spread 1.0, E[S]", lam * (m + 0.5).exp()), ("try: log-spread 1.0, sd(S)", (lam * (2.0 * m + 2.0).exp()).sqrt()),
        ("try: threshold 50,000, alpha endless", 1.0 / (simpson(&|z| (m + SIG * z - 5e4f64.ln()) * phi(z), z50, 12.0, 20000)
                                                      / simpson(&phi, z50, 12.0, 20000))),
    ];
    for (label, v) in &rows { println!("{:<38}{:>18.6}", label, v); }
    println!("tail: claims a year above x, lognormal vs fitted Pareto");
    for x in [25_000.0f64, 50_000.0, 100_000.0, 200_000.0, 400_000.0] {
        println!("  x = {:>7}   lognormal {:>10.4}   Pareto {:>10.4}", x as u64, lam * tail_ln(x), lam * tail_par(x));
    }
    let edges: Vec<f64> = (0..11).map(|i| 13.4e6 + 0.4e6 * i as f64).collect();
    let hist: Vec<usize> = (0..10).map(|i| totals.iter().filter(|&&v| edges[i] <= v && v < edges[i + 1]).count()).collect();
    let e_s: Vec<String> = edges[..10].iter().map(|e| format!("{:.1}", e / 1e6)).collect();
    let h_s: Vec<String> = hist.iter().map(|h| h.to_string()).collect();
    println!("histogram, $M from: {}", e_s.join(" "));
    println!("histogram, years:   {}  outside: {}", h_s.join(" "), YEARS - hist.iter().sum::<usize>());

    assert!((mu_int / mu - 1.0).abs() < 1e-9); // integral agrees with closed form
    assert!((m2_int / m2 - 1.0).abs() < 1e-9); // and for the second moment
    assert!((mean_sim - es).abs() < 4.0 * sd / yf.sqrt()); // simulation mean within 4 standard errors
    assert!((sd_sim / sd - 1.0).abs() < 0.06); // simulated spread within 6%
    assert!((n_var / n_mean - 1.0).abs() < 0.1); // Poisson counts: variance equals mean
    assert!((alpha_gold - alpha_hat).abs() < 1e-6); // optimiser finds the closed-form maximum
    assert!((alpha_hat - alpha_pop).abs() < 4.0 * alpha_hat / bn.sqrt()); // fit lands near its endless-data value
    println!("ALL CHECKS PASS");
}
