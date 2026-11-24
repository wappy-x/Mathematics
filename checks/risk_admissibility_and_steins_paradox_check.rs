// Risk, minimax, admissibility and Stein's paradox -- the same check as the Python, in Rust.  No crates.
// Part 1: a coin flipped 16 times.  Each rule's risk (average squared miss) is computed two ways:
// a closed form, and an exact sum over all 17 possible head counts.  Minimax is found a third way,
// by searching the shrink rules (X + a)/(16 + 2a) for the smallest worst-case risk.
// Part 2: five means, each seen once with unit normal noise.  James-Stein risk comes from a
// Poisson series, from a seeded simulation of the actual loss, and from Stein's unbiased
// risk estimate averaged over the same draws.  Quadrature checks two more simulated risks.
const N: u64 = 16;
const P: usize = 5;

fn choose(n: u64, k: u64) -> f64 { (0..k).fold(1u64, |out, i| out * (n - i) / (i + 1)) as f64 }

// exact: sum over every head count x
fn risk_sum(rule: &dyn Fn(f64) -> f64, p: f64, n: u64) -> f64 {
    (0..=n)
        .map(|x| choose(n, x) * p.powi(x as i32) * (1.0 - p).powi((n - x) as i32) * (rule(x as f64) - p).powi(2))
        .sum()
}

fn simpson(g: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    let mut s = g(lo) + g(hi);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * g(lo + i as f64 * h);
    }
    s * h / 3.0
}

fn beta22(p: f64) -> f64 { 6.0 * p * (1.0 - p) } // the Beta(2, 2) prior density

// largest risk of (X + a)/(n + 2a) over a fine grid of p
fn worst(a: f64, n: u64) -> f64 {
    (0..=400).map(|i| risk_sum(&|x| (x + a) / (n as f64 + 2.0 * a), i as f64 / 400.0, n)).fold(f64::MIN, f64::max)
}

// E[1/S], S noncentral chi-square: Poisson mixture
fn einv(lam: f64, p: usize) -> f64 {
    let (mut s, mut w) = (0.0, (-lam / 2.0).exp());
    for k in 0..400 {
        s += w / ((p - 2 + 2 * k) as f64);
        w *= lam / 2.0 / (k + 1) as f64;
    }
    s
}
fn js_risk(lam: f64, c: f64, p: usize) -> f64 {
    p as f64 - c * (2.0 * (p as f64 - 2.0) - c) * einv(lam, p)
}

// SplitMix64, then Box-Muller for normal draws
struct Rng(u64);
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.uniform();
        let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}

// mean and standard error of each loss
fn simulate(rng: &mut Rng, theta: &[f64], reps: usize) -> Vec<(f64, f64)> {
    let mut acc = vec![(0.0f64, 0.0f64); 5];
    let pf = P as f64;
    for _ in 0..reps {
        let x: Vec<f64> = theta.iter().map(|t| t + rng.normal()).collect();
        let s: f64 = x.iter().map(|v| v * v).sum();
        let c = 1.0 - (pf - 2.0) / s;
        let cp = f64::max(0.0, c);
        let sq = |k: f64| -> f64 { x.iter().zip(theta).map(|(v, t)| (k * v - t).powi(2)).sum() };
        let losses = [sq(1.0), sq(c), pf - (pf - 2.0).powi(2) / s, sq(cp), (c * x[0] - theta[0]).powi(2)];
        for (j, l) in losses.iter().enumerate() {
            acc[j].0 += l;
            acc[j].1 += l * l;
        }
    }
    let r = reps as f64;
    acc.iter().map(|(s1, s2)| (s1 / r, ((s2 / r - (s1 / r).powi(2)) / r).sqrt())).collect()
}

fn f(v: f64, d: usize) -> String { format!("{:.*}", d, v) }

