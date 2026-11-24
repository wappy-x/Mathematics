// Locally convex and Frechet spaces: smooth motion profiles on [0, 1] s, sized by every derivative.
// std only, no crates.  Every number quoted on the card is printed here.
const E: f64 = std::f64::consts::E;

fn grid() -> Vec<f64> { (0..=1000).map(|j| j as f64 / 1000.0).collect() } // 1001 sample times across [0, 1] s

fn binom(k: usize, j: usize) -> f64 { (0..j).fold(1.0, |acc, i| acc * (k - i) as f64 / (i + 1) as f64) }
fn fact(n: usize) -> f64 { (1..=n).fold(1.0, |a, i| a * i as f64) }

// road 2: k-th central difference, built from samples of f alone
fn fd(f: &dyn Fn(f64) -> f64, k: usize, t: f64) -> f64 {
    let h = 1e-3;
    let s: f64 = (0..=k).map(|j| if (k - j) % 2 == 0 { 1.0 } else { -1.0 } * binom(k, j) * f(t + (j as f64 - k as f64 / 2.0) * h)).sum();
    s / h.powi(k as i32)
}

// seminorm p_k(f) = max |f^(k)(t)| over the grid, derivative by differences
fn p_fd(f: &dyn Fn(f64) -> f64, k: usize) -> f64 { grid().iter().map(|&t| fd(f, k, t).abs()).fold(0.0, f64::max) }

// road 1: differentiate integer coefficients k times, then take the grid maximum
fn p_poly(c0: &[i64], k: usize) -> f64 {
    let mut c = c0.to_vec();
    for _ in 0..k { c = (1..c.len()).map(|i| i as i64 * c[i]).collect(); }
    let ev = |t: f64| c.iter().enumerate().map(|(i, &a)| a as f64 * t.powi(i as i32)).sum::<f64>().abs();
    grid().iter().map(|&t| ev(t)).fold(0.0, f64::max)
}

// the Frechet metric from a list of seminorm values p_0, p_1, ...
fn dist(ps: &[f64]) -> f64 { ps.iter().enumerate().map(|(k, &x)| 2f64.powi(-(k as i32)) * x.min(1.0)).sum() }
// closed form for g_n(t) = sin(n t) / n^2 on [0, 1], n >= 2
fn ripple_p(n: u32, k: i32) -> f64 { (n as f64).powi(k - 2) }

// finite rehearsal: integer coefficients of T_N(2t - 1), from T_(k+1) = 2(2t - 1) T_k - T_(k-1)
fn cheb(n: usize) -> Vec<i64> {
    let (mut a, mut b) = (vec![1i64], vec![-1i64, 2]);
    for _ in 1..n {
        let c: Vec<i64> = (0..=b.len())
            .map(|i| 4 * (if i > 0 { b[i - 1] } else { 0 }) - 2 * b.get(i).unwrap_or(&0) - a.get(i).unwrap_or(&0)).collect();
        a = std::mem::replace(&mut b, c);
    }
    b
}

// p_k(e^t - s_M): the tail of the series for e from j = M - k + 1, largest at t = 1
fn gap(m: usize, k: usize) -> f64 {
    let start = if k <= m { m - k + 1 } else { 0 };
    let rem: f64 = (start..80).map(|j| 1.0 / fact(j)).sum();
    if k <= m {
        // road 2: e minus the partial sum, and Taylor's bound 1/(m+1)! <= rem <= e/(m+1)!
        let partial: f64 = (0..=m - k).map(|j| 1.0 / fact(j)).sum();
        assert!((rem - (E - partial)).abs() < 1e-14);
        assert!(1.0 / fact(m - k + 1) <= rem && rem <= E / fact(m - k + 1));
    }
    rem
}

