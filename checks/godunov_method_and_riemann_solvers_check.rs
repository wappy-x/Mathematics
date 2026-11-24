// Godunov's method: solve a small Riemann problem at every cell edge -- the same
// check in Rust, std only, no crates.  Burgers' equation u_t + (u^2/2)_x = 0.
// Road 1: the Rankine-Hugoniot speed.  Road 2: Godunov's method at five grid sizes, on the
// shock and on a smooth wave.  Road 3: the mass identity (telescoping end fluxes).  Road 4: the
// exact Riemann solution against the closed-form flux; Roe and HLL against Godunov and HLL's middle state.
use std::f64::consts::PI;

fn f(u: f64) -> f64 { 0.5 * u * u }                    // Burgers' flux

fn riemann(ul: f64, ur: f64, xi: f64) -> f64 {         // exact Riemann solution at x/t = xi
    if ul > ur { return if xi < (ul + ur) / 2.0 { ul } else { ur } }   // shock
    if xi <= ul { return ul }                          // rarefaction fan: u = x/t inside
    if xi >= ur { return ur }
    xi
}
fn godunov(ul: f64, ur: f64) -> f64 { f(riemann(ul, ur, 0.0)) }   // flux through the edge
fn closed(ul: f64, ur: f64) -> f64 { f(ul.max(0.0)).max(f(ur.min(0.0))) }
fn roe_d(ul: f64, ur: f64, d: f64) -> f64 {            // Roe: one wave at the averaged speed
    let mut a = (ul + ur).abs() / 2.0;
    if a < d { a = (a * a + d * d) / (2.0 * d) }       // Harten's entropy fix, width d
    (f(ul) + f(ur)) / 2.0 - a / 2.0 * (ur - ul)
}
fn roe(ul: f64, ur: f64) -> f64 { roe_d(ul, ur, 0.0) }
fn roe5(ul: f64, ur: f64) -> f64 { roe_d(ul, ur, 0.5) }  fn roe2(ul: f64, ur: f64) -> f64 { roe_d(ul, ur, 0.2) }
fn hll(ul: f64, ur: f64) -> f64 {                      // HLL: two waves, one middle state
    let (sl, sr) = (ul.min(ur), ul.max(ur));
    if sl >= 0.0 { return f(ul) }
    if sr <= 0.0 { return f(ur) }
    (sr * f(ul) - sl * f(ur) + sl * sr * (ur - ul)) / (sr - sl)
}
fn hll2(ul: f64, ur: f64, sl: f64, sr: f64) -> f64 {  // HLL again: middle state um from conservation over
    let um = (sr * ur - sl * ul - (f(ur) - f(ul))) / (sr - sl);   // the fan, then the jump condition
    f(ul) + sl * (um - ul)                             // across the left wave
}

