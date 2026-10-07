// Greeks of a spread option -- the same check as spread_option_greeks_check.py, in Rust.
// Standard library only, no crates.  The bell-curve area is a series written out here,
// the integral is Simpson's rule, the random numbers come from splitmix64.
use std::f64::consts::PI;
const F1: f64 = 100.0; const F2: f64 = 90.0; const S1: f64 = 0.30; const S2: f64 = 0.25;
const RHO: f64 = 0.5; const T: f64 = 0.5; const R: f64 = 0.05;
fn d() -> f64 { (-R * T).exp() }                               // discount factor to expiry
fn n(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() } // bell-curve height
fn nc(x: f64) -> f64 {                                          // bell-curve area left of x
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() { term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0; }
    0.5 + n(x) * total
}
fn spread_vol(s1: f64, s2: f64, rho: f64) -> f64 { (s1 * s1 + s2 * s2 - 2.0 * rho * s1 * s2).sqrt() }
type Pricer = fn(f64, f64, f64, f64, f64, f64) -> f64;         // f1, f2, K, s1, s2, rho
fn margrabe(f1: f64, f2: f64, _k: f64, s1: f64, s2: f64, rho: f64) -> f64 {   // road 1
    let v = spread_vol(s1, s2, rho) * T.sqrt();
    let d1 = ((f1 / f2).ln() + 0.5 * v * v) / v;
    d() * (f1 * nc(d1) - f2 * nc(d1 - v))
}
fn mg(f1: f64, f2: f64, rho: f64) -> f64 { margrabe(f1, f2, 0.0, S1, S2, rho) }
const NAMES: [&str; 8] = ["delta gasoline", "delta crude", "gamma 11", "gamma 12", "gamma 22",
    "vega gasoline", "vega crude", "corr sensitivity"];
