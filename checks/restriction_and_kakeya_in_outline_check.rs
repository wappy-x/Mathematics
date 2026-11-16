// Restriction and Kakeya in outline: the check behind the card. std only.
// A 343 Hz tone in air has wavelength 1 m, so its spectrum lies on the circle of
// radius 1 cycle per metre. Every circle integral and every area is computed here.
use std::f64::consts::PI;

// Eg(x) = integral over the arc lo..hi of exp(2 pi i x.w) d(arc), g = 1, midpoint rule
fn ext(x1: f64, x2: f64, lo: f64, hi: f64, m: usize) -> (f64, f64) {
    let h = (hi - lo) / m as f64;
    let (mut re, mut im) = (0.0, 0.0);
    for k in 0..m {
        let p = lo + (k as f64 + 0.5) * h;
        let a = 2.0 * PI * (x1 * p.cos() + x2 * p.sin());
        re += a.cos(); im += a.sin();
    }
    (re * h, im * h)
}

fn circle(r: f64) -> f64 { // whole circle, g = 1: real by symmetry
    ext(r, 0.0, 0.0, 2.0 * PI, (8.0 * r) as usize + 64).0
}
fn j0_series(z: f64) -> f64 { // J0(z) = sum (-1)^k (z/2)^(2k) / (k!)^2
    let (mut term, mut s, mut k) = (1.0f64, 1.0f64, 1.0f64);
    while term.abs() > 1e-18 { term *= -(z * z / 4.0) / (k * k); s += term; k += 1.0; }
    s
}

fn asym(r: f64) -> f64 { // large r: 2 pi J0(2 pi r) is about (2 / sqrt r)(cos u + sin u / (16 pi r)), u = 2 pi r - pi/4
    let u = 2.0 * PI * r - PI / 4.0;
    2.0 * (u.cos() + u.sin() / (16.0 * PI * r)) / r.sqrt()
}
fn hyp(z: (f64, f64)) -> f64 { z.0.hypot(z.1) }
fn join(v: Vec<String>) -> String { v.join(", ") }

// flat segment w = (1, s), |s| <= delta: no curvature
fn flat(x1: f64, x2: f64, d: f64, m: usize) -> f64 {
    let (mut re, mut im) = (0.0, 0.0);
    for k in 0..m {
        let a = 2.0 * PI * (x1 + x2 * (-d + (k as f64 + 0.5) * 2.0 * d / m as f64));
        re += a.cos(); im += a.sin();
    }
    re.hypot(im) * 2.0 * d / m as f64
}

// needle bound in the plane: N tubes 1 by 1/N, directions k pi / N
fn overlap_total(n: usize) -> f64 { // N delta + sum over pairs of delta^2 / sin(angle)
    let dl = 1.0 / n as f64;
    let s: f64 = (1..n).map(|m| 1.0 / (PI * m as f64 / n as f64).sin()).sum();
    n as f64 * dl + n as f64 * dl * dl * s
}

fn shoelace(p: &[(f64, f64)]) -> f64 {
    let n = p.len();
    let s: f64 = (0..n).map(|i| { let j = (i + n - 1) % n; p[i].0 * p[j].1 - p[j].0 * p[i].1 }).sum();
    s.abs() / 2.0
}

