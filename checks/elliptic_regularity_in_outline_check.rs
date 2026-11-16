// Elliptic regularity on a heated brick wall: -(k u')' = f, u(0) = 20 C, u(L) = 0 C.
use std::f64::consts::PI;

const L: f64 = 0.2; const K: f64 = 0.77; const T_IN: f64 = 20.0; // m, W/(m K), C
const Q: f64 = 100.0; const A: f64 = 0.03; const W: f64 = 0.01; // W/m2, m, m
const F_BOX: f64 = Q / (2.0 * W); // 5000 W/m3 in the cable layer
const KW: f64 = 0.035; // wool, for the two-material wall

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let acc: f64 = (1..n).fold(0.0, |s, i| s + (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h));
    (g(a) + g(b) + acc) * h / 3.0
}
fn bump(t: f64) -> f64 { if t.abs() < 1.0 { (-1.0 / (1.0 - t * t)).exp() } else { 0.0 } }
fn i0() -> f64 { simpson(&bump, -1.0, 1.0, 4000) }
fn f_bump(x: f64, i0: f64) -> f64 { Q / (W * i0) * bump((x - A) / W) }
fn df_bump(x: f64, i0: f64) -> f64 {
    let t = (x - A) / W;
    if t.abs() < 1.0 { f_bump(x, i0) * (-2.0 * t / (1.0 - t * t).powf(2.0)) / W } else { 0.0 }
}
// integral of (x - y) f(y) dy from 0 to x: heat made before x, weighted
fn qint(kind: &str, x: f64, i0: f64) -> f64 {
    match kind {
        "foil" => Q * (x - A).max(0.0),
        "box" => if x <= A - W { 0.0 } else if x <= A + W { F_BOX * (x - A + W).powf(2.0) / 2.0 } else { Q * (x - A) },
        _ => {
            let hi = x.min(A + W);
            if hi > A - W { simpson(&|y| (x - y) * f_bump(y, i0), A - W, hi, 2000) } else { 0.0 }
        }
    }
}
fn c0() -> f64 { Q * (L - A) / L - K * T_IN / L } // flux into the room at x = 0 (Step 1)
fn u_exact(kind: &str, x: f64, i0: f64) -> f64 { T_IN + (c0() * x - qint(kind, x, i0)) / K }

