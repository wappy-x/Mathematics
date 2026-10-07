// The monotone convergence theorem -- the same check as the Python, in Rust,
// no crates.  The lowest-per-cell sums are exact: whole numbers over 2^(3n)
// in i128.  The series is summed in f64 where the Python keeps fractions.
// River: depth d(x) = 4x(1 - x) metres over a 1 km stretch; integral 2/3.
// Road 1: the staircase through its level sets, lambda(d >= t) = sqrt(1 - t).
// Road 2: the same staircase sampled at M grid midpoints; it never sees a level set.
// Road 3: a different rising sequence, the lowest depth on each of 2^n equal
//         cells, summed exactly and set against the algebra 2/3 - h - 2h^2/3.
// Series on [0, 1/2]: the integrals of x^k added term by term, against ln 2 found
// by Simpson's rule and by the series 2 atanh(1/3).  The code checks finite
// stages; that every rising sequence reaches the limit's integral is the proof's.
const M: usize = 1 << 16; // grid cells for road 2

fn d(x: f64) -> f64 { 4.0 * x * (1.0 - x) } // river depth, metres, x in km
fn stair(v: f64, n: i32) -> f64 {           // round down to marks 2^-n apart, cap n
    let p = 2f64.powi(n);
    (n as f64).min((v * p).floor() / p)
}
fn grid(f: &dyn Fn(f64) -> f64) -> f64 {
    (0..M).map(|i| f((i as f64 + 0.5) / M as f64)).sum::<f64>() / M as f64
}
fn simpson(f: &dyn Fn(f64) -> f64, lo: f64, hi: f64, m: usize) -> f64 { // own integrator, m even
    let w = (hi - lo) / m as f64;
    w / 3.0 * (0..=m).map(|i| f(lo + i as f64 * w) * if i == 0 || i == m { 1.0 } else if i % 2 == 1 { 4.0 } else { 2.0 }).sum::<f64>()
}
fn join(v: &[f64], p: usize) -> String { v.iter().map(|x| format!("{:.*}", p, x)).collect::<Vec<_>>().join(" ") }

