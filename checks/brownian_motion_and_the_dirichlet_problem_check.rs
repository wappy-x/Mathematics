// The Dirichlet problem by Brownian motion -- the check behind the card.  std only, no crates.
// A unit disc plate, rim held at 1 on the upper half and 0 on the lower half.  u(x) = chance a
// Brownian path from x leaves through the upper half.  Four roads to u(0, 0.5): the closed form,
// the Poisson integral by Simpson's rule, walk-on-spheres, and time-stepped Brownian motion.
use std::f64::consts::PI;

struct SplitMix64 {
    s: u64,
}
impl SplitMix64 {
    fn unif(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}

fn exact(x: f64, y: f64) -> f64 {
    0.5 + (2.0 * y / (1.0 - x * x - y * y)).atan() / PI
}

fn kernel(x: f64, y: f64, s: f64) -> f64 {
    (1.0 - x * x - y * y) / ((s.cos() - x).powi(2) + (s.sin() - y).powi(2))
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 2000;
    let h = (b - a) / n as f64;
    let mut inner = 0.0;
    for k in 1..n {
        inner += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + inner) * h / 3.0
}

fn wos(x0: f64, y0: f64, eps: f64, n: usize, rng: &mut SplitMix64,
       dist: &dyn Fn(f64, f64) -> f64, read: &dyn Fn(f64, f64) -> f64) -> (f64, f64, f64) {
    let (mut tot, mut sq, mut jumps) = (0.0, 0.0, 0usize);
    for _ in 0..n {
        let (mut x, mut y) = (x0, y0);
        loop {
            let d = dist(x, y);
            if d < eps {
                break;
            }
            let a = 2.0 * PI * rng.unif();
            x += d * a.cos();
            y += d * a.sin();
            jumps += 1;
        }
        let v = read(x, y);
        tot += v;
        sq += v * v;
    }
    let m = tot / n as f64;
    (m, ((sq / n as f64 - m * m) / n as f64).sqrt(), jumps as f64 / n as f64)
}

fn main() {
    let disc = |x: f64, y: f64| 1.0 - x.hypot(y);
    let top = |_x: f64, y: f64| if y > 0.0 { 1.0 } else { 0.0 };
    let (x0, y0) = (0.0f64, 0.5f64);
    let u = exact(x0, y0);
    println!("example: unit disc, rim 1 on top half, 0 on bottom half, start (0, 0.5)");
    println!("centre u(0,0) = {:.6}", exact(0.0, 0.0));
    println!("road 1 closed form 1/2 + atan(1/0.75)/pi = {:.6}", u);
    let r1 = 2.0 / PI * ((1.0 + y0) / (1.0 - y0)).atan();
    println!("road 1b on the axis (2/pi) atan(3) = {:.6}", r1);
    let g = 2.0 * y0 / (1.0 - y0 * y0);
    println!("by hand: 1 - r^2 = {:.6}, 2y/(1 - r^2) = {:.6}, atan = {:.6}, /pi = {:.6}, atan(3) = {:.6}",
             1.0 - y0 * y0, g, g.atan(), g.atan() / PI, 3f64.atan());
    let pint = simpson(&|s| kernel(x0, y0, s), 0.0, PI) / (2.0 * PI);
    println!("road 2 Poisson integral over top half = {:.6}", pint);
    println!("kernel weights: top (0,1) {:.6}, bottom (0,-1) {:.6}, sides (1,0) {:.6}",
             kernel(x0, y0, PI / 2.0), kernel(x0, y0, -PI / 2.0), kernel(x0, y0, 0.0));
    assert!((pint - u).abs() < 1e-9);
    assert!((r1 - u).abs() < 1e-12);
    let off = simpson(&|s| kernel(0.6, 0.3, s), 0.0, PI) / (2.0 * PI);
    println!("off the axis (0.6, 0.3): closed form {:.6}, Poisson {:.6}", exact(0.6, 0.3), off);
    assert!((off - exact(0.6, 0.3)).abs() < 1e-9);
    let mut rng = SplitMix64 { s: 20261123 };
    let (m, se, j) = wos(x0, y0, 1e-4, 100000, &mut rng, &disc, &top);
    println!("road 3 walk-on-spheres, 100000 walks, eps 1e-4: {:.6} +- {:.6}, mean jumps {:.2}", m, se, j);
    assert!((m - u).abs() < 4.0 * se);
    let (mut up, mut tsum) = (0.0f64, 0.0f64);
    let (h, n) = (1e-3f64, 10000usize);
    for _ in 0..n {
        let (mut x, mut y, mut t) = (x0, y0, 0.0f64);
        while x * x + y * y < 1.0 {
            let g = (-2.0 * h * (1.0 - rng.unif()).ln()).sqrt();
            let a = 2.0 * PI * rng.unif();
            x += g * a.cos();
            y += g * a.sin();
            t += h;
        }
        up += if y > 0.0 { 1.0 } else { 0.0 };
        tsum += t;
    }
    let p = up / n as f64;
    let sp = (p * (1.0 - p) / n as f64).sqrt();
    println!("road 4 time steps of 0.001, 10000 paths: {:.6} +- {:.6}, steps per path {:.1}",
             p, sp, tsum / n as f64 / h);
    assert!((p - u).abs() < 4.0 * sp);
    println!("mean exit time: Dynkin (1 - 0.25)/2 = {:.6}, time steps {:.6}",
             (1.0 - x0 * x0 - y0 * y0) / 2.0, tsum / n as f64);
    let mut ring = 0.0;
    for k in 0..3600 {
        let a = 2.0 * PI * k as f64 / 3600.0;
        ring += exact(0.3 * a.cos(), y0 + 0.3 * a.sin());
    }
    ring /= 3600.0;
    println!("mean value: average of u on circle radius 0.3 round (0,0.5) = {:.6}", ring);
    assert!((ring - u).abs() < 1e-9);
    let dh = 1e-3;
    let lap = (exact(dh, y0) + exact(-dh, y0) + exact(0.0, y0 + dh) + exact(0.0, y0 - dh) - 4.0 * u)
        / (dh * dh);
    println!("Laplacian by differences at (0,0.5) = {:.6}", lap);
    assert!(lap.abs() < 1e-4);
    println!("what breaks:");
    println!("  rim treated as uniform: {:.6}", simpson(&|_s| 1.0, 0.0, PI) / (2.0 * PI));
    println!("  nearest rim point (0,1) read off: {:.6}", top(0.0, 1.0));
    let (mb, sb, jb) = wos(x0, y0, 0.3, 100000, &mut rng, &disc, &top);
    println!("  walk-on-spheres with eps 0.3: {:.6} +- {:.6}, mean jumps {:.2}", mb, sb, jb);
    assert!(mb - u > 5.0 * sb);
    println!("hole of radius delta at the centre, held at 1; outer rim 0; start at distance 0.5:");
    for (e, lab) in [(0.1f64, "0.1"), (0.01, "0.01"), (1e-3, "0.001"), (1e-6, "1e-06")] {
        println!("  delta = {}: u = ln 0.5 / ln delta = {:.6}", lab, 0.5f64.ln() / e.ln());
    }
    let (ma, sa, _) = wos(x0, y0, 1e-4, 20000, &mut rng,
                          &|x: f64, y: f64| (x.hypot(y) - 0.1).min(1.0 - x.hypot(y)),
                          &|x: f64, y: f64| if x.hypot(y) < 0.55 { 1.0 } else { 0.0 });
    println!("  delta = 0.1 by walk-on-spheres, 20000 walks: {:.6} +- {:.6}", ma, sa);
    assert!((ma - 0.5f64.ln() / 0.1f64.ln()).abs() < 4.0 * sa);
    println!("chart: u up the vertical diameter, exact and walk-on-spheres (20000 walks each)");
    for k in -3i32..4 {
        let yk = 0.3 * k as f64;
        let (mk, sk, _) = wos(0.0, yk, 1e-4, 20000, &mut rng, &disc, &top);
        println!("  y = {:+.1}: exact {:.6}, walks {:.6} +- {:.6}", yk, exact(0.0, yk), mk, sk);
        assert!((mk - exact(0.0, yk)).abs() < 4.0 * sk + 1e-12);
    }
    let b3 = (1.0 - y0 * y0) / (2.0 * y0) * (1.0 / (1.0 - y0) - 1.0 / (1.0 + y0 * y0).sqrt());
    let i3 = (1.0 - y0 * y0) / 2.0 * simpson(&|c| (1.0 - 2.0 * y0 * c + y0 * y0).powf(-1.5), 0.0, 1.0);
    let mut hit = 0.0f64;
    for _ in 0..20000 {
        let (mut x, mut y, mut z) = (0.0f64, 0.0f64, y0);
        loop {
            let d = 1.0 - (x * x + y * y + z * z).sqrt();
            if d < 1e-4 {
                break;
            }
            let c = 2.0 * rng.unif() - 1.0;
            let a = 2.0 * PI * rng.unif();
            let w = (1.0 - c * c).sqrt();
            x += d * w * a.cos();
            y += d * w * a.sin();
            z += d * c;
        }
        hit += if z > 0.0 { 1.0 } else { 0.0 };
    }
    let q = hit / 20000.0;
    let sq3 = (q * (1.0 - q) / 20000.0).sqrt();
    println!("ball in 3D, top half held at 1, start (0,0,0.5): formula {:.6}, integral {:.6}, walks {:.6} +- {:.6}",
             b3, i3, q, sq3);
    assert!((b3 - i3).abs() < 1e-9);
    assert!((q - b3).abs() < 4.0 * sq3);
    println!("ALL CHECKS PASS");
}
