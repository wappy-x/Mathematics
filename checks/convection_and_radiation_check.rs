// Convection and radiation from one radiator panel -- the check behind the card.
// Rust std only, no crates. Prints exactly what the Python check prints.
use std::f64::consts::PI;

const SIGMA: f64 = 5.670374419e-8;         // Stefan-Boltzmann constant, W/(m^2 K^4), NIST CODATA
const HP: f64 = 6.62607015e-34;            // Planck constant, exact SI
const C: f64 = 299792458.0;                // speed of light, exact SI
const KB: f64 = 1.380649e-23;              // Boltzmann constant, exact SI
const G: f64 = 9.80665;                    // standard gravity, m/s^2
const K0: f64 = 273.15;                    // 0 degC in kelvin
// dry air at 1 atm, Incropera Table A.4: T K, nu m^2/s, k W/(m K), alpha m^2/s
const AIR: [[f64; 4]; 2] = [[300.0, 15.89e-6, 26.3e-3, 22.5e-6], [350.0, 20.92e-6, 30.0e-3, 29.9e-6]];
const TA: f64 = 20.0;                      // room air, degC
const TW: f64 = 20.0;                      // room walls, degC
const TS: f64 = 60.0;                      // radiator surface, degC
const EPS: f64 = 0.90;                     // emissivity of white paint, Incropera
const L: f64 = 0.60;                       // panel height, m
const W: f64 = 1.00;                       // panel length, m
const A: f64 = 2.0 * L * W;                // both faces, m^2
const WALL_DT: f64 = 0.691;                // room wall face below the air on Fourier's law, K
const WALL_H: f64 = 2.5;                   // wall height, m

fn air(t: f64) -> [f64; 3] {               // straight line between the two table rows
    let f = (t - AIR[0][0]) / (AIR[1][0] - AIR[0][0]);
    let mut out = [0.0; 3];
    for i in 0..3 { out[i] = AIR[0][i + 1] + f * (AIR[1][i + 1] - AIR[0][i + 1]); }
    out
}

// natural convection, vertical plate (Churchill-Chu): h, Ra, Pr, Nu, k_air
fn conv(ts: f64, ta: f64, l: f64) -> (f64, f64, f64, f64, f64) {
    let tf = (ts + ta) / 2.0 + K0;         // film temperature, K
    let [nu, k, al] = air(tf);
    let ra = G * (ts - ta) * l.powf(3.0) / (tf * nu * al);
    let pr = nu / al;
    let nusselt = (0.825 + 0.387 * ra.powf(1.0 / 6.0)
        / (1.0 + (0.492 / pr).powf(9.0 / 16.0)).powf(8.0 / 27.0)).powf(2.0);
    (nusselt * k / l, ra, pr, nusselt, k)
}

fn rad(ts: f64, tw: f64, eps: f64) -> f64 { // net radiation per m^2, small body in a big room
    eps * SIGMA * ((ts + K0).powf(4.0) - (tw + K0).powf(4.0))
}

fn planck(lam: f64, t: f64) -> f64 {       // black-body power per m^2 per metre of wavelength
    2.0 * PI * HP * C * C / lam.powf(5.0) / ((HP * C / (lam * KB * t)).exp() - 1.0)
}

fn rad_spectrum(ts: f64, tw: f64, eps: f64, n: usize) -> f64 { // road 2: add up the spectrum
    let (a, b) = ((1e-7f64).ln(), (1e-2f64).ln());
    let h = (b - a) / n as f64;
    let mut tot = 0.0;
    for i in 0..=n {
        let lam = (a + i as f64 * h).exp();
        let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        tot += w * (planck(lam, ts + K0) - planck(lam, tw + K0)) * lam;
    }
    eps * tot * h / 3.0
}

fn total(ts: f64, eps: f64, height: f64, area: f64) -> f64 { // watts: convection plus radiation
    area * (conv(ts, TA, height).0 * (ts - TA) + rad(ts, TW, eps))
}

