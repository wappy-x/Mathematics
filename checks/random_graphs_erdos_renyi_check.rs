// Random graphs G(n, p) -- the same check as the Python, in Rust.  No crates.
// 1,000 people; each of the 499,500 pairs becomes a friendship with chance
// 0.003, every pair on its own coin.  Three roads: the formulas, every outcome
// of a 4-person network enumerated, and 40 networks drawn from a SplitMix64
// generator written out here (seed 20260929).
const N: usize = 1000;
const P: f64 = 0.003;

struct SplitMix(u64); // 64 random bits per call

impl SplitMix {
    fn next(&mut self) -> u64 {
        self.0 = self.0.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = self.0;
        z = (z ^ (z >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        z ^ (z >> 31)
    }
}

fn binom_pmf(m: usize, p: f64) -> Vec<f64> { // P(X = k) for k = 0..m, ratio rule
    let mut out = vec![(1.0 - p).powf(m as f64)];
    for k in 0..m {
        let last = out[k];
        out.push(last * (m - k) as f64 / (k + 1) as f64 * p / (1.0 - p));
    }
    out
}

fn poisson_pmf(lam: f64, kmax: usize) -> Vec<f64> { // P(Y = k) for k = 0..kmax
    let mut out = vec![(-lam).exp()];
    for k in 0..kmax {
        let last = out[k];
        out.push(last * lam / (k + 1) as f64);
    }
    out
}

fn tv(a: &[f64], b: &[f64]) -> f64 { // half the summed gaps between two laws
    0.5 * a.iter().zip(b).map(|(x, y)| (x - y).abs()).sum::<f64>()
}

fn mean_se(xs: &[f64]) -> (f64, f64) { // average and its standard error
    let n = xs.len() as f64;
    let m = xs.iter().sum::<f64>() / n;
    let var = xs.iter().map(|x| (x - m).powi(2)).sum::<f64>() / (n - 1.0);
    (m, (var / n).sqrt())
}

fn n_pairs(n: usize) -> usize { n * (n - 1) / 2 } // unordered pairs, n(n - 1)/2

fn join(v: &[f64]) -> String { v.iter().map(|x| format!("{:.4}", x)).collect::<Vec<_>>().join(", ") }

fn main() {
    let pairs = n_pairs(N);
    let lam = (N - 1) as f64 * P; // average friends per person
    // ---- road 1: the formulas ----
    let (bin_d, poi_d) = (binom_pmf(N - 1, P), poisson_pmf(lam, N - 1));
    let (e_edges, sd_edges) = (pairs as f64 * P, (pairs as f64 * P * (1.0 - P)).sqrt());
    let e_loners = N as f64 * bin_d[0]; // each friendless with chance (1-p)^(n-1)
    let triples = N * (N - 1) * (N - 2) / 6;
    let e_tri = triples as f64 * P.powf(3.0);
    println!("people {}, chance per pair {}, pairs C({},2) = {}", N, P, N, pairs);
    println!("expected friendships {:.1}, standard deviation {:.4}", e_edges, sd_edges);
    println!("friends per person ~ Binomial({}, {}): mean {:.3}, variance {:.6}", N - 1, P, lam, lam * (1.0 - P));
    println!("expected people with no friends {:.4}; expected triangles {} x {}^3 = {:.6}", e_loners, triples, P, e_tri);
    let (dist, bound) = (tv(&bin_d, &poi_d), (N - 1) as f64 * P * (1.0 - (-P).exp()));
    println!("gap between Binomial and Poisson laws {:.6}; coupling bound {:.6}; (n-1)p^2 = {:.6}", dist, bound, (N - 1) as f64 * P * P);
    // ---- road 2: a 4-person network with p = 0.3, all 2^6 = 64 outcomes ----
    let pairs4: Vec<(usize, usize)> = (0..4).flat_map(|i| (i + 1..4).map(move |j| (i, j))).collect();
    let (mut e4, mut deg0) = (0.0f64, vec![0.0f64; 4]);
    for mask in 0..64u32 {
        let on: Vec<(usize, usize)> = (0..6).filter(|b| mask >> b & 1 == 1).map(|b| pairs4[b]).collect();
        let w = 0.3f64.powf(on.len() as f64) * 0.7f64.powf((6 - on.len()) as f64);
        e4 += w * on.len() as f64;
        deg0[on.iter().filter(|e| e.0 == 0 || e.1 == 0).count()] += w;
    }
    let b4 = binom_pmf(3, 0.3);
    println!("4 people, p = 0.3, enumerated: expected friendships {:.6}, formula C(4,2)p = {:.6}", e4, n_pairs(4) as f64 * 0.3);
    println!("  person 1's friend count, enumerated: {}", join(&deg0));
    println!("  Binomial(3, 0.3) formula:            {}", join(&b4));
    // ---- road 3: 40 networks, each pair tossed on its own coin ----
    let mut rng = SplitMix(20260929);
    let t = (P * 2f64.powi(64)) as u64; // a draw below t has chance P
    let g = 40;
    let (mut edges_s, mut loners_s, mut tri_s, mut hist) = (vec![], vec![], vec![], vec![0usize; 1000]);
    for _ in 0..g {
        let mut nbr: Vec<Vec<usize>> = vec![vec![]; N];
        let mut adj = vec![vec![false; N]; N];
        for i in 0..N {
            for j in i + 1..N {
                if rng.next() < t {
                    nbr[i].push(j);
                    nbr[j].push(i);
                    adj[i][j] = true;
                    adj[j][i] = true;
                }
            }
        }
        let deg: Vec<usize> = nbr.iter().map(|a| a.len()).collect();
        edges_s.push((deg.iter().sum::<usize>() / 2) as f64);
        loners_s.push(deg.iter().filter(|&&d| d == 0).count() as f64);
        for &d in &deg { hist[d] += 1 }
        let mut tri = 0usize;
        for i in 0..N {
            for &j in nbr[i].iter().filter(|&&j| j > i) { tri += nbr[i].iter().filter(|&&w| adj[j][w]).count() }
        }
        tri_s.push((tri / 3) as f64);
    }
    let ((me, se), (ml, sl), (mt, st)) = (mean_se(&edges_s), mean_se(&loners_s), mean_se(&tri_s));
    println!("simulated, {} networks: friendships {:.2} +/- {:.2} (formula {:.1})", g, me, se, e_edges);
    println!("  friends per person {:.4} +/- {:.4} (formula {:.3})", 2.0 * me / N as f64, 2.0 * se / N as f64, lam);
    println!("  people with no friends {:.2} +/- {:.2} (formula {:.2})", ml, sl, e_loners);
    let most = (0..1000).filter(|&k| hist[k] > 0).max().unwrap();
    println!("  triangles {:.3} +/- {:.3} (formula {:.3}); most friends seen {}", mt, st, e_tri, most);
    println!("k, Binomial, Poisson, simulated share +/- se");
    let (mut ok, mut shares) = (true, vec![]);
    for k in 0..11 {
        let f = hist[k] as f64 / (g * N) as f64;
        shares.push(f);
        let sf = (bin_d[k] * (1.0 - bin_d[k]) / (g * N) as f64).sqrt(); // se if the law is right
        ok = ok && (f - bin_d[k]).abs() < 4.0 * sf + 1e-12;
        println!("{}, {:.4}, {:.4}, {:.4} +/- {:.4}", k, bin_d[k], poi_d[k], f, sf);
    }
    let two = |v: &[f64]| v.iter().map(|x| format!("{:.2}", x)).collect::<Vec<_>>().join(" ");
    println!("chart, to 2 places, Poisson {}; simulated {}", two(&poi_d[..11]), two(&shares));
    // ---- what breaks ----
    println!("mistake 1, n^2 p counts ordered pairs and self-pairs: {:.1}, not {:.1}", (N * N) as f64 * P, e_edges);
    println!("mistake 2, n x average friends, not halved: {:.1} friendships, not {:.1}", N as f64 * lam, e_edges);
    let mut dep = vec![0.0f64; N]; // one coin decides every pair at once
    dep[0] = 1.0 - P;
    dep[N - 1] = P;
    let dep_mean: f64 = dep.iter().enumerate().map(|(k, x)| k as f64 * x).sum();
    println!("mistake 3, one coin for all pairs: mean friends {:.3}, chance of none {:.4} (own coins: {:.4})", dep_mean, dep[0], bin_d[0]);
    let (mut e4dep, mut none_dep) = (0.0f64, 0.0f64); // 4 people, one shared coin: all 6 pairs or none
    for (on, w) in [(&pairs4[..0], 0.7), (&pairs4[..], 0.3)] {
        e4dep += w * on.len() as f64;
        if on.iter().filter(|e| e.0 == 0 || e.1 == 0).count() == 0 { none_dep += w }
    }
    println!("  same, 4 people enumerated: friendships {:.6} (own coins {:.6}), person 1 has none {:.4} (own coins {:.4})", e4dep, e4, none_dep, deg0[0]);
    let (b11, p11) = (binom_pmf(10, 0.3), poisson_pmf(3.0, 10));
    println!("mistake 4, 11 people at p = 0.3: chance of no friends {:.4}, Poisson says {:.4}; gap {:.4}",
             b11[0], p11[0], tv(&b11, &p11) + 0.5 * (1.0 - p11.iter().sum::<f64>()));
    // ---- the picture: 8 people, p = 0.3, one draw (seed 8) ----
    let (mut rng8, t8) = (SplitMix(8), (0.3 * 2f64.powi(64)) as u64);
    let pi2 = 2.0 * std::f64::consts::PI;
    let pts: Vec<String> = (0..8).map(|i| {
        let a = pi2 * i as f64 / 8.0;
        format!("({:.1},{:.1})", 180.0 + 90.0 * a.sin(), 120.0 - 90.0 * a.cos())
    }).collect();
    let (mut fig_edges, mut counts) = (vec![], vec![0; 8]);
    for i in 0..8 {
        for j in i + 1..8 {
            if rng8.next() < t8 { fig_edges.push(format!("{}-{}", i + 1, j + 1)); counts[i] += 1; counts[j] += 1 }
        }
    }
    println!("figure, people at {}", pts.join(" "));
    println!("figure, friendships {}; {} of 28, expected 8.4", fig_edges.join(" "), fig_edges.len());
    println!("figure, friend counts {}", counts.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "));
    assert!((e4 - n_pairs(4) as f64 * 0.3).abs() < 1e-12 && deg0.iter().zip(&b4).all(|(x, y)| (x - y).abs() < 1e-12));
    assert!((me - e_edges).abs() < 4.0 * se && (ml - e_loners).abs() < 4.0 * sl && (mt - e_tri).abs() < 4.0 * st);
    assert!(ok); // every share within 4 standard errors
    assert!(dist < bound); // the coupling bound holds
    assert!((e4dep - e4).abs() < 1e-12 && none_dep > deg0[0] + 0.3); // average kept, law changed
    println!("ALL CHECKS PASS");
}
