// Mixed-effects models -- the check behind the card.  std only: the solver, the REML
// search and the random numbers (SplitMix64, Box-Muller) are written out here.
// Three schools: mean score, pupils; within-school variance 100, between-school 25.
const S2: f64 = 100.0;
const T2: f64 = 25.0;
fn kept(t2: f64, s2: f64, n: usize) -> f64 { t2 / (t2 + s2 / n as f64) }
fn centre(t2: f64, s2: f64, means: &[f64], sizes: &[usize]) -> (f64, Vec<f64>) {
    let w: Vec<f64> = sizes.iter().map(|&n| 1.0 / (t2 + s2 / n as f64)).collect();
    let top: f64 = w.iter().zip(means).map(|(a, b)| a * b).sum();
    (top / w.iter().sum::<f64>(), w)
}
fn shrink(t2: f64, s2: f64, means: &[f64], sizes: &[usize], mu: f64) -> Vec<f64> {
    means.iter().zip(sizes).map(|(&m, &n)| mu + kept(t2, s2, n) * (m - mu)).collect()
}
fn solve(m: &[Vec<f64>], r: &[f64]) -> Vec<f64> {
    let n = r.len();
    let mut a: Vec<Vec<f64>> = m.iter().zip(r).map(|(row, &v)| { let mut x = row.clone(); x.push(v); x }).collect();
    for c in 0..n {
        let p = (c..n).fold(c, |p, i| if a[i][c].abs() > a[p][c].abs() { i } else { p });
        a.swap(c, p);
        for i in c + 1..n {
            let f = a[i][c] / a[c][c];
            for j in 0..=n { a[i][j] -= f * a[c][j]; }
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() { x[i] = (a[i][n] - (i + 1..n).map(|j| a[i][j] * x[j]).sum::<f64>()) / a[i][i]; }
    x
}
fn reml(t2: f64, s2: f64, means: &[f64], sizes: &[usize], ssw: f64) -> f64 {
    let (m, wt) = centre(t2, s2, means, sizes);
    let ntot: usize = sizes.iter().sum();
    let mut ll = -((ntot - sizes.len()) as f64) * s2.ln() - ssw / s2 - wt.iter().sum::<f64>().ln();
    for ((a, &n), v) in means.iter().zip(sizes).zip(&wt) { ll += v.ln() - v * (a - m).powi(2) - (n as f64).ln(); }
    0.5 * ll
}
fn golden<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..80 {
        let (c, d) = (b - g * (b - a), a + g * (b - a));
        if f(c) > f(d) { b = d } else { a = c }
    }
    (a + b) / 2.0
}
struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
    fn normal(&mut self) -> f64 { (-2.0 * (1.0 - self.unif()).ln()).sqrt() * (2.0 * std::f64::consts::PI * self.unif()).cos() }
    fn district(&mut self, sizes: &[usize]) -> (Vec<f64>, Vec<f64>, f64) {
        let (mut tr, mut means, mut ssw) = (vec![], vec![], 0.0);
        for &n in sizes {
            let t = 75.0 + T2.sqrt() * self.normal();
            let ys: Vec<f64> = (0..n).map(|_| t + S2.sqrt() * self.normal()).collect();
            let m = ys.iter().sum::<f64>() / n as f64;
            ssw += ys.iter().map(|v| (v - m).powi(2)).sum::<f64>();
            tr.push(t); means.push(m);
        }
        (tr, means, ssw)
    }
}
fn moments(means: &[f64], sizes: &[usize], ssw: f64) -> (f64, f64) {
    let (n, k) = (sizes.iter().sum::<usize>() as f64, sizes.len() as f64);
    let yb = means.iter().zip(sizes).map(|(m, &s)| m * s as f64).sum::<f64>() / n;
    let mw = ssw / (n - k);
    let mb = means.iter().zip(sizes).map(|(m, &s)| s as f64 * (m - yb).powi(2)).sum::<f64>() / (k - 1.0);
    let n0 = (n - sizes.iter().map(|&s| (s * s) as f64).sum::<f64>() / n) / (k - 1.0);
    ((mb - mw) / n0, mw)
}
fn row(label: &str, v: &[f64], d: usize) -> String {
    format!("{label}{}", v.iter().map(|x| format!("{:>9.*}", d, x)).collect::<String>())
}
fn avg(v: &[f64]) -> f64 { v.iter().sum::<f64>() / v.len() as f64 }
fn sd(v: &[f64]) -> f64 { (avg(&v.iter().map(|x| x * x).collect::<Vec<_>>()) - avg(v).powi(2)).sqrt() }
fn main() {
    let (mean, size, k, nn) = ([70.0, 80.0, 75.0], [4usize, 25, 9], 3usize, 38.0);
    let lam: Vec<f64> = size.iter().map(|&n| kept(T2, S2, n)).collect();
    let (mu, w) = centre(T2, S2, &mean, &size);
    let theta = shrink(T2, S2, &mean, &size, mu);
    let vmu = 1.0 / w.iter().sum::<f64>();
    let noise: Vec<f64> = size.iter().map(|&n| S2 / n as f64).collect();
    println!("school                     A        B        C");
    println!("pupils n             {}", size.iter().map(|n| format!("{n:>9}")).collect::<String>());
    println!("{}", row("noise of mean 100/n  ", &noise, 3));
    println!("{}", row("kept share           ", &lam, 3));
    println!("{}", row("weight 1/(25+100/n)  ", &w, 5));
    let wsum: f64 = w.iter().zip(&mean).map(|(a, b)| a * b).sum();
    println!("sum of weights {:.5}, weighted sum of means {:.4}", w.iter().sum::<f64>(), wsum);
    let ybar = mean.iter().zip(&size).map(|(m, &n)| m * n as f64).sum::<f64>() / nn;
    println!("overall mean {mu:.2}, its variance {vmu:.2}, pupil-weighted mean {ybar:.2}");
    println!("{}", row("shrunken mean        ", &theta, 2));
    // road 2: Henderson's mixed-model equations, unknowns (mu, b_A, b_B, b_C)
    let mut m = vec![std::iter::once(nn / S2).chain(size.iter().map(|&n| n as f64 / S2)).collect::<Vec<f64>>()];
    for (j, &n) in size.iter().enumerate() {
        m.push(std::iter::once(n as f64 / S2).chain((0..k).map(|i| if i == j { n as f64 / S2 + 1.0 / T2 } else { 0.0 })).collect());
    }
    let mut rhs = vec![ybar * nn / S2];
    rhs.extend(mean.iter().zip(&size).map(|(m, &n)| m * n as f64 / S2));
    let h = solve(&m, &rhs);
    let hb: Vec<f64> = h[1..].iter().map(|b| h[0] + b).collect();
    println!("{}   mu {:.2}", row("Henderson mu + b_j   ", &hb, 2), h[0]);
    let pev: Vec<f64> = lam.iter().zip(&size).map(|(l, &n)| l * S2 / n as f64 + (1.0 - l).powi(2) * vmu).collect();
    println!("{}", row("error var, raw mean  ", &noise, 3));
    println!("{}", row("error var, shrunken  ", &pev, 3));
    let ssw = 3500.0; // within-school SS: 3500 over 35 degrees of freedom
    let (t2raw, msw) = moments(&mean, &size, ssw);
    let msb = mean.iter().zip(&size).map(|(m, &n)| n as f64 * (m - ybar).powi(2)).sum::<f64>() / 2.0;
    let n0 = (nn - size.iter().map(|&n| (n * n) as f64).sum::<f64>() / nn) / 2.0;
    let t2mom = t2raw.max(0.0);
    println!("MSW {msw:.2}, MSB {msb:.2}, n0 {n0:.2}, moment estimate of tau^2 {t2mom:.2}");
    let best_s2 = |t: f64| golden(|s| reml(t, s, &mean, &size, ssw), 1.0, 1000.0);
    let rt = golden(|t| reml(t, best_s2(t), &mean, &size, ssw), 0.0, 1000.0);
    let rs = best_s2(rt);
    println!("REML estimates: tau^2 {rt:.2}, sigma^2 {rs:.2}");
    let (mut g, reps) = (Rng(20261123), 20000);
    let (mut raw_se, mut shr_se, mut t2s, mut s2s) = (vec![0.0; k], vec![0.0; k], vec![], vec![]);
    for _ in 0..reps {
        let (tr, ms, sw) = g.district(&size);
        let (c, _) = centre(T2, S2, &ms, &size);
        let sh = shrink(T2, S2, &ms, &size, c);
        for j in 0..k { raw_se[j] += (ms[j] - tr[j]).powi(2) / reps as f64; shr_se[j] += (sh[j] - tr[j]).powi(2) / reps as f64; }
        let (a, b) = moments(&ms, &size, sw);
        t2s.push(a); s2s.push(b);
    }
    println!("{}", row("simulated, raw       ", &raw_se, 3));
    println!("{}", row("simulated, shrunken  ", &shr_se, 3));
    let neg = t2s.iter().filter(|&&v| v < 0.0).count() as f64 / reps as f64;
    println!("3 schools x {reps}: tau^2 estimate mean {:.2}, sd {:.2}, below zero {:.1}%; sigma^2 mean {:.2}",
        avg(&t2s), sd(&t2s), 100.0 * neg, avg(&s2s));
    let big: Vec<usize> = (0..10).flat_map(|_| size).collect();
    let t30: Vec<f64> = (0..2000).map(|_| { let d = g.district(&big); moments(&d.1, &big, d.2).0 }).collect();
    println!("30 schools x 2000: tau^2 estimate mean {:.2}, sd {:.2}", avg(&t30), sd(&t30));
    let pool: Vec<f64> = w.iter().map(|wj| vmu + T2 - 2.0 * wj * T2 * vmu).collect();
    println!("{}", row("error var, all at mu ", &pool, 3));
    let same: Vec<f64> = mean.iter().map(|m| mu + kept(T2, S2, 1) * (m - mu)).collect();
    println!("{}", row(&format!("one share {:.3} for all ", kept(T2, S2, 1)), &same, 2));
    println!("{}", row("centred at 77.76     ", &shrink(T2, S2, &mean, &size, ybar), 2));
    let sh: Vec<String> = size.iter().map(|&n| format!("{:.3}", kept(t2mom, S2, n))).collect();
    println!("shares with tau^2 = 12.36 {}", sh.join(" "));
    let ns: Vec<usize> = (2..41).step_by(2).collect();
    println!("chart, n {}", ns.iter().map(|n| n.to_string()).collect::<Vec<_>>().join(" "));
    for t in [T2, t2mom] {
        let v: Vec<String> = ns.iter().map(|&n| format!("{:.3}", kept(t, S2, n))).collect();
        println!("chart, tau^2 {t:.2} {}", v.join(" "));
    }
    for ((lab, m), s) in ["A", "B", "C"].iter().zip(&mean).zip(&theta) {
        println!("bars, {lab} raw gap {:<24} {:6.2}", "#".repeat(((m - mu).abs() * 4.0).round() as usize), m - mu);
        println!("bars, {lab} kept    {:<24} {:6.2}", "#".repeat(((s - mu).abs() * 4.0).round() as usize), s - mu);
    }
    assert!(theta.iter().zip(&hb).all(|(a, b)| (a - b).abs() < 1e-9)); // two roads agree
    assert!((h[0] - mu).abs() < 1e-9);                                  // same overall mean
    let r3: Vec<f64> = lam.iter().map(|v| (v * 1000.0).round() / 1000.0).collect();
    assert!(r3 == vec![0.5, 0.862, 0.692]);                             // the spec's shares
    assert!((rt - t2mom).abs() < 0.05 && (rs - msw).abs() < 1.0);       // REML near moments
    for j in 0..k {                                                     // simulation, 4 SE
        let se = (2.0 / reps as f64).sqrt();
        assert!((raw_se[j] - noise[j]).abs() < 4.0 * se * noise[j]);
        assert!((shr_se[j] - pev[j]).abs() < 4.0 * se * pev[j]);
        assert!(pev[j] < noise[j].min(pool[j]));                        // partial pooling wins
    }
    assert!((avg(&t2s) - T2).abs() < 4.0 * sd(&t2s) / (reps as f64).sqrt());
    assert!((avg(&s2s) - S2).abs() < 4.0 * sd(&s2s) / (reps as f64).sqrt());
    assert!(sd(&t30) < sd(&t2s) / 2.0);                                 // more schools, firmer
    println!("ALL CHECKS PASS");
}
