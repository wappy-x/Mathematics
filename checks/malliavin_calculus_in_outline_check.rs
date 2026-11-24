// Malliavin calculus in outline -- the check behind the card.  Rust std only, no crates.
// A digital call pays $1 if a share, now $100, ends one year above $100 (volatility 20%,
// no interest).  Its delta from the Malliavin weight, E[1{S_T > K} W_T] / (S0 sigma T),
// against the exact phi(d2) / (S0 sigma); then the duality and Clark-Ocone by simulation.
use std::f64::consts::PI;

const S0: f64 = 100.0;
const K: f64 = 100.0;
const SIG: f64 = 0.2;
const T: f64 = 1.0;

struct Rng { s: u64 } // SplitMix64, normals by Box-Muller
impl Rng {
    fn u(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {
        let u1 = self.u();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * self.u()).cos()
    }
}
fn psum(xs: &[f64]) -> f64 { // compensated sum, as Python's sum() does
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for &x in xs {
        let t = s + x;
        if s.abs() >= x.abs() { c += (s - t) + x; } else { c += (x - t) + s; }
        s = t;
    }
    s + c
}
fn pdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } // bell-curve height phi
fn cdf(x: f64) -> f64 { // 1/2 + phi(x)(x + x^3/3 + x^5/15 + ...)
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 {
        k += 1.0; term *= x * x / (2.0 * k + 1.0); total += term;
    }
    0.5 + pdf(x) * total
}
fn d2(s: f64, tau: f64) -> f64 { ((s / K).ln() - 0.5 * SIG * SIG * tau) / (SIG * tau.sqrt()) }
fn value(s: f64, tau: f64) -> f64 { cdf(d2(s, tau)) } // digital's fair value, rate 0
fn share(w: f64, s0: f64) -> f64 { s0 * (-0.5 * SIG * SIG * T + SIG * w).exp() }
fn mse(xs: &[f64]) -> (f64, f64) { // mean and its standard error
    let n = xs.len() as f64; let m = psum(xs) / n;
    let d: Vec<f64> = xs.iter().map(|x| (x - m).powf(2.0)).collect();
    (m, (psum(&d) / (n - 1.0) / n).sqrt())
}
fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let v: Vec<f64> = (0..=n).map(|i| {
        let c = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        c * f(a + i as f64 * h) }).collect();
    h / 3.0 * psum(&v)
}

