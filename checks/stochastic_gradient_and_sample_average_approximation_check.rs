// Stochastic gradient and sample average approximation -- the check behind the card.
// std only.  An online grocer with 200,000 customers (synthetic, from SplitMix64
// seed 2026) picks one delivery fee p.  Customer i books b_i (m_i - p) deliveries a
// month; each costs the grocer c = £1.  The card MINIMISES the average loss f(p) =
// minus the average monthly profit per customer, in pounds.
struct Rng { s: u64 }
impl Rng {
    fn next(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn unif(&mut self) -> f64 { (self.next() >> 11) as f64 * 2f64.powi(-53) }
    fn pick(&mut self, n: usize) -> usize { (self.next() % n as u64) as usize }
}
const N: usize = 200_000;
const C: f64 = 1.0;
const P0: f64 = 2.0;
const MU: f64 = 0.8; // every b_i lies in [0.4, 1.6]: curvature 2 b_i in [MU, L]
const L: f64 = 3.2;
const MARKS: [usize; 6] = [0, 1, 10, 100, 1000, 10000];

fn mean(xs: &[f64]) -> f64 {
    let mut s = 0.0;
    for x in xs { s += x; }
    s / xs.len() as f64
}

fn step(r: usize, k: usize) -> f64 {
    match r {
        0 => 0.5 / (k + 1) as f64,
        1 => 0.02,
        2 => 0.05 / (k + 1) as f64,
        3 => 0.25 / ((k + 1) * (k + 1)) as f64,
        _ => 0.5 / ((k + 1) as f64).sqrt(),
    }
}

fn main() {
    let mut rng = Rng { s: 2026 };
    let (mut b, mut m) = (Vec::with_capacity(N), Vec::with_capacity(N));
    for _ in 0..N {
        b.push(0.4 + 1.2 * rng.unif());
        m.push(4.0 + 6.0 * rng.unif());
    }
    let ff = |p: f64, i: usize| -(p - C) * b[i] * (m[i] - p); // one customer's loss, £ a month
    let g = |p: f64, i: usize| b[i] * (2.0 * p - m[i] - C);   // its slope in p
    let f = |p: f64| { let mut s = 0.0; for i in 0..N { s += ff(p, i); } s / N as f64 };

    // ---- the whole-population answer, two roads and a certificate ----
    let b1 = mean(&b);
    let bmc: Vec<f64> = (0..N).map(|i| b[i] * (m[i] + C)).collect();
    let bm = mean(&bmc);
    let pstar = bm / (2.0 * b1); // road 1: f'(p) = 0, solved
    let (f3, f4, f5) = (f(3.0), f(4.0), f(5.0));
    let curv = f5 - 2.0 * f4 + f3; // f'' from three loss values, h = 1
    let pvert = 4.0 - (f5 - f3) / (2.0 * curv); // road 2: vertex of the parabola
    let fstar = f(pstar);
    let slope = (f(pstar + 1e-3) - f(pstar - 1e-3)) / 2e-3;
    println!("customers {}; mean b {:.5}; mean b(m+c) {:.5}; best fee p* = £{:.4}; parabola vertex £{:.4}", N, b1, bm, pstar, pvert);
    println!("profit a customer a month: at £{:.2} £{:.4}; at p* £{:.4}; whole base £{:.0}", P0, -f(P0), -fstar, -fstar * N as f64);
    println!("certificate: f'(p*) = {:.6}, f'' = {:.4} > 0, so p* is the global minimum", slope, curv);
    assert!((pstar - pvert).abs() < 1e-6 && slope.abs() < 1e-6 && (curv - 2.0 * b1).abs() < 1e-6);
    let gm = mean(&(0..N).map(|i| g(P0, i)).collect::<Vec<_>>());
    assert!((gm - (f(P0 + 1e-3) - f(P0 - 1e-3)) / 2e-3).abs() < 1e-6); // g really is F's slope

    let z: Vec<f64> = (0..N).map(|i| g(pstar, i)).collect(); // each customer's slope at p*: pure noise
    let z1 = mean(&z);
    let z2 = mean(&z.iter().map(|x| x * x).collect::<Vec<_>>());
    let b2 = mean(&b.iter().map(|x| x * x).collect::<Vec<_>>());
    let bz = mean(&(0..N).map(|i| b[i] * z[i]).collect::<Vec<_>>());
    println!("noise at p*: sigma^2 = {:.4}; mu = {:.1}, L = {:.1}, f'' = {:.4}", z2, MU, L, curv);
    assert!(z1.abs() < 1e-9);

    // ---- stochastic gradient: one customer per step ----
    let names = ["Robbins-Monro 0.5/(k+1)", "constant 0.02", "timid 0.05/(k+1)", "summable 0.25/(k+1)^2", "root 0.5/sqrt(k+1)"];
    let exact = |r: usize| { // road 2: exact mean and mean square of e_k = p_k - p*
        let (mut m1, mut m2, mut out) = (P0 - pstar, (P0 - pstar).powi(2), Vec::new());
        for k in 0..=10000 {
            if MARKS.contains(&k) { out.push((m1, m2)); }
            let a = step(r, k);
            let n1 = (1.0 - 2.0 * a * b1) * m1 - a * z1;
            let n2 = (1.0 - 4.0 * a * b1 + 4.0 * a * a * b2) * m2 - 2.0 * a * (z1 - 2.0 * a * bz) * m1 + a * a * z2;
            m1 = n1; m2 = n2;
        }
        out
    };
    let sgd = |r: usize, kk: usize, rg: &mut Rng| {
        let (mut p, mut out) = (P0, Vec::new());
        for k in 0..=kk {
            if MARKS.contains(&k) { out.push(p); }
            if k < kk { p -= step(r, k) * g(p, rg.pick(N)); }
        }
        out
    };
    let ex: Vec<Vec<(f64, f64)>> = (0..5).map(|r| exact(r)).collect();
    let run = sgd(0, 10000, &mut Rng { s: 7 });
    let i0 = Rng { s: 7 }.pick(N);
    assert!((run[1] - (P0 - step(0, 0) * g(P0, i0))).abs() < 1e-12); // the loop's first step, by hand
    println!("first customer drawn: b {:.5}, m £{:.5}, slope at £2 {:.4}, p_1 = 2 - 0.5 x slope = £{:.4}", b[i0], m[i0], g(P0, i0), P0 - 0.5 * g(P0, i0));
    let s: Vec<String> = MARKS.iter().zip(&run).map(|(k, p)| format!("{}:£{:.4}", k, p)).collect();
    println!("one run, Robbins-Monro steps, fee p_k at k = {}", s.join(" "));
    println!("exact root-mean-square error |p_k - p*| in £, and its split at k = 10000:");
    for r in 0..5 {
        let (m1, m2) = ex[r][5];
        let s: Vec<String> = ex[r].iter().map(|e| format!("{:.4}", e.1.sqrt())).collect();
        println!("  {:24}{} | mean {:+.4}, start part {:.6} noise part {:.6}", names[r], s.join(" "), m1, m1 * m1, m2 - m1 * m1);
    }
    let ch: Vec<String> = (0..3).map(|r| ex[r].iter().map(|e| format!("{:.2}", e.1.sqrt().log10())).collect::<Vec<_>>().join(" ")).collect();
    println!("chart, log10 RMS error: {}", ch.join("; "));
    let (rr, mut rs) = (200usize, Rng { s: 11 });
    let mut sq = vec![Vec::new(); 4];
    for _ in 0..rr {
        let o = sgd(0, 10000, &mut rs);
        for j in 0..4 { sq[j].push((o[j + 2] - pstar).powi(2)); }
    }
    for j in 0..4 {
        let mc = mean(&sq[j]);
        let se = ((mean(&sq[j].iter().map(|x| x * x).collect::<Vec<_>>()) - mean(&sq[j]).powi(2)) / rr as f64).sqrt();
        let e = ex[0][j + 2].1;
        println!("  k = {:5}: simulated RMS £{:.4}, exact £{:.4}, gap {:+.2} se", MARKS[j + 2], mc.sqrt(), e.sqrt(), (mc - e) / se);
        assert!((mc - e).abs() < 4.0 * se);
    }
    println!("  sigma/(f'' sqrt k) at k = 10000: £{:.4}", (z2 / (curv * curv * 1e4)).sqrt());
    assert!((ex[0][5].1 / (z2 / (curv * curv * 1e4)) - 1.0).abs() < 0.02); // the 1/k law, step 1/f''
    assert!(ex[1][5].1 > 50.0 * ex[0][5].1 && ex[3][5].0.abs() > 0.5 && ex[2][5].0.abs() > 0.5);
    let fl = step(4, 10000) * z2 / (2.0 * curv); // floor where pull and kick balance
    println!("root steps, squares not summable: RMS £{:.4} at k = 10000; floor alpha_k sigma^2/(2f'') gives £{:.4}", ex[4][5].1.sqrt(), fl.sqrt());
    assert!((ex[4][5].1 / fl - 1.0).abs() < 0.02 && ex[4][5].1 < ex[4][4].1 / 3.0);
    let lg = 4.0 + (ex[2][5].0.abs() / 0.01).log10() / (0.1 * b1); // mean error shrinks like k^(-0.1 f''/2)
    println!("timid steps: 2af'' = {:.2}; mean error still £{:.4}; reaching £0.01 takes about 10^{:.1} steps", 0.1 * curv, ex[2][5].0.abs(), lg);
    println!("summable steps 0.25/(k+1)^2 add up to {:.3} in all", 0.25 * std::f64::consts::PI.powi(2) / 6.0);
    let (mut p, mut k, mut i) = (P0, 0usize, 0usize);
    while k < 10000 { // customers read in file order, keen ones (m > 7) only
        if m[i] > 7.0 { p -= step(0, k) * g(p, i); k += 1; }
        i += 1;
    }
    println!("biased stream, 10000 keen customers in file order: fee ends at £{:.4}", p);
    assert!(p - pstar > 0.5);

    // ---- sample average approximation: solve exactly on a sample of n customers ----
    println!("SAA: RMS error of the sample's best fee, against the bound sigma/(mu sqrt n)");
    for n in [100usize, 1000, 10000] {
        let (mut e2, mut opt, mut rs) = (Vec::new(), Vec::new(), Rng { s: 100 + n as u64 });
        for _ in 0..rr {
            let (mut sb, mut sbmc) = (0.0, 0.0);
            for _ in 0..n { let i = rs.pick(N); sb += b[i]; sbmc += b[i] * (m[i] + C); }
            let ph = sbmc / (2.0 * sb);
            e2.push((ph - pstar).powi(2));
            opt.push(sb / n as f64 * (ph - pstar).powi(2));
        }
        let mc = mean(&e2);
        let se = ((mean(&e2.iter().map(|x| x * x).collect::<Vec<_>>()) - mc.powi(2)) / rr as f64).sqrt();
        let (bound, asym) = (z2 / (MU * MU * n as f64), z2 / (curv * curv * n as f64));
        println!("  n = {:5}: simulated RMS £{:.4}, asymptotic £{:.4}, bound £{:.4} ({:.6}); claimed profit too high by {:.3}p, real profit short by {:.3}p",
                 n, mc.sqrt(), asym.sqrt(), bound.sqrt(), bound, 100.0 * mean(&opt), 100.0 * b1 * mc);
        assert!(mc + 4.0 * se < bound && (mc - asym).abs() < 4.0 * se + 0.1 * asym);
    }
    let need_mu = (z2 / (MU * MU * 0.1f64.powi(2) * 0.05)).ceil();
    let need_f = (z2 / (curv * curv * 0.1f64.powi(2) * 0.05)).ceil();
    println!("customers to sample for |p_hat - p*| < £0.10 with 95%: {} from mu, {} from f''", need_mu, need_f);
    println!("the 200,000 themselves, as a sample of future customers: RMS £{:.4}", (z2 / (curv * curv * N as f64)).sqrt());
    println!("ALL CHECKS PASS");
}
