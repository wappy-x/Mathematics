// Normal modes -- the same check as the Python, in Rust.  No crates.  Two 1 kg
// carts, three springs of 1 N/m: x'' = -K x, K = [[2, -1], [-1, 2]]; cart 1 starts
// 10 cm out, cart 2 in place, both still.  Road one: eigenvalues and modes of K,
// then the mode sum.  Road two: plain Euler steps, with periods timed from them.
use std::f64::consts::PI;
type Mat = (f64, f64, f64); // K = [[a, b], [b, d]]

fn modes(k: Mat) -> [(f64, (f64, f64)); 2] { // roots of l^2 - (a + d) l + ad - b^2
    let (a, b, d) = k;
    let r = ((a + d).powi(2) - 4.0 * (a * d - b * b)).sqrt();
    let (l1, l2) = ((a + d - r) / 2.0, (a + d + r) / 2.0);
    [(l1, (1.0, (l1 - a) / b)), (l2, (1.0, (l2 - a) / b))]
}
fn exact(k: Mat, x0: (f64, f64), t: f64) -> (f64, f64) { // the mode sum, started from rest at x0
    let mut x = (0.0, 0.0);
    for (l, v) in modes(k) {
        let c = (x0.0 * v.0 + x0.1 * v.1) / (v.0 * v.0 + v.1 * v.1);
        x = (x.0 + c * v.0 * (l.sqrt() * t).cos(), x.1 + c * v.1 * (l.sqrt() * t).cos());
    }
    x
}
fn euler(k: Mat, x0: (f64, f64), t_end: f64, h: f64, watch: &mut dyn FnMut(f64, f64, f64)) -> [f64; 4] {
    let ((a, b, d), (mut x1, mut x2), mut v1, mut v2) = (k, x0, 0.0, 0.0); // x' = v, v' = -K x
    for n in 0..(t_end / h).round() as usize {
        (x1, x2, v1, v2) = (x1 + h * v1, x2 + h * v2, v1 - h * (a * x1 + b * x2), v2 - h * (b * x1 + d * x2));
        watch((n + 1) as f64 * h, x1, x2);
    }
    [x1, x2, v1, v2]
}
fn energy(k: Mat, s: [f64; 4]) -> f64 { // mJ, with x in cm and v in cm/s
    let [x1, x2, v1, v2] = s;
    0.05 * (v1 * v1 + v2 * v2 + k.0 * x1 * x1 + 2.0 * k.1 * x1 * x2 + k.2 * x2 * x2)
}
fn main() {
    let (k, x0, hw): (Mat, (f64, f64), f64) = ((2.0, -1.0, 2.0), (10.0, 0.0), 1e-4);
    let [(l1, u), (l2, w)] = modes(k);
    let res = modes(k).iter().map(|&(l, v)| (k.0 * v.0 + k.1 * v.1 - l * v.0).abs() + (k.1 * v.0 + k.2 * v.1 - l * v.1).abs()).fold(0.0, f64::max);
    let (mut cross, mut last): ([Vec<f64>; 2], [f64; 2]) = ([vec![], vec![]], [10.0, 10.0]); // zero crossings of x1 + x2, x1 - x2
    euler(k, x0, 20.0, hw, &mut |t, x1, x2| {
        for (j, val) in [x1 + x2, x1 - x2].into_iter().enumerate() {
            if val * last[j] < 0.0 { cross[j].push(t - hw * val / (val - last[j])) }
            last[j] = val;
        }
    });
    let per: Vec<f64> = cross.iter().map(|c| 2.0 * (c[c.len() - 1] - c[0]) / (c.len() - 1) as f64).collect();
    let errs: Vec<f64> = [0.01, 0.005, 0.0025].iter().map(|&h| (euler(k, x0, 10.0, h, &mut |_, _, _| {})[0] - exact(k, x0, 10.0).0).abs()).collect();
    let fine = euler(k, x0, 10.0, 1e-5, &mut |_, _, _| {});
    let ts: Vec<f64> = (0..25).map(|i| i as f64 / 2.0).collect();
    let wk: Mat = (1.05, -0.05, 1.05); // weak middle spring, 0.05 N/m: the carts trade the motion
    let dw = modes(wk)[1].0.sqrt() - modes(wk)[0].0.sqrt();
    let big_t = PI / dw;
    let mut peak = [0.0f64, 0.0f64];
    euler(wk, x0, big_t + PI, 1e-5, &mut |t, x1, x2| {
        if (t - big_t).abs() < PI { peak = [peak[0].max(x1.abs()), peak[1].max(x2.abs())] }
    });
    let e10 = exact(k, x0, 10.0);
    let (su, sw) = (x0.0 * u.0 + x0.1 * u.1, x0.0 * w.0 + x0.1 * w.1);
    let drop = modes((1.0, -1.0, 1.0));
    println!("trace {:.0}, determinant {:.0}: eigenvalues {:.0} and {:.0}, modes {:?} and {:?}", k.0 + k.2, k.0 * k.2 - k.1 * k.1, l1, l2, u, w);
    println!("largest |K v - lambda v| {:.12}; modes' dot product {:.0}; frequencies {:.3} and {:.3} rad/s; periods {:.3} and {:.3} s",
             res, u.0 * w.0 + u.1 * w.1, l1.sqrt(), l2.sqrt(), 2.0 * PI / l1.sqrt(), 2.0 * PI / l2.sqrt());
    println!("start (10, 0) cm = 5 x (1, 1) + 5 x (1, -1); energy {:.2} mJ = {:.2} slow + {:.2} fast", energy(k, [x0.0, x0.1, 0.0, 0.0]), 0.5 * l1 * 50.0 * 0.1, 0.5 * l2 * 50.0 * 0.1);
    println!("t (s)   {}", ts.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(" "));
    println!("x1 (cm) {}", ts.iter().map(|&t| format!("{:.2}", exact(k, x0, t).0)).collect::<Vec<_>>().join(" "));
    println!("x2 (cm) {}", ts.iter().map(|&t| format!("{:.2}", exact(k, x0, t).1)).collect::<Vec<_>>().join(" "));
    println!("t = 10 s: mode sum x1 {:.3}, x2 {:.3} cm; Euler h = 0.00001 x1 {:.3}, x2 {:.3} cm", e10.0, e10.1, fine[0], fine[1]);
    println!("Euler error in x1 at t = 10, h = 0.01, 0.005, 0.0025: {:.4} {:.4} {:.4} ratios {:.2} {:.2}", errs[0], errs[1], errs[2], errs[0] / errs[1], errs[1] / errs[2]);
    println!("periods timed from Euler's zero crossings: x1 + x2 {:.3} s, x1 - x2 {:.3} s", per[0], per[1]);
    println!("weak middle spring: eigenvalues {:.2} and {:.2}, frequencies {:.3} and {:.4} rad/s; cart 1 hands over at pi/{:.4} = {:.2} s", modes(wk)[0].0, modes(wk)[1].0, modes(wk)[0].0.sqrt(), modes(wk)[1].0.sqrt(), dw, big_t);
    println!("within pi s of {:.2} s: largest |x1| {:.2} cm (envelope says <= {:.2}), largest |x2| {:.2} cm", big_t, peak[0], 10.0 * (dw * PI / 2.0).sin(), peak[1]);
    println!("mistake, eigenvalue as frequency: fast period 2 pi/3 = {:.3} s, not {:.3}", 2.0 * PI / 3.0, 2.0 * PI / 3f64.sqrt());
    println!("mistake, share without dividing by |v|^2: {:.0} x (1, 1) + {:.0} x (1, -1) starts x1 at {:.0} cm", su, sw, su + sw);
    println!("mistake, wall springs dropped: frequencies {:.3} and {:.3} rad/s", drop[0].0.sqrt(), drop[1].0.sqrt());
    println!("mistake, Euler with h = 0.1 to t = 20: energy {:.0} mJ, not 10", energy(k, euler(k, x0, 20.0, 0.1, &mut |_, _, _| {})));
    assert!(res < 1e-12 && (per[0] - 2.0 * PI).abs() < 1e-3 && (per[1] - 2.0 * PI / 3f64.sqrt()).abs() < 1e-3);
    assert!((fine[0] - e10.0).abs() < 2e-3 && (fine[1] - e10.1).abs() < 2e-3);
    assert!((0..2).all(|i| errs[i] / errs[i + 1] > 1.8 && errs[i] / errs[i + 1] < 2.3)); // error halves with h: order one
    assert!(peak[1] > 9.5 && peak[0] <= 10.0 * (dw * PI / 2.0).sin() + 0.02);
    println!("ALL CHECKS PASS");
}
