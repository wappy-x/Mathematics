// Fourier inversion -- the same check as the Python, in Rust.  No crates.
// Convention: fhat(xi) = integral of f(t) e^(-2 pi i xi t) dt, t in seconds, xi in
// hertz; the inverse has no factor in front.  The shutter is open (f = 1) for T = 1 ms.
// Two rebuilds: the sharp cut-off S_W (keep |xi| < W) and the bell rebuild G_eps
// (multiply the spectrum by e^(-pi eps^2 xi^2)).  Roads: closed forms through Si and
// erf, each a series written out here; the inverse integral on the frequency side by
// Simpson's rule at n and 2n strips; the blur on the time side, also by Simpson.
use std::f64::consts::PI;

const T: f64 = 0.001; // shutter open time, seconds
fn f6(x: f64) -> String { format!("{:.6}", if x.abs() < 5e-7 { 0.0 } else { x }) }
fn c2(x: f64) -> String { format!("{:.2}", if x.abs() < 0.005 { 0.0 } else { x }) }
fn sci(x: f64) -> String { // Python's %.2e: two-digit exponent
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_at(s.find('e').unwrap());
    let n: i32 = e[1..].parse().unwrap();
    format!("{}e{}{:02}", m, if n < 0 { '-' } else { '+' }, n.abs())
}
fn fhat(xi: f64) -> f64 { if xi == 0.0 { T } else { (PI * T * xi).sin() / (PI * xi) } }

fn si(x: f64) -> f64 { // Si(x): area under sin(u)/u, 0 to x
    if x < 0.0 { return -si(-x); }
    if x <= 20.0 { // power series, 80 terms
        let (mut a, mut s) = (x, 0.0);
        for k in 0..80 {
            s += a / (2 * k + 1) as f64;
            a *= -x * x / (((2 * k + 2) * (2 * k + 3)) as f64);
        }
        return s;
    }
    let (mut fa, mut ga, mut c) = (0.0, 0.0, 1.0); // large x: asymptotic series, 9 terms
    for k in 0..9 {
        fa += c / x.powi(2 * k + 1);
        ga += c * (2 * k + 1) as f64 / x.powi(2 * k + 2);
        c *= -(((2 * k + 1) * (2 * k + 2)) as f64);
    }
    PI / 2.0 - fa * x.cos() - ga * x.sin()
}

fn erf(x: f64) -> f64 { // erf(x) = (2/sqrt(pi)) area under e^(-u^2)
    if x < 0.0 { return -erf(-x); }
    if x <= 4.0 { // power series, 100 terms
        let (mut a, mut s) = (x, 0.0);
        for k in 0..100 {
            s += a / (2 * k + 1) as f64;
            a *= -x * x / (k + 1) as f64;
        }
        return 2.0 * s / PI.sqrt();
    }
    let (mut s, mut c) = (0.0, 1.0); // large x: erfc asymptotic, 7 terms
    for k in 0..7 {
        s += c;
        c *= -((2 * k + 1) as f64) / (2.0 * x * x);
    }
    1.0 - (-x * x).exp() / (x * PI.sqrt()) * s
}

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let w = (b - a) / n as f64;
    let mut s = g(a) + g(b);
    for k in 1..n { s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * g(a + k as f64 * w); }
    s * w / 3.0
}

fn sharp_closed(t: f64, w: f64) -> f64 { (si(2.0 * PI * w * (t + T / 2.0)) - si(2.0 * PI * w * (t - T / 2.0))) / PI }
fn bell_closed(t: f64, e: f64) -> f64 { (erf(PI.sqrt() * (t + T / 2.0) / e) - erf(PI.sqrt() * (t - T / 2.0) / e)) / 2.0 }
fn sharp_freq(t: f64, w: f64, n: usize) -> f64 { 2.0 * simpson(&|x| fhat(x) * (2.0 * PI * x * t).cos(), 0.0, w, n) }
fn bell_freq(t: f64, e: f64, n: usize) -> f64 {
    2.0 * simpson(&|x| fhat(x) * (-PI * (e * x).powi(2)).exp() * (2.0 * PI * x * t).cos(), 0.0, 4.0 / e, n)
}
fn dirichlet(u: f64, w: f64) -> f64 { if u == 0.0 { 2.0 * w } else { (2.0 * PI * w * u).sin() / (PI * u) } }
fn sharp_time(t: f64, w: f64, n: usize) -> f64 { simpson(&|s| dirichlet(t - s, w), -T / 2.0, T / 2.0, n) }
fn bell_time(t: f64, e: f64, n: usize) -> f64 { simpson(&|s| (-PI * ((t - s) / e).powi(2)).exp() / e, -T / 2.0, T / 2.0, n) }

