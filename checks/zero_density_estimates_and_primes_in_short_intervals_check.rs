// Zero-density estimates and primes in short intervals -- the check behind the card.
// std only.  Roads: exact exponent algebra in fractions; the density envelopes
// scanned on a grid; primes counted by a sieve and again by trial division.
use std::cmp::Ordering;

#[derive(Clone, Copy, PartialEq, Debug)]
struct Q { n: i128, d: i128 }                                // a reduced fraction n/d, d > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d) * if d < 0 { -1 } else { 1 };
    Q { n: n / g, d: d / g }
}
impl Q {
    fn add(self, o: Q) -> Q { q(self.n * o.d + o.n * self.d, self.d * o.d) }
    fn sub(self, o: Q) -> Q { q(self.n * o.d - o.n * self.d, self.d * o.d) }
    fn mul(self, o: Q) -> Q { q(self.n * o.n, self.d * o.d) }
    fn div(self, o: Q) -> Q { q(self.n * o.d, self.d * o.n) }
    fn cmp(self, o: Q) -> Ordering { (self.n * o.d).cmp(&(o.n * self.d)) }
    fn min(self, o: Q) -> Q { if self.cmp(o) == Ordering::Greater { o } else { self } }
    fn f(self) -> f64 { self.n as f64 / self.d as f64 }
    fn s(self) -> String { if self.d == 1 { format!("{}", self.n) } else { format!("{}/{}", self.n, self.d) } }
}
fn int(n: i128) -> Q { q(n, 1) }
fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}
fn is_prime_td(n: usize) -> bool {                           // trial division, no sieve
    if n < 2 { return false; }
    let mut d = 2;
    while d * d <= n { if n % d == 0 { return false; } d += 1; }
    true
}
fn huxley(s: Q) -> Q { int(3).div(int(2).sub(s)).min(int(3).div(int(3).mul(s).sub(int(1)))) }
fn guth_maynard(s: Q) -> Q { int(3).div(int(2).sub(s)).min(int(15).div(int(3).add(int(5).mul(s)))) }

