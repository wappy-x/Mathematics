// Mihlin-Hormander multiplier theorem -- the same check as the Python file, in Rust.
// Standard library only, no crates.  Units: frequency xi in kHz, time x in ms.
use std::f64::consts::PI;

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn eq(xi: f64) -> f64 { 1.0 + 0.5 * (2.0 * PI * xi.abs().log2()).cos() }   // one wobble per octave
fn echo(xi: f64) -> f64 { 1.0 + 0.5 * (PI * xi).cos() }                   // echoes at -0.5 and +0.5 ms

fn row<F: Fn(i32) -> String>(label: &str, f: F) {
    let v: Vec<String> = (-16..=16).map(|k| f(k)).collect();
    println!("{}{}", label, v.join(" "));
}

fn scan_1d<F: Fn(f64) -> f64>(m: F, u0: f64, u1: f64, n: usize) -> (f64, f64) {
    let h = 1e-5_f64;
    let (mut b0, mut b1) = (0.0_f64, 0.0_f64);
    for k in 0..=n {
        let xi = 2f64.powf(u0 + (u1 - u0) * k as f64 / n as f64);
        b0 = b0.max(m(xi).abs());
        b1 = b1.max((m(xi * h.exp()) - m(xi * (-h).exp())).abs() / (2.0 * h));   // xi m'
    }
    (b0, b1)
}

fn riesz(a: f64, b: f64) -> f64 { a * a / (a * a + b * b) }               // xi1^2/|xi|^2 = -R1^2

fn partials(a: f64, b: f64, h: f64) -> [f64; 6] {
    let f = riesz;
    let d1 = (f(a + h, b) - f(a - h, b)) / (2.0 * h);
    let d2 = (f(a, b + h) - f(a, b - h)) / (2.0 * h);
    let d11 = (f(a + h, b) - 2.0 * f(a, b) + f(a - h, b)) / (h * h);
    let d22 = (f(a, b + h) - 2.0 * f(a, b) + f(a, b - h)) / (h * h);
    let d12 = (f(a + h, b + h) - f(a + h, b - h) - f(a - h, b + h) + f(a - h, b - h)) / (4.0 * h * h);
    [f(a, b).abs(), d1.abs(), d2.abs(), d11.abs(), d22.abs(), d12.abs()]
}

fn ff(xi: f64) -> f64 { let u = xi.log2(); eq(xi) * (PI * u / 2.0).cos().powi(2) }   // m times psi
fn dff(xi: f64) -> f64 {
    let u = xi.log2();
    let du = -PI * (2.0 * PI * u).sin() * (PI * u / 2.0).cos().powi(2) - eq(xi) * (PI / 2.0) * (PI * u).sin();
    du / (xi * 2f64.ln())
}
fn k0(x: f64) -> f64 { 2.0 * simpson(|s| ff(s) * (2.0 * PI * x * s).cos(), 0.5, 2.0, 600) }

fn tg_abs(t: f64, a: f64) -> f64 {                                         // s = 1 ms
    let re = simpson(|x| (-PI * x * x).exp() * (PI * a * x * x).cos() * (2.0 * PI * x * t).cos(), 0.0, 4.0, 4000);
    let im = simpson(|x| (-PI * x * x).exp() * (PI * a * x * x).sin() * (2.0 * PI * x * t).cos(), 0.0, 4.0, 4000);
    2.0 * (re * re + im * im).sqrt()
}
fn ratio_closed(a: f64) -> f64 { (1.0 + a * a).sqrt().powf(0.25) }

fn echo_peak(x: f64) -> f64 {        // top of the last hump of (pi/2) xi |sin(pi xi)| below X, by Newton
    let mut xi = x - 0.5;
    for _ in 0..20 { xi -= ((PI * xi).sin() + PI * xi * (PI * xi).cos()) / (2.0 * PI * (PI * xi).cos() - PI * PI * xi * (PI * xi).sin()); }
    PI / 2.0 * xi * (PI * xi).sin().abs()
}

