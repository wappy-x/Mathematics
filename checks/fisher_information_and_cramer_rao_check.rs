// Fisher information and the Cramer-Rao bound -- the same check in Rust, std only.
// A bent coin, chance of heads p = 0.25, flipped n = 4 times.  Roads: the formula;
// all 16 strings, the score as a numerical slope of the log-likelihood; the
// curvature; a seeded simulation (SplitMix64, same seed); a search of unbiased estimators.
const N: usize = 4;
const P: f64 = 0.25;
const H: f64 = 1e-5;

struct SplitMix64 { s: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 / 2f64.powi(53) }   // uniform in [0, 1)
}

fn row(label: &str, v: f64, d: usize) { println!("{:<44}{:>12.*}", label, d, v); }

struct Coin { strings: Vec<Vec<usize>>, heads: Vec<usize> }
impl Coin {
    fn prob(&self, i: usize, p: f64) -> f64 {          // chance of string i
        p.powi(self.heads[i] as i32) * (1.0 - p).powi((N - self.heads[i]) as i32)
    }
    fn loglik(&self, i: usize, p: f64) -> f64 {        // log-likelihood, flip by flip
        self.strings[i].iter().map(|&x| if x == 1 { p.ln() } else { (1.0 - p).ln() }).sum()
    }
    fn score(&self, i: usize) -> f64 {                 // slope of the log-likelihood at P
        (self.loglik(i, P + H) - self.loglik(i, P - H)) / (2.0 * H)
    }
    fn curve(&self, i: usize) -> f64 {                 // its second slope
        let h = 1e-4;
        (self.loglik(i, P + h) - 2.0 * self.loglik(i, P) + self.loglik(i, P - h)) / (h * h)
    }
    fn moments(&self, t: &[f64], p: f64) -> (f64, f64, f64) {   // mean, variance, mse
        let m: f64 = (0..1 << N).map(|i| self.prob(i, p) * t[i]).sum();
        let v: f64 = (0..1 << N).map(|i| self.prob(i, p) * (t[i] - m).powi(2)).sum();
        (m, v, v + (m - p).powi(2))
    }
    fn e<F: Fn(usize) -> f64>(&self, f: F) -> f64 { (0..1 << N).map(|i| self.prob(i, P) * f(i)).sum() }
}

