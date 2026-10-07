// Random walks on a graph -- the same check as the Python, in Rust.  No crates.
// A six-page website where every link works both ways.  A surfer clicks one of
// the current page's links, each equally likely.  Where does the surfer spend
// time, how fast does the starting page stop mattering, and what is PageRank?
type M = Vec<Vec<f64>>;
const NAMES: [&str; 6] = ["Home", "About", "Blog", "Shop", "Contact", "FAQ"];
const EDGES: [(usize, usize); 8] = [(0, 1), (0, 2), (0, 3), (0, 4), (2, 3), (2, 5), (3, 4), (3, 5)];
struct Rng { s: u64 }                             // SplitMix64, written out
impl Rng {
    fn below(&mut self, k: usize) -> usize {      // a whole number 0 .. k-1, equally likely
        self.s = self.s.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.s;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        (((z ^ (z >> 31)) >> 11) as f64 / 9007199254740992.0 * k as f64) as usize
    }
}
fn step_matrix(out: &[Vec<usize>]) -> M {         // P[i][j]: chance one click goes from i to j
    (0..6).map(|i| (0..6).map(|j| out[i].iter().filter(|&&x| x == j).count() as f64
        / out[i].len() as f64).collect()).collect()
}
fn advance(p: &[f64], pm: &M) -> Vec<f64> { (0..6).map(|j| (0..6).map(|i| p[i] * pm[i][j]).sum()).collect() }   // one click
fn tv(p: &[f64], q: &[f64]) -> f64 { 0.5 * p.iter().zip(q).map(|(a, b)| (a - b).abs()).sum::<f64>() }   // total variation
fn solve(m: &M, b: &[f64]) -> Vec<f64> {          // Gaussian elimination with row swaps
    let n = b.len();
    let mut a: M = (0..n).map(|i| { let mut r = m[i].clone(); r.push(b[i]); r }).collect();
    for c in 0..n {
        let mut r = c;
        for k in c..n { if a[k][c].abs() > a[r][c].abs() { r = k } }
        a.swap(c, r);
        for k in c + 1..n {
            let f = a[k][c] / a[c][c];
            for j in 0..=n { a[k][j] -= f * a[c][j] }
        }
    }
    let mut x = vec![0.0; n];
    for c in (0..n).rev() {
        let s: f64 = (c + 1..n).map(|j| a[c][j] * x[j]).sum();
        x[c] = (a[c][n] - s) / a[c][c];
    }
    x
}
fn stationary(pm: &M) -> Vec<f64> {               // road two: pi P = pi, entries add to 1
    let m: M = (0..5).map(|i| (0..6).map(|j| pm[j][i] - (i == j) as i32 as f64).collect()).chain([vec![1.0; 6]]).collect();
    solve(&m, &[0.0, 0.0, 0.0, 0.0, 0.0, 1.0])
}
fn jacobi(s: &M) -> Vec<f64> {                    // every eigenvalue of a symmetric matrix
    let mut a = s.clone();
    for _ in 0..30 {
        for p in 0..5 {
            for q in p + 1..6 {
                if a[p][q].abs() < 1e-15 { continue }
                let th = 0.5 * (2.0 * a[p][q]).atan2(a[q][q] - a[p][p]);
                let (c, sn) = (th.cos(), th.sin());       // rotate columns p and q, then rows p and q
                for k in 0..6 { let (x, y) = (a[k][p], a[k][q]); (a[k][p], a[k][q]) = (c * x - sn * y, sn * x + c * y) }
                for k in 0..6 { let (x, y) = (a[p][k], a[q][k]); (a[p][k], a[q][k]) = (c * x - sn * y, sn * x + c * y) }
            }
        }
    }
    let mut e: Vec<f64> = (0..6).map(|i| a[i][i]).collect();
    e.sort_by(|x, y| y.partial_cmp(x).unwrap());
    e
}
fn f4(xs: &[f64]) -> String { xs.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(" ") }
fn main() {
    let out: Vec<Vec<usize>> = (0..6).map(|i| EDGES.iter().filter(|e| e.0 == i).map(|e| e.1)
        .chain(EDGES.iter().filter(|e| e.1 == i).map(|e| e.0)).collect()).collect();
    let (pm, m) = (step_matrix(&out), EDGES.len());
    let deg: Vec<usize> = out.iter().map(|o| o.len()).collect();
    let pi_deg: Vec<f64> = deg.iter().map(|&d| d as f64 / (2 * m) as f64).collect();   // road one
    let pi_sol = stationary(&pm);
    println!("pages {}; links m = {}, 2m = {}", NAMES.join(" "), m, 2 * m);
    println!("degrees {}", deg.iter().map(|d| d.to_string()).collect::<Vec<_>>().join(" "));
    println!("pi by degree / 2m  {}", f4(&pi_deg));
    println!("pi by solving      {}", f4(&pi_sol));
    println!("flow along a link, each way, pi(i)/deg(i): {}", f4(&(0..6).map(|i| pi_deg[i] / deg[i] as f64).collect::<Vec<_>>()));
    let mut dist: M = (0..6).map(|i| (0..6).map(|j| (i == j) as i32 as f64).collect()).collect();
    let mut vv: Vec<Vec<i64>> = (0..6).map(|i| (0..6).map(|j| (i == j) as i64).collect()).collect();   // road two: 12^t P^t, whole numbers
    let (mut d_all, mut d_about, mut tv_exact) = (vec![], vec![], vec![]);
    for t in 0..13 {                              // every start page at once, 0 to 12 clicks
        if (1..=3).contains(&t) {
            println!("from About, t = {}: {} TV {:.4}", t, f4(&dist[1]), tv(&dist[1], &pi_deg));
        }
        d_all.push(dist.iter().map(|r| tv(r, &pi_deg)).fold(0.0, f64::max));
        d_about.push(tv(&dist[1], &pi_deg));
        tv_exact.push(vv.iter().map(|v| (0..6).map(|j| (2 * m as i64 * v[j] - deg[j] as i64 * 12i64.pow(t)).abs()).sum::<i64>()).max().unwrap() as f64 / (4 * m as i64 * 12i64.pow(t)) as f64);
        dist = dist.iter().map(|r| advance(r, &pm)).collect();
        vv = vv.iter().map(|v| (0..6).map(|j| (0..6).filter(|&i| out[i].contains(&j)).map(|i| v[i] * (12 / deg[i] as i64)).sum()).collect()).collect();
    }
    let t_mix = (0..13).find(|&t| d_all[t] <= 0.25).unwrap();
    println!("TV from About, t = 0..12:   {}", f4(&d_about));
    println!("worst start TV, t = 0..12:  {}", f4(&d_all));
    println!("mixing time t_mix(1/4) = {} clicks", t_mix);
    let s: M = (0..6).map(|i| (0..6).map(|j| pm[i][j] * (deg[i] as f64 / deg[j] as f64).sqrt()).collect()).collect();
    let eig = jacobi(&s);
    let lam = eig[1..].iter().map(|e| e.abs()).fold(0.0, f64::max);
    let v: Vec<f64> = pi_deg.iter().map(|q| q.sqrt()).collect();
    let mut x = vec![1.0, -2.0, 3.0, -1.0, 0.5, 2.0];
    let mul = |x: &[f64]| -> Vec<f64> { (0..6).map(|i| (0..6).map(|j| s[i][j] * x[j]).sum()).collect() };
    for _ in 0..3000 {                            // road two: power iteration, top direction removed
        let y = mul(&x);
        let dot: f64 = v.iter().zip(&y).map(|(a, b)| a * b).sum();
        let z: Vec<f64> = y.iter().zip(&v).map(|(a, b)| a - dot * b).collect();
        let nx = z.iter().map(|a| a * a).sum::<f64>().sqrt();
        x = z.iter().map(|a| a / nx).collect();
    }
    let lam_pow = mul(&x).iter().map(|a| a * a).sum::<f64>().sqrt();
    let (sq_eig, sq_edges): (f64, f64) = (eig.iter().map(|e| e * e).sum(),
        EDGES.iter().map(|&(a, b)| 2.0 / (deg[a] * deg[b]) as f64).sum());
    println!("eigenvalues of P: {}", f4(&eig));
    println!("lambda* by Jacobi {:.4}, by power iteration {:.4}", lam, lam_pow);
    println!("sum of squared eigenvalues {:.4}; sum over links of 2/(deg deg) {:.4}", sq_eig, sq_edges);
    let bound: Vec<f64> = (0..13).map(|t| 0.5 * (1.0 / pi_deg[1] - 1.0).sqrt() * lam.powi(t)).collect();
    println!("bound from About, t = 0..12: {}", f4(&bound));
    let f2 = |xs: &[f64]| xs.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("figure, TV from About {}\nfigure, bound         {}", f2(&d_about), f2(&bound));
    let (mut rng, n, clicks) = (Rng { s: 2026 }, 20000usize, 40);   // road three: simulated surfers
    let mut count = [0usize; 6];
    for _ in 0..n {
        let mut page = 1;
        for _ in 0..clicks { page = out[page][rng.below(deg[page])] }
        count[page] += 1
    }
    let freq: Vec<f64> = count.iter().map(|&c| c as f64 / n as f64).collect();
    let se: Vec<f64> = freq.iter().map(|f| (f * (1.0 - f) / n as f64).sqrt()).collect();
    println!("{} surfers, {} clicks from About: {}", n, clicks, f4(&freq));
    println!("  standard errors:                   {}", f4(&se));
    let (mut page, mut steps, mut trips) = (1usize, 0usize, Vec::new());
    while trips.len() < n {                       // return trips to About, on one long walk
        (page, steps) = (out[page][rng.below(deg[page])], steps + 1);
        if page == 1 { trips.push(steps as f64); steps = 0 }
    }
    let mt = trips.iter().sum::<f64>() / n as f64;   // mean trip, then its standard error
    let st = (trips.iter().map(|a| (a - mt) * (a - mt)).sum::<f64>() / (n - 1) as f64 / n as f64).sqrt();
    println!("mean return time to About {:.2} clicks (se {:.2}); 1/pi = {:.2}", mt, st, 1.0 / pi_deg[1]);
    let (dd, mut r) = (0.85, vec![1.0 / 6.0; 6]);   // PageRank on the same site
    for _ in 0..200 { r = advance(&r, &pm).iter().map(|y| (1.0 - dd) / 6.0 + dd * y).collect() }
    let g: M = (0..6).map(|i| (0..6).map(|j| (i == j) as i32 as f64 - dd * pm[j][i]).collect()).collect();
    let r_sol = solve(&g, &[(1.0 - dd) / 6.0; 6]);
    println!("PageRank d = 0.85, iterated {}", f4(&r));
    println!("PageRank d = 0.85, solved   {}", f4(&r_sol));
    let one_way: Vec<Vec<usize>> = out[..5].iter().cloned().chain([vec![0]]).collect();   // FAQ links to Home only
    let (p1, mut pw) = (step_matrix(&one_way), vec![1.0 / 6.0; 6]);
    let (pi_one, hit) = (stationary(&p1), solve(&(0..6).map(|i| (0..6).map(|j| (i == j) as i32 as f64 - pm[i][j] * (j != 5) as i32 as f64).collect()).collect(), &[1.0; 6]));
    for _ in 0..500 { pw = advance(&pw, &p1) }       // road two: 500 clicks from the even spread
    let indeg: Vec<f64> = (0..6).map(|j| one_way.iter().flatten().filter(|&&x| x == j).count() as f64).collect();
    let tot: f64 = indeg.iter().sum();
    println!("one-way site, true pi:      {}", f4(&pi_one));
    println!("one-way site, in-degree/{}: {}", tot, f4(&indeg.iter().map(|k| k / tot).collect::<Vec<_>>()));
    let ring = step_matrix(&(0..6).map(|k| vec![(k + 5) % 6, (k + 1) % 6]).collect::<Vec<_>>());
    let lazy: M = (0..6).map(|i| (0..6).map(|j| 0.5 * ring[i][j] + 0.5 * (i == j) as i32 as f64).collect()).collect();
    let (mut a, mut b, flat) = (vec![1.0, 0.0, 0.0, 0.0, 0.0, 0.0], vec![1.0, 0.0, 0.0, 0.0, 0.0, 0.0], [1.0 / 6.0; 6]);
    for _ in 0..60 { a = advance(&a, &ring); b = advance(&b, &lazy) }
    println!("ring of six, TV after 60 clicks {:.4}, after 61 {:.4}; lazy walk after 60 {:.4}", tv(&a, &flat), tv(&advance(&a, &ring), &flat), tv(&b, &flat));
    let maxdiff = |x: &[f64], y: &[f64]| x.iter().zip(y).map(|(p, q)| (p - q).abs()).fold(0.0, f64::max);
    assert!(maxdiff(&pi_deg, &pi_sol) < 1e-12);                              // formula vs solving
    assert!((0..6).all(|i| (freq[i] - pi_deg[i]).abs() < 4.0 * se[i]));     // simulation vs formula
    assert!((mt - (2 * m) as f64 / deg[1] as f64).abs() < 4.0 * st);        // return time vs 2m/deg
    assert!((lam - lam_pow).abs() < 1e-9);                                  // two roads to lambda*
    assert!((sq_eig - sq_edges).abs() < 1e-9);                              // Jacobi vs a link count
    assert!((0..13).all(|t| d_about[t] <= bound[t] + 1e-12));               // the spectral bound holds
    assert!((0..13).all(|t| (d_all[t] - tv_exact[t]).abs() + (d_about[t] - tv_exact[t]).abs() < 1e-12));   // distances, two roads; About worst
    assert!(t_mix == (0..13).find(|&t| tv_exact[t] <= 0.25).unwrap());     // mixing time, two roads
    assert!(maxdiff(&r, &r_sol) < 1e-12);                                   // PageRank, two roads
    assert!(maxdiff(&pi_one, &pw) < 1e-12);                                 // one-way shares, two roads
    assert!((pi_one[5] * (1.0 + hit[0]) - 1.0).abs() < 1e-12);   // road three, Kac: FAQ clicks to Home, then hit[0] clicks back on the two-way site
    assert!((jacobi(&ring)[5] + 1.0).abs() < 1e-9);                         // the ring's eigenvalue -1
    assert!((tv(&a, &flat) - 0.5).abs() + (tv(&advance(&a, &ring), &flat) - 0.5).abs() < 1e-12);   // parity: all on one half, which holds 1/2
    println!("ALL CHECKS PASS");
}
