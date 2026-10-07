// Tail dependence and the t copula -- the same check as the Python, in Rust.  No
// crates: the normal and t curves, the root finder, the integrals and the random
// numbers are all written out below.
use std::f64::consts::PI;
fn big_phi(x: f64) -> f64 {                      // normal CDF: series near 0, continued fraction in the tail
    if x.abs() < 3.0 {
        let (mut term, mut total, mut n) = (x, x, 0.0);
        while term.abs() > 1e-17 * total.abs() + 1e-300 {
            n += 1.0;
            term *= x * x / (2.0 * n + 1.0);
            total += term;
        }
        return 0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt();
    }
    let z = x.abs();
    let mut f = z;                               // Mills ratio by backward continued fraction
    for k in (1..=200).rev() { f = z + k as f64 / f; }
    let tail = (-0.5 * z * z).exp() / (2.0 * PI).sqrt() / f;
    if x < 0.0 { tail } else { 1.0 - tail }
}
fn bisect(f: &dyn Fn(f64) -> f64, p: f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {                            // root finder: f increasing, f(root) = p
        let mid = 0.5 * (lo + hi);
        if f(mid) < p { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}
fn t4_cdf(x: f64) -> f64 {                       // Student t, 4 degrees of freedom, closed form
    let r = (4.0 + x * x).sqrt();
    let opu = if x < 0.0 { 4.0 / (r * (r - x)) } else { 1.0 + x / r };
    opu.powi(2) * (2.0 - (opu - 1.0)) / 4.0
}
fn t5_cdf(x: f64) -> f64 {                       // Student t, 5 degrees of freedom, closed form
    let th = (x / 5f64.sqrt()).atan();
    0.5 + (th + th.sin() * th.cos() * (1.0 + 2.0 / 3.0 * th.cos().powi(2))) / PI
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}
fn t_cdf_by_area(n: f64, x: f64) -> f64 {        // any t curve as an area, substituting v = y / sqrt(n + y^2)
    let f = |v: f64| (1.0 - v * v).powf((n - 2.0) / 2.0);
    simpson(&f, -1.0, x / (n + x * x).sqrt(), 4000) / simpson(&f, -1.0, 1.0, 4000)
}
fn joint_by_angle(cut: f64, rho: f64, student: bool) -> f64 {   // road 1: a 1-D angle integral
    let al = rho.acos();
    let k = |th: f64| {
        let m = (-th.cos()).min(-(th - al).cos());
        if m <= 0.0 { return 0.0; }
        let s = cut * cut / (m * m);
        if student { (1.0 + s / 4.0).powf(-2.0) } else { (-0.5 * s).exp() }
    };
    simpson(&k, PI / 2.0 + al, 1.5 * PI, 20000) / (2.0 * PI)
}
fn phi(m: f64) -> f64 { (-0.5 * m * m).exp() / (2.0 * PI).sqrt() }
fn joint_by_factor(cut: f64, rho: f64, n: usize) -> f64 {       // road 2: condition on the economy M
    let b = (1.0 - rho).sqrt();
    simpson(&|m: f64| big_phi((cut - rho.sqrt() * m) / b).powi(2) * phi(m), -9.0, 9.0, n)
}
fn joint_t_by_factor(q: f64, rho: f64) -> f64 {  // road 2 for t: also average over the scale V = w^2
    simpson(&|w: f64| w.powi(3) * (-w * w / 2.0).exp() / 2.0 * joint_by_factor(q * w / 2.0, rho, 200), 0.0, 12.0, 400)
}
struct Rng(u64);
impl Rng {                                       // road 3: splitmix64 random numbers, written out
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 1e-18
    }
}
fn main() {
    let (rho, p) = (0.20_f64, 0.05_f64);
    let lam_closed = 2.0 * t5_cdf(-(5.0 * (1.0 - rho) / (1.0 + rho)).sqrt());
    let lam = |nu: f64, r: f64| 2.0 * t_cdf_by_area(nu + 1.0, -((nu + 1.0) * (1.0 - r) / (1.0 + r)).sqrt());
    let lam_area = lam(4.0, rho);
    let (a, q) = (bisect(&big_phi, p, -40.0, 0.0), bisect(&t4_cdf, p, -1e6, 0.0));
    let (jg1, jt1) = (joint_by_angle(a, rho, false), joint_by_angle(q, rho, true));
    let (jg2, jt2) = (joint_by_factor(a, rho, 400), joint_t_by_factor(q, rho));
    let (draws, mut hit_g, mut hit_t) = (400000usize, 0usize, 0usize);
    let mut rng = Rng(0x9E3779B97F4A7C15);
    for _ in 0..draws {                          // simulate the pair: two normals, one shared chi-square(4)
        let r = (-2.0 * rng.uniform().ln()).sqrt();
        let th = 2.0 * PI * rng.uniform();
        let (g1, g2) = (r * th.cos(), rho * r * th.cos() + (1.0 - rho * rho).sqrt() * r * th.sin());
        let s = (-2.0 * (rng.uniform() * rng.uniform()).ln() / 4.0).sqrt();
        if g1 < a && g2 < a { hit_g += 1 }
        if g1 / s < q && g2 / s < q { hit_t += 1 }
    }
    let (mc_g, mc_t) = (hit_g as f64 / draws as f64, hit_t as f64 / draws as f64);
    let dc = |j: f64| (j - p * p) / (p * (1.0 - p));   // default correlation from a joint chance
    println!("rho {:.2}, degrees of freedom 4, default chance each p = {:.2}", rho, p);
    println!("lambda, Gaussian: 0 for every rho below 1");
    println!("lambda, t4, closed form        {:.6}", lam_closed);
    println!("lambda, t4, by area            {:.6}", lam_area);
    let arg = (5.0 * (1.0 - rho) / (1.0 + rho)).sqrt();
    println!("lambda pieces: 5(1-rho)/(1+rho), root, t5 area  {:.6} {:.6} {:.6}", arg * arg, arg, t5_cdf(-arg));
    println!("cutoff, normal  a = Phi^-1(p)  {:.6}", a);
    println!("cutoff, t4      q = t4^-1(p)   {:.6}", q);
    println!("joint, Gaussian, by angle      {:.6}", jg1);
    println!("joint, Gaussian, by factor     {:.6}", jg2);
    println!("joint, Gaussian, simulated     {:.6}   ({} of {})", mc_g, hit_g, draws);
    println!("joint, t4, by angle            {:.6}", jt1);
    println!("joint, t4, by factor and scale {:.6}", jt2);
    println!("joint, t4, simulated           {:.6}   ({} of {})", mc_t, hit_t, draws);
    println!("joint if independent, p*p      {:.6}", p * p);
    println!("default correlation, Gaussian  {:.6}", dc(jg1));
    println!("default correlation, t4        {:.6}", dc(jt1));
    println!("both | one, Gaussian, J/p      {:.6}", jg1 / p);
    println!("both | one, t4, J/p            {:.6}", jt1 / p);
    println!();
    println!("threshold p    Gaussian J/p   t4 J/p     t4/Gaussian");
    let (labels, pps) = (["5e-02", "1e-02", "1e-03", "1e-04", "1e-06", "1e-08"], [0.05, 0.01, 1e-3, 1e-4, 1e-6, 1e-8]);
    let mut cond: Vec<(f64, f64)> = Vec::new();
    for (lab, &pp) in labels.iter().zip(pps.iter()) {
        let (aa, qq) = (bisect(&big_phi, pp, -40.0, 0.0), bisect(&t4_cdf, pp, -1e6, 0.0));
        let (g, t) = (joint_by_angle(aa, rho, false) / pp, joint_by_angle(qq, rho, true) / pp);
        cond.push((g, t));
        println!("{:<12}   {:.6}       {:.6}   {:10.2}", lab, g, t, t / g);
    }
    let row = |k: usize| cond.iter().map(|c| format!("{:.2}", 100.0 * if k == 0 { c.0 } else { c.1 })).collect::<Vec<_>>().join(" ");
    println!("chart, Gaussian %  {}", row(0));
    println!("chart, t4 %        {}", row(1));
    println!("chart, t4 limit %  {}", cond.iter().map(|_| format!("{:.2}", 100.0 * lam_closed)).collect::<Vec<_>>().join(" "));
    println!();
    let c = (1.0 - rho).sqrt() * bisect(&big_phi, 0.25, -40.0, 40.0);   // a quarter of a large pool defaults
    let sen_g = big_phi((a - c) / rho.sqrt());                           // Vasicek's curve
    let sen_t1 = simpson(&|v: f64| v * (-v / 2.0).exp() / 4.0 * big_phi((q * (v / 4.0).sqrt() - c) / rho.sqrt()), 0.0, 70.0, 2000);
    let v_below = |m: f64| {                     // chance the scale V is small enough, for economy M = m
        let z = c + rho.sqrt() * m;
        if z >= 0.0 { return 0.0; }
        let w = 4.0 * (z / q).powi(2);
        1.0 - (-w / 2.0).exp() * (1.0 + w / 2.0)
    };
    let sen_t2 = simpson(&|m: f64| phi(m) * v_below(m), -9.0, 9.0, 4000);
    println!("senior trigger: default fraction, loss at 40% recovery  {:.6} {:.6}", 0.25, 0.25 * 0.6);
    println!("large pool, P(quarter default), Gaussian       {:.6}", sen_g);
    println!("large pool, P(quarter default), t4, over V     {:.6}", sen_t1);
    println!("large pool, P(quarter default), t4, over M     {:.6}", sen_t2);
    println!("large pool, t4 / Gaussian                      {:.2}", sen_t1 / sen_g);
    println!();
    let wrong_q = joint_by_angle(a, rho, true);  // t model fed the normal cutoff
    println!("wrong: normal cutoff in the t model, marginal  {:.6}", t4_cdf(a));
    println!("wrong: normal cutoff in the t model, joint     {:.6}", wrong_q);
    println!("wrong: rho read as default correlation         {:.6}", rho);
    println!("wrong: lambda read as the p = 5% chance        {:.6}", jt1 / p);
    println!("wrong: 30 degrees of freedom, lambda           {:.6}", lam(30.0, rho));
    println!("try: lambda, t4, rho 0 / rho 0.5 / nu 10       {:.6} {:.6} {:.6}", lam(4.0, 0.0), lam(4.0, 0.5), lam(10.0, rho));
    assert!((lam_closed - lam_area).abs() < 1e-9, "two roads to lambda");
    assert!((cond[5].1 - lam_closed).abs() < 2e-3, "deep finite threshold lands on the limit");
    assert!(cond[5].0 < 0.01 && 0.01 < cond[0].0, "Gaussian conditional chance drains away");
    assert!((jg1 - 0.00525).abs() < 1e-5, "the shelf's house number, 0.525%");
    assert!((jg1 - jg2).abs() < 1e-7, "Gaussian joint, angle vs factor");
    assert!((jt1 - jt2).abs() < 1e-6, "t joint, angle vs factor-and-scale");
    assert!((mc_g - jg1).abs() < 4.0 * (jg1 / draws as f64).sqrt(), "Gaussian simulation within 4 errors");
    assert!((mc_t - jt1).abs() < 4.0 * (jt1 / draws as f64).sqrt(), "t simulation within 4 errors");
    assert!((sen_t1 - sen_t2).abs() < 1e-6, "senior tail, two orders of integration");
    assert!((joint_by_angle(bisect(&t4_cdf, 0.005, -1e6, 0.0), 0.5, true) / joint_by_angle(bisect(&big_phi, 0.005, -40.0, 0.0), 0.5, false) - 2.79).abs() < 0.01, "Demarta-McNeil table: 2.79");
    println!("ALL CHECKS PASS");
}
