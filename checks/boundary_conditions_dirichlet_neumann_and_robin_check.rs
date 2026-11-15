// Boundary conditions -- the check behind the card.  Rust std only.
// A 1 m square steel plate, 10 mm thick, faces insulated, so heat moves in its
// plane.  Bottom edge held at 20 + 60 sin(pi x) C, sides held at 20 C; the top
// edge is held at 20 C (D), insulated (N) or cooled by 20 C air (R).  v = u - 20.
// Road one: closed forms in sinh and cosh.  Road two: a grid solved by
// over-relaxed Gauss-Seidel, written out.  Road three: the heat budget, each
// edge's flux summed by Simpson's rule.  Then the tube (periodic) and the
// all-insulated plate fed and drained through its edges (compatibility).
use std::f64::consts::PI;
const K: f64 = 50.0; const D: f64 = 0.01; // W/(m K), m
const RHO: f64 = 7850.0; const C: f64 = 490.0; // kg/m^3, J/(kg K)

fn ch(x: f64) -> f64 { x.cosh() } fn sh(x: f64) -> f64 { x.sinh() }
// profile up the plate, Y(0) = 1; b = h/k per m
fn yp(kind: char, y: f64, b: f64) -> f64 {
    match kind {
        'D' => sh(PI * (1.0 - y)) / sh(PI),
        'N' => ch(PI * (1.0 - y)) / ch(PI),
        _ => (PI * ch(PI * (1.0 - y)) + b * sh(PI * (1.0 - y))) / (PI * ch(PI) + b * sh(PI)),
    }
}
// its slope, from the same formulas
fn dyp(kind: char, y: f64, b: f64) -> f64 {
    match kind {
        'D' => -PI * ch(PI * (1.0 - y)) / sh(PI),
        'N' => -PI * sh(PI * (1.0 - y)) / ch(PI),
        _ => -PI * (PI * sh(PI * (1.0 - y)) + b * ch(PI * (1.0 - y))) / (PI * ch(PI) + b * sh(PI)),
    }
}
// integral of f over [0, 1]
fn simpson(f: &dyn Fn(f64) -> f64) -> f64 {
    let n = 200;
    let mut s = f(0.0) + f(1.0);
    for i in 1..n {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(i as f64 / n as f64);
    }
    s / (3.0 * n as f64)
}
// grid road; tube joins x = 0 to x = 1
fn plate(n: usize, kind: char, b: f64, tube: bool) -> Vec<Vec<f64>> {
    let (hh, w) = (1.0 / n as f64, 2.0 / (1.0 + (PI / n as f64).sin()));
    let mut v = vec![vec![0.0f64; n + 1]; n + 1];
    for i in 0..=n {
        let x = PI * i as f64 * hh;
        v[i][0] = if tube { 30.0 - 30.0 * (2.0 * x).cos() } else { 60.0 * x.sin() };
    }
    let last = if kind == 'N' || kind == 'R' { n } else { n - 1 };
    let first = if tube { 0 } else { 1 };
    loop {
        let mut big = 0.0f64;
        for i in first..n {
            let (l, r) = if tube { ((i + n - 1) % n, (i + 1) % n) } else { (i - 1, i + 1) };
            for j in 1..=last {
                let new = if j < n {
                    (v[l][j] + v[r][j] + v[i][j - 1] + v[i][j + 1]) / 4.0
                } else {
                    (v[l][j] + v[r][j] + 2.0 * v[i][j - 1]) / (4.0 + 2.0 * hh * if kind == 'R' { b } else { 0.0 })
                };
                let dv = w * (new - v[i][j]);
                v[i][j] += dv;
                big = big.max(dv.abs());
            }
        }
        if big < 1e-13 { return v; }
    }
}
// all four edges given du/dn
fn insulated(n: usize, g_in: f64, g_out: f64, tilt: f64, sweeps: usize) -> Vec<Vec<f64>> {
    let (hh, w) = (1.0 / n as f64, 2.0 / (1.0 + (PI / n as f64).sin()));
    let mut u: Vec<Vec<f64>> = (0..=n).map(|i| vec![20.0 + tilt * i as f64 / n as f64; n + 1]).collect();
    let limit = if sweeps > 0 { sweeps } else { 1_000_000 };
    for _ in 0..limit {
        let mut big = 0.0f64;
        for i in 0..=n {
            for j in 0..=n {
                let l = if i > 0 { u[i - 1][j] } else { u[1][j] };
                let r = if i < n { u[i + 1][j] } else { u[n - 1][j] };
                let dn = if j > 0 { u[i][j - 1] } else { u[i][1] + 2.0 * hh * g_in };
                let up = if j < n { u[i][j + 1] } else { u[i][n - 1] - 2.0 * hh * g_out };
                let du = w * ((l + r + dn + up) / 4.0 - u[i][j]);
                u[i][j] += du;
                big = big.max(du.abs());
            }
        }
        if sweeps == 0 && big < 1e-12 { return u; }
    }
    u
}
fn mean(u: &Vec<Vec<f64>>) -> f64 {
    let mut s = 0.0;
    for row in u { let mut r = 0.0; for x in row { r += x; } s += r; }
    s / (u.len() * u.len()) as f64
}
fn name(kd: char) -> &'static str {
    match kd { 'D' => "held 20 C", 'N' => "insulated", _ => "air-cooled" }
}
fn tube_ex(x: f64, y: f64) -> f64 {
    30.0 * (1.0 - y) - 30.0 * (2.0 * PI * x).cos() * sh(2.0 * PI * (1.0 - y)) / sh(2.0 * PI)
}
fn px(x: f64, y: f64) -> String { format!("{:.0},{:.0}", 60.0 + 300.0 * x, 340.0 - 300.0 * y) }
fn main() {
    let b = 0.5;
    println!("plate 1 m x 1 m x 10 mm steel, k = 50 W/(m K); bottom 20 + 60 sin(pi x) C, sides 20 C");
    for kd in ['D', 'N', 'R'] {
        println!("top {:10}: centre {:.3} C, top middle {:.3} C", name(kd), 20.0 + 60.0 * yp(kd, 0.5, b), 20.0 + 60.0 * yp(kd, 1.0, b));
    }
    println!("hand: sinh pi {:.4}, cosh pi {:.4}, sinh pi/2 {:.4}, cosh pi/2 {:.4}; h/k = {:.1} per m", sh(PI), ch(PI), sh(PI / 2.0), ch(PI / 2.0), 25.0 / K);
    println!("hand: Y(1/2) held {:.5}, insulated {:.5}, air-cooled {:.4}/{:.4} = {:.5}", yp('D', 0.5, b), yp('N', 0.5, b),
        PI * ch(PI / 2.0) + 0.5 * sh(PI / 2.0), PI * ch(PI) + 0.5 * sh(PI), yp('R', 0.5, b));
    println!("hand: heat in, held 60 coth pi = {:.4} W, insulated 60 tanh pi = {:.4} W", 60.0 * ch(PI) / sh(PI), 60.0 * sh(PI) / ch(PI));
    println!("road two, grid centre at h = 0.1 0.05 0.025 m, and error ratios:");
    for kd in ['D', 'N', 'R'] {
        let ex = 60.0 * yp(kd, 0.5, b);
        let e: Vec<f64> = [10usize, 20, 40].iter().map(|&n| (plate(n, kd, b, false)[n / 2][n / 2] - ex).abs()).collect();
        println!("  {:10}: errors {:.5} {:.5} {:.5} K, ratios {:.2} {:.2}", name(kd), e[0], e[1], e[2], e[0] / e[1], e[1] / e[2]);
        assert!(e[2] < 0.02 && 3.6 < e[0] / e[1] && e[0] / e[1] < 4.4 && 3.6 < e[1] / e[2] && e[1] / e[2] < 4.4);
    }
    let s = simpson(&|x: f64| (PI * x).sin()); // 2/pi, by Simpson
    println!("road three, heat budget in W: in at bottom = out through sides + out at top");
    for kd in ['D', 'N', 'R'] {
        let pin = K * D * 60.0 * -dyp(kd, 0.0, b) * s;
        let side = 2.0 * K * D * 60.0 * PI * simpson(&|y: f64| yp(kd, y, b));
        let top = K * D * 60.0 * -dyp(kd, 1.0, b) * s;
        println!("  {:10}: {:.4} = {:.4} + {:.4}", name(kd), pin, side, top);
        assert!((pin - side - top).abs() < 1e-8);
    }
    let e = 1e-4;
    for kd in ['D', 'N', 'R'] {
        // the top condition, by centred differences
        let slope = (yp(kd, 1.0 + e, b) - yp(kd, 1.0 - e, b)) / (2.0 * e);
        let res = match kd { 'D' => yp(kd, 1.0, b), 'N' => slope, _ => slope + 0.5 * yp(kd, 1.0, b) };
        assert!(res.abs() < 1e-7);
    }
    let sweep: Vec<String> = [0.0, 25.0, 250.0, 2500.0].iter().map(|hv| format!("{:.3}", 20.0 + 60.0 * yp('R', 1.0, hv / K))).collect();
    println!("Robin top middle, h = 0 25 250 2500 W/(m^2 K) and held: {} 20.000 C", sweep.join(" "));
    assert!((yp('R', 1.0, 0.0) - yp('N', 1.0, b)).abs() < 1e-12 && (yp('R', 0.5, 1e9) - yp('D', 0.5, b)).abs() < 1e-8);
    for kd in ['D', 'N', 'R'] {
        let pts: Vec<String> = (0..11).map(|j| format!("{:.2}", 20.0 + 60.0 * yp(kd, j as f64 / 10.0, b))).collect();
        println!("chart, {:10} {}", name(kd), pts.join(" "));
    }
    let vt = plate(40, 'D', b, true);
    println!("tube (periodic seam): opposite seam {:.3} C, on seam {:.3} C; grid h = 0.025 m: {:.3} {:.3} C",
        20.0 + tube_ex(0.5, 0.5), 20.0 + tube_ex(0.0, 0.5), 20.0 + vt[20][20], 20.0 + vt[0][20]);
    assert!((vt[20][20] - tube_ex(0.5, 0.5)).abs() < 0.02 && (vt[0][20] - tube_ex(0.0, 0.5)).abs() < 0.02);
    let flow = |y: f64| K * D * simpson(&|x: f64| -(tube_ex(x, y + e) - tube_ex(x, y - e)) / (2.0 * e));
    println!("  tube budget: in {:.3} W at bottom, out {:.3} W at top, nothing at the seam", flow(0.0), flow(1.0));
    assert!((flow(0.0) - 15.0).abs() < 1e-5 && (flow(1.0) - 15.0).abs() < 1e-5);
    let (q, g) = (60.0 / (1.0 * D), 60.0 / (1.0 * D) / K); // W/m^2 of edge face, and K/m
    println!("insulated plate fed 60 W at bottom, drained at top: {:.0} W/m^2 of edge face, gradient {:.0} K/m", q, g);
    let ua = insulated(10, g, g, 0.0, 0);
    let ub = insulated(10, g, g, 500.0, 0);
    let mut diff = Vec::new();
    for i in 0..11 { for j in 0..11 { diff.push(ub[i][j] - ua[i][j]); } }
    let (mx, mn) = diff.iter().fold((f64::MIN, f64::MAX), |(a, c), &x| (a.max(x), c.min(x)));
    println!("  drained 60 W: compatible; starts flat and tilted settle at centre {:.3} and {:.3} C, apart by {:.3} K at every point",
        ua[5][5], ub[5][5], diff[0]);
    assert!(mx - mn < 1e-8 && (ua[5][5] - ua[5][10] - 0.5 * g).abs() < 1e-8);
    let m: Vec<f64> = [1000usize, 2000, 4000].iter().map(|&s| mean(&insulated(10, g, 100.0, 0.0, s))).collect();
    println!("  drained 50 W: incompatible; grid mean after 1000 2000 4000 sweeps {:.1} {:.1} {:.1} C", m[0], m[1], m[2]);
    assert!(m[2] - m[1] > 1.5 * (m[1] - m[0]) && m[1] - m[0] > 0.0);
    let heat = RHO * C * D; // J per K per m^2 of plate
    println!("  real plate: 10 W surplus warms it {:.3} K/h; all edges insulated, 60 W in: {:.3} K/h; diffusivity k/(rho c) {:.2}e-5 m^2/s", 10.0 / heat * 3600.0, 60.0 / heat * 3600.0, K / (RHO * C) * 1e5);
    println!("mistake, Robin sign flipped: top middle {:.3} C, above insulated {:.3} C", 20.0 + 60.0 * yp('R', 1.0, -0.5), 20.0 + 60.0 * yp('N', 1.0, b));
    println!("mistake, du/dn = u_y on the bottom too: edges sum to {:.0} K, books {:.0} W leaving, cooling {:.3} K/h",
        -g - g, 2.0 * q * D, 120.0 / heat * 3600.0);
    println!("try, plate 20 mm thick, top held: same {:.3} C centre, heat in {:.2} W", 20.0 + 60.0 * yp('D', 0.5, b), 2.0 * K * D * 60.0 * -dyp('D', 0.0, b) * s);
    println!("figure, corners {} {} centre {} normal tips {} {} {} {}", px(0.0, 0.0), px(1.0, 1.0), px(0.5, 0.5),
        px(0.5, -0.12), px(0.5, 1.12), px(-0.12, 0.5), px(1.12, 0.5));
    println!("ALL CHECKS PASS");
}
