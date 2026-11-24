// Rao-Blackwell and Lehmann-Scheffe -- the same check in Rust, std only.
// Five hours of help-desk calls: 2, 3, 0, 1, 4, total T = 10.  Each hour's count
// is Poisson with unknown rate lam; the target is e^(-lam), the chance of an
// empty hour.  Roads: closed forms; every split of a total, enumerated; a seeded
// simulation (SplitMix64, same seed); a search of unbiased rules; the house poll.
const N: usize = 5;

struct Rng(u64);
impl Rng {
    fn next64(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next64() >> 11) as f64 / 9007199254740992.0 }
    fn draw(&mut self, lam: f64) -> u32 {
        let (u, mut k, mut p) = (self.unif(), 0u32, (-lam).exp());
        let mut c = p;
        while u > c { k += 1; p *= lam / k as f64; c += p; }
        k
    }
}

fn fact(k: u32) -> f64 { (1..=k).fold(1.0, |a, i| a * i as f64) }
fn pois(lam: f64, k: u32) -> f64 { (-lam).exp() * lam.powf(k as f64) / fact(k) }
fn splits(t: u32, parts: usize) -> Vec<Vec<u32>> {
    if parts == 1 { return vec![vec![t]]; }
    let mut out = Vec::new();
    for first in 0..=t {
        for rest in splits(t - first, parts - 1) { out.push([vec![first], rest].concat()); }
    }
    out
}
fn row(label: &str, x: f64) { println!("{:<46}{:.6}", label, x); }
fn first(x: &[u32]) -> f64 { if x[0] == 0 { 1.0 } else { 0.0 } }
fn share(x: &[u32]) -> f64 { x.iter().filter(|&&v| v == 0).count() as f64 / N as f64 }
fn cond_mean(rule: fn(&[u32]) -> f64, t: u32, lam: f64) -> f64 {
    let (mut num, mut den) = (0.0, 0.0);
    for x in splits(t, N) {
        let w = x.iter().fold(1.0, |a, &xi| a * pois(lam, xi));
        num += rule(&x) * w;
        den += w;
    }
    num / den
}
fn lgam(x: f64) -> f64 {                        // log of the gamma function, Lanczos
    let g = [676.5203681218851, -1259.1392167224028, 771.32342877765313, -176.61502916214059,
        12.507343278686905, -0.13857109526572012, 9.9843695780195716e-6, 1.5056327351493116e-7];
    let (x, mut a) = (x - 1.0, 0.99999999999980993);
    for (i, c) in g.iter().enumerate() { a += c / (x + i as f64 + 1.0); }
    let t = x + 7.5;
    0.5 * (2.0 * std::f64::consts::PI).ln() + (x + 0.5) * t.ln() - t + a.ln()
}

