// Navier-Stokes derivation -- the same check as navier_stokes_derivation_check.py, in Rust.
// Standard library only, no crates.  Part A: Poiseuille flow in the 5 cm pipe solves the
// derived equations, and the integral balances over a 1 m slug close.  Part B: a
// Taylor-Green eddy 5 cm across, its pressure recovered from the velocity alone.
use std::f64::consts::PI;

const RHO: f64 = 998.207; // water at 20 C, kg/m^3
const MU: f64 = 1.0016e-3; // Pa s
const V: f64 = 1.0; // mean speed, m/s
const D: f64 = 0.05; // bore, m
const R: f64 = D / 2.0;
const U: f64 = 1.0; // eddy speed, m/s

fn u_pipe(r: f64) -> f64 { 2.0 * V * (1.0 - (r / R).powi(2)) }
fn g_drop() -> f64 { 8.0 * MU * V / R.powi(2) }

// road 1: the equation's residual by centred differences, Cartesian x, y
fn resid(x: f64, y: f64, h: f64) -> f64 {
    let f = |a: f64, b: f64| u_pipe((a * a + b * b).sqrt());
    let lap = (f(x + h, y) + f(x - h, y) + f(x, y + h) + f(x, y - h) - 4.0 * f(x, y)) / h.powi(2);
    g_drop() + MU * lap
}

fn kk() -> f64 { PI / D }
fn vel(x: f64, y: f64) -> (f64, f64) {
    let k = kk();
    (U * (k * x).sin() * (k * y).cos(), -U * (k * x).cos() * (k * y).sin())
}
fn p_exact(x: f64, y: f64) -> f64 { RHO * U * U / 4.0 * ((2.0 * kk() * x).cos() + (2.0 * kk() * y).cos()) }
const E: f64 = 1e-5;
fn grads(x: f64, y: f64) -> (f64, f64, f64, f64) {
    let ((a, c), (b, d)) = (vel(x + E, y), vel(x - E, y));
    let ((a2, c2), (b2, d2)) = (vel(x, y + E), vel(x, y - E));
    ((a - b) / (2.0 * E), (a2 - b2) / (2.0 * E), (c - d) / (2.0 * E), (c2 - d2) / (2.0 * E))
}
fn dpdx_dpdy(x: f64, y: f64) -> (f64, f64) {
    let (u, v) = vel(x, y);
    let (ux, uy, vx, vy) = grads(x, y);
    (-RHO * (u * ux + v * uy), -RHO * (u * vx + v * vy))
}
fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, m: usize) -> f64 {
    let mut s = f(a) + f(b);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * (b - a) / m as f64); }
    s * (b - a) / (3.0 * m as f64)
}

// periodic box 2D x 2D, -Lap p = rho * sum d_i u_j d_j u_i, solved by SOR
fn poisson(n: usize, sign: f64) -> (f64, f64) {
    let l = 2.0 * D;
    let hh = l / n as f64;
    let k = kk();
    let xs: Vec<f64> = (0..n).map(|i| i as f64 * hh).collect();
    let mut s = vec![vec![0.0; n]; n];
    for i in 0..n {
        for j in 0..n {
            let (cx, sx, cy, sy) = ((k * xs[i]).cos(), (k * xs[i]).sin(), (k * xs[j]).cos(), (k * xs[j]).sin());
            let (ux, uy, vx, vy) = (U * k * cx * cy, -U * k * sx * sy, U * k * sx * sy, -U * k * cx * cy);
            s[i][j] = sign * RHO * (ux * ux + 2.0 * uy * vx + vy * vy);
        }
    }
    let mut p = vec![vec![0.0; n]; n];
    let w = 2.0 / (1.0 + (2.0 * PI / n as f64).sin());
    for _sweep in 0..5000 {
        let mut big: f64 = 0.0;
        for i in 0..n {
            for j in 0..n {
                let nb = p[(i + 1) % n][j] + p[(i + n - 1) % n][j] + p[i][(j + 1) % n] + p[i][(j + n - 1) % n];
                let new = (nb + hh * hh * s[i][j]) / 4.0;
                let d = w * (new - p[i][j]);
                p[i][j] += d;
                big = big.max(d.abs());
            }
        }
        if big < 1e-11 { break; }
    }
    let mut mean = 0.0;
    for row in &p { let rs: f64 = row.iter().sum(); mean += rs; }
    mean /= (n * n) as f64;
    let mut err: f64 = 0.0;
    for i in 0..n { for j in 0..n { err = err.max((p[i][j] - mean - p_exact(xs[i], xs[j])).abs()); } }
    (p[n / 4][n / 4] - mean, err)
}

