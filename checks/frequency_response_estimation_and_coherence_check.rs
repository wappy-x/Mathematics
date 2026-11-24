// Measured Bode plot of the radiator room: Welch cross-spectrum over input spectrum, and coherence.
// Standard library only, no crates. The same roads as the Python check: (1) the plant's closed-form G;
// (2) a noise-free sine test simulated in time; (3) Welch's estimate from one noisy logged day.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; self.mul(o.conj()).sc(1.0 / d) }
    fn pow(self, d: i32) -> C { let mut r = C { re: 1.0, im: 0.0 }; for _ in 0..d { r = r.mul(self); } r }
    fn deg(self) -> f64 { self.im.atan2(self.re).to_degrees() }
}
fn ejm(t: f64) -> C { C { re: t.cos(), im: -t.sin() } } // e^(-j t)
struct Rng { s: u64 } // SplitMix64, then Box-Muller for Gaussian noise
impl Rng {
    fn u64(&mut self) -> u64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
    fn uni(&mut self) -> f64 { ((self.u64() >> 11) as f64 + 0.5) / 2f64.powi(53) }
    fn gauss(&mut self) -> f64 { let a = self.uni(); (-2.0 * a.ln()).sqrt() * (2.0 * PI * self.uni()).cos() }
}
const A: f64 = 0.9; const B: f64 = 0.5; const SIG: f64 = 0.1; // y_k = 0.9 y_(k-1) + 0.5 u_(k-1) + e_k
const N: usize = 1440; const HOLD: usize = 5; const L: usize = 180; const ND: usize = 8;
fn day(seed: u64, hold: usize, sig: f64) -> (Vec<f64>, Vec<f64>) {
    let mut r = Rng { s: seed }; let mut u = vec![]; let mut y = vec![0.0];
    for _ in 0..N / hold { let v = if r.u64() >> 63 == 1 { 1.0 } else { -1.0 }; for _ in 0..hold { u.push(v); } }
    for k in 1..N { let g = r.gauss(); let p = y[k - 1]; y.push(A * p + B * u[k - 1] + sig * g); }
    let mu = u.iter().sum::<f64>() / N as f64; let my = y.iter().sum::<f64>() / N as f64;
    (u.iter().map(|v| v - mu).collect(), y.iter().map(|v| v - my).collect())
}
struct Dft { w: Vec<f64>, cs: Vec<f64>, sn: Vec<f64> }
impl Dft {
    fn new() -> Dft {
        let t = |n: usize| 2.0 * PI * n as f64 / L as f64;
        Dft { w: (0..L).map(|n| 0.5 - 0.5 * t(n).cos()).collect(), // Hann taper
              cs: (0..L).map(|n| t(n).cos()).collect(), sn: (0..L).map(|n| t(n).sin()).collect() }
    }
    fn at(&self, x: &[f64], k: usize) -> C {
        let (mut re, mut im) = (0.0, 0.0);
        for n in 0..L { re += self.w[n] * x[n] * self.cs[k * n % L]; im -= self.w[n] * x[n] * self.sn[k * n % L]; }
        C { re, im }
    }
    fn welch(&self, u: &[f64], y: &[f64], k: usize, nseg: usize) -> (C, f64, f64) {
        let (mut suu, mut syy, mut syu) = (0.0, 0.0, C { re: 0.0, im: 0.0 });
        for m in 0..nseg {
            let uu = self.at(&u[m * L..(m + 1) * L], k); let yy = self.at(&y[m * L..(m + 1) * L], k);
            suu += uu.re * uu.re + uu.im * uu.im; syy += yy.re * yy.re + yy.im * yy.im;
            syu = syu.add(yy.mul(uu.conj()));
        }
        (syu.sc(1.0 / suu), (syu.re * syu.re + syu.im * syu.im) / (suu * syy), (syy / suu).sqrt())
    }
}
fn spectra(dft: &Dft, u: &[f64], y: &[f64]) -> Vec<(C, f64, f64)> { // bins 1..89; bin 0, the mean, left empty
    (0..90).map(|k| if k == 0 { (C { re: 0.0, im: 0.0 }, 0.0, 0.0) } else { dft.welch(u, y, k, ND) }).collect()
}
fn zk(k: usize) -> C { ejm(2.0 * PI * k as f64 / L as f64) }
fn g(k: usize, a: f64, b: f64, d: i32) -> C { let z = zk(k); z.pow(d).sc(b).div(C { re: 1.0, im: 0.0 }.sub(z.sc(a))) }
fn gt(k: usize) -> C { g(k, A, B, 1) }
fn true_coh(k: usize) -> f64 {
    let w = 2.0 * PI * k as f64 / L as f64;
    let suu = ((HOLD as f64 * w / 2.0).sin() / (w / 2.0).sin()).powi(2) / HOLD as f64;
    1.0 / (1.0 + SIG * SIG / (B * B * suu))
}
fn fit(e: &[(C, f64, f64)], ks: &[usize], d: i32) -> (f64, f64, f64) { // G = b z^-d / (1 - a z^-1), linear least squares
    let (mut s11, mut s12, mut s22, mut r1, mut r2) = (0.0, 0.0, 0.0, 0.0, 0.0);
    for &k in ks {
        let ge = e[k].0; let z = zk(k); let c1 = ge.mul(z); let c2 = z.pow(d);
        s11 += c1.abs().powi(2); s12 += c1.mul(c2.conj()).re; s22 += c2.abs().powi(2);
        r1 += ge.mul(c1.conj()).re; r2 += ge.mul(c2.conj()).re;
    }
    let det = s11 * s22 - s12 * s12; let a = (r1 * s22 - r2 * s12) / det; let b = (s11 * r2 - s12 * r1) / det;
    (a, b, ks.iter().map(|&k| e[k].0.sub(g(k, a, b, d)).abs().powi(2)).sum())
}
fn best(e: &[(C, f64, f64)], ks: &[usize]) -> (f64, f64, f64, i32) { // the delay d = 0, 1 or 2 with the smallest misfit
    let mut bst = (0.0, 0.0, f64::INFINITY, 0); for d in 0..3 { let (a, b, r) = fit(e, ks, d); if r < bst.2 { bst = (a, b, r, d); } } bst
}
fn db(z: C) -> f64 { 20.0 * z.abs().log10() }
fn f1(x: f64) -> String { let t = format!("{:.1}", x); if t == "-0.0" { "0.0".into() } else { t } }
fn f(k: usize) -> f64 { k as f64 / L as f64 }
fn main() {
    // ---- road 2: a sine test on the noise-free room, 0.05 cycles/min (period 20 min) ----
    let (mut y, mut acc) = (0.0, C { re: 0.0, im: 0.0 });
    for n in 1..3000 {
        y = A * y + B * (2.0 * PI * 9.0 * (n - 1) as f64 / L as f64).sin();
        if n >= 1000 { acc = acc.add(ejm(2.0 * PI * 9.0 * n as f64 / L as f64).sc(y)); }
    }
    let gs = C { re: 0.0, im: 2.0 }.mul(acc).sc(1.0 / 2000.0);
    println!("sine test at {:.3} c/min: gain {:.4} C per kW, phase {:.2} deg", f(9), gs.abs(), gs.deg());
    println!("formula   at {:.3} c/min: gain {:.4} C per kW, phase {:.2} deg", f(9), gt(9).abs(), gt(9).deg());
    assert!(gs.sub(gt(9)).abs() < 1e-6);
    let w = 2.0 * PI * f(9); let (re, im) = (1.0 - A * w.cos(), A * w.sin()); // the hand table
    println!("hand: {} c/min = {:.3} mHz, w {:.4} rad/min, cos {:.4}, sin {:.4}, 1-0.9e^-jw = {:.4} + {:.4}j, size {:.4}, angle {:.2} deg, delay angle {:.2} deg",
             f(9), 1000.0 * f(9) / 60.0, w, w.cos(), w.sin(), re, im, re.hypot(im), im.atan2(re).to_degrees(), w.to_degrees());
    // ---- road 3: Welch on the logged day ----
    let dft = Dft::new(); let (u, yd) = day(2026, HOLD, SIG); let est = spectra(&dft, &u, &yd);
    println!("  k  f c/min  period min  true gain  meas gain  true deg  meas deg  coherence  theory  err %");
    for k in [2, 5, 9, 18, 27, 36, 54, 72, 89] { let (ge, c, _) = est[k];
        println!("{:3}  {:.4}  {:9.1}  {:9.3}  {:9.3}  {:8.1}  {:8.1}  {:9.3}  {:6.3}  {:5.1}", k, f(k), 1.0 / f(k),
                 gt(k).abs(), ge.abs(), gt(k).deg(), ge.deg(), c, true_coh(k), 100.0 * ge.sub(gt(k)).abs() / gt(k).abs());
    }
    let trust: Vec<usize> = (1..90).filter(|&k| est[k].1 >= 0.9).collect(); let rest: Vec<usize> = (1..90).filter(|&k| est[k].1 < 0.9).collect();
    let med = |ks: &Vec<usize>| { let mut v: Vec<f64> = ks.iter().map(|&k| est[k].0.sub(gt(k)).abs() / gt(k).abs()).collect();
        v.sort_by(|a, b| a.partial_cmp(b).unwrap()); (v[(v.len() - 1) / 2] + v[v.len() / 2]) / 2.0 }; // the middle value, or the mean of two
    let top = (1..90).find(|k| !trust.contains(k)).unwrap() - 1;
    println!("trusted bins (coherence >= 0.9): {} of 89, unbroken from bin 1 to bin {} ({:.3} c/min); median error {:.1}%",
             trust.len(), top, f(top), 100.0 * med(&trust));
    println!("untrusted bins: {}, median error {:.1}%", rest.len(), 100.0 * med(&rest));
    assert!(med(&trust) < 0.08 && med(&rest) > 2.0 * med(&trust));
    assert!((1..90).all(|k| est[k].1 >= 0.0 && est[k].1 <= 1.0 + 1e-12)); // Cauchy-Schwarz
    let bar = |c: f64| 100.0 * ((1.0 - c) / (c * 2.0 * ND as f64)).sqrt();
    println!("error bar at 0.05 c/min: sqrt(1-c)/(sqrt(c) sqrt(2*{})) = {:.1}%; at 0.4 c/min, from its measured coherence {:.3}: {:.1}%",
             ND, bar(est[9].1), est[72].1, bar(est[72].1));
    // ---- Monte Carlo: 300 more days; error bar and the coherence of unrelated records ----
    let bins = [9usize, 30]; let mut mc: Vec<Vec<C>> = vec![vec![], vec![]]; let mut null = vec![];
    for s in 0..300u64 {
        let (uu, yy) = day(5000 + s, HOLD, SIG);
        for (i, &k) in bins.iter().enumerate() { mc[i].push(dft.welch(&uu, &yy, k, ND).0); }
        let (_, yo) = day(9000 + s, HOLD, SIG); null.push(dft.welch(&uu, &yo, 9, ND).1);
    }
    for (i, &k) in bins.iter().enumerate() {
        let rel: Vec<f64> = mc[i].iter().map(|z| z.abs() / gt(k).abs()).collect();
        let m = rel.iter().sum::<f64>() / rel.len() as f64; let sd = (rel.iter().map(|r| (r - m).powi(2)).sum::<f64>() / (rel.len() - 1) as f64).sqrt();
        let c = true_coh(k); let pred = ((1.0 - c) / (c * 2.0 * ND as f64)).sqrt();
        println!("bin {:2} ({:.3} c/min): true coherence {:.3}, error bar formula {:.1}%, scatter over 300 days {:.1}%",
                 k, f(k), c, 100.0 * pred, 100.0 * sd);
        assert!(0.8 * pred < sd && sd < 1.4 * pred);
    }
    let mn = null.iter().sum::<f64>() / null.len() as f64;
    println!("coherence of unrelated records: mean {:.3}, theory 1/{} = {:.3}", mn, ND, 1.0 / ND as f64);
    assert!((mn - 1.0 / ND as f64).abs() < 0.03);
    // ---- fit a first-order-plus-delay model G = b z^-d / (1 - a z^-1) by linear least squares ----
    let all: Vec<usize> = (1..90).collect();
    for (label, ks) in [("trusted", &trust), ("all 89 ", &all)] { for d in 0..3 { let (a, b, res) = fit(&est, ks, d);
        println!("fit {} d={}: a {:.4} b {:.4} gain {:.2} C/kW lag {:.2} min residual {:.4}", label, d, a, b, b / (1.0 - a), -1.0 / a.ln(), res);
    } }
    let (a, b, _, d) = best(&est, &trust);
    println!("best delay d={} min; true a {} b {} gain {:.2} C/kW lag {:.2} min", d, A, B, B / (1.0 - A), -1.0 / A.ln());
    assert!(d == 1 && (a - A).abs() < 0.02 && (b - B).abs() < 0.05 && fit(&est, &trust, 1).2 < fit(&est, &trust, 0).2);
    // ---- what breaks ----
    let one: Vec<f64> = (1..90).map(|k| dft.welch(&u, &yd, k, 1).1).collect();
    let (lo, hi) = one.iter().fold((f64::INFINITY, f64::NEG_INFINITY), |(l, h), &v| (l.min(v), h.max(v)));
    println!("one segment only: coherence min {:.6} max {:.6}", lo, hi);
    assert!((lo - 1.0).abs() < 1e-9);
    println!("at {:.3} c/min: true gain {:.3}, Syu/Suu {:.3}, sqrt(Syy/Suu) {:.3}", f(33), gt(33).abs(), est[33].0.abs(), est[33].2);
    // ---- chart points ----
    let ks: Vec<usize> = (3..90).step_by(3).collect();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, f c/min {}", join(ks.iter().map(|&k| format!("{:.3}", f(k))).collect()));
    println!("chart, true dB {}", join(ks.iter().map(|&k| f1(db(gt(k)))).collect()));
    println!("chart, meas dB {}", join(ks.iter().map(|&k| f1(db(est[k].0))).collect()));
    println!("chart, coherence {}", join(ks.iter().map(|&k| format!("{:.2}", est[k].1)).collect()));
    // ---- the Try box, and the noise switched off: the same day re-made with one setting changed ----
    for (name, seed, hold, sig, dt, bins) in [("valve held 1 min", 2026, 1, SIG, &dft, &[36usize][..]),
            ("noise 0.3 C", 2026, HOLD, 0.3, &dft, &[][..]), ("no taper", 2026, HOLD, SIG, &Dft { w: vec![1.0; L], ..Dft::new() }, &[9][..]),
            ("seed 7", 7, HOLD, SIG, &dft, &[][..]), ("noise off", 2026, HOLD, 0.0, &dft, &[2, 36, 72][..])] {
        let (uu, yy) = day(seed, hold, sig); let e = spectra(dt, &uu, &yy); let ks: Vec<usize> = (1..90).filter(|&k| e[k].1 >= 0.9).collect();
        let (a, b, _, _) = best(&e, &ks);
        let at: String = bins.iter().map(|&k| format!(" bin {} error {:.1}%, coherence {:.3};", k, 100.0 * e[k].0.sub(gt(k)).abs() / gt(k).abs(), e[k].1)).collect();
        println!("try {}:{} {} trusted bins; fit {:.2} C/kW, {:.2} min", name, at, ks.len(), b / (1.0 - a), -1.0 / a.ln());
    }
    println!("ALL CHECKS PASS");
}
