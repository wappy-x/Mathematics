// PID control and tuning -- the same check as pid_control_and_tuning_check.py, in Rust.  Std only.
// Room heated through a slow pipe: u = radiator heat change (kW), y = room temperature change (C),
// time in minutes.  True room: gain 2 C/kW, lag 3 min, delay 1 min.  Roads: bump-test fits,
// closed-form frequency domain, exact step-by-step simulation of the loop.
use std::f64::consts::PI;

const K: f64 = 2.0; const TAU: f64 = 3.0; const TH: f64 = 1.0; const DT: f64 = 0.01;

struct SplitMix(u64);
impl SplitMix {
    fn next(&mut self) -> f64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.0 ^ (self.0 >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (z ^ (z >> 31)) as f64 / 18446744073709551616.0
    }
}
#[derive(Clone, Copy)] struct P { k: f64, tau: f64, th: f64, dt: f64 }
const ROOM: P = P { k: K, tau: TAU, th: TH, dt: DT };

// L(jw) = kp (1 + j c) K e^(-j w th) / (1 + j w tau): magnitude and phase; ti = 0 means no integral
fn l(w: f64, g: (f64, f64, f64), p: P) -> (f64, f64) {
    let c = g.2 * w - if g.1 > 0.0 { 1.0 / (g.1 * w) } else { 0.0 };
    (g.0 * (1.0 + c * c).sqrt() * p.k / (1.0 + (w * p.tau).powi(2)).sqrt(), c.atan() - (w * p.tau).atan() - w * p.th)
}
fn first(f: &dyn Fn(f64) -> f64) -> f64 {
    let mut w = 0.01;
    while f(w) * f(w * 1.01) > 0.0 { w *= 1.01; }
    let (mut a, mut b) = (w, w * 1.01);
    for _ in 0..60 {
        let m = (a + b) / 2.0; if f(a) * f(m) <= 0.0 { b = m; } else { a = m; }
    }
    a
}
fn margins(g: (f64, f64, f64), p: P) -> (f64, f64, f64, f64) {
    let (wc, w180) = (first(&|w| l(w, g, p).0 - 1.0), first(&|w| l(w, g, p).1 + PI));
    (1.0 / l(w180, g, p).0, (PI + l(wc, g, p).1) * 180.0 / PI, wc, w180)
}

fn sim(g: (f64, f64, f64), p: P, r: f64, dist: f64, tend: f64, umax: f64, aw: bool) -> Vec<f64> {
    let (kp, ti, td) = g;
    let (a, nd) = ((-p.dt / p.tau).exp(), (p.th / p.dt).round() as usize);
    let (mut buf, mut ys) = (vec![0.0; nd], Vec::new());
    let (mut y, mut yp, mut ip) = (0.0f64, 0.0f64, 0.0f64);
    for n in 0..=((tend / p.dt).round() as usize) {
        ys.push(y); let e = r - y;
        let mut ui = ip + if ti > 0.0 { kp / ti * e * p.dt } else { 0.0 };
        let mut u = kp * e + ui - kp * td * (y - yp) / p.dt;      // derivative on the measurement
        if u.abs() > umax {
            u = if u > 0.0 { umax } else { -umax };
            if aw { ui = ip; }                                   // anti-windup: stop integrating
        }
        ip = ui; yp = y;
        let ud = buf[n % nd]; buf[n % nd] = u;
        y = a * y + (1.0 - a) * p.k * (ud + if n as f64 * p.dt >= 20.0 { dist } else { 0.0 });
    }
    ys
}
fn lp(g: (f64, f64, f64), p: P, tend: f64) -> Vec<f64> { sim(g, p, 1.0, -0.5, tend, f64::INFINITY, true) }
fn growth(g: (f64, f64, f64), p: P) -> f64 {
    let (ys, n) = (sim(g, p, 1.0, 0.0, 60.0, f64::INFINITY, true), (20.0 / p.dt).round() as usize);
    let sw = |a: usize, b: usize| ys[a..b].iter().map(|v| (v - 1.0).abs()).fold(0.0, f64::max);
    sw(2 * n, ys.len()) / sw(n, 2 * n)
}
fn row(label: &str, v: &[f64], prec: usize) {
    let s: Vec<String> = v.iter().map(|x| format!("{:5.p$}", x, p = prec)).collect();
    println!("{}{}", label, s.join(" "));
}

