// The z-transform -- the same check as the Python, in Rust.  No crates.
// A soldering-iron tip on a digital thermostat that updates every T = 0.1 s.
//   tip:        y[n+1] = a y[n] + b u[n]     y: tip temperature change (degC), u: heater power change (W)
//   thermostat: u[n]   = K (r - y[n-1])      it acts on the reading taken one tick earlier
//   transform:  H(z) = b K z / (z^2 - a z + b K)
// Step response by three roads: the loop itself; partial fractions over the poles;
// the inverse transform as a contour integral.  Stability by roots, by Jury's test, by running it.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }                             // a complex number, written out
fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        c((self.re * o.re + self.im * o.im) / d, (self.im * o.re - self.re * o.im) / d)
    }
    fn sc(self, k: f64) -> C { c(self.re * k, self.im * k) }
    fn abs(self) -> f64 { self.re.hypot(self.im) }  fn arg(self) -> f64 { self.im.atan2(self.re) }
    fn powi(self, n: i32) -> C { let mut p = c(1.0, 0.0); for _ in 0..n { p = p.mul(self) } p }
}
fn cis(t: f64) -> C { c(t.cos(), t.sin()) }

const T: f64 = 0.1; const CTH: f64 = 2.5; const RTH: f64 = 20.0; const P_IDLE: f64 = 16.5; const P_MAX: f64 = 80.0;
const A: f64 = 1.0 - T / (RTH * CTH); const B: f64 = T / CTH;  // share kept per tick; degC per W per tick
const K: f64 = 12.5; const R0: f64 = 5.0;                   // W/degC; setpoint raised 5 degC

fn run(k: f64, r: f64, ticks: usize, b: f64, d: f64, lo: f64, hi: f64, a: f64) -> (Vec<f64>, Vec<f64>) {   // the firmware
    let (mut y, mut u) = (vec![0.0, 0.0], vec![]);         // y[-1], y[0]: at rest
    for _ in 0..ticks {
        let l = y.len();
        u.push(hi.min(lo.max(k * (r - y[l - 2]))));         // reading from one tick back
        y.push(a * y[l - 1] + b * u[u.len() - 1] - b * d);  // d: heat drawn by a joint, W
    }
    (y[1..].to_vec(), u)
}
fn lp(k: f64, r: f64, ticks: usize) -> (Vec<f64>, Vec<f64>) { run(k, r, ticks, B, 0.0, f64::NEG_INFINITY, f64::INFINITY, A) }

fn poles_a(k: f64, b: f64, a: f64) -> (C, C) {             // roots of z^2 - a z + b K
    let disc = a * a - 4.0 * b * k;
    let q = if disc >= 0.0 { c(disc.sqrt(), 0.0) } else { c(0.0, (-disc).sqrt()) };
    (c(a, 0.0).add(q).sc(0.5), c(a, 0.0).sub(q).sc(0.5))
}
fn poles(k: f64, b: f64) -> (C, C) { poles_a(k, b, A) }    fn maxp(k: f64, b: f64) -> f64 { maxp_a(k, b, A) }
fn maxp_a(k: f64, b: f64, a: f64) -> f64 { let (p, q) = poles_a(k, b, a); p.abs().max(q.abs()) }
fn jury(k: f64) -> bool {                                   // z^2 + c1 z + c0, no roots needed
    let (c1, c0) = (-A, B * k);
    c0.abs() < 1.0 && 1.0 + c1 + c0 > 0.0 && 1.0 - c1 + c0 > 0.0
}
fn yz(z: C) -> C {                                          // transform of the step response
    let one = c(1.0, 0.0);
    z.mul(z).sc(B * K * R0).div(z.sub(one).mul(z.mul(z).sub(z.sc(A)).add(c(B * K, 0.0))))
}
fn residues(n: i32) -> f64 {                                // partial fractions, read back in time
    let (p1, p2) = poles(K, B);
    let (g, one) = (B * K * R0, c(1.0, 0.0));
    let t0 = c(g, 0.0).div(one.sub(p1).mul(one.sub(p2)));
    let t1 = p1.powi(n + 1).sc(g).div(p1.sub(one).mul(p1.sub(p2)));
    let t2 = p2.powi(n + 1).sc(g).div(p2.sub(one).mul(p2.sub(p1)));
    t0.add(t1).add(t2).re
}
fn clean(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } }   // no "-0.00000" from rounding noise
fn contour(n: i32) -> f64 {                                 // (1/2 pi j) closed integral of Y z^(n-1) dz
    let (rho, m) = (1.2, 256);
    let mut s = c(0.0, 0.0);
    for k in 0..m {
        let z = cis(2.0 * PI * k as f64 / m as f64).sc(rho);
        s = s.add(yz(z).mul(z.powi(n)));
    }
    s.re / m as f64
}
fn hz(f: f64) -> C {
    let e = cis(2.0 * PI * f * T);
    e.sc(B * K).div(cis(4.0 * PI * f * T).sub(e.sc(A)).add(c(B * K, 0.0)))
}

