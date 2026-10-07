// The integral of a non-negative function -- the same check in Rust, std only.
// River depth d(x) = 4x(1 - x) metres at x km along a 1 km stretch.  Staircases
// below d (depth rounded down to steps of 1/k m) are integrated by three roads:
// piece lengths from the quadratic formula, piece lengths from a bisection root
// finder, and a fine grid of midpoints in x.  Exact 2/3 by integer fractions.

fn depth(x: f64) -> f64 {
    4.0 * x * (1.0 - x)
}

fn length_formula(t: f64) -> f64 { // length of {d >= t}: x from (1 - r)/2 to (1 + r)/2
    if t < 1.0 { (1.0 - t).sqrt() } else { 0.0 }
}

fn length_bisect(t: f64) -> f64 { // road two: halve [0, 0.5] onto the left crossing
    if t >= 1.0 {
        return 0.0; // {d >= 1} is the single point x = 0.5
    }
    let (mut lo, mut hi) = (0.0f64, 0.5f64);
    for _ in 0..60 {
        let mid = (lo + hi) / 2.0;
        if depth(mid) >= t { hi = mid } else { lo = mid }
    }
    1.0 - 2.0 * hi
}

fn staircase(k: usize, length: fn(f64) -> f64, up: f64) -> f64 { // value x length of each piece
    let kf = k as f64;
    (0..k).map(|j| (j as f64 + up) / kf * (length(j as f64 / kf) - length((j as f64 + 1.0) / kf))).sum()
}

fn grid(func: &dyn Fn(f64) -> f64, m: usize) -> f64 { // road three: midpoint sum of a step function
    (0..m).map(|i| func((i as f64 + 0.5) / m as f64)).sum::<f64>() / m as f64
}

fn ln(y: f64) -> f64 { // natural log by the series 2(z + z^3/3 + ...)
    let z = (y - 1.0) / (y + 1.0);
    let (mut total, mut p, mut i) = (0.0, z, 0.0);
    while p.abs() > 1e-17 {
        total += p / (2.0 * i + 1.0);
        p *= z * z;
        i += 1.0;
    }
    2.0 * total
}

