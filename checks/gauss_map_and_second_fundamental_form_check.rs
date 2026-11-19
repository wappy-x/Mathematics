// Gauss map and second fundamental form -- the check behind the card.  std only, no crates.
// Roof: the saddle middle, z = 30 + (u^2 - v^2)/120 m (plan chart), the same saddle in the
// seam chart u = p + q, v = p - q, and the dome over the east end, a sphere of radius 60 m.
use std::f64::consts::PI;
type V = [f64; 3];
type Chart = fn(f64, f64) -> V;
type M2 = [[f64; 2]; 2];
const R: f64 = 60.0;

fn plan(u: f64, v: f64) -> V { [u, v, 30.0 + (u * u - v * v) / 120.0] }
fn seam(p: f64, q: f64) -> V { [p + q, p - q, 30.0 + p * q / 30.0] }
fn dome(f: f64, t: f64) -> V { [R * f.sin() * t.cos(), R * f.sin() * t.sin(), R * f.cos()] }
fn barrel(u: f64, v: f64) -> V { [R * (u / R).sin(), v, R * (u / R).cos()] } // a barrel vault, for "try"
fn ridge(u: f64, v: f64) -> V { [u, v, 30.0 - 0.3 * u.abs()] } // a crease, for "breaks"

fn sub(a: V, b: V) -> V { [a[0] - b[0], a[1] - b[1], a[2] - b[2]] }
fn scl(a: V, s: f64) -> V { [a[0] * s, a[1] * s, a[2] * s] }
fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn unit(a: V) -> V { scl(a, 1.0 / dot(a, a).sqrt()) }
fn up(n: V) -> V { if n[2] > 0.0 { n } else { scl(n, -1.0) } } // house rule: the normal points up

fn arrows(ch: Chart, a: f64, b: f64, h: f64) -> [V; 5] {
    // tangent arrows r_u, r_v and second derivatives r_uu, r_uv, r_vv by central differences
    let (c, pu, mu, pv, mv) = (ch(a, b), ch(a + h, b), ch(a - h, b), ch(a, b + h), ch(a, b - h));
    let (ru, rv) = (scl(sub(pu, mu), 0.5 / h), scl(sub(pv, mv), 0.5 / h));
    let ruu = scl(sub(sub(pu, c), sub(c, mu)), 1.0 / h.powi(2));
    let rvv = scl(sub(sub(pv, c), sub(c, mv)), 1.0 / h.powi(2));
    let ruv = scl(sub(sub(ch(a + h, b + h), ch(a + h, b - h)), sub(ch(a - h, b + h), ch(a - h, b - h))), 0.25 / h.powi(2));
    [ru, rv, ruu, ruv, rvv]
}
fn gauss(ch: Chart, a: f64, b: f64) -> V { let r = arrows(ch, a, b, 1e-3); up(unit(cross(r[0], r[1]))) }
fn forms(ch: Chart, a: f64, b: f64, unit_normal: bool, h: f64) -> ([f64; 3], [f64; 3]) {
    // h = 0.1 on the quadratic saddle: exact, less rounding
    let [ru, rv, ruu, ruv, rvv] = arrows(ch, a, b, h);
    let mut n = up(cross(ru, rv));
    if unit_normal { n = unit(n); }
    ([dot(ru, ru), dot(ru, rv), dot(rv, rv)], [dot(ruu, n), dot(ruv, n), dot(rvv, n)])
}
fn shape(i: [f64; 3], ii: [f64; 3]) -> M2 {
    // road 1: W = I^-1 II, written out
    let ([e, f, g], [l, m, n]) = (i, ii);
    let d = e * g - f * f;
    [[(g * l - f * m) / d, (g * m - f * n) / d], [(e * m - f * l) / d, (e * n - f * m) / d]]
}
fn weingarten(ch: Chart, a: f64, b: f64, h: f64) -> M2 {
    // road 2: how the Gauss map moves; -n_u = w11 r_u + w21 r_v
    let r = arrows(ch, a, b, 1e-3);
    let (ru, rv) = (r[0], r[1]);
    let nu = scl(sub(gauss(ch, a + h, b), gauss(ch, a - h, b)), -0.5 / h);
    let nv = scl(sub(gauss(ch, a, b + h), gauss(ch, a, b - h)), -0.5 / h);
    let (e, f, g) = (dot(ru, ru), dot(ru, rv), dot(rv, rv));
    let d = e * g - f * f;
    let col = |x: V| ((g * dot(x, ru) - f * dot(x, rv)) / d, (e * dot(x, rv) - f * dot(x, ru)) / d);
    let (c0, c1) = (col(nu), col(nv));
    [[c0.0, c1.0], [c0.1, c1.1]]
}
fn det(w: M2) -> f64 { w[0][0] * w[1][1] - w[0][1] * w[1][0] }
fn tr(w: M2) -> f64 { w[0][0] + w[1][1] }
fn fx(x: f64) -> String { format!("{:.6}", if x.abs() < 0.5 * 10f64.powi(-6) { 0.0 } else { x }) } // no "-0.000000"
fn two(w: M2) -> String { format!("{} {} / {} {}", fx(w[0][0]), fx(w[0][1]), fx(w[1][0]), fx(w[1][1])) }
fn image_ratio(ch: Chart, a: f64, b: f64, h: f64) -> f64 {
    // road 4: signed globe area of a small square's normals / roof area
    let c = [(a - h / 2.0, b - h / 2.0), (a + h / 2.0, b - h / 2.0), (a + h / 2.0, b + h / 2.0), (a - h / 2.0, b + h / 2.0)];
    let n: Vec<V> = c.iter().map(|p| gauss(ch, p.0, p.1)).collect();
    let r: Vec<V> = c.iter().map(|p| ch(p.0, p.1)).collect();
    let n0 = gauss(ch, a, b);
    dot(cross(sub(n[2], n[0]), sub(n[3], n[1])), n0) / dot(cross(sub(r[2], r[0]), sub(r[3], r[1])), n0)
}
fn gap(a: f64, b: f64) -> f64 { dot(sub(plan(30.0 + a, 20.0 + b), plan(30.0, 20.0)), gauss(plan, 30.0, 20.0)) }

