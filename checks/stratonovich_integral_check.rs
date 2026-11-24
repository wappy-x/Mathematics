// The Stratonovich integral -- the same check as the Python, in Rust.  No crates.
// W is Brownian motion, t in years.  The Stratonovich sum reads the integrand at
// the middle of each step; the Ito sum reads it at the start.  Roads: a 4-step
// path in whole tenths, exactly; one seeded path pinned to end at W_1 = 1.4;
// an ordinary differential equation along a smoothed path (Wong-Zakai); and
// 20000 seeded paths for averages.
const MU: f64 = 0.05;
const SIG: f64 = 0.20;
const S0: f64 = 100.0; // the share, read the Stratonovich way

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) * 2f64.powi(-53) }
    fn normal(&mut self) -> f64 { // Box-Muller, cosine branch only
        let u = self.uniform();
        let v = self.uniform();
        (-2.0 * u.ln()).sqrt() * (2.0 * std::f64::consts::PI * v).cos()
    }
}

fn mean_se(s: f64, s2: f64, m: f64) -> (f64, f64) { // sample mean and its standard error
    let a = s / m;
    (a, ((s2 / m - a * a) * m / (m - 1.0) / m).sqrt())
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    // Road 1: four quarter-year steps, W in whole tenths, so every sum is an exact integer
    let w: [i64; 5] = [0, 8, 6, 10, 14];
    let (mut left, mut right, mut mid2, mut qv) = (0i64, 0i64, 0i64, 0i64);
    for k in 0..4 {
        let d = w[k + 1] - w[k];
        left += w[k] * d; right += w[k + 1] * d; mid2 += (w[k] + w[k + 1]) * d; qv += d * d;
        println!("hand, step {}: W {:.1} to {:.1}, move {:.1}, half-move {:.1}, middle {:.1}, start x move {:.2}, middle x move {:.2}, move squared {:.2}",
            k + 1, w[k] as f64 / 10.0, w[k + 1] as f64 / 10.0, d as f64 / 10.0, d as f64 / 20.0, (w[k] + w[k + 1]) as f64 / 20.0,
            (w[k] * d) as f64 / 100.0, ((w[k] + w[k + 1]) * d) as f64 / 200.0, (d * d) as f64 / 100.0);
    }
    assert!(mid2 == w[4] * w[4]); // midpoint sum telescopes to W^2/2
    assert!(2 * left == w[4] * w[4] - qv); // left sum = W^2/2 - (sum of squares)/2
    assert!(right - left == qv);
    println!("hand, totals: Ito (start) {:.2}, Stratonovich (middle) {:.2}, end-point {:.2}, sum of squares {:.2}, gap {:.2}",
        left as f64 / 100.0, mid2 as f64 / 200.0, right as f64 / 100.0, qv as f64 / 100.0, (mid2 - 2 * left) as f64 / 200.0);

    // Road 2: one seeded path of 20000 half-steps, pinned to end at 1.4 (a Brownian bridge)
    let mut rng = SplitMix64 { s: 20261123 };
    let n_big: usize = 10000;
    let end = 1.4;
    let mut f = vec![0.0f64];
    for _ in 0..2 * n_big { let x = f[f.len() - 1] + (1.0 / (2 * n_big) as f64).sqrt() * rng.normal(); f.push(x); }
    let last = f[2 * n_big];
    for j in 0..=2 * n_big { f[j] = f[j] - j as f64 / (2 * n_big) as f64 * (last - end); }
    let (mut lsum, mut tsum, mut msum, mut q, mut sd, mut sl, mut sint) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    let mut chart: Vec<Vec<f64>> = vec![vec![0.0], vec![0.0], vec![0.0]];
    for k in 0..n_big {
        let (a, m, b) = (f[2 * k], f[2 * k + 1], f[2 * k + 2]);
        let (d, dt) = (b - a, 1.0 / n_big as f64);
        lsum += a * d; tsum += 0.5 * (a + b) * d; msum += m * d; q += d * d;
        let sa = S0 * (MU * k as f64 * dt + SIG * a).exp();
        let sb = S0 * (MU * (k + 1) as f64 * dt + SIG * b).exp();
        sd += 0.5 * (sa + sb) * (MU * dt + SIG * d); // Stratonovich sum for dS
        sl += sa * (MU * dt + SIG * d); sint += sa * dt; // Ito-reading sum, and int S dt
        if (k + 1) % 500 == 0 { chart[0].push(tsum); chart[1].push(lsum); chart[2].push(0.5 * q); }
    }
    let nf = n_big as f64;
    assert!((tsum - end * end / 2.0).abs() < 1e-9);
    assert!((msum - end * end / 2.0).abs() < 4.0 * (1.0 / (4.0 * nf)).sqrt());
    assert!((lsum - (end * end - 1.0) / 2.0).abs() < 4.0 * (2.0 / nf).sqrt() / 2.0);
    assert!((q - 1.0).abs() < 4.0 * (2.0 / nf).sqrt());
    println!("path, {} steps, W_1 = {:.4}: sum of squares {:.4} (limit 1)", n_big, f[2 * n_big], q);
    println!("path, Stratonovich, average of ends: {:.4}; at the middle time: {:.4}; W^2/2 = {:.4}", tsum, msum, end * end / 2.0);
    println!("path, Ito (start): {:.4}; (W^2 - 1)/2 = {:.4}; end-point sum {:.4}", lsum, (end * end - 1.0) / 2.0, tsum + 0.5 * q);
    println!("path, gap Stratonovich - Ito {:.4}, half the sum of squares {:.4}", tsum - lsum, 0.5 * q);
    for (i, name) in ["Stratonovich sum", "Ito sum", "half the squares"].iter().enumerate() {
        println!("chart, {}: {}", name, join(&chart[i]));
    }
    let s1 = S0 * (MU + SIG * end).exp();
    assert!((sd - (s1 - S0)).abs() < 0.01); // ordinary chain rule, path by path
    assert!(((s1 - S0) - sl - 0.5 * SIG * SIG * sint).abs() < 0.1); // Ito reading needs the half sigma^2 term
    println!("share, S_1 = 100 exp(0.05 + 0.2 W_1) = {:.4}; Stratonovich sum of dS {:.4}; Ito-reading sum {:.4}", s1, sd, sl);
    println!("share, half sigma^2 x int S dt = {:.4}; Ito-reading sum plus it {:.4}", 0.5 * SIG * SIG * sint, sl + 0.5 * SIG * SIG * sint);

    // Road 3: Wong-Zakai. Join the path's values every 0.01 year by straight lines and
    // solve the ordinary equation dS/dt = S (0.05 + 0.2 x slope) by Runge-Kutta.
    let mut x = S0;
    for k in 0..100 {
        let slope = (f[200 * (k + 1)] - f[200 * k]) / 0.01;
        let h = 0.01 / 20.0;
        let g = |s: f64| s * (MU + SIG * slope);
        for _ in 0..20 {
            let k1 = g(x);
            let k2 = g(x + h / 2.0 * k1);
            let k3 = g(x + h / 2.0 * k2);
            let k4 = g(x + h * k3);
            x += h / 6.0 * (k1 + 2.0 * k2 + 2.0 * k3 + k4);
        }
    }
    let ito_sol = S0 * (MU - SIG * SIG / 2.0 + SIG * end).exp();
    assert!((x - s1).abs() < 1e-6 * s1 && (x - ito_sol).abs() > 2.0);
    println!("smoothed path, ordinary equation: S_1 = {:.4}; Stratonovich solution {:.4}; Ito solution {:.4}", x, s1, ito_sol);

    // Road 4: 20000 seeded paths of 100 steps: averages
    let (m_paths, n) = (20000usize, 100usize);
    let dt = 1.0 / n as f64;
    let mut acc = [[0.0f64; 2]; 6];
    let mut worst = 0.0f64;
    for _ in 0..m_paths {
        let (mut wv, mut lf) = (0.0f64, 0.0f64);
        let (mut heun, mut eul7, mut eul5) = (S0, S0, S0);
        let (mut cx, mut cy, mut r2) = (1.0f64, 0.0f64, 1.0f64);
        for _ in 0..n {
            let d = dt.sqrt() * rng.normal();
            lf += wv * d; wv += d;
            let p = heun + heun * (MU * dt + SIG * d); // Heun: predict, then average the ends
            heun += 0.5 * (heun + p) * (MU * dt + SIG * d);
            eul7 += eul7 * ((MU + SIG * SIG / 2.0) * dt + SIG * d); // converted to Ito, Euler step
            eul5 += eul5 * (MU * dt + SIG * d); // NOT converted: the mistake
            r2 *= 1.0 + d * d; // Ito rotation dX = -Y dW, dY = X dW, Euler
            let c = d / 2.0;
            let nx = (cx * (1.0 - c * c) - 2.0 * c * cy) / (1.0 + c * c);
            let ny = (cy * (1.0 - c * c) + 2.0 * c * cx) / (1.0 + c * c);
            cx = nx; cy = ny;
        }
        worst = worst.max((cx * cx + cy * cy - 1.0).abs());
        for (a, v) in acc.iter_mut().zip([wv * wv / 2.0, lf, heun, eul7, eul5, r2]) { a[0] += v; a[1] += v * v; }
    }
    let names = ["Stratonovich int W dW", "Ito int W dW", "share, Heun (Stratonovich)",
        "share, Euler with drift 0.07", "share, Euler with drift 0.05", "Ito rotation, radius squared"];
    let nn = n as f64;
    let exact = [0.5, 0.0, S0 * (1.0 + MU * dt + 0.5 * (MU * MU * dt * dt + SIG * SIG * dt)).powf(nn),
        S0 * (1.0 + (MU + SIG * SIG / 2.0) * dt).powf(nn), S0 * (1.0 + MU * dt).powf(nn), (1.0 + dt).powf(nn)];
    println!("averages, {} paths, {} steps, seed 20261123", m_paths, n);
    for i in 0..6 {
        let (m, se) = mean_se(acc[i][0], acc[i][1], m_paths as f64);
        assert!((m - exact[i]).abs() < 4.0 * se);
        println!("averages, {}: {:.4} +/- {:.4} (exact {:.4})", names[i], m, se, exact[i]);
    }
    assert!(worst < 1e-12);
    println!("averages, Stratonovich rotation: radius squared within 1e-12 of 1 on every path; Ito limit e = {:.4}", 1f64.exp());
    println!("share, no grid: Stratonovich mean 100 e^0.07 = {:.2}, median 100 e^0.05 = {:.2}; Ito median 100 e^0.03 = {:.2}",
        S0 * (MU + SIG * SIG / 2.0).exp(), S0 * MU.exp(), S0 * (MU - SIG * SIG / 2.0).exp());
    println!("ALL CHECKS PASS");
}
