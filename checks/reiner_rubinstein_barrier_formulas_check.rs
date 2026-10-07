// The eight barrier formulas -- the same check as the Python, in Rust.  No crates.
// Road 1: the Reiner-Rubinstein blocks A..F.  Road 2: Simpson's rule over the
// reflected density of the log price.  Road 3: a Monte Carlo of monthly steps
// with the Brownian-bridge chance of a touch between steps.  Road 4: parity.
use std::collections::HashMap;
use std::f64::consts::PI;
const S: f64 = 100.0; const R_: f64 = 0.05; const Q_: f64 = 0.02; const SIG: f64 = 0.20; const T: f64 = 1.0; const REB: f64 = 3.0;
const CALL: f64 = 9.227005508154; const PUT: f64 = 6.330080627550;   // house prices, from the Black-Scholes card
fn dens(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + s)
}
fn ncdf(x: f64) -> f64 {                                   // bell-curve area left of x, by slices
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(dens, 0.0, x, 2000)
}
fn blocks(k: f64, hb: f64, phi: f64, eta: f64) -> [f64; 6] {   // the six Reiner-Rubinstein terms
    let v = SIG * T.sqrt(); let mu = (R_ - Q_ - 0.5 * SIG * SIG) / (SIG * SIG); let lam = (mu * mu + 2.0 * R_ / (SIG * SIG)).sqrt();
    let x1 = (S / k).ln() / v + (1.0 + mu) * v; let x2 = (S / hb).ln() / v + (1.0 + mu) * v;
    let y1 = (hb * hb / (S * k)).ln() / v + (1.0 + mu) * v; let y2 = (hb / S).ln() / v + (1.0 + mu) * v; let z = (hb / S).ln() / v + lam * v;
    let (sq, kr, h) = (S * (-Q_ * T).exp(), k * (-R_ * T).exp(), hb / S);
    let a = phi * sq * ncdf(phi * x1) - phi * kr * ncdf(phi * (x1 - v));
    let b = phi * sq * ncdf(phi * x2) - phi * kr * ncdf(phi * (x2 - v));
    let c = phi * sq * h.powf(2.0 * mu + 2.0) * ncdf(eta * y1) - phi * kr * h.powf(2.0 * mu) * ncdf(eta * (y1 - v));
    let d = phi * sq * h.powf(2.0 * mu + 2.0) * ncdf(eta * y2) - phi * kr * h.powf(2.0 * mu) * ncdf(eta * (y2 - v));
    let e = REB * (-R_ * T).exp() * (ncdf(eta * (x2 - v)) - h.powf(2.0 * mu) * ncdf(eta * (y2 - v)));
    let f = REB * (h.powf(mu + lam) * ncdf(eta * z) + h.powf(mu - lam) * ncdf(eta * (z - 2.0 * lam * v)));
    [a, b, c, d, e, f]
}
// which blocks each contract adds, as coefficients on (A, B, C, D); key (in?, eta, phi, strike above barrier?)
fn mix(inn: i32, eta: i32, phi: i32, above: i32) -> [f64; 4] {
    match (inn, eta, phi, above) {
        (1, 1, 1, 1) | (1, -1, -1, 0) => [0.0, 0.0, 1.0, 0.0], (1, 1, 1, 0) | (1, -1, -1, 1) => [1.0, -1.0, 0.0, 1.0],
        (1, -1, 1, 1) | (1, 1, -1, 0) => [1.0, 0.0, 0.0, 0.0], (1, -1, 1, 0) | (1, 1, -1, 1) => [0.0, 1.0, -1.0, 1.0],
        (0, 1, 1, 1) | (0, -1, -1, 0) => [1.0, 0.0, -1.0, 0.0], (0, 1, 1, 0) | (0, -1, -1, 1) => [0.0, 1.0, 0.0, -1.0],
        (0, -1, 1, 1) | (0, 1, -1, 0) => [0.0; 4], _ => [1.0, -1.0, 1.0, -1.0],
    }
}
fn rr(k: f64, hb: f64, phi: i32, eta: i32, inn: i32, rebate: bool) -> f64 {
    let b = blocks(k, hb, phi as f64, eta as f64);
    let c = mix(inn, eta, phi, (k > hb) as i32);
    let val = (0..4).fold(0.0, |s, j| s + c[j] * b[j]);
    val + if rebate { if inn == 1 { b[4] } else { b[5] } } else { 0.0 }
}
fn integral(k: f64, hb: f64, phi: f64, eta: i32, inn: i32, pay: Option<fn(f64) -> f64>) -> f64 {   // road 2
    let (nu, sd, bl) = (R_ - Q_ - 0.5 * SIG * SIG, SIG * T.sqrt(), (hb / S).ln());
    let w = (2.0 * nu * bl / (SIG * SIG)).exp();
    let f = |u: f64| dens((u - nu * T) / sd) / sd;
    let g = |u: f64| {
        let live = if eta == 1 { u > bl } else { u < bl };
        let surv = if live { f(u) - w * f(u - 2.0 * bl) } else { 0.0 };
        let p = match pay { Some(pf) => pf(u), None => (phi * (S * u.exp() - k)).max(0.0) };
        p * if inn == 1 { f(u) - surv } else { surv }
    };
    let mut cuts = vec![-3.0, bl, (k / S).ln(), 3.0];
    cuts.sort_by(|a, b| a.partial_cmp(b).unwrap()); cuts.dedup();
    (-R_ * T).exp() * cuts.windows(2).map(|p| simpson(&g, p[0], p[1], 4000)).sum::<f64>()
}
fn touch_pv(hb: f64) -> f64 {                               // E[e^{-r tau}; tau <= T] from the first-passage density
    let (nu, bl) = (R_ - Q_ - 0.5 * SIG * SIG, (hb / S).ln().abs());
    let sgn = if hb < S { 1.0 } else { -1.0 };
    let g = |t: f64| if t == 0.0 { 0.0 } else {
        (-R_ * t).exp() * bl / (SIG * (2.0 * PI * t.powf(3.0)).sqrt()) * (-(bl + sgn * nu * t).powi(2) / (2.0 * SIG * SIG * t)).exp() };
    simpson(g, 0.0, T, 4000)
}
const CASES: [(&str, f64, i32, i32, i32); 8] = [("DOC", 80.0, 1, 1, 0), ("DIC", 80.0, 1, 1, 1), ("DOP", 80.0, -1, 1, 0), ("DIP", 80.0, -1, 1, 1),
    ("UOC", 120.0, 1, -1, 0), ("UIC", 120.0, 1, -1, 1), ("UOP", 120.0, -1, -1, 0), ("UIP", 120.0, -1, -1, 1)];
