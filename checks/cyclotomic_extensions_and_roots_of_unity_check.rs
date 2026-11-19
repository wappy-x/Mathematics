// Cyclotomic fields -- the same check as the Python, in Rust.  No crates.
// The twelfth roots of unity.  Polynomials are integer vectors, lowest power
// first.  Phi_12 is built two ways (exact division, and a product over the
// primitive roots in floating point); the symmetries are found two ways (which
// substitutions x -> x^k keep Phi_12 at zero, and which k share no factor with 12).
type P = Vec<i64>;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn cm(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cis(t: f64) -> C { C { re: t.cos(), im: t.sin() } }
fn r6(x: f64) -> f64 { (x * 1e6).round() / 1e6 + 0.0 }
fn num(z: C) -> String { let (re, im) = (r6(z.re), r6(z.im)); format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs()) }

fn trim(mut p: P) -> P { while p.len() > 1 && *p.last().unwrap() == 0 { p.pop(); } p }
fn md(p: P, m: i64) -> P { if m > 0 { p.iter().map(|c| c.rem_euclid(m)).collect() } else { p } }
fn mul(p: &P, q: &P, m: i64) -> P {
    let mut out = vec![0i64; p.len() + q.len() - 1];
    for (i, a) in p.iter().enumerate() { for (j, b) in q.iter().enumerate() { out[i + j] += a * b; } }
    trim(md(out, m))
}
fn divmod_monic(p: &P, d: &P, m: i64) -> (P, P) {     // long division by a monic d
    let mut p = p.clone();
    let mut q = vec![0i64; std::cmp::max(1, p.len() as i64 - d.len() as i64 + 1) as usize];
    for s in (0..(p.len() + 1).saturating_sub(d.len())).rev() {
        let c = p[s + d.len() - 1];
        q[s] = c;
        for (j, b) in d.iter().enumerate() { p[s + j] -= c * b; }
    }
    let p = md(p, m);
    let r: P = if d.len() > 1 { p[..std::cmp::min(d.len() - 1, p.len())].to_vec() } else { vec![] };
    (trim(q), trim(if r.is_empty() { vec![0] } else { r }))
}
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }  // Euclid
fn cyclo(n: usize) -> P {                             // road one: x^n - 1 over Phi_d, d | n, d < n
    let mut p = vec![0i64; n + 1]; p[0] = -1; p[n] = 1;
    for d in 1..n { if n % d == 0 { let (q, r) = divmod_monic(&p, &cyclo(d), 0); assert!(r == vec![0]); p = q; } }
    p
}
fn units(n: i64) -> Vec<i64> { (1..n).filter(|&k| gcd(k, n) == 1).collect() }
fn by_roots(n: i64) -> P {                            // road two: product of (x - zeta^k), k coprime to n
    let mut p = vec![C { re: 1.0, im: 0.0 }];
    for k in units(n).into_iter().chain(if n == 1 { vec![1] } else { vec![] }) {
        let z = cis(2.0 * std::f64::consts::PI * k as f64 / n as f64);
        let mut q = Vec::new();
        for i in 0..=p.len() {
            let prev = if i > 0 { p[i - 1] } else { C { re: 0.0, im: 0.0 } };
            let cur = if i < p.len() { cm(z, p[i]) } else { C { re: 0.0, im: 0.0 } };
            q.push(C { re: prev.re - cur.re, im: prev.im - cur.im });
        }
        p = q;
    }
    p.iter().map(|c| c.re.round() as i64).collect()
}
fn modpow(a: i64, mut e: i64, n: i64) -> i64 { let (mut out, mut b) = (1 % n, a.rem_euclid(n)); while e > 0 { if e & 1 == 1 { out = out * b % n; } b = b * b % n; e >>= 1; } out }
fn order(a: i64, n: i64) -> i64 { (1..=n).find(|&e| modpow(a, e, n) == 1).unwrap() }
fn show(p: &P) -> String {
    let mut parts = Vec::new();
    for (j, (i, &c)) in p.iter().enumerate().rev().filter(|(_, &c)| c != 0).enumerate() {
        let coef = if c.abs() == 1 && i > 0 { String::new() } else { c.abs().to_string() };
        let t = format!("{}{}{}", coef, if i > 0 { "x" } else { "" }, if i > 1 { format!("^{}", i) } else { String::new() });
        let sign = if j > 0 { if c < 0 { "- " } else { "+ " } } else if c < 0 { "-" } else { "" };
        parts.push(format!("{}{}", sign, t));
    }
    parts.join(" ")
}
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

