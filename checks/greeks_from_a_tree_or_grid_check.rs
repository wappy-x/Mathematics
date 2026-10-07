// Greeks from a tree or grid -- the same check as the Python, in Rust.  Std only,
// no crates.  Rust has no erf, so the bell-curve area is built the honest way:
// thin slices under the curve (Simpson).  Four roads reach the Acme call's delta;
// the tree's nodes give delta, gamma and theta; a grid in log coordinates gives
// two of them again.  Compile: rustc --edition 2021 -O this_file.rs -o /tmp/chk
use std::f64::consts::PI;

const S: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05;
const Q: f64 = 0.02;  const SIG: f64 = 0.20;  const T: f64 = 1.0;

fn pdf(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * PI).sqrt() }   // bell-curve height

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn ncdf(x: f64) -> f64 {                                  // bell-curve area left of x
    if x < -12.0 { return 0.0; }
    if x > 12.0 { return 1.0; }
    0.5 + simpson(pdf, 0.0, x, 2000)
}

fn d1d2(s: f64, t: f64) -> (f64, f64) {
    let vt = SIG * t.sqrt();
    let d1 = ((s / K).ln() + (R - Q + 0.5 * SIG * SIG) * t) / vt;
    (d1, d1 - vt)
}
fn call(s: f64, t: f64) -> f64 {                          // the Black-Scholes call
    if t <= 0.0 { return (s - K).max(0.0); }
    let (d1, d2) = d1d2(s, t);
    s * (-Q * t).exp() * ncdf(d1) - K * (-R * t).exp() * ncdf(d2)
}

fn bs_delta(s: f64, t: f64) -> f64 {                      // e^-qT N(d1)
    let (d1, _) = d1d2(s, t); (-Q * t).exp() * ncdf(d1)
}
fn bs_gamma(s: f64, t: f64) -> f64 {
    let (d1, _) = d1d2(s, t); (-Q * t).exp() * pdf(d1) / (s * SIG * t.sqrt())
}
fn bs_theta(s: f64, t: f64) -> f64 {                      // calendar time forward, per year
    let (d1, d2) = d1d2(s, t);
    -s * (-Q * t).exp() * pdf(d1) * SIG / (2.0 * t.sqrt())
        + Q * s * (-Q * t).exp() * ncdf(d1) - R * K * (-R * t).exp() * ncdf(d2)
}
fn stencil(vm: f64, v0: f64, vp: f64, hm: f64, hp: f64) -> (f64, f64) {   // chord, curvature
    ((vp - vm) / (hp + hm), 2.0 * ((vp - v0) / hp - (v0 - vm) / hm) / (hp + hm))
}

fn tree(steps: usize) -> (f64, f64, f64, Vec<Vec<f64>>) {  // CRR tree, rows 0, 1, 2 kept
    let dt = T / steps as f64; let x = SIG * dt.sqrt();    // one step's length and log move
    let (u, d) = (x.exp(), (-x).exp());
    let p = (((R - Q) * dt).exp() - d) / (u - d); let disc = (-R * dt).exp();
    let mut v: Vec<f64> = (0..=steps)
        .map(|j| (S * (((2 * j) as f64 - steps as f64) * x).exp() - K).max(0.0)).collect();
    let mut rows = vec![Vec::new(), Vec::new(), Vec::new()];
    for n in (0..steps).rev() {
        v = (0..=n).map(|j| disc * ((1.0 - p) * v[j] + p * v[j + 1])).collect();
        if n <= 2 { rows[n] = v.clone(); }
    }
    (u, d, p, rows)
}

fn node_greeks(steps: usize) -> (f64, f64, f64, Vec<Vec<f64>>, f64, f64, f64, f64, f64) {
    let dt = T / steps as f64;
    let (u, d, p, rows) = tree(steps);
    let (hp, hm) = (S * (u * u - 1.0), S * (1.0 - d * d));
    let delta = (rows[1][1] - rows[1][0]) / (S * u - S * d);
    let gamma = stencil(rows[2][0], rows[2][1], rows[2][2], hm, hp).1;
    let theta = (rows[2][1] - rows[0][0]) / (2.0 * dt);
    (u, d, p, rows, hm, hp, delta, gamma, theta)
}

