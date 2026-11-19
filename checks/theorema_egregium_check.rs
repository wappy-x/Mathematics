// Theorema Egregium -- the check behind the card.  std only, no crates.
// Gaussian curvature K, three independent roads:
//   1 inside:  Brioschi's formula, fed only the table E, F, G (derivatives by central differences)
//   2 outside: det of the shape operator, (LN - M^2)/(EG - F^2), which needs the normal in space
//   3 taped:   lay a tape round a circle walked out on the surface and compare it with 2 pi s
use std::f64::consts::PI;
type V3 = [f64; 3];

fn d1(f: &dyn Fn(f64, f64) -> f64, u: f64, v: f64, h: f64) -> (f64, f64) {
    ((f(u + h, v) - f(u - h, v)) / (2.0 * h), (f(u, v + h) - f(u, v - h)) / (2.0 * h))
}
fn det3(m: [[f64; 3]; 3]) -> f64 {
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn vec(a: V3, b: V3, s: f64) -> V3 { [(a[0] - b[0]) * s, (a[1] - b[1]) * s, (a[2] - b[2]) * s] }
fn dot(a: V3, b: V3) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V3, b: V3) -> V3 { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }

fn brioschi(e_: &dyn Fn(f64, f64) -> f64, f_: &dyn Fn(f64, f64) -> f64, g_: &dyn Fn(f64, f64) -> f64,
            u: f64, v: f64, h: f64) -> f64 {
    // road 1: E, F, G and their derivatives, nothing else
    let (e, f, g) = (e_(u, v), f_(u, v), g_(u, v));
    let ((eu, ev), (fu, fv), (gu, gv)) = (d1(e_, u, v, h), d1(f_, u, v, h), d1(g_, u, v, h));
    let evv = (e_(u, v + h) - 2.0 * e + e_(u, v - h)) / h.powf(2.0);
    let guu = (g_(u + h, v) - 2.0 * g + g_(u - h, v)) / h.powf(2.0);
    let fuv = (f_(u + h, v + h) - f_(u + h, v - h) - f_(u - h, v + h) + f_(u - h, v - h)) / (4.0 * h * h);
    let a = [[-evv / 2.0 + fuv - guu / 2.0, eu / 2.0, fu - ev / 2.0], [fv - gu / 2.0, e, f], [gv / 2.0, f, g]];
    let b = [[0.0, ev / 2.0, gu / 2.0], [ev / 2.0, e, f], [gu / 2.0, f, g]];
    (det3(a) - det3(b)) / (e * g - f * f).powf(2.0)
}

fn gauss_orth(e_: &dyn Fn(f64, f64) -> f64, g_: &dyn Fn(f64, f64) -> f64, u: f64, v: f64, h: f64) -> f64 {
    // Gauss's shorter formula, valid only where F = 0
    let w = |a: f64, b: f64| (e_(a, b) * g_(a, b)).sqrt();
    let a_ = |a: f64, b: f64| d1(g_, a, b, h).0 / w(a, b);
    let b_ = |a: f64, b: f64| d1(e_, a, b, h).1 / w(a, b);
    -(d1(&a_, u, v, h).0 + d1(&b_, u, v, h).1) / (2.0 * w(u, v))
}

fn outside(r: &dyn Fn(f64, f64) -> V3, u: f64, v: f64, h: f64) -> (f64, f64, f64, f64, [f64; 3]) {
    // road 2: the patch in space, its normal, L, M, N
    let p = |i: f64, j: f64| r(u + i * h, v + j * h);
    let (ru, rv) = (vec(p(1.0, 0.0), p(-1.0, 0.0), 0.5 / h), vec(p(0.0, 1.0), p(0.0, -1.0), 0.5 / h));
    let (c, pu, mu, pv, mv) = (p(0.0, 0.0), p(1.0, 0.0), p(-1.0, 0.0), p(0.0, 1.0), p(0.0, -1.0));
    let (pp, pm, mp, mm) = (p(1.0, 1.0), p(1.0, -1.0), p(-1.0, 1.0), p(-1.0, -1.0));
    let mut ruu = [0.0; 3]; let mut rvv = [0.0; 3]; let mut ruv = [0.0; 3];
    for k in 0..3 {
        ruu[k] = (pu[k] + mu[k] - 2.0 * c[k]) / h.powf(2.0);
        rvv[k] = (pv[k] + mv[k] - 2.0 * c[k]) / h.powf(2.0);
        ruv[k] = (pp[k] - pm[k] - mp[k] + mm[k]) / (4.0 * h * h);
    }
    let m = cross(ru, rv);
    let len = dot(m, m).sqrt();
    let n = [m[0] / len, m[1] / len, m[2] / len];
    let (e, f, g) = (dot(ru, ru), dot(ru, rv), dot(rv, rv));
    let (l, mm_, nn) = (dot(ruu, n), dot(ruv, n), dot(rvv, n));
    let k = (l * nn - mm_ * mm_) / (e * g - f * f);
    let hm = (e * nn - 2.0 * f * mm_ + g * l) / (2.0 * (e * g - f * f));
    let root = (hm * hm - k).max(0.0).sqrt();
    (k, hm, hm + root, hm - root, [e, f, g])
}

