// Cox-Ingersoll-Ross: the 5-year zero four ways, and the same bond under Vasicek.
// std only. Random numbers, ODE solver and PDE grid are written here.
use std::f64::consts::PI;

const K: f64 = 0.3; const TH: f64 = 0.05; const SIG: f64 = 0.05; const R0: f64 = 0.04; const T: f64 = 5.0;
const SIG_V: f64 = 0.01; // Vasicek noise: the shelf's house example

fn sq(x: f64) -> f64 { x.powf(2.0) }

// road 1: the closed form; returns (A, B, gamma)
fn cir_ab(tau: f64, k: f64, th: f64, s: f64, two: f64) -> (f64, f64, f64) {
    let g = (k * k + two * s * s).sqrt();
    let e = (g * tau).exp(); let den = (g + k) * (e - 1.0) + 2.0 * g;
    let b = 2.0 * (e - 1.0) / den;
    let a = (2.0 * k * th / (s * s) * (2.0 * g * ((g + k) * tau / 2.0).exp() / den).ln()).exp();
    (a, b, g)
}

fn cir_p(tau: f64, r: f64, k: f64, th: f64, s: f64) -> f64 { let (a, b, _) = cir_ab(tau, k, th, s, 2.0); a * (-b * r).exp() }

fn vas_p(tau: f64, r: f64) -> (f64, f64) {
    let b = (1.0 - (-K * tau).exp()) / K;
    let ln_a = (TH - sq(SIG_V) / (2.0 * K * K)) * (b - tau) - sq(SIG_V) * b * b / (4.0 * K);
    ((ln_a - b * r).exp(), b)
}

// road 2: B' = 1 - kB - s^2 B^2/2, (lnA)' = -k th B, by RK4
fn riccati_p(tau: f64, n: usize) -> f64 {
    let f = |b: f64| 1.0 - K * b - 0.5 * SIG * SIG * b * b;
    let h = tau / n as f64;
    let (mut b, mut ln_a) = (0.0, 0.0);
    for _ in 0..n {
        let k1 = f(b); let k2 = f(b + h * k1 / 2.0); let k3 = f(b + h * k2 / 2.0); let k4 = f(b + h * k3);
        let (b1, b2, b3) = (b + h * k1 / 2.0, b + h * k2 / 2.0, b + h * k3);
        ln_a -= K * TH * h * (b + 2.0 * b1 + 2.0 * b2 + b3) / 6.0;
        b += h * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
    }
    (ln_a - b * R0).exp()
}

// road 3: explicit grid for P_tau = k(th-r)P_r + s^2 r P_rr/2 - rP
fn pde_p(tau: f64, rmax: f64, m: usize, dt: f64) -> f64 {
    let hr = rmax / m as f64;
    let mut u = vec![1.0f64; m + 1];
    for _ in 0..(tau / dt).round() as usize {
        let mut v = u.clone();
        for i in 0..=m {
            let r = i as f64 * hr; let mu = K * (TH - r); let d = 0.5 * SIG * SIG * r;
            let (ur, urr);
            if i == 0 { ur = (u[1] - u[0]) / hr; urr = 0.0; }
            else if i == m { ur = (u[m] - u[m - 1]) / hr; urr = 0.0; }
            else if mu.abs() * hr <= 2.0 * d {
                ur = (u[i + 1] - u[i - 1]) / (2.0 * hr); urr = (u[i + 1] - 2.0 * u[i] + u[i - 1]) / sq(hr);
            } else {
                ur = if mu > 0.0 { (u[i + 1] - u[i]) / hr } else { (u[i] - u[i - 1]) / hr };
                urr = (u[i + 1] - 2.0 * u[i] + u[i - 1]) / sq(hr);
            }
            v[i] = u[i] + dt * (mu * ur + d * urr - r * u[i]);
        }
        u = v;
    }
    u[(R0 / hr).round() as usize]
}

struct Rng(u64); // splitmix64 + Box-Muller
impl Rng {
    fn u(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (1.0 / 9007199254740992.0)
    }
    fn pair(&mut self) -> (f64, f64) {
        let a = 1.0 - self.u(); let b = self.u(); let rad = (-2.0 * a.ln()).sqrt();
        (rad * (2.0 * PI * b).cos(), rad * (2.0 * PI * b).sin())
    }
}

