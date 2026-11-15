// A PDE problem -- the same check as the Python, in Rust.  No crates.  The problem:
// a 1 m square steel plate, edges held at 0 C, starting at 80 sin(pi x) sin(pi y) C,
// obeying u_t = kappa (u_xx + u_yy).  Road one: the closed form.  Road two: an explicit
// grid that never sees it.  Road three: the equation's residual by centred differences.
use std::f64::consts::PI;
const KAPPA: f64 = 1.2e-5; // m^2/s (illustrative)
const L: f64 = 1.0; // m
const U0: f64 = 80.0; // C
const HOUR: f64 = 3600.0; // s

fn rate() -> f64 { 2.0 * PI * PI * KAPPA / (L * L) } // decay rate of the closed form, 1/s

fn exact(x: f64, y: f64, t: f64) -> f64 { // road one: the closed form
    U0 * (-rate() * t).exp() * (PI * x / L).sin() * (PI * y / L).sin()
}

fn grid(n: usize, steps: usize, t_end: f64, insulated: bool) -> f64 { // road two
    let (h, dt) = (L / n as f64, t_end / steps as f64);
    let lam = KAPPA * dt / (h * h); // grid ratio kappa dt / h^2
    assert!(lam <= 0.25); // inside the explicit scheme's stability limit
    let edge = |i: usize, j: usize| i == 0 || i == n || j == 0 || j == n;
    let mut u = vec![vec![0.0f64; n + 1]; n + 1];
    for j in 0..=n {
        for i in 0..=n {
            let v = U0 * (PI * i as f64 / n as f64).sin() * (PI * j as f64 / n as f64).sin();
            u[j][i] = if edge(i, j) && !insulated { 0.0 } else { v };
        }
    }
    for _ in 0..steps {
        let mut new = u.clone();
        for j in 0..=n {
            for i in 0..=n {
                if edge(i, j) && !insulated { continue } // an edge point is data, not equation
                let w = if i > 0 { u[j][i - 1] } else { u[j][1] }; // insulated: mirror across the edge
                let e = if i < n { u[j][i + 1] } else { u[j][n - 1] };
                let s = if j > 0 { u[j - 1][i] } else { u[1][i] };
                let nn = if j < n { u[j + 1][i] } else { u[n - 1][i] };
                new[j][i] = u[j][i] + lam * (w + e + s + nn - 4.0 * u[j][i]);
            }
        }
        u = new;
    }
    u[n / 2][n / 2]
}

fn residual(x: f64, y: f64, t: f64, d: f64) -> (f64, f64) { // road three: centred differences
    let dt = 1.0;
    let ut = (exact(x, y, t + dt) - exact(x, y, t - dt)) / (2.0 * dt);
    let lap = (exact(x + d, y, t) + exact(x - d, y, t) + exact(x, y + d, t) + exact(x, y - d, t)
        - 4.0 * exact(x, y, t)) / (d * d);
    (ut, ut - KAPPA * lap)
}

