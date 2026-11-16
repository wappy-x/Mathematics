// The uncertainty principle -- the same check as w20_uncertainty_principle_check.py, in Rust.
// Standard library only, no crates.  A complex number is a small struct; every
// transform and integral is Simpson's rule written out.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn norm2(self) -> f64 { self.re * self.re + self.im * self.im }
}
fn real(x: f64) -> C { C { re: x, im: 0.0 } }

fn wt(i: usize, n: usize) -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    (0..=n).map(|i| wt(i, n) * f(a + i as f64 * h)).sum::<f64>() * h / 3.0
}

// f^(xi) = integral f(t) e^(-2 pi i xi t) dt
fn transform(f: &dyn Fn(f64) -> C, xi: f64, a: f64, b: f64, n: usize) -> C {
    let h = (b - a) / n as f64;
    let (mut re, mut im) = (0.0, 0.0);
    for i in 0..=n {
        let t = a + i as f64 * h;
        let v = f(t).mul(C { re: (2.0 * PI * xi * t).cos(), im: -(2.0 * PI * xi * t).sin() });
        re += wt(i, n) * v.re;
        im += wt(i, n) * v.im;
    }
    C { re: re * h / 3.0, im: im * h / 3.0 }
}

// integrals of |f^|^2 times 1, xi, xi^2 over [xa, xb]
fn moments(f: &dyn Fn(f64) -> C, ta: f64, tb: f64, nt: usize, xa: f64, xb: f64, nx: usize) -> (f64, f64, f64) {
    let h = (xb - xa) / nx as f64;
    let (mut e, mut m1, mut m2) = (0.0, 0.0, 0.0);
    for k in 0..=nx {
        let x = xa + k as f64 * h;
        let q = wt(k, nx) * h / 3.0 * transform(f, x, ta, tb, nt).norm2();
        e += q; m1 += x * q; m2 += x * x * q;
    }
    (e, m1, m2)
}

fn spread_time(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let e = simpson(&|t| f(t).powi(2), a, b, n);
    let m = simpson(&|t| t * f(t).powi(2), a, b, n) / e;
    (simpson(&|t| (t - m).powi(2) * f(t).powi(2), a, b, n) / e).sqrt()
}

fn spread_freq(f: &dyn Fn(f64) -> C, ta: f64, tb: f64, nt: usize, xa: f64, xb: f64, nx: usize) -> (f64, f64, f64) {
    let (e, m1, m2) = moments(f, ta, tb, nt, xa, xb, nx);
    (e, m1 / e, (m2 / e - (m1 / e).powi(2)).sqrt())
}

