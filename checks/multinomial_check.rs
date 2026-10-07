// Multinomial -- the same check as the Python, in Rust.  No crates.  Twenty
// customers each pick a cup size on their own: small 0.3, medium 0.5, large
// 0.2.  Three roads: the counting formula, an exact table built one customer
// at a time (every one of the 3^20 orders, grouped by tally), and a seeded
// simulation of 100,000 days drawn from SplitMix64, written out below.
const N: usize = 20;
const P: [f64; 3] = [0.3, 0.5, 0.2];
type Law = Vec<Vec<f64>>;

fn fact(n: usize) -> u128 { (2..=n as u128).product() }

fn ipow(x: f64, k: usize) -> f64 {                // x multiplied in k times
    let mut out = 1.0;
    for _ in 0..k { out *= x }
    out
}

fn formula(k: [usize; 3], p: [f64; 3], n: usize) -> f64 {   // road one
    let coef = fact(n) / (fact(k[0]) * fact(k[1]) * fact(k[2]));
    coef as f64 * ipow(p[0], k[0]) * ipow(p[1], k[1]) * ipow(p[2], k[2])
}

fn table(p: [f64; 3], steps: usize, size: usize) -> Law {    // road two: law[s][m]
    let mut law = vec![vec![0.0; N + 1]; N + 1];
    law[0][0] = 1.0;
    for t in 0..steps {
        let mut new = vec![vec![0.0; N + 1]; N + 1];
        for s in 0..=t * size {
            for m in 0..=(t * size - s) {
                let w = law[s][m];
                new[s + size][m] += w * p[0];     // this customer (or pair) takes small
                new[s][m + size] += w * p[1];     // medium
                new[s][m] += w * p[2];            // large
            }
        }
        law = new;
    }
    law
}

fn moments(law: &Law) -> ([f64; 3], [[f64; 3]; 3]) {
    let mut cells = Vec::new();
    for s in 0..=N { for m in 0..=(N - s) { cells.push(([s as f64, m as f64, (N - s - m) as f64], law[s][m])) } }
    let mut mean = [0.0; 3];
    for (c, w) in &cells { for i in 0..3 { mean[i] += c[i] * w } }
    let mut cov = [[0.0; 3]; 3];
    for (c, w) in &cells {
        for i in 0..3 { for j in 0..3 { cov[i][j] += (c[i] - mean[i]) * (c[j] - mean[j]) * w } }
    }
    (mean, cov)
}

fn add(xs: impl Iterator<Item = f64>) -> f64 {   // plain left-to-right sum
    let mut out = 0.0;
    for x in xs { out += x }
    out
}

fn binom_pmf(n: usize, p: f64) -> Vec<f64> {      // Pascal's triangle, no factorials
    let mut row: Vec<u64> = vec![1];
    for _ in 0..n {
        let mut next = vec![1];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]) }
        next.push(1);
        row = next;
    }
    (0..=n).map(|k| row[k] as f64 * ipow(p, k) * ipow(1.0 - p, n - k)).collect()
}

struct SplitMix(u64);
impl SplitMix {
    fn draw(&mut self) -> u64 {                   // SplitMix64, top 53 bits
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) >> 11
    }
}

