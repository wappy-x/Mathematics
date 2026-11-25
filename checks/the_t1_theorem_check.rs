// The T(1) theorem -- the same check as the_t1_theorem_check.py, in Rust.
// Standard library only, no crates.  Operator: Calderon's first commutator for
// the corner A(x) = |x|:  C f(x) = p.v. integral of (|x| - |y|)/(x - y)^2 f(y) dy.
// Compile: rustc --edition 2021 -O the_t1_theorem_check.rs -o /tmp/the_t1_theorem
use std::f64::consts::{E, PI};

fn sech(x: f64) -> f64 {
    2.0 * (-x.abs()).exp() / (1.0 + (-2.0 * x.abs()).exp())
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn kern(x: f64, y: f64) -> f64 {
    (x.abs() - y.abs()) / ((x - y) * (x - y))
}

fn t_closed(x: f64, r: f64) -> f64 {
    (x * x / (x * x - r * r).abs()).ln() + 2.0 * r / (x.abs() + r)
}

fn t_quad(x: f64, r: f64) -> f64 {
    let pair = |u: f64| -> f64 {
        if u == 0.0 {
            return 0.0;
        }
        [x + u, x - u].iter().filter(|y| y.abs() < r).map(|&y| kern(x, y)).sum()
    };
    let mut cuts = vec![0.0, r - x.abs(), r + x.abs()];
    for k in 0..8 {
        let c = x.abs() * 2f64.powi(k);
        if c < r {
            cuts.push(c);
        }
    }
    cuts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    cuts.dedup();
    let mut tot = 0.0;
    for w in cuts.windows(2) {
        if w[1] > w[0] {
            tot += simpson(&pair, w[0] + 1e-12, w[1] - 1e-12, 2000);
        }
    }
    tot
}

fn f_anti(x: f64) -> f64 {
    if x != 0.0 { x * x.abs().ln() - x } else { 0.0 }
}

fn osc(a: f64, b: f64) -> f64 {
    let m = 2.0 * (f_anti(b) - f_anti(a)) / (b - a);
    let r = (m / 2.0).exp();
    let mut pts = vec![a];
    for p in [-r, r] {
        if a < p && p < b {
            pts.push(p);
        }
    }
    pts.push(b);
    let g = |x: f64| 2.0 * f_anti(x) - m * x;
    pts.windows(2).map(|w| (g(w[1]) - g(w[0])).abs()).sum::<f64>() / (b - a)
}

fn sym(t: f64, sgn: f64) -> f64 {
    (PI * t).tanh() + sgn * 2.0 * t * sech(PI * t)
}

fn gate_out(x: f64, sgn: f64) -> f64 {
    if sgn > 0.0 {
        (x * x / (x * x - 1.0).abs()).ln() + 2.0 / (x + 1.0)
    } else {
        ((x + 1.0) / (x - 1.0).abs()).ln() - 2.0 / (x + 1.0)
    }
}

fn energy_time(sgn: f64, n: usize) -> f64 {
    let mut tot = 0.0;
    for i in 0..n {
        let s = (i as f64 + 0.5) / n as f64;
        let (w, dw) = (3.0 * s * s - 2.0 * s * s * s, 6.0 * s * (1.0 - s));
        tot += (gate_out(w, sgn).powi(2) + gate_out(1.0 + w, sgn).powi(2)) * dw / n as f64;
        tot += gate_out(2.0 / s, sgn).powi(2) * 2.0 / (s * s) / n as f64;
    }
    2.0 * tot
}

fn energy_mellin(sgn: f64, l: f64, n: usize) -> f64 {
    let h = l / n as f64;
    let mut tot = 0.0;
    for i in 0..n {
        let t = (i as f64 + 0.5) * h;
        tot += sym(t, sgn).powi(2) / (0.25 + t * t);
    }
    2.0 * PI * (tot * h + 2.0 * (PI / 2.0 - (2.0 * l).atan()))
}

fn main() {
    println!("T(1) for the corner: C applied to the gate |y| < R, minus its value at x = 1 m");
    let rs = [10.0, 1000.0, 100000.0];
    for x in [0.1, 0.5, 2.0, 5.0] {
        let d: Vec<f64> = rs.iter().map(|&r| t_closed(x, r) - t_closed(1.0, r)).collect();
        println!("x = {:.1} m: R = 10, 1000, 100000 give {:.6} {:.6} {:.6}; 2 ln x = {:.6}", x, d[0], d[1], d[2], 2.0 * x.ln());
        assert!((d[2] - 2.0 * x.ln()).abs() < 1e-4 * (1.0 + x * x));
        assert!((t_quad(x, 10.0) - t_closed(x, 10.0)).abs() < 1e-6);
    }
    println!("quadrature against closed form at R = 10, x = 0.5 m: {:.6} {:.6}", t_quad(0.5, 10.0), t_closed(0.5, 10.0));
    let raw: Vec<f64> = rs.iter().map(|&r| t_closed(1.0, r)).collect();
    println!("raw value at x = 1 m for R = 10, 1000, 100000: {:.6} {:.6} {:.6}", raw[0], raw[1], raw[2]);

    let mut c0 = 0.0;
    for i in 0..4001 {
        let c = i as f64 / 1000.0;
        if osc(c - 1.0, c + 1.0) > osc(c0 - 1.0, c0 + 1.0) {
            c0 = c;
        }
    }
    let (mut lo, mut hi) = (c0 - 0.001, c0 + 0.001);
    for _ in 0..60 {
        let (m1, m2) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if osc(m1 - 1.0, m1 + 1.0) < osc(m2 - 1.0, m2 + 1.0) { lo = m1 } else { hi = m2 }
    }
    let bmo = osc(lo - 1.0, lo + 1.0);
    println!("BMO norm of T(1) = 2 ln|x|: centred {:.6} = 4/e {:.6}; largest {:.6} at centre/radius {:.4}", osc(-1.0, 1.0), 4.0 / E, bmo, lo);
    assert!((osc(-1.0, 1.0) - 4.0 / E).abs() < 1e-12);
    assert!((osc(-37.0 * 0.3, 37.0 * 1.7) - osc(-0.3, 1.7)).abs() < 1e-9);
    assert!(bmo >= osc(-1.0, 1.0) && bmo < 2.0);

    let (mut a, mut b) = (0.1f64, 2.0f64);
    for _ in 0..80 {
        let m = (a + b) / 2.0;
        if PI * sech(PI * m) + 2.0 - 2.0 * PI * m * (PI * m).tanh() > 0.0 { a = m } else { b = m }
    }
    let peak = PI * sym(a, 1.0);
    assert!((peak - (0..60000).map(|k| PI * sym(k as f64 / 20000.0, 1.0)).fold(0.0, f64::max)).abs() < 1e-8); // road two for the peak: a grid search
    println!("L2 norm of C: peak of the even-signal multiplier at tau = {:.6}, norm {:.6}; straight line {:.6}", a, peak, PI);
    for t in [0.25, a, 1.0] {
        let mp = 2.0 * simpson(&|v: f64| (t * v).sin() / (2.0 * (v / 2.0).sinh()), 1e-9, 80.0, 20000);
        let mq = 2.0 * simpson(&|v: f64| (v / 2.0).sinh() * (t * v).sin() / (2.0 * (1.0 / sech(v / 2.0)).powi(2)), 0.0, 80.0, 20000);
        println!("tau = {:.6}: P {:.6} vs pi tanh {:.6}; Q {:.6} vs 2 pi tau sech {:.6}", t, mp, PI * (PI * t).tanh(), mq, 2.0 * PI * t * sech(PI * t));
        assert!((mp - PI * (PI * t).tanh()).abs() < 1e-6 && (mq - 2.0 * PI * t * sech(PI * t)).abs() < 1e-6);
    }

    for (name, sgn) in [("even gate", 1.0), ("odd gate", -1.0)] {
        let (et, em) = (energy_time(sgn, 40000), energy_mellin(sgn, 40.0, 200000));
        println!("{}, energy 2 V^2 m in: out {:.6} by time, {:.6} by Mellin; stretch {:.6}", name, et, em, (em / 2.0).sqrt());
        assert!((et - em).abs() < 1e-4 && (em / 2.0).sqrt() < peak);
    }
    let wbp = 2.0 * simpson(&|s: f64| gate_out(3.0 * s * s - 2.0 * s * s * s, 1.0) * 6.0 * s * (1.0 - s), 1e-12, 1.0 - 1e-12, 20000);
    println!("weak boundedness: size of <C g, g> on the gate {:.6}, against 2 m", wbp.abs());
    assert!(wbp.abs() < 1e-4);
    for eps in [1e-3f64, 1e-6] {
        let num = 2.0 * simpson(&|w: f64| 1.0 - w.exp(), eps.ln(), 0.0, 20000);
        let formula = 2.0 * ((1.0 / eps).ln() - 1.0 + eps);
        println!("positive kernel, gap {:.6} m: pairing {:.6} by quadrature, {:.6} by formula", eps, num, formula);
        assert!((num - formula).abs() < 1e-6);
    }
    let row = |f: &dyn Fn(f64) -> f64| (0..11).map(|k| format!("{:5.2}", f(k as f64 / 4.0))).collect::<Vec<_>>().join(" ");
    println!("chart, tau        {}", row(&|t| t));
    println!("chart, even       {}", row(&|t| PI * sym(t, 1.0)));
    println!("chart, odd        {}", row(&|t| PI * sym(t, -1.0)));
    println!("chart, straight   {}", row(&|t| PI * ((PI * t).tanh().powi(2) + sech(PI * t).powi(2)).sqrt()));
    println!("ALL CHECKS PASS");
}
