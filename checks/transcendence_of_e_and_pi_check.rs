// Transcendence of e and pi -- the same check as the Python, in Rust.  No crates.
// Test relation: a e^2 + b e + c = 0 with (a, b, c) = (1, -7, 12).  Hermite's
// polynomial: f(x) = x^(p-1) (x - 1)^p (x - 2)^p, p a prime.  Roads: (1) F(k), the sum
// of all derivatives, by a recurrence on f's coefficients; (2) the same F(k) by shifting
// f to k; (3) Hermite's integral by Simpson's rule against integration by parts.
// Whole numbers past u128 use a small signed big-integer type, base 10^9.
const BASE: i128 = 1_000_000_000;
#[derive(Clone, PartialEq, Debug)]
struct Z { neg: bool, d: Vec<i128> } // sign and base-10^9 digits, lowest first

fn norm(v: Vec<i128>) -> Z { // carry signed digit sums into a sign and true digits
    let (mut d, mut carry) = (vec![], 0i128);
    for x in v { let s = x + carry; d.push(s.rem_euclid(BASE)); carry = s.div_euclid(BASE); }
    while carry > 0 { d.push(carry % BASE); carry /= BASE; }
    if carry < 0 { d.push(carry); return Z { neg: true, d: norm(d.iter().map(|x| -x).collect()).d }; }
    while d.len() > 1 && *d.last().unwrap() == 0 { d.pop(); }
    Z { neg: false, d }
}
impl Z {
    fn from(x: i128) -> Z { norm(vec![x]) }
    fn signed(&self) -> Vec<i128> { self.d.iter().map(|x| if self.neg { -x } else { *x }).collect() }
    fn add(&self, o: &Z) -> Z {
        let (a, b) = (self.signed(), o.signed());
        norm((0..a.len().max(b.len())).map(|i| a.get(i).unwrap_or(&0) + b.get(i).unwrap_or(&0)).collect())
    }
    fn mul(&self, m: i128) -> Z { norm(self.signed().iter().map(|x| x * m).collect()) } // |m| below 10^18
    fn divrem(&self, m: u128) -> (Z, u128) { // magnitude divided by m, remainder of the magnitude
        let (mut q, mut r) = (vec![0u128; self.d.len()], 0u128);
        for i in (0..self.d.len()).rev() { let cur = r * 1_000_000_000 + self.d[i] as u128; q[i] = cur / m; r = cur % m; }
        let mut z = norm(q.iter().map(|&x| x as i128).collect()); z.neg = self.neg; (z, r)
    }
    fn modp(&self, p: u128) -> u128 { let r = self.divrem(p).1; if self.neg && r > 0 { p - r } else { r } }
    fn f64(&self) -> f64 { let m = self.d.iter().rev().fold(0.0, |a, &x| a * 1e9 + x as f64); if self.neg { -m } else { m } }
    fn show(&self) -> String {
        let head = format!("{}{}", if self.neg { "-" } else { "" }, self.d.last().unwrap());
        self.d.iter().rev().skip(1).fold(head, |s, x| s + &format!("{:09}", x))
    }
}
fn mulp(f: &[i128], g: &[i128]) -> Vec<i128> {
    let mut out = vec![0; f.len() + g.len() - 1];
    for (i, x) in f.iter().enumerate() { for (j, y) in g.iter().enumerate() { out[i + j] += x * y; } } out
}
fn hermite(p: usize, s: i128) -> Vec<i128> { // coefficients of f(x + s)
    let mut f = vec![1];
    for _ in 0..p - 1 { f = mulp(&f, &[s, 1]); }
    for k in 1..=2 { for _ in 0..p { f = mulp(&f, &[s - k, 1]); } } f
}
fn big_f1(p: usize, k: i128) -> Z { // F(k) = sum_i c_i S_i, S_i = k^i + i S_(i-1)
    let (mut s, mut total) = (Z::from(0), Z::from(0));
    for (i, c) in hermite(p, 0).iter().enumerate() {
        s = Z::from(k.pow(i as u32)).add(&s.mul(i as i128));
        total = total.add(&s.mul(*c));
    } total
}
fn big_f2(p: usize, k: i128) -> Z { // F(k) = sum_j j! t_j, t_j the coefficients of f(k + y)
    let (mut total, mut fact) = (Z::from(0), Z::from(1));
    for (j, t) in hermite(p, k).iter().enumerate() {
        total = total.add(&fact.mul(*t));
        fact = fact.mul(j as i128 + 1);
    } total
}
fn big_n(p: usize, a: i128, b: i128, c: i128) -> Z {
    let n1 = big_f1(p, 0).mul(c).add(&big_f1(p, 1).mul(b)).add(&big_f1(p, 2).mul(a));
    let n2 = big_f2(p, 0).mul(c).add(&big_f2(p, 1).mul(b)).add(&big_f2(p, 2).mul(a));
    assert!(n1 == n2); n1 // road 1 against road 2, exact integers
}
fn fact(n: u128) -> u128 { (2..=n).product::<u128>().max(1) }
fn f_value(u: f64, p: usize) -> f64 {
    let mut out = 1.0;
    for _ in 0..p - 1 { out *= u; }
    for _ in 0..p { out *= (u - 1.0) * (u - 2.0); } out
}
fn hermite_integral(k: f64, p: usize) -> f64 { // integral from 0 to k of e^(k - u) f(u) du
    let n = 4000;
    let (h, mut s) = (k / n as f64, 0.0);
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        s += w * (k - i as f64 * h).exp() * f_value(i as f64 * h, p);
    } s * h / 3.0
}
fn sci(x: f64) -> String { // 4 significant digits, the same in both languages
    if x == 0.0 { return "0".into(); }
    let mut ex = x.abs().log10().floor() as i32;
    let mut m = x / 10f64.powi(ex);
    if m.abs() >= 9.9995 { m /= 10.0; ex += 1; }
    format!("{:.3}e{}", m, ex)
}
#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 } // a small complex-number type
fn cmul(a: Cx, b: Cx) -> Cx { Cx { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cadd(a: Cx, b: Cx) -> Cx { Cx { re: a.re + b.re, im: a.im + b.im } }
fn main() {
    let (a0, b0, c0) = (1i128, -7i128, 12i128);
    let e = 1f64.exp();
    println!("e = {:.12}; e^2 - 7e + 12 = {:.6}", e, e * e - 7.0 * e + 12.0);
    for h in [2i32, 12] {
        let mut best = (f64::INFINITY, 0, 0, 0);
        for a in -h..=h { for b in -h..=h { for c in -h..=h {
            let v = (a as f64 * e * e + b as f64 * e + c as f64).abs();
            if (a, b, c) != (0, 0, 0) && v < best.0 { best = (v, a, b, c); } } } }
        println!("closest triple with every |coefficient| <= {}: ({}, {}, {}) gives {:.6}", h, best.1, best.2, best.3, best.0);
    }
    println!("p = 3: f = {:?} (lowest power first); F(0), F(1), F(2) = {}, {}, {}",
             hermite(3, 0), big_f1(3, 0).show(), big_f1(3, 1).show(), big_f1(3, 2).show());
    for k in [1i128, 2] {
        let lhs = hermite_integral(k as f64, 3);
        let rhs = e.powi(k as i32) * big_f1(3, 0).f64() - big_f1(3, k).f64();
        println!("p = 3, k = {}: Simpson integral {:.9}; e^k F(0) - F(k) = {:.9}", k, lhs, rhs);
        assert!((lhs - rhs).abs() < 1e-9); // integration by parts against numerical integration
    }
    let n13 = big_n(13, a0, b0, c0);
    let (q13, r13) = n13.divrem(fact(12));
    println!("p = 13: N = {} ({} digits); 2^13 = {}", n13.show(), n13.show().len(), 1u32 << 13);
    println!("N / 12! = {}, remainder {}; (N / 12!) mod 13 = {}", q13.show(), r13, q13.modp(13));
    assert!(r13 == 0 && q13.modp(13) != 0); // divisible by 12!, not by 13!
    let j13 = b0 as f64 * hermite_integral(1.0, 13) + a0 as f64 * hermite_integral(2.0, 13);
    println!("p = 13: J = c I(0) + b I(1) + a I(2) = {}; 12! = 479,001,600", sci(j13));
    assert!(fact(12) == 479_001_600 && j13.abs() > 0.0 && j13.abs() < 1.0); // far below 12!
    let exact_i = |k: i128| { let sc = |z: Z| (0..8).fold(z, |a, _| a.mul(BASE)); // times S = 10^72
        let (mut t, mut sum) = (sc(big_f1(13, 0)), Z::from(0)); // e^k F(0) S, e^k summed exactly to 70 terms
        for j in 0..=70u128 { sum = sum.add(&t); t = t.mul(k).divrem(j + 1).0; }
        sum.add(&sc(big_f1(13, k)).mul(-1)).f64() / 1e72 };
    for (v, x) in [(hermite_integral(1.0, 13), exact_i(1)), (hermite_integral(2.0, 13), exact_i(2)),
                   (j13, c0 as f64 * exact_i(0) + b0 as f64 * exact_i(1) + a0 as f64 * exact_i(2))] { assert!((v - x).abs() < 1e-9 * x.abs()); }
    let f0 = big_f1(13, 0).f64();
    println!("F(1)/F(0) - e = {}; F(2)/F(0) - e^2 = {}", sci(-hermite_integral(1.0, 13) / f0), sci(-hermite_integral(2.0, 13) / f0));
    let cc = b0.abs() as f64 * e + 2.0 * a0.abs() as f64 * e * e;
    println!("crude constant |b| e + 2|a| e^2 = {:.2}, half of it {:.2}; largest |x(x-1)(x-2)| on [0, 2] = 2/(3 sqrt 3) = {:.3}", cc, cc / 2.0, 2.0 / (3.0 * 3f64.sqrt()));
    println!("p, N divisible by (p-1)!, (N/(p-1)!) mod p, log10 (p-1)!, log10 crude bound, log10 |J|");
    let primes = [3usize, 5, 7, 11, 13, 17, 19, 23];
    let mut chart = vec![];
    for &p in &primes {
        let (q, r) = big_n(p, a0, b0, c0).divrem(fact(p as u128 - 1));
        let crude = (b0.abs() as f64 * e + 2.0 * a0.abs() as f64 * e * e) * 2f64.powi(2 * p as i32 - 1);
        let j = b0 as f64 * hermite_integral(1.0, p) + a0 as f64 * hermite_integral(2.0, p);
        let row = ((fact(p as u128 - 1) as f64).log10(), crude.log10(), j.abs().log10());
        chart.push(row);
        println!("{}, {}, {}, {:.2}, {:.2}, {:.2}", p, if r == 0 { "yes" } else { "no" }, q.modp(p as u128), row.0, row.1, row.2);
    }
    let first = primes.iter().zip(&chart).find(|(p, r)| **p > 12 && r.1 < r.0).unwrap().0;
    println!("first prime past 12 where the crude bound is below (p-1)!: {}", first);
    assert!(chart[4].1 > chart[4].0 && chart[5].1 < chart[5].0); // crude bound crosses at 17
    let n0 = big_n(13, 1, -7, 0);
    println!("mistake, c = 0: (N/12!) mod 13 = {}; p = 3 dividing c = 12: (N/2!) mod 3 = {}",
             n0.divrem(fact(12)).0.modp(13), big_n(3, a0, b0, c0).divrem(2).0.modp(3));
    let pi = std::f64::consts::PI;
    let one_plus = ((1.0 + pi.cos()).powi(2) + pi.sin().powi(2)).sqrt();
    println!("sqrt(pi) = {:.6}; |1 + e^(i pi)| below 1e-15: {}", pi.sqrt(), if one_plus < 1e-15 { "yes" } else { "no" });
    println!("stand-in i sqrt10 for i pi, sqrt 10 = {:.6}: (1 + e^(i r))(1 + e^(-i r)) = 2 + 2 cos(sqrt 10) = {:.6}", 10f64.sqrt(), 2.0 + 2.0 * 10f64.sqrt().cos());
    let (r, w) = (2f64.powf(1.0 / 3.0), Cx { re: (2.0 * pi / 3.0).cos(), im: (2.0 * pi / 3.0).sin() });
    let rw = Cx { re: r * w.re, im: r * w.im };
    let roots = [Cx { re: r, im: 0.0 }, rw, cmul(rw, w)];
    let mut poly = vec![Cx { re: 1.0, im: 0.0 }];
    for m in 1..8usize {
        let s = (0..3).filter(|i| m >> i & 1 == 1).fold(Cx { re: 0.0, im: 0.0 }, |t, i| cadd(t, roots[i]));
        if s.re.hypot(s.im) <= 1e-9 { continue; }
        let mut next = vec![Cx { re: 0.0, im: 0.0 }; poly.len() + 1];
        for (i, z) in poly.iter().enumerate() {
            next[i] = cadd(next[i], cmul(*z, Cx { re: -s.re, im: -s.im }));
            next[i + 1] = cadd(next[i + 1], *z);
        }
        poly = next;
    }
    let rounded: Vec<i128> = poly.iter().map(|z| z.re.round() as i128).collect();
    println!("roots of x^3 - 2: 8 subset sums, {} of them 0; the other {} solve {:?} (lowest power first)",
             9 - poly.len(), poly.len() - 1, rounded);
    assert!(rounded == mulp(&[-2, 0, 0, 1], &[2, 0, 0, 1])); // equals (x^3 - 2)(x^3 + 2)
    assert!(poly.iter().zip(&rounded).all(|(z, &k)| (z.re - k as f64).hypot(z.im) < 1e-9));
    println!("ALL CHECKS PASS");
}
