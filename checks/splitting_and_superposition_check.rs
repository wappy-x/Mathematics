// Splitting and merging Poisson streams -- the same check as the Python, in Rust.
// No crates.  A switchboard takes calls at 4 an hour; each call is routed to
// sales with chance 0.25, else to support.  Four roads to the joint law of the
// two desks: the formula; every label word enumerated; a grid of m slots an
// hour as m grows; a seeded simulation, with errors.
const LAM: f64 = 4.0;
const P: f64 = 0.25;
const H: usize = 200000;
const SEED: u64 = 20260930;
const NMAX: usize = 16;
const ROT: usize = 4;

fn fact(n: usize) -> f64 { (2..=n).fold(1.0, |acc, i| acc * i as f64) }

fn pois(k: usize, mu: f64) -> f64 { (-mu).exp() * mu.powi(k as i32) / fact(k) }  // Poisson probability of k

struct SplitMix64 { s: u64 }                        // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {                  // a number in [0, 1) with 53 random bits
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn wait(&mut self, rate: f64) -> f64 { -(1.0 - self.uniform()).ln() / rate }  // exponential, hours
}

fn freq(hits: usize, n: usize) -> (f64, f64) {      // a simulated share and its standard error
    let f = hits as f64 / n as f64;
    (f, (f * (1.0 - f) / n as f64).sqrt())
}

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (l1, l2) = (P * LAM, (1.0 - P) * LAM);
    println!("setup: calls at {:.0} an hour; each call is sales with chance {}, else support", LAM, P);
    println!("split rates: sales {:.1} an hour, support {:.1} an hour", l1, l2);
    let (pt, words) = (pois(3, LAM), 3.0 * P * (1.0 - P).powi(2));
    println!("worked, one hour: P(total 3) = {:.6}; label words for 1 sales in 3 = {:.6}; product {:.6}", pt, words, pt * words);
    println!("worked, one hour: P(sales 1) = {:.6}; P(support 2) = {:.6}; product {:.6}",
             pois(1, l1), pois(2, l2), pois(1, l1) * pois(2, l2));

    // road two: every label word of every length n up to NMAX, weighted and binned
    let mut joint = vec![vec![0.0f64; NMAX + 1]; NMAX + 1];
    for n in 0..=NMAX {
        for mask in 0u32..(1u32 << n) {
            let a = mask.count_ones() as usize;
            joint[a][n - a] += pois(n, LAM) * P.powi(a as i32) * (1.0 - P).powi((n - a) as i32);
        }
    }
    let mut gap = 0.0f64;
    for a in 0..=NMAX { for b in 0..=(NMAX - a) { gap = gap.max((joint[a][b] - pois(a, l1) * pois(b, l2)).abs()) } }
    println!("enumeration: {} label words; every cell equals Poisson(1) x Poisson(3) to 1e-15: {}",
             (1usize << (NMAX + 1)) - 1, if gap < 1e-15 { "yes" } else { "no" });
    let given_support: Vec<f64> = (0..7).map(|k| joint[0][k] / (0..=(NMAX - k)).map(|a| joint[a][k]).sum::<f64>()).collect();
    let given_total: Vec<f64> = (0..7).map(|k| joint[0][k] / pois(k, LAM)).collect();
    println!("chart, P(sales silent | support took k), k = 0..6: {}", join(&given_support));
    println!("chart, P(sales silent | switchboard took k), k = 0..6: {}", join(&given_total));
    assert!(gap < 1e-15);                                                         // words against the formula
    assert!(given_support.iter().all(|x| (x - (-l1).exp()).abs() < 1e-4));       // independence: flat at e^-1

    // road three: m slots an hour, each holding one sales call, one support call, or none
    let (target, mut last) = (pois(1, l1) * pois(2, l2), 1.0f64);
    for m in [10.0f64, 100.0, 1000.0, 10000.0] {
        let grid = m * (m - 1.0) * (m - 2.0) / 2.0 * (l1 / m) * (l2 / m).powi(2) * (1.0 - LAM / m).powi(m as i32 - 3);
        println!("grid, {} slots an hour: P(sales 1, support 2) = {:.6}, off by {:.6}", m, grid, (grid - target).abs());
        assert!((grid - target).abs() < last);                                   // the error shrinks with m
        last = (grid - target).abs();
    }
    assert!(last < 2e-4);

    // road four: one long stream of calls, labelled by coin and by a 1-in-ROT rotation
    let mut g = SplitMix64 { s: SEED };
    let (mut sales, mut support, mut rota, mut fig) = (vec![0usize; H], vec![0usize; H], vec![0usize; H], Vec::new());
    let (mut t, mut calls) = (g.wait(LAM), 0usize);
    while t < H as f64 {
        let h = t as usize;
        calls += 1;
        let is_sales = g.uniform() < P;
        if is_sales { sales[h] += 1 } else { support[h] += 1 }
        if calls % ROT == 0 { rota[h] += 1 }
        if t < 2.0 { fig.push(format!("{:.3}{} x {:.1}", t, if is_sales { "S" } else { "U" }, 40.0 + 150.0 * t)) }
        t += g.wait(LAM);
    }
    println!("simulation: {} hours, seed {}, {} calls", H, SEED, calls);
    let hf = H as f64;
    let ms = sales.iter().sum::<usize>() as f64 / hf;
    let mu = support.iter().sum::<usize>() as f64 / hf;
    let ses = (sales.iter().map(|&x| (x as f64 - ms).powi(2)).sum::<f64>() / hf / hf).sqrt();
    let seu = (support.iter().map(|&x| (x as f64 - mu).powi(2)).sum::<f64>() / hf / hf).sqrt();
    println!("simulated calls an hour: sales {:.4} +- {:.4}, support {:.4} +- {:.4}", ms, ses, mu, seu);
    let (f12, se12) = freq((0..H).filter(|&i| sales[i] == 1 && support[i] == 2).count(), H);
    println!("simulated P(sales 1, support 2) = {:.4} +- {:.4}, exact {:.4}", f12, se12, target);
    let prods: Vec<f64> = (0..H).map(|i| (sales[i] as f64 - ms) * (support[i] as f64 - mu)).collect();
    let cov = prods.iter().sum::<f64>() / hf;
    let secov = (prods.iter().map(|x| (x - cov).powi(2)).sum::<f64>() / hf / hf).sqrt();
    println!("simulated covariance of sales and support counts = {:.4} +- {:.4}, exact 0", cov, secov);
    for (x, e, s) in [(ms, l1, ses), (mu, l2, seu), (f12, target, se12), (cov, 0.0, secov)] {
        assert!((x - e).abs() < 4.0 * s);
    }
    for k in 0..7 {
        let nk = support.iter().filter(|&&x| x == k).count();
        let (f, se) = freq((0..H).filter(|&i| support[i] == k && sales[i] == 0).count(), nk);
        println!("simulated P(sales silent | support took {}) = {:.4} +- {:.4} over {} hours", k, f, se, nk);
        assert!((f - (-l1).exp()).abs() < 4.0 * se);
    }
    println!("figure, first 2 hours, time in hours, S sales or U support, x = 40 + 150 t: {}", fig.join(", "));

    // merging: a sales line at 1 an hour and a support line at 3, drawn apart, added
    let mut merged = vec![0usize; H];
    let (mut t1, mut t2) = (g.wait(l1), g.wait(l2));
    let (mut prev, mut ng, mut sg, mut sg2, mut from_sales) = (0.0f64, 0usize, 0.0f64, 0.0f64, 0usize);
    while t1.min(t2) < hf {
        let t;
        if t1 < t2 { t = t1; t1 += g.wait(l1); from_sales += 1 } else { t = t2; t2 += g.wait(l2) }
        merged[t as usize] += 1;
        ng += 1;
        sg += t - prev;
        sg2 += (t - prev).powi(2);
        prev = t;
    }
    for k in 0..9 {
        let conv: f64 = (0..=k).map(|i| pois(i, l1) * pois(k - i, l2)).sum();
        let (f, se) = freq(merged.iter().filter(|&&x| x == k).count(), H);
        println!("merge, P(merged count = {}): formula {:.6}, convolution {:.6}, simulated {:.4} +- {:.4}",
                 k, pois(k, LAM), conv, f, se);
        assert!((conv - pois(k, LAM)).abs() < 1e-15 && (f - conv).abs() < 4.0 * se);
    }
    let mg = sg / ng as f64;
    let seg = ((sg2 / ng as f64 - mg * mg) / ng as f64).sqrt();
    let (fs, sefs) = freq(from_sales, ng);
    println!("merge, gap between merged calls: exact {:.4} hours, simulated {:.4} +- {:.4} over {} gaps", 1.0 / LAM, mg, seg, ng);
    println!("merge, share of merged calls from sales: exact {:.4}, simulated {:.4} +- {:.4}", l1 / LAM, fs, sefs);
    assert!((mg - 1.0 / LAM).abs() < 4.0 * seg);
    assert!((fs - l1 / LAM).abs() < 4.0 * sefs);

    // what breaks when a hypothesis is dropped
    let rr_exact = (1..=ROT).map(|j| (0..j).map(|i| pois(i, LAM)).sum::<f64>()).sum::<f64>() / ROT as f64;
    let (frr, serr) = freq(rota.iter().filter(|&&x| x == 0).count(), H);
    println!("mistake, every {}th call to sales: P(sales silent an hour) exact {:.4}, simulated {:.4} +- {:.4}, Poisson {:.4}", ROT,
             rr_exact, frr, serr, (-LAM / ROT as f64).exp());
    assert!((frr - rr_exact).abs() < 4.0 * serr);
    let w: Vec<(f64, f64)> = (0u32..16).map(|m| { let a = m.count_ones() as i32;
        (a as f64, P.powi(a) * (1.0 - P).powi(4 - a)) }).collect();
    let p0: f64 = w.iter().filter(|(a, _)| *a == 0.0).map(|(_, q)| q).sum();
    let cv = w.iter().map(|(a, q)| q * a * (4.0 - a)).sum::<f64>()
        - w.iter().map(|(a, q)| q * a).sum::<f64>() * w.iter().map(|(a, q)| q * (4.0 - a)).sum::<f64>();
    println!("mistake, calls on the quarter hour, then coin labels: P(sales silent) {:.4}, covariance {:.4}", p0, cv);
    assert!((cv + 4.0 * P * (1.0 - P)).abs() < 1e-12);                            // minus a binomial variance
    let odd = (0..20).filter(|j| 2 * j == 1).map(|j| pois(j, l1)).fold(0.0, |s, x| s + x);
    println!("mistake, sales line merged with a copy of itself: P(1 call) {:.4}, P(2 calls) {:.4}; Poisson(2) says {:.4} and {:.4}",
             odd, pois(1, l1), pois(1, 2.0 * l1), pois(2, 2.0 * l1));
    println!("mistake, told the switchboard took 3: P(sales silent) {:.4}, not {:.4}", given_total[3], (-l1).exp());
    println!("ALL CHECKS PASS");
}
