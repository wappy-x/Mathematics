// Euler characteristic -- the same check as the Python, in Rust.  No crates.
// A surface is a list of triangles, each a sorted triple of vertex numbers.
// Road 1 counts vertices, edges and triangles.  Road 2 adds up 6 minus each
// vertex's degree, which is 6 times chi on a closed surface of triangles.
// Road 3 cuts the dome and the tube up at random and recounts after every cut.
use std::collections::{BTreeMap, BTreeSet};
type T = [i64; 3];

fn tri(a: i64, b: i64, c: i64) -> T { let mut t = [a, b, c]; t.sort(); t }

fn edge_uses(tris: &[T]) -> BTreeMap<(i64, i64), i64> {   // how many triangles touch each edge
    let mut uses = BTreeMap::new();
    for t in tris {
        for e in [(t[0], t[1]), (t[0], t[2]), (t[1], t[2])] { *uses.entry(e).or_insert(0) += 1 }
    }
    uses
}

fn counts(tris: &[T]) -> (i64, i64, i64) {
    let verts: BTreeSet<i64> = tris.iter().flatten().copied().collect();
    (verts.len() as i64, edge_uses(tris).len() as i64, tris.len() as i64)
}

fn chi(tris: &[T]) -> i64 { let (v, e, f) = counts(tris); v - e + f }

fn degree_sum(tris: &[T]) -> (i64, Vec<i64>) {             // road 2: sum of (6 - degree)
    let mut deg: BTreeMap<i64, i64> = BTreeMap::new();
    for (a, b) in edge_uses(tris).keys() {
        *deg.entry(*a).or_insert(0) += 1;
        *deg.entry(*b).or_insert(0) += 1;
    }
    let mut d: Vec<i64> = deg.values().copied().collect(); d.sort();
    (d.iter().map(|x| 6 - x).sum(), d)
}

fn find(boss: &BTreeMap<i64, i64>, x: i64) -> i64 { if boss[&x] == x { x } else { find(boss, boss[&x]) } }

fn rim_loops(tris: &[T]) -> usize {                        // edges used once, joined into loops
    let rim: Vec<(i64, i64)> = edge_uses(tris).into_iter().filter(|e| e.1 == 1).map(|e| e.0).collect();
    let mut boss: BTreeMap<i64, i64> = BTreeMap::new();
    for &(a, b) in &rim { boss.insert(a, a); boss.insert(b, b); }
    for &(a, b) in &rim { let (ra, rb) = (find(&boss, a), find(&boss, b)); boss.insert(ra, rb); }
    boss.keys().map(|&v| find(&boss, v)).collect::<BTreeSet<i64>>().len()
}

fn is_surface(tris: &[T], closed: bool) -> bool {          // no repeats; each edge used once or twice
    let distinct: BTreeSet<T> = tris.iter().copied().collect();
    let ok = distinct.len() == tris.len() && tris.iter().all(|t| t[0] != t[1] && t[1] != t[2]);
    ok && edge_uses(tris).values().all(|&k| k == 2 || (k == 1 && !closed))
}

fn icosahedron() -> Vec<T> {                               // top 0, rings 1-5 and 6-10, bottom 11
    let (u, l) = (|i: i64| 1 + i % 5, |i: i64| 6 + i % 5);
    let mut out = vec![];
    for i in 0..5 {
        out.extend([tri(0, u(i), u(i + 1)), tri(u(i), u(i + 1), l(i)),
                    tri(u(i + 1), l(i), l(i + 1)), tri(11, l(i), l(i + 1))]);
    }
    out
}

