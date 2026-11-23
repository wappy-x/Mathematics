// Unique games conjecture -- the check behind the card.  std only.
// A small unique game solved two ways, max-cut as the two-label case, and the
// dictator test behind "UGC makes 0.878 optimal" computed exactly.
use std::f64::consts::PI;
type Edges = Vec<(usize, usize, usize)>;

fn met(e: &Edges, k: usize, lab: &[usize]) -> usize { // rules lab[v] = lab[u] + c (mod k)
    e.iter().filter(|&&(u, v, c)| (lab[v] + 2 * k - lab[u] - c) % k == 0).count()
}
fn neq(e: &Edges, _k: usize, lab: &[usize]) -> usize {
    e.iter().filter(|&&(u, v, _)| lab[u] != lab[v]).count()
}
fn brute(n: usize, e: &Edges, k: usize, ok: fn(&Edges, usize, &[usize]) -> usize) -> (usize, usize) {
    let mut scores = vec![]; // road 1: try every labelling
    for code in 0..k.pow(n as u32) {
        let mut lab = vec![0; n];
        let mut c = code;
        for i in (0..n).rev() { lab[i] = c % k; c /= k; }
        scores.push(ok(e, k, &lab));
    }
    let best = *scores.iter().max().unwrap();
    (best, scores.iter().filter(|&&s| s == best).count())
}
fn propagate(n: usize, e: &Edges, k: usize) -> (usize, usize) {
    let (mut best, mut full) = (0, 0); // road 2: fix node 0, each rule forces the next label
    for start in 0..k {
        let mut lab = vec![0; n];
        lab[0] = start;
        for &(u, v, c) in &e[..n - 1] { lab[v] = (lab[u] + c) % k; }
        let s = met(e, k, &lab);
        best = best.max(s);
        if s == e.len() { full += 1; }
    }
    (best, full)
}
fn ring(off: &[usize]) -> Edges {
    let n = off.len();
    off.iter().enumerate().map(|(i, &c)| (i, (i + 1) % n, c)).collect()
}
fn r(t: f64) -> f64 { 2.0 * t / (PI * (1.0 - t.cos())) }

fn maj_pass(n: usize, rho: f64) -> f64 { // exact, by counting +1s: a in x, j flipped, l of the rest
    let q = (1.0 - rho) / 2.0;
    let mut c: Vec<Vec<f64>> = vec![vec![1.0]];
    for i in 0..n {
        let mut row = vec![1.0];
        for j in 0..i { row.push(c[i][j] + c[i][j + 1]); }
        row.push(1.0);
        c.push(row);
    }
    let b = |m: usize, j: usize| c[m][j] * q.powi(j as i32) * (1.0 - q).powi((m - j) as i32);
    let mut tot = 0.0;
    for a in 0..=n { for j in 0..=a { for l in 0..=(n - a) {
        if (2 * a > n) != (2 * (a - j + l) > n) {
            tot += c[n][a] / 2f64.powi(n as i32) * b(a, j) * b(n - a, l);
        }
    } } }
    tot
}
fn maj_brute(n: usize, rho: f64) -> f64 { // every x and every flip pattern, weighted
    let q = (1.0 - rho) / 2.0;
    let mut tot = 0.0;
    for xs in 0..(1usize << n) { for fs in 0..(1usize << n) {
        let (mut sx, mut sy, nf) = (0i32, 0i32, fs.count_ones() as i32);
        for i in 0..n {
            let x = if xs >> i & 1 == 1 { 1 } else { -1 };
            sx += x;
            sy += if fs >> i & 1 == 1 { -x } else { x };
        }
        if (sx > 0) != (sy > 0) {
            tot += q.powi(nf) * (1.0 - q).powi(n as i32 - nf) / 2f64.powi(n as i32);
        }
    } }
    tot
}

