// Maxwell's equations -- the same check as maxwells_equations_check.py, in Rust.  std only, no crates.
// Two round plates, radius 5 cm, 1 mm apart in air, charged by a steady 10 mA.
// Road 1: the field from Maxwell's term, in closed form.  Road 2: Biot-Savart summed over the
// conduction currents alone (the wires and the plates), with no displacement current anywhere.
// Plus div(curl F) = 0 by differences, and the rim field at 1 GHz by a series and by an integral.
// Compile: rustc --edition 2021 -O maxwells_equations_check.rs -o /tmp/maxwells_equations_check
use std::f64::consts::PI;

const EPS0: f64 = 8.8541878188e-12; // F/m, CODATA 2022
const MU0: f64 = 1.25663706127e-6; // N/A^2, CODATA 2022
const C_EXACT: f64 = 299792458.0; // m/s, exact: it defines the metre
const A: f64 = 0.05; // plate radius, m
const D: f64 = 0.001; // gap, m
const I: f64 = 0.010; // charging current, A
const I_COND_GAP: f64 = 0.0; // A: conduction current crossing the bag surface in the gap

fn show(label: &str, value: f64, unit: &str, places: usize) {
    let line = format!("{:<42}{:>12.*} {}", label, places, value, unit);
    println!("{}", line.trim_end());
}

// field round the axis in the gap: the enclosed share of the current
fn b_maxwell(r: f64, a: f64, i: f64) -> f64 {
    MU0 * i * r.min(a).powi(2) / (a * a) / (2.0 * PI * r)
}

// Ampere's law without Maxwell's term, bag surface through the gap
fn b_old_ampere(r: f64) -> f64 {
    MU0 * I_COND_GAP / (2.0 * PI * r)
}

// road 2: wires plus the plates' spreading currents, nothing else
fn b_biot_savart(r: f64, gap: f64) -> f64 {
    let h = gap / 2.0;
    let wires = 2.0 * MU0 * I / (4.0 * PI * r) * (1.0 - h / (r * r + h * h).sqrt());
    let (u0, u1, v0) = ((-r / h).asinh(), ((A - r) / h).asinh(), (PI * r / h).asinh());
    let (nu, nv) = (400, 300);
    let (du, dv) = ((u1 - u0) / nu as f64, 2.0 * v0 / nv as f64);
    let mut tot = 0.0;
    for i in 0..nu {
        // grid packed close to the point, s = r + h sinh(u)
        let u = u0 + (i as f64 + 0.5) * du;
        let (s, ds) = (r + h * u.sinh(), h * u.cosh() * du);
        let ks = I * (1.0 - s * s / (A * A)) / (2.0 * PI); // sheet current K(s) times s
        for j in 0..nv {
            let v = -v0 + (j as f64 + 0.5) * dv;
            let (ph, dph) = (h / r * v.sinh(), h / r * v.cosh() * dv);
            let r2 = r * r + s * s - 2.0 * r * s * ph.cos() + h * h;
            tot += ks * h * ph.cos() / r2.powf(1.5) * ds * dph;
        }
    }
    wires - 2.0 * MU0 / (4.0 * PI) * tot // the two plates pull the same way, against the wires
}

fn j0_series(x: f64) -> f64 {
    let (mut term, mut total, mut k) = (1.0f64, 1.0f64, 0.0f64);
    while term.abs() > 1e-17 {
        k += 1.0;
        term *= -(x / 2.0).powi(2) / (k * k);
        total += term;
    }
    total
}

// (1/pi) times the integral of cos(x sin t) for t from 0 to pi
fn j0_integral(x: f64, n: usize) -> f64 {
    (0..n).map(|k| (x * ((k as f64 + 0.5) * PI / n as f64).sin()).cos()).sum::<f64>() / n as f64
}

fn field(p: [f64; 3]) -> [f64; 3] {
    let [x, y, z] = p;
    [(y * z).sin(), x * x * z, x.exp() * y]
}

fn curl(p: [f64; 3]) -> [f64; 3] {
    let e = 1e-4;
    let dd = |k: usize, axis: usize| {
        let (mut q, mut m) = (p, p);
        q[axis] += e;
        m[axis] -= e;
        (field(q)[k] - field(m)[k]) / (2.0 * e)
    };
    [dd(2, 1) - dd(1, 2), dd(0, 2) - dd(2, 0), dd(1, 0) - dd(0, 1)]
}

