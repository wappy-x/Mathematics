// Changing the measure -- the same check as the Python, in Rust.  No crates.
// Ten tosses of a coin that lands heads 0.6 of the time (P), reweighted path
// by path into a fair coin (Q).  Roads: the fair-coin formula, exact
// enumeration of all 1,024 paths in fractions (written out below), and a
// seeded simulation of the loaded coin carrying its weights.
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy, PartialEq)]
struct R { n: i128, d: i128 }                       // an exact fraction n/d, kept in lowest terms
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn r(n: i128, d: i128) -> R {
    let g = gcd(n, d).max(1);
    let s = if d < 0 { -1 } else { 1 };
    R { n: s * n / g, d: s * d / g }
}
impl Add for R { type Output = R; fn add(self, o: R) -> R { let g = gcd(self.d, o.d); r(self.n * (o.d / g) + o.n * (self.d / g), self.d / g * o.d) } }
impl Sub for R { type Output = R; fn sub(self, o: R) -> R { self + r(-o.n, o.d) } }
impl Mul for R { type Output = R; fn mul(self, o: R) -> R { let (a, b) = (r(self.n, o.d), r(o.n, self.d)); R { n: a.n * b.n, d: a.d * b.d } } }
impl Div for R { type Output = R; fn div(self, o: R) -> R { self * r(o.d, o.n) } }
impl R { fn f(self) -> f64 { self.n as f64 / self.d as f64 } }
impl std::fmt::Display for R {
    fn fmt(&self, w: &mut std::fmt::Formatter) -> std::fmt::Result {
        if self.d == 1 { write!(w, "{}", self.n) } else { write!(w, "{}/{}", self.n, self.d) }
    }
}
fn pw(x: R, k: usize) -> R { (0..k).fold(r(1, 1), |a, _| a * x) }
fn comb(n: usize, k: usize) -> i128 { (0..k).fold(1i128, |a, j| a * (n - j) as i128 / (j + 1) as i128) }

const N: usize = 10;
fn ph() -> R { r(3, 5) }
fn qh() -> R { r(1, 2) }
fn up() -> R { qh() / ph() }                        // 5/6 on heads
fn down() -> R { (r(1, 1) - qh()) / (r(1, 1) - ph()) } // 5/4 on tails
fn heads(p: &[u8]) -> usize { p.iter().filter(|&&x| x == 1).count() }
fn prob(p: &[u8], h: R) -> R { p.iter().fold(r(1, 1), |a, &x| a * if x == 1 { h } else { r(1, 1) - h }) }
fn dens(p: &[u8]) -> R { pw(up(), heads(p)) * pw(down(), p.len() - heads(p)) }
fn paths(n: usize) -> Vec<Vec<u8>> { (0..1usize << n).map(|i| (0..n).map(|j| ((i >> j) & 1) as u8).collect()).collect() }
fn wins(p: &[u8]) -> R { r(2 * heads(p) as i128 - p.len() as i128, 1) }
fn big(p: &[u8]) -> R { r(if heads(p) >= 7 { 1 } else { 0 }, 1) }
fn sz(p: &[u8]) -> R { wins(p) * dens(p) }
fn cond(pre: &[u8], f: &dyn Fn(&[u8]) -> R) -> R {  // E^P[f(whole path) | the first tosses]
    paths(N - pre.len()).iter().fold(r(0, 1), |a, s| {
        let w: Vec<u8> = pre.iter().chain(s.iter()).copied().collect();
        a + prob(s, ph()) * f(&w)
    })
}
fn total(f: &dyn Fn(&[u8]) -> R) -> R { paths(N).iter().fold(r(0, 1), |a, w| a + prob(w, ph()) * f(w)) }

struct Mix(u64);                                    // SplitMix64, seed 20260930
impl Mix {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    }
}
fn row(label: &str, vals: Vec<String>) { println!("{:<17}{}", label, vals.join(" ")) }

