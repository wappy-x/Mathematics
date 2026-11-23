// Colouring the plane -- the same check as the Python, in Rust.  No crates.
// Road 1: every colouring of the Moser spindle tried (3^7 = 2,187 of them).
// Road 2: the same counts by deletion-contraction, which never lists one.
// Road 3: the 7-colouring by hexagons: its two distances by formula and by
// measuring the polygons, then tested on random unit pairs (SplitMix64).
use std::collections::BTreeSet;

type Q4 = [i64; 4]; // a + b*sqrt3 + c*sqrt11 + d*sqrt33, held as four integers

fn mul(x: Q4, y: Q4) -> Q4 {
    let ([a, b, c, d], [e, f, g, h]) = (x, y);
    [a * e + 3 * b * f + 11 * c * g + 33 * d * h, a * f + b * e + 11 * c * h + 11 * d * g,
     a * g + c * e + 3 * b * h + 3 * d * f, a * h + d * e + b * g + c * f]
}

fn val(x: Q4) -> f64 {
    (x[0] as f64 + x[1] as f64 * 3f64.sqrt() + x[2] as f64 * 11f64.sqrt() + x[3] as f64 * 33f64.sqrt()) / 12.0
}

// The spindle, every coordinate multiplied by 12 so all are whole combinations.
const PTS: [(Q4, Q4); 7] = [([0, 0, 0, 0], [0, 0, 0, 0]), ([0, 1, 3, 0], [-3, 0, 0, 1]),
    ([0, -1, 3, 0], [-3, 0, 0, -1]), ([0, 0, 6, 0], [-6, 0, 0, 0]),
    ([0, 1, 3, 0], [3, 0, 0, -1]), ([0, -1, 3, 0], [3, 0, 0, 1]),
    ([0, 0, 6, 0], [6, 0, 0, 0])];
const NAMES: [&str; 7] = ["A", "B", "C", "D", "E", "F", "G"];

fn dist2(p: (Q4, Q4), q: (Q4, Q4)) -> Q4 {
    let (dx, dy): (Q4, Q4) = ([0, 1, 2, 3].map(|k| p.0[k] - q.0[k]), [0, 1, 2, 3].map(|k| p.1[k] - q.1[k]));
    let (u, v) = (mul(dx, dx), mul(dy, dy));
    [0, 1, 2, 3].map(|k| u[k] + v[k])
}

fn brute(n: u32, es: &[(usize, usize)], k: usize) -> usize {   // road 1: list them all
    (0..k.pow(n)).filter(|&code| {
        let col: Vec<usize> = (0..n).map(|i| code / k.pow(i) % k).collect();
        es.iter().all(|&(u, v)| col[u] != col[v])
    }).count()
}

fn dc(n: u32, es: &[(usize, usize)], k: i64) -> i64 {         // road 2: P(G) = P(G-e) - P(G/e)
    if es.is_empty() { return k.pow(n) }
    let ((u, v), rest) = (es[0], &es[1..]);
    let merged: Vec<(usize, usize)> = rest.iter()
        .map(|&(a, b)| (if a == v { u } else { a }, if b == v { u } else { b }))
        .filter(|&(a, b)| a != b).map(|(a, b)| (a.min(b), a.max(b)))
        .collect::<BTreeSet<_>>().into_iter().collect();
    dc(n, rest, k) - dc(n - 1, &merged, k)
}

fn clique(es: &[(usize, usize)]) -> usize {                     // largest all-joined set
    let mut best = 0;
    for m in 0..(1usize << 7) {
        let vs: Vec<usize> = (0..7).filter(|i| m >> i & 1 == 1).collect();
        let ok = vs.iter().all(|&a| vs.iter().all(|&b| a >= b || es.contains(&(a, b))));
        if ok { best = best.max(vs.len()) }
    }
    best
}

fn centre(a: i64, b: i64, s: f64) -> (f64, f64) {
    (3f64.sqrt() * s * (a as f64 + b as f64 / 2.0), 1.5 * s * b as f64)
}

