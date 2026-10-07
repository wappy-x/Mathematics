// Heavy tails -- the check behind the card, std only.
// Fortunes of at least $1 million (units: $ millions) follow Pareto with b = 1, a = 1.5.
// Roads: closed forms; Simpson integration in log-space; a bell curve built from its own
// series; and seeded draws (SplitMix64, seed 2026) that never use the closed forms.
use std::f64::consts::PI;
const A: f64 = 1.5;
const B: f64 = 1.0;

fn simpson<G: Fn(f64) -> f64>(g: G, lo: f64, hi: f64, n: usize) -> f64 {
    let w = (hi - lo) / n as f64;
    let inner: f64 = (1..n).map(|j| (if j % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + j as f64 * w)).sum();
    (g(lo) + g(hi) + inner) * w / 3.0
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }   // standard normal density
fn big_phi(z: f64) -> f64 {                          // area left of z, by its Taylor series
    let (mut term, mut s, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -z * z / 2.0 / n;
        s += term / (2.0 * n + 1.0);
    }
    0.5 + s / (2.0 * PI).sqrt()
}
fn phi_inv(u: f64) -> f64 {                          // bisection on the area
    let (mut lo, mut hi) = (-8.0f64, 8.0f64);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if big_phi(mid) < u { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                   // strictly inside (0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
}
fn frac_se(hits: usize, n: usize) -> (f64, f64) {
    let p = hits as f64 / n as f64;
    (p, (p * (1.0 - p) / n as f64).sqrt())
}
fn pareto_q(u: f64) -> f64 { B * (1.0 - u).powf(-1.0 / A) }
fn avg(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 }
fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (mean, share) = (A * B / (A - 1.0), 0.01f64.powf(1.0 - 1.0 / A));
    println!("Pareto b = {:?}, a = {:?}: mean {:.4}; median {:.4}; P(X > 10) = {:.5}", B, A, mean, pareto_q(0.5), 10f64.powf(-A));
    println!("top 1 percent start at {:.4} and hold {:.4} of all wealth", pareto_q(0.99), share);
    println!("mean fortune above 10 = {:.4}; variance formula at a = 1.5 gives {:.4}", A * 10.0 / (A - 1.0), A * B * B / ((A - 1.0).powi(2) * (A - 2.0)));
    let t_hi = 50.0;                                 // log-space: x = e^t, t from ln(lower) to 50
    let area = simpson(|t| A * (-A * t).exp(), 0.0, t_hi, 20000);
    let top = simpson(|t| A * ((1.0 - A) * t).exp(), pareto_q(0.99).ln(), t_hi, 20000) / mean;
    println!("Simpson: total area {:.9}; top 1 percent share {:.9}", area, top);
    let mut gaps: Vec<f64> = Vec::new();              // Simpson minus closed form, for the asserts
    for r in [10.0f64, 100.0, 1e4, 1e6] {
        let m1 = simpson(|t| A * ((1.0 - A) * t).exp(), 0.0, r.ln(), 4000);
        let m2 = simpson(|t| A * ((2.0 - A) * t).exp(), 0.0, r.ln(), 4000);
        let (c1, c2) = (A / (A - 1.0) * (1.0 - r.powf(1.0 - A)), A / (2.0 - A) * (r.powf(2.0 - A) - 1.0));
        gaps.extend([m1 - c1, m2 - c2]);
        println!("cutoff R = {:>7}: partial mean {:.4} (closed {:.4}); partial E[X^2] {:.4} (closed {:.4})",
                 r as u64, m1, c1, m2, c2);
    }
    let (z75, z99) = (phi_inv(0.75), phi_inv(0.99));
    let sig = (pareto_q(0.75) - pareto_q(0.25)) / (2.0 * z75);   // bell: same mean, same middle half
    let nshare = (0.01 * mean + sig * phi(z99)) / mean;
    let nshare_s = simpson(|x| x * phi((x - mean) / sig) / sig, mean + z99 * sig, mean + 40.0 * sig, 20000) / mean;
    let bell_tail = |x: f64| simpson(phi, (x - mean) / sig, 40.0, 20000);
    let ntail = bell_tail(10.0);
    println!("bell curve: mean {:.4}, sd {:.4}; top 1 percent start at {:.4}, hold {:.4} (Simpson {:.4})", mean, sig, mean + z99 * sig, nshare, nshare_s);
    println!("bell curve: P(X > 10) = {:.3e}; P(X < 0) = {:.5}", ntail, big_phi(-mean / sig));
    let g = |z: f64| 1.0 / (PI * (1.0 + z * z));
    let cm = 4.0 * simpson(g, 0.0, 1.0, 2000);        // w = 1/z folds the tail onto [0, 1]
    println!("Cauchy: total area by folding {:.9}; P(-1 < Z < 1) = {:.6}", cm, 2.0 * simpson(g, 0.0, 1.0, 2000));
    for r in [10.0f64, 100.0, 1000.0] {
        let half = simpson(|t| (2.0 * t).exp() / (PI * (1.0 + (2.0 * t).exp())), -30.0, r.ln(), 20000);
        gaps.push(half - (1.0 + r * r).ln() / (2.0 * PI));
        println!("Cauchy: integral of z g(z) from 0 to {:>4} = {:.4} (closed {:.4})", r as u64, half, (1.0 + r * r).ln() / (2.0 * PI));
    }
    let half_m = 2.0 * simpson(|t| (1.5 * t).exp() / (PI * (1.0 + (2.0 * t).exp())), -60.0, 60.0, 20000);
    println!("Cauchy: E|Z|^0.5 by Simpson {:.6}; closed form 1/cos(pi/4) = {:.6}", half_m, 1.0 / (PI / 4.0).cos());
    let pout_exact = 1.0 - 2.0 * 10f64.atan() / PI;
    println!("Cauchy: cutoffs -R and 2R give {:.4} in the limit, not 0; P(|Z| > 10) = {:.4}", 4f64.ln() / (2.0 * PI), pout_exact);

    let mut rng = SplitMix64 { s: 2026 };
    let (mut xs, mut run): (Vec<f64>, f64) = (Vec::new(), 0.0);
    for i in 1..=1_000_000usize {
        let x = B * rng.uniform().powf(-1.0 / A);    // inverse transform
        xs.push(x); run += x;
        if [10, 100, 1000, 10000, 100000, 1000000].contains(&i) {
            let m = run / i as f64;
            let sd = (xs.iter().map(|v| (v - m) * (v - m)).sum::<f64>() / (i - 1) as f64).sqrt();
            println!("simulated fortunes n = {:>7}: average {:.4}; sample sd {:.4}", i, m, sd);
        }
    }
    let (p10, se10) = frac_se(xs.iter().filter(|&&x| x > 10.0).count(), xs.len());
    let biggest = xs.iter().cloned().fold(0.0f64, f64::max);
    println!("simulated: P(X > 10) = {:.5} (se {:.5}); largest fortune {:.1}", p10, se10, biggest);
    let mut shares = Vec::new();
    for k in 0..10 {                                  // 10 batches of 100,000
        let mut s = xs[k * 100000..(k + 1) * 100000].to_vec();
        s.sort_by(|a, b| b.partial_cmp(a).unwrap());
        shares.push(s[..1000].iter().sum::<f64>() / s.iter().sum::<f64>());
    }
    let sm = avg(&shares);
    let sse = (shares.iter().map(|v| (v - sm) * (v - sm)).sum::<f64>() / 9.0 / 10.0).sqrt();
    println!("simulated: top 1 percent share {:.4} (se {:.4}, from 10 batches of 100000)", sm, sse);
    let (mut ret, mut ratio) = (Vec::new(), Vec::new());
    for _ in 0..100000 {                              // two daily returns, 1.2 percent spread
        let (u1, u2, u3, u4) = (rng.uniform(), rng.uniform(), rng.uniform(), rng.uniform());
        let r1 = 1.2 * (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        let r2 = 1.2 * (-2.0 * u3.ln()).sqrt() * (2.0 * PI * u4).cos();
        ret.push(r1); ratio.push(r1 / r2);
    }
    let (pin, sein) = frac_se(ratio.iter().filter(|z| z.abs() < 1.0).count(), ratio.len());
    let (pout, seout) = frac_se(ratio.iter().filter(|z| z.abs() > 10.0).count(), ratio.len());
    println!("ratio of two returns: P(-1 < Z < 1) = {:.4} (se {:.4}); P(|Z| > 10) = {:.4} (se {:.4})", pin, sein, pout, seout);
    let ns = [10usize, 100, 1000, 10000, 100000];
    for &n in &ns { println!("ratio of two returns, running average n = {:>6}: {:.4}", n, avg(&ratio[..n])); }
    let cav: Vec<f64> = ratio.chunks(100).map(avg).collect();
    let rav: Vec<f64> = ret.chunks(100).map(avg).collect();
    let (pc, sec) = frac_se(cav.iter().filter(|v| v.abs() < 1.0).count(), 1000);
    let (pr, _) = frac_se(rav.iter().filter(|v| v.abs() < 1.2).count(), 1000);
    println!("figure, ratio averages: {}", join(&ns.iter().map(|&n| avg(&ratio[..n])).collect::<Vec<_>>()));
    println!("figure, return averages: {}", join(&ns.iter().map(|&n| avg(&ret[..n])).collect::<Vec<_>>()));
    println!("1000 averages of 100 ratios: P(-1 < avg < 1) = {:.4} (se {:.4}); of 100 returns within 1.2: {:.4}", pc, sec, pr);
    let grid: Vec<f64> = (1..=10).map(|x| x as f64).collect();
    println!("figure, $ millions:  {}", (1..=10).map(|x| x.to_string()).collect::<Vec<_>>().join(", "));
    println!("figure, Pareto %:    {}", join(&grid.iter().map(|x| 100.0 * x.powf(-A)).collect::<Vec<_>>()));
    println!("figure, bell %:      {}", join(&grid.iter().map(|&x| 100.0 * bell_tail(x)).collect::<Vec<_>>()));
    let simp: Vec<f64> = grid.iter().map(|&x| 100.0 * xs[..100000].iter().filter(|&&v| v > x).count() as f64 / 100000.0).collect();
    println!("figure, simulated %: {}", join(&simp));
    assert!((area - 1.0).abs() < 1e-8 && (top - share).abs() < 1e-8);          // integration vs algebra
    assert!(gaps.iter().all(|g| g.abs() < 1e-6));                               // partial moments vs closed forms
    assert!((cm - 1.0).abs() < 1e-9 && (half_m - 2f64.sqrt()).abs() < 1e-6 && (nshare_s - nshare).abs() < 1e-6);
    assert!((p10 - 10f64.powf(-A)).abs() < 4.0 * se10 && (sm - share).abs() < 4.0 * sse);   // simulation vs formula
    assert!((pin - 0.5).abs() < 4.0 * sein && (pout - pout_exact).abs() < 4.0 * seout);
    assert!((pc - 0.5).abs() < 4.0 * sec && pr > 0.99);                         // Cauchy averages never tighten
    println!("ALL CHECKS PASS");
}
