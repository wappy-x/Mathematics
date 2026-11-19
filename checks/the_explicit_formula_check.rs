// The explicit formula -- the same check as the Python, in Rust.  No crates.
// Zeta by Euler-Maclaurin; 1,000 zeros from sign changes of Z(t), checked, then
// fed into von Mangoldt's formula at x = 7.5 and nearby.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn dv(self, k: f64) -> C { C { re: self.re / k, im: self.im / k } }
    fn div(self, b: C) -> C {                      // Smith's division, as CPython does it
        if b.re.abs() >= b.im.abs() { let r = b.im / b.re; let d = b.re + b.im * r;
            C { re: (self.re + self.im * r) / d, im: (self.im - self.re * r) / d }
        } else { let r = b.re / b.im; let d = b.re * r + b.im;
            C { re: (self.re * r + self.im) / d, im: (self.im * r - self.re) / d } }
    }
    fn exp(self) -> C { let l = self.re.exp(); C { re: l * self.im.cos(), im: l * self.im.sin() } }
}
const B: [f64; 10] = [1.0 / 6.0, -1.0 / 30.0, 1.0 / 42.0, -1.0 / 30.0, 5.0 / 66.0, -691.0 / 2730.0,
                      7.0 / 6.0, -3617.0 / 510.0, 43867.0 / 798.0, -174611.0 / 330.0];

fn zeta(s: C) -> C {                               // Euler-Maclaurin, valid for any s != 1
    let n_cut = (s.im.abs() / 2.0) as usize + 10;
    let ns = C { re: -s.re, im: -s.im };
    let (mut tot, nf) = (C { re: 0.0, im: 0.0 }, n_cut as f64);
    for n in 1..n_cut { tot = tot.add(ns.sc((n as f64).ln()).exp()) }
    let big = ns.sc(nf.ln()).exp(); tot = tot.add(big.sc(nf).div(C { re: s.re - 1.0, im: s.im })).add(big.dv(2.0));
    let (mut term, mut fact) = (s.mul(big).dv(nf), 1.0);
    for k in 1..=10 {
        fact *= ((2 * k - 1) * (2 * k)) as f64;
        tot = tot.add(term.sc(B[k - 1] / fact));
        let kk = (2 * k) as f64;
        term = term.mul(C { re: s.re + kk - 1.0, im: s.im }.mul(C { re: s.re + kk, im: s.im }).dv(nf * nf));
    }
    tot
}

fn theta(t: f64) -> f64 {                          // Riemann-Siegel angle, Stirling series
    t / 2.0 * (t / (2.0 * PI)).ln() - t / 2.0 - PI / 8.0
        + 1.0 / (48.0 * t) + 7.0 / (5760.0 * t.powf(3.0)) + 31.0 / (80640.0 * t.powf(5.0))
}

fn z_real(t: f64) -> f64 {                         // Z(t): zeta on the line, turned real
    C { re: 0.0, im: theta(t) }.exp().mul(zeta(C { re: 0.5, im: t })).re
}

fn find_zeros(count: usize, step: f64) -> Vec<f64> { // scan for sign changes, then Illinois
    let (mut out, mut t, mut zp) = (Vec::new(), 10.0, z_real(10.0));
    while out.len() < count {
        let (a, zc) = (t, z_real(t + step)); t += step;
        if zp * zc < 0.0 {
            let (mut lo, mut hi, mut flo, mut fhi) = (a, t, zp, zc);
            for _ in 0..80 {
                let m = hi - fhi * (hi - lo) / (fhi - flo); let fm = z_real(m);
                if fm * fhi < 0.0 { lo = hi; flo = fhi } else { flo /= 2.0 }
                hi = m; fhi = fm;
                if (hi - lo).abs() < 1e-12 { break }
            }
            out.push(hi);
        } zp = zc;
    }
    out
}

fn sieve(n: usize) -> Vec<usize> {                 // Eratosthenes: every prime up to n
    let (mut ok, mut i) = (vec![true; n + 1], 2); ok[0] = false; ok[1] = false;
    while i * i <= n { if ok[i] { let mut j = i * i; while j <= n { ok[j] = false; j += i } } i += 1 }
    (0..=n).filter(|&i| ok[i]).collect()
}

fn psi(x: f64, primes: &[usize]) -> f64 {          // the staircase: log p at every p^k <= x
    let mut tot = 0.0; for &p in primes.iter().filter(|&&p| p as f64 <= x) {
        let mut pk = p as f64; while pk <= x { tot += (p as f64).ln(); pk *= p as f64 }
    }
    tot
}

fn wave(x: f64, t: f64) -> f64 {                   // one mirror pair: 2 Re(x^rho / rho)
    let lx = x.ln(); 2.0 * x.sqrt() * (0.5 * (t * lx).cos() + t * (t * lx).sin()) / (0.25 + t * t)
}

