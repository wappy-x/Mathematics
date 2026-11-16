// Stable laws and heavy tails -- the check behind the card.
// Lighthouse: d = 1 km off a straight shore, flashes at a uniform random angle;
// a hit lands at x0 + d tan(angle): Cauchy errors, fingerprint exp(-d|t|).
// Roads: closed forms against defining integrals, series, inversion and simulation.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn add(a: C, b: C) -> C { c(a.re + b.re, a.im + b.im) }
fn sub(a: C, b: C) -> C { c(a.re - b.re, a.im - b.im) }
fn mul(a: C, b: C) -> C { c(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re) }
fn scale(a: C, k: f64) -> C { c(a.re * k, a.im * k) }
fn cexp(a: C) -> C { let l = a.re.exp(); c(l * a.im.cos(), l * a.im.sin()) }
fn cabs(a: C) -> f64 { a.re.hypot(a.im) }
fn sum(xs: &[f64]) -> f64 { let mut t = 0.0; for x in xs { t += x; } t }
fn simpson_c(f: &dyn Fn(f64) -> C, a: f64, b: f64, m: usize) -> C {
    let h = (b - a) / m as f64;
    let mut s = add(f(a), f(b));
    for k in 1..m { s = add(s, scale(f(a + k as f64 * h), if k % 2 == 1 { 4.0 } else { 2.0 })); }
    scale(s, h / 3.0)
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 { simpson_c(&|x| c(f(x), 0.0), a, b, m).re }
fn big_phi(x: f64) -> f64 {
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 { k += 1.0; term *= -x * x / (2.0 * k); total += term / (2.0 * k + 1.0); }
    0.5 + total / (2.0 * PI).sqrt()
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn hit(&mut self) -> f64 { D * (PI * (self.unif() - 0.5)).tan() }
    fn gauss(&mut self) -> f64 {
        let r = (-2.0 * (1.0 - self.unif()).ln()).sqrt();
        r * (2.0 * PI * self.unif()).cos()
    }
}
const D: f64 = 1.0; const N_HITS: usize = 100;
fn sorted(v: &[f64]) -> Vec<f64> { let mut w = v.to_vec(); w.sort_by(|a, b| a.partial_cmp(b).unwrap()); w }
fn semi_iqr(v: &[f64]) -> f64 { let w = sorted(v); (w[3 * w.len() / 4] - w[w.len() / 4]) / 2.0 }
fn median(v: &[f64]) -> f64 {
    let (w, m) = (sorted(v), v.len() / 2);
    if v.len() % 2 == 1 { w[m] } else { (w[m - 1] + w[m]) / 2.0 }
}
const A: f64 = 1.5; const MU: f64 = 3.0; const NF: usize = 1000;
fn ca() -> C { scale(c(1.0, 1.0), -(2.0 * PI).sqrt()) }
fn phi_pareto(s: f64) -> C {
    let mut total = add(c(1.0, s * MU), scale(ca(), s.powf(A)));
    let (mut k, mut term) = (2.0, c(-s * s / 2.0, 0.0));
    while cabs(term) > 1e-18 {
        total = sub(total, scale(term, A / (k - A)));
        k += 1.0;
        term = mul(term, c(0.0, s / k));
    }
    total
}
fn limit(t: f64) -> C { cexp(scale(ca(), t.powf(A))) }
fn exact(t: f64) -> C {
    let s = t / (NF as f64).powf(1.0 / A);
    let w = mul(cexp(c(0.0, -MU * s)), phi_pareto(s));
    cexp(scale(c(cabs(w).ln(), w.im.atan2(w.re)), NF as f64))
}
fn exact2(t: f64, fv: &dyn Fn(f64) -> C) -> C { // road 2: quadrature from 0 to s in place of the series; own centre A/(A-1)
    let (s, m) = (t / (NF as f64).powf(2.0 / 3.0), A / (A - 1.0));
    let w = mul(cexp(c(0.0, -m * s)), add(c(1.0, m * s), scale(sub(ca(), simpson_c(fv, 0.0, s.sqrt(), 40)), s.powf(A))));
    cexp(scale(c(cabs(w).ln(), w.im.atan2(w.re)), NF as f64))
}
fn cdf(phi: &dyn Fn(f64) -> C, z: f64) -> f64 {
    let g = |s: f64| if s == 0.0 { 0.0 } else { 2.0 * mul(cexp(c(0.0, -s * s * z)), phi(s * s)).im / s };
    0.5 - simpson(&g, 0.0, 4.0, 4000) / PI
}
fn main() {
    let mut rng = Rng(20261115);
    let (mut lo, mut hi) = (0.0f64, 3.0f64);
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if big_phi(mid) < 0.75 { lo = mid } else { hi = mid } }
    let med_k = lo * PI / 2.0;
    // 1. Cauchy: fingerprint, stability, chances
    let cut = 1000.0;
    let by_int = 2.0 * simpson(&|x: f64| x.cos() / (PI * (1.0 + x * x)), 0.0, cut, 400000);
    println!("Cauchy, d = {:.0} km: fingerprint at t = 1 per km: closed form exp(-1) = {:.6}", D, (-1.0f64).exp());
    println!("  defining integral to |x| = 1000: {:.6} (tail at most {:.7})", by_int, 4.0 / (PI * (1.0 + cut * cut)));
    let lap = 2.0 * simpson(&|x: f64| x.cos() * 0.5 * (-x).exp(), 0.0, 40.0, 40000);
    println!("  duality: Laplace law's fingerprint at t = 1 is {:.6} = 1/(1 + 1) = 0.5", lap);
    let one = (-D / N_HITS as f64).exp();
    println!("mean of {} hits at t = 1: exp(-1/{}) = {:.6}; to the {}th = {:.6}", N_HITS, N_HITS, one, N_HITS, one.powf(N_HITS as f64));
    println!("  sum of {} over sqrt({}) at t = 1: exp(-sqrt({})) = {:.6}", N_HITS, N_HITS, N_HITS, (-(N_HITS as f64).sqrt()).exp());
    for a in [1.0f64, 3.0] {
        println!("  P(|mean error| > {} km) = 1 - (2/pi) atan({}) = {:.6}", a, a, 1.0 - 2.0 * (a / D).atan() / PI);
    }
    println!("n, middle-half half-width (km) of 1000 means, of 1000 medians, large-n median {:.6} pi/2/sqrt(n) = {:.6}/sqrt(n)", lo, med_k);
    let mut widths = vec![];
    for n in [1usize, 10, 100, 1000] {
        let (mut means, mut meds, mut far) = (vec![], vec![], 0);
        for _ in 0..1000 {
            let xs: Vec<f64> = (0..n).map(|_| rng.hit()).collect();
            means.push(sum(&xs) / n as f64);
            meds.push(median(&xs));
            if means[means.len() - 1].abs() > 1.0 { far += 1; }
        }
        widths.push((n, semi_iqr(&means), semi_iqr(&meds)));
        println!("  {:4}  {:.6}  {:.6}  {:.6}  beyond 1 km: {:.3}", n, semi_iqr(&means), semi_iqr(&meds),
                 med_k * D / (n as f64).sqrt(), far as f64 / 1000.0);
    }
    // 2. Index above 2 is no law: invert exp(-|t|^3)
    let neg = simpson(&|t: f64| (4.5 * t).cos() * (-t.powf(3.0)).exp(), 0.0, 6.0, 6000) / PI;
    let pos: Vec<f64> = [2.0, 1.0].iter().map(|&a| simpson(&|t: f64| (4.5 * t).cos() * (-t.powf(a)).exp(), 0.0, 60.0, 60000) / PI).collect();
    println!("inverse of exp(-|t|^a) at x = 4.5: a = 3 {:.6}; a = 2 {:.6}; a = 1 {:.6}", neg, pos[0], pos[1]);
    println!("die: variance 35/12 = {:.6} (finite), so dice totals over sqrt(n) go to the bell, index 2", 35.0 / 12.0);
    // 3. Levy waits: first time a 20 %-a-year Brownian log price climbs 0.1; c = (0.1/0.2)^2 years
    let c_l = (0.1f64 / 0.2).powf(2.0);
    let med1 = c_l / lo.powf(2.0);
    let waits: Vec<f64> = (0..40000).map(|_| c_l / rng.gauss().powf(2.0)).collect();
    let avgs: Vec<f64> = (0..4000).map(|k| sum(&waits[10 * k..10 * k + 10]) / 10.0).collect();
    let cs: Vec<f64> = waits.iter().map(|w| w.cos()).collect();
    let ss: Vec<f64> = waits.iter().map(|w| w.sin()).collect();
    let fp = c(sum(&cs) / 40000.0, sum(&ss) / 40000.0);
    let fp_cf = cexp(scale(c(1.0, -1.0), -c_l.sqrt()));
    println!("Levy, c = {:.2} years: median wait c/0.674490^2 = {:.4} (simulated {:.4})", c_l, med1, median(&waits));
    println!("  average of 10 waits: median 10 x {:.4} = {:.4} (simulated {:.4})", med1, 10.0 * med1, median(&avgs));
    println!("  fingerprint at t = 1 per year: closed form {:.4} + {:.4}i; simulated {:.4} + {:.4}i", fp_cf.re, fp_cf.im, fp.re, fp.im);
    // 4. The generalised limit theorem: Pareto fortunes, shape 1.5, cutoff $1 million, mean 3
    let v_cut = 30.0;
    let f = |v: f64| if v > 0.0 { scale(sub(sub(cexp(c(0.0, v * v)), c(1.0, 0.0)), c(0.0, v * v)), 3.0 / v.powf(4.0)) } else { c(-1.5, 0.0) };
    let num = add(simpson_c(&f, 0.0, v_cut, 60000), c(-1.0 / v_cut.powf(3.0), -3.0 / v_cut));
    println!("limit constant: closed form {:.6} {:+.6}i; by integral {:.6} {:+.6}i", ca().re, ca().im, num.re, num.im);
    let s0 = 0.1;
    let direct = simpson_c(&|x: f64| scale(cexp(c(0.0, s0 * x)), A * x.powf(-A - 1.0)), 1.0, 1000.0, 200000);
    let ps = phi_pareto(s0);
    println!("Pareto fingerprint at s = 0.1: series {:.6} {:+.6}i; integral to 1000 {:.6} {:+.6}i", ps.re, ps.im, direct.re, direct.im);
    let nf = NF as f64;
    let zs_sim: Vec<f64> = (0..4000).map(|_| {
        let xs: Vec<f64> = (0..NF).map(|_| (1.0 - rng.unif()).powf(-1.0 / A)).collect();
        (sum(&xs) - MU * nf) / nf.powf(1.0 / A)
    }).collect();
    println!("average of {} fortunes = 3 + Z/{:.0}; gamma = (2 pi)^(1/3) = {:.6}", NF, nf.powf(1.0 - 1.0 / A), (2.0 * PI).powf(1.0 / 3.0));
    println!("Z at most, average at most, P limit, P exact n = {}, P simulated (4000 runs)", NF);
    let mut rows = vec![];
    for z in [-1.0f64, 0.0, 2.0, 5.0] {
        let r = (cdf(&limit, z), cdf(&exact, z), zs_sim.iter().filter(|&&x| x <= z).count() as f64 / 4000.0, cdf(&|t: f64| exact2(t, &f), z));
        println!("  {:2}  {:.1}  {:.4}  {:.4}  {:.4}", z, MU + z / 10.0, r.0, r.1, r.2);
        rows.push((z, r));
    }
    println!("exact column again, by quadrature in place of the series: every gap below 1e-6: {}", if rows.iter().all(|(_, r)| (r.3 - r.1).abs() < 1e-6) { "yes" } else { "no" });
    println!("chart n, means, medians");
    let m: Vec<String> = widths.iter().map(|w| format!("{:.3}", w.1)).collect();
    let d: Vec<String> = widths.iter().map(|w| format!("{:.3}", w.2)).collect();
    println!("  {} | {}", m.join(", "), d.join(", "));
    assert!((by_int - (-1.0f64).exp()).abs() < 1e-5);
    assert!((lap - 0.5).abs() < 1e-9);
    assert!(widths.iter().all(|w| (w.1 - D).abs() < 0.2));
    assert!((widths[3].2 - med_k * D / 1000f64.sqrt()).abs() < 0.01);
    assert!(neg < -0.01);
    assert!(pos.iter().all(|&p| p > 0.0));
    assert!((pos[1] - 1.0 / (PI * (1.0 + 4.5 * 4.5))).abs() < 1e-6);
    assert!((median(&avgs) - 10.0 * med1).abs() < 0.6);
    assert!(cabs(sub(fp, fp_cf)) < 0.02);
    assert!(cabs(sub(num, ca())) < 1e-4);
    assert!(cabs(sub(direct, ps)) < 1e-5);
    assert!((rows[1].1 .0 - 2.0 / 3.0).abs() < 1e-6);
    assert!(rows.iter().all(|(_, r)| (r.3 - r.1).abs() < 1e-6));
    assert!(rows.iter().all(|(_, r)| (r.1 - r.2).abs() < 4.0 * (r.1 * (1.0 - r.1) / 4000.0).sqrt()));
    println!("ALL CHECKS PASS");
}
