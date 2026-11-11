// Value iteration and policy iteration on a reservoir, checked against each other,
// against the Bellman equation and against every policy of a small reservoir.
use std::sync::atomic::{AtomicUsize, Ordering::Relaxed};

const RAIN: [f64; 4] = [0.2, 0.3, 0.3, 0.2]; // chance of 0, 1, 2, 3 bands of inflow in a month
static OPS: AtomicUsize = AtomicUsize::new(0); // multiply-adds, counted as the work is done

fn acts(s: usize) -> Vec<usize> { (0..3).filter(|&a| a <= s).collect() } // release 0, 1 or 2 bands
fn moves(n: usize, s: usize, a: usize) -> Vec<(f64, usize, usize)> { // (chance, next band, spilled)
    RAIN.iter().enumerate().map(|(w, &p)| { let t = s - a + w; (p, t.min(n - 1), t.saturating_sub(n - 1)) }).collect()
}
fn reward(n: usize, s: usize, a: usize) -> f64 { // £k: sales, low-flow fine, flood damage
    let spill: f64 = moves(n, s, a).iter().map(|&(p, _, x)| p * x as f64).sum();
    (a * (10 + s)) as f64 - if a == 0 { 7.0 } else { 0.0 } - 40.0 * spill
}
fn q(n: usize, v: &[f64], s: usize, a: usize, g: f64) -> f64 {
    OPS.fetch_add(4, Relaxed);
    reward(n, s, a) + g * moves(n, s, a).iter().map(|&(p, t, _)| p * v[t]).sum::<f64>()
}
fn greedy(n: usize, v: &[f64], g: f64, old: Option<&[usize]>) -> Vec<usize> { // keep old on a tie
    (0..n).map(|s| {
        let qs: Vec<(usize, f64)> = acts(s).into_iter().map(|a| (a, q(n, v, s, a, g))).collect();
        let best = qs.iter().map(|x| x.1).fold(f64::NEG_INFINITY, f64::max);
        match old {
            Some(o) if qs.iter().any(|x| x.0 == o[s] && x.1 >= best - 1e-9) => o[s],
            _ => qs.iter().filter(|x| x.1 == best).map(|x| x.0).max().unwrap(),
        }
    }).collect()
}
fn backup(n: usize, v: &[f64], g: f64) -> Vec<f64> {
    (0..n).map(|s| acts(s).into_iter().map(|a| q(n, v, s, a, g)).fold(f64::NEG_INFINITY, f64::max)).collect()
}
fn solve(a: &[Vec<f64>], b: &[f64]) -> Vec<f64> { // Gaussian elimination with partial pivoting
    let n = b.len();
    let mut m: Vec<Vec<f64>> = a.iter().zip(b).map(|(r, &bi)| { let mut r = r.clone(); r.push(bi); r }).collect();
    for i in 0..n {
        let mut piv = i;
        for r in i..n { if m[r][i].abs() > m[piv][i].abs() { piv = r; } } m.swap(i, piv);
        for r in i + 1..n {
            let f = m[r][i] / m[i][i];
            for c in i..=n { let t = m[i][c]; m[r][c] -= f * t; }
            OPS.fetch_add(n + 1 - i, Relaxed);
        }
    }
    let mut x = vec![0.0; n];
    for i in (0..n).rev() {
        let s: f64 = (i + 1..n).map(|c| m[i][c] * x[c]).sum();
        x[i] = (m[i][n] - s) / m[i][i]; OPS.fetch_add(n - i, Relaxed);
    }
    x
}
fn chain(n: usize, pol: &[usize]) -> Vec<Vec<f64>> { // transition table under a fixed rule
    let mut p = vec![vec![0.0; n]; n];
    for s in 0..n { for (pr, t, _) in moves(n, s, pol[s]) { p[s][t] += pr; } }
    p
}
fn longrun(n: usize, pol: &[usize]) -> (Vec<f64>, f64) { // stationary d: d P = d, adds to 1
    let p = chain(n, pol);
    let mut a: Vec<Vec<f64>> = (0..n - 1).map(|i| (0..n).map(|j| p[j][i] - if i == j { 1.0 } else { 0.0 }).collect()).collect();
    a.push(vec![1.0; n]);
    let mut b = vec![0.0; n]; b[n - 1] = 1.0;
    let d = solve(&a, &b); let avg = (0..n).map(|s| d[s] * reward(n, s, pol[s])).sum();
    (d, avg)
}
fn evaluate(n: usize, pol: &[usize], g: f64) -> Vec<f64> { // solve V = r + g P V exactly
    let p = chain(n, pol);
    let a: Vec<Vec<f64>> = (0..n).map(|i| (0..n).map(|j| (if i == j { 1.0 } else { 0.0 }) - g * p[i][j]).collect()).collect();
    solve(&a, &(0..n).map(|s| reward(n, s, pol[s])).collect::<Vec<_>>())
}
fn policy_iteration(n: usize, start: Vec<usize>, g: f64) -> Vec<(Vec<usize>, Vec<f64>, usize)> {
    let (mut pol, mut rounds) = (start, Vec::new());
    while rounds.len() < 50 { // a cap: a correct method needs far fewer
        let v = evaluate(n, &pol, g); let new = greedy(n, &v, g, Some(&pol));
        let ch = (0..n).filter(|&s| new[s] != pol[s]).count();
        rounds.push((pol.clone(), v, ch));
        if new == pol { break; }
        pol = new;
    }
    rounds
}
fn gap(u: &[f64], v: &[f64]) -> f64 { u.iter().zip(v).map(|(a, b)| (a - b).abs()).fold(0.0, f64::max) }
fn value_iteration(n: usize, g: f64, tol: f64, cap: usize) -> Vec<Vec<f64>> {
    let mut hist = vec![vec![0.0; n]];
    while hist.len() <= cap {
        let v = backup(n, hist.last().unwrap(), g);
        let done = gap(&v, hist.last().unwrap()) < tol;
        hist.push(v);
        if done { break; }
    }
    hist
}
fn f1(v: f64) -> String { format!("{:.1}", v) }
fn show(label: &str, vals: &[String]) { println!("{:<46}{}", label, vals.join(" ")); }
fn word(pol: &[usize]) -> String { pol.iter().map(|a| a.to_string()).collect() }
fn ones(n: usize) -> Vec<usize> { (0..n).map(|s| s.min(1)).collect() }

