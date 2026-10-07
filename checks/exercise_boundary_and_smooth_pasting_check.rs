// Exercise boundary and smooth pasting -- the check behind the card.  Rust std only.
// Three roads to the house put's exercise boundary: a 2000-step CRR tree, the early-exercise
// integral equation solved by a root finder, and a PSOR grid on the linear complementarity problem.
const S0: f64 = 100.0; const K: f64 = 100.0; const R: f64 = 0.05; const Q: f64 = 0.02;
const SIG: f64 = 0.20; const T: f64 = 1.0;

fn nc(x: f64) -> f64 { // normal CDF from its Taylor series, no erf
    if x.abs() > 9.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let (mut s, mut t, mut k) = (x, x, 1.0);
    while t.abs() > 1e-17 * s.abs() { k += 2.0; t *= x * x / k; s += t; }
    0.5 + s * (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt()
}
fn d12(s: f64, b: f64, u: f64) -> (f64, f64) {
    let d1 = ((s / b).ln() + (R - Q + 0.5 * SIG * SIG) * u) / (SIG * u.sqrt()); (d1, d1 - SIG * u.sqrt())
}
fn euro(s: f64, u: f64) -> f64 { let (d1, d2) = d12(s, K, u); K * (-R * u).exp() * nc(-d2) - s * (-Q * u).exp() * nc(-d1) }
fn root(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 { // bisection
    let mut flo = f(lo);
    for _ in 0..60 {
        let m = 0.5 * (lo + hi); let fm = f(m);
        if (fm > 0.0) == (flo > 0.0) { lo = m; flo = fm; } else { hi = m; }
    }
    0.5 * (lo + hi)
}
// ---- road 1: CRR tree, 2000 steps a year, started m steps early so the t = 0 slice is wide
fn tree(n: usize, m: usize, rule: Option<&dyn Fn(f64) -> f64>, want: &[f64]) -> (f64, Vec<f64>, f64) {
    let dt = T / n as f64; let u = (SIG * dt.sqrt()).exp(); let p = (((R - Q) * dt).exp() - 1.0 / u) / (u - 1.0 / u);
    let disc = (-R * dt).exp(); let tot = n + m;
    let node = |j: usize, i: usize| S0 * u.powi(2 * j as i32 - i as i32);
    let mut v: Vec<f64> = (0..=tot).map(|j| (K - node(j, tot)).max(0.0)).collect();
    let mut edge = vec![0.0; want.len()];
    for i in (m..tot).rev() {
        let left = (tot - i) as f64 * dt; let bnd = rule.map(|f| f(left)); let mut ex = 0.0;
        for j in 0..=i {
            let s = node(j, i); let c = disc * (p * v[j + 1] + (1.0 - p) * v[j]);
            let stop = match bnd { None => K - s > c, Some(b) => s <= b };
            v[j] = if stop { K - s } else { c };
            if stop { ex = s; }
        }
        for (w, e) in want.iter().zip(edge.iter_mut()) { if ((w / dt).round() as usize) == tot - i { *e = ex; } }
    }
    (v[m / 2], edge, u * u)
}
// ---- road 2: the early-exercise integral equation, marched from expiry with bisection
fn prem(s: f64, taus: &[f64], bs: &[f64], last: f64, i: usize) -> f64 {
    let (mut tot, mut prev) = (0.0, None::<(f64, f64)>);
    for j in (0..=i).rev() {
        let u = taus[i] - taus[j]; let b = if j == i { last } else { bs[j] };
        let f = if u == 0.0 { if s == b { 0.5 * (R * K - Q * s) } else if s < b { R * K - Q * s } else { 0.0 } }
            else { let (d1, d2) = d12(s, b, u); R * K * (-R * u).exp() * nc(-d2) - Q * s * (-Q * u).exp() * nc(-d1) };
        if let Some((pu, pf)) = prev { tot += 0.5 * (f + pf) * (u - pu); }
        prev = Some((u, f));
    }
    tot
}
fn main() {
    let left_t = [1.0, 0.75, 0.5, 0.25, 0.09, 0.04, 0.01, 0.0025];
    let (a_tree, edge, gap) = tree(2000, 400, None, &left_t);
    let n = 200; let taus: Vec<f64> = (0..=n).map(|i| T * (i as f64 / n as f64).powi(2)).collect();
    let mut bs = vec![K];
    for i in 1..=n {
        let hi = bs[i - 1]; let bsr = &bs;
        let b = root(&|b: f64| K - b - euro(b, taus[i]) - prem(b, &taus, bsr, b, i), 40.0, hi); bs.push(b);
    }
    let b_int = |t: f64| { // boundary at t years left, linear between grid dates
        let i = (0..n).filter(|&k| taus[k] <= t).max().unwrap(); let w = (t - taus[i]) / (taus[i + 1] - taus[i]);
        bs[i] + w * (bs[i + 1] - bs[i]) };
    let b1 = bs[n];
    let v_int = |s: f64| -> f64 { // price anywhere: Simpson in v, where u = v^2 years from now
        if s <= b1 { return K - s; }
        let m = 800; let hv = T.sqrt() / m as f64; let mut tot = 0.0;
        for k in 1..=m {
            let u = (k as f64 * hv).powi(2); let (d1, d2) = d12(s, b_int(T - u), u);
            let f = R * K * (-R * u).exp() * nc(-d2) - Q * s * (-Q * u).exp() * nc(-d1);
            let wt = if k % 2 == 1 { 4.0 } else if k < m { 2.0 } else { 1.0 };
            tot += wt * f * 2.0 * k as f64 * hv;
        }
        euro(s, T) + tot * hv / 3.0 };
    let a_int = v_int(S0);
    // ---- road 3: implicit grid in log-price; PSOR solves the complementarity problem each step
    let (dx, nt, w) = (0.005, 1000, 1.5);
    let sg: Vec<f64> = (-500..=400).map(|k| S0 * (k as f64 * dx).exp()).collect(); let mm = sg.len() - 1;
    let g: Vec<f64> = sg.iter().map(|s| (K - s).max(0.0)).collect();
    let dt = T / nt as f64; let a = 0.5 * SIG * SIG * dt / (dx * dx); let bb = (R - Q - 0.5 * SIG * SIG) * dt / (2.0 * dx);
    let (dn, up, dg) = (a - bb, a + bb, 1.0 + 2.0 * a + R * dt);
    let mut v = g.clone(); let mut rhs = v.clone();
    for _ in 0..nt {
        rhs = v.clone();
        loop {
            let mut err: f64 = 0.0;
            for k in 1..mm {
                let y = g[k].max(v[k] + w * ((rhs[k] + dn * v[k - 1] + up * v[k + 1]) / dg - v[k]));
                err = err.max((y - v[k]).abs()); v[k] = y;
            }
            if err < 1e-11 { break; }
        }
    }
    let gapc = (1..mm).map(|k| (v[k] - g[k]).min(dg * v[k] - dn * v[k - 1] - up * v[k + 1] - rhs[k]).abs()).fold(0.0, f64::max);
    let v_grid = |s: f64| { let k = ((s / sg[0]).ln() / dx) as usize; let f = (s - sg[k]) / (sg[k + 1] - sg[k]); v[k] + f * (v[k + 1] - v[k]) };
    let a_grid = v_grid(S0);
    let jb = (0..=mm).filter(|&k| sg[k] < K && v[k] - g[k] < 1e-9).max().unwrap(); let b_grid = sg[jb];
    // ---- smooth pasting at t = 0: slopes by nudging, and the curvature balance at the boundary
    let h = 0.05;
    let slope = |f: &dyn Fn(f64) -> f64, s: f64| (f(s + h) - f(s - h)) / (2.0 * h);
    let eu_delta = |s: f64| -(-Q * T).exp() * nc(-d12(s, K, T).0);
    let side: Vec<f64> = [2.0, 1.0, 0.5].iter().map(|e| (v_int(b1 + e) - (K - b1)) / e).collect();
    let bal_int = 0.5 * SIG * SIG * b1 * b1 * (v_int(b1 + 0.75) - 2.0 * v_int(b1 + 0.5) + v_int(b1 + 0.25)) / 0.0625;
    let j = jb + 1; let sl: Vec<f64> = [j - 1, j].iter().map(|&i| (v[i + 1] - v[i]) / (sg[i + 1] - sg[i])).collect();
    let bal_grid = 0.5 * SIG * SIG * b1 * b1 * (sl[1] - sl[0]) / (0.5 * (sg[j + 1] - sg[j - 1]));
    let c = R - Q - 0.5 * SIG * SIG; let beta = (-c - (c * c + 2.0 * SIG * SIG * R).sqrt()) / (SIG * SIG);
    let b_perp = beta * K / (beta - 1.0);
    // ---- what breaks: exercise rules that are not the free boundary, priced on the same tree
    let cross = |t: f64| root(&|s: f64| euro(s, t) - (K - s), 20.0, K - 1e-9);
    let wrong = [tree(2000, 0, Some(&|_t: f64| b1), &[]).0, tree(2000, 0, Some(&|_t: f64| b_perp), &[]).0,
                 tree(2000, 0, Some(&cross), &[]).0];

    println!("American put today   tree {:.6}   integral {:.6}   grid {:.6}", a_tree, a_int, a_grid);
    println!("European put {:.6}   early-exercise premium {:.6}", euro(S0, T), a_int - euro(S0, T));
    println!("boundary   years left   tree node   integral");
    for (t, e) in left_t.iter().zip(edge.iter()) { println!("           {:10.4} {:11.2} {:10.2}", t, e, b_int(*t)); }
    println!("           {:10.4} {:11.2} {:10.2}", 0.0, K, K);
    println!("tree node spacing factor u^2 {:.6}   grid exercise node {:.3}", gap, b_grid);
    println!("grid complementarity gap {:.1e}   perpetual floor {:.3}", gapc, b_perp);
    println!("today       S    value    K-S  delta int  delta grid  delta Euro");
    for s in [70.0, 74.0, 78.0, 82.0, 86.0, 90.0, 94.0, 98.0] {
        println!("       {:6.1} {:8.3} {:6.2} {:10.4} {:11.4} {:11.4}", s, v_int(s), K - s, slope(&v_int, s), slope(&v_grid, s), eu_delta(s));
    }
    println!("chart delta American {}", (0..8).map(|i| format!("{:.2}", slope(&v_int, 70.0 + 4.0 * i as f64))).collect::<Vec<_>>().join(" "));
    println!("chart delta European {}", (0..8).map(|i| format!("{:.2}", eu_delta(70.0 + 4.0 * i as f64))).collect::<Vec<_>>().join(" "));
    println!("slope from B out by 2, 1, 0.5:  {:.4}  {:.4}  {:.4}", side[0], side[1], side[2]);
    println!("European delta at B {:.4}", eu_delta(b1));
    println!("balance at B: integral {:.4}  grid {:.4}  rK - qB {:.4}", bal_int, bal_grid, R * K - Q * b1);
    println!("wrong: freeze today's B {:.6}", wrong[0]);
    println!("wrong: perpetual floor  {:.6}", wrong[1]);
    println!("wrong: European cross   {:.6}   (cross today {:.3})", wrong[2], cross(T));

    assert!((euro(S0, T) - 6.330080627550).abs() < 1e-9, "series CDF against the pilot card's European put");
    assert!((a_int - a_tree).abs() < 0.002 && (a_grid - a_tree).abs() < 0.005, "three roads, one price");
    assert!(left_t.iter().zip(edge.iter()).all(|(t, e)| (e - b_int(*t)).abs() < e * (gap - 1.0)), "tree within one node");
    assert!((b_grid - b1).abs() < b_grid * (dx.exp() - 1.0), "grid within one node");
    assert!(left_t.windows(2).all(|p| b_int(p[0]) < b_int(p[1])) && b_perp < b1 && K - bs[1] < 0.5, "rises to K");
    let gp: Vec<f64> = side.iter().map(|x| 1.0 + x).collect();
    assert!(gp[0] / gp[1] > 1.8 && gp[0] / gp[1] < 2.2 && gp[1] / gp[2] > 1.8 && gp[1] / gp[2] < 2.2, "no corner");
    assert!((slope(&v_int, 78.0) - slope(&v_grid, 78.0)).abs() < 0.005 && eu_delta(b1) > -0.9, "pasting");
    assert!((bal_int / (R * K - Q * b1) - 1.0).abs() < 0.01 && (bal_grid / (R * K - Q * b1) - 1.0).abs() < 0.01);
    assert!(gapc < 1e-9 && wrong.iter().all(|&x| x < a_tree - 0.1), "complementarity holds; wrong rules lose");
    println!("ALL CHECKS PASS");
}
