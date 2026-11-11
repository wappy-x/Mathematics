// Interior point for linear programs -- the check behind the card.  std only, no crates.
// Roads to the answer: the primal-dual interior point method; every corner of the
// workshop's region listed in exact fractions; the prices y = (3, 0, 7) checked as a
// dual bound that meets the best corner.  Then the worst cases: the simplex method on
// Klee-Minty cubes against the interior point count on the same cubes.
type V = Vec<f64>;
type Hist = Vec<(usize, V, V, f64, f64)>;
fn dot(u: &[f64], v: &[f64]) -> f64 { let mut t = 0.0; for (a, b) in u.iter().zip(v) { t += a * b; } t }
fn f4(v: f64) -> String { format!("{:.4}", v) }
fn list(v: &[f64]) -> String { v.iter().map(|&a| f4(a)).collect::<Vec<_>>().join(", ") }
fn col(a: &[V], j: usize) -> V { a.iter().map(|r| r[j]).collect() }

fn solve(m0: &[V], r: &[f64]) -> V { // Gaussian elimination with row swaps
    let n = r.len();
    let mut m: Vec<V> = (0..n).map(|i| { let mut row = m0[i].clone(); row.push(r[i]); row }).collect();
    for k in 0..n {
        let mut p = k;
        for i in k + 1..n { if m[i][k].abs() > m[p][k].abs() { p = i; } }
        m.swap(k, p);
        for i in k + 1..n {
            let f = m[i][k] / m[k][k];
            for j in k..n + 1 { let v = m[k][j]; m[i][j] -= f * v; }
        }
    }
    let mut x = vec![0.0; n];
    for k in (0..n).rev() { x[k] = (m[k][n] - dot(&m[k][k + 1..n], &x[k + 1..])) / m[k][k]; }
    x
}

// one primal-dual Newton direction, x and y feasible: returns s, mu, M, dx, dy, ds
fn newton(a: &[V], c: &[f64], x: &[f64], y: &[f64], sigma: f64) -> (V, f64, Vec<V>, V, V, V) {
    let (m, n) = (a.len(), c.len());
    let s: V = (0..n).map(|j| dot(&col(a, j), y) - c[j]).collect();
    let mu = dot(x, &s) / n as f64;
    let r: V = (0..n).map(|j| sigma * mu - x[j] * s[j]).collect();
    let d: V = (0..n).map(|j| x[j] / s[j]).collect();
    let mm: Vec<V> = (0..m).map(|i| (0..m).map(|l| dot(&(0..n).map(|j| a[i][j] * d[j]).collect::<V>(), &a[l])).collect()).collect();
    let rs: V = (0..n).map(|j| r[j] / s[j]).collect();
    let dy = solve(&mm, &(0..m).map(|i| dot(&a[i], &rs)).collect::<V>());
    let ds: V = (0..n).map(|j| dot(&col(a, j), &dy)).collect();
    let dx: V = (0..n).map(|j| (r[j] - x[j] * ds[j]) / s[j]).collect();
    (s, mu, mm, dx, dy, ds)
}

fn ipm(a: &[V], c: &[f64], x0: &[f64], y0: &[f64], sigma: f64, eta: Option<f64>, cap: usize, h: &mut Hist) -> (usize, V, V) {
    let (mut x, mut y) = (x0.to_vec(), y0.to_vec());
    let n = x.len();
    for k in 0..=cap {
        let (s, _, _, dx, dy, ds) = newton(a, c, &x, &y, sigma);
        let gap = dot(&x, &s);
        let mut amax = 1e9;
        for j in 0..n { if dx[j] < 0.0 { amax = f64::min(amax, -x[j] / dx[j]); } if ds[j] < 0.0 { amax = f64::min(amax, -s[j] / ds[j]); } }
        let al = match eta { None => 1.0, Some(e) => f64::min(1.0, e * amax) };
        h.push((k, x.clone(), y.clone(), gap, al));
        if gap <= 1e-8 * (1.0 + dot(c, &x).abs()) || k == cap { return (k, x, y); }
        for j in 0..n { x[j] += al * dx[j]; }
        for i in 0..y.len() { y[i] += al * dy[i]; }
    }
    unreachable!()
}

