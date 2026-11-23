// Working on a problem -- the same check as the Python, in Rust.  No crates.
// The problem: u(n), the most pairs among n points in the plane at distance
// exactly 1.  The working file needs lower bounds (point sets, counted here in
// exact arithmetic), upper bounds (a counting argument, done two ways), and the
// literature's table, tested against both.  A point is (xa, xb, ya, yb):
// x = (xa + xb*sqrt3)/10 and y = (ya + yb*sqrt3)/10, so no rounding ever enters.
type P = [i64; 4];

fn is_unit(p: &P, q: &P) -> bool {           // squared distance exactly 1, in Z[sqrt3]/100
    let (a, b, c, d) = (p[0] - q[0], p[1] - q[1], p[2] - q[2], p[3] - q[3]);
    a * a + 3 * b * b + c * c + 3 * d * d == 100 && a * b + c * d == 0
}

fn pairs(pts: &[P]) -> usize {
    let mut k = 0;
    for i in 0..pts.len() { for j in i + 1..pts.len() { if is_unit(&pts[i], &pts[j]) { k += 1 } } }
    k
}

fn most_common_neighbours(pts: &[P]) -> usize { // two unit circles meet in at most 2 points
    let n = pts.len();
    let mut best = 0;
    for i in 0..n { for j in i + 1..n {
        let c = (0..n).filter(|&k| k != i && k != j && is_unit(&pts[i], &pts[k]) && is_unit(&pts[j], &pts[k])).count();
        best = best.max(c);
    } }
    best
}

fn distinct(pts: &[P]) -> usize {
    let mut v = pts.to_vec();
    v.sort();
    v.dedup();
    v.len()
}

fn lattice(a: i64, b: i64) -> P { [10 * a + 5 * b, 0, 0, 5 * b] } // a + b*omega, omega at 60 degrees

fn isqrt(x: i64) -> i64 { let mut r = 0; while (r + 1) * (r + 1) <= x { r += 1 } r }

fn bound_degrees(n: i64) -> i64 {           // largest e whose most even degrees pass the count
    let mut e = 0;
    loop {
        let (q, r) = (2 * (e + 1) / n, 2 * (e + 1) % n);
        if r * (q + 1) * q / 2 + (n - r) * q * (q - 1) / 2 > n * (n - 1) || e == n * (n - 1) / 2 { return e }
        e += 1;
    }
}

fn bound_formula(n: i64) -> i64 {           // u <= n(1 + sqrt(8n - 7))/4, and never above n(n - 1)/2
    ((n as f64 * (1.0 + ((8 * n - 7) as f64).sqrt()) / 4.0) as i64).min(n * (n - 1) / 2)
}

fn erdos_grid(side: i64, m: i64) -> (usize, i64) { // pairs at squared distance m in a side x side grid
    let mut vecs = Vec::new();
    for dx in 0..side { for dy in -side + 1..side {
        if dx * dx + dy * dy == m && (dx > 0 || dy > 0) { vecs.push((dx, dy)) }
    } }
    (vecs.len(), vecs.iter().map(|&(dx, dy)| (side - dx.abs()) * (side - dy.abs())).sum())
}

fn erdos_brute(side: i64, m: i64) -> i64 {
    let pts: Vec<(i64, i64)> = (0..side).flat_map(|i| (0..side).map(move |j| (i, j))).collect();
    let mut k = 0;
    for a in 0..pts.len() { for b in a + 1..pts.len() {
        let (dx, dy) = (pts[a].0 - pts[b].0, pts[a].1 - pts[b].1);
        if dx * dx + dy * dy == m { k += 1 }
    } }
    k
}

