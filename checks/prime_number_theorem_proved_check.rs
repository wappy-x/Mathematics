// Prime number theorem with an error term: psi(x) - x and pi(x) - Li(x) by exact counts,
// the contour of the proof checked on zeta itself, and the choice of the cut-off height T.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, f: f64) -> C { C { re: f * self.re, im: f * self.im } }
    fn div(self, o: C) -> C { let w = o.re * o.re + o.im * o.im; self.mul(C { re: o.re / w, im: -o.im / w }) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn ksum(v: impl Iterator<Item = f64>) -> f64 { // Kahan summation, the same in both languages
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in v { let y = x - c; let t = s + y; c = (t - s) - y; s = t; }
    s
}
fn npow(p: u64, x: u64) -> f64 { let (mut k, mut q) = (1.0, p); while q * p <= x { q *= p; k += 1.0; } k }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000; let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn li(x: f64) -> f64 { simpson(&|u: f64| u.exp() / u, 2f64.ln(), x.ln()) }
fn li_series(x: f64) -> f64 {
    let (l, l2) = (x.ln(), 2f64.ln());
    let (mut s, mut a, mut b) = (l.ln() - l2.ln(), 1.0, 1.0);
    for n in 1..120 { a *= l / n as f64; b *= l2 / n as f64; s += (a - b) / n as f64; }
    s
}
const NB: usize = 60;
fn cpow(b: f64, s: C) -> C { let lb = b.ln(); let m = (-s.re * lb).exp(); C { re: m * (-s.im * lb).cos(), im: m * (-s.im * lb).sin() } }
fn zeta(s: C, d: &[f64]) -> C {
    let mut acc = C { re: 0.0, im: 0.0 };
    for k in 0..NB { let sg = if k % 2 == 0 { 1.0 } else { -1.0 }; acc = acc.add(cpow((k + 1) as f64, s).sc(sg * (d[k] - d[NB]))); }
    let w = C { re: 1.0, im: 0.0 }.sub(cpow(2.0, s).sc(2.0)).sc(d[NB]); let w2 = w.re * w.re + w.im * w.im;
    acc.sc(-1.0).mul(C { re: w.re / w2, im: -w.im / w2 })
}
fn hz(t: f64, d: &[f64]) -> f64 { // Hardy's Z: real on the critical line
    let th = t / 2.0 * (t / (2.0 * PI)).ln() - t / 2.0 - PI / 8.0 + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t.powf(3.0));
    let z = zeta(C { re: 0.5, im: t }, d); z.re * th.cos() - z.im * th.sin()
}
fn sci(v: f64) -> String {
    let mut e = v.log10().floor(); let mut m = v / 10f64.powf(e);
    if (m * 1000.0).round() / 1000.0 >= 10.0 { m /= 10.0; e += 1.0; }
    format!("{:.3}e{}", m, e as i64)
}
fn join(v: &[f64], p: usize, sep: &str) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(sep) }
fn main() {
    let (n, m) = (10_000_000usize, 1_000_000usize);
    let mut sv = vec![true; n + 1]; sv[0] = false; sv[1] = false;
    let mut p = 2; while p * p <= n { if sv[p] { let mut q = p * p; while q <= n { sv[q] = false; q += p; } } p += 1; }
    let primes: Vec<u64> = (0..=n).filter(|&i| sv[i]).map(|i| i as u64).collect();
    println!("sieve to 10^7: {} primes", primes.len());
    let xs: Vec<u64> = (2..8).map(|k| 10u64.pow(k)).collect();
    let mut rows = vec![];
    println!("       x    pi(x)    x/log x        Li(x)          psi(x)    psi - x   theta - x");
    for &x in &xs {
        let ps: Vec<u64> = primes.iter().cloned().filter(|&p| p <= x).collect();
        let th = ksum(ps.iter().map(|&p| (p as f64).ln()));
        let psi = ksum(ps.iter().map(|&p| (p as f64).ln() * npow(p, x)));
        let xf = x as f64; let l = li(xf);
        rows.push((ps.len() as f64, th, psi, l));
        println!("{:8} {:8} {:10.3} {:12.3} {:15.3} {:10.3} {:11.3}", x, ps.len(), xf / xf.ln(), l, psi, psi - xf, th - xf);
        assert!((l - li_series(xf)).abs() < 1e-6 * l);
        if x >= 100_000 { assert!((psi / xf - 1.0).abs() < 1e-3); }
    }
    let ch: Vec<Vec<f64>> = (0..3).map(|j| xs.iter().enumerate().map(|(i, &x)| { let (a, _, c, d) = rows[i]; let xf = x as f64; [c / xf, a * xf.ln() / xf, a / d][j] }).collect()).collect();
    println!("chart psi/x: {}", join(&ch[0], 4, ", "));
    println!("chart pi/(x/log x): {}", join(&ch[1], 4, ", "));
    println!("chart pi/Li: {}", join(&ch[2], 4, ", "));
    let (pi6, th6, psi6, li6) = rows[4]; let mf = m as f64;
    let l6 = mf.ln(); let y6 = mf / l6;
    let ps6: Vec<u64> = primes.iter().cloned().filter(|&p| p <= m as u64).collect();
    let (mut thc, mut i1) = (0.0, 0.0);
    for i in 0..ps6.len() {
        thc += (ps6[i] as f64).ln(); let q = if i + 1 < ps6.len() { ps6[i + 1] as f64 } else { mf };
        i1 += thc * (1.0 / (ps6[i] as f64).ln() - 1.0 / q.ln());
    }
    let jj = simpson(&|u: f64| u.exp() / u.powf(2.0), 2f64.ln(), l6);
    let pi_abel = th6 / l6 + i1;
    println!("worked, log x = {:.4}, sqrt(log x) = {:.4}, x/log^2 x = {:.3}", l6, l6.sqrt(), y6 / l6);
    println!("worked, pi = x/log x + (Li - x/log x) + (pi - Li) = {:.3} + {:.3} + {:.3}", y6, li6 - y6, pi6 - li6);
    println!("worked, theta - x = (psi - x) - (psi - theta) = {:.3} - {:.3} = {:.3}", psi6 - mf, psi6 - th6, th6 - mf);
    let rhs = (th6 - mf) / l6 + (i1 - jj) + 2.0 / 2f64.ln();
    println!("worked, pi - Li = {:.3} + {:.3} + {:.3} = {:.3}", (th6 - mf) / l6, i1 - jj, 2.0 / 2f64.ln(), rhs);
    println!("worked, pi by partial summation from theta = {:.3}", pi_abel);
    assert!((pi_abel - pi6).abs() < 1e-6 && (rhs - (pi6 - li6)).abs() < 1e-6);
    let mut lam = vec![0.0f64; m + 1]; // Chebyshev's identity: sum of psi(x/n) = log of x factorial
    for &p in &ps6 { let mut q = p as usize; while q <= m { lam[q] = (p as f64).ln(); q *= p as usize; } }
    let mut cum = vec![0.0f64; m + 1];
    for k in 1..=m { cum[k] = cum[k - 1] + lam[k]; }
    let mut lhs = 0.0; for k in 1..=m { lhs += cum[m / k]; }
    let mut logfact = 0.0; for k in 2..=m { logfact += (k as f64).ln(); }
    println!("Chebyshev identity at 10^6: sum psi(x/n) = {:.3}, log(x!) = {:.3}", lhs, logfact);
    assert!((lhs - logfact).abs() < 1e-3 && (cum[m] - psi6).abs() < 1e-6);
    let (mut d, mut term, mut acc) = (vec![], 1.0 / NB as f64, 0.0); // Borwein's algorithm for zeta(s), Re s > 0
    for i in 0..=NB {
        if i > 0 { term *= (4 * (NB + i - 1) * (NB - i + 1)) as f64 / ((2 * i) * (2 * i - 1)) as f64; }
        acc += term; d.push(NB as f64 * acc);
    }
    let c = 1.0 + 1.0 / l6; let tt = l6.sqrt().exp(); let s1 = 1.0 - 1.0 / (2.0 * 5.558691 * tt.ln());
    println!("contour at 10^6: c = {:.6}, T = exp(sqrt(log x)) = {:.4}, sigma1 = {:.6}; 1/(2R) = {:.6}, 1/sqrt(2R) = {:.6}", c, tt, s1, 1.0 / (2.0 * 5.558691), 1.0 / (2.0 * 5.558691f64).sqrt());
    let (mut zeros, mut t) = (vec![], 10.0f64);
    while t + 0.1 <= 45.0 { // up to the top of the figure
        if hz(t, &d) * hz(t + 0.1, &d) < 0.0 {
            let (mut a, mut b) = (t, t + 0.1);
            for _ in 0..45 { let mm = (a + b) / 2.0; if hz(a, &d) * hz(mm, &d) < 0.0 { b = mm } else { a = mm } }
            zeros.push((a + b) / 2.0);
        }
        t += 0.1;
    }
    println!("zeros on Re s = 1/2 up to height 45, heights: {}", join(&zeros, 6, " "));
    assert!(zeros.len() == 8 && zeros[6] < tt && tt < zeros[7] && (zeros[0] - 14.134725).abs() < 1e-5);
    let mut path: Vec<C> = (0..=8000).map(|i| C { re: c, im: -tt + 2.0 * tt * i as f64 / 8000.0 }).collect();
    path.extend((1..=40).map(|i| C { re: c - (c - s1) * i as f64 / 40.0, im: tt }));
    path.extend((1..=8000).map(|i| C { re: s1, im: tt - 2.0 * tt * i as f64 / 8000.0 }));
    path.extend((1..=40).map(|i| C { re: s1 + (c - s1) * i as f64 / 40.0, im: -tt }));
    let vals: Vec<C> = path.iter().map(|&s| zeta(s, &d)).collect();
    let turn = vals.windows(2).map(|w| { let q = w[1].mul(C { re: w[0].re, im: -w[0].im }); q.im.atan2(q.re) }).sum::<f64>() / (2.0 * PI);
    println!("winding of zeta round the rectangle: {:.6} turns (zeros inside minus poles inside)", turn);
    assert!((turn + 1.0).abs() < 1e-6);
    let (h, mut best) = (1e-4, (0.0f64, 0.0f64));
    for i in 0..781 {
        let s = C { re: s1, im: 2.0 + (tt - 2.0) * i as f64 / 780.0 };
        let dz = zeta(C { re: s.re + h, im: s.im }, &d).sub(zeta(C { re: s.re - h, im: s.im }, &d)).sc(1.0 / (2.0 * h));
        let rr = dz.div(zeta(s, &d)).abs();
        if rr > best.0 { best = (rr, s.im); }
    }
    println!("max |zeta'/zeta| on the left side, 2 <= t <= T: {:.4} at t = {:.2}; (log T)^2 = {:.4}", best.0, best.1, tt.ln().powf(2.0));
    assert!(best.0 < tt.ln().powf(2.0));
    let r0 = zeta(C { re: s1 + h, im: 0.0 }, &d).sub(zeta(C { re: s1 - h, im: 0.0 }, &d)).sc(1.0 / (2.0 * h)).div(zeta(C { re: s1, im: 0.0 }, &d)).abs();
    println!("|zeta'/zeta| on the left side at t = 0, next to the pole: {:.2}; 2R log T = {:.2}", r0, 2.0 * 5.558691 * tt.ln());
    let mut out = vec![];
    for k in [6.0, 20.0, 100.0f64] { // relative error bound of the proof, every constant set to 1
        let l = k * 10f64.ln();
        out = [100f64.ln(), l.sqrt(), l / 2.0].iter().map(|&lt| l * l / lt.exp() + lt.powf(3.0) * (-l / lt).exp()).collect();
        println!("shape, x = 10^{}: T = 100 {}, T = exp(sqrt(log x)) {}, T = sqrt(x) {}", k, sci(out[0]), sci(out[1]), sci(out[2]));
    }
    assert!(out[1] < 1.0 && 1.0 < out[0].min(out[2]));
    let rho = C { re: 1.0, im: zeros[0] };
    let amp = 2.0 * mf / rho.abs(); let wave = -2.0 * cpow(mf, C { re: -1.0, im: -zeros[0] }).div(rho).re;
    println!("broken: zeros at 1 +- {:.6}i, wave amplitude at 10^6 {:.3}, wave now {:.3}", zeros[0], amp, wave);
    let g1: Vec<f64> = (3..6).map(|i| rows[i].0 - xs[i] as f64 / (xs[i] as f64).ln()).collect();
    let g2: Vec<f64> = (3..6).map(|i| rows[i].0 - rows[i].3).collect();
    println!("broken: pi - x/log x at 10^5, 10^6, 10^7: {}", join(&g1, 3, " "));
    println!("broken: pi - Li at 10^5, 10^6, 10^7: {}", join(&g2, 3, " "));
    println!("try: share of primes near 2^1024 1/{:.2}, among odd numbers 1/{:.2}", 1024.0 * 2f64.ln(), 512.0 * 2f64.ln());
    let fx = |sg: f64| 60.0 + 300.0 * sg; let fy = |t: f64| 170.0 - 3.5 * t;
    let bd: Vec<f64> = [2.0, 3.0, 5.0, 8.0, 12.0, 20.0, 30.0, 45.0f64].iter().map(|&t| fx(1.0 - 1.0 / (5.558691 * t.ln()))).collect();
    println!("figure, X = 60 + 300 Re s, Y = 170 - 3.5 Im s: c {:.1}, sigma1 {:.1}, top {:.1}, bottom {:.1}", fx(c), fx(s1), fy(tt), fy(-tt));
    let zy: Vec<f64> = zeros.iter().map(|&z| fy(z)).collect();
    println!("figure, zeros y {}; boundary x at t = 2 3 5 8 12 20 30 45: {}", join(&zy, 1, " "), join(&bd, 1, " "));
    println!("ALL CHECKS PASS");
}
