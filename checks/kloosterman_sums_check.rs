// Kloosterman sums: K(1,1;13) = 5.2595 sits under Weil's 2 sqrt 13 = 7.2111 -- the same check as the
// Python, in Rust, no crates.  Road 1 adds the roots of unity directly.  Road 2 gets the fourth moment
// by counting solutions of x1 + x2 = x3 + x4, 1/x1 + 1/x2 = 1/x3 + 1/x4 by brute force.  Road 3 is the
// closed form 2p^3 - 3p^2 - 3p - 1.  Road 4 rebuilds the sums over GF(p^2) and counts points on the
// curves y^p - y = x + d/x, d = 1, 2, checking K_2 = 2p - K^2 behind Weil's bound, then puts the bound to work.
use std::collections::HashMap;
use std::f64::consts::PI;
type G = (i64, i64);

fn isprime(n: i64) -> bool { n > 1 && (2..).take_while(|d| d * d <= n).all(|d| n % d != 0) }
fn inv(x: i64, q: i64) -> Option<i64> {          // inverse mod q by Euclid's algorithm, or None
    let (mut r0, mut r1, mut s0, mut s1) = (q, x.rem_euclid(q), 0i64, 1i64);
    while r1 != 0 { let k = r0 / r1; (r0, r1, s0, s1) = (r1, r0 - k * r1, s1, s0 - k * s1); }
    if r0 == 1 { Some(s0.rem_euclid(q)) } else { None }
}
fn ks(a: i64, b: i64, q: i64, imag: bool) -> f64 { // K(a, b; q) = sum over units x of zeta_q^(a x + b/x)
    let mut t = 0.0;
    for x in 1..q { if let Some(xi) = inv(x, q) {
        let th = 2.0 * PI * ((a * x + b * xi).rem_euclid(q)) as f64 / q as f64;
        t += if imag { th.sin() } else { th.cos() };
    } }
    t
}
fn k(a: i64, b: i64, q: i64) -> f64 { ks(a, b, q, false) }
fn ktab(p: i64) -> Vec<f64> {                    // K(a, 1; p) for a = 0..p-1, from one cosine table
    let c: Vec<f64> = (0..p).map(|t| (2.0 * PI * t as f64 / p as f64).cos()).collect();
    let iv: Vec<i64> = (0..p).map(|x| if x == 0 { 0 } else { inv(x, p).unwrap() }).collect();
    (0..p).map(|a| (1..p).map(|x| c[((a * x + iv[x as usize]) % p) as usize]).sum()).collect()
}
fn closed(p: i64) -> i64 { 2 * p * p * p - 3 * p * p - 3 * p - 1 }
fn f4(x: f64) -> String { format!("{:.4}", if x.abs() > 5e-5 { x } else { 0.0 }) }
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() > 5e-7 { x } else { 0.0 }) }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn mom(v: &[f64], e: i32) -> f64 { v.iter().map(|x| x.powi(e)).sum() }
fn nsol(p: i64) -> (i64, i64) {                         // brute force: x1 + x2 = x3 + x4 and 1/x1 + 1/x2 = 1/x3 + 1/x4
    let iv: Vec<i64> = (0..p).map(|x| if x == 0 { 0 } else { inv(x, p).unwrap() }).collect();
    let mut n = (0, 0);                          // (solutions with x1 + x2 != 0, solutions with x1 + x2 = 0)
    for x1 in 1..p { for x2 in 1..p { for x3 in 1..p {
        let x4 = (x1 + x2 - x3).rem_euclid(p);
        if x4 != 0 && (iv[x1 as usize] + iv[x2 as usize] - iv[x3 as usize] - iv[x4 as usize]).rem_euclid(p) == 0 { if (x1 + x2) % p == 0 { n.1 += 1 } else { n.0 += 1 } }
    } } }
    n
}
struct F { p: i64, d: i64 }                      // GF(p^2) = GF(p)[w], w^2 = d, d the least non-square
impl F {
    fn new(p: i64) -> F { let d = (2..p).find(|&d| modpow(d, (p - 1) / 2, p) == p - 1).unwrap(); F { p, d } }
    fn mul(&self, u: G, v: G) -> G { ((u.0 * v.0 + self.d * u.1 * v.1) % self.p, (u.0 * v.1 + u.1 * v.0) % self.p) }
    fn pw(&self, mut u: G, mut e: i64) -> G {
        let mut r = (1, 0);
        while e > 0 { if e & 1 == 1 { r = self.mul(r, u); } u = self.mul(u, u); e >>= 1; } r
    }
    fn els(&self) -> Vec<G> { (0..self.p).flat_map(|u| (0..self.p).map(move |v| (u, v))).collect() }
}
fn modpow(mut b: i64, mut e: i64, m: i64) -> i64 {
    let mut r = 1 % m; b %= m;
    while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r
}
fn k2(p: i64, c: i64) -> f64 {                   // K_2(c, c) = sum over z in GF(p^2)* of zeta_p^(c Tr(z + 1/z))
    let f = F::new(p); let mut s = 0.0;
    for z in f.els().into_iter().skip(1) {
        let zi = f.pw(z, p * p - 2); s += (2.0 * PI * (c * 2 * (z.0 + zi.0)) as f64 / p as f64).cos();
    }
    s
}
fn curve(p: i64, e: i64) -> i64 {                // points (x, y), x != 0, on y^p - y = x + e/x over GF(p^2)
    let f = F::new(p); let mut m: HashMap<G, i64> = HashMap::new();
    for y in f.els() { let u = f.pw(y, p); *m.entry(((u.0 - y.0).rem_euclid(p), (u.1 - y.1).rem_euclid(p))).or_insert(0) += 1; }
    let mut tot = 0;
    for x in f.els().into_iter().skip(1) { let xi = f.pw(x, p * p - 2); tot += m.get(&((x.0 + e * xi.0) % p, (x.1 + e * xi.1) % p)).unwrap_or(&0); }
    tot
}
fn main() {
    let p = 13i64;
    let iv: Vec<i64> = (1..p).map(|x| inv(x, p).unwrap()).collect();
    let js = |v: &[i64]| v.iter().map(|t| t.to_string()).collect::<Vec<_>>().join(" ");
    println!("x = 1..12, 1/x mod 13: {}", js(&iv));
    let t: Vec<i64> = (1..p).map(|x| (x + iv[(x - 1) as usize]) % p).collect();
    println!("t = x + 1/x mod 13:    {}", js(&t));
    let mut kg = 0.0;
    for g in [vec![0i64], vec![1, 12], vec![2, 11], vec![4, 9]] {
        let n = t.iter().filter(|x| g.contains(x)).count() as f64; let c = (2.0 * PI * g[0] as f64 / p as f64).cos(); kg += n * c;
        let gs = format!("[{}]", g.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "));
        println!("  t in {:<8} {} terms, cos(2 pi t/13) = {:>9}, adds {:>9}", gs, n, f6(c), f6(n * c));
    }
    let k13 = k(1, 1, p);
    println!("K(1,1;13) grouped = {};  direct = {};  imaginary part = {}", f6(kg), f6(k13), f6(ks(1, 1, p, true)));
    println!("bounds at 13: Weil 2 sqrt p = {};  Kloosterman 2^(1/4) p^(3/4) = {};  trivial p - 1 = 12", f6(2.0 * (p as f64).sqrt()), f6((2.0 * (p * p * p) as f64).powf(0.25)));
    let k101 = k(1, 1, 101);
    println!("K(1,1;101) = {};  Weil {};  Kloosterman {};  trivial 100", f6(k101), f6(2.0 * 101f64.sqrt()), f6((2.0 * 1030301.0f64).powf(0.25)));
    assert!((kg - k13).abs() < 1e-12 && ks(1, 1, p, true).abs() < 1e-12 && (k13 - 5.2595).abs() < 1e-4 && (k101 - 1.5258).abs() < 1e-4);
    let tt = ktab(p);
    println!("K(a,1;13), a = 1..12: {}", tt[1..].iter().map(|&v| f4(v)).collect::<Vec<_>>().join(" "));
    let sym = (1..p).all(|a| (k(a, 1, p) - k(1, a, p)).abs() < 1e-12);
    println!("K(a,1;13) = K(1,a;13) for every a: {};  largest |K(a,1;13)| = {}", yn(sym), f4(tt[1..].iter().fold(0.0f64, |m, v| m.max(v.abs()))));
    let s4 = mom(&tt[1..], 4);
    println!("fourth moment p = 13: sum of K(a,1;13)^4 = {};  2p^3 - 3p^2 - 3p - 1 = {};  fourth root {}", f6(s4), closed(13), f4(s4.powf(0.25)));
    let s7 = mom(&ktab(7)[1..], 4);
    println!("fourth moment p = 7: {};  closed form {};  K(1,1;7) = {}", f6(s7), closed(7), f6(k(1, 1, 7)));
    assert!(s4.round() == 3847.0 && (s4 - 3847.0).abs() < 1e-6 && s7.round() == 517.0 && (s7 - 517.0).abs() < 1e-6);
    for q in [7i64, 13] {
        let (n0, n1) = nsol(q); let n = n0 + n1; let s = (q * q * n - (q - 1).pow(4) - 2 * (q - 1)) / (q - 1);
        println!("p = {}: solutions N = {} (sum s != 0) + {} (s = 0) = {};  3(p-1)(p-2) = {}", q, n0, n1, n, 3 * (q - 1) * (q - 2));
        println!("  p^2 N = {};  (p-1)^4 = {};  2(p-1) = {};  (p^2 N - (p-1)^4 - 2(p-1))/(p-1) = {}", q * q * n, (q - 1).pow(4), 2 * (q - 1), s);
        assert!(n0 == (q - 1) * (2 * q - 5) && n1 == (q - 1).pow(2) && n == 3 * (q - 1) * (q - 2) && s == closed(q));
    }
    let pr: Vec<i64> = (3..60).filter(|&q| isprime(q)).collect();
    let okn = pr.iter().all(|&q| { let n = nsol(q); n.0 + n.1 == 3 * (q - 1) * (q - 2) });
    let pr2: Vec<i64> = (3..200).filter(|&q| isprime(q)).collect();
    let ok4 = pr2.iter().all(|&q| (mom(&ktab(q)[1..], 4) - closed(q) as f64).abs() < 1e-6);
    println!("brute-force N = 3(p-1)(p-2) for all {} odd primes below 60: {}", pr.len(), yn(okn));
    println!("sum of K^4 = 2p^3 - 3p^2 - 3p - 1 for all {} odd primes below 200: {}", pr2.len(), yn(ok4));
    assert!(okn && ok4);
    let (mut worst, mut wk, mut cnt) = (0.0f64, (0i64, 0i64, 0.0f64), 0i64);   // Weil and Kloosterman bounds
    for q in (3..400).filter(|&q| isprime(q)) {
        for (a, v) in ktab(q).into_iter().enumerate().skip(1) {
            cnt += 1; let r = v.abs() / (2.0 * (q as f64).sqrt());
            if r > worst { worst = r; wk = (a as i64, q, v); }
        }
    }
    println!("all {} sums K(a,1;p), odd p below 400: largest |K|/(2 sqrt p) = {}, at a = {}, p = {}, K = {}", cnt, f6(worst), wk.0, wk.1, f6(wk.2));
    assert!(worst < 1.0);
    let v2 = k2(13, 1);
    println!("over GF(169): K_2(1,1) = {};  2p - K(1,1;13)^2 = {}", f6(v2), f6(26.0 - k13 * k13));
    let okh = pr[..10].iter().all(|&q| (k2(q, 1) - (2.0 * q as f64 - k(1, 1, q).powi(2))).abs() < 1e-9);
    println!("K_2 = 2p - K^2 for all odd primes up to {}: {}", pr[9], yn(okh));
    assert!((v2 - (26.0 - k13 * k13)).abs() < 1e-9 && okh);
    let n1 = p * (1..p).filter(|&x| (x + inv(x, p).unwrap()) % p == 0).count() as i64;
    let r1 = (p - 1) as f64 + (1..p).map(|c| k(c, c, p)).sum::<f64>();
    println!("curve over GF(13): points with x != 0: {};  p - 1 + sum of K(c,c;13) = {}", n1, f6(r1));
    let nc = curve(p, 1);
    let r2 = (p * p - 1) as f64 + (1..p).map(|c| k2(p, c)).sum::<f64>();
    let r3 = (p * p - 1) as f64 + (1..p).map(|c| 2.0 * p as f64 - k(c, c, p).powi(2)).sum::<f64>();
    println!("curve over GF(169): brute count {};  p^2 - 1 + sum K_2(c,c) = {};  p^2 - 1 + sum (2p - K(c,c)^2) = {}", nc, f6(r2), f6(r3));
    println!("  gap from p^2 - 1 = {};  Weil allows 2(p-1)p = {}", nc - p * p + 1, 2 * (p - 1) * p);
    assert!((nc as f64 - r2).abs() < 1e-6 && (nc as f64 - r3).abs() < 1e-6 && (nc - p * p + 1).abs() <= 2 * (p - 1) * p && (n1 as f64 - r1).abs() < 1e-9);
    let nd = curve(p, 2); let rd = (p * p - 1) as f64 + (1..p).map(|c| 2.0 * p as f64 - k(c, 2 * c, p).powi(2)).sum::<f64>(); // d = 2, a non-square
    let cls = |e: i64| { let mut v: Vec<String> = (1..p).map(|c| f4(k(c, e * c, p))).collect(); v.sort_by(|x, y| x.parse::<f64>().unwrap().total_cmp(&y.parse::<f64>().unwrap())); v.dedup(); v };
    let (sq, ns) = (cls(1), cls(2));
    println!("K(c,c;13) takes {} values: {};  K(c,2c;13) takes the other {}: {}", sq.len(), sq.join(" "), ns.len(), ns.join(" "));
    println!("curve y^p - y = x + 2/x over GF(169): brute count {};  p^2 - 1 + sum (2p - K(c,2c)^2) = {}", nd, f6(rd));
    let mut all: Vec<String> = tt[1..].iter().map(|&x| f4(x)).collect(); all.sort(); all.dedup();
    let mut both: Vec<String> = sq.iter().chain(ns.iter()).cloned().collect(); both.sort();
    assert!((nd as f64 - rd).abs() < 1e-6 && both == all && !sq.iter().any(|x| ns.contains(x)));
    let q = 100003i64; let am = (q - 1) / 2;       // a count the bound pins down
    let na = (1..=am).filter(|&x| inv(x, q).unwrap() <= am).count();
    let sa = ((1..q).map(|a| ((PI * a as f64 * am as f64 / q as f64).sin() / (PI * a as f64 / q as f64).sin()).abs()).sum::<f64>() / q as f64).powi(2);
    let (ex, e0) = ((am * am) as f64 / q as f64, (am * am) as f64 / (q * q) as f64);
    let (ew, ek) = (e0 + 2.0 * (q as f64).sqrt() * sa, e0 + (2.0 * (q * q * q) as f64).powf(0.25) * sa);
    println!("mod {}: x = 1..{} with 1/x also <= {}: {};  expected {}^2/{} = {};  error cap from Weil {}, from Kloosterman {}", q, am, am, na, am, q, f4(ex), f4(ew), f4(ek));
    assert!((na as f64 - ex).abs() <= ew && ew < ex && ex < am as f64 && (am as f64) < ek);
    let s2 = mom(&tt[1..], 2);                    // what breaks
    println!("second moment p = 13: {} = p^2 - p - 1 = {};  bound sqrt = {}, worse than trivial 12", f6(s2), p * p - p - 1, f4(s2.sqrt()));
    println!("p divides a and b: K(0,0;13) = {};  p divides a only: K(0,1;13) = {}", f4(k(0, 0, p)), f4(k(0, 1, p)));
    let cq = (2..400).find(|&q| k(1, 1, q).abs() > 2.0 * (q as f64).sqrt()).unwrap();
    println!("smallest modulus with |K(1,1;q)| > 2 sqrt q: q = {} = 9 x 13, K = {} against {};  caps multiplied 2 sqrt 9 x 2 sqrt 13 = {}", cq, f4(k(1, 1, cq)), f4(2.0 * (cq as f64).sqrt()), f4(4.0 * (cq as f64).sqrt()));
    println!("fourth moment with a = 0 kept: {}", f6(mom(&tt, 4)));
    assert!((s2 - 155.0).abs() < 1e-9 && cq == 117 && k(1, 1, cq).abs() < 4.0 * (cq as f64).sqrt() && (k(0, 0, p) - 12.0).abs() < 1e-12 && (mom(&tt, 4) - 3848.0).abs() < 1e-6);
    println!("try: q = 176: K = {} against {};  sixth moment p = 13: {}, (2 sqrt 13)^6 = {}", f4(k(1, 1, 176)), f4(2.0 * 176f64.sqrt()), f6(mom(&tt[1..], 6)), 64 * 13i64.pow(3));
    for q in [11i64, 1009, 10007] { println!("try: K(1,1;{}) = {};  2 sqrt p = {}", q, f4(k(1, 1, q)), f4(2.0 * (q as f64).sqrt())); }
    let cp: Vec<i64> = (3..102).filter(|&q| isprime(q)).collect();
    println!("chart, primes: {}", cp.iter().map(|q| q.to_string()).collect::<Vec<_>>().join(", "));
    println!("chart, K(1,1;p): {}", cp.iter().map(|&q| format!("{:.2}", k(1, 1, q))).collect::<Vec<_>>().join(", "));
    println!("chart, 2 sqrt p: {}", cp.iter().map(|&q| format!("{:.2}", 2.0 * (q as f64).sqrt())).collect::<Vec<_>>().join(", "));
    println!("chart, -2 sqrt p: {}", cp.iter().map(|&q| format!("{:.2}", -2.0 * (q as f64).sqrt())).collect::<Vec<_>>().join(", "));
    println!("ALL CHECKS PASS");
}