fn main() {
    let ln2 = 2f64.ln();
    let g = 2.0 * PI / ln2;
    // ---- the gain curve and the house example ----
    row("chart, frequency in Hz   ", |k| format!("{:6.0}", 1000.0 * 2f64.powf(k as f64 / 8.0)));
    row("chart, equaliser gain    ", |k| format!("{:6.3}", eq(2f64.powf(k as f64 / 8.0))));
    row("chart, echo gain         ", |k| format!("{:6.3}", echo(2f64.powf(k as f64 / 8.0))));
    let c: Vec<String> = (-5..5).map(|k| format!("{:.3}", eq(2f64.powi(k)))).collect();
    println!("gain at the ten band centres {}", c.join(" "));
    println!("gain halfway, at 707 Hz      {:.6}", eq(2f64.powf(-0.5)));
    println!("in decibels: peak {:.6} dB, dip {:.6} dB", 20.0 * 1.5f64.log10(), 20.0 * 0.5f64.log10());

    // ---- 1. Mihlin constants ----
    let (e0, e1) = scan_1d(eq, -5.0, 5.0, 10240);
    println!("equaliser sup|m|            closed 1.500000   scan {:.6}", e0);
    println!("equaliser sup|xi m'|        closed {:.6}   scan {:.6}", PI / ln2, e1);
    println!("equaliser Mihlin constant A {:.6}", 1.5f64.max(PI / ln2));
    let mut echo_scan = vec![];
    for x in [4.0_f64, 8.0, 16.0] {
        let v = scan_1d(echo, -5.0, x.log2(), 4096 * x as usize).1;
        let pk = echo_peak(x);
        println!("echo sup|xi m'| up to {:>2} kHz {:10.6}   scan {:.6}   (pi/2)(X - 1/2) = {:.6}", x, pk, v, PI / 2.0 * (x - 0.5));
        echo_scan.push((x, v, pk));
    }
    let closed2 = [1.0, 4.0 / (3.0 * 3f64.sqrt()), 4.0 / (3.0 * 3f64.sqrt()), 2.0, 2.0, 1.0];
    let mut scans = [[0.0_f64; 6]; 2];
    for (ri, r) in [1.0_f64, 7.0].iter().enumerate() {
        for k in 0..2880 {
            let th = PI * k as f64 / 1440.0;
            let p = partials(r * th.cos(), r * th.sin(), 1e-4 * r);
            let w = [1.0, *r, *r, r * r, r * r, r * r];
            for i in 0..6 { scans[ri][i] = scans[ri][i].max(p[i] * w[i]); }
        }
    }
    let names = ["|m|", "|xi| |d1 m|", "|xi| |d2 m|", "|xi|^2 |d11 m|", "|xi|^2 |d22 m|", "|xi|^2 |d12 m|"];
    for i in 0..6 {
        println!("Riesz {:<15} closed {:.6}  scan r=1 {:.6}  r=7 {:.6}", names[i], closed2[i], scans[0][i], scans[1][i]);
    }
    println!("Riesz Mihlin constant A     {:.6}; kernel size constant 1/(2 pi) = {:.6}", 2.0, 1.0 / (2.0 * PI));

    // ---- 2. the proof on the equaliser: one octave piece ----
    let n = 4000;
    let i2 = 2.0 * simpson(|s| dff(s).powi(2), 0.5, 2.0, n) / (4.0 * PI * PI);
    let j0 = 2.0 * simpson(|s| 4.0 * PI * PI * s * s * ff(s).powi(2), 0.5, 2.0, n);
    let j2 = 2.0 * simpson(|s| (ff(s) + s * dff(s)).powi(2), 0.5, 2.0, n);
    let d1 = (2.0 * j0).sqrt() + (2.0 * j2).sqrt();
    let lp_sum = |y: f64| -> f64 {
        (-60..=60).map(|j| { let r = 2f64.powi(j) * y; (r * d1).min(2.0 * (2.0 * i2 / r).sqrt()) }).sum()
    };
    let b_grid = (0..=256).map(|k| lp_sum(1.0 + k as f64 / 256.0)).fold(0.0_f64, f64::max);
    let r_sw = (2.0 * (2.0 * i2).sqrt() / d1).powf(2.0 / 3.0);      // the piece whose two bounds are equal
    let b_lp = (3.0 + 2f64.sqrt()) * d1 * r_sw;                     // both lists are geometric series from there
    let y_sw = r_sw * 2f64.powf(-r_sw.log2().floor());              // that shift, moved into [1, 2) ms
    println!("piece: int x^2 K0^2 from the frequency side  {:.6}", i2);
    let fj: f64 = [0.5 + 1e-6, 2.0 - 1e-6].iter().map(|&s| (dff(s + 1e-6) - dff(s - 1e-6)).abs() / 2e-6).sum();
    let g3: Vec<f64> = (0..=30000).map(|k| 0.5 + 1e-5 + (1.5 - 2e-5) * k as f64 / 30000.0)
        .map(|s| (dff(s + 1e-5) - 2.0 * dff(s) + dff(s - 1e-5)) / 1e-10).collect();
    let v3 = g3[0].abs() + g3[30000].abs() + g3.windows(2).map(|w| (w[0] - w[1]).abs()).sum::<f64>();   // total change of F'''
    let xmax = 30.0;
    let i2t = 2.0 * simpson(|x| x * x * k0(x).powi(2), 0.0, xmax, 3000);
    let (a3, a4) = (2.0 * fj / (2.0 * PI).powi(3), 2.0 * v3 / (2.0 * PI).powi(4));   // |K0(x)| <= a3/|x|^3 + a4/|x|^4
    let tail = 2.0 * (a3 * a3 / (3.0 * xmax.powi(3)) + a3 * a4 / (2.0 * xmax.powi(4)) + a4 * a4 / (5.0 * xmax.powi(5)));
    println!("piece: int x^2 K0^2 from the kernel, |x| < 30 ms  {:.6}  (tail at most {:.6})", i2t, tail);
    println!("piece: int K0'^2 {:.6}   int x^2 K0'^2 {:.6}   so int |K0'| <= {:.6}", j0, j2, d1);
    println!("Hormander constant B, octave-piece bound      {:.6}  (largest at the shift {:.6} ms)", b_lp, y_sw);
    println!("  the same by direct sum at that shift        {:.6};  on a 257-shift grid {:.6}", lp_sum(y_sw), b_grid);

    // ---- 3. the exact kernel |x|^(-1-iG) / C ----
    let cabs = (2.0 * PI / (g * (PI * g / 2.0).tanh())).sqrt();
    let cpow = |z: f64| ((g * z.ln()).cos() / z, -(g * z.ln()).sin() / z);
    let dabs = |p: (f64, f64), q: (f64, f64)| ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt();
    let ih = simpson(|u| { let x = u.exp(); x * (dabs(cpow(x - 1.0), cpow(x)) + dabs(cpow(x + 1.0), cpow(x))) },
                     2f64.ln(), 1e6f64.ln(), 40000);
    let tail_h = 2.0 * (1.0 + g * g).sqrt() / (1e6 - 1.0);
    println!("|C| = {:.6}  (sqrt(ln 2) = {:.6});  size: |K(x)| <= {:.6} / |x|", cabs, ln2.sqrt(), 0.5 / cabs);
    let b_ex = 0.5 * (ih + tail_h) / cabs;                          // the integral to 10^6 ms, plus its tail
    println!("Hormander constant B, exact-kernel bound      {:.6}  (tail beyond 10^6 ms included: {:.6})", b_ex, 0.5 * tail_h / cabs);

    // ---- 4. what breaks: a dispersion filter exp(-i pi a xi^2) ----
    let q = 4.0 / 3.0;
    let out = (2.0 * simpson(|t| tg_abs(t, 10.0).powf(q), 0.0, 40.0, 400)).powf(1.0 / q);
    let inn = (2.0 * simpson(|t| (-PI * t * t).exp().powf(q), 0.0, 10.0, 400)).powf(1.0 / q);
    for a in [10.0_f64, 100.0, 1000.0] {
        println!("dispersion a = {:6.0} ms^2: L^(4/3) ratio {:.6}, L^4 ratio {:.6}", a, ratio_closed(a), 1.0 / ratio_closed(a));
    }
    println!("dispersion a = 10 by numerical transform: L^(4/3) ratio {:.6}", out / inn);
    println!("brick wall: ||T||_4 <= ||H||_4 = cot(pi/8) = {:.6}", (PI / 8.0).cos() / (PI / 8.0).sin());
    println!("try: 2 wobbles per octave A = {:.6};  depth 0.1: sup|xi m'| = {:.6}, A = 1.100000", 2.0 * PI / ln2, 0.1 * g);

    assert!((e1 - PI / ln2).abs() < 1e-6, "scan must find the closed-form derivative bound");
    assert!((0..2).all(|r| (0..6).all(|i| (scans[r][i] - closed2[i]).abs() < 1e-5)), "Riesz constants");
    assert!(echo_scan.iter().all(|&(x, _, pk)| PI / 2.0 * (x - 0.5) < pk && pk < PI / 2.0 * x), "echo grows like pi X / 2");
    assert!(echo_scan.iter().all(|&(_, v, pk)| 0.0 <= pk - v && pk - v < 1e-4), "echo: the scan sits just below the Newton peak");
    assert!(0.0 < i2 - i2t && i2 - i2t < tail, "Plancherel on the piece: the kernel side falls short by less than the tail");
    assert!((out / inn - ratio_closed(10.0)).abs() < 1e-4, "dispersion ratio: closed form vs numerical");
    assert!((lp_sum(y_sw) - b_lp).abs() < 1e-6, "octave bound: geometric series against the direct sum");
    assert!(0.0 <= b_lp - b_grid && b_lp - b_grid < 1e-3, "octave bound: no shift on the grid beats the switch");
    assert!((cabs - ln2.sqrt()).abs() < 1e-9, "|C|: the coth formula is sqrt(ln 2) to 1e-12");
    assert!(b_ex < b_lp, "the exact kernel must sit inside the proof's bound");
    println!("ALL CHECKS PASS");
}
