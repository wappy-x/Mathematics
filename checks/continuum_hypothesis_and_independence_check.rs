// The continuum hypothesis -- the same check as the Python, in Rust.  No crates.
// CH itself is independent of the axioms, so no program can test it.  What the
// code checks are the finite shadows of the two proofs: Cohen's forcing (a new
// real built by meeting dense sets, dodging a ground list of reals) and Godel's
// levels (finite levels of the constructible universe are the full tower).
const L: usize = 40; // binary digits kept per real
const K: usize = 4; // new reals added

fn isqrt(m: u128) -> u128 { // floor square root by bisection, written out
    let (mut lo, mut hi) = (0u128, 1u128);
    while hi * hi <= m { hi *= 2 }
    while hi - lo > 1 {
        let mid = (lo + hi) / 2;
        if mid * mid <= m { lo = mid } else { hi = mid }
    }
    lo
}

fn frac_bits(mut p: u64, q: u64) -> String { // first L binary digits of p/q, by long division
    let mut out = String::new();
    for _ in 0..L {
        p *= 2;
        out.push_str(&(p / q).to_string());
        p %= q;
    }
    out
}

fn sqrt_bits(m: u128) -> String { // first L binary digits of sqrt(m) - 1
    let big = m << (2 * L);
    let s = isqrt(big);
    assert!(s * s <= big && big < (s + 1) * (s + 1));
    format!("{:0w$b}", s - (1u128 << L), w = L)
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn flip(bit: char) -> char { if bit == '0' { '1' } else { '0' } }

fn meet(p: &str, r: &str) -> (String, &'static str) { // extend p into "disagrees with r somewhere"
    if !r.starts_with(p) { return (p.to_string(), "met for free") }
    (format!("{}{}", p, flip(r.as_bytes()[p.len()] as char)), "extended by one digit")
}

fn differ(a: &str, b: &str) -> bool { // road two: look for a digit where both are defined
    a.chars().zip(b.chars()).any(|(x, y)| x != y)
}

fn dodgers(n: usize, reals: &[String]) -> usize { // conditions of length n agreeing with no listed real
    let mut count = 0;
    for v in 0..(1usize << n) {
        let s = format!("{:0w$b}", v, w = n);
        if reals.iter().all(|r| differ(&s, r)) { count += 1 }
    }
    count
}

fn main() {
    let ground: Vec<(&str, String)> = vec![("0", "0".repeat(L)), ("1/3", frac_bits(1, 3)), ("1/7", frac_bits(1, 7)),
        ("2/5", frac_bits(2, 5)), ("sqrt2-1", sqrt_bits(2)), ("sqrt3-1", sqrt_bits(3))];
    let reals: Vec<String> = ground.iter().map(|(_, r)| r.clone()).collect();
    let between: Vec<i64> = (0..7u32).map(|n| ((n as i64 + 1)..(1i64 << n)).count() as i64).collect();
    let by_formula: Vec<i64> = (0..7u32).map(|n| (1i64 << n) - n as i64 - 1).collect();
    println!("finite sizes strictly between n and 2^n, n = 0..6: {:?}", between);
    println!("the same by 2^n - n - 1:                         {:?}", by_formula);
    println!("ground list, first 12 binary digits:");
    for (name, r) in &ground { println!("  {:<8} 0.{}...", name, &r[..12]) }
    println!("conditions that already dodge all six (counted / by formula):");
    let lengths = [1usize, 2, 3, 4, 6, 8, 12];
    let brute: Vec<usize> = lengths.iter().map(|&n| dodgers(n, &reals)).collect();
    let formula: Vec<usize> = lengths.iter().map(|&n| {
        let mut pre: Vec<&str> = reals.iter().map(|r| &r[..n]).collect();
        pre.sort();
        pre.dedup();
        (1usize << n) - pre.len()
    }).collect();
    for i in 0..lengths.len() {
        println!("  length {:>2}: {:>4} / {:>4} of {}", lengths[i], brute[i], formula[i], 1usize << lengths[i]);
    }
    let mut g = String::new();
    println!("one Cohen real, meeting one dense set per listed real:");
    for (name, r) in &ground {
        let (next, how) = meet(&g, r);
        g = next;
        println!("  dodge {:<8} {:<22} condition now {}", name, how, g);
    }
    let diag: String = reals.iter().enumerate().map(|(i, r)| flip(r.as_bytes()[i] as char)).collect();
    println!("Cantor's diagonal for comparison: {}", diag);
    println!("generic differs from every listed real: {}", yn(reals.iter().all(|r| differ(&g, r))));
    let mut cols: Vec<String> = vec![String::new(); K];
    let (mut free, mut extended) = (0usize, 0usize);
    for c in 0..K {
        for r in &reals {
            let (next, how) = meet(&cols[c], r);
            cols[c] = next;
            if how == "met for free" { free += 1 } else { extended += 1 }
        }
        for d in 0..c {
            let (a, b) = (cols[c].clone(), cols[d].clone());
            if differ(&a, &b) { free += 1; continue }
            extended += 1;
            if a.len() < b.len() {
                cols[c] = format!("{}{}", a, flip(b.as_bytes()[a.len()] as char));
            } else if a.len() > b.len() {
                cols[d] = format!("{}{}", b, flip(a.as_bytes()[b.len()] as char));
            } else {
                cols[c] = format!("{}0", a);
                cols[d] = format!("{}1", b);
            }
        }
    }
    println!("{} Cohen reals added side by side:", K);
    for c in 0..K { println!("  column {}: {}", c, cols[c]) }
    let dense = K * reals.len() + K * (K - 1) / 2;
    let mut pairs = 0;
    for c in 0..K { for d in 0..c { if differ(&cols[c], &cols[d]) { pairs += 1 } } }
    println!("dense sets met: {} of {}; free {}, extended {}", free + extended, dense, free, extended);
    println!("pairs of new reals that differ: {} of {}", pairs, K * (K - 1) / 2);
    let mut only: Vec<String> = Vec::new();
    for _ in 0..K { // the same columns, dodging the list but not each other
        let mut p = String::new();
        for r in &reals { p = meet(&p, r).0 }
        only.push(p);
    }
    let mut same = 0;
    for c in 0..K { for d in 0..c { if differ(&only[c], &only[d]) { same += 1 } } }
    println!("columns dodging only the list: {}; pairs that differ {} of {}", only.join(" "), same, K * (K - 1) / 2);
    let every: Vec<String> = (0..16usize).map(|v| format!("{:04b}", v)).collect();
    println!("ground list holding all 16 strings of length 4: dodgers {}", dodgers(4, &every));
    let (mut level, mut tower, mut codes_ok): (Vec<u64>, u64, bool) = (Vec::new(), 0, true);
    let (mut built, mut towers) = (vec![0u64], vec![0u64]);
    for _ in 0..5 {
        let mut picks: Vec<u64> = vec![0];
        for &x in &level { // every subset of the level, as its Ackermann code
            let more: Vec<u64> = picks.iter().map(|p| p + (1u64 << x)).collect();
            picks.extend(more);
        }
        picks.sort();
        codes_ok = codes_ok && picks == (0..(1u64 << level.len())).collect::<Vec<u64>>();
        level = picks;
        tower = 1u64 << tower;
        built.push(level.len() as u64);
        towers.push(tower);
    }
    println!("tower V_0..V_5 built / by 2^previous: {:?} / {:?}", built, towers);
    assert!(between == by_formula); // two roads, finite gap
    assert!(brute == formula && brute[0] == 0 && brute[6] == 4096 - 6); // two roads, density
    assert!(reals[1..4].iter().zip([(1u64, 3u64), (1, 7), (2, 5)]).all(|(r, (p, q))| r[..12] == format!("{:012b}", p * 4096 / q)));
    assert!([(2u128, 4usize), (3, 5)].iter().all(|&(m, i)| { // road two for the roots: square the 12-digit prefix
        let n = 4096 + u128::from_str_radix(&reals[i][..12], 2).unwrap();
        n * n <= m << 24 && m << 24 < (n + 1) * (n + 1) }));
    assert!(g == "11" && diag == "100101"); // the worked table, by hand
    assert!(reals.iter().all(|r| differ(&g, r)) && reals.iter().all(|r| differ(&diag, r)));
    assert!(pairs == K * (K - 1) / 2);
    assert!(dodgers(4, &every) == 0 && codes_ok && same == 0);
    assert!(built == towers && built == vec![0, 1, 2, 4, 16, 65536]);
    println!("ALL CHECKS PASS");
}
