// De Giorgi-Nash-Moser on a checkerboard conductor.  Standard library only.
// Two opposite square tiles conduct 100 S/m, the other two 1 S/m (illustrative).
// Near the shared corner the potential is u = V0 r^a phi(theta).  Roads to a:
// Kellogg's closed form, an RK4 transfer across the tiles found by bisection,
// and the equation's residual by centred differences on the assembled u.
use std::f64::consts::PI;
const HI: f64 = 100.0; // S/m
const LO: f64 = 1.0; // S/m
const V0: f64 = 0.5; // volts on the 1 cm circle

fn alpha_closed(c: f64) -> f64 { 4.0 / PI * (1.0 / c.sqrt()).atan() }

fn half_turn(a: f64, c: f64) -> [[f64; 2]; 2] { // RK4 for (phi, k phi') across a hi tile then a lo tile
    let n = 400;
    let mut cols = [[0.0; 2]; 2];
    for (col, start) in [(1.0, 0.0), (0.0, 1.0)].iter().enumerate() {
        let (mut p, mut q) = *start;
        for k in [c, 1.0] {
            let h = PI / 2.0 / n as f64;
            let f = |p: f64, q: f64| (q / k, -k * a * a * p);
            for _ in 0..n {
                let k1 = f(p, q);
                let k2 = f(p + h / 2.0 * k1.0, q + h / 2.0 * k1.1);
                let k3 = f(p + h / 2.0 * k2.0, q + h / 2.0 * k2.1);
                let k4 = f(p + h * k3.0, q + h * k3.1);
                p += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
                q += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
            }
        }
        cols[col] = [p, q];
    }
    cols // columns of the half-turn matrix
}

