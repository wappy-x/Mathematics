// Quadratic reciprocity via Gauss sums: is 43 a square mod 97?
const P: i64 = 97;
const Q: i64 = 43;
const BIG: i64 = 1_000_000_000;

fn odd_primes_below(n: usize) -> Vec<i64> {
    let mut s = vec![true; n];
    for i in (2..n).take_while(|i| i * i < n) {
        if s[i] {
            for j in (i * i..n).step_by(i) { s[j] = false; }
        }
    }
    (3..n).filter(|&k| s[k]).map(|k| k as i64).collect()
}
fn pow_mod(a: i64, mut k: i64, m: i64) -> i64 {
    let (mut r, mut b) = (1i128, a.rem_euclid(m) as i128);
    while k > 0 {
        if k & 1 == 1 { r = r * b % m as i128; }
        b = b * b % m as i128;
        k >>= 1;
    }
    r as i64
}
// Euler's criterion: a^((p-1)/2) mod p is 1 or p - 1
fn euler(a: i64, p: i64) -> i64 {
    let r = pow_mod(a, (p - 1) / 2, p);
    if r == 0 { 0 } else if r == 1 { 1 } else { -1 }
}
// list every square mod p
fn by_squares(a: i64, p: i64) -> i64 {
    if (1..p).any(|x| x * x % p == a.rem_euclid(p)) { 1 } else { -1 }
}
fn pm(s: i64) -> &'static str { if s > 0 { "+" } else { "-" } }
// the flip rule, the rule for -1 and the rule for 2
fn recip(a: i64, p: i64, log: &mut Vec<String>) -> i64 {
    let a = a.rem_euclid(p);
    if a == 1 { return 1; }
    if a == p - 1 {
        let v = if p % 4 == 1 { 1 } else { -1 };
        log.push(format!("({}/{}) = (-1/{}) = {}", a, p, p, v));
        return v;
    }
    let f = (2..=a).find(|d| a % d == 0).unwrap();
    if f < a { return recip(f, p, log) * recip(a / f, p, log); }
    if a == 2 { return if p % 8 == 1 || p % 8 == 7 { 1 } else { -1 }; }
    let sign = if a % 4 == 3 && p % 4 == 3 { -1 } else { 1 };
    log.push(format!("({}/{}) = {}({}/{}) = {}({}/{})", a, p, pm(sign), p, a, pm(sign), p % a, a));
    sign * recip(p, a, log)
}
// multiply in (Z mod q)[x] with x^p = 1
fn mul(u: &[i64], v: &[i64], p: usize, q: i64) -> Vec<i64> {
    let mut w = vec![0i64; p];
    for (i, &ui) in u.iter().enumerate() {
        if ui != 0 {
            for (j, &vj) in v.iter().enumerate() {
                let k = (i + j) % p;
                w[k] = ((w[k] as i128 + ui as i128 * vj as i128) % q as i128) as i64;
            }
        }
    }
    w
}
fn power(u: &[i64], mut k: i64, p: usize, q: i64) -> Vec<i64> {
    let mut r = vec![0i64; p]; r[0] = 1;
    let mut b = u.to_vec();
    while k > 0 {
        if k & 1 == 1 { r = mul(&r, &b, p, q); }
        b = mul(&b, &b, p, q);
        k >>= 1;
    }
    r
}
// g = sum of (a/p) x^a, coefficients mod q
fn gauss(p: i64, q: i64) -> Vec<i64> {
    (0..p).map(|a| euler(a, p).rem_euclid(q)).collect()
}
fn neg(u: &[i64], q: i64) -> Vec<i64> { u.iter().map(|c| (-c).rem_euclid(q)).collect() }
// g^q = +g or -g in characteristic q
fn gauss_sign(p: i64, q: i64) -> i64 {
    let (g, h) = (gauss(p, q), power(&gauss(p, q), q, p as usize, q));
    if h == g { 1 } else if h == neg(&g, q) { -1 } else { 0 }
}
fn show(u: &[i64], q: i64) -> String {
    let mut t = Vec::new();
    for (i, &x) in u.iter().enumerate() {
        let v = if x <= q / 2 { x } else { x - q };
        if v != 0 { t.push(if i == 0 { format!("{}", v) } else { format!("{}x^{}", v, i).replace("1x", "x") }); }
    }
    t.join(" + ").replace("+ -", "- ").replace("x^1 ", "x ")
}
fn main() {
    let wit: Vec<i64> = (0..P).filter(|x| x * x % P == Q).collect();
    println!("square roots of {} mod {}: {:?}", Q, P, wit);
    for &w in wit.iter().take(1) { println!("check: {}^2 = {} = {} x {} + {}", w, w * w, w * w / P, P, w * w % P); }
    println!("by listing all {} squares mod {}: {:+}", P / 2, P, by_squares(Q, P));
    println!("Euler: {}^{} mod {} = {}, so {:+}", Q, (P - 1) / 2, P, pow_mod(Q, (P - 1) / 2, P), euler(Q, P));
    let mut log = Vec::new();
    let r = recip(Q, P, &mut log);
    for line in &log { println!("flip: {}", line); }
    println!("reciprocity: ({}/{}) = {:+}; rules applied: {}", Q, P, r, log.len());
    assert!(r == euler(Q, P) && r == by_squares(Q, P) && (wit.len() == 2) == (r == 1));
    let g3 = power(&gauss(3, BIG), 2, 3, BIG);
    println!("p = 3: g = x - x^2, g^2 = {}, which is -3 once 1 + x + x^2 = 0", show(&g3, BIG));
    let g5 = power(&gauss(3, 5), 5, 3, 5);
    println!("p = 3, q = 5: g^5 = {} = -g; (5/3) = {:+}, (-3/5) = {:+}", show(&g5, 5), euler(5, 3), euler(-3, 5));
    assert!(g5 == neg(&gauss(3, 5), 5) && euler(5, 3) == -1 && euler(-3, 5) == -1);
    for &p in &[P, Q] {
        let (g2, e) = (power(&gauss(p, BIG), 2, p as usize, BIG), euler(-1, p));
        let mut want = vec![(-e).rem_euclid(BIG); p as usize];
        want[0] = (e * (p - 1)).rem_euclid(BIG);
        assert!(g2 == want);
        println!("p = {}: g^2 = {} on x^0 and {} on every other power, so g^2 = p* = {}", p, e * (p - 1), -e, e * p);
    }
    for &(p, q) in &[(P, Q), (Q, P)] {
        let s = gauss_sign(p, q);
        let ps = euler(euler(-1, p) * p, q);
        println!("in characteristic {}, g^{} = {:+} g for p = {}: ({}/{}) = {:+}, Euler says {:+}, (p*/q) = {:+}", q, q, s, p, q, p, s, euler(q, p), ps);
        assert!(s == euler(q, p) && s == ps);
    }
    let small = odd_primes_below(40);
    let mut ok = 0;
    for &p in &small {
        for &q in &small {
            ok += (p != q && gauss_sign(p, q) == euler(q, p) && euler(q, p) == euler(euler(-1, p) * p, q)) as usize;
        }
    }
    let total = small.len() * (small.len() - 1);
    println!("Gauss-sum road against Euler, all ordered pairs of odd primes below 40: {} of {}", ok, total);
    assert!(ok == total);
    let pr = odd_primes_below(200);
    let (mut npairs, mut law, mut negs, mut both3) = (0, 0, 0, 0);
    for (i, &p) in pr.iter().enumerate() {
        for &q in &pr[i + 1..] {
            npairs += 1;
            let prod = euler(p, q) * euler(q, p);
            let sign = if ((p - 1) / 2 * (q - 1) / 2) % 2 == 0 { 1 } else { -1 };
            law += (prod == sign) as i32;
            negs += (prod == -1) as i32;
            both3 += (p % 4 == 3 && q % 4 == 3) as i32;
        }
    }
    println!("pairs of odd primes below 200: {}; law holds for {}; (p/q)(q/p) = -1 for {}; both 3 mod 4: {}", npairs, law, negs, both3);
    assert!(law == npairs && negs == both3);
    let (agree, tests) = (pr.iter().map(|&p| (1..p).filter(|&a| recip(a, p, &mut Vec::new()) == euler(a, p)).count()).sum::<usize>(), pr.iter().map(|&p| (p - 1) as usize).sum::<usize>());
    println!("reciprocity road against Euler, every a from 1 to p - 1, odd primes p below 200: {} of {}", agree, tests);
    assert!(agree == tests);
    // The house example: 5 is a square mod p exactly when p ends in 1 or 9
    let big: Vec<i64> = odd_primes_below(1_000_000).into_iter().filter(|&p| p != 5).collect();
    let sq5: Vec<i64> = big.iter().cloned().filter(|&p| euler(5, p) == 1).collect();
    let end19: Vec<i64> = big.iter().cloned().filter(|&p| p % 10 == 1 || p % 10 == 9).collect();
    println!("primes below a million other than 2 and 5: {}; 5 is a square mod {}; end in 1 or 9: {}; not a square: {}", big.len(), sq5.len(), end19.len(), big.len() - sq5.len());
    assert!(sq5 == end19);
    println!("bars, square: {} not square: {}", sq5.len(), big.len() - sq5.len());
    // What breaks
    let bad1 = recip(43, 11, &mut Vec::new());
    println!("mistake 1, no sign on the flip of (11/43): (43/97) = {:+}, yet 25^2 mod 97 = {}", bad1, 25 * 25 % 97);
    let bad2 = -1 * recip(97, 43, &mut Vec::new());
    println!("mistake 2, sign from 43 alone on the first flip: (43/97) = {:+}", bad2);
    println!("mistake 3, g^2 = p, not p*, so (q/p) = (p/q) always: (3/7) = {:+}, (7/3) = {:+}; the rule fails for {} of {} pairs", euler(3, 7), euler(7, 3), both3, npairs);
    let z = power(&gauss(P, P), P, P as usize, P);
    let nz = z.iter().filter(|&&c| c != 0).count();
    println!("mistake 4, q = p = {}: g^{} has {} nonzero coefficients, so g^{} = 0 and g cannot be cancelled", P, P, nz, P);
    let mut sq15: Vec<i64> = (0..15).map(|x| x * x % 15).collect();
    sq15.sort(); sq15.dedup();
    println!("mistake 5, 15 is not prime: (2/3)(2/5) = {:+}, yet the squares mod 15 are {:?}", euler(2, 3) * euler(2, 5), sq15);
    assert!(!sq15.contains(&2) && euler(2, 3) * euler(2, 5) == 1);
    assert!(bad1 == -1 && bad2 == -1 && euler(3, 7) == -euler(7, 3) && nz == 0);
    println!("ALL CHECKS PASS");
}
