// Chain rule in several variables -- the same check as the Python, in Rust.
// No crates.  Path p(t) = (2t, t^2) km; weather map G(x, y) = (13 - x - y^2,
// 5 + xy + 3y) gives air temperature A in C and wind w in km/h; felt
// temperature F(A, w) = A - 0.02 w (30 - A).  Rate of the felt temperature at t = 1.
fn p(t: f64) -> (f64, f64) { (2.0 * t, t * t) }
fn g(x: f64, y: f64) -> (f64, f64) { (13.0 - x - y * y, 5.0 + x * y + 3.0 * y) }
fn f(a: f64, w: f64) -> f64 { a - 0.02 * w * (30.0 - a) }
fn fg(x: f64, y: f64) -> f64 { let (a, w) = g(x, y); f(a, w) }
fn felt(t: f64) -> f64 { let (x, y) = p(t); fg(x, y) }
fn matmul(p: &[Vec<f64>], q: &[Vec<f64>]) -> Vec<Vec<f64>> {   // rows of p against columns of q
    (0..p.len()).map(|i| (0..q[0].len()).map(|j| (0..q.len()).map(|k| p[i][k] * q[k][j]).sum()).collect()).collect()
}
fn fmt(v: &[f64], d: usize) -> String {
    format!("[{}]", v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", "))
}
fn q(a: f64, b: f64) -> f64 { if a == 0.0 && b == 0.0 { 0.0 } else { a * a * b / (a * a + b * b) } }
fn main() {
    let t = 1.0;
    let (x, y) = p(t);
    let (a, w) = g(x, y);
    let jp = vec![vec![2.0], vec![2.0 * t]];                            // 2 x 1: km/h east, north
    let jg = vec![vec![-1.0, -2.0 * y], vec![y, x + 3.0]];              // 2 x 2: read at (x, y)
    let jf = vec![vec![1.0 + 0.02 * w, -0.02 * (30.0 - a)]];            // 1 x 2: read at (A, w)
    let inner = matmul(&jg, &jp);                                       // rates of A and w per hour
    let chain = matmul(&jf, &inner)[0][0];                              // road 1: matrices multiply
    let grad = matmul(&jf, &jg)[0].clone();                             // felt C per km
    println!("at t = 1 h: position ({:.0}, {:.0}) km, air {:.0} C, wind {:.0} km/h, felt {:.2} C", x, y, a, w, f(a, w));
    println!("J_p = {}; J_G rows {}, {}; J_F = {}", fmt(&[jp[0][0], jp[1][0]], 0), fmt(&jg[0], 0), fmt(&jg[1], 0), fmt(&jf[0], 1));
    println!("J_G J_p: air {:.0} C/h, wind {:.0} km/h per h", inner[0][0], inner[1][0]);
    println!("road 1, J_F (J_G J_p) = {:.2} C/h", chain);
    let routes: Vec<f64> = (0..4).map(|n| jf[0][n / 2] * jg[n / 2][n % 2] * jp[n % 2][0]).collect();
    println!("four routes t -> x or y -> A or w -> F: {}, sum {:.2}", fmt(&routes, 2), routes.iter().sum::<f64>());
    println!("grouped the other way, J_F J_G = {} C/km, times J_p: {:.2}", fmt(&grad, 2), grad[0] * jp[0][0] + grad[1] * jp[1][0]);
    let e = 1e-6;                                                       // felt gradient by nudges
    let fx = (fg(x + e, y) - fg(x - e, y)) / (2.0 * e);
    let fy = (fg(x, y + e) - fg(x, y - e)) / (2.0 * e);
    println!("felt gradient by nudging x and y: {} C/km", fmt(&[fx, fy], 4));
    let mut errs = Vec::new();
    for h in [0.1, 0.01, 0.001] {                                       // road 2: secants of the walk
        let qq = (felt(t + h) - felt(t)) / h;
        errs.push(qq - chain);
        println!("road 2, secant over h = {} h: {:.5} C/h, misses by {:.5}", h, qq, qq - chain);
    }
    let (mut lo, mut hi) = (0.0_f64, 0.1_f64);                          // largest step within 0.01 C/h
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if ((felt(t + mid) - felt(t)) / mid - chain).abs() < 0.01 { lo = mid } else { hi = mid }
    }
    println!("tolerance: every forward step under {:.6} h ({:.2} s) lands within 0.01 C/h", (lo * 1e6).floor() / 1e6, (lo * 360000.0).floor() / 100.0);
    let central = (felt(t + 1e-5) - felt(t - 1e-5)) / 2e-5;
    println!("road 2, central secant over h = 0.00001 h: {:.6} C/h", central);
    let jg_bad = vec![vec![-1.0, -2.0 * 1.0], vec![1.0, 1.0 + 3.0]];   // J_G read at (1, 1), not (2, 1)
    println!("mistake 1, J_G read at (1, 1): {:.2} C/h", matmul(&jf, &matmul(&jg_bad, &jp))[0][0]);
    let jgt = vec![vec![jg[0][0], jg[1][0]], vec![jg[0][1], jg[1][1]]]; // rows and columns swapped
    println!("mistake 2, J_G transposed: {:.2} C/h", matmul(&jf, &matmul(&jgt, &jp))[0][0]);
    println!("mistake 3, wind ignored, felt = air: {:.2} C/h", inner[0][0]);
    let (qx, qy) = ((q(1e-6, 0.0) - q(0.0, 0.0)) / 1e-6, (q(0.0, 1e-6) - q(0.0, 0.0)) / 1e-6);
    let walk = (q(1e-6, 1e-6) - q(0.0, 0.0)) / 1e-6;
    println!("crease: partials at 0 are {:.2}, {:.2}, so chain gives {:.2}; walking the diagonal gives {:.2}", qx, qy, qx + qy, walk);
    let pts: Vec<f64> = (0..9).map(|i| i as f64 / 4.0).collect();
    println!("chart, felt C at t = 0, 0.25, ..., 2: {}", fmt(&pts.iter().map(|&s| felt(s)).collect::<Vec<_>>(), 2));
    println!("chart, tangent at t = 1: {}", fmt(&pts.iter().map(|&s| felt(t) + chain * (s - t)).collect::<Vec<_>>(), 2));
    assert!((chain - central).abs() < 1e-6);                            // matrices = the composed walk
    assert!(errs[0] / errs[1] > 9.0 && errs[0] / errs[1] < 11.0 && errs[2].abs() < 0.05);
    assert!((grad[0] - fx).abs() < 1e-6 && (grad[1] - fy).abs() < 1e-6); // J_F J_G = nudged gradient
    assert!((walk - 0.5).abs() < 1e-9 && qx + qy == 0.0);               // the crease breaks the rule
    println!("ALL CHECKS PASS");
}
