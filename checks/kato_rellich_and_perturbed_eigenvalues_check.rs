// Kato-Rellich and perturbed eigenvalues: a 2 x 2 rehearsal, then hydrogen, -Laplacian - 1/r on R^3.
// std only. No eigen-solver: roots, bisection, contour sums and Simpson are written out.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn r(x: f64) -> C { C { re: x, im: 0.0 } }
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}

const V: [[f64; 2]; 2] = [[0.0, 1.0], [1.0, 0.0]];
fn exact_low(e: f64) -> f64 { (3.0 - (1.0 + 4.0 * e * e).sqrt()) / 2.0 } // road 1: the quadratic formula
fn exact_high(e: f64) -> f64 { (3.0 + (1.0 + 4.0 * e * e).sqrt()) / 2.0 }
fn rs2(e: f64) -> f64 { 1.0 + e * V[0][0] + e * e * V[1][0] * V[1][0] / (1.0 - 2.0) } // road 2: Rayleigh-Schroedinger

fn riesz(e: f64, k: usize, c: f64, rho: f64) -> (f64, f64, f64) { // road 3: P = (1/2 pi i) closed integral of (z - M)^-1 dz
    let (mut p, mut rmax) = ([[C::r(0.0); 2]; 2], 0.0f64);
    for j in 0..k {
        let t = 2.0 * PI * j as f64 / k as f64;
        let w = C { re: t.cos(), im: t.sin() };
        let z = C::r(c).add(C::r(rho).mul(w));
        for q in [z.sub(C::r(1.0)), z.sub(C::r(2.0))] { rmax = rmax.max(1.0 / (q.re * q.re + q.im * q.im).sqrt()); } // |R(z, A)|
        let (a, b, d) = (z.sub(C::r(1.0)), C::r(-e), z.sub(C::r(2.0)));
        let det = a.mul(d).sub(b.mul(b));
        let zero = C::r(0.0);
        let inv = [[d.div(det), zero.sub(b).div(det)], [zero.sub(b).div(det), a.div(det)]];
        let f = C::r(rho).mul(w).div(C::r(k as f64));
        for i in 0..2 { for l in 0..2 { p[i][l] = p[i][l].add(inv[i][l].mul(f)); } }
    }
    let tr_p = p[0][0].add(p[1][1]).re;
    let tr_mp = 1.0 * p[0][0].re + e * p[1][0].re + e * p[0][1].re + 2.0 * p[1][1].re;
    (tr_p, tr_mp, rmax)
}

fn series(e: f64, kk: usize) -> f64 { // (3 - sum_k binom(1/2, k) (4e^2)^k) / 2
    let (mut c, mut s, x, mut xk) = (1.0, 0.0, 4.0 * e * e, 1.0);
    for k in 0..=kk {
        s += c * xk;
        c = c * (0.5 - k as f64) / (k as f64 + 1.0);
        xk = xk * x;
    }
    (3.0 - s) / 2.0
}

fn lowest(z: f64, n: usize, k: usize, rmax: f64) -> f64 { // road 2: radial grid, u = r psi, bisection by Sturm count
    let h = rmax / (n as f64 + 1.0);
    let count = |x: f64| -> usize {
        let (mut q, mut c) = (1.0f64, 0usize);
        for i in 1..=n {
            q = 2.0 / (h * h) - z / (i as f64 * h) - x - (if i > 1 { 1.0 / ((h * h) * (h * h)) / q } else { 0.0 });
            if q == 0.0 { q = 1e-300; }
            if q < 0.0 { c += 1; }
        }
        c
    };
    let (mut lo, mut hi) = (-2.0f64, 1.0f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if count(mid) >= k { hi = mid; } else { lo = mid; }
    }
    (lo + hi) / 2.0
}

