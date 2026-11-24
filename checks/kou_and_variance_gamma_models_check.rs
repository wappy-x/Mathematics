// Kou and variance gamma -- the same check as the Python, in Rust.  No crates.  Written out here: complex
// exp and log, Marsaglia's bell-curve series, COS, the inversion integral, Simpson, the house recurrence, Box-Muller.
use std::f64::consts::PI;
const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0;
const SIG: f64 = 0.20; const LAM: f64 = 1.0; const P: f64 = 0.4; const E1: f64 = 10.0; const E2: f64 = 5.0;  // Kou
const VS: f64 = 0.20; const NU: f64 = 0.20; const TH: f64 = -0.14;                                          // VG
const SEED: u64 = 20261123; const PATHS: usize = 1000000; const STRIKES: [f64; 7] = [70.0, 80.0, 90.0, 100.0, 110.0, 120.0, 130.0];
#[derive(Clone, Copy)] struct C { re: f64, im: f64 }  fn c(re: f64, im: f64) -> C { C { re, im } }
impl C {
    fn add(self, o: C) -> C { c(self.re + o.re, self.im + o.im) }
    fn sub(self, o: C) -> C { c(self.re - o.re, self.im - o.im) }
    fn mul(self, o: C) -> C { c(self.re * o.re - self.im * o.im, self.re * o.im + self.im * o.re) }
    fn sc(self, a: f64) -> C { c(a * self.re, a * self.im) }
    fn exp(self) -> C { let m = self.re.exp(); c(m * self.im.cos(), m * self.im.sin()) }
    fn ln(self) -> C { c(self.re.hypot(self.im).ln(), self.im.atan2(self.re)) }
}
fn cdiv(a: f64, b: C) -> C { c(a * b.re / (b.re * b.re + b.im * b.im), -a * b.im / (b.re * b.re + b.im * b.im)) }
fn n_cdf(x: f64) -> f64 {                   // area left of x, Marsaglia's series
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t { t = s; i += 2.0; b *= x * x / i; s = t + b; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn bs(k: f64, sig: f64, t: f64) -> f64 {    // Black-Scholes call, spot S, yield Q
    let v = sig * t.sqrt(); let d1 = ((S / k).ln() + (R - Q + 0.5 * sig * sig) * t) / v;
    S * (-Q * t).exp() * n_cdf(d1) - k * (-R * t).exp() * n_cdf(d1 - v)
}
fn zeta(p: f64) -> f64 { p * E1 / (E1 - 1.0) + (1.0 - p) * E2 / (E2 + 1.0) - 1.0 }   // E[e^J] - 1
fn omega(th: f64, nu: f64) -> f64 { (1.0 - th * nu - 0.5 * VS * VS * nu).ln() / nu }
#[derive(Clone, Copy)] struct M { vg: bool, lam: f64, p: f64, comp: Option<f64>, th: f64, nu: f64, w: Option<f64> }
const KOU: M = M { vg: false, lam: LAM, p: P, comp: None, th: TH, nu: NU, w: None };
const VG: M = M { vg: true, ..KOU };
fn lnmgf(m: &M, z: C, t: f64) -> C {        // ln E[e^(zY)], Y = ln(S_T / S), z complex
    if m.vg {
        let (w, tz) = (m.w.unwrap_or(omega(m.th, m.nu)), z.sc(m.th * m.nu)); let inner = c(1.0 - tz.re, -tz.im).sub(z.sc(0.5 * VS * VS * m.nu).mul(z));
        return z.sc((R - Q + w) * t).sub(inner.ln().sc(t / m.nu));
    }
    let mu = R - Q - 0.5 * SIG * SIG - m.lam * m.comp.unwrap_or(zeta(m.p));
    let jump = cdiv(m.p * E1, c(E1 - z.re, -z.im)).add(cdiv((1.0 - m.p) * E2, c(E2 + z.re, z.im)));
    z.sc(mu).add(z.sc(0.5 * SIG * SIG).mul(z)).add(c(jump.re - 1.0, jump.im).sc(m.lam)).sc(t)
}
fn cos_call(m: &M, k: f64, t: f64, modes: usize) -> f64 {   // road 1: COS put, then parity
    let (a, b) = (-6.0f64, 6.0f64); let (l, d, mut tot) = (b - a, f64::min(b, (k / S).ln()), 0.0);
    for n in 0..(if d > a { modes } else { 0 }) {
        let w = n as f64 * PI / l;
        let fnn = 2.0 / l * lnmgf(m, c(0.0, w), t).sub(c(0.0, w * a)).exp().re;
        let psi = if n == 0 { d - a } else { (w * (d - a)).sin() / w };
        let chi = (d.exp() * ((w * (d - a)).cos() + w * (w * (d - a)).sin()) - (a as f64).exp()) / (1.0 + w * w);
        tot += (if n == 0 { 0.5 } else { 1.0 }) * fnn * 2.0 / l * (k * psi - S * chi);
    }
    (-R * t).exp() * l / 2.0 * tot + S * (-Q * t).exp() - k * (-R * t).exp()
}
fn gp_call(m: &M, k: f64, t: f64) -> f64 {  // road 2: invert for the two chances
    let (h, x, g1, mut p1, mut p2) = (0.02, (k / S).ln(), lnmgf(m, c(1.0, 0.0), t).re, 0.0, 0.0);
    for j in 0..5000 {                      // Re[w / (iu)] = Im(w) / u
        let u = (j as f64 + 0.5) * h;
        p2 += c(0.0, -u * x).add(lnmgf(m, c(0.0, u), t)).exp().im / u;
        p1 += c(0.0, -u * x).add(lnmgf(m, c(1.0, u), t)).sub(c(g1, 0.0)).exp().im / u;
    }
    S * (g1 - R * t).exp() * (0.5 + p1 * h / PI) - k * (-R * t).exp() * (0.5 + p2 * h / PI)
}
fn simpson<F: Fn(f64) -> f64>(f: F, lo: f64, hi: f64, n: usize) -> f64 {
    let h = (hi - lo) / n as f64;
    h / 3.0 * (0..=n).fold(0.0, |s, i| s + (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * h))
}
fn vg_mix(k: f64) -> (f64, f64) {           // road 3: Black-Scholes on each gamma clock
    let (shape, w) = (T / NU, omega(TH, NU));
    let dens = |g: f64| if g > 0.0 { g.powf(shape - 1.0) * (-g / NU).exp() / (24.0 * NU.powf(shape)) } else { 0.0 };  // 24 = 4! = Gamma(T/NU): T/NU = 5 only
    let fwd = |g: f64| S * ((R - Q + w) * T + TH * g + 0.5 * VS * VS * g).exp();
    let call = |g: f64| { let v = VS * g.sqrt(); let d1 = ((fwd(g) / k).ln() + 0.5 * v * v) / v;
                          (-R * T).exp() * (fwd(g) * n_cdf(d1) - k * n_cdf(d1 - v)) };
    (simpson(|g| if g > 0.0 { dens(g) * call(g) } else { 0.0 }, 0.0, 8.0, 4000), simpson(|g| dens(g) * fwd(g), 0.0, 8.0, 4000))
}
fn cumulants(vg: bool, t: f64) -> [f64; 3] {   // closed form: variance, skew, excess kurtosis
    let m = |n: f64, f: f64| LAM * f * (P / E1.powf(n) + (1.0 - P) * (-1.0f64).powf(n) / E2.powf(n));   // f = n!
    let (c2, c3, c4) = if !vg { ((SIG * SIG + m(2.0, 2.0)) * t, m(3.0, 6.0) * t, m(4.0, 24.0) * t) } else {
        ((VS.powf(2.0) + TH.powf(2.0) * NU) * t, (2.0 * TH.powf(3.0) * NU.powf(2.0) + 3.0 * VS.powf(2.0) * TH * NU) * t,
         (3.0 * VS.powf(4.0) * NU + 12.0 * VS.powf(2.0) * TH.powf(2.0) * NU.powf(2.0) + 6.0 * TH.powf(4.0) * NU.powf(3.0)) * t) };
    [c2, c3 / c2.powf(1.5), c4 / c2.powf(2.0)]
}
fn fd_cumulants(m: &M) -> [f64; 3] {        // differences of ln E[e^(zY)] at real z
    let (h, js) = (0.01, [-2.0, -1.0, 0.0, 1.0, 2.0]);
    let g: Vec<f64> = js.iter().map(|j: &f64| lnmgf(m, c(j * h, 0.0), T).re).collect();
    let (c2, c3) = ((g[3] - 2.0 * g[2] + g[1]) / h.powf(2.0), (g[4] - 2.0 * g[3] + 2.0 * g[1] - g[0]) / (2.0 * h.powf(3.0)));
    [c2, c3 / c2.powf(1.5), (g[4] - 4.0 * g[3] + 6.0 * g[2] - 4.0 * g[1] + g[0]) / h.powf(4.0) / c2.powf(2.0)]
}
fn implied(price: f64, k: f64, t: f64) -> f64 {   // bisection: Black-Scholes rises with vol
    let (mut lo, mut hi) = (1e-4, 3.0);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if bs(k, mid, t) < price { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn uniform(state: &mut u64) -> f64 {        // the house recurrence
    *state = (1664525 * *state + 1013904223) % (1u64 << 32); (*state as f64 + 0.5) / 4294967296.0
}
fn simulate(vg: bool) -> [f64; 7] {         // road 4: real jumps, or a real gamma clock
    let (mut state, disc, e0, mut sums) = (SEED, (-R * T).exp(), (-LAM * T).exp(), [0.0f64; 8]);
    for _ in 0..PATHS {
        let (u, v) = (uniform(&mut state), uniform(&mut state));
        let z = (-2.0 * u.ln()).sqrt() * (2.0 * PI * v).cos();         // Box-Muller, cosine half
        let x = if !vg {
            let (mut x, mut prod) = ((R - Q - 0.5 * SIG * SIG - LAM * zeta(P)) * T + SIG * T.sqrt() * z, 1.0);
            loop {                          // Knuth's Poisson count, one jump per pass; side and size from one uniform
                prod *= uniform(&mut state); if prod <= e0 { break; }
                let u = uniform(&mut state); x += if u < P { -(u / P).ln() / E1 } else { ((u - P) / (1.0 - P)).ln() / E2 };
            }
            x
        } else {
            let mut g = 0.0;
            for _ in 0..5 { g -= NU * uniform(&mut state).ln(); }      // gamma clock: T/NU = 5 waits, mean nu
            (R - Q + omega(TH, NU)) * T + TH * g + VS * g.sqrt() * z };
        let (pay, st) = (disc * (S * x.exp() - K).max(0.0), disc * S * x.exp());
        for (i, v) in [pay, pay * pay, st, st * st, x, x * x, x * x * x, x * x * x * x].iter().enumerate() { sums[i] += v; }
    }
    let m: Vec<f64> = sums.iter().map(|v| v / PATHS as f64).collect();
    let (var, c3) = (m[5] - m[4].powf(2.0), m[6] - 3.0 * m[4] * m[5] + 2.0 * m[4].powf(3.0));
    let c4 = m[7] - 4.0 * m[4] * m[6] + 6.0 * m[4].powf(2.0) * m[5] - 3.0 * m[4].powf(4.0);
    [m[0], ((m[1] - m[0].powf(2.0)) / PATHS as f64).sqrt(), m[2], ((m[3] - m[2].powf(2.0)) / PATHS as f64).sqrt(),
     var, c3 / var.powf(1.5), c4 / var.powf(2.0) - 3.0]
}
fn row(name: &str, v: f64) { println!("{:<46}{:>12.6}", name, v); }
fn main() {
    println!("house: S 100, K 100, r 5%, q 2%, T 1; Kou: sigma 0.20, lambda 1, p 0.4, eta1 10, eta2 5; VG: sigma 0.20, nu 0.20, theta -0.14");
    for (name, v) in [("Kou up part, p eta1/(eta1 - 1)", P * E1 / (E1 - 1.0)), ("Kou down part, (1 - p) eta2/(eta2 + 1)", (1.0 - P) * E2 / (E2 + 1.0)),
                      ("Kou compensator zeta", zeta(P)), ("Kou drift r - q - sigma^2/2 - lambda zeta", R - Q - 0.5 * SIG * SIG - LAM * zeta(P)),
                      ("VG inside the log, 1 - theta nu - sigma^2 nu/2", 1.0 - TH * NU - 0.5 * VS * VS * NU),
                      ("VG martingale correction omega", omega(TH, NU)), ("VG drift r - q + omega", R - Q + omega(TH, NU))] { row(name, v); }
    println!("E[S_T]/S from the exponent at z = 1: Kou {:.6}, VG {:.6}; forward factor e^(r - q)T {:.6}",
             lnmgf(&KOU, c(1.0, 0.0), T).exp().re, lnmgf(&VG, c(1.0, 0.0), T).exp().re, ((R - Q) * T).exp());
    let (sk, sv) = (simulate(false), simulate(true)); println!("model  how        variance      skew  ex. kurt");
    for (name, vg, sim, m) in [("kou", false, sk, KOU), ("vg", true, sv, VG)] {
        for (how, cc) in [("closed", cumulants(vg, T)), ("differ", fd_cumulants(&m)), ("simul", [sim[4], sim[5], sim[6]]),
                          ("3 months", cumulants(vg, 0.25))] { println!("{:<5}  {:<8} {:>9.6}  {:>8.4}  {:>8.4}", name, how, cc[0], cc[1], cc[2]); }
    }
    println!("COS modes      Kou call     VG call");
    for mm in [32, 64, 128, 256, 512] { println!("{:>9}  {:>10.6}  {:>10.6}", mm, cos_call(&KOU, K, T, mm), cos_call(&VG, K, T, mm)); }
    let (ck, cv, (cm, fm), gk, gv) = (cos_call(&KOU, K, T, 512), cos_call(&VG, K, T, 512), vg_mix(K), gp_call(&KOU, K, T), gp_call(&VG, K, T));
    let (vk, vv) = (cumulants(false, T)[0].sqrt(), cumulants(true, T)[0].sqrt());
    let (onek, onev, fwdl) = (format!("wrong: one vol for Kou, {:.2}%", vk * 100.0), format!("wrong: one vol for VG, {:.2}%", vv * 100.0), format!("Kou simulated e^-rT S_T (S e^-qT {:.6})", S * (-Q * T).exp()));
    for (name, v) in [("Kou road 1  COS, 512 modes", ck), ("Kou road 2  inversion integral", gk),
                      ("Kou road 4  simulation", sk[0]), ("            standard error", sk[1]),
                      (fwdl.as_str(), sk[2]), ("            standard error", sk[3]),
                      ("VG  road 1  COS, 512 modes", cv), ("VG  road 2  inversion integral", gv), ("VG  road 3  gamma-clock Black-Scholes", cm),
                      ("VG  road 4  simulation", sv[0]), ("            standard error", sv[1]),
                      ("VG simulated e^-rT S_T", sv[2]), ("            standard error", sv[3]), ("VG gamma clock: forward averaged", fm),
                      ("Kou with lambda = 0 (house Black-Scholes)", cos_call(&M { lam: 0.0, ..KOU }, K, T, 512)),
                      ("wrong: Kou, no compensator", gp_call(&M { comp: Some(0.0), ..KOU }, K, T)),
                      ("wrong: Kou, compensator from mean log jump", gp_call(&M { comp: Some(P / E1 - (1.0 - P) / E2), ..KOU }, K, T)),
                      ("wrong: VG, no omega", gp_call(&M { w: Some(0.0), ..VG }, K, T)),
                      ("wrong: VG, omega with the sign flipped", gp_call(&M { w: Some(-omega(TH, NU)), ..VG }, K, T)),
                      ("wrong: VG no omega, call by parity", cos_call(&M { w: Some(0.0), ..VG }, K, T, 512)),
                      (onek.as_str(), bs(K, vk, T)), (onev.as_str(), bs(K, vv, T))] { row(name, v); }
    let iv = |m: &M| STRIKES.iter().map(|&k| implied(cos_call(m, k, T, 512), k, T)).collect::<Vec<f64>>();
    let (ivk, ivv) = (iv(&KOU), iv(&VG));
    let line = |v: &Vec<f64>| v.iter().map(|x| format!("{:>8.2}", x * 100.0)).collect::<String>();
    println!("strike         {}", STRIKES.iter().map(|k| format!("{:>8.0}", k)).collect::<String>());
    println!("Kou implied %  {}\nVG implied %   {}", line(&ivk), line(&ivv));
    let (th0, ks) = (M { th: 0.0, ..VG }, [-0.2f64, 0.0, 0.2].map(|x| S * ((R - Q) * T + x).exp()));   // no clock drift; strikes even in log terms around F
    let ivs: Vec<f64> = ks.iter().map(|&k| implied(cos_call(&th0, k, T, 512), k, T) * 100.0).collect();
    println!("try: Kou p = 0.6 call {:.6}; VG theta = 0 implied % at {:.2}, {:.2}, {:.2}: {:.2}, {:.2}, {:.2}", cos_call(&M { p: 0.6, ..KOU }, K, T, 512), ks[0], ks[1], ks[2], ivs[0], ivs[1], ivs[2]);
    assert!((cos_call(&M { lam: 0.0, ..KOU }, K, T, 512) - 9.227005508154).abs() < 1e-8, "no jumps: the house call");
    assert!((gk - ck).abs() < 1e-7 && (gv - cv).abs() < 1e-7, "inversion integral lands on COS");
    assert!((cm - cv).abs() < 1e-7 && (fm - S * ((R - Q) * T).exp()).abs() < 1e-7, "gamma clock lands on COS and on the forward");
    for (vg, sim, cc, m) in [(false, sk, ck, KOU), (true, sv, cv, VG)] {
        assert!((sim[0] - cc).abs() < 3.0 * sim[1] && (sim[2] - S * (-Q * T).exp()).abs() < 3.0 * sim[3], "simulation backs the transform");
        let (a, b) = (cumulants(vg, T), fd_cumulants(&m)); assert!((0..3).all(|i| (a[i] - b[i]).abs() < 1e-3), "cumulants from the exponent");
        assert!((sim[5] - a[1]).abs() < 0.05 && (sim[6] - a[2]).abs() < 0.3, "simulated shape");
    }
    assert!(ivk[0] > ivk[3] && ivk[3] > ivk[6] && ivv[0] > ivv[3] && ivv[3] > ivv[6], "both lean to the left");
    println!("ALL CHECKS PASS");
}
