// Uncertainty -- the same check as uncertainty_principle_check.py, in Rust.
// Standard library only, no crates.  An electron in a 1 nm box: its position
// spread and momentum spread, reached three ways (formula, position-space sums,
// momentum-space sums), then the commutator pairing, the Gaussian that sits on
// the floor, and the guitar note.
// Compile: rustc --edition 2021 -O uncertainty_principle_check.rs -o /tmp/uncertainty
use std::f64::consts::PI;

const H: f64 = 6.62607015e-34;          // Planck constant, J s, exact (CODATA 2022)
const ME: f64 = 9.1093837139e-31;       // electron mass, kg (CODATA 2022)
const EV: f64 = 1.602176634e-19;        // J per eV, exact
const KB: f64 = 1.380649e-23;           // Boltzmann constant, J/K, exact
const EPS0: f64 = 8.8541878188e-12;     // F/m (CODATA 2022)
const C: f64 = 299792458.0;             // m/s, exact
const NM: f64 = 1e-9;                   // print lengths in nm
const P25: f64 = 1e-25;                 // print momenta in units of 1e-25 kg m/s

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {   // n even
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn phi2(k: f64, a: f64, l: f64) -> f64 {   // |phi(k)|^2 in closed form; L/2 at k = a
    if (k * k - a * a).abs() < 1e-9 * a * a { l / 2.0 }
    else { (2.0 / l) * a * a * 4.0 * (k * l / 2.0).cos().powi(2) / (a * a - k * k).powi(2) }
}

fn box_product(m: f64) -> f64 { m * PI * (1.0 / 12.0 - 1.0 / (2.0 * m * m * PI * PI)).sqrt() }

fn main() {
    let hbar = H / (2.0 * PI);
    let l = 1.0 * NM;                                   // the box
    let a = PI / l;                                     // ground state's wavenumber, rad/m
    let psi = |x: f64| (2.0 / l).sqrt() * (a * x).sin();

    // road 1: the formulas
    let sx = l * (1.0 / 12.0 - 1.0 / (2.0 * PI * PI)).sqrt();
    let sp = PI * hbar / l;
    let floor = hbar / (2.0 * sx);

    // road 2: sums in position space; the slope by a finite difference
    let (n, d) = (4000usize, l * 1e-6);
    let dpsi = |x: f64| (psi(x + d) - psi(x - d)) / (2.0 * d);
    let norm = simpson(|x| psi(x).powi(2), 0.0, l, n);
    let xbar = simpson(|x| x * psi(x).powi(2), 0.0, l, n);
    let sx2 = simpson(|x| (x - xbar).powi(2) * psi(x).powi(2), 0.0, l, n).sqrt();
    let sp2 = hbar * simpson(|x| dpsi(x).powi(2), 0.0, l, n).sqrt();      // <p> = 0 for a real psi
    let pbar = hbar * simpson(|x| psi(x) * dpsi(x), 0.0, l, n);           // <p> = -i hbar times this
    let pair = -hbar * simpson(|x| (x - xbar) * psi(x) * dpsi(x), 0.0, l, n); // Im <(x - xbar)psi, p psi>

    // road 3: momentum space.  phi(k) = integral of psi e^(-ikx); check it, then sum k^2 |phi|^2
    let phi2_direct = |k: f64| simpson(|x| psi(x) * (k * x).cos(), 0.0, l, n).powi(2)
        + simpson(|x| psi(x) * (k * x).sin(), 0.0, l, n).powi(2);
    assert!([0.0, 2.0 * a].iter().all(|&k| (phi2_direct(k) - phi2(k, a, l)).abs() < 1e-6 * phi2(k, a, l)), "closed-form |phi|^2 against the direct transform");
    let kk = 400.0 * a;
    let mass = 2.0 * simpson(|k| phi2(k, a, l), 0.0, kk, 40000) / (2.0 * PI);
    let k2 = 2.0 * simpson(|k| k * k * phi2(k, a, l), 0.0, kk, 40000) / (2.0 * PI) + 4.0 * a * a / (PI * l * kk);
    let sp3 = hbar * k2.sqrt();
    let (e, kt) = (sp * sp / (2.0 * ME) / EV, KB * 300.0 / EV);   // kinetic energy and kT at 300 K, eV

    // the Gaussian with the same position spread sits exactly on the floor
    let g = |x: f64| (2.0 * PI * sx * sx).powf(-0.25) * (-x * x / (4.0 * sx * sx)).exp();
    let dg = |x: f64| (g(x + d) - g(x - d)) / (2.0 * d);
    let gx = simpson(|x| x * x * g(x).powi(2), -12.0 * sx, 12.0 * sx, n).sqrt();
    let gp = hbar * simpson(|x| dg(x).powi(2), -12.0 * sx, 12.0 * sx, n).sqrt();

    // other states: one wave round a 1 nm ring, psi = (cr + i sr); its momentum spread by sums
    let (cr, sr) = (|x: f64| (2.0 * PI * x / l).cos() / l.sqrt(), |x: f64| (2.0 * PI * x / l).sin() / l.sqrt());
    let (dc, ds) = (|x: f64| (cr(x + d) - cr(x - d)) / (2.0 * d), |x: f64| (sr(x + d) - sr(x - d)) / (2.0 * d));
    let ring_pbar = hbar * simpson(|x| cr(x) * ds(x) - sr(x) * dc(x), 0.0, l, n);    // Re <psi, p psi>
    let ring_sp = simpson(|x| (hbar * ds(x) - ring_pbar * cr(x)).powi(2) + (hbar * dc(x) + ring_pbar * sr(x)).powi(2), 0.0, l, n).sqrt();
    let ring_sx = l / 12f64.sqrt();

    // what breaks
    let wrong_width = hbar / (2.0 * l);                 // box width used as the spread
    let wrong_h = 2.0 * PI * hbar / (2.0 * sx);         // h in place of hbar
    let fermi_v = PI * hbar / 1e-15 / ME;               // the same box shrunk to 1 fm, speed spread m/s

    // the guitar: E2 and F2, and the shortest note that tells them apart
    let (fe, ff) = (440.0 * 2f64.powf(-29.0 / 12.0), 440.0 * 2f64.powf(-28.0 / 12.0));
    let sf_need = (ff - fe) / 2.0;
    let st_need = 1.0 / (4.0 * PI * sf_need);
    let burst = |t: f64| (-t * t / (4.0 * st_need * st_need)).exp() * (2.0 * PI * fe * t).cos();
    let dt = 12.0 * st_need / 1200.0;
    let ts: Vec<f64> = (0..1201).map(|i| -6.0 * st_need + i as f64 * dt).collect();
    let power = |f: f64| {                              // |X(f)|^2 by a direct sum over the burst
        let re: f64 = ts.iter().map(|&t| burst(t) * (2.0 * PI * f * t).cos()).sum::<f64>() * dt;
        let im: f64 = ts.iter().map(|&t| burst(t) * (2.0 * PI * f * t).sin()).sum::<f64>() * dt;
        re * re + im * im
    };
    let sb = 1.0 / (4.0 * PI * st_need);                // +-6 of the burst's own spread
    let fs: Vec<f64> = (0..241).map(|i| fe - 6.0 * sb + i as f64 * 12.0 * sb / 240.0).collect();
    let p: Vec<f64> = fs.iter().map(|&f| power(f)).collect();
    let tot: f64 = p.iter().sum();
    let fmean = fs.iter().zip(&p).map(|(f, q)| f * q).sum::<f64>() / tot;
    let sf_meas = (fs.iter().zip(&p).map(|(f, q)| (f - fmean).powi(2) * q).sum::<f64>() / tot).sqrt();

    // hydrogen: minimise hbar^2/(2 m r^2) - e^2/(4 pi eps0 r)
    let r0 = 4.0 * PI * EPS0 * hbar * hbar / (ME * EV * EV);
    let eh = hbar * hbar / (2.0 * ME * r0 * r0) / EV - EV / (4.0 * PI * EPS0 * r0);

    let rows: Vec<(&str, f64)> = vec![
        ("hbar, 1e-34 J s", hbar / 1e-34), ("electron mass, 1e-31 kg", ME / 1e-31),
        ("1/12 - 1/(2 pi^2)", 1.0 / 12.0 - 1.0 / (2.0 * PI * PI)), ("a = pi/L, 1/nm", a * NM),
        ("1 position spread sx, formula, nm", sx / NM),
        ("2 position spread sx, sums, nm", sx2 / NM),
        ("  norm of psi, sums", norm),
        ("1 momentum spread sp, formula, 1e-25 kg m/s", sp / P25),
        ("2 momentum spread sp, slope sums, 1e-25", sp2 / P25),
        ("3 momentum spread sp, from phi(k), 1e-25", sp3 / P25),
        ("  norm of phi, sums", mass),
        ("  |phi(0)|^2 closed form, nm", phi2(0.0, a, l) / NM),
        ("  |phi(0)|^2 direct integral, nm", phi2_direct(0.0) / NM),
        ("  |phi(2a)|^2 closed form, nm", phi2(2.0 * a, a, l) / NM),
        ("  |phi(2a)|^2 direct integral, nm", phi2_direct(2.0 * a) / NM),
        ("Im pairing / hbar", pair / hbar),
        ("product sx sp / hbar", sx * sp / hbar),
        ("floor hbar/(2 sx), 1e-25", floor / P25),
        ("sp over floor", sp / floor),
        ("speed spread sp/m, km/s", sp / ME / 1e3),
        ("kinetic energy <p^2>/2m, eV", e),
        ("kT at 300 K, eV", kt),
        ("energy over kT", e / kt),
        ("Gaussian sx, nm", gx / NM),
        ("Gaussian sp, 1e-25", gp / P25),
        ("Gaussian product / hbar", gx * gp / hbar),
        ("box level 2 product / hbar", box_product(2.0)), ("box level 3 product / hbar", box_product(3.0)),
        ("ring sx, nm", ring_sx / NM),
        ("ring product / hbar", ring_sx * ring_sp / hbar),
        ("wrong: width as spread, 1e-25", wrong_width / P25),
        ("wrong: h for hbar, 1e-25", wrong_h / P25),
        ("wrong: mean for spread, energy eV", pbar * pbar / (2.0 * ME) / EV),
        ("wrong: 1 fm box, speed over c", fermi_v / C),
        ("guitar E2, Hz", fe), ("guitar F2, Hz", ff),
        ("half the gap, Hz", sf_need),
        ("time spread needed st, ms", st_need * 1e3),
        ("  burst length, about 4 st, ms", 4.0 * st_need * 1e3),
        ("burst spread sf, measured, Hz", sf_meas),
        ("st sf, against 1/(4 pi)", st_need * sf_meas), ("1/(4 pi)", 1.0 / (4.0 * PI)),
        ("hydrogen radius, nm", r0 / NM), ("hydrogen energy, eV", eh),
    ];
    for (name, v) in &rows {
        println!("{:<44}{:12.6}", name, v);
    }

    let ks: Vec<i32> = (-6..=6).map(|i| 2 * i).collect();
    println!("chart, k in 1/nm      {}", ks.iter().map(|k| format!("{:5}", k)).collect::<Vec<_>>().join(" "));
    for w in [1.0f64, 0.5] {
        let (lw, aw) = (w * NM, PI / (w * NM));
        let vals: Vec<String> = ks.iter().map(|&k| format!("{:5.3}", phi2(k as f64 / NM, aw, lw) / (2.0 * PI) / NM)).collect();
        println!("chart, L = {:.1} nm, nm {}", w, vals.join(" "));
    }

    assert!((sx2 - sx).abs() < 1e-6 * sx, "position spread: sums against formula");
    assert!((sp2 - sp).abs() < 1e-5 * sp, "momentum spread: slope sums against formula");
    assert!((sp3 - sp).abs() < 1e-4 * sp, "momentum spread: momentum space against formula");
    assert!((pair / hbar - 0.5).abs() < 1e-6, "commutator fixes Im pairing at hbar/2");
    assert!(sx * sp >= hbar / 2.0, "the box obeys the bound");
    assert!(ring_sx * ring_sp < 1e-6 * hbar, "the ring escapes the line's floor: one definite momentum");
    assert!((gx * gp / hbar - 0.5).abs() < 1e-6, "the Gaussian sits on the floor");
    assert!((st_need * sf_meas - 1.0 / (4.0 * PI)).abs() < 1e-4, "time-frequency floor, measured");
    assert!((sf_meas - sf_need).abs() < 1e-4 * sf_need, "burst spread: measured against target");
    assert!((eh + 13.6057).abs() < 1e-3, "hydrogen ground energy");
    println!("ALL CHECKS PASS");
}
