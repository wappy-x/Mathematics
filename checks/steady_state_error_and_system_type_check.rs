// Steady-state error and system type -- the check behind the card.  Rust std only.
// A room (200 min lag) heated by a radiator through a slow pipe (10 min lag), with a thermostat.
// Roads: the final-value formula; a heat balance at rest; an RK4 simulation.  The frequency
// response near zero checks the s -> 0 limit.  Time in minutes, temperature in degC, power in W.
const U: f64 = 100.0; // heat loss, W/K
const KC: f64 = 1900.0; // thermostat gain, W/K
const TR: f64 = 200.0; // room lag, min
const TP: f64 = 10.0; // radiator pipe lag, min
const TI: f64 = 30.0; // integral time, min
const QMAX: f64 = 3000.0; // radiator limit, W

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 } // a complex number, written out
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn div(self, o: C) -> C {
        let d = o.re * o.re + o.im * o.im;
        C { re: (self.re * o.re + self.im * o.im) / d, im: (self.im * o.re - self.re * o.im) / d }
    }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn r(x: f64) -> C { C { re: x, im: 0.0 } }

struct Run { ti: f64, t_end: f64, x: [f64; 3], out: f64, r0: f64, slope: f64, front: Option<(f64, f64)>, qmax: Option<f64> }
fn run(ti: f64, t_end: f64, th: f64, q: f64, i: f64, out: f64) -> Run {
    Run { ti, t_end, x: [th, q, i], out, r0: 20.0, slope: 0.0, front: None, qmax: None }
}
// RK4 on room temperature, radiator output, integral of error.  Returns final state and history.
fn sim(p: &Run) -> ([f64; 3], Vec<(f64, f64, f64)>) {
    let dt = 0.05;
    let f = |t: f64, x: [f64; 3]| -> [f64; 3] {
        let to = match p.front { Some((t0, v)) if t >= t0 => v, _ => p.out };
        let e = p.r0 + p.slope * t - x[0];
        let mut qc = KC * (e + if p.ti > 0.0 { x[2] / p.ti } else { 0.0 });
        if let Some(m) = p.qmax { qc = qc.max(0.0).min(m); }
        [(x[1] / U - (x[0] - to)) / TR, (qc - x[1]) / TP, if p.ti > 0.0 { e } else { 0.0 }]
    };
    let step = |x: [f64; 3], k: [f64; 3], h: f64| [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2]];
    let mut x = p.x;
    let mut hist = vec![(0.0, x[0], p.r0)];
    let n = (p.t_end / dt).round() as usize;
    for k in 0..n {
        let t = k as f64 * dt;
        let k1 = f(t, x);
        let k2 = f(t + dt / 2.0, step(x, k1, dt / 2.0));
        let k3 = f(t + dt / 2.0, step(x, k2, dt / 2.0));
        let k4 = f(t + dt, step(x, k3, dt));
        for j in 0..3 { x[j] += dt / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]); }
        let tn = (k + 1) as f64 * dt;
        hist.push((tn, x[0], p.r0 + p.slope * tn));
    }
    (x, hist)
}
// L(jw): thermostat (with or without integral) times radiator pipe times room.
fn lp(w: f64, ti: f64) -> C {
    let s = C { re: 0.0, im: w };
    let ctrl = if ti > 0.0 { r(KC).mul(r(1.0).add(r(1.0).div(r(ti).mul(s)))) } else { r(KC) };
    ctrl.div(r(U)).div(r(TR).mul(s).add(r(1.0)).mul(r(TP).mul(s).add(r(1.0))))
}
fn sens(w: f64, ti: f64) -> f64 { r(1.0).div(r(1.0).add(lp(w, ti))).abs() } // |S(jw)|
fn row(name: &str, v: f64, unit: &str) { println!("{:<44} {:>11.6} {}", name, v, unit); }

