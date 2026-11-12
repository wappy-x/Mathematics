// Small worlds and hubs -- the same check as small_world_and_scale_free_models_check.py.
// Standard library only, no crates.  Synthetic networks of 5,000 people with about
// 10 friends each, drawn from SplitMix64 written out below.
// Compile: rustc --edition 2021 -O small_world_and_scale_free_models_check.rs -o /tmp/swsf
const N: usize = 5000; const H: usize = 5; const M: usize = 5;
const GAMMA: f64 = 0.5772156649015329;            // Euler's constant, for the path-length formula
type Adj = Vec<Vec<usize>>;

struct Rng(u64);
impl Rng {
    fn rnd(&mut self) -> f64 {                    // SplitMix64: a uniform number in [0, 1)
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64 * (2.0f64).powi(-53)
    }
    fn pick(&mut self, n: usize) -> usize { (self.rnd() * n as f64) as usize }
}
fn link(adj: &mut Adj, a: usize, b: usize) { adj[a].push(b); adj[b].push(a); }
fn unlink(adj: &mut Adj, a: usize, b: usize) { adj[a].retain(|&x| x != b); adj[b].retain(|&x| x != a); }

fn ring(n: usize, h: usize) -> Adj {              // everyone joined to the h nearest on each side
    let mut adj = vec![Vec::new(); n];
    for i in 0..n { for j in 1..=h { link(&mut adj, i, (i + j) % n); } }
    adj
}
fn watts_strogatz(n: usize, h: usize, beta: f64, seed: u64) -> Adj {
    let mut g = Rng(seed); let mut adj = ring(n, h);
    for i in 0..n { for j in 1..=h {
        if g.rnd() < beta {
            let mut t = g.pick(n);
            while t == i || adj[i].contains(&t) { t = g.pick(n); }
            unlink(&mut adj, i, (i + j) % n); link(&mut adj, i, t);
        }
    } }
    adj
}
fn erdos_renyi(n: usize, m: usize, seed: u64) -> Adj {   // exactly m links, each a random new pair
    let mut g = Rng(seed); let mut adj = vec![Vec::new(); n]; let mut made = 0;
    while made < m {
        let (a, b) = (g.pick(n), g.pick(n));
        if a != b && !adj[a].contains(&b) { link(&mut adj, a, b); made += 1; }
    }
    adj
}
fn grow(n: usize, m: usize, seed: u64, by_degree: bool) -> Adj {   // newcomers bring m links each
    let mut g = Rng(seed); let mut adj = vec![Vec::new(); n]; let mut ends: Vec<usize> = Vec::new();
    for a in 0..=m { for b in 0..a { link(&mut adj, a, b); ends.push(a); ends.push(b); } }
    for v in (m + 1)..n {
        let mut chosen: Vec<usize> = Vec::new();
        while chosen.len() < m {
            let t = if by_degree { ends[g.pick(ends.len())] } else { g.pick(v) };
            if !chosen.contains(&t) { chosen.push(t); }
        }
        for &t in &chosen { link(&mut adj, v, t); ends.push(v); ends.push(t); }
    }
    adj
}

