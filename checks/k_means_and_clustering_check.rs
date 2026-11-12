// k-means -- the same check as the Python, in Rust.  No crates.
// A shop's 20,000 past orders, each described by 12 numbers on a common scale.
// SYNTHETIC: four customer groups, each a centre plus a bell-shaped wobble of
// spread 0.7 in every number, drawn from SplitMix64 with seed 2026.
// Roads: (1) every split of a six-order example, by brute force, against k-means;
// (2) the shift identity behind the update step; (3) the run's objective against
// the generating rule's expected value; (4) the found groups against the true ones.
type Pt = Vec<f64>;
struct Rng(u64);
impl Rng {
    fn rnd(&mut self) -> f64 { // SplitMix64, a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
    fn gauss(&mut self) -> f64 { // Box-Muller: one bell-shaped number from two uniforms
        let (u1, u2) = (1.0 - self.rnd(), self.rnd());
        (-2.0 * u1.ln()).sqrt() * (2.0 * std::f64::consts::PI * u2).cos()
    }
}
fn dist(a: &[f64], b: &[f64]) -> f64 { a.iter().zip(b).map(|(x, y)| (x - y) * (x - y)).sum::<f64>().sqrt() }
fn sq(a: &[f64], b: &[f64]) -> f64 { let d = dist(a, b); d * d }
fn assign(x: &[Pt], c: &[Pt]) -> (Vec<usize>, f64) {
    let (mut lab, mut j) = (Vec::new(), 0.0);
    for p in x {
        let (mut best, mut bd) = (0, sq(p, &c[0]));
        for i in 1..c.len() { let d = sq(p, &c[i]); if d < bd { best = i; bd = d; } }
        lab.push(best); j += bd;
    }
    (lab, j)
}
fn update(x: &[Pt], lab: &[usize], c: &[Pt]) -> Vec<Pt> {
    let mut s = vec![vec![0.0; x[0].len()]; c.len()];
    let mut n = vec![0usize; c.len()];
    for (p, &l) in x.iter().zip(lab) { n[l] += 1; for i in 0..p.len() { s[l][i] += p[i]; } }
    (0..c.len()).map(|j| if n[j] > 0 { s[j].iter().map(|v| v / n[j] as f64).collect() } else { c[j].clone() }).collect()
}
fn cost(x: &[Pt], lab: &[usize], c: &[Pt]) -> f64 { let mut j = 0.0; for (p, &l) in x.iter().zip(lab) { j += sq(p, &c[l]); } j }
struct Run { lab: Vec<usize>, c: Vec<Pt>, j: f64, trace: Vec<(f64, f64)> }
fn kmeans(x: &[Pt], mut c: Vec<Pt>) -> Run { // assign, update, repeat until no label moves
    let mut lab: Vec<usize> = Vec::new();
    let mut trace = Vec::new();
    loop {
        let (new, j1) = assign(x, &c);
        if new == lab { return Run { lab, c, j: j1, trace }; }
        lab = new;
        c = update(x, &lab, &c);
        trace.push((j1, cost(x, &lab, &c)));
    }
}
fn plusplus(x: &[Pt], k: usize, g: &mut Rng) -> Vec<Pt> { // k-means++: each new seed far from the old ones
    let mut c = vec![x[(g.rnd() * x.len() as f64) as usize].clone()];
    let mut d: Vec<f64> = x.iter().map(|p| sq(p, &c[0])).collect();
    while c.len() < k {
        let mut tot = 0.0;
        for v in &d { tot += v; }
        let (mut r, mut i) = (g.rnd() * tot, 0);
        while r >= d[i] && i < x.len() - 1 { r -= d[i]; i += 1; }
        c.push(x[i].clone());
        for t in 0..x.len() { d[t] = d[t].min(sq(&x[t], &x[i])); }
    }
    c
}
fn kind(lab: &[usize], truth: &[usize], k: usize) -> usize { // orders sharing a group with the majority of their kind
    (0..k).map(|j| (0..4).map(|g| lab.iter().zip(truth).filter(|(&l, &t)| l == j && t == g).count()).max().unwrap()).sum()
}
fn silhouette(dm: &[Vec<f64>], l: &[usize], k: usize) -> f64 { // mean over the orders of (b - a) / max(a, b); dm: their distances
    let mut tot = 0.0;
    for i in 0..l.len() {
        let (mut sums, mut cnt) = (vec![0.0; k], vec![0usize; k]);
        for jx in 0..l.len() { sums[l[jx]] += dm[i][jx]; cnt[l[jx]] += 1; }
        if cnt[l[i]] > 1 {
            let a = sums[l[i]] / (cnt[l[i]] - 1) as f64;
            let b = (0..k).filter(|&cc| cc != l[i] && cnt[cc] > 0).map(|cc| sums[cc] / cnt[cc] as f64).fold(f64::INFINITY, f64::min);
            tot += (b - a) / a.max(b);
        }
    }
    tot / l.len() as f64
}
fn first_by(runs: &[Run], better: fn(f64, f64) -> bool) -> &Run { let mut b = &runs[0]; for r in runs { if better(r.j, b.j) { b = r; } } b }

fn main() {
    // road 1: six orders, two numbers each (basket value, discount share), k = 2, by hand
    let p: Vec<Pt> = [(0., 4.), (1., 3.), (0., 2.), (3., 0.), (4., 1.), (5., 0.)].iter().map(|&(a, b)| vec![a, b]).collect();
    let r6 = kmeans(&p, vec![p[0].clone(), p[1].clone()]);
    let t: Vec<String> = r6.trace.iter().map(|(a, b)| format!("{:.4} -> {:.4}", a, b)).collect();
    println!("six orders, J after each assign -> update: {}", t.join(", "));
    let cs: Vec<String> = r6.c.iter().map(|c| format!("({:.4}, {:.4})", c[0], c[1])).collect();
    println!("six orders: stable after {} passes; centres {}; J = {:.4}", r6.trace.len(), cs.join(" and "), r6.j);
    let (mut best, mut bs) = (f64::INFINITY, vec![]);
    for m in (2..64).step_by(2) { // every split with A in group 0: 31
        let s: Vec<usize> = (0..6).map(|i| (m >> i) & 1).collect();
        let j = cost(&p, &s, &update(&p, &s, &[p[0].clone(), p[0].clone()]));
        if j < best { best = j; bs = s; }
    }
    let ga: Vec<String> = "ABCDEF".chars().zip(&bs).filter(|(_, &b)| b == 0).map(|(c, _)| c.to_string()).collect();
    println!("brute force over 31 splits: lowest J = {:.4}, with A in a group of {}", best, ga.join(" "));
    let g3 = &p[..3];
    let m = update(g3, &[0, 0, 0], &[p[0].clone()]).remove(0);
    let lhs = cost(g3, &[0, 0, 0], &[p[0].clone()]);
    let rhs = cost(g3, &[0, 0, 0], &[m.clone()]) + 3.0 * sq(&m, &p[0]);
    println!("shift identity on A, B, C with centre A: {:.4} = {:.4} + 3 x {:.4}", lhs, cost(g3, &[0, 0, 0], &[m.clone()]), sq(&m, &p[0]));

    // the shop: 20,000 orders, 12 numbers, 4 true groups in proportion 4 : 3 : 2 : 1
    let names = ["family weekly shop", "bargain hunter", "late-night top-up", "big-ticket buyer"];
    let true_c: [[f64; 12]; 4] = [[0.5, 1.5, 0., 1.5, 1., -0.5, 0., 1., 0., 1., -1., -0.5], [-1., 0.5, 2., 0., 0.5, -0.5, 0.5, -1., 0., 0., 0., 0.],
        [-0.5, -1., -0.5, -1., -1., 0., 0., 1., 2., 0., -0.5, 0.], [2.5, -1., -1., -1., -0.5, 2.5, 0., 1., 0., 0., 2., 1.]];
    let (n, sig) = (20000usize, 0.7);
    let mut g = Rng(2026);
    let truth: Vec<usize> = (0..n).map(|i| [0, 0, 0, 0, 1, 1, 1, 2, 2, 3][i % 10]).collect();
    let x: Vec<Pt> = truth.iter().map(|&t| (0..12).map(|d| true_c[t][d] + sig * g.gauss()).collect()).collect();
    let mut runs: Vec<Vec<Run>> = vec![vec![]];
    for k in 1..9 { let mut v = vec![]; for _ in 0..3 { let c = plusplus(&x, k, &mut g); v.push(kmeans(&x, c)); } runs.push(v); }
    let b4 = first_by(&runs[4], |a, b| a < b);
    let (lab, c, j) = (&b4.lab, &b4.c, b4.j);
    let st: Vec<String> = runs[4].iter().map(|r| format!("{:.1} ({} passes)", r.j, r.trace.len())).collect();
    println!("k = 4, three k-means++ starts stop at J = {}", st.join(", "));
    for (i, (a, b)) in b4.trace.iter().enumerate() { println!("  best start, pass {}: J {:.1} after assign -> {:.1} after update", i + 1, a, b); }
    let (expect, sd) = (n as f64 * 12.0 * sig * sig, sig * sig * (2.0 * n as f64 * 12.0).sqrt()); // n x 12 squared wobbles: mean, SD
    println!("final J = {:.1}, per order {:.4}; the generating rule expects about {:.1} = 20000 x 12 x 0.7^2, SD {:.1}", j, j / n as f64, expect, sd);
    for jj in 0..4 {
        let cnt: Vec<usize> = (0..4).map(|gg| lab.iter().zip(&truth).filter(|(&l, &t)| l == jj && t == gg).count()).collect();
        let mut gi = 0;
        for gg in 1..4 { if cnt[gg] > cnt[gi] { gi = gg; } }
        println!("  group {}: {} orders, {} of them {}; centre's basket value {:.2}, discount {:.2}",
                 jj, cnt.iter().sum::<usize>(), cnt[gi], names[gi], c[jj][0], c[jj][2]);
    }
    let right = kind(lab, &truth, 4);
    println!("orders grouped with their own kind: {} of {} = {:.4}", right, n, right as f64 / n as f64);

    // choosing k: the elbow on all orders, the silhouette on every 19th order
    let js: Vec<f64> = (0..9).map(|k| if k == 0 { 0.0 } else { first_by(&runs[k], |a, b| a < b).j }).collect();
    let s: Vec<usize> = (0..n).step_by(19).collect();
    let dm: Vec<Vec<f64>> = s.iter().map(|&a| s.iter().map(|&b| dist(&x[a], &x[b])).collect()).collect();
    let mut sil = vec![0.0; 9];
    for k in 2..9 { let bl = &first_by(&runs[k], |a, b| a < b).lab; sil[k] = silhouette(&dm, &s.iter().map(|&i| bl[i]).collect::<Vec<_>>(), k); }
    let pts = [0.0, 1.0, 3.0, 4.0_f64];
    let sil_hand = silhouette(&pts.iter().map(|a| pts.iter().map(|b| (a - b).abs()).collect()).collect::<Vec<Vec<f64>>>(), &[0, 0, 1, 1], 2);
    for k in 1..9 {
        if k == 1 { println!("k = {}: J = {:9.1}", k, js[k]); }
        else { println!("k = {}: J = {:9.1}, drop from k - 1 = {:8.1}, silhouette = {:.4}", k, js[k], js[k - 1] - js[k], sil[k]); }
    }
    let (mut best_k, mut low_k) = (2, 1);
    for k in 2..9 { if sil[k] > sil[best_k] { best_k = k; } }
    for k in 1..9 { if js[k] < js[low_k] { low_k = k; } }
    println!("silhouette sample: {} orders; it picks k = {}; lowest J picks k = {}", s.len(), best_k, low_k);

    // what breaks
    let w = first_by(&runs[4], |a, b| a > b);
    let wb: Vec<String> = w.c.iter().map(|c| format!("{:.2}", c[0])).collect();
    println!("worst k = 4 start: J = {:.1}, {:.4} times the best; with own kind {}; basket values {}", w.j, w.j / j, kind(&w.lab, &truth, 4), wb.join(", "));
    let xp: Vec<Pt> = x.iter().map(|p| { let mut q = p.clone(); q[0] = 45.0 + 30.0 * p[0]; q }).collect();
    let cp = plusplus(&xp, 4, &mut g);
    let right_p = kind(&kmeans(&xp, cp).lab, &truth, 4);
    println!("basket value left in pounds: grouped with their own kind {} of {} = {:.4}", right_p, n, right_p as f64 / n as f64);
    let fc: Vec<String> = c.iter().map(|q| format!("({:.2}, {:.2})", q[0], q[2])).collect();
    println!("figure, centres (basket value, discount): {}; {} orders drawn", fc.join("; "), (s.len() + 10) / 11);

    assert!((best - r6.j).abs() < 1e-9 && (r6.j - 16.0 / 3.0).abs() < 1e-9 && r6.trace.len() == 2);
    assert!((lhs - rhs).abs() < 1e-9 && (lhs - 6.0).abs() < 1e-9);
    let tr = &b4.trace;
    assert!(tr.iter().all(|(a, b)| *b <= a + 1e-9) && (0..tr.len() - 1).all(|i| tr[i + 1].0 <= tr[i].1 + 1e-9));
    assert!((1..8).all(|k| js[k + 1] < js[k]));
    assert!((j - expect).abs() < 3.0 * sd); // run against the generating rule, 3 SD
    assert!((sil_hand - 23.0 / 35.0).abs() < 1e-12); // orders at 0, 1 | 3, 4 by hand: (5/7 + 3/5 + 3/5 + 5/7) / 4 = 23/35
    assert!(right as f64 / n as f64 > 0.99 && best_k == 4 && w.j > 1.05 * j && (right_p as f64 / n as f64) < 0.9);
    println!("ALL CHECKS PASS");
}
