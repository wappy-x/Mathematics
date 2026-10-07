// Basket options -- the same check as the Python, in Rust.  No crates.  The
// normal CDF is a series written out here, the random numbers come from a
// hand-written generator, and the integral is Simpson's rule.  Three roads to
// one price: moment matching, correlated simulation, and an exact integral
// over the first share's shock.
use std::f64::consts::PI;
const R: f64 = 0.05; const T: f64 = 1.0;                 // bank rate, years
const HOUSE_BS: f64 = 9.227005508154;         // the pilot card's house call, typed in

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }

fn n_cdf(x: f64) -> f64 {                      // Marsaglia's series
    if x < -9.0 { return 0.0 }
    if x > 9.0 { return 1.0 }
    if x < 0.0 { return 1.0 - n_cdf(-x) }
    let (mut term, mut total, mut n) = (x, x, 1.0);
    while term > 1e-17 * total { term *= x * x / (2.0 * n + 1.0); total += term; n += 1.0; }
    0.5 + phi(x) * total
}

#[derive(Clone, Copy)]
struct M { s: [f64; 2], sig: [f64; 2], q: [f64; 2], w: [f64; 2], rho: f64, k: f64 }
const HOUSE: M = M { s: [100.0, 100.0], sig: [0.2, 0.2], q: [0.02, 0.02], w: [0.5, 0.5], rho: 0.5, k: 100.0 };

fn fwd(m: &M, i: usize) -> f64 { m.s[i] * ((R - m.q[i]) * T).exp() }
fn cv(m: &M, i: usize, j: usize) -> f64 { (if i == j { 1.0 } else { m.rho }) * m.sig[i] * m.sig[j] * T }

fn moments(m: &M) -> (f64, f64, f64) {         // exact E[B], E[B^2], E[B^3] at T
    let (mut m1, mut m2, mut m3) = (0.0, 0.0, 0.0);
    let wf = |i: usize| m.w[i] * fwd(m, i);
    for i in 0..2 { m1 += wf(i);
        for j in 0..2 { m2 += wf(i) * wf(j) * cv(m, i, j).exp();
            for k in 0..2 { m3 += wf(i) * wf(j) * wf(k) * (cv(m, i, j) + cv(m, i, k) + cv(m, j, k)).exp(); } } }
    (m1, m2, m3)
}

fn road1_mm(m: &M, spot: bool) -> f64 {        // moment matching
    let (mut m1, mut m2, _) = moments(m);
    if spot { let b0 = m.w[0] * m.s[0] + m.w[1] * m.s[1]; m2 *= (b0 / m1).powi(2); m1 = b0; }
    let v = (m2 / (m1 * m1)).ln();
    let d1 = ((m1 / m.k).ln() + 0.5 * v) / v.sqrt();
    (-R * T).exp() * (m1 * n_cdf(d1) - m.k * n_cdf(d1 - v.sqrt()))
}

fn road3_int(m: &M, n: usize) -> f64 {         // exact 1-D integral
    let rt = T.sqrt();
    let sd = m.sig[1] * rt * (1.0 - m.rho * m.rho).max(0.0).sqrt();
    let f = |z: f64| -> f64 {                  // share 2's own shock done in closed form
        let c = m.w[0] * fwd(m, 0) * (-0.5 * m.sig[0].powi(2) * T + m.sig[0] * rt * z).exp();
        let a = m.w[1] * fwd(m, 1) * (-0.5 * m.sig[1].powi(2) * T + m.sig[1] * rt * m.rho * z).exp();
        let kk = m.k - c;
        let v = if kk <= 0.0 { a * (0.5 * sd * sd).exp() - kk }
            else if sd < 1e-12 { (a - kk).max(0.0) }
            else {
                let b = (kk / a).ln() / sd;
                a * (0.5 * sd * sd).exp() * n_cdf(sd - b) - kk * n_cdf(-b)
            };
        v * phi(z)
    };
    let (lo, hi) = (-9.0, 9.0);
    let (h, mut tot) = ((hi - lo) / n as f64, f(lo) + f(hi));
    for i in 1..n { tot += if i % 2 == 1 { 4.0 } else { 2.0 } * f(lo + i as f64 * h); }
    (-R * T).exp() * tot * h / 3.0
}

