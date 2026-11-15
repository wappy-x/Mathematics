// Energy methods -- the check behind the card.  std only, no crates.
// A 1 m x 1 m steel plate, edges held.  w = difference of two plates' temperatures.
// Roads to the energy E(t) = (1/2) * integral of w^2: closed form by modes, midpoint
// quadrature of the series, an explicit grid; dE/dt by centred differences against
// -kappa * integral |grad w|^2 (+ 2aE with a heat source).  Then the wave equation.
use std::f64::consts::PI;
const KAPPA: f64 = 1.2e-5; // steel's diffusivity, m^2/s
const MODES: [(f64, f64, f64); 2] = [(1.0, 1.0, 0.5), (2.0, 3.0, 0.3)]; // (m, n, amplitude in C)

fn sci(x: f64) -> String { // same digits in Python and Rust: 1.234e+31
    let mut e = x.abs().log10().floor() as i32;
    let mut m = x / 10f64.powi(e);
    if (m.abs() * 1000.0).round() / 1000.0 >= 10.0 { m /= 10.0; e += 1; }
    format!("{:.3}e{}{:02}", m, if e >= 0 { "+" } else { "-" }, e.abs())
}
fn lam(m: f64, n: f64) -> f64 { PI * PI * (m * m + n * n) } // mode's -Laplacian eigenvalue, 1/m^2
fn w(x: f64, y: f64, t: f64, a: f64) -> f64 { // series solution of w_t = kappa*Lap w + a*w
    MODES.iter().map(|&(m, n, amp)| amp * ((a - KAPPA * lam(m, n)) * t).exp()
        * (m * PI * x).sin() * (n * PI * y).sin()).sum()
}
fn e_closed(t: f64, a: f64) -> f64 { // each mode: (1/2)(A^2/4) e^{2(a - kappa*lam) t}
    MODES.iter().map(|&(m, n, amp)| amp * amp / 8.0 * (2.0 * (a - KAPPA * lam(m, n)) * t).exp()).sum()
}
fn e_edge(t: f64) -> f64 { // frames 0.5 C apart: w = 0.5 - v, v the zero-edge solution from 0.5,
    let mut s = 0.0;       // odd modes 8/(pi^2 m n); E = (1/2)(1/4 - int v + int v^2)
    for m in (1..11).step_by(2) { for n in (1..11).step_by(2) {
        let (mf, nf) = (m as f64, n as f64);
        let g = (-KAPPA * lam(mf, nf) * t).exp();
        s += 16.0 / (PI * PI * PI * PI * mf * mf * nf * nf) * (g * g - 2.0 * g);
    } }
    0.5 * (0.25 + s)
}
fn gron(t: f64, a: f64) -> f64 { e_closed(0.0, 0.0) * (2.0 * a * t).exp() } // Gronwall: E(t) <= E(0) e^{2at}
fn quad<F: Fn(f64, f64) -> f64>(f: F) -> f64 { // midpoint rule on the unit square
    let mm = 60; let h = 1.0 / mm as f64; let mut s = 0.0;
    for i in 0..mm { for j in 0..mm { s += f((i as f64 + 0.5) * h, (j as f64 + 0.5) * h); } }
    s * h * h
}
fn e_quad(t: f64, a: f64) -> f64 { quad(|x, y| 0.5 * w(x, y, t, a).powi(2)) }
fn grad2(t: f64, a: f64) -> f64 { // integral of |grad w|^2, gradient by centred differences
    let d = 1e-5;
    quad(|x, y| ((w(x + d, y, t, a) - w(x - d, y, t, a)) / (2.0 * d)).powi(2)
        + ((w(x, y + d, t, a) - w(x, y - d, t, a)) / (2.0 * d)).powi(2))
}
// explicit scheme; returns (final E, steps where E rose, r)
fn grid(t_end: f64, n: usize, dt: f64, edge: f64, start: Option<&Vec<Vec<f64>>>, track: bool) -> (f64, u32, f64) {
    let h = 1.0 / n as f64; let r = KAPPA * dt / h / h;
    let bd = |i: usize, j: usize| i == 0 || i == n || j == 0 || j == n;
    let mut u = vec![vec![0.0; n + 1]; n + 1];
    for i in 0..=n { for j in 0..=n {
        u[i][j] = if bd(i, j) { edge } else if let Some(s) = start { s[i][j] } else { w(i as f64 * h, j as f64 * h, 0.0, 0.0) };
    } }
    let wt = |i: usize| if i == 0 || i == n { 0.5 } else { 1.0 }; // trapezoid: edge nodes count half
    let en = |u: &Vec<Vec<f64>>| { let mut s = 0.0;
        for i in 0..=n { for j in 0..=n { s += wt(i) * wt(j) * u[i][j] * u[i][j]; } } 0.5 * h * h * s };
    let (mut rises, mut last) = (0u32, en(&u));
    for _ in 0..(t_end / dt).round() as usize {
        let mut v = u.clone();
        for i in 1..n { for j in 1..n {
            v[i][j] = u[i][j] + r * (u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] - 4.0 * u[i][j]);
        } }
        u = v;
        let e = en(&u); if track && e > last + 1e-15 { rises += 1; } last = e;
    }
    (last, rises, r)
}
fn main() {
    println!("heat: kappa = 1.2e-5 m^2/s; difference 0.5 C in mode (1,1), 0.3 C in mode (2,3)");
    println!("t (min) | E closed | E quadrature | E grid | dE/dt by differences | -kappa*int|grad w|^2  (E in C^2 m^2, rates per s)");
    for mins in [0, 30, 60, 120] {
        let t = 60.0 * mins as f64;
        let dedt = (e_quad(t + 1.0, 0.0) - e_quad(t - 1.0, 0.0)) / 2.0;
        let d = KAPPA * grad2(t, 0.0);
        let eg = grid(t, 40, 12.0, 0.0, None, false).0;
        println!("{:3} | {:.6} | {:.6} | {:.6} | {} | {}", mins, e_closed(t, 0.0), e_quad(t, 0.0), eg, sci(dedt), sci(-d));
        assert!((e_quad(t, 0.0) - e_closed(t, 0.0)).abs() < 1e-9 && (eg - e_closed(t, 0.0)).abs() < 1e-2 * e_closed(t, 0.0));
        assert!((dedt + d).abs() < 1e-4 * d); // the energy identity, two roads
    }
    println!("grid: h = 0.025 m, dt = 12 s, r = kappa dt / h^2 = {:.4} (limit 0.25)", grid(0.0, 40, 12.0, 0.0, None, false).2);
    println!("rms difference: start {:.4} C, 60 min {:.4} C", (2.0 * e_closed(0.0, 0.0)).sqrt(), (2.0 * e_closed(3600.0, 0.0)).sqrt());
    println!("decay bound E(0)e^(-2 kappa 2 pi^2 t) at 60 min: {:.6}", e_closed(0.0, 0.0) * (-4.0 * PI * PI * KAPPA * 3600.0).exp());
    let (k11, k23) = (KAPPA * lam(1.0, 1.0), KAPPA * lam(2.0, 3.0));
    println!("hand: kappa*lam(1,1) = {} /s; 60 min: 2*kappa*lam*t = {:.4} and {:.4}, factors {:.4} and {}",
        sci(k11), 7200.0 * k11, 7200.0 * k23, (-7200.0 * k11).exp(), sci((-7200.0 * k23).exp()));
    let chart: Vec<String> = (0..9).map(|k| format!("{:.4}", e_closed(900.0 * k as f64, 0.0))).collect();
    println!("chart, E every 15 min: {}", chart.join(", "));

    let mut s: u64 = 0x2026111500000007; // SplitMix64: random starting differences on a 10 x 10 grid
    let mut rnd = || {
        s = s.wrapping_add(0x9E3779B97F4A7C15); let mut z = s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    };
    let mut total = 0;
    for _ in 0..20 {
        let st: Vec<Vec<f64>> = (0..11).map(|_| (0..11).map(|_| 2.0 * rnd() - 1.0).collect()).collect();
        total += grid(2500.0, 10, 250.0 / 1.2, 0.0, Some(&st), true).1;
    }
    println!("random starts: 20 trials x 12 steps at r = 0.25; steps where E rose: {}", total);
    assert!(total == 0);
    let zero = vec![vec![0.0; 41]; 41];
    let same = grid(3600.0, 40, 12.0, 0.0, Some(&zero), false).0;
    println!("identical data: E of the difference at 60 min = {:.6}", same);

    let a_heat = 1e-4; // heated plate: w_t = kappa Lap w + a w
    for mins in [30, 60] {
        let t = 60.0 * mins as f64;
        let (tru, bound) = (e_closed(t, a_heat), gron(t, a_heat));
        let dedt = (e_quad(t + 1.0, a_heat) - e_quad(t - 1.0, a_heat)) / 2.0;
        let rhs = -KAPPA * grad2(t, a_heat) + 2.0 * a_heat * e_quad(t, a_heat);
        println!("heated, a = 1e-4 /s, {} min: E true {:.6}, Gronwall factor {:.4}, bound {:.6}, dE/dt {} vs {}",
            mins, tru, (2.0 * a_heat * t).exp(), bound, sci(dedt), sci(rhs));
        assert!(tru <= bound && (dedt - rhs).abs() < 1e-4 * rhs.abs());
    }

    println!("what breaks:");
    println!("  backward heat, 1e-6 C in mode (10,10), 60 min: exponent {:.2}, {} C", KAPPA * lam(10.0, 10.0) * 3600.0, sci(1e-6 * (KAPPA * lam(10.0, 10.0) * 3600.0).exp()));
    let es = e_edge(3600.0);
    let z20 = vec![vec![0.0; 21]; 21];
    let (eb, eb2) = (grid(3600.0, 40, 12.0, 0.5, Some(&zero), false).0, grid(3600.0, 20, 48.0, 0.5, Some(&z20), false).0);
    println!("  edges 0.5 C apart, same start: E from 0 to {:.6} at 60 min by series, first omitted term {}",
        es, sci(16.0 / (PI * PI * PI * PI * 121.0) * (-KAPPA * lam(11.0, 1.0) * 3600.0).exp()));
    let ratio = (eb2 - es) / (eb - es);
    println!("  same case on the grid: h = 0.05 m, dt = 48 s {:.6}; h = 0.025 m, dt = 12 s {:.6}; error ratio {:.2}", eb2, eb, ratio);
    assert!((eb - es).abs() < 0.005 * es && 3.5 < ratio && ratio < 4.5); // two roads; second order in h
    let big = e_closed(3600.0, 5e-4);
    println!("  a = 5e-4 /s, no Gronwall factor: claimed E <= {:.6}, true {:.6}; Gronwall bound {:.6}", e_closed(0.0, 0.0), big, gron(3600.0, 5e-4));
    assert!(e_closed(0.0, 0.0) < big && big <= gron(3600.0, 5e-4));

    let (rho, c, b, amp) = (15.7, 100.0f64, 1.0, 0.001); // wave: kg/m^2, m/s, damping /s, 1 mm in mode (1,1)
    let w11 = c * PI * 2f64.sqrt();
    let wave = |t: f64, b: f64| { // damped mode: displacement amplitude and its rate
        let wd = (w11 * w11 - b * b / 4.0).sqrt(); let e = (-b * t / 2.0).exp();
        (amp * e * ((wd * t).cos() + b / (2.0 * wd) * (wd * t).sin()), -amp * e * (w11 * w11 / wd) * (wd * t).sin())
    };
    let wave_e = |t: f64, b: f64, c2: f64| { // (rho/2) int (w_t^2 + c^2 |grad w|^2); sin^2 integrates to 1/4
        let (q, p) = wave(t, b);
        rho / 2.0 * (p * p + c2 * lam(1.0, 1.0) * q * q) / 4.0
    };
    println!("wave: mode (1,1) {:.2} rad/s = {:.2} Hz, rho_s = {} kg/m^2, c = {:.0} m/s, E(0) = {:.6} J", w11, w11 / (2.0 * PI), rho, c, wave_e(0.0, 0.0, c * c));
    for t in [0.25, 0.5, 1.0] {
        let de = (wave_e(t + 1e-6, b, c * c) - wave_e(t - 1e-6, b, c * c)) / 2e-6;
        let loss = -b * rho * wave(t, b).1.powi(2) / 4.0;
        println!("  t = {:.2} s: E undamped {:.6} J, damped {:.6} J, dE/dt {:.6} vs {:.6} J/s", t, wave_e(t, 0.0, c * c), wave_e(t, b, c * c), de, loss);
        assert!((wave_e(t, 0.0, c * c) - wave_e(0.0, 0.0, c * c)).abs() < 1e-12 && (de - loss).abs() < 1e-5);
    }
    let q4 = PI / (2.0 * w11);
    println!("  energy without c^2: {} J at t = 0, {} J a quarter period on", sci(wave_e(0.0, 0.0, 1.0)), sci(wave_e(q4, 0.0, 1.0)));
    println!("ALL CHECKS PASS");
}
