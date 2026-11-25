// Strichartz estimates and nonlinear Schrodinger -- the same check in Rust.  std only, no crates.
// Free flow i u_t + u_xx = 0 from f(x) = exp(-x^2); quintic NLS i u_t + u_xx = -|u|^4 u (focusing).
use std::f64::consts::PI;

fn simpson<F: Fn(f64) -> f64>(f: F, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    s * h / 3.0
}

fn u_free(t: f64, x: f64) -> (f64, f64) {   // closed form (1+4it)^(-1/2) exp(-x^2/(1+4it))
    let a = 1.0 + 16.0 * t * t;
    let m = a.powf(-0.25) * (-x * x / a).exp();
    let ph = 4.0 * t * x * x / a - 0.5 * (4.0 * t).atan2(1.0);
    (m * ph.cos(), m * ph.sin())
}

fn absu(t: f64, x: f64) -> f64 { let (re, im) = u_free(t, x); (re * re + im * im).sqrt() }

fn peak_spectral(t: f64) -> f64 {          // road 2: the Fourier side, f-hat = sqrt(pi) exp(-pi^2 xi^2)
    let g = |c: fn(f64) -> f64| simpson(|s| PI.sqrt() * (-PI * PI * s * s).exp() * c(4.0 * PI * PI * t * s * s), -2.2, 2.2, 8000);
    (g(f64::cos).powf(2.0) + g(f64::sin).powf(2.0)).sqrt()
}

fn l6_x(t: f64, shift: f64) -> f64 {       // integral over x of |u|^6, one bump or two bumps 'shift' apart
    let w = 4.0 * (1.0 + 16.0 * t * t).sqrt();
    let g = |x: f64| {
        let (a, b) = (u_free(t, x), u_free(t, x - shift));
        let (re, im) = if shift != 0.0 { (a.0 + b.0, a.1 + b.1) } else { a };
        (re * re + im * im).powf(3.0)
    };
    simpson(g, -w, w + shift, 240)
}

const N: usize = 601;
fn rhs(re: &[f64], im: &[f64], dx: f64) -> (Vec<f64>, Vec<f64>) {   // u_t = i (u_xx + |u|^4 u)
    let (mut wr, mut wi) = (vec![0.0; N], vec![0.0; N]);
    for i in 1..N - 1 {
        let m4 = (re[i] * re[i] + im[i] * im[i]).powf(2.0);
        wr[i] = (re[i + 1] - 2.0 * re[i] + re[i - 1]) / dx.powf(2.0) + m4 * re[i];
        wi[i] = (im[i + 1] - 2.0 * im[i] + im[i - 1]) / dx.powf(2.0) + m4 * im[i];
    }
    (wi.iter().map(|v| -v).collect(), wr)
}

fn stats(re: &[f64], im: &[f64], xs: &[f64], dx: f64) -> (f64, f64, f64) {
    let m2: Vec<f64> = (0..N).map(|i| re[i].powf(2.0) + im[i].powf(2.0)).collect();
    let (mut g, mut s, mut s6, mut sv) = (0.0, 0.0, 0.0, 0.0);
    for i in 0..N - 1 { g += (re[i + 1] - re[i]).powf(2.0) + (im[i + 1] - im[i]).powf(2.0); }
    for i in 0..N { s += m2[i]; s6 += m2[i].powf(3.0); sv += xs[i].powf(2.0) * m2[i]; }
    (s * dx, g / dx / 2.0 - s6 * dx / 6.0, sv * dx)
}

