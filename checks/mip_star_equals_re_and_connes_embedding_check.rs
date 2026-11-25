// MIP* = RE and Connes' embedding -- the same check as the Python, in Rust.  No crates.
// Part 1: the CHSH game, squeezed from below (strategy search) and above (an exact
// sum of squares).  Part 2: primality three ways, and Huang's theorem on small cubes.
use std::collections::BTreeMap;
use std::f64::consts::PI;
type Poly = BTreeMap<Vec<String>, (i64, i64)>; // coefficient (p, q) means (p + q*sqrt2)/4

fn win(al: [f64; 2], be: [f64; 2]) -> f64 {    // win chance on (|00> + |11>)/sqrt2
    let basis = |t: f64, a: usize| if a == 0 { (t.cos(), t.sin()) } else { (-t.sin(), t.cos()) };
    let mut tot = 0.0;
    for code in 0..16 {
        let (x, y, a, b) = (code >> 3 & 1, code >> 2 & 1, code >> 1 & 1, code & 1);
        let (u, v) = (basis(al[x], a), basis(be[y], b));
        let amp = (u.0 * v.0 + u.1 * v.1) / 2f64.sqrt();
        if (a ^ b) == (x & y) { tot += amp * amp / 4.0 }
    }
    tot
}
fn red(w: &[String], commute: bool) -> Vec<String> { // each observable squares to I
    let parts: Vec<Vec<String>> = if commute {
        ["A", "B"].iter().map(|s| w.iter().filter(|t| t.starts_with(s)).cloned().collect()).collect()
    } else { vec![w.to_vec()] };
    let mut out = Vec::new();
    for part in parts {
        let mut st: Vec<String> = Vec::new();
        for t in part { if st.last() == Some(&t) { st.pop(); } else { st.push(t) } }
        out.extend(st);
    }
    out
}
fn mul(pp: &Poly, qq: &Poly, commute: bool) -> Poly {
    let mut r = Poly::new();
    for (w1, &(p1, q1)) in pp { for (w2, &(p2, q2)) in qq {
        let (p, q) = (p1 * p2 + 2 * q1 * q2, p1 * q2 + q1 * p2);
        assert!(p % 4 == 0 && q % 4 == 0);
        let w = red(&[w1.clone(), w2.clone()].concat(), commute);
        let o = r.entry(w).or_insert((0, 0));
        *o = (o.0 + p / 4, o.1 + q / 4);
    } }
    r.retain(|_, c| *c != (0, 0)); r
}
fn add(pp: &Poly, qq: &Poly) -> Poly {
    let mut r = pp.clone();
    for (w, &(p, q)) in qq { let o = r.entry(w.clone()).or_insert((0, 0)); *o = (o.0 + p, o.1 + q); }
    r.retain(|_, c| *c != (0, 0)); r
}
fn poly(terms: &[(&[&str], i64, i64)]) -> Poly {
    terms.iter().map(|(w, p, q)| (w.iter().map(|s| s.to_string()).collect(), (*p, *q))).collect()
}
fn sos(c: bool) -> Poly {                       // (1/sqrt2) (X0^2 + X1^2)
    let x0 = poly(&[(&["A0"], 4, 0), (&["B0"], 0, -2), (&["B1"], 0, -2)]); // A0 - (B0 + B1)/sqrt2
    let x1 = poly(&[(&["A1"], 4, 0), (&["B0"], 0, -2), (&["B1"], 0, 2)]);  // A1 - (B0 - B1)/sqrt2
    mul(&poly(&[(&[], 0, 2)]), &add(&mul(&x0, &x0, c), &mul(&x1, &x1, c)), c)
}
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn gcd(a: u64, b: u64) -> u64 { if b == 0 { a } else { gcd(b, a % b) } }
fn isqrt(n: u64) -> u64 { let mut c = 0; while (c + 1) * (c + 1) <= n { c += 1 } c }
fn powmod(mut a: u64, mut e: u64, n: u64) -> u64 {
    let mut r = 1 % n; a %= n;
    while e > 0 { if e & 1 == 1 { r = r * a % n } a = a * a % n; e >>= 1 }
    r
}
fn trial(n: u64) -> bool { n > 1 && (2..=isqrt(n)).all(|d| n % d != 0) }
fn strong(n: u64, a: u64) -> bool {             // a passes the Miller-Rabin round for odd n
    let (mut d, mut s) = (n - 1, 0);
    while d % 2 == 0 { d /= 2; s += 1 }
    let mut x = powmod(a, d, n);
    for i in 0..s {
        if x == 1 || x == n - 1 { return x == n - 1 || i == 0 }
        x = x * x % n;
    }
    false
}
fn mr(n: u64) -> bool { n == 2 || n == 3 || (n > 3 && n % 2 == 1 && strong(n, 2) && strong(n, 3)) }
fn mulp(f: &[u64], g: &[u64], n: u64, r: usize) -> Vec<u64> { // modulo x^r - 1 and n
    let mut h = vec![0; r];
    for i in 0..r { for j in 0..r { h[(i + j) % r] = (h[(i + j) % r] + f[i] * g[j]) % n } }
    h
}
fn congruent(n: u64, r: u64, a: u64) -> bool {  // (x + a)^n = x^n + a modulo x^r - 1 and n?
    let ru = r as usize; let (mut res, mut base, mut e) = (vec![0u64; ru], vec![0u64; ru], n);
    res[0] = 1; base[0] = a % n; base[1] = 1;
    while e > 0 { if e & 1 == 1 { res = mulp(&res, &base, n, ru) } base = mulp(&base, &base, n, ru); e >>= 1; }
    let mut want = vec![0u64; ru]; want[(n % r) as usize] = 1; want[0] = (want[0] + a) % n;
    res == want
}
fn aks(n: u64) -> (bool, u64, String) {         // log2 n replaced by the bit length l
    let l = 64 - n.leading_zeros() as u64;
    if n < 2 || (2..=l).any(|b| (2..=isqrt(n)).any(|c| c.checked_pow(b as u32) == Some(n))) {
        return (false, 0, "below 2 or a perfect power".to_string());
    }
    let mut r = 2;                              // the least r with n's order mod r above l^2
    while gcd(r, n) != 1 || (1..=l * l).any(|k| powmod(n, k, r) == 1) { r += 1 }
    for a in 2..=r.min(n - 1) {
        let g = gcd(a, n);
        if 1 < g && g < n { return (false, r, format!("factor {} found", g)) }
    }
    if n <= r { return (true, r, "n <= r".to_string()) }
    let lim = (isqrt((1..r).filter(|&k| gcd(k, r) == 1).count() as u64) + 1) * l;
    for a in 1..=lim { if !congruent(n, r, a) { return (false, r, format!("(x + {})^n test failed", a)) } }
    (true, r, format!("{} polynomial tests passed", lim))
}
fn main() {
    let mut tables = Vec::new();                // all 16 answer tables a[x], b[y]
    for t in 0..16usize {
        let (a, b) = ([t >> 3 & 1, t >> 2 & 1], [t >> 1 & 1, t & 1]);
        tables.push((0..4).filter(|&q| (a[q >> 1] ^ b[q & 1]) == ((q >> 1) & (q & 1))).count());
    }
    let (classical, n3) = (*tables.iter().max().unwrap() as f64 / 4.0, tables.iter().filter(|&&w| w == 3).count());
    println!("classical: 16 answer tables, {} win 3 of 4, best {:.6}", n3, classical);
    let mut lower = BTreeMap::new();
    for m in [2usize, 4, 8, 16] {               // try every angle k*pi/m for each setting
        let g: Vec<f64> = (0..m).map(|k| k as f64 * PI / m as f64).collect();
        let mut b = 0.0f64;
        for &p in &g { for &q in &g { for &r in &g { for &s in &g { b = b.max(win([p, q], [r, s])) } } } }
        lower.insert(m, b);
        println!("lower bound, angles in steps of pi/{:<2}: best win {:.6}", m, b);
    }
    let best = win([0.0, PI / 4.0], [PI / 8.0, -PI / 8.0]);
    println!("strategy A at 0 or pi/4, B at pi/8 or -pi/8: win {:.12}", best);
    println!("<W> = 8 x (win - 1/2) = {:.6}; 2*sqrt2 = {:.6}", 8.0 * (best - 0.5), 2.0 * 2f64.sqrt());
    println!("cos^2(pi/8) = {:.12}, (2 + sqrt2)/4 = {:.12}", (PI / 8.0).cos().powi(2), (2.0 + 2f64.sqrt()) / 4.0);
    let lhs = poly(&[(&[], 0, 8), (&["A0", "B0"], -4, 0), (&["A0", "B1"], -4, 0),
                     (&["A1", "B0"], -4, 0), (&["A1", "B1"], 4, 0)]); // 2 sqrt2 I - W
    println!("sum of squares equals 2*sqrt2 - W, exactly: {}", yn(sos(true) == lhs));
    let upper = 0.5 + 2.0 * 2f64.sqrt() / 8.0;
    println!("upper bound for commuting operators: 1/2 + 2*sqrt2/8 = {:.12}", upper);
    println!("CHSH squeeze: |upper - lower| = {:.12}", (upper - lower[&16]).abs());
    println!("same identity if A's need not commute with B's: {}, {} terms against {}",
             yn(sos(false) == lhs), sos(false).len(), lhs.len());
    let agree = (1..=100u64).all(|n| trial(n) == mr(n) && mr(n) == aks(n).0);
    println!("n = 1 to {}: trial division, Miller-Rabin and AKS agree: {}; {} primes",
             100, yn(agree), (0..=100u64).filter(|&n| trial(n)).count());
    for n in [31u64, 561] {
        let (v, r, why) = aks(n);
        println!("AKS on {}: r = {}, {}, verdict {}", n, r, why, if v { "prime" } else { "composite" });
    }
    let alone: Vec<u64> = (1..4).filter(|&a| !congruent(561, aks(561).1, a)).collect(); // the factor step skipped
    println!("AKS on 561, factor step skipped: r = {}, the (x + a)^561 test fails for a = {:?}", aks(561).1, alone);
    let liars = (1..561).filter(|&a| strong(561, a)).count();
    println!("561 = 3 x 11 x 17: Fermat base 2 gives 2^560 mod 561 = {}; Miller-Rabin base 2 passes: {}",
             powmod(2, 560, 561), yn(strong(561, 2)));
    println!("561: strong liars {} of 560 bases, share {:.6} (bound 1/4)", liars, liars as f64 / 560.0);
    for n in [3usize, 4] {
        let mut a: Vec<Vec<i64>> = vec![vec![0]];
        for _ in 0..n {                         // A_n = [[A, I], [I, -A]]
            let k = a.len();
            a = (0..2 * k).map(|i| (0..2 * k).map(|j| {
                if i < k && j < k { a[i][j] } else if i >= k && j >= k { -a[i - k][j - k] }
                else { (i % k == j % k) as i64 } }).collect()).collect();
        }
        let k = a.len();
        let sq = (0..k).all(|i| (0..k).all(|j|
            (0..k).map(|t| a[i][t] * a[t][j]).sum::<i64>() == if i == j { n as i64 } else { 0 }));
        let maxdeg = |mask: usize| (0..k).filter(|&v| mask >> v & 1 == 1)
            .map(|v| (0..n).filter(|&b| mask >> (v ^ (1 << b)) & 1 == 1).count()).max().unwrap();
        let mindeg = |size: u32| (0..1usize << k).filter(|m| m.count_ones() == size)
            .map(|m| maxdeg(m)).min().unwrap();
        let (h1, h0) = (mindeg(k as u32 / 2 + 1), mindeg(k as u32 / 2));
        println!("{}-cube: A^2 = {} I: {}; any {} corners have max degree >= {} (sqrt {} = {:.6}); {} corners can have {}",
                 n, n, yn(sq), k / 2 + 1, h1, n, (n as f64).sqrt(), k / 2, h0);
        assert!(sq && h1 as f64 >= (n as f64).sqrt() && h0 == 0);
    }
    assert!(classical == 0.75 && n3 == 8);
    assert!((lower[&8] - (2.0 + 2f64.sqrt()) / 4.0).abs() < 1e-12 && (best - (PI / 8.0).cos().powi(2)).abs() < 1e-12);
    assert!(lower[&4] < lower[&8] && sos(true) == lhs && sos(false) != lhs && (upper - lower[&16]).abs() < 1e-12);
    assert!(agree && !aks(561).0 && aks(31) == (true, 29, "30 polynomial tests passed".to_string()) && alone.contains(&1));
    assert!(powmod(2, 560, 561) == 1 && liars <= 560 / 4);
    println!("ALL CHECKS PASS");
}
