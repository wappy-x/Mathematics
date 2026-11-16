// Levy's inversion formula -- the same check as levy_inversion_and_uniqueness_check.py.
// Standard library only, no crates.  Every integral is Simpson's rule written
// out, and so is the sine integral Si.  A complex number is a small struct.
use std::f64::consts::PI;

#[derive(Clone, Copy)]
struct C { re: f64, im: f64 }

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, n: i64) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for k in 1..n {
        s += (if k % 2 == 1 { 4.0 } else { 2.0 }) * f(a + k as f64 * h);
    }
    s * h / 3.0
}

fn sinc(v: f64) -> f64 { if v == 0.0 { 1.0 } else { v.sin() / v } }

fn si(u: f64) -> f64 { simpson(&sinc, 0.0, u, 2 * (20.0 * u.abs() + 50.0) as i64) }

fn si_series(u: f64) -> f64 {
    let (mut term, mut s) = (u, 0.0);
    for k in 0..40 {
        s += term / (2 * k + 1) as f64;
        term *= -u * u / ((2 * k + 2) * (2 * k + 3)) as f64;
    }
    s
}

fn gg(u: f64) -> f64 { let u = u.abs(); u * si(u) + u.cos() - 1.0 }   // G: area under Si, 0 to |u|

fn phi_u(t: f64) -> C { C { re: sinc(t / 2.0), im: 0.0 } }

fn phi_die(t: f64) -> C {
    let (mut re, mut im) = (0.0, 0.0);
    for k in 1..7 { re += (k as f64 * t).cos(); im += (k as f64 * t).sin(); }
    C { re: re / 6.0, im: im / 6.0 }
}

fn levy(phi: &dyn Fn(f64) -> C, a: f64, b: f64, t_cut: f64, flip: f64) -> f64 {
    let g = |t: f64| -> f64 {
        if t == 0.0 { return b - a; }
        let p = phi(t);
        let wr = ((t * b).sin() - (t * a).sin()) / t;
        let wi = ((t * b).cos() - (t * a).cos()) / t;
        wr * p.re - wi * flip * p.im
    };
    simpson(&g, 0.0, t_cut, 2 * (50.0 * t_cut + 100.0) as i64) / PI
}

fn kernel(x: f64, a: f64, b: f64, t: f64) -> f64 { (si(t * (x - a)) - si(t * (x - b))) / PI }

fn fubini_u(a: f64, b: f64, t: f64) -> f64 {
    (gg(t * (0.5 - a)) - gg(t * (-0.5 - a)) - gg(t * (0.5 - b)) + gg(t * (-0.5 - b))) / (PI * t)
}

fn fubini_die(a: f64, b: f64, t: f64) -> f64 {
    let mut s = 0.0;
    for k in 1..7 { s += kernel(k as f64, a, b, t); }
    s / 6.0
}

fn dens(phi: &dyn Fn(f64) -> C, x: f64, t_cut: f64) -> f64 {
    let g = |t: f64| phi(t).re * (t * x).cos() + phi(t).im * (t * x).sin();
    simpson(&g, 0.0, t_cut, 2 * (50.0 * t_cut + 100.0) as i64) / PI
}

fn f6(v: f64) -> String { format!("{:.6}", v) }

