// Dependence and influence -- the check behind the card.  std only, no crates.
// A tap on a steel string, felt 10 cm away.  Roads: d'Alembert's formula; a grid
// stepped from neighbours only; the energy in a shrinking cone; in 3-D, a closed
// form against Kirchhoff's sphere average; for heat, an erf series against Simpson.
use std::f64::consts::PI;
const T: f64 = 100.0; const RHO: f64 = 0.01; // tension N, mass per metre kg/m (illustrative)
const V0: f64 = 0.5; const A: f64 = 0.01; const X: f64 = 0.10; // tap speed m/s, tap half-width m, listening point m
const KAPPA: f64 = 1.2e-5; // diffusivity of steel, m^2/s (typical value)

fn c() -> f64 { (T / RHO).sqrt() }

fn tap(x: f64, centre: f64) -> f64 { // starting velocity: V0 on the tap, half at its edges
    let d = (x - centre).abs(); if d < A - 1e-12 { V0 } else if (d - A).abs() < 1e-12 { V0 / 2.0 } else { 0.0 }
}

fn string(x: f64, t: f64, taps: &[f64]) -> f64 { // road 1, d'Alembert: tap length inside [x-ct, x+ct], over 2c
    let s: f64 = taps.iter().map(|&p| ((x + c() * t).min(p + A) - (x - c() * t).max(p - A)).max(0.0)).sum();
    V0 * s / (2.0 * c())
}

fn grid(r: f64, steps: usize, taps: &[f64]) -> (Vec<f64>, Vec<f64>, f64) { // road 2: neighbours only
    let (dx, n) = (0.001, 500usize);
    let dt = r * dx / c();
    let mut old = vec![0.0; 2 * n + 1];
    let mut new: Vec<f64> = (0..2 * n + 1)
        .map(|j| { let mut g = 0.0; for &p in taps { g += tap((j as f64 - n as f64) * dx, p); } dt * g })
        .collect();
    let mut seen = vec![0.0, new[n + 100]]; // history at x = 10 cm
    for _ in 0..steps - 1 {
        let mut nxt = vec![0.0; 2 * n + 1];
        for j in 1..2 * n {
            nxt[j] = 2.0 * (1.0 - r * r) * new[j] + r * r * (new[j + 1] + new[j - 1]) - old[j];
        }
        old = std::mem::replace(&mut new, nxt);
        seen.push(new[n + 100]);
    }
    (seen, new, dt)
}

fn cone_energy(t: f64) -> f64 { // road 3: (rho/2) sum of u_t^2 + c^2 u_x^2 over |x - x0| <= c(t0 - t)
    let (x0, t0, h) = (0.10, 0.0015, 2e-5);
    let rr = c() * (t0 - t);
    let (mut e, mut k) = (0.0, 0.0);
    while -rr + (k + 0.5) * h < rr {
        let x = x0 - rr + (k + 0.5) * h;
        let tm = (t - h / c()).max(0.0);
        let ut = (string(x, t + h / c(), &[0.0]) - string(x, tm, &[0.0])) / ((t + h / c()) - tm);
        let ux = (string(x + h, t, &[0.0]) - string(x - h, t, &[0.0])) / (2.0 * h);
        e += 0.5 * RHO * (ut * ut + c() * c() * ux * ux) * h;
        k += 1.0;
    }
    e
}

fn halves_inside(t: f64) -> f64 { // closed form: each half-tap carries rho V0^2 A / 2 of energy
    let (x0, t0) = (0.10, 0.0015);
    let (lo, hi) = (x0 - c() * (t0 - t), x0 + c() * (t0 - t));
    let part = |p: f64, q: f64| (q.min(hi) - p.max(lo)).max(0.0) / (2.0 * A);
    RHO * V0 * V0 * A / 2.0 * (part(-A - c() * t, A - c() * t) + part(-A + c() * t, A + c() * t))
}

fn ball_closed(r: f64, t: f64) -> f64 { // 3-D, radial reduction
    let l = r - c() * t; if l.abs() < A { V0 * (A * A - l * l) / (4.0 * c() * r) } else { 0.0 }
}

fn ball_kirchhoff(r: f64, t: f64) -> f64 { // 3-D, Kirchhoff: t times the average tap speed on the sphere
    let (rr, m) = (c() * t, 200000usize);
    let mut s = 0.0;
    for k in 0..m {
        let th = (k as f64 + 0.5) * PI / m as f64;
        if r * r + rr * rr + 2.0 * r * rr * th.cos() < A * A { s += th.sin(); }
    }
    t * V0 * s * (PI / m as f64) / 2.0
}

