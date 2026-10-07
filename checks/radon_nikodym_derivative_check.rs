// The Radon-Nikodym derivative -- the same check as the Python, in Rust.  No
// crates.  Exact fractions are done by hand on small integers: a fair die P, a
// loaded die Q, a third die R, the exchange rate Z = dQ/dP, the change of
// measure, the chain rule through R and the reciprocal rule back.  Then
// SplitMix64 rolls (seed 2026), and the bus-wait companion (rate 1 under P,
// rate 2 under Q) by Simpson's rule and by weighted draws, then the mistakes.
#[derive(Clone, Copy, PartialEq)]
struct Fr { n: i64, d: i64 }

fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn fr(n: i64, d: i64) -> Fr {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    Fr { n: s * n / g, d: s * d / g }
}
fn add(a: Fr, b: Fr) -> Fr { fr(a.n * b.d + b.n * a.d, a.d * b.d) }
fn mul(a: Fr, b: Fr) -> Fr { fr(a.n * b.n, a.d * b.d) }
fn div(a: Fr, b: Fr) -> Fr { fr(a.n * b.d, a.d * b.n) }
fn fl(a: Fr) -> f64 { a.n as f64 / a.d as f64 }
fn st(a: Fr) -> String { if a.d == 1 { format!("{}", a.n) } else { format!("{}/{}", a.n, a.d) } }
fn show(a: Fr) -> String { if a.d > 1 { format!("{} = {:.4}", st(a), fl(a)) } else { st(a) } }
fn rate(nu: &[Fr], mu: &[Fr]) -> Vec<Fr> { nu.iter().zip(mu).map(|(&n, &m)| div(n, m)).collect() }
fn mean(w: &[Fr], v: &[Fr]) -> Fr { w.iter().zip(v).fold(fr(0, 1), |s, (&a, &b)| add(s, mul(a, b))) }
fn times(a: &[Fr], b: &[Fr]) -> Vec<Fr> { a.iter().zip(b).map(|(&x, &y)| mul(x, y)).collect() }
fn join(v: &[String]) -> String { v.join(", ") }

struct Rng(u64);
impl Rng {                                  // SplitMix64, written out; 53 bits into [0, 1)
    fn uniform(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut inner = 0.0;
    for k in 1..n { inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * h) }
    (g(a) + g(b) + inner) * h / 3.0
}

