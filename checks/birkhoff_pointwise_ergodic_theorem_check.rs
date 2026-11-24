// Birkhoff's pointwise ergodic theorem -- the check behind the card.  std only.
// The doubling map T x = 2x mod 1 shifts binary digits, so with f = first digit,
// f(T^k x) is digit k + 1 and the time average is a share of 1s.
use std::collections::HashMap;

struct SplitMix(u64); // SplitMix64 written out: the digits of a typical start
impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn fraction_digits(mut p: u64, q: u64, n: usize) -> Vec<u64> { // binary digits of p/q by long division
    (0..n).map(|_| { p *= 2; let d = (p >= q) as u64; p %= q; d }).collect()
}

fn typical_digits(n: usize, seed: u64) -> Vec<u64> {
    let (mut g, mut out) = (SplitMix(seed), Vec::with_capacity(n + 64));
    while out.len() < n {
        let w = g.next();
        out.extend((0..64).map(|i| (w >> (63 - i)) & 1));
    }
    out.truncate(n);
    out
}

fn sum(d: &[u64]) -> u64 { d.iter().sum() }

fn l1_binomial(n: usize) -> f64 { // road 1: digits are fair coins; p_k by the ratio rule
    let (mut p, mut tot) = (0.5f64.powi(n as i32), 0.0);
    for k in 0..=n {
        tot += p * (k as f64 / n as f64 - 0.5).abs();
        p = p * (n - k) as f64 / (k + 1) as f64;
    }
    tot
}

fn l1_enumerate(n: u32) -> f64 { // road 2: count the 1s in every n-digit string
    let tot: i64 = (0..1u64 << n).map(|j| (2 * j.count_ones() as i64 - n as i64).abs()).sum();
    tot as f64 / (2 * n as u64 * (1u64 << n)) as f64
}

fn maximal_dp(n_max: usize) -> (u128, u128, u128) { // road 1: count strings by (first digit, ones, flag)
    let mut st: HashMap<(u64, usize, bool), u128> = HashMap::new();
    st.insert((0, 0, false), 1);
    for n in 1..=n_max {
        let mut new = HashMap::new();
        for (&(f1, o, fl), &c) in &st { // the flag records: share above 3/5 at some n so far
            for d in 0..2u64 {
                let key = (if n == 1 { d } else { f1 }, o + d as usize, fl || 5 * (o + d as usize) > 3 * n);
                *new.entry(key).or_insert(0) += c;
            }
        }
        st = new;
    }
    let in_e = st.iter().filter(|(k, _)| k.2).map(|(_, c)| *c).sum();
    let f_e = st.iter().filter(|(k, _)| k.2 && k.0 == 1).map(|(_, c)| *c).sum();
    (in_e, f_e, 1u128 << n_max)
}

fn maximal_enumerate(n: usize) -> (u64, u64, u64, i64) { // road 2: every string of N + 1 digits
    let (mut in_e, mut f_e, mut worst) = (0, 0, i64::MIN);
    for j in 0..1u64 << (n + 1) {
        let d: Vec<i64> = (0..=n).map(|i| ((j >> (n - i)) & 1) as i64).collect();
        let m = |start: usize| { // M_N = max(0, S_1, ..., S_N) for g = 5 f - 3, from digit start
            let (mut s, mut m) = (0i64, 0i64);
            for i in start..start + n { s += 5 * d[i] - 3; m = m.max(s); }
            m
        };
        if m(0) > 0 {
            in_e += 1;
            f_e += d[0] as u64;
            worst = worst.max(m(0) - (5 * d[0] - 3) - m(1)); // Garsia: must be <= 0
        }
    }
    (in_e, f_e, 1u64 << (n + 1), worst)
}

