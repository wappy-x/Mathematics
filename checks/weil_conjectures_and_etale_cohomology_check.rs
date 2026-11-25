// The Weil conjectures -- the check behind the card, std only.  Same roads as the
// Python: brute-force counts over F_(5^n) for y^2 = x^3 - x, a genus-2 curve, the
// plane and a singular cubic, against the zeta function, in exact fractions.
use std::collections::HashSet;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy, PartialEq, Debug)]
struct Fr(i128, i128);                                  // top / bottom, lowest terms, bottom > 0
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(t: i128, d: i128) -> Fr { let g = gcd(t, d) * d.signum(); Fr(t / g, d / g) }
impl Add for Fr { type Output = Fr; fn add(self, o: Fr) -> Fr { fr(self.0.checked_mul(o.1).unwrap() + o.0.checked_mul(self.1).unwrap(), self.1.checked_mul(o.1).unwrap()) } }
impl Sub for Fr { type Output = Fr; fn sub(self, o: Fr) -> Fr { self + Fr(-o.0, o.1) } }
impl Mul for Fr { type Output = Fr; fn mul(self, o: Fr) -> Fr { fr(self.0.checked_mul(o.0).unwrap(), self.1.checked_mul(o.1).unwrap()) } }
impl Div for Fr { type Output = Fr; fn div(self, o: Fr) -> Fr { fr(self.0.checked_mul(o.1).unwrap(), self.1.checked_mul(o.0).unwrap()) } }
impl std::fmt::Display for Fr {
    fn fmt(&self, f: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.1 == 1 { write!(f, "{}", self.0) } else { write!(f, "{}/{}", self.0, self.1) }
    }
}
fn n(x: i64) -> Fr { Fr(x as i128, 1) }
fn pmod(a: &[i64], m: &[i64], p: i64) -> Vec<i64> {   // remainder of a by the monic m, mod p
    let mut a = a.to_vec();
    let (lm, mut i) = (m.len() as i64, a.len() as i64 - 1);
    while i > lm - 2 {
        let c = a[i as usize].rem_euclid(p);
        for j in 0..lm { a[(i - lm + 1 + j) as usize] -= c * m[j as usize]; }
        i -= 1;
    }
    a[..(lm - 1) as usize].iter().map(|x| x.rem_euclid(p)).collect()
}
fn monics(p: i64, d: u32) -> Vec<Vec<i64>> {            // every monic polynomial of degree d
    (0..p.pow(d)).map(|k| { let mut v: Vec<i64> = (0..d).map(|i| (k / p.pow(i)) % p).collect(); v.push(1); v }).collect()
}
fn modulus(p: i64, k: u32) -> Vec<i64> {                // no factor of degree <= k/2
    monics(p, k).into_iter().find(|m| (1..=k / 2).all(|d| monics(p, d).iter().all(|g| pmod(m, g, p).iter().any(|&x| x != 0)))).unwrap()
}
fn mul(a: &[i64], b: &[i64], m: &[i64], p: i64) -> Vec<i64> {
    let mut c = vec![0; 2 * a.len() - 1];
    for (i, x) in a.iter().enumerate() { for (j, y) in b.iter().enumerate() { c[i + j] += x * y; } }
    pmod(&c, m, p)
}
fn power(a: &[i64], mut e: i64, m: &[i64], p: i64) -> Vec<i64> {
    let (mut out, mut a) = (vec![0; a.len()], a.to_vec()); out[0] = 1;
    while e > 0 {
        if e & 1 == 1 { out = mul(&out, &a, m, p); }
        a = mul(&a, &a, m, p); e >>= 1;
    }
    out
}
fn count(f: &[i64], p: i64, k: u32) -> i64 {            // points of y^2 = f(x) over F_(p^k), one at infinity
    let (m, qq) = (modulus(p, k), p.pow(k));
    let (mut one, mut total) = (vec![0; k as usize], 1); one[0] = 1;
    for nn in 0..qq {
        let x: Vec<i64> = (0..k).map(|i| (nn / p.pow(i)) % p).collect();
        let mut v = vec![0; k as usize];
        for &c in f { v = mul(&v, &x, &m, p); v[0] = (v[0] + c).rem_euclid(p); }
        total += if v.iter().all(|&c| c == 0) { 1 } else if power(&v, (qq - 1) / 2, &m, p) == one { 2 } else { 0 };
    }
    total
}
fn zeta_from_counts(nc: &[i64]) -> Vec<Fr> {            // n z_n = sum_k N_k z_(n-k)
    let mut z = vec![n(1)];
    for k in 1..=nc.len() {
        let mut s = n(0);
        for j in 1..=k { s = s + n(nc[j - 1]) * z[k - j]; }
        z.push(s / n(k as i64));
    }
    z
}
fn counts_from_zeta(z: &[Fr]) -> Vec<i64> {             // the same identity, solved for N_n
    let mut out: Vec<Fr> = vec![];
    for k in 1..z.len() {
        let mut s = n(k as i64) * z[k];
        for j in 1..k { s = s - out[j - 1] * z[k - j]; }
        out.push(s);
    }
    out.iter().map(|c| { assert_eq!(c.1, 1); c.0 as i64 }).collect()
}
fn expand(num: &[i64], roots: &[i64], len: usize) -> Vec<Fr> {   // num(t) / prod (1 - r t)
    let mut s: Vec<Fr> = (0..=len).map(|i| n(*num.get(i).unwrap_or(&0))).collect();
    for &r in roots { for i in 1..=len { s[i] = s[i] + n(r) * s[i - 1]; } }
    s
}
fn numerator(z: &[Fr], q: i64, g: usize) -> Vec<i64> {  // P(t) = Z(t)(1 - t)(1 - qt): g terms, then symmetry
    let w: Vec<i64> = (0..=g).map(|i| {
        let mut c = z[i];
        if i >= 1 { c = c - n(1 + q) * z[i - 1]; }
        if i >= 2 { c = c + n(q) * z[i - 2]; }
        assert_eq!(c.1, 1); c.0 as i64 }).collect();                  // exact: a fraction here is a failure
    let mut out = w.clone(); for i in (0..g).rev() { out.push(q.pow((g - i) as u32) * w[i]); }
    out
}
fn zf(num: &[i64], roots: &[i64], t: Fr) -> Fr {        // the rational function at a fraction t
    let mut out = n(0); let mut tp = n(1);
    for &c in num { out = out + n(c) * tp; tp = tp * t; }
    for &r in roots { out = out / (n(1) - n(r) * t); }
    out
}
fn poly(c: &[i64]) -> String {
    let parts: Vec<String> = c.iter().enumerate().filter(|(_, &x)| x != 0)
        .map(|(i, x)| if i > 0 { format!("{}t^{}", x, i) } else { x.to_string() }).collect();
    parts.join(" + ").replace("t^1 ", "t ")
}
fn main() {
    let (q, kk) = (5i64, 4u32);
    let ne: Vec<i64> = (1..=kk).map(|k| count(&[1, 0, -1, 0], q, k)).collect();
    let a = q + 1 - ne[0];
    let pe = numerator(&zeta_from_counts(&ne[..1]), q, 1);
    let fe = numerator(&zeta_from_counts(&ne[..2]), q, 2)[..3].to_vec(); // P(t) read from two counts, no symmetry imposed
    let prede = counts_from_zeta(&expand(&pe, &[1, q], kk as usize));
    let im = (0..q).find(|s| 4 * s * s == 4 * q - a * a).unwrap();
    println!("y^2 = x^3 - x, counted over F_5, F_25, F_125, F_625: {:?}", ne);
    println!("over F_5, x^3 - x for x = 0..4: {:?}; squares mod 5: {:?}", (0..q).map(|x| (x * x * x - x).rem_euclid(q)).collect::<Vec<_>>(), { let mut v: Vec<i64> = (0..q).map(|y| y * y % q).collect(); v.sort(); v.dedup(); v });
    println!("a = 5 + 1 - {} = {}; P(t) = {}; Z(t) = P(t) / ((1 - t)(1 - 5t))", ne[0], a, poly(&pe));
    println!("counts predicted from F_5 alone: {:?}", prede);
    println!("F_25 by hand: 25 + 1 - (a^2 - 2q) = 26 - ({} - 10) = {}", a * a, 26 - (a * a - 10));
    println!("reciprocal roots {} +- {}i, size^2 {}; roots of P: t = ({} -+ {}i)/{}, size {:.6}", a / 2, im, (a / 2).pow(2) + im * im, a / 2, im, q, (q as f64).powf(-0.5));
    let mut s = vec![2i64, a];
    for _ in 2..=12 { let l = s.len(); s.push(a * s[l - 1] - q * s[l - 2]); }
    let e: Vec<f64> = (1..=12).map(|k| -(s[k] as f64) / (2.0 * (q as f64).powf(k as f64 / 2.0))).collect();
    let th = (im as f64).atan2(a as f64 / 2.0);
    println!("chart, (N_n - 5^n - 1)/(2 * 5^(n/2)), n = 1..12: {}", e.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", "));
    let emax = e.iter().fold(0.0f64, |m, x| m.max(x.abs()));
    println!("N_12 = {}; largest |error/allowance| {:.4}; angle of alpha {:.4} degrees", q.pow(12) + 1 - s[12], emax, th * 57.29577951308232);
    for t in [n(2), fr(1, 3)] {
        println!("functional equation, t = {}: Z(t) = {}, Z(1/(5t)) = {}", t, zf(&fe, &[1, q], t), zf(&fe, &[1, q], n(1) / (n(q) * t)));
    }
    let n2: Vec<i64> = (1..=kk).map(|k| count(&[1, 0, 0, 0, 1, 1], q, k)).collect();
    let p2 = numerator(&zeta_from_counts(&n2[..2]), q, 2);
    let pred2 = counts_from_zeta(&expand(&p2, &[1, q], kk as usize));
    let b = [1i64, 0, 5];
    let sq: Vec<i64> = (0..5).map(|i: i64| (0..3).filter(|j| i - j >= 0 && i - j < 3).map(|j| b[j as usize] * b[(i - j) as usize]).sum()).collect();
    println!("genus 2, y^2 = x^5 + x + 1: counted {:?}; P(t) = {}; (1 + 5t^2)^2 = {}", n2, poly(&p2), poly(&sq));
    println!("genus 2 counts predicted from F_5 and F_25: {:?}", pred2);
    let (t0, f2) = (fr(1, 2), numerator(&zeta_from_counts(&n2), q, 4)[..5].to_vec()); // from four counts, no symmetry
    let r2 = zf(&f2, &[1, q], n(1) / (n(q) * t0)) / zf(&f2, &[1, q], t0);
    println!("genus 2 functional equation at t = 1/2: Z(1/(5t)) / Z(t) = {}; 1/(5t^2) = {}", r2, n(1) / (n(q) * t0 * t0));
    let np: Vec<i64> = (1..=kk).map(|k| 1 + q.pow(k) + q.pow(2 * k)).collect();
    let mut cls: HashSet<Vec<i64>> = HashSet::new();     // lines through 0 in F_5^3
    for v in 1..q.pow(3) {
        let w = [v % q, v / q % q, v / (q * q)];
        cls.insert((1..q).map(|l| w.iter().map(|c| l * c % q).collect::<Vec<i64>>()).min().unwrap());
    }
    let (zp, ep) = (zeta_from_counts(&np), expand(&[1], &[1, q, q * q], kk as usize));
    let ints = |v: &[Fr]| v.iter().map(|c| c.0 as i64).collect::<Vec<i64>>();
    println!("P^2 over F_5: {} classes of nonzero triples; 1 + q^n + q^2n = {:?}", cls.len(), np);
    println!("P^2 zeta from counts {:?}; 1/((1-t)(1-5t)(1-25t)) {:?}", ints(&zp), ints(&ep));
    let (lp, rp) = (zf(&[1], &[1, q, q * q], fr(1, 50)), n(-1000) * zf(&[1], &[1, q, q * q], n(2)));
    println!("P^2 functional equation at t = 2: Z(1/(25t)) = {}, -125 t^3 Z(t) = {}", lp, rp);
    let bet = |num: &[i64], roots: &[i64], d: u32| -> Vec<i64> { (0..=2 * d).map(|i| if i % 2 == 1 { num.iter().rposition(|&c| c != 0).unwrap() as i64 }
        else { roots.iter().filter(|&&r| r == q.pow(i / 2)).count() as i64 }).collect() };
    println!("deg P_i = b_i: genus 1 {:?}; genus 2 {:?}; P^2 {:?}", bet(&fe, &[1, q], 1), bet(&f2, &[1, q], 1), bet(&[1], &[1, q, q * q], 2));
    let ns: Vec<i64> = (1..=2).map(|k| count(&[1, 1, 0, 0], q, k)).collect();
    let ws = counts_from_zeta(&expand(&numerator(&zeta_from_counts(&ns[..1]), q, 1), &[1, q], 2))[1]; // the genus-1 rule
    println!("mistake, singular y^2 = x^3 + x^2: counted {:?}; smooth-curve rule predicts {} over F_25", ns, ws);
    println!("  its zeta is 1/(1 - 5t): Z(2) = {}, Z(1/10) = {}", zf(&[1], &[q], n(2)), zf(&[1], &[q], fr(1, 10)));
    let no = ne[0] - 1;
    println!("mistake, O left out: a = 5 + 1 - {} = {}, F_25 predicted {}", no, q + 1 - no, 26 - ((q + 1 - no).pow(2) - 2 * q));
    println!("mistake, alpha^2 + beta^2 read as a^2: F_25 predicted {}", 26 - a * a);
    let z25 = 1 + (0..25i64).map(|x| (0..25i64).filter(|y| (y * y - x * x * x + x).rem_euclid(25) == 0).count() as i64).sum::<i64>();
    println!("mistake, integers mod 25 for F_25: {} points", z25);
    assert!(ne == prede && ne == vec![8, 32, 104, 640]);             // rationality: one count fixes all
    assert!(n2 == pred2 && p2 == sq);                                // genus 2: two counts fix all
    assert!(a * a < 4 * q && fe[2] == q);                            // Riemann hypothesis, genus 1: alpha beta = q
    assert!(e.iter().enumerate().all(|(k, x)| (x + ((k + 1) as f64 * th).cos()).abs() < 1e-12) && emax <= 1.0);
    assert!([n(2), fr(1, 3)].iter().all(|&t| zf(&fe, &[1, q], t) == zf(&fe, &[1, q], n(1) / (n(q) * t))));
    assert!(r2 == n(1) / (n(q) * t0 * t0) && lp == rp);              // functional equations
    assert!(cls.len() as i64 == np[0] && zp == ep);                  // P^2: brute count, and the product
    assert!(ns[1] != ws && z25 != ne[1]);                            // the singular curve and Z/25 fail
    println!("ALL CHECKS PASS");
}
