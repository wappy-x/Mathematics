// The Hilbert transform and the analytic signal -- the check behind the card.
// Rust std only.  Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt.
// H has multiplier -i sgn(xi) and kernel 1/(pi t); the analytic signal is z = s + i Hs.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}

fn midpoint<F: Fn(f64) -> f64>(g: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    h * (0..n).map(|k| g(a + (k as f64 + 0.5) * h)).fold(0.0, |s, v| s + v)
}

const FC: f64 = 1000e3;
const FM: f64 = 1e3;
const FS: f64 = 8e6;

fn fft(a: &[C], sgn: f64) -> Vec<C> { // mixed-radix Cooley-Tukey, any n with factors 2 and 5
    let n = a.len();
    if n == 1 { return a.to_vec(); }
    let p = if n % 2 == 0 { 2 } else { 5 };
    let m = n / p;
    let subs: Vec<Vec<C>> = (0..p).map(|r| fft(&a.iter().skip(r).step_by(p).cloned().collect::<Vec<C>>(), sgn)).collect();
    (0..n).map(|k| {
        let mut acc = C { re: 0.0, im: 0.0 };
        for r in 0..p {
            let ang = sgn * 2.0 * PI * r as f64 * k as f64 / n as f64;
            acc = acc.add(subs[r][k % m].mul(C { re: ang.cos(), im: ang.sin() }));
        }
        acc
    }).collect()
}

fn hilbert(s: &[f64], flip: f64) -> Vec<f64> { // multiply bin k by -i sgn(k), zero at 0 and n/2
    let n = s.len();
    let mut x = fft(&s.iter().map(|&v| C { re: v, im: 0.0 }).collect::<Vec<C>>(), -1.0);
    for k in 0..n {
        let w = if k == 0 || 2 * k == n { C { re: 0.0, im: 0.0 } }
                else if 2 * k < n { C { re: 0.0, im: -flip } } else { C { re: 0.0, im: flip } };
        x[k] = x[k].mul(w);
    }
    fft(&x, 1.0).iter().map(|v| v.re / n as f64).collect()
}

fn am(m: f64, fc: f64, fm: f64, n: usize) -> (Vec<f64>, Vec<f64>, Vec<f64>) {
    let t: Vec<f64> = (0..n).map(|k| k as f64 / FS).collect();
    let a: Vec<f64> = t.iter().map(|&x| 1.0 + m * (2.0 * PI * fm * x).cos()).collect();
    let s = a.iter().zip(&t).map(|(&a, &x)| a * (2.0 * PI * fc * x).cos()).collect();
    (t, a, s)
}

fn envelope(s: &[f64], hs: &[f64]) -> Vec<f64> {
    s.iter().zip(hs).map(|(a, b)| (a * a + b * b).sqrt()).collect()
}

fn inst_freq(s: &[f64], hs: &[f64]) -> Vec<f64> { // phase step per sample, in kHz
    (0..s.len() - 1).map(|k| {
        let w = C { re: s[k + 1], im: hs[k + 1] }.mul(C { re: s[k], im: -hs[k] });
        w.im.atan2(w.re) / (2.0 * PI) * FS / 1e3
    }).collect()
}

fn gap(e: &[f64], a: &[f64], lo: usize, hi: usize) -> f64 {
    (lo..hi).map(|k| (e[k] - a[k]).abs()).fold(0.0, f64::max)
}

