// Wiener's Tauberian theorem -- the check behind the card.  Rust std only, no crates.
// The pulse f(t) = exp(-|t|), t in s, has transform 2/(1 + 4 pi^2 xi^2), xi in Hz,
// never 0, so sums of its shifts reach the 1-second gate.  The odd pulse
// p(t) = t exp(-t^2) has transform 0 at 0 Hz, so its sums never come closer than
// 1 V*s.  Roads: closed forms against Simpson's rule at two steps, exact weight sums
// against areas, least-squares fits checked by their normal equations and squared
// errors, and the Tauberian readings.  Every cut-off prints its tail bound.
use std::f64::consts::PI;

fn f(t: f64) -> f64 { (-t.abs()).exp() }
fn p(t: f64) -> f64 { t * (-t * t).exp() }
fn gate(t: f64) -> f64 { if t.abs() < 0.5 { 1.0 } else if t.abs() == 0.5 { 0.5 } else { 0.0 } }
fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    let h = (b - a) / n as f64;
    let mut s = 0.0;
    for i in 1..n { s += (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h); }
    (g(a) + g(b) + s) * h / 3.0
}
fn pieces(g: &dyn Fn(f64) -> f64, cuts: &[f64], n: usize) -> f64 { let mut s = 0.0; for w in cuts.windows(2) { s += simpson(g, w[0], w[1], n); } s }
fn z(v: f64, d: usize) -> String {         // fixed decimals, never "-0.00"
    let s = format!("{:.*}", d, v);
    if s.trim_start_matches('-').chars().all(|c| c == '0' || c == '.') { s.trim_start_matches('-').to_string() } else { s }
}
fn l1(fun: &dyn Fn(f64) -> f64, cuts: &[f64], n: usize) -> f64 {   // area between F and the gate
    let mut out = 0.0;
    for w in cuts.windows(2) {
        let (a, b) = (w[0], w[1]);
        let c = gate((a + b) / 2.0);
        let d = |t: f64| fun(t) - c;
        let mut pts = vec![a];
        for k in 1..41 {
            let (mut u, mut v) = (a + (b - a) * (k - 1) as f64 / 40.0, a + (b - a) * k as f64 / 40.0);
            if d(u) * d(v) < 0.0 {
                for _ in 0..60 {
                    let m = (u + v) / 2.0;
                    if d(u) * d(m) <= 0.0 { v = m } else { u = m }
                }
                pts.push((u + v) / 2.0);
            }
        }
        pts.push(b);
        for q in pts.windows(2) { out += simpson(&|t| d(t).abs(), q[0], q[1], n); }
    }
    out
}
fn weights(n: i64) -> Vec<(f64, f64)> {   // shifts at s = j h, h = 1/N: (h/2)(g_j - second difference)
    let h = 1.0 / n as f64;
    let g = |j: i64| gate(j as f64 * h);
    (-n / 2 - 1..n / 2 + 2).map(|j| (j as f64 * h, h / 2.0 * ((1.0 + 2.0 / h / h) * g(j) - (g(j - 1) + g(j + 1)) / h / h))).collect()
}
fn sum_at(t: f64, w: &[(f64, f64)]) -> f64 { let mut s = 0.0; for &(a, c) in w { s += c * f(t - a); } s }
fn cuts_of(w: &[(f64, f64)]) -> Vec<f64> {   // cut off at +-30 s
    [-30.0, -10.0, -3.0].into_iter().chain(w.iter().map(|x| x.0)).chain([3.0, 10.0, 30.0]).collect()
}
fn l1_gap(w: &[(f64, f64)], n: usize) -> f64 { l1(&|t| sum_at(t, w), &cuts_of(w), n) }
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> {   // Gaussian elimination, partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| { let mut r = a[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut r = c; for k in c + 1..n { if m[k][c].abs() > m[r][c].abs() { r = k; } }
        m.swap(c, r);
        for r in c + 1..n { let q = m[r][c] / m[c][c]; for k in c..n + 1 { m[r][k] -= q * m[c][k]; } }
    }
    let mut x = vec![0.0; n];
    for c in (0..n).rev() {
        let mut s = 0.0; for k in c + 1..n { s += m[c][k] * x[k]; }
        x[c] = (m[c][n] - s) / m[c][c];
    }
    x
}
fn read_exp(x: f64, y: &dyn Fn(f64) -> f64, n: usize) -> f64 {   // exp kernel cut off at +-30 s
    simpson(&|s| f(s) / 2.0 * y(x - s), -30.0, 0.0, n) + simpson(&|s| f(s) / 2.0 * y(x - s), 0.0, 30.0, n) }
fn join(v: &[f64], d: usize) -> String { v.iter().map(|&x| z(x, d)).collect::<Vec<_>>().join(" ") }

