// Weak derivatives and Sobolev spaces -- the same check as the Python, in Rust.
// No crates.  The load: an illustrative evening peak on a feeder, 4 MW above
// base at 18:00, ramping up from 17:00 and down to 19:00.  With t in hours after
// 17:00, u(t) = 4(1 - |t - 1|) on (0, 2).  The kink at t = 1 has no slope; the
// weak derivative g = +4 then -4 MW/h is tested against smooth probes.
fn u(t: f64) -> f64 { if (0.0..=2.0).contains(&t) { 4.0 * (1.0 - (t - 1.0).abs()) } else { 0.0 } }
fn g(t: f64) -> f64 { if t < 1.0 { 4.0 } else { -4.0 } }          // the claimed weak derivative
fn switch(t: f64) -> f64 { if t > 1.0 { 4.0 } else { 0.0 } }      // a 4 MW block switched on at 18:00

fn bump(t: f64, c: f64, r: f64) -> f64 {                           // smooth probe, zero off (c - r, c + r)
    let s = (t - c) / r;
    if s.abs() < 1.0 { (-1.0 / (1.0 - s * s)).exp() } else { 0.0 }
}

fn dbump(t: f64, c: f64, r: f64) -> f64 {                          // its slope, by the chain rule
    let s = (t - c) / r;
    if s.abs() < 1.0 { bump(t, c, r) * (-2.0 * s / (r * (1.0 - s * s).powi(2))) } else { 0.0 }
}