fn km_simplex(n: usize) -> (usize, i128) { // Dantzig's rule, integer tableau: every pivot is 1
    let mut t: Vec<Vec<i128>> = (0..n).map(|i| {
        let mut row: Vec<i128> = (0..2 * n).map(|j| if j < i { 2 * 10i128.pow((i - j) as u32) } else { (j == i || j == n + i) as i128 }).collect();
        row.push(100i128.pow(i as u32)); row }).collect();
    let mut z: Vec<i128> = (0..n).map(|j| -(10i128.pow((n - 1 - j) as u32))).chain(vec![0; n + 1]).collect();
    let mut piv = 0;
    loop {
        let mut j = 0;
        for k in 1..2 * n { if z[k] < z[j] { j = k; } }
        if z[j] >= 0 { return (piv, z[2 * n]); }
        let mut r = usize::MAX;
        for i in 0..n { if t[i][j] > 0 && (r == usize::MAX || t[i][2 * n] * t[r][j] < t[r][2 * n] * t[i][j]) { r = i; } }
        assert!(t[r][j] == 1);
        let tr = t[r].clone();
        for i in 0..n { if i != r { let f = t[i][j]; for q in 0..=2 * n { t[i][q] -= f * tr[q]; } } }
        let f = z[j]; for q in 0..=2 * n { z[q] -= f * tr[q]; }
        piv += 1;
    }
}

fn km_ipm(n: usize) -> (usize, V) { // the same cube with each x_j measured in units of 100^j
    let mut p = vec![1.0];
    for _ in 0..n { let l = p[p.len() - 1] / 10.0; p.push(l); }
    let a: Vec<V> = (0..n).map(|i| (0..2 * n).map(|j| if j < i { 2.0 * p[i - j] } else if j == i || j == n + i { 1.0 } else { 0.0 }).collect()).collect();
    let x: V = (0..2 * n).map(|i| if i < n { 0.1 } else { 1.0 - dot(&a[i - n][..n], &vec![0.1; n]) }).collect();
    let c: V = (0..n).map(|j| p[n - 1 - j]).chain(vec![0.0; n]).collect();
    let (k, x, _) = ipm(&a, &c, &x, &vec![2.0; n], 0.1, Some(0.9), 200, &mut Vec::new());
    (k, x)
}

fn frac(n: i64, d: i64) -> String { if n % d == 0 { format!("{}", n / d) } else { format!("{}/{}", n, d) } }

