// Tonelli and Fubini -- the same check as the Python, in Rust.  No crates.
// A dart lands uniformly on the 1 m x 1 m board [0, 1] x [0, 1]; D is its
// distance from the centre (0.5, 0.5).  E[D] five ways: y first with an exact
// inner integral, x first with numerical inner integrals, a grid of small
// squares summed by rows and by columns, the closed form, and thrown darts.
// Then f = (x^2 - y^2)/(x^2 + y^2)^2, whose two orders disagree; a
// non-negative double series summed both ways; and the +1/-1 table.

fn simpson(g: &dyn Fn(f64) -> f64, a: f64, b: f64, n: usize) -> f64 {
    // n even
    let h = (b - a) / n as f64;
    let inner: f64 = (1..n).map(|i| (if i % 2 == 1 { 4.0 } else { 2.0 }) * g(a + i as f64 * h)).sum();
    (g(a) + g(b) + inner) * h / 3.0
}

fn dist(x: f64, y: f64) -> f64 {
    ((x - 0.5).powi(2) + (y - 0.5).powi(2)).sqrt()
}

fn slice_y(x: f64) -> f64 {
    // integral of D over y in [0, 1], by antiderivative
    let a = (x - 0.5).abs();
    let r = (a * a + 0.25).sqrt();
    0.5 * r + if a > 0.0 { a * a * ((0.5 + r) / a).ln() } else { 0.0 }
}

fn arctan_series(t: f64) -> f64 {
    // |t| < 1
    let (mut s, mut p, mut k) = (0.0, t, 0.0);
    while p.abs() > 1e-18 {
        s += p / (2.0 * k + 1.0);
        p *= -t * t;
        k += 1.0;
    }
    s
}

fn splitmix(s: u64) -> (u64, u64) {
    // SplitMix64: returns (new state, 64 random bits)
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}

fn row(v: impl Iterator<Item = f64>) -> String {
    v.map(|t| format!("{:.2}", t)).collect::<Vec<_>>().join(", ")
}

