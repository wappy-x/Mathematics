// Reaction-diffusion on a simulated fish skin: Fisher's front speed and Turing's stripes.
// Illustrative constants: growth r = 1 per day, spreading D = 0.01 mm^2/day.
// Scaled units: length sqrt(D/r) = 0.1 mm, time 1/r = 1 day.
const R: f64 = 1.0; // growth per day
const D: f64 = 0.01; // mm^2/day
const A: f64 = 0.1; const B: f64 = 0.9; // Schnakenberg constants

fn fmt_e(x: f64) -> String {
    let s = format!("{:.3e}", x);
    let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn min_shape(c: f64) -> f64 {
    // the front shape U(xi) leaving the saddle U = 1 by RK4; returns its lowest value
    let mu = (-c + (c * c + 4.0).sqrt()) / 2.0;
    let (mut u, mut w, h, mut low) = (1.0 - 1e-6, -1e-6 * mu, 0.01, 1.0f64);
    let f = |u: f64, w: f64| (w, -c * w - u * (1.0 - u));
    for _ in 0..10000 {
        let k1 = f(u, w);
        let k2 = f(u + h / 2.0 * k1.0, w + h / 2.0 * k1.1); let k3 = f(u + h / 2.0 * k2.0, w + h / 2.0 * k2.1);
        let k4 = f(u + h * k3.0, w + h * k3.1);
        u += h / 6.0 * (k1.0 + 2.0 * k2.0 + 2.0 * k3.0 + k4.0); w += h / 6.0 * (k1.1 + 2.0 * k2.1 + 2.0 * k3.1 + k4.1);
        low = low.min(u);
    }
    low
}

fn fisher(dx: f64) -> Vec<f64> {
    // explicit grid on [0, 140], no-flux ends; returns front positions at t = 10..60
    let (dt, n) = (0.4 * dx * dx, (140.0 / dx).round() as usize + 1);
    let mut u: Vec<f64> = (0..n).map(|i| if i as f64 * dx < 10.0 { 1.0 } else { 0.0 }).collect();
    let (per, mut pos) = ((10.0 / dt).round() as usize, Vec::new());
    for s in 1..=6 * per {
        let mut new = u.clone();
        for i in 1..n - 1 {
            new[i] = u[i] + dt * ((u[i - 1] - 2.0 * u[i] + u[i + 1]) / (dx * dx) + u[i] * (1.0 - u[i]));
        }
        new[0] = new[1]; new[n - 1] = new[n - 2]; u = new;
        if s % per == 0 {
            let i = (0..n - 1).find(|&j| u[j] >= 0.5 && 0.5 > u[j + 1]).unwrap();
            pos.push((i as f64 + (u[i] - 0.5) / (u[i] - u[i + 1])) * dx);
        }
    }
    pos
}

struct Jac { fu: f64, fv: f64, gu: f64, gv: f64 }

fn sigma(j: &Jac, k2: f64, d: f64) -> f64 {
    // larger growth rate of the mode cos(kx), per day
    let (p, q) = (j.fu - k2, j.gv - d * k2);
    let disc = (p + q) * (p + q) - 4.0 * (p * q - j.fv * j.gu);
    if disc >= 0.0 { (p + q + disc.sqrt()) / 2.0 } else { (p + q) / 2.0 }
}

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn ring(d: f64, l: f64, n: usize, t: f64, start: &[f64], v0: f64, u0: f64, every: f64) -> (Vec<f64>, Vec<(i64, f64, usize)>) {
    // explicit grid on a ring of skin; returns u and a log of (day, largest departure, peaks)
    let dx = l / n as f64; let dt = 0.2 * dx * dx / d;
    let (mut u, mut v, mut log) = (start.to_vec(), vec![v0; n], Vec::new());
    let steps = (t / dt).round() as usize;
    let per = if every > 0.0 { (every / dt).round() as usize } else { 0 };
    for s in 0..=steps {
        if per > 0 && s % per == 0 {
            let peaks = (0..n).filter(|&i| u[i] > u[(i + n - 1) % n] && u[i] >= u[(i + 1) % n] && u[i] > u0).count();
            let amp = u.iter().fold(0.0f64, |a, &x| a.max((x - u0).abs()));
            log.push(((s as f64 * dt).round() as i64, amp, peaks));
        }
        if s == steps { break; }
        let (mut un, mut vn) = (vec![0.0; n], vec![0.0; n]);
        for i in 0..n {
            let (lft, p, uuv) = ((i + n - 1) % n, (i + 1) % n, u[i] * u[i] * v[i]);
            un[i] = u[i] + dt * ((u[lft] - 2.0 * u[i] + u[p]) / (dx * dx) + A - u[i] + uuv);
            vn[i] = v[i] + dt * (d * (v[lft] - 2.0 * v[i] + v[p]) / (dx * dx) + B - uuv);
        }
        u = un; v = vn;
    }
    (u, log)
}

fn main() {
    let (ell, c_mm, pi) = ((D / R).sqrt(), 2.0 * (R * D).sqrt(), std::f64::consts::PI);
    let c_star = c_mm / (ell * R);
    println!("front speed c* = {:.3} mm/day; 5 mm of bare skin covered in {:.1} days", c_mm, 5.0 / c_mm);
    println!("wrong: sqrt(rD) = {:.3} mm/day; diffusion alone: half cover stays at the edge, blurred by sqrt(2Dt) = {:.3} mm at 25 days", (R * D).sqrt(), (2.0 * D * 25.0).sqrt());
    for c in [1.8, 2.2] {
        println!("shape at speed {:.2} mm/day: scaled c^2 - 4 = {:.2}, lowest density {}", c * ell, c * c - 4.0, fmt_e(min_shape(c)));
    }
    assert!(min_shape(1.8) < -1e-6 && min_shape(2.2) > 0.0);
    let (mut speeds, mut p) = (Vec::new(), Vec::new());
    for dx in [0.5, 0.25, 0.125] {
        p = fisher(dx);
        speeds.push((p[5] - p[3]) / 20.0);
        println!("grid {:.4} mm: speed over days 40-60 = {:.4} mm/day", dx * ell, speeds[speeds.len() - 1] * ell);
    }
    let fr: Vec<String> = p.iter().map(|x| format!("{:.2}", x * ell)).collect();
    println!("front at days 10..60 (mm): {}; bare skin crossed by day 30 = {:.2} mm", fr.join(" "), (p[2] - 10.0) * ell);
    let (order, rich) = (((speeds[1] - speeds[0]) / (speeds[2] - speeds[1])).log2(), speeds[2] + (speeds[2] - speeds[1]) / 3.0);
    let bram = c_star - 1.5 * (60.0f64 / 40.0).ln() / 20.0;
    println!("observed order {:.2}; extrapolated speed {:.4}; Bramson c* - 1.5 l ln(60/40)/20 = {:.4} mm/day", order, rich * ell, bram * ell);
    assert!(speeds.iter().all(|&v| v < c_star) && (rich - bram).abs() < 0.003 && order > 1.7 && order < 2.3);
    let (f, g) = (|u: f64, v: f64| A - u + u * u * v, |u: f64, v: f64| B - u * u * v);
    let (u0, v0) = (A + B, B / ((A + B) * (A + B)));
    let j = Jac { fu: -1.0 + 2.0 * u0 * v0, fv: u0 * u0, gu: -2.0 * u0 * v0, gv: -u0 * u0 };
    let h = 1e-4;
    let num = [(f(u0 + h, v0) - f(u0 - h, v0)) / (2.0 * h), (f(u0, v0 + h) - f(u0, v0 - h)) / (2.0 * h),
               (g(u0 + h, v0) - g(u0 - h, v0)) / (2.0 * h), (g(u0, v0 + h) - g(u0, v0 - h)) / (2.0 * h)];
    assert!((0..4).all(|i| (num[i] - [j.fu, j.fv, j.gu, j.gv][i]).abs() < 1e-8));
    let (tr, det) = (j.fu + j.gv, j.fu * j.gv - j.fv * j.gu);
    println!("uniform state u0 = {:.3}, v0 = {:.3}; fu fv gu gv = {:.2} {:.2} {:.2} {:.2}; trace {:.2}, det {:.2}", u0, v0, j.fu, j.fv, j.gu, j.gv, tr, det);
    assert!(tr < 0.0 && det > 0.0 && f(u0, v0).abs() + g(u0, v0).abs() < 1e-12);
    let s_c = (det.sqrt() + (det - j.fu * j.gv).sqrt()) / j.fu; let d_c = s_c * s_c;
    let (mut lo, mut hi) = (1.0f64, 20.0f64); // second road: bisect on the scanned worst determinant
    for _ in 0..50 {
        let mid = (lo + hi) / 2.0;
        let worst = (1..15000).map(|i| { let q = i as f64 * 1e-4; (j.fu - q) * (j.gv - mid * q) - j.fv * j.gu }).fold(f64::INFINITY, f64::min);
        if worst > 0.0 { lo = mid } else { hi = mid }
    }
    println!("threshold: sqrt(d_c) = {:.3}; d_c formula {:.4}, scan {:.4}; D_v must exceed {:.4} mm^2/day", s_c, d_c, lo, d_c * D);
    assert!((d_c - lo).abs() < 1e-3);
    let kc = (det / d_c).sqrt().sqrt();
    println!("first stripe spacing at onset 2 pi/k_c = {:.3} mm", 2.0 * pi / kc * ell);
    let d = 20.0;
    let m = j.fu * d + j.gv;
    let (q1, q2) = ((m + (m * m - 4.0 * d * det).sqrt()) / (2.0 * d), (m - (m * m - 4.0 * d * det).sqrt()) / (2.0 * d));
    println!("d = 20: m = {:.2}; unstable k^2 from {:.4} to {:.4} (scaled); spacings {:.3} to {:.3} mm", m, q2, q1, 2.0 * pi / q1.sqrt() * ell, 2.0 * pi / q2.sqrt() * ell);
    let (mut best, mut kbest) = (f64::NEG_INFINITY, 0.0);
    for i in 1..20000 { let k = i as f64 * 1e-4; let s = sigma(&j, k * k, d); if s >= best { best = s; kbest = k; } }
    println!("fastest mode: k = {:.3} rad/mm, spacing {:.3} mm, growth {:.4} per day", kbest / ell, 2.0 * pi / kbest * ell, sigma(&j, kbest * kbest, d));
    for dd in [5.0, d_c, 20.0] {
        let row: Vec<String> = (1..11).map(|jj| format!("{:.3}", sigma(&j, (jj as f64 * ell) * (jj as f64 * ell), dd))).collect();
        println!("sigma, d = {:.2}, k = 1..10 rad/mm: {}", dd, row.join(" "));
    }
    let (mut rng, lr, nr) = (SplitMix(7), 64.0, 128); // ring length (scaled) and grid points
    let noise: Vec<f64> = (0..nr).map(|_| u0 + 0.01 * (2.0 * rng.next() - 1.0)).collect();
    let (u, log) = ring(20.0, lr, nr, 100.0, &noise, v0, u0, 5.0);
    for &(t, amp, pk) in &log[..9] {
        println!("day {:3}: largest departure {}, peaks {}", t, fmt_e(amp), pk);
    }
    let (last, predicted) = (log[log.len() - 1].2, lr / (2.0 * pi / kbest));
    println!("day 100: {} stripes on a {:.1} mm ring, spacing {:.3} mm; predicted {:.2}", last, lr * ell, lr * ell / last as f64, predicted);
    assert!(last == 5 && (predicted - last as f64).abs() < 0.5);
    let prof: Vec<String> = (0..nr).step_by(4).map(|i| format!("{:.2}", u[i])).collect();
    println!("stripe profile u, every 0.2 mm: {}", prof.join(" "));
    let k5 = 2.0 * pi * 5.0 / 64.0; // third road: one small mode grows at sigma(k)
    let one: Vec<f64> = (0..128).map(|i| u0 + 1e-6 * (k5 * i as f64 * 0.5).cos()).collect();
    let mlog = ring(20.0, 64.0, 128, 20.0, &one, v0, u0, 10.0).1;
    let rate = (mlog[2].1 / mlog[1].1).ln() / 10.0;
    println!("mode 5 (k = {:.3} rad/mm) grows at {:.4} per day on the grid; formula {:.4}", k5 / ell, rate, sigma(&j, k5 * k5, d));
    println!("mode 5 alone, per day: reaction {:.3}; activator spreading {:.3}; substrate spreading {:.3}; together {:.3}", sigma(&j, 0.0, d), -k5 * k5, -d * k5 * k5, sigma(&j, k5 * k5, d));
    assert!((rate - sigma(&j, k5 * k5, d)).abs() < 0.003);
    let dep = |w: &[f64]| w.iter().fold(0.0f64, |a, &x| a.max((x - u0).abs()));
    let (eq, small) = (ring(1.0, 64.0, 128, 100.0, &noise[..128], v0, u0, 0.0).0, ring(20.0, 7.0, 14, 100.0, &noise[..14], v0, u0, 0.0).0);
    println!("equal diffusion d = 1: departure at day 100 = {}", fmt_e(dep(&eq)));
    println!("0.7 mm ring, d = 20: departure at day 100 = {}", fmt_e(dep(&small)));
    assert!(dep(&eq) < 1e-5 && dep(&small) < 1e-5);
    println!("ALL CHECKS PASS");
}
