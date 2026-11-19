// Landau's four problems -- the same check as landau_problems_and_legendre_check.py,
// in Rust.  No crates.  One sieve of Eratosthenes to 1,000,003 gives every count;
// each count is reached a second, independent way: trial division, a gap argument,
// a twin sieve on two classes, or a sieve on the values n^2 + 1.
fn by_division(n: u64) -> bool {                  // road two: trial division
    let mut d = 2;
    while d * d <= n && n % d != 0 { d += 1; }
    n > 1 && d * d > n
}
fn commas(n: u64) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, c) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(c);
    }
    out
}
fn join<T: ToString>(v: &[T]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn main() {
    const X: usize = 1_000_003;                  // 1,000,003: the first prime past 10^6
    let mut flag = vec![true; X + 1];
    flag[0] = false; flag[1] = false;
    for p in 2..1001 {
        if flag[p] { let mut k = p * p; while k <= X { flag[k] = false; k += p; } }
    }
    let primes: Vec<usize> = (2..=X).filter(|&p| flag[p]).collect();
    let small: Vec<usize> = primes.iter().cloned().filter(|&p| p <= 1000).collect();
    let ln = |m: usize| (m as f64).ln();
    // Legendre: a prime strictly between n^2 and (n+1)^2, for n = 1 to 999
    let cnt: Vec<usize> = (0..1000).map(|n| (n * n + 1..(n + 1) * (n + 1)).filter(|&m| flag[m]).count()).collect();
    let inside: Vec<usize> = (962..1024).filter(|&m| flag[m]).collect();
    println!("primes between 961 and 1024: {} ({} of them)", join(&inside), inside.len());
    let rems: Vec<usize> = small.iter().filter(|&&p| p <= 31).map(|&p| 967 % p).collect();
    println!("trial division of 967 by 2 to 31: remainders {:?}", rems);
    let facs: Vec<String> = (962..967).map(|m| { let q = *small.iter().find(|&&p| m % p == 0).unwrap(); format!("{} = {} x {}", m, q, m / q) }).collect();
    println!("962 to 966: {}", facs.join(", "));
    let expect: f64 = (962..1024).map(|m| 1.0 / ln(m)).sum();
    println!("n = 31: expected {:.2}; Brun-Titchmarsh ceiling 2y/log y with y = 62: {:.2}", expect, 124.0 / ln(62));
    let low = (1..1000).min_by_key(|&n| (cnt[n], n)).unwrap();
    println!("n = 1 to 999: every interval has a prime: {}; fewest {}, at n = {}; most {}",
             if (1..1000).all(|n| cnt[n] > 0) { "True" } else { "False" }, cnt[low], low, cnt[1..].iter().max().unwrap());
    let gap = primes.windows(2).filter(|w| w[0] < 1_000_000).map(|w| (w[1] - w[0], w[0])).max().unwrap();
    let start = gap.0 / 2 - 1;                     // n >= start: 2n + 3 > largest gap
    println!("largest gap below 10^6: {}, after {}; so n >= {} cannot fail below 10^6", gap.0, commas(gap.1 as u64), start);
    let hold = (1..start as u64).all(|n| (n * n + 1..(n + 1) * (n + 1)).any(by_division));
    println!("n = 1 to {} by trial division: all hold: {}", start - 1, if hold { "True" } else { "False" });
    println!("gap record 1476 below 4 x 10^18 covers n >= {} up to (n+1)^2 = 4 x 10^18, n + 1 = {}",
             1476 / 2 - 1, commas((4e18f64).sqrt() as u64));
    let pts = [31usize, 100, 200, 300, 400, 500, 600, 700, 800, 900, 999];
    println!("chart n: {}", join(&pts));
    println!("chart, primes counted: {}", join(&pts.iter().map(|&n| cnt[n]).collect::<Vec<_>>()));
    let ex: Vec<String> = pts.iter().map(|&n| format!("{:.1}", (n * n + 1..(n + 1) * (n + 1)).map(|m| 1.0 / ln(m)).sum::<f64>())).collect();
    println!("chart, expected: {}", ex.join(", "));
    let bt: Vec<String> = pts.iter().map(|&n| format!("{:.1}", 4.0 * n as f64 / ln(2 * n))).collect();
    println!("chart, Brun-Titchmarsh ceiling: {}", bt.join(", "));
    let win = 10f64.powf(18.0 * 0.525);
    println!("proved window x^0.525 against square gap 2 sqrt x: equal at x = 2^40 = {}; at 10^18: {:.3} x 10^9 against 2.000 x 10^9",
             commas(1u64 << 40), win / 1e9);
    // Twin primes: road one from the sieve, road two sieving n and n + 2 together
    let twins: Vec<usize> = primes.iter().cloned().filter(|&p| p + 2 < 1_000_000 && flag[p + 2]).collect();
    let mut two = vec![true; 1_000_001];
    for &p in &small {
        let mut k = 0; while k <= 1_000_000 { two[k] = false; k += p; }
        let mut k = p - 2; while k <= 1_000_000 { two[k] = false; k += p; }
    }
    let above = (1001..999_999).filter(|&n| two[n]).count();
    let below = twins.iter().filter(|&&p| p < 1000).count();
    let c2 = primes[1..].iter().filter(|&&p| p <= 1_000_000).fold(1.0, |a, &p| a * (1.0 - 1.0 / (((p - 1) * (p - 1)) as f64)));
    let (a, b, nn) = (2f64.ln(), 1e6f64.ln(), 20000);
    let h = (b - a) / nn as f64;
    let f = |u: f64| u.exp() / (u * u);
    let mut inner = 0.0;
    for i in 1..nn { inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    let simp = h / 3.0 * (f(a) + f(b) + inner);
    let brun: f64 = twins.iter().fold(0.0, |s, &p| s + (1.0 / p as f64 + 1.0 / (p + 2) as f64));
    println!("twin pairs below 10^6: {}; twin sieve: {} below 1000 + {} above = {}",
             commas(twins.len() as u64), below, commas(above as u64), commas((below + above) as u64));
    let hl = 2.0 * c2 * simp;
    println!("C2 = {:.6}; Hardy-Littlewood 2 C2 integral of 1/log^2 t: {}; Brun's sum to 10^6: {:.4}",
             c2, commas(format!("{:.0}", hl).parse().unwrap()), brun);
    // Goldbach: the smallest prime p with n - p prime, for every even n to 10^6
    let worst = (4..=1_000_000).step_by(2).map(|n: usize| (*primes.iter().find(|&&p| p <= n / 2 && flag[n - p]).unwrap(), n)).max().unwrap();
    println!("Goldbach, every even n from 4 to 1,000,000 has a pair; the hardest needs p = {}, at n = {}", worst.0, commas(worst.1 as u64));
    // n^2 + 1: road one reads the sieve, road two sieves the values n^2 + 1 directly
    let hits: Vec<usize> = (1..1001).filter(|&n| flag[n * n + 1]).collect();
    let mut val = vec![true; 1001];
    for &p in &small {
        for r in (0..p).filter(|&r| (r * r + 1) % p == 0) {
            let mut n = r; while n <= 1000 { if n * n + 1 != p { val[n] = false; } n += p; }
        }
    }
    let hits2: Vec<usize> = (1..1001).filter(|&n| val[n]).collect();
    let roots = small.iter().filter(|&&p| (0..p).any(|r| (r * r + 1) % p == 0)).count();
    let cpoly = primes[1..].iter().filter(|&&p| p <= 1_000_000)
        .fold(1.0, |a, &p| a * (1.0 - (if p % 4 == 1 { 1.0 } else { -1.0 }) / (p - 1) as f64));
    let pred = cpoly * (1..1001).map(|n| 1.0 / ln(n * n + 1)).sum::<f64>();
    println!("n^2 + 1 prime for n = 1 to 1000: {}; first: {}; by the value sieve: {}", hits.len(), join(&hits[..8]), hits2.len());
    println!("primes up to 1000 that ever divide n^2 + 1: {} of {}; constant C = {:.4}; predicted {:.1}", roots, small.len(), cpoly, pred);
    let bad: Vec<usize> = (1..1000).map(|n| n * n + n + 2).collect();
    println!("n^2 + n + 2 prime for n = 1 to 999: {}; all even: {}", bad.iter().filter(|&&v| flag[v]).count(),
             if bad.iter().all(|v| v % 2 == 0) { "True" } else { "False" });
    assert!(inside[0] == 967 && inside.len() == 10 && inside.iter().all(|&m| by_division(m as u64)));
    assert!((1..1000).all(|n| cnt[n] > 0) && hold && gap == (114, 492113) && primes.iter().filter(|&&p| p < 1_000_000).count() == 78498);
    assert!(twins.len() == 8169 && below + above == 8169 && hl.round() == 8248.0);
    assert!(worst == (523, 503222) && roots == 1 + small.iter().filter(|&&p| p % 4 == 1).count());
    assert!(hits == hits2 && hits.iter().all(|&n| by_division((n * n + 1) as u64)));
    assert!(124.0 / ln(62) > inside.len() as f64 && inside.len() as f64 > expect);
    println!("ALL CHECKS PASS");
}
