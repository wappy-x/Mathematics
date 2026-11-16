// Reflection at a wall -- the same check as the Python, in Rust.  No crates.
// The open A string of a guitar, wave speed 143 m/s.  A 4 cm stretch near the
// bridge is pinched into a tent 2 mm high at 10 cm and let go from rest.  The
// bridge is the wall at x = 0; the nut, 65 cm away, is too far to matter yet.
// Road 1: d'Alembert's formula on the data extended oddly (clamped end) or
// evenly (free end).  Road 2: march the string on a grid that knows only the
// wall (u = 0 there, or zero slope), never the mirror.  Road 3: total energy
// through the bounce, against its closed form.
const L: f64 = 0.65;                       // string length (m)
const FREQ: f64 = 110.0;                   // note (Hz)
const C: f64 = 2.0 * L * FREQ;             // wave speed, m/s
const X0: f64 = 0.10;                      // tent centre (m)
const W: f64 = 0.02;                       // half-width (m)
const H: f64 = 2.0;                        // height (mm)

#[derive(Clone, Copy, PartialEq)]
enum Ext { Odd, Even, NoMirror, Two }      // clamped end, free end, mistake: no mirror, both ends clamped

fn phi(y: f64) -> f64 { if (y - X0).abs() < W { H * (1.0 - (y - X0).abs() / W) } else { 0.0 } }
fn dphi(y: f64) -> f64 {                   // its slope, mm per mm
    if (y - X0).abs() >= W { 0.0 } else if y < X0 { H / (1000.0 * W) } else { -H / (1000.0 * W) }
}
fn ext(e: Ext, y: f64) -> f64 {
    match e {
        Ext::Odd => if y >= 0.0 { phi(y) } else { -phi(-y) },
        Ext::Even => phi(y.abs()),
        Ext::NoMirror => if y >= 0.0 { phi(y) } else { 0.0 },
        Ext::Two => { let y = y.rem_euclid(2.0 * L); if y <= L { phi(y) } else { -phi(2.0 * L - y) } }  // odd about each end, period 2L
    }
}
fn u(e: Ext, x: f64, t: f64) -> f64 { (ext(e, x - C * t) + ext(e, x + C * t)) / 2.0 }  // d'Alembert
fn z(v: f64) -> f64 { if v.abs() < 5e-9 { 0.0 } else { v } }      // no "-0.0000" in print
fn mm(v: f64) -> String { format!("{:.4}", z(v)) }
fn slope(e: Ext, y: f64) -> f64 {          // slope of the extended data
    if e == Ext::Odd { dphi(y.abs()) } else if y >= 0.0 { dphi(y) } else { -dphi(-y) }
}

fn march(dx: f64, clamped: bool, t_end: f64) -> (Vec<f64>, f64) {  // road 2: Courant number 1
    let n = (0.40 / dx).round() as usize;
    let steps = (t_end * C / dx).round() as usize;
    let e = if clamped { Ext::Odd } else { Ext::Even };
    let nxt = |cur: &Vec<f64>, prev: &Vec<f64>, half: bool| -> Vec<f64> {
        let mut out = vec![0.0; n + 1];    // the far end at 40 cm stays at 0
        for j in 1..n {
            out[j] = (cur[j - 1] + cur[j + 1]) * (if half { 0.5 } else { 1.0 }) - (if half { 0.0 } else { prev[j] });
        }
        if !clamped {                      // zero slope: the node beyond the end copies node 1
            out[0] = cur[1] * (if half { 1.0 } else { 2.0 }) - (if half { 0.0 } else { prev[0] });
        }
        out
    };
    let mut old: Vec<f64> = (0..=n).map(|j| phi(j as f64 * dx)).collect();
    let mut cur = nxt(&old, &old, true);
    let mut gap = (0..=n).map(|j| (cur[j] - u(e, j as f64 * dx, dx / C)).abs()).fold(0.0, f64::max);
    for s in 2..=steps {
        let new = nxt(&cur, &old, false);
        old = cur;
        cur = new;
        let g = (0..=n).step_by(10).map(|j| (cur[j] - u(e, j as f64 * dx, s as f64 * dx / C)).abs()).fold(0.0, f64::max);
        gap = gap.max(g);
    }
    (cur, gap)
}

