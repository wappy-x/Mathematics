// The integral of a simple function -- the same check as the Python, in Rust.
// No crates.  River depth d(x) = 4x(1 - x) metres at x km along a 1 km
// stretch, rounded down to the quarter metre, is a simple function s.
// Road one finds where the depth crosses each level by bisection and adds
// value times length over the pieces {s = value}.  Road two adds the
// overlapping layers {d >= c} with lengths from the square root.  Road three
// averages s over a million-point grid.  Road four cuts every piece at each
// 0.1 km mark.  Then linearity, monotonicity, a die, and what breaks.
const M: usize = 4; // steps per metre: quarter-metre levels
const MF: f64 = 4.0;

fn depth(x: f64) -> f64 {
    4.0 * x * (1.0 - x)
}

fn s(x: f64) -> f64 {
    // depth rounded down to a quarter metre
    (depth(x) * MF).floor() / MF
}

fn left_end(c: f64) -> f64 {
    // smallest x in [0, 0.5] with depth(x) >= c
    let (mut lo, mut hi) = (0.0f64, 0.5f64);
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if depth(mid) >= c { hi = mid; } else { lo = mid; }
    }
    hi
}

fn refined(f: &dyn Fn(f64) -> f64, cuts: &[f64]) -> (f64, usize) {
    // value at the midpoint times width, over the cells of the partition
    let mut pts = vec![0.0, 1.0];
    pts.extend_from_slice(cuts);
    pts.sort_by(|a, b| a.partial_cmp(b).unwrap());
    pts.dedup();
    let total = pts.windows(2).map(|w| f((w[0] + w[1]) / 2.0) * (w[1] - w[0])).sum();
    (total, pts.len() - 1)
}

fn gcd(a: i64, b: i64) -> i64 {
    if b == 0 { a } else { gcd(b, a % b) }
}

