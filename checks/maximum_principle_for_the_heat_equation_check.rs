// Diffusion's maximum principle -- the check behind the card.  std only, no crates.
// A 1 m copper rod, ends held at 20 C, starts with a tent-shaped hot spot 20 cm wide
// peaking at 100 C.  Roads: a sine series, an explicit grid, the equation's residual
// by centred differences, and a barrier built by hand.  Then the three breaks,
// ending with Tychonoff's solution on an endless rod.
use std::f64::consts::PI;

const KAPPA: f64 = 1.0 / 9009.0; // copper's diffusivity, m^2/s (9009 s per m^2)
const END: f64 = 20.0; // end temperature, C
const PEAK: f64 = 80.0; // hot spot's rise, K
const W: f64 = 0.1; // half-width, m

fn tent(x: f64) -> f64 {
    END + PEAK * (1.0 - (x - 0.5).abs() / W).max(0.0)
}

fn b(n: usize) -> f64 {
    let nf = n as f64;
    4.0 * PEAK * (nf * PI / 2.0).sin() * (1.0 - (nf * PI * W).cos()) / (W * (nf * PI).powf(2.0))
}

fn rod(x: f64, t: f64) -> f64 {
    let mut s = 0.0;
    for n in 1..=40 {
        let nf = n as f64;
        s += b(n) * (-KAPPA * (nf * PI).powf(2.0) * t).exp() * (nf * PI * x).sin();
    }
    END + s
}

fn grid(m: usize, steps: usize, t_end: f64) -> (Vec<f64>, f64, f64, f64) {
    let h = 1.0 / m as f64;
    let dt = t_end / steps as f64;
    let r = KAPPA * dt / (h * h);
    let mut u: Vec<f64> = (0..=m).map(|i| tent(i as f64 * h)).collect();
    let (mut hi, mut lo) = (vmax(&u), vmin(&u));
    for _ in 0..steps {
        let mut v = u.clone();
        for i in 1..m { v[i] = u[i] + r * (u[i - 1] - 2.0 * u[i] + u[i + 1]); }
        u = v;
        hi = hi.max(vmax(&u));
        lo = lo.min(vmin(&u));
    }
    (u, hi, lo, r)
}

fn vmax(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::NEG_INFINITY, f64::max) }
fn vmin(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::INFINITY, f64::min) }
fn row(v: &[f64]) -> String {
    v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(", ")
}

fn resid(f: &dyn Fn(f64, f64) -> f64, x: f64, t: f64, dx: f64, dt: f64, k: f64) -> f64 {
    let ut = (f(x, t + dt) - f(x, t - dt)) / (2.0 * dt);
    ut - k * (f(x + dx, t) - 2.0 * f(x, t) + f(x - dx, t)) / (dx * dx)
}

// Tychonoff: sum g^(k)(t) x^(2k)/(2k)!, g = exp(-1/t^2); returns (sum, first omitted, c)
fn tych(x: f64, t: f64) -> (f64, f64, Vec<f64>) {
    let kk = 120;
    let h: Vec<f64> = (0..=kk).map(|n| -(if n % 2 == 0 { 1.0 } else { -1.0 }) * (n + 1) as f64 / t.powf((n + 2) as f64)).collect();
    let mut c = vec![h[0].exp()];
    for n in 1..=kk {
        let mut s = 0.0;
        for j in 1..=n { s += j as f64 * h[j] * c[n - j]; }
        c.push(s / n as f64);
    }
    let (mut ratio, mut terms) = (1.0, Vec::new());
    for k in 0..=kk {
        if k > 0 { ratio *= k as f64 / ((2 * k) * (2 * k - 1)) as f64; }
        terms.push(c[k] * ratio * x.powf((2 * k) as f64));
    }
    let mut s = 0.0;
    for v in &terms[..kk] { s += v; }
    (s, terms[kk], c)
}