fn main() {
    // ---- road 1: the formula, from the loop's constants ----
    let a_step = 20.0 - 0.0; // setpoint 20 degC above a 0 degC outdoors
    let k0 = KC / U; // position constant L(0), type 0
    let kv = KC / U / TI; // velocity constant lim s L(s), type 1, per minute
    let a = 2.0 / 60.0; // ramp slope, degC per minute
    row("type 0 position constant K0 = L(0)", k0, "dimensionless");
    row("type 1 velocity constant Kv", kv, "1/min");
    row("formula  P  step error A/(1+K0)", a_step / (1.0 + k0), "degC");
    row("formula  PI ramp error a/Kv", a / kv, "degC");
    row("formula  PI ramp lag in time 1/Kv", 1.0 / kv, "min");
    // ---- road 2: heat balance at rest ----
    let e_bal = U * a_step / (U + KC);
    row("balance  P  step error", e_bal, "degC");
    row("balance  P  power held at rest", KC * e_bal, "W");
    row("balance  PI power held at rest", U * 20.0, "W");
    // ---- road 3: simulation ----
    let (x0, _) = sim(&run(0.0, 360.0, 20.0, 2000.0, 0.0, 0.0));
    row("sim      P  from 20 degC, error at 360 min", 20.0 - x0[0], "degC");
    let (xp, hp) = sim(&Run { front: Some((160.0, -3.0)), ..run(0.0, 480.0, 19.0, 1900.0, 0.0, 0.0) });
    let (xi, hi) = sim(&Run { front: Some((160.0, -3.0)), ..run(TI, 480.0, 19.0, 1900.0, 0.0, 0.0) });
    for k in (0..hp.len()).step_by(800) {
        println!("chart, t {:3.0} min, P {:5.2}, PI {:5.2}, setpoint {:5.2}", hp[k].0, hp[k].1, hi[k].1, hp[k].2);
    }
    row("sim      P  error at 480 min, after the front", 20.0 - xp[0], "degC");
    row("formula  P  error after the front 23/(1+K0)", 23.0 / (1.0 + k0), "degC");
    row("sim      PI error at 480 min", 20.0 - xi[0], "degC");
    let low = hi[3200..].iter().map(|h| h.1).fold(f64::INFINITY, f64::min);
    row("sim      PI lowest room after the front", low, "degC");
    row("sim      PI radiator power at 480 min", xi[1], "W");
    // ---- the s -> 0 limit, checked on the frequency response ----
    let w = 1e-5;
    row("freq     P  step error A*|S(jw)|", a_step * sens(w, 0.0), "degC");
    row("freq     PI step error A*|S(jw)|", a_step * sens(w, TI), "degC");
    row("freq     PI ramp error a*|S(jw)|/w", a * sens(w, TI) / w, "degC");
    // ---- ramp: night setback 14 degC rising to 22 degC at 2 degC/h ----
    let (xr, _) = sim(&Run { r0: 14.0, slope: a, ..run(TI, 240.0, 14.0, 1400.0, 1400.0 / KC * TI, 0.0) });
    let (xrp, _) = sim(&Run { r0: 14.0, slope: a, ..run(0.0, 240.0, 14.0 - 14.0 / 20.0, 1400.0 * 19.0 / 20.0, 0.0, 0.0) });
    row("sim      PI ramp error at 240 min", 22.0 - xr[0], "degC");
    row("sim      P  ramp error at 240 min", 22.0 - xrp[0], "degC");
    row("formula  P  error if 22 degC were held", 22.0 / (1.0 + k0), "degC");
    // ---- what breaks ----
    let ti_edge = k0 * TR * TP / ((1.0 + k0) * (TR + TP)); // cubic a2*a1 > a3*a0 (Routh) solved for Ti
    row("stability edge for Ti", ti_edge, "min");
    let worst = |ti: f64| -> Vec<f64> {
        let (_, h) = sim(&run(ti, 360.0, 19.0, 1900.0, 0.0, 0.0));
        [2400usize, 4800, 7200].iter().map(|&k| h[k - 2400..k].iter().map(|p| (20.0 - p.1).abs()).fold(0.0, f64::max)).collect()
    };
    let (pu, ps) = (worst(5.0), worst(15.0));
    for (j, k) in [120, 240, 360].iter().enumerate() {
        row(&format!("sim      worst error to {} min, Ti = 5 / 15 min", k), pu[j], &format!("/ {:.6} degC", ps[j]));
    }
    let (plo, phi) = (worst(0.9 * ti_edge), worst(1.1 * ti_edge));
    row("sim      worst error to 360 min, Ti = 0.9 / 1.1 edge", plo[2], &format!("/ {:.6} degC", phi[2]));
    let (xs, _) = sim(&Run { qmax: Some(QMAX), ..run(TI, 1500.0, 20.0, 2000.0, 2000.0 / KC * TI, -15.0) });
    row("sim      -15 degC, 3000 W cap, error at 1500 min", 20.0 - xs[0], "degC");
    row("balance  -15 degC, power needed at 20 degC", U * 35.0, "W");
    row("balance  -15 degC, 3000 W cap, error", 20.0 - (-15.0 + QMAX / U), "degC");
    row("sim      -15 degC, integral term asks for", KC * xs[2] / TI, "W");
    row("wrong: FVT on the unstable loop, Ti = 5 min", a_step * sens(w, 5.0), "degC");
    // ---- try changing ----
    row("try: P, draughty room U = 150 W/K", 150.0 * a_step / (150.0 + KC), "degC");
    row("try: P, thermostat gain 3900 W/K", U * a_step / (U + 3900.0), "degC");
    row("try: PI ramp error, Ti = 15 min", a * 15.0 / k0, "degC");

    assert!((e_bal - (20.0 - x0[0])).abs() < 1e-3); // heat balance vs simulation
    assert!((a_step / (1.0 + k0) - a_step * sens(w, 0.0)).abs() < 1e-4); // formula vs the s -> 0 limit of S
    assert!((20.0 - xp[0] - 23.0 / (1.0 + k0)).abs() < 1e-4); // cold front, P: formula vs simulation
    assert!((20.0 - xi[0]).abs() < 1e-4); // the integrator removes the offset
    assert!(((22.0 - xr[0]) - a / kv).abs() < 2e-4); // ramp lag: formula vs simulation
    assert!((a * sens(w, TI) / w - a / kv).abs() < 1e-4); // ramp: the s -> 0 limit vs formula
    assert!(pu[2] > 10.0 * pu[0] && ps[2] < ps[0] / 10.0); // simulated: Ti = 5 min grows, 15 min dies
    assert!(plo[2] > plo[0] && phi[2] < phi[0]); // Routh edge: just below it grows, just above it dies
    assert!(((20.0 - xs[0]) - (20.0 - (-15.0 + QMAX / U))).abs() < 1e-2); // saturated: heat balance vs simulation
    println!("all checks passed");
}
