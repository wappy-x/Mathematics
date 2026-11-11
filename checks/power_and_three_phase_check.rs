// AC power and three phases -- the check behind the card.  std only, no crates.
// A 5 kW motor at power factor 0.8 on 230 V, 50 Hz.  Every number on the card is
// printed here.  Road 1: the formulas.  Road 2: sample v(t) and i(t) over one cycle
// and average.  Road 3: simulate the motor as a resistor and inductor (RK4) and
// measure the power it draws.  Then three phases, sampled instant by instant.
use std::f64::consts::PI;

const V: f64 = 230.0; // rms volts
const F: f64 = 50.0; // hertz
const P: f64 = 5000.0; // watts
const PF: f64 = 0.8; // cos(phi)

fn main() {
    let w = 2.0 * PI * F; // angular frequency, radians per second
    let t_cyc = 1.0 / F; // one cycle, seconds
    let phi = PF.acos(); // current lags the voltage by phi
    let r2 = 2f64.sqrt();

    // ---- road 1: the formulas ----
    let s = P / PF;
    let q = s * phi.sin();
    let i_rms = s / V;
    let r = P / i_rms.powi(2); // the motor seen as resistance and reactance
    let x = q / i_rms.powi(2);
    let l = x / w;

    let v = |t: f64, shift: f64| r2 * V * (w * t - shift).cos();
    let i = |t: f64| r2 * i_rms * (w * t - phi).cos();

    // ---- road 2: sample one cycle and average ----
    let n = 40000usize;
    let ts: Vec<f64> = (0..n).map(|k| k as f64 * t_cyc / n as f64).collect();
    let nf = n as f64;
    let p_avg = ts.iter().map(|&t| v(t, 0.0) * i(t)).sum::<f64>() / nf;
    let rms = |g: &dyn Fn(f64) -> f64| (ts.iter().map(|&t| g(t).powi(2)).sum::<f64>() / nf).sqrt();
    let s_rms = rms(&|t| v(t, 0.0)) * rms(&|t| i(t));
    let q_avg = ts.iter().map(|&t| v(t - t_cyc / 4.0, 0.0) * i(t)).sum::<f64>() / nf; // voltage a quarter cycle late
    let p_one: Vec<f64> = ts.iter().map(|&t| v(t, 0.0) * i(t)).collect();

    // ---- road 3: L di/dt = v - R i, from rest, ten cycles by RK4 ----
    let didt = |t: f64, c: f64| (v(t, 0.0) - r * c) / l;
    let h = t_cyc / 2000.0;
    let (mut cur, mut t, mut p_sim, mut v2_sim, mut i2_sim) = (0.0f64, 0.0f64, 0.0f64, 0.0f64, 0.0f64);
    for k in 0..10 * 2000 {
        if k >= 9 * 2000 {
            p_sim += v(t, 0.0) * cur / 2000.0; // average over the last cycle
            v2_sim += v(t, 0.0).powi(2) / 2000.0;
            i2_sim += cur.powi(2) / 2000.0;
        }
        if l == 0.0 { cur = v(t + h, 0.0) / r; t += h; continue; } // pf 1: no inductance, current follows v / R
        let k1 = didt(t, cur);
        let k2 = didt(t + h / 2.0, cur + h * k1 / 2.0);
        let k3 = didt(t + h / 2.0, cur + h * k2 / 2.0);
        let k4 = didt(t + h, cur + h * k3);
        cur += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
        t += h;
    }
    let pf_sim = p_sim / (v2_sim.sqrt() * i2_sim.sqrt()); // power factor, measured back

    // ---- three phases: 230 V to neutral, 120 degrees apart, a third of the load each ----
    let sh = [0.0, 2.0 * PI / 3.0, 4.0 * PI / 3.0];
    let i3n = (P / 3.0) / PF / V;
    let i3 = |t: f64, k: usize, size: f64| r2 * size * (w * t - phi - sh[k]).cos();
    let vl = 3f64.sqrt() * V;
    let vl_s = rms(&|t| v(t, 0.0) - v(t, sh[1]));
    let p3_formula = 3f64.sqrt() * vl * i3n * PF;
    let cs: f64 = sh.iter().map(|&a| (phi + a).cos()).sum();
    let sn: f64 = sh.iter().map(|&a| (phi + a).sin()).sum();
    let in_ph = (cs * cs + sn * sn).sqrt() * i3n;
    let in_s = ts.iter().map(|&t| (0..3).map(|k| i3(t, k, i3n)).sum::<f64>().abs()).fold(0.0, f64::max);
    let p3: Vec<f64> = ts.iter().map(|&t| (0..3).map(|k| v(t, sh[k]) * i3(t, k, i3n)).sum()).collect();
    let loss1 = 2.0 * i_rms.powi(2) * 0.1; // 0.1 ohm in every wire
    let loss3 = 3.0 * i3n.powi(2) * 0.1;
    let in_off = rms(&|t| i3(t, 0, i3n) + i3(t, 1, i3n)); // phase c switched off
    let in_half = rms(&|t| i3(t, 0, i3n) + i3(t, 1, i3n) + i3(t, 2, i3n / 2.0));
    let in_h3 = rms(&|t| sh.iter().map(|&a| r2 * 3.0 * (3.0 * (w * t - a)).cos()).sum());

    let mn = |xs: &[f64]| xs.iter().cloned().fold(f64::INFINITY, f64::min);
    let mx = |xs: &[f64]| xs.iter().cloned().fold(f64::NEG_INFINITY, f64::max);
    let rows: Vec<(&str, f64)> = vec![
        ("phase angle phi, degrees", phi.to_degrees()), ("sin phi", phi.sin()),
        ("omega, rad/s", w), ("peak V, V", r2 * V), ("peak I, A", r2 * i_rms),
        ("1 formula   S = P / pf, VA", s), ("1 formula   Q = S sin phi, var", q),
        ("1 formula   I = S / V, A", i_rms), ("  I sin phi, quarter-cycle part, A", i_rms * phi.sin()),
        ("2 samples   P = mean of v i, W", p_avg), ("2 samples   S = rms v x rms i, VA", s_rms),
        ("2 samples   Q = mean of v(t-T/4) i, var", q_avg),
        ("3 circuit   P drawn by R and L, W", p_sim),
        ("3 circuit   pf = P / (rms v x rms i)", pf_sim),
        ("  R, ohm", r), ("  X, ohm", x), ("  L, mH", l * 1000.0),
        ("  p(t) lowest sample, W", mn(&p_one)), ("  p(t) highest sample, W", mx(&p_one)),
        ("current at pf 1, A", P / V), ("wire loss ratio pf 0.8 : pf 1", (i_rms / (P / V)).powi(2)),
        ("three-phase current per line, A", i3n), ("line voltage sqrt3 V, V", vl),
        ("line voltage, sampled, V", vl_s), ("P = sqrt3 V_L I_L pf, W", p3_formula),
        ("neutral, phasor sum, A", in_ph), ("neutral, largest sample, A", in_s),
        ("three-phase p(t) lowest, W", mn(&p3)), ("three-phase p(t) highest, W", mx(&p3)),
        ("wire loss single-phase, W", loss1), ("wire loss three-phase, W", loss3),
        ("unbalanced: phase c off, neutral, A", in_off),
        ("unbalanced: phase c half, neutral, A", in_half),
        ("third harmonic 3 A each, neutral, A", in_h3),
        ("wrong: P = V I, W", V * i_rms), ("wrong: S = P + Q, VA", P + q),
        ("wrong: I = P / (3 V_L pf), A", P / (3.0 * vl * PF)),
        ("wrong: neutral = sum of sizes, A", 3.0 * i3n),
        ("wrong: peak V x peak I x pf, W", 2.0 * V * i_rms * PF),
        ("try: pf 0.5, current, A", P / 0.5 / V), ("try: pf 0.5, S, VA", P / 0.5), ("try: pf 1, Q, var", P / 1.0 * 1.0f64.acos().sin()),
        ("try: 60 Hz, L, mH", x / (2.0 * PI * 60.0) * 1000.0),
    ];
    for (label, val) in &rows {
        println!("{:<40}{:12.4}", label, val);
    }
    let ms: Vec<usize> = (0..21).map(|k| k * n / 20).collect(); // 0, 1, ..., 20 ms
    let line = |xs: &[f64]| ms.iter().map(|&k| format!("{}", xs[k % n].round() as i64)).collect::<Vec<_>>().join(" ");
    println!("chart, single-phase p(t), W {}", line(&p_one));
    println!("chart, three-phase p(t), W  {}", line(&p3));

    assert!((p_avg - P).abs() < 1e-6 && (s_rms - s).abs() < 1e-6, "sampled averages vs formulas");
    assert!((q_avg - q).abs() < 1e-6, "quarter-cycle average vs S sin phi");
    assert!((p_sim - P).abs() < 0.01, "simulated motor draws 5 kW");
    assert!((pf_sim - PF).abs() < 1e-5, "simulated motor's power factor is 0.8");
    assert!((vl_s - vl).abs() < 1e-6, "sampled line voltage vs sqrt3 V");
    assert!(in_ph < 1e-9 && in_s < 1e-9, "balanced neutral carries nothing");
    assert!(mx(&p3) - mn(&p3) < 1e-6 && (p3[0] - P).abs() < 1e-6, "three-phase power is flat at P");
    assert!((mn(&p_one) - (P - s)).abs() < 1e-3, "single-phase dips to P - S");
    assert!((loss1 / loss3 - 6.0).abs() < 1e-9, "three wires: a sixth of the loss");
    println!("ALL CHECKS PASS");
}
