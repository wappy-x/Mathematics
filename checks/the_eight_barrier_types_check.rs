// The eight single barriers -- the check behind the card.  Rust std only, no crates.  House FX market:
// EURUSD 1.10, strike 1.10, USD 5%, EUR 3%, vol 10%, 1 year, walls 1.05 and 1.20; USD per 1 EUR.
// Roads: (1) blocks A-F; (2) in + out = vanilla; (3) Simpson integral of payoff times bridge survival;
// (4) Monte Carlo with its own random numbers; (5) rebate at hit from the first-hitting-time density.
use std::f64::consts::PI;
const S0: f64 = 1.10; const K: f64 = 1.10; const RD: f64 = 0.05; const RF: f64 = 0.03;
const VOL: f64 = 0.10; const T: f64 = 1.0; const LO: f64 = 1.05; const HI: f64 = 1.20; const R: f64 = 0.005;

fn n(x: f64) -> f64 { // normal CDF, own series: 0.5 + phi(x)(x + x^3/3 + x^5/15 + ...)
    if x.abs() > 9.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    let (mut term, mut total, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * total.abs() || k < 5.0 {
        term *= x * x / (2.0 * k + 1.0); total += term; k += 1.0;
    }
    0.5 + total * (-0.5 * x * x).exp() / (2.0 * PI).sqrt()
}

// name, barrier, eta, phi, coefficients on A B C D, blocks in words, strike
struct Ty(&'static str, f64, f64, f64, [f64; 4], &'static str, f64);
const TYPES: [Ty; 8] = [Ty("DOC", LO, 1.0, 1.0, [1.0, 0.0, -1.0, 0.0], "A-C", K), Ty("DIC", LO, 1.0, 1.0, [0.0, 0.0, 1.0, 0.0], "C", K),
    Ty("DOP", LO, 1.0, -1.0, [1.0, -1.0, 1.0, -1.0], "A-B+C-D", K), Ty("DIP", LO, 1.0, -1.0, [0.0, 1.0, -1.0, 1.0], "B-C+D", K),
    Ty("UOC", HI, -1.0, 1.0, [1.0, -1.0, 1.0, -1.0], "A-B+C-D", K), Ty("UIC", HI, -1.0, 1.0, [0.0, 1.0, -1.0, 1.0], "B-C+D", K),
    Ty("UOP", HI, -1.0, -1.0, [1.0, 0.0, -1.0, 0.0], "A-C", K), Ty("UIP", HI, -1.0, -1.0, [0.0, 0.0, 1.0, 0.0], "C", K)];
const OTHER: [Ty; 8] = [Ty("DOC", LO, 1.0, 1.0, [0.0, 1.0, 0.0, -1.0], "B-D", 1.0), Ty("DIC", LO, 1.0, 1.0, [1.0, -1.0, 0.0, 1.0], "A-B+D", 1.0),
    Ty("DOP", LO, 1.0, -1.0, [0.0; 4], "0", 1.0), Ty("DIP", LO, 1.0, -1.0, [1.0, 0.0, 0.0, 0.0], "A", 1.0),
    Ty("UOC", HI, -1.0, 1.0, [0.0; 4], "0", 1.25), Ty("UIC", HI, -1.0, 1.0, [1.0, 0.0, 0.0, 0.0], "A", 1.25),
    Ty("UOP", HI, -1.0, -1.0, [0.0, 1.0, 0.0, -1.0], "B-D", 1.25), Ty("UIP", HI, -1.0, -1.0, [1.0, -1.0, 0.0, 1.0], "A-B+D", 1.25)];

fn blocks(s0: f64, v: f64, h: f64, eta: f64, phi: f64, b: f64, k: f64) -> [f64; 15] {
    let s = v * T.sqrt(); let mu = (b - 0.5 * v * v) / (v * v); let lam = (mu * mu + 2.0 * RD / (v * v)).sqrt();
    let x1 = (s0 / k).ln() / s + (1.0 + mu) * s; let x2 = (s0 / h).ln() / s + (1.0 + mu) * s;
    let y1 = (h * h / (s0 * k)).ln() / s + (1.0 + mu) * s; let y2 = (h / s0).ln() / s + (1.0 + mu) * s;
    let z = (h / s0).ln() / s + lam * s;
    let (fs, fk) = (s0 * (-RF * T).exp(), k * (-RD * T).exp());
    let (hp, hm) = ((h / s0).powf(2.0 * mu + 2.0), (h / s0).powf(2.0 * mu));
    let a = phi * fs * n(phi * x1) - phi * fk * n(phi * x1 - phi * s);
    let bb = phi * fs * n(phi * x2) - phi * fk * n(phi * x2 - phi * s);
    let c = phi * fs * hp * n(eta * y1) - phi * fk * hm * n(eta * y1 - eta * s);
    let d = phi * fs * hp * n(eta * y2) - phi * fk * hm * n(eta * y2 - eta * s);
    let e = (-RD * T).exp() * (n(eta * x2 - eta * s) - hm * n(eta * y2 - eta * s)); // 1 USD at expiry if never hit
    let f = (h / s0).powf(mu + lam) * n(eta * z) + (h / s0).powf(mu - lam) * n(eta * z - 2.0 * eta * lam * s); // 1 USD at hit
    [a, bb, c, d, e, f, mu, lam, x1, x2, y1, y2, z, hp, hm]
}
fn price(t: &Ty, s0: f64, v: f64, b: f64) -> f64 {
    let bl = blocks(s0, v, t.1, t.2, t.3, b, t.6);
    (0..4).fold(0.0, |acc, i| acc + t.4[i] * bl[i])
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64; let mut tot = f(a) + f(b);
    for i in 1..m { tot += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    tot * h / 3.0
}
fn by_integral(t: &Ty) -> f64 { // road 3: survival chance of a bridge pinned at both ends
    let out = t.0.as_bytes()[1] == b'O';
    let (a, m, s) = ((t.1 / S0).ln(), (RD - RF - 0.5 * VOL * VOL) * T, VOL * T.sqrt());
    let f = |z: f64| {
        let x = m + s * z; let pay = (t.3 * (S0 * x.exp() - t.6)).max(0.0);
        let live = if t.2 == 1.0 { x > a } else { x < a };
        let surv = if live { 1.0 - (-2.0 * a * (a - x) / (s * s)).exp() } else { 0.0 };
        pay * (if out { surv } else { 1.0 - surv }) * (-0.5 * z * z).exp() / (2.0 * PI).sqrt()
    };
    (-RD * T).exp() * simpson(&f, -9.0, 9.0, 20000)
}
fn hit_integral(h: f64) -> f64 { // road 5: first-hitting-time density, discounted
    let (a, nu) = ((h / S0).ln(), RD - RF - 0.5 * VOL * VOL);
    let f = |t: f64| if t == 0.0 { 0.0 } else {
        (-RD * t).exp() * a.abs() / (VOL * (2.0 * PI * t.powf(3.0)).sqrt()) * (-(a - nu * t).powf(2.0) / (2.0 * VOL * VOL * t)).exp()
    };
    simpson(&f, 0.0, T, 20000)
}
struct Rng(u64);
impl Rng { // splitmix64, then 53 bits into (0, 1)
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}
fn monte_carlo(paths: usize, steps: usize) -> ([f64; 12], [f64; 12]) { // road 4: bridge test each step
    let mut g = Rng(20260927);
    let dt = T / steps as f64; let (drift, sd) = ((RD - RF - 0.5 * VOL * VOL) * dt, VOL * dt.sqrt());
    let (al, ah, disc) = ((LO / S0).ln(), (HI / S0).ln(), (-RD * T).exp());
    let (mut sm, mut sq) = ([0.0f64; 12], [0.0f64; 12]);
    for _ in 0..paths {
        let (mut x, mut tl, mut th) = (0.0f64, -1.0f64, -1.0f64);
        for i in 0..steps {
            let u1 = g.unif(); let u2 = g.unif();
            let z = (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos(); let (u3, u4) = (g.unif(), g.unif());
            let y = x + drift + sd * z;
            if tl < 0.0 && (y <= al || u3 < (-2.0 * (x - al) * (y - al) / (sd * sd)).exp()) { tl = (i as f64 + 0.5) * dt; }
            if th < 0.0 && (y >= ah || u4 < (-2.0 * (ah - x) * (ah - y) / (sd * sd)).exp()) { th = (i as f64 + 0.5) * dt; }
            x = y;
        }
        let (c, p) = ((S0 * x.exp() - K).max(0.0) * disc, (K - S0 * x.exp()).max(0.0) * disc);
        let (hl, hh) = (tl >= 0.0, th >= 0.0);
        let (o, i_) = (|hit: bool, val: f64| if hit { 0.0 } else { val }, |hit: bool, val: f64| if hit { val } else { 0.0 });
        let v = [o(hl, c), i_(hl, c), o(hl, p), i_(hl, p), o(hh, c), i_(hh, c), o(hh, p), i_(hh, p),
                 if hl { (-RD * tl).exp() } else { 0.0 }, if hh { (-RD * th).exp() } else { 0.0 }, o(hl, disc), o(hh, disc)];
        for k in 0..12 { sm[k] += v[k]; sq[k] += v[k] * v[k]; }
    }
    let (mut mean, mut se) = ([0.0f64; 12], [0.0f64; 12]);
    for k in 0..12 {
        mean[k] = sm[k] / paths as f64; se[k] = ((sq[k] / paths as f64 - mean[k].powf(2.0)).max(0.0) / paths as f64).sqrt();
    }
    (mean, se)
}
fn gk(phi: f64, s: f64, k: f64) -> f64 { // Garman-Kohlhagen vanilla, written the usual way
    let d1 = ((s / k).ln() + (RD - RF + 0.5 * VOL * VOL) * T) / (VOL * T.sqrt()); let d2 = d1 - VOL * T.sqrt();
    phi * (s * (-RF * T).exp() * n(phi * d1) - k * (-RD * T).exp() * n(phi * d2))
}
fn row(xs: &[f64], w: usize, p: usize, f: &dyn Fn(f64) -> f64) -> String {
    xs.iter().map(|&x| format!("{:w$.p$}", f(x), w = w, p = p)).collect::<Vec<_>>().join(" ")
}
fn main() {
    let b0 = RD - RF; let van = [gk(1.0, S0, K), gk(-1.0, S0, K)];
    let (mc, se) = monte_carlo(200000, 20);
    println!("vanilla EUR call {:.6}   vanilla EUR put {:.6}", van[0], van[1]);
    for (h, eta) in [(LO, 1.0), (HI, -1.0)] {
        let bl = blocks(S0, VOL, h, eta, 1.0, b0, K);
        println!("blocks, call, H={:.2}   {}", h, bl[..6].iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join("  "));
        println!("pieces, H={:.2} mu lam x1 x2 y1 y2 z hp hm {}", h, bl[6..].iter().map(|x| format!("{:.6}", x)).collect::<Vec<_>>().join(" "));
    }
    println!("type blocks      formula  integral  monte-carlo   se      delta    vega/pt");
    let mut p = [0.0f64; 8];
    for (k, t) in TYPES.iter().enumerate() {
        p[k] = price(t, S0, VOL, b0); let i = by_integral(t);
        let dl = (price(t, S0 + 1e-4, VOL, b0) - price(t, S0 - 1e-4, VOL, b0)) / 2e-4;
        let vg = (price(t, S0, VOL + 1e-4, b0) - price(t, S0, VOL - 1e-4, b0)) / 2e-4 * 0.01;
        println!("{}  {:<9} {:9.6} {:9.6} {:9.6} {:9.6} {:8.4} {:9.6}", t.0, t.5, p[k], i, mc[k], se[k], dl, vg);
        assert!((i - p[k]).abs() < 1e-7, "{}", t.0);
        assert!((mc[k] - p[k]).abs() < 4.0 * se[k], "{}", t.0);
    }
    for (o, ph) in [(0usize, 0usize), (2, 1), (4, 0), (6, 1)] {
        println!("parity {}+{} {:.9}  vanilla {:.9}", TYPES[o].0, TYPES[o + 1].0, p[o] + p[o + 1], van[ph]);
        assert!((p[o] + p[o + 1] - van[ph]).abs() < 1e-12);
    }
    let mut q = [0.0f64; 8];
    for (k, t) in OTHER.iter().enumerate() { // the barrier on the other side of the strike
        q[k] = price(t, S0, VOL, b0); let i = by_integral(t);
        println!("other side, {} K={:.2} {:<6} formula {:.6}  integral {:.6}", t.0, t.6, t.5, q[k], i);
        assert!((i - q[k]).abs() < 1e-7 && (k % 2 == 0 || (q[k] + q[k - 1] - gk(t.3, S0, t.6)).abs() < 1e-12));
    }
    for (j, (h, eta)) in [(LO, 1.0), (HI, -1.0)].iter().enumerate() {
        let bl = blocks(S0, VOL, *h, *eta, 1.0, b0, K); let fi = hit_integral(*h);
        println!("1 USD at hit, H={:.2}: F {:.6}  density {:.6}  mc {:.6}", h, bl[5], fi, mc[8 + j]);
        println!("1 USD at expiry if untouched, H={:.2}: E {:.6}  mc {:.6}", h, bl[4], mc[10 + j]);
        assert!((fi - bl[5]).abs() < 1e-7 && (mc[8 + j] - bl[5]).abs() < 4.0 * se[8 + j] && (mc[10 + j] - bl[4]).abs() < 4.0 * se[10 + j]);
    }
    let (bu, bd) = (blocks(S0, VOL, HI, -1.0, 1.0, b0, K), blocks(S0, VOL, LO, 1.0, 1.0, b0, K));
    let (eu, fu, ed) = (bu[4], bu[5], bd[4]);
    println!("one-touch 1.20, 1 USD at expiry = e^-rT - E {:.6}", (-RD * T).exp() - eu);
    println!("UOC share of vanilla {:.4}   UIC share {:.4}", p[4] / van[0], p[5] / van[0]);
    println!("UOC + 0.005 rebate at hit {:.6}   at expiry {:.6}", p[4] + R * fu, p[4] + R * ((-RD * T).exp() - eu));
    println!("DIC + 0.005 rebate at expiry if never in {:.6}", p[1] + R * ed);
    println!("wrong: UOC by the regular pair A-C {:.6}", bu[0] - bu[2]);
    println!("wrong: DOC with the EUR rate left out of mu {:.6}", price(&TYPES[0], S0, VOL, RD));
    println!("wrong: UIC+rebate as vanilla - (UOC+rebate at hit) {:.6}  right {:.6}", van[0] - p[4] - R * fu, p[5] + R * eu);
    let xs: Vec<f64> = (0..11).map(|i| 1.00 + 0.02 * i as f64).collect();
    println!("chart, spot today    {}", row(&xs, 6, 2, &|x| x));
    println!("chart, vanilla cents {}", row(&xs, 6, 2, &|x| 100.0 * gk(1.0, x, K)));
    for t in &TYPES[4..6] {
        println!("chart, {}     cents {}", t.0, row(&xs, 6, 2, &|x| { let v = price(t, x, VOL, b0); 100.0 * (if v.abs() > 1e-12 { v } else { 0.0 }) }));
    }
    let xs: Vec<f64> = (0..13).map(|i| 1.00 + 0.025 * i as f64).collect();
    println!("payoff, EURUSD at expiry {}", row(&xs, 5, 3, &|x| x));
    println!("payoff, vanilla   cents  {}", row(&xs, 5, 2, &|x| 100.0 * (x - K).max(0.0)));
    println!("payoff, UOC       cents  {}", row(&xs, 5, 2, &|x| 100.0 * (x - K).max(0.0) * (if x < HI - 1e-9 { 1.0 } else { 0.0 })));
    println!("ALL CHECKS PASS");
}