fn main() {
    let (good, bad) = (ring(&[1, 2, 0, 1, 2]), ring(&[1, 2, 0, 1, 1]));
    for (name, g) in [("consistent ring", &good), ("one rule changed", &bad)] {
        let (bb, bc) = brute(5, g, 3, met);
        let (pb, pf) = propagate(5, g, 3);
        let s = g.iter().map(|x| x.2).sum::<usize>() % 3;
        println!("{:17} offsets sum mod 3 = {}  best {}/5 = {:.6}  best labellings {} of {}  propagation full {}",
                 name, s, bb, bb as f64 / 5.0, bc, 3usize.pow(5), pf);
        assert!(bb == pb && (bb == 5) == (s == 0));
    }
    let mut lab = vec![0usize];
    for &(_, _, c) in &good[..4] { let l = (lab[lab.len() - 1] + c) % 3; lab.push(l); }
    println!("labels forced on the consistent ring from camera 0 at 0: {}",
             lab.iter().map(|l| l.to_string()).collect::<Vec<_>>().join(" "));
    assert!(brute(5, &bad, 3, met) == (4, 15) && propagate(5, &good, 3) == (5, 3));

    let (cut, ncut) = brute(5, &ring(&[1; 5]), 2, met);
    let sdp = 5.0 * (1.0 - (4.0 * PI / 5.0).cos()) / 2.0;
    println!("max-cut on the 5-ring: best {}/5 ({} best splits), SDP bound {:.6}, ratio {:.6}, GW expected cut {:.6}",
             cut, ncut, sdp, cut as f64 / sdp, 5.0 * (4.0 * PI / 5.0) / PI);
    let lap = |v: &[f64; 5]| -> [f64; 5] { std::array::from_fn(|i| 2.0 * v[i] - v[(i + 4) % 5] - v[(i + 1) % 5]) };
    let mut v = [1.0f64, 0.0, 0.0, 0.0, 0.0]; // road 2 for the bound: power iteration finds the top eigenvalue
    for _ in 0..200 { let w = lap(&v); let m = w.iter().fold(0.0f64, |a, x| a.max(x.abs())); v = w.map(|x| x / m); }
    let top = lap(&v).iter().zip(&v).map(|(a, b)| a * b).sum::<f64>() / v.iter().map(|x| x * x).sum::<f64>();
    println!("dual bound: top Laplacian eigenvalue {:.6}, times 5/4 = {:.6}", top, 5.0 * top / 4.0);
    assert!((cut, ncut) == (5 - 1, 2 * 5)); // odd ring: one link left uncut (5 ways), two colourings each
    assert!((sdp - 5.0 * top / 4.0).abs() < 1e-9); // primal vectors and dual prices meet, so 4.522542 is the optimum

    let (full3, cnt3) = brute(5, &ring(&[0; 5]), 3, neq);
    println!("'differ' with 3 colours on the ring: {} labellings meet all {} rules; each rule leaves 2 choices, so nothing is forced",
             cnt3, full3);
    assert!(cnt3 == 32 - 2);

    let (mut lo, mut hi) = (0.5f64, PI); // road 1: golden-section search
    for _ in 0..200 {
        let (m1, m2) = (hi - (hi - lo) / 1.618033988749895, lo + (hi - lo) / 1.618033988749895);
        if r(m1) < r(m2) { hi = m2; } else { lo = m1; }
    }
    let t_gold = (lo + hi) / 2.0;
    let (mut lo, mut hi) = (2.0f64, 3.0f64); // road 2: bisection on (1 - cos t) = t sin t
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if (1.0 - mid.cos()) - mid * mid.sin() < 0.0 { lo = mid; } else { hi = mid; }
    }
    let t_bis = (lo + hi) / 2.0;
    let grid = (1..=100000).map(|i| { let x = -(i as f64) / 100000.0; (x.acos() / PI) / ((1.0 - x) / 2.0) })
        .fold(f64::INFINITY, f64::min); // road 3: a grid over rho
    let (alpha, rho) = (r(t_bis), t_bis.cos());
    println!("theta* {:.6} rad = {:.4} deg, rho* {:.6}", t_bis, t_bis * 180.0 / PI, rho);
    println!("alpha_GW: golden {:.6}  bisection {:.6}  rho grid {:.6}", r(t_gold), alpha, grid);
    assert!((t_gold - t_bis).abs() < 1e-6 && (grid - alpha).abs() < 1e-8 && grid >= alpha - 1e-12);

    let limit = rho.acos() / PI;
    for n in [1, 3, 9, 27, 81] { println!("majority of {:2} bits passes {:.6}", n, maj_pass(n, rho)); }
    for n in [1, 3, 5] { assert!((maj_pass(n, rho) - maj_brute(n, rho)).abs() < 1e-12); }
    println!("dictator passes (1-rho)/2 = {:.6}; many-bit limit arccos(rho)/pi = {:.6}; ratio {:.6}",
             (1.0 - rho) / 2.0, limit, limit / ((1.0 - rho) / 2.0));
    assert!((maj_pass(1, rho) - (1.0 - rho) / 2.0).abs() < 1e-12);
    assert!(maj_pass(3, rho) > maj_pass(81, rho) && maj_pass(81, rho) > limit && maj_pass(81, rho) - limit < 0.01);
    println!("rho = -1: dictator {:.6}, majority of 81 {:.6}, limit {:.6}: no gap",
             maj_pass(1, -1.0), maj_pass(81, -1.0), (-1f64).acos() / PI);
    let rs: Vec<f64> = (0..11).map(|i| -1.0 + i as f64 / 10.0).collect();
    println!("chart dictator {}", rs.iter().map(|x| format!("{:.3}", (1.0 - x) / 2.0)).collect::<Vec<_>>().join(" "));
    println!("chart majority-limit {}", rs.iter().map(|x| format!("{:.3}", x.acos() / PI)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
