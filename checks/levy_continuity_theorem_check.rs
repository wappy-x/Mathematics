// Levy's continuity theorem -- the check behind the card.  std only, no crates.
// Binomial(n, 2/n) fingerprints against the Poisson(2)'s; three roads to the masses
// (counting, inversion of the fingerprint, simulation); tightness; three traps.
use std::f64::consts::PI;

const LAM: f64 = 2.0; const P_REQ: f64 = 0.002; const N_REQ: i64 = 1000; const SEED: u64 = 20261115; // 1,000 requests a minute, 0.2% fail each

#[derive(Clone, Copy)] struct C { re: f64, im: f64 }
fn cmul(a: C, b: C) -> C { C { re: a.re * b.re - a.im * b.im, im: a.re * b.im + a.im * b.re } }
fn cexp(x: f64, y: f64) -> C { let r = x.exp(); C { re: r * y.cos(), im: r * y.sin() } }
fn cpow(mut z: C, mut n: u64) -> C { // z^n by repeated squaring
    let mut out = C { re: 1.0, im: 0.0 };
    while n > 0 {
        if n & 1 == 1 { out = cmul(out, z); }
        z = cmul(z, z); n >>= 1;
    }
    out
}
fn fp_binom(n: u64, p: f64, t: f64) -> C { cpow(C { re: 1.0 - p + p * t.cos(), im: p * t.sin() }, n) }
fn fp_pois(lam: f64, t: f64) -> C { cexp(lam * (t.cos() - 1.0), lam * t.sin()) }
fn gap(a: C, b: C) -> f64 { (a.re - b.re).hypot(a.im - b.im) }
fn binom_pmf(n: u64, p: f64, kmax: u64) -> Vec<f64> { // counting road: the ratio recurrence
    let mut out = vec![(1.0 - p).powf(n as f64)];
    for k in 0..kmax { let last = out[out.len() - 1]; out.push(last * (n - k) as f64 / (k + 1) as f64 * p / (1.0 - p)); }
    out
}
fn pois_pmf(lam: f64, kmax: u64) -> Vec<f64> {
    let mut v = Vec::new(); let mut fact = 1.0;
    for k in 0..=kmax { if k > 0 { fact *= k as f64; } v.push((-lam).exp() * lam.powf(k as f64) / fact); }
    v
}
fn invert(fp: &[C], m: usize, k: f64) -> f64 { // (1/2pi) int_{-pi}^{pi} fp(t) e^{-itk} dt, m points
    let mut s = 0.0;
    for j in 0..m {
        let t = -PI + 2.0 * PI * j as f64 / m as f64; let f = fp[j];
        s += f.re * (t * k).cos() + f.im * (t * k).sin();
    }
    s / m as f64
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64; let mut s = f(a) + f(b);
    for i in 1..m { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn tail_bound<F: Fn(f64) -> f64>(re_fp: F, u: f64) -> f64 { simpson(|t| 1.0 - re_fp(t), -u, u, 2000) / u }
fn erf(x: f64) -> f64 { // 2/sqrt(pi) e^{-x^2} sum 2^k x^{2k+1}/(1*3*...*(2k+1))
    let (mut term, mut s, mut k) = (x, x, 0.0);
    while term > 1e-17 * s { k += 1.0; term *= 2.0 * x * x / (2.0 * k + 1.0); s += term; }
    2.0 / PI.sqrt() * (-x * x).exp() * s
}
struct Rng(u64);
impl Rng {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uniform(&mut self) -> f64 { ((self.next() >> 11) + 1) as f64 / 9007199254740992.0 } // in (0, 1]
}
fn c6(z: C) -> String { format!("{:+.6} {:+.6}i", z.re, z.im) }
fn sum(v: &[f64]) -> f64 { v.iter().sum() }

fn main() {
    println!("Levy continuity check: Binomial(n, 2/n) fingerprints against the Poisson(2)'s");
    println!("fingerprint at t = 1:");
    let lim1 = fp_pois(LAM, 1.0);
    for n in [10u64, 100, 1000, 10000] {
        let z = fp_binom(n, LAM / n as f64, 1.0);
        println!("  n={:<6} {}   gap {:.6}   n x gap {:.4}", n, c6(z), gap(z, lim1), n as f64 * gap(z, lim1));
    }
    println!("  Poisson  {}", c6(lim1));
    let w = C { re: 1f64.cos() - 1.0, im: 1f64.sin() };
    let pred = lim1.re.hypot(lim1.im) * LAM.powf(2.0) * (2.0 - 2.0 * 1f64.cos()) / 2.0;
    println!("by hand: e^i {}  lam(e^i - 1) {}  |fp| {:.6}", c6(C { re: 1f64.cos(), im: 1f64.sin() }), c6(C { re: LAM * w.re, im: LAM * w.im }), (LAM * w.re).exp());
    println!("by hand: base n=1000 {}  predicted n x gap {:.4}  at n=1000 {:.6}", c6(C { re: 1.0 + P_REQ * w.re, im: P_REQ * w.im }), pred, pred / 1000.0);
    assert!((10000.0 * gap(fp_binom(10000, LAM / 10000.0, 1.0), lim1) - pred).abs() < 0.001);
    let ts: Vec<f64> = (0..=2000).map(|j| -PI + 2.0 * PI * j as f64 / 2000.0).collect();
    let mut worst = Vec::new();
    for n in [10u64, 100, 1000] {
        let w = ts.iter().map(|&t| gap(fp_binom(n, LAM / n as f64, t), fp_pois(LAM, t))).fold(0.0f64, f64::max);
        println!("worst gap over all t, n={:<5} {:.6}   n x gap {:.4}", n, w, n as f64 * w);
        worst.push(w);
    }
    assert!(worst[2] < worst[1] && worst[1] < worst[0] && (1000.0 * worst[2] / (100.0 * worst[1]) - 1.0).abs() < 0.02);

    let m = 1024;
    let fpb: Vec<C> = (0..m).map(|j| fp_binom(N_REQ as u64, P_REQ, -PI + 2.0 * PI * j as f64 / m as f64)).collect();
    let fpp: Vec<C> = (0..64).map(|j| fp_pois(LAM, -PI + 2.0 * PI * j as f64 / 64.0)).collect();
    let (cnt, pois) = (binom_pmf(N_REQ as u64, P_REQ, 6), pois_pmf(LAM, 6));
    println!("k  counting n=1000  inverted n=1000  Poisson   inverted Poisson (64 points)");
    for k in 0..7 {
        let (ib, ip) = (invert(&fpb, m, k as f64), invert(&fpp, 64, k as f64));
        println!("{}  {:.6}        {:.6}         {:.6}  {:.6}", k, cnt[k], ib, pois[k], ip);
        assert!((ib - cnt[k]).abs() < 1e-12 && (ip - pois[k]).abs() < 1e-12);
    }
    println!("aliasing bound for 64 points: P(N >= 64) = {:.1e}", sum(&pois_pmf(LAM, 100)[64..]));

    let t10 = 1.0 - sum(&binom_pmf(10, LAM / 10.0, 5));
    let t100 = 1.0 - sum(&binom_pmf(100, LAM / 100.0, 5));
    let t1000 = 1.0 - sum(&binom_pmf(1000, LAM / 1000.0, 5));
    let tp = 1.0 - sum(&pois[..6]);
    println!("P(6 or more failures): n=10 {:.6}  n=100 {:.6}  n=1000 {:.6}  Poisson {:.6}", t10, t100, t1000, tp);
    println!("paging gap, Poisson minus n=1000: {:.6}   one minute in {:.1} (n=1000), {:.1} (Poisson)", tp - t1000, 1.0 / t1000, 1.0 / tp);
    let (min, mut hits, mut total) = (200000i64, 0i64, 0i64);
    let log_q = (1.0 - P_REQ).ln();
    let mut rng = Rng(SEED);
    for _ in 0..min { // simulation road: jump from failure to failure
        let (mut pos, mut c) = (-1i64, 0i64);
        loop {
            pos += 1 + (rng.uniform().ln() / log_q) as i64;
            if pos >= N_REQ { break; }
            c += 1;
        }
        if c >= 6 { hits += 1; }
        total += c;
    }
    let se = (t1000 * (1.0 - t1000) / min as f64).sqrt();
    let (fh, mean) = (hits as f64 / min as f64, total as f64 / min as f64);
    println!("simulation, {} minutes, seed {}: mean {:.4}  P(6 or more) {:.6}  (s.e. {:.6})", min, SEED, mean, fh, se);
    assert!((fh - t1000).abs() < 4.0 * se && (mean - 2.0).abs() < 0.02);

    let u = 0.3;
    println!("tightness, u = {}: tail bound (1/u) int (1 - Re fp) dt, against P(count > 2/u = {:.2})", u, 2.0 / u);
    for n in [10u64, 100, 1000] {
        let b = tail_bound(|t| fp_binom(n, LAM / n as f64, t).re, u);
        let tr = 1.0 - sum(&binom_pmf(n, LAM / n as f64, (2.0 / u) as u64));
        println!("  n={:<5} bound {:.6}   true {:.6}   ratio {:.1}", n, b, tr, b / tr);
        assert!(tr <= b && b < 0.2);
    }
    let bp = tail_bound(|t| fp_pois(LAM, t).re, u);
    let tpp = 1.0 - sum(&pois_pmf(LAM, (2.0 / u) as u64));
    println!("  Poisson  bound {:.6}   true {:.6}   ratio {:.1}", bp, tpp, bp / tpp);
    assert!((bp - (2.0 * u * u - 94.0 / 60.0 * u.powi(4))).abs() < 0.0015); // moments: E[N^2] = 6, E[N^4] = 94

    println!("trap 1, chance fixed at 0.002 while n grows:");
    for n in [1000u64, 10000, 100000] {
        let z = fp_binom(n, P_REQ, 1.0);
        println!("  n={:<6} |fp(1)| {:.6}   P(5 or fewer) {:.6}", n, z.re.hypot(z.im), sum(&binom_pmf(n, P_REQ, 5)));
    }
    assert!(fp_binom(100000, P_REQ, 1.0).re.hypot(fp_binom(100000, P_REQ, 1.0).im) < 1e-30 && (fp_binom(100000, P_REQ, 2.0 * PI).re - 1.0).abs() < 1e-9);
    println!("trap 2, normal laws of variance n:");
    for n in [1.0f64, 100.0, 10000.0] {
        let pin = erf(5.0 / (2.0 * n).sqrt());
        let b = tail_bound(|t| (-n * t * t / 2.0).exp(), u);
        println!("  n={:<6} fp(0.1) {:.6}   P(|X| <= 5) {:.6}   tail bound {:.6}", n as i64, (-n * 0.005).exp(), pin, b);
        assert!(pin > 0.0 && pin <= 1.0);
    }
    assert!((erf(5.0 / 200f64.sqrt()) - 0.3829249225480261).abs() < 1e-12); // value printed by the Python library cross-check
    println!("trap 3, Poisson(2) with chance 0.9, else the value n:");
    let mut fps = Vec::new();
    for n in [20u64, 200, 2000] {
        let z = C { re: 0.9 * lim1.re + 0.1 * (n as f64).cos(), im: 0.9 * lim1.im + 0.1 * (n as f64).sin() };
        let zk = pois_pmf(LAM, 60).iter().enumerate().fold(C { re: 0.1 * (n as f64).cos(), im: 0.1 * (n as f64).sin() }, |a, (k, q)| C { re: a.re + 0.9 * q * (k as f64).cos(), im: a.im + 0.9 * q * (k as f64).sin() });
        let f = |x: u64| 0.9 * sum(&pois_pmf(LAM, x.min(60))) + 0.1 * (if n <= x { 1.0 } else { 0.0 });
        println!("  n={:<5} fp(1) {}   F_n(10) {:.6}   F_n(1000) {:.6}", n, c6(z), f(10), f(1000));
        assert!(gap(z, zk) < 1e-12 && (f(1000) - if n <= 1000 { 1.0 } else { 0.9 }).abs() < 1e-12 && (f(10) - 0.9 + 0.9 * sum(&pois_pmf(LAM, 60)[11..])).abs() < 1e-12); fps.push(z);
    }
    assert!(gap(fps[0], fps[1]) > 0.05 && gap(fps[0], fps[2]) > 0.05); // the fingerprints wander: no limit

    println!("chart, real part of the fingerprint at t = 0, 0.25, ..., 3:");
    let rows: [(&str, Box<dyn Fn(f64) -> C>); 3] = [("n=5 ", Box::new(|t| fp_binom(5, 0.4, t))),
        ("n=20", Box::new(|t| fp_binom(20, 0.1, t))), ("Pois", Box::new(|t| fp_pois(LAM, t)))];
    for (name, f) in rows.iter() {
        let pts: Vec<String> = (0..13).map(|j| format!("{:.2}", f(0.25 * j as f64).re)).collect();
        println!("  {} {}", name, pts.join(", "));
    }
    println!("ALL CHECKS PASS");
}
