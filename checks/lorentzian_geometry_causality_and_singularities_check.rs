// Lorentzian geometry: sort vectors by the sign of g(v, v), solve Friedmann for a matter universe,
// find the horizons of a spinning black hole, and check the focusing behind the singularity theorems.
use std::f64::consts::PI;

fn z(v: f64) -> f64 { if v.abs() < 5e-13 { 0.0 } else { v } } // print a tiny rounding leftover as 0
fn show(label: &str, v: f64, d: usize) { println!("{:<46}{:>14.*}", label, d, z(v)); }

// ---- 1. causal character in flat spacetime, in years and light-years, so c = 1 ----
fn eta(u: (f64, f64), v: (f64, f64)) -> f64 { -u.0 * v.0 + u.1 * v.1 }
fn boost(v: (f64, f64), beta: f64) -> (f64, f64) { // the same two events seen from a ship moving at speed beta
    let gam = 1.0 / (1.0 - beta * beta).sqrt();
    (gam * (v.0 - beta * v.1), gam * (v.1 - beta * v.0))
}
fn kind(q: f64) -> &'static str { if q < -1e-12 { "timelike" } else if q > 1e-12 { "spacelike" } else { "null" } }

// ---- 2. FLRW: Einstein tensor of -dt^2 + a(t)^2 (dx^2 + dy^2 + dz^2) from the metric alone ----
fn frw(expo: f64, p: &[f64; 4]) -> [f64; 4] { let a2 = p[0].powf(2.0 * expo); [-1.0, a2, a2, a2] }
fn shift(p: &[f64; 4], i: usize, s: f64) -> [f64; 4] { let mut q = *p; q[i] += s; q }
type G3 = [[[f64; 4]; 4]; 4];
fn christoffel(expo: f64, p: &[f64; 4], h: f64) -> G3 { // g diagonal
    let g = frw(expo, p);
    let mut dg = [[0.0; 4]; 4];
    for m in 0..4 {
        let (u, w) = (frw(expo, &shift(p, m, h)), frw(expo, &shift(p, m, -h)));
        for i in 0..4 { dg[m][i] = (u[i] - w[i]) / (2.0 * h); }
    }
    let d = |m: usize, i: usize, j: usize| if i == j { dg[m][i] } else { 0.0 };
    let mut out = [[[0.0; 4]; 4]; 4];
    for l in 0..4 { for j in 0..4 { for k in 0..4 { out[l][j][k] = 0.5 / g[l] * (d(j, l, k) + d(k, l, j) - d(l, j, k)); } } }
    out
}
fn einstein(expo: f64, p: &[f64; 4]) -> [f64; 4] { // Ric_bd = d_a G^a_bd - d_d G^a_ba + G^a_ae G^e_bd - G^a_de G^e_ba
    let (h, mut ric) = (1e-4, [0.0; 4]);
    let gm = christoffel(expo, p, h);
    let mut dg = [[[[0.0; 4]; 4]; 4]; 4];
    for i in 0..4 {
        let (u, w) = (christoffel(expo, &shift(p, i, h), h), christoffel(expo, &shift(p, i, -h), h));
        for l in 0..4 { for j in 0..4 { for k in 0..4 { dg[i][l][j][k] = (u[l][j][k] - w[l][j][k]) / (2.0 * h); } } }
    }
    for b in 0..4 { for a in 0..4 {
        let mut s = dg[a][a][b][b] - dg[b][a][b][a];
        for e in 0..4 { s += gm[a][a][e] * gm[e][b][b] - gm[a][b][e] * gm[e][b][a]; }
        ric[b] += s;
    } }
    let g = frw(expo, p);
    let sc: f64 = (0..4).map(|i| ric[i] / g[i]).sum();
    [0, 1, 2, 3].map(|i| ric[i] - 0.5 * sc * g[i])
}

// ---- 3. ages: H0 = 70 km/s per Mpc ----
const MPC_KM: f64 = 3.0856775814913673e19;
const GYR_S: f64 = 3.15576e16;
fn hubble_time(h0: f64) -> f64 { MPC_KM / h0 / GYR_S } // 1/H0 in billions of years
fn age_integral(om: f64, ol: f64, n: usize) -> f64 { // t0 H0 = integral of 2u^2/sqrt(Om + OL u^6), Simpson
    let f = |u: f64| 2.0 * u * u / (om + ol * u.powf(6.0)).sqrt();
    let s: f64 = (0..=n).map(|k| (if k == 0 || k == n { 1.0 } else if k % 2 == 1 { 4.0 } else { 2.0 }) * f(k as f64 / n as f64)).sum();
    s / (3.0 * n as f64)
}