fn join(v: &[f64], d: usize) -> String {
    v.iter().map(|x| format!("{:.*}", d, x)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let (num, den) = (2 * 3 - 4, 3); // antiderivative 2x^2 - 4x^3/3 from 0 to 1: 2 - 4/3
    let exact = num as f64 / den as f64;
    let m_grid = 100_000;
    println!("area under d by the antiderivative 2x^2 - 4x^3/3: {}/{} = {:.6} km m", num, den, exact);
    println!("k levels, staircase by formula, by bisection, by grid of 100000 midpoints, upper staircase, gap to 2/3");
    let (mut lows, mut ups): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    for n in 1..9 {
        let k = 1usize << n;
        let kf = k as f64;
        let (a, b) = (staircase(k, length_formula, 0.0), staircase(k, length_bisect, 0.0));
        let c = grid(&|x| (kf * depth(x)).floor() / kf, m_grid);
        let u = staircase(k, length_formula, 1.0);
        assert!((a - b).abs() < 1e-12 && (a - c).abs() <= 2.0 / m_grid as f64 + 1e-12); // three roads
        assert!(den as f64 * a < num as f64 && den as f64 * u > num as f64); // squeezed round 2/3
        assert!(lows.last().map_or(true, |&p| p < a)); // rising
        lows.push(a);
        ups.push(u);
        println!("{:3}, {:.6}, {:.6}, {:.6}, {:.6}, {:.6}", k, a, b, c, u, exact - a);
    }
    println!("chart, lower: {}", join(&lows, 2));
    println!("chart, upper: {}", join(&ups, 2));
    let near = (length_formula(0.25) + length_formula(0.75)) / 2.0;
    println!("k = 2 rounded to nearest, not down: {:.6}, above {:.6}", near, exact);

    let covers: Vec<f64> = [0.1, 0.001, 0.00001].iter().map(|e| 2.0 * e).collect();
    println!("covers of the point x = 0.5 by [0.5 - e, 0.5 + e], e = 0.1, 0.001, 0.00001: {}", join(&covers, 5));
    let left: f64 = (0..1000).map(|j| depth(j as f64 / 1000.0)).sum::<f64>() / 1000.0;
    println!("1000 left-end samples: {:.6}; with the 1000 m spike sampled: {:.6}", left, left + 999.0 / 1000.0);

    println!("t, length of {{d >= t}} by formula, by bisection, Markov bound (2/3)/t, t x length");
    for &t in [0.25, 0.5, 0.75, 0.9].iter() {
        let (l, lb, bound) = (length_formula(t), length_bisect(t), exact / t);
        assert!((l - lb).abs() < 1e-12 && l <= bound && t * l < exact);
        println!("{:.2}, {:.6}, {:.6}, {:.6}, {:.6}", t, l, lb, bound, t * l);
    }
    let f_tight = |x: f64| if (0.25..=0.75).contains(&x) { 0.75 } else { 0.0 }; // f = 0.75 on [0.25, 0.75], 0 elsewhere
    let tight = grid(&f_tight, m_grid); // its integral, on the grid
    let t_len = grid(&|x| if f_tight(x) >= 0.75 { 1.0 } else { 0.0 }, m_grid); // size of {f >= 0.75}
    assert!((tight / 0.75 - t_len).abs() < 1e-12); // Markov met with equality
    println!("tight: f = 0.75 on [0.25, 0.75], integral {:.3}, bound at t = 0.75: {:.3}, true {:.3}", tight, tight / 0.75, t_len);
    let signed_f = |x: f64| if x < 0.5 { 2.0 } else { -2.0 };
    let (s_int, s_len) = (grid(&signed_f, m_grid), grid(&|x| if signed_f(x) >= 1.0 { 1.0 } else { 0.0 }, m_grid));
    assert!(s_len > s_int / 1.0); // Markov fails once f may be negative
    println!("signed f = +2 then -2: integral {:.1}, length of {{f >= 1}} {:.1}, Markov bound {:.1}", s_int, s_len, s_int / 1.0);

    println!("n, staircase of 1/x: layers, grid of 200000, 1 + ln n; staircase of 1/sqrt(x): layers, grid");
    let (mut rec, mut rsq): (Vec<f64>, Vec<f64>) = (vec![], vec![]);
    for &n in [1usize, 2, 4, 8, 16].iter() {
        let (m, nf) = ((1usize << n) as f64, n as f64);
        let top = n * (1usize << n);
        let lay_r: f64 = (1..=top).map(|j| (m / j as f64).min(1.0)).sum::<f64>() / m; // sizes of {f >= j/m}
        let lay_s: f64 = (1..=top).map(|j| (m / j as f64).powi(2).min(1.0)).sum::<f64>() / m;
        let g_r = grid(&|x| ((m / x).floor() / m).min(nf), 200_000);
        let g_s = grid(&|x| ((m / x.sqrt()).floor() / m).min(nf), 200_000);
        assert!((lay_r - g_r).abs() <= nf / 200_000.0 && (lay_s - g_s).abs() <= nf / 200_000.0);
        let lo_r = 1.0 + ln((nf * m + 1.0) / (m + 1.0)); // sum of 1/j beats the integral of 1/x
        let lo_s = 1.0 + m / (m + 1.0) - m / (nf * m + 1.0);
        assert!(lo_r <= lay_r && lay_r <= 1.0 + ln(nf) + 1e-12);
        assert!(lo_s <= lay_s && lay_s <= 2.0 - 1.0 / nf + 1e-12);
        rec.push(lay_r);
        rsq.push(lay_s);
        println!("{:2}, {:.4}, {:.4}, {:.4}; {:.4}, {:.4}", n, lay_r, g_r, 1.0 + ln(nf), lay_s, g_s);
    }
    println!("chart, 1/x: {}", join(&rec, 2));
    println!("chart, 1/sqrt(x): {}", join(&rsq, 2));
    let mut steps: Vec<f64> = [0.25, 0.5, 0.75].iter().map(|&t| 30.0 + 300.0 * (1.0 - length_formula(t)) / 2.0).collect();
    let right: Vec<f64> = steps.iter().rev().map(|s| 360.0 - s).collect();
    steps.extend(right);
    println!("figure, x px {}; y px 80, 120, 160; bed bottom (180, 200)", join(&steps, 1));
    println!("ALL CHECKS PASS");
}
