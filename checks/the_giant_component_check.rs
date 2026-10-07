// The giant component -- the check behind the card.  Rust std only.
// 1,000 people; each pair are friends, independently, with chance
// p = c/999, so c is the average number of friends.  Four roads to the share
// of people in the giant: bisection on z = 1 - e^(-c z), the extinction chance
// generation by generation, a simulated family tree, and simulated networks.

struct Rng { s: u64 }                       // SplitMix64 with a stated seed; Python uses the same
impl Rng {
    fn u(&mut self) -> f64 {                // a uniform number in [0, 1)
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (self.s ^ (self.s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0
    }
}

fn zeta_bisect(c: f64) -> f64 {             // road 1: the root of 1 - e^(-c z) - z above 0
    if c <= 1.0 { return 0.0; }
    let (mut lo, mut hi) = (1e-6, 1.0);     // the gap is positive at lo, negative at 1
    for _ in 0..100 {
        let mid = (lo + hi) / 2.0;
        if 1.0 - (-c * mid).exp() - mid > 0.0 { lo = mid; } else { hi = mid; }
    }
    (lo + hi) / 2.0
}

fn extinction(c: f64, gens: usize) -> Vec<f64> { // road 2: q_k = e^(c (q_(k-1) - 1)), q_0 = 0
    let mut q = 0.0;
    let mut path = Vec::new();
    for _ in 0..gens { q = (c * (q - 1.0)).exp(); path.push(q); }
    path
}

fn poisson(rng: &mut Rng, lam: f64) -> u64 { // Knuth: multiply uniforms until below e^-lam
    let (mut k, mut t, stop) = (0u64, rng.u(), (-lam).exp());
    while t > stop { k += 1; t *= rng.u(); }
    k
}

fn survives(rng: &mut Rng, c: f64) -> bool { // road 3: one family line, Poisson(c) children each
    let mut alive = 1u64;
    while alive > 0 && alive < 50 {         // at 50 alive, dying out has chance below 1e-18
        alive = poisson(rng, c * alive as f64); // a generation's children, all drawn at once
    }
    alive > 0
}

fn root(parent: &mut Vec<usize>, mut x: usize) -> usize {
    while parent[x] != x { parent[x] = parent[parent[x]]; x = parent[x]; }
    x
}

fn sizes(n: usize, edges: &[(usize, usize)]) -> Vec<usize> { // union-find: sizes, largest first
    let mut parent: Vec<usize> = (0..n).collect();
    for &(a, b) in edges {
        let (ra, rb) = (root(&mut parent, a), root(&mut parent, b));
        if ra != rb { parent[ra] = rb; }
    }
    let mut count = vec![0usize; n];
    for x in 0..n { let r = root(&mut parent, x); count[r] += 1; }
    let mut out: Vec<usize> = count.into_iter().filter(|&s| s > 0).collect();
    out.sort_unstable_by(|a, b| b.cmp(a));
    out
}

fn network(rng: &mut Rng, n: usize, p: f64) -> Vec<(usize, usize)> { // road 4: geometric jumps
    let (mut edges, mut v, mut w, lq) = (Vec::new(), 1i64, -1i64, (1.0 - p).ln());
    let n = n as i64;
    while v < n {
        w += 1 + ((1.0 - rng.u()).ln() / lq).floor() as i64;
        while w >= v && v < n { w -= v; v += 1; }
        if v < n { edges.push((v as usize, w as usize)); }
    }
    edges
}

fn stubs(rng: &mut Rng, count: usize, deg: usize) -> Vec<(usize, usize)> { // random pairing
    let mut s: Vec<usize> = (0..count).flat_map(|i| std::iter::repeat(i).take(deg)).collect();
    for i in (1..s.len()).rev() {           // Fisher-Yates shuffle, then pair neighbours
        let j = (rng.u() * (i + 1) as f64).floor() as usize;
        s.swap(i, j);
    }
    (0..s.len()).step_by(2).map(|k| (s[k], s[k + 1])).collect()
}

fn mean_se(xs: &[f64]) -> (f64, f64) {
    let m = xs.iter().sum::<f64>() / xs.len() as f64;
    let v = xs.iter().map(|x| (x - m) * (x - m)).sum::<f64>() / (xs.len() - 1) as f64;
    (m, (v / xs.len() as f64).sqrt())
}

fn main() {
    let (n, runs) = (1000usize, 40);
    let nf = n as f64;
    let mut rng = Rng { s: 2026 };
    let mut keep: Vec<Vec<Vec<usize>>> = vec![Vec::new()];
    println!("c, theory %, simulated largest % (40 networks), s.e. %");
    for i in 1..13 {
        let c = 0.25 * i as f64;
        let got: Vec<Vec<usize>> = (0..runs).map(|_| { let e = network(&mut rng, n, c / (nf - 1.0)); sizes(n, &e) }).collect();
        let (m, se) = mean_se(&got.iter().map(|g| g[0] as f64 / nf).collect::<Vec<_>>());
        println!("sweep, {:.2}, {:.2}, {:.2}, {:.2}", c, 100.0 * zeta_bisect(c), 100.0 * m, 100.0 * se);
        keep.push(got);
    }

    let c = 1.5;
    let path = extinction(c, 200);
    let q = path[path.len() - 1];
    let (z1, z2) = (zeta_bisect(c), 1.0 - q);
    let first: Vec<String> = path[..5].iter().map(|q| format!("{:.4}", q)).collect();
    println!("extinction chance by generation, c = 1.5: {}", first.join(", "));
    println!("limit q = {:.6}; road 2 share 1 - q = {:.6}; road 1 bisection = {:.6}", q, z2, z1);
    println!("setup: n = {}, pairs {}, c = 1.5, p = c/999 = {:.6}", n, n * (n - 1) / 2, c / (nf - 1.0));
    println!("check: exponent 1.5 x {:.4} = {:.4}; 1 - e^(-{:.4}) = {:.4}; giant about {:.0}, outside {:.0}", z1, c * z1, c * z1, 1.0 - (-c * z1).exp(), z1 * nf, (1.0 - z1) * nf);
    let lines = 10000;
    let alive: Vec<f64> = (0..lines).map(|_| if survives(&mut rng, c) { 1.0 } else { 0.0 }).collect();
    let (zs, zse) = mean_se(&alive);
    println!("road 3: {} family lines at c = 1.5 survive {:.4}, s.e. {:.4}, gap {:.1} s.e.", lines, zs, zse, (zs - z1) / zse);
    let low = (0..2000).filter(|_| survives(&mut rng, 0.5)).count();
    println!("road 3 at c = 0.5: {} of 2000 lines survive", low);
    let (m6, s6) = mean_se(&keep[6].iter().map(|g| g[0] as f64 / nf).collect::<Vec<_>>());
    let (m6b, _) = mean_se(&keep[6].iter().map(|g| g[1] as f64).collect::<Vec<_>>());
    println!("road 4: largest share at c = 1.5 {:.4}, s.e. {:.4}; second largest {:.1} people", m6, s6, m6b);

    let g2 = &keep[2];                      // c = 0.5, below the switch
    let big = g2.iter().map(|g| g[0]).max().unwrap();
    let (avg_big, _) = mean_se(&g2.iter().map(|g| g[0] as f64).collect::<Vec<_>>());
    let own_v: Vec<f64> = g2.iter().map(|g| g.iter().map(|&s| (s * s) as f64).sum::<f64>() / nf).collect();
    let (own, own_se) = mean_se(&own_v);
    let rate = 0.5 - 1.0 - (0.5f64).ln();
    let k = (2.0 * nf.ln() / rate).floor() as usize + 1;
    println!("c = 0.5: largest island mean {:.1}, biggest in 40 networks {}", avg_big, big);
    println!("c = 0.5: a person's own island {:.4} (s.e. {:.4}); bound 1/(1 - c) = {:.4}", own, own_se, 1.0 / (1.0 - 0.5));
    println!("c = 0.5: rate I = {:.4}; ln n = {:.4}; 2 ln n / I = {:.2}; k = {}", rate, nf.ln(), 2.0 * nf.ln() / rate, k);
    println!("c = 0.5: chance any island tops k is at most n e^(-k I) = {:.6}", nf * (-(k as f64) * rate).exp());
    let (crit, _) = mean_se(&keep[4].iter().map(|g| g[0] as f64).collect::<Vec<_>>());
    println!("c = 1: largest mean {:.1} people; n^(2/3) = {:.1}", crit, nf.powf(2.0 / 3.0));

    let mut quads = Vec::new();
    for g in 0..250 { for a in 0..4 { for b in (a + 1)..4 { quads.push((4 * g + a, 4 * g + b)); } } }
    let qs = sizes(n, &quads);
    let hubs: Vec<f64> = (0..runs).map(|_| { let e = stubs(&mut rng, 300, 3); sizes(n, &e)[0] as f64 }).collect();
    let (hub, _) = mean_se(&hubs);
    println!("breaks: 250 foursomes, average {:.1} friends, largest {}; theory {:.0}", 2.0 * quads.len() as f64 / nf, qs[0], zeta_bisect(3.0) * nf);
    println!("breaks: 300 people with 3 friends, 700 with none, average {:.1}, new friends per friend {:.1}, largest mean {:.1}", 900.0 / nf, 3.0 * 2.0 * 300.0 / 900.0, hub);
    println!("breaks: straight line 2(c - 1) at c = 1.5 gives {:.4}; at c = 1.1 {:.4} vs {:.4}", 2.0 * (c - 1.0), 2.0 * 0.1, zeta_bisect(1.1));
    println!("try: c = 2 share {:.4}; c = 3 share {:.4}", zeta_bisect(2.0), zeta_bisect(3.0));
    println!("try: outside the giant at c = 1.5, friends per person c q = {:.4}", c * q);
    println!("try: c = 6.9, expected loners n e^(-c) = {:.4}", nf * (-6.9f64).exp());

    assert!((z1 - z2).abs() < 1e-9);        // bisection against the generation limit
    assert!((zs - z1).abs() < 4.0 * zse);   // simulated family lines against the formula
    assert!((m6 - z1).abs() < 4.0 * s6);    // networks of 1,000 against the formula
    assert!(own < 1.0 / (1.0 - 0.5) + 3.0 * own_se); // the proven mean-size bound below the switch
    assert!(big < k);                       // the proven largest-island bound below the switch
}