fn main() {
    let pi = 16.0 * arctan_series(1.0 / 5.0) - 4.0 * arctan_series(1.0 / 239.0); // Machin's formula
    println!("pi by Machin's series: {:.11}", pi);

    // 1. the dartboard, E[D] by several roads
    let (r2, l2) = (2f64.sqrt(), (1.0 + 2f64.sqrt()).ln());
    let closed = (r2 + l2) / 6.0;
    let y_first = simpson(&slice_y, 0.0, 1.0, 2000);
    let x_first = simpson(&|y: f64| simpson(&|x: f64| dist(x, y), 0.0, 1.0, 400), 0.0, 1.0, 400);
    let m = 600;
    let mf = m as f64;
    let cell: Vec<Vec<f64>> = (0..m).map(|i| (0..m).map(|j| dist((i as f64 + 0.5) / mf, (j as f64 + 0.5) / mf)).collect()).collect();
    let rows_first = (0..m).map(|i| (0..m).map(|j| cell[i][j]).sum::<f64>()).sum::<f64>() / (mf * mf);
    let cols_first = (0..m).map(|j| (0..m).map(|i| cell[i][j]).sum::<f64>()).sum::<f64>() / (mf * mf);
    let (mut state, n_darts, mut s1, mut s2) = (2026u64, 100000, 0.0, 0.0);
    for _ in 0..n_darts {
        let (st, u) = splitmix(state);
        let (st, v) = splitmix(st);
        state = st;
        let d = dist((u >> 11) as f64 / 2f64.powi(53), (v >> 11) as f64 / 2f64.powi(53));
        s1 += d;
        s2 += d * d;
    }
    let mc = s1 / n_darts as f64;
    let se = ((s2 / n_darts as f64 - mc * mc) / n_darts as f64).sqrt();
    println!("dart, closed form (sqrt 2 + ln(1 + sqrt 2))/6: {:.6}", closed);
    println!("dart, y first (exact inner, Simpson outer): {:.6}", y_first);
    println!("dart, x first (Simpson inner and outer): {:.6}", x_first);
    println!("dart, grid of {} x {} squares: rows first {:.6}, columns first {:.6}", m, m, rows_first, cols_first);
    println!("dart, {} thrown darts, SplitMix64 seed 2026: mean {:.4}, standard error {:.4}", n_darts, mc, se);
    assert!((y_first - closed).abs() < 1e-8);
    assert!((x_first - closed).abs() < 1e-5);
    assert!((rows_first - closed).abs() < 1e-5);
    assert!((mc - closed).abs() < 4.0 * se);
    println!("slice averages at x = 0, 0.1, ..., 1: {}", row((0..11).map(|k| slice_y(k as f64 / 10.0))));
    println!("by hand, slice at x = 0: 0.5 sqrt(0.5) = {:.4}, 0.25 ln(1 + sqrt 2) = {:.4}, sum {:.4}; slice at x = 0.5: {:.4}",
        0.5 * 0.5f64.sqrt(), 0.25 * l2, slice_y(0.0), slice_y(0.5));
    println!("by hand, sqrt 2 = {:.6}, ln(1 + sqrt 2) = {:.6}, sum {:.6}, divided by 6 = {:.6}", r2, l2, r2 + l2, closed);
    println!("figure, board 0 to 1 m, centre (0.5, 0.5), dart (0.8, 0.3) at D = {:.4}, strips x 0.2 to 0.25 and y 0.7 to 0.75", dist(0.8, 0.3));

    // 2. f = (x^2 - y^2)/(x^2 + y^2)^2 on (0, 1] x (0, 1]: the two orders disagree
    let f = |x: f64, y: f64| (x * x - y * y) / (x * x + y * y).powi(2);
    let a_in = |x: f64| 1.0 / (1.0 + x * x); // y-integral of f: [y/(x^2 + y^2)] from 0 to 1
    let (iy, ix) = (simpson(&|y: f64| f(0.5, y), 0.0, 1.0, 2000), simpson(&|x: f64| f(x, 0.5), 0.0, 1.0, 2000));
    println!("f, inner y-integral at x = 0.5: Simpson {:.6}, antiderivative 1/(1 + x^2) = {:.6}", iy, a_in(0.5));
    println!("f, inner x-integral at y = 0.5: Simpson {:.6}, antiderivative -1/(1 + y^2) = {:.6}", ix, -a_in(0.5));
    assert!((iy - a_in(0.5)).abs() < 1e-9);
    assert!((ix + a_in(0.5)).abs() < 1e-9);
    let yx = simpson(&a_in, 0.0, 1.0, 2000);
    let xy = simpson(&|y: f64| -1.0 / (1.0 + y * y), 0.0, 1.0, 2000);
    println!("f, y first then x: {:.6} (pi/4 = {:.6}); x first then y: {:.6} (-pi/4 = {:.6})", yx, pi / 4.0, xy, -pi / 4.0);
    assert!((yx - pi / 4.0).abs() < 1e-10);
    assert!((xy + pi / 4.0).abs() < 1e-10);
    println!("chart, y-first inner integral 1/(1 + x^2): {}", row((0..11).map(|k| a_in(k as f64 / 10.0))));
    println!("chart, x-first inner integral -1/(1 + y^2): {}", row((0..11).map(|k| -a_in(k as f64 / 10.0))));
    let ry = simpson(&|x: f64| 2.0 / (x * x + 4.0), 0.0, 1.0, 2000);
    let rx = -simpson(&|y: f64| 1.0 / (1.0 + y * y), 0.0, 2.0, 2000);
    println!("f on [0, 1] x [0, 2]: y first {:.6}, x first {:.6}, gap {:.6} (pi/2 = {:.6})", ry, rx, ry - rx, pi / 2.0);
    assert!(((ry - rx) - pi / 2.0).abs() < 1e-10);
    for e in [0.1f64, 0.01, 0.001] {
        // |f| over [e, 1]^2, exact inner integral, outer in t = ln x
        let g = |x: f64| 1.0 / x - e / (x * x + e * e) - 1.0 / (1.0 + x * x);
        let num = simpson(&|t: f64| g(t.exp()) * t.exp(), e.ln(), 0.0, 4000);
        let form = (1.0 / e).ln() - (pi / 2.0 - arctan_series(e)) + arctan_series(e);
        let sq = simpson(&|t: f64| (1.0 / (1.0 + (2.0 * t).exp()) - e / ((2.0 * t).exp() + e * e)) * t.exp(), e.ln(), 0.0, 4000);
        println!("|f| on [e, 1]^2, e = {}: Simpson {:.6}, formula ln(1/e) - arctan(1/e) + arctan(e) = {:.6}; f itself, size of total {:.6}",
            e, num, form, sq.abs());
        let gx: f64 = [(e, 0.5), (0.5, 1.0)].iter().map(|&(a, b)| simpson(&|y: f64| f(0.5, y).abs(), a, b, 2000)).sum();
        assert!((gx - g(0.5)).abs() < 1e-6); // the exact inner integral of |f| matches |f| itself
        assert!((num - form).abs() < 1e-6);
        assert!(sq.abs() < 1e-6);
    }

    // 3. double series: the +1/-1 table b(i, j) = [j = i] - [j = i + 1]
    let band = |i: i64, j: i64| (j == i) as i64 - (j == i + 1) as i64;
    let n = 10i64;
    let rows: Vec<i64> = (1..=n).map(|i| (1..=i + 1).map(|j| band(i, j)).sum()).collect(); // row i lives on j = i, i + 1
    let cols: Vec<i64> = (1..=n).map(|j| (1..=j).map(|i| band(i, j)).sum()).collect(); // column j lives on i = j - 1, j
    let corner = |c: i64| -> i64 { (1..=n).map(|i| (1..=c).map(|j| band(i, j)).sum::<i64>()).sum() };
    let (square, wide) = (corner(n), corner(n + 1)); // n x n and n x (n + 1) corners
    let absn: i64 = (1..=n).map(|i| (1..=n + 1).map(|j| band(i, j).abs()).sum::<i64>()).sum();
    let (rs, cs): (i64, i64) = (rows.iter().sum(), cols.iter().sum());
    println!("table, complete rows {:?}...: rows first {}; complete columns {:?}...: columns first {}; absolute entries in the first {} rows {}",
        &rows[..4], rs, &cols[..4], cs, n, absn);
    println!("table, finite {} x {} corner: total {} in either order; {} x {} corner, more columns than rows: total {}", n, n, square, n, n + 1, wide);
    assert_eq!(rs, 0);
    assert_eq!(cs, 1);
    assert_eq!((square, wide), (1, 0));

    // 4. Tonelli on counting measure: sum over n >= 2 of (zeta(n) - 1), rows versus columns
    let zeta_minus_1 = |n: i32| -> f64 {
        // direct sum to M plus Euler-Maclaurin tail
        let mm = 1000f64;
        (2..=1000).map(|k| (k as f64).powi(-n)).sum::<f64>() + mm.powi(1 - n) / (n - 1) as f64 - mm.powi(-n) / 2.0
            + n as f64 * mm.powi(-n - 1) / 12.0
    };
    let z: Vec<f64> = (2..61).map(zeta_minus_1).collect();
    println!("zeta(2) - 1: series {:.6}, pi^2/6 - 1 = {:.6}; zeta(3) - 1 = {:.6}", z[0], pi * pi / 6.0 - 1.0, z[1]);
    assert!((z[0] - (pi * pi / 6.0 - 1.0)).abs() < 1e-12);
    let zs: f64 = z.iter().sum();
    println!("rows first, sum over n = 2..60 of zeta(n) - 1: {:.9}", zs);
    let col2: f64 = (2..61).map(|n| 2f64.powi(-n)).sum();
    let cols_z: f64 = (2..1001).map(|k| 1.0 / (k as f64 * (k - 1) as f64)).sum();
    println!("columns first, column k totals 1/(k(k - 1)); column 2 by its series {:.6}; columns 2..1000: {:.6} = 1 - 1/1000", col2, cols_z);
    assert!((zs - 1.0).abs() < 1e-12);
    assert!((cols_z - (1.0 - 1.0 / 1000.0)).abs() < 1e-12);
    let diag: Vec<(f64, f64)> = (0..1000).map(|i| (i as f64 + 0.5) / 1000.0).map(|t| (t, t)).collect(); // the diagonal at 1000 points
    let v_d = diag.iter().map(|&(x, _)| diag.iter().filter(|&&(u, _)| u == x).count()).sum::<usize>() as f64 / 1000.0; // length on x: count each vertical section, times width
    let h_d: f64 = diag.iter().map(|&(_, y)| { // counting on y: add each horizontal section's length
        let s: Vec<f64> = diag.iter().filter(|&&(_, v)| v == y).map(|&(u, _)| u).collect();
        s.iter().cloned().fold(f64::MIN, f64::max) - s.iter().cloned().fold(f64::MAX, f64::min)
    }).sum();
    println!("breaks, not sigma-finite: diagonal of [0, 1]^2 at 1000 points, length on x and counting on y; the orders give {} and {}", v_d, h_d);
    println!("ALL CHECKS PASS");
}
