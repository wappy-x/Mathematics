// Densities and likelihood ratios -- the check behind the card.
// Rust std only.  Bus waits in minutes: model P says buses come at rate 1 a
// minute (density e^-x), model Q says rate 2 (density 2 e^-2x).  Then the
// fair die is tilted by e^(theta x face) until its mean is 4.4, and set
// beside the loaded die with the same mean.
fn p(x: f64) -> f64 { (-x).exp() }                  // density of P against length
fn q(x: f64) -> f64 { 2.0 * (-2.0 * x).exp() }      // density of Q against length
fn lr(x: f64) -> f64 { 2.0 * (-x).exp() }           // the claimed dQ/dP, 2 e^-x
fn cdf(x: f64) -> f64 { 1.0 - (-x).exp() }          // P(wait <= x)

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {   // composite Simpson, n even
    let n = 20000;
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h) }
    (g(a) + g(b) + acc) * h / 3.0
}

struct SplitMix64 { s: u64 }                         // the same generator in both checks
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                   // in (0, 1], never 0, so log is safe
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) + 1) as f64 / 9007199254740992.0
    }
}

fn mean_se(xs: &[f64]) -> (f64, f64) {               // sample mean and its standard error
    let n = xs.len() as f64;
    let m = xs.iter().fold(0.0, |s, x| s + x) / n;
    let ss = xs.iter().fold(0.0, |s, x| s + (x - m) * (x - m));
    (m, (ss / (n - 1.0) / n).sqrt())
}

