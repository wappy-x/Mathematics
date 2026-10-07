// The central limit theorem, proved -- the same check as the Python, in Rust.
// No crates.  One fair die, faces 1 to 6.  S is the total of 100 independent
// rolls: mean 350, standard deviation 17.08.  Rust has no big integers, so the
// law of S is convolved in f64, and the whole-number count of sequences is
// checked modulo the prime 2^61 - 1, by convolution and by inclusion-exclusion.
use std::f64::consts::PI;

const N: usize = 100;
const CUT: usize = 330;
const DELTA: f64 = 0.5;
const C_SHEV: f64 = 0.4748;
const P61: u128 = (1u128 << 61) - 1;

fn phi_cdf(z: f64) -> f64 {              // 1/2 + phi(z) * sum z^(2k+1) / (1*3*...*(2k+1))
    if z.abs() > 8.0 { return if z < 0.0 { 0.0 } else { 1.0 }; }  // beyond 8 the tail is below 1e-15
    let (mut term, mut total, mut k) = (z, z, 0.0);
    while term.abs() > 1e-17 * total.abs() {
        k += 1.0;
        term *= z * z / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + (-z * z / 2.0).exp() / (2.0 * PI).sqrt() * total
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let w = |i: usize| if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
    h / 3.0 * (0..=m).map(|i| w(i) * f(a + i as f64 * h)).sum::<f64>()
}

fn pow_mod(mut b: u128, mut e: u128) -> u128 {
    let mut r = 1u128;
    while e > 0 { if e & 1 == 1 { r = r * b % P61; } b = b * b % P61; e >>= 1; }
    r
}

fn comb_mod(n: usize, k: usize) -> u128 {  // n choose k modulo the prime, by Fermat inverses
    if k > n { return 0; }
    let (mut num, mut den) = (1u128, 1u128);
    for j in 0..k { num = num * (n - j) as u128 % P61; den = den * (j + 1) as u128 % P61; }
    num * pow_mod(den, P61 - 2) % P61
}

fn main() {
    // ---- one roll, exactly: in 96ths, since 3.5 = 7/2 ----
    let rho = (1..=6i64).map(|k| (2 * k - 7).abs().pow(3)).sum::<i64>() as f64 / 48.0;
    let m4 = (1..=6i64).map(|k| (2 * k - 7).pow(4)).sum::<i64>() as f64 / 96.0;
    let var: f64 = 35.0 / 12.0;
    let sig = var.sqrt();
    let (ratio, kurt) = (rho / sig.powi(3), m4 / (var * var));
    println!("one roll: mean 7/2, variance 35/12, E|X - 3.5|^3 = {}/8, E(X - 3.5)^4 = {}/48", (rho * 8.0).round(), (m4 * 48.0).round());
    println!("sigma = {:.4}; rho/sigma^3 = {:.4}; E[Y^4] = {:.4}", sig, ratio, kurt);

    // ---- road 1: the law of S by convolution, every k from 1 to 100 kept ----
    let mut probs: Vec<Vec<f64>> = vec![vec![1.0]];
    let mut counts: Vec<u128> = vec![1];              // modulo 2^61 - 1
    for _ in 1..=N {
        let last = probs.last().unwrap();
        let mut new = vec![0.0; last.len() + 6];
        let mut newc = vec![0u128; counts.len() + 6];
        for s in 0..last.len() {
            for f in 1..=6 { new[s + f] += last[s] / 6.0; newc[s + f] = (newc[s + f] + counts[s]) % P61; }
        }
        probs.push(new);
        counts = newc;
    }
    let two = (1..=6).flat_map(|a| (1..=6).map(move |b| a + b)).filter(|&t| t <= 7).count();
    println!("two rolls: {} of 36 totals <= 7, P(Z_2 <= 0) = {}/12 against Phi(0) = {}", two, two / 3, phi_cdf(0.0));
    let sd = (N as f64 * var).sqrt();
    println!("total of {} rolls: mean {}, variance {}/3, standard deviation {:.4}", N, 7 * N / 2, 35 * N / 4, sd);
    let below = counts[..=CUT].iter().fold(0u128, |a, &c| (a + c) % P61);
    let (mut plus, mut minus) = (0u128, 0u128);        // road 2: inclusion-exclusion
    for j in 0..=(CUT - N) / 6 {
        let term = comb_mod(N, j) * comb_mod(CUT - 6 * j, N) % P61;
        if j % 2 == 0 { plus = (plus + term) % P61 } else { minus = (minus + term) % P61 }
    }
    let incl_excl = (plus + P61 - minus) % P61;
    assert_eq!(below, incl_excl);
    println!("roll sequences with total <= {}, mod 2^61 - 1: {} by convolution, {} by inclusion-exclusion", CUT, below, incl_excl);
    let exact: f64 = probs[N][..=CUT].iter().sum();
    let (z, zc) = ((CUT as f64 - 350.0) / sd, (CUT as f64 + 0.5 - 350.0) / sd);
    println!("P(S <= {}) exact = {:.6}", CUT, exact);
    println!("normal: z = {:.4}, Phi(z) = {:.6}; half-step z = {:.4}, Phi = {:.6}", z, phi_cdf(z), zc, phi_cdf(zc));
    println!("gaps: exact - Phi(z) = {:.6}; exact - half-step = {:.6}", exact - phi_cdf(z), exact - phi_cdf(zc));
    let be = C_SHEV * ratio / (N as f64).sqrt();
    println!("Berry-Esseen: {} x {:.4} / sqrt({}) = {:.4}", C_SHEV, ratio, N, be);
    assert!((exact - phi_cdf(z)).abs() <= be);

    // ---- figure 1: mass of S against the normal density, times 1000 ----
    let xs: Vec<usize> = (300..=400).step_by(10).collect();
    let join = |v: Vec<String>| v.join(", ");
    println!("figure, s: {}", join(xs.iter().map(|s| s.to_string()).collect()));
    println!("figure, P(S = s) x 1000: {}", join(xs.iter().map(|&s| format!("{:.2}", 1000.0 * probs[N][s])).collect()));
    println!("figure, normal density x 1000: {}", join(xs.iter().map(|&s| {
        let u = (s as f64 - 350.0) / sd;
        format!("{:.2}", 1000.0 * (-u * u / 2.0).exp() / (sd * (2.0 * PI).sqrt()))
    }).collect()));

    // ---- the largest CDF gap over every threshold, against Berry-Esseen ----
    let (mut gap_fig, mut bound_fig) = (Vec::new(), Vec::new());
    for n in [1usize, 2, 5, 10, 20, 50, 100] {
        let (mut f, mut worst, s_n) = (0.0f64, 0.0f64, (n as f64 * var).sqrt());
        for s in n..=6 * n {
            let ph = phi_cdf((s as f64 - 3.5 * n as f64) / s_n);
            worst = worst.max((f - ph).abs());
            f += probs[n][s];
            worst = worst.max((f - ph).abs());
        }
        let bound = (C_SHEV * ratio / (n as f64).sqrt()).min(1.0);
        println!("n = {}: largest gap {:.4}, Berry-Esseen bound {:.4}, sqrt(n) x gap {:.4}", n, worst, bound, (n as f64).sqrt() * worst);
        assert!(worst <= bound);
        gap_fig.push(format!("{:.2}", 1000.0 * worst));
        bound_fig.push(format!("{:.2}", 1000.0 * bound));
    }
    println!("figure, largest gap x 1000: {}", gap_fig.join(", "));
    println!("figure, Berry-Esseen bound x 1000: {}", bound_fig.join(", "));

    // ---- Lindeberg's swap: replace rolls by normals one at a time ----
    let g3 = 2.0 * (2.0 / PI).sqrt();
    let g3_num = simpson(&|g: f64| g.abs().powi(3) * (-g * g / 2.0).exp() / (2.0 * PI).sqrt(), -12.0, 12.0, 2400);
    println!("E|G|^3 = 2 sqrt(2/pi) = {:.6}; by Simpson {:.6}", g3, g3_num);
    assert!((g3 - g3_num).abs() < 1e-8);
    let hybrid = |k: usize| -> f64 {             // E h(W_k): k standardized rolls, N - k normals
        let b = (DELTA * DELTA + (N - k) as f64 / N as f64).sqrt();
        probs[k].iter().enumerate().filter(|(_, &p)| p > 0.0)
            .map(|(s, &p)| p * phi_cdf((z - (s as f64 - 3.5 * k as f64) / sd) / b)).sum::<f64>()
    };
    let h: Vec<f64> = (0..=N).map(hybrid).collect();
    let eh_simpson = simpson(&|g: f64| phi_cdf((z - g) / DELTA) * (-g * g / 2.0).exp() / (2.0 * PI).sqrt(), -12.0, 12.0, 2400);
    println!("smooth step h(u) = Phi((a - u)/{}), a = {:.4}: E h(Z_100) = {:.6}, E h(G) = {:.6}, by Simpson {:.6}", DELTA, z, h[N], h[0], eh_simpson);
    assert!((h[0] - eh_simpson).abs() < 1e-7);
    let h3 = 1.0 / (2.0 * PI).sqrt() / DELTA.powi(3);   // sup |h'''|: phi''(x) = (x^2 - 1) phi(x) peaks at x = 0
    let per_swap = h3 * (ratio + g3) / (6.0 * (N as f64).powf(1.5));
    let largest = (1..=N).map(|k| (h[k] - h[k - 1]).abs()).fold(0.0, f64::max);
    let total = (h[N] - h[0]).abs();
    let sci = |x: f64| { let s = format!("{:.2e}", x); s.replace("e-", "e-0") };
    println!("swap bound per roll {:.6}, over {} rolls {:.4}; largest actual swap {}, all {} together {}", per_swap, N, N as f64 * per_swap, sci(largest), N, sci(total));
    assert!(largest <= per_swap); // every swap within Step 3's bound

    // ---- road 3: the characteristic function of Z_n against exp(-t^2/2) ----
    let chf = |t: f64, n: usize| -> f64 {
        ((1..=6).map(|k| ((k as f64 - 3.5) * t / (sig * (n as f64).sqrt())).cos()).sum::<f64>() / 6.0).powi(n as i32)
    };
    for t in [1.0f64, 2.0] {
        let row: Vec<f64> = [1usize, 10, 100, 1000].iter().map(|&n| chf(t, n)).collect();
        println!("t = {:.0}: phi_Zn at n = 1, 10, 100, 1000: {}; limit {:.6}", t, join(row.iter().map(|v| format!("{:.6}", v)).collect()), (-t * t / 2.0).exp());
        for (n, v) in [10usize, 100, 1000].iter().zip(&row[1..]) {
            assert!((v - (-t * t / 2.0).exp()).abs() <= (kurt / 24.0 + 0.125) * t.powi(4) / *n as f64);
        }
    }
    println!("bound at t = 1, n = 100: (E[Y^4]/24 + 1/8)/100 = {:.6}", (kurt / 24.0 + 0.125) / 100.0);

    // ---- what breaks ----
    let cau: Vec<f64> = [1usize, 4, 100].iter().map(|&n| (-1.0 / (n as f64).sqrt()).exp().powi(n as i32)).collect();
    println!("Cauchy steps, phi at t = 1 after dividing by sqrt(n): n = 1, 4, 100: {:.4}, {:.4}, {:.6}", cau[0], cau[1], cau[2]);
    let low = (1..=6usize).filter(|&k| N * k <= CUT).count();  // faces k with 100 k <= 330
    println!("one roll copied {} times: P(S <= {}) = {}/6 = {}", N, CUT, low, low as f64 / 6.0);
    println!("standard deviation taken as {} x sigma = {:.2}: Phi = {:.4}", N, N as f64 * sig, phi_cdf((CUT as f64 - 350.0) / (N as f64 * sig)));
    let p: f64 = 1.0 / 10000.0;
    println!("rare event p = 1/10000, {} trials: P(count <= np) = P(count = 0) = {:.4}", N, (1.0 - p).powi(N as i32));
    println!("ALL CHECKS PASS");
}
