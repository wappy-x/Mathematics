// Counterexamples -- the same check as the Python one, in Rust.  No crates.
// Three "for every" claims, each refuted by one exact witness, and each witness
// reached by two roads: a search that finds it, and a direct exact check of it.
use std::collections::HashMap;

fn smallest_factor(n: u64) -> u64 {                // trial division, written out
    let mut d = 2;
    while d * d <= n {
        if n % d == 0 { return d; }
        d += if d == 2 { 1 } else { 2 };
    }
    n
}
fn is_prime(n: u64) -> bool { n >= 2 && smallest_factor(n) == n }
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn comb(n: u128, k: u128) -> u128 { (0..k).fold(1, |acc, i| acc * (n - i) / (i + 1)) }
fn powmod(b: u128, e: u32, m: u128) -> u128 { (0..e).fold(1, |acc, _| acc * b % m) }
fn list(v: &[u64]) -> String {
    format!("[{}]", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn main() {
    println!("Claim 1 (Fermat, 1640): every 2^(2^m) + 1 is prime");
    let fermat: Vec<u64> = (0..6).map(|m| (1u64 << (1u32 << m)) + 1).collect();
    for (m, &f) in fermat.iter().enumerate() {
        let p = smallest_factor(f);
        let tail = if p == f { "prime".to_string() } else { format!("divisible by {}", p) };
        println!("  m={}  {:>10}  {}", m, f, tail);
    }
    let cands: Vec<u64> = (65..642).step_by(64).filter(|&p| is_prime(p)).collect(); // Euler: 1 + a multiple of 64
    println!("  primes one more than a multiple of 64, up to 641: {}", list(&cands));
    let hits: Vec<u64> = cands.iter().cloned().filter(|&p| fermat[5] % p == 0).collect();
    let (mut x, mut chain) = (2u64, Vec::new());
    for _ in 0..5 { x = x * x % 641; chain.push(x); }   // square five times: 2^32 mod 641
    println!("  squaring 2 mod 641: 2^2,2^4,2^8,2^16,2^32 -> {}", list(&chain));
    println!("  641 = 5*2^7 + 1 = {} = 5^4 + 2^4 = {}", 5 * 128 + 1, 625 + 16);
    let cof = fermat[5] / 641;
    println!("  witness: 2^32 + 1 = 641 x {}; cofactor prime: {}", cof, py(is_prime(cof)));
    let pr: Vec<bool> = fermat.iter().map(|&f| is_prime(f)).collect();
    assert!(pr == vec![true, true, true, true, true, false]);
    assert!(hits == vec![641] && cands[4] == 641 && chain[4] == 640 && 641 * cof == fermat[5]);

    println!("Claim 2 (Goldbach, 1752): every odd composite is a prime + 2 x a square");
    let n_max = 6000usize;
    let mut sieve = vec![true; n_max + 1];
    sieve[0] = false; sieve[1] = false;
    let mut i = 2;
    while i * i <= n_max {
        if sieve[i] { let mut j = i * i; while j <= n_max { sieve[j] = false; j += i; } }
        i += 1;
    }
    let has_form = |n: usize| -> usize {
        let mut k = 1;
        while 2 * k * k < n { if sieve[n - 2 * k * k] { return k; } k += 1; }
        0
    };
    let odd_comp: Vec<usize> = (9..=n_max).step_by(2).filter(|&n| !sieve[n]).collect();
    let fails: Vec<u64> = odd_comp.iter().filter(|&&n| has_form(n) == 0).map(|&n| n as u64).collect();
    let passed = odd_comp.iter().filter(|&&n| (n as u64) < fails[0]).count() as u64;
    println!("  odd composites 9..{}: {}; failures: {}", n_max, odd_comp.len(), list(&fails));
    let first: Vec<String> = odd_comp[..3].iter()
        .map(|&n| { let k = has_form(n); format!("{}={}+2*{}^2", n, n - 2 * k * k, k) }).collect();
    println!("  odd composites below {} that fit: {}, first ones: {}", fails[0], passed, first.join(", "));
    let rest: Vec<u64> = (1..5777u64).filter(|k| 2 * k * k < 5777).map(|k| 5777 - 2 * k * k).collect(); // road 2
    let f5777 = smallest_factor(5777);
    println!("  5777 = {} x {}; 5777 - 2 x (1^2..53^2): {} numbers, primes among them: {}",
        f5777, 5777 / f5777, rest.len(), rest.iter().filter(|&&r| is_prime(r)).count());
    assert!(fails == vec![5777, 5993] && !rest.iter().any(|&r| is_prime(r)));
    assert!(fails.iter().all(|&n| !is_prime(n)));

    println!("Claim 3 (Euler, 1769): k-th powers need at least k terms to sum to a k-th power");
    let w: [u64; 5] = [27, 84, 110, 133, 144];
    for v in w { println!("  {:>3}^5 = {:>11}", v, v.pow(5)); }
    let lhs: u64 = w[..4].iter().map(|v| v.pow(5)).sum();
    println!("  sum of the four = {}; 144^5 = {}; equal: {}", lhs, w[4].pow(5), py(lhs == w[4].pow(5)));
    let s4: u64 = w[..4].iter().sum();
    println!("  mod 30 shortcut: 27+84+110+133 = {} = {} mod 30, 144 = {} mod 30", s4, s4 % 30, 144 % 30);
    let e_max = 150u64;                                // road 2: meet-in-the-middle search
    let p5: Vec<u64> = (0..=e_max).map(|i| i.pow(5)).collect();
    let mut pairs: HashMap<u64, Vec<(u64, u64)>> = HashMap::new();
    for a in 1..e_max { for b in a..e_max {
        pairs.entry(p5[a as usize] + p5[b as usize]).or_default().push((a, b));
    } }
    let mut found: Vec<[u64; 5]> = Vec::new();
    for e in 2..=e_max { for c in 1..e { for d in c..e {
        let used = p5[c as usize] + p5[d as usize];
        if used + 2 > p5[e as usize] { break; }
        if let Some(v) = pairs.get(&(p5[e as usize] - used)) {
            for &(a, b) in v { if b <= c { found.push([a, b, c, d, e]); } }
        }
    } } }
    let shown: Vec<String> = found.iter()
        .map(|t| format!("({})", t.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))).collect();
    println!("  search a<=b<=c<=d<e<={}: solutions [{}]", e_max, shown.join(", "));
    let cand: u128 = (2..144u128).map(|e| comb(e + 2, 4)).sum();
    println!("  candidates a<=b<=c<=d<e, e < 144, all failing: {} (formula C(146,5) = {})", cand, comb(146, 5));
    let s: Vec<u64> = w.iter().map(|v| 2 * v).collect();
    let s_ok = s[..4].iter().map(|v| v.pow(5)).sum::<u64>() == s[4].pow(5);
    println!("  doubled witness ({}): still equal: {}",
        s.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "), py(s_ok));
    let frye: [u128; 4] = [95800, 217519, 414560, 422481];
    let elkies: [u128; 4] = [2682440, 15365639, 18796760, 20615673];
    let ok4 = |q: &[u128; 4]| q[..3].iter().map(|v| v.pow(4)).sum::<u128>() == q[3].pow(4);
    for (name, q) in [("Frye 1988", &frye), ("Elkies 1988", &elkies)] {
        println!("  k=4, {}: {}^4+{}^4+{}^4 = {}^4 is {}", name, q[0], q[1], q[2], q[3], py(ok4(q)));
    }
    println!("  not a witness: 3^3+4^3+5^3 = {} = 6^3, but that is k = 3 terms, not fewer", 27 + 64 + 125);
    assert!(found == vec![w] && lhs == w[4].pow(5) && lhs == 61917364224 && cand == comb(146, 5));
    assert!(s4 % 30 == w[4] % 30 && s_ok && ok4(&frye) && ok4(&elkies));

    println!("Trap: a near miss is not a witness (k = 12)");
    let (mut fl, mut fr, mut fa) = (1.0f64, 1.0f64, 1.0f64);
    for _ in 0..12 { fl *= 1782.0; fr *= 1841.0; fa *= 1922.0; }
    let gap = (fl + fr - fa) / fa;
    println!("  floats: 1782^12+1841^12 ~ {} x 10^29, 1922^12 ~ {} x 10^29",
        ((fl + fr) / 1e29).floor(), (fa / 1e29).floor());
    println!("  relative gap, parts per 10^12: {}", (gap * 1e12 + 0.5).floor());
    // exact comparison without big integers: residues modulo several primes
    let ms: [u128; 4] = [2, 1_000_000_007, 998_244_353, 2_147_483_647];
    let lr: Vec<(u128, u128)> = ms.iter()
        .map(|&m| ((powmod(1782, 12, m) + powmod(1841, 12, m)) % m, powmod(1922, 12, m))).collect();
    let equal = lr.iter().all(|&(l, r)| l == r);
    let oe = |r: u128| if r == 1 { "odd" } else { "even" };
    println!("  exact: left is {}, right is {}; equal: {}", oe(lr[0].0), oe(lr[0].1), py(equal));
    assert!(!equal && lr[0] == (1, 0) && lr[1].0 != lr[1].1 && 0.0 < -gap && -gap < 1e-9);

    println!("Successes before the first failure (log10, one # per 0.25)");
    let rows: [(&str, u128); 4] = [("Fermat, cases m=0..4", 5), ("Goldbach, odd composites", passed as u128),
        ("Euler k=5, candidates", cand), ("Polya, n=2.., quoted", 906150257 - 2)];
    for (name, v) in rows {
        let lg = (v as f64).log10();
        println!("  {:<26}{:<36}{:>11}  {:.2}", name, "#".repeat((lg * 4.0 + 0.5) as usize), v, lg);
    }
    println!("ALL CHECKS PASS");
}