fn hexagon(a: i64, b: i64, s: f64) -> Vec<(f64, f64)> {
    let h = 3f64.sqrt() / 2.0;
    let corners = [(h, 0.5), (0.0, 1.0), (-h, 0.5), (-h, -0.5), (0.0, -1.0), (h, -0.5)];
    let (cx, cy) = centre(a, b, s);
    corners.iter().map(|&(x, y)| (cx + s * x, cy + s * y)).collect()
}

fn seg(p: (f64, f64), a: (f64, f64), b: (f64, f64)) -> f64 {    // point to segment distance
    let (vx, vy, wx, wy) = (b.0 - a.0, b.1 - a.1, p.0 - a.0, p.1 - a.1);
    let t = 0f64.max(1f64.min((vx * wx + vy * wy) / (vx * vx + vy * vy)));
    ((wx - t * vx) * (wx - t * vx) + (wy - t * vy) * (wy - t * vy)).sqrt()
}

fn gap(s: f64) -> f64 {                                         // measured, polygon to polygon
    let (h0, mut best) = (hexagon(0, 0, s), 9.0f64);
    for a in -5..6i64 {
        for b in -5..6i64 {
            if (a + 3 * b).rem_euclid(7) == 0 && (a, b) != (0, 0) {
                let h = hexagon(a, b, s);
                for (p_, q_) in [(&h0, &h), (&h, &h0)] {
                    for &p in p_.iter() {
                        for i in 0..6 { best = best.min(seg(p, q_[i], q_[(i + 1) % 6])) }
                    }
                }
            }
        }
    }
    best
}

fn colour(x: f64, y: f64, s: f64) -> i64 {                      // colour of the nearest centre
    let b0 = (y / (1.5 * s)).floor() as i64;
    let a0 = (x / (3f64.sqrt() * s) - b0 as f64 / 2.0).floor() as i64;
    let (mut best, mut col) = (9e9f64, -1i64);
    for a in a0 - 1..a0 + 3 {
        for b in b0 - 1..b0 + 3 {
            let (cx, cy) = centre(a, b, s); let d = (x - cx) * (x - cx) + (y - cy) * (y - cy);
            if d < best { best = d; col = (a + 3 * b).rem_euclid(7) }
        }
    }
    col
}

