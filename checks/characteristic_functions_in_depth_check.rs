// Characteristic functions in depth -- the same check as the Python, in Rust.  No crates.
// Four laws: a fair coin paying +1 or -1 dollar, the uniform law on [-sqrt 3, sqrt 3],
// the standard bell and the standard Cauchy (a lighthouse 1 km off a straight shore).
// The fingerprint is phi(t) = E[cos tX] + i E[sin tX]; all four laws are symmetric.
use std::f64::consts::PI;

fn r3() -> f64 { 3.0f64.sqrt() }
fn coin(t: f64) -> f64 { t.cos() }
fn unif(t: f64) -> f64 { if t == 0.0 { 1.0 } else { (r3() * t).sin() / (r3() * t) } }
fn bell(t: f64) -> f64 { (-t * t / 2.0).exp() }
fn cauchy(t: f64) -> f64 { (-t.abs()).exp() }
fn fake(t: f64) -> f64 { (-(t * t * t * t)).exp() }      // 1 at 0, at most 1, smooth, even: a fake
fn z(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {   // n even
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h) }
    (f(a) + f(b) + s) * h / 3.0
}

// Road two: the defining average, a sum over the coin's two faces or an integral against a density.
fn coin_sum(t: f64) -> (f64, f64) { ((t.cos() + (-t).cos()) / 2.0, (t.sin() + (-t).sin()) / 2.0) }
fn unif_int(t: f64) -> f64 { simpson(&|x: f64| (t * x).cos() / (2.0 * r3()), -r3(), r3(), 2000) }
fn bell_int(t: f64) -> f64 {
    simpson(&|x: f64| (t * x).cos() * (-x * x / 2.0).exp() / (2.0 * PI).sqrt(), -12.0, 12.0, 4000)
}
const L: f64 = 2000.0;                                     // Cauchy cut-off: the tail beyond is at most 2/(pi L)
fn cauchy_int(t: f64) -> f64 { 2.0 * simpson(&|x: f64| (t * x).cos() / (PI * (1.0 + x * x)), 0.0, L, 400000) }

