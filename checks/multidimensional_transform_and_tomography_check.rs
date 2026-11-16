// Transforms in two dimensions and the projection-slice theorem -- the same
// check as the Python file, in Rust.  Standard library only, no crates.  Units:
// cm, cycles per cm, mu in 1/cm; shadows are pure numbers, 2-D transforms in cm.
// Illustrative phantom: water disc, radius 10 cm, mu 0.2; bone rod, radius 2 cm,
// centred 5 cm right, mu 0.5 in all.  A complex number is a small struct.
use std::f64::consts::PI;
use std::ops::{Add, Sub};

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl Add for C { type Output = C; fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } } }
impl Sub for C { type Output = C; fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } } }
impl C {
    fn sc(self, k: f64) -> C { C { re: self.re * k, im: self.im * k } }
    fn dv(self, k: f64) -> C { C { re: self.re / k, im: self.im / k } }
    fn abs(self) -> f64 { (self.re * self.re + self.im * self.im).sqrt() }
}
fn re(x: f64) -> C { C { re: x, im: 0.0 } }
const Z: C = C { re: 0.0, im: 0.0 };
type Disc = (f64, f64, f64, f64); // centre x, y; radius; mu added
const DISCS: [Disc; 2] = [(0.0, 0.0, 10.0, 0.2), (5.0, 0.0, 2.0, 0.3)];
const WATER: [Disc; 1] = [(0.0, 0.0, 10.0, 0.2)];
const SIG: f64 = 0.1; // the worked shadow: 0.1 cycles/cm at 30 degrees

fn arrow(x: f64) -> C { C { re: x.cos(), im: x.sin() } } // e^(ix), written out
fn mu(x: f64, y: f64, discs: &[Disc]) -> f64 {
    discs.iter().filter(|&&(a, b, r, _)| (x - a).powi(2) + (y - b).powi(2) < r * r).fold(0.0, |s, d| s + d.3)
}
fn bessel(n: i32, x: f64) -> f64 { // J_n(x) = (1/pi) int_0^pi cos(n t - x sin t) dt, trapezoid
    let (m, mut s) = (400, 0.0);
    for k in 1..m { let t = k as f64 * PI / m as f64; s += (n as f64 * t - x * t.sin()).cos(); }
    (0.5 * (1.0 + (n as f64 * PI).cos()) + s) / m as f64
}
fn series(n: i32, x: f64) -> f64 { // J_n(x) as its power series, a second road
    let (mut s, mut fk, mut fkn) = (0.0, 1.0, (1..=n).map(|v| v as f64).product::<f64>());
    for k in 0..40 {
        if k > 0 { fk *= k as f64; fkn *= (k + n) as f64; }
        s += (if k % 2 == 1 { -1.0 } else { 1.0 }) * (x / 2.0).powf((2 * k + n) as f64) / (fk * fkn);
    }
    s
}
fn disc_hat(r: f64, m: f64, rho: f64) -> f64 { // mu R J1(2 pi R rho) / rho
    if rho == 0.0 { m * PI * r * r } else { m * r * bessel(1, 2.0 * PI * r * rho) / rho }
}
fn fhat(x1: f64, x2: f64, discs: &[Disc]) -> C { // radial transforms, shifted to centres
    let rho = x1.hypot(x2);
    discs.iter().fold(Z, |s, &(a, b, r, m)| s + arrow(-2.0 * PI * (x1 * a + x2 * b)).sc(disc_hat(r, m, rho)))
}
fn shadow(th: f64, s: f64) -> f64 { // line integral of mu along x cos th + y sin th = s
    DISCS.iter().fold(0.0, |t, &(a, b, r, m)| { let d = s - (a * th.cos() + b * th.sin());
        t + if d.abs() < r { 2.0 * m * (r * r - d * d).sqrt() } else { 0.0 } })
}
fn simpson(f: &dyn Fn(f64) -> C, a: f64, b: f64, n: usize) -> C {
    let w = (b - a) / n as f64;
    let mut s = Z;
    for k in 1..n { s = s + f(a + k as f64 * w).sc(if k % 2 == 1 { 4.0 } else { 2.0 }); }
    (f(a) + f(b) + s).sc(w).dv(3.0)
}
fn ft1(th: f64, sig: f64, n: usize, lo: f64, hi: f64) -> C { // 1-D transform of the shadow
    simpson(&|s| arrow(-2.0 * PI * sig * s).sc(shadow(th, s)), lo, hi, n)
}
fn pixels(x1: f64, x2: f64, h: f64, discs: &[Disc]) -> C { // sum over square pixels
    let n = (20.0 / h).round() as usize;
    let mut tot = Z;
    for i in 0..n {
        for j in 0..n {
            let (x, y) = (-10.0 + (i as f64 + 0.5) * h, -10.0 + (j as f64 + 0.5) * h);
            let m = mu(x, y, discs);
            if m != 0.0 { tot = tot + arrow(-2.0 * PI * (x1 * x + x2 * y)).sc(m); }
        }
    }
    tot.sc(h).sc(h)
}
fn recon(px: f64, py: f64, sg: f64, ramp: bool, ns: usize) -> f64 { // filtered back-projection, slices from the formula
    let (nth, w) = (180, sg / ns as f64);
    let sig: Vec<f64> = (0..=ns).map(|k| k as f64 * w).collect();
    let wt: Vec<f64> = (0..=ns).map(|k| (if k == 0 || k == ns { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 })
        * w / 3.0 * if ramp { sig[k] } else { 1.0 }).collect();
    let tab: Vec<Vec<f64>> = DISCS.iter().map(|&(_, _, r, m)| sig.iter().map(|&s| disc_hat(r, m, s)).collect()).collect();
    let mut tot = 0.0;
    for j in 0..nth {
        let (ct, st) = ((j as f64 * PI / nth as f64).cos(), (j as f64 * PI / nth as f64).sin());
        for (d, &(a, b, _, _)) in DISCS.iter().enumerate() {
            let off = (px - a) * ct + (py - b) * st;
            let mut s = 0.0;
            for k in 0..=ns { s += wt[k] * tab[d][k] * (2.0 * PI * sig[k] * off).cos(); }
            tot += s;
        }
    }
    2.0 * tot * PI / nth as f64
}
fn hankel_recon(px: f64, py: f64, sg: f64, ns: usize) -> f64 { // disc by disc: mu (1 - J0(2 pi R sg)) if centred on the point
    DISCS.iter().fold(0.0, |s, &(a, b, r, m)| s + if (px, py) == (a, b) { m * (1.0 - bessel(0, 2.0 * PI * r * sg)) } else { 2.0 * PI
        * simpson(&|q| re(disc_hat(r, m, q) * bessel(0, 2.0 * PI * q * (px - a).hypot(py - b)) * q), 0.0, sg, ns).re })
}
fn snap(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn c(z: C) -> String { format!("{:.6} {} {:.6}i", snap(z.re), if snap(z.im) < 0.0 { "-" } else { "+" }, z.im.abs()) }
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { (PI * u).sin() / (PI * u) } }

