// Eight trees, one fence: monotone chain against gift wrapping.  No crates.
type Pt = (f64, f64);
const T: [(&str, Pt); 9] = [("A", (2.0, 0.0)), ("B", (14.0, 2.0)), ("C", (18.0, 10.0)), ("D", (12.0, 16.0)),
    ("E", (4.0, 14.0)), ("F", (0.0, 6.0)), ("G", (8.0, 6.0)), ("H", (11.0, 8.0)), ("I", (20.0, 4.0))];
fn tree(k: &str) -> Pt { T.iter().find(|t| t.0 == k).unwrap().1 }
fn name(p: Pt) -> &'static str { T.iter().find(|t| t.1 == p).unwrap().0 }
fn names(h: &[Pt]) -> String { h.iter().map(|&p| name(p)).collect::<Vec<_>>().join(" ") }
fn turn(a: Pt, b: Pt, c: Pt) -> f64 { (b.0 - a.0) * (c.1 - a.1) - (b.1 - a.1) * (c.0 - a.0) } // > 0: bends left
fn root(v: f64) -> f64 { (0..60).fold(v.max(1.0), |r, _| (r + v / r) / 2.0) } // square root by Newton's rule
fn chain(pts: &[Pt], log: &mut Vec<String>) -> Vec<Pt> { // one half of the monotone chain
    let mut h: Vec<Pt> = Vec::new();
    for &p in pts {
        while h.len() >= 2 && turn(h[h.len() - 2], h[h.len() - 1], p) <= 0.0 { // right turn or straight: drop
            log.push(format!("{} {}", name(h[h.len() - 1]), turn(h[h.len() - 2], h[h.len() - 1], p)));
            h.pop();
        }
        h.push(p);
    }
    h.pop();
    h
}
fn wrap(pts: &[Pt]) -> Vec<Pt> {                     // gift wrapping from the lowest leftmost tree
    let mut hull = vec![pts.iter().copied().fold(pts[0], |m, p| if p < m { p } else { m })];
    loop {
        let last = *hull.last().unwrap();
        let mut q = *pts.iter().find(|&&p| p != last).unwrap();
        for &r in pts { if turn(last, q, r) < 0.0 { q = r } } // r right of the string: swing to it
        if q == hull[0] { return hull }
        hull.push(q);
    }
}
fn area(h: &[Pt]) -> f64 { (0..h.len()).map(|i| turn((0.0, 0.0), h[(i + h.len() - 1) % h.len()], h[i])).sum::<f64>() / 2.0 }
fn fence(h: &[Pt]) -> f64 { (0..h.len()).map(|i| { let (a, b) = (h[(i + h.len() - 1) % h.len()], h[i]); root((b.0 - a.0).powi(2) + (b.1 - a.1).powi(2)) }).sum() }
fn inside(h: &[Pt], p: Pt) -> bool { (0..h.len()).all(|i| turn(h[(i + h.len() - 1) % h.len()], h[i], p) >= -1e-9) }
fn main() {
    let mut p: Vec<Pt> = T.iter().filter(|t| t.0 != "I").map(|t| t.1).collect();
    p.sort_by(|a, b| a.partial_cmp(b).unwrap());
    let rev: Vec<Pt> = p.iter().rev().copied().collect();
    let (mut low, mut up) = (Vec::new(), Vec::new());
    let (mono, gift) = ([chain(&p, &mut low), chain(&rev, &mut up)].concat(), wrap(&p));
    let mut brute: Vec<String> = Vec::new();
    for &a in &p { for &b in &p { if a != b && p.iter().all(|&r| turn(a, b, r) >= 0.0) { brute.push(format!("{}{}", name(a), name(b))) } } }
    brute.sort();
    let mut edges: Vec<String> = (0..mono.len()).map(|i| format!("{}{}", name(mono[(i + 5) % 6]), name(mono[i]))).collect();
    edges.sort();
    let cells = (0..360).flat_map(|i| (0..320).map(move |j| ((i as f64 + 0.5) / 20.0, (j as f64 + 0.5) / 20.0))).filter(|&q| inside(&mono, q)).count();
    let mut seg: Vec<Pt> = Vec::new();
    for &a in &p { for &b in &p { if a < b { for t in 1..10 { let t = t as f64;
        seg.push(((10.0 - t) * a.0 / 10.0 + t * b.0 / 10.0, (10.0 - t) * a.1 / 10.0 + t * b.1 / 10.0)) } } } }
    let [a, b, c, d, f, g, h] = ["A", "B", "C", "D", "F", "G", "H"].map(tree);
    let w = [turn(g, b, d) / turn(f, b, d), turn(f, g, d) / turn(f, b, d), turn(f, b, g) / turn(f, b, d)];
    let mix = (w[0] * f.0 + w[1] * b.0 + w[2] * d.0, w[0] * f.1 + w[1] * b.1 + w[2] * d.1);
    let dent: Vec<Pt> = "FAGBHCDE".chars().map(|k| tree(&k.to_string())).collect();
    let nine = wrap(&[p.clone(), vec![tree("I")]].concat());
    let tf = |x: bool| if x { "True" } else { "False" };
    println!("road one, monotone chain: {}\nroad two, gift wrapping: {}", names(&mono), names(&gift));
    println!("brute force, of {} ordered pairs, edges with every tree on the left: {}", p.len() * (p.len() - 1), brute.join(" "));
    println!("turns at the corners: {}", (0..6).map(|i| format!("{} {}", name(mono[i]), turn(mono[(i + 5) % 6], mono[i], mono[(i + 1) % 6]))).collect::<Vec<_>>().join(", ")
        + &format!("; dented fence at G {}, at H {}", turn(a, g, b), turn(b, h, c)));
    println!("lower sweep drops: {}; upper sweep drops: {}", low.join(", "), up.join(", "));
    println!("shoelace terms: {}; sum {:.0}", (1..7).map(|i| format!("{:.0}", turn((0.0, 0.0), mono[i - 1], mono[i % 6]))).collect::<Vec<_>>().join(", "), 2.0 * area(&mono));
    println!("edges: {}", (1..7).map(|i| format!("{}{} {:.3}", name(mono[i - 1]), name(mono[i % 6]), fence(&[mono[i - 1], mono[i % 6]]) / 2.0)).collect::<Vec<_>>().join(", "));
    println!("hull: {} corners, area {:.1} m^2, fence {:.3} m", mono.len(), area(&mono), fence(&mono));
    println!("fine grid, 0.05 m cells inside: {} = {:.2} m^2", cells, cells as f64 / 400.0);
    println!("segment rule: {} points on the 28 tree-to-tree segments, inside the hull: {}", seg.len(), seg.iter().filter(|&&q| inside(&mono, q)).count());
    println!("G as a mix of F, B, D: weights {:.4}, {:.4}, {:.4}; sum {:.4}; point ({:.1}, {:.1})", w[0], w[1], w[2], w.iter().sum::<f64>(), mix.0, mix.1);
    println!("midpoint of A and H (6.5, 4.0) in the notch A B G: {}", tf(inside(&[a, b, g], (6.5, 4.0))));
    println!("mistake, fence through all eight F A G B H C D E: area {:.1} m^2, fence {:.3} m", area(&dent), fence(&dent));
    println!("mistake, trees fenced left to right {}: area {:.1} m^2, fence {:.3} m", names(&p), area(&p), fence(&p));
    println!("ninth tree I at (20, 4): hull {}, area {:.1} m^2, fence {:.3} m", names(&nine), area(&nine), fence(&nine));
    println!("figure, 1 m = 12: {}", "ABCDEFGH".chars().map(|k| { let q = tree(&k.to_string()); format!("{} ({}, {})", k, 40.0 + 12.0 * q.0, 216.0 - 12.0 * q.1) }).collect::<Vec<_>>().join(" "));
    assert!(mono == gift);                                          // two sweeps, one fence
    assert!(brute == edges);                                        // every edge found by brute force
    assert!((cells as f64 / 400.0 - area(&mono)).abs() < 0.5);      // grid count against shoelace
    assert!(w.iter().all(|&x| x > 0.0) && (mix.0 - g.0).abs() < 1e-9 && (mix.1 - g.1).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