fn main() {
    let nu = MU / RHO;
    let g = g_drop();
    let (res1, res2) = (resid(0.01, 0.005, 1e-3), resid(0.01, 0.005, 5e-4));
    let n = 2000;
    let (mut q, mut mom) = (0.0, 0.0);
    for i in 0..n {
        let (r, dr) = ((i as f64 + 0.5) * R / n as f64, R / n as f64);
        q += u_pipe(r) * 2.0 * PI * r * dr;
        mom += RHO * u_pipe(r).powi(2) * 2.0 * PI * r * dr;
    }
    let h = 1e-6;
    let tau_w = -MU * (u_pipe(R + h) - u_pipe(R - h)) / (2.0 * h);
    let (f_p, f_w) = (g * PI * R.powi(2) * 1.0, tau_w * 2.0 * PI * R * 1.0);
    let re = V * D / nu;
    let f_bl = 0.3164 * re.powf(-0.25);
    let g_turb = f_bl * RHO * V.powi(2) / (2.0 * D);

    println!("nu (mm^2/s)                      {:12.6}", nu * 1e6);
    println!("Re = V D / nu                    {:12.1}", re);
    println!("u_max on the axis (m/s)          {:12.4}", u_pipe(0.0));
    println!("G = 8 mu V / R^2 (Pa/m)          {:12.4}", g);
    println!("residual, h = 1 mm (N/m^3)       {:>12}", sci(res1));
    println!("residual, h = 0.5 mm (N/m^3)     {:>12}", sci(res2));
    println!("Q by rings (L/s)                 {:12.6}", q * 1000.0);
    println!("Q = pi R^2 V (L/s)               {:12.6}", PI * R * R * V * 1000.0);
    println!("mass through each end (kg/s)     {:12.6}", RHO * q);
    println!("momentum flux by rings (N)       {:12.6}", mom);
    println!("momentum flux 4/3 rho V^2 A (N)  {:12.6}", 4.0 / 3.0 * RHO * V * V * PI * R * R);
    println!("wall shear tau_w (Pa)            {:12.6}", tau_w);
    println!("pressure force on slug (N)       {:12.6}", f_p);
    println!("wall friction on slug (N)        {:12.6}", f_w);
    println!("Blasius f                        {:12.6}", f_bl);
    println!("turbulent drop (Pa/m)            {:12.4}", g_turb);
    println!("turbulent / laminar              {:12.4}", g_turb / g);
    println!("wrong: mu = 0 (Pa/m)             {:12.4}", 8.0 * 0.0 * V / R.powi(2));
    println!("wrong: 1 m/s as centre (Pa/m)    {:12.4}", 4.0 * MU * V / R.powi(2));
    println!("try: V = 2 m/s (Pa/m), Re        {:12.4} {:10.1}", 16.0 * MU / R.powi(2), 2.0 * re);
    println!("try: D = 10 cm (Pa/m)            {:12.4}", 8.0 * MU * V / 0.05f64.powi(2));
    let rs: Vec<String> = (0..11).map(|i| format!("{:5}", -25 + 5 * i)).collect();
    println!("chart, r (mm)  {}", rs.join(" "));
    let us: Vec<String> = (0..11).map(|i| format!("{:5.2}", u_pipe((-25 + 5 * i) as f64 / 1000.0))).collect();
    println!("chart, u (m/s) {}", us.join(" "));

    let dp_line = simpson(|x| dpdx_dpdy(x, 0.0).0, 0.0, R, 200) + simpson(|y| dpdx_dpdy(R, y).1, 0.0, R, 200);
    let (pc16, err16) = poisson(16, 1.0);
    let (pc32, err32) = poisson(32, 1.0);
    let (pc64, err64) = poisson(64, 1.0);
    let (pc_wrong, _) = poisson(32, -1.0);
    let gr = grads(0.0, 0.0);
    let divrate = (gr.0.powi(2) + gr.3.powi(2) + 2.0 * gr.1 * gr.2).abs();
    let k = kk();

    println!("TG p at eddy centre, exact (Pa)  {:12.4}", p_exact(R, R));
    println!("TG p at corner, exact (Pa)       {:12.4}", p_exact(0.0, 0.0));
    println!("TG centre - corner, exact (Pa)   {:12.4}", p_exact(R, R) - p_exact(0.0, 0.0));
    println!("TG centre - corner, line (Pa)    {:12.4}", dp_line);
    println!("TG centre, Poisson N=16 (Pa)     {:12.4}", pc16);
    println!("TG centre, Poisson N=32 (Pa)     {:12.4}", pc32);
    println!("TG centre, Poisson N=64 (Pa)     {:12.4}", pc64);
    println!("TG max error N=16, 32, 64 (Pa)   {:12.4} {:10.4} {:10.4}", err16, err32, err64);
    println!("TG observed order 16-32, 32-64   {:12.4} {:10.4}", (err16 / err32).ln() / 2f64.ln(), (err32 / err64).ln() / 2f64.ln());
    println!("wrong: Poisson sign flipped (Pa) {:12.4}", pc_wrong);
    println!("no pressure: d(div u)/dt (1/s^2) {:12.1}", divrate);
    println!("no pressure: div u at 1 ms (1/s) {:12.4}", divrate * 1e-3);

    assert!((re - 49830.6).abs() < 0.1, "Reynolds number of the house pipe");
    assert!(res1.abs() < 1e-6 * g && res2.abs() < 1e-5 * g, "Poiseuille solves the equation");
    assert!((q - PI * R * R * V).abs() < 1e-9, "ring sum against the closed-form flow rate");
    assert!((mom - 4.0 / 3.0 * RHO * V * V * PI * R * R).abs() < 1e-6, "momentum flux by rings vs formula");
    assert!((f_p - f_w).abs() < 1e-9, "pressure force balances wall friction on the slug");
    assert!((dp_line - (p_exact(R, R) - p_exact(0.0, 0.0))).abs() < 1e-4, "pressure from momentum");
    assert!((pc32 - p_exact(R, R)).abs() < 0.02 * RHO, "Poisson pressure at the eddy centre");
    let ord = (err32 / err64).ln() / 2f64.ln();
    assert!(ord > 1.9 && ord < 2.1, "second-order grid");
    assert!((divrate - 2.0 * U * U * k * k).abs() < 0.1, "divergence growth without pressure");
    println!("ALL CHECKS PASS");
}

// Python's {:.2e} format: two decimals, signed two-digit exponent
fn sci(x: f64) -> String {
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}
