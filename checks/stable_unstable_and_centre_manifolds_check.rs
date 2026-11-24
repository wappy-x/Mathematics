// Invariant manifolds -- the same check as the Python, in Rust, no crates.
// Saddle: x' = x, y' = -y + x^2.  Centre: x' = xy, y' = -y - x^2, and its twin
// y' = -y + x^2.  Road one: power series that the flow must leave unchanged.
// Road two: Runge-Kutta 4, written out here, run on the full system.
use std::f64::consts::PI;
type S = (f64, f64);
fn rk4(f: &dyn Fn(S) -> S, mut s: S, t: f64, h: f64) -> S {
    let n = ((t.abs() / h).round() as usize).max(1); let k = t / n as f64;   // n equal steps, landing exactly on t
    for _ in 0..n {
        let a = f(s);
        let b = f((s.0 + k / 2.0 * a.0, s.1 + k / 2.0 * a.1));
        let c = f((s.0 + k / 2.0 * b.0, s.1 + k / 2.0 * b.1));
        let d = f((s.0 + k * c.0, s.1 + k * c.1));
        s = (s.0 + k / 6.0 * (a.0 + 2.0 * b.0 + 2.0 * c.0 + d.0), s.1 + k / 6.0 * (a.1 + 2.0 * b.1 + 2.0 * c.1 + d.1));
    }
    s
}
fn centre(sign: i64) -> Vec<i64> {      // y = h(x) = sum a[k] x^k, with h'(x) x h(x) = -h(x) + sign x^2
    let mut a = vec![0i64; 9];
    for k in (2..9).step_by(2) {
        a[k] = sign * (k == 2) as i64 - (2..k - 1).map(|i| i as i64 * a[i] * a[k - i]).sum::<i64>();
    }
    a
}
fn ev(a: &[i64], x: f64) -> f64 { [2, 4, 6].iter().map(|&k| a[k] as f64 * x.powi(k as i32)).sum() }
fn p(s: S, x0: f64, y0: f64, k: f64) -> String { format!("{:.1},{:.1}", x0 + k * s.0, y0 - k * s.1) }
fn main() {
    let saddle = |s: S| (s.0, -s.1 + s.0 * s.0);
    let sad: Vec<(i64, i64)> = (0..9).map(|k| ((k == 2) as i64, k + 1)).collect(); // Step 1: (k + 1) a_k = [k = 2]
    let hs = |x: f64| (0..9).map(|k| sad[k].0 as f64 / sad[k].1 as f64 * x.powi(k as i32)).sum::<f64>();
    let dhs = |x: f64| (1..9).map(|k| (k as i64 * sad[k].0) as f64 / sad[k].1 as f64 * x.powi(k as i32 - 1)).sum::<f64>();
    let txt = |c: (i64, i64)| if c.0 == 0 { "0".to_string() } else { format!("{}/{}", c.0, c.1) };
    println!("saddle x' = x, y' = -y + x^2: J = [[1, 0], [0, -1]], eigenvalues 1 and -1");
    println!("unstable manifold y = a2 x^2 + ... + a8 x^8: {}", (2..9).map(|k| txt(sad[k])).collect::<Vec<_>>().join(", "));
    assert!((-4..5).all(|i| { let x = i as f64; (dhs(x) * saddle((x, hs(x))).0 - saddle((x, hs(x))).1).abs() < 1e-9 })); // h' f = g at 9 points
    let tl = 100f64.ln();
    for y0 in [0.0, 1.0] {
        let (x1, y1) = rk4(&saddle, (0.01, y0), tl, 0.001);
        assert!((y1 - (1.0 / 3.0 + (y0 - 0.0001 / 3.0) / 100.0)).abs() < 1e-9); // exact: gap falls like e^-t
        println!("start (0.01, {}), t = ln 100 = {:.6}: x = {:.6}, y = {:.6}, curve x^2/3 = {:.6}", y0, tl, x1, y1, x1 * x1 / 3.0);
    }
    println!("stable manifold x = 0: start (0, 1), y at t = 5: {:.6} = e^-5", rk4(&saddle, (0.0, 1.0), 5.0, 0.001).1);
    let (a, b) = (centre(-1), centre(1));
    println!("centre x' = xy, y' = -y - x^2: J = [[0, 0], [0, -1]], eigenvalues 0 and -1");
    println!("centre manifold y = h(x), coefficients of x^2, x^4, x^6, x^8: {}, {}, {}, {}", a[2], a[4], a[6], a[8]);
    assert!([a[2], a[4], a[6], a[8]] == [-1, -2, -12, -112]);
    let h = |x: f64| ev(&a, x);
    let full = |s: S| (s.0 * s.1, -s.1 - s.0 * s.0);
    let gaps: Vec<S> = [0.0, 2.0, 4.0, 8.0].iter().map(|&t| rk4(&full, (0.3, 0.2), t, 0.001)).collect();
    println!("start (0.3, 0.2): gap y - h(x) at t = 0, 2, 4, 8: {}; x at t = 8: {:.6}",
             gaps.iter().map(|s| format!("{:.6}", s.1 - h(s.0))).collect::<Vec<_>>().join(", "), gaps[3].0);
    assert!((gaps[3].1 - h(gaps[3].0)).abs() < 0.01 * (0.2 - h(0.3)).abs());
    let xf = rk4(&full, (0.3, h(0.3)), 100.0, 0.01).0;
    let xr = rk4(&|s: S| (s.0 * h(s.0), 0.0), (0.3, 0.0), 100.0, 0.01).0;
    let x3 = 0.3 / (1.0f64 + 2.0 * 0.09 * 100.0).sqrt();
    assert!((xf - xr).abs() < 0.1 * (xf - x3).abs());       // the x^5 term earns its place
    println!("from x = 0.3 on the curve, x at t = 100: full system {:.6}, reduced x' = x h(x) {:.6}, x' = -x^3 alone {:.6}", xf, xr, x3);
    let xg = rk4(&|s: S| (s.0 * s.1, -s.1 + s.0 * s.0), (0.3, ev(&b, 0.3)), 6.0, 0.001).0;
    assert!(b[2] == 1 && b[4] == -2 && xg > 0.6);
    println!("twin y' = -y + x^2, same J: coefficients {}, {}, so x' = +x^3 - 2x^5; from 0.3, x at t = 6: {:.6}", b[2], b[4], xg);
    println!("mistake 1, tangent line y = 0 as the way out of the saddle: y = 0 at x = 1, truly {:.6}", 1.0 / 3.0);
    println!("mistake 2, centre curve taken as y = 0: x' = 0, x stays 0.3; truly {:.6} at t = 100", xf);
    let swing = |s: S| (s.1, -s.0.sin() - 0.5 * s.1);
    let ls = 0.5 * (-0.5 - 4.25f64.sqrt());
    let mut tops = vec![];
    for e in [1e-5, 1e-7] {                                  // start on the swing's stable line at the top, run back
        let (mut s, mut q) = ((PI - e, -ls * e), (PI - e, -ls * e));
        while s.0 > 0.0 { q = s; s = rk4(&swing, s, -0.001, 0.001); }
        tops.push(q.1 + (s.1 - q.1) * q.0 / (q.0 - s.0));
    }
    assert!((tops[0] - tops[1]).abs() < 1e-6 && tops[0] > 2.0);
    println!("swing, upright rest: stable manifold meets theta = 0 at speed {:.4} rad per unit (2 without damping)", tops[0]);
    let sc: Vec<String> = (-3..4).map(|x| p((x as f64 / 2.0, (x * x) as f64 / 12.0), 160.0, 200.0, 100.0)).collect();
    println!("figure, saddle curve: {}", sc.join(" "));
    let cc: Vec<String> = (-4..5).step_by(2).map(|x| { let u = x as f64 / 10.0; p((u, h(u)), 480.0, 110.0, 250.0) }).collect();
    let pc: Vec<String> = gaps.iter().map(|&s| p(s, 480.0, 110.0, 250.0)).collect();
    println!("figure, centre curve: {}; path at t = 0, 2, 4, 8: {}", cc.join(" "), pc.join(" "));
    println!("ALL CHECKS PASS");
}
