// The delta and the derivative of a switch -- the same check as the Python, in
// Rust.  No crates: std supplies exp and ln, nothing more.  Time is in
// milliseconds.  A switch puts 12 V on a lamp at t = 0, with a 100 uF capacitor
// across it.  The step's derivative is read on one smooth probe by three roads:
// the delta's rule 12*phi(0); the derivative moved onto the probe, integrated by
// Simpson's rule; and real switches that ramp up over eps ms, eps shrinking.
const V: f64 = 12.0; // volts
const C: f64 = 100e-6; // farads
const CEN: f64 = 2.0; // probe centre, ms
const W: f64 = 4.0; // probe half-width, ms: alive on (-2, 6)

fn phi(t: f64) -> f64 {
    // the probe: a smooth bump, zero outside (-2, 6)
    let u = (t - CEN) / W;
    if u.abs() < 1.0 { (-1.0 / (1.0 - u * u)).exp() } else { 0.0 }
}

fn dphi(t: f64) -> f64 {
    // its slope, per ms, by the chain rule
    let u = (t - CEN) / W;
    if u.abs() < 1.0 { phi(t) * (-2.0 * u / (1.0 - u * u).powi(2)) / W } else { 0.0 }
}

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64) -> f64 {
    // Simpson's rule, written out; n is even
    let n = 4000;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n {
        s += if k % 2 == 1 { 4.0 } else { 2.0 } * f(a + k as f64 * h);
    }
    s * h / 3.0
}

fn gap_integral(lo: f64, hi: f64) -> f64 {
    // integral of phi(t)/t over (-2, -lo) and (hi, 6); t = e^x right, t = -e^x left
    let right = simpson(|x| phi(x.exp()), hi.ln(), 6.0f64.ln());
    let left = simpson(|x| phi(-x.exp()), lo.ln(), 2.0f64.ln());
    right - left
}

fn log_weight(s: f64) -> f64 {
    // ln|t| phi'(t) after t = s*s, on each side
    if s == 0.0 { return 0.0; }
    4.0 * s * s.ln() * (dphi(s * s) + dphi(-s * s))
}