struct R { k: f64, c: f64, l: f64, six: f64, reach: f64, mx: usize, k20: usize, k50: usize, sq: f64, sum: f64 }
fn clustering(adj: &Adj) -> f64 {                 // average share of a person's friend pairs who are friends
    let mut mark = vec![false; adj.len()]; let mut total = 0.0;
    for v in 0..adj.len() {
        let k = adj[v].len();
        if k < 2 { continue; }
        for &u in &adj[v] { mark[u] = true; }
        let mut tri = 0usize;
        for &u in &adj[v] { for &w in &adj[u] { if mark[w] { tri += 1; } } }
        for &u in &adj[v] { mark[u] = false; }
        total += (tri / 2) as f64 / ((k * (k - 1)) as f64 / 2.0);
    }
    total / adj.len() as f64
}
fn measure(adj: &Adj) -> R {
    let n = adj.len(); let (mut tot, mut cnt, mut near, mut srcs) = (0u64, 0u64, 0u64, 0u64);
    for s in (0..n).step_by(10) {                 // breadth-first search from every 10th person
        let mut dist = vec![-1i64; n]; dist[s] = 0; let mut q = vec![s]; let mut i = 0; srcs += 1;
        while i < q.len() {
            let u = q[i]; i += 1;
            for &w in &adj[u] { if dist[w] < 0 { dist[w] = dist[u] + 1; q.push(w); } }
        }
        for &d in &dist { if d > 0 { tot += d as u64; cnt += 1; if d <= 6 { near += 1; } } }
    }
    let deg: Vec<usize> = adj.iter().map(|a| a.len()).collect();
    let sum: usize = deg.iter().sum();
    R { k: sum as f64 / n as f64, c: clustering(adj), l: tot as f64 / cnt as f64, six: near as f64 / cnt as f64,
        reach: cnt as f64 / (srcs * (n as u64 - 1)) as f64, mx: *deg.iter().max().unwrap(),
        k20: deg.iter().filter(|&&d| d >= 20).count(), k50: deg.iter().filter(|&&d| d >= 50).count(),
        sq: deg.iter().map(|&d| (d * d) as f64).sum(), sum: sum as f64 }
}