fn sphere(rr: f64) -> impl Fn(f64, f64) -> V3 {
    move |ph: f64, th: f64| [rr * ph.sin() * th.cos(), rr * ph.sin() * th.sin(), rr * ph.cos()]
}
fn tape(rr: f64, s: f64, n: usize) -> f64 {
    // road 3: n straight tape pieces round the circle s from the pole
    let sp = sphere(rr);
    let pts: Vec<V3> = (0..=n).map(|k| sp(s / rr, 2.0 * PI * k as f64 / n as f64)).collect();
    let mut t = 0.0;
    for w in pts.windows(2) { let d = vec(w[1], w[0], 1.0); t += dot(d, d).sqrt(); }
    t
}
fn k_from_circle(s: f64, c: f64) -> f64 { 3.0 * (2.0 * PI * s - c) / (PI * s.powf(3.0)) }
fn z(x: f64) -> f64 { if x.abs() < 5e-13 { 0.0 } else { x } }   // print a rounding-level zero as 0

fn main() {
    // ---- the paper: an A4 sheet, 297 mm side rolled round, 210 mm along the tube ----
    let a = 0.297 / (2.0 * PI);
    let sheet = |x: f64, y: f64| [x, y, 0.0];
    let tube = move |x: f64, y: f64| [a * (x / a).sin(), a * (x / a).cos(), y];   // normal points in
    let helix: Vec<V3> = (0..=1000).map(|k| tube(0.297 * k as f64 / 1000.0, 0.210 * k as f64 / 1000.0)).collect();
    let mut helix_len = 0.0;
    for w in helix.windows(2) { let d = vec(w[1], w[0], 1.0); helix_len += dot(d, d).sqrt(); }
    let (one, zero) = (|_: f64, _: f64| 1.0, |_: f64, _: f64| 0.0);
    let (kt, ht, k1t, k2t, efg_t) = outside(&tube, 0.1, 0.05, 1e-5);
    let (_, hs, _, _, _) = outside(&sheet, 0.1, 0.05, 1e-5);
    // ---- the dome (sphere of radius 60 m) and the globe (6371 km), polar angle phi, longitude theta ----
    let (ed, gd) = (|_: f64, _: f64| 3600.0, |ph: f64, _: f64| 3600.0 * ph.sin().powf(2.0));
    let rg = 6371.0_f64;
    let (eg, gg) = (move |_: f64, _: f64| rg * rg, move |ph: f64, _: f64| rg * rg * ph.sin().powf(2.0));
    // ---- the saddle: plan chart (u east, v north) and seam chart (u = p + q, v = p - q) ----
    let seam = |p: f64, q: f64| [p + q, p - q, 30.0 + p * q / 30.0];       // the seam chart's patch in space
    let (ep, fp, gp) = (|u: f64, _: f64| 1.0 + u * u / 3600.0, |u: f64, v: f64| -u * v / 3600.0, |_: f64, v: f64| 1.0 + v * v / 3600.0);
    let (es, fs, gs) = (|_: f64, q: f64| 2.0 + q * q / 900.0, |p: f64, q: f64| p * q / 900.0, |p: f64, _: f64| 2.0 + p * p / 900.0);
    let k_p_hand = -(1.0 / 3600.0) / (1.0_f64 + 0.25 + 1.0 / 9.0).powf(2.0);
    let b = 0.210 / (2.0 * PI);                                         // try: roll the other side round
    let (kn, _, _, _, _) = outside(&move |x: f64, y: f64| [b * (x / b).sin(), b * (x / b).cos(), y], 0.1, 0.05, 1e-5);
    let diag = (0.297f64.powf(2.0) + 0.210f64.powf(2.0)).sqrt();
    let mut rows: Vec<(String, String)> = vec![
        ("tube radius a, m".into(), format!("{:.6}", a)),
        ("tube E, F, G from the patch".into(), format!("{:.6} {:.6} {:.6}", z(efg_t[0]), z(efg_t[1]), z(efg_t[2]))),
        ("sheet diagonal, flat, m".into(), format!("{:.6}", diag)),
        ("same line on the tube, 1000 tape pieces, m".into(), format!("{:.6}", helix_len)),
        ("1 K tube, inside (E=1, F=0, G=1)".into(), format!("{:.9}", z(brioschi(&one, &zero, &one, 0.1, 0.05, 1e-3)))),
        ("2 K tube, outside, 1/m^2".into(), format!("{:.9}", z(kt))),
        ("  tube kappa1, kappa2, 1/m".into(), format!("{:.6} {:.6}", k1t, z(k2t))),
        ("  H tube, sheet, 1/m".into(), format!("{:.6} {:.6}", ht, z(hs))),
        ("1 K dome, inside, 1/m^2".into(), format!("{:.9}", brioschi(&ed, &zero, &gd, 0.3, 0.4, 1e-4))),
        ("  Gauss F=0 formula".into(), format!("{:.9}", gauss_orth(&ed, &gd, 0.3, 0.4, 1e-4))),
        ("2 K dome, outside".into(), format!("{:.9}", outside(&sphere(60.0), 0.3, 0.4, 1e-4).0)),
        ("  1/60^2".into(), format!("{:.9}", 1.0 / 3600.0)),
        ("D (12 m E, 16 m N of crown): to cut, rim, m".into(), format!("{:.6} {:.6}", 60.0 * (12.0f64 / 60.0).asin(), 60.0 * (0.8f64.acos() - (20.0f64 / 60.0).asin()))),
    ];
    for s in [10.0_f64, 5.0] {
        let c = 2.0 * PI * 60.0 * (s / 60.0).sin();
        rows.push((format!("dome circle s = {:.0} m: 2 pi s, closed C, m", s), format!("{:.6} {:.6}", 2.0 * PI * s, c)));
        rows.push(("  tape 360, 3600 pieces, m".into(), format!("{:.6} {:.6}", tape(60.0, s, 360), tape(60.0, s, 3600))));
        rows.push(("  sin(s/60); g, shortfall, m; 3 K: C, tape".into(), format!("{:.6} {:.6} {:.6} {:.9} {:.9}",
                   (s / 60.0).sin(), 60.0 * (s / 60.0).sin(), 2.0 * PI * s - c, k_from_circle(s, c), k_from_circle(s, tape(60.0, s, 3600)))));
    }
    let kg = brioschi(&eg, &zero, &gg, 0.9, 0.2, 1e-4);
    let cg = 2.0 * PI * rg * (1000.0 / rg).sin();
    let r72 = 72.0_f64.to_radians();
    let more: Vec<(&str, String)> = vec![
        ("1 K globe, inside, x 1e8 per km^2", format!("{:.6}", kg * 1e8)),
        ("  1/sqrt(K), km", format!("{:.3}", 1.0 / kg.sqrt())),
        ("2 K globe, outside, x 1e8", format!("{:.6}", outside(&sphere(rg), 0.9, 0.2, 1e-4).0 * 1e8)),
        ("globe circle s = 1000 km: 2 pi s, C, km", format!("{:.3} {:.3}", 2.0 * PI * 1000.0, cg)),
        ("  tape 10000 pieces, km; shortfall, km", format!("{:.3} {:.3}", tape(rg, 1000.0, 10000), 2.0 * PI * 1000.0 - cg)),
        ("3 K from tape, x 1e8", format!("{:.6}", k_from_circle(1000.0, tape(rg, 1000.0, 10000)) * 1e8)),
        ("  rim kept 2 pi s on a flat map: stretch", format!("{:.6}", 2.0 * PI * 1000.0 / cg)),
        ("Mercator at 72 deg: length, area stretch", format!("{:.6} {:.6}", 1.0 / r72.cos(), 1.0 / r72.cos().powf(2.0))),
        ("1 K roof at P, plan chart, 1/m^2", format!("{:.9}", brioschi(&ep, &fp, &gp, 30.0, 20.0, 1.0))),
        ("1 K roof at P, seam chart", format!("{:.9}", brioschi(&es, &fs, &gs, 25.0, 5.0, 1.0))),
        ("2 K roof at P, outside, seam patch", format!("{:.9}", outside(&seam, 25.0, 5.0, 1.0).0)),
        ("  hand: 1.361111^2, -(1/3600)/1.361111^2", format!("{:.6} {:.9}", (1.0_f64 + 0.25 + 1.0 / 9.0).powf(2.0), k_p_hand)),
        ("K roof at O, inside, 1/m^2", format!("{:.9}", brioschi(&ep, &fp, &gp, 0.0, 0.0, 1.0))),
        ("wrong: F=0 formula on plan chart at P; F there", format!("{:.9} {:.6}", z(gauss_orth(&ep, &gp, 30.0, 20.0, 1.0)), fp(30.0, 20.0))),
        ("wrong: circle test at s = pi R/2, x 1e8; % low", format!("{:.6} {:.2}", k_from_circle(PI * rg / 2.0, 2.0 * PI * rg) * 1e8, 100.0 * (1.0 - k_from_circle(PI * rg / 2.0, 2.0 * PI * rg) * rg * rg))),
        ("breaks: cone tip, quarter cut, K at 0.1, 0.01 m", format!("{:.3} {:.3}", k_from_circle(0.1, 1.5 * PI * 0.1), k_from_circle(0.01, 1.5 * PI * 0.01))),
        ("try: roll the 210 mm side: kappa1 = 1/b, K", format!("{:.6} {:.9}", 1.0 / b, z(kn))),
        ("try: 10 m circle on a 120 m dome, shortfall", format!("{:.6}", 2.0 * PI * 10.0 - 2.0 * PI * 120.0 * (10.0_f64 / 120.0).sin())),
        ("try: K roof at the corner (30, 36)", format!("{:.9}", brioschi(&ep, &fp, &gp, 30.0, 36.0, 1.0))),
    ];
    for (n, v) in more { rows.push((n.to_string(), v)); }
    for (name, v) in &rows { println!("{:<48} {}", name, v); }
    let ss: Vec<f64> = (0..9).map(|k| 250.0 * k as f64).collect();
    let line = |f: &dyn Fn(f64) -> String| ss.iter().map(|&s| f(s)).collect::<Vec<_>>().join(" ");
    println!("figure, s km {}", line(&|s| format!("{:.0}", s)));
    println!("figure, shortfall km {}", line(&|s| format!("{:.1}", 2.0 * PI * s - 2.0 * PI * rg * (s / rg).sin())));
    println!("figure, pi K s^3/3 km {}", line(&|s| format!("{:.1}", PI * s.powf(3.0) / (3.0 * rg * rg))));

    assert!((helix_len - diag).abs() < 1e-6, "rolling keeps the diagonal's length");
    assert!((brioschi(&ed, &zero, &gd, 0.3, 0.4, 1e-4) * 3600.0 - 1.0).abs() < 1e-6, "dome: inside K = 1/60^2");
    assert!((outside(&sphere(60.0), 0.3, 0.4, 1e-4).0 * 3600.0 - 1.0).abs() < 1e-6, "dome: outside K = 1/60^2");
    assert!((gauss_orth(&ed, &gd, 0.3, 0.4, 1e-4) * 3600.0 - 1.0).abs() < 1e-6, "dome: Gauss's F = 0 form gives 1/60^2");
    assert!((kg * rg * rg - 1.0).abs() < 1e-6, "globe: inside K = 1/R^2");
    assert!((brioschi(&ep, &fp, &gp, 30.0, 20.0, 1.0) / k_p_hand - 1.0).abs() < 1e-9, "roof, plan chart, against the hand value");
    assert!((brioschi(&es, &fs, &gs, 25.0, 5.0, 1.0) / k_p_hand - 1.0).abs() < 1e-9, "roof, seam chart: K is not chart-made");
    assert!((outside(&seam, 25.0, 5.0, 1.0).0 / k_p_hand - 1.0).abs() < 1e-9, "roof: outside agrees with inside");
    assert!(kt.abs() < 1e-6, "tube: outside K = 0, as the inside table says");
    assert!((ht - 1.0 / (2.0 * a)).abs() < 1e-4, "tube: H = 1/(2a), not 0: H is not felt from inside");
    let (e5, e10) = ((k_from_circle(5.0, tape(60.0, 5.0, 3600)) * 3600.0 - 1.0).abs(), (k_from_circle(10.0, tape(60.0, 10.0, 3600)) * 3600.0 - 1.0).abs());
    assert!(e5 < e10 && e10 < 0.01, "circle test closes in");
    assert!((k_from_circle(1000.0, tape(rg, 1000.0, 10000)) * rg * rg - 1.0).abs() < 0.002, "globe felt by a tape");
    println!("ALL CHECKS PASS");
}
