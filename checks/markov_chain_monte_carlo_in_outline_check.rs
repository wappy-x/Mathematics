// MCMC in outline -- the same check as the Python, in Rust.  No crates.  A new coin shows
// 7 heads in 10 flips; with a flat prior its posterior is Beta(8, 4).  Road 1: exact, by
// counting.  Road 2: Simpson's rule on p^7 (1 - p)^3.  Road 3: a Metropolis random walk.
// Road 4: independent draws (the 8th smallest of 11 uniforms).  Road 5: the same walk on a
// grid of 99 points, its whole distribution pushed forward exactly, step by step.

struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 { // SplitMix64, written out: the same stream as the Python
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { ((self.next() >> 11) as f64 + 0.5) / 2f64.powi(53) }
}

fn pw(x: f64, k: usize) -> f64 { let mut r = 1.0; for _ in 0..k { r *= x; } r }
fn total(xs: &[f64]) -> f64 { let mut t = 0.0; for x in xs { t += x; } t }
fn comb(n: u64, k: u64) -> f64 { let mut c = 1u64; for i in 0..k { c = c * (n - i) / (i + 1); } c as f64 }

fn f(p: f64) -> f64 { if 0.0 < p && p < 1.0 { pw(p, 7) * pw(1.0 - p, 3) } else { 0.0 } } // flat prior x likelihood
fn f_tri(p: f64) -> f64 { f(p) * p.min(1.0 - p) }                                        // prior peaked at a fair coin
fn f_logit(t: f64) -> f64 { f(1.0 / (1.0 + (-t).exp())) } // walk on log-odds, no Jacobian correction

fn cdf(x: f64) -> f64 { // Beta(8,4) by counting: at least 8 of 11 uniforms below x
    let terms: Vec<f64> = (8..12).map(|k| comb(11, k as u64) * pw(x, k) * pw(1.0 - x, 11 - k)).collect();
    total(&terms)
}

fn quantile(c: f64) -> f64 { // bisection on the counted CDF
    let (mut lo, mut hi) = (0.0, 1.0);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if cdf(mid) < c { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn simpson(g: &dyn Fn(f64) -> f64) -> f64 { // the area under g on [0, 1]
    let n = 2000;
    let h = 1.0 / n as f64;
    let terms: Vec<f64> = (0..=n)
        .map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * h)).collect();
    h / 3.0 * total(&terms)
}

fn walk(rng: &mut Rng, target: &dyn Fn(f64) -> f64, h: f64, n: usize, burn: usize, show: usize) -> (Vec<f64>, f64) {
    let (mut p, mut fp, mut acc, mut out) = (0.5, target(0.5), 0usize, Vec::new());
    for t in 0..burn + n {
        let u = rng.unif(); let prop = p + h * (2.0 * u - 1.0); // propose: a step of up to h either way
        let (fq, v) = (target(prop), rng.unif());
        let ok = v < fq / fp; // accept with chance min(1, f(p') / f(p))
        if t < show {
            println!("  step {}: at {:.4}, u {:.4}, propose {:.4}, ratio {:.4}, draw {:.4}, {}",
                     t + 1, p, u, prop, fq / fp, v, if ok { "move" } else { "stay" });
        }
        if ok { p = prop; fp = fq; acc += 1; }
        if t >= burn { out.push(p); }
    }
    (out, acc as f64 / (burn + n) as f64)
}

fn summary(xs: &[f64], batches: usize) -> (f64, f64, f64, f64) { // mean, spread, batch-means SE, effective size
    let (n, m) = (xs.len(), total(xs) / xs.len() as f64);
    let var = total(&xs.iter().map(|x| (x - m) * (x - m)).collect::<Vec<_>>()) / (n - 1) as f64;
    let k = n / batches;
    let bm: Vec<f64> = (0..batches).map(|b| total(&xs[b * k..(b + 1) * k]) / k as f64).collect();
    let se = (total(&bm.iter().map(|b| (b - m) * (b - m)).collect::<Vec<_>>()) / (batches - 1) as f64 / batches as f64).sqrt();
    (m, var.sqrt(), se, var / (se * se))
}

