// PageRank by power iteration: one pass over the links per step, dangling pages
// folded into the jump, a stopping rule that certifies the ranking, at two sizes.
const A: f64 = 0.85; // the damping factor, alpha
const NAMES: [&str; 6] = ["Home", "Map", "Prices", "Join", "Help", "Terms"];

fn step(x: &[f64], links: &[Vec<usize>], a: f64, fold: bool) -> Vec<f64> {
    let (n, mut dang) = (x.len(), 0.0);
    let mut y = vec![0.0; n];
    for i in 0..n {
        if links[i].is_empty() { dang += x[i]; continue; } // rank parked on a dangling page
        let share = a * x[i] / links[i].len() as f64;
        for &j in &links[i] { y[j] += share; }
    }
    let extra = ((if fold { a * dang } else { 0.0 }) + (1.0 - a)) / n as f64;
    y.iter().map(|v| v + extra).collect()
}
fn l1(x: &[f64], y: &[f64]) -> f64 { x.iter().zip(y).fold(0.0, |s, (p, q)| s + (p - q).abs()) }
fn f4(x: &[f64]) -> String { x.iter().map(|v| format!("{:.4}", v)).collect::<Vec<_>>().join(" ") }
fn iterate(links: &[Vec<usize>], a: f64, passes: usize, x0: Option<Vec<f64>>, fold: bool) -> Vec<f64> {
    let mut x = x0.unwrap_or(vec![1.0 / links.len() as f64; links.len()]);
    for _ in 0..passes { x = step(&x, links, a, fold); }
    x
}
fn order(x: &[f64]) -> Vec<usize> {
    let mut idx: Vec<usize> = (0..x.len()).collect();
    idx.sort_by(|&i, &j| x[j].partial_cmp(&x[i]).unwrap());
    idx
}
fn min_gap(x: &[f64]) -> f64 {
    let o = order(x);
    (0..x.len() - 1).map(|i| x[o[i]] - x[o[i + 1]]).fold(f64::INFINITY, f64::min)
}
fn certify(links: &[Vec<usize>], a: f64) -> (String, String) { // stop when bound < smallest gap
    let (mut x, mut k, cap) = (vec![1.0 / links.len() as f64; links.len()], 0, 300);
    while k < cap {
        let xn = step(&x, links, a, true);
        let bound = a / (1.0 - a) * l1(&xn, &x);
        x = xn; k += 1;
        if bound < min_gap(&x) {
            let names: Vec<&str> = order(&x).iter().map(|&i| NAMES[i]).collect();
            return (k.to_string(), names.join(" > "));
        }
    }
    ("none by".to_string(), format!("pass {}: {}", cap, f4(&x))) // a tie is never certified
}
fn solve(links: &[Vec<usize>], a: f64) -> Vec<f64> { // road 2: Gaussian elimination
    let n = links.len();
    let mut m: Vec<Vec<f64>> = (0..n).map(|i| {
        let mut r: Vec<f64> = (0..n).map(|j| if i == j { 1.0 } else { 0.0 }).collect();
        r.push((1.0 - a) / n as f64); r }).collect();
    for i in 0..n {
        let out: Vec<usize> = if links[i].is_empty() { (0..n).collect() } else { links[i].clone() };
        for &j in &out { m[j][i] -= a / out.len() as f64; }
    }
    for c in 0..n {
        let mut p = c;
        for r in c..n { if m[r][c].abs() > m[p][c].abs() { p = r; } }
        m.swap(c, p);
        for r in (0..n).filter(|&r| r != c) {
            let (f, rowc) = (m[r][c] / m[c][c], m[c].clone());
            for (u, v) in m[r].iter_mut().zip(&rowc) { *u = *u - f * v; }
        }
    }
    (0..n).map(|i| m[i][n] / m[i][i]).collect()
}
fn splitmix(s: u64) -> (u64, u64) { // SplitMix64, written out
    let s = s.wrapping_add(0x9E3779B97F4A7C15);
    let z = (s ^ (s >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    (s, (z ^ (z >> 31)) >> 11) // 53 random bits
}
fn main() {
    let links: Vec<Vec<usize>> = vec![vec![1, 2, 5], vec![0], vec![0, 3], vec![1, 4, 5], vec![0, 5], vec![]];
    let (n, pi) = (6, solve(&links, A));
    println!("page              {}", NAMES.iter().map(|s| format!("{:>6}", s)).collect::<Vec<_>>().join(" "));
    println!("pi, solved         {}  links {}", f4(&pi), links.iter().map(|l| l.len()).sum::<usize>());
    let inflow = 1.0 / 6.0 + 1.0 / 12.0 + 1.0 / 12.0; // Map, Prices, Help into Home
    println!("by hand, Home: links in {:.4}, x alpha {:.4}, Terms' share {:.4}, jump {:.4}, total {:.4}",
        inflow, A * inflow, A / 36.0, (1.0 - A) / 6.0, A * inflow + A / 36.0 + (1.0 - A) / 6.0);
    let (mut x, mut hist, e0) = (vec![1.0 / 6.0; n], Vec::new(), l1(&vec![1.0 / 6.0; n], &pi));
    println!("pass  0  {}  error {:.4}", f4(&x), e0);
    for k in 1..61 { // road 1: power iteration
        let xn = step(&x, &links, A, true);
        let (d, e) = (l1(&xn, &x), l1(&xn, &pi));
        assert!(e <= A / (1.0 - A) * d + 1e-15 && e <= A.powf(k as f64) * e0 + 1e-15); // the two promises
        hist.push((k, xn.clone(), d, e, A / (1.0 - A) * d, min_gap(&xn)));
        x = xn;
    }
    for (k, xn, d, e, b, g) in &hist[..12] {
        println!("pass {:2}  {}  change {:.4}  bound {:.4}  gap {:.4}  error {:.4}", k, f4(xn), d, b, g, e);
    }
    let (stop, ord) = certify(&links, A);
    let total12 = hist[11].1.iter().fold(0.0, |s, v| s + v);
    println!("certified at pass {}: {}, total {:.6}, alpha/(1-alpha) {:.2}", stop, ord, total12, A / (1.0 - A));
    println!("chart, error      {}", hist[..12].iter().map(|h| format!("{:.4}", h.3)).collect::<Vec<_>>().join(" "));
    println!("chart, 0.85^k e0  {}", hist[..12].iter().map(|h| format!("{:.4}", A.powf(h.0 as f64) * e0)).collect::<Vec<_>>().join(" "));
    let pu = iterate(&links, 1.0, 400, None, true); // same site with no damping
    let eu: Vec<f64> = [39, 40].iter().map(|&k| l1(&iterate(&links, 1.0, k, None, true), &pu)).collect();
    let (r_d, r_u) = (hist[39].3 / hist[38].3, eu[1] / eu[0]);
    println!("error shrink per pass: damped {:.4}, undamped {:.4}, ratio {:.4}", r_d, r_u, r_d / r_u);
    println!("no damping, limit  {}", f4(&pu));
    let (mut seed, mut page, mut visits) = (2026u64, 0usize, vec![0u64; n]); // road 3: a random surfer
    for _ in 0..1000000 {
        let (s1, u) = splitmix(seed);
        let (s2, v) = splitmix(s1);
        seed = s2;
        let out = &links[page];
        page = if !out.is_empty() && (u as f64) < A * 9007199254740992.0 {
            out[((v * out.len() as u64) >> 53) as usize] } else { ((v * n as u64) >> 53) as usize };
        visits[page] += 1;
    }
    let sim: Vec<f64> = visits.iter().map(|&c| c as f64 / 1000000.0).collect();
    println!("surfer, 1e6 clicks {}", f4(&sim));
    let y = iterate(&links, A, 12, None, false); // what breaks
    println!("wrong: Terms' rank dropped, 12 passes {}  total {:.4}", f4(&y), y.iter().fold(0.0, |s, v| s + v));
    let mut sl = links.clone(); sl[5] = vec![5];
    let z = iterate(&sl, A, 300, None, true);
    println!("wrong: Terms links to itself          {}", f4(&z));
    let lp = vec![vec![1], vec![0]];
    let w = vec![iterate(&lp, 1.0, 100, Some(vec![1.0, 0.0]), true), iterate(&lp, 1.0, 101, Some(vec![1.0, 0.0]), true),
                 iterate(&lp, A, 30, Some(vec![1.0, 0.0]), true)];
    for (lab, v) in ["no damping, pass 100", "no damping, pass 101", "alpha 0.85, pass 30"].iter().zip(&w) {
        println!("two-page loop, {} {}", lab, f4(v));
    }
    for a in [0.99, 0.5] {
        let (p, o) = certify(&links, a);
        println!("try: alpha {}, certified at pass {} {}", a, p, o);
    }
    for (lab, page, new) in [("Home drops Terms, certified at pass", 0, vec![1, 2]), ("Help drops Terms, certified", 4, vec![0])] {
        let mut l2 = links.clone(); l2[page] = new;
        let (p, o) = certify(&l2, A);
        println!("try: {} {} {}", lab, p, o);
    }
    let (nn, mut seed) = (5000usize, 7u64); // at scale: 5,000 people, synthetic
    let mut net: Vec<Vec<usize>> = Vec::new();
    for i in 0..nn {
        let (s, u) = splitmix(seed); seed = s;
        let mut fol: Vec<usize> = Vec::new();
        while (fol.len() as u64) < u % 21 { // follows 0 to 20 people
            let (s, v) = splitmix(seed); seed = s;
            let j = ((((v as u128 * v as u128) >> 53) * nn as u128) >> 53) as usize; // low numbers are more popular
            if j != i && !fol.contains(&j) { fol.push(j); }
        }
        net.push(fol);
    }
    let m: usize = net.iter().map(|f| f.len()).sum();
    println!("people {}  links {}  follow nobody {}", nn, m, net.iter().filter(|f| f.is_empty()).count());
    let refv = iterate(&net, A, 250, None, true);
    let mut x = vec![1.0 / nn as f64; nn];
    let (mut k, mut d, mut errs) = (0usize, 1.0, vec![l1(&x, &refv)]);
    while A / (1.0 - A) * d >= 1e-6 { // stop: guaranteed error < 1e-6
        let xn = step(&x, &net, A, true);
        d = l1(&xn, &x); x = xn; k += 1;
        errs.push(l1(&x, &refv));
    }
    let kp = (1..999).find(|&t| 2.0 * A.powf(t as f64) < 1e-6).unwrap();
    println!("per pass: link visits {}  full table {}", m + nn, nn * nn);
    println!("passes: {}  promised at most {}  total visits {}  full table {}", k, kp, k * (m + nn), k * nn * nn);
    println!("error shrink per pass, last: {:.4}", errs[k] / errs[k - 1]);
    let top: Vec<usize> = order(&x)[..3].to_vec();
    println!("top three people {} {} {} {}", top[0], top[1], top[2], top.iter().map(|&i| format!("{:.5}", x[i])).collect::<Vec<_>>().join(" "));
    assert!(hist[59].1.iter().zip(&pi).all(|(p, q)| (p - q).abs() < 1e-11)); // iteration = solve
    assert!(sim.iter().zip(&pi).all(|(p, q)| (p - q).abs() < 0.002)); // surfer = solve
    assert!((r_d / r_u - A).abs() < 1e-3); // damping scales the shrink by alpha
    assert!(stop == "12" && (total12 - 1.0).abs() < 1e-12);
    assert!(y.iter().sum::<f64>() < 0.9 && z[5] > 0.5 && l1(&w[0], &w[1]) > 1.99); // the three breaks
    assert!((0..k).all(|t| errs[t + 1] <= A * errs[t] + 1e-15) && k <= kp);
    println!("ALL CHECKS PASS");
}
