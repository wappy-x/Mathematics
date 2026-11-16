// Weak solutions: the tent-shaped sheet, a kinked rope pulse and a Burgers shock.
// Rust std only. Simpson's rule, the bumps and the grid solve are written out here.
const T: f64 = 200.0; const A: f64 = 0.5; const H: f64 = 0.05; // tension N/m, half-side m (1 m square), apex m
const SL: f64 = H / A; const E: f64 = std::f64::consts::E; // SL: slope of each face

fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, n: usize) -> f64 {
    if hi <= lo { return 0.0; }
    let d = (hi - lo) / n as f64;
    let mut s = f(lo) + f(hi);
    for i in 1..n {
        s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * f(lo + i as f64 * d);
    }
    s * d / 3.0
}
fn z(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } } // print a rounding-level number as 0
fn tent(x: f64, y: f64) -> f64 { H * (1.0 - x.abs().max(y.abs()) / A) } // the sheet's height, m
fn v2(cx: f64, cy: f64, r: f64, x: f64, y: f64) -> f64 {
    let p2 = ((x - cx).powf(2.0) + (y - cy).powf(2.0)) / r.powf(2.0);
    if p2 < 1.0 { E * (-1.0 / (1.0 - p2)).exp() } else { 0.0 }
}
fn grad2(cx: f64, cy: f64, r: f64, x: f64, y: f64) -> (f64, f64) {
    let p2 = ((x - cx).powf(2.0) + (y - cy).powf(2.0)) / r.powf(2.0);
    if p2 >= 1.0 { return (0.0, 0.0); }
    let g = v2(cx, cy, r, x, y) * -2.0 / (1.0 - p2).powf(2.0) / r.powf(2.0);
    (g * (x - cx), g * (y - cy))
}
fn pt(face: usize, s: f64, t: f64) -> (f64, f64) {
    match face { 0 => (s, t), 1 => (-s, t), 2 => (t, s), _ => (t, -s) }
}
// road 1: a(u, v) = T * integral of grad u . grad v, face by face, iterated Simpson
fn a_form(c: (f64, f64, f64)) -> f64 {
    let (cx, cy, r) = c;
    let bx = [cx - r, cx + r, cy - r, cy + r];
    let faces = [((-SL, 0.0), 0, 1.0), ((SL, 0.0), 0, -1.0), ((0.0, -SL), 2, 1.0), ((0.0, SL), 2, -1.0)];
    let mut total = 0.0;
    for (fi, &((gx, gy), k, sg)) in faces.iter().enumerate() {
        let (p, q) = (sg * bx[k], sg * bx[k + 1]);
        let (lo, hi) = if p <= q { (p, q) } else { (q, p) };
        let (tlo, thi) = (bx[2 - k], bx[3 - k]);
        let inner = |s: f64| {
            let f = |t: f64| {
                let (x, y) = pt(fi, s, t);
                gx * grad2(cx, cy, r, x, y).0 + gy * grad2(cx, cy, r, x, y).1
            };
            simpson(&f, (-s).max(tlo), s.min(thi), 200)
        };
        total += T * simpson(&inner, lo.max(0.0), hi.min(A), 400);
    }
    total
}
// road 2: l(v) = Q * integral of v along both rods (the diagonals)
fn l_form(q: f64, v: &dyn Fn(f64, f64) -> f64) -> f64 {
    let r2 = 2f64.sqrt();
    let l = 2.0 * r2 * A;
    let d1 = simpson(&|s: f64| v(-A + s / r2, -A + s / r2), 0.0, l, 800);
    let d2 = simpson(&|s: f64| v(-A + s / r2, A - s / r2), 0.0, l, 800);
    q * (d1 + d2)
}
fn b(s: f64) -> f64 { if s.abs() < 1.0 { E * (-1.0 / (1.0 - s * s)).exp() } else { 0.0 } }
fn b1(s: f64) -> f64 { if s.abs() < 1.0 { b(s) * -2.0 * s / (1.0 - s * s).powf(2.0) } else { 0.0 } }
fn b2(s: f64) -> f64 {
    if s.abs() >= 1.0 { return 0.0; }
    let w = 1.0 - s * s;
    b(s) * ((-2.0 * s / w.powf(2.0)).powf(2.0) - 2.0 / w.powf(2.0) - 8.0 * s * s / w.powf(3.0))
}
// wave: a tent pulse on a rope, u = F(x - ct); very weak form: integral of u (v_tt - c^2 v_xx) = 0
const C: f64 = 10.0; const HW: f64 = 0.02; const W: f64 = 0.2;
const X0: f64 = 0.5; const RX: f64 = 0.4; const T0: f64 = 0.05; const RT: f64 = 0.04;
fn wave_res(speed: f64) -> f64 {
    let inner = |t: f64| {
        let f = |x: f64| {
            let fu = HW * (1.0 - (x - speed * t).abs() / W).max(0.0);
            fu * (b((x - X0) / RX) * b2((t - T0) / RT) / RT.powf(2.0)
                - C.powf(2.0) * b2((x - X0) / RX) / RX.powf(2.0) * b((t - T0) / RT))
        };
        let mut cuts = vec![X0 - RX, X0 + RX];
        for k in [-1.0, 0.0, 1.0] {
            cuts.push((speed * t + k * W).max(X0 - RX).min(X0 + RX));
        }
        cuts.sort_by(|p, q| p.partial_cmp(q).unwrap());
        (0..4).map(|k| simpson(&f, cuts[k], cuts[k + 1], 200)).sum::<f64>()
    };
    simpson(&inner, T0 - RT, T0 + RT, 400)
}
// Burgers u_t + (u^2/2)_x = 0 (scaled): a jump from 1 to 0 moving at speed s
const P0: f64 = 0.5; const RP: f64 = 0.4; const S0: f64 = 1.0; const RS: f64 = 0.5;
fn burgers_res(s: f64, left: bool) -> f64 {
    let inner = |t: f64| {
        let g = |x: f64| b((x - P0) / RP) * b1((t - S0) / RS) / RS + 0.5 * b1((x - P0) / RP) / RP * b((t - S0) / RS);
        let k = (s * t).max(P0 - RP).min(P0 + RP);
        if left { simpson(&g, P0 - RP, k, 200) } else { simpson(&g, k, P0 + RP, 200) }
    };
    simpson(&inner, S0 - RS, S0 + RS, 400)
}
fn rh(s: f64) -> f64 {
    (0.5 - s) * simpson(&|t: f64| b((s * t - P0) / RP) * b((t - S0) / RS), S0 - RS, S0 + RS, 400)
}
fn main() {
    let r2 = 2f64.sqrt();
    let q = r2 * T * SL; // load per metre of rod, N/m (Step 3)
    println!("sheet: 1 m square, T = {:.0} N/m, apex {:.0} cm, face slope {:.2}, rod load q = {:.4} N/m", T, H * 100.0, SL, q);
    println!("hand: slope jump across a rod {:.6}, rod length 2 x {:.4} m, area under the rods {:.6} m^2", r2 * SL, 2.0 * r2 * A, 2.0 * r2 * A * H);
    println!("total lift: rods q x {:.4} m = {:.4} N; frame T x slope x {:.0} m = {:.4} N", 4.0 * r2 * A, q * 4.0 * r2 * A, 8.0 * A, T * SL * 8.0 * A);
    assert!((q * 4.0 * r2 * A - T * SL * 8.0 * A).abs() < 1e-9); // force balance: the rods lift what the frame pulls down
    let mut rows = vec![];
    for (name, c) in [("A apex", (0.0, 0.0, 0.3)), ("B on a rod", (0.25, 0.25, 0.15)), ("C inside a face", (0.3, 0.0, 0.1))] {
        let (av, lv) = (a_form(c), l_form(q, &|x, y| v2(c.0, c.1, c.2, x, y)));
        rows.push((av, lv));
        println!("bump {:<16} centre ({:.2}, {:.2}) m r {:.2} m: a(u,v) = {:8.4} N, l(v) = {:8.4} N", name, c.0, c.1, c.2, z(av), z(lv));
    }
    assert!(rows.iter().all(|&(av, lv)| (av - lv).abs() < 1e-6)); // the tent solves the weak form
    assert!(rows[0].0.abs() > 1.0 && rows[2].0.abs() < 1e-9); // free sheet (f = 0) fails bump A only
    let au = T * SL.powf(2.0) * (2.0 * A).powf(2.0); // v = u itself, an H^1_0 test
    let lu = 2.0 * q * simpson(&|s: f64| tent(-A + s / r2, -A + s / r2), 0.0, 2.0 * r2 * A, 800);
    println!("test with v = u: a(u,u) = {:.4} J, l(u) = {:.4} J; stored energy {:.4} J; slope integral {:.4} m^2", au, lu, au / 2.0, au / T);
    assert!((au - lu).abs() < 1e-9);
    for d in [0.01, 0.001, 0.0001] {
        let (x, y) = (0.25, 0.25);
        let lap = (tent(x + d, y) + tent(x - d, y) + tent(x, y + d) + tent(x, y - d) - 4.0 * tent(x, y)) / d.powf(2.0);
        let lap2 = (tent(0.3 + d, 0.0) + tent(0.3 - d, 0.0) + tent(0.3, d) + tent(0.3, -d) - 4.0 * tent(0.3, 0.0)) / d.powf(2.0);
        println!("step {:.4} m: -T x Laplacian on a rod {:10.1} N/m^2, inside a face {:.1} N/m^2", d, -T * lap, (T * lap2).abs());
        assert!((-T * lap - 2.0 * T * H / (A * d)).abs() < 1e-6 * T / d);
    }
    // road 3: relax the free sheet between the rods on a grid; it settles into the tent's flat faces
    let n = 20usize;
    let dx = 2.0 * A / n as f64;
    let mut u = vec![vec![0.0f64; n + 1]; n + 1];
    let fixed = |i: usize, j: usize| i == 0 || i == n || j == 0 || j == n || i == j || i + j == n;
    for i in 0..=n {
        let h = tent(-A + i as f64 * dx, -A + i as f64 * dx);
        u[i][i] = h;
        u[i][n - i] = h;
    }
    for _ in 0..5000 {
        let mut ch: f64 = 0.0;
        for i in 1..n {
            for j in (1..n).filter(|&j| !fixed(i, j)) {
                let new = (u[i - 1][j] + u[i + 1][j] + u[i][j - 1] + u[i][j + 1]) / 4.0;
                ch = ch.max((new - u[i][j]).abs());
                u[i][j] = new;
            }
        }
        if ch < 1e-15 { break; }
    }
    let gap = (0..=n * n + 2 * n).map(|m| (m / (n + 1), m % (n + 1)))
        .map(|(i, j)| (u[i][j] - tent(-A + i as f64 * dx, -A + j as f64 * dx)).abs()).fold(0.0, f64::max);
    println!("grid {}x{}, step {:.2} m: relaxed sheet vs tent, largest gap {:.6} mm", n, n, dx, gap * 1000.0);
    assert!(gap < 1e-9);
    let xs: Vec<String> = (0..9).map(|k| format!("{:.3}", -A + k as f64 * 0.125)).collect();
    println!("chart x (m): {}", xs.join(", "));
    for (lab, y) in [("0", 0.0), ("0.25", 0.25)] {
        let pts: Vec<String> = (0..9).map(|k| format!("{:.2}", 100.0 * tent(-A + k as f64 * 0.125, y))).collect();
        println!("chart y={} (cm): {}", lab, pts.join(", "));
    }
    println!("breaks: slope jump along x gives q = {:.4} N/m, total {:.4} N; v = 1: a = 0, l = {:.4} N", T * SL, T * SL * 4.0 * r2 * A, q * 4.0 * r2 * A);
    let (rw, rw12) = (wave_res(10.0), wave_res(12.0));
    println!("wave c = 10 m/s, tent pulse {:.0} cm high, {:.1} m half-width: kinked pulse at 10 m/s residual {:.6} m^2/s; at 12 m/s {:.6} m^2/s", HW * 100.0, W, z(rw), rw12);
    assert!(rw.abs() < 1e-8 && rw12.abs() > 1e-4);
    for s in [0.5, 1.0] {
        println!("Burgers jump 1 -> 0 at speed {:.1}: residual {:.6}, Rankine-Hugoniot road {:.6}", s, z(burgers_res(s, true)), z(rh(s)));
        assert!((burgers_res(s, true) - rh(s)).abs() < 1e-6);
    }
    println!("Burgers jump 0 -> 1 at speed 0.5: residual {:.6} (also weak; entropy rules it out)", z(burgers_res(0.5, false)));
    assert!(rh(1.0).abs() > 0.01 && burgers_res(0.5, false).abs() < 1e-6);
    println!("ALL CHECKS PASS");
}