fn main() {
    // ---- road 1 and road 2: the delta's rule, and the derivative moved onto the probe
    let road1 = V * phi(0.0);
    let road2 = -simpson(|t| V * dphi(t), 0.0, 6.0);
    println!("switch 12 V at t = 0 ms; capacitor 100 uF; probe centre 2 ms, half-width 4 ms");
    println!("probe phi(0) = {:.6}, slope phi'(0) = {:.6} per ms", phi(0.0), dphi(0.0));
    println!("road 1, the delta's rule 12*phi(0): {:.6}", road1);
    println!("road 2, minus the integral of 12*phi' over t > 0: {:.6}", road2);

    // ---- road 3: a real switch ramps from 0 to 12 V over eps ms
    println!("road 3, ramp switch of rise time eps: peak current, charge, reading, error/eps");
    let mut ratios = Vec::new();
    for eps in [1.0, 0.1, 0.01, 0.001] {
        let slope = V / eps; // V per ms while the ramp rises
        let current = C * slope * 1000.0; // amps: C dV/dt with dt in seconds
        let charge = simpson(|_| current, 0.0, eps); // amps times ms is millicoulombs
        let reading = simpson(|t| slope * phi(t), 0.0, eps);
        ratios.push((reading - road1) / eps);
        println!("  eps {} ms: {:.1} A, {:.3} mC, {:.6}, {:.6}", eps, current, charge, reading,
                 ratios[ratios.len() - 1]);
    }
    let half_slope = V * dphi(0.0) / 2.0;
    println!("  error/eps tends to 12*phi'(0)/2 = {:.6}", half_slope);

    // ---- the finite rehearsal: the step as a list of N samples on (-4, 8) ms
    println!("finite rehearsal, N samples: spike height V/ms, reading, by parts, error");
    for n in [12usize, 120, 1200, 12000] {
        let h = 12.0 / n as f64;
        let ts: Vec<f64> = (0..n).map(|k| -4.0 + (k as f64 + 0.5) * h).collect();
        let step: Vec<f64> = ts.iter().map(|&t| if t >= 0.0 { V } else { 0.0 }).collect();
        let mut diff = vec![0.0; n];
        for k in 1..n { diff[k] = (step[k] - step[k - 1]) / h; }
        let reading: f64 = (0..n).map(|k| diff[k] * phi(ts[k]) * h).sum();
        let by_parts: f64 = -(0..n - 1).map(|k| step[k] * (phi(ts[k + 1]) - phi(ts[k]))).sum::<f64>();
        assert!((reading - by_parts).abs() < 1e-12); // summation by parts, exact
        let top = diff.iter().cloned().fold(f64::MIN, f64::max);
        println!("  N {}: {:.1}, {:.6}, {:.6}, {:.6}", n, top, reading, by_parts, reading - road1);
    }

    // ---- the jump rule: on at 0 ms, off at 5 ms
    let jump_rule = V * phi(0.0) - V * phi(5.0);
    let moved = -simpson(|t| V * dphi(t), 0.0, 5.0);
    println!("jump rule, on at 0 and off at 5 ms: 12*phi(0) - 12*phi(5) = {:.6}; moved onto the probe = {:.6}",
             jump_rule, moved);

    // ---- the principal value of 1/t: the derivative of ln|t|
    println!("principal value of 1/t on the probe, gap (-eps, eps) cut out:");
    let mut gaps = Vec::new();
    for eps in [0.1, 0.01, 0.001] {
        gaps.push(gap_integral(eps, eps));
        println!("  eps {}: {:.6}", eps, gaps[gaps.len() - 1]);
    }
    let log_road = -simpson(log_weight, 0.0, 6.0f64.sqrt());
    println!("  minus the integral of ln|t| phi'(t): {:.6}", log_road);
    let lopsided = gap_integral(0.001, 0.002);
    let ln2_shift = phi(0.0) * 2.0f64.ln();

    // ---- what breaks
    println!("mistake 1, classical derivative, zero off the switch: reading 0, charge 0 mC, not {:.6}", road1);
    println!("mistake 2, minus sign dropped: {:.6}", -road2);
    println!("mistake 3, lopsided gap (-0.001, 0.002): {:.6}, off by phi(0) ln 2 = {:.6}", lopsided, ln2_shift);
    let squares: Vec<String> = [1.0, 0.1, 0.01, 0.001].iter()
        .map(|&e: &f64| format!("{:.0}", simpson(|_| (V / e).powi(2), 0.0, e))).collect();
    println!("mistake 4, squaring the ramp's slope, integral of (12/eps)^2: {}", squares.join(", "));

    // ---- chart: capacitor current for rise times 2, 1 and 0.5 ms
    let xs: Vec<f64> = (0..13).map(|k| -0.5 + 0.25 * k as f64).collect();
    for eps in [2.0, 1.0, 0.5] {
        let row: Vec<String> = xs.iter()
            .map(|&x| format!("{:.2}", if x >= 0.0 && x < eps { C * V / eps * 1000.0 } else { 0.0 }))
            .collect();
        println!("chart eps {}: {}", eps, row.join(", "));
    }

    assert!((road1 - road2).abs() < 1e-9); // rule against moved derivative
    assert!((ratios[3] - half_slope).abs() < 1e-3); // ramp error falls like eps
    assert!((jump_rule - moved).abs() < 1e-9); // two jumps, two deltas
    assert!((gaps[2] - log_road).abs() < 3.0 * 0.001 * dphi(0.0)); // PV: gap against log road
    assert!(((gaps[2] - lopsided) - ln2_shift).abs() < 1e-3); // lopsided gap is off by ln 2
    println!("ALL CHECKS PASS");
}
