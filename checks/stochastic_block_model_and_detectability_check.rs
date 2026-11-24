// The stochastic block model: plant two groups, find them, and test the Kesten-Stigum line.
// Rust std only, no crates.  Every graph is synthetic, drawn by SplitMix64 from a stated seed.
type Edges = Vec<(usize, usize)>;
fn rng(state: u64) -> (u64, u64) {
    let s = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, z ^ (z >> 31))
}
fn sbm(n: usize, cin: f64, cout: f64, seed: u64) -> Edges {
    // one coin per pair: c_in/n inside a group, c_out/n across
    let (h, mut st, mut e) = (n / 2, seed, Vec::new());
    for i in 0..n {
        let runs = [(cin / n as f64, i + 1, i / h * h + h), (if i < h { cout / n as f64 } else { 0.0 }, h, n)];
        for &(p, lo, hi) in &runs {
            if p <= 0.0 { continue; }
            let (lq, mut j) = ((1.0 - p).ln(), lo as i64 - 1);
            loop {
                // jump straight to the next pair whose coin lands "friends"
                let (s, r) = rng(st); st = s;
                j += 1 + ((((r >> 11) + 1) as f64 / 9007199254740992.0).ln() / lq) as i64;
                if j >= hi as i64 { break; }
                e.push((i, j as usize));
            }
        }
    }
    e
}
fn dot(a: &[f64], b: &[f64]) -> f64 { let mut t = 0.0; for (u, v) in a.iter().zip(b) { t += u * v; } t }
fn norm(x: &[f64]) -> f64 { dot(x, x).sqrt() }
fn scale(x: &[f64], r: f64) -> Vec<f64> { x.iter().map(|v| v / r).collect() }
fn nb(x: &[f64], src: &[usize], dst: &[usize], n: usize) -> Vec<f64> {
    // non-backtracking step: walk on, never straight back
    let mut s = vec![0.0; n];
    for e in 0..x.len() { s[src[e]] += x[e]; }
    (0..x.len()).map(|e| s[dst[e]] - x[e ^ 1]).collect()
}
fn signs(n: usize, seed: u64) -> Vec<f64> {
    let mut st = seed; (0..n).map(|_| { let (s, r) = rng(st); st = s; if r >> 63 == 1 { 1.0 } else { -1.0 } }).collect()
}
fn overlap(n: usize, z: &[f64]) -> (f64, usize) {
    // 0 = coin toss, 1 = everyone right (either naming of the groups)
    let r = (0..n).filter(|&v| (z[v] >= 0.0) == (v < n / 2)).count(); let r = r.max(n - r);
    (2.0 * r as f64 / n as f64 - 1.0, r)
}
fn detect(n: usize, e: &Edges, seed: u64, deflate: bool) -> (f64, f64, (f64, usize)) {
    // spectral method on the non-backtracking matrix B
    let src: Vec<usize> = e.iter().flat_map(|&(a, b)| [a, b]).collect();
    let dst: Vec<usize> = e.iter().flat_map(|&(a, b)| [b, a]).collect();
    let (mut x, mut lam1) = (vec![1.0; src.len()], 0.0);
    for _ in 0..40 { let y = nb(&x, &src, &dst, n); let r = norm(&y); lam1 = r / norm(&x); x = scale(&y, r); }
    let rv = x.clone(); let lf: Vec<f64> = (0..rv.len()).map(|i| rv[i ^ 1]).collect();
    let lr = dot(&lf, &rv);
    let defl = |v: Vec<f64>| -> Vec<f64> {
        if !deflate { return v; }
        let k = dot(&lf, &v) / lr; v.iter().zip(&rv).map(|(a, b)| a - k * b).collect()
    };
    let x0 = defl(signs(src.len(), seed + 1)); let r = norm(&x0); let mut x = scale(&x0, r); let mut logs = Vec::new();
    for _ in 0..100 { let y = defl(nb(&x, &src, &dst, n)); let r = norm(&y); logs.push(r.ln()); x = scale(&y, r); }
    let mu = (dot(&logs[logs.len() - 20..], &[1.0; 20]) / 20.0).exp();
    let mut z = vec![0.0; n];
    for i in 0..x.len() { z[dst[i]] += x[i]; }
    (lam1, mu, overlap(n, &z))
}
fn neighbours(n: usize, e: &Edges) -> Vec<Vec<usize>> {
    let mut nbr = vec![Vec::new(); n];
    for &(a, b) in e { nbr[a].push(b); nbr[b].push(a); }
    nbr
}
fn adjacency_split(n: usize, e: &Edges, seed: u64) -> (usize, (f64, usize)) {
    // plain spectral: 100 power steps toward the adjacency second eigenvector
    let nbr = neighbours(n, e);
    let ax = |x: &[f64]| -> Vec<f64> { (0..n).map(|v| dot(&nbr[v].iter().map(|&w| x[w]).collect::<Vec<_>>(), &vec![1.0; nbr[v].len()])).collect() };
    let mut u = vec![1.0; n];
    for _ in 0..100 { let y = ax(&u); let r = norm(&y); u = scale(&y, r); }
    let mut x = signs(n, seed + 2);
    for _ in 0..100 {
        let y = ax(&x); let k = dot(&u, &y); let y: Vec<f64> = y.iter().zip(&u).map(|(a, b)| a - k * b).collect();
        let r = norm(&y); x = scale(&y, r);
    }
    (nbr.iter().map(|l| l.len()).max().unwrap(), overlap(n, &x))
}
fn pieces(n: usize, e: &Edges) -> (usize, usize) {
    // flood fill: number of separate pieces, size of the largest
    let nbr = neighbours(n, e); let (mut seen, mut count, mut big) = (vec![false; n], 0, 0);
    for s in 0..n {
        if seen[s] { continue; }
        count += 1; seen[s] = true; let (mut stack, mut size) = (vec![s], 0);
        while let Some(v) = stack.pop() {
            size += 1;
            for &w in &nbr[v] { if !seen[w] { seen[w] = true; stack.push(w); } }
        }
        big = big.max(size);
    }
    (count, big)
}
fn census(cin: f64, cout: f64, t: usize) -> Vec<f64> {
    // tree road: signal-to-noise of the depth-t census, exact recursion
    let (c, th) = ((cin + cout) / 2.0, (cin - cout) / (cin + cout)); let (mut m, mut m2, mut out) = (1.0, 1.0, Vec::new());
    for _ in 0..t { m2 = c * m2 + (c * th * m) * (c * th * m); m = c * th * m; out.push(m * m / (m2 - m * m)); }
    out
}
fn main() {
    let (n, seed) = (5000usize, 2026u64);
    println!("people {} in two groups of {}, seed {}", n, n / 2, seed);
    let nf = n as f64; let mut keep: Option<(Edges, f64)> = None;
    for &(ci, co) in &[(5i64, 1i64), (4, 2)] {
        let (cin, cout) = (ci as f64, co as f64);
        let snr = ((ci - co) * (ci - co)) as f64 / (2 * (ci + co)) as f64;
        println!("c_in {} c_out {}: (c_in - c_out)^2 = {}  2(c_in + c_out) = {}  lambda = {:.4}  {}", ci, co, (ci - co) * (ci - co), 2 * (ci + co), snr, if snr > 1.0 { "detectable" } else { "undetectable" });
        println!("  p_in {:.4}  p_out {:.4}  friends inside {:.4}  across {:.4}  theta {:.4}  c theta^2 {:.4}", cin / nf, cout / nf, (n / 2 - 1) as f64 * cin / nf, (n / 2) as f64 * cout / nf,
            (cin - cout) / (cin + cout), (cin + cout) / 2.0 * ((cin - cout) / (cin + cout)).powi(2));
        println!("  predicted eigenvalues of B: c {:.4}  community {:.4}  bulk edge sqrt(c) {:.4}", (cin + cout) / 2.0, (cin - cout) / 2.0, ((cin + cout) / 2.0).sqrt());
        let e = sbm(n, cin, cout, seed); let inside = e.iter().filter(|&&(a, b)| (a < n / 2) == (b < n / 2)).count();
        let (lam1, mu, (q, right)) = detect(n, &e, seed, true);
        let mut has = vec![false; n]; for &(a, b) in &e { has[a] = true; has[b] = true; }
        println!("  graph: {} friendships, {} inside, {} across, mean degree {:.4}, {} with none", e.len(), inside, e.len() - inside, 2.0 * e.len() as f64 / nf, has.iter().filter(|&&h| !h).count());
        let (ein, eout) = ((n / 2 * (n / 2 - 1)) as f64 * cin / nf, (n / 2 * (n / 2)) as f64 * cout / nf); // friendships the rates predict inside, across
        assert!((inside as f64 - ein).abs() < 4.0 * ein.sqrt() && ((e.len() - inside) as f64 - eout).abs() < 4.0 * eout.sqrt(), "friendship counts should match the rates");
        println!("  measured: top eigenvalue {:.4}  next growth {:.4}  right {} of {}  overlap {:.4}", lam1, mu, right, n, q);
        let t = census(cin, cout, 12);
        let ts: Vec<String> = [1, 2, 4, 8, 12].iter().map(|&i| format!("{:.4}", t[i - 1])).collect();
        println!("  tree census signal-to-noise, depth 1 2 4 8 12: {}  limit {:.4}", ts.join(" "), (snr - 1.0).max(0.0));
        assert!((lam1 - (cin + cout) / 2.0).abs() < 0.1, "top eigenvalue should sit near the mean degree c");
        assert!((0..12).all(|i| (t[i] - (snr - 1.0) / (1.0 - snr.powf(-(i as f64 + 1.0)))).abs() < 1e-9), "census recursion disagrees with its closed form");
        if snr > 1.0 {
            assert!((mu - (cin - cout) / 2.0).abs() < 0.1 && q > 0.2, "above the line the community eigenvalue and the groups should show");
            keep = Some((e, q));
        } else {
            assert!((mu - ((cin + cout) / 2.0).sqrt()).abs() < 0.1 && q < 0.05, "below the line only the bulk and a coin toss should show");
        }
    }
    let mut sweep = Vec::new();
    for &cin in &[3.5, 4.0, 4.5, 4.75, 5.0, 5.5, 5.75] {
        // mean degree 3 throughout; only the split between in and out moves
        let cout = 6.0 - cin; let snr = (cin - cout) * (cin - cout) / 12.0;
        let (_, mu, (q, _)) = detect(n, &sbm(n, cin, cout, seed), seed, true);
        sweep.push((snr, q)); println!("sweep c_in {:.2} c_out {:.2}: lambda {:.4}  next growth {:.4}  overlap {:.4}", cin, cout, snr, mu, q);
    }
    let below = sweep.iter().filter(|p| p.0 < 0.9).map(|p| p.1).fold(f64::MIN, f64::max);
    let above = sweep.iter().filter(|p| p.0 > 1.2).map(|p| p.1).fold(f64::MAX, f64::min);
    assert!(below < 0.07 && 0.2 < above, "a cliff near lambda = 1");
    println!("chart, lambda:overlap {}", sweep.iter().map(|(s, q)| format!("{:.2}:{:.2}", s, q)).collect::<Vec<_>>().join(" "));
    println!("what breaks, at c_in 5, c_out 1:");
    let (e51, q51) = keep.unwrap();
    let (dmax, (qa, ra)) = adjacency_split(n, &e51, seed);
    println!("  plain adjacency eigenvector, 100 steps: right {} of {}, overlap {:.4}; busiest person {} friends", ra, n, qa, dmax);
    assert!(qa < 0.1 && 0.1 < q51, "plain adjacency should fail where non-backtracking succeeds");
    let (cnt, big) = pieces(n, &e51);
    println!("  Laplacian: the network falls into {} pieces (largest {}), so {} zero eigenvalues and lambda_2 = 0", cnt, big, cnt);
    let (_, mu0, (q0, r0)) = detect(n, &e51, seed, false);
    println!("  top eigenvector left in: growth {:.4}, right {} of {}, overlap {:.4}", mu0, r0, n, q0);
    assert!(cnt > 1 && (mu0 - 3.0).abs() < 0.1 && q0 < 0.1, "these mistakes should fail");
    for &(nn, s) in &[(10000usize, seed), (n, 7u64)] {
        // the "Try changing" runs
        let (lam1, mu, (q, right)) = detect(nn, &sbm(nn, 5.0, 1.0, s), s, true);
        println!("try: c_in 5 c_out 1, {} people, seed {}: top {:.4}  next growth {:.4}  right {} of {}  overlap {:.4}", nn, s, lam1, mu, right, nn, q);
    }
    println!("ALL CHECKS PASS");
}
