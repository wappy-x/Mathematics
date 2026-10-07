// Backtesting VaR -- the check behind the card.  Rust std only, no crates.
// Own normal CDF (series), own root finder, own integrator, own random numbers.
const N: usize = 250;
const P: f64 = 0.01;
const PI: f64 = std::f64::consts::PI;

fn phi_cdf(x: f64) -> f64 {
    // normal CDF: 1/2 + phi(x) * (x + x^3/3 + x^5/15 + ...)
    let (mut term, mut s, mut k) = (x, x, 1.0);
    while term.abs() > 1e-17 * s.abs().max(1.0) { term *= x * x / (2.0 * k + 1.0); s += term; k += 1.0; }
    0.5 + (-x * x / 2.0).exp() / (2.0 * PI).sqrt() * s
}
fn simpson(f: &dyn Fn(f64) -> f64, a: f64, b: f64, m: usize) -> f64 {
    let h = (b - a) / m as f64;
    let mut s = f(a) + f(b);
    for i in 1..m { s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h); }
    h / 3.0 * s
}
fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    for _ in 0..200 { let mid = (lo + hi) / 2.0; if f(lo) * f(mid) <= 0.0 { hi = mid } else { lo = mid } }
    (lo + hi) / 2.0
}
fn golden_max(f: &dyn Fn(f64) -> f64) -> f64 {
    let (mut lo, mut hi, g) = (1e-12, 1.0 - 1e-12, (5f64.sqrt() - 1.0) / 2.0);
    for _ in 0..200 { let (a, b) = (hi - g * (hi - lo), lo + g * (hi - lo)); if f(a) > f(b) { hi = b } else { lo = a } }
    f((lo + hi) / 2.0)
}
fn xlog(c: usize, q: f64) -> f64 { if c == 0 { 0.0 } else { c as f64 * q.ln() } }
fn lr_uc(k: usize, m: usize, p0: f64) -> f64 {
    let ph = k as f64 / m as f64;
    2.0 * (xlog(k, ph) + xlog(m - k, 1.0 - ph) - xlog(k, p0) - xlog(m - k, 1.0 - p0))
}
fn days(hit: &[usize]) -> Vec<usize> { (1..=N).map(|t| hit.contains(&t) as usize).collect() }
fn counts(seq: &[usize]) -> [usize; 4] {
    let mut c = [0; 4]; for w in seq.windows(2) { c[2 * w[0] + w[1]] += 1; } c
}
fn counts_by_runs(hit: &[usize]) -> [usize; 4] {
    let runs = hit.iter().filter(|&&t| !hit.contains(&(t - 1))).count();
    [N - 1 - hit.len() - runs, runs, runs, hit.len() - runs]
}
fn lr_ind_cc(c: [usize; 4]) -> (f64, f64, [f64; 3]) {
    let [n00, n01, n10, n11] = c;
    let p01 = n01 as f64 / (n00 + n01) as f64;
    let p11 = n11 as f64 / (n10 + n11) as f64;
    let ph = (n01 + n11) as f64 / (N - 1) as f64;
    let markov = xlog(n00, 1.0 - p01) + xlog(n01, p01) + xlog(n10, 1.0 - p11) + xlog(n11, p11);
    let common = xlog(n00 + n10, 1.0 - ph) + xlog(n01 + n11, ph);
    let fixed = xlog(n00 + n10, 1.0 - P) + xlog(n01 + n11, P);
    (2.0 * (markov - common), 2.0 * (markov - fixed), [markov, common, fixed])
}
fn ll(q: f64, pairs: &[(usize, usize)], rows: &[usize]) -> f64 {
    pairs.iter().filter(|(a, _)| rows.contains(a))
        .map(|&(_, b)| b as f64 * q.ln() + (1 - b) as f64 * (1.0 - q).ln()).sum()
}
fn lr_ind_search(seq: &[usize]) -> f64 {
    let pr: Vec<(usize, usize)> = seq.windows(2).map(|w| (w[0], w[1])).collect();
    let markov = golden_max(&|q| ll(q, &pr, &[0])) + golden_max(&|q| ll(q, &pr, &[1]));
    2.0 * (markov - golden_max(&|q| ll(q, &pr, &[0, 1])))
}
fn comb(n: usize, k: usize) -> f64 { (0..k).fold(1.0, |acc, i| acc * (n - i) as f64 / (i + 1) as f64) }
fn prob(q: f64, ks: &[usize]) -> f64 {
    ks.iter().map(|&j| comb(N, j) * q.powi(j as i32) * (1.0 - q).powi((N - j) as i32)).sum()
}
fn zone_table(k: usize) -> &'static str { if k <= 4 { "G" } else if k <= 9 { "Y" } else { "R" } }
fn sci(v: f64) -> String {
    // Python-style 1.234e-06
    let s = format!("{:.3e}", v); let (m, e) = s.split_once('e').unwrap();
    let e: i32 = e.parse().unwrap();
    format!("{}e{}{:02}", m, if e < 0 { '-' } else { '+' }, e.abs())
}
fn join<T: ToString>(v: impl Iterator<Item = T>) -> String { v.map(|x| x.to_string()).collect::<Vec<_>>().join(" ") }
fn main() {
    let iso = [40, 90, 140, 200];
    let run = [40, 41, 42, 43];
    let pmf: Vec<f64> = (0..=N).map(|k| prob(P, &[k])).collect();
    let cdf: Vec<f64> = (0..=N).map(|k| pmf[..=k].iter().sum()).collect();
    let zone_cut = |k: usize| if cdf[k] < 0.95 { "G" } else if cdf[k] < 0.9999 { "Y" } else { "R" };
    let plus = |k: usize| match k { 5 => 0.40, 6 => 0.50, 7 => 0.65, 8 => 0.75, 9 => 0.85, 10.. => 1.00, _ => 0.0 };
    let c1 = bisect(&|x: f64| 2.0 * (1.0 - phi_cdf(x.sqrt())) - 0.05, 0.5, 10.0);
    let tail1 = 2.0 * simpson(&|z: f64| (-z * z / 2.0).exp() / (2.0 * PI).sqrt(), c1.sqrt(), 12.0, 2000);
    let c2 = bisect(&|x: f64| (-x / 2.0).exp() - 0.05, 0.5, 20.0);
    let r2 = c2.sqrt(); // road 2: P(Z1^2 + Z2^2 > c2), Z1 = r2 sin a on the disc, Z2 beyond it
    let tail2 = 2.0 * (1.0 - phi_cdf(r2)) + 4.0 * simpson(&|a: f64| (-(r2 * a.sin()).powi(2) / 2.0).exp() / (2.0 * PI).sqrt() * (1.0 - phi_cdf(r2 * a.cos())) * r2 * a.cos(), 0.0, PI / 2.0, 2000);
    let rej: Vec<usize> = (0..=N).filter(|&k| lr_uc(k, N, P) > c1).collect();
    // splitmix64 random numbers, same seed and stream as the Python
    let (mut state, years) = (20260928u64, 20000usize);
    let mut rnd = || {
        state = state.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (state ^ (state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    };
    let mut sim = vec![0usize; N + 1];
    for _ in 0..years { sim[(0..N).filter(|_| rnd() < P).count()] += 1; }
    let sim_size = rej.iter().map(|&k| sim[k]).sum::<usize>() as f64 / years as f64;
    let (si, sr) = (days(&iso), days(&run));
    let (ci, cr) = (counts(&si), counts(&sr));
    let ((ind_i, cc_i, ll_i), (ind_r, cc_r, ll_r)) = (lr_ind_cc(ci), lr_ind_cc(cr));
    let (uc249_i, uc249_r) = (lr_uc(ci[1] + ci[3], N - 1, P), lr_uc(cr[1] + cr[3], N - 1, P));
    let kp: Vec<(usize, usize)> = si.iter().map(|&b| (0, b)).collect();
    let uc_search = 2.0 * (golden_max(&|q| ll(q, &kp, &[0])) - ll(P, &kp, &[0]));
    let (s_i, s_r) = (lr_ind_search(&si), lr_ind_search(&sr));
    let f6 = |v: f64| format!("{:.6}", v);
    let pct = |v: &[f64]| join(v.iter().map(|x| format!("{:.2}", 100.0 * x)));
    let upper = |lo: usize| (lo..=N).collect::<Vec<usize>>();
    let mut rows: Vec<(String, String)> = vec![
        ("days n, promised rate p".into(), format!("{} {:.2}", N, P)),
        ("expected count n p".into(), f6(N as f64 * P)),
        ("exception days isolated | clustered; K".into(), format!("{} | {}; {} {}", join(iso.iter()), join(run.iter()), si.iter().sum::<usize>(), sr.iter().sum::<usize>())),
        ("pmf % k=0..10, exact".into(), pct(&pmf[..11])),
        ("pmf % k=0..10, simulated".into(), join(sim[..11].iter().map(|&c| format!("{:.2}", 100.0 * c as f64 / years as f64)))),
        ("cdf % k=0..10".into(), pct(&cdf[..11])),
        ("zones k=0..12, Basel table".into(), join((0..13).map(zone_table))),
        ("zones k=0..12, 95%/99.99% cut".into(), join((0..13).map(zone_cut))),
        ("K=4: zone, plus factor, multiplier".into(), format!("{} {:.2} {:.2}", zone_cut(4), plus(4), 3.0 + plus(4))),
        ("plus factors k=5..9, 10+".into(), join((5..11).map(|k| format!("{:.2}", plus(k))))),
        ("P(K>=4) exact".into(), f6(1.0 - cdf[3])), ("P(K>=5) exact".into(), f6(1.0 - cdf[4])),
        ("p-hat, K ln(p-hat/p), (n-K) ln(ratio)".into(), format!("{:.6} {:.6} {:.6}", 4.0 / N as f64, xlog(4, 4.0 / N as f64 / P), xlog(N - 4, (1.0 - 4.0 / N as f64) / (1.0 - P)))),
        ("Kupiec LR, closed form / by search".into(), format!("{:.6} {:.6}", lr_uc(4, N, P), uc_search)),
        ("chi2(1) 5% cutoff; tail beyond, Simpson".into(), format!("{:.6} {:.6}", c1, tail1)),
        ("Kupiec p-value, chi2(1)".into(), f6(2.0 * (1.0 - phi_cdf(lr_uc(4, N, P).sqrt())))),
        ("Kupiec LR at k=0,1,2,3,5,6,7".into(), join([0, 1, 2, 3, 5, 6, 7].iter().map(|&k| format!("{:.3}", lr_uc(k, N, P))))),
        ("Kupiec rejects at k".into(), format!("{} ...", join(rej[..4].iter()))),
        ("Kupiec false alarms: exact / 20000 years".into(), format!("{:.6} {:.6}", prob(P, &rej), sim_size)),
        ("n00 n01 n10 n11 isolated: pairs | runs".into(), format!("{} | {}", join(ci.iter()), join(counts_by_runs(&iso).iter()))),
        ("n00 n01 n10 n11 clustered: pairs | runs".into(), format!("{} | {}", join(cr.iter()), join(counts_by_runs(&run).iter()))),
        ("p01 p11 isolated".into(), format!("{:.6} {:.6}", ci[1] as f64 / (ci[0] + ci[1]) as f64, ci[3] as f64 / (ci[2] + ci[3]) as f64)),
        ("p01 p11 clustered".into(), format!("{:.6} {:.6}", cr[1] as f64 / (cr[0] + cr[1]) as f64, cr[3] as f64 / (cr[2] + cr[3]) as f64)),
        ("LR_IND isolated, closed / search".into(), format!("{:.6} {:.6}", ind_i, s_i)),
        ("LR_IND clustered, closed / search".into(), format!("{:.6} {:.6}", ind_r, s_r)),
        ("log-lik Markov, common, fixed p; iso".into(), join(ll_i.iter().map(|v| format!("{:.6}", v)))),
        ("log-lik Markov, common, fixed p; clu".into(), join(ll_r.iter().map(|v| format!("{:.6}", v)))),
        ("LR_UC on the 249 pairs, both series".into(), f6(uc249_r)),
        ("LR_CC isolated, direct / IND+UC249".into(), format!("{:.6} {:.6}", cc_i, ind_i + uc249_i)),
        ("LR_CC clustered, direct / IND+UC249".into(), format!("{:.6} {:.6}", cc_r, ind_r + uc249_r)),
        ("LR_CC clustered, IND+UC250 shortcut".into(), f6(ind_r + lr_uc(4, N, P))),
        ("chi2(2) 5% cutoff; tail of Z1^2+Z2^2".into(), format!("{:.6} {:.6}", c2, tail2)),
        ("p-value IND clustered, chi2(1)".into(), sci(2.0 * (1.0 - phi_cdf(ind_r.sqrt())))),
        ("p-value CC clustered, chi2(2)".into(), sci((-cc_r / 2.0).exp())),
        ("C(250,4); run of 4 given K=4: 247/C".into(), format!("{} {}", comb(N, 4).round(), sci((N - 3) as f64 / comb(N, 4)))),
    ];
    for q in [0.01, 0.015, 0.02, 0.03, 0.04] {
        rows.push((format!("true {:.1}%: % not green, red, Kupiec", 100.0 * q),
            format!("{:.2} {:.2} {:.2}", 100.0 * prob(q, &upper(5)), 100.0 * prob(q, &upper(10)), 100.0 * prob(q, &rej))));
    }
    rows.push(("wrong: p = 5% for a 99% VaR, LR".into(), f6(lr_uc(4, N, 0.05))));
    rows.push(("wrong: drop the (n-K) term, LR".into(), f6(2.0 * 4.0 * ((4.0 / N as f64) / P).ln())));
    rows.push(("wrong: count only, clustered LR".into(), f6(lr_uc(sr.iter().sum(), N, P))));
    rows.push(("try: p = 2.5%, K = 4, Kupiec LR".into(), f6(lr_uc(4, N, 0.025))));
    rows.push(("try: n = 500, K = 8, Kupiec LR".into(), f6(lr_uc(8, 500, P))));
    rows.push(("try: days 40 41 90 140, LR_IND".into(), f6(lr_ind_cc(counts(&days(&[40, 41, 90, 140]))).0)));
    for (lab, v) in &rows { println!("{:<42} {}", lab, v); }

    assert!((0..11).all(|k| (sim[k] as f64 / years as f64 - pmf[k]).abs() < 0.01)); // simulation agrees
    assert!((0..40).all(|k| zone_table(k) == zone_cut(k)));
    assert!((lr_uc(4, N, P) - uc_search).abs() < 1e-9);
    assert!((tail1 - 0.05).abs() < 1e-9);
    assert!((tail2 - 0.05).abs() < 1e-9);
    assert!((prob(P, &rej) - sim_size).abs() < 0.01);
    assert_eq!(ci, counts_by_runs(&iso));
    assert_eq!(cr, counts_by_runs(&run));
    assert!((ind_i - s_i).abs() < 1e-8);
    assert!((ind_r - s_r).abs() < 1e-8);
    assert!((cc_r - (ind_r + uc249_r)).abs() < 1e-9);
    let (m, mut hits, mut all) = (20usize, 0usize, 0usize); // run formula, brute force over 4-day subsets
    for a in 0..m { for b in a + 1..m { for c in b + 1..m { for d in c + 1..m { all += 1; if d - a == 3 { hits += 1; } } } } }
    assert!((hits as f64 / all as f64 - (m - 3) as f64 / comb(m, 4)).abs() < 1e-12);
    println!("ALL CHECKS PASS");
}
