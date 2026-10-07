// Dominated convergence -- the same check as the Python, in Rust.  No crates.
// Spam at 2 per hour: cut the hour into n slots, each holding one spam with
// chance 2/n.  The count K is binomial(n, 2/n); its masses p_n(k) tend to the
// Poisson(2) masses q(k).  A sum over k is an integral against counting measure.
// Road one builds each mass as a product; road two by a recursion or a closed
// form.  Then the roof 2^k/k!, the swapped limits, Scheffe's total error,
// x^n on [0, 1] under the roof 1, and what breaks when no roof exists.
const KMAX: usize = 60; // counts above 60: the roof's tail is printed
const NS: [usize; 3] = [10, 100, 1000];

fn exp_series(t: f64) -> f64 {
    // e^t from its power series
    let (mut s, mut term) = (0.0, 1.0);
    for j in 0..90 {
        s += term;
        term *= t / (j as f64 + 1.0);
    }
    s
}

fn roof(k: usize) -> f64 {
    // g(k) = 2^k / k!
    (0..k).fold(1.0, |r, i| r * 2.0 / (i as f64 + 1.0))
}

fn binom_product(n: usize, k: usize) -> f64 {
    // [n(n-1)...(n-k+1)/n^k] x 2^k/k! x (1 - 2/n)^(n-k)
    if k > n {
        return 0.0;
    }
    let nf = n as f64;
    let c = (0..k).fold(1.0, |c, i| c * ((nf - i as f64) / nf * 2.0 / (i as f64 + 1.0)));
    c * (1.0 - 2.0 / nf).powi((n - k) as i32)
}

fn binom_recursion(n: usize) -> Vec<f64> {
    // p(k+1) = p(k) x (n-k)/(k+1) x 2/(n-2)
    let nf = n as f64;
    let mut p = vec![(1.0 - 2.0 / nf).powi(n as i32)];
    for k in 0..KMAX {
        let last = p[k];
        p.push(last * (nf - k as f64) / (k as f64 + 1.0) * 2.0 / (nf - 2.0));
    }
    p
}

fn midpoint(f: &dyn Fn(f64) -> f64) -> f64 {
    // integral over [0, 1] by midpoints
    let m = 200000;
    (0..m).map(|i| f((i as f64 + 0.5) / m as f64)).sum::<f64>() / m as f64
}

