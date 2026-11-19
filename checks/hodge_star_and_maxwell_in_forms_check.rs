// Hodge star and Maxwell in forms -- the same check as hodge_star_and_maxwell_in_forms_check.py.
// Standard library only, no crates.  Coordinates 0 = t (s), 1 = x, 2 = y, 3 = z (m).
// A two-form is a 4x4 antisymmetric array F[a][b].
use std::f64::consts::PI;
const C: f64 = 299792458.0;
const MU0: f64 = 1.25663706127e-6; // CODATA 2022
type Form = [[f64; 4]; 4];
const PAIRS: [(usize, usize); 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
const TRIPLES: [(usize, usize, usize); 4] = [(0, 1, 2), (0, 1, 3), (0, 2, 3), (1, 2, 3)];

fn sign(p: [usize; 4]) -> f64 {
    let inv = (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).filter(|&(i, j)| p[i] > p[j]).count();
    if inv % 2 == 0 { 1.0 } else { -1.0 }
}
fn form(e: [f64; 3], b: [f64; 3]) -> Form {
    let mut f = [[0.0; 4]; 4];
    for i in 0..3 { f[i + 1][0] = e[i]; f[0][i + 1] = -e[i]; }
    for &((p, q), v) in &[((2, 3), b[0]), ((3, 1), b[1]), ((1, 2), b[2])] { f[p][q] = v; f[q][p] = -v; }
    f
}
fn fields(f: &Form) -> ([f64; 3], [f64; 3]) { ([f[1][0], f[2][0], f[3][0]], [f[2][3], f[3][1], f[1][2]]) }
fn rest(a: usize, b: usize) -> (usize, usize) { // the other two coordinates, in order
    let r: Vec<usize> = (0..4).filter(|k| *k != a && *k != b).collect(); (r[0], r[1])
}
fn ginv(sg: f64) -> [f64; 4] { [1.0 / (sg * C * C), 1.0, 1.0, 1.0] }
// road 1: (*F)_ab = sqrt|g| eps_abcd F^cd, g = diag(sg c^2, 1, 1, 1)
fn star(f: &Form, sg: f64) -> Form {
    let gi = ginv(sg);
    let mut s = [[0.0; 4]; 4];
    for a in 0..4 { for b in 0..4 { if a != b {
        let (c, d) = rest(a, b); s[a][b] = C * sign([a, b, c, d]) * gi[c] * gi[d] * f[c][d];
    } } }
    s
}
fn inner(x: &Form, y: &Form, sg: f64) -> f64 {
    let gi = ginv(sg);
    PAIRS.iter().fold(0.0, |s, &(a, b)| s + gi[a] * gi[b] * x[a][b] * y[a][b])
}
fn wedge(x: &Form, y: &Form) -> f64 {
    PAIRS.iter().fold(0.0, |s, &(a, b)| { let (c, d) = rest(a, b); s + sign([a, b, c, d]) * x[a][b] * y[c][d] })
}
fn basis(a: usize, b: usize) -> Form { let mut f = [[0.0; 4]; 4]; f[a][b] = 1.0; f[b][a] = -1.0; f }
// exterior derivative by central differences
fn d(ff: &dyn Fn([f64; 4]) -> Form, p: [f64; 4], h: [f64; 4]) -> [f64; 4] {
    let dd = |k: usize, a: usize, b: usize| {
        let (mut q1, mut q2) = (p, p);
        q1[k] += h[k]; q2[k] -= h[k];
        (ff(q1)[a][b] - ff(q2)[a][b]) / (2.0 * h[k])
    };
    let mut out = [0.0; 4];
    for (i, &(a, b, c)) in TRIPLES.iter().enumerate() { out[i] = dd(a, b, c) + dd(b, c, a) + dd(c, a, b); }
    out
}
fn z(v: f64) -> f64 { if (v * 1e6).round() == 0.0 { 0.0 } else { v } } // print a rounded zero as 0, never -0
fn maxabs(v: [f64; 4]) -> f64 { v.iter().fold(0.0, |m: f64, x| m.max(x.abs())) }
fn boost(f: &Form, beta: f64) -> Form {
    let g = 1.0 / (1.0 - beta * beta).sqrt();
    let m = [[g, g * beta / C, 0.0, 0.0], [g * beta * C, g, 0.0, 0.0], [0.0, 0.0, 1.0, 0.0], [0.0, 0.0, 0.0, 1.0]];
    let mut o = [[0.0; 4]; 4];
    for mu in 0..4 { for nu in 0..4 { for a in 0..4 { for b in 0..4 { o[mu][nu] += m[a][mu] * f[a][b] * m[b][nu]; } } } }
    o
}

fn main() {
    let eps0 = 1.0 / (MU0 * C * C);
    // ---- the radio mast: 100 MHz, vertical mast, field 0.1 V/m at 10 km ----
    let (f, r, e0) = (100e6, 10000.0, 0.1);
    let (lam, k) = (C / f, 2.0 * PI * f / C);
    let s_pow = e0 * e0 / (2.0 * MU0 * C); // mean power per square metre
    let eirp = 4.0 * PI * r * r * s_pow; // the same, spread over a whole sphere of radius r
    let wave_f = |p: [f64; 4], f0: f64| {
        let ph = (2.0 * PI * f0 / C) * p[1] - 2.0 * PI * f0 * p[0];
        form([0.0, 0.0, e0 * ph.cos()], [0.0, -e0 / C * ph.cos(), 0.0])
    };
    let wave = |p: [f64; 4]| wave_f(p, f);
    println!("wavelength (m)                    {:.6}", lam);
    println!("k (rad/m)                         {:.6}", k);
    println!("E0 (V/m), B0 = E0/c (nT)          {:.6} {:.6}", e0, e0 / C * 1e9);
    println!("power density (uW/m^2), 2 mu0 c   {:.6} {:.2}", s_pow * 1e6, 2.0 * MU0 * C);
    println!("equivalent isotropic power (kW)   {:.6}", eirp / 1e3);
    println!("light time to 10 km (us), s^2     {:.6} {:.6}", r / C * 1e6, z(-(C * (r / C)).powi(2) + r * r));
    println!("2-form slots, 1-form slots, eqns  {} 4 {}", PAIRS.len(), 2 * TRIPLES.len());

    // road 2: the star against its definition A ^ *B = <A, B> vol, vol = c dt^dx^dy^dz, all 36 pairs
    let err = PAIRS.iter().flat_map(|&p| PAIRS.iter().map(move |&q| (p, q))).fold(0.0f64, |m, ((a, b), (c, d2))|
        m.max((wedge(&basis(a, b), &star(&basis(c, d2), -1.0)) - inner(&basis(a, b), &basis(c, d2), -1.0) * C).abs()));
    let names = ["t", "x", "y", "z"];
    for &(a, b) in &PAIRS {
        let s = star(&basis(a, b), -1.0);
        let (m, n) = rest(a, b);
        let unit = if s[m][n].abs() > 1.0 { "c" } else { "(1/c)" };
        println!("*(d{}^d{}) = {}{} d{}^d{}", names[a], names[b], if s[m][n] > 0.0 { "+" } else { "-" }, unit, names[m], names[n]);
    }
    let ss_m: Vec<f64> = PAIRS.iter().map(|&(a, b)| star(&star(&basis(a, b), -1.0), -1.0)[a][b]).collect();
    let ss_e: Vec<f64> = PAIRS.iter().map(|&(a, b)| star(&star(&basis(a, b), 1.0), 1.0)[a][b]).collect();
    let show = |v: &Vec<f64>| v.iter().map(|x| format!("{:+.0}", x)).collect::<Vec<_>>().join(" ");
    println!("** on the six planes, (-,+,+,+)   {}", show(&ss_m));
    println!("** on the six planes, (+,+,+,+)   {}", show(&ss_e));

    // the wave at a crest (phase 0): F, *F, **F
    let fw = wave([0.0; 4]);
    let (e1, b1) = fields(&star(&fw, -1.0));
    let (e2, _) = fields(&star(&star(&fw, -1.0), -1.0));
    println!("*F: E_y (V/m), B_z (nT)           {:.6} {:.6}", e1[1], b1[2] * 1e9);
    println!("**F: E_z (V/m)                    {:.6}", e2[2]);
    println!("c^2<F,F> = c^2B^2 - E^2, F^F      {:.6} {:.6}", z(inner(&fw, &fw, -1.0) * C * C), z(wedge(&fw, &fw)));

    // road 3: Maxwell, by forms against vector calculus, where the field's derivative peaks (phase -pi/2)
    let (p0, h) = ([0.25 / f, 0.0, 0.0, 0.0], [1e-4 / C, 1e-4, 1e-4, 1e-4]);
    let (ez, by) = (|t: f64, x: f64| wave([t, x, 0.0, 0.0])[3][0], |t: f64, x: f64| wave([t, x, 0.0, 0.0])[3][1]);
    let curle_y = -(ez(p0[0], h[1]) - ez(p0[0], -h[1])) / (2.0 * h[1]);
    let dby_dt = (by(p0[0] + h[0], 0.0) - by(p0[0] - h[0], 0.0)) / (2.0 * h[0]);
    println!("Faraday y: curl E, dB/dt (V/m^2)  {:.6} {:.6}", curle_y, dby_dt);
    let df = d(&wave, p0, h);
    let dsf = d(&|q| star(&wave(q), -1.0), p0, h);
    let dsf_e = d(&|q| star(&wave(q), 1.0), p0, h);
    println!("wave: max |dF|, max |d*F|         {:.6} {:.6}", z(maxabs(df)), z(maxabs(dsf)));
    println!("wave, all-plus star: d*F Ampere z {:.6}", dsf_e[0].abs());
    let dsf_g = d(&|q| star(&wave_f(q, 1e9), -1.0), p0, [1e-5 / C, 1e-5, 1e-5, 1e-5]);
    println!("try: 1 GHz, max |d*F|, E0 k       {:.6} {:.6}", z(maxabs(dsf_g)), e0 * 2.0 * PI * 1e9 / C);

    // sources: uniform charge 1 nC/m^3 and current 1 A/m^2 along z; E = rho r/(3 eps0), B = mu0 J (-y, x, 0)/2
    let (rho, j) = (1e-9, 1.0);
    let src = |q: [f64; 4]| form([rho * q[1] / (3.0 * eps0), rho * q[2] / (3.0 * eps0), rho * q[3] / (3.0 * eps0)],
                                 [-MU0 * j * q[2] / 2.0, MU0 * j * q[1] / 2.0, 0.0]);
    let ps = [0.0, 0.3, -0.2, 0.5];
    let hs = [1e-3 / C, 1e-3, 1e-3, 1e-3];
    let dss = d(&|q| star(&src(q), -1.0), ps, hs);
    let want = [-j, 0.0, 0.0, rho]; // current three-form: rho dx^dy^dz - J dx^dy^dt
    println!("d*F / (mu0 c): dtdxdy, dxdydz     {:.6} {:.6}", dss[0] / (MU0 * C), dss[3] / (MU0 * C) * 1e9);
    println!("source field: max |dF|            {:.6}", z(maxabs(d(&src, ps, hs))));

    // road 4: chart against chart, a boost along x
    let fs = src(ps);
    let mut chart: f64 = 0.0;
    for g in [&fw, &fs] {
        let (x, y) = (star(&boost(g, 0.6), -1.0), boost(&star(g, -1.0), 0.6));
        for &(a, b) in &PAIRS {
            let den = if y[a][b] == 0.0 { 1.0 } else { y[a][b].abs() };
            chart = chart.max((x[a][b] - y[a][b]).abs() / den);
        }
    }
    let (fb, fsb) = (boost(&fw, 0.6), boost(&fs, 0.6));
    println!("boost 0.6c: E_z (V/m), c^2<F,F>   {:.6} {:.6}", fields(&fb).0[2], z(inner(&fb, &fb, -1.0) * C * C));
    println!("source field c^2<F,F>, both charts {:.6} {:.6}", inner(&fs, &fs, -1.0) * C * C, inner(&fsb, &fsb, -1.0) * C * C);
    println!("try: boost -0.6c, E_z (V/m)       {:.6}", fields(&boost(&fw, -0.6)).0[2]);
    println!("try: 20 km, same power, E0 (V/m)  {:.6}", (2.0 * MU0 * C * eirp / (4.0 * PI * 20000.0f64.powi(2))).sqrt());

    let (gm, n, rr) = (1.0, 200, 2.0); // a hole in space: a 1 Wb monopole, B = g r/(4 pi |r|^3); a 2 m sphere round it
    let mono = |q: [f64; 4]| { let r3 = (q[1] * q[1] + q[2] * q[2] + q[3] * q[3]).powf(1.5);
        form([0.0; 3], [gm * q[1] / (4.0 * PI * r3), gm * q[2] / (4.0 * PI * r3), gm * q[3] / (4.0 * PI * r3)]) };
    let (dfm, mut flux) = (maxabs(d(&mono, [0.0, 1.0, 1.0, 1.0], [1e-4; 4])), 0.0);
    for i in 0..n { for j in 0..2 * n { // B.n R^2 sin(th) dth dph
        let (th, ph) = ((i as f64 + 0.5) * PI / n as f64, (j as f64 + 0.5) * PI / n as f64);
        let q = [0.0, rr * th.sin() * ph.cos(), rr * th.sin() * ph.sin(), rr * th.cos()];
        let b = fields(&mono(q)).1; flux += (b[0] * q[1] + b[1] * q[2] + b[2] * q[3]) * rr * th.sin() * (PI / n as f64).powi(2); } }
    println!("monopole: |dF| at (1,1,1) m, flux {:.6} {:.4}", z(dfm), flux);

    assert!(err < 1e-15, "star against its definition");
    assert!(ss_m.iter().all(|v| *v == -1.0) && ss_e.iter().all(|v| *v == 1.0), "star twice");
    assert!((e1[1] - e0).abs() < 1e-12 && (e2[2] + e0).abs() < 1e-12, "*F horizontal, **F = -F");
    assert!(maxabs(df) < 1e-6 * e0 * k && maxabs(dsf) < 1e-6 * e0 * k, "the wave solves both lines");
    assert!((curle_y + e0 * k).abs() < 1e-6 && (dby_dt - e0 * k).abs() < 1e-6, "Faraday terms");
    assert!((dsf_e[0].abs() - 2.0 * e0 * k).abs() < 1e-6, "all-plus star: Ampere terms add");
    for i in 0..4 { assert!((dss[i] / (MU0 * C) - want[i]).abs() < 1e-6 * want[i].abs().max(rho), "d*F = mu0 c J"); }
    assert!(chart < 1e-9 && (inner(&fsb, &fsb, -1.0) / inner(&fs, &fs, -1.0) - 1.0).abs() < 1e-9, "star and c^2<F,F> ignore a boost");
    assert!((fields(&fb).0[2] - 0.5 * e0).abs() < 1e-12, "Doppler factor 0.5");
    assert!(dfm < 1e-6 && (flux - gm).abs() < 1e-4, "monopole: dF = 0, flux = g");
    println!("ALL CHECKS PASS");
}
