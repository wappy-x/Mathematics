// The reference distributions -- the same check as the Python, in Rust.  No crates.
// Ten bags from a filling machine labelled 500 g, spread unknown; seven bags from a second machine.
// Roads: closed forms (a normal series, finite sums for chi-square, t and F); Simpson's rule on the
// densities; a seeded simulation that weighs whole samples and never uses a chi-square, t or F formula.
use std::f64::consts::PI;

const LABEL: f64 = 500.0;
const SIGMA: f64 = 3.0;

fn summary(xs: &[f64]) -> (usize, f64, f64) {      // size, mean, sample variance with n - 1
    let n = xs.len();
    let m = xs.iter().sum::<f64>() / n as f64;
    (n, m, xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (n - 1) as f64)
}
fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() }
fn big_phi(x: f64) -> f64 {                        // 1/2 + phi(x) (x + x^3/3 + x^5/15 + ...)
    let (mut term, mut s) = (x, x);
    for j in 1..200 { term *= x * x / (2 * j + 1) as f64; s += term; }
    0.5 + phi(x) * s
}
fn gam(h2: u32) -> f64 {                           // Gamma(h2 / 2), for a whole number h2 >= 1
    let (mut g, mut h) = if h2 % 2 == 1 { (PI.sqrt(), 0.5) } else { (1.0, 1.0) };
    while h < h2 as f64 / 2.0 { g *= h; h += 1.0; }
    g
}
fn chi_d(x: f64, k: u32) -> f64 {                  // chi-square density: Gamma(k/2, rate 1/2)
    let kf = k as f64;
    x.powf(kf / 2.0 - 1.0) * (-x / 2.0).exp() / (2f64.powf(kf / 2.0) * gam(k))
}
fn t_d(t: f64, v: u32) -> f64 {
    let vf = v as f64;
    gam(v + 1) / ((vf * PI).sqrt() * gam(v)) * (1.0 + t * t / vf).powf(-(vf + 1.0) / 2.0)
}
fn f_d(x: f64, v1: u32, v2: u32) -> f64 {          // F density, with c = v1 / v2
    let (a, b) = (v1 as f64, v2 as f64);
    gam(v1 + v2) / (gam(v1) * gam(v2)) * (a / b).powf(a / 2.0) * x.powf(a / 2.0 - 1.0)
        * (1.0 + a * x / b).powf(-(a + b) / 2.0)
}
fn chi_tail(x: f64, k: u32) -> f64 {               // P(V > x): Poisson sum (even k), normal road (odd k)
    if k % 2 == 0 {
        let (mut term, mut s) = (1.0, 1.0);
        for j in 1..k / 2 { term *= x / 2.0 / j as f64; s += term; }
        return (-x / 2.0).exp() * s;
    }
    let (mut term, mut s) = (x.sqrt(), 0.0);
    for r in 1..=(k - 1) / 2 { s += term; term *= x / (2 * r + 1) as f64; }
    2.0 * (1.0 - big_phi(x.sqrt())) + 2.0 * phi(x.sqrt()) * s
}
fn t_tail2(t: f64, v: u32) -> f64 {                // P(|T| > t), odd v, through the angle atan(t / sqrt v)
    let th = (t / (v as f64).sqrt()).atan();
    let (c, mut w, mut s) = (th.cos(), 1.0, 0.0);
    for j in 0..(v - 1) / 2 { s += w * c.powi(2 * j as i32 + 1); w *= (2 * j + 2) as f64 / (2 * j + 3) as f64; }
    1.0 - 2.0 / PI * (th + th.sin() * s)
}
fn beta_cdf(y: f64, a: f64, b: f64) -> f64 {       // needs a whole number a or b
    if b != b.trunc() { return 1.0 - beta_cdf(1.0 - y, b, a); }
    let (mut term, mut s) = (1.0, 1.0);
    for j in 1..b as u32 { term *= (a + j as f64 - 1.0) / j as f64 * (1.0 - y); s += term; }
    y.powf(a) * s
}
fn f_tail(x: f64, v1: u32, v2: u32) -> f64 {       // P(F > x), through the beta variable cF / (1 + cF)
    let (a, b) = (v1 as f64, v2 as f64);
    1.0 - beta_cdf(a * x / (b + a * x), a / 2.0, b / 2.0)
}
fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64) -> f64 {
    let (n, h) = (4000, (hi - lo) / 4000.0);
    h / 3.0 * (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(lo + i as f64 * h)).sum::<f64>()
}
fn bisect(g: &dyn Fn(f64) -> f64, target: f64, mut lo: f64, mut hi: f64) -> f64 {   // g decreasing
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if g(mid) > target { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}
struct Rng(u64);                                   // SplitMix64, seed 20260928
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normals(&mut self, k: usize) -> Vec<f64> {  // Box-Muller, two at a time
        let mut out = Vec::new();
        while out.len() < k {
            let r = (-2.0 * self.uniform().ln()).sqrt();
            let a = 2.0 * PI * self.uniform();
            out.push(r * a.cos());
            out.push(r * a.sin());
        }
        out.truncate(k);
        out
    }
}
fn join(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let a: Vec<f64> = [507, 498, 505, 500, 503, 502, 501, 497, 505, 502].iter().map(|&x| x as f64).collect();
    let b: Vec<f64> = [503, 498, 501, 498, 502, 499, 499].iter().map(|&x| x as f64).collect();
    let ((n, m, s2), (nb, mb, s2b)) = (summary(&a), summary(&b));
    let se = (s2 / n as f64).sqrt();
    let (t_obs, q_obs, f_obs) = ((m - LABEL) / se, (n - 1) as f64 * s2 / SIGMA.powi(2), s2 / s2b);
    println!("machine one: n {}, mean {:.3}, squared residuals {:.1}, S^2 {:.3}, S {:.3}, S/sqrt(n) {:.3}", n, m, s2 * (n - 1) as f64, s2, s2.sqrt(), se);
    println!("machine two: n {}, mean {:.3}, squared residuals {:.1}, S^2 {:.3}", nb, mb, s2b * (nb - 1) as f64, s2b);
    println!("observed: t {:.3} on 9; V = 9 S^2/3^2 {:.3} on 9; F = S1^2/S2^2 {:.3} on (9, 6)", t_obs, q_obs, f_obs);
    let (p_t, p_q, p_f) = (t_tail2(t_obs, 9), chi_tail(q_obs, 9), f_tail(f_obs, 9, 6));
    let s_t = 1.0 - 2.0 * simpson(&|x| t_d(x, 9), 0.0, t_obs);
    let s_q = 1.0 - simpson(&|x| chi_d(x, 9), 0.0, q_obs);
    let s_f = 1.0 - simpson(&|x| f_d(x, 9, 6), 0.0, f_obs);
    println!("P(|T| > 2) on 9: closed form {:.4}; Simpson {:.4}; normal instead {:.4}", p_t, s_t, 2.0 * (1.0 - big_phi(2.0)));
    println!("P(V > 10) on 9: closed form {:.4}; Simpson {:.4}. P(F > 2.5) on (9, 6): beta sum {:.4}; Simpson {:.4}", p_q, s_q, p_f, s_f);
    println!("Gamma(1/2) {:.6}; Gamma(9/2) {:.6}; area under t on 9 {:.6}", gam(1), gam(9), 2.0 * simpson(&|x| t_d(x, 9), 0.0, 60.0));
    let q_t = bisect(&|x| t_tail2(x, 9), 0.05, 0.0, 20.0);
    let (q_lo, q_hi) = (bisect(&|x| chi_tail(x, 9), 0.975, 0.0, 60.0), bisect(&|x| chi_tail(x, 9), 0.025, 0.0, 60.0));
    let (q_95, f_95) = (bisect(&|x| chi_tail(x, 9), 0.05, 0.0, 60.0), bisect(&|x| f_tail(x, 9, 6), 0.05, 0.0, 60.0));
    println!("cutoffs: t on 9, 2.5% each side {:.3}; normal {:.3}", q_t, bisect(&|x| 2.0 * (1.0 - big_phi(x)), 0.05, 0.0, 10.0));
    println!("cutoffs: chi-square 9, middle 95% {:.3} to {:.3}, top 5% {:.3}; F (9, 6) top 5% {:.3}", q_lo, q_hi, q_95, f_95);
    println!("P(|T| > 1.96): t on 9 {:.4}; t on 1 (Cauchy) P(|T| > 2) {:.4}", t_tail2(1.96, 9), t_tail2(2.0, 1));
    let big_n = 100_000;
    let mut rng = Rng(20260928);
    let (mut c_t, mut c_z, mut c_q, mut c_f, mut c_sk, mut c_st) = (0, 0, 0, 0, 0, 0);
    let (mut sq, mut sq2, mut st2, mut st4, mut sf, mut sf2) = (0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    for _ in 0..big_n {
        let (_, ma, va) = summary(&rng.normals(10).iter().map(|z| LABEL + SIGMA * z).collect::<Vec<_>>());
        let (_, _, vb) = summary(&rng.normals(7).iter().map(|z| LABEL + SIGMA * z).collect::<Vec<_>>());
        let (_, me, ve) = summary(&(0..10).map(|_| LABEL - SIGMA - SIGMA * rng.uniform().ln()).collect::<Vec<_>>());
        let (t, q, f) = ((ma - LABEL) / (va / 10.0).sqrt(), 9.0 * va / SIGMA.powi(2), va / vb);
        c_t += (t.abs() > 2.0) as u32; c_z += (t.abs() > 1.96) as u32; c_q += (q > 10.0) as u32; c_f += (f > 2.5) as u32;
        c_sk += (9.0 * ve / SIGMA.powi(2) > q_95) as u32; c_st += (((me - LABEL) / (ve / 10.0).sqrt()).abs() > q_t) as u32;
        sq += q; sq2 += q * q; st2 += t * t; st4 += t.powi(4); sf += f; sf2 += f * f;
    }
    let nf = big_n as f64;
    let est = |c: u32| (c as f64 / nf, (c as f64 / nf * (1.0 - c as f64 / nf) / nf).sqrt());   // a share and its standard error
    let ((r_t, e_t), (r_z, e_z), (r_q, e_q), (r_f, e_f), (r_sk, e_sk), (r_st, e_st)) = (est(c_t), est(c_z), est(c_q), est(c_f), est(c_sk), est(c_st));
    let (mq, vq) = (sq / nf, sq2 / nf - (sq / nf).powi(2));
    let (mt2, et2, mf, ef) = (st2 / nf, ((st4 / nf - (st2 / nf).powi(2)) / nf).sqrt(), sf / nf, ((sf2 / nf - (sf / nf).powi(2)) / nf).sqrt());
    println!("simulated {} rounds of 10 + 7 bags, true mean 500, sigma 3, seed 20260928; estimate (standard error)", big_n);
    println!("  P(|T| > 2) {:.4} ({:.4}); P(V > 10) {:.4} ({:.4}); P(F > 2.5) {:.4} ({:.4})", r_t, e_t, r_q, e_q, r_f, e_f);
    println!("  V: mean {:.3} ({:.3}), variance {:.3}; T: mean square {:.4} ({:.4}), formula 9/7 = {:.4}; F: mean {:.4} ({:.4}), formula 6/4 = {:.4}",
             mq, (vq / nf).sqrt(), vq, mt2, et2, 9.0 / 7.0, mf, ef, 6.0 / 4.0);
    println!("mistake, cutoff 1.96 with an estimated spread: true label rejected {:.4} ({:.4}), closed form {:.4}", r_z, e_z, t_tail2(1.96, 9));
    println!("mistake, 10 degrees of freedom for 9: P(V > 10) {:.4}, not {:.4}", chi_tail(10.0, 10), p_q);
    println!("mistake, F read on (6, 9) for (9, 6): P(F > 2.5) {:.4}, not {:.4}", f_tail(2.5, 6, 9), p_f);
    println!("mistake, skewed bags (exponential, same mean and sd): 5% chi-square test rejects {:.4} ({:.4}); 5% t test {:.4} ({:.4})", r_sk, e_sk, r_st, e_st);
    let xs: Vec<f64> = (-8..=8).map(|i| 0.5 * i as f64).collect();
    println!("figure, t: {}", join(&xs, 1));
    println!("figure, normal: {}", join(&xs.iter().map(|&x| phi(x)).collect::<Vec<_>>(), 2));
    println!("figure, t on 9: {}", join(&xs.iter().map(|&x| t_d(x, 9)).collect::<Vec<_>>(), 2));
    println!("figure, t on 2: {}", join(&xs.iter().map(|&x| t_d(x, 2)).collect::<Vec<_>>(), 2));
    let vs: Vec<f64> = (0..13).map(|i| 2.0 * i as f64).collect();
    println!("figure, v: {}", join(&vs, 0));
    for k in [3, 9] {
        println!("figure, chi-square {}: {}", k, join(&vs.iter().map(|&v| chi_d(v, k)).collect::<Vec<_>>(), 2));
    }
    assert!((p_t - s_t).abs() < 1e-9 && (p_q - s_q).abs() < 1e-9 && (p_f - s_f).abs() < 1e-9);   // closed forms against Simpson
    assert!((chi_tail(10.0, 10) - (1.0 - simpson(&|x| chi_d(x, 10), 0.0, 10.0))).abs() < 1e-9);
    assert!((f_tail(2.5, 6, 9) - (1.0 - simpson(&|x| f_d(x, 6, 9), 0.0, 2.5))).abs() < 1e-9);   // the swapped-beta branch
    assert!((r_t - p_t).abs() < 4.0 * e_t && (r_q - p_q).abs() < 4.0 * e_q && (r_f - p_f).abs() < 4.0 * e_f);
    assert!((mq - 9.0).abs() < 4.0 * (vq / nf).sqrt() && (vq - 18.0).abs() < 0.42);   // nine squares: mean 9, variance 18 (SE 0.104)
    assert!((r_z - t_tail2(1.96, 9)).abs() < 4.0 * e_z && (mt2 - 9.0 / 7.0).abs() < 4.0 * et2 && (mf - 1.5).abs() < 4.0 * ef);
    assert!(r_sk - 0.05 > 4.0 * e_sk);                  // skewed bags break the 5 percent promise
    assert!(r_st - 0.05 > 4.0 * e_st);                  // the t test's too, at ten bags
    println!("ALL CHECKS PASS");
}
