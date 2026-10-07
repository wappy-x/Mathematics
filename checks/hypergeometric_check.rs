// Hypergeometric: drawing without replacement -- the same check in Rust, std only.
// The lottery: 6 balls drawn from 49, a ticket holds 6 numbers, X = how many of
// them are drawn.  Three roads to the law of X: count with binomial
// coefficients, enumerate all 13,983,816 draws, and follow the draw one ball at
// a time.  A seeded simulation checks the moments.
const N: usize = 49;
const K: usize = 6;
const NN: usize = 6; // balls drawn

fn c(a: usize, b: usize) -> u128 {                 // a choose b, by the product rule
    if b > a { return 0; }
    let mut v: u128 = 1;
    for j in 1..=b as u128 { v = v * (a as u128 - b as u128 + j) / j; }
    v
}

fn mass(n: usize, k: usize, d: usize) -> Vec<f64> { // road one: counting
    (0..=d).map(|j| if j > k || d - j > n - k { 0.0 } else {
        c(k, j) as f64 * c(n - k, d - j) as f64 / c(n, d) as f64 }).collect()
}

fn binom(d: usize, p: f64) -> Vec<f64> {           // the with-replacement law, for contrast
    (0..=d).map(|j| c(d, j) as f64 * p.powi(j as i32) * (1.0 - p).powi((d - j) as i32)).collect()
}

fn mean_var(p: &[f64]) -> (f64, f64) {
    let m: f64 = p.iter().enumerate().map(|(k, q)| k as f64 * q).sum();
    let s: f64 = p.iter().enumerate().map(|(k, q)| (k * k) as f64 * q).sum();
    (m, s - m * m)
}

fn enumerate(start: usize, left: usize, hits: usize, out: &mut [u64]) { // road two
    if left == 0 { out[hits] += 1; return; }
    for b in start..=N - left { enumerate(b + 1, left - 1, hits + (b < 6) as usize, out); }
}

