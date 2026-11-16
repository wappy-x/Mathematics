// Schwartz space and tempered distributions -- the same check as the Python
// file, in Rust.  Standard library only, no crates.  Units: t in ms, xi in kHz.
// A complex number is a small struct; every transform and pairing is computed.
use std::f64::consts::{E, PI};
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C { type Output = C; fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } } }
impl Div for C {
    type Output = C;
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d } }
}
fn r(x: f64) -> C { C { re: x, im: 0.0 } }
fn im(x: f64) -> C { C { re: 0.0, im: x } }
fn abs(z: C) -> f64 { (z.re * z.re + z.im * z.im).sqrt() }
fn arrow(x: f64) -> C { C { re: x.cos(), im: x.sin() } } // e^(ix), written out
fn snap(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }
fn c(z: C) -> String { format!("{:.6} {} {:.6}i", snap(z.re), if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }
fn sci(x: f64) -> String { // Python's {:.1e}: mantissa, e, sign, two-digit exponent
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    let mut tot = f(a) + f(b);
    for k in 1..n { tot += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * w); }
    tot * w / 3.0
}
fn simpson_c<F: Fn(f64) -> C>(f: F, a: f64, b: f64, n: usize) -> C {
    r(simpson(|t| f(t).re, a, b, n)) + im(simpson(|t| f(t).im, a, b, n))
}
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
const XI0: f64 = 0.25; // the probe's centre, 250 Hz
const R: f64 = 6.0; // cut-off 6 kHz or 6 ms
fn phi(x: f64) -> f64 { (-PI * (x - XI0).powi(2)).exp() } // probe in frequency
fn g0(t: f64) -> f64 { (-PI * t * t).exp() } // the bell, its own transform

