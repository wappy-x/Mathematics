// Kinds of claim -- the same check as the Python, in Rust.  No crates.
// Ten claims get a kind (fixed) and a dated status (moves).  The numbers
// behind them are computed here, each by two roads that share no arithmetic.
use std::f64::consts::PI;

const LIMIT: usize = 1_000_000;
const LEDGER: [(&str, &str, &str, u32, &str); 10] = [ // claim, kind, status, year, backing
    ("central limit theorem", "theorem", "proved", 1901, "Lyapunov's proof"),
    ("four-colour theorem", "conjecture", "proved", 1977, "refereed; formal proof 2005"),
    ("Fermat's last theorem", "conjecture", "proved", 1995, "open 1637 to 1993"),
    ("Poincare conjecture", "conjecture", "proved", 2006, "checked by three teams"),
    ("Goldbach", "conjecture", "open", 2026, "checked to 4e18 in 2014"),
    ("Riemann hypothesis", "conjecture", "proved", 2026, "formal proof certified 2026-11-21"),
    ("Polya: L(n) <= 0 for n >= 2", "conjecture", "refuted", 1958, "Haselgrove; first failure 906150257"),
    ("Black-Scholes call 9.23", "model", "proved", 1973, "inside the model; fit is evidence"),
    ("P(<= 55 heads) ~ Phi(1.1)", "approximation", "proved", 2026, "error computed below"),
    ("pi(1e6) ~ 1e6/ln(1e6)", "approximation", "proved", 2026, "error computed below"),
];

fn timeline(claim: &str) -> Vec<(u32, &'static str)> {
    if claim == "four-colour" { vec![(1852, "open"), (1879, "proved"), (1890, "open"), (1976, "claimed"), (1977, "proved")] }
    else { vec![(1637, "open"), (1993, "claimed"), (1995, "proved")] }
}

fn status_on(claim: &str, year: u32) -> &'static str { // the latest event on or before the year
    let mut s = "not yet stated";
    for (y, st) in timeline(claim) { if y <= year { s = st } }
    s
}

fn trial_prime(n: usize) -> bool {                    // a third test, by trial division
    n > 1 && (2..).take_while(|d| d * d <= n).all(|d| n % d != 0)
}

fn lam_trial(mut n: usize) -> i64 {                   // the same sign, by factoring n by hand
    let (mut k, mut d) = (0, 2);
    while n > 1 {
        while n % d == 0 { n /= d; k += 1 }
        d += 1;
    }
    if k % 2 == 0 { 1 } else { -1 }
}

fn colourings(k: usize) -> usize {                    // Belgium, France, Germany, Luxembourg, Netherlands
    let edges = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3), (4, 0), (4, 2)];
    let mut total = 0;
    for c in 0..k.pow(5) {
        let col: Vec<usize> = (0..5).map(|i| c / k.pow(i) % k).collect();
        if edges.iter().all(|&(a, b)| col[a] != col[b]) { total += 1 }
    }
    total
}

fn colour_formula(k: i64) -> i64 { k * (k - 1) * (k - 2) * (k - 2) * (k - 3) } // road two

