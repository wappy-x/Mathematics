// Finite word length -- the check behind the card.  Rust std only, no crates.
// The 5th-order Butterworth hum filter (fs 500 Hz, cutoff 20 Hz) built two ways:
// one direct form (one 5th-degree denominator) and a cascade of sections (two biquads + one 1st-order).
// Part 1: round the feedback coefficients to a step 2^-F and see where the poles go.
// Part 2: round each stored sum to 16 bits (q = 2^-15) and size the noise that adds.
// Same roads as the Python: roots against the sensitivity formula; A(1) two ways; noise gain two ways; a bit-true run.
use std::f64::consts::PI;
const FS: f64 = 500.0; const FC: f64 = 20.0; const N: usize = 5; const MV: f64 = 5.0;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im;
        c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }  fn conj(self) -> C { c(self.re, -self.im) }
}
fn rnd(v: f64, q: f64) -> f64 { (v / q + 0.5).floor() * q }
fn rndv(v: &[f64], f: i32) -> Vec<f64> { v.iter().map(|&x| rnd(x, 2f64.powi(-f))).collect() }
fn sum(v: &[f64]) -> f64 { v.iter().fold(0.0, |s, x| s + x) }
fn polymul(p: &[f64], r: &[f64]) -> Vec<f64> {
    (0..p.len() + r.len() - 1).map(|k| (0..p.len()).filter(|&i| k >= i && k - i < r.len()).fold(0.0, |s, i| s + p[i] * r[k - i])).collect()
}
fn roots(cf: &[f64]) -> Vec<C> { // Durand-Kerner: all roots at once
    let n = cf.len() - 1; let s = c(0.4, 0.9);
    let mut z: Vec<C> = (0..n).map(|k| (0..k).fold(c(1.0, 0.0), |p, _| p.mul(s))).collect();
    for _ in 0..600 {
        let mut nz = Vec::new();
        for i in 0..n {
            let num = cf.iter().fold(c(0.0, 0.0), |p, &v| p.mul(z[i]).add(c(v, 0.0)));
            let den = (0..n).filter(|&j| j != i).fold(c(1.0, 0.0), |p, j| p.mul(z[i].sub(z[j])));
            nz.push(z[i].sub(num.div(den)));
        }
        z = nz;
    }
    z
}
fn sec_poles(a: &[f64]) -> Vec<C> { // quadratic formula, section by section
    if a.len() == 2 { return vec![c(-a[1], 0.0)]; }
    let d = a[1] * a[1] - 4.0 * a[2];
    if d >= 0.0 { vec![c((-a[1] + d.sqrt()) / 2.0, 0.0), c((-a[1] - d.sqrt()) / 2.0, 0.0)] }
    else { vec![c(-a[1] / 2.0, (-d).sqrt() / 2.0), c(-a[1] / 2.0, -(-d).sqrt() / 2.0)] }
}
fn maxr(v: &[C]) -> f64 { v.iter().map(|p| p.abs()).fold(0.0, f64::max) }
fn impulse(b: &[f64], a: &[f64]) -> Vec<f64> {
    let mut y: Vec<f64> = Vec::new();
    for i in 0..3000 { let fb = (1..a.len()).filter(|&k| i >= k).fold(0.0, |s, k| s + a[k] * y[i - k]);
        y.push((if i < b.len() { b[i] } else { 0.0 }) - fb); }
    y
}
fn freq(b: &[f64], a: &[f64], w: f64) -> f64 {
    let ev = |cf: &[f64]| cf.iter().enumerate().fold(c(0.0, 0.0), |s, (k, &v)| s.add(c(v * (w * k as f64).cos(), -v * (w * k as f64).sin())));
    ev(b).div(ev(a)).abs()
}
fn gain_freq(b: &[f64], a: &[f64]) -> f64 { (0..4096).fold(0.0, |s, m| s + freq(b, a, 2.0 * PI * m as f64 / 4096.0).powi(2)) / 4096.0 } // road 3
fn shaping(order: &[(Vec<f64>, Vec<f64>)]) -> Vec<(Vec<f64>, Vec<f64>)> { // noise path from each section's rounding
    (0..order.len()).map(|k| { let (mut num, mut den) = (vec![1.0], order[k].1.clone());
        for (b2, a2) in &order[k + 1..] { num = polymul(&num, b2); den = polymul(&den, a2); } (num, den) }).collect()
}
fn run(b: &[f64], a: &[f64], xs: &[f64], q: f64, errs: &mut Vec<f64>) -> Vec<f64> { // direct form I, wide accumulator
    let mut y: Vec<f64> = Vec::new();
    for n in 0..xs.len() {
        let s1 = (0..b.len()).filter(|&k| n >= k).fold(0.0, |s, k| s + b[k] * xs[n - k]);
        let s2 = (1..a.len()).filter(|&k| n >= k).fold(0.0, |s, k| s + a[k] * y[n - k]);
        let acc = s1 - s2; y.push(if q > 0.0 { rnd(acc, q) } else { acc }); // one rounding, when stored
        if q > 0.0 { errs.push(y[n] - acc); }
    }
    y
}
fn var(e: &[f64]) -> f64 { let m = sum(e) / e.len() as f64; e.iter().fold(0.0, |s, v| s + (v - m) * (v - m)) / e.len() as f64 }
fn sci(x: f64, p: usize) -> String { let s = format!("{:.*e}", p, x); let (m, e) = s.split_once('e').unwrap(); // Python-style exponent
    let e: i32 = e.parse().unwrap(); format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs()) }
