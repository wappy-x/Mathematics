// RLC resonance: a series tuner picking 98.5 MHz. Three roads to f0 and Q:
// the formulas, a frequency sweep of the complex impedance, and a time-domain simulation.
use std::f64::consts::PI;

const L: f64 = 100e-9; // henry
const R: f64 = 0.5; // ohm
const F_STATION: f64 = 98.5e6; // hertz
const V_ANT: f64 = 10e-6; // volt, antenna EMF
const C_LIGHT: f64 = 299792458.0; // m/s, exact by the SI definition

#[derive(Clone, Copy)]
struct Cx { re: f64, im: f64 } // a complex number, written out
impl Cx { fn abs(self) -> f64 { self.re.hypot(self.im) } }

fn show(label: &str, value: f64, unit: &str, dp: usize) {
    let line = format!("{:<44}{:>14.*} {}", label, dp, value, unit);
    println!("{}", line.trim_end());
}

fn z(f: f64, r: f64, c: f64) -> Cx {
    let w = 2.0 * PI * f;
    Cx { re: r, im: w * L - 1.0 / (w * c) }
}
fn gain(f: f64, r: f64, c: f64) -> f64 { r / z(f, r, c).abs() } // |I(f)| / |I(f0)|

fn edge(level: f64, mut lo: f64, mut hi: f64, c: f64) -> f64 { // bisection for gain = level
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (gain(lo, R, c) - level) * (gain(mid, R, c) - level) <= 0.0 { hi = mid } else { lo = mid }
    }
    (lo + hi) / 2.0
}

// RK4 on q' = i, L i' = v(t) - R i - q/C
fn step(q: f64, i: f64, t: f64, h: f64, c: f64, drive: &dyn Fn(f64) -> f64) -> (f64, f64) {
    let d = |q: f64, i: f64, t: f64| (i, (drive(t) - R * i - q / c) / L);
    let k1 = d(q, i, t);
    let k2 = d(q + h / 2.0 * k1.0, i + h / 2.0 * k1.1, t + h / 2.0);
    let k3 = d(q + h / 2.0 * k2.0, i + h / 2.0 * k2.1, t + h / 2.0);
    let k4 = d(q + h * k3.0, i + h * k3.1, t + h);
    (q + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0),
     i + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1))
}

fn driven_amplitude(fd: f64, c: f64) -> f64 { // steady current amplitude, from rest
    let (periods, n) = (600usize, 100usize);
    let (w, h) = (2.0 * PI * fd, 1.0 / (fd * n as f64));
    let drive = move |t: f64| V_ANT * (w * t).sin();
    let (mut q, mut i) = (0.0, 0.0);
    for k in 0..periods * n { let r = step(q, i, k as f64 * h, h, c, &drive); q = r.0; i = r.1; }
    let (mut s, mut cc) = (0.0, 0.0);
    for k in 0..n { // project the last period on sin and cos
        let t = (periods * n + k) as f64 * h;
        s += i * (w * t).sin(); cc += i * (w * t).cos();
        let r = step(q, i, t, h, c, &drive); q = r.0; i = r.1;
    }
    2.0 * s.hypot(cc) / n as f64
}