struct Sim { c: Vec<f64>, v: Vec<f64>, rt: Vec<f64>, c0: i64, v0: i64 }

// road 4: paths straight from the SDE, each with an antithetic twin
fn simulate(s: f64, pairs: usize, steps: usize, seed: u64) -> Sim {
    let mut rng = Rng(seed); let dt = T / steps as f64;
    let mut out = Sim { c: vec![], v: vec![], rt: vec![], c0: 0, v0: 0 };
    for _ in 0..pairs {
        let mut zs = Vec::with_capacity(steps);
        for _ in 0..steps / 2 { let (x, y) = rng.pair(); zs.push(x); zs.push(y); }
        for sign in [1.0, -1.0] {
            let (mut rc, mut rv, mut ic, mut iv) = (R0, R0, 0.0, 0.0);
            let (mut hitc, mut hitv) = (false, false);
            for &z in &zs {
                let dw = sign * z * dt.sqrt();
                let nc = rc + K * (TH - rc) * dt + s * rc.max(0.0).sqrt() * dw;
                let nv = rv + K * (TH - rv) * dt + SIG_V * dw;
                ic += 0.5 * (rc + nc.max(0.0)) * dt; iv += 0.5 * (rv + nv) * dt;
                hitc = hitc || nc <= 0.0; hitv = hitv || nv < 0.0;
                rc = nc.max(0.0); rv = nv;
            }
            out.c.push((-ic).exp()); out.v.push((-iv).exp()); out.rt.push(rc);
            out.c0 += hitc as i64; out.v0 += hitv as i64;
        }
    }
    out
}

fn tot(xs: &[f64]) -> f64 { let mut s = 0.0; for &x in xs { s += x; } s }

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let ps: Vec<f64> = xs.chunks(2).map(|p| (p[0] + p[1]) / 2.0).collect();
    let n = ps.len() as f64; let m = tot(&ps) / n;
    let d: Vec<f64> = ps.iter().map(|p| sq(p - m)).collect();
    (m, (tot(&d) / (n - 1.0) / n).sqrt())
}

fn yld(p: f64, t: f64) -> f64 { -p.ln() / t * 100.0 }

