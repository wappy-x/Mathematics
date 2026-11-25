// L-functions of modular forms -- the same check as the Python, in Rust.  No crates.
// f = q prod (1 - q^n)^2 (1 - q^(11n))^2, weight 2, level 11; q = e^(2 pi i z), not a modulus.
// Lambda(s) = (sqrt 11 / 2 pi)^s Gamma(s) L(f, s) is the completed L-function, not von Mangoldt.
use std::f64::consts::PI;
const M: usize = 2000;
const K: usize = 600;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                 // a small complex-number struct
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn inv(self) -> C { let d = self.re * self.re + self.im * self.im; C { re: self.re / d, im: -self.im / d } }
}
fn cs(w: C) -> String { format!("{:.9} {} {:.9}i", w.re, if w.im >= 0.0 { "+" } else { "-" }, w.im.abs()) }
fn gcd(a: usize, b: usize) -> usize { if b == 0 { a } else { gcd(b, a % b) } }
fn count(p: usize) -> i64 {                   // points of y^2 + y = x^3 - x^2 over F_p, O included
    let mut ways = vec![0i64; p];
    for y in 0..p { ways[(y * y + y) % p] += 1 }
    1 + (0..p).map(|x| ways[(x * x * x + p * p - x * x % p) % p]).sum::<i64>()
}
fn fz(a: &[i128], z: C) -> C {               // f(z) = sum a_n q^n at a point of the upper half plane
    let r = (-2.0 * PI * z.im).exp();
    let q = C { re: r * (2.0 * PI * z.re).cos(), im: r * (2.0 * PI * z.re).sin() };
    let (mut s, mut w) = (C { re: 0.0, im: 0.0 }, C { re: 1.0, im: 0.0 });
    for n in 1..=K { w = w.mul(q); s = s.add(w.scale(a[n] as f64)) }
    s
}
fn g(a: &[i128], y: f64) -> f64 {            // f on the imaginary axis, a real number
    let (x, mut w, mut s) = ((-2.0 * PI * y).exp(), 1.0, 0.0);
    for n in 1..=K { w *= x; s += a[n] as f64 * w }
    s
}
fn gam_inc(s: f64, x: f64) -> f64 {          // Gamma(s, x) by its continued fraction
    let (mut bb, mut cc) = (x + 1.0 - s, 1e300);
    let mut d = 1.0 / bb;
    let mut hh = d;
    for i in 1..300 {
        let an = -(i as f64) * (i as f64 - s);
        bb += 2.0; d = 1.0 / (an * d + bb); cc = bb + an / cc; hh *= d * cc;
    }
    (-x).exp() * x.powf(s) * hh
}
fn main() {
    let mut c = vec![0i128; M + 1];          // road 1 to a_n: multiply out the product
    c[0] = 1;
    for m in 1..=M {
        let steps = if 11 * m <= M { vec![m, m, 11 * m, 11 * m] } else { vec![m, m] };
        for step in steps { for i in (step..=M).rev() { c[i] = c[i].checked_sub(c[i - step]).unwrap() } }
    }
    let mut a = vec![0i128; M + 1];
    for n in 1..=M { a[n] = c[n - 1] }
    let primes: Vec<usize> = (2..=M).filter(|&p| (2..).take_while(|d| d * d <= p).all(|d| p % d != 0)).collect();
    println!("a_1..a_13 from the product: {:?}", &a[1..14]);
    println!("#E(F_p) for p = 2, 3, 5, 7, 11, 13: {:?}", [2, 3, 5, 7, 11, 13].iter().map(|&p| count(p)).collect::<Vec<_>>());
    let ap = |p: usize| p as i64 + 1 - count(p);                // road 2 to a_p: count points
    assert!([2, 3, 5, 7, 13].iter().map(|&p| ap(p)).collect::<Vec<_>>() == vec![-2, -1, 1, -2, 4]);
    assert!([2, 3, 5, 7, 13].iter().all(|&p| ap(p) as i128 == a[p]));
    assert!(primes.iter().all(|&p| ap(p) as i128 == a[p]));
    let worst = primes.iter().filter(|&&p| p != 11).map(|&p| (a[p] as f64).abs() / (2.0 * (p as f64).sqrt())).fold(0.0, f64::max);
    println!("a_p = p + 1 - #E(F_p) for all {} primes below {}: yes; max |a_p|/(2 sqrt p) = {:.6}", primes.len(), M, worst);
    assert!(worst <= 1.0);
    let mut pairs = 0;
    for m in 2..=M { for n in (m + 1)..=(M / m) { if gcd(m, n) == 1 { assert!(a[m * n] == a[m] * a[n]); pairs += 1 } } }
    let mut steps = 0;
    for &p in &primes {
        let (mut q, mut r) = (p, p * p);
        while r <= M {
            let want = a[p] * a[q] - (if p == 11 { 0 } else { p as i128 }) * a[q / p];
            assert!(a[r] == want); steps += 1; q = r; r *= p;
        }
    }
    println!("Hecke rules to {}: {} coprime pairs, {} prime-power steps, all hold; a_121 = {}, a_1331 = {}", M, pairs, steps, a[121], a[1331]);
    let mut e: Vec<i128> = vec![1, -2];      // 1/(1 + 2X + 2X^2) as a series in X = 2^(-s)
    while e.len() < 11 { let k = e.len(); e.push(-2 * e[k - 1] - 2 * e[k - 2]) }
    let pw: Vec<i128> = (0..11).map(|k| a[1 << k]).collect();
    println!("Euler factor at 2, series: {:?} ; a_(2^k): {:?}", e, pw);
    assert!(e == pw);
    let (num, den) = (16i64, 16 + 8 + 2);    // 1/(1 + 2/4 + 2/16) = 16/26
    println!("Euler factor at 2, s = 2: {}/{}", num / gcd(16, 26) as i64, den / gcd(16, 26) as i64);
    println!("mistake, good-prime factor at 11: predicts a_121 = {} but a_121 = {}", a[11] * a[11] - 11, a[121]);
    let b = |n: usize| a[n] + if n % 2 == 0 { a[n / 2] } else { 0 };   // f(z) + f(2z), level 22
    println!("mistake, oldform f(z) + f(2z) at level 22: b_2 = {}, b_4 = {}; an Euler factor needs {} or {}", b(2), b(4), b(2) * b(2), b(2) * b(2) - 2);
    let genus12 = |n: usize| -> i64 {        // 12 x dim S_2(Gamma_0(N)), from the genus formula
        let mut mu = n;
        for &p in primes.iter().filter(|&&p| n % p == 0) { mu = mu * (p + 1) / p }
        let v2 = if n % 4 == 0 { 0 } else { (0..n).filter(|x| (x * x + 1) % n == 0).count() };
        let v3 = if n % 9 == 0 { 0 } else { (0..n).filter(|x| (x * x + x + 1) % n == 0).count() };
        let vc: usize = (1..=n).filter(|d| n % d == 0).map(|d| { let g = gcd(d, n / d); (1..=g).filter(|k| gcd(*k, g) == 1).count() }).sum();
        12 + mu as i64 - 3 * v2 as i64 - 4 * v3 as i64 - 6 * vc as i64
    };
    assert!(genus12(11) == 12 && genus12(22) == 24);
    println!("dim S_2(Gamma_0(N)) by the genus formula: N = 11: {} ; N = 22: {}", genus12(11) / 12, genus12(22) / 12);
    let z = C { re: 0.1, im: 0.4 };
    let minus = C { re: -1.0, im: 0.0 };
    let l = fz(&a, minus.mul(z.scale(11.0).inv()));
    let r = z.mul(z).scale(-11.0).mul(fz(&a, z));
    println!("z = 0.1 + 0.4i: f(-1/(11z)) = {} ; -11 z^2 f(z) = {}", cs(l), cs(r));
    assert!(l.sub(r).abs() < 1e-10);
    println!("mistake, level-1 flip: f(-1/z) = {} ; z^2 f(z) = {}", cs(fz(&a, minus.mul(z.inv()))), cs(z.mul(z).mul(fz(&a, z))));
    let h = 0.05;                            // road A: the whole Mellin integral, u = log y
    let us: Vec<f64> = (0..133).map(|j| -4.2 + 0.05 * j as f64).collect();
    let gs: Vec<f64> = us.iter().map(|&u| g(&a, u.exp())).collect();
    let lam_direct = |s: f64| { let mut t = 0.0; for (v, u) in gs.iter().zip(&us) { t += v * (s * u).exp() } 11f64.powf(s / 2.0) * h * t };
    let lam_split = |s: f64| {               // road B: the proof's formula, only y above 1/sqrt 11
        let mut tot = 0.0;
        for n in 1..=40 {
            let cn = 2.0 * PI * n as f64 / 11f64.sqrt();
            tot += a[n] as f64 * (cn.powf(-s) * gam_inc(s, cn) + cn.powf(s - 2.0) * gam_inc(2.0 - s, cn));
        }
        tot
    };
    let sq = PI.sqrt();
    let rg = [(-1.0, 0.0), (-0.5, -0.5 / sq), (0.0, 0.0), (0.5, 1.0 / sq), (1.0, 1.0), (1.5, 2.0 / sq), (2.0, 1.0), (2.5, 4.0 / (3.0 * sq)), (3.0, 0.5)];
    println!("s, Lambda by the whole integral, by the split formula, L(f, s):");
    for &(s, rgs) in &rg {
        let (aa, bb) = (lam_direct(s), lam_split(s));
        println!("{:5.1}: {:.9} {:.9} {:.9}", s, aa, bb, aa * (2.0 * PI / 11f64.sqrt()).powf(s) * rgs);
        assert!((aa - bb).abs() < 1e-9 && (aa - lam_direct(2.0 - s)).abs() < 1e-9);
    }
    let pre = (11f64.sqrt() / (2.0 * PI)).powf(3.0) * 2.0;
    let mut sum3 = 0.0;
    for n in 1..=M { sum3 += a[n] as f64 / (n as f64).powf(3.0) }
    let mut eul = 1.0;
    for &p in &primes { let pf = p as f64; eul /= 1.0 - a[p] as f64 * pf.powf(-3.0) + if p == 11 { 0.0 } else { pf * pf.powf(-6.0) } }
    let (dir3, eul3) = (pre * sum3, pre * eul);
    println!("Lambda(3) by the Dirichlet series to {}: {:.7}; by the Euler product to {}: {:.7}", M, dir3, M, eul3);
    assert!((dir3 - lam_direct(3.0)).abs() < 1e-6 && (eul3 - lam_direct(3.0)).abs() < 1e-6);
    let mut l1 = 0.0;
    for n in 1..=40 { l1 += a[n] as f64 / n as f64 * (-2.0 * PI * n as f64 / 11f64.sqrt()).exp() }
    l1 *= 2.0;
    println!("L(f, 1) = 2 sum (a_n/n) e^(-2 pi n/sqrt 11) = {:.9}", l1);
    assert!((l1 - lam_direct(1.0) * 2.0 * PI / 11f64.sqrt()).abs() < 1e-9);
    println!("mistake, no sqrt 11 in Lambda: s = 0.5 gives {:.9} ; s = 1.5 gives {:.9}", 11f64.powf(-0.25) * lam_direct(0.5), 11f64.powf(-0.75) * lam_direct(1.5));
    let true5 = lam_direct(0.5) * (2.0 * PI / 11f64.sqrt()).powf(0.5) / sq;
    let part: Vec<String> = [500, 1000, 2000].iter().map(|&nn| { let mut t = 0.0; for n in 1..=nn { t += a[n] as f64 / (n as f64).sqrt() } format!("{:.3}", t) }).collect();
    println!("mistake, the series at s = 0.5, partial sums to 500, 1000, 2000: {} ; L(f, 0.5) = {:.9}", part.join(", "), true5);
    println!("ALL CHECKS PASS");
}