fn main() {
    let (er, ba, un) = (measure(&erdos_renyi(N, 25000, 1)), measure(&grow(N, M, 2, true)), measure(&grow(N, M, 2, false)));
    let sweep = [0.0, 0.001, 0.003, 0.01, 0.03, 0.1, 0.3, 1.0];
    let labels = ["0", "0.001", "0.003", "0.01", "0.03", "0.1", "0.3", "1.0"];
    let ws: Vec<R> = sweep.iter().map(|&b| measure(&watts_strogatz(N, H, b, 3))).collect();
    println!("5,000 synthetic people; paths from every 10th person (500 searches)");
    println!("{:<24}{:>7}{:>8}{:>9}{:>8}{:>6}{:>6}{:>6}", "model", "mean k", "C", "L", "<=6", "max k", "k>=20", "k>=50");
    for (name, r) in [("ER, 25,000 links", &er), ("WS ring, beta = 0", &ws[0]), ("WS beta = 0.01", &ws[3]),
                      ("WS beta = 0.1", &ws[5]), ("BA, m = 5", &ba), ("growth, no preference", &un)] {
        println!("{:<24}{:7.3}{:8.4}{:9.3}{:8.4}{:6}{:6}{:6}", name, r.k, r.c, r.l, r.six, r.mx, r.k20, r.k50);
    }
    let c0 = 3.0 * (H - 1) as f64 / (2.0 * (2 * H - 1) as f64);   // ring clustering, by counting triangles
    let l0 = (1..N).map(|d| (d.min(N - d) + H - 1) / H).sum::<usize>() as f64 / (N - 1) as f64;
    let p = 2.0 * 25000.0 / (N * (N - 1)) as f64;                 // ER: chance a given pair is linked
    let kbar = 2.0 * 25000.0 / N as f64;
    let l_er = ((N as f64).ln() - GAMMA) / kbar.ln() + 0.5;       // ER path-length formula
    let (mut pois, mut term) = (0.0f64, (-kbar).exp());           // Poisson(10): chance of under 20
    for k in 0..20 { pois += term; term *= kbar / (k + 1) as f64; }
    let tail = |k: f64| (M * (M + 1)) as f64 / (k * (k + 1.0));   // BA: share with k or more friends
    let rows: Vec<(&str, f64)> = vec![
        ("by hand: links n<k>/2", N as f64 * kbar / 2.0), ("by hand: ln n", (N as f64).ln()), ("by hand: ln<k>", kbar.ln()), ("by hand: gamma", GAMMA),
        ("ring linked friend pairs", (3 * H * (H - 1)) as f64 / 2.0), ("ring friend pairs h(2h-1)", (H * (2 * H - 1)) as f64),
        ("shortcuts n h beta, 0.01", (N * H) as f64 * 0.01), ("shortcuts n h beta, 0.1", (N * H) as f64 * 0.1),
        ("(1-beta)^3 at 0.1", 0.9f64.powf(3.0)),
        ("ring C, counted", ws[0].c), ("  3(h-1)/(2(2h-1))", c0),
        ("ring L, by search", ws[0].l), ("  exact sum over offsets", l0), ("  rough n/(4h)", N as f64 / (4 * H) as f64),
        ("WS 0.01 C", ws[3].c), ("  C0 (1-beta)^3", c0 * 0.99f64.powf(3.0)),
        ("WS 0.1 C", ws[5].c), ("  C0 (1-beta)^3", c0 * 0.9f64.powf(3.0)),
        ("ER C", er.c), ("  p = <k>/(n-1)", p),
        ("ER L", er.l), ("  (ln n - gamma)/ln<k> + 1/2", l_er), ("  wrong: ln n / ln<k>", (N as f64).ln() / kbar.ln()),
        ("ER people with k>=20", er.k20 as f64), ("  Poisson(10) expects", N as f64 * (1.0 - pois)),
        ("BA share k>=20", ba.k20 as f64 / N as f64), ("  m(m+1)/(k(k+1))", tail(20.0)), ("  n m(m+1)/(k(k+1))", N as f64 * tail(20.0)),
        ("BA people with k>=50", ba.k50 as f64), ("  n m(m+1)/(k(k+1))", N as f64 * tail(50.0)),
        ("no-preference people k>=20", un.k20 as f64), ("  long run n (m/(m+1))^15", N as f64 * (M as f64 / (M + 1) as f64).powf(15.0)),
        ("no-preference people k>=50", un.k50 as f64), ("  oldest expects m + sum m/v", M as f64 + ((M + 1)..N).map(|v| M as f64 / v as f64).sum::<f64>()),
        ("BA average friend's k", ba.sq / ba.sum), ("ER average friend's k", er.sq / er.sum),
        ("wrong: BA mean k taken as m", M as f64)];
    for (name, v) in &rows { println!("{:<32}{:12.4}", name, v); }
    println!("chart, beta      {}", labels.iter().map(|b| format!("{:>6}", b)).collect::<Vec<_>>().join(" "));
    println!("chart, C/C0      {}", ws.iter().map(|r| format!("{:6.3}", r.c / ws[0].c)).collect::<Vec<_>>().join(" "));
    println!("chart, L/L0      {}", ws.iter().map(|r| format!("{:6.3}", r.l / ws[0].l)).collect::<Vec<_>>().join(" "));
    println!("chart, L         {}", ws.iter().map(|r| format!("{:6.2}", r.l)).collect::<Vec<_>>().join(" "));
    let (t1, t2, t3) = (measure(&erdos_renyi(N, 10000, 4)), measure(&grow(N, 2, 5, true)), measure(&watts_strogatz(N, 2, 0.01, 6)));
    println!("try: ER 10,000 links   L {:.3}  formula {:.3}  reached {:.4}", t1.l, ((N as f64).ln() - GAMMA) / 4f64.ln() + 0.5, t1.reach);
    println!("try: BA m = 2          L {:.3}  max k {}  k>=50 {}", t2.l, t2.mx, t2.k50);
    println!("try: WS h = 2, 0.01    L {:.3}  C {:.4}  <=6 {:.4}", t3.l, t3.c, t3.six);

    assert!((ws[0].c - 2.0 / 3.0).abs() < 1e-12, "ring clustering must be exactly 2/3");
    assert!((ws[0].l - l0).abs() < 1e-9, "ring search must equal the exact offset sum");
    assert!((ws[5].c - c0 * 0.9f64.powf(3.0)).abs() < 0.02, "rewired clustering vs triangles surviving");
    assert!((er.c - p).abs() < 0.0005, "ER clustering vs p");
    assert!((er.l - l_er).abs() < 0.1, "ER path length vs formula");
    assert!((ba.k20 as f64 / N as f64 - tail(20.0)).abs() < 0.015, "BA degree tail vs m(m+1)/(k(k+1))");
    assert!((ba.k50 as f64 - N as f64 * tail(50.0)).abs() < 20.0, "BA hub count vs the tail formula");
    assert!(ws[5].c > 100.0 * er.c && ws[5].l < 1.5 * er.l, "small world: clustered and short");
    assert!(er.reach == 1.0 && ba.reach == 1.0, "networks must be in one piece");
    println!("ALL CHECKS PASS");
}
