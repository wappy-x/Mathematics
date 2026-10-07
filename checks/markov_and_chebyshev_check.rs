// Markov, Chebyshev and Chernoff on the river: the check behind the card.
// Rust std only. A small exact fraction type; own integrator, series, minimiser and RNG.
#[derive(Clone, Copy, PartialEq, Debug)]
struct Q(i64, i64);
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn q(n: i64, d: i64) -> Q { let g = gcd(n, d) * d.signum(); Q(n / g, d / g) }
fn add(a: Q, b: Q) -> Q { q(a.0 * b.1 + b.0 * a.1, a.1 * b.1) }
fn sub(a: Q, b: Q) -> Q { q(a.0 * b.1 - b.0 * a.1, a.1 * b.1) }
fn mul(a: Q, b: Q) -> Q { q(a.0 * b.0, a.1 * b.1) }
fn div(a: Q, b: Q) -> Q { q(a.0 * b.1, a.1 * b.0) }
fn fl(a: Q) -> f64 { a.0 as f64 / a.1 as f64 }
fn d(x: f64) -> f64 { 4.0 * x * (1.0 - x) }
fn f6(v: f64) -> String { format!("{:.6}", v) }
// integral over [0, 1] of sum c_k x^k, exactly
fn poly_int(c: &[i64]) -> Q { c.iter().enumerate().fold(q(0, 1), |s, (k, &ck)| add(s, q(ck, k as i64 + 1))) }
fn tail_up(a: f64) -> f64 { (1.0 - a).sqrt() }
fn tail_low(b: f64) -> f64 { 1.0 - (1.0 - b).sqrt() }
fn m_simpson(t: f64) -> f64 {
    let n = 2000; let h = 1.0 / n as f64; let mut s = 0.0;
    for i in 0..=n { let w = if i == 0 || i == n { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }; s += w * (t * d(i as f64 * h)).exp(); }
    h / 3.0 * s
}
fn m_series(t: f64) -> f64 {
    let (mut s, mut term, mut k) = (0.0f64, 1.0f64, 0.0f64);
    while k < 12.0 || term.abs() > 1e-17 { s += term; k += 1.0; term *= 4.0 * t * k / ((2.0 * k) * (2.0 * k + 1.0)); }
    s
}
fn argmin(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    let g = (5f64.sqrt() - 1.0) / 2.0;
    for _ in 0..120 {
        let (c, e) = (hi - g * (hi - lo), lo + g * (hi - lo));
        if f(c) < f(e) { hi = e } else { lo = c }
    }
    (lo + hi) / 2.0
}
fn chernoff_up(a: f64) -> (f64, f64, f64) {
    let t = argmin(&|t: f64| m_simpson(t).ln() - a * t, 0.0, 40.0);
    (t, (-a * t).exp() * m_simpson(t), (-a * t).exp() * m_series(t))
}
fn main() {
    // road 1: exact moments and exact tails
    let m = poly_int(&[0, 4, -4]); let m2 = poly_int(&[0, 0, 16, -32, 16]); let var = sub(m2, mul(m, m));
    let (a, eps) = (q(9, 10), q(1, 2));
    let (mk, ch) = (div(m, a), div(var, mul(eps, eps)));
    let (t_mk, t_ch) = (tail_up(0.9), tail_low(1.0 / 6.0));
    // road 2: grid of N cells, sizes of level sets counted directly
    let n = 1_000_000usize; let (mut gs1, mut gs2, mut g_up, mut g_ch) = (0.0, 0.0, 0usize, 0usize);
    for i in 0..n {
        let y = d((i as f64 + 0.5) / n as f64); gs1 += y; gs2 += y * y;
        g_up += (y >= 0.9) as usize; g_ch += ((y - 2.0 / 3.0).abs() >= 0.5) as usize;
    }
    let (gm, gv) = (gs1 / n as f64, gs2 / n as f64 - (gs1 / n as f64).powi(2));
    // road 3: 200000 random moorings, SplitMix64 with seed 20260929
    let mut st: u64 = 20260929;
    let mut rnd = || {
        st = st.wrapping_add(0x9E3779B97F4A7C15); let mut z = st;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 2f64.powi(53)
    };
    let r = 200_000usize; let (mut r1, mut r2, mut r_up, mut r_ch) = (0.0, 0.0, 0usize, 0usize);
    for _ in 0..r {
        let y = d(rnd()); r1 += y; r2 += y * y;
        r_up += (y >= 0.9) as usize; r_ch += ((y - 2.0 / 3.0).abs() >= 0.5) as usize;
    }
    let (rm, rv) = (r1 / r as f64, r2 / r as f64 - (r1 / r as f64).powi(2));
    let (nf, rf) = (n as f64, r as f64);
    println!("depth d(x) = 4x(1 - x) m, x km uniform on [0, 1]; exact, grid of 10^6 cells, 200000 moorings");
    println!("mean depth: {} {} {}", f6(fl(m)), f6(gm), f6(rm));
    println!("variance:   {} {} {}   (exact 4/45)", f6(fl(var)), f6(gv), f6(rv));
    println!("P(d >= 0.9):           {} {} {}   Markov bound {}", f6(t_mk), f6(g_up as f64 / nf), f6(r_up as f64 / rf), f6(fl(mk)));
    println!("P(|d - 2/3| >= 0.5):   {} {} {}   Chebyshev bound {}", f6(t_ch), f6(g_ch as f64 / nf), f6(r_ch as f64 / rf), f6(fl(ch)));
    assert!(m == q(2, 3) && var == q(4, 45));
    assert!((gm - fl(m)).abs() < 1e-9 && (gv - fl(var)).abs() < 1e-9);
    assert!((g_up as f64 / nf - t_mk).abs() < 2.0 / nf && (g_ch as f64 / nf - t_ch).abs() < 2.0 / nf);
    for (p, c) in [(t_mk, r_up), (t_ch, r_ch)] { assert!((c as f64 / rf - p).abs() < 4.0 * (p * (1.0 - p) / rf).sqrt()); }
    assert!(t_mk < fl(mk) && t_ch < fl(ch));
    // Chernoff, the exponential form of Markov
    let (t9, c9, c9s) = chernoff_up(0.9);
    println!("Chernoff, P(d >= 0.9): best t {:.3}, bound by Simpson {}, by series {}", t9, f6(c9), f6(c9s));
    assert!((c9 - c9s).abs() < 1e-9 && t_mk < c9 && c9 < fl(mk));
    let fact = |k: u128| (1..=k).product::<u128>() as f64;
    let mom: Vec<f64> = (1..=8u32).map(|p| 4f64.powi(p as i32) * fact(p as u128).powi(2) / fact(2 * p as u128 + 1) / 0.9f64.powf(p as f64)).collect();
    let ms: Vec<String> = mom.iter().map(|v| format!("{:.4}", v)).collect();
    println!("moment bounds E[d^p]/0.9^p, p = 1..8: {}", ms.join(" "));
    assert!(mom.iter().cloned().fold(f64::INFINITY, f64::min) < c9 && (mom[0] - fl(mk)).abs() < 1e-12);
    let tl = argmin(&|t: f64| m_simpson(-t).ln() + t / 6.0, 0.0, 40.0);
    let cl = (tl / 6.0).exp() * m_simpson(-tl);
    let mk1 = div(sub(q(1, 1), m), q(5, 6));
    println!("P(d <= 1/6): true {}; Markov on 1 - d {}; Chebyshev {}; Chernoff (t = {:.3}) {}", f6(tail_low(1.0 / 6.0)), f6(fl(mk1)), f6(fl(ch)), tl, f6(cl));
    assert!(tail_low(1.0 / 6.0) < cl && cl < fl(ch) && fl(ch) < fl(mk1));
    println!("threshold a, true P(d >= a), Markov, Chernoff");
    let mut rows = vec![];
    for k in 14..20 {
        let x = k as f64 / 20.0; let (_, c, _) = chernoff_up(x);
        let row = [tail_up(x), fl(m) / x, c];
        println!("  {:.2}, {}, {}, {}", x, f6(row[0]), f6(row[1]), f6(c));
        assert!(row[0] < row[1].min(row[2]));
        rows.push(row);
    }
    for (j, name) in ["true", "Markov", "Chernoff"].iter().enumerate() {
        let v: Vec<String> = rows.iter().map(|r| format!("{:.2}", r[j])).collect();
        println!("chart, {}: {}", name, v.join(" "));
    }
    // tight laws: exact step functions on [0, 1] whose tails meet the bounds
    let pieces = [(a, q(20, 27)), (q(0, 1), q(7, 27))];
    let ti = pieces.iter().fold(q(0, 1), |s, &(h, l)| add(s, mul(h, l)));
    let tl9 = pieces.iter().filter(|&&(h, _)| fl(h) >= fl(a)).fold(q(0, 1), |s, &(_, l)| add(s, l));
    println!("tight Markov: 0.9 m on 20/27 km, dry after: integral {} tail {} bound {}", f6(fl(ti)), f6(fl(tl9)), f6(fl(div(ti, a))));
    let w = [q(8, 45), q(29, 45), q(8, 45)]; let v = [q(1, 6), q(2, 3), q(7, 6)];
    let tm = (0..3).fold(q(0, 1), |s, i| add(s, mul(w[i], v[i])));
    let tv = (0..3).fold(q(0, 1), |s, i| { let e = sub(v[i], tm); add(s, mul(w[i], mul(e, e))) });
    let far = |i: usize| fl(sub(v[i], tm)).abs();
    let tt = (0..3).filter(|&i| far(i) >= fl(eps)).fold(q(0, 1), |s, i| add(s, w[i]));
    let tstrict = (0..3).filter(|&i| far(i) > fl(eps)).fold(q(0, 1), |s, i| add(s, w[i]));
    println!("tight Chebyshev: 1/6, 2/3, 7/6 m on 8/45, 29/45, 8/45 km: mean {} variance {} tail {} bound {} strict tail {}",
        f6(fl(tm)), f6(fl(tv)), f6(fl(tt)), f6(fl(div(tv, mul(eps, eps)))), f6(fl(tstrict)));
    assert!(ti == m && tl9 == mk && tm == m && tv == var && tt == ch);
    println!("breaks: Markov on signed d - 2/3 at 0.2 gives {} against the true {}", f6(fl(div(sub(m, q(2, 3)), q(1, 5)))), f6(tail_up(13.0 / 15.0)));
    println!("breaks: variance over eps, not eps^2, on the tight law: {} below its tail {}", f6(fl(div(tv, eps))), f6(fl(tt)));
    println!("breaks: Markov on d itself for P(d <= 1/6): {}", f6(fl(div(m, q(1, 6)))));
    assert!(tail_up(13.0 / 15.0) > fl(div(sub(m, q(2, 3)), q(1, 5))) && fl(div(tv, eps)) < fl(tt));
    let (x1, x2) = ((1.0 - tail_up(0.9)) / 2.0, (1.0 + tail_up(0.9)) / 2.0);
    println!("figure, X = 36 + 300x, Y = 210 - 150d; set ends x = {:.4}, {:.4} km, X = {:.2}, {:.2}; Y(0.9) = {:.2}, Y(2/3) = {:.2}; rectangle area {:.6}",
        x1, x2, 36.0 + 300.0 * x1, 36.0 + 300.0 * x2, 210.0 - 150.0 * 0.9, 210.0 - 100.0, 0.9 * tail_up(0.9));
}