enum How { Flux(fn(f64, f64) -> f64), Nonc, Squares, Loop }
fn advance(how: &How, u: &[f64], nu: f64) -> Vec<f64> {
    let n = u.len();
    match how {
        How::Flux(fl) => {                             // finite-volume update; ghost cells copy the ends
            let g: Vec<f64> = (0..n + 2).map(|i| u[i.max(1).min(n) - 1]).collect();
            let fx: Vec<f64> = (0..n + 1).map(|i| fl(g[i], g[i + 1])).collect();
            (0..n).map(|j| u[j] - nu * (fx[j + 1] - fx[j])).collect()
        }
        How::Loop => advance(&How::Flux(godunov), &[&u[n - 1..], u, &u[..1]].concat(), nu)[1..n + 1].to_vec(),   // ghosts: far ends
        How::Nonc => (0..n).map(|j| u[j] - nu * u[j] * (u[j] - u[if j > 0 { j - 1 } else { 0 }])).collect(),
        How::Squares => {                              // conserves u^2 with flux (2/3) u^3 instead
            let v: Vec<f64> = u.iter().map(|w| w * w).collect();
            let g: Vec<f64> = v.iter().map(|w| 2.0 / 3.0 * w.powf(1.5)).collect();
            (0..n).map(|j| (v[j] - nu * (g[j] - g[if j > 0 { j - 1 } else { 0 }])).max(0.0).powf(0.5)).collect()
        }
    }
}
fn start(n: usize, x0: f64, a: f64, b: f64) -> Vec<f64> { (0..n).map(|j| if (j as f64 + 0.5) / (n as f64) < x0 { a } else { b }).collect() }
fn run(n: usize, nu: f64, t: f64, how: &How, u0: Option<Vec<f64>>) -> Vec<f64> {
    let mut u = u0.unwrap_or_else(|| start(n, 0.3, 1.0, 0.0));
    for _ in 0..(t * n as f64 / nu).round() as usize { u = advance(how, &u, nu) }
    u
}
fn cross(u: &[f64]) -> f64 {                           // where the profile crosses 1/2
    let n = u.len();
    let j = (0..n - 1).filter(|&i| u[i] >= 0.5 && 0.5 > u[i + 1]).max().unwrap();
    (j as f64 + 0.5 + (u[j] - 0.5) / (u[j] - u[j + 1])) / n as f64
}
fn l1(u: &[f64], xs: f64) -> f64 {                     // distance from the exact shock's cell averages
    let n = u.len() as f64;
    u.iter().enumerate().map(|(j, v)| (v - (xs * n - j as f64).max(0.0).min(1.0)).abs()).sum::<f64>() / n
}
fn wave(x: f64, t: f64) -> f64 {                       // smooth wave on a loop: u = u0(x - u t), by iteration
    (0..60).fold(0.5, |v, _| 0.5 + 0.25 * (2.0 * PI * (x - v * t)).sin())
}
fn fan(j: usize, n: usize) -> f64 {                    // exact cell average of the fan from x = 0.5
    let g = |y: f64| if y.abs() <= 0.25 { y * y / (2.0 * 0.25) } else { y.abs() - 0.25 / 2.0 };
    (g((j + 1) as f64 / n as f64 - 0.5) - g(j as f64 / n as f64 - 0.5)) * n as f64
}
fn sci(x: f64) -> String {                             // Python's {:.1e}: exponent with sign and two digits
    let s = format!("{:.1e}", x);
    let (m, e) = s.split_once('e').map(|(m, e)| (m, e.parse::<i32>().unwrap())).unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn mx(u: &[f64]) -> f64 { u.iter().fold(f64::MIN, |m, &v| m.max(v)) }
fn mn(u: &[f64]) -> f64 { u.iter().fold(f64::MAX, |m, &v| m.min(v)) }
fn gap(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).fold(0.0, |m, (x, y)| m.max((x - y).abs())) }
fn join(v: Vec<String>) -> String { v.join(", ") }