fn main() {
    // d = 1 only at x = 0.5: 1 - d = (1 - 2x)^2
    let mut l: Vec<f64> = (0..M).map(|k| left_end(k as f64 / MF)).collect();
    l.push(0.5);
    l.push(0.5);
    println!("layer {{d >= c}}: c, from, to, length (km)");
    for k in 1..=M {
        println!("  c = {:.2}: {:.4} to {:.4}, length {:.4}", k as f64 / MF, l[k], 1.0 - l[k], 1.0 - 2.0 * l[k]);
    }

    // road one: the level sets {s = k/4}, each two intervals, found by bisection
    let piece: Vec<f64> = (0..=M).map(|k| 2.0 * (l[k + 1] - l[k])).collect();
    let mut road1 = 0.0;
    for k in 0..=M {
        let v = k as f64 / MF;
        road1 += v * piece[k];
        println!("road 1, piece s = {:.2} m: length {:.4} km, value x length {:.4}", v, piece[k], v * piece[k]);
    }
    println!("road 1, level sets by bisection: {:.4} km-m", road1);

    // road two: layers {d >= c} overlap; each adds one step of 0.25 m
    let layer: Vec<f64> = (1..=M).map(|k| (1.0 - k as f64 / MF).sqrt()).collect();
    let road2 = layer.iter().sum::<f64>() / MF;
    let shown: Vec<String> = layer[..M - 1].iter().map(|v| format!("{:.4}", v)).collect();
    println!("road 2, layers {} x ({}) = {:.4} km-m; (1 + sqrt 2 + sqrt 3)/8 = {:.6}", 1.0 / MF, shown.join(" + "), road2, road2);
    assert!((road1 - road2).abs() < 1e-12);
    let hits: Vec<f64> = (1..=M).map(|k| k as f64 / MF).filter(|c| depth(0.4) >= *c).collect(); // the layers holding x = 0.4 km
    println!("point 0.4 km: depth {:.4}, level {:.2}; in {} layers, {} x {} = {:.2}; weighted by level {:.2}",
        depth(0.4), s(0.4), hits.len(), 1.0 / MF, hits.len(), hits.len() as f64 / MF, hits.iter().sum::<f64>());
    assert!(hits.len() as f64 / MF == s(0.4));

    // road three: average of s over a grid of a million midpoints; also t <= s
    let n_grid = 1_000_000usize;
    let (mut total, mut t_below) = (0.0f64, true);
    for i in 0..n_grid {
        let x = (i as f64 + 0.5) / n_grid as f64;
        total += s(x);
        t_below = t_below && (depth(x) * 2.0).floor() / 2.0 <= s(x);
    }
    let grid = total / n_grid as f64;
    println!("road 3, grid of {} midpoints: {:.6} km-m", n_grid, grid);
    assert!((grid - road2).abs() < 2.0 * (MF - 1.0) / MF / n_grid as f64); // 2(M - 1) jumps, each off by 1/M m on one cell

    // road four: a finer partition -- every piece cut again at each 0.1 km mark
    let mut ends: Vec<f64> = (1..=M).map(|k| l[k]).collect();
    ends.extend((1..=M).map(|k| 1.0 - l[k]));
    let mut cuts = ends.clone();
    cuts.extend((1..10).map(|j| j as f64 / 10.0));
    let (road4, cells) = refined(&s, &cuts);
    println!("road 4, cut again at every 0.1 km: {} cells, {:.4} km-m", cells, road4);
    assert!((road4 - road1).abs() < 1e-12);

    // linearity: silt u = 0.2 m on [0.3, 0.8), 0.1 m on [0.8, 1]; and scaling to centimetres
    let u = |x: f64| if 0.3 <= x && x < 0.8 { 0.2 } else if x >= 0.8 { 0.1 } else { 0.0 };
    let int_u = 0.2 * 0.5 + 0.1 * 0.2;
    let mut cuts2 = ends.clone();
    cuts2.extend([0.3, 0.8]);
    let (both, cells2) = refined(&|x| s(x) + u(x), &cuts2);
    println!("linearity: integral of silt u = {:.4}; of s + u on {} cells = {:.4}; sum of the two = {:.4}", int_u, cells2, both, road1 + int_u);
    assert!((both - (road1 + int_u)).abs() < 1e-12);
    let (cm, _) = refined(&|x| 100.0 * s(x), &ends);
    println!("scaling: depth in centimetres, integral {:.2} km-cm = 100 x {:.4}", cm, road1);
    assert!((cm - 100.0 * road1).abs() < 1e-9);

    // monotonicity: t = depth rounded down to the half metre sits below s
    let (int_t, _) = refined(&|x| (depth(x) * 2.0).floor() / 2.0, &ends);
    println!("monotonicity: t <= s at every grid point: {}; integral of t = {:.4} <= {:.4}", if t_below { "yes" } else { "no" }, int_t, road1);
    assert!(t_below);
    assert!((int_t - 0.5 * 0.5f64.sqrt()).abs() < 1e-12);

    // the same formula against a probability: a die paying 0, 0, 0, 2, 2, 6
    let pay = [0i64, 0, 0, 2, 2, 6];
    let by_point: i64 = pay.iter().sum(); // over 6
    let mut values = pay.to_vec();
    values.dedup();
    let by_level: i64 = values.iter().map(|v| v * pay.iter().filter(|p| *p == v).count() as i64).sum();
    let (g1, g2) = (gcd(by_point, 6), gcd(by_level, 6));
    println!("die: point by point {}/{}, by level sets {}/{} = {:.4}", by_point / g1, 6 / g1, by_level / g2, 6 / g2, by_level as f64 / 6.0);
    assert!(by_point == by_level);
    assert!(by_level * 3 == 5 * 6);

    // finer steps rise toward the true area 2/3 (the next card's limit)
    for m in [2usize, 4, 8, 16] {
        let low = (1..=m).map(|k| (1.0 - k as f64 / m as f64).sqrt()).sum::<f64>() / m as f64;
        println!("step 1/{} m: lower staircase {:.4}", m, low);
        assert!(low <= 2.0 / 3.0);
    }
    println!("true area under d: 2/3 = {:.4}; staircase average depth {:.4} m, short by {:.4}", 2.0 / 3.0, road1, 2.0 / 3.0 - road1);

    // what breaks
    let (up, _) = refined(&|x| (depth(x) * MF).ceil() / MF, &ends);
    println!("breaks, rounding up: {:.4} km-m, above 2/3; gap to s = {:.4} = {} m x 1 km", up, up - road1, 1.0 / MF);
    assert!((up - road1 - 1.0 / MF).abs() < 1e-12);
    assert!(up > 2.0 / 3.0);
    let levels_only: f64 = (1..M).map(|k| k as f64 / MF).sum();
    let lv: Vec<String> = (1..M).map(|k| format!("{:.2}", k as f64 / MF)).collect();
    println!("breaks, levels added without lengths: {} = {:.2}", lv.join(" + "), levels_only);
    let wrong_layers: f64 = (1..=M).map(|k| k as f64 / MF * (1.0 - 2.0 * l[k])).sum();
    println!("breaks, overlapping layers weighted by their level: {:.4}, not {:.4}", wrong_layers, road1);
    assert!((wrong_layers - road1).abs() > 0.1);
    let n: i64 = 1000; // +1 on [0, inf), -1 on (-inf, 0), summed unit by unit
    let cut: Vec<i64> = [n, 2 * n].iter().map(|&b| (-n..b).map(|j| if j >= 0 { 1 } else { -1 }).sum()).collect();
    println!("breaks, signed pieces +1 on [0, inf), -1 on (-inf, 0): cut at [-{}, {}] gives {}, at [-{}, {}] gives {}", n, n, cut[0], n, 2 * n, cut[1]);
    assert!(cut == vec![0, n]);

    let mut fig: Vec<f64> = ends.iter().copied().filter(|&e| e != 0.5).collect();
    fig.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let xs: Vec<String> = fig.iter().map(|v| format!("{:.1}", 40.0 + 300.0 * v)).collect();
    let ys: Vec<String> = (1..M).map(|k| format!("{:.0}", 200.0 - 160.0 * k as f64 / MF)).collect();
    println!("figure, x = 40 + 300 x, y = 200 - 160 d; ends x = {}; levels y = {}; apex (190, 40)", xs.join(", "), ys.join(", "));
    assert!(200.0 - 160.0 * depth(0.5) == 40.0);
    println!("ALL CHECKS PASS");
}
