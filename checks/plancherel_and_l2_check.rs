// Plancherel -- the same check as the Python, in Rust.  No crates.
// The note: f(t) = A e^(-t/tau) sin(2 pi f0 t) for t >= 0, 0 before the pluck,
// with A = 1 V, f0 = 110 Hz, tau = 1 s (illustrative).  Hertz form:
// fhat(xi) = integral f(t) e^(-2 pi i xi t) dt, xi in hertz, energy in V^2 s.
// Roads as in the Python.  A complex number is a small struct.
use std::f64::consts::PI;
const A: f64 = 1.0; const F0: f64 = 110.0; const TAU: f64 = 1.0;
const AL: f64 = 1.0 / TAU;                         // decay rate, per second
const SI: f64 = 2.0 * PI * F0;                     // the note is Im(A e^(S t)), S = -AL + i SI
#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }
impl C {
    fn add(self, o: C) -> C { C { re: self.re + o.re, im: self.im + o.im } }
    fn sub(self, o: C) -> C { C { re: self.re - o.re, im: self.im - o.im } }
    fn mul(self, o: C) -> C { C { re: self.re * o.re - self.im * o.im, im: self.re * o.im + self.im * o.re } }
    fn inv(self) -> C { let d = self.re * self.re + self.im * self.im; C { re: self.re / d, im: -self.im / d } }
    fn scale(self, s: f64) -> C { C { re: self.re * s, im: self.im * s } }
    fn abs(self) -> f64 { self.re.hypot(self.im) }
    fn cis(a: f64) -> C { C { re: a.cos(), im: a.sin() } }
}
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = g(a) + g(b);
    for k in 1..m { s += if k % 2 == 1 { 4.0 } else { 2.0 } * g(a + k as f64 * h); }
    s * h / 3.0
}
fn note(t: f64) -> f64 { if t >= 0.0 { A * (-t / TAU).exp() * (2.0 * PI * F0 * t).sin() } else { 0.0 } }
fn fhat(xi: f64) -> C {                            // closed form, a complex number
    let (p, q) = (C { re: AL, im: 2.0 * PI * (xi - F0) }.inv(), C { re: AL, im: 2.0 * PI * (xi + F0) }.inv());
    let d = p.sub(q).scale(A / 2.0);               // divide by 2i: (re, im) -> (im, -re)
    C { re: d.im, im: -d.re }
}
fn power(xi: f64) -> f64 { fhat(xi).abs().powi(2) }

fn band(lo: f64, hi: f64, w: &dyn Fn(f64) -> f64, m: usize) -> f64 {
    let th = |xi: f64| (2.0 * PI * (xi - F0) / AL).atan();  // xi = F0 + (AL/2pi) tan(th):
    let g = |u: f64| {                                      // flattens the peak at F0
        let xi = F0 + AL / (2.0 * PI) * u.tan();
        power(xi) * w(xi) * AL / (2.0 * PI) / u.cos().powi(2)
    };
    simpson(&g, th(lo), th(hi), m)
}
fn freq_int(w: &dyn Fn(f64) -> f64, m: usize) -> f64 {   // all xi: power is even
    let cuts = [0.0, F0 - 1.0, F0 + 1.0, 1e3];            // three pieces, peak in the middle
    let top = |u: f64| if u > 0.0 { let xi = 1e3 / u.powi(4); power(xi) * w(xi) * 4e3 / u.powi(5) } else { 0.0 };
    let s = (0..3).map(|i| band(cuts[i], cuts[i + 1], w, m)).sum::<f64>() + simpson(&top, 0.0, 1.0, m);
    2.0 * s                                               // last piece: xi = 1 kHz / u^4, out to infinity
}

