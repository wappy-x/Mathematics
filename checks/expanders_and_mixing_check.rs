// Expanders: a 10-station pilot (every cut checked) and two synthetic 1,200-station networks with 3 links
// per station: a random one (SplitMix64, seed 2026) and a ladder (two loops of 600 joined by rungs).
type Adj = Vec<Vec<usize>>;
struct SplitMix64 { x: u64 }
impl SplitMix64 {
    fn next(&mut self) -> u64 {
        self.x = self.x.wrapping_add(0x9E3779B97F4A7C15);
        let z = (self.x ^ (self.x >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB); z ^ (z >> 31)
    }
    fn below(&mut self, k: usize) -> usize { (self.next() % k as u64) as usize }
}
fn sm(seed: u64) -> SplitMix64 { SplitMix64 { x: seed } }
fn tot<I: Iterator<Item = f64>>(xs: I) -> f64 { xs.fold(0.0, |a, b| a + b) }
fn ball(adj: &Adj, start: usize, k: usize) -> Vec<usize> {
    let (mut seen, mut order, mut i) = (vec![false; adj.len()], vec![start], 0);
    seen[start] = true;
    while i < order.len() && order.len() < k {
        for &w in &adj[order[i]] { if !seen[w] && order.len() < k { seen[w] = true; order.push(w); } }
        i += 1;
    }
    order
}
fn random_cubic(n: usize, rng: &mut SplitMix64) -> Adj {
    loop {
        let mut ends: Vec<usize> = (0..3 * n).map(|k| k / 3).collect();
        for i in (1..ends.len()).rev() { let j = rng.below(i + 1); ends.swap(i, j); }
        let (mut adj, mut ok): (Adj, bool) = (vec![vec![]; n], true);
        for k in (0..3 * n).step_by(2) {
            let (a, b) = (ends[k], ends[k + 1]);
            if a == b || adj[a].contains(&b) { ok = false; break; }
            adj[a].push(b); adj[b].push(a);
        }
        if ok && ball(&adj, 0, n).len() == n { return adj; }
    }
}
fn ladder(n: usize) -> Adj {
    let m = n / 2;
    (0..n).map(|v| { let (r, i) = (v / m, v % m); vec![(i + 1) % m + r * m, (i + m - 1) % m + r * m, i + (1 - r) * m] }).collect()
}
fn boundary(adj: &Adj, ins: &[bool]) -> usize {
    (0..adj.len()).filter(|&v| ins[v]).map(|v| adj[v].iter().filter(|&&w| !ins[w]).count()).sum()
}
fn rayleigh(adj: &Adj, f: &[f64]) -> f64 {
    let num = tot((0..adj.len()).flat_map(|i| adj[i].iter().filter(move |&&j| i < j).map(move |&j| (f[i] - f[j]) * (f[i] - f[j]))));
    num / tot(f.iter().map(|x| x * x))
}
fn lam2(adj: &Adj, iters: usize) -> (f64, Vec<f64>) {
    let (n, mut rng) = (adj.len(), sm(7));
    let mut f: Vec<f64> = (0..n).map(|_| (rng.next() >> 11) as f64 / 9007199254740992.0 - 0.5).collect();
    for it in 0..=iters {
        let mean = tot(f.iter().cloned()) / n as f64; f = f.iter().map(|x| x - mean).collect();
        if it == iters { return (rayleigh(adj, &f), f); }
        let g: Vec<f64> = (0..n).map(|i| 3.0 * f[i] + f[adj[i][0]] + f[adj[i][1]] + f[adj[i][2]]).collect();
        let s = tot(g.iter().map(|x| x * x)).sqrt(); f = g.iter().map(|x| x / s).collect();
    }
    unreachable!()
}
fn sweep(adj: &Adj, f: &[f64]) -> (i64, i64) {
    let (n, mut order): (usize, Vec<usize>) = (adj.len(), (0..adj.len()).collect());
    order.sort_by(|&a, &b| f[a].partial_cmp(&f[b]).unwrap());
    let (mut ins, mut cut, mut best) = (vec![false; n], 0i64, (9i64, 1i64));
    for (k, &v) in order[..n / 2].iter().enumerate() {
        ins[v] = true; cut += adj[v].iter().map(|&w| if ins[w] { -1 } else { 1 }).sum::<i64>();
        if cut * best.1 < best.0 * (k as i64 + 1) { best = (cut, k as i64 + 1); }
    }
    best
}
fn tv_trace(adj: &Adj, steps: usize, lazy: bool, start: usize, stop: f64) -> Vec<f64> {
    let (n, mut out) = (adj.len(), vec![]);
    let mut p: Vec<f64> = (0..n).map(|i| if i == start { 1.0 } else { 0.0 }).collect();
    while out.len() <= steps && out.last().map_or(true, |&d: &f64| d > stop) {   // ends early once the distance is down to stop
        out.push(0.5 * tot(p.iter().map(|x| (x - 1.0 / n as f64).abs())));
        let nb: Vec<f64> = (0..n).map(|i| p[adj[i][0]] + p[adj[i][1]] + p[adj[i][2]]).collect();
        p = if lazy { (0..n).map(|i| 0.5 * p[i] + nb[i] / 6.0).collect() } else { nb.iter().map(|x| x / 3.0).collect() };
    }
    out
}
fn walk_share(adj: &Adj, ins: &[bool], steps: usize, rng: &mut SplitMix64) -> f64 {
    let (mut v, mut hits) = (rng.below(adj.len()), 0);
    for _ in 0..steps {
        if rng.below(2) == 1 { v = adj[v][rng.below(3)]; } if ins[v] { hits += 1; }
    }
    hits as f64 / steps as f64
}
fn spread(xs: &[f64]) -> (f64, f64) {
    let m = tot(xs.iter().cloned()) / xs.len() as f64;
    (m, (tot(xs.iter().map(|x| (x - m) * (x - m))) / (xs.len() - 1) as f64).sqrt())
}
fn main() {
    // ---- the pilot: outer ring of 5, inner star of 5, 5 spokes (the Petersen network) ----
    let mut p: Adj = (0..5).map(|i| vec![(i + 1) % 5, (i + 4) % 5, i + 5]).collect();
    for i in 0..5 { p.push(vec![5 + (i + 2) % 5, 5 + (i + 3) % 5, i]); }
    let (mut best, mut nbest, mut cuts) = (9.0f64, 0, 0);
    for mask in 1u32..(1 << 10) {
        let s: Vec<bool> = (0..10).map(|v| (mask >> v) & 1 == 1).collect();
        let k = s.iter().filter(|&&b| b).count();
        if k > 5 { continue; }
        cuts += 1; let r = boundary(&p, &s) as f64 / k as f64;
        if r < best - 1e-12 { best = r; nbest = 0; }
        if (r - best).abs() < 1e-12 { nbest += 1; }
    }
    let a2 = |i: usize, j: usize| (0..10).filter(|&k| p[k].contains(&i) && p[k].contains(&j)).count() as i64;
    let identity = (0..10).all(|i| (0..10).all(|j| a2(i, j) + p[i].contains(&j) as i64 - 2 * (i == j) as i64 == 1));
    let lp = lam2(&p, 200).0;
    let tf = |b: bool| if b { "True" } else { "False" };
    println!("pilot: sets of 1-5 stations checked {}; edge expansion h {:.6}, reached by {} sets", cuts, best, nbest);
    println!("pilot: A^2 + A - 2I = J at every entry: {}; gap by power iteration {:.6}", tf(identity), lp);
    println!("pilot: lam2/2 {:.6} <= h {:.6} <= sqrt(2 d lam2) {:.6}; mixes within {} steps", lp / 2.0, best, (6.0 * lp).sqrt(), (6.0 / lp * (2.0 * 10f64.sqrt()).ln()).ceil());
    // ---- 1,200 stations, 1,800 links: random against ladder ----
    let (mut rng, pi) = (sm(2026), std::f64::consts::PI);
    let e120 = random_cubic(120, &mut rng);
    let (e, l) = (random_cubic(1200, &mut rng), ladder(1200));
    let lad = |n: usize| 2.0 - 2.0 * (2.0 * pi / (n / 2) as f64).cos();
    let ((le, fe), le_half, l120) = (lam2(&e, 3000), lam2(&e, 1500).0, lam2(&e120, 3000).0);
    let fl: Vec<f64> = (0..1200).map(|i| (2.0 * pi * (i % 600) as f64 / 600.0).cos()).collect();
    let (ll, ll_rq, ll120) = (lad(1200), rayleigh(&l, &fl), lam2(&ladder(120), 3000).0);
    let (c1, c2) = (sweep(&e, &fe), sweep(&e, &fe.iter().map(|x| -x).collect::<Vec<f64>>()));   // sweep from both ends
    let (cut, size) = if c1.0 * c2.1 <= c2.0 * c1.1 { c1 } else { c2 }; let cs = cut as f64 / size as f64;
    println!("gap, random  n=120, 1200:   {:.6} {:.6}   (1500 iterations: {:.6})", l120, le, le_half);
    println!("gap, ladder  n=120, 1200:   {:.6} {:.6}   (closed form; power iteration n=120: {:.6}; Rayleigh check: {:.6})", lad(120), ll, ll120, ll_rq);
    println!("large-network limit 3 - 2 sqrt 2:             {:.6}", 3.0 - 2.0 * 2f64.sqrt());
    println!("random: h >= lam2/2 = {:.4}; sweep cut {} links / {} stations = {:.4}; h <= {:.4}", le / 2.0, cut, size, cs, (6.0 * le).sqrt());
    println!("ladder: h >= lam2/2 = {:.7}; half cut 4 links / 600 stations = {:.4}; h <= {:.4}", ll / 2.0, 4.0 / 600.0, (6.0 * ll).sqrt());
    let lnn = (2.0 * 1200f64.sqrt()).ln();
    let (tb_e, tb_l) = ((6.0 / le * lnn).ceil() as usize, (6.0 / ll * lnn).ceil() as usize);
    println!("guaranteed mixing, (2d/lam2) ln(2 sqrt n): random {} steps, ladder {} steps", tb_e, tb_l);
    let (te, tl) = (tv_trace(&e, 150, true, 0, -1.0), tv_trace(&l, 1000, true, 0, -1.0));
    let bound = |lam: f64, t: usize| 0.5 * (1.0 - lam / 6.0).powf(t as f64) * 1199f64.sqrt();
    let tmix = te.iter().position(|&d| d <= 0.25).unwrap();
    let tmix_w = (0..1200).map(|s| tv_trace(&e, 400, true, s, 0.25).len() - 1).max().unwrap();   // every start; t_mix is the worst
    println!("step   distance: random  ladder   random's guarantee");
    for t in (0..151).step_by(15) { println!("{:4}            {:.4}  {:.4}   {:.4}", t, te[t], tl[t], bound(le, t).min(1.0)); }
    println!("random: first step with distance <= 1/4: {} from station 0, {} from the worst start;  ladder at step 1000: {:.4}", tmix, tmix_w, tl[1000]);
    // ---- sampling: share of stations in a 240-station district around station 0 (truth 0.2) ----
    let (mut res, mut dist): (Vec<Vec<f64>>, Vec<Vec<bool>>) = (vec![], vec![]);
    for (name, g, lam) in [("random", &e, le), ("ladder", &l, ll)] {
        let mut ins = vec![false; 1200];
        for v in ball(g, 0, 240) { ins[v] = true; }
        let b = boundary(g, &ins);
        res.push((0..200).map(|s| walk_share(g, &ins, 1000, &mut sm(s + 1))).collect()); dist.push(ins);
        println!("district on {}: {} links out (at least {:.2}); a lazy step leaves with chance {:.4}", name, b, lam * 240.0 * 960.0 / 1200.0, b as f64 / 1440.0);
    }
    let indep: Vec<f64> = (0..200).map(|s| { let mut r = sm(10_000 + s); (0..1000).filter(|_| r.below(1200) < 240).count() as f64 / 1000.0 }).collect();
    let ((m_i, s_i), (m_e, s_e), (m_l, s_l)) = (spread(&indep), spread(&res[0]), spread(&res[1]));
    for (name, m, sd) in [("independent picks", m_i, s_i), ("walk, random", m_e, s_e), ("walk, ladder", m_l, s_l)] { println!("200 runs x 1000 picks, {:<17} mean {:.4}  spread {:.4}", name, m, sd); }
    let (s_th, ls) = ((0.16f64 / 1000.0).sqrt(), 1.0 - le / 6.0);
    let s_g = s_th * ((1.0 + ls) / (1.0 - ls)).sqrt();
    println!("theory: independent spread sqrt(0.2 x 0.8 / 1000) = {:.4}; walk guarantee x {:.2} = {:.4}", s_th, s_g / s_th, s_g);
    println!("random bits per run: independent {:.0}, walk {:.0}", 1000.0 * 1200f64.log2(), 1200f64.log2() + 1000.0 * (1.0 + 3f64.log2()));
    let short: Vec<f64> = (0..200).map(|s| walk_share(&e, &dist[0], 250, &mut sm(500 + s))).collect();
    println!("try: walk of 250 steps on random network, spread {:.4}", spread(&short).1);
    // ---- what breaks: the cube (8 stations, 3 links, two colours) walked without waiting ----
    let q: Adj = (0..8).map(|i: usize| vec![i ^ 1, i ^ 2, i ^ 4]).collect();
    let (qn, ql) = (tv_trace(&q, 61, false, 0, -1.0), tv_trace(&q, 61, true, 0, -1.0));
    println!("cube: gap {:.6}; plain walk distance at 60, 61: {:.4} {:.4}; lazy: {:.4}", lam2(&q, 200).0, qn[60], qn[61], ql[60]);
    let mut pts = vec![];
    for rad in [95.0f64, 45.0] { for k in 0..5 { let a = (-90.0 + 72.0 * k as f64).to_radians(); pts.push(format!("{:.1},{:.1}", 180.0 + rad * a.cos(), 125.0 + rad * a.sin())); } }
    println!("figure, {}", pts.join(" "));
    assert!((best - 1.0).abs() < 1e-12 && nbest == 12, "pilot: every set checked, cheapest is 5 links for 5 stations");
    assert!(identity && (lp - 2.0).abs() < 1e-9, "pilot: power iteration lands on the gap the identity forces");
    assert!((ll - ll_rq).abs() < 1e-12 && (ll120 - lad(120)).abs() < 1e-9, "ladder: closed form vs its cosine pattern, and vs power iteration at 120");
    assert!(le / 2.0 <= cs && cs <= (6.0 * le).sqrt() && (le - le_half).abs() < 1e-6, "random: sweep cut inside Cheeger");
    assert!((0..151).all(|t| te[t] <= bound(le, t)) && (0..1001).all(|t| tl[t] <= bound(ll, t)), "gap bound");
    assert!(tmix <= tmix_w && tmix_w <= tb_e && tl[1000] > 0.5, "random mixes inside its guarantee from every start; ladder is still far off");
    assert!((s_i / s_th - 1.0).abs() < 0.2 && (m_e - 0.2).abs() < 4.0 * s_e / 200f64.sqrt() && s_e <= s_g, "samplers");
    assert!(s_l > 5.0 * s_e, "ladder walk's estimate swings far more than the random network's");
    assert!((qn[60] - 0.5).abs() < 1e-12 && (qn[61] - 0.5).abs() < 1e-12 && ql[60] < 1e-6, "two-colour trap");
    println!("ALL CHECKS PASS");
}
