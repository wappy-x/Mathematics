// Stone-Cech compactification -- the same check as the Python, in Rust.  No crates.
// Exact arithmetic throughout: halving endpoints are whole multiples of 2^-30, and
// every sequence value is a fraction p/q held in i128.  Part 1 reads bounded
// sequences at new points of beta N by halving.  Part 2 checks every family of
// subsets of a 4-point set, so that finite case is proved.  Part 3 counts the new
// points that more and more functions force.  Part 4 is the circle.
use std::collections::{BTreeMap, BTreeSet};

const M: i128 = 12;
const TAIL: i128 = 12 * 100_000_000_000;
const STEPS: u32 = 30;
const SCALE: i128 = 1 << STEPS;                    // an endpoint u stands for u / 2^30

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn show(p: i128, q: i128) -> String {
    let g = gcd(p, q).max(1) * q.signum();
    if q / g == 1 { format!("{}", p / g) } else { format!("{}/{}", p / g, q / g) }
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn sign(n: i128) -> i128 { if n % 2 == 0 { 1 } else { -1 } }
// A free ultrafilter p holds exactly one residue class r mod 12.  On a set that is
// eventually periodic mod 12 (every set used below is), p says "large" exactly when
// the set holds the far-out members of that class.  The test reads three of them.
fn large(member: &dyn Fn(i128) -> bool, r: i128) -> bool {
    (0..3).all(|k| member(TAIL + M * k + r))
}
// sequence k at n, as a fraction (p, q) with q > 0
fn seq(k: usize, n: i128) -> (i128, i128) {
    match k { 0 => (sign(n), 1), 1 => (1, n), _ => (sign(n) * n + 1, n) }
}
fn direct(k: usize, r: i128) -> i128 { if k == 1 { 0 } else { sign(r) } }   // road 2
fn within(k: usize, n: i128, lo: i128, hi: i128) -> bool {                    // lo <= a_n < hi
    let (p, q) = seq(k, n);
    lo * q <= p * SCALE && p * SCALE < hi * q
}
fn halve(k: usize, r: i128) -> (i128, i128) {
    let (mut lo, mut hi) = (-2 * SCALE, 2 * SCALE);  // every value lies in [-2, 2)
    for _ in 0..STEPS {
        let mid = (lo + hi) / 2;
        let left = large(&|n| within(k, n, lo, mid), r);
        let right = large(&|n| within(k, n, mid, hi), r);
        assert!(left != right);                       // exactly one half is large
        if left { hi = mid } else { lo = mid }
    }
    (lo, hi)
}

fn is_filter(fam: u32) -> bool {
    let mem: Vec<u32> = (0..16).filter(|&a| fam >> a & 1 == 1).collect();
    if mem.is_empty() || fam & 1 == 1 { return false; }
    let up = mem.iter().all(|&a| (0..16u32).all(|b| a & b != a || fam >> b & 1 == 1));
    up && mem.iter().all(|&a| mem.iter().all(|&b| fam >> (a & b) & 1 == 1))
}
fn lcm(a: i128, b: i128) -> i128 { a / gcd(a, b) * b }

fn main() {
    // ---- Part 1 ----
    let names = ["(-1)^n", "1/n", "(-1)^n + 1/n"];
    println!("Part 1: values at the new point p_r of beta N, by {} halvings of [-2, 2)", STEPS);
    let odd_large = large(&|n| sign(n) < 0, 1);
    assert!(odd_large && !large(&|n| sign(n) >= 0, 1));
    println!("  step 1 for (-1)^n at r = 1: [-2, 0) holds the odd n; large: {}", yn(odd_large));
    let mut tally: BTreeMap<i128, i32> = BTreeMap::new();
    for r in 0..M {
        for k in 0..3 {
            let (lo, hi) = halve(k, r);
            let v = direct(k, r) * SCALE;
            assert!(lo <= v && v < hi);
            assert!(hi - lo == 4 * SCALE >> STEPS);   // the printed width, against its formula
            if k == 0 { *tally.entry(lo / SCALE).or_insert(0) += 1; }
            if r == 1 || r == 2 {
                println!("  r = {:>2} mod 12: {:<13} -> {:>2}, interval width {}",
                         r, names[k], show(lo, SCALE), show(hi - lo, SCALE));
            }
        }
    }
    assert!(tally.len() == 2 && tally[&-1] == 6 && tally[&1] == 6);
    println!("  (-1)^n over all 12 classes: -1 at {}, +1 at {}, anything else at 0", tally[&-1], tally[&1]);

    // ---- Part 2 ----
    let filters: Vec<u32> = (0..1u32 << 16).filter(|&f| is_filter(f)).collect();
    let mut ultras: Vec<u32> = filters.iter().cloned()
        .filter(|&f| (0..16).all(|a| f >> a & 1 == 1 || f >> (15 ^ a) & 1 == 1)).collect();
    let mut principal: Vec<u32> = (0..4)
        .map(|i| (0..16u32).filter(|&a| a >> i & 1 == 1).map(|a| 1u32 << a).sum()).collect();
    ultras.sort(); principal.sort();
    assert!(filters.len() == (1 << 4) - 1 && ultras == principal);
    let free = ultras.iter().filter(|&&f| (0..4).all(|i| f >> (1u32 << i) & 1 == 0)).count(); // holds no single point
    println!("Part 2: 4 points (4 voters), all 65536 families of subsets checked");
    println!("  filters {} (formula 2^4 - 1 = {}); ultrafilters {}", filters.len(), (1 << 4) - 1, ultras.len());
    println!("  each ultrafilter is 'the 8 sets holding point i': {}; free ones: {}", yn(ultras == principal), free);

    // ---- Part 3 ----
    let funcs: [(&str, i128); 5] = [("1/n", 1), ("(-1)^n", 2), ("n mod 3", 3), ("n mod 4", 4), ("n mod 5", 5)];
    println!("Part 3: new points of the closure of N in the cube, function by function");
    for k in 1..=funcs.len() {
        let periods: Vec<i128> = funcs[..k].iter().map(|f| f.1).collect();
        let seen: BTreeSet<Vec<i128>> = (1_000_000_000..1_000_001_000i128)
            .map(|n| periods[1..].iter().map(|p| n % p).collect()).collect();
        let l = periods.iter().fold(1, |a, &b| lcm(a, b));
        assert!(seen.len() as i128 == l);
        let nm: Vec<&str> = funcs[..k].iter().map(|f| f.0).collect();
        println!("  {:<38} new points {:>2}; lcm of periods {}", nm.join(", "), seen.len(), l);
    }

    // ---- Part 4 ----
    println!("Part 4: R plus one point is the circle (north pole (0, 1) added)");
    for t in [0i128, 1, -1, 1000, -1000] {
        let d = 1 + t * t;
        assert!((2 * t) * (2 * t) + (t * t - 1) * (t * t - 1) == d * d);
        println!("  t = {:>5}: ({}, {})", t, show(2 * t, d), show(t * t - 1, d));
    }
    let g = |t: i128| (t * t, 1 + t * t);
    let h = |t: i128| (t, 1 + t.abs());
    assert!(g(1000) == g(-1000) && h(1000) != h(-1000));
    println!("  t^2/(1+t^2) at +-1000: {}, {}: one value 1 at the pole, extends",
             show(g(1000).0, g(1000).1), show(g(-1000).0, g(-1000).1));
    println!("  t/(1+|t|)   at +-1000: {}, {}: two limits, no value at the pole",
             show(h(1000).0, h(1000).1), show(h(-1000).0, h(-1000).1));

    // ---- What breaks ----
    println!("What breaks");
    let far: Vec<i128> = [1000i128, 1001, 1_000_000, 1_000_001].iter().map(|&n| sign(n)).collect();
    assert!(far == vec![1, -1, 1, -1]);
    let fs: Vec<String> = far.iter().map(|v| v.to_string()).collect();
    println!("  one point at infinity for (-1)^n: n = 1000, 1001, 10^6, 10^6+1 give {}", fs.join(", "));
    let small: Vec<bool> = [10i128, 1000, 1_000_000].iter().map(|&b| large(&|n| n <= b, 1)).collect();
    assert!(small == vec![false, false, false]);
    println!("  unbounded a_n = n: {{n <= B}} for B = 10, 1000, 10^6 has B members, large: no, no, no");
    let vals = [0i128, 2, 4];                         // 0, 1/2, 1 in quarters
    let maps: Vec<(i128, i128)> = vals.iter().flat_map(|&u| vals.iter().map(move |&w| (u, w))).collect();
    let cont: Vec<&(i128, i128)> = maps.iter()
        .filter(|m| vals.iter().all(|&c| ((m.0 - c).abs() < 1) == ((m.1 - c).abs() < 1))).collect();
    assert!(cont.len() == 3 && cont.iter().all(|m| m.0 == m.1));
    println!("  indiscrete 2 points: {} of {} maps continuous, all constant: 2 points, 1 image", cont.len(), maps.len());
    println!("ALL CHECKS PASS");
}
