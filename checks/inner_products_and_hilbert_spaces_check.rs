// Inner products and Hilbert spaces -- the check behind the card.  std only, no crates.
// Two 8-sample clips (thousands of counts, 8,000 samples a second): B hears A one sample
// late, plus a little noise.  Roads: inner products summed directly; Cauchy-Schwarz rebuilt
// from the split y = t x + r; polarization from meter readings alone; the parallelogram law
// on four meters, exact and on random pairs; truncations of 1/n against pi^2/6.
// Exact work uses integers (pre-emphasis scaled by 4) and Gaussian integers (re, im).

const A: [i64; 8] = [2, 5, 3, -1, -4, -3, -2, 0];
const B: [i64; 8] = [1, 2, 5, 3, -1, -3, -3, -4];

fn ip(x: &[i64], y: &[i64]) -> i64 { x.iter().zip(y).map(|(a, b)| a * b).sum() }
fn add(x: &[i64], y: &[i64], c: i64) -> Vec<i64> { x.iter().zip(y).map(|(a, b)| a + c * b).collect() }
fn shift(x: &[i64], k: usize) -> Vec<i64> { let mut v = vec![0; k]; v.extend_from_slice(&x[..x.len() - k]); v }
fn n1(x: &[i64]) -> i64 { x.iter().map(|a| a.abs()).sum() }
fn npk(x: &[i64]) -> i64 { x.iter().map(|a| a.abs()).max().unwrap() }
fn sqe4(x: &[i64]) -> i64 { (0..x.len()).map(|n| { let d = 2 * x[n] - if n > 0 { x[n - 1] } else { 0 }; d * d }).sum() }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn frac(n: i64, d: i64) -> String { let g = gcd(n, d); let (n, d) = (n / g, d / g); if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) } }
fn f4(v: f64) -> String { format!("{:.4}", v) }