fn main() {
    let g = How::Flux(godunov);
    let s = (f(1.0) - f(0.0)) / (1.0 - 0.0);  let xs = 0.3 + s * 0.5;
    println!("Burgers, u = 1 left of 0.3, 0 right; 100 cells h = 0.01, dt = 0.005, nu = 0.50, 100 steps to t = 0.5");
    println!("Rankine-Hugoniot: s = (0.5 - 0)/(1 - 0) = {:.4}; exact shock at 0.3 + {:.1} x 0.5 = {:.4}", s, s, xs);
    let grid: Vec<f64> = (0..41).map(|i| i as f64 / 10.0 - 2.0).collect();
    let (mut gc, mut same, mut tr, mut hg) = (vec![], vec![], vec![], vec![]);
    for &a in &grid { for &b in &grid {
        gc.push((godunov(a, b) - closed(a, b)).abs());
        if a < 0.0 && 0.0 < b { tr.push((roe(a, b) - godunov(a, b)).abs()) } else { same.push((roe(a, b) - godunov(a, b)).abs()) }
        if a.min(b) < 0.0 && 0.0 < a.max(b) { hg.push((hll(a, b) - hll2(a, b, a.min(b), a.max(b))).abs()) }
    } }
    println!("Riemann solver sampled at x/t = 0 against max(f(max(uL,0)), f(min(uR,0))), 1681 pairs: largest gap {}", sci(mx(&gc)));
    println!("Roe against Godunov: largest gap {} on the {} pairs without uL < 0 < uR; smallest gap {} on the {} with it",
             sci(mx(&same)), same.len(), sci(mn(&tr)), tr.len());
    println!("HLL against f(uL) + sL (um - uL), um from conservation, {} pairs with sL < 0 < sR: largest gap {}", hg.len(), sci(mx(&hg)));

    let mut u = start(100, 0.3, 1.0, 0.0);
    println!("by hand, the first two steps at the cell from 0.30 to 0.31 (left neighbour 1, right neighbour 0):");
    for k in 1..=2 {
        let (b, fl, fr) = (u[30], godunov(u[29], u[30]), godunov(u[30], u[31]));
        u = advance(&g, &u, 0.5);
        println!("  step {}: F_left = {:.5}, F_right = {:.5}, new u = {:.6} - 0.5 x ({:.5} - {:.5}) = {:.6}", k, fl, fr, b, fr, fl, u[30]);
    }
    let (gd, nc, sq) = (run(100, 0.5, 0.5, &g, None), run(100, 0.5, 0.5, &How::Nonc, None), run(100, 0.5, 0.5, &How::Squares, None));
    let mass = gd.iter().sum::<f64>() / 100.0;
    println!("Godunov: crossing {:.4}, true error {:+.4} = {:+.2} cells; mass {:.4}; range {:.4} to {:.4}",
             cross(&gd), cross(&gd) - xs, (cross(&gd) - xs) * 100.0, mass, mn(&gd), mx(&gd));
    println!("  mass identity 0.3 + 100 x 0.005 x 0.5 = {:.4}; gap {}", 0.3 + 100.0 * 0.005 * 0.5, sci((mass - 0.55).abs()));
    println!("  cells 0.50 to 0.60: {}", gd[50..60].iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "));
    println!("non-conservative upwind: crossing {:.4}, true error {:+.4}; mass {:.4}", cross(&nc), cross(&nc) - xs, nc.iter().sum::<f64>() / 100.0);
    println!("conserving u^2 instead: speed (2/3)/1 = {:.4}, shock at {:.4}; crossing {:.4}, where u^2 itself crosses 1/2: {:.4}",
             2.0 / 3.0, 0.3 + 0.5 * 2.0 / 3.0, cross(&sq), cross(&sq.iter().map(|w| w * w).collect::<Vec<f64>>()));
    let (rs, hs) = (run(100, 0.5, 0.5, &How::Flux(roe), None), run(100, 0.5, 0.5, &How::Flux(hll), None));
    println!("Roe and HLL on the shock: largest gap from Godunov {}, {}", sci(gap(&rs, &gd)), sci(gap(&hs, &gd)));
    println!("Lax-Wendroff theorem at work: refine, nu = 0.5 | L1 error = h x sum |u_j - exact cell average|");
    println!("  and Godunov on a smooth wave u0 = 0.5 + 0.25 sin(2 pi x), on a loop, to t = 0.2, before it breaks at 1/(0.25 x 2 pi) = {:.4} | L1 against exact u at centres", 1.0 / (0.5 * PI));
    let (mut eg, mut en, mut es) = (vec![], vec![], vec![]);
    for n in [100usize, 200, 400, 800, 1600] {
        let (a, b) = (run(n, 0.5, 0.5, &g, None), run(n, 0.5, 0.5, &How::Nonc, None));
        let w = run(n, 0.5, 0.2, &How::Loop, Some((0..n).map(|j| wave((j as f64 + 0.5) / n as f64, 0.0)).collect()));
        eg.push(l1(&a, xs)); en.push(l1(&b, xs));
        es.push(w.iter().enumerate().map(|(j, v)| (v - wave((j as f64 + 0.5) / n as f64, 0.2)).abs()).sum::<f64>() / n as f64);
        println!("  {:>4} cells: Godunov crossing {:.4}, L1 {:.5} | non-conservative crossing {:.4}, L1 {:.4} | smooth L1 {:.6}",
                 n, cross(&a), eg[eg.len() - 1], cross(&b), en[en.len() - 1], es[es.len() - 1]);
    }
    for (name, e) in [("shock", &eg), ("smooth wave", &es)] { println!("  Godunov L1 ratios as h halves, {}: {}", name, join((0..4).map(|i| format!("{:.2}", e[i] / e[i + 1])).collect())) }

    println!("transonic fan: u = -1 left of 0.5, +1 right, 100 cells, nu = 0.5, 50 steps to t = 0.25 | L1 error");
    let (mut fans, mut fl1): (Vec<Vec<f64>>, Vec<f64>) = (vec![], vec![]);
    let list: [(&str, fn(f64, f64) -> f64); 5] = [("Godunov", godunov), ("Roe, no fix", roe), ("Roe, fix width 0.5", roe5), ("Roe, fix width 0.2", roe2), ("HLL", hll)];
    for (name, fl) in list.iter() {
        let v = run(100, 0.5, 0.25, &How::Flux(*fl), Some(start(100, 0.5, -1.0, 1.0)));
        let e = v.iter().enumerate().map(|(j, w)| (w - fan(j, 100)).abs()).sum::<f64>() / 100.0;
        println!("  {:<19} L1 {:.4}; cells either side of 0.5: {:+.4} {:+.4}", name, e, v[49], v[50]);
        fans.push(v); fl1.push(e);
    }
    println!("  exact cell averages there: {:+.4} {:+.4}", fan(49, 100), fan(50, 100));
    let big = run(100, 1.25, 0.5, &g, None);
    println!("what breaks: nu = 1.25 (dt = 0.0125, 40 steps): range {:.4} to {:.4}, overshoot {:.4}", mn(&big), mx(&big), mx(&big) - 1.0);
    println!("cost: {} edge fluxes for the 100-cell run, about 6 operations each", 101 * 100);
    let idx = |x: f64| (x * 100.0 - 0.5).round() as usize;
    let lab: Vec<f64> = (0..21).map(|i| 0.245 + 0.02 * i as f64).collect();
    println!("chart, x: {}", join(lab.iter().map(|x| format!("{:.3}", x)).collect()));
    println!("chart, exact: {}", join(lab.iter().map(|&x| format!("{:.2}", if x < xs { 1.0 } else { 0.0 })).collect()));
    println!("chart, Godunov: {}", join(lab.iter().map(|&x| format!("{:.2}", gd[idx(x)])).collect()));
    println!("chart, non-conservative: {}", join(lab.iter().map(|&x| format!("{:.2}", nc[idx(x)])).collect()));
    let lab2: Vec<f64> = (0..15).map(|i| 0.205 + 0.04 * i as f64).collect();
    println!("chart2, x: {}", join(lab2.iter().map(|x| format!("{:.3}", x)).collect()));
    println!("chart2, exact: {}", join(lab2.iter().map(|&x| format!("{:.2}", fan(idx(x), 100))).collect()));
    println!("chart2, Godunov: {}", join(lab2.iter().map(|&x| format!("{:.2}", fans[0][idx(x)])).collect()));
    println!("chart2, Roe, no fix: {}", join(lab2.iter().map(|&x| format!("{:.2}", fans[1][idx(x)])).collect()));

    assert!((cross(&gd) - xs).abs() < 0.02);              // within two cells of Rankine-Hugoniot
    assert!((mass - (0.3 + 0.25)).abs() < 1e-12);          // mass identity: telescoping fluxes
    assert!((cross(&nc) - 0.3).abs() < 1e-12 && en[4] > 0.24);   // non-conservative: frozen, wrong limit
    assert!((cross(&sq) - (0.3 + 1.0 / 3.0)).abs() < 0.02);  // u^2 conserved: the other speed, 2/3
    assert!((0..4).all(|i| es[i] / es[i + 1] > 1.8 && es[i] / es[i + 1] < 2.2));   // first order, seen on the smooth wave
    assert!(gc.iter().all(|&e| e < 1e-15) && same.iter().all(|&e| e < 1e-15) && tr.iter().all(|&e| e > 1e-3));   // Roe: only fans differ
    assert!(gap(&rs, &gd) < 1e-12 && hg.iter().all(|&e| e < 1e-12));   // HLL, two roads
    assert!((fans[1][49] + 1.0).abs() < 1e-12);            // no fix: the expansion shock never opens
    assert!(fl1[0] < 0.05 && fl1[2] < 0.05 && fl1[3] < 0.05 && fl1[4] < 0.05);   // fixed solvers open the fan (NaN fails)
    assert!(mx(&big) > 1.005 && mx(&gd) <= 1.0 && mn(&gd) >= 0.0);
    println!("ALL CHECKS PASS");
}