fn main() {
    println!("river, grid of {} midpoints; n: staircase by levels | staircase on grid | lowest-per-cell exact | 2/3 - h - 2h^2/3 | stair short | cells short", M);
    let (mut stairs, mut cells): (Vec<f64>, Vec<f64>) = (Vec::new(), Vec::new());
    for n in 1..=10i32 {
        let nn: i128 = 1 << n;
        let by_levels = (1..=nn).map(|k| (1.0 - k as f64 / nn as f64).sqrt()).sum::<f64>() / nn as f64;
        let on_grid = grid(&|x| stair(d(x), n));
        let s: i128 = (0..nn).map(|j| 4 * (j * (nn - j)).min((j + 1) * (nn - j - 1))).sum(); // low = s / N^3
        let cube = nn * nn * nn;
        assert!((by_levels - on_grid).abs() <= 2.0 / M as f64);      // one staircase, two roads
        assert_eq!(3 * s, 2 * cube - 3 * nn * nn - 2 * nn);             // exact sum against the algebra
        let short = 2.0 / 3.0 - by_levels;
        assert!(0.0 < short && short <= 1.0 / nn as f64);              // staircase within 2^-n of d
        let low = s as f64 / cube as f64;
        assert!(stairs.is_empty() || (by_levels > stairs[n as usize - 2] && low > cells[n as usize - 2]));
        stairs.push(by_levels);
        cells.push(low);
        if n == 2 {
            let ls: Vec<f64> = (1..5).map(|k| (1.0 - k as f64 / 4.0).sqrt()).collect();
            println!("river, n=2 level-set lengths, lambda(d >= 1/4, 1/2, 3/4, 1): {}", join(&ls, 10));
        }
        let closed = (2 * cube - 3 * nn * nn - 2 * nn) as f64 / (3 * cube) as f64;
        println!("river, n={}: {:.10} | {:.10} | {:.10} | {:.10} | {:.10} | {:.10}", n, by_levels, on_grid, low,
                 closed, short, (2 * cube - 3 * s) as f64 / (3 * cube) as f64);
    }
    println!("river, both limits: 2/3 = {:.10}, from the antiderivative 2x^2 - 4x^3/3 at x = 1", 2.0 / 3.0);

    let (s_top, c, a, b) = (0.95f64, 0.99f64, 0.4f64, 0.6f64); // test function s: 0.95 m on [0.4, 0.6] km
    assert!(d(a) >= s_top && d(b) >= s_top);                       // s sits under d: d >= 0.96 there
    println!("test sets E_n = {{staircase >= c s}}, c = {}, s = {} on [0.4, 0.6] where d >= {:.2}, c s = {:.4}", c, s_top, d(a), c * s_top);
    println!("test set, n: lowest mark >= c s | length by formula | on grid | c x integral of s on E_n | staircase integral");
    for n in 1..=6i32 {
        let p = 2f64.powi(n);
        let t = (c * s_top * p).ceil() / p;                        // lowest mark at or above c s = 0.9405
        let inside = if t <= 1.0 { (b - a).min((1.0 - t).sqrt()) } else { 0.0 };
        let length = 1.0 - (b - a) + inside;
        let on_grid = grid(&|x| if stair(d(x), n) >= (if a <= x && x <= b { c * s_top } else { 0.0 }) { 1.0 } else { 0.0 });
        assert!((length - on_grid).abs() <= 4.0 / M as f64);
        assert!(c * s_top * inside <= stairs[n as usize - 1]);     // integral of f_n >= c times integral of s on E_n
        println!("test set, n={}: {} | {:.10} | {:.10} | {:.10} | {:.10}", n, t, length, on_grid, c * s_top * inside, stairs[n as usize - 1]);
    }
    println!("test sets, limit: length 1; c x integral of s = {:.10}", c * s_top * (b - a));

    let zero_part = 1.0 - 0.75f64.sqrt();                          // where staircase_2 = 0: d < 1/4
    let mut lens = Vec::new();
    for n in [2.0f64, 10.0, 100.0] {
        lens.push(grid(&|x| if (1.0 - 1.0 / n) * stair(d(x), 2) >= stair(d(x), 2) { 1.0 } else { 0.0 }));
        assert!((lens[lens.len() - 1] - zero_part).abs() <= 4.0 / M as f64);
    }
    println!("c = 1 fails: f_n = (1 - 1/n) staircase_2, length of {{f_n >= staircase_2}}, n = 2, 10, 100: {}; formula 1 - sqrt(3/4) = {:.4}",
             join(&lens, 4), zero_part);

    println!("additivity, d + r with r(x) = x/2, exact 2/3 + 1/4 = 11/12: n | staircase of d + r | stair d + stair r");
    for n in [2i32, 4, 6, 8, 10] {
        let nn = 1i64 << n;
        let joint = grid(&|x| stair(d(x) + x / 2.0, n));
        let apart = stairs[n as usize - 1] + (1..=nn / 2).map(|k| 1.0 - (2 * k) as f64 / nn as f64).sum::<f64>() / nn as f64;
        assert!(0.0 < 11.0 / 12.0 - joint && 11.0 / 12.0 - joint <= 1.0 / nn as f64 + 3.0 / M as f64);
        assert!(0.0 < 11.0 / 12.0 - apart && 11.0 / 12.0 - apart <= 2.0 / nn as f64);
        println!("additivity, n={}: {:.10} | {:.10}", n, joint, apart);
    }
    println!("additivity, 11/12 = {:.10}", 11.0 / 12.0);

    let ln2_simpson = simpson(&|x| 1.0 / (1.0 - x), 0.0, 0.5, 1000);
    let ln2_atanh = 2.0 * (0..30).map(|j| 1.0 / ((2 * j + 1) as f64 * 3f64.powi(2 * j + 1))).sum::<f64>(); // ln 2 = 2 atanh(1/3)
    assert!((ln2_simpson - ln2_atanh).abs() < 1e-12);
    println!("series, ln 2 by Simpson on 1/(1 - x): {:.12}; by 2 atanh(1/3): {:.12}", ln2_simpson, ln2_atanh);
    println!("series on [0, 1/2], term k integrates to 1/(m 2^m) with m = k + 1: N | sum of first N | ln 2 minus it | bound 1/((N+1) 2^N)");
    let mut p = 0.0f64;
    for m in 1..=30i32 {
        p += 1.0 / (m as f64 * 2f64.powi(m));
        if [1, 2, 3, 4, 5, 10, 20, 30].contains(&m) {
            let (gap, bound) = (ln2_atanh - p, 1.0 / ((m + 1) as f64 * 2f64.powi(m)));
            assert!(0.0 < gap && gap <= bound);                      // the tail of the term-by-term sum
            println!("series, N={}: {:.12} | {:.3e} | {:.3e}", m, p, gap, bound);
        }
    }
    let five = simpson(&|x| 1.0 + x + x * x + x * x * x + x * x * x * x, 0.0, 0.5, 1000);
    let five_terms: f64 = (1..=5).map(|m| 1.0 / (m as f64 * 2f64.powi(m))).sum();
    assert!((five - five_terms).abs() < 1e-14);
    let terms: Vec<String> = (1..=5).map(|m| format!("1/{}", m * (1 << m))).collect();
    let den = 960; // lcm of 2, 8, 24, 64, 160
    let num: i64 = (1..=5i64).map(|m| den / (m * (1 << m))).sum();
    assert_eq!(num, 661);
    println!("series, integral of 1 + x + ... + x^4 by Simpson: {:.12}; terms {} = {}/{}", five, terms.join(" + "), num, den);
    let (mut h, mut hs) = (0.0f64, Vec::new());
    for k in 1..=10000 {
        h += 1.0 / k as f64;                                      // integral of x^(k-1) over [0, 1] is 1/k
        if [10, 100, 1000, 10000].contains(&k) { hs.push(h); }
    }
    assert!(hs[3] > 9.0 && hs[3] - hs[2] > 2.3);                  // still climbing by about ln 10 per decade
    println!("series on [0, 1): sums of 1/k, N = 10, 100, 1000, 10000: {}", join(&hs, 6));

    let ns = [1.0f64, 2.0, 4.0, 8.0, 16.0];
    let spikes: Vec<f64> = ns.iter().map(|&n| grid(&|x| if x < 1.0 / n { n } else { 0.0 })).collect();
    assert_eq!(spikes, vec![1.0; 5]);                              // grid count against n x (1/n) = 1
    let at: Vec<String> = [1.0f64, 2.0, 3.0, 4.0, 5.0].iter().map(|&n| if 0.3 < 1.0 / n { format!("{}", n) } else { "0".to_string() }).collect();
    println!("spike n on (0, 1/n), n = 1, 2, 4, 8, 16: integrals {}; value at x = 0.3 for n = 1 to 5: {}; limit function 0, integral 0",
             join(&spikes, 4), at.join(" "));
    let nw: Vec<(usize, usize)> = [1usize, 10, 100].iter().flat_map(|&n| [1000usize, 1000000].map(|w| (n, w))).collect();
    let w: Vec<f64> = nw.iter().map(|&(n, w)| (0..4 * w).filter(|&i| (i as f64 + 0.5) / 4.0 >= n as f64).count() as f64 / 4.0).collect();
    let exact: Vec<f64> = nw.iter().map(|&(n, w)| (w - n) as f64).collect();
    assert!(w == exact);                                          // grid against w - n
    println!("tails, length of [n, infinity) inside [0, w], n = 1, 10, 100, w = 1000 and 10^6: {}",
             w.iter().map(|v| v.to_string()).collect::<Vec<_>>().join(" "));

    let px = |x: f64| 30.0 + 300.0 * x;                            // figure: 300 px per km, 160 px per metre
    let edges: Vec<f64> = [1.0f64, 2.0, 3.0].iter().map(|k| 0.5 - (1.0 - k / 4.0).sqrt() / 2.0).collect();
    let left: Vec<f64> = edges.iter().map(|&e| px(e)).collect();
    let right: Vec<f64> = edges.iter().rev().map(|&e| px(1.0 - e)).collect();
    println!("figure, staircase_2 step edges x px: {} | {} | levels y px 80 120 160 | surface y 40", join(&left, 2), join(&right, 2));
    let bed: Vec<String> = (0..21).map(|i| format!("{:.0},{:.1}", px(i as f64 / 20.0), 40.0 + 160.0 * d(i as f64 / 20.0))).collect();
    println!("figure, bed: {}", bed.join(" "));
    println!("chart, staircase integrals n=1..8: {}", join(&stairs[..8], 2));
    println!("chart, lowest-per-cell integrals n=1..8: {}", join(&cells[..8], 2));
    println!("ALL CHECKS PASS");
}