fn main() {
    let xs: Vec<f64> = (0..21).map(|i| i as f64 / 20.0).collect();
    let tents: Vec<f64> = xs.iter().map(|&x| tent(x)).collect();
    println!("setup: kappa = 1/9009 = {:.4}e-4 m^2/s; boundary max {:.1} C, min {:.1} C", KAPPA * 1e4, vmax(&tents), END);
    println!("b_1 = 320*(1 - cos(0.1 pi))/(0.1 pi^2) = {:.4} K; b_2 = {:.4}; b_3 = {:.4} K", b(1), b(2), b(3));
    let mut s0 = 0.0;
    for n in 1..=2000 { s0 += b(n) * (n as f64 * PI * 0.45).sin(); }
    s0 += END;
    let tail = 4.0 * PEAK * 2.0 / (W * PI.powf(2.0)) / 2000.0;
    println!("start at x=0.45: tent {:.4}, series N=2000 {:.4}, tail bound {:.4}", tent(0.45), s0, tail);
    assert!((s0 - tent(0.45)).abs() < tail);
    for t in [0.0, 60.0, 600.0] {
        let vals: Vec<f64> = xs.iter().map(|&x| if t == 0.0 { tent(x) } else { rod(x, t) }).collect();
        println!("profile t={} s, x=0,0.05..1: {}", t, row(&vals));
    }
    let lg = b(41).abs().log10() - KAPPA * (41.0 * PI).powf(2.0) * 60.0 / 10f64.ln();
    println!("series uses 40 terms; log10 of the first omitted term at t=60 s: {:.1}", lg);
    for t in [60.0, 300.0, 600.0, 1800.0] {
        let prof: Vec<f64> = (0..=200).map(|i| rod(i as f64 / 200.0, t)).collect();
        let (mx, mn) = (vmax(&prof), vmin(&prof));
        assert!(20.0 - 1e-9 <= mn && mx <= 100.0);
        let at = prof.iter().position(|&v| v == mx).unwrap();
        println!("t={} s: rod max {:.4} C at x={:.3} m, min {:.4} C", t, mx, at as f64 / 200.0, mn);
    }
    let mut centre = [0.0; 2];
    for (idx, &(m, steps)) in [(50usize, 375usize), (100, 1500)].iter().enumerate() {
        let (u, hi, lo, r) = grid(m, steps, 600.0);
        centre[idx] = u[m / 2];
        assert!(hi <= 100.0 + 1e-12 && lo >= 20.0 - 1e-12);
        println!("grid h=1/{}, r={:.4}: centre at 600 s {:.4} C; over the run max {:.4}, min {:.4}", m, r, u[m / 2], hi, lo);
    }
    let exact = rod(0.5, 600.0);
    let ratio = (centre[0] - exact) / (centre[1] - exact);
    println!("centre at 600 s: series {:.4} C; grid error ratio {:.2}", exact, ratio);
    assert!((centre[1] - exact).abs() < 0.01 && 3.5 < ratio && ratio < 4.5);
    for k in [1e-3, 5e-4] {
        let res = resid(&rod, 0.3, 600.0, k, 1e4 * k, KAPPA);
        println!("residual u_t - kappa u_xx at (0.3 m, 600 s), dx={:.4} m, dt={:.0} s: {:.2} nK/s", k, 1e4 * k, res * 1e9);
        assert!(res.abs() < 1e-7);
    }
    let lam = KAPPA * PI.powf(2.0); // road 4: the barrier 20 + 80 exp(-lam t) sin(pi x)
    let half = 2f64.ln() / lam;
    let bar = END + PEAK * (-lam * 600.0).exp();
    println!("barrier: decay rate kappa pi^2 = {:.4}e-3 per s, half-life {:.1} s; centre cap at 600 s {:.2} C", lam * 1e3, half, bar);
    println!("barrier factor exp(-{:.4}) = {:.4}; b_1 term at the centre {:.4} K of the rise {:.4} K", lam * 600.0, (-lam * 600.0).exp(), b(1) * (-lam * 600.0).exp(), exact - END);
    let mut ok = true;
    for i in 0..=50 {
        for t in [60.0, 300.0, 600.0, 1800.0] {
            ok &= rod(i as f64 / 50.0, t) <= END + PEAK * (-lam * t).exp() * (PI * i as f64 / 50.0).sin() + 1e-9;
        }
    }
    println!("barrier above the series at 51 points x 4 times: {}", if ok { "yes" } else { "no" });
    assert!(ok && exact < bar);
    let q = (exact - END) / PEAK;
    println!("plate 1 m square, hot square spot: centre at 600 s 20 + 80*{:.4}^2 = {:.4} C, rod {:.4} C", q, END + PEAK * q * q, exact);
    let (_, hi, lo, r) = grid(50, 30, 60.0);
    println!("try: grid h=1/50, r={:.4} > 1/2: after 60 s max {:.1} C, min {:.1} C", r, hi, lo);
    // ---- what breaks ----
    let a = 10.0; // heater: source kappa pi^2 A sin(pi x), start and ends 20 C
    let heater = |x: f64, t: f64| END + a * (1.0 - (-lam * t).exp()) * (PI * x).sin();
    let src = resid(&heater, 0.5, 600.0, 1e-3, 10.0, KAPPA);
    println!("breaks 1, heater: residual = source {:.4} mK/s, formula {:.4} mK/s; centre at 600 s {:.4} C, boundary max 20.0000 C",
             src * 1e3, lam * a * 1e3, heater(0.5, 600.0));
    assert!((src - lam * a).abs() < 1e-6 && heater(0.5, 600.0) > END + 4.0);
    let back = |x: f64, t: f64| (lam * t).exp() * (PI * x).sin();
    let res = resid(&back, 0.5, 600.0, 1e-3, 10.0, -KAPPA);
    println!("breaks 2, time run backward, u_t = -kappa u_xx (residual {:.2} nK/s): 1 K sine bump at 600 s {:.4} K, boundary max 1.0000 K",
             res * 1e9, back(0.5, 600.0));
    assert!(res.abs() < 1e-7 && back(0.5, 600.0) > 1.9);
    let (_, _, c) = tych(1.0, 0.5);
    println!("breaks 3, Tychonoff g'(0.5)/g = 2/0.5^3: series {:.6}, closed form {:.6}", c[1] / c[0], 2.0 / 0.5f64.powf(3.0));
    assert!((c[1] / c[0] - 16.0).abs() < 1e-9 && (2.0 * c[2] / c[0] - (4.0 / 0.5f64.powf(6.0) - 6.0 / 0.5f64.powf(4.0))).abs() < 1e-6);
    for (x, t) in [(0.0, 1.0), (1.0, 0.5), (3.0, 0.3)] {
        let (val, last, _) = tych(x, t);
        let tail = if x != 0.0 { format!("log10 of first omitted term {:.0}", last.abs().log10()) } else { "exact, one term".to_string() };
        println!("  u({:.0} m, {:.1} scaled = {:.1} s) = {:.4} K from a 0 K start; {}", x, t, t * 9009.0, val, tail);
    }
    let (mut p, mut refv, mut fact) = (vec![1.0f64], 0.0, 1.0); // second road at (1 m, 0.5): g^(k)(t) = P_k(1/t) e^(-1/t^2), with
    for k in 0..20 { // P_(k+1)(s) = 2 s^3 P_k(s) - s^2 P_k'(s), summed at s = 1/t = 2
        refv += p.iter().enumerate().map(|(i, a)| a * 2f64.powi(i as i32)).sum::<f64>() * (-4f64).exp() / fact;
        let mut q = vec![0.0; p.len() + 3];
        for (i, a) in p.iter().enumerate() { q[i + 3] += 2.0 * a; q[i + 1] -= i as f64 * a; }
        p = q; fact *= ((2 * k + 1) * (2 * k + 2)) as f64;
    }
    assert!((tych(1.0, 0.5).0 - refv).abs() < 1e-12);
    for k in [0.01, 0.005] {
        let res = resid(&|x, t| tych(x, t).0, 1.0, 0.5, k, k, 1.0);
        println!("  residual u_t - u_xx at (1, 0.5) scaled, step {}: {:.6}", k, res);
        assert!(res.abs() < 10.0 * k * k);
    }
    println!("ALL CHECKS PASS");
}
