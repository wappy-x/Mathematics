// Three families -- the check behind the card.  Rust std only, no crates.
// One steel bar, h = 0.01 m.  Heat (parabolic): explicit, backward Euler and Crank-Nicolson
// steps against the exact Fourier series, all along the bar.  Sound (hyperbolic): leapfrog against the
// exact standing wave, and backward Euler steps against their mode formula.  A steel plate
// (elliptic): Jacobi sweeps against the exact centre value 25 C and the rate cos(pi h).
use std::f64::consts::PI;
const ALPHA: f64 = 1.2e-5; // diffusivity of steel, m^2/s (illustrative)
const H: f64 = 0.01; // grid spacing in m
const N: usize = 100; // intervals along the 1 m bar
fn c_speed() -> f64 { (200e9f64 / 7850.0).sqrt() } // sound speed in steel, m/s: sqrt(stiffness / density) (illustrative)
fn sci(x: f64) -> String { format!("{:.2e}", x) } // e-notation with the same digits in Python and Rust
fn family(a: f64, b: f64, cc: f64) -> (f64, &'static str) {
    let d = b * b - 4.0 * a * cc; // the sign of B^2 - 4AC
    (d, if d > 0.0 { "hyperbolic" } else if d == 0.0 { "parabolic" } else { "elliptic" })
}
fn lam(k: usize, h: f64) -> f64 { 4.0 / (h * h) * (k as f64 * PI * h / 2.0).sin().powi(2) } // grid mode k: rate of the 3-point bend
fn thomas(a: f64, b: f64, c: f64, d: &[f64]) -> Vec<f64> {
    let (m, mut cp, mut dp) = (d.len(), vec![0.0; d.len()], vec![0.0; d.len()]);
    (cp[0], dp[0]) = (c / b, d[0] / b);
    for i in 1..m {
        let den = b - a * cp[i - 1];
        (cp[i], dp[i]) = (c / den, (d[i] - a * dp[i - 1]) / den);
    }
    let mut x = dp.clone();
    for i in (0..m - 1).rev() { x[i] = dp[i] - cp[i] * x[i + 1]; }
    x
}
fn maxabs(u: &[f64]) -> f64 { u.iter().fold(0.0, |m, x| if x.abs() > m { x.abs() } else { m }) }
fn series(x: f64, t: f64) -> f64 { // the exact temperature: Fourier series of the 100 C start
    (1..400usize).step_by(2).map(|k| { let kf = k as f64; 400.0 / PI / kf * (kf * PI * x).sin() * (-ALPHA * (kf * PI).powi(2) * t).exp() }).sum()
}
fn heat_explicit(dt: f64) -> Vec<f64> { // each point moves toward its neighbours, one level back
    let (mut u, r) = (vec![100.0; N + 1], ALPHA * dt / (H * H));
    (u[0], u[N]) = (0.0, 0.0);
    for _ in 0..(3600.0 / dt).round() as usize {
        let mut v = vec![0.0; N + 1];
        for j in 1..N { v[j] = u[j] + r * (u[j - 1] - 2.0 * u[j] + u[j + 1]); }
        u = v;
    }
    u
}
fn heat_implicit(dt: f64, th: f64, t_end: f64) -> Vec<f64> { // th 1: backward Euler, 0.5: Crank-Nicolson; one solve per step
    let (mut u, r) = (vec![100.0; N + 1], ALPHA * dt / (H * H));
    let s = (1.0 - th) * r;
    (u[0], u[N]) = (0.0, 0.0);
    for _ in 0..(t_end / dt).round() as usize {
        let rhs: Vec<f64> = (1..N).map(|j| u[j] + s * (u[j - 1] - 2.0 * u[j] + u[j + 1])).collect();
        u = [vec![0.0], thomas(-th * r, 1.0 + 2.0 * th * r, -th * r, &rhs), vec![0.0]].concat();
    }
    u
}
fn report(name: &str, u: &[f64], bar: &[f64]) -> (f64, f64) { // the middle, its true error, the largest true error along the bar
    let e: Vec<f64> = (0..=N).map(|j| u[j] - bar[j]).collect();
    let j = (0..=N).fold(0, |b, i| if e[i].abs() > e[b].abs() { i } else { b });
    println!("heat {}: middle {:.4}, error {:+.4}; largest error {:.4} C at x = {:.2} m", name, u[N / 2], e[N / 2], e[j].abs(), j as f64 / N as f64);
    (e[N / 2], e[j].abs())
}
fn bend(u: &[f64], j: usize) -> f64 { (u[j - 1] - 2.0 * u[j] + u[j + 1]) / (H * H) }
fn leapfrog(nu: f64, steps: usize) -> (f64, f64) {
    let c = c_speed();
    let dt = nu * H / c;
    let mut old: Vec<f64> = (0..=N).map(|j| if j < N { (PI * j as f64 * H).sin() } else { 0.0 }).collect();
    let mut now = vec![0.0; N + 1];
    for j in 1..N { now[j] = old[j] + dt * dt / 2.0 * c * c * bend(&old, j); }
    for _ in 0..steps - 1 {
        let mut new = vec![0.0; N + 1];
        for j in 1..N { new[j] = 2.0 * now[j] - old[j] + dt * dt * c * c * bend(&now, j); }
        (old, now) = (now, new);
    }
    (now[N / 2], maxabs(&now))
}
fn sound_implicit(per: usize) -> (f64, f64) {
    let c = c_speed();
    let dt = 2.0 / c / per as f64;
    let k = (c * dt / H).powi(2);
    let mut u: Vec<f64> = (1..N).map(|j| (PI * j as f64 * H).sin()).collect();
    let mut v = vec![0.0; N - 1];
    for _ in 0..per {
        let rhs: Vec<f64> = (0..N - 1).map(|i| u[i] + dt * v[i]).collect();
        let u1 = thomas(-k, 1.0 + 2.0 * k, -k, &rhs);
        v = (0..N - 1).map(|i| (u1[i] - u[i]) / dt).collect();
        u = u1;
    }
    let w = c * lam(1, H).sqrt();
    let m = N / 2 - 1; ((u[m].powi(2) + (v[m] / w).powi(2)).sqrt(), (1.0 + (w * dt).powi(2)).powf(-(per as f64) / 2.0))
}
fn jacobi(m: usize, marks: &[usize]) -> Vec<(usize, f64)> {
    let mut u = vec![vec![0.0; m + 1]; m + 1];
    for i in 1..m { u[m][i] = 100.0; }
    let mut out = vec![];
    for s in 1..=*marks.iter().max().unwrap() {
        let mut new = u.clone();
        for j in 1..m {
            for i in 1..m { new[j][i] = (u[j][i - 1] + u[j][i + 1] + u[j - 1][i] + u[j + 1][i]) / 4.0; }
        }
        u = new;
        if marks.contains(&s) { out.push((s, u[m / 2][m / 2])); }
    }
    out
}
fn main() {
    let c = c_speed();
    // 1. Classify from the coefficients of u_xx, u_xy, u_yy (time plays y)
    let cases = [("heat in the bar, alpha u_xx - u_t", ALPHA, 0, 0), ("sound in the bar, c^2 u_xx - u_tt", c * c, 0, -1),
        ("steady plate, u_xx + u_yy", 1.0, 0, 1), ("Black-Scholes, S = 100, sigma = 0.2", 0.5 * 0.04 * 100f64.powi(2), 0, 0)];
    let mut kinds = vec![];
    for (name, a, b, cc) in cases {
        let (d, k) = family(a, b as f64, cc as f64);
        kinds.push(k);
        println!("{}: A {}, B {}, C {}, B^2 - 4AC {} -> {}", name, sci(a), b, cc, sci(d), k);
    }
    // 2. Grid modes and the two explicit step limits
    let (l1, lmax) = (lam(1, H), lam(N - 1, H));
    println!("grid modes, h = 0.01: slowest rate {:.6} (pi^2 = {:.6}), fastest {:.2} (4/h^2 = {:.0})", l1, PI * PI, lmax, 4.0 / (H * H));
    let (w1, wmax) = (c * l1.sqrt(), c * lmax.sqrt());
    println!("sound rings at: slowest {:.0} rad/s, fastest {:.0} rad/s, spread {:.0}", w1, wmax, wmax / w1);
    let (dt_heat, dt_heat_mode) = (H * H / (2.0 * ALPHA), 2.0 / (ALPHA * lmax));
    println!("heat: explicit limit h^2/(2 alpha) = {:.4} s (fastest mode allows {:.4} s); slowest decay time {:.0} s, fastest {:.2} s; spread of rates {:.0}",
        dt_heat, dt_heat_mode, 1.0 / (ALPHA * l1), 1.0 / (ALPHA * lmax), lmax / l1);
    let (dt_wave, period) = (H / c, 2.0 / c);
    println!("sound: c = {:.1} m/s, explicit limit h/c = {:.4} us; ring period {:.2} us = {:.0} steps", c, dt_wave * 1e6, period * 1e6, period / dt_wave);
    // 3. Heat: one hour of cooling, three roads; true errors at the middle and at the worst point of the bar
    let bar: Vec<f64> = (0..=N).map(|j| series(j as f64 / N as f64, 3600.0)).collect();
    println!("heat middle at 1 h: exact series {:.4} C", bar[N / 2]);
    let ex4 = report("explicit dt 4 s (900 steps)", &heat_explicit(4.0), &bar);
    let be60 = report("backward Euler dt 60 s (60 steps)", &heat_implicit(60.0, 1.0, 3600.0), &bar);
    let be4 = report("backward Euler dt 4 s (900 steps)", &heat_implicit(4.0, 1.0, 3600.0), &bar);
    let cn60 = report("Crank-Nicolson dt 60 s (60 steps)", &heat_implicit(60.0, 0.5, 3600.0), &bar);
    report("backward Euler dt 600 s (6 steps)", &heat_implicit(600.0, 1.0, 3600.0), &bar);
    let blow = maxabs(&heat_explicit(4.5));
    let mids: Vec<f64> = [1800.0, 5400.0].iter().map(|&t| heat_implicit(60.0, 1.0, t)[N / 2] - series(0.5, t)).collect();
    println!("heat backward Euler dt 60 s, middle error at 30 min {:+.4}, at 90 min {:+.4}", mids[0], mids[1]);
    let fl = [900 * 99 * 5, 60 * (8 * 99 - 7), 900 * (8 * 99 - 7), 60 * (5 * 99 + 8 * 99 - 7)];
    println!("heat flops: explicit 900 x 99 x 5 = {}; backward Euler 60 x (8 x 99 - 7) = {}, 900 x 785 = {}; Crank-Nicolson 60 x (5 x 99 + 785) = {}; explicit / Crank-Nicolson {:.2}; r at 4 s {:.2}",
        fl[0], fl[1], fl[2], fl[3], fl[0] as f64 / fl[3] as f64, ALPHA * 4.0 / (H * H));
    println!("heat explicit dt 4.5 s = {:.2} x limit (r = {:.2}): largest value after 1 h {} C; fastest mode x{:.4} per step",
        4.5 / dt_heat, ALPHA * 4.5 / (H * H), sci(blow), (1.0 - ALPHA * 4.5 * lmax).abs());
    // 4. Sound: half a period of leapfrog, then backward Euler steps over one period
    let (mid, _) = leapfrog(0.5, 200);
    let (_, wild) = leapfrog(1.05, 190);
    println!("sound leapfrog cdt/h = 0.5 (dt {:.4} us), 200 steps to half a period: middle {:.10} um (exact -1), error {}",
        0.5 * dt_wave * 1e6, mid, sci(mid + 1.0));
    println!("sound leapfrog cdt/h = 1.05, 190 steps: largest value {} um", sci(wild));
    for per in [10, 100, 1000] {
        let (grid, formula) = sound_implicit(per);
        println!("sound backward Euler, {} steps per period: amplitude after one period {:.6} (mode formula {:.6})", per, grid, formula);
    }
    // 5. Plate: no time; Jacobi sweeps toward the exact centre 25 C (four rotated copies add to 100)
    let plate = jacobi(20, &[100, 400, 500, 1200]);
    let list: Vec<String> = plate.iter().map(|(s, v)| format!("{}: {:.6}", s, v)).collect();
    println!("plate h = 0.05, centre after sweeps: {}", list.join(", "));
    let rate = ((25.0 - plate[2].1) / (25.0 - plate[1].1)).powf(0.01);
    println!("plate error shrinks x{:.8} per sweep; cos(pi h) = {:.8}", rate, (PI * 0.05).cos());
    let sw: Vec<f64> = [0.05, 0.025, 0.01].iter().map(|hh: &f64| (1e6f64.ln() / -(PI * hh).cos().ln()).ceil()).collect();
    println!("sweeps to cut the error a millionfold: h = 0.05 {}, 0.025 {}, 0.01 {}; estimate {:.2}/h^2 = {:.0} at h = 0.05 (361 unknowns)",
        sw[0], sw[1], sw[2], 2.0 * 1e6f64.ln() / (PI * PI), 2.0 * 1e6f64.ln() / (PI * 0.05).powi(2));
    println!("halve h: heat explicit steps per hour {} -> {}; sound steps per period {:.0} -> {:.0}; plate sweeps {} -> {}",
        (3600.0 / dt_heat).ceil(), (3600.0 / (H * H / 8.0 / ALPHA)).ceil(), period / dt_wave, 2.0 * period / dt_wave, sw[0], sw[1]);
    let xs: Vec<String> = (0..3).map(|p| (60 + 120 * p).to_string()).collect();
    println!("figure, panels centre x {}; rows y 90, 120, 150; spacing 30 (one h or one dt)", xs.join(", "));
    assert!(kinds == ["parabolic", "hyperbolic", "elliptic", "parabolic"]);
    assert!(ex4.0.abs() <= ex4.1 && ex4.1 < 0.02 && cn60.1 < 0.01 && be60.1 > 0.1); // explicit and Crank-Nicolson land on the series
    assert!(be60.1 / be4.1 > 12.0 && be60.1 / be4.1 < 18.0 && be60.0.abs() < 0.01 && 0.01 < -mids[0]); // backward Euler: first order; lucky middle
    assert!(blow > 1e10 && (1.0 - ALPHA * 4.5 * lmax).abs() > 1.0); // over the limit: the fastest mode grows
    assert!(dt_heat_mode / dt_heat > 1.0 && dt_heat_mode / dt_heat < 1.001); // the mode limit sits just above h^2/(2 alpha)
    assert!((mid + 1.0).abs() < 1e-6 && wild > 1e10); // leapfrog: exact inside h/c, wild outside
    assert!([10, 100].iter().all(|&p| { let (g, f) = sound_implicit(p); (g - f).abs() < 1e-9 })); // grid run = mode formula
    assert!((plate[3].1 - 25.0).abs() < 1e-4 && (rate - (PI * 0.05).cos()).abs() < 1e-8); // superposition and Jacobi's rate
    println!("ALL CHECKS PASS");
}