fn erf(z: f64) -> f64 { // all-positive series
    let (mut term, mut s, mut n) = (z, z, 0.0);
    while term.abs() > 1e-17 * s.abs() {
        n += 1.0;
        term *= 2.0 * z * z / (2.0 * n + 1.0);
        s += term;
    }
    2.0 / PI.sqrt() * (-z * z).exp() * s
}

fn heat(x: f64, t: f64) -> f64 { // heat road 1
    let s = (4.0 * KAPPA * t).sqrt();
    0.5 * (erf((x + A) / s) - erf((x - A) / s))
}

fn simpson_w(k: usize, m: usize) -> f64 { if k == 0 || k == m { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 } }

fn heat_simpson(x: f64, t: f64) -> f64 { // heat road 2: the bell summed over the hot spot
    let m = 2000usize;
    let h = 2.0 * A / m as f64;
    let g = |y: f64| (-(x - y).powi(2) / (4.0 * KAPPA * t)).exp() / (4.0 * PI * KAPPA * t).sqrt();
    h / 3.0 * (0..=m).map(|k| simpson_w(k, m) * g(-A + k as f64 * h)).sum::<f64>()
}

fn heat_log10(x: f64, t: f64) -> (f64, f64) { // far tail: two roads to log10 of the fraction
    let s = (4.0 * KAPPA * t).sqrt();
    let (z1, z2) = ((x - A) / s, (x + A) / s);
    let asym = (-z1 * z1 - (2.0 * z1 * PI.sqrt()).ln() + (1.0 - 1.0 / (2.0 * z1 * z1) + 3.0 / (4.0 * z1.powi(4))).ln()) / 10f64.ln();
    let (w, m) = ((z2 - z1).min(40.0 / z1), 20000usize);
    let hw = w / m as f64;
    let mut i = 0.0;
    for k in 0..=m { let v = k as f64 * hw; i += simpson_w(k, m) * (-2.0 * z1 * v - v.powi(2)).exp(); }
    let i = hw / 3.0 * i;
    (asym, (-z1 * z1 + (i / PI.sqrt()).ln()) / 10f64.ln())
}

