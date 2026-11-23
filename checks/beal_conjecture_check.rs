// Beal's conjecture: A^x + B^y = C^z with x, y, z >= 3 forces a common prime.  std only, no crates.
// Beal is open, so the search is evidence.  Roads: the search by set lookup against integer-root tests;
// the common factor by gcd of all three against gcd of two; the families by identity against direct powers.
use std::collections::HashSet;

fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }

fn pw(b: u128, e: u32) -> Option<u128> { b.checked_pow(e) }

fn iroot(n: u128, k: u32) -> u128 {          // largest r with r^k <= n, float guess corrected in integers
    let mut r = (n as f64).powf(1.0 / k as f64).round() as u128;
    while r > 0 && pw(r, k).map_or(true, |v| v > n) { r -= 1; }
    while pw(r + 1, k).map_or(false, |v| v <= n) { r += 1; }
    r
}

fn bits(n: u128) -> u32 { 128 - n.leading_zeros() }

fn high_power(n: u128) -> bool {             // n = r^k for some k >= 3?  (1 = 1^3 counts)
    n == 1 || (3..=bits(n)).any(|k| iroot(n, k).pow(k) == n)
}

fn common_exp(v: &[u128]) -> u32 {           // an n >= 3 with every value an n-th power, else 0
    let top = v.iter().map(|&x| bits(x)).max().unwrap();
    for n in 3..=top {
        if v.iter().all(|&x| iroot(x, n).pow(n) == x) { return n; }
    }
    0
}

type T3 = (u128, u128, u128);
fn cop_all(t: &[T3]) -> usize { t.iter().filter(|t| gcd(gcd(t.0, t.1), t.2) == 1).count() }  // coprime: gcd of all three
fn cop_two(t: &[T3]) -> usize { t.iter().filter(|t| gcd(t.0, t.1) == 1).count() }             // coprime: gcd of the first two
fn below1(x: u32, y: u32, z: u32) -> bool {    // 1/x + 1/y + 1/z < 1, in whole numbers: the bottom row
    let (x, y, z) = (x as u128, y as u128, z as u128);
    y * z + x * z + x * y < x * y * z
}

fn commas(n: u128) -> String {
    let s = n.to_string();
    let mut out = String::new();
    for (i, ch) in s.chars().enumerate() {
        if i > 0 && (s.len() - i) % 3 == 0 { out.push(','); }
        out.push(ch);
    }
    out
}

