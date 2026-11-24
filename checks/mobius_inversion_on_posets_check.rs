// Mobius inversion on an order -- the same check as the Python, in Rust.  No crates.
// An order is a list of members and a test "x is below y".  mu comes from the
// recursion alone, then every count it recovers is rebuilt by brute force.
use std::collections::{BTreeSet, HashMap};
type Mu = HashMap<(u32, u32), i64>;

fn mobius(xs: &[u32], le: fn(u32, u32) -> bool) -> Mu {   // mu(x, y) for every x below y, bottom up
    let mut mu = Mu::new();
    for &x in xs {
        let mut ys: Vec<u32> = xs.iter().copied().filter(|&y| le(x, y)).collect();
        ys.sort_by_key(|&y| xs.iter().filter(|&&z| le(z, y)).count());
        for y in ys {
            let v = if x == y { 1 } else {
                -xs.iter().filter(|&&z| le(x, z) && le(z, y) && z != y).map(|&z| mu[&(x, z)]).sum::<i64>() };
            mu.insert((x, y), v);
        }
    }
    mu
}
fn mirror_ok(xs: &[u32], le: fn(u32, u32) -> bool, mu: &Mu) -> bool {   // Step 2
    xs.iter().all(|&w| xs.iter().filter(|&&y| le(w, y)).all(|&y|
        xs.iter().filter(|&&x| le(w, x) && le(x, y)).map(|&x| mu[&(x, y)]).sum::<i64>() == (w == y) as i64))
}
fn divisors(n: u32) -> Vec<u32> { (1..=n).filter(|d| n % d == 0).collect() }
fn divides(a: u32, b: u32) -> bool { b % a == 0 }
fn subset(a: u32, b: u32) -> bool { a & !b == 0 }          // subsets written as bit patterns
fn by_inversion(n: u32) -> i64 {                           // f(n) = sum over d dividing n of mu(d, n) 2^d
    let mu = mobius(&divisors(n), divides);
    divisors(n).iter().map(|&d| mu[&(d, n)] * (1i64 << d)).sum()
}
fn strings(n: u32) -> Vec<String> { (0..1u32 << n).map(|k| format!("{:0w$b}", k, w = n as usize)).collect() }
fn primitive(s: &str) -> bool {                            // road two: not a shorter block repeated
    let n = s.len() as u32;
    divisors(n).iter().filter(|&&d| d < n).all(|&d| s != s[..d as usize].repeat((n / d) as usize))
}
fn necklaces(ss: &[String]) -> usize {
    ss.iter().map(|s| (0..s.len()).map(|i| format!("{}{}", &s[i..], &s[..i])).min().unwrap()).collect::<BTreeSet<_>>().len()
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn main() {
    let d6 = divisors(6); let mu6 = mobius(&d6, divides); let f6 = by_inversion(6);
    let brute: Vec<String> = strings(6).into_iter().filter(|s| primitive(s)).collect();
    let inv8: Vec<i64> = (1..=8).map(by_inversion).collect();
    let brute8: Vec<i64> = (1..=8).map(|n| strings(n).iter().filter(|s| primitive(s)).count() as i64).collect();
    let (b3, b4): (Vec<u32>, Vec<u32>) = ((0..8).collect(), (0..16).collect());
    let (mub3, mub4) = (mobius(&b3, subset), mobius(&b4, subset));
    let pairs: Vec<(u32, u32)> = b3.iter().flat_map(|&s| b3.iter().filter(move |&&t| subset(s, t)).map(move |&t| (s, t))).collect();
    let signs = pairs.iter().all(|&(s, t)| mub3[&(s, t)] == if (t & !s).count_ones() % 2 == 0 { 1 } else { -1 });
    let top4: Vec<i64> = b4.iter().map(|&t| mub4[&(0, t)]).collect();
    // hotel: bit 1 breakfast, bit 2 parking, bit 4 spa; how many guests in each region
    let regions = [(7, 5), (3, 15), (5, 10), (6, 5), (1, 20), (2, 15), (4, 10), (0, 20)];
    let roster: Vec<u32> = regions.iter().flat_map(|&(r, n)| std::iter::repeat(r).take(n)).collect();
    let g = |s: u32| roster.iter().filter(|&&guest| subset(s, guest)).count() as i64;   // at least s
    let layers: Vec<i64> = (0..4).map(|j| b3.iter().filter(|t| t.count_ones() == j).map(|&t| g(t)).sum()).collect();
    let none: i64 = b3.iter().map(|&t| mub3[&(0, t)] * g(t)).sum();
    let walk = roster.iter().filter(|&&x| x == 0).count() as i64;
    let mirrors = mirror_ok(&d6, divides, &mu6) && mirror_ok(&b3, subset, &mub3) && mirror_ok(&b4, subset, &mub4);
    println!("divisors of 6 under 'divides'; mu(d, 6) for d = {:?}: {:?}; mu(1, 4) = {}", d6,
             d6.iter().map(|&d| mu6[&(d, 6)]).collect::<Vec<_>>(), mobius(&divisors(4), divides)[&(1, 4)]);
    println!("f(6) = 2 - 4 - 8 + 64 = {}; testing all {} strings: {}", f6, 1 << 6, brute.len());
    println!("lengths 1 to 8, by inversion:   {:?}", inv8);
    println!("lengths 1 to 8, by brute force: {:?}", brute8);
    println!("necklaces with no repeating block: {} / 6 = {}, listing {}", f6, f6 / 6, necklaces(&brute));
    println!("all necklaces of length 6, repeats allowed: {}", necklaces(&strings(6)));
    println!("mu(empty, {{1, 2, 3}}) = {}; (-1)^(|T| - |S|) on all {} pairs: {}", mub3[&(0, 7)], pairs.len(), yn(signs));
    println!("16 subsets of {{1, 2, 3, 4}}: mu(empty, T) is +1 for {}, -1 for {}, total {}; mu(empty, {{1, 2, 3, 4}}) = {}",
             top4.iter().filter(|&&v| v == 1).count(), top4.iter().filter(|&&v| v == -1).count(), top4.iter().sum::<i64>(), mub4[&(0, 15)]);
    println!("mirror sums are 1 or 0 on all three orders: {}", yn(mirrors));
    println!("hotel: layers {:?}; none = 100 - 120 + 45 - 5 = {}; walking the roster: {}", layers, none, walk);
    println!("mistake 1, subtract every shorter block: 64 - 2 - 4 - 8 = {}, not {}", 64 - 2 - 4 - 8, f6);
    println!("mistake 2, subtract only the blocks of 3 and 2: 64 - 8 - 4 = {}, not {}", 64 - 8 - 4, f6);
    println!("mistake 3, all 64 strings shared by 6 turns: 64 / 6 = {:.2}, not a whole number", 64.0 / 6.0);
    assert!(f6 == brute.len() as i64 && f6 == 54 && inv8 == brute8);    // inversion against brute force
    assert!(f6 / 6 == necklaces(&brute) as i64 && f6 / 6 == 9 && f6 % 6 == 0);
    assert!(signs && mub3[&(0, 7)] == -1 && top4.iter().sum::<i64>() == 0);
    assert!(none == walk && none == 20 && layers == [100, 120, 45, 5]);  // the hotel card's layers
    assert!(mirrors);
    println!("ALL CHECKS PASS");
}
