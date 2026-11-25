// Leray-Schauder and a priori bounds -- the check behind the card.  std only.
// Slab, scaled: -((1 + u^2) u')' = t on (0, 1), u(0) = u(1) = 0.  Theta* = 100 K, L = 0.1 m.
use std::f64::consts::PI;

fn sci(x: f64, p: usize) -> String { // Python-style e-notation: two-digit exponent
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_once('e').unwrap();
    let (sign, digits) = if let Some(d) = e.strip_prefix('-') { ("-", d) } else { ("+", e) };
    format!("{}e{}{:0>2}", m, sign, digits)
}

fn kirchhoff_root(rhs: f64) -> f64 { // bisection for u + u^3/3 = rhs, rhs >= 0
    let (mut lo, mut hi) = (0.0f64, 1.0 + rhs);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if mid + mid * mid * mid / 3.0 < rhs { lo = mid } else { hi = mid }
    }
    0.5 * (lo + hi)
}

fn frozen_map(w: &[f64], s: f64) -> Vec<f64> { // T(w) = v with -((1 + w^2) v')' = s, trapezoid rule
    let (n, h) = (w.len() - 1, 1.0 / (w.len() - 1) as f64);
    let g: Vec<f64> = w.iter().map(|wi| 1.0 / (1.0 + wi * wi)).collect();
    let (mut i0, mut i1) = (0.0, 0.0);
    for j in 0..n {
        i0 += 0.5 * h * (g[j] + g[j + 1]);
        i1 += 0.5 * h * (j as f64 * h * g[j] + (j + 1) as f64 * h * g[j + 1]);
    }
    let c = i1 / i0;
    let mut v = vec![0.0; n + 1];
    for j in 0..n {
        v[j + 1] = v[j] + 0.5 * h * s * ((c - j as f64 * h) * g[j] + (c - (j + 1) as f64 * h) * g[j + 1]);
    }
    v
}

fn fixed_point(n: usize, s: f64) -> (Vec<f64>, usize) { // repeat T until it stops moving
    let (mut u, mut k) = (vec![0.0; n + 1], 0);
    loop {
        k += 1;
        let v = frozen_map(&u, s);
        let d = u.iter().zip(&v).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
        u = v;
        if d < 1e-15 || k > 500 { return (u, k); }
    }
}

fn det(mut a: Vec<Vec<f64>>) -> f64 { // Gaussian elimination with partial pivoting
    let (n, mut d) = (a.len(), 1.0);
    for i in 0..n {
        let mut p = i;
        for r in i..n { if a[r][i].abs() > a[p][i].abs() { p = r; } }
        if p != i { a.swap(i, p); d = -d; }
        d *= a[i][i];
        for r in i + 1..n {
            let f = a[r][i] / a[i][i];
            for col in i..n { a[r][col] -= f * a[i][col]; }
        }
    }
    d
}

