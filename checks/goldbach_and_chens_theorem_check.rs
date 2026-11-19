// Goldbach and Chen's theorem -- the same check as the Python, in Rust.  No
// crates.  Every prime, count and constant is computed here.  Roads to each
// answer: a smallest-factor sieve against a Miller-Rabin test written out;
// direct counts against the circle-method integral; counts against the
// Hardy-Littlewood and Vinogradov predictions.
use std::f64::consts::PI;

struct Sieve { spf: Vec<usize>, p: Vec<usize> }

impl Sieve {
    fn is_p(&self, m: usize) -> bool { m > 1 && self.spf[m] == m }
    fn factors(&self, mut m: usize) -> Vec<usize> {      // prime factors, with repeats
        let mut out = Vec::new();
        while m > 1 { out.push(self.spf[m]); m /= self.spf[m]; }
        out
    }
    fn pairs(&self, n: usize) -> Vec<usize> {             // smaller prime p of each p + q = n
        self.p.iter().copied().take_while(|&p| p <= n / 2).filter(|&p| self.is_p(n - p)).collect()
    }
    fn pi(&self, x: usize) -> usize { self.p.iter().filter(|&&p| p <= x).count() }
}

fn pow_mod(mut a: u128, mut e: u128, m: u128) -> u128 {
    let mut r = 1u128;
    a %= m;
    while e > 0 {
        if e & 1 == 1 { r = r * a % m; }
        a = a * a % m;
        e >>= 1;
    }
    r
}

fn miller_rabin(m: u128) -> bool {                        // road two; bases 2, 3, 5, 7 are exact below 3.2e9
    for a in [2u128, 3, 5, 7] { if m % a == 0 { return m == a; } }
    let (mut d, mut s) = (m - 1, 0);
    while d % 2 == 0 { d /= 2; s += 1; }
    'base: for a in [2u128, 3, 5, 7] {
        let mut x = pow_mod(a, d, m);
        if x == 1 || x == m - 1 { continue; }
        for _ in 0..s - 1 {
            x = x * x % m;
            if x == m - 1 { continue 'base; }
        }
        return false;
    }
    m > 1
}