// ---- 4. Raychaudhuri, run backwards: dTheta/dt = -Theta^2/3 - Ric(u,u), da/dt = a Theta/3 ----
fn back_to(a_stop: f64, h: f64) -> f64 { // units 1/H0; today a = 1, Theta = 3 H0; RK4 with time running back
    let f = |a: f64, th: f64| (-a * th / 3.0, th * th / 3.0 + 1.5 / a.powf(3.0));
    let (mut a, mut th, mut t) = (1.0f64, 3.0f64, 0.0f64);
    loop {
        let k1 = f(a, th);
        let k2 = f(a + h / 2.0 * k1.0, th + h / 2.0 * k1.1);
        let k3 = f(a + h / 2.0 * k2.0, th + h / 2.0 * k2.1);
        let k4 = f(a + h * k3.0, th + h * k3.1);
        let na = a + h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0);
        let nt = th + h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        if na < a_stop { return t + h * (a - a_stop) / (a - na); }
        a = na; th = nt; t += h;
    }
}

// ---- 5. Kerr black hole, G = c = 1, M = 1; phi down from the spin axis, theta round it ----
fn kerr(r: f64, ph: f64, b: f64) -> [f64; 4] { // g_tt, g_t-theta, g_theta-theta, g_rr
    let (s, d, s2) = (r * r + (b * ph.cos()).powi(2), r * r - 2.0 * r + b * b, ph.sin().powi(2));
    [-(1.0 - 2.0 * r / s), -2.0 * b * r * s2 / s, (r * r + b * b + 2.0 * b * b * r * s2 / s) * s2, s / d]
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) > 0.0 { lo = mid; } else { hi = mid; } }
    (lo + hi) / 2.0
}

