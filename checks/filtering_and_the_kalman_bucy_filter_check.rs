// Kalman-Bucy filter -- the same check as filtering_and_the_kalman_bucy_filter_check.py, in Rust.
// Standard library only, no crates.  A hidden rate X_t (percentage points, t in years) follows
// dX = -A (X - TH) dt + SIG dW; quotes arrive as dY = X dt + RHO dB.  Roads: the Riccati closed
// form; the same equation by RK4; the discrete Kalman filter with shrinking steps; the best fixed
// gain by golden section; 2000 simulated years from SplitMix64 and Box-Muller normals.
use std::f64::consts::PI;

const A: f64 = 2.0; const TH: f64 = 4.0; const SIG: f64 = 1.0; const S_Q: f64 = 0.5; const DAY: f64 = 1.0 / 250.0;
const RHO2: f64 = S_Q * S_Q * DAY; const P0: f64 = SIG * SIG / (2.0 * A); const M0: f64 = TH;
const SEED: u64 = 20260930; const PATHS: usize = 2000; const SUB: usize = 10;

fn lam() -> f64 { (A * A + SIG * SIG / RHO2).sqrt() }     // the filter's forgetting rate, per year
fn pp() -> f64 { RHO2 * (lam() - A) }
fn pm() -> f64 { -RHO2 * (lam() + A) }

fn p_closed(t: f64) -> f64 {                // (P - PP)/(P - PM) decays like e^(-2 LAM t)
    let c = (P0 - pp()) / (P0 - pm()) * (-2.0 * lam() * t).exp();
    (pp() - pm() * c) / (1.0 - c)
}

fn ric(p: f64, sig2: f64) -> f64 { -2.0 * A * p + sig2 - p * p / RHO2 }

