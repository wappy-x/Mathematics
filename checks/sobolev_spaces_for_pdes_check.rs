// Sobolev spaces for PDEs -- the check behind the card.  std only, no crates.
// A square rubber sheet, 1 m x 1 m, rim held at height 0, tension T = 200 N/m.
// Roads: closed-form energies against midpoint quadrature; the Poincare constant
// 1/(pi sqrt 2) against inverse iteration on grids; the sag under a uniform load
// by a double sine series against an SOR grid solve, both against the Poincare
// bounds.  What breaks: a needle, a sheer wall, a free rim, a change of unit.
use std::f64::consts::PI;
const T: f64 = 200.0; // tension, N/m
const B: f64 = 0.02; // lift, m
const F: f64 = 16.0; // load, N/m^2
const R: f64 = 0.5; // needle's outer radius, m

fn sci(x: f64) -> String { // same digits in Python and Rust: 1.234e-05
    let mut e = x.abs().log10().floor() as i32;
    let mut m = x / 10f64.powi(e);
    if (m.abs() * 1000.0).round() / 1000.0 >= 10.0 { m /= 10.0; e += 1; }
    format!("{:.3}e{}{:02}", m, if e >= 0 { "+" } else { "-" }, e.abs())
}
fn quad2<G: Fn(f64, f64) -> f64>(f: G) -> f64 { // midpoint rule on the unit square
    let mm = 400; let h = 1.0 / mm as f64; let mut s = 0.0;
    for i in 0..mm { for j in 0..mm { s += f((i as f64 + 0.5) * h, (j as f64 + 0.5) * h); } }
    s * h * h
}
fn grad2<U: Fn(f64, f64) -> f64>(u: &U, x: f64, y: f64) -> f64 { // |grad u|^2 by centred differences
    let d = 1e-6;
    ((u(x + d, y) - u(x - d, y)) / (2.0 * d)).powi(2) + ((u(x, y + d) - u(x, y - d)) / (2.0 * d)).powi(2)
}
fn radial<G: Fn(f64) -> f64>(g: G, r0: f64, r1: f64) -> f64 { // integral of g(r) 2 pi r dr, midpoint in ln r
    let n = 4000; let (a, b) = (r0.ln(), r1.ln()); let ds = (b - a) / n as f64; let mut s = 0.0;
    for k in 0..n { let t = a + (k as f64 + 0.5) * ds; s += g(t.exp()) * 2.0 * PI * (2.0 * t).exp(); }
    s * ds
}
fn dr<P: Fn(f64) -> f64>(p: &P, r: f64) -> f64 { (p(r * (1.0 + 1e-6)) - p(r * (1.0 - 1e-6))) / (2e-6 * r) }

fn needle(eps: f64) -> (f64, f64, f64) { // lift b at the centre, log profile out to R, zero beyond
    let l = (R / eps).ln();
    let p = |r: f64| B * (R / r).ln() / l;
    let n2 = PI * eps * eps * B * B + 2.0 * PI * B * B / (l * l) * (R * R / 4.0 - eps * eps * (l * l / 2.0 + l / 2.0 + 0.25));
    let g2 = 2.0 * PI * B * B / l;
    let qn = PI * eps * eps * B * B + radial(|r| p(r).powi(2), eps, R);
    let qg = radial(|r| dr(&p, r).powi(2), eps, R);
    assert!((qn - n2).abs() < 1e-6 * n2 && (qg - g2).abs() < 1e-6 * g2);
    (n2, g2, l)
}
fn sor(n: usize, rhs: &Vec<Vec<f64>>, u: &mut Vec<Vec<f64>>) { // solve -Lap_h u = rhs, zero rim, in place
    let h2 = 1.0 / (n * n) as f64; let om = 2.0 / (1.0 + (PI / n as f64).sin());
    loop {
        let mut big: f64 = 0.0;
        for i in 1..n { for j in 1..n {
            let d = om * ((u[i + 1][j] + u[i - 1][j] + u[i][j + 1] + u[i][j - 1] + h2 * rhs[i][j]) / 4.0 - u[i][j]);
            u[i][j] += d; big = big.max(d.abs());
        } }
        if big < 1e-14 { return; }
    }
}
fn lam1(n: usize) -> f64 { // smallest eigenvalue of the grid -Laplacian, inverse iteration
    let mut v = vec![vec![0.0; n + 1]; n + 1];
    for i in 1..n { for j in 1..n { v[i][j] = 1.0; } }
    let mut w = vec![vec![0.0; n + 1]; n + 1];
    let (mut vw, mut ww) = (0.0, 0.0);
    for _ in 0..12 {
        sor(n, &v, &mut w);
        vw = 0.0; ww = 0.0; let mut mx = f64::MIN;
        for i in 0..=n { for j in 0..=n { vw += v[i][j] * w[i][j]; ww += w[i][j] * w[i][j]; mx = mx.max(w[i][j]); } }
        for i in 0..=n { for j in 0..=n { v[i][j] = w[i][j] / mx; } }
    }
    vw / ww
}

