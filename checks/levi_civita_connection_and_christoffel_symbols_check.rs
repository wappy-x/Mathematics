// Levi-Civita connection -- the same check as the Python, in Rust.  No crates.
// The globe is a sphere of radius 6371 km.  Its Christoffel symbols at London
// come by three roads: the metric formula with numerical partials, the closed
// form, and the 3-D surface (tangential part of second derivatives).  Then the
// geometric number, how hard a due-east course bends, comes from two charts.
const R: f64 = 6371.0;                     // km
const LAT: f64 = 51.5074;                  // London's latitude, degrees north
const H: f64 = 1e-4;                       // step for the numerical partials, radians
type M2 = [[f64; 2]; 2];
type Gam = [[[f64; 2]; 2]; 2];

fn clean(x: f64) -> f64 { if x.abs() < 5e-10 { 0.0 } else { x } }

fn polar(p: [f64; 2]) -> M2 {              // chart 1: (phi, theta) -> g_ij
    [[R * R, 0.0], [0.0, (R * p[0].sin()).powi(2)]]
}

fn mercator(p: [f64; 2]) -> M2 {           // chart 2: (x, y) = (longitude, Mercator height)
    let s = R / p[1].cosh();
    [[s * s, 0.0], [0.0, s * s]]
}

fn christoffel(metric: fn([f64; 2]) -> M2, p: [f64; 2], half: f64, sign: f64) -> Gam {
    let g = metric(p);
    let det = g[0][0] * g[1][1] - g[0][1] * g[1][0];
    let gi = [[g[1][1] / det, -g[0][1] / det], [-g[1][0] / det, g[0][0] / det]];
    let mut dg = [[[0.0; 2]; 2]; 2];       // dg[l][i][j] = partial_l of g_ij
    for l in 0..2 {
        let (mut up, mut dn) = (p, p);
        up[l] += H;
        dn[l] -= H;
        let (gu, gd) = (metric(up), metric(dn));
        for i in 0..2 { for j in 0..2 { dg[l][i][j] = (gu[i][j] - gd[i][j]) / (2.0 * H) } }
    }
    let mut out = [[[0.0; 2]; 2]; 2];
    for k in 0..2 { for i in 0..2 { for j in 0..2 {
        let mut t = 0.0;
        for l in 0..2 { t += half * gi[k][l] * (dg[i][j][l] + dg[j][i][l] + sign * dg[l][i][j]) }
        out[k][i][j] = clean(t);
    } } }
    out
}

fn embed(p: [f64; 2]) -> [f64; 3] {        // the globe in space, km
    [R * p[0].sin() * p[1].cos(), R * p[0].sin() * p[1].sin(), R * p[0].cos()]
}

fn d1(p: [f64; 2], i: usize) -> [f64; 3] {
    let (mut up, mut dn) = (p, p);
    up[i] += H;
    dn[i] -= H;
    let (a, b) = (embed(up), embed(dn));
    [0, 1, 2].map(|m| (a[m] - b[m]) / (2.0 * H))
}

fn d2(p: [f64; 2], i: usize, j: usize) -> [f64; 3] {
    let (mut up, mut dn) = (p, p);
    up[i] += H;
    dn[i] -= H;
    let (a, b) = (d1(up, j), d1(dn, j));
    [0, 1, 2].map(|m| (a[m] - b[m]) / (2.0 * H))
}

fn dot(a: [f64; 3], b: [f64; 3]) -> f64 { a[0] * b[0] + a[1] * b[1] + a[2] * b[2] }

fn from_outside(p: [f64; 2]) -> Gam {      // road 3: never touches the metric formula
    let r = [d1(p, 0), d1(p, 1)];
    let gg = [[dot(r[0], r[0]), dot(r[0], r[1])], [dot(r[1], r[0]), dot(r[1], r[1])]];
    let det = gg[0][0] * gg[1][1] - gg[0][1] * gg[0][1];
    let mut out = [[[0.0; 2]; 2]; 2];
    for i in 0..2 { for j in 0..2 {
        let rij = d2(p, i, j);
        let (b0, b1) = (dot(rij, r[0]), dot(rij, r[1]));
        out[0][i][j] = clean((gg[1][1] * b0 - gg[0][1] * b1) / det);
        out[1][i][j] = clean((gg[0][0] * b1 - gg[0][1] * b0) / det);
    } }
    out
}

fn bend(metric: fn([f64; 2]) -> M2, gam: &Gam, p: [f64; 2], a: usize) -> (f64, f64) {
    let (g, b) = (metric(p), 1 - a);       // geodesic curvature along coordinate a; metric diagonal
    let acc = gam[b][a][a] / g[a][a];      // the only sideways part of grad_e e, e = d_a / |d_a|
    (g[b][b].sqrt() * acc.abs(), acc)
}

fn deg1000(k: f64) -> f64 { (k * 1000.0).to_degrees() }   // turning, degrees per 1000 km flown

