// Electromagnetic waves -- the check behind the card.  std only, no crates.
// Road 1: the closed form, c = 1/sqrt(mu0 eps0) and wavelength = c/f.
// Road 2: a simulation that knows only the two curl equations (Yee's leapfrog).
// Road 3: the vector identity the derivation rests on, by finite differences.
use std::f64::consts::PI;

const MU0: f64 = 1.25663706127e-6; // N/A^2, vacuum magnetic permeability (CODATA 2022)
const EPS0: f64 = 8.8541878188e-12; // F/m, vacuum electric permittivity (CODATA 2022)
const C_DEF: f64 = 299792458.0; // m/s, exact: it defines the metre
const F: f64 = 100e6; // Hz, the station
const E0: f64 = 1e-3; // V/m, field amplitude of a clearly heard station
const DX: f64 = 0.05; // m
const DT: f64 = 1e-10; // s; c*DT/DX = 0.6, under the stability limit 1
const H: f64 = 1e-3;

fn f2(v: f64) -> String { format!("{:6.2}", v).replace("-0.00", " 0.00") } // no minus sign on a zero

// Step the two curl equations on a line of cells; returns final E, B and probe traces.
// term is the size of Maxwell's term (1 = true); dx is the cell size.
fn simulate(steps: usize, source: &dyn Fn(f64) -> f64, probes: &[f64], term: f64, dx: f64)
    -> (Vec<f64>, Vec<f64>, Vec<Vec<f64>>) {
    let n = 700; // 700 cells, 35 m at 5 cm; E at x = i*dx, B halfway between
    let (mut e, mut b) = (vec![0.0; n + 1], vec![0.0; n]);
    let mut trace = vec![Vec::new(); probes.len()];
    for s in 0..steps {
        for i in 0..n { b[i] -= DT * (e[i + 1] - e[i]) / dx; } // Faraday: dB/dt = -dE/dx
        // Ampere-Maxwell in vacuum: dE/dt = -(1/(mu0 eps0)) dB/dx
        for i in 1..n { e[i] -= term * DT / (MU0 * EPS0) * (b[i] - b[i - 1]) / dx; }
        e[0] = source((s + 1) as f64 * DT); // the transmitter drives the left end
        for (j, p) in probes.iter().enumerate() { trace[j].push(e[(p / dx).round() as usize]); }
    }
    (e, b, trace)
}

fn peak_time(y: &[f64]) -> f64 { // time of the largest sample, refined by a parabola
    let mut m = 0;
    for i in 1..y.len() { if y[i] > y[m] { m = i; } }
    let (a, b, d) = (y[m - 1], y[m], y[m + 1]);
    ((m + 1) as f64 + 0.5 * (a - d) / (a - 2.0 * b + d)) * DT
}

// time the pulse's peak from 3 m to 9 m
fn pulse_speed(steps: usize, term: f64, dx: f64) -> (f64, Vec<Vec<f64>>) {
    let pulse = |t: f64| E0 * (-((t - 8e-9) / 2e-9).powi(2)).exp();
    let (_, _, tr) = simulate(steps, &pulse, &[3.0, 6.0, 9.0], term, dx);
    ((9.0 - 3.0) / (peak_time(&tr[2]) - peak_time(&tr[0])), tr)
}

// drive at f; zero crossings from 1 m to 11 m
fn wavelength(f: f64) -> (f64, usize, Vec<f64>, Vec<f64>) {
    let ramp = |t: f64| if t < 20e-9 { 0.5 * (1.0 - (PI * t / 20e-9).cos()) } else { 1.0 };
    let (e, b, _) = simulate(600, &|t: f64| E0 * (2.0 * PI * f * t).sin() * ramp(t), &[], 1.0, DX);
    let zs: Vec<f64> = (20..220).filter(|&i| e[i] * e[i + 1] < 0.0)
        .map(|i| (i as f64 + e[i] / (e[i] - e[i + 1])) * DX).collect();
    (2.0 * (zs[zs.len() - 1] - zs[0]) / (zs.len() - 1) as f64, zs.len(), e, b)
}

fn maxabs(v: &[f64]) -> f64 { v.iter().fold(0.0, |m: f64, x| m.max(x.abs())) }

fn field(p: [f64; 3]) -> [f64; 3] { [p[2] * p[2] * p[1].sin(), p[0].powi(3) * p[2].cos(), p[1] * p[0].exp()] }

fn partial(f: &dyn Fn([f64; 3]) -> [f64; 3], j: usize, a: usize, pt: [f64; 3]) -> f64 {
    let (mut up, mut dn) = (pt, pt); // d(component j)/d(coordinate a), central difference
    up[a] += H; dn[a] -= H;
    (f(up)[j] - f(dn)[j]) / (2.0 * H)
}

fn curl(f: &dyn Fn([f64; 3]) -> [f64; 3], pt: [f64; 3]) -> [f64; 3] {
    [partial(f, 2, 1, pt) - partial(f, 1, 2, pt),
     partial(f, 0, 2, pt) - partial(f, 2, 0, pt),
     partial(f, 1, 0, pt) - partial(f, 0, 1, pt)]
}

