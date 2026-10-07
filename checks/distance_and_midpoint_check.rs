// Distance and midpoint -- the same check as the Python, in Rust.  No crates.
// Van grid in km, depot at (0, 0), drops A (3, 4) and B (8, 1).  In space, a
// cable in metres from (1, 2, 0) to (4, 6, 12).  Roads: the formula, the square
// on the segment by corner coordinates, the depot's dot products, a search.

fn root(x: f64) -> f64 {                          // square root by Newton: average guess and x / guess
    let mut r = x.max(1.0);
    for _ in 0..80 { r = (r + x / r) / 2.0 }
    r
}

fn sq(a: &[f64], b: &[f64]) -> f64 {              // road one: square each change and add
    a.iter().zip(b).map(|(p, q)| (q - p) * (q - p)).sum()
}

fn dot(a: &[i64], b: &[i64]) -> i64 { a.iter().zip(b).map(|(p, q)| p * q).sum() }

fn shoelace(p: &[(i64, i64)]) -> f64 {            // area of a polygon from its corners
    let s: i64 = (0..p.len()).map(|j| { let ((x, y), (u, v)) = (p[j], p[(j + 1) % p.len()]); x * v - y * u }).sum();
    s.abs() as f64 / 2.0
}

fn search_mid(a: &[f64], b: &[f64]) -> Vec<f64> { // walk along the segment until equally far
    let (mut lo, mut hi, mut t) = (0.0, 1.0, 0.0);
    for _ in 0..100 {
        t = (lo + hi) / 2.0;
        let p: Vec<f64> = a.iter().zip(b).map(|(x, y)| x + t * (y - x)).collect();
        if sq(a, &p) < sq(&p, b) { lo = t } else { hi = t }
    }
    a.iter().zip(b).map(|(x, y)| ((x + t * (y - x)) * 1e9).round() / 1e9 + 0.0).collect()
}

fn tup(v: &[i64]) -> String { format!("({})", v.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ")) }

fn main() {
    for (a, b) in [(vec![3i64, 4], vec![8i64, 1]), (vec![1, 2, 0], vec![4, 6, 12])] {
        let (af, bf): (Vec<f64>, Vec<f64>) = (a.iter().map(|&x| x as f64).collect(), b.iter().map(|&x| x as f64).collect());
        let ch: Vec<i64> = a.iter().zip(&b).map(|(p, q)| q - p).collect();
        let (s, d) = (sq(&af, &bf), root(sq(&af, &bf)));
        let m: Vec<f64> = af.iter().zip(&bf).map(|(p, q)| (p + q) / 2.0).collect();
        let road2 = dot(&a, &a) + dot(&b, &b) - 2 * dot(&a, &b);
        let (am, mb) = (root(sq(&af, &m)), root(sq(&m, &bf)));
        let back: Vec<f64> = m.iter().zip(&af).map(|(x, p)| 2.0 * x - p).collect();
        println!("{} to {}: changes {:?}, squares {:?}, sum {}, distance {:.10}",
                 tup(&a), tup(&b), ch, ch.iter().map(|c| c * c).collect::<Vec<_>>(), s, d);
        println!("  depot road: {} + {} - 2 x {} = {}", dot(&a, &a), dot(&b, &b), dot(&a, &b), road2);
        println!("  midpoint by averaging {:?}; by searching the segment {:?}", m, search_mid(&af, &bf));
        println!("  halves {:.10} + {:.10} = {:.10}; 2M - A = {:?}", am, mb, am + mb, back);
        assert!(s == road2 as f64);                                     // two roads to the square
        assert!(m == search_mid(&af, &bf));                             // two roads to the midpoint
        assert!((am - mb).abs() < 1e-12 && (am + mb - root(road2 as f64)).abs() < 1e-12);
    }
    let w = (3i64, 5i64);                                               // the change (5, -3) turned a quarter turn
    let tilt = vec![(3i64, 4i64), (8, 1), (8 + w.0, 1 + w.1), (3 + w.0, 4 + w.1)];
    println!("square on AB, corners {:?}: area by corners {:.0}; box 8 x 8 - 4 x 7.5 = {}", tilt, shoelace(&tilt), 64 - 30);
    assert!(shoelace(&tilt) == sq(&[3.0, 4.0], &[8.0, 1.0]));           // the square Pythagoras names
    println!("depot to A {:.10}, depot to B {:.10}; floor diagonal {:.10}; corner ({}, {})", root(25.0), root(65.0), root(9.0 + 16.0), [8, 1][0], [3, 4][1]);
    println!("mistakes: add the legs 5 + 3 = {}; stop before the root {}; halve the change ({:?}, {:?})",
             5 + 3, 5 * 5 + 3 * 3, (8.0 - 3.0) / 2.0, (1.0 - 4.0) / 2.0);
    println!("try: shifted by (10, -7) to ({}, {}) and ({}, {}) distance {:.10}; B moved to (9, 12) gives {:.10}", 3 + 10, 4 - 7, 8 + 10, 1 - 7,
             root(sq(&[13.0, -3.0], &[18.0, -6.0])), root(sq(&[3.0, 4.0], &[9.0, 12.0])));
    let (k, ox, oy) = (30.0, 40.0, 190.0);                              // figure: 1 km = 30 units, y points down
    let px = |x: f64, y: f64| format!("({:.0}, {:.0})", ox + k * x, oy - k * y);
    println!("figure, 1 km = {}: depot {} A {} B {} M {} corner {}",
             k, px(0.0, 0.0), px(3.0, 4.0), px(8.0, 1.0), px(5.5, 2.5), px(8.0, 4.0));
    println!("figure, marker {} {} {}; axes to {} {}", px(7.0 + 2.0 / 3.0, 4.0), px(7.0 + 2.0 / 3.0, 3.0 + 2.0 / 3.0),
             px(8.0, 3.0 + 2.0 / 3.0), px(10.0, 0.0), px(0.0, 5.0));
    let r = root(150.0 * 150.0 + 90.0 * 90.0);
    let n = (-90.0 * 6.0 / r, 150.0 * 6.0 / r);                         // tick half-length 6
    for c in [(167.5, 92.5), (242.5, 137.5)] {
        println!("figure, tick ({:.1}, {:.1}) ({:.1}, {:.1})", c.0 + n.0, c.1 + n.1, c.0 - n.0, c.1 - n.1);
    }
    println!("ALL CHECKS PASS");
}