fn main() {
    let names = ["phi", "theta"];
    let phi = (90.0 - LAT).to_radians();   // polar angle, measured down from the North Pole
    let gp = christoffel(polar, [phi, 0.0], 0.5, -1.0);
    let ge = from_outside([phi, 0.0]);
    let (s, c) = (phi.sin(), phi.cos());
    let closed: Gam = [[[0.0, 0.0], [0.0, -s * c]], [[0.0, c / s], [c / s, 0.0]]];
    let y = LAT.to_radians().tan().asinh();
    let gm = christoffel(mercator, [0.0, y], 0.5, -1.0);
    println!("London: latitude {:.4} N, polar angle phi = {:.4} deg = {:.6} rad", LAT, 90.0 - LAT, phi);
    println!("sin phi = {:.6}, cos phi = {:.6}", s, c);
    println!("metric: g_phiphi = {:.0} km^2, g_thetatheta = {:.0} km^2", R * R, (R * s).powi(2));
    println!("partial_phi g_thetatheta = 2 R^2 sin cos = {:.0} km^2", 2.0 * R * R * s * c);
    println!("Gamma^k_ij, chart (phi, theta): formula | from 3-D | closed form");
    let mut worst: f64 = 0.0;
    for k in 0..2 { for i in 0..2 { for j in i..2 {
        let (a, b, e) = (gp[k][i][j], ge[k][i][j], closed[k][i][j]);
        worst = worst.max((a - e).abs()).max((b - e).abs());
        println!("  Gamma^{}_{}{} = {:+.6} | {:+.6} | {:+.6}", names[k], names[i], names[j], a, b, e);
    } } }
    let (n, mut unknowns, mut equations) = (2, 0, 0);
    for _k in 0..n { for i in 0..n { for j in 0..n { if i <= j { unknowns += 1 } } } }    // Gamma^k_ij = Gamma^k_ji
    for _l in 0..n { for i in 0..n { for j in 0..n { if i <= j { equations += 1 } } } }   // one per rate d_l g_ij
    println!("unknowns after symmetry {}, equations from keeping lengths {}", unknowns, equations);
    let g0 = polar([phi, 0.0]);
    let mut comp: f64 = 0.0;
    for k in 0..2 {                                                // d_k g_ij against the symbols, both directions
        let (mut up, mut dn) = ([phi, 0.0], [phi, 0.0]);
        up[k] += H;
        dn[k] -= H;
        let (gu, gd) = (polar(up), polar(dn));
        for i in 0..2 { for j in 0..2 {
            let mut rhs = 0.0;
            for l in 0..2 { rhs += gp[l][k][i] * g0[l][j] + gp[l][k][j] * g0[i][l] }
            comp = comp.max(((gu[i][j] - gd[i][j]) / (2.0 * H) - rhs).abs() / (R * R));
        } }
    }
    let mn = ["x", "y"];
    println!("Mercator chart at London: y = {:.6}, tanh y = {:.6}", y, y.tanh());
    for (k, i, j) in [(0, 0, 1), (1, 0, 0), (1, 1, 1), (0, 0, 0)] {
        println!("  Gamma^{}_{}{} = {:+.6}", mn[k], mn[i], mn[j], gm[k][i][j]);
    }
    let (kp, ap) = bend(polar, &gp, [phi, 0.0], 1);
    let (km, am) = bend(mercator, &gm, [0.0, y], 0);
    let (kx, _) = bend(polar, &ge, [phi, 0.0], 1);
    let kc = c / (s * R);
    println!("due-east course at London bends toward the pole: {}", if ap < 0.0 && am > 0.0 { "yes" } else { "no" });
    println!("geodesic curvature, per km: polar chart {:.8} | Mercator {:.8} | 3-D {:.8} | cot(phi)/R {:.8}", kp, km, kx, kc);
    println!("turning over 1000 km: {:.5} rad = {:.2} deg", kp * 1000.0, deg1000(kp));
    println!("latitude, deg | turning, deg per 1000 km");
    for lat in (0..90).step_by(10) {
        let p = (90.0 - lat as f64).to_radians();
        println!("  {:2} | {:.2}", lat, deg1000(bend(polar, &christoffel(polar, [p, 0.0], 0.5, -1.0), [p, 0.0], 1).0));
    }
    let plain = bend(polar, &[[[0.0; 2]; 2]; 2], [phi, 0.0], 1).0;
    let k2 = bend(polar, &christoffel(polar, [phi, 0.0], 1.0, -1.0), [phi, 0.0], 1);
    let k3 = christoffel(polar, [phi, 0.0], 0.5, 1.0);
    println!("mistake 1, plain partials, no Gamma: {:.2} deg per 1000 km, a straight parallel", deg1000(plain));
    println!("mistake 2, the 1/2 dropped: {:.8} per km, {:.2} deg per 1000 km", k2.0, deg1000(k2.0));
    println!("mistake 3, last sign flipped: Gamma^phi_thetatheta = {:+.6}, course bends toward the equator", k3[0][1][1]);
    println!("mistake 4, components read as shape: Gamma^phi_phiphi = {:+.6} but Gamma^y_yy = {:+.6}", gp[0][0][0], gm[1][1][1]);
    for d in [1.0_f64, 0.1] {
        println!("mistake 5, near the pole: polar angle {:.1} deg, Gamma^theta_phitheta = {:.2}", d,
                 christoffel(polar, [d.to_radians(), 0.0], 0.5, -1.0)[1][0][1]);
    }
    let pole = polar([0.0, 0.0]);
    println!("  at the pole det g = {:.1}: g^ij does not exist", clean(pole[0][0] * pole[1][1]));
    assert!(worst < 1e-7);                                         // formula and 3-D agree with the closed form
    assert!((kp - kc).abs() < 1e-10);                              // polar chart against cot(phi)/R
    assert!((km - kc).abs() < 1e-10);                              // Mercator chart: same bending
    assert!((kx - kc).abs() < 1e-10);                              // 3-D road: same bending
    assert!(comp < 1e-8);                                          // the symbols keep lengths
    assert!((0..2).all(|k| gp[k][0][1] == gp[k][1][0]));           // no twist: symmetric
    assert!((k2.0 - 2.0 * kc).abs() < 1e-10);                      // dropping the 1/2 doubles it
    assert!(k3[0][1][1] > 0.0);                                    // the flipped sign points it south
    println!("ALL CHECKS PASS");
}
