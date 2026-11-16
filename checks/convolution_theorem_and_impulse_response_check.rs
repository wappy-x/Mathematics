// The convolution theorem and the hall's echo -- the same check as the Python, in Rust.
// Standard library only, no crates. A complex number is a small struct.
use std::f64::consts::PI;
const A: f64 = 0.5; // echo strength
const T: f64 = 0.05; // echo delay, s
const SIG: f64 = 1e-4; // clap width, s (standard deviation)
const LO: f64 = -0.025; // the recording window w: 1 from LO to HI seconds, 0 outside
const HI: f64 = 0.175;
const L: f64 = HI - LO; // window length 0.2 s
const MID: f64 = (LO + HI) / 2.0; // window centre 0.075 s

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
fn c(re: f64, im: f64) -> C { C { re, im } }
fn mul(p: C, q: C) -> C { c(p.re * q.re - p.im * q.im, p.re * q.im + p.im * q.re) }
fn sub(p: C, q: C) -> C { c(p.re - q.re, p.im - q.im) }
fn turn(x: f64) -> C { c(x.cos(), x.sin()) } // e^(ix)
fn size(p: C) -> f64 { (p.re * p.re + p.im * p.im).sqrt() }
fn hhat(xi: f64, a: f64, d: f64) -> C { // frequency response, closed form 1/(1 - a e^(-2 pi i xi d))
    let (re, im) = (1.0 - a * (2.0 * PI * xi * d).cos(), a * (2.0 * PI * xi * d).sin());
    let m = re * re + im * im;
    c(re / m, -im / m)
}
fn chat(xi: f64, s: f64) -> f64 { (-2.0 * PI * PI * s * s * xi * xi).exp() } // transform of the clap bump
fn echo_sum(xi: f64, n: usize, a: f64) -> C { // first n+1 arrivals: sum of a^k e^(-2 pi i xi k T)
    let mut z = c(0.0, 0.0);
    for k in 0..=n {
        let ak = a.powi(k as i32);
        z.re += ak * (2.0 * PI * xi * k as f64 * T).cos();
        z.im -= ak * (2.0 * PI * xi * k as f64 * T).sin();
    }
    z
}
fn show(w: C) -> String { // size and turn, a turn under 0.005 deg printed as 0
    let ang = w.im.atan2(w.re).to_degrees();
    format!("{:.6} at {:+.2} deg", size(w), if ang.abs() >= 0.005 { ang } else { 0.0 })
}

// Road 1: play a steady tone in the hall, sample by sample, and measure what reaches the seat.
fn tone_gain(xi: f64) -> C {
    let (fs, echoes) = (8820usize, 30usize);
    let d = (T * fs as f64).round() as usize; // 441 samples between echoes; measure over 1 s
    let (mut sx, mut sy) = (c(0.0, 0.0), c(0.0, 0.0));
    for n in echoes * d..echoes * d + fs {
        let x = (2.0 * PI * xi * n as f64 / fs as f64).cos();
        let mut y = 0.0;
        for k in 0..=echoes {
            y += A.powi(k as i32) * (2.0 * PI * xi * (n - k * d) as f64 / fs as f64).cos();
        }
        let p = turn(-2.0 * PI * xi * n as f64 / fs as f64);
        sx = c(sx.re + x * p.re, sx.im + x * p.im);
        sy = c(sy.re + y * p.re, sy.im + y * p.im);
    }
    let m = sx.re * sx.re + sx.im * sx.im; // complex ratio of output to input at xi
    c((sy.re * sx.re + sy.im * sx.im) / m, (sy.im * sx.re - sy.re * sx.im) / m)
}

// Road 2: the clap recording r(t) = sum a^k c(t - kT), transformed by its defining integral (Simpson).
fn rhat_integral(xi: f64) -> C {
    let (s, echoes, n) = (SIG, 40usize, 200usize);
    let mut z = c(0.0, 0.0);
    for k in 0..=echoes {
        let (a0, h) = (k as f64 * T - 8.0 * s, 16.0 * s / n as f64);
        for j in 0..=n {
            let t = a0 + j as f64 * h;
            let wt = (if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 }) * h / 3.0;
            let tk = t - k as f64 * T;
            let v = A.powi(k as i32) * (-tk * tk / (2.0 * s * s)).exp() / (s * (2.0 * PI).sqrt());
            z.re += wt * v * (2.0 * PI * xi * t).cos();
            z.im -= wt * v * (2.0 * PI * xi * t).sin();
        }
    }
    z
}

// Road 3: the reverse direction. The cut recording r.w has transform (rhat * what)(xi), a blend over eta.
fn whatf(nu: f64) -> C { // transform of the window: e^(-2 pi i nu MID) sin(pi nu L)/(pi nu)
    let amp = if nu.abs() < 1e-12 { L } else { (PI * nu * L).sin() / (PI * nu) };
    let p = turn(-2.0 * PI * nu * MID);
    c(amp * p.re, amp * p.im)
}
fn blend(f: fn(f64) -> C, g: fn(f64) -> C, xi: f64) -> C { // integral of F(eta) G(xi - eta), trapezoid
    let (m, step) = (20000.0, 0.5);
    let last = (2.0 * m / step) as usize;
    let mut z = c(0.0, 0.0);
    for j in 0..=last {
        let eta = -m + j as f64 * step;
        let q = mul(f(eta), g(xi - eta));
        let wt = if j == 0 || j == last { step / 2.0 } else { step };
        z.re += wt * q.re;
        z.im += wt * q.im;
    }
    z
}
fn rhat(eta: f64) -> C { mul(c(chat(eta, SIG), 0.0), hhat(eta, A, T)) }

