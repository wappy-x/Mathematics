// Birch and Swinnerton-Dyer -- the same check as the Python, in Rust.  No crates.
// The curve E: y^2 = x^3 - 2 and its rational point P = (3, 5).  Both sides of the
// strong form are computed by roads that share no arithmetic: L'(E, 1) from point
// counts mod p; the period, height, Tamagawa numbers and torsion.  Ratio: #Sha.
use std::f64::consts::PI;
const A: i64 = 0;
const B: i64 = -2;
const M: usize = 400;
type Q = (i128, i128);                                // a fraction, numerator over denominator

fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i128, d: i128) -> Q { let g = gcd(n, d) * d.signum(); (n / g, d / g) }
fn mul(a: Q, b: Q) -> Q { fr(a.0.checked_mul(b.0).unwrap(), a.1.checked_mul(b.1).unwrap()) }
fn sub(a: Q, b: Q) -> Q { fr(a.0.checked_mul(b.1).unwrap().checked_sub(b.0.checked_mul(a.1).unwrap()).unwrap(), a.1.checked_mul(b.1).unwrap()) }
fn div(a: Q, b: Q) -> Q { mul(a, fr(b.1, b.0)) }
fn show(a: Q) -> String { if a.1 == 1 { format!("{}", a.0) } else { format!("{}/{}", a.0, a.1) } }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn primes(n: usize) -> Vec<usize> { (2..=n).filter(|&p| (2..p).take_while(|d| d * d <= p).all(|d| p % d != 0)).collect() }
fn md(a: i64, p: i64) -> usize { a.rem_euclid(p) as usize }
fn join(v: &[f64], dp: usize) -> String { v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ") }

fn count(p: usize, b: i64) -> usize {                 // points of y^2 = x^3 + b mod p, with O
    let mut sq = vec![0; p];
    for y in 0..p { sq[y * y % p] += 1 }
    1 + (0..p as i64).map(|x| sq[md(x * x * x + b, p as i64)]).sum::<usize>()
}

fn count_brute(p: i64, b: i64) -> i64 {               // second road: try every pair (x, y)
    1 + (0..p).map(|x| (0..p).filter(|y| (y * y - x * x * x - b).rem_euclid(p) == 0).count() as i64).sum::<i64>()
}

fn add(p: (Q, Q), q: (Q, Q)) -> (Q, Q) {              // chord and tangent, exact fractions
    let m = if p == q { div(mul(fr(3, 1), mul(p.0, p.0)), mul(fr(2, 1), p.1)) } else { div(sub(q.1, p.1), sub(q.0, p.0)) };
    let x3 = sub(sub(mul(m, m), p.0), q.0);
    (x3, sub(mul(m, sub(p.0, x3)), p.1))
}

fn e1(x: f64) -> f64 {                                // exponential integral E1, written out
    if x < 1.0 {
        let (mut s, mut t) = (-0.5772156649015329 - x.ln(), 1.0);
        for k in 1..60 { t *= -x / k as f64; s -= t / k as f64 }
        return s;
    }
    let (mut b, mut c, mut d, mut h) = (x + 1.0, 1e300, 1.0 / (x + 1.0), 1.0 / (x + 1.0));
    for i in 1..200 {                                 // continued fraction, Lentz's method
        let ii = (i * i) as f64;
        b += 2.0;
        d = 1.0 / (b - ii * d);
        c = b - ii / c;
        h *= c * d;
    }
    h * (-x).exp()
}

fn agm(mut a: f64, mut b: f64) -> f64 {               // arithmetic-geometric mean
    while (a - b).abs() > 1e-15 * a { (a, b) = ((a + b) / 2.0, (a * b).sqrt()) }
    a
}

fn series(an: &[i64], cond: f64, t: f64, kind: f64) -> f64 { // L(E,1) or L'(E,1), trial conductor and sign
    let (mut tot, r) = (0.0, cond.sqrt());
    for n in 1..=M {
        let (u, v) = (2.0 * PI * n as f64 * t / r, 2.0 * PI * n as f64 / (t * r));
        let f = if kind == 0.0 { e1(u) + e1(v) } else { (-u).exp() + kind * (-v).exp() };
        tot += an[n] as f64 / n as f64 * f;
    }
    tot
}

fn main() {
    let disc = -16 * (4 * A.pow(3) + 27 * B * B);
    println!("curve y^2 = x^3 - 2; discriminant -16(4A^3 + 27B^2) = {}; j = 0", disc);
    println!("P = (3, 5) lies on it, 5^2 = 25 = 3^3 - 2: {}", yn(5 * 5 == 27 - 2));
    let p1 = (fr(3, 1), fr(5, 1));
    let p2 = add(p1, p1);
    let mult = [p1, p2, add(p2, p1), add(p2, p2)];
    for n in 2..=4 { println!("{}P = ({}, {})", n, show(mult[n - 1].0), show(mult[n - 1].1)) }
    let nh: Vec<f64> = mult.iter().enumerate().map(|(i, pt)| (pt.0 .0.abs().max(pt.0 .1) as f64).ln() / ((i + 1) * (i + 1)) as f64).collect();
    println!("naive height of x(nP) over n^2, n = 1 to 4: {}", join(&nh, 4));
    let ps = primes(M);
    let mut cnt = vec![0usize; M + 1];
    for &p in &ps { cnt[p] = count(p, B) }
    let two: Vec<String> = [5, 7, 11, 13].iter().map(|&p| format!("p={}: {} {}", p, cnt[p], count_brute(p as i64, B))).collect();
    println!("points mod p, two roads: {}", two.join(", "));
    let hasse = ps.iter().filter(|&&p| p > 3).all(|&p| ((p + 1) as f64 - cnt[p] as f64).abs() <= 2.0 * (p as f64).sqrt());
    println!("Hasse window at p = 7: 8 +- {:.2}; holds for every p from 5 to {}: {}", 2.0 * 7f64.sqrt(), M, yn(hasse));
    let tors = gcd(cnt[5] as i128, cnt[7] as i128);
    println!("torsion: gcd(#E(F_5), #E(F_7)) = gcd({}, {}) = {}", cnt[5], cnt[7], tors);
    let mut fx = [0u32; 4];
    for p in [2i64, 3] {                              // Tate's algorithm, steps 1 to 3
        let x0 = (0..p).find(|&x| (0..p).any(|y| (y * y - x * x * x - B).rem_euclid(p) == 0 && (2 * y) % p == 0 && (3 * x * x) % p == 0)).unwrap();
        let (a2, a4, a6) = (3 * x0, 3 * x0 * x0, x0 * x0 * x0 + B); // move the singular point to x = 0
        fx[p as usize] = (0..20).filter(|&v| disc % p.pow(v) == 0).max().unwrap();
        println!("p = {}: singular point at x = {}; shifted a2, a4, a6 = {}, {}, {}; p divides all three: {}; p^2 divides a6: {}; so type II, c_{} = 1, f_{} = v_{}(disc) = {}",
                 p, x0, a2, a4, a6, yn(a2 % p == 0 && a4 % p == 0 && a6 % p == 0), yn(a6 % (p * p) == 0), p, p, p, fx[p as usize]);
        assert!(a2 % p == 0 && a4 % p == 0 && a6 % p == 0 && a6 % (p * p) != 0); // Tate's test for type II
    }
    let nc = 2i64.pow(fx[2]) * 3i64.pow(fx[3]);
    println!("conductor N = 2^{} * 3^{} = {}", fx[2], fx[3], nc);
    let mut ap = vec![0i64; M + 1];
    for &p in &ps { ap[p] = if p < 5 { 0 } else { (p + 1) as i64 - cnt[p] as i64 } }
    let small: Vec<String> = ps.iter().filter(|&&p| p <= 31).map(|&p| format!("{}:{}", p, ap[p])).collect();
    println!("a_p for p up to 31: {}", small.join(", "));
    let mut an = vec![0i64; M + 1];
    an[1] = 1;
    for n in 2..=M {                                  // multiply a_n out of the a_p
        let p = *ps.iter().find(|&&q| n % q == 0).unwrap();
        let (mut pk, mut m) = (p, n / p);
        while m % p == 0 { pk *= p; m /= p }
        an[n] = if m > 1 { an[pk] * an[m] } else if pk == p { ap[p] } else if p < 5 { 0 }
                else { ap[p] * an[pk / p] - p as i64 * an[pk / p / p] };
    }
    let ncf = nc as f64;
    let l0: Vec<f64> = [1.2, 1.5].iter().map(|&t| series(&an, ncf, t, -1.0).abs()).collect();
    let l1: Vec<f64> = [1.0, 1.2, 1.5].iter().map(|&t| series(&an, ncf, t, 0.0)).collect();
    println!("size of L(E,1), sign -1, at t = 1.2 and 1.5: {}", join(&l0, 12));
    println!("L'(E,1) at t = 1.0, 1.2, 1.5: {}", join(&l1, 12));
    let w = [series(&an, ncf, 1.0, 1.0), series(&an, ncf, 1.2, 1.0), series(&an, ncf / 2.0, 1.0, 0.0), series(&an, ncf / 2.0, 1.2, 0.0)];
    println!("wrong sign +1: L(E,1) at t = 1.0 and 1.2: {:.4}, {:.4}", w[0], w[1]);
    println!("wrong conductor {}: L'(E,1) at t = 1.0 and 1.2: {:.4}, {:.4}", nc / 2, w[2], w[3]);
    let e = 2f64.powf(1.0 / 3.0);                     // the real root of x^3 - 2
    let z = (3.0 * e * e + A as f64).sqrt();
    let om = 2.0 * PI / agm(2.0 * z.sqrt(), (2.0 * z + 3.0 * e).sqrt());
    let g = |th: f64| -> f64 {                        // integrand after x = e + tan(th)^2
        let u = e + th.tan().powi(2);
        if th < PI / 2.0 { 2.0 / th.cos().powi(2) / (u * u + e * u + e * e).sqrt() } else { 2.0 }
    };
    let hs = PI / 4000.0;                             // Simpson's rule, 2000 steps
    let om_q = hs / 3.0 * (g(0.0) + g(PI / 2.0) + (1..2000).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(i as f64 * hs)).sum::<f64>());
    println!("real period Omega by the AGM: {:.12}; by Simpson's rule: {:.12}", om, om_q);
    let (mut x, mut h) = (3.0f64, 3f64.ln());
    let mut parts = vec![h];
    for j in 0..40 {                                  // Tate's series for the canonical height
        let zz = 1.0 - 2.0 * A as f64 / x.powi(2) - 8.0 * B as f64 / x.powi(3) + (A * A) as f64 / x.powi(4);
        h += zz.ln() / 4f64.powi(j + 1);
        parts.push(h);
        x = x.powi(4) * zz / (4.0 * (x.powi(3) + A as f64 * x + B as f64));
    }
    println!("canonical height, Tate's series after 0 to 5 terms: {}; limit {:.12}", join(&parts[..6], 6), h);
    let rhs = om * h * 1.0 * 1.0 / 1.0;
    let sha = l1[0] / rhs;
    println!("right side Omega * Reg * c_2 * c_3 / tors^2 = {:.6} * {:.6} * 1 * 1 / 1 = {:.12}", om, h, rhs);
    println!("#Sha = L'(E,1) / right side = {:.12}", sha);
    println!("mistake 1, height halved to {:.4}: #Sha comes out {:.4}", h / 2.0, l1[0] / (rhs / 2.0));
    println!("mistake 2, naive height log 3 = {:.4}: #Sha comes out {:.4}", 3f64.ln(), l1[0] / (om * 3f64.ln()));
    let marks = [10, 100, 200, 500, 1000, 2000, 5000, 10000, 20000];
    let big = primes(20000);
    let last: Vec<usize> = marks.iter().map(|&m| *big.iter().filter(|&&q| q <= m).max().unwrap()).collect();
    for (b, name) in [(-2, "rank 1, y^2 = x^3 - 2"), (1, "rank 0, y^2 = x^3 + 1")] {
        let (mut pr, mut out) = (1.0f64, vec![]);
        for &p in &big {
            pr *= if p > 3 { count(p, b) as f64 / p as f64 } else { 1.0 };
            if last.contains(&p) { out.push(pr) }
        }
        println!("product of N_p/p up to {:?}, {}: {}", marks, name, join(&out, 2));
    }
    assert!([5, 7, 11, 13].iter().all(|&p| cnt[p] as i64 == count_brute(p as i64, B))); // two roads to N_p
    assert!(tors == 1 && nc == 1728);                                                   // torsion; conductor
    assert!(l0.iter().all(|v| *v < 1e-12) && l1.iter().fold(0.0f64, |m, v| m.max((v - l1[0]).abs())) < 1e-12);
    assert!((w[0] - w[1]).abs() > 1e-3 && (w[2] - w[3]).abs() > 1e-3);
    assert!((om - om_q).abs() < 1e-12 && (nh[3] - h).abs() < 0.01);                   // two roads each
    assert!((sha - 1.0).abs() < 1e-10);                                                 // the strong form
    println!("ALL CHECKS PASS");
}