struct SplitMix(u64);                              // SplitMix64, written out, seed stated
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn main() {
    let total = c(N, NN);
    let counted: Vec<u128> = (0..=NN).map(|k| c(K, k) * c(N - K, NN - k)).collect();
    let mut en = vec![0u64; NN + 1];
    enumerate(0, NN, 0, &mut en);
    let mut seq = vec![0.0f64; NN + 1];            // road three: 64 hit/miss paths
    for path in 0..(1u32 << NN) {
        let (mut pr, mut hits) = (1.0f64, 0usize);
        for i in 0..NN {
            if path >> i & 1 == 1 { pr *= (K - hits) as f64 / (N - i) as f64; hits += 1; }
            else { pr *= (N - K - (i - hits)) as f64 / (N - i) as f64; }
        }
        seq[hits] += pr;
    }
    let p = K as f64 / N as f64;
    let (pm, bm) = (mass(N, K, NN), binom(NN, p));
    println!("lottery: {} balls from {}; a ticket holds {} numbers; C(49,6) = {}", NN, N, K, total);
    let ordered: u128 = (44..=49).product();
    println!("by hand: 49x48x47x46x45x44 = {} ordered draws; / 720 = {}", ordered, ordered / 720);
    println!("by hand: C(6,3) = {}, C(43,3) = {}, product {}", c(6, 3), c(43, 3), c(6, 3) * c(43, 3));
    println!("k  counted  enumerated  P(X=k)      ball by ball  about 1 in");
    for k in 0..=NN {
        println!("{}  {:>7}  {:>10}  {:.8}  {:.8}    {:.1}", k, counted[k], en[k], pm[k], seq[k],
                 total as f64 / counted[k] as f64);
    }
    let pct = |v: &[f64]| v.iter().map(|q| format!("{:.2}", 100.0 * q)).collect::<Vec<_>>().join(", ");
    println!("chart, percent: hypergeometric {}", pct(&pm));
    println!("chart, percent: binomial       {}", pct(&bm));
    let tail: f64 = pm[3..].iter().sum();
    println!("at least 3 matches: {:.6}, about 1 in {:.1}", tail, 1.0 / tail);
    println!("jackpot with replacement (binomial): 1 in {:.1}, {:.1} times too likely", 1.0 / bm[6], bm[6] / pm[6]);
    println!("sample share of the pool: {:.2} percent", 100.0 * NN as f64 / N as f64);
    let ((hm, hv), (bmean, bv)) = (mean_var(&pm), mean_var(&bm));
    let fpc = (N - NN) as f64 / (N - 1) as f64;
    let nf = NN as f64;
    println!("mean from the table {:.6}; n K / N = {:.6}; binomial mean {:.6}", hm, nf * p, bmean);
    println!("variance from the table {:.6}; n p (1-p) (N-n)/(N-1) = {:.6}", hv, nf * p * (1.0 - p) * fpc);
    println!("binomial variance n p (1-p) = {:.6}; correction (N-n)/(N-1) = {:.6}", bv, fpc);
    let both = (K * (K - 1)) as f64 / (N * (N - 1)) as f64;
    println!("two named draws both hit: {:.6}; p^2 = {:.6}; covariance {:.7}; {} ordered pairs", both, p * p, both - p * p, NN * (NN - 1));
    println!("variance as the draw grows, ticket of 6 (n, without, with replacement):");
    for m in (0..=N).step_by(7) {
        let wv = mean_var(&mass(N, K, m)).1;
        let mf = m as f64;
        let fv = mf * p * (1.0 - p) * (N - m) as f64 / (N - 1) as f64;
        assert!((wv - fv).abs() < 1e-12);          // table road against the correction formula
        println!("figure, n={:>2}  {:.2}  {:.2}", m, wv, mf * p * (1.0 - p));
    }
    println!("P(X=3) as the pool grows, same shares (6 in 49), 6 drawn:");
    for s in [1usize, 10, 100, 1000] {
        println!("  pool {:>5}: {:.6}", N * s, mass(N * s, K * s, NN)[3]);
    }
    println!("  binomial:   {:.6}", bm[3]);
    println!("smaller game, 6 from 39: jackpot 1 in {:.1}; correction {:.6}", 1.0 / mass(39, K, NN)[6], (39 - NN) as f64 / 38.0);
    let wrong = c(K, 3) as f64 * c(N - 3, 3) as f64 / total as f64;
    println!("mistake, ordered over unordered jackpot: 1 in {:.1}", total as f64 / 720.0);
    println!("mistake, choose 3 hits then any 3 balls: {:.6} for at least 3", wrong);

    let mut g = SplitMix(20260928);
    let r = 200000u64;
    let (mut s1, mut s2, mut s3, mut s4, mut big) = (0u64, 0u64, 0u64, 0u64, 0u64);
    for _ in 0..r {
        let mut balls: Vec<usize> = (0..N).collect();
        let mut x = 0u64;
        for i in 0..NN {                            // partial shuffle: 6 distinct balls
            let j = i + (g.next() % (N - i) as u64) as usize;
            balls.swap(i, j);
            x += (balls[i] < 6) as u64;
        }
        s1 += x; s2 += x * x; s3 += x * x * x; s4 += x * x * x * x; big += (x >= 3) as u64;
    }
    let rf = r as f64;
    let sm = s1 as f64 / rf;
    let sv = s2 as f64 / rf - sm * sm;
    let m4 = (s4 as f64 - 4.0 * sm * s3 as f64 + 6.0 * sm * sm * s2 as f64) / rf - 3.0 * sm.powi(4); // 4th moment about the mean
    let se_v = ((m4 - sv * sv) / rf).sqrt();
    let sp = big as f64 / rf;
    let se_p = (sp * (1.0 - sp) / rf).sqrt();
    println!("simulated, {} draws, seed 20260928: mean {:.4} (se {:.4})", r, sm, (sv / rf).sqrt());
    println!("simulated variance {:.4} (se {:.4}); at least 3 matches {:.5} (se {:.5})", sv, se_v, sp, se_p);
    assert!(counted.iter().zip(&en).all(|(a, b)| *a == *b as u128) && en.iter().sum::<u64>() as u128 == total);
    assert!(pm.iter().zip(&seq).all(|(a, b)| (a - b).abs() < 1e-15));
    assert!((hv - nf * p * (1.0 - p) * fpc).abs() < 1e-12 && (hm - nf * p).abs() < 1e-12);
    assert!((sv - hv).abs() < 4.0 * se_v && (sv - bv).abs() > 4.0 * se_v); // sees the correction
    assert!((sp - tail).abs() < 4.0 * se_p && (sm - hm).abs() < 4.0 * (sv / rf).sqrt());
    println!("ALL CHECKS PASS");
}
