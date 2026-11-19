// Ricci and scalar curvature: contract the curvature tensor, then compare a small ball with the flat answer.
use std::f64::consts::PI;

const R: f64 = 30.0; // the dome's radius of curvature, m
const RP: f64 = 5.0; // patch radius, measured along the roof from the top, m
type M = Vec<Vec<f64>>;

fn sphere_chart(p: &[f64]) -> M { // polar angle phi from the top, longitude theta
    vec![vec![R * R, 0.0], vec![0.0, (R * p[0].sin()).powi(2)]]
}
fn graph_chart(p: &[f64]) -> M { // x, y in metres on the floor plan
    let w = R * R - p[0] * p[0] - p[1] * p[1];
    vec![vec![1.0 + p[0] * p[0] / w, p[0] * p[1] / w], vec![p[0] * p[1] / w, 1.0 + p[1] * p[1] / w]]
}
fn saddle_chart(p: &[f64]) -> M { // half-plane chart of the hyperbolic plane, curvature -1/R^2
    let c = R * R / (p[1] * p[1]);
    vec![vec![c, 0.0], vec![0.0, c]]
}
fn stack_chart(p: &[f64]) -> M { // dome directions phi, theta plus one flat direction t (m)
    vec![vec![R * R, 0.0, 0.0], vec![0.0, (R * p[0].sin()).powi(2), 0.0], vec![0.0, 0.0, 1.0]]
}

fn inverse(g: &M) -> M { // 2x2 or 3x3 inverse by cofactors
    if g.len() == 2 {
        let d = g[0][0] * g[1][1] - g[0][1] * g[1][0];
        return vec![vec![g[1][1] / d, -g[0][1] / d], vec![-g[1][0] / d, g[0][0] / d]];
    }
    let c: M = (0..3).map(|i| (0..3).map(|j| g[(j + 1) % 3][(i + 1) % 3] * g[(j + 2) % 3][(i + 2) % 3]
        - g[(j + 1) % 3][(i + 2) % 3] * g[(j + 2) % 3][(i + 1) % 3]).collect()).collect();
    let d = g[0][0] * c[0][0] + g[0][1] * c[1][0] + g[0][2] * c[2][0];
    c.iter().map(|row| row.iter().map(|x| x / d).collect()).collect()
}

fn shift(p: &[f64], i: usize, s: f64) -> Vec<f64> {
    let mut q = p.to_vec(); q[i] += s; q
}

type G3 = Vec<Vec<Vec<f64>>>;
fn christoffel(chart: fn(&[f64]) -> M, p: &[f64], h: f64) -> G3 { // G[l][j][k]
    let n = p.len();
    let gi = inverse(&chart(p));
    let (up, dn): (Vec<M>, Vec<M>) = (0..n).map(|m| (chart(&shift(p, m, h)), chart(&shift(p, m, -h)))).unzip();
    let dg = |m: usize, i: usize, j: usize| (up[m][i][j] - dn[m][i][j]) / (2.0 * h);
    (0..n).map(|l| (0..n).map(|j| (0..n).map(|k| 0.5 * (0..n).map(|m|
        gi[l][m] * (dg(j, m, k) + dg(k, m, j) - dg(m, j, k))).sum::<f64>()).collect()).collect()).collect()
}

fn ricci(chart: fn(&[f64]) -> M, p: &[f64], h: f64) -> (M, f64) { // rm(l, i, j, k) = Rm^l_kij; Ric_jk = Rm^i_jik
    let n = p.len();
    let g = christoffel(chart, p, h);
    let dgam: Vec<G3> = (0..n).map(|i| {
        let (a, b) = (christoffel(chart, &shift(p, i, h), h), christoffel(chart, &shift(p, i, -h), h));
        (0..n).map(|l| (0..n).map(|j| (0..n).map(|k| (a[l][j][k] - b[l][j][k]) / (2.0 * h)).collect()).collect()).collect()
    }).collect();
    let rm = |l: usize, i: usize, j: usize, k: usize| {
        let mut s = dgam[i][l][j][k] - dgam[j][l][i][k];
        for m in 0..n { s += g[l][i][m] * g[m][j][k] - g[l][j][m] * g[m][i][k]; }
        s
    };
    let ric: M = (0..n).map(|j| (0..n).map(|k| (0..n).map(|i| rm(i, i, k, j)).sum()).collect()).collect();
    let gi = inverse(&chart(p));
    let s = (0..n).map(|j| (0..n).map(|k| gi[j][k] * ric[j][k]).sum::<f64>()).sum();
    (ric, s)
}

