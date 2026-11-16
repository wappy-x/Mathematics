// The transform rulebook -- the same check as the Python file, in Rust.
// Standard library only, no crates.  Units: t in ms, xi in kHz, transforms in
// ms.  A complex number is a small struct; every transform is computed here.
use std::f64::consts::PI;
use std::ops::{Add, Mul, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl Mul for C {
    type Output = C;
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
}
impl C {
    fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
    fn div(self, o: C) -> C { let d = o.re * o.re + o.im * o.im; (self * C { re: o.re, im: -o.im }).sc(1.0 / d) }
}
fn r(x: f64) -> C { C { re: x, im: 0.0 } }
const I: C = C { re: 0.0, im: 1.0 };

const T: f64 = 1.0; // plain exposure 1 ms
const T0: f64 = 3.0; // new pulse: delay 3 ms
const S: f64 = 2.0; // and stretch 2
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }
fn arrow(x: f64) -> C { C { re: x.cos(), im: x.sin() } } // e^(ix), written out
fn gate(t: f64) -> f64 { if t.abs() <= T / 2.0 { 1.0 } else { 0.0 } } // plain shutter
fn ghat(xi: f64) -> f64 { T * sinc(T * xi) } // from the L1-transform card
fn h(t: f64) -> f64 { gate((t - T0) / S) } // the new pulse: open 2 ms to 4 ms
fn hhat(xi: f64) -> C { arrow(-2.0 * PI * xi * T0).sc(S.abs() * ghat(S * xi)) } // rules
const LO: f64 = T0 - S.abs() * T / 2.0; // where h is open
const HI: f64 = T0 + S.abs() * T / 2.0;