fn main() {
    println!("free flow from exp(-x^2): peak |u(t,0)| against the dispersive bound (4|t|)^(-1/2)");
    println!("     t   peak closed  peak spectral      bound  peak/bound");
    for t in [0.25, 0.5, 1.0, 2.0, 4.0, 8.0] {
        let (pc, ps, b) = (absu(t, 0.0), peak_spectral(t), (4.0 * t).powf(-0.5));
        assert!((pc - ps).abs() < 1e-9, "closed form vs spectral integral");
        assert!(pc <= b, "dispersive bound");
        println!("{:6.2} {:13.6} {:14.6} {:10.6} {:11.6}", t, pc, ps, b, pc / b);
    }
    let (t0, x0, h) = (0.7, 0.4, 1e-4);
    let c = |t: f64, x: f64, k: usize| if k == 0 { u_free(t, x).0 } else { u_free(t, x).1 };
    let ut: Vec<f64> = (0..2).map(|k| (c(t0 + h, x0, k) - c(t0 - h, x0, k)) / (2.0 * h)).collect();
    let uxx: Vec<f64> = (0..2).map(|k| (c(t0, x0 + h, k) - 2.0 * c(t0, x0, k) + c(t0, x0 - h, k)) / (h * h)).collect();
    let resid = ((uxx[0] - ut[1]).powf(2.0) + (uxx[1] + ut[0]).powf(2.0)).sqrt();
    assert!(resid < 1e-5, "closed form must solve i u_t + u_xx = 0");
    println!("residual of i u_t + u_xx at t = 0.7, x = 0.4: {:.10}", resid);
    let masses: Vec<f64> = [0.0_f64, 1.0, 8.0].iter().map(|&t| {
        let w = 8.0 * (1.0 + 16.0 * t * t).sqrt();
        simpson(|x| absu(t, x).powf(2.0), -w, w, 2000) }).collect();
    assert!(masses.iter().all(|m| (m - (PI / 2.0).sqrt()).abs() < 1e-9), "mass is conserved");
    let ms: Vec<String> = masses.iter().map(|m| format!("{:.6}", m)).collect();
    println!("mass at t = 0, 1, 8: {}   sqrt(pi/2) = {:.6}", ms.join(" "), (PI / 2.0).sqrt());

    let big_t = 50.0;
    let i6_num = 2.0 * simpson(|t| l6_x(t, 0.0), 0.0, big_t, 4000);
    let tail_exact = (PI / 6.0).sqrt() * (PI / 2.0 - (4.0 * big_t).atan()) / 2.0;
    let tail_bound = (PI / 6.0).sqrt() / (8.0 * big_t);
    let i6 = PI.powf(1.5) / (4.0 * 6f64.sqrt());
    assert!(tail_exact <= tail_bound && (i6_num + tail_exact - i6).abs() < 1e-8, "space-time integral, two roads");
    let (l6, f2) = (i6.powf(1.0 / 6.0), (PI / 2.0).powf(0.25));
    let sharp = 12f64.powf(-1.0 / 12.0);
    let gamma13 = 3.0 * simpson(|y: f64| (-y.powf(3.0)).exp(), 0.0, 8.0, 4000);
    let c_hls = PI.powf(-1.0 / 6.0) * 3f64.sqrt() * gamma13.powf(3.0) / (2f64.powf(4.0 / 3.0) * PI.powf(1.5));
    let gamma56 = 6.0 * simpson(|z: f64| z.powi(4) * (-z.powi(6)).exp(), 0.0, 4.0, 4000);   // Gamma(5/6) = 6 int z^4 e^(-z^6)
    assert!((c_hls - PI.powf(-1.0 / 6.0) * gamma13 / gamma56).abs() < 1e-9, "Lieb's constant: duplication form against Gamma(5/6)");
    let k = (4.0 * PI).powf(-1.0 / 3.0) * c_hls;
    let s_proof = k.sqrt();
    assert!((l6 / f2 - sharp).abs() < 1e-9, "the Gaussian meets the sharp constant 12^(-1/12)");
    assert!(sharp < s_proof, "the proof's constant is larger than the sharp one");
    let mut rows: Vec<(String, f64)> = vec![
        ("int |u|^6 numeric, |t| <= 50".into(), i6_num), ("  tail beyond 50, exact".into(), tail_exact),
        ("  tail bound sqrt(pi/6)/(8T)".into(), tail_bound), ("  numeric + tail".into(), i6_num + tail_exact),
        ("  closed form pi^1.5/(4 sqrt 6)".into(), i6), ("||u||_L6 space-time".into(), l6), ("||f||_2".into(), f2),
        ("ratio ||u||_L6 / ||f||_2".into(), l6 / f2), ("sharp constant 12^(-1/12)".into(), sharp),
        ("Gamma(1/3)".into(), gamma13), ("HLS constant, kernel |t|^(-1/3)".into(), c_hls),
        ("K = (4 pi)^(-1/3) C_HLS".into(), k), ("proof's Strichartz constant sqrt K".into(), s_proof)];
    let i6_two = 2.0 * simpson(|t| l6_x(t, 3.0), 0.0, big_t, 4000) + 2f64.powf(6.0) * tail_exact;
    let f2_two = (2.0 * (PI / 2.0).sqrt() * (1.0 + (-4.5f64).exp())).sqrt();
    assert!(i6_two.powf(1.0 / 6.0) / f2_two < sharp, "two bumps fall below the Gaussian's ratio");
    rows.push(("two bumps 3 apart: ratio (tail bounded)".into(), i6_two.powf(1.0 / 6.0) / f2_two));
    let l4 = |t: f64| PI.sqrt() / 4.0 * (4.0 * t).asinh();
    let l4_num = 2.0 * simpson(|t| { let w = 5.0 * (1.0 + 16.0 * t * t).sqrt(); simpson(|x| absu(t, x).powf(4.0), -w, w, 400) }, 0.0, 10.0, 2000);
    assert!((l4_num - l4(10.0)).abs() < 1e-7, "L4 space-time, two roads");
    rows.push(("wrong pair (4,4): int |u|^4, |t| < 10 numeric".into(), l4_num));
    for t in [10u64, 100, 1000, 1000000] { rows.push((format!("  formula, |t| < {}", t), l4(t as f64))); }
    let p4 = |t: f64| absu(t, 0.0).powf(4.0);
    let l4inf = 2.0 * (simpson(p4, 0.0, 10.0, 4000) + simpson(p4, 10.0, 1e4, 20000));
    assert!((l4inf - PI / 4.0).abs() < 2.0 / (16.0 * 1e4), "endpoint pair (4, inf): int peak^4 dt = pi/4, tail under 1/(8T)");
    rows.push(("pair (4,inf): int peak^4 dt, |t| < 10^4".into(), l4inf));
    rows.push(("  pi/4".into(), PI / 4.0));
    let eta = (160.0 * k).powf(-0.25);
    let a = 2.0_f64;
    let t_loc = (4.0 * eta.powf(6.0) / (a.powf(6.0) * (PI / 6.0).sqrt())).tan() / 4.0;
    assert!((10.0 * k * (2.0 * eta).powf(4.0) - 1.0).abs() < 1e-12 && eta + k * (2.0 * eta).powf(5.0) <= 2.0 * eta, "eta*: Lipschitz factor 10K R^4 = 1 at R = 2 eta, ball kept");
    assert!((a.powf(6.0) * simpson(|t| l6_x(t, 0.0), 0.0, t_loc, 40) - eta.powf(6.0)).abs() < 1e-9 * eta.powf(6.0), "T_loc: the bell's L6 size on [0, T_loc], integrated, is eta*");
    rows.push(("contraction threshold eta*".into(), eta));
    rows.push(("small-data amplitude eta*/||u||_L6".into(), eta / l6));
    rows.push(("A = 2: guaranteed time T_loc".into(), t_loc));
    let (grad2, int6, int4) = (a * a * (PI / 2.0).sqrt(), a.powf(6.0) * (PI / 6.0).sqrt(), a.powf(4.0) * (PI / 4.0).sqrt());
    let (e, v0) = (grad2 / 2.0 - int6 / 6.0, a * a * (PI / 2.0).sqrt() / 4.0);
    let t_star = (v0 / (-8.0 * e)).sqrt();
    for (n, v) in [("A = 2: int |u_x|^2", grad2), ("A = 2: int |u|^6", int6), ("quintic energy E", e), ("variance V(0)", v0),
                   ("blow-up before T* = sqrt(V0/(8|E|))", t_star), ("E < 0 once A > 27^(1/8)", 27f64.powf(0.125)),
                   ("cubic: energy E3", grad2 / 2.0 - int4 / 4.0), ("cubic: V''(0) = 8 int|u_x|^2 - 2 int|u|^4", 8.0 * grad2 - 2.0 * int4)] {
        rows.push((n.into(), v));
    }
    for (name, v) in &rows { println!("{:<46} {:14.6}", name, v); }

    // road 3 for the virial law: solve the focusing quintic by finite differences and RK4
    let l = 6.0;
    let dx = 2.0 * l / (N - 1) as f64;
    let xs: Vec<f64> = (0..N).map(|i| -l + i as f64 * dx).collect();
    let mut re: Vec<f64> = xs.iter().map(|x| a * (-x * x).exp()).collect();
    let mut im = vec![0.0; N];
    let (dt, steps) = (1e-4, 100);
    println!("focusing quintic, A = 2, grid dx = 0.02, RK4 dt = 0.0001");
    println!("     t        mass      energy  V numeric  V0 + 8 E t^2");
    for kk in 0..5 {
        let (m, en, v) = stats(&re, &im, &xs, dx);
        let tk = kk as f64 * dt * steps as f64;
        println!("{:6.2} {:11.6} {:11.6} {:10.6} {:13.6}", tk, m, en, v, v0 + 8.0 * e * tk * tk);
        assert!((v - (v0 + 8.0 * e * tk * tk)).abs() < 1e-4 && (m - 4.0 * (PI / 2.0).sqrt()).abs() < 1e-6, "virial law and mass");
        for _ in 0..steps {
            let step = |r: &[f64], i: &[f64], kr: &[f64], ki: &[f64], c: f64| -> (Vec<f64>, Vec<f64>) {
                ((0..N).map(|j| r[j] + c * kr[j]).collect(), (0..N).map(|j| i[j] + c * ki[j]).collect()) };
            let k1 = rhs(&re, &im, dx);
            let (r2, i2) = step(&re, &im, &k1.0, &k1.1, dt / 2.0);
            let k2 = rhs(&r2, &i2, dx);
            let (r3, i3) = step(&re, &im, &k2.0, &k2.1, dt / 2.0);
            let k3 = rhs(&r3, &i3, dx);
            let (r4, i4) = step(&re, &im, &k3.0, &k3.1, dt);
            let k4 = rhs(&r4, &i4, dx);
            re = (0..N).map(|j| re[j] + dt / 6.0 * (k1.0[j] + 2.0 * k2.0[j] + 2.0 * k3.0[j] + k4.0[j])).collect();
            im = (0..N).map(|j| im[j] + dt / 6.0 * (k1.1[j] + 2.0 * k2.1[j] + 2.0 * k3.1[j] + k4.1[j])).collect();
        }
    }
    let ts: Vec<f64> = (1..17).map(|k| 0.25 * k as f64).collect();
    println!("chart t      {}", ts.iter().map(|t| format!("{}", t)).collect::<Vec<_>>().join(" "));
    println!("chart peak   {}", ts.iter().map(|t| format!("{:.3}", absu(*t, 0.0))).collect::<Vec<_>>().join(" "));
    println!("chart bound  {}", ts.iter().map(|t| format!("{:.3}", (4.0 * t).powf(-0.5))).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
