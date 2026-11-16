// Subharmonic functions and Perron's method -- the check behind the card.  Rust std only.
// A long metal box, cross-section 1 m x 1 m.  Lid (x2 = 1 m) at 100 V, sides and floor grounded.
// The floor is rough: five sawtooth teeth, 10 cm tall, 20 cm wide.  u = potential, V.
// Roads: under and over shapes in closed form (Fourier series); the discrete Perron lift from
// below and from above; SOR grids at four steps with observed order; mean-value tests.
use std::f64::consts::PI;

const V0: f64 = 100.0;
const TOOTH: f64 = 0.1;
type Grid = Vec<Vec<f64>>;

fn sci(v: f64, d: usize) -> String { // e-notation with the same digits as Python
    let e = v.abs().log10().floor() as i32; let m = v / 10f64.powi(e);
    format!("{:.*}e{}{:02}", d, m, if e < 0 { '-' } else { '+' }, e.abs())
}

fn floor_at(x: f64) -> f64 { TOOTH - (x.rem_euclid(2.0 * TOOTH) - TOOTH).abs() } // rough floor height, m

fn boxv(x: f64, y: f64, top: f64, lid: f64) -> f64 { // flat-floored box [0,1] x [0,top]
    let mut s = 0.0;
    for m in 0..200 {
        let k = (2 * m + 1) as f64 * PI;
        s += 4.0 * lid / k * (k * x).sin() * (k * (y - top)).exp() * (1.0 - (-2.0 * k * y).exp()) / (1.0 - (-2.0 * k * top).exp());
    }
    s
}

fn omitted(x: f64, y: f64, top: f64) -> f64 { // first term the series leaves out
    let k = 401.0 * PI;
    4.0 * V0 / k * (k * x).sin().abs() * (k * (y - top)).exp()
}

fn under(x: f64, y: f64) -> f64 { if y > TOOTH { boxv(x, y - TOOTH, 1.0 - TOOTH, V0) } else { 0.0 } }
fn over(x: f64, y: f64) -> f64 { boxv(x, y, 1.0, V0) }

fn setup(n: usize, rough: bool, lid: f64, fill: f64) -> (Grid, Vec<usize>) {
    let fl: Vec<usize> = (0..=n).map(|i| if rough { (floor_at(i as f64 / n as f64) * n as f64).round() as usize } else { 0 }).collect();
    let mut u = vec![vec![0.0; n + 1]; n + 1];
    for i in 1..n { u[i][n] = lid; for j in fl[i] + 1..n { u[i][j] = fill; } }
    (u, fl)
}

fn sweep(u: &mut Grid, fl: &[usize], w: f64) -> f64 { // each value moves to (w times) its neighbours' average
    let n = u.len() - 1; let mut d: f64 = 0.0;
    for i in 1..n {
        for j in fl[i] + 1..n {
            let r = 0.25 * (u[i - 1][j] + u[i + 1][j] + u[i][j - 1] + u[i][j + 1]) - u[i][j];
            u[i][j] += w * r; d = d.max(r.abs());
        }
    }
    d
}

fn grid(n: usize, rough: bool, lid: f64) -> (Grid, usize) { // SOR to convergence
    let (mut u, fl) = setup(n, rough, lid, 0.0); let w = 2.0 / (1.0 + (PI / n as f64).sin()); let mut count = 1;
    while sweep(&mut u, &fl, w) > 1e-10 { count += 1; }
    (u, count)
}

fn avg(f: &dyn Fn(f64, f64) -> f64, x: f64, y: f64, r: f64) -> f64 {
    let m = 720; let mut s = 0.0;
    for t in 0..m { let a = 2.0 * PI * t as f64 / m as f64; s += f(x + r * a.cos(), y + r * a.sin()); }
    s / m as f64
}

fn barrier(x: f64, y: f64) -> f64 { // sqrt(r) cos(phi/2), phi measured from straight up at the tip
    let (dx, dy) = (x - 0.5, y - TOOTH);
    dx.hypot(dy).sqrt() * (dx.atan2(dy) / 2.0).cos()
}