fn unit_pairs(s: f64, n: usize, seed: u64) -> usize {          // same-coloured pairs at distance 1
    let (mut st, mut bad) = (seed, 0);
    let mut nxt = || {
        st = st.wrapping_add(0x9E3779B97F4A7C15);
        let mut z = (st ^ (st >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
        z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
        ((z ^ (z >> 31)) >> 11) as f64
    };
    let t53 = 9007199254740992.0;
    for _ in 0..n {
        let (x, y) = (20.0 * nxt() / t53, 20.0 * nxt() / t53);
        let (dx, dy, r) = loop {
            let (dx, dy) = (2.0 * nxt() / t53 - 1.0, 2.0 * nxt() / t53 - 1.0);
            let r = (dx * dx + dy * dy).sqrt();
            if 0.0 < r && r <= 1.0 { break (dx, dy, r) }
        };
        if colour(x, y, s) == colour(x + dx / r, y + dy / r, s) { bad += 1 }
    }
    bad
}

fn main() {
    let pairs: Vec<(usize, usize)> = (0..7).flat_map(|i| (i + 1..7).map(move |j| (i, j))).collect();
    let edges: Vec<(usize, usize)> =
        pairs.iter().copied().filter(|&(i, j)| dist2(PTS[i], PTS[j]) == [144, 0, 0, 0]).collect();
    let cut: Vec<(usize, usize)> = edges.iter().copied().filter(|&e| e != (3, 6)).collect();
    let names = |es: &[(usize, usize)]| es.iter().map(|&(i, j)| format!("{}{}", NAMES[i], NAMES[j])).collect::<Vec<_>>().join(" ");
    println!("Moser spindle: 7 points, unit pairs found by exact arithmetic: {} of {}", edges.len(), pairs.len());
    println!("edges: {}", names(&edges));
    let fig: Vec<String> = PTS.iter().enumerate().map(|(i, p)| format!("{} ({:.4}, {:.4})", NAMES[i], val(p.0), val(p.1))).collect();
    println!("figure, {}", fig.join(", "));
    println!("largest all-joined set: {} points", clique(&edges));
    let (b3, d3, b4, d4) = (brute(7, &edges, 3), dc(7, &edges, 3), brute(7, &edges, 4), dc(7, &edges, 4));
    println!("proper 3-colourings: {} of {} by listing, {} by deletion-contraction", b3, 3i64.pow(7), d3);
    println!("proper 4-colourings: {} of {} by listing, {} by deletion-contraction", b4, 4i64.pow(7), d4);
    let (c3, c4) = (brute(7, &cut, 3), brute(7, &cut, 4));
    let hand: Vec<i64> = [3i64, 4].iter().map(|&k| k * (k - 1).pow(2) * (k - 2).pow(4)).collect();
    println!("without edge DG: {} 3-colourings, {} 4-colourings; k(k-1)^2(k-2)^4 at 3 and 4: {}, {}",
             c3, c4, hand[0], hand[1]);
    let same = (0..3usize.pow(7)).filter(|&code| {
        let col: Vec<usize> = (0..7).map(|i| code / 3usize.pow(i) % 3).collect();
        cut.iter().all(|&(u, v)| col[u] != col[v]) && col[0] == col[3] && col[3] == col[6]
    }).count();
    println!("of those 3-colourings, A, D and G share one colour in {}", same);
    for s in [0.4, 0.55, 0.35] {
        println!("hexagons of side {}: widest inside one {:.4}; nearest same colour {:.4} measured, {:.4} by sqrt(7) x side",
                 s, 2.0 * s, gap(s), 7f64.sqrt() * s);
    }
    let nb: Vec<i64> = [(1, 0), (-1, 0), (0, 1), (0, -1), (1, -1), (-1, 1)].iter().map(|&(a, b): &(i64, i64)| (a + 3 * b).rem_euclid(7)).collect();
    let d12 = { let (cx, cy) = centre(1, 2, 0.4); (cx * cx + cy * cy).sqrt() };  // nearest same-colour centre
    println!("colours of the 6 neighbours of colour 0: {:?}; nearest colour-0 centre (1, 2), {:.4} away at side 0.4", nb, d12);
    println!("side must lie between 1/sqrt(7) = {:.4} and 1/2 = 0.5000", 1.0 / 7f64.sqrt());
    let tests: Vec<(f64, usize)> = [0.4, 0.55, 0.35].iter().map(|&s| (s, unit_pairs(s, 100000, 2026))).collect();
    for &(s, bad) in &tests { println!("side {}: 100000 random unit pairs, same-coloured pairs {}", s, bad) }
    println!("quoted, not checked here: de Grey 2018 graph 1581 points; Heule 2018 graph 553 points; Parts 2020 graph 509 points");
    assert!(edges.len() == 11 && clique(&edges) == 3);
    assert!(b3 == 0 && d3 == 0 && b4 as i64 == d4 && d4 > 0);                // two roads agree
    assert!(vec![c3 as i64, c4 as i64] == vec![dc(7, &cut, 3), dc(7, &cut, 4)] && vec![c3 as i64, c4 as i64] == hand && same == c3);
    assert!((gap(0.4) - 7f64.sqrt() * 0.4).abs() < 1e-12 && gap(0.35) < 1.0 && 1.0 < gap(0.4));
    let mut sorted = nb.clone(); sorted.sort();
    assert!(sorted == (1..7).collect::<Vec<i64>>() && (d12 - 21f64.sqrt() * 0.4).abs() < 1e-12);
    assert!(tests[0].1 == 0 && tests[1].1 > 0 && tests[2].1 > 0);
    println!("ALL CHECKS PASS");
}