struct F { phi: P, zeta: C }
impl F {
    fn red(&self, p: &P) -> P { divmod_monic(p, &self.phi, 0).1 }    // reduce modulo Phi_12: work in Q(zeta)
    fn xp(&self, k: i64) -> P { let mut p = vec![0i64; k as usize + 1]; p[k as usize] = 1; self.red(&p) }
    fn sub(&self, p: &P, k: i64) -> P {                               // apply x -> x^k, then reduce
        let mut out = vec![0i64; 1];
        for (i, &c) in p.iter().enumerate() {
            let t = mul(&vec![c], &self.xp(k * i as i64), 0);
            let n = std::cmp::max(out.len(), t.len());
            out = (0..n).map(|j| out.get(j).copied().unwrap_or(0) + t.get(j).copied().unwrap_or(0)).collect();
        }
        self.red(&trim(out))
    }
    fn val(&self, p: &P) -> C {
        let (mut s, mut z) = (C { re: 0.0, im: 0.0 }, C { re: 1.0, im: 0.0 });
        for &c in p { s = C { re: s.re + c as f64 * z.re, im: s.im + c as f64 * z.im }; z = cm(z, self.zeta); }
        s
    }
}
fn powmod_x(mut e: i64, p: i64, phi: &P) -> P {      // x^e modulo (Phi_12, p), by repeated squaring
    let (mut out, mut b): (P, P) = (vec![1], vec![0, 1]);
    while e > 0 {
        if e & 1 == 1 { out = divmod_monic(&mul(&out, &b, p), phi, p).1; }
        b = divmod_monic(&mul(&b, &b, p), phi, p).1;
        e >>= 1;
    }
    out
}