fn greeks(f1: f64, f2: f64, s1: f64, s2: f64, rho: f64) -> [f64; 8] {   // closed-form Greeks
    let s = spread_vol(s1, s2, rho); let v = s * T.sqrt();
    let d1 = ((f1 / f2).ln() + 0.5 * v * v) / v; let d2 = d1 - v;
    let dvs = d() * f1 * n(d1) * T.sqrt();                      // dV / d(spread vol)
    [d() * nc(d1), -d() * nc(d2), d() * n(d1) / (f1 * v), -d() * n(d1) / (f2 * v),
     d() * n(d1) * f1 / (f2 * f2 * v), dvs * (s1 - rho * s2) / s, dvs * (s2 - rho * s1) / s,
     -dvs * s1 * s2 / s]
}
fn kirk(f1: f64, f2: f64, k: f64, s1: f64, s2: f64, rho: f64) -> f64 {  // Kirk's approximation
    let b = f2 / (f2 + k);
    let v = (s1 * s1 - 2.0 * rho * s1 * s2 * b + s2 * s2 * b * b).sqrt() * T.sqrt();
    let d1 = ((f1 / (f2 + k)).ln() + 0.5 * v * v) / v;
    d() * (f1 * nc(d1) - (f2 + k) * nc(d1 - v))
}
fn exact(f1: f64, f2: f64, k: f64, s1: f64, s2: f64, rho: f64) -> f64 {  // road 2: fix crude's shock z
    let given = |z: f64| {                                      // then gasoline is lognormal: Black
        let c2 = f2 * (-0.5 * s2 * s2 * T + s2 * T.sqrt() * z).exp() + k;
        let c1 = f1 * (-0.5 * rho * rho * s1 * s1 * T + rho * s1 * T.sqrt() * z).exp();
        let w = s1 * (1.0 - rho * rho).sqrt() * T.sqrt();
        let e1 = ((c1 / c2).ln() + 0.5 * w * w) / w;
        (c1 * nc(e1) - c2 * nc(e1 - w)) * n(z)
    };
    let (m, a) = (400, -9.0); let h = 18.0 / m as f64;          // Simpson's rule over z
    let mut s = 0.0;
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * given(a + i as f64 * h); }
    d() * (given(a) + given(-a) + s) * h / 3.0
}
fn bumped(p: Pricer, k: f64) -> [f64; 8] {                      // Greeks by bump-and-reprice
    let (h, e) = (0.1, 1e-4);
    let v = |a: f64, b: f64| p(F1 + a, F2 + b, k, S1, S2, RHO);
    [(v(h, 0.0) - v(-h, 0.0)) / (2.0 * h), (v(0.0, h) - v(0.0, -h)) / (2.0 * h),
     (v(h, 0.0) - 2.0 * v(0.0, 0.0) + v(-h, 0.0)) / (h * h),
     (v(h, h) - v(h, -h) - v(-h, h) + v(-h, -h)) / (4.0 * h * h),
     (v(0.0, h) - 2.0 * v(0.0, 0.0) + v(0.0, -h)) / (h * h),
     (p(F1, F2, k, S1 + e, S2, RHO) - p(F1, F2, k, S1 - e, S2, RHO)) / (2.0 * e),
     (p(F1, F2, k, S1, S2 + e, RHO) - p(F1, F2, k, S1, S2 - e, RHO)) / (2.0 * e),
     (p(F1, F2, k, S1, S2, RHO + e) - p(F1, F2, k, S1, S2, RHO - e)) / (2.0 * e)]
}
struct Rng(u64);                                                // splitmix64, then Box-Muller
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { let u = self.unif(); (-2.0 * u.ln()).sqrt() * (2.0 * PI * self.unif()).cos() }
}
fn se(xs: &[f64]) -> f64 {                                      // standard error of the mean
    let n = xs.len() as f64; let mut mu = 0.0; for x in xs { mu += x; } mu /= n;
    let mut ss = 0.0; for x in xs { ss += (x - mu) * (x - mu); } (ss / (n - 1.0) / n).sqrt()
}
fn hedge_sim(rng: &mut Rng, rho_real: f64, paths: usize, steps: usize) -> (f64, f64, f64) {  // road 3
    let dt = T / steps as f64; let (mut pnl, mut raw) = (Vec::with_capacity(paths), Vec::with_capacity(paths));
    for _ in 0..paths {
        let (mut f1, mut f2, mut cash) = (F1, F2, mg(F1, F2, RHO));
        for k in 0..steps {
            let t_left = T - k as f64 * dt;
            let v = spread_vol(S1, S2, RHO) * t_left.sqrt();
            let d1 = ((f1 / f2).ln() + 0.5 * v * v) / v;
            let (a1, a2) = ((-R * t_left).exp() * nc(d1), -(-R * t_left).exp() * nc(d1 - v));
            let g1 = rng.gauss(); let g2 = rho_real * g1 + (1.0 - rho_real * rho_real).sqrt() * rng.gauss();
            let n1 = f1 * (-0.5 * S1 * S1 * dt + S1 * dt.sqrt() * g1).exp();
            let n2 = f2 * (-0.5 * S2 * S2 * dt + S2 * dt.sqrt() * g2).exp();
            cash = cash * (R * dt).exp() + a1 * (n1 - f1) + a2 * (n2 - f2);
            f1 = n1; f2 = n2;
        }
        pnl.push(d() * (cash - (f1 - f2).max(0.0))); raw.push(mg(F1, F2, RHO) - d() * (f1 - f2).max(0.0));
    }
    let mut mu = 0.0; for x in &pnl { mu += x; } mu /= paths as f64;
    (mu, se(&pnl), se(&raw))                                    // hedged mean, hedged se, unhedged se
}
fn main() {
    let (v0, g) = (mg(F1, F2, RHO), greeks(F1, F2, S1, S2, RHO));
    let (gm, gx) = (bumped(margrabe, 0.0), bumped(exact, 0.0));
    let x0 = exact(F1, F2, 0.0, S1, S2, RHO);
    let sv = spread_vol(S1, S2, RHO) * T.sqrt(); let d1 = ((F1 / F2).ln() + 0.5 * sv * sv) / sv;
    let line = |lab: &str, v: &[f64]| { let mut s = format!("{:<32}", lab);
        for x in v { s.push_str(&format!("{:12.6}", x)); } println!("{}", s); };
    println!("house crack: F1 100, F2 90, vols 0.30 0.25, corr 0.5, T 0.5, r 0.05; sim 2000 paths x 63 hedges");
    println!("spread vol sigma                {:12.6}", spread_vol(S1, S2, RHO));
    line("D = e^-rT, v = sigma*sqrt(T)", &[d(), sv]); line("d1, d2", &[d1, d1 - sv]);
    line("N(d1), N(d2), n(d1)", &[nc(d1), nc(d1 - sv), n(d1)]);
    let sg = spread_vol(S1, S2, RHO); line("ln(F1/F2), sigma^2, v^2/2", &[(F1 / F2).ln(), sg * sg, 0.5 * sv * sv]);
    line("dV/dsigma, dsigma/ds1, ds2, drho", &[d() * F1 * n(d1) * T.sqrt(), (S1 - RHO * S2) / sg, (S2 - RHO * S1) / sg, -S1 * S2 / sg]);
    println!("price  Margrabe formula         {:12.6}", v0);
    println!("price  integral over crude      {:12.6}", x0);
    println!("{:<20}{:>12}{:>14}{:>15}", "greek at K = 0", "closed form", "bump formula", "bump integral");
    for i in 0..8 { println!("{:<20}{:12.6}{:14.6}{:15.6}", NAMES[i], g[i], gm[i], gx[i]); }
    let euler = F1 * g[0] + F2 * g[1];
    println!("F1*delta1 + F2*delta2           {:12.6}", euler);
    println!("F1*gamma11 + F2*gamma12         {:12.6}", F1 * g[2] + F2 * g[3]);
    println!("s1*s2*T*F1*F2*gamma12           {:12.6}", S1 * S2 * T * F1 * F2 * g[3]);
    let book = |f1: f64, f2: f64, rho: f64| -(mg(f1, f2, rho) - v0) + g[0] * (f1 - F1) + g[1] * (f2 - F2);
    println!("hedged short book, instant moves (USD per bbl of spread)");
    println!("  both legs +5%                 {:12.6}", book(105.0, 94.5, RHO));
    println!("  both legs +5 USD              {:12.6}", book(105.0, 95.0, RHO));
    println!("  gasoline +5%, crude -5%       {:12.6}", book(105.0, 85.5, RHO));
    let gam = -0.5 * (g[2] * 25.0 + 2.0 * g[3] * 5.0 * -4.5 + g[4] * 4.5 * 4.5);
    println!("  gamma estimate of that        {:12.6}", gam);
    println!("  correlation 0.5 -> 0.3        {:12.6}", book(F1, F2, 0.3));
    println!("  corr sensitivity x 0.2        {:12.6}", g[7] * 0.2);
    let row = |lab: &str, f: &dyn Fn(f64) -> String, xs: &[f64]| {
        let mut s = format!("{:<26}", lab); for &x in xs { s.push_str(&f(x)); } println!("{}", s); };
    let xs = [0.0, 2.0, 4.0, 6.0, 8.0];
    row("chart, move x %", &|x| format!("{:8}", x as i32), &xs);
    row("chart, together +x/+x", &|x| format!("{:8.2}", book(F1 * (1.0 + x / 100.0), F2 * (1.0 + x / 100.0), RHO)), &xs);
    row("chart, apart +x/-x", &|x| format!("{:8.2}", book(F1 * (1.0 + x / 100.0), F2 * (1.0 - x / 100.0), RHO)), &xs);
    let rs: Vec<f64> = (0..6).map(|i| (2 * i) as f64 / 10.0).collect();
    row("chart, correlation", &|x| format!("{:8.1}", x), &rs);
    row("chart, Margrabe K = 0", &|x| format!("{:8.2}", mg(F1, F2, x)), &rs);
    row("chart, Kirk K = 10", &|x| format!("{:8.2}", kirk(F1, F2, 10.0, S1, S2, x)), &rs);
    let (gk, ge) = (bumped(kirk, 10.0), bumped(exact, 10.0));
    println!("{:<20}{:>12}{:>14}", "strike K = 10", "Kirk bump", "exact bump");
    println!("{:<20}{:12.6}{:14.6}", "price", kirk(F1, F2, 10.0, S1, S2, RHO), exact(F1, F2, 10.0, S1, S2, RHO));
    for i in 0..8 { println!("{:<20}{:12.6}{:14.6}", NAMES[i], gk[i], ge[i]); }
    let kbridge = S1 * S2 * T * F1 * F2 * ge[3];
    println!("K=10 s1*s2*T*F1*F2*gamma12      {:12.6}", kbridge);
    let mut rng = Rng(20260927);
    let (m5, e5, u5) = hedge_sim(&mut rng, 0.5, 2000, 63); let (m2, e2, u2) = hedge_sim(&mut rng, 0.2, 2000, 63);
    println!("sim: realised corr 0.5, mean    {:12.6}  se {:.6}  unhedged se {:.6}", m5, e5, u5);
    println!("sim: realised corr 0.2, mean    {:12.6}  se {:.6}  unhedged se {:.6}", m2, e2, u2);
    println!("price at 0.5 minus price at 0.2 {:12.6}", v0 - mg(F1, F2, 0.2));
    let w_d2 = d() * nc(d1 - sv);
    let w_plus = mg(F1, F2, -RHO);
    let w_nodisc = g[0] / d();
    let w_same = book(105.0, 94.5, RHO) - (g[1] + g[0]) * 4.5;
    println!("wrong: N(d2) as gasoline delta  {:12.6}", w_d2);
    println!("wrong: +2 rho s1 s2, price      {:12.6}", w_plus);
    println!("wrong: no discount, delta       {:12.6}", w_nodisc);
    println!("wrong: crude hedge = -delta1    {:12.6}", w_same);
    println!("try: rho 0.9, vega crude        {:12.6}", greeks(F1, F2, S1, S2, 0.9)[6]);
    println!("try: crude 100, delta gasoline  {:12.6}", greeks(F1, 100.0, S1, S2, RHO)[0]);
    assert!((v0 - x0).abs() < 1e-8, "Margrabe vs integral over crude");
    for i in 0..8 { assert!((g[i] - gx[i]).abs() < 2e-4 * g[i].abs().max(1.0), "closed-form Greek vs bumped integral"); }
    assert!((euler - x0).abs() < 1e-8, "deltas rebuild the price (Euler)");
    assert!((kbridge - ge[7]).abs() < 1e-3, "bridge: corr sensitivity = s1 s2 T F1 F2 gamma12, K=10");
    assert!(m5.abs() < 4.0 * e5 + 0.02 && m2 < -1.0 && e5 < 0.1 * u5 && e2 < 0.1 * u2, "hedged book: flat at the priced correlation, loses when legs decouple");
    assert!((w_d2 - g[0]).abs() > 0.05 && (w_plus - v0).abs() > 1.0 && w_same.abs() > 0.1, "each mistake moves a number");
    println!("ALL CHECKS PASS");
}
