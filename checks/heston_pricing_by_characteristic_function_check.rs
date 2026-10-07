// Pricing Heston exactly -- the same check as the .py, std only. Rust std has no complex numbers, so a
// small complex type is written here, with Simpson's rule, the normal CDF, bisection and the random numbers.
use std::f64::consts::PI;
use std::ops::{Add, Div, Mul, Sub};

#[derive(Clone, Copy)]
struct Z { re: f64, im: f64 }
fn z(re: f64, im: f64) -> Z { Z { re, im } }                  // z(a, b) is a + bi
fn c(x: f64) -> Z { z(x, 0.0) }                                // c(x) is x + 0i
impl Add for Z { type Output = Z; fn add(self, o: Z) -> Z { z(self.re + o.re, self.im + o.im) } }
impl Sub for Z { type Output = Z; fn sub(self, o: Z) -> Z { z(self.re - o.re, self.im - o.im) } }
impl Mul for Z { type Output = Z; fn mul(self, o: Z) -> Z { z(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) } }
impl Div for Z { type Output = Z; fn div(self, o: Z) -> Z { let m = o.re * o.re + o.im * o.im; z((self.re * o.re + self.im * o.im) / m, (self.im * o.re - self.re * o.im) / m) } }
impl Z {
    fn exp(self) -> Z { let m = self.re.exp(); z(m * self.im.cos(), m * self.im.sin()) }
    fn ln(self) -> Z { z(self.re.hypot(self.im).ln(), self.im.atan2(self.re)) }
    fn sqrt(self) -> Z {                                   // principal root: real part >= 0
        let t = ((self.re.abs() + self.re.hypot(self.im)) / 2.0).sqrt();
        if self.re >= 0.0 { z(t, self.im / (2.0 * t)) } else { z(self.im.abs() / (2.0 * t), t.copysign(self.im)) }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
const I: Z = Z { re: 0.0, im: 1.0 };
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
type Par = (f64, f64, f64, f64, f64);                      // v0, kappa, theta, xi, rho
const P: Par = (0.04, 2.0, 0.04, 0.3, -0.7);

fn parts(u: Z, t: f64, p: Par, trap: bool, mu: f64) -> [Z; 6] {   // beta, d, g, e^-dT, A, B
    let (_, kap, th, xi, rho) = p;
    let beta = c(kap) - c(rho * xi) * I * u;
    let mut d = (beta * beta + c(xi * xi) * (u * u + I * u)).sqrt();
    if trap { d = c(0.0) - d; }                            // Heston's 1993 layout: the other root
    let g = (beta - d) / (beta + d);
    let e = (c(0.0) - d * c(t)).exp();
    let a = c(mu * t) * I * u + c(kap * th / (xi * xi)) * ((beta - d) * c(t) - c(2.0) * ((c(1.0) - g * e) / (c(1.0) - g)).ln());
    let b = (beta - d) / c(xi * xi) * (c(1.0) - e) / (c(1.0) - g * e);
    [beta, d, g, e, a, b]
}
fn phi(u: Z, t: f64, p: Par, trap: bool, mu: f64) -> Z {  // E[exp(i u ln S_T)], closed form
    let w = parts(u, t, p, trap, mu);
    (I * u * c(S.ln()) + w[4] + w[5] * c(p.0)).exp()
}
fn ph(u: Z, t: f64) -> Z { phi(u, t, P, false, R - Q) }
fn phi_ode(u: f64, t: f64, steps: usize) -> Z {           // same fingerprint: solve B' and A' by RK4
    let (v0, kap, th, xi, rho) = P;
    let uu = c(u);
    let beta = c(kap) - c(rho * xi) * I * uu;
    let f = |b: Z| c(0.5 * xi * xi) * b * b - beta * b - c(0.5) * (uu * uu + I * uu);
    let (h, mut a, mut b) = (t / steps as f64, c(0.0), c(0.0));
    for _ in 0..steps {
        let k1 = f(b); let b2 = b + c(h / 2.0) * k1; let k2 = f(b2); let b3 = b + c(h / 2.0) * k2; let k3 = f(b3); let b4 = b + c(h) * k3;
        a = a + c(h) * (c(R - Q) * I * uu + c(kap * th) * (b + c(2.0) * b2 + c(2.0) * b3 + b4) / c(6.0));
        b = b + c(h / 6.0) * (k1 + c(2.0) * k2 + c(2.0) * k3 + f(b4));
    }
    (I * uu * c(S.ln()) + a + b * c(v0)).exp()
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n { s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h); }
    s * h / 3.0
}
fn integrand(u: f64, t: f64, p: Par, trap: bool, mu: f64, same: bool) -> f64 {
    let top = if same { phi(c(u), t, p, trap, mu) } else { phi(z(u, -1.0), t, p, trap, mu) };
    ((c(0.0) - I * c(u * K.ln())).exp() * (top - c(K) * phi(c(u), t, p, trap, mu)) / (I * c(u))).re
}
fn call(t: f64, p: Par, n: usize, big_u: f64, trap: bool, mu: f64, same: bool, half: f64) -> f64 {
    let i = simpson(|u| integrand(u, t, p, trap, mu, same), 1e-8, big_u, n);
    half * 0.5 * (S * (-Q * t).exp() - K * (-R * t).exp()) + (-R * t).exp() / PI * i
}
fn base(t: f64, trap: bool) -> f64 { call(t, P, 200, 100.0, trap, R - Q, false, 1.0) }
fn lewis(n: usize) -> f64 {                               // road 2: integrate along Im u = -1/2
    let f = S * ((R - Q) * T).exp();
    let g = |u: f64| (I * c(u * (f / K).ln())).exp() * ph(z(u, -0.5), T) / (I * z(u, -0.5) * c(f.ln())).exp();
    S * (-Q * T).exp() - (S * K).sqrt() * (-(R + Q) * T / 2.0).exp() / PI * simpson(|u| g(u).re / (u * u + 0.25), 0.0, 100.0, n)
}
fn prob(shift: f64) -> f64 {                              // P2 (shift 0) or P1 (shift 1), one integral
    let f = |u: f64| ((c(0.0) - I * c(u * K.ln())).exp() * ph(z(u, -shift), T) / (I * c(u) * ph(z(0.0, -shift), T))).re;
    0.5 + simpson(f, 1e-8, 100.0, 200) / PI
}
fn n_cdf(x: f64) -> f64 { 0.5 + simpson(|y| (-0.5 * y * y).exp() / (2.0 * PI).sqrt(), 0.0, x, 2000) }
fn bs(sig: f64) -> f64 {
    let d1 = ((S / K).ln() + (R - Q + 0.5 * sig * sig) * T) / (sig * T.sqrt());
    S * (-Q * T).exp() * n_cdf(d1) - K * (-R * T).exp() * n_cdf(d1 - sig * T.sqrt())
}
fn implied(price: f64) -> f64 {                           // bisection on the Black-Scholes price
    let (mut lo, mut hi) = (0.01, 1.0);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if bs(mid) < price { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn mc(paths: usize, steps: usize, seed: u64) -> (f64, f64, f64, f64) {   // road 3: full-truncation Euler
    let (v0, kap, th, xi, rho) = P;
    let (mut st, dt) = (seed, T / steps as f64);
    let (sr, sw) = ((1.0 - rho * rho).sqrt(), dt.sqrt());
    let (mut s, mut s2, mut hit, mut sh) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..paths {
        let (mut x, mut v) = (S.ln(), v0);
        for _ in 0..steps {
            st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);   // 64-bit LCG
            let u1 = ((st >> 11) as f64 + 0.5) / 9007199254740992.0;
            st = st.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
            let (rad, ang) = ((-2.0 * u1.ln()).sqrt(), 2.0 * PI * ((st >> 11) as f64 / 9007199254740992.0));
            let (z1, z2) = (rad * ang.cos(), rad * ang.sin());                          // Box-Muller
            let vp = if v > 0.0 { v } else { 0.0 };                                     // full truncation
            let sv = vp.sqrt() * sw;
            x += (R - Q - 0.5 * vp) * dt + sv * z1;
            v += kap * (th - vp) * dt + xi * sv * (rho * z1 + sr * z2);
        }
        let st_t = x.exp();
        if st_t > K { s += st_t - K; s2 += (st_t - K) * (st_t - K); hit += 1.0; sh += st_t; }
    }
    let (np, m) = (paths as f64, s / paths as f64);
    ((-R * T).exp() * m, (-R * T).exp() * ((s2 / np - m * m) / np).sqrt(), sh / np / (S * ((R - Q) * T).exp()), hit / np)
}

fn main() {
    let (rq, cc, p1, p2) = (R - Q, base(T, false), prob(1.0), prob(0.0));
    let (mc_c, mc_se, mc_p1, mc_p2) = mc(200000, 100, 12345);
    let (sm_c, sm_se, _, _) = mc(20000, 100, 12345);
    let (col, bs20) = (call(T, (0.04, 2.0, 0.04, 1e-4, 0.0), 200, 100.0, false, rq, false, 1.0), bs(0.2));
    let (good5, bad5, ode5) = (ph(c(4.0), 5.0), phi(c(4.0), 5.0, P, true, rq), phi_ode(4.0, 5.0, 4000));
    let (rat, gmax) = (bad5 / good5, (0..402).map(|k| parts(z(0.5 * (k / 2) as f64, -((k % 2) as f64)), T, P, false, rq)[2].abs()).fold(0.0, f64::max));
    let turn = rat.im.atan2(rat.re);                               // gmax: largest |g| at u and u - i
    let kt = P.1 * P.2 / (P.3 * P.3);
    let w = parts(c(1.0), T, P, false, rq);
    let zs = [("u=1 beta", w[0]), ("u=1 d", w[1]), ("u=1 g", w[2]), ("u=1 e^-dT", w[3]), ("u=1 A", w[4]), ("u=1 B", w[5]),
        ("u=1 phi, closed form", ph(c(1.0), T)), ("u=1 phi, RK4 on the equations", phi_ode(1.0, T, 4000)),
        ("T=5 u=4 phi, closed form", good5), ("T=5 u=4 phi, RK4", ode5), ("T=5 u=4 phi, 1993 layout", bad5)];
    for (name, v) in &zs { println!("{:<34}{:>+14.6}{:>+13.6}i", name, v.re, v.im); }
    println!("{:<34}{:>14.3e}", "|phi| at u=100", ph(c(100.0), T).abs());
    let nohalf = call(T, P, 200, 100.0, false, rq, false, 0.0);
    let rows = [("forward S e^(r-q)T", S * rq.exp()), ("phi(0)", ph(c(0.0), T).re), ("phi(-i)", ph(z(0.0, -1.0), T).re),
        ("largest |g|, u and u-i to 100", gmax), ("T=5 u=4 turn, 1993 vs stable", turn), ("  4 pi (kappa theta/xi^2 - 1)", 4.0 * PI * (kt - 1.0)),
        ("half-gap", 0.5 * (S * (-Q * T).exp() - K * (-R * T).exp())), ("the integral, 200 slices", nohalf * PI / (-R * T).exp()),
        ("e^-rT/pi x integral", nohalf), ("1 HESTON CALL, 200 slices", cc),
        ("  same, 2000 slices to u=200", call(T, P, 2000, 200.0, false, rq, false, 1.0)), ("2 Lewis integral, 2000 slices", lewis(2000)),
        ("3 P1, counted in shares", p1), ("  P1 by simulation", mc_p1), ("  P2, counted in dollars", p2), ("  P2 by simulation", mc_p2),
        ("4 simulation, 200000 paths", mc_c), ("  standard error", mc_se),
        ("5 Heston at xi=1e-4, rho=0", col), ("  Black-Scholes at 20%", bs20), ("implied vol of the Heston call", implied(cc)),
        ("wrong: no half-gap", nohalf), ("wrong: phi(u) in both slots", call(T, P, 200, 100.0, false, rq, true, 1.0)),
        ("wrong: dividend left out of phi", call(T, P, 200, 100.0, false, R, false, 1.0)), ("wrong: Lewis with 200 slices", lewis(200)),
        ("wrong: integral stopped at u=10", call(T, P, 200, 10.0, false, rq, false, 1.0)),
        ("try: xi = 0.6", call(T, (0.04, 2.0, 0.04, 0.6, -0.7), 200, 100.0, false, rq, false, 1.0)),
        ("try: rho = 0", call(T, (0.04, 2.0, 0.04, 0.3, 0.0), 200, 100.0, false, rq, false, 1.0)),
        ("try: 20 slices", call(T, P, 20, 100.0, false, rq, false, 1.0)), ("try: simulation, 20000 paths", sm_c), ("  standard error", sm_se)];
    for (name, v) in rows { println!("{:<34}{:>14.6}", name, v); }
    let row = |label: &str, f: &dyn Fn(u32) -> String, xs: Vec<u32>| println!("{}{}", label, xs.into_iter().map(|x| f(x)).collect::<String>());
    row("chart, years      ", &|t| format!("{:7}", t), (1..11).collect());
    row("chart, stable     ", &|t| format!("{:7.2}", base(t as f64, false)), (1..11).collect());
    row("chart, 1993 layout", &|t| format!("{:7.2}", base(t as f64, true)), (1..11).collect());
    row("chart, u          ", &|u| format!("{:7}", u), (0..21).step_by(2).collect());
    row("chart, integrand  ", &|u| format!("{:7.2}", integrand((u as f64).max(1e-8), T, P, false, rq, false)), (0..21).step_by(2).collect());

    assert!((ph(z(0.0, -1.0), T) - c(S * rq.exp())).abs() < 1e-9, "phi(-i) must be the forward");
    assert!((ph(c(1.0), T) - phi_ode(1.0, T, 4000)).abs() < 1e-10, "closed form vs the equations solved by RK4");
    assert!((good5 - ode5).abs() < 1e-10, "at five years the stable layout matches the equations");
    assert!((bad5 - ode5).abs() > 0.1, "at five years the 1993 layout misses");
    assert!(gmax < 1.0, "stable layout: |g| < 1 keeps the log off its cut");
    assert!((turn - 4.0 * PI * (kt - 1.0)).abs() < 1e-9, "the 1993 error is one whole turn of the log");
    assert!((cc - call(T, P, 2000, 200.0, false, rq, false, 1.0)).abs() < 1e-6, "200 slices must already be converged");
    assert!((cc - lewis(2000)).abs() < 1e-6, "Lewis's integral must agree");
    assert!((mc_c - cc).abs() < 3.0 * mc_se, "simulation within 3 standard errors");
    assert!((mc_p2 - p2).abs() < 3.0 * (p2 * (1.0 - p2) / 200000.0).sqrt(), "exercise chance: integral vs simulation");
    assert!((col - bs20).abs() < 1e-6, "no vol-of-vol: Heston becomes Black-Scholes");
    assert!((bs20 - 9.227005508154).abs() < 1e-8, "the house Black-Scholes call");
    println!("ALL CHECKS PASS");
}
