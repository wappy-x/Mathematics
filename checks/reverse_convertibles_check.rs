// Reverse convertibles -- the check behind the card.  std only, no crates.
// House market: Acme S = 100, strike K = 100, r = 5%, q = 2%, sigma = 20%, one year.
// A note of face F = 100 pays its coupon in cash, then 100 back if Acme ends at or above K,
// or F/K shares if it ends below.  The barrier note delivers shares only if Acme also
// touched H = 80 during the year.  Four roads: closed forms, digitals, an integral over the
// end-price density, and a 20,000-path daily simulation.  Coupons are solved by bisection.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn nn(x: f64) -> f64 {
    if x < -9.0 { return 0.0; }
    if x > 9.0 { return 1.0; }
    let (mut term, mut s, mut k) = (x, x, 0);
    while k < 400 && term.abs() > 1e-17 * s.abs() {
        k += 1; term *= x * x / (2 * k + 1) as f64; s += term;
    }
    0.5 + phi(x) * s
}
fn d12(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * v * v) * t) / (v * t.sqrt());
    (d1, d1 - v * t.sqrt())
}
fn put(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, v, t);
    k * (-r * t).exp() * nn(-d2) - s * (-q * t).exp() * nn(-d1)
}
fn call(s: f64, k: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, v, t);
    s * (-q * t).exp() * nn(d1) - k * (-r * t).exp() * nn(d2)
}
fn dip(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64) -> f64 {
    let (st, lam) = (v * t.sqrt(), (r - q + 0.5 * v * v) / (v * v));
    let x1 = (s / h).ln() / st + lam * st;
    let y = (h * h / (s * k)).ln() / st + lam * st;
    let y1 = (h / s).ln() / st + lam * st;
    -s * (-q * t).exp() * nn(-x1) + k * (-r * t).exp() * nn(-x1 + st)
        + s * (-q * t).exp() * (h / s).powf(2.0 * lam) * (nn(y) - nn(y1))
        - k * (-r * t).exp() * (h / s).powf(2.0 * lam - 2.0) * (nn(y - st) - nn(y1 - st))
}
fn fair(f: f64, b: f64, opt: f64) -> f64 { (f - b + opt) / b }
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 20000; let h = (b - a) / n as f64; let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}
fn by_density(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64, f: f64) -> (f64, f64, f64, f64) {
    let (nu, sd) = (r - q - 0.5 * v * v, v * t.sqrt());
    let (b, kk) = ((h / s).ln(), (k / s).ln());
    let p = move |x: f64| phi((x - nu * t) / sd) / sd;
    let short = move |x: f64| f / k * (k - s * x.exp());
    let lo = nu * t - 12.0 * sd;
    let w = (2.0 * nu * b / (v * v)).exp();
    let plain = simpson(&|x| short(x) * p(x), lo, kk);
    let touched = simpson(&|x| short(x) * p(x), lo, b) + simpson(&|x| short(x) * w * p(x - 2.0 * b), b, kk);
    let p_plain = simpson(&p, lo, kk);
    let p_touch = simpson(&p, lo, b) + simpson(&|x| w * p(x - 2.0 * b), b, kk);
    ((-r * t).exp() * plain, (-r * t).exp() * touched, p_plain, p_touch)
}
fn by_simulation(s: f64, k: f64, h: f64, r: f64, q: f64, v: f64, t: f64, f: f64) -> Vec<(f64, f64)> {
    let (paths, days) = (20000usize, 252usize);
    let mut state: u64 = 20261123;
    let mut unif = move || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = state;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    };
    let dt = t / days as f64; let mu = (r - q - 0.5 * v * v) * dt; let sd = v * dt.sqrt(); let hl = (h / s).ln();
    let mut sums = [[0.0f64; 2]; 4];
    for _ in 0..paths {
        let (mut x, mut surv, mut daily) = (0.0f64, 1.0f64, 1.0f64);
        let mut z2: Option<f64> = None;
        for _ in 0..days {
            let z = match z2 {
                None => { let (u1, u2) = (unif(), unif()); let rad = (-2.0 * u1.ln()).sqrt();
                          z2 = Some(rad * (2.0 * PI * u2).sin()); rad * (2.0 * PI * u2).cos() }
                Some(w) => { z2 = None; w }
            };
            let nx = x + mu + sd * z;
            if nx <= hl { surv = 0.0; daily = 0.0; }
            else if surv > 0.0 { surv *= 1.0 - (-2.0 * (x - hl) * (nx - hl) / (v * v * dt)).exp(); }
            x = nx;
        }
        let loss = (-r * t).exp() * f / k * (k - s * x.exp()).max(0.0);
        for (j, y) in [loss, -loss * surv, -loss * daily, loss * (daily - surv)].iter().enumerate() { // put; DIP - P, two ways; their gap
            sums[j][0] += y; sums[j][1] += y * y;
        }
    }
    let n = paths as f64;
    sums.iter().map(|a| (a[0] / n, ((a[1] / n - (a[0] / n).powi(2)) / (n - 1.0)).sqrt())).collect()
}
fn bisect(value: &dyn Fn(f64) -> f64, target: f64) -> f64 {
    let (mut lo, mut hi) = (0.0f64, 1.0f64);
    for _ in 0..100 { let mid = 0.5 * (lo + hi); if value(mid) < target { lo = mid } else { hi = mid } }
    0.5 * (lo + hi)
}
fn line(label: &str, xs: &[f64], f: &dyn Fn(f64) -> f64, w: usize) {
    let body: String = xs.iter().map(|&x| format!("{:>7.*}", w, f(x))).collect();
    println!("{:<18}:{}", label, body);
}

