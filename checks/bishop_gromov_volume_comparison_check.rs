// Bishop-Gromov volume comparison -- the same check as bishop_gromov_volume_comparison_check.py.
// Standard library only, no crates.  A ball is everything within flying distance r of one point.
// Roads: closed-form ball areas against areas built from Jacobi fields stepped by RK4; the flattened
// Earth's polar ball from its geometry against the Jacobi equation; a no-fly zone by rays and a grid.
use std::f64::consts::PI;

const R: f64 = 6371.0;                                  // the globe, km (a model)
const A_EQ: f64 = 6378.137;                             // WGS 84 semi-axes, km
const B_POL: f64 = 6356.752314245;
const D: f64 = 600.0; const Z: f64 = 300.0;             // no-fly zone: centre km east of the airport, radius km

fn flat(r: f64) -> f64 { PI * r * r }
fn globe(r: f64, rr: f64) -> f64 { 2.0 * PI * rr * rr * (1.0 - (r / rr).cos()) }
fn saddle(r: f64) -> f64 { 2.0 * PI * R * R * ((r / R).cosh() - 1.0) }

fn rk4<F: Fn(&[f64]) -> Vec<f64>>(f: F, y: &[f64], h: f64) -> Vec<f64> {
    let step = |a: &[f64], b: &[f64], c: f64| -> Vec<f64> { a.iter().zip(b).map(|(x, d)| x + c * d).collect() };
    let k1 = f(y); let k2 = f(&step(y, &k1, h / 2.0));
    let k3 = f(&step(y, &k2, h / 2.0)); let k4 = f(&step(y, &k3, h));
    (0..y.len()).map(|i| y[i] + h / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect()
}

fn jacobi_area(k: f64, r: f64, steps: usize) -> f64 {   // state: gap per radian f, its rate, area
    let (mut y, h) = (vec![0.0, 1.0, 0.0], r / steps as f64);
    for _ in 0..steps { y = rk4(|z| vec![z[1], -k * z[0], 2.0 * PI * z[0]], &y, h); }
    y[2]
}

fn w(be: f64) -> f64 { (A_EQ * A_EQ * be.sin().powi(2) + B_POL * B_POL * be.cos().powi(2)).sqrt() }
fn k_ell(be: f64) -> f64 { B_POL * B_POL / w(be).powi(4) } // Gaussian curvature at parametric latitude be
fn cap(be: f64) -> f64 {                                 // cap area from the pole down to latitude be
    let c = (A_EQ * A_EQ - B_POL * B_POL).sqrt();
    let g = |u: f64| u / 2.0 * (B_POL * B_POL + c * c * u * u).sqrt() + B_POL * B_POL / (2.0 * c) * (c * u / B_POL).asinh();
    2.0 * PI * A_EQ * (g(1.0) - g(be.sin()))
}

fn fly(x: f64, y: f64) -> Option<f64> {                 // flying distance from the airport at the origin
    let cx = x - D;
    let dc = cx.hypot(y);
    if dc < Z { return None; }
    let beta = (-cx / dc).max(-1.0).min(1.0).acos() - (Z / D).acos() - (Z / dc).acos();
    Some(if beta <= 0.0 { x.hypot(y) } else { (D * D - Z * Z).sqrt() + (dc * dc - Z * Z).sqrt() + Z * beta })
}

fn zone_rays(r: f64, m: usize) -> f64 {
    let mut tot = 0.0;
    for i in 0..m {
        let th = (i as f64 + 0.5) * PI / m as f64;
        if th >= (Z / D).asin() { tot += r * r / 2.0; continue; }
        let q = (Z * Z - (D * th.sin()).powi(2)).sqrt();
        let (t1, t2) = (D * th.cos() - q, D * th.cos() + q);
        if r <= t1 { tot += r * r / 2.0; continue; }
        tot += t1 * t1 / 2.0;
        let (mut lo, mut hi) = (t2 * 1.000001, r);
        if lo >= r || fly(lo * th.cos(), lo * th.sin()).unwrap() > r { continue; }
        for _ in 0..60 {
            let mid = (lo + hi) / 2.0;
            if fly(mid * th.cos(), mid * th.sin()).unwrap() <= r { lo = mid; } else { hi = mid; }
        }
        tot += (lo * lo - t2 * t2) / 2.0;
    }
    2.0 * tot * PI / m as f64
}

fn zone_grid(r: f64, cell: f64) -> f64 {
    let n = (r / cell) as i64 + 1;
    let mut cnt = 0u64;
    for i in -n..n {
        for j in 0..n {
            let (x, y) = ((i as f64 + 0.5) * cell, (j as f64 + 0.5) * cell);
            if x * x + y * y > r * r { continue; }
            if let Some(d) = fly(x, y) { if d <= r { cnt += 1; } }
        }
    }
    2.0 * cnt as f64 * cell * cell
}

fn s3_ball(r: f64, rr: f64) -> f64 { PI * rr * rr * (2.0 * r - rr * (2.0 * r / rr).sin()) }
fn s3_shells(r: f64, rr: f64, n: usize) -> f64 {           // 3D ball as a sum of shells 4 pi sn^2 ds
    (0..n).map(|i| 4.0 * PI * (rr * ((i as f64 + 0.5) * r / n as f64 / rr).sin()).powi(2) * r / n as f64).sum()
}

fn join(v: &[f64], p: usize) -> String { v.iter().map(|q| format!("{:.*}", p, q)).collect::<Vec<_>>().join(" ") }

fn main() {
    // ---- 1. the globe: ball of 1,000 km, two roads, and the ratio against flat ----
    let (g1000, j1000) = (globe(1000.0, R), jacobi_area(1.0 / (R * R), 1000.0, 100));
    println!("globe ball r=1000 km   closed {:.1}   Jacobi RK4 {:.1}   flat {:.1}", g1000, j1000, flat(1000.0));
    println!("r/R {:.6}   cos(r/R) {:.6}   2 pi R^2 {:.1}", 1000.0 / R, (1000.0 / R).cos(), 2.0 * PI * R * R);
    println!("shortfall {:.1} km2   1-cos(r/R) {:.9}", flat(1000.0) - g1000, 1.0 - (1000.0 / R).cos());
    let radii = [1000.0, 2000.0, 5000.0, 10000.0, 15000.0, PI * R];
    let ratios: Vec<f64> = radii.iter().map(|&r| globe(r, R) / flat(r)).collect();
    println!("ratio area/(pi r^2) at r = 1000 2000 5000 10000 15000 piR={:.2}: {}", PI * R, join(&ratios, 6));
    println!("doubling: area(2000)/area(1000) = {:.6}  (Ric >= 0 caps it at 4)", globe(2000.0, R) / g1000);

    // ---- 2. the flattened Earth, ball round the North Pole: polar caps ----
    let (kmin, kmax) = (k_ell(PI / 2.0), k_ell(0.0));
    let rho = 1.0 / kmin.sqrt();                        // radius of the least curved comparison sphere
    let (mut y, h, mut ok) = (vec![PI / 2.0, 0.0, 1.0, 0.0], 1.0, true); // beta, Jacobi f, f', area
    let (mut prev_ratio, mut prev_dens, mut prev_m, mut worst) = (1.0, 1.0, f64::NAN, 0.0f64);
    let mut rows: Vec<[f64; 9]> = Vec::new();
    for i in 1..=5000 {
        y = rk4(|z| vec![-1.0 / w(z[0]), z[2], -k_ell(z[0]) * z[1], 2.0 * PI * z[1]], &y, h);
        let s = i as f64 * h;
        let (be, f, fp, area) = (y[0], y[1], y[2], y[3]);
        let sk = kmin.sqrt();
        let (m, m_model) = (fp / f, sk / ((sk * s).sin() / (sk * s).cos()));
        let dens = f / ((sk * s).sin() / sk);
        if !prev_m.is_nan() && s > 500.0 {              // Riccati: m' + m^2 = -K, m' by a difference quotient
            let (mid_m, mid_k) = ((m + prev_m) / 2.0, k_ell(be + h / (2.0 * w(be))));
            worst = worst.max(((m - prev_m) / h + mid_m * mid_m + mid_k).abs() / mid_k);
        }
        prev_m = m;
        ok = ok && m <= m_model + 1e-12 && dens <= prev_dens + 1e-12;
        prev_dens = dens;
        if i % 1000 == 0 {
            let ratio = area / globe(s, rho);
            ok = ok && ratio <= prev_ratio + 1e-12;
            prev_ratio = ratio;
            if i == 1000 { println!("pole r=1000  m = f'/f {:.9}  model {:.9}  flat 1/r {:.9}", m, m_model, 1.0 / s); }
            rows.push([s, A_EQ * be.cos(), f, cap(be), area, globe(s, rho), globe(s, R), ratio, area / flat(s)]);
        }
    }
    for r in &rows {
        println!("pole r={:5.0}  f geom {:.6}  f Jacobi {:.6}  area cap {:.1}  Jacobi {:.1}", r[0], r[1], r[2], r[3], r[4]);
        println!("           model rho {:.1}  globe 6371 {:.1}  area/model {:.9}  area/flat {:.6}", r[5], r[6], r[7], r[8]);
    }
    println!("Riccati m' + m^2 + K, worst relative error {:.9}", worst);
    println!("sphere of radius b = {:.3} km, ball r=1000: {:.1}  (below the pole's ball)", B_POL, globe(1000.0, B_POL));
    println!("comparison radius rho = a^2/b = {:.3} km   pinching Kmin/Kmax = {:.6}", rho, kmin / kmax);

    // ---- 3. what breaks: the saddle (Ric < 0), the no-fly zone (not complete), a 3D slip ----
    let behind = 2.0 * (D * D - Z * Z).sqrt() + Z * PI / 3.0; // two tangents and a 60-degree arc
    println!("point 1200 km east, behind the zone: by air {:.3} km, by hand {:.3} km", fly(1200.0, 0.0).unwrap(), behind);
    let zr: Vec<f64> = [300.0, 500.0, 700.0, 900.0, 1200.0, 2000.0].iter().map(|&r| zone_rays(r, 4000) / flat(r)).collect();
    let zg: Vec<f64> = [700.0, 2000.0].iter().map(|&r| zone_grid(r, 5.0) / flat(r)).collect();
    println!("no-fly zone ratio at r = 300 500 700 900 1200 2000: {}", join(&zr, 4));
    println!("  grid count at 700 and 2000: {:.4} {:.4}", zg[0], zg[1]);
    let zmin = (60..=100).map(|i| 10.0 * i as f64).map(|r| (zone_rays(r, 4000) / flat(r), r)).fold((f64::INFINITY, 0.0), |a, b| if b.0 < a.0 { b } else { a });
    let zgm = zone_grid(zmin.1, 5.0) / flat(zmin.1);
    println!("  lowest ratio, r = 600 to 1000 km in 10 km steps: {:.4} at {:.0} km, grid count {:.4}", zmin.0, zmin.1, zgm);
    let sj: Vec<f64> = [1000.0, 3000.0].iter().map(|&r| jacobi_area(-1.0 / (R * R), r, 300) / flat(r)).collect();
    println!("saddle ratio at 1000 and 3000: {:.6} {:.6}   Jacobi RK4 {:.6} {:.6}", saddle(1000.0) / flat(1000.0), saddle(3000.0) / flat(3000.0), sj[0], sj[1]);
    let (true3, wrong3) = (s3_ball(1000.0, R), s3_ball(1000.0, R / 2f64.sqrt()));
    println!("3D globe ball r=1000: true {:.0} km3, model read as k=2/R^2 gives {:.0}", true3, wrong3);
    let chart_r: Vec<f64> = (1..=12).map(|i| 250.0 * i as f64).collect();
    println!("chart r: {}", join(&chart_r, 0));
    println!("chart globe: {}", join(&chart_r.iter().map(|&r| globe(r, R) / flat(r)).collect::<Vec<_>>(), 4));
    println!("chart saddle: {}", join(&chart_r.iter().map(|&r| saddle(r) / flat(r)).collect::<Vec<_>>(), 4));
    println!("chart no-fly: {}", join(&chart_r.iter().map(|&r| zone_rays(r, 2000) / flat(r)).collect::<Vec<_>>(), 4));

    assert!((j1000 - g1000).abs() < 1e-3, "Jacobi-built area must match the closed form");
    assert!((flat(1000.0) - g1000 - 6444.6).abs() < 0.1, "shortfall agrees with the Ricci card");
    assert!(ratios.windows(2).all(|p| p[0] > p[1]), "Ric >= 0: the ratio only falls");
    assert!(worst < 1e-3, "the mean curvature of the circles obeys the Riccati equation");
    assert!(ok, "Riccati bound m <= model, density ratio and volume ratio never rise");
    assert!(rows.iter().all(|r| (r[1] - r[2]).abs() < 1e-6), "circle radius: geometry and Jacobi agree");
    assert!(rows.iter().all(|r| (r[3] - r[4]).abs() < 1e-3), "ball area: closed form and Jacobi agree");
    assert!(rows.iter().all(|r| r[4] <= r[5]), "Bishop: no bigger than the comparison sphere");
    assert!(globe(1000.0, B_POL) < rows[0][4], "the most curved sphere is not a valid upper bound");
    assert!((zr[2] - zg[0]).abs() < 2e-3 && (zr[5] - zg[1]).abs() < 2e-3 && (zmin.0 - zgm).abs() < 2e-3, "rays and grid agree");
    assert!((fly(1200.0, 0.0).unwrap() - behind).abs() < 1e-9, "wrap-around distance against the hand formula");
    assert!(zmin.0 < zr[2] && zr[2] < zr[3], "no-fly zone: the ratio falls past 700 km, then rises, so completeness was needed");
    assert!(saddle(1000.0) > flat(1000.0), "saddle: Ric < 0 lets the ball beat flat");
    assert!(sj.iter().zip([1000.0, 3000.0]).all(|(q, r)| (q - saddle(r) / flat(r)).abs() < 1e-9), "saddle: Jacobi-built area matches the closed form");
    assert!((ratios[5] - 4.0 / (PI * PI)).abs() < 1e-12, "whole globe: 4 pi R^2 over pi (pi R)^2 is 4/pi^2");
    assert!([R, R / 2f64.sqrt()].iter().all(|&q| (s3_shells(1000.0, q, 2000) / s3_ball(1000.0, q) - 1.0).abs() < 1e-6), "3D ball: shells against closed form");
    assert!(wrong3 < true3, "3D slip: the misread model is smaller than the true ball");
    println!("ALL CHECKS PASS");
}