fn main() {
    // ---- Road 1: closed form
    let c = 1.0 / (MU0 * EPS0).sqrt();
    let lam = c / F;
    let (omega, k) = (2.0 * PI * F, 2.0 * PI / lam);
    println!("mu0  = {:.11} x 10^-6 N/A^2, eps0 = {:.10} x 10^-12 F/m", MU0 * 1e6, EPS0 * 1e12);
    println!("mu0 eps0 = {:.4} x 10^-17 s^2/m^2", MU0 * EPS0 * 1e17);
    println!("c = 1/sqrt(mu0 eps0) = {:.0} m/s, defined value {:.0} m/s", c, C_DEF);
    assert!((c - C_DEF).abs() / C_DEF < 1e-9); // consistency of the constants: since 2019 eps0 = 1/(mu0 c^2)
    println!("f = {:.0} MHz: period {:.0} ns, wavelength {:.4} m", F / 1e6, 1e9 / F, lam);
    println!("omega = {:.1} x 10^6 rad/s, k = {:.4} rad/m, omega/k = {:.0} m/s", omega / 1e6, k, omega / k);
    println!("quarter-wave whip {:.4} m, half-wave dipole {:.4} m", lam / 4.0, lam / 2.0);
    println!("other waves: 50 Hz {:.0} km, 2.45 GHz {:.4} m, 3 GHz {:.4} m; light in 1 ns {:.4} m",
             c / 50.0 / 1e3, c / 2.45e9, c / 3e9, c * 1e-9);
    println!("E0 = {:.3} mV/m, B0 = E0/c = {:.3} pT", E0 * 1e3, E0 / c * 1e12);
    for ns in [0.0, 2.5, 5.0, 7.5, 10.0] {
        println!("crest at t = {:4.1} ns: x = {:.3} m", ns, c * ns * 1e-9);
    }
    let xs: Vec<f64> = (0..13).map(|i| 0.25 * i as f64).collect();
    let row = |g: &dyn Fn(f64) -> String| xs.iter().map(|&x| g(x)).collect::<Vec<_>>().join(" ");
    println!("chart, x (m)         {}", row(&|x| format!("{:6.2}", x)));
    println!("chart, E at 0 ns     {}", row(&|x| f2(1e3 * E0 * (k * x).cos())));
    println!("chart, E at 2.5 ns   {}", row(&|x| f2(1e3 * E0 * (k * x - omega * 2.5e-9).cos())));
    for deg in [0, 30, 45, 60, 90] {
        let g = (deg as f64 * PI / 180.0).cos();
        let db = if g > 1e-9 { format!("{:6.2} dB", 20.0 * g.log10()) } else { "   none".to_string() };
        println!("antenna tilted {:2} deg: voltage x {:.3}, power x {:.3}, {}", deg, g, g * g, db);
    }

    // ---- Road 2: step the two curl equations, 60 cells per wavelength
    let probes = [3.0, 6.0, 9.0];
    let (v, tr) = pulse_speed(450, 1.0, DX);
    println!("simulated pulse speed, 3 m to 9 m: {:.0} m/s ({:.4} of c)", v, v / c);
    assert!((v / c - 1.0).abs() < 5e-3);
    for (j, p) in probes.iter().enumerate() {
        let pk = tr[j].iter().cloned().fold(f64::MIN, f64::max);
        println!("pulse peak at {:.0} m: {:.3} mV/m", p, pk * 1e3);
        assert!((pk - E0).abs() < 0.01 * E0);
    }

    let (lam_sim, nz, e, b) = wavelength(F);
    println!("simulated wavelength, 1 m to 11 m: {:.4} m ({} zero crossings)", lam_sim, nz);
    assert!((lam_sim / lam - 1.0).abs() < 5e-3);
    let ratio = maxabs(&e[20..220]) / (c * maxabs(&b[20..220]));
    println!("simulated E/(cB) = {:.3}", ratio);
    assert!((ratio - 1.0).abs() < 1e-2);

    // ---- Road 3: curl of curl of a field with zero divergence equals minus its Laplacian
    let (x, y, z) = (0.3f64, 0.7f64, 1.1f64);
    let num = curl(&|p| curl(&field, p), [x, y, z]);
    let exact = [(z * z - 2.0) * y.sin(), (x.powi(3) - 6.0 * x) * z.cos(), -y * x.exp()]; // -Laplacian, by hand
    let s5 = |a: [f64; 3]| a.iter().map(|v| format!("{:.5}", v)).collect::<Vec<_>>().join(" ");
    println!("curl curl F, differences: {}", s5(num));
    println!("minus Laplacian, by hand: {}", s5(exact));
    assert!((0..3).all(|i| (num[i] - exact[i]).abs() < 1e-5));

    // ---- What breaks
    println!("wrong: omega in place of f: wavelength {:.4} m, whip {:.4} m", c / omega, c / omega / 4.0);
    println!("wrong: no square root: speed {:.3} x 10^16 m/s", 1.0 / (MU0 * EPS0) / 1e16);
    println!("outside the model: in polyethylene (permittivity 2.25 eps0): wavelength {:.4} m", lam / 2.25f64.sqrt());
    let vq = pulse_speed(800, 0.25, DX).0; // Maxwell's term at a quarter of its size
    println!("Maxwell's term at a quarter: pulse speed {:.0} m/s ({:.4} of c)", vq, vq / c);
    assert!((vq / (c / 2.0) - 1.0).abs() < 1e-2); // a quarter of the term halves the speed
    let lam88 = wavelength(88e6).0;
    println!("try: F = 88 MHz: wavelength {:.4} m, whip {:.4} m, simulated {:.4} m", c / 88e6, c / 88e6 / 4.0, lam88);
    let v20 = pulse_speed(450, 1.0, 0.2).0;
    println!("try: 20 cm cells, {:.0} per wavelength: pulse speed {:.4} of c", lam / 0.2, v20 / c);
    println!("try: 0.2 ns step: light crosses {:.2} cells per step, over the limit 1", c * 2e-10 / DX);
    println!("ALL CHECKS PASS");
}
