// Chooser options -- the same check as chooser_options_check.py, in Rust.  Std only, no crates.
// The normal CDF is a series written out, the root finder is bisection, the integral is
// Simpson's rule, the tree is a loop, the random numbers are splitmix64 with Box-Muller.
use std::f64::consts::PI;

fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height
fn n_cdf(x: f64) -> f64 {                                              // area left of x (Marsaglia)
    if x < -8.0 { return 0.0; }
    if x > 8.0 { return 1.0; }
    let (mut s, mut t, b, mut i) = (x, x, x * x, 3.0);
    while s + t != s { t *= b / i; s += t; i += 2.0; }
    0.5 + s * phi(x)
}

#[derive(Clone, Copy)]
struct M { s: f64, k: f64, r: f64, q: f64, sig: f64, tau: f64, t: f64 }

fn d12(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> (f64, f64) {
    let d1 = ((s / k).ln() + (r - q + 0.5 * sig * sig) * t) / (sig * t.sqrt());
    (d1, d1 - sig * t.sqrt())
}
fn call(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, sig, t);
    s * (-q * t).exp() * n_cdf(d1) - k * (-r * t).exp() * n_cdf(d2)
}
fn put(s: f64, k: f64, r: f64, q: f64, sig: f64, t: f64) -> f64 {
    let (d1, d2) = d12(s, k, r, q, sig, t);
    k * (-r * t).exp() * n_cdf(-d2) - s * (-q * t).exp() * n_cdf(-d1)
}
fn chooser(m: M) -> f64 {                                              // road 1: parity at the choice date
    let M { s, k, r, q, sig, tau, t } = m;
    if tau <= 0.0 { return call(s, k, r, q, sig, t).max(put(s, k, r, q, sig, t)); }
    let kp = k * (-(r - q) * (t - tau)).exp();
    call(s, k, r, q, sig, t) + (-q * (t - tau)).exp() * put(s, kp, r, q, sig, tau)
}

fn bisect<F: Fn(f64) -> f64>(f: F, mut a: f64, mut b: f64) -> f64 {  // a root of f between a and b
    let mut fa = f(a);
    for _ in 0..200 {
        let m = 0.5 * (a + b);
        if (f(m) > 0.0) == (fa > 0.0) { a = m; fa = f(m); } else { b = m; }
    }
    0.5 * (a + b)
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut sum = 0.0;
    for i in 1..n { sum += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * (f(a) + f(b) + sum)
}

// road 2: average max(C, P) at the choice date over the bell curve, split at the kink
fn by_integral(m: M, kcall: f64, kput: f64) -> (f64, f64) {
    let M { s, r, q, sig, tau, t, .. } = m;
    let st = |z: f64| s * ((r - q - 0.5 * sig * sig) * tau + sig * tau.sqrt() * z).exp();
    let gap = |z: f64| call(st(z), kcall, r, q, sig, t - tau) - put(st(z), kput, r, q, sig, t - tau);
    let zs = bisect(gap, -8.0, 8.0);
    let f = |z: f64| call(st(z), kcall, r, q, sig, t - tau).max(put(st(z), kput, r, q, sig, t - tau)) * phi(z);
    ((-r * tau).exp() * (simpson(f, -8.0, zs, 2000) + simpson(f, zs, 8.0, 2000)), st(zs))
}

fn by_tree(m: M, steps: usize) -> f64 {                               // road 3: coin-flip tree
    let M { s, k, r, q, sig, tau, t } = m;
    let dt = t / steps as f64; let u = (sig * dt.sqrt()).exp(); let d = 1.0 / u;
    let p = (((r - q) * dt).exp() - d) / (u - d); let disc = (-r * dt).exp();
    let mid = (steps as f64 * tau / t).round() as usize;
    let st = |j: usize| s * u.powf(j as f64) * d.powf((steps - j) as f64);
    let mut vc: Vec<f64> = (0..=steps).map(|j| (st(j) - k).max(0.0)).collect();
    let mut vp: Vec<f64> = (0..=steps).map(|j| (k - st(j)).max(0.0)).collect();
    for n in (mid + 1..=steps).rev() {
        vc = (0..n).map(|j| disc * (p * vc[j + 1] + (1.0 - p) * vc[j])).collect();
        vp = (0..n).map(|j| disc * (p * vp[j + 1] + (1.0 - p) * vp[j])).collect();
    }
    let mut v: Vec<f64> = vc.iter().zip(&vp).map(|(a, b)| a.max(*b)).collect();
    for n in (1..=mid).rev() { v = (0..n).map(|j| disc * (p * v[j + 1] + (1.0 - p) * v[j])).collect(); }
    v[0]
}

struct Rng(u64);
impl Rng {
    fn unif(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15); let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * 2f64.powi(-53) + 2f64.powi(-54)
    }
}

