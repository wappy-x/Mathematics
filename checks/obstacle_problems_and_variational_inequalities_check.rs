// The obstacle problem: a rubber sheet on a 20 cm hoop, pressed over a stone ball.
// Unknown u(r): sheet height in cm at distance r cm from the centre. Standard library only.
use std::f64::consts::PI;

const R: f64 = 20.0; // hoop radius cm
const RHO: f64 = 10.0; // stone radius cm
const H: f64 = 2.0; // stone top above the hoop plane, cm
const T: f64 = 50.0; // tension N/m
const C: f64 = RHO - H; // the stone's centre sits 8 cm below the hoop plane

fn psi(r: f64) -> f64 { if r < RHO { (RHO * RHO - r * r).sqrt() - C } else { -C } }
fn dpsi(r: f64) -> f64 { -r / (RHO * RHO - r * r).sqrt() }
fn press(r: f64) -> f64 { let s = (RHO * RHO - r * r).sqrt(); RHO * RHO / (s * s * s) + 1.0 / s }
fn z(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } }
fn tf(b: bool) -> &'static str { if b { "True" } else { "False" } }

fn simpson(f: &dyn Fn(f64) -> f64, x0: f64, x1: f64) -> f64 {
    let n = 2000;
    let h = (x1 - x0) / n as f64;
    let mut s = f(x0) + f(x1);
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(x0 + i as f64 * h); }
    s * h / 3.0
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let m = 0.5 * (lo + hi);
        if (f(lo) < 0.0) == (f(m) < 0.0) { lo = m; } else { hi = m; }
    }
    0.5 * (lo + hi)
}

fn psor(n: usize) -> (f64, f64, f64, f64, usize) {
    let h = R / n as f64;
    let r: Vec<f64> = (0..=n).map(|i| i as f64 * h).collect();
    let ob: Vec<f64> = r.iter().map(|&x| psi(x)).collect();
    let mut v: Vec<f64> = ob.iter().map(|&o| o.max(0.0)).collect();
    v[n] = 0.0;
    let w = 2.0 / (1.0 + (PI / n as f64).sin());
    let mut sweep = 0;
    for s in 1..=100000 {
        sweep = s;
        let mut big: f64 = 0.0;
        for i in 0..n {
            let (lo, hi) = (if i == 0 { 0.0 } else { r[i] - h / 2.0 }, r[i] + h / 2.0);
            let gs = if i == 0 { v[1] } else { (lo * v[i - 1] + hi * v[i + 1]) / (lo + hi) };
            let new = ob[i].max(v[i] + w * (gs - v[i]));
            big = big.max((new - v[i]).abs());
            v[i] = new;
        }
        if big < 1e-13 { break; }
    }
    let k = (0..n).filter(|&i| v[i] - ob[i] < 1e-12).max().unwrap();
    let mut eh = 0.0;
    for i in 0..n { eh += PI * (r[i] + h / 2.0) * (v[i + 1] - v[i]) * (v[i + 1] - v[i]) / h; }
    (v[n / 2], r[k], r[k + 1], eh, sweep)
}