fn j_int(n: f64) -> f64 {                                   // Simpson's rule for the integral
    let steps = 2_000_000;
    let (a, h) = (2.0, (n - 4.0) / steps as f64);
    let f = |t: f64| 1.0 / (t.ln() * (n - t).ln());
    let mut s = f(a) + f(n - 2.0);
    for i in 1..steps { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}

fn circle(sv: &Sieve, n: usize, k: i32) -> (f64, f64) {   // (1/M) sum of F(a)^k e(-n a) over a = j/M
    let m = 4096usize;
    let ps: Vec<usize> = sv.p.iter().copied().filter(|&p| p <= n).collect();
    let (mut tot, mut sq) = (0.0, 0.0);
    for j in 0..m {
        let re: f64 = ps.iter().map(|&p| (2.0 * PI * p as f64 * j as f64 / m as f64).cos()).sum();
        let im: f64 = ps.iter().map(|&p| (2.0 * PI * p as f64 * j as f64 / m as f64).sin()).sum();
        let (mut zr, mut zi) = (1.0, 0.0);
        for _ in 0..k { let t = zr * re - zi * im; zi = zr * im + zi * re; zr = t; }
        let ang = 2.0 * PI * n as f64 * j as f64 / m as f64;
        let (cr, ci) = (ang.cos(), -ang.sin());
        tot += zr * cr - zi * ci;
        sq += re * re + im * im;
    }
    (tot / m as f64, sq / m as f64)
}

fn main() {
    let big = 1_000_002usize;
    let mut spf: Vec<usize> = (0..=big).collect();
    for i in 2..1001 {
        if spf[i] == i { let mut k = i * i; while k <= big { if spf[k] == k { spf[k] = i; } k += i; } }
    }
    let p: Vec<usize> = (2..=big).filter(|&m| spf[m] == m).collect();
    let sv = Sieve { spf, p };
    let c2: f64 = sv.p[1..].iter().fold(1.0, |c, &q| c * (1.0 - 1.0 / ((q - 1) as f64).powi(2)));
    let sing = |n: usize| {
        let mut f = sv.factors(n);
        f.dedup();
        f.iter().filter(|&&q| q > 2).fold(2.0 * c2, |s, &q| s * (q - 1) as f64 / (q - 2) as f64)
    };
    let n = 1_000_000usize;
    let h: Vec<String> = sv.pairs(100)[..4].iter().map(|q| format!("{} + {}", q, 100 - q)).collect();
    println!("100 = {} (4 of {})", h.join(" = "), sv.pairs(100).len());
    let r = sv.pairs(n);
    let r_mr = (2..=n / 2).filter(|&q| miller_rabin(q as u128) && miller_rabin((n - q) as u128)).count();
    println!("primes up to 1000000: {}", sv.pi(n));
    println!("R(1000000) = {} by the sieve, {} by Miller-Rabin; smallest pair {} + {}", r.len(), r_mr, r[0], n - r[0]);
    let (mut worst, mut at, mut ok) = (0, 0, true);
    for m in (4..=n).step_by(2) {
        match sv.p.iter().copied().find(|&q| sv.is_p(m - q)) {
            None => { ok = false; break; }
            Some(q) => if q > worst { worst = q; at = m; },
        }
    }
    println!("every even n from 4 to 1000000 has a pair: {}; largest smallest prime {}, at n = {}", if ok { "yes" } else { "no" }, worst, at);
    let w = sv.pairs(999998)[0];
    println!("so every odd N from 7 to 1000003 is three primes; 1000001 = 3 + {} + {}", w, 999998 - w);
    println!("twin-prime constant C2, primes to a million: {:.6}", c2);
    println!("n | factors | sing(n) | R(n) | sing n/(2 log^2 n) | sing J/2 | R/(sing J/2)");
    let mut hl = std::collections::HashMap::new();
    for m in [100usize, 1000, 10000, 100000, 1000000, 999998, 1000002] {
        let pred = sing(m) * j_int(m as f64) / 2.0;
        let rm = sv.pairs(m).len();
        hl.insert(m, rm as f64 / pred);
        println!("{} | {:?} | {:.4} | {} | {:.1} | {:.1} | {:.4}", m, sv.factors(m), sing(m), rm,
                 sing(m) * m as f64 / (m as f64).ln().powi(2) / 2.0, pred, hl[&m]);
    }
    let l = (n as f64).ln();
    println!("by hand, n = 1000000: log n = {:.4}, squared {:.3}, n over that {:.1}; sing = 2 x {:.6} x 4/3 = {:.6}; half the product {:.1}",
             l, l * l, n as f64 / (l * l), c2, sing(n), sing(n) * n as f64 / (l * l) / 2.0);
    println!("N | sing3(N) | ordered triples | sum log p log q log r | sing3 N^2/2 | ratio");
    let mut vin: Vec<(usize, f64)> = Vec::new();
    for t in [1001usize, 10001, 100001] {
        let s3 = sv.p.iter().fold(1.0, |s, &q| {
            let d = (q - 1) as f64;
            if t % q == 0 { s * (1.0 - 1.0 / d.powi(2)) } else { s * (1.0 + 1.0 / d.powi(3)) }
        });
        let ps: Vec<usize> = sv.p.iter().copied().filter(|&q| q < t).collect();
        let (mut cnt, mut wt) = (0usize, 0.0f64);
        for &a in &ps {
            for &b in &ps {
                if a + b + 2 > t { break; }
                let c = t - a - b;
                if sv.is_p(c) { cnt += 1; wt += (a as f64).ln() * (b as f64).ln() * (c as f64).ln(); }
            }
        }
        let main = s3 * (t * t) as f64 / 2.0;
        vin.push((cnt, wt / main));
        println!("{} | {:.4} | {} | {:.0} | {:.0} | {:.4}", t, s3, cnt, wt, main, wt / main);
    }
    let (cp, pars) = circle(&sv, 1000, 2);
    let (ct, _) = circle(&sv, 1001, 3);
    println!("circle method, 4096 points: ordered pairs of 1000 = {:.3}, ordered triples of 1001 = {:.3}, mean |F|^2 = {:.3}", cp, ct, pars);
    let chen = sv.p.iter().filter(|&&q| q <= n - 2 && sv.factors(n - q).len() <= 2).count();
    let twin_chen = sv.p.iter().filter(|&&q| q < n && sv.factors(q + 2).len() <= 2).count();
    let twins = sv.p.iter().filter(|&&q| q < n && sv.is_p(q + 2)).count();
    println!("Chen: p from 2 to n - 2 with n - p prime or two primes: {}, of which {} have n - p prime", chen, 2 * r.len());
    println!("Chen's twin form: p below a million with p + 2 prime or two primes: {}, of which {} are twins", twin_chen, twins);
    println!("mistake 1, two primes for odd 1000001: {} ways, since 999999 = {:?}", sv.pairs(1000001).len(), sv.factors(999999));
    println!("mistake 2, no local factor: predicts {:.1} for 999998 and {:.1} for 1000002; true {} and {}",
             c2 * j_int(999998.0), c2 * j_int(1000002.0), sv.pairs(999998).len(), sv.pairs(1000002).len());
    println!("mistake 3, Chen read as Goldbach: {} against {} ordered prime pairs", chen, 2 * r.len());
    println!("mistake 4, two primes in Vinogradov's budget: error room {} against {} ordered pairs", sv.pi(n), 2 * r.len());
    assert!(r.len() == r_mr && r_mr == 5402);                                     // sieve against Miller-Rabin
    assert!(cp.round() as usize == 2 * sv.pairs(1000).len() && ct.round() as usize == vin[0].0);
    assert!(pars.round() as usize == sv.pi(1000));                                 // Parseval: mean |F|^2 is pi(1000)
    assert!((hl[&1000000] - 1.0).abs() < 0.01 && (hl[&999998] - 1.0).abs() < 0.01 && (hl[&1000002] - 1.0).abs() < 0.01);
    assert!(vin[0].1 < vin[1].1 && vin[1].1 < vin[2].1 && vin[2].1 < 1.0 && vin[2].1 > 0.98);
    assert!(ok && miller_rabin(w as u128) && miller_rabin((999998 - w) as u128) && chen > 2 * r.len() && twin_chen > twins);
    println!("ALL CHECKS PASS");
}
