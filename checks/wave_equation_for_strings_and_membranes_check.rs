// Waves on strings and drums -- the check behind the card.  Rust std only, no crates.
// Road 1: the mode formulas.  Road 2: shooting (RK4 + bisection) on the string's
// shape equation.  Road 3: a time simulation of the square drum, then a written-out
// Fourier scan of one point's motion, to see which frequencies it actually rings at.
use std::f64::consts::PI;

const L: f64 = 0.648; // guitar high E: scale length, m
const F1: f64 = 329.63; // open note, Hz

// Road 2: march X'' = -k^2 X from X(0) = 0, X'(0) = 1 with RK4; return X(L) (or X'(L))
fn shoot(k: f64, free_end: bool) -> f64 {
    let steps = 400;
    let h = L / steps as f64;
    let (mut x, mut v) = (0.0f64, 1.0f64);
    for _ in 0..steps {
        let (a1, b1) = (v, -k * k * x);
        let (a2, b2) = (v + h / 2.0 * b1, -k * k * (x + h / 2.0 * a1));
        let (a3, b3) = (v + h / 2.0 * b2, -k * k * (x + h / 2.0 * a2));
        let (a4, b4) = (v + h * b3, -k * k * (x + h * a3));
        (x, v) = (x + h / 6.0 * (a1 + 2.0 * a2 + 2.0 * a3 + a4), v + h / 6.0 * (b1 + 2.0 * b2 + 2.0 * b3 + b4));
    }
    if free_end { v } else { x }
}

// scan k for sign changes of the end value, then bisect each one
fn allowed_k(count: usize, free_end: bool) -> Vec<f64> {
    let (mut found, mut k, dk) = (Vec::new(), 0.5f64, 0.5f64);
    let mut prev = shoot(k, free_end);
    while found.len() < count {
        let nxt = shoot(k + dk, free_end);
        if prev * nxt < 0.0 {
            let (mut lo, mut hi) = (k, k + dk);
            for _ in 0..50 {
                let mid = (lo + hi) / 2.0;
                if shoot(lo, free_end) * shoot(mid, free_end) <= 0.0 { hi = mid; } else { lo = mid; }
            }
            found.push((lo + hi) / 2.0);
        }
        (k, prev) = (k + dk, nxt);
    }
    found
}

fn lap(w: &Vec<Vec<f64>>, i: usize, j: usize) -> f64 {
    w[i + 1][j] + w[i - 1][j] + w[i][j + 1] + w[i][j - 1] - 4.0 * w[i][j]
}

fn sorted_modes(f: impl Fn(f64, f64) -> f64, top: i32) -> Vec<(f64, i32, i32)> {
    let mut v: Vec<(f64, i32, i32)> = Vec::new();
    for m in 1..top { for n in 1..top { v.push((f(m as f64, n as f64), m, n)); } }
    v.sort_by(|p, q| p.0.partial_cmp(&q.0).unwrap().then(p.1.cmp(&q.1)).then(p.2.cmp(&q.2)));
    v
}

