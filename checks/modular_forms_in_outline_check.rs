// Modular forms in outline -- the same check as the Python, in Rust.  No crates.
// Delta = q (1 - q)^24 (1 - q^2)^24 ... is the weight-12, level-1 cusp form, and
// its coefficients are Ramanujan's tau(n).  Here q = e^(2 pi i z), not a modulus.
use std::f64::consts::PI;
const N: usize = 40;
const MOD: i128 = 1_000_000_007;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }               // a small complex-number struct
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn inv(self) -> C { let d = self.re * self.re + self.im * self.im; C { re: self.re / d, im: -self.im / d } }
    fn exp(self) -> C { let r = self.re.exp(); C { re: r * self.im.cos(), im: r * self.im.sin() } }
    fn pow(self, k: u32) -> C { (0..k).fold(C { re: 1.0, im: 0.0 }, |a, _| a.mul(self)) }
}
fn show(w: C) -> String { format!("{:.9} {} {:.9}i", w.re, if w.im >= 0.0 { "+" } else { "-" }, w.im.abs()) }
fn mul(a: &[i128], b: &[i128], m: i128) -> Vec<i128> {   // product of two series, cut at q^N
    let mut c = vec![0i128; N + 1];
    for i in 0..=N {
        for j in 0..=N - i {
            c[i + j] = c[i + j].checked_add(a[i].checked_mul(b[j]).unwrap()).unwrap();
            if m > 0 { c[i + j] %= m }
        }
    }
    if m > 0 { c.iter().map(|v| v.rem_euclid(m)).collect() } else { c }
}
fn sigma(k: u32, n: usize) -> i128 { (1..=n).filter(|d| n % d == 0).map(|d| (d as i128).pow(k)).sum() }
fn eis(c: i128, k: u32) -> Vec<i128> { (0..=N).map(|n| if n == 0 { 1 } else { c * sigma(k, n) }).collect() }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn primes(n: usize) -> Vec<usize> { (2..=n).filter(|&p| (2..p).all(|d| p % d != 0)).collect() }
fn series(c: &[i128], z: C) -> C {
    let q = C { re: 0.0, im: 2.0 * PI }.mul(z).exp();
    (0..=N).fold(C { re: 0.0, im: 0.0 }, |s, n| s.add(q.pow(n as u32).scale(c[n] as f64)))
}
fn powmod(mut b: i128, mut e: i128) -> i128 {
    let mut r = 1;
    while e > 0 { if e & 1 == 1 { r = r * b % MOD } b = b * b % MOD; e >>= 1 }
    r
}
fn det_mod(mut m: Vec<Vec<i128>>) -> i128 {             // determinant mod MOD, by elimination
    let mut d = 1;
    for c in 0..m.len() {
        let piv = match (c..m.len()).find(|&r| m[r][c] != 0) { Some(r) => r, None => return 0 };
        m.swap(c, piv);
        d = d * m[c][c] % MOD;
        let inv = powmod(m[c][c], MOD - 2);
        for r in c + 1..m.len() {
            let f = m[r][c] * inv % MOD;
            let row_c = m[c].clone();
            for (x, y) in m[r].iter_mut().zip(row_c.iter()) { *x = (*x - f * y).rem_euclid(MOD) }
        }
    }
    d
}
fn walk(vals: &[i64], len: usize, s: i64, sq: i64, e8: &mut [u64; 4]) {   // doubled coordinates y = 2x
    if len == 8 {
        if s % 4 == 0 && sq % 8 == 0 && sq > 0 && sq <= 24 { e8[(sq / 8) as usize] += 1 }
        return;
    }
    for &v in vals { if sq + v * v <= 24 { walk(vals, len + 1, s + v, sq + v * v, e8) } }
}