fn grid(a: f64) -> (f64, f64, f64, f64) {                 // slopes in x, converted to S
    let (um, u0, up) = (call(S * (-a).exp(), T), call(S, T), call(S * a.exp(), T));
    let (ux, uxx) = ((up - um) / (2.0 * a), (up - 2.0 * u0 + um) / (a * a));
    (ux, uxx, ux / S, (uxx - ux) / (S * S))
}

fn main() {
    // ---- an exact fixture: three samples of 3 + 2x + 5x^2 on gaps 1.5 and 4.0 ----
    let (fx_chord, fx_curv) = stencil(3.0 - 3.0 + 11.25, 3.0, 3.0 + 8.0 + 80.0, 1.5, 4.0);
    // ---- the four-quarter tree of the earlier card ----
    let (u4, d4, p4, r4, hm4, hp4, dl4, gm4, th4) = node_greeks(4);
    let (ux, uxx, d_grid, g_grid) = grid(0.01);
    let (_, _, d_fine, g_fine) = grid(0.002);
    // ---- four roads to the same delta ----
    let d_form = bs_delta(S, T);
    let h = 0.01;
    let d_bump = (call(S + h, T) - call(S - h, T)) / (2.0 * h);
    let sizes = [4usize, 8, 16, 32, 64, 128, 256, 1024];
    let fine: Vec<(f64, f64, f64, f64, f64)> = sizes.iter().map(|&m| {
        let g = node_greeks(m); (g.4, g.5, g.6, g.7, g.8)
    }).collect();
    let (d_tree, gm_1024, th_1024) = (fine[7].2, fine[7].3, fine[7].4);
    // ---- what breaks ----
    let g_equal = (r4[2][2] - 2.0 * r4[2][1] + r4[2][0]) / (0.25 * (hm4 + hp4) * (hm4 + hp4));
    let g_noterm = uxx / (S * S);
    let th_up = (r4[2][2] - r4[0][0]) / (2.0 * (T / 4.0));
    let amp = 0.01 * 4.0 / (fine[7].0 * fine[7].1);

    println!("house call price, formula                {:>12.6}", call(S, T));
    println!("Black-Scholes delta  e^-qT N(d1)         {:>12.6}", d_form);
    println!("Black-Scholes gamma                      {:>12.6}", bs_gamma(S, T));
    println!("Black-Scholes theta, per year            {:>12.6}", bs_theta(S, T));
    println!("exact fixture 3 + 2x + 5x^2 on gaps 1.5 and 4.0: chord {:.6} curvature {:.6}",
             fx_chord, fx_curv);
    println!();
    println!("the Acme call's delta by four roads");
    println!("  1 tree node slope, 1024 steps          {:>12.6}", d_tree);
    println!("  2 formula e^-qT N(d1)                  {:>12.6}", d_form);
    println!("  3 log-grid slope U_x / S, a = 0.002    {:>12.6}", d_fine);
    println!("  4 price bumped in S, h = 0.01          {:>12.6}", d_bump);
    println!();
    println!("the four-quarter tree, node by node");
    println!("  u, d, p                                {:.6} {:.6} {:.6}", u4, d4, p4);
    println!("  step 0   S = {:.6}                V = {:.6}", S, r4[0][0]);
    println!("  step 1   S = {:.6} / {:.6}      V = {:.6} / {:.6}",
             S * d4, S * u4, r4[1][0], r4[1][1]);
    println!("  step 2   S = {:.6} / {:.6} / {:.6}", S * d4 * d4, S, S * u4 * u4);
    println!("  step 2   V = {:.6} / {:.6} / {:.6}", r4[2][0], r4[2][1], r4[2][2]);
    println!("  gaps h-, h+                            {:.6} {:.6}", hm4, hp4);
    println!("  slopes below, above the middle node     {:.6} {:.6}",
             (r4[2][1] - r4[2][0]) / hm4, (r4[2][2] - r4[2][1]) / hp4);
    println!("  node delta, dated 3 months in          {:>12.6}", dl4);
    println!("  node gamma, dated 6 months in          {:>12.6}", gm4);
    println!("  node theta, per year                   {:>12.6}", th4);
    println!();
    println!("the grid in x = ln(S/100): delta = U_x / S, gamma = (U_xx - U_x) / S^2");
    println!("  spacing a = 0.010    delta {:.6}   gamma {:.6}", d_grid, g_grid);
    println!("  spacing a = 0.002    delta {:.6}   gamma {:.6}", d_fine, g_fine);
    println!();
    println!("finer trees: the node estimates, and the formula at the node's own date");
    println!("  steps   node delta   node gamma   node theta   formula delta at that date");
    for (i, &m) in sizes.iter().enumerate() {
        println!("  {:>5}  {:>11.6}  {:>11.6}  {:>11.6}   {:>11.6}",
                 m, fine[i].2, fine[i].3, fine[i].4, bs_delta(S, T - T / m as f64));
    }
    println!();
    let join = |v: Vec<String>| v.join(" ");
    println!("chart, steps M       {}", join(sizes.iter().map(|m| format!("{:>6}", m)).collect()));
    println!("chart, gamma error % {}", join(fine.iter()
        .map(|f| format!("{:>6.2}", 100.0 * (f.3 / bs_gamma(S, T) - 1.0).abs())).collect()));
    println!("chart, theta error % {}", join(fine.iter()
        .map(|f| format!("{:>6.2}", 100.0 * (f.4 / bs_theta(S, T) - 1.0).abs())).collect()));
    println!();
    println!("what breaks");
    println!("  4 steps, gaps assumed equal: gamma     {:>12.6}", g_equal);
    println!("  U_x read as a share delta              {:>12.6}", ux);
    println!("  grid gamma with the -U_x term dropped  {:>12.6}", g_noterm);
    println!("  4 steps, theta taken along an up move  {:>12.6}", th_up);
    println!("  1024 steps, one cent of node error     {:>12.6}  of gamma", amp);

    assert!((call(S, T) - 9.227005508154).abs() < 1e-9, "formula vs the house call price");
    assert!((fx_chord - 14.5).abs() < 1e-12, "chord on the exact quadratic, by hand 14.5");
    assert!((fx_curv - 10.0).abs() < 1e-12, "curvature on the exact quadratic, by hand 10");
    assert!((d_fine - d_form).abs() < 2e-6, "log-grid slope vs the derivative formula");
    assert!((g_fine - bs_gamma(S, T)).abs() < 5e-7, "log-grid curvature vs the gamma formula");
    assert!(15.0 * (d_fine - d_form).abs() < (d_grid - d_form).abs(), "grid error shrinks like a^2");
    assert!((d_bump - d_form).abs() < 1e-6, "bumped price vs the derivative formula");
    assert!((d_tree - d_form).abs() < 1e-4, "1024-step node slope vs the formula");
    assert!((gm_1024 - bs_gamma(S, T)).abs() < 5e-4, "1024-step node gamma vs the formula");
    assert!((th_1024 - bs_theta(S, T)).abs() < 0.02, "1024-step node theta vs the formula");
    assert!((g_noterm - bs_gamma(S, T)).abs() > 5e-3, "dropping -U_x must really break gamma");
    assert!((fine[6].3 / bs_gamma(S, T) - 1.0).abs() * 8.0
            < (fine[0].3 / bs_gamma(S, T) - 1.0).abs(), "gamma error must shrink with steps");
    println!("ALL CHECKS PASS");
}
