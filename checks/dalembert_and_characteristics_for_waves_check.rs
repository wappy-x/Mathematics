// d'Alembert by characteristics -- the same check in Rust, std only.  The open
// A string of a guitar, 65 cm long, is pulled 3 mm aside a third of the way
// along and let go from rest.  Road 1 is d'Alembert's formula, the held ends
// built in by the odd extension.  Road 2 rides the characteristics: the signal
// w = u_t - c u_x is read back along a right-moving line, then summed by RK4
// along a left-moving one.  Road 3 marches the string in whole numbers on a
// grid of characteristics, ends held at zero.
const L: f64 = 0.65; // string length (m)
const H: f64 = 3.0; // pluck height (mm)
const FREQ: f64 = 110.0; // note (Hz)
const C: f64 = 2.0 * L * FREQ; // wave speed (m/s): the open A string
const A: f64 = L / 3.0; // pluck point, m from the bridge
const PER: f64 = 2.0 * L / C; // one period (s)

fn f(y: f64) -> f64 { if y <= A { H * y / A } else { H * (L - y) / (L - A) } } // starting shape, mm
fn fp(y: f64) -> f64 { if y < A { H / A } else { -H / (L - A) } } // its slope, mm per m
fn fext(y: f64) -> f64 { // f made odd about each end, period 2L
    let y = y.rem_euclid(2.0 * L);
    if y <= L { f(y) } else { -f(2.0 * L - y) }
}
fn u(x: f64, t: f64) -> f64 { (fext(x - C * t) + fext(x + C * t)) / 2.0 } // road 1: d'Alembert
fn fz(y: f64) -> f64 { if (0.0..=L).contains(&y) { f(y) } else { 0.0 } } // mistake: ends ignored
fn z(v: f64) -> f64 { if v.abs() < 1e-9 { 0.0 } else { v } } // no "-0.00" in print
fn fold(y: f64) -> f64 { // a path at speed c, bounced between the ends
    let y = y.rem_euclid(2.0 * L);
    if y <= L { y } else { 2.0 * L - y }
}

fn ride(x: f64, t: f64, n: usize) -> f64 { // road 2: RK4 along the left-moving line
    let w = |s: f64| -C * fp(x + C * t - 2.0 * C * s); // w = u_t - c u_x, read back to t = 0
    let (mut total, k) = (f(x + C * t), t / n as f64); // start: the height where the line meets t = 0
    for i in 0..n {
        let s = i as f64 * k; // du/ds = w(s) holds no u, so RK4 is Simpson
        let (k1, k2, k4) = (w(s), w(s + k / 2.0), w(s + k));
        total += k * (k1 + 4.0 * k2 + k4) / 6.0;
    }
    total
}

fn res(x: f64, t: f64, h: f64) -> f64 { // (u_tt / c^2 - u_xx) by centred differences, mm per m^2
    let k = h / (2.0 * C);
    (u(x, t + k) - 2.0 * u(x, t) + u(x, t - k)) / (C * k).powi(2) - (u(x + h, t) - 2.0 * u(x, t) + u(x - h, t)) / (h * h)
}

