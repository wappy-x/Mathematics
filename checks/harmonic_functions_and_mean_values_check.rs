// Harmonic functions and mean values -- the same check as the Python file, in Rust.  No crates.
// A 3 m cube room: the sunny wall (y = 0) at 30 C, the other five faces at 18 C, no heater.
// Road 1: the sine-sinh series.  Road 2: averages over spheres and balls (Gauss-Legendre).
// Road 3: a grid where every node is the average of its six neighbours, at two steps.
use std::f64::consts::PI;

const L: f64 = 3.0; const COLD: f64 = 18.0; const SUN: f64 = 30.0; const D: f64 = 3.0; const NP: usize = 32;

struct Room { modes: Vec<(usize, usize, f64, f64)> }
impl Room {
    fn new() -> Room {
        let mut modes = Vec::new();
        for m in (1..140).step_by(2) { for n in (1..140).step_by(2) {
            let (mf, nf) = (m as f64, n as f64);
            modes.push((m, n, PI * (mf * mf + nf * nf).sqrt() / L, 16.0 / (PI * PI * mf * nf)));
        } }
        Room { modes }
    }
    fn unit(&self, x: f64, y: f64, z: f64) -> f64 {     // sunny wall at 1, the rest at 0
        let sx: Vec<f64> = (0..140).map(|m| (m as f64 * PI * x / L).sin()).collect();
        let sz: Vec<f64> = (0..140).map(|n| (n as f64 * PI * z / L).sin()).collect();
        let mut s = 0.0;
        for &(m, n, k, c) in &self.modes {
            let e = (-k * y).exp();
            if e < 1e-17 { continue; }                    // dropped term below 1e-17 of its size
            s += c * sx[m] * sz[n] * e * (1.0 - (-2.0 * k * (L - y)).exp()) / (1.0 - (-2.0 * k * L).exp());
        }
        s
    }
    fn u(&self, x: f64, y: f64, z: f64) -> f64 { COLD + (SUN - COLD) * self.unit(x, y, z) }
    fn dudy(&self, x: f64, y: f64, z: f64) -> f64 {     // the series differentiated term by term
        let mut s = 0.0;
        for &(m, n, k, c) in &self.modes {
            s -= c * (m as f64 * PI * x / L).sin() * (n as f64 * PI * z / L).sin() * k
                * ((-k * y).exp() + (-k * (2.0 * L - y)).exp()) / (1.0 - (-2.0 * k * L).exp());
        }
        (SUN - COLD) * s
    }
    fn heat(&self, x: f64, y: f64, z: f64, f: f64) -> f64 { // same walls, heater f inside: u + v with -Lap v = f, v = 0 on the walls
        let mut s = 0.0;                                  // v = f x(L - x)/2 minus a sine-cosh series that cancels it on four faces
        for &(m, n, k, c) in &self.modes {
            let ch = |t: f64| ((-k * t).exp() + (-k * (L - t)).exp()) / (1.0 + (-k * L).exp());
            s += c * L * L / (PI * PI * m as f64 * m as f64) * (m as f64 * PI * x / L).sin() * ((n as f64 * PI * z / L).sin() * ch(y) + (n as f64 * PI * y / L).sin() * ch(z));
        }
        self.u(x, y, z) + f * (0.5 * x * (L - x) - s)
    }
}

fn gauss_legendre(n: usize) -> (Vec<f64>, Vec<f64>) { // nodes and weights on [-1, 1], by Newton
    let (mut xs, mut ws) = (Vec::new(), Vec::new());
    for i in 1..=n {
        let mut x = (PI * (i as f64 - 0.25) / (n as f64 + 0.5)).cos();
        let mut dp = 0.0;
        for _ in 0..60 {
            let (mut p0, mut p1) = (1.0, x);
            for k in 2..=n {
                let kf = k as f64;
                (p0, p1) = (p1, ((2.0 * kf - 1.0) * x * p1 - (kf - 1.0) * p0) / kf);
            }
            dp = n as f64 * (x * p1 - p0) / (x * x - 1.0);
            x -= p1 / dp;
        }
        xs.push(x); ws.push(2.0 / ((1.0 - x * x) * dp * dp));
    }
    (xs, ws)
}

fn sphere_avg(f: &dyn Fn(f64, f64, f64) -> f64, g: &(Vec<f64>, Vec<f64>), c: (f64, f64, f64), r: f64) -> f64 {
    let mut tot = 0.0;
    for (t, w) in g.0.iter().zip(g.1.iter()) {
        let st = (1.0 - t * t).sqrt();
        for j in 0..NP {
            let p = 2.0 * PI * j as f64 / NP as f64;
            tot += w * f(c.0 + r * st * p.cos(), c.1 + r * t, c.2 + r * st * p.sin());
        }
    }
    tot / (2.0 * NP as f64)
}