fn main() {
    let mut rng = Rng(20261123);
    let (counts, lam0) = ([2u32, 3, 0, 1, 4], 2.0f64);
    let (nf, t_obs) = (N as f64, counts.iter().sum::<u32>());
    let rb = (1.0 - 1.0 / nf).powf(t_obs as f64);
    println!("data: counts 2 3 0 1 4, total T = {}", t_obs);
    row("crude rule: was hour 1 empty?", first(&counts));
    row("fraction of empty hours", share(&counts));
    row("plug-in e^(-T/5)", (-(t_obs as f64) / nf).exp());
    row("1 Rao-Blackwell (4/5)^T, formula", rb);
    for lam in [0.7, 2.0, 3.5] {
        let c = cond_mean(first, t_obs, lam);
        row(&format!("2 E[crude | T=10] by enumeration, lam={:?}", lam), c);
        assert!((c - rb).abs() < 1e-12);
    }
    let cf = cond_mean(share, t_obs, lam0);
    row("2 E[fraction | T=10] by enumeration", cf);
    assert!((cf - rb).abs() < 1e-12);
    let theta = (-lam0).exp();
    let pt: Vec<f64> = (0..120).map(|t| pois(nf * lam0, t)).collect();
    let m: Vec<f64> = (0..120).map(|t| (1.0 - 1.0 / nf).powf(t as f64)).collect();
    let mean_rb: f64 = (0..120).map(|t| pt[t] * m[t]).sum();
    let var_rb = (0..120).map(|t| pt[t] * m[t] * m[t]).sum::<f64>() - mean_rb * mean_rb;
    let inner: f64 = (0..120).map(|t| pt[t] * (m[t] - m[t] * m[t])).sum();
    let (var_crude, var_frac) = (theta * (1.0 - theta), theta * (1.0 - theta) / nf);
    let var_form = (-2.0 * lam0).exp() * ((lam0 / nf).exp() - 1.0);
    let cr = lam0 * (-2.0 * lam0).exp() / nf;
    let plug: f64 = (0..120).map(|t| pt[t] * (-(t as f64) / nf).exp()).sum();
    println!("at true rate lam = 2, target e^(-2) = {:.6}", theta);
    row("mean of (4/5)^T, sum over T", mean_rb);
    println!("  e^(-2 lam) = {:.6}  e^(lam/n) - 1 = {:.6}  1 - theta = {:.6}", (-2.0 * lam0).exp(), (lam0 / nf).exp() - 1.0, 1.0 - theta);
    row("variance of crude rule theta(1-theta)", var_crude);
    row("  average leftover variance E[Var(W|T)]", inner);
    row("  variance of (4/5)^T, sum over T", var_rb);
    row("  variance of (4/5)^T, formula", var_form);
    row("variance of fraction of empty hours", var_frac);
    row("Cramer-Rao floor lam e^(-2 lam)/n", cr);
    row("efficiency floor / variance of (4/5)^T", cr / var_rb);
    row("mean of plug-in e^(-T/5), sum over T", plug);
    row("  closed form exp(n lam (e^(-1/n) - 1))", (nf * lam0 * ((-1.0 / nf).exp() - 1.0)).exp());
    assert!((mean_rb - theta).abs() < 1e-12 && (var_rb - var_form).abs() < 1e-12);
    assert!((inner + var_rb - var_crude).abs() < 1e-12);
    assert!(var_rb > cr && var_rb < var_frac && var_frac < var_crude && plug - theta > 0.02);
    row("E[crude | X2] at lam = 1 (not a statistic)", pois(1.0, 0));
    row("E[crude | X2] at lam = 2", pois(2.0, 0));
    let (r, mut s) = (200000usize, [[0.0f64; 2]; 3]);
    for _ in 0..r {
        let x: Vec<u32> = (0..N).map(|_| rng.draw(lam0)).collect();
        let vals = [first(&x), share(&x), (1.0 - 1.0 / nf).powf(x.iter().sum::<u32>() as f64)];
        for i in 0..3 { s[i][0] += vals[i]; s[i][1] += vals[i] * vals[i]; }
    }
    let (names, exact) = (["crude", "fraction", "(4/5)^T"], [var_crude, var_frac, var_rb]);
    for i in 0..3 {
        let (rf, mu) = (r as f64, s[i][0] / r as f64);
        let var = s[i][1] / rf - mu * mu;
        println!("3 simulated {:<9} mean {:.6}  variance {:.6}", names[i], mu, var);
        assert!((mu - theta).abs() < 4.0 * (var / rf).sqrt() && (var - exact[i]).abs() < 0.05 * exact[i]);
    }
    let groups: Vec<Vec<f64>> = (0..9u32).map(|t| splits(t, N).iter()
        .map(|x| fact(t) / (nf.powf(t as f64) * x.iter().fold(1.0, |a, &v| a * fact(v)))).collect()).collect();
    let (mut best, mut worst_bias) = (1.0f64, 0.0f64);
    for _ in 0..300 {
        let size = 0.2 * rng.unif();
        let mut noise: Vec<Vec<f64>> = Vec::new();
        for wt in &groups {
            let u: Vec<f64> = wt.iter().map(|_| size * (2.0 * rng.unif() - 1.0)).collect();
            let c: f64 = u.iter().zip(wt).map(|(a, b)| a * b).sum();
            noise.push(u.iter().map(|a| a - c).collect());
        }
        let mut ex2: f64 = (9..120).map(|t| pt[t] * m[t] * m[t]).sum();
        for (t, wt) in groups.iter().enumerate() {
            ex2 += pt[t] * wt.iter().zip(&noise[t]).map(|(w, a)| w * (m[t] + a) * (m[t] + a)).sum::<f64>();
        }
        best = best.min(ex2 - theta * theta);
        for lam in [0.5, 2.0, 3.5] {
            let mut mean: f64 = (0..120).map(|t| pois(nf * lam, t as u32) * m[t]).sum();
            for (t, wt) in groups.iter().enumerate() {
                for (w, a) in wt.iter().zip(&noise[t]) { mean += pois(nf * lam, t as u32) * w * a; }
            }
            worst_bias = worst_bias.max((mean - (-lam).exp()).abs());
        }
    }
    row("4 search: 300 unbiased rules, least variance", best);
    row("  largest bias at lam = 0.5, 2, 3.5", worst_bias);
    assert!(best >= var_rb - 1e-12 && worst_bias < 1e-12);
    let (n, k) = (1000.0f64, 520.0f64);
    let umvue = k * (n - k) / (n * (n - 1.0));
    let count = (lgam(n - 1.0) - lgam(k) - lgam(n - k) - lgam(n + 1.0) + lgam(k + 1.0) + lgam(n - k + 1.0)).exp();
    row("poll: P(1 yes, 2 no | K=520) by counting", count);
    row("  formula K(n-K)/(n(n-1))", umvue);
    row("  plug-in p-hat(1-p-hat)", 0.52 * 0.48);
    let (mut mean_u, mut mean_plug) = (0.0, 0.0);
    for j in 0..=1000 {
        let jf = j as f64;
        let lp = lgam(n + 1.0) - lgam(jf + 1.0) - lgam(n - jf + 1.0) + jf * 0.52f64.ln() + (n - jf) * 0.48f64.ln();
        mean_u += lp.exp() * jf * (n - jf) / (n * (n - 1.0));
        mean_plug += lp.exp() * jf * (n - jf) / (n * n);
    }
    row("  mean of K(n-K)/(n(n-1)) at p = 0.52", mean_u);
    row("  mean of plug-in at p = 0.52", mean_plug);
    assert!((count - umvue).abs() < 1e-9);
    for nn in [5.0f64, 10.0, 20.0, 50.0] {
        println!("n = {:2} hours: efficiency at lam = 2  {:.6}", nn as u32, (lam0 / nn) / ((lam0 / nn).exp() - 1.0));
    }
    let lams: Vec<f64> = (1..9).map(|i| 0.5 * i as f64).collect();
    let join = |f: &dyn Fn(f64) -> String| lams.iter().map(|&v| f(v)).collect::<Vec<_>>().join(" ");
    println!("chart, lam       {}", join(&|v| format!("{:.2}", v)));
    println!("chart, (4/5)^T   {}", join(&|v| format!("{:.3}", (v / nf) / ((v / nf).exp() - 1.0))));
    println!("chart, fraction  {}", join(&|v| format!("{:.3}", v / (v.exp() - 1.0))));
    println!("ALL CHECKS PASS");
}
