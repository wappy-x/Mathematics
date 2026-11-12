// Two-point boundary problems: shooting, finite differences and collocation -- the check behind the card.
// Rust std only. A cable hangs between towers 30 m and 40 m high, 100 m apart (illustrative):
// y'' = sqrt(1 + y'^2) / a with a = H / w = 4000 N / (20 N/m) = 200 m. Every solver is written out.
use std::f64::consts::PI;
fn sci(x: f64, d: usize) -> String { format!("{:.*e}", d, x) }
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut t = 0.0; for (p, q) in u.iter().zip(v) { t += p * q; } t }
fn asinh(v: f64) -> f64 { (v + (v * v + 1.0).sqrt()).ln() }
const L: f64 = 100.0; const YA: f64 = 30.0; const YB: f64 = 40.0; const A: f64 = 200.0;
struct Eq { f: Box<dyn Fn(f64, f64, f64) -> f64>, fy: Box<dyn Fn(f64, f64, f64) -> f64>, fp: Box<dyn Fn(f64, f64, f64) -> f64> }
fn cat() -> Eq {                                   // F, dF/dy, dF/dp
    Eq { f: Box::new(|_, _, p| (1.0 + p * p).sqrt() / A), fy: Box::new(|_, _, _| 0.0),
         fp: Box::new(|_, _, p| p / (A * (1.0 + p * p).sqrt())) }
}
struct Ex { x0: f64, c0: f64 }
impl Ex { fn y(&self, x: f64) -> f64 { A * ((x - self.x0) / A).cosh() + self.c0 } }

// road 2: RK4 on (y, y', dy/ds, dy'/ds), Newton on the start slope s
fn shoot(eq: &Eq, a: f64, b: f64, ya: f64, yb: f64, s0: f64, n: usize, log: Option<&mut Vec<f64>>) -> (f64, f64, f64, usize, f64) {
    let h = (b - a) / n as f64; let mut s = s0; let (mut mid, mut g, mut z, mut shots) = (0.0, 0.0, 0.0, 0);
    let rhs = |x: f64, u: &[f64; 4]| -> [f64; 4] {
        [u[1], (eq.f)(x, u[0], u[1]), u[3], (eq.fy)(x, u[0], u[1]) * u[2] + (eq.fp)(x, u[0], u[1]) * u[3]] };
    let mut log = log;
    for it in 0..20 {
        let mut u = [ya, s, 0.0, 1.0];
        for i in 0..n {
            let x = a + i as f64 * h; let k1 = rhs(x, &u);
            let k2 = rhs(x + h / 2.0, &std::array::from_fn(|j| u[j] + h / 2.0 * k1[j]));
            let k3 = rhs(x + h / 2.0, &std::array::from_fn(|j| u[j] + h / 2.0 * k2[j]));
            let k4 = rhs(x + h, &std::array::from_fn(|j| u[j] + h * k3[j]));
            u = std::array::from_fn(|j| u[j] + h / 6.0 * (k1[j] + 2.0 * k2[j] + 2.0 * k3[j] + k4[j]));
            if 2 * (i + 1) == n { mid = u[0]; }
        }
        g = u[0] - yb; z = u[2]; let ds = g / u[2]; shots = it + 1;
        if let Some(l) = log.as_mut() {
            l.push(g); println!("  shot {}: s = {:.9}, miss {} m, dmiss/ds = {:.4} m", it, s, sci(g, 4), u[2]);
        }
        s -= ds;
        if ds.abs() <= 1e-14 * (1.0 + s.abs()) { break; }
    }
    (s, mid, g, shots, z)
}