fn in_time(e: f64, c: f64) -> f64 {               // energy of c f - f_eps, in time: no transform
    let (m, s) = (6.0 * e, C { re: -AL, im: SI });
    let gb = |u: f64| (-PI * u * u / (e * e)).exp() / e;              // the bell, cut at 6 eps
    let fe = |t: f64| if t > -m { simpson(&|u| note(t - u) * gb(u), -m, t.min(m), 400) } else { 0.0 };
    let g = |t: f64| (c * note(t) - fe(t)).powi(2);  // fe(t) = f_eps(t) = integral f(t - u) G(u) du
    let kp = |p: fn(C) -> f64| simpson(&|u| p(C::cis(-SI * u)) * (AL * u).exp() * gb(u), -m, m, 400);
    let d = C { re: c, im: 0.0 }.sub(C { re: kp(|z| z.re), im: kp(|z| z.im) }).scale(A);
    let ee = C::cis(2.0 * SI * m).scale((-2.0 * AL * m).exp());     // past m: Im(D e^(S t))
    let far = (d.abs().powi(2) * (-2.0 * AL * m).exp() / (2.0 * AL) + d.mul(d).mul(ee).mul(s.scale(2.0).inv()).re) / 2.0;
    simpson(&g, -m, 0.0, 400) + simpson(&g, 0.0, m, 400) + far      // near part split at the kink
}
fn fft(x: &[C]) -> Vec<C> {                        // radix-2, written out
    let n = x.len();
    if n == 1 { return x.to_vec(); }
    let ev: Vec<C> = x.iter().step_by(2).cloned().collect();
    let od: Vec<C> = x.iter().skip(1).step_by(2).cloned().collect();
    let (ev, od) = (fft(&ev), fft(&od));
    let mut out = vec![C { re: 0.0, im: 0.0 }; n];
    for k in 0..n / 2 {
        let tw = C::cis(-2.0 * PI * k as f64 / n as f64).mul(od[k]);
        out[k] = ev[k].add(tw);
        out[k + n / 2] = ev[k].sub(tw);
    }
    out
}
fn sci(v: f64, d: usize) -> String {               // Python's e format: 2.385e-01
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let ex: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ex < 0 { '-' } else { '+' }, ex.abs())
}
fn f6(v: f64) -> String { format!("{:.6}", v) }
fn f9(v: f64) -> String { format!("{:.9}", v) }

