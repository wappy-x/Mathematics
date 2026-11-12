// Centrality and PageRank -- the check behind the card.  Rust std only, no crates.
// Ten bike stations (synthetic; the standard kite test network).  Four ideas of "hub",
// each reached by two roads; PageRank by three.  Nothing imported knows the answer.
const NAMES: [&str; 10] = ["Arcade", "Bus Station", "Cathedral", "Market", "East Gate",
    "Fountain", "Guildhall", "Hill Top", "Riverside", "Quay"];
const KEY: &str = "ABCMEFGHRQ"; const N: usize = 10;

fn splitmix(s: &mut u64) -> u64 { // SplitMix64, seed 2026
    *s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*s ^ (*s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}
fn row(label: &str, xs: &[f64]) {
    println!("{:<21}{}", label, xs.iter().map(|x| format!("{:6.3}", x)).collect::<Vec<_>>().join(" "));
}
fn rowi(label: &str, xs: &[usize]) {
    println!("{:<21}{}", label, xs.iter().map(|x| format!("{:6}", x)).collect::<Vec<_>>().join(" "));
}
struct Net { links: Vec<String>, pairs: Vec<(usize, usize)>, nbr: Vec<Vec<usize>> }
impl Net {
    fn trips(&self, oneway: &[&str]) -> Vec<Vec<usize>> { // where a bike can go next
        let mut out = vec![vec![]; N];
        for (&(i, j), l) in self.pairs.iter().zip(&self.links) {
            out[i].push(j); if !oneway.contains(&l.as_str()) { out[j].push(i); }
        }
        out
    }
    fn bfs(&self, s: usize, work: &mut usize) -> (Vec<i64>, Vec<usize>, Vec<f64>, Vec<Vec<usize>>) {
        let (mut d, mut order, mut sig, mut pred) = (vec![-1i64; N], vec![s], vec![0.0; N], vec![vec![]; N]);
        d[s] = 0; sig[s] = 1.0; let mut k = 0;
        while k < order.len() {
            let u = order[k]; k += 1;
            for &v in &self.nbr[u] {
                *work += 1;
                if d[v] < 0 { d[v] = d[u] + 1; order.push(v); }
                if d[v] == d[u] + 1 { sig[v] += sig[u]; pred[v].push(u); }
            }
        }
        (d, order, sig, pred)
    }
    fn backward_pass(&self, work: &mut usize) -> Vec<f64> { // each route's credit, passed back from its far end
        let mut b = vec![0.0; N];
        for s in 0..N {
            let (_, order, sig, pred) = self.bfs(s, work); let mut delta = vec![0.0; N];
            for &w in order.iter().rev() {
                for &v in &pred[w] { delta[v] += sig[v] / sig[w] * (1.0 + delta[w]); }
                if w != s { b[w] += delta[w] / 2.0; }
            }
        }
        b
    }
}
fn pagerank_iter(out: &[Vec<usize>], alpha: f64) -> Vec<f64> {
    let mut p = vec![1.0 / N as f64; N]; for _ in 0..200 {
        let mut q = vec![(1.0 - alpha) / N as f64; N];
        for i in 0..N { for &j in &out[i] { q[j] += alpha * p[i] / out[i].len() as f64; } }
        p = q; }
    p
}
fn pagerank_solve(out: &[Vec<usize>], alpha: f64) -> Vec<f64> { // last row: sum = 1
    let mut m: Vec<Vec<f64>> = (0..N).map(|i| {
        let mut r: Vec<f64> = (0..N).map(|j| (if i == j { 1.0 } else { 0.0 })
            - if out[j].contains(&i) { alpha / out[j].len() as f64 } else { 0.0 }).collect();
        r.push((1.0 - alpha) / N as f64); r }).collect(); m[N - 1] = vec![1.0; N + 1];
    for c in 0..N {
        let mut p = c;
        for r in c..N { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in 0..N {
            if r != c {
                let (k, pc) = (m[r][c] / m[c][c], m[c].clone());
                for (a, b) in m[r].iter_mut().zip(&pc) { *a -= k * b; }
            }
        }
    }
    (0..N).map(|i| m[i][N] / m[i][i]).collect()
}
fn win(xs: &[f64]) -> String { let mx = xs.iter().cloned().fold(f64::MIN, f64::max);
    (0..N).filter(|&i| (xs[i] - mx).abs() < 1e-9).map(|i| NAMES[i]).collect::<Vec<_>>().join(" ")
}
fn routes(s: usize, t: usize, nbr: &[Vec<usize>], dist: &[Vec<i64>]) -> Vec<Vec<usize>> {
    if s == t { return vec![vec![t]]; } // every shortest route s -> t, walked by distance
    nbr[s].iter().filter(|&&v| dist[v][t] == dist[s][t] - 1)
        .flat_map(|&v| routes(v, t, nbr, dist).into_iter().map(move |r| [vec![s], r].concat())).collect()
}
fn main() {
    let key: Vec<char> = KEY.chars().collect();
    let links: Vec<String> = "AB AC AM AF BM BE BG CM CF ME MF MG EG FG FH GH HR RQ"
        .split(' ').map(String::from).collect();
    let at = |c: char| key.iter().position(|&k| k == c).unwrap();
    let pairs: Vec<(usize, usize)> = links.iter().map(|l| { let c: Vec<char> = l.chars().collect(); (at(c[0]), at(c[1])) }).collect();
    let mut nbr = vec![vec![]; N]; for &(i, j) in &pairs { nbr[i].push(j); nbr[j].push(i); }
    let mut net = Net { links, pairs, nbr }; let m = net.links.len();
    println!("{:<21}{}", "station", key.iter().map(|c| format!("{:>7}", c)).collect::<String>());
    // ---- degree: row sums of A, and a count down the link list ----
    let a: Vec<Vec<usize>> = (0..N).map(|i| (0..N).map(|j| net.nbr[i].contains(&j) as usize).collect()).collect();
    let deg: Vec<usize> = a.iter().map(|r| r.iter().sum()).collect();
    let deg2: Vec<usize> = key.iter().map(|&c| net.links.iter().map(|l| l.matches(c).count()).sum()).collect();
    assert!(deg == deg2 && deg.iter().sum::<usize>() == 2 * m);
    rowi("degree", &deg); row("degree / (n-1)", &deg.iter().map(|&d| d as f64 / (N - 1) as f64).collect::<Vec<_>>());
    // ---- distances: breadth-first search, and powers of A ----
    let mut work = 0usize; let dist: Vec<Vec<i64>> = (0..N).map(|s| net.bfs(s, &mut work).0).collect();
    let mut dpow: Vec<Vec<i64>> = (0..N).map(|i| (0..N).map(|j| if i == j { 0 } else { -1 }).collect()).collect();
    let mut ak = a.clone(); for k in 1..N {
        for i in 0..N { for j in 0..N { if dpow[i][j] < 0 && ak[i][j] > 0 { dpow[i][j] = k as i64; } } }
        ak = (0..N).map(|i| (0..N).map(|j| (0..N).map(|t| ak[i][t] * a[t][j]).sum()).collect()).collect();
    }
    assert!(dpow == dist);
    let far: Vec<usize> = dist.iter().map(|r| r.iter().sum::<i64>() as usize).collect();
    let clo: Vec<f64> = far.iter().map(|&f| (N - 1) as f64 / f as f64).collect();
    rowi("distance sum", &far); row("closeness", &clo); println!("distance from F: {} ; sigma M-H {}", dist[5].iter().map(|d| d.to_string()).collect::<Vec<_>>().join(" "), net.bfs(3, &mut work).2[7] as usize);
    // ---- betweenness: the backward pass, and every shortest route listed ----
    work = 0; let bet = net.backward_pass(&mut work);
    assert!(work == N * 2 * m);
    let (mut brute, mut first, mut listed, mut fparts) = (vec![0.0; N], vec![0usize; N], 0, vec![]);
    for s in 0..N {
        for t in s + 1..N {
            let rs = routes(s, t, &net.nbr, &dist); listed += rs.len();
            for v in 0..N {
                let c = rs.iter().filter(|r| r[1..r.len() - 1].contains(&v)).count();
                let x = c as f64 / rs.len() as f64; brute[v] += x;
                if v == 5 && x > 0.0 { fparts.push(format!("{}{} {:.3}", key[s], key[t], x)); }
                first[v] += rs[0][1..rs[0].len() - 1].contains(&v) as usize;
            }
        }
    }
    assert!((0..N).all(|i| (bet[i] - brute[i]).abs() < 1e-12));
    row("betweenness", &bet); println!("Fountain's pairs: {}", fparts.join(" "));
    println!("backward-pass route checks {} = n * 2m; shortest routes listed {}", work, listed);
    println!("n {} m {} n-1 {} 2m {} pairs {} ; without Hill Top {} ; town x river {}",
        N, m, N - 1, 2 * m, N * (N - 1) / 2, (N - 1) * (N - 2) / 2, 7 * 2);
    // ---- PageRank: iterate, solve, and follow 20,000 bikes ----
    let out = net.trips(&["HR"]); let (pr, prs) = (pagerank_iter(&out, 0.85), pagerank_solve(&out, 0.85));
    assert!((0..N).all(|i| (pr[i] - prs[i]).abs() < 1e-12) && (pr.iter().sum::<f64>() - 1.0).abs() < 1e-12);
    let (mut st, mut count, bikes) = (2026u64, vec![0usize; N], 20000usize);
    for _ in 0..bikes {
        let mut i = (splitmix(&mut st) % N as u64) as usize;
        for _ in 0..50 {
            if (splitmix(&mut st) >> 11) as f64 / 9007199254740992.0 < 0.85 {
                i = out[i][(splitmix(&mut st) % out[i].len() as u64) as usize];
            } else { i = (splitmix(&mut st) % N as u64) as usize; } }
        count[i] += 1; }
    let sim: Vec<f64> = count.iter().map(|&c| c as f64 / bikes as f64).collect();
    assert!((0..N).all(|i| (sim[i] - pr[i]).abs() < 4.0 * (pr[i] * (1.0 - pr[i]) / bikes as f64).sqrt()));
    row("PageRank, one-way", &pr); row("simulated bikes", &sim);
    let (h3, back) = (pr[7] / 3.0, 0.015 + 0.85 * (pr[7] / 3.0 + pr[9])); assert!((back - pr[8]).abs() < 1e-12);
    println!("Riverside in: {:.6} / 3 = {:.6}; 0.015 + 0.85 * ({:.6} + {:.6}) = 0.015 + 0.85 * {:.6} = 0.015 + {:.6} = {:.6}",
        pr[7], h3, h3, pr[9], h3 + pr[9], 0.85 * (h3 + pr[9]), back);
    let two = pagerank_iter(&net.trips(&[]), 0.85); row("PageRank, two-way", &two);
    row("degree / 2m", &deg.iter().map(|&d| d as f64 / (2 * m) as f64).collect::<Vec<_>>());
    let degf: Vec<f64> = deg.iter().map(|&d| d as f64).collect(); assert!(win(&two) == win(&degf));
    for (lab, xs) in [("degree", &degf), ("closeness", &clo), ("betweenness", &bet), ("PageRank", &pr)] {
        println!("winner by {}: {}", lab, win(xs));
    }
    assert!(win(&degf) == "Market" && win(&bet) == "Hill Top" && win(&pr) == "Riverside");
    assert!(win(&clo) == "Fountain Guildhall" && (bet[7] - 14.0).abs() < 1e-12);
    // ---- what breaks ----
    rowi("one route per pair", &first);
    println!("biggest distance sum: {}", win(&far.iter().map(|&f| f as f64).collect::<Vec<_>>()));
    let nod = pagerank_solve(&out, 1.0); row("no jumps (0.85 -> 1)", &nod);
    assert!((nod[8] - 0.5).abs() < 1e-12 && nod[..8].iter().all(|x| x.abs() < 1e-12));
    // ---- try changing ----
    net.links.push("FR".to_string()); net.pairs.push((5, 8)); net.nbr[5].push(8); net.nbr[8].push(5);
    row("betweenness + F-R", &net.backward_pass(&mut work));
    row("PageRank + F-R", &pagerank_iter(&net.trips(&["HR"]), 0.85));
    row("PageRank, 0.5", &pagerank_iter(&out, 0.5));
    println!("figure, A 60 40, B 150 40, C 25 110, M 105 110, E 190 110, F 60 170, G 150 170, H 105 220, R 215 220, Q 320 220");
    println!("ALL CHECKS PASS");
}
