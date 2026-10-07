// The convolution theorem -- the same check as the Python, in Rust.  No crates.
// A box blur b, 1 mm wide, is smeared with itself.  Road one: the convolution
// integral as a sum.  Road two: Fourier transforms by Simpson's rule.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for C { type Output = C; fn div(self, o: C) -> C {
    let d = o.re * o.re + o.im * o.im;
    c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d) } }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
const H: f64 = 1.0 / 400.0;                    // grid step, in mm

fn bx(t: f64) -> f64 { if -0.5 <= t && t < 0.5 { 1.0 } else { 0.0 } }
fn shutter(t: f64) -> f64 { if 0.0 <= t && t < 1.0 { 1.0 } else { 0.0 } }
fn conv(f: &dyn Fn(f64) -> f64, g: &dyn Fn(f64) -> f64, t: f64, lo: f64, hi: f64) -> f64 {
    let n = ((hi - lo) / H).round() as usize;  // midpoint sum of f(s) g(t - s) ds
    (0..n).map(|k| f(lo + (k as f64 + 0.5) * H) * g(t - lo - (k as f64 + 0.5) * H)).sum::<f64>() * H
}
fn fourier(vals: &[f64], lo: f64, w: f64) -> C {  // Simpson's rule for v(t) e^(-iwt) dt
    let (mut tot, last) = (c(0.0, 0.0), vals.len() - 1);
    for (k, &v) in vals.iter().enumerate() {
        let wt = if k == 0 || k == last { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 };
        let x = w * (lo + k as f64 * H);
        tot = tot + c(wt * v, 0.0) * c(x.cos(), -x.sin());
    }
    tot * c(H / 3.0, 0.0)
}
fn bhat(w: f64) -> f64 { if w == 0.0 { 1.0 } else { (w / 2.0).sin() / (w / 2.0) } }
fn phat(w: f64) -> C { (c(1.0, 0.0) - c(w.cos(), -w.sin())) / c(0.0, w) }
fn show(z: C) -> String {
    let (re, im) = ((z.re * 1e6).round() / 1e6 + 0.0, (z.im * 1e6).round() / 1e6);
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, z.im.abs())
}
fn row(xs: &[f64], d: usize) -> String {
    xs.iter().map(|&x| format!("{:.*}", d, (x * 10f64.powi(d as i32)).round() / 10f64.powi(d as i32) + 0.0)).collect::<Vec<_>>().join(", ")
}
fn sci(x: f64) -> String { let e = x.log10().floor(); format!("{:.1}e{}", x / 10f64.powf(e), e as i32) }
fn dconv(a: &[i32], b: &[i32]) -> Vec<i32> {
    (0..a.len() + b.len() - 1).map(|k| (0..a.len()).filter(|&j| k >= j && k - j < b.len()).map(|j| a[j] * b[k - j]).sum()).collect()
}
fn main() {
    let nodes: Vec<f64> = (0..801).map(|k| -1.0 + k as f64 * H).collect();
    let tent: Vec<f64> = nodes.iter().map(|&t| conv(&bx, &bx, t, -0.5, 0.5)).collect();
    let q = [0.0, 0.25, 0.5, 0.75, 1.0];
    println!("b * b by the sliding sum at t = 0, 0.25, 0.5, 0.75, 1 mm: {}", row(&q.map(|t| conv(&bx, &bx, t, -0.5, 0.5)), 6));
    println!("the tent 1 - |t| at the same points: {}", row(&q.map(|t: f64| 1.0 - t.abs()), 6));
    let ch: Vec<f64> = (-6..7).map(|k| conv(&bx, &bx, k as f64 / 4.0, -0.5, 0.5)).collect();
    println!("chart, b * b at t = -1.5 to 1.5 in steps of 0.25: {}", row(&ch, 2));
    let (ones, bnum, tnum) = (vec![1.0; 401], fourier(&[1.0; 401], -0.5, PI).re, fourier(&tent, -1.0, PI).re);
    println!("w = pi (stripes 2 mm apart): b-hat by Simpson {:.6}; by hand sin(w/2)/(w/2) {:.6}", bnum, bhat(PI));
    println!("w = pi: transform of b * b by Simpson {:.6}; b-hat squared {:.6}", tnum, bhat(PI).powi(2));
    let ws: Vec<f64> = (0..17).map(|w| w as f64).collect();
    let gap = ws.iter().map(|&w| abs(fourier(&tent, -1.0, w) - c(bhat(w).powi(2), 0.0))).fold(0.0, f64::max);
    println!("largest gap, transform of b * b against b-hat squared, w = 0 to 16: {}", sci(gap));
    println!("chart, b-hat at w = 0 to 16: {}", row(&ws.iter().map(|&w| fourier(&ones, -0.5, w).re).collect::<Vec<_>>(), 2));
    println!("chart, transform of b * b at w = 0 to 16: {}", row(&ws.iter().map(|&w| fourier(&tent, -1.0, w).re).collect::<Vec<_>>(), 2));
    let ptri: Vec<f64> = (0..801).map(|k| conv(&shutter, &shutter, k as f64 * H, 0.0, 1.0)).collect();
    let pgap = [PI, 2.0].iter().map(|&w| abs(fourier(&ptri, 0.0, w) - phat(w) * phat(w))).fold(0.0, f64::max);
    println!("motion blur p on 0 to 1 mm: p-hat(pi) = {}; p-hat(pi)^2 = {}", show(phat(PI)), show(phat(PI) * phat(PI)));
    println!("transform of p * p by Simpson: at pi {}; at 2 {}", show(fourier(&ptri, 0.0, PI)), show(fourier(&ptri, 0.0, 2.0)));
    println!("p-hat(2)^2 by hand: {}; largest gap {}", show(phat(2.0) * phat(2.0)), sci(pgap));
    println!("mistake, pointwise product b x b = b: transform at pi {:.6}, not {:.6}", bnum, tnum);
    let corr = fourier(&nodes.iter().map(|&t| conv(&shutter, &|u| shutter(-u), t, 0.0, 1.0)).collect::<Vec<_>>(), -1.0, PI);
    println!("mistake, no flip, p(s) p(s - t): transform at pi {}; |p-hat(pi)|^2 = {:.6}", show(corr), abs(phat(PI)).powi(2));
    let big: Vec<f64> = [10.0, 100.0, 1000.0].iter().map(|&l| conv(&|_| 1.0, &|_| 1.0, 0.0, -l, l)).collect();
    println!("break, f = g = 1 (not integrable): sum over |s| < L at L = 10, 100, 1000: {}", row(&big, 1));
    println!("3-pixel box blur applied twice, weights over 9: {:?}", dconv(&[1, 1, 1], &[1, 1, 1]));
    let dice: Vec<i32> = (2..13).map(|n| (1..7).flat_map(|x| (1..7).map(move |y| x + y)).filter(|&s| s == n).count() as i32).collect();
    println!("two dice, ways to make 2 to 12: {:?}; by listing all 36 rolls: {:?}", dconv(&[1; 6], &[1; 6]), dice);
    assert!(tent.iter().zip(&nodes).map(|(v, t)| (v - (1.0 - t.abs())).abs()).fold(0.0, f64::max) < 1e-12); // the tent
    assert!(gap < 1e-6);                                                  // transform of b * b = b-hat^2
    assert!(pgap < 1e-6);                                                 // off-centre, complex: p-hat^2
    assert!(abs(corr - c(abs(phat(PI)).powi(2), 0.0)) < 1e-6);            // no flip: |p-hat|^2, phase lost
    println!("ALL CHECKS PASS");
}