fn main() {
    let vecs = [("ship at 0.6 c", (1.0, 0.6)), ("light pulse", (1.0, 1.0)), ("1 yr, 2 ly apart", (1.0, 2.0))];
    for (name, v) in vecs {
        let w = boost(v, 0.6);
        println!("{:<17} g = {:6.3} {:<9} | at 0.6 c: dt = {:6.3} dx = {:6.3} g = {:6.3}",
                 name, z(eta(v, v)), kind(eta(v, v)), z(w.0), z(w.1), z(eta(w, w)));
    }
    show("proper time of the ship per year, years", (-eta(vecs[0].1, vecs[0].1)).sqrt(), 3);
    let w8 = boost(vecs[2].1, 0.8);
    println!("try: the 2 ly pair seen at 0.8 c: dt = {:6.3}, g = {:6.3}", w8.0, eta(w8, w8));

    let p = [1.0, 0.3, 0.2, 0.1];
    for (expo, name) in [(2.0 / 3.0, "a = t^(2/3), dust"), (0.5, "a = t^(1/2), radiation")] {
        let gt = einstein(expo, &p);
        show(&format!("{}: G_tt at t = 1", name), gt[0], 6);
        show("  closed form 3 H^2 = 3 (expo / t)^2", 3.0 * expo * expo, 6);
        show(&format!("{}: G_xx at t = 1", name), gt[1], 6);
        show("  closed form -(2 a''/a + H^2) a^2", -(2.0 * expo * (expo - 1.0) + expo * expo), 6);
    }
    let (dust, rad) = (einstein(2.0 / 3.0, &p), einstein(0.5, &p));

    let (g_n, m_p) = (6.67430e-11, 1.67262192595e-27);
    let h0s = 70.0 / MPC_KM; // per second
    show("1 Mpc in millions of light-years", MPC_KM / 9.4607304725808e12 / 1e6, 4);
    show("Hubble time 1/H0, Gyr", hubble_time(70.0), 3);
    show("matter only: age 2/(3 H0), Gyr", 2.0 / 3.0 * hubble_time(70.0), 3);
    let rho_c = 3.0 * h0s * h0s / (8.0 * PI * g_n);
    show("critical density 3H^2/(8 pi G), 1e-27 kg/m^3", rho_c * 1e27, 4);
    show("  protons per cubic metre", rho_c / m_p, 2);
    show("matter only, H0 = 67.4: age, Gyr", 2.0 / 3.0 * hubble_time(67.4), 3);
    let lcdm = 2.0 / (3.0 * 0.685f64.sqrt()) * (0.685f64 / 0.315).sqrt().asinh() * hubble_time(67.4);
    show("with dark energy, H0 = 67.4: closed form, Gyr", lcdm, 3);
    show("with dark energy, H0 = 67.4: by integral, Gyr", age_integral(0.315, 0.685, 2000) * hubble_time(67.4), 3);
    show("measured age (Planck 2018), Gyr", 13.787, 3);
    show("Ric(u,u) today / H0^2, matter only", 1.5 * 1.0, 4);
    show("Ric(u,u) today / H0^2, with dark energy", 1.5 * (0.315 - 2.0 * 0.685), 4);

    let ray = back_to(0.01, 1e-5);
    let exact = 2.0 / 3.0 * (1.0 - 0.01f64.powf(1.5));
    show("back to a = 0.01: Raychaudhuri RK4, Gyr", ray * hubble_time(70.0), 5);
    show("back to a = 0.01: exact (2/3)(1 - a^1.5), Gyr", exact * hubble_time(70.0), 5);
    show("focusing bound 3/Theta = 1/H0, Gyr", hubble_time(70.0), 3);

    let b = 0.6;
    let det = |ph: f64| move |r: f64| { let k = kerr(r, ph, b); k[0] * k[2] - k[1] * k[1] };
    show("outer horizon M + sqrt(M^2 - b^2), M", 1.0 + (1.0 - b * b).sqrt(), 6);
    show("inner horizon M - sqrt(M^2 - b^2), M", 1.0 - (1.0 - b * b).sqrt(), 6);
    for ph in [PI / 2.0, PI / 3.0] {
        println!("  from the metric at phi = {:2.0} deg: outer {:.6} M, inner {:.6} M",
                 ph * 180.0 / PI, bisect(&det(ph), 1.0, 3.0), bisect(&det(ph), 0.01, 1.0));
    }
    for ph in [PI / 2.0, PI / 4.0] {
        show(&format!("ergosurface, phi = {:2.0} deg, closed form, M", ph * 180.0 / PI), 1.0 + (1.0 - (b * ph.cos()).powi(2)).sqrt(), 6);
        show("  from g_tt = 0, M", bisect(&|r| kerr(r, ph, b)[0], 1.0, 3.0), 6);
    }
    show("g_rr at r = 1.0 M (inside): d/dr is timelike", kerr(1.0, PI / 2.0, b)[3], 4);
    show("g_tt at r = 1.9 M (ergosphere): d/dt spacelike", kerr(1.9, PI / 2.0, b)[0], 6);
    show("g_tt at r = 2.5 M (outside): d/dt timelike", kerr(2.5, PI / 2.0, b)[0], 6);
    let mm = 10.0 * 1.3271244e20 / 299792458.0f64.powi(2) / 1000.0; // 10 Suns, in km
    show("10 Suns: M = GM/c^2, km", mm, 3);
    show("  outer horizon, km", (1.0 + (1.0 - b * b).sqrt()) * mm, 2);
    show("  inner horizon, km", (1.0 - (1.0 - b * b).sqrt()) * mm, 2);
    show("  ergosurface at the equator, km", 2.0 * mm, 2);
    let dmin = (0..=3000).map(|k| { let r = k as f64 / 1000.0; r * r - 2.0 * r + 1.44 }).fold(f64::INFINITY, f64::min);
    show("b = 1.2 M: smallest Delta = b^2 - M^2", dmin, 4);
    show("try: b = 0.9 M, outer horizon, M", 1.0 + (1.0f64 - 0.81).sqrt(), 6);
    show("try: b = 0.9 M, inner horizon, M", 1.0 - (1.0f64 - 0.81).sqrt(), 6);

    let (t0, th) = (2.0 / 3.0 * hubble_time(70.0), hubble_time(70.0));
    let row = |f: &dyn Fn(f64) -> String| (0..15).map(|t| f(t as f64)).collect::<Vec<_>>().join(" ");
    println!("chart Gyr ago {}", row(&|t| format!("{:5}", t as i64)));
    println!("matter        {}", row(&|t| format!("{:5.2}", (1.0 - t / t0).max(0.0).powf(2.0 / 3.0))));
    println!("coasting      {}", row(&|t| format!("{:5.2}", (1.0 - t / th).max(0.0))));

    assert!((dust[0] - 4.0 / 3.0).abs() < 1e-6 && dust[1].abs() < 1e-6, "dust: G_tt = 3H^2 and no pressure");
    assert!((rad[1] - 0.25).abs() < 1e-6, "radiation exponent leaves pressure G_xx = 1/4");
    assert!((age_integral(1.0, 0.0, 2000) - 2.0 / 3.0).abs() < 1e-12, "matter age by integral");
    assert!((age_integral(0.315, 0.685, 2000) * hubble_time(67.4) - lcdm).abs() < 1e-6, "dark-energy age, two roads");
    assert!((ray - exact).abs() < 1e-6 && ray < 1.0, "Raychaudhuri run back agrees, inside the focusing bound");
    assert!((bisect(&det(PI / 3.0), 1.0, 3.0) - 1.8).abs() < 1e-12 && (bisect(&det(PI / 2.0), 0.01, 1.0) - 0.2).abs() < 1e-12, "horizons");
    assert!((bisect(&|r| kerr(r, PI / 4.0, b)[0], 1.0, 3.0) - (1.0 + 0.82f64.sqrt())).abs() < 1e-12, "ergosurface");
    assert!((eta(w8, w8) - 3.0).abs() < 1e-12 && w8.0 < 0.0, "boost keeps g(v, v), reverses the spacelike order");
    println!("ALL CHECKS PASS");
}
