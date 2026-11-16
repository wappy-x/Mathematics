// The central limit theorem by fingerprints -- the check behind the card.
// Model (illustrative): a stock's daily log return is 1.5 % times Y, where Y is
// a Student t law with 3 degrees of freedom scaled to variance 1: density
// 2/(pi (1 + y^2)^2), fingerprint (1 + |s|) exp(-|s|).  A month is 21 days.
// Roads: closed-form fingerprint against its defining integral and simulation;
// inversion of the fingerprint against the closed-form law and simulation.
use std::f64::consts::PI;
const SIGMA: f64 = 1.5;
const N: usize = 21;
const LOSS: f64 = 10.0;
const CUT: f64 = 40.0;
fn phi_y(s: f64) -> f64 { // fingerprint of one standardised day
    let s = s.abs();
    (1.0 + s) * (-s).exp()
}
fn phi_z(t: f64, n: usize) -> f64 { // line 1: sums -> products, scale -> argument
    phi_y(t / (n as f64).sqrt()).powf(n as f64)
}
fn big_phi(x: f64) -> f64 { // normal law, one series written out
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= -x * x / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 { // m even
    let h = (b - a) / m as f64;
    let mut acc = 0.0;
    for k in 1..m {
        acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + acc) * h / 3.0
}
fn cdf(x: f64, n: usize) -> f64 { // Gil-Pelaez inversion of a real, even fingerprint
    let g = |t: f64| if t == 0.0 { x } else { (t * x).sin() / t * phi_z(t, n) };
    0.5 + simpson(&g, 0.0, CUT, 40000) / PI
}
fn tail_bound(n: usize) -> f64 { // |integral beyond cut| / pi, phi_y falling on s > 0
    let (cut, rn) = (CUT, (n as f64).sqrt());
    let a = cut / rn;
    phi_y(a).powf((n - 1) as f64) * rn * (a + 2.0) * (-a).exp() / cut / PI
}
fn cdf_one_day(x: f64) -> f64 { // closed form of the scaled t law, 3 degrees
    0.5 + (x.atan() + x / (1.0 + x * x)) / PI
}
struct Rng(u64); // SplitMix64, seed 20261115
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normals(&mut self) -> (f64, f64) { // Box-Muller: two standard normals
        let r = (-2.0 * (1.0 - self.unif()).ln()).sqrt();
        let a = 2.0 * PI * self.unif();
        (r * a.cos(), r * a.sin())
    }
    fn day(&mut self) -> f64 { // t law, 3 degrees, scaled to variance 1
        let (g0, g1) = self.normals();
        let (g2, g3) = self.normals();
        g0 / (g1 * g1 + g2 * g2 + g3 * g3).sqrt()
    }
}
fn add(xs: &[f64]) -> f64 { // plain left-to-right sum
    let mut total = 0.0;
    for x in xs { total += x; }
    total
}
fn main() {
    let nf = N as f64;
    let z_loss = -LOSS / (SIGMA * nf.sqrt());
    let s = 1.0 / nf.sqrt();
    let dens = |y: f64| 2.0 / (PI * (1.0 + y * y) * (1.0 + y * y));
    let by_integral = 2.0 * simpson(&|y: f64| (s * y).cos() * dens(y), 0.0, 400.0, 80000);
    println!("one day: sd {:.1} %; month: {} days, sd {:.6} %", SIGMA, N, SIGMA * nf.sqrt());
    println!("a monthly log return of -{:.0} % (a price fall of {:.2} %) is z = {:.6} month standard deviations",
             LOSS, 100.0 * (1.0 - (-LOSS / 100.0).exp()), z_loss);
    println!("fingerprint of one day at s = 1/sqrt(21) = {:.6}: closed form {:.9}", s, phi_y(s));
    println!("  by its defining integral to |y| = 400 (tail at most 0.000000007): {:.9}", by_integral);
    let r = phi_y(s) - (1.0 - s * s / 2.0);
    println!("line 2: 1 - s^2/2 = {:.6}; remainder r = {:.6}; |s|^3/3 = {:.6}", 1.0 - s * s / 2.0, r, s.powf(3.0) / 3.0);
    let (a21, b21) = (phi_z(1.0, N), (1.0 - 1.0 / (2.0 * nf)).powf(nf));
    println!("line 3 at t = 1: fingerprint^21 {:.6}; (1 - 1/42)^21 {:.6}; gap {:.6} <= 21|r| = {:.6}",
             a21, b21, (a21 - b21).abs(), nf * r.abs());
    let bell = simpson(&|y: f64| y.cos() * (-y * y / 2.0).exp(), -10.0, 10.0, 4000) / (2.0 * PI).sqrt();
    println!("line 4: exp(-1/2) = {:.6}; bell fingerprint by integral {:.6}", (-0.5f64).exp(), bell);
    println!("n, fingerprint of Z_n at t = 1, minus exp(-1/2), n|r(1/sqrt n)|");
    for n in [1usize, 2, 5, 21, 100, 1000] {
        let rn = phi_y(1.0 / (n as f64).sqrt()) - 1.0 + 1.0 / (2.0 * n as f64);
        println!("  {:4}  {:.6}  {:.6}  {:.6}", n, phi_z(1.0, n), phi_z(1.0, n) - (-0.5f64).exp(), n as f64 * rn.abs());
    }
    println!("chart t, fingerprint n = 1, n = 21, exp(-t^2/2)");
    for k in 0..13 {
        let t = k as f64 / 4.0;
        println!("  {:.2}  {:.4}  {:.4}  {:.4}", t, phi_z(t, 1), phi_z(t, N), (-t * t / 2.0).exp());
    }
    let (p1, p21, pn) = (cdf(z_loss, 1), cdf(z_loss, N), big_phi(z_loss));
    println!("chance of a month at or below z, by inversion (cut-off t = {:.0}, tail below 1e-12: {}):", CUT,
             if tail_bound(1).max(tail_bound(N)) < 1e-12 { "yes" } else { "no" });
    println!("  one day's law {:.6} (closed form {:.6}); month {:.6}; bell {:.6}", p1, cdf_one_day(z_loss), p21, pn);
    println!("far tail: chance at or below -3 and -4 standard deviations");
    let ns = [1usize, 5, 21, 100, 1000];
    let mut tails = Vec::new();
    for &n in ns.iter() {
        tails.push((cdf(-3.0, n), cdf(-4.0, n)));
        println!("  n = {:4}  {:.6}  {:.6}", n, tails.last().unwrap().0, tails.last().unwrap().1);
    }
    println!("  bell      {:.6}  {:.6};  ratio at -4, n = 21: {:.1}", big_phi(-3.0), big_phi(-4.0), tails[2].1 / big_phi(-4.0));
    println!("bars: chance at or below -3, one # per 0.0002");
    for (i, &n) in ns.iter().enumerate() {
        let bar = "#".repeat((tails[i].0 / 0.0002).round() as usize);
        println!("  n = {:<5}|{:<35}| {:.6}", n, bar, tails[i].0);
    }
    println!("  bell     |{:<35}| {:.6}", "#".repeat((big_phi(-3.0) / 0.0002).round() as usize), big_phi(-3.0));
    let m = 20000; // quarters of 84 days = 80,000 months
    let mut rng = Rng(20261115);
    let (mut hits, mut hits3, mut moved) = (0usize, 0usize, 0usize);
    let (mut cos_sum, mut sq_sum) = (0.0f64, 0.0f64);
    for _ in 0..m {
        let days: Vec<f64> = (0..84).map(|_| rng.day()).collect();
        for q in 0..4 {
            let zm = add(&days[21 * q..21 * q + 21]) / nf.sqrt();
            if zm <= z_loss { hits += 1; }
            if zm <= -3.0 { hits3 += 1; }
            cos_sum += zm.cos();
        }
        let (z21, z84) = (add(&days[..21]) / 21f64.sqrt(), add(&days) / 84f64.sqrt());
        if (z84 - z21).abs() > 1.0 { moved += 1; }
        sq_sum += (z84 - z21) * (z84 - z21);
    }
    let months = (4 * m) as f64;
    let (p_sim, se) = (hits as f64 / months, (p21 * (1.0 - p21) / months).sqrt());
    println!("simulation, {} months, seed 20261115: at or below z {:.6} (se {:.6}); below -3 {:.6}",
             4 * m, p_sim, se, hits3 as f64 / months);
    println!("  fingerprint at t = 1 by averaging cos: {:.6}", cos_sum / months);
    let p84 = 2.0 * cdf(-1.0, 84); // Z_84 - Z_21 has the law of Z_84: the days are symmetric
    println!("  Z_84 - Z_21: mean square {:.6} (expected 1 at every n); beyond 1 in {:.6} of quarters, exact {:.6}, bell {:.6}",
             sq_sum / m as f64, moved as f64 / m as f64, p84, 2.0 * (1.0 - big_phi(1.0)));
    println!("break 1, divide by n, not sqrt n: fingerprint at t = 1 is {:.6}, n = 1000: {:.6}",
             phi_y(1.0 / nf).powf(nf), phi_y(1.0 / 1000.0).powf(1000.0));
    println!("break 2, one day copied 21 times: fingerprint {:.6}, chance at or below z {:.6}", phi_y(1.0), p1);
    println!("break 3, Cauchy days: fingerprint of sum/sqrt n at t = 1: n = 21 {:.6}, n = 1000 {:.6}; mean of n: {:.6} for every n",
             (-(21f64).sqrt()).exp(), (-(1000f64).sqrt()).exp(), (-1.0f64).exp());
    assert!((by_integral - phi_y(s)).abs() < 1e-8); // closed form = defining integral
    assert!((cdf(z_loss, 1) - cdf_one_day(z_loss)).abs() < 1e-10); // inversion = closed-form law
    assert!((cdf(-3.0, 1) - cdf_one_day(-3.0)).abs() < 1e-10);
    assert!((a21 - b21).abs() <= nf * r.abs()); // the product lemma
    assert!((p_sim - p21).abs() < 4.0 * se); // inversion = simulation
    assert!((cos_sum / months - a21).abs() < 0.006); // fingerprint = simulation
    assert!((moved as f64 / m as f64 - p84).abs() < 4.0 * (p84 * (1.0 - p84) / m as f64).sqrt()); // law of Z_84 = simulation
    assert!((phi_z(1.0, 1000000) - (-0.5f64).exp()).abs() < 0.001); // the limit is the bell's
    println!("ALL CHECKS PASS");
}