fn main() {
    println!("1 frequency response of the hall (walls {:.3} m apart, peaks every {:.0} Hz), closed form against a played tone", 343.0 * T / 2.0, 1.0 / T);
    let tones = [440.0, 430.0, 435.0];
    let gains: Vec<C> = tones.iter().map(|&xi| tone_gain(xi)).collect();
    for (i, &xi) in tones.iter().enumerate() {
        println!("  {} Hz  formula {}   tone {}", xi, show(hhat(xi, A, T)), show(gains[i]));
    }
    let cyc: Vec<String> = tones.iter().map(|&xi| format!("{:.2}", xi * T)).collect();
    println!("  cycles per echo delay: {}", cyc.join(" "));
    println!("  h-hat(435) = {:.6} + {:.6}i", hhat(435.0, A, T).re, hhat(435.0, A, T).im);
    println!("  decay to a thousandth of the clap's size: {:.4} s", T * 1000f64.ln() / (1.0 / A).ln());
    println!("  echo build-up, arrivals 0..5:");
    for xi in [440.0, 430.0] {
        let v: Vec<String> = (0..6).map(|n| format!("{:.4}", echo_sum(xi, n, A).re)).collect();
        println!("   {} Hz {}", xi, v.join(" "));
    }
    println!("2 clap recording at 440 Hz: c-hat times h-hat against the defining integral");
    let (p, q) = (rhat(440.0), rhat_integral(440.0));
    println!("  product {}   integral {}", show(p), show(q));
    println!("  c-hat(440) = exp(-{:.6}) = {:.6}", 2.0 * PI * PI * SIG * SIG * 440.0 * 440.0, chat(440.0, SIG));
    println!("  settling as the clap shortens (2 c-hat(440)):");
    for s in [1e-3, 3e-4, 1e-4, 3e-5] {
        println!("   width {:.2} ms  {:.6}", s * 1000.0, 2.0 * chat(440.0, s));
    }
    println!("3 cut to 0.2 s (window spectrum first zero {:.1} Hz, blend over {} frequencies)", 1.0 / L, (40000.0 / 0.5) as usize + 1);
    println!("  tail beyond 20000 Hz: clap factor there {:.1e}, tail bound {:.1e}", chat(20000.0, SIG), 0.8 * chat(20000.0, SIG) / (4.0 * PI * PI * SIG * SIG * 20000.0));
    let mut cut = Vec::new();
    for xi in [440.0, 430.0] {
        let closed = mul(c(chat(xi, SIG), 0.0), echo_sum(xi, 3, A));
        let b = blend(rhat, whatf, xi);
        println!("  {} Hz  closed {}   blend {}   full {:.6}", xi, show(closed), show(b), size(rhat(xi)));
        cut.push((closed, b));
    }
    println!("4 window times itself is itself (L2 only), tails cut beyond 20000 Hz");
    let bound = 2.0 / (PI * PI * 20000.0);
    let mut gg = Vec::new();
    for xi in [0.0, 2.5] {
        let b = blend(whatf, whatf, xi);
        println!("  {:.1} Hz  blend {:.6}   what {:.6}   tail bound {:.7}", xi, size(b), size(whatf(xi)), bound);
        gg.push((b, whatf(xi)));
    }
    println!("5 what breaks");
    println!("  echo sizes added, delays ignored, 430 Hz   {:.6}", echo_sum(0.0, 40, A).re);
    println!("  omega form, reverse without 1/2pi, 440 Hz  {:.6}", 2.0 * PI * size(cut[0].1));
    println!("  walls keep everything, 440 Hz after 1 s    {:.6}", size(echo_sum(440.0, 20, 1.0)));
    println!("  same walls, a = 0.5, after 1 s             {:.6}", size(echo_sum(440.0, 20, A)));
    println!("  clap 1 ms wide taken as the kick, 440 Hz   {:.6}", 2.0 * chat(440.0, 1e-3));
    println!("6 try changing");
    println!("  a = 0.8: 440 Hz {:.6}  430 Hz {:.6}", size(hhat(440.0, 0.8, T)), size(hhat(430.0, 0.8, T)));
    println!("  T = 0.1 s (walls {:.3} m apart): 430 Hz {:.6}", 343.0 * 0.1 / 2.0, size(hhat(430.0, A, 0.1)));
    println!("  window to 0.375 s (8 arrivals), 440 Hz {:.6}", size(echo_sum(440.0, 7, A)));
    let xs: Vec<f64> = (0..33).map(|j| 400.0 + 2.5 * j as f64).collect();
    let hall: Vec<String> = xs.iter().map(|&x| format!("{:.3}", size(hhat(x, A, T)))).collect();
    let cutc: Vec<String> = xs.iter().map(|&x| format!("{:.3}", size(echo_sum(x, 3, A)))).collect();
    println!("chart, hall {}", hall.join(" "));
    println!("chart, cut  {}", cutc.join(" "));

    assert!((size(hhat(440.0, A, T)) - echo_sum(440.0, 60, A).re).abs() < 1e-12, "comb peak");
    assert!((size(hhat(430.0, A, T)) - echo_sum(430.0, 60, A).re).abs() < 1e-12, "comb dip");
    for (i, &xi) in tones.iter().enumerate() {
        assert!(size(sub(gains[i], hhat(xi, A, T))) < 1e-8, "road 1");
    }
    assert!(size(sub(p, q)) < 1e-9, "forward theorem on the clap recording");
    for (closed, b) in &cut { assert!(size(sub(*closed, *b)) < 1e-6, "reverse theorem, cut recording"); }
    for (b, w) in &gg { assert!(size(sub(*b, *w)) < bound, "reverse theorem in L2"); }
    assert!(size(echo_sum(440.0, 20, 1.0)) > 20.0, "no absorption: no settling");
    println!("ALL CHECKS PASS");
}