fn main() {
    // Road 1: smooth fit. Outside contact u = A log(r/R); match the stone's height and slope at r = a.
    let fit = |a: f64| a * dpsi(a) * (a / R).ln() - psi(a);
    let a = bisect(&fit, 1.0, 6.0);
    let aa = a * dpsi(a);
    let u = |r: f64| if r <= a { psi(r) } else { aa * (r / R).ln() + 0.0 };
    let du = |r: f64| if r <= a { dpsi(r) } else { aa / r };
    println!("smooth fit: F(1) = {:.4}, F(6) = {:.4} cm; root a = {:.4} cm", fit(1.0), fit(6.0), a);
    println!("contact radius a = {:.4} cm ({:.2} cm), A = {:.4} cm, height at edge {:.4} cm, slope at edge {:.4}", a, a, aa, psi(a), dpsi(a));
    println!("by hand: top {:.0} cm, a^2 = {:.4}, s = {:.4} cm, log(a/R) = {:.4}, log(10/R) = {:.4}, A^2 = {:.4} cm^2", H, a * a, (RHO * RHO - a * a).sqrt(), (a / R).ln(), (10.0 / R).ln(), aa * aa);
    for r in [0.0, 1.0, 2.0, a, 4.0, 6.0, 8.0, 10.0, 15.0, 20.0] {
        println!("r = {:7.4} cm: sheet {:7.4} cm, stone {:7.4} cm, gap {:7.4} cm", r, u(r), psi(r), u(r) - psi(r));
    }
    let gmin = (1..=1000).map(|k| { let r = a + (R - a) * k as f64 / 1000.0; u(r) - psi(r) }).fold(f64::INFINITY, f64::min);
    assert!(gmin > 0.0 && (u(a) - psi(a)).abs() < 1e-12);

    // Energy E = (1/2) integral |grad u|^2 dA = pi * integral u'^2 r dr, in cm^2
    let e_in = PI * simpson(&|r| dpsi(r) * dpsi(r) * r, 0.0, a);
    let e_out = PI * simpson(&|r| (aa / r) * (aa / r) * r, a, R);
    let e_out_exact = PI * aa * aa * (R / a).ln();
    let e = e_in + e_out;
    println!("energy: contact {:.4}, free part {:.4} (exact {:.4}), total {:.4} cm^2", e_in, e_out, e_out_exact, e);
    println!("stored energy T E = {:.2} mJ", T * e * 1e-4 * 1e3);
    assert!((e_out - e_out_exact).abs() < 1e-9);

    // The equation, by centred differences of u'' + u'/r: equals the stone's Laplacian on contact, 0 off it
    let lap = |r: f64, h: f64| (u(r + h) - 2.0 * u(r) + u(r - h)) / (h * h) + (u(r + h) - u(r - h)) / (2.0 * h * r);
    for h in [0.1, 0.05] {
        println!("step {} cm: -Laplacian of sheet at r = 1.5 cm {:.6} (stone {:.6}), at r = 10 cm {:.6} per cm", h, -lap(1.5, h), press(1.5), lap(10.0, h).abs());
    }
    assert!((-lap(1.5, 0.05) - press(1.5)).abs() < 1e-4 && lap(10.0, 0.05).abs() < 1e-4);
    println!("contact pressure T x (-Laplacian): top {:.1} Pa, edge {:.1} Pa", T * press(0.0) * 100.0, T * press(a) * 100.0);

    // Force balance: the stone's push equals the hoop's pull (N)
    let f_press = T * simpson(&|r| press(r) * 2.0 * PI * r, 0.0, a) / 100.0;
    let f_rim = T * 2.0 * PI * R * du(R).abs() / 100.0;
    println!("stone's push: pressure integral {:.4} N, hoop flux {:.4} N ({:.2} N)", f_press, f_rim, f_rim);
    assert!((f_press - f_rim).abs() < 1e-6);

    // Road 2: the variational inequality, tested on rival sheets v. I = integral grad u . grad (v - u) dA
    let split = |f: &dyn Fn(f64) -> f64| simpson(f, 0.0, a) + simpson(f, a, 6.0) + simpson(f, 6.0, R);
    let bump = |r: f64| 1.0 - r * r / (R * R);
    let far = |r: f64| if r > 6.0 { (PI * (r - 6.0) / (R - 6.0)).sin() * (PI * (r - 6.0) / (R - 6.0)).sin() } else { 0.0 };
    let dbump = |r: f64| -2.0 * r / (R * R);
    let dfar = |r: f64| if r > 6.0 { PI / (R - 6.0) * (2.0 * PI * (r - 6.0) / (R - 6.0)).sin() } else { 0.0 };
    let tests: [(&str, f64, &dyn Fn(f64) -> f64, &dyn Fn(f64) -> f64); 4] = [("lift 0.5 cm", 0.5, &bump, &dbump),
        ("press 0.5 cm", -0.5, &bump, &dbump), ("wiggle +0.3 cm", 0.3, &far, &dfar), ("wiggle -0.3 cm", -0.3, &far, &dfar)];
    for (name, t, f, df) in tests {
        let i_ = 2.0 * PI * t * split(&|r| du(r) * df(r) * r);
        let i_p = 2.0 * PI * t * simpson(&|r| press(r) * f(r) * r, 0.0, a);
        let ev = PI * split(&|r| (du(r) + t * df(r)) * (du(r) + t * df(r)) * r);
        let ok = (0..=2000).map(|k| { let r = R * k as f64 / 2000.0; u(r) + t * f(r) - psi(r) }).fold(f64::INFINITY, f64::min) >= -1e-12;
        let de = PI * t * t * split(&|r| df(r) * df(r) * r);
        println!("{}: admissible {}, I = {:.4} (by parts {:.4}), E(v) - E(u) = {:.4} = I + E(v - u) = {:.4} + {:.4} cm^2", name, tf(ok), z(i_), z(i_p), ev - e, z(i_), de);
        assert!((i_ - i_p).abs() < 1e-6 && (ev - (e + i_ + de)).abs() < 1e-9);
        assert!((i_ >= -1e-9) == ok);
    }

    // Wrong edges: sheet on the stone out to b, then A_b log(r/R), matching height only
    println!("guessed edge b: energy cm^2, deepest cut into the stone mm, slope jump, ring force N/m (negative = pull)");
    let mut jumps = Vec::new();
    let b0 = (RHO * RHO - C * C).sqrt(); // the clipped guess max(stone, 0) leaves the stone here
    for b in [1.0, 2.0, 2.5, a, 3.0, 4.0, 5.0, b0] {
        let bb = psi(b) / (b / R).ln();
        let eb = PI * simpson(&|r| dpsi(r) * dpsi(r) * r, 0.0, b) + PI * bb * bb * (R / b).ln();
        let cut = (1..1000).map(|k| { let r = b + (RHO - b) * k as f64 / 1000.0; psi(r) - bb * (r / R).ln() }).fold(f64::NEG_INFINITY, f64::max);
        let jump = bb / b - dpsi(b);
        jumps.push(jump);
        println!("b = {:.4}: energy {:.4}, cut {:.4}, jump {:.4}, ring {:.2}", b, eb, z(cut.max(0.0)) * 10.0, z(jump), z(-T * jump));
        assert!((cut > 1e-9) == (b < a - 1e-9));
        if b >= a { assert!(eb >= e - 1e-9); }
    }
    assert!(jumps[0] < 0.0 && 0.0 < jumps[7] && jumps[3].abs() < 1e-9);

    // Road 3: projected SOR on a radial grid, minimising the grid energy with u_i >= psi_i
    let mut errs = Vec::new();
    for n in [50usize, 100, 200] {
        let (um, rk, rk1, eh, sw) = psor(n);
        errs.push(eh - e);
        println!("grid N = {}, step {:.2} cm: energy {:.4} cm^2 (error {:.4}), sheet at {:.0} cm {:.6} (error {:.6}), last point on the stone {:.2} cm, first free point {:.2} cm, {} sweeps",
            n, R / n as f64, eh, eh - e, R / 2.0, um, um - u(R / 2.0), rk, rk1, sw);
        assert!((rk - a).abs() <= R / n as f64 && (um - u(R / 2.0)).abs() < 1e-3);
    }
    println!("observed order, energy: {:.2}, {:.2}", (errs[0] / errs[1]).ln() / 2f64.ln(), (errs[1] / errs[2]).ln() / 2f64.ln());
    assert!(errs[2].abs() < errs[1].abs() && errs[1].abs() < errs[0].abs());

    // A hypothesis that fails: a needle. Hold the sheet at 2 cm on a tip of radius d; energy pi H^2 / log(R/d)
    for (name, d) in [("1 mm", 0.1), ("1 micrometre", 1e-4), ("1e-13 cm, a proton", 1e-13)] {
        println!("needle tip radius {}: energy {:.4} cm^2", name, PI * H * H / (R / d).ln());
    }
    println!("figure, hoop +-{:.0} cm, stone centre (0, {:.0}) radius {:.0} cm, contact edge +-{:.4} cm at height {:.4} cm, sheet at 10 cm {:.4} cm", R, -C, RHO, a, psi(a), u(10.0));
    println!("ALL CHECKS PASS");
}