fn ball_avg(f: &dyn Fn(f64, f64, f64) -> f64, g: &(Vec<f64>, Vec<f64>), g8: &(Vec<f64>, Vec<f64>), c: (f64, f64, f64), r: f64) -> f64 {
    // shells of radius s weighted by d s^(d-1) / r^d
    g8.0.iter().zip(g8.1.iter()).map(|(t, w)| w * 0.5 * D * ((t + 1.0) / 2.0).powi(2) * sphere_avg(f, g, c, 0.5 * r * (t + 1.0))).sum()
}

fn grid(n: usize, q: f64) -> (f64, f64, f64, f64) {  // six-neighbour averaging plus a heater q (K per m^2), by SOR
    let h = L / n as f64;
    let mut g = vec![vec![vec![COLD; n + 1]; n + 1]; n + 1];
    for i in 1..n { for k in 1..n { g[i][0][k] = SUN; } }
    let om = 2.0 / (1.0 + (PI / n as f64).sin());
    loop {
        let mut big: f64 = 0.0;
        for i in 1..n { for j in 1..n { for k in 1..n {
            let a = (g[i-1][j][k] + g[i+1][j][k] + g[i][j-1][k] + g[i][j+1][k] + g[i][j][k-1] + g[i][j][k+1] + q * h * h) / 6.0;
            let dv = om * (a - g[i][j][k]);
            g[i][j][k] += dv;
            big = big.max(dv.abs());
        } } }
        if big < 1e-12 { break; }
    }
    let (mut hi, mut lo) = (f64::MIN, f64::MAX);
    for i in 1..n { for j in 1..n { for k in 1..n { hi = hi.max(g[i][j][k]); lo = lo.min(g[i][j][k]); } } }
    (g[n / 2][n / 2][n / 2], g[n / 2][(1.0 / h).round() as usize][n / 2], hi, lo)
}

