// Poisson counts -- the same check as the Python, in Rust.  No crates.  A help
// desk receives 12 emails an hour on average.  The chance of more than 20 in one
// hour is reached by five roads: the mass summed up to 20 and subtracted from 1,
// the tail summed upward with log-factorials, a geometric bracket, the binomial
// with the hour cut into ever finer slots, and a seeded simulation.
const LAM: f64 = 12.0;
const CUT: usize = 20;
const TOP: usize = 150;

fn pmf_recurrence(lam: f64, top: usize) -> Vec<f64> {   // p0 = e^-lam, then p(k+1) = p(k) lam/(k+1)
    let mut p = vec![(-lam).exp()];
    for k in 0..top {
        let next = p[k] * lam / (k as f64 + 1.0);
        p.push(next);
    }
    p
}

fn pmf_logs(lam: f64, k: usize) -> f64 {                // e^(-lam + k ln lam - ln k!), ln k! summed
    let lf: f64 = (2..=k).map(|j| (j as f64).ln()).sum();
    (-lam + k as f64 * lam.ln() - lf).exp()
}

fn binom_pmf(n: usize, p: f64, top: usize) -> Vec<f64> { // (1-p)^n, then times (n-k)/(k+1) p/(1-p)
    let mut b = vec![(1.0 - p).powf(n as f64)];
    for k in 0..top {
        let next = if k < n { b[k] * (n - k) as f64 / (k as f64 + 1.0) * p / (1.0 - p) } else { 0.0 };
        b.push(next);
    }
    b
}

fn phi_normal(x: f64) -> f64 {                          // normal area left of x, by its Taylor series
    let (mut term, mut total, mut j) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        j += 1.0;
        term *= x * x / (2.0 * j + 1.0);
        total += term;
    }
    0.5 + (-x * x / 2.0).exp() / (2.0 * std::f64::consts::PI).sqrt() * total
}

fn poisson_tail(lam: f64, cut: usize) -> f64 {
    1.0 - pmf_recurrence(lam, cut)[..=cut].iter().sum::<f64>()
}

fn splitmix(state: &mut u64) -> f64 {                   // SplitMix64, uniform in [0,1)
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^= z >> 31;
    (z >> 11) as f64 * 2f64.powi(-53)
}

