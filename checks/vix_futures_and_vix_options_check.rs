// VIX futures and options on the house flat 20% surface, 6 months out, VIX lognormal at 80% vol.
// Roads: 1 closed forms (lognormal moments, Black-76), 2 Simpson integrals over the normal density,
// 3 Monte Carlo with a home-made generator. The implied vol of VIX is solved back by bisection.
const R: f64 = 0.05; const T: f64 = 0.5; const OMEGA: f64 = 0.80; // rate, years to expiry, vol of VIX
const PI: f64 = std::f64::consts::PI;
const K1: f64 = 0.04; const K2: f64 = 0.04; // variance strikes to T and to T + 30 days

fn tau() -> f64 { 30.0 / 365.0 }
fn disc() -> f64 { (-R * T).exp() }
fn ncdf(x: f64) -> f64 { // normal CDF by Marsaglia's series, no library
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut s, mut t, mut n) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { n += 2.0; t *= x * x / n; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}
fn npdf(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * PI).sqrt() }
fn black76(f: f64, k: f64, vol: f64, call: bool) -> f64 { // Black-76 on a forward or future
    let sd = vol * T.sqrt(); let d1 = ((f / k).ln() + 0.5 * sd * sd) / sd; let d2 = d1 - sd;
    if call { disc() * (f * ncdf(d1) - k * ncdf(d2)) } else { disc() * (k * ncdf(-d2) - f * ncdf(-d1)) }
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut inner = 0.0;
    for i in 1..n { inner += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + inner)
}
fn cap() -> f64 { 100.0 * ((K2 * (T + tau()) - K1 * T) / tau()).sqrt() } // the ceiling, VIX points
fn vix_at(z: f64, om: f64) -> f64 { // VIX at expiry: VIX^2 lognormal with mean cap^2
    let s = 2.0 * om * T.sqrt();
    (cap() * cap() * (s * z - 0.5 * s * s).exp()).sqrt()
}
fn fut_closed(om: f64) -> f64 { cap() * (-om * om * T / 2.0).exp() }
fn fut_simpson(om: f64) -> f64 { simpson(&|z| vix_at(z, om) * npdf(z), -12.0, 12.0, 4000) }
fn kink(k: f64) -> f64 { // the z at which the VIX lands exactly on K
    let s = 2.0 * OMEGA * T.sqrt(); (2.0 * (k / cap()).ln() + 0.5 * s * s) / s
}
struct Rng(u64); // splitmix64, then Box-Muller: no library random
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 + 0.5 / 9007199254740992.0
    }
}
fn implied(price: f64, f: f64, k: f64) -> f64 { // bisection: Black-76 price rises with vol
    let (mut lo, mut hi) = (0.01, 5.0);
    for _ in 0..200 { let mid = 0.5 * (lo + hi); if black76(f, k, mid, true) < price { lo = mid; } else { hi = mid; } }
    0.5 * (lo + hi)
}
fn main() {
    let d = disc(); let cap = cap();
    let xi = (K2 * (T + tau()) - K1 * T) / tau();
    let (f1, f2) = (fut_closed(OMEGA), fut_simpson(OMEGA));
    let ev2 = simpson(&|z| vix_at(z, OMEGA).powi(2) * npdf(z), -12.0, 12.0, 4000);
    let nmc = 200000usize; let (mut sx, mut sxx, mut sc, mut scc) = (0.0, 0.0, 0.0, 0.0);
    let mut rng = Rng(0x9E3779B97F4A7C15);
    for _ in 0..nmc / 2 {
        let (a, b) = (rng.u01(), rng.u01());
        for z in [(-2.0 * a.ln()).sqrt() * (2.0 * PI * b).cos(), (-2.0 * a.ln()).sqrt() * (2.0 * PI * b + PI / 2.0).cos()] {
            let x = vix_at(z, OMEGA); let c = d * (x - f1).max(0.0);
            sx += x; sxx += x * x; sc += c; scc += c * c;
        }
    }
    let n = nmc as f64;
    let (f3, f3se) = (sx / n, ((sxx / n - (sx / n).powi(2)) / n).sqrt());
    let c1 = black76(f1, f1, OMEGA, true);
    let c2 = d * simpson(&|z| (vix_at(z, OMEGA) - f1) * npdf(z), kink(f1), 12.0, 4000);
    let (c3, c3se) = (sc / n, ((scc / n - (sc / n).powi(2)) / n).sqrt());
    let p1 = black76(f1, f1, OMEGA, false);
    let quoted = (c1 * 10000.0).round() / 10000.0;
    let iv = implied(quoted, f1, f1);
    let om_gap = (2.0 * (cap / f2).ln() / T).sqrt(); // the vol of VIX the futures gap implies
    println!("forward variance, T to T+30d      {:.6}", xi);
    println!("ceiling 100 sqrt(xi)              {:.4}", cap);
    println!("average VIX^2 (Simpson)           {:.4}", ev2);
    println!("omega^2 T / 2                     {:.6}", OMEGA * OMEGA * T / 2.0);
    println!("exp(-omega^2 T / 2)               {:.6}", (-OMEGA * OMEGA * T / 2.0).exp());
    println!("future 1 closed form              {:.4}", f1);
    println!("future 2 Simpson                  {:.4}", f2);
    println!("future 3 Monte Carlo              {:.4}  (se {:.4}, {} draws)", f3, f3se, nmc);
    println!("gap below the ceiling             {:.4}", cap - f1);
    let sd = OMEGA * T.sqrt();
    println!("d1, d2                            {:.6}  {:.6}", sd / 2.0, -sd / 2.0);
    println!("N(d1), N(d2)                      {:.6}  {:.6}", ncdf(sd / 2.0), ncdf(-sd / 2.0));
    println!("discount factor D                 {:.6}", d);
    println!("ATM call 1 Black-76               {:.4}", c1);
    println!("ATM call 2 Simpson                {:.4}", c2);
    println!("ATM call 3 Monte Carlo            {:.4}  (se {:.4})", c3, c3se);
    println!("ATM put, Black-76                 {:.4}", p1);
    println!("implied vol of VIX from {:.4}    {:.4}", quoted, iv);
    println!("vol of VIX from the futures gap   {:.6}", om_gap);
    println!("vega of the ATM call, per point   {:.4}", black76(f1, f1, OMEGA + 0.005, true) - black76(f1, f1, OMEGA - 0.005, true));
    println!();
    println!("strike   call     put      call-put  D(F-K)");
    for k in [15.0, 20.0, 25.0] {
        let (c, p) = (black76(f1, k, OMEGA, true), black76(f1, k, OMEGA, false));
        println!("{:5.1} {:8.4} {:8.4} {:9.4} {:8.4}", k, c, p, c - p, d * (f1 - k));
    }
    println!();
    println!("omega  future   gap    eighth-rule gap");
    let grid = [0.4, 0.6, 0.8, 1.0, 1.2];
    for om in grid {
        let s2 = 4.0 * om * om * T;
        println!("{:4.1} {:8.4} {:6.4} {:9.4}", om, fut_closed(om), cap - fut_closed(om), cap.powi(4) * (s2.exp() - 1.0) / (8.0 * cap.powi(3)));
    }
    println!();
    let months: Vec<String> = (0..7).map(|m| format!("{:6}", m)).collect();
    let futs: Vec<String> = (0..7).map(|m| format!("{:6.2}", cap * (-OMEGA.powi(2) * m as f64 / 12.0 / 2.0).exp())).collect();
    println!("chart, months {}", months.join(" "));
    println!("chart, future {}", futs.join(" "));
    println!();
    let eighth = cap - cap.powi(4) * ((4.0 * OMEGA * OMEGA * T).exp() - 1.0) / (8.0 * cap.powi(3));
    println!("wrong: future at the ceiling          {:.4}", cap);
    println!("wrong: eighth-rule future             {:.4}", eighth);
    println!("wrong: Black-76 on spot VIX 20        {:.4}", black76(cap, f1, OMEGA, true));
    println!("wrong: rate inside d1, as for a stock {:.4}",
        f1 * ncdf((R * T + 0.5 * sd * sd) / sd) - f1 * d * ncdf((R * T - 0.5 * sd * sd) / sd));
    println!("try: omega 1.0, ATM call              {:.4}", black76(fut_closed(1.0), fut_closed(1.0), 1.0, true));
    println!("try: one-year expiry, future          {:.4}", cap * (-OMEGA * OMEGA * 1.0 / 2.0).exp());
    let cap2 = 100.0 * ((0.041 * (T + tau()) - K1 * T) / tau()).sqrt(); // 30 days later now struck at 0.041
    println!("try: K2 = 0.041, ceiling and future   {:.4}  {:.4}", cap2, cap2 * (-OMEGA * OMEGA * T / 2.0).exp());

    assert!((f1 - f2).abs() < 1e-9, "Simpson future must equal the lognormal closed form");
    assert!((f1 - f3).abs() < 4.0 * f3se, "Monte Carlo future within four standard errors");
    assert!((ev2 - cap * cap).abs() < 1e-8, "VIX^2 must average to the forward variance");
    assert!((c1 - c2).abs() < 1e-6, "Simpson call must equal Black-76");
    assert!((c1 - c3).abs() < 4.0 * c3se, "Monte Carlo call within four standard errors");
    assert!((iv - OMEGA).abs() < 1e-4, "bisection must recover the 80% vol of VIX");
    assert!((om_gap - OMEGA).abs() < 1e-8, "the futures gap must imply the same vol of VIX");
    assert!(grid.iter().all(|&om| fut_simpson(om) < cap), "Jensen: every future below the ceiling");
    let p2 = d * simpson(&|z| (20.0 - vix_at(z, OMEGA)) * npdf(z), -12.0, kink(20.0), 4000);
    assert!(((black76(f1, 20.0, OMEGA, true) - p2) - d * (f2 - 20.0)).abs() < 1e-6, "parity: Black-76 call minus Simpson put");
    assert!((p1 - d * simpson(&|z| (f1 - vix_at(z, OMEGA)) * npdf(z), -12.0, kink(f1), 4000)).abs() < 1e-6, "Simpson put must equal the Black-76 put");
    println!("ALL CHECKS PASS");
}
