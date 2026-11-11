// Schrodinger's equation and the particle in a box -- the same check in Rust.
// No crates.  An electron in a box 1 nm wide, walls it cannot cross, set
// beside a guitar string.  Three roads to the energy levels: the closed form,
// a shooting solve of the equation itself (RK4 plus bisection), and a finite
// well whose walls are raised until it becomes the box.
use std::f64::consts::PI;

const H: f64 = 6.62607015e-34;      // Planck constant, J s (exact in SI)
const ME: f64 = 9.1093837139e-31;   // electron mass, kg (CODATA 2022)
const EV: f64 = 1.602176634e-19;    // one electronvolt, J (exact in SI)
const C: f64 = 299792458.0;         // speed of light, m/s (exact in SI)
const L: f64 = 1e-9;                // box width, m

fn hbar() -> f64 { H / (2.0 * PI) }
fn kk() -> f64 { 2.0 * ME * EV * 1e-9 * 1e-9 / (hbar() * hbar()) } // phi'' = -K E phi

fn level(n: f64, width: f64) -> f64 { n * n * H * H / (8.0 * ME * width * width) / EV }

fn shoot(e: f64, steps: usize, w: f64) -> f64 { // phi(0)=0, phi'(0)=1, RK4 across w nm
    let (dx, k) = (w / steps as f64, kk());
    let (mut y, mut v) = (0.0f64, 1.0f64);
    for _ in 0..steps {
        let (k1y, k1v) = (v, -k * e * y);
        let (k2y, k2v) = (v + dx / 2.0 * k1v, -k * e * (y + dx / 2.0 * k1y));
        let (k3y, k3v) = (v + dx / 2.0 * k2v, -k * e * (y + dx / 2.0 * k2y));
        let (k4y, k4v) = (v + dx * k3v, -k * e * (y + dx * k3y));
        y += dx / 6.0 * (k1y + 2.0 * k2y + 2.0 * k3y + k4y);
        v += dx / 6.0 * (k1v + 2.0 * k2v + 2.0 * k3v + k4v);
    }
    y
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {
    let mut fa = f(a);
    for _ in 0..60 {
        let m = (a + b) / 2.0;
        if (f(m) < 0.0) == (fa < 0.0) { a = m; fa = f(m); } else { b = m; }
    }
    (a + b) / 2.0
}

fn shot_levels(count: usize) -> Vec<f64> {   // scan E for sign changes, then bisect
    let (mut found, mut e) = (Vec::new(), 0.02f64);
    let mut prev = shoot(e, 2000, 1.0);
    while found.len() < count {
        let nxt = shoot(e + 0.02, 2000, 1.0);
        if (prev < 0.0) != (nxt < 0.0) { found.push(bisect(|x| shoot(x, 2000, 1.0), e, e + 0.02)); }
        e += 0.02;
        prev = nxt;
    }
    found
}

fn finite_well(v0: f64, a: f64) -> f64 {     // even ground state, a nm wide, v0 eV deep
    let k = kk();
    let z0 = a / 2.0 * (k * v0).sqrt();
    let z = bisect(|z: f64| z * z.tan() - (z0 * z0 - z * z).sqrt(), 1e-9, z0.min(PI / 2.0) - 1e-12);
    4.0 * z * z / (k * a * a)
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    let n = 1000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn phi(n: f64, x: f64) -> f64 { 2.0f64.sqrt() * (n * PI * x).sin() }   // x in nm

fn main() {
    let k = kk();
    let e: Vec<f64> = (1..6).map(|n| level(n as f64, L)).collect();
    let s = shot_levels(5);
    println!("constants: h 6.62607015 x 10^-34 J s, hbar {:.9} x 10^-34 J s, m_e {:.10} x 10^-31 kg",
             hbar() * 1e34, ME * 1e31);
    println!("box width L = 1.000 nm; K = 2 m_e (1 eV)(1 nm)^2 / hbar^2 = {:.4}", k);
    println!("n   E_n formula   E_n shooting   E_n/E_1   E_n/h");
    for n in 0..5 {
        println!("{}   {:8.4} eV   {:9.4} eV   {:7.2}   {:6.1} THz",
                 n + 1, e[n], s[n], e[n] / e[0], e[n] * EV / H / 1e12);
    }
    println!("hand route: h^2 = {:.4} x 10^-67 J^2 s^2, 8 m_e L^2 = {:.4} x 10^-48 kg m^2, h c = {:.4} x 10^-25 J m",
             H * H * 1e67, 8.0 * ME * L * L * 1e48, H * C * 1e25);
    println!("E_1 = {:.4} x 10^-20 J = {:.5} eV", e[0] * EV * 1e20, e[0]);
    let g: Vec<f64> = (0..3).map(|i| e[i + 1] - e[i]).collect();
    println!("gaps E2-E1, E3-E2, E4-E3: {:.3}, {:.3}, {:.3} eV, ratio {:.0} : {:.0} : {:.0}",
             g[0], g[1], g[2], g[0] / e[0], g[1] / e[0], g[2] / e[0]);
    let lam = H * C / (g[0] * EV);
    println!("photon from level 2 to level 1: {:.4} eV, wavelength {:.0} nm", g[0], lam * 1e9);
    println!("normaliser sqrt(2/L) = {:.0} per root metre = {:.4} per root nm", (2.0 / L).sqrt(), 2.0f64.sqrt());
    let norm = simpson(|x| phi(1.0, x).powi(2), 0.0, 1.0);
    let o12 = simpson(|x| phi(1.0, x) * phi(2.0, x), 0.0, 1.0);
    let o13 = simpson(|x| phi(1.0, x) * phi(3.0, x), 0.0, 1.0);
    println!("Simpson: total probability n=1 {:.6}; overlap(1,2) {:.6}; overlap(1,3) {:.6}", norm, o12.abs(), o13.abs());
    let mid: Vec<f64> = [1.0, 2.0].iter().map(|&n| simpson(|x| phi(n, x).powi(2), 1.0 / 3.0, 2.0 / 3.0)).collect();
    let f1 = 1.0 / 3.0 + 3.0f64.sqrt() / (2.0 * PI);
    let f2 = 1.0 / 3.0 - 3.0f64.sqrt() / (4.0 * PI);
    println!("P(middle third): n=1 {:.4} (formula {:.4}), n=2 {:.4} (formula {:.4}), classical 0.3333",
             mid[0], f1, mid[1], f2);
    let (ls, f1s) = (0.65f64, 110.0f64);
    let harm: Vec<String> = (1..6).map(|n| format!("{:.0}", n as f64 * f1s)).collect();
    println!("guitar A string: {:.2} m, wave speed {:.0} m/s, harmonics {} Hz", ls, 2.0 * ls * f1s, harm.join(" "));
    let sr: Vec<String> = (1..6).map(|n| format!("{:.0}", n as f64 * f1s / f1s)).collect();
    let er: Vec<String> = e.iter().map(|x| format!("{:.0}", x / e[0])).collect();
    println!("chart, string ratio: {}; electron ratio: {}", sr.join(" "), er.join(" "));
    println!("box width scan: L 0.5, 1, 2 nm -> E_1 {:.4}, {:.4}, {:.4} eV",
             level(1.0, 0.5e-9), level(1.0, 1e-9), level(1.0, 2e-9));
    let fw: Vec<f64> = [1.0, 10.0, 100.0].iter().map(|&v| finite_well(v, 1.0)).collect();
    println!("finite well 1 nm wide, ground level: depth 1 eV {:.4}, 10 eV {:.4}, 100 eV {:.4} eV", fw[0], fw[1], fw[2]);
    println!("mistake, h in place of hbar: E_1 = {:.2} eV", e[0] * 4.0 * PI * PI);
    println!("mistake, levels in step like a string: E_3 = {:.3} eV (right {:.3} eV)", 3.0 * e[0], e[2]);
    println!("mistake, normaliser sqrt(1/L): total probability {:.4}", norm / 2.0);
    println!("mistake, infinite walls for a 1 eV well: {:.4} eV against {:.4} eV, {:.0}% high",
             e[0], fw[0], 100.0 * (e[0] / fw[0] - 1.0));
    println!("figure, walls x_px 60 360, 300 px per nm, 70 px per eV, levels y_px {:.2} {:.2} {:.2}, amplitude 25 px",
             275.0 - 70.0 * e[0], 275.0 - 70.0 * e[1], 275.0 - 70.0 * e[2]);
    let starved: Vec<f64> = [(0.3, 0.45), (9.0, 10.0)].iter().map(|&(lo, hi)| bisect(|x| shoot(x, 20, 1.0), lo, hi)).collect();
    println!("try: steps=20, level 1 {:.4} eV, level 5 {:.4} eV; well 1000 eV deep, ground level {:.4} eV",
             starved[0], starved[1], finite_well(1000.0, 1.0));

    assert!((0..5).all(|i| (s[i] - e[i]).abs() / e[i] < 1e-6));       // shooting meets formula
    assert!((PI * PI / k - e[0]).abs() / e[0] < 1e-12);                // hbar form meets h form
    assert!(fw[0] < fw[1] && fw[1] < fw[2] && fw[2] < e[0] && (e[0] - fw[2]) / e[0] < 0.25);
    assert!((norm - 1.0).abs() < 1e-9 && o12.abs() < 1e-9 && o13.abs() < 1e-9);
    assert!((mid[0] - f1).abs() < 1e-9 && (mid[1] - f2).abs() < 1e-9);
    assert!((lam - H * C / ((s[1] - s[0]) * EV)).abs() / lam < 1e-6);   // wavelength, by the shooting road
    assert!((bisect(|x| shoot(x, 2000, 2.0), 0.05, 0.15) / level(1.0, 2e-9) - 1.0).abs() < 1e-6); // 1/L^2: shoot a 2 nm box
    println!("ALL CHECKS PASS");
}
