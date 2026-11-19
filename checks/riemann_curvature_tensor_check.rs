// Riemann curvature tensor of the globe: the check behind the card. Rust std only.
// Five roads to one number, the sectional curvature at London: a closed form by hand,
// a finite-difference tensor in two different charts, a vector carried round London's
// latitude circle, and the shortfall of a circle's circumference against a flat chart.
use std::f64::consts::PI;

const R: f64 = 6371.0; // Earth's radius in km (the globe is modelled as a sphere)
type M = [[f64; 2]; 2];
type G3 = [[[f64; 2]; 2]; 2];

fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn fx(x: f64, d: usize) -> String {
    let s = format!("{:.*}", d, x);
    if s.starts_with('-') && s[1..].parse::<f64>().unwrap() == 0.0 { s[1..].to_string() } else { s }
}
fn shift(x: [f64; 2], k: usize, s: f64) -> [f64; 2] { let mut y = x; y[k] += s; y }

fn christoffel(metric: &dyn Fn([f64; 2]) -> M, x: [f64; 2], h: f64) -> G3 {
    let g = metric(x);
    let det = g[0][0] * g[1][1] - g[0][1] * g[1][0];
    let gi = [[g[1][1] / det, -g[0][1] / det], [-g[1][0] / det, g[0][0] / det]];
    let (gp, gm) = ([metric(shift(x, 0, h)), metric(shift(x, 1, h))], [metric(shift(x, 0, -h)), metric(shift(x, 1, -h))]);
    let mut dg = [[[0.0; 2]; 2]; 2];
    for k in 0..2 { for i in 0..2 { for j in 0..2 { dg[k][i][j] = (gp[k][i][j] - gm[k][i][j]) / (2.0 * h); } } }
    let mut out = [[[0.0; 2]; 2]; 2];
    for a in 0..2 { for b in 0..2 { for c in 0..2 {
        let mut s = 0.0;
        for l in 0..2 { s += gi[a][l] * (dg[b][c][l] + dg[c][b][l] - dg[l][b][c]); }
        out[a][b][c] = 0.5 * s;
    } } }
    out
}

// returns (Rm(d1,d2,d2,d1), sectional curvature)
fn curvature(metric: &dyn Fn([f64; 2]) -> M, x: [f64; 2], h: f64) -> (f64, f64) {
    let g3 = christoffel(metric, x, h);
    let gp = [christoffel(metric, shift(x, 0, h), h), christoffel(metric, shift(x, 1, h), h)];
    let gm = [christoffel(metric, shift(x, 0, -h), h), christoffel(metric, shift(x, 1, -h), h)];
    let mut dg = [[[[0.0; 2]; 2]; 2]; 2];
    for k in 0..2 { for a in 0..2 { for b in 0..2 { for c in 0..2 {
        dg[k][a][b][c] = (gp[k][a][b][c] - gm[k][a][b][c]) / (2.0 * h);
    } } } }
    // R^a_bcd = d_c G^a_db - d_d G^a_cb + G^a_ce G^e_db - G^a_de G^e_cb
    let rup = |a: usize, b: usize, c: usize, d: usize| {
        let mut s = 0.0;
        for e in 0..2 { s += g3[a][c][e] * g3[e][d][b] - g3[a][d][e] * g3[e][c][b]; }
        dg[c][a][d][b] - dg[d][a][c][b] + s
    };
    let g = metric(x);
    let mut rm = 0.0;
    for e in 0..2 { rm += g[0][e] * rup(e, 1, 0, 1); }
    (rm, rm / (g[0][0] * g[1][1] - g[0][1] * g[0][1]))
}

fn sphere(x: [f64; 2]) -> M { let r = R * x[0].sin(); [[R * R, 0.0], [0.0, r * r]] } // chart A: (phi, theta)
fn stereo(x: [f64; 2]) -> M { // chart B: (u, v) in km
    let lam = 2.0 * R * R / (R * R + x[0] * x[0] + x[1] * x[1]);
    [[lam * lam, 0.0], [0.0, lam * lam]]
}
fn polar(x: [f64; 2]) -> M { [[1.0, 0.0], [0.0, x[0] * x[0]]] } // flat chart: (r, theta)