fn sci(x: f64, d: usize) -> String {                    // Python-style e-notation: 6.1442e-06
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn rows(label: &str, v: &[f64]) {
    println!("{}", label);
    for r in (0..31).step_by(8) {
        let cells: Vec<String> = (r..(r + 8).min(31)).map(|k| format!("{:.4}", v[k])).collect();
        println!("  {}", cells.join(", "));
    }
}

fn main() {
    let p = pmf_recurrence(LAM, TOP);
    let tail_a = 1.0 - p[..=CUT].iter().sum::<f64>();                          // road 1
    let tail_b: f64 = (CUT + 1..TOP).map(|k| pmf_logs(LAM, k)).sum();           // road 2
    let (lo, hi) = (p[CUT + 1], p[CUT + 1] / (1.0 - LAM / (CUT as f64 + 2.0))); // road 3
    let mean: f64 = p.iter().enumerate().map(|(k, q)| k as f64 * q).sum();
    let var = p.iter().enumerate().map(|(k, q)| (k * k) as f64 * q).sum::<f64>() - mean * mean;
    let fall2: f64 = p.iter().enumerate().map(|(k, q)| (k * k - k) as f64 * q).sum();
    println!("help desk: lambda = {} emails an hour; question: P(X > {})", LAM, CUT);
    println!("p0 = e^-12 = {}; p11 = {:.6}; p12 = {:.6}; p20 = {:.6}; p21 = {:.6}", sci(p[0], 4), p[11], p[12], p[20], p[21]);
    println!("P(X <= 20) = {:.6}", 1.0 - tail_a);
    println!("road 1, 1 minus the sum to 20:       P(X > 20) = {:.6}", tail_a);
    println!("road 2, tail summed upward by logs:  P(X > 20) = {:.6}", tail_b);
    println!("road 3, geometric bracket:  {:.6} <= P(X > 20) <= {:.6}", lo, hi);
    println!("read back: about one hour in {:.0}, or {:.2}% of hours", 1.0 / tail_a, 100.0 * tail_a);
    println!("sum of all masses = {:.12}", p.iter().sum::<f64>());
    println!("mean = {:.9}; E[X(X-1)] = {:.9}; variance = {:.9}; sd = {:.4}", mean, fall2, var, var.sqrt());
    rows("figure, Poisson(12) masses k=0..30:", &p);
    let b60 = binom_pmf(60, LAM / 60.0, 30);
    rows("figure, Binomial(60, 0.2) masses k=0..30:", &b60);
    let mut gaps: Vec<f64> = Vec::new();
    for n in [60usize, 600, 3600, 36000] {
        let b = binom_pmf(n, LAM / n as f64, CUT);
        let t = 1.0 - b.iter().sum::<f64>();
        let g = (t - tail_a).abs();
        gaps.push(g);
        println!("binomial, n = {:>5} slots, p = {:.6}: P(X > 20) = {:.6}; gap {}; n x gap = {:.3}; Le Cam bound 144/n = {:.4}",
                 n, LAM / n as f64, t, sci(g, 2), n as f64 * g, 144.0 / n as f64);
        assert!(g <= 144.0 / n as f64);
    }
    let (mut state, hours) = (20260928u64, 200000usize);
    let (mut total, mut total_sq, mut over) = (0usize, 0usize, 0usize);
    let floor = (-LAM).exp();
    for _ in 0..hours {                                  // multiply uniforms until the product < e^-12
        let (mut k, mut prod) = (0usize, 1.0f64);
        loop {
            prod *= splitmix(&mut state);
            if prod < floor { break }
            k += 1;
        }
        total += k; total_sq += k * k; if k > CUT { over += 1 }
    }
    let h = hours as f64;
    let s_mean = total as f64 / h;
    let s_var = (total_sq as f64 - h * s_mean * s_mean) / (h - 1.0);
    let s_tail = over as f64 / h;
    let se_tail = (tail_a * (1.0 - tail_a) / h).sqrt();
    println!("simulation, seed 20260928, {} hours: mean {:.4} (se {:.4}); variance {:.4} (se {:.4})",
             hours, s_mean, (LAM / h).sqrt(), s_var, ((LAM + 2.0 * LAM * LAM) / h).sqrt());
    println!("simulation: P(X > 20) = {:.5} (se {:.5}); hours over 20: {}", s_tail, se_tail, over);
    let at20 = tail_a + p[20];
    let (z_plain, z_cc) = ((CUT as f64 - LAM) / LAM.sqrt(), (CUT as f64 + 0.5 - LAM) / LAM.sqrt());
    let mix = 0.5 * poisson_tail(6.0, CUT) + 0.5 * poisson_tail(18.0, CUT);
    let pairs = poisson_tail(6.0, 10);
    println!("mistake, 'at least 20' for 'more than 20': P(X >= 20) = {:.6}", at20);
    println!("mistake, one email per minute at most: Binomial(60, 0.2) P(X > 20) = {:.6}; variance {:.1}",
             1.0 - b60[..21].iter().sum::<f64>(), 60.0 * 0.2 * 0.8);
    println!("mistake, normal curve, z = {:.4}: {:.6}; with the half-step, z = {:.4}: {:.6}",
             z_plain, 1.0 - phi_normal(z_plain), z_cc, 1.0 - phi_normal(z_cc));
    println!("mistake, 12 used for a two-hour window: true P(X > 20) at lambda 24 = {:.6}", poisson_tail(24.0, CUT));
    println!("breaks, rate 6 or 18 on a coin flip (mean 12, variance 48): P(X > 20) = {:.6}", mix);
    println!("breaks, emails in pairs, 6 pairs an hour (mean 12, variance 24): P(X > 20) = {:.6}", pairs);
    assert!((tail_a - tail_b).abs() < 1e-12);                      // two sums, one tail
    assert!(lo <= tail_a && tail_a <= hi);                         // bracket holds
    assert!((mean - LAM).abs() < 1e-9 && (var - LAM).abs() < 1e-9); // the theorem, by sums
    assert!(gaps.windows(2).all(|w| w[0] > w[1]));                 // slots finer, gap smaller
    assert!((binom_pmf(60, 0.2, 60).iter().enumerate().map(|(k, q)| k as f64 * q).sum::<f64>() - 60.0 * 0.2).abs() < 1e-9);
    assert!((s_tail - tail_a).abs() < 4.0 * se_tail);              // simulation agrees
    assert!((s_mean - LAM).abs() < 4.0 * (LAM / h).sqrt());
    assert!((s_var - LAM).abs() < 4.0 * ((LAM + 2.0 * LAM * LAM) / h).sqrt());
    let (q6, q18) = (pmf_recurrence(6.0, TOP), pmf_recurrence(18.0, TOP));
    let mix_var = q6.iter().zip(&q18).enumerate().map(|(k, (a, b))| (k * k) as f64 * (a + b) / 2.0).sum::<f64>() - LAM * LAM;
    let pair_var = q6.iter().enumerate().map(|(k, q)| (4 * k * k) as f64 * q).sum::<f64>() - LAM * LAM;
    assert!((mix_var - 48.0).abs() < 1e-9);                        // mixture variance 48
    assert!((pair_var - 24.0).abs() < 1e-9);                       // pairs variance 24
    let pairs_logs: f64 = (11..TOP).map(|k| pmf_logs(6.0, k)).sum();
    assert!((pairs - pairs_logs).abs() < 1e-12 && mix > pairs && pairs > tail_a);
    println!("ALL CHECKS PASS");
}
