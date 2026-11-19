// Volume form and Laplace-Beltrami on a dome panel. std only.
// Roads: closed form, two charts (phi, theta) and (x, y), a triangle mesh with cotangent weights,
// and a Legendre series for the slowest cooling rate. Every number on the card is printed here.
use std::collections::HashMap;
use std::f64::consts::PI;
const R: f64 = 1.0; const P0: f64 = PI / 3.0; const KAPPA: f64 = 1.0e-4; const T0: f64 = 40.0;
const A_GEO: f64 = R * P0; // distance from top to edge along the panel, m
const H: f64 = 1e-4;
fn f6(x: f64) -> String { format!("{:.6}", x) }
type Metric = fn(f64, f64) -> (f64, f64, f64);
type Func = fn(f64, f64) -> f64;

// Laplace-Beltrami from the metric: (1/sqrt det g) d_i( sqrt det g  g^ij  d_j f ), by central differences
fn lb(metric: Metric, f: Func, x: f64, y: f64) -> f64 {
    let flux = |x: f64, y: f64| {
        let (e, ff, g) = metric(x, y); let det = e * g - ff * ff; let s = det.sqrt();
        let fx = (f(x + H, y) - f(x - H, y)) / (2.0 * H); let fy = (f(x, y + H) - f(x, y - H)) / (2.0 * H);
        (s * (g * fx - ff * fy) / det, s * (-ff * fx + e * fy) / det, s)
    };
    let d1 = (flux(x + H, y).0 - flux(x - H, y).0) / (2.0 * H); let d2 = (flux(x, y + H).1 - flux(x, y - H).1) / (2.0 * H);
    (d1 + d2) / flux(x, y).2
}
fn flat(f: Func, x: f64, y: f64) -> f64 { // the flat-plane Laplacian f_xx + f_yy in the same chart: the mistake
    (f(x + H, y) + f(x - H, y) + f(x, y + H) + f(x, y - H) - 4.0 * f(x, y)) / (H * H)
}
fn polar(p: f64, _t: f64) -> (f64, f64, f64) { (R * R, 0.0, (R * p.sin()).powi(2)) } // chart 1: (phi, theta)
fn graph(x: f64, y: f64) -> (f64, f64, f64) { // chart 2: (x, y), z = sqrt(R^2 - x^2 - y^2)
    let q = R * R - x * x - y * y; (1.0 + x * x / q, x * y / q, 1.0 + y * y / q)
}
fn z_polar(p: f64, _t: f64) -> f64 { R * p.cos() }
fn z_graph(x: f64, y: f64) -> f64 { (R * R - x * x - y * y).sqrt() }

