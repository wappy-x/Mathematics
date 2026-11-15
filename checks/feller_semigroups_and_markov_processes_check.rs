// Feller semigroups -- the same check as the Python, in Rust.  No crates.
// Share price X_t = x + mu t + sigma W_t (pounds, years); payoff f: a 90/100/110 butterfly.
// Generator A f = mu f' + (1/2) sigma^2 f''; Feller semigroup P_t f(x) = E_x[f(X_t)].
// Roads: closed form; a price grid (a Markov chain) by uniformization and by the resolvent
// product; Monte Carlo along random paths (SplitMix64, seed 20261115).
const MU: f64 = 5.0; const SIG: f64 = 20.0; const X0: f64 = 100.0; const T: f64 = 1.0;
const WINGS: [(f64, f64); 3] = [(90.0, 1.0), (100.0, -2.0), (110.0, 1.0)];
fn phi(z: f64) -> f64 { (-0.5 * z * z).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn tent(y: f64) -> f64 { (10.0 - (y - 100.0).abs()).max(0.0) }
fn close(a: f64, b: f64, tol: f64) { assert!((a - b).abs() <= tol, "{} {}", a, b); }
fn ncdf(z: f64) -> f64 { // 1/2 + phi(z) (z + z^3/3 + z^5/(3*5) + ...)
    if z.abs() > 9.0 { return if z > 0.0 { 1.0 } else { 0.0 }; }
    let (mut term, mut s, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 * s.abs() || n < 5.0 {
        term = term * z * z / (2.0 * n + 3.0); n += 1.0; s += term;
    }
    0.5 + phi(z) * s
}
fn u(t: f64, x: f64, mu: f64, sig: f64) -> f64 { // P_t f(x): three normal-model calls
    if t == 0.0 { return tent(x); }
    let (m, s) = (x + mu * t, sig * t.sqrt());
    WINGS.iter().fold(0.0, |acc, &(k, c)| acc + c * ((m - k) * ncdf((m - k) / s) + s * phi((m - k) / s)))
}
fn rates(dl: f64, mu: f64, s2: f64) -> (usize, Vec<f64>, Vec<f64>) {
    let n = (200.0 / dl).round() as usize + 1;
    let mut up = vec![s2 / (2.0 * dl * dl) + mu / (2.0 * dl); n];
    let mut dn = vec![s2 / (2.0 * dl * dl) - mu / (2.0 * dl); n];
    up[n - 1] = 0.0; dn[0] = 0.0;
    (n, up, dn)
}
fn qmul(up: &[f64], dn: &[f64], v: &[f64], r: f64) -> Vec<f64> { // (Q - r I) v
    let n = v.len();
    (0..n).map(|i| (if i < n - 1 { up[i] * (v[i + 1] - v[i]) } else { 0.0 })
        + (if i > 0 { dn[i] * (v[i - 1] - v[i]) } else { 0.0 }) - r * v[i]).collect()
}
fn unif(dl: f64, f: &[f64], t: f64, r: f64) -> Vec<f64> { // sum of Poisson(lam t; k) K^k f
    let (n, up, dn) = rates(dl, MU, SIG * SIG);
    let lam = (0..n).map(|i| up[i] + dn[i]).fold(f64::MIN, f64::max) + r;
    let (mut v, mut out, mut lw, mut k) = (f.to_vec(), vec![0.0; n], -lam * t, 0.0);
    while k < lam * t + 12.0 * (lam * t).sqrt() + 30.0 {
        out = out.iter().zip(&v).map(|(o, a)| o + lw.exp() * a).collect();
        v = v.iter().zip(&qmul(&up, &dn, &v, r)).map(|(a, b)| a + b / lam).collect();
        k += 1.0; lw += (lam * t).ln() - k.ln();
    }
    out
}
fn resolvent_power(dl: f64, f: &[f64], t: f64, steps: usize) -> Vec<f64> { // (I - hQ)^-steps f
    let (n, up, dn) = rates(dl, MU, SIG * SIG);
    let (h, mut v) = (t / steps as f64, f.to_vec());
    for _ in 0..steps {
        let (mut cp, mut dp) = (vec![0.0; n], vec![0.0; n]);
        for i in 0..n {
            let a = -h * dn[i];
            let den = 1.0 + h * (up[i] + dn[i]) - (if i > 0 { a * cp[i - 1] } else { 0.0 });
            cp[i] = -h * up[i] / den; dp[i] = (v[i] - (if i > 0 { a * dp[i - 1] } else { 0.0 })) / den;
        }
        for i in (0..n).rev() { v[i] = dp[i] - (if i < n - 1 { cp[i] * v[i + 1] } else { 0.0 }); }
    }
    v
}
fn rnd(state: &mut u64) -> f64 { // SplitMix64, a uniform number in [0, 1)
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
}
fn main() {
    let (pi, exact) = (std::f64::consts::PI, u(T, X0, MU, SIG));
    println!("read, generator 5 f' + 200 f'': drift {:.6} pounds/yr, sigma = sqrt(2 x 200) = {:.6}", MU, 400f64.sqrt());
    println!("closed form, calls at 90, 100, 110 (mean 105, spread 20): {}", WINGS.iter().map(|&(k, _)| format!("{:.6}", (105.0 - k) * ncdf((105.0 - k) / 20.0) + 20.0 * phi((105.0 - k) / 20.0))).collect::<Vec<_>>().join(", "));
    println!("closed form, P_1 f(100) = {:.6} pounds, discounted at 5% {:.6}", exact, (-0.05f64).exp() * exact);
    // 1. The finite rehearsal: a Markov chain on prices 0, dl, ..., 200, walls at both ends.
    let steps = [5.0, 2.5, 1.25, 0.625];
    println!("read, grid step, up rate, down rate, drift from the row, variance rate from the row");
    for &dl in &steps {
        let (n, up, dn) = rates(dl, MU, SIG * SIG);
        let (a, b) = ((up[n / 2] - dn[n / 2]) * dl, (up[n / 2] + dn[n / 2]) * dl * dl);
        close(a, MU, 1e-9); close(b, SIG * SIG, 1e-9);
        println!("read, {:.3}, {:.6}, {:.6}, {:.6}, {:.6}", dl, up[0], dn[n - 1], a, b);
    }
    println!("read, h, (E X_h - x)/h, E (X_h - x)^2 / h, on the grid from 100; closed form 400 + 25 h");
    for &h in &[0.1, 0.01, 0.001] {
        let g1: Vec<f64> = (0..161).map(|i| i as f64 * 1.25 - 100.0).collect();
        let g2: Vec<f64> = g1.iter().map(|y| y * y).collect();
        let (m1, m2) = (unif(1.25, &g1, h, 0.0)[80] / h, unif(1.25, &g2, h, 0.0)[80] / h);
        close(m1, MU, 1e-9); close(m2, 400.0 + 25.0 * h, 1e-8);
        println!("read, {}, {:.6}, {:.6}, {:.6}", h, m1, m2, 400.0 + 25.0 * h);
    }
    println!("grid, cells N, step, P_1 f(100), error, error ratio");
    let (mut errs, mut g125): (Vec<f64>, f64) = (vec![], 0.0);
    for &dl in &steps {
        let n = (200.0 / dl).round() as usize + 1; let f: Vec<f64> = (0..n).map(|i| tent(i as f64 * dl)).collect();
        let g = unif(dl, &f, T, 0.0)[n / 2]; if dl == 1.25 { g125 = g; }
        errs.push(g - exact);
        let ratio = if errs.len() > 1 { format!("{:.3}", errs[errs.len() - 2] / errs[errs.len() - 1]) } else { "-".to_string() };
        println!("grid, {}, {:.3}, {:.6}, {:.6}, {}", n - 1, dl, g, g - exact, ratio);
    }
    assert!(3.5 < errs[2] / errs[3] && errs[2] / errs[3] < 4.5 && errs[3].abs() < 0.001);
    println!("chart, log10 N, {}", steps.iter().map(|d| format!("{:.3}", (200.0 / d).log10())).collect::<Vec<_>>().join(", "));
    println!("chart, log10 abs error, {}", errs.iter().map(|e| format!("{:.3}", e.abs().log10())).collect::<Vec<_>>().join(", "));
    // 2. Feller properties of the 41-state matrix P_1 (step 5).
    let n = 41;
    let cols: Vec<Vec<f64>> = (0..n).map(|j| unif(5.0, &(0..n).map(|i| if i == j { 1.0 } else { 0.0 }).collect::<Vec<f64>>(), T, 0.0)).collect();
    let neg = cols.iter().flatten().filter(|&&a| a < 0.0).count();
    let rowdev = (0..n).map(|i| ((0..n).fold(0.0, |s, j| s + cols[j][i]) - 1.0).abs()).fold(0.0, f64::max);
    let f5: Vec<f64> = (0..n).map(|i| tent(5.0 * i as f64)).collect();
    let (p1, half) = (unif(5.0, &f5, T, 0.0), unif(5.0, &unif(5.0, &f5, 0.5, 0.0), 0.5, 0.0));
    let semi = half.iter().zip(&p1).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    let top = p1.iter().cloned().fold(f64::MIN, f64::max);
    assert!(neg == 0 && rowdev < 1e-12 && top <= 10.0 && semi < 1e-12);
    let yes = |b: bool| if b { "yes" } else { "no" };
    println!("feller, step 5: negative entries {}, rows sum to 1: {}, P_0.5 P_0.5 f = P_1 f: {}, largest P_1 f = {:.6}", neg, yes(rowdev < 1e-12), yes(semi < 1e-12), top);
    let kill = unif(5.0, &vec![1.0; n], T, 0.05); close(kill[20], (-0.05f64).exp(), 1e-12);
    println!("killed, rate 0.05: P_1 1 = {:.6}, e^-0.05 = {:.6}", kill[20], (-0.05f64).exp());
    // 3. Hille-Yosida's road: (I - Q/n)^(-n) f, by n tridiagonal solves (step 1.25).
    println!("resolvent, n, (I - Q/n)^-n f at 100, gap to uniformization, n x gap");
    let (f125, mut r): (Vec<f64>, f64) = ((0..161).map(|i| tent(i as f64 * 1.25)).collect(), 0.0);
    for &st in &[10usize, 100, 1000] {
        r = resolvent_power(1.25, &f125, T, st)[80];
        println!("resolvent, {}, {:.6}, {:.6}, {:.4}", st, r, r - g125, st as f64 * (r - g125));
    }
    close(r, g125, 1e-3);
    // 4. Averages along random paths: four quarterly steps, SplitMix64, Box-Muller.
    let mut state = 20261115u64;
    let (paths, mut s1, mut s2) = (40000, 0.0, 0.0);
    for _ in 0..paths {
        let mut x = X0;
        for _ in 0..2 { // each pair of normals moves the price two quarters
            let (rr, b) = ((-2.0 * (1.0 - rnd(&mut state)).ln()).sqrt(), 2.0 * pi * rnd(&mut state));
            x += 2.0 * MU * 0.25 + SIG * 0.5 * (rr * b.cos() + rr * b.sin());
        }
        s1 += tent(x); s2 += tent(x).powi(2);
    }
    let (mc, se) = (s1 / paths as f64, ((s2 / paths as f64 - (s1 / paths as f64).powi(2)) / paths as f64).sqrt());
    assert!((mc - exact).abs() < 4.0 * se);
    println!("paths, {} paths of 4 quarterly steps: average payoff {:.6}, standard error {:.6}", paths, mc, se);
    // 5. Strong continuity in the sup norm: the butterfly (in C_0) against a digital (a jump).
    println!("continuity, h, sup |P_h f - f|, divided by sqrt h, digital gap at the jump, (P_h f - f)/h at 100");
    let mut last = 0.0;
    for &h in &[0.1, 0.01, 0.001] {
        let sup = (0..4001).map(|i| { let x = 80.0 + 0.01 * i as f64; (u(h, x, MU, SIG) - tent(x)).abs() }).fold(0.0, f64::max);
        let dig = 10.0 * ncdf(MU * f64::sqrt(h) / SIG);
        assert!(dig > 5.0 && sup < 16.0 * h.sqrt());
        println!("continuity, {}, {:.4}, {:.4}, {:.4}, {:.4}", h, sup, sup / h.sqrt(), dig, (u(h, X0, MU, SIG) - 10.0) / h);
        last = sup / h.sqrt();
    }
    close(last, 20.0 * (2.0 / pi).sqrt(), 0.02);
    // 6. The backward equation du/dt = A u at t = 1, x = 100, by finite differences.
    let (dt, dx) = (1e-4, 1e-2); let (up_, dn_) = (u(T, X0 + dx, MU, SIG), u(T, X0 - dx, MU, SIG));
    let ut = (u(T + dt, X0, MU, SIG) - u(T - dt, X0, MU, SIG)) / (2.0 * dt);
    let au = MU * (up_ - dn_) / (2.0 * dx) + 200.0 * (up_ - 2.0 * exact + dn_) / dx.powi(2);
    close(ut, au, 1e-5);
    println!("backward, du/dt = {:.6}, A u = 5 u_x + 200 u_xx = {:.6}", ut, au);
    // 7. What breaks, and the chart.
    println!("breaks, sigma read as sqrt 200 = {:.6}: P_1 f(100) = {:.6}", 200f64.sqrt(), u(T, X0, MU, 200f64.sqrt()));
    println!("breaks, drift dropped (the bar's heat flow): P_1 f(100) = {:.6}", u(T, X0, 0.0, SIG));
    println!("breaks, curvature sign flipped, step, zigzag growth rate per year, 800/step^2");
    for &dl in &steps {
        let (n, up, dn) = rates(dl, MU, -SIG * SIG);
        let z: Vec<f64> = (0..n).map(|i| if i % 2 == 0 { 1.0 } else { -1.0 }).collect();
        let gr = qmul(&up, &dn, &z, 0.0)[n / 2] / z[n / 2];
        close(gr, 800.0 / (dl * dl), 1e-9); println!("breaks, {:.3}, {:.6}, {:.6}", dl, gr, 800.0 / (dl * dl));
    }
    let xs: Vec<f64> = (0..13).map(|i| 70.0 + 5.0 * i as f64).collect();
    println!("chart, x, {}", xs.iter().map(|x| format!("{}", x)).collect::<Vec<_>>().join(", "));
    for &t in &[0.0, 0.25, 1.0] {
        println!("chart, t = {:.2}, {}", t, xs.iter().map(|&x| format!("{:.2}", u(t, x, MU, SIG))).collect::<Vec<_>>().join(", "));
    }
    println!("ALL CHECKS PASS");
}