fn phi(z: f64) -> f64 {                               // bell-curve area left of z, by the erf series
    let (mut s, mut term, mut n) = (0.0, z, 0.0);
    while term.abs() > 1e-17 { s += term / (2.0 * n + 1.0); n += 1.0; term *= -z * z / (2.0 * n) }
    0.5 + s / (2.0 * PI).sqrt()
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = 0.0;
    for i in 0..=m {
        let w = if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + i as f64 * h);
    }
    h / 3.0 * s
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let mut sieve = vec![true; LIMIT + 1];           // road A to the primes: Eratosthenes
    sieve[0] = false; sieve[1] = false;
    let mut p = 2;
    while p * p <= LIMIT {
        if sieve[p] { let mut m = p * p; while m <= LIMIT { sieve[m] = false; m += p } }
        p += 1;
    }
    let mut spf: Vec<usize> = (0..=LIMIT).collect(); // road B: smallest prime factor of each n
    let mut p = 2;
    while p * p <= LIMIT {
        if spf[p] == p { let mut m = p * p; while m <= LIMIT { if spf[m] == m { spf[m] = p } m += p } }
        p += 1;
    }
    let primes: Vec<usize> = (2..=LIMIT).filter(|&n| sieve[n]).collect();
    let count_b = (2..=LIMIT).filter(|&n| spf[n] == n).count();
    let mut goldbach_ok = true;                       // every even 4 <= n <= LIMIT, one pair each
    for n in (4..=LIMIT).step_by(2) {
        if !primes.iter().take_while(|&&q| q < n).any(|&q| sieve[n - q]) { goldbach_ok = false }
    }
    let r100 = primes.iter().filter(|&&q| q <= 50 && sieve[100 - q]).count();
    let r100_trial = (2..=50).filter(|&q| trial_prime(q) && trial_prime(100 - q)).count();
    let mut lam = vec![0i64; LIMIT + 1];             // Liouville: -1 to the number of prime factors
    lam[1] = 1;
    for n in 2..=LIMIT { lam[n] = -lam[n / spf[n]] }
    let (mut l, mut worst) = (1i64, -(LIMIT as i64));
    for n in 2..=LIMIT { l += lam[n]; worst = worst.max(l) }
    let lam_agree = (1..=10000).all(|n| lam[n] == lam_trial(n));

    let mut row: Vec<u128> = vec![1];                 // 100 fair flips: Pascal's rule, exact integers
    for _ in 0..100 {
        let mut next = vec![1u128];
        for i in 0..row.len() - 1 { next.push(row[i] + row[i + 1]) }
        next.push(1); row = next;
    }
    let mut prod: Vec<u128> = vec![1];                // road two: C(n,k) = C(n,k-1)(n-k+1)/k
    for k in 1..=100u128 { let c = prod[prod.len() - 1] * (101 - k) / k; prod.push(c) }
    let exact = row[..56].iter().sum::<u128>() as f64 / 2f64.powi(100); let z = (55.5 - 100.0 * 0.5) / (100.0f64 * 0.25).sqrt();
    let bell = |x: f64| (-x * x / 2.0).exp() / (2.0 * PI).sqrt();
    let phi_simpson = 0.5 + simpson(&bell, 0.0, z, 2000);

    let (s, k, r, q, sig, t) = (100.0f64, 100.0f64, 0.05f64, 0.02f64, 0.20f64, 1.0f64);
    let d1 = ((s / k).ln() + (r - q + sig * sig / 2.0) * t) / (sig * t.sqrt());
    let d2 = d1 - sig * t.sqrt();
    let bs = s * (-q * t).exp() * phi(d1) - k * (-r * t).exp() * phi(d2);
    let pay = |x: f64| (s * ((r - q - sig * sig / 2.0) * t + sig * t.sqrt() * x).exp() - k) * bell(x);
    let bs_int = (-r * t).exp() * simpson(&pay, -d2, 10.0, 4000); // road two: average the payoff
    let xlnx = LIMIT as f64 / (LIMIT as f64).ln();

    println!("ledger, status as of 2026-11-23");
    for (name, kind, st, yr, why) in LEDGER.iter() {
        println!("  {:<28} {:<13} {:<8} {}  {}", name, kind, st, yr, why);
    }
    let kinds = ["theorem", "conjecture", "model", "approximation"];
    let stats = ["open", "claimed", "proved", "refuted"];
    println!("grid, kind down, status across:  {}", stats.join("  "));
    for kd in kinds {
        let cells: String = stats.iter()
            .map(|st| format!("{:>9}", LEDGER.iter().filter(|x| x.1 == kd && x.2 == *st).count())).collect();
        println!("  {:<13}{}", kd, cells);
    }
    for (claim, years) in [("four-colour", vec![1860, 1885, 1900, 1976, 2010]), ("Fermat", vec![1900, 1994, 2000])] {
        let parts: Vec<String> = years.iter().map(|&y| format!("{} {}", y, status_on(claim, y))).collect();
        println!("status of {}: {}", claim, parts.join(", "));
    }
    println!("primes below 1e6: Eratosthenes {}, smallest-factor sieve {}", primes.len(), count_b);
    println!("Goldbach, every even n from 4 to 1e6 has a pair: {}; r(100) = {} by sieve, {} by trial division",
             yn(goldbach_ok), r100, r100_trial);
    println!("Polya, largest L(n) for 2 <= n <= 1e6: {}; lambda by sieve = by trial division to 1e4: {}", worst, yn(lam_agree));
    println!("map of 5 neighbours: 3 colours {} ways, 4 colours {} ways; formula {}, {}",
             colourings(3), colourings(4), colour_formula(3), colour_formula(4));
    println!("P(at most 55 heads in 100): exact {:.6}; Pascal = product formula: {}", exact, yn(row == prod));
    println!("  bell with half step, z = (55.5 - 50) / 5 = {:.1}: Phi {:.6}, Simpson {:.6}, error {:.6}", z, phi(z), phi_simpson, (phi(z) - exact).abs());
    println!("  bell without it   Phi(1.0) {:.6}, error {:.6}", phi(1.0), (phi(1.0) - exact).abs());
    println!("Black-Scholes call: formula {:.6}, integral {:.6}", bs, bs_int);
    println!("pi(1e6) = {}; 1e6/ln(1e6) = {:.1}; ratio {:.6}; short by {:.4}",
             primes.len(), xlnx, primes.len() as f64 / xlnx, 1.0 - xlnx / primes.len() as f64);
    println!("log10 of how far each pattern is known to hold:");
    for (label, x) in [("Polya, checked here", LIMIT as f64), ("Polya, first failure", 906150257.0),
                       ("Goldbach, checked here", LIMIT as f64), ("Goldbach, checked 2014", 4e18)] {
        let bar = "#".repeat((2.0 * x.log10()).round() as usize);
        println!("  {:<24} {:<37} {:5.2}", label, bar, x.log10());
    }

    assert!(primes.len() == count_b && count_b == 78498);          // two sieves, the known count
    assert!(goldbach_ok && r100 == r100_trial && r100 == 6);        // checked for n <= 1e6 only
    assert!(worst == 0 && lam_agree);
    assert!(colourings(3) as i64 == colour_formula(3) && colour_formula(3) == 0 && colourings(4) as i64 == colour_formula(4));
    assert!(row == prod && (phi(1.1) - phi_simpson).abs() < 1e-9 && (phi(1.1) - exact).abs() < 1e-4);
    assert!((bs - bs_int).abs() < 1e-6 && (bs - 9.227005508154).abs() < 1e-9);
    assert!(status_on("four-colour", 1885) == "proved" && status_on("four-colour", 1900) == "open");
    let conj: std::collections::BTreeSet<&str> = LEDGER.iter().filter(|x| x.1 == "conjecture").map(|x| x.2).collect();
    assert!(conj.len() == 3);                                       // one kind, three statuses
    println!("ALL CHECKS PASS");
}