fn main() {
    let grid: Vec<P> = (0..3).flat_map(|i| (0..3).map(move |j| [10 * i, 0, 10 * j, 0])).collect();
    let mut patch: Vec<P> = Vec::new();
    for a in -2..3i64 { for b in -2..3i64 { if (a + b).abs() <= 2 { patch.push(lattice(a, b)) } } }
    let np = patch.len();
    let adj: Vec<u32> = (0..np).map(|i| (0..np).filter(|&j| j != i && is_unit(&patch[i], &patch[j]))
        .map(|j| 1u32 << j).sum()).collect();
    let mut best = [0i64; 10];              // best subset of the 19-point patch, by brute force
    for s in 0u32..(1 << np) {
        let n = s.count_ones() as usize;
        if n < 2 || n > 9 { continue }
        let e: u32 = (0..np).filter(|&i| s >> i & 1 == 1).map(|i| (adj[i] & s).count_ones()).sum();
        best[n] = best[n].max(e as i64 / 2);
    }
    let harborth = |n: i64| { let t = 12 * n - 3; let r = isqrt(t); 3 * n - r - if r * r == t { 0 } else { 1 } };
    let tri: [P; 3] = [[0, 0, 0, 0], [10, 0, 0, 0], [5, 0, 0, 5]];       // a unit triangle
    let turned: [P; 3] = [[0, 0, 0, 0], [6, 0, 8, 0], [3, -4, 4, 3]];    // the same, turned by (3/5, 4/5)
    let mut mink: Vec<P> = Vec::new();
    for a in &tri { for b in &turned { mink.push([a[0] + b[0], a[1] + b[1], a[2] + b[2], a[3] + b[3]]) } }
    let gens: [P; 3] = [[10, 0, 0, 0], [0, 0, 10, 0], [6, 0, 8, 0]];
    let cube: Vec<P> = (0..8).map(|m: usize| {
        let mut p = [0i64; 4];
        for (g, v) in gens.iter().enumerate() { if m >> g & 1 == 1 { for k in 0..4 { p[k] += v[k] } } }
        p }).collect();
    let known: [i64; 22] = [0, 0, 1, 3, 5, 7, 9, 12, 14, 18, 20, 23, 27, 30, 33, 37, 41, 43, 46, 50, 54, 57];

    println!("statement: u(n) = most pairs at distance exactly 1 among n distinct points in the plane");
    println!("3 x 3 square grid: {} points, {} unit pairs", grid.len(), pairs(&grid));
    println!("triangular patch: {} points; best n-point subsets by brute force:", np);
    for n in 2..10 {
        println!("  n = {}: lattice best {}, formula floor(3n - sqrt(12n - 3)) = {}, known u(n) = {}", n, best[n], harborth(n as i64), known[n]);
    }
    println!("two triangles summed: {} points, {} unit pairs", distinct(&mink), pairs(&mink));
    let degs: Vec<usize> = mink.iter().map(|p| mink.iter().filter(|q| *q != p && is_unit(p, q)).count()).collect();
    println!("  degrees {:?}; cherries {} <= 2 x {} = {}; second triangle turned {:.2} degrees",
             degs, degs.iter().map(|d| d * (d - 1) / 2).sum::<usize>(), 9 * 8 / 2, 9 * 8, 8f64.atan2(6.0).to_degrees());
    println!("cube shadow from (1,0), (0,1), (3/5,4/5): {} points, {} unit pairs, known u(8) = {}", distinct(&cube), pairs(&cube), known[8]);
    println!("most common neighbours of a pair: grid {}, patch {}, two triangles {}",
             most_common_neighbours(&grid), most_common_neighbours(&patch), most_common_neighbours(&mink));
    println!("upper bound from common neighbours, against the literature (n <= 21):");
    for n in 2..22i64 {
        println!("  n = {}: by degrees {}, by formula {}, known {}, gap {}", n, bound_degrees(n), bound_formula(n), known[n as usize], bound_degrees(n) - known[n as usize]);
    }
    println!("cherry bound at n = 9: sqrt(65) = {:.3}, 9 x {:.3} / 4 = {:.2}", 65f64.sqrt(), 1.0 + 65f64.sqrt(), 9.0 * (1.0 + 65f64.sqrt()) / 4.0);
    let ring = [(1i64, 7i64), (5, 5), (7, 1), (7, -1), (5, -5)]; // on x^2 + y^2 = 50: radius 1/sqrt2, scaled by 10
    let four: Vec<P> = ring.iter().map(|&(a, b)| [a, b, 0, 0]).chain(ring.iter().map(|&(a, b)| [0, 0, a, b])).collect();
    let unit4 = |p: &P, q: &P| (0..4).map(|k| (p[k] - q[k]) * (p[k] - q[k])).sum::<i64>() == 100;
    let all4 = (0..10).map(|i| (i + 1..10).filter(|&j| unit4(&four[i], &four[j])).count()).sum::<usize>();
    let across = (0..5).map(|i| (5..10).filter(|&j| unit4(&four[i], &four[j])).count()).sum::<usize>();
    println!("four dimensions, two circles of 5 points: {} unit pairs among 10 points, {} across the circles; the plane allows u(10) = {}", all4, across, known[10]);
    let cross = (2..1_000_000i64).find(|&n| 1.94 * (n as f64).powf(4.0 / 3.0) < n as f64 * (1.0 + ((8 * n - 7) as f64).sqrt()) / 4.0).unwrap();
    println!("1.94 n^(4/3) at n = 21: {:.1}; it first beats the counting bound at n = {}", 1.94 * 21f64.powf(4.0 / 3.0), cross);
    println!("quoted, not computed: u(n) > n^1.014 for infinitely many n (preprint, 2026-05-20); checked write-up exponent 1 + 6.24e-38");
    let (side, squares) = (30, [1, 25, 65]);   // Erdos's idea: a big grid and a well-chosen distance
    for m in squares {
        let (dirs, count) = erdos_grid(side, m);
        println!("{} x {} grid, squared distance {}: {} directions, {} pairs (brute force {})", side, side, m, 2 * dirs, count, erdos_brute(side, m));
    }
    println!("same idea on the 3 x 3 grid, squared distance 65: {} pairs", erdos_grid(3, 65).1);
    let wrong = (2..10).find(|&n| harborth(n) != known[n as usize]).unwrap();
    println!("lattice pattern guessed as u(n): first fails at n = {}, {} against {}", wrong, harborth(wrong), known[wrong as usize]);
    println!("counting bound read as u(n): first fails at n = {}", (2..22).find(|&n| bound_degrees(n) != known[n as usize]).unwrap());
    let s3 = 3f64.sqrt();
    let f: Vec<String> = mink.iter().map(|p| format!("({:.3} {:.3})",
        (p[0] as f64 + p[1] as f64 * s3) / 10.0, (p[2] as f64 + p[3] as f64 * s3) / 10.0)).collect();
    println!("figure,{}", f.join(","));
    assert!((2..10).all(|n| best[n] == harborth(n as i64)));           // brute force against formula
    assert!(distinct(&mink) == 9 && pairs(&mink) as i64 == known[9]); // construction meets the table
    assert!((2..22).all(|n| bound_degrees(n) == bound_formula(n)));     // two roads to the bound
    assert!((2..22).all(|n| known[n as usize] <= bound_degrees(n)));    // literature passes the proved bound
    assert!((2..10).all(|n| best[n] <= known[n]));                      // constructions never beat the table
    assert!(squares.iter().all(|&m| erdos_grid(side, m).1 == erdos_brute(side, m)));
    assert!(across == 25 && across as i64 > known[10]);              // 4D beats the plane's table
    assert!([&grid, &patch, &mink, &cube].iter().map(|s| most_common_neighbours(s)).max().unwrap() <= 2);
    println!("ALL CHECKS PASS");
}
