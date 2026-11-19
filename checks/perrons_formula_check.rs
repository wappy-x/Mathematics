// Perron's formula: psi(x), the weighted prime count, recovered from -zeta'/zeta by a line integral cut at height T.
// Roads: (1) psi(x) by a sieve; (2) the cut line integral, zeta by Euler-Maclaurin, must sit within the proved bound;
// (3) the switch integral of y^s/s two ways: straight up the line, and by residues plus the two horizontal sides.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Neg, Sub};

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 }
fn cx(re: f64, im: f64) -> Cx { Cx { re, im } }
impl Add for Cx { type Output = Cx; fn add(self, o: Cx) -> Cx { cx(self.re + o.re, self.im + o.im) } }
impl Sub for Cx { type Output = Cx; fn sub(self, o: Cx) -> Cx { cx(self.re - o.re, self.im - o.im) } }
impl Neg for Cx { type Output = Cx; fn neg(self) -> Cx { cx(-self.re, -self.im) } }
impl Mul for Cx { type Output = Cx; fn mul(self, o: Cx) -> Cx { cx(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for Cx {
    type Output = Cx;
    fn div(self, o: Cx) -> Cx { let d = o.re * o.re + o.im * o.im; cx((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
}
fn sc(a: f64, z: Cx) -> Cx { cx(a * z.re, a * z.im) }
fn cexp(z: Cx) -> Cx { let m = z.re.exp(); cx(m * z.im.cos(), m * z.im.sin()) }

const BERN: [f64; 8] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0, -691.0 / 2730.0, 7.0 / 6.0, -3617.0 / 510.0];

fn zeta_pair(s: Cx, n_terms: usize) -> (Cx, Cx) {
    let (mut z, mut d) = (cx(0.0, 0.0), cx(0.0, 0.0));
    for n in 1..n_terms {
        let ln = (n as f64).ln();
        let t = cexp(sc(-ln, s));
        z = z + t;
        d = d - sc(ln, t);
    }
    let (nf, ln) = (n_terms as f64, (n_terms as f64).ln());
    let a = cexp(sc(-ln, s));
    let s1 = s - cx(1.0, 0.0);
    z = z + sc(nf, a) / s1 + sc(0.5, a);
    d = d + sc(-ln * nf, a) / s1 - sc(nf, a) / (s1 * s1) - sc(0.5 * ln, a);
    let (mut p, mut dp, mut pw, mut fac) = (s, cx(1.0, 0.0), sc(1.0 / nf, a), 2.0);
    for k in 1..9 {
        z = z + sc(BERN[k - 1] / fac, p * pw);
        d = d + sc(BERN[k - 1] / fac, (dp - sc(ln, p)) * pw);
        for j in [2 * k - 1, 2 * k] {
            let sj = s + cx(j as f64, 0.0);
            (dp, p) = (dp * sj + p, p * sj);
        }
        pw = sc(1.0 / (nf * nf), pw);
        fac *= ((2 * k + 1) * (2 * k + 2)) as f64;
    }
    (z, d)
}

fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut tot = g(a) + g(b);
    for i in 1..m { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    tot * h / 3.0
}

fn switch_line(y: f64, t_max: f64, c: f64, m: usize) -> f64 {
    let l = y.ln();
    y.powf(c) / PI * simpson(|t| (c * (l * t).cos() + t * (l * t).sin()) / (c * c + t * t), 0.0, t_max, m)
}

fn switch_residue(y: f64, t_max: f64, c: f64, m: usize) -> f64 {
    let l = y.ln();
    let side = |u: f64| (l * u).exp() * (u * (t_max * l).sin() - t_max * (t_max * l).cos()) / (u * u + t_max * t_max);
    if y > 1.0 { 1.0 + simpson(side, c - 50.0 / l, c, m) / PI } else { -simpson(side, c, c - 50.0 / l, m) / PI }
}

fn nsum<I: Iterator<Item = f64>>(it: I) -> f64 {   // compensated sum, as Python's sum() does
    let (mut s, mut comp) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { comp += (s - t) + x } else { comp += (x - t) + s } s = t; }
    s + comp
}

const NMAX: usize = 1_000_000;

fn perron_cut(x: f64, c: f64, ts: &[f64], h: f64) -> Vec<f64> {
    let l = x.ln();
    let f = |t: f64| {
        let s = cx(c, t);
        let (z, d) = zeta_pair(s, 30 + (t / 3.0) as usize);
        ((-d / z) * cexp(sc(l, s)) / s).re
    };
    let (mut out, mut total, mut t0) = (Vec::new(), 0.0, 0.0);
    for &t in ts {
        let m = 2 * ((t - t0) / (2.0 * h)).round() as usize;
        total += simpson(&f, t0, t, m);
        out.push(total / PI);
        t0 = t;
    }
    out
}

fn bound(pp: &[(usize, f64)], x: f64, t: f64, c: f64, capped: bool) -> f64 {
    let (mut main, mut part) = (0.0, 0.0);
    for &(n, lam) in pp {
        let y = x / n as f64;
        let w = 1.0 / (PI * t * y.ln().abs());
        main += lam * y.powf(c) * (if capped { w.min(1.0) } else { w });
        part += lam * (n as f64).powf(-c);
    }
    let (z, d) = zeta_pair(cx(c, 0.0), 60);
    main + x.powf(c) / (PI * t * (NMAX as f64 / x).ln()) * ((-d / z).re - part)
}

fn main() {
    let mut sieve = vec![true; NMAX + 1]; sieve[0] = false; sieve[1] = false;
    let mut i = 2;
    while i * i <= NMAX { if sieve[i] { let mut j = i * i; while j <= NMAX { sieve[j] = false; j += i; } } i += 1; }
    let mut pp: Vec<(usize, f64)> = Vec::new();   // (n, Lambda(n)) for n = p^k
    for p in 2..=NMAX { if sieve[p] { let mut q = p; while q <= NMAX { pp.push((q, (p as f64).ln())); q *= p; } } }
    pp.sort_by_key(|e| e.0);
    let lam = |n: usize| pp.iter().find(|e| e.0 == n).unwrap().1;
    let psi = |x: f64| nsum(pp.iter().filter(|e| e.0 as f64 <= x).map(|e| e.1));
    let x: f64 = 100.5;
    let c = 1.0 + 1.0 / x.ln();
    let ts = [10.0, 25.0, 50.0, 100.0, 200.0, 400.0, 1000.0];
    let (z2, d2) = zeta_pair(cx(2.0, 0.0), 60);
    println!("engine zeta(2) {:.12}  pi^2/6 {:.12}", z2.re, PI * PI / 6.0);
    let lam2 = nsum(pp.iter().map(|e| e.1 / (e.0 as f64).powi(2)));
    println!("engine -zeta'/zeta(2) {:.6}  sum Lambda(n)/n^2 to 10^6 {:.6}", (-d2 / z2).re, lam2);
    assert!((z2.re - PI * PI / 6.0).abs() < 1e-12, "zeta engine off at 2");
    let gap = (-d2 / z2).re - lam2;
    assert!(0.0 < gap && gap < 2e-6, "log derivative off: the tail past 10^6 is about 1e-6");
    let p = psi(x);
    let small = nsum(pp.iter().filter(|e| e.0 as f64 <= x && !sieve[e.0]).map(|e| e.1));
    println!("x {}  c = 1 + 1/log x {:.6}  x^c {:.4}  e*x {:.4}", x, c, x.powf(c), 1f64.exp() * x);
    println!("psi(x) by sieve {:.6}  theta(100) {:.6}  prime powers {:.6}  primes {}, to 10^6 {}", p, p - small, small,
             sieve[..101].iter().filter(|&&b| b).count(), sieve.iter().filter(|&&b| b).count());
    println!("switch    y     T    up the line   by residues  |I - step|      bound");
    for y in [2.0f64, 1.0, 0.5] {
        for t in [10.0f64, 100.0] {
            let a = switch_line(y, t, c, 20000);
            let b = if y != 1.0 { switch_residue(y, t, c, 20000) } else { (t / c).atan() / PI };
            let step = if y > 1.0 { 1.0 } else if y == 1.0 { 0.5 } else { 0.0 };
            let bd = if y == 1.0 { c / (PI * t) } else { y.powf(c) * (1.0 / (PI * t * y.ln().abs())).min(1.0) };
            println!("switch {:5.1} {:5}  {:12.6}  {:12.6}  {:10.6} {:10.6}", y, t as i64, a, b, (a - step).abs(), bd);
            assert!((a - b).abs() < 1e-7, "line and residue roads disagree");
            assert!((a - step).abs() <= bd, "switch error above its bound");
        }
    }
    let jv = perron_cut(x, c, &ts, 0.02);
    println!("   T     J(T) cut integral   psi - J      bound B(T)   from n = 101");
    for (k, &t) in ts.iter().enumerate() {
        let b = bound(&pp, x, t, c, true);
        let n101 = -lam(101) * switch_line(x / 101.0, t, c, 20000);
        println!("{:5}  {:16.6}  {:10.6}  {:12.6}  {:10.6}", t as i64, jv[k], p - jv[k], b, n101);
        assert!((p - jv[k]).abs() <= b, "Perron error above the proved bound");
    }
    for n in [97usize, 101] {
        let y = x / n as f64;
        let w = PI * 100.0 * y.ln().abs();
        println!("bound piece n={}: Lambda {:.4} y {:.6} log y {:.6} pi T|log y| {:.4} min {:.4} y^c {:.5} piece {:.4}",
                 n, lam(n), y, y.ln(), w, (1.0 / w).min(1.0), y.powf(c), lam(n) * y.powf(c) * (1.0 / w).min(1.0));
    }
    println!("switch at y = 1, T = 100: arctan(T/c)/pi {:.6}  c/(pi T) {:.6}", (100.0 / c).atan() / PI, c / (PI * 100.0));
    let j101 = perron_cut(101.0, 1.0 + 1.0 / 101f64.ln(), &[1000.0], 0.02)[0];
    println!("wrong: x = 101, T = 1000 gives {:.4}; psi(101) {:.4}; midpoint {:.4}", j101, psi(101.0), psi(101.0) - lam(101) / 2.0);
    println!("wrong: no min, T = 10: bound {:.4}  T = 25: {:.4}", bound(&pp, x, 10.0, c, false), bound(&pp, x, 25.0, c, false));
    let j2 = perron_cut(x, 2.0, &[100.0], 0.02)[0];
    println!("wrong: c = 2, T = 100: bound {:.4}  error {:.6}", bound(&pp, x, 100.0, 2.0, true), p - j2);
    assert!((j101 - (psi(101.0) - lam(101) / 2.0)).abs() < (j101 - psi(101.0)).abs(), "a jump gives the midpoint");
    let (x9, c9) = (100.9f64, 1.0 + 1.0 / 100.9f64.ln());   // try: x nearer the prime 101
    println!("try: x = 100.9, T = 100: error {:.6}  bound {:.6}", psi(x9) - perron_cut(x9, c9, &[100.0], 0.02)[0], bound(&pp, x9, 100.0, c9, true));
    println!("chart y      {}", (0..16).map(|i| format!("{:5.1}", 0.5 + 0.1 * i as f64)).collect::<Vec<_>>().join(" "));
    for t in [10usize, 50] {
        let vals: Vec<String> = (0..16).map(|i| format!("{:5.2}", switch_line(0.5 + 0.1 * i as f64, t as f64, c, 4000)).replace("-0.00", " 0.00")).collect();
        println!("chart T={:<4} {}", t, vals.join(" "));
    }
    println!("ALL CHECKS PASS");
}