fn main() {
    let plain = |x: f64| x / N as f64;
    let minimax = |x: f64| (x + 2.0) / (N as f64 + 4.0);
    let (mut lo, mut hi) = (0.0f64, 5.0f64);
    for _ in 0..50 {
        // ternary search for the a with the smallest worst risk
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if worst(m1, N) < worst(m2, N) { hi = m2 } else { lo = m1 }
    }
    let a_best = (lo + hi) / 2.0;
    let grid: Vec<f64> = (0..=20).map(|i| i as f64 / 20.0).collect();
    let r_plain: Vec<f64> = grid.iter().map(|&p| risk_sum(&plain, p, N)).collect();
    let r_mm: Vec<f64> = grid.iter().map(|&p| risk_sum(&minimax, p, N)).collect();
    let r_half: Vec<f64> = grid.iter().map(|&p| risk_sum(&|x| x / 8.0, p, 8)).collect();
    let bayes_plain = simpson(&|p| beta22(p) * risk_sum(&plain, p, N), 0.0, 1.0, 400);
    let bayes_mm = simpson(&|p| beta22(p) * risk_sum(&minimax, p, N), 0.0, 1.0, 400);
    let a10 = 10f64.sqrt() / 2.0;
    let mx = |v: &Vec<f64>| v.iter().cloned().fold(f64::MIN, f64::max);
    let mn = |v: &Vec<f64>| v.iter().cloned().fold(f64::MAX, f64::min);

    let xs = [1.2, -0.4, 2.0, 0.3, -1.1];
    let s: f64 = xs.iter().map(|v| v * v).sum();
    let share = 1.0 - 3.0 / s;
    let js = |lam: f64| js_risk(lam, 3.0, P);
    let mut rng = Rng(20261123);
    let sim_obs = simulate(&mut rng, &xs, 100000);
    let sim_zero = simulate(&mut rng, &[0.0; 5], 100000);
    let sim_one = simulate(&mut rng, &[3.0, 0.0, 0.0, 0.0, 0.0], 100000);
    let lams: Vec<f64> = (0..=10).map(|i| 5.0 * i as f64).collect();
    // exact: the first mean's own risk at theta = (3,0,0,0,0), midpoint rule over X1 ~ N(3,1) and u = sqrt(R), R ~ chi-square(4)
    let cell = |x: f64, u: f64| (-(x - 3.0).powi(2) / 2.0).exp() * ((1.0 - 3.0 / (x * x + u * u)) * x - 3.0).powi(2) * u.powi(3) * (-u * u / 2.0).exp();
    let first = (0..800).map(|i| (0..500).map(|j| cell(-5.0 + (i as f64 + 0.5) * 0.02, (j as f64 + 0.5) * 0.02)).sum::<f64>()).sum::<f64>() * 0.02 * 0.02 / (2.0 * (2.0 * std::f64::consts::PI).sqrt());
    let jsp0 = simpson(&|s| (s - 6.0 + 9.0 / s) * s.powf(1.5) * (-s / 2.0).exp() / (3.0 * (2.0 * std::f64::consts::PI).sqrt()), 3.0, 80.0, 2000); // JS+ at 0
    let join = |v: Vec<String>, sep: &str| v.join(sep);

    println!("coin, n = 16");
    println!("plain X/16: risk at theta = 0.5, 0.2, 0.1 {} {} {}", f(r_plain[10], 6), f(r_plain[4], 6), f(r_plain[2], 6));
    println!("  closed form theta(1-theta)/16 at 0.5, 0.1 {} {}", f(0.25 / 16.0, 6), f(0.09 / 16.0, 6));
    println!("(X+2)/20: risk min and max over theta {} {}", f(mn(&r_mm), 6), f(mx(&r_mm), 6));
    println!("first 8 flips only: risk at 0.5, 0.1 {} {}", f(r_half[10], 6), f(r_half[2], 6));
    println!("risks cross where theta(1-theta) = 0.16, theta = {} {}", f(0.5 - (0.25f64 - 0.16).sqrt(), 2), f(0.5 + (0.25f64 - 0.16).sqrt(), 2));
    println!("constant guess 0.5: risk at 0.5, 0.1 {} {}", f(risk_sum(&|_| 0.5, 0.5, N), 6), f(risk_sum(&|_| 0.5, 0.1, N), 6));
    println!("Bayes risk under Beta(2,2): plain, (X+2)/20 {} {}", f(bayes_plain, 6), f(bayes_mm, 6));
    println!("  closed form (1/5)/16 {}", f(0.2 / 16.0, 6));
    println!("search: best a in (X+a)/(16+2a), worst risk {} {}", f(a_best, 4), f(worst(a_best, N), 6));
    println!("  sqrt(16)/2, 1/(4(sqrt(16)+1)^2) {} {}", f(16f64.sqrt() / 2.0, 4), f(1.0 / (4.0 * 25.0), 6));
    println!("(X+1)/18: worst risk {}", f(worst(1.0, N), 6));
    println!("11 heads of 16: plain, minimax {} {}", f(11.0 / 16.0, 4), f(13.0 / 20.0, 4));
    println!("house coin n = 10: minimax a, worst risk, plain worst {} {} {}", f(a10, 4), f(1.0 / (4.0 * (10f64.sqrt() + 1.0).powi(2)), 6), f(0.025, 6));
    println!("  7 of 10: plain, minimax, Beta(2,2) mean {} {} {}", f(0.7, 4), f((7.0 + a10) / (10.0 + 2.0 * a10), 4), f(9.0 / 14.0, 4));
    println!("five means, unit noise");
    println!("seen {} sum of squares {}", join(xs.iter().map(|&v| f(v, 1)).collect(), " "), f(s, 2));
    println!("share kept 1 - 3/S {}", f(share, 4));
    println!("James-Stein estimates {}", join(xs.iter().map(|&v| f(share * v, 3)).collect(), " "));
    println!("risk at |theta|^2 = 0: series, 5 - 9/3 {} {}", f(js(0.0), 4), f(5.0 - 9.0 / 3.0, 4));
    println!("risk at |theta|^2 = 6.9 (theta = the data) {}", f(js(s), 4));
    for (name, sim) in [("theta = data", &sim_obs), ("theta = 0", &sim_zero), ("theta = (3,0,0,0,0)", &sim_one)] {
        println!("sim {}: plain, JS, SURE, JS+, first mean", name);
        println!("  {}", join(sim.iter().map(|(m, se)| format!("{:.4}+-{:.4}", m, se)).collect(), "  "));
    }
    println!("exact at theta = (3,0,0,0,0): JS total, first mean by quadrature {} {}", f(js(9.0), 4), f(first, 4));
    println!("exact JS+ risk at theta = 0, by Simpson over S ~ chi-square(5) {}", f(jsp0, 4));
    println!("constant c at theta = 0: c = 3, 5, 6, 7 {}", join([3.0, 5.0, 6.0, 7.0].iter().map(|&c| f(js_risk(0.0, c, P), 4)).collect(), " "));
    println!("risk at 0 for k = 3, 10, 100 {}", join([3usize, 10, 100].iter().map(|&p| f(js_risk(0.0, p as f64 - 2.0, p), 4)).collect(), " "));
    println!("figure, coin plain risk x1000 at theta = 0, 0.05, .., 1: {}", join(r_plain.iter().map(|&r| f(1000.0 * r, 1)).collect(), ", "));
    println!("figure, JS risk at |theta|^2 = 0, 5, .., 50: {}", join(lams.iter().map(|&l| f(js(l), 2)).collect(), ", "));
    assert!(r_plain.iter().zip(&grid).all(|(r, p)| (r - p * (1.0 - p) / 16.0).abs() < 1e-12)); // sum against closed form
    assert!((mx(&r_mm) - 0.01).abs() < 1e-12 && (mn(&r_mm) - 0.01).abs() < 1e-12); // constant risk, by summing
    assert!((bayes_plain - 0.2 / 16.0).abs() < 1e-9 && (bayes_mm - 0.01).abs() < 1e-9); // Simpson against Beta moments
    assert!((a_best - 2.0).abs() < 1e-3); // search finds sqrt(n)/2
    assert!((1..20).all(|i| r_half[i] > r_plain[i])); // throwing flips away is dominated
    assert!((js(0.0) - 2.0).abs() < 1e-12 && lams.iter().all(|&l| js(l) < 5.0)); // series against chi-square mean
    for (sim, lam) in [(&sim_obs, s), (&sim_zero, 0.0), (&sim_one, 9.0)] {
        assert!((sim[1].0 - js(lam)).abs() < 4.0 * sim[1].1); // simulated loss against series
        assert!((sim[2].0 - js(lam)).abs() < 4.0 * sim[2].1); // unbiased risk estimate too
        assert!((sim[0].0 - 5.0).abs() < 4.0 * sim[0].1); // plain averages: risk 5
    }
    assert!((sim_one[4].0 - first).abs() < 4.0 * sim_one[4].1); // first mean: simulation against quadrature
    assert!((sim_zero[3].0 - jsp0).abs() < 4.0 * sim_zero[3].1); // positive part: simulation against Simpson
    println!("ALL CHECKS PASS");
}
