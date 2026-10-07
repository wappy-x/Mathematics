// CMS convexity adjustment -- the check behind the card.  Rust std only.
// One CMS coupon: the 10-year annual swap rate fixed in 5 years, paid 1 year later.
// Roads: (1) static replication in swaptions, (2) direct integral over the rate,
// (3) Monte Carlo with a hand-made generator, (4) the linear quick formula.
use std::f64::consts::PI;

const F: f64 = 0.045;
const SIG: f64 = 0.20;
const T: f64 = 5.0;
const N_SWAP: i32 = 10;
const L: f64 = 10_000_000.0;

fn n_cdf(x: f64) -> f64 { // normal CDF from its Taylor series
    if x > 9.0 { return 1.0; }
    if x < -9.0 { return 0.0; }
    let (mut term, mut total, mut k) = (x, x, 0.0);
    while term.abs() > 1e-17 * total.abs().max(1.0) {
        k += 1.0;
        term *= x * x / (2.0 * k + 1.0);
        total += term;
    }
    0.5 + (-x * x / 2.0).exp() / (2.0 * PI).sqrt() * total
}
fn phi(z: f64) -> f64 { (-z * z / 2.0).exp() / (2.0 * PI).sqrt() }
fn g(s: f64) -> f64 { (1..=N_SWAP).map(|i| (1.0 + s).powi(-i)).sum() } // annuity at rate s
fn w(s: f64, d: i32) -> f64 { (1.0 + s).powi(-d) / g(s) } // payment bond / annuity
fn h(s: f64, d: i32) -> f64 { (s - F) * (w(s, d) - w(F, d)) }
fn second(f: &dyn Fn(f64) -> f64, k: f64) -> f64 {
    let e = 1e-4;
    (f(k + e) - 2.0 * f(k) + f(k - e)) / (e * e)
}
fn black(k: f64, sig: f64, payer: bool) -> f64 { // swaption value in annuity units
    let v = sig * T.sqrt();
    let d1 = ((F / k).ln() + v * v / 2.0) / v;
    let d2 = d1 - v;
    if payer { F * n_cdf(d1) - k * n_cdf(d2) } else { k * n_cdf(-d2) - F * n_cdf(-d1) }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let step = (b - a) / m as f64;
    let mut tot = f(a) + f(b);
    for i in 1..m { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * step); }
    tot * step / 3.0
}
fn otm(k: f64, sig: f64) -> f64 { if k > 0.0 { black(k, sig, k > F) } else { 0.0 } }
fn by_strip(sig: f64, d: i32) -> (f64, f64, f64) { // receivers below F, payers above F
    let num = |k: f64| second(&|s| h(s, d), k) * otm(k, sig);
    let den = |k: f64| second(&|s| w(s, d), k) * otm(k, sig);
    let (rec, pay) = (simpson(&num, 0.0, F, 600), simpson(&num, F, 1.0, 4000));
    let bot = w(F, d) + simpson(&den, 0.0, F, 600) + simpson(&den, F, 1.0, 4000);
    (rec / bot, pay / bot, bot) // adjustment = rec + pay, bot = E[w]
}
fn by_integral(sig: f64, d: i32, f0: f64, t: f64) -> f64 {
    let v = sig * t.sqrt();
    let s = |z: f64| f0 * (-v * v / 2.0 + v * z).exp();
    let top = simpson(&|z| s(z) * w(s(z), d) * phi(z), -9.0, 9.0, 4000);
    let bot = simpson(&|z| w(s(z), d) * phi(z), -9.0, 9.0, 4000);
    top / bot - f0
}
fn by_monte_carlo(paths: usize, seed: u64) -> (f64, f64) {
    let mut x = seed;
    let v = SIG * T.sqrt();
    let mut unif = || { x ^= x << 13; x ^= x >> 7; x ^= x << 17; ((x >> 11) as f64 + 0.5) / 2f64.powi(53) };
    let (mut sh, mut sw, mut sh2) = (0.0, 0.0, 0.0);
    for _ in 0..paths / 2 {
        let u1 = unif();
        let u2 = unif();
        let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
        for zz in [z, -z] { // antithetic pair
            let s = F * (-v * v / 2.0 + v * zz).exp();
            sh += h(s, 1); sw += w(s, 1); sh2 += h(s, 1).powi(2);
        }
    }
    let (mh, mw) = (sh / paths as f64, sw / paths as f64);
    (mh / mw, ((sh2 / paths as f64 - mh * mh) / paths as f64).sqrt() / mw)
}
fn quick(sig: f64, d: i32, t: f64) -> f64 { // linear weight: F^2 (e^{sig^2 T} - 1) w'(F)/w(F)
    let slope = (w(F + 1e-5, d) - w(F - 1e-5, d)) / 2e-5;
    F * F * ((sig * sig * t).exp() - 1.0) * slope / w(F, d)
}