fn main() {
    let mut out: Vec<String> = Vec::new();
    let mut show = |label: &str, x: f64| out.push(format!("{:<46}{:>14.6}", label, x));

    let dt = 0.010;
    let hit = move |t: f64| (-t * t / (4.0 * dt * dt)).exp();
    let floor = 1.0 / (4.0 * PI * dt);
    let e_t = simpson(&|t| hit(t).powi(2), -0.1, 0.1, 2000);
    let m_t = simpson(&|t| t * hit(t).powi(2), -0.1, 0.1, 2000) / e_t;
    let dt_num = (simpson(&|t| (t - m_t).powi(2) * hit(t).powi(2), -0.1, 0.1, 2000) / e_t).sqrt();
    let hitc = move |t: f64| real(hit(t));
    let (e_x, _, dx_400) = spread_freq(&hitc, -0.1, 0.1, 2000, -80.0, 80.0, 400);
    let dx_200 = spread_freq(&hitc, -0.1, 0.1, 2000, -80.0, 80.0, 200).2;
    let d = 1e-7;
    let slope = move |t: f64| (hit(t + d) - hit(t - d)) / (2.0 * d);
    let dx_slope = (simpson(&|t| slope(t).powi(2), -0.1, 0.1, 2000) / e_t).sqrt() / (2.0 * PI);
    let tone = move |t: f64| real(hit(t)).mul(C { re: (2.0 * PI * 100.0 * t).cos(), im: (2.0 * PI * 100.0 * t).sin() });
    let (_, m_tone, dx_tone) = spread_freq(&tone, -0.1, 0.1, 2000, 20.0, 180.0, 400);
    let real_hit = move |t: f64| real(hit(t) * (2.0 * PI * 100.0 * t).cos());
    let dx_real = spread_freq(&real_hit, -0.1, 0.1, 2000, -180.0, 180.0, 900).2;
    // the proof's two lines, on the hit: ||f||^2 = -2 Re int t f f' dt, and Cauchy-Schwarz
    let pairing = -2.0 * simpson(&|t| t * hit(t) * slope(t), -0.1, 0.1, 2000);
    let cs = 2.0 * simpson(&|t| (t * hit(t)).powi(2), -0.1, 0.1, 2000).sqrt() * simpson(&|t| slope(t).powi(2), -0.1, 0.1, 2000).sqrt();

    show("closed form: floor 1/(4 pi dt), Hz", floor);
    show("dt from |f|^2 sums, ms", 1000.0 * dt_num);
    show("energy in time (closed form sqrt(2pi) dt)", e_t);
    show("energy in frequency, transform by sums", e_x);
    show("dxi, transform by sums, 400 steps, Hz", dx_400);
    show("dxi, transform by sums, 200 steps, Hz", dx_200);
    show("dxi from the slope, ||f'||/(2pi||f||), Hz", dx_slope);
    show("product dt dxi", dt_num * dx_400);
    show("  1/(4 pi)", 1.0 / (4.0 * PI));
    show("proof: ||f||^2", e_t);
    show("proof: -2 Re int t f f' dt", pairing);
    show("proof: 2 ||t f|| ||f'||", cs);
    show("100 Hz complex hit: mean frequency, Hz", m_tone);
    show("100 Hz complex hit: dxi, Hz", dx_tone);
    show("5 Hz needs dt at least, ms", 1000.0 / (4.0 * PI * 5.0));
    show("5 Hz as a fraction of the floor", 5.0 / floor);
    let fw = 2.0 * (2.0 * 2f64.ln()).sqrt();
    show("half-maximum width / standard deviation", fw);
    show("half-maximum width in time, ms", 1000.0 * fw * dt);
    show("half-maximum width in frequency, Hz", fw * floor);
    show("half-maximum product, 2 ln2 / pi", fw * dt * fw * floor);
    // other shapes, all scaled to dt = 10 ms: closed form against the transform by sums
    let l = dt / (1.0 / 12.0 - 5.0 / (8.0 * PI * PI)).sqrt();
    let hann = move |t: f64| real(if t.abs() < l / 2.0 { (PI * t / l).cos().powi(2) } else { 0.0 });
    let dxh = spread_freq(&hann, -l / 2.0, l / 2.0, 2000, -120.0, 120.0, 400).2;
    let dxh2 = spread_freq(&hann, -l / 2.0, l / 2.0, 2000, -240.0, 240.0, 800).2;
    let dth = spread_time(&|t| hann(t).re, -l / 2.0, l / 2.0, 2000);
    show("raised cosine: length L, ms", 1000.0 * l);
    show("raised cosine: dt by sums, ms", 1000.0 * dth);
    show("raised cosine: dxi closed 1/(sqrt3 L), Hz", 1.0 / (3f64.sqrt() * l));
    show("raised cosine: dxi by sums to 120 Hz", dxh);
    show("raised cosine: dxi by sums to 240 Hz", dxh2);
    show("raised cosine: product / floor", dt / (3f64.sqrt() * l) * 4.0 * PI);
    let tau = dt * 2f64.sqrt();
    let dec = move |t: f64| real((-t.abs() / tau).exp());
    let (a, x) = (2.0 * PI * tau, 400.0);
    let tail = 4.0 * tau * tau / a.powi(3) * (PI / 2.0 - (a * x).atan() + a * x / (1.0 + a * a * x * x));
    let m2 = moments(&dec, -40.0 * tau, 40.0 * tau, 8000, -x, x, 800).2;
    let dxd = ((m2 + tail) / tau).sqrt();
    let dtd = spread_time(&|t| dec(t).re, -40.0 * tau, 40.0 * tau, 8000);
    show("two-sided decay: tau = sqrt2 dt, ms", 1000.0 * tau);
    show("two-sided decay: dt by sums, ms", 1000.0 * dtd);
    show("two-sided decay: dxi closed 1/(2 pi tau), Hz", 1.0 / (2.0 * PI * tau));
    show("two-sided decay: dxi by sums to 400 Hz", (m2 / tau).sqrt());
    show("  plus the closed-form tail beyond 400 Hz", dxd);
    show("two-sided decay: product / floor", dt / (2.0 * PI * tau) * 4.0 * PI);
    // the shutter: open 1 ms; its frequency spread has no finite value
    let tt = 0.001;
    show("shutter: dt = T/sqrt12, ms", 1000.0 * tt / 12f64.sqrt());
    for xc in [1000.0f64, 10000.0, 100000.0] {
        let closed = ((xc - (2.0 * PI * tt * xc).sin() / (2.0 * PI * tt)) / (PI * PI * tt)).sqrt();
        let summed = (simpson(&|v| (PI * tt * v).sin().powi(2) / (PI * PI), -xc, xc, (xc / 5.0) as usize) / tt).sqrt();
        show(&format!("shutter: dxi cut at {:>6.0} Hz, closed", xc), closed);
        show(&format!("shutter: dxi cut at {:>6.0} Hz, sums", xc), summed);
        let sinc2 = |v: f64| if v == 0.0 { tt * tt } else { ((PI * tt * v).sin() / (PI * v)).powi(2) };
        show(&format!("shutter: energy share beyond {:>6.0} Hz", xc), 1.0 - simpson(&sinc2, -xc, xc, (xc / 5.0) as usize) / tt);
    }
    show("mistake: rad/s floor 1/(2 dt) read as Hz", 1.0 / (2.0 * dt));
    show("  over the true floor", 1.0 / (2.0 * dt) / floor);
    show("mistake: half-max width 23.55 ms in sd bound", 1.0 / (4.0 * PI * fw * dt));
    show("mistake: real 100 Hz hit, spread about 0", dx_real);
    show("try: dt = 20 ms, floor Hz", 1.0 / (4.0 * PI * 0.020));
    show("try: dt = 2 ms, floor Hz", 1.0 / (4.0 * PI * 0.002));
    let pts: Vec<i32> = (-24..=24).step_by(4).collect();
    let row = |g: &dyn Fn(f64) -> f64| pts.iter().map(|&p| format!("{:>5.3}", g(p as f64))).collect::<Vec<_>>().join(" ");
    let line1 = format!("chart, frequency (Hz)  {}", pts.iter().map(|p| format!("{:>5}", p)).collect::<Vec<_>>().join(" "));
    let line2 = format!("chart, 10 ms hit       {}", row(&|v| (-v * v / (2.0 * floor * floor)).exp()));
    let line3 = format!("chart, 5 Hz wish       {}", row(&|v| (-v * v / 50.0).exp()));
    out.push(line1); out.push(line2); out.push(line3);
    println!("{}", out.join("\n"));

    assert!((dx_400 - floor).abs() < 1e-6 && (dx_200 - floor).abs() < 1e-6);
    assert!((dx_slope - floor).abs() < 1e-4);
    assert!((dt_num - dt).abs() < 1e-9 && (e_t - (2.0 * PI).sqrt() * dt).abs() < 1e-12);
    assert!((e_x - e_t).abs() < 1e-9);
    assert!((pairing - e_t).abs() < 1e-8 && cs >= pairing - 1e-12);
    assert!((m_tone - 100.0).abs() < 1e-6 && (dx_tone - floor).abs() < 1e-6);
    assert!((dxh2 - 1.0 / (3f64.sqrt() * l)).abs() < 1e-4 && (dth - dt).abs() < 1e-9);
    assert!((dxd - 1.0 / (2.0 * PI * tau)).abs() < 1e-4 && (dtd - dt).abs() < 1e-6);
    assert!(dth * dxh2 > 1.0 / (4.0 * PI) && dtd * dxd > 1.0 / (4.0 * PI));
    assert!((dx_real - (100f64.powi(2) + floor * floor).sqrt()).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