fn main() {
    println!("smooth functions on [0, 1]: p_k(f) = max |f^(k)(t)|, d(f, g) = sum 2^-k min(1, p_k(f - g))");
    println!("elevator move f(t) = t^3 m, t in s");
    println!("   k   p_k exact   p_k from samples only");
    let cube_f = |t: f64| t * t * t;
    let exact: Vec<f64> = (0..41).map(|k| p_poly(&[0, 0, 0, 1], k)).collect();
    for k in 0..5 {
        let by_fd = if k < 4 { format!("{:22.6}", p_fd(&cube_f, k)) } else { "        (not sampled)".to_string() };
        println!("{:4} {:11.6} {}", k, exact[k], by_fd);
    }
    assert!(exact[..5] == [1.0, 3.0, 6.0, 6.0, 0.0]); // the hand values
    assert!((0..4).all(|k| (p_fd(&cube_f, k) - exact[k]).abs() < 1e-5));
    assert!((dist(&exact) - 1.875).abs() < 1e-15); // 1 + 1/2 + 1/4 + 1/8, every later term zero
    println!("d(t^3, 0) = 1 + 1/2 + 1/4 + 1/8 = {:.6}", dist(&exact));
    println!("slope at the end f'(1) = {:.6}, bounded by p_1 = {:.6}", fd(&cube_f, 1, 1.0), exact[1]);
    let gmax = exact[..4].iter().cloned().fold(0.0, f64::max);
    println!("wall f''(1) = {:.6}; gauge of U = max(p_0..p_3) = {:.6}", fd(&cube_f, 2, 1.0), gmax);
    println!("finite rehearsal, polynomials of degree <= N: T_N(2t - 1), where T_N(cos th) = cos(N th)");
    println!("   N  p_0(T_N)   p_1(T_N)  2N^2");
    for &n in &[1usize, 3, 10] {
        let (q0, q1) = (p_poly(&cheb(n), 0), p_poly(&cheb(n), 1));
        assert!((q0 - 1.0).abs() < 1e-9 && (q1 - (2 * n * n) as f64).abs() < 1e-9); // closed forms: |T_N| <= 1, slope 2N^2 at t = 1
        println!("{:4} {:9.6} {:10.6} {:5}", n, q0, q1, 2 * n * n);
    }

    let g10 = |t: f64| (10.0 * t).sin() / 100.0;
    let s: Vec<String> = (0..3).map(|k| format!("p_{} {:.6}", k, p_fd(&g10, k))).collect();
    println!("ripple g_n(t) = sin(n t)/n^2, n = 10, seminorms from samples: {}", s.join(", "));
    assert!((0..3).all(|k| (p_fd(&g10, k) / ripple_p(10, k as i32) - 1.0).abs() < 1e-3));
    println!("   n    p_0(g_n)    p_1(g_n)  p_2(g_n)  p_3(g_n)  d(g_n, 0) by 60 terms  0.5 + 1/(2n) + 1/n^2");
    let (mut cd, mut cp) = (vec![], vec![]);
    for &n in &[2u32, 4, 8, 10, 16, 32, 64] {
        let d60 = dist(&(0..60).map(|k| ripple_p(n, k)).collect::<Vec<_>>());
        let closed = 0.5 + 1.0 / (2.0 * n as f64) + 1.0 / (n as f64 * n as f64);
        assert!((d60 - closed).abs() < 2f64.powi(-58)); // the truncated sum misses at most the tail
        if n != 10 {
            cd.push(format!("{:.4}", d60));
            cp.push(format!("{:.4}", ripple_p(n, 0)));
        }
        println!("{:4} {:11.6} {:11.6} {:9.0} {:9.0} {:22.6} {:21.6}",
                 n, ripple_p(n, 0), ripple_p(n, 1), ripple_p(n, 2), ripple_p(n, 3), d60, closed);
    }
    println!("chart: n 2, 4, 8, 16, 32, 64");
    println!("chart: d(g_n, 0) {}", cd.join(", "));
    println!("chart: p_0(g_n) {}", cp.join(", "));

    // completeness: Taylor sums s_N of e^t are Cauchy in d and close in on e^t, which is smooth
    println!("Taylor sums s_N of e^t\n   N  d(s_N, e^t)  d(s_N, s_2N)");
    let mut d_lim = 0.0;
    for &n in &[2usize, 4, 8, 16] {
        d_lim = dist(&(0..60).map(|k| gap(n, k)).collect::<Vec<_>>());
        let d_cau = dist(&(0..60).map(|k| gap(n, k) - gap(2 * n, k)).collect::<Vec<_>>());
        assert!(d_cau <= d_lim + 1e-15);
        println!("{:4} {:12.6} {:13.6}", n, d_lim, d_cau);
    }
    assert!(d_lim < 1e-4);

    // one norm is not enough: smoothed corners f_w(t) = sqrt((t - 1/2)^2 + w^2) are Cauchy in p_0 only
    let fine: Vec<f64> = (0..=200000).map(|j| j as f64 / 200000.0).collect();
    let slope = |w: f64, t: f64| (t - 0.5) / ((t - 0.5).powi(2) + w * w).sqrt();
    // road 2 for the stuck slope gap: ternary search of u/sqrt(u^2+1/4) - u/sqrt(u^2+1)
    let phi = |u: f64| u / (u * u + 0.25).sqrt() - u / (u * u + 1.0).sqrt();
    let (mut lo, mut hi) = (0.0f64, 5.0f64);
    for _ in 0..200 {
        let (a, b) = (lo + (hi - lo) / 3.0, hi - (hi - lo) / 3.0);
        if phi(a) < phi(b) { lo = a } else { hi = b }
    }
    println!("corner:      w  p_0(f_w - |t - 1/2|)  p_0(f_w - f_w/2)  p_1(f_w - f_w/2)");
    for &w in &[0.1f64, 0.01, 0.001] {
        let mx = |g: &dyn Fn(f64) -> f64| fine.iter().map(|&t| g(t)).fold(f64::MIN, f64::max);
        let p0_lim = mx(&|t: f64| ((t - 0.5).powi(2) + w * w).sqrt() - (t - 0.5).abs());
        let p0_cau = mx(&|t: f64| ((t - 0.5).powi(2) + w * w).sqrt() - ((t - 0.5).powi(2) + w * w / 4.0).sqrt());
        let p1_cau = mx(&|t: f64| (slope(w, t) - slope(w / 2.0, t)).abs());
        assert!((p0_lim - w).abs() < 1e-15 && (p0_cau - w / 2.0).abs() < 1e-15 && (p1_cau - phi(lo)).abs() < 1e-5);
        println!("{:15.3} {:21.6} {:17.6} {:17.6}", w, p0_lim, p0_cau, p1_cau);
    }
    assert!((phi(lo) - (2f64.cbrt() - 1.0)).abs() < 1e-12); // road 3: the closed form 2^(1/3) - 1, where phi'(u) = 0
    println!("  slope gap by search over u = (t - 1/2)/w: {:.6} at every w; closed form 2^(1/3) - 1 = {:.6}", phi(lo), 2f64.cbrt() - 1.0);

    // no norm: U(0.1, 2) = {p_0, p_1, p_2 < 0.1} holds g_n / 20 for every n, yet p_3 grows
    let s: Vec<String> = [10u32, 100, 1000].iter().map(|&n| format!("{:.1}", ripple_p(n, 3) / 20.0)).collect();
    println!("U(0.1, 2) holds g_n/20: p_0..p_2 at most 0.05, p_3 = {} at n = 10, 100, 1000", s.join(", "));

    // Schwartz space: the bell e^(-t^2/2) and the seminorms max |t^a f^(b)(t)|
    let bell = |t: f64| (-t * t / 2.0).exp();
    let wide: Vec<f64> = (0..=20000).map(|j| -10.0 + j as f64 / 1000.0).collect();
    let s10 = wide.iter().map(|&t| (t * bell(t)).abs()).fold(0.0, f64::max);
    let s01 = wide.iter().map(|&t| fd(&bell, 1, t).abs()).fold(0.0, f64::max);
    let s20 = wide.iter().map(|&t| t * t * bell(t)).fold(0.0, f64::max);
    assert!((s10 - (-0.5f64).exp()).abs() < 1e-6 && (s01 - (-0.5f64).exp()).abs() < 1e-6 && (s20 - 2.0 / E).abs() < 1e-6);
    println!("bell: p_(1,0) = {:.6}, p_(0,1) = {:.6}, p_(2,0) = {:.6}", s10, s01, s20);
    let tails: Vec<f64> = [10.0f64, 100.0, 1000.0].iter().map(|&m| {
        let x = (0..=1000).map(|j| m * j as f64 / 1000.0).map(|t| (t.powi(3) / (1.0 + t * t)).abs()).fold(0.0, f64::max);
        assert!((x - m.powi(3) / (1.0 + m * m)).abs() < 1e-9 * m);
        x
    }).collect();
    let s: Vec<String> = tails.iter().map(|x| format!("{:.3}", x)).collect();
    println!("1/(1+t^2): max |t^3 f(t)| over |t| <= 10, 100, 1000: {}", s.join(", "));

    // what breaks
    let (k10, k100): (f64, f64) = ((0..10).map(|_| E.min(1.0)).sum(), (0..100).map(|_| E.min(1.0)).sum());
    println!("no weights, e^t: sum of min(1, p_k) over K terms = {:.0} at K = 10, {:.0} at K = 100", k10, k100);
    let e2f = |t: f64| (2.0 * t).exp();
    assert!((0..4).all(|k| (p_fd(&e2f, k) / (2f64.powi(k as i32) * E * E) - 1.0).abs() < 1e-5));
    println!("no min(1, .), e^(2t): p_k = 2^k e^2, so sum 2^-k p_k over 10 terms = {:.6}", 10.0 * E * E);
    for &n in &[4u32, 100] { // L^(1/2): size of n times the indicator of [0, 1/n), by a midpoint sum
        let size = (0..100000).filter(|&i| (i as f64 + 0.5) / 100000.0 < 1.0 / n as f64)
            .map(|_| (n as f64).sqrt()).sum::<f64>() / 100000.0;
        assert!((size - 1.0 / (n as f64).sqrt()).abs() < 1e-9);
        println!("not convex, L^(1/2): 1 on [0, 1] is the average of {} pieces of size {:.6}", n, size);
    }
    println!("ALL CHECKS PASS");
}
