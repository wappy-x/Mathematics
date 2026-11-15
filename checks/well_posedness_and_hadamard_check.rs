// Well posed -- the same check as the Python, in Rust.  No crates.  Road one is
// the closed form for each pattern (mode).  Road two steps the plate on a grid of
// points that never sees exp, forwards and then backwards, and marches Hadamard's
// slope data up the plate by RK4, which never sees sinh.  A centred-difference
// residual checks Hadamard's solution itself.
use std::f64::consts::PI;

const KAPPA: f64 = 1.2e-5; // steel diffusivity (m^2/s, illustrative)
const ELL: f64 = 1.0; // plate side (m)
const HOUR: f64 = 3600.0;
const DAY: f64 = 86400.0;

fn sci(x: f64, k: usize) -> String {
    // 1.80e9: the same digits in Python and Rust
    let mut e = x.abs().log10().floor() as i32;
    let mut m = x / 10f64.powi(e);
    let p = 10f64.powi(k as i32);
    if (m.abs() * p).round() / p >= 10.0 {
        m /= 10.0;
        e += 1;
    }
    format!("{:.*}e{}", k, m, e)
}

fn rate(m: f64, n: f64) -> f64 {
    KAPPA * PI * PI * (m * m + n * n) / (ELL * ELL)
}

fn amp(m: f64, n: f64, tau: f64) -> f64 {
    (rate(m, n) * tau).exp()
}

fn grid_run(nn: usize, m: f64, tau: f64, kk: usize, back: bool, seed: f64) -> f64 {
    let (h, dt, sg) = (ELL / nn as f64, tau / kk as f64, if back { -1.0 } else { 1.0 });
    let fin = (nn - 1) as f64;
    let mut u = vec![vec![0.0f64; nn + 1]; nn + 1];
    for i in 0..=nn {
        for j in 0..=nn {
            let (x, y) = (i as f64 * h, j as f64 * h);
            u[i][j] = (m * PI * x).sin() * (m * PI * y).sin() + seed * (fin * PI * x).sin() * (fin * PI * y).sin();
        }
    }
    let c = sg * KAPPA * dt / (h * h);
    for _ in 0..kk {
        // u(t + dt) = u + dt * kappa * Laplacian(u); back: dt < 0
        let mut v = vec![vec![0.0f64; nn + 1]; nn + 1];
        for i in 1..nn {
            for j in 1..nn {
                v[i][j] = u[i][j] + c * (u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] - 4.0 * u[i][j]);
            }
        }
        u = v;
    }
    let i0 = nn / (2 * m as usize); // a grid point near a peak of the pattern
    let w = if seed != 0.0 { fin } else { m };
    u[i0][i0] / (w * PI * i0 as f64 * h).sin().powi(2)
}

fn rk4_height(k: f64, steps: usize) -> f64 {
    // a'' = k^2 a, a(0) = 0, a'(0) = 1/k; u = a(y) sin(kx)
    let (mut a, mut b, dy) = (0.0f64, 1.0 / k, 1.0 / steps as f64);
    let f = |a: f64, b: f64| (b, k * k * a);
    for _ in 0..steps {
        let k1 = f(a, b);
        let k2 = f(a + dy / 2.0 * k1.0, b + dy / 2.0 * k1.1);
        let k3 = f(a + dy / 2.0 * k2.0, b + dy / 2.0 * k2.1);
        let k4 = f(a + dy * k3.0, b + dy * k3.1);
        a += dy / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        b += dy / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
    }
    a
}

fn r(x: f64, y: f64, k: f64) -> f64 {
    (k * x).sin() * (k * y).sinh() / (k * k)
}

fn lap(d: f64) -> (f64, f64) {
    // u_xx and u_yy by centred differences at (0.3, 0.5), k = 10
    let uxx = (r(0.3 + d, 0.5, 10.0) - 2.0 * r(0.3, 0.5, 10.0) + r(0.3 - d, 0.5, 10.0)) / (d * d);
    (uxx, (r(0.3, 0.5 + d, 10.0) - 2.0 * r(0.3, 0.5, 10.0) + r(0.3, 0.5 - d, 10.0)) / (d * d))
}