type V3 = [f64; 3];
fn mesh(n: usize) -> (Vec<V3>, Vec<Vec<usize>>, Vec<[usize; 3]>) { // rings of 1, 6, 12, ... points
    let (mut pts, mut rings, mut tris) = (Vec::new(), Vec::new(), Vec::new());
    for k in 0..=n {
        let m = std::cmp::max(1, 6 * k); let ph = k as f64 * P0 / n as f64;
        rings.push((pts.len()..pts.len() + m).collect::<Vec<usize>>());
        for j in 0..m {
            let th = 2.0 * PI * j as f64 / m as f64;
            pts.push([R * ph.sin() * th.cos(), R * ph.sin() * th.sin(), R * ph.cos()]);
        }
    }
    for k in 1..=n {
        let (a_, b_) = (&rings[k - 1], &rings[k]); let (a, b) = (a_.len(), b_.len()); let (mut i, mut j) = (0, 0);
        while if k == 1 { j < b } else { i < a || j < b } {
            if k > 1 && i < a && (j == b || (i + 1) * b < (j + 1) * a) {
                tris.push([a_[i], a_[(i + 1) % a], b_[j % b]]); i += 1;
            } else {
                tris.push([a_[i % a], b_[j], b_[(j + 1) % b]]); j += 1;
            }
        }
    }
    (pts, rings, tris)
}
fn sub(p: &V3, q: &V3) -> V3 { [p[0] - q[0], p[1] - q[1], p[2] - q[2]] }
fn dot(p: &V3, q: &V3) -> f64 { p[0] * q[0] + p[1] * q[1] + p[2] * q[2] }
fn cross(p: &V3, q: &V3) -> V3 { [p[1] * q[2] - p[2] * q[1], p[2] * q[0] - p[0] * q[2], p[0] * q[1] - p[1] * q[0]] }
fn cot_laplacian(pts: &[V3], tris: &[[usize; 3]]) -> (Vec<Vec<(usize, f64)>>, Vec<f64>) {
    let mut idx: HashMap<(usize, usize), usize> = HashMap::new(); let mut w: Vec<((usize, usize), f64)> = Vec::new();
    let mut m = vec![0.0; pts.len()];
    for t in tris {
        let c = cross(&sub(&pts[t[1]], &pts[t[0]]), &sub(&pts[t[2]], &pts[t[0]])); let ar = 0.5 * dot(&c, &c).sqrt();
        for s in 0..3 {
            let (p, q, r) = (t[s], t[(s + 1) % 3], t[(s + 2) % 3]);
            let (u, v) = (sub(&pts[p], &pts[r]), sub(&pts[q], &pts[r])); let cr = cross(&u, &v);
            let e = (p.min(q), p.max(q)); let add = dot(&u, &v) / dot(&cr, &cr).sqrt() / 2.0;
            match idx.get(&e) { Some(&ix) => w[ix].1 += add, None => { idx.insert(e, w.len()); w.push((e, 0.0 + add)); } }
            m[r] += ar / 3.0;
        }
    }
    let mut nb = vec![Vec::new(); pts.len()];
    for &((p, q), wt) in &w { nb[p].push((q, wt)); nb[q].push((p, wt)); }
    (nb, m)
}
fn mesh_lambda(nb: &[Vec<(usize, f64)>], m: &[f64], inside: &[bool]) -> f64 { // inverse iteration + CG
    let nn = m.len();
    let l = |u: &[f64]| -> Vec<f64> { (0..nn).map(|i| if inside[i] { nb[i].iter().fold(0.0, |s, &(j, w)| s + w * (u[i] - u[j])) } else { 0.0 }).collect() };
    let mut u: Vec<f64> = inside.iter().map(|&s| if s { 1.0 } else { 0.0 }).collect();
    for _ in 0..40 {
        let b: Vec<f64> = (0..nn).map(|i| if inside[i] { m[i] * u[i] } else { 0.0 }).collect();
        let mut x = vec![0.0; nn]; let mut r = b.clone(); let mut p = r.clone(); let mut rr = r.iter().fold(0.0, |s, v| s + v * v);
        for _ in 0..2000 {
            let ap = l(&p); let al = rr / (0..nn).fold(0.0, |s, i| s + p[i] * ap[i]);
            for i in 0..nn { x[i] += al * p[i]; r[i] -= al * ap[i]; }
            let r2 = r.iter().fold(0.0, |s, v| s + v * v);
            if r2 < 1e-26 { break; }
            for i in 0..nn { p[i] = r[i] + r2 / rr * p[i]; } rr = r2;
        }
        let s = (0..nn).fold(0.0, |s, i| s + m[i] * x[i] * x[i]).sqrt(); u = x.iter().map(|v| v / s).collect();
    }
    let lu = l(&u); (0..nn).fold(0.0, |s, i| s + u[i] * lu[i]) // u is M-normalised
}
fn legendre(nu: f64, x: f64) -> f64 { // P_nu(x) as the series 2F1(-nu, nu+1; 1; (1-x)/2)
    let (z, mut term, mut tot) = ((1.0 - x) / 2.0, 1.0, 1.0);
    for k in 0..400 { let k = k as f64; term *= (k - nu) * (k + nu + 1.0) / ((k + 1.0) * (k + 1.0)) * z; tot += term; }
    tot
}
fn cap_lambda(radius: f64, angle: f64) -> f64 { // first zero in nu of P_nu(cos angle); lambda = nu(nu+1)/radius^2
    let mut nu = 0.0;
    while legendre(nu + 0.05, angle.cos()) > 0.0 { nu += 0.05; }
    let (mut lo, mut hi) = (nu, nu + 0.05);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if legendre(mid, angle.cos()) > 0.0 { lo = mid } else { hi = mid } }
    lo * (lo + 1.0) / radius.powi(2)
}
fn j0(x: f64) -> f64 {
    let mut s = 0.0; let mut fact = 1.0;
    for k in 0..40 { if k > 0 { fact *= k as f64; } s += (if k % 2 == 0 { 1.0 } else { -1.0 }) * (x / 2.0).powf(2.0 * k as f64) / (fact * fact); }
    s
}
fn main() {
    let (mut lo, mut hi) = (2.0, 3.0);
    for _ in 0..60 { let mid = (lo + hi) / 2.0; if j0(mid) > 0.0 { lo = mid } else { hi = mid } }
    let j01 = lo;
    println!("panel: R = {} m, cap angle phi0 = {} rad = 60 deg, edge distance a = {} m", f6(R), f6(P0), f6(A_GEO));
    let area_exact = 2.0 * PI * R * R * (1.0 - P0.cos()); let nq = 2000; let rho = R * P0.sin();
    let area_polar = (0..nq).fold(0.0, |s, i| s + 2.0 * PI * R * R * ((i as f64 + 0.5) * P0 / nq as f64).sin() * P0 / nq as f64);
    let area_graph = (0..nq).fold(0.0, |s, i| { let r = (i as f64 + 0.5) * rho / nq as f64; s + 2.0 * PI * r * R / (R * R - r * r).sqrt() * rho / nq as f64 });
    println!("1 - cos phi0 = {} ; area closed form 2 pi R^2 (1 - cos phi0) = {} m^2", f6(1.0 - P0.cos()), f6(area_exact));
    println!("area chart (phi, theta), sum of sqrt det g = {}", f6(area_polar));
    println!("area chart (x, y), sum of sqrt det g = {}", f6(area_graph));
    println!("flat disc radius a: area = {} edge = {} m; cap edge = {} m", f6(PI * A_GEO.powi(2)), f6(2.0 * PI * A_GEO), f6(2.0 * PI * rho));
    let g30 = polar(PI / 6.0, 0.0);
    println!("sqrt det g at phi = 30 deg, chart (phi, theta) = {}", f6((g30.0 * g30.2).sqrt()));
    let ex = -2.0 * (PI / 6.0).cos() / R; let lbp = lb(polar, z_polar, PI / 6.0, 0.0); let lbg = lb(graph, z_graph, 0.5, 0.0);
    println!("at phi = 30 deg: z = {} m, z_phi = {} m, cot(phi) = {}", f6(z_polar(PI / 6.0, 0.0)), f6(-R * (PI / 6.0).sin()), f6(1.0 / (PI / 6.0).tan()));
    println!("Delta_g z exact -2 z / R^2 = {} per m", f6(ex));
    println!("Delta_g z chart (phi, theta) = {}  chart (x, y) = {}", f6(lbp), f6(lbg));
    let p = PI / 6.0; let bend = (z_polar(p + H, 0.0) - 2.0 * z_polar(p, 0.0) + z_polar(p - H, 0.0)) / (H * H) / R.powi(2);
    let spread = (1.0 / p.tan()) * (z_polar(p + H, 0.0) - z_polar(p - H, 0.0)) / (2.0 * H) / R.powi(2);
    println!("bend term z_phiphi / R^2 = {}  spread term cot(phi) z_phi / R^2 = {}", f6(bend), f6(spread));
    let mut res: HashMap<usize, (f64, f64, f64)> = HashMap::new();
    for &n in &[8usize, 16] {
        let (pts, rings, tris) = mesh(n); let (nb, m) = cot_laplacian(&pts, &tris); let v = rings[n / 2][0];
        let lz = -nb[v].iter().fold(0.0, |s, &(j, w)| s + w * (pts[v][2] - pts[j][2])) / m[v];
        let mut inside = vec![true; pts.len()];
        for &i in &rings[n] { inside[i] = false; }
        let r = (m.iter().fold(0.0, |s, x| s + x), lz, mesh_lambda(&nb, &m, &inside)); res.insert(n, r);
        println!("mesh n = {}: {} points {} triangles; area {} err {}; Delta_g z {} err {}", n, pts.len(), tris.len(), f6(r.0), f6(area_exact - r.0), f6(lz), f6(lz - ex));
    }
    let lam = cap_lambda(R, P0); let lam_flat = (j01 / A_GEO).powi(2);
    for n in [8usize, 16] { println!("mesh n = {}: lambda1 = {} per m^2, err {}", n, f6(res[&n].2), f6(res[&n].2 - lam)); }
    println!("lambda1 cap, Legendre series = {} per m^2; flat disc (j01/a)^2 = {} with j01 = {}", f6(lam), f6(lam_flat), f6(j01));
    let half = |l: f64, k: f64| 2f64.ln() / (k * l) / 60.0;
    println!("cap / flat disc: area ratio {} ; lambda1 ratio flat / cap {}", f6(area_exact / (PI * A_GEO.powi(2))), f6(lam_flat / lam));
    println!("ln 2 = {} ; kappa lambda1 = {} per s; half-life {:.2} s", f6(2f64.ln()), format!("{:.10}", KAPPA * lam), half(lam, KAPPA) * 60.0);
    println!("half-life of the slowest pattern, kappa = 1e-4 m^2/s: cap {:.2} min, flat disc {:.2} min", half(lam, KAPPA), half(lam_flat, KAPPA));
    let row = |l: f64| (0..7).map(|k| format!("{:.2}", T0 * (-KAPPA * l * 600.0 * k as f64).exp())).collect::<Vec<_>>().join(" ");
    println!("chart minutes 0..60: cap {}", row(lam));
    println!("chart minutes 0..60: flat {}", row(lam_flat));
    println!("break: area with sqrt det g dropped, chart (phi, theta) = {} m^2", f6(2.0 * PI * R * R * P0));
    let (fp, fg) = (flat(z_polar, PI / 6.0, 0.0) / R.powi(2), flat(z_graph, 0.5, 0.0));
    println!("break: flat Laplacian of z, chart (phi, theta) / R^2 = {}  chart (x, y) = {}", f6(fp), f6(fg));
    let hgt = (PI / 6.0).tan(); // edge (-1,0,0)-(1,0,0), apexes (0, +-hgt, 0): both angles facing it are 120 deg
    let w_obt = cot_laplacian(&[[-1.0, 0.0, 0.0], [1.0, 0.0, 0.0], [0.0, hgt, 0.0], [0.0, -hgt, 0.0]], &[[0, 1, 2], [1, 0, 3]]).0[0].iter().find(|e| e.0 == 1).unwrap().1;
    println!("break: edge weight with two 120 deg opposite angles = {}", f6(w_obt));
    let (lam_h, lam_10) = (cap_lambda(R, PI / 2.0), cap_lambda(10.0, A_GEO / 10.0));
    println!("try: hemisphere lambda1 = {} ; R = 10 m, same a: lambda1 = {} ; steel kappa 1.2e-5: half-life {:.2} min", f6(lam_h), f6(lam_10), half(lam, 1.2e-5));
    assert!((area_polar - area_exact).abs() < 1e-6 && (area_graph - area_exact).abs() < 1e-5); // two charts, one area
    assert!((lbp - ex).abs() < 1e-5 && (lbg - ex).abs() < 1e-5 && (bend + spread - ex).abs() < 1e-5);
    let (e8, e16) = ((res[&8].1 - ex).abs(), (res[&16].1 - ex).abs());
    assert!(e16 < e8 / 3.0 && e8 / 3.0 < 0.02); // mesh converges, order 2
    assert!((res[&16].0 - area_exact).abs() < (res[&8].0 - area_exact).abs() / 3.0);
    let (l8, l16) = ((res[&8].2 - lam).abs(), (res[&16].2 - lam).abs());
    assert!(l16 < l8 / 3.0 && l8 / 3.0 < 0.05); // mesh lambda -> series lambda
    assert!((lam_h - 2.0 / R.powi(2)).abs() < 1e-9 && lam < lam_10 && lam_10 < lam_flat);
    assert!((fp - ex).abs() > 0.5 && (fg - fp).abs() > 1.0 && (w_obt + 1.0 / 3f64.sqrt()).abs() < 1e-9); // the mistakes are wrong
    println!("ALL CHECKS PASS");
}
