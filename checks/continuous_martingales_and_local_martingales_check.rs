// Continuous martingales and local martingales -- the check behind the card.
// std only. B is a 3-dimensional Brownian motion started at distance R0 = 1
// from the origin, and X_t = 1/|B_t| is one over its distance.
// Roads to E[X_1]: the closed form 2 Phi(1) - 1; a Simpson integral of the
// Gaussian average over space; exact draws of B_1; whole simulated paths.
use std::f64::consts::PI;

const R0: f64 = 1.0; const T: f64 = 1.0; const CAP: u32 = 10; // start distance, horizon, cap on X

fn phi(x: f64) -> f64 { (-x * x / 2.0).exp() / (2.0 * PI).sqrt() } // the bell curve's height

fn big_phi(x: f64) -> f64 { // its area to the left: 1/2 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + phi(x) * total
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 { // Simpson's rule, n even
    let h = (b - a) / n as f64;
    let mut acc = 0.0;
    for i in 1..n {
        acc += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    (f(a) + f(b) + acc) * h / 3.0
}

fn mean_closed(r0: f64, t: f64) -> f64 { (2.0 * big_phi(r0 / t.sqrt()) - 1.0) / r0 } // E[1/|B_t|]

fn mean_space(r0: f64, t: f64) -> f64 { // the Gaussian average of 1/|y| over space, in shells:
    // rho = |y|, u = cosine of y's angle to the start
    let c = 2.0 * PI / (2.0 * PI * t).powf(1.5);
    let inner = |rho: f64| {
        let g = |u: f64| rho * (-(rho * rho - 2.0 * rho * r0 * u + r0 * r0) / (2.0 * t)).exp();
        simpson(g, -1.0, 1.0, 200)
    };
    c * simpson(inner, 0.0, r0 + 12.0 * t.sqrt(), 600)
}

fn shell(rho: f64, r0: f64) -> f64 { // average of 1/|y| over the sphere of radius rho around the start
    simpson(|u| 0.5 / (rho * rho + r0 * r0 - 2.0 * rho * r0 * u).sqrt(), -1.0, 1.0, 2000)
}

fn capped(n: u32, r0: f64, t: f64) -> (f64, f64, f64) { // stop at the first time |B| = 1/n, i.e. X reaches n
    let n = n as f64;
    let q = big_phi((r0 - 1.0 / n) / t.sqrt());
    let chance = (1.0 / n) / r0 * 2.0 * (1.0 - q);
    (chance, n * chance, (2.0 * q - 1.0) / r0)
}

struct Rng(u64); // SplitMix64 and Box-Muller, written out
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
    fn normals(&mut self) -> (f64, f64) {
        let (u, v) = (1.0 - self.uniform(), self.uniform());
        let r = (-2.0 * u.ln()).sqrt();
        (r * (2.0 * PI * v).cos(), r * (2.0 * PI * v).sin())
    }
}

fn stats(xs: &[f64]) -> (f64, f64) { // mean and its standard error, summed in order
    let (mut m, mut v) = (0.0, 0.0);
    for x in xs { m += x; }
    m /= xs.len() as f64;
    for x in xs { v += (x - m) * (x - m); }
    (m, (v / (xs.len() as f64 - 1.0) / xs.len() as f64).sqrt())
}

fn main() {
    // ---- the example: one over the distance, started 1 unit out ----
    let (exact, quad) = (mean_closed(R0, T), mean_space(R0, T));
    println!("Phi(1) = {:.6}, phi(1) = {:.6}", big_phi(1.0), phi(1.0));
    println!("E[X_1], road 1, closed form 2 Phi(1) - 1 = {:.6}", exact);
    println!("E[X_1], road 2, Simpson over space = {:.6}", quad);
    assert!((quad - exact).abs() < 1e-6);
    println!("mean lost by time 1 = {:.6}", 1.0 / R0 - exact);
    let inside = 2.0 * big_phi(1.0) - 1.0 - 2.0 * phi(1.0);
    println!("Newton split: P(moved <= 1) = {:.6}, E[1/moved; moved > 1] = {:.6}", inside, 2.0 * phi(1.0));
    println!("shell averages: radius 0.3 -> {:.6}, radius 3 -> {:.6}", shell(0.3, R0), shell(3.0, R0));
    assert!((shell(0.3, R0) - 1.0 / R0).abs() < 1e-6); // inside the shell: 1 / (start distance)
    assert!((shell(3.0, R0) - 1.0 / 3.0).abs() < 1e-6); // outside: 1 / (shell radius)
    println!("E[X_4] = {:.6} (Simpson {:.6})", mean_closed(R0, 4.0), mean_space(R0, 4.0));
    assert!((mean_space(R0, 4.0) - mean_closed(R0, 4.0)).abs() < 1e-6);

    // ---- road 3: exact draws of B_T = start + sqrt(T) times three standard normals ----
    let mut rng = Rng(20261123);
    let mut xs = Vec::new();
    for _ in 0..100000 {
        let (a, b) = rng.normals();
        let (c, _) = rng.normals();
        let q = T.sqrt();
        xs.push(1.0 / ((R0 + q * a) * (R0 + q * a) + (q * b) * (q * b) + (q * c) * (q * c)).sqrt());
    }
    let (m, se) = stats(&xs);
    println!("E[X_1], road 3, 100000 exact draws = {:.6} +- {:.6}", m, se);
    assert!((m - exact).abs() < 4.0 * se);

    // ---- localisation: caps at X = n, read at time 1 ----
    for n in [2, 5, CAP, 100, 1000] {
        let (ch, mass, rest) = capped(n, R0, T);
        println!("cap {}: P(reach cap by 1) = {:.6}, mean on capped paths = {:.6}, mean on the rest = {:.6}", n, ch, mass, rest);
    }
    println!("cap {}: frozen reading's average = {:.6}", CAP, capped(CAP, R0, T).1 + capped(CAP, R0, T).2);
    assert!((capped(1000000, R0, T).2 - exact).abs() < 1e-5);

    // ---- road 4: 4000 whole paths, 200 steps; frozen at the cap X = 4, and not ----
    let (paths, steps, ncap) = (4000, 200, 4.0);
    let s = (T / steps as f64).sqrt();
    let (mut free, mut frozen) = (Vec::new(), Vec::new());
    for _ in 0..paths {
        let (mut x, mut y, mut z, mut stop): (f64, f64, f64, Option<f64>) = (R0, 0.0, 0.0, None);
        for _ in 0..steps {
            let (a, b) = rng.normals();
            let (c, _) = rng.normals();
            (x, y, z) = (x + s * a, y + s * b, z + s * c);
            if stop.is_none() && (x * x + y * y + z * z).sqrt() <= 1.0 / ncap {
                stop = Some(1.0 / (x * x + y * y + z * z).sqrt());
            }
        }
        let last = 1.0 / (x * x + y * y + z * z).sqrt();
        free.push(last);
        frozen.push(stop.unwrap_or(last));
    }
    let ((mf, sf), (mz, sz)) = (stats(&free), stats(&frozen));
    println!("paths: unfrozen mean at 1 = {:.6} +- {:.6}", mf, sf);
    println!("paths: frozen at cap {}, mean = {:.6} +- {:.6}", ncap, mz, sz);
    assert!((mf - exact).abs() < 4.0 * sf);
    assert!((mz - 1.0 / R0).abs() < 4.0 * sz + 0.02); // the grid freezes a little late

    // ---- the chance of reaching the cap, by another road: the radial heat equation on a grid ----
    let (a, dr, ds) = (1.0 / CAP as f64, 0.025, 0.00025); // u[i] = P(reach radius a by now | start at a + i dr)
    let mut u: Vec<f64> = (0..321).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect();
    for _ in 0..(T / ds).round() as usize {
        let old = u.clone();
        for i in 1..320 {
            u[i] = old[i] + ds * ((old[i + 1] - 2.0 * old[i] + old[i - 1]) / (2.0 * dr * dr) + (old[i + 1] - old[i - 1]) / (2.0 * dr) / (a + i as f64 * dr));
        }
    }
    let pde = u[((R0 - a) / dr).round() as usize];
    println!("cap {}: P(reach cap by 1) on a heat-equation grid = {:.6}", CAP, pde);
    assert!((pde - capped(CAP, R0, T).0).abs() < 1e-4);

    // ---- the house example M_t = (W_t^2 - t)/2, a true martingale ----
    let msq = simpson(|w| ((w * w - 1.0) / 2.0).powi(2) * phi(w), -12.0, 12.0, 4000);
    let clock = simpson(|s| s, 0.0, 1.0, 2);
    println!("house: E[M_1^2] by Simpson = {:.6}; isometry, E[clock at 1] = {:.6}", msq, clock);
    assert!((msq - clock).abs() < 1e-6);
    let mut series = 0.0;
    for k in 0..200000i64 {
        series += (if k % 2 == 0 { 1.0 } else { -1.0 }) / ((2 * k + 1) * (2 * k + 1) * (2 * k + 1)) as f64;
    }
    series *= 32.0 / PI.powi(3);
    println!("house: exit time of (-1, 1), E[tau] by series = {:.6}; optional stopping gives 1", series);
    assert!((series - 1.0).abs() < 1e-6);

    // ---- what breaks ----
    println!("break: martingale assumed, E[X_1] = {:.6}; true {:.6}", 1.0 / R0, exact);
    println!("break: lost mean read as a chance = {:.6}; P(reach cap {} by 1) = {:.6}", 1.0 / R0 - exact, CAP, capped(CAP, R0, T).0);
    println!("break: t for sqrt t at time 4 = {:.6}; true {:.6}", (2.0 * big_phi(R0 / 4.0) - 1.0) / R0, mean_closed(R0, 4.0));
    println!("ALL CHECKS PASS");
}