fn thomas(lo: &[f64], di: &[f64], up: &[f64], r: &[f64]) -> Vec<f64> {   // one sweep down, one back
    let (mut di, mut r) = (di.to_vec(), r.to_vec()); let m = di.len();
    for i in 1..m { let q = lo[i] / di[i - 1]; di[i] -= q * up[i - 1]; r[i] -= q * r[i - 1]; }
    let mut x = r.clone(); x[m - 1] = r[m - 1] / di[m - 1];
    for i in (0..m - 1).rev() { x[i] = (r[i] - up[i] * x[i + 1]) / di[i]; }
    x
}
// road 3: Newton on the grid equations
fn fd(eq: &Eq, a: f64, b: f64, ya: f64, yb: f64, n: usize, onesided: bool, noslope: bool, log: bool) -> (Vec<f64>, usize) {
    let h = (b - a) / n as f64; let mut y: Vec<f64> = (0..=n).map(|i| ya + (yb - ya) * i as f64 / n as f64).collect();
    let mut steps = 0;
    for it in 1..60 {
        steps = it; let (mut lo, mut di, mut up, mut r) = (vec![], vec![], vec![], vec![]);
        for i in 1..n {
            let x = a + i as f64 * h;
            let p = if onesided { (y[i + 1] - y[i]) / h } else { (y[i + 1] - y[i - 1]) / (2.0 * h) };
            let fp = if noslope { 0.0 } else { (eq.fp)(x, y[i], p) };
            r.push(-(y[i - 1] - 2.0 * y[i] + y[i + 1] - h * h * (eq.f)(x, y[i], p)));
            lo.push(1.0 + h * fp / 2.0); di.push(-2.0 - h * h * (eq.fy)(x, y[i], p)); up.push(1.0 - h * fp / 2.0);
        }
        let d = thomas(&lo, &di, &up, &r);
        for i in 1..n { y[i] += d[i - 1]; }
        if log && it == 1 {
            println!("  step 1: each equation misses by {:.6}; Jacobian row: lower {:.6}, diagonal {:.1}, upper {:.6}", -r[0], lo[1], di[1], up[1]);
            println!("  after step 1: y = {:.6} {:.6} {:.6}", y[1], y[2], y[3]);
        }
        if d.iter().fold(0.0f64, |m, v| m.max(v.abs())) < 1e-12 { break; }
    }
    (y, steps)
}

// road 4: one polynomial, the equation enforced at Chebyshev points
fn colloc(eq: &Eq, ex: &Ex, a: f64, b: f64, ya: f64, yb: f64, n: usize) -> (f64, usize) {
    let t: Vec<f64> = (0..=n).map(|j| (PI * j as f64 / n as f64).cos()).collect();
    let x: Vec<f64> = t.iter().map(|tj| a + (b - a) * (1.0 - tj) / 2.0).collect();
    let w: Vec<f64> = (0..=n).map(|j| (if j == 0 || j == n { 2.0 } else { 1.0 }) * (1 - 2 * (j % 2) as i64) as f64).collect();
    let mut dm: Vec<Vec<f64>> = (0..=n).map(|i| (0..=n).map(|j| if i == j { 0.0 } else { w[i] / w[j] / (t[i] - t[j]) * (-2.0 / (b - a)) }).collect()).collect();
    for i in 0..=n { dm[i][i] = -dot(&dm[i], &vec![1.0; n + 1]); }      // rows of D must kill constants
    let d2: Vec<Vec<f64>> = (0..=n).map(|i| (0..=n).map(|j| dot(&dm[i], &(0..=n).map(|k| dm[k][j]).collect::<Vec<_>>())).collect()).collect();
    let mut y: Vec<f64> = x.iter().map(|xi| ya + (yb - ya) * (xi - a) / (b - a)).collect();
    let mut steps = 0;
    for it in 1..60 {
        steps = it;
        let p: Vec<f64> = (0..=n).map(|i| dot(&dm[i], &y)).collect();
        let mut m: Vec<Vec<f64>> = (0..=n).map(|i| (0..=n).map(|j| if i == j { 1.0 } else { 0.0 }).collect()).collect();
        let mut r = vec![0.0; n + 1]; r[0] = ya - y[0]; r[n] = yb - y[n];
        for i in 1..n {
            m[i] = (0..=n).map(|j| d2[i][j] - (eq.fp)(x[i], y[i], p[i]) * dm[i][j] - if i == j { (eq.fy)(x[i], y[i], p[i]) } else { 0.0 }).collect();
            r[i] = -(dot(&d2[i], &y) - (eq.f)(x[i], y[i], p[i]));
        }
        for k in 0..=n {                           // dense elimination with partial pivoting
            let mut q = k; for i in k..=n { if m[i][k].abs() > m[q][k].abs() { q = i; } }
            m.swap(k, q); r.swap(k, q);
            for i in k + 1..=n {
                let f = m[i][k] / m[k][k]; r[i] -= f * r[k];
                for j in k..=n { m[i][j] -= f * m[k][j]; }
            }
        }
        let mut d = vec![0.0; n + 1];
        for i in (0..=n).rev() { d[i] = (r[i] - dot(&m[i][i + 1..], &d[i + 1..])) / m[i][i]; }
        for i in 0..=n { y[i] += d[i]; }
        if d.iter().fold(0.0f64, |m, v| m.max(v.abs())) < 1e-12 { break; }
    }
    ((0..=n).fold(0.0f64, |m, i| m.max((y[i] - ex.y(x[i])).abs())), steps)
}

