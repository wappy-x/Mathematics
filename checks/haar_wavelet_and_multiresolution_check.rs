// The Haar wavelet on the whole line: eight days of bakery sales as averages and differences.
// std only.  Roads: the averages-and-differences ladder, integrals of f times each Haar
// function on the time line (midpoint sums, exact for these steps), and energy.
const SALES: [f64; 8] = [820.0, 760.0, 900.0, 980.0, 1240.0, 1300.0, 640.0, 600.0];
const H: f64 = 1.0 / 8.0; // grid step in days for the integrals
fn phi(x: f64) -> f64 { if (0.0..1.0).contains(&x) { 1.0 } else { 0.0 } }
fn psi(x: f64) -> f64 { if (0.0..0.5).contains(&x) { 1.0 } else if (0.5..1.0).contains(&x) { -1.0 } else { 0.0 } }
fn unit(g: fn(f64) -> f64, j: i32, k: i32) -> impl Fn(f64) -> f64 {
    move |t| 2f64.powf(-j as f64 / 2.0) * g(2f64.powf(-j as f64) * t - k as f64)
}
fn f(t: f64) -> f64 { if (0.0..8.0).contains(&t) { SALES[t as usize] } else { 0.0 } }
fn integral(u: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = ((b - a) / H) as usize;
    let mut s = 0.0;
    for i in 0..n { s += u(a + (i as f64 + 0.5) * H); }
    s * H
}
fn inner(u: &dyn Fn(f64) -> f64, v: &dyn Fn(f64) -> f64) -> f64 { integral(&|t| u(t) * v(t), 0.0, 16.0) }
fn close(a: f64, b: f64, tol: f64) -> bool { (a - b).abs() <= tol }
fn ladder(x: &[f64], levels: usize) -> (Vec<f64>, Vec<Vec<f64>>) {
    let (mut s, mut out) = (x.to_vec(), Vec::new());
    for _ in 0..levels {
        let h = s.len() / 2;
        out.push((0..h).map(|i| (s[2 * i] - s[2 * i + 1]) / 2.0).collect());
        s = (0..h).map(|i| (s[2 * i] + s[2 * i + 1]) / 2.0).collect();
    }
    (s, out)
}
fn row(xs: &[f64], d: usize) -> String { xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(" ") }
fn main() {
    println!("sales, dollars, days 1..8: {}", row(&SALES, 0));
    let total: f64 = SALES.iter().sum();
    let energy: f64 = SALES.iter().map(|x| x * x).sum();
    println!("total {}  energy sum f^2 {} dollars^2/day", total, energy);
    let (avg3, half) = ladder(&SALES, 3);
    for j in 0..3 {
        println!("level {} averages: {}   half-differences: {}", j + 1, row(&ladder(&SALES, j + 1).0, 0), row(&half[j], 0));
    }
    let coarse = inner(&f, &unit(phi, 3, 0));
    println!("<f, phi_3,0> integral {:.6}  ladder {:.6}", coarse, 2f64.powf(1.5) * avg3[0]);
    assert!(close(coarse, 2f64.powf(1.5) * avg3[0], 1e-9));
    let mut level_energy = Vec::new();
    for j in [3, 2, 1] {
        let c: Vec<f64> = (0..(8 >> j)).map(|k| inner(&f, &unit(psi, j, k))).collect();
        println!("<f, psi_{},k> integral: {}", j, row(&c, 6));
        for k in 0..c.len() { assert!(close(c[k], 2f64.powf(j as f64 / 2.0) * half[j as usize - 1][k], 1e-9)); }
        level_energy.push(c.iter().map(|x| x * x).sum::<f64>());
    }
    let le: f64 = level_energy.iter().sum();
    println!("energy by part: coarse {:.1}  level 3 {:.1}  level 2 {:.1}  level 1 {:.1}  sum {:.1}",
             coarse * coarse, level_energy[0], level_energy[1], level_energy[2], coarse * coarse + le);
    assert!(close(coarse * coarse + le, energy, 1e-6));
    // rebuild day 1..8 from the coefficients: f = sum c phi + sum d psi
    let mut basis: Vec<(f64, Box<dyn Fn(f64) -> f64>)> = vec![(coarse, Box::new(unit(phi, 3, 0)))];
    for j in [1, 2, 3] {
        for k in 0..(8 >> j) { basis.push((inner(&f, &unit(psi, j, k)), Box::new(unit(psi, j, k)))); }
    }
    let rebuild = |from: usize| -> Vec<f64> {
        (0..8).map(|d| basis[from..].iter().map(|(c, u)| c * u(d as f64 + 0.5)).sum()).collect()
    };
    let rebuilt = rebuild(0);
    println!("rebuilt days: {}", row(&rebuilt, 6));
    assert!(rebuilt.iter().zip(SALES.iter()).all(|(a, b)| (a - b).abs() < 1e-9));
    println!("details only, no coarse box: {}  energy {:.1} = {:.2}%", row(&rebuild(1), 1), le, 100.0 * le / energy);
    // orthonormality: every psi_{j,k} with support inside [0, 16), levels -1..3, by integration
    let mut fam = Vec::new();
    for j in [-1, 0, 1, 2, 3] { for k in 0..((16.0 / 2f64.powi(j)) as i32) { fam.push((j, k)); } }
    let mut gap: f64 = 0.0;
    for a in &fam { for b in &fam {
        let want = if a == b { 1.0 } else { 0.0 };
        gap = gap.max((inner(&unit(psi, a.0, a.1), &unit(psi, b.0, b.1)) - want).abs());
    } }
    println!("Gram matrix of {} Haar functions, levels -1..3 on [0,16): max |G - I| {:.12}", fam.len(), gap);
    assert!(gap < 1e-12);
    let mut cross: f64 = 0.0;
    for j in [1, 2, 3] { for k in 0..(8 >> j) { cross = cross.max(inner(&unit(phi, 3, 0), &unit(psi, j, k)).abs()); } }
    println!("coarse box against every finer detail: max |inner| {:.12}", cross);
    assert!(cross < 1e-12);
    let mut two_scale: f64 = 0.0;
    for i in 0..192 {
        let t = (i as f64 + 0.5) / 64.0 - 1.0;
        two_scale = two_scale.max((phi(t) - phi(2.0 * t) - phi(2.0 * t - 1.0)).abs())
            .max((psi(t) - phi(2.0 * t) + phi(2.0 * t - 1.0)).abs());
    }
    println!("two-scale: phi(t) = phi(2t) + phi(2t-1), psi(t) = phi(2t) - phi(2t-1): max error {:.1}", two_scale);
    assert!(two_scale == 0.0);
    // separation: the coarse part drains away, energy 7240^2 / 2^J, by formula and by the ladder
    println!("J | energy left in V_J: formula, ladder on [0, 4096) | share captured by details");
    let mut long_row = SALES.to_vec();
    long_row.resize(4096, 0.0);
    for jj in [3, 4, 5, 6, 8, 10, 12] {
        let left = total * total / 2f64.powi(jj);
        let (s, _) = ladder(&long_row, jj as usize);
        let by_ladder: f64 = s.iter().map(|a| (2f64.powf(jj as f64 / 2.0) * a).powi(2)).sum();
        assert!(close(left, by_ladder, 1e-6));
        println!("{:2} | {:.3}  {:.3} | {:.4}%", jj, left, by_ladder, 100.0 * (1.0 - left / energy));
    }
    println!("20 | {:.3}", total * total / 2f64.powi(20));
    // what breaks
    let naive: f64 = avg3.iter().map(|x| x * x).sum::<f64>() + half.iter().flatten().map(|x| x * x).sum::<f64>();
    println!("averages and half-differences as coordinates: sum of squares {:.1} (true {})", naive, energy);
    assert!(!close(naive, energy, 1.0));
    let hs = inner(&unit(psi, 0, 0), &|t| psi(t - 0.5));
    println!("half shift: <psi, psi(t - 1/2)> = {:.6}", hs);
    assert!(close(hs, -0.5, 1e-9));
    let e4 = inner(&|t| psi(t / 4.0), &|t| psi(t / 4.0)); // width 4, height 1
    println!("no 2^(-j/2): energy of psi(t/4) = {:.6}", e4);
    assert!(close(e4, 4.0, 1e-9));
    let mut rec = SALES.to_vec();
    rec.resize(16, 0.0);
    let mut shifted = vec![0.0];
    shifted.extend_from_slice(&SALES);
    shifted.resize(16, 0.0); // the same week, one day later
    for (name, x) in [("as recorded", rec), ("one day later", shifted)] {
        let (s, hd) = ladder(&x, 4);
        let e: Vec<f64> = (1..5).map(|j| hd[j - 1].iter().map(|v| (2f64.powf(j as f64 / 2.0) * v).powi(2)).sum()).collect();
        println!("{}: detail energy levels 1-4 {}  coarse {:.1}", name, row(&e, 1), (4.0 * s[0]).powi(2));
        assert!(close(e.iter().sum::<f64>() + (4.0 * s[0]).powi(2), energy, 1e-6));
    }
    // converges in energy, not uniformly: a till opening at 8 a.m. (t = 1/3 day), boxes 2^-m wide
    // exact integers: lengths counted in units of 1 / (3 * 2^m) days
    println!("m | box days | worst gap | energy gap: by boxes, formula (2/9) 2^-m");
    for m in [1u32, 2, 4, 8, 12] {
        let d: i64 = 3 << m; // one day in units
        let (w, open) = (3i64, 1i64 << m);
        let mut kept: i64 = 0; // sum of overlap^2; kept energy = kept / (3 d)
        for i in 0..(1i64 << m) {
            if (i + 1) * w > open { let l = d.min((i + 1) * w) - open.max(i * w); kept += l * l; }
        }
        let gap_num = 2 * d - kept; // energy gap = gap_num / (3 d), by Pythagoras
        assert!(gap_num == 2); // (2/9) 2^-m = 2 / (3 d)
        let r = (1i64 << m) % 3;
        let worst = r.max(3 - r) as f64 / 3.0;
        println!("{:2} | {:.6} | {:.6} | {:.9}  {:.9}", m, 1.0 / (1u64 << m) as f64, worst,
                 gap_num as f64 / (3 * d) as f64, 2.0 / (3 * d) as f64);
    }
    let days: Vec<f64> = (1..9).map(|x| x as f64).collect();
    println!("chart day: {}", row(&days, 0));
    println!("chart V_0: {}", row(&SALES, 0));
    let v1: Vec<f64> = ladder(&SALES, 1).0.iter().flat_map(|&v| [v, v]).collect();
    let v2: Vec<f64> = ladder(&SALES, 2).0.iter().flat_map(|&v| [v, v, v, v]).collect();
    println!("chart V_1: {}", row(&v1, 0));
    println!("chart V_2: {}", row(&v2, 0));
    println!("ALL CHECKS PASS");
}