fn main() {
    let strings: Vec<Vec<usize>> = (0..1usize << N).map(|m| (0..N).map(|i| (m >> i) & 1).collect()).collect();
    let heads: Vec<usize> = strings.iter().map(|s| s.iter().sum()).collect();
    let c = Coin { strings: strings.clone(), heads: heads.clone() };
    let mut rng = SplitMix64 { s: 20260928 };
    let i_form = N as f64 / (P * (1.0 - P));
    row("1 formula: information n/(p(1-p))", i_form, 6);
    row("  floor p(1-p)/n", 1.0 / i_form, 6);
    row("  floor as a standard deviation", (1.0 / i_form).sqrt(), 6);
    println!("head count k, chance of that count, score, score squared");
    for k in 0..=N {
        let i = heads.iter().position(|&h| h == k).unwrap();
        let ck: f64 = (0..1 << N).filter(|&j| heads[j] == k).map(|j| c.prob(j, P)).sum();
        println!("  {}  {:.8}  {:10.6}  {:11.6}", k, ck, c.score(i), c.score(i).powi(2));
    }
    let es = c.e(|i| c.score(i));
    let i_enum = c.e(|i| c.score(i).powi(2));
    let i_curv = -c.e(|i| c.curve(i));
    row("2 enumerated: average score", es, 6);
    row("  average squared score (information)", i_enum, 6);
    row("3 curvature: minus average second slope", i_curv, 6);
    let phat: Vec<f64> = heads.iter().map(|&h| h as f64 / N as f64).collect();
    let (m, v, _) = c.moments(&phat, P);
    let cov = c.e(|i| (phat[i] - P) * c.score(i));
    row("sample proportion: mean", m, 6);
    row("  variance", v, 6);
    row("  covariance with the score", cov, 6);
    row("  variance x information", v * i_form, 6);
    let others: Vec<(&str, Vec<f64>)> = vec![
        ("first flip only", strings.iter().map(|s| s[0] as f64).collect()),
        ("weights 0.4 0.3 0.2 0.1", strings.iter().map(|s| 0.4 * s[0] as f64 + 0.3 * s[1] as f64
            + 0.2 * s[2] as f64 + 0.1 * s[3] as f64).collect()),
        ("Laplace (K+1)/(n+2), biased", heads.iter().map(|&h| (h + 1) as f64 / (N + 2) as f64).collect()),
        ("stopped clock 0.25, biased", vec![0.25; 1 << N])];
    let mut lap = (0.0, 0.0, 0.0);
    for (name, t) in &others {
        let r = c.moments(t, P);
        if name.starts_with("Laplace") { lap = r; }
        println!("{:<30} mean {:.6}  var {:.6}  mse {:.6}", name, r.0, r.1, r.2);
    }
    row("Laplace floor (1 + bias slope)^2 / I", (N as f64 / (N + 2) as f64).powi(2) / i_form, 6);
    for (p, lab) in [(0.05, "0.05"), (0.6, "0.6")] {
        println!("at p = {}: floor {:.6}  Laplace mse {:.6}  clock mse {:.6}", lab, p * (1.0 - p) / N as f64,
            c.moments(&others[2].1, p).2, c.moments(&others[3].1, p).2);
    }
    let (mut best, mut worst_mean) = (1.0f64, 0.0f64);     // 4: random unbiased estimators
    for _ in 0..2000 {
        let amp = 0.3 * rng.unif();
        let mut z: Vec<f64> = (0..1 << N).map(|_| amp * (2.0 * rng.unif() - 1.0)).collect();
        for k in 0..=N {                                   // zero sum inside each head-count class
            let cls: Vec<usize> = (0..1 << N).filter(|&i| heads[i] == k).collect();
            let mean = cls.iter().map(|&i| z[i]).sum::<f64>() / cls.len() as f64;
            for &i in &cls { z[i] -= mean; }
        }
        let t: Vec<f64> = (0..1 << N).map(|i| phat[i] + z[i]).collect();
        for p in [0.1, 0.25, 0.7] { worst_mean = worst_mean.max((c.moments(&t, p).0 - p).abs()); }
        best = best.min(c.moments(&t, P).1);
    }
    row("4 search: 2000 unbiased estimators, least var", best, 6);
    row("  largest bias found at p = 0.1, 0.25, 0.7", worst_mean, 6);
    let runs = 200000;                                     // 5: simulation of the sample proportion
    let (mut acc, mut acc2) = (0.0f64, 0.0f64);
    for _ in 0..runs {
        let k = (0..N).filter(|_| rng.unif() < P).count();
        let sq = (k as f64 / N as f64 - P).powi(2);
        acc += sq; acc2 += sq * sq;
    }
    let sim = acc / runs as f64;
    let se = ((acc2 / runs as f64 - sim * sim) / runs as f64).sqrt();
    row("5 simulated variance, 200000 runs", sim, 6);
    row("  standard error", se, 6);
    let theta = 2.0f64;                                    // moving edge: uniform on (0, theta)
    let (mut ua, mut ua2) = (0.0f64, 0.0f64);
    for _ in 0..runs {
        let mx = (0..N).map(|_| theta * rng.unif()).fold(f64::MIN, f64::max);
        let sq = ((N + 1) as f64 / N as f64 * mx - theta).powi(2);
        ua += sq; ua2 += sq * sq;
    }
    let usim = ua / runs as f64;
    let use_ = ((ua2 / runs as f64 - usim * usim) / runs as f64).sqrt();
    row("uniform: slope of log(1/theta) per draw", ((1.0 / (theta + H)).ln() - (1.0 / (theta - H)).ln()) / (2.0 * H), 6);
    row("  naive floor theta^2/n^2", theta * theta / (N * N) as f64, 6);
    row("  corrected maximum, exact theta^2/(n(n+2))", theta * theta / (N * (N + 2)) as f64, 6);
    row("  corrected maximum, simulated", usim, 6);
    row("  standard error", use_, 6);
    let (n, p) = (1000usize, 0.52f64);                     // house poll: exact binomial sum in logs
    let (mut lp, mut pv) = (n as f64 * (1.0 - p).ln(), 0.0f64);
    for k in 0..=n {
        pv += lp.exp() * (k as f64 / n as f64 - p).powi(2);
        if k < n { lp += ((n - k) as f64 / (k + 1) as f64 * p / (1.0 - p)).ln(); }
    }
    row("poll n=1000 p=0.52: floor p(1-p)/n", p * (1.0 - p) / n as f64, 7);
    row("  exact variance of the proportion", pv, 7);
    row("  floor as a standard deviation", (p * (1.0 - p) / n as f64).sqrt(), 6);
    row("  information n/(p(1-p))", n as f64 / (p * (1.0 - p)), 1);
    for nn in [4usize, 16, 64, 100] {
        let f = P * (1.0 - P) / nn as f64;
        println!("n = {:3}: floor {:.6}  standard deviation {:.6}", nn, f, f.sqrt());
    }
    let join = |v: Vec<String>| v.join(" ");
    let drop = |nn: f64, kk: f64, q: f64| kk * (q / 0.25).ln() + (nn - kk) * ((1.0 - q) / 0.75).ln();
    let grid: Vec<f64> = (1..13).map(|j| j as f64 / 20.0).collect();
    println!("chart1, p       {}", join(grid.iter().map(|q| format!("{:.2}", q)).collect()));
    println!("chart1, n=4     {}", join(grid.iter().map(|&q| format!("{:.2}", drop(4.0, 1.0, q))).collect()));
    println!("chart1, n=40    {}", join(grid.iter().map(|&q| format!("{:.2}", drop(40.0, 10.0, q))).collect()));
    let g2: Vec<f64> = (1..20).map(|j| j as f64 / 20.0).collect();
    println!("chart2, floor   {}", join(g2.iter().map(|q| format!("{:.4}", q * (1.0 - q) / N as f64)).collect()));
    println!("chart2, Laplace {}", join(g2.iter().map(|&q| format!("{:.4}", c.moments(&others[2].1, q).2)).collect()));
    println!("crossings of floor and Laplace {:.6} {:.6}", (1.0 - 5f64.sqrt() / 3.0) / 2.0, (1.0 + 5f64.sqrt() / 3.0) / 2.0);

    assert!((i_enum - i_form).abs() < 1e-6, "enumerated squared score equals n/(p(1-p))");
    assert!((i_curv - i_form).abs() < 1e-3, "curvature road equals the squared-score road");
    assert!(es.abs() < 1e-6, "the score averages zero");
    assert!((cov - 1.0).abs() < 1e-6, "unbiased estimator has covariance 1 with the score");
    assert!((v - 1.0 / i_form).abs() < 1e-12, "enumerated variance of phat sits on the floor");
    assert!(best >= v - 1e-12, "no unbiased estimator found below the floor");
    assert!(worst_mean < 1e-12, "every searched estimator is unbiased at three values of p");
    assert!((sim - 1.0 / i_form).abs() < 4.0 * se, "simulated variance within four standard errors");
    assert!(lap.2 < v, "a biased estimator beats the floor at p = 0.25");
    assert!((lap.1 - (N as f64 / (N + 2) as f64).powi(2) / i_form).abs() < 1e-12, "Laplace sits on its biased floor");
    assert!((usim - theta * theta / 24.0).abs() < 4.0 * use_, "corrected maximum: simulation matches theta^2/(n(n+2))");
    assert!(theta * theta / 16.0 - usim > 20.0 * use_, "moving edge: variance far below the naive floor");
    assert!((pv - p * (1.0 - p) / n as f64).abs() < 1e-10, "poll: exact sum equals p(1-p)/n");
    println!("ALL CHECKS PASS");
}