fn lobes(m: usize) -> f64 {
    let g = |u: f64| if u != 0.0 { ((PI * u).sin() / (PI * u)).abs() } else { 1.0 };
    2.0 * (0..m).map(|k| simpson(&g, k as f64, (k + 1) as f64, 40)).sum::<f64>()
}

fn main() {
    println!("shutter open T = 1 ms; fhat in ms at 0, 500, 1000 Hz: {}, {}, {}",
             f6(1000.0 * fhat(0.0)), f6(1000.0 * fhat(500.0)), f6(1000.0 * fhat(1000.0)));
    let areas = [lobes(10), lobes(100), lobes(1000)];
    println!("area under |fhat| on [-W, W], W = 10 kHz, 100 kHz, 1 MHz: {}, {}, {}", f6(areas[0]), f6(areas[1]), f6(areas[2]));
    let decade = 4.0 / (PI * PI) * 10f64.ln();
    println!("growth per decade: {}, {}; (4/pi^2) ln 10 = {}", f6(areas[1] - areas[0]), f6(areas[2] - areas[1]), f6(decade));
    assert!((areas[2] - areas[1] - decade).abs() < 1e-5); // the area never settles
    let rp = PI.sqrt();
    println!("by hand: erf(9 sqrt(pi)) = {}, erf(sqrt(pi)) = {}, erf(5 sqrt(pi)) = {}", f6(erf(9.0 * rp)), f6(erf(rp)), f6(erf(5.0 * rp)));
    println!("by hand: Si(18 pi) = {}, Si(2 pi) = {}, Si(10 pi) = {}; area of |f| / eps = {}",
             f6(si(18.0 * PI)), f6(si(2.0 * PI)), f6(si(10.0 * PI)), f6(T / 1e-4));
    println!("bell peak 1/eps = {} per s, spread eps/sqrt(2 pi) = {} ms, fade at 10 kHz = {}; D_W peak 2W = {} per s",
             f6(1.0 / 1e-4), f6(0.1 / (2.0 * PI).sqrt()), f6((-PI * (1e-4f64 * 1e4).powi(2)).exp()), f6(dirichlet(0.0, 10000.0)));
    let mut peaks: Vec<f64> = Vec::new();
    for &(w, e, n) in &[(10000.0, 1e-4, 4000usize), (100000.0, 1e-5, 40000usize)] {
        println!("W = {} kHz, eps = {} ms; Simpson at {} and {} strips", (w / 1000.0) as i64, f6(1000.0 * e), n, 2 * n);
        let mut gap: f64 = 0.0;
        for sharp in [true, false] {
            let (p, nf) = if sharp { (w, n) } else { (e, 4 * n) };
            println!("  {} at t ms: closed form | frequency side | time side",
                     if sharp { "sharp cut-off S_W" } else { "bell rebuild G_eps" });
            for tm in [0.0, 0.4, 0.5, 0.6, 1.0] {
                let t = tm / 1000.0;
                let (c, a, b, a2) = if sharp {
                    (sharp_closed(t, p), sharp_freq(t, p, 2 * nf), sharp_time(t, p, 2 * n), sharp_freq(t, p, nf))
                } else {
                    (bell_closed(t, p), bell_freq(t, p, 2 * nf), bell_time(t, p, 2 * n), bell_freq(t, p, nf))
                };
                gap = gap.max((a - a2).abs());
                println!("    t = {:.1}: {} | {} | {}", tm, f6(c), f6(a), f6(b));
                assert!((c - a).abs() < 1e-7 && (c - b).abs() < 1e-7); // three roads agree
            }
        }
        let tail = 2.0 * T * (-16.0 * PI).exp() / (8.0 * PI * e);
        println!("  largest gap n vs 2n strips: {}; bell cut at 4/eps, tail bound {}", sci(gap), sci(tail));
        let (mut top, mut at) = (f64::MIN, 0.0);
        for k in 4000..=5000 {
            let v = sharp_closed(k as f64 * 1e-7, w);
            if v >= top { top = v; at = k as f64 / 10000.0; }
        }
        let bells: Vec<f64> = (0..=10000).map(|k| bell_closed(k as f64 * 1e-7, e)).collect();
        let hi = bells.iter().cloned().fold(f64::MIN, f64::max);
        let lo = bells.iter().cloned().fold(f64::MAX, f64::min);
        peaks.push(top);
        println!("  scan 0.4 to 0.5 ms: largest S_W {} at t = {:.4} ms; G_eps over 0 to 1 ms stays in [{}, {}]", f6(top), at, f6(lo), f6(hi));
        let jmin = -((T / e).round() as i64);
        let l1 = 2.0 * (jmin..20).map(|j| {
            let f = if j < 0 { 1.0 } else { 0.0 };
            simpson(&|t| (bell_closed(t, e) - f).abs(), T / 2.0 + j as f64 * e / 2.0, T / 2.0 + (j + 1) as f64 * e / 2.0, 200)
        }).sum::<f64>();
        println!("  mean error, area of |G_eps - f|: {} ms; 2 eps/pi = {} ms", f6(1000.0 * l1), f6(1000.0 * 2.0 * e / PI));
        let miss = 2.0 / (PI * PI * w * T);
        println!("  middle miss 1 - S_W(0): {}; 2/(pi^2 W T) = {}", f6(1.0 - sharp_closed(0.0, w)), f6(miss));
        assert!((l1 - 2.0 * e / PI).abs() < 1e-6 * 2.0 * e / PI); // mean error is 2 eps/pi
        assert!((1.0 - sharp_closed(0.0, w) - miss).abs() < 0.1 * miss);
        assert!(lo >= 0.0 && hi <= 1.0 && (bell_closed(T / 2.0, e) - 0.5).abs() < 1e-12); // no overshoot, midpoint
    }
    let limit = 0.5 + si(PI) / PI;
    println!("single-edge overshoot limit 1/2 + Si(pi)/pi = {}", f6(limit));
    assert!(peaks.iter().cloned().fold(f64::MAX, f64::min) > limit - 1e-3); // overshoot never shrinks
    println!("mistake, 1/(2 pi) in front with xi in hertz: G_eps(0) = {} instead of {}",
             f6(bell_closed(0.0, 1e-4) / (2.0 * PI)), f6(bell_closed(0.0, 1e-4)));
    println!("mistake, edge read as 1: S_W(0.5 ms) = {} at 100 kHz, G_eps(0.5 ms) = {}",
             f6(sharp_closed(T / 2.0, 100000.0)), f6(bell_closed(T / 2.0, 1e-5)));
    println!("mistake, no damping: integral of e^(2 pi i xi u) over |xi| < L at u = 0.1 ms, per s:");
    let swings: Vec<String> = [10000.0, 12500.0, 15000.0, 17500.0].iter().map(|&l| f6(dirichlet(1e-4, l))).collect();
    println!("  L = 10, 12.5, 15, 17.5 kHz: {}", swings.join(", "));
    let ts: Vec<f64> = (0..41).map(|k| 0.3 + 0.01 * k as f64).collect();
    let row = |g: &dyn Fn(f64) -> String| ts.iter().map(|&t| g(t)).collect::<Vec<String>>().join(", ");
    println!("chart t ms: {}", row(&|t| format!("{:.2}", t)));
    println!("chart shutter: {}", row(&|t| format!("{:.2}", if t < 0.499 { 1.0 } else if t < 0.501 { 0.5 } else { 0.0 })));
    println!("chart S_W 10 kHz: {}", row(&|t| c2(sharp_closed(t / 1000.0, 10000.0))));
    println!("chart G_eps 0.1 ms: {}", row(&|t| c2(bell_closed(t / 1000.0, 1e-4))));
    println!("ALL CHECKS PASS");
}
