// Operator splitting and the Trotter formula -- the same check as the Python, in Rust.  No crates.
// A 100 kg spill drifts and spreads for 1 h in a river reach whose speed rises downstream.
// Roads: step-by-step moment maps against closed-form sums and the leading-error formula;
// an N-cell grid whose exponentials are summed term by term; the commutator against 2 beta B.
use std::f64::consts::PI;
const Q: f64 = 100.0; const C0: f64 = 0.5; const BETA: f64 = 1e-4; // kg, m/s, 1/s
const KAPPA: f64 = 20.0; const W0: f64 = 200.0; const T: f64 = 3600.0; // m^2/s, m, s

fn close(a: f64, b: f64, tol: f64) { assert!((a - b).abs() <= tol * b.abs().max(1.0), "{} {}", a, b); }
fn drift(mu: f64, v: f64, dt: f64) -> (f64, f64) { // the flow x' = C0 + BETA x: moves the centre, stretches the variance
    ((mu + C0 / BETA) * (BETA * dt).exp() - C0 / BETA, v * (2.0 * BETA * dt).exp())
}
fn spread(mu: f64, v: f64, dt: f64) -> (f64, f64) { (mu, v + 2.0 * KAPPA * dt) } // adds 2 kappa dt to the variance

fn run(n: usize, order: &str, t: f64) -> (f64, f64) { // drift then spread, spread then drift, or Strang
    let (mut mu, mut v, dt) = (0.0, W0 * W0, t / n as f64);
    for _ in 0..n {
        (mu, v) = match order {
            "drift-spread" => { let (a, b) = drift(mu, v, dt); spread(a, b, dt) }
            "spread-drift" => { let (a, b) = spread(mu, v, dt); drift(a, b, dt) }
            _ => { let (a, b) = drift(mu, v, dt / 2.0); let (a, b) = spread(a, b, dt); drift(a, b, dt / 2.0) }
        };
    }
    (mu, v)
}
fn phi(z: f64) -> f64 { // normal CDF from the power series of erf
    let (mut s, mut term, mut k) = (0.0, z / 2f64.sqrt(), 0.0);
    while term.abs() > 1e-18 {
        (s, k) = (s + term / (2.0 * k + 1.0), k + 1.0);
        term *= -z * z / 2.0 / k;
    }
    0.5 + s / PI.sqrt()
}
fn l1_gap(va: f64, vb: f64) -> f64 { // L1 distance of two plumes, same mass and centre: each misplaced kg counts twice
    let (sa, sb) = (va.min(vb).sqrt(), va.max(vb).sqrt());
    let z = (2.0 * (sb / sa).ln() * sa * sa * sb * sb / (sb * sb - sa * sa)).sqrt();
    4.0 * Q * (phi(z / sa) - phi(z / sb))
}
fn load(x: f64, mu: f64, v: f64) -> f64 { Q / (2.0 * PI * v).sqrt() * (-(x - mu).powi(2) / (2.0 * v)).exp() }
fn sci(x: f64, d: usize) -> String { // Python-style scientific notation, e.g. 2.6000e-06
    let s = format!("{:.*e}", d, x);
    let (m, e) = s.split_once('e').map(|(m, e)| (m, e.parse::<i32>().unwrap())).unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

// The finite rehearsal: N cells on [-1500, 5500] m, load held at 0 beyond the ends.
// A_N: drift, central fluxes c (u_i + u_i+1)/2.  B_N: spread, kappa (u_i+1 - 2 u_i + u_i-1)/h^2.
struct Grid { n: usize, h: f64, cf: Vec<f64> }
impl Grid {
    fn new(n: usize) -> Grid {
        let h = 7000.0 / n as f64;
        Grid { n, h, cf: (0..=n).map(|i| C0 + BETA * (-1500.0 + i as f64 * h)).collect() }
    }
    fn pad(&self, u: &[f64]) -> Vec<f64> { [&[0.0], u, &[0.0]].concat() }
    fn a(&self, u: &[f64]) -> Vec<f64> {
        let p = self.pad(u);
        let fl: Vec<f64> = (0..=self.n).map(|i| self.cf[i] * (p[i] + p[i + 1]) / 2.0).collect();
        (0..self.n).map(|i| -(fl[i + 1] - fl[i]) / self.h).collect()
    }
    fn b(&self, u: &[f64]) -> Vec<f64> {
        let p = self.pad(u);
        (0..self.n).map(|i| KAPPA * (p[i + 2] - 2.0 * p[i + 1] + p[i]) / (self.h * self.h)).collect()
    }
    fn u0(&self) -> Vec<f64> { (0..self.n).map(|i| load(-1500.0 + (i as f64 + 0.5) * self.h, 0.0, W0 * W0)).collect() }
}
fn expv( // e^(tau op) u: Taylor series on m substeps with tau * size / m <= 0.5
    op: &dyn Fn(&[f64]) -> Vec<f64>, size: f64, tau: f64, u: Vec<f64>) -> Vec<f64> {
    let (m, mut u) = (((tau * size / 0.5).ceil() as usize).max(1), u);
    let amax = |w: &[f64]| w.iter().fold(0.0f64, |a, x| a.max(x.abs()));
    for _ in 0..m {
        let (mut term, mut s, mut k) = (u.clone(), u.clone(), 0);
        while k < 30 && amax(&term) > 1e-17 * amax(&s) {
            k += 1;
            term = op(&term).iter().map(|x| x * tau / m as f64 / k as f64).collect();
            s = s.iter().zip(&term).map(|(a, b)| a + b).collect();
        }
        u = s;
    }
    u
}
fn l1(h: f64, u: &[f64], w: &[f64]) -> f64 { h * u.iter().zip(w).map(|(a, b)| (a - b).abs()).sum::<f64>() }

fn main() {
    // 1. The true flow in closed form: the centre follows the water, the variance obeys v' = 2 beta v + 2 kappa.
    let q = (2.0 * BETA * T).exp();
    let (mu_t, v_t) = ((C0 / BETA) * ((BETA * T).exp() - 1.0), W0 * W0 * q + (KAPPA / BETA) * (q - 1.0));
    println!("true, e^(beta t) {:.6}, e^(2 beta t) {:.6}, centre {:.2} m, width {:.2} m, peak {:.6} kg/m", (BETA * T).exp(), q, mu_t, v_t.sqrt(), load(0.0, 0.0, v_t));
    let ((m1, v1), s600) = (run(1, "drift-spread", 600.0), W0 * W0 * (1200.0 * BETA).exp());
    let v600 = s600 + (KAPPA / BETA) * ((1200.0 * BETA).exp() - 1.0);
    println!("first step, 600 s: c0/beta {:.2} m, kappa/beta {:.2} m^2, start variance {:.2}, e^(beta dt) {:.6}, e^(2 beta dt) {:.6}, centre {:.2} m, stretched variance {:.2}, spread adds {:.2}",
        C0 / BETA, KAPPA / BETA, W0 * W0, (600.0 * BETA).exp(), (1200.0 * BETA).exp(), m1, s600, 2.0 * KAPPA * 600.0);
    println!("first step, 600 s: split variance {:.2}, width {:.2}; true adds {:.2}, true variance {:.2}, width {:.2}", v1, v1.sqrt(), v600 - s600, v600, v600.sqrt());
    // 2. Split steps: iterate the moment maps, compare with the closed-form sums.
    println!("split, n, step (s), scheme, width (m), peak (kg/m), width error (m), L1 gap (kg)");
    for n in [1usize, 6, 60] {
        let (dt, r) = (T / n as f64, (2.0 * BETA * T / n as f64).exp());
        for (order, sum) in [("drift-spread", 1.0), ("spread-drift", r), ("strang", (BETA * dt).exp())] {
            let (mu, v) = run(n, order, T);
            close(mu, mu_t, 1e-10);
            close(v, W0 * W0 * q + 2.0 * KAPPA * dt * sum * (q - 1.0) / (r - 1.0), 1e-12);
            println!("split, {}, {:.0}, {}, {:.2}, {:.6}, {:+.3}, {:.4}", n, dt, order, v.sqrt(), load(0.0, 0.0, v), v.sqrt() - v_t.sqrt(), l1_gap(v, v_t));
        }
    }
    let profiles = [("true", (mu_t, v_t)), ("drift-spread n=1", run(1, "drift-spread", T)), ("spread-drift n=1", run(1, "spread-drift", T))];
    for (name, (mu, v)) in profiles {
        println!("profile, {}, {}", name, (0..9).map(|k| format!("{:.4}", load(500.0 * k as f64, mu, v))).collect::<Vec<_>>().join(", "));
    }
    // 3. Rates: drift-spread's variance error is about kappa dt (e^(2 beta t) - 1); Strang's falls like 1/n^2.
    println!("chart, log10 n, 0, 1, 2, 3");
    for order in ["drift-spread", "strang"] {
        let e: Vec<f64> = [1usize, 10, 100, 1000].iter().map(|&n| (run(n, order, T).1 - v_t).abs()).collect();
        println!("chart, log10 variance error {} (m^2), {}", order, e.iter().map(|x| format!("{:.3}", x.log10())).collect::<Vec<_>>().join(", "));
        close((e[3] / e[2]).log10(), if order == "strang" { -2.0 } else { -1.0 }, 0.01);
        let dt = T / 1000.0;
        let lead = if order == "strang" { KAPPA * BETA * dt * dt * (q - 1.0) / 6.0 } else { KAPPA * dt * (q - 1.0) };
        assert!((e[3] / lead - 1.0).abs() < 2e-3, "{} {}", e[3], lead);
        println!("rate, {}, n = 1000: variance error {:.6} m^2, leading-term formula {:.6} m^2", order, e[3], lead);
    }
    // 4. The grid: exponentials of A_N + B_N, and six split steps, measured by the L1 gap in kg.
    println!("grid, N, h (m), mass (kg), L1 gap (kg) at n = 6: drift-spread, strang; continuum: drift-spread, strang");
    let cont = [l1_gap(run(6, "drift-spread", T).1, v_t), l1_gap(run(6, "strang", T).1, v_t)];
    let mut err140 = 0.0;
    for n in [35usize, 70, 140, 280] {
        let g = Grid::new(n);
        let (sa, sb) = (2.0 * (C0 + BETA * 5500.0) / g.h, 4.0 * KAPPA / g.h / g.h);
        let (fa, fb) = (|u: &[f64]| g.a(u), |u: &[f64]| g.b(u));
        let fab = |u: &[f64]| g.a(u).iter().zip(g.b(u)).map(|(a, b)| a + b).collect::<Vec<f64>>();
        let truth = expv(&fab, sa + sb, T, g.u0());
        let (mut lie, mut st) = (g.u0(), g.u0());
        for _ in 0..6 {
            lie = expv(&fb, sb, 600.0, expv(&fa, sa, 600.0, lie));
            st = expv(&fa, sa, 300.0, expv(&fb, sb, 600.0, expv(&fa, sa, 300.0, st)));
        }
        let (el, es) = (l1(g.h, &lie, &truth), l1(g.h, &st, &truth));
        close(el, cont[0], 0.05 * (70.0 / n as f64).powi(2)); // the grid's own error falls like h^2
        if n == 140 { err140 = el; }
        println!("grid, {}, {:.0}, {:.4}, {:.4}, {:.4}; {:.4}, {:.4}", n, g.h, g.h * truth.iter().sum::<f64>(), el, es, cont[0], cont[1]);
    }
    // 5. The commutator [A_N, B_N] = A_N B_N - B_N A_N: near 2 beta B_N on the plume, yet its norm has no ceiling.
    println!("commutator, N, h (m), L1 norm (1/s^2), largest column away from the ends, times h^2, gap to 2 beta B_N on the plume");
    let (mut bound, mut gap) = (0.0, 0.0);
    for n in [35usize, 70, 140, 280, 560] {
        let g = Grid::new(n);
        let units = (0..n).map(|j| (0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>());
        let cols: Vec<f64> = units.map(|e| g.a(&g.b(&e)).iter().zip(g.b(&g.a(&e))).map(|(a, b)| (a - b).abs()).sum()).collect();
        let (full, inner) = (cols.iter().fold(0.0f64, |a, &x| a.max(x)), cols[3..n - 3].iter().fold(0.0f64, |a, &x| a.max(x)));
        close(inner * g.h * g.h, 2.0 * BETA * KAPPA, 1e-9);
        let u0 = g.u0();
        let cu: Vec<f64> = g.a(&g.b(&u0)).iter().zip(g.b(&g.a(&u0))).map(|(a, b)| a - b).collect();
        let pred: Vec<f64> = g.b(&u0).iter().map(|x| 2.0 * BETA * x).collect();
        gap = cu.iter().zip(&pred).map(|(a, b)| (a - b).abs()).sum::<f64>() / pred.iter().map(|x| x.abs()).sum::<f64>();
        println!("commutator, {}, {:.1}, {}, {}, {:.6}, {:.6}", n, g.h, sci(full, 4), sci(inner, 4), inner * g.h * g.h, gap);
        if n == 140 { bound = T * T / 12.0 * full * Q; }
    }
    assert!(gap < 0.01 && bound > 100.0 * err140);
    println!("bound, N = 140, n = 6: t^2/(2n) x norm x 100 kg = {:.1} kg; actual {:.4} kg", bound, err140);
    // 6. What breaks.  Backward spreading is not a generator: its top grid mode grows without limit as h shrinks.
    println!("backward, N, growth of the top grid mode in one 600 s step, closed form");
    for n in [35usize, 70, 140] {
        let g = Grid::new(n);
        let v: Vec<f64> = (0..n).map(|i| (n as f64 * PI * (i + 1) as f64 / (n + 1) as f64).sin()).collect();
        let back = |u: &[f64]| g.b(u).iter().map(|x| -x).collect::<Vec<f64>>();
        let w = expv(&back, 4.0 * KAPPA / g.h / g.h, 600.0, v.clone());
        let growth = w.iter().map(|x| x.abs()).sum::<f64>() / v.iter().map(|x| x.abs()).sum::<f64>();
        let f = (600.0 * 4.0 * KAPPA * (PI / (2 * n + 2) as f64).cos().powi(2) / g.h / g.h).exp();
        close(growth, f, 1e-9 * f);
        println!("backward, {}, {}, {}", n, sci(growth, 6), sci(f, 6));
    }
    println!("ALL CHECKS PASS");
}
