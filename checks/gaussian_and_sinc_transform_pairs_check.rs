// Gate and sinc, and the bell that is its own transform -- the check behind the card.
// Standard library only. Convention: f-hat(xi) = integral of f(t) e^(-2 pi i xi t) dt,
// t in seconds, xi in hertz. The gate is a camera shutter open for T = 1 ms.
// Roads: closed form; the defining integral by Simpson's rule at two step counts;
// the finite twin (a sampled sum, one bin of a length-1000 DFT); a series for Si.
use std::f64::consts::PI;

const T: f64 = 0.001; // shutter open time, seconds
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn scale(self, k: f64) -> C { C { re: k * self.re, im: k * self.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
}
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn one(_t: f64) -> f64 { 1.0 } // the gate, inside its open interval
fn gate_hat(xi: f64) -> f64 { T * sinc(xi * T) } // road 1
fn bell(t: f64) -> f64 { (-PI * (t / T).powi(2)).exp() } // bell with area T
fn bell_hat(xi: f64) -> f64 { T * (-PI * (xi * T).powi(2)).exp() } // road 1
fn ms(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-13 { 0.0 } else { 1000.0 * x }) }
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-10 { 0.0 } else { x }) }
fn sci(x: f64) -> String { // Python's %.2e: two-digit exponent with a sign
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn c2(x: f64) -> String { format!("{:.2}", if x.abs() < 0.005 { 0.0 } else { x }) }
fn cms(z: C) -> String { format!("{}{}{}i", ms(z.re), if z.im < -5e-13 { " - " } else { " + " }, ms(z.im.abs())) }
fn probe(xi: f64, t: f64, sign: f64) -> C { let a = 2.0 * PI * xi * t; C { re: a.cos(), im: sign * a.sin() } }

fn simpson<F: Fn(f64) -> C>(f: F, a: f64, b: f64, n: usize) -> C { // n even: parabola-topped strips
    let w = (b - a) / n as f64;
    let mut s = f(a).add(f(b));
    for k in 1..n { s = s.add(f(a + k as f64 * w).scale(if k % 2 == 1 { 4.0 } else { 2.0 })); }
    let s = s.scale(w);
    C { re: s.re / 3.0, im: s.im / 3.0 }
}
fn simpson_re<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 { simpson(|t| C { re: f(t), im: 0.0 }, a, b, n).re }
fn by_integral(f: fn(f64) -> f64, a: f64, b: f64, xi: f64, n: usize, sign: f64) -> C { // road 2
    simpson(|t| probe(xi, t, sign).scale(f(t)), a, b, n)
}
fn by_samples(f: fn(f64) -> f64, xi: f64, h: f64, m: i64, edge: f64, step: bool) -> C { // road 3
    let mut s = C { re: 0.0, im: 0.0 }; // edge: weight of the samples at n = -M, M
    for n in -m..=m {
        let t = n as f64 * h;
        s = s.add(probe(xi, t, -1.0).scale((if n.abs() == m { edge } else { 1.0 }) * f(t)));
    }
    s.scale(if step { h } else { 1.0 })
}
fn unit_bell(t: f64) -> f64 { (-PI * t * t).exp() }

fn main() {
    println!("convention: f-hat(xi) = integral f(t) e^(-2 pi i xi t) dt; t in s, xi in Hz; values in ms");
    println!("gate, T = 1 ms: closed form T sinc(xi T); Simpson on the open millisecond, 400 strips; errors at 200 and 400 strips:");
    for xi in [0.0, 500.0, 1000.0, 1500.0, 2000.0] {
        let (a, b) = (by_integral(one, -T / 2.0, T / 2.0, xi, 200, -1.0), by_integral(one, -T / 2.0, T / 2.0, xi, 400, -1.0));
        let g = C { re: gate_hat(xi), im: 0.0 };
        let (e1, e2) = (a.sub(g).abs() / T, b.sub(g).abs() / T);
        println!("  xi = {:4} Hz: {}; {}; {}, {} of T", xi as i64, ms(gate_hat(xi)), cms(b), sci(e1), sci(e2));
        assert!(e1 < 1e-8 && e2 < 1e-9);
    }
    println!("first zeros 1/T for five pulse lengths, with Simpson at that frequency:");
    for (name, ts) in [("1/100 s", 1.0 / 100.0), ("1/250 s", 1.0 / 250.0), ("1/1000 s", 1.0 / 1000.0), ("1/4000 s", 1.0 / 4000.0), ("1 us pulse", 1e-6)] {
        let z = by_integral(one, -ts / 2.0, ts / 2.0, 1.0 / ts, 400, -1.0);
        println!("  {}: open {} ms, first zero 1/T = {} Hz, Simpson there {}", name, f6(1000.0 * ts), f6(1.0 / ts), cms(z));
        assert!(z.abs() < 1e-15 && by_integral(one, -ts / 2.0, ts / 2.0, 0.9 / ts, 400, -1.0).abs() > 0.1 * ts);
    }
    let lobe = simpson_re(|u| sinc(u).powi(2), -1.0, 1.0, 2000);
    let (mut si, mut term, mut k) = (0.0f64, 2.0 * PI, 0i64); // Si(x) = sum (-1)^k x^(2k+1) / ((2k+1)(2k+1)!)
    while term.abs() > 1e-17 {
        si += term / (2 * k + 1) as f64; k += 1;
        term *= -(2.0 * PI).powi(2) / ((2 * k) * (2 * k + 1)) as f64;
    }
    println!("energy below 1 kHz: Simpson {}; 2 Si(2 pi)/pi {} (Si(2 pi) = {}, {} terms)", f6(lobe), f6(2.0 * si / PI), f6(si), k);
    assert!((lobe - 2.0 * si / PI).abs() < 1e-9);
    let (mut peak, mut at) = (0.0f64, 0.0f64);
    for j in 0..=10000 {
        let (p, a) = (sinc(1.0 + j as f64 / 10000.0).abs(), 1000.0 + j as f64 / 10.0);
        if p > peak || (p == peak && a > at) { peak = p; at = a; }
    }
    println!("first side lobe, scan of 1000 to 2000 Hz in 0.1 Hz steps: largest |sinc| {} at {:.1} Hz, {:.2} dB", f6(peak), at, 20.0 * peak.log10());
    assert!(0.2172 < peak && peak < 0.2173 && 1430.0 < at && at < 1431.0);
    println!("unit bell e^(-pi t^2), closed form e^(-pi xi^2) against Simpson on [-6, 6], 600 and 1200 strips:");
    let tail = (-36.0 * PI).exp() / (6.0 * PI);
    for xi in [0.0, 0.5, 1.0, 1.5] {
        let (a, b) = (by_integral(unit_bell, -6.0, 6.0, xi, 600, -1.0), by_integral(unit_bell, -6.0, 6.0, xi, 1200, -1.0));
        let exact = (-PI * xi * xi).exp();
        println!("  xi = {:.1}: {}; {}; {}", xi, f6(exact), f6(a.re), f6(b.re));
        assert!(a.sub(C { re: exact, im: 0.0 }).abs() < 1e-12 && b.sub(a).abs() < 1e-13);
    }
    println!("  cut-off |t| = 6, tail bound e^(-36 pi)/(6 pi) = {}", sci(tail));
    let d = 1e-5;
    let g = |x: f64| by_integral(unit_bell, -6.0, 6.0, x, 1200, -1.0).re;
    let slope = (g(0.5 + d) - g(0.5 - d)) / (2.0 * d);
    println!("slope at xi = 0.5: difference quotient {}; -2 pi xi g-hat {}", f6(slope), f6(-PI * g(0.5)));
    assert!((slope + PI * g(0.5)).abs() < 1e-6);
    println!("shutter flicker pass-through, sinc(nu T) for the gate and e^(-pi (nu T)^2) for the bell:");
    for nu in [100.0, 1000.0, 1500.0] {
        println!("  nu = {:4} Hz: gate {}, bell {}", nu as i64, f6(gate_hat(nu) / T), f6(bell_hat(nu) / T));
    }
    println!("benchmark, h = 20 us (50 kHz), bins every 50 Hz of a length-1000 DFT; gap = sampled - exact:");
    for xi in [0i64, 500, 1000, 1500] {
        let x = xi as f64;
        let (gs, bs) = (by_samples(one, x, T / 50.0, 25, 0.5, true), by_samples(bell, x, T / 50.0, 300, 1.0, true));
        println!("  bin {:2}, {:4} Hz: gate {} gap {}; bell {} gap {}", xi / 50, xi, ms(gs.re), sci(1000.0 * (gs.re - gate_hat(x))), ms(bs.re), sci(1000.0 * (bs.re - bell_hat(x))));
        assert!(bs.sub(C { re: bell_hat(x), im: 0.0 }).abs() < 1e-18 && gs.im.abs() < 1e-15);
        assert!((gs.re - gate_hat(x)).abs() < 1e-3 * T); // half-weight edges: the gap is aliasing only
    }
    let gap = |m: i64| by_samples(one, 1500.0, T / m as f64, m / 2, 0.5, true).re - gate_hat(1500.0);
    let (g1, g2) = (gap(50), gap(100));
    println!("gate gap at 1500 Hz: h = 20 us {} ms, h = 10 us {} ms, ratio {:.4}", sci(1000.0 * g1), sci(1000.0 * g2), g1 / g2);
    assert!(3.9 < g1 / g2 && g1 / g2 < 4.1 && g1.abs() > 1e-4 * T);
    let shut = by_integral(one, 0.0, T, 500.0, 400, -1.0); // shutter opening at t = 0 instead of centred
    let want = C { re: 0.0, im: -gate_hat(500.0) };
    println!("shutter on [0, T] at 500 Hz: Simpson {}; T sinc(1/2) e^(-i pi/2) {}", cms(shut), cms(want));
    assert!(shut.sub(want).abs() < 1e-12);
    let chart = |f: fn(f64) -> f64| (0..17).map(|j| c2(1000.0 * f(250.0 * j as f64))).collect::<Vec<_>>().join(", ");
    println!("chart, xi = 0 to 4000 Hz in 250 Hz steps, gate in ms: {}", chart(gate_hat));
    println!("chart, xi = 0 to 4000 Hz in 250 Hz steps, bell in ms: {}", chart(bell_hat));
    let wrong = |xi: f64| by_integral(one, -T / 2.0, T / 2.0, xi / (2.0 * PI), 400, -1.0); // kernel e^(-i xi t)
    println!("mistake, kernel e^(-i xi t) with xi in Hz: at 1000 Hz {}; first zero at {} Hz, Simpson there {}", cms(wrong(1000.0)), f6(2.0 * PI / T), cms(wrong(2.0 * PI / T)));
    assert!(wrong(2.0 * PI / T).abs() < 1e-15 && wrong(1000.0).sub(C { re: gate_hat(1000.0), im: 0.0 }).abs() > 0.9 * T);
    let nostep = by_samples(one, 0.0, T / 50.0, 25, 0.5, false).re;
    println!("mistake, no step h in the sum, gate at 0 Hz: {} instead of {} ms", f6(nostep), ms(gate_hat(0.0)));
    assert!((nostep - gate_hat(0.0) / (T / 50.0)).abs() < 1e-9); // a count of samples: the area over h
    let full = by_samples(one, 1000.0, T / 50.0, 25, 1.0, true).re;
    println!("mistake, edge samples at full weight: 0 Hz {} ms, 1000 Hz {} ms", ms(by_samples(one, 0.0, T / 50.0, 25, 1.0, true).re), ms(full));
    assert!((full + T / 50.0).abs() < 1e-15);
    let flip = by_integral(one, 0.0, T, 500.0, 400, 1.0);
    println!("mistake, sign flipped to e^(+2 pi i xi t): shutter on [0, T] {}; centred gate {}, unchanged", cms(flip), cms(by_integral(one, -T / 2.0, T / 2.0, 500.0, 400, 1.0)));
    assert!(flip.sub(shut.conj()).abs() < 1e-15 && flip.sub(shut).abs() > T);
    let area: Vec<f64> = [10, 100, 1000].iter().map(|&w| 2.0 * (0..w).fold(0.0, |acc, j| acc + simpson_re(|u| sinc(u).abs(), j as f64, (j + 1) as f64, 40))).collect();
    println!("hypothesis fails: area under |sinc| on [-W, W], W = 10, 100, 1000: {}, {}, {}; per decade {}, {} against (4/pi^2) ln 10 = {}",
        f6(area[0]), f6(area[1]), f6(area[2]), f6(area[1] - area[0]), f6(area[2] - area[1]), f6(4.0 / PI.powi(2) * 10f64.ln()));
    assert!((area[2] - area[1] - 4.0 / PI.powi(2) * 10f64.ln()).abs() < 0.01);
    println!("ALL CHECKS PASS");
}