fn main() {
    let faces: Vec<Fr> = (1..=6).map(|k| fr(k, 1)).collect();
    let p = vec![fr(1, 6); 6];
    let q = vec![fr(1, 10), fr(1, 10), fr(1, 10), fr(1, 10), fr(2, 10), fr(4, 10)];
    let r = vec![fr(1, 4), fr(1, 4), fr(2, 10), fr(1, 10), fr(1, 10), fr(1, 10)];
    let q0 = vec![fr(0, 1), fr(2, 10), fr(1, 10), fr(1, 10), fr(2, 10), fr(4, 10)]; // never a 1
    let (z, zqr, zrp, zpq) = (rate(&q, &p), rate(&q, &r), rate(&r, &p), rate(&p, &q));
    let every_event = (0..64u32).all(|mask| {
        let a: Vec<usize> = (0..6).filter(|i| mask >> i & 1 == 1).collect();
        a.iter().fold(fr(0, 1), |s, &i| add(s, q[i])) == a.iter().fold(fr(0, 1), |s, &i| add(s, mul(z[i], p[i])))
    });
    let direct = mean(&q, &faces);
    let changed = mean(&p, &times(&faces, &z));
    let chain = times(&zqr, &zrp);
    let via_r = mean(&r, &times(&faces, &zqr));
    let back = mean(&q, &times(&faces, &zpq));
    let dec = |v: &[Fr]| join(&v.iter().map(|&x| format!("{:?}", fl(x))).collect::<Vec<_>>());
    println!("dice as decimals: P {:.4} each; Q {}; R {}", fl(p[0]), dec(&q), dec(&r));
    println!("face | P | Q | R | Z = dQ/dP | dQ/dR | dR/dP | dP/dQ");
    for i in 0..6 {
        println!("{} | {} | {} | {} | {:.2} | {:.2} | {:.2} | {:.4}", i + 1, st(p[i]), st(q[i]), st(r[i]),
                 fl(z[i]), fl(zqr[i]), fl(zrp[i]), fl(zpq[i]));
    }
    println!("figure, Z per face: {}", join(&z.iter().map(|&x| format!("{:.2}", fl(x))).collect::<Vec<_>>()));
    println!("Q(A) equals the sum over A of Z times P, for all 64 events A: {}", if every_event { "yes" } else { "no" });
    println!("E_P[Z] = {}", st(mean(&p, &z)));
    println!("E_Q[face], directly: {}", show(direct));
    println!("E_P[face x Z], by the change of measure: {}", show(changed));
    println!("chain: dQ/dR x dR/dP equals dQ/dP on every face: {}", if chain == z { "yes" } else { "no" });
    println!("E_R[face x dQ/dR], through the third die: {}", show(via_r));
    println!("reciprocal: dP/dQ x dQ/dP on the six faces: {}", join(&times(&zpq, &z).iter().map(|&x| st(x)).collect::<Vec<_>>()));
    let forgot = mean(&p, &faces);
    println!("E_Q[dP/dQ] = {}; E_Q[face x dP/dQ] = {}; E_P[face] = {}", st(mean(&q, &zpq)), show(back), show(forgot));

    let n = 200000usize;
    let mut rng = Rng(2026);
    let zf: Vec<f64> = z.iter().map(|&x| fl(x)).collect();
    let mut cum = vec![0.0f64; 6];
    let mut acc = 0.0;
    for k in 0..6 { acc += fl(q[k]); cum[k] = acc; }
    let (mut s1, mut s2, mut s3, mut s4) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..n {
        let face = (6.0 * rng.uniform()) as usize + 1;   // a fair roll, weighted by the exchange rate
        let w = face as f64 * zf[face - 1];
        s1 += w;
        s2 += w * w;
        let u = rng.uniform();                           // a loaded roll, by its cumulative weights
        let f = (0..6).find(|&k| u < cum[k] || k == 5).unwrap() as f64 + 1.0;
        s3 += f;
        s4 += f * f;
    }
    let nf = n as f64;
    let (m1, m3) = (s1 / nf, s3 / nf);
    let se1 = ((s2 / nf - m1 * m1) / nf).sqrt();
    let se3 = ((s4 / nf - m3 * m3) / nf).sqrt();
    println!("draws, seed 2026: {} fair rolls, mean of face x Z = {:.4} (s.e. {:.4})", n, m1, se1);
    println!("draws: {} loaded rolls, mean face = {:.4} (s.e. {:.4})", n, m3, se3);

    let zb = |t: f64| 2.0 * (-t).exp();              // bus: dQ/dP at wait t minutes
    let pb = |t: f64| (-t).exp();
    let ez = simpson(&|t| zb(t) * pb(t), 0.0, 40.0, 4000);
    let et = simpson(&|t| t * zb(t) * pb(t), 0.0, 40.0, 4000);
    let eq = simpson(&|t| t * 2.0 * (-2.0 * t).exp(), 0.0, 40.0, 4000);
    let (mut sw, mut sw2) = (0.0, 0.0);
    for _ in 0..n {
        let t = -(1.0 - rng.uniform()).ln();         // a rate-1 wait, weighted by the exchange rate
        let w = t * zb(t);
        sw += w;
        sw2 += w * w;
    }
    let mw = sw / nf;
    let sew = ((sw2 / nf - mw * mw) / nf).sqrt();
    println!("bus: E_P[Z] by Simpson = {:.6}", ez);
    println!("bus: E_Q[T] by Simpson on the rate-2 density = {:.6}; exact 1/2", eq);
    println!("bus: E_P[T x Z] by Simpson = {:.6}", et);
    println!("bus: {} rate-1 draws, mean of T x Z = {:.4} (s.e. {:.4})", n, mw, sew);
    let ts: Vec<f64> = (0..7).map(|k| 0.5 * k as f64).collect();
    let row = |g: &dyn Fn(f64) -> f64, dp: usize| join(&ts.iter().map(|&t| format!("{:.*}", dp, g(t))).collect::<Vec<_>>());
    println!("figure, t: {}", row(&|t| t, 1));
    println!("figure, P density: {}", row(&pb, 2));
    println!("figure, Q density: {}", row(&|t| 2.0 * (-2.0 * t).exp(), 2));
    println!("figure, Z(t): {}", row(&zb, 2));

    let twice = mean(&q, &times(&faces, &z));
    let z0 = rate(&q0, &p);
    let dropped = (0..6).filter(|&i| z0[i].n > 0).fold(fr(0, 1), |s, i| add(s, div(mul(q0[i], faces[i]), z0[i])));
    println!("mistake 1, Z forgotten: E_P[face] = {}, not 22/5", show(forgot));
    println!("mistake 2, Z applied under Q: E_Q[face x Z] = {}, above the top face", show(twice));
    println!("mistake 3, Q' never shows 1, Z' = {}: sum of face / Z' under Q' = {}, not 7/2",
             join(&z0.iter().map(|&x| st(x)).collect::<Vec<_>>()), show(dropped));
    let tries = [fr(1, 1), fr(10, 1), fr(1000, 1)];
    println!("mistake 4, P not << Q': P({{1}}) = {}, but f(1) x Q'({{1}}) for f(1) = 1, 10, 1000: {}",
             st(p[0]), join(&tries.iter().map(|&f| st(mul(f, q0[0]))).collect::<Vec<_>>()));

    assert!(every_event && direct == fr(22, 5));                // exact: Q(A) on all 64 events
    assert!(z == vec![fr(3, 5), fr(3, 5), fr(3, 5), fr(3, 5), fr(6, 5), fr(12, 5)]);   // each rate against the hand value
    assert!(zpq == vec![fr(5, 3), fr(5, 3), fr(5, 3), fr(5, 3), fr(5, 6), fr(5, 12)]); // each rate back against the hand value
    assert!(changed == direct && mean(&p, &z) == fr(1, 1));     // change of measure; Z averages 1
    assert!(chain == z && via_r == direct && back == forgot);   // chain through R; reciprocal back
    assert!((m1 - 4.4).abs() < 4.0 * se1 && (m3 - 4.4).abs() < 4.0 * se3); // draws against the exact answer
    assert!((et - 0.5).abs() < 1e-6 && (mw - 0.5).abs() < 4.0 * sew);      // bus: Simpson and draws against 1/2
    assert!((eq - 0.5).abs() < 1e-6 && (ez - 1.0).abs() < 1e-6);   // bus: rate-2 mean; Z averages 1
    assert!(twice == fr(189, 25) && dropped == fr(10, 3));      // the mistakes, exactly
    println!("ALL CHECKS PASS");
}
