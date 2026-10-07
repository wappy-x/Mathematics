// Information coefficient and the fundamental law -- the same check in Rust.
// Standard library only, no crates. Own random numbers (splitmix64 + Box-Muller),
// own normal CDF (Simpson), own sums. Prints the same rows as the Python check.
use std::f64::consts::PI;

struct Rng { state: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {                  // splitmix64, then 53 bits into (0, 1)
        self.state = self.state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^= z >> 31;
        ((z >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normals(&mut self, n: usize) -> Vec<f64> {   // Box-Muller, two draws per pair
        let mut out = Vec::with_capacity(n + 1);
        while out.len() < n {
            let r = (-2.0 * self.uniform().ln()).sqrt();
            let a = 2.0 * PI * self.uniform();
            out.push(r * a.cos());
            out.push(r * a.sin());
        }
        out.truncate(n);
        out
    }
}

fn big_n(x: f64) -> f64 {                           // bell-curve area left of x, Simpson on [0, |x|]
    let n = 2000;
    let h = x.abs() / n as f64;
    let f = |t: f64| (-0.5 * t * t).exp() / (2.0 * PI).sqrt();
    let mut s = f(0.0) + f(x.abs());
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h); }
    let area = s * h / 3.0;
    if x >= 0.0 { 0.5 + area } else { 0.5 - area }
}

fn pearson(x: &[f64], y: &[f64]) -> f64 {
    let n = x.len() as f64;
    let mx = x.iter().sum::<f64>() / n;
    let my = y.iter().sum::<f64>() / n;
    let (mut sxy, mut sxx, mut syy) = (0.0, 0.0, 0.0);
    for (a, b) in x.iter().zip(y) {
        sxy += (a - mx) * (b - my);
        sxx += (a - mx) * (a - mx);
        syy += (b - my) * (b - my);
    }
    sxy / (sxx * syy).sqrt()
}

fn ranks(v: &[f64]) -> Vec<f64> {
    let mut order: Vec<usize> = (0..v.len()).collect();
    order.sort_by(|&i, &j| v[i].partial_cmp(&v[j]).unwrap());
    let mut r = vec![0.0; v.len()];
    for (k, &i) in order.iter().enumerate() { r[i] = k as f64 + 1.0; }
    r
}

fn ir_of(xs: &[f64]) -> f64 {
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (n - 1.0);
    m / v.sqrt()
}

fn main() {
    // ---- 1. the toy: five stocks, scores and next-year residual returns (percent) ----
    let score = [-2.0, -1.0, 0.0, 1.0, 2.0];
    let ret = [-2.0, 0.0, 1.0, -1.0, 2.0];
    let ic_toy = pearson(&score, &ret);
    let ric_toy = pearson(&ranks(&score), &ranks(&ret));
    let by_hand = [-2i64, -1, 0, 1, 2].iter().zip([-2i64, 0, 1, -1, 2]).map(|(a, b)| a * b).sum::<i64>() as f64 / 10.0;

    // ---- 2. the law, and its exact form inside the model ----
    let (ic, b, omega) = (0.05_f64, 500usize, 0.25_f64);
    let law = ic * (b as f64).sqrt();
    let exact = law / (1.0 - ic * ic).sqrt();

    // ---- 3. coin-flip model, every outcome counted ----
    let (mut lp, mut mean_a, mut sq_a, mut lose) = (b as f64 * 0.5_f64.ln(), 0.0, 0.0, 0.0); // log chances
    for k in 0..=b {
        let a = ic * b as f64 + (1.0 - ic * ic).sqrt() * (2.0 * k as f64 - b as f64);
        let p = lp.exp();
        mean_a += p * a;
        sq_a += p * a * a;
        if a < 0.0 { lose += p; }
        lp += ((b - k).max(1) as f64 / (k + 1) as f64).ln();
    }
    let ir_coin = mean_a / (sq_a - mean_a * mean_a).sqrt();

    // ---- 4. simulation: 4000 years, 500 stocks, bell-curve scores and shocks ----
    let years = 4000usize;
    let mut rng = Rng { state: 20260928 };
    let (mut act, mut act_sort, mut ics) = (Vec::new(), Vec::new(), Vec::new());
    let (mut hits, mut bins) = (0usize, [0usize; 12]);
    for _ in 0..years {
        let mut z = rng.normals(b);
        let mz = z.iter().sum::<f64>() / b as f64;
        let sz = (z.iter().map(|v| (v - mz) * (v - mz)).sum::<f64>() / b as f64).sqrt();
        for v in z.iter_mut() { *v = (*v - mz) / sz; }
        let eps = rng.normals(b);
        let th: Vec<f64> = z.iter().zip(&eps).map(|(zi, e)| omega * (ic * zi + (1.0 - ic * ic).sqrt() * e)).collect();
        act.push(z.iter().zip(&th).map(|(zi, t)| zi * t).sum::<f64>());
        act_sort.push(z.iter().zip(&th).map(|(zi, t)| if *zi > 0.0 { *t } else { -*t }).sum::<f64>());
        let ic_y = pearson(&z, &th);
        ics.push(ic_y);
        hits += z.iter().zip(&th).filter(|(zi, t)| (**zi > 0.0) == (**t > 0.0)).count();
        let j = ((ic_y + 0.10) / 0.025).floor();
        if j >= 0.0 && j < 12.0 { bins[j as usize] += 1; }
    }
    let (ir_sim, ir_sort_sim) = (ir_of(&act), ir_of(&act_sort));
    let ic_mean = ics.iter().sum::<f64>() / years as f64;
    let ic_sd = (ics.iter().map(|c| (c - ic_mean) * (c - ic_mean)).sum::<f64>() / (years - 1) as f64).sqrt();
    let lose_sim = act.iter().filter(|a| **a < 0.0).count() as f64 / years as f64;
    let hit_sim = hits as f64 / (years * b) as f64;
    let tc_sort = (2.0 / PI).sqrt();
    let bf = b as f64;

    let rows: Vec<(&str, f64)> = vec![
        ("toy: sum of score x return", score.iter().zip(&ret).map(|(a, r)| a * r).sum::<f64>()),
        ("toy: sum of squared scores", score.iter().map(|a| a * a).sum::<f64>()),
        ("toy: sum of squared returns", ret.iter().map(|r| r * r).sum::<f64>()),
        ("toy: Pearson IC, five stocks", ic_toy), ("toy: rank IC, five stocks", ric_toy),
        ("law: IC x sqrt(500)", law), ("exact model: law / sqrt(1 - IC^2)", exact),
        ("coin-flip model, all 501 outcomes", ir_coin), ("simulation, 4000 years: IR", ir_sim),
        ("simulation: mean realised IC", ic_mean), ("simulation: spread of realised IC", ic_sd),
        ("theory: spread 1/sqrt(500)", 1.0 / bf.sqrt()),
        ("coin-flip: chance of a losing year", lose), ("bell curve: N(-exact IR)", big_n(-exact)),
        ("simulation: share of losing years", lose_sim),
        ("hit rate: 1/2 + asin(IC)/pi", 0.5 + ic.asin() / PI), ("simulation: hit rate", hit_sim),
        ("R-squared: IC^2", ic * ic), ("residual volatility omega", omega), ("forecast alpha, score +1", ic * omega * 1.0),
        ("expected active return at 4% risk", law * 0.04),
        ("sort portfolio: TC sqrt(2/pi)", tc_sort), ("sort portfolio: TC x law", tc_sort * law),
        ("sort portfolio: simulation", ir_sort_sim),
        ("wrong: 50 lockstep groups, IC sqrt(50)", ic * 50f64.sqrt()), ("wrong: no square root, IC x 500", ic * bf),
        ("monthly bets: IC sqrt(12 x 500)", ic * (12.0 * bf).sqrt()), ("wrong: monthly IR x 12", law * 12.0),
        ("right: monthly IR x sqrt(12)", law * 12f64.sqrt()),
        ("timing, breadth 1: IC for the same IR", law / (1.0 + law * law).sqrt()),
    ];
    for (name, v) in &rows { println!("{:<40} {:>11.6}", name, v); }
    let breadths = [25usize, 50, 100, 200, 500, 1000, 2000];
    println!("chart, breadth      {}", breadths.iter().map(|x| format!("{:>6}", x)).collect::<Vec<_>>().join(" "));
    for icc in [0.05_f64, 0.10] {
        println!("chart, IC {:.2}     {}", icc, breadths.iter().map(|x| format!("{:6.2}", icc * (*x as f64).sqrt())).collect::<Vec<_>>().join(" "));
    }
    println!("histogram, IC from  {}", (0..12).map(|j| format!("{:6.3}", -0.10 + 0.025 * j as f64)).collect::<Vec<_>>().join(" "));
    println!("histogram, years    {}", bins.iter().map(|c| format!("{:6}", c)).collect::<Vec<_>>().join(" "));

    assert!((ic_toy - by_hand).abs() < 1e-12, "toy IC vs the integer count by hand, 7/10");
    assert!((ir_coin - exact).abs() < 1e-9, "every-outcome count must land on the exact model");
    assert!((ir_sim - exact).abs() < 4.0 * ((1.0 + exact * exact / 2.0) / years as f64).sqrt(), "simulated IR within 4 standard errors");
    assert!((ic_mean - ic).abs() < 4.0 * (1.0 / bf.sqrt()) / (years as f64).sqrt(), "mean realised IC within 4 standard errors");
    assert!((lose - big_n(-exact)).abs() < 0.01, "binomial losing-year chance vs bell curve");
    assert!((hit_sim - (0.5 + ic.asin() / PI)).abs() < 0.002, "simulated hit rate vs Sheppard's formula");
    assert!((ir_sort_sim - tc_sort * exact).abs() < 0.08, "sort portfolio IR shrinks by the transfer coefficient");
    assert!(ir_sort_sim < ir_sim, "score-weighted beats sign-weighted");
    println!("ALL CHECKS PASS");
}
