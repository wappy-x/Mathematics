// Transfer functions -- the same check as the Python, in Rust.  No crates.
// The plant is a car on cruise control: m dv/dt = u - b v, with the drag
// c v^2 linearised about 25 m/s.  Its transfer function is G(s) = 1/(m s + b).
// Roads: the formula; an RK4 simulation of the equation; a numerical Laplace
// transform (Simpson) of the impulse response; residues at the poles.
const M: f64 = 1000.0; // mass, kg
const C: f64 = 0.5; // drag, N s^2/m^2
const V0: f64 = 25.0; // cruise, m/s
const B: f64 = 2.0 * C * V0; // linearised drag, N s/m
const TAU: f64 = M / B; // time constant, s
const DT: f64 = 0.01; // RK4 step, s
const J: f64 = 500.0; // the shove, N s
const TE: f64 = 0.5; // engine lag, s

fn g(s: f64) -> f64 { 1.0 / (M * s + B) } // the transfer function, (m/s)/N
fn h(t: f64) -> f64 { (-B * t / M).exp() / M } // impulse response: residue at s = -b/m
fn steps(t: f64) -> usize { (t / DT).round() as usize }

// RK4 on dx/dt = f(t, x); keeps every state
fn run(f: &dyn Fn(f64, &[f64]) -> Vec<f64>, x0: Vec<f64>, t0: f64, n: usize) -> Vec<Vec<f64>> {
    let axpy = |x: &[f64], c: f64, k: &[f64]| -> Vec<f64> { x.iter().zip(k).map(|(a, b)| a + c * b).collect() };
    let mut x = x0;
    let mut out = vec![x.clone()];
    for i in 0..n {
        let t = t0 + i as f64 * DT;
        let k1 = f(t, &x);
        let k2 = f(t + DT / 2.0, &axpy(&x, DT / 2.0, &k1));
        let k3 = f(t + DT / 2.0, &axpy(&x, DT / 2.0, &k2));
        let k4 = f(t + DT, &axpy(&x, DT, &k3));
        x = (0..x.len()).map(|j| x[j] + DT / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j])).collect();
        out.push(x.clone());
    }
    out
}

fn car(u: impl Fn(f64) -> f64) -> impl Fn(f64, &[f64]) -> Vec<f64> { move |t, x| vec![(u(t) - B * x[0]) / M] }

fn push(force: f64, width: f64, t_end: f64) -> Vec<f64> { // constant force for width s, then coast
    let on = run(&car(|_| force), vec![0.0], 0.0, steps(width));
    let off = run(&car(|_| 0.0), on[on.len() - 1].clone(), width, steps(t_end - width));
    on.iter().chain(off[1..].iter()).map(|x| x[0]).collect()
}

fn simpson(ys: &[f64], dx: f64) -> f64 { // composite Simpson's rule, odd point count
    let n = ys.len();
    let (mut odd, mut even) = (0.0, 0.0);
    for i in (1..n - 1).step_by(2) { odd += ys[i] }
    for i in (2..n - 1).step_by(2) { even += ys[i] }
    dx / 3.0 * (ys[0] + ys[n - 1] + 4.0 * odd + 2.0 * even)
}

fn laplace_of_h(s: f64) -> f64 { // integral of h(t) e^(-s t) dt, numerically
    let (t_end, dx) = (1000.0, 0.05);
    let n = (t_end / dx as f64).round() as usize;
    let ys: Vec<f64> = (0..=n).map(|k| h(k as f64 * dx) * (-s * k as f64 * dx).exp()).collect();
    simpson(&ys, dx)
}

fn drive_ratio(s: f64) -> f64 { // feed u = e^(s t) from rest; output / input
    let t_end = 800.0;
    let v = run(&car(|t| (s * t).exp()), vec![0.0], 0.0, steps(t_end));
    v[v.len() - 1][0] / (s * t_end).exp()
}

