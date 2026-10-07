// Convergence tests -- the check behind the card.  Rust std only; ln() is a
// primitive, and every sum is added here one term at a time.
fn partial(term: fn(u64) -> f64, big_n: u64) -> f64 { // road one: add the terms
    let mut s = 0.0;
    for n in 1..=big_n {
        s += term(n);
    }
    s
}
fn harm(n: u64) -> f64 { 1.0 / n as f64 } // the harmonic series
fn sq(n: u64) -> f64 { 1.0 / (n * n) as f64 } // the squares
fn tele(n: u64) -> f64 { 1.0 / (n * (n + 1)) as f64 } // shifted one place, caps a square
fn half(n: u64) -> f64 { n as f64 / 2f64.powi(n as i32) } // a case the ratio test settles
fn atan(x: f64) -> f64 { // arctangent by its own series
    (0..30).map(|k| (-1f64).powi(k) * x.powi(2 * k + 1) / (2 * k + 1) as f64).sum()
}
fn f2(v: Vec<f64>) -> String {
    v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ")
}

fn main() {
    println!("tests on the harmonic series 1/n and the squares 1/n^2");
    let pts: Vec<u64> = (0..11).map(|k| 1u64 << k).collect();
    let names: Vec<String> = pts.iter().map(|n| n.to_string()).collect();
    println!("figure, n: {}", names.join(" "));
    println!("figure, harmonic partial sums: {}", f2(pts.iter().map(|&n| partial(harm, n)).collect()));
    println!("figure, doubling floor 1 + k/2: {}", f2((0..11).map(|k| 1.0 + k as f64 / 2.0).collect()));
    println!("figure, squares partial sums: {}", f2(pts.iter().map(|&n| partial(sq, n)).collect()));

    for big_n in [1000u64, 1000000] { // road two: area under 1/x is log x
        let h = partial(harm, big_n);
        let (lo, hi) = (((big_n + 1) as f64).ln(), 1.0 + (big_n as f64).ln());
        assert!(lo <= h && h <= hi);
        println!("harmonic N={}: sum {:.6}, integral bounds {:.6} to {:.6}", big_n, h, lo, hi);
    }

    for big_n in [10u64, 1000] { // road two: area under 1/x^2 is 1/N
        let s = partial(sq, big_n);
        println!("squares N={}: sum {:.6}, whole sum between {:.6} and {:.6}",
            big_n, s, s + 1.0 / (big_n + 1) as f64, s + 1.0 / big_n as f64);
    }
    let pi = 16.0 * atan(1.0 / 5.0) - 4.0 * atan(1.0 / 239.0); // Machin's formula builds pi
    let (euler, s) = (pi * pi / 6.0, partial(sq, 1000));
    assert!(s + 1.0 / 1001.0 <= euler && euler <= s + 1.0 / 1000.0); // Euler's value lands in the box
    println!("Euler's value pi^2/6, pi built by Machin: {:.6}, inside the N=1000 bounds", euler);
    let t = 1.0 + partial(tele, 999); // 1 + sum of 1/((n-1)n), n = 2..1000
    assert!((t - (2.0 - 1.0 / 1000.0)).abs() < 1e-12 && s <= t); // telescoping, then the ceiling
    println!("squares ceiling by comparison, N=1000: added {:.6}, telescoped 2 - 1/N = {:.6}", t, 2.0 - 1.0 / 1000.0);

    let n = 1000u64;
    println!("ratio at n={}: harmonic {:.6}, squares {:.6}", n, harm(n + 1) / harm(n), sq(n + 1) / sq(n));
    let r = 1.0 / n as f64;
    println!("root at n={}: harmonic {:.6}, squares {:.6}", n, harm(n).powf(r), sq(n).powf(r));

    let (h20, closed) = (partial(half, 20), 2.0 - 22.0 / 2f64.powi(20));
    assert!((h20 - closed).abs() < 1e-12); // adding against the induction formula
    println!("n/2^n: ratio at n=2 {:.6}, at n=20 {:.6}, root at n=20 {:.6}",
        half(3) / half(2), half(21) / half(20), half(20).powf(1.0 / 20.0));
    println!("n/2^n, N=20: added {:.6}, closed form 2 - 22/2^20 = {:.6}", h20, closed);
    println!("integral of 1/x^2 from 1 to 1000000: {:.6}", 1.0 - 1.0 / 1000000.0);
    println!("All 4 asserts passed.");
}
