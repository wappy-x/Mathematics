// The weak law of large numbers on a fair die: the check behind the card.
// Rust std only. A small exact fraction type; own dynamic program, minimiser and RNG.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i128, i128);
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn sub(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn le(a: Q, b: Q) -> bool { a.0 * b.1 <= b.0 * a.1 }
fn fl(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
fn show(a: Q) -> String { format!("{}/{}", a.0, a.1) }
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn step(p: &[f64]) -> Vec<f64> {                     // law of the sum after one more roll
    let mut new = vec![0.0; p.len() + 6]; let mut w = 0.0;
    for s in 0..new.len() {
        if s >= 1 && s <= p.len() { w += p[s - 1]; }
        if s >= 7 { w -= p[s - 7]; }
        new[s] = w / 6.0;
    }
    new
}
fn tail(p: &[f64], n: i64, k: i64) -> f64 {           // P(|S/n - 3.5| >= 1/k), in whole numbers
    let mut t = 0.0;
    for (s, ps) in p.iter().enumerate() { if (2 * k * s as i64 - 7 * k * n).abs() >= 2 * n { t += ps; } }
    t
}
fn gss(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..100 { let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo)); if f(a) < f(b) { hi = b } else { lo = a } }
    (lo + hi) / 2.0
}
fn logm(t: f64) -> f64 { let mut m = 0.0; for k in 1..=6 { m += (t * k as f64).exp(); } (m / 6.0).ln() }
fn tb(n: f64) -> f64 { n.powf(-0.5) + 12.0 * (n.sqrt() - 1.0) / (n * 0.25) }
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}
fn main() {
    let mu = q(21, 6); let var = sub(q(91, 6), mul(mu, mu));
    let (eps, delta) = (q(1, 10), q(1, 100));
    let c = div(var, mul(eps, eps));
    let qq = div(c, delta); let nn = (qq.0 + qq.1 - 1) / qq.1; let n_big = nn as i64;
    println!("one roll: mean {}, variance {} = {}; margin 0.1, confidence 0.99", f6(fl(mu)), show(var), f6(fl(var)));
    println!("Chebyshev: P(|average - 3.5| >= 0.1) <= {} / n = {} / n", show(c), f6(fl(c)));
    println!("n = {} gives {:.8}; n = {} gives {:.8}", nn, fl(div(c, q(nn, 1))), nn - 1, fl(div(c, q(nn - 1, 1))));
    assert!(le(div(c, q(nn, 1)), delta) && !le(div(c, q(nn - 1, 1)), delta));
    assert!(nn % 2 == 1);                              // code guard: two dice per draw below need an odd N
    // road 2: the exact law of the sum of n dice
    let mut p = vec![1.0f64]; let mut ex = std::collections::BTreeMap::new(); let mut ind15 = 0.0; let mut ex4 = 0.0;
    for n in 1..=1000i64 {
        p = step(&p);
        if n % 100 == 0 || n == 295 { ex.insert(n, tail(&p, n, 10)); }
        if n == 15 { ind15 = tail(&p, 15, 1); }
        if n == 4 { ex4 = tail(&p, 4, 4); }
    }
    let mut v1000 = 0.0;
    for (s, ps) in p.iter().enumerate() { let d = s as f64 / 1000.0 - 3.5; v1000 += ps * (d * d); }
    println!("exact law at n = 1000: variance of the average {:.9}, formula 35/12/1000 = {:.9}", v1000, fl(var) / 1000.0);
    assert!((v1000 - fl(var) / 1000.0).abs() < 1e-12);
    // road 3: the Chernoff bound
    let t = gss(&|t| logm(t) - 3.6 * t, 0.0, 5.0); let r = logm(t) - 3.6 * t;
    println!("Chernoff: best t {:.6}, exponent per roll {:.9}", t, r);
    println!("n, Chebyshev bound, exact P(miss), Chernoff bound");
    let (mut cap, mut exs) = (vec![], vec![]);
    for n in (100..=1000i64).step_by(100) {
        let (cb, e, ch) = (fl(c) / n as f64, ex[&n], 2.0 * (n as f64 * r).exp());
        println!("  {}, {}, {}, {}", n, f6(cb), f6(e), f6(ch));
        assert!(e <= cb.min(1.0) && e <= ch);
        cap.push(format!("{:.2}", cb.min(1.0))); exs.push(format!("{:.2}", e));
    }
    println!("chart, Chebyshev capped at 1: {}", cap.join(" "));
    println!("chart, exact: {}", exs.join(" "));
    println!("at n = {}: Chebyshev {:.8}, Chernoff {:.3e}", nn, fl(div(c, q(nn, 1))), 2.0 * (n_big as f64 * r).exp());
    // road 4: simulate 1000 runs of N rolls; SplitMix64, seed 20260929, two dice per 64-bit draw
    let mut rng = Rng(20260929); let rr = 1000;
    let (mut fails, mut ss, mut worst) = (0, 0.0f64, 0.0f64);
    for _ in 0..rr {
        let mut tot: i64 = 0;
        for j in 0..(n_big / 2 + 1) {
            let z = rng.next();
            tot += (((z >> 32) * 6) >> 32) as i64 + 1;
            if j < n_big / 2 { tot += (((z & 0xFFFFFFFF) * 6) >> 32) as i64 + 1; }
        }
        let d = tot as f64 / n_big as f64 - 3.5; ss += d * d; worst = worst.max(d.abs());
        if (10 * tot - 35 * n_big).abs() >= n_big { fails += 1; }
    }
    let (rms, sd) = ((ss / rr as f64).sqrt(), (fl(var) / n_big as f64).sqrt());
    println!("simulated, {} runs of {} rolls: misses {}; largest |average - 3.5| {:.6}", rr, n_big, fails, worst);
    println!("root-mean-square miss {:.6}; theory sqrt(35/12/{}) = {:.6}", rms, n_big, sd);
    assert!(fails == 0 && (rms - sd).abs() < 4.0 * sd / (2.0 * rr as f64).sqrt());
    // pairwise independent faces: 4 real dice x_i in 0..5 give 15 faces
    let outs: Vec<Vec<i128>> = (0..1296).map(|code: i128| {
        let x: Vec<i128> = (0..4).map(|i| code / 6i128.pow(i) % 6).collect();
        (1..16).map(|m| (0..4).filter(|&i| m >> i & 1 == 1).map(|i| x[i]).sum::<i128>() % 6 + 1).collect()
    }).collect();
    let mut pairs_ok = true;
    for a in 0..15 { for b in a + 1..15 {
        let mut cnt = [0; 36];
        for f in &outs { cnt[(6 * (f[a] - 1) + f[b] - 1) as usize] += 1; }
        pairs_ok = pairs_ok && cnt.iter().all(|&k| k == 36);
    } }
    let tt: Vec<i128> = outs.iter().map(|f| f.iter().sum()).collect();
    let v15 = q(tt.iter().map(|s| (2 * s - 105).pow(2)).sum(), 900 * 1296);
    let t15 = q(tt.iter().filter(|s| (2 * **s - 105).abs() >= 30).count() as i128, 1296);
    let trip = q(outs.iter().filter(|f| f[0] == 1 && f[1] == 1 && f[2] == 1).count() as i128, 1296);
    let e4 = q(outs.iter().filter(|f| (4 * (f[0] + f[1] + f[3] + f[7]) - 56).abs() >= 4).count() as i128, 1296); // faces 1, 2, 4, 8 are the dice
    println!("exact law checked by listing 4 dice: P(|average - 3.5| >= 0.25) = {} = {}; dynamic program {}", show(e4), f6(fl(e4)), f6(ex4));
    assert!((fl(e4) - ex4).abs() < 1e-12);
    println!("15 faces from 4 dice: every pair uniform on 36 outcomes: {}", if pairs_ok { "yes" } else { "no" });
    println!("  faces 1, 2 and 1+2 all show 1 with chance {} (independent faces: 1/216)", show(trip));
    println!("  variance of the average {}, formula (35/12)/15 = {}", show(v15), show(div(var, q(15, 1))));
    println!("  P(|average - 3.5| >= 1): {}; 15 independent dice {}; Chebyshev {}", f6(fl(t15)), f6(ind15), f6(fl(div(var, q(15, 1)))));
    assert!(pairs_ok && trip == q(1, 36) && v15 == div(var, q(15, 1)) && le(t15, v15));
    // finite mean, infinite variance: Pareto P(X > x) = x^-1.5 on x >= 1, mean 3, margin 0.5
    let tbs: Vec<String> = [4, 6, 8].iter().map(|&k| format!("n = 10^{}: {:.6}", k, tb(10f64.powi(k)))).collect();
    println!("truncation bound n^-0.5 + 12(sqrt(n) - 1)/(0.25 n): {}", tbs.join(", "));
    let (n2, r2) = (10000usize, 200usize); let (mut f2, mut big) = (0, 0);
    for _ in 0..r2 {
        let (mut tot, mut top) = (0.0f64, 0.0f64);
        for _ in 0..n2 {
            let xv = (1.0 - (rng.next() >> 11) as f64 / 2f64.powi(53)).powf(-2.0 / 3.0);
            tot += xv; top = top.max(xv);
        }
        if (tot / n2 as f64 - 3.0).abs() >= 0.5 { f2 += 1; }
        if top > n2 as f64 { big += 1; }
    }
    println!("simulated, {} runs of {} Pareto draws: misses {}; runs with a draw above n {} (bound n^-0.5 = 0.01)", r2, n2, f2, big);
    assert!(f2 as f64 / r2 as f64 <= tb(n2 as f64));
    // what breaks
    let cop = q((1..=6i128).filter(|x| (10 * x - 35).abs() >= 1).count() as i128, 6);
    let n_sd = (fl(var).sqrt() / fl(mul(delta, mul(eps, eps)))).ceil() as i128;
    let n_1d = (fl(div(c, sub(q(1, 1), delta)))).ceil() as i128;
    println!("breaks: every roll a copy of the first: P(miss) {} at every n; variance of the average {}", f6(fl(cop)), f6(fl(var)));
    println!("breaks: standard deviation for variance: n = {}, Chebyshev there {}", n_sd, f6(fl(div(c, q(n_sd, 1)))));
    println!("breaks: 1 - delta for delta: n = {}, Chebyshev there {}, exact P(miss) {}", n_1d, f6(fl(div(c, q(n_1d, 1)))), f6(ex[&295]));
    assert!(cop == q(1, 1) && !le(div(c, q(n_sd, 1)), delta) && n_1d == 295 && ex[&295] > fl(delta));
}