fn main() {
    let one = |_: f64| 1.0;
    println!("== the note: 1 V, 110 Hz, amplitude falls by e each second ==");
    let bt = 2.0 * PI * F0 * TAU;
    println!("b = 2 pi f0 tau = {}; b^2/(1 + b^2) = {}", f6(bt), f9(bt * bt / (1.0 + bt * bt)));
    let e_exact = TAU / 4.0 * bt * bt / (1.0 + bt * bt);
    let e_simp = simpson(&|t| note(t).powi(2), 0.0, 10.0, 200000);
    let tail_t = TAU / 2.0 * (-20.0 / TAU).exp();
    println!("energy in time, closed form (tau/4) b^2/(1 + b^2), b = 2 pi f0 tau: {} V^2 s", f9(e_exact));
    println!("energy in time, Simpson on 0..10 s: {}; tail beyond 10 s at most {}", f9(e_simp), sci(tail_t, 2));
    assert!((e_simp - e_exact).abs() < 1e-9);                 // road 1 = road 2
    let (e_f1, e_f2) = (freq_int(&one, 2000), freq_int(&one, 4000));
    println!("energy in frequency, Simpson, 2000 and 4000 steps: {} and {} V^2 s", f9(e_f1), f9(e_f2));
    assert!((e_f2 - e_exact).abs() < 1e-9);                   // Plancherel on the note
    assert!((e_f1 - e_f2).abs() < 1e-8);
    println!("peak |fhat(110)| = {} V s; half-power half-width 1/(2 pi tau) = {} Hz", f6(fhat(F0).abs()), f6(AL / (2.0 * PI)));
    println!("bars, share of the energy within d Hz of +-110 Hz: d | share");
    for d in [0.1, 0.5, 1.0, 5.0, 50.0] {
        println!("bars, {} | {:.4} %", d, 100.0 * 2.0 * band(F0 - d, F0 + d, &one, 2000) / e_exact);
    }
    println!("Lorentz estimate for d = 1, (2/pi) atan(2 pi): {:.4} %", 100.0 * 2.0 / PI * (2.0 * PI).atan());

    println!("== the samples: 4096 a second for 8 s, N = 32768, written-out FFT ==");
    let (fs, n) = (4096.0, 32768usize);
    let (dt, dxi) = (1.0 / fs, fs / n as f64);
    let x: Vec<C> = (0..n).map(|k| C { re: note(k as f64 * dt), im: 0.0 }).collect();
    let xx = fft(&x);
    let (mut s_time, mut s_freq) = (0.0, 0.0);
    for k in 0..n {
        s_time += x[k].abs().powi(2) * dt;
        s_freq += xx[k].scale(dt).abs().powi(2) * dxi;
    }
    println!("dt sum x^2 = {}; dxi sum |dt X|^2 = {} V^2 s", f9(s_time), f9(s_freq));
    assert!((s_time - s_freq).abs() < 1e-12);                 // finite Parseval, exact
    println!("gap from the true energy (sampling and the 8 s cut): {}", sci(s_time - e_exact, 2));
    assert!((s_time - e_exact).abs() < 1e-6);
    let k = (F0 / dxi).round() as usize;
    let cut = fhat(F0).abs() * (1.0 - (-8.0 / TAU).exp());  // the 8 s cut drops e^(-8) of the peak
    println!("bin {} at {} Hz: |dt X| = {}; |fhat| = {}, times 1 - e^-8 = {}", k, f6(k as f64 * dxi), f6(xx[k].scale(dt).abs()), f6(fhat(F0).abs()), f6(cut));
    assert!((xx[k].scale(dt).abs() - cut).abs() < 1e-6);      // the FFT is the transform

    println!("== density: bell-smoothed notes f_eps, each rapidly decreasing ==");
    println!("eps ms | gain at 110 Hz | energy of f_eps | ||f - f_eps||^2 in time | in frequency | ||f_eps - f_prev||^2");
    let eps_list = [10.0, 1.0, 0.1, 0.01];
    let (mut dist, mut ens): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for i in 0..4 {
        let e = eps_list[i] / 1000.0;
        let p = eps_list[(i + 3) % 4] / 1000.0;
        let sm = |xi: f64, e: f64| (-PI * e * e * xi * xi).exp();   // the bell's transform
        ens.push(freq_int(&|xi| sm(xi, e).powi(2), 4000));
        dist.push(in_time(e, 1.0));                                // f is not in S: measured in time
        let d_f = freq_int(&|xi| (1.0 - sm(xi, e)).powi(2), 4000);
        let c = if i == 0 { "-".to_string() } else { sci(freq_int(&|xi| (sm(xi, e) - sm(xi, p)).powi(2), 4000), 3) };
        println!("{} | {} | {} | {} | {} | {}", eps_list[i], f6(sm(F0, e)), f9(ens[i]), sci(dist[i], 3), sci(d_f, 3), c);
        assert!((d_f - dist[i]).abs() < 1e-3 * dist[i]);          // time side = frequency side
    }
    assert!(dist[0] > dist[1] && dist[1] > dist[2] && dist[2] > dist[3] && dist[3] < 1e-5 * dist[0]);
    let e_time = in_time(0.001, 0.0);              // f_eps for eps = 1 ms, built in time
    println!("eps = 1 ms: energy of f_eps in time {}, in frequency {} V^2 s", f9(e_time), f9(ens[1]));
    assert!((e_time - ens[1]).abs() < 1e-8);                  // Plancherel on a smooth note

    println!("== the shutter: 1 V for 1 ms; its spectrum sin(pi xi T)/(pi xi) ==");
    let t_open = 0.001;
    let gate = |xi: f64| if xi == 0.0 { t_open } else { (PI * xi * t_open).sin() / (PI * xi) };
    let lobe = 2.0 * simpson(&|xi| gate(xi).powi(2), 0.0, 1.0 / t_open, 2000);
    println!("gate energy {} V^2 ms; main lobe |xi| < 1 kHz holds {:.4} %", f6(t_open * 1000.0), 100.0 * lobe / t_open);
    let (mut area, mut edge, mut areas) = (0.0, 0.0, Vec::new());
    for w in [10.0, 100.0, 1000.0] {               // in units of kHz; lobes of 1 kHz
        while edge < w { area += 2.0 * simpson(&|xi| gate(xi).abs(), edge / t_open, (edge + 1.0) / t_open, 40); edge += 1.0; }
        println!("area under |spectrum| for |xi| < {} kHz: {} V", w, f6(area));
        areas.push(area);
    }
    let grow = 4.0 / (PI * PI) * 10f64.ln();
    println!("growth per tenfold band: {} V; (4/pi^2) ln 10 = {}", f6(areas[2] - areas[1]), f6(grow));
    assert!((areas[2] - areas[1] - grow).abs() < 1e-3);       // no finite area

    println!("== what breaks ==");
    println!("omega form, no 1/2pi: integral |F(omega)|^2 d omega = 2 pi x {} = {}", f6(e_f2), f6(2.0 * PI * e_f2));
    for l in [1usize, 10, 100] {
        let en = simpson(&|t| (2.0 * PI * F0 * t).sin().powi(2), 0.0, l as f64, 2000 * l);
        println!("string that never decays: energy over the first {} s = {} V^2 s", l, f6(en));
    }
    println!("positive frequencies only: {} against {}", f6(e_f2 / 2.0), f6(e_exact));
    println!("because |fhat(-110)| = {} = |fhat(110)|", f6(fhat(-F0).abs()));
    assert!((power(-F0) - power(F0)).abs() < 1e-12);          // a real note: even power
    println!("ALL CHECKS PASS");
}
