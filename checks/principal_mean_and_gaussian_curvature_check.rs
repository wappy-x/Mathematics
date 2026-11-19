// Principal, mean and Gaussian curvature -- the check behind the card.
// Standard library only.  A stadium roof: a saddle z = 30 + (x^2 - y^2)/120
// over the middle and a dome (a sphere of radius 60 m) over the east end.
// The unit normal n points up, to the sky; a bending rate is positive where the
// roof bends toward n (up, like a bowl).  Roads to the two bending rates:
// (1) the formulas K = det II / det I and H = half the trace of W = I^-1 II,
// (2) a symmetric 2-by-2 matrix in a roof-perpendicular frame, turned by one
// Jacobi rotation, (3) a sweep of 3600 directions measuring each curve on the
// roof from raw 3D points, (4) a second chart, (5) K from the spread of n.
use std::f64::consts::PI;
type V = [f64; 3];
type Chart = fn(f64, f64) -> V;
const A: f64 = 60.0; // saddle radius a (m)
const R: f64 = 60.0; // dome sphere radius (m)
fn saddle(x: f64, y: f64) -> V { [x, y, 30.0 + (x * x - y * y) / (2.0 * A)] }
fn seam(s: f64, t: f64) -> V { saddle(s + t, s - t) } // second saddle chart: along the seams
fn dome_plan(x: f64, y: f64) -> V { [x, y, -10.5 + (R * R - (x - 30.0).powi(2) - y * y).sqrt()] }
fn dome_sphere(p: f64, t: f64) -> V { [30.0 + R * p.sin() * t.cos(), R * p.sin() * t.sin(), -10.5 + R * p.cos()] }
fn vault(x: f64, s: f64) -> V { [x, 20.0 * (s / 20.0).sin(), 20.0 * (s / 20.0).cos()] } // copper rolled to radius 20 m
fn sheet(x: f64, s: f64) -> V { [x, s, 0.0] } // the same copper laid flat