fn insulated_centre(t: f64, terms: usize) -> (f64, f64) { // cosine series: value, first omitted term
    let tau = KAPPA * t / (L * L);
    let a = |k: usize| if k == 0 { 2.0 / PI } else { -4.0 / (PI * (4.0 * (k * k) as f64 - 1.0)) };
    let decay = |k: usize| (-4.0 * (k * k) as f64 * PI * PI * tau).exp();
    let s: f64 = (0..terms).map(|k| a(k) * (if k % 2 == 0 { 1.0 } else { -1.0 }) * decay(k)).sum();
    (U0 * s * s, a(terms).abs() * decay(terms))
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let problems: Vec<(&str, Vec<(u32, u32, u32)>)> = vec![
        ("cooling, u_t = kappa (u_xx + u_yy)", vec![(0, 0, 1), (2, 0, 0), (0, 2, 0)]),
        ("held steady, u_xx + u_yy = 0", vec![(2, 0, 0), (0, 2, 0)]),
        ("ringing membrane, u_tt = c^2 (u_xx + u_yy)", vec![(0, 0, 2), (2, 0, 0), (0, 2, 0)]),
        ("ringing plate, w_tt + D/(rho H)(w_xxxx + 2w_xxyy + w_yyyy) = 0",
         vec![(0, 0, 2), (4, 0, 0), (2, 2, 0), (0, 4, 0)]),
    ];
    let mut orders = Vec::new();
    for (name, terms) in &problems {
        let total = terms.iter().map(|&(a, b, c)| a + b + c).max().unwrap();
        let in_t = terms.iter().map(|&(_, _, c)| c).max().unwrap();
        let in_space = terms.iter().map(|&(a, b, _)| a + b).max().unwrap();
        orders.push((total, in_t, in_space / 2));
        println!("{}: order {}; {} start field(s); {} condition(s) per edge point", name, total, in_t, in_space / 2);
    }
    let rt = rate();
    println!("kappa {:.1}e-5 m^2/s; decay rate 2 pi^2 kappa / L^2 = {:.5}e-4 per s", KAPPA * 1e5, rt * 1e4);
    let c1 = exact(0.5, 0.5, HOUR);
    println!("exponent at 1 h: {:.6}; factor {:.5}; centre at 1 h: {:.2} C", rt * HOUR, (-rt * HOUR).exp(), c1);
    println!("centre halves after {:.1} s = {:.1} min", 2f64.ln() / rt, 2f64.ln() / rt / 60.0);
    let (mut gs, mut errs) = (Vec::new(), Vec::new());
    for &(n, steps) in &[(10usize, 20usize), (20, 80), (40, 320)] {
        let g = grid(n, steps, HOUR, false);
        gs.push(g);
        errs.push((g - c1).abs());
        println!("grid h = {:.3} m, dt = {:.2} s: centre {:.4} C, error {:.4} C", L / n as f64, HOUR / steps as f64, g, (g - c1).abs());
    }
    let (o1, o2) = ((errs[0] / errs[1]).ln() / 2f64.ln(), (errs[1] / errs[2]).ln() / 2f64.ln());
    println!("observed order: {:.2}, {:.2}", o1, o2);
    let (ut, r1) = residual(0.5, 0.5, HOUR, 0.01);
    let (_, r2) = residual(0.5, 0.5, HOUR, 0.005);
    println!("residual at the centre, 1 h: u_t = {:.4}e-3 C/s; u_t - kappa lap u = {:.4}e-7 at step 0.01 m, {:.4}e-7 at 0.005 m; ratio {:.2}",
             ut * 1e3, r1 * 1e7, r2 * 1e7, r1 / r2);
    let (mut edge_max, mut start_gap) = (0.0f64, 0.0f64);
    for p in 0..=10 {
        for &q in &[0.0, L] {
            for &t in &[0.0, HOUR] { edge_max = edge_max.max(exact(p as f64 / 10.0, q, t).abs()) }
        }
        for q in 0..=10 {
            let (x, y) = (p as f64 / 10.0, q as f64 / 10.0);
            start_gap = start_gap.max((exact(x, y, 0.0) - U0 * (PI * x).sin() * (PI * y).sin()).abs());
        }
    }
    println!("data: every edge value below 1e-12 C: {}; start matches g: {}", yn(edge_max < 1e-12), yn(start_gap < 1e-12));
    let forced = -rt * U0;
    let lap_g = (4.0 * U0 * (PI * 0.501).sin() - 4.0 * U0 * (PI * 0.5).sin()) / 1e-6; // discrete bend of g at the centre
    println!("start rate the equation forces at the centre: {:.6} C/s = {:.4} C/min; from g's bend: {:.6} C/s",
             forced, forced * 60.0, KAPPA * lap_g);
    let (ins, omitted) = insulated_centre(HOUR, 3);
    let gi = grid(40, 320, HOUR, true);
    println!("insulated edges, centre at 1 h: series {:.2} C (3 terms, first omitted {:.1}e-9), grid h = 0.025 m {:.2} C", ins, omitted * 1e9, gi);
    println!("insulated edges, long run: the mean 80 (2/pi)^2 = {:.2} C; series at 12 h {:.2} C",
             U0 * 4.0 / (PI * PI), insulated_centre(12.0 * HOUR, 40).0);
    println!("mistake 1, no start given: u = 0 also fits; centre at 1 h 0.00 C, not {:.2} C", c1);
    println!("mistake 2, no edge rule: insulated edges also fit; centre at 1 h {:.2} C, not {:.2} C", ins, c1);
    println!("mistake 3, start rate 0 added: the equation forces {:.6} C/s; no solution", forced);
    let hours: Vec<f64> = (0..9).map(|k| k as f64 / 2.0).collect();
    let held: Vec<String> = hours.iter().map(|&h| format!("{:.1}", exact(0.5, 0.5, h * HOUR))).collect();
    let ins_c: Vec<String> = hours.iter().map(|&h| format!("{:.1}", insulated_centre(h * HOUR, 40).0)).collect();
    println!("chart held centre: {}", held.join(", "));
    println!("chart insulated centre: {}", ins_c.join(", "));
    assert!(orders == vec![(2, 1, 1), (2, 0, 1), (2, 2, 1), (4, 2, 2)]); // counts known from the equations
    assert!(errs[2] < 0.03 && ((4.0 * gs[2] - gs[1]) / 3.0 - c1).abs() < 0.002); // closed form against the grid
    assert!(1.9 < o1 && o1 < 2.1 && 1.9 < o2 && o2 < 2.1); // second order
    assert!(r1.abs() < 1e-3 * ut.abs() && 3.9 < r1 / r2 && r1 / r2 < 4.1); // residual shrinks as step^2
    assert!((KAPPA * lap_g - forced).abs() < 1e-6 && (ins - gi).abs() < 0.05 && (ins - c1).abs() > 5.0);
    println!("ALL CHECKS PASS");
}
