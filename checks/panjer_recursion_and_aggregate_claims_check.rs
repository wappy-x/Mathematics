// Panjer's recursion -- the same check as the Python, in Rust.  No crates;
// nothing imported contains the answer.  A motor insurer's 50,000 policies
// give 20 large claims a year on average (Poisson).  Sizes on a $10,000 grid:
// 1 unit 50%, 2 units 30%, 5 units 20%.  Question: the chance that the year's
// total beats 120% of its expected value.  Four roads, then the mistakes.
const LAM: f64 = 20.0;
const Q: [f64; 6] = [0.0, 0.5, 0.3, 0.0, 0.0, 0.2];
const KMAX: usize = 200;

fn panjer(a: f64, b: f64, p0: f64, q: &[f64], kmax: usize) -> Vec<f64> {  // road 1
    let mut p = vec![0.0; kmax + 1];
    p[0] = p0;
    for k in 1..=kmax {
        let mut s = 0.0;
        for j in 1..=k.min(q.len() - 1) {
            s += (a + b * j as f64 / k as f64) * q[j] * p[k - j];
        }
        p[k] = s / (1.0 - a * q[0]);
    }
    p
}

fn poisson(mu: f64, n: usize) -> f64 {           // e^-mu mu^n / n!, written out
    let mut v = (-mu).exp();
    for i in 1..=n { v *= mu / i as f64 }
    v
}

fn by_count(weight: &dyn Fn(usize) -> f64, q: &[f64], kmax: usize) -> Vec<f64> {  // road 3
    let (mut out, mut conv) = (vec![0.0; kmax + 1], vec![0.0; kmax + 1]);
    conv[0] = 1.0;                                // conv = q^{*n}
    for n in 0..=kmax {                           // every claim is >= 1 unit, so n <= kmax
        let w = weight(n);
        for k in 0..=kmax { out[k] += w * conv[k] }
        let mut new = vec![0.0; kmax + 1];
        for k in 0..=kmax {
            for j in 1..=k.min(q.len() - 1) { new[k] += q[j] * conv[k - j] }
        }
        conv = new;
    }
    out
}

fn row(label: &str, v: f64, d: usize) { println!("{:<38}{:.*}", label, d, v) }

fn normal_cdf(z: f64) -> f64 {                    // 0.5 + Simpson's rule on the bell curve
    let (n, h) = (2000, z / 2000.0);
    let mut s = 1.0 + (-z * z / 2.0).exp();
    for i in 1..n {
        let x = i as f64 * h;
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * (-x * x / 2.0).exp();
    }
    0.5 + s * h / 3.0 / (2.0 * 3.141592653589793f64).sqrt()
}

