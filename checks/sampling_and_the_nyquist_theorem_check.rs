// Sampling and the Nyquist theorem -- the same check as sampling_and_the_nyquist_theorem_check.py.
// Standard library only, no crates.  A 15 kHz tone sampled 20,000 times a second returns
// as 5 kHz: by folding, by comparing samples, by a spectrum search, by the sinc sum.
// Then the filter before the converter, sized by formula and by its poles.
use std::f64::consts::PI;

fn rnd(x: f64) -> f64 { (x + 0.5).floor() }              // round half up, as in the Python
fn fold(f: f64, fs: f64) -> f64 { (f - fs * rnd(f / fs)).abs() }
fn signed(f: f64, fs: f64) -> f64 { f - fs * rnd(f / fs) }
fn clean(v: f64, d: i32) -> f64 { if v.abs() < 0.5 * 10f64.powi(-d) { 0.0 } else { v } }
fn row(label: &str, vals: &[f64], d: usize) {
    let s: Vec<String> = vals.iter().map(|v| format!("{:.*}", d, clean(*v, d as i32))).collect();
    println!("{} {}", label, s.join(" "));
}
fn small(v: f64) -> String { if v < 1e-9 { "below 1e-9".to_string() } else { format!("{:.3}", v) } }

fn atten_formula(ratio: f64, n: i32) -> f64 { 10.0 * (1.0 + ratio.powi(2 * n)).log10() }

fn atten_poles(ratio: f64, n: i32) -> f64 {              // loss in dB from distances to the n poles
    let mut gain = 1.0;
    for k in 1..=n {
        let ang = PI * (2 * k + n - 1) as f64 / (2 * n) as f64;
        gain /= (-ang.cos()).hypot(ratio - ang.sin());
    }
    -20.0 * f64::log10(gain)
}

fn order_formula(a: f64, ratio: f64) -> i32 {
    ((10f64.powf(a / 10.0) - 1.0).log10() / (2.0 * ratio.log10())).ceil() as i32
}

fn order_search(a: f64, ratio: f64) -> i32 {
    let mut n = 1;
    while atten_poles(ratio, n) < a { n += 1; }
    n
}