fn main() {
    let (n, g, eps) = (20usize, 0.95f64, 10.0f64);
    let tol = eps * (1.0 - g) / (2.0 * g);
    for b in [10, 19] { show(&format!("rewards at band {} for release 0, 1, 2", b), &(0..3).map(|a| f1(reward(n, b, a))).collect::<Vec<_>>()); }
    // ---- policy iteration from 'release one band whenever there is water' ----
    OPS.store(0, Relaxed); let rounds = policy_iteration(n, ones(n), g);
    let ops_pi = OPS.load(Relaxed);
    let (pol_pi, vstar) = (rounds.last().unwrap().0.clone(), rounds.last().unwrap().1.clone());
    for (k, (pol, v, ch)) in rounds.iter().enumerate() {
        show(&format!("PI round {}: rule, V(10), error, changed", k + 1), &[word(pol), f1(v[10]), f1(gap(v, &vstar)), ch.to_string()]);
    }
    let resid = gap(&backup(n, &vstar, g), &vstar);
    show("PI: Bellman residual max|TV - V|", &[format!("{:.1e}", resid)]);
    // ---- value iteration from V = 0 ----
    OPS.store(0, Relaxed); let hist = value_iteration(n, g, tol, 5000);
    let ops_vi = OPS.load(Relaxed);
    let kk = hist.len() - 1; let vk = hist[kk].clone(); let pol_vi = greedy(n, &vk, g, None);
    let last = gap(&hist[kk], &hist[kk - 1]);
    show("VI: stop when a sweep changes less than", &[format!("{:.4}", tol)]);
    show("VI: sweeps, last change, error to V*", &[kk.to_string(), format!("{:.4}", last), format!("{:.4}", gap(&vk, &vstar))]);
    show("VI: rule after the last sweep", &[word(&pol_vi)]);
    show("VI: bound 0.95/0.05 * last change", &[format!("{:.4}", g / (1.0 - g) * last)]);
    show("VI sweep 1: V at bands 8 to 13", &(8..14).map(|s| f1(hist[1][s])).collect::<Vec<_>>());
    show("VI sweep 2 at band 10: q for release 0, 1, 2", &(0..3).map(|a| format!("{:.2}", q(n, &hist[1], 10, a, g))).collect::<Vec<_>>());
    let errs: Vec<f64> = (0..=kk).map(|k| gap(&hist[k], &vstar)).collect();
    show("VI error ratio, sweeps 1/0, 2/1, 94/93", &[1, 2, kk].iter().map(|&k| format!("{:.4}", errs[k] / errs[k - 1])).collect::<Vec<_>>());
    let marks: Vec<usize> = (0..10).map(|i| 10 * i).collect();
    show("log10 VI error at sweeps 0, 10, ..., 90", &marks.iter().map(|&k| format!("{:.2}", errs[k].log10())).collect::<Vec<_>>());
    show("log10 bound 0.95^k * error(0)", &marks.iter().map(|&k| format!("{:.2}", (g.powf(k as f64) * errs[0]).log10())).collect::<Vec<_>>());
    show("work: VI total, per sweep", &[ops_vi.to_string(), (ops_vi / kk).to_string()]);
    show("work: PI total, per round", &[ops_pi.to_string(), (ops_pi / rounds.len()).to_string()]);
    for k in [0, 1, 4] {
        show(&format!("chart: V, PI round {}, bands 0-19 by 3", k + 1), &(0..20).step_by(3).map(|s| format!("{:.0}", rounds[k].1[s])).collect::<Vec<_>>());
    }
    // ---- long run under the best rule: the stationary distribution d ----
    let (d, avg) = longrun(n, &pol_pi);
    show("long run: share of months holding, 1, 2", &(0..3).map(|a| format!("{:.4}", (0..n).filter(|&s| pol_pi[s] == a).map(|s| d[s]).sum::<f64>())).collect::<Vec<_>>());
    let dv: f64 = (0..n).map(|s| d[s] * vstar[s]).sum();
    show("long run: £k a month, (1-gamma) d.V*", &[format!("{:.4}", avg), format!("{:.4}", (1.0 - g) * dv)]);
    // ---- a 6-band reservoir: every rule listed ----
    let n6 = 6; let mut allp: Vec<Vec<usize>> = vec![vec![]];
    for s in 0..n6 { allp = allp.iter().flat_map(|p| acts(s).into_iter().map(move |a| { let mut p = p.clone(); p.push(a); p })).collect(); }
    let vals: Vec<Vec<f64>> = allp.iter().map(|p| evaluate(n6, p, g)).collect();
    let top: Vec<usize> = (0..vals.len()).filter(|&i| vals.iter().all(|w| (0..n6).all(|s| vals[i][s] >= w[s] - 1e-9))).collect();
    let pi6 = policy_iteration(n6, ones(n6), g).pop().unwrap();
    let vi6 = value_iteration(n6, g, tol, 5000);
    let vi6pol = greedy(n6, vi6.last().unwrap(), g, None);
    show("6 bands: rules listed, best rule", &[allp.len().to_string(), word(&allp[top[0]])]);
    show("6 bands: PI rule, VI rule, VI value error", &[word(&pi6.0), word(&vi6pol), format!("{:.4}", gap(&vals[top[0]], vi6.last().unwrap()))]);
    // ---- what breaks ----
    let early = greedy(n, &hist[10], g, None);
    show("rule after 10 sweeps, worst loss £k", &[word(&early), f1(gap(&evaluate(n, &early, g), &vstar))]);
    let naive = value_iteration(n, g, eps, 5000);
    show("stop at change < 10: sweeps, true error", &[(naive.len() - 1).to_string(), f1(gap(naive.last().unwrap(), &vstar))]);
    let h1 = value_iteration(n, 1.0, tol, 400);
    let ch1: Vec<f64> = [94, 400].iter().map(|&k| gap(&h1[k], &h1[k - 1])).collect();
    let pol1 = greedy(n, h1.last().unwrap(), 1.0, None); let avg1 = longrun(n, &pol1).1;
    show("gamma 1: change at sweeps 94 and 400", &[f1(ch1[0]), format!("{:.4}", ch1[1])]);
    show("gamma 1: rule, its long-run £k a month", &[word(&pol1), format!("{:.4}", avg1)]);
    for gg in [0.9, 0.99] {
        show(&format!("try gamma {}: VI sweeps, PI rounds", gg), &[(value_iteration(n, gg, eps * (1.0 - gg) / (2.0 * gg), 5000).len() - 1).to_string(),
            policy_iteration(n, ones(n), gg).len().to_string()]);
    }
    show("try eps 1: VI sweeps", &[(value_iteration(n, g, 1.0 * (1.0 - g) / (2.0 * g), 5000).len() - 1).to_string()]);
    assert!(pol_vi == pol_pi && rounds.len() < 50); // two methods, one rule
    assert!(resid < 1e-9 && gap(&vk, &vstar) < eps / 2.0); // Bellman certificate; VI's bound
    assert!(top.len() == 1 && allp[top[0]] == pi6.0 && pi6.0 == vi6pol); // enumeration
    assert!((errs[kk] / errs[kk - 1] - g).abs() < 1e-3); // contraction rate
    assert!((avg - (1.0 - g) * dv).abs() < 1e-9); // stationary identity
    assert!(gap(naive.last().unwrap(), &vstar) > eps && h1.len() == 401); // the two failures happen
    assert!((ch1[1] - avg1).abs() < 1e-6); // gamma 1: change = average reward
    println!("ALL CHECKS PASS");
}
