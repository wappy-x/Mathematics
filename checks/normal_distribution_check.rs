// Normal distribution -- the same check as the Python, in Rust.  No crates.
// A share's daily return is modelled as normal: centre MU = 0.05 percent,
// spread SIGMA = 1.2 percent.  The standard normal's cumulative area Phi is
// built twice, by a power series and by Simpson's rule, and the answers are
// met a third way by a seeded simulation.  Nothing used holds the answer.
use std::f64::consts::PI;

const MU: f64 = 0.05; // percent per day
const SIGMA: f64 = 1.2;
const DAYS: f64 = 252.0; // trading days a year
const LOSS: f64 = -2.0; // the loss threshold, percent

fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() } // standard normal density

fn f(x: f64) -> f64 { phi((x - MU) / SIGMA) / SIGMA } // the return's own density, per percent

fn phi_series(z: f64) -> f64 { // road 1: Taylor series, integrated term by term
    let (mut term, mut total) = (z, z); // term = (-1)^n z^(2n+1) / (2^n n!)
    for n in 1..200 {
        let n = n as f64;
        term *= -z * z / (2.0 * n);
        total += term / (2.0 * n + 1.0);
    }
    0.5 + total / (2.0 * PI).sqrt()
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 { // road 2, n even
    let h = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(a + i as f64 * h);
    }
    s * h / 3.0
}

fn phi_simpson(z: f64) -> f64 { simpson(&phi, -12.0, z, 4000) } // area from far left (-12) to z

struct SplitMix(u64); // road 3: SplitMix64, seed 20260928

impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) } // in (0, 1)
    fn normal_pair(&mut self) -> [f64; 2] { // Marsaglia's polar method
        loop {
            let (u, v) = (2.0 * self.uniform() - 1.0, 2.0 * self.uniform() - 1.0);
            let s = u * u + v * v;
            if s > 0.0 && s < 1.0 {
                let k = (-2.0 * s.ln() / s).sqrt();
                return [u * k, v * k];
            }
        }
    }
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    // the parameters mean what they say: area 1, centre MU, spread SIGMA
    let (lo, hi) = (MU - 12.0 * SIGMA, MU + 12.0 * SIGMA);
    let area = simpson(&f, lo, hi, 4000);
    let mean = simpson(&|x| x * f(x), lo, hi, 4000);
    let var = simpson(&|x| (x - mean).powi(2) * f(x), lo, hi, 4000);
    println!("model: centre {:.2}%, spread {:.2}%, variance {:.2} (percent squared)", MU, SIGMA, SIGMA * SIGMA);
    println!("by Simpson on the return's density: area {:.9}, mean {:.6}, sd {:.6}", area, mean, var.sqrt());
    println!("peak height 1/sqrt(2 pi) = {:.6}; divided by the spread = {:.6} per percent", phi(0.0), f(MU));

    // Phi by two roads
    println!("z, Phi by series, Phi by Simpson");
    for z in [-2.0, -1.0, 0.0, 1.0, 1.7083, 2.0, 3.0] {
        println!("{:7.4}  {:.6}  {:.6}", z, phi_series(z), phi_simpson(z));
    }
    for k in [1.0, 2.0, 3.0] {
        let inside = 2.0 * phi_series(k) - 1.0;
        println!("within {} spread(s), {:.2}% to {:.2}%: {:.6}; beyond: {:.6}",
                 k, MU - k * SIGMA, MU + k * SIGMA, inside, 1.0 - inside);
    }

    // the card's example: a day beyond two spreads, and a loss worse than 2 percent
    let beyond2 = 2.0 * (1.0 - phi_series(2.0));
    println!("beyond two spreads: {:.4}, one day in {:.1}, {:.1} days a year", beyond2, 1.0 / beyond2, beyond2 * DAYS);
    println!("one tail only, above the mean + 2 spreads: {:.4}", 1.0 - phi_series(2.0));
    let z_loss = (LOSS - MU) / SIGMA;
    let p_loss = phi_series(z_loss);
    let p_loss_direct = simpson(&f, lo, LOSS, 4000); // no standardising: the return's own density
    println!("loss worse than 2%: z = ({:.2} - {:.2}) / {:.2} = {:.4}", LOSS, MU, SIGMA, z_loss);
    println!("  Phi(z) by series {:.4}; area under f by Simpson {:.4}", p_loss, p_loss_direct);
    println!("  one day in {:.1}, {:.1} days a year", 1.0 / p_loss, p_loss * DAYS);
    let tail5 = 2.0 * simpson(&phi, 5.0, 12.0, 4000); // both tails beyond five spreads
    println!("beyond five spreads, as the model says: {:.9}, once in {:.0} years", tail5, 1.0 / tail5 / DAYS);

    // what breaks
    println!("mistake 1, mean not subtracted: Phi({:.4}) = {:.4}", LOSS / SIGMA, phi_series(LOSS / SIGMA));
    let zv = (LOSS - MU) / (SIGMA * SIGMA);
    println!("mistake 2, variance used as spread: Phi({:.4}) = {:.4}", zv, phi_series(zv));
    println!("mistake 3, Phi(+z) read for the loss tail: {:.4}", phi_series(-z_loss));

    // road 3: simulate 200,000 days
    let n: usize = 200_000;
    let mut rng = SplitMix(20260928);
    let mut cnt = [0usize; 3];
    let mut lost = 0usize;
    for _ in 0..n / 2 {
        for z in rng.normal_pair() {
            for k in 0..3 {
                if z.abs() > (k + 1) as f64 { cnt[k] += 1 }
            }
            if MU + SIGMA * z < LOSS { lost += 1 }
        }
    }
    println!("simulated {} days, seed 20260928; estimate (standard error)", n);
    let nf = n as f64;
    let mut sim = [(0.0, 0.0); 3];
    for k in 0..3 {
        let p = cnt[k] as f64 / nf;
        sim[k] = (p, (p * (1.0 - p) / nf).sqrt());
        println!("  beyond {} spread(s): {:.4} ({:.4})", k + 1, p, sim[k].1);
    }
    let p_sim = lost as f64 / nf;
    let se_sim = (p_sim * (1.0 - p_sim) / nf).sqrt();
    println!("  loss worse than 2%: {:.4} ({:.4})", p_sim, se_sim);

    // figures: density and cumulative area at half-spread steps
    let zs: Vec<f64> = (-6..7).map(|k| k as f64 / 2.0).collect();
    println!("figure, return %: {}", join(&zs.iter().map(|z| MU + z * SIGMA).collect::<Vec<_>>(), 2));
    println!("figure, density: {}", join(&zs.iter().map(|z| f(MU + z * SIGMA)).collect::<Vec<_>>(), 2));
    println!("figure, cumulative: {}", join(&zs.iter().map(|&z| phi_series(z)).collect::<Vec<_>>(), 3));

    assert!((area - 1.0).abs() < 1e-9 && (mean - MU).abs() < 1e-9 && (var - SIGMA * SIGMA).abs() < 1e-9);
    for z in [-3.0, -1.7083, 0.5, 2.0, 4.0] { // two roads to Phi agree
        assert!((phi_series(z) - phi_simpson(z)).abs() < 1e-10);
    }
    assert!((p_loss - p_loss_direct).abs() < 1e-10); // standardising = integrating f itself
    assert!((tail5 - 2.0 * (1.0 - phi_series(5.0))).abs() < 1e-9);
    for k in 0..3 { // simulation within 4 standard errors
        assert!((sim[k].0 - (2.0 - 2.0 * phi_series((k + 1) as f64))).abs() < 4.0 * sim[k].1);
    }
    assert!((p_sim - p_loss).abs() < 4.0 * se_sim);
    println!("ALL CHECKS PASS");
}
