// Fermat's last theorem: the descent for n = 4, and Kummer's regular primes.  No crates.
// Search is evidence; the descent is the proof, so the code checks the descent's
// parametrisation two ways and computes the regular primes two ways.
fn gcd(mut a: i64, mut b: i64) -> i64 {
    a = a.abs(); b = b.abs();
    while b != 0 { (a, b) = (b, a % b) }
    a
}

fn isqrt(n: u128) -> u128 {                    // largest r with r^2 <= n
    let mut r = (n as f64).sqrt() as u128;
    while r * r > n { r -= 1 }
    while (r + 1) * (r + 1) <= n { r += 1 }
    r
}

fn sq(n: i128) -> bool { n >= 0 && isqrt(n as u128).pow(2) == n as u128 }

fn root4(n: u128) -> u128 { isqrt(isqrt(n)) }  // largest w with w^4 <= n

fn icbrt(n: u64) -> u64 {                      // largest c with c^3 <= n
    let mut c = (n as f64).cbrt().round() as u64;
    while c * c * c > n { c -= 1 }
    while (c + 1) * (c + 1) * (c + 1) <= n { c += 1 }
    c
}

fn case_for(n: i64) -> i64 {                   // 4 if 4 divides n, else the smallest odd prime factor
    if n % 4 == 0 { return 4 }
    let mut m = n;
    while m % 2 == 0 { m /= 2 }
    (3..=m).find(|d| m % d == 0).unwrap()
}

fn near_miss(a: i64, b: i64) -> (i64, i64, i64) { // the descent run backwards from seeds a > b
    let (x, s, r) = (a * a - b * b, 2 * a * b, a * a + b * b);
    (x, 2 * r * s, r * r + s * s)              // x^4 + Y^2 = z^2
}

fn powmod(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1;
    b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m } b = b * b % m; e >>= 1 }
    r
}

fn irregular_by_bernoulli(p: i64) -> Vec<i64> { // B_0..B_{p-3} mod p by the recurrence
    let (mut bs, mut row, mut hits) = (vec![1i64], vec![1i64, 1], Vec::new());
    for n in 1..(p - 2) {
        let mut next = vec![1i64];
        for k in 1..row.len() { next.push((row[k - 1] + row[k]) % p) }
        next.push(1);
        row = next;
        let s = (0..n as usize).map(|k| row[k] * bs[k] % p).sum::<i64>() % p;
        bs.push((p - s * powmod(n + 1, p - 2, p) % p) % p);
        if n % 2 == 0 && bs[n as usize] == 0 { hits.push(n) }
    }
    hits
}

fn irregular_by_power_sums(p: i64) -> Vec<i64> { // p | B_m iff 1^m + ... + (p-1)^m = 0 mod p^2
    let (q, mut hits) = (p * p, Vec::new());
    let sq_j: Vec<i64> = (0..p).map(|j| j * j % q).collect();
    let mut cur = sq_j.clone();
    let mut m = 2;
    while m < p - 2 {
        if cur[1..].iter().sum::<i64>() % q == 0 { hits.push(m) }
        cur = cur.iter().zip(&sq_j).map(|(c, s)| c * s % q).collect();
        m += 2;
    }
    hits
}

fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }

fn main() {
    let cases: Vec<String> = (3..13).map(|n| format!("{}->{}", n, case_for(n))).collect();
    println!("exponent -> case that covers it: {}", cases.join(" "));
    let n_max: i128 = 1000;
    let (mut fourth, mut cubes, mut trip) = (0, 0, 0);
    for x in 1..=n_max {
        for y in x..=n_max {
            if sq(x.pow(4) + y.pow(4)) { fourth += 1 }
            let s = (x.pow(3) + y.pow(3)) as u64;
            if icbrt(s).pow(3) == s { cubes += 1 }
        }
    }
    for z in 1..=n_max as i64 {
        for x in (1..z).step_by(2) {
            let d = z * z - x * x;
            if d > 0 && sq(d as i128) && gcd(x, z) == 1 { trip += 1 }
        }
    }
    println!("pairs 1 <= x <= y <= {} tested: {}", n_max, n_max * (n_max + 1) / 2);
    println!("x^4 + y^4 a perfect square: {}", fourth);
    println!("x^3 + y^3 a perfect cube: {}", cubes);
    println!("contrast, primitive x^2 + y^2 = z^2 with z <= {}: {}", n_max, trip);
    let zmax: i64 = 10000;
    let mut road_a = Vec::new();
    for x in (1..100i64).step_by(2) {
        for z in (x * x + 1)..=zmax {
            let d = z * z - x.pow(4);
            if sq(d as i128) && gcd(x, z) == 1 { road_a.push((x, isqrt(d as u128) as i64, z)) }
        }
    }
    road_a.sort();
    let mut pieces = Vec::new();
    for a in 2..100i64 {
        for b in 1..a {
            if (a - b) % 2 == 1 && gcd(a, b) == 1 && near_miss(a, b).2 <= zmax { pieces.push((a, b, a * a + b * b)) }
        }
    }
    let mut road_b: Vec<(i64, i64, i64)> = pieces.iter().map(|&(a, b, _)| near_miss(a, b)).collect();
    road_b.sort();
    println!("near misses x^4 + Y^2 = z^2, x odd, primitive, z <= {}: search {}, seeds {}", zmax, road_a.len(), road_b.len());
    let first: Vec<String> = road_a[..3].iter().map(|(x, y, z)| format!("{}^4 + {}^2 = {}^2", x, y, z)).collect();
    println!("first three: {}", first.join(", "));
    let coprime = pieces.iter().all(|&(a, b, c)| gcd(a, b) == 1 && gcd(a, c) == 1 && gcd(b, c) == 1);
    let matched = pieces.iter().all(|&(a, b, c)| near_miss(a, b).1 == 4 * a * b * c);
    println!("Y = 4 a b (a^2 + b^2) in all: {}; pieces pairwise coprime: {}", yn(matched), yn(coprime));
    let all3 = pieces.iter().any(|&(a, b, c)| sq(a as i128) && sq(b as i128) && sq(c as i128));
    println!("Y a square in any: {}; all three pieces squares in any: {}",
             yn(road_a.iter().any(|&(_, y, _)| sq(y as i128))), yn(all3));
    let (x, y, z) = near_miss(4, 1);
    println!("trace from u, v = 2, 1: a, b = 4, 1; x = {}, s = 8, r = 17, Y = 2 r s = {}, z = {}", x, y, z);
    println!("{}^4 + {}^2 = {} + {} = {} = {}^2; Y = 4 x 4 x 1 x 17, a square: {}",
             x, y, x.pow(4), y * y, z * z, z, yn(sq(y as i128)));
    println!("2^4 + 1^4 = {}, a square: {}; would-be w^4 = 17^2 = {} < z = {}", 16 + 1, yn(sq(17)), 17 * 17, z);
    let (mut ladder, mut b) = (vec![10u128.pow(38)], 10u128.pow(38));
    while b >= 2 { b = root4(b - 1); ladder.push(b) }
    let lad: Vec<String> = ladder.iter().map(|v| v.to_string()).collect();
    println!("descent ladder, bound on z: {} (z >= 2 is needed)", lad.join(" -> "));
    println!("9^3 + 10^3 = {} = 12^3 + {} = (9 + 10)(81 - 90 + 100) = 19 x {}", 729 + 1000, 1729 - 1728, 81 - 90 + 100);
    let mut pts = Vec::new();
    for a in -1000..=1000i64 {
        for e in 1..=30i64 {
            if gcd(a, e) == 1 && sq((a.pow(3) - a * e.pow(4)) as i128) { pts.push((a, e)) }
        }
    }
    pts.sort();
    let px: Vec<String> = pts.iter().map(|(a, e)| format!("{}/{}", a, e * e)).collect();
    println!("points on y^2 = x^3 - x, x = a/e^2 with |a| <= 1000, e <= 30: x = {} and y = 0 each", px.join(", "));
    let pmax: i64 = 200; let primes: Vec<i64> = (3..pmax).filter(|&p| (2..).take_while(|d| d * d <= p).all(|d| p % d != 0)).collect();
    let irr_b: Vec<(i64, Vec<i64>)> = primes.iter().map(|&p| (p, irregular_by_bernoulli(p))).collect();
    let irr_s: Vec<(i64, Vec<i64>)> = primes.iter().map(|&p| (p, irregular_by_power_sums(p))).collect();
    let bad: Vec<&(i64, Vec<i64>)> = irr_b.iter().filter(|(_, h)| !h.is_empty()).collect();
    println!("odd primes below {}: {}; irregular: {}; regular: {}", pmax, primes.len(), bad.len(), primes.len() - bad.len());
    let bl: Vec<String> = bad.iter().map(|(p, h)| format!("{} at {:?}", p, h)).collect();
    println!("irregular p with index 2k, p | B_2k (Bernoulli road): {}", bl.join(", "));
    println!("power-sum road agrees: {}", yn(irr_s == irr_b));
    let below100: Vec<i64> = bad.iter().map(|(p, _)| *p).filter(|&p| p < 100).collect();
    println!("below 100: {} odd primes, irregular {:?}", primes.iter().filter(|&&p| p < 100).count(), below100);
    let (h23, irr23) = (3, bad.iter().any(|(p, _)| *p == 23)); // h23 quoted from a published table
    println!("quoted: class number of Q(zeta_23) = {}, so unique factorisation fails; 23 divides it: {}; 23 irregular by Bernoulli: {}",
             h23, yn(h23 % 23 == 0), yn(irr23));
    let e4: [i128; 4] = [2682440, 15365639, 18796760, 20615673];
    println!("Euler's pattern fails: 2682440^4 + 15365639^4 + 18796760^4 - 20615673^4 = {}",
             e4[0].pow(4) + e4[1].pow(4) + e4[2].pow(4) - e4[3].pow(4));
    println!("what breaks: 2 x 8 = {}, a square, gcd(2, 8) = {}, 2 square: {}", 2 * 8, gcd(2, 8), yn(sq(2)));
    assert!(fourth == 0 && cubes == 0);                      // the theorem's prediction, searched
    assert!(road_a == road_b && !road_a.is_empty());         // descent parametrisation, two roads
    assert!(z * z - x.pow(4) == y * y && !sq(y as i128) && y == 4 * 4 * 1 * 17);
    assert!(*ladder.last().unwrap() <= 1 && ladder.len() == 5); // four rungs to nothing
    assert!(irr_s == irr_b);                                 // regularity, two roads
    assert!(bad.iter().map(|(p, _)| *p).collect::<Vec<i64>>() == vec![37, 59, 67, 101, 103, 131, 149, 157]);
    assert!((h23 % 23 == 0) == irr23);                       // table and Bernoulli road agree
    assert!(pts == vec![(-1, 1), (0, 1), (1, 1)]);
    println!("ALL CHECKS PASS");
}