fn main() {
    let h = M { s: 100.0, k: 100.0, r: 0.05, q: 0.02, sig: 0.20, tau: 0.5, t: 1.0 };
    let (M { s, k, r, q, sig, tau, t }, kc, kq) = (h, 105.0, 95.0); // complex chooser: call 105, put 95

    // road 4: simulate through the choice date to expiry
    let (mut g, paths) = (Rng(20260924), 100000);
    let (mut acc, mut n_call) = ([0.0f64; 4], 0u32);
    for _ in 0..paths {
        let (rad, ang) = ((-2.0 * g.unif().ln()).sqrt(), 2.0 * PI * g.unif());
        let s1 = s * ((r - q - 0.5 * sig * sig) * tau + sig * tau.sqrt() * (rad * ang.cos())).exp();
        let s_t = s1 * ((r - q - 0.5 * sig * sig) * (t - tau) + sig * (t - tau).sqrt() * rad * ang.sin()).exp();
        let pick_call = call(s1, k, r, q, sig, t - tau) > put(s1, k, r, q, sig, t - tau);
        n_call += pick_call as u32;
        let x = (-r * t).exp() * if pick_call { (s_t - k).max(0.0) } else { (k - s_t).max(0.0) };
        let pick_c2 = call(s1, kc, r, q, sig, t - tau) > put(s1, kq, r, q, sig, t - tau);
        let y = (-r * t).exp() * if pick_c2 { (s_t - kc).max(0.0) } else { (kq - s_t).max(0.0) };
        acc[0] += x; acc[1] += x * x; acc[2] += y; acc[3] += y * y;
    }
    let pf = paths as f64;
    let (mc, mc_se) = (acc[0] / pf, ((acc[1] / pf - (acc[0] / pf).powi(2)) / pf).sqrt());
    let (mcx, mcx_se) = (acc[2] / pf, ((acc[3] / pf - (acc[2] / pf).powi(2)) / pf).sqrt());

    let (c, p, v) = (call(s, k, r, q, sig, t), put(s, k, r, q, sig, t), chooser(h));
    let kp = k * (-(r - q) * (t - tau)).exp();
    let (p1, p2) = d12(s, kp, r, q, sig, tau); let (c1, _) = d12(s, k, r, q, sig, t);
    let (pleg, scale) = (put(s, kp, r, q, sig, tau), (-q * (t - tau)).exp());
    let (v_int, s_star) = by_integral(h, k, k); let v_tree = by_tree(h, 2000);
    let (x_int, x_star) = by_integral(h, kc, kq);
    let delta = (chooser(M { s: s + 0.01, ..h }) - chooser(M { s: s - 0.01, ..h })) / 0.02;
    let delta_an = (-q * t).exp() * (n_cdf(c1) - n_cdf(-p1));
    let gamma = (chooser(M { s: s + 0.5, ..h }) - 2.0 * v + chooser(M { s: s - 0.5, ..h })) / 0.25;
    let vega = (chooser(M { sig: sig + 1e-4, ..h }) - chooser(M { sig: sig - 1e-4, ..h })) / 2e-4 / 100.0;
    let rho = (chooser(M { r: r + 1e-4, ..h }) - chooser(M { r: r - 1e-4, ..h })) / 2e-4 / 100.0;
    let theta = chooser(M { tau: tau - 1.0 / 365.0, t: t - 1.0 / 365.0, ..h }) - v;

    let rows: Vec<(&str, f64)> = vec![
        ("house call C(S,K,T)", c), ("house put P(S,K,T)", p),
        ("put leg strike K' = K e^-(r-q)(T-tau)", kp), ("put leg d1", p1), ("put leg d2", p2),
        ("put leg N(-d1)", n_cdf(-p1)), ("put leg N(-d2)", n_cdf(-p2)),
        ("put leg cash half K' e^-r.tau N(-d2)", kp * (-r * tau).exp() * n_cdf(-p2)),
        ("put leg share half S e^-q.tau N(-d1)", s * (-q * tau).exp() * n_cdf(-p1)),
        ("put leg P(S,K',tau)", pleg), ("scale e^-q(T-tau)", scale), ("put leg scaled", scale * pleg),
        ("1 chooser, parity formula", v), ("2 chooser, integral over S_tau", v_int),
        ("3 chooser, tree 2000 steps", v_tree), ("4 chooser, simulation 100000 paths", mc),
        ("  simulation standard error", mc_se), ("critical price, root finder", s_star),
        ("chance of choosing the call, simulation", n_call as f64 / pf), ("  N(d2) of the put leg", n_cdf(p2)),
        ("call plus put, both legs kept", c + p),
        ("greek delta by bump", delta), ("  e^-qT (N(d1 call) - N(-d1 put leg))", delta_an),
        ("greek gamma", gamma), ("greek vega per vol point", vega), ("greek rho per rate point", rho),
        ("greek theta, one day passes", theta),
        ("wrong: put leg struck at K", c + scale * put(s, k, r, q, sig, tau)),
        ("wrong: no e^-q(T-tau) scale", c + pleg),
        ("wrong: no-dividend textbook strike K e^-r(T-tau)", c + put(s, k * (-r * (t - tau)).exp(), r, q, sig, tau)),
        ("wrong: choose today, max(C,P)", c.max(p)),
        ("complex: critical price, root finder", x_star), ("complex: chooser by integral", x_int),
        ("complex: chooser by simulation", mcx), ("  simulation standard error", mcx_se),
        ("complex: floor, better of C(105) and P(95)", call(s, kc, r, q, sig, t).max(put(s, kq, r, q, sig, t))),
        ("complex: ceiling, C(105) plus P(95)", call(s, kc, r, q, sig, t) + put(s, kq, r, q, sig, t)),
        ("try: sigma = 0.40", chooser(M { sig: 0.40, ..h })), ("try: S = 120", chooser(M { s: 120.0, ..h })),
        ("try: S = 120, call alone", call(120.0, k, r, q, sig, t)),
    ];
    for (name, x) in &rows { println!("{:<48} {:>12.6}", name, x); }
    let taus: Vec<f64> = (0..11).map(|i| i as f64 / 10.0).collect();
    let grid: Vec<f64> = (0..9).map(|i| 80.0 + 5.0 * i as f64).collect();
    let line = |label: &str, xs: Vec<String>| println!("{}{}", label, xs.join(" "));
    line("chart, choice date ", taus.iter().map(|x| format!("{:6.1}", x)).collect());
    line("chart, chooser     ", taus.iter().map(|x| format!("{:6.2}", chooser(M { tau: *x, ..h }))).collect());
    line("chart, S at tau    ", grid.iter().map(|x| format!("{:6.0}", x)).collect());
    line("chart, call at tau ", grid.iter().map(|x| format!("{:6.2}", call(*x, k, r, q, sig, t - tau))).collect());
    line("chart, put at tau  ", grid.iter().map(|x| format!("{:6.2}", put(*x, k, r, q, sig, t - tau))).collect());
    line("chart, chooser     ", grid.iter().map(|x| format!("{:6.2}", call(*x, k, r, q, sig, t - tau).max(put(*x, k, r, q, sig, t - tau)))).collect());

    assert!((v - 13.344280).abs() < 5e-7, "parity formula vs the shelf's house number");
    assert!((v_int - v).abs() < 1e-7, "integral of max(C, P) at the choice date vs the parity formula");
    assert!((v_tree - v).abs() < 0.01, "tree within a cent");
    assert!((mc - v).abs() < 3.0 * mc_se, "simulation within 3 standard errors");
    assert!((n_call as f64 / pf - n_cdf(p2)).abs() < 3.0 * (n_cdf(p2) * (1.0 - n_cdf(p2)) / pf).sqrt(), "simulated choice rate vs N(d2)");
    assert!((s_star - kp).abs() < 1e-8, "root-found critical price equals the put leg's strike");
    assert!((x_int - mcx).abs() < 3.0 * mcx_se, "complex chooser: integral vs simulation");
    assert!((delta - delta_an).abs() < 1e-6, "bumped delta vs the two-leg delta");
    println!("ALL CHECKS PASS");
}
