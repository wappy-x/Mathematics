// Green's function and the representation formula -- the same check as greens_functions_and_the_representation_formula_check.py, in Rust.
// A 1 m concrete cube: top face on a hot plate at 80 C, the other five faces at 20 C,
// a 20 W heater inside at a, a sensor at b.  Standard library only, no crates.
// Road 1: G and the wall weights as sine-sinh series (the closed form).
// Road 2: G = Phi - h, the corrector h solved on a grid by SOR, never using the series.
// Road 3: exact facts: the centre weighs each face 1/6; all weights add to 1.
use std::f64::consts::PI;
type P3 = [f64; 3];

fn g_series(x: P3, y: P3, n: usize) -> f64 { // unit poke at y, walls at 0, read at x
    let (zl, zh) = (x[2].min(y[2]), x[2].max(y[2]));
    let mut tot = 0.0;
    for l in 1..=n {
        for m in 1..=n {
            let (lf, mf) = (l as f64, m as f64);
            let be = PI * (lf * lf + mf * mf).sqrt();
            tot += 4.0 * (lf * PI * x[0]).sin() * (lf * PI * y[0]).sin() * (mf * PI * x[1]).sin() * (mf * PI * y[1]).sin()
                * (be * zl).sinh() * (be * (1.0 - zh)).sinh() / (be * be.sinh());
        }
    }
    tot
}
fn w_top(x: P3, n: usize) -> f64 { // weight of the face z = 1 at x: the integral of P = -dG/dn over it
    let mut tot = 0.0;
    for l in (1..=n).step_by(2) {
        for m in (1..=n).step_by(2) {
            let (lf, mf) = (l as f64, m as f64);
            let be = PI * (lf * lf + mf * mf).sqrt();
            let ratio = ((be * (x[2] - 1.0)).exp() - (-be * (x[2] + 1.0)).exp()) / (1.0 - (-2.0 * be).exp());
            tot += 16.0 / (PI * PI * lf * mf) * (lf * PI * x[0]).sin() * (mf * PI * x[1]).sin() * ratio;
        }
    }
    tot
}
fn weights(x: P3, n: usize) -> Vec<f64> { // all six faces, by turning the cube so each face is on top
    let [a, b, c] = x;
    [[a, b, c], [a, b, 1.0 - c], [b, c, a], [b, c, 1.0 - a], [a, c, b], [a, c, 1.0 - b]].iter().map(|p| w_top(*p, n)).collect()
}
fn sor(n: usize, bc: &dyn Fn(f64, f64, f64) -> f64) -> Vec<f64> { // Laplace on the grid, wall values bc
    let (mm, nf) = (n + 1, n as f64);
    let om = 2.0 / (1.0 + (PI / nf).sin());
    let mut u = vec![0.0; mm * mm * mm];
    for i in 0..mm { for j in 0..mm { for k in 0..mm {
        if i == 0 || j == 0 || k == 0 || i == n || j == n || k == n {
            u[(i * mm + j) * mm + k] = bc(i as f64 / nf, j as f64 / nf, k as f64 / nf);
        }
    } } }
    for _ in 0..15 * n { for i in 1..n { for j in 1..n { for k in 1..n {
        let p = (i * mm + j) * mm + k;
        let s = u[p - mm * mm] + u[p + mm * mm] + u[p - mm] + u[p + mm] + u[p - 1] + u[p + 1];
        u[p] += om * (s / 6.0 - u[p]);
    } } } }
    u
}
fn at(u: &[f64], n: usize, x: P3) -> f64 {
    let (mm, nf) = (n + 1, n as f64);
    let r = |v: f64| (v * nf).round() as usize;
    u[(r(x[0]) * mm + r(x[1])) * mm + r(x[2])]
}
fn phi(x: P3, y: P3) -> f64 {
    let mut s = 0.0;
    for i in 0..3 { s += (x[i] - y[i]) * (x[i] - y[i]); }
    1.0 / (4.0 * PI * s.sqrt())
}
fn sci(v: f64, d: usize) -> String { // Python-style e-notation: two-digit exponent
    let s = format!("{:.*e}", d, v);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn f6(w: &[f64]) -> String { w.iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(" ") }
fn main() {
    let (q, kc, hot, cold) = (20.0_f64, 1.4_f64, 80.0_f64, 20.0_f64);
    let (a, b, c): (P3, P3, P3) = ([0.2, 0.3, 0.4], [0.5, 0.5, 0.8], [0.5, 0.5, 0.5]);
    println!("box 1 m cube; plate {:.0} C on top, {:.0} C on five faces; heater {:.0} W at a = (0.2, 0.3, 0.4) m, sensor b = (0.5, 0.5, 0.8) m, k = {} W/(m K)", hot, cold, q, kc);
    let (wc, wb) = (weights(c, 81), weights(b, 81));
    let sum = |w: &[f64]| w.iter().fold(0.0, |s, v| s + v);
    let one_term = 16.0 / (PI * PI) * (PI * 2f64.sqrt() / 2.0).sinh() / (PI * 2f64.sqrt()).sinh();
    println!("face weights at centre c  (top, bottom, x=1, x=0, y=1, y=0): {}", f6(&wc));
    println!("  sum {:.6}; one-term top weight 16/pi^2 sinh(pi sqrt2/2)/sinh(pi sqrt2) = {:.6}", sum(&wc), one_term);
    println!("face weights at sensor b  (top, bottom, x=1, x=0, y=1, y=0): {}", f6(&wb));
    println!("  sum {:.6}; first omitted term (l = 1, m = 83) {}", sum(&wb),
             sci(16.0 / (PI * PI * 83.0) * (-0.2 * PI * (1.0 + 83.0 * 83.0_f64).sqrt()).exp(), 1));
    for (name, w) in [("centre c", &wc), ("sensor b", &wb)] {
        println!("walls alone at {}: 20 + 60 x {:.6} = {:.4} C; sum of weight x wall temp = {:.4} C",
                 name, w[0], cold + (hot - cold) * w[0], hot * w[0] + cold * sum(&w[1..]));
    }
    println!("bars, weight at b in % : {}", wb.iter().map(|w| format!("{:.1}", 100.0 * w)).collect::<Vec<_>>().join(" "));
    let s80: Vec<(f64, f64)> = (0..81).map(|i| (i as f64 / 80.0, (if i == 0 || i == 80 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) / 240.0)).collect();
    let hn = 1e-4; // the wall weight -dG/dn from G itself: G = 0 on the face, so -dG/dn ~ G(b, y)/hn just inside
    let mut w_from_g = 0.0;
    for &(s1, w1) in &s80 { for &(t1, w2) in &s80 { w_from_g += w1 * w2 * g_series(b, [s1, t1, 1.0 - hn], 40); } }
    w_from_g /= hn;
    println!("top weight at b from G itself (Simpson 80 x 80 over the face, slope from 1e-4 m inside): {:.6}; series {:.6}", w_from_g, wb[0]);
    let (g40, g20, gs_ab) = (g_series(b, a, 40), g_series(b, a, 20), g_series(a, b, 40));
    println!("Phi(b - a) = 1/(4 pi |b - a|) = {:.6} 1/m, |b - a| = {:.6} m", phi(a, b), 0.29_f64.sqrt());
    println!("series G(b, a) N = 40: {:.6} 1/m; N = 20 differs by {}; corrector h_a(b) = {:.6}", g40, sci((g40 - g20).abs(), 1), phi(a, b) - g40);
    let walls_b = cold + (hot - cold) * wb[0];
    let mut grid = Vec::new();
    for n in [10usize, 20] {
        let ha = sor(n, &|x, y, z| phi([x, y, z], a));
        let hb = sor(n, &|x, y, z| phi([x, y, z], b));
        let uw = sor(n, &|_x, _y, z| if z == 1.0 { hot } else { cold });
        let row = (phi(a, b) - at(&ha, n, b), phi(a, b) - at(&hb, n, a), at(&uw, n, b), at(&uw, n, c));
        println!("grid step {:.2} m: G(b, a) = {:.6}, G(a, b) = {:.6}, walls at b {:.4} C, at c {:.4} C", 1.0 / n as f64, row.0, row.1, row.2, row.3);
        grid.push(row);
    }
    let (e10, e20) = ((grid[0].0 - g40).abs(), (grid[1].0 - g40).abs());
    let (rich_ba, rich_ab) = ((4.0 * grid[1].0 - grid[0].0) / 3.0, (4.0 * grid[1].1 - grid[0].1) / 3.0);
    println!("grid error in G(b, a): {} at step 0.1 m, {} at step 0.05 m, observed order {:.2}", sci(e10, 2), sci(e20, 2), (e10 / e20).ln() / 2f64.ln());
    println!("grid error in walls at b: {:.4} C at step 0.1 m, {:.4} C at step 0.05 m", (grid[0].2 - walls_b).abs(), (grid[1].2 - walls_b).abs());
    println!("extrapolated (4 G_fine - G_coarse)/3: G(b, a) = {:.6}, G(a, b) = {:.6}; series G(a, b) = {:.6}", rich_ba, rich_ab, gs_ab);
    let rise = q / kc * g40;
    println!("heater rise at b = (Q/k) G(b, a) = {:.4} x {:.6} = {:.4} C", q / kc, g40, rise);
    println!("sensor reading at b = {:.4} + {:.4} = {:.4} C", walls_b, rise, walls_b + rise);
    println!("swap heater and sensor: rise at a from the heater at b = {:.4} C", q / kc * gs_ab);
    // ---- Green's identities on u = x^2 y + z, v = x y z + y^2, by Simpson (exact for cubics) ----
    let s: Vec<(f64, f64)> = (0..5).map(|i| (i as f64 / 4.0, (if i == 0 || i == 4 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) / 12.0)).collect();
    let vol = |f: &dyn Fn(P3) -> f64| { let mut t = 0.0;
        for &(x, wx) in &s { for &(y, wy) in &s { for &(z, wz) in &s { t += wx * wy * wz * f([x, y, z]); } } } t };
    let wall = |f: &dyn Fn(P3, P3) -> f64| { let mut t = 0.0;
        for ax in 0..3 { for (side, nrm) in [(0.0, -1.0), (1.0, 1.0)] { for &(p1, w1) in &s { for &(p2, w2) in &s {
            let mut p = vec![p1, p2]; p.insert(ax, side); let mut nv = [0.0; 3]; nv[ax] = nrm;
            t += w1 * w2 * f([p[0], p[1], p[2]], nv); } } } } t };
    let u = |p: P3| p[0] * p[0] * p[1] + p[2];
    let gu = |p: P3| [2.0 * p[0] * p[1], p[0] * p[0], 1.0];
    let lu = |p: P3| 2.0 * p[1];
    let v = |p: P3| p[0] * p[1] * p[2] + p[1] * p[1];
    let gv = |p: P3| [p[1] * p[2], p[0] * p[2] + 2.0 * p[1], p[0] * p[1]];
    let dot = |p: P3, r: P3| { let mut t = 0.0; for i in 0..3 { t += p[i] * r[i]; } t };
    let i1 = vol(&|p| v(p) * lu(p) + dot(gu(p), gv(p)));
    let b1 = wall(&|p, nv| v(p) * dot(gu(p), nv));
    let i2 = vol(&|p| u(p) * 2.0 - v(p) * lu(p));
    let b2 = wall(&|p, nv| u(p) * dot(gv(p), nv) - v(p) * dot(gu(p), nv));
    println!("first identity:  inside {:.6}, walls {:.6};  second identity: inside {:.6}, walls {:.6}", i1, b1, i2, b2);
    println!("mistake 1, Phi for G (no walls): rise {:.4} C, not {:.4}", q / kc * phi(a, b), rise);
    println!("mistake 2, wall term dropped: reading {:.4} C, not {:.4}", rise, walls_b + rise);
    println!("mistake 3, inward normal: walls give {:.4} C, reading {:.4} C", -walls_b, rise - walls_b);
    println!("mistake 4, insulated walls: unit poke's wall flux = -(sum of weights at a) = {:.4}, needs 0", -sum(&weights(a, 81)));
    println!("try: sensor at centre: {:.4} C; heater 40 W: rise {:.4} C; plate at 20 C: {:.4} C",
             cold + (hot - cold) * wc[0] + q / kc * g_series(c, a, 40), 2.0 * rise, cold + rise);
    let px = |p: P3| format!("({:.0},{:.0})", 60.0 + 300.0 * p[0], 360.0 - 300.0 * p[2]);
    println!("figure, side view x-z, 300 px/m, origin (60,360): heater {} sensor {} centre {}", px(a), px(b), px(c));
    assert!((wc[0] - 1.0 / 6.0).abs() < 1e-9 && (sum(&wb) - 1.0).abs() < 1e-9); // series vs exact facts
    assert!((w_from_g - wb[0]).abs() < 1e-5); // wall weight from G vs the face series
    assert!((rich_ba - g40).abs() < 2e-5 && (rich_ab - g40).abs() < 2e-5); // grid road vs series road
    assert!((grid[1].2 - walls_b).abs() < (grid[0].2 - walls_b).abs() && (grid[0].2 - walls_b).abs() < 0.5);
    assert!((i1 - b1).abs() < 1e-12 && (i2 - b2).abs() < 1e-12 && i1.abs() > 0.1); // identities, both sides
    println!("ALL CHECKS PASS");
}
