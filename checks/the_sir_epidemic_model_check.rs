// The SIR model -- the same check as the Python, in Rust.  No crates.  A flu
// in a town of 10,000: S, I, R are the shares susceptible, ill and recovered;
// S' = -bSI, I' = bSI - gI, R' = gI, time in days, one case on day 0.  Road one
// steps the equations (Runge-Kutta 4, written out); road two is the phase
// curve I + S - ln(S)/R0 = constant, which needs no stepping at all.
const N: f64 = 10000.0;
const B: f64 = 0.625; const G: f64 = 0.25;          // contact rate and recovery rate, per day
const R0: f64 = B / G;
const I0: f64 = 1.0 / N;
const S0: f64 = 1.0 - I0;

fn f(s: f64, i: f64) -> [f64; 2] { [-B * s * i, B * s * i - G * i] }

fn rk4(s: f64, i: f64, h: f64) -> (f64, f64) {             // one Runge-Kutta 4 step
    let a = f(s, i);
    let b = f(s + h / 2.0 * a[0], i + h / 2.0 * a[1]);
    let c = f(s + h / 2.0 * b[0], i + h / 2.0 * b[1]);
    let d = f(s + h * c[0], i + h * c[1]);
    (s + h / 6.0 * (a[0] + 2.0 * b[0] + 2.0 * c[0] + d[0]), i + h / 6.0 * (a[1] + 2.0 * b[1] + 2.0 * c[1] + d[1]))
}

fn run(h: f64, days: f64) -> Vec<(f64, f64, f64)> {         // every step, as (t, S, I)
    let (mut s, mut i, mut out) = (S0, I0, vec![(0.0, S0, I0)]);
    for k in 1..=(days / h).round() as usize { let n = rk4(s, i, h); s = n.0; i = n.1; out.push((k as f64 * h, s, i)); }
    out
}

fn phase_i(s: f64) -> f64 { S0 + I0 - s + (s.ln() - S0.ln()) / R0 }   // road two: I on the phase curve

