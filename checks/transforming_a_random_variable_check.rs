// Transforming a random variable -- the check behind the card.  Rust std
// only; nothing imported holds the answer.  A filling machine misses its
// 500 ml target by X ml, X normal with centre 0 and spread SIGMA = 2.  The
// squared error is Y = X^2, in ml^2.  Roads: the branch-sum density; the CDF
// route, differentiated numerically; Simpson's rule on the density; a seeded
// simulation of 200,000 bottles.
use std::f64::consts::PI;

const SIGMA: f64 = 2.0;

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
fn f_x(x: f64, mu: f64) -> f64 { phi((x - mu) / SIGMA) / SIGMA }
fn f_y(y: f64) -> f64 {                      // road 1: add the two branches
    let r = y.sqrt();
    (f_x(r, 0.0) + f_x(-r, 0.0)) / (2.0 * r)
}
fn cdf_y(y: f64, mu: f64) -> f64 {           // road 2: P(-sqrt y <= X <= sqrt y)
    let r = y.sqrt();
    big_phi((r - mu) / SIGMA) - big_phi((-r - mu) / SIGMA)
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000;
    let h = (b - a) / n as f64;
    let mut acc = g(a) + g(b);
    for i in 1..n { acc += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    acc * h / 3.0
}
fn area(dens: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {  // y = t^2 tames the spike at 0
    simpson(&|t: f64| dens(t * t) * 2.0 * t, a.sqrt().max(1e-12), b.sqrt())
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
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let fx = |x: f64| f_x(x, 0.0);
    let fy = |y: f64| cdf_y(y, 0.0);
    println!("model: fill error X normal, centre 0 ml, spread {:.1} ml; Y = X^2 in ml^2", SIGMA);
    println!("formula: f_Y(1) = {:.6}, f_Y(4) = {:.6}, f_Y(9) = {:.6} per ml^2", f_y(1.0), f_y(4.0), f_y(9.0));
    println!("by hand: f_X(1) = {:.6}, f_X(2) = {:.6}, f_X(3) = {:.6} per ml", fx(1.0), fx(2.0), fx(3.0));
    println!("CDF route: P(Y <= 1) = {:.4}, P(Y > 4) = {:.4}, P(Y > 9) = {:.4}, P(Y > 16) = {:.4}",
             fy(1.0), 1.0 - fy(4.0), 1.0 - fy(9.0), 1.0 - fy(16.0));
    println!("by hand: Phi(0.5) = {:.5}, Phi(1) = {:.5}, Phi(1.5) = {:.5}, Phi(2) = {:.5}",
             big_phi(0.5), big_phi(1.0), big_phi(1.5), big_phi(2.0));
    let gap = [0.5, 1.0, 4.0, 9.0].iter().map(|&y| ((fy(y + 1e-5) - fy(y - 1e-5)) / 2e-5 - f_y(y)).abs()).fold(0.0, f64::max);
    println!("slope of the CDF against the branch sum, y = 0.5, 1, 4, 9: largest gap {:.1e}", gap);
    let (mut lo, mut hi) = (0.25, 16.0);       // median of Y by bisection on the CDF
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if fy(mid) < 0.5 { lo = mid } else { hi = mid }
    }
    let median = (lo + hi) / 2.0;
    println!("median of Y by bisection: {:.4}; its square root {:.5} ml", median, median.sqrt());

    // road 3: Simpson's rule on the density itself
    let top = 400.0;                           // sqrt(400) = 20 ml = 10 spreads
    let (tot, p1, p4) = (area(&f_y, 0.0, top), area(&f_y, 0.0, 1.0), area(&f_y, 4.0, top));
    let mean_i = area(&|y: f64| y * f_y(y), 0.0, top);
    let var_i = area(&|y: f64| (y - mean_i) * (y - mean_i) * f_y(y), 0.0, top);
    let band = area(&f_y, 1.0, 2.25);
    println!("Simpson: area {:.9}, P(Y <= 1) = {:.4}, P(Y > 4) = {:.4}", tot, p1, p4);
    println!("Simpson: mean {:.4}, variance {:.4}, spread {:.4}", mean_i, var_i, var_i.sqrt());
    println!("band 1 <= Y <= 2.25: Simpson {:.4}; two strips 2 x P(1 <= X <= 1.5) = {:.4}; strip width {:.2}, band width {:.2}",
             band, 2.0 * (big_phi(0.75) - big_phi(0.5)), 1.5 - 1.0, 2.25 - 1.0);

    // road 4: simulate 200,000 bottles (SplitMix64, seed 20260928; Marsaglia polar)
    let n = 200_000usize;
    let nf = n as f64;
    let mut rng = Rng(20260928);
    let mut xs = Vec::with_capacity(n);
    for _ in 0..n / 2 {
        let (a, b) = rng.normal_pair();
        xs.push(SIGMA * a);
        xs.push(SIGMA * b);
    }
    let mut ys: Vec<f64> = xs.iter().map(|x| x * x).collect();
    ys.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let m_sim = ys.iter().sum::<f64>() / nf;
    let se_m = (ys.iter().map(|y| (y - m_sim) * (y - m_sim)).sum::<f64>() / (nf - 1.0) / nf).sqrt();
    let frac = |pred: &dyn Fn(f64) -> bool, v: &[f64]| v.iter().filter(|&&y| pred(y)).count() as f64 / nf;
    let (q1, q4) = (frac(&|y| y <= 1.0, &ys), frac(&|y| y > 4.0, &ys));
    let (se1, se4) = ((q1 * (1.0 - q1) / nf).sqrt(), (q4 * (1.0 - q4) / nf).sqrt());
    let med_sim = (ys[n / 2 - 1] + ys[n / 2]) / 2.0;
    let se_med = 1.0 / (2.0 * f_y(median) * nf.sqrt());
    let clip0 = frac(&|x| x <= 0.0, &xs);      // a gauge that logs max(X, 0): the flat branch
    let pit = frac(&|x| big_phi(x / SIGMA) <= 0.3, &xs);   // F_X(X) = Phi(X/2) should be uniform
    println!("simulated {} bottles, seed 20260928; estimate (standard error)", n);
    println!("  P(Y <= 1) {:.4} ({:.4}), P(Y > 4) {:.4} ({:.4})", q1, se1, q4, se4);
    println!("  mean {:.4} ({:.4}), median {:.4} ({:.4})", m_sim, se_m, med_sim, se_med);
    let bins: Vec<f64> = (1..=20).map(|k| 0.5 * k as f64).collect();
    let (mut worst, mut sim_h) = (0.0f64, Vec::new());
    for &c in &bins {                          // histogram, bins 0.5 wide centred on c
        let p_hat = frac(&|y| c - 0.25 <= y && y < c + 0.25, &ys);
        let p_ex = fy(c + 0.25) - fy(c - 0.25);
        worst = worst.max((p_hat - p_ex).abs() / (p_ex * (1.0 - p_ex) / nf).sqrt());
        sim_h.push(100.0 * p_hat / 0.5);
    }
    println!("  20 histogram bins against the CDF route: largest gap {:.1} standard errors", worst);
    println!("  F_X(X) = Phi(X/2) at most 0.3: {:.4} ({:.4}); a uniform gives 0.3", pit, (0.3 * 0.7 / nf).sqrt());

    // what breaks
    let one_b = |y: f64| fx(y.sqrt()) / (2.0 * y.sqrt());
    let (one, one4) = (area(&one_b, 0.0, top), area(&one_b, 4.0, top));
    let bare = area(&|y: f64| fx(y.sqrt()) + fx(-y.sqrt()), 0.0, top);
    let mean_x = simpson(&|x: f64| x * fx(x), -20.0, 20.0);
    println!("mistake, one branch only: area {:.4}, P(Y > 4) = {:.4} instead of {:.4}", one, one4, 1.0 - fy(4.0));
    println!("mistake, no stretch factor: area {:.4}; 4 sigma / sqrt(2 pi) = {:.4}", bare, 4.0 * SIGMA / (2.0 * PI).sqrt());
    println!("mistake, square of the average: E[X]^2 = {:.4} instead of E[X^2] = {:.4}", mean_x * mean_x, mean_i);
    println!("hypothesis dropped, gauge logs max(X, 0): branch-formula area {:.4}; simulated P(reading = 0) {:.4} ({:.4})",
             area(&fx, 0.0, top), clip0, (clip0 * (1.0 - clip0) / nf).sqrt());
    println!("try: spread 1 ml: P(Y > 4) = {:.4}, mean {:.4}", 1.0 - (big_phi(2.0) - big_phi(-2.0)), simpson(&|x: f64| x * x * phi(x), -20.0, 20.0));
    let shifted = |y: f64| y * (f_x(y.sqrt(), 1.0) + f_x(-y.sqrt(), 1.0)) / (2.0 * y.sqrt());
    println!("try: centre 1 ml: f_Y(4) = {:.6}, P(Y > 4) = {:.4}, mean {:.4}",
             (f_x(2.0, 1.0) + f_x(-2.0, 1.0)) / 4.0, 1.0 - cdf_y(4.0, 1.0), area(&shifted, 0.0, top));
    println!("try: Y = X^3, one branch: f_Y(8) = {:.6}, P(Y > 8) = {:.4}", fx(2.0) / 12.0, 1.0 - big_phi(1.0));
    println!("try: Y = |X|, no stretch: f(1) = {:.6}, mean {:.4}", 2.0 * fx(1.0), simpson(&|x: f64| 2.0 * x * fx(x), 0.0, 20.0));

    // figures: the density in percent per ml^2, and the fold drawn to scale
    println!("figure, y (ml^2): {}", join(&bins, 1));
    println!("figure, formula: {}", join(&bins.iter().map(|&c| 100.0 * f_y(c)).collect::<Vec<_>>(), 2));
    println!("figure, simulated: {}", join(&sim_h, 2));
    let px = |x: f64| 180.0 + 45.0 * x;
    let py = |y: f64| 200.0 - 20.0 * y;
    println!("figure, parabola: ends ({:.0},{:.0}) ({:.0},{:.0}), control ({:.0},{:.0}); band y {:.0} to {:.0}; strips x {:.1} to {:.0} and {:.0} to {:.1}",
             px(-3.0), py(9.0), px(3.0), py(9.0), px(0.0), py(-9.0), py(2.25), py(1.0), px(-1.5), px(-1.0), px(1.0), px(1.5));

    assert!((tot - 1.0).abs() < 1e-6 && (one - 0.5).abs() < 1e-6);
    assert!((p1 - fy(1.0)).abs() < 1e-7 && (p4 - (1.0 - fy(4.0))).abs() < 1e-7 && gap < 1e-5);
    assert!((mean_i - SIGMA * SIGMA).abs() < 1e-6 && (var_i - 2.0 * SIGMA.powi(4)).abs() < 1e-4);
    assert!((bare - 4.0 * SIGMA / (2.0 * PI).sqrt()).abs() < 1e-6 && (band - 2.0 * (big_phi(0.75) - big_phi(0.5))).abs() < 1e-7);
    assert!((f_y(4.0) - (-4.0 / (2.0 * SIGMA * SIGMA)).exp() / (SIGMA * (2.0 * PI * 4.0).sqrt())).abs() < 1e-12);
    assert!((q4 - (1.0 - fy(4.0))).abs() < 4.0 * se4 && (m_sim - SIGMA * SIGMA).abs() < 4.0 * se_m);
    assert!((med_sim - median).abs() < 4.0 * se_med && worst < 4.0);
    assert!((clip0 - 0.5).abs() < 4.0 * (0.25 / nf).sqrt());
    assert!((pit - 0.3).abs() < 4.0 * (0.3 * 0.7 / nf).sqrt());
}
