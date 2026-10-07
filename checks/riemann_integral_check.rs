// The Riemann integral -- the same check as the Python, in Rust.  No crates.
// A tank fills at f(t) = 3 + 2t litres per minute from t = 0 to t = 10 minutes.
// Road one: lower and upper sums, slice by slice.  Road two: the closed form
// 130 -/+ 100/n, from 0 + 1 + ... + (n - 1) = n(n - 1)/2.  Road three: geometry,
// a 3-by-10 rectangle under a triangle of base 10 and height 20.
fn rate(t: f64) -> f64 { 3.0 + 2.0 * t }

fn valve(t: f64) -> f64 { if t < 4.0 { 3.0 } else { 8.0 } }   // second case: wider at t = 4

fn sums(f: fn(f64) -> f64, cuts: &[f64]) -> (f64, f64) {     // monotone: extremes at slice ends
    let (mut lo, mut hi) = (0.0, 0.0);
    for w in cuts.windows(2) {
        let (s, u) = (w[0], w[1]);
        lo += f(s).min(f(u)) * (u - s);
        hi += f(s).max(f(u)) * (u - s);
    }
    (lo, hi)
}

fn even(n: usize) -> Vec<f64> { (0..=n).map(|k| 10.0 * k as f64 / n as f64).collect() }

fn gap(f: fn(f64) -> f64, n: usize) -> f64 { let (lo, hi) = sums(f, &even(n)); hi - lo }

fn row(xs: &[f64], d: usize) -> String {
    xs.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let geometry = 3.0 * 10.0 + 10.0 * 20.0 / 2.0;
    println!("tank: rate 3 + 2t litres per minute, {:.0} at t = 0, {:.0} at t = 10; geometry 3 x 10 + 10 x 20 / 2 = {:.1}",
             rate(0.0), rate(10.0), geometry);
    for n in [5usize, 10, 100, 1000] {
        let (lo, hi) = sums(rate, &even(n));
        let nf = n as f64;
        println!("n = {}, width {}: lower {:.1}, upper {:.1}, gap {:.1}", n, 10.0 / nf, lo, hi, hi - lo);
        assert!((lo - (130.0 - 100.0 / nf)).abs() < 1e-9 && (hi - (130.0 + 100.0 / nf)).abs() < 1e-9);
        assert!(lo <= geometry && geometry <= hi && ((hi - lo) * nf - 200.0).abs() < 1e-6);
    }
    println!("n = 5, rate at each cut: {}", row(&even(5).iter().map(|&t| rate(t)).collect::<Vec<_>>(), 0));
    let ns = [1usize, 2, 4, 5, 10, 20, 50, 100];
    let nsf: Vec<f64> = ns.iter().map(|&n| n as f64).collect();
    let lows: Vec<f64> = ns.iter().map(|&n| sums(rate, &even(n)).0).collect();
    let highs: Vec<f64> = ns.iter().map(|&n| sums(rate, &even(n)).1).collect();
    println!("chart n: {}; lower: {}", row(&nsf, 0), row(&lows, 0));
    println!("chart upper: {}", row(&highs, 0));
    let (c, r) = (sums(rate, &[0.0, 5.0, 10.0]), sums(rate, &[0.0, 2.0, 5.0, 10.0]));
    println!("refine: cuts 0, 5, 10 give lower {:.1}, upper {:.1}; a cut at 2 gives {:.1}, {:.1}", c.0, c.1, r.0, r.1);
    assert!(c.0 <= r.0 && r.0 <= geometry && geometry <= r.1 && r.1 <= c.1);   // extra cut tightens
    let n1 = (1..10_000).find(|&n| gap(rate, n) <= 1.0 + 1e-9).unwrap();         // road one, searched
    let n2 = (19_900..20_100).find(|&n| gap(rate, n) <= 0.01 + 1e-9).unwrap();
    println!("gap at most 1 litre first at n = {}, width {}; at most 0.01 litres needs n = {}", n1, 10.0 / n1 as f64, n2);
    for n in [7usize, 100] {
        let (lo, hi) = sums(valve, &even(n));
        println!("valve, exact 3 x 4 + 8 x 6 = 60, n = {}: lower {:.3}, upper {:.3}, gap {:.3}", n, lo, hi, hi - lo);
        let exact = 3.0 * 4.0 + 8.0 * 6.0;
        assert!(lo - 1e-9 <= exact && exact <= hi && ((hi - lo) * n as f64 - 50.0).abs() < 1e-6);
    }
    let e5 = even(5);
    let xs: Vec<f64> = e5.iter().map(|t| 40.0 + 28.0 * t).collect();
    let low_y: Vec<f64> = e5[..5].iter().map(|&t| 215.0 - 8.0 * rate(t)).collect();
    let up_y: Vec<f64> = e5[1..].iter().map(|&t| 215.0 - 8.0 * rate(t)).collect();
    println!("figure, 28 px per minute, 8 px per litre/min; slice edges x = {}", row(&xs, 0));
    println!("figure, lower tops y = {}; upper tops y = {}", row(&low_y, 0), row(&up_y, 0));
    println!("mistake 1, lower sum at n = 10 taken as the total: {:.1}", sums(rate, &even(10)).0);
    let heights: f64 = even(20)[1..].iter().map(|&t| rate(t)).sum();
    println!("mistake 2, 20 slice rates added without widths: {:.1}", heights);
    let inside = [4usize, 100, 10000].iter().all(|&n| (0..n).all(|k| {
        let (s, u, tag) = (k as f64 / n as f64, (k + 1) as f64 / n as f64,
                           k as f64 / n as f64 + 2f64.sqrt() / (4.0 * n as f64));
        s < tag && tag < u
    }));
    println!("mistake 3, fraction rule on [0, 1]: a sqrt(2) tag inside every slice: {}; lower 0, upper 1 at n = 4, 100, 10000",
             if inside { "yes" } else { "no" });
    println!("ALL CHECKS PASS");
}