fn main() {
    let bp = 1e4;
    let du = 1.045f64.powi(-6); // payment bond on a flat 4.5% annual curve
    let a0: f64 = (6..16).map(|i| 1.045f64.powi(-i)).sum();
    let (rec, pay, ew) = by_strip(SIG, 1);
    let a1 = rec + pay;
    let a2 = by_integral(SIG, 1, F, T);
    let (a3, se) = by_monte_carlo(200_000, 20260928);
    let a4 = quick(SIG, 1, T);
    let parity = black(0.06, SIG, true) - black(0.06, SIG, false);
    println!("inputs: forward, vol, expiry           {:.3}  {:.2}  {:.1}", F, SIG, T);
    println!("payment weight w(F) = D(U)/A0          {:.6}  {:.6}", w(F, 1), du / a0);
    println!("weight slope w'(F)/w(F)                {:.6}", (w(F + 1e-5, 1) - w(F - 1e-5, 1)) / 2e-5 / w(F, 1));
    println!("annuity at the forward G(F); D(U); A0  {:.6}  {:.6}  {:.6}", g(F), du, a0);
    println!("e^(sig^2 T) - 1; rate variance F^2(..)  {:.6}  {:.8}", (SIG * SIG * T).exp() - 1.0, F * F * ((SIG * SIG * T).exp() - 1.0));
    println!("parity at k=6%: payer - receiver       {:.8}", parity);
    println!("1 strip of swaptions, bp               {:.4}", a1 * bp);
    println!("2 direct integral, bp                  {:.4}", a2 * bp);
    println!("3 Monte Carlo 200k paths, bp           {:.4}  (se {:.4})", a3 * bp, se * bp);
    println!("4 linear quick formula, bp             {:.4}", a4 * bp);
    println!("CMS rate, percent                      {:.4}", (F + a2) * 100.0);
    println!("adjustment on $10m, dollars            {:.2}", L * du * a2);
    println!("coupon at forward, no adjustment, $    {:.2}", L * du * F);
    println!("CMS coupon on $10m, dollars            {:.2}", L * du * (F + a2));
    println!("strip: receivers below F, bp           {:.4}", rec * bp);
    println!("strip: payers above F, bp              {:.4}", pay * bp);
    println!("average weight E[w] under annuity law  {:.6}", ew);
    println!("expiry sweep, adjustment bp (direct, quick):");
    for t in [1.0, 2.0, 3.0, 5.0, 7.0, 10.0] {
        println!("  T = {:>2}                                {:.2}  {:.2}", t as i32, by_integral(SIG, 1, F, t) * bp, quick(SIG, 1, t) * bp);
    }
    println!("quick formula shortfall at 5y, 10y, %   {:.1}  {:.1}", (1.0 - a4 / a2) * 100.0, (1.0 - quick(SIG, 1, 10.0) / by_integral(SIG, 1, F, 10.0)) * 100.0);
    println!("payoff counted in annuities, S w(S)/w(F) against S, percent:");
    for s in [0.01, 0.03, 0.045, 0.07, 0.10, 0.13] {
        println!("  S = {:>4.1}                              {:.3}", s * 100.0, s * w(s, 1) / w(F, 1) * 100.0);
    }
    let (up, dn) = (by_integral(SIG, 1, F + 1e-4, T), by_integral(SIG, 1, F - 1e-4, T));
    println!("delta: CMS rate per 1bp of forward     {:.4}", (2e-4 + up - dn) / 2e-4);
    println!("vega: adjustment bp per vol point      {:.4}", (by_integral(SIG + 0.005, 1, F, T) - by_integral(SIG - 0.005, 1, F, T)) * bp);
    println!("wrong: no adjustment, bp               {:.4}", 0.0);
    println!("wrong: paid on fixing date, bp         {:.4}", by_integral(SIG, 0, F, T) * bp);
    println!("wrong: paid at swap's end, bp          {:.4}", by_integral(SIG, 10, F, T) * bp);
    println!("try: vol 30%, bp                       {:.4}", by_integral(0.30, 1, F, T) * bp);
    println!("try: vol 10%, bp                       {:.4}", by_integral(0.10, 1, F, T) * bp);
    let end = by_strip(SIG, 10);
    println!("try: strip, paid at swap's end, bp     {:.4}", (end.0 + end.1) * bp);

    assert!((a1 - a2).abs() < 1e-7); // replication against direct integral
    assert!((a3 - a2).abs() < 4.0 * se); // simulation against direct integral
    assert!((a4 - a2).abs() < 0.03 * a2); // quick formula within 3 percent
    assert!((parity - (F - 0.06)).abs() < 1e-12);
    assert!((w(F, 1) - du / a0).abs() < 1e-12); // flat-curve weight matches today's curve
    assert!((end.0 + end.1 - by_integral(SIG, 10, F, T)).abs() < 1e-7); // replication holds when the sign flips
    assert!(by_integral(SIG, 10, F, T) < 0.0); // paying late flips the sign
    assert!(by_integral(SIG, 0, F, T) > a2); // paying early makes it bigger
    println!("all checks passed");
}
