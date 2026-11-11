// Interior point methods -- the check behind the card.  Standard library only, no crates.
// Three pumps feed a town.  MINIMISE the power f0(x) = sum a_i x_i^2 (kW) over the flows x (L/s),
// subject to total flow h(x) = x1 + x2 + x3 - 150 = 0, head at the hill tank between 35 and 45 m,
// and every flow at least 0.  The five limits are written f_i(x) <= 0; slack_i = -f_i(x).
// Road 1: the barrier method, Newton centring for t = 1, 10, 100, ... (the central path).
// Road 2: the dual bound q(lambda, nu), from the Lagrangian minimised in closed form.
// Road 3: the KKT conditions solved for every one of the 32 choices of binding limits.
const A: [f64; 3] = [0.02, 0.03, 0.05]; // kW per (L/s)^2
const K: [f64; 3] = [0.1, 0.2, 0.4]; // m of head per L/s
const D: f64 = 150.0; // L/s
const LO: f64 = 35.0; // m
const HI: f64 = 45.0; // m
const M: usize = 5; // number of limits
const START: [f64; 3] = [40.0, 50.0, 60.0]; // strictly inside
const GROW: f64 = 10.0; // t factor

fn gs(j: usize, i: usize) -> f64 { // gradient of slack j, entry i
    match j { 0 => K[i], 1 => -K[i], _ => if j - 2 == i { 1.0 } else { 0.0 } }
}
fn f0(x: &[f64]) -> f64 { (0..3).fold(0.0, |s, i| s + A[i] * x[i] * x[i]) }
fn head(x: &[f64]) -> f64 { (0..3).fold(0.0, |s, i| s + K[i] * x[i]) }
fn slacks_w(x: &[f64], lo: f64, hi: f64) -> Vec<f64> { vec![head(x) - lo, hi - head(x), x[0], x[1], x[2]] }
fn slacks(x: &[f64]) -> Vec<f64> { slacks_w(x, LO, HI) }
fn z4(u: f64) -> String { let s = format!("{:.4}", u); if s == "-0.0000" { "0.0000".into() } else { s } }
fn f4(v: &[f64]) -> String { v.iter().map(|&u| z4(u)).collect::<Vec<_>>().join(", ") }

fn gauss(mx: &[Vec<f64>], r: &[f64]) -> Option<Vec<f64>> { // elimination with row swaps
    let n = r.len();
    let mut m: Vec<Vec<f64>> = mx.iter().zip(r).map(|(row, &v)| { let mut w = row.clone(); w.push(v); w }).collect();
    for c in 0..n {
        let mut p = c;
        for i in c + 1..n { if m[i][c].abs() > m[p][c].abs() { p = i; } }
        if m[p][c].abs() < 1e-12 { return None; }
        m.swap(c, p);
        for i in 0..n {
            if i != c {
                let f = m[i][c] / m[c][c];
                let pivot = m[c].clone();
                for (u, v) in m[i].iter_mut().zip(pivot.iter()) { *u = *u - f * v; }
            }
        }
    }
    Some((0..n).map(|i| m[i][n] / m[i][i]).collect())
}

fn phi(x: &[f64], t: f64) -> Option<f64> { // t f0 - sum log(slack); None outside the interior
    let s = slacks(x);
    if s.iter().cloned().fold(f64::INFINITY, f64::min) <= 0.0 { return None; }
    Some(t * f0(x) - s.iter().fold(0.0, |a, v| a + v.ln()))
}

fn newton(x: &[f64], t: f64) -> (Vec<f64>, f64, f64) { // the centring step: a KKT-shaped 4 x 4 system
    let s = slacks(x);
    let g: Vec<f64> = (0..3).map(|i| t * 2.0 * A[i] * x[i] - (0..M).fold(0.0, |a, j| a + gs(j, i) / s[j])).collect();
    let mut h: Vec<Vec<f64>> = (0..3).map(|i| {
        let mut row: Vec<f64> = (0..3).map(|l| (if i == l { t * 2.0 * A[i] } else { 0.0 })
            + (0..M).fold(0.0, |a, j| a + gs(j, i) * gs(j, l) / s[j].powi(2))).collect();
        row.push(1.0); row }).collect();
    h.push(vec![1.0, 1.0, 1.0, 0.0]);
    let mut rhs: Vec<f64> = g.iter().map(|v| -v).collect();
    rhs.push(0.0);
    let z = gauss(&h, &rhs).unwrap();
    let dec2 = -(0..3).fold(0.0, |a, i| a + g[i] * z[i]);
    (z[..3].to_vec(), z[3], dec2) // direction d, w = t nu, decrement squared
}