fn show(label: &str, v: f64, d: usize) {
    let v = if v.abs() < 5e-12 { 0.0 } else { v };
    println!("{:<40}{:>16.*}", label, d, v);
}
fn cap(s: f64) -> f64 { 2.0 * PI * R * R * (1.0 - (s / R).cos()) } // area within distance s of the top
fn simpson_w(i: usize, n: usize) -> f64 { if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 } }
fn cap_by_chart(s: f64, n: usize) -> f64 { // integrate sqrt(det g) over the graph chart's disc
    let (rho, mut tot) = (R * (s / R).sin(), 0.0);
    for i in 0..=n {
        let q = rho * i as f64 / n as f64;
        let g = graph_chart(&[q * (0.7f64).cos(), q * (0.7f64).sin()]);
        tot += simpson_w(i, n) * (g[0][0] * g[1][1] - g[0][1].powi(2)).sqrt() * q;
    }
    2.0 * PI * rho / n as f64 / 3.0 * tot
}
fn ball3(s: f64, n: usize) -> f64 { // Simpson over t of the dome cap at radius sqrt(s^2 - t^2)
    let hh = 2.0 * s / n as f64;
    let tot: f64 = (0..=n).map(|i| {
        let t = -s + i as f64 * hh;
        cap((s * s - t * t).max(0.0).sqrt()) * simpson_w(i, n)
    }).sum();
    hh / 3.0 * tot
}

