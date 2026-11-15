// Plancherel -- the check behind the card.  Rust std only; the DFT, Simpson's
// rule and the sine integral Si are written out here.  The signal is a radar
// pulse: 1 V RMS for |t| < 1 microsecond into 1 ohm, so energies are in uJ.  Its
// transform is F(w) = 2 sin(w)/w, with w in radians per microsecond.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn conj(self) -> C { C { re: self.re, im: -self.im } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
}
fn cis(a: f64) -> C { C { re: a.cos(), im: -a.sin() } }

fn simpson<G: Fn(f64) -> f64>(f: G, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h); }
    (f(a) + f(b) + s) * h / 3.0
}
fn sinc(u: f64) -> f64 { if u == 0.0 { 1.0 } else { u.sin() / u } }
fn si(x: f64) -> f64 { simpson(sinc, 0.0, x, 2 * 50usize.max((x.abs() * 50.0) as usize)) }
fn ff(w: f64, a: f64) -> f64 { 2.0 * a * sinc(a * w) }
fn dft(x: &[f64]) -> Vec<C> {
    let n = x.len();
    (0..n).map(|k| {
        let mut s = C { re: 0.0, im: 0.0 };
        for j in 0..n { s = s.add(C { re: x[j], im: 0.0 }.mul(cis(2.0 * PI * k as f64 * j as f64 / n as f64))); }
        s
    }).collect()
}
fn inside(w: f64, a: f64) -> f64 {
    2.0 * simpson(|v| ff(v, a).powi(2), 0.0, w, 2 * 50usize.max((w * 50.0) as usize)) / (2.0 * PI)
}
fn tail(w: f64) -> f64 { 4.0 / PI * (w.sin().powi(2) / w + PI / 2.0 - si(2.0 * w)) }
fn fw(t: f64, w: f64) -> f64 { (si(w * (1.0 + t)) + si(w * (1.0 - t))) / PI }