fn alpha_transfer(c: f64) -> f64 { // smallest a > 0 with trace(half turn) = -2
    let g = |a: f64| { let m = half_turn(a, c); m[0][0] + m[1][1] + 2.0 };
    let (mut lo, mut hi) = (1e-4, 1e-4);
    while g(hi) > 0.0 { lo = hi; hi *= 1.5; }
    for _ in 0..50 {
        let mid = (lo + hi) / 2.0;
        if g(mid) > 0.0 { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

struct Tiles { a: f64, cot: f64 }
impl Tiles {
    fn phi(&self, t: f64) -> f64 { // angular profile, max 1 at 45 degrees; tiles 0-90 and 180-270 conduct 100
        let (mut t, mut s) = (t.rem_euclid(2.0 * PI), 1.0);
        if t >= PI { t -= PI; s = -1.0; }
        if t <= PI / 2.0 { return s * (self.a * (t - PI / 4.0)).cos(); }
        -s * self.cot * (self.a * (t - 3.0 * PI / 4.0)).sin()
    }
    fn dphi(&self, t: f64) -> f64 { // its slope, by hand from the same pieces
        let (mut t, mut s) = (t.rem_euclid(2.0 * PI), 1.0);
        if t >= PI { t -= PI; s = -1.0; }
        if t <= PI / 2.0 { return -s * self.a * (self.a * (t - PI / 4.0)).sin(); }
        -s * self.cot * self.a * (self.a * (t - 3.0 * PI / 4.0)).cos()
    }
    fn u(&self, x: f64, y: f64) -> f64 { V0 * x.hypot(y).powf(self.a) * self.phi(y.atan2(x)) }
}
fn kk(t: f64) -> f64 { if t.rem_euclid(PI) < PI / 2.0 { HI } else { LO } }

fn simpson<F: Fn(f64) -> f64>(g: F, a: f64, b: f64) -> f64 {
    let n = 400;
    let mut s = g(a) + g(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + (b - a) * i as f64 / n as f64); }
    s * (b - a) / n as f64 / 3.0
}
fn pyexp(s: String) -> String { // Rust's 2.4e-4 written as Python's 2.4e-04
    let (m, e) = s.split_at(s.find('e').unwrap());
    let e: i32 = e[1..].parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn fe(x: f64) -> String { pyexp(format!("{:.4e}", x)) }

fn main() {
    let a = alpha_closed(HI / LO);
    let at = alpha_transfer(HI / LO);
    let (tl, cot) = (Tiles { a, cot: 1.0 / (a * PI / 4.0).tan() }, 1.0 / (a * PI / 4.0).tan());
    println!("tiles 100 S/m and 1 S/m, contrast Lambda/lambda = {:.0}", HI / LO);
    println!("alpha: Kellogg (4/pi) atan(sqrt(lambda/Lambda)) = {:.6}, RK4 transfer + bisection = {:.6}", a, at);
    assert!((a - at).abs() < 1e-7);
    let m = half_turn(a, HI / LO);
    let (p0, q0) = ((a * PI / 4.0).cos(), HI * a * (a * PI / 4.0).sin());
    let (p1, q1) = (m[0][0] * p0 + m[1][0] * q0, m[0][1] * p0 + m[1][1] * q0);
    println!("half turn sends (phi, k phi') = ({:.6}, {:.6}) to ({:.6}, {:.6})", p0, q0, p1, q1);
    assert!((p1 + p0).abs() < 1e-8 && (q1 + q0).abs() < 1e-6); // antiperiodic: phi(t + pi) = -phi(t)
    println!("lo-tile amplitude cot(a pi/4) = {:.6}; phi at 90 deg: hi side {:.6}, lo side {:.6}", cot, p0, cot * (a * PI / 4.0).sin());
    let h = 1e-3; // residual of div(k grad u) inside each tile, cm
    for deg in [30.0f64, 120.0] {
        let (x, y) = (0.5 * deg.to_radians().cos(), 0.5 * deg.to_radians().sin());
        let lap = (tl.u(x + h, y) + tl.u(x - h, y) + tl.u(x, y + h) + tl.u(x, y - h) - 4.0 * tl.u(x, y)) / h / h;
        println!("residual at r = 0.5 cm, {:.0} deg: centred Laplacian {} V/cm2, u = {:+.6} V", deg, pyexp(format!("{:+.1e}", lap)), tl.u(x, y));
        assert!(lap.abs() < 1e-4);
    }
    let y0 = 0.5; // flux across the interface x = 0 at y = 0.5 cm
    let fr = HI * (-3.0 * tl.u(0.0, y0) + 4.0 * tl.u(h, y0) - tl.u(2.0 * h, y0)) / (2.0 * h);
    let fl = LO * (3.0 * tl.u(0.0, y0) - 4.0 * tl.u(-h, y0) + tl.u(-2.0 * h, y0)) / (2.0 * h);
    println!("flux k du/dx across x = 0 at y = 0.5 cm: 100 S/m side {:.6}, 1 S/m side {:.6} (S/m)(V/cm)", fr, fl);
    assert!((fr - fl).abs() < 1e-4 * fr.abs());
    let q4 = |g: &dyn Fn(f64) -> f64| (0..4).map(|j| simpson(g, j as f64 * PI / 2.0, (j + 1) as f64 * PI / 2.0)).sum::<f64>();
    let ip = q4(&|t| kk(t + 1e-12) * tl.phi(t).powi(2));
    let id = q4(&|t| kk(t + 1e-12) * tl.dphi(t + 1e-12).powi(2));
    println!("energy identity: int k phi'^2 = {:.4}, a^2 int k phi^2 = {:.4}", id, a * a * ip);
    assert!((id - a * a * ip).abs() < 1e-9 * id);
    let lhs = V0.powi(2) * (0.5f64.powf(2.0 * a) / (2.0 * a) + simpson(|r| 4.0 * (1.0 - r).powi(2) * r.powf(2.0 * a - 1.0), 0.5, 1.0)) * 2.0 * a * a * ip;
    let rhs = 4.0 * V0.powi(2) * 4.0 * (1.0 - 0.5f64.powf(2.0 * a + 2.0)) / (2.0 * a + 2.0) * ip;
    println!("Caccioppoli, cutoff 1 cm -> 0.5 cm: int k eta^2 |grad u|^2 = {:.4} <= 4 int k |grad eta|^2 u^2 = {:.4} W/m", lhs, rhs);
    assert!(lhs <= rhs);
    let iq = q4(&|t| tl.phi(t).powi(2));
    let rms = (V0 * V0 * iq / (2.0 * a + 2.0) / PI).sqrt();
    let sup = V0 * 0.5f64.powf(a);
    println!("L-infinity bound: sup over 0.5 cm disc {:.6} V, rms over 1 cm disc {:.6} V, ratio {:.4}", sup, rms, sup / rms);
    println!("by hand: atan(0.1) = {:.6} rad, 1 - a = {:.6}, V0 a cot = {:.6} V/cm, 1e4^(1-a) = {:.2}, 1 + 2^-a = {:.6}, 1 - 2^-a = {:.6}",
        0.1f64.atan(), 1.0 - a, V0 * a * cot, 1e4f64.powf(1.0 - a), 1.0 + 0.5f64.powf(a), 1.0 - 0.5f64.powf(a));
    println!("one halving of the radius keeps 2^-a = {:.6} of the oscillation; one tenfold cut keeps {:.6}", 0.5f64.powf(a), 0.1f64.powf(a));
    for r in [1.0f64, 0.1, 0.01, 0.001, 0.0001] {
        let vals: Vec<f64> = (0..720).map(|i| { let t = (i as f64 / 2.0).to_radians(); tl.u(r * t.cos(), r * t.sin()) }).collect();
        let osc = vals.iter().cloned().fold(f64::MIN, f64::max) - vals.iter().cloned().fold(f64::MAX, f64::min);
        println!("osc on circle r = {:.4} cm: sampled {:.6} V, 2 V0 r^a {:.6} V, uniform sheet {:.6} V", r, osc, 2.0 * V0 * r.powf(a), r);
        assert!((osc - 2.0 * V0 * r.powf(a)).abs() < 1e-9);
    }
    for r in [1.0f64, 0.0001] { // field on the 1 S/m tile's bisector
        let (t, e) = (3.0 * PI / 4.0, 1e-6);
        let fd = (tl.u(r * (t + e).cos(), r * (t + e).sin()) - tl.u(r * (t - e).cos(), r * (t - e).sin())) / (2.0 * r * e);
        let fm = V0 * a * cot * r.powf(a - 1.0);
        println!("field at r = {:.4} cm on the 1 S/m bisector: centred diff {:.4}, formula V0 a cot r^(a-1) {:.4} V/cm", r, fd.abs(), fm);
        assert!((fd.abs() - fm).abs() < 1e-4 * fd.abs());
    }
    let (mut smax, mut smin) = (f64::MIN, f64::MAX);
    for rr in 0..51 {
        for d in 0..360 {
            let t = (d as f64).to_radians();
            let v = V0 + tl.u(rr as f64 / 100.0 * t.cos(), rr as f64 / 100.0 * t.sin());
            smax = smax.max(v); smin = smin.min(v);
        }
    }
    let hc = (1.0 + 0.5f64.powf(a)) / (1.0 - 0.5f64.powf(a));
    println!("Harnack, v = 0.5 V + u >= 0 on 1 cm disc: on 0.5 cm disc max {:.6}, min {:.6} V, ratio {:.4}, formula {:.4}", smax, smin, smax / smin, hc);
    assert!((smax / smin - hc).abs() < 1e-6 * hc);
    for c in [1.0f64, 10.0, 100.0, 1e4, 1e8] {
        let a1 = alpha_closed(c);
        let a2 = if c > 1.0 { alpha_transfer(c) } else { a1 }; // contrast 1 is Laplace, u = x: the trace only touches -2
        let tr = if c > 1.0 { format!("{:.6} transfer", a2) } else { "Laplace u = x".to_string() };
        println!("contrast {:9.0}: alpha {:.6} closed, {}; Harnack ratio {:12.4}; osc at 1 um {:.6} V", c, a1, tr, (1.0 + 0.5f64.powf(a1)) / (1.0 - 0.5f64.powf(a1)), 0.0001f64.powf(a1));
        assert!((a1 - a2).abs() < 1e-6);
    }
    let (cc, b, eps) = (4.0f64, 4.0f64, 0.5f64); // iteration lemma, illustrative constants
    let star = cc.powf(-1.0 / eps) * b.powf(-1.0 / (eps * eps));
    println!("iteration Y(j+1) = C b^j Y(j)^(1+eps), C = b = 4, eps = 1/2: threshold C^(-1/eps) b^(-1/eps^2) = {}, decay there b^(1/eps) = {:.0} per step", fe(star), b.powf(1.0 / eps));
    for f in [0.5f64, 1.0, 2.0] {
        let (mut y, mut ys) = (f * star, Vec::new());
        for j in 0..13 { ys.push(y); y = cc * b.powi(j) * y.powf(1.0 + eps); }
        println!("  start {:.1} x threshold: Y0 {}, Y4 {}, Y8 {}, Y12 {}", f, fe(ys[0]), fe(ys[4]), fe(ys[8]), fe(ys[12]));
        if f == 1.0 { assert!((ys[12] - star * b.powf(-12.0 / eps)).abs() < 1e-9 * ys[12]); }
        if f == 2.0 { assert!(ys[12] > ys[0]); }
        if f == 0.5 { assert!(ys[12] < star * b.powf(-12.0 / eps)); }
    }
    let j = |v: Vec<String>| v.join(", ");
    println!("chart r mm: {}", j((0..21).map(|i| if i % 2 == 0 { format!("{}", i / 2) } else { format!("{:.1}", i as f64 / 2.0) }).collect()));
    println!("chart checkerboard u V: {}", j((0..21).map(|i| format!("{:.3}", V0 * (i as f64 / 20.0).powf(a))).collect()));
    println!("chart uniform u V: {}", j((0..21).map(|i| format!("{:.3}", V0 * i as f64 / 20.0)).collect()));
    println!("chart phi, 0..360 deg by 15: {}", j((0..25).map(|i| format!("{:.3}", (tl.phi((15.0 * i as f64).to_radians()) * 1000.0).round() / 1000.0 + 0.0)).collect()));
    println!("ALL CHECKS PASS");
}
