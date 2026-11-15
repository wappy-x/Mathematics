// Weak solutions -- the same check as the Python, in Rust.  No crates.
// A wall: 0.1 m of mineral wool (k = 0.035 W/(m K)) on the room side, then
// 0.1 m of brick (k = 0.77).  Faces held at 20 C and 0 C.  Steady state:
// -(k u')' = 0.  The conductivity jumps, so u'' does not exist at the joint.
// Roads to the joint temperature: resistances in series (closed form); hat
// functions solved by the Thomas algorithm (Galerkin); a smooth probe that
// straddles the joint (Simpson quadrature, then a secant step).
const K1: f64 = 0.035;
const K2: f64 = 0.77;
const L1: f64 = 0.1;
const L2: f64 = 0.1;
const TIN: f64 = 20.0;
const TOUT: f64 = 0.0;
const L: f64 = L1 + L2;
const DT: f64 = TIN - TOUT;

fn kbar(a: f64, b: f64) -> f64 {                   // mean conductivity over [a, b]
    let wool = (b.min(L1) - a).max(0.0);
    (K1 * wool + K2 * (b - a - wool)) / (b - a)
}

fn galerkin(n: usize) -> (Vec<f64>, f64, f64, f64) { // nodes, flux, energy, series flux
    let h = L / n as f64;
    let ks: Vec<f64> = (0..n).map(|e| kbar(e as f64 * h, (e + 1) as f64 * h)).collect();
    let m = n - 1;                                  // inside nodes 1..n-1
    let diag: Vec<f64> = (0..m).map(|i| (ks[i] + ks[i + 1]) / h).collect();
    let off: Vec<f64> = (0..m.saturating_sub(1)).map(|i| -ks[i + 1] / h).collect();
    let mut rhs = vec![0.0; m];
    rhs[0] += ks[0] / h * TIN;
    rhs[m - 1] += ks[n - 1] / h * TOUT;
    let (mut c, mut d) = (vec![0.0; m], vec![0.0; m]); // Thomas algorithm, written out
    for i in 0..m {
        let den = diag[i] - if i > 0 { off[i - 1] * c[i - 1] } else { 0.0 };
        c[i] = if i < m - 1 { off[i] / den } else { 0.0 };
        d[i] = (rhs[i] - if i > 0 { off[i - 1] * d[i - 1] } else { 0.0 }) / den;
    }
    let mut u = vec![0.0; m];
    for i in (0..m).rev() {
        u[i] = d[i] - if i < m - 1 { c[i] * u[i + 1] } else { 0.0 };
    }
    let mut full = vec![TIN];
    full.extend(u);
    full.push(TOUT);
    let flux = -ks[0] * (full[1] - full[0]) / h;
    let energy: f64 = (0..n).map(|e| ks[e] * (full[e + 1] - full[e]).powi(2) / h).sum();
    let series = DT / ks.iter().map(|ke| h / ke).sum::<f64>(); // second road to the flux
    (full, flux, energy, series)
}

fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64) -> f64 {
    let n = 400;
    let h = (b - a) / n as f64;
    let mut s = f(a) + f(b);
    for i in 1..n { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h) }
    s * h / 3.0
}

fn dbump(x: f64, centre: f64, r: f64) -> f64 {     // slope of the smooth probe exp(-1/(1-t^2))
    let t = (x - centre) / r;
    if t.abs() >= 1.0 { return 0.0 }
    (-1.0 / (1.0 - t * t)).exp() * (-2.0 * t / (1.0 - t * t).powi(2)) / r
}

fn residual(tj: f64, centre: f64, r: f64) -> f64 { // integral of k u' v' for the profile with joint tj
    let (s1, s2) = ((tj - TIN) / L1, (TOUT - tj) / L2);
    let (lo, hi) = ((centre - r).max(0.0), (centre + r).min(L));
    let left = if lo < L1 { simpson(&|x| K1 * s1 * dbump(x, centre, r), lo, L1) } else { 0.0 };
    let right = if hi > L1 { simpson(&|x| K2 * s2 * dbump(x, centre, r), lo.max(L1), hi) } else { 0.0 };
    left + right
}

fn clean(x: f64) -> f64 { if x.abs() < 5e-7 { 0.0 } else { x } } // a rounding-level number as 0

