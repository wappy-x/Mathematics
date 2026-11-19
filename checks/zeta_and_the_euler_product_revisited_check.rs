// Zeta of a complex variable: the check behind the card.  std only, no crates.
// Zeta is computed two ways: Euler-Maclaurin with Bernoulli terms (cut-off 60),
// and a long sum to 100,000 with the integral tail.  Primes come from a sieve.
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn r(x: f64) -> C { C { re: x, im: 0.0 } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, k: f64) -> C { C { re: k * self.re, im: k * self.im } }
    fn div(self, b: C) -> C { // the same scaled division as CPython
        if b.re.abs() >= b.im.abs() {
            let ra = b.im / b.re; let de = b.re + b.im * ra;
            C { re: (self.re + self.im * ra) / de, im: (self.im - self.re * ra) / de }
        } else {
            let ra = b.re / b.im; let de = b.re * ra + b.im;
            C { re: (self.re * ra + self.im) / de, im: (self.im * ra - self.re) / de }
        }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn cpow(n: u64, s: C) -> C { // n^(-s)
    let l = (n as f64).ln(); let r = (-s.re * l).exp();
    C { re: r * (s.im * l).cos(), im: -r * (s.im * l).sin() }
}
const BERN: [f64; 6] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0, -691.0 / 2730.0];
fn zeta_em(s: C, n_cut: u64) -> (C, C) { // zeta(s) and zeta'(s)
    let (mut z, mut d) = (C::r(0.0), C::r(0.0));
    for n in 1..n_cut { let w = cpow(n, s); z = z.add(w); d = d.sub(w.sc((n as f64).ln())); }
    let nf = n_cut as f64; let ln_n = nf.ln(); let wn = cpow(n_cut, s); let s1 = s.sub(C::r(1.0));
    z = z.add(wn.sc(nf).div(s1)).add(wn.sc(0.5));
    d = d.add(wn.sc(nf).sc(-ln_n).div(s1)).sub(wn.sc(nf).div(s1.mul(s1))).sub(wn.sc(ln_n).sc(0.5));
    let mut fact = 1.0;
    for k in 1..7usize {
        fact *= ((2 * k - 1) * (2 * k)) as f64;
        let (mut p, mut dp) = (C::r(1.0), C::r(0.0));
        for j in 0..(2 * k - 1) { let sj = s.add(C::r(j as f64)); dp = dp.mul(sj).add(p); p = p.mul(sj); }
        let c = BERN[k - 1] / fact * nf.powf(1.0 - 2.0 * k as f64);
        z = z.add(p.sc(c).mul(wn)); d = d.add(wn.sc(c).mul(dp.sub(p.sc(ln_n))));
    }
    (z, d)
}
fn zeta_long(s: C) -> C { // sum to M, plus M^(1-s)/(s-1) - M^(-s)/2
    let m = 100000u64; let mut z = C::r(0.0);
    for n in 1..=m { z = z.add(cpow(n, s)); }
    let wm = cpow(m, s);
    z.add(wm.sc(m as f64).div(s.sub(C::r(1.0)))).sub(wm.sc(0.5))
}
fn row(xs: &[f64], k: usize) -> String { xs.iter().map(|x| format!("{:.*}", k, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let x: usize = 1_000_000;
    let mut sieve = vec![true; x + 1]; sieve[0] = false; sieve[1] = false;
    for p in 2..=1000 { if sieve[p] { let mut q = p * p; while q <= x { sieve[q] = false; q += p; } } }
    let primes: Vec<u64> = (0..=x).filter(|&p| sieve[p]).map(|p| p as u64).collect();
    println!("primes below 10^6 by sieve: {}", primes.len());
    assert!(primes.len() == 78498);
    let euler = |sg: f64, pmax: u64| { let mut pr = 1.0;
        for &p in &primes { if p > pmax { break; } pr *= 1.0 / (1.0 - (p as f64).powf(-sg)); } pr };
    let mut part = 0.0; for n in 1..=1000u64 { part += 1.0 / ((n * n) as f64); }
    let (lo, hi) = (part + 1.0 / 1001.0, part + 1.0 / 1000.0);
    let z2 = zeta_em(C::r(2.0), 60).0.re; let pi26 = std::f64::consts::PI.powi(2) / 6.0;
    println!("zeta(2): 1000 terms {:.8}; tail bracket [{:.8}, {:.8}]", part, lo, hi);
    let (e1000, ex) = (euler(2.0, 1000), euler(2.0, x as u64));
    println!("zeta(2): product, 168 primes {:.8}; 78498 primes {:.8}; pi^2/6 {:.8}; Euler-Maclaurin {:.8}", e1000, ex, pi26, z2);
    assert!(lo < pi26 && pi26 < hi && (z2 - pi26).abs() < 1e-12);
    assert!(e1000 < ex && ex < z2 && z2 - ex < 1.0 / x as f64);
    let z11 = zeta_em(C::r(1.1), 60).0.re; let l11 = zeta_long(C::r(1.1)).re;
    println!("zeta(1.1): Euler-Maclaurin {:.6}; long sum {:.6}; bracket 10 < zeta(1.1) < 11", z11, l11);
    assert!((z11 - l11).abs() < 1e-7 && 10.0 < z11 && z11 < 11.0);
    let sgs: Vec<f64> = (1..=10).map(|k| 1.0 + k as f64 / 10.0).collect();
    let zs: Vec<f64> = sgs.iter().map(|&sg| zeta_em(C::r(sg), 60).0.re).collect();
    println!("chart, sigma = 1.1 .. 2.0, lower 1/(sigma-1): {}", row(&sgs.iter().map(|sg| 1.0 / (sg - 1.0)).collect::<Vec<_>>(), 2));
    println!("chart, zeta(sigma): {}", row(&zs, 2));
    println!("chart, upper sigma/(sigma-1): {}", row(&sgs.iter().map(|sg| sg / (sg - 1.0)).collect::<Vec<_>>(), 2));
    for (sg, z) in sgs.iter().zip(&zs) { assert!(1.0 / (sg - 1.0) < *z && *z < sg / (sg - 1.0)); }
    let mut gn = 0.0; for n in 1..=x { gn += 1.0 / n as f64; }
    let xf = x as f64; let gamma = gn - xf.ln() - 1.0 / (2.0 * xf) + 1.0 / (12.0 * xf * xf);
    let near = [1.1, 1.01, 1.001];
    let zn: Vec<f64> = near.iter().map(|&sg| zeta_em(C::r(sg), 60).0.re).collect();
    println!("pole: (sigma-1) zeta(sigma) at 1.1, 1.01, 1.001: {}", row(&near.iter().zip(&zn).map(|(sg, z)| (sg - 1.0) * z).collect::<Vec<_>>(), 6));
    println!("zeta(sigma) - 1/(sigma-1) at 1.1, 1.01, 1.001: {}", row(&near.iter().zip(&zn).map(|(sg, z)| z - 1.0 / (sg - 1.0)).collect::<Vec<_>>(), 6));
    println!("Euler's constant gamma from 1 + 1/2 + ... + 1/N - log N, N = 10^6: {:.6}", gamma);
    assert!((zn[2] - 1.0 / 0.001 - gamma).abs() < 1e-4);
    let vm = |sg: f64, powers: bool| { let mut tot = 0.0;
        for &p in &primes { let mut q = p;
            while q <= x as u64 { tot += (p as f64).ln() * (q as f64).powf(-sg); if !powers { break; } q *= p; } }
        tot };
    let (z, d) = zeta_em(C::r(2.0), 60);
    let (ld2, vm2, vp2) = (C::r(0.0).sub(d).div(z).re, vm(2.0, true), vm(2.0, false));
    println!("-zeta'/zeta(2): prime powers to 10^6 {:.5}; slope of zeta {:.5}; primes only {:.5}", vm2, ld2, vp2);
    assert!(0.0 < ld2 - vm2 && ld2 - vm2 < 2e-6);
    let lds: Vec<f64> = near.iter().map(|&sg| { let (z, d) = zeta_em(C::r(sg), 60); C::r(0.0).sub(d).div(z).re }).collect();
    println!("-zeta'/zeta(sigma) at 1.1, 1.01, 1.001: {}", row(&lds, 6));
    println!("1/(sigma-1) - gamma at 1.1, 1.01, 1.001: {}", row(&near.iter().map(|sg| 1.0 / (sg - 1.0) - gamma).collect::<Vec<_>>(), 6));
    for (l, sg) in lds.iter().zip(&near) { assert!((l - (1.0 / (sg - 1.0) - gamma)).abs() < 3.0 * (sg - 1.0)); }
    let ts = [1u64, 10, 100, 1000];
    let zc: Vec<(C, C)> = ts.iter().map(|&t| zeta_em(C { re: 1.1, im: t as f64 }, t.max(60))).collect();
    let floor = zeta_em(C::r(2.2), 60).0.re / z11;
    println!("floor zeta(2.2)/zeta(1.1) {:.6}, ceiling zeta(1.1) {:.6}", floor, z11);
    println!("|zeta(1.1 + it)| at t = 1, 10, 100, 1000: {}", row(&zc.iter().map(|(z, _)| z.abs()).collect::<Vec<_>>(), 6));
    println!("|zeta'/zeta(1.1 + it)| at t = 1, 10, 100, 1000: {}", row(&zc.iter().map(|(z, d)| d.div(*z).abs()).collect::<Vec<_>>(), 6));
    for (z, d) in &zc { assert!(floor < z.abs() && z.abs() < z11 && d.div(*z).abs() < lds[0]); }
    let tl = [10u64, 100, 1000];
    let em1: Vec<f64> = tl.iter().map(|&t| zeta_em(C { re: 1.0, im: t as f64 }, t.max(60)).0.abs()).collect();
    let lg1: Vec<f64> = tl.iter().map(|&t| zeta_long(C { re: 1.0, im: t as f64 }).abs()).collect();
    println!("|zeta(1 + it)| at t = 10, 100, 1000, Euler-Maclaurin: {}", row(&em1, 6));
    println!("|zeta(1 + it)| at t = 10, 100, 1000, long sum: {}", row(&lg1, 6));
    println!("bound log t + 5.5 at t = 10, 100, 1000: {}", row(&tl.iter().map(|&t| (t as f64).ln() + 5.5).collect::<Vec<_>>(), 2));
    for i in 0..3 { assert!((em1[i] - lg1[i]).abs() < 1e-6 && em1[i] < (tl[i] as f64).ln() + 5.5); }
    let (eu11, vm11) = (euler(1.1, x as u64), vm(1.1, true));
    println!("mistake, Euler product at 1.1 over primes to 10^6: {:.6}, not {:.6}", eu11, z11);
    println!("mistake, prime powers to 10^6 at 1.1: {:.6}, not {:.6}", vm11, lds[0]);
    let mut h = 0.0; for n in 1..=1000u64 { h += (n as f64).powf(-0.5); }
    let zh = zeta_em(C::r(0.5), 60).0.re;
    println!("mistake, the series at s = 1/2, 1000 terms: {:.6}; zeta(1/2) {:.6}, inside [-2, -1]", h, zh);
    assert!(eu11 < z11 - 1.0 && vm11 < lds[0] - 1.0 && -2.0 < zh && zh < -1.0);
    let e11 = euler(1.1, 1000);
    println!("try: zeta(1.01) {:.6}; Euler product at 1.1, primes to 1000: {:.6}", zn[1], e11);
    assert!(100.0 < zn[1] && zn[1] < 101.0 && e11 < eu11);
    println!("gaps at 1.1: zeta - floor {:.6}, ceiling - zeta {:.6}, -zeta'/zeta - prediction {:.6}; cut product short by {:.1} percent; 6/pi^2 {:.6}",
        z11 - 10.0, 11.0 - z11, lds[0] - 1.0 / 0.1 + gamma, 100.0 * (1.0 - eu11 / z11), 6.0 / std::f64::consts::PI.powi(2));
    println!("ALL CHECKS PASS");
}