fn main() {
    let a: Vec<V> = vec![vec![4.0, 2.0, 1.0, 0.0, 0.0], vec![3.0, 1.0, 0.0, 1.0, 0.0], vec![1.0, 2.0, 0.0, 0.0, 1.0]];
    let (b, c) = (vec![160.0, 120.0, 64.0], vec![19.0, 20.0, 0.0, 0.0, 0.0]);
    let (x0, y0) = (vec![10.0, 10.0, 100.0, 80.0, 34.0], vec![5.0, 5.0, 5.0]);
    println!("maximise 19 x1 + 20 x2 pounds: timber 4,2 <= 160 m; labour 3,1 <= 120 h; finish 1,2 <= 64 l");
    let (s, mu, mm, dx, dy, ds) = newton(&a, &c, &x0, &y0, 0.1);
    println!("start x = ({}), y = (5, 5, 5), s = ({})", list(&x0), list(&s));
    println!("gap x.s = {}, mu = {}, target sigma*mu = {}", f4(dot(&x0, &s)), f4(mu), f4(0.1 * mu));
    println!("M = A D A^T rows: {}", mm.iter().map(|r| list(r)).collect::<Vec<_>>().join("; "));
    println!("dy = ({}), ds = ({}), dx = ({})", list(&dy), list(&ds), list(&dx));
    let mut amax = f64::INFINITY;
    for j in 0..5 { if ds[j] < 0.0 { amax = f64::min(amax, -s[j] / ds[j]); } }
    println!("largest safe step {} (chairs' surplus s2 hits 0); take 0.9 of it: alpha = {}", f4(amax), f4(0.9 * amax));
    println!("new gap predicted 1330 * (1 - alpha * 0.9) = {}", f4(1330.0 * (1.0 - 0.9 * amax * 0.9)));
    let mut h: Hist = Vec::new();
    let (k, x, y) = ipm(&a, &c, &x0, &y0, 0.1, Some(0.9), 200, &mut h);
    println!(" k   tables    chairs    profit     bound       gap   step");
    for (j, xj, yj, g, al) in &h { println!("{:2} {:8.4} {:9.4} {:9.4} {:9.4} {:9.6} {:6.4}", j, xj[0], xj[1], dot(&c, xj), dot(&b, yj), g, al); }
    println!("chart log10 gap: {}", h.iter().map(|e| format!("{:.2}", e.3.log10())).collect::<Vec<_>>().join(", "));
    println!("stop after {} iterations: plan ({}, {}), prices y = ({})", k, f4(x[0]), f4(x[1]), list(&y));
    let (pw, qw): ([[i64; 2]; 5], [i64; 5]) = ([[4, 2], [3, 1], [1, 2], [-1, 0], [0, -1]], [160, 120, 64, 0, 0]);
    let mut corners: Vec<(i64, i64, i64)> = Vec::new(); // (num x1, num x2, common denominator > 0)
    for p in 0..5 { for q in p + 1..5 {
        let mut det = pw[p][0] * pw[q][1] - pw[p][1] * pw[q][0];
        if det == 0 { continue; }
        let (mut n1, mut n2) = (qw[p] * pw[q][1] - pw[p][1] * qw[q], pw[p][0] * qw[q] - qw[p] * pw[q][0]);
        if det < 0 { det = -det; n1 = -n1; n2 = -n2; }
        if (0..5).all(|w| pw[w][0] * n1 + pw[w][1] * n2 <= qw[w] * det) && !corners.iter().any(|&(a1, a2, d)| a1 * det == n1 * d && a2 * det == n2 * d) { corners.push((n1, n2, det)); }
    } }
    corners.sort_by(|u, v| (u.0 * v.2).cmp(&(v.0 * u.2)).then((u.1 * v.2).cmp(&(v.1 * u.2))));
    let profit = |u: &(i64, i64, i64)| (19 * u.0 + 20 * u.1, u.2);
    println!("corners: {}", corners.iter().map(|u| format!("({}, {}) {}", frac(u.0, u.2), frac(u.1, u.2), frac(profit(u).0, u.2))).collect::<Vec<_>>().join("; "));
    let yc = [3i64, 0, 7];
    let cover: Vec<i64> = (0..2).map(|j| (0..3).map(|i| pw[i][j] * yc[i]).sum()).collect();
    let dual: i64 = (0..3).map(|i| qw[i] * yc[i]).sum();
    println!("certificate y = (3, 0, 7): covers tables {} >= 19, chairs {} >= 20; bound {}", cover[0], cover[1], dual);
    let mut h2: Hist = Vec::new(); ipm(&a, &c, &x0, &y0, 0.1, None, 2, &mut h2);
    for j in [1, 2] { let xj = &h2[j].1; println!("break, full steps, after {}: plan ({}, {}), timber left {}, profit {}", j, f4(xj[0]), f4(xj[1]), f4(xj[2]), f4(dot(&c, xj))); }
    let mut hc: Hist = Vec::new(); ipm(&a, &c, &x0, &y0, 1.0, Some(0.9), 20, &mut hc);
    println!("break, sigma = 1 (centre only): gap after 20 iterations {}", f4(hc[hc.len() - 1].3));
    let (kt, xt, _) = ipm(&a, &[19.0, 38.0, 0.0, 0.0, 0.0], &x0, &[5.0, 10.0, 10.0], 0.1, Some(0.9), 200, &mut Vec::new());
    println!("break, chairs at 38 pounds (tied best edge): stops after {} at ({}, {}), profit {}", kt, f4(xt[0]), f4(xt[1]), f4(19.0 * xt[0] + 38.0 * xt[1]));
    let prox = |x: &[f64], y: &[f64]| -> f64 {
        let s = newton(&a, &c, x, y, 1.0).0; let mu = dot(x, &s) / 5.0;
        let mut t = 0.0; for j in 0..5 { let v = x[j] * s[j] / mu - 1.0; t += v * v; } t.sqrt() };
    let (mut xs, mut ys, mut nc) = (x0.clone(), y0.clone(), 0); // short step: centre, then sigma = 1 - 0.4/sqrt(n)
    while prox(&xs, &ys) > 0.4 { let r = ipm(&a, &c, &xs, &ys, 1.0, Some(0.9), 1, &mut Vec::new()); xs = r.1; ys = r.2; nc += 1; }
    let sig = 1.0 - 0.4 / 5f64.sqrt();
    let g0 = dot(&xs, &newton(&a, &c, &xs, &ys, 1.0).0);
    let mut hs: Hist = Vec::new();
    let (ks, _, _) = ipm(&a, &c, &xs, &ys, sig, None, 500, &mut hs);
    let worst = hs.iter().map(|e| prox(&e.1, &e.2)).fold(f64::MIN, f64::max);
    let pred = ((g0 / (1e-8 * 929.0)).ln() / -sig.ln()).ceil() as usize;
    let bound = 5f64.sqrt() / 0.4 * (g0 / (1e-8 * 929.0)).ln();
    println!("short step: {} centring steps, gap {}; sigma {}; {} iterations (predicted {}, bound {}); worst proximity {}", nc, f4(g0), f4(sig), ks, pred, f4(bound), f4(worst));
    println!(" d  pivots          2^d - 1  iterations  x_d");
    let mut rows = Vec::new();
    for n in [2usize, 4, 6, 8, 10, 20, 40] {
        let sp = if n <= 10 { Some(km_simplex(n)) } else { None };
        let (kn, xk) = km_ipm(n);
        let ps = match sp { Some((p, _)) => p.to_string(), None => "-".to_string() };
        println!("{:2} {:>7} {:>16} {:>11}  {:.6}", n, ps, (1u64 << n) - 1, kn, xk[n - 1]); rows.push((n, sp, kn, xk[n - 1]));
    }
    println!("figure, px = 50 + 5*x1, py = 225 - 5*x2: path k = 0..7 {}", h[..8].iter().map(|e| format!("({:.1},{:.1})", 50.0 + 5.0 * e.1[0], 225.0 - 5.0 * e.1[1])).collect::<Vec<_>>().join(" "));
    let best = corners.iter().map(|u| profit(u).0 / u.2).max().unwrap();
    assert!(best == 928 && corners.iter().any(|u| u.0 == 32 * u.2 && u.1 == 16 * u.2 && profit(u).0 == 928 * u.2)); // enumeration
    assert!(cover[0] >= 19 && cover[1] >= 20 && dual == best);                  // dual bound meets it
    assert!((x[0] - 32.0).abs() < 1e-6 && (x[1] - 16.0).abs() < 1e-6 && k == 13); // interior point meets both
    assert!((0..3).all(|i| (y[i] - yc[i] as f64).abs() < 1e-6));
    assert!((h[1].3 - 1330.0 * (1.0 - 0.9 * amax * 0.9)).abs() < 1e-9);       // gap falls by 1 - alpha(1 - sigma)
    assert!(h2[2].1[2] < 0.0 && dot(&c, &h2[2].1) > best as f64);              // full steps leave the region
    assert!((hc[hc.len() - 1].3 - 1330.0).abs() < 1e-6 && ks == pred && worst <= 0.4);
    assert!((19.0 * xt[0] + 38.0 * xt[1] - 1216.0).abs() < 1e-5 && 1.0 < xt[0] && xt[0] < 31.0); // tie: inside the edge
    assert!(rows.iter().all(|r| match r.1 { None => true, Some((p, v)) => p == (1usize << r.0) - 1 && v == 100i128.pow(r.0 as u32 - 1) }));
    assert!(rows.iter().all(|r| (r.3 - 1.0).abs() < 1e-6 && r.2 <= 20));
    println!("ALL CHECKS PASS");
}
