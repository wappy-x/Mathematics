// Apery's theorem by Beukers' integral -- the check behind the card.  std only, no crates.
// Road 1: exact whole numbers A_n, B_n with d_n^3 I_n = A_n + B_n zeta(3), zeta(3) to 54 digits.
// Road 2: the triple integral I_n by Gauss-Legendre quadrature, in floating point.
// Also: Apery numbers by a sum and by a recurrence; the bound (sqrt2 - 1)^4 by a grid search.
use std::f64::consts::PI;
const B9: u64 = 1_000_000_000;               // big numbers: base 10^9 limbs, lowest first

fn trim(mut v: Vec<u64>) -> Vec<u64> { while v.len() > 1 && *v.last().unwrap() == 0 { v.pop(); } v }
fn big(mut x: u128) -> Vec<u64> { let mut v = vec![]; while x > 0 { v.push((x % B9 as u128) as u64); x /= B9 as u128; } v }
fn mul(v: &mut Vec<u64>, m: u64) {
    let mut c = 0u128;
    for d in v.iter_mut() { let t = *d as u128 * m as u128 + c; *d = (t % B9 as u128) as u64; c = t / B9 as u128; }
    while c > 0 { v.push((c % B9 as u128) as u64); c /= B9 as u128; }
}
fn div(v: &mut Vec<u64>, m: u64) {
    let mut r = 0u128;
    for d in v.iter_mut().rev() { let t = r * B9 as u128 + *d as u128; *d = (t / m as u128) as u64; r = t % m as u128; }
    *v = trim(v.clone());
}
fn addsub(a: &[u64], b: &[u64], sign: i64) -> Vec<u64> { // a + b, or a - b when a >= b
    let (mut out, mut c) = (vec![], 0i64);
    for i in 0..a.len().max(b.len()) {
        let t = *a.get(i).unwrap_or(&0) as i64 + sign * *b.get(i).unwrap_or(&0) as i64 + c;
        c = if t < 0 { -1 } else { t / B9 as i64 }; out.push(t.rem_euclid(B9 as i64) as u64);
    }
    if c > 0 { out.push(c as u64); }
    assert!(c >= 0); trim(out)
}
fn shift(v: &[u64], k: usize) -> Vec<u64> { let mut o = vec![0; k]; o.extend_from_slice(v); o }
fn tof(v: &[u64]) -> f64 { v.iter().rev().fold(0.0, |s, &d| s * B9 as f64 + d as f64) }
fn zero(v: &[u64]) -> bool { v.iter().all(|&d| d == 0) }
fn commas(x: i128) -> String {
    let s = x.unsigned_abs().to_string();
    let mut o = String::new();
    for (i, ch) in s.chars().enumerate() { if i > 0 && (s.len() - i) % 3 == 0 { o.push(','); } o.push(ch); }
    if x < 0 { format!("-{}", o) } else { o }
}
fn gcd(a: u128, b: u128) -> u128 { if b == 0 { a } else { gcd(b, a % b) } }
fn lcm_to(n: u128) -> u128 { (1..=n).fold(1, |d, k| d * k / gcd(d, k)) } // d_n = lcm(1, ..., n)
fn comb(n: i128, k: i128) -> i128 { (0..k).fold(1, |c, i| c * (n - i) / (i + 1)) }
fn coeffs(n: i128) -> Vec<i128> { (0..=n).map(|k| (1 - 2 * (k % 2)) * comb(n, k) * comb(n + k, k)).collect() }
fn jrs(r: usize, s: usize, d: i128) -> (i128, i128) { // d^3 J(r, s) = A + B zeta(3), by Step 1's formula
    let (lo, hi) = (r.min(s) as i128, r.max(s) as i128);
    if r == s { return (-2 * (1..=hi).map(|m| (d / m).pow(3)).sum::<i128>(), 2 * d * d * d); }
    ((d / (hi - lo)) * (lo + 1..=hi).map(|m| (d / m).pow(2)).sum::<i128>(), 0)
}
fn whole_ab(c: &[i128], d: i128) -> (i128, i128) { // d^3 * sum c_r c_s J(r, s) = A + B zeta(3)
    let (mut a, mut b) = (0i128, 0i128);
    for r in 0..c.len() { for s in 0..c.len() {
        let ((ja, jb), k) = (jrs(r, s, d), c[r] * c[s]);
        a = a.checked_add(k.checked_mul(ja).unwrap()).unwrap(); b = b.checked_add(k.checked_mul(jb).unwrap()).unwrap();
    } }
    (a, b)
}
fn gauss(m: usize) -> (Vec<f64>, Vec<f64>) {  // Gauss-Legendre nodes and weights on [0, 1]
    let (mut xs, mut ws) = (vec![], vec![]);
    for i in 1..=m {
        let (mut x, mut dp) = ((PI * (i as f64 - 0.25) / (m as f64 + 0.5)).cos(), 0.0);
        for _ in 0..100 {
            let (mut p0, mut p1) = (1.0, x);
            for j in 2..=m { let p2 = ((2 * j - 1) as f64 * x * p1 - (j - 1) as f64 * p0) / j as f64; p0 = p1; p1 = p2; }
            dp = m as f64 * (x * p1 - p0) / (x * x - 1.0);
            let dx = p1 / dp; x -= dx;
            if dx.abs() < 1e-16 { break; }
        }
        xs.push((1.0 - x) / 2.0); ws.push(1.0 / ((1.0 - x * x) * dp * dp));
    }
    (xs, ws)
}
fn power(b: f64, n: usize) -> f64 { (0..n).fold(1.0, |p, _| p * b) } // b^n by n multiplications
fn triple(g: &(Vec<f64>, Vec<f64>), n: usize, legendre: bool) -> f64 { // x = u^2, y = t^2, w = 1 - v^2
    let (xs, ws) = g;
    let mut s = 0.0;
    for (u, wu) in xs.iter().zip(ws) { for (t, wt) in xs.iter().zip(ws) {
        let (x, y) = (u * u, t * t);
        for (v, wv) in xs.iter().zip(ws) {
            let w = 1.0 - v * v; let den = 1.0 - (1.0 - x * y) * w;
            let f = if legendre { power(x * (1.0 - x) * y * (1.0 - y) * w * (1.0 - w), n) / power(den, n + 1) }
                    else { power(x * (1.0 - x) * y * (1.0 - y), n) / den };
            s += 8.0 * u * t * v * wu * wt * wv * f;
        }
    } }
    s
}
fn main() {
    // zeta(3), road 1: Apery's series 5/2 * sum (-1)^(k+1) / (k^3 C(2k, k)), in whole numbers
    let s54 = shift(&[1], 6);                 // 10^54
    let (mut pos, mut neg, mut t, mut k) = (vec![0u64], vec![0u64], s54.clone(), 1u64);
    div(&mut t, 2);
    while !zero(&t) {
        if k % 2 == 1 { pos = addsub(&pos, &t, 1); } else { neg = addsub(&neg, &t, 1); }
        k += 1; mul(&mut t, (k - 1).pow(3)); div(&mut t, 2 * k * k * (2 * k - 1));
    }
    let mut z = addsub(&pos, &neg, -1); mul(&mut z, 5); div(&mut z, 2);
    // zeta(3), road 2: 1 + 1/8 + ... + 1/1000^3, plus the tail 1/(2N^2) - 1/(2N^3) + 1/(4N^4)
    let (nn, mut z3) = (1000.0f64, 0.0);
    for k in 1..=1000u64 { z3 += 1.0 / (k * k * k) as f64; }
    z3 += 1.0 / (2.0 * nn * nn) - 1.0 / (2.0 * nn * nn * nn) + 1.0 / (4.0 * nn * nn * nn * nn);
    let mut zr = addsub(&z, &shift(&big(5_000_000), 4), 1); // zeta(3) rounded to 11 decimals
    for _ in 0..4 { div(&mut zr, B9); } div(&mut zr, 10_000_000); let zr = tof(&zr) as u64;
    println!("zeta(3): Apery series {}.{:011} | sum to 1000 plus tail {:.11}", zr / 100_000_000_000, zr % 100_000_000_000, z3);
    assert!((tof(&z) / 1e54 - z3).abs() < 1e-14);
    // Apery numbers a_n: road 1 the binomial sum, road 2 the recurrence
    let apery: Vec<i128> = (0..13).map(|n| (0..=n).map(|k| (comb(n, k) * comb(n + k, k)).pow(2)).sum()).collect();
    let mut u: Vec<i128> = vec![1, 5]; for n in 2..13i128 { let l = u.len(); u.push(((34 * n.pow(3) - 51 * n * n + 27 * n - 5) * u[l - 1] - (n - 1).pow(3) * u[l - 2]) / n.pow(3)); }
    assert!(u == apery);
    println!("Apery numbers a_0..a_8: {}", apery[..9].iter().map(|&a| commas(a)).collect::<Vec<_>>().join(", "));
    let r2 = 2f64.powf(0.5);
    println!("a_12 / a_11 = {:.6}; (1 + sqrt2)^4 = 17 + 12 sqrt2 = {:.6}", apery[12] as f64 / apery[11] as f64, 17.0 + 12.0 * r2);
    let (g, m4) = (gauss(24), power(r2 - 1.0, 4)); // m4: the proved maximum (sqrt2 - 1)^4
    println!("J(0, 0) = {} zeta(3); J(1, 1) = {} zeta(3) - {}; J(1, 0) = {}", jrs(0, 0, 1).1, jrs(1, 1, 1).1, -jrs(1, 1, 1).0, jrs(1, 0, 1).0);
    println!("n | d_n | A_n | B_n");
    for n in 1..5 { let d = lcm_to(n) as i128; let (a, b) = whole_ab(&coeffs(n as i128), d); println!("{} | {} | {} | {}", n, d, commas(a), commas(b)); }
    assert!(whole_ab(&coeffs(1), 1) == (-12, 10)); // by hand: I_1 = 10 zeta(3) - 12
    let mut chart = vec![]; println!("n | d_n | d_n^3 I_n exact | by quadrature | bound d_n^3 2 zeta(3) (sqrt2-1)^(4n) | q at least");
    for n in 1..13usize {
        let d = lcm_to(n as u128) as i128;
        let (a, b) = whole_ab(&coeffs(n as i128), d);
        assert!(b == 2 * u[n] * d * d * d);     // the zeta(3) part is twice the Apery number, by the recurrence
        let mut p = z.clone();                 // V = B Z + A 10^54 = d^3 I_n in units of 10^-54
        for f in [2, apery[n] as u64, d as u64, d as u64, d as u64] { mul(&mut p, f); }
        let v = addsub(&p, &shift(&big((-a) as u128), 6), -1);
        let (quad, bound) = ((d * d * d) as f64 * triple(&g, n, true), (2 * d * d * d) as f64 * z3 * power(m4, n));
        let (vf, mut rv) = (tof(&v), addsub(&v, &shift(&big(500_000), 4), 1)[4..].to_vec());
        assert!(!zero(&v) && (quad / (vf / 1e54) - 1.0).abs() < 1e-6 && vf / 1e54 < bound);
        div(&mut rv, 1_000_000);
        println!("{} | {} | 0.{:012} | {:.12} | {:.12} | {}", n, commas(d), tof(&rv) as u64, quad, bound, commas((1e54 / vf) as i128 + 1));
        chart.push(((1e54 / vf).log10() + 3.0 * (d as f64).log10(), 3.0 * (d as f64).log10()));
    }
    println!("chart log10(1/I_n): {}", chart.iter().map(|c| format!("{:.2}", c.0)).collect::<Vec<_>>().join(", "));
    println!("chart log10(d_n^3): {}", chart.iter().map(|c| format!("{:.2}", c.1)).collect::<Vec<_>>().join(", "));
    let (a2, b2) = whole_ab(&coeffs(2), 2); println!("without d_2^3: I_2 = {} zeta(3) - {}", b2 / 8, -a2 as f64 / 8.0);
    // the bound: grid search for the largest x(1-x) y(1-y) w(1-w) / (1 - (1-xy) w)
    let mut best = (0.0f64, 0, 0, 0);
    for i in 1..100 { for j in 1..100 {
        let (x, y) = (i as f64 / 100.0, j as f64 / 100.0);
        for l in 1..100 {
            let w = l as f64 / 100.0; let f = x * (1.0 - x) * y * (1.0 - y) * w * (1.0 - w) / (1.0 - (1.0 - x * y) * w);
            if f > best.0 { best = (f, i, j, l); }
        }
    } }
    println!("grid max {:.10} at x = {}, y = {}, w = {}", best.0, best.1 as f64 / 100.0, best.2 as f64 / 100.0, best.3 as f64 / 100.0);
    println!("proved max (sqrt2 - 1)^4 = {:.10} at x = y = sqrt2 - 1 = {:.6}, w = 1/sqrt2 = {:.6}", m4, r2 - 1.0, 1.0 / r2);
    assert!(m4 - 1e-5 < best.0 && best.0 <= m4);
    // d_n against 3^n: psi(n) = log d_n, a sum of log p over prime powers p^k <= n
    let np = 100000usize;
    let (mut lp, mut sieve) = (vec![0.0f64; np + 1], vec![true; np + 1]);
    for p in 2..=np { if sieve[p] {
        for m in (p * p..=np).step_by(p) { sieve[m] = false; }
        let mut pk = p; while pk <= np { lp[pk] = (p as f64).ln(); pk *= p; }
    } }
    let (mut psi, mut worst) = (0.0f64, (0.0f64, 0usize));
    for n in 1..=np {
        psi += lp[n];
        if psi / n as f64 > worst.0 { worst = (psi / n as f64, n); }
        assert!(psi < n as f64 * 3f64.ln()); // d_n < 3^n, checked to NP
    }
    println!("psi(n)/n up to {}: largest {:.6} at n = {}; at n = {}: {:.6}; log 3 = {:.6}", commas(np as i128), worst.0, worst.1, commas(np as i128), psi / np as f64, 3f64.ln());
    // the race, per step of n
    let e3 = 3f64.exp();
    println!("(sqrt2-1)^4 = {:.6}; times e^3 = {:.6}: {:.6}; times 27: {:.6}; times 64: {:.6}", m4, e3, e3 * m4, 27.0 * m4, 64.0 * m4);
    let (p10, p11) = (triple(&g, 10, false), triple(&g, 11, false));
    println!("plain x^n(1-x)^n: at most 1/16 per step, e^3/16 = {:.6}; I'_11 / I'_10 = {:.6}, times e^3: {:.6}", e3 / 16.0, p11 / p10, e3 * p11 / p10);
    assert!(e3 * p11 / p10 > 1.0);             // the plain integral loses the race already at n = 10 to 11
    let l = 4.0 * (1.0 + r2).ln(); println!("irrationality exponent of zeta(3) at most 1 + (4 log(1+sqrt2) + 3)/(4 log(1+sqrt2) - 3) = {:.4}", 1.0 + (l + 3.0) / (l - 3.0));
    println!("quoted, not computed: Rhin and Viola (2001) lowered the exponent bound to 5.513891");
    println!("1/zeta(3) = {:.6}", 1.0 / z3);
    println!("ALL CHECKS PASS");
}