fn main() {
    let mut p = vec![0i128; N + 1]; p[0] = 1;            // road 1: multiply out the product
    for n in 1..=N { for _ in 0..24 { for i in (n..=N).rev() { p[i] -= p[i - n] } } }
    let mut tau = vec![0i128]; tau.extend_from_slice(&p[..N]);
    let (e4, e6) = (eis(240, 3), eis(-504, 5));         // road 2: Eisenstein series
    let (e43, e62) = (mul(&mul(&e4, &e4, 0), &e4, 0), mul(&e6, &e6, 0));
    let d: Vec<i128> = e43.iter().zip(e62.iter()).map(|(x, y)| (x - y).div_euclid(1728)).collect();
    let mut one = vec![0i128; N + 1]; one[0] = 1; for _ in 0..24 { for i in (1..=N).rev() { one[i] -= one[i - 1] } }
    println!("(1 - q)^24 starts {:?}", &one[..4]);
    println!("E4 starts {:?} ; E6 starts {:?}", &e4[..4], &e6[..4]);
    println!("E4^3: q {}, q^2 {};  E6^2: q {}, q^2 {}", e43[1], e43[2], e62[1], e62[2]);
    println!("tau(1..12): {:?}", &tau[1..13]);
    let mut t0 = tau.clone(); t0[0] = 0;
    println!("product and (E4^3 - E6^2)/1728 agree to q^{}: {}", N, yn(d == t0));

    let z = C { re: 0.3, im: 1.1 }; let w = z.inv().scale(-1.0);
    let (dz, dw) = (series(&t0, z), series(&t0, w));
    let e2 = eis(-24, 1);
    let gap = series(&e2, w).sub(z.pow(2).mul(series(&e2, z)));
    let pred = C { re: 0.0, im: -6.0 / PI }.mul(z);
    println!("z = {}; -1/z = {}; |z| = {:.6}, |-1/z| = {:.6}; |q| = {:.6}", show(z), show(w), z.abs(), w.abs(),
             C { re: 0.0, im: 2.0 * PI }.mul(z).exp().abs());
    println!("Delta(z) x 1000 = {}", show(dz.scale(1000.0)));
    println!("Delta(-1/z) x 1000 = {}", show(dw.scale(1000.0)));
    println!("z^12 Delta(z) x 1000 = {}", show(z.pow(12).mul(dz).scale(1000.0)));
    println!("weight 11 instead: z^11 Delta(z) x 1000 = {}", show(z.pow(11).mul(dz).scale(1000.0)));
    println!("E2(-1/z) - z^2 E2(z) = {}; -6iz/pi = {}", show(gap), show(pred));

    let (mut cop, mut pp) = (0, 0);
    for m in 2..=N { for n in m + 1..=N / m {
        if (2..=m).all(|d| m % d != 0 || n % d != 0) { assert!(tau[m * n] == tau[m] * tau[n]); cop += 1 }
    } }
    for &p in &primes(N) {
        let mut r = p;
        while r * p <= N {
            assert!(tau[r * p] == tau[p] * tau[r] - (p as i128).pow(11) * tau[r / p]); pp += 1; r *= p;
        }
    }
    println!("Hecke relations to {}: {} coprime pairs, {} prime-power steps, all hold", N, cop, pp);
    println!("mistake, 4 = 2 x 2 not coprime: tau(4) = {}, tau(2)^2 = {}", tau[4], tau[2] * tau[2]);
    let cong = (1..=N).all(|n| (sigma(11, n) - tau[n]) % 691 == 0); let s2 = sigma(11, 2);
    println!("sigma11(n) - tau(n) divisible by 691 for n = 1..{}: {}; n = 2: {} - ({}) = {} = {} x 691",
             N, yn(cong), s2, tau[2], s2 - tau[2], (s2 - tau[2]) / 691);
    let xs: Vec<String> = primes(N).iter().map(|&p| format!("{:.3}", tau[p] as f64 / (2.0 * (p as f64).powf(5.5)))).collect();
    let deligne = primes(N).iter().all(|&p| tau[p] * tau[p] <= 4 * (p as i128).pow(11));
    println!("tau(p)/(2 p^5.5), p = 2..37: {} ; all in [-1, 1]: {}", xs.join(", "), yn(deligne));

    let (e4m, e6m) = (e4.iter().map(|v| v.rem_euclid(MOD)).collect::<Vec<_>>(), e6.iter().map(|v| v.rem_euclid(MOD)).collect::<Vec<_>>());
    let (mut dims, mut counts, mut pinned) = (vec![], vec![], true);
    for k in (0..=36usize).step_by(2) {
        dims.push(k / 12 + if k % 12 == 2 { 0 } else { 1 });
        let mons: Vec<(usize, usize)> = (0..=k / 4).filter(|a| (k - 4 * a) % 6 == 0).map(|a| (a, (k - 4 * a) / 6)).collect();
        counts.push(mons.len());
        let mut rows = vec![];
        for &(a, b) in &mons {
            let mut s = vec![0i128; N + 1]; s[0] = 1;
            for _ in 0..a { s = mul(&s, &e4m, MOD) }
            for _ in 0..b { s = mul(&s, &e6m, MOD) }
            rows.push(s[..mons.len()].to_vec());
        }
        pinned = pinned && (mons.is_empty() || det_mod(rows) != 0);
    }
    println!("dim M_k, k = 0, 2, ..., 36, by floor(k/12) + [k not 2 mod 12]: {:?}", dims);
    println!("count of products E4^a E6^b of weight k:                     {:?}", counts);
    println!("each space pinned by its first dim coefficients (det mod {} nonzero): {}", MOD, yn(pinned));

    let mut e8 = [0u64; 4]; walk(&[-4, -2, 0, 2, 4], 0, 0, 0, &mut e8); walk(&[-3, -1, 1, 3], 0, 0, 0, &mut e8);
    println!("E8 vectors of norm 2, 4, 6 by brute force: {:?}; 240 sigma3(n): {:?}", &e8[1..], &e4[1..4]);
    let leech: Vec<i128> = (1..=4).map(|n| 65520 * (sigma(11, n) - tau[n]) / 691).collect();
    println!("Leech vectors of norm 2, 4, 6, 8 from E12 - (65520/691) Delta: {:?}", leech);
    println!("mistake, E12 alone: 65520 x {}/691 = {:.4}, not a whole number", s2, 65520.0 * s2 as f64 / 691.0);
    let mut r4 = vec![0i128; N + 1];                     // four squares by brute force, against Jacobi's divisor formula
    for x in -6i64..=6 { for y in -6i64..=6 { for z in -6i64..=6 { for t in -6i64..=6 { let s = (x * x + y * y + z * z + t * t) as usize; if s <= N { r4[s] += 1 } } } } }
    let jac: Vec<i128> = (0..=N).map(|n| 8 * (1..=n).filter(|d| n % d == 0 && d % 4 != 0).map(|d| d as i128).sum::<i128>()).collect();
    println!("four squares, ways for n = 1..8: {:?}; 8 x (divisors not divisible by 4): {:?}; equal to n = {}: {}", &r4[1..9], &jac[1..9], N, yn(r4[1..] == jac[1..]));
    const M: usize = 400;                                // level 32: q (1 - q^4)^2 (1 - q^8)^2 ...
    let mut g = vec![0i128; M + 1]; g[0] = 1;
    for n in 1..=M / 4 { for m in [4 * n, 8 * n] { for _ in 0..2 { for i in (m..=M).rev() { g[i] -= g[i - m] } } } }
    let f32 = |z: C| { let q = C { re: 0.0, im: 2.0 * PI }.mul(z).exp();
        (0..=M).fold(C { re: 0.0, im: 0.0 }, |s, n| s.add(q.pow(n as u32 + 1).scale(g[n] as f64))) };
    let u = C { re: -1.0 / 64.0, im: 2.0 / 64.0 }; let c = u.scale(32.0).add(C { re: 1.0, im: 0.0 });
    let v = u.mul(c.inv()); let (fu, fv) = (f32(u), f32(v));
    println!("level 32: u = {}, 32u + 1 = {}, u/(32u + 1) = {}", show(u), show(c), show(v));
    println!("f(u) = {}", show(fu));
    println!("f(u/(32u + 1)) = {}; (32u + 1)^2 f(u) = {}", show(fv), show(c.pow(2).mul(fu)));
    println!("weight 1 instead: (32u + 1) f(u) = {}", show(c.mul(fu)));
    let ap: Vec<i128> = primes(N)[1..].iter().map(|&p| g[p - 1]).collect();
    let pts: Vec<i128> = primes(N)[1..].iter().map(|&p| {
        let p = p as i128;
        p - (0..p).map(|x| (0..p).filter(|y| (y * y - x * x * x + x).rem_euclid(p) == 0).count() as i128).sum::<i128>()
    }).collect();
    println!("level 32, weight 2, a_p for p = 3..37: {:?}", ap);
    println!("p minus the points of y^2 = x^3 - x mod p:   {:?}", pts);
    println!("figure, z = ({:.6}, {:.6}), -1/z = ({:.6}, {:.6}), rho = (-0.500000, {:.6}), i = (0, 1)",
             z.re, z.im, w.re, w.im, 3f64.sqrt() / 2.0);

    assert!(d == t0 && tau[1..6] == [1, -24, 252, -1472, 4830]);               // two roads
    assert!(dw.sub(z.pow(12).mul(dz)).abs() < 1e-12 * dw.abs());                // weight 12
    assert!(gap.sub(pred).abs() < 1e-9 && dw.sub(z.pow(11).mul(dz)).abs() > 1e-4);
    assert!(cong && deligne && tau[4] != tau[2] * tau[2] && r4[1..] == jac[1..]);   // Jacobi's four squares
    assert!(dims == counts && pinned && e8[1..].iter().zip(&e4[1..4]).all(|(a, b)| *a as i128 == *b));
    assert!(leech[..3] == [0, 196560, 16773120] && ap == pts && fv.sub(c.pow(2).mul(fu)).abs() < 1e-9);                 // Conway-Sloane; the curve
    println!("ALL CHECKS PASS");
}
