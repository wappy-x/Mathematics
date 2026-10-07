// Arithmetic Asian options -- the same check as the Python, in Rust.  No crates.
// House market, 52 weekly fixings.  Nothing imported knows the answer: the
// bell-curve area is a series written out, the random numbers come from a
// splitmix64 generator written out, and the paths are simulated step by step.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0;
const R: f64 = 0.05; const Q: f64 = 0.02;     // bank rate, dividend yield
const SIGMA: f64 = 0.20; const T: f64 = 1.0; const NF: usize = 52;
fn disc() -> f64 { (-R * T).exp() }

fn ncdf(x: f64) -> f64 {                   // area left of x: Marsaglia's series
    if x < -9.0 { return 0.0 }
    if x > 9.0 { return 1.0 }
    let (mut s, mut t, mut b, mut i) = (x, 0.0, x, 1.0);
    while s != t {
        i += 2.0;
        b *= x * x / i;
        t = s;
        s += b;
    }
    0.5 + s * (-0.5 * x * x - 0.91893853320467274178).exp()
}

fn black(f: f64, v: f64) -> f64 {          // call on a lognormal with forward f, log-spread v
    let d1 = ((f / K).ln() + 0.5 * v * v) / v;
    disc() * (f * ncdf(d1) - K * ncdf(d1 - v))
}

fn fixings(m: usize) -> Vec<f64> {         // m equally spaced dates, the last at T
    (0..m).map(|i| T * (i + 1) as f64 / m as f64).collect()
}

fn kemna_vorst(m: usize) -> (f64, f64) {   // geometric twin, exact (sibling card 01)
    let mf = m as f64;
    let tbar = T * (mf + 1.0) / (2.0 * mf);
    let var = SIGMA * SIGMA * T * (mf + 1.0) * (2.0 * mf + 1.0) / (6.0 * mf * mf);
    let f_g = S * ((R - Q - 0.5 * SIGMA * SIGMA) * tbar + 0.5 * var).exp();
    (black(f_g, var.sqrt()), f_g)
}

fn turnbull_wakeman(m: usize, spot: f64, vol: f64) -> (f64, f64, f64, f64) {
    let ts = fixings(m);                   // moment-matched lognormal for the average
    let (mf, mut m1, mut m2) = (m as f64, 0.0, 0.0);
    for &a in &ts {                        // exact first and second moments of the average
        m1 += spot * ((R - Q) * a).exp() / mf;
        for &b in &ts {
            m2 += spot * spot * ((R - Q) * (a + b) + vol * vol * a.min(b)).exp() / (mf * mf);
        }
    }
    let va = (m2 / (m1 * m1)).ln().sqrt();
    (black(m1, va), m1, va, m2)
}

fn uniform(state: &mut u64) -> f64 {       // splitmix64: 64-bit integer mixing
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
}