fn main() {
    let (lo, hi) = (under(0.5, 0.5), over(0.5, 0.5));
    println!("under shape (rectangle above the tips) at centre: {:.4} V; first omitted term {} V", lo, sci(omitted(0.5, 0.4, 0.9), 1));
    let sh = |z: f64| (z.exp() - (-z).exp()) / 2.0;
    let terms: Vec<f64> = [1.0, 3.0, 5.0].iter().map(|&k: &f64| 4.0 * V0 / (k * PI) * (k * PI / 2.0).sin() * sh(0.4 * k * PI) / sh(0.9 * k * PI)).collect();
    println!("by hand: 400/pi = {:.3} V; sinh(0.4 pi) = {:.4}, sinh(0.9 pi) = {:.4}; terms k = 1, 3, 5: {} V; sum {:.4} V", 4.0 * V0 / PI, sh(0.4 * PI), sh(0.9 * PI),
             terms.iter().map(|t| format!("{:.4}", t)).collect::<Vec<_>>().join(", "), terms.iter().sum::<f64>());
    println!("over shape (flat-floored square) at centre: {:.4} V; exact by symmetry 25 V", hi);
    assert!((hi - 25.0).abs() < 1e-12); // four rotated lids add to a constant 100 V
    println!("grid | h cm | SOR sweeps | u(centre) V | flat floor V");
    let mut vals = vec![]; let mut fine = vec![];
    for n in [20usize, 40, 80, 160] {
        let (u, cnt) = grid(n, true, V0); let f = grid(n, false, V0).0[n / 2][n / 2];
        vals.push(u[n / 2][n / 2]); let v = vals[vals.len() - 1];
        assert!((f - 25.0).abs() < 1e-6 && lo < v && v < hi);
        println!("grid | {:.3} | {} | {:.4} | {:.4}", 100.0 / n as f64, cnt, v, f);
        if n == 160 { fine = u; }
    }
    let orders: Vec<f64> = (0..2).map(|i| ((vals[i] - vals[i + 1]) / (vals[i + 1] - vals[i + 2])).log2()).collect();
    let p = orders[1]; let best = vals[3] + (vals[3] - vals[2]) / (2f64.powf(p) - 1.0);
    assert!(orders.iter().all(|&q| 1.1 < q && q < 1.5)); // sharp tips: about 4/3, not 2
    println!("observed order {:.2}, {:.2}; extrapolated centre {:.4} V, last step off by {:.4} V", orders[0], orders[1], best, best - vals[3]);
    assert!(lo < best && best < hi);
    println!("by hand: last two grids differ by {:.4} V; 2^p - 1 = {:.3}; teeth pull the centre down by {:.4} V", vals[3] - vals[2], 2f64.powf(p) - 1.0, hi - best);

    println!("Perron lift on the 5 cm grid | sweeps | from below V | from above V | gap V");
    let (mut a, fl) = setup(20, true, V0, 0.0); let (mut b, _) = setup(20, true, V0, V0);
    let (mut k, mut prev_lo, mut prev_hi, mut stop20) = (0, -1.0, 1e9, 0.0);
    let (mut al, mut bh) = (0.0, 0.0);
    while b[10][10] - a[10][10] >= 0.01 {
        k += 1; sweep(&mut a, &fl, 1.0); sweep(&mut b, &fl, 1.0);
        al = a[10][10]; bh = b[10][10];
        assert!(prev_lo <= al && al <= vals[0] && vals[0] <= bh && bh <= prev_hi); prev_lo = al; prev_hi = bh;
        for i in 1..20 { for j in fl[i] + 1..20 { // every lower iterate is a discrete under shape
            assert!(a[i][j] <= 0.25 * (a[i - 1][j] + a[i + 1][j] + a[i][j - 1] + a[i][j + 1]) + 1e-12);
        } }
        if k == 20 { stop20 = al; }
        if k == 10 || k == 40 || k == 160 { println!("lift | {} | {:.4} | {:.4} | {:.4}", k, al, bh, bh - al); }
    }
    println!("lift | {} | {:.4} | {:.4} | {:.4}  (first sweep with gap under 0.01 V)", k, al, bh, bh - al);

    let ys: Vec<f64> = (1..=10).map(|i| (i as f64 * 0.1 * 10.0).round() / 10.0).collect();
    let line = |f: &dyn Fn(f64) -> f64| ys.iter().map(|&y| format!("{:.2}", f(y))).collect::<Vec<_>>().join(", ");
    println!("chart, x1 = 0.5 m, x2 = 0.1..1.0 m, under: {}", line(&|y| if y < 1.0 { under(0.5, y) } else { V0 }));
    println!("chart, rough box (1/160 m grid): {}", line(&|y| fine[80][(160.0 * y).round() as usize]));
    println!("chart, over: {}", line(&|y| if y < 1.0 { over(0.5, y) } else { V0 }));
    println!("first omitted term at x2 = 0.9 m: {} V", sci(omitted(0.5, 0.9, 1.0), 1));

    let ac = avg(&over, 0.5, 0.5, 0.3); assert!((ac - hi).abs() < 1e-9); // harmonic: equal to its average
    let ag = avg(&under, 0.2, 0.1, 0.05); assert!(ag > under(0.2, 0.1) + 0.1); // glued shape: strictly below its average
    println!("mean values: over shape at centre {:.4} V, circle of 30 cm {:.4} V; glued under shape at (0.2, 0.1) m {:.4} V, circle of 5 cm {:.4} V",
             hi, ac, under(0.2, 0.1), ag);

    let mut bd = vec![];
    for i in 0..=1000 { let s = i as f64 / 1000.0; bd.push((s, floor_at(s))); }
    for j in 0..=1000 { bd.push((0.0, j as f64 / 1000.0)); }
    for j in 0..=1000 { bd.push((1.0, j as f64 / 1000.0)); }
    for i in 0..=1000 { bd.push((i as f64 / 1000.0, 1.0)); }
    for s in [-1.0, 1.0] { bd.push((0.5 + s * 0.05 / 2f64.sqrt(), TOOTH - 0.05 / 2f64.sqrt())); } // the two edge points exactly 5 cm away
    let mb = bd.iter().filter(|&&(x, y)| (x - 0.5).hypot(y - TOOTH) >= 0.05 - 1e-12).map(|&(x, y)| barrier(x, y)).fold(f64::INFINITY, f64::min);
    let ab = avg(&barrier, 0.5, 0.3, 0.1); assert!((ab - barrier(0.5, 0.3)).abs() < 1e-9 && mb > 0.0);
    assert!((mb - 0.05f64.sqrt() * (3.0 * PI / 8.0).cos()).abs() < 1e-12); // least value: on the tooth edge, 5 cm out
    println!("barrier at the tip (0.5, 0.1) m: {:.6} at (0.5, 0.3), circle average {:.6}; least on walls 5 cm or more away {:.4}; on the tooth edge cos(67.5 deg) = {:.4}",
             barrier(0.5, 0.3), ab, mb, (3.0 * PI / 8.0).cos());
    let cap = V0 / mb; let near = fine[80][17]; // over shape cap * barrier: >= 0 near the tip, >= 100 V beyond 5 cm
    assert!(near <= cap * barrier(0.5, 0.10625));
    println!("barrier over shape {:.1} x barrier: at 0.625 cm above the tip {:.2} V (grid {:.4} V); at 1 mm {:.2} V; at 1 um {:.4} V",
             cap, cap * barrier(0.5, 0.10625), near, cap * barrier(0.5, 0.101), cap * barrier(0.5, 0.100001));

    let (rr, r) = (0.5, 0.25); // grounded tube, thin wire on its axis at 100 V
    let tube = |a: f64, s: f64| V0 * (rr / s).ln() / (rr / a).ln();
    for a in [1e-3, 1e-6, 1e-12] {
        let t: f64 = 1e-4;
        let res = (tube(a, r + t) - 2.0 * tube(a, r) + tube(a, r - t)) / t.powi(2) + (tube(a, r + t) - tube(a, r - t)) / (2.0 * t * r);
        assert!(res.abs() < 1e-4 * tube(a, r));
        println!("tube: wire radius {} m, u at r = 25 cm: {:.4} V; residual u_rr + u_r/r = {} V/m^2", sci(a, 0), tube(a, r), sci(res.abs(), 1));
    }
    assert!(tube(1e-300, r) < 0.25);
    println!("wire shrunk to a point (radius 1e-300 m): {:.4} V; Perron's answer 0 V, not 100 V", tube(1e-300, r));

    let dome = |x: f64, y: f64| 50.0 * (PI * x).sin() * (PI * (y - TOOTH) / (1.0 - TOOTH)).sin();
    println!("what breaks, at the centre:");
    println!("  floor taken as flat: {:.4} V, not {:.4}", hi, best);
    println!("  a dome under the walls taken as an under shape: {:.4} V, above the answer", dome(0.5, 0.5));
    println!("  lift stopped after 20 sweeps: {:.4} V, a floor, not the answer", stop20);
    println!("  bowl 100 x2^2 taken as an under shape: {:.4} V; it pokes {:.0} V above the side walls at the top", V0 * 0.25, V0 * 1.0);
    println!("try: lid at 50 V, centre {:.4} V; wire 1e-9 m: {:.4} V", grid(80, true, 50.0).0[40][40], tube(1e-9, r));
    println!("ALL CHECKS PASS");
}
