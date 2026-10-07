// Gaussian integers -- the same check as the Python, in Rust.  No crates.  The pair
// (a, b) stands for a + bi, where i times i is -1.  Road one factors a whole number
// and applies the exponent rule for primes leaving remainder 3 on division by 4.
// Road two searches every pair of squares; the roads are compared for n = 1 to 400.
const LIMIT: i64 = 400;
const CASES: [i64; 5] = [5, 13, 21, 45, 65];
type G = (i64, i64);
fn mul(z: G, w: G) -> G {                       // (a+bi)(c+di), i times i = -1
    (z.0 * w.0 - z.1 * w.1, z.0 * w.1 + z.1 * w.0)
}
fn conj(z: G) -> G { (z.0, -z.1) }              // the mirror image: flip b
fn norm(z: G) -> i64 { z.0 * z.0 + z.1 * z.1 }  // the norm a*a + b*b
fn quotient(z: G, w: G) -> (G, i64) { (mul(z, conj(w)), norm(w)) }   // numerators, divisor
fn divides(w: G, z: G) -> bool {                // exact division on the grid
    let ((across, up), den) = quotient(z, w);
    den != 0 && across % den == 0 && up % den == 0
}
fn primes_in(mut n: i64) -> Vec<(i64, i64)> {   // trial division: prime, power
    let (mut out, mut p) = (vec![], 2);
    while p * p <= n {
        let mut e = 0;
        while n % p == 0 { n /= p; e += 1; }
        if e > 0 { out.push((p, e)); }
        p += 1;
    }
    if n > 1 { out.push((n, 1)); }
    out
}
fn rule(n: i64) -> bool {                       // road one: the exponent rule
    primes_in(n).iter().all(|&(p, e)| p % 4 != 3 || e % 2 == 0)
}
fn pairs(n: i64) -> Vec<G> {                    // road two: search the squares
    let mut top = 0;
    while (top + 1) * (top + 1) <= n { top += 1; }
    let mut out = vec![];
    for a in 0..=top { for b in a..=top { if a * a + b * b == n { out.push((a, b)); } } }
    out
}
fn main() {
    let (z, w) = ((2, 1), (3, 2));              // the points 2 + i and 3 + 2i
    let (five, thirteen, prod) = (mul(z, conj(z)), mul(w, conj(w)), mul(z, w));
    let mut units = vec![];
    for a in -1..=1 { for b in -1..=1 { if norm((a, b)) == 1 { units.push((a, b)); } } }
    let (exact, off) = (quotient((5, 0), z), quotient(z, conj(z)));
    let agree = (1..=LIMIT).filter(|&n| rule(n) == !pairs(n).is_empty()).count() as i64;
    println!("the pair (a, b) means a + bi, i times i = -1; the grid holds the norm a*a + b*b, columns a = 0 to 4");
    for b in [3i64, 2, 1, 0] {
        let mut line = format!("b = {} |", b);
        for a in 0..5 { line.push_str(&format!("{:>4}", a * a + b * b)); }
        println!("{}", line);
    }
    println!("(2 + i) + (3 + 2i) = {} + {}i", z.0 + w.0, z.1 + w.1);
    println!("(2 + i)(2 - i) = {} + {}i, factor norms {} and {}, and the norm of 5 + 0i is {}",
             five.0, five.1, norm(z), norm(conj(z)), norm((5, 0)));
    println!("(3 + 2i)(3 - 2i) = {} + {}i, factor norms {} and {}", thirteen.0, thirteen.1, norm(w), norm(conj(w)));
    println!("(2 + i)(3 + 2i) = {} + {}i, norm {} = {} x {}, and 4*4 + 7*7 = {}",
             prod.0, prod.1, norm(prod), norm(z), norm(w), prod.0 * prod.0 + prod.1 * prod.1);
    println!("the grid points of norm 1, the units, are {:?}: -1, -i, i and 1", units);
    println!("5 over (2 + i): numerators {:?} over {}, quotient ({}, {}), on the grid",
             exact.0, exact.1, exact.0.0 / exact.1, exact.0.1 / exact.1);
    println!("(2 + i) over (2 - i): numerators {:?} over {}, off the grid, norm ratio {}",
             off.0, off.1, norm(z) / norm(conj(z)));
    for n in CASES {
        let got = pairs(n);
        let ps: Vec<String> = primes_in(n).iter().map(|(p, e)| format!("{}^{}", p, e)).collect();
        let shown = if got.is_empty() { "none".to_string() }
            else { got.iter().map(|(a, b)| format!("({}, {})", a, b)).collect::<Vec<_>>().join(" ") };
        println!("n = {}: primes {}, rule says {}, pairs {}", n, ps.join(" "),
                 if rule(n) { "yes" } else { "no" }, shown);
    }
    println!("rule and square-search agree for every n from 1 to {}: {} of {}", LIMIT, agree, LIMIT);
    println!("with i times i = +1, (2 + i)(2 - i) would be {}, not {}; and 21 mod 4 = {}",
             2 * 2 - 1 * 1, five.0, 21 % 4);
    assert!(five == (5, 0) && thirteen == (13, 0) && units == vec![(-1, 0), (0, -1), (0, 1), (1, 0)]);
    assert!(norm(prod) == norm(z) * norm(w) && prod == (4, 7));
    assert!(agree == LIMIT && pairs(5) == vec![(1, 2)] && pairs(21).is_empty());
    assert!(exact == ((10, -5), 5) && off == ((3, 4), 5) && !divides(conj(z), z) && divides(z, (5, 0)));
    println!("ALL CHECKS PASS");
}