// hat functions on n equal elements: the weak form only
fn galerkin(n: usize, kind: &str, i0: f64) -> (Vec<f64>, f64) {
    let h = L / n as f64;
    let kel: Vec<f64> = (0..n)
        .map(|e| if kind == "wall2" && (e as f64 + 0.5) * h < 0.1 { KW } else if kind == "wall2" { 0.77 } else { K })
        .collect();
    let mut b = vec![0.0; n + 1];
    if kind == "foil" { b[(A / h).round() as usize] = Q; }
    for e in 0..n {
        let x0 = e as f64 * h;
        let inside = A - W - 1e-12 <= x0 && x0 < A + W - 1e-12;
        if kind == "box" && inside { b[e] += F_BOX * h / 2.0; b[e + 1] += F_BOX * h / 2.0; }
        if kind == "bump" && inside {
            b[e] += simpson(&|y| f_bump(y, i0) * (x0 + h - y) / h, x0, x0 + h, 16);
            b[e + 1] += simpson(&|y| f_bump(y, i0) * (y - x0) / h, x0, x0 + h, 16);
        }
    }
    let lo: Vec<f64> = (1..n).map(|i| -kel[i - 1] / h).collect();
    let mut di: Vec<f64> = (1..n).map(|i| (kel[i - 1] + kel[i]) / h).collect();
    let up: Vec<f64> = (1..n).map(|i| -kel[i] / h).collect();
    let mut rhs: Vec<f64> = b[1..n].to_vec();
    rhs[0] += kel[0] / h * T_IN;
    for i in 1..n - 1 { // Thomas algorithm
        let m = lo[i] / di[i - 1]; di[i] -= m * up[i - 1]; rhs[i] -= m * rhs[i - 1];
    }
    let mut u = vec![0.0; n - 1];
    u[n - 2] = rhs[n - 2] / di[n - 2];
    for i in (0..n - 2).rev() { u[i] = (rhs[i] - up[i] * u[i + 1]) / di[i]; }
    let mut out = vec![T_IN]; out.extend(u); out.push(0.0);
    (out, h)
}
// root-mean-square of first, second and third differences over the wall
fn rms_diffs(u: &[f64], h: f64) -> (f64, f64, f64) {
    let n = u.len() - 1;
    let (mut s1, mut s2, mut s3) = (0.0, 0.0, 0.0);
    for i in 0..n { s1 += h * ((u[i + 1] - u[i]) / h).powf(2.0); }
    for i in 1..n { s2 += h * ((u[i + 1] - 2.0 * u[i] + u[i - 1]) / h.powf(2.0)).powf(2.0); }
    for i in 1..n - 1 { s3 += h * ((u[i + 2] - 3.0 * u[i + 1] + 3.0 * u[i] - u[i - 1]) / h.powf(3.0)).powf(2.0); }
    ((s1 / L).sqrt(), (s2 / L).sqrt(), (s3 / L).sqrt())
}
// integral of |D2 u|^2 over the sector, u = r^alpha sin(alpha phi)
fn corner(alpha: f64, opening: f64, eps: f64) -> f64 {
    let u = |x: f64, y: f64| {
        let mut ph = y.atan2(x);
        if ph < -PI / 4.0 { ph += 2.0 * PI; }
        x.hypot(y).powf(alpha) * (alpha * ph).sin()
    };
    let hess2 = |r: f64, p: f64| {
        let (x, y, d) = (r * p.cos(), r * p.sin(), 1e-3 * r);
        let uxx = (u(x + d, y) - 2.0 * u(x, y) + u(x - d, y)) / d.powf(2.0);
        let uyy = (u(x, y + d) - 2.0 * u(x, y) + u(x, y - d)) / d.powf(2.0);
        let uxy = (u(x + d, y + d) - u(x + d, y - d) - u(x - d, y + d) + u(x - d, y - d)) / (4.0 * d * d);
        uxx.powf(2.0) + uyy.powf(2.0) + 2.0 * uxy.powf(2.0)
    };
    simpson(&|s| simpson(&|p| hess2(s.exp(), p), 0.0, opening, 60) * (2.0 * s).exp(), eps.ln(), 0.0, 200)
}
fn join(v: &[f64], d: usize) -> String { v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let (i0, c0) = (i0(), c0());
    println!("wall: L = {} m, k = {} W/(m K), faces {:.0} C and 0 C, heater {:.0} W/m2 centred at {} m", L, K, T_IN, Q, A);
    println!("unheated loss {:.4} W/m2; heater sends {:.4} to the room side, {:.4} outward", K * T_IN / L, Q * (L - A) / L, Q * A / L);
    println!("flux at the room face {:.4} W/m2 into the room; at the outside face {:.4} W/m2 out", c0, Q - c0);
    assert!((i0 - 0.443993816).abs() < 1e-8);
    let mut boxmax = 0.0;
    for kind in ["foil", "box", "bump"] {
        let (g, h) = galerkin(10000, kind, i0);
        let (i3, i10) = ((0.03 / h).round() as usize, (0.10 / h).round() as usize);
        let (e3, e10) = (u_exact(kind, 0.03, i0), u_exact(kind, 0.10, i0));
        let mut imax = 0;
        for i in 0..g.len() { if g[i] > g[imax] { imax = i; } }
        if kind == "box" { boxmax = g[imax]; }
        println!("{:4}: u(3 cm) flux formula {:.6}, Galerkin {:.6}; u(10 cm) {:.6}, {:.6}; peak {:.4} C at {:.3} cm",
                 kind, e3, g[i3], e10, g[i10], g[imax], imax as f64 * h * 100.0);
        assert!((e3 - g[i3]).abs() < 1e-6 && (e10 - g[i10]).abs() < 1e-6);
        assert!((e10 - (T_IN / 2.0 + Q * A * (L - 0.10) / (K * L))).abs() < 1e-9);
    }
    let xp = A - W + c0 / F_BOX;
    let peak_hand = T_IN + c0 * (A - W) / K + (c0 * (xp - A + W) - F_BOX * (xp - A + W).powf(2.0) / 2.0) / K;
    println!("box by hand: f = {:.0} W/m3, bend {:.2} K/m2, u(2 cm) {:.4} C, peak {:.4} C at {:.2} cm",
             F_BOX, -F_BOX / K, T_IN + c0 * (A - W) / K, peak_hand, xp * 100.0);
    assert!((peak_hand - boxmax).abs() < 1e-5);
    let hd = 1e-4; let res = -K * (u_exact("bump", 0.03 + hd, i0) - 2.0 * u_exact("bump", 0.03, i0) + u_exact("bump", 0.03 - hd, i0)) / hd.powf(2.0);
    println!("bump residual at 3 cm: -k u'' = {:.2}, f = {:.2} W/m3", res, f_bump(0.03, i0));
    assert!((res - f_bump(0.03, i0)).abs() < 1e-3 * f_bump(0.03, i0));
    let rb2 = (simpson(&|x| f_bump(x, i0).powf(2.0), A - W, A + W, 4000) / L).sqrt() / K;
    let rb3 = (simpson(&|x| df_bump(x, i0).powf(2.0), A - W, A + W, 4000) / L).sqrt() / K;
    println!("limits: box rms bend {:.2} K/m2; bump rms bend {:.2} K/m2, rms third derivative {:.0} K/m3",
             F_BOX / K * (2.0 * W / L).sqrt(), rb2, rb3);
    let mut table = std::collections::HashMap::new();
    for kind in ["foil", "box", "bump", "wall2"] {
        for n in [100usize, 1000, 10000] {
            let (u, h) = galerkin(n, kind, i0);
            let (s1, s2, s3) = rms_diffs(&u, h);
            table.insert((kind, n), (s1, s2, s3));
            let e = format!("{:.4e}", s3).replace("e", "e+0");
            println!("{:5} h = {:5.2} mm: rms slope {:9.4} K/m, rms 2nd diff {:10.2} K/m2, rms 3rd diff {} K/m3", kind, h * 1000.0, s1, s2, e);
        }
    }
    for n in [100usize, 1000] {
        assert!((table[&("foil", 10 * n)].1 / table[&("foil", n)].1 - 10f64.sqrt()).abs() < 1e-6);
        assert!((table[&("box", 10 * n)].2 / table[&("box", n)].2 - 10f64.sqrt()).abs() < 0.05);
    }
    assert!((table[&("box", 10000)].1 - F_BOX / K * (2.0 * W / L).sqrt()).abs() < 1e-2 * table[&("box", 10000)].1);
    assert!((table[&("bump", 10000)].1 - rb2).abs() < 1e-3 * rb2 && (table[&("bump", 10000)].2 - rb3).abs() < 1e-2 * rb3);
    for n in [100usize, 1000, 10000] {
        let h = L / n as f64;
        println!("foil formula (Q/k)/sqrt(hL) at h = {:5.2} mm: {:.2} K/m2", h * 1000.0, Q / K / (h * L).sqrt());
        assert!((table[&("foil", n)].1 - Q / K / (h * L).sqrt()).abs() < 1e-6 * table[&("foil", n)].1);
    }
    let (u2, h2) = galerkin(10000, "wall2", i0);
    let j = (0.1 / h2).round() as usize; let jump = (u2[j + 1] - u2[j] - u2[j] + u2[j - 1]) / h2;
    let tj = T_IN * (0.1 / 0.77) / (0.1 / KW + 0.1 / 0.77);
    println!("two-material wall: joint {:.6} C (resistances {:.6}), slope jump {:.2} K/m", u2[j], tj, jump);
    assert!((u2[j] - tj).abs() < 1e-9 && (table[&("wall2", 100)].1 - jump / (0.002 * L).sqrt()).abs() < 1e-6 * jump);
    for (eps, name) in [(1e-2, "1e-02"), (1e-4, "1e-04"), (1e-6, "1e-06")] {
        let (num, exact) = (corner(2.0 / 3.0, 1.5 * PI, eps), 2.0 * PI / 9.0 * (eps.powf(-2.0 / 3.0) - 1.0));
        println!("corner 270 deg, eps = {}: H2 energy {:.4}, closed form {:.4} (scaled)", name, num, exact);
        assert!((num - exact).abs() < 1e-4 * exact);
    }
    let c90 = corner(2.0, 0.5 * PI, 1e-6);
    println!("corner  90 deg, eps = 1e-06: H2 energy {:.4}, closed form {:.4} (scaled)", c90, 2.0 * PI * (1.0 - 1e-12));
    assert!((c90 - 2.0 * PI).abs() < 1e-4);
    println!("chart, depth cm: {}", (0..21).map(|i| i.to_string()).collect::<Vec<_>>().join(", "));
    let heated: Vec<f64> = (0..21).map(|i| u_exact("bump", i as f64 / 100.0, i0)).collect();
    println!("chart, heated u: {}", join(&heated.iter().map(|v| (v * 100.0).round() / 100.0 + 0.0).collect::<Vec<_>>(), 2));
    let unheated: Vec<f64> = (0..21).map(|i| T_IN * (1.0 - i as f64 / 20.0)).collect();
    println!("chart, unheated: {}", join(&unheated, 2));
    let xs: Vec<f64> = (0..16).map(|i| 1.5 + 0.2 * i as f64).collect();
    println!("chart, bend x cm: {}", join(&xs, 1));
    let bx: Vec<f64> = xs.iter().map(|&x| if 2.0 < x && x < 4.0 { -F_BOX / K } else { 0.0 }).collect();
    println!("chart, box bend: {}", join(&bx, 0));
    let bb: Vec<f64> = xs.iter().map(|&x| -f_bump(x / 100.0, i0) / K + 0.0).collect();
    println!("chart, bump bend: {}", join(&bb, 0));
    println!("ALL CHECKS PASS");
}