fn main() {
    println!("circle field Eg(r), g = 1 on the whole circle");
    for r in [0.0, 0.25, 0.5, 1.0, 2.0] {
        let (q, s) = (circle(r), 2.0 * PI * j0_series(2.0 * PI * r));
        assert!((q - s).abs() < 1e-9);
        println!("r={} m: quadrature {:.6}, Bessel series {:.6}", r, q, s);
    }
    for r in [10.3, 50.3] {
        let q = circle(r);
        assert!((q - asym(r)).abs() < 1e-4);
        println!("r={} m: quadrature {:.6}, large-r formula {:.6}, envelope 2/sqrt(r) {:.6}", r, q, asym(r), 2.0 / r.sqrt());
    }
    let rs: Vec<f64> = (1..21).map(|i| 0.25 * i as f64).collect();
    println!("chart r: {}", join(rs.iter().map(|r| format!("{}", r)).collect()));
    println!("chart Eg: {}", join(rs.iter().map(|&r| format!("{:.3}", circle(r))).collect()));
    println!("chart envelope 2/sqrt(r): {}", join(rs.iter().map(|r| format!("{:.3}", 2.0 / r.sqrt())).collect()));

    // integral over the disc of radius R of |Eg|^p, Simpson in r with step 1/128 m
    let (n_per, r_max) = (128usize, 64usize);
    let h = 1.0 / n_per as f64;
    let vals: Vec<f64> = (0..=r_max * n_per).map(|i| if i > 0 { circle(i as f64 * h) } else { 2.0 * PI }).collect();
    let (ps, rr) = ([3.0f64, 4.0, 5.0, 6.0], [8usize, 16, 32, 64]);
    let mut lp = [[0.0f64; 4]; 4];
    for (pi_, &p) in ps.iter().enumerate() {
        let mut s = 0.0;
        for (i, v) in vals.iter().enumerate() {
            let f = v.abs().powf(p) * 2.0 * PI * i as f64 * h;
            if i > 0 && i % (8 * n_per) == 0 {
                if let Some(k) = rr.iter().position(|&r| r == i / n_per) { lp[pi_][k] = (s + f) * h / 3.0; }
            }
            s += f * if i == 0 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 };
        }
    }
    for (pi_, p) in ps.iter().enumerate() {
        println!("p={}: {}", p, join((0..4).map(|k| format!("R={} {:.1}", rr[k], lp[pi_][k])).collect()));
    }
    let grow: Vec<f64> = (0..3).map(|k| lp[1][k + 1] - lp[1][k]).collect();
    let c = 12.0 * PI * 2f64.ln();
    println!("p=4 gain per doubling of R: {} | 12 pi ln 2 = {:.2}", join(grow.iter().map(|g| format!("{:.2}", g)).collect()), c);
    assert!(grow[0] > grow[1] && grow[1] > grow[2] && grow[2] > c && c > grow[2] - 0.1);
    let tails = [lp[3][2] + 40.0 * PI / 32.0, lp[3][3] + 40.0 * PI / 64.0]; // p=6 tail beyond R
    assert!((tails[0] - tails[1]).abs() < 0.05);
    println!("p=6 plus tail 40 pi/R: R=32 {:.1}, R=64 {:.1}", tails[0], tails[1]);
    let ratio = (lp[0][3] / lp[0][2]).powi(2);
    assert!((ratio - 2.0).abs() < 0.05);
    println!("p=3 growth: (I(64)/I(32))^2 = {:.3}, like sqrt(R)", ratio);

    // a cap of half-width delta = 0.1 rad around the direction (1, 0): a beam
    let d = 0.1;
    let mut along = Vec::new();
    for x in [0.0, 25.0, 50.0, 100.0, 200.0, 400.0] {
        let v = hyp(ext(x, 0.0, -d, d, 2000));
        assert!((v - hyp(ext(x, 0.0, -d, d, 4000))).abs() < 1e-6);
        along.push((x, v));
    }
    println!("beam along the axis: {}", join(along.iter().map(|(x, v)| format!("{} m {:.4}", x, v)).collect()));
    let mut across = Vec::new();
    for y in [0.0, 2.5, 5.0, 7.5, 10.0] {
        let v = hyp(ext(0.0, y, -d, d, 2000));
        let u = 2.0 * PI * d * y;
        let small = 2.0 * d * if u != 0.0 { (u.sin() / u).abs() } else { 1.0 };
        assert!((v - small).abs() < 1e-3);
        across.push(format!("{} m {:.4} (small-angle {:.4})", y, v, small));
    }
    println!("beam across the axis: {}", join(across));
    let fl = [flat(200.0, 0.0, d, 2000), flat(400.0, 0.0, d, 2000)];
    assert!((flat(400.0, 2.5, d, 2000) - 2.0 * d * (5.0 * PI * d).sin() / (5.0 * PI * d)).abs() < 1e-6 && along[4].1 < 0.1); // off axis: 2 delta sinc(2 delta x2)
    println!("flat segment along the axis: 200 m {:.4}, 400 m {:.4}", fl[0], fl[1]);
    println!("try delta=0.05: across 10 m {:.4}, along 400 m {:.4}", hyp(ext(0.0, 10.0, -0.05, 0.05, 2000)), hyp(ext(400.0, 0.0, -0.05, 0.05, 2000)));
    for p in [5.0f64, 6.0] {
        let v: Vec<String> = [0.1f64, 0.01, 0.001].iter()
            .map(|e| format!("delta={} {:.3}", e, (2.0 * e).powf(0.5) * e.powf(-3.0 / p))).collect();
        println!("Knapp ratio (2 delta)^(1/2) delta^(-3/{}) at L2 data: {}", p, join(v));
    }

    for n in [10usize, 100, 1000, 10000] {
        let s = overlap_total(n);
        println!("N={}: S_N {:.4}, union at least 1/S_N = {:.4}, 1 + (2/pi) ln N = {:.4}", n, s, 1.0 / s, 1.0 + 2.0 / PI * (n as f64).ln());
    }
    let inv: Vec<f64> = (1..10).map(|m| 1.0 / (PI * m as f64 / 10.0).sin()).collect();
    println!("S_10 terms 1/sin(m pi/10), m=1..5: {} | sum m=1..9 {:.4}", join(inv[..5].iter().map(|v| format!("{:.4}", v)).collect()), inv.iter().sum::<f64>());
    let (n, g) = (10usize, 440usize);
    let cell = 1.1 / g as f64;
    let dirs: Vec<(f64, f64)> = (0..n).map(|k| { let t = PI * k as f64 / n as f64; (t.cos(), t.sin()) }).collect();
    let (mut cover, mut squares) = (0usize, 0usize);
    for i in 0..g {
        let x = -0.55 + (i as f64 + 0.5) * cell;
        for j in 0..g {
            let y = -0.55 + (j as f64 + 0.5) * cell;
            let m = dirs.iter().filter(|(c, s)| (x * c + y * s).abs() <= 0.5 && (y * c - x * s).abs() <= 0.05).count();
            if m > 0 { cover += 1; }
            squares += m * m;
        }
    }
    let (cover, squares) = (cover as f64 * cell * cell, squares as f64 * cell * cell);
    assert!((squares - overlap_total(10)).abs() < 0.01 && cover >= 1.0 / overlap_total(10));
    println!("bush of 10 tubes on a grid: union {:.3}, sum of overlaps {:.3}", cover, squares);

    // Kakeya needle problem: areas in which a unit needle turns round
    let side = 2.0 / 3f64.sqrt();
    let tri = shoelace(&[(0.0, 0.0), (side, 0.0), (side / 2.0, 1.0)]);
    let (kk, a) = (4000usize, 0.25);
    let pts: Vec<(f64, f64)> = (0..kk).map(|k| { let t = 2.0 * PI * k as f64 / kk as f64;
        (2.0 * a * t.cos() + a * (2.0 * t).cos(), 2.0 * a * t.sin() - a * (2.0 * t).sin()) }).collect();
    let delt = shoelace(&pts);
    let gt = (0..997).flat_map(|i| (0..997).map(move |j| (i, j))).filter(|&(i, j)| { let x = (i as f64 + 0.5) * side / 997.0; (j as f64 + 0.5) / 997.0 <= 3f64.sqrt() * x.min(side - x) }).count() as f64 * side / (997.0 * 997.0); // grid count
    assert!((tri - gt).abs() < 1e-5 && (delt - PI / 8.0).abs() < 1e-6);
    println!("needle areas: disc {:.6}, triangle {:.6} (1/sqrt3 {:.6}), deltoid {:.6} (pi/8 {:.6})",
        PI / 4.0, tri, 1.0 / 3f64.sqrt(), delt, PI / 8.0);
    for (dim, p) in [(2.0f64, 4.0f64), (2.0, 6.0), (3.0, 3.0), (3.0, 3.5), (3.0, 4.0)] {
        println!("restriction at p={} in dimension {}: Kakeya dimension at least {:.3}", p, dim, 2.0 * p / (p - 2.0) - dim);
    }
    println!("ALL CHECKS PASS");
}
