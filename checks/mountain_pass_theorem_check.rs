// Mountain pass check: -u'' = u^3 on (0, pi), u(0) = u(pi) = 0, energy J(u) = 1/2 int u'^2 - 1/4 int u^4.
// std only.  Three roads to the pass level c: shooting by RK4, the AGM closed form, a grid minimax.
use std::f64::consts::PI;

fn simpson(f: &[f64], h: f64) -> f64 {
    let n = f.len() - 1; let mut s = f[0] + f[n];
    for i in (1..n).step_by(2) { s += 4.0 * f[i]; }
    for i in (2..n).step_by(2) { s += 2.0 * f[i]; }
    s * h / 3.0
}

fn shoot(s: f64, n: usize) -> (Vec<f64>, Vec<f64>) {
    let h = PI / n as f64;
    let (mut u, mut p) = (0.0f64, s);
    let (mut us, mut ps) = (vec![u], vec![p]);
    for _ in 0..n {
        let (k1u, k1p) = (p, -u * u * u);
        let a = u + 0.5 * h * k1u; let (k2u, k2p) = (p + 0.5 * h * k1p, -a * a * a);
        let a = u + 0.5 * h * k2u; let (k3u, k3p) = (p + 0.5 * h * k2p, -a * a * a);
        let a = u + h * k3u; let (k4u, k4p) = (p + h * k3p, -a * a * a);
        u += h * (k1u + 2.0 * k2u + 2.0 * k3u + k4u) / 6.0;
        p += h * (k1p + 2.0 * k2p + 2.0 * k3p + k4p) / 6.0;
        us.push(u); ps.push(p);
    }
    (us, ps)
}

fn tri_solve(r: &[f64], h: f64) -> Vec<f64> {
    let n = r.len(); let (mut c, mut d) = (vec![0.0; n], vec![0.0; n]);
    c[0] = -0.5; d[0] = r[0] * h * h / 2.0;
    for i in 1..n { let m = 2.0 + c[i - 1]; c[i] = -1.0 / m; d[i] = (r[i] * h * h + d[i - 1]) / m; }
    let mut w = vec![0.0; n]; w[n - 1] = d[n - 1];
    for i in (0..n - 1).rev() { w[i] = d[i] - c[i] * w[i + 1]; }
    w
}

fn ground(n: usize, iters: usize) -> (f64, f64, Vec<f64>, f64) {
    let h = PI / (n + 1) as f64;
    let mut v: Vec<f64> = (0..n).map(|i| ((i + 1) as f64 * h).sin()).collect();
    let mut m = 1.0;
    for _ in 0..iters {
        let cube: Vec<f64> = v.iter().map(|x| x * x * x).collect();
        let w = tri_solve(&cube, h);
        m = w.iter().cloned().fold(f64::MIN, f64::max);
        v = w.iter().map(|x| x / m).collect();
    }
    let mut va = vec![0.0]; va.extend(v.iter()); va.push(0.0);
    let (mut a, mut b) = (0.0, 0.0);
    for i in 0..=n { a += (va[i + 1] - va[i]).powi(2) / h; }
    for x in &v { b += h * x.powi(4); }
    (a * a / (4.0 * b), 1.0 / m.sqrt(), v, h)
}

fn sci(x: f64, p: usize) -> String { // Python-style e-notation: two-digit exponent with sign
    let s = format!("{:.*e}", p, x);
    let (m, e) = s.split_at(s.find('e').unwrap());
    let ev: i32 = e[1..].parse().unwrap();
    format!("{}e{}{:02}", m, if ev < 0 { "-" } else { "+" }, ev.abs())
}

fn maxv(v: &[f64]) -> f64 { v.iter().cloned().fold(f64::MIN, f64::max) }