fn normal(state: &mut u64) -> f64 {        // Box-Muller, one draw per pair of uniforms
    let (u1, u2) = (uniform(state), uniform(state));
    (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
}

// mean, plain error bar, controlled mean and bar, rho, control's mean and bar
fn cv(s1: f64, s11: f64, s2: f64, s22: f64, s12: f64, known: f64, p: f64) -> [f64; 7] {
    let (m1, m2) = (s1 / p, s2 / p);
    let (v1, v2, c12) = (s11 / p - m1 * m1, s22 / p - m2 * m2, s12 / p - m1 * m2);
    let beta = c12 / v2;
    [m1, (v1 / p).sqrt(), m1 - beta * (m2 - known), ((v1 - beta * c12) / p).sqrt(),
     c12 / (v1 * v2).sqrt(), m2, (v2 / p).sqrt()]
}

fn greeks(m: usize) -> [f64; 3] {          // bumps for the Greeks, on Turnbull-Wakeman
    let (h, hv) = (0.01, 0.0001);
    let [up, mid, dn] = [h, 0.0, -h].map(|s| turnbull_wakeman(m, S * (1.0 + s), SIGMA).0);
    let (vup, vdn) = (turnbull_wakeman(m, S, SIGMA + hv).0, turnbull_wakeman(m, S, SIGMA - hv).0);
    [(up - dn) / (2.0 * S * h), (up - 2.0 * mid + dn) / ((S * h) * (S * h)), (vup - vdn) / (2.0 * hv) / 100.0]
}

fn main() {
    // ---- roads 1 and 2: 50,000 weekly paths; the geometric payoff rides along as control
    let (paths, dt, disc) = (50000usize, T / NF as f64, disc());
    let (drift, step) = ((R - Q - 0.5 * SIGMA * SIGMA) * dt, SIGMA * dt.sqrt());
    let (kv, f_g) = kemna_vorst(NF);
    let (tw, m1, va, m2) = turnbull_wakeman(NF, S, SIGMA);
    let mut st: u64 = 20260924;
    let mut acc = [0.0f64; 12];            // sx sxx sy syy sxy sa saa sf sff sw sww sfw
    for _ in 0..paths {
        let (mut x, mut tot, mut totlog) = (S.ln(), 0.0, 0.0);
        for _ in 0..NF {
            x += drift + step * normal(&mut st);
            tot += x.exp();
            totlog += x;
        }
        let (a, g, st_t) = (tot / NF as f64, (totlog / NF as f64).exp(), x.exp());
        let (xa, yg) = (disc * (a - K).max(0.0), disc * (g - K).max(0.0));
        let (fl, w) = (disc * (st_t - a).max(0.0), disc * (st_t - a));
        for (k, v) in [xa, xa * xa, yg, yg * yg, xa * yg, a, a * a, fl, fl * fl, w, w * w, fl * w].iter().enumerate() {
            acc[k] += v;
        }
    }
    let p = paths as f64;
    let [plain, se_plain, ctrl, se_ctrl, rho, geo_sim, se_geo] = cv(acc[0], acc[1], acc[2], acc[3], acc[4], kv, p);
    let f_t = S * ((R - Q) * T).exp();    // floating strike: control S_T - A is worth disc*(F - M1)
    let fwd_known = disc * (f_t - m1);
    let fl = cv(acc[7], acc[8], acc[9], acc[10], acc[11], fwd_known, p);
    let (mean_a, se_a) = (acc[5] / p, ((acc[6] / p - (acc[5] / p) * (acc[5] / p)) / p).sqrt());
    let vanilla = turnbull_wakeman(1, S, SIGMA).0;
    let upper = kv + disc * (m1 - f_g);   // A - G >= (A-K)+ - (G-K)+ >= 0, path by path
    let (house, e1) = (kemna_vorst(10_000_000).0, ((m1 / K).ln() + 0.5 * va * va) / va);

    let (fx, mut m3) = (fixings(NF), 0.0); // m3: exact third moment, each pair of three dates sharing shoves
    for &a in &fx { for &b in &fx { for &c in &fx {
        m3 += S * S * S * ((R - Q) * (a + b + c) + SIGMA * SIGMA * (a.min(b) + a.min(c) + b.min(c))).exp() / (NF * NF * NF) as f64;
    } } }
    let (skew, skew_fit) = ((m3 - 3.0 * m1 * m2 + 2.0 * m1 * m1 * m1) / (m2 - m1 * m1).powf(1.5), (m2 / (m1 * m1) + 2.0) * (m2 / (m1 * m1) - 1.0).sqrt());
    println!("{:<38}{:>12.6}{:>12.6}", "fixings, first and last (years)", fx[0], fx[NF - 1]);
    let rows: [(&str, f64); 39] = [("vanilla call, Black-Scholes", vanilla), ("mean of the average M1, exact", m1),
        ("  simulated", mean_a), ("  its error bar", se_a), ("second moment M2, exact", m2),
        ("M2 / M1^2", m2 / (m1 * m1)), ("log-spread of the average vA", va),
        ("log-spread of one price, sigma*sqrt(T)", SIGMA * T.sqrt()),
        ("cut-off e1", e1), ("cut-off e2 = e1 - vA", e1 - va), ("N(e1)", ncdf(e1)), ("N(e2)", ncdf(e1 - va)),
        ("discount e^-rT", disc), ("geometric twin, Kemna-Vorst", kv), ("  simulated", geo_sim), ("  its error bar", se_geo),
        ("geometric forward F_G", f_g), ("1 plain simulation", plain), ("  its error bar", se_plain),
        ("2 control-variate simulation", ctrl), ("  its error bar", se_ctrl), ("  correlation rho", rho),
        ("  error bar shrinks by", se_plain / se_ctrl), ("3 Turnbull-Wakeman", tw),
        ("  minus road 2", tw - ctrl), ("  skewness of the average, exact", skew),
        ("  skewness of the fitted lognormal", skew_fit), ("4 floor: geometric twin", kv),
        ("  ceiling: twin + disc*(M1 - F_G)", upper), ("arithmetic / vanilla", ctrl / vanilla),
        ("floating strike, plain", fl[0]), ("  its error bar", fl[1]), ("floating strike, controlled", fl[2]),
        ("  its error bar", fl[3]), ("expiry forward F", f_t),
        ("dial: lower spread only", black(f_t, va)), ("dial: lower forward only", black(m1, SIGMA * T.sqrt())),
        ("wrong: fixings as independent draws", black(m1, SIGMA * (T / NF as f64).sqrt())),
        ("house check: continuous geometric", house)];
    for (name, v) in rows.iter() {
        println!("{:<38}{:>12.6}", name, v);
    }
    for (label, m) in [("greeks, Asian (delta gamma vega/pt)", NF), ("greeks, vanilla", 1)] {
        let g = greeks(m);
        println!("{:<38}{:>10.4}{:>10.4}{:>10.4}", label, g[0], g[1], g[2]);
    }
    let ns = [1usize, 4, 12, 52, 252];
    let line = |f: &dyn Fn(usize) -> f64| ns.iter().map(|&m| format!("{:>8.2}", f(m))).collect::<String>();
    println!("{:<38}{}", "chart, fixings n", ns.iter().map(|m| format!("{:>8}", m)).collect::<String>());
    println!("{:<38}{}", "chart, Turnbull-Wakeman", line(&|m| turnbull_wakeman(m, S, SIGMA).0));
    println!("{:<38}{}", "chart, Kemna-Vorst", line(&|m| kemna_vorst(m).0));
    println!("{:<38}{}", "bars, price ladder", [vanilla, black(f_t, va), black(m1, SIGMA * T.sqrt()), tw, ctrl, kv]
             .iter().map(|v| format!("{:>8.2}", v)).collect::<String>());
    let avgs: Vec<i32> = (0..11).map(|i| 80 + 5 * i).collect();
    println!("{:<38}{}", "chart, average at expiry", avgs.iter().map(|a| format!("{:>7}", a)).collect::<String>());
    println!("{:<38}{}", "chart, profit after premium",
             avgs.iter().map(|&a| format!("{:>7.2}", (a as f64 - K).max(0.0) - ctrl)).collect::<String>());

    assert!((vanilla - 9.227005508154).abs() < 1e-9, "one fixing: the average is S_T, so Black-Scholes");
    assert!((house - 4.985760).abs() < 2e-6, "many fixings: the shelf's continuous geometric");
    assert!((geo_sim - kv).abs() < 3.0 * se_geo, "the paths reproduce the exact geometric price");
    assert!((mean_a - m1).abs() < 3.0 * se_a, "the paths reproduce the exact mean of the average");
    assert!(kv < ctrl && ctrl < upper, "controlled price inside the AM-GM floor and ceiling");
    assert!((ctrl - plain).abs() < 3.0 * se_plain, "the control moves the price by less than the plain bar");
    assert!(se_plain / se_ctrl > 10.0, "the control shrinks the error bar at least tenfold");
    assert!((tw - ctrl).abs() < 0.03, "moment matching within three cents of the simulation");
    assert!((fl[5] - fwd_known).abs() < 3.0 * fl[6], "the paths reproduce the exact value of S_T - A");
    assert!((fl[2] - fl[0]).abs() < 3.0 * fl[1], "floating strike: control agrees with plain");
    assert!(skew > skew_fit, "the true average is more lopsided than the fitted lognormal");
    println!("ALL CHECKS PASS");
}
