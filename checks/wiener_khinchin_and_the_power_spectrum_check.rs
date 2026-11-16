// Wiener-Khinchin -- the check behind the card.  Rust std only, no crates.
// Tape hiss, modelled as white noise of level N0 = 100 uV^2/Hz (two-sided),
// goes through a first-order hiss filter with corner 5 kHz.  Its power spectrum
// is found four ways: gain squared, the transform of the autocorrelation, the
// windowed definition E|X_T^|^2 / T, and a simulation.  All integrals written out.
use std::f64::consts::PI;

const N0: f64 = 100.0; // hiss level, uV^2/Hz
const XC: f64 = 5000.0; // filter corner, Hz
const A: f64 = 2.0 * PI * XC; // filter h(t) = A e^(-A t), t >= 0; gain h^(xi) = 1/(1 + i xi/XC)
const R0: f64 = N0 * PI * XC; // R_Y(0), the output variance, uV^2
const FS: f64 = 100000.0; // 100 kHz sampling
const N: usize = 1000; // records of 10 ms
const K: usize = 1000; // 1000 records
const HUM: f64 = 1000.0; // 50 Hz hum, amplitude 1 mV, random phase

fn r_y(tau: f64) -> f64 { R0 * (-A * tau.abs()).exp() }
fn gain2(xi: f64) -> f64 { 1.0 / (1.0 + (xi / XC) * (xi / XC)) }