fn main() {
    let (ms, um, cc) = (1000.0, 1e6, c());
    println!("string: c = sqrt({:.0} N / {} kg/m) = {:.0} m/s; tap {} m/s on |x| <= {:.0} cm", T, RHO, cc, V0, A * 100.0);
    println!("dependence of (10 cm, 1.00 ms): x from {:.0} cm to {:.0} cm; it holds {:.0} cm of the tap", (X - cc * 0.001) * 100.0, (X + cc * 0.001) * 100.0, string(X, 0.001, &[0.0]) * 2.0 * cc / V0 * 100.0);
    println!("influence of the tap at 1.00 ms: |x| <= {:.0} cm", (A + cc * 0.001) * 100.0);
    let (t_on, t_full) = ((X - A) / cc, (X + A) / cc);
    println!("first motion at 10 cm: {:.2} ms; full by {:.2} ms; plateau {:.0} um", t_on * ms, t_full * ms, V0 * A / cc * um);
    let (seen, _, dt) = grid(1.0, 150, &[0.0]);
    let gap = (0..151).map(|k| (seen[k] - string(X, k as f64 * dt, &[0.0])).abs()).fold(0.0, f64::max);
    let first = (0..151).find(|&k| seen[k] != 0.0).unwrap();
    println!("grid, Courant 1: largest gap to d'Alembert at 10 cm = {:.6} um; first nonzero sample {:.2} ms", gap * um, first as f64 * dt * ms);
    let row = |f: &dyn Fn(f64) -> String| (0..15).map(|k| f((0.70 + 0.05 * k as f64) / ms)).collect::<Vec<_>>().join(" ");
    println!("string u(10 cm, t) um, t = 0.70 to 1.40 ms step 0.05: {}", row(&|t| format!("{:.1}", string(X, t, &[0.0]) * um)));
    println!("3-D  u(10 cm, t) um, t = 0.70 to 1.40 ms step 0.05: {}", row(&|t| format!("{:.4}", ball_closed(X, t) * um)));
    for tm in [0.95, 1.00, 1.20] { println!("3-D at {:.2} ms: closed form {:.4} um, Kirchhoff average {:.4} um", tm, ball_closed(X, tm / ms) * um, ball_kirchhoff(X, tm / ms) * um); }
    let e: Vec<(f64, f64, f64)> = [0.0, 0.25, 0.5, 1.0, 1.25, 1.4].iter().map(|&tm| (tm, cone_energy(tm / ms), halves_inside(tm / ms))).collect();
    for &(tm, en, ex) in &e { println!("energy in the cone to (10 cm, 1.50 ms) at {:.2} ms: differences {:.3} uJ, half-taps {:.3} uJ", tm, en * 1e6, ex * 1e6); }
    let (a2, s2) = (grid(1.0, 100, &[0.0, 0.30]).0[100], grid(1.0, 100, &[0.0]).0[100]);
    println!("second tap at 30 cm: u(10 cm, 1.00 ms) = {:.3} um without, {:.3} um with", s2 * um, a2 * um);
    let lg = [heat_log10(X, 0.001), heat_log10(X, 1.0)];
    for (ts, &(l1, l2)) in ["1 ms", "1 s"].iter().zip(lg.iter()) { println!("heat, kappa = {:.0} mm^2/s: fraction at 10 cm after {} = 10^{:.2} (tail series), 10^{:.2} (Simpson)", KAPPA * 1e6, ts, l1, l2); }
    println!("heat fraction at 10 cm after 100 s: erf series {:.6}, Simpson {:.6}", heat(X, 100.0), heat_simpson(X, 100.0));
    println!("second hot spot at 30 cm: heat at 10 cm after 100 s goes from {:.6} to {:.6}", heat(X, 100.0), heat(X, 100.0) + heat(X - 0.30, 100.0));
    let (mut lo, mut hi) = (10.0f64, 2000.0f64); // golden-section search for the heat peak at 10 cm
    let gr = (5f64.sqrt() - 1.0) / 2.0;
    while hi - lo > 1e-3 {
        let (m1, m2) = (hi - gr * (hi - lo), lo + gr * (hi - lo));
        if heat(X, m1) < heat(X, m2) { lo = m1; } else { hi = m2; }
    }
    let tp = (lo + hi) / 2.0;
    println!("heat peak at 10 cm: {:.1} s, {:.2} % of the excess; point-source rule x^2/(2 kappa) = {:.1} s", tp, heat(X, tp) * 100.0, X * X / (2.0 * KAPPA));
    println!("what breaks: timing from the tap centre gives {:.2} ms, but u there is already {:.0} um", X / cc * ms, string(X, X / cc, &[0.0]) * um);
    println!("what breaks: forgetting the tap width puts the influence edge at {:.0} cm, not {:.0} cm", cc * 0.001 * 100.0, (A + cc * 0.001) * 100.0);
    println!("what breaks: 3-D read as a string at 1.50 ms gives {:.0} um; 3-D is at {:.0} um", string(X, 0.0015, &[0.0]) * um, ball_closed(X, 0.0015) * um);
    let (s11, last11, dt11) = grid(1.1, 136, &[0.0]);
    let f11 = (0..137).find(|&k| s11[k] != 0.0).unwrap();
    let big = last11.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    println!("what breaks: Courant 1.1, first motion at {:.2} ms; largest |u| at {:.2} ms = 10^{:.1} um", f11 as f64 * dt11 * ms, 136.0 * dt11 * ms, (big * um).log10());
    let px = |xc: f64| 40.0 + 10.0 * (xc + 15.0);
    println!("figure, px: tap ({:.0}..{:.0}, 260); P ({:.0}, {:.0}); base ({:.0}..{:.0}, 260); first motion y {:.0}", px(-1.0), px(1.0), px(10.0), 260.0 - 150.0 * 1.0, px(0.0), px(20.0), 260.0 - 150.0 * t_on * ms);
    assert!(gap < 1e-12); // the neighbour-only grid lands on d'Alembert's formula
    assert!((first as f64 * dt - t_on).abs() < dt + 1e-12); // first motion at the cone's edge
    assert!(e.iter().all(|&(_, en, ex)| (en - ex).abs() < 0.01 * V0 * V0 * RHO * A)); // differenced energy = half-tap count
    assert!(e.windows(2).all(|w| w[1].1 <= w[0].1 + 1e-9)); // energy in the shrinking cone never rises
    assert!([0.95, 1.0, 1.2].iter().all(|&tm| (ball_closed(X, tm / ms) - ball_kirchhoff(X, tm / ms)).abs() < 1e-3 * V0 * A * A / (4.0 * cc * X)));
    assert!((a2 - s2).abs() < 1e-15 && (s2 - string(X, 0.001, &[0.0])).abs() < 1e-12); // data outside [0, 20] cm changes nothing
    assert!(lg.iter().all(|&(l1, l2)| (l1 - l2).abs() < 0.01)); // two roads to the heat's far tail
    assert!((heat(X, 100.0) - heat_simpson(X, 100.0)).abs() < 1e-9 && heat(X - 0.30, 100.0) > 1e-6);
    assert!((tp - X * X / (2.0 * KAPPA)).abs() < 0.01 * tp); // peak time matches the point-source rule
    assert!(f11 as f64 * dt11 > t_on + 0.05e-3); // Courant 1.1: the grid's cone is too narrow
    println!("ALL CHECKS PASS");
}