fn main() {
    let (x, t) = (L / 2.0, PER / 10.0); // 12th fret (half way), a tenth of a period
    let ans = u(x, t);
    let jump = H / A + H / (L - A);
    println!("c = 2 x 0.65 m x {} Hz = {:.0} m/s; period 2L/c = {:.4} ms; pluck at {:.4} cm", FREQ, C, 1000.0 * PER, 100.0 * A);
    println!("t = {:.4} ms: ct = {:.4} cm; feet at {:.4} and {:.4} cm", 1000.0 * t, 100.0 * C * t, 100.0 * (x - C * t), 100.0 * (x + C * t));
    println!("triangle: pieces {:.4} and {:.4} cm, slopes {:.4} and {:.4} mm per m, steepest {:.4}", 100.0 * A, 100.0 * (L - A), H / A, -H / (L - A), H / A / 1000.0);
    println!("f at the feet: {:.4} and {:.4} mm; started at f(32.5 cm) = {:.4} mm", f(x - C * t), f(x + C * t), f(x));
    println!("road 1, d'Alembert: u(32.5 cm, {:.4} ms) = {:.4} mm", 1000.0 * t, ans);
    let (vv, ww) = (C * fp(x + C * t) / 1000.0, -C * fp(x - C * t) / 1000.0); // m/s
    println!("signals at the point: v = u_t + c u_x = {:.4} m/s, w = u_t - c u_x = {:.4} m/s", vv, ww);
    println!("so u_t = (v + w)/2 = {:.4} m/s and u_x = (v - w)/(2c) = {:.4} mm per m", (vv + ww) / 2.0, 1000.0 * (vv - ww) / (2.0 * C));
    let mut err = vec![];
    for n in [20usize, 40, 80] {
        let r = ride(x, t, n);
        err.push((r - ans).abs());
        println!("road 2, RK4 {} steps: {:.6} mm, error {:.6} mm, one step x jump / 6 = {:.6} mm", n, r, err[err.len() - 1], t / n as f64 * C * jump / 6.0);
    }
    println!("road 2 error ratios: {:.2} {:.2} (first order: a corner sits inside one step)", err[0] / err[1], err[1] / err[2]);
    const N: usize = 30; // road 3: cells of L/30; time step L/(30c)
    let ff: Vec<i64> = (0..=N as i64).map(|j| if j <= 10 { 12 * j } else { 6 * (N as i64 - j) }).collect(); // 40 x f
    assert!((1..N).all(|j| (ff[j - 1] + ff[j + 1]) % 2 == 0)); // first step stays whole
    let mut first = vec![0i64; N + 1];
    for j in 1..N { first[j] = (ff[j - 1] + ff[j + 1]) / 2; } // from rest
    let mut rows = vec![ff.clone(), first];
    for _ in 2..=2 * N { // u(t + dt) = u(x - dx) + u(x + dx) - u(t - dt)
        let (p, q) = (&rows[rows.len() - 1], &rows[rows.len() - 2]);
        let mut next = vec![0i64; N + 1];
        for j in 1..N { next[j] = p[j - 1] + p[j + 1] - q[j]; }
        rows.push(next);
    }
    println!("grid: dx = L/30 = {:.4} cm, dt = dx/c = {:.4} ms; corners travel {:.1} cm per ms; extension repeats every {:.0} cm", 100.0 * L / N as f64, 1000.0 * L / N as f64 / C, C / 10.0, 200.0 * L);
    let gap = (0..=N).map(|j| (rows[6][j] as f64 / 40.0 - u(j as f64 * L / N as f64, 6.0 * PER / (2 * N) as f64)).abs()).fold(0.0, f64::max);
    let yn = |b: bool| if b { "yes" } else { "no" };
    println!("road 3, grid in 1/40 mm: u(32.5 cm, 6 steps) = {}/40 = {:.4} mm; every point within 1e-12 mm of road 1: {}", rows[6][15], rows[6][15] as f64 / 40.0, yn(gap < 1e-12));
    let half = (0..=N).all(|j| rows[N][j] == -ff[N - j]);
    let full = rows[2 * N] == ff;
    println!("grid at half a period, the start flipped and mirrored: {}; after a whole period, the start: {}", yn(half), yn(full));
    let (lc, rc) = (fold(A - C * t), fold(A + C * t)); // the two corners ride x = a -/+ ct
    println!("corners at {:.4} cm ({:.4} mm) and {:.4} cm ({:.4} mm)", 100.0 * lc, u(lc, t), 100.0 * rc, u(rc, t));
    for m in [1.0 / 6.0, 1.0 / 3.0, 0.5, 1.0] { // the corners through one period
        let tm = m * PER;
        let (p, q) = (fold(A - C * tm), fold(A + C * tm));
        println!("moment {:.4} ms: corners at {:.2} cm ({:.2} mm), {:.2} cm ({:.2} mm)", 1000.0 * tm, 100.0 * p, z(u(p, tm)), 100.0 * q, z(u(q, tm)));
    }
    let e = 1e-4;
    let (sl, sr) = ((u(rc, t) - u(rc - e, t)) / e, (u(rc + e, t) - u(rc, t)) / e);
    println!("slopes either side of the right corner: {:.4} and {:.4} mm per m; jump {:.4}, half the start's {:.4}", sl, sr, sl - sr, jump);
    println!("half a period, {:.4} ms: u(43.33 cm) = {:.4} mm, u(32.5 cm) = {:.4} mm", 1000.0 * PER / 2.0, u(L - A, PER / 2.0), u(x, PER / 2.0));
    let rr = [res(rc, t, 1e-3), res(rc, t, 5e-4)];
    println!("residual at 32.5 cm: {:.4}; at the right corner: h = 1 mm {:.1}, h = 0.5 mm {:.1} mm per m^2", z(res(x, t, 1e-3)).abs(), rr[0], rr[1]);
    println!("mistake 1, no 1/2: {:.4} mm; mistake 2, right-mover only f(x - ct): {:.4} mm", 2.0 * ans, f(x - C * t));
    println!("mistake 3, ends ignored: bridge at {:.4} ms moves to {:.4} mm; 32.5 cm at half a period {:.4} mm, not {:.4}",
        1000.0 * t, (fz(-C * t) + fz(C * t)) / 2.0, z((fz(x - L) + fz(x + L)) / 2.0), u(x, PER / 2.0));
    for tt in [0.0, PER / 10.0, PER / 2.0] {
        let row: Vec<String> = (0..16).map(|j| format!("{:.2}", z(u(j as f64 * L / 15.0, tt)))).collect();
        println!("chart, t = {:.4} ms: {}", 1000.0 * tt, row.join(", "));
    }
    let pts = [(A, 0.0), (0.0, A), (L, L - A), (L - A, L), (L, L + A), (0.0, 2.0 * L - A), (A, 2.0 * L)];
    let fig: Vec<String> = pts.iter().map(|&(px, s)| format!("({:.2}, {:.4})", 100.0 * px, 1000.0 * s / C)).collect();
    println!("figure, corner paths (cm, ms): {}", fig.join("; "));
    assert!((ans - 2.025).abs() < 1e-12 && (u(x, 0.0) - 2.25).abs() < 1e-12); // by hand
    for (i, n) in [20.0, 40.0, 80.0].iter().enumerate() { assert!((err[i] - t / n * C * jump / 6.0).abs() < 1e-9); }
    assert!((err[0] / err[1] - 2.0).abs() < 1e-6 && (err[1] / err[2] - 2.0).abs() < 1e-6); // road 2 converges
    assert!(rows[6][15] == 81 && gap < 1e-12 && half && full); // road 3, exact
    assert!((sl - sr - jump / 2.0).abs() < 1e-6); // half the jump
    assert!(res(x, t, 1e-3).abs() < 1e-3 && rr[1] / rr[0] > 1.9); // corner: no u_xx
    println!("ALL CHECKS PASS");
}