fn join(v: &[f64], dp: usize, sep: &str) -> String {
    v.iter().map(|x| format!("{:.*}", dp, x)).collect::<Vec<_>>().join(sep)
}

fn main() {
    let (r1, r2) = (L1 / K1, L2 / K2);
    let q = DT / (r1 + r2);
    let tj = TIN - q * r1;
    let (s1, s2) = (-q / K1, -q / K2);
    let energy = K1 * s1 * s1 * L1 + K2 * s2 * s2 * L2;
    println!("road 1, resistances: wool {:.4}, brick {:.4} m^2 K/W; flux {:.4} W/m^2", r1, r2, q);
    println!("joint temperature {:.4} C; slopes {:.2} and {:.2} K/m; energy a(u,u) {:.4}", tj, s1, s2, energy);
    println!("flux times temperature drop {:.4}; heat flux each side {:.4} and {:.4}", q * DT, -K1 * s1, -K2 * s2);
    let u2 = galerkin(2).0;
    let (u4, f4, _, _) = galerkin(4);
    println!("road 2, Galerkin with a node on the joint: N=2 joint {:.6}, N=4 joint {:.6} C", u2[1], u4[2]);
    println!("N=4 nodes {}; flux {:.4}", join(&u4, 4, ", "), f4);
    let mid = (TIN + TOUT) / 2.0;                  // the straight line's joint temperature
    let (p0, p1) = (residual(mid, L1, 0.05), residual(TOUT, L1, 0.05));
    let tp = mid - p0 * (TOUT - mid) / (p1 - p0);   // one secant step: the residual is linear
    println!("road 3, probe on the joint (radius 0.05 m): residual {:.4} at joint {:.0} C, {:.4} at {:.0} C", p0, mid, p1, TOUT);
    println!("the probe's zero: joint {:.6} C; residual for the true profile {:.6}", tp, clean(residual(tj, L1, 0.05)));
    println!("probe inside the wool only (centre 0.05, radius 0.04): residual for the straight line {:.6}",
             clean(residual(mid, 0.05, 0.04)));
    println!("profile at x = 0, 0.025 .. 0.2 m: weak solution, then straight line");
    let xs: Vec<f64> = (0..9).map(|i| i as f64 * 0.025).collect();
    let prof: Vec<f64> = xs.iter().map(|&x| clean(if x <= L1 { TIN + s1 * x } else { tj + s2 * (x - L1) })).collect();
    println!("chart,{}", join(&prof, 2, ","));
    let line: Vec<f64> = xs.iter().map(|&x| TIN - DT * x / L).collect();
    println!("chart,{}", join(&line, 2, ","));
    println!("mesh cutting the joint: N, flux, series flux, energy error, error x sqrt(N)");
    let mut errs: Vec<(f64, f64, f64, f64)> = Vec::new();
    for n in [3usize, 5, 9, 17, 33, 65, 129] {
        let (_, fl, en, se) = galerkin(n);
        let err = (en - energy).sqrt();
        errs.push((err * (n as f64).sqrt(), err, DT * (fl - q), (fl - se).abs()));
        println!("N={:3}  {:.4}  {:.4}  {:.4}  {:.4}", n, fl, se, err, err * (n as f64).sqrt());
    }
    let ds = s2 - s1;
    let smooth = |x: f64, eps: f64| {               // the C^2 profile itself: slope blended by 3t^2 - 2t^3
        let t = ((x - L1 + eps) / (2.0 * eps)).max(0.0).min(1.0);
        TIN + s1 * x.min(L1 - eps) + 2.0 * eps * (s1 * t + ds * (t * t * t - t * t * t * t / 2.0)) + s2 * (x - L1 - eps).max(0.0)
    };
    let cells = |eps: f64| {                        // second road: k (temperature step)^2 / width, cell by cell
        let segs = [(0.0, L1 - eps, K1), (L1 - eps, L1, K1), (L1, L1 + eps, K2), (L1 + eps, L, K2)];
        segs.iter().map(|&(a, b, kk)| (0..2000).map(|i| {
            let du = smooth(a + (i + 1) as f64 * (b - a) / 2000.0, eps) - smooth(a + i as f64 * (b - a) / 2000.0, eps);
            kk * (du * du) * 2000.0 / (b - a)
        }).sum::<f64>()).sum::<f64>()
    };
    println!("smooth profiles closing on the corner: reach, energy excess (Simpson, cells), largest bend K/m^2");
    let (mut excess, mut steps) = (Vec::new(), Vec::new());
    for eps in [0.01, 0.001, 0.0001] {
        let blend = |t: f64, k: f64| k * (s1 + ds * (3.0 * t * t - 2.0 * t.powi(3))).powi(2);
        let mut en = K1 * s1 * s1 * (L1 - eps) + K2 * s2 * s2 * (L2 - eps);
        en += 2.0 * eps * (simpson(&|t| blend(t, K1), 0.0, 0.5) + simpson(&|t| blend(t, K2), 0.5, 1.0));
        excess.push(en - energy);
        steps.push(cells(eps) - energy);
        println!("reach {:.4} m  excess {:.4}, {:.4}  bend {:.0}", eps, en - energy, steps[steps.len() - 1], 0.75 * ds / eps);
    }
    let (cc, cbig) = (K1.min(K2), K1.max(K2));
    let wnorm = ((s1 + DT / L).powi(2) * L1 + (s2 + DT / L).powi(2) * L2).sqrt();
    let bound = cbig / cc * ((DT / L).powi(2) * L).sqrt();
    println!("Lax-Milgram: c = {:.3}, C = {:.3}; correction size {:.4}, guaranteed below {:.4}", cc, cbig, wnorm, bound);
    println!("mistake 1, straight line: energy {:.4}; flux wool {:.4}, brick {:.4}",
             (K1 + K2) * (DT / L).powi(2) * L1, K1 * DT / L, K2 * DT / L);
    println!("mistake 2, average conductivity {:.4}: flux {:.4}", (K1 + K2) / 2.0, (K1 + K2) / 2.0 * DT / L);
    let h4 = L / 4.0;                               // mistake 3: both faces free, N = 4
    let k4: Vec<f64> = (0..4).map(|e| kbar(e as f64 * h4, (e + 1) as f64 * h4)).collect();
    let mut a = [[0.0f64; 5]; 5];
    for e in 0..4 {
        for (i, j, sgn) in [(e, e, 1.0), (e + 1, e + 1, 1.0), (e, e + 1, -1.0), (e + 1, e, -1.0)] {
            a[i][j] += sgn * k4[e] / h4;
        }
    }
    for p in 0..4 {                                 // elimination, no row swaps
        for i in p + 1..5 {
            let f = a[i][p] / a[p][p];
            for j in 0..5 { a[i][j] -= f * a[p][j] }
        }
    }
    let piv: Vec<f64> = (0..4).map(|i| a[i][i]).collect();
    println!("mistake 3, both faces given a flux (N=4): pivots {}, last pivot {:.4}", join(&piv, 4, ", "), clean(a[4][4]));
    assert!((u4[2] - tj).abs() < 1e-9 && (f4 - q).abs() < 1e-9);  // Galerkin against resistances
    assert!((tp - tj).abs() < 1e-6);                               // probe against resistances
    assert!((p0 - (-1.0f64).exp() * (K2 - K1) * DT / L).abs() < 1e-6); // quadrature against exact
    assert!(errs.iter().all(|e| e.3 < 1e-9));                      // Thomas against series formula
    assert!(errs.iter().all(|e| (e.1 * e.1 - e.2).abs() < 1e-9));  // energy gap = drop x flux gap
    assert!((errs[6].0 / errs[5].0 - 1.0).abs() < 0.05);           // rate 1/2
    assert!(excess[0] > excess[1] && excess[1] > excess[2] && excess[2] > 0.0); // smooth profiles cost more
    assert!(excess.iter().zip(&steps).all(|(e, m)| (e - m).abs() < 1e-5 * e)); // Simpson on the slope against the cells
    assert!([0.01, 0.001, 0.0001].iter().all(|&e| (smooth(L, e) - TOUT).abs() < 1e-9)); // the blend keeps the 20 K drop
    assert!((q * DT - energy).abs() < 1e-9);                       // energy balance: flux x drop
    assert!(wnorm < bound);                                        // Lax-Milgram's ceiling
    assert!(a[4][4].abs() < 1e-9);                                 // both faces free: singular
    println!("ALL CHECKS PASS");
}
