// Trace and Rellich-Kondrachov in outline: a 1 m square plate, temperatures in deg C above room.
// Every computation is a truncation (N cells, n x n pixels, N modes) shown at several sizes.
use std::f64::consts::PI;

fn thomas(lo: &[f64], di: &[f64], up: &[f64], rhs: &[f64]) -> Vec<f64> {
    // tridiagonal solve, written out: lo/up are the off-diagonals, di the diagonal
    let n = di.len();
    let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    (c[0], d[0]) = (up[0] / di[0], rhs[0] / di[0]);
    for i in 1..n {
        let m = di[i] - lo[i] * c[i - 1];
        c[i] = if i < n - 1 { up[i] / m } else { 0.0 };
        d[i] = (rhs[i] - lo[i] * d[i - 1]) / m;
    }
    let mut x = d.clone();
    for i in (0..n - 1).rev() {
        x[i] = d[i] - c[i] * x[i + 1];
    }
    x
}

fn min_energy(nc: usize, stiff: f64) -> f64 {
    // smallest ||u||^2 (stiff=1: H1 norm, stiff=0: L2 norm) over piecewise-linear u on N cells with u(0) = 1
    let h = 1.0 / nc as f64;
    let (a0, off) = (stiff / h + h / 3.0, -stiff / h + h / 6.0);
    let mut di = vec![2.0 * a0; nc];
    di[nc - 1] = a0;
    let mut rhs = vec![0.0; nc];
    rhs[0] = -off;
    let v = thomas(&vec![off; nc], &di, &vec![off; nc], &rhs);
    a0 + off * v[0]
}

fn sci3(x: f64) -> String {
    // Python's {:.3e}: two-digit signed exponent
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let ev: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { '-' } else { '+' }, ev.abs())
}

fn edge_from_inside(n: usize) -> f64 {
    // midpoint pixels only, never the edge: integral of w^2 - 2(1 - x) w w_x, w_x by differences
    let h = 1.0 / n as f64;
    let mut tot = 0.0;
    for j in 0..n {
        let y = (j as f64 + 0.5) * h;
        let col: Vec<f64> = (0..n).map(|i| 60.0 * (-PI * (i as f64 + 0.5) * h).exp() * (PI * y).sin()).collect();
        for i in 0..n {
            let wx = if i == 0 {
                (-3.0 * col[0] + 4.0 * col[1] - col[2]) / (2.0 * h)
            } else if i == n - 1 {
                (3.0 * col[i] - 4.0 * col[i - 1] + col[i - 2]) / (2.0 * h)
            } else {
                (col[i + 1] - col[i - 1]) / (2.0 * h)
            };
            let x = (i as f64 + 0.5) * h;
            tot += (col[i].powi(2) - 2.0 * (1.0 - x) * col[i] * wx) * h * h;
        }
    }
    tot
}

fn coef(k: usize) -> f64 {
    // cosine coefficient of f(x) = 60 exp(-pi x), basis 1, sqrt(2) cos(k pi x)
    let e = (-PI).exp();
    if k == 0 {
        return 60.0 * (1.0 - e) / PI;
    }
    let sgn = if k % 2 == 0 { 1.0 } else { -1.0 };
    2f64.sqrt() * 60.0 * (1.0 - sgn * e) / (PI * (1.0 + (k * k) as f64))
}

fn coef_quad(k: usize, kk: usize) -> f64 {
    let mut s = 0.0;
    for i in 0..kk {
        let x = (i as f64 + 0.5) / kk as f64;
        let b = if k == 0 { 1.0 } else { 2f64.sqrt() * (k as f64 * PI * x).cos() };
        s += 60.0 * (-PI * x).exp() * b;
    }
    s / kk as f64
}