fn row(v: &[f64], scale: f64) -> String {
    v.iter().map(|x| format!("{:.2}", scale * x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    // the limit q(k) = e^(-2) 2^k/k!, two ways to e^(-2)
    let (e_a, e_b) = (exp_series(-2.0), 1.0 / exp_series(2.0));
    let q: Vec<f64> = (0..=KMAX).map(|k| e_a * roof(k)).collect();
    let mut q2 = vec![e_b];
    for k in 0..KMAX {
        let last = q2[k];
        q2.push(last * 2.0 / (k as f64 + 1.0));
    }
    assert!(q.iter().zip(&q2).all(|(a, b)| (a - b).abs() < 1e-15));
    println!("e^(-2): series {:.10}, 1/(series for e^2) {:.10}", e_a, e_b);
    println!("by hand, n = 10, k = 2: 10 x 9/100 = {:.4}, roof {:.4}, 0.8^8 = {:.4}, product {:.4}; q(2) = e^(-2) x 2 = {:.6} x 2 = {:.4}",
        10.0 * 9.0 / 100.0, roof(2), 0.8f64.powi(8), 10.0 * 9.0 / 100.0 * roof(2) * 0.8f64.powi(8), e_a, q[2]);

    let p: Vec<Vec<f64>> = NS.iter().map(|&n| (0..=KMAX).map(|k| binom_product(n, k)).collect()).collect();
    for (i, &n) in NS.iter().enumerate() {
        assert!(p[i].iter().zip(binom_recursion(n)).all(|(a, b)| (a - b).abs() < 1e-13));
    }
    println!("k   n = 10   n = 100  n = 1000  Poisson  roof 2^k/k!");
    for k in 0..9 {
        println!("{}   {:.4}   {:.4}   {:.4}    {:.4}   {:.4}", k, p[0][k], p[1][k], p[2][k], q[k], roof(k));
    }

    // the roof: p_n(k) <= 2^k/k! at every count, for every n
    let under: Vec<bool> = NS.iter().map(|&n| (0..=n).all(|k| binom_product(n, k) <= roof(k))).collect();
    let shown: Vec<String> = NS.iter().zip(&under).map(|(n, u)| format!("n = {} {}", n, if *u { "yes" } else { "no" })).collect();
    println!("roof holds at every count: {}", shown.join(", "));
    assert!(under.iter().all(|u| *u));
    let tail: f64 = (KMAX + 1..200).map(roof).sum();
    let total: f64 = (0..200).map(roof).sum();
    let total2: f64 = (0..200).map(|k| (k * k) as f64 * roof(k)).sum();
    println!("roof totals: sum 2^k/k! = {:.4} = e^2; sum k^2 2^k/k! = {:.4} = 6e^2; tail above k = {}: {:.1e}", total, total2, KMAX, tail);

    // dominated convergence: mean and E[K^2] follow the masses
    let moments = |v: &[f64]| -> (f64, f64) {
        let m1: f64 = v.iter().enumerate().map(|(k, x)| k as f64 * x).sum();
        let m2: f64 = v.iter().enumerate().map(|(k, x)| (k * k) as f64 * x).sum();
        (m1, m2)
    };
    for (i, &n) in NS.iter().enumerate() {
        let (m1, m2) = moments(&p[i]);
        let f2 = 6.0 - 4.0 / n as f64;
        println!("n = {}: mean {:.4} (formula 2), E[K^2] {:.4} (formula 6 - 4/n = {:.4}), variance {:.4}", n, m1, m2, f2, m2 - m1 * m1);
        assert!((m2 - f2).abs() < 1e-9);
    }
    let (m1, m2) = moments(&q);
    println!("Poisson: mean {:.4}, E[K^2] {:.4} (formula 2 + 4 = 6), variance {:.4}", m1, m2, m2 - m1 * m1);
    assert!((m2 - 6.0).abs() < 1e-12);

    // Scheffe: equal totals turn pointwise convergence into total-error convergence
    let qb = 1.0 - q[..5].iter().sum::<f64>();
    for (i, &n) in NS.iter().enumerate() {
        let nf = n as f64;
        let l1: f64 = p[i].iter().zip(&q).map(|(a, b)| (a - b).abs()).sum();
        let pos: f64 = p[i].iter().zip(&q).map(|(a, b)| (b - a).max(0.0)).sum();
        let over: Vec<String> = (0..=KMAX).filter(|&k| p[i][k] > q[k]).map(|k| k.to_string()).collect();
        println!("Scheffe, n = {}: sum |p - q| = {:.4}; 2 x sum (q - p)+ = {:.4}; Le Cam bound 8/n = {:.4}; p above q at counts [{}]",
            n, l1, 2.0 * pos, 8.0 / nf, over.join(", "));
        assert!((l1 - 2.0 * pos).abs() < 1e-12);
        assert!(l1 <= 8.0 / nf);
        let pb = 1.0 - p[i][..5].iter().sum::<f64>();
        println!("  burst of 5 or more: binomial {:.4}, Poisson {:.4}, gap {:.4} <= half the total error {:.4}", pb, qb, (pb - qb).abs(), l1 / 2.0);
        assert!((pb - qb).abs() <= l1 / 2.0);
    }
    for (lab, v) in [("n = 10", &p[0]), ("n = 100", &p[1]), ("Poisson", &q)] {
        println!("chart %, {}: {}", lab, row(&v[..9], 100.0));
    }

    // x^n on [0, 1] under the roof 1 (bounded convergence)
    let mut spike = Vec::new();
    for n in [1i32, 10, 100, 1000] {
        let integral = midpoint(&|x: f64| x.powi(n));
        spike.push((n + 1) as f64 * integral);
        println!("x^n, n = {}: midpoint sum {:.6}, exact 1/(n+1) = {:.6}; at x = 0.999 still {:.4}", n, integral, 1.0 / (n + 1) as f64, 0.999f64.powi(n));
        assert!((integral - 1.0 / (n + 1) as f64).abs() < 1e-6);
    }
    println!("chart roof g = 1: {}", row(&[1.0; 11], 1.0));
    for n in [5i32, 20] {
        let v: Vec<f64> = (0..11).map(|j| (j as f64 / 10.0).powi(n)).collect();
        println!("chart x^n, n = {}: {}", n, row(&v, 1.0));
    }

    // what breaks
    let env: Vec<usize> = NS.iter().map(|&r| (1..=r).map(|k| (1..=r).map(|n| if k == n { 1 } else { 0 }).max().unwrap()).sum()).collect(); // all the chance at count n
    println!("breaks, sliding mass at count n: total 1, limit 0 at every count; smallest roof summed over counts 1..R = {}, {}, {} for R = 10, 100, 1000", env[0], env[1], env[2]);
    for (i, &n) in NS.iter().enumerate() {
        // storm hour: n^2 spams with chance 1/n
        let nf = n as f64;
        let s_l1: f64 = p[i].iter().zip(&q).map(|(a, b)| ((1.0 - 1.0 / nf) * a - b).abs()).sum::<f64>() + 1.0 / nf;
        let s_mean: f64 = p[i].iter().enumerate().map(|(k, x)| k as f64 * (1.0 - 1.0 / nf) * x).sum::<f64>() + nf * nf / nf;
        let f = 2.0 * (1.0 - 1.0 / nf) + nf;
        println!("breaks, storm hour, n = {}: total error {:.4}, mean {:.4} (formula 2(1 - 1/n) + n = {:.4})", n, s_l1, s_mean, f);
        assert!((s_mean - f).abs() < 1e-9);
    }
    println!("breaks, spike (n+1)x^n: integral {:.4}, {:.4}, {:.4} at n = 10, 100, 1000; limit 0 below x = 1", spike[1], spike[2], spike[3]);
    assert!((spike[3] - 1.0).abs() < 1e-3);
    println!("breaks, the limit as roof: p_10(2) = {:.4} > q(2) = {:.4}", p[0][2], q[2]);
    assert!(p[0][2] > q[2]);
    println!("ALL CHECKS PASS");
}
