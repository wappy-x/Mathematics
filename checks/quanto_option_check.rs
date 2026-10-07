// Quanto option -- the check behind the card.  Rust std only, no crates.
// Every number quoted on the card is printed here.  The normal CDF is a series
// written out, the integral is Simpson's rule, the random numbers are splitmix64.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const XBAR: f64 = 1.10; const X0: f64 = 1.15;
const RD: f64 = 0.05; const RF: f64 = 0.03; const Q: f64 = 0.01;
const SS: f64 = 0.20; const SX: f64 = 0.10; const RHO: f64 = 0.30; const T: f64 = 1.0;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn n_cdf(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() {            // x + x^3/3 + x^5/(3*5) + ...
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + phi(x) * total
}
fn drift(rf: f64, q: f64, ss: f64, sx: f64, rho: f64) -> f64 { rf - q - rho * ss * sx }
fn quanto(s: f64, k: f64, xbar: f64, rd: f64, mu: f64, ss: f64, t: f64, put: bool) -> f64 {
    let v = ss * t.sqrt();                               // road 1: the closed form
    let d1 = ((s / k).ln() + (mu + 0.5 * ss * ss) * t) / v; let d2 = d1 - v;
    let (share, cash) = (s * ((mu - rd) * t).exp(), k * (-rd * t).exp());
    if put { xbar * (cash * n_cdf(-d2) - share * n_cdf(-d1)) } else { xbar * (share * n_cdf(d1) - cash * n_cdf(d2)) }
}
fn call(ss: f64, sx: f64, rho: f64, q: f64, s: f64) -> f64 { quanto(s, K, XBAR, RD, drift(RF, q, ss, sx, rho), ss, T, false) }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64; let mut total = 0.0;
    for i in 0..=n {
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        total += w * f(a + i as f64 * h);
    }
    h / 3.0 * total
}
fn euro_world(x0: f64, put: bool, n: usize) -> f64 {  // road 2: EUR world, mu never used
    let m_s = (RF - Q - 0.5 * SS * SS) * T;              // share drifts at its own rate rf - q
    let m_x = (RD - RF + SX * SX - 0.5 * SX * SX) * T;   // USD per EUR drifts at rd - rf + sX^2
    let zk = ((K / S).ln() - m_s) / (SS * T.sqrt());
    let inner = |z1: f64| -> f64 {
        let s_t = S * (m_s + SS * T.sqrt() * z1).exp();
        let g = |z2: f64| -> f64 {
            let x_t = x0 * (m_x + SX * T.sqrt() * (RHO * z1 + (1.0 - RHO * RHO).sqrt() * z2)).exp();
            XBAR * (if put { K - s_t } else { s_t - K }).max(0.0) / x_t * phi(z2)
        };
        simpson(&g, -9.0, 9.0, n) * phi(z1)
    };
    let (lo, hi) = if put { (-9.0, zk) } else { (zk, 9.0) };
    x0 * (-RF * T).exp() * simpson(&inner, lo, hi, n)
}
struct Rng(u64);
impl Rng {
    fn u01(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53)
    }
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid; } else { hi = mid; }
    }
    0.5 * (lo + hi)
}
fn main() {
    let mu = drift(RF, Q, SS, SX, RHO);
    let d1 = ((S / K).ln() + (mu + 0.5 * SS * SS) * T) / (SS * T.sqrt()); let d2 = d1 - SS * T.sqrt();
    let c = call(SS, SX, RHO, Q, S); let p = quanto(S, K, XBAR, RD, mu, SS, T, true);
    let (c115, c200, p_int) = (euro_world(1.15, false, 400), euro_world(2.00, false, 400), euro_world(1.15, true, 400));
    // road 3: Monte Carlo in the USD world, both assets, each draw and its mirror
    let mut rng = Rng(20260927); let n_mc = 200000usize;
    let (mut sp, mut sp2, mut sv, mut sv2) = (0.0, 0.0, 0.0, 0.0);
    for _ in 0..n_mc / 2 {
        let r = (-2.0 * (1.0 - rng.u01()).ln()).sqrt(); let a = 2.0 * PI * rng.u01();
        let (z1, z2) = (r * a.cos(), r * a.sin());
        for (s1, s2) in [(z1, z2), (-z1, -z2)] {
            let s_t = S * ((mu - 0.5 * SS * SS) * T + SS * T.sqrt() * s1).exp();
            let x_t = X0 * ((RD - RF - 0.5 * SX * SX) * T + SX * T.sqrt() * (RHO * s1 + (1.0 - RHO * RHO).sqrt() * s2)).exp();
            let pay = XBAR * (s_t - K).max(0.0); sp += pay; sp2 += pay * pay;
            let v = s_t * x_t; sv += v; sv2 += v * v;
        }
    }
    let nf = n_mc as f64;
    let mc = (-RD * T).exp() * sp / nf; let mc_se = (-RD * T).exp() * ((sp2 / nf - (sp / nf).powi(2)) / nf).sqrt();
    let (mv, mv_se) = (sv / nf, ((sv2 / nf - (sv / nf).powi(2)) / nf).sqrt());
    let need_v = S * X0 * ((RD - Q) * T).exp(); let unadj_v = S * X0 * ((RD - Q + RHO * SS * SX) * T).exp();
    let no_adj = quanto(S, K, XBAR, RD, RF - Q, SS, T, false);
    let flipped = quanto(S, K, XBAR, RD, RF - Q + RHO * SS * SX, SS, T, false);
    let vol_eq = bisect(&|s: f64| call(s, SX, RHO, Q, S) - no_adj, 0.05, 0.60);
    let h = 1e-4;
    let delta_fd = (call(SS, SX, RHO, Q, S + h) - call(SS, SX, RHO, Q, S - h)) / (2.0 * h);
    let delta_an = XBAR * ((mu - RD) * T).exp() * n_cdf(d1);
    let rows: Vec<(&str, f64)> = vec![("1.01 x 1.01, moving together", 1.01 * 1.01), ("1.01 x 0.99, moving apart", 1.01 * 0.99),
        ("euro growth rf - q", RF - Q), ("currency growth rd - rf", RD - RF),
        ("adjustment -rho sS sX", -RHO * SS * SX), ("mu = rf - q - rho sS sX", mu), ("d1", d1), ("d2", d2),
        ("N(d1)", n_cdf(d1)), ("N(d2)", n_cdf(d2)), ("share side S e^(mu-rd)T N(d1)", S * ((mu - RD) * T).exp() * n_cdf(d1)),
        ("cash side K e^-rdT N(d2)", K * (-RD * T).exp() * n_cdf(d2)), ("1 formula, call", c),
        ("2 EUR world, spot 1.15", c115), ("2 EUR world, spot 2.00", c200),
        ("3 Monte Carlo, 200000 paths", mc), ("  standard error", mc_se),
        ("formula, put", p), ("EUR world, put", p_int), ("  C - P, both by EUR world", c115 - p_int),
        ("  Xbar e^-rdT (S e^muT - K)", XBAR * (-RD * T).exp() * (S * (mu * T).exp() - K)),
        ("MC mean of S_T X_T, USD", mv), ("  standard error", mv_se),
        ("  required S X0 e^(rd-q)T", need_v), ("  if drift were rf - q", unadj_v),
        ("substitute dividend q*", RD - RF + Q + RHO * SS * SX),
        ("quanto forward S e^muT", S * (mu * T).exp()), ("euro forward S e^(rf-q)T", S * ((RF - Q) * T).exp()),
        ("premium on 10,000 shares", 10000.0 * c), ("breakeven share K + C/Xbar", K + c / XBAR),
        ("wrong: no adjustment", no_adj), ("  error, USD", no_adj - c),
        ("  too dear, percent", 100.0 * (no_adj / c - 1.0)),
        ("  as share vol, points", 100.0 * (vol_eq - SS)), ("wrong: sign flipped", flipped),
        ("wrong: spot 1.15 for Xbar", c / XBAR * X0), ("wrong: rd in the drift", quanto(S, K, XBAR, RD, RD - Q - RHO * SS * SX, SS, T, false)),
        ("wrong: vol sqrt(sS^2+sX^2)", quanto(S, K, XBAR, RD, mu, (SS * SS + SX * SX).sqrt(), T, false)),
        ("wrong: dividend dropped", call(SS, SX, RHO, 0.0, S)),
        ("delta, USD per EUR, bump", delta_fd), ("delta, Xbar e^(mu-rd)T N(d1)", delta_an),
        ("gamma, bump", (call(SS, SX, RHO, Q, S + 0.01) - 2.0 * c + call(SS, SX, RHO, Q, S - 0.01)) / 1e-4),
        ("vega, per share-vol point", (call(SS + h, SX, RHO, Q, S) - call(SS - h, SX, RHO, Q, S)) / (2.0 * h) / 100.0),
        ("per 0.01 of correlation", (call(SS, SX, RHO + h, Q, S) - call(SS, SX, RHO - h, Q, S)) / (2.0 * h) / 100.0),
        ("per FX-vol point", (call(SS, SX + h, RHO, Q, S) - call(SS, SX - h, RHO, Q, S)) / (2.0 * h) / 100.0)];
    for (name, v) in &rows { println!("{:<32}{:>14.6}", name, v); }
    let rhos = [-1.0, -0.75, -0.5, -0.25, 0.0, 0.25, 0.5, 0.75, 1.0];
    println!("chart, correlation {}", rhos.iter().map(|r| format!("{:6.2}", r)).collect::<Vec<_>>().join(" "));
    println!("chart, call USD    {}", rhos.iter().map(|&r| format!("{:6.2}", call(SS, SX, r, Q, S))).collect::<Vec<_>>().join(" "));
    let shares: Vec<f64> = (0..11).map(|i| 80.0 + 5.0 * i as f64).collect();
    println!("chart, share EUR   {}", shares.iter().map(|s| format!("{:6.0}", s)).collect::<Vec<_>>().join(" "));
    println!("chart, profit USD  {}", shares.iter().map(|&s| format!("{:6.2}", XBAR * (s - K).max(0.0) - c)).collect::<Vec<_>>().join(" "));

    assert!((c - 9.151629).abs() < 5e-7, "formula vs the hand-worked 9.151629");
    assert!((c115 - c).abs() < 1e-6, "EUR-world road, spot 1.15, lands on the formula");
    assert!((c200 - c).abs() < 1e-6, "EUR-world road, spot 2.00: today's rate cancels");
    assert!((mc - c).abs() < 4.0 * mc_se, "Monte Carlo within four standard errors");
    assert!((p - p_int).abs() < 1e-6, "formula put vs EUR-world put");
    assert!(((c115 - p_int) - XBAR * (-RD * T).exp() * (S * (mu * T).exp() - K)).abs() < 1e-6, "quanto put-call parity");
    assert!((mv - need_v).abs() < 4.0 * mv_se, "USD value of one share grows at rd - q");
    assert!((mv - unadj_v).abs() > 8.0 * mv_se, "without the adjustment it would grow too fast");
    assert!((delta_fd - delta_an).abs() < 1e-6, "bumped delta vs Xbar e^(mu-rd)T N(d1)");
    println!("ALL CHECKS PASS");
}
