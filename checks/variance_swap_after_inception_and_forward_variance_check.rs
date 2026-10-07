// Marking a running variance swap, and forward variance between two expiries, by several roads.
const S: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02; const T: f64 = 1.0; const TT: f64 = 0.5; const DAYS: f64 = 252.0;
const KVOL: f64 = 20.0; const NVEGA: f64 = 100000.0;   // strike in vol points; vega notional, $ per vol point
const NVAR: f64 = NVEGA / (2.0 * KVOL);                 // variance notional: $ per variance point
const N: f64 = NVAR * 1e4;                              // the same notional per unit of decimal variance
const KVAR: f64 = 0.04; const DONE: f64 = 0.18; const IMP: f64 = 0.20; // strike; realised so far; implied for the rest
const TAU: f64 = T - TT;                                // time left
const TWO_PI: f64 = 2.0 * std::f64::consts::PI;
fn ncdf(x: f64) -> f64 {                                // own bell-curve area: 0.5 + pdf(x)(x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut s, mut term, mut n) = (x, x, 1.0);
    while term.abs() > 1e-17 * s.abs() { n += 2.0; term *= x * x / n; s += term; }
    0.5 + s * (-0.5 * x * x).exp() / TWO_PI.sqrt()
}
fn bs(s: f64, k: f64, sig: f64, ta: f64, call: bool) -> f64 {
    let v = sig * ta.sqrt(); let d1 = ((s / k).ln() + (R - Q + 0.5 * sig * sig) * ta) / v; let d2 = d1 - v;
    if call { s * (-Q * ta).exp() * ncdf(d1) - k * (-R * ta).exp() * ncdf(d2) }
    else { k * (-R * ta).exp() * ncdf(-d2) - s * (-Q * ta).exp() * ncdf(-d1) }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let (h, mut acc) = ((b - a) / n as f64, 0.0);
    for i in 0..=n { let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; acc += w * f(a + i as f64 * h); }
    h / 3.0 * acc
}
fn strip_pv(s: f64, f0: f64, sig: f64, ta: f64, width: f64, n: usize) -> f64 { // OTM puts and calls weighted 1/K^2
    let g = |x: f64| bs(s, f0 * x.exp(), sig, ta, x > 0.0) / (f0 * x.exp());
    simpson(&g, -width, 0.0, n) + simpson(&g, 0.0, width, n)
}
fn strip_var(sig: f64, ta: f64) -> f64 {               // road 2: fair variance from the strip, no formula for it
    let f0 = S * ((R - Q) * ta).exp();
    2.0 * (R * ta).exp() / ta * strip_pv(S, f0, sig, ta, 12.0 * sig * ta.sqrt(), 400)
}
fn mark(done: f64, imp_var: f64, ta: f64) -> f64 {      // road 1: the marking formula
    (-R * ta).exp() * N * ((T - ta) / T * done.powi(2) + ta / T * imp_var - KVAR)
}
fn p(label: &str, x: f64, d: usize) { println!("{:<44}{:>16.*}", label, d, x); }
struct Rng(u64);
impl Rng { fn u01(&mut self) -> f64 {                   // splitmix64, then a uniform in (0, 1)
    self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (((z ^ (z >> 31)) >> 11) as f64 + 0.5) / 9007199254740992.0
} }
fn main() {
    let d = (-R * TAU).exp();
    p("variance notional, $ per variance point", NVAR, 2);
    p("  the same, $ per unit of decimal variance", N, 0);
    p("discount factor D for the last half-year", d, 6);
    let rem = strip_var(IMP, TAU);
    p("remaining fair variance, strip of options", rem, 6);
    p("realised so far, as total variance", TT / T * DONE.powi(2), 6);
    p("expected total variance at expiry", TT / T * DONE.powi(2) + TAU / T * rem, 6);
    p("  short of the 0.04 strike by", KVAR - (TT / T * DONE.powi(2) + TAU / T * rem), 6);
    let (m1, m2) = (mark(DONE, IMP.powi(2), TAU), mark(DONE, rem, TAU));
    p("1 mark, formula", m1, 2);
    p("2 mark, strip for the rest", m2, 2);
    let mut rng = Rng(20260927);
    let dt = 1.0 / DAYS; let mu = (R - Q - 0.5 * IMP.powi(2)) * dt; let vs = IMP * dt.sqrt();
    let (paths, left, acc) = (20000usize, 126usize, DONE.powi(2) * TT); // 126 trading days left
    let (mut tot, mut tot2) = (0.0, 0.0);
    for _ in 0..paths {
        let mut ss = 0.0;
        for _ in 0..left / 2 {                          // Box-Muller: two bell-curve draws per pair of uniforms
            let rad = (-2.0 * rng.u01().ln()).sqrt(); let ang = TWO_PI * rng.u01();
            let (a, b) = (mu + vs * rad * ang.cos(), mu + vs * rad * ang.sin());
            ss += a * a + b * b;
        }
        let pay = N * ((acc + ss) / T - KVAR);
        tot += pay; tot2 += pay * pay;
    }
    let mean = tot / paths as f64; let se = ((tot2 / paths as f64 - mean * mean) / paths as f64).sqrt();
    p("3 mark, 20000 simulated daily paths", d * mean, 2);
    p("  its standard error", d * se, 2);
    assert!((rem - IMP.powi(2)).abs() < 1e-7, "strip must price the rest at 20% squared");
    assert!((d * mean - m1).abs() < 4.0 * d * se, "simulation must land within 4 standard errors");
    let (t1, t2, v1, v2) = (0.5f64, 1.0f64, 0.18f64, 0.20f64);
    let (w1, w2) = (v1.powi(2) * t1, v2.powi(2) * t2);
    let fv = (w2 - w1) / (t2 - t1);
    p("total variance w1 to half a year", w1, 6); p("total variance w2 to one year", w2, 6);
    p("  six-month swap strike, 18% squared", v1.powi(2), 6);
    p("1 forward variance, formula", fv, 6); p("  forward vol, percent", 100.0 * fv.sqrt(), 2);
    let fs = (t2 * strip_var(v2, t2) - t1 * strip_var(v1, t1)) / (t2 - t1);
    p("2 forward variance, two strips", fs, 6);
    let (z, nz) = (7.0f64, 160usize);                  // road 3: two-step bell-curve integral, then bisection
    let hz = 2.0 * z / nz as f64;
    let grid: Vec<(f64, f64)> = (0..=nz).map(|i| { let x = -z + i as f64 * hz;
        let w = if i == 0 || i == nz { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        (x, hz / 3.0 * w * (-0.5 * x.powi(2)).exp() / TWO_PI.sqrt()) }).collect();
    let call2 = |sf: f64| -> f64 {                      // one-year call: 18% for six months, then sf for six
        let (a, b) = (v1 * t1.sqrt(), sf * (t2 - t1).sqrt());
        let m = S.ln() + (R - Q) * t2 - 0.5 * (a * a + b * b);
        let mut acc = 0.0;
        for &(zz, w) in &grid { for &(y, v) in &grid { acc += w * v * ((m + a * zz + b * y).exp() - 100.0).max(0.0); } }
        (-R * t2).exp() * acc
    };
    let target = bs(S, 100.0, v2, t2, true);
    let (mut lo, mut hi) = (0.01f64, 0.60f64);
    for _ in 0..40 { let mid = 0.5 * (lo + hi); if call2(mid) < target { lo = mid } else { hi = mid } }
    let sf = 0.5 * (lo + hi);
    p("  one-year call at 20%, target", target, 6);
    p("3 forward vol matching that call, percent", 100.0 * sf, 2);
    p("3 forward variance from it", sf * sf, 6);
    assert!((fs - fv).abs() < 1e-6, "two strips must give the formula's forward variance");
    assert!((sf - fv.sqrt()).abs() < 2e-4, "the two-step integral must give the forward vol");
    let (mut lo, mut hi) = (0.0f64, 0.6f64);           // break-even: the vol for the rest at which the mark is zero
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if mark(DONE, mid * mid, TAU) < 0.0 { lo = mid } else { hi = mid } }
    p("break-even vol for the rest, percent", 100.0 * lo, 2);
    assert!((lo - fv.sqrt()).abs() < 1e-9, "break-even must equal the forward vol");
    p("no forward: w1 = 24% squared x 0.5", 0.24f64.powi(2) * 0.5, 6); p("no forward: w2 = 16% squared x 1", 0.16f64.powi(2) * 1.0, 6);
    p("no forward: 24% to 0.5y, 16% to 1y, fwd var", (0.16f64.powi(2) * 1.0 - 0.24f64.powi(2) * 0.5) / 0.5, 6);
    let vega = d * NVAR * TAU / T * 2.0 * 100.0 * IMP;
    let vb = (mark(DONE, strip_var(IMP + 1e-4, TAU), TAU) - mark(DONE, strip_var(IMP - 1e-4, TAU), TAU)) / 2e-2;
    p("vega per vol point, formula", vega, 2);
    p("vega per vol point, strip bumped", vb, 2);
    p("vega per vol point at inception", (-R * T).exp() * NVAR * 2.0 * 100.0 * IMP, 2);
    p("per variance point of realised so far", d * NVAR * TT / T, 2);
    assert!((vb - vega).abs() < 0.05, "vega by bumping the strip");
    let (f0, h) = (S * ((R - Q) * TAU).exp(), 0.5);
    let vfun = |s: f64| N * (TAU / T) * (2.0 / TAU) * strip_pv(s, f0, IMP, TAU, 3.0, 600);
    let cfun = |s: f64| bs(s, 100.0, IMP, TAU, true);
    let g2 = |f: &dyn Fn(f64) -> f64, s: f64| s * s * (f(s + h) - 2.0 * f(s) + f(s - h)) / (h * h);
    let gam = 2.0 * N * d / T;
    p("dollar gamma S^2 x Gamma, formula 2ND/T", gam, 0);
    let k = gam / g2(&cfun, 100.0);                     // calls needed to match the strip's dollar gamma at S = 100
    for s in [80.0f64, 100.0, 120.0] {
        let gs = g2(&vfun, s);
        println!("  S = {:5.1}   strip {:12.0}   {:6.0} calls struck at 100 {:12.0}", s, gs, k, k * g2(&cfun, s));
        assert!((gs / gam - 1.0).abs() < 1e-3, "strip dollar gamma must not depend on S");
    }
    p("break-even daily move, percent", 100.0 * IMP / DAYS.sqrt(), 4);
    for mv in [0.0f64, 1.0, 2.0, 3.0] {
        p(&format!("  day with a {:.0}% move adds to the payoff", mv), N / T * ((mv / 100.0).powi(2) - IMP.powi(2) / DAYS), 2);
    }
    for (lab, v) in [("wrong: average the vols, 19% squared", d * N * (0.19f64.powi(2) - KVAR)),
                     ("wrong: drop the realised half", d * N * (IMP.powi(2) - KVAR)),
                     ("wrong: 18% as the whole year's", d * N * (DONE.powi(2) - KVAR)),
                     ("wrong: no discount", N * (TT / T * DONE.powi(2) + TAU / T * IMP.powi(2) - KVAR)),
                     ("wrong: forward vol from vols, percent", (100.0 * v2 * t2 - 100.0 * v1 * t1) / (t2 - t1))] { p(lab, v, 2); }
    println!("story: month, realised so far %, implied for rest %, mark $");
    for (mo, rv, iv) in [(3, 16.0f64, 20.0f64), (6, 18.0, 20.0), (9, 19.0, 26.0), (12, 20.5, 20.0)] {
        let ta = (12 - mo) as f64 / 12.0; let mk = mark(rv / 100.0, (iv / 100.0).powi(2), ta); // squared-return sums
        assert!((mk - (-R * ta).exp() * N * (((rv / 100.0).powi(2) * mo as f64 / 12.0 + (iv / 100.0).powi(2) * ta) / T - KVAR)).abs() < 1e-6, "sums");
        println!("  month {:2}   {:5.1}   {:5.1}   {:12.2}", mo, rv, iv, mk);
    }
    println!("chart, vol for the rest %      14       16       18       20       22       24       26");
    let xs = [14.0f64, 16.0, 18.0, 20.0, 22.0, 24.0, 26.0];
    println!("chart, payoff if realised $k{}", xs.iter().map(|x| format!("{:9.2}", N * (acc + TAU / T * (x / 100.0).powi(2) - KVAR) / 1000.0)).collect::<String>());
    println!("chart, mark if implied $k   {}", xs.iter().map(|x| format!("{:9.2}", mark(DONE, (x / 100.0).powi(2), TAU) / 1000.0)).collect::<String>());
    println!("ALL CHECKS PASS");
}