fn main() {
    // ---- finite rehearsal: the DFT divided by sqrt(N) is a rigid rotation ----
    let n = 8;
    let u: Vec<Vec<C>> = (0..n).map(|k| (0..n).map(|j| {
        let c = cis(2.0 * PI * k as f64 * j as f64 / n as f64);
        C { re: c.re / (n as f64).sqrt(), im: c.im / (n as f64).sqrt() }
    }).collect()).collect();
    let (mut e1, mut e2) = (0.0f64, 0.0f64);
    for k in 0..n { for m in 0..n {
        let (mut a, mut b) = (C { re: 0.0, im: 0.0 }, C { re: 0.0, im: 0.0 });
        for j in 0..n { a = a.add(u[j][k].conj().mul(u[j][m])); b = b.add(u[k][j].mul(u[j][m])); }
        e1 = e1.max(C { re: a.re - if k == m { 1.0 } else { 0.0 }, im: a.im }.abs());
        e2 = e2.max(C { re: b.re - if (k + m) % n == 0 { 1.0 } else { 0.0 }, im: b.im }.abs());
    }}
    println!("N=8: U*U = I to within 1e-12: {}; U^2 reverses the list, so U^4 = I: {}",
             if e1 < 1e-12 { "yes" } else { "no" }, if e2 < 1e-12 { "yes" } else { "no" });
    assert!(e1 < 1e-12);
    assert!(e2 < 1e-12);
    let mut errs: Vec<f64> = vec![];
    for &nn in &[8usize, 32, 128] {
        let dt = 8.0 / nn as f64;
        let x: Vec<f64> = (0..nn).map(|j| if (-4.0 + (j as f64 + 0.5) * dt).abs() < 1.0 { 1.0 } else { 0.0 }).collect();
        let xx = dft(&x);
        let et = dt * x.iter().map(|v| v * v).sum::<f64>();
        let ef = dt * xx.iter().map(|c| c.abs().powi(2)).sum::<f64>() / nn as f64;
        println!("N={:3}, dt={:.4} us: time energy {:.6} uJ, frequency energy {:.6} uJ, |dt X_1| {:.6} against F(pi/4) {:.6}",
                 nn, dt, et, ef, dt * xx[1].abs(), ff(PI / 4.0, 1.0));
        assert!((et - ef).abs() < 1e-12 && (et - 2.0).abs() < 1e-12);
        errs.push((dt * xx[1].abs() - ff(PI / 4.0, 1.0)).abs());
    }
    assert!(errs.windows(2).all(|p| p[1] < p[0] / 10.0)); // the sampled spectrum closes on F
    let x: Vec<f64> = (0..8).map(|j| 1.0 / (1.0 + j as f64)).collect();
    let bx: Vec<f64> = (0..8).map(|j| x[(j + 7) % 8] / 4.0 + x[j] / 2.0 + x[(j + 1) % 8] / 4.0).collect();
    let gain: Vec<f64> = (0..8).map(|k| (PI * k as f64 / 8.0).cos().powi(2)).collect();
    let (db, dx) = (dft(&bx), dft(&x));
    let gap = (0..8).map(|k| C { re: db[k].re - gain[k] * dx[k].re, im: db[k].im - gain[k] * dx[k].im }.abs()).fold(0.0, f64::max);
    let gs: Vec<String> = gain.iter().map(|g| format!("{:.3}", g)).collect();
    println!("blur gains by frequency: {} | worst case {:.3}", gs.join(" "), gain.iter().cloned().fold(0.0, f64::max));
    assert!(gap < 1e-12);

    // ---- Plancherel for the pulse: 2 uJ in time, 2 uJ in frequency ----
    for &(lab, w) in &[("0.5", PI / 2.0), ("1", PI), ("2", 2.0 * PI), ("4", 4.0 * PI)] {
        let i = inside(w, 1.0);
        println!("share of the energy in |w| < {} pi: {:.6} uJ = {:.4} %", lab, i, 50.0 * i);
    }
    for &w in &[10usize, 100, 1000] {
        let (i, t) = (inside(w as f64, 1.0), tail(w as f64));
        println!("|w| < {:4}: inside {:.6}, tail (closed form) {:.6}, total {:.6} uJ", w, i, t, i + t);
        assert!((i + t - 2.0).abs() < 1e-7);
    }
    println!("without the 1/sqrt(2 pi): integral of |F|^2 = {:.6}, not 2", 2.0 * PI * 2.0);
    for &w in &[1.0f64, 2.5] {
        let tri = 2.0 * simpson(|s| (2.0 - s) * (w * s).cos(), 0.0, 2.0, 2000);
        println!("autocorrelation triangle at w = {:.1}: transform {:.6}, |F|^2 {:.6}", w, tri, ff(w, 1.0).powi(2));
        assert!((tri - ff(w, 1.0).powi(2)).abs() < 1e-10);
    }
    for &d in &[1.0f64, 0.5] {
        let ip = 2.0 * simpson(|w| ff(w, 1.0).powi(2) * (w * d).cos(), 0.0, 128.0 * PI, 80000) / (2.0 * PI);
        let ang = (ip / 2.0).acos().to_degrees();
        println!("echo after {:.1} us: overlap in time {:.6}, in frequency {:.6}, angle {:.4} degrees", d, 2.0 - d, ip, ang);
        assert!((ip - (2.0 - d)).abs() < 1e-6);
    }

    // ---- the extension by density: cut the spectrum at W, invert, let W grow ----
    let mut prev = 0.0;
    for &m in &[10usize, 100, 1000] {
        let mut area = 0.0;
        for j in 0..m { area += simpson(|w| ff(w, 1.0).abs(), j as f64 * PI, (j + 1) as f64 * PI, 400); }
        area *= 2.0;
        println!("area under |F| for |w| < {} pi: {:.6}", m, area);
        if m == 1000 {
            println!("last tenfold step adds {:.6}; (8/pi) ln 10 = {:.6}", area - prev, 8.0 / PI * 10f64.ln());
            assert!((area - prev - 8.0 / PI * 10f64.ln()).abs() < 0.01);
        }
        prev = area;
    }
    let direct = simpson(|w| ff(w, 1.0) * (0.5 * w).cos(), 0.0, 10.0, 2000) / PI;
    println!("rebuilt pulse W = 10 at t = 0.5: Si formula {:.6}, inverse integral {:.6}", fw(0.5, 10.0), direct);
    assert!((direct - fw(0.5, 10.0)).abs() < 1e-8);
    let (d, r) = (0.005f64, 100usize);
    let mut s = vec![0.0f64];
    for j in 0..((40.0 * (r as f64 + 1.0) / d) as usize + 1) {
        let jf = j as f64;
        let last = *s.last().unwrap();
        s.push(last + d / 6.0 * (sinc(jf * d) + 4.0 * sinc((jf + 0.5) * d) + sinc((jf + 1.0) * d)));
    }
    let sit = |j: i64| if j >= 0 { s[j as usize] } else { -s[(-j) as usize] };
    let sv = |v: &[f64]| {
        let mut acc = 0.0;
        for k in 1..v.len() - 1 { acc += (if k % 2 == 1 { 4.0 } else { 2.0 }) * v[k]; }
        d / 3.0 * (v[0] + v[v.len() - 1] + acc)
    };
    for &w in &[10i64, 20, 40] {
        let g: Vec<f64> = (0..(200 * r as i64 + 1)).map(|m| (sit(m * w + 200 * w) - sit(m * w - 200 * w)) / PI).collect();
        let a: Vec<f64> = g[..201].iter().map(|y| (1.0 - y).powi(2)).collect();
        let b: Vec<f64> = g[200..].iter().map(|y| y * y).collect();
        let et = 2.0 * (sv(&a) + sv(&b));
        let wf = w as f64;
        println!("W = {}: error energy in time {:.6}, in frequency {:.6}, W x error {:.6}", w, et, tail(wf), wf * tail(wf));
        assert!((et - tail(wf)).abs() < 5e-5);
    }
    for &w in &[10.0f64, 20.0, 40.0, 80.0] {
        println!("W = {}: rebuild at t = 1 - pi/W, just inside the edge: {:.6}", w, fw(1.0 - PI / w, w));
        assert!((fw(1.0 - PI / w, w) - (0.5 + si(PI) / PI)).abs() < 0.02);
    }
    println!("its limit: 1/2 + Si(pi)/pi = {:.6}; 2/pi = {:.6}", 0.5 + si(PI) / PI, 2.0 / PI);
    for &w in &[10.0f64, 40.0] {
        let pts: Vec<String> = (0..21).map(|k| format!("{:.3}", fw(k as f64 / 10.0, w))).collect();
        println!("chart W={}: {}", w, pts.join(", "));
    }
    let ws = [10.0f64, 100.0, 1000.0];
    let js = |t: f64| ws.iter().map(|&w| format!("{:.6}", fw(t, w))).collect::<Vec<_>>().join(" ");
    println!("fixed times, W = 10, 100, 1000: t = 0.9 -> {} ; edge t = 1 -> {}", js(0.9), js(1.0));
    let e9: Vec<f64> = ws.iter().map(|&w| (fw(0.9, w) - 1.0).abs()).collect();
    assert!(e9[2] < e9[1] && e9[1] < e9[0] && (fw(1.0, 1000.0) - 0.5).abs() < 1e-3);

    // ---- try changing ----
    let x: Vec<f64> = (0..512).map(|j| if (-4.0 + (j as f64 + 0.5) * 8.0 / 512.0).abs() < 1.0 { 1.0 } else { 0.0 }).collect();
    println!("N=512: |dt X_1| {:.6} against F(pi/4) {:.6}", 8.0 / 512.0 * dft(&x)[1].abs(), ff(PI / 4.0, 1.0));
    println!("pulse 4 us long: main lobe |w| < pi/2 holds {:.6} of 4 uJ, share {:.6}; W = 160: error energy {:.6} uJ",
             inside(PI / 2.0, 2.0), inside(PI / 2.0, 2.0) / 4.0, tail(160.0));
    println!("ALL CHECKS PASS");
}
