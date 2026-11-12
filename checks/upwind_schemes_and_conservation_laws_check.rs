// Flow problems: upwind, centred and Lax-Wendroff steps on a river pulse -- the
// same check in Rust, std only, no crates.
// Road 1: the exact shifted pulse.  Road 2: each grid scheme, stepped with no formula.
// Road 3: the modified equation, a Gaussian widened by the numerical diffusivity.
use std::f64::consts::PI;

const C: f64 = 2.0; const H: f64 = 0.25; const DT: f64 = 0.1; const T: f64 = 3.0;
const LO: f64 = -4.0; const HI: f64 = 12.0;

fn f(x: f64) -> f64 { 10.0 * (-x * x).exp() }         // the spill at t = 0, mg/L

fn step(s: &str, a: f64, b: f64, c: f64, nu: f64) -> f64 {   // one update from a | b | c
    match s {
        "upwind" => b - nu * (b - a),
        "downwind" => b - nu * (c - b),
        "centred" => b - nu / 2.0 * (c - a),
        _ => b - nu / 2.0 * (c - a) + nu * nu / 2.0 * (c - 2.0 * b + a), // Lax-Wendroff
    }
}

fn run(s: &str, h: f64, nu: f64, t: f64) -> Vec<f64> {
    let n = ((HI - LO) / h).round() as usize + 1;
    let mut u: Vec<f64> = (0..n).map(|i| f(LO + i as f64 * h)).collect();
    for _ in 0..(t / (nu * h / C)).round() as usize {
        let mut v = vec![0.0; n];
        for i in 1..n - 1 { v[i] = step(s, u[i - 1], u[i], u[i + 1], nu) }
        v[n - 1] = u[n - 2];
        u = v;
    }
    u
}

fn at(u: &[f64], x: f64, h: f64) -> f64 { u[((x - LO) / h).round() as usize] }
fn gauss(x: f64, t: f64, alpha: f64) -> f64 {          // road 3: variance 1/2 + 2 alpha t
    let v = 0.5 + 2.0 * alpha * t;
    10.0 * (0.5 / v).sqrt() * (-(x - C * t).powi(2) / (2.0 * v)).exp()
}
fn alpha_num(h: f64, nu: f64) -> f64 { C * h * (1.0 - nu) / 2.0 }
fn mx(u: &[f64]) -> f64 { u.iter().fold(f64::MIN, |m, &v| m.max(v)) }
fn mn(u: &[f64]) -> f64 { u.iter().fold(f64::MAX, |m, &v| m.min(v)) }
fn maxgap(u: &[f64], h: f64, g: &dyn Fn(f64) -> f64) -> f64 {
    u.iter().enumerate().fold(0.0, |m, (i, &v)| m.max((v - g(LO + i as f64 * h)).abs()))
}
fn row(u: &[f64], xs: &[f64]) -> String {
    xs.iter().map(|&x| format!("{:.2}", at(u, x, H))).collect::<Vec<_>>().join(", ")
}