fn main() {
    // ---- road 1: the formulas ----
    let c = 1.0 / ((2.0 * PI * F_STATION).powi(2) * L);
    let w0 = 1.0 / (L * c).sqrt();
    let f0 = w0 / (2.0 * PI);
    let q_f = w0 * L / R;
    let bw = R / (2.0 * PI * L);
    let zeta = (R / 2.0) * (c / L).sqrt(); // spring road: m = L, c = R, k = 1/C
    println!("inputs: L {:.0} nH, R {:.1} ohm, station {:.1} MHz, antenna {:.0} uV", L * 1e9, R, F_STATION / 1e6, V_ANT * 1e6);
    println!("FM band 88 to 108 MHz, channels 200 kHz apart; speed of light 299792458 m/s");
    show(&format!("C that tunes {:.1} MHz", F_STATION / 1e6), c * 1e12, "pF", 4);
    show("w0 = 1/sqrt(LC)", w0 / 1e6, "million rad/s", 4);
    show("f0 = 1/(2 pi sqrt(LC))", f0 / 1e6, "MHz", 4);
    show("reactance of the coil at f0, w0 L", w0 * L, "ohm", 4);
    show("Q = w0 L / R", q_f, "", 4);
    show("bandwidth R/(2 pi L)", bw / 1e3, "kHz", 4);
    show("spring road: zeta = (R/2) sqrt(C/L)", zeta, "", 6);
    show("spring road: Q = 1/(2 zeta)", 1.0 / (2.0 * zeta), "", 4);
    show("car corner, zeta 0.7: Q = 1/(2 zeta)", 1.0 / 1.4, "", 4);
    show("current at f0, V/R", V_ANT / R * 1e6, "uA", 4);
    show("capacitor voltage at f0, Q V", q_f * V_ANT * 1e3, "mV", 4);

    // ---- road 2: frequency domain ----
    let (mut lo, mut hi) = (0.9 * F_STATION, 1.1 * F_STATION);
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..200 { // golden-section search for the smallest |Z|
        let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if z(a, R, c).abs() < z(b, R, c).abs() { hi = b } else { lo = a }
    }
    let f_peak = (lo + hi) / 2.0;
    let s2 = 1.0 / 2f64.sqrt();
    let (f1, f2) = (edge(s2, 0.9 * F_STATION, f_peak, c), edge(s2, f_peak, 1.1 * F_STATION, c));
    let (h1, h2) = (edge(0.5, 0.9 * F_STATION, f_peak, c), edge(0.5, f_peak, 1.1 * F_STATION, c));
    show("sweep: frequency of smallest |Z|", f_peak / 1e6, "MHz", 4);
    show("sweep: lower half-power edge", f1 / 1e6, "MHz", 4);
    show("sweep: upper half-power edge", f2 / 1e6, "MHz", 4);
    show("sweep: bandwidth f2 - f1", (f2 - f1) / 1e3, "kHz", 4);
    show("sweep: Q = f0 / bandwidth", f_peak / (f2 - f1), "", 4);
    show("sweep: sqrt(f1 f2)", (f1 * f2).sqrt() / 1e6, "MHz", 4);
    for fs in [98.7e6, 100.5e6] {
        show(&format!("gain at {:.1} MHz", fs / 1e6), gain(fs, R, c), "", 4);
        show("  in decibels", 20.0 * gain(fs, R, c).log10(), "dB", 2);
    }

    // ---- road 3: time domain ----
    let mut amps = Vec::new();
    for fs in [98.5e6, 98.7e6, 100.5e6] {
        let a = driven_amplitude(fs, c);
        amps.push((fs, a));
        show(&format!("simulated current at {:.1} MHz", fs / 1e6), a * 1e6, "uA", 4);
        show("  phasor V/|Z|", V_ANT / z(fs, R, c).abs() * 1e6, "uA", 4);
    }
    let alpha = R / (2.0 * L); // ring-down: charge C to Q V, let go
    let wd = (w0 * w0 - alpha * alpha).sqrt();
    let (td, n, cycles) = (2.0 * PI / wd, 200usize, 124usize);
    let (mut q, mut i) = (c * q_f * V_ANT, 0.0);
    let energy = |q: f64, i: f64| L * i * i / 2.0 + q * q / (2.0 * c);
    let (e0, h) = (energy(q, i), td / n as f64);
    let mut e1 = 0.0;
    let free = |_t: f64| 0.0;
    for k in 0..cycles * n {
        let r = step(q, i, k as f64 * h, h, c, &free); q = r.0; i = r.1;
        if k == n - 1 { e1 = energy(q, i); }
    }
    let e_end = energy(q, i);
    let q_ring = w0 * cycles as f64 * td / -(e_end / e0).ln();
    show("ring-down: energy lost in one cycle", 100.0 * (1.0 - e1 / e0), "%", 3);
    show("  2 pi / Q, the high-Q estimate of it", 100.0 * 2.0 * PI / q_f, "%", 3);
    show(&format!("ring-down: amplitude left after {} cycles", cycles), 100.0 * (e_end / e0).sqrt(), "%", 3);
    show("  e^-pi, the target after Q cycles", 100.0 * (-PI).exp(), "%", 3);
    show("ring-down: Q from the decay rate", q_ring, "", 4);

    // ---- the band, the neighbour, the range ----
    for fb in [88e6, 108e6] {
        show(&format!("C to tune {:.0} MHz", fb / 1e6), 1e12 / ((2.0 * PI * fb).powi(2) * L), "pF", 4);
        show("  Q there", 2.0 * PI * fb * L / R, "", 4);
    }
    let x = 98.7 / 98.5 - 98.5 / 98.7;
    let q_need = (1.0 / (0.1f64 * 0.1) - 1.0).sqrt() / x;
    show("Q to cut 98.7 MHz to 0.1 of the peak", q_need, "", 1);
    show("  series R that needs", w0 * L / q_need * 1e3, "mohm", 1);
    show("Q with a 75 ohm antenna wired into the loop", w0 * L / (R + 75.0), "", 4);
    show("wavelength at 98.5 MHz", C_LIGHT / 98.5e6, "m", 4);
    show("wavelength at 2.45 GHz", C_LIGHT / 2.45e9 * 100.0, "cm", 2);

    // ---- what breaks ----
    show("wrong: 1/sqrt(LC) read as hertz", 1.0 / (L * c).sqrt() / 1e6, "MHz", 2);
    show("wrong: half-amplitude width", (h2 - h1) / 1e3, "kHz", 2);
    show("wrong: Q = 1/zeta", 1.0 / zeta, "", 4);
    show("  its bandwidth f0/Q", f0 * zeta / 1e3, "kHz", 2);
    show("wrong: bandwidth R/L read as hertz", R / L / 1e6, "MHz", 2);

    let fr: Vec<f64> = (0..11).map(|k| 96.0 + 0.5 * k as f64).collect();
    println!("chart, MHz                {}", fr.iter().map(|f| format!("{:6.1}", f)).collect::<Vec<_>>().join(" "));
    for r in [R, 2.0] {
        let row: Vec<String> = fr.iter().map(|f| format!("{:6.3}", gain(f * 1e6, r, c))).collect();
        println!("chart, R {:.1} ohm, Q {:5.1} {}", r, w0 * L / r, row.join(" "));
    }

    assert!((f_peak - f0).abs() / f0 < 1e-9, "sweep peak must sit at 1/(2 pi sqrt(LC))");
    assert!(((f2 - f1) - bw).abs() / bw < 1e-9, "half-power width must equal R/(2 pi L)");
    assert!(((h2 - h1) - 3f64.sqrt() * bw).abs() / bw < 1e-9, "half-amplitude width is sqrt(3) bandwidths");
    assert!(((f1 * f2).sqrt() - f0).abs() / f0 < 1e-12, "f0 is the geometric mean of the edges");
    assert!((1.0 / (2.0 * zeta) - q_f).abs() / q_f < 1e-12, "spring road and circuit road give one Q");
    for (fs, a) in &amps {
        assert!((a - V_ANT / z(*fs, R, c).abs()).abs() / a < 1e-4, "simulation must match the phasor");
    }
    assert!((q_ring - q_f).abs() / q_f < 1e-3, "ring-down Q must match w0 L / R");
    println!("ALL CHECKS PASS");
}
