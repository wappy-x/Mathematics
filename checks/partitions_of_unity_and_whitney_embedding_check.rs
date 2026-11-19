// Partition of unity and Whitney embedding -- the check behind the card.  std only, no crates.
// The Earth is a sphere of radius R = 6371 km (a model), covered by six orthographic sheets.
// Each sheet drops one coordinate of space and keeps the other two; it covers the open half
// where the dropped coordinate has its sign.  A bump on each sheet glues them into one map F.
const R: f64 = 6371.0;
const C: f64 = 0.5; // a bump is on where t > C, with t = dropped coordinate / R
const W: f64 = 0.1;
const SHEETS: [(&str, usize, f64); 6] = [("North", 2, 1.0), ("South", 2, -1.0), ("Greenwich", 0, 1.0),
    ("Date line", 0, -1.0), ("East", 1, 1.0), ("West", 1, -1.0)]; // (name, dropped axis, sign)
type V = Vec<f64>;

fn f(s: f64) -> f64 { if s > 0.0 { (-1.0 / (s * s)).exp() } else { 0.0 } } // e^(-1/s^2), 0 for s <= 0
fn df(s: f64) -> f64 { if s > 0.0 { 2.0 / s.powi(3) * f(s) } else { 0.0 } }
fn tent(s: f64) -> f64 { s.max(0.0) }
fn cut(s: f64) -> f64 { if s > 0.0 { 1.0 } else { 0.0 } }
fn t_of(p: &[f64], k: usize) -> f64 { SHEETS[k].2 * p[SHEETS[k].1] / R }
fn bump_with(p: &[f64], k: usize, c: f64, prof: fn(f64) -> f64) -> f64 { prof((t_of(p, k) - c) / W) }
fn bump(p: &[f64], k: usize) -> f64 { bump_with(p, k, C, f) }
fn chart(p: &[f64], k: usize) -> V { (0..3).filter(|&j| j != SHEETS[k].1).map(|j| p[j]).collect() }
fn point(lat: f64, lon: f64) -> V {
    let (a, b) = (lat.to_radians(), lon.to_radians());
    vec![R * a.cos() * b.cos(), R * a.cos() * b.sin(), R * a.sin()]
}
fn dist(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y) * (x - y)).sum::<f64>().sqrt() }
fn sci(x: f64) -> String { // Python's {:.2e}: two-digit exponent
    let s = format!("{:.2e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { "-" } else { "+" }, e.abs())
}

fn embed(p: &[f64], with_bumps: bool) -> V { // F(p) = (psi_1 x_1, ..., psi_6 x_6, R psi_1, ..., R psi_6), km
    let psi: V = (0..6).map(|k| bump(p, k)).collect();
    let mut out: V = Vec::new();
    for k in 0..6 { for u in chart(p, k) { out.push(psi[k] * u); } }
    if with_bumps { for q in &psi { out.push(R * q); } }
    out
}
fn unembed(fv: &[f64]) -> V { // road 1 to "one-to-one": read p back off F(p)
    let mut k = 0;
    for i in 1..6 { if fv[12 + i] > fv[12 + k] { k = i; } }
    let x = [R * fv[2 * k] / fv[12 + k], R * fv[2 * k + 1] / fv[12 + k]];
    let (a, sg) = (SHEETS[k].1, SHEETS[k].2);
    let mut p: V = x[..a].to_vec();
    p.push(sg * (R * R - x[0] * x[0] - x[1] * x[1]).sqrt());
    p.extend_from_slice(&x[a..]);
    p
}
fn d_f(p: &[f64], v: &[f64]) -> V { // derivative of F along a tangent vector v, by the product rule
    let (mut rows, mut dpsi) = (Vec::new(), Vec::new());
    for k in 0..6 {
        let (a, sg) = (SHEETS[k].1, SHEETS[k].2);
        let s = (t_of(p, k) - C) / W;
        let dp = df(s) / W * sg * v[a] / R;
        for (u, w) in chart(p, k).iter().zip(chart(v, k)) { rows.push(dp * u + bump(p, k) * w); }
        dpsi.push(R * dp);
    }
    rows.extend(dpsi);
    rows
}
fn tangents(p: &[f64]) -> (V, V) { // two unit vectors at right angles, tangent to the globe
    let a = if p[2].abs() < 0.9 * R { [0.0, 0.0, 1.0] } else { [1.0, 0.0, 0.0] };
    let e = [a[1] * p[2] - a[2] * p[1], a[2] * p[0] - a[0] * p[2], a[0] * p[1] - a[1] * p[0]];
    let n = e.iter().map(|u| u * u).sum::<f64>().sqrt();
    let e: V = e.iter().map(|u| u / n).collect();
    let g = vec![(p[1] * e[2] - p[2] * e[1]) / R, (p[2] * e[0] - p[0] * e[2]) / R, (p[0] * e[1] - p[1] * e[0]) / R];
    (e, g)
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn min_stretch(p: &[f64]) -> f64 { // smallest stretch of dF on unit ground vectors (2x2 Gram matrix)
    let (e, g) = tangents(p);
    let (a, b) = (d_f(p, &e), d_f(p, &g));
    let (pp, q, r) = (dot(&a, &a), dot(&a, &b), dot(&b, &b));
    ((pp + r) / 2.0 - (((pp - r) / 2.0).powi(2) + q * q).sqrt()).sqrt()
}

fn main() {
    let mut grid: Vec<V> = Vec::new();
    for lat in (-80..=80).step_by(10) { for lon in (0..360).step_by(10) { grid.push(point(lat as f64, lon as f64)); } }
    grid.push(point(90.0, 0.0));
    grid.push(point(-90.0, 0.0));

    // ---- the partition of unity at London ----
    let l = point(51.5074, -0.1278);
    let psi_l: V = (0..6).map(|k| bump(&l, k)).collect();
    let tot_l: f64 = psi_l.iter().sum();
    let rho_l: V = psi_l.iter().map(|p| p / tot_l).collect();
    println!("London in space (km): {}", l.iter().map(|u| format!("{:.1}", u)).collect::<Vec<_>>().join(", "));
    for k in 0..6 {
        println!("{:<10} t = {:8.5}  s = {:8.4}  bump {:.6}  weight {:.6}", SHEETS[k].0, t_of(&l, k), (t_of(&l, k) - C) / W,
                 psi_l[k], rho_l[k]);
    }
    println!("bumps add to {:.6}; weights add to {:.12}", tot_l, rho_l.iter().sum::<f64>());
    println!("F(London), km: {}", embed(&l, true).iter().map(|u| format!("{:.1}", u + 0.0)).collect::<Vec<_>>().join(", "));
    let (la, lo) = (51.5074f64.to_radians(), (-0.1278f64).to_radians());
    let north = [-la.sin() * lo.cos(), -la.sin() * lo.sin(), la.cos()];
    let spd: V = (0..6).map(|k| chart(&north, k).iter().map(|u| u * u).sum::<f64>().sqrt()).collect();
    let glued = (0..6).map(|k| rho_l[k] * spd[k] * spd[k]).sum::<f64>().sqrt();
    println!("walking north: North sheet speed {:.4}, Greenwich {:.4}, glued ruler {:.4}", spd[0], spd[2], glued);

    // ---- every point is under some bump: grid search against the corner formula ----
    let tot: V = grid.iter().map(|p| (0..6).map(|k| bump(p, k)).sum()).collect();
    let tmin = tot.iter().cloned().fold(f64::INFINITY, f64::min);
    let corner = 3.0 * f((1.0 / 3f64.sqrt() - C) / W);
    println!("sum of bumps: grid minimum {:.6}, at the corner {:.2} N 45.00 E, t = {:.5}, total {:.6}", tmin,
             (1.0 / 3f64.sqrt()).asin().to_degrees(), 1.0 / 3f64.sqrt(), corner);
    assert!(tmin >= corner - 1e-12 && corner > 0.5);

    // ---- road 1: F is one-to-one, because p can be read back off F(p) ----
    let back = grid.iter().map(|p| dist(&unembed(&embed(p, true)), p)).fold(0.0, f64::max);
    println!("grid points {}; worst miss reading p back from F(p): {} km", grid.len(), sci(back));
    assert!(back < 1e-6);

    // ---- road 2: F is one-to-one, by brute force over every pair of grid points ----
    let fg: Vec<V> = grid.iter().map(|p| embed(p, true)).collect();
    let mut ratio = f64::INFINITY;
    for i in 0..grid.len() { for j in 0..i { ratio = ratio.min(dist(&fg[i], &fg[j]) / dist(&grid[i], &grid[j])); } }
    println!("pairs {}; smallest (gap in F) / (gap in space): {:.4}", grid.len() * (grid.len() - 1) / 2, ratio);
    assert!(ratio > 0.1);

    // ---- F is an immersion: product rule against difference quotients, then the whole grid ----
    let (e, _g) = tangents(&l);
    let h = 1.0;
    let ph: V = l.iter().zip(&e).map(|(p, u)| (h / R).cos() * p + R * (h / R).sin() * u).collect();
    let pm: V = l.iter().zip(&e).map(|(p, u)| (h / R).cos() * p - R * (h / R).sin() * u).collect();
    let num: V = embed(&ph, true).iter().zip(embed(&pm, true)).map(|(a, b)| (a - b) / (2.0 * h)).collect();
    let miss = num.iter().zip(d_f(&l, &e)).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max);
    println!("London: product rule vs difference quotient, worst entry miss {}", sci(miss));
    assert!(miss < 1e-6);
    let st = grid.iter().map(|p| min_stretch(p)).fold(f64::INFINITY, f64::min);
    println!("smallest stretch of dF: at London {:.4}, over the grid {:.4}", min_stretch(&l), st);
    assert!(st > 0.1);

    // ---- what breaks ----
    let (np, sp) = (vec![0.0, 0.0, R], vec![0.0, 0.0, -R]);
    println!("poles apart in F: with bump entries {:.6}, without {:.6}",
             dist(&embed(&np, true), &embed(&sp, true)), dist(&embed(&np, false), &embed(&sp, false)));
    assert!(dist(&embed(&np, false), &embed(&sp, false)) == 0.0);
    println!("bumps start at t > 0.6: sum at the corner {:.6}", 3.0 * f((1.0 / 3f64.sqrt() - 0.6) / W));
    let profs: [(fn(f64) -> f64, &str); 3] = [(f, "e^(-1/s^2)"), (tent, "tent"), (cut, "hard cut")];
    for (prof, name) in profs {
        let at = |lat: f64| bump_with(&point(lat, 0.0), 0, C, prof);
        let step = 1.0 / R * 180.0 / 3.141592653589793; // 1 km of ground, in degrees
        println!("{:<10} North bump slope at 30 N, per 1000 km: below {:.4}, above {:.4}", name,
                 1000.0 * (at(30.0) - at(30.0 - step)), 1000.0 * (at(30.0 + step) - at(30.0)));
    }

    // ---- the chart along the Greenwich meridian, and the figure ----
    let lats: Vec<i32> = (-90..=90).step_by(10).collect();
    println!("latitude   {}", lats.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "));
    for (k, name) in [(1, "South"), (2, "Greenwich"), (0, "North")] {
        let w: Vec<String> = lats.iter().map(|&lat| {
            let p = point(lat as f64, 0.0);
            format!("{:.2}", bump(&p, k) / (0..6).map(|j| bump(&p, j)).sum::<f64>())
        }).collect();
        println!("{:<10} {}", name, w.join(", "));
    }
    let px = |p: &[f64], r: f64| (220.0 + p[0] / R * r, 220.0 - p[2] / R * r); // globe circle r = 160 px; arcs drawn outside it
    let (a, b, c) = (px(&l, 160.0), px(&point(30.0, 0.0), 176.0), px(&point(60.0, 0.0), 192.0));
    let (d, e) = (px(&point(30.0, 0.0), 205.0), px(&point(60.0, 0.0), 205.0));
    println!("figure, London px ({:.1}, {:.1}); North arc (r 176) right end ({:.1}, {:.1}); Greenwich arc (r 192) top end ({:.1}, {:.1}); 30 N and 60 N rays (r 205) end ({:.1}, {:.1}), ({:.1}, {:.1})",
             a.0, a.1, b.0, b.1, c.0, c.1, d.0, d.1, e.0, e.1);
    println!("ALL CHECKS PASS");
}