fn main() {
    const BIG: usize = 1000000;
    let (third, seventh, typ) = (fraction_digits(1, 3, 1000), fraction_digits(1, 7, 1000), typical_digits(BIG, 2026));
    println!("-- doubling map, f = first binary digit: share of 1s in the first n digits");
    println!("n, start 1/3, start 1/7, typical start");
    for n in [10, 20, 50, 100, 200, 500, 1000] {
        let s = |d: &[u64]| sum(&d[..n]) as f64 / n as f64;
        println!("{}, {:.4}, {:.4}, {:.4}", n, s(&third), s(&seventh), s(&typ));
    }
    let ones = sum(&typ);
    println!("typical start, n = {}: {} ones, share {:.6}", BIG, ones, ones as f64 / BIG as f64);
    assert!(sum(&third) == 500 && sum(&seventh) == 1000 / 3);
    assert!((ones as f64 / BIG as f64 - 0.5).abs() < 4.0 * 0.5 / (BIG as f64).sqrt());
    let (mut blocks, mut tb) = ([0usize; 4], [0usize; 4]);
    for i in 0..BIG - 1 { blocks[(2 * typ[i] + typ[i + 1]) as usize] += 1; }
    for i in 0..999 { tb[(2 * third[i] + third[i + 1]) as usize] += 1; }
    let fmt = |b: &[usize; 4], t: f64| b.iter().map(|&c| format!("{:.4}", c as f64 / t)).collect::<Vec<_>>().join(" ");
    println!("pairs of digits 00 01 10 11, typical: {}; start 1/3: {}", fmt(&blocks, (BIG - 1) as f64), fmt(&tb, 999.0));
    assert!(blocks.iter().all(|&c| (c as f64 / (BIG - 1) as f64 - 0.25).abs() < 0.003));

    println!("-- convergence in L1: distance E|share - 1/2| over all starts");
    for n in [10, 100, 1000] {
        println!("n = {}: exact {:.6}, bell-curve estimate 1/sqrt(2 pi n) {:.6}", n, l1_binomial(n),
                 1.0 / (2.0 * std::f64::consts::PI * n as f64).sqrt());
    }
    println!("n = 10 by enumerating 1024 starts: {:.6}", l1_enumerate(10));
    assert!((l1_enumerate(10) - l1_binomial(10)).abs() < 1e-12);
    assert!((l1_binomial(1000) * (2.0 * std::f64::consts::PI * 1000.0).sqrt() - 1.0).abs() < 0.01);

    println!("-- maximal ergodic theorem: E_N = {{share of 1s exceeds 3/5 at some n <= N}}");
    for n in [10, 30, 100] {
        let (e, fe, tot) = maximal_dp(n);
        let g = (5 * fe) as f64 - (3 * e) as f64;
        println!("N = {}: m(E_N) = {:.4}, integral of f over E_N = {:.4}, integral of f - 3/5 over E_N = {:.4}",
                 n, e as f64 / tot as f64, fe as f64 / tot as f64, g / (5 * tot) as f64);
        assert!(5 * fe >= 3 * e); // Garsia's inequality
    }
    let (e12, _fe12, t12, worst) = maximal_enumerate(12);
    let dp12 = maximal_dp(12).0;
    println!("N = 12: m(E_N) by counting {:.6}, by digit strings {:.6}; largest M_N - g - M_N(T) on E_N: {}",
             e12 as f64 / t12 as f64, dp12 as f64 / 4096.0, worst);
    assert!(e12 as u128 * 4096 == dp12 * t12 as u128 && worst <= 0);
    println!("maximal inequality bound (1/2)/(3/5) = {:.4}", 0.5 / 0.6);

    let alpha = 2f64.log10();
    println!("-- rotation by alpha = log10 2 = {:.5}, start 0: leading digit of 2^k for k < n", alpha);
    let (mut p, mut lead): (Vec<u64>, [usize; 10]) = (vec![1], [0; 10]); // base 10^9 limbs, low first
    for n in 0..1000usize {
        let top = *p.last().unwrap(); // road 1: exact whole numbers
        lead[top.to_string().as_bytes()[0] as usize - 48] += 1;
        let mut carry = 0;
        for limb in p.iter_mut() { let v = *limb * 2 + carry; *limb = v % 1_000_000_000; carry = v / 1_000_000_000; }
        if carry > 0 { p.push(carry); }
        if [10, 100, 1000].contains(&(n + 1)) {
            let hits = (0..=n).filter(|&k| (k as f64 * alpha) % 1.0 < alpha).count(); // road 2: the orbit
            println!("n = {}: leading digit 1 by exact powers {}, by orbit in [0, alpha) {}, alpha n = {:.2}",
                     n + 1, lead[1], hits, alpha * (n + 1) as f64);
            assert!(hits == lead[1]);
        }
    }
    println!("digit, count of 1000, Benford 1000 log10(1 + 1/d)");
    for d in 1..10 { println!("{}, {}, {:.1}", d, lead[d], 1000.0 * (1.0 + 1.0 / d as f64).log10()); }
    assert!((1..10).all(|d| (lead[d] as f64 - 1000.0 * (1.0 + 1.0 / d as f64).log10()).abs() < 12.0));

    println!("-- what breaks");
    let q: Vec<f64> = [1u64, 3].iter().map(|&s| (0..1000u64).filter(|k| 4 * ((s + 5 * k) % 10) < 10).count() as f64 / 1000.0).collect();
    println!("rotation by 1/2, f = 1 on [0, 1/4): start 0.1 -> {:.4}, start 0.3 -> {:.4}, space average 0.2500", q[0], q[1]);
    let (mut x, mut h) = (0.75f64, 0);
    for _ in 0..1000 { h += (x >= 0.5) as u32; x /= 2.0; }
    println!("T x = x/2 keeps no length: start 0.75, share at n = 1000: {:.4}", h as f64 / 1000.0);
    println!("start 1/7: share at n = 1000: {:.4}", sum(&seventh) as f64 / 1000.0);
    let (mut x, mut h, mut dead) = (0.1f64, 0u32, 0u32);
    for k in 0..1000 {
        h += (x >= 0.5) as u32;
        x = 2.0 * x % 1.0;
        if dead == 0 && x == 0.0 { dead = k + 1; }
    }
    let bits = 0.1f64.to_bits(); // 0.1 as a whole number over a power of 2, read from its bits
    let mant = (bits & ((1u64 << 52) - 1)) | (1u64 << 52);
    let tz = mant.trailing_zeros();
    let (num, e2) = (mant >> tz, 1075 - ((bits >> 52) & 0x7ff) as i64 - tz as i64);
    println!("doubling 0.1 in floating point: {} ones in 1000 steps, share {:.4}, zero from step {}; \
0.1 is stored as {}/2^{}, whose numerator has {} ones", h, h as f64 / 1000.0, dead, num, e2, num.count_ones());
    assert!(h == num.count_ones() && dead as i64 == e2 && q == [0.5, 0.0]);
    println!("ALL CHECKS PASS");
}
