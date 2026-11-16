// Frames in outline: a Gabor frame with half-overlapping windows on a ten-second bird call.
// std only.  Roads: frame bounds from the window-energy sum M*G(k), against the frame
// operator built atom by atom as a matrix, against the energy of FFT coefficients.
use std::f64::consts::PI;
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn sc(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn abs2(self) -> f64 { self.re * self.re + self.im * self.im }
}
const Z: C = C { re: 0.0, im: 0.0 }; const FS: usize = 6400; const SEC: usize = 10; const L: usize = 256; const M: usize = 256;
fn fft(x: &[C]) -> Vec<C> { // radix-2, recursive: X[m] = sum x[k] e^(-2 pi i m k/n)
    let n = x.len();
    if n == 1 { return x.to_vec(); }
    let ev: Vec<C> = x.iter().step_by(2).cloned().collect();
    let od: Vec<C> = x.iter().skip(1).step_by(2).cloned().collect();
    let (e, o) = (fft(&ev), fft(&od));
    let mut out = vec![Z; n];
    for k in 0..n / 2 {
        let t = 2.0 * PI * k as f64 / n as f64;
        let w = C { re: t.cos(), im: -t.sin() }.mul(o[k]);
        out[k] = e[k].add(w); out[k + n / 2] = e[k].sub(w);
    }
    out
}
fn ifft_sum(c: &[C]) -> Vec<C> { let cc: Vec<C> = c.iter().map(|z| z.conj()).collect(); fft(&cc).iter().map(|z| z.conj()).collect() }
fn window(kind: &str, n: usize) -> Vec<f64> { // unit-energy windows sampled at k + 1/2
    (0..n).map(|k| { let s = (PI * (k as f64 + 0.5) / n as f64).sin();
        match kind { "rect" => 1.0 / (n as f64).sqrt(), "sine" => (2.0 / n as f64).sqrt() * s,
                     _ => (8.0 / (3.0 * n as f64)).sqrt() * s.powi(2) } }).collect()
}
fn gsum(g: &[f64], a: usize) -> Vec<f64> { (0..a).map(|k| (0..g.len() / a).map(|j| g[k + j * a].powi(2)).sum()).collect() }
fn bounds(g: &[f64], a: usize, m: usize) -> (f64, f64) {
    let s: Vec<f64> = gsum(g, a).iter().map(|v| m as f64 * v).collect();
    (s.iter().cloned().fold(f64::INFINITY, f64::min), s.iter().cloned().fold(f64::NEG_INFINITY, f64::max))
}
fn analyse(f: &[f64], g: &[f64], a: usize) -> Vec<Vec<C>> { // c[n][m] = <f, g_(m,n)>
    let n_ = f.len();
    (0..n_ / a).map(|n| { let seg: Vec<C> = (0..g.len()).map(|k| C { re: f[(n * a + k) % n_] * g[k], im: 0.0 }).collect(); fft(&seg) }).collect()
}
fn synth(c: &[Vec<C>], gam: &[f64], a: usize, n_: usize) -> Vec<C> {
    let mut out = vec![Z; n_];
    for (n, row) in c.iter().enumerate() {
        let s = ifft_sum(row);
        for k in 0..gam.len() { let i = (n * a + k) % n_; out[i] = out[i].add(s[k].sc(gam[k])); }
    }
    out
}
fn cenergy(c: &[Vec<C>]) -> f64 { c.iter().map(|r| r.iter().map(|z| z.abs2()).sum::<f64>()).sum() }
fn err_energy(x: &[C], f: &[f64]) -> f64 { x.iter().zip(f).map(|(z, y)| z.sub(C { re: *y, im: 0.0 }).abs2()).sum() }
fn close(x: f64, y: f64, tol: f64) -> bool { (x - y).abs() <= tol }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn eig2(s: [[f64; 2]; 2]) -> (f64, f64) {
    let (t, d) = (s[0][0] + s[1][1], s[0][0] * s[1][1] - s[0][1] * s[1][0]);
    let r = (t * t / 4.0 - d).sqrt(); (t / 2.0 - r, t / 2.0 + r)
}
fn frame_op(vs: &[(f64, f64)]) -> [[f64; 2]; 2] {
    let p = |v: &(f64, f64), i: usize| if i == 0 { v.0 } else { v.1 };
    let mut s = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { s[i][j] = vs.iter().map(|v| p(v, i) * p(v, j)).sum(); } }
    s
}
struct Rng(u64);
impl Rng { fn next(&mut self) -> f64 { // SplitMix64, uniform on [-1, 1)
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9); z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(52) - 1.0 } }
fn main() {
    println!("Mercedes frame: three unit vectors at 90, 210, 330 degrees in the plane");
    let v: Vec<(f64, f64)> = [90.0f64, 210.0, 330.0].iter().map(|d| ((d * PI / 180.0).cos(), (d * PI / 180.0).sin())).collect();
    for (name, vs) in [("three vectors", &v[..]), ("first two only", &v[..2])] {
        let (a, b) = eig2(frame_op(vs)); println!("  {}: A = {:.6}, B = {:.6}", name, a, b);
    }
    for f2 in [(1.0f64, 0.0f64), (0.0, 1.0), (0.6, 0.8)] {
        let s: f64 = v.iter().map(|w| (f2.0 * w.0 + f2.1 * w.1).powi(2)).sum();
        println!("  f = ({:.1}, {:.1}): sum of squared coefficients {:.6}", f2.0, f2.1, s);
        assert!(close(s, 1.5, 1e-12));
    }
    let z: (f64, f64) = (v.iter().map(|w| w.0).sum(), v.iter().map(|w| w.1).sum());
    println!("  coefficients (1, 1, 1) build ({:.6}, {:.6}): not unique", z.0.abs(), z.1.abs());
    assert!(close(eig2(frame_op(&v[..2])).0, 0.5, 1e-12));
    println!("\nsmall instance N = 16, L = 8, hop 4, M = 8: frame operator built atom by atom");
    let (n0, l0, a0) = (16usize, 8usize, 4usize);
    for kind in ["sine", "hann"] {
        let g = window(kind, l0); let mut s = vec![vec![Z; n0]; n0];
        for n in 0..n0 / a0 { for m in 0..l0 {
            let mut at = vec![Z; n0];
            for k in 0..l0 { let th = 2.0 * PI * (m * k) as f64 / l0 as f64; at[(n * a0 + k) % n0] = C { re: th.cos(), im: th.sin() }.sc(g[k]); }
            for i in 0..n0 { for j in 0..n0 { s[i][j] = s[i][j].add(at[i].mul(at[j].conj())); } }
        } }
        let mut off: f64 = 0.0;
        for i in 0..n0 { for j in 0..n0 { if i != j { off = off.max(s[i][j].abs2().sqrt()); } } }
        let d: Vec<f64> = (0..n0).map(|i| s[i][i].re).collect();
        let (dmin, dmax) = (d.iter().cloned().fold(f64::INFINITY, f64::min), d.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
        let (a, b) = bounds(&g, a0, l0);
        println!("  {}: off-diagonal below 1e-12 {}; diagonal {:.6} to {:.6}; M*G {:.6} to {:.6}", kind, yn(off < 1e-12), dmin, dmax, a, b);
        assert!(off < 1e-12 && close(dmin, a, 1e-12) && close(dmax, b, 1e-12));
    }
    let n = FS * SEC;
    println!("\nbird call: {} s at {} Hz, N = {}, {} slices; window {} samples = {:.0} ms, {} channels {:.0} Hz apart", SEC, FS, n, n / 128, L, 1000.0 * L as f64 / FS as f64, M, FS as f64 / M as f64);
    let f: Vec<f64> = (0..n).map(|t| { let s = t as f64 / FS as f64; 0.5 * (2.0 * PI * (1000.0 * s + 75.0 * s.powi(2))).sin() }).collect();
    let ef: f64 = f.iter().map(|x| x * x).sum();
    println!("pitch 1000 Hz at 0 s rising to {} Hz at {} s; energy {:.4}", 1000 + 150 * SEC, SEC, ef);
    let mut res = std::collections::HashMap::new();
    for (kind, a) in [("rect", 256usize), ("sine", 128), ("hann", 128), ("hann", 64), ("sine", 256)] {
        let g = window(kind, L); let (a_, b_) = bounds(&g, a, M); res.insert((kind, a), (a_, b_));
        println!("  {:4} hop {} ({:.0} ms): a*b = {:.2}, atoms {} = {:.0} N, A = {:.6}, B = {:.6}, B/A = {:.2}", kind, a, 1000.0 * a as f64 / FS as f64,
                 a as f64 / M as f64, n / a * M, (n / a * M) as f64 / n as f64, a_, b_, b_ / a_);
    }
    let mgh: Vec<f64> = gsum(&window("hann", L), 128).iter().map(|v| M as f64 * v).collect();
    let mgs: Vec<f64> = gsum(&window("sine", L), 128).iter().map(|v| M as f64 * v).collect();
    let mg2: Vec<f64> = gsum(&window("sine", L), 256).iter().map(|v| M as f64 * v).collect();
    let pts = |v: &[f64], p: usize| (0..=256).step_by(32).map(|k| format!("{:.3}", v[k % p])).collect::<Vec<_>>().join(" ");
    println!("figure, M*G at 0,5,...,40 ms: hann {}", pts(&mgh, 128));
    println!("figure, sine half {} | sine no overlap {}", pts(&mgs, 128), pts(&mg2, 256));
    let mc = M as f64 * 8.0 / (3.0 * L as f64); let (hl, hh) = (res[&("hann", 128)].0 / mc, res[&("hann", 128)].1 / mc);
    println!("hann by hand: H^2 = 8/(3L) = {:.6}, M H^2 = {:.6}; sin^4 + cos^4 from {:.6} to {:.6}; 4/3 = {:.6}, 8/3 = {:.6}; mean of M*G {:.6}", 8.0 / (3.0 * L as f64), mc, hl, hh, 4.0 / 3.0, 8.0 / 3.0, mgh.iter().sum::<f64>() / 128.0);
    assert!(close(res[&("rect", 256)].0, 1.0, 1e-12) && close(res[&("sine", 128)].1, 2.0, 1e-12));
    assert!(close(res[&("hann", 128)].0, 4.0 / 3.0, 5e-4) && close(res[&("hann", 128)].1, 8.0 / 3.0, 5e-4));
    let mut ch = vec![];
    for kind in ["sine", "hann"] { // road 3: FFT energy against the weighted-energy formula
        let g = window(kind, L); let c = analyse(&f, &g, 128);
        let ec = cenergy(&c); let gk = gsum(&g, 128);
        let ew = M as f64 * (0..n).map(|t| f[t].powi(2) * gk[t % 128]).sum::<f64>();
        println!("  {}: sum |c|^2 = {:.4}; M * sum f^2 G = {:.4}; ratio to energy {:.6}", kind, ec, ew, ec / ef);
        let (a_, b_) = res[&(kind, 128)];
        assert!(close(ec, ew, 1e-6 * ew) && a_ - 1e-9 <= ec / ef && ec / ef <= b_ + 1e-9);
        if kind == "hann" { ch = c; }
    }
    let gh = window("hann", L); let ghs = gsum(&gh, 128);
    let dual: Vec<f64> = (0..L).map(|k| gh[k] / (M as f64 * ghs[k % 128])).collect();
    let err = (err_energy(&synth(&ch, &dual, 128, n), &f) / ef).sqrt();
    let half_g: Vec<f64> = gh.iter().map(|v| v / 2.0).collect();
    let wrong = (err_energy(&synth(&ch, &half_g, 128, n), &f) / ef).sqrt();
    println!("hann rebuild with dual window: relative error below 1e-12 {}; with g/2: {:.6}", yn(err < 1e-12), wrong);
    assert!(err < 1e-12 && wrong > 0.1);
    let mut spike = vec![0.0; 1024]; spike[64] = 1.0;
    let r = cenergy(&analyse(&spike, &gh, 128));
    println!("spike at sample 64: sum |c|^2 = {:.6} = M*G(64)", r);
    assert!(close(r, M as f64 * ghs[64], 1e-9));
    println!("critical sine window, hop = L: A = 2 sin^2(pi/(2L))");
    for ln in [64usize, 256, 1024] {
        let a_ = bounds(&window("sine", ln), ln, ln).0; let fo = 2.0 * (PI / (2.0 * ln as f64)).sin().powi(2);
        println!("  L = {:4}: A = {:.9}, formula {:.9}, 1/sqrt(A) = {:.1}", ln, a_, fo, a_.powf(-0.5));
        assert!(close(a_, fo, 1e-15));
    }
    let tone: Vec<f64> = (0..n).map(|t| (2.0 * PI * (49 * t) as f64 / 256.0).sin()).collect();
    let full = analyse(&tone, &window("rect", L), 256); let et = cenergy(&full);
    let half: Vec<Vec<C>> = full.iter().map(|r| r.iter().step_by(2).cloned().collect()).collect();
    let etone: f64 = tone.iter().map(|x| x * x).sum();
    println!("half the channels (even only), rect hop 256: atoms {}; {:.2} Hz tone, energy {:.1}, all channels {:.1}, even channels below 1e-12 {}",
             n / 256 * 128, 49.0 * FS as f64 / 256.0, etone, et, yn(cenergy(&half) < 1e-12));
    assert!(cenergy(&half) < 1e-12 * et && close(et, etone, 1e-6 * et));
    let mut rng = Rng(2026); let h = 0.001 * 3f64.sqrt(); let mut out = vec![];
    for (kind, a, scale) in [("rect", 256usize, 1.0), ("sine", 128, 0.5)] {
        let g = window(kind, L);
        let c: Vec<Vec<C>> = analyse(&f, &g, a).iter().map(|r| r.iter().map(|z| { let re = h * rng.next(); let im = h * rng.next(); z.add(C { re, im }) }).collect()).collect();
        let gs: Vec<f64> = g.iter().map(|v| scale * v).collect();
        let e = err_energy(&synth(&c, &gs, a, n), &f); out.push(e);
        println!("  noise on every {} coefficient: rebuild error energy {:.6}", kind, e);
    }
    let q = out[1] / out[0]; let ex = n as f64 * 2.0 * 0.001f64.powi(2);
    println!("frame / basis error energy {:.4}; expected {:.3} and {:.3}, ratio 0.5", q, ex, ex / 2.0);
    assert!(close(out[0], ex, 0.0013) && close(q, 0.5, 0.008)); // about 4 standard errors each
    println!("ALL CHECKS PASS");
}