fn main() {
    const X: usize = 1_000_000;
    const LIM: usize = X + 40000;
    const BIG: usize = 100_000_000;                          // the cube-root windows are followed this far
    let mut ok = vec![true; BIG + 1];                        // Eratosthenes up to BIG
    ok[0] = false; ok[1] = false;
    let mut i = 2;
    while i * i <= BIG {
        if ok[i] { let mut j = i * i; while j <= BIG { ok[j] = false; j += i; } }
        i += 1;
    }
    let mut pi = vec![0usize; LIM + 1];                      // pi[n] = primes up to n
    for n in 1..=LIM { pi[n] = pi[n - 1] + ok[n] as usize; }
    let count = |y: usize, h: usize| pi[y + h] - pi[y];      // primes in (y, y + h]
    println!("house: primes below a million = {}", pi[X]);
    assert_eq!(pi[X], 78498);

    // Road 1: the density envelopes, scanned on a grid of sigma, in exact fractions.
    let envs: [(&str, fn(Q) -> Q, Q); 2] = [("Huxley", huxley, q(3, 4)), ("Guth-Maynard", guth_maynard, q(7, 10))];
    for (name, env, s_star) in envs {
        let mut best = q(500, 1000);
        for k in 500..=1000 { let s = q(k, 1000); if env(s).cmp(env(best)) == Ordering::Greater { best = s; } }
        println!("envelope {}: max over sigma at {} = {} (crossing solved: {})", name, best.s(), env(best).s(), s_star.s());
        assert!(best == s_star);
    }
    assert!(huxley(q(3, 4)) == q(12, 5) && guth_maynard(q(7, 10)) == q(30, 13));
    let ing40 = |s: Q| int(3).div(int(2).sub(s));            // Ingham 1940 against Ingham 1937's flat 8/3
    let cross = (500..=1000).map(|k| q(k, 1000)).filter(|&s| ing40(s).cmp(q(8, 3)) != Ordering::Greater).last().unwrap();
    println!("envelope Ingham 1940: 3/(2 - sigma) is {} at sigma = 1, at most 8/3 up to sigma = {} (solved: {})", ing40(int(1)).s(), cross.s(), int(2).sub(q(9, 8)).s());
    assert!(cross == int(2).sub(q(9, 8)));

    // Road 2: theta = 1 - 1/A for every interval, 1 - 2/A for almost every interval.
    let rows = [("Carlson 1921", int(4)), ("Ingham 1937", q(8, 3)), ("Huxley 1972", q(12, 5)),
                ("Guth-Maynard", q(30, 13)), ("density hyp.", int(2))];
    let quoted = [(q(8, 3), q(5, 8)), (q(12, 5), q(7, 12)), (q(30, 13), q(17, 30))]; // as stated by the papers
    let quoted_aa = [(q(12, 5), q(1, 6)), (q(30, 13), q(2, 15))];
    println!("x = 10^6, log x = {:.4}", (X as f64).ln());
    let r4 = (X as f64).ln().powf(0.25);
    println!("error shape exp(-(log x)^(1/4)) at 10^6 = exp(-{:.3}) = {:.4}", r4, (-r4).exp());
    println!("name          A      theta  almost-all   x^theta      h  primes  h/log x    diff  ratio  psi-gain/h");
    let mut bars = Vec::new();
    for (name, a) in rows {
        let th = int(1).sub(int(1).div(a));
        let aa = int(1).sub(int(2).div(a));
        for (qa, qe) in quoted { if a == qa { assert!(th == qe); } }          // theta against the papers
        for (qa, qaa) in quoted_aa { if a == qa { assert!(aa == qaa); } }
        let h = (X as f64).powf(th.f()).floor() as usize;
        let c = count(X, h);
        let c_td = (X + 1..=X + h).filter(|&n| is_prime_td(n)).count();
        assert_eq!(c, c_td);                                 // sieve against trial division
        let mut gain = 0.0f64;
        for n in X + 1..=X + h { if ok[n] { gain += (n as f64).ln(); } }
        let pred = h as f64 / (X as f64).ln();
        println!("{:13} {:6} {:6} {:10} {:9.2} {:>6}  {:6}  {:7.1}  {:6.1}  {:.3}  {:.4}", name, a.s(), th.s(), aa.s(),
                 (X as f64).powf(th.f()), commas(h as u64), c, pred, c as f64 - pred, c as f64 / pred, gain / h as f64);
        bars.push((name, h));
    }
    for &(name, h) in &bars[1..] {                           // one # per 200 integers
        let n = (h as f64 / 200.0).round() as usize;
        println!("bar {:13} {:29} x^theta = {}", name, "#".repeat(n), commas(h as u64));
    }

    // Evidence across [10^5, 10^6]: every interval (y, y + y^theta] for two exponents.
    for (th, label) in [(q(7, 12), "7/12"), (q(1, 3), "1/3")] {
        let (mut lo, mut hi, mut arg_lo, mut empty) = (9.0f64, 0.0f64, 0usize, 0usize);
        for y in 100_000..=X {
            let h = (y as f64).powf(th.f()).floor() as usize;
            let r = count(y, h) as f64 / (h as f64 / (y as f64).ln());
            if r < lo { lo = r; arg_lo = y; }
            hi = hi.max(r);
            if count(y, h) == 0 { empty += 1; }
        }
        println!("scan theta={}: worst ratio {:.4} at y={}, best {:.4}, empty intervals {}", label, lo,
                 commas(arg_lo as u64), hi, commas(empty as u64));
        if th == q(7, 12) { assert!(empty == 0 && lo > 0.75); } else { assert!(empty > 0); }
    }

    // What breaks 1: the largest prime gap below a million, against theta = 1/3.
    let ps: Vec<usize> = (2..=X).filter(|&n| ok[n]).collect();
    let (mut g, mut p) = (0usize, 0usize);
    for k in 0..ps.len() - 1 { let d = ps[k + 1] - ps[k]; if d > g || (d == g && ps[k] > p) { g = d; p = ps[k]; } }
    let h = (p as f64).powf(1.0 / 3.0).floor() as usize;
    println!("breaks: gap {} after {}; (p, p + {}] holds {} primes, predicted {:.2}", g, commas(p as u64), h,
             count(p, h), h as f64 / (p as f64).ln());
    assert!(g == 114 && p == 492113 && count(p, h) == 0);
    let (mut last, mut prev) = ((0usize, 0usize, 0usize), 2usize); // the last empty (p, p + p^(1/3)] below BIG
    for p in (3..=BIG).filter(|&n| ok[n]) {
        let h = (prev as f64).powf(1.0 / 3.0).floor() as usize;
        if p - prev > h { last = (prev, p - prev, h); }
        prev = p;
    }
    println!("breaks: below 10^8 the last empty (p, p + p^(1/3)] is at p = {}: gap {} against a window of {}", commas(last.0 as u64), last.1, last.2);
    assert!(last.0 == 2010733 && last.1 == 148);             // a record gap in the maximal-gap tables

    // What breaks 2: read the almost-all exponent 1/6 as 'every interval'. Count times size as a power of x,
    // T = x^(1 - theta): one window (T^A/x)^(1-sigma), Step 0, k = 1; averaged over x (T^A/x^2)^(1-sigma), Step 7, k = 2.
    let a = q(12, 5);
    let cs = |th: Q, k: i128| a.mul(int(1).sub(th)).sub(int(k));
    println!("breaks: count x size, A=12/5, as a power of x: one window x^{} at theta=7/12, x^{} at theta=1/6; averaged over x, x^{} at theta=1/6",
             cs(int(1).sub(int(1).div(a)), 1).s(), cs(q(1, 6), 1).s(), cs(q(1, 6), 2).s());
    assert!(cs(q(1, 6), 1).cmp(int(0)) == Ordering::Greater && cs(q(1, 6), 2).cmp(int(0)) != Ordering::Greater);
    let (mut bad, mut model, mut hmin, mut hmax) = (0usize, 0.0f64, usize::MAX, 0usize); // windows shorter than the mean gap
    for y in 100_000..=X {
        let h = (y as f64).powf(1.0 / 6.0).floor() as usize;
        hmin = hmin.min(h); hmax = hmax.max(h);
        if count(y, h) == 0 { bad += 1; }
        model += (1.0 - 1.0 / (y as f64).ln()).powf(h as f64); // each integer prime with chance 1/log y
    }
    println!("breaks: theta=1/6, widths {} to {}, mean gap log y {:.4} to {:.4}; empty {} of 900,001 = {:.4}, random model {:.4}",
             hmin, hmax, (100_000f64).ln(), (X as f64).ln(), commas(bad as u64), bad as f64 / 900001.0, model / 900001.0);
    assert!((bad as f64 - model).abs() < 0.1 * 900001.0);

    // What breaks 3: no density bound. Up to T = x/h every zero may add up to 2h.
    let t = X as f64 / 3162.0;
    let tp = 2.0 * std::f64::consts::PI;
    let nt = t / tp * (t / tp).ln() - t / tp + 7.0 / 8.0;
    println!("breaks: no density bound, T = {:.1}, smooth N(T) = {:.1}, error bound {:.0} times h", t, nt, 2.0 * nt);

    // What breaks 4: classical zero-free region only, width 1/(5.558691 log T).
    let kappa = int(1).sub(q(12, 5).mul(q(3, 8)));          // A = 12/5, theta = 5/8
    let saving = (-kappa.f() / 5.558691 / (3.0 / 8.0)).exp();
    println!("breaks: classical region, A=12/5, theta=5/8, kappa={}, saving factor {:.4} at every x", kappa.s(), saving);
    assert!(kappa == q(1, 10) && 0.9 < saving && saving < 1.0);
    println!("quoted, not computed: classical region width 1/(5.558691 log t); zeros on the line to 3 x 10^12;");
    println!("quoted, not computed: first zero 1/2 + 14.134725i; Ingham uses |zeta(1/2 + it)| << t^(1/6 + eps)");
    println!("quoted, not computed: a prime in every [x - x^0.525, x] (Baker-Harman-Pintz 2001)");
    println!("ALL CHECKS PASS");
}