fn main() {
    println!("transforms, closed form against Simpson on [-40, 40] s (tail below 2e-17):");
    for xi in [0.0, 0.5, 1.0] {
        let num = 2.0 * simpson(&|t| f(t) * (2.0 * PI * xi * t).cos(), 0.0, 40.0, 40000);
        let cl = 2.0 / (1.0 + 4.0 * PI * PI * xi * xi);
        println!("  f-hat({:.2} Hz) closed {:.6}  Simpson {:.6}  1/f-hat {:.6}", xi, cl, num, (1.0 + 4.0 * PI * PI * xi * xi) / 2.0);
        assert!((num - cl).abs() < 1e-9);
    }
    let pn = -simpson(&|t| p(t) * (2.0 * PI * 0.25 * t).sin(), -10.0, 10.0, 20000);
    let pc = PI.powf(1.5) * 0.25 * (-PI * PI / 16.0).exp();
    println!("  p-hat(0.25 Hz) closed -i {:.6}  Simpson -i {:.6} on [-10, 10] s, tail <= e^-100 = {:.1e}", pc, -pn, (-100.0f64).exp());
    assert!((-pn - pc).abs() < 1e-9);
    let xs: Vec<f64> = (0..9).map(|k| 0.25 * k as f64).collect();
    println!("chart xi: {}", join(&xs, 2));
    println!("chart f-hat: {}", join(&xs.iter().map(|&x| 2.0 / (1.0 + 4.0 * PI * PI * x * x)).collect::<Vec<_>>(), 3));
    println!("chart gate-hat: {}", join(&xs.iter().map(|&x| if x != 0.0 { (PI * x).sin() / (PI * x) } else { 1.0 }).collect::<Vec<_>>(), 3));
    println!("chart |p-hat|: {}", join(&xs.iter().map(|&x| PI.powf(1.5) * x * (-PI * PI * x * x).exp()).collect::<Vec<_>>(), 3));

    let w = weights(2);
    println!("N = 2, h = 0.5 s: weights {}", w.iter().map(|&(s, c)| format!("{:+.1}:{:.6}", s, c)).collect::<Vec<_>>().join(" "));
    println!("  sum at 0 s {:.6}  at 1 s {:.6}  using {}", sum_at(0.0, &w), sum_at(1.0, &w),
        [0.5f64, 1.0, 1.5, 2.0].iter().map(|&u| format!("e^-{:.1} {:.6}", u, (-u).exp())).collect::<Vec<_>>().join(" "));
    println!("N | shifts | sum of weights | sum of |weights| | L1 gap to gate V*s | gap x N | area of sum | largest gap at 0.5 s -+ 1e-9 s | tail beyond +-30 s");
    let mut prev = 9.0;
    for n in [2i64, 4, 8, 16, 32, 64] {
        let w = weights(n);
        let (e1, e2) = (l1_gap(&w, 200), l1_gap(&w, 400));
        let area = pieces(&|t| sum_at(t, &w), &cuts_of(&w), 400);
        let (mut sw, mut sa, en) = (0.0, 0.0, e2 * n as f64);
        for &(_, c) in &w { sw += c; sa += c.abs(); }
        let peak = [0.5 - 1e-9, 0.5 + 1e-9].iter().map(|&t| (sum_at(t, &w) - gate(t)).abs()).fold(0.0, f64::max);
        let tail = 2.0 * sa * (-(29.5 - 1.0 / n as f64)).exp();   // |sum| <= sa e^-(|t| - 0.5 - 1/N)
        println!("  {:2} | {:2} | {:.6} | {:.6} | {:.6} | {:.4} | {:.6} | {:.6} | {:.1e}", n, w.len(), sw, sa, e2, en, area, peak, tail);
        assert!((e1 - e2).abs() < 1e-7 && e2 < prev / 1.9 && 0.9 < en && en < 1.1 && peak >= 0.5);
        assert!((area - 2.0 * sw).abs() < 1e-8 && (area - 1.0).abs() < 1e-8);
        assert!(tail < 1e-10);
        prev = e2;
    }
    let ts: Vec<f64> = (0..17).map(|k| ((-1.2 + 0.15 * k as f64) * 100.0).round() / 100.0).collect();
    println!("chart t: {}", join(&ts, 2));
    println!("chart gate: {}", join(&ts.iter().map(|&t| gate(t)).collect::<Vec<_>>(), 2));
    for n in [4i64, 16] {
        let w = weights(n);
        println!("chart sum N={}: {}", n, join(&ts.iter().map(|&t| sum_at(t, &w)).collect::<Vec<_>>(), 2));
    }

    let floor = 1.0;   // |gate-hat(0) - mix-hat(0)| = 1 for every mix of odd pulses
    println!("odd pulse t exp(-t^2): least-squares sums of shifts at spacing 0.5 s on [-R, R], cut at +-(R + 6) s, floor {:.6} V*s", floor);
    println!("R s | shifts | max |G c - rhs| | squared error: closed, Simpson | area of right half | L1 gap to gate V*s | gap / floor | tail");
    for r in [1i64, 2, 4, 8] {
        let ss: Vec<f64> = (-2 * r..2 * r + 1).map(|j| 0.5 * j as f64).collect();
        let g: Vec<Vec<f64>> = ss.iter().map(|&a| ss.iter().map(|&b| (-(a - b) * (a - b) / 2.0).exp() * (PI / 2.0).sqrt() * (1.0 - (a - b) * (a - b)) / 4.0).collect()).collect();
        let rhs: Vec<f64> = ss.iter().map(|&a| ((-(0.5 + a) * (0.5 + a)).exp() - (-(0.5 - a) * (0.5 - a)).exp()) / 2.0).collect();
        let c = solve(&g, &rhs);
        let mut res: f64 = 0.0;
        for i in 0..ss.len() { let mut s = 0.0; for k in 0..ss.len() { s += g[i][k] * c[k]; } res = res.max((s - rhs[i]).abs()); }
        let hh = |t: f64| { let mut s = 0.0; for (ci, a) in c.iter().zip(ss.iter()) { s += ci * p(t - a); } s };
        let half = |t: f64| { let mut s = 0.0; for (ci, a) in c.iter().zip(ss.iter()) { if *a > 0.0 { s += ci * p(t - a); } } s };
        let cuts: Vec<f64> = (-2 * r - 12..2 * r + 13).map(|k| 0.5 * k as f64).collect();
        let (mut cr, mut sc, mut e2s) = (0.0, 0.0, 0.0);
        for (ci, ri) in c.iter().zip(rhs.iter()) { cr += ci * ri; sc += ci.abs(); }
        for w in cuts.windows(2) { let g0 = gate((w[0] + w[1]) / 2.0); e2s += simpson(&|t| { let d = hh(t) - g0; d * d }, w[0], w[1], 200); }
        let (e2c, g1, g2, ah, tail) = (1.0 - cr, l1(&hh, &cuts, 200), l1(&hh, &cuts, 400), pieces(&half, &cuts, 200), sc * (-36.0f64).exp());
        println!("  {} | {:2} | {:.1e} | {:.6} {:.6} | {:.6} | {:.6} | {:.4} | {:.1e}", r, ss.len(), res, e2c, e2s, ah.abs(), g2, g2 / floor, tail);
        assert!(res < 1e-12 && (e2c - e2s).abs() < 1e-9 && ah.abs() < 1e-9 && (g1 - g2).abs() < 1e-7 && g2 >= floor);
    }
    let b: Vec<(f64, f64)> = weights(64).iter().map(|&(s, _)| (s, gate(s) / 128.0)).collect();
    let blur = l1_gap(&b, 400);
    println!("what breaks: plain blur, no second difference, N = 64: L1 gap {:.6}  limit 2(1 - 1/e) {:.6}  tail beyond +-30 s <= {:.1e}", blur, 2.0 * (1.0 - (-1.0f64).exp()),
        2.0 * b.iter().fold(0.0, |s, x| s + x.1) * (-(29.5 - 1.0 / 64.0f64)).exp());
    assert!((blur - 2.0 * (1.0 - (-1.0f64).exp())).abs() < 1e-3 && (blur - l1_gap(&b, 200)).abs() < 1e-7);

    let y = |t: f64| 1.0 + (t * t).cos();
    println!("cut-offs, |y| <= 2: exp kernel at +-30 s, tail <= 2 e^-30 = {:.1e}; odd pulse at +-8 s, tail <= 2 e^-64 = {:.1e}", 2.0 * (-30.0f64).exp(), 2.0 * (-64.0f64).exp());
    println!("Tauberian readings of y(t) = 1 + cos(t^2) V, each at two steps: x s | exp kernel | 1-s gate | odd pulse");
    let mut last = [1.0, 1.0];
    for x in [5.0, 10.0, 20.0, 40.0] {
        let (r1, r2) = (read_exp(x, &y, 30000), read_exp(x, &y, 60000));
        let (rg, rg2) = (simpson(&|s| y(x - s), -0.5, 0.5, 4000), simpson(&|s| y(x - s), -0.5, 0.5, 8000));
        let (ro, ro2) = (simpson(&|s| p(s) * y(x - s), -8.0, 8.0, 16000), simpson(&|s| p(s) * y(x - s), -8.0, 8.0, 32000));
        println!("  {:2} | {:.6} | {:.6} | {:.6}", x as i64, r2, rg2, ro2.abs());
        assert!((r1 - r2).abs() < 1e-8 && (rg - rg2).abs() < 1e-9 && (ro - ro2).abs() < 1e-9 && ro2.abs() < 1e-4);
        last = [(r2 - 1.0).abs(), (rg2 - 1.0).abs()];
    }
    assert!(last[0] < 1e-3 && last[1] < 0.01);
    let hum = |t: f64| 1.0 + (2.0 * PI * t).cos();
    println!("what breaks: gate as the starting kernel, y(t) = 1 + cos(2 pi t) V");
    for x in [10.0, 10.25, 10.5] {
        let (rg, re) = (simpson(&|s| hum(x - s), -0.5, 0.5, 4000), read_exp(x, &hum, 30000));
        let fm = 1.0 + (2.0 * PI * x).cos() / (1.0 + 4.0 * PI * PI);
        println!("  x {:5.2} s: gate {:.6}  exp kernel {:.6}  formula 1 + cos(2 pi x)/(1 + 4 pi^2) {:.6}", x, rg, re, fm);
        assert!((rg - 1.0).abs() < 1e-9 && (re - fm).abs() < 1e-9);
    }
    println!("ALL CHECKS PASS");
}