fn show(out: &mut Vec<String>, label: &str, v: f64, dec: usize) {
    out.push(format!("{:<46}{:14.*}", label, dec, v));
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n {
        s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    (f(a) + f(b) + s) * h / 3.0
}

fn transform_r(xi: f64, cut: f64, n: usize) -> f64 {
    2.0 * simpson(|t| r_y(t) * (2.0 * PI * xi * t).cos(), 0.0, cut, n)
}

fn windowed(xi: f64, t_rec: f64) -> f64 {
    let cut = t_rec.min(2e-3); // beyond 2 ms, R_Y < e^(-62) of its peak
    2.0 * simpson(|t| (1.0 - t / t_rec) * r_y(t) * (2.0 * PI * xi * t).cos(), 0.0, cut, 40000)
}

fn splitmix(state: &mut u64) -> u64 {
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = *state;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (z ^ (z >> 31)) >> 11
}

fn sampled_s(xi: f64, fs: f64) -> f64 {
    let c = (-A / fs).exp();
    N0 * (1.0 - c) * (1.0 - c) / (1.0 - 2.0 * c * (2.0 * PI * xi / fs).cos() + c * c)
}

fn main() {
    let mut out: Vec<String> = Vec::new();
    for xi in [5000.0f64, 10000.0] {
        let kz = xi / 1000.0;
        show(&mut out, &format!("gain squared at {:.0} kHz", kz), gain2(xi), 6);
        show(&mut out, &format!("S_Y({:.0} kHz) = N0 x gain squared, uV^2/Hz", kz), N0 * gain2(xi), 6);
        show(&mut out, "  transform of R_Y, 2000 steps to 2 ms", transform_r(xi, 2e-3, 2000), 6);
        show(&mut out, "  transform of R_Y, 4000 steps to 2 ms", transform_r(xi, 2e-3, 4000), 6);
    }
    show(&mut out, "R_Y(0) = N0 pi xi_c, output variance, uV^2", R0, 2);
    let x = 200000.0; // area under S_Y: sums to 200 kHz plus the closed-form tail beyond
    let area = 2.0 * simpson(|v| N0 * gain2(v), 0.0, x, 20000);
    let tail = 2.0 * N0 * XC * (PI / 2.0 - (x / XC).atan());
    show(&mut out, "  area of S_Y by sums to 200 kHz", area, 2);
    show(&mut out, "  plus the closed-form tail beyond 200 kHz", area + tail, 2);
    show(&mut out, "output rms, uV", R0.sqrt(), 2);
    show(&mut out, "hiss rms in the audible band +-20 kHz, uV", (N0 * 40000.0).sqrt(), 2);
    show(&mut out, "output rms in the audible band, uV", (2.0 * N0 * XC * 4.0f64.atan()).sqrt(), 2);
    let s10 = N0 * gain2(10000.0);
    for (t, lab) in [(1e-4, "0.1"), (1e-3, "1"), (1e-2, "10"), (1e-1, "100")] {
        show(&mut out, &format!("windowed E|X_T^|^2/T at 10 kHz, T = {} ms", lab), windowed(10000.0, t), 6);
    }
    let w2 = 2.0 * PI * 10000.0;
    let lead = -2.0 * R0 * (A * A - w2 * w2) / ((A * A + w2 * w2) * (A * A + w2 * w2));
    show(&mut out, "T x gap at T = 100 ms, uV^2", 0.1 * (windowed(10000.0, 0.1) - s10), 9);
    show(&mut out, "  closed form -2 R0 (a^2-w^2)/(a^2+w^2)^2", lead, 9);

    // ---- simulation: independent samples at fs stand in for white noise ----
    let c = (-A / FS).exp(); // y[n] = C y[n-1] + (1 - C) x[n]: the hiss filter, sampled
    let amp = (12.0 * N0 * FS).sqrt(); // uniform samples of variance N0 fs
    let tab: Vec<(f64, f64)> = (0..40).map(|k| ((2.0 * PI * k as f64 / 40.0).cos(), (2.0 * PI * k as f64 / 40.0).sin())).collect();
    let unit = 2.0f64.powi(-53);
    let mut state: u64 = 2026;
    let mut y = 0.0;
    for _ in 0..500 {
        let u = splitmix(&mut state) as f64;
        y = c * y + (1.0 - c) * amp * (u * unit - 0.5);
    }
    let (mut sum_p, mut sum_p2, mut sumvar) = ([0.0f64; 9], [0.0f64; 9], 0.0f64);
    let mut rec = vec![0.0f64; N];
    for _ in 0..K {
        for n in 0..N {
            let u = splitmix(&mut state) as f64;
            y = c * y + (1.0 - c) * amp * (u * unit - 0.5);
            rec[n] = y;
        }
        for m in 0..9 {
            let (mut re, mut im) = (0.0, 0.0);
            for (n, &v) in rec.iter().enumerate() {
                re += v * tab[(m * n) % 40].0;
                im += v * tab[(m * n) % 40].1;
                if m == 0 { sumvar += v * v; }
            }
            let p = (re * re + im * im) / (N as f64 * FS);
            sum_p[m] += p;
            sum_p2[m] += p * p;
        }
    }
    let mean: Vec<f64> = (0..9).map(|m| sum_p[m] / K as f64).collect();
    let se: Vec<f64> = (0..9).map(|m| ((sum_p2[m] / K as f64 - mean[m] * mean[m]) / K as f64).sqrt()).collect();
    let g = |h: i64| N0 * FS * (1.0 - c) * (1.0 - c) / (1.0 - c * c) * c.powf(h.abs() as f64);
    let expect = |xi: f64| {
        let mut s = 0.0;
        for h in -(N as i64) + 1..N as i64 {
            s += (1.0 - h.abs() as f64 / N as f64) * g(h) * (2.0 * PI * xi * h as f64 / FS).cos();
        }
        s / FS
    };
    for m in [2usize, 4] {
        let xi = 2500.0 * m as f64;
        show(&mut out, &format!("sim {:.0} kHz: mean of 1000 periodograms", xi / 1000.0), mean[m], 6);
        show(&mut out, "  its standard error", se[m], 6);
        show(&mut out, "  exact expectation, 10 ms records", expect(xi), 6);
        show(&mut out, "  sampled spectrum N0 |H_d|^2", sampled_s(xi, FS), 6);
        show(&mut out, "  continuous S_Y", N0 * gain2(xi), 6);
    }
    let simvar = sumvar / (N * K) as f64;
    show(&mut out, "sim output variance, uV^2", simvar, 2);
    show(&mut out, "  sampled output variance g(0), uV^2", g(0), 2);
    for fs in [50e3f64, 100e3, 200e3, 400e3] {
        let cc = (-A / fs).exp();
        out.push(format!("settle fs {:3.0} kHz: input var {:11.0}  output var {:11.2}  S(10k) {:9.6}",
            fs / 1000.0, N0 * fs, N0 * fs * (1.0 - cc) / (1.0 + cc), sampled_s(1e4, fs)));
    }
    // ---- what breaks ----
    show(&mut out, "mistake: gain not squared at 10 kHz", N0 / (1.0f64 + 4.0).sqrt(), 6);
    show(&mut out, "mistake: S_Y over positive frequencies only", R0 / 2.0, 2);
    show(&mut out, "  its rms, uV", (R0 / 2.0).sqrt(), 2);
    let hum = |t_rec: f64| 2.0 * simpson(|t| (1.0 - t / t_rec) * HUM * HUM / 2.0 * (2.0 * PI * 50.0 * t).cos() * (2.0 * PI * 50.0 * t).cos(), 0.0, t_rec, 20000);
    for (t, lab) in [(0.1, "0.1"), (1.0, "1"), (10.0, "10")] {
        show(&mut out, &format!("hum: windowed value at 50 Hz, T = {} s", lab), HUM * HUM * t / 4.0, 2);
    }
    for (t, lab) in [(0.1, "0.1"), (1.0, "1")] { show(&mut out, &format!("  T = {} s by sums", lab), hum(t), 2); }
    // ---- try changing ----
    show(&mut out, "try: corner 2.5 kHz, S_Y(10 kHz)", N0 / (1.0 + 16.0), 6);
    show(&mut out, "try: corner 2.5 kHz, output rms, uV", (N0 * PI * 2500.0).sqrt(), 2);
    show(&mut out, "try: N0 = 400, output rms, uV", (400.0 * PI * XC).sqrt(), 2);
    let row = |f: &dyn Fn(usize) -> f64| (0..9).map(|m| format!("{:5.1}", f(m))).collect::<Vec<_>>().join(" ");
    out.push(format!("chart, frequency (kHz) {}", row(&|m| 2.5 * m as f64)));
    out.push(format!("chart, S_Y closed      {}", row(&|m| N0 * gain2(2500.0 * m as f64))));
    out.push(format!("chart, sampled filter  {}", row(&|m| sampled_s(2500.0 * m as f64, FS))));
    out.push(format!("chart, S_Y simulated   {}", row(&|m| mean[m])));
    println!("{}", out.join("\n"));

    assert!((transform_r(10000.0, 2e-3, 4000) - s10).abs() < 1e-6); // transform of R_Y meets N0 |h^|^2
    assert!((transform_r(5000.0, 2e-3, 4000) - 50.0).abs() < 1e-6);
    assert!((area + tail - R0).abs() < 1e-3); // variance = area under S_Y
    assert!((windowed(10000.0, 0.01) - s10).abs() < (windowed(10000.0, 0.001) - s10).abs() / 5.0); // the window settles
    assert!((0.1 * (windowed(10000.0, 0.1) - s10) - lead).abs() < 1e-8); // with the proof's 1/T gap
    for m in 0..9 {
        assert!((mean[m] - expect(2500.0 * m as f64)).abs() < 4.0 * se[m]); // simulation meets the formula
    }
    assert!((simvar - g(0)).abs() < 0.02 * g(0));
    for t in [0.1, 1.0] { assert!((hum(t) - HUM * HUM * t / 4.0).abs() < 1e-3); } // sums confirm the growth: no density
    println!("ALL CHECKS PASS");
}