fn main() {
    let ts: Vec<i64> = (0..21).map(|k| 2 * k).collect();
    println!("fingerprint of U: phi_U(4) = {}  first zero at 2 pi = {}", f6(phi_u(4.0).re), f6(2.0 * PI));
    println!("chart, t      {}", ts.iter().map(|t| format!("{:5}", t)).collect::<Vec<_>>().join(" "));
    println!("chart, phi_U  {}", ts.iter().map(|&t| format!("{:5.2}", phi_u(t as f64).re)).collect::<Vec<_>>().join(" "));
    println!("Si(pi) by Simpson {} by series {}  Si(200) = {}  pi/2 = {}", f6(si(PI)), f6(si_series(PI)), f6(si(200.0)), f6(PI / 2.0));
    assert!((si(PI) - si_series(PI)).abs() < 1e-9);
    assert!((si(200.0) - PI / 2.0).abs() < 2.0 / 200.0);

    let (a, b) = (-0.25, 0.25);
    let exact = b - a;
    println!("U, a = {} g, b = {} g, exact chance by length {}", a, b, f6(exact));
    println!("    T   integral over t   kernel averaged over U");
    for t in [10.0, 40.0, 160.0] {
        let (r1, r2) = (levy(&phi_u, a, b, t, 1.0), fubini_u(a, b, t));
        println!("{:5}   {}          {}", t as i64, f6(r1), f6(r2));
        assert!((r1 - r2).abs() < 1e-8);
    }
    assert!((levy(&phi_u, a, b, 160.0, 1.0) - exact).abs() < 1e-3);
    println!("hand: Si(10) = {}  Si(30) = {}  G(10) = {}  G(30) = {}  2(G(30) - G(10))/(40 pi) = {}",
             f6(si(10.0)), f6(si(30.0)), f6(gg(10.0)), f6(gg(30.0)), f6(2.0 * (gg(30.0) - gg(10.0)) / (40.0 * PI)));
    for u in [10.0, 30.0] { assert!((gg(u) - simpson(&si, 0.0, u, (20.0 * u) as i64)).abs() < 1e-6); }
    println!("kernel at T = 40: x = 0: {}  x = 0.25: {}  x = 0.4: {}  ceiling 2 Si(pi)/pi = {}",
             f6(kernel(0.0, a, b, 40.0)), f6(kernel(0.25, a, b, 40.0)), f6(kernel(0.4, a, b, 40.0)), f6(2.0 * si(PI) / PI));
    let kmax = (-100..101).map(|k| kernel(k as f64 / 100.0, a, b, 40.0).abs()).fold(0.0, f64::max);
    assert!(kmax <= 2.0 * si(PI) / PI);

    let pf = [1.0 / 6.0; 6];
    for (a, b) in [(2.0, 5.0), (2.5, 4.5)] {
        let (mut inside, mut ends) = (0.0, 0.0);
        for k in 1..7 {
            let x = k as f64;
            if a < x && x < b { inside += pf[k - 1]; }
            if x == a || x == b { ends += pf[k - 1]; }
        }
        let vals: Vec<f64> = [10.0, 40.0, 160.0, 640.0].iter().map(|&t| levy(&phi_die, a, b, t, 1.0)).collect();
        println!("die, a = {}, b = {}: T = 10, 40, 160, 640: {}  counted: inside {}, half the ends {}", a, b,
                 vals.iter().map(|&v| f6(v)).collect::<Vec<_>>().join(" "), f6(inside), f6(ends / 2.0));
        for (i, t) in [10.0, 40.0, 160.0, 640.0].into_iter().enumerate() {
            assert!((vals[i] - fubini_die(a, b, t)).abs() < 1e-8);
        }
        assert!((vals[3] - (inside + ends / 2.0)).abs() < 1e-3);
    }
    println!("die, a = 2, b = 5: chance with both ends {}", f6(4.0 / 6.0));

    println!("density of U by the cut-off integral (true: 1 inside, 0 outside)");
    println!("  peak: at x = 0.5 - pi/T;  abs area: (1/2pi) int_{{-T}}^{{T}} |phi_U(t)| dt");
    println!("    T     x = 0  x = 0.25  edge 0.5      peak  abs area");
    for t in [10.0, 40.0, 160.0] {
        let mut row: Vec<f64> = [0.0, 0.25, 0.5, 0.5 - PI / t].iter().map(|&x| dens(&phi_u, x, t)).collect();
        row.push(simpson(&|s: f64| phi_u(s).re.abs(), 0.0, t, 20000) / PI);
        println!("{:5}  {}", t as i64, row.iter().map(|&v| f6(v)).collect::<Vec<_>>().join("  "));
    }
    assert!((dens(&phi_u, 0.5, 160.0) - kernel(0.5, -0.5, 0.5, 160.0)).abs() < 1e-8);
    println!("peak limit 1/2 + Si(pi)/pi = {}", f6(0.5 + si(PI) / PI));
    let xs: Vec<f64> = (0..21).map(|k| k as f64 / 10.0 - 1.0).collect();
    println!("chart, x       {}", xs.iter().map(|x| format!("{:5.1}", x)).collect::<Vec<_>>().join(" "));
    let gate = |x: f64| if x.abs() < 0.5 { 1.0 } else if x.abs() == 0.5 { 0.5 } else { 0.0 };
    println!("chart, gate    {}", xs.iter().map(|&x| format!("{:5.2}", gate(x))).collect::<Vec<_>>().join(" "));
    for t in [10.0, 40.0] {
        println!("chart, T = {:2} {}", t as i64, xs.iter().map(|&x| format!("{:5.2}", dens(&phi_u, x, t))).collect::<Vec<_>>().join(" "));
    }

    let sq = |t: f64| { let p = phi_u(t).re; C { re: p * p, im: 0.0 } };
    println!("U1 - U2, triangle on [-1, 1] g: true density 1 at 0, 0.5 at 0.5");
    for t in [50.0, 200.0] {
        let (d0, d5, tail) = (dens(&sq, 0.0, t), dens(&sq, 0.5, t), 4.0 / (PI * t));
        println!("  T = {:3}: x = 0: {}  x = 0.5: {}  tail bound 4/(pi T) = {}", t as i64, f6(d0), f6(d5), f6(tail));
        assert!((d0 - 1.0).abs() <= tail);
        assert!((d5 - 0.5).abs() <= tail);
    }

    println!("mistake, no 1/(2 pi), U, T = 160: {}", f6(2.0 * PI * levy(&phi_u, -0.25, 0.25, 160.0, 1.0)));
    let fl = levy(&phi_die, 2.5, 4.5, 160.0, -1.0);
    println!("mistake, spin-back sign flipped, die, a = 2.5, b = 4.5, T = 160: {}", f6(fl));
    assert!(fl.abs() < 1e-3);
    println!("ALL CHECKS PASS");
}
