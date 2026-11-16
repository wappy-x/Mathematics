// The energy inequality, and the gap it leaves in three dimensions -- the same
// check as the Python, in Rust.  No crates.  Water (nu = 1.0e-6 m^2/s) in a 5 cm
// periodic cell, the size of the pipe's largest eddies; three crossing velocity
// waves, two of 1 m/s and one of sqrt(2) m/s.
// Every integral is a grid sum of trigonometric products, exact once the grid
// beats the highest frequency; derivatives are taken by hand, mode by mode.
use std::f64::consts::PI;
const L: f64 = 0.05; const U: f64 = 1.0; const NU: f64 = 1.0e-6; const RHO: f64 = 1000.0;
const K: f64 = 1.0; // illustrative constant
type Mode = ([f64; 3], [f64; 3], f64); // (amplitude direction, wave numbers / k0, phase)

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn e(x: f64, p: usize) -> String { format!("{:.*e}", p, x) }

// returns E, y, |lap u|^2, S, W, T, int u.lap u, pressure term
fn integrals(flow: &[Mode], d: i32, lam: f64) -> [f64; 8] {
    let (n, k0) = (8usize, 2.0 * PI / L);
    let h = L / lam / n as f64;
    let mut t = [0.0f64; 8];
    for i in 0..n { for j in 0..n { for l in 0..(if d == 3 { n } else { 1 }) {
        let x = [i as f64 * h, j as f64 * h, l as f64 * h];
        let (mut u, mut g, mut lap) = ([0.0f64; 3], [[0.0f64; 3]; 3], [0.0f64; 3]);
        for (a, kv, ph) in flow {
            let q: Vec<f64> = kv.iter().map(|c| lam * k0 * c).collect();
            let th = q[0] * x[0] + q[1] * x[1] + q[2] * x[2] + ph;
            let (c, s, qq) = (th.cos(), th.sin(), q.iter().map(|v| v * v).sum::<f64>());
            for i in 0..3 {
                u[i] += lam * U * a[i] * c;
                lap[i] -= lam * U * a[i] * qq * c;
                for m in 0..3 { g[i][m] -= lam * U * a[i] * q[m] * s; }
            }
        }
        let adv: Vec<f64> = (0..3).map(|c| (0..3).map(|m| u[m] * g[c][m]).sum()).collect();
        let w = [g[2][1] - g[1][2], g[0][2] - g[2][0], g[1][0] - g[0][1]]; // vorticity
        let gp = [-k0 * (k0 * x[0]).sin() * (k0 * x[1]).cos(), // grad of a test pressure
                  -k0 * (k0 * x[0]).cos() * (k0 * x[1]).sin(), 0.0];
        t[0] += 0.5 * u.iter().map(|v| v * v).sum::<f64>();
        for a in 0..3 { for b in 0..3 {
            t[1] += g[a][b] * g[a][b];
            t[4] += w[a] * 0.5 * (g[a][b] + g[b][a]) * w[b];
        } }
        for c in 0..3 {
            t[2] += lap[c] * lap[c]; t[3] += adv[c] * lap[c]; t[5] += adv[c] * u[c];
            t[6] += u[c] * lap[c]; t[7] += gp[c] * u[c];
        }
    } } }
    t.map(|v| v * h.powi(d))
}

