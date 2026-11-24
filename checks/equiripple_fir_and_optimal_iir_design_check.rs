// Optimal filters -- the same check as the Python, in Rust.  No crates.  ECG hum spec, fs = 500 Hz: half power
// or more to 20 Hz, 40 dB off from 49.8 to 250 Hz.  Same roads; complex numbers are a small struct written out.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
const FS: f64 = 500.0; const FP: f64 = 20.0; const FST: f64 = 49.8; const ATT: f64 = 40.0; const RP: f64 = 3.0;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
impl C { fn abs(self) -> f64 { self.re.hypot(self.im) } fn arg(self) -> f64 { self.im.atan2(self.re) } fn conj(self) -> C { c(self.re, -self.im) }
    fn s(self, k: f64) -> C { c(self.re * k, self.im * k) } fn cos(self) -> C { c(self.re.cos() * self.im.cosh(), -self.re.sin() * self.im.sinh()) } }
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }
struct Des { zs: Vec<C>, ps: Vec<C>, g: f64, k1: f64 }
struct G { wp: f64, ws: f64, wpw: f64, r: f64 }
fn db(g: f64) -> f64 { if g > 1e-15 { 20.0 * g.log10() } else { -300.0 } }
fn maxf(v: impl Iterator<Item = f64>) -> f64 { v.fold(f64::MIN, f64::max) }
fn resp(d: &Des, f: f64) -> C {                         // H(z) on the unit circle from zeros and poles
    let z = cis(2.0 * PI * f / FS);
    d.ps.iter().fold(d.zs.iter().fold(c(d.g, 0.0), |h, q| h * (z - *q)), |h, p| h / (z - *p))
}
fn poly(rts: &[C]) -> Vec<f64> {                        // multiply out the product of (1 - root z^-1)
    let mut cf = vec![c(1.0, 0.0)];
    for q in rts { let mut n = cf.clone(); n.push(c(0.0, 0.0)); for i in 1..n.len() { n[i] = n[i] - *q * cf[i - 1]; } cf = n; } cf.iter().map(|v| v.re).collect()
}
fn digital(g: &G, za: &[C], pa: &[C], h0: f64, n: usize, k1: f64) -> Des { // bilinear map z = (1 + s)/(1 - s), s scaled by Wp
    let m = |q: &C| (c(1.0, 0.0) + q.s(g.wpw)) / (c(1.0, 0.0) - q.s(g.wpw));
    let mut d = Des { zs: za.iter().map(m).chain(std::iter::repeat(c(-1.0, 0.0))).take(n).collect(), ps: pa.iter().map(m).collect(), g: 1.0, k1 };
    d.g = h0 / resp(&d, 0.0).abs(); d                   // gain at 0 Hz set to h0
}
fn agm_k(k: f64) -> f64 {                               // complete elliptic integral K(k) by the AGM
    let (mut a, mut b) = (1.0f64, (1.0 - k * k).sqrt());
    for _ in 0..40 { let t = (a + b) / 2.0; b = (a * b).sqrt(); a = t; } PI / (2.0 * a)
}
fn fint(phi: f64, k: f64, n: usize) -> f64 {            // integral of 1/sqrt(1 - k^2 sin^2 t), Simpson's rule
    (0..=n).map(|i| (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) / (1.0 - (k * (i as f64 * phi / n as f64).sin()).powi(2)).sqrt()).sum::<f64>() * phi / n as f64 / 3.0
}
fn cde(u: C, k: f64) -> C {                             // Jacobi cd(uK, k) by descending Landen steps
    let (mut ks, mut k) = (vec![], k); for _ in 0..10 { k = (k / (1.0 + (1.0 - k * k).sqrt())).powi(2); ks.push(k); }
    ks.iter().rev().fold(u.s(PI / 2.0).cos(), |w, kn| w.s(1.0 + kn) / (c(1.0, 0.0) + (w * w).s(*kn)))
}
fn h0(n: usize, e: f64) -> f64 { if n % 2 == 1 { 1.0 } else { 1.0 / (1.0 + e * e).sqrt() } }
fn butter(g: &G, n: usize) -> Des { digital(g, &[], &(0..n).map(|i| cis(PI * (2 * i + n + 1) as f64 / (2 * n) as f64)).collect::<Vec<_>>(), 1.0, n, 0.0) }
fn cheby(g: &G, n: usize, e: f64) -> Des {
    let a = (1.0 / e).asinh() / n as f64; let pa: Vec<C> = (0..n).map(|i| { let t = (2 * i + 1) as f64 * PI / (2 * n) as f64; c(-a.sinh() * t.sin(), a.cosh() * t.cos()) }).collect();
    digital(g, &[], &pa, h0(n, e), n, 0.0)
}
fn ellip(g: &G, n: usize, e: f64) -> Des {
    let (k, u): (f64, Vec<f64>) = (1.0 / g.r, (1..=n / 2).map(|i| (2 * i - 1) as f64 / n as f64).collect());
    let k1 = k.powi(n as i32) * u.iter().map(|ui| cde(c(1.0 - ui, 0.0), k).re.powi(4)).product::<f64>();   // sn(uK) = cd((1 - u)K)
    let v0 = fint((1.0 / e).atan(), (1.0 - k1 * k1).sqrt(), 4000) / (n as f64 * agm_k(k1));
    let mut za: Vec<C> = u.iter().map(|ui| c(0.0, 1.0 / (k * cde(c(*ui, 0.0), k).re))).collect();     // zeros in the stopband
    let mut pa: Vec<C> = u.iter().map(|ui| c(0.0, 1.0) * cde(c(*ui, -v0), k)).collect();
    if n % 2 == 1 { pa.push(c(0.0, 1.0) * cde(c(1.0, -v0), k)); } for i in 0..n / 2 { za.push(za[i].conj()); pa.push(pa[i].conj()); }
    digital(g, &za, &pa, h0(n, e), n, k1)
}
fn worst(d: &Des, stop: &[f64]) -> f64 { maxf(stop.iter().map(|f| resp(d, *f).abs())) }
fn gdelay(d: &Des, f: f64) -> f64 { let h = 1e-4; -(resp(d, f + h) / resp(d, f - h)).arg() / (4.0 * PI * h) * 1000.0 }
fn settled(b: &[f64], a: &[f64], f: f64) -> f64 {        // run the difference equation on a sine; amplitude, last 5 s
    let mut y: Vec<f64> = vec![];
    for n in 0..3000usize {
        let v: f64 = (0..b.len().min(n + 1)).map(|k| b[k] * (2.0 * PI * f * (n - k) as f64 / FS).sin()).sum::<f64>(); y.push(v - (1..a.len().min(n + 1)).map(|k| a[k] * y[n - k]).sum::<f64>());
    }
    2.0 * (500..3000).fold(c(0.0, 0.0), |s, n| s + cis(-2.0 * PI * f * n as f64 / FS).s(y[n])).abs() / 2500.0
}
fn bary(w: f64, x: &[f64], cc: &[f64], gm: &[f64]) -> f64 {  // the cosine polynomial, barycentric form
    let t = w.cos(); if let Some(i) = x[..gm.len()].iter().position(|xi| *xi == t) { return cc[i]; }
    let q: Vec<f64> = (0..gm.len()).map(|i| gm[i] / (t - x[i])).collect();
    (0..gm.len()).map(|i| q[i] * cc[i]).sum::<f64>() / q.iter().sum::<f64>()
}
fn weights(x: &[f64], n: usize) -> Vec<f64> { (0..n).map(|i| 1.0 / (0..n).filter(|j| *j != i).map(|j| x[i] - x[j]).product::<f64>()).collect() }
fn remez(g: &G, l: usize, kw: f64) -> (Vec<f64>, f64) { // Parks-McClellan exchange; weight kw in the passband
    let m = (l - 1) / 2; let (np, ns) = (((32 * (m + 2)) as f64 * g.wp / (g.wp + PI - g.ws)).round().max(4.0) as usize, 32 * (m + 2));
    let gr: Vec<f64> = (0..np).map(|i| g.wp * i as f64 / (np - 1) as f64).chain((0..ns).map(|i| g.ws + (PI - g.ws) * i as f64 / (ns - l % 2) as f64)).collect();
    let cs = |i: usize| if l % 2 == 0 { (gr[i] / 2.0).cos() } else { 1.0 };   // even L: amplitude is cos(w/2) times a polynomial, 0 at 250 Hz
    let (dg, wg, sg) = (|i: usize| if i < np { 1.0 / cs(i) } else { 0.0 }, |i: usize| if i < np { kw * cs(i) } else { cs(i) }, |i: usize| if i % 2 == 0 { 1.0 } else { -1.0 });
    let mut ext: Vec<usize> = (0..m + 2).map(|i| (i as f64 * (gr.len() - 1) as f64 / (m + 1) as f64).round() as usize).collect();
    let (mut x, mut cc, mut gm, mut dl) = (vec![], vec![], vec![], 0.0);
    for _ in 0..60 {
        x = ext.iter().map(|e| gr[*e].cos()).collect(); let bw = weights(&x, m + 2);   // bw, gm: barycentric weights
        dl = (0..m + 2).map(|i| bw[i] * dg(ext[i])).sum::<f64>() / (0..m + 2).map(|i| bw[i] * sg(i) / wg(ext[i])).sum::<f64>();
        cc = (0..m + 2).map(|i| dg(ext[i]) - sg(i) * dl / wg(ext[i])).collect(); gm = weights(&x, m + 1);   // A must hit cc at the old set
        let e: Vec<f64> = (0..gr.len()).map(|i| wg(i) * (dg(i) - bary(gr[i], &x, &cc, &gm))).collect();
        let mut new: Vec<usize> = vec![];                   // new set: alternating peaks of the error
        for i in 0..gr.len() {
            if e[i].abs() < dl.abs() * (1.0 - 1e-6) || [i.wrapping_sub(1), i + 1].iter().any(|j| *j < gr.len() && (*j < np) == (i < np) && (e[i] - e[*j]) * e[i] < 0.0) { continue; }
            match new.last().copied() { Some(j) if (e[i] > 0.0) == (e[j] > 0.0) => { if e[i].abs() > e[j].abs() { *new.last_mut().unwrap() = i; } } _ => new.push(i) }
        }
        while new.len() > m + 2 { if e[new[0]].abs() < e[new[new.len() - 1]].abs() { new.remove(0); } else { new.pop(); } }
        if new.len() < m + 2 || new == ext { break; } ext = new;
    }
    let am: Vec<f64> = (0..=m).map(|j| bary(2.0 * PI * j as f64 / l as f64, &x, &cc, &gm) * if l % 2 == 0 { (PI * j as f64 / l as f64).cos() } else { 1.0 }).collect();   // taps from L samples
    ((0..l).map(|n| (am[0] + 2.0 * (1..=m).map(|j| am[j] * (2.0 * PI * (j as f64) * (n as f64 - (l - 1) as f64 / 2.0) / l as f64).cos()).sum::<f64>()) / l as f64).collect(), dl.abs())
}
fn amp(h: &[f64], f: f64) -> f64 { h.iter().enumerate().map(|(k, v)| v * (2.0 * PI * f / FS * (k as f64 - (h.len() - 1) as f64 / 2.0)).cos()).sum() }
fn alternations(h: &[f64], kw: f64, pas: &[f64], stop: &[f64]) -> usize { // sign changes between the peaks of the weighted error
    let e: Vec<f64> = pas.iter().map(|f| kw * (1.0 - amp(h, *f))).chain(stop.iter().map(|f| -amp(h, *f))).collect();
    let top = 0.995 * maxf(e.iter().map(|v| v.abs()));
    let pk: Vec<usize> = (0..e.len()).filter(|&i| e[i].abs() >= top && ([0, 400, 401, e.len() - 1].contains(&i) || e[i].abs() >= e[i - 1].abs().max(e[i + 1].abs()))).collect();
    1 + pk.windows(2).filter(|w| (e[w[0]] > 0.0) != (e[w[1]] > 0.0)).count()
}
fn hamming(l: usize) -> Vec<f64> {                       // the window design of Digital filters
    let (fc, mid) = ((FP + FST) / 2.0, (l - 1) as f64 / 2.0);
    let h: Vec<f64> = (0..l).map(|k| { let t = k as f64 - mid; (0.54 - 0.46 * (2.0 * PI * k as f64 / (l - 1) as f64).cos())
        * if 2 * k != l - 1 { (2.0 * PI * fc / FS * t).sin() / (PI * t) } else { 2.0 * fc / FS } }).collect();
    let s: f64 = h.iter().sum(); h.iter().map(|v| v / s).collect()
}
fn f1(x: f64) -> String { let s = format!("{:5.1}", x); if s == " -0.0" { "  0.0".into() } else { s } }
fn yes(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let (wp, ws) = (2.0 * PI * FP / FS, 2.0 * PI * FST / FS); let wpw = (wp / 2.0).tan();
    let (r, eps) = ((ws / 2.0).tan() / wpw, (10f64.powf(RP / 10.0) - 1.0).sqrt());
    let (dd, g) = ((10f64.powf(ATT / 10.0) - 1.0).sqrt() / eps, G { wp, ws, wpw, r });
    let (stop, pas): (Vec<f64>, Vec<f64>) = ((0..4005).map(|i| FST + 0.05 * i as f64).collect(), (0..401).map(|i| 0.05 * i as f64).collect());
    let meets = |d: &Des| resp(d, FP).abs().powi(2) >= 0.5 - 1e-9 && worst(d, &stop) <= 10f64.powf(-ATT / 20.0);
    let (nb, nc) = ((10f64.powf(ATT / 10.0) - 1.0).log10() / (2.0 * r.log10()), dd.acosh() / r.acosh());
    let ks = [1.0 / r, (1.0 - 1.0 / (r * r)).sqrt(), 1.0 / dd, (1.0 - 1.0 / (dd * dd)).sqrt()];   // K(k), K'(k) = K(sqrt(1 - k^2))
    let kv: Vec<f64> = ks.iter().map(|k| agm_k(*k)).collect(); let (ne, kgap) = (kv[0] * kv[3] / (kv[1] * kv[2]), maxf((0..4).map(|i| (kv[i] - fint(PI / 2.0, ks[i], 200000)).abs())));
    println!("spec: fs {:.0} Hz; half power or more to {:.0} Hz; {:.0} dB off from {:.1} Hz to {:.0} Hz\nby hand: warped edge ratio r {:.4}; ripple eps {:.4}, floor {:.3} dB; D {:.2}",
             FS, FP, ATT, FST, FS / 2.0, r, eps, db(1.0 / (1.0 + eps * eps).sqrt()), dd);
    println!("Butterworth: log10(10^(A/10) - 1) / (2 log10 r) = {:.5} / {:.4} = {:.3}\nChebyshev:   acosh(D) / acosh(r) = {:.4} / {:.4} = {:.3}", (10f64.powf(ATT / 10.0) - 1.0).log10(), 2.0 * r.log10(), nb, dd.acosh(), r.acosh(), nc);
    println!("elliptic:    K(1/r) {:.4}, K' {:.4}; K(1/D) {:.4}, K' {:.4}; ratio {:.3}", kv[0], kv[1], kv[2], kv[3], ne);
    println!("K by Simpson's rule agrees with the AGM to 1e-9: {}\ndesign       order: search formula  mult  pole radius  worst stop dB  hum left uV  sim=H  peak delay ms", yes(kgap < 1e-9));
    let mut des: Vec<Des> = vec![];
    for (name, need, fam) in [("Butterworth", nb, 0), ("Chebyshev I", nc, 1), ("elliptic", ne, 2)] {
        let mk = |n: usize| match fam { 0 => butter(&g, n), 1 => cheby(&g, n, eps), _ => ellip(&g, n, eps) };
        let n = (1..12).find(|n| meets(&mk(*n))).unwrap(); let d = mk(n); let b: Vec<f64> = poly(&d.zs).iter().map(|v| v * d.g).collect();
        let (am, h, pr) = (settled(&b, &poly(&d.ps), 50.2), resp(&d, 50.2).abs(), maxf(d.ps.iter().map(|p| p.abs())));
        println!("{:12}         {:3}    {:3}     {:3}     {:.4}       {:7.2}       {:6.2}    {}     {:6.2}", name, n, need.ceil(), 2 * n + 1, pr,
                 db(worst(&d, &stop)), 500.0 * am, if (am - h).abs() < 1e-6 { "yes" } else { "no " }, maxf(pas[1..].iter().map(|f| gdelay(&d, *f))));
        assert!(n == need.ceil() as usize && n == [5, 4, 3][fam] && pr < 1.0 && (am - h).abs() < 1e-6);
        des.push(d);
    }
    let t4 = |x: f64| if x <= 1.0 { (4.0 * x.acos()).cos() } else { (4.0 * x.acosh()).cosh() };
    let cf = maxf(pas.iter().chain(stop.iter()).map(|f| (resp(&des[1], *f).abs() - 1.0 / (1.0 + (eps * t4((PI * f / FS).tan() / wpw)).powi(2)).sqrt()).abs()));
    println!("Chebyshev 4 against 1/sqrt(1 + eps^2 T4^2), both bands, agree to 1e-12: {}", yes(cf < 1e-12));
    let e3 = &des[2]; let ep: Vec<f64> = pas.iter().map(|f| db(resp(e3, *f).abs())).collect();
    let (epmin, epmax, est) = (-maxf(ep.iter().map(|v| -v)), maxf(ep.iter().cloned()), -10.0 * (1.0 + (eps / e3.k1).powi(2)).log10());
    println!("elliptic 3: passband {:.3} to {} dB; stopband peaks {:.2} dB, theory {:.2} dB; zero at {:.2} Hz", epmin,
             format!("{:.3}", epmax).replace("-0.000", "0.000"), db(worst(e3, &stop)), est, FS / (2.0 * PI) * e3.zs[0].arg());
    let dp3 = (1.0 - 10f64.powf(-RP / 20.0)) / (1.0 + 10f64.powf(-RP / 20.0));   // a 3 dB band written as 1 +- dp
    let mut flat = vec![];
    for (name, dp, ds, l0) in [("PM, flat", 0.01, 0.01, 11), ("PM, even L", 0.01, 0.01, 10), ("PM, 3 dB ripple", dp3, 0.01 * (1.0 + dp3), 11)] {
        let l = (l0..81).step_by(2).find(|l| remez(&g, *l, ds / dp).1 <= ds).unwrap();
        let ((h, dl), dl2) = (remez(&g, l, ds / dp), remez(&g, l - 2, ds / dp).1);
        let (sc, kai) = (if dp > 0.05 { 1.0 / maxf(pas.iter().map(|f| amp(&h, *f))) } else { 1.0 }, /* the rippled design is scaled to peak gain 1 */ (-20.0 * (dp * ds).sqrt().log10() - 13.0) / (14.6 * (FST - FP) / FS) + 1.0);
        let (wsm, al) = (maxf(stop.iter().map(|f| amp(&h, *f).abs())), alternations(&h, ds / dp, &pas, &stop));
        println!("{}: {} taps, M = {}, delay {:.0} ms (Kaiser's estimate {:.1} taps); ripple {:.5}, {} taps {:.5}", name, l, (l - 1) as f64 / 2.0, (l - 1) as f64 / 2.0 / FS * 1000.0, kai, dl, l - 2, dl2);
        println!("  measured: worst stop {:.2} dB, at 20 Hz {:.2} dB; alternations {} of {} needed; hum left {:.2} uV", db(sc * wsm),
                 db(sc * amp(&h, FP).abs()), al, (l - 1) / 2 + 2, 500.0 * sc * settled(&h, &[1.0], 50.2));
        assert!(dl <= ds && ds < dl2 && al >= (l - 1) / 2 + 2 && (wsm - dl).abs() < 1e-2 * dl && sc * amp(&h, FP).abs() >= 0.5f64.sqrt());
        if flat.is_empty() { flat = h; }
    }
    let hw: Vec<f64> = [51, 53].iter().map(|l| db(maxf(stop.iter().map(|f| amp(&hamming(*l), *f).abs())))).collect();
    println!("Hamming FIR from Digital filters: 53 taps worst stop {:.2} dB, 51 taps {:.2} dB", hw[1], hw[0]);
    println!("chart, f Hz     {}", (0..101).map(|i| format!("{:5.1}", 2.5 * i as f64)).collect::<Vec<_>>().join(" "));
    let h53 = hamming(53); for (nm, k) in [("Butterworth", 0), ("Chebyshev I", 1), ("elliptic", 2), ("PM, flat", 3), ("Hamming 53", 4)] {
        let row: Vec<String> = (0..101).map(|i| { let f = 2.5 * i as f64;
            f1(db(match k { 0..=2 => resp(&des[k], f).abs(), 3 => amp(&flat, f).abs(), _ => amp(&h53, f).abs() }).max(-80.0)) }).collect();
        println!("chart, {:11} {}", nm, row.join(" "));
    }
    let brk = [db(worst(&cheby(&g, 3, eps), &stop)), db(worst(&ellip(&g, 2, eps), &stop)), db(worst(&ellip(&g, 3, (10f64.powf(0.01) - 1.0).sqrt()), &stop))];
    println!("breaks: Chebyshev order 3 {:.2} dB; elliptic order 2 {:.2} dB; elliptic 3 held to 0.1 dB ripple {:.2} dB", brk[0], brk[1], brk[2]);
    assert!(kgap < 1e-9 && cf < 1e-12 && hw[1] < -40.0 && -40.0 < hw[0] && brk.iter().all(|b| *b > -40.0));
    assert!(epmax.abs() < 1e-9 && (epmin + RP).abs() < 1e-6 && (db(worst(e3, &stop)) - est).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
