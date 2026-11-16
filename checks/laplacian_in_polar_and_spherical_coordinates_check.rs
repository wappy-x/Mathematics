// The Laplacian in round coordinates -- the check behind the card.  std only, no crates.
// A steel drum lid, radius 0.30 m, faces lagged, rim held at 30 + 12 cos(phi) + 4 cos(2 phi) degC.
// Roads: the round formulas against the exact Cartesian Laplacian; the mode series against
// the Poisson integral and the rim mean; the equation's residual at two steps; the same in a ball.
use std::f64::consts::PI;

const R: f64 = 0.30; // lid radius, m
const A: [(usize, f64); 3] = [(0, 30.0), (1, 12.0), (2, 4.0)]; // rim modes: degC times cos(m phi)
const RA: f64 = 0.15; // the point read off, m from the centre

fn sci(x: f64) -> String { format!("{:.2e}", x) }

fn lid(r: f64, p: f64) -> f64 { // the mode series: mode m fades as (r/R)^m
    A.iter().map(|&(m, a)| a * (r / R).powf(m as f64) * (m as f64 * p).cos()).sum()
}
fn rim(p: f64) -> f64 { lid(R, p) }

fn polar_lap(u: &dyn Fn(f64, f64) -> f64, r: f64, p: f64, h: f64) -> f64 { // flux through a small polar box, per unit area
    let rad = ((r + h / 2.0) * (u(r + h, p) - u(r, p)) - (r - h / 2.0) * (u(r, p) - u(r - h, p))) / (h * h * r);
    rad + (u(r, p + h) - 2.0 * u(r, p) + u(r, p - h)) / (h * h * r * r)
}
fn ang_lap(y: &dyn Fn(f64, f64) -> f64, t: f64, p: f64, h: f64) -> f64 { // the angular part of the spherical Laplacian
    let th = ((t + h / 2.0).sin() * (y(t + h, p) - y(t, p)) - (t - h / 2.0).sin() * (y(t, p) - y(t - h, p))) / (h * h * t.sin());
    th + (y(t, p + h) - 2.0 * y(t, p) + y(t, p - h)) / (h * h * t.sin().powf(2.0))
}
fn sph_lap(u: &dyn Fn(f64, f64, f64) -> f64, r: f64, t: f64, p: f64, h: f64) -> f64 { // radial flux through r^2 faces, plus angular over r^2
    let rad = ((r + h / 2.0).powf(2.0) * (u(r + h, t, p) - u(r, t, p)) - (r - h / 2.0).powf(2.0) * (u(r, t, p) - u(r - h, t, p))) / (h * h * r * r);
    rad + ang_lap(&|tt, pp| u(r, tt, pp), t, p, h) / (r * r)
}
fn legendre(n: usize) -> Vec<f64> { // coefficients of P_n, by Bonnet's rule
    let mut p: Vec<Vec<f64>> = vec![vec![1.0], vec![0.0, 1.0]];
    for k in 1..n {
        let kf = k as f64;
        let mut a = vec![0.0];
        a.extend(p[k].iter().map(|c| (2.0 * kf + 1.0) * c / (kf + 1.0)));
        for (i, c) in p[k - 1].iter().enumerate() { a[i] -= kf * c / (kf + 1.0); }
        p.push(a);
    }
    p[n].clone()
}
fn assoc(n: usize, m: usize, s: f64) -> f64 { // P_n^m(s) = (1 - s^2)^(m/2) times the m-th derivative of P_n, s = cos(theta)
    let mut c = legendre(n);
    for _ in 0..m {
        c = (1..c.len()).map(|i| i as f64 * c[i]).collect();
        if c.is_empty() { c = vec![0.0]; }
    }
    (1.0 - s * s).powf(m as f64 / 2.0) * c.iter().enumerate().map(|(i, ci)| ci * s.powf(i as f64)).sum::<f64>()
}
fn ball(r: f64, t: f64, _p: f64) -> f64 {
    A.iter().map(|&(n, a)| a * (r / R).powf(n as f64) * assoc(n, 0, t.cos())).sum()
}

