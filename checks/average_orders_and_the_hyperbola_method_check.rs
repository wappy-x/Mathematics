// Average orders and the hyperbola method -- the same check as the Python, in Rust.  No crates.
// D(x) = tau(1) + ... + tau(x) counts the lattice points (a, b) with a*b <= x.  Three roads to D(10^6):
// a divisor sieve, the column sum of floor(x/d), and Dirichlet's hyperbola cut at sqrt(x).  Then the
// formula x log x + (2 gamma - 1) x, its error against the proved bound 2 sqrt(x) + 5, and the totient.
fn isqrt(x: u64) -> u64 { // largest m with m*m <= x
    let mut m = (x as f64).sqrt() as u64;
    while m * m > x { m -= 1; }
    while (m + 1) * (m + 1) <= x { m += 1; }
    m
}
fn column_sum(x: u64) -> u64 { (1..=x).map(|d| x / d).sum() } // road 2: column d holds floor(x/d) points
fn hyperbola(x: u64) -> u64 { // road 3: columns d <= m, rows b <= m, minus the m-by-m square
    let m = isqrt(x);
    2 * (1..=m).map(|d| x / d).sum::<u64>() - m * m
}
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn main() {
    let n = 1_000_000usize;
    let mut tau = vec![0u64; n + 1]; // road 1: tau(m) = number of divisors, by a sieve
    for d in 1..=n { let mut m = d; while m <= n { tau[m] += 1; m += d; } }
    let mut phi: Vec<u64> = (0..=n as u64).collect(); // Euler's totient by a sieve over the primes
    for p in 2..=n {
        if phi[p] == p as u64 { let mut m = p; while m <= n { phi[m] -= phi[m] / p as u64; m += p; } }
    }
    let mut dd = vec![0u64; n + 1]; // D[x] = tau(1) + ... + tau(x)
    for x in 1..=n { dd[x] = dd[x - 1] + tau[x]; }
    let k = 10000u64; // Euler's constant from H(n) - log n with Euler-Maclaurin terms
    let mut hk = 0.0f64;
    for j in 1..=k { hk += 1.0 / j as f64; }
    let kf = k as f64;
    let g = hk - kf.ln() - 1.0 / (2.0 * kf) + 1.0 / (12.0 * kf * kf);
    let c = 2.0 * g - 1.0;
    let predicted = |x: f64| x * x.ln() + c * x;
    let nf = n as f64;
    let nu = n as u64;
    let cols: Vec<u64> = (1..=10).map(|d| 10 / d).collect();
    let cs: Vec<String> = cols.iter().map(|v| v.to_string()).collect();
    println!("x = 10, columns floor(10/d): [{}], total {}; hyperbola 2 x ({} + {} + {}) - 3 x 3 = {}", cs.join(", "), cols.iter().sum::<u64>(), cols[0], cols[1], cols[2], hyperbola(10));
    println!("x = 10: average {:.4}; log 10 = {:.4}, log 10 + 2 gamma - 1 = {:.4}", dd[10] as f64 / 10.0, 10f64.ln(), 10f64.ln() + c);
    println!("chart, columns floor(10/d) as bars; hyperbola 10/d: {}", (1..=10).map(|d| format!("{:.2}", 10.0 / d as f64)).collect::<Vec<_>>().join(", "));
    println!("Euler's constant gamma {:.10}, 2 gamma - 1 = {:.10}", g, c);
    let h: u64 = (1..=1000u64).map(|d| nu / d).sum();
    println!("x = 10^6: sieve {}, column sum {}, hyperbola 2 x {} - 1000 x 1000 = {}", dd[n], column_sum(nu), h, hyperbola(nu));
    println!("x = 10^6: average {:.6}; x log x {:.2}, (2 gamma - 1) x {:.2}, predicted {:.2}", dd[n] as f64 / nf, nf * nf.ln(), c * nf, predicted(nf));
    let dl = dd[n] as f64 - predicted(nf);
    println!("x = 10^6: error Delta = {:.2}, sqrt x = {:.0}, Delta / sqrt x = {:.4}, bound 2 sqrt x + 5 = {:.0}", dl, nf.sqrt(), dl / nf.sqrt(), 2.0 * nf.sqrt() + 5.0);
    println!("x | D(x) | average | log x + 2 gamma - 1 | ratio D/predicted | Delta | Delta/sqrt x");
    let xs = [10usize, 100, 1000, 10000, 100000, 1000000];
    for &x in &xs {
        let xf = x as f64;
        let dl = dd[x] as f64 - predicted(xf);
        println!("{} | {} | {:.4} | {:.4} | {:.6} | {:.2} | {:.4}", x, dd[x], dd[x] as f64 / xf, xf.ln() + c, dd[x] as f64 / predicted(xf), dl, dl / xf.sqrt());
    }
    let line = |f: &dyn Fn(usize) -> f64| xs.iter().map(|&x| format!("{:.2}", f(x))).collect::<Vec<_>>().join(", ");
    println!("chart, average D(x)/x: {}", line(&|x| dd[x] as f64 / x as f64));
    println!("chart, log x + 2 gamma - 1: {}", line(&|x| (x as f64).ln() + c));
    println!("chart, log x alone: {}", line(&|x| (x as f64).ln()));
    let (mut worst, mut wx, mut ok) = (0.0f64, 0usize, true);
    for x in 1..=n {
        let xf = x as f64;
        let dl = dd[x] as f64 - predicted(xf);
        ok = ok && dl.abs() < 2.0 * xf.sqrt() + 5.0;
        if dl.abs() / xf.sqrt() > worst { worst = dl.abs() / xf.sqrt(); wx = x; }
    }
    println!("every x up to 10^6: |Delta| < 2 sqrt x + 5 is {}; largest |Delta|/sqrt x = {:.4}, at x = {}", if ok { "True" } else { "False" }, worst, wx);
    let (mut kk, mut f, mut e) = (720720u64, Vec::new(), 1u64); // 720720 by trial division, then tau from the exponents
    for p in 2..14u64 {
        let mut a = 0;
        while kk % p == 0 { kk /= p; a += 1; }
        if a > 0 { f.push(format!("{}^{}", p, a)); e *= a + 1; }
    }
    println!("720720 = {}: tau by exponents {}, by sieve {}, largest tau up to 10^6 {}", f.join(" "), e, tau[720720], tau.iter().max().unwrap());
    let mx = *tau.iter().max().unwrap();
    let top: Vec<usize> = (1..=n).filter(|&m| tau[m] == mx).collect();
    println!("numbers up to 10^6 with {} divisors: {}: {}", mx, top.len(), top.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(", "));
    let mut srt: Vec<u64> = tau[1..].to_vec();
    srt.sort();
    let few = tau[1..].iter().filter(|&&v| v < 14).count();
    println!("median tau up to 10^6: {}; numbers with fewer than 14 divisors: {} ({:.1} percent)", srt[n / 2 - 1], few, 100.0 * few as f64 / nf);
    println!("mistake, count columns and rows but not the square: {}", 2 * h);
    let mut hh = 0.0f64;
    for d in 1..=n { hh += 1.0 / d as f64; }
    let over = nf * hh - dd[n] as f64;
    println!("mistake, drop the floors: H(10^6) = {:.4}, x H(x) = {:.2}, over by {:.2} = {:.4} x; 1 - gamma = {:.4}", hh, nf * hh, over, over / nf, 1.0 - g);
    let short = dd[n] as f64 - nf * nf.ln();
    println!("mistake, average log x alone: {:.4}, total {:.2}, short by {:.2} = {:.1} sqrt x", nf.ln(), nf * nf.ln(), short, short / nf.sqrt());
    let p1000: u64 = phi[1..=1000].iter().sum();
    let mut cop = 0u64;
    for a in 1..=1000u64 { for b in 1..=1000u64 { if gcd(a, b) == 1 { cop += 1; } } }
    let pi2 = std::f64::consts::PI * std::f64::consts::PI;
    println!("totient: phi(1) + ... + phi(1000) = {}, 3 x^2 / pi^2 = {:.2}; 2 x {} - 1 = {}; coprime pairs by gcd {}", p1000, 3e6 / pi2, p1000, 2 * p1000 - 1, cop);
    let pn: u64 = phi[1..].iter().sum();
    let main_t = 3e12 / pi2;
    let bound = nf * nf.ln() + 1.5 * nf;
    println!("totient: Phi(10^6) = {}, 3 x^2 / pi^2 = {:.2}, difference {:.2}, proved bound x log x + 1.5x = {:.2}", pn, main_t, pn as f64 - main_t, bound);
    let mut avg = 0.0f64;
    for m in 1..=n { avg += phi[m] as f64 / m as f64; }
    println!("totient: average phi(n)/n up to 10^6 {:.6}, 6/pi^2 {:.6}", avg / nf, 6.0 / pi2);
    assert!(dd[n] == column_sum(nu) && dd[n] == hyperbola(nu) && (1..=2000).all(|x| dd[x] == hyperbola(x as u64))); // three roads agree
    assert!(ok && worst < 2.0); // Dirichlet's root-x error bound holds at every x up to 10^6
    assert!((g - 0.5772156649).abs() < 1e-9 && (dd[n] as f64 / nf - (nf.ln() + c)).abs() < (2.0 * nf.sqrt() + 5.0) / nf); // the average
    assert!(e == tau[720720] && e == 240 && top[0] == 720720 && 2 * p1000 - 1 == cop && (pn as f64 - main_t).abs() < bound); // 720720; totient
    println!("ALL CHECKS PASS");
}