fn main() {
    let (lat, lon) = (51.5074f64, -0.1278f64); // London, degrees north and east
    let (phi, th) = ((90.0 - lat).to_radians(), lon.to_radians());
    let k = 1.0 / (R * R);
    let (r2, r4) = (R * R, R * R * R * R);
    println!("model: R = {:.1} km; London phi = {:.4} deg, theta = {:.4} deg", R, phi.to_degrees(), th.to_degrees());
    println!("target 1/R^2 = {} per km^2 = {} per m^2", sci(k, 4), sci(k * 1e-6, 4));

    // road 1: closed form, by hand
    let (s, c) = (phi.sin(), phi.cos());
    let (g_tt, g_pt) = (-s * c, c / s);
    let (dgam, quad) = (-(c * c - s * s), -g_tt * g_pt);
    let rup = dgam + quad;
    let (rm_a, det_a) = (r2 * rup, r4 * s * s);
    println!("road 1 by hand: sin phi = {:.6}, cos phi = {:.6}", s, c);
    println!("  Gamma^phi_thth = {:.6}, Gamma^th_phith = {:.6}", g_tt, g_pt);
    println!("  d_phi Gamma = {:.6}, Gamma*Gamma term = {:.6}, Rm^phi_thphth = {:.6}", dgam, quad, rup);
    println!("  Rm_1221 = {} km^2, det g = {} km^4, sec = {}", sci(rm_a, 4), sci(det_a, 4), sci(rm_a / det_a, 4));
    assert!((rup - s * s).abs() < 1e-12);
    assert!((rm_a / det_a - k).abs() < 1e-12 * k);

    // roads 2 and 3: the tensor from the metric alone, by finite differences, in two charts
    let rho = R * (phi / 2.0).tan();
    let pt_b = [rho * th.cos(), rho * th.sin()];
    println!("chart B point: u = {:.3} km, v = {:.3} km", pt_b[0], pt_b[1]);
    let charts: [(&str, &dyn Fn([f64; 2]) -> M, [f64; 2], [(f64, &str); 2]); 2] = [
        ("A (phi,theta)", &sphere, [phi, th], [(2e-3, "0.002"), (1e-3, "0.001")]),
        ("B stereographic", &stereo, pt_b, [(10.0, "10"), (5.0, "5")]),
    ];
    for (name, metric, pt, hs) in charts.iter() {
        let mut errs = [0.0; 2];
        for (i, (h, hl)) in hs.iter().enumerate() {
            let (rm, kk) = curvature(*metric, *pt, *h);
            errs[i] = (kk - k).abs() / k;
            println!("road chart {}, step {}: Rm_1221 = {}, sec*R^2 = {:.6}, rel err {}", name, hl, sci(rm, 4), kk * R * R, sci(errs[i], 1));
            assert!(errs[i] < 1e-5);
        }
        let ratio = errs[0] / errs[1];
        println!("  halving the step cuts the error by {:.1}", ratio);
        assert!(3.0 < ratio && ratio < 5.0);
    }
    let (rm_b, _) = curvature(&stereo, pt_b, 5.0);
    let lam = 2.0 * R * R / (R * R + rho * rho);
    let l4 = lam * lam * lam * lam;
    println!("  chart B by hand: lambda = {:.6}, Rm_1221 = lambda^4/R^2 = {} per km^2", lam, sci(l4 * k, 4));
    assert!((rm_b - l4 * k).abs() < 1e-5 * l4 * k);
    assert!((rm_b - rm_a).abs() > 1e6);

    // road 4: carry a vector round London's latitude circle (RK4), compare with K times cap area
    let carry = |n: usize| {
        let (mut a, mut b) = (1.0f64, 0.0f64); // components along unit south, unit east
        let f = |a: f64, b: f64| (c * b, -c * a);
        for _ in 0..n {
            let dt = 2.0 * PI / n as f64;
            let k1 = f(a, b); let k2 = f(a + dt / 2.0 * k1.0, b + dt / 2.0 * k1.1);
            let k3 = f(a + dt / 2.0 * k2.0, b + dt / 2.0 * k2.1);
            let k4 = f(a + dt * k3.0, b + dt * k3.1);
            a += dt / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
            b += dt / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        }
        b.atan2(a)
    };
    let area = 2.0 * PI * R * R * (1.0 - c);
    println!("road 4: cap north of London = {} km^2, sec * area = {:.4} deg", sci(area, 4), (area * k).to_degrees());
    for n in [24usize, 48] {
        let ang = carry(n);
        println!("  carried with {} steps: turned {:.4} deg, angle/area = {}", n, ang.to_degrees(), sci(ang / area, 4));
        assert!((ang - area * k).abs() < 1e-4);
    }
    let paris = 1.0 - (90.0f64 - 48.846).to_radians().cos();
    println!("  Foucault, Paris: swing plane turns {:.1} deg per sidereal day, holonomy {:.1} deg", 360.0 * (1.0 - paris), 360.0 * paris);

    // road 5: a circle of ground radius r round London, globe against flat chart
    for r in [500.0f64, 250.0] {
        let circ = 2.0 * PI * R * (r / R).sin();
        let est = 3.0 * (2.0 * PI * r - circ) / (PI * (r * r * r));
        println!("road 5: r = {:.0} km: flat 2 pi r = {:.3}, globe = {:.3}, short by {:.3} km, sec est = {}", r, 2.0 * PI * r, circ, 2.0 * PI * r - circ, sci(est, 4));
        assert!((est - k).abs() < 1e-3 * k);
    }

    // the flat chart: Christoffel symbols are not zero, the curvature is
    let (gpol, (_, k_p)) = (christoffel(&polar, [1000.0, 0.3], 1.0), curvature(&polar, [1000.0, 0.3], 1.0));
    println!("flat polar chart at r = 1000 km: Gamma^r_thth = {:.3} km, Gamma^th_rth = {:.6} per km, sec*R^2 = {}", gpol[0][1][1], gpol[1][0][1], fx(k_p * R * R, 6));
    assert!((gpol[0][1][1] + 1000.0).abs() < 1e-6);
    assert!(k_p.abs() < 1e-6 * k);

    // how many independent numbers the tensor holds: formula against a count of pairs
    for n in [2usize, 3, 4] {
        let nn = n * (n - 1) / 2; let (f, cnt) = (n * n * (n * n - 1) / 12, nn * (nn + 1) / 2 - n * (n - 1) * (n - 2) * (n - 3) / 24);
        println!("dimension {}: n^2(n^2-1)/12 = {}, plane pairs minus Bianchi = {}", n, f, cnt);
        assert_eq!(f, cnt);
    }

    // what breaks
    println!("break: drop the Gamma*Gamma term: sec = {} per km^2", sci(dgam * R * R / det_a, 4));
    println!("break: leave the index up: Rm^phi_thphth / det g = {} per km^4", sci(rup / det_a, 4));
    println!("break: report the component, not sec: {} km^2", sci(rm_a, 4));
    println!("break: other sign convention for Rm: sec = {} per km^2", sci(-k, 4));
    let den = (R * R) * (R * R) - (R * R) * (R * R); // X = Y = d_phi: |X|^2 |Y|^2 - g(X,Y)^2
    println!("break: X = Y, a plane of zero area: denominator = {:.1}, sec undefined", den);

    // try changing
    println!("try: Moon R = 1737.4 km: sec = {} per km^2", sci(1.0 / (1737.4f64 * 1737.4), 4));
    let s1 = 1.0f64.to_radians().sin();
    println!("try: phi = 1 deg: Rm_1221 = {:.1} km^2, sec = {}", R * R * s1 * s1, sci(R * R * s1 * s1 / (r4 * s1 * s1), 4));
    println!("try: triangle of area 1,000,000 km^2: angle excess = {:.3} deg", (1e6 * k).to_degrees());
    println!("survey triangle, 100 km sides: area {:.0} km^2, sec * area = {:.1} arcsec, law of cosines: {:.1} arcsec", 3f64.sqrt() / 4.0 * 1e4, (3f64.sqrt() / 4.0 * 1e4 * k).to_degrees() * 3600.0, (3.0 * ((100.0 / R).cos() / (1.0 + (100.0 / R).cos())).acos() - PI).to_degrees() * 3600.0);
    println!("ALL CHECKS PASS");
}