fn row(v: &[f64]) -> String {
    v.iter().map(|x| format!("{:.3}", x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    // Road to the multiplier: (2/pi) times the integral of sin(x)/x from 0 to X tends to 1.
    for x in [10usize, 100, 1000] {
        let v = 2.0 / PI * midpoint(|u| u.sin() / u, 0.0, x as f64, 100 * x);
        let b = 4.0 / (PI * x as f64);
        println!("quarter turn: (2/pi) Si({}) = {:.6}, off by {:.6}, bound 4/(pi X) = {:.6}", x, v, (v - 1.0).abs(), b);
        assert!((v - 1.0).abs() <= b);
    }
    // Kernel against multiplier, on a click f(t) = 1/(1 + t^2), t in ms, xi in kHz.
    let f = |t: f64| 1.0 / (1.0 + t * t);
    let fh = midpoint(|t| f(t) * (PI * t).cos(), -200.0, 200.0, 40000);
    println!("click: fhat(0.5 kHz) by its integral {:.6} ms, closed form pi e^(-pi) {:.6} ms", fh, PI * (-PI).exp());
    assert!((fh - PI * (-PI).exp()).abs() < 1e-4);
    for t in [0.5, 1.0, 2.0] {
        let exact = t / (1.0 + t * t);
        let ker: Vec<f64> = [50usize, 100].iter().map(|&r| midpoint(|u| (f(t - u) - f(t + u)) / u, 0.0, r as f64, 200 * r) / PI).collect();
        let mul = midpoint(|x| 2.0 * PI * (-2.0 * PI * x).exp() * (2.0 * PI * x * t).sin(), 0.0, 6.0, 60000);
        println!("click Hf({:.1} ms): t/(1+t^2) {:.6}; kernel R=50 {:.6}, R=100 {:.6}; multiplier {:.6}", t, exact, ker[0], ker[1], mul);
        assert!((ker[1] - exact).abs() < 1e-6 && (mul - exact).abs() < 1e-7);
    }
    // The AM signal: s = A(t) cos(2 pi FC t), A = 1 + m cos(2 pi FM t), sampled 1 ms at 8 MHz.
    let (t, a, s) = am(0.5, FC, FM, 8000);
    let x = fft(&s.iter().map(|&v| C { re: v, im: 0.0 }).collect::<Vec<C>>(), -1.0);
    for k in [999usize, 1000, 1001, 1500] {
        let mut d = C { re: 0.0, im: 0.0 };
        for j in 0..8000 {
            let ang = 2.0 * PI * j as f64 * k as f64 / 8000.0;
            d = d.add(C { re: s[j], im: 0.0 }.mul(C { re: ang.cos(), im: -ang.sin() }));
        }
        println!("bin {} ({} kHz): |FFT| {:.6}, |direct DFT| {:.6}", k, k, x[k].abs(), d.abs());
        assert!(C { re: x[k].re - d.re, im: x[k].im - d.im }.abs() < 1e-6);
    }
    let hs = hilbert(&s, 1.0);
    let env = envelope(&s, &hs);
    let gap_h = (0..8000).map(|k| (hs[k] - a[k] * (2.0 * PI * FC * t[k]).sin()).abs()).fold(0.0, f64::max);
    let gap_e = gap(&env, &a, 0, 8000);
    println!("largest gap, Hs against A sin: {:.9} V; envelope against A: {:.9} V", gap_h, gap_e);
    assert!(gap_h < 1e-9 && gap_e < 1e-9);
    let hhs = hilbert(&hs, 1.0); // H twice is minus the signal; energy is kept
    let (ms_s, ms_h) = (s.iter().fold(0.0, |q, v| q + v * v) / 8000.0, hs.iter().fold(0.0, |q, v| q + v * v) / 8000.0);
    let gap_hh = (0..8000).map(|k| (hhs[k] + s[k]).abs()).fold(0.0, f64::max);
    println!("mean square: s {:.6} V^2, Hs {:.6} V^2, by hand (1 + 2 x 0.25^2)/2 = 0.562500; H(Hs) + s largest {:.9} V", ms_s, ms_h, gap_hh);
    assert!((ms_s - 0.5625).abs() < 1e-12 && (ms_h - 0.5625).abs() < 1e-12 && gap_hh < 1e-9);
    let n0 = 1601;
    let ph = hs[n0].atan2(s[n0]) * 180.0 / PI;
    println!("worked instant t = {:.3} us: s {:.6} V, Hs {:.6} V, envelope {:.6} V, A {:.6} V, phase {:.3} deg",
             t[n0] * 1e6, s[n0], hs[n0], env[n0], a[n0], ph);
    println!("by hand: message angle {:.3} deg, cos {:.6}, carrier angle {:.3} deg",
             360.0 * FM * t[n0], (2.0 * PI * FM * t[n0]).cos(), (360.0 * FC * t[n0]) % 360.0);
    assert!((env[n0] - a[n0]).abs() < 1e-9 && (ph - 45.0).abs() < 1e-6);
    let fr = inst_freq(&s, &hs);
    let (lo, hi) = (fr.iter().cloned().fold(f64::MAX, f64::min), fr.iter().cloned().fold(f64::MIN, f64::max));
    println!("instantaneous frequency: {:.3} kHz to {:.3} kHz", lo, hi);
    assert!((lo - 1000.0).abs() < 1e-6 && (hi - 1000.0).abs() < 1e-6);
    let pick = |v: &[f64], sign: f64| -> Vec<f64> {
        (0..20).map(|k| { let y = sign * v[401 * k]; if y.abs() < 5e-7 { 0.0 } else { y } }).collect()
    };
    println!("chart t us: [{}]", row(&pick(&t.iter().map(|x| x * 1e6).collect::<Vec<f64>>(), 1.0)));
    println!("chart s V: [{}]", row(&pick(&s, 1.0)));
    println!("chart envelope V: [{}]", row(&pick(&env, 1.0)));
    println!("chart -envelope V: [{}]", row(&pick(&env, -1.0)));

    // What breaks.
    println!("mistake, s + Hs at the worked instant: {:.6} V; |s| one sample later: {:.6} V", (s[n0] + hs[n0]).abs(), s[n0 + 1].abs());
    let flipped = inst_freq(&s, &hilbert(&s, -1.0)).iter().cloned().fold(f64::MAX, f64::min);
    println!("mistake, sign flipped: frequency {:.3} kHz", flipped);
    let (_, a2, s2) = am(0.5, FC, FM, 10000); // 1.25 ms: 1.25 tone cycles, the loop has a seam
    let e2 = envelope(&s2, &hilbert(&s2, 1.0));
    let (g_all, g_mid) = (gap(&e2, &a2, 0, 10000), gap(&e2, &a2, 2000, 8001));
    println!("record 1.25 ms: largest envelope gap {:.6} V; between 0.25 and 1 ms {:.6} V", g_all, g_mid);
    assert!(g_all > 0.01 && g_mid < g_all / 5.0);
    let (_, a3, s3) = am(1.5, FC, FM, 8000);
    let e3 = envelope(&s3, &hilbert(&s3, 1.0));
    println!("depth 1.5 at t = 500 us: message {:.6} V, envelope {:.6} V", a3[4000], e3[4000]);
    assert!((e3[4000] - a3[4000].abs()).abs() < 1e-9);
    let (_, a4, s4) = am(0.5, 1e3, 2e3, 8000); // carrier below the tone: Bedrosian fails
    let g4 = gap(&envelope(&s4, &hilbert(&s4, 1.0)), &a4, 0, 8000);
    println!("1 kHz carrier, 2 kHz tone: largest envelope gap {:.6} V", g4);
    assert!(g4 > 0.1);

    // The 1 ms gate (the shutter): Hf = (1/pi) ln|(t + 1/2)/(t - 1/2)|, t in ms; tail T/(pi t).
    let hg = |x: f64| ((x + 0.5) / (x - 0.5)).abs().ln() / PI;
    let big_f = |x: f64| ((x + 0.5) * (x + 0.5).ln() - (x - 0.5) * (x - 0.5).ln()) / PI;
    for x in [1.0, 10.0, 100.0] {
        println!("gate Hf({} ms) = {:.6}, tail 1/(pi t) = {:.6}", x, hg(x), 1.0 / (PI * x));
    }
    let num = midpoint(hg, 1.0, 10.0, 90000);
    println!("area of |Hf| from 1 to 10 ms: antiderivative {:.6} ms, integral {:.6} ms", big_f(10.0) - big_f(1.0), num);
    assert!((num - (big_f(10.0) - big_f(1.0))).abs() < 1e-8);
    for r in [100.0, 1000.0, 10000.0] {
        println!("area of |Hf| from 1 to {} ms: {:.6} ms", r, big_f(r) - big_f(1.0));
    }
    println!("growth per decade, (1/pi) ln 10 = {:.6} ms", 10f64.ln() / PI);
    println!("ALL CHECKS PASS");
}