fn main() {
    // ---- road 1: the bump test ----
    let mut rnd = SplitMix(2026);
    let ts: Vec<f64> = (0..221).map(|n| n as f64 / 10.0 - 2.0).collect();
    let data: Vec<f64> = ts.iter().map(|&t| 20.0 + if t > TH { K * (1.0 - (-(t - TH) / TAU).exp()) } else { 0.0 } + 0.04 * (rnd.next() - 0.5)).collect();
    let base = data[..20].iter().sum::<f64>() / 20.0;
    let fin = data[200..].iter().sum::<f64>() / 21.0;
    let cross = |f: f64| {
        let lvl = base + f * (fin - base);
        let i = data.iter().position(|&v| v >= lvl).unwrap();
        ts[i - 1] + (lvl - data[i - 1]) / (data[i] - data[i - 1]) * 0.1
    };
    let (t28, t63) = (cross(0.283), cross(0.632));
    let (ka, taua, tha) = (fin - base, 1.5 * (t63 - t28), t63 - 1.5 * (t63 - t28));
    let mut best = (f64::INFINITY, 0.0, 0.0, 0.0);
    for i in 0..81 {
        for j in 0..201 {
            let (th, tau) = (0.8 + 0.005 * i as f64, 2.5 + 0.005 * j as f64);
            let f: Vec<f64> = ts.iter().map(|&t| if t > th { 1.0 - (-(t - th) / tau).exp() } else { 0.0 }).collect();
            let k = f.iter().zip(&data).map(|(a, v)| a * (v - base)).sum::<f64>() / f.iter().map(|a| a * a).sum::<f64>();
            let sse = f.iter().zip(&data).map(|(a, v)| (v - base - k * a).powi(2)).sum::<f64>();
            if sse < best.0 { best = (sse, k, tau, th); }
        }
    }
    println!("room: K = 2 C/kW, tau = 3 min, theta = 1 min; bump 1.5 -> 2.5 kW at t = 0; noise +-0.02 C");
    println!("bump, read off: base {:.3} C, final {:.3} C, t28 {:.3} min, t63 {:.3} min", base, fin, t28, t63);
    println!("fit, two-point:     K {:.3} C/kW  tau {:.3} min  theta {:.3} min  (t63 - t28 = {:.4} min)", ka, taua, tha, t63 - t28);
    println!("two-point constants: ln(1/(1 - 0.283)) = {:.4}, ln(1/(1 - 0.632)) = {:.4}", -(1.0f64 - 0.283).ln(), -(1.0f64 - 0.632).ln());
    let (_, kb, taub, thb) = best; println!("fit, least squares: K {:.3} C/kW  tau {:.3} min  theta {:.3} min", kb, taub, thb);
    assert!((ka - K).abs() < 0.03 && (taua - TAU).abs() < 0.1 && (tha - TH).abs() < 0.05);
    assert!((kb - K).abs() < 0.02 && (taub - TAU).abs() < 0.05 && (thb - TH).abs() < 0.03);
    // ---- road 2: frequency domain ----
    let wu = margins((1.0, 0.0, 0.0), ROOM).3;
    let (ku, pu) = ((1.0 + (wu * TAU).powi(2)).sqrt() / K, 2.0 * PI / wu);
    println!("ultimate, frequency domain: wu {:.4} rad/min  Ku {:.4} kW/C  Pu {:.4} min", wu, ku, pu);
    // ---- road 3: simulation ----
    let (mut lo, mut hi) = (2.0, 3.5);
    for _ in 0..40 {
        let m = (lo + hi) / 2.0; if growth((m, 0.0, 0.0), ROOM) > 1.0 { hi = m; } else { lo = m; }
    }
    let ys = sim((lo, 0.0, 0.0), ROOM, 1.0, 0.0, 60.0, f64::INFINITY, true);
    let up: Vec<f64> = (3001..6000).filter(|&n| ys[n - 1] < 1.0 && 1.0 <= ys[n]).map(|n| n as f64 * DT).collect();
    let pus = (up[up.len() - 1] - up[0]) / (up.len() - 1) as f64;
    println!("ultimate, simulation:       Ku {:.4} kW/C  Pu {:.4} min", lo, pus);
    assert!((lo / ku - 1.0).abs() < 0.01 && (pus / pu - 1.0).abs() < 0.01);

    let tune = [("ZN PID", (1.2 * TAU / (K * TH), 2.0 * TH, 0.5 * TH)), ("lambda PI", (TAU / (K * (1.0 + TH)), TAU, 0.0))];
    for (name, g) in tune {
        let (gm, pm, wc, w180) = margins(g, ROOM);
        let ys = lp(g, ROOM, 40.0);
        let ov = ys[..2000].iter().fold(f64::MIN, |a, &b| a.max(b)) - 1.0;
        let settle = (0..2000).filter(|&n| (ys[n] - 1.0).abs() > 0.02).max().unwrap() as f64 * DT;
        let dip = 1.0 - ys[2000..].iter().fold(f64::MAX, |a, &b| a.min(b));
        let iae = ys[2000..].iter().map(|v| (1.0 - v).abs()).sum::<f64>() * DT;
        let ie = lp(g, ROOM, 60.0)[2000..].iter().map(|v| 1.0 - v).sum::<f64>() * DT;
        println!("{:9}: Kp {:.3} kW/C  Ti {:.3} min  Td {:.3} min  Ki {:.3}  Kd {:.3}", name, g.0, g.1, g.2, g.0 / g.1, g.0 * g.2);
        println!("{:9}: GM {:.3}  PM {:.2} deg  wc {:.4}  w180 {:.4} rad/min", name, gm, pm, wc, w180);
        println!("{:9}: overshoot {:.3} C  settles (2%) {:.2} min  door dip {:.3} C  IAE {:.3} C min", name, ov, settle, dip, iae);
        println!("{:9}: error at 40 min {:.4} C; door error, integrated {:.4} C min (0.5/Ki = {:.4})",
                 name, (1.0 - ys[ys.len() - 1]).abs(), ie, 0.5 * g.1 / g.0);
        assert!((1.0 - ys[ys.len() - 1]).abs() < 0.005 && (ie / (0.5 * g.1 / g.0) - 1.0).abs() < 0.002);
        assert!(growth((g.0 * gm * 0.98, g.1, g.2), ROOM) < 1.0 && 1.0 < growth((g.0 * gm * 1.02, g.1, g.2), ROOM));
    }
    let (gm, pm, wc, _) = margins(tune[1].1, ROOM);
    println!("lambda PI, by hand: GM = pi = {:.3}  PM = 90 - 0.5 rad = {:.2} deg  wc = 0.5", PI, 90.0 - 0.5 * 180.0 / PI);
    assert!((gm - PI).abs() < 1e-6 && (pm - (90.0 - 0.5 * 180.0 / PI)).abs() < 1e-6 && (wc - 0.5).abs() < 1e-6);
    // ---- what breaks ----
    let off = 1.0 - sim((1.8, 0.0, 0.0), ROOM, 1.0, 0.0, 80.0, f64::INFINITY, true)[8000];
    println!("wrong: P only, Kp 1.8: error left {:.4} C (formula 1/(1 + K Kp) = {:.4})", off, 1.0 / (1.0 + K * 1.8));
    assert!((off - 1.0 / (1.0 + K * 1.8)).abs() < 1e-3);
    println!("wrong: P only at 1.1 Ku = {:.3}: swing grows x{:.2} per 20 min", 1.1 * ku, growth((1.1 * ku, 0.0, 0.0), ROOM));
    for aw in [false, true] {
        let ys = sim(tune[1].1, ROOM, 2.5, 0.0, 40.0, 1.5, aw);
        let mx = ys.iter().fold(f64::MIN, |a, &b| a.max(b));
        let st = (0..4001).filter(|&n| (ys[n] - 2.5).abs() > 0.05).max().unwrap() as f64 * DT;
        println!("windup: lambda PI, 2.5 C step, heater 0..3 kW, anti-windup {}: overshoot {:.3} C, settles (2%) {:.2} min",
                 if aw { "on " } else { "off" }, (mx - 2.5).max(0.0), st);
    }
    let slow = P { th: 2.0, ..ROOM };
    for (name, g) in tune {
        let (gm, pm, _, _) = margins(g, slow); let gr = growth(g, slow); println!("wrong: pipe delay 2 min, {:9}: GM {:.3}  PM {:.2} deg  swing x{:.3} per 20 min", name, gm, pm, gr);
        assert!((gm > 1.0) == (gr < 1.0));
    }
    println!("outside the model: 4 C setpoint asks {:.1} kW extra; heater gives 1.5, room tops out at {:.1} C", 4.0 / K, 20.0 + 1.5 * K);
    println!("try: lambda = 3 min: Kp {:.4}  GM {:.3}", TAU / (K * 4.0), margins((TAU / (K * 4.0), TAU, 0.0), ROOM).0);
    let g3 = growth(tune[0].1, P { k: 3.0, ..ROOM }); println!("try: ZN PID on K = 3 room: GM {:.3}  swing x{:.3} per 20 min", margins(tune[0].1, P { k: 3.0, ..ROOM }).0, g3);
    assert!(g3 > 1.0 && growth((1.1 * ku, 0.0, 0.0), ROOM) > 1.0);   // GM below 1: the simulation grows too
    let fine = P { dt: 0.001, ..ROOM }; let zf = lp(tune[0].1, fine, 40.0);
    println!("finer step 0.001 min, ZN PID: overshoot {:.3} C  settles (2%) {:.2} min  swing x{:.2} (K = 3), x{:.2} (delay 2 min)", zf[..20000].iter().fold(f64::MIN, |a, &b| a.max(b)) - 1.0, (0..20000).filter(|&n| (zf[n] - 1.0).abs() > 0.02).max().unwrap() as f64 * 0.001, growth(tune[0].1, P { k: 3.0, ..fine }), growth(tune[0].1, P { th: 2.0, ..fine }));
    println!("try: lambda PI, longest pipe delay it survives: {:.3} min", 1.0 + (PI / 2.0 - 0.5) / 0.5);
    assert!(growth(tune[1].1, P { th: 3.10, ..ROOM }) < 1.0 && 1.0 < growth(tune[1].1, P { th: 3.20, ..ROOM }));
    let pick: Vec<usize> = (0..221).step_by(10).collect();
    row("chart, bump t min    ", &pick.iter().map(|&n| ts[n]).collect::<Vec<_>>(), 0);
    row("chart, bump data C   ", &pick.iter().map(|&n| data[n]).collect::<Vec<_>>(), 2);
    row("chart, bump fit C    ", &pick.iter().map(|&n| base + if ts[n] > tha { ka * (1.0 - (-(ts[n] - tha) / taua).exp()) } else { 0.0 }).collect::<Vec<_>>(), 2);
    let (zn, lam) = (lp(tune[0].1, ROOM, 40.0), lp(tune[1].1, ROOM, 40.0));
    row("chart, loop t min    ", &(0..41).map(|n| n as f64).collect::<Vec<_>>(), 0);
    row("chart, ZN PID C      ", &(0..41).map(|n| 20.0 + zn[n * 100]).collect::<Vec<_>>(), 2);
    row("chart, lambda PI C   ", &(0..41).map(|n| 20.0 + lam[n * 100]).collect::<Vec<_>>(), 2);
    println!("ALL CHECKS PASS");
}
