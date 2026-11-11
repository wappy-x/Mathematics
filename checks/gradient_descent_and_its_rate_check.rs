// Gradient descent on the Rosenbrock banana, with the proofs' bounds checked.
// std only: the gradient, the curvatures and the walk are written out.
type P = [f64; 2];

fn f(x: P) -> f64 { (1.0 - x[0]).powi(2) + 100.0 * (x[1] - x[0].powi(2)).powi(2) }
fn grad(x: P) -> P { [-2.0 * (1.0 - x[0]) - 400.0 * x[0] * (x[1] - x[0].powi(2)), 200.0 * (x[1] - x[0].powi(2))] }
fn curv(x: P) -> (f64, f64) { // the two curvatures (eigenvalues of the Hessian), largest first
    let (a, b, c) = (1200.0 * x[0].powi(2) - 400.0 * x[1] + 2.0, -400.0 * x[0], 200.0);
    let (m, r) = ((a + c) / 2.0, (((a - c) / 2.0).powi(2) + b * b).sqrt());
    (m + r, m - r)
}
fn walk(mut x: P, alpha: f64, steps: usize, sign: f64) -> Vec<P> { // x_{k+1} = x_k - alpha * grad f(x_k)
    let mut path = vec![x];
    for _ in 0..steps {
        let g = grad(x);
        x = [x[0] - sign * alpha * g[0], x[1] - sign * alpha * g[1]];
        path.push(x);
    }
    path
}
fn dist(x: P) -> f64 { ((x[0] - 1.0).powi(2) + (x[1] - 1.0).powi(2)).sqrt() }
fn reversals(p: &[P]) -> usize {
    (1..p.len() - 1).filter(|&k| (p[k][0] - p[k - 1][0]) * (p[k + 1][0] - p[k][0]) + (p[k][1] - p[k - 1][1]) * (p[k + 1][1] - p[k][1]) < 0.0).count()
}
fn show(label: &str, v: &[String]) { println!("{:<44}{}", label, v.join(" ")); }
fn f4(v: f64) -> String { format!("{:.4}", v).replace("-0.0000", "0.0000") }