struct Rng(u64);
impl Rng {                                      // splitmix64, then 53 bits into (0, 1)
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
}

fn road2_mc(m: &M, paths: usize, bug: bool) -> (f64, f64) {   // Cholesky by hand
    let mut rng = Rng(20260924);
    let (mut s1, mut s2) = (0.0, 0.0);
    let l22 = if bug { 1.0 } else { (1.0 - m.rho * m.rho).sqrt() };
    for _ in 0..paths {
        let (u1, u2) = (rng.uniform(), rng.uniform());
        let rad = (-2.0 * u1.ln()).sqrt();
        let (z1, z2) = (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2).sin());   // Box-Muller
        let x2 = m.rho * z1 + l22 * z2;
        let leg = |i: usize, x: f64| m.w[i] * fwd(m, i) * (-0.5 * m.sig[i].powi(2) * T + m.sig[i] * T.sqrt() * x).exp();
        let b = leg(0, z1) + leg(1, x2);
        let p = (b - m.k).max(0.0); s1 += p; s2 += p * p;
    }
    let (mean, np) = (s1 / paths as f64, paths as f64);
    ((-R * T).exp() * mean, (-R * T).exp() * ((s2 / np - mean * mean) / np).sqrt())
}

fn main() {
    let h = HOUSE;
    let with = |f: &dyn Fn(&mut M)| { let mut m = h; f(&mut m); m };
    let (m1, m2, m3) = moments(&h);
    let v = (m2 / (m1 * m1)).ln();
    let m3_logn = m1.powi(3) * (m2 / m1.powi(2)).powi(3);
    let (mm, ex, ex_half) = (road1_mm(&h, false), road3_int(&h, 2000), road3_int(&h, 1000));
    let (mc, se) = road2_mc(&h, 400000, false);
    let fw = fwd(&h, 0);
    println!("forward of each share        {:.6}", fw);
    println!("E[B] and E[B^2]              {:.6}  {:.6}", m1, m2);
    println!("E[B^2] own, own, cross       {:.6}  {:.6}  {:.6}", h.w[0].powi(2) * fw * fw * (h.sig[0].powi(2) * T).exp(),
             h.w[1].powi(2) * fw * fw * (h.sig[1].powi(2) * T).exp(), 2.0 * h.w[0] * h.w[1] * fw * fw * (h.rho * h.sig[0] * h.sig[1] * T).exp());
    let d1 = ((m1 / h.k).ln() + 0.5 * v) / v.sqrt();
    println!("E[B^2]/E[B]^2 and v = ln     {:.6}  {:.6}", m2 / m1.powi(2), v);
    println!("basket vol sigma_B           {:.6}", (v / T).sqrt());
    println!("d1 d2 N(d1) N(d2)            {:.6}  {:.6}  {:.6}  {:.6}", d1, d1 - v.sqrt(), n_cdf(d1), n_cdf(d1 - v.sqrt()));
    println!("E[B^3] exact                 {:.4}", m3);
    println!("E[B^3] fitted lognormal      {:.4}", m3_logn);
    println!("1 moment match               {:.6}", mm);
    println!("2 simulation, 400000 paths   {:.6} +- {:.6}", mc, se);
    println!("3 exact integral, n = 2000   {:.6}", ex);
    println!("  same, n = 1000             {:.6}", ex_half);
    println!("  moment match minus exact   {:.6}", mm - ex);
    let floor = fw * (-0.5 * h.sig[0].powi(2) * T).exp();         // rho = -1: B = floor * cosh(...)
    let anti = with(&|m| m.rho = -1.0);
    let (m1n, m2n, _) = moments(&anti);
    let sure = (-R * T).exp() * (m1n - h.k);
    let vn = (m2n / m1n.powi(2)).ln();
    let below = n_cdf(-((m1n / h.k).ln() - 0.5 * vn) / vn.sqrt());
    println!("rho = -1: B never below      {:.6}", floor);
    println!("rho = -1: e^-rT (E[B] - K)   {:.6}", sure);
    println!("rho = -1: fit's P(B < K)     {:.6}", below);
    println!("rho    moment   exact    gap");
    let (mut ca, mut ce): (Vec<String>, Vec<String>) = (Vec::new(), Vec::new());
    for i in 0..9 {
        let m = with(&|m| m.rho = -1.0 + 0.25 * i as f64);
        let (a, e) = (road1_mm(&m, false), road3_int(&m, 2000));
        println!("{:5.2}  {:7.4}  {:7.4}  {:7.4}", m.rho, a, e, a - e);
        ca.push(format!("{:.2}", a)); ce.push(format!("{:.2}", e));
    }
    println!("chart, moment match  {}", ca.join(" "));
    println!("chart, exact         {}", ce.join(" "));
    let mut g: Vec<(f64, f64, f64)> = Vec::new();
    for (name, road) in [("moment", 0), ("exact ", 1)] {
        let p = |m: M| if road == 0 { road1_mm(&m, false) } else { road3_int(&m, 2000) };
        let d = (p(with(&|m| m.s[0] = 100.01)) - p(with(&|m| m.s[0] = 99.99))) / 0.02;
        let vg = (p(with(&|m| m.sig[0] = 0.201)) - p(with(&|m| m.sig[0] = 0.199))) / 0.002 * 0.01;
        let rg = (p(with(&|m| m.rho = 0.51)) - p(with(&|m| m.rho = 0.49))) / 0.02 * 0.01;
        g.push((d, vg, rg));
        println!("greeks {} delta1 {:.6} vega1/pt {:.6} rho/0.01 {:.6}", name, d, vg, rg);
    }
    let ri = |f: &dyn Fn(&mut M)| road3_int(&with(f), 2000);
    println!("swing, rho 0.3 to 0.7        {:.6}", ri(&|m| m.rho = 0.7) - ri(&|m| m.rho = 0.3));
    println!("swing, sigma1 19% to 21%     {:.6}", ri(&|m| m.sig[0] = 0.21) - ri(&|m| m.sig[0] = 0.19));
    println!("wrong: rho set to 0          {:.6}", ri(&|m| m.rho = 0.0));
    println!("wrong: spot not forward      {:.6}", road1_mm(&h, true));
    println!("wrong: no discount           {:.6}", mm * (R * T).exp());
    let (bug, bug_se) = road2_mc(&h, 400000, true);
    println!("wrong: rho matrix as mixer   {:.6} +- {:.6}", bug, bug_se);
    println!("  its share-2 vol and rho    {:.6}  {:.6}", h.sig[1] * (1.0 + h.rho * h.rho).sqrt(), h.rho / (1.0 + h.rho * h.rho).sqrt());
    let one = road1_mm(&with(&|m| m.rho = 1.0), false);
    println!("wrong: two calls, half each  {:.6}", 0.5 * one + 0.5 * one);
    println!("try: K = 110                 {:.6}", ri(&|m| m.k = 110.0));
    println!("try: weights 0.8/0.2         {:.6}", ri(&|m| m.w = [0.8, 0.2]));
    println!("try: sigma2 = 30%            {:.6}  mm {:.6}", ri(&|m| m.sig[1] = 0.3), road1_mm(&with(&|m| m.sig[1] = 0.3), false));
    println!("story: Acme 130, Birch 80    basket {:.0}, call {:.0}, two half calls {:.0}", 0.5 * 130.0 + 0.5 * 80.0,
             (0.5 * 130.0 + 0.5 * 80.0 - h.k).max(0.0), 0.5 * (130.0 - h.k).max(0.0) + 0.5 * (80.0 - h.k).max(0.0));
    let pay: Vec<String> = (0..11).map(|i| format!("{:.0}", (80.0 + 5.0 * i as f64 - h.k).max(0.0))).collect();
    println!("payoff at B = 80..130        {}", pay.join(" "));
    assert!((mc - ex).abs() < 3.0 * se, "simulation and exact integral disagree");
    assert!((ex - ex_half).abs() < 1e-7, "integral not settled on its grid");
    assert!((one - HOUSE_BS).abs() < 1e-9 && (ri(&|m| m.rho = 1.0) - HOUSE_BS).abs() < 1e-4);
    assert!((ri(&|m| m.rho = -1.0) - sure).abs() < 1e-9 && road1_mm(&anti, false) - sure > 0.1, "floor case");
    assert!((g[0].2 - g[1].2).abs() < 0.001 && (mm - ex).abs() < 0.001);
    println!("ALL CHECKS PASS");
}