fn main() {
    // Road 1: closed form.  Road 2: bump the exact price.  Road 3: quadrature of E[1{S_T>K} W_T].
    let z2 = d2(S0, T); let delta = pdf(z2) / (S0 * SIG * T.sqrt());
    let bump = (value(S0 + 0.01, T) - value(S0 - 0.01, T)) / 0.02;
    let wstar = ((K / S0).ln() + 0.5 * SIG * SIG * T) / SIG; // S_T > K exactly when W_T > wstar
    let quad = simpson(|w| w * pdf(w / T.sqrt()) / T.sqrt(), wstar, 10.0, 4000);
    println!("d2 = (ln(S0/K) - sigma^2 T/2)/(sigma sqrt T)  {:.6}", z2);
    println!("phi(d2), bell-curve height                    {:.6}", pdf(z2));
    println!("digital value N(d2), dollars                  {:.6}", value(S0, T));
    println!("S_T > K exactly when W_T >                    {:.6}", wstar);
    println!("delta exact phi(d2)/(S0 sigma sqrt T)         {:.6}", delta);
    println!("delta by bumping the exact price 1 cent       {:.6}", bump);
    println!("E[1{{S_T>K}} W_T] by quadrature                 {:.6}", quad);
    println!("quadrature / (S0 sigma T)                     {:.6}", quad / (S0 * SIG * T));
    assert!((bump - delta).abs() < 1e-7 && (quad - pdf(z2)).abs() < 1e-9);

    // Road 4: Monte Carlo, 102,400 paths; W at half a year and at the year's end.
    let mut rng = Rng { s: 20261123 }; let n_paths = 102400;
    let wh: Vec<f64> = (0..n_paths).map(|_| (0.5 * T).sqrt() * rng.normal()).collect();
    let wt: Vec<f64> = wh.iter().map(|a| a + (0.5 * T).sqrt() * rng.normal()).collect();
    let ind = |w: f64, s0: f64| if share(w, s0) > K { 1.0 } else { 0.0 };
    let mall: Vec<f64> = wt.iter().map(|&w| ind(w, S0) * w / (S0 * SIG * T)).collect();
    let half: Vec<f64> = wh.iter().zip(&wt).map(|(&a, &w)| ind(w, S0) * a / (S0 * SIG * T)).collect();
    let bumped = |h: f64| -> Vec<f64> {
        wt.iter().map(|&w| (ind(w, S0 + h) - ind(w, S0 - h)) / (2.0 * h)).collect() };
    let (b1, b001) = (bumped(1.0), bumped(0.01));
    let (m_val, s_val) = mse(&wt.iter().map(|&w| ind(w, S0)).collect::<Vec<f64>>()); // the value itself, by a road that skips d2
    println!("MC digital value, mean of 1{{S_T>K}}            {:.6} +- {:.6}", m_val, s_val);
    assert!((m_val - value(S0, T)).abs() < 4.0 * s_val);
    for (name, xs) in [("Malliavin weight", &mall), ("bump h = $1, same draws", &b1),
                       ("bump h = 1 cent, same draws", &b001), ("weight W_{T/2} (wrong)", &half)] {
        let (m, s) = mse(xs); println!("MC delta, {:<36}{:.6} +- {:.6}", name, m, s);
    }
    let (m_mall, s_mall) = mse(&mall); let (_, s_b1) = mse(&b1); let (m_half, s_half) = mse(&half);
    println!("MC delta, pathwise (payoff slope is 0)        {:.6} +- {:.6}", 0.0, 0.0);
    println!("paths needed, bump $1 / Malliavin, same error {:.2}", (s_b1 / s_mall).powf(2.0));
    assert!((m_mall - delta).abs() < 4.0 * s_mall && (m_half - delta / 2.0).abs() < 4.0 * s_half);
    assert!(s_b1 > 2.0 * s_mall);
    for n in [400usize, 1600, 6400, 25600, 102400] {
        println!("chart, paths {:6}  Malliavin {:.6}  bump $1 {:.6}", n,
                 psum(&mall[..n]) / n as f64, psum(&b1[..n]) / n as f64);
    }

    // The duality E[F W_T] = E[integral of D_t F dt], with F = W_T^3 and F = S_T.
    let col = |f: &dyn Fn(f64) -> f64| -> Vec<f64> { wt.iter().map(|&w| f(w)).collect() };
    let (c3l, s3l) = mse(&col(&|w| w.powf(4.0))); let (c3r, s3r) = mse(&col(&|w| 3.0 * w * w * T));
    let (csl, ssl) = mse(&col(&|w| share(w, S0) * w)); let (csr, ssr) = mse(&col(&|w| SIG * share(w, S0) * T));
    println!("F = W_T^3: E[F W_T] = {:.4} +- {:.4}   E[3 W_T^2 T] = {:.4} +- {:.4}   exact 3", c3l, s3l, c3r, s3r);
    println!("F = S_T:   E[F W_T] = {:.4} +- {:.4}   E[sigma S_T T] = {:.4} +- {:.4}  exact {:.0}",
             csl, ssl, csr, ssr, S0 * SIG * T);
    assert!((c3l - 3.0 * T * T).abs() < 4.0 * s3l && (csl - S0 * SIG * T).abs() < 4.0 * ssl);

    // Clark-Ocone.  W_T^2 = T + int 2 W_t dW_t; mean of W = int (T - s) dW_s; the digital's shares.
    let mut rng = Rng { s: 7 }; let (p, n) = (2000usize, 500usize);
    let dt = T / n as f64; let (mut miss2, mut avg) = (Vec::new(), Vec::new());
    for _ in 0..p {
        let (mut w, mut a, mut g) = (0.0f64, 0.0f64, 0.0f64);
        for _ in 0..n {
            let dw = dt.sqrt() * rng.normal(); a += w * dt; g += 2.0 * w * dw; w += dw;
        }
        miss2.push((w * w - (T + g)).powf(2.0)); avg.push(a);
    }
    let rms = (psum(&miss2) / p as f64).sqrt(); let (ma, _) = mse(&avg);
    let dev: Vec<f64> = avg.iter().map(|x| (x - ma).powf(2.0)).collect();
    let va = psum(&dev) / (p - 1) as f64;
    let g: Vec<f64> = (1..=n).map(|j| (T - j as f64 * dt).powf(2.0) * dt).collect();
    let vgrid = psum(&g); let se_va = va * (2.0 / (p - 1) as f64).sqrt();
    let exact = (2.0 * T * T / n as f64).sqrt();
    println!("W_T^2 hedge, 500 steps: RMS miss {:.6}, exact sqrt(2/500) {:.6}", rms, exact);
    println!("mean of W: variance {:.4} +- {:.4}, isometry on grid {:.4}, limit 1/3", va, se_va, vgrid);
    assert!((rms - exact).abs() < 0.1 * exact && (va - vgrid).abs() < 4.0 * se_va);
    for (t, s) in [(0.0, 100.0), (0.5, 110.0), (0.5, 100.0), (1.0 - 1.0 / 252.0, 100.0)] {
        let tau = T - t; let co = pdf(d2(s, tau)) / tau.sqrt(); let h = co / (SIG * s);
        let fd = (value(s + 0.01, tau) - value(s - 0.01, tau)) / 0.02;
        println!("t = {:.4}, S = {:.0}: E[D_t F | F_t] = {:.6}, shares {:.6}, bumped slope {:.6}", t, s, co, h, fd);
        assert!((h - fd).abs() < 1e-4 * h + 1e-9);
    }
    println!("ALL CHECKS PASS");
}