fn dot(a: V, b: V) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }
fn cross(a: V, b: V) -> V { [a[1] * b[2] - a[2] * b[1], a[2] * b[0] - a[0] * b[2], a[0] * b[1] - a[1] * b[0]] }
fn comb(cs: &[f64], vs: &[V]) -> V {
    let mut r = [0.0; 3];
    for k in 0..3 { r[k] = cs.iter().zip(vs).fold(0.0, |acc, (c, v)| acc + c * v[k]); }
    r
}
fn unit_up(f: Chart, u: f64, v: f64, h: f64) -> (V, V, V) { // the unit normal, turned to point up
    let ru = comb(&[0.5 / h, -0.5 / h], &[f(u + h, v), f(u - h, v)]);
    let rv = comb(&[0.5 / h, -0.5 / h], &[f(u, v + h), f(u, v - h)]);
    let n = cross(ru, rv);
    let s = dot(n, n).sqrt() * if n[2] > 0.0 { 1.0 } else { -1.0 };
    (ru, rv, [n[0] / s, n[1] / s, n[2] / s])
}
fn forms(f: Chart, u: f64, v: f64, h: f64) -> [f64; 6] { // E, F, G, L, M, N by central differences
    let (ru, rv, n) = unit_up(f, u, v, h);
    let w = [1.0 / h / h, -2.0 / h / h, 1.0 / h / h];
    let ruu = comb(&w, &[f(u + h, v), f(u, v), f(u - h, v)]);
    let rvv = comb(&w, &[f(u, v + h), f(u, v), f(u, v - h)]);
    let q = 0.25 / h / h;
    let ruv = comb(&[q, -q, -q, q], &[f(u + h, v + h), f(u + h, v - h), f(u - h, v + h), f(u - h, v - h)]);
    [dot(ru, ru), dot(ru, rv), dot(rv, rv), dot(ruu, n), dot(ruv, n), dot(rvv, n)]
}
fn curv(x: [f64; 6]) -> [f64; 4] { // road 1: K, H, kappa_1, kappa_2
    let [e, f, g, l, m, n] = x;
    let k = (l * n - m * m) / (e * g - f * f);
    let h = (e * n - 2.0 * f * m + g * l) / (2.0 * (e * g - f * f));
    let d = (h * h - k).max(0.0).sqrt();
    [k, h, h + d, h - d]
}
fn frame(e: f64, f: f64, g: f64) -> ([f64; 2], [f64; 2]) { // roof-perpendicular unit steps, as (du, dv)
    let w = (g - f * f / e).sqrt();
    ([1.0 / e.sqrt(), 0.0], [-f / e / w, 1.0 / w])
}
fn ii(l: f64, m: f64, n: f64, a: [f64; 2], b: [f64; 2]) -> f64 { l * a[0] * b[0] + m * (a[0] * b[1] + a[1] * b[0]) + n * a[1] * b[1] }
fn jacobi(x: [f64; 6]) -> [f64; 4] { // road 2: one rotation diagonalises S
    let [e, f, g, l, m, n] = x;
    let (e1, e2) = frame(e, f, g);
    let (s11, s12, s22) = (ii(l, m, n, e1, e1), ii(l, m, n, e1, e2), ii(l, m, n, e2, e2));
    let th = 0.5 * (2.0 * s12).atan2(s11 - s22);
    let (c, s) = (th.cos(), th.sin());
    [s11 * c * c + 2.0 * s12 * s * c + s22 * s * s, s11 * s * s - 2.0 * s12 * s * c + s22 * c * c, th, s12]
}
fn kn_raw(f: Chart, u: f64, v: f64, th: f64, h: f64) -> f64 { // road 3: bend of a roof curve from 3D points
    let x = forms(f, u, v, h);
    let (e1, e2) = frame(x[0], x[1], x[2]);
    let (a, b) = (th.cos() * e1[0] + th.sin() * e2[0], th.cos() * e1[1] + th.sin() * e2[1]);
    let n = unit_up(f, u, v, h).2;
    let g1 = comb(&[0.5 / h, -0.5 / h], &[f(u + a * h, v + b * h), f(u - a * h, v - b * h)]);
    let g2 = comb(&[1.0 / h / h, -2.0 / h / h, 1.0 / h / h], &[f(u + a * h, v + b * h), f(u, v), f(u - a * h, v - b * h)]);
    dot(g2, n) / dot(g1, g1)
}
fn gauss_map_k(f: Chart, u: f64, v: f64, h: f64) -> f64 { // road 5: area spread of n over area of roof
    let (ru, rv, n) = unit_up(f, u, v, h);
    let nu = comb(&[0.5 / h, -0.5 / h], &[unit_up(f, u + h, v, h).2, unit_up(f, u - h, v, h).2]);
    let nv = comb(&[0.5 / h, -0.5 / h], &[unit_up(f, u, v + h, h).2, unit_up(f, u, v - h, h).2]);
    dot(cross(nu, nv), n) / dot(cross(ru, rv), n)
}
fn f9(v: f64) -> String { format!("{:.9}", v) }
fn f12(v: f64) -> String { format!("{:.12}", v) }
fn show(label: &str, val: String) { println!("{:<44} {}", label, val); }