fn main() {
    let (d, rho, e_steel) = (0.254e-3f64, 7850.0f64, 200e9f64);
    let area = PI * d * d / 4.0;
    let (mu, c) = (rho * area, 2.0 * L * F1);
    let t = mu * c * c;
    println!("string: {} m long, open {} Hz, steel {:.3} mm thick, {:.0} kg/m^3, {:.0} GPa", L, F1, d * 1000.0, rho, e_steel / 1e9);
    println!("string: mass per metre {:.4} g/m, wave speed {:.2} m/s, tension {:.1} N", mu * 1000.0, c, t);

    println!("string harmonics: n, formula n c/(2L), shooting, nodes inside the string");
    for (i, k) in allowed_k(4, false).iter().enumerate() {
        let n = (i + 1) as f64;
        let (fs, fnn) = (c * k / (2.0 * PI), n * c / (2.0 * L));
        assert!((fs - fnn).abs() < 1e-6 * fnn);
        println!("  {}  {:8.2} Hz  {:8.2} Hz  {}", i + 1, fnn, fs, i);
    }
    println!("touch lightly at a point: lowest harmonic with a node there");
    for (name, frac) in [("1/2 (12th fret)", 0.5f64), ("1/3 (7th fret)", 1.0 / 3.0), ("1/4 (5th fret)", 0.25), ("1/5 (4th fret)", 0.2)] {
        let n = (1..20).find(|&m| (m as f64 * PI * frac).sin().abs() < 1e-9).unwrap();
        println!("  {:<16} at {:.3} m: harmonic {}, {:.2} Hz", name, frac * L, n, n as f64 * F1);
    }
    assert_eq!((1..20).find(|&m| (m as f64 * PI / 3.0).sin().abs() < 1e-9).unwrap(), 3);
    let k400 = 2.0 * PI * 400.0 / c; // a frequency not on the list
    println!("try 400 Hz: shape at the bridge sin(kL) = {:.4}, by shooting {:.4}, not 0", (k400 * L).sin(), k400 * shoot(k400, false));
    let xs: Vec<String> = (0..11).map(|i| format!("{:5.3}", L * i as f64 / 10.0)).collect();
    println!("chart, position m       {}", xs.join(" "));
    for n in 1..=3 {
        let pts: Vec<String> = (0..11).map(|i| L * i as f64 / 10.0)
            .map(|x| format!("{:5.2}", ((n as f64 * PI * x / L).sin() * 100.0).round() / 100.0 + 0.0)).collect();
        println!("chart, harmonic {} shape {}", n, pts.join(" "));
    }

    // ---- the square drum: side a, wave speed cd ----
    let (a, cd) = (0.30f64, 100.0f64);
    let f_mn = |m: f64, n: f64| cd / (2.0 * a) * (m * m + n * n).sqrt();
    let modes = sorted_modes(f_mn, 5);
    println!("square drum, side 0.3 m, wave speed 100.0 m/s: modes up to 650 Hz");
    let mut notes: Vec<f64> = Vec::new();
    for &(f, m, n) in &modes {
        if f < 650.0 {
            println!("  ({},{})  {:7.2} Hz  ratio {:.3}", m, n, f, f / modes[0].0);
            let rf = (f * 1e6).round() / 1e6;
            if notes.last() != Some(&rf) { notes.push(rf); }
        }
    }
    let rect = sorted_modes(|m, n| 50.0 * ((m / 0.3).powi(2) + (n / 0.2).powi(2)).sqrt(), 4);
    let rs: Vec<String> = rect[..4].iter().map(|&(f, m, n)| format!("({},{}) {:.1} Hz", m, n, f)).collect();
    println!("try: 0.30 x 0.20 m head, first notes {}", rs.join(", "));

    // Road 3: leapfrog simulation of u_tt = c^2 (u_xx + u_yy), edges clamped, released from rest
    let (nn, dt, steps, keep) = (30usize, 5e-5f64, 4000usize, 4usize);
    let dx = a / nn as f64;
    let r2 = (cd * dt / dx).powi(2); // (c dt / dx)^2 = 0.25, inside the stability limit 0.5
    let mut prev = vec![vec![0.0f64; nn + 1]; nn + 1];
    for i in 1..nn { for j in 1..nn {
        let (x, y) = (i as f64 * dx - 0.09, j as f64 * dx - 0.06);
        prev[i][j] = (-(x * x + y * y) / (2.0 * 0.03f64.powi(2))).exp();
    } }
    let mut u = vec![vec![0.0f64; nn + 1]; nn + 1];
    for i in 1..nn { for j in 1..nn { u[i][j] = prev[i][j] + 0.5 * r2 * lap(&prev, i, j); } }
    let mut rec: Vec<f64> = Vec::new();
    for s in 1..steps {
        if s % keep == 0 { rec.push(u[21][13]); } // the point (0.21 m, 0.13 m)
        let mut nxt = vec![vec![0.0f64; nn + 1]; nn + 1];
        for i in 1..nn { for j in 1..nn { nxt[i][j] = 2.0 * u[i][j] - prev[i][j] + r2 * lap(&u, i, j); } }
        (prev, u) = (u, nxt);
    }
    let (mlen, ts) = (rec.len(), keep as f64 * dt);
    let win: Vec<f64> = rec.iter().enumerate()
        .map(|(k, r)| r * (0.5 - 0.5 * (2.0 * PI * k as f64 / (mlen - 1) as f64).cos())).collect();
    let power = |f: f64| -> f64 {
        let (re, im) = win.iter().enumerate().fold((0.0f64, 0.0f64), |(re, im), (k, w)| {
            let ph = 2.0 * PI * f * k as f64 * ts; (re + w * ph.cos(), im + w * ph.sin()) });
        re * re + im * im
    };
    let grid: Vec<(i32, f64)> = (100..651).map(|f| (f, power(f as f64))).collect();
    let top = grid.iter().map(|g| g.1).fold(f64::MIN, f64::max);
    let mut peaks: Vec<f64> = Vec::new();
    for w in grid.windows(3) {
        let ((_, pa), (fb, pb), (_, pc)) = (w[0], w[1], w[2]);
        if pb > pa && pb >= pc && pb > 1e-3 * top {
            let cand = (0..201).map(|q| (fb - 1) as f64 + 0.01 * q as f64).map(|f| (f, power(f)));
            peaks.push(cand.fold((0.0f64, f64::MIN), |b, x| if x.1 > b.1 { x } else { b }).0);
        }
    }
    println!("simulation: {} x {} grid, {} steps of {:.0} us; peaks heard at (0.21, 0.13) m", nn, nn, steps, dt * 1e6);
    assert_eq!(peaks.len(), notes.len());
    for (p, f) in peaks.iter().zip(notes.iter()) {
        assert!((p - f).abs() < 0.01 * f);
        println!("  peak {:7.1} Hz   formula {:7.1} Hz   off by {:+.2}%", p, f, 100.0 * (p - f) / f);
    }

    println!("figure, 400 px per m, panel 120 px = 0.30 m; node lines: (2,1) x = 60; (1,2) y = 60; (1,2)+(2,1) from (0,120) to (120,0), y measured up");
    // the mix of (1,2) and (2,1) vanishes on the anti-diagonal x + y = a
    let mix = |x: f64, y: f64| (PI * x / a).sin() * (2.0 * PI * y / a).sin() + (2.0 * PI * x / a).sin() * (PI * y / a).sin();
    assert!([0.03f64, 0.11, 0.2].iter().map(|&s| mix(s, a - s).abs()).fold(0.0, f64::max) < 1e-12 && mix(0.1, 0.1).abs() > 0.5);

    // ---- what breaks, and outside the range ----
    println!("wrong: drum overtone taken as 2 x f11: {:.1} Hz, true next mode {:.1} Hz", 2.0 * modes[0].0, modes[1].0);
    println!("wrong: frequencies add, c/(2a) (1+2): {:.1} Hz, true (1,2) {:.1} Hz", cd / (2.0 * a) * 3.0, f_mn(1.0, 2.0));
    println!("wrong: dropped the 2, f1 = c/L: {:.2} Hz", c / L);
    let ff: Vec<f64> = allowed_k(2, true).iter().map(|k| c * k / (2.0 * PI)).collect();
    assert!((ff[0] - c / (4.0 * L)).abs() < 1e-6 * ff[0] && (ff[1] / ff[0] - 3.0).abs() < 1e-6);
    println!("wrong: one end free: notes {:.2} Hz, {:.2} Hz (odd multiples only)", ff[0], ff[1]);
    for amp in [1e-3f64, 5e-3] { // big swing in harmonic 1 stretches the string
        let dt_n = e_steel * area * (PI * amp / L).powi(2) / 4.0; // peak tension rise = EA x mean strain at full swing
        let rise = 3.0 / 8.0 * F1 * dt_n / t; // the rise comes and goes twice a cycle: 3/8 of f1 dT/T, not 1/2
        println!("swing {:.0} mm: peak tension +{:.2} N, pitch +{:.2} Hz, {:.2}%", amp * 1000.0, dt_n, rise, 100.0 * rise / F1);
    }

    // ---- beside it: an electron in a 1 nm box (CODATA 2022) ----
    let (h, me, ev, lb) = (6.62607015e-34f64, 9.1093837139e-31f64, 1.602176634e-19f64, 1e-9f64);
    let e1 = h * h / (8.0 * me * lb * lb);
    let lv: Vec<String> = [1.0f64, 2.0, 3.0].iter().map(|n| format!("{:.3}", n * n * e1 / ev)).collect();
    println!("electron, 1 nm box: E1 {:.4e} J; levels {} eV; ratios 1 : 4 : 9 against the string's 1 : 2 : 3", e1, lv.join(", "));
    println!("ALL CHECKS PASS");
}
