// Runge-Kutta and Butcher tableaux -- the same check as the Python, in Rust.  No crates;
// tanh, cosh and ln feed the closed form, nothing else.
// Rocket while the motor burns (illustrative): H' = v, v' = 40 - 0.004 v^2, from rest.
type Tab = (Vec<f64>, Vec<Vec<f64>>, Vec<f64>);   // (c, A, b): one explicit Runge-Kutta method
type F = dyn Fn(f64, &[f64]) -> Vec<f64>;
fn sci(x: f64) -> String { format!("{:.2e}", x) }
fn rocket(_t: f64, s: &[f64]) -> Vec<f64> { vec![s[1], 40.0 - 0.004 * s[1] * s[1]] }
fn exact(t: f64) -> [f64; 2] { [250.0 * (0.4 * t).cosh().ln(), 100.0 * (0.4 * t).tanh()] }
fn step(tab: &Tab, f: &F, t: f64, s: &[f64], h: f64) -> (Vec<f64>, Vec<Vec<f64>>) {
    let (c, a, b) = tab; let mut ks: Vec<Vec<f64>> = vec![];
    for i in 0..b.len() {                       // one explicit step, read off a tableau (c, A, b)
        let y: Vec<f64> = (0..s.len()).map(|m| s[m] + h * (0..i).fold(0.0, |p, j| p + a[i][j] * ks[j][m])).collect();
        ks.push(f(t + c[i] * h, &y));
    }
    ((0..s.len()).map(|m| s[m] + h * (0..b.len()).fold(0.0, |p, i| p + b[i] * ks[i][m])).collect(), ks)
}
fn run(tab: &Tab, f: &F, s0: &[f64], h: f64, n: usize) -> Vec<f64> {
    let mut s = s0.to_vec();
    for i in 0..n { s = step(tab, f, i as f64 * h, &s, h).0; }
    s
}
fn three_stage(c2: f64, c3: f64) -> Tab {        // Step 4: solve the four order-3 conditions
    let b2 = (2.0 - 3.0 * c3) / (6.0 * c2 * (c2 - c3)) + 0.0; let b3 = (2.0 - 3.0 * c2) / (6.0 * c3 * (c3 - c2));
    let a32 = 1.0 / (6.0 * b3 * c2);
    (vec![0.0, c2, c3], vec![vec![], vec![c2], vec![c3 - a32, a32]], vec![1.0 - b2 - b3, b2, b3])
}
fn t(c: &[f64], a: &[&[f64]], b: &[f64]) -> Tab { (c.to_vec(), a.iter().map(|r| r.to_vec()).collect(), b.to_vec()) }
fn forests(m: usize, start: usize, pool: &[(usize, Vec<usize>)]) -> Vec<Vec<usize>> {
    if m == 0 { return vec![vec![]]; }               // multisets of trees from pool, total m nodes
    let mut out = vec![];
    for i in start..pool.len() {
        if pool[i].0 <= m { for mut rest in forests(m - pool[i].0, i, pool) { rest.insert(0, i); out.push(rest); } }
    }
    out
}
fn main() {
    let tabs: Vec<(&str, Tab)> = vec![
        ("Euler", t(&[0.0], &[&[]], &[1.0])), ("midpoint", t(&[0.0, 0.5], &[&[], &[0.5]], &[0.0, 1.0])),
        ("Heun", t(&[0.0, 1.0], &[&[], &[1.0]], &[0.5, 0.5])), ("Kutta3", three_stage(0.5, 1.0)),
        ("Heun3", three_stage(1.0 / 3.0, 2.0 / 3.0)),
        ("RK4", t(&[0.0, 0.5, 0.5, 1.0], &[&[], &[0.5], &[0.0, 0.5], &[0.0, 0.0, 1.0]], &[1.0 / 6.0, 1.0 / 3.0, 1.0 / 3.0, 1.0 / 6.0])),
        ("equal-b", t(&[0.0, 0.5, 1.0], &[&[], &[0.5], &[-1.0, 2.0]], &[1.0 / 3.0, 1.0 / 3.0, 1.0 / 3.0])),
        ("a32=1", t(&[0.0, 0.5, 1.0], &[&[], &[0.5], &[0.0, 1.0]], &[1.0 / 6.0, 2.0 / 3.0, 1.0 / 6.0]))];
    let get = |nm: &str| tabs.iter().find(|p| p.0 == nm).unwrap().1.clone();
    let h = 0.1; let rk4 = get("RK4");
    let (s1, ks) = step(&rk4, &rocket, 0.0, &[0.0, 0.0], h);
    println!("rocket: H' = v, v' = 40 - 0.004 v^2, terminal speed {:.0} m/s; one step h = 0.1 s from rest", (40.0f64 / 0.004).sqrt());
    for (i, k) in ks.iter().enumerate() {
        println!("RK4 stage {}: c = {:.1}, height slope {:.9}, speed slope {:.9}", i + 1, rk4.0[i], k[0], k[1]);
    }
    let wsl: Vec<f64> = (0..2).map(|m| ks.iter().zip([1.0, 2.0, 2.0, 1.0]).fold(0.0, |p, (k, w)| p + w * k[m]) / 6.0).collect();
    println!("RK4 weighted slopes (1, 2, 2, 1)/6: height {:.9}, speed {:.9}", wsl[0], wsl[1]);
    let ex = exact(h);
    println!("exact after 0.1 s: height {:.9} m, speed {:.9} m/s", ex[0], ex[1]);
    let mut euler_h = 0.0;
    for (nm, tab) in &tabs {
        let s = step(tab, &rocket, 0.0, &[0.0, 0.0], h).0; let e = [ex[0] - s[0], ex[1] - s[1]];
        if *nm == "Euler" { euler_h = e[0]; }
        println!("{:<9}height {:.9} error {}, speed {:.9} error {}", nm, s[0], sci(e[0]), s[1], sci(e[1]));
    }
    assert!((s1[0] - ex[0]).abs() < 1e-8 && (s1[1] - ex[1]).abs() < 1e-6 && euler_h.abs() > 0.19);
    let (k3, h3) = (get("Kutta3"), get("Heun3"));
    for tb in [&k3, &h3] {                          // c2 and c3 read off the tableau itself
        println!("three-stage, c2 = {:.4}, c3 = {:.4}: b = {:.6} {:.6} {:.6} a31 = {:.6} a32 = {:.6}",
            tb.0[1], tb.0[2], tb.2[0], tb.2[1], tb.2[2], tb.1[2][0], tb.1[2][1]);
    }
    let got = [k3.2[0], k3.2[1], k3.2[2], k3.1[2][0], k3.1[2][1]];
    assert!(got.iter().zip([1.0 / 6.0, 2.0 / 3.0, 1.0 / 6.0, -1.0, 2.0]).all(|(p, q)| (p - q).abs() < 1e-15));
    // rooted trees: a tree is a multiset of child trees; trees[i] = (nodes, children indices)
    let mut trees: Vec<(usize, Vec<usize>)> = vec![(1, vec![])];
    for n in 2..7 { let pool = trees.clone(); for f in forests(n - 1, 0, &pool) { trees.push((n, f)); } }
    fn name(tr: &[(usize, Vec<usize>)], i: usize) -> String { format!("[{}]", tr[i].1.iter().map(|&j| name(tr, j)).collect::<String>()) }
    fn gamma(tr: &[(usize, Vec<usize>)], i: usize) -> usize { tr[i].0 * tr[i].1.iter().map(|&j| gamma(tr, j)).product::<usize>() }
    let counts: Vec<usize> = (1..7).map(|n| trees.iter().filter(|t| t.0 == n).count()).collect();
    let cum: Vec<String> = (1..7).map(|p| counts[..p].iter().sum::<usize>().to_string()).collect();
    println!("rooted trees with 1..6 nodes: {} ; conditions for order 1..6: {}",
        counts.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" "), cum.join(" "));
    assert!(counts == vec![1, 1, 2, 4, 9, 20]);
    for i in 0..8 { println!("tree {}: {:<10} nodes {}, gamma {}", i + 1, name(&trees, i), trees[i].0, gamma(&trees, i)); }
    let misses = |tab: &Tab| -> Vec<f64> {          // b . Phi(tree) - 1/gamma(tree), every tree
        let (_, a, b) = tab; let s = b.len(); let mut phi: Vec<Vec<f64>> = vec![];
        for tr in &trees {
            let row: Vec<f64> = (0..s).map(|i| tr.1.iter().fold(1.0, |p, &k| p * (0..i).fold(0.0, |q, j| q + a[i][j] * phi[k][j]))).collect();
            phi.push(row);
        }
        phi.iter().enumerate().map(|(k, p)| (0..s).fold(0.0, |q, i| q + b[i] * p[i]) - 1.0 / gamma(&trees, k) as f64).collect()
    };
    let order = |tab: &Tab| -> usize {
        misses(tab).iter().enumerate().filter(|(_, m)| m.abs() > 1e-12).map(|(k, _)| trees[k].0 - 1).min().unwrap_or(6)
    };
    let orders: Vec<usize> = tabs.iter().map(|(_, tb)| order(tb)).collect();
    println!("order from the trees: {}", tabs.iter().zip(&orders).map(|((nm, _), p)| format!("{} {}", nm, p)).collect::<Vec<_>>().join(", "));
    assert!(orders == vec![1, 2, 2, 3, 3, 4, 2, 2]);
    let m5 = misses(&rk4)[8..17].to_vec();
    let big = m5.iter().fold(0.0f64, |p, &m| if m.abs() > p.abs() { m } else { p });
    println!("RK4 on the 9 five-node trees: {} missed, largest miss {}", m5.iter().filter(|m| m.abs() > 1e-12).count(), sci(big));
    println!("stages s = 1..6, free numbers s(s+1)/2: {}", (1..7).map(|s| (s * (s + 1) / 2).to_string()).collect::<Vec<_>>().join(" "));
    let gm = |s: &str| gamma(&trees, (0..trees.len()).find(|&i| name(&trees, i) == s).unwrap());
    let (ga, gb) = (gm("[[[[]]]]"), gm("[[][[[]]]]"));
    println!("five-stage barrier: sum b_i (1 - c_i) a_ij a_jk c_k must be 1/{} - 1/{} = 1/{}", ga, gb, ga * gb / (gb - ga));
    assert!(ga * gb == 120 * (gb - ga));
    let b7 = t(&[0.0, 1.0 / 3.0, 2.0 / 3.0, 1.0 / 3.0, 0.5, 0.5, 1.0], &[&[], &[1.0 / 3.0], &[0.0, 2.0 / 3.0],   // Butcher's
        &[1.0 / 12.0, 1.0 / 3.0, -1.0 / 12.0], &[-1.0 / 16.0, 9.0 / 8.0, -3.0 / 16.0, -3.0 / 8.0],                // 7 stages
        &[0.0, 9.0 / 8.0, -3.0 / 8.0, -3.0 / 4.0, 0.5], &[9.0 / 44.0, -9.0 / 11.0, 63.0 / 44.0, 18.0 / 11.0, 0.0, -16.0 / 11.0]],
        &[11.0 / 120.0, 0.0, 27.0 / 40.0, 27.0 / 40.0, -4.0 / 15.0, -4.0 / 15.0, 11.0 / 120.0]);
    println!("Butcher's seven stages: order {} from the trees, {} conditions met with {} free numbers", order(&b7), counts.iter().sum::<usize>(), 7 * 8 / 2);
    assert!(order(&b7) == 6);
    println!("exact at t = 2 s: height {:.6} m, speed {:.6} m/s", exact(2.0)[0], exact(2.0)[1]);
    println!("burn to t = 2 s, speed error (true error) at h = 0.2, 0.1, 0.05 s; slope readings at h = 0.05; observed order");
    let ex2 = exact(2.0)[1];
    for nm in ["Euler", "Heun", "Kutta3", "RK4", "equal-b", "a32=1"] {
        let tb = get(nm); let p = orders[tabs.iter().position(|q| q.0 == nm).unwrap()];
        let e: Vec<f64> = [0.2, 0.1, 0.05].iter().map(|&hh: &f64| ex2 - run(&tb, &rocket, &[0.0, 0.0], hh, (2.0 / hh).round() as usize)[1]).collect();
        let obs: Vec<f64> = (0..2).map(|i| (e[i] / e[i + 1]).abs().log2()).collect();
        println!("{:<8}{} {} {}  readings {}  order {:.2} {:.2}", nm, sci(e[0]), sci(e[1]), sci(e[2]), 40 * tb.2.len(), obs[0], obs[1]);
        assert!((obs[1] - p as f64).abs() < 0.15);    // the run agrees with the tree count
    }
    let clock = |t: f64, _s: &[f64]| vec![3.0 * t * t];   // y' = 3t^2, y(1) = 1: depends on t only
    let wrongc: Tab = (vec![0.0, 0.5, 0.5], k3.1.clone(), k3.2.clone());   // Kutta3 with c3 copied wrong
    for (nm, tb) in [("Kutta3", &k3), ("Kutta3, c3 = 1/2", &wrongc)] {
        println!("y' = 3t^2 to t = 1, h = 0.1, {}: y(1) = {:.9}", nm, run(tb, &clock, &[0.0], 0.1, 10)[0]);
    }
    assert!((run(&k3, &clock, &[0.0], 0.1, 10)[0] - 1.0).abs() < 1e-14 && (run(&wrongc, &clock, &[0.0], 0.1, 10)[0] - 1.0).abs() > 0.01);
    let gap = (run(&k3, &rocket, &[0.0, 0.0], 0.1, 20)[0] - run(&wrongc, &rocket, &[0.0, 0.0], 0.1, 20)[0]).abs();
    println!("same Kutta3 rows on the rocket, h = 0.1: heights agree to {}", sci(gap));
    fn draw(tr: &[(usize, Vec<usize>)], i: usize, mut x: f64, y: f64, out: &mut Vec<(f64, f64)>) -> (f64, f64) {
        if tr[i].1.is_empty() { out.push((x, y)); return (x + 22.0, x); }   // figure: leaves 22 apart, levels 26 up
        let k = out.len(); out.push((0.0, 0.0)); let mut xs = vec![];
        for &j in &tr[i].1 { let (nx, cx) = draw(tr, j, x, y - 26.0, out); x = nx; xs.push(cx); }
        out[k] = ((xs[0] + xs[xs.len() - 1]) / 2.0, y); (x, out[k].0)
    }
    for i in 0..8 {
        let mut pts = vec![]; draw(&trees, i, 45.0 + 90.0 * (i % 4) as f64, 90.0 + 120.0 * (i / 4) as f64, &mut pts);
        println!("figure, tree {}: {}", i + 1, pts.iter().map(|(px, py)| format!("{:.0},{:.0}", px, py)).collect::<Vec<_>>().join(" "));
    }
    println!("ALL CHECKS PASS");
}
