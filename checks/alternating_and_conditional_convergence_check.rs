// Alternating series -- the check behind the card.  Rust std only.
// Road one adds the terms 1 - 1/2 + 1/3 - ... in order.  Road two builds ln 2
// with no series at all: Simpson's rule on the area under 1/(1+t), t from 0 to 1.

fn simpson(f: impl Fn(f64) -> f64, a: f64, b: f64, panels: usize) -> f64 {
    let h = (b - a) / panels as f64;
    let mut s = f(a) + f(b);
    for i in 1..panels {
        s += if i % 2 == 1 { 4.0 } else { 2.0 } * f(a + i as f64 * h);
    }
    s * h / 3.0
}

fn partial(terms: impl Fn(usize) -> f64, n: usize) -> f64 {
    let mut total = 0.0;
    for k in 1..=n {
        total += terms(k);
    }
    total
}

fn harmonic(k: usize) -> f64 {
    (if k % 2 == 1 { 1.0 } else { -1.0 }) / k as f64
}

fn rearranged(k: usize) -> f64 {
    let (m, r) = ((k + 2) / 3, k % 3);
    if r == 1 { 1.0 / (4 * m - 3) as f64 } else if r == 2 { 1.0 / (4 * m - 1) as f64 } else { -1.0 / (2 * m) as f64 }
}

fn geo_rearranged(k: usize) -> f64 {
    let (m, r) = ((k + 2) / 3, k % 3);
    if r == 1 { 0.25f64.powi(2 * m as i32 - 2) } else if r == 2 { 0.25f64.powi(2 * m as i32 - 1) } else { -0.5 * 0.25f64.powi(m as i32 - 1) }
}

fn row(v: Vec<String>) -> String { v.join(" ") }

fn main() {
    let l = simpson(|t| 1.0 / (1.0 + t), 0.0, 1.0, 2000);
    println!("ln 2 by Simpson, 2000 strips: {:.9}", l);
    println!("chart S_n, n=1..12: {}", row((1..=12).map(|n| format!("{:.2}", partial(harmonic, n))).collect()));
    println!("chart T_n, n=1..12: {}", row((1..=12).map(|n| format!("{:.2}", partial(rearranged, n))).collect()));
    for n in [10usize, 100, 999] {
        let s = partial(harmonic, n);
        let (err, bound) = (l - s, 1.0 / (n + 1) as f64);
        assert!(err.abs() <= bound);
        assert!((err > 0.0) == (n % 2 == 0));
        println!("N={}: S_N={:.9}  ln2-S_N={:+.9}  bound b_(N+1)={:.9}", n, s, err, bound);
    }
    let n_bound = (1..1_000_000usize).find(|&n| 1.0 / (n + 1) as f64 <= 0.001).unwrap();
    let (mut s, mut n_true) = (0.0, 0usize);
    while n_true == 0 || (l - s).abs() > 0.001 {
        n_true += 1;
        s += harmonic(n_true);
    }
    println!("within 0.001: bound certifies N={}; true error first there at N={}", n_bound, n_true);
    for m in [10usize, 100, 1000] {
        let t = partial(rearranged, 3 * m);
        let slack = 1.0 / (4 * m + 1) as f64 + 0.5 / (2 * m + 1) as f64;
        assert!((t - 1.5 * l).abs() <= slack);
        println!("rearranged, {} triples: T={:.9}  (3/2)ln2={:.9}  gap={:+.9}", m, t, 1.5 * l, t - 1.5 * l);
    }
    for m in [8usize, 64] {
        let mut total = 0.0;
        for k in 1..=m {
            total += 1.0 / k as f64;
            total += -1.0 / (2 * k) as f64;
        }
        let half_h = partial(|k| 1.0 / k as f64, m) / 2.0;
        println!("not decreasing, {} pairs: total={:.6}  H_m/2={:.6}", m, total, half_h);
    }
    println!("not shrinking, 1-1+1-...: {}", row((1..=6).map(|n| format!("{:.0}", partial(|k| if k % 2 == 1 { 1.0 } else { -1.0 }, n))).collect()));
    let geo = partial(|k| (-0.5f64).powi(k as i32 - 1), 60);
    let geo_re = partial(geo_rearranged, 60);
    assert!((geo_re - 2.0 / 3.0).abs() < 1e-12);
    println!("1-1/2+1/4-...: in order={:.9}  reordered={:.9}  closed form 2/3={:.9}", geo, geo_re, 2.0 / 3.0);
    println!("all checks passed");
}
