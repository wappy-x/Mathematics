// Four squares and beyond -- the check behind the card.  std only, no crates.
// Road 1 searches: fewest squares for every n to 100,000, fewest cubes to 10,000.
// Road 2 runs Lagrange's proof as an algorithm (pigeonhole, descent, Euler's
// identity) and builds four squares for every n to 10,000.  Road 3 is Legendre's
// test 4^e(8t+7).  Euler's identity is checked on every quadruple from -1 to 2.
type Q = [i64; 4];

fn euler(a: Q, b: Q) -> Q { // right side of Euler's four-square identity
    [a[0] * b[0] + a[1] * b[1] + a[2] * b[2] + a[3] * b[3],
     a[0] * b[1] - a[1] * b[0] + a[2] * b[3] - a[3] * b[2],
     a[0] * b[2] - a[1] * b[3] - a[2] * b[0] + a[3] * b[1],
     a[0] * b[3] + a[1] * b[2] - a[2] * b[1] - a[3] * b[0]]
}
fn sq(q: &[i64]) -> i64 { q.iter().map(|x| x * x).sum() }
fn join(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn show(q: &[i64]) -> String { format!("({})", join(q)) }
fn list(v: &[i64]) -> String { format!("[{}]", join(v)) }
fn commas(n: usize) -> String {
    let s = n.to_string();
    s.chars().enumerate().map(|(i, c)| if i > 0 && (s.len() - i) % 3 == 0 { format!(",{}", c) } else { c.to_string() }).collect()
}

fn prime_rep(p: i64, log: &mut Vec<String>) -> Q { // road 2: four squares for a prime p
    if p == 2 { return [1, 1, 0, 0]; }
    let mut seen = std::collections::HashMap::new();
    for v in 0..(p + 1) / 2 { seen.insert((-1 - v * v).rem_euclid(p), v); }
    let u = (0..(p + 1) / 2).find(|u| seen.contains_key(&(u * u % p))).unwrap();
    let mut q: Q = [u, seen[&(u * u % p)], 1, 0]; // pigeonhole: u^2 + v^2 + 1 = m p
    let mut m = sq(&q) / p;
    while m > 1 {
        if m % 2 == 0 { // pair equal parities, then halve
            let mut s = q;
            s.sort_by_key(|x| x.rem_euclid(2));
            let new = [(s[0] + s[1]) / 2, (s[0] - s[1]) / 2, (s[2] + s[3]) / 2, (s[2] - s[3]) / 2];
            log.push(format!("m = {} at {} = {} x {}: halve to {}", m, show(&q), m, p, show(&new)));
            (q, m) = (new, m / 2);
        } else { // nearest remainders, multiply, divide by m
            let y = q.map(|x| (x + m / 2).rem_euclid(m) - m / 2);
            let r = sq(&y) / m;
            let (mix, new) = (euler(q, y), euler(q, y).map(|z| z / m));
            log.push(format!("m = {} at {} = {} x {}: remainders {} = {} x {}, mixtures {} = {}, / {} = {}",
                m, show(&q), m, p, show(&y), m, r, show(&mix), sq(&mix), m, show(&new)));
            (q, m) = (new, r);
        }
    }
    q
}

fn lowest_count(n_max: usize, powers: &[usize]) -> Vec<usize> { // road 1: dynamic programming
    let mut f = vec![0; n_max + 1];
    for n in 1..=n_max {
        f[n] = 1 + powers.iter().filter(|&&c| c <= n).map(|&c| f[n - c]).min().unwrap();
    }
    f
}

fn legendre(mut n: usize) -> bool { // road 3: n = 4^e (8t + 7)?
    while n % 4 == 0 { n /= 4; }
    n % 8 == 7
}

fn main() {
    let (n_all, nb, nc) = (100_000usize, 10_000usize, 10_000usize);
    println!("-- 7 and three squares --");
    let small: Vec<i64> = (0..3).map(|i| i * i).collect();
    let mut reach: Vec<i64> = (0..27).map(|c| small[c % 3] + small[c / 3 % 3] + small[c / 9]).collect();
    reach.sort(); reach.dedup();
    println!("squares up to 7: {}; three of them reach {}", list(&small), list(&reach));
    assert!(!reach.contains(&7));
    let mut m8: Vec<i64> = (0..8).map(|x| x * x % 8).collect();
    m8.sort(); m8.dedup();
    println!("7 mod 8 = {}; squares mod 8 are {}", 7 % 8, list(&m8));
    let fewest = lowest_count(n_all, &(1..400usize).map(|b| b * b).filter(|&c| c <= n_all).collect::<Vec<_>>()); // no cap at four
    println!("-- fewest squares, n = 1 to {} (search) --", commas(n_all));
    for k in 1..=5 { println!("need {}: {}", k, commas(fewest[1..].iter().filter(|&&f| f == k).count())); }
    assert!(*fewest.iter().max().unwrap() == 4); // nothing up to n_all needs five or more
    let four: Vec<usize> = (1..=n_all).filter(|&n| fewest[n] == 4).collect();
    let leg: Vec<usize> = (1..=n_all).filter(|&n| legendre(n)).collect();
    assert!(four == leg);
    println!("need four = numbers of the form 4^e(8t+7): {}", if four == leg { "True" } else { "False" });
    let not7: Vec<&usize> = four.iter().filter(|&&n| n % 8 != 7).collect();
    println!("need four but not 7 mod 8: {}, first {}", commas(not7.len()), not7[0]);
    for mm in [1_000usize, 10_000, 100_000] {
        let c = four.iter().filter(|&&n| n <= mm).count();
        println!("share needing four up to {}: {} = {:.6} (1/6 = {:.6})", commas(mm), commas(c),
            c as f64 / mm as f64, 1.0 / 6.0);
    }
    assert!((four.len() as f64 / n_all as f64 - 1.0 / 6.0).abs() < 0.001);
    let mut r4 = vec![0usize; 101]; // r4(n): ways to write n as four squares, n <= 100
    for s in (0..21i64.pow(4)).map(|c| sq(&[c % 21 - 10, c / 21 % 21 - 10, c / 441 % 21 - 10, c / 9261 - 10]) as usize) {
        if s <= 100 { r4[s] += 1; } // every (a, b, c, d) from -10 to 10
    }
    let jac: Vec<usize> = (0..=100usize).map(|n| 8 * (1..=n).filter(|d| n % d == 0 && d % 4 != 0).sum::<usize>()).collect();
    assert!(r4[1..] == jac[1..]); // Jacobi: 8 x (sum of divisors not divisible by 4)
    let agree = if r4[1..] == jac[1..] { "True" } else { "False" };
    println!("r4(7) by search {}, by Jacobi 8 x {} = {}; agree for n = 1 to 100: {}", r4[7], jac[7] / 8, jac[7], agree);
    println!("-- Lagrange's proof run as an algorithm --");
    for p in [7i64, 23] {
        let mut log = vec![];
        let q = prime_rep(p, &mut log);
        println!("p = {}: {}; {} sums to {}", p, log.join("; "), show(&q), sq(&q));
        assert!(sq(&q) == p);
    }
    let mut spf: Vec<usize> = (0..=nb).collect();
    for i in (2..).take_while(|i| i * i <= nb) {
        if spf[i] == i { for j in (i * i..=nb).step_by(i) { if spf[j] == j { spf[j] = i; } } }
    }
    let (mut reps, mut steps) = (std::collections::HashMap::new(), 0);
    for p in (2..=nb).filter(|&i| spf[i] == i) {
        let mut log = vec![];
        reps.insert(p, prime_rep(p as i64, &mut log));
        steps = steps.max(log.len());
    }
    let mut built = 0;
    for n in 1..=nb {
        let (mut q, mut k): (Q, usize) = ([1, 0, 0, 0], n);
        while k > 1 { q = euler(q, reps[&spf[k]]); k /= spf[k]; }
        assert!(sq(&q) == n as i64);
        built += 1;
    }
    println!("four squares built and summed for n = 1 to {}: {}; primes {}; most descent steps {}",
        commas(nb), commas(built), commas(reps.len()), steps);
    let mut bad = 0;
    for code in 0..4u32.pow(8) {
        let v: Vec<i64> = (0..8).map(|i| ((code >> (2 * i)) & 3) as i64 - 1).collect();
        let (a, b): (Q, Q) = ([v[0], v[1], v[2], v[3]], [v[4], v[5], v[6], v[7]]);
        if sq(&euler(a, b)) != sq(&a) * sq(&b) { bad += 1; }
    }
    assert!(bad == 0);
    println!("Euler's identity on all {} pairs of quadruples from -1 to 2: failures {}", commas(4usize.pow(8)), bad);
    let (a, w): (Q, Q) = ([2, 1, 1, 1], [1, 1, 1, 0]);
    let e = euler(a, w);
    let flip = [e[0], a[0] * w[1] + a[1] * w[0] + a[2] * w[3] - a[3] * w[2], e[2], e[3]];
    println!("7 x 3: {} sums to {}; one sign flipped {} sums to {}", show(&e), sq(&e), show(&flip), sq(&flip));
    let plain = [2i64, 8, 1, 0].map(|x| x % 3);
    println!("descent with plain remainders at p = 23, m = 3: {} = 3 x {}, no smaller m", show(&plain), sq(&plain) / 3);
    println!("-- fewest cubes, n = 1 to {} (search) --", commas(nc));
    let cubes: Vec<usize> = (1..100usize).map(|b| b * b * b).filter(|&c| c <= nc).collect();
    let fc = lowest_count(nc, &cubes);
    let parts: Vec<String> = (1..10).map(|k| format!("{}: {}", k, commas(fc[1..].iter().filter(|&&f| f == k).count()))).collect();
    println!("need {}", parts.join(", "));
    let nine: Vec<i64> = (1..=nc).filter(|&n| fc[n] == 9).map(|n| n as i64).collect();
    let eight: Vec<usize> = (1..=nc).filter(|&n| fc[n] == 8).collect();
    assert!(nine == vec![23, 239] && *eight.iter().max().unwrap() == 454);
    println!("need nine: {}; need eight: {}, largest {}; 23 = 8 + 8 + 7 x 1", list(&nine), eight.len(), eight.iter().max().unwrap());
    let mut c9: Vec<i64> = (0..9).map(|b| b * b * b % 9).collect();
    c9.sort(); c9.dedup();
    let hit: Vec<i64> = (0..27).map(|c| (c9[c % 3] + c9[c / 3 % 3] + c9[c / 9]) % 9).collect();
    let miss: Vec<i64> = (0..9).filter(|r| !hit.contains(r)).collect();
    println!("cubes mod 9: {}; three of them miss {}", list(&c9), list(&miss));
    let mut signed = vec![];
    for x in -3i64..4 { for y in x..4 { for z in y..4 { for t in z..4 {
        if x.pow(3) + y.pow(3) + z.pow(3) + t.pow(3) == 23 { signed.push(show(&[x, y, z, t])); }
    } } } }
    println!("23 with negative cubes allowed, four cubes from -3 to 3: [{}]", signed.join(", "));
    println!("-- Waring: the lower bound witness n = 2^k floor(1.5^k) - 1 --");
    for k in 2u32..7 {
        let q = 3usize.pow(k) / 2usize.pow(k);
        let (n, g) = (2usize.pow(k) * q - 1, 2usize.pow(k) + q - 2);
        let pw: Vec<usize> = (1..=n).map(|b| b.pow(k)).take_while(|&c| c <= n).collect();
        let f = lowest_count(n, &pw)[n];
        println!("k = {}: n = {}, fewest by search {}, 2^k + floor(1.5^k) - 2 = {}", k, n, f, g);
        assert!(f == g);
    }
    let pw = |b: u128, k: u32| b.checked_pow(k).unwrap();
    let ok = (2u32..81).filter(|&k| pw(3, k) % pw(2, k) + pw(3, k) / pw(2, k) <= pw(2, k)).count();
    assert!(ok == 79);
    println!("condition for g(k) = 2^k + floor(1.5^k) - 2 holds for k = 2 to 80: {} of 79", ok);
    println!("ALL CHECKS PASS");
}