fn bisect(fun: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {   // root finder, written out
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if fun(lo) * fun(mid) > 0.0 { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}

fn eig(s: f64, i: f64) -> (f64, f64) {       // Jacobian by differences; 2x2 eigenvalues from trace and det
    let d = 1e-6;
    let j: Vec<[f64; 2]> = (0..2).map(|r| [(f(s + d, i)[r] - f(s - d, i)[r]) / (2.0 * d), (f(s, i + d)[r] - f(s, i - d)[r]) / (2.0 * d)]).collect();
    let (tr, det) = (j[0][0] + j[1][1], j[0][0] * j[1][1] - j[0][1] * j[1][0]);
    let q = (tr * tr / 4.0 - det).sqrt();
    (tr / 2.0 - q, tr / 2.0 + q)
}

fn join(v: Vec<String>) -> String { v.join(" ") }

fn main() {
    let path = run(0.01, 300.0);
    let (t_pk, s_pk, i_pk) = *path.iter().max_by(|a, b| a.2.partial_cmp(&b.2).unwrap()).unwrap();
    let s_inf = bisect(&|s| phase_i(s), 1e-9, 1.0 / R0);                  // the phase curve meets I = 0
    let z = bisect(&|z| 1.0 - (-R0 * z).exp() - z, 0.5, 1.0);             // vanishing-start form
    let err: Vec<f64> = [1.0, 0.5, 0.25].iter().map(|&h| run(h, 300.0).last().unwrap().1 - s_inf).collect();
    let days: Vec<&(f64, f64, f64)> = path.iter().filter(|r| (r.0 / 5.0 - (r.0 / 5.0).round()).abs() < 1e-6 && r.0 <= 60.001).collect();
    let s_end = path.last().unwrap().1;
    let (e1, e2) = (eig(1.0, 0.0), eig(s_inf, 0.0));
    println!("town {}; b = {}/day, g = {}/day, illness 1/g = {:.0} days; R0 = b/g = {}; one case on day 0", N, B, G, 1.0 / G, R0);
    println!("early growth: I' = (b - g) I = {:.3} I per day; cases double every {:.2} days", B - G, 2f64.ln() / (B - G));
    println!("eigenvalues at (S, I) = (1, 0): {:+.4} {:+.4} per day", e1.0, e1.1);
    println!("eigenvalues at (S_inf, 0): {:+.4} {:+.4} per day", e2.0, e2.1);
    println!("peak, phase curve at S = 1/R0 = {}: I = {:.6}, {:.0} ill", 1.0 / R0, phase_i(1.0 / R0), N * phase_i(1.0 / R0));
    println!("peak, Runge-Kutta h = 0.01: I = {:.6}, {:.0} ill on day {:.2}, S there {:.4}", i_pk, N * i_pk, t_pk, s_pk);
    println!("final size, phase curve meets I = 0: S_inf = {:.6}; {:.0} ever ill ({:.1}%), {:.0} never", s_inf, N * (1.0 - s_inf), 100.0 * (1.0 - s_inf), N * s_inf);
    println!("final size, Runge-Kutta day 300: S = {:.6}; z = 1 - e^(-2.5 z) from a vanishing start: {:.6}", s_end, z);
    println!("Runge-Kutta error in never-ill people, day 300, h = 1, 0.5, 0.25: {:.7} {:.7} {:.7}; ratios {:.1} {:.1}", N * err[0], N * err[1], N * err[2], err[0] / err[1], err[1] / err[2]);
    println!("chart days: {}", join(days.iter().map(|r| format!("{:.0}", r.0)).collect()));
    println!("chart S: {}", join(days.iter().map(|r| format!("{:.0}", N * r.1)).collect()));
    println!("chart I: {}", join(days.iter().map(|r| format!("{:.0}", N * r.2)).collect()));
    println!("chart R: {}", join(days.iter().map(|r| format!("{:.0}", (N * (1.0 - r.1 - r.2)).max(0.0))).collect()));
    println!("mistake 1, no depletion: e^({} x {:.2}) = {:.0} ill at the peak day, in a town of {}", B - G, t_pk, ((B - G) * t_pk).exp(), N);
    println!("mistake 2, threshold 1 - 1/R0 = {:.0}% read as the final size; overshoot {:.0} people", 100.0 * (1.0 - 1.0 / R0), N * (1.0 - s_inf - (1.0 - 1.0 / R0)));
    println!("mistake 3, g = 4 per day (the period used as the rate): R0 = {:.4}, no outbreak", B / 4.0);
    let x = |s: f64| 40.0 + 300.0 * s;                       // 300 units per unit S
    let y = |i: f64| 210.0 - 720.0 * i;                      // 720 units per unit I
    println!("figure, peak ({:.1}, {:.1}); start x {:.1}; end x {:.1}", x(1.0 / R0), y(phase_i(1.0 / R0)), x(S0), x(s_inf));
    let mut ss = vec![S0]; ss.extend((1..18).map(|n| 1.0 - 0.05 * n as f64)); ss.push(s_inf);
    println!("figure, curve: {}", join(ss.iter().map(|&s| format!("{:.1},{:.1}", x(s), y(phase_i(s)))).collect()));
    assert!((i_pk - phase_i(1.0 / R0)).abs() < 1e-6 && (s_pk - 1.0 / R0).abs() < 0.002);   // peak: stepping vs phase curve
    assert!((s_end - s_inf).abs() < 1e-7);                                                  // final size: stepping vs root
    assert!(err[0] / err[1] > 14.0 && err[0] / err[1] < 18.0);                               // fourth order: error / 16
    assert!((e1.1 - (B - G)).abs() < 1e-6 && (e2.0 - (B * s_inf - G)).abs() < 1e-6);         // vs hand Jacobian
    println!("ALL CHECKS PASS");
}