fn main() {
    // ---- forward a day: yesterday's 50 C hump, read today ----
    let a11 = amp(1.0, 1.0, DAY);
    println!("(1,1) rate {} per s; one day: exponent {:.2}, factor {}", sci(rate(1.0, 1.0), 4), rate(1.0, 1.0) * DAY, sci(a11, 2));
    println!("50 C hump yesterday -> {} C today; a 0.01 C reading error -> {} C yesterday", sci(50.0 / a11, 2), sci(0.01 * a11, 2));

    // ---- back one hour, pattern by pattern, with a 0.01 C error in each ----
    println!("worked (5,5): pi^2 {:.4}, kappa pi^2 {} per s, x 50 = {} per s, x 3600 s = {:.3}", PI * PI, sci(KAPPA * PI * PI, 4), sci(rate(5.0, 5.0), 4), rate(5.0, 5.0) * HOUR);
    for m in [1.0f64, 2.0, 3.0, 5.0, 10.0] {
        let lt = rate(m, m) * HOUR;
        println!("back 1 h, mode ({},{}), patches {:.0} cm: rate x 1 h {:.3}, factor {}, 0.01 C error -> {} C, forward x{}",
            m, m, 100.0 * ELL / m, lt, sci(lt.exp(), 2), sci(0.01 * lt.exp(), 2), sci((-lt).exp(), 2));
    }
    println!("1e-6 C error in mode (10,10), back 1 h -> {} C", sci(1e-6 * amp(10.0, 10.0, HOUR), 2));
    for m in [100.0f64, 300.0, 1000.0] {
        println!("back 1 s, mode ({},{}), patches {:.0} mm: factor {}", m, m, 1000.0 * ELL / m, sci(amp(m, m, 1.0), 2));
    }

    // ---- road two: the plate on an N x N grid, explicit time steps, no exp ----
    let (g10, g20) = (1.0 / grid_run(10, 2.0, HOUR, 4000, false, 0.0), 1.0 / grid_run(20, 2.0, HOUR, 4000, false, 0.0));
    let exact = rate(2.0, 2.0) * HOUR;
    let (e10, e20) = (exact - g10.ln(), exact - g20.ln());
    let rich = (4.0 * (exact - e20) - (exact - e10)) / 3.0;
    println!("grid forward 1 h, mode (2,2): 1/decay at h = 10 cm {:.3}, at h = 5 cm {:.3}; closed form {:.3}", g10, g20, exact.exp());
    println!("grid exponent short by {:.4} then {:.4}: ratio {:.2} (order 2); extrapolated {:.4} vs {:.4}", e10, e20, e10 / e20, rich, exact);
    let gb = grid_run(20, 2.0, HOUR, 4000, true, 1e-6);
    let step = 1.0 + KAPPA * (HOUR / 4000.0) / (0.05f64 * 0.05) * 8.0 * (19.0 * PI * 0.05 / 2.0).sin().powi(2);
    println!("grid backward 1 h, h = 5 cm, (2,2) plus 1e-6 C in its finest ripple (19,19): ripple {} C; per-step factor {:.5}, predicted {} C",
        sci(gb, 2), step, sci(1e-6 * step.powi(4000), 2));

    // ---- Hadamard: u_xx + u_yy = 0, u(x,0) = 0, u_y(x,0) = sin(kx)/k ----
    let mut had = Vec::new();
    for k in [10.0f64, 20.0, 40.0] {
        let (cf, rk) = (k.sinh() / (k * k), rk4_height(k, 4000));
        had.push((cf, rk));
        println!("Hadamard k = {}: data size {:.3}, at y = 1 m closed form {}, RK4 {}; ratio over data: plain {}, counting 4 derivatives {}",
            k, 1.0 / k, sci(cf, 2), sci(rk, 2), sci(cf * k, 2), sci(cf / (k * k * k), 2));
    }
    println!("as on the wing 08 card: k = 10 gives {:.2}, k = 20 gives {:.0}", had[0].0, had[1].0);
    let (uxx, uyy) = lap(1e-3);
    let (a2, b2) = lap(5e-4);
    let (res, res2) = (uxx + uyy, a2 + b2);
    println!("Hadamard solution, k = 10, at (0.3, 0.5): u_xx {:.4}, u_yy {:.4}, sum {}; half step {}", uxx, uyy, sci(res, 2), sci(res2, 2));

    // ---- chart: log10 of the backward factor, modes (m,m), m = 1..10 ----
    let row = |tau: f64| (1..=10).map(|m| format!("{:.2}", amp(m as f64, m as f64, tau).log10())).collect::<Vec<_>>().join(", ");
    println!("chart, back 1 h: {}", row(HOUR));
    println!("chart, back 10 min: {}", row(600.0));

    assert!((g20 / exact.exp() - 1.0).abs() < 0.04 && (g10 / exact.exp() - 1.0).abs() < 0.15); // grid agrees with closed form
    assert!(e10 / e20 > 3.5 && e10 / e20 < 4.5 && (rich - exact).abs() < 0.005); // at second order in h
    assert!(had.iter().all(|&(cf, rk)| (rk / cf - 1.0).abs() < 1e-8)); // RK4 march = sinh(k)/k^2
    assert!((gb / (1e-6 * step.powi(4000)) - 1.0).abs() < 1e-6); // back-run = its own law
    assert!(res.abs() < 2e-5 * uxx.abs() && res / res2 > 3.8 && res / res2 < 4.2); // it solves Laplace
    assert!(had[2].0 * 40.0 > had[1].0 * 20.0 && had[1].0 * 20.0 > had[0].0 * 10.0 && had[0].0 * 10.0 > 1000.0); // solution over data rises with k
    println!("ALL CHECKS PASS");
}