fn main() {
    let n = 12i64; let f = F { phi: cyclo(12), zeta: cis(2.0 * std::f64::consts::PI / 12.0) };
    let phi = f.phi.clone();
    println!("zeta = e^(2 pi i/12) = {}; exponents sharing no factor with 12: {:?}; phi(12) = {}", num(f.zeta), units(n), units(n).len());
    for d in [1i64, 2, 3, 4, 6, 12] { println!("  hours of order {:>2}: {:?}; Phi_{} = {}", d, (0..n).filter(|&k| n / gcd(k, n) == d).collect::<Vec<i64>>(), d, show(&cyclo(d as usize))); }
    println!("Phi_12 by dividing x^12 - 1 by Phi_1 Phi_2 Phi_3 Phi_4 Phi_6: {}", show(&phi));
    println!("Phi_12 by multiplying out (x - zeta^k), k = 1, 5, 7, 11: {}", show(&by_roots(n)));
    println!("(x^6 + 1) / (x^2 + 1) = {}", show(&divmod_monic(&vec![1, 0, 0, 0, 0, 0, 1], &vec![1, 0, 1], 0).0));
    let at_m1: i64 = phi.iter().enumerate().map(|(i, c)| if i % 2 == 0 { *c } else { -*c }).sum();
    println!("zeta^2 = {}, zeta^4 = {}; Phi_12(zeta) = {}; Phi_12(1) = {}, Phi_12(-1) = {}", num(cm(f.zeta, f.zeta)), num(cm(cm(f.zeta, f.zeta), cm(f.zeta, f.zeta))), num(f.val(&phi)), phi.iter().sum::<i64>(), at_m1);
    let mut quads = 0;
    for a in -5..6 { for c in -5..6 { for &b in &[1i64, -1] { for &d in &[1i64, -1] {
        if mul(&vec![b, a, 1], &vec![d, c, 1], 0) == phi { quads += 1; } } } } }
    println!("factorisations into two integer quadratics (a, c from -5 to 5): {}; b = e = 1 or -1 forces a^2 = {}; so degree [Q(zeta):Q] = {}", quads, [1i64, -1].iter().map(|b| (b + b - phi[2]).to_string()).collect::<Vec<_>>().join(" or "), phi.len() - 1);
    let degs: Vec<usize> = (1..13).map(|k| cyclo(k).len() - 1).collect();
    let phis: Vec<usize> = (1..13).map(|k| if k > 1 { units(k).len() } else { 1 }).collect();
    println!("n = 1..12, degree of Phi_n: {:?}; phi(n): {:?}; phi(17) = {}", degs, phis, units(17).len());
    let keeps: Vec<i64> = (0..n).filter(|&k| f.sub(&phi, k) == vec![0]).collect();
    println!("substitutions x -> x^k that keep Phi_12 at zero: k = {:?}", keeps);
    let s2 = f.sub(&phi, 2);
    println!("mistake 2, x -> x^2: Phi_12(zeta^2) reduces to {}, value {}", show(&s2), num(f.val(&s2)));
    let compose_ok = keeps.iter().all(|&a| keeps.iter().all(|&b| f.sub(&f.xp(a), b) == f.xp(a * b % n)));
    println!("applying k = a then k = b equals k = ab mod 12, for all 16 pairs: {}; squares {:?}", yn(compose_ok), keeps.iter().map(|a| a * a).collect::<Vec<i64>>());
    for &a in &keeps {
        let row: Vec<i64> = keeps.iter().map(|&b| a * b % n).collect();
        println!("  {:>2} x {:?} mod 12 = {:?}; order {}", a, keeps, row, order(a, n));
    }
    let mut z11 = vec![0i64; 12]; z11[1] = 1; z11[11] = 1;  // zeta + zeta^11
    let alpha: Vec<(i64, P, &str, i64)> = vec![(11, z11, "zeta + zeta^11", 3), (5, vec![0, 0, 0, 1], "zeta^3", -1), (7, vec![-1, 0, 2], "2 zeta^2 - 1", -3)];
    let mut squares_ok = true;
    for (k, p, name, want) in &alpha {
        let p = f.red(p);
        let neg: P = p.iter().map(|c| -c).collect();
        let signs: Vec<&str> = keeps.iter().map(|&j| { let s = f.sub(&p, j); if s == p { "fixed" } else if s == neg { "negated" } else { "moved" } }).collect();
        let sq = f.red(&mul(&p, &p, 0));
        squares_ok &= sq == vec![*want];
        println!("fixed by k = {:>2}: {} = {}; square = {}; under k = {:?}: {}", k, name, num(f.val(&p)), show(&sq), keeps, signs.join(", "));
    }
    let mut subgroups: Vec<Vec<i64>> = Vec::new();
    for r in 1..5u32 { for mask in 0u32..16 { if mask.count_ones() == r {
        let s: Vec<i64> = (0..4).filter(|i| mask >> i & 1 == 1).map(|i| keeps[i]).collect();
        if s.contains(&1) && s.iter().all(|a| s.iter().all(|b| s.contains(&(a * b % n)))) { subgroups.push(s); } } } }
    println!("subgroups of (Z mod 12)^x: {:?}; count {}", subgroups, subgroups.len());
    let twos = |m: i64| units(m).iter().filter(|&&a| order(a, m) == 2).count();
    for &m in &[5i64, 8, 12] {
        println!("n = {:>2}: Phi_n = {}; largest order {}; elements of order 2 (quadratic subfields) {}",
                 m, show(&cyclo(m as usize)), units(m).iter().map(|&a| order(a, m)).max().unwrap(), twos(m));
    }
    let primes: Vec<i64> = (5..101).filter(|&p| (2..p).all(|q| p % q != 0)).collect();
    let roots: Vec<usize> = primes.iter().map(|&p| (0..p).filter(|&t| phi.iter().enumerate()
        .map(|(i, c)| c * modpow(t, i as i64, p)).sum::<i64>().rem_euclid(p) == 0).count()).collect();
    let four: Vec<i64> = primes.iter().zip(&roots).filter(|(_, &r)| r == 4).map(|(&p, _)| p).collect();
    let mut res: Vec<i64> = four.iter().map(|p| p % 12).collect(); res.sort(); res.dedup();
    println!("primes 5 to 100 where Phi_12 has 4 roots mod p: {:?}; residues mod 12: {:?}", four, res);
    println!("primes with 0 roots: {}; other root counts: {}; largest order of p mod 12: {}", roots.iter().filter(|&&r| r == 0).count(),
             roots.iter().filter(|&&r| r != 0 && r != 4).count(), primes.iter().map(|&p| order(p % 12, 12)).max().unwrap());
    println!("x^(p^2) = x modulo (Phi_12, p) for every one of the {} primes: {}", primes.len(), yn(primes.iter().all(|&p| powmod_x(p * p, p, &phi) == vec![0, 1])));
    let mut f5: Vec<(i64, i64)> = Vec::new();
    for a in 0..5 { for b in 0..5 { if divmod_monic(&phi, &vec![b, a, 1], 5).1 == vec![0] { f5.push((a, b)); } } }
    println!("mod 5 the monic quadratic factors x^2 + ax + b are (a, b) = {:?}; degree over GF(5) = {}", f5, order(5, 12));
    let mut x12 = vec![0i64; 13]; x12[0] = -1; x12[12] = 1;
    let pd: Vec<usize> = [2, 3, 4, 6, 12].iter().map(|&d| degs[d - 1]).collect();
    println!("mistake 1, 12 treated as prime: (x^12 - 1)/(x - 1) has degree {}, = Phi_2 Phi_3 Phi_4 Phi_6 Phi_12, degrees {:?}",
             divmod_monic(&x12, &vec![-1, 1], 0).0.len() - 1, pd);
    println!("mistake 3, group taken as cyclic like n = 5: {} quadratic subfield predicted; true count {}", twos(5), keeps.iter().filter(|&&a| order(a, n) == 2).count());
    assert!(phi == by_roots(n) && phi == vec![1, 0, -1, 0, 1]);              // two roads to Phi_12
    let v = f.val(&phi); assert!(quads == 0 && (v.re * v.re + v.im * v.im).sqrt() < 1e-12);       // zeta is a root; no factorisation
    assert!(keeps == units(n) && compose_ok);                                 // two roads to the symmetries
    assert!(degs == phis && squares_ok);                                      // degree = phi(n); the three squares
    assert!(four == primes.iter().copied().filter(|p| p % 12 == 1).collect::<Vec<i64>>() && f5 == vec![(2, 4), (3, 4)]);
    assert!(primes.iter().all(|&p| powmod_x(p * p, p, &phi) == vec![0, 1]));   // every factor mod p has degree 1 or 2
    println!("ALL CHECKS PASS");
}
