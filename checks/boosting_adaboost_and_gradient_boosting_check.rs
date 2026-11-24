// Boosting -- the same check as boosting_adaboost_and_gradient_boosting_check.py, in Rust.
// Standard library only, no crates.  Same toy orders, same SplitMix64 data (seed 2026).
// nsum is compensated (Neumaier) summation, the way Python's sum() adds floats.
#[derive(Clone, Copy)]
struct St { e: f64, j: usize, c: usize, s: f64 }
struct Round { st: St, e: f64, a: f64, z: f64, pz: f64, g2: f64, f: Vec<f64>, w: Vec<f64>, ft: Vec<f64> }
type Rep<'a> = Option<&'a dyn Fn(usize, &St, f64, f64, &[f64], &[f64], f64, &[f64])>;
fn nsum<I: IntoIterator<Item = f64>>(it: I) -> f64 {
    let (mut s, mut c) = (0.0f64, 0.0f64);
    for x in it { let t = s + x; if s.abs() >= x.abs() { c += (s - t) + x } else { c += (x - t) + s }; s = t; }
    if c != 0.0 && c.is_finite() { s + c } else { s }
}
fn splitmix64(s: &mut u64) -> u64 {
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn best_stump(cols: &[Vec<usize>], y: &[f64], w: &[f64], nv: usize) -> St {
    let mut best = St { e: 2.0, j: 0, c: 0, s: 1.0 };
    for (j, col) in cols.iter().enumerate() {
        let (mut wp, mut wm, mut cnt) = (vec![0.0; nv], vec![0.0; nv], vec![0usize; nv]);
        for i in 0..col.len() { cnt[col[i]] += 1; if y[i] > 0.0 { wp[col[i]] += w[i] } else { wm[col[i]] += w[i] } }
        let (mut below_p, mut above_m, tot) = (0.0, nsum(wm.iter().copied()), nsum(wp.iter().copied()) + nsum(wm.iter().copied()));
        for c in 0..nv {
            if cnt[c] > 0 {
                for (s, e) in [(1.0, below_p + above_m), (-1.0, tot - below_p - above_m)] {
                    if e < best.e - 1e-12 { best = St { e, j, c, s } }
                }
            }
            below_p += wp[c]; above_m -= wm[c];
        }
    }
    best
}
fn h(st: &St, x: &[usize]) -> f64 { if x[st.j] >= st.c { st.s } else { -st.s } }
fn name(st: &St, names: &[&str], lo: &[usize]) -> String {
    if st.c == lo[st.j] { return format!("every order {}", if st.s > 0.0 { "returned" } else { "kept" }) }
    format!("{}{}{}", names[st.j], if st.s > 0.0 { ">=" } else { "<" }, st.c)
}
fn err(f: &[f64], y: &[f64]) -> f64 { f.iter().zip(y).filter(|(a, b)| *a * *b <= 0.0).count() as f64 / y.len() as f64 }
fn cols_of(x: &[Vec<usize>]) -> Vec<Vec<usize>> { (0..x[0].len()).map(|j| x.iter().map(|r| r[j]).collect()).collect() }
fn adaboost(x: &[Vec<usize>], y: &[f64], tmax: usize, nv: usize, report: Rep, sign: f64, half: f64, xt: &[Vec<usize>]) -> Vec<Round> {
    let (n, cols) = (x.len(), cols_of(x));
    let (mut w, mut f, mut ft) = (vec![1.0 / n as f64; n], vec![0.0; n], vec![0.0; xt.len()]);
    let (mut pz, mut g2, mut hist) = (1.0, 0.0, Vec::new());
    for t in 1..=tmax {
        let st = best_stump(&cols, y, &w, nv); let e = st.e;
        let a = if e > 0.0 && e < 0.5 { half * ((1.0 - e) / e).ln() } else { 0.0 };
        let hv: Vec<f64> = x.iter().map(|r| h(&st, r)).collect();
        let new: Vec<f64> = (0..n).map(|i| w[i] * (-sign * a * y[i] * hv[i]).exp()).collect(); let z = nsum(new.iter().copied());
        if let Some(rep) = report { rep(t, &st, e, a, &w, &hv, z, &f) }
        w = new.iter().map(|v| v / z).collect(); pz *= z; g2 += (0.5 - e) * (0.5 - e);
        f = (0..n).map(|i| f[i] + a * hv[i]).collect();
        ft = (0..xt.len()).map(|i| ft[i] + a * h(&st, &xt[i])).collect();
        hist.push(Round { st, e, a, z, pz, g2, f: f.clone(), w: w.clone(), ft: ft.clone() });
    }
    hist
}
fn loss(y: f64, f: f64) -> f64 { (1.0 + (-y * f).exp()).ln() }
// gradient boosting: log loss, regression stumps fitted to minus the gradient; returns per round (j, c, lo, hi, r, F, Ft)
fn gboost(x: &[Vec<usize>], y: &[f64], tmax: usize, nv: usize, eta: f64, xt: &[Vec<usize>]) -> Vec<(usize, usize, f64, f64, Vec<f64>, Vec<f64>, Vec<f64>)> {
    let (n, cols) = (x.len(), cols_of(x));
    let (mut f, mut ft, mut out) = (vec![0.0; n], vec![0.0; xt.len()], Vec::new());
    for _ in 0..tmax {
        let r: Vec<f64> = (0..n).map(|i| y[i] / (1.0 + (y[i] * f[i]).exp())).collect();
        let mut best = (-1.0, 0, 0, 0.0, 0.0);
        for (j, col) in cols.iter().enumerate() {
            let (mut s, mut cnt) = (vec![0.0; nv], vec![0usize; nv]);
            for i in 0..n { s[col[i]] += r[i]; cnt[col[i]] += 1; }
            let (tot, mut sl, mut nl) = (nsum(s.iter().copied()), 0.0, 0usize);
            for c in 0..nv {
                if cnt[c] == 0 { continue }
                let left = if nl > 0 { sl * sl / nl as f64 } else { 0.0 };
                let gain = left + (tot - sl) * (tot - sl) / (n - nl) as f64;
                if gain > best.0 + 1e-12 { best = (gain, j, c, if nl > 0 { sl / nl as f64 } else { 0.0 }, (tot - sl) / (n - nl) as f64) }
                sl += s[c]; nl += cnt[c];
            }
        }
        let (_, j, c, vlo, vhi) = best;
        f = (0..n).map(|i| f[i] + eta * if x[i][j] >= c { vhi } else { vlo }).collect();
        ft = (0..xt.len()).map(|i| ft[i] + eta * if xt[i][j] >= c { vhi } else { vlo }).collect();
        out.push((j, c, vlo, vhi, r, f.clone(), ft.clone()));
    }
    out
}
fn chance(x: &[usize]) -> f64 { let b = |q: bool| -> f64 { if q { 3.0 } else { 0.0 } }; 1.0 / (1.0 + (4.5 - b(x[0] >= 6) - b(x[1] >= 7) - b(x[9] <= 2)).exp()) }
fn main() {
    let toy: Vec<Vec<usize>> = [(1, 50), (1, 60), (1, 80), (1, 90), (3, 30), (4, 30), (4, 40), (4, 60), (5, 60), (6, 40)].iter().map(|p| vec![p.0, p.1]).collect();
    let ty = [-1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0, -1.0, 1.0, 1.0];
    let (tn, tl, ab) = (["items", "price"], [1usize, 30], b"ABCDEFGHIJ");
    let toy_report = |t: usize, st: &St, e: f64, a: f64, w: &[f64], hv: &[f64], z: f64, f: &[f64]| {
        let zof = |al: f64| nsum((0..10).map(|i| w[i] * (-al * ty[i] * hv[i]).exp()));
        let (mut lo, mut hi) = (0.0f64, 3.0f64);            // road 2 for alpha: golden-section search
        for _ in 0..200 { let (c, d) = (hi - 0.618034 * (hi - lo), lo + 0.618034 * (hi - lo)); if zof(c) < zof(d) { hi = d } else { lo = c } }
        let wrong: Vec<usize> = (0..10).filter(|&i| hv[i] != ty[i]).collect(); let share = nsum(wrong.iter().map(|&i| w[i] * a.exp())) / z;
        let ws: String = wrong.iter().map(|&i| ab[i] as char).collect();
        println!("toy round {}: {:<20} error {:.4}  alpha {:.4}  by search {:.4}  Z {:.4}  2sqrt(e(1-e)) {:.4}  wrong after update hold {:.4}  wrong: {}",
            t, name(st, &tn, &tl), e, a, (lo + hi) / 2.0, z, 2.0 * (e * (1.0 - e)).sqrt(), share, ws);
        assert!(((lo + hi) / 2.0 - a).abs() < 1e-6, "alpha formula = the minimum of Z found by search");
        assert!((z - 2.0 * (e * (1.0 - e)).sqrt()).abs() < 1e-12 && (share - 0.5).abs() < 1e-12);
        // road 3, function space: brute-force the stump best aligned with minus the exp-loss gradient
        let grad: Vec<f64> = (0..10).map(|i| -ty[i] * (-ty[i] * f[i]).exp()).collect();
        let mut best: (f64, St) = (f64::NEG_INFINITY, *st);
        for j in 0..2 {
            let mut vals: Vec<usize> = toy.iter().map(|r| r[j]).collect(); vals.sort(); vals.dedup();
            for &c in &vals { for s in [1.0, -1.0] {
                let q = St { e: 0.0, j, c, s }; let v = nsum((0..10).map(|i| -grad[i] * h(&q, &toy[i]))); if v > best.0 { best = (v, q) }
            } }
        }
        assert!((0..10).all(|i| h(&best.1, &toy[i]) == hv[i]), "least weighted error = steepest way down");
    };
    let hist = adaboost(&toy, &ty, 3, 100, Some(&toy_report), 1.0, 0.5, &[]);
    let (a1, f3, pz3) = (hist[0].a, &hist[2].f, hist[2].pz);
    println!("round 1 by hand: grow e^alpha {:.4}  shrink e^-alpha {:.4}  wrong each {:.4}  right each {:.4}  e^(-2*0.2^2) {:.4}  rounds at 0.3 to force 0 errors on 16000: {}", a1.exp(), (-a1).exp(), 1.0 / 6.0, 1.0 / 14.0, (-0.08f64).exp(), (16000f64.ln() / -(2.0 * 0.21f64.sqrt()).ln()) as i64 + 1);
    let expl = nsum((0..10).map(|i| (-ty[i] * f3[i]).exp())) / 10.0;
    let sc: Vec<String> = (0..10).map(|i| format!("{} {:+.4}", ab[i] as char, f3[i])).collect();
    println!("toy scores after 3 rounds: {}", sc.join(" "));
    println!("toy after 3 rounds: training errors {:.1}  bound prod Z {:.4}  mean e^(-yF) {:.4}", err(f3, &ty), pz3, expl);
    assert!((a1 - 0.423649).abs() < 1e-6 && (expl - pz3).abs() < 1e-12 && err(f3, &ty) <= pz3);
    let h100 = adaboost(&toy, &ty, 100, 100, None, 1.0, 0.5, &[]).pop().unwrap();
    println!("toy after 100 rounds: training errors {:.1}  order H holds {:.4} of the weight  bound {:.6}", err(&h100.f, &ty), h100.w[7], h100.pz);
    // ---- what breaks ----
    let flip = &adaboost(&toy, &ty, 2, 100, None, -1.0, 0.5, &[])[1];
    let xs: Vec<Vec<usize>> = vec![vec![0, 0], vec![0, 1], vec![1, 0], vec![1, 1]];
    let xor = &adaboost(&xs, &[-1.0, 1.0, 1.0, -1.0], 1, 2, None, 1.0, 0.5, &[])[0];
    println!("wrong: alpha without the 1/2: Z {:.4}", adaboost(&toy, &ty, 1, 100, None, 1.0, 1.0, &[])[0].z);
    println!("wrong: grow the right orders: round 2 picks {} again, error {:.4}", name(&flip.st, &tn, &tl), flip.e);
    println!("no weak learner (returned if phone xor weekend): best error {:.4}  alpha {:.4}  Z {:.4}", xor.e, xor.a, xor.z);
    // ---- the shop: 20,000 synthetic orders, 12 numbers each stored as a decile 0..9 ----
    let sn = ["items", "price", "past", "gap", "phone", "hour", "code", "dist", "wkend", "age", "news", "viewed"];
    let (mut rng, mut xx, mut yy) = (2026u64, Vec::new(), Vec::new());
    for _ in 0..20000 {
        let x: Vec<usize> = (0..12).map(|_| (splitmix64(&mut rng) % 10) as usize).collect();
        yy.push(if (splitmix64(&mut rng) >> 11) as f64 / 2f64.powi(53) < chance(&x) { 1.0 } else { -1.0 }); xx.push(x);
    }
    let (xtr, ytr, xte, yte) = (&xx[..16000], &yy[..16000], &xx[16000..], &yy[16000..]);
    let bayes = nsum((0..1000).map(|k| { let mut x = vec![0usize; 12]; x[0] = k / 100; x[1] = k / 10 % 10; x[9] = k % 10;
        chance(&x).min(1.0 - chance(&x)) })) / 1000.0;
    let ideal = err(&xte.iter().map(|x| chance(x) - 0.5).collect::<Vec<_>>(), yte);
    println!("shop: returned {} of 20000  best possible error {:.4}  ideal rule on test {:.4}", yy.iter().filter(|v| **v > 0.0).count(), bayes, ideal);
    let check = [1usize, 2, 3, 5, 10, 20, 50, 200];
    println!(" round  stump        error   train   prod Z  e^-2sum(g^2)  test");
    let ada = adaboost(xtr, ytr, 200, 10, None, 1.0, 0.5, xte);
    for (k, r) in ada.iter().enumerate() { let t = k + 1;
        assert!(err(&r.f, ytr) <= r.pz && r.pz <= (-2.0 * r.g2).exp(), "training error <= prod Z <= exp(-2 sum gamma^2)");
        if check.contains(&t) {
            let u: Vec<f64> = (0..16000).map(|i| (-ytr[i] * r.f[i]).exp() / (16000.0 * r.pz)).collect();
            assert!((nsum(u.iter().copied()) - 1.0).abs() < 1e-9 && (0..16000).all(|i| (u[i] - r.w[i]).abs() < 1e-12));
            println!("{:>6}  {:<11} {:.4}  {:.4}  {:.4}  {:.4}       {:.4}", t, name(&r.st, &sn, &[0; 12]), r.e, err(&r.f, ytr), r.pz, (-2.0 * r.g2).exp(), err(&r.ft, yte));
        }
    }
    let ada_test = err(&ada[199].ft, yte);
    let g1 = &gboost(&toy, &ty, 1, 100, 1.0, &[])[0];
    println!("gradient boosting, toy round 1: residuals +-{:.4}  split {}>={}  leaves {:+.4} {:+.4}", g1.4[0].abs(), tn[g1.0], g1.1, g1.2, g1.3);
    let gb = gboost(xtr, ytr, 200, 10, 0.5, xte);
    println!(" round  split     train log loss  train   test");
    for (k, g) in gb.iter().enumerate() {
        if check.contains(&(k + 1)) {
            let ll = nsum((0..16000).map(|i| loss(ytr[i], g.5[i]))) / 16000.0;
            println!("{:>6}  {:<9} {:.4}          {:.4}  {:.4}", k + 1, format!("{}>={}", sn[g.0], g.1), ll, err(&g.5, ytr), err(&g.6, yte));
        }
    }
    let fd = (0..16000).map(|i| { let (y, f) = (ytr[i], gb[198].5[i]);
        (-(loss(y, f + 1e-6) - loss(y, f - 1e-6)) / 2e-6 - gb[199].4[i]).abs() }).fold(0.0, f64::max);
    println!("residual vs finite-difference slope, worst gap {:.2e}", fd);
    assert!(fd < 1e-6, "residuals are minus the slope of the loss");
    assert!((ada_test - ideal).abs() < 0.02 && (err(&gb[199].6, yte) - ideal).abs() < 0.02, "both near the ideal rule");
    println!("ALL CHECKS PASS");
}