fn main() {
    let r = RP;
    let (phi0, th0) = (0.5f64, 0.3f64);
    let (x0, y0) = (R * phi0.sin() * th0.cos(), R * phi0.sin() * th0.sin());
    let (ric_a, sa) = ricci(sphere_chart, &[phi0, th0], 1e-4);
    let (ric_b, sb) = ricci(graph_chart, &[x0, y0], 1e-2);
    let gb = graph_chart(&[x0, y0]);
    show("by hand: Rm^phi_thphth = sin^2 phi", phi0.sin().powi(2), 6); show("sphere chart Ric_phiphi", ric_a[0][0], 6);
    show("sphere chart Ric_thetatheta", ric_a[1][1], 6); show("sphere chart Ric_phitheta", ric_a[0][1], 6);
    show("graph chart Ric_xx, 1/m^2", ric_b[0][0], 8); show("graph chart Ric_xy, 1/m^2", ric_b[0][1], 8);
    show("graph chart g_xx * K, 1/m^2", gb[0][0] / R.powi(2), 8);
    show("S, sphere chart, 1/m^2", sa, 8); show("S, graph chart, 1/m^2", sb, 8);
    show("S = 2K = 2/R^2, 1/m^2", 2.0 / R.powi(2), 8);
    let (_, sh) = ricci(saddle_chart, &[0.0, 40.0], 1e-2);
    show("S, saddle (hyperbolic) chart, 1/m^2", sh, 8);

    let (flat, exact, chart_area) = (PI * r * r, cap(r), cap_by_chart(r, 200));
    let pred = flat * (1.0 - sb * r * r / 24.0);
    show("fraction missing, S r^2 / 24", 2.0 / R.powi(2) * r * r / 24.0, 8);
    show("flat disc pi r^2, m^2", flat, 4); show("exact cap area, m^2", exact, 4);
    show("chart integral area, m^2", chart_area, 4); show("Ricci prediction, m^2", pred, 4);
    show("missing area, exact, m^2", flat - exact, 4); show("missing area, predicted, m^2", flat - pred, 4);
    show("prediction error, m^2", pred - exact, 6);
    let kest = 12.0 * (flat - exact) / (PI * r.powi(4));
    show("radius read back from the area, m", 1.0 / kest.sqrt(), 4);
    show("Earth, 1000 km disc, missing km^2", PI * 1000f64.powi(2) - 2.0 * PI * 6371f64.powi(2) * (1.0 - (1000.0f64 / 6371.0).cos()), 1);

    let (ric3, s3) = ricci(stack_chart, &[phi0, th0, 0.0], 1e-4);
    let ric_dir = |v: [f64; 3]| -> f64 {
        let mut s = 0.0;
        for j in 0..3 { for k in 0..3 { s += ric3[j][k] * v[j] * v[k]; } }
        s
    };
    show("3D Ric, along the dome, 1/m^2", ric_dir([1.0 / R, 0.0, 0.0]), 8);
    show("3D Ric, along t, 1/m^2", ric_dir([0.0, 0.0, 1.0]), 8);
    show("3D Ric, tilted 45 degrees, 1/m^2", ric_dir([1.0 / (R * 2f64.sqrt()), 0.0, 1.0 / 2f64.sqrt()]), 8);
    let mut avg = 0.0; // Simpson in z = cos(angle from t), 8 midpoints around
    for a in 0..21 {
        let z = -1.0 + a as f64 / 10.0;
        for b in 0..8 {
            let v = 2.0 * PI * (b as f64 + 0.5) / 8.0;
            let e = [(1.0 - z * z).sqrt() * v.cos(), (1.0 - z * z).sqrt() * v.sin(), z];
            avg += simpson_w(a, 20) / 30.0 / 2.0 / 8.0 * ric_dir([e[0] / R, e[1] / (R * phi0.sin()), e[2]]);
        }
    }
    show("average Ric over all directions", avg, 8); show("S / 3, 1/m^2", s3 / 3.0, 8);
    let (flat3, ex3) = (4.0 / 3.0 * PI * r.powi(3), ball3(r, 400));
    show("3D flat ball, m^3", flat3, 3); show("3D exact ball, m^3", ex3, 3);
    show("3D Ricci prediction, m^3", flat3 * (1.0 - s3 * r * r / 30.0), 3);

    println!("parts of Rm and of Ric, n = 2, 3, 4: {}", [2u32, 3, 4].map(|n| format!("{}/{}", n * n * (n * n - 1) / 12, n * (n + 1) / 2)).join("  "));
    show("wrong: divide by 6, not 24, m^2", flat * (1.0 - sb * r * r / 6.0), 4);
    show("wrong: S taken as K, m^2", flat * (1.0 - (sb / 2.0) * r * r / 24.0), 4);
    show("wrong: sign flipped, m^2", flat * (1.0 + sb * r * r / 24.0), 4);
    let big = PI * R; show("whole sphere, r = pi R, m", big, 2);
    show("whole sphere, exact, m^2", cap(big), 2); show("whole sphere, prediction, m^2", PI * big * big * (1.0 - sb * big * big / 24.0), 2);
    show("try: saddle disc, exact, m^2", 2.0 * PI * R * R * ((r / R).cosh() - 1.0), 4);
    show("try: R = 15 m, exact, m^2", 2.0 * PI * 225.0 * (1.0 - (r / 15.0).cos()), 4);

    let rs: Vec<f64> = (1..10).map(|i| 10.0 * i as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64, d: usize| rs.iter().map(|&s| format!("{:6.*}", d, f(s))).collect::<Vec<_>>().join(" ");
    println!("chart r  {}", row(&|s| s, 0));
    println!("exact    {}", row(&|s| cap(s) / (PI * s * s), 3));
    println!("predict  {}", row(&|s| 1.0 - sb * s * s / 24.0, 3));

    assert!((sa - 2.0 / R.powi(2)).abs() < 1e-9, "sphere chart S against 2/R^2");
    assert!((sb - sa).abs() < 1e-9, "S agrees in two charts");
    assert!((sh + 2.0 / R.powi(2)).abs() < 1e-8, "saddle has S = -2/R^2");
    assert!((chart_area - exact).abs() < 1e-6, "chart integral against closed form");
    assert!(((exact - pred) - flat * (r / R).powi(4) / 360.0).abs() < 1e-6, "prediction misses only the next term");
    assert!((avg - s3 / 3.0).abs() < 1e-12, "direction average of Ric is S/n");
    assert!((ex3 - flat3 * (1.0 - s3 * r * r / 30.0)).abs() < 0.01, "3D ball against S r^2 / 30");
    assert!((ric_b[0][0] - gb[0][0] / R.powi(2)).abs() < 1e-9, "on a surface Ric = K g");
    assert!((ric_a[1][1] - phi0.sin().powi(2)).abs() < 1e-6, "Ric_thetatheta against the hand contraction");
    println!("ALL CHECKS PASS");
}