fn main() {
    let law = table(P, N, 1);
    let exact = formula([6, 10, 4], P, N);
    let one_order = ipow(0.3, 6) * ipow(0.5, 10) * ipow(0.2, 4);
    let (mut total, mut best) = (0.0, (0, 0, 0.0));
    for s in 0..=N {
        for m in 0..=(N - s) {
            total += law[s][m];
            if law[s][m] > best.2 { best = (s, m, law[s][m]) }
        }
    }
    let (mean, cov) = moments(&law);
    let corr = cov[0][1] / (cov[0][0] * cov[1][1]).sqrt();
    let nf = N as f64;
    println!("coefficient C(20; 6, 10, 4) = {}", fact(20) / (fact(6) * fact(10) * fact(4)));
    println!("one order, 6 small then 10 medium then 4 large = {:.12}", one_order);
    println!("its pieces: 0.3^6 = {:.10}, 0.5^10 = {:.10}, 0.2^4 = {:.10}", ipow(0.3, 6), ipow(0.5, 10), ipow(0.2, 4));
    println!("P(6, 10, 4) by the formula          = {:.6}", exact);
    println!("P(6, 10, 4) by the customer table   = {:.6}", law[6][10]);
    println!("table total over {} tallies = {:.6}; most likely tally {}, {}, {}", (N + 1) * (N + 2) / 2, total, best.0, best.1, N - best.0 - best.1);
    println!("means from the table: small {:.4}, medium {:.4}, large {:.4}", mean[0], mean[1], mean[2]);
    for (i, name) in ["small", "medium", "large"].iter().enumerate() {
        println!("covariance row {:6}: {:8.4} {:8.4} {:8.4}; formula diagonal {:.4}", name, cov[i][0], cov[i][1], cov[i][2], nf * P[i] * (1.0 - P[i]));
    }
    println!("formula off-diagonal: -n p1 p2 = {:.4}, -n p1 p3 = {:.4}, -n p2 p3 = {:.4}", -nf * P[0] * P[1], -nf * P[0] * P[2], -nf * P[1] * P[2]);
    println!("correlation small with medium = {:.4}; variance of the total = {:.4}", corr, add(cov.iter().map(|r| add(r.iter().copied()))));
    let mut marg_err: f64 = 0.0;                  // each count alone, summed out of the table
    for i in 0..3 {
        let (mut marg, pmf) = (vec![0.0; N + 1], binom_pmf(N, P[i]));
        for s in 0..=N { for m in 0..=(N - s) { marg[[s, m, N - s - m][i]] += law[s][m] } }
        for a in 0..=N { marg_err = marg_err.max((marg[a] - pmf[a]).abs()) }
    }
    println!("each count alone matches Binomial(20, its chance) to 1e-12: {}", if marg_err < 1e-12 { "yes" } else { "no" });
    let bars: Vec<String> = (4..=16).map(|m| format!("{:.4}", add((0..=(N - m)).map(|s| law[s][m])))).collect();
    println!("figure, P(medium = m), m = 4..16: {}", bars.join(", "));
    let ms: Vec<usize> = (0..=N).step_by(2).collect();
    let cond: Vec<f64> = ms.iter().map(|&m| {
        let w: Vec<f64> = (0..=(N - m)).map(|s| law[s][m]).collect();
        add((0..w.len()).map(|s| s as f64 * w[s])) / add(w.iter().copied())
    }).collect();
    println!("figure, mean small given m medium, m = 0,2..20: {}", cond.iter().map(|c| format!("{:.2}", c)).collect::<Vec<_>>().join(", "));
    println!("figure, mean large given m medium, m = 0,2..20: {}", ms.iter().zip(&cond).map(|(&m, c)| format!("{:.2}", (N - m) as f64 - c)).collect::<Vec<_>>().join(", "));
    println!("given m medium, each other customer is small with chance 0.3 / (0.3 + 0.2) = {:.4}", P[0] / (P[0] + P[2]));
    let mut rng = SplitMix(20260928);
    let (cut1, cut2, days_n) = ((0.3 * 2f64.powi(53)) as u64, (0.8 * 2f64.powi(53)) as u64, 100000usize);
    let (mut hits, mut days, mut ss, mut sm, mut ssm) = (0usize, Vec::new(), 0i64, 0i64, 0i64);
    for _ in 0..days_n {                          // road three: simulate the days
        let (mut s, mut m) = (0i64, 0i64);
        for _ in 0..N {
            let u = rng.draw();
            if u < cut1 { s += 1 } else if u < cut2 { m += 1 }
        }
        if (s, m) == (6, 10) { hits += 1 }
        days.push((s, m));
        ss += s; sm += m; ssm += s * m;
    }
    let d = days_n as f64;
    let ph = hits as f64 / d;
    let cov_sim = (ssm as f64 - (ss * sm) as f64 / d) / (d - 1.0);
    let mut dev = 0.0;
    for &(s, m) in &days {
        let x = (s as f64 - ss as f64 / d) * (m as f64 - sm as f64 / d) - cov_sim;
        dev += x * x;
    }
    let se_cov = (dev / (d - 1.0) / d).sqrt();
    let se_p = (ph * (1.0 - ph) / d).sqrt();
    println!("simulated {} days, seed 20260928: P(6, 10, 4) = {:.5} +/- {:.5}; Cov(small, medium) = {:.4} +/- {:.4}", days_n, ph, se_p, cov_sim, se_cov);
    let indep = binom_pmf(N, P[0])[6] * binom_pmf(N, P[1])[10] * binom_pmf(N, P[2])[4];
    let pairs = table(P, N / 2, 2);
    let (_, pc) = moments(&pairs);
    let pair_formula = formula([3, 5, 2], P, 10);
    println!("mistake 1, one order only, no coefficient: {:.12}, not {:.6}", one_order, exact);
    println!("mistake 2, three binomial chances multiplied as if independent: {:.6}, not {:.6}", indep, exact);
    println!("mistake 3, the three variances added: {:.4}, but the total never moves", cov[0][0] + cov[1][1] + cov[2][2]);
    println!("mistake 4, customers in 10 pairs ordering alike: P(6, 10, 4) = {:.6}, formula on pairs {:.6}; Var(medium) = {:.4}; Cov(small, medium) = {:.4}", pairs[6][10], pair_formula, pc[1][1], pc[0][1]);
    assert!((exact - law[6][10]).abs() < 1e-12 * exact);                // formula against the table
    assert!(marg_err < 1e-12 && (total - 1.0).abs() < 1e-12);           // marginals are the binomials
    for i in 0..3 { for j in 0..3 {
        let want = nf * P[i] * ((if i == j { 1.0 } else { 0.0 }) - P[j]);
        assert!((cov[i][j] - want).abs() < 1e-9);
    } }
    assert!((best.0, best.1) == (6, 10) && ms.iter().zip(&cond).all(|(&m, c)| (c - P[0] / (P[0] + P[2]) * (N - m) as f64).abs() < 1e-9));
    assert!((ph - exact).abs() < 4.0 * se_p && (cov_sim - cov[0][1]).abs() < 4.0 * se_cov);   // simulation agrees
    assert!((pairs[6][10] - pair_formula).abs() < 1e-12 && (pc[1][1] - 2.0 * cov[1][1]).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