fn main() {
    println!("car: m = {:.0} kg, c = {} N s^2/m^2, cruising at v0 = {:.0} m/s", M, C, V0);
    println!("linearised drag b = 2 c v0 = {:.0} N s/m; cruise force c v0^2 = {:.1} N", B, C * V0 * V0);
    println!("G(s) = 1/({:.0} s + {:.0}) (m/s)/N; pole s = {:.3} 1/s; time constant {:.0} s", M, B, -B / M, TAU);
    println!("G(s) three ways, (m/s)/N: formula | transform of h, Simpson to 1000 s | e^(st) drive, RK4 to 800 s");
    let mut rows = Vec::new();
    for s in [0.0, 0.025, 0.05, 0.1] {
        let r = (g(s), laplace_of_h(s), drive_ratio(s));
        println!("s = {:.3} 1/s: {:.7} | {:.7} | {:.7}", s, r.0, r.1, r.2);
        rows.push(r);
    }
    println!("impulse response h(t) = (1/m) e^(-t/{:.0} s); h(0+) = {:.3} (m/s) per N s", TAU, h(0.0));
    let (short, slow) = (push(1000.0, 0.5, 120.0), push(12.5, 40.0, 120.0));
    println!("{:.0} N s shove, speed gained (m/s): t | ideal impulse | 1000 N for 0.5 s | 12.5 N for 40 s", J);
    let times: Vec<f64> = (0..=12).map(|k| 10.0 * k as f64).collect();
    for &t in &times {
        println!("t = {:3} s: {:.3} | {:.3} | {:.3}", t as i64, J * h(t), short[steps(t)], slow[steps(t)]);
    }
    println!("figure, chart ideal: {}", times.iter().map(|&t| format!("{:.2}", J * h(t))).collect::<Vec<_>>().join(" "));
    println!("figure, chart 40 s push: {}", times.iter().map(|&t| format!("{:.2}", slow[steps(t)])).collect::<Vec<_>>().join(" "));
    let step: Vec<f64> = run(&car(|_| 100.0), vec![0.0], 0.0, steps(160.0)).iter().map(|x| x[0]).collect();
    println!("100 N extra thrust, speed gained (m/s): t | partial fractions | RK4 | convolution h*u");
    let mut stepped = Vec::new();
    for t in [20.0, 40.0, 80.0, 160.0] {
        let pf = 100.0 / B * (1.0 - (-t / TAU).exp());
        let ys: Vec<f64> = (0..=(t / 0.05_f64).round() as usize).map(|k| 100.0 * h(k as f64 * 0.05)).collect();
        let conv = simpson(&ys, 0.05);
        println!("t = {:3} s: {:.4} | {:.4} | {:.4}", t as i64, pf, step[steps(t)], conv);
        stepped.push((pf, step[steps(t)], conv));
    }
    let (p1, p2) = (-B / M, -1.0 / TE); // engine lag 1/(TE s + 1) in series
    let (r1, r2) = (1.0 / ((TE * p1 + 1.0) * M), 1.0 / (TE * (M * p2 + B)));
    let lag = |r: Box<dyn Fn(f64) -> f64>| move |t: f64, x: &[f64]| vec![(r(t) - x[0]) / TE, (x[0] - B * x[1]) / M];
    let g2 = g(0.05) / (TE * 0.05 + 1.0);
    let d = run(&lag(Box::new(|t| (0.05 * t).exp())), vec![0.0, 0.0], 0.0, steps(800.0));
    let d2 = d[d.len() - 1][1] / 40.0_f64.exp();
    println!("engine lag {} s in series: G_total(0.05) = {:.7} by product, {:.7} by e^(st) drive", TE, g2, d2);
    println!("residues: h2(t) = {:.8} e^({:.3} t) + ({:.8}) e^({:.0} t); h2(0+) = {:.6}", r1, p1, r2, p2, (r1 + r2).abs());
    let kick = run(&lag(Box::new(|_| 0.0)), vec![J / TE, 0.0], 0.0, steps(40.0));
    let h2 = |t: f64| J * (r1 * (p1 * t).exp() + r2 * (p2 * t).exp());
    for t in [1.0, 10.0, 40.0] {
        println!("{:.0} N s through the engine, t = {:2} s: residues {:.5} m/s | RK4 {:.5} m/s", J, t as i64, h2(t), kick[steps(t)][1]);
    }
    let peak = slow.iter().cloned().fold(f64::MIN, f64::max);
    println!("mistake 1, shove spread over 40 s: peak {:.3} m/s, not {:.3} m/s", peak, J * h(0.0));
    let warm = run(&car(|_| 100.0), vec![1.0], 0.0, steps(800.0));
    let ys: Vec<f64> = warm.iter().enumerate().map(|(k, x)| x[0] * (-0.05 * k as f64 * DT).exp()).collect();
    let vs = simpson(&ys, DT);
    println!("mistake 2, car already 1 m/s fast: V/U at s = 0.05 is {:.4}, not G = {:.4}", vs / (100.0 / 0.05), g(0.05));
    println!("mistake 3, mass dropped, G = 1/(s + {:.3}): steady gain {:.0} (m/s)/N, not {:.2}", B / M, 1.0 / (B / M), g(0.0));
    let mut far = Vec::new();
    for df in [100.0, 1000.0] {
        let sq = move |_t: f64, x: &[f64]| vec![(C * V0 * V0 + df - C * x[0] * x[0]) / M];
        let r = run(&sq, vec![V0], 0.0, steps(600.0));
        let row = (df / B, (V0 * V0 + df / C).sqrt() - V0, r[r.len() - 1][0] - V0);
        println!("{}{:.0} N step: linear +{:.3} m/s, drag-squared car +{:.3} m/s (RK4 at 600 s: +{:.3})",
                 if df > 500.0 { "mistake 4, " } else { "in range, " }, df, row.0, row.1, row.2);
        far.push(row);
    }
    for &(gs, lap, drv) in &rows { // transform of h, and the e^(st) drive, both give G
        assert!((lap - gs).abs() < 1e-6 * gs && (drv - gs).abs() < 1e-6 * gs);
    }
    assert!(times[1..].iter().all(|&t| (short[steps(t)] - J * h(t)).abs() < 0.01 * J * h(t)));
    assert!((peak - 12.5 / B * (1.0 - (-40.0 / TAU).exp())).abs() < 1e-6); // 40 s push peak, closed form
    assert!(stepped.iter().all(|&(pf, rk, cv)| (rk - pf).abs() < 1e-6 && (cv - pf).abs() < 1e-6));
    assert!((d2 - g2).abs() < 1e-6 * g2);
    assert!([1.0, 10.0, 40.0].iter().all(|&t| (kick[steps(t)][1] - h2(t)).abs() < 1e-6));
    assert!(far.iter().all(|&(_, exact, rk)| (rk - exact).abs() < 1e-6) && (vs - (2000.0 + M * 1.0) * g(0.05)).abs() < 1e-4);
    println!("ALL CHECKS PASS");
}
