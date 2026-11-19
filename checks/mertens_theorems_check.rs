// Mertens' theorems -- the same check as the Python, in Rust.  No crates.
// A sieve lists the primes to 5,200,000.  Road one adds 1/p, log p / p and
// multiplies 1 - 1/p over them.  Road two finds the constants M and gamma by
// different series and checks the three theorems' predictions against road one.
const LIMIT: usize = 5_200_000;
const X: usize = 1_000_000;

fn com(v: f64, d: usize) -> String {               // thousands commas, d decimals
    let s = format!("{:.*}", d, v);
    let (int, frac) = match s.find('.') { Some(i) => (&s[..i], &s[i..]), None => (&s[..], "") };
    let (sign, digits) = if let Some(r) = int.strip_prefix('-') { ("-", r) } else { ("", int) };
    let mut out = String::new();
    for (i, ch) in digits.chars().enumerate() {
        if i > 0 && (digits.len() - i) % 3 == 0 { out.push(',') }
        out.push(ch);
    }
    format!("{}{}{}", sign, out, frac)
}

fn vp(m: usize, p: usize) -> usize {               // Legendre's formula
    let (mut t, mut q) = (0, p);
    while q <= m { t += m / q; q *= p }
    t
}

fn main() {
    let mut sieve = vec![true; LIMIT + 1];
    sieve[0] = false; sieve[1] = false;
    let mut i = 2;
    while i * i <= LIMIT {
        if sieve[i] { let mut j = i * i; while j <= LIMIT { sieve[j] = false; j += i } }
        i += 1;
    }
    let primes: Vec<usize> = (0..=LIMIT).filter(|&p| sieve[p]).collect();
    let ln = |v: usize| (v as f64).ln();
    let euler_gamma = |nn: usize| {                // gamma = H(n) - log n, refined
        let (mut h, n) = (0.0, nn as f64);
        for k in (1..=nn).rev() { h += 1.0 / k as f64 }
        h - n.ln() - 1.0 / (2.0 * n) + 1.0 / (12.0 * n * n)
    };
    let (gamma, gamma_half, n) = (euler_gamma(X), euler_gamma(X / 2), X as f64);
    let (mut c, mut hh, mut m) = (0.0, 0.0, 0.0);
    for &p in &primes { c += ln(p) / (p * (p - 1)) as f64 }
    for &p in &primes { let q = p as f64; hh += -(1.0 - 1.0 / q).ln() - 1.0 / q }
    for &p in &primes { let q = p as f64; m += (1.0 - 1.0 / q).ln() + 1.0 / q }
    let mm = gamma + m;                            // road two to M
    let eg = (-gamma).exp();
    println!("primes up to {}: {}; gamma from harmonic numbers {:.10} (n = 10^6), {:.10} (n = 500,000)",
             com(LIMIT as f64, 0), com(primes.len() as f64, 0), gamma, gamma_half);
    println!("road two: M = gamma - H = {:.6}; H = {:.6}; c = {:.6}; E = -gamma - c = {:.6}", mm, hh, c, -gamma - c);
    println!("e^-gamma = {:.6}; e^gamma = {:.6}", eg, 1.0 / eg);
    println!("x | pi(x) | sum 1/p | loglog x + M | gap | sum log p/p - log x | product * log x");
    let (mut s1, mut s2, mut pr) = (0.0f64, 0.0f64, 1.0f64);
    let (mut lo1, mut hi1, mut rs, mut r283) = (0.0f64, -9.0f64, 0.0f64, 0.0f64);
    let marks: Vec<usize> = (1..=6).map(|j| 10usize.pow(j)).collect();
    let mut row: Vec<(usize, f64, f64, f64)> = Vec::new();
    let mut cross = 0usize;
    for (i, &p) in primes.iter().enumerate() {
        while row.len() < 6 && p > marks[row.len()] { row.push((i, s1, s2, pr)) }
        let q = p as f64;
        s1 += q.ln() / q; s2 += 1.0 / q; pr *= 1.0 - 1.0 / q;
        let nxt = if i + 1 < primes.len() { primes[i + 1] } else { LIMIT };
        hi1 = hi1.max(s1 - q.ln()); lo1 = lo1.min(s1 - ln(nxt));
        if nxt > 286 {                             // Rosser-Schoenfeld range
            let a = p.max(286);
            rs = rs.max((s2 - ln(a).ln() - mm) * 2.0 * ln(a).powi(2))
                   .max((mm + ln(nxt).ln() - s2) * 2.0 * ln(nxt).powi(2));
        }
        if p == 283 { r283 = (s2 - q.ln().ln() - mm) * 2.0 * q.ln().powi(2) }  // just below the range
        if cross == 0 && s2 > 3.0 { cross = p }
    }
    for (k, &x) in marks.iter().enumerate() {
        let (cnt, a1, a2, ap) = row[k];
        let l = ln(x);
        println!("{:>7} | {:>5} | {:.6} | {:.6} | {:+.6} | {:+.6} | {:.6}", x, cnt, a2, l.ln() + mm, a2 - l.ln() - mm, a1 - l, ap * l);
    }
    let (cnt, a1, a2, ap) = row[5];
    let l = n.ln();
    println!("at 10^6: road one M = sum - loglog x = {:.6}; gap to road two {:+.6}; bound 1/(2 log^2 x) = {:.6}", a2 - l.ln(), a2 - l.ln() - mm, 1.0 / (2.0 * l * l));
    println!("at 10^6: product * log x / e^-gamma = {:.6}; road one M + H = {:.6}, gamma {:.6}", ap * l / eg, a2 - l.ln() + hh, gamma);
    let mut logfact = 0.0;                         // road A to log n!
    for k in 2..=X { logfact += ln(k) }
    let (mut leg, mut theta) = (0.0, 0.0);         // road B to log n!
    for &p in primes.iter().filter(|&&p| p <= X) { leg += vp(X, p) as f64 * ln(p) }
    for &p in primes.iter().filter(|&&p| p <= X) { theta += ln(p) }
    let f10: usize = 2usize.pow(vp(10, 2) as u32) * 3usize.pow(vp(10, 3) as u32) * 5usize.pow(vp(10, 5) as u32) * 7usize.pow(vp(10, 7) as u32);
    println!("10! = 2^{} 3^{} 5^{} 7^{}; check {} = {}", vp(10, 2), vp(10, 3), vp(10, 5), vp(10, 7), f10, (1..=10usize).product::<usize>());
    println!("log(10^6 !): sum of logs {}; by Legendre {}; theta(10^6)/10^6 = {:.6}", com(logfact, 1), com(leg, 1), theta / n);
    println!("step 2 sandwich at 10^6: {:.4} <= sum log p/p = {:.4} <= {:.4} <= {:.4}", l - 1.0 - c, a1, l + theta / n, l + 4f64.ln());
    println!("sum log p/p - log x over 2 <= x <= {}: lowest {:.6}, highest {:.6}", com(LIMIT as f64, 0), lo1, hi1);
    println!("Rosser-Schoenfeld, 286 <= x <= {}: largest gap / (1/(2 log^2 x)) = {:.6}; at x = 283 {:.6}", com(LIMIT as f64, 0), rs, r283);
    let pred3 = (3.0 - mm).exp().exp();
    println!("sum 1/p first passes 3 at p = {}; loglog x + M = 3 predicts {}", com(cross as f64, 0), com(pred3, 0));
    println!("sum 1/p reaches 4 near x = {:.2} x 10^18", (4.0 - mm).exp().exp() / 1e18);
    let mut plus = 1.0;
    for &p in primes.iter().filter(|&&p| p <= X) { plus *= 1.0 + 1.0 / p as f64 }
    let pi = std::f64::consts::PI;
    println!("product of 1 + 1/p to 10^6: {:.4}; (6/pi^2) e^gamma log x = {:.4}", plus, 6.0 / (pi * pi) / eg * l);
    let (mut two, mut kk) = (1.0, 0.0);            // a = -2, primes 3 to 10^6; general rule's constant
    for &p in primes[1..].iter().filter(|&&p| p <= X) { two *= 1.0 - 2.0 / p as f64 }
    for &p in &primes[1..] { let q = p as f64; kk += (1.0 - 2.0 / q).ln() + 2.0 / q }
    let rule = (1.0 - 2.0 * mm + kk).exp();
    println!("product of 1 - 2/p, 3 <= p <= 10^6: {:.9}; times log^2 x {:.6}; rule's constant {:.6}", two, two * l * l, rule);
    let mut survivors = 0usize;
    let mut pz = 1.0;
    for z in [10usize, 100, 1000] {                // numbers <= 10^6 with no prime factor <= z
        let mut left = vec![true; X + 1];
        left[0] = false;
        for &p in primes.iter().take_while(|&&p| p <= z) { let mut j = p; while j <= X { left[j] = false; j += p } }
        let mut prod_z = 1.0;
        for &p in primes.iter().take_while(|&&p| p <= z) { prod_z *= 1.0 - 1.0 / p as f64 }
        survivors = left.iter().filter(|&&b| b).count();
        pz = prod_z;
        println!("no prime factor <= {}: counted {}; 10^6 times product {}; 10^6 e^-gamma / log z {}", z, com(survivors as f64, 0), com(n * prod_z, 1), com(n * eg / ln(z), 1));
    }
    let log_n = 1024.0 * 2f64.ln();
    println!("1024-bit search: 1 in {:.1} prime; survivors of division by primes <= 1000: share {:.4}, 1 in {:.1} prime", log_n, pz, log_n * pz);
    println!("mistake 1, sieve to sqrt(10^6) as independent: {} against {} survivors, ratio {:.4}; x / log x = {}; 2e^-gamma = {:.4}", com(n * pz, 0), com(survivors as f64, 0), n * pz / survivors as f64, com(n / l, 0), 2.0 * eg);
    println!("mistake 2, drop M: loglog 10^6 = {:.4} against {:.4}", l.ln(), a2);
    println!("mistake 3, log(1 - 1/p) taken as -1/p: e^-sum = {:.5} against {:.5}", (-a2).exp(), ap);
    println!("mistake 4, drop e^-gamma: 1/log 10^6 = {:.5} against {:.5}", 1.0 / l, ap);
    println!("by hand: log 10^6 = {:.6}; loglog 10^6 = {:.6}; plus M = {:.6}", l, l.ln(), l.ln() + mm);
    println!("by hand: log x + E = {:.6} against {:.6}; e^-gamma / log x = {:.6} against product {:.6}", l - gamma - c, a1, eg / l, ap);
    let omega: usize = primes.iter().filter(|&&p| p <= X).map(|&p| X / p).sum();  // distinct prime factors, all n
    println!("average count of distinct prime factors, n <= 10^6: {:.6}", omega as f64 / n);
    let c1: Vec<String> = row.iter().map(|r| format!("{:.2}", r.2)).collect();
    let c2: Vec<String> = marks.iter().map(|&x| format!("{:.2}", ln(x).ln() + mm)).collect();
    println!("chart, sum 1/p: {}", c1.join(", "));
    println!("chart, loglog x + M: {}", c2.join(", "));
    assert!(cnt == 78498);                                           // pi(10^6), known table
    assert!((logfact - leg).abs() < 1e-6 * logfact);                 // Legendre = sum of logs
    assert!(l - 1.0 - c <= a1 && a1 <= l + theta / n);               // step 2 sandwich
    assert!(-2.0 < lo1 && hi1 < 2.0);                                // Mertens' own bound
    assert!(((a2 - l.ln()) - mm).abs() < 1.0 / (2.0 * l * l) && rs < 1.0 && 1.0 < r283); // theorem 2
    assert!(((a1 - l) - (-gamma - c)).abs() < 1e-3);                 // theorem 1's constant E
    assert!((gamma - gamma_half).abs() < 1e-11 && (ap * l - eg).abs() < 1e-3 && (cross as f64 / pred3 - 1.0).abs() < 0.01);
    assert!(survivors == 1 + cnt - 168);                             // survivors: 1 and primes > 1000
    assert!((two * l * l - rule).abs() < 1e-3);                      // step 6 rule, a = -2
    println!("ALL CHECKS PASS");
}
