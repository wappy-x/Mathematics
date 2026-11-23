// Landau's four problems, the status card -- the same check as landau_problems_check.py,
// in Rust.  No crates.  One sieve of Eratosthenes to 1,000,003 gives the counts; trial
// division, the gap argument and an algebraic identity reach each count a second way.
fn by_division(n: usize) -> bool {                // road two: trial division
    let mut d = 2;
    while d * d <= n && n % d != 0 { d += 1; }
    n > 1 && d * d > n
}
fn factor(mut n: usize) -> Vec<usize> {
    let (mut out, mut d) = (vec![], 2);
    while d * d <= n {
        while n % d == 0 { out.push(d); n /= d; }
        d += 1;
    }
    if n > 1 { out.push(n); }
    out
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
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn main() {
    const X: usize = 1_000_003;                   // the first prime past 10^6
    let mut flag = vec![true; X + 1];
    flag[0] = false; flag[1] = false;
    for p in 2..1001 {
        if flag[p] { let mut k = p * p; while k <= X { flag[k] = false; k += p; } }
    }
    let primes: Vec<usize> = (2..=X).filter(|&p| flag[p]).collect();
    let between = |a: usize, b: usize| -> Vec<usize> { (a + 1..b).filter(|&m| flag[m]).collect() };
    // The example: Legendre at n = 100, between 10,000 and 10,201
    let inside = between(10000, 10201);
    println!("primes between 10000 and 10201: {}; first {}, last {}", inside.len(), inside[0], inside[inside.len() - 1]);
    for m in (10001..10007).step_by(2) {
        let f: Vec<String> = factor(m).iter().map(|x| x.to_string()).collect();
        println!("{} = {}", m, f.join(" x "));
    }
    let small: Vec<usize> = primes.iter().cloned().filter(|&p| p < 101).collect();
    let rems: Vec<usize> = small.iter().map(|&p| 10007 % p).collect();
    println!("10007 by the {} primes up to 97: smallest remainder {}; 101 x 101 = {}", small.len(), rems.iter().min().unwrap(), 101 * 101);
    let expect: f64 = (10001..10201).map(|m| 1.0 / (m as f64).ln()).sum();
    println!("expected count, sum of 1/log m from 10001 to 10200: {:.1}", expect);
    for n in 96..105usize {
        let c = between(n * n, (n + 1) * (n + 1)).len();
        println!("bar n = {:>3} {:>6} to {:>6} {} {}", n, n * n, (n + 1) * (n + 1), "#".repeat(c), c);
    }
    // Legendre for n = 1 to 999: road one counts directly, road two is the gap argument
    let direct = (1..1000).all(|n| !between(n * n, (n + 1) * (n + 1)).is_empty());
    let gap = primes.windows(2).filter(|w| w[0] < 1_000_000).map(|w| (w[1] - w[0], w[0])).max().unwrap();
    let start = (gap.0 - 3) / 2 + 1;              // a failure at n needs a gap >= 2n + 3
    let hold = (1..start).all(|n| (n * n + 1..(n + 1) * (n + 1)).any(by_division));
    println!("Legendre n = 1 to 999 counted directly: {}; largest gap below 10^6: {} after {}", tf(direct), gap.0, commas(gap.1 as u64));
    println!("gap argument: n >= {} needs a gap >= {}, none below 10^6; n = 1 to {} by trial division: {}", start, 2 * start + 3, start - 1, tf(hold));
    println!("at n = 100 a failure needs a gap of at least {}", 2 * 100 + 3);
    println!("quoted gap record 1476 below 4e18: n >= {} safe up to n + 1 = {}", (1476 - 3) / 2 + 1, commas((4e18f64).sqrt() as u64));
    println!("0.525 window equals 2 sqrt x at x = 2^40 = {}", commas(1u64 << 40));
    println!("Ingham 1937: exponent 5/8 = {:.3} < 2/3 = {:.3}, enough for cubes; squares need 1/2 = {:.3}", 5.0 / 8.0, 2.0 / 3.0, 1.0 / 2.0);
    println!("quoted record, by year published: Goldbach checked to 4e18 (2014); bounded gaps 70000000 (2014), 600 (2015), 246 (2014)");
    // What Legendre does not say: Bertrand (proved) and Oppermann (stronger, open)
    println!("Bertrand, between 100 and 200: {} primes", between(100, 200).len());
    let (lo, hi) = (between(10000, 10100), between(10100, 10201));
    let opp = (2..1000).all(|n| !between(n * n, n * n + n).is_empty() && !between(n * n + n, (n + 1) * (n + 1)).is_empty());
    println!("Oppermann at n = 100: {} below 10100, {} above; both halves hold for n = 2 to 999: {}", lo.len(), hi.len(), tf(opp));
    println!("boundary cases: primes between 1 and 2: {}; whole numbers between 0 and 1: {}", between(1, 2).len(), (1..1).count());
    // Goldbach: 10,000 as p + q, two roads; every even m from 4 to 10^6
    let pairs: Vec<usize> = primes.iter().cloned().filter(|&p| p <= 5000 && flag[10000 - p]).collect();
    let pairs2: Vec<usize> = (2..5001).filter(|&p| by_division(p) && by_division(10000 - p)).collect();
    let worst = (4..=1_000_000).step_by(2).map(|m: usize| (*primes.iter().find(|&&p| flag[m - p]).unwrap(), m)).max().unwrap();
    println!("10000 = p + q with p <= q: {} ways by sieve, {} by division; smallest {} + {}", pairs.len(), pairs2.len(), pairs[0], 10000 - pairs[0]);
    println!("Goldbach for every even m from 4 to 1,000,000: yes; hardest m = {} needs p = {}", commas(worst.1 as u64), worst.0);
    // Twin primes in the example interval, and below 10^6
    let tw: Vec<usize> = inside.iter().cloned().filter(|&p| flag[p + 2] && p + 2 < 10201).collect();
    let tw2: Vec<usize> = (10001..10199).step_by(2).filter(|&p| by_division(p) && by_division(p + 2)).collect();
    let twins = primes.iter().filter(|&&p| p + 2 < 1_000_000 && flag[p + 2]).count();
    let shown: Vec<String> = tw.iter().map(|p| format!("({}, {})", p, p + 2)).collect();
    println!("twin pairs inside 10000 to 10201: {}; by division {}", shown.join(", "), tw2.len());
    println!("twin pairs below 10^6: {}", commas(twins as u64));
    // n^2 + 1: the example's first number is 100^2 + 1
    let f1 = factor(10001);
    let hits: Vec<usize> = (1..1001).filter(|&n| flag[n * n + 1]).collect();
    let hits2: Vec<usize> = (1..1001).filter(|&n| by_division(n * n + 1)).collect();
    println!("100^2 + 1 = 10001 = {} x {}; remainders on division by 4: {}, {}", f1[0], f1[1], f1[0] % 4, f1[1] % 4);
    println!("n^2 + 1 prime for n = 1 to 1000: {} by sieve, {} by division; last {}", hits.len(), hits2.len(), hits[hits.len() - 1]);
    let sq: Vec<usize> = (1..1001).filter(|&n| flag[n * n - 1]).collect();
    println!("n^2 - 1 = (n - 1)(n + 1) prime for n = 1 to 1000: {}, at n = {}", sq.len(), sq[0]);
    println!("largest prime factor of 10001: {}; 100^1.279 = {:.0}", f1.iter().max().unwrap(), 100f64.powf(1.279));
    assert!(inside[0] == 10007 && inside.iter().all(|&m| by_division(m)) && !(10001..10007).any(by_division));
    assert!(inside.len() == (10001..10201).filter(|&m| by_division(m)).count() && !rems.contains(&0));
    assert!(direct && hold && gap == (114, 492113) && opp && between(1, 2).is_empty());
    assert!(2 * start + 1 <= gap.0 && gap.0 < 2 * start + 3);   // start is the first n the gap table clears
    assert!(pairs == pairs2 && worst == (523, 503222) && twins == 8169);
    assert!(tw == tw2 && tw[0] == 10007 && tw.len() == 5);
    assert!(hits == hits2 && hits.len() == 112 && sq == vec![2] && f1 == vec![73, 137]);
    println!("ALL CHECKS PASS");
}