fn main() {
    let ray = |t: f64| PI * t * t / 4.0 - 3.0 * PI * t.powi(4) / 32.0;
    let ts = 2.0 / 3f64.sqrt();
    let n = 2000usize; let hx = PI / n as f64;
    let xs: Vec<f64> = (0..=n).map(|i| i as f64 * hx).collect();
    let jq = simpson(&xs.iter().map(|x| 0.5 * (ts * x.cos()).powi(2) - 0.25 * (ts * x.sin()).powi(4)).collect::<Vec<_>>(), hx);
    println!("ray t sin x: peak at t = {:.6}, J = {:.6} (pi/6 = {:.6}), by Simpson {:.6}", ts, ray(ts), PI / 6.0, jq);
    println!("ray t sin x: J back to 0 at t = {:.6}; J(2 sin x) = {:.6}; J(3 sin x) = {:.6}", (8.0f64 / 3.0).sqrt(), ray(2.0), ray(3.0));
    assert!((jq - PI / 6.0).abs() < 1e-9 && (ray(ts) - jq).abs() < 1e-9); assert!(ray(2.0) < 0.0);

    let rho = 2.0 / PI.sqrt(); let alpha = 1.0 / PI;
    println!("ring: radius |u'| = {:.6}, guaranteed height 1/pi = {:.6}", rho, alpha);

    let (mut lo, mut hi) = (0.5f64, 1.5f64);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if *shoot(mid, n).0.last().unwrap() > 0.0 { lo = mid } else { hi = mid } }
    let s = 0.5 * (lo + hi); let (us, ps) = shoot(s, n);
    let amp = maxv(&us);
    let a1 = simpson(&ps.iter().map(|p| p * p).collect::<Vec<_>>(), hx);
    let b1 = simpson(&us.iter().map(|u| u.powi(4)).collect::<Vec<_>>(), hx);
    let j1 = 0.5 * a1 - 0.25 * b1;
    println!("road 1 shooting: slope u'(0) = {:.9}, height u(pi/2) = {:.9}, J = {:.9}", s, amp, j1);
    println!("  int u'^2 = {:.9}, int u^4 = {:.9} (equal for a solution)", a1, b1);

    let (mut a, mut g) = (1.0f64, 2f64.sqrt());
    for _ in 0..8 { let an = 0.5 * (a + g); g = (a * g).sqrt(); a = an; }
    let mm = a; let c2 = PI / (3.0 * mm.powi(4));
    println!("road 2 AGM: M = {:.9}, slope sqrt2/M^2 = {:.9}, height sqrt2/M = {:.9}, c = pi/(3M^4) = {:.9}", mm, 2f64.sqrt() / mm.powi(2), 2f64.sqrt() / mm, c2);
    assert!((j1 - c2).abs() < 1e-9 && (amp - 2f64.sqrt() / mm).abs() < 1e-7 && (s - 2f64.sqrt() / mm.powi(2)).abs() < 1e-9);
    assert!((a1 - b1).abs() < 1e-8 && alpha < c2 && c2 < PI / 6.0);
    println!("by hand: pi/4 = {:.6}, 3pi/32 = {:.6}, |2 cos x| = {:.6}, agm step 1: {:.6}, {:.6}, 3g^4 = {:.6}", PI / 4.0, 3.0 * PI / 32.0, 2.0 * (PI / 2.0).sqrt(), (1.0 + 2f64.sqrt()) / 2.0, 2f64.sqrt().sqrt(), 3.0 * mm.powi(4));
    println!("by hand: c is {:.2}% below pi/6 and {:.1}% above 1/pi; f(4, 1) = {:.0}; 2* = 2d/(d-2) = {:.0} at d = 3, {:.0} at d = 4", 100.0 * (1.0 - c2 / (PI / 6.0)), 100.0 * (c2 / alpha - 1.0), 16.0 + (1.0f64 - 4.0).powi(3), 2.0 * 3.0 / (3.0 - 2.0), 2.0 * 4.0 / (4.0 - 2.0));

    let mut errs = vec![];
    for nn in [50usize, 100, 200] {
        let (ch, ah, _, h) = ground(nn, 120); errs.push(ch - c2);
        println!("road 3 grid: h = {:.6}, c_h = {:.9}, height {:.6}, error {}", h, ch, ah, sci(ch - c2, 3));
    }
    let order = (errs[0] / errs[1]).ln() / 2f64.ln(); let order2 = (errs[1] / errs[2]).ln() / 2f64.ln();
    println!("  observed order {:.3}, then {:.3}", order, order2);
    assert!(errs[2].abs() < 3e-5 && 1.9 < order2 && order2 < 2.1);

    for (name, aa, bb) in [("sin x", PI / 2.0, 3.0 * PI / 8.0), ("sin 2x", 2.0 * PI, 3.0 * PI / 8.0), ("u*", a1, b1)] {
        let j = rho.powi(2) / 2.0 - rho.powi(4) * bb / (4.0 * aa * aa);
        println!("on the ring: {:6} J = {:.6}", name, j); assert!(j >= alpha);
    }
    println!("lower bound r^2/2 - (pi/16) r^4 at r = rho: {:.6}", rho.powi(2) / 2.0 - PI / 16.0 * rho.powi(4));

    for t in [0.9f64, 1.1] { println!("J({} u*) = {:.6}  (below c)", t, a1 * (t * t / 2.0 - t.powi(4) / 4.0)); }
    for e in [0.1f64, -0.1] {
        let f: Vec<f64> = (0..=n).map(|i| 0.5 * (ps[i] + 3.0 * e * (3.0 * xs[i]).cos()).powi(2) - 0.25 * (us[i] + e * (3.0 * xs[i]).sin()).powi(4)).collect();
        let jj = simpson(&f, hx);
        println!("J(u* {:+.1} sin 3x) = {:.6}  (above c)", e, jj); assert!(jj > j1);
    }
    assert!(a1 * (0.81 / 2.0 - 0.6561 / 4.0) < j1 && a1 * (1.21 / 2.0 - 1.4641 / 4.0) < j1);

    let rs: Vec<f64> = (0..11).map(|k| 0.2 * k as f64).collect();
    let row = |f: &dyn Fn(f64) -> f64| rs.iter().map(|&r| format!("{:.3}", f(r))).collect::<Vec<_>>().join(", ");
    println!("chart sin x: {}", row(&|r| r * r / 2.0 - r.powi(4) * 3.0 / (8.0 * PI)));
    println!("chart u*   : {}", row(&|r| r * r / 2.0 - r.powi(4) / (4.0 * a1)));
    println!("chart bound: {}", row(&|r| r * r / 2.0 - PI / 16.0 * r.powi(4)));

    println!("drop the growth, -u'' = u/2: J(2 sin x) = {:.6} > 0, no far valley", PI * 4.0 / 8.0);
    let jl = PI * 0.01 / 4.0 - PI * 0.01 / 2.0 - 3.0 * PI * 1e-4 / 32.0;
    println!("drop the ring, -u'' = 2u + u^3: J(0.1 sin x) = {} < 0 next to u = 0", sci(jl, 6)); assert!(jl < 0.0);
    let (mut gr, mut f, mut y) = (0.0, 0.0, 0.0);
    for sm in [0.1f64, 0.01, 0.001] {
        let x = 1.0 + sm; y = (2.0 * x / (3.0 * sm * sm)).sqrt(); f = x * x + (1.0 - x).powi(3) * y * y;
        gr = (2.0 * x - 3.0 * (1.0 - x).powi(2) * y * y).hypot(2.0 * (1.0 - x).powi(3) * y);
        println!("drop Palais-Smale: s = {}, point ({:.3}, {:.3}), f = {:.6}, |grad f| = {}", sm, x, y, f, sci(gr, 3));
    }
    assert!(gr < 1e-4 && (f - 1.0).abs() < 1e-2 && y > 800.0);

    // how it moves: u_t = u_xx + u^3 from fac times the grid solution (N = 50, dt = 0.001)
    let (_, ah, v, h) = ground(50, 120); let dt = 0.001;
    let flow = |fac: f64, steps: usize| -> (Vec<String>, f64, f64) {
        let mut u: Vec<f64> = v.iter().map(|x| fac * ah * x).collect();
        let mut line = vec![]; let mut k = 0;
        while k < steps && maxv(&u) <= 10.0 {
            if k % 250 == 0 { line.push(format!("{:.4}", maxv(&u))); }
            let mut ua = vec![0.0]; ua.extend(u.iter()); ua.push(0.0);
            u = (0..u.len()).map(|i| u[i] + dt * ((ua[i] - 2.0 * ua[i + 1] + ua[i + 2]) / (h * h) + u[i].powi(3))).collect();
            k += 1;
        }
        (line, k as f64 * dt, maxv(&u))
    };
    for fac in [0.9f64, 1.1] {
        let (line, te, pk) = flow(fac, 2000);
        println!("heat flow from {} u*, peak every 0.25: {}; ends t = {:.3}, peak {:.4}", fac, line.join(", "), te, pk);
        assert!(if fac < 1.0 { pk < 0.3 } else { te < 2.0 });
    }

    // try changing
    for fac in [0.99f64, 1.01] { let (_, te, pk) = flow(fac, 4000); println!("try: heat flow from {} u* ends t = {:.3}, peak {:.4}", fac, te, pk); }
    let w: Vec<f64> = xs.iter().map(|x| x.sin() - 0.05 * (3.0 * x).sin()).collect();
    let wp: Vec<f64> = xs.iter().map(|x| x.cos() - 0.15 * (3.0 * x).cos()).collect();
    let a3 = simpson(&wp.iter().map(|q| q * q).collect::<Vec<_>>(), hx);
    let b3 = simpson(&w.iter().map(|q| q.powi(4)).collect::<Vec<_>>(), hx);
    println!("try: ray of sin x - 0.05 sin 3x peaks at {:.6}", a3 * a3 / (4.0 * b3)); assert!(a3 * a3 / (4.0 * b3) >= j1);
    println!("try: solutions with 1 and 2 interior zeros have J = 16c = {:.6} and 81c = {:.6}", 16.0 * c2, 81.0 * c2);
    let (mut lo, mut hi) = (0.5f64, 1.5f64);
    for _ in 0..60 { let mid = 0.5 * (lo + hi); if *shoot(mid, 20).0.last().unwrap() > 0.0 { lo = mid } else { hi = mid } }
    let (u20, p20) = shoot(0.5 * (lo + hi), 20);
    let f20: Vec<f64> = (0..=20).map(|i| 0.5 * p20[i] * p20[i] - 0.25 * u20[i].powi(4)).collect();
    println!("try: shooting with 20 RK4 steps: J = {:.9}", simpson(&f20, PI / 20.0));
    println!("ALL CHECKS PASS");
}