fn main() {
    let (i1, ii1) = forms(plan, 30.0, 20.0, true, 0.1);
    let w1 = shape(i1, ii1);
    let (i2, ii2) = forms(seam, 25.0, 5.0, true, 0.1);
    let w2 = shape(i2, ii2);
    let n = gauss(plan, 30.0, 20.0);
    let f0 = 0.5 * 0.643501108793284; // halfway up the dome's slope; rim polar angle acos(0.8)
    let (id, iid) = forms(dome, f0, 0.0, true, 1e-3);
    let wd = shape(id, iid);
    let (dome_area, cap) = (PI * R * 12.0, PI * (1.0 - 0.8)); // half dome pi R h; its half-cap on the globe
    let (iu, iiu) = forms(plan, 30.0, 20.0, false, 0.1);
    let wdn = shape(i2, [-ii2[0], -ii2[1], -ii2[2]]); // r_p x r_q points down; not flipped
    let kink: Vec<f64> = [1.0, 0.1].iter().map(|&h: &f64| { let d = sub(gauss(ridge, h / 2.0, 0.0), gauss(ridge, -h / 2.0, 0.0)); dot(d, d).sqrt() / h }).collect();
    let ([e, f, g], [l, m, nn]) = (i1, ii1);
    let ar = arrows(plan, 30.0, 20.0, 1e-3);
    let c = cross(ar[0], ar[1]);
    let (ic, iic) = forms(plan, 0.0, 0.0, true, 1e-3);
    let (ib, iib) = forms(barrel, 10.0, 5.0, true, 1e-3);
    let (il, iil) = forms(plan, 30.0, -20.0, true, 1e-3);
    let rows: Vec<(&str, String)> = vec![
        ("unit normal n at P", format!("{:.6} {:.6} {:.6}", n[0], n[1], n[2])),
        ("  by hand (-3, 2, 6)/7", format!("{:.6} {:.6} {:.6}", -3.0 / 7.0, 2.0 / 7.0, 6.0 / 7.0)),
        ("  tilt from vertical, deg", format!("{:.6}", n[2].acos().to_degrees())),
        ("r_u x r_v at P, its length", format!("{:.6} {:.6} {:.6} {:.6}", c[0], c[1], c[2], dot(c, c).sqrt())),
        ("r_uu, r_vv at P", format!("{} {} {:.6} / {} {} {:.6}", fx(ar[2][0]), fx(ar[2][1]), ar[2][2], fx(ar[4][0]), fx(ar[4][1]), ar[4][2])),
        ("E, F, G at P", format!("{:.6} {:.6} {:.6}", e, f, g)),
        ("I^-1 at P", two(shape(i1, [1.0, 0.0, 1.0]))),
        ("L, M, N at P, plan chart", format!("{} {} {}", fx(l), fx(m), fx(nn))),
        ("  by hand 1/70, 0, -1/70", format!("{:.6} {:.6} {:.6}", 1.0 / 70.0, 0.0, -1.0 / 70.0)),
        ("EG - F^2, LN - M^2", format!("{:.6} {:.9}", e * g - f * f, l * nn - m * m)),
        ("1 W = I^-1 II, plan chart", two(w1)),
        ("2 W from the Gauss map, h = 1 m", two(weingarten(plan, 30.0, 20.0, 1.0))),
        ("  same, h = 0.1 m", two(weingarten(plan, 30.0, 20.0, 0.1))),
        ("3 W in the seam chart at (25, 5)", two(w2)),
        ("  seam L, M, N", format!("{} {} {}", fx(ii2[0]), fx(ii2[1]), fx(ii2[2]))),
        ("det W: plan, seam", format!("{:.9} {:.9}", det(w1), det(w2))),
        ("  (LN - M^2)/(EG - F^2)", format!("{:.9}", (l * nn - m * m) / (e * g - f * f))),
        ("trace W: plan, seam", format!("{:.9} {:.9}", tr(w1), tr(w2))),
        ("  by hand -9/60025, -1/686", format!("{:.9} {:.9}", -9.0 / 60025.0, -1.0 / 686.0)),
        ("4 globe area / roof area, 2 m square", format!("{:.9}", image_ratio(plan, 30.0, 20.0, 2.0))),
        ("  same, 0.2 m square", format!("{:.9}", image_ratio(plan, 30.0, 20.0, 0.2))),
        ("gap above tangent plane, 10 m east", format!("{:.6} half II {:.6}", gap(10.0, 0.0), 0.5 * l * 100.0)),
        ("  10 m east, measured straight up", format!("{:.6}", plan(40.0, 20.0)[2] - plan(30.0, 20.0)[2] - 10.0 * ar[0][2])),
        ("  10 m north", format!("{:.6} half II {:.6}", gap(0.0, 10.0), 0.5 * nn * 100.0)),
        ("  10 m along the seam (10, 10)", format!("{} half II {}", fx(gap(10.0, 10.0)), fx(0.5 * (l + 2.0 * m + nn) * 100.0))),
        ("  1 m east", format!("{:.6}", gap(1.0, 0.0))),
        ("dome W halfway up, outward n", two(wd)),
        ("  -1/R", format!("{:.6}", -1.0 / R)),
        ("  det W and 1/R^2", format!("{:.9} {:.9}", det(wd), 1.0 / R.powi(2))),
        ("half dome: roof area m^2", format!("{:.6}", dome_area)),
        ("  globe area of its normals, cap", format!("{:.6}", cap)),
        ("  det W times roof area", format!("{:.6}", det(wd) * dome_area)),
        ("  rim tilt, deg; globe radius", format!("{:.6} {:.6}", 0.643501108793284f64.to_degrees(), 0.643501108793284f64.sin())),
        ("wrong: normal not unit, W", two(shape(iu, iiu))),
        ("wrong: W = II, det", format!("{:.9}", l * nn - m * m)),
        ("wrong: seam normal left pointing down", two(wdn)),
        ("  its det and trace", format!("{:.9} {:.9}", det(wdn), tr(wdn))),
        ("breaks: crease, |dn|/h at h = 1, 0.1", format!("{:.6} {:.6}", kink[0], kink[1])),
        ("try: W at the centre O", two(shape(ic, iic))),
        ("try: barrel vault R = 60, W", two(shape(ib, iib))),
        ("try: lamp fixing (30, -20), det W", format!("{:.9}", det(shape(il, iil)))),
    ];
    for (name, v) in &rows { println!("{:<38} {}", name, v); }
    for (u, v) in [(30, -20), (30, 20), (-30, 20), (-30, -20)] {
        let g = gauss(plan, u as f64, v as f64);
        println!("figure, saddle corner ({}, {}) -> globe {:.4} {:.4}", u, v, g[0], g[1]);
    }

    assert!((n[0] + 3.0 / 7.0).abs() + (n[1] - 2.0 / 7.0).abs() + (n[2] - 6.0 / 7.0).abs() < 1e-9, "unit normal by hand");
    assert!((l - 1.0 / 70.0).abs() + m.abs() + (nn + 1.0 / 70.0).abs() < 1e-6, "second form by hand");
    let wg = weingarten(plan, 30.0, 20.0, 0.1);
    let worst = (0..2).flat_map(|i| (0..2).map(move |j| (i, j))).map(|(i, j)| (wg[i][j] - w1[i][j]).abs()).fold(0.0, f64::max);
    assert!(worst < 1e-5, "Gauss map road agrees");
    assert!((det(w1) - det(w2)).abs() < 1e-9 && (tr(w1) - tr(w2)).abs() < 1e-8, "det and trace ignore the chart");
    assert!((w1[0][0] - w2[0][0]).abs() > 1e-3, "entries of W do depend on the chart");
    assert!((det(w1) + 9.0 / 60025.0).abs() < 1e-12 && (tr(w1) + 1.0 / 686.0).abs() < 1e-10, "det and trace by hand");
    let (e2, e02) = ((image_ratio(plan, 30.0, 20.0, 2.0) - det(w1)).abs(), (image_ratio(plan, 30.0, 20.0, 0.2) - det(w1)).abs());
    assert!(e02 < e2 / 50.0 && e02 < 1e-9, "the globe area ratio closes in on det W");
    assert!((gap(10.0, 0.0) - 0.5 * l * 100.0).abs() < 1e-6, "the roof leaves its tangent plane by II/2");
    assert!((wd[0][0] + 1.0 / R).abs() + (wd[1][1] + 1.0 / R).abs() + wd[0][1].abs() < 1e-6, "dome W = -I/R");
    assert!((det(wd) * dome_area - cap).abs() < 1e-6, "dome: det W times area = globe area");
    assert!(kink[1] > 9.0 * kink[0], "a crease has no shape operator");
    println!("ALL CHECKS PASS");
}
