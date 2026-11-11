// Magnetic fields and Faraday's law -- the check behind the card.  std only, no crates.
// A 1000-turn coil, 25 cm long, 5 cm across, carrying 3 A, switched off in 10 ms.
use std::f64::consts::PI;

const MU0: f64 = 1.25663706127e-6; // magnetic constant, N/A^2 (NIST CODATA 2022)
const QE: f64 = 1.602176634e-19; // electron charge, C (exact)
const ME: f64 = 9.1093837139e-31; // electron mass, kg (NIST CODATA 2022)
const N: f64 = 1000.0; // turns
const ELL: f64 = 0.25; // length, m
const R_IN: f64 = 0.025; // radius, m
const I0: f64 = 3.0; // current, A
const R_COIL: f64 = 4.0; // coil resistance, ohm
const V_SUP: f64 = 12.0; // supply, V
const V_D: f64 = 0.7; // diode drop, V
const DT: f64 = 0.010; // switch-off time, s

fn ideal_b(n: f64, ell: f64, i: f64) -> f64 { MU0 * n / ell * i } // Ampere's loop: B = mu0 n I
fn ideal_l(n: f64, ell: f64, r: f64) -> f64 { MU0 * n * n * PI * r * r / ell } // L = mu0 N^2 A / ell
fn loop_bz(r: f64, z: f64, i: f64) -> f64 { MU0 * i * r * r / (2.0 * (r * r + z * z).powf(1.5)) }

// Road 2 for B: Biot-Savart, every one of the N turns added one by one
fn coil_bz(z: f64) -> f64 {
    (0..N as usize).map(|i| loop_bz(R_IN, z - (-ELL / 2.0 + (i as f64 + 0.5) * ELL / N), I0)).sum()
}

// the same sum done as an integral, in closed form: mu0 n I (cos a1 + cos a2) / 2
fn sheet_bz(z: f64, ell: f64) -> f64 {
    let (a, b) = (ell / 2.0 - z, ell / 2.0 + z);
    MU0 * N / ell * I0 * (a / (a * a + R_IN * R_IN).sqrt() + b / (b * b + R_IN * R_IN).sqrt()) / 2.0
}

// complete elliptic integrals K(k), E(k) by the arithmetic-geometric mean
fn ke(k: f64) -> (f64, f64) {
    let (mut a, mut b, mut c, mut s, mut p) = (1.0, (1.0 - k * k).sqrt(), k, k * k / 2.0, 1.0);
    while c.abs() > 1e-15 {
        let (a2, b2, c2) = ((a + b) / 2.0, (a * b).sqrt(), (a - b) / 2.0);
        a = a2; b = b2; c = c2;
        p *= 2.0; s += p * c * c / 2.0;
    }
    (PI / (2.0 * a), PI / (2.0 * a) * (1.0 - s))
}

// finite-length factor for a current sheet: L = K_N * ideal L
fn nagaoka(ell: f64, r: f64) -> f64 {
    let d = (4.0 * r * r + ell * ell).sqrt();
    let (k, kp) = (2.0 * r / d, ell / d);
    let (kk, e) = ke(k);
    4.0 / (3.0 * PI * kp) * (kp * kp / (k * k) * (kk - e) + e - k)
}

// Maxwell: two coaxial turns of radius r, a distance u apart
fn mutual(u: f64, r: f64) -> f64 {
    let k = (4.0 * r * r / (4.0 * r * r + u * u)).sqrt();
    let (kk, e) = ke(k);
    MU0 * r * ((2.0 / k - k) * kk - 2.0 / k * e)
}

// Road 3 for L: add the flux every slice of winding sends through every other slice
fn l_by_pairs(n: f64, ell: f64, r: f64, m: usize) -> f64 {
    let mut tot = 0.0;
    for i in 0..m {
        let s = (i as f64 + 0.5) / m as f64;
        let u = ell * s * s;
        tot += (ell - u) * mutual(u, r) * 2.0 * ell * s / m as f64;
    }
    2.0 * tot * (n / ell).powi(2)
}

fn rk4<F: Fn(&[f64]) -> Vec<f64>>(f: F, y: &[f64], h: f64) -> Vec<f64> {
    let add = |a: &[f64], b: &[f64], c: f64| -> Vec<f64> { a.iter().zip(b).map(|(x, d)| x + c * d).collect() };
    let k1 = f(y);
    let k2 = f(&add(y, &k1, h / 2.0));
    let k3 = f(&add(y, &k2, h / 2.0));
    let k4 = f(&add(y, &k3, h));
    (0..y.len()).map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect()
}