fn main() {
    println!("example: 3^3 + 6^3 = 3^5");
    let (a, b, c) = (3u128.pow(3), 6u128.pow(3), 3u128.pow(5));
    println!("{} + {} = {}   gcd = {}   gcd(A, B, C) = {}", a, b, c, gcd(gcd(a, b), c), gcd(gcd(3, 6), 3));
    println!("divide by 3^3: {} + {} = {} = 3^2, so z falls to 2", a / 27, b / 27, c / 27);
    println!("float cube root of 216, truncated: {}   integer root: {}", 216f64.powf(1.0 / 3.0) as u64, iroot(216, 3));

    println!("\nfamily 1: 1 + 2^3 = 3^2 times 3^(3k) gives (3^k)^3 + (2*3^k)^3 = 3^(3k+2)");
    for k in 1..5u32 {
        let (x, y) = (3u128.pow(k), 2 * 3u128.pow(k));
        let r = 3u128.pow(3 * k + 2);
        assert!(3u128.pow(3 * k) * 9 == x.pow(3) + y.pow(3) && x.pow(3) + y.pow(3) == r);
        println!("  k={}: {}^3 + {}^3 = 3^{} = {}", k, x, y, 3 * k + 2, commas(r));
    }
    println!("family 2: (a s)^m + (b s)^m = s^(m+1), s = a^m + b^m");
    let mut n_id = 0;
    for x in 1..5u128 {
        for y in 1..5u128 {
            for m in 3..7u32 {
                let s = x.pow(m) + y.pow(m);
                let lhs = (x * s).pow(m) + (y * s).pow(m);
                assert!(lhs == s.pow(m + 1) && high_power(lhs));
                n_id += 1;
            }
        }
    }
    println!("  a=1 b=2 m=3: 9^3 + 18^3 = 9^4 = {}   identities checked: {}", commas(9u128.pow(4)), n_id);

    let big_n: u128 = 10u128.pow(10);
    let mut set: HashSet<u128> = HashSet::new();
    set.insert(1);
    for e in 3..=bits(big_n) {                // every A^x <= N with x >= 3
        let mut r = 2u128;
        while r.pow(e) <= big_n { set.insert(r.pow(e)); r += 1; }
    }
    let mut l: Vec<u128> = set.iter().cloned().collect();
    l.sort();
    let mut road1 = Vec::new();
    let mut road2 = Vec::new();
    for &r in &l {
        for &p in &l {
            if 2 * p > r { break; }
            if set.contains(&(r - p)) { road1.push((p, r - p, r)); }
            if high_power(r - p) { road2.push((p, r - p, r)); }   // second road: no lookup table
        }
    }
    assert!(road1 == road2);
    println!("\nsearch: A^x + B^y = C^z, x, y, z >= 3, A^x <= B^y, C^z <= 10^10");
    println!("bound    powers  solutions  coprime  one exponent for all three");
    for j in 6..11u32 {
        let lim = 10u128.pow(j);
        let s: Vec<T3> = road1.iter().filter(|t| t.2 <= lim).cloned().collect();
        let (cop1, cop2) = (cop_all(&s), cop_two(&s));
        assert!(cop1 == cop2);                 // a prime in two of p, q, r divides the third
        let feq = s.iter().filter(|t| common_exp(&[t.0, t.1, t.2]) > 0).count();
        let np = l.iter().filter(|&&v| v <= lim).count();
        println!("10^{:<5} {:>6}  {:>9}  {:>7}  {:>5}", j, np, s.len(), cop1, feq);
    }
    assert!(road1.iter().filter(|t| t.2 <= 1_000_000).count() == 25);   // the abc card's count
    println!("set lookup and integer-root test agree; checked for C^z <= 10^10");
    println!("one-exponent test on 8, 27, 64 (all cubes): {}", common_exp(&[8, 27, 64]));
    assert!(common_exp(&[8, 27, 64]) == 3);   // the last column's test can find a shared exponent
    let first: Vec<String> = road1[..8].iter().map(|t| format!("{}+{}={}", t.0, t.1, t.2)).collect();
    println!("first eight: {}", first.join(", "));
    let dbl = road1.iter().filter(|t| t.0 == t.1).count();
    println!("A^x = B^y (a doubling, like 8 + 8 = 16): {} of {}", dbl, road1.len());
    assert!(dbl == l.iter().filter(|&&p| set.contains(&(2 * p))).count());   // second road: powers whose double is a power
    assert!(road1.contains(&(27, 216, 243)));

    println!("\nexponent 2 allowed: the ten coprime solutions listed in 1997");
    let fc: [[(u128, u32); 3]; 10] = [
        [(1, 7), (2, 3), (3, 2)], [(2, 5), (7, 2), (3, 4)], [(7, 3), (13, 2), (2, 9)],
        [(2, 7), (17, 3), (71, 2)], [(3, 5), (11, 4), (122, 2)], [(17, 7), (76271, 3), (21063928, 2)],
        [(1414, 3), (2213459, 2), (65, 7)], [(9262, 3), (15312283, 2), (113, 7)],
        [(43, 8), (96222, 3), (30042907, 2)], [(33, 8), (1549034, 2), (15613, 3)]];
    let mut inside = 0;
    for t in fc.iter() {
        let ((aa, x), (bb, y), (cc, z)) = (t[0], t[1], t[2]);
        assert!(aa.pow(x) + bb.pow(y) == cc.pow(z) && gcd(aa, bb) == 1 && gcd(bb, cc) == 1 && gcd(aa, cc) == 1);
        assert!((x == 2 || y == 2 || z == 2) && below1(x, y, z));
        if cc.pow(z) <= big_n { inside += 1; }
        println!("  {}^{} + {}^{} = {}^{} = {}", aa, x, bb, y, cc, z, commas(cc.pow(z)));
    }
    let fcv: Vec<T3> = fc.iter().map(|t| (t[0].0.pow(t[0].1), t[1].0.pow(t[1].1), t[2].0.pow(t[2].1))).collect();
    let least_x = (2..99u32).find(|&x| below1(x, 3, 2)).unwrap();   // 1 = 1^x for every x
    println!("1/x + 1/y + 1/z below 1 for all ten; for 1^x + 2^3 = 3^2, from x = {}", least_x);
    println!("coprime counters on these ten: gcd of all three {}, gcd of two {}", cop_all(&fcv), cop_two(&fcv));
    assert!(cop_all(&fcv) == fc.len() && cop_two(&fcv) == fc.len());
    println!("inside the search bound 10^10: {} of 10", inside);
    assert!(inside == 5);
    println!("Pythagoras, all exponents 2: 3^2 + 4^2 = 5^2 = {}  gcd {}", 9 + 16, gcd(3, 4));
    let mut sums: Vec<(u128, u128)> = Vec::new();        // 1/x + 1/y + 1/z as a reduced fraction
    for x in 3..30u128 { for y in x..30 { for z in y..30 {
        let (nu, de) = (y * z + x * z + x * y, x * y * z);
        let g = gcd(nu, de);
        sums.push((nu / g, de / g));
    } } }
    sums.sort_by(|p, q| (q.0 * p.1).cmp(&(p.0 * q.1)));
    sums.dedup();
    let show = |f: (u128, u128)| if f.1 == 1 { f.0.to_string() } else { format!("{}/{}", f.0, f.1) };
    println!("1/x + 1/y + 1/z, all >= 3: largest {} at (3, 3, 3), next {} at (3, 3, 4)", show(sums[0]), show(sums[1]));
    assert!(sums[0] == (1, 1) && sums[1] == (11, 12));

    println!("\nwhat breaks");
    println!("  allow an exponent 2: 2^5 + 7^2 = 3^4 = {}  gcd {}", 32 + 49, gcd(32, 49));
    println!("  divide out the common 3^3: 1 + 8 = 9, exponent 2");
    println!("  read 'no solutions': {} solutions with a common prime, C^z <= 10^10", road1.len());
    println!("  trust the search: {} of 10 exponent-2 solutions lie above 10^10", 10 - inside);
    println!("ALL CHECKS PASS");
}