fn main() {
    let (px, py) = (30.0, 20.0); // the north-east lamp fixing
    let (p, q) = (px / A, -py / A); // its two slopes
    let (e, f, g) = (1.0 + p * p, p * q, 1.0 + q * q);
    let (l, m, n) = ((1.0 / A) / (1.0 + p * p + q * q).sqrt(), 0.0, (-1.0 / A) / (1.0 + p * p + q * q).sqrt());
    let [k, h, k1, k2] = curv([e, f, g, l, m, n]);
    show("P slopes east, north", format!("{:.6} {:.6}", p, q));
    show("P E, F, G", format!("{:.6} {:.6} {:.6}", e, f, g));
    show("P EG - F^2, its root", format!("{:.6} {:.6}", e * g - f * f, (e * g - f * f).sqrt()));
    show("P L, M, N (1/m)", format!("{} {} {}", f9(l), f9(m), f9(n)));
    show("P K (1/m^2), road 1", f12(k));
    show("P H (1/m), road 1", f9(h));
    show("P root of H^2 - K (1/m)", f9((h * h - k).sqrt()));
    show("P kappa_1, kappa_2 (1/m), road 1", format!("{} {}", f9(k1), f9(k2)));
    show("P signed radii 1/kappa (m)", format!("{:.3} {:.3}", 1.0 / k1, 1.0 / k2));
    let [j1, j2, th, s12] = jacobi([e, f, g, l, m, n]);
    let (e1, e2) = frame(e, f, g);
    let (s11, s22) = (ii(l, m, n, e1, e1), ii(l, m, n, e2, e2));
    show("P frame e1, e2 as plan steps (dx, dy)", format!("{:.6} {:.6} {:.6} {:.6}", e1[0], e1[1], e2[0], e2[1]));
    show("P frame matrix S: s11, s22, s12 (1/m)", format!("{} {} {}", f9(s11), f9(s22), f9(s12)));
    show("P tan 2 theta_1 = 2 s12 / (s11 - s22)", format!("{:.6}", 2.0 * s12 / (s11 - s22)));
    show("P kappa_1, kappa_2, road 2 Jacobi", format!("{} {}", f9(j1), f9(j2)));
    let w = [g * l - f * m, g * m - f * n, e * m - f * l, e * n - f * m].map(|x| x / (e * g - f * f)); // W = I^-1 II
    show("P W row by row (1/m)", w.map(f9).join(" "));
    show("P trace W = 2H, det W = K", format!("{} {}", f9(w[0] + w[3]), f12(w[0] * w[3] - w[1] * w[2])));
    let (v1, v2) = ([k1 - w[3], w[2]], [k2 - w[3], w[2]]); // eigenvectors of W in (dx, dy), from its second row
    show("P v1, v2: eigenvectors of W (dx, dy)", format!("{} {} {} {}", f9(v1[0]), f9(v1[1]), f9(v2[0]), f9(v2[1])));
    let hd = [v1, v2].map(|v| v[1].atan2(v[0]).to_degrees().rem_euclid(180.0));
    show("P plan headings of v1, v2; angle between", format!("{:.4} {:.4} {:.4}", hd[0], hd[1], hd[1] - hd[0]));
    let roof = ii(e, f, g, v1, e2).atan2(ii(e, f, g, v1, e1)).to_degrees(); // ii's formula fed E, F, G is the first form
    show("P kappa_1 roof deg from east: Jacobi, v1", format!("{:.4} {:.4}", th.to_degrees(), roof));
    let sweep: Vec<(f64, f64)> = (0..3600).map(|i| (kn_raw(saddle, px, py, PI * i as f64 / 3600.0, 1.0), i as f64 / 20.0)).collect();
    let (mut hi, mut lo) = (sweep[0], sweep[0]);
    for &(kk, d) in &sweep {
        if kk > hi.0 || (kk == hi.0 && d > hi.1) { hi = (kk, d); }
        if kk < lo.0 || (kk == lo.0 && d < lo.1) { lo = (kk, d); }
    }
    show("P sweep max, min (1/m), road 3", format!("{} {}", f9(hi.0), f9(lo.0)));
    show("P sweep at roof deg", format!("{:.2} {:.2}", hi.1, lo.1));
    let euler = sweep.iter().map(|&(kk, d)| (kk - (k1 * (d.to_radians() - th).cos().powi(2) + k2 * (d.to_radians() - th).sin().powi(2))).abs()).fold(0.0, f64::max);
    show("P worst gap to Euler's formula (1/m)", f12(euler));
    let s_seam = curv(forms(seam, 25.0, 5.0, 1.0));
    show("P K, kappa_1, kappa_2, road 4 seam chart", format!("{} {} {}", f12(s_seam[0]), f9(s_seam[2]), f9(s_seam[3])));
    let (gk2, gk) = (gauss_map_k(saddle, px, py, 0.02), gauss_map_k(saddle, px, py, 0.01));
    show("P K by road 5, step 0.02 | 0.01 m", format!("{} | {}", f12(gk2), f12(gk)));
    let i12 = ii(e, f, g, v1, v2);
    show("P |I(v1, v2)|, roof dot of the two", f12(i12.abs()));
    show("P east and north lines, roof angle (deg)", format!("{:.4}", (f / (e * g).sqrt()).acos().to_degrees()));
    let o = curv(forms(saddle, 0.0, 0.0, 1.0));
    show("O K, H, kappa_1, kappa_2", format!("{} {} {} {}", f12(o[0]), f9(o[1]), f9(o[2]), f9(o[3])));
    let [d1c, d1] = [0.02, 0.01].map(|h| curv(forms(dome_plan, 42.0, 16.0, h)));
    let [d2c, d2] = [0.0004, 0.0002].map(|h| curv(forms(dome_sphere, (1.0f64 / 3.0).asin(), 16.0f64.atan2(12.0), h)));
    show("D plan K, H, step 0.02 | 0.01 m", format!("{} {} | {} {}", f12(d1c[0]), f9(d1c[1]), f12(d1[0]), f9(d1[1])));
    show("D sphere K, H, step 0.0004 | 0.0002 rad", format!("{} {} | {} {}", f12(d2c[0]), f9(d2c[1]), f12(d2[0]), f9(d2[1])));
    let [djc, dj] = [0.02, 0.01].map(|h| jacobi(forms(dome_plan, 42.0, 16.0, h)));
    show("D kappa_1 - kappa_2, step 0.02 | 0.01 m", format!("{} | {}", f12(djc[0] - djc[1]), f12(dj[0] - dj[1])));
    let (cyl, flat) = (forms(vault, 0.0, 0.0, 0.01), forms(sheet, 0.0, 0.0, 0.01));
    let efg: Vec<String> = cyl[..3].iter().chain(flat[..3].iter()).map(|x| format!("{:.6}", x)).collect();
    show("vault E, F, G | sheet E, F, G", efg.join(" "));
    let (cc, ff) = (curv(cyl), curv(flat));
    show("vault K, H | sheet K, H", format!("{} {} {} {}", f12(cc[0]), f9(cc[1]), f12(ff[0]), f9(ff[1])));
    show("vault H, step 0.02 | 0.01 m", format!("{} | {}", f9(curv(forms(vault, 0.0, 0.0, 0.02))[1]), f9(cc[1])));
    show("wrong: eigenvalues of II alone; product", format!("{} {} {}", f9(l), f9(n), f12(l * n)));
    show("wrong: height Hessian K, H", format!("{} {}", f12(-1.0 / A / A), f9(0.0)));
    show("wrong: east, north as principal; K, H", format!("{} {} {} {}", f9(l / e), f9(n / g), f12(l / e * n / g), f9((l / e + n / g) / 2.0)));
    let fl = curv([e, f, g, -l, -m, -n]);
    show("flip n: K, H", format!("{} {}", f12(fl[0]), f9(fl[1])));
    let rows: [(&str, Chart, f64, f64, f64); 3] = [("O", saddle, 0.0, 0.0, 1.0), ("P", saddle, px, py, 1.0), ("D", dome_plan, 42.0, 16.0, 0.01)];
    for (name, ch, u, v, hh) in rows {
        let pts: Vec<String> = (0..13).map(|i| format!("{:.2}", 1000.0 * kn_raw(ch, u, v, (15.0 * i as f64).to_radians(), hh))).collect();
        println!("chart, {} kappa_n (1/km) every 15 roof deg: {}", name, pts.join(" "));
    }

    assert!((j1 - k1).abs() < 1e-12 && (j2 - k2).abs() < 1e-12); // road 2 against road 1
    assert!((hi.0 - k1).abs() < 1e-8 && (lo.0 - k2).abs() < 1e-8 && euler < 1e-9); // road 3
    assert!((s_seam[0] - k).abs() < 1e-12 && (s_seam[2] - k1).abs() < 1e-9 && (s_seam[3] - k2).abs() < 1e-9);
    assert!((gk - k).abs() < 1e-9); // road 5: Gauss map against det II / det I
    assert!(i12.abs() < 1e-15 && (roof - th.to_degrees()).abs() < 1e-9 && (w[0] * w[3] - w[1] * w[2] - k).abs() < 1e-15); // W's eigenvectors against the Jacobi turn
    assert!((d1[0] - 1.0 / R / R).abs() < 1e-8 && (d2[0] - 1.0 / R / R).abs() < 1e-8 && (d1[1] + 1.0 / R).abs() < 1e-6 && (d2[1] + 1.0 / R).abs() < 1e-6);
    assert!((dj[0] - dj[1]).abs() < 1e-6 && (l * n - k).abs() > 1e-5); // dome umbilic; II alone is wrong
    assert!((gk - k).abs() < (gk2 - k).abs() / 3.0 && (dj[0] - dj[1]).abs() < (djc[0] - djc[1]).abs() / 3.0); // stepped errors shrink
    assert!((cc[1] + 1.0 / 40.0).abs() < 1e-6 && cc[0].abs() < 1e-9 && (cyl[0] - flat[0]).abs() + (cyl[2] - flat[2]).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