fn energy(e: Ext, t: f64) -> (f64, f64) { // road 3: kinetic and stretch parts, midpoint rule
    let n = 4000;
    let (mut kin, mut st) = (0.0, 0.0);
    for i in 0..n {
        let x = (i as f64 + 0.5) * 0.40 / n as f64;   // strip of 0.1 mm
        let (a, b) = (slope(e, x - C * t), slope(e, x + C * t));
        kin += ((b - a) / 2.0).powi(2) * 0.40 / n as f64;   // (u_t / c)^2
        st += ((a + b) / 2.0).powi(2) * 0.40 / n as f64;    // (u_x)^2
    }
    (kin, st)
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let (t1, t2) = (X0 / C, 2.0 * X0 / C);
    let e0 = 2.0 * W * (H / (1000.0 * W)).powi(2);   // closed form: slope squared times width
    println!("c = 2 x 0.65 m x {:.0} Hz = {:.0} m/s; tent: centre {:.0} cm, half-width {:.0} cm, height {:.0} mm", FREQ, C, 100.0 * X0, 100.0 * W, H);
    println!("centre reaches the bridge at {:.4} ms; back at 10 cm at {:.4} ms", 1000.0 * t1, 1000.0 * t2);
    println!("road 1, clamped: u(10 cm, {:.4} ms) = {} mm; u(30 cm) = {} mm", 1000.0 * t2, mm(u(Ext::Odd, X0, t2)), mm(u(Ext::Odd, 0.30, t2)));
    println!("road 1, free:    u(10 cm, {:.4} ms) = {} mm; bridge end at {:.4} ms = {} mm", 1000.0 * t2, mm(u(Ext::Even, X0, t2)), 1000.0 * t1, mm(u(Ext::Even, 0.0, t1)));
    println!("model holds until the right-going front reaches the nut: (65 - 12) cm / c = {:.4} ms", 1000.0 * (L - X0 - W) / C);
    println!("try: tent at 20 cm, echo at {:.4} ms; high E at 330 Hz, c = {:.0} m/s, echo at {:.4} ms", 2000.0 * 0.20 / C, 2.0 * L * 330.0, 2000.0 * X0 / (2.0 * L * 330.0));
    let (gc, gf) = (march(0.001, true, t2), march(0.001, false, t2));
    println!("road 2, grid dx = 1 mm, step dx/c: clamped u(10 cm) = {} mm; free u(10 cm) = {} mm", mm(gc.0[100]), mm(gf.0[100]));
    println!("road 2, largest gap to road 1 over the run, mm, below 1e-9: clamped {}, free {}", yn(gc.1 < 1e-9), yn(gf.1 < 1e-9));
    let wall = (0..200).map(|i| u(Ext::Odd, 0.0, i as f64 * t2 / 199.0).abs()).fold(0.0, f64::max);
    println!("clamped end stays at 0: max |u(0, t)| over 200 times = {:.4} mm", wall);
    println!("bars at x = 1 cm, ct = 9.5 cm: incoming half {}, mirror half {}, string {} mm", mm(ext(Ext::Odd, 0.105) / 2.0), mm(ext(Ext::Odd, -0.085) / 2.0), mm(u(Ext::Odd, 0.01, 0.095 / C)));
    println!("story at x = 1 cm: ct (cm), t (ms), u (mm), bridge slope; incoming half's slope alone");
    for ct in [0.0, 4.0, 8.5, 9.0, 9.5, 10.5, 11.0, 12.0, 16.0] {
        let t = ct / 100.0 / C;
        println!("  {:4.1}  {:.4}  {}  {:.2}; {:.3}", ct, 1000.0 * t, mm(u(Ext::Odd, 0.01, t)), z(slope(Ext::Odd, ct / 100.0)), z(dphi(ct / 100.0) / 2.0));
    }
    let (a, b) = (slope(Ext::Odd, 0.01 - t1 * C), slope(Ext::Odd, 0.01 + t1 * C));
    let flat = (0..41).map(|i| u(Ext::Odd, i as f64 / 1000.0, t1).abs()).fold(0.0, f64::max);
    let v3 = C * (slope(Ext::Odd, 0.03 + t1 * C) - slope(Ext::Odd, 0.03 - t1 * C)) / 2.0;  // past the overlap
    println!("at {:.4} ms: max |u| over 0 to 4 cm = {:.4} mm; velocity at 1 cm = {:.2} m/s, at 3 cm = {:.2} m/s, incoming half alone {:.2} m/s", 1000.0 * t1, flat, C * (b - a) / 2.0, z(v3), C * b / 2.0);
    let times: Vec<String> = (0..25).map(|k| format!("{:.2}", 1000.0 * k as f64 / 100.0 / C)).collect();
    let trace: Vec<String> = (0..25).map(|k| format!("{:.1}", z(u(Ext::Odd, X0, k as f64 / 100.0 / C)))).collect();
    println!("pickup at 10 cm, ct = 0, 1, ..., 24 cm; t (ms): {}", times.join(", "));
    println!("pickup at 10 cm, u (mm): {}", trace.join(", "));
    let fr: Vec<(f64, f64)> = [0.0, t1, t2].iter().map(|&t| energy(Ext::Odd, t)).collect();
    let parts: Vec<String> = fr.iter().map(|&(k, s)| format!("total {:.4}, kinetic {:.4}", (k + s) / e0, k / e0)).collect();
    println!("energy / start, clamped, at 0, {:.4}, {:.4} ms: {}", 1000.0 * t1, 1000.0 * t2, parts.join("; "));
    println!("figure, panels t = 0, {:.2}, {:.2} ms: peaks (cm, mm) (10, {}) ghost (-10, {}); (20, {}) ghost (-20, {}); (10, {}) (30, {}) ghost (-10, {})",
             1000.0 * t1, 1000.0 * t2, mm(u(Ext::Odd, X0, 0.0)), mm(u(Ext::Odd, -X0, 0.0)), mm(u(Ext::Odd, 0.2, t1)), mm(u(Ext::Odd, -0.2, t1)),
             mm(u(Ext::Odd, X0, t2)), mm(u(Ext::Odd, 0.3, t2)), mm(u(Ext::Odd, -X0, t2)));
    let (m1, m2, m3) = (u(Ext::NoMirror, X0, t2), u(Ext::Even, X0, t2), u(Ext::Odd, X0, t1));
    println!("mistake 1, no mirror: u(10 cm, {:.4} ms) = {} mm; the half sits at -10 cm, past the bridge", 1000.0 * t2, mm(m1));
    println!("mistake 2, even mirror at a clamped end: u(10 cm) = {} mm, and the bridge moves {} mm", mm(m2), mm(u(Ext::Even, 0.0, t1)));
    println!("mistake 3, echo time x0/c = {:.4} ms: u(10 cm) then = {} mm; the echo is due at {:.4} ms", 1000.0 * t1, mm(m3), 1000.0 * t2);
    let (m4, m5) = (u(Ext::Odd, 0.55, L / C), u(Ext::Two, 0.55, L / C));  // half a period: the nut has been reached
    println!("hypothesis fails, nut ignored: at half a period, {:.4} ms, u(55 cm) = {} mm; with both ends {} mm", 1000.0 * L / C, mm(m4), mm(m5));
    assert!((u(Ext::Odd, X0, t2) + H / 2.0).abs() < 1e-12 && (u(Ext::Even, X0, t2) - H / 2.0).abs() < 1e-12);  // flipped, upright
    assert!(gc.1 < 1e-9 && gf.1 < 1e-9 && (gc.0[100] + 1.0).abs() < 1e-9);  // grid knows only the wall
    assert!(wall < 1e-12);                                                   // mirror holds the bridge at 0
    assert!(fr.iter().all(|&(k, s)| ((k + s) / e0 - 1.0).abs() < 1e-9) && (fr[1].0 / e0 - 0.75).abs() < 1e-9);  // energy
    assert!((u(Ext::Even, 0.0, t1) - H).abs() < 1e-12 && m1.abs() < 1e-12);  // free end doubles; no mirror loses it
    assert!((m4 + H / 2.0).abs() < 1e-12 && (m5 + H).abs() < 1e-12);         // past the nut the one-end answer misses half
    println!("ALL CHECKS PASS");
}