fn main() {
    let room = Room::new();
    let (g16, g8) = (gauss_legendre(16), gauss_legendre(8));
    let u = |x: f64, y: f64, z: f64| room.u(x, y, z);
    let (c, p) = ((1.5, 1.5, 1.5), (1.5, 1.0, 1.5)); // room centre; 1 m out from the sunny wall
    let (uc, up) = (u(c.0, c.1, c.2), u(p.0, p.1, p.2));
    // what the series drops, at every point it is used (all have y >= 0.5 m): skipped terms, then the first mode past the list
    let tail_skip = (SUN - COLD) * 16.0 / (PI * PI) * 1e-17 * room.modes.len() as f64;
    let tail_141 = (SUN - COLD) * 16.0 / (PI * PI * 141.0) * (-PI * (141.0f64 * 141.0 + 1.0).sqrt() * 0.5 / L).exp();
    let (s_c1, s_p, b_p) = (sphere_avg(&u, &g16, c, 1.0), sphere_avg(&u, &g16, p, 0.5), ball_avg(&u, &g16, &g8, p, 0.5));
    let (g12, g24) = (grid(12, 0.0), grid(24, 0.0));
    let (e12, e24) = (g12.1 - up, g24.1 - up);
    let order = (e12.abs() / e24.abs()).ln() / 2.0_f64.ln();   // observed order of the grid error
    // derivatives are averages too: d/dy u(c) = (d/r) * sphere average of u * n_y
    let grad_series = room.dudy(c.0, c.1, c.2);
    let grad_fd = (u(1.5, 1.5 + 1e-3, 1.5) - u(1.5, 1.5 - 1e-3, 1.5)) / 2e-3;
    let grad_mvp = D / 1.0 * sphere_avg(&|x, y, z| u(x, y, z) * (y - 1.5), &g16, c, 1.0);
    let grad_cap = D / 1.5 * (SUN - COLD) / 2.0;      // (d/r) * max |u - 24| with r = 1.5 m
    // what breaks
    let f = 3.0;                                      // an even heater, K per m^2 (illustrative)
    let heat = |x: f64, y: f64, z: f64| room.heat(x, y, z, f);
    let (heat_c, heat_avg) = (heat(c.0, c.1, c.2), sphere_avg(&heat, &g16, c, 1.0));
    let (q12, q24) = (grid(12, f), grid(24, f));
    let q_order = ((q12.0 - heat_c).abs() / (q24.0 - heat_c).abs()).ln() / 2.0_f64.ln();
    let src = |x: f64, y: f64, z: f64| 1.0 / ((x - 1.5).powi(2) + (y - 1.0).powi(2) + (z - 1.5).powi(2)).sqrt();
    let src_avg = sphere_avg(&src, &g16, c, 1.0);

    let rows: Vec<(&str, f64)> = vec![
        ("centre, series (C)", uc), ("centre, symmetry 18 + 12/6 (C)", COLD + (SUN - COLD) / 6.0),
        ("centre, sphere r = 1 m (C)", s_c1), ("centre, grid h = 0.25 m (C)", g12.0),
        ("P, series (C)", up), ("P, sphere r = 0.5 m (C)", s_p), ("P, ball r = 0.5 m (C)", b_p),
        ("P, grid h = 0.25 m (C)", g12.1), ("P, grid h = 0.125 m (C)", g24.1),
        ("P, grid observed order", order),
        ("hottest grid node inside (C)", g24.2), ("coldest grid node inside (C)", g24.3),
        ("du/dx2 at centre, series (K/m)", grad_series), ("du/dx2 at centre, centred diff (K/m)", grad_fd),
        ("du/dx2 at centre, (d/r) avg u n_y (K/m)", grad_mvp), ("|grad u| cap (d/r) max|u-24| (K/m)", grad_cap),
        ("wrong: 2-D rule 18 + 12/4 (C)", COLD + (SUN - COLD) / 4.0),
        ("wrong: plain wall average at P (C)", (SUN + 5.0 * COLD) / 6.0),
        ("break: heater, centre, series (C)", heat_c), ("  heater centre, grid h = 0.25 m (C)", q12.0),
        ("  heater centre, grid h = 0.125 m (C)", q24.0), ("  heater centre, grid observed order", q_order),
        ("break: heater, sphere avg r = 1 m (C)", heat_avg), ("  shortfall f r^2/(2d) (K)", f / (2.0 * D)),
        ("break: source inside, sphere avg (1/m)", src_avg), ("  value at centre 1/0.5 (1/m)", src(c.0, c.1, c.2)),
    ];
    for (name, v) in &rows { println!("{:<40} {:>12.6}", name, v); }
    let radii = [0.0, 0.25, 0.5, 0.75, 1.0];
    let line = |vals: Vec<f64>| vals.iter().map(|v| format!("{:6.2}", v)).collect::<Vec<_>>().join(" ");
    println!("{:<40} {:>12.3e}", "series: all skipped terms, at most (K)", tail_skip);
    println!("{:<40} {:>12.3e}", "series: first omitted mode, y = 0.5 m (K)", tail_141);
    println!("chart, radius (m)          {}", line(radii.to_vec()));
    println!("chart, no heater (C)       {}", line(radii.iter().map(|&r| if r == 0.0 { uc } else { sphere_avg(&u, &g16, c, r) }).collect()));
    println!("chart, even heater (C)     {}", line(radii.iter().map(|&r| if r == 0.0 { heat_c } else { sphere_avg(&heat, &g16, c, r) }).collect()));
    println!("figure, 120 px/m, slice z = 1.5 m: room (60, 40)-(420, 400); centre (240, 220) r 120; P (240, 280) r 60");

    assert!((uc - 20.0).abs() < 1e-9, "series centre must match the six-face symmetry");
    assert!((s_c1 - uc).abs() < 1e-9 && (s_p - up).abs() < 1e-9, "sphere averages equal the centre values");
    assert!((b_p - up).abs() < 1e-9, "ball average equals the centre value");
    assert!((g12.0 - 20.0).abs() < 1e-9, "grid centre is exactly a sixth of the way up");
    assert!(e24.abs() < 0.02 && 1.8 < order && order < 2.2, "grid converges to the series at second order");
    assert!(SUN > g24.2 && g24.3 > COLD, "inside stays strictly between the wall temperatures");
    assert!((grad_series - grad_fd).abs() < 1e-5 && (grad_mvp - grad_series).abs() < 1e-9, "three roads to the slope");
    assert!(grad_series.abs() <= grad_cap, "slope obeys the mean-value derivative bound");
    assert!((q24.0 - heat_c).abs() < 0.02 && 1.8 < q_order && q_order < 2.2, "heated grid converges to the heated series");
    assert!(((heat_c - heat_avg) - f / (2.0 * D)).abs() < 1e-9, "heater shortfall is f r^2/(2d)");
    assert!((src_avg - 1.0).abs() < 1e-6, "an enclosed source averages to 1/r, not its centre value");
    println!("ALL CHECKS PASS");
}