fn split4(tris: &[T]) -> Vec<T> {                          // each triangle into four, at edge midpoints
    let mut mid: BTreeMap<(i64, i64), i64> = BTreeMap::new();
    let mut out = vec![];
    for t in tris {
        let mut m = |a: i64, b: i64| { let n = 12 + mid.len() as i64; *mid.entry((a, b)).or_insert(n) };
        let (a, b, c) = (t[0], t[1], t[2]);
        let (ab, ac, bc) = (m(a, b), m(a, c), m(b, c));
        out.extend([tri(a, ab, ac), tri(b, ab, bc), tri(c, ac, bc), tri(ab, ac, bc)]);
    }
    out
}

fn grid(cols: i64, rows: i64, glue_i: i64, glue_j: i64) -> Vec<T> {  // glue_i: 0 open, 1 straight, 2 half twist
    let name = |mut i: i64, mut j: i64| {
        if i == cols && glue_i != 0 { i = 0; if glue_i == 2 { j = rows - j } }
        if j == rows && glue_j != 0 { j = 0 }
        i * (rows + 1) + j
    };
    let mut out: Vec<[i64; 3]> = vec![];
    for i in 0..cols {
        for j in 0..rows {
            let (a, b, c, d) = (name(i, j), name(i + 1, j), name(i + 1, j + 1), name(i, j + 1));
            out.extend([[a, b, c], [a, d, c]]);
        }
    }
    let ids: Vec<i64> = out.iter().flatten().copied().collect::<BTreeSet<i64>>().into_iter().collect();
    let ix = |v: i64| ids.iter().position(|&w| w == v).unwrap() as i64;   // renumber the corners
    out.iter().map(|t| tri(ix(t[0]), ix(t[1]), ix(t[2]))).collect()
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn show(label: &str, t: &[T]) -> String { let (v, e, f) = counts(t); format!("{}: V {}, E {}, F {}, chi {}", label, v, e, f, v - e + f) }

fn rand(state: &mut u64) -> u64 {                          // SplitMix64, written out
    *state = state.wrapping_add(0x9E3779B97F4A7C15);
    let z = (*state ^ (*state >> 30)).wrapping_mul(0xBF58476D1CE4E5B9);
    let z = (z ^ (z >> 27)).wrapping_mul(0x94D049BB133111EB);
    z ^ (z >> 31)
}

fn cut_up(rng: &mut u64, start_tris: &[T], moves: usize) -> (Vec<T>, bool, [i64; 2]) {  // road 3
    let mut tris = start_tris.to_vec();
    let (mut new, mut ok, mut kinds, start) = (1 + tris.iter().map(|t| t[2]).max().unwrap(), true, [0, 0], chi(&tris));
    for _ in 0..moves {
        let (k, pick) = ((rand(rng) % tris.len() as u64) as usize, (rand(rng) % 4) as usize);
        let [a, b, c] = tris[k];
        if pick == 0 {                                     // a new corner inside triangle k
            tris[k] = tri(a, b, new);
            tris.extend([tri(a, c, new), tri(b, c, new)]);
        } else {                                           // a new corner on one edge of triangle k
            let (a, b, c) = [(a, b, c), (a, c, b), (b, c, a)][pick - 1];
            let k2 = (0..tris.len()).find(|&j| j != k && tris[j].contains(&a) && tris[j].contains(&b)).unwrap();
            let d = tris[k2].iter().sum::<i64>() - a - b;
            (tris[k], tris[k2]) = (tri(a, new, c), tri(a, new, d));
            tris.extend([tri(new, b, c), tri(new, b, d)]);
        }
        kinds[(pick != 0) as usize] += 1;
        new += 1;
        ok = ok && chi(&tris) == start && degree_sum(&tris).0 == 6 * start;
    }
    let ok = ok && is_surface(&tris, true); (tris, ok, kinds)
}

fn main() {
    let (dome, tube, flat, sleeve) = (split4(&icosahedron()), grid(3, 3, 1, 1), grid(3, 3, 0, 0), grid(3, 3, 1, 0));
    let (klein, lp, twist) = (grid(3, 3, 2, 1), grid(6, 1, 1, 0), grid(6, 1, 2, 0));
    let cut = tube[0];                                     // pretzel: two tubes, one triangle out of each
    let m = |v: i64| if cut.contains(&v) { v } else { v + 100 };
    let pretzel: Vec<T> = tube[1..].iter().copied().chain(tube[1..].iter().map(|t| tri(m(t[0]), m(t[1]), m(t[2])))).collect();
    let (ds, dd) = degree_sum(&dome);
    let cnt = |x: i64| dd.iter().filter(|&&d| d == x).count();
    println!("{}", show("icosahedron, before subdividing", &icosahedron()));
    println!("{}", show("dome, geodesic sphere", &dome));
    println!("dome degrees: {} corners of 5 struts, {} of 6; sum of (6 - degree) = {} = 6 x {}", cnt(5), cnt(6), ds, ds / 6);
    println!("{}; sum of (6 - degree) = {}", show("tube, 3 x 3 grid glued both ways", &tube), degree_sum(&tube).0);
    for (label, t) in [("flat square", &flat), ("glued left to right", &sleeve), ("glued top to bottom", &tube)] {
        println!("{}, rim loops {}", show(&format!("  {}", label), t), rim_loops(t));
    }
    println!("{}; sum of (6 - degree) = {}", show("pretzel, two tubes joined", &pretzel), degree_sum(&pretzel).0);
    println!("{}", show("klein bottle, one side flipped", &klein));
    println!("{}, rim loops {}", show("paper strip, plain loop", &lp), rim_loops(&lp));
    println!("{}, rim loops {}", show("paper strip, half twist", &twist), rim_loops(&twist));
    let closed = [&dome, &tube, &pretzel, &klein];
    let all_ok = closed.iter().all(|t| is_surface(t, true)) && [&flat, &sleeve, &lp, &twist].iter().all(|t| is_surface(t, false));
    println!("every model a surface of triangles, each edge on 1 or 2 of them: {}", yn(all_ok));
    let mut rng: u64 = 2026;
    println!("random cuts, SplitMix64 seed {}, 300 on each, chi recounted after every cut:", rng);
    let (d2, dok, dk) = cut_up(&mut rng, &dome, 300);
    let (t2, tok, tk) = cut_up(&mut rng, &tube, 300);
    println!("{}; unchanged every time: {}; edge cuts {}, face cuts {}", show("  dome", &d2), yn(dok), dk[1], dk[0]);
    println!("{}; unchanged every time: {}; edge cuts {}, face cuts {}", show("  tube", &t2), yn(tok), tk[1], tk[0]);
    let (v, f) = (counts(&dome).0, dome.len() as i64);
    println!("mistake 1, flat square left unglued: {}, not 0", chi(&flat));
    println!("mistake 2, struts counted once per panel: {} - {} + {} = {}", v, 3 * f, f, v - 3 * f + f);
    println!("mistake 3, one dome panel left out: {}, rim loops {}", chi(&dome[1..]), rim_loops(&dome[1..]));
    let coarse = grid(2, 2, 1, 1);
    println!("mistake 4, tube from a 2 x 2 grid: {}; a surface of triangles: {}", show("counted", &coarse), yn(is_surface(&coarse, true)));
    println!("figure, schematic: 3 x 3 squares, side 80, from (60, 40); left glued to right, bottom to top");
    assert!(closed.iter().map(|t| chi(t)).collect::<Vec<i64>>() == vec![2, 0, -2, 0]);       // road 1, by counting
    assert!(closed.iter().all(|t| degree_sum(t).0 == 6 * chi(t)));                            // road 2 agrees
    assert!(counts(&dome) == (42, 120, 80) && cnt(5) == 12 && counts(&tube) == (9, 27, 18));
    assert!(chi(&flat) == 1 && rim_loops(&lp) == 2 && rim_loops(&twist) == 1);
    assert!(all_ok && dok && tok && !is_surface(&coarse, true));
    println!("ALL CHECKS PASS");
}
