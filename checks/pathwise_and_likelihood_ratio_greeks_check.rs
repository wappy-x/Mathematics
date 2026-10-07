// Greeks inside the simulation -- the same check as the Python, in Rust.  No
// crates.  Nothing here already knows an answer: the bell-curve area is
// Simpson's rule written out here, the normal draws come from a generator
// written out here.  Four roads to every Greek.
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0; const CASH: f64 = 1.0;   // the digital pays $1
const HS: f64 = 0.01; const HV: f64 = 0.0001; const HP: f64 = 0.000001;   // the bumps
const NPATH: usize = 65536; const SEED: u64 = 20260919; const MODU: u64 = 1 << 32;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }  // bell-curve height
fn nz(v: f64) -> f64 { if v == 0.0 { 0.0 } else { v } }             // print 0, never -0

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {                           // bell-curve area to the left of x
    if x < -12.0 || x > 12.0 { return if x < 0.0 { 0.0 } else { 1.0 }; }
    0.5 + simpson(phi, 0.0, x, 2000)
}

fn dees(s: f64, sig: f64, t: f64) -> (f64, f64) {  // the two distances, d1 and d2
    let d2 = ((s / K).ln() + (R - Q - 0.5 * sig * sig) * t) / (sig * t.sqrt());
    (d2 + sig * t.sqrt(), d2)
}

fn call_px(s: f64, sig: f64, t: f64) -> f64 {
    let (d1, d2) = dees(s, sig, t);
    s * (-Q * t).exp() * ncdf(d1) - K * (-R * t).exp() * ncdf(d2)
}

fn dig_px(s: f64, sig: f64, t: f64) -> f64 { CASH * (-R * t).exp() * ncdf(dees(s, sig, t).1) }
fn terminal(z: f64, s: f64, sig: f64, t: f64) -> f64 { s * ((R - Q - 0.5 * sig * sig) * t + sig * t.sqrt() * z).exp() }
fn payoffs(st: f64) -> (f64, f64) { ((st - K).max(0.0), if st > K { CASH } else { 0.0 }) }

fn estimators(z: f64, s: f64, sig: f64, t: f64) -> [f64; 8] {
    let st = terminal(z, s, sig, t);
    let on = if st > K { 1.0 } else { 0.0 };       // the switch: Acme above the strike
    let disc = (-R * t).exp();
    let (dst_ds, dst_dsig) = (st / s, st * (t.sqrt() * z - sig * t));  // the path's slopes
    let (call_slope, dig_slope) = (on, 0.0);       // payoff slopes: a kink, and a jump
    let (pay_call, pay_dig) = payoffs(st);
    let w_s = z / (s * sig * t.sqrt());                               // score for spot
    let w_sig = (z * z - 1.0) / sig - t.sqrt() * z;                    // score for vol
    [disc * call_slope * dst_ds,   disc * pay_call * w_s,
     disc * call_slope * dst_dsig, disc * pay_call * w_sig,
     disc * dig_slope * dst_ds,    disc * pay_dig * w_s,
     disc * dig_slope * dst_dsig,  disc * pay_dig * w_sig]
}

