// Monte Carlo estimates and error -- the check behind the card.  Rust std only.
// Pi from 10,000 darts thrown at a unit square, with its standard error.
// Road 1: exact values: pi from Machin's arctangent series, sigma from p = pi / 4.
// Road 2: a deterministic grid, every cell centre of the square counted.
// Road 3: seeded simulation from a SplitMix64 generator written out below.
const SEED: u64 = 1946;
const N: usize = 10000; const R: usize = 200; // darts per run, repeated runs
const CHECK: [usize; 6] = [100, 400, 1600, 6400, 10000, 25600]; // dart counts watched inside each run

struct SplitMix(u64);
impl SplitMix {
    fn u(&mut self) -> f64 { // one uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn atan_series(x: f64) -> f64 { // x - x^3/3 + x^5/5 - ...
    let (mut term, mut total, mut k) = (x, 0.0, 0.0);
    while term.abs() > 1e-18 {
        total += term / (2.0 * k + 1.0);
        term *= -x * x;
        k += 1.0;
    }
    total
}

fn phi_cdf(z: f64) -> f64 { // standard normal area left of z, by series
    let (mut term, mut total) = (z, z);
    for k in 1..300 {
        let k = k as f64;
        term *= -z * z / (2.0 * k);
        total += term / (2.0 * k + 1.0);
    }
    0.5 + total / (2.0 * 3.141592653589793f64).sqrt()
}

fn quantile(q: f64) -> f64 { // Phi^(-1)(q) by bisection
    let (mut lo, mut hi) = (0.0, 8.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if phi_cdf(mid) < q { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn inside(x: f64, y: f64) -> bool { x * x + y * y <= 1.0 }

fn main() {
    let mut g = SplitMix(SEED);
    let (nf, rf) = (N as f64, R as f64);
    let pi = 16.0 * atan_series(1.0 / 5.0) - 4.0 * atan_series(1.0 / 239.0);
    let (p, z) = (pi / 4.0, quantile(0.975));
    let sigma = 4.0 * (p * (1.0 - p)).sqrt(); // spread of one dart's score, 4 or 0
    println!("road 1, exact: pi {:.6}, p = pi/4 {:.6}, sigma = 4 sqrt(p(1-p)) {:.6}", pi, p, sigma);
    println!("  z for 95% {:.6}; true standard error at {} darts {:.6}", z, N, sigma / nf.sqrt());
    let mut grid = 0.0;
    for m in [100i64, 1000] {
        let count = (0..m).flat_map(|i| (0..m).map(move |j| (i, j)))
            .filter(|&(i, j)| (2 * i + 1) * (2 * i + 1) + (2 * j + 1) * (2 * j + 1) <= 4 * m * m).count();
        grid = 4.0 * count as f64 / m as f64 / m as f64;
        println!("road 2, grid of {}x{} cell centres: {} inside, 4 x fraction {:.6}", m, m, count, grid);
    }
    let (mut darts, mut k_hits) = (Vec::new(), 0usize);
    for i in 0..N {
        let (x, y) = (g.u(), g.u());
        if inside(x, y) { k_hits += 1; }
        if i < 20 { darts.push((x, y)); }
    }
    let (p_hat, pi_hat) = (k_hits as f64 / nf, 4.0 * k_hits as f64 / nf);
    let s = (16.0 * p_hat * (1.0 - p_hat) * nf / (nf - 1.0)).sqrt();
    let se = s / nf.sqrt();
    println!("road 3, {} darts, seed {}: {} inside, fraction {:.4}, estimate {:.4}", N, SEED, k_hits, p_hat, pi_hat);
    println!("  sample spread s {:.6}, standard error s/root n {:.6}", s, se);
    println!("  95% interval {:.4} to {:.4}; miss from pi {:.4} = {:.2} standard errors",
             pi_hat - z * se, pi_hat + z * se, pi_hat - pi, (pi_hat - pi) / se);
    for a in [0usize, 10] {
        let row: Vec<String> = darts[a..a + 10].iter()
            .map(|&(x, y)| format!("({:.0},{:.0},{})", 40.0 + 200.0 * x, 220.0 - 200.0 * y, inside(x, y) as i32))
            .collect();
        println!("figure, darts {}-{} (x, y, 1 = inside): {}", a + 1, a + 10, row.join(" "));
    }
    let h20 = darts.iter().filter(|&&(x, y)| inside(x, y)).count();
    println!("figure, first 20 darts: {} inside, estimate 4 x {}/20 = {:.2}", h20, h20, 4.0 * h20 as f64 / 20.0);
    let (mut g1, mut g2) = (0.0, 0.0);
    for _ in 0..N {
        let h = 4.0 * (1.0 - g.u().powi(2)).sqrt(); // height of the curve at a random x
        g1 += h; g2 += h * h;
    }
    let (semi, s_semi) = (g1 / nf, ((g2 - g1 * g1 / nf) / (nf - 1.0)).sqrt());
    let sig_semi = (32.0 / 3.0 - pi * pi).sqrt(); // spread of one height: E[16(1 - x^2)] = 32/3
    println!("curve heights 4 sqrt(1 - x^2), {} draws: estimate {:.4}, s {:.6} (exact {:.6}), standard error {:.6}",
             N, semi, s_semi, sig_semi, s_semi / nf.sqrt());
    let mut est: Vec<Vec<f64>> = vec![Vec::new(); CHECK.len()];
    let (mut cover, mut cover_n) = (0usize, 0usize);
    for _ in 0..R {
        let mut k = 0usize;
        for i in 1..=CHECK[CHECK.len() - 1] {
            let (x, y) = (g.u(), g.u());
            if inside(x, y) { k += 1; }
            if let Some(c) = CHECK.iter().position(|&c| c == i) {
                est[c].push(4.0 * k as f64 / i as f64);
                if i == N {
                    let q = k as f64 / nf;
                    let sr = (16.0 * q * (1.0 - q) * nf / (nf - 1.0)).sqrt();
                    if (4.0 * q - pi).abs() <= z * sr / nf.sqrt() { cover += 1; }
                    if (4.0 * q - pi).abs() <= z * sr / nf { cover_n += 1; }
                }
            }
        }
    }
    println!("{} repeated runs: n, true standard error sigma/root n, observed root-mean-square miss", R);
    let mut rms = Vec::new();
    for (ci, &c) in CHECK.iter().enumerate() {
        let r = (est[ci].iter().map(|e| (e - pi) * (e - pi)).sum::<f64>() / rf).sqrt();
        rms.push(r);
        println!("  {:>5}  {:.4}  {:.4}", c, sigma / (c as f64).sqrt(), r);
    }
    let mean10 = est[4].iter().sum::<f64>() / rf;
    let spread10 = (est[4].iter().map(|e| (e - mean10) * (e - mean10)).sum::<f64>() / (rf - 1.0)).sqrt();
    println!("  at {}: mean of estimates {:.4}, their spread {:.6}", N, mean10, spread10);
    println!("  95% intervals covering pi: {} of {} = {:.3}", cover, R, cover as f64 / rf);
    let clt_n = (z * sigma / 0.01) * (z * sigma / 0.01);
    println!("darts for +/- 0.01 at 95%: CLT (z sigma / 0.01)^2 = {:.0}; Chebyshev sigma^2 / (0.05 x 0.01^2) = {:.0}",
             clt_n, sigma * sigma / (0.05 * 0.0001));
    println!("what breaks, the right answer is {:.4} +/- {:.4}", pi_hat, se);
    let mut kb = 0usize;
    for _ in 0..N {
        let w = g.u();
        if inside(w, w) { kb += 1; } // one random number used for both coordinates
    }
    let qb = kb as f64 / nf;
    let se_b = 4.0 * (qb * (1.0 - qb) / nf).sqrt();
    println!("  same number for x and y: {:.4} +/- {:.4}; exact 4/root 2 = {:.4}", 4.0 * qb, se_b, 4.0 / 2f64.sqrt());
    println!("  error bar s/n, not s/root n: +/- {:.6}; covers pi in {} of {} runs", s / nf, cover_n, R);
    println!("  forgetting the 4: {:.4}", p_hat);
    let mut heavy = 0usize;
    for _ in 0..R {
        let (mut h1, mut h2) = (0.0, 0.0);
        for _ in 0..N {
            let h = 0.2 * (1.0 - g.u()).powf(-0.8); // integral over [0, 1] is 1, variance infinite
            h1 += h; h2 += h * h;
        }
        let hs = ((h2 - h1 * h1 / nf) / (nf - 1.0)).sqrt();
        if (h1 / nf - 1.0).abs() <= z * hs / nf.sqrt() { heavy += 1; }
    }
    println!("  infinite variance, 0.2 x^-0.8 on [0, 1]: 95% intervals cover 1 in {} of {} runs", heavy, R);
    println!("try: 40000 darts, standard error {:.4}; 1000000 darts {:.4}; curve heights at 10000 {:.4}",
             sigma / 40000f64.sqrt(), sigma / 1000000f64.sqrt(), sig_semi / nf.sqrt());
    assert!((grid - pi).abs() < 1e-3, "grid count vs Machin's series");
    let bell: f64 = (0..=1000).map(|k| (if k == 0 || k == 1000 { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 })
        * (-(k as f64 * z / 1000.0).powi(2) / 2.0).exp()).sum();
    assert!((bell * z / 3000.0 / (2.0 * pi).sqrt() - 0.475).abs() < 1e-9, "z: bell area 0 to z by Simpson's rule is 0.475");
    assert!((mean10 - pi).abs() < 4.0 * sigma / (nf * rf).sqrt(), "estimates average to pi: no bias");
    assert!((pi_hat - pi).abs() < 4.0 * se, "simulation vs exact pi");
    assert!((s - sigma).abs() < 4.0 * 2.0 * (2.0 * p - 1.0) / nf.sqrt(), "sample spread vs 4 sqrt(p(1-p)): s has se 2(2p-1)/root n");
    assert!((spread10 - sigma / nf.sqrt()).abs() < 4.0 * sigma / nf.sqrt() / (2.0 * rf).sqrt(), "spread of runs");
    for (ci, &c) in CHECK.iter().enumerate() {
        assert!((rms[ci] / (sigma / (c as f64).sqrt()) - 1.0).abs() < 4.0 / (2.0 * rf).sqrt(), "miss shrinks as 1/root n");
    }
    assert!((cover as f64 / rf - 0.95).abs() < 4.0 * (0.95 * 0.05 / rf).sqrt(), "coverage vs 95%");
    assert!((semi - pi).abs() < 4.0 * s_semi / nf.sqrt(), "curve heights vs exact pi");
    assert!((s_semi - sig_semi).abs() < 0.02, "curve heights' spread vs sqrt(32/3 - pi^2)");
    assert!((4.0 * qb - 4.0 / 2f64.sqrt()).abs() < 4.0 * se_b, "shared number lands on 4/root 2");
    assert!((heavy as f64 / rf) < 0.95 - 4.0 * (0.95 * 0.05 / rf).sqrt(), "infinite variance breaks the interval");
    println!("ALL CHECKS PASS");
}