fn main() {
    let e = 0.1;
    let (tr_p, lam3, rmax) = riesz(e, 64, 1.0, 0.5);
    println!("== 2 x 2: M = [[1, e], [e, 2]], e = 0.1 ==");
    println!("exact lower eigenvalue        {:.6}", exact_low(e));
    println!("second order 1 - e^2          {:.6}", rs2(e));
    println!("Riesz contour: trace P        {:.6}", tr_p);
    println!("Riesz contour: trace MP       {:.6}", lam3);
    println!("max |R(z, A)| on the circle   {:.6}", rmax);
    println!("error of 1 - e^2              {:.6}", exact_low(e) - rs2(e));
    println!("first order only, 1 + e V11   {:.6}", 1.0 + e * V[0][0]);
    println!("wrong sign, divide by 2 - 1   {:.6}", 1.0 + e * e * V[1][0] * V[1][0] / (2.0 - 1.0));
    println!("guaranteed range |e| < 1/(max|R| |V|) = {:.6}", 1.0 / (rmax * 1.0));
    assert!((lam3 - exact_low(e)).abs() < 1e-12 && (tr_p - 1.0).abs() < 1e-12);
    assert!((rmax - 1.0 / 0.5).abs() < 1e-12); // on the circle, |z - 1| = radius 0.5
    assert!((exact_low(e) - rs2(e)).abs() < 2.0 * e.powi(4));
    println!("chart e, lower, 1 - e^2, upper");
    for i in 0..11 {
        let x = i as f64 * 0.05;
        println!("chart {:.2} {:.6} {:.6} {:.6}", x, exact_low(x), rs2(x), exact_high(x));
    }
    println!("power series in e, terms k = 0..K, up to e^(2K)");
    for ee in [0.4, 0.6] {
        println!("e = {:.1}: K=5 {:.6}  K=10 {:.6}  K=20 {:.6}  exact {:.6}", ee, series(ee, 5), series(ee, 10), series(ee, 20), exact_low(ee));
    }
    assert!((series(0.4, 20) - exact_low(0.4)).abs() < 1e-2 && (series(0.6, 20) - exact_low(0.6)).abs() > 1.0);

    let nrm = simpson(&|r: f64| 4.0 * PI * r * r * (-r).exp(), 0.0, 60.0, 4000);
    let kin = simpson(&|r: f64| 4.0 * PI * r * r * 0.25 * (-r).exp(), 0.0, 60.0, 4000); // psi'^2 = e^(-r)/4
    let pot = simpson(&|r: f64| 4.0 * PI * r * (-r).exp(), 0.0, 60.0, 4000); // <psi, psi/r>
    println!("== hydrogen ground state psi = e^(-r/2) ==");
    println!("|psi|^2/pi {:.6}  kinetic/pi {:.6}  <psi,psi/r>/pi {:.6}", nrm / PI, kin / PI, pot / PI);
    println!("Rayleigh quotient (kin - pot)/|psi|^2  {:.6}", (kin - pot) / nrm);
    assert!(((kin - pot) / nrm + 0.25).abs() < 1e-9);
    let psi = |r: f64| (-r / 2.0).exp();
    let (mut res, hd) = (0.0f64, 1e-3);
    for r in [0.5, 1.0, 2.0, 5.0] {
        let d2 = (psi(r + hd) - 2.0 * psi(r) + psi(r - hd)) / (hd * hd);
        let d1 = (psi(r + hd) - psi(r - hd)) / (2.0 * hd);
        res = res.max((-d2 - 2.0 * d1 / r - psi(r) / r + psi(r) / 4.0).abs());
    }
    println!("max |H psi + psi/4| at r = 0.5, 1, 2, 5 (difference quotients)  {:.6}", res);
    assert!(res < 1e-6);

    println!("== relative bound on u = e^(-s r): |u/r| <= 0.5 |Lap u| + 3 |u| ==");
    println!("s       |u/r|      |Lap u|    |u|        bound      |u/r|/|Lap u|  Sobolev, beta = 2, on max|u| = 1");
    for s in [0.5f64, 2.0, 8.0, 32.0] {
        let l = 40.0 / s;
        let ur = simpson(&|r: f64| 4.0 * PI * (-2.0 * s * r).exp(), 0.0, l, 4000).sqrt();
        let lu = simpson(&|r: f64| 4.0 * PI * (-2.0 * s * r).exp() * (s * s * r - 2.0 * s) * (s * s * r - 2.0 * s), 0.0, l, 4000).sqrt();
        let un = simpson(&|r: f64| 4.0 * PI * r * r * (-2.0 * s * r).exp(), 0.0, l, 4000).sqrt();
        for (got, want) in [(ur, (2.0 * PI / s).sqrt()), (lu, (5.0 * PI * s).sqrt()), (un, (PI / (s * s * s)).sqrt())] {
            assert!((got / want - 1.0).abs() < 1e-7);
        }
        let (bound, sob) = (0.5 * lu + 3.0 * un, (lu + 4.0 * un) / (16.0 * PI).sqrt());
        assert!(ur <= bound && 1.0 <= sob);
        println!("{:<7.1} {:<10.6} {:<10.6} {:<10.6} {:<10.6} {:<14.6} {:.6}", s, ur, lu, un, bound, ur / lu, sob);
    }
    println!("trade-off a = sqrt(r0/(2 beta)), b = beta^1.5 sqrt(r0/2) + 1/r0");
    for (r0, beta) in [(1.0f64, 2.0f64), (0.02, 1.0), (0.0002, 1.0)] {
        println!("r0 = {:.4}, beta = {:.1}: a = {:.6}, b = {:.6}", r0, beta, (r0 / (2.0 * beta)).sqrt(), beta * beta.sqrt() * (r0 / 2.0).sqrt() + 1.0 / r0);
    }
    println!("mu = 12: a + b/mu = {:.6}", 0.5 + 3.0 / 12.0);

    println!("== grid truncation, box of radius 40, N points ==");
    let mut prev: Option<f64> = None;
    for n in [100usize, 200, 400, 800] {
        let en = lowest(1.0, n, 1, 40.0);
        let tail = match prev { Some(p) => format!("  error ratio {:.2}", (p + 0.25) / (en + 0.25)), None => String::new() };
        println!("N = {:<4} lowest {:.6}  error {:.6}{}", n, en, en + 0.25, tail);
        prev = Some(en);
    }
    let e2 = lowest(1.0, 800, 2, 40.0);
    println!("N = 800 second level {:.6} (exact -1/16 = -0.062500)", e2);
    assert!((prev.unwrap() + 0.25).abs() < 1e-3 && (e2 + 0.0625).abs() < 1e-3);

    println!("== charge Z = 1 + eps: first order -1/4 - eps <psi,psi/r>/|psi|^2, exact -(1+eps)^2/4 ==");
    for eps in [0.1f64, 1.0] {
        let (first, grid) = (-0.25 - eps * pot / nrm, lowest(1.0 + eps, 800, 1, 40.0));
        println!("eps = {:.1}: first order {:.6}  exact {:.6}  grid N = 800 {:.6}", eps, first, -(1.0 + eps) * (1.0 + eps) / 4.0, grid);
        assert!((grid + (1.0 + eps).powi(2) / 4.0).abs() < 2e-3 * (1.0 + eps).powi(4));
    }
    assert!((pot / nrm - 0.5).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