fn gauss(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {          // two-point Gauss on n pieces:
    let n = 2000;                                                  // never samples an end point
    let (h, q) = ((b - a) / n as f64, (b - a) / n as f64 / (2.0 * 3.0f64.sqrt()));
    let mut total = 0.0;
    for k in 0..n {
        let m = a + (k as f64 + 0.5) * h;
        total += f(m - q) + f(m + q);
    }
    total * h / 2.0
}

fn integral(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {       // split at the kink or jump at 1
    if a < 1.0 && 1.0 < b { gauss(f, a, 1.0) + gauss(f, 1.0, b) } else { gauss(f, a, b) }
}

fn grid(n: usize) -> (f64, Vec<f64>, f64, f64, f64) {              // the finite rehearsal: n steps of h
    let h = 2.0 / n as f64;
    let vals: Vec<f64> = (0..=n).map(|i| u(i as f64 * h)).collect();
    let trap = h * vals.iter().map(|v| v * v).sum::<f64>();       // ends are 0: the trapezoid sum
    let slope: f64 = (0..n).map(|i| h * ((vals[i + 1] - vals[i]) / h).powi(2)).sum();
    let bend: f64 = (1..n).map(|i| h * ((vals[i + 1] - 2.0 * vals[i] + vals[i - 1]) / (h * h)).powi(2)).sum();
    (h, vals, trap, slope, bend)
}

fn main() {
    println!("finite rehearsal, N = 16 steps, probe centred 0.7, half-width 0.4:");
    let (h, vals, _, _, _) = grid(16);
    let ph: Vec<f64> = (0..17).map(|i| bump(i as f64 * h, 0.7, 0.4)).collect();
    let left: f64 = (0..16).map(|i| vals[i] * (ph[i + 1] - ph[i])).sum();
    let right: f64 = -(0..16).map(|i| (vals[i + 1] - vals[i]) * ph[i + 1]).sum::<f64>();
    println!("  sum u_i (phi_i+1 - phi_i) = {:.9};  -sum (u_i+1 - u_i) phi_i+1 = {:.9}", left, right);
    assert!((left - right).abs() < 1e-12);                         // summation by parts, no boundary term

    println!("weak derivative test, integral u phi' against -integral g phi:");
    for &(c, r) in &[(0.9, 0.5), (0.7, 0.4), (1.2, 0.6)] {
        let lhs = integral(&|t| u(t) * dbump(t, c, r), c - r, c + r);
        let rhs = -integral(&|t| g(t) * bump(t, c, r), c - r, c + r);
        println!("  probe c = {:.1}, r = {:.1}:  {:.9}  {:.9}", c, r, lhs, rhs);
        assert!((lhs - rhs).abs() < 1e-9);
    }
    let (c, r) = (1.0, 0.5);
    let bump_area = integral(&|t| bump(t, c, r), c - r, c + r);
    let wrong = integral(&|t| u(t) * dbump(t, c, r), c - r, c + r) + integral(&|t| 4.0 * bump(t, c, r), c - r, c + r);
    println!("mistake 1, slope +4 everywhere: residual on probe c = 1.0, r = 0.5 is {:.6}", wrong);
    assert!((wrong - 4.0 * bump_area).abs() < 1e-9);               // 8 times the right half of the probe

    println!("mistake 2, jumps: probes centred at 1, height phi(1) = {:.6}", bump(1.0, 1.0, 0.5));
    for &r in &[0.5, 0.05, 0.005] {
        let sp = integral(&|t| switch(t) * dbump(t, 1.0, r), 1.0 - r, 1.0 + r);
        let gp = integral(&|t| g(t) * dbump(t, 1.0, r), 1.0 - r, 1.0 + r);
        let area = integral(&|t| bump(t, 1.0, r), 1.0 - r, 1.0 + r);
        println!("  r = {:<6} integral switch phi' {:.6}  integral g phi' {:.6}  integral phi {:.6}", r, sp, gp, area);
        let e = std::f64::consts::E;
        assert!((sp + 4.0 / e).abs() < 1e-9 && (gp - 8.0 / e).abs() < 1e-9);   // -4 phi(1) and 8 phi(1)
    }

    let (mut run, mut worst) = (0.0f64, 0.0f64);                   // absolute continuity: u is the running integral of g
    for i in 0..2000 {
        run += g((i as f64 + 0.5) / 1000.0) / 1000.0;
        worst = worst.max((run - u((i + 1) as f64 / 1000.0)).abs());
    }
    println!("running integral of g reproduces u: largest gap {:.1e} MW", worst);
    assert!(worst < 1e-12);

    let (l2, d2) = (32.0 / 3.0, 32.0);                              // closed forms, MW^2 h and (MW/h)^2 h
    let mut h1 = 0.0;
    for p in [1i32, 2] {
        let up = integral(&|t| u(t).abs().powi(p), 0.0, 2.0);
        let gp = integral(&|t| g(t).abs().powi(p), 0.0, 2.0);
        let norm = (up + gp).powf(1.0 / p as f64);
        println!("W^(1,{}): integral |u|^{} = {:.6}, integral |g|^{} = {:.6}, norm {:.6}", p, p, up, p, gp, norm);
        let exact = (2.0 * 4f64.powi(p) * (p + 2) as f64 / (p + 1) as f64).powf(1.0 / p as f64);
        assert!((norm - exact).abs() < 1e-9);
        h1 = norm;
    }
    let slopes: Vec<f64> = (0..16).map(|i| (vals[i + 1] - vals[i]).abs() / h).collect();
    let (mu, mg) = (vals.iter().cloned().fold(0.0, f64::max), slopes.iter().cloned().fold(0.0, f64::max));
    println!("W^(1,inf): max |u| = {:.6}, max |g| = {:.6}, norm {:.6}", mu, mg, mu.max(mg));
    println!("H^1 norm squared {:.6} = 32/3 + 32 = {:.6}; u(0) = {:.1}, u(2) = {:.1}", h1 * h1, l2 + d2, u(0.0), u(2.0));
    assert!((h1 * h1 - 128.0 / 3.0).abs() < 1e-9);

    println!("truncation:     N        h   sum u^2    sum u'^2    sum u''^2");
    for n in [4usize, 16, 64, 256] {
        let (h, _, trap, slope, bend) = grid(n);
        println!("           {:6} {:8.5} {:9.6} {:11.6} {:12.3}", n, h, trap, slope, bend);
        assert!((trap - (l2 + 16.0 * h * h / 3.0)).abs() < 1e-9 && (slope - d2).abs() < 1e-9 && (bend - 64.0 / h).abs() < 1e-6);
    }

    println!("rounding the corner over 1 - eps to 1 + eps by a parabola:");
    for eps in [0.25f64, 0.0625, 0.015625] {
        let v = |t: f64| 4.0 - 2.0 * eps - 2.0 * (t - 1.0).powi(2) / eps;
        let dv = |t: f64| -4.0 * (t - 1.0) / eps;
        let d0 = integral(&|t| (u(t) - v(t)).powi(2), 1.0 - eps, 1.0 + eps);
        let d1 = integral(&|t| (g(t) - dv(t)).powi(2), 1.0 - eps, 1.0 + eps);
        println!("  eps {:<9} peak {:.4}  H^1 distance squared {:.6}  distance {:.6}  integral v''^2 {:.0}",
                 eps, 4.0 - 2.0 * eps, d0 + d1, (d0 + d1).sqrt(), 32.0 / eps);
        assert!((d0 + d1 - (8.0 * eps.powi(3) / 5.0 + 32.0 * eps / 3.0)).abs() < 1e-9);
    }

    let mins = 30.0f64;                                             // mistake 4: the same load in minutes
    let uvals: [f64; 5] = [0.0, 2.0, 4.0, 2.0, 0.0];
    let slope_min: f64 = (0..4).map(|i| mins * ((uvals[i + 1] - uvals[i]) / mins).powi(2)).sum();
    println!("mistake 4, minutes: integral u^2 = {:.3} MW^2 min, integral u'^2 = {:.6}", l2 * 60.0, slope_min);
    assert!((slope_min - d2 / 60.0).abs() < 1e-12);
    let x = |t: f64| 40.0 + 160.0 * t;                              // figure scale: 160 px per hour,
    let y = |m: f64| 130.0 - 25.0 * m;                              // 25 px per MW, 10 px per MW/h
    println!("figure, tent px: ({:.0}, {:.0}) ({:.0}, {:.0}) ({:.0}, {:.0}); rounded peak ({:.0}, {:.1}); slope px: +4 at y {}, -4 at y {}, rounded from x {:.0} to {:.0}",
             x(0.0), y(u(0.0)), x(1.0), y(u(1.0)), x(2.0), y(u(2.0)), x(1.0), y(3.5), 220 - 40, 220 + 40, x(0.75), x(1.25));
    println!("ALL CHECKS PASS");
}