fn main() {
    // ---- the valley and its certificate ----
    let (x0, alpha, xs): (P, f64, P) = ([-1.2, 1.0], 0.001, [1.0, 1.0]);
    let (g0, h) = (grad(x0), 1e-6);
    let cd = [(f([x0[0] + h, x0[1]]) - f([x0[0] - h, x0[1]])) / (2.0 * h), (f([x0[0], x0[1] + h]) - f([x0[0], x0[1] - h])) / (2.0 * h)];
    show("start: height, gradient, distance", &[f4(f(x0)), f4(g0[0]), f4(g0[1]), f4(dist(x0))]);
    show("gradient by central differences", &[f4(cd[0]), f4(cd[1])]);
    let (l0, mu0) = curv(xs);
    let hm = [[802.0, -400.0], [-400.0, 200.0]]; // Hessian at the bottom
    let scan: Vec<f64> = (0..3600).map(|i| i as f64 * std::f64::consts::PI / 3600.0)
        .map(|t| hm[0][0] * t.cos().powi(2) + 2.0 * hm[0][1] * t.cos() * t.sin() + hm[1][1] * t.sin().powi(2)).collect();
    let (smax, smin) = (scan.iter().cloned().fold(f64::MIN, f64::max), scan.iter().cloned().fold(f64::MAX, f64::min));
    show("bottom (1, 1): height, gradient", &[f4(f(xs)), f4(grad(xs)[0]), f4(grad(xs)[1])]);
    show("bottom curvatures: formula", &[f4(l0), f4(mu0)]);
    show("bottom curvatures: 3600 directions scanned", &[f4(smax), f4(smin)]);
    show("bottom: 1/L, 2/L, L/mu", &[format!("{:.7}", 1.0 / l0), format!("{:.7}", 2.0 / l0), format!("{:.1}", l0 / mu0)]);

    // ---- 200 steps at alpha = 0.001 ----
    let p = walk(x0, alpha, 200, 1.0);
    let mut l = f64::MIN;
    for k in 0..200 {
        for j in 0..11 {
            let t = j as f64 / 10.0;
            l = l.max(curv([p[k][0] + t * (p[k + 1][0] - p[k][0]), p[k][1] + t * (p[k + 1][1] - p[k][1])]).0);
        }
    }
    let gn: Vec<f64> = p.iter().map(|&q| grad(q)[0].powi(2) + grad(q)[1].powi(2)).collect();
    let promise: Vec<f64> = (0..200).map(|k| alpha * (1.0 - l * alpha / 2.0) * gn[k]).collect();
    let held = (0..200).filter(|&k| f(p[k]) - f(p[k + 1]) >= promise[k] && promise[k] > 0.0).count();
    show("steepest curvature on the path L, 2/L", &[f4(l), format!("{:.7}", 2.0 / l)]);
    show("step 1: point, height", &[f4(p[1][0]), f4(p[1][1]), f4(f(p[1]))]);
    show("|grad|^2 at start, 1 - L alpha/2", &[f4(gn[0]), f4(1.0 - l * alpha / 2.0)]);
    show("step 1: promised drop, actual drop", &[f4(promise[0]), f4(f(p[0]) - f(p[1]))]);
    show("descent promise kept, of 200 steps", &[held.to_string()]);
    show("height at steps 0 1 2 10 50 100 150 200", &[0, 1, 2, 10, 50, 100, 150, 200].iter().map(|&k| f4(f(p[k]))).collect::<Vec<_>>());
    show("step 200: point, distance to the bottom", &[f4(p[200][0]), f4(p[200][1]), f4(dist(p[200]))]);
    let bound = (f(x0) - 0.0) / (200.0 * alpha * (1.0 - l * alpha / 2.0));
    let gmin = gn[..200].iter().cloned().fold(f64::MAX, f64::min);
    show("smallest |grad|^2 in 200 steps, bound", &[f4(gmin), f4(bound)]);
    show("step reversals in 200 steps, step 0.001", &[reversals(&p).to_string()]);
    show("step reversals, steps 0.0013 and 0.0017", &[reversals(&walk(x0, 0.0013, 200, 1.0)).to_string(), reversals(&walk(x0, 0.0017, 200, 1.0)).to_string()]);

    // ---- the long run, and the rate near the bottom ----
    let (mut q, mut hit, mut logs, mut fa, mut fb) = (x0, None, vec![], 0.0, 0.0);
    for k in 0..=18000usize {
        if k % 2000 == 0 { logs.push(format!("{:.2}", f(q).log10())); }
        if hit.is_none() && dist(q) < 1e-3 { hit = Some(k); }
        if k == 17000 { fa = f(q); }
        if k == 17001 { fb = f(q); }
        q = walk(q, alpha, 1, 1.0)[1];
    }
    let pred = (1.0 - alpha * mu0).powi(2);
    let proved = 1.0 - 2.0 * mu0 * alpha * (1.0 - l0 * alpha / 2.0);
    show("steps until within 0.001 of the bottom", &[hit.unwrap().to_string()]);
    show("log10 height every 2000 steps", &logs);
    show("height ratio per step at 17000: measured", &[format!("{:.6}", fb / fa)]);
    show("predicted (1 - alpha mu)^2, proved bound", &[format!("{:.6}", pred), format!("{:.6}", proved)]);
    show("steps for a tenfold drop", &[format!("{:.0}", 10f64.ln() / -pred.ln())]);

    // ---- the stretched bowl: the banana's bottom, magnified ----
    let v0 = [(l0 - 200.0) / 400.0 * -1.0, 1.0]; // across direction (curvature l0), unnormalised
    let n = (v0[0].powi(2) + v0[1].powi(2)).sqrt();
    let v = [v0[0] / n, v0[1] / n];
    let w = [-v[1], v[0]]; // along the floor
    let e0 = [-0.2, 0.0]; // start at (0.8, 1.0)
    let c0 = [e0[0] * v[0] + e0[1] * v[1], e0[0] * w[0] + e0[1] * w[1]];
    show("bowl start: across, along", &[f4(c0[0]), f4(c0[1])]);
    for a in [0.001, 0.0015, 0.0019, 0.0021] {
        let mut e = e0;
        for _ in 0..50 { e = [e[0] - a * (hm[0][0] * e[0] + hm[0][1] * e[1]), e[1] - a * (hm[1][0] * e[0] + hm[1][1] * e[1])]; }
        let across = e[0] * v[0] + e[1] * v[1];
        assert!((across - (1.0 - a * l0).powi(50) * c0[0]).abs() < 1e-9 * across.abs().max(1.0)); // iteration = closed form
        show(&format!("step {}: across, along, across at 50", a), &[f4(1.0 - a * l0), format!("{:.6}", 1.0 - a * mu0), f4(across)]);
    }
    show("step 0.0019: across error, steps 0 to 6", &(0..7).map(|k| format!("{:.4}", (1.0 - 0.0019 * l0).powi(k) * c0[0])).collect::<Vec<_>>());

    // ---- what breaks ----
    show("step 0.002: height after step 1", &[f4(f(walk(x0, 0.002, 1, 1.0)[1]))]);
    show("far start (-2, 2): f, f after 1, L there", &[f4(f([-2.0, 2.0])), f4(f(walk([-2.0, 2.0], alpha, 1, 1.0)[1])), f4(curv([-2.0, 2.0]).0)]);
    show("uphill sign: height after 3 steps", &[f4(f(walk(x0, alpha, 3, -1.0)[3]))]);
    let stop = (1..200).find(|&k| f(p[k - 1]) - f(p[k]) < 0.01).unwrap();
    show("stop when the drop < 0.01: step, distance", &[stop.to_string(), f4(dist(p[stop]))]);
    let fig: Vec<String> = [p[0], p[1], p[2], p[200], xs].iter().flat_map(|c| c.iter().map(|v| format!("{:.4}", v))).collect();
    println!("figure,{},contours,25,4,1", fig.join(","));

    assert!((0..2).all(|i| (g0[i] - cd[i]).abs() < 1e-4)); // gradient formula vs differences
    assert!((smax - l0).abs() < 1e-3 && (smin - mu0).abs() < 1e-3); // curvature formula vs scan
    assert!(held == 200 && gmin <= bound); // descent lemma and its sum
    assert!((fb / fa - pred).abs() < 1e-5 && fb / fa <= proved); // the rate
    assert!(hit.is_some() && dist(p[200]) > 1.0); // reaches the bottom; still far at 200
    println!("ALL CHECKS PASS");
}