fn centre(mut x: Vec<f64>, t: f64) -> (Vec<f64>, f64, usize) { // until the predicted drop dec2 / 2 <= 1e-14 max(t, 1)
    for steps in 0..100 {
        let (d, w, dec2) = newton(&x, t);
        if dec2 / 2.0 <= 1e-14 * t.max(1.0) { return (x, w / t, steps); } // phi's rounding error grows with t
        let (mut al, p0) = (1.0, phi(&x, t).unwrap());
        loop {
            let y: Vec<f64> = (0..3).map(|i| x[i] + al * d[i]).collect();
            if let Some(py) = phi(&y, t) { if py <= p0 - 0.25 * al * dec2 { x = y; break; } }
            al /= 2.0;
        }
    }
    panic!("no convergence");
}

fn dual(lam: &[f64], nu: f64) -> f64 { // q(lam, nu) = min over x of the Lagrangian, in closed form
    let c: Vec<f64> = (0..3).map(|i| -lam[0] * K[i] + lam[1] * K[i] - lam[2 + i] + nu).collect();
    LO * lam[0] - HI * lam[1] - D * nu - (0..3).fold(0.0, |a, i| a + c[i].powi(2) / (4.0 * A[i]))
}
fn und(p: Option<f64>) -> &'static str { if p.is_none() { "undefined" } else { "defined" } }