fn formula(x: f64, zs: &[f64], k: usize, pairs: f64, log2pi: bool) -> f64 {
    let smooth = x - if log2pi { (2.0 * PI).ln() } else { 0.0 } - 0.5 * (1.0 - x.powf(-2.0)).ln();
    smooth - pairs / 2.0 * zs[..k].iter().map(|&t| wave(x, t)).sum::<f64>()
}
fn f(x: f64, zs: &[f64], k: usize) -> f64 { formula(x, zs, k, 2.0, true) }

fn logderiv_max(h: f64) -> f64 {                   // max |zeta'/zeta| on -1 <= sigma <= 2
    let mut best: f64 = 0.0;
    for j in 0..61 { let s = C { re: -1.0 + 0.05 * j as f64, im: h };
        let d = zeta(C { re: s.re + 1e-5, im: s.im }).sub(zeta(C { re: s.re - 1e-5, im: s.im })).dv(2e-5);
        let q = d.div(zeta(s)); best = best.max(q.re.hypot(q.im));
    }
    best
}

fn main() {
    let (zs, primes) = (find_zeros(1000, 0.05), sieve(1_000_000));
    let lmfdb = [(1, 14.1347251417), (10, 49.7738324777), (100, 236.5242296658), (1000, 1419.4224809460)];
    let mut gap = 0; for i in 0..999 { if zs[i + 1] - zs[i] < zs[gap + 1] - zs[gap] { gap = i } }
    let (smooth_count, below) = (theta(1420.0) / PI + 1.0, zs.iter().filter(|&&g| g < 1420.0).count());
    let window = (10..1420).map(|a| zs.iter().filter(|&&g| a as f64 <= g && g < a as f64 + 1.0).count()).max().unwrap();
    println!("zeros found: {}, heights {:.6} to {:.6}", zs.len(), zs[0], zs[999]);
    println!("smallest gap {:.6}, between zeros {} and {}", zs[gap + 1] - zs[gap], gap + 1, gap + 2);
    let tab: Vec<String> = lmfdb.iter().map(|&(n, _)| format!("'{:.6}'", zs[n - 1])).collect();
    println!("LMFDB table, zeros 1, 10, 100, 1000: [{}]", tab.join(", "));
    println!("zeros below 1420: {}; smooth count RS angle/pi + 1 = {:.3}", below, smooth_count);
    println!("most zeros in one window [a, a+1) up to 1420: {}; log 1420 = {:.3}", window, 1420f64.ln());
    let mut edges = Vec::new();
    for a in [100.0, 500.0, 1000.0] {
        let mut cuts = vec![0.0];
        cuts.extend(zs.iter().filter(|&&g| a < g && g < a + 1.0).map(|&g| g - a)); cuts.push(1.0);
        let mut i = 0;
        for j in 0..cuts.len() - 1 { if cuts[j + 1] - cuts[j] > cuts[i + 1] - cuts[i] { i = j } }
        let t = a + (cuts[i] + cuts[i + 1]) / 2.0;
        let near = zs.iter().map(|&g| (t - g).abs()).fold(f64::INFINITY, f64::min);
        let (m, l2) = (logderiv_max(t), t.ln().powf(2.0)); edges.push((m, l2));
        println!("T = {:.3}: nearest zero {:.3} away, max |zeta'/zeta| {:.2}, log^2 T {:.2}", t, near, m, l2);
    }
    let bad = logderiv_max(zs[0] + 0.001); println!("T = first zero + 0.001: max |zeta'/zeta| {:.1}", bad);
    let (x, exact, ks) = (7.5, psi(7.5, &primes), [0, 10, 100, 1000]);
    let errs: Vec<f64> = ks.iter().map(|&k| f(x, &zs, k) - exact).collect();
    println!("psi(7.5) = {:.6} = log 420 = {:.6}", exact, 420f64.ln());
    for (k, e) in ks.iter().zip(&errs) { println!("{:>4} zeros at 7.5: {:.6}, miss {:+.6}", k, exact + e, e) }
    println!("at the jump x = 7, midpoint {:.6}; 10, 100, 1000 zeros: {:.6} {:.6} {:.6}",
             psi(7.0, &primes) - 7f64.ln() / 2.0, f(7.0, &zs, 10), f(7.0, &zs, 100), f(7.0, &zs, 1000));
    let mut si = 0.0;
    for j in 0..=1000 { let (u, w) = (j as f64 * PI / 1000.0, if j == 0 || j == 1000 { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 });
        si += w * if u != 0.0 { u.sin() / u } else { 1.0 } }
    let (gibbs, mut rings) = ((si * PI / 3000.0 / PI - 0.5) * 7f64.ln(), Vec::new());
    for k in [10, 100, 1000] {
        let (mut top, mut at) = (f64::NEG_INFINITY, 0.0);
        for i in 1..=1000 { let v = 7.0 + i as f64 * 0.0005; let y = f(v, &zs, k); if y > top { top = y; at = v } }
        let spot = 7.0 * PI / zs[k - 1]; rings.push((top - exact, at - 7.0, spot));
        println!("{:>4} zeros, T = {:.3}: peak {:.4} at x = {:.4}, overshoot {:.4}, Gibbs spot 7 + {:.4}",
                 k, zs[k - 1], top, at, top - exact, spot);
    }
    println!("Gibbs overshoot (Si(pi)/pi - 1/2) x log 7 = {:.4}", gibbs);
    let big = psi(1e6, &primes); let m: Vec<String> = ks.iter().map(|&k| format!("{:.2}", f(1e6 + 0.5, &zs, k) - big)).collect();
    println!("primes below a million {}; psi(10^6) = {:.3}; formula minus psi at 10^6 + 0.5: {}", primes.len(), big, m.join(" "));
    let euler = (1..=10000).map(|n| 1.0 / n as f64).sum::<f64>() - 10000f64.ln() - 1.0 / 20000.0 + 1.0 / (12.0 * 1e8);
    let target = 2.0 + euler - (4.0 * PI).ln();
    let sq: Vec<f64> = [10, 100, 1000].iter().map(|&k| zs[..k].iter().map(|&t| 2.0 / (0.25 + t * t)).sum()).collect();
    let tail = ((zs[999] / (2.0 * PI)).ln() + 1.0) / (PI * zs[999]);
    println!("sum 2/|rho|^2 over 10, 100, 1000 pairs: {:.6} {:.6} {:.6} + tail {:.6} = {:.6}; 2 + gamma - log 4pi = {:.6}",
             sq[0], sq[1], sq[2], tail, sq[2] + tail, target);
    let ab: Vec<f64> = [10, 100, 1000].iter().map(|&k| zs[..k].iter().map(|&t| 2.0 / (0.25 + t * t).sqrt()).sum()).collect();
    println!("sum 2/|rho| over 10, 100, 1000 pairs: {:.3} {:.3} {:.3} ; log^2(T/2pi)/2pi at T = {:.0}: {:.3}",
             ab[0], ab[1], ab[2], zs[999], (zs[999] / (2.0 * PI)).ln().powf(2.0) / (2.0 * PI));
    println!("break: no -log 2pi, 1000 zeros at 7.5: miss {:+.4}", formula(x, &zs, 1000, 2.0, false) - exact);
    println!("break: one zero of each pair, 1000 zeros at 7.5: miss {:+.4}", formula(x, &zs, 1000, 1.0, true) - exact);
    println!("break: primes only, theta(7.5) = log 210 = {:.4}: miss {:+.4}", 210f64.ln(), f(x, &zs, 1000) - 210f64.ln());
    println!("constants: log 2pi {:.6}, trivial term {:.6}, Si(pi) {:.6}, gamma {:.6}, Gibbs fraction {:.4}, log 2 {:.4}, x log^2(xT)/T at 10^6 {:.0}",
             (2.0 * PI).ln(), -0.5 * (1.0 - x.powf(-2.0)).ln(), si * PI / 3000.0, euler, si * PI / 3000.0 / PI - 0.5, 2f64.ln(), 1e6 * (1e6 * zs[999]).ln().powf(2.0) / zs[999]);
    let grid: Vec<f64> = (0..41).map(|i| 6.5 + 0.05 * i as f64).collect();
    for (name, k) in [("staircase", 0), ("10 zeros", 10), ("100 zeros", 100)] {
        let v: Vec<String> = grid.iter().map(|&g| format!("{:.2}", if k == 0 { psi(g, &primes) } else { f(g, &zs, k) })).collect();
        println!("chart {}: {}", name, v.join(", "));
    }
    assert!(lmfdb.iter().all(|&(n, v)| (zs[n - 1] - v).abs() < 1e-8));        // a named table
    assert!(below == 1000 && (1000.0 - smooth_count).abs() < 1.0);
    assert!((exact - 420f64.ln()).abs() < 1e-12 && errs[3].abs() < errs[2].abs() && errs[2].abs() < errs[1].abs() && errs[1].abs() < errs[0].abs());
    assert!(edges.iter().all(|&(m, l2)| m < l2) && bad > 100.0);
    assert!((rings[2].0 - gibbs).abs() < 0.01 && (rings[2].1 / rings[2].2 - 1.0).abs() < 0.1);
    assert!(primes.len() == 78498 && (sq[2] + tail - target).abs() < 1e-4);
    assert!(zs.iter().all(|&t| { let r = C { re: 0.5, im: t }; (wave(x, t) - 2.0 * r.sc(x.ln()).exp().div(r).re).abs() < 1e-12 }));
    println!("ALL CHECKS PASS");
}