fn main() {
    let x0 = L / 2.0 - A * asinh((YB - YA) / (2.0 * A * (L / (2.0 * A)).sinh()));   // road 1: the closed form
    let ex = Ex { x0, c0: YA - A * (x0 / A).cosh() };
    let (s_ex, mid_ex) = ((-x0 / A).sinh(), ex.y(L / 2.0));
    let cat = cat();
    println!("cable: y'' = sqrt(1 + y'^2)/a, a = 200 m; towers 30 m at x = 0 and 40 m at x = 100 m");
    println!("exact: lowest point at x = {:.6} m, height {:.6} m; midspan y(50) = {:.9} m", x0, A + ex.c0, mid_ex);
    println!("exact: start slope s = {:.9}, angle {:.4} deg", s_ex, s_ex.atan() * 180.0 / PI);
    println!("shooting, RK4 with 16 steps, Newton on the start slope from the chord slope 0.1:");
    let mut misses = vec![]; let (s16, _, _, sh16, _) = shoot(&cat, 0.0, L, YA, YB, 0.1, 16, Some(&mut misses));
    println!("  |miss_k+1| / |miss_k|^2: {}; final s = {:.12}, true error {}", (0..3).map(|k| sci(misses[k + 1].abs() / (misses[k] * misses[k]), 2)).collect::<Vec<_>>().join(", "), s16, sci(s16 - s_ex, 2));
    println!("finite differences, 4 intervals of 25 m, Newton from the straight line y = {}:", [1.0, 2.0, 3.0].iter().map(|i| format!("{:.1}", YA + (YB - YA) * i / 4.0)).collect::<Vec<_>>().join(" "));
    let (y4, it4) = fd(&cat, 0.0, L, YA, YB, 4, false, false, true);
    println!("  after {} steps: y = {:.6} {:.6} {:.6}; exact {:.6} {:.6} {:.6}", it4, y4[1], y4[2], y4[3], ex.y(25.0), ex.y(50.0), ex.y(75.0));
    println!("midspan error, m:  h (m)    shooting    centred FD  one-sided FD");
    let mut e: Vec<[f64; 3]> = vec![];
    for n in [4usize, 8, 16, 32, 64] {
        let r = [shoot(&cat, 0.0, L, YA, YB, 0.1, n, None).1 - mid_ex, fd(&cat, 0.0, L, YA, YB, n, false, false, false).0[n / 2] - mid_ex,
                 fd(&cat, 0.0, L, YA, YB, n, true, false, false).0[n / 2] - mid_ex];
        println!("  {:20.3}  {:>10}  {:>12}  {:>12}", L / n as f64, sci(r[0], 2), sci(r[1], 2), sci(r[2], 2)); e.push(r);
    }
    let order: Vec<f64> = (0..3).map(|j| (e[3][j] / e[4][j]).abs().log2()).collect();
    println!("observed order, last halving: shooting {:.2}, centred {:.2}, one-sided {:.2}", order[0], order[1], order[2]);
    let y64 = fd(&cat, 0.0, L, YA, YB, 64, false, false, false).0; let i = (1..64).fold(1, |b, j| if y64[j] < y64[b] { j } else { b });   // lowest grid height
    let (d1, d2) = (y64[i + 1] - y64[i - 1], y64[i + 1] - 2.0 * y64[i] + y64[i - 1]); let (xl, yl) = ((i as f64 - d1 / (2.0 * d2)) * L / 64.0, y64[i] - d1 * d1 / (8.0 * d2));
    println!("lowest point, 64-interval grid and a parabola through its 3 lowest heights: {:.6} m at x = {:.4} m; true errors {} m, {} m", yl, xl, sci(yl - A - ex.c0, 2), sci(xl - x0, 2));
    println!("collocation, degree n:  max nodal error, Newton steps");
    let mut c = std::collections::HashMap::new();
    for n in [4usize, 6, 8, 10, 12] {
        let r = colloc(&cat, &ex, 0.0, L, YA, YB, n); println!("  n = {:2}: {:>9}  {}", n, sci(r.0, 2), r.1); c.insert(n, r);
    }
    let (y16, it16) = fd(&cat, 0.0, L, YA, YB, 16, false, false, false); let (y16n, it16n) = fd(&cat, 0.0, L, YA, YB, 16, false, true, false);
    println!("cost at 16 intervals: shooting 1 unknown, {} shots of 64 F-calls; FD 15 unknowns, {} steps of a {}-flop Thomas sweep", sh16, it16, 8 * 15 - 7);
    println!("cost of collocation n = 8: 9 unknowns, {} steps of a {}-flop dense elimination", c[&8].1, (4 * 729 + 9 * 81 - 7 * 9) / 6);
    println!("wrong: FD Jacobian without the slope term: {} Newton steps, not {}; answer moves {} m", it16n, it16, sci(y16n[8] - y16[8], 2));
    println!("stiff bed y'' = k^2 y, y(0) = y(1) = 1, 200 steps: k, dmiss/ds (RK4 | sinh k / k), midspan exact | shooting | FD");
    let mut bb = std::collections::HashMap::new();
    for k in [10.0f64, 20.0, 30.0, 40.0] {
        let bed = Eq { f: Box::new(move |_, y, _| k * k * y), fy: Box::new(move |_, _, _| k * k), fp: Box::new(|_, _, _| 0.0) };
        let (sb, mb, gb, _, zb) = shoot(&bed, 0.0, 1.0, 1.0, 1.0, 0.0, 200, None); let yb = fd(&bed, 0.0, 1.0, 1.0, 1.0, 200, false, false, false).0[100];
        let exm = 1.0 / (k / 2.0).cosh();
        println!("  {}: {} | {}   {} | {} | {}   miss {}", k, sci(zb, 3), sci(k.sinh() / k, 3), sci(exm, 3), sci(mb, 3), sci(yb, 3), sci(gb, 2));
        bb.insert(k as i64, (zb, mb, yb, gb, sb));
    }
    let ulp = 2f64.powi(bb[&40].4.abs().log2().floor() as i32 - 52);
    println!("k = 40: one ulp of s ({}) moves midspan {} and far end {}", sci(ulp, 2), sci(ulp * 20f64.sinh() / 40.0, 2), sci(ulp * 40f64.sinh() / 40.0, 2));
    println!("k = 40 in 10 pieces (multiple shooting): each piece's dmiss/ds is sinh(4)/40 = {:.4}; d(far height)/d(start height) cosh(4) = {:.2}", 4f64.sinh() / 40.0, 4f64.cosh());
    println!("chart, log10 h: {}", [4.0f64, 8.0, 16.0, 32.0, 64.0].iter().map(|n| format!("{:.2}", (L / n).log10())).collect::<Vec<_>>().join(" "));
    for (j, name) in [(0usize, "shooting"), (1, "centred FD")] {
        println!("chart, log10 |error| {}: {}", name, e.iter().map(|r| format!("{:.2}", r[j].abs().log10())).collect::<Vec<_>>().join(" "));
    }

    assert!((s16 - s_ex).abs() < 1e-9, "shooting slope must match the closed form");
    assert!((misses[3] / (misses[2] * misses[2])).abs() < 0.01, "Newton on the slope must converge quadratically");
    assert!(3.9 < order[0] && order[0] < 4.1 && 1.95 < order[1] && order[1] < 2.05 && 0.9 < order[2] && order[2] < 1.1, "orders 4, 2 and 1");
    assert!(c[&8].0 < 1e-11 && 1e-11 < c[&4].0, "collocation: geometric convergence against the closed form");
    assert!(e[4][1].abs() < 4e-5 && (y4[2] - mid_ex).abs() < 0.01 && (yl - A - ex.c0).abs() < 1e-4 && (xl - x0).abs() < 1e-3, "FD within its h^2 error of the closed form");
    assert!((bb[&40].0 / (40f64.sinh() / 40.0) - 1.0).abs() < 1e-3, "variational equation vs sinh(k)/k");
    assert!((bb[&40].2 * 20f64.cosh() - 1.0).abs() < 0.05 && (bb[&40].1 * 20f64.cosh() - 1.0).abs() > 1.0, "FD holds, shooting fails");
    assert!(it16 <= 5 && 5 < it16n, "exact grid Jacobian: quadratic Newton; without F_p: slower");
    println!("ALL CHECKS PASS");
}