fn main() {
    let (s, k, h, r, q, v, t, f): (f64, f64, f64, f64, f64, f64, f64, f64) = (100.0, 100.0, 80.0, 0.05, 0.02, 0.20, 1.0, 100.0);
    let b = f * (-r * t).exp(); let p = put(s, k, r, q, v, t); let di = dip(s, k, h, r, q, v, t);
    let (c_rc, c_brc) = (fair(f, b, f / k * p), fair(f, b, f / k * di));
    let (d1, d2) = d12(s, k, r, q, v, t);
    let (cash_dig, asset_dig) = ((-r * t).exp() * nn(d2), s * (-q * t).exp() * nn(-d1));
    let c_dig = (f - f * cash_dig - f / k * asset_dig) / b;
    let (p_int, dip_int, prob_rc, prob_brc) = by_density(s, k, h, r, q, v, t, f);
    let c_bis_rc = bisect(&|c| b * (1.0 + c) - p_int, f);
    let c_bis_brc = bisect(&|c| b * (1.0 + c) - dip_int, f);
    let mc = by_simulation(s, k, h, r, q, v, t, f);                       // DIP = exact P + simulated (DIP - P)
    let dip_d = dip(s, k, h * (-0.5826 * v * (t / 252.0).sqrt()).exp(), r, q, v, t); // daily closes: the shifted barrier
    let rows: Vec<(&str, f64)> = vec![("bond F e^-rT", b), ("put P", p), ("down-and-in put, H = 80", di),
        ("down-and-out put = P - DIP", p - di), ("F - B", f - b), ("F - B + P", f - b + p), ("F - B + DIP", f - b + di),
        ("1 fair coupon %, plain", 100.0 * c_rc), ("1 fair coupon %, barrier", 100.0 * c_brc),
        ("2 cash digital e^-rT N(d2)", cash_dig), ("2 asset digital S e^-qT N(-d1)", asset_dig),
        ("2 note before coupon, digitals", f * cash_dig + f / k * asset_dig),
        ("2 same, covered call S e^-qT - C", f / k * (s * (-q * t).exp() - call(s, k, r, q, v, t))),
        ("2 fair coupon %, plain, digitals", 100.0 * c_dig),
        ("3 put, density integral", p_int), ("3 DIP, density integral", dip_int),
        ("3 coupon % by bisection, plain", 100.0 * c_bis_rc), ("3 coupon % by bisection, barrier", 100.0 * c_bis_brc),
        ("4 put, simulation", mc[0].0), ("  its error bar (1 s.e.)", mc[0].1),
        ("4 DIP, simulation, continuous", p + mc[1].0), ("  its error bar (1 s.e.)", mc[1].1),
        ("4 DIP, simulation, daily closes", p + mc[2].0), ("  its error bar (1 s.e.)", mc[2].1),
        ("4 continuous - daily, same paths", mc[3].0), ("  its error bar (1 s.e.)", mc[3].1),
        ("DIP, daily, shifted barrier formula", dip_d), ("fair coupon %, daily closes", 100.0 * fair(f, b, dip_d)),
        ("coupon cash at T, plain", f * c_rc), ("coupon cash at T, barrier", f * c_brc), ("coupon gap, plain - barrier", f * (c_rc - c_brc)),
        ("chance of shares, plain", prob_rc), ("chance of shares, barrier", prob_brc),
        ("put carried to T, P e^rT", p * (r * t).exp()), ("check: F(1+c) - P e^rT", f * (1.0 + c_rc) - p * (r * t).exp()),
        ("  F e^rT", f * (r * t).exp()),
        ("wrong %: divide by face, not bond", 100.0 * (f - b + p) / f),
        ("wrong %: bond only, no put", 100.0 * fair(f, b, 0.0)),
        ("wrong %: knock-out put for barrier", 100.0 * fair(f, b, p - di)),
        ("wrong %: dividend left out of put", 100.0 * fair(f, b, put(s, k, r, 0.0, v, t))),
        ("try %: sigma 30%, plain", 100.0 * fair(f, b, put(s, k, r, q, 0.3, t))),
        ("try %: sigma 30%, barrier", 100.0 * fair(f, b, dip(s, k, h, r, q, 0.3, t))),
        ("try %: strike 90, plain", 100.0 * fair(f, b, f / 90.0 * put(s, 90.0, r, q, v, t))),
        ("try %: two years, plain", 100.0 * fair(f, f * (-2.0 * r).exp(), put(s, k, r, q, v, 2.0)))];
    for (name, val) in &rows { println!("{:<36} {:>11.6}", name, val); }
    let vols = [0.10, 0.15, 0.20, 0.25, 0.30, 0.35, 0.40];
    line("chart, sigma %", &vols, &|x| 100.0 * x, 0);
    line("chart, plain %", &vols, &|x| 100.0 * fair(f, b, put(s, k, r, q, x, t)), 2);
    line("chart, barrier %", &vols, &|x| 100.0 * fair(f, b, dip(s, k, h, r, q, x, t)), 2);
    line("story, put P", &vols, &|x| put(s, k, r, q, x, t), 2);
    line("story, DIP", &vols, &|x| dip(s, k, h, r, q, x, t), 2);
    let hs = [50.0, 60.0, 70.0, 80.0, 90.0, 95.0];
    line("bars, barrier H", &hs, &|x| x, 0);
    line("bars, coupon %", &hs, &|x| 100.0 * fair(f, b, dip(s, k, x, r, q, v, t)), 2);
    let ends: Vec<f64> = (0..9).map(|i| 50.0 + 10.0 * i as f64).collect();
    line("payoff, S_T", &ends, &|x| x, 0);
    line("payoff, plain", &ends, &|x| f * (x / k).min(1.0) + f * c_rc, 2);
    line("payoff, touched", &ends, &|x| f * (x / k).min(1.0) + f * c_brc, 2);
    assert!((p - 6.330080627550).abs() < 1e-9, "put vs the Black-Scholes card");
    assert!((di - 4.597403).abs() < 1e-6, "down-and-in put vs the eight-barrier card");
    assert!((c_dig - c_rc).abs() < 1e-10, "digitals road vs the put road");
    assert!((p_int - p).abs() < 1e-7, "density integral vs the put formula");
    assert!((dip_int - di).abs() < 1e-7, "density integral with reflection vs the closed-form DIP");
    assert!((p + mc[1].0 - di).abs() < 3.0 * mc[1].1, "simulated DIP, barrier watched by the bridge, vs the closed form");
    assert!((p + mc[2].0 - dip_d).abs() < 3.0 * mc[2].1, "simulated DIP on daily closes vs the shifted-barrier formula");
    assert!((mc[3].0 - (di - dip_d)).abs() < 3.0 * mc[3].1, "touches between closes: the bridge vs the two formulas");
    assert!((c_rc - 0.1178).abs() < 5e-5, "plain coupon vs the hand value 11.78%");
    assert!((c_brc - 0.0996).abs() < 5e-5, "barrier coupon vs the hand value 9.96%");
    println!("ALL CHECKS PASS");
}
