// The regularity lemma -- the same check as the Python, in Rust.  No crates.  A pair of
// parts is one bitmask per vertex of A: bit j is set when it links to b(j+1).  Road one
// tries every sub-pair X, Y; road two fixes Y and sorts A by links into Y, since the
// densest X of each size takes the top of that list and the sparsest the bottom.
fn key(seed: &mut u64) -> u64 {          // a 64-bit linear congruential generator
    *seed = seed.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407); *seed }
fn rand(n: usize, seed: &mut u64) -> Vec<u32> { // exactly half the pairs: the smallest keys
    let keys: Vec<u64> = (0..n * n).map(|_| key(seed)).collect();
    let mut idx: Vec<usize> = (0..n * n).collect();
    idx.sort_by_key(|&i| keys[i]);
    let mut nb = vec![0u32; n];
    for &i in &idx[..n * n / 2] { nb[i / n] |= 1 << (i % n) }
    nb }
fn blocks(n: usize) -> Vec<u32> { (0..n).map(|a| ((1u32 << (n / 2)) - 1) << (if a >= n / 2 { n / 2 } else { 0 })).collect() }
fn dens(nb: &[u32]) -> f64 { nb.iter().map(|v| v.count_ones()).sum::<u32>() as f64 / (nb.len() * nb.len()) as f64 }
fn sets(n: usize, m: u32) -> Vec<u32> { (1..1u32 << n).filter(|y| y.count_ones() >= m).collect() }
fn brute(nb: &[u32], n: usize, m: u32) -> f64 { // road one: every X and every Y with at least m vertices
    let mut worst = 0.0f64;
    for &x in &sets(n, m) { for &y in &sets(n, m) {
        let e: u32 = (0..n).filter(|a| x >> a & 1 == 1).map(|a| (nb[a] & y).count_ones()).sum();
        worst = worst.max((e as f64 / x.count_ones() as f64 / y.count_ones() as f64 - dens(nb)).abs());
    } }
    worst }
fn greedy(nb: &[u32], n: usize, m: u32) -> f64 { // road two: for each Y, only the top and bottom s of A
    let (d, mut worst) = (dens(nb), 0.0f64);
    for &y in &sets(n, m) {
        let mut deg: Vec<u32> = nb.iter().map(|v| (v & y).count_ones()).collect();
        deg.sort();
        let t = y.count_ones() as f64;
        for s in m as usize..=n {
            let (hi, lo): (u32, u32) = (deg[n - s..].iter().sum(), deg[..s].iter().sum());
            worst = worst.max(hi as f64 / s as f64 / t - d).max(d - lo as f64 / s as f64 / t);
        } }
    worst }
fn eps_star(nb: &[u32], n: usize) -> f64 {   // smallest eps the pair passes, with sides >= eps x n
    (1..=n).map(|m| (m, greedy(nb, n, m as u32))).filter(|&(m, g)| g <= m as f64 / n as f64)
        .map(|(m, g)| g.max((m - 1) as f64 / n as f64)).fold(f64::INFINITY, f64::min) }
fn energy(parts: &[Vec<Vec<usize>>; 2], nb: &[u32], n: f64) -> f64 { // sum of |P||Q| d(P,Q)^2 / n^2
    let mut s = 0.0;
    for p in &parts[0] { for q in &parts[1] {
        let e: u32 = p.iter().map(|&a| q.iter().map(|&b| nb[a] >> b & 1).sum::<u32>()).sum();
        let size = (p.len() * q.len()) as f64;
        s += size * (e as f64 / size).powi(2); } }
    s / n / n }
fn triangles(xy: &[u32], yz: &[u32], xz: &[u32], n: usize) -> u32 { // x-y linked, then count z linked to both
    (0..n).map(|x| (0..n).filter(|&y| xy[x] >> y & 1 == 1).map(|y| (yz[y] & xz[x]).count_ones()).sum::<u32>()).sum() }