fn main() {
    let a = PI * R_IN * R_IN;
    let b = ideal_b(N, ELL, I0);
    let l = ideal_l(N, ELL, R_IN);
    let loop_len = 0.075;
    let turns_in = N / ELL * loop_len; // Ampere rectangle 75 mm long
    let b_amp = MU0 * turns_in * I0 / loop_len;
    let (bc_sum, bc_sheet) = (coil_bz(0.0), sheet_bz(0.0, ELL));
    let (be_sum, be_sheet) = (coil_bz(ELL / 2.0), sheet_bz(ELL / 2.0, ELL));
    let phi = b * a;
    let link = N * phi;
    let kn = nagaoka(ELL, R_IN);
    let l_fin = kn * l;
    let l_pairs = l_by_pairs(N, ELL, R_IN, 4000);
    let emf = l * I0 / DT;
    let emf_far = N * a * (b - 0.0) / DT; // L dI/dt, and N dPhi/dt from the field
    let steps = 1000;
    let h = DT / steps as f64; // energy the 2.96 V delivers while I ramps 3 -> 0
    let w_out: f64 = (0..steps).map(|k| emf * I0 * (1.0 - (k as f64 + 0.5) / steps as f64) * h).sum();
    let w_l = 0.5 * l * I0 * I0;
    let w_field = b * b / (2.0 * MU0) * a * ELL;
    let tau = l / R_COIL;
    let t_off = tau * (1.0 + R_COIL * I0 / V_D).ln(); // diode route: L dI/dt = -(R I + V_D)
    let (mut y, mut t, hs) = (vec![I0], 0.0, 1e-6);
    loop {
        let y2 = rk4(|v| vec![-(R_COIL * v[0] + V_D) / l], &y, hs);
        if y2[0] <= 0.0 { t += hs * y[0] / (y[0] - y2[0]); break; }
        y = y2;
        t += hs;
    }
    let t_off_sim = t;
    let v_e = (2.0 * QE * 100.0 / ME).sqrt();
    let rad = ME * v_e / (QE * b);
    let per = 2.0 * PI * ME / (QE * b);
    let mut st = vec![0.0, 0.0, v_e, 0.0];
    let mut xmax: f64 = 0.0; // electron in the coil: F = q v x B, B along z
    for _ in 0..4000 {
        st = rk4(|s| vec![s[2], s[3], -QE / ME * s[3] * b, QE / ME * s[2] * b], &st, per / 4000.0);
        xmax = xmax.max((st[0] * st[0] + st[1] * st[1]).sqrt());
    }
    let rad_sim = xmax / 2.0;
    let (short_ideal, short_true) = (ideal_b(N, 0.05, I0), sheet_bz(0.0, 0.05));
    let lw = ideal_l(N, ELL, 2.0 * R_IN);
    let rows: Vec<(&str, f64)> = vec![
        ("turns per metre n, 1/m", N / ELL), ("cross-section A, cm^2", a * 1e4),
        ("1 B = mu0 n I, mT", b * 1e3), ("2 Ampere loop: turns inside", turns_in),
        ("  current inside, A", turns_in * I0), ("  B from the loop, mT", b_amp * 1e3),
        ("3 Biot-Savart centre, 1000 turns, mT", bc_sum * 1e3), ("  closed form, centre, mT", bc_sheet * 1e3),
        ("  centre / ideal", bc_sheet / b), ("  Biot-Savart at an end, mT", be_sum * 1e3), ("  end / ideal", be_sheet / b),
        ("flux per turn, uWb", phi * 1e6), ("flux linkage N Phi, mWb", link * 1e3),
        ("L ideal = mu0 N^2 A / ell, mH", l * 1e3), ("  N Phi / I, mH", link / I0 * 1e3),
        ("Nagaoka factor", kn), ("L finite, Nagaoka, mH", l_fin * 1e3), ("L finite, turn pairs, mH", l_pairs * 1e3),
        ("dI/dt during the ramp, A/s", I0 / DT), ("emf L I / dt, 10 ms, V", emf), ("  N A dB/dt, V", emf_far), ("  with finite L, V", l_fin * I0 / DT),
        ("  switch, end of ramp: V_sup + emf, V", V_SUP + emf), ("emf, off in 1 ms, V", l * I0 / 1e-3), ("emf, off in 10 us, V", l * I0 / 1e-5),
        ("coil volume, cm^3", a * ELL * 1e6), ("energy 1/2 L I^2, J", w_l), ("energy B^2/2mu0 x volume, J", w_field), ("energy emf x I summed, J", w_out),
        ("diode: tau = L/R, ms", tau * 1e3), ("  current gone, formula, ms", t_off * 1e3),
        ("  current gone, RK4, ms", t_off_sim * 1e3), ("  switch sees V_sup + V_D, V", V_SUP + V_D),
        ("electron 100 V: speed, km/s", v_e / 1e3), ("  circle radius m v/(q B), mm", rad * 1e3),
        ("  radius by RK4, mm", rad_sim * 1e3), ("  one lap, ns", per * 1e9),
        ("wrong: N for n, mT", ideal_b(N, 1.0, I0) * 1e3), ("wrong: N not N^2, uH", l / N * 1e6),
        ("  its emf, mV", l / N * I0 / DT * 1e3), ("wrong: diameter as radius, mH", lw * 1e3),
        ("  its emf, V", lw * I0 / DT),
        ("short 5 cm coil: mu0 n I, mT", short_ideal * 1e3), ("  true centre, mT", short_true * 1e3), ("  formula / true", short_ideal / short_true),
    ];
    for (name, v) in &rows {
        println!("{:<38} {:>14.6}", name, v);
    }
    let zmm: Vec<i32> = (0..17).map(|i| 25 * i - 200).collect();
    println!("chart, z mm      {}", zmm.iter().map(|z| format!("{:6}", z)).collect::<Vec<_>>().join(" "));
    println!("chart, B mT      {}", zmm.iter().map(|&z| format!("{:6.2}", coil_bz(z as f64 / 1000.0) * 1e3)).collect::<Vec<_>>().join(" "));
    let ts: Vec<f64> = (0..11).map(|i| 0.001 * i as f64).collect();
    println!("chart, t ms      {}", ts.iter().map(|t| format!("{:6.0}", t * 1e3)).collect::<Vec<_>>().join(" "));
    println!("chart, ramp A    {}", ts.iter().map(|t| format!("{:6.2}", I0 * (1.0 - t / DT))).collect::<Vec<_>>().join(" "));
    println!("chart, diode A   {}", ts.iter().map(|t| format!("{:6.2}", ((I0 + V_D / R_COIL) * (-t / tau).exp() - V_D / R_COIL).max(0.0))).collect::<Vec<_>>().join(" "));
    let px = |mm: f64| 60.0 + 1.6 * mm; // figure: 1.6 px per mm
    println!("figure, 1.6 px/mm, 25 marks of 40 turns, coil x {:.0}-{:.0}, wires y {:.0} and {:.0}, loop x {:.0}-{:.0} y 20-110",
        px(0.0), px(250.0), 110.0 - 1.6 * 25.0, 110.0 + 1.6 * 25.0, px(87.5), px(162.5));

    assert!((b_amp - b).abs() / b < 1e-12); // Ampere loop agrees with B = mu0 n I
    assert!((bc_sum - bc_sheet).abs() / bc_sheet < 1e-5); // 1000 turns one by one vs the integral
    assert!((be_sum - be_sheet).abs() / be_sheet < 1e-3);
    assert!(bc_sum / b > 0.97 && bc_sum / b < 0.99 && be_sum / b > 0.49 && be_sum / b < 0.51);
    assert!((link / I0 - l).abs() / l < 1e-12); // flux linkage / current = mu0 N^2 A / ell
    assert!((l_pairs - l_fin).abs() / l_fin < 1e-5); // turn-pair double integral vs Nagaoka
    assert!((emf_far - emf).abs() / emf < 1e-12); // N dPhi/dt = L dI/dt
    assert!((w_field - w_l).abs() / w_l < 1e-12 && (w_out - w_l).abs() / w_l < 1e-9); // three energies agree
    assert!((t_off_sim - t_off).abs() < 2e-6); // RK4 diode decay vs closed form
    assert!((rad_sim - rad).abs() / rad < 1e-4); // simulated electron circle vs m v / (q B)
    println!("ALL CHECKS PASS");
}