fn moments(t: f64) -> (f64, f64, f64) {              // M(theta), mean and variance of the tilt
    let w: Vec<f64> = (1..=6).map(|k| (t * k as f64).exp() / 6.0).collect();
    let big = w.iter().fold(0.0, |s, x| s + x);
    let mean = w.iter().enumerate().fold(0.0, |s, (i, x)| s + (i + 1) as f64 * x) / big;
    let var = w.iter().enumerate().fold(0.0, |s, (i, x)| {
        let d = (i + 1) as f64 - mean; s + d * d * x }) / big;
    (big, mean, var)
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    // ---- road 1: the density is the slope of the distribution function ----
    let mut slope_err: f64 = 0.0;
    for &x in &[0.5, 1.0, 2.0] {
        let h = 1e-4;
        let slope = (cdf(x + h) - cdf(x - h)) / (2.0 * h);
        println!("density at {:.1}: slope of F {:.6}, formula e^-x {:.6}", x, slope, p(x));
        slope_err = slope_err.max((slope - p(x)).abs());
    }
    println!("P(wait <= 1): area under the density {:.6}, F(1) {:.6}", simpson(&p, 0.0, 1.0), cdf(1.0));

    // ---- the two densities and their ratio, the points of the chart ----
    let xs: Vec<f64> = (0..7).map(|i| 0.5 * i as f64).collect();
    println!("chart x: {}", join(&xs, 1));
    println!("chart p: {}", join(&xs.iter().map(|&x| p(x)).collect::<Vec<_>>(), 2));
    println!("chart q: {}", join(&xs.iter().map(|&x| q(x)).collect::<Vec<_>>(), 2));
    println!("chart L: {}", join(&xs.iter().map(|&x| lr(x)).collect::<Vec<_>>(), 2));
    println!("L at 0.3 = {:.4}; L at 2 = {:.4}; L = 1 at x = ln 2 = {:.4}", lr(0.3), lr(2.0), 2f64.ln());

    // ---- road 2: Q(wait > 1) three ways ----
    let exact = (-2f64).exp();
    let by_integral = simpson(&|x| lr(x) * p(x), 1.0, 41.0);
    let mut rng = SplitMix64 { s: 20260929 };
    let draws: Vec<f64> = (0..200000).map(|_| -rng.uniform().ln()).collect();   // waits from P
    let (tail_mc, tail_se) = mean_se(&draws.iter().map(|&x| if x > 1.0 { lr(x) } else { 0.0 }).collect::<Vec<_>>());
    let (mass_mc, mass_se) = mean_se(&draws.iter().map(|&x| lr(x)).collect::<Vec<_>>());
    println!("Q(wait > 1): closed form e^-2 {:.6}; integral of L dP {:.6}", exact, by_integral);
    println!("  reweighted P-draws, n = 200000: {:.6} (standard error {:.6})", tail_mc, tail_se);
    println!("  plain P-probability of the same event {:.6}", 1.0 - cdf(1.0));
    println!("P-average of L: integral {:.6}; P-draws {:.6} (se {:.6})", simpson(&|x| lr(x) * p(x), 0.0, 40.0), mass_mc, mass_se);

    // ---- road 3: Kullback-Leibler divergence three ways ----
    let kl_exact = 2f64.ln() - 0.5;
    let kl_int = simpson(&|x| q(x) * (q(x) / p(x)).ln(), 0.0, 40.0);
    let qdraws: Vec<f64> = (0..200000).map(|_| -rng.uniform().ln() / 2.0).collect();   // waits from Q
    let (kl_mc, kl_se) = mean_se(&qdraws.iter().map(|&x| lr(x).ln()).collect::<Vec<_>>());
    let theta: f64 = -1.0;                                          // Q is P tilted by theta = -1
    let big_m = simpson(&|x| (theta * x).exp() * p(x), 0.0, 40.0);  // M(theta), integrated against P
    let m_tilt = simpson(&|x| x * (theta * x).exp() / big_m * p(x), 0.0, 40.0);   // the tilt's mean
    let kl_tilt = theta * m_tilt - big_m.ln();
    println!("D(Q||P): ln 2 - 1/2 = {:.6}; integral {:.6}; Q-draws {:.6} (se {:.6})", kl_exact, kl_int, kl_mc, kl_se);
    println!("  as a tilt, theta = -1, M {:.6} and m {:.6} integrated against P: theta m - ln M {:.6}", big_m, m_tilt, kl_tilt);
    let kl_rev = simpson(&|x| p(x) * (p(x) / q(x)).ln(), 0.0, 40.0);
    println!("D(P||Q): 1 - ln 2 = {:.6}; integral {:.6}", 1.0 - 2f64.ln(), kl_rev);

    // ---- road 4: tilt the fair die to mean 4.4, three root-finders ----
    let target = 4.4;
    let (mut lo, mut hi) = (0.0, 3.0);
    for _ in 0..100 {                                // bisection on mean(theta) = 4.4
        let mid = (lo + hi) / 2.0;
        if moments(mid).1 < target { lo = mid } else { hi = mid }
    }
    let th_bis = (lo + hi) / 2.0;
    let mut th_new = 0.0;
    for i in 0..5 {                                  // Newton: slope of the mean is the variance
        let (_, mean, var) = moments(th_new);
        th_new -= (mean - target) / var;
        println!("Newton step {}: theta {:.12}", i + 1, th_new);
    }
    let (mut a, mut b, g) = (0.0, 3.0, (5f64.sqrt() - 1.0) / 2.0);
    let obj = |t: f64| moments(t).0.ln() - target * t;   // convex; its minimum is the tilt
    for _ in 0..80 {                                 // golden-section search, no derivatives
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if obj(c) < obj(d) { b = d } else { a = c }
    }
    let th_gold = (a + b) / 2.0;
    let (big, mean, var) = moments(th_bis);
    let tilt: Vec<f64> = (1..=6).map(|k| (th_bis * k as f64).exp() / 6.0 / big).collect();
    println!("theta: bisection {:.9}; Newton {:.9}; golden section {:.7}", th_bis, th_new, th_gold);
    println!("tilted die: M(theta) {:.6}, mean {:.6}, variance {:.6}", big, mean, var);
    let loaded = [0.1, 0.1, 0.1, 0.1, 0.2, 0.4];
    println!("tilted die weights: {}", join(&tilt, 4));
    println!("chart fair:   {}", join(&[1.0 / 6.0; 6], 2));
    println!("chart tilted: {}", join(&tilt, 2));
    println!("chart loaded: {}", join(&loaded, 2));
    println!("dQ/dP for the tilt, e^(theta k)/M: {}", join(&tilt.iter().map(|w| 6.0 * w).collect::<Vec<_>>(), 4));
    let kl_t_sum = tilt.iter().fold(0.0, |s, w| s + w * (6.0 * w).ln());
    let kl_t_formula = th_bis * target - big.ln();
    let kl_l = loaded.iter().fold(0.0, |s, w| s + w * (6.0 * w).ln());
    let kl_lt = loaded.iter().zip(&tilt).fold(0.0, |s, (w, t)| s + w * (w / t).ln());
    println!("D(tilt||fair): by the sum {:.6}; theta m - ln M {:.6}", kl_t_sum, kl_t_formula);
    println!("D(loaded||fair) {:.6} = D(loaded||tilt) {:.6} + D(tilt||fair) {:.6}", kl_l, kl_lt, kl_t_sum);

    // ---- what breaks ----
    for &h in &[0.1, 0.01, 0.001] {                 // the die against length: no density
        println!("die, P(face in [6 - h, 6 + h]) / length 2h, h = {}: {:.4}", h, (1.0 / 6.0) / (2.0 * h));
    }
    let pu = |x: f64| if x <= 1.0 { 1.0 } else { 0.0 };        // P uniform on [0, 1]
    let qu = |x: f64| if x <= 2.0 { 0.5 } else { 0.0 };        // Q uniform on [0, 2]: not << P
    let seen = simpson(&|x| (if pu(x) > 0.0 { qu(x) / pu(x) } else { 0.0 }) * pu(x), 0.0, 1.0);
    let unseen = simpson(&qu, 1.0, 2.0);                       // Q's mass where p = 0
    println!("Q uniform on [0, 2], P on [0, 1]: integral of q/p dP {:.6}; Q-mass where p = 0 {:.6}", seen, unseen);
    let wrong = simpson(&|x| p(x) * lr(x).ln(), 0.0, 40.0);
    println!("log-ratio averaged under P instead of Q: {:.6}; Q's density at 0: {:.4}", wrong, q(0.0));

    assert!(slope_err < 1e-7);                                 // density = slope of F
    assert!((by_integral - exact).abs() < 1e-9);               // integral of L dP = Q(A)
    assert!((tail_mc - exact).abs() < 4.0 * tail_se);          // reweighted draws land on it
    assert!((kl_int - kl_exact).abs() < 1e-9);                 // KL by integral vs closed form
    assert!((kl_mc - kl_int).abs() < 4.0 * kl_se);             // KL by sampling from Q
    assert!((kl_tilt - kl_int).abs() < 1e-9);                  // KL by the tilt formula
    assert!((kl_rev - (1.0 - 2f64.ln())).abs() < 1e-9);        // the reverse divergence
    assert!((th_bis - th_new).abs() < 1e-12);                  // two root-finders agree
    assert!((th_gold - th_bis).abs() < 1e-6);                  // KL minimiser is the tilt
    assert!((kl_l - (kl_lt + kl_t_sum)).abs() < 1e-12);        // Pythagoras for the tilt
    assert!((kl_t_sum - kl_t_formula).abs() < 1e-12);          // tilt KL two ways
    println!("ALL CHECKS PASS");
}