fn j(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (q, one) = (2f64.powi(-15), c(1.0, 0.0));
    let wc = (PI * FC / FS).tan();
    let poles: Vec<C> = (0..N).map(|k| { let t = PI * (2 * k + N + 1) as f64 / (2 * N) as f64;
        let s = c(wc * t.cos(), wc * t.sin()); one.add(s).div(one.sub(s)) }).collect(); // bilinear map
    let mut ac = vec![one];
    for p in &poles { let mut na = vec![c(0.0, 0.0); ac.len() + 1];
        for i in 0..na.len() { let u = if i < ac.len() { ac[i] } else { c(0.0, 0.0) };
            na[i] = if i > 0 { u.sub(p.mul(ac[i - 1])) } else { u }; } ac = na; }
    let a: Vec<f64> = ac.iter().map(|z| z.re).collect();
    let mut binom = vec![1.0f64]; for k in 1..=N { binom.push(binom[k - 1] * (N + 1 - k) as f64 / k as f64); }
    let b: Vec<f64> = binom.iter().map(|v| v * sum(&a) / 32.0).collect();
    let pr = *poles.iter().find(|p| p.im.abs() < 1e-9).unwrap();
    let mut pp: Vec<C> = poles.iter().cloned().filter(|p| p.im > 1e-9).collect();
    pp.sort_by(|x, y| x.abs().partial_cmp(&y.abs()).unwrap());
    let mut dens = vec![vec![1.0, -pr.re]];
    for p in &pp { dens.push(vec![1.0, -2.0 * p.re, p.abs().powi(2)]); }
    let secs: Vec<(Vec<f64>, Vec<f64>)> = dens.iter().map(|d| { let w: Vec<f64> = if d.len() == 2 { vec![1.0, 1.0] } else { vec![1.0, 2.0, 1.0] };
        (w.iter().map(|v| v * sum(d) / 2f64.powi(d.len() as i32 - 1)).collect(), d.clone()) }).collect();
    let mv = |new: &[C]| poles.iter().map(|p| new.iter().map(|r| r.sub(*p).abs()).fold(f64::INFINITY, f64::min)).fold(0.0, f64::max);
    let casc = |f: i32| -> Vec<C> { dens.iter().flat_map(|d| sec_poles(&rndv(d, f))).collect() };
    let dirp = |f: i32| -> Vec<C> { roots(&rndv(&a, f)) };
    println!("a = {}", j(&a, 6));
    println!("sections: {}", dens.iter().map(|d| j(&d[1..], 6)).collect::<Vec<_>>().join("; "));
    println!("pole radii {}; angles deg {}", j(&poles.iter().map(|p| p.abs()).collect::<Vec<_>>(), 4),
        j(&poles.iter().map(|p| p.im.atan2(p.re).to_degrees()).collect::<Vec<_>>(), 2));
    let (a1, a1p) = (sum(&a), poles.iter().fold(1.0, |s, p| s * one.sub(*p).abs())); // A(1) two ways
    println!("A(1): sum of a {:.6}, product of (1 - p) {:.6}; sections {}", a1, a1p, j(&dens.iter().map(|d| sum(d)).collect::<Vec<_>>(), 4));
    assert!((a1 - a1p).abs() < 1e-12);
    let p0 = pp[1]; let da = |p: C, ps: &[C]| ps.iter().filter(|r| r.sub(p).abs() > 1e-12).fold(1.0, |s, r| s * p.sub(*r).abs());
    println!("sensitivity of the 0.9259 pole, 1/|A'(p)|: direct {:.1}, biquad {:.3}, 1/(2 rho sin theta) {:.3}",
        1.0 / da(p0, &poles), 1.0 / da(p0, &[p0, p0.conj()]), 1.0 / (2.0 * p0.abs() * p0.im.atan2(p0.re).sin()));
    let pred_move = |f: i32| -> (C, C) { // road 2: first-order prediction of the move
        let d: Vec<f64> = rndv(&a, f).iter().zip(&a).map(|(r, v)| r - v).collect();
        let num = (1..=N).fold(c(0.0, 0.0), |s, k| s.add(c(d[k], 0.0).mul((0..N - k).fold(one, |t, _| t.mul(p0)))));
        let den = poles.iter().filter(|r| r.sub(p0).abs() > 1e-12).fold(one, |t, r| t.mul(p0.sub(*r)));
        let ex = dirp(f).into_iter().fold((f64::INFINITY, one), |m, r| if r.sub(p0).abs() < m.0 { (r.sub(p0).abs(), r.sub(p0)) } else { m });
        (c(0.0, 0.0).sub(num.div(den)), ex.1) }; // (predicted move, exact move), as complex numbers
    for f in [16, 10] { println!("F = {}, move of the 0.9259 pole: predicted {:.6}, exact root {:.6}", f, pred_move(f).0.abs(), pred_move(f).1.abs()); }
    assert!(pred_move(16).0.sub(pred_move(16).1).abs() < 0.05 * pred_move(16).1.abs());
    println!("bits F | direct: largest radius, largest move | cascade: largest radius, largest move");
    let mut chart = Vec::new();
    for f in 8..17 { let (d, cc) = (dirp(f), casc(f)); chart.push((maxr(&d), maxr(&cc)));
        println!("  {:2}   |      {:.4}  {:.4}          |       {:.4}  {:.6}", f, maxr(&d), mv(&d), maxr(&cc), mv(&cc)); }
    let dmin = (2..30).find(|&f| (f..30).all(|g| maxr(&dirp(g)) < 1.0 - 1e-9)).unwrap();
    let cmin = (2..30).find(|&f| (f..30).all(|g| maxr(&casc(g)) < 1.0 - 1e-9)).unwrap();
    println!("fewest fraction bits for stability at every F above: direct {}, cascade {}", dmin, cmin);
    let ar10 = rndv(&a, 10);
    println!("F = 10: step {:.6}, worst shift of A(1) 5 x step/2 = {:.6}; rounded a = {} ; A(1) = {:.6}", 2f64.powi(-10), 5.0 * 2f64.powi(-11), j(&ar10, 6), sum(&ar10));
    assert!(sum(&ar10).abs() < 1e-12 && cmin < dmin);
    for f in [12, 16] { println!("F = {}: gain at 0 Hz, direct {:.4}, cascade {:.4}", f, sum(&b) / sum(&rndv(&a, f)),
        secs.iter().fold(1.0, |s, (bb, aa)| s * (sum(bb) / sum(&rndv(aa, f))))); }
    // ---- Part 2: roundoff noise ----
    let s2 = q * q / 12.0; let gain_sum = |b: &[f64], a: &[f64]| impulse(b, a).iter().fold(0.0, |s, v| s + v * v);
    let (gd, gdf) = (gain_sum(&[1.0], &a), gain_freq(&[1.0], &a));
    let vd = s2 * gd;
    let vc = shaping(&secs).iter().fold(0.0, |s, (nu, de)| s + s2 * gain_sum(nu, de));
    let rev: Vec<(Vec<f64>, Vec<f64>)> = secs.iter().rev().cloned().collect();
    let vr = shaping(&rev).iter().fold(0.0, |s, (nu, de)| s + s2 * gain_sum(nu, de));
    println!("q = 2^-15 = {} = {:.4} uV; one rounding: variance q^2/12 = {}, rms {:.4} q", sci(q, 4), q * MV * 1000.0, sci(s2, 3), s2.sqrt() / q);
    println!("noise gain of 1/A(z): squared impulse response {:.1}, frequency average {:.1}", gd, gdf);
    assert!((gd - gdf).abs() < 1e-6 * gd);
    for (k, (nu, de)) in shaping(&secs).iter().enumerate() {
        println!("  noise path from section {}: {:.3} by impulse, {:.3} by frequency", k + 1, gain_sum(nu, de), gain_freq(nu, de)); }
    let mut seed: u64 = 2026;
    let mut next = || { seed = seed.wrapping_add(0x9E3779B97F4A7C15); let mut z = seed;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); (z ^ (z >> 31)) >> 11 };
    let x: Vec<f64> = (0..40000).map(|_| ((next() % 16384) as f64 - 8192.0) * q).collect(); // white input, +-0.25
    let (mut errs, mut none) = (Vec::new(), Vec::new());
    let ed: Vec<f64> = run(&b, &a, &x, q, &mut none).iter().zip(run(&b, &a, &x, 0.0, &mut none)).map(|(u, v)| u - v).collect();
    let (mut yq, mut yf) = (x.clone(), x.clone());
    for (bb, aa) in &secs { yq = run(bb, aa, &yq, q, &mut errs); yf = run(bb, aa, &yf, 0.0, &mut none); }
    let ec: Vec<f64> = yq.iter().zip(&yf).map(|(u, v)| u - v).collect();
    println!("rounding errors seen: {}, mean {:+.4} q, variance / (q^2/12) {:.4}", errs.len(), sum(&errs) / errs.len() as f64 / q, var(&errs) / s2);
    println!("direct form, 1 rounding:   predicted rms {:.1} q, simulated {:.1} q", vd.sqrt() / q, var(&ed).sqrt() / q);
    println!("cascade, 3 roundings:      predicted rms {:.2} q, simulated {:.2} q", vc.sqrt() / q, var(&ec).sqrt() / q);
    assert!((var(&ed) / vd - 1.0).abs() < 0.1 && (var(&ec) / vc - 1.0).abs() < 0.1 && (var(&errs) / s2 - 1.0).abs() < 0.02 && (sum(&errs) / errs.len() as f64).abs() < 0.01 * q);
    println!("in the ECG (1.0 = {:.0} mV): direct {:.1} uV rms, cascade {:.2} uV rms; ratio {:.1}, {:.1} dB",
        MV, vd.sqrt() * MV * 1000.0, vc.sqrt() * MV * 1000.0, (vd / vc).sqrt(), 10.0 * (vd / vc).log10());
    let hum = 500.0 / (1.0 + ((PI * 50.2 / FS).tan() / wc).powi(10)).sqrt(); // uV of 0.5 mV hum left at 50.2 Hz
    println!("hum left by the exact filter {:.2} uV; direct-form noise / hum {:.1}", hum, vd.sqrt() * MV * 1000.0 / hum);
    let peak = |bb: &[f64], aa: &[f64]| (0..2001).map(|i| freq(bb, aa, PI * i as f64 / 2000.0)).fold(0.0, f64::max);
    println!("peak gain of each section: {}; sections in reverse order {:.2} q",
        j(&secs.iter().map(|(bb, aa)| peak(bb, aa)).collect::<Vec<_>>(), 3), vr.sqrt() / q);
    println!("breaks: direct form at F = 9: largest radius {:.4}", maxr(&dirp(9)));
    println!("try: 24-bit words: direct {:.3} uV, cascade {:.4} uV; direct form II inner gain at 0 Hz 1/A(1) = {:.1}, {} bits of headroom",
        vd.sqrt() * MV * 1000.0 / 256.0, vc.sqrt() * MV * 1000.0 / 256.0, 1.0 / a1, (1.0 / a1).log2().ceil());
    let a3 = &dens[2]; let (mut y1, mut y2) = (1000.0f64, 0.0f64); // zero input into the 0.9259 biquad, integers in q
    for _ in 0..3000 { let y = -(a3[1] * y1 + a3[2] * y2 + 0.5).floor(); y2 = y1; y1 = y; }
    println!("zero-input biquad from 1000 q: stuck at {} q after 3000 steps ({:.2} uV); bound 0.5/A3(1) = {:.2} q",
        y1, y1 * q * MV * 1000.0, 0.5 / sum(a3));
    assert!(y1 != 0.0 && y1 == y2 && y1.abs() <= 0.5 / sum(a3));
    println!("chart, direct  {}\nchart, cascade {}", j(&chart.iter().map(|r| r.0).collect::<Vec<_>>(), 4), j(&chart.iter().map(|r| r.1).collect::<Vec<_>>(), 4));
    println!("ALL CHECKS PASS");
}