fn main() {
    let tail = (-PI * (R - XI0).powi(2)).exp();
    println!("probe phi(xi) = exp(-pi (xi - 0.25)^2), cut-off {:.0}, tail below {}", R, sci(tail));

    // 1. Schwartz space: weighted slopes of the bell
    let (mut p10, mut p20, mut p01) = (f64::MIN, f64::MIN, f64::MIN);
    for k in 0..=500000 {
        let t = k as f64 / 100000.0;
        p10 = p10.max(t * g0(t)); p20 = p20.max(t * t * g0(t)); p01 = p01.max(2.0 * PI * t * g0(t));
    }
    let (ex10, ex20) = ((-0.5f64).exp() / (2.0 * PI).sqrt(), 1.0 / (PI * E));
    println!("bell weighted slopes: p00 1.000000, p10 {:.6} (exact {:.6}), p20 {:.6} (exact {:.6}), p01 {:.6} (exact {:.6})",
        p10, ex10, p20, ex20, p01, 2.0 * PI * ex10);
    assert!((p10 - ex10).abs() < 1e-9 && (p20 - ex20).abs() < 1e-9 && (p01 - 2.0 * PI * ex10).abs() < 1e-8);
    let bell_self = simpson(|t| g0(t) * (2.0 * PI * 0.5 * t).cos(), -R, R, 4000);
    println!("bell transform at 0.5 kHz: Simpson {:.6}, bell itself {:.6}", bell_self, g0(0.5));
    assert!((bell_self - g0(0.5)).abs() < 1e-12);
    let lor: Vec<String> = [10.0f64, 100.0, 1000.0].iter().map(|&t| format!("t={}: {:.6}", t, t.powi(3) / (1.0 + t * t))).collect();
    println!("1/(1+t^2), weight t^3: {}", lor.join(", "));
    let bump = |t: f64| if t.abs() < 1.0 { (-1.0 / (1.0 - t * t)).exp() } else { 0.0 };
    for xi in [2.0f64, 3.0] {
        let b1 = simpson(|t| bump(t) * (2.0 * PI * xi * t).cos(), -1.0, 1.0, 4000);
        let b2 = simpson(|t| bump(t) * (2.0 * PI * xi * t).cos(), -1.0, 1.0, 8000);
        println!("bump zero outside 1 ms, transform at {:.0} kHz: {:.6} ms (n=4000), {:.6} ms (n=8000)", xi, b1, b2);
        assert!((b1 - b2).abs() < 1e-9 && b1.abs() > 1e-4);
    }

    // 2. delta and constant
    for (w, lab) in [(1.0f64, "1.0"), (0.1, "0.1"), (0.01, "0.01")] {
        let s = simpson(|t| (2.0 * PI * XI0 * t).cos() / w, -w / 2.0, w / 2.0, 200);
        println!("flash {} ms at 250 Hz: closed form {:.6}, Simpson {:.6}, delta gives 1", lab, sinc(w * XI0), s);
        assert!((s - sinc(w * XI0)).abs() < 1e-9);
    }
    let target = phi(0.0);
    println!("lamp on for good, paired with probe: delta(phi) = phi(0) = {:.6}", target);
    for l in [1usize, 2, 4] {
        let lf = l as f64;
        let fr = simpson(|x| lf * sinc(lf * x) * phi(x), -R, R, 6000 * l);
        let tm = simpson(|t| g0(t) * (2.0 * PI * XI0 * t).cos(), -lf / 2.0, lf / 2.0, 2000);
        let gap = 2.0 * (-PI * lf * lf / 4.0).exp() / (PI * lf);
        println!("lamp {} ms: frequency side {:.6}, time side {:.6}, gap {} <= bound {}", l, fr, tm, sci((target - tm).abs()), sci(gap));
        assert!((fr - tm).abs() < 1e-8 && (target - tm).abs() <= gap);
    }
    let pw: Vec<String> = [5.0f64, 15.0, 25.0].iter().map(|&l| format!("L={} ms: {:.6}", l, l * sinc(l * 0.1))).collect();
    println!("lamp transform at 100 Hz, pointwise: {}", pw.join(", "));

    // 3. the sign function
    let time_side = im(-2.0 * simpson(|t| g0(t) * (2.0 * PI * XI0 * t).sin(), 0.0, R, 6000));
    let odd = |x: f64| if x != 0.0 { (phi(x) - phi(-x)) / x } else { 4.0 * PI * XI0 * phi(0.0) };
    let pv = r(simpson(odd, 0.0, R, 6000)) / im(PI);
    let x = PI.sqrt() * XI0;
    let (mut term, mut dawson, mut n) = (x, 0.0f64, 0);
    while term.abs() > 1e-17 { dawson += term; n += 1; term *= -2.0 * x * x / (2 * n + 1) as f64; }
    let series = im(-2.0 * dawson / PI.sqrt());
    println!("sgn-hat on probe: time side {}, p.v. side {}, Dawson series {}", c(time_side), c(pv), c(series));
    assert!(abs(time_side - pv) < 1e-10 && abs(pv - series) < 1e-12);
    let mut last = 1.0f64;
    let mut point = r(0.0);
    for (eps, lab) in [(1.0f64, "1.0"), (0.1, "0.1"), (0.01, "0.01"), (0.001, "0.001")] {
        let k = |x: f64| (phi(x) - phi(-x)) * x / (eps * eps + 4.0 * PI * PI * x * x);
        let pair = im(-4.0 * PI * simpson(k, 0.0, R, 400000));
        point = im(-4.0 * PI * XI0 / (eps * eps + 4.0 * PI * PI * XI0 * XI0));
        println!("damped sign eps={}/ms: at 250 Hz {} ms, on probe {}, gap {:.6}", lab, c(point), c(pair), abs(pair - pv));
        assert!(abs(pair - pv) < last / 5.0); last = abs(pair - pv);
    }
    let sgn_at = r(1.0) / im(PI * XI0);
    assert!(last < 5e-4 && abs(point - sgn_at) < 1e-6);
    println!("sgn-hat at 250 Hz: 1/(pi i xi) = {} ms", c(sgn_at));
    let uneven = r(simpson(|x| phi(x) / x, 0.002, R, 400000) + simpson(|x| phi(x) / x, -R, -0.001, 400000)) / im(PI);
    let lim = r(-phi(0.0) * 2f64.ln()) / im(PI);
    println!("uneven gap (-1 Hz, 2 Hz) instead of p.v.: {}, shift {}, limit as the gap shrinks {}", c(uneven), c(uneven - pv), c(lim));
    assert!(abs(uneven - pv - lim) < 2e-3);

    // 4. the step H = (1 + sgn)/2
    let h_time = simpson(g0, 0.0, R, 6000);
    println!("H-hat on the centred bell: time side {:.6}, formula 1/2 + 0 = 0.500000, without delta/2 0.000000", h_time);
    assert!((h_time - 0.5).abs() < 1e-12);
    let h_probe = simpson_c(|t| r(g0(t)) * arrow(-2.0 * PI * XI0 * t), 0.0, R, 6000);
    let h_formula = r(phi(0.0) / 2.0) + pv * r(0.5);
    println!("H-hat on probe: time side {}, phi(0)/2 + p.v./2 {}", c(h_probe), c(h_formula));
    assert!(abs(h_probe - h_formula) < 1e-10);
    println!("H-hat at 250 Hz, away from 0: 1/(2 pi i xi) = {} ms", c(r(1.0) / im(2.0 * PI * XI0)));
    println!("1-hat = 2 pi delta in hertz (the omega-form factor): {:.6} instead of {:.6}", 2.0 * PI * target, target);

    // 5. the 1 ms shutter from two steps, and its slope as two spikes
    let tt = 1.0f64;
    let spikes = arrow(PI * XI0 * tt) - arrow(-PI * XI0 * tt);
    let steps = spikes / im(2.0 * PI * XI0);
    let direct = simpson(|t| (2.0 * PI * XI0 * t).cos(), -tt / 2.0, tt / 2.0, 400);
    let gh = tt * sinc(tt * XI0);
    println!("shutter at 250 Hz: from two steps {}, T sinc(T xi) {:.6}, Simpson {:.6} ms", c(steps), gh, direct);
    assert!(abs(steps - r(direct)) < 1e-9 && (direct - gh).abs() < 1e-10); // two steps against Simpson
    let rule = im(2.0 * PI * XI0 * gh);
    println!("shutter slope at 250 Hz: two spikes {}, 2 pi i xi g-hat {}, pointwise slope 0", c(spikes), c(rule));
    assert!(abs(spikes - im(2.0 * PI * XI0 * direct)) < 1e-9); // the jumps against 2 pi i xi times Simpson's g-hat
    let xs: Vec<String> = (1..=20).map(|k| format!("{:6.2}", k as f64 / 20.0)).collect();
    println!("chart, xi kHz      {}", xs.join(" "));
    for (eps, lab) in [(1.0f64, "1.0 "), (0.25, "0.25")] {
        let v: Vec<String> = (1..=20).map(|k| { let x = k as f64 / 20.0; format!("{:6.3}", 4.0 * PI * x / (eps * eps + 4.0 * PI * PI * x * x)) }).collect();
        println!("chart, eps={}    {}", lab, v.join(" "));
    }
    let v: Vec<String> = (1..=20).map(|k| format!("{:6.3}", 1.0 / (PI * k as f64 / 20.0))).collect();
    println!("chart, 1/(pi xi)   {}", v.join(" "));
    println!("ALL CHECKS PASS");
}