const STRIKES: [f64; 3] = [100.0, 60.0, 140.0];            // 60 sits below the 80 barrier, 140 above the 120 one
fn main() {
    // ---- road 3: Monte Carlo, 12 monthly steps, bridge chance of a touch between steps ----
    let mut state: u64 = 20260924;
    let mut uniform = || { state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        ((state >> 11) as f64 + 0.5) / 9007199254740992.0 };
    let (paths, steps) = (200000usize, 12usize);
    let dt = T / steps as f64; let drift = (R_ - Q_ - 0.5 * SIG * SIG) * dt; let vol = SIG * dt.sqrt();
    let (bd, bu) = (0.8f64.ln(), 1.2f64.ln());
    let mut acc: HashMap<(usize, usize), (f64, f64)> = HashMap::new(); let mut monthly = 0.0;
    for _ in 0..paths {
        let (mut x, mut sdn, mut sup, mut alive_m) = (0.0f64, 1.0f64, 1.0f64, true);
        for _ in 0..steps {
            let u1 = uniform(); let u2 = uniform();
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos();
            let y = x + drift + vol * z;
            sdn *= if y <= bd { 0.0 } else { 1.0 - (-2.0 * (x - bd) * (y - bd) / (vol * vol)).exp() };
            sup *= if y >= bu { 0.0 } else { 1.0 - (-2.0 * (bu - x) * (bu - y) / (vol * vol)).exp() };
            alive_m = alive_m && y > bd;
            x = y;
        }
        let st = S * x.exp();
        for (ci, &(_, _, phi, eta, inn)) in CASES.iter().enumerate() {
            for (ki, &k) in STRIKES.iter().enumerate() {
                let keep = if eta == 1 { sdn } else { sup };
                let p = (phi as f64 * (st - k)).max(0.0) * if inn == 1 { 1.0 - keep } else { keep };
                let e = acc.entry((ci, ki)).or_insert((0.0, 0.0)); e.0 += p; e.1 += p * p;
            }
        }
        if alive_m { monthly += (st - 100.0).max(0.0); }
    }
    let mc = |ci: usize, ki: usize| { let (s1, s2) = acc[&(ci, ki)]; let m = s1 / paths as f64;
        ((-R_ * T).exp() * m, (-R_ * T).exp() * ((s2 / paths as f64 - m * m).max(0.0) / paths as f64).sqrt()) };
    println!("house: S 100, r 5%, q 2%, sigma 20%, T 1; barriers 80 and 120; rebate 3");
    println!("blocks at K 100      A          B          C          D");
    for (lab, hb, phi, eta) in [("down call", 80.0, 1.0, 1.0), ("down put", 80.0, -1.0, 1.0), ("up call", 120.0, 1.0, -1.0), ("up put", 120.0, -1.0, -1.0)] {
        let b = blocks(100.0, hb, phi, eta);
        println!("{:<11}{}", lab, b[..4].iter().map(|v| format!("{:11.6}", v)).collect::<String>());
    }
    println!("contract   K   formula    integral   simulated   +/- se");
    let mut prices: HashMap<(&str, usize), f64> = HashMap::new(); let (mut worst_int, mut worst_z) = (0.0f64, 0.0f64);
    for (ki, &k) in STRIKES.iter().enumerate() {
        for (ci, &(name, hb, phi, eta, inn)) in CASES.iter().enumerate() {
            if ki != 0 && (ki == 1) != (eta == 1) { continue; }
            let f = rr(k, hb, phi, eta, inn, false); let i = integral(k, hb, phi as f64, eta, inn, None); let (m, se) = mc(ci, ki);
            prices.insert((name, ki), f); worst_int = worst_int.max((f - i).abs()); worst_z = worst_z.max((f - m).abs() / se.max(1e-12));
            println!("{} {:5.0} {:10.6} {:10.6} {:10.4} {:8.4}", name, k, f, i, m, se);
        }
    }
    let van = |k: f64, phi: f64| integral(k, 1e-9, phi, 1, 0, None);   // barrier far out of reach
    let pairs = [(0usize, "DOC", "DIC", CALL), (0, "DOP", "DIP", PUT), (0, "UOC", "UIC", CALL), (0, "UOP", "UIP", PUT),
        (1, "DOC", "DIC", van(60.0, 1.0)), (1, "DOP", "DIP", van(60.0, -1.0)), (2, "UOC", "UIC", van(140.0, 1.0)), (2, "UOP", "UIP", van(140.0, -1.0))];
    for (ki, o, i, target) in pairs {
        let tot = prices[&(o, ki)] + prices[&(i, ki)];
        println!("parity {}+{} K{:4.0}: {:10.6}  plain option {:10.6}", o, i, STRIKES[ki], tot, target);
        assert!((tot - target).abs() < 1e-7, "in plus out must rebuild the plain option");
    }
    let one: fn(f64) -> f64 = |_| 1.0;
    let qd = integral(100.0, 80.0, 0.0, 1, 0, Some(one)) * (R_ * T).exp();
    let qu = integral(100.0, 120.0, 0.0, -1, 0, Some(one)) * (R_ * T).exp();
    for (lab, hb, eta, q) in [("80 ", 80.0, 1.0, qd), ("120", 120.0, -1.0, qu)] {
        let b = blocks(100.0, hb, 1.0, eta);
        println!("barrier {}: chance of touching {:.6}; F {:.6} vs {:.6}; E {:.6} vs {:.6}", lab, 1.0 - q, b[5], REB * touch_pv(hb), b[4], REB * (-R_ * T).exp() * q);
        assert!((b[5] - REB * touch_pv(hb)).abs() < 1e-7 && (b[4] - REB * (-R_ * T).exp() * q).abs() < 1e-7);
    }
    println!("DOC 80 with rebate 3 paid at the touch: {:.6}; UOC 120: {:.6}", rr(100.0, 80.0, 1, 1, 0, true), rr(100.0, 120.0, 1, -1, 0, true));
    println!("DIC 80 with rebate 3 paid at expiry if never touched: {:.6}", rr(100.0, 80.0, 1, 1, 1, true));
    let b80 = blocks(100.0, 80.0, 1.0, 1.0); let b120w = blocks(100.0, 120.0, 1.0, 1.0);
    println!("wrong: DOC 80 by the strike-below-barrier branch B - D {:.6}", b80[1] - b80[3]);
    println!("wrong: UOC 120 with eta left at +1 {:.6}", b120w[0] - b120w[1] + b120w[2] - b120w[3]);
    let (v, mu) = (SIG * T.sqrt(), (R_ - Q_ - 0.5 * SIG * SIG) / (SIG * SIG)); let y1 = 0.64f64.ln() / v + (1.0 + mu) * v;
    let wrong_c = S * (-Q_ * T).exp() * 0.8f64.powf(2.0 * mu) * ncdf(y1) - 100.0 * (-R_ * T).exp() * 0.8f64.powf(2.0 * mu) * ncdf(y1 - v);
    let (lam, sh, ch) = ((mu * mu + 2.0 * R_ / (SIG * SIG)).sqrt(), S * (-Q_ * T).exp() * 0.8f64.powf(2.0 * mu + 2.0) * ncdf(y1), 100.0 * (-R_ * T).exp() * 0.8f64.powf(2.0 * mu) * ncdf(y1 - v));
    println!("worked DOC 80: mu {:.6} lambda {:.6} y1 {:.6} N(y1) {:.6} N(y1-v) {:.6}", mu, lam, y1, ncdf(y1), ncdf(y1 - v));
    println!("worked DOC 80: (H/S)^(2mu+2) {:.6} (H/S)^2mu {:.6} share {:.6} cash {:.6} C {:.6}", 0.8f64.powf(2.0 * mu + 2.0), 0.8f64.powf(2.0 * mu), sh, ch, sh - ch);
    let bu = blocks(100.0, 120.0, 1.0, -1.0);
    println!("worked UOC 120: A-B {:.6} C-D {:.6} UOC {:.6}", bu[0] - bu[1], bu[2] - bu[3], prices[&("UOC", 0)]);
    println!("wrong: DOC 80 with one image weight (H/S)^2mu on both halves of C {:.6}", b80[0] - wrong_c);
    println!("wrong: DOC 80 rebate paid at expiry, not at the touch {:.6}", prices[&("DOC", 0)] + REB * (-R_ * T).exp() * (1.0 - qd));
    let m_mc = (-R_ * T).exp() * monthly / paths as f64;
    println!("wrong: DOC 80 checked only at 12 month-ends, no bridge (simulated) {:.4}", m_mc);
    let hs: Vec<i32> = (50..100).step_by(5).collect();
    let row = |f: &dyn Fn(f64) -> f64| hs.iter().map(|&h| format!("{:6.2}", f(h as f64))).collect::<Vec<_>>().join(" ");
    println!("chart, barrier   {}", hs.iter().map(|h| format!("{:6}", h)).collect::<Vec<_>>().join(" "));
    println!("chart, DOC       {}", row(&|h| rr(100.0, h, 1, 1, 0, false)));
    println!("chart, DIC       {}", row(&|h| rr(100.0, h, 1, 1, 1, false)));
    println!("chart, eight     {}", CASES.iter().map(|c| format!("{:6.2}", prices[&(c.0, 0)])).collect::<Vec<_>>().join(" "));
    println!("try: UOC barrier 150 {:.6}; DOC barrier 99 {:.6}; UIP barrier 105 {:.6}", rr(100.0, 150.0, 1, -1, 0, false), rr(100.0, 99.0, 1, 1, 0, false), rr(100.0, 105.0, -1, -1, 1, false));
    assert!((prices[&("DOC", 0)] - 9.133306).abs() < 1e-6 && (prices[&("DIC", 0)] - 0.093699).abs() < 1e-6);
    assert!(worst_int < 1e-7, "formula and reflected-density integral must agree");
    assert!(worst_z < 4.0, "simulation within four standard errors of every formula price");
    assert!(m_mc > prices[&("DOC", 0)], "month-end checks miss touches, so the price comes out high");
    println!("worst formula-integral gap {:.1e}; worst simulation gap {:.2} standard errors", worst_int, worst_z);
    println!("ALL CHECKS PASS");
}