fn main() {
    println!("start {} L/s: head {:.4} m, power {:.4} kW, slacks {}", f4(&START), head(&START), f0(&START), f4(&slacks(&START)));
    // ---- road 3: KKT by enumeration of binding sets ----
    let mut kkt: Vec<(Vec<usize>, Vec<f64>)> = vec![];
    for mask in 0..32 {
        let act: Vec<usize> = (0..M).filter(|j| mask >> j & 1 == 1).collect();
        let na = act.len();
        let mut rows: Vec<Vec<f64>> = (0..3).map(|i| {
            let mut r: Vec<f64> = (0..3).map(|c| if c == i { 2.0 * A[i] } else { 0.0 }).collect();
            r.extend(act.iter().map(|&j| -gs(j, i))); r.push(1.0); r }).collect();
        for &j in &act { let mut r: Vec<f64> = (0..3).map(|i| gs(j, i)).collect(); r.extend(vec![0.0; na + 1]); rows.push(r); }
        let mut r = vec![1.0, 1.0, 1.0]; r.extend(vec![0.0; na + 1]); rows.push(r);
        let mut rhs = vec![0.0; 3];
        rhs.extend(act.iter().map(|&j| [LO, -HI, 0.0, 0.0, 0.0][j])); rhs.push(D);
        if let Some(z) = gauss(&rows, &rhs) {
            let ok = slacks(&z[..3]).iter().cloned().fold(f64::INFINITY, f64::min) > -1e-9 && z[3..3 + na].iter().all(|&v| v > -1e-9);
            if ok { kkt.push((act, z)); }
        }
    }
    println!("road 3, KKT by enumeration: {} of 32 binding sets pass", kkt.len());
    let (act, z) = kkt[0].clone();
    let (xs, lam_star, nu_star) = (z[..3].to_vec(), z[3], z[4]);
    let pstar = f0(&xs);
    println!("  binding: limit {} (head floor); flows {} L/s, lambda {:.4} kW per m, nu {:.4}", act[0] + 1, f4(&xs), lam_star, nu_star);
    println!("  p* = {:.4} kW, {:.4} pounds per hour at 0.20 pounds per kWh", pstar, 0.2 * pstar);
    assert!(kkt.len() == 1 && act == vec![0] && xs.iter().all(|v| (v - 50.0).abs() < 1e-9));
    let (d0, _, dr0) = newton(&START, 1.0); // the Newton step's slope and curvature against central differences of phi
    let pd = |e: f64| phi(&(0..3).map(|i| START[i] + e * d0[i]).collect::<Vec<f64>>(), 1.0).unwrap();
    assert!(((pd(1e-3) - pd(-1e-3)) / 2e-3 + dr0).abs() < 1e-5 * dr0);
    assert!(((pd(1e-3) - 2.0 * pd(0.0) + pd(-1e-3)) / 1e-6 - dr0).abs() < 1e-5 * dr0);
    // ---- road 1 and road 2: the central path, with a certificate at every point ----
    let (mut x, mut t, eps, mut total) = (START.to_vec(), 1.0_f64, 1e-4, 0);
    let mut path: Vec<(f64, Vec<f64>, f64, Vec<f64>, f64, usize)> = vec![];
    let mut nu;
    loop {
        let (xn, nn, n) = centre(x, t);
        x = xn; nu = nn;
        let lam: Vec<f64> = slacks(&x).iter().map(|s| 1.0 / (t * s)).collect();
        let q = dual(&lam, nu);
        total += n;
        println!("t {:9.0}: flows {}, head {:.4} m, power {:.4}, bound {:.4}, gap {:.5} kW, {} steps", t, f4(&x), head(&x), f0(&x), q, f0(&x) - q, n);
        assert!(((f0(&x) - q) - M as f64 / t).abs() < 1e-7 && q <= pstar + 1e-9 && pstar + 1e-9 <= f0(&x) + 2e-9);
        path.push((t, x.clone(), nu, lam, q, n));
        if M as f64 / t <= eps { break; }
        t *= GROW;
    }
    let rounds = 1 + ((M as f64 / eps).log10() / GROW.log10()).ceil() as usize; // t0 = 1
    println!("rounds {} (formula 1 + ceil(log(m / (t0 eps)) / log(factor)) = {}), Newton steps {}", path.len(), rounds, total);
    println!("Newton steps per round: {}", path.iter().map(|p| p.5.to_string()).collect::<Vec<_>>().join(" "));
    println!("power minus p*, kW: {}", path[..5].iter().map(|p| format!("{:.6}", f0(&p.1) - pstar)).collect::<Vec<_>>().join(" "));
    println!("ratio of successive errors: {}", (0..4).map(|i| format!("{:.4}", (f0(&path[i].1) - pstar) / (f0(&path[i + 1].1) - pstar))).collect::<Vec<_>>().join(" "));
    assert!(path.len() == rounds && (0..3).all(|i| (x[i] - xs[i]).abs() < 1e-4) && (nu - nu_star).abs() < 1e-4);
    let (x1, nu1, lam1) = (path[0].1.clone(), path[0].2, path[0].3.clone());
    println!("at t = 1: slacks {}", slacks(&x1).iter().map(|v| format!("{:.6}", v)).collect::<Vec<_>>().join(", "));
    let prod: Vec<f64> = lam1.iter().zip(slacks(&x1)).map(|(l, s)| l * s).collect();
    println!("at t = 1: lambda {}; lambda_i * slack_i = {}", f4(&lam1), f4(&prod));
    println!("at t = 1: pump A row {:.6} - {:.6} + {:.6} - {:.6} + nu = 0, nu = {:.6}", 2.0 * A[0] * x1[0], K[0] * lam1[0], K[0] * lam1[1], lam1[2], nu1);
    println!("at t = {:.0}: lambda {}", t, f4(&path[path.len() - 1].3));
    assert!((path[path.len() - 1].3[0] - lam_star).abs() < 1e-3);
    // ---- the picture: the central path in the (x1, x2) plane, x3 = 150 - x1 - x2 ----
    let xa = centre(START.to_vec(), 1e-9).0;
    let mut pts = vec![xa.clone()];
    for tt in [0.003, 0.01, 0.03, 0.1, 0.3, 1.0] { pts.push(centre(START.to_vec(), tt).0); }
    println!("figure, path (x1, x2): {}", pts.iter().map(|p| format!("({:.2}, {:.2})", p[0], p[1])).collect::<Vec<_>>().join(" "));
    println!("figure, analytic centre head {:.4} m; head-floor line through (44.67, 58) and (59.33, 36); optimum (50, 50)", head(&xa));
    // ---- what breaks ----
    let bad = [70.0, 50.0, 30.0];
    println!("start outside {}: head {:.4} m, slack {:.4}, barrier {}", f4(&bad), head(&bad), slacks(&bad)[0], und(phi(&bad, 1.0)));
    println!("window 35 to 35 m: slacks at the best plan {}; their sum is 0 for every plan", f4(&slacks_w(&xs, 35.0, 35.0)[..2]));
    let (d, _, _) = newton(&x1, 10.0);
    let y: Vec<f64> = (0..3).map(|i| x1[i] + d[i]).collect();
    println!("full Newton step from x*(1) at t = 10: flows {}, head {:.4} m, barrier {}", f4(&y), head(&y), und(phi(&y, 10.0)));
    assert!(head(&y) < LO && phi(&bad, 1.0).is_none());
    let lam_bad: Vec<f64> = slacks(&path[1].1).iter().map(|s| 1.0 / s).collect();
    println!("multipliers without the 1/t at t = 10: head floor {:.4}, bound {:.4} kW", lam_bad[0], dual(&lam_bad, path[1].2 * 10.0));
    println!("stop at t = 1 and call it best: {:.4} kW, {:.4} kW too much", f0(&x1), f0(&x1) - pstar);
    println!("ALL CHECKS PASS");
}