fn main() {
    let th = 30f64.to_radians();
    println!("Bessel functions: trapezoid integral | power series");
    for x in [2.0 * PI * 0.2, 2.0 * PI] {
        println!("x = {:.6}: J0 {:.9} | {:.9}, J1 {:.9} | {:.9}", x, bessel(0, x), series(0, x), bessel(1, x), series(1, x));
        assert!((bessel(0, x) - series(0, x)).abs() < 1e-12 && (bessel(1, x) - series(1, x)).abs() < 1e-12);
    }
    for (deg, s) in [(0, 0.0), (0, 5.0), (90, 0.0)] {
        let p = shadow((deg as f64).to_radians(), s);
        println!("shadow at {} deg, s = {:.0} cm: {:.6}, share of X-rays through {:.6}", deg, s, p, (-p).exp());
    }
    // separability: a 4 cm by 2 cm block, mu 1: transform = 4 sinc(4 xi1) x 2 sinc(2 xi2)
    let sep = 4.0 * sinc(4.0 * 0.1) * 2.0 * sinc(2.0 * 0.2);
    let blk = simpson(&|x| simpson(&|y| arrow(-2.0 * PI * (0.1 * x + 0.2 * y)), -1.0, 1.0, 80), -2.0, 2.0, 80);
    println!("block at (0.1, 0.2): {:.6} x {:.6} = {:.6}, 2-D Simpson {}", 4.0 * sinc(0.4), 2.0 * sinc(0.4), sep, c(blk));
    assert!((blk - re(sep)).abs() < 1e-6);
    // rotation invariance and the Hankel transform: the water disc alone
    let hank = 2.0 * PI * simpson(&|r| re(0.2 * bessel(0, 2.0 * PI * 0.1 * r) * r), 0.0, 10.0, 200).re;
    println!("water disc, |xi| = 0.1: mu R J1(2 pi R rho)/rho {:.6}, Hankel integral {:.6}", disc_hat(10.0, 0.2, 0.1), hank);
    assert!((hank - disc_hat(10.0, 0.2, 0.1)).abs() < 1e-7);
    for deg in [0.0f64, 30.0, 90.0] {
        let p = pixels(0.1 * deg.to_radians().cos(), 0.1 * deg.to_radians().sin(), 0.05, &WATER);
        let gap = (p - re(hank)).abs();
        println!("  pixel sum, 0.05 cm pixels, direction {:.0} deg: {}, gap {:.6}", deg, c(p), gap);
        assert!(gap < 0.01);
    }
    // the projection-slice theorem at 30 degrees and 0.1 cycles/cm: three roads
    let u = (SIG * th.cos(), SIG * th.sin());
    let two = fhat(u.0, u.1, &DISCS);
    let turn = arrow(-2.0 * PI * SIG * 5.0 * th.cos());
    println!("water part {:.6}, bone part {:.6}, bone centre along u {:.6} cm, angle {:.6} rad, turn {}, bone turned {}", disc_hat(10.0, 0.2, SIG),
        disc_hat(2.0, 0.3, SIG), 5.0 * th.cos(), 2.0 * PI * SIG * 5.0 * th.cos(), c(turn), c(turn.sc(disc_hat(2.0, 0.3, SIG))));
    println!("slice: 2-D transform at ({:.6}, {:.6}) by formula {}", u.0, u.1, c(two));
    for n in [2000usize, 8000] {
        let one = ft1(th, SIG, n, -10.0, 10.0);
        println!("  1-D transform of the 30 deg shadow, Simpson n = {}: {}, gap {:.6}", n, c(one), (one - two).abs());
        assert!((one - two).abs() < 1e-3);
    }
    let mut p = Z;
    for h in [0.1, 0.05] {
        p = pixels(u.0, u.1, h, &DISCS);
        println!("  2-D pixel sum, {} cm pixels: {}, gap {:.6}", h, c(p), (p - two).abs());
    }
    assert!((p - two).abs() < 0.01);
    // rebuilding the picture: filtered back-projection against the Hankel road
    for (pt, name) in [((5.0, 0.0), "bone centre"), ((0.0, 0.0), "water centre")] {
        for sg in [2.0f64, 4.0, 8.0] {
            let ns = sg.round() as usize; // sigma steps 1/1000 and 1/600
            let (a, b, t) = (recon(pt.0, pt.1, sg, true, 1000 * ns), hankel_recon(pt.0, pt.1, sg, 600 * ns), mu(pt.0, pt.1, &DISCS));
            println!("{}, cut-off {:.0} cycles/cm: back-projection {:.6}, closed form + Hankel {:.6}, true {:.6}, gap {:.6}", name, sg, a, b, t, t - a);
            assert!((a - b).abs() < 2e-7 && (a - t).abs() < 0.05);
        }
    }
    // what breaks, at 30 degrees and 0.1 cycles/cm unless stated
    println!("what breaks: right answer {}", c(two));
    println!("slice along the rays, not the detector | {}", c(fhat(-u.1, u.0, &DISCS)));
    let (lost, cut) = (simpson(&|p| re(80.0 * p.cos() * p.cos() * (20.0 * PI * SIG * p.sin()).cos()), 0.8f64.asin(), PI / 2.0, 400).re, ft1(th, SIG, 8000, -8.0, 8.0));
    println!("detector 16 cm wide, shadow cut at |s| = 8 | {} | Simpson on the cut shadow {}", c(two - re(lost)), c(cut)); // water beyond |s| = 8, exactly
    assert!((cut - (two - re(lost))).abs() < 1e-4);
    println!("water disc's profile given a 1-D transform | {:.6} against {:.6}", snap(2.0 * 0.2 * 10.0 * sinc(2.0 * 10.0 * 0.1)), disc_hat(10.0, 0.2, 0.1));
    println!("back-projection without the ramp, bone centre, cut-off 4 | {:.6} against 0.500000", recon(5.0, 0.0, 4.0, false, 1200));
    let row = |f: &dyn Fn(i32) -> String| (-10..=10).map(|s| f(s)).collect::<Vec<_>>().join(" ");
    println!("chart, s cm       {}", row(&|s| format!("{:6}", s)));
    for deg in [0, 90] {
        println!("chart, shadow {:2}  {}", deg, row(&|s| format!("{:6.3}", shadow((deg as f64).to_radians(), s as f64))));
    }
    println!("figure, 10 px per cm, water centre (190, 200) r 100, bone centre (240, 200) r 20, 30 deg rod centre at s = {:.3} cm, height {:.3}",
        5.0 * th.cos(), shadow(th, 5.0 * th.cos()));
    println!("ALL CHECKS PASS");
}