fn main() {
    let all = paths(N);
    let q_mean = r(N as i128, 1) * (r(2, 1) * qh() - r(1, 1));          // road 1: the fair coin
    let q_big = r((7..=N).map(|k| comb(N, k)).sum::<i128>(), 1 << N);
    let e_z = total(&dens);                                              // road 2: weighted by Z
    let e_sz = total(&sz);
    let e_bz = total(&|w| dens(w) * big(w));
    let p_mean = total(&wins);
    let p_big = total(&big);
    let flip = total(&|w| r(1, 1) / dens(w));                            // mistake: upside down
    let pres: Vec<Vec<u8>> = (0..=N).flat_map(|n| paths(n)).collect();
    let mart = pres.iter().all(|p| cond(p, &dens) == dens(p));
    let smart = pres.iter().all(|p| cond(p, &sz) == sz(p));
    let (hhhh, path1): (Vec<u8>, Vec<u8>) = (vec![1, 1, 1, 1], vec![0, 1, 1, 1, 1, 0, 1, 1, 1, 0]);
    let raw = cond(&hhhh, &sz);
    let (bayes, drift) = (raw / dens(&hhhh), cond(&hhhh, &wins) - wins(&hhhh));

    let (m, mut g) = (200000usize, Mix(20260930));                       // road 3: simulation
    let (mut sums, mut first) = ([0.0f64; 8], Vec::new());
    for i in 0..m {
        let (mut z, mut s, mut h) = (1.0f64, 0i64, 0usize);
        let mut trace = vec![(0usize, '-', 1.0f64, 1.0f64)];
        for n in 1..=N {
            let head = g.unif() < 0.6;
            let f = if head { 5.0 / 6.0 } else { 5.0 / 4.0 };
            z *= f;
            s += if head { 1 } else { -1 };
            h += head as usize;
            trace.push((n, if head { 'H' } else { 'T' }, f, z));
        }
        if i == 0 { first = trace }
        let b = if h >= 7 { 1.0 } else { 0.0 };
        let sf = s as f64;
        for (j, v) in [z, z * z, sf * z, (sf * z) * (sf * z), z * b, z * z * b, sf, sf * sf].iter().enumerate() { sums[j] += v }
    }
    let mf = m as f64;
    let est = |j: usize| { let mu = sums[j] / mf; (mu, ((sums[j + 1] / mf - mu * mu) / (mf - 1.0)).sqrt()) };
    let ((sim_z, se_z), (sim_sz, se_sz), (sim_bz, se_bz), (sim_s, se_s)) = (est(0), est(2), est(4), est(6));

    let (mu, t_end, x_end) = (0.2f64, 10.0f64, 2usize);                  // toss every h, step sqrt(h)
    let mut bridge = Vec::new();
    for k in 0..6i32 {
        let (h, n) = (4f64.powi(-k), 10 * 4usize.pow(k as u32));
        let (hd, a) = ((n + x_end * 2usize.pow(k as u32)) / 2, mu * h.sqrt());
        let zd = (-(hd as f64) * (1.0 + a).ln() - (n - hd) as f64 * (1.0 - a).ln()).exp();
        bridge.push((h, n, zd, (-mu * x_end as f64 + 0.5 * mu * mu * t_end).exp()));
    }
    let mut lf = vec![0.0f64];                                           // log factorials
    for j in 1..=500 { let last = lf[j - 1]; lf.push(last + (j as f64).ln()) }
    let mut far = Vec::new();                                            // P and Q of {Z_n <= 0.01}
    for n in (0..=500usize).step_by(50) {
        let (mut pz, mut qz) = (0.0f64, 0.0f64);
        for k in 0..=n {
            if k as f64 * (5.0f64 / 6.0).ln() + (n - k) as f64 * (5.0f64 / 4.0).ln() <= 0.01f64.ln() {
                let c = lf[n] - lf[k] - lf[n - k];
                pz += (c + k as f64 * 0.6f64.ln() + (n - k) as f64 * 0.4f64.ln()).exp();
                qz += (c + n as f64 * 0.5f64.ln()).exp();
            }
        }
        far.push((n, pz, qz));
    }

    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("loaded coin P: heads 0.6; fair coin Q: heads 0.5; {} tosses, {} paths", N, all.len());
    println!("weights per toss: heads {} = {:.6}, tails {} = {:.6}; log-weight per toss averages {:.6} under P",
             up(), up().f(), down(), down().f(), 0.6 * (5.0f64 / 6.0).ln() + 0.4 * (5.0f64 / 4.0).ln());
    row("heads count k", (0..=N).map(|k| format!("{:6}", k)).collect());
    row("P-law of k", (0..=N).map(|k| format!("{:.4}", (r(comb(N, k), 1) * pw(ph(), k) * pw(r(1, 1) - ph(), N - k)).f())).collect());
    row("Q-law of k", (0..=N).map(|k| format!("{:.4}", (r(comb(N, k), 1) * pw(qh(), N)).f())).collect());
    row("Z_10 at k heads", (0..=N).map(|k| format!("{:.4}", (pw(up(), k) * pw(down(), N - k)).f())).collect());
    println!("path 1, THHHHTHHHT: P {:.8}, Q {:.8}, Z {:.6}, P x Z {:.8}",
             prob(&path1, ph()).f(), prob(&path1, qh()).f(), dens(&path1).f(), (prob(&path1, ph()) * dens(&path1)).f());
    println!("E^P[Z_10] by enumeration: {}", e_z);
    println!("E^Q[S_10]: fair formula {}; E^P[S_10 Z_10] enumerated {}; unweighted E^P[S_10] {:.6}", q_mean, e_sz, p_mean.f());
    println!("Q(7+ heads): counted {}/{} = {:.6}; E^P[Z_10; 7+] enumerated {:.6}; P(7+) {:.6}",
             q_big * r(1 << N, 1), 1 << N, q_big.f(), e_bz.f(), p_big.f());
    println!("E^P[Z_10 | first n tosses] = Z_n for all {} prefixes: {}", pres.len(), yn(mart));
    println!("S_n Z_n a P-martingale on all {} prefixes: {}", pres.len(), yn(smart));
    println!("after HHHH: Z_4 = {:.6}; E^P[S_10 Z_10 | HHHH] over {} endings = {:.6}; divided by Z_4 = {:.6}",
             dens(&hhhh).f(), 1 << (N - 4), raw.f(), bayes.f());
    println!("after HHHH: E^P[S_10 | HHHH] - S_4 = {:.6} (S is not a P-martingale)", drift.f());
    println!("mistake, ratio upside down: weights average {:.6}, formula (26/25)^10 = {:.6}", flip.f(), pw(r(26, 25), N).f());
    for (n, c, f, z) in &first { println!("path 1, toss {:2}: {}  factor {:.4}  Z_n {:.4}", n, c, f, z) }
    println!("simulated, M = {}, seed 20260930:", m);
    println!("  E^P[Z_10]        {:.4} +- {:.4}  (exact 1)", sim_z, se_z);
    println!("  E^P[S_10 Z_10]   {:.4} +- {:.4}  (exact 0)", sim_sz, se_sz);
    println!("  E^P[Z_10; 7+]    {:.4} +- {:.4}  (exact {:.6})", sim_bz, se_bz, q_big.f());
    println!("  unweighted S_10  {:.4} +- {:.4}  (exact 2)", sim_s, se_s);
    for (h, n, zd, zc) in &bridge {
        println!("bridge h = {:.6}, {:5} tosses: Z discrete {:.6}, limit {:.6}, error {:.7}", h, n, zd, zc, (zd - zc).abs());
    }
    row("n", far.iter().map(|x| format!("{:6}", x.0)).collect());
    row("P(Z_n <= 0.01)", far.iter().map(|x| format!("{:.4}", x.1)).collect());
    row("Q(Z_n <= 0.01)", far.iter().map(|x| format!("{:.4}", x.2)).collect());
    row("figure, Z_n", first.iter().map(|x| format!("{:.2}", x.3)).collect());
    row("figure, E^P[Z_n]", (0..=N).map(|n| paths(n).iter().fold(r(0, 1), |a, w| a + prob(w, ph()) * dens(w)).to_string()).collect());
    row("figure, P(<=.01)", far.iter().map(|x| format!("{:.2}", x.1)).collect());
    row("figure, Q(<=.01)", far.iter().map(|x| format!("{:.2}", x.2)).collect());
    assert!(e_z == r(1, 1) && all.iter().all(|w| dens(w).n > 0));       // a probability, equivalent
    assert!(e_sz == q_mean && p_mean == r(N as i128, 1) * (r(2, 1) * ph() - r(1, 1))); // weighted P average = Q formula
    assert!(e_bz == q_big);                                              // weighted P chance = Q count
    assert!(mart && smart);                                              // every prefix, exactly
    assert!(bayes == r(4, 1) + r((N - 4) as i128, 1) * (r(2, 1) * qh() - r(1, 1)) && drift == r((N - 4) as i128, 1) * (r(2, 1) * ph() - r(1, 1)));
    assert!(flip == pw(r(26, 25), N));                                   // upside-down weights do not average 1
    assert!([(sim_z, se_z, 1.0), (sim_sz, se_sz, q_mean.f()), (sim_bz, se_bz, q_big.f()), (sim_s, se_s, p_mean.f())].iter().all(|&(m, e, x)| (m - x).abs() < 4.0 * e));
    assert!(bridge.windows(2).all(|b| (b[1].2 - b[1].3).abs() < (b[0].2 - b[0].3).abs() / 3.0)); // error falls about 4x per step
    assert!(far.iter().all(|x| x.2 <= 0.01 * x.1 + 1e-15) && far[far.len() - 1].1 > 0.5);
    println!("ALL CHECKS PASS");
}
