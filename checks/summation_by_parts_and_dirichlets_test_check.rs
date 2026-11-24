// Summation by parts and Dirichlet's test -- the check behind the card.  Rust std only.
// Road one adds sin(n)/n term by term.  Road two gets the target (pi - 1)/2 with
// no series: pi from Simpson's rule on 4/(1 + t^2).  Road three re-adds the same
// terms in the summation-by-parts form and must agree with road one.

fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, panels: usize) -> f64 {
    let h = (b - a) / panels as f64;
    let mut s = f(a) + f(b);
    for i in 1..panels {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn main() {
    let pi = simpson(|t| 4.0 / (1.0 + t * t), 0.0, 1.0, 2000);
    let (target, m) = ((pi - 1.0) / 2.0, 1.0 / 0.5f64.sin());
    println!("pi by Simpson: {:.9}  target (pi-1)/2 = {:.6}  bound M = 1/sin(1/2) = {:.4}", pi, target, m);
    let (mut a, mut s, mut lo, mut hi) = (0.0f64, 0.0f64, 9.0f64, -9.0f64);
    let (mut chart_a, mut chart_s) = (Vec::new(), Vec::new());
    for n in 1..=100000usize {
        let x = n as f64;
        a += x.sin();
        s += x.sin() / x;
        assert!((a - (0.5f64.cos() - (x + 0.5).cos()) / (2.0 * 0.5f64.sin())).abs() < 1e-9);
        lo = lo.min(a);
        hi = hi.max(a);
        if n <= 16 {
            chart_a.push(format!("{:.2}", a));
            chart_s.push(format!("{:.2}", s));
        }
        if [10, 100, 1000, 10000].contains(&n) {
            assert!((s - target).abs() <= m / (x + 1.0));
            println!("N={}: S_N={:.6}  miss={:+.6}  bound M/(N+1)={:.6}", n, s, target - s, m / (x + 1.0));
        }
    }
    println!("chart A_n, n=1..16: {}", chart_a.join(" "));
    println!("chart S_n, n=1..16: {}", chart_s.join(" "));
    let (low, high) = (-0.25f64.tan() / 2.0, 1.0 / 0.25f64.tan() / 2.0);
    println!("A_n over n<=100000: lowest {:.4}, highest {:.4}; exact range {:.4} to {:.4}", lo, hi, low, high);
    assert!(low - 1e-12 <= lo && hi <= high + 1e-12 && hi > 1.95);
    let big_n = 1000usize;
    let av: Vec<f64> = (0..=big_n).map(|n| if n == 0 { 0.0 } else { (n as f64).sin() }).collect();
    let bv: Vec<f64> = (0..=big_n + 1).map(|n| if n == 0 { 0.0 } else { 1.0 / n as f64 }).collect();
    let mut acum = vec![0.0f64];
    for n in 1..=big_n {
        acum.push(acum[n - 1] + av[n]);
    }
    let direct: f64 = (1..=big_n).map(|n| av[n] * bv[n]).sum();
    let parts = acum[big_n] * bv[big_n] + (1..big_n).map(|n| acum[n] * (bv[n] - bv[n + 1])).sum::<f64>();
    assert!((direct - parts).abs() < 1e-12);
    println!("identity at N=1000: term by term {:.12}  by parts {:.12}", direct, parts);
    let abel: f64 = (1..=200000).map(|n| { let x = n as f64; x.sin() / x * (1.0 + 1.0 / x) }).sum();
    let sq: f64 = (1..=200000).map(|n| { let x = n as f64; x.sin() / (x * x) }).sum();
    assert!((abel - (target + sq)).abs() < 2.0 * m / 200001.0 + 1e-9);
    println!("Abel, weights 1+1/n: {:.4} = {:.4} + sum sin(n)/n^2 {:.4}", abel, target, sq);
    let alt: Vec<i64> = (1..=6).map(|n| (1..=n).map(|k: i64| if k % 2 == 1 { 1 } else { -1 }).sum()).collect();
    println!("alternating case: A_n = {:?}, so M = 1 and the miss after 10 terms is at most 1/11 = {:.4}", alt, 1.0 / 11.0);
    let h: f64 = (1..=1000).map(|n| 1.0 / n as f64).sum();
    let bounce: f64 = (1..=1000).map(|n: i32| { let sg = if n % 2 == 1 { 1.0 } else { -1.0 }; sg * (2.0 - sg) / n as f64 }).sum();
    assert!(h > 7.0 && bounce < -6.0);
    println!("sin(n) alone, A_998..A_1000: {:.4} {:.4} {:.4}", acum[998], acum[999], acum[1000]);
    println!("a_n = 1 (unbounded A_n), b_n = 1/n: H_1000 = {:.4}", h);
    println!("bouncing sizes (2+(-1)^n)/n with signs +-: total at 1000 = {:.4}", bounce);
    let (mut t, mut parts_abs) = (0.0f64, Vec::new());
    for n in 1..=1000000usize {
        t += (n as f64).sin().abs() / n as f64;
        if [100, 10000, 1000000].contains(&n) {
            parts_abs.push((n, t));
        }
    }
    assert!(parts_abs[2].1 - parts_abs[1].1 > 2.5);
    println!("sizes |sin n|/n: {}", parts_abs.iter().map(|(k, v)| format!("N={}: {:.4}", k, v)).collect::<Vec<_>>().join("  "));
    println!("ALL CHECKS PASS");
}
