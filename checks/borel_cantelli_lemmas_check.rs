// The Borel-Cantelli lemmas -- the check behind the card.  Rust std only.
// A fair die rolled forever.  A_n: roll n is a six.  B_n: rolls n to 2n-1 are
// all sixes, so roll n starts a run of n sixes.  Exact chances are integer
// fractions over 6^L, written by hand.  Finite stages only; the infinite claims
// rest on the proofs.
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn frac(n: u128, d: u128) -> String { let g = gcd(n, d); format!("{}/{}", n / g, d / g) }
fn p6(k: u32) -> u128 { 6u128.pow(k) }
fn b(mask: u32, n: u32) -> bool { (n..2 * n).all(|i| mask >> (i - 1) & 1 == 1) }
// exact P(event) as numerator over 6^L, listing every six/not-six pattern of rolls 1..L
fn prob(l: u32, event: &dyn Fn(u32) -> bool) -> u128 {
    let mut num = 0u128;
    for mask in 0..(1u32 << l) {
        if event(mask) { num += 5u128.pow(l - mask.count_ones()); }
    }
    num
}
// P(B_1 or ... or B_m) by inclusion-exclusion, numerator over 6^(2m-1)
fn incl_excl(m: u32) -> i128 {
    let l = 2 * m - 1;
    let mut num = 0i128;
    for s in 1u32..(1 << m) {
        let mut rolls = 0u32;
        for n in 1..=m { if s >> (n - 1) & 1 == 1 { for i in n..2 * n { rolls |= 1 << (i - 1); } } }
        let term = p6(l - rolls.count_ones()) as i128;
        num += if s.count_ones() % 2 == 1 { term } else { -term };
    }
    num
}
fn exp_series(x: f64) -> f64 {
    let (mut term, mut s, mut k) = (1.0f64, 1.0f64, 0.0f64);
    while term > 1e-18 * s { k += 1.0; term *= x / k; s += term; }
    s
}
fn exp_squaring(x: f64) -> f64 {
    let mut y = 1.0 + x / 2f64.powi(20);
    for _ in 0..20 { y *= y; }
    y
}
struct Rng(u64);
impl Rng {
    fn roll(&mut self) -> u64 { // SplitMix64, then a face 1..6
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) % 6 + 1
    }
}
fn main() {
    println!("lemma 1, B_n: n, P(B_n) listed, 6^-n, sum of P(B_k) to n, closed form (1 - 6^-n)/5");
    for n in 1..=6u32 {
        let l = 2 * n - 1;
        let listed = prob(l, &|mask| b(mask, n));
        let partial: u128 = (1..=n).map(|k| p6(n - k)).sum(); // over 6^n
        let closed = (p6(n) - 1) / 5; // (1 - 6^-n)/5 over 6^n: 6^n - 1 is a multiple of 5
        assert!(listed * p6(n) == p6(l)); // listing against the formula
        assert!(partial * 5 == p6(n) - 1); // term by term against the closed form
        let (pf, cf) = (partial as f64 / p6(n) as f64, closed as f64 / p6(n) as f64);
        println!("n={} {} {} {:.6} {:.6}", n, frac(listed, p6(l)), frac(1, p6(n)), pf, cf);
    }
    println!("sum over all n of P(B_n) = (1/6)/(1 - 1/6) = {}", frac(p6(1), p6(1) * (p6(1) - p6(0))));
    let mut unions = Vec::new();
    let mut ie = Vec::new();
    for m in 1..=6u32 {
        let l = 2 * m - 1;
        let u = prob(l, &|mask| (1..=m).any(|n| b(mask, n)));
        let v = incl_excl(m);
        assert!(u as i128 == v); // two roads to every union
        unions.push(u as f64 / p6(l) as f64);
        ie.push(v as f64 / p6(l) as f64);
    }
    let show = |v: &Vec<f64>| v.iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" ");
    println!("P(B_1 or ... or B_m), m=1..6, listed:   {}", show(&unions));
    println!("same, by inclusion-exclusion:           {}", show(&ie));
    let u2 = prob(3, &|mask| b(mask, 1) || b(mask, 2));
    let u6 = prob(11, &|mask| (1..=6).any(|n| b(mask, n)));
    let lo = u6 as f64 / p6(11) as f64;
    let hi = (u6 * 5 + p6(5)) as f64 / (5 * p6(11)) as f64; // plus 6^-6/5
    println!("m=2 exactly {}; some B_n ever: between {:.6} and {:.6}", frac(u2, p6(3)), lo, hi);
    let tails: Vec<f64> = (1..=6u32).map(|n| 1.0 / (5 * p6(n - 1)) as f64).collect();
    for n in 1..=6i32 {
        let f: f64 = (n..n + 60).map(|k| 6f64.powi(-k)).sum();
        assert!((tails[(n - 1) as usize] - f).abs() < 1e-12);
    }
    let ts: Vec<String> = tails.iter().map(|t| format!("{:.4}", t)).collect();
    println!("union bound on P(some B_n with n >= N), N=1..6: {}", ts.join(" "));
    let win: Vec<String> = (1..=6).map(|_| format!("{:.4}", 1.0 - (5.0f64 / 6.0).powi(60))).collect();
    println!("chance of some A_n with n >= N, N=1..6, within 60 rolls: {}", win.join(" "));

    println!("lemma 2, no six in m rolls in a row: exact (5/6)^m <= bound e^(-m/6)");
    for m in [6u32, 12, 30, 60] {
        let exact = (5.0f64 / 6.0).powi(m as i32);
        let bound = 1.0 / exp_series(m as f64 / 6.0);
        assert!(exact < bound);
        println!("m={:3}: {:.8} <= {:.8}", m, exact, bound);
    }
    let e10 = (1.0 / exp_series(10.0), 1.0 / exp_squaring(10.0));
    assert!((e10.0 / e10.1 - 1.0).abs() < 1e-4);
    println!("e^(-10) by series {:.8}, by squaring {:.8}", e10.0, e10.1);

    let mut rng = Rng(20260929);
    let (m_paths, r_len) = (20000usize, 120usize);
    let (mut sixes, mut late, mut runs, mut any_run, mut late_run, mut glued) = (0usize, 0, 0, 0, 0, 0);
    for _ in 0..m_paths {
        let mut r = vec![false; r_len + 1]; // r[i]: roll i is a six
        for i in 1..=r_len { r[i] = rng.roll() == 6; }
        sixes += r.iter().filter(|&&x| x).count();
        if r[61..].iter().any(|&x| x) { late += 1; }
        let starts: Vec<usize> = (1..=60).filter(|&n| r[n..2 * n].iter().all(|&x| x)).collect();
        runs += starts.len();
        if !starts.is_empty() { any_run += 1; }
        if starts.iter().any(|&n| n >= 3) { late_run += 1; }
        if r[1] { glued += 1; }
    }
    let mf = m_paths as f64;
    println!("simulation, {} paths of {} rolls, SplitMix64 seed 20260929:", m_paths, r_len);
    println!("mean sixes per path {:.4}, exact 20", sixes as f64 / mf);
    println!("share with a six in rolls 61 to 120 {:.5}, exact {:.5}", late as f64 / mf, 1.0 - (5.0f64 / 6.0).powi(60));
    println!("mean run-starts B_n per path, n <= 60: {:.4}, exact {:.4}", runs as f64 / mf, (1.0 - 6f64.powi(-60)) / 5.0);
    println!("share with at least one run-start {:.4}, exact {:.4}", any_run as f64 / mf, lo);
    println!("share with a run-start at n >= 3 {:.4}, at most {:.4}", late_run as f64 / mf, tails[2]);
    println!("share with roll 1 a six, the glued events happening infinitely often {:.4}, exact {:.4}", glued as f64 / mf, 1.0 / 6.0);
    let se = |p: f64| 4.0 * (p * (1.0 - p) / mf).sqrt();
    assert!((sixes as f64 / mf - 20.0).abs() < 4.0 * (120.0 * 5.0 / 36.0 / mf).sqrt());
    assert!((any_run as f64 / mf - lo).abs() < se(lo) && (glued as f64 / mf - 1.0 / 6.0).abs() < se(1.0 / 6.0));
    assert!((late_run as f64 / mf) < tails[2] + se(tails[2]));

    println!("subsequence, X_n = share of sixes in the first n rolls, tolerance 0.05:");
    for n in [100i64, 400, 900, 1600] {
        let (mut pmf, mut tail) = ((5.0f64 / 6.0).powf(n as f64), 0.0f64);
        for j in 0..=n {
            if 20 * (6 * j - n).abs() > 6 * n { tail += pmf; }
            pmf *= (n - j) as f64 / (j + 1) as f64 / 5.0;
        }
        let bound = 500.0 / (9.0 * n as f64);
        assert!(tail <= bound); // exact binomial tail under Chebyshev
        println!("n={:4}: Chebyshev bound 500/(9n) = {:.6}, exact binomial {:.6}", n, bound, tail);
    }
    let all_n: f64 = (1..=10000).map(|n| 500.0 / (9.0 * n as f64)).sum();
    let squares: f64 = (1..=100).map(|k| 500.0 / (9.0 * (k * k) as f64)).sum();
    println!("sum of the bounds over all n <= 10000: {:.4}; over n = k^2, k <= 100: {:.4}", all_n, squares);
    println!("bound on the sum over k > K of 500/(9k^2), 500/(9K): K=100 {:.4}, K=1000 {:.4}", 500.0 / 900.0, 500.0 / 9000.0);
    let mut xs = vec![0i64; 10001];
    let mut miss = Vec::new();
    for n in 1..=10000usize { xs[n] = xs[n - 1] + if rng.roll() == 6 { 1 } else { 0 }; }
    for k in 1..=100i64 {
        let n = k * k;
        if 20 * (6 * xs[n as usize] - n).abs() > 6 * n { miss.push(k.to_string()); }
    }
    let xv: Vec<String> = [100usize, 900, 2500, 10000].iter().map(|&n| format!("{:.4}", xs[n] as f64 / n as f64)).collect();
    println!("one path of 10000 rolls: X_n at n = 100, 900, 2500, 10000: {}", xv.join(" "));
    println!("k <= 100 with |X_(k^2) - 1/6| > 0.05: {} ({} of 100)", miss.join(" "), miss.len());
    println!("ALL CHECKS PASS");
}
