// Callable bond and yield to worst -- the same check as callable_bonds_and_yield_to_worst_check.py, in Rust.
// Std only, no crates.  Rungs are stored in vectors at index j + jm.  Roads: (1) tree with min(100, keep);
// (2) curve bond minus the issuer's option; (3) forward ledger; (4) Jamshidian.  Yields: bisection and Newton.
use std::collections::HashSet;
const F: f64 = 100.0; const CPN: f64 = 6.0; const K: f64 = 100.0; const A: f64 = 0.2; const SIG: f64 = 0.01;
fn d(t: f64, sh: f64) -> f64 { (-(0.03 + sh) * t - 0.002 * t * t).exp() }
fn phi(x: f64) -> f64 { (-0.5 * x * x).exp() / (2.0 * std::f64::consts::PI).sqrt() }
fn ncdf(x: f64) -> f64 {
    if x.abs() > 10.0 { return if x > 0.0 { 1.0 } else { 0.0 }; }
    let h = x / 2000.0;
    0.5 + h / 3.0 * (0..=2000).map(|i| (if i == 0 || i == 2000 { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }) * phi(i as f64 * h)).sum::<f64>()
}
fn weights(offs: [i64; 3], m: f64) -> [f64; 3] {
    let (s2, mut out) = (1.0 / 3.0 + m * m, [0.0; 3]);
    for (n, &a) in offs.iter().enumerate() {
        let rest: Vec<f64> = offs.iter().filter(|&&o| o != a).map(|&o| o as f64).collect();
        let (b, c, af) = (rest[0], rest[1], a as f64);
        out[n] = (s2 - (b + c) * m + b * c) / ((af - b) * (af - c));
    }
    out
}
struct Out { s: f64, c: f64, o: f64, led: f64, ncalls: usize, layer5: Vec<(f64, f64, f64)>, jm: i64, dx: f64 }
fn price(n: usize, sig: f64, sh: f64, dates: &[usize], below: Option<f64>) -> Out {
    let dt = 10.0 / n as f64; let m = (-A * dt).exp() - 1.0;
    let dx = (3.0 * sig * sig * (1.0 - (-2.0 * A * dt).exp()) / (2.0 * A)).sqrt();
    let jm = (0.184 / -m) as i64 + 1; let w = (2 * jm + 1) as usize;
    let ix = |j: i64| (j + jm) as usize;
    let br: Vec<Vec<(i64, f64)>> = (-jm..=jm).map(|j| {
        let offs = if j == jm { [0, -1, -2] } else if j == -jm { [2, 1, 0] } else { [1, 0, -1] };
        let p = weights(offs, j as f64 * m);
        (0..3).map(|t| (j + offs[t], p[t])).collect()
    }).collect();
    let mut q = vec![0.0; w]; q[ix(0)] = 1.0; let mut al = Vec::new();
    for i in 0..n {
        let r = (i as i64).min(jm);
        let base: f64 = (-r..=r).map(|j| q[ix(j)] * (-(j as f64) * dx * dt).exp()).sum();
        al.push((base / d((i + 1) as f64 * dt, sh)).ln() / dt);
        let mut nq = vec![0.0; w];
        for j in -r..=r { for &(k, p) in &br[ix(j)] { nq[ix(k)] += q[ix(j)] * p * (-(al[i] + j as f64 * dx) * dt).exp(); } }
        q = nq;
    }
    let st = n / 10;
    let (mut sv, mut cv, mut ov) = (vec![F + CPN; w], vec![F + CPN; w], vec![0.0; w]);
    let mut calls = HashSet::new(); let mut layer5 = Vec::new();
    for i in (0..n).rev() {
        let cpn = if i > 0 && i % st == 0 { CPN } else { 0.0 };
        let can = i % st == 0 && dates.contains(&(i / st));
        let (mut ns, mut nc, mut no) = (vec![0.0; w], vec![0.0; w], vec![0.0; w]);
        let r = (i as i64).min(jm);
        for j in -r..=r {
            let rate = al[i] + j as f64 * dx; let disc = (-rate * dt).exp();
            let roll = |v: &Vec<f64>| disc * br[ix(j)].iter().map(|&(k, p)| p * v[ix(k)]).sum::<f64>();
            let (s, c, o) = (roll(&sv), roll(&cv), roll(&ov));
            ns[ix(j)] = cpn + s;
            nc[ix(j)] = match below {
                Some(b) => cpn + if can && rate < b { K } else { c },
                None => cpn + if can { K.min(c) } else { c },
            };
            no[ix(j)] = if can { (s - K).max(o) } else { o };
            if can && c > K { calls.insert((i, j)); }
            if i == 5 * st { layer5.push((100.0 * rate, s, K.min(c))); }
        }
        sv = ns; cv = nc; ov = no;
    }
    let (mut led, mut live) = (0.0, vec![0.0; w]); live[ix(0)] = 1.0;
    for i in 0..=n {
        if i > 0 && i % st == 0 { led += CPN * live.iter().sum::<f64>(); }
        if i == n { led += F * live.iter().sum::<f64>(); break; }
        let mut nl = vec![0.0; w]; let r = (i as i64).min(jm);
        for j in -r..=r {
            if calls.contains(&(i, j)) { led += K * live[ix(j)]; continue; }
            for &(k, p) in &br[ix(j)] { nl[ix(k)] += live[ix(j)] * p * (-(al[i] + j as f64 * dx) * dt).exp(); }
        }
        live = nl;
    }
    Out { s: sv[ix(0)], c: cv[ix(0)], o: ov[ix(0)], led, ncalls: calls.len(), layer5, jm, dx }
}
fn jamshidian(t: f64) -> (f64, f64) {
    let b = |s: f64, u: f64| (1.0 - (-A * (u - s)).exp()) / A;
    let lna = |s: f64, u: f64| (d(u, 0.0) / d(s, 0.0)).ln() + b(s, u) * (0.03 + 0.004 * s)
        - SIG * SIG / (4.0 * A) * (1.0 - (-2.0 * A * s).exp()) * b(s, u).powi(2);
    let cf: Vec<(f64, f64)> = ((t as usize + 1)..=10).map(|u| (u as f64, CPN + if u == 10 { F } else { 0.0 })).collect();
    let bond = |r: f64| cf.iter().map(|&(u, c)| c * (lna(t, u) - b(t, u) * r).exp()).sum::<f64>();
    let (mut lo, mut hi) = (-1.0, 1.0);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if bond(mid) > K { lo = mid } else { hi = mid } }
    let mut tot = 0.0;
    for &(u, c) in &cf {
        let x = (lna(t, u) - b(t, u) * lo).exp();
        let sp = SIG * ((1.0 - (-2.0 * A * t).exp()) / (2.0 * A)).sqrt() * b(t, u);
        let h = (d(u, 0.0) / (x * d(t, 0.0))).ln() / sp + sp / 2.0;
        tot += c * (d(u, 0.0) * ncdf(h) - x * d(t, 0.0) * ncdf(h - sp));
    }
    (tot, 100.0 * lo)
}
fn fixed(e: i32, y: f64) -> f64 { (1..=e).map(|t| CPN / (1.0 + y).powi(t)).sum::<f64>() + F / (1.0 + y).powi(e) }
fn y_bisect(e: i32, p: f64) -> f64 {
    let (mut lo, mut hi) = (-0.5, 1.0);
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if fixed(e, mid) > p { lo = mid } else { hi = mid } }
    (lo + hi) / 2.0
}
fn y_newton(e: i32, p: f64) -> f64 {
    let mut y: f64 = 0.05;
    for _ in 0..50 {
        let dp = -(1..=e).map(|t| t as f64 * CPN / (1.0 + y).powi(t + 1)).sum::<f64>() - e as f64 * F / (1.0 + y).powi(e + 1);
        y -= (fixed(e, y) - p) / dp;
    }
    y
}
fn main() {
    let all = [5, 6, 7, 8, 9];
    let r0 = price(400, SIG, 0.0, &all, None); let (s0, c0, o0) = (r0.s, r0.c, r0.o);
    let curve = (1..=10).map(|t| CPN * d(t as f64, 0.0)).sum::<f64>() + F * d(10.0, 0.0);
    let eur = s0 - price(400, SIG, 0.0, &[5], None).c; let (jam, rstar) = jamshidian(5.0);
    let sched: Vec<f64> = (5..=10).map(|e| (1..=e).map(|t| CPN * d(t as f64, 0.0)).sum::<f64>() + F * d(e as f64, 0.0)).collect();
    let smin = sched.iter().cloned().fold(f64::INFINITY, f64::min);
    let flat = price(400, 0.0, 0.0, &all, None).c;
    println!("{:<40} 400 {} {:.6}", "tree: steps, edge rung, rung spacing %", r0.jm, 100.0 * r0.dx);
    let sd = (1..=10).map(|t| d(t as f64, 0.0)).sum::<f64>();
    println!("{:<40} {:.6} {:.6} {:.6} {:.6}", "curve: D(10), sum D(1..10), 6x, 100xD(10)", d(10.0, 0.0), sd, 6.0 * sd, 100.0 * d(10.0, 0.0));
    let rows = [("1 straight bond, from the curve", curve), ("  straight bond, rolled back on tree", s0),
        ("1 callable, tree, 400 steps", c0), ("  callable, tree, 100 steps", price(100, SIG, 0.0, &all, None).c),
        ("  callable, tree, 200 steps", price(200, SIG, 0.0, &all, None).c),
        ("2 issuer's call option, own recursion", o0), ("  straight minus option", s0 - o0),
        ("3 callable, forward ledger", r0.led), ("4 year-5-only call, tree", eur),
        ("  year-5-only call, Jamshidian", jam), ("  critical rate r* at year 5, %", rstar),
        ("  Bermudan call minus year-5-only call", o0 - eur),
        ("zero vol: callable on tree", flat), ("zero vol: cheapest fixed schedule", smin)];
    for (lab, v) in rows.iter() { println!("{:<40} {:12.6}", lab, v); }
    println!("{:<40} {}", "call nodes on the 400-step tree", r0.ncalls);
    println!("fixed schedules on the curve, called at 5..9, maturity 10:");
    println!("  {}", sched.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" "));
    let ys: Vec<(f64, f64)> = (5..=10).map(|e| (y_bisect(e, c0), y_newton(e, c0))).collect();
    println!("yields at the model price {:.6}, percent, bisection | Newton:", c0);
    for (n, &(yb, yn)) in ys.iter().enumerate() {
        let lab = if n < 5 { format!("to call, year {}", n + 5) } else { "to maturity, year 10".to_string() };
        println!("  {:<22} {:.6}  {:.6}", lab, 100.0 * yb, 100.0 * yn);
    }
    let (wi, ytw) = ys.iter().enumerate().fold((0, f64::INFINITY), |a, (n, &(yb, _))| if yb < a.1 { (n, yb) } else { a }); let v5 = (1.0 + ytw).powi(-5);
    println!("{:<40} {:.6} {}", "yield to worst %, and its year", 100.0 * ytw, 5 + wi);
    println!("{:<40} {:.6} {:.6} {:.6} {:.6}", "  at it: (1+y)^-5, a_5, 6 a_5, 100 v^5", v5, (1.0 - v5) / ytw, 6.0 * (1.0 - v5) / ytw, 100.0 * v5);
    for p in [100.0, 95.0] {
        let yv: Vec<f64> = (5..=10).map(|e| y_bisect(e, p)).collect();
        let wy = yv.iter().enumerate().fold((0, f64::INFINITY), |a, (n, &y)| if y < a.1 { (n, y) } else { a }).0;
        println!("at price {:.2}: yields % {}  worst year {}", p, yv.iter().map(|y| format!("{:.4}", 100.0 * y)).collect::<Vec<_>>().join(" "), 5 + wy);
    }
    println!("{:<40} {:12.6}", "wrong: ignore the call (straight price)", s0);
    println!("{:<40} {:12.6}", "wrong: call whenever rate < 6%", price(400, SIG, 0.0, &all, Some(0.06)).c);
    println!("{:<40} {:12.6}", "wrong: only the first call date", s0 - eur);
    println!("{:<40} {:12.6}", "wrong: quote yield to maturity, %", 100.0 * ys[5].0);
    let mut g = Vec::new();
    for (lab, sig, sh) in [("curve -1%", SIG, -0.01), ("curve +1%", SIG, 0.01), ("vol 0.5%", 0.005, 0.0), ("vol 2%", 0.02, 0.0)] {
        let r = price(400, sig, sh, &all, None); g.push((r.s, r.c));
        println!("{:<40} {:10.4} {:10.4}", format!("greeks: {}, straight | callable", lab), r.s, r.c);
    }
    println!("{:<40} {:10.4}", "effective duration, straight", (g[0].0 - g[1].0) / (2.0 * s0 * 0.01));
    println!("{:<40} {:10.4}", "effective duration, callable", (g[0].1 - g[1].1) / (2.0 * c0 * 0.01));
    println!("chart, year 5 after coupon: rate %, straight, callable (rungs -16 to 16, every 4th)");
    let pts: Vec<&(f64, f64, f64)> = r0.layer5[(r0.jm - 16) as usize..=(r0.jm + 16) as usize].iter().step_by(4).collect();
    println!("  {}", pts.iter().map(|p| format!("{:7.2}", p.0)).collect::<Vec<_>>().join(" "));
    println!("  {}", pts.iter().map(|p| format!("{:7.2}", p.1)).collect::<Vec<_>>().join(" "));
    println!("  {}", pts.iter().map(|p| format!("{:7.2}", p.2)).collect::<Vec<_>>().join(" "));
    assert!((s0 - curve).abs() < 1e-9, "tree must reprice the straight bond the curve prices");
    assert!((r0.led - c0).abs() < 1e-9, "forward ledger vs rollback");
    assert!((s0 - o0 - c0).abs() < 1e-9, "straight minus the separately rolled option vs rollback");
    assert!((eur - jam).abs() < 5e-4, "tree's one-date call vs Jamshidian closed form");
    assert!((flat - smin).abs() < 1e-9, "zero vol: tree equals cheapest fixed schedule");
    assert!(ys.iter().all(|&(yb, yn)| (yb - yn).abs() < 1e-12), "yield by bisection vs Newton");
    assert!((5..=10).all(|e| (y_newton(e, 100.0) - 0.06).abs() < 1e-12), "at par every yield is the coupon rate");
    println!("ALL CHECKS PASS");
}
