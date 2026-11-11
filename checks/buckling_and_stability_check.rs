// Buckling -- the check behind the card.  std only.  A 3 m steel scaffold tube, 48.3 mm across
// with a 4.0 mm wall, loaded end-on.  Road 1: Euler's formula with the end factor K.  Road 2: RK4
// shooting on EI y'''' + P y'' = 0 for each pair of ends.  Road 3: the tube as a chain of stiff
// links and springs, stable while its energy matrix has no negative pivot.
use std::f64::consts::PI;
const E: f64 = 210e9; const FY: f64 = 235e6; const L: f64 = 3.0; const D: f64 = 0.0483; const T: f64 = 0.0040;

fn euler(k: f64, l: f64, i: f64, e: f64) -> f64 { PI * PI * e * i / (k * l).powi(2) }
fn bisect<F: Fn(f64) -> f64>(g: F, mut lo: f64, mut hi: f64, n: usize) -> f64 {
    let mut glo = g(lo);
    for _ in 0..n {
        let m = (lo + hi) / 2.0; let gm = g(m);
        if glo * gm <= 0.0 { hi = m } else { lo = m; glo = gm }
    }
    (lo + hi) / 2.0
}
fn rk4<F: Fn(f64, &[f64]) -> Vec<f64>>(f: &F, v0: &[f64], n: usize, h: f64) -> Vec<f64> {
    let mut v = v0.to_vec(); let mut x = 0.0;
    let step = |v: &[f64], d: &[f64], s: f64| -> Vec<f64> { v.iter().zip(d).map(|(p, q)| p + s * q).collect() };
    for _ in 0..n {
        let a = f(x, &v); let b = f(x + h / 2.0, &step(&v, &a, h / 2.0));
        let c = f(x + h / 2.0, &step(&v, &b, h / 2.0)); let d = f(x + h, &step(&v, &c, h));
        for j in 0..v.len() { v[j] += h / 6.0 * (a[j] + 2.0 * b[j] + 2.0 * c[j] + d[j]); }
        x += h;
    }
    v
}
fn top_bc(kind: &str, v: &[f64], k2: f64) -> (f64, f64) {
    match kind { "pin" => (v[0], v[2]), "fix" => (v[0], v[1]), _ => (v[2], v[3] + k2 * v[1]) }
}
fn det(p: f64, i: f64, base: &str, top: &str) -> f64 {
    let k2 = p / (E * i);
    let f = move |_x: f64, v: &[f64]| vec![v[1], v[2], v[3], -k2 * v[2]];
    let starts: [[f64; 4]; 2] = if base == "pin" { [[0., 1., 0., 0.], [0., 0., 0., 1.]] } else { [[0., 0., 1., 0.], [0., 0., 0., 1.]] };
    let (a, b) = top_bc(top, &rk4(&f, &starts[0], 200, L / 200.0), k2);
    let (c, d) = top_bc(top, &rk4(&f, &starts[1], 200, L / 200.0), k2);
    a * d - b * c
}
fn shoot(i: f64, base: &str, top: &str) -> f64 {
    let mut p = 1e3;
    while det(p, i, base, top) * det(p + 1e3, i, base, top) > 0.0 && p < 1e6 { p += 1e3; }
    bisect(|q| det(q, i, base, top), p, p + 1e3, 40)
}
fn negative_pivots(p: f64, n_links: usize, i: f64) -> usize {
    let h = L / n_links as f64; let n = n_links - 1;
    let tm = |a: usize, b: usize| -> f64 { if a == b { 2.0 } else if a.abs_diff(b) == 1 { -1.0 } else { 0.0 } };
    let mut m = vec![vec![0.0; n]; n];
    for r in 0..n { for c in 0..n {
        let mut s = 0.0;
        for k in r.saturating_sub(1)..(r + 2).min(n) { s += tm(r, k) * tm(k, c); }
        m[r][c] = E * i / h.powi(3) * s - p / h * tm(r, c);
    } }
    let mut neg = 0;
    for a in 0..n {
        if m[a][a] < 0.0 { neg += 1; }
        for r in a + 1..(a + 3).min(n) {
            let f = m[r][a] / m[a][a];
            for c in a..(a + 3).min(n) { m[r][c] -= f * m[a][c]; }
        }
    }
    neg
}
fn chain(n: usize, i: f64) -> f64 {
    let (mut lo, mut hi) = (0.0, 2.0 * euler(1.0, L, i, E));
    for _ in 0..50 { let m = (lo + hi) / 2.0; if negative_pivots(m, n, i) > 0 { hi = m } else { lo = m } }
    (lo + hi) / 2.0
}
fn main() {
    let di = D - 2.0 * T;
    let a = PI / 4.0 * (D * D - di * di); let i = PI / 64.0 * (D.powi(4) - di.powi(4));
    let r = (i / a).sqrt(); let w = i / (D / 2.0); let psq = FY * a;
    let kl_fp = bisect(|x: f64| x.sin() - x * x.cos(), 4.0, 4.6, 60);
    let ends = [("pinned-pinned", 1.0, "pin", "pin"), ("fixed-free", 2.0, "fix", "free"),
                ("fixed-pinned", PI / kl_fp, "fix", "pin"), ("fixed-fixed", 0.5, "fix", "fix")];
    let pe = euler(1.0, L, i, E);
    let bow_formula = |p: f64, e0: f64| e0 / (1.0 - p / pe);
    let bow_rk4 = |p: f64, e0: f64| -> f64 {
        let f = move |x: f64, v: &[f64]| vec![v[1], -e0 * (PI / L).powi(2) * (PI * x / L).sin() - p / (E * i) * v[0], 0.0];
        let end = |s: f64| rk4(&f, &[0.0, s, 0.0], 200, L / 200.0)[0];
        let s = -end(0.0) / (end(1.0) - end(0.0));
        rk4(&f, &[0.0, s, 0.0], 100, L / 200.0)[0]
    };
    let peak = |p: f64, e0: f64, pcr: f64| p / a + p * e0 / (1.0 - p / pcr) / w;
    let first_yield = |e0: f64, pcr: f64| bisect(|p| peak(p, e0, pcr) - FY, 1.0, pcr * (1.0 - 1e-12), 60);
    let first_yield_quad = |e0: f64, pcr: f64| -> f64 { // smaller root of (fy - P/A)(1 - P/Pcr) = P e0 / W
        let (qa, qb) = (1.0 / (a * pcr), FY / pcr + 1.0 / a + e0 / w);
        (qb - (qb * qb - 4.0 * qa * FY).sqrt()) / (2.0 * qa)
    };
    let (kn, mm, mpa) = (1e-3, 1e3, 1e-6);
    println!("inputs: D = {:.1} mm, wall {:.1} mm, inside {:.1} mm, L = {:.0} m, E = {:.0} GPa, fy = {:.0} MPa, pi^2 = {:.4}",
             D * mm, T * mm, di * mm, L, E * 1e-9, FY * mpa, PI * PI);
    println!("tube: A = {:.1} mm^2, I = {:.0} mm^4, r = {:.2} mm, W = {:.0} mm^3, EI = {:.0} N m^2", a * 1e6, i * 1e12, r * mm, w * 1e9, E * i);
    let (mut a2, mut i2, dr) = (0.0, 0.0, (D - di) / 2.0 / 4000.0); // A and I again from thin rings
    for k in 0..4000 {
        let rr = di / 2.0 + (k as f64 + 0.5) * dr;
        a2 += 2.0 * PI * rr * dr; i2 += PI * rr.powi(3) * dr;
    }
    assert!((a2 - a).abs() < 1e-9 * a && (i2 - i).abs() < 1e-6 * i);
    println!("tube again, from 4000 thin rings: A = {:.1} mm^2, I = {:.0} mm^4", a2 * 1e6, i2 * 1e12);
    println!("slenderness L/r = {:.1}; crossover pi sqrt(E/fy) = {:.1}", L / r, PI * (E / FY).sqrt());
    println!("squash load fy A = {:.1} kN; Euler stress = {:.1} MPa", psq * kn, pe / a * mpa);
    println!("fixed-pinned root kL = {:.4}, so K = {:.4}", kl_fp, PI / kl_fp);
    println!("ends           K       road 1 kN  road 2 kN  share of squash  Le m");
    for (name, k, base, top) in ends.iter() {
        let p1 = euler(*k, L, i, E); let p2 = shoot(i, base, top);
        assert!((p1 - p2).abs() < 1e-3 * p1, "{}", name);
        println!("{:14} {:.4}  {:8.2}  {:9.2}  {:13.1} %  {:.3}", name, k, p1 * kn, p2 * kn, p1 / psq * 100.0, k * L);
    }
    for n in [10, 20, 40] { println!("road 3, {} links, pinned-pinned: {:.2} kN", n, chain(n, i) * kn); }
    let (c10, c20, c40) = (chain(10, i), chain(20, i), chain(40, i));
    assert!((c40 - pe).abs() < 0.002 * pe && c10 < c20 && c20 < c40 && c40 < pe);
    println!("40 kN on the pinned tube is {:.2} x Euler and {:.1} % of squash", 40e3 / pe, 40e3 / psq * 100.0);
    println!("load kN  bow mm (formula, rk4)  squeeze MPa  bending MPa  peak MPa, e0 = 3 mm");
    for p in [0.0, 10e3, 20e3, 25e3, 28e3] {
        let (b1, b2) = (bow_formula(p, 3e-3), bow_rk4(p, 3e-3));
        assert!((b1 - b2).abs() < 1e-4 * b1);
        println!("{:5.0}  {:8.2} {:8.2}  {:15.1}  {:11.1}  {:8.1}", p * kn, b1 * mm, b2 * mm, p / a * mpa, p * b1 / w * mpa, peak(p, 3e-3, pe) * mpa);
    }
    let (py3, py1) = (first_yield(3e-3, pe), first_yield(1e-3, pe));
    for e in [3e-3, 1e-3] { assert!((first_yield(e, pe) - first_yield_quad(e, pe)).abs() < 1e-6 * py3); }
    assert!(py1 > py3 && py3 < pe);
    println!("first yield, bow 3 mm: {:.2} kN; bow 1 mm: {:.2} kN", py3 * kn, py1 * kn);
    let loads: Vec<f64> = (0..15).map(|k| 2.0 * k as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64| loads.iter().map(|&p| format!("{:.0}", f(p * 1e3) * mpa)).collect::<Vec<_>>().join(" ");
    println!("chart load kN {}", loads.iter().map(|p| format!("{:.0}", p)).collect::<Vec<_>>().join(" "));
    println!("chart squeeze only MPa {}", row(&|p| p / a));
    println!("chart peak, bow 3 mm MPa {}", row(&|p| peak(p, 3e-3, pe)));
    println!("chart peak, bow 1 mm MPa {}", row(&|p| peak(p, 1e-3, pe)));
    println!("chart yield MPa {}", row(&|_| FY));
    let ff = euler(0.5, L, i, E);
    let pyf = first_yield(1.5e-3, ff);
    assert!((pyf - first_yield_quad(1.5e-3, ff)).abs() < 1e-6 * pyf);
    println!("outside the range: fixed-fixed Euler {:.1} kN vs squash {:.1} kN; with a 1.5 mm bow first yield at {:.1} kN",
             ff * kn, psq * kn, pyf * kn);
    println!("outside the range: 0.5 m pinned tube, Euler {:.0} kN, crushes at {:.1} kN", euler(1.0, 0.5, i, E) * kn, psq * kn);
    let solid = euler(1.0, L, PI / 64.0 * D.powi(4), E);
    assert!(solid > 1.9 * pe);
    println!("wrong: solid-bar I gives {:.2} kN; K not squared, flagpole {:.2} kN", solid * kn, PI * PI * E * i / (2.0 * L * L) * kn);
    println!("wrong: fixed-fixed assumed for pinned couplers {:.2} kN", ff * kn);
    println!("try: 3.2 mm wall {:.2} kN; 2 m tube {:.2} kN; aluminium E = 70 GPa {:.2} kN",
             euler(1.0, L, PI / 64.0 * (D.powi(4) - (D - 0.0064).powi(4)), E) * kn, euler(1.0, 2.0, i, E) * kn, euler(1.0, L, i, 70e9) * kn);
    println!("try: 40 kN on a fixed-pinned tube is {:.0} % of its Euler load", 40e3 / euler(PI / kl_fp, L, i, E) * 100.0);
    println!("figure, 60 px per m, inflection heights m: pinned 0, 3; fixed-free 3; fixed-pinned {:.3}, 3; fixed-fixed {:.2}, {:.2}",
             L * (1.0 - PI / kl_fp), L / 4.0, 3.0 * L / 4.0);
    println!("ALL CHECKS PASS");
}