fn main() {
    println!("tip: T = {:.1} s, C = {:.1} J/degC, R = {:.1} degC/W; a = {:.6}, b = {:.6} degC per W per tick", T, CTH, RTH, A, B);
    let (ea, eb) = ((-T / (RTH * CTH)).exp(), RTH * (1.0 - (-T / (RTH * CTH)).exp()));   // heater held flat over each tick
    println!("exact one-tick factors (card 09): a = {:.6}, b = {:.6}", ea, eb);
    let (y, u) = lp(K, R0, 400); let (p1, _p2) = poles(K, B);
    println!("K = {:.1} W/degC: b K = {:.3}; poles {:.5} +- {:.5}j, |p| = {:.5}, angle {:.2} deg", K, B * K, p1.re, p1.im.abs(), p1.abs(), p1.arg().to_degrees());
    let umin = u.iter().cloned().fold(f64::INFINITY, f64::min);
    println!("power for the 5 degC step: first tick {:.1} W extra, total {:.1} W of {:.0} W; min extra {:.2} W", u[0], u[0] + P_IDLE, P_MAX, umin);
    let gap = (0..41).map(|n| (y[n] - residues(n as i32)).abs().max((y[n] - contour(n as i32)).abs())).fold(0.0, f64::max);
    println!("three roads, ticks 0-40 (contour |z| = 1.2, 256 points): largest gap {} degC", if gap < 1e-9 { "below 1e-9".to_string() } else { format!("{}", gap) });
    for n in [0usize, 1, 2, 3, 4, 5, 10, 20] {
        println!("n = {:2}  t = {:.1} s  loop {:8.5}  partial fractions {:8.5}  contour {:8.5} degC", n, n as f64 * T, y[n], clean(residues(n as i32)), clean(contour(n as i32)));
    }
    println!("chart, y[n] n=0..20 (degC) {}", y[..21].iter().map(|v| format!("{:.2}", v)).collect::<Vec<_>>().join(" "));
    let h1 = B * K / (1.0 - A + B * K);
    let mut pk = 0; for n in 0..60 { if y[n] > y[pk] { pk = n } }
    let settle = (0..200).filter(|&n| (y[n] - h1 * R0).abs() > 0.02 * h1 * R0).max().unwrap() + 1;
    println!("final value: H(1) = {:.6}, H(1) r = {:.5} degC (loop at n = 399: {:.5}); droop {:.5} degC", h1, h1 * R0, y[399], R0 - h1 * R0);
    println!("peak {:.4} degC at n = {} (t = {:.1} s), overshoot {:.1} %, {:.5} degC past", y[pk], pk, pk as f64 * T, 100.0 * (y[pk] / (h1 * R0) - 1.0), y[pk] - h1 * R0);
    println!("2 % settling: loop n = {} ({:.1} s); envelope ln(0.02)/ln|p| = {:.2} ticks", settle, settle as f64 * T, 0.02f64.ln() / p1.abs().ln());
    let (ye, _) = run(K, R0, 400, eb, 0.0, f64::NEG_INFINITY, f64::INFINITY, ea); let mut pe = 0; for n in 0..60 { if ye[n] > ye[pe] { pe = n } }
    println!("exact factors, same loop: |p| = {:.5}, peak {:.5} degC at n = {}, overshoot {:.1} %, final {:.5} degC, limit 1/b = {:.3} W/degC", maxp_a(K, eb, ea), ye[pe], pe, 100.0 * (ye[pe] / ye[399] - 1.0), ye[399], 1.0 / eb);
    let z0 = 2.0f64; let fwd: f64 = (0..400).map(|n| y[n] * z0.powi(-(n as i32))).sum();
    println!("definition at z = 2: sum of y[n] 2^-n = {:.9}; closed form Y(2) = {:.9}", fwd, yz(c(z0, 0.0)).re);
    let per = 2.0 * PI / p1.arg();
    println!("ringing period 2 pi/angle = {:.3} ticks = {:.4} s, {:.4} Hz", per, per * T, 1.0 / (per * T));
    let (sre, sim) = (p1.abs().ln() / T, p1.arg() / T);
    println!("z = e^(sT): closed-loop s = {:.4} +- {:.4}j rad/s; plant pole ln(a)/T = {:.6} 1/s vs -1/(RC) = {:.6}", sre, sim.abs(), A.ln() / T, -1.0 / (RTH * CTH));

    // ---- stability against the unit circle ----
    for k in [0.0, 5.0, 12.5, 20.0, 24.0, 25.0, 26.0, 30.0] {
        let m = maxp(k, B);
        let (yk, _) = lp(k, R0, 3000);
        let fin = B * k / (1.0 - A + B * k) * R0;
        let dev = yk[2900..].iter().map(|v| (v - fin).abs()).fold(0.0, f64::max);
        let sw = if dev < 1e-9 { "below 1e-9".to_string() } else if dev < 1e3 { format!("{:.2}", dev) } else { format!("10^{:.2}", dev.log10()) };
        println!("K = {:4.1}  max|p| = {:.5}  roots say {}  Jury says {}  swing after 290 s {} degC", k, m,
                 if m < 1.0 - 1e-12 { "stable" } else { "not stable" }, if jury(k) { "stable" } else { "not stable" }, sw);
    }
    let (mut lo_k, mut hi_k) = (0.0, 100.0);
    for _ in 0..100 { let mid = (lo_k + hi_k) / 2.0; if maxp(mid, B) < 1.0 { lo_k = mid } else { hi_k = mid } }   // bisection on the roots' size
    println!("stability limit: bisection on max|p| = 1 {:.6} W/degC; Jury's b K < 1 gives 1/b = {:.6} W/degC; gain margin {:.2}", lo_k, 1.0 / B, 1.0 / B / K);
    for k in [25.0, 30.0] {
        let q = poles(k, B).0;
        println!("K = {:.1}: poles {:.5} +- {:.5}j, angle {:.2} deg, period {:.4} s", k, q.re, q.im.abs(), q.arg().to_degrees(), 2.0 * PI / q.arg() * T);
    }
    for s in [1.2, 2.0] { println!("tip heat capacity / {:.1}: b = {:.3}, max|p| = {:.5}", s, B * s, maxp_a(K, B * s, 1.0 - T * s / (RTH * CTH))) }   // b grows, a shrinks
    println!("figure, centre (170,120), unit circle radius 90 px; zero at (170,120)");
    for k in [12.5, 25.0, 30.0] {
        let q = poles(k, B).0;
        println!("figure, K = {:.1}: poles at ({:.1},{:.1}) and ({:.1},{:.1})", k, 170.0 + 90.0 * q.re, 120.0 - 90.0 * q.im, 170.0 + 90.0 * q.re, 120.0 + 90.0 * q.im);
    }

    // ---- the unit circle is frequency: z = e^(j 2 pi f T) ----
    for f in [0.0, 0.5, 1.0, 1.25, 2.0, 5.0] { println!("|H| at {:4.2} Hz = {:.4}", f, hz(f).abs()) }
    let mut fpk = 0.0;
    for i in 0..5001 { let f = i as f64 * 0.001; if hz(f).abs() > hz(fpk).abs() { fpk = f } }
    println!("peak gain {:.4} at {:.3} Hz; z = -1 is f_s/2 = {:.1} Hz", hz(fpk).abs(), fpk, 1.0 / (2.0 * T));
    let mut yv = vec![0.0, 0.0];
    for n in 0..1200 {                                      // setpoint wobbling 1 degC at 1 Hz
        let l = yv.len();
        yv.push(A * yv[l - 1] + B * K * ((2.0 * PI * 1.0 * n as f64 * T).sin() - yv[l - 2]));
    }
    let tail = &yv[201..1201];                              // y[200]..y[1199], 100 whole periods
    let cs = tail.iter().enumerate().map(|(n, v)| v * (2.0 * PI * (n + 200) as f64 * T).cos()).sum::<f64>() * 2.0 / 1000.0;
    let sn = tail.iter().enumerate().map(|(n, v)| v * (2.0 * PI * (n + 200) as f64 * T).sin()).sum::<f64>() * 2.0 / 1000.0;
    println!("1 Hz wobble of 1 degC, run through the loop: tip swings {:.4} degC ({:.1} deg per tick)", cs.hypot(sn), 360.0 * 1.0 * T);
    println!("no sensor delay: one pole a - b K = {:.3}; limit K = (1 + a)/b = {:.2} W/degC", A - B * K, (1.0 + A) / B);

    // ---- what breaks ----
    println!("s-plane rule on z-poles: Re p = {:.3} > 0 calls the K = 12.5 loop unstable; |p| = {:.5} < 1, it settles", p1.re, p1.abs());
    let (yl, ul) = lp(K, 20.0, 200);
    let (yc, _uc) = run(K, 20.0, 200, B, 0.0, -P_IDLE, P_MAX - P_IDLE, A);
    let (ylm, mut ic) = (yl.iter().cloned().fold(f64::NEG_INFINITY, f64::max), 0);
    for n in 0..yc.len() { if yc[n] > yc[ic] { ic = n } }
    println!("20 degC step: linear asks {:.0} W extra, peak {:.3} degC; heater clamped to +{:.1} W/-{:.1} W peaks {:.3} degC at n = {}", ul[0], ylm, P_MAX - P_IDLE, P_IDLE, yc[ic], ic);
    let (yd, _) = run(K, 0.0, 400, B, 20.0, f64::NEG_INFINITY, f64::INFINITY, A);
    println!("joint drawing 20 W: loop settles at {:.4} degC; formula -b d/(1 - a + b K) = {:.4} degC; bare tip would sag R d = {:.0} degC", yd[399], -B * 20.0 / (1.0 - A + B * K), RTH * 20.0);
    let anti: f64 = (1..400).map(|m| -(0.5 / A).powi(m)).sum();
    println!("anti-causal twin: same z/(z-a), ROC |z| < {:.3}: anti-causal sum at z = 0.5 is {:.6} = {:.6}", A, anti, 0.5 / (0.5 - A));

    assert!(gap < 1e-9);                                    // loop vs pole formula vs contour integral
    assert!((fwd - yz(c(z0, 0.0)).re).abs() < 1e-9);        // summed definition vs closed-form transform
    assert!((y[399] - h1 * R0).abs() < 1e-9);               // long run vs z -> 1
    assert!((lo_k - 1.0 / B).abs() < 1e-9);                 // bisection on the roots vs Jury's b K < 1
    assert!([0.0, 5.0, 12.5, 24.0, 26.0, 30.0].iter().all(|&k| jury(k) == (maxp(k, B) < 1.0 - 1e-12)));
    assert!((yd[399] + B * 20.0 / (1.0 - A + B * K)).abs() < 1e-9);   // disturbance run vs formula
    assert!((cs.hypot(sn) - hz(1.0).abs()).abs() < 1e-6);  // simulated wobble vs H on the unit circle
    assert!((anti - 0.5 / (0.5 - A)).abs() < 1e-9);         // anti-causal sum vs the same fraction
    println!("ALL CHECKS PASS");
}