fn simpson(f: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C {
    let w = (b - a) / n as f64;
    let mut tot = f(a) + f(b);
    for k in 1..n { tot = tot + f(a + k as f64 * w).sc(if k % 2 == 1 { 4.0 } else { 2.0 }); }
    tot.sc(w / 3.0)
}
fn ft(f: &dyn Fn(f64) -> C, xi: f64, a: f64, b: f64, n: usize) -> C {
    simpson(&|t| f(t) * arrow(-2.0 * PI * xi * t), a, b, n)
}
fn box_exact(a: f64, b: f64, xi: f64) -> C {
    (arrow(-2.0 * PI * xi * a) - arrow(-2.0 * PI * xi * b)).div(I.sc(2.0 * PI * xi))
}
fn snap(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }
fn c(z: C) -> String {
    let (re, im) = (snap(z.re), snap(z.im));
    format!("{:.6} {} {:.6}i", re, if im < 0.0 { "-" } else { "+" }, im.abs())
}
fn c4(z: C) -> String { format!("{:.4} {} {:.4}i", z.re, if z.im < 0.0 { "-" } else { "+" }, z.im.abs()) }

fn main() {
    let hc = |t: f64| r(h(t));
    println!("plain shutter g: open 1 ms, centred on 0");
    println!("g-hat(250 Hz) = {:.6} ms, g-hat(0) = {:.6} ms", ghat(0.25), ghat(0.0));
    println!("new pulse h: opens {:.0} ms, closes {:.0} ms, centre {:.0} ms", LO, HI, T0);
    println!("xi Hz | by the rules | defining integral, Simpson n=400 | exact antiderivative");
    for xi in [0.1, 0.25, 0.5] {
        let (rr, s, e) = (hhat(xi), ft(&hc, xi, LO, HI, 400), box_exact(LO, HI, xi));
        println!("{:.0} | {} | {} | {}", xi * 1000.0, c(rr), c(s), c(e));
        assert!((rr - s).abs() < 1e-9 && (rr - e).abs() < 1e-12);
    }
    println!("steps for 250 Hz: 2 x g-hat(500 Hz) = {:.6} ms, turns {:.2}, turn = {}", 2.0 * ghat(0.5), 0.25 * T0, c(arrow(-2.0 * PI * 0.25 * T0)));
    println!("flicker swing kept | 1 ms shutter | 2 ms shutter");
    for xi in [0.1, 0.25, 0.5] {
        println!("{:.0} Hz | {:.6} | {:.6}", xi * 1000.0, ghat(xi).abs() / ghat(0.0), snap(hhat(xi).abs() / hhat(0.0).abs()));
    }
    // time reversal: h(-t) has transform |-1| h-hat(-xi); forgetting |s| flips the sign
    let rev = ft(&|t| r(h(-t)), 0.25, -HI, -LO, 400);
    println!("reversed h at 250 Hz: Simpson {}, rule {}, without |s| {}", c(rev), c(hhat(-0.25)), c(hhat(-0.25).sc(-1.0)));
    assert!((rev - hhat(-0.25)).abs() < 1e-9 && (rev + hhat(-0.25)).abs() > 1.0);
    // modulation: the 1 ms gate times cos(2 pi 2 kHz t), a two-cycle burst
    let burst = |t: f64| r(gate(t) * (2.0 * PI * 2.0 * t).cos());
    for xi in [2.0, 2.25] {
        let rule = (ghat(xi - 2.0) + ghat(xi + 2.0)) / 2.0;
        let s = ft(&burst, xi, -0.5, 0.5, 2000);
        println!("burst at {:.0} Hz: rule {:.6} ms, Simpson {} ms", xi * 1000.0, rule, c(s));
        assert!((s - r(rule)).abs() < 1e-9);
    }
    // duality: sinc^2 in time has the tent as its transform: 0.75 at 250 Hz.
    let tent = |t: f64| r((1.0 - t.abs()).max(0.0));
    for l in [500usize, 1000] {
        let lf = l as f64;
        let d = 2.0 * simpson(&|t| r(sinc(t).powi(2) * (2.0 * PI * 0.25 * t).cos()), 0.0, lf, 100 * l).re;
        let bound = 2.0 / (PI * PI * lf);
        println!("sinc^2 at 250 Hz, cut-off {} ms: {:.6} ms, tent value {:.6}, tail bound {:.6}", l, d, tent(0.25).re, bound);
        assert!((d - tent(0.25).re).abs() < bound);
    }
    // derivative rule on the tent: its slope is two shifted gates, +1 then -1
    let dhat = (arrow(PI * 0.25) - arrow(-PI * 0.25)).sc(ghat(0.25)); // shift rule only
    let tent_rule = dhat.div(I.sc(2.0 * PI * 0.25));
    let tent_simp = ft(&tent, 0.25, -1.0, 0.0, 400) + ft(&tent, 0.25, 0.0, 1.0, 400);
    println!("tent at 250 Hz: derivative rule {}, g-hat^2/T {:.6}, Simpson {}", c(tent_rule), ghat(0.25).powi(2) / T, c(tent_simp));
    assert!((tent_rule - r(ghat(0.25).powi(2) / T)).abs() < 1e-12 && (tent_simp - tent_rule).abs() < 1e-9);
    // the rule fails on the gate itself: its slope is 0 wherever it exists; the jumps hold it all
    let slope = |t: f64| r((gate(t + 1e-4) - gate(t - 1e-4)) / 2e-4); // difference quotient, off the jumps
    let flat = [(-1.0, -0.501), (-0.499, 0.499), (0.501, 1.0)].iter()
        .fold(r(0.0), |s, &(a, b)| s + ft(&slope, 0.25, a, b, 400));
    let spikes = arrow(PI * 0.25 * T) - arrow(-PI * 0.25 * T); // +1 at -T/2, -1 at +T/2
    let jump = I.sc(2.0 * PI * 0.25 * ghat(0.25));
    println!("gate, 250 Hz: transform of pointwise slope {}, 2 pi i xi g-hat = {}, jump spikes {}", c(flat), c(jump), c(spikes));
    assert!(flat.abs() < 1e-12 && (jump - spikes).abs() < 1e-12);
    // frequency-side derivative: d/dxi h-hat = transform of -2 pi i t h(t)
    let dq = 1e-5;
    let cd = (hhat(0.25 + dq) - hhat(0.25 - dq)).sc(1.0 / (2.0 * dq));
    let sd = ft(&|t| I.sc(-2.0 * PI * t * h(t)), 0.25, LO, HI, 400);
    println!("slope of h-hat at 250 Hz: difference quotient {}, transform of -2 pi i t h {} ms^2", c4(cd), c4(sd));
    assert!((cd - sd).abs() < 1e-6);
    let ph = |xi: f64| { let z = hhat(xi); z.im.atan2(z.re) };
    println!("delay read from the phase slope: {:.6} ms", -(ph(0.25 + dq) - ph(0.25 - dq)) / (2.0 * dq) / (2.0 * PI));
    // what breaks, all at 250 Hz
    let turn = arrow(-2.0 * PI * 0.25 * T0);
    println!("what breaks at 250 Hz, right answer {}", c(hhat(0.25)));
    println!("stretch on the wrong side, 2 g-hat(xi/2) | {}", c(turn.sc(2.0 * ghat(0.125))));
    println!("drop the factor 2 | {}", c(turn.sc(ghat(0.5))));
    println!("delay then stretch, centre at 6 ms | {}", c(hhat(0.25) * turn));
    println!("plus sign in the turn | {}", c(arrow(2.0 * PI * 0.25 * T0).sc(2.0 * ghat(0.5))));
    let row = |f: &dyn Fn(usize) -> String| (0..21).map(|k| f(k)).collect::<Vec<_>>().join(" ");
    println!("chart, xi Hz            {}", row(&|k| format!("{:6}", k * 100)));
    println!("chart, 1 ms g-hat       {}", row(&|k| format!("{:6.3}", snap(ghat(k as f64 / 10.0)))));
    println!("chart, 2 ms 2g-hat(2xi) {}", row(&|k| format!("{:6.3}", snap(2.0 * ghat(k as f64 / 5.0)))));
    println!("ALL CHECKS PASS");
}
