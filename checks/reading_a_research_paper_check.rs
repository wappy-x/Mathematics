// Reading a paper: Zhang's bounded gaps, abstract against Theorem 1 -- the check behind the card.
// Standard library only.  Four roads:
// 1. a sieve of Eratosthenes to 7 x 10^7 counts primes and builds the paper's own 3,500,000-tuple;
// 2. Lucy's prime-counting recursion finds pi(x) with no sieve, for the paper's inequality;
// 3. admissibility, by the paper's shortcut against the full residue-class definition;
// 4. the dependency list as a graph: longest chain by Kahn's queue and by depth-first search.
use std::collections::{BTreeMap, BTreeSet, HashSet};

fn c(n: usize) -> String { // thousands commas
    let d = n.to_string(); let mut o = String::new();
    for (i, ch) in d.chars().enumerate() { if i > 0 && (d.len() - i) % 3 == 0 { o.push(','); } o.push(ch); }
    o
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> String { let g = gcd(n, d); format!("{}/{}", n / g, d / g) }
fn isqrt(n: usize) -> usize { let mut r = (n as f64).sqrt() as usize; while r * r > n { r -= 1; } while (r + 1) * (r + 1) <= n { r += 1; } r }

fn lucy(n: usize) -> usize { // pi(n) by Lucy's recursion: no list of primes is kept
    let r = isqrt(n);
    let mut v: Vec<usize> = (1..=r).map(|i| n / i).collect();
    let last = *v.last().unwrap();
    for x in (1..last).rev() { v.push(x); }
    let mut s: BTreeMap<usize, i64> = v.iter().map(|&x| (x, x as i64 - 1)).collect();
    for p in 2..=r {
        if s[&p] > s[&(p - 1)] {
            let (sp, p2) = (s[&(p - 1)], p * p);
            for &x in &v {
                if x < p2 { break; }
                let sub = s[&(x / p)] - sp;
                *s.get_mut(&x).unwrap() -= sub;
            }
        }
    }
    s[&n] as usize
}

fn admissible(t: &[usize], s: &[bool]) -> (bool, Option<usize>) { // the definition, prime by prime
    for p in 2..=t.len() {
        if s[p] && t.iter().map(|h| h % p).collect::<HashSet<_>>().len() == p { return (false, Some(p)); }
    }
    (true, None)
}

fn main() {
    let (x, k0) = (70_000_000usize, 3_500_000usize);
    let mut s = vec![true; x + 1]; s[0] = false; s[1] = false;
    for i in 2..=isqrt(x) { if s[i] { let mut j = i * i; while j <= x { s[j] = false; j += i; } } }
    let ps: Vec<usize> = (0..=x).filter(|&i| s[i]).collect();
    let (pi_x, pi_k) = (ps.len(), s[..=k0].iter().filter(|&&b| b).count());
    let (lx, lk) = (lucy(x), lucy(k0));
    println!("Road 1 and 2: the paper's inequality pi(7 x 10^7) - pi(3.5 x 10^6) > 3.5 x 10^6");
    println!("pi(70,000,000) = {} by sieve, {} by Lucy's recursion", c(pi_x), c(lx));
    println!("pi(3,500,000) = {} by sieve, {} by Lucy's recursion", c(pi_k), c(lk));
    println!("difference = {}, needed > {}: {}", c(pi_x - pi_k), c(k0), if pi_x - pi_k > k0 { "True" } else { "False" });
    let h = &ps[pi_k..pi_k + k0]; // the k0 primes just above k0: the paper's admissible set
    let (h1, hk) = (h[0], h[k0 - 1]);
    println!("the tuple: primes {} (prime number {}) to {} (prime number {})", c(h1), c(pi_k + 1), c(hk), c(pi_k + k0));
    println!("width h_k0 - h_1 = {}; abstract's bound 70,000,000; slack {}", c(hk - h1), c(x - (hk - h1)));
    println!("shortcut: every entry prime and above k0, so class 0 mod each p <= k0 is empty: {}", if h1 > k0 { "True" } else { "False" });

    println!("Road 3: admissibility, shortcut against the full residue check");
    let tf = |b: bool| if b { "True" } else { "False" };
    for &k in &[10usize, 50, 300] {
        let t: Vec<usize> = ps.iter().cloned().filter(|&p| p > k).take(k).collect();
        let f = &ps[..k];
        let (at, af) = (admissible(&t, &s), admissible(f, &s));
        println!("k = {}: primes above k from {} to {}, admissible {}; first k primes from {} to {}, admissible {}, fails at p = {}",
                 k, t[0], t[k - 1], tf(at.0), f[0], f[k - 1], tf(af.0), af.1.unwrap());
        assert!(at.0 == (t[0] > k) && !af.0);
    }
    println!("(0, 2, 4): classes mod 3 met = {} of 3, so not admissible", [0usize, 2, 4].iter().map(|v| v % 3).collect::<HashSet<_>>().len());

    println!("What the theorem does not say");
    let tw = ps.iter().filter(|&&p| p + 2 <= x && s[p + 2]).count();
    let (mut g, mut at) = (0, 0);
    for w in ps.windows(2) { if w[1] - w[0] > g { g = w[1] - w[0]; at = w[0]; } }
    println!("twin pairs below 70,000,000: {} (evidence only; gap 2 is not claimed)", c(tw));
    println!("widest gap below 70,000,000: {}, after {} (true of this range, not 'infinitely often')", g, c(at));
    let f10 = 3_628_800usize; // 10!: 10! + 2, ..., 10! + 10 are all composite
    println!("10! + 2 to 10! + 10 composite: {}; gaps are unbounded", tf((2..11).all(|j| !s[f10 + j])));

    println!("Theorem 2: varpi = {}, level 1/2 + 2 varpi = {} = {:.6}", fr(1, 1168), fr(584 + 2, 1168), 293.0f64 / 584.0);
    println!("cut-off D = x^(1/4 + varpi) = x^({}); excess over Bombieri-Vinogradov 2 varpi = {}", fr(292 + 1, 1168), fr(2, 1168));
    println!("Polymath 2014 exponent (quoted): 1/2 + 7/300 = {} = {:.6}", fr(150 + 7, 300), 157.0f64 / 300.0); // quoted, not proved here

    println!("Road 4: the dependency list (A <- B means A uses B)");
    let uses: BTreeMap<&str, Vec<&str>> = [
        ("Theorem 1", vec!["GPY sieve [7]", "Theorem 2"]),
        ("Theorem 2", vec!["Bombieri-Vinogradov", "Heath-Brown identity [9]", "Type I/II", "Type III"]),
        ("Type I/II", vec!["dispersion method [1], [5]", "Siegel-Walfisz", "Weil's Kloosterman bound", "Shiu [12]"]),
        ("Type III", vec!["Birch-Bombieri, appendix to [6]", "Weil's Kloosterman bound"]),
        ("Birch-Bombieri, appendix to [6]", vec!["Deligne 1974 [4]"]),
    ].into_iter().collect();
    let mut nodes: BTreeSet<&str> = uses.keys().cloned().collect();
    for v in uses.values() { for b in v { nodes.insert(b); } }
    let outside: Vec<&str> = nodes.iter().cloned().filter(|n| !uses.contains_key(n) || n.starts_with("Birch")).collect();
    let inside: Vec<&str> = nodes.iter().cloned().filter(|n| !outside.contains(n)).collect();
    println!("proved in the paper: {}", inside.join(", "));
    let byname: Vec<&str> = outside.iter().cloned().filter(|n| !n.contains('[')).collect();
    println!("main outside results: {}, of which {} carry a reference number", outside.len(), outside.len() - byname.len());
    println!("cited by name only: {}", byname.join(", "));
    fn depth(n: &str, u: &BTreeMap<&str, Vec<&str>>) -> usize {
        1 + u.get(n).map_or(0, |v| v.iter().map(|b| depth(b, u)).max().unwrap_or(0))
    }
    let mut indeg: BTreeMap<&str, usize> = nodes.iter().map(|&n| (n, 0)).collect();
    for v in uses.values() { for b in v { *indeg.get_mut(b).unwrap() += 1; } }
    let mut level: BTreeMap<&str, usize> = nodes.iter().map(|&n| (n, 1)).collect();
    let mut queue: Vec<&str> = nodes.iter().cloned().filter(|n| indeg[n] == 0).collect();
    let mut longest = 0;
    while let Some(a) = queue.pop() {
        longest = longest.max(level[a]);
        if let Some(v) = uses.get(a) { for &b in v {
            let la = level[a]; let lb = level.get_mut(b).unwrap(); *lb = (*lb).max(la + 1);
            let d = indeg.get_mut(b).unwrap(); *d -= 1; if *d == 0 { queue.push(b); }
        } }
    }
    let dt = depth("Theorem 1", &uses);
    println!("longest chain: {} results by depth-first search, {} by Kahn's queue", dt, longest);
    println!("Theorem 1 <- Theorem 2 <- Type III <- Birch-Bombieri <- Deligne 1974");
    assert!(dt == longest && indeg.values().all(|&v| v == 0));

    println!("bars: proved bound on a gap that recurs forever, log10");
    for (lab, v) in [("Zhang 2013, abstract", x), ("Zhang's own tuple", hk - h1), ("Maynard 2013", 600), ("Polymath 2014", 246), ("twin primes, open", 2)] {
        let l = (v as f64).log10();
        println!("{:<21}{:<32}{:.2}", lab, "#".repeat((4.0 * l).round() as usize), l);
    }
    assert!(pi_x == lx && pi_k == lk && pi_x - pi_k > k0);
    assert!(h.len() == k0 && lucy(hk) == pi_k + k0 && lucy(hk - 1) + 1 == pi_k + k0 && lucy(h1 - 1) == pi_k);
    println!("ALL CHECKS PASS");
}