fn quad(s: f64, sig: f64, t: f64, n: usize) -> ([f64; 8], [f64; 8]) {
    // Exact average and second moment of all eight estimators.  Every one of
    // them is zero below the strike crossing, so the panel starts just above it.
    let lo = -dees(s, sig, t).1 + 1e-11;
    let h = (12.0 - lo) / n as f64;
    let (mut m1, mut m2) = ([0.0f64; 8], [0.0f64; 8]);
    for i in 0..=n {
        let z = lo + i as f64 * h;
        let p = (if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(z);
        for (j, y) in estimators(z, s, sig, t).into_iter().enumerate() { m1[j] += p * y; m2[j] += p * y * y; }
    }
    for j in 0..8 { m1[j] = m1[j] * h / 3.0; m2[j] = m2[j] * h / 3.0; }
    (m1, m2)
}

fn draws(n: usize, seed: u64) -> Vec<f64> {   // a linear step, then Box-Muller
    let (mut out, mut st) = (Vec::with_capacity(n), seed);
    while out.len() < n {
        st = (1664525 * st + 1013904223) % MODU;
        let u = (st as f64 + 0.5) / MODU as f64;
        st = (1664525 * st + 1013904223) % MODU;
        let (rad, ang) = ((-2.0 * u.ln()).sqrt(), 2.0 * PI * ((st as f64 + 0.5) / MODU as f64));
        out.push(rad * ang.cos()); out.push(rad * ang.sin());
    }
    out
}

fn wrong<F: Fn(f64) -> f64>(f: F, lo: f64) -> f64 { simpson(|z| f(z) * phi(z), lo, 12.0, 4000) }

fn main() {
    let ((d1, d2), disc) = (dees(S, SIG, T), (-R * T).exp());
    let lo = -d2 + 1e-11;
    let exact = [(-Q * T).exp() * ncdf(d1), S * (-Q * T).exp() * phi(d1) * T.sqrt(),
                 CASH * disc * phi(d2) / (S * SIG * T.sqrt()), -CASH * disc * phi(d2) * d1 / SIG];
    let bumped = [(call_px(S + HS, SIG, T) - call_px(S - HS, SIG, T)) / (2.0 * HS),
                  (call_px(S, SIG + HV, T) - call_px(S, SIG - HV, T)) / (2.0 * HV),
                  (dig_px(S + HS, SIG, T) - dig_px(S - HS, SIG, T)) / (2.0 * HS),
                  (dig_px(S, SIG + HV, T) - dig_px(S, SIG - HV, T)) / (2.0 * HV)];
    let (m1, m2) = quad(S, SIG, T, 4000);
    let sd: Vec<f64> = (0..8).map(|j| (m2[j] - m1[j] * m1[j]).max(0.0).sqrt()).collect();
    let names = ["call delta pathwise", "call delta score", "call vega pathwise",
                 "call vega score", "digital delta score", "digital vega score"];
    let cols = [0usize, 1, 2, 3, 5, 7];
    let aims = [exact[0], exact[0], exact[1], exact[1], exact[2], exact[3]];
    println!("Acme: S=100 K=100 r=5% q=2% sigma=20% T=1; the digital pays $1 if Acme ends above 100");
    println!("d1 {:.6}   d2 {:.6}   call {:.6}   digital {:.6}", d1, d2, call_px(S, SIG, T), dig_px(S, SIG, T));
    println!("{:<16}{:>14}{:>14}{:>14}{:>14}", "Greek", "closed form", "price bump", "pathwise", "score");
    for (name, j) in [("call delta", 0usize), ("call vega", 2), ("digital delta", 4), ("digital vega", 6)] {
        println!("{:<16}{:>14.6}{:>14.6}{:>14.6}{:>14.6}", name, exact[j / 2], bumped[j / 2], nz(m1[j]), m1[j + 1]);
    }
    println!("five fixed draws, spot nudged {:.2} either way, the same draw kept:", HS);
    println!("{:>7}{:>16}{:>19}{:>22}", "Z", "Acme at expiry", "call payoff slope", "digital payoff slope");
    for z in [-1.0f64, -0.06, -0.04, 0.5, 2.0] {
        let (up, dn) = (payoffs(terminal(z, S + HS, SIG, T)), payoffs(terminal(z, S - HS, SIG, T)));
        println!("{:>7.2}{:>16.4}{:>19.6}{:>22.6}", z, terminal(z, S, SIG, T),
                 (up.0 - dn.0) / (2.0 * HS), (up.1 - dn.1) / (2.0 * HS));
    }
    println!("by hand: e^-rT {:.6}   e^-qT {:.6}   N(d1) {:.6}   phi(d2) {:.6}   S sigma sqrt(T) {:.6}",
             disc, (-Q * T).exp(), ncdf(d1), phi(d2), S * SIG * T.sqrt());
    println!("estimator spread per path, and the paths needed to pin the answer to 1 percent:");
    for (i, j) in cols.iter().enumerate() {
        println!("{:<22}{:>9}{:>13.6}{:>9}{:>12.6}{:>7}{:>9}", names[i], "average", m1[*j], "spread", sd[*j],
                 "paths", (100.0 * sd[*j] / m1[*j].abs()).powi(2) as i64 + 1);
    }
    let st_ = |z: f64| terminal(z, S, SIG, T);
    println!("what breaks:");
    for (name, right, got) in [
            ("switch dropped from the call's pathwise delta", exact[0], wrong(|z| disc * st_(z) / S, -12.0)),
            ("sigma-T term dropped from the call's pathwise vega", exact[1], wrong(|z| disc * st_(z) * T.sqrt() * z, lo)),
            ("drift term dropped from the digital's score vega", exact[3], wrong(|z| disc * CASH * (z * z - 1.0) / SIG, lo)),
            ("discount forgotten in the digital's score delta", exact[2], wrong(|z| CASH * z / (S * SIG * T.sqrt()), lo))] {
        println!("{:<52}{:>7}{:>12.6}{:>7}{:>12.6}", name, "right", right, "wrong", got);
    }
    let (mut tot, mut totsq, mut flips) = ([0.0f64; 8], [0.0f64; 8], 0usize);
    for z in draws(NPATH, SEED) {
        for (j, y) in estimators(z, S, SIG, T).into_iter().enumerate() { tot[j] += y; totsq[j] += y * y; }
        if (terminal(z, S + HP, SIG, T) > K) != (terminal(z, S - HP, SIG, T) > K) { flips += 1; }
    }
    println!("{} draws from the generator written above, shared by every estimator:", NPATH);
    let (mut mc, mut se) = (Vec::new(), Vec::new());
    for (i, j) in cols.iter().enumerate() {
        let mean = tot[*j] / NPATH as f64;
        let err = ((totsq[*j] - NPATH as f64 * mean * mean).max(0.0) / (NPATH - 1) as f64 / NPATH as f64).sqrt();
        mc.push(mean); se.push(err);
        println!("{:<22}{:>7}{:>13.6}{:>10}{:>11.6}{:>9}{:>13.6}", names[i], "mean", mean, "std err", err, "target", aims[i]);
    }
    println!("paths whose digital payoff moved when spot moved by {:.6}: {} of {}", HP, flips, NPATH);
    let spots: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let grid: Vec<f64> = (0..9).map(|i| -1.0 + 0.5 * i as f64).collect();
    let charts: [(&str, Vec<f64>); 6] = [
        ("chart, Acme's price now:        ", spots.clone()),
        ("chart, digital payoff at expiry:", spots.iter().map(|&x| payoffs(x).1).collect()),
        ("chart, digital price today:     ", spots.iter().map(|&x| dig_px(x, SIG, T)).collect()),
        ("chart, the draw Z:              ", grid.clone()),
        ("chart, call delta pathwise:     ", grid.iter().map(|&z| estimators(z, S, SIG, T)[0]).collect()),
        ("chart, call delta score:        ", grid.iter().map(|&z| estimators(z, S, SIG, T)[1]).collect())];
    for (label, vals) in &charts {
        println!("{}{}", label, vals.iter().map(|&v| format!("{:>7.2}", nz(v))).collect::<Vec<String>>().join(" "));
    }
    assert!((m1[0] - exact[0]).abs() < 1e-6 && (m1[1] - exact[0]).abs() < 1e-6, "both delta roads vs e^-qT N(d1)");
    assert!((m1[2] - exact[1]).abs() < 1e-5 && (m1[3] - exact[1]).abs() < 1e-5, "both vega roads vs S e^-qT phi(d1) sqrt(T)");
    assert!((m1[5] - exact[2]).abs() < 1e-8, "score digital delta vs e^-rT phi(d2)/(S sigma sqrt T)");
    assert!((m1[7] - exact[3]).abs() < 1e-8, "score digital vega vs -e^-rT phi(d2) d1/sigma");
    assert!(m1[4] == 0.0 && m1[6] == 0.0 && bumped[2] - m1[4] > 0.018, "pathwise is zero on the digital; the price slope is not");
    assert!(flips == 0, "no path's digital payoff moved under a millionth-dollar nudge");
    assert!((0..4).all(|i| (bumped[i] - exact[i]).abs() < 1e-5 * 1.0f64.max(exact[i].abs())), "price bumps vs closed forms");
    assert!((mc[0] - exact[0]).abs() < 4.0 * se[0], "simulated pathwise delta within four standard errors");
    assert!(sd[1] > 2.0 * sd[0], "the score's spread is more than double the pathwise spread");
    println!("ALL CHECKS PASS");
}