fn solve(q: f64) -> f64 {                  // road 3: surface temperature that sheds q watts
    let (mut lo, mut hi) = (TA + 1e-9, 150.0);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if total(mid, EPS, L, A) < q { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn main() {
    let (h, ra, pr, nusselt, kair) = conv(TS, TA, L);
    let [nu_f, _, al_f] = air((TS + TA) / 2.0 + K0);
    let g_pr = 0.75 * pr.powf(0.5) / (0.609 + 1.221 * pr.powf(0.5) + 1.238 * pr).powf(0.25);
    let nu_th = 4.0 / 3.0 * (ra / pr / 4.0).powf(0.25) * g_pr; // smooth-flow similarity solution
    let nu_lam = 0.68 + 0.670 * ra.powf(0.25) / (1.0 + (0.492 / pr).powf(9.0 / 16.0)).powf(4.0 / 9.0); // Ra < 1e9 only
    let h_lam = nu_lam * kair / L;
    let (qc, qr) = (h * (TS - TA), rad(TS, TW, EPS));
    let qr2 = rad_spectrum(TS, TW, EPS, 4000);
    let (ts_k, tw_k) = (TS + K0, TW + K0);
    let hr = EPS * SIGMA * (ts_k + tw_k) * (ts_k.powf(2.0) + tw_k.powf(2.0));
    let q60 = total(TS, EPS, L, A);
    let mut best = (f64::MIN, 0.0);
    for l in 100..=3000 {
        let v = planck(l as f64 * 1e-8, ts_k);
        if v > best.0 { best = (v, l as f64 / 100.0); }
    }
    let peak = best.1;
    let steel = (qc + qr) * 0.00125 / 60.5; // drop across 1.25 mm of steel, k = 60.5 W/(m K)
    let q45 = total(45.0, EPS, L, A);
    let n_exp = (q60 / q45).ln() / (40.0f64 / 25.0).ln();
    let cel = A * (qc + EPS * SIGMA * (TS.powf(4.0) - TW.powf(4.0)));
    let lin = A * (qc + 4.0 * EPS * SIGMA * tw_k.powf(3.0) * (TS - TW));
    let (stove, stove_lin) = (rad(300.0, TW, EPS), 4.0 * EPS * SIGMA * tw_k.powf(3.0) * (300.0 - TW));
    let h_wall = conv(TA + WALL_DT, TA, WALL_H).0; // a face colder than the air drives the same flow, downward
    let tf_k = TA - WALL_DT + K0;
    let hr_wall = EPS * SIGMA * (tf_k + tw_k) * (tf_k.powf(2.0) + tw_k.powf(2.0));

    let rows: Vec<(&str, f64)> = vec![
        ("film temperature, K", (ts_k + tw_k) / 2.0), ("air viscosity nu, mm^2/s", 1e6 * nu_f),
        ("air diffusivity alpha, mm^2/s", 1e6 * al_f), ("Rayleigh number Ra, millions", ra / 1e6),
        ("Prandtl number Pr", pr), ("air conductivity k, W/(m K)", kair), ("Nusselt number Nu", nusselt),
        ("convection coefficient h, W/(m^2 K)", h), ("  still-air film k/h, mm", 1000.0 * kair / h),
        ("smooth-flow theory: Nu", nu_th), ("  its h, W/(m^2 K)", nu_th * kair / L),
        ("Churchill-Chu laminar form: Nu", nu_lam), ("  its h, W/(m^2 K)", h_lam),
        ("  its total, W", A * (h_lam * (TS - TA) + qr)),
        ("  its radiation share, %", 100.0 * qr / (h_lam * (TS - TA) + qr)),
        ("radiation coefficient h_r, W/(m^2 K)", hr),
        ("  straightened at mean temp, W/(m^2 K)", 4.0 * EPS * SIGMA * (ts_k / 2.0 + tw_k / 2.0).powf(3.0)),
        ("convection, W/m^2", qc), ("1 radiation by formula, W/m^2", qr),
        ("2 radiation by spectrum, W/m^2", qr2), ("  h_r x 40 K, W/m^2", hr * 40.0),
        ("film resistance 1/(h + h_r), m^2 K/W", 1.0 / (h + hr)),
        ("spectrum peak at 60 C, um", peak), ("panel area, m^2", A),
        ("convection, W", A * qc), ("radiation, W", A * qr), ("TOTAL, W", q60),
        ("radiation share, %", 100.0 * qr / (qc + qr)), ("drop across the steel, K", steel),
        ("3 surface temp that sheds TOTAL, C", solve(q60)), ("surface temp for 400 W, C", solve(400.0)),
        ("at 45 C surface, W", q45), ("  scaled by 25/40 instead, W", q60 * 25.0 / 40.0),
        ("  output exponent n, Q ~ dT^n", n_exp), ("  panel length for TOTAL at 45 C, m", W * q60 / q45),
        ("wrong: Celsius in the 4th power, W", cel), ("  its radiation part, W", cel - A * qc),
        ("wrong: radiation left out, W", A * qc),
        ("wrong: radiation linear at room temp, W", lin), ("  its radiation part, W/m^2", lin / A - qc),
        ("stove at 300 C: radiation, W/m^2", stove), ("  linear at room temp, W/m^2", stove_lin),
        ("try: eps = 0.30, W", total(TS, 0.30, L, A)),
        ("try: 0.30 m tall, same length, W", total(TS, EPS, 0.30, 0.60)),
        ("try: 0.30 m tall: h, W/(m^2 K)", conv(TS, TA, 0.30).0),
        ("  1/4-power law at 0.30 m: h, W/(m^2 K)", h * 2f64.powf(0.25)),
        ("wall face, 0.691 K below air: h, W/(m^2 K)", h_wall), ("  its h_r, W/(m^2 K)", hr_wall),
        ("  its film 1/(h + h_r), m^2 K/W", 1.0 / (h_wall + hr_wall)),
    ];
    for (name, v) in &rows { println!("{:<42} {:>12.4}", name, v); }
    let chart: Vec<(f64, f64)> = (30..85).step_by(5).map(|ts| { let t = ts as f64;
        (A * conv(t, TA, L).0 * (t - TA), A * rad(t, TW, EPS)) }).collect();
    println!("chart, surface C  {}", (30..85).step_by(5).map(|ts| format!("{:5}", ts)).collect::<String>());
    for (name, j) in [("convection W", 0), ("radiation W", 1), ("total W", 2)] {
        println!("chart, {:<12}{}", name, chart.iter().map(|c| format!("{:5.0}",
            if j == 2 { c.0 + c.1 } else if j == 0 { c.0 } else { c.1 })).collect::<String>());
    }

    assert!((qr2 / qr - 1.0).abs() < 1e-4);       // spectrum sum agrees with sigma T^4
    assert!((solve(q60) - TS).abs() < 1e-6);      // balance turned round returns the 60 C surface
    assert!((peak - 2897.771955e-6 / ts_k * 1e6).abs() < 0.01); // Wien's constant, NIST
    assert!((h / (nu_th * kair / L) - 1.0).abs() < 0.35); // fitted h within 35% of smooth-flow theory
    assert!((pr - 0.705).abs() < 0.005);          // Table A.4's own Prandtl column: 0.707 at 300 K, 0.700 at 350 K
    assert!((nu_lam / nu_th - 1.0).abs() < 0.02); // laminar fit to measurements against smooth-flow theory
    assert!(q45 < q60 * 25.0 / 40.0);             // output falls faster than the difference
    println!("ALL CHECKS PASS");
}