fn main() {
    let mut seed: u64 = 2026;
    let (b4, r16) = (blocks(4), rand(16, &mut seed));
    let (br2, gr2, gr1, gr3, es) = (brute(&b4, 4, 2), greedy(&b4, 4, 2), greedy(&b4, 4, 1), greedy(&b4, 4, 3), eps_star(&b4, 4));
    let (b16g, r16g, r16g1) = (greedy(&blocks(16), 16, 8), greedy(&r16, 16, 8), greedy(&r16, 16, 1));
    let whole = [vec![vec![0, 1, 2, 3]], vec![vec![0, 1, 2, 3]]];
    let halves = [vec![vec![0, 1], vec![2, 3]], vec![vec![0, 1], vec![2, 3]]];
    let (e1, e2) = (energy(&whole, &b4, 8.0), energy(&halves, &b4, 8.0));
    let sq: f64 = halves[0].iter().map(|p| halves[1].iter().map(|q| 4.0 * ((p.iter().map(|&a|
        q.iter().map(|&b| b4[a] >> b & 1).sum::<u32>()).sum::<u32>() as f64) / 4.0 - 0.5).powi(2)).sum::<f64>()).sum::<f64>() / 64.0;
    let promised = 0.5f64.powi(4) * 16.0 / 64.0;
    let same = blocks(16); let opp: Vec<u32> = same.iter().map(|v| 0xFFFF - v).collect();
    let (rx, ry, rz) = (rand(16, &mut seed), rand(16, &mut seed), rand(16, &mut seed));
    let (t_rand, t_block) = (triangles(&rx, &ry, &rz, 16), triangles(&same, &same, &opp, 16));
    let h = [b4[0] & 3, b4[1] & 3];
    println!("pair A-B, 4 + 4 vertices: {:.0} of 16 links, density {:.3}", dens(&b4) * 16.0, dens(&b4));
    println!("halves a1,a2 and b1,b2: {} of 4 links, density {:.3}, gap {:.3}", (b4[0] & 3).count_ones() * 2, dens(&h), dens(&h) - 0.5);
    println!("worst gap, sides >= 2: {:.3} over all 121 such sub-pairs, {:.3} by sorting", br2, gr2);
    println!("worst gap, sides >= 1: {:.3}; sides >= 3: {:.3}", gr1, gr3);
    println!("smallest eps that makes the pair eps-regular: {:.3}", es);
    println!("16 + 16, worst gap on sides >= 8: blocks {:.3}, random {:.3}", b16g, r16g);
    println!("energy: parts A, B {:.4}; halves {:.4}; gain {:.4}", e1, e2, e2 - e1);
    println!("gain from squared gaps {:.4}; promised at least (1/2)^4 x 16/64 = {:.4}", sq, promised);
    println!("three parts of 16, density 0.5 each: product rule 0.5^3 x 16^3 = {:.0} triangles", 0.5f64.powi(3) * 4096.0);
    println!("random links: {} triangles; blocks, X-Z opposite halves: {}", t_rand, t_block);
    println!("mistake 1, whole-pair density only: blocks {:.3}, random {:.3}", dens(&blocks(16)), dens(&r16));
    println!("mistake 2, single vertices allowed: random pair's worst gap {:.3}", r16g1);
    assert!(br2 == 0.5 && gr2 == 0.5 && gr1 == 0.5 && (gr3 - 1.0 / 18.0).abs() < 1e-12); // two roads agree
    assert!((brute(&b4, 4, 3) - 1.0 / 18.0).abs() < 1e-12 && (1..=5).all(|m| { let c: Vec<u32> = r16[..5].iter().map(|v| v & 31).collect(); (brute(&c, 5, m) - greedy(&c, 5, m)).abs() < 1e-12 }));
    assert!(es == 0.5 && b16g == 0.5 && r16g < 0.4);                    // blocks fail, random does better
    assert!(((e2 - e1) - sq).abs() < 1e-12 && e2 - e1 >= promised);     // energy rises by the squared gaps
    assert!(t_block == 0 && (t_rand as i64 - 512).abs() < 128);         // density alone does not count triangles
    println!("ALL CHECKS PASS");
}
