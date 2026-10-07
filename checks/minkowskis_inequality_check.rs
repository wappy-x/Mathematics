// Minkowski's inequality -- the same check as the Python, in Rust.  No crates.
// Turbine A's week of daily mean wind speeds (m/s) is the shelf's house example;
// turbine B stands 3 km away.  Each week is a function on 7 days.  Roads: the two
// sides computed directly; p = 2 again from whole-number sums and a square root
// written out here; the Hoelder split of the proof; 3000 random SplitMix64 pairs.
const INF: f64 = f64::INFINITY;

fn norm(f: &[f64], p: f64, w: &[f64]) -> f64 {  // (sum of |f|^p times weight)^(1/p); max where p = inf
    if p == INF {
        return f.iter().zip(w).filter(|(_, wt)| **wt > 0.0).map(|(x, _)| x.abs()).fold(0.0, f64::max);
    }
    f.iter().zip(w).map(|(x, wt)| x.abs().powf(p) * wt).sum::<f64>().powf(1.0 / p)
}

fn sqrt_newton(x: f64) -> f64 {                 // square root by Newton's method, written out
    let mut r = if x > 1.0 { x } else { 1.0 };
    for _ in 0..60 { r = 0.5 * (r + x / r) }
    r
}

fn splitmix(state: u64) -> (u64, u64) {         // SplitMix64: returns (new state, 64-bit output)
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let mut z = s;
    z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn pname(p: f64) -> String { if p == INF { "inf".to_string() } else { format!("{}", p) } }

fn main() {
    let ai: [i64; 7] = [3, 5, 8, 2, 6, 4, 7];
    let bi: [i64; 7] = [5, 2, 4, 6, 1, 3, 2];
    let si: Vec<i64> = ai.iter().zip(&bi).map(|(a, b)| a + b).collect();
    let (a, b): (Vec<f64>, Vec<f64>) = (ai.iter().map(|&x| x as f64).collect(), bi.iter().map(|&x| x as f64).collect());
    let s: Vec<f64> = si.iter().map(|&x| x as f64).collect();
    let (count, prob) = (vec![1.0; 7], vec![1.0 / 7.0; 7]);
    let n = |f: &[f64], p: f64| norm(f, p, &count);
    println!("A = {:?}, B = {:?}, A + B = {:?}  (m/s)", ai, bi, si);
    println!("counting measure: p, ||A+B||_p, ||A||_p + ||B||_p, slack, holds");
    for p in [0.5, 1.0, 1.5, 2.0, 3.0, 4.0, INF] {
        let (l, r) = (n(&s, p), n(&a, p) + n(&b, p));
        println!("  p = {:>3}: {:10.4} {:10.4} {:+9.4}  {}", pname(p), l, r, r - l, if l <= r + 1e-12 { "yes" } else { "NO" });
    }
    let (na, nb, ns) = (n(&a, 2.0), n(&b, 2.0), n(&s, 2.0));
    println!("p = 2 parts: ||A|| = {:.4}, ||B|| = {:.4}, ||A+B|| = {:.4}", na, nb, ns);
    let sa: i64 = ai.iter().map(|x| x * x).sum();
    let sb: i64 = bi.iter().map(|x| x * x).sum();
    let dot: i64 = ai.iter().zip(&bi).map(|(x, y)| x * y).sum();
    let ss = sa + 2 * dot + sb;                 // ||A+B||^2 expanded: no square root taken of it
    let gap_sq = 2.0 * (sqrt_newton((sa * sb) as f64) - dot as f64);
    let slack2 = gap_sq / (sqrt_newton(sa as f64) + sqrt_newton(sb as f64) + sqrt_newton(ss as f64));
    println!("p = 2 by whole numbers: sum A^2 = {}, sum B^2 = {}, sum A*B = {}, sum (A+B)^2 = {}", sa, sb, dot, ss);
    println!("  gap in squares 2(sqrt({}*{}) - {}) = {:.4}; slack = {:.4}", sa, sb, dot, gap_sq, slack2);
    let (ra, rb, rs) = (norm(&a, 2.0, &prob), norm(&b, 2.0, &prob), norm(&s, 2.0, &prob));
    println!("uniform probability 1/7: RMS A = {:.4}, RMS B = {:.4}, RMS A+B = {:.4}, sum = {:.4}", ra, rb, rs, ra + rb);
    println!("  fleet average (A+B)/2: RMS {:.4} <= mean of RMS {:.4}", rs / 2.0, (ra + rb) / 2.0);
    println!("  cube-mean p = 3: A {:.4}, B {:.4}, A+B {:.4}", norm(&a, 3.0, &prob), norm(&b, 3.0, &prob), norm(&s, 3.0, &prob));
    let mut split = Vec::new();
    for p in [2u32, 3] {                        // the proof's split, with Hoelder on each half
        let ia: i64 = ai.iter().zip(&si).map(|(x, t)| x * t.pow(p - 1)).sum();
        let ib: i64 = bi.iter().zip(&si).map(|(x, t)| x * t.pow(p - 1)).sum();
        let tot: i64 = si.iter().map(|t| t.pow(p)).sum();
        let pf = p as f64;
        let (ha, hb) = (n(&a, pf) * n(&s, pf).powf(pf - 1.0), n(&b, pf) * n(&s, pf).powf(pf - 1.0));
        println!("Hoelder split p = {}: sum (A+B)^{} = {} = {} + {}; bounds {:.2} + {:.2}", p, p, tot, ia, ib, ha, hb);
        split.push((ia as f64) <= ha && (ib as f64) <= hb);
    }
    println!("p = inf as a limit: ||A||_p at p = 8, 16, 64: {:.4}, {:.4}, {:.4}; max = {}",
             n(&a, 8.0), n(&a, 16.0), n(&a, 64.0), n(&a, INF));
    let c = -2.5;
    let ca: Vec<f64> = a.iter().map(|x| c * x).collect();
    println!("scaling: ||(-2.5)A||_3 = {:.4}, 2.5 * ||A||_3 = {:.4}", n(&ca, 3.0), f64::abs(c) * n(&a, 3.0));
    let off = [1.0, 1.0, 1.0, 1.0, 1.0, 1.0, 0.0]; // day 7 given weight zero: sensor offline
    let z: [i64; 7] = [0, 0, 0, 0, 0, 0, 9];
    let zf: Vec<f64> = z.iter().map(|&x| x as f64).collect();
    println!("weight 0 on day 7: ||{:?}||_2 = {:.4}, yet the function is not 0 on day 7", z, norm(&zf, 2.0, &off));
    let scaled = |k: f64| -> Vec<f64> { a.iter().map(|x| k * x).collect() };
    println!("B = 2A: ||A+2A||_2 = {:.4}, ||A|| + ||2A|| = {:.4}", n(&scaled(3.0), 2.0), na + n(&scaled(2.0), 2.0));
    println!("B = -2A: ||A-2A||_2 = {:.4}, ||A|| + ||-2A|| = {:.4}", n(&scaled(-1.0), 2.0), na + n(&scaled(-2.0), 2.0));
    println!("mistake, no root at p = 2: sum (A+B)^2 = {} > {} + {} = {}", ss, sa, sb, sa + sb);
    println!("mistake, p = 1/2: {:.4} > {:.4}", n(&s, 0.5), n(&a, 0.5) + n(&b, 0.5));
    let ps = [0.5, 1.0, 1.5, 2.0, 3.0, INF];
    let (mut state, mut fails, mut worst) = (20260929u64, [0u32; 6], [0.0f64; 6]);
    for _ in 0..3000 {
        let mut v = Vec::new();
        for _ in 0..14 {
            let (st, zz) = splitmix(state);
            state = st;
            v.push(((zz >> 33) % 19) as f64 - 9.0);
        }
        let (f, g) = (&v[..7], &v[7..]);
        let h: Vec<f64> = f.iter().zip(g).map(|(x, y)| x + y).collect();
        for (i, &p) in ps.iter().enumerate() {
            let (l, r) = (n(&h, p), n(f, p) + n(g, p));
            if r > 0.0 {
                worst[i] = worst[i].max(l / r);
                if l > r * (1.0 + 1e-12) { fails[i] += 1 }
            }
        }
    }
    println!("3000 random pairs, entries -9..9: p, failures, largest ||f+g|| / (||f|| + ||g||)");
    for (i, &p) in ps.iter().enumerate() { println!("  p = {:>3}: {:4}  {:.6}", pname(p), fails[i], worst[i]) }
    let chart = [0.5, 0.75, 1.0, 1.5, 2.0, 3.0, 4.0, 8.0, 16.0];
    let cp: Vec<String> = chart.iter().map(|&p| pname(p)).collect();
    let cr: Vec<String> = chart.iter().map(|&p| format!("{:.2}", n(&s, p) / (n(&a, p) + n(&b, p)))).collect();
    println!("chart, p:     {}", cp.join(" "));
    println!("chart, ratio: {}", cr.join(" "));
    let (la, lb, ls) = (n(&a[..2], 2.0), n(&b[..2], 2.0), n(&s[..2], 2.0));
    println!("figure, days 1-2 at 20 units per m/s from (40, 200): A tip (100, 100), sum tip (200, 60), lengths {:.3} + {:.3} = {:.3} vs {:.3}",
             la, lb, la + lb, ls);
    assert!(((na + nb - ns) - slack2).abs() < 1e-9);   // p = 2 slack: roots of sums vs whole numbers
    assert!(split.iter().all(|&ok| ok));                // Hoelder bounds each half of the split
    assert!(fails[1..].iter().all(|&k| k == 0) && fails[0] > 0);
    assert!((n(&ca, 3.0) - 2.5 * n(&a, 3.0)).abs() < 1e-9); // scaling, list rescaled vs norm rescaled
    assert!((n(&a, 64.0) - n(&a, INF)).abs() < 1e-3);   // large p approaches the sup-norm
    assert!((n(&scaled(3.0), 2.0) - (na + n(&scaled(2.0), 2.0))).abs() < 1e-9); // t = 2: equality
    assert!(n(&scaled(-1.0), 2.0) < na + n(&scaled(-2.0), 2.0) - 1.0);          // t = -2: strict
    assert!(norm(&zf, 2.0, &off) == 0.0);               // size zero, function not zero
    println!("ALL CHECKS PASS");
}