struct SplitMix(u64);                             // road 4: splitmix64, then Knuth's Poisson
impl SplitMix {
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn tail_upto(p: &[f64], x: usize) -> f64 { 1.0 - p[..=x].iter().sum::<f64>() }

fn tail120(lam: f64, q: &[f64]) -> f64 {          // try-changing runs: 120% of the new mean
    let pp = panjer(0.0, lam, (-lam * (1.0 - q[0])).exp(), q, KMAX);
    let m: f64 = q.iter().enumerate().map(|(j, x)| j as f64 * x).sum();
    tail_upto(&pp, (1.2 * lam * m) as usize)
}

fn main() {
    let p = panjer(0.0, LAM, (-LAM * (1.0 - Q[0])).exp(), &Q, KMAX);
    let mut split = vec![0.0; KMAX + 1];          // road 2: 10 + 6 + 4 independent Poissons
    let c: Vec<Vec<f64>> = [10.0, 6.0, 4.0].iter().map(|&mu| (0..=KMAX).map(|n| poisson(mu, n)).collect()).collect();
    for n5 in 0..=KMAX / 5 {
        for n2 in 0..=(KMAX - 5 * n5) / 2 {
            for n1 in 0..=KMAX - 5 * n5 - 2 * n2 {
                split[n1 + 2 * n2 + 5 * n5] += c[0][n1] * c[1][n2] * c[2][n5];
            }
        }
    }
    let conv = by_count(&|n| poisson(LAM, n), &Q, KMAX);
    let ex: f64 = Q.iter().enumerate().map(|(j, x)| j as f64 * x).sum();
    let ex2: f64 = Q.iter().enumerate().map(|(j, x)| (j * j) as f64 * x).sum();
    let (mean, var) = (LAM * ex, LAM * ex2);
    let t = (1.2 * mean) as usize;                // 50.4 units: beating it means K >= 51
    let (tail, tail_split, tail_conv) = (tail_upto(&p, t), tail_upto(&split, t), tail_upto(&conv, t));
    let (years, mut hits) = (200000, 0);
    let limit = (-LAM).exp();
    let mut rng = SplitMix(20260928);
    for _ in 0..years {
        let (mut n, mut prod) = (0, rng.uniform());
        while prod > limit { n += 1; prod *= rng.uniform() }
        let mut total = 0;
        for _ in 0..n {
            let u = rng.uniform();
            total += if u < 0.5 { 1 } else if u < 0.8 { 2 } else { 5 };
        }
        if total > t { hits += 1 }
    }
    let m_d: f64 = p.iter().enumerate().map(|(k, x)| k as f64 * x).sum();
    let v_d: f64 = p.iter().enumerate().map(|(k, x)| (k * k) as f64 * x).sum::<f64>() - m_d * m_d;
    let tail150 = tail_upto(&p, (1.5 * mean) as usize);     // 63 units
    let nb = panjer(2.0 / 3.0, 6.0, 3f64.powi(-10), &Q, KMAX);  // r = 10, beta = 2
    let nb_weight = |n: usize| -> f64 {           // C(n+9, 9) (1/3)^10 (2/3)^n, closed form
        let mut c: u64 = 1;
        for i in 1..10u64 { c = c * (n as u64 + i) / i }
        c as f64 * (1.0f64 / 3.0).powi(10) * (2.0f64 / 3.0).powi(n as i32)
    };
    let nb_conv = by_count(&nb_weight, &Q, KMAX);
    let nb_tail = tail_upto(&nb, t);
    let q0 = [0.2f64, 0.4, 0.24, 0.0, 0.0, 0.16]; // 25 claims a year, one in five settles at zero
    let thin = panjer(0.0, 25.0, (-25.0 * (1.0 - q0[0])).exp(), &q0, KMAX);  // the same year as p
    let nb_thin = panjer(5.0 / 7.0, 45.0 / 7.0, 3f64.powi(-10), &q0, KMAX); // r = 10, beta = 2.5: same as nb
    let mut no_j = vec![0.0; KMAX + 1];           // mistake: weight j dropped from the sum
    no_j[0] = (-LAM).exp();
    for k in 1..=KMAX {
        no_j[k] = LAM / k as f64 * (1..=k.min(5)).map(|j| Q[j] * no_j[k - j]).sum::<f64>();
    }
    let big = panjer(0.0, 2500.0, (-2500.0f64).exp(), &Q, 50);

    row("mean claim, units of $10,000", ex, 6);
    row("mean total, units", mean, 6);
    row("sd of total, units", var.sqrt(), 6);
    row("threshold 120% of mean, units", 1.2 * mean, 6);
    row("p0 = e^-20, times 10^9", p[0] * 1e9, 6);
    for k in 1..=3 { row(&format!("p{} / p0, road 1 Panjer", k), p[k] / p[0], 6) }
    row("P(K <= 50), road 1 Panjer", 1.0 - tail, 10);
    row("P(K <= 50), road 2 Poisson split", 1.0 - tail_split, 10);
    row("P(K <= 50), road 3 sum over count", 1.0 - tail_conv, 10);
    row("tail, road 1 Panjer", tail, 6);
    row("tail, road 4 simulated 200,000 years", hits as f64 / years as f64, 6);
    row("mean from the distribution, units", m_d, 6);
    row("variance from the distribution", v_d, 6);
    row("variance lambda E[X^2]", var, 6);
    row("p2 / p0, road 2 Poisson split", split[2] / split[0], 6);
    row("tail beyond 150% of mean (K > 63)", tail150, 6);
    row("negative binomial count, tail", nb_tail, 6);
    row("  same by closed-form count weights", tail_upto(&nb_conv, t), 6);
    row("wrong: normal curve at 120%", 1.0 - normal_cdf((1.2 * mean - mean) / var.sqrt()), 6);
    row("wrong: normal curve at 150%", 1.0 - normal_cdf((1.5 * mean - mean) / var.sqrt()), 6);
    row("wrong: counted $500,000 as a breach", tail_upto(&p, t - 1), 6);
    row("wrong: j dropped, total probability", no_j.iter().sum::<f64>(), 6);
    row("wrong: lambda 2500, total of p0..p50", big.iter().sum::<f64>(), 6);
    row("try: 25 claims a year, tail at 120%", tail120(25.0, &Q), 6);
    row("try: $50,000 claims 30%, $10k 40%", tail120(LAM, &[0.0, 0.4, 0.3, 0.0, 0.0, 0.3]), 6);
    row("try: sizes 1 unit only, tail at 120%", tail120(LAM, &[0.0, 1.0]), 6);
    let (ks, xs): (Vec<usize>, Vec<usize>) = ((20..=80).step_by(5).collect(), (30..=70).step_by(5).collect());
    let line = |label: &str, v: Vec<String>| println!("{:<18}{}", label, v.join(" "));
    line("chart, total $k", ks.iter().map(|k| format!("{:6}", 10 * k)).collect());
    line("chart, p_k in %", ks.iter().map(|&k| format!("{:6.2}", 100.0 * p[k])).collect());
    line("chart, over $k", xs.iter().map(|x| format!("{:6}", 10 * x)).collect());
    line("chart, exact %", xs.iter().map(|&x| format!("{:6.2}", 100.0 * tail_upto(&p, x))).collect());
    line("chart, normal %", xs.iter().map(|&x| format!("{:6.2}", 100.0 * (1.0 - normal_cdf((x as f64 - mean) / var.sqrt())))).collect());

    let gap = |a: &[f64], b: &[f64]| a.iter().zip(b).map(|(x, y)| (x - y).abs()).fold(0.0, f64::max);
    assert!(gap(&p, &split) < 1e-15);                                   // recursion vs split
    assert!((tail - tail_conv).abs() < 1e-12 && (tail - tail_split).abs() < 1e-12);
    assert!((hits as f64 / years as f64 - tail).abs() < 0.006);         // about 6 standard errors
    assert!((m_d - mean).abs() < 1e-9 && (v_d - var).abs() < 1e-6);     // moments vs lambda E[X]
    assert!(gap(&nb, &nb_conv) < 1e-15);                                // (a, b, 0) vs closed form
    assert!(gap(&p, &thin) < 1e-15 && gap(&nb, &nb_thin) < 1e-15);     // q0 > 0 terms
    println!("ALL CHECKS PASS");
}