#[derive(Clone, Copy, PartialEq, Debug)]
struct G { re: i64, im: i64 }                                     // a Gaussian integer re + im i
fn gm(a: G, b: G) -> G { G { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn gc(a: G) -> G { G { re: a.re, im: -a.im } }
fn gip(x: &[G], y: &[G]) -> G { x.iter().zip(y).fold(G { re: 0, im: 0 }, |s, (a, b)| { let p = gm(gc(*a), *b); G { re: s.re + p.re, im: s.im + p.im } }) }
fn gsq(x: &[G]) -> i64 { gip(x, x).re }
fn gadd(x: &[G], y: &[G], c: G) -> Vec<G> { x.iter().zip(y).map(|(a, b)| { let p = gm(c, *b); G { re: a.re + p.re, im: a.im + p.im } }).collect() }
fn cx(z: G) -> String { format!("{}{}{}i", z.re, if z.im >= 0 { "+" } else { "-" }, z.im.abs()) }
const I: [G; 4] = [G { re: 1, im: 0 }, G { re: 0, im: 1 }, G { re: -1, im: 0 }, G { re: 0, im: -1 }];

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                                     // a float complex number
fn cip(x: &[C], y: &[C]) -> C {
    let mut s = C { re: 0.0, im: 0.0 };
    for (a, b) in x.iter().zip(y) { let (ar, ai) = (a.re, -a.im); s.re += ar * b.re - ai * b.im; s.im += ar * b.im + ai * b.re; }
    s
}
fn cn2(x: &[C]) -> f64 { cip(x, x).re.sqrt() }
fn cn1(x: &[C]) -> f64 { x.iter().fold(0.0, |s, a| s + a.re.hypot(a.im)) }
fn cpk(x: &[C]) -> f64 { x.iter().fold(0.0f64, |m, a| m.max(a.re.hypot(a.im))) }
fn cadd(x: &[C], y: &[C], c: f64) -> Vec<C> { x.iter().zip(y).map(|(a, b)| C { re: a.re + c * b.re, im: a.im + c * b.im }).collect() }

fn main() {
    // 1. correlation of the two clips at each lag: the cosine of the angle between them
    println!("lag,inner product,squared lengths,correlation");
    let mut best = 0; let mut bv = f64::MIN;
    for k in 0..4 {
        let x = shift(&A, k);
        let (p, xx, bb) = (ip(&x, &B), ip(&x, &x), ip(&B, &B));
        println!("lag {},{},{} {},{}", k, p, xx, bb, f4(p as f64 / ((xx as f64).sqrt() * (bb as f64).sqrt())));
        let v = p as f64 / (xx as f64).sqrt(); if v > bv { bv = v; best = k; }
    }
    println!("delay,{} sample,{:.3} ms", best, 1000.0 * best as f64 / 8000.0);
    assert!(best == 1);
    // 2. Cauchy-Schwarz as a split: B = t (shifted A) + r, t = p/q, so q r = q B - p x in integers
    let mut r = vec![];
    for k in 0..2 {
        let x = shift(&A, k);
        let (p, q) = (ip(&x, &B), ip(&x, &x)); let g = gcd(p, q); let (p, q) = (p / g, q / g);
        let qr: Vec<i64> = B.iter().zip(&x).map(|(b, a)| q * b - p * a).collect();
        assert!(ip(&x, &qr) == 0 && q * q * ip(&B, &B) == ip(&qr, &qr) + p * p * ip(&x, &x));
        let gap = ip(&x, &x) * ip(&B, &B) - ip(&x, &B).pow(2);
        assert!(gap * q * q == ip(&x, &x) * ip(&qr, &qr));
        println!("split lag {},t {},r squared {},bound {},gap {} = {} - {}", k, frac(p, q), f4(gap as f64 / ip(&x, &x) as f64),
                 f4(((ip(&x, &x) * ip(&B, &B)) as f64).sqrt()), gap, ip(&x, &x) * ip(&B, &B), ip(&x, &B).pow(2));
        r = qr.iter().map(|v| v / q).collect();
    }
    println!("lag 1 remainder, {:?}", r);
    assert!(r == vec![1, 0, 0, 0, 0, 1, 0, -2]);
    // 3. polarization: the inner product from four meter readings, real and complex
    let (s, d) = (add(&A, &B, 1), add(&A, &B, -1));
    println!("polarize real,{} {},{}", ip(&s, &s), ip(&d, &d), (ip(&s, &s) - ip(&d, &d)) / 4);
    assert!(ip(&s, &s) - ip(&d, &d) == 4 * 43 && ip(&A, &B) == 43);
    let dft = |x: &[i64]| -> Vec<G> { (0..3).map(|k: i64| x.iter().enumerate().fold(G { re: 0, im: 0 }, |z, (n, a)| {
        let w = I[((-k * n as i64).rem_euclid(4)) as usize]; G { re: z.re + a * w.re, im: z.im + a * w.im } })).collect() };
    let (xf, yf) = (dft(&A[..4]), dft(&B[..4]));
    println!("frame coefficients, {} | {}", xf.iter().map(|z| cx(*z)).collect::<Vec<_>>().join(" "), yf.iter().map(|z| cx(*z)).collect::<Vec<_>>().join(" "));
    let reads: Vec<i64> = (0..4).map(|m| gsq(&gadd(&xf, &yf, I[m]))).collect();
    let mut pol = G { re: 0, im: 0 };
    for m in 0..4 { let w = I[(4 - m) % 4]; pol = G { re: pol.re + w.re * reads[m], im: pol.im + w.im * reads[m] }; }
    assert!(pol.re % 4 == 0 && pol.im % 4 == 0);
    let pol = G { re: pol.re / 4, im: pol.im / 4 }; let z = gip(&xf, &yf);
    println!("polarize complex, {} {} direct {}", reads.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "), cx(pol), cx(z));
    assert!(pol == z && z == G { re: 98, im: -25 });
    let (zz, pr) = (z.re * z.re + z.im * z.im, gsq(&xf) * gsq(&yf));
    println!("complex CS,squared lengths {} {},{} {},gap {},{} {}", gsq(&xf), gsq(&yf), zz, pr, pr - zz, f4((zz as f64).sqrt()), f4((pr as f64).sqrt()));
    assert!(zz < pr);
    let nc = xf.iter().fold(G { re: 0, im: 0 }, |s, a| { let p = gm(*a, *a); G { re: s.re + p.re, im: s.im + p.im } });
    let one = G { re: 1, im: 0 }; let mone = G { re: -1, im: 0 };
    println!("no conjugate, {} | {} against {} | real polarization, {}", cx(gm(xf[1], xf[1])), cx(nc), gsq(&xf), (gsq(&gadd(&xf, &yf, one)) - gsq(&gadd(&xf, &yf, mone))) / 4);
    // 4. the parallelogram test on four meters, on the clips and on the two unit samples
    let (e0, e1) = ([1i64, 0], [0i64, 1]);
    let vs = [A.to_vec(), B.to_vec(), s.clone(), d.clone()];
    println!("meters on A B A+B A-B,sum {},peak {}", vs.iter().map(|v| n1(v).to_string()).collect::<Vec<_>>().join(" "), vs.iter().map(|v| npk(v).to_string()).collect::<Vec<_>>().join(" "));
    let meters: [(&str, fn(&[i64]) -> f64); 4] = [("RMS", |x| ip(x, x) as f64), ("pre-emphasis", |x| sqe4(x) as f64 / 4.0),
        ("sum", |x| (n1(x) * n1(x)) as f64), ("peak", |x| (npk(x) * npk(x)) as f64)];
    for (name, nm) in meters.iter() {
        let (lhs, rhs) = (nm(&s) + nm(&d), 2.0 * nm(&A) + 2.0 * nm(&B));
        let (l0, r0) = (nm(&add(&e0, &e1, 1)) + nm(&add(&e0, &e1, -1)), 2.0 * nm(&e0) + 2.0 * nm(&e1));
        println!("parallelogram {},clips {:.2} vs {:.2},unit samples {:.2} vs {:.2}", name, lhs, rhs, l0, r0);
    }
    assert!(n1(&s).pow(2) + n1(&d).pow(2) == 1924 && npk(&s).pow(2) + npk(&d).pow(2) == 80);
    println!("one lucky pair (A and 2A), sum meter, {} {}", n1(&add(&A, &A, 2)).pow(2) + n1(&add(&A, &A, -2)).pow(2), 2 * n1(&A).pow(2) + 2 * n1(&add(&A, &A, 1)).pow(2));
    let pk4 = |x: &[i64], y: &[i64]| npk(&add(x, y, 1)).pow(2) - npk(&add(x, y, -1)).pow(2);   // 4 times the polarized peak
    let ab = add(&A, &B, 1);
    println!("polarized peak,A B {},A+B B {},B B {},sum of parts {}", frac(pk4(&A, &B), 4), frac(pk4(&ab, &B), 4), frac(pk4(&B, &B), 4), frac(pk4(&A, &B) + pk4(&B, &B), 4));
    assert!(pk4(&ab, &B) != pk4(&A, &B) + pk4(&B, &B));
    // 5. the pre-emphasis meter's hidden inner product, recovered by polarization (scaled by 16)
    let pe16 = |x: &[i64], y: &[i64]| sqe4(&add(x, y, 1)) - sqe4(&add(x, y, -1));
    let fa: Vec<i64> = (0..8).map(|n| 2 * A[n] - if n > 0 { A[n - 1] } else { 0 }).collect();
    let fb: Vec<i64> = (0..8).map(|n| 2 * B[n] - if n > 0 { B[n - 1] } else { 0 }).collect();
    println!("pre-emphasis, {:.2} {:.2} polarized {:.2} direct {:.2}", sqe4(&A) as f64 / 4.0, sqe4(&B) as f64 / 4.0, pe16(&A, &B) as f64 / 16.0, ip(&fa, &fb) as f64 / 4.0);
    let e = |i: usize| -> Vec<i64> { (0..3).map(|j| (i == j) as i64).collect() };
    let gram: Vec<Vec<i64>> = (0..3).map(|i| (0..3).map(|k| pe16(&e(i), &e(k))).collect()).collect();
    println!("pre-emphasis Gram, three samples, {}", gram.iter().map(|row| row.iter().map(|g| frac(*g, 16)).collect::<Vec<_>>().join(" ")).collect::<Vec<_>>().join(" | "));
    assert!(pe16(&A, &B) == 4 * ip(&fa, &fb) && gram[0][0] == 20 && gram[0][1] == -8 && gram[0][2] == 0);
    // 6. random pairs from SplitMix64, seed 20261115: worst Cauchy-Schwarz ratio, worst law defect
    let mut st: u64 = 20261115;
    let mut rnd = || { st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 4503599627370496.0 - 1.0 };
    let (mut worst, mut dfl) = (0.0f64, [0.0f64; 3]);
    let cm: [fn(&[C]) -> f64; 3] = [cn2, cn1, cpk];
    for _ in 0..2000 {
        let x: Vec<C> = (0..8).map(|_| { let re = rnd(); C { re, im: rnd() } }).collect();
        let y: Vec<C> = (0..8).map(|_| { let re = rnd(); C { re, im: rnd() } }).collect();
        let z = cip(&x, &y); worst = worst.max(z.re.hypot(z.im) / (cn2(&x) * cn2(&y)));
        for (j, nm) in cm.iter().enumerate() {
            let q = nm(&cadd(&x, &y, 1.0)).powi(2) + nm(&cadd(&x, &y, -1.0)).powi(2) - 2.0 * nm(&x).powi(2) - 2.0 * nm(&y).powi(2);
            dfl[j] = dfl[j].max(q.abs() / (nm(&x).powi(2) + nm(&y).powi(2)));
        }
    }
    println!("random 2000 complex pairs,worst ratio {},law defect RMS sum peak {} {} {}", f4(worst), f4(dfl[0]), f4(dfl[1]), f4(dfl[2]));
    assert!(worst < 1.0 && dfl[0] < 1e-12 && dfl[1] > 0.1 && dfl[2] > 0.1);
    // 7. completeness: the list 1, 1/2, 1/3, ... cut at N; the cuts settle, the limit is not a finite list
    let full = std::f64::consts::PI * std::f64::consts::PI / 6.0;
    for n in [10u64, 100, 1000, 10000] {
        let sn: f64 = (1..=n).map(|k| 1.0 / ((k * k) as f64)).fold(0.0, |a, b| a + b);
        let gapn: f64 = (n + 1..=2 * n).map(|k| 1.0 / ((k * k) as f64)).fold(0.0, |a, b| a + b);
        println!("truncate N {},energy {:.6},N times missing {},distance to 2N {:.6}", n, sn, f4(n as f64 * (full - sn)), gapn.sqrt());
        assert!((n as f64 * (full - sn) - 1.0).abs() < 1.0 / n as f64);
    }
    println!("limit energy pi^2/6,{:.6}", full);
    // 8. figure: unit balls of four meters on two samples, radius in four directions
    let h = 0.5f64.sqrt();
    let ne2 = |v: [f64; 2]| (v[0] * v[0] + (v[1] - v[0] / 2.0) * (v[1] - v[0] / 2.0)).sqrt();
    let fm: [(&str, Box<dyn Fn([f64; 2]) -> f64>); 4] = [("sum", Box::new(|v: [f64; 2]| v[0].abs() + v[1].abs())),
        ("RMS", Box::new(|v: [f64; 2]| (v[0] * v[0] + v[1] * v[1]).sqrt())), ("peak", Box::new(|v: [f64; 2]| v[0].abs().max(v[1].abs()))), ("pre-emphasis", Box::new(ne2))];
    for (name, nm) in fm.iter() {
        let rs: Vec<String> = [[1.0, 0.0], [h, h], [0.0, 1.0], [-h, h]].iter().map(|d| f4(1.0 / nm(*d))).collect();
        println!("figure,{} radius at 0 45 90 135 degrees,{}", name, rs.join(" "));
    }
    let (lo, hi) = ((9.0 - 17f64.sqrt()) / 8.0, (9.0 + 17f64.sqrt()) / 8.0);
    let ax0 = [1.0, 2.0 * (1.25 - lo)]; let l = (ax0[0] * ax0[0] + ax0[1] * ax0[1]).sqrt(); let ax = [ax0[0] / l, ax0[1] / l];
    println!("figure,pre-emphasis ellipse semi-axes {} {},tilt {:.1} degrees", f4(1.0 / lo.sqrt()), f4(1.0 / hi.sqrt()), ax[1].atan2(ax[0]).to_degrees());
    assert!((1.0 / ne2(ax) - 1.0 / lo.sqrt()).abs() < 1e-12);
    // 9. try changing: the speech-standard coefficient 0.97 (scaled by 100); a 4-power meter
    let p97 = |x: &[i64]| -> i64 { (0..8).map(|n| { let d = 100 * x[n] - 97 * if n > 0 { x[n - 1] } else { 0 }; d * d }).sum() };
    println!("try coefficient 0.97,clips {:.4} vs {:.4}", (p97(&s) + p97(&d)) as f64 / 10000.0, (2 * p97(&A) + 2 * p97(&B)) as f64 / 10000.0);
    assert!(p97(&s) + p97(&d) == 2 * p97(&A) + 2 * p97(&B));
    let n4sq = |x: &[i64]| (x.iter().map(|a| a.pow(4)).sum::<i64>() as f64).sqrt();
    println!("try 4-power meter,clips {:.2} vs {:.2}", n4sq(&s) + n4sq(&d), 2.0 * n4sq(&A) + 2.0 * n4sq(&B));
    println!("ALL CHECKS PASS");
}