fn rk4(f: &dyn Fn([f64; 2]) -> [f64; 2], mut y: [f64; 2], t: f64, n: usize) -> [f64; 2] {
    let h = t / n as f64;
    let step = |y: [f64; 2], k: [f64; 2], s: f64| [y[0] + s * k[0], y[1] + s * k[1]];
    for _ in 0..n {
        let k1 = f(y); let k2 = f(step(y, k1, h / 2.0));
        let k3 = f(step(y, k2, h / 2.0)); let k4 = f(step(y, k3, h));
        for i in 0..2 { y[i] = y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
    }
    y
}

fn discrete_kf(h: f64, t: f64) -> f64 {     // exact OU predict, update on y = x + noise, R = RHO2/h
    let (phi, mut p, r) = ((-A * h).exp(), P0, RHO2 / h);
    let q = SIG * SIG * (1.0 - phi * phi) / (2.0 * A);
    for _ in 0..(t / h).round() as usize { p = phi * phi * p + q; p = p * r / (p + r); }
    p
}

fn v_const(k: f64) -> f64 { (SIG * SIG + k * k * RHO2) / (2.0 * (A + k)) }

struct SplitMix64 { s: u64 }                 // the wing's generator, written out
impl SplitMix64 {
    fn uniform(&mut self) -> f64 {
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn normal(&mut self) -> f64 {            // Box-Muller, cosine half only
        let u1 = 1.0 - self.uniform(); let u2 = self.uniform();
        (-2.0 * u1.ln()).sqrt() * (2.0 * PI * u2).cos()
    }
}

fn total(xs: &[f64]) -> f64 { let mut s = 0.0; for x in xs { s += *x; } s }

fn mse(xs: &[f64]) -> (f64, f64) {
    let n = xs.len() as f64; let m = total(xs) / n;
    let d: Vec<f64> = xs.iter().map(|x| (x - m) * (x - m)).collect();
    (m, (total(&d) / (n - 1.0) / n).sqrt())
}

fn main() {
    let (lm, ppv, pmv) = (lam(), pp(), pm());
    println!("pull A {:.1}/yr, level {:.1}, noise {:.1}, quote error {:.1} per day, rho^2 {:.6}, prior var {:.4}", A, TH, SIG, S_Q, RHO2, P0);
    println!("forgetting rate lambda {:.6}/yr = 1 / {:.4} trading days; roots {:.6}, {:.6}", lm, 250.0 / lm, ppv, pmv);
    println!("one trading day {:.3} years; gain at the start P0/rho^2 {:.1}/yr", DAY, P0 / RHO2);
    println!("steady state: P {:.6}, sd {:.4} points, gain K {:.6}/yr, worth {:.4} days of quotes", ppv, ppv.sqrt(), ppv / RHO2, S_Q * S_Q / ppv);
    println!("hand: sigma^2/rho^2 {:.1}, a^2 + that {:.1}, P0 - PP {:.6}, P0 - PM {:.6}, c {:.6}",
             SIG * SIG / RHO2, A * A + SIG * SIG / RHO2, P0 - ppv, P0 - pmv, (P0 - ppv) / (P0 - pmv));
    let e5 = (-2.0 * lm * 5.0 * DAY).exp(); let c5 = (P0 - ppv) / (P0 - pmv) * e5;
    println!("hand, day 5: 2 lambda t {:.6}, e^-that {:.6}, c e^-that {:.6}, P {:.6}", 2.0 * lm * 5.0 * DAY, e5, c5, (ppv - pmv * c5) / (1.0 - c5));
    for d in [0usize, 1, 2, 5, 10, 20, 250] {
        let t = d as f64 * DAY;
        let pr = if d > 0 { rk4(&|y| [ric(y[0], SIG * SIG), 0.0], [P0, 0.0], t, 4000)[0] } else { P0 };
        println!("day {:3}: P closed {:.6}, RK4 {:.6}, sd {:.4} points", d, p_closed(t), pr, p_closed(t).sqrt());
        if d > 0 { assert!((pr - p_closed(t)).abs() < 1e-12); }   // day 0 is the start itself
    }
    let mut errs = vec![];
    for n in [1usize, 10, 100, 1000] {
        let pd = discrete_kf(DAY / n as f64, 5.0 * DAY);
        errs.push((pd - p_closed(5.0 * DAY)).abs());
        println!("discrete filter, {:4} quotes a day: P at day 5 {:.8}, off by {:.8}", n, pd, errs[errs.len() - 1]);
    }
    assert!(errs[3] < errs[2] / 5.0 && errs[2] / 5.0 < errs[1] / 25.0 && errs[1] / 25.0 < errs[0] / 125.0);
    let dd = discrete_kf(DAY, 1.0);
    let pb = (-2.0 * A * DAY).exp() * dd + SIG * SIG * (1.0 - (-2.0 * A * DAY).exp()) / (2.0 * A);
    println!("discrete daily filter, steady after-quote P {:.6}; before the quote {:.6}", dd, pb);
    assert!((pb * S_Q * S_Q / (pb + S_Q * S_Q) - dd).abs() < 1e-12 && dd < ppv && ppv < pb);
    let (mut lo, mut hi, gr) = (0.0f64, 200.0f64, (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 {
        let (k1, k2) = (hi - gr * (hi - lo), lo + gr * (hi - lo));
        if v_const(k1) < v_const(k2) { hi = k2; } else { lo = k1; }
    }
    println!("best fixed gain by golden section {:.6}/yr, error var {:.6}; gain x rho^2 {:.6}", lo, v_const(lo), lo * RHO2);
    assert!((lo - (lm - A)).abs() < 1e-6 && (v_const(lo) - ppv).abs() < 1e-12);
    for k in [0.0f64, 10.0, 100.0, 1000.0] { println!("fixed gain {:6.1}/yr: steady error var {:.6}", k, v_const(k)); }
    let lw = (A * A + SIG * SIG / (S_Q * S_Q)).sqrt();
    println!("mistake, S_Q^2 in place of rho^2: gain {:.6}/yr, steady error var {:.6}", lw - A, v_const(lw - A));
    for (sq, sg) in [(1.0f64, SIG), (S_Q, 2.0)] {
        let r2 = sq * sq * DAY; let lt = (A * A + sg * sg / r2).sqrt();
        println!("try: quote error {:.1}, noise {:.1}: lambda {:.4}, memory {:.2} days, gain {:.4}, P {:.6}, sd {:.4}", sq, sg, lt, 250.0 / lt, lt - A, r2 * (lt - A), (r2 * (lt - A)).sqrt());
    }
    let still = |y: [f64; 2]| [-2.0 * A * y[0] - y[0] * y[0] / RHO2,
                               -2.0 * (A + y[0] / RHO2) * y[1] + SIG * SIG + (y[0] / RHO2) * (y[0] / RHO2) * RHO2];
    let st = rk4(&still, [P0, P0], 1.0, 40000);
    println!("filter assuming no shocks (SIG = 0), at 1 year: claims var {:.6}, true error var {:.6}", st[0], st[1]);
    let wide = |y: [f64; 2]| [ric(y[0], SIG * SIG), -2.0 * (A + 1.5 * y[0] / RHO2) * y[1] + SIG * SIG + (1.5 * y[0] / RHO2) * (1.5 * y[0] / RHO2) * RHO2];
    let w_true = rk4(&wide, [P0, P0], 1.0, 40000)[1];      // true error of a filter run at 1.5 times the gain
    println!("filter at 1.5 times the Kalman-Bucy gain, at 1 year: true error var {:.6}", w_true);

    let mut g = SplitMix64 { s: SEED };
    let (dt, steps) = (DAY / SUB as f64, 250 * SUB);
    let phi = (-A * dt).exp(); let q = (SIG * SIG * (1.0 - phi * phi) / (2.0 * A)).sqrt();
    let c0 = 1.0 / P0 + 1.0 / (2.0 * A * RHO2);
    let gain: Vec<f64> = (0..steps).map(|k| p_closed(k as f64 * dt) / RHO2).collect();
    let gfro: Vec<f64> = (0..steps).map(|k| 1.0 / (c0 * (2.0 * A * k as f64 * dt).exp() - 1.0 / (2.0 * A * RHO2)) / RHO2).collect();
    let (mut kal, mut quote, mut lvl, mut frozen, mut early, mut bias, mut fig, mut worse) = (vec![], vec![], vec![], vec![], vec![], vec![], vec![], vec![]);
    for p in 0..PATHS {
        let mut x = TH + P0.sqrt() * g.normal();
        let (mut m, mut mf, mut mw, mut ydays, mut qd) = (M0, M0, M0, 0.0, 0.0);
        for k in 0..steps {
            let dy = x * dt + (RHO2 * dt).sqrt() * g.normal();
            m += -A * (m - TH) * dt + gain[k] * (dy - m * dt);
            mf += -A * (mf - TH) * dt + gfro[k] * (dy - mf * dt);
            mw += -A * (mw - TH) * dt + 1.5 * gain[k] * (dy - mw * dt);
            ydays += dy;
            x = TH + phi * (x - TH) + q * g.normal();
            if (k + 1) % SUB == 0 {
                qd = ydays / DAY; ydays = 0.0;
                if (k + 1) / SUB == 5 { early.push((x - m) * (x - m)); }
                if p == 0 && ((k + 1) / SUB) % 3 == 0 && (k + 1) / SUB <= 60 { fig.push((x, qd, m)); }
            }
        }
        kal.push((x - m) * (x - m)); quote.push((x - qd) * (x - qd)); lvl.push((x - TH) * (x - TH));
        frozen.push((x - mf) * (x - mf)); bias.push(x - m); worse.push((x - mw) * (x - mw) - (x - m) * (x - m));
    }
    let rows: [(&str, &Vec<f64>, f64); 6] = [("Kalman-Bucy at day 5", &early, p_closed(5.0 * DAY)), ("Kalman-Bucy at 1 year", &kal, p_closed(1.0)),
        ("latest daily quote", &quote, S_Q * S_Q + SIG * SIG * DAY / 3.0), ("long-run level 4", &lvl, P0), ("no-shock filter", &frozen, st[1]),
        ("1.5x gain minus K-B", &worse, w_true - p_closed(1.0))];   // same draws
    for (lab, xs, rf) in rows.iter() {
        let (v, se) = mse(xs);
        println!("simulated error var, {:21}: {:.6} +- {:.6} (formula {:.6})", lab, v, se, rf);
        assert!((v - rf).abs() < 4.0 * se);
    }
    let (b, sb) = (total(&bias) / PATHS as f64, (mse(&kal).0 / PATHS as f64).sqrt());
    println!("simulated mean error at 1 year {:.4} +- {:.4} points", b, sb);
    assert!(b.abs() < 4.0 * sb);
    let join = |v: Vec<String>| v.join(", ");
    println!("figure, trading day: {}", join((0..fig.len()).map(|i| format!("{}", 3 * i + 3)).collect()));
    println!("figure, true rate: {}", join(fig.iter().map(|r| format!("{:.2}", r.0)).collect()));
    println!("figure, daily quote: {}", join(fig.iter().map(|r| format!("{:.2}", r.1)).collect()));
    println!("figure, filter estimate: {}", join(fig.iter().map(|r| format!("{:.2}", r.2)).collect()));
    println!("figure, sd in basis points by day 0..20: {}", join((0..21).map(|d| format!("{:.2}", 100.0 * p_closed(d as f64 * DAY).sqrt())).collect()));
    println!("ALL CHECKS PASS");
}
