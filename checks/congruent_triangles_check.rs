// Congruent triangles -- the check behind the card.  std only, no crates.
// A double gate, metres.  Left brace triangle: corner hole A, rail hole B,
// stile hole C.  The right leaf D, E, F is built by ASA and by RHS, then
// compared with the left leaf flipped over.  SSA and AAA are shown failing.
type P = (f64, f64);

fn dist(p: P, q: P) -> f64 {
    // the distance formula on the grid
    ((p.0 - q.0).powi(2) + (p.1 - q.1).powi(2)).sqrt()
}

fn bisect(f: &dyn Fn(f64) -> f64, mut lo: f64, mut hi: f64) -> f64 {
    // a root of f between lo and hi, by halving
    for _ in 0..200 {
        let mid = (lo + hi) / 2.0;
        if (f(lo) > 0.0) == (f(mid) > 0.0) { lo = mid } else { hi = mid }
    }
    (lo + hi) / 2.0
}

fn main() {
    let (a, b, c): (P, P, P) = ((0.0, 0.0), (1.5, 0.0), (0.0, 0.8));
    let (d, e): (P, P) = ((3.2, 0.0), (1.7, 0.0));
    let brace = dist(b, c);
    let dot = (b.0 - a.0) * (c.0 - a.0) + (b.1 - a.1) * (c.1 - a.1); // 0 means a square corner
    println!("left leaf: rail {:.3} stile {:.3} brace {:.3}, corner dot product {:.3}", dist(a, b), dist(a, c), brace, dot);
    println!("SAS right leaf, 1.500 and 0.800 at a square corner: brace {:.3}", dist(e, (d.0, 0.8)));
    // ASA: the bevel gauge copies the brace line, mirrored, and runs it to the right stile
    let u = (-(c.0 - b.0), c.1 - b.1);
    let t = (d.0 - e.0) / u.0;
    let f = (e.0 + t * u.0, e.1 + t * u.1);
    println!("ASA right leaf, bevel copy at rail hole: stile hole {:.3} up, brace {:.3}", f.1, dist(e, f));
    // rigid motion: turn the left leaf over about the gate's centre line
    let flip: Vec<P> = [a, b, c].iter().map(|p| (3.2 - p.0, p.1)).collect();
    let miss = flip.iter().zip([d, e, f].iter()).map(|(p, q)| dist(*p, *q)).fold(0.0, f64::max);
    println!("flipped left leaf vs ASA-built right leaf: largest hole miss {:.3}", miss);
    println!("SSS spacings right leaf: {:.3} {:.3} {:.3}", dist(d, e), dist(d, f), dist(e, f));
    let h = bisect(&|y| dist(e, (d.0, y)) - brace, 0.0, brace);
    println!("RHS search up the stile for a {:.3} brace: {:.3}", brace, h);
    assert!(miss < 1e-12);
    assert!((dist(e, f) - brace).abs() < 1e-12);
    assert!((h - dist(a, c)).abs() < 1e-9);
    // SSA: angle at B, rail BA = 1.5, stile hole 0.8 from A; brace length s unknown
    let w = ((c.0 - b.0) / brace, (c.1 - b.1) / brace);
    let p = (b.0 - a.0) * w.0 + (b.1 - a.1) * w.1;
    let q = dist(a, b).powi(2) - 0.8f64.powi(2); // s^2 + 2 p s + q = 0
    let roots = [-p - (p * p - q).sqrt(), -p + (p * p - q).sqrt()];
    println!("SSA quadratic: braces {:.3} and {:.3}", roots[1], roots[0]);
    println!("SSA gap from corner hole to brace line: {:.3}", (dist(a, b).powi(2) - p * p).sqrt());
    let g = |s: f64| dist(a, (b.0 + s * w.0, b.1 + s * w.1)) - 0.8;
    let scan: Vec<f64> = (0..300)
        .filter(|k| (g(*k as f64 / 100.0) > 0.0) != (g((*k + 1) as f64 / 100.0) > 0.0))
        .map(|k| bisect(&g, k as f64 / 100.0, (k + 1) as f64 / 100.0))
        .collect();
    println!("SSA brute-force scan: braces {:.3} and {:.3}", scan[1], scan[0]);
    assert!(roots.iter().zip(scan.iter()).all(|(x, y)| (x - y).abs() < 1e-9));
    let cs = (b.0 + scan[0] * w.0, b.1 + scan[0] * w.1);
    println!("SSA second stile hole: ({:.3}, {:.3}), {:.3} from corner", cs.0, cs.1, dist(a, cs));
    let small = [0.8 * dist(a, b), 0.8 * dist(a, c)]; // AAA: same angles, 0.8 size
    let sb = dist((small[0], 0.0), (0.0, small[1]));
    println!("AAA copy at 0.8 size: rail {:.3} stile {:.3} brace {:.3}", small[0], small[1], sb);
    println!("brace slope {:.3} vs {:.3}, brace short by {:.3}", small[1] / small[0], c.1 / b.0, brace - sb);
    println!("rail and stile swapped: rail hole misses by {:.3}", dist(a, b) - dist(a, c));
    let fig = |p: P| format!("{:.0},{:.0}", 20.0 + 100.0 * p.0, 200.0 - 100.0 * p.1);
    let pts = [("A", a), ("B", b), ("C", c), ("D", d), ("E", e), ("F", f)];
    let row: Vec<String> = pts.iter().map(|(n, p)| format!("{} {}", n, fig(*p))).collect();
    println!("figure, 100 units per m: {}", row.join(" "));
    let fig2 = |p: P| format!("{:.1},{:.1}", 60.0 + 150.0 * p.0, 200.0 - 150.0 * p.1);
    let pts2 = [("A", a), ("B", b), ("C", c), ("C*", cs)];
    let row2: Vec<String> = pts2.iter().map(|(n, p)| format!("{} {}", n, fig2(*p))).collect();
    println!("figure2, 150 units per m: {}", row2.join(" "));
    println!("ALL CHECKS PASS");
}