fn main() {
    println!("1. The round formulas against the exact Cartesian Laplacian");
    let (x, y) = (0.2 * 0.7f64.cos(), 0.2 * 0.7f64.sin());
    let g2 = |r: f64, p: f64| (r * p.cos()).powf(3.0) * (r * p.sin()) + (r * p.cos()).powf(2.0);
    let e2: Vec<f64> = [0.01, 0.005].iter().map(|&h| polar_lap(&g2, 0.2, 0.7, h) - (6.0 * x * y + 2.0)).collect();
    println!("polar, x^3 y + x^2 at r 0.2 m, phi 0.7: exact {:.6}; error h 0.01 {}, h 0.005 {}, ratio {:.2}", 6.0 * x * y + 2.0, sci(e2[0]), sci(e2[1]), e2[0] / e2[1]);
    assert!(e2[1].abs() < 1e-3 && 3.5 < e2[0] / e2[1] && e2[0] / e2[1] < 4.5);
    let cart = |r: f64, t: f64, p: f64| (r * t.sin() * p.cos(), r * t.sin() * p.sin(), r * t.cos());
    let g3 = |r: f64, t: f64, p: f64| { let (x, y, z) = cart(r, t, p); x * x * y * z + z.powf(3.0) };
    let (_, yy, zz) = cart(0.25, 1.0, 0.6);
    let e3: Vec<f64> = [0.01, 0.005].iter().map(|&h| sph_lap(&g3, 0.25, 1.0, 0.6, h) - (2.0 * yy * zz + 6.0 * zz)).collect();
    println!("spherical, x^2 y z + z^3 at r 0.25 m: exact {:.6}; error h 0.01 {}, h 0.005 {}, ratio {:.2}", 2.0 * yy * zz + 6.0 * zz, sci(e3[0]), sci(e3[1]), e3[0] / e3[1]);
    assert!(e3[1].abs() < 1e-3 && 3.5 < e3[0] / e3[1] && e3[0] / e3[1] < 4.5);

    println!("2. Angular modes: the angular part returns -n(n+1) times Y_n^m");
    for &(n, m) in &[(1usize, 0usize), (2, 0), (2, 1), (2, 2), (3, 1)] {
        let yf = move |t: f64, p: f64| assoc(n, m, t.cos()) * (m as f64 * p).cos();
        let lam = ang_lap(&yf, 0.9, 0.4, 1e-3) / yf(0.9, 0.4);
        let nn = (n * (n + 1)) as f64;
        println!("n {}, m {}: ratio {:.4}, -n(n+1) = {}", n, m, lam, -(nn as i64));
        assert!((lam + nn).abs() < 1e-4);
    }
    println!("P_2^1(0.6) = {:.4}, by hand 3 s sqrt(1 - s^2) = {:.4}", assoc(2, 1, 0.6), 3.0 * 0.6 * 0.8);

    println!("3. The drum lid: the mode series against the Poisson integral");
    let nq = 256;
    let ps: Vec<f64> = (0..nq).map(|k| 2.0 * PI * k as f64 / nq as f64).collect();
    let coef: Vec<f64> = (0..4).map(|m| ps.iter().map(|&p| rim(p) * (m as f64 * p).cos()).sum::<f64>() / nq as f64 * if m == 0 { 1.0 } else { 2.0 }).collect();
    let parts: Vec<String> = coef.iter().enumerate().map(|(m, &c)| format!("m {} {:.6} degC", m, if c.abs() > 5e-7 { c } else { 0.0 })).collect();
    println!("rim modes by a 256-point sum: {}", parts.join(", "));
    assert!((0..4).all(|m| (coef[m] - A.iter().find(|a| a.0 == m).map_or(0.0, |a| a.1)).abs() < 1e-9));
    let poisson = |r: f64, p: f64| ps.iter().map(|&q| (R * R - r * r) / (R * R - 2.0 * R * r * (p - q).cos() + r * r) * rim(q)).sum::<f64>() / nq as f64;
    for &(lab, r, p) in &[("centre", 0.0, 0.0), ("halfway, hot side", RA, 0.0), ("halfway, 90 deg round", RA, PI / 2.0)] {
        println!("{}: series {:.6} degC, Poisson integral {:.6} degC", lab, lid(r, p), poisson(r, p));
        assert!((lid(r, p) - poisson(r, p)).abs() < 1e-9);
    }
    println!("hand rows at r/R {:.2}: mode 0 {:.2}, mode 1 {:.2}, mode 2 {:.2} degC", RA / R, A[0].1, A[1].1 * (RA / R), A[2].1 * (RA / R).powf(2.0));
    let res: Vec<f64> = [0.01, 0.005].iter().map(|&h| polar_lap(&lid, RA, 0.0, h)).collect();
    println!("residual of the series in the polar formula: h 0.01 {:.6}, h 0.005 {:.6} degC/m^2, ratio {:.2}", res[0], res[1], res[0] / res[1]);
    assert!(res[1].abs() < 0.01 && 3.5 < res[0] / res[1] && res[0] / res[1] < 4.5);
    let s: Vec<f64> = (0..13).map(|k| 0.05 * k as f64 - 0.30).collect();
    let hot: Vec<String> = s.iter().map(|&s| format!("{:.2}", lid(s.abs(), if s >= 0.0 { 0.0 } else { PI }))).collect();
    println!("chart, hot-cold diameter, x from -0.30 to 0.30 m: {}", hot.join(", "));
    let cross: Vec<String> = s.iter().map(|&s| format!("{:.2}", lid(s.abs(), PI / 2.0))).collect();
    println!("chart, cross diameter: {}", cross.join(", "));

    println!("4. The same pattern on a ball, radius 0.30 m: surface 30 + 12 P_1 + 4 P_2 of cos(theta)");
    println!("halfway on the axis {:.6} degC, halfway on the equator {:.6} degC", ball(RA, 0.0, 0.0), ball(RA, PI / 2.0, 0.0));
    let mm = 200;
    let mean = (0..=mm).map(|i| {
        let w = if i == 0 || i == mm { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        let t = i as f64 * PI / mm as f64;
        w * ball(R, t, 0.0) * t.sin()
    }).sum::<f64>() * PI / (3.0 * mm as f64) / 2.0;
    println!("surface mean, Simpson in theta, 200 steps: {:.6} degC = centre {:.6} degC", mean, ball(0.0, 0.0, 0.0));
    assert!((mean - ball(0.0, 0.0, 0.0)).abs() < 1e-6);
    let rb: Vec<f64> = [0.01, 0.005].iter().map(|&h| sph_lap(&ball, RA, 0.8, 0.3, h)).collect();
    println!("residual of the ball in the spherical formula: h 0.01 {:.6}, h 0.005 {:.6} degC/m^2, ratio {:.2}", rb[0], rb[1], rb[0] / rb[1]);
    assert!(rb[1].abs() < 0.01 && 3.5 < rb[0] / rb[1] && rb[0] / rb[1] < 4.5);
    println!("outside, at r = 2R, a degree-1 pattern keeps: disc {:.3}, ball {:.3}; degree 2: disc {:.3}, ball {:.3}", 0.5f64.powf(1.0), 0.5f64.powf(2.0), 0.5f64.powf(2.0), 0.5f64.powf(3.0));

    println!("5. What breaks");
    let q = RA / R;
    let k2: Vec<f64> = [1.0f64, 2.0].iter().map(|m| (1.0 + (1.0 + 4.0 * m * m).sqrt()) / 2.0).collect();
    let w1 = A[0].1 + A[1].1 * q.powf(k2[0]) + A[2].1 * q.powf(k2[1]);
    println!("mistake 1, drop u_r/r: powers {:.6}, {:.6}; halfway {:.2} degC, not {:.2}", k2[0], k2[1], w1, lid(RA, 0.0));
    println!("mistake 2, no fade: halfway {:.2} degC, not {:.2}", A.iter().map(|a| a.1).sum::<f64>(), lid(RA, 0.0));
    let scan: Vec<f64> = (0..3600).map(|k| rim(2.0 * PI * k as f64 / 3600.0)).collect();
    let (mx, mn) = (scan.iter().cloned().fold(f64::MIN, f64::max), scan.iter().cloned().fold(f64::MAX, f64::min));
    println!("mistake 3, centre as the rim's midrange: ({:.2} + {:.2})/2 = {:.2} degC, not {:.2}", mx, mn, (mx + mn) / 2.0, lid(0.0, 0.0));
    let a_in = 0.025f64; // bung radius, m
    let bung = |n_r: usize| -> f64 { // radial grid of n_r cells; returns the temperature at RA
        let hr = (R - a_in) / n_r as f64;
        let rr: Vec<f64> = (0..=n_r).map(|i| a_in + i as f64 * hr).collect();
        let sub: Vec<f64> = rr.iter().map(|r| r - hr / 2.0).collect();
        let sup: Vec<f64> = rr.iter().map(|r| r + hr / 2.0).collect();
        let mut dg: Vec<f64> = (0..=n_r).map(|i| -(sub[i] + sup[i])).collect();
        let mut rhs = vec![0.0; n_r + 1];
        rhs[1] -= sub[1] * 60.0;
        rhs[n_r - 1] -= sup[n_r - 1] * 30.0;
        for i in 2..n_r { // Thomas sweep on the flux equations, rows 1 .. n_r - 1
            let w = sub[i] / dg[i - 1];
            dg[i] -= w * sup[i - 1];
            rhs[i] -= w * rhs[i - 1];
        }
        let mut u = vec![0.0; n_r + 1];
        u[0] = 60.0;
        u[n_r] = 30.0;
        for i in (1..n_r).rev() {
            u[i] = (rhs[i] - if i < n_r - 1 { sup[i] * u[i + 1] } else { 0.0 }) / dg[i];
        }
        u[((RA - a_in) / hr).round() as usize]
    };
    let exact = 30.0 + 30.0 * (RA / R).ln() / (a_in / R).ln();
    let grid: Vec<f64> = [220usize, 440, 880].iter().map(|&n| bung(n)).collect(); // steps 1.25, 0.625, 0.3125 mm
    let be: Vec<f64> = grid.iter().map(|g| g - exact).collect();
    println!("mistake 4, bung of radius 2.5 cm at 60 degC, rim 30 degC: log form {:.4}, grid {:.4} degC; centre rule gives 30.00", exact, grid[1]);
    println!("bung grid error at steps 1.25, 0.625, 0.3125 mm: {}, {}, {} degC; observed order {:.2}, {:.2}", sci(be[0]), sci(be[1]), sci(be[2]), (be[0] / be[1]).log2(), (be[1] / be[2]).log2());
    assert!(be[2].abs() < 1e-4 && 1.9 < (be[1] / be[2]).log2() && (be[1] / be[2]).log2() < 2.1);
    let kb: Vec<f64> = [1.0f64, 2.0].iter().map(|n| (-1.0 + (1.0 + 4.0 * n * n).sqrt()) / 2.0).collect();
    let w5 = A[0].1 + A[1].1 * q.powf(kb[0]) + A[2].1 * q.powf(kb[1]);
    println!("mistake 5, ball with angular number n^2: powers {:.6}, {:.6}; axis halfway {:.2} degC, not {:.2}", kb[0], kb[1], w5, ball(RA, 0.0, 0.0));
    println!("ALL CHECKS PASS");
}
