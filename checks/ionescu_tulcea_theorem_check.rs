// The Ionescu-Tulcea theorem -- the check behind the card.  std only, no crates.
// Roads: (1) compose the urn's kernels step by step, in exact fractions;
// (2) the same chances as an integral over a uniform share p, by Simpson's rule;
// (3) build the draws from uniform numbers (SplitMix64, seed 20261123) and count.
// A pattern of n draws is a number whose bits, first draw highest, are 1 = red, 0 = black.
use std::fmt;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q { let g = gcd(n, d).max(1); Q { n: n / g, d: d / g } }
impl Q {
    fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) }
    fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
}
impl fmt::Display for Q {
    fn fmt(&self, w: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(w, "{}", self.n) } else { write!(w, "{}/{}", self.n, self.d) }
    }
}
fn bits(v: usize, n: usize) -> Vec<u8> { (0..n).rev().map(|i| ((v >> i) & 1) as u8).collect() }
fn urn(past: &[u8], colour: u8) -> Q {
    let s: i128 = past.iter().map(|&c| c as i128).sum();
    let red = q(1 + s, past.len() as i128 + 2);
    if colour == 1 { red } else { q(red.d - red.n, red.d) }
}
fn sticky(past: &[u8], colour: u8, stay: Q, switch: Q) -> Q {
    if past.is_empty() { return q(1, 2); }
    if colour == past[past.len() - 1] { stay } else { switch }
}
// P_{n+1}(x, y) = P_n(x) * kernel(x, y); laws[n-1] is P_n, indexed by pattern
fn laws(kernel: &dyn Fn(&[u8], u8) -> Q, n: usize) -> Vec<Vec<Q>> {
    let mut out: Vec<Vec<Q>> = Vec::new();
    let mut law = vec![q(1, 1)];
    for m in 0..n {
        let mut next = vec![q(0, 1); law.len() * 2];
        for (v, &p) in law.iter().enumerate() {
            for y in 0..2u8 { next[2 * v + y as usize] = p.mul(kernel(&bits(v, m), y)); }
        }
        out.push(next.clone());
        law = next;
    }
    out
}
fn word(v: usize, n: usize) -> String { bits(v, n).iter().map(|&c| if c == 1 { 'R' } else { 'B' }).collect() }
fn pw(x: f64, k: usize) -> f64 { let mut o = 1.0; for _ in 0..k { o *= x; } o }
fn simpson(f: &dyn Fn(f64) -> f64, m: usize) -> f64 {
    let h = 1.0 / m as f64;
    let mut t = 0.0;
    for i in 1..m { t += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(i as f64 * h); }
    (f(0.0) + f(1.0) + t) * h / 3.0
}
fn consistent(l: &Vec<Vec<Q>>) -> bool {
    (1..l.len()).all(|n| (0..l[n - 1].len()).all(|v| l[n][2 * v].add(l[n][2 * v + 1]) == l[n - 1][v]))
}
struct Rng { s: u64 }
impl Rng {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn urn_run(&mut self, n: usize) -> usize {
        let mut reds = 0;
        for i in 0..n { if self.uniform() < (1 + reds) as f64 / (i + 2) as f64 { reds += 1; } }
        reds
    }
}
fn main() {
    // ---- road 1: kernels composed, exact ----
    let p = laws(&urn, 10);
    println!("urn kernel after R:   P(R) = {}, P(B) = {}", urn(&[1], 1), urn(&[1], 0));
    println!("urn kernel after R,R: P(R) = {}, P(B) = {}", urn(&[1, 1], 1), urn(&[1, 1], 0));
    let rrr = p[2][7];
    println!("P(R, R, R) = 1/2 x 2/3 x 3/4 = {} = {:.6}", rrr, rrr.f());
    assert!(rrr == q(1, 2).mul(q(2, 3)).mul(q(3, 4)));
    let mut pasts = vec!["start".to_string() + " " + &urn(&[], 1).to_string()];
    for n in 1..3usize {
        for v in (0..1usize << n).rev() { pasts.push(format!("{} {}", word(v, n), urn(&bits(v, n), 1))); }
    }
    println!("tree, P(next R) after each past: {}", pasts.join(", "));
    let tree: Vec<String> = (0..8).rev().map(|v| format!("{} {}", word(v, 3), p[2][v])).collect();
    println!("tree, three draws: {}", tree.join(", "));
    println!("consistency at R,R: P(RRR) + P(RRB) = {} + {} = {} = P(RR)", rrr, p[2][6], rrr.add(p[2][6]));
    assert!(consistent(&p));
    for law in &p { assert!(law.iter().fold(q(0, 1), |a, &b| a.add(b)) == q(1, 1)); }
    println!("urn laws consistent for n = 1 to 10: yes; total of every law = 1");
    for &n in &[3usize, 10] {
        let counts: Vec<Q> = (0..=n).map(|k| (0..1usize << n).filter(|v| v.count_ones() as usize == k)
            .fold(q(0, 1), |a, v| a.add(p[n - 1][v]))).collect();
        assert!(counts.iter().all(|&c| c == q(1, n as i128 + 1)));
        println!("number of reds in {} draws: each of 0..{} has chance {}", n, n, counts[0]);
    }
    println!("order does not matter: P(RRB) = {}, P(RBR) = {}, P(BRR) = {}", p[2][6], p[2][5], p[2][3]);
    let h1r = urn(&[1], 1).mul(urn(&[1, 1], 1));
    let h0 = urn(&[], 1).mul(h1r).add(urn(&[], 0).mul(q(0, 1)));
    println!("proof's h for event RRR: h1(R) = {}, h1(B) = 0, h0 = 1/2 x {} = {}", h1r, h1r, h0);
    assert!(h0 == rrr);
    let s = laws(&|x: &[u8], y: u8| sticky(x, y, q(4, 5), q(1, 5)), 10);
    assert!(consistent(&s));
    let hhh = s[2][7];
    println!("sticky coin: P(H, H, H) = 0.5 x 0.8 x 0.8 = {:.2}; consistent to n = 10: yes", hhh.f());
    assert!(hhh == q(8, 25));
    // ---- road 2: a uniform share p, then independent draws with chance p ----
    let mut worst: f64 = 0.0;
    for n in 1..9usize {
        for v in 0..1usize << n {
            let k = v.count_ones() as usize;
            let val = simpson(&|x: f64| pw(x, k) * pw(1.0 - x, n - k), 1000);
            worst = worst.max((val - p[n - 1][v].f()).abs());
        }
    }
    assert!(worst < 1e-9);
    println!("all 510 patterns of 1 to 8 draws: kernel product = integral of p^k (1-p)^(n-k); largest gap {:.0e}", worst);
    println!("integral of p^3 over 0..1 = {:.6}", simpson(&|x: f64| pw(x, 3), 1000));
    // ---- what breaks ----
    let indep = q(1, 8);
    println!("draws treated as independent halves: P(RRR) = {:.6}, not {:.6}", indep.f(), rrr.f());
    let b = laws(&|x: &[u8], y: u8| sticky(x, y, q(4, 5), q(3, 10)), 3);
    let total = b[2].iter().fold(q(0, 1), |a, &c| a.add(c));
    println!("kernel weights 0.8 + 0.3 = 1.1: P_2(HH) = {:.2}, P_3 summed over toss 3 = {:.2}, total of P_3 = {:.2}",
        b[1][3].f(), b[2][7].add(b[2][6]).f(), total.f());
    assert!(b[2][7].add(b[2][6]) != b[1][3]);
    let mk = laws(&|x: &[u8], y: u8| urn(&x[x.len().saturating_sub(1)..], y), 3)[2][7];   // "Markov" misreading: last draw only
    println!("kernel that sees only the last draw: P(RRR) = 1/2 x 2/3 x 2/3 = {:.6}, not {:.6}", mk.f(), rrr.f());
    assert!(mk != rrr);
    let mut cnt = vec![q(1, 1)];                       // the kernel composed on the count of reds, 100 draws
    for n in 0..100usize {
        let mut nxt = vec![q(0, 1); n + 2];
        for (r, &pr) in cnt.iter().enumerate() {
            let past: Vec<u8> = (0..n).map(|i| (i < r) as u8).collect();
            for y in 0..2u8 { nxt[r + y as usize] = nxt[r + y as usize].add(pr.mul(urn(&past, y))); }
        }
        cnt = nxt;
    }
    let urn25 = cnt[..26].iter().fold(q(0, 1), |a, &b| a.add(b));
    assert!(urn25 == q(26, 101));                      // Step 6: each count from 0 to 100 has chance 1/101
    let (mut c, mut num) = (1i128, 0i128);
    for k in 0..26i128 { num += c; c = c * (100 - k) / (k + 1); }
    println!("at most 25 reds in 100 draws: urn {} = {:.6}, the kernel composed 100 times; fair coin {:.2} x 10^-7", urn25, urn25.f(), num as f64 / (1i128 << 100) as f64 * 1e7);
    assert!(num * 1_000_000 < (1i128 << 100));
    // ---- road 3: the draws built from uniform numbers ----
    let mut r = Rng { s: 20261123 };
    let runs = 200000usize;
    let hits = (0..runs).filter(|_| r.urn_run(3) == 3).count();
    let (est, se) = (hits as f64 / runs as f64, (0.25f64 * 0.75 / runs as f64).sqrt());
    println!("simulated urn, {} runs: P(RRR) = {:.6}; exact 0.250000; standard error {:.6}", runs, est, se);
    assert!((est - 0.25).abs() < 4.0 * se);
    let long_runs = 20000usize;
    let low = (0..long_runs).filter(|_| r.urn_run(100) <= 25).count();
    let est2 = low as f64 / long_runs as f64;
    let se2 = (urn25.f() * (1.0 - urn25.f()) / long_runs as f64).sqrt();
    println!("simulated urn, {} runs of 100 draws: P(at most 25 reds) = {:.6}; exact {:.6}; standard error {:.6}",
        long_runs, est2, urn25.f(), se2);
    assert!((est2 - urn25.f()).abs() < 4.0 * se2);
    let mut hh = 0usize;
    for _ in 0..runs {
        let t1 = r.uniform() < 0.5;
        let t2 = if r.uniform() < 0.8 { t1 } else { !t1 };
        let t3 = if r.uniform() < 0.8 { t2 } else { !t2 };
        if t1 && t2 && t3 { hh += 1; }
    }
    let (est3, se3) = (hh as f64 / runs as f64, (0.32f64 * 0.68 / runs as f64).sqrt());
    println!("simulated sticky coin, {} runs: P(HHH) = {:.6}; exact 0.320000; standard error {:.6}", runs, est3, se3);
    assert!((est3 - 0.32).abs() < 4.0 * se3);
    println!("ALL CHECKS PASS");
}