fn main() {
    let (fs, f, nn) = (20.0_f64, 15.0_f64, 400usize);
    println!("spacing T = {:.1} us; Nyquist frequency fs/2 = {:.1} kHz; Nyquist rate of the tone 2f = {:.1} kHz", 1000.0 / fs, fs / 2.0, 2.0 * f);
    let alias = fold(f, fs);
    println!("road 1, folding: |{:.0} - {:.0} x {}| = {:.2} kHz", f, fs, rnd(f / fs) as i64, alias);
    println!("angle turned per sample: 15 kHz {:.0} deg, the same point as {:.0}; 5 kHz {:.0} deg", 360.0 * f / fs, 360.0 * f / fs - 360.0, 360.0 * alias / fs);
    let x15: Vec<f64> = (0..nn).map(|n| (2.0 * PI * f * n as f64 / fs).cos()).collect();
    let x5: Vec<f64> = (0..nn).map(|n| (2.0 * PI * alias * n as f64 / fs).cos()).collect();
    let gap = x15.iter().zip(&x5).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let flip = (0..nn).map(|n| ((2.0 * PI * f * n as f64 / fs).sin() + (2.0 * PI * alias * n as f64 / fs).sin()).abs()).fold(0.0, f64::max);
    println!("road 2, {} samples: largest gap, 15 vs 5 kHz cosine, {}; sine 15 plus sine 5, {}", nn, small(gap), small(flip));
    row("first samples, 15 kHz cosine", &x15[..5], 2);
    let (mut best, mut peak) = (0.0_f64, -1.0_f64);
    for i in 0..201 {                                      // 0 to 10 kHz in 50 Hz steps
        let g = 0.05 * i as f64;
        let (mut re, mut im) = (0.0, 0.0);
        for (n, x) in x15.iter().enumerate() {
            re += x * (2.0 * PI * g * n as f64 / fs).cos();
            im += x * (2.0 * PI * g * n as f64 / fs).sin();
        }
        let amp = 2.0 * f64::hypot(re, im) / nn as f64;
        if amp > peak { best = g; peak = amp; }
    }
    println!("road 3, spectrum of the samples, 0 to 10 kHz: peak at {:.2} kHz, amplitude {:.3}", best, peak);
    let m = 50000i64;                                      // sinc terms each side of t = 0
    let mut rebuilt = Vec::new();
    for u in [0.25_f64, 0.75, 1.6] {
        let mut s = 0.0;
        for n in -m..=m {
            let sign = if n.rem_euclid(2) == 0 { 1.0 } else { -1.0 };
            s += sign * (2.0 * PI * f * n as f64 / fs).cos() / (PI * (u - n as f64));
        }
        s *= (PI * u).sin();
        let t = u / fs;
        let (c5, c15) = ((2.0 * PI * alias * t).cos(), (2.0 * PI * f * t).cos());
        rebuilt.push((s, c5, c15));
        println!("road 4, sinc sum at t = {:6.2} us: rebuilt {:.5}; 5 kHz {:.5}; 15 kHz {:.5}", 1000.0 * t, s, c5, c15);
    }
    let edge = (0..nn).map(|n| (2.0 * PI * 10.0 * n as f64 / fs).sin().abs()).fold(0.0, f64::max);
    println!("10 kHz sine sampled at exactly 20 kHz: largest sample {:.6}", edge);
    let fl: Vec<String> = [9.0, 11.0, 15.0, 19.0, 21.0, 25.0, 35.0].iter().map(|g| format!("{:.0} -> {:.0}", g, fold(*g, fs))).collect();
    println!("fold at 20 kHz: {}", fl.join(", "));

    // ---- the filter before the converter: keep 0-5 kHz, crush what folds onto it by 60 dB ----
    let (fp, a) = (5.0_f64, 60.0_f64);
    let stop = fs - fp;
    let (n7, n7s) = (order_formula(a, stop / fp), order_search(a, stop / fp));
    println!("filter: pass to {:.0} kHz, stop from fs - fp = {:.0} kHz, ratio {:.0}, {:.0} dB = height / {:.0}", fp, stop, stop / fp, a, 10f64.powf(a / 20.0));
    println!("  order by formula {} ({:.3} rounded up), by pole search {}; loss at {:.0} kHz: order 6 {:.2} dB, order 7 {:.2} dB", n7, (10f64.powf(a / 10.0) - 1.0).log10() / (2.0 * (stop / fp).log10()), n7s, stop, atten_poles(3.0, 6), atten_poles(3.0, 7));
    println!("  loss at the {:.0} kHz band edge {:.2} dB, amplitude {:.4}", fp, atten_poles(1.0, 7), 10f64.powf(-atten_poles(1.0, 7) / 20.0));
    println!("  15 kHz tone after the order-7 filter: amplitude {:.6}, still heard at {:.0} kHz", 10f64.powf(-atten_poles(3.0, 7) / 20.0), alias);
    println!("  sized at the Nyquist frequency instead, 60 dB at 10 kHz: order {}", order_formula(a, 10.0 / fp));

    // ---- the house example: a ten second guitar chord at 44.1 kHz ----
    let (fh, ph) = (44.1_f64, 20.0_f64);
    let ah = 20.0 * 2f64.powi(16).log10();                 // one step of a 16-bit converter
    println!("guitar: {} samples in 10 s; Nyquist {:.2} kHz; stop edge {:.1} kHz; {:.2} dB", (10.0 * fh * 1000.0).round() as i64, fh / 2.0, fh - ph, ah);
    println!("  top E string 329.63 Hz: harmonics below Nyquist {}; a 30 kHz pick click returns at {:.1} kHz", (fh / 2.0 / 0.32963).floor() as i64, fold(30.0, fh));
    let mut orders = Vec::new();
    for mm in [1.0_f64, 2.0, 4.0, 8.0] {
        let r = (mm * fh - ph) / ph;
        orders.push((order_formula(ah, r), order_search(ah, r)));
        let o = orders[orders.len() - 1];
        println!("  sampling {} x 44.1 = {:6.1} kHz: stop edge {:6.1} kHz, order {} (pole search {})", mm as i64, mm * fh, mm * fh - ph, o.0, o.1);
    }
    println!("phone: 8 kHz sampling, 3.4 kHz kept, stop edge {:.1} kHz; film: 22 turns/s at 24 frames/s looks like {:.0}", 8.0 - 3.4, signed(22.0, 24.0));
    println!("try: 25 kHz -> {:.0}; 19 kHz -> {:.0}; 15 kHz at 40 kHz -> {:.0}; 90 dB needs order {}; fs 40: Nyquist {:.0} kHz, stop edge {:.0} kHz, order {}", fold(25.0, fs), fold(19.0, fs), fold(15.0, 40.0), order_formula(90.0, 3.0), 40.0 / 2.0, 40.0 - fp, order_formula(a, (40.0 - fp) / fp));
    let tk: Vec<f64> = (0..17).map(|i| 2.5 * i as f64).collect();
    row("chart, true kHz", &tk, 1);
    row("chart, heard kHz", &tk.iter().map(|g| fold(*g, fs)).collect::<Vec<_>>(), 1);
    row("chart, time us", &(0..33).map(|i| 6.25 * i as f64).collect::<Vec<_>>(), 2);
    row("chart, 15 kHz wave", &(0..33).map(|i| (2.0 * PI * f * 6.25e-3 * i as f64).cos()).collect::<Vec<_>>(), 2);
    row("chart, 5 kHz wave", &(0..33).map(|i| (2.0 * PI * alias * 6.25e-3 * i as f64).cos()).collect::<Vec<_>>(), 2);

    assert!(alias == 5.0 && (best - alias).abs() < 1e-9 && (peak - 1.0).abs() < 1e-9, "spectrum search must find the folded tone");
    assert!(gap < 1e-9 && flip < 1e-9, "15 and 5 kHz must give the same samples");
    assert!(rebuilt.iter().all(|&(s, c5, c15)| (s - c5).abs() < 1e-4 && (s - c15).abs() > 0.1), "sinc rebuild must give 5 kHz");
    for r in [1.0, 2.0, 3.0, 7.82] {
        for n in 1..=60 { assert!((atten_poles(r, n) - atten_formula(r, n)).abs() < 1e-7); }
    }
    assert!(n7 == 7 && n7s == 7 && atten_poles(3.0, 6) < a && a <= atten_poles(3.0, 7), "order 7 is the smallest that reaches 60 dB");
    assert!(orders.iter().all(|o| o.0 == o.1) && orders.iter().map(|o| o.0).collect::<Vec<_>>() == vec![60, 10, 6, 4], "house orders by both roads");
    assert!(edge < 1e-9, "a sine at exactly fs/2 is sampled at its zeros");
    println!("ALL CHECKS PASS");
}
