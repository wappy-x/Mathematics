// Sampling and the Dirac comb -- the check behind the card.  Standard library only.
// Digital audio at 44,100 samples a second, and a 20-microsecond click as the probe.
// Roads: a finite comb's DFT summed out against its closed form; Poisson summation,
// samples side against spectrum side; the sampled spectrum summed directly against
// its copies; the click's transform by Simpson's rule against its closed form.
use std::f64::consts::PI;

const FS: f64 = 44100.0; // samples a second
const DT: f64 = 1.0 / FS; // spacing between samples, seconds
const SIG: f64 = 20e-6; // the click's width, seconds (illustrative)
const B: f64 = 20000.0; // top of hearing, Hz

fn click(t: f64, s: f64) -> f64 {
    (-t * t / (2.0 * s * s)).exp()
}

fn click_hat(w: f64, s: f64) -> f64 {
    s * (2.0 * PI).sqrt() * (-s * s * w * w / 2.0).exp()
}

fn simpson_hat(w: f64, s: f64) -> f64 {
    let m = 4000;
    let (a, h) = (-12.0 * s, 24.0 * s / m as f64);
    let mut tot = 0.0;
    for j in 0..=m {
        let c = if j == 0 || j == m { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        let t = a + j as f64 * h;
        tot += c * click(t, s) * (w * t).cos();
    }
    tot * h / 3.0
}

fn sampled(f: f64, dt: f64, s: f64) -> f64 {
    let w = 2.0 * PI * f;
    dt * (-60..=60).map(|n| click(n as f64 * dt, s) * (w * n as f64 * dt).cos()).sum::<f64>()
}

fn copies(f: f64, dt: f64, s: f64) -> f64 {
    let (w, ws) = (2.0 * PI * f, 2.0 * PI / dt);
    (-6..=6).map(|k| click_hat(w - k as f64 * ws, s)).sum()
}

fn alias(f: f64, fs: f64) -> f64 {
    (f - (f / fs).round() * fs).abs()
}

fn dft(v: &[f64]) -> Vec<(f64, f64)> {
    let n = v.len();
    (0..n)
        .map(|k| {
            let ang = |j: usize| 2.0 * PI * (j * k) as f64 / n as f64;
            ((0..n).map(|j| v[j] * ang(j).cos()).sum(), -(0..n).map(|j| v[j] * ang(j).sin()).sum::<f64>())
        })
        .collect()
}

fn ints(z: &[(f64, f64)]) -> String {
    z.iter().map(|c| format!("{}", c.0.round() as i64)).collect::<Vec<_>>().join(" ")
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    let ws = 2.0 * PI / DT;
    println!("== audio at 44,100 samples a second ==");
    println!("spacing dt = {:.6} microseconds", DT * 1e6);
    println!("copy spacing 2 pi / dt = {:.4} rad/s = {:.0} Hz", ws, ws / (2.0 * PI));
    println!("Nyquist frequency {:.0} Hz; rate needed for a {:.0} Hz band {:.0} Hz", FS / 2.0, B, 2.0 * B);
    println!("first copy of the band starts at {:.0} Hz; guard gap {:.0} Hz", FS - B, FS - 2.0 * B);
    let a30 = alias(30000.0, FS);
    let tone = (0..50)
        .map(|n| ((2.0 * PI * 30000.0 * n as f64 * DT).cos() - (2.0 * PI * a30 * n as f64 * DT).cos()).abs())
        .fold(0.0, f64::max);
    println!("30000 Hz tone aliases to {:.0} Hz; largest sample difference {:.9}", a30, tone);
    assert!(a30 == 14100.0 && tone < 1e-9);

    println!("== finite rehearsal: a 12-point grid ==");
    for sp in [3usize, 4] {
        let c = dft(&(0..12).map(|j| if j % sp == 0 { 1.0 } else { 0.0 }).collect::<Vec<_>>());
        let l = 12 / sp;
        println!("DFT of comb spacing {}: {}", sp, ints(&c));
        for k in 0..12 {
            let closed = if k % l == 0 { l as f64 } else { 0.0 };
            assert!((c[k].0 - closed).abs() < 1e-9 && c[k].1.abs() < 1e-9);
        }
    }
    let tone12: Vec<f64> = (0..12).map(|j| (2.0 * PI * 5.0 * j as f64 / 12.0).cos()).collect();
    let x = dft(&tone12);
    let y = dft(&(0..12).map(|j| if j % 3 == 0 { tone12[j] } else { 0.0 }).collect::<Vec<_>>());
    let yc: Vec<(f64, f64)> =
        (0..12).map(|k| ((0..3).map(|r| x[(k + 12 - 4 * r) % 12].0).sum::<f64>() / 3.0, 0.0)).collect();
    println!("tone at bin 5, every 3rd point kept, DFT direct: {}", ints(&y));
    println!("same from copies (1/3) sum X[k - 4r]:          {}", ints(&yc));
    println!("kept points heard at bin 5 mod 4 = {}", 5 % 4);
    for k in 0..12 {
        assert!((y[k].0 - yc[k].0).abs() < 1e-9);
    }

    println!("== the comb's transform has no values ==");
    let ns = [1i64, 2, 11, 100];
    for f in [0.0, FS / 2.0] {
        let d: Vec<f64> =
            ns.iter().map(|&nn| (-nn..=nn).map(|n| (2.0 * PI * f * n as f64 * DT).cos()).sum()).collect();
        println!("partial sum at {:.0} Hz, N = 1 2 11 100: {}", f, join(&d, 3));
        for i in 0..4 {
            let want = if f == 0.0 { (2 * ns[i] + 1) as f64 } else if ns[i] % 2 == 1 { -1.0 } else { 1.0 };
            assert!((d[i] - want).abs() < 1e-9);
        }
    }

    println!("== tested on the 20-microsecond click: Poisson summation ==");
    let left: Vec<f64> = (0..8i64).map(|nn| (-nn..=nn).map(|n| click(n as f64 * DT, SIG)).sum()).collect();
    let right: Vec<f64> =
        [0i64, 1].iter().map(|&kk| (-kk..=kk).map(|k| click_hat(k as f64 * ws, SIG)).sum::<f64>() / DT).collect();
    println!("samples side, N = 0..7: {}", join(&left, 9));
    println!("spectrum side, K = 0 and 1: {:.12} {:.12}", right[0], right[1]);
    println!("copy weight xhat(ws) / xhat(0) = {:.12}", click_hat(ws, SIG) / click_hat(0.0, SIG));
    assert!((left[7] - right[1]).abs() < 1e-12);
    assert!((left[2] - right[1]).abs() > 1e-3 && (right[0] - right[1]).abs() > 1e-7);

    println!("== sampled spectrum of the click, microseconds ==");
    for f in [0.0, 10000.0, FS / 2.0] {
        let (tr, sa) = (click_hat(2.0 * PI * f, SIG), sampled(f, DT, SIG));
        let (co, si) = (copies(f, DT, SIG), simpson_hat(2.0 * PI * f, SIG));
        println!(
            "f = {:.0} Hz: true {:.6} Simpson {:.6} sampled {:.6} copies {:.6} ratio {:.6}",
            f, tr * 1e6, si * 1e6, sa * 1e6, co * 1e6, sa / tr
        );
        assert!((tr - si).abs() < 1e-15 && (sa - co).abs() < 1e-15);
    }
    assert!((sampled(FS / 2.0, DT, SIG) / click_hat(PI * FS, SIG) - 2.0).abs() < 1e-6);

    println!("== what breaks ==");
    let d8 = 1.0 / 8000.0;
    let s8 = sampled(0.0, d8, SIG);
    println!("click sampled 8000 a second: sampled at 0 Hz {:.6} vs true {:.6}", s8 * 1e6, click_hat(0.0, SIG) * 1e6);
    println!("omega weight 2 pi / dt with hertz copies: sum reads {:.6} not {:.6}", 2.0 * PI * left[7], left[7]);
    println!("20000 Hz band at 32000 a second: copy starts {:.0} Hz, overlap {:.0} Hz", 32000.0 - B, 2.0 * B - 32000.0);
    assert!((s8 - copies(0.0, d8, SIG)).abs() < 1e-12 && s8 > 2.0 * click_hat(0.0, SIG));

    println!("== try changing ==");
    println!("40000 Hz tone at 44100: heard at {:.0} Hz", alias(40000.0, FS));
    println!("at 48000: copy starts {:.0} Hz; 30000 Hz tone heard at {:.0} Hz", 48000.0 - B, alias(30000.0, 48000.0));
    println!("10-microsecond click: copy weight {:.12}", click_hat(ws, 10e-6) / click_hat(0.0, 10e-6));

    let fk: Vec<f64> = (0..21).map(|i| 4.41 * i as f64).collect();
    println!("chart, f kHz: {}", join(&fk, 2));
    println!("chart, true: {}", join(&fk.iter().map(|v| click_hat(2.0 * PI * v * 1e3, SIG) * 1e6).collect::<Vec<_>>(), 2));
    println!("chart, sampled: {}", join(&fk.iter().map(|v| sampled(v * 1e3, DT, SIG) * 1e6).collect::<Vec<_>>(), 2));
    println!(
        "figure, sample heights n = 0..3: {}; copies centred at 0, {:.1}, {:.1} kHz",
        join(&(0..4).map(|n| click(n as f64 * DT, SIG)).collect::<Vec<_>>(), 4),
        FS / 1e3,
        2.0 * FS / 1e3
    );
    println!("ALL CHECKS PASS");
}