fn main() {
    let coth1 = 1f64.cosh() / 1f64.sinh();
    println!("== Trace on the interval (0, 1): sharpest C with u(0)^2 <= C ||u||^2 ==");
    println!("closed form coth(1) = {:.10}  (minimiser cosh(1 - x)/cosh(1), energy tanh(1) = {:.10})", coth1, 1f64.tanh());
    let ns = [4usize, 16, 64, 256];
    let mut errs = vec![];
    for &n in &ns {
        let (r1, r0) = (1.0 / min_energy(n, 1.0), 1.0 / min_energy(n, 0.0));
        errs.push(coth1 - r1);
        println!("N={:4} cells: H1 ratio {:.10}  gap {}   L2-only ratio {:10.3}  = {:.6} N", n, r1, sci3(coth1 - r1), r0, r0 / n as f64);
        assert!(coth1 - r1 > 0.0 && coth1 - r1 < 0.01 && (r0 / n as f64 - 2.0 * 3f64.sqrt()).abs() < 1e-3);
    }
    errs.windows(2).for_each(|w| assert!(w[0] / w[1] > 14.0 && w[0] / w[1] < 18.0));
    println!("gap shrink per 4x cells: {:.2} {:.2} {:.2}", errs[0] / errs[1], errs[1] / errs[2], errs[2] / errs[3]);
    println!("L2-only ratio / N -> 2 sqrt(3) = {:.6}: no bound survives N -> infinity", 2.0 * 3f64.sqrt());
    let row = |f: &dyn Fn(usize) -> String| ns.iter().map(|&n| f(n)).collect::<Vec<_>>().join(",");
    println!("chart,log10 N,{}", row(&|n| format!("{:.2}", (n as f64).log10())));
    println!("chart,log10 H1 ratio,{}", row(&|n| format!("{:.3}", (1.0 / min_energy(n, 1.0)).log10())));
    println!("chart,log10 L2 ratio,{}", row(&|n| format!("{:.3}", (1.0 / min_energy(n, 0.0)).log10())));

    println!("== The plate: w(x, y) = 60 exp(-pi x) sin(pi y), left edge x = 0 ==");
    let e2 = 1.0 - (-2.0 * PI).exp();
    let l2 = 1800.0 * e2 / (2.0 * PI);
    let (gr, h1) = (1800.0 * PI * e2, l2 + 1800.0 * PI * e2);
    println!("||w||^2 = {:.4}  ||grad w||^2 = {:.4}  ||w||_H1^2 = {:.4}", l2, gr, h1);
    println!("edge integral of w^2 = 1800 (exact), rms edge excess = {:.4} C, peak 60 C", 1800f64.sqrt());
    let wx = PI * PI * l2; // w_x = -pi w, half of the gradient's energy
    println!("||w_x||^2 = {:.4}  bounds on 1800: crude 2(||w||^2 + ||w_x||^2) = {:.4}", wx, 2.0 * (l2 + wx));
    println!("  sharp coth(1)(||w||^2 + ||w_x||^2) = {:.4}  coth(1)||w||_H1^2 = {:.4}", coth1 * (l2 + wx), coth1 * h1);
    assert!((2.0 * wx - gr).abs() < 1e-9 * gr);
    assert!(1800.0 <= coth1 * (l2 + wx) && coth1 * (l2 + wx) <= 2.0 * (l2 + wx));
    let mut prev = 0.0;
    for &n in &[20usize, 80, 320] {
        let v = edge_from_inside(n);
        let err = (v - 1800.0).abs();
        println!("{:3} x {:<3} interior pixels: edge integral {:.4}  error {:.4}", n, n, v, err);
        if prev > 0.0 {
            assert!(prev / err > 15.0 && prev / err < 30.0);
            println!("  error shrink {:.2}x", prev / err);
        }
        prev = err;
    }
    assert!(prev < 0.02);

    println!("== What breaks: a hot layer of width eps on the left edge, 100 C at the edge ==");
    for &eps in &[0.1f64, 0.01, 0.001] {
        let (l2d, gx) = (1e4 * eps / 3.0, 1e4 / eps);
        // midpoint rule over the layer, independent of the closed forms
        let m = 1000;
        let s: f64 = (0..m).map(|k| (100.0 * (1.0 - (k as f64 + 0.5) / m as f64)).powi(2)).sum::<f64>() * eps / m as f64;
        assert!((s - l2d).abs() < 1e-3 * l2d);
        println!("eps={:<6}: ||u||^2 = {:.4}  edge = 10000  ratio {:.0}  ||u_x||^2 = {:.0}  H1 bound {:.0}", eps, l2d, 1e4 / l2d, gx, coth1 * (l2d + gx));
        assert!(coth1 * (l2d + gx) >= 1e4);
    }
    let tent = |x: f64| (1.0 - x.abs()).max(0.0); // 1 m tent on an endless strip, slid 2 m
    let xs: Vec<f64> = (0..40000).map(|k| -1.0 + (k as f64 + 0.5) * 1e-4).collect();
    let dist2 = xs.iter().map(|&x| (tent(x) - tent(x - 2.0)).powi(2)).sum::<f64>() * 1e-4;
    let h1t = xs.iter().map(|&x| tent(x).powi(2) + if x.abs() < 1.0 { 1.0 } else { 0.0 }).sum::<f64>() * 1e-4;
    println!("tent: ||tent||_H1^2 = {:.6} (8/3)  L2 distance between slides 2 m apart = {:.6}", h1t, dist2.sqrt());
    assert!((dist2 - 4.0 / 3.0).abs() < 1e-6 && (h1t - 8.0 / 3.0).abs() < 1e-6);

    println!("== Rellich: ripples sqrt(2) sin(n pi x) on (0, 1) ==");
    for &n in &[1usize, 10, 100] {
        let kk = 4000;
        let mut d2 = 0.0;
        for k in 0..kk {
            let x = (k as f64 + 0.5) / kk as f64;
            d2 += (2f64.sqrt() * ((n as f64 * PI * x).sin() - ((2 * n) as f64 * PI * x).sin())).powi(2);
        }
        d2 /= kk as f64;
        println!("n={:3}: ||s_n||_H1^2 = {:.4}  L2 distance to s_2n = {:.6}", n, 1.0 + (n as f64 * PI).powi(2), d2.sqrt());
        assert!((d2 - 2.0).abs() < 1e-6);
    }
    println!("== Rellich: keep N cosine modes; worst L2 error over the H1 unit ball ==");
    [0usize, 1, 2, 7].iter().for_each(|&k| assert!((coef(k) - coef_quad(k, 20000)).abs() < 1e-4));
    let fh1 = (1.0 + PI * PI) * 3600.0 * e2 / (2.0 * PI);
    let energy: f64 = (0..200000usize).map(|k| (1.0 + (k as f64 * PI).powi(2)) * coef(k).powi(2)).sum();
    println!("midline f = 60 exp(-pi x): ||f||_H1^2 = {:.4}, sum (1 + k^2 pi^2) c_k^2 = {:.4}", fh1, energy);
    assert!((energy - fh1).abs() < 0.1);
    for &n in &[1usize, 10, 100] {
        let worst = 1.0 / (1.0 + (n as f64 * PI).powi(2)).sqrt();
        let tail = (n..200000usize).map(|k| coef(k).powi(2)).sum::<f64>().sqrt();
        println!("N={:3}: worst {:.6}  f's tail {:.6} <= {:.6}  L2 ball worst 1", n, worst, tail, worst * fh1.sqrt());
        assert!(tail <= worst * fh1.sqrt());
    }
    println!("ALL CHECKS PASS");
}
