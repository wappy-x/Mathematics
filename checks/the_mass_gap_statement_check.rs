// Mass gap: the Yang-Mills prize problem stated precisely -- the check behind the card.
// Standard library only.  Energies in MeV, lengths in fm (1 fm = 1e-15 m).
// Part 1: what a gap means for the strong force (range of a force, a photon in a box).
// Part 2: a toy with a provable gap, one plaquette of SU(2) lattice gauge theory.
// Roads to the toy's gap: its matrix in the spin-j basis, a finite-difference grid
// at two step sizes, and the decay of a correlation in imaginary time (no eigensolver).
use std::f64::consts::PI;

fn below(d: &[f64], e: &[f64], x: f64) -> usize {
    // how many eigenvalues of a tridiagonal matrix lie below x
    let (mut c, mut q) = (0, 1.0);
    for i in 0..d.len() {
        q = d[i] - x - if i > 0 { e[i - 1] * e[i - 1] / q } else { 0.0 };
        if q == 0.0 { q = 1e-300; }
        if q < 0.0 { c += 1; }
    }
    c
}
fn eig(d: &[f64], e: &[f64], k: usize) -> f64 {
    // k-th eigenvalue by bisection (Sturm count)
    let em = e.iter().fold(0.0f64, |m, x| m.max(x.abs()));
    let mut lo = d.iter().cloned().fold(f64::INFINITY, f64::min) - 4.0 * em;
    let mut hi = d.iter().cloned().fold(f64::NEG_INFINITY, f64::max) + 4.0 * em;
    for _ in 0..200 {
        let m = (lo + hi) / 2.0;
        if below(d, e, m) > k { hi = m; } else { lo = m; }
    }
    (lo + hi) / 2.0
}
fn spin_basis(g2: f64, n: usize) -> (Vec<f64>, Vec<f64>) {
    // u_n = sin(n theta), n = 2j + 1; H = (g2/2) C + (4/g2)(1 - cos theta)
    ((1..=n).map(|k| g2 / 8.0 * ((k * k) as f64 - 1.0) + 4.0 / g2).collect(), vec![-2.0 / g2; n - 1])
}
fn grid(g2: f64, m: usize) -> (Vec<f64>, Vec<f64>) {
    // same H on theta in (0, pi), u = 0 at both ends, m intervals
    let s = PI / m as f64;
    ((1..m).map(|k| g2 / 8.0 * (2.0 / (s * s) - 1.0) + 4.0 / g2 * (1.0 - (k as f64 * s).cos())).collect(),
     vec![-g2 / 8.0 / (s * s); m - 2])
}
fn hv(d: &[f64], e: &[f64], v: &[f64], s: f64) -> Vec<f64> {
    let n = d.len();
    (0..n).map(|i| (d[i] - s) * v[i] + if i > 0 { e[i - 1] * v[i - 1] } else { 0.0 }
        + if i < n - 1 { e[i] * v[i + 1] } else { 0.0 }).collect()
}
fn step(d: &[f64], e: &[f64], v: &[f64], s: f64, dt: f64) -> Vec<f64> {
    let n = v.len();
    let k1 = hv(d, e, v, s);
    let k2 = hv(d, e, &(0..n).map(|i| v[i] - dt / 2.0 * k1[i]).collect::<Vec<_>>(), s);
    let k3 = hv(d, e, &(0..n).map(|i| v[i] - dt / 2.0 * k2[i]).collect::<Vec<_>>(), s);
    let k4 = hv(d, e, &(0..n).map(|i| v[i] - dt * k3[i]).collect::<Vec<_>>(), s);
    (0..n).map(|i| v[i] - dt / 6.0 * (k1[i] + 2.0 * k2[i] + 2.0 * k3[i] + k4[i])).collect()
}
fn dot(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| x * y).sum() }
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    let hbarc = 6.62607015e-34 * 299792458.0 / (2.0 * PI) / 1.602176634e-13 * 1e15; // MeV fm, exact SI
    let (m_pi, m_gb) = (139.57039, 1730.0); // charged pion (PDG 2024); lightest glueball (lattice, 1999)
    println!("hbar c = {:.6} MeV fm", hbarc);
    println!("inputs: charged pion {:.5} MeV, lightest glueball {:.0} MeV", m_pi, m_gb);
    let (r_pi, r_gb) = (hbarc / m_pi, hbarc / m_gb);
    println!("range hbar c / m: pion {:.4} fm, lightest glueball {:.4} fm, photon infinite", r_pi, r_gb);
    println!("glueball correlation left at 1 fm: exp(-1/{:.4}) = {:.6}", r_gb, (-1.0 / r_gb).exp());
    println!("potential at 1 fm over potential at 2 fm: Coulomb (massless) {:.2}, Yukawa with pion {:.2}", 2.0, 2.0 * (1.0 / r_pi).exp());
    let (mu, h) = (1.0 / r_pi, 1e-3); // road check: exp(-mu r)/r solves -phi'' - (2/r) phi' + mu^2 phi = 0
    let yuk = |r: f64| (-mu * r).exp() / r;
    let res: Vec<f64> = [0.5, 1.0, 2.0].iter().map(|&r| -(yuk(r + h) - 2.0 * yuk(r) + yuk(r - h)) / (h * h)
        - (2.0 / r) * (yuk(r + h) - yuk(r - h)) / (2.0 * h) + mu * mu * yuk(r)).collect();
    println!("Yukawa field equation residual at 0.5, 1, 2 fm: {}", join(&res.iter().map(|x| x.abs()).collect::<Vec<_>>(), 6));
    let pho: Vec<f64> = [1.0, 2.0, 4.0, 8.0, 16.0, 32.0].iter().map(|l| 2.0 * PI * hbarc / l).collect();
    println!("lowest photon energy in a box of side L fm, 2 pi hbar c / L (MeV): {}", join(&pho, 2));
    println!("  L = 10 fm: {:.2} MeV; L = 1000 fm: {:.2} MeV", 2.0 * PI * hbarc / 10.0, 2.0 * PI * hbarc / 1000.0);
    println!("chart, photon: {}; gapped theory: {:.0} at every L",
        pho.iter().map(|x| format!("{:.0}", x)).collect::<Vec<_>>().join(", "), m_gb);
    println!("one massless quantum of a 1 km wave, 2 pi hbar c / lambda: {:.4} neV", 2.0 * PI * hbarc / 1e18 * 1e15);

    println!("one SU(2) plaquette, lattice units: g^2, E0, E1, gap, strong-coupling guess 3 g^2 / 8");
    let couplings = [0.25, 1.0, 4.0, 16.0];
    let mut gap = [0.0f64; 4];
    for (i, &g2) in couplings.iter().enumerate() {
        let (d, e) = spin_basis(g2, 30);
        let (e0, e1) = (eig(&d, &e, 0), eig(&d, &e, 1));
        gap[i] = e1 - e0;
        println!("  {:5.2} {:.6} {:.6} {:.6} {:.6}", g2, e0, e1, gap[i], 3.0 * g2 / 8.0);
    }
    let mut fd = [0.0f64; 2];
    for (i, &m) in [200usize, 400].iter().enumerate() {
        let (d, e) = grid(1.0, m);
        fd[i] = eig(&d, &e, 1) - eig(&d, &e, 0);
        println!("  grid, {} steps, g^2 = 1: gap {:.6}, off by {:.6}", m, fd[i], gap[1] - fd[i]);
    }
    let ratio = (gap[1] - fd[0]) / (gap[1] - fd[1]);
    println!("  grid error ratio, 200 over 400 steps: {:.2} (second order predicts 4)", ratio);

    let (d, e) = spin_basis(1.0, 30); // road three: imaginary time, dv/dtau = -(H - shift) v
    let n = d.len();
    let mut v = vec![0.0; n];
    v[0] = 1.0;
    for _ in 0..3000 { // 30 units of imaginary time cools any start to the vacuum
        v = step(&d, &e, &v, 0.0, 0.01);
        let nv = dot(&v, &v).sqrt();
        v = v.iter().map(|x| x / nv).collect();
    }
    let e0 = dot(&v, &hv(&d, &e, &v, 0.0));
    let o: Vec<f64> = (0..n).map(|i| if i > 0 { v[i - 1] } else { 0.0 } + if i < n - 1 { v[i + 1] } else { 0.0 }).collect();
    let avg = dot(&v, &o);
    let w: Vec<f64> = (0..n).map(|i| o[i] - avg * v[i]).collect(); // Tr U with its vacuum average removed
    println!("imaginary time, g^2 = 1: vacuum energy {:.6}, vacuum average of Tr U {:.6}", e0, avg);
    let mut c = Vec::new();
    let mut u = w.clone();
    for _ in 0..9 {
        c.push(dot(&w, &u));
        for _ in 0..100 { u = step(&d, &e, &u, e0, 0.01); }
    }
    let meff: Vec<f64> = (0..8).map(|t| (c[t] / c[t + 1]).ln()).collect();
    println!("  tau, C(tau), effective mass ln(C(tau)/C(tau+1))");
    for t in 0..8 { println!("  {} {:.10} {:.6}", t, c[t], meff[t]); }
    let bound = (0..9).all(|t| c[t] <= c[0] * (-gap[1] * t as f64).exp() * (1.0 + 1e-9));
    println!("  bound C(tau) <= C(0) exp(-gap tau) holds at every tau: {}", if bound { "yes" } else { "no" });
    println!("toy continuum limit: Delta = (gap in lattice units) hbar c / a, against the required 1730 MeV");
    for a in [0.1, 0.05] {
        println!("  a = {:.2} fm: toy {:.0} MeV; required gap in lattice units {:.4}", a, gap[0] * hbarc / a, m_gb * a / hbarc);
    }
    println!("what breaks: first-step effective mass {:.6} against gap {:.6}, {:.1}% high", meff[0], gap[1], 100.0 * (meff[0] / gap[1] - 1.0));

    assert!((hbarc - 197.3269804).abs() < 1e-6); // CODATA 2022 value of hbar c
    assert!(res.iter().fold(0.0f64, |m, x| m.max(x.abs())) < 1e-3 * mu * mu * yuk(2.0)); // Yukawa solves the field equation
    assert!((gap[1] - fd[1]).abs() < 1e-3 && ratio > 3.5 && ratio < 4.5); // spin basis and grid agree, second order
    assert!((meff[7] - gap[1]).abs() < 1e-4 && meff[0] > meff[3] && meff[3] > meff[7]); // decay gives the gap
    assert!((gap[3] - 6.0).abs() < 0.01 && (gap[0] - 2.0).abs() < 0.05); // strong and weak coupling limits
    assert!(gap.iter().all(|&g| g > 0.0)); // the toy has a gap at every coupling
    assert!(bound);
    println!("ALL CHECKS PASS");
}
