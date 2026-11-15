// Canonical form -- the check behind the card.  std only.
// Road 1: exact integer algebra.  The chain rule gives the new coefficients
//   A' = A a1^2 + B a1 b1 + C b1^2,  B' = 2A a1 a2 + B(a1 b2 + b1 a2) + 2C b1 b2,
//   C' = A a2^2 + B a2 b2 + C b2^2   for xi = a1 p + b1 q, eta = a2 p + b2 q.
// Road 2: bisection finds the characteristic speeds without the quadratic formula.
// Road 3: centred differences test the solutions in the ORIGINAL coordinates.
// Road 4: the strip's tone three ways: closed form, round trip, far-end scan.
use std::f64::consts::PI;

fn transform(a: i64, b: i64, c: i64, d: i64, e: i64, a1: i64, b1: i64, a2: i64, b2: i64) -> [i64; 6] {
    [a*a1*a1 + b*a1*b1 + c*b1*b1, 2*a*a1*a2 + b*(a1*b2 + b1*a2) + 2*c*b1*b2,
     a*a2*a2 + b*a2*b2 + c*b2*b2, d*a1 + e*b1, d*a2 + e*b2, a1*b2 - b1*a2]
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) < 0.0) == (f(mid) < 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

// relative size of A u_pp + B u_pq + C u_qq + D u_p + E u_q
fn residual(co: [f64; 5], u: &dyn Fn(f64, f64) -> f64, p: f64, q: f64, hp: f64, hq: f64) -> f64 {
    let upp = (u(p + hp, q) - 2.0*u(p, q) + u(p - hp, q)) / hp.powi(2);
    let uqq = (u(p, q + hq) - 2.0*u(p, q) + u(p, q - hq)) / hq.powi(2);
    let upq = (u(p+hp, q+hq) - u(p+hp, q-hq) - u(p-hp, q+hq) + u(p-hp, q-hq)) / (4.0*hp*hq);
    let up = (u(p + hp, q) - u(p - hp, q)) / (2.0*hp);
    let uq = (u(p, q + hq) - u(p, q - hq)) / (2.0*hq);
    let t = [co[0]*upp, co[1]*upq, co[2]*uqq, co[3]*up, co[4]*uq];
    t.iter().sum::<f64>().abs() / t.iter().map(|x| x.abs()).sum::<f64>()
}

fn sci(v: f64) -> String {
    let mut e = v.log10().floor() as i32;
    let mut m = v / 10f64.powf(e as f64);
    if (m * 100.0).round() / 100.0 >= 10.0 { m /= 10.0; e += 1; }
    format!("{:.2}e{:+03}", m, e)
}

// residual at three steps and the observed order
fn ladder(co: [f64; 5], u: &dyn Fn(f64, f64) -> f64, p: f64, q: f64, h: f64, k: f64) -> (Vec<f64>, f64) {
    let r: Vec<f64> = (0..3).map(|i| residual(co, u, p, q, h / 2f64.powi(i), k / 2f64.powi(i))).collect();
    let o = (r[1] / r[2]).log2();
    (r, o)
}

fn join(r: &[f64]) -> String { r.iter().map(|&v| sci(v)).collect::<Vec<_>>().join(", ") }

fn main() {
    // ---- the moving steel strip: wave speed c on the strip, line speed V, span L ----
    let (c, v, l): (i64, i64, i64) = (80, 20, 2); // m/s, m/s, m (illustrative)
    let (a, b, cc) = (1i64, 2*v, -(c*c - v*v)); // u_tt + 2V u_xt - (c^2 - V^2) u_xx = 0, variables (t, x)
    let disc = b*b - 4*a*cc;
    println!("strip: c = {} m/s, V = {} m/s, L = {} m", c, v, l);
    println!("strip: A, B, C = {}, {} m/s, {} m^2/s^2; B^2 - 4AC = {} m^2/s^2", a, b, cc, disc);
    let quad = |lam: f64| a as f64*lam*lam - b as f64*lam + cc as f64; // A' for xi = x - lam t
    let r = (disc as f64).sqrt().round() as i64; assert!(r * r == disc);
    let (lp, lm) = ((b + r).div_euclid(2*a), (b - r).div_euclid(2*a));
    let vert = b as f64 / (2.0*a as f64);
    let (bp, bm) = (bisect(&quad, vert, 1e4), bisect(&quad, -1e4, vert));
    println!("speeds: formula {} and {} m/s; bisection {:.9} and {:.9} m/s", lp, lm, bp, bm);
    assert!((bp - (v + c) as f64).abs() < 1e-9 && (bm - (v - c) as f64).abs() < 1e-9);
    let t1 = transform(a, b, cc, 0, 0, -lp, 1, -lm, 1);
    let (ap, bpp, cp, j) = (t1[0], t1[1], t1[2], t1[5]);
    println!("xi = x - {} t, eta = x + {} t: A', B', C' = {}, {}, {}; J = {} m/s", lp, -lm, ap, bpp, cp, j);
    println!("invariant: B'^2 - 4A'C' = {} = J^2 (B^2 - 4AC) = {} x {}", bpp*bpp - 4*ap*cp, j*j, disc);
    assert!(ap == 0 && cp == 0 && bpp*bpp - 4*ap*cp == j*j*disc);
    let s = transform(a, b, cc, 0, 0, -v, 1, c, 0); // s = (xi + eta)/2 = x - V t, r = (eta - xi)/2 = c t
    println!("s = x - {} t, r = {} t: A', B', C' = {}, {}, {}  (v_rr = v_ss)", v, c, s[0], s[1], s[2]);
    assert!(s[1] == 0 && s[0] == -s[2]);
    let f = |z: f64| (-(z / 0.1).powi(2)).exp();
    let g = |z: f64| 0.5 * (-((z - 0.7) / 0.2).powi(2)).exp();
    let (lpf, lmf, cf) = (lp as f64, lm as f64, c as f64);
    let good = |t: f64, x: f64| f(x - lpf*t) + g(x - lmf*t);
    let bad = |t: f64, x: f64| f(x - cf*t) + g(x + cf*t); // still-strip speeds, flow ignored
    let co = [a as f64, b as f64, cc as f64, 0.0, 0.0];
    let (rg, og) = ladder(co, &good, 0.004, 0.5, 0.0002, 0.02);
    let (rb, ob) = ladder(co, &bad, 0.004, 0.5, 0.0002, 0.02);
    println!("residual at x = 0.5 m, t = 0.004 s; space steps 0.02, 0.01, 0.005 m, time step = space step / ({} m/s):", lp);
    println!("  F(x - {}t) + G(x + {}t): {}; order {:.2}", lp, -lm, join(&rg), og);
    println!("  F(x - {}t) + G(x + {}t):  {}; order {:.2}", c, c, join(&rb), ob);
    assert!(1.9 < og && og < 2.1 && rg[2] < 0.01 * rb[2] && rb.iter().cloned().fold(f64::MAX, f64::min) > 0.1);

    // ---- parabolic and elliptic reductions, variables (x, y) ----
    let h = transform(1, 2, 1, 0, -1, -1, 1, 1, 0); // u_xx + 2u_xy + u_yy - u_y; xi = y - x, eta = x
    println!("heat type: A, B, C, D, E = 1, 2, 1, 0, -1; B^2 - 4AC = {}; xi = y - x, eta = x: A', B', C' = {}, {}, {}; D', E' = {}, {}; J = {}",
             2*2 - 4*1*1, h[0], h[1], h[2], h[3], h[4], h[5]);
    assert!(h[..5] == [0, 0, 1, -1, 0]);
    let (rh, oh) = ladder([1.0, 2.0, 1.0, 0.0, -1.0], &|x: f64, y: f64| (-(y - x)).exp() * x.sin(), 0.5, 1.0, 0.1, 0.1);
    println!("  e^-(y-x) sin x: residual {}; order {:.2}", join(&rh), oh);
    let (la, lb, lc) = (1i64, 2i64, 5i64); // u_xx + 2u_xy + 5u_yy = 0
    let (al, d4) = (lb.div_euclid(2*la), 4*la*lc - lb*lb); // roots alpha +- i beta of LA l^2 - LB l + LC
    let be = ((d4 as f64).sqrt().round() as i64).div_euclid(2*la);
    assert!((2*la*be)*(2*la*be) == d4 && 2*la*al == lb);
    let lt = transform(la, lb, lc, 0, 0, -al, 1, be, 0); // xi = y - alpha x, eta = beta x
    println!("Laplace type: A, B, C = {}, {}, {}; B^2 - 4AC = {}; alpha, beta = {}, {}; xi = y - alpha x, eta = beta x: A', B', C' = {}, {}, {}",
             la, lb, lc, -d4, al, be, lt[0], lt[1], lt[2]);
    assert!(lt[..3] == [d4.div_euclid(4*la), 0, d4.div_euclid(4*la)]); // (4AC - B^2)/(4A) each
    let (alf, bef) = (al as f64, be as f64);
    let (rl, ol) = ladder([la as f64, lb as f64, lc as f64, 0.0, 0.0], &|x: f64, y: f64| (y - alf*x).exp() * (bef*x).cos(), 0.5, 1.0, 0.1, 0.1);
    println!("  e^(y - alpha x) cos(beta x): residual {}; order {:.2}", join(&rl), ol);
    assert!(1.9 < oh && oh < 2.1 && 1.9 < ol && ol < 2.1);

    // ---- the tone of the strip between two fixed rollers ----
    let (vf, lf) = (v as f64, l as f64);
    let (f_still, f_form) = (cf / (2.0*lf), (cf*cf - vf*vf) / (2.0*lf*cf));
    let trip = lf / (vf + cf) + lf / (cf - vf);
    println!("tone: still strip c/2L = {:.2} Hz; moving, (c^2 - V^2)/(2Lc) = {:.2} Hz", f_still, f_form);
    println!("tone: round trip {:.4} s + {:.4} s = {:.4} s, so {:.2} Hz", lf/(vf+cf), lf/(cf-vf), trip, 1.0/trip);
    // largest |u(L, t)| over one period for the mode sin(wt - k1 x) - sin(wt - k2 x)
    let far_end = |fr: f64| {
        let w = 2.0*PI*fr; let (k1, k2) = (w / (vf + cf), w / (vf - cf));
        (0..200).map(|i| i as f64 / (200.0*fr)).map(|t| ((w*t - k1*lf).sin() - (w*t - k2*lf).sin()).abs())
            .fold(0.0f64, f64::max)
    };
    let scan: Vec<f64> = (1..5001).map(|i| far_end(i as f64 / 100.0)).collect(); // 0.01 to 50 Hz
    let rise = (0..5000).find(|&i| scan[i] > 1.0).unwrap(); // skip the zero at 0 Hz
    let first = (rise..5000).find(|&i| scan[i] < 0.05).unwrap();
    let best = (first..first + 30).min_by(|&i, &k| scan[i].partial_cmp(&scan[k]).unwrap()).unwrap() + 1;
    println!("tone: far-end scan 0.01 to 50 Hz finds {:.2} Hz; far end at {:.2} Hz {:.6}, at {:.2} Hz {:.6}",
             best as f64 / 100.0, f_form, far_end(f_form), f_still, far_end(f_still));
    assert!((best as f64 / 100.0 - f_form).abs() < 0.006 && (1.0 / trip - f_form).abs() < 1e-9);
    let tones: Vec<String> = [0.0, 40.0, 80.0].iter().map(|&s: &f64| format!("{:.2}", (cf*cf - s*s) / (2.0*lf*cf))).collect();
    println!("tone at line speed 0, 40, 80 m/s: {} Hz", tones.join(", "));

    // ---- what breaks ----
    let w = transform(a, b, cc, 0, 0, -c, 1, c, 1);
    println!("breaks: still-strip speeds {} and {} m/s: A', C' = {}, {} (not 0)", c, -c, w[0], w[2]);
    let x = transform(a, b, cc, 0, 0, lp, 1, lm, 1);
    println!("breaks: signs slipped, speeds {} and {} m/s: A', C' = {}, {}", -lp, -lm, x[0], x[2]);
    let y = transform(la, lb, lc, 0, 0, -al, 1, 1, 0);
    println!("breaks: Laplace type with eta = x (beta dropped): A', B', C' = {}, {}, {}", y[0], y[1], y[2]);
    let z = transform(1, 2, 1, 0, -1, -1, 1, -2, 2);
    println!("breaks: heat type with eta = 2(y - x): J = {}", z[5]);
    let tri = |y: i64| 0*0 - 4*y*1; // Tricomi y u_xx + u_yy: A = y, B = 0, C = 1
    println!("breaks: Tricomi y u_xx + u_yy: B^2 - 4AC = {} at y = 1, {} at y = -1", tri(1), tri(-1));
    let want = [quad(cf), quad(-cf), quad(-lpf), quad(-lmf)]; // A' = Q(-lam, 1) by the bisection's own quadratic
    assert!([w[0], w[2], x[0], x[2]].iter().zip(want.iter()).all(|(&p, &q)| p as f64 == q) && w[0] != 0 && x[0] != 0);
    assert!(y[0] == la*al*al - lb*al + lc && y[1] == 0 && y[2] == la && y[0] != y[2] && z[5] == 0);
    println!("figure, round trip (m, s): (0, 0) -> ({}, {:.7}) -> (0, {:.7})", l, lf/(vf+cf), trip);
    println!("ALL CHECKS PASS");
}