fn main() {
    let nu0 = C * DT / H;
    println!("river {:.1} km/h, cell h = {:.2} km, step {:.1} h, Courant number nu = {:.2}, {} steps to {:.1} h",
             C, H, DT, nu0, (T / DT).round(), T);
    let (up, lw, ce) = (run("upwind", H, nu0, T), run("Lax-Wendroff", H, nu0, T), run("centred", H, nu0, T));
    let an = alpha_num(H, nu0);
    let mass: f64 = up.iter().sum::<f64>() * H;
    println!("exact: peak {:.4} mg/L at {:.0} km; mass 10 sqrt(pi) = {:.7} mg/L km", f(0.0), C * T, 10.0 * PI.sqrt());
    println!("upwind: peak {:.4}, lowest {:.4}, mass {:.7}", mx(&up), mn(&up), mass);
    println!("numerical diffusivity c h (1 - nu)/2 = {:.4} km^2/h = {:.2} m^2/s", an, an * 1e6 / 3600.0);
    println!("modified equation: variance 0.5 + 2 x {:.2} x {:.0} = {:.4} km^2, peak {:.4}", an, T, 0.5 + 2.0 * an * T, gauss(C * T, T, an));
    let gap_mod = maxgap(&up, H, &|x| gauss(x, T, an));
    let gap_ex = maxgap(&up, H, &|x| f(x - C * T));
    println!("upwind's largest gap: from the exact pulse {:.4}, from the modified equation {:.4}", gap_ex, gap_mod);
    println!("upwind peak sits {:.4} below the modified equation's; the water at 6.00 km came from {:.2} km", gauss(C * T, T, an) - mx(&up), C * T - C * DT);
    println!("Lax-Wendroff: peak {:.4}, lowest {:.4}, mass {:.7}", mx(&lw), mn(&lw), lw.iter().sum::<f64>() * H);
    println!("centred: peak {:.4}, lowest {:.4}", mx(&ce), mn(&ce));
    println!("Lax-Wendroff with negatives clipped to zero: mass {:.7}", lw.iter().map(|&v| v.max(0.0)).sum::<f64>() * H);

    println!("one upwind step by hand, cells at 5.75 and 6.00 km, t = 2.9 -> 3.0 h:");
    let u29 = run("upwind", H, nu0, 2.9);
    let (a, b) = (at(&u29, 5.75, H), at(&u29, 6.0, H));
    println!("  {:.4} - {:.1} x ({:.4} - {:.4}) = {:.4}; grid {:.4}", b, nu0, b, a, b - nu0 * (b - a), at(&up, 6.0, H));

    println!("growth factor |g| per step: measured on a periodic grid of 16 cells | formula");
    let measured = |s: &str, m: usize| -> (f64, f64) {   // feed in cos(xi j); energy ratio
        let xi = 2.0 * PI * m as f64 / 16.0;
        let u: Vec<f64> = (0..16).map(|j| (xi * j as f64).cos()).collect();
        let v: Vec<f64> = (0..16).map(|j| step(s, u[(j + 15) % 16], u[j], u[(j + 1) % 16], nu0)).collect();
        ((v.iter().map(|w| w * w).sum::<f64>() / u.iter().map(|w| w * w).sum::<f64>()).sqrt(), xi)
    };
    let form = |s: &str, x: f64| -> f64 {
        match s {
            "upwind" => (1.0 - 2.0 * nu0 * (1.0 - nu0) * (1.0 - x.cos())).sqrt(),
            "centred" => (1.0 + nu0 * nu0 * x.sin().powi(2)).sqrt(),
            _ => (1.0 - nu0 * nu0 * (1.0 - nu0 * nu0) * (1.0 - x.cos()).powi(2)).sqrt(),
        }
    };
    let mut worst: f64 = 0.0;
    for s in ["upwind", "centred", "Lax-Wendroff"] {
        let mut cells = vec![];
        for m in [2, 4, 8] {
            let (g, xi) = measured(s, m);
            worst = worst.max((g - form(s, xi)).abs());
            cells.push(format!("{:.4} | {:.4}", g, form(s, xi)));
        }
        println!("  {:<12} xi = pi/4, pi/2, pi: {}", s, cells.join(";  "));
    }

    let strongest = |t: f64| -> f64 {   // the wave carrying most of the centred error, by a DFT
        let e: Vec<f64> = run("centred", H, nu0, t).iter().enumerate().map(|(j, &v)| v - f(LO + j as f64 * H - C * t)).collect();
        let n = e.len() as f64;
        let amp = |m: usize| -> f64 {
            let a = |j: usize| 2.0 * PI * m as f64 * j as f64 / n;
            let re: f64 = e.iter().enumerate().map(|(j, &w)| w * a(j).cos()).sum();
            let im: f64 = e.iter().enumerate().map(|(j, &w)| -w * a(j).sin()).sum();
            (re * re + im * im).sqrt()
        };
        let mut best = 1; for m in 2..=e.len() / 2 { if amp(m) > amp(best) { best = m } }
        2.0 * PI * best as f64 / n
    };
    for t in [1.0, 3.0] {
        let (xi, k) = (strongest(t), (t / DT).round());
        let g = (1.0 + nu0 * nu0 * xi.sin().powi(2)).sqrt();
        println!("centred error at {:.1} h: strongest wave xi = {:.3} pi, {:.1} cells long, grown x{:.1} in {} steps from a spill weight of 1 in {:.0}",
                 t, xi / PI, 2.0 * PI / xi, g.powi(k as i32), k, ((xi / H).powi(2) / 4.0).exp());
    }
    println!("the xi = pi/2 wave: grown x{:.0} in 30 steps from a spill weight of 1 in {:.0}",
             (1.0 + nu0 * nu0).sqrt().powi(30), ((PI / 2.0 / H).powi(2) / 4.0).exp());

    println!("order: largest error at 3 h against the exact pulse, nu = 0.8");
    let (mut eu, mut el) = (vec![], vec![]);
    for h in [0.25, 0.125, 0.0625] {
        let (u1, u2) = (run("upwind", h, nu0, T), run("Lax-Wendroff", h, nu0, T));
        eu.push(maxgap(&u1, h, &|x| f(x - C * T)));
        el.push(maxgap(&u2, h, &|x| f(x - C * T)));
        println!("  h = {:<6} upwind {:.4} (peak {:.4}, modified eq {:.4})   Lax-Wendroff {:.4}",
                 h, eu[eu.len() - 1], mx(&u1), gauss(C * T, T, alpha_num(h, nu0)), el[el.len() - 1]);
    }
    println!("  ratios as h halves: upwind {:.2}, {:.2}; Lax-Wendroff {:.2}, {:.2}", eu[0] / eu[1], eu[1] / eu[2], el[0] / el[1], el[1] / el[2]);

    println!("how it moves: peak (and lowest) by time, mg/L");
    for t in [0.5, 1.0, 2.0, 3.0] {
        let (a1, a2, a3) = (run("upwind", H, nu0, t), run("Lax-Wendroff", H, nu0, t), run("centred", H, nu0, t));
        println!("  t = {:.1} h: upwind {:.4} (modified eq {:.4}); Lax-Wendroff {:.4} ({:.4}); centred {:.4} ({:.4})",
                 t, mx(&a1), gauss(C * t, t, an), mx(&a2), mn(&a2), mx(&a3), mn(&a3));
    }

    let absmax = |u: &[f64]| u.iter().fold(0.0f64, |m, v| m.max(v.abs()));
    let (dn, big, late) = (run("downwind", H, nu0, T), run("upwind", H, 1.2, T), run("centred", H, nu0, 12.0));
    println!("what breaks: downwind at 3 h, largest |u| = 10^{:.1} mg/L", absmax(&dn).log10());
    println!("what breaks: upwind with nu = 1.2 (step 0.15 h), peak {:.4}, lowest {:.4}", mx(&big), mn(&big));
    println!("what breaks: centred at 12 h, largest |u| = 10^{:.1} mg/L", absmax(&late).log10());
    println!("what breaks: fitting the upwind smear as real mixing gives {:.2} m^2/s of mixing that is not there", an * 1e6 / 3600.0);
    for nu in [1.0, 0.5] {
        let w = run("upwind", H, nu, T);
        println!("try: upwind nu = {:.1}: peak {:.4}, modified eq {:.4}", nu, mx(&w), gauss(C * T, T, alpha_num(H, nu)));
    }

    let lab: Vec<f64> = (0..17).map(|i| 2.0 + 0.5 * i as f64).collect();
    println!("chart, x km: {}", lab.iter().map(|x| format!("{:.1}", x)).collect::<Vec<_>>().join(", "));
    println!("chart, exact 3 h: {}", lab.iter().map(|&x| format!("{:.2}", f(x - C * T))).collect::<Vec<_>>().join(", "));
    println!("chart, upwind 3 h: {}", row(&up, &lab));
    println!("chart, Lax-Wendroff 3 h: {}", row(&lw, &lab));
    let ce1 = run("centred", H, nu0, 1.0);
    let lab1: Vec<f64> = (0..13).map(|i| -1.0 + 0.5 * i as f64).collect();
    println!("chart, centred 1 h: {}", row(&ce1, &lab1));
    println!("chart, exact 1 h: {}", lab1.iter().map(|&x| format!("{:.2}", f(x - C))).collect::<Vec<_>>().join(", "));
    let px = |x: f64| 60.0 + (x + 0.5) * 320.0;
    let cells: Vec<String> = [-0.5, -0.25, 0.0, 0.25].iter().map(|&x| format!("{:.2}", 6.0 + x)).collect();
    let nodes: Vec<String> = [-0.5, -0.25, 0.0, 0.25].iter().map(|&x| format!("{:.0}", px(x))).collect();
    println!("figure, cells {} km at px {}; foot {:.2} km at px {:.0}; 2.9 h at y 180, 3.0 h at y {:.0}",
             cells.join(" "), nodes.join(" "), 6.0 - C * DT, px(-C * DT), 180.0 - DT * 1200.0);

    assert!((mx(&up) - gauss(C * T, T, an)).abs() < 0.02);   // grid peak meets the modified equation
    assert!(gap_mod < 0.1 * gap_ex);                          // modified equation explains the error
    assert!((mass - 10.0 * PI.sqrt()).abs() < 1e-6);          // conservation form keeps the mass
    assert!(worst < 1e-12);                                   // measured growth meets von Neumann
    assert!(eu[0] / eu[1] > 1.6 && eu[0] / eu[1] < 2.2 && eu[1] / eu[2] > 1.6 && eu[1] / eu[2] < 2.2);
    assert!(el[0] / el[1] > 3.4 && el[0] / el[1] < 4.4 && el[1] / el[2] > 3.4 && el[1] / el[2] < 4.4);
    assert!(mn(&up) >= 0.0 && mx(&up) <= 10.0 && mn(&lw) < -0.1 && mx(&ce) > 50.0);
    println!("ALL CHECKS PASS");
}
