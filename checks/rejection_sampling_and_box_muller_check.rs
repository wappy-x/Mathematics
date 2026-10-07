// Rejection sampling and Box-Muller -- the same check as the Python, in Rust.  No crates.
// Every draw comes from SplitMix64, seed 20260929, so both languages draw the same
// numbers.  Phi is Simpson's rule on the bell curve, never a sampler.
use std::f64::consts::{E, PI};

struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {                   // SplitMix64, 53 bits, in (0, 1]
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) + 1) as f64 / 2f64.powi(53)
    }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let (n, mut inner) = (20000, 0.0);
    let h = (b - a) / n as f64;
    for i in 1..n {
        inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    (f(a) + f(b) + inner) * h / 3.0
}

fn bell(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn phi(x: f64) -> f64 { 0.5 + simpson(&bell, 0.0, x) }
fn half_normal(y: f64) -> f64 { 2.0 * bell(y) }     // target f: the size of a normal
fn lognormal_call(s: f64) -> f64 {                  // e^-r E[(e^X - 100)+], X ~ N(m, s^2)
    let m = 100f64.ln() + 0.01;
    let d = (m - 100f64.ln()) / s;
    (-0.05f64).exp() * ((m + s * s / 2.0).exp() * phi(d + s) - 100.0 * phi(d))
}

fn rejection(g: &mut Rng, ceiling: f64) -> (f64, u64) {   // a signed draw and the tries used
    let mut tries = 0;
    loop {
        tries += 1;
        let y = -g.uniform().ln();                  // exponential proposal, by inverse transform
        if g.uniform() <= (half_normal(y) / (ceiling * (-y).exp())).min(1.0) {
            return (if g.uniform() < 0.5 { y } else { -y }, tries);
        }
    }
}

fn box_muller(g: &mut Rng, k: f64, root: bool) -> (f64, f64) {
    let (u1, u2) = (g.uniform(), g.uniform());
    let rad = if root { (-k * u1.ln()).sqrt() } else { -k * u1.ln() };
    (rad * (2.0 * PI * u2).cos(), rad * (2.0 * PI * u2).sin())
}

fn polar(g: &mut Rng) -> (f64, f64, u64) {          // dart in the square, kept if inside the disc
    let mut tries = 0;
    loop {
        tries += 1;
        let (x, y) = (2.0 * g.uniform() - 1.0, 2.0 * g.uniform() - 1.0);
        let s = x * x + y * y;
        if 0.0 < s && s <= 1.0 {
            return (x * (-2.0 * s.ln() / s).sqrt(), y * (-2.0 * s.ln() / s).sqrt(), tries);
        }
    }
}

fn summary(zs: &[f64]) -> (f64, f64, f64, f64) {
    let n = zs.len() as f64;
    let mean = zs.iter().fold(0.0, |a, z| a + z) / n;
    let var = zs.iter().fold(0.0, |a, z| a + (z - mean) * (z - mean)) / n;
    let p = zs.iter().filter(|&&z| z <= 1.0).count() as f64 / n;
    (mean, var, p, (p * (1.0 - p) / n).sqrt())
}

fn show(label: &str, zs: &[f64]) -> (f64, f64) {
    let (mean, var, p, se) = summary(zs);
    println!("{}: mean {:.4}, variance {:.4}, P(Z <= 1) {:.4} +/- {:.4}", label, mean, var, p, se);
    (p, se)
}
fn row(label: &str, v: &[f64], places: usize) {
    let cells: Vec<String> = v.iter().map(|x| format!("{:.*}", places, x)).collect();
    println!("chart, {}: {}", label, cells.join(", "));
}
fn main() {
    let mut g = Rng(20260929);
    let (n, phi1) = (200000usize, phi(1.0));
    let nf = n as f64;
    let m_env = (2.0 * E / PI).sqrt();
    println!("SplitMix64 seed 20260929; {} normal draws per method; Phi(1) by Simpson {:.6}; largest R from 53-bit uniforms {:.4}",
             n, phi1, (-2.0 * 2f64.powi(-53).ln()).sqrt());
    let accept_int = simpson(&|y: f64| (-y).exp() * (-(y - 1.0) * (y - 1.0) / 2.0).exp(), 0.0, 12.0);
    println!("rejection: M = sqrt(2e/pi) = {:.6}; acceptance 1/M = {:.6}, by integral {:.6}", m_env, 1.0 / m_env, accept_int);
    let draws: Vec<(f64, u64)> = (0..n).map(|_| rejection(&mut g, m_env)).collect();
    let (rej, rej_tries): (Vec<f64>, u64) = (draws.iter().map(|d| d.0).collect(), draws.iter().map(|d| d.1).sum());
    let acc = nf / rej_tries as f64;
    let acc_se = (acc * (1.0 - acc) / rej_tries as f64).sqrt();
    println!("rejection: {} proposals, acceptance {:.4} +/- {:.4}, tries per draw {:.4}", rej_tries, acc, acc_se, rej_tries as f64 / nf);
    let (p_rej, se_rej) = show("rejection draws", &rej);
    let (u1, u2, r_hand, y_hand) = (0.3f64, 0.8f64, (-2.0 * 0.3f64.ln()).sqrt(), -0.3f64.ln());
    let keep = (-(y_hand - 1.0) * (y_hand - 1.0) / 2.0).exp();
    println!("by hand, rejection: Y = -ln 0.3 = {:.6}, keep chance exp(-(Y - 1)^2 / 2) = {:.6}, test U = 0.8: kept {}",
             y_hand, keep, if 0.8 <= keep { "yes" } else { "no" });
    let (z1, z2) = (r_hand * (2.0 * PI * u2).cos(), r_hand * (2.0 * PI * u2).sin());
    println!("by hand: U1 = 0.3, U2 = 0.8 -> -2 ln U1 = {:.6}, R = {:.6}, angle = {:.6}, cos {:.6}, sin {:.6}",
             -2.0 * u1.ln(), r_hand, 2.0 * PI * u2, (2.0 * PI * u2).cos(), (2.0 * PI * u2).sin());
    println!("by hand: Z1 = {:.6}, Z2 = {:.6}; stock in a year 100 exp(0.01 + 0.2 Z1) = {:.2}", z1, z2, 100.0 * (0.01 + 0.2 * z1).exp());
    let (m, mut below, mut both) = (1000usize, 0usize, 0usize);
    for i in 0..m {
        let rad = (-2.0 * ((i as f64 + 0.5) / m as f64).ln()).sqrt();
        for j in 0..m {
            let t = 2.0 * PI * (j as f64 + 0.5) / m as f64;
            let (a, b) = (rad * t.cos(), rad * t.sin());
            if a <= 1.0 { below += 1; if b <= 1.0 { both += 1; } }
        }
    }
    let (gb, gj) = (below as f64 / m as f64 / m as f64, both as f64 / m as f64 / m as f64);
    println!("grid of {} uniform pairs, no randomness: P(Z1 <= 1) {:.6}, P(Z1 <= 1 and Z2 <= 1) {:.6}, Phi(1)^2 {:.6}", m * m, gb, gj, phi1 * phi1);
    let mut bm = Vec::new();
    for _ in 0..n / 2 { let (a, b) = box_muller(&mut g, 2.0, true); bm.push(a); bm.push(b); }
    let (p_bm, se_bm) = show("Box-Muller draws", &bm);
    let np = (n / 2) as f64;
    let corr = bm.chunks(2).fold(0.0, |s, c| s + c[0] * c[1]) / np;
    let p_both = bm.chunks(2).filter(|c| c[0] <= 1.0 && c[1] <= 1.0).count() as f64 / np;
    println!("Box-Muller pairs: average Z1 Z2 {:.4}, P(Z1 <= 1 and Z2 <= 1) {:.4} +/- {:.4}", corr, p_both, (p_both * (1.0 - p_both) / np).sqrt());
    let (mut pol, mut pol_tries) = (Vec::new(), 0u64);
    for _ in 0..n / 2 { let (a, b, t) = polar(&mut g); pol.push(a); pol.push(b); pol_tries += t; }
    let pi_hat = 4.0 * (n / 2) as f64 / pol_tries as f64;
    let pi_se = 4.0 * ((pi_hat / 4.0) * (1.0 - pi_hat / 4.0) / pol_tries as f64).sqrt();
    println!("polar: acceptance pi/4 = {:.6}; darts {}, 4 x kept share {:.4} +/- {:.4}", PI / 4.0, pol_tries, pi_hat, pi_se);
    let (p_pol, se_pol) = show("polar draws", &pol);
    let stock: Vec<f64> = bm.iter().map(|z| 100.0 * (0.01 + 0.2 * z).exp()).collect();
    let up = stock.iter().filter(|&&s| s > 100.0).count() as f64 / nf;
    let pay: Vec<f64> = stock.iter().map(|s| (-0.05f64).exp() * (s - 100.0).max(0.0)).collect();
    let call = pay.iter().fold(0.0, |a, p| a + p) / nf;
    let call_se = (pay.iter().fold(0.0, |a, p| a + (p - call) * (p - call)) / nf / nf).sqrt();
    println!("stock: P(price > 100) {:.4} +/- {:.4}; exact Phi(0.05) = {:.6}", up, (up * (1.0 - up) / nf).sqrt(), phi(0.05));
    let avg = stock.iter().fold(0.0, |a, s| a + s) / nf;
    println!("stock: average price {:.4} +/- {:.4}; exact 100 e^0.03 = {:.4}", avg,
             (stock.iter().fold(0.0, |a, s| a + (s - avg) * (s - avg)) / nf / nf).sqrt(), 100.0 * 0.03f64.exp());
    let exact_call = lognormal_call(0.2);
    println!("stock: call by simulation {:.4} +/- {:.4}; by formula {:.6}", call, call_se, exact_call);
    let half: Vec<f64> = (0..n).map(|_| box_muller(&mut g, 1.0, true).0).collect();
    let wide: Vec<f64> = (0..n).map(|_| box_muller(&mut g, 2.0, false).0).collect();
    let clip: Vec<f64> = (0..n).map(|_| rejection(&mut g, 1.0).0).collect();
    let floor = |y: f64| half_normal(y).min((-y).exp());     // clipped: the accepted weight
    let clip_tail = simpson(&floor, 2.0, 12.0) / simpson(&floor, 0.0, 12.0);
    let tail_sim = clip.iter().filter(|z| z.abs() > 2.0).count() as f64 / nf;
    println!("break, -ln U1 without the 2: variance {:.4} (exact 0.5); call {:.4}", summary(&half).1, lognormal_call(0.2 / 2f64.sqrt()));
    println!("break, R = -2 ln U1 with no root: variance {:.4} (exact 4)", summary(&wide).1);
    println!("break, envelope M = 1, clipped: P(|Z| > 2) {:.4} +/- {:.4}; by integral {:.4}; true {:.4}; mean {:.4}, variance {:.4}",
             tail_sim, (tail_sim * (1.0 - tail_sim) / nf).sqrt(), clip_tail, 2.0 * (1.0 - phi(2.0)), summary(&clip).0, summary(&clip).1);
    let ys: Vec<f64> = (0..17).map(|k| 0.25 * k as f64).collect();
    row("y", &ys, 2);
    row("target f(y), percent", &ys.iter().map(|&y| 100.0 * half_normal(y)).collect::<Vec<f64>>(), 2);
    row("envelope M g(y), percent", &ys.iter().map(|&y| 100.0 * m_env * (-y).exp()).collect::<Vec<f64>>(), 2);
    let edges: Vec<f64> = (0..12).map(|k| -3.0 + 0.5 * k as f64).collect();
    row("bin centres", &edges.iter().map(|a| a + 0.25).collect::<Vec<f64>>(), 2);
    row("Box-Muller percent per unit", &edges.iter().map(|&a|
        100.0 * bm.iter().filter(|&&z| a < z && z <= a + 0.5).count() as f64 / nf / 0.5).collect::<Vec<f64>>(), 2);
    row("exact bell percent per unit", &edges.iter().map(|&a| 100.0 * (phi(a + 0.5) - phi(a)) / 0.5).collect::<Vec<f64>>(), 2);
    assert!((accept_int - (PI / (2.0 * E)).sqrt()).abs() < 1e-9);   // integral against closed form
    assert!((acc - 1.0 / m_env).abs() < 4.0 * acc_se);               // simulated acceptance
    assert!((gb - phi1).abs() < 1e-3 && (gj - phi1 * phi1).abs() < 1e-3);
    for (p, se) in [(p_rej, se_rej), (p_bm, se_bm), (p_pol, se_pol)] {
        assert!((p - phi1).abs() < 4.0 * se);                        // three samplers, one bell
    }
    assert!((p_both - phi1 * phi1).abs() < 4.0 * (p_both * (1.0 - p_both) / np).sqrt()); // independent pair
    assert!((call - exact_call).abs() < 4.0 * call_se && (exact_call - 9.227005508154).abs() < 1e-6);
    assert!((tail_sim - clip_tail).abs() < 4.0 * (clip_tail * (1.0 - clip_tail) / nf).sqrt());
    assert!((summary(&half).1 - 0.5).abs() < 0.01 && (summary(&wide).1 - 4.0).abs() < 0.1);
    assert!(clip_tail - 2.0 * (1.0 - phi(2.0)) > 0.005);            // the clipped sampler is wrong
    println!("ALL CHECKS PASS");
}