fn main() {
    let cp = 1.0 / (PI * 2f64.sqrt()); // Poincare constant of the unit square, m
    println!("sheet 1 m x 1 m, T = {:.0} N/m, lift b = {} m; C_P = 1/(pi sqrt 2) = {:.6} m", T, B, cp);
    println!("shape | ||u||^2 (m^4) closed, quadrature | ||grad u||^2 (m^2) closed, quadrature | energy (J) | ||u||/||grad u|| (m)");
    let bump = |x: f64, y: f64| B * (PI * x).sin() * (PI * y).sin();
    let pyr = |x: f64, y: f64| B * (1.0 - (2.0 * x - 1.0).abs().max((2.0 * y - 1.0).abs()));
    let shapes: [(&str, &dyn Fn(f64, f64) -> f64, f64, f64); 2] =
        [("bump", &bump, B * B / 4.0, B * B * PI * PI / 2.0), ("pyramid", &pyr, B * B / 6.0, 4.0 * B * B)];
    for (name, u, n2, g2) in shapes {
        let qn = quad2(|x, y| u(x, y).powi(2)); let qg = quad2(|x, y| grad2(&u, x, y));
        println!("{} | {}, {} | {:.6}, {:.6} | {:.6} | {:.6}", name, sci(n2), sci(qn), g2, qg, T / 2.0 * g2, (n2 / g2).sqrt());
        assert!((qn - n2).abs() < 1e-4 * n2 && (qg - g2).abs() < 1e-2 * g2 && (n2 / g2).sqrt() <= cp + 1e-12);
        if name == "bump" { assert!(((qn / qg).sqrt() - cp).abs() < 1e-6); } // the bump attains C_P: no smaller constant works
    }
    let (n2, g2, l) = needle(1e-3);
    println!("needle, tip 1 mm | {} | {:.6} | {:.6} | {:.6}", sci(n2), g2, T / 2.0 * g2, (n2 / g2).sqrt());
    println!("  ln(R/eps) = {:.5}; slope at the tip b/(eps ln(R/eps)) = {:.3}", l, B / (1e-3 * l));
    let chart: Vec<f64> = (2..11).map(|k| T / 2.0 * needle(10f64.powi(-k)).1).collect();
    let cs: Vec<String> = chart.iter().map(|e| format!("{:.4}", e)).collect();
    println!("chart, needle energy (J) at eps = 1e-2 ... 1e-10 m: {}", cs.join(", "));
    assert!((0..8).all(|k| chart[k + 1] < chart[k]));
    println!("  energy 0.001 J needs eps = R exp(-{:.2}) = {} m", PI * B * B * T / 0.001, sci(R * (-PI * B * B * T / 0.001).exp()));
    println!("knife edge along the midline: ||grad u||^2 >= 4 b^2 = {:.6} m^2, energy >= {:.6} J", 4.0 * B * B, T / 2.0 * 4.0 * B * B);
    assert!(chart[8] < T / 2.0 * 4.0 * B * B);

    println!("Poincare: lambda_1 = 2 pi^2 = {:.6} /m^2, C_P = {:.6} m", 2.0 * PI * PI, cp);
    let mut errs = vec![];
    for n in [10usize, 20, 40] {
        let lh = lam1(n); let nf = n as f64; let exact = 8.0 * nf * nf * (PI / (2.0 * nf)).sin().powi(2);
        errs.push(2.0 * PI * PI - lh);
        println!("  grid h = {:.4} m: inverse iteration {:.6}, grid formula {:.6}, C_P,h = {:.6} m", 1.0 / nf, lh, exact, 1.0 / lh.sqrt());
        assert!((lh - exact).abs() < 1e-8 * exact);
        assert!((1.0 / lh.sqrt() - cp).abs() < 0.2 / (nf * nf)); // grid constants close in on C_P at order h^2
    }
    let orders: Vec<f64> = (0..2).map(|k| (errs[k] / errs[k + 1]).log2()).collect();
    println!("  observed order of lambda_1: {:.3}, {:.3}", orders[0], orders[1]);
    assert!(orders.iter().all(|&o| 1.9 < o && o < 2.1));

    let kk = 999; // sag under the load: double sine series, odd m, n <= K
    let (mut c, mut s2, mut g2) = (0.0, 0.0, 0.0);
    for m in (1..=kk).step_by(2) { for n in (1..=kk).step_by(2) {
        let (mf, nf) = (m as f64, n as f64);
        let lm = PI * PI * (mf * mf + nf * nf); let a = F / T * 16.0 / (PI * PI * mf * nf * lm);
        c += if ((m + n) / 2 - 1) % 2 == 0 { a } else { -a }; s2 += a * a / 4.0; g2 += lm * a * a / 4.0;
    } }
    println!("sag, f = {:.0} N/m^2 (1.5 mm rubber at 1100 kg/m^3 weighs {:.2} N/m^2):", F, 1.5e-3 * 1100.0 * 9.81);
    println!("  series to m, n <= {}: centre {:.6} m, ||u||^2 = {} m^4, ||grad u||^2 = {} m^2, energy {:.6} J; centre tail <= {} m",
        kk, c, sci(s2), sci(g2), T / 2.0 * g2, sci(F / T / (PI * PI * kk as f64)));
    let mut cent = vec![];
    for n in [20usize, 40, 80] {
        let rhs = vec![vec![F / T; n + 1]; n + 1]; let mut u = vec![vec![0.0; n + 1]; n + 1];
        sor(n, &rhs, &mut u);
        let mut work = 0.0;
        for i in 0..=n { for j in 0..=n { work += F * u[i][j]; } }
        work /= (n * n) as f64; cent.push(u[n / 2][n / 2]);
        println!("  grid h = {:.4} m: centre {:.6} m, ||grad u||^2 = work/T = {} m^2", 1.0 / n as f64, u[n / 2][n / 2], sci(work / T));
        let nf = n as f64;
        assert!((work / T - g2).abs() < 8.0 / nf / nf * g2 && (u[n / 2][n / 2] - c).abs() < 2.0 / nf / nf * c);
    }
    println!("  observed order of the centre sag: {:.3}, {:.3}", ((cent[0] - c) / (cent[1] - c)).log2(), ((cent[1] - c) / (cent[2] - c)).log2());
    let fnorm = F * 1.0; // ||f|| over the unit square, N/m
    println!("  Poincare bounds: ||grad u|| = {:.6} <= C_P ||f||/T = {:.6} m; ||u|| = {:.6} <= C_P^2 ||f||/T = {:.6} m^2",
        g2.sqrt(), cp * fnorm / T, s2.sqrt(), cp * cp * fnorm / T);
    assert!(g2.sqrt() <= cp * fnorm / T && s2.sqrt() <= cp * cp * fnorm / T);
    println!("coercivity: alpha = 1/(1 + C_P^2) = {:.6} (m); in cm, C_P = {:.4}, alpha = {:.6}", 1.0 / (1.0 + cp * cp), 100.0 * cp, 1.0 / (1.0 + 1e4 * cp * cp));
    println!("what breaks:");
    for (d, mm) in [(1e-2, "10"), (1e-3, "1"), (1e-4, "0.1")] { // plateau of radius 0.1 m, wall width d
        let a = 0.1; let g = radial(|_r| (B / d).powi(2), a, a + d);
        println!("  sheer wall, plateau 0.1 m, wall {} mm: ||grad u||^2 = {:.6} m^2, energy {:.4} J", mm, g, T / 2.0 * g);
        assert!((g - PI * B * B * (2.0 * a + d) / d).abs() < 1e-6 * g);
    }
    let fan = |x: f64, y: f64| B * (1.0 - y.atan2(x) / PI); // a 2 cm step in the rim at the origin: the sheet fans around it
    for (d, mm) in [(1e-2, "10"), (1e-3, "1"), (1e-4, "0.1")] { // half circles from radius d out to R
        let g = radial(|r| grad2(&fan, 0.0, r), d, R) / 2.0;
        println!("  rim step 2 cm, fan cut off {} mm from the step: ||grad u||^2 = {:.6} m^2, energy {:.4} J", mm, g, T / 2.0 * g);
        assert!((g - B * B / PI * (R / d).ln()).abs() < 1e-4 * g); // the floor (T b^2 / 2 pi) ln(R/d), attained
    }
    println!("  free rim, whole sheet lifted 2 cm: ||u||^2 = {} m^4, ||grad u||^2 = 0; net load {:.0} N, needs 0", sci(B * B), fnorm);
    println!("ALL CHECKS PASS");
}