fn main() {
    println!("constants: eps0 8.8541878188 pF/m, mu0 1.25663706127 uN/A^2 (CODATA 2022)");
    let c = 1.0 / (MU0 * EPS0).sqrt();
    show("c = 1/sqrt(mu0 eps0)", c, "m/s", 1);
    assert!((c - C_EXACT).abs() / C_EXACT < 1e-9);
    let area = PI * A * A;
    show("plate area pi a^2", area * 1e4, "cm^2", 2);
    show("capacitance eps0 pi a^2 / d", EPS0 * area / D * 1e12, "pF", 2);
    let q1 = I * 1e-6;
    let e1 = q1 / (EPS0 * area);
    show("plate charge after 1 us", q1 * 1e9, "nC", 2);
    show("E in the gap after 1 us (Gauss)", e1 / 1e3, "kV/m", 1);
    show("voltage after 1 us", e1 * D, "V", 1);
    let dedt = I / (EPS0 * area);
    show("dE/dt in the gap", dedt / 1e3 * 1e-6, "kV/m per us", 1);
    show("dPhi_E/dt through the gap", dedt * area * 1e-6, "V m per us", 1);
    let i_d = EPS0 * dedt * area;
    show("displacement current eps0 dPhi_E/dt", i_d * 1e3, "mA", 3);
    show("displacement current density", i_d / area, "A/m^2", 3);
    show("road 1: B at 8 cm, flat surface (wire)", MU0 * I / (2.0 * PI * 0.08) * 1e9, "nT", 2);
    show("road 1: B at 8 cm, surface through gap", b_maxwell(0.08, A, I) * 1e9, "nT", 2);
    show("displacement current inside r = 2.5 cm", i_d * (0.025 / A).powi(2) * 1e3, "mA", 3);
    show("road 1: B at 2.5 cm, in the gap", b_maxwell(0.025, A, I) * 1e9, "nT", 2);
    let bs: Vec<f64> = [0.025, 0.05, 0.08].iter().map(|&r| b_biot_savart(r, D)).collect();
    for (k, r) in [0.025f64, 0.05, 0.08].iter().enumerate() {
        show(&format!("road 2: Biot-Savart, r = {} cm", r * 100.0), bs[k] * 1e9, "nT", 2);
    }
    let bm = b_maxwell(0.025, A, I);
    assert!((bs[0] - bm).abs() / bm < 0.02);
    assert!((bs[2] - b_maxwell(0.08, A, I)).abs() / b_maxwell(0.08, A, I) < 0.02);
    let bs_thin = b_biot_savart(0.025, 0.0001);
    assert!((bs_thin - bm).abs() < (bs[0] - bm).abs() / 5.0);

    let (p, e) = ([0.3, 0.7, 0.2], 1e-3);
    let mut dc = 0.0;
    for k in 0..3 {
        let (mut q, mut m) = (p, p);
        q[k] += e;
        m[k] -= e;
        dc += (curl(q)[k] - curl(m)[k]) / (2.0 * e);
    }
    show("div(curl F) at (0.3, 0.7, 0.2), |value|", dc.abs(), "", 6);
    assert!(dc.abs() < 1e-5);
    assert!((curl(p)[2] - (2.0 * 0.3 * 0.2 - 0.2 * (0.7f64 * 0.2).cos())).abs() < 1e-6); // curl by hand

    show("wrong: old Ampere, gap surface, 8 cm", b_old_ampere(0.08) * 1e9, "nT", 2);
    show("wrong: wire formula inside gap, 2.5 cm", MU0 * I / (2.0 * PI * 0.025) * 1e9, "nT", 2);
    show("wrong: gap formula past the rim, 8 cm", MU0 * I * 0.08 / (2.0 * PI * A * A) * 1e9, "nT", 2);
    let x = 2.0 * PI * 1e9 * A / C_EXACT;
    show("1 GHz: u = 2 pi f a / c", x, "", 4);
    let (js, ji) = (j0_series(x), j0_integral(x, 2000));
    show("rim / centre E at 1 GHz, series", js, "", 4);
    show("rim / centre E at 1 GHz, integral", ji, "", 4);
    assert!((js - ji).abs() < 1e-9);
    show("rim / centre, first correction 1 - u^2/4", 1.0 - x * x / 4.0, "", 4);
    let x6 = 2.0 * PI * 1e6 * A / C_EXACT;
    show("1 MHz: rim dip 1 - J0, parts per million", (1.0 - j0_series(x6)) * 1e6, "ppm", 4);
    show("1 MHz: wavelength c / f", C_EXACT / 1e6, "m", 2);
    show("try: a = 10 cm, B at 2.5 cm", b_maxwell(0.025, 0.10, I) * 1e9, "nT", 2);
    show("try: a = 10 cm, B at 8 cm", b_maxwell(0.08, 0.10, I) * 1e9, "nT", 2);
    show("try: I = 1 A, B at 8 cm", b_maxwell(0.08, A, 1.0) * 1e6, "uT", 3);
    show("try: 100 MHz, rim / centre", j0_series(2.0 * PI * 1e8 * A / C_EXACT), "", 5);
    show("try: gap 0.1 mm, Biot-Savart at 2.5 cm", bs_thin * 1e9, "nT", 2);
    show("try: gap 2 mm, voltage after 1 us", e1 * 0.002, "V", 1);
    let rs: Vec<i32> = (0..11).collect();
    let row = |f: &dyn Fn(i32) -> String| rs.iter().map(|&r| f(r)).collect::<Vec<_>>().join(" ");
    println!("chart, r (cm)        {}", row(&|r| format!("{:>6}", r)));
    let gap_b = |r: i32| b_maxwell(if r > 0 { r as f64 / 100.0 } else { 1e-9 }, A, I) * 1e9;
    println!("chart, B in gap (nT) {}", row(&|r| format!("{:>6.2}", gap_b(r))));
    let old_b = |r: i32| b_old_ampere(if r > 0 { r as f64 / 100.0 } else { 1e-9 }) * 1e9;
    println!("chart, old Ampere    {}", row(&|r| format!("{:>6.2}", old_b(r))));
    println!(
        "figure, 2 px per mm across: axis x 210, plate edges x {} and {}, loop x {} and {}; 1 mm gap drawn 40 px (schematic)",
        210.0 - 2000.0 * A, 210.0 + 2000.0 * A, 210.0 - 2000.0 * 0.08, 210.0 + 2000.0 * 0.08
    );
    println!("ALL CHECKS PASS");
}