fn main() {
    let (a5, b5, g) = cir_ab(T, K, TH, SIG, 2.0);
    let (p1, p2, p3) = (cir_p(T, R0, K, TH, SIG), riccati_p(T, 500), pde_p(T, 0.4, 200, 0.001));
    let sim = simulate(SIG, 5000, 250, 20260928);
    let (p4, se4) = mean_se(&sim.c); let (pv4, sev) = mean_se(&sim.v); let nt = sim.rt.len() as f64; let mt = tot(&sim.rt) / nt;
    let dev: Vec<f64> = sim.rt.iter().map(|x| sq(x - mt)).collect();
    let sdt = (tot(&dev) / (nt - 1.0)).sqrt(); let (pv, bv) = vas_p(T, R0);
    let e = (-K * T).exp();
    let mean_f = TH + (R0 - TH) * e;
    let sd_c = (R0 * sq(SIG) / K * (e - e * e) + TH * sq(SIG) / (2.0 * K) * sq(1.0 - e)).sqrt();
    let sd_v = (sq(SIG_V) / (2.0 * K) * (1.0 - e * e)).sqrt();
    let fail = simulate(0.2, 1000, 250, 20260928);
    let (ag, bg, _) = cir_ab(T, K, TH, SIG, 1.0);
    let den5 = (g + K) * ((g * T).exp() - 1.0) + 2.0 * g; let base5 = 2.0 * g * ((g + K) * T / 2.0).exp() / den5;
    let rows: Vec<(&str, f64)> = vec![
        ("Feller 2*kappa*theta", 2.0 * K * TH), ("Feller sigma^2", SIG * SIG), ("gamma", g), ("e^(gamma T)", (g * T).exp()),
        ("D = (g+k)(e^(gT)-1) + 2g", den5), ("power 2*kappa*theta/sigma^2", 2.0 * K * TH / (SIG * SIG)),
        ("A base 2g e^((g+k)T/2) / D", base5), ("e^(-B(5) r0)", (-b5 * R0).exp()), ("B(5)", b5), ("A(5)", a5), ("1 closed form P(5)", p1), ("2 Riccati by RK4 P(5)", p2),
        ("3 PDE grid P(5)", p3), ("4 Monte Carlo P(5)", p4), ("  Monte Carlo std error", se4),
        ("CIR 5y yield %", yld(p1, T)), ("Vasicek B(5)", bv), ("Vasicek P(5) formula", pv),
        ("Vasicek P(5) Monte Carlo", pv4), ("Vasicek 5y yield %", yld(pv, T)), ("CIR minus Vasicek P(5)", p1 - pv), ("e^(-kappa T)", e),
        ("CIR long yield %", 200.0 * K * TH / (g + K)), ("Vasicek long yield %", 100.0 * (TH - sq(SIG_V) / (2.0 * K * K))),
        ("mean r(5) formula %", 100.0 * mean_f), ("mean r(5) CIR sim %", 100.0 * mt),
        ("sd r(5) CIR formula %", 100.0 * sd_c), ("sd r(5) CIR sim %", 100.0 * sdt), ("sd r(5) Vasicek %", 100.0 * sd_v),
        ("paths below zero, CIR", sim.c0 as f64), ("paths below zero, Vasicek", sim.v0 as f64),
        ("wrong: Vasicek sigma 0.01 in CIR", cir_p(T, R0, K, TH, 0.01)),
        ("wrong: A without its power", (base5.ln() - b5 * R0).exp()),
        ("wrong: gamma without the 2", ag * (-bg * R0).exp()),
        ("wrong: flat e^(-r0 T)", (-R0 * T).exp()),
        ("try: sigma 0.2 P(5)", cir_p(T, R0, K, TH, 0.2)), ("try: sigma 0.2 paths touching 0 of 2000", fail.c0 as f64),
        ("try: r0 0.01 P(5)", cir_p(T, 0.01, K, TH, SIG)), ("try: kappa 1.0 P(5)", cir_p(T, R0, 1.0, TH, SIG))];
    for (name, v) in &rows {
        if name.contains("paths") { println!("{:<40} {:>12}", name, *v as i64) } else { println!("{:<40} {:>12.6}", name, v) }
    }
    let mats = [1.0, 2.0, 3.0, 5.0, 7.0, 10.0, 20.0, 30.0];
    let line = |xs: Vec<String>| xs.join(" ");
    println!("chart maturity    {}", line(mats.iter().map(|t| format!("{:5}", *t as i64)).collect()));
    println!("chart CIR %       {}", line(mats.iter().map(|&t| format!("{:5.2}", yld(cir_p(t, R0, K, TH, SIG), t))).collect()));
    println!("chart Vasicek %   {}", line(mats.iter().map(|&t| format!("{:5.2}", yld(vas_p(t, R0).0, t))).collect()));
    println!("chart rate %      {}", line((0..11).map(|i| format!("{:5}", i)).collect()));
    println!("chart CIR noise % {}", line((0..11).map(|i| format!("{:5.2}", 100.0 * SIG * (i as f64 / 100.0).sqrt())).collect()));
    assert!((p2 - p1).abs() < 1e-10, "RK4 on the Riccati pair must land on the closed form");
    assert!((p3 - p1).abs() < 2e-5, "PDE grid, which never guesses the affine shape, must agree");
    assert!((p4 - p1).abs() < 4.0 * se4, "Monte Carlo from the SDE within four standard errors");
    assert!((pv4 - pv).abs() < 4.0 * sev, "Vasicek on the same draws within four standard errors");
    assert!((mt - mean_f).abs() < 4.0 * mean_se(&sim.rt).1, "simulated mean rate vs the transition law");
    assert!(sim.c0 == 0, "Feller holds: no CIR path touches zero");
    assert!(fail.c0 > 0, "Feller broken (sigma 0.2): some paths do touch zero");
    println!("ALL CHECKS PASS");
}
