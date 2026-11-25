// Adeles and ideles of Q: the product formula, A = Q + ([0,1) x Z-hat), and the idele class group.
// Every number is an exact fraction (i128 with checked products); std only.
use std::collections::BTreeSet;
use std::fmt;

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
#[derive(Clone, Copy, PartialEq, Eq, PartialOrd, Ord)]
struct Q { n: i128, d: i128 }
fn q(n: i128, d: i128) -> Q {
    let g = gcd(n, d) * if d < 0 { -1 } else { 1 };
    Q { n: n / g, d: d / g }
}
fn mul(a: i128, b: i128) -> i128 { a.checked_mul(b).expect("overflow") }
impl Q {
    fn add(self, o: Q) -> Q { q(mul(self.n, o.d) + mul(o.n, self.d), mul(self.d, o.d)) }
    fn sub(self, o: Q) -> Q { self.add(Q { n: -o.n, d: o.d }) }
    fn times(self, o: Q) -> Q { q(mul(self.n, o.n), mul(self.d, o.d)) }
    fn div(self, o: Q) -> Q { q(mul(self.n, o.d), mul(self.d, o.n)) }
    fn abs(self) -> Q { Q { n: self.n.abs(), d: self.d } }
    fn lt(self, o: Q) -> bool { mul(self.n, o.d) < mul(o.n, self.d) }
}
impl fmt::Display for Q {
    fn fmt(&self, f: &mut fmt::Formatter) -> fmt::Result {
        if self.d == 1 { write!(f, "{}", self.n) } else { write!(f, "{}/{}", self.n, self.d) }
    }
}
fn primes_upto(n: usize) -> Vec<i128> {
    let mut s = vec![true; n + 1]; s[0] = false; s[1] = false;
    let mut i = 2;
    while i * i <= n { if s[i] { let mut j = i * i; while j <= n { s[j] = false; j += i; } } i += 1; }
    (0..=n).filter(|&i| s[i]).map(|i| i as i128).collect()
}
fn vp(x: Q, p: i128) -> i32 {
    let (mut n, mut d, mut v) = (x.n, x.d, 0);
    while n % p == 0 { n /= p; v += 1; }
    while d % p == 0 { d /= p; v -= 1; }
    v
}
fn ppow(p: i128, k: i32) -> Q { let m = p.pow(k.unsigned_abs()); if k >= 0 { q(m, 1) } else { q(1, m) } }
fn size(x: Q, v: i128) -> Q { if v == 0 { x.abs() } else { ppow(v, -vp(x, v)) } }
fn inv_mod(a: i128, m: i128) -> i128 {
    let (mut r0, mut r1, mut s0, mut s1) = (a.rem_euclid(m), m, 1i128, 0i128);
    while r1 != 0 { let t = r0 / r1; (r0, r1) = (r1, r0 - t * r1); (s0, s1) = (s1, s0 - t * s1); }
    assert!(r0 == 1); s0.rem_euclid(m)
}
fn mod_of(x: Q, pk: i128) -> i128 { (x.n.rem_euclid(pk) * inv_mod(x.d, pk)).rem_euclid(pk) }
fn principal_part(a: Q, p: i128) -> Q {
    let k = -vp(a, p);
    if k <= 0 { return q(0, 1); }
    let pk = p.pow(k as u32);
    q(mod_of(a.times(q(pk, 1)), pk), pk)
}
fn idele_class(a_inf: Q, listed: &[(i128, Q)], other: Q) -> (Q, Q, Q, i128) {
    let mut qq = q(if a_inf.n > 0 { 1 } else { -1 }, 1);
    for &(p, y) in listed { qq = qq.times(ppow(p, vp(y, p))); }
    let unit = |p: i128| listed.iter().find(|t| t.0 == p).map(|t| t.1).unwrap_or(other).div(qq);
    for p in listed.iter().map(|t| t.0).chain([5]) { assert!(vp(unit(p), p) == 0); }
    let (r4, r5) = (mod_of(unit(2), 4), mod_of(unit(5), 5));
    let u = (0..20).find(|z| z % 4 == r4 && z % 5 == r5).unwrap();
    let mut norm = a_inf.abs();
    for &(p, y) in listed { norm = norm.times(size(y, p)); }
    (qq, a_inf.div(qq), norm, u)
}
fn main() {
    let pr = primes_upto(10000);
    println!("== product formula ==");
    let x = q(7, 12);
    let sz: Vec<(i128, Q)> = [2, 3, 7, 0].iter().map(|&v| (v, size(x, v))).collect();
    let parts: Vec<String> = sz.iter().map(|(v, s)| format!("|x|_{} = {}", if *v == 0 { "inf".to_string() } else { v.to_string() }, s)).collect();
    println!("7/12: {}", parts.join(", "));
    let fin = sz[0].1.times(sz[1].1).times(sz[2].1);
    let prod = fin.times(sz[3].1);
    println!("product over all places = {}; finite places only = {}", prod, fin);
    assert!(prod == q(1, 1) && fin == q(1, 1).div(x) && sz[0].1 == q(4, 1) && sz[1].1 == q(3, 1));
    let (mut count, mut bad) = (0, 0);
    for a in -60i128..=60 {
        for b in 1i128..=60 {
            if a == 0 || gcd(a, b) != 1 { continue; }
            count += 1;
            let y = q(a, b);
            let mut p_ = size(y, 0);
            for &p in pr.iter().filter(|&&p| p <= 60) { p_ = p_.times(size(y, p)); }
            if p_ != q(1, 1) { bad += 1; }
        }
    }
    println!("fractions a/b with 1 <= |a|, b <= 60 in lowest terms: {}, product not 1: {}", count, bad);
    assert!(count > 2000 && bad == 0);

    println!("== an adele split as rational + ([0,1) x Z-hat) ==");
    let a_inf = q(53, 10);
    let a_fin = [(2i128, q(1, 4)), (3, q(2, 3))];
    let mut r = q(0, 1); for &(p, a) in &a_fin { r = r.add(principal_part(a, p)); }
    let t = a_inf.sub(r); let n = t.n.div_euclid(t.d);
    let qq = r.add(q(n, 1));
    let b_inf = a_inf.sub(qq); let b: Vec<Q> = a_fin.iter().map(|&(_, a)| a.sub(qq)).collect();
    let mq = q(-qq.n, qq.d);
    println!("principal parts sum r = {}; floor(a_inf - r) = {}; rational q = {}", r, n, qq);
    println!("remainder: real {}, at 2 {}, at 3 {}, at p >= 5 {}", b_inf, b[0], b[1], mq);
    assert!(!b_inf.lt(q(0, 1)) && b_inf.lt(q(1, 1)) && vp(b[0], 2) >= 0 && vp(b[1], 3) >= 0 && vp(mq, 5) >= 0);
    let mut found = BTreeSet::new(); for d in 1i128..73 {
        for k in -1000i128..1000 {
            let c = q(k, d);
            let gap = a_inf.sub(c);
            let mut ok = !gap.lt(q(0, 1)) && gap.lt(q(1, 1));
            for &p in &pr[..20] {
                let ap = a_fin.iter().find(|t| t.0 == p).map(|t| t.1).unwrap_or(q(0, 1));
                let v = ap.sub(c);
                if v.n != 0 && vp(v, p) < 0 { ok = false; }
            }
            if ok { found.insert(c); }
        }
    }
    let fs: Vec<String> = found.iter().map(|c| c.to_string()).collect();
    println!("brute force over k/d, d <= 72, |k| < 1000: rationals that work: {}", fs.join(", "));
    assert!(found.len() == 1 && found.contains(&qq));

    println!("== Q is discrete in the adeles ==");
    let mut real_only = vec![]; for b in 1i128..=100 { for a in -50i128..=50 { if gcd(a, b) == 1 && q(a, b).abs().lt(q(1, 2)) { real_only.push(q(a, b)); } } }
    let adelic: Vec<Q> = real_only.iter().cloned().filter(|y| y.d == 1).collect();
    let ad: Vec<String> = adelic.iter().map(|y| y.to_string()).collect();
    println!("fractions with denominator <= 100 in (-1/2, 1/2): {}; also in Z_p for every p: {}", real_only.len(), ad.join(", "));
    assert!(adelic.len() == 1 && adelic[0] == q(0, 1) && real_only.len() > 1000);
    let l: i128 = 2i128.pow(8) * 3i128.pow(4) * 25 * 7;
    let near0 = (-300i128..=300).filter(|k| (k * l).abs() <= 1_000_000_000).count();
    println!("no real place: multiples of 10! = {} within real size 10^9, all p-adically as small as 10!: {}", l, near0);
    assert!(l == 3628800 && near0 == 551);
    let mut pp = q(0, 1); for &p in pr.iter().filter(|&&p| p <= 29) { pp = pp.add(principal_part(q(1, p), p)); }
    println!("full product: 1/p at every p needs sum of 1/p; by p = 29 its denominator is {}", pp.d);
    assert!(pp.d == 2 * 3 * 5 * 7 * 11 * 13 * 17 * 19 * 23 * 29);

    println!("== ideles: rational times (positive real, unit at every prime) ==");
    let s = q(7, 12);
    let cases = [("principal 7/12", s, vec![(2i128, s), (3, s), (7, s)], s),
                 ("(5; 12 at 2, 1/3 at 3)", q(5, 1), vec![(2, q(12, 1)), (3, q(1, 3))], q(1, 1))];
    for (name, ai, listed, other) in cases.iter() {
        let (qq, real, norm, u) = idele_class(*ai, listed, *other);
        println!("{}: q = {}, real part {}, idele norm {}, unit part mod 20 = {}", name, qq, real, norm, u);
        assert!(real == norm && q(0, 1).lt(real));
    }
    let mut fro = vec![]; for p in [3i128, 7, 11, 13, 17, 19] {
        let (_, real, _, u) = idele_class(q(1, 1), &[(p, q(p, 1))], q(1, 1));
        assert!(u * p % 20 == 1 && real == q(1, p));
        fro.push(format!("{}->{}", p, u));
    }
    println!("p in the p-slot, class mod 20 (Frob_p raises roots of one to the p): {}", fro.join(", "));

    println!("== house: p = x^2 + 5y^2 and the open subgroup {{1, 9}} of (Z/20)^x ==");
    let nn = 10000; let mut f1 = BTreeSet::new(); for x in 0i128..101 { for y in 0i128..46 { f1.insert(x * x + 5 * y * y); } }
    let mut f2 = BTreeSet::new(); for x in -100i128..101 { for y in -100i128..101 { f2.insert(2 * x * x + 2 * x * y + 3 * y * y); } }
    let ps: Vec<i128> = pr.iter().cloned().filter(|&p| p != 2 && p != 5).collect();
    let powm = |mut b: i128, mut e: i128, m: i128| { let mut r = 1; b = b.rem_euclid(m); while e > 0 { if e & 1 == 1 { r = r * b % m; } b = b * b % m; e >>= 1; } r };
    let euler = |a: i128, p: i128| powm(a, (p - 1) / 2, p) == 1;
    let a_: Vec<i128> = ps.iter().cloned().filter(|p| f1.contains(p)).collect();
    let b_: Vec<i128> = ps.iter().cloned().filter(|&p| euler(-1, p) && euler(-5, p)).collect();
    let c_: Vec<i128> = ps.iter().cloned().filter(|p| p % 20 == 1 || p % 20 == 9).collect();
    let d_: Vec<i128> = ps.iter().cloned().filter(|p| f2.contains(p)).collect();
    let split_k: Vec<i128> = ps.iter().filter(|&&p| euler(-5, p)).map(|p| p % 20).collect::<BTreeSet<_>>().into_iter().collect();
    let res_d: Vec<i128> = d_.iter().map(|p| p % 20).collect::<BTreeSet<_>>().into_iter().collect();
    println!("odd primes below {} other than 5: {}", nn, ps.len());
    println!("x^2 + 5y^2: {}; -1 and -5 both squares: {}; p = 1 or 9 mod 20: {}", a_.len(), b_.len(), c_.len());
    println!("2x^2 + 2xy + 3y^2: {}, residues {:?}; -5 a square: residues {:?}", d_.len(), res_d, split_k);
    let units = (1..20).filter(|u| u % 2 != 0 && u % 5 != 0).count();
    let res_a: Vec<i128> = a_.iter().map(|p| p % 20).collect::<BTreeSet<_>>().into_iter().collect();
    println!("units mod 20: {}; residues of x^2 + 5y^2 primes {:?}, index {}; share {:.4}", units, res_a, units / res_a.len(), a_.len() as f64 / ps.len() as f64);
    assert!(a_ == b_ && b_ == c_ && res_a == vec![1, 9] && units / res_a.len() == 4 && split_k == vec![1, 3, 7, 9] && res_d == vec![3, 7]);
    println!("ALL CHECKS PASS");
}