// Positive definiteness at the rates 0, 0.5, 1: the matrix [g(tj - tk)] is [[1,a,b],[a,1,a],[b,a,1]].
fn eig_closed(g: fn(f64) -> f64) -> f64 {                 // road one: the smallest eigenvalue in closed form
    let (a, b) = (g(0.5), g(1.0));
    (1.0 - b).min((2.0 + b - (b * b + 8.0 * a * a).sqrt()) / 2.0)
}
fn eig_bisect(g: fn(f64) -> f64) -> f64 {                 // road two: first root of det(M - lam I), from below
    let (a, b) = (g(0.5), g(1.0));
    let det = |l: f64| (1.0 - l) * ((1.0 - l) * (1.0 - l) - a * a) - a * (a * (1.0 - l) - a * b) + b * (a * a - b * (1.0 - l));
    let mut lo = -3.0;
    while det(lo + 0.001) > 0.0 { lo += 0.001 }
    let mut hi = lo + 0.001;
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if det(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn die(t: f64) -> f64 {
    let (mut c, mut s) = (0.0, 0.0);
    for k in 1..7 { c += (k as f64 * t).cos(); s += (k as f64 * t).sin() }
    c.hypot(s) / 6.0
}

struct SplitMix(u64);                                      // SplitMix64, seed 20261115
impl SplitMix {
    fn unit(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut x = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        x = (x ^ (x >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((x ^ (x >> 31)) >> 11) as f64 + 0.5) / 2.0f64.powi(53)
    }
}

fn main() {
    println!("fingerprints at t = 1        closed form  defining average");
    let (c_re, c_im) = coin_sum(1.0);
    let rows = [("coin, cos t", coin(1.0), c_re), ("uniform, sin(r3 t)/(r3 t)", unif(1.0), unif_int(1.0)),
                ("bell, e^(-t^2/2)", bell(1.0), bell_int(1.0)), ("Cauchy, e^(-|t|)", cauchy(1.0), cauchy_int(1.0)),
                ("Cauchy again, at t = 2", cauchy(2.0), cauchy_int(2.0))];
    for (name, closed, avg) in rows {
        println!("  {:27}{:9.6}  {:9.6}", name, closed, avg);
        assert!((closed - avg).abs() < 2.0 / (PI * L));
    }
    println!("  sqrt 3 = {:.6}; coin's sine part {:.6}; Cauchy cut-off {:.0}, tail bound {:.6}", r3(), z(c_im), L, 2.0 / (PI * L));
    for t in [PI, 5.0] {
        println!("at t = {:.4}: coin {:.6}  uniform {:.6}  bell {:.6}  Cauchy {:.6}", t, coin(t), unif(t), bell(t), cauchy(t));
    }

    println!("rates 0, 0.5, 1: a = g(0.5), b = g(1), smallest eigenvalue by closed form / bisection");
    let laws: [(&str, fn(f64) -> f64); 5] =
        [("coin", coin), ("uniform", unif), ("bell", bell), ("Cauchy", cauchy), ("fake e^(-t^4)", fake)];
    for (name, g) in laws {
        let (e1, e2) = (eig_closed(g), eig_bisect(g));
        println!("  {:14}{:9.6}{:9.6}{:11.6}{:11.6}", name, g(0.5), g(1.0), z(e1), z(e2));
        assert!((e1 - e2).abs() < 1e-6 && (e1 > -1e-9) == (name != "fake e^(-t^4)"));
    }
    let two: [(&str, fn(f64) -> f64); 2] = [("bell", bell), ("fake", fake)];
    for (name, g) in two {
        let (a, b) = (g(0.5), g(1.0));
        println!("  by hand, {}: 2 + b = {:.6}, b^2 = {:.6}, 8a^2 = {:.6}", name, 2.0 + b, b * b, 8.0 * a * a);
    }
    println!("four-times rule at t = 0.5: 1 - g(1)  against  4(1 - g(0.5))");
    let three: [(&str, fn(f64) -> f64); 3] = [("coin", coin), ("bell", bell), ("fake e^(-t^4)", fake)];
    for (name, g) in three { println!("  {:14}{:9.6}  {:9.6}", name, 1.0 - g(1.0), 4.0 * (1.0 - g(0.5))) }
    assert!(1.0 - fake(1.0) > 4.0 * (1.0 - fake(0.5)) && 1.0 - bell(1.0) <= 4.0 * (1.0 - bell(0.5)));

    // Lattice and fading.  |phi(t0)| = 1 at t0 != 0 exactly for laws on evenly spaced points.
    println!("|phi| at the lattice rate: coin at pi {:.6}, die at 2 pi {:.6}", coin(PI).abs(), die(2.0 * PI));
    let peak = (0..2000).map(|k| unif(1.0 + k as f64 / 100.0).abs()).fold(0.0, f64::max);
    println!("largest |uniform phi| for t in [1, 21): {:.6}; never 1 again", peak);
    let t_big = 100.0;
    let avg_coin = simpson(&|t: f64| coin(t) * coin(t), -t_big, t_big, 20000) / (2.0 * t_big);
    let avg_die = simpson(&|t: f64| die(t) * die(t), -t_big, t_big, 20000) / (2.0 * t_big);
    let avg_unif = simpson(&|t: f64| unif(t) * unif(t), -t_big, t_big, 20000) / (2.0 * t_big);
    println!("average of |phi|^2 over [-{:.0}, {:.0}] / sum of squared point chances", t_big, t_big);
    let coin_exact = 0.5 + (2.0 * t_big).sin() / (4.0 * t_big);
    println!("  coin {:.6} / {:.6}; exact 1/2 + sin(2T)/(4T) = {:.6}", avg_coin, 0.25 + 0.25, coin_exact);
    let mut d = 0.0;
    for j in 0..6 { for k in 0..6 { if j != k { let u = (j - k) as f64 * t_big; d += u.sin() / u } } }
    let die_exact = (6.0 + d) / 36.0;
    println!("  die {:.6} / {:.6}; exact (6 + sum of sin(dT)/(dT))/36 = {:.6}", avg_die, 6.0 / 36.0, die_exact);
    println!("  uniform {:.6} / 0, bound pi/(2 r3 T) = {:.6}", avg_unif, PI / (2.0 * r3() * t_big));
    assert!((avg_coin - coin_exact).abs() < 1e-6 && (avg_die - die_exact).abs() < 1e-6);
    assert!(avg_unif < PI / (2.0 * r3() * t_big) && (die(2.0 * PI) - 1.0).abs() < 1e-12 && peak < 0.6);

    // The Cauchy: a corner at 0, and the mean of n draws has the fingerprint of one draw.
    let h = 1e-4;
    println!("slopes at 0 from the right / left: Cauchy {:.5} / {:.5}; bell {:.5} / {:.5}",
             (cauchy(h) - 1.0) / h, (cauchy(-h) - 1.0) / -h, (bell(h) - 1.0) / h, (bell(-h) - 1.0) / -h);
    println!("mean of 100 Cauchy draws: phi(1/100)^100 = {:.6}, one draw {:.6}", cauchy(0.01).powi(100), cauchy(1.0));
    println!("P(|one draw| > 1 km) = 1 - (2/pi) atan 1 = {:.6}", 1.0 - 2.0 / PI * 1.0f64.atan());

    let mut rng = SplitMix(20261115);
    let (m, n) = (20000usize, 100usize);
    let (mut far_one, mut far_mean, mut cos_sum) = (0usize, 0usize, 0.0f64);
    for _ in 0..m {
        let mut total = 0.0;
        for j in 0..n {
            let x = (PI * (rng.unit() - 0.5)).tan();          // where the beam meets the shore, in km
            if j == 0 && x.abs() > 1.0 { far_one += 1 }
            total += x;
            cos_sum += x.cos();
        }
        if (total / n as f64).abs() > 1.0 { far_mean += 1 }
    }
    let (p1, pm) = (far_one as f64 / m as f64, far_mean as f64 / m as f64);
    let se = (0.25 / m as f64).sqrt();
    println!("simulated, {} trials of {} lighthouse flashes: P(|one| > 1) {:.4}, P(|mean| > 1) {:.4}, standard error {:.4}",
             m, n, p1, pm, se);
    let sim_phi = cos_sum / (m * n) as f64;
    println!("simulated phi(1) from {} flashes: {:.4}, against e^(-1) {:.4}", m * n, sim_phi, cauchy(1.0));
    assert!((p1 - 0.5).abs() < 4.0 * se && (pm - 0.5).abs() < 4.0 * se && (sim_phi - cauchy(1.0)).abs() < 0.003);

    let figs: [(&str, fn(f64) -> f64); 3] = [("coin", coin), ("uniform", unif), ("bell", bell)];
    for (name, g) in figs {
        let pts: Vec<String> = (0..13).map(|k| format!("{:.2}", z(g(k as f64 / 2.0)))).collect();
        println!("figure, {:8}{}", name, pts.join(" "));
    }
    println!("ALL CHECKS PASS");
}