fn main() {
    let k0 = 2.0 * PI / L;
    let flow3: [Mode; 3] = [([0., 0., 1.], [1., 0., 0.], 0.0), ([1., 0., 0.], [0., 1., 1.], 0.0), ([1., -1., 0.], [1., 1., 1.], -PI / 2.0)];
    let flow2: [Mode; 3] = [([0., 1., 0.], [1., 0., 0.], 0.0), ([1., 0., 0.], [0., 1., 0.], 0.0), ([1., -1., 0.], [1., 1., 0.], -PI / 2.0)];
    let squeeze: [Mode; 3] = [([-1., 0., 0.], [1., 0., 0.], 0.0), flow3[1], flow3[2]]; // first amplitude along its k
    let (r3, r2, bad) = (integrals(&flow3, 3, 1.0), integrals(&flow2, 2, 1.0), integrals(&squeeze, 3, 1.0));
    let re = U * L / NU;
    println!("house: L = {} m, U = {:.1} m/s, nu = {} m^2/s, Re = UL/nu = {:.0}", L, U, e(NU, 1), re);
    for (name, r, unit) in [("3D", r3, "m^5/s^2"), ("2D", r2, "m^4/s^2 per m of depth")] {
        println!("{}: energy E0 = {} {}; enstrophy y0 = {:.4}; |lap u|^2 = {:.1}", name, e(r[0], 4), unit, r[1], r[2]);
    }
    println!("3D energy in joules (x rho = 1000 kg/m^3): {:.4} J; budget E0/nu = {:.1} m^3/s", RHO * r3[0], r3[0] / NU);
    for (name, r) in [("3D", r3), ("2D", r2)] {
        let sc = r[1] * k0 * U; // natural size of a cubic term
        println!("{}: transport term ~0: {}; pressure term ~0: {}; int u.lap u = -y0: {}", name,
                 yn(r[5].abs() < 1e-12 * sc), yn(r[7].abs() < 1e-12 * sc), yn((r[6] + r[1]).abs() < 1e-12 * r[1]));
    }
    println!("3D stretching S = {:.4} m^3/s^3; as vorticity times strain: {:.4} m^3/s^3", r3[3], r3[4]);
    println!("2D stretching ~0: {}", yn(r2[3].abs() < 1e-12 * r2[1] * k0 * U));
    println!("3D start: dy/dt = 2S - 2 nu |lap u|^2 = {:.4} - {:.4} = {:.4} m^3/s^3; stretching / damping = {:.1}",
             2.0 * r3[3], 2.0 * NU * r3[2], 2.0 * r3[3] - 2.0 * NU * r3[2], r3[3] / (NU * r3[2]));
    println!("2D start: dy/dt = -2 nu |lap u|^2 = {:.4} m^2/s^3: never rises", -2.0 * NU * r2[2]);
    for lam in [10.0f64, 100.0] {
        for (d, flow, r) in [(3, &flow3, r3), (2, &flow2, r2)] {
            let z = integrals(flow, d, lam);
            let rule = lam.powi(2 - d);
            println!("zoom {:.0}x, {}D: energy ratio {:.6} (rule lam^(2-d) = {:.6}); enstrophy ratio {:.1}",
                     lam, d, z[0] / r[0], rule, z[1] / r[1]);
            assert!((z[0] / r[0] - rule).abs() < 1e-9);
        }
    }
    let tstar = NU.powi(3) / (2.0 * K * r3[1] * r3[1]);
    println!("3D guarantee T* = nu^3/(2K y0^2) = {} s; turnover L/U = {} s; Re^3 = {}", e(tstar, 4), L / U, e(re.powi(3), 4));
    let f = |z: f64| z * z * z / 2.0; // dz/ds, z = y/y0, s = t/T*
    let (mut z, hs, mut iz, mut iz2) = (1.0f64, 1e-4, 0.0f64, 0.0f64);
    let (mut marks, mut out) = (vec![0.99, 0.96, 0.9, 0.75, 0.5, 0.25], vec![1.0f64]);
    for step in 0..9900 {
        let k1 = f(z); let k2 = f(z + hs * k1 / 2.0); let k3 = f(z + hs * k2 / 2.0); let k4 = f(z + hs * k3);
        let zn = z + hs * (k1 + 2.0 * k2 + 2.0 * k3 + k4) / 6.0;
        iz += hs * (z + zn) / 2.0; iz2 += hs * (z * z + zn * zn) / 2.0;
        z = zn;
        let s = (step + 1) as f64 * hs;
        if let Some(&m) = marks.last() { if (s - m).abs() < 1e-9 { out.push(z); marks.pop(); } }
    }
    let exact: Vec<f64> = [0.0, 0.25, 0.5, 0.75, 0.9, 0.96, 0.99].iter().map(|q: &f64| 1.0 / (1.0 - q).sqrt()).collect();
    let pts: Vec<String> = out.iter().map(|v| format!("{:.3}", v)).collect();
    println!("chart, 3D bound y/y0 at t/T* = 0,0.25,0.5,0.75,0.9,0.96,0.99: {}", pts.join(", "));
    let flat: Vec<String> = out.iter().map(|_| format!("{:.3}", 1.0)).collect();
    println!("chart, 2D bound y/y0 at the same times: {}", flat.join(", "));
    println!("to 0.99 T*: int y dt / (y0 T*) = {:.4} (exact 1.8); int y^2 dt / (y0^2 T*) = {:.4} (exact {:.4})",
             iz, iz2, 100f64.ln());
    for dl in [1e-2f64, 1e-4, 1e-6] {
        println!("cut {} T* short: int y = {:.4} y0 T*, int y^2 = {:.4} y0^2 T*", e(dl, 0), 2.0 * (1.0 - dl.sqrt()), (1.0 / dl).ln());
    }
    println!("energy allows int y dt up to {:.1} m^3/s; this blow-up uses {} m^3/s", r3[0] / NU, e(2.0 * r3[1] * tstar, 4));
    let expo = 2.0 * K * r2[0] * r2[0] / NU.powi(4);
    println!("2D with walls: y <= y0 exp({}), a number with about {} digits", e(expo, 4), e(expo / 10f64.ln(), 4));
    let prod = (2.0 * r3[0] * r3[1]).sqrt();
    println!("small-data test: |u0| |grad u0| = {:.4} m^4/s^2 = {} nu^2", prod, e(prod / (NU * NU), 4));
    println!("mistake, squeezing wave: dE/dt gains -T = {} m^5/s^3 = {:.4} W from nothing", e(-bad[5], 4), -RHO * bad[5]);
    assert!(out.iter().zip(&exact).all(|(a, b)| (a - b).abs() < 1e-6)); // RK4 against 1/sqrt(1-s)
    assert!((iz - 1.8).abs() < 1e-4 && (iz2 - 100f64.ln()).abs() < 1e-4); // quadrature against closed form
    assert!((r3[3] - r3[4]).abs() < 1e-9 * r3[3].abs() && r3[3] > 1.0); // two roads to stretching
    assert!(r2[3].abs() < 1e-12 * r2[1] * k0 * U && r3[5].abs() < 1e-12 * r3[1] * k0 * U);
    assert!([r3, r2].iter().all(|r| r[7].abs() < 1e-12 * r[1] * k0 * U
            && (r[6] + r[1]).abs() < 1e-12 * r[1])); // pressure; int u.lap u = -y0
    assert!((r3[0] - L.powi(3) * U * U).abs() < 1e-15 && (r3[1] - L.powi(3) * 4.5 * k0 * k0 * U * U).abs() < 1e-9);
    assert!((-bad[5] - PI / 800.0).abs() < 1e-12); // the squeeze: pi/800 by hand
    println!("ALL CHECKS PASS");
}
