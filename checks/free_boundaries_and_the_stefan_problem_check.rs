// Free boundaries and the Stefan problem -- the same check as the Python, in Rust.
// No crates.  A glass of ice at 0 C under a lid held at 20 C, melting for 20
// minutes.  Road 1: the Neumann closed form, its number lam found by bisection.
// Road 2: an enthalpy grid that never tracks the front, at three steps.
// Road 3: the heat through the lid against the heat stored, by Simpson's rule.
const K: f64 = 0.6;
const RHO: f64 = 1000.0;
const C: f64 = 4186.0;
const LAT: f64 = 334000.0;
const T0: f64 = 20.0; // water, SI units
const KS: f64 = 2.2;
const CS: f64 = 2100.0;
const TI: f64 = -10.0; // ice, for the -10 C break
const TEND: f64 = 1200.0; // 20 minutes, s

fn sqpi() -> f64 { std::f64::consts::PI.sqrt() }
fn kap() -> f64 { K / (RHO * C) } // water's diffusivity, m^2/s
fn st() -> f64 { C * T0 / LAT } // Stefan number

fn erf(z: f64) -> f64 { // Taylor series, fine for z < 3
    let (mut term, mut total, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 {
        n += 1.0;
        term *= -z * z / n;
        total += term / (2.0 * n + 1.0);
    }
    2.0 / sqpi() * total
}

fn bisect(f: &dyn Fn(f64) -> f64, mut a: f64, mut b: f64) -> f64 { // f(a) < 0 < f(b)
    for _ in 0..200 {
        let m = 0.5 * (a + b);
        if f(m) < 0.0 { a = m; } else { b = m; }
    }
    0.5 * (a + b)
}

fn temp(lam: f64, x: f64, t: f64) -> f64 { T0 * (1.0 - erf(x / (2.0 * (kap() * t).sqrt())) / erf(lam)) }

fn enthalpy_front(n_cells: usize, dt: f64) -> f64 { // H = heat content per m^3 above ice at 0 C
    let h = 0.015 / n_cells as f64;
    let mut hh = vec![0.0; n_cells + 1];
    let mut t = vec![0.0; n_cells + 1];
    t[0] = T0;
    for _ in 0..(TEND / dt).round() as usize {
        for i in 1..n_cells {
            hh[i] += dt * K * (t[i + 1] - 2.0 * t[i] + t[i - 1]) / (h * h);
        }
        for i in 1..n_cells {
            t[i] = f64::max(0.0, (hh[i] - RHO * LAT) / (RHO * C));
        }
    }
    h / 2.0 + h * hh[1..].iter().map(|v| f64::min(1.0, v / (RHO * LAT))).sum::<f64>()
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for j in 0..=n {
        let w = if j == 0 || j == n { 1.0 } else if j % 2 == 1 { 4.0 } else { 2.0 };
        s += w * f(a + j as f64 * h);
    }
    h / 3.0 * s
}

fn out(label: &str, value: String) { println!("{:<46}{}", label, value); }

fn main() {
    let (kap, st, sqpi) = (kap(), st(), sqpi());
    let lam = bisect(&|l: f64| l * (l * l).exp() * erf(l) - st / sqpi, 0.0, 2.0);
    let front = |t: f64| 2.0 * lam * (kap * t).sqrt();
    let speed = |t: f64| lam * (kap / t).sqrt();
    out("diffusivity of water, 1e-7 m^2/s", format!("{:.4}", kap * 1e7));
    out("Stefan number c*T0/L", format!("{:.4}", st));
    out("lam, root of the Neumann equation", format!("{:.6}", lam));
    let s20 = front(TEND);
    out("by hand: exp(lam^2), erf(lam), product", format!("{:.4}, {:.4}, {:.4} = St/sqrt(pi) {:.4}",
        (lam * lam).exp(), erf(lam), lam * (lam * lam).exp() * erf(lam), st / sqpi));
    out("sqrt(kappa t) at 20 min, mm", format!("{:.3}", 1000.0 * (kap * TEND).sqrt()));
    out("front after 5, 10 and 20 min, mm",
        format!("{:.3}, {:.3}, {:.3}", 1000.0 * front(300.0), 1000.0 * front(600.0), 1000.0 * s20));
    out("front speed at 1 min and 20 min, mm/min",
        format!("{:.3} and {:.3}", 60000.0 * speed(60.0), 60000.0 * speed(TEND)));
    let mins: Vec<f64> = (0..=10).map(|k| (2 * k) as f64).collect();
    let mut line = String::from("minute   ");
    for m in &mins { line.push_str(&format!("{:>6}", m)); }
    println!("{}", line);
    let mut line = String::from("front mm ");
    for m in &mins { line.push_str(&format!("{:>6.2}", 1000.0 * front(60.0 * m))); }
    println!("{}", line);
    let qs: Vec<f64> = mins.iter().map(|m| (2.0 * K * T0 * 60.0 * m / (RHO * LAT)).sqrt()).collect();
    let mut line = String::from("quasi mm ");
    for v in &qs { line.push_str(&format!("{:>6.2}", 1000.0 * v)); }
    println!("{}", line);
    for m in [5.0, 10.0, 20.0] {
        let t = 60.0 * m;
        let row: Vec<String> = (0..10).map(|x| {
            let xm = x as f64 / 1000.0;
            format!("{:5.2}", if xm <= front(t) { temp(lam, xm, t) } else { 0.0 })
        }).collect();
        println!("T at {:>2} min, x = 0..9 mm, C {}", m, row.join(" "));
    }
    // road 3: heat in through the lid against latent plus sensible heat stored
    let q_in = 2.0 * K * T0 * TEND.sqrt() / (erf(lam) * (std::f64::consts::PI * kap).sqrt());
    let latent = RHO * LAT * s20;
    let sensible = RHO * C * simpson(&|x: f64| temp(lam, x, TEND), 0.0, s20, 200);
    out("heat in through the lid, kJ/m^2", format!("{:.3}", q_in / 1000.0));
    out("melting the ice (latent), kJ/m^2", format!("{:.3}", latent / 1000.0));
    out("warming the melt water (sensible), kJ/m^2", format!("{:.3}", sensible / 1000.0));
    out("stored / in", format!("{:.8}", (latent + sensible) / q_in));
    out("shares: latent, sensible, %", format!("{:.1}, {:.1}", 100.0 * latent / q_in, 100.0 * sensible / q_in));
    let dx = 1e-3 * s20; // Stefan condition at 20 min, two sides
    let grad = (temp(lam, s20 + dx, TEND) - temp(lam, s20 - dx, TEND)) / (2.0 * dx);
    let lid = -K * (temp(lam, dx, TEND) - temp(lam, -dx, TEND)) / (2.0 * dx);
    out("W/m^2 at 20 min: lid, -k T_x(s), rho L s'",
        format!("{:.1}, {:.1}, {:.1}", lid, -K * grad, RHO * LAT * speed(TEND)));
    // road 2: the enthalpy grid, explicit, r = kappa*dt/h^2 = 0.4587 on every grid
    let mut grid = Vec::new();
    for (n_cells, dt) in [(30usize, 0.8), (60, 0.2), (120, 0.05)] {
        let sg = enthalpy_front(n_cells, dt);
        grid.push(sg);
        out(&format!("grid h = {:.3} mm, dt = {} s, front mm", 15.0 / n_cells as f64, dt),
            format!("{:.3}  error {:+.1} um  ratio {:.4}", 1000.0 * sg, 1e6 * (sg - s20), kap * dt / (0.015 / n_cells as f64).powi(2)));
    }
    // two-phase: ice starting at -10 C also soaks up heat ahead of the front
    let kaps = KS / (RHO * CS);
    let (nu, sts) = ((kap / kaps).sqrt(), CS * (0.0 - TI) / LAT);
    let lam2 = bisect(&|l: f64| l - st * (-l * l).exp() / (sqpi * erf(l))
        + sts * (-nu * nu * l * l).exp() / (nu * sqpi * (1.0 - erf(nu * l))), 1e-9, 2.0);
    let s_cold = 2.0 * lam2 * (kap * TEND).sqrt();
    out("ice at -10 C: lam, front after 20 min mm", format!("{:.6}, {:.3}", lam2, 1000.0 * s_cold));
    let mist = [60.0 * speed(60.0) * 20.0, qs[10], lam * (kap * TEND).sqrt()];
    out("mistakes, mm: constant speed, quasi, no 2",
        format!("{:.3}, {:.3}, {:.3}", 1000.0 * mist[0], 1000.0 * mist[1], 1000.0 * mist[2]));
    out("off by, %: -10 C ice, quasi-steady",
        format!("{:+.1}, {:+.1}", 100.0 * (s_cold / s20 - 1.0), 100.0 * (qs[10] / s20 - 1.0)));
    // centred-difference residual of the heat equation at mid-layer, 20 min, two steps
    let x0 = 0.5 * s20;
    let u = |x: f64, t: f64| temp(lam, x, t);
    let mut res = Vec::new();
    for (d, e) in [(0.1 * s20, 40.0), (0.05 * s20, 20.0)] {
        res.push((u(x0, TEND + e) - u(x0, TEND - e)) / (2.0 * e)
            - kap * (u(x0 + d, TEND) - 2.0 * u(x0, TEND) + u(x0 - d, TEND)) / (d * d));
    }
    out("heat-eq residual, 1e-6 K/s, step d and d/2", format!("{:.4}, {:.4}", res[0] * 1e6, res[1] * 1e6));
    assert!((lam - (st / 2.0).sqrt() * (1.0 - st / 6.0)).abs() < 0.01 * lam); // small-St series
    assert!(((latent + sensible) / q_in - 1.0).abs() < 1e-8); // energy is conserved
    assert!(grid.iter().all(|g| (g - s20).abs() < 1e-3 * s20)); // the grid agrees with Neumann
    assert!(3.5 < res[0] / res[1] && res[0] / res[1] < 4.5); // order 2: the formula solves the equation
    assert!((-K * grad / (RHO * LAT * speed(TEND)) - 1.0).abs() < 1e-5); // the Stefan condition
    assert!(s_cold < s20 && s20 < qs[10] && qs[10] < mist[0]); // each break's direction
    println!("ALL CHECKS PASS");
}
