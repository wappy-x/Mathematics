// Twin primes and bounded gaps -- the same check as twin_primes_and_bounded_gaps_check.py, in Rust.
// No crates.  Road 1: a sieve counts twin pairs below a million; a segmented sieve counts them near
// a billion and is tested against the plain sieve; trial division checks the example.  Road 2: the
// Hardy-Littlewood prediction as an integral by Simpson's rule and as a direct sum.  Road 3: the
// twin constant as a product over primes and from counted remainders.
fn segment(s: &[bool], a: usize, w: usize) -> Vec<bool> { // primality flags for a, a+1, ..., a+w+1
    let mut seg = vec![true; w + 2];
    let mut p = 2;
    while p * p <= a + w + 1 {
        if s[p] { let mut m = (p * p).max((a + p - 1) / p * p); while m <= a + w + 1 { seg[m - a] = false; m += p; } }
        p += 1;
    }
    for k in 0..2usize.saturating_sub(a) { seg[k] = false; }
    seg
}
fn by_division(n: usize) -> bool { let mut d = 2; while d * d <= n && n % d != 0 { d += 1; } d * d > n }
fn li2(a: f64, b: f64, n: usize) -> f64 { // integral of dt / (log t)^2, Simpson in u = log t
    let (u0, h) = (a.ln(), (b.ln() - a.ln()) / n as f64);
    let f = |u: f64| u.exp() / (u * u);
    let mut acc = f(u0) + f(u0 + n as f64 * h);
    for k in 1..n { acc += if k % 2 == 1 { 4.0 } else { 2.0 } * f(u0 + k as f64 * h); }
    h / 3.0 * acc
}
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    const L: usize = 1_000_010;
    let mut s = vec![true; L + 1]; s[0] = false; s[1] = false;
    let mut i = 2;
    while i * i <= L { if s[i] { let mut m = i * i; while m <= L { s[m] = false; m += i; } } i += 1; }
    let ps: Vec<usize> = (2..1_000_000).filter(|&p| s[p]).collect();
    let mut cum = vec![0usize; L + 1]; let mut c = 0; // cum[x] = twin pairs p, p + 2 with p <= x
    for x in 0..=L { if x + 2 <= L && s[x] && s[x + 2] { c += 1; } cum[x] = c; }
    let (gap, at) = ps.windows(2).map(|w| (w[1] - w[0], w[0])).fold((0, 0), |b, x| if x.0 > b.0 { x } else { b });
    let m6 = 1_000_000usize;
    println!("primes below 1,000,000: {}; twin pairs p, p+2 with p <= 1,000,000: {}", ps.len(), cum[m6]);
    println!("widest gap below 1,000,000: {}, after {}", gap, at);
    let low = segment(&s, 0, m6);
    assert!((0..=m6).filter(|&i| low[i] && low[i + 2]).count() == cum[m6]);
    println!("segmented sieve on 0..1,000,000 agrees with the plain sieve: {} twin pairs", cum[m6]);
    let (a, w) = (1_000_000_000usize, 1_000_000usize);
    let seg = segment(&s, a, w);
    let first = a + (0..w).find(|&i| seg[i] && seg[i + 2]).unwrap();
    let tw = (0..w).filter(|&i| seg[i] && seg[i + 2]).count();
    let pr = (0..w).filter(|&i| seg[i]).count();
    println!("first twin pair from 1,000,000,000 up: {}, {}", first, first + 2);
    println!("trial division: {} prime {}, {} prime {}", first, tf(by_division(first)), first + 2, tf(by_division(first + 2)));
    println!("window 1,000,000,000 to 1,000,999,999: {} primes, {} twin pairs, mean spacing {:.2}", pr, tw, w as f64 / pr as f64);
    let mut c2 = 1.0f64;
    for &p in &ps[1..] { c2 *= 1.0 - 1.0 / ((p - 1) as f64).powi(2); }
    println!("C2 = product over odd primes below 1,000,000 of 1 - 1/(p-1)^2 = {:.6}; 2 C2 = {:.6}", c2, 2.0 * c2);
    println!("local factor: p, both-coprime share counted, independent share, ratio, formula");
    for p in [2usize, 3, 5, 7, 11] {
        let both = (0..p).filter(|&r| r % p != 0 && (r + 2) % p != 0).count();
        let (cnt, ind) = (both as f64 / p as f64, (1.0 - 1.0 / p as f64).powi(2));
        let form = if p == 2 { 2.0 } else { 1.0 - 1.0 / ((p - 1) as f64).powi(2) };
        println!("  p = {}: {}/{} = {:.6}, {:.6}, {:.6}, {:.6}", p, both, p, cnt, ind, cnt / ind, form);
        assert!((cnt / ind - form).abs() < 1e-12);
    }
    let (mut direct, mut tot, mut nxt) = (vec![], 0.0f64, 1000usize);
    for n in 3..=m6 { tot += 2.0 * c2 / (n as f64).ln().powi(2); if n == nxt { direct.push(tot); nxt *= 10; } }
    println!("x, twin pairs counted, 2 C2 Li2(x), direct sum, counted / predicted");
    for (j, x) in [1000usize, 10_000, 100_000, 1_000_000].iter().enumerate() {
        let hl = 2.0 * c2 * li2(2.0, *x as f64, 20000);
        println!("  {}: {}, {:.1}, {:.1}, {:.4}", x, cum[*x], hl, direct[j], cum[*x] as f64 / hl);
        assert!((hl - direct[j]).abs() < 1.2 && (cum[*x] as f64 / hl - 1.0).abs() < 0.25);
    }
    let xs: Vec<usize> = (1..=10).map(|k| k * 100_000).collect();
    println!("chart x (thousands): {:?}", xs.iter().map(|x| x / 1000).collect::<Vec<_>>());
    println!("chart counted: {:?}", xs.iter().map(|&x| cum[x]).collect::<Vec<_>>());
    println!("chart Hardy-Littlewood: {:?}", xs.iter().map(|&x| (2.0 * c2 * li2(2.0, x as f64, 20000)).round() as i64).collect::<Vec<_>>());
    println!("chart no correction: {:?}", xs.iter().map(|&x| li2(2.0, x as f64, 20000).round() as i64).collect::<Vec<_>>());
    let la = (a as f64).ln();
    println!("by hand near 10^9: log = {:.4}, log^2 = {:.2}, 1/log^2 = {:.7}", la, la * la, 1.0 / la.powi(2));
    println!("by hand: x 2 = {:.7}, x C2 = {:.7} = 1 in {:.1}", 2.0 / la.powi(2), 2.0 * c2 / la.powi(2), la.powi(2) / (2.0 * c2));
    let (hand, simp) = (2.0 * c2 * w as f64 / la.powi(2), 2.0 * c2 * li2(a as f64, (a + w) as f64, 20000));
    println!("window prediction: by hand {:.0}, by Simpson {:.0}; counted {}; counted / predicted {:.4}", hand, simp, tw, tw as f64 / simp);
    assert!((hand - simp).abs() < 1.0 && (tw as f64 / simp - 1.0).abs() < 0.05);
    let (naive, crude) = (li2(2.0, 1e6, 20000), 2.0 * c2 * 1e6 / 1e6f64.ln().powi(2));
    let trip_naive: f64 = (3..=m6).map(|n| 1.0 / (n as f64).ln().powi(3)).sum();
    let trip = ps.iter().filter(|&&p| s[p + 2] && s[p + 4]).count();
    println!("mistakes below 10^6: no correction {:.0}; factor 2 only {:.0}; x/(log x)^2 {:.0}", naive, 2.0 * naive, crude);
    println!("triples n, n+2, n+4 all prime below 10^6: coin model {:.0}, counted {}", trip_naive, trip);
    let (cousins, sexy) = (ps.iter().filter(|&&p| s[p + 4]).count(), ps.iter().filter(|&&p| s[p + 6]).count());
    println!("pairs p, p+4 below 10^6: {}; p, p+6: {}; prediction for gap 6 is twice the twin one: {:.0}", cousins, sexy, 2.0 * naive * 2.0 * c2);
    let gaps: Vec<usize> = ps.windows(2).map(|w| w[1] - w[0]).collect();
    let mut ladder = vec![gaps.iter().filter(|&&g| g == 2).count()];
    for b in [6usize, 12, 246] { ladder.push(gaps.iter().filter(|&&g| g <= b).count()); }
    println!("consecutive gaps below 10^6 equal to 2, at most 6, 12, 246: {:?} of {}", ladder, gaps.len());
    assert!(ladder[0] == cum[m6] && ladder[3] == gaps.len());
    let chen = |p: usize| { let m = p + 2; if s[m] { return true; } let mut d = 2; while m % d != 0 { d += 1; } s[m / d] };
    let ch = ps.iter().filter(|&&p| chen(p)).count();
    println!("primes p below 10^6 with p+2 prime or a product of two primes: {} (twins among them {})", ch, cum[m6]);
    println!("quoted, not computed: gap 70,000,000 (2013), 600 (2013), 246 (2014); 12 on EH, 6 on GEH");
    assert!(ps.len() == 78498 && cum[m6] == 8169 && (gap, at) == (114, 492113));
    assert!(first == 1_000_000_007 && by_division(first) && by_division(first + 2) && tw == 3037);
    assert!((2.0 * c2 - 1.3203236316).abs() < 1e-6 && trip == 1 && trip_naive > 100.0);
    assert!(cum[1000] == (2..1001).filter(|&p| by_division(p) && by_division(p + 2)).count());
    assert!(ch == 29949 && (cousins, sexy) == (8144, 16386)); // pin the counts printed above
    println!("ALL CHECKS PASS");
}