fn main() {
    println!("scale: q L^2/(k0 theta*) = 10000 * 0.1^2 / (1 * 100) = {:.6}", 10000.0 * (0.1 * 0.1) / 100.0);
    let peak = kirchhoff_root(0.125);
    let p3 = (1.0f64 + 9.0 / 256.0).sqrt();
    let cbrt = |y: f64| y.abs().powf(1.0 / 3.0).copysign(y);
    let cardano = cbrt(3.0 / 16.0 + p3) + cbrt(3.0 / 16.0 - p3);
    println!("peak u(1/2), Kirchhoff root by bisection: {:.9}  = {:.4} K", peak, 100.0 * peak);
    println!("peak u(1/2), Cardano's formula:           {:.9}", cardano);
    assert!((peak - cardano).abs() < 1e-12);
    assert!(0.0 <= peak && peak <= 0.125);
    let (gap, kslope) = (0.125 * 0.125 * 0.125 / 3.0, 1.0 + 0.125 * 0.125);
    println!("hand Newton step from 1/8: K(1/8) - 1/8 = {:.6}, slope K'(1/8) = {:.6}, new guess {:.6}", gap, kslope, 0.125 - gap / kslope);
    assert!((0.125 - gap / kslope - peak).abs() < 1e-6);
    println!("constant conductivity peak 1/8: {:.6} = {:.4} K; nonlinearity lowers it {:.4} K", 0.125, 12.5, 100.0 * (0.125 - peak));
    let mut errs = vec![];
    for n in [50usize, 100, 200, 400] {
        let (u, k) = fixed_point(n, 1.0);
        errs.push((u[n / 2] - peak).abs());
        println!("fixed point of discrete T, N = {:3}: peak {:.9}, error {}, {} rounds", n, u[n / 2], sci(errs[errs.len() - 1], 3), k);
    }
    let order = (errs[1] / errs[2]).ln() / 2.0f64.ln();
    println!("observed order of the trapezoid fixed point: {:.3}", order);
    assert!(1.9 < order && order < 2.1); assert!(errs[2] < 1e-5);
    let x = 0.3;
    for h in [0.01f64, 0.005] {
        let um = kirchhoff_root((x - h) * (1.0 - (x - h)) / 2.0);
        let u0 = kirchhoff_root(x * (1.0 - x) / 2.0);
        let up = kirchhoff_root((x + h) * (1.0 - (x + h)) / 2.0);
        let (d1, d2) = ((up - um) / (2.0 * h), (up - 2.0 * u0 + um) / (h * h));
        let res = -(1.0 + u0 * u0) * d2 - 2.0 * u0 * d1 * d1 - 1.0;
        println!("residual of the equation at x = 0.3, h = {}: {}", h, sci(res, 3));
        assert!(res.abs() < 2e-5);
    }
    let (u, _) = fixed_point(200, 1.0);
    let w0 = (-3.0 * u[0] + 4.0 * u[1] - u[2]) * 100.0;
    println!("wall slope u'(0) from the N = 200 grid: {:.6} scaled = {:.1} K/m; wall flux {:.1} W/m^2, against q L/2 = {:.1} W/m^2", w0, w0 * 100.0 / 0.1, w0 * 1000.0, 10000.0 * 0.1 / 2.0);
    assert!((w0 - 0.5).abs() < 1e-4);
    let ts = [0.0f64, 0.2, 0.4, 0.6, 0.8, 0.9, 0.95];
    let slab: Vec<f64> = ts.iter().map(|t| kirchhoff_root(t / 8.0)).collect();
    for i in [1usize, 3] {
        let (t, pk) = (ts[i], slab[i]);
        let (u, _) = fixed_point(200, t);
        println!("t-family t = {:?}: peak {:.6} (grid {:.6}) <= bound t/8 = {:.6}", t, pk, u[100], t / 8.0);
        assert!((u[100] - pk).abs() < 1e-5);
        assert!(pk <= t / 8.0);
    }
    let wild: Vec<f64> = (0..400001).map(|j| 100.0 * (50.0 * PI * j as f64 / 400000.0).sin()).collect(); // 400,000 cells follow all 25 waves
    let v = frozen_map(&wild, 1.0);
    let slope = (0..400000).map(|j| (v[j + 1] - v[j]).abs() * 400000.0).fold(0.0, f64::max);
    let (vmin, vmax) = (v.iter().cloned().fold(f64::INFINITY, f64::min), v.iter().cloned().fold(f64::NEG_INFINITY, f64::max));
    println!("T(wild input, size 100, 400000 cells): min {:.6}, max {:.6} <= 1/8, steepest slope over a cell {:.6} <= 1", vmin, vmax, slope);
    assert!(vmin > -1e-12); assert!(vmax <= 0.125 && (vmax - 0.125 / (1.0f64 + 100.0 * 100.0).sqrt()).abs() < 1e-6); assert!(slope <= 1.0);
    let mut dets = vec![];
    for n in [20usize, 40, 80] {
        let (u, _) = fixed_point(n, 1.0);
        let (eps, mut jac) = (1e-6, vec![]);
        for j in 0..=n {
            let (mut a, mut b) = (u.clone(), u.clone());
            a[j] += eps; b[j] -= eps;
            let (ta, tb) = (frozen_map(&a, 1.0), frozen_map(&b, 1.0));
            jac.push((0..=n).map(|i| (ta[i] - tb[i]) / (2.0 * eps)).collect::<Vec<f64>>());
        }
        let m: Vec<Vec<f64>> = (0..=n).map(|i| (0..=n).map(|j| (if i == j { 1.0 } else { 0.0 }) - jac[j][i]).collect()).collect();
        let dv = det(m);
        println!("det(I - DT) at the solution, N = {}: {:.6}, index {}", n, dv, if dv > 0.0 { "+1" } else { "-1" });
        assert!(dv > 0.0);
        dets.push(dv);
    }
    assert!((dets[2] - dets[1]).abs() < 1e-4);
    let (mut lo, mut hi) = (0.5f64, 3.0f64);
    for _ in 0..200 {
        let mid = 0.5 * (lo + hi);
        if mid - (2.0 * mid).tanh() < 0.0 { lo = mid } else { hi = mid }
    }
    let root = 0.5 * (lo + hi);
    let idx: Vec<i32> = [-root, 0.0, root].iter().map(|m| if 1.0 - 2.0 / ((2.0 * m).cosh() * (2.0 * m).cosh()) > 0.0 { 1 } else { -1 }).collect();
    let deg_b = (1.0f64.copysign(3.0 - 6.0f64.tanh()) as i32 - 1.0f64.copysign(-3.0 + 6.0f64.tanh()) as i32) / 2;
    let sum: i32 = idx.iter().sum();
    println!("magnet m = tanh(2m): roots {:.6}, 0, {:.6}; indices {:?}; sum {}; degree on (-3, 3) from end signs {}", -root, root, idx, sum, deg_b);
    assert!(sum == 1 && deg_b == 1);
    assert!((root - (2.0 * root).tanh()).abs() < 1e-12);
    let (pi3, mut res_peaks, mut omit) = (PI * PI * PI, vec![], 0.0);
    for &t in ts.iter() {
        let k = PI * t.sqrt() / 2.0;
        let closed = if t > 0.0 { (1.0 / k.cos() - 1.0) / (PI * PI) } else { 0.0 };
        let mut series = 0.0;
        for i in 0..4000 {
            let nn = (2 * i + 1) as f64;
            series += (1 - 2 * (i % 2)) as f64 * 4.0 * t / (nn * pi3 * (nn * nn - t));
        }
        omit = 4.0 * t / (8001.0 * pi3 * (8001.0 * 8001.0 - t));
        res_peaks.push(closed);
        assert!((closed - series).abs() <= omit + 1e-12);
    }
    let fmt4 = |v: &[f64]| v.iter().map(|p| format!("{:.4}", p)).collect::<Vec<_>>().join(" ");
    println!("self-heating family -u'' = t(pi^2 u + 1): peaks {} (series agrees; first omitted term <= {})", fmt4(&res_peaks), sci(omit, 1));
    for t in [0.99f64, 0.999] {
        println!("  t = {:?}: peak {:.4}", t, (1.0 / (PI * t.sqrt() / 2.0).cos() - 1.0) / (PI * PI));
    }
    println!("  t = 1: no solution, since int_0^1 1 * sin(pi x) dx = 2/pi = {:.6}, not 0", 2.0 / PI);
    println!("chart t: {}", ts.iter().map(|t| format!("{:?}", t)).collect::<Vec<_>>().join(" "));
    println!("chart slab peaks: {}", fmt4(&slab));
    println!("chart self-heating peaks: {}", fmt4(&res_peaks));
    let big = kirchhoff_root(1.0);
    println!("source 8 (q = 80 kW/m^3): peak {:.6} = {:.2} K; constant conductivity {:.6} = {:.2} K", big, 100.0 * big, 1.0, 100.0);
    assert!((big + big * big * big / 3.0 - 1.0).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
