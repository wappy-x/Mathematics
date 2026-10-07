// PID in practice: a room, a slow radiator pipe, and a valve that stops at fully open. Rust std only.
// Units: minutes, °C, kW; valve opening 0 (shut) to 1 (wide open). Simulations: RK4, 0.01 min step.
// Road 1: closed forms (pinned valve solved exactly, integral-area identity, lag formulas). Road 2: simulation
// of the same room, no formula inside it. Derivative noise: variance formula, Parseval, Monte Carlo.
const G: f64 = 0.2; const C: f64 = 6.0; const QM: f64 = 6.0; const TQ: f64 = 4.0; const TR: f64 = C / G;
const KP: f64 = 0.125; const KI: f64 = 0.125 / 15.0; const DT: f64 = 0.01;
const KPO: f64 = KP * QM; const KIO: f64 = KI * QM; const KIN: f64 = 8.0 / QM;
#[derive(Clone, Copy)] struct Opt { limit: bool, aw: bool, ff: f64, cascade: bool, fb: bool }
const BASE: Opt = Opt { limit: true, aw: false, ff: 0.0, cascade: false, fb: true };

/// Steady at room t0, outdoor tout0; at t = 0 outdoor becomes tout and the radiator loses d kW.
/// Returns room, radiator, outer integral, valve demand, one entry per step.
fn sim(r: f64, t0: f64, tout0: f64, tout: f64, d: f64, tend: f64, o: Opt) -> [Vec<f64>; 4] {
    let q0 = G * (t0 - tout0);
    let mut x = [t0, q0, if o.cascade { q0 - o.ff * q0 } else { (q0 - o.ff * q0) / QM }, q0 / QM];
    let sat = |v: f64, hi: f64| if o.limit { v.max(0.0).min(hi) } else { v };
    let f = |x: &[f64; 4]| -> ([f64; 4], f64) {
        let (t, q, xo, xi) = (x[0], x[1], x[2], x[3]);
        let e = if o.fb { r - t } else { 0.0 };
        let (u, v, dxo, dxi);
        if o.cascade {                                   // outer PI asks for heat; inner PI moves the valve
            let qv = o.ff * G * (r - tout) + KPO * e + xo; let qr = sat(qv, QM); let eq = qr - q;
            v = KIN * eq + xi; u = sat(v, 1.0);
            dxo = if o.aw && qv != qr && e * (qv - qr) > 0.0 { 0.0 } else { KIO * e };
            dxi = if o.aw && v != u && eq * (v - u) > 0.0 { 0.0 } else { KIN / TQ * eq };
        } else {
            v = o.ff * G * (r - tout) / QM + KP * e + xo; u = sat(v, 1.0);
            dxo = if o.aw && v != u && e * (v - u) > 0.0 { 0.0 } else { KI * e }; dxi = 0.0;
        }
        ([(q - G * (t - tout)) / C, (QM * u - d - q) / TQ, dxo, dxi], v)
    };
    let mut out = [vec![t0], vec![q0], vec![x[2]], vec![]];
    let add = |x: &[f64; 4], k: &[f64; 4], h: f64| [x[0] + h * k[0], x[1] + h * k[1], x[2] + h * k[2], x[3] + h * k[3]];
    for _ in 0..(tend / DT).round() as usize {
        let (k1, v) = f(&x);
        let k2 = f(&add(&x, &k1, DT / 2.0)).0;
        let k3 = f(&add(&x, &k2, DT / 2.0)).0;
        let k4 = f(&add(&x, &k3, DT)).0;
        for i in 0..4 { x[i] += DT / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i]); }
        out[0].push(x[0]); out[1].push(x[1]); out[2].push(x[2]); out[3].push(v);
    }
    out
}
fn bisect(f: impl Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..100 { let mid = (lo + hi) / 2.0; if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn cross(ys: &[f64], level: f64) -> f64 {              // first time ys falls through level, interpolated
    let i = (1..ys.len()).find(|&i| ys[i] <= level).unwrap();
    (i as f64 - 1.0 + (ys[i - 1] - level) / (ys[i - 1] - ys[i])) * DT
}
fn peak(ys: &[f64], sign: f64) -> (f64, f64) {
    let mut b = 0;
    for i in 1..ys.len() { if sign * ys[i] > sign * ys[b] { b = i } }
    (ys[b], b as f64 * DT)
}
fn row(lab: &str, ys: &[f64]) {
    let v: Vec<String> = (0..=9000).step_by(500).map(|i| format!("{:.2}", ys[i])).collect();
    println!("{:<24}{}", lab, v.join(" "));
}
fn trap(ys: &[f64], n: usize, r: f64) -> f64 { (0..n).fold(0.0, |s, i| s + (2.0 * r - ys[i] - ys[i + 1]) * DT / 2.0) } // area of the error
struct Mix(u64);
impl Mix {                                             // SplitMix64, mapped to (0, 1)
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
    fn gauss(&mut self) -> f64 {                       // Box-Muller
        let u1 = self.unif();
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * self.unif()).cos()
    }
}
fn main() {
    // ---- 1. cold morning: outdoor -5 °C, setpoint raised from 15 to 21 °C ----
    let (r, t0, to) = (21.0, 15.0, -5.0);
    let (q0, teq, x0, x1) = (G * (t0 - to), to + QM / G, G * (t0 - to) / QM, G * (r - to) / QM);
    let b = (QM - q0) / C * TQ * TR / (TR - TQ); let d = t0 - teq - b;   // open valve: teq + b e^(-t/TQ) + d e^(-t/TR)
    let t_open = |t: f64| teq + b * (-t / TQ).exp() + d * (-t / TR).exp();
    let area_open = |t: f64| (r - teq) * t - b * TQ * (1.0 - (-t / TQ).exp()) - d * TR * (1.0 - (-t / TR).exp());
    let xo_open = |t: f64| x0 + KI * area_open(t);
    let t_wind = bisect(|t| KP * (r - t_open(t)) + xo_open(t) - 1.0, 0.0, 200.0);
    let t_clamp = bisect(|t| KP * (r - t_open(t)) + x0 - 1.0, 0.0, 200.0);
    let t_c = bisect(|t| t_open(t) - r, 0.0, 200.0);
    let (lin, wnd, clp) = (sim(r, t0, to, to, 0.0, 300.0, Opt { limit: false, ..BASE }),
        sim(r, t0, to, to, 0.0, 300.0, BASE), sim(r, t0, to, to, 0.0, 300.0, Opt { aw: true, ..BASE }));
    println!("before: radiator {:.2} kW, valve {:.4}; after: needs {:.2} kW, valve {:.4}", q0, x0, G * (r - to), x1);
    println!("first valve demand {:.4}; wide open the room heads for {:.2} °C", KP * (r - t0) + x0, teq);
    println!("open-valve room: T = {:.2} + {:.4} e^(-t/{:.0}) {:+.4} e^(-t/{:.0})", teq, b, TQ, d, TR);
    let ar: Vec<f64> = [&lin, &wnd, &clp].iter().map(|run| trap(&run[0], run[0].len() - 1, r)).collect();
    let (sw, wmax) = (cross(&wnd[3], 1.0), wnd[2].iter().cloned().fold(f64::MIN, f64::max));
    println!("windup: valve pinned until {:.3} min (formula), {:.3} min (sim)", t_wind, sw);
    println!("windup: room crosses 21 at {:.3} min; integral peaks at {:.4} (formula), {:.4} (sim)", t_c, xo_open(t_c), wmax);
    println!("windup: area banked while pinned {:.1} °C·min (formula), {:.1} (sim)", area_open(t_wind),
             trap(&wnd[0], (t_wind / DT).round() as usize, r));
    println!("clamped: valve pinned until {:.3} min (formula), {:.3} min (sim), room {:.3} °C", t_clamp, cross(&clp[3], 1.0), r - (1.0 - x0) / KP);
    println!("area identity: change in valve / KI = ({:.4} - {:.4}) / {:.6} = {:.3} °C·min; left to repay after the valve frees {:.1} °C·min",
             x1, x0, KI, (x1 - x0) / KI, area_open(t_wind) - (x1 - x0) / KI);
    for (lab, run, a) in [("no valve limit", &lin, ar[0]), ("limit, no anti-windup", &wnd, ar[1]), ("limit, clamping", &clp, ar[2])] {
        let (pk, tp) = peak(&run[0], 1.0);
        let st = (0..run[0].len()).filter(|&i| (run[0][i] - r).abs() > 0.2).max().unwrap() as f64 * DT;
        println!("{:<22} peak {:.2} °C at {:5.1} min, within 0.2 °C after {:5.1} min, area {:6.3}", lab, pk, tp, st, a);
    }
    row("chart, no valve limit", &lin[0]); row("chart, no anti-windup", &wnd[0]); row("chart, clamping", &clp[0]);
    // ---- 2. cold front: outdoor 0 -> -6 °C with the room at 21 °C; feedforward from an outdoor sensor ----
    let dto: f64 = -6.0; let tstar = (TR / TQ).ln() * TR * TQ / (TR - TQ);
    let ffpk = dto * TQ / (TR - TQ) * ((-tstar / TR).exp() - (-tstar / TQ).exp());
    let cases = [("feedback only", 0.0, true), ("feedforward only", 1.0, false), ("both", 1.0, true),
                 ("ff 30% low, alone", 0.7, false), ("ff 30% low, with fb", 0.7, true)];
    let runs: Vec<[Vec<f64>; 4]> = cases.iter().map(|&(_, g, fb)| sim(r, r, 0.0, dto, 0.0, 300.0, Opt { ff: g, fb, ..BASE })).collect();
    println!("feedforward only, formula: dip {:.4} °C at {:.3} min; steady error if 30% low {:.2} °C", ffpk, tstar, 0.3 * dto);
    for (k, run) in cases.iter().zip(runs.iter()) {
        let (pk, tp) = peak(&run[0], -1.0);
        println!("cold front, {:<20} lowest {:.4} °C at {:6.2} min, at 300 min {:.4} °C", k.0, pk, tp, run[0][run[0].len() - 1]);
    }
    row("chart, feedback only", &runs[0][0]); row("chart, feedforward only", &runs[1][0]); row("chart, both", &runs[2][0]);
    // ---- 3. supply water cools: the radiator loses 1.2 kW at the same valve; one loop against a cascade ----
    let (dq, ts) = (1.2, TQ * 8f64.ln() / 7.0);
    let qpk = -dq / 7.0 * ((-ts / TQ).exp() - (-8.0 * ts / TQ).exp());
    let (qmin, tq_) = peak(&sim(r, r, 0.0, 0.0, dq, 30.0, Opt { cascade: true, fb: false, ..BASE })[1], -1.0);
    println!("inner loop time {:.2} min; inner loop alone: radiator dips {:.4} kW at {:.3} min (formula), {:.4} kW at {:.3} (sim)",
             TQ / (KIN * QM), qpk, ts, qmin - G * r, tq_);
    for (lab, cas) in [("single loop", false), ("cascade", true)] {
        let run = sim(r, r, 0.0, 0.0, dq, 300.0, Opt { cascade: cas, aw: true, ..BASE });
        let (pk, tp) = peak(&run[0], -1.0);
        let qlo = run[1].iter().cloned().fold(f64::MAX, f64::min);
        println!("supply drop, {:<12} room lowest {:.4} °C at {:6.2} min, radiator lowest {:.4} kW", lab, pk, tp, qlo);
    }
    // ---- 4. derivative on a noisy thermometer: KD = KP x 2 min, sensor noise 0.05 °C rms, seed 2026 ----
    let (kd, sig, mut rng, mut noise, mut pms) = (KP * 2.0, 0.05, Mix(2026), vec![], vec![]);
    for h in [0.1, 0.01] {
        for tf in [0.0, 0.2] {
            let (a, bb, n) = (tf / (tf + h), kd / (tf + h), 2000usize);
            let formula = bb * sig * (2.0 / (1.0 + a)).sqrt();
            let hp = |th: f64| bb * bb * (2.0 - 2.0 * th.cos()) / (1.0 - 2.0 * a * th.cos() + a * a);
            let s = (0..=n).fold(0.0, |s, j| s + (if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 })
                                 * hp(j as f64 * std::f64::consts::PI / n as f64));
            let par = sig * (s * (std::f64::consts::PI / n as f64) / 3.0 / std::f64::consts::PI).sqrt();
            let (mut prev, mut dv, mut acc) = (rng.gauss() * sig, 0.0, 0.0);
            for k in 0..100100 {
                let y = rng.gauss() * sig;
                dv = a * dv + bb * (y - prev); prev = y;
                acc += if k >= 100 { dv * dv } else { 0.0 };
            }
            let mc = (acc / 100000.0).sqrt(); noise.push((formula, par, mc));
            println!("derivative, h {:.2} min, filter {:.1} min, a {:.4}, b {:.4}: jitter {:.4} formula, {:.4} Parseval, {:.4} Monte Carlo",
                     h, tf, a, bb, formula, par, mc);
        }
    }
    println!("radiator law (Tw - T)^1.3, water 60 °C: output at 25 °C room / at 15 °C room = {:.4}", (35.0f64 / 45.0).powf(1.3));
    let lm = |w: f64, kd: f64, tf: f64| { let (cr, ci) = (KP + kd * tf * w * w / (1.0 + tf * tf * w * w), kd * w / (1.0 + tf * tf * w * w) - KI / w); // C(jw); |L|, arg L
        ((cr * cr + ci * ci).sqrt() * QM / G / ((1.0 + TQ * TQ * w * w) * (1.0 + TR * TR * w * w)).sqrt(), ci.atan2(cr) - (TQ * w).atan() - (TR * w).atan()) };
    for (lab, kdx, tf) in [("PI", 0.0, 0.0), ("PID, raw derivative", kd, 0.0), ("PID, D filtered 0.2 min", kd, 0.2)] {
        let wc = bisect(|w| lm(w, kdx, tf).0 - 1.0, 0.01, 1.0); pms.push(180.0 + lm(wc, kdx, tf).1.to_degrees());
        println!("margins, {:<23} crossover {:.4} rad/min, phase margin {:.2} deg", lab, wc, pms[pms.len() - 1]);
    }

    assert!((t_wind - sw).abs() < 0.01, "pinned-valve time: exact solution against simulation");
    assert!((ar[1] - (x1 - x0) / KI).abs() < 0.01, "windup run must pay back exactly the identity's area");
    assert!((xo_open(t_c) - wmax).abs() < 1e-4, "integral peak: exact solution against simulation");
    assert!((t_clamp - cross(&clp[3], 1.0)).abs() < 0.01, "clamped release time: exact solution against simulation");
    assert!((ffpk - peak(&runs[1][0], -1.0).0 + r).abs() < 1e-4, "feedforward dip: formula against sim");
    assert!((runs[3][0][runs[3][0].len() - 1] - r - 0.3 * dto).abs() < 1e-3, "30% low feedforward: steady error against sim");
    assert!((qpk - (qmin - G * r)).abs() < 1e-4, "inner-loop dip: formula against sim");
    assert!(noise.iter().all(|&(f, p, _)| (p - f).abs() < 1e-6), "Parseval integral against the variance formula");
    assert!(noise.iter().all(|&(f, _, m)| (m - f).abs() < 0.03 * f), "Monte Carlo within 3% (a few standard errors)");
    assert!((pms[2] - pms[1]).abs() < 1.0, "a 0.2 min derivative filter moves the phase margin by under 1 deg");
    println!("ALL CHECKS PASS");
}
