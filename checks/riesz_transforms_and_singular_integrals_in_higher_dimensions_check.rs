// Riesz transforms: for -Lap u = f in the plane, d1 d2 u = R1 R2 f. Source f = exp(-|x|^2).
use std::f64::consts::PI;

const EG: f64 = 0.5772156649015329; // Euler's constant, used only in the area's closed form

fn f(x1: f64, x2: f64) -> f64 { (-(x1 * x1 + x2 * x2)).exp() }
// radial factor: d1 d2 u = cos(t) sin(t) g(r), from solving the radial equation
fn g(r: f64) -> f64 {
    let s = r * r;
    if s < 1e-2 {
        return s / 2.0 - s * s / 3.0 + s.powi(3) / 8.0 - s.powi(4) / 30.0;
    }
    (1.0 - (1.0 + s) * (-s).exp()) / s
}
// closed form of d1 d2 u
fn d(x1: f64, x2: f64) -> f64 {
    let r2 = x1 * x1 + x2 * x2;
    x1 * x2 / r2 * g(r2.sqrt())
}
// kernel of R1 R2: d1 d2 of the point-source potential -ln|x|/(2 pi)
fn k(x1: f64, x2: f64) -> f64 { x1 * x2 / (PI * (x1 * x1 + x2 * x2).powi(2)) }
// Gamma(m/2) for a whole number m >= 1, by Gamma(z + 1) = z Gamma(z)
fn gamma_half(m: u32) -> f64 {
    let (mut v, mut z) = if m % 2 == 0 { (1.0, 1.0) } else { (PI.sqrt(), 0.5) };
    while z < m as f64 / 2.0 - 1e-9 {
        v *= z;
        z += 1.0;
    }
    v
}
// integral of fun(r) r dr for r = e^s, midpoint in s
fn radial(fun: &dyn Fn(f64) -> f64, s0: f64, s1: f64) -> f64 {
    let n = 20000;
    let h = (s1 - s0) / n as f64;
    let mut tot = 0.0;
    for i in 0..n {
        let s = s0 + (i as f64 + 0.5) * h;
        tot += fun(s.exp()) * (2.0 * s).exp();
    }
    tot * h
}
// transform of the cut kernel x_j/(2 pi |x|^3); returns imaginary parts, the real parts cancel
fn riesz_mult(rho: f64, phi: f64) -> (f64, f64) {
    let (eps, rr, nr, nt) = (1e-3, 20.0, 4000, 512);
    let (hr, ht) = ((rr - eps) / nr as f64, 2.0 * PI / nt as f64);
    let (mut a1, mut a2) = (0.0, 0.0);
    for a in 0..nr {
        let r = eps + (a as f64 + 0.5) * hr;
        for b in 0..nt {
            let t = (b as f64 + 0.5) * ht;
            let s = (2.0 * PI * rho * r * (t - phi).cos()).sin() / r;
            a1 += t.cos() * s;
            a2 += t.sin() * s;
        }
    }
    (-a1 * hr * ht / (2.0 * PI), -a2 * hr * ht / (2.0 * PI))
}
// p.v. integral of K(x - y) f(y), taken in rings round x
fn kernel_road(x1: f64, x2: f64) -> f64 {
    let (rmax, nr, nt) = (7.0, 700, 128);
    let (hr, ht) = (rmax / nr as f64, 2.0 * PI / nt as f64);
    let mut tot = 0.0;
    for a in 0..nr {
        let r = (a as f64 + 0.5) * hr;
        let mut ring = 0.0;
        for b in 0..nt {
            let t = (b as f64 + 0.5) * ht;
            ring += t.cos() * t.sin() * f(x1 - r * t.cos(), x2 - r * t.sin());
        }
        tot += ring / (PI * r);
    }
    tot * hr * ht
}
// inverse transform of sign xi1 xi2/|xi|^2 times pi exp(-pi^2 |xi|^2)
fn mult_road(x1: f64, x2: f64, sign: f64) -> f64 {
    let (rmax, nr, nt) = (3.0, 300, 128);
    let (hr, ht) = (rmax / nr as f64, 2.0 * PI / nt as f64);
    let mut tot = 0.0;
    for a in 0..nr {
        let p = (a as f64 + 0.5) * hr;
        for b in 0..nt {
            let t = (b as f64 + 0.5) * ht;
            tot += sign * t.cos() * t.sin() * PI * (-PI * PI * p * p).exp() * (2.0 * PI * p * (x1 * t.cos() + x2 * t.sin())).cos() * p;
        }
    }
    tot * hr * ht
}
fn list(v: &[f64], dp: usize) -> String { v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(", ") }
fn main() {
    let na = 36000; // every hundredth of a degree, 45 included
    let cs: Vec<f64> = (0..na).map(|i| { let t = i as f64 * 2.0 * PI / na as f64; t.cos() * t.sin() }).collect();
    let big = cs.iter().fold(0.0f64, |m, c| m.max(c.abs()));
    let msq = cs.iter().map(|c| c * c).sum::<f64>() / na as f64;
    println!("multiplier -xi1 xi2/|xi|^2 of R1 R2: largest size over 36000 directions {:.6}; mean square {:.6}", big, msq);
    assert!((big - 0.5).abs() < 1e-6 && (msq - 0.125).abs() < 1e-9);
    let s: Vec<f64> = [1, 2, 4].iter().map(|&p| cs.iter().map(|c| c.abs().powi(p)).sum::<f64>() * 2.0 * PI / na as f64).collect();
    println!("ring sums of |cos sin|^p: p=1 {:.6} (2), p=2 {:.6} (pi/4 = {:.6}), p=4 {:.6} (3pi/64 = {:.6})", s[0], s[1], PI / 4.0, s[2], 3.0 * PI / 64.0);
    assert!((s[0] - 2.0).abs() < 1e-6 && (s[1] - PI / 4.0).abs() < 1e-9 && (s[2] - 3.0 * PI / 64.0).abs() < 1e-9);
    let (x, y, h) = (0.3, 0.4, 1e-5);
    let (gx, gy) = ((k(x + h, y) - k(x - h, y)) / (2.0 * h), (k(x, y + h) - k(x, y - h)) / (2.0 * h));
    let grad = (gx * gx + gy * gy).sqrt();
    println!("kernel x1 x2/(pi |x|^4): size constant {:.6}, signed ring sum {:.6}, |grad K| at (0.3, 0.4) {:.6}, 1/(pi r^3) {:.6}, so B <= 8",
        big / PI, cs.iter().sum::<f64>().abs() * 2.0 * PI / na as f64, grad, 1.0 / (PI * 0.5f64.powi(3)));
    assert!((grad - 1.0 / (PI * 0.125)).abs() < 1e-6);
    let c: Vec<f64> = (1..4).map(|n| gamma_half(n + 1) / PI.powf((n + 1) as f64 / 2.0)).collect();
    println!("Riesz constants Gamma((n+1)/2)/pi^((n+1)/2): n=1 {:.6}, n=2 {:.6}, n=3 {:.6}", c[0], c[1], c[2]);
    assert!((gamma_half(3) / PI.powf(1.5) - 1.0 / (2.0 * PI)).abs() < 1e-12);
    let phi = PI / 6.0;
    for rho in [1.0, 2.0] {
        let (m1, m2) = riesz_mult(rho, phi);
        let (lo, hi) = (PI * rho * 1e-3, 1.0 / (PI * rho * 20.0));
        println!("|xi| = {:.0} at 30 deg: kernel road m1 = {:.6} i, m2 = {:.6} i (exact {:.6} i, {:.6} i); m1 m2 = {:.6} (exact {:.6}); cut-off error at most {:.6} + {:.6}",
            rho, m1, m2, -phi.cos(), -phi.sin(), -m1 * m2, -phi.cos() * phi.sin(), lo, hi);
        assert!((m1 + phi.cos()).abs() < lo + hi && (m2 + phi.sin()).abs() < lo + hi);
    }
    let e2 = (-2.0f64).exp();
    println!("by hand at (1, 1): r^2 = 2, e^-2 = {:.6}, 3e^-2 = {:.6}, 1 - 3e^-2 = {:.6}, x1 x2/r^4 = 0.25", e2, 3.0 * e2, 1.0 - 3.0 * e2);
    let (dk, dm, d11) = (kernel_road(1.0, 1.0), mult_road(1.0, 1.0, -1.0), d(1.0, 1.0));
    println!("d1 d2 u at (1, 1): closed form {:.6}, kernel road {:.6} (cut at r = 7, f < {:.1e} there), multiplier road {:.6}",
        d11, dk, (-(7.0 - 2f64.sqrt()).powi(2)).exp(), dm);
    assert!((dk - d11).abs() < 1e-5 && (dm - d11).abs() < 1e-5);
    let i2 = radial(&|r| g(r).powi(2), -12.0, 10.0);
    let (n2f, n2d) = ((PI / 2.0).sqrt(), (s[1] * i2).sqrt());
    println!("p = 2: ||f||_2^2 = pi/2 = {:.6}, ||D||_2^2 = {:.6} (pi/16 = {:.6}); ||f||_2 = {:.6}, ||D||_2 = {:.6}; ratio {:.6}, 1/sqrt(8) = {:.6}; bound 0.5",
        PI / 2.0, s[1] * i2, PI / 16.0, n2f, n2d, n2d / n2f, 1.0 / 8f64.sqrt());
    assert!((n2d / n2f - 1.0 / 8f64.sqrt()).abs() < 1e-6);
    let i4 = radial(&|r| g(r).powi(4), -12.0, 10.0);
    let hg = 0.04;
    let mut grid4 = 0.0;
    for i in 0..400 {
        for j in 0..400 {
            grid4 += d(-8.0 + (i as f64 + 0.5) * hg, -8.0 + (j as f64 + 0.5) * hg).powi(4);
        }
    }
    grid4 *= hg * hg;
    let n4f = (PI / 4.0).powf(0.25);
    let ratio4 = (s[2] * i4).powf(0.25) / n4f;
    println!("p = 4: ||f||_4 = {:.6}; ||D||_4^4 by rings {:.8}, by a 0.04 grid {:.8}; ratio {:.6}; bound (p* - 1)/2 = 1.5", n4f, s[2] * i4, grid4, ratio4);
    assert!((grid4 - s[2] * i4).abs() < 1e-4 * s[2] * i4 && ratio4 < 1.5);
    println!("p = 1: ||f||_1 = pi = {:.6}", PI);
    for rr in [10.0f64, 100.0, 1000.0, 10000.0] {
        let area = s[0] * radial(&g, -12.0, rr.ln());
        println!("area of |D| inside radius {:.0}: rings {:.6}, closed form 2 ln R + gamma - 1 = {:.6}", rr, area, 2.0 * rr.ln() + EG - 1.0);
        assert!((area - (2.0 * rr.ln() + EG - 1.0)).abs() < 1e-5);
    }
    println!("growth per factor of ten in R: 2 ln 10 = {:.6}", 2.0 * 10f64.ln());
    let (hq, mut cb) = (0.002, 0.0);
    for i in 0..500 {
        for j in 0..500 {
            let (a, b) = ((i as f64 + 0.5) * hq, (j as f64 + 0.5) * hq);
            let r2 = a * a + b * b;
            if 0.01 < r2 && r2 < 1.0 {
                cb += k(a, b);
            }
        }
    }
    let ln10 = 10f64.ln();
    println!("checkerboard source sgn(x1 x2) on 0.1 < |x| < 1: d1 d2 u at 0 by a 0.002 grid {:.6}, closed form (2/pi) ln 10 = {:.6}", 4.0 * cb * hq * hq, 2.0 / PI * ln10);
    assert!((4.0 * cb * hq * hq - 2.0 / PI * ln10).abs() < 5e-3);
    for e in 1..7 {
        println!("checkerboard hole eps = 1e-{}: d1 d2 u at 0 = {:.6}, source never above 1", e, 2.0 / PI * 10f64.powi(e).ln());
    }
    println!("wrong sign, multiplier +xi1 xi2/|xi|^2: d1 d2 u at (1, 1) comes out {:.6}", mult_road(1.0, 1.0, 1.0));
    let rs: Vec<f64> = (0..17).map(|i| 0.25 * i as f64).collect();
    println!("chart r: [{}]", list(&rs, 2));
    println!("chart f on the diagonal: [{}]", list(&rs.iter().map(|r| (-r * r).exp()).collect::<Vec<_>>(), 3));
    println!("chart d1 d2 u on the diagonal: [{}]", list(&rs.iter().map(|&r| g(r) / 2.0).collect::<Vec<_>>(), 3));
    println!("ALL CHECKS PASS");
}