fn grid_step(d: &[f64], wg: &[f64]) -> Vec<f64> {
    let mut new = vec![0.0; 99];
    for i in 0..99i64 {
        for j in -10..=10i64 {
            if j == 0 { continue; }
            let k = i + j;
            let a = if (0..99).contains(&k) { (1.0f64).min(wg[k as usize] / wg[i as usize]) } else { 0.0 };
            if a > 0.0 { new[k as usize] += d[i as usize] * a / 20.0; }
            new[i as usize] += d[i as usize] * (1.0 - a) / 20.0;
        }
    }
    new
}

fn main() {
    let mut rng = Rng(20260929);
    let z_exact = 1.0 / (4.0 * comb(11, 4)); // 7! 3! / 11! = 1 / 1320
    let z_simp = simpson(&f);
    let (mean_x, sd_x) = (8.0 / 12.0, (32.0f64 / 1872.0).sqrt());
    let up_x = 1.0 - total(&(8..12).map(|k| comb(11, k)).collect::<Vec<_>>()) / 2048.0;
    let (lo_x, hi_x) = (quantile(0.025), quantile(0.975));
    println!("road 1, exact, Beta(8, 4): mean {:.6}, sd {:.6}, P(p > 0.5) = 1 - 232/2048 = {:.6}", mean_x, sd_x, up_x);
    println!("  95% credible interval {:.4} to {:.4}; Z = 1/1320 = {:.9}", lo_x, hi_x, z_exact);
    println!("road 2, Simpson: Z {:.9}, mean {:.6}", z_simp, simpson(&|p| p * f(p)) / z_simp);
    println!("road 3, Metropolis, step h = 0.25, start 0.5; the first five steps:");
    let (n, burn) = (100000usize, 1000usize);
    let (ch, acc) = walk(&mut rng, &f, 0.25, n, burn, 5);
    let (m3, s3, se3, ess3) = summary(&ch, 100);
    let up: Vec<f64> = ch.iter().map(|&x| if x > 0.5 { 1.0 } else { 0.0 }).collect();
    let (u3, _, seu, _) = summary(&up, 100);
    let mut srt = ch.clone();
    srt.sort_by(|a, b| a.partial_cmp(b).unwrap());
    println!("  {} kept after {} burn-in, acceptance {:.4}", n, burn, acc);
    println!("  mean {:.4} (SE {:.4}), sd {:.4}, P(p > 0.5) {:.4} (SE {:.4})", m3, se3, s3, u3, seu);
    println!("  95% interval {:.4} to {:.4}", srt[(0.025 * n as f64) as usize], srt[(0.975 * n as f64) as usize]);
    println!("  batch means over 100 batches: effective sample size {:.0}; naive SE sd/root N {:.4}", ess3, s3 / (n as f64).sqrt());
    let iid: Vec<f64> = (0..20000).map(|_| {
        let mut u: Vec<f64> = (0..11).map(|_| rng.unif()).collect();
        u.sort_by(|a, b| a.partial_cmp(b).unwrap());
        u[7]
    }).collect();
    let (m4, s4, _, _) = summary(&iid, 100);
    println!("road 4, 20000 independent draws, 8th smallest of 11 uniforms: mean {:.4} (SE {:.4}), sd {:.4}", m4, s4 / 20000f64.sqrt(), s4);
    let row = |g: &dyn Fn(f64) -> String| (0..10).map(|b| g(b as f64)).collect::<Vec<_>>().join(" ");
    println!("chart, bin from:  {}", row(&|b| format!("{:.1}", b / 10.0)));
    println!("chart, exact %:   {}", row(&|b| format!("{:.2}", 100.0 * (cdf((b + 1.0) / 10.0) - cdf(b / 10.0)))));
    println!("chart, chain %:   {}", row(&|b| {
        let c = total(&ch.iter().filter(|&&x| b / 10.0 <= x && x < (b + 1.0) / 10.0).map(|_| 1.0).collect::<Vec<_>>());
        format!("{:.2}", 100.0 * c / n as f64)
    }));

    let wg: Vec<f64> = (1..100).map(|i| f(i as f64 / 100.0)).collect(); // road 5: the walk on a grid
    let tgt: Vec<f64> = wg.iter().map(|w| w / total(&wg)).collect();
    let mut d: Vec<f64> = (0..99).map(|i| if i == 0 { 1.0 } else { 0.0 }).collect(); // start at p = 0.01
    let mut tv: Vec<(usize, f64)> = Vec::new();
    for s in 0..=200usize {
        if [0, 5, 10, 20, 50, 100, 200].contains(&s) {
            tv.push((s, total(&d.iter().zip(&tgt).map(|(a, b)| (a - b).abs()).collect::<Vec<_>>()) / 2.0));
        }
        d = grid_step(&d, &wg);
    }
    let pm: Vec<Vec<f64>> = (0..99).map(|i| grid_step(&(0..99).map(|j| if j == i { 1.0 } else { 0.0 }).collect::<Vec<f64>>(), &wg)).collect(); // row i: one step from state i
    let mut flow = 0.0f64;
    for i in 0..99usize { for k in 0..99usize { flow = flow.max((tgt[i] * pm[i][k] - tgt[k] * pm[k][i]).abs()); } }
    let still = grid_step(&tgt, &wg).iter().zip(&tgt).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("road 5, grid of 99 points, steps of 1 to 10 cells, start 0.01: largest flow imbalance {:.1e}; one step moves the posterior by {:.1e}", flow, still);
    println!("chart, grid steps:    {}", tv.iter().map(|(s, _)| s.to_string()).collect::<Vec<_>>().join(" "));
    println!("chart, distance left: {}", tv.iter().map(|(_, v)| format!("{:.3}", v)).collect::<Vec<_>>().join(" "));

    let mt_x = simpson(&|p| p * f_tri(p)) / simpson(&f_tri);
    let (mt, _, set, _) = summary(&walk(&mut rng, &f_tri, 0.25, n, burn, 0).0, 100);
    println!("second case, prior min(p, 1 - p): Simpson mean {:.4}; chain mean {:.4} (SE {:.4})", mt_x, mt, set);

    println!("what breaks");
    let kept: Vec<f64> = (0..ch.len()).filter(|&i| i == 0 || ch[i] != ch[i - 1]).map(|i| ch[i]).collect();
    let (mk, sk, sek, _) = summary(&kept, 100);
    println!("  repeats dropped: {} moves, mean {:.4} (SE {:.4}), sd {:.4}", kept.len(), mk, sek, sk);
    let chl = walk(&mut rng, &f_logit, 1.0, n, burn, 0).0;
    let (ml, _, sel, _) = summary(&chl.iter().map(|t| 1.0 / (1.0 + (-t).exp())).collect::<Vec<_>>(), 100);
    println!("  log-odds walk, no Jacobian: mean {:.4} (SE {:.4}); Beta(7, 3) mean {:.4}", ml, sel, 7.0 / 10.0);
    let (chs, accs) = walk(&mut rng, &f, 0.002, 2000, 0, 0);
    let (ms, _, ses, esss) = summary(&chs, 20);
    println!("  step 0.002, 2000 steps: acceptance {:.4}, mean {:.4} (SE {:.4}), ESS {:.0}", accs, ms, ses, esss);

    assert!((z_simp - z_exact).abs() < 1e-12 && (simpson(&|p| p * f(p)) / z_simp - mean_x).abs() < 1e-9, "Simpson vs factorials");
    assert!((m3 - mean_x).abs() < 4.0 * se3 && (u3 - up_x).abs() < 4.0 * seu, "chain vs exact, within 4 SE");
    assert!((m4 - mean_x).abs() < 4.0 * s4 / 20000f64.sqrt(), "independent draws vs exact");
    assert!(s3 / (n as f64).sqrt() < se3, "correlated draws: naive SE must understate the batch-means SE");
    assert!(flow < 1e-15 && still < 1e-15 && tv[6].1 < 0.01 && 0.01 < tv[2].1, "grid: balance, stillness, forgetting");
    assert!((mt - mt_x).abs() < 4.0 * set, "second prior: chain vs Simpson");
    assert!((ml - 0.7).abs() < 4.0 * sel && (ml - mean_x).abs() > 4.0 * sel, "missing Jacobian lands on Beta(7, 3)");
    println!("ALL CHECKS PASS");
}
