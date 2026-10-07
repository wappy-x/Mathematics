// The chromatic polynomial -- the same check as the Python, in Rust.  No crates.  Rooms are dots, a shared wall is a line,
// and a colouring is proper when no wall carries the same colour on both sides.  Four roads to every count: try all q^n
// colourings, run the deletion-contraction recursion on coefficients, add and subtract over sets of walls, the closed forms.
type G = (usize, Vec<(usize, usize)>);
fn ring(n: usize) -> G { (n, (0..n).map(|i| (i, (i + 1) % n)).collect()) }
fn path(n: usize) -> G { (n, (0..n - 1).map(|i| (i, i + 1)).collect()) }
fn brute(g: &G, q: i64) -> i64 {                 // road 1: try every one of the q^n colourings
    let (n, edges) = g;
    (0..q.pow(*n as u32)).filter(|c| edges.iter().all(|(u, v)| c / q.pow(*u as u32) % q != c / q.pow(*v as u32) % q)).count() as i64
}
fn contract(g: &G, e: (usize, usize)) -> G {     // fuse a wall's two ends into one dot
    let ((n, edges), (u, v)) = (g, e);
    let to = |x: usize| { let y = if x == v { u } else { x }; if y > v { y - 1 } else { y } };
    let mut fused: Vec<(usize, usize)> = edges.iter().map(|(a, b)| (to(*a), to(*b))).filter(|(a, b)| a != b).map(|(a, b)| (a.min(b), a.max(b))).collect();
    fused.sort(); fused.dedup();
    (n - 1, fused)
}
fn chrom(g: &G) -> Vec<i64> {                    // road 2: deletion minus contraction
    let (n, edges) = g;
    if edges.is_empty() { let mut p = vec![0; *n]; p.push(1); return p }  // no walls: q^n, rooms free
    let (keep, mut gone) = (chrom(&(*n, edges[1..].to_vec())), chrom(&contract(g, edges[0])));
    gone.resize(keep.len(), 0);  keep.iter().zip(gone).map(|(a, b)| a - b).collect()
}
fn at(p: &[i64], q: i64) -> i64 { p.iter().enumerate().map(|(i, a)| a * q.pow(i as u32)).sum() }
fn pieces(n: usize, edges: &[(usize, usize)]) -> i64 {   // separate pieces a set of walls leaves
    let mut home: Vec<usize> = (0..n).collect();
    for _ in 0..n { for (a, b) in edges { let m = home[*a].min(home[*b]); home[*a] = m; home[*b] = m } }
    home.sort(); home.dedup(); home.len() as i64
}
fn by_sets(g: &G, q: i64) -> i64 {               // road 3: add and subtract over sets of walls
    let (n, edges) = g;
    (0..1usize << edges.len()).map(|m| {
        let s: Vec<(usize, usize)> = edges.iter().enumerate().filter(|(i, _)| m >> i & 1 == 1).map(|(_, e)| *e).collect();
        if s.len() % 2 == 0 { q.pow(pieces(*n, &s) as u32) } else { -q.pow(pieces(*n, &s) as u32) }
    }).sum()
}
fn chi(g: &G) -> i64 { (1..9).find(|&q| brute(g, q) > 0).unwrap() }
fn show(p: &[i64]) -> String {                   // coefficients into q^4 - 4q^3 + 6q^2 - 3q
    let mut bits: Vec<String> = p.iter().enumerate().filter(|(_, a)| **a != 0).map(|(i, a)| {
        let mag = if a.abs() == 1 && i > 0 { String::new() } else { a.abs().to_string() };
        format!("{} {}{}", if *a < 0 { "-" } else { "+" }, mag, if i > 1 { format!("q^{}", i) } else if i == 1 { "q".to_string() } else { String::new() })
    }).collect();
    bits.reverse();
    bits.join(" ").trim_start_matches("+ ").to_string()
}
fn main() {
    let (row, rg, tri, path3) = (path(4), ring(4), ring(3), path(3));
    let mut he = rg.1.clone(); he.push((1, 3));   // a hatch makes rooms 2 and 4 neighbours as well
    let (hatch, qs, q): (G, Vec<i64>, i64) = ((4, he), (0..6).collect(), 3);
    let (hatch_closed, gs) = (q * (q - 1) * (q - 2).pow(2), [&row, &rg, &tri, &hatch]);
    let chis: Vec<i64> = gs.iter().map(|g| chi(g)).collect();
    let poly_chis: Vec<i64> = gs.iter().map(|g| (1..9).find(|&x| at(&chrom(g), x) > 0).unwrap()).collect();
    println!("the row: {} rooms, {} shared walls;  the ring: {} rooms, {} walls;  the triangle: {} rooms, {} walls", row.0, row.1.len(), rg.0, rg.1.len(), tri.0, tri.1.len());
    let tab: Vec<(&str, Vec<i64>)> = vec![("colours q", qs.clone()),
        ("row, every colouring tried", qs.iter().map(|&x| brute(&row, x)).collect()),
        ("row, q(q-1)^3", qs.iter().map(|&x| x * (x - 1).pow(3)).collect()),
        ("ring, every colouring tried", qs.iter().map(|&x| brute(&rg, x)).collect()),
        ("ring, deletion minus contraction", qs.iter().map(|&x| at(&chrom(&rg), x)).collect()),
        ("ring, add and subtract over wall sets", qs.iter().map(|&x| by_sets(&rg, x)).collect()),
        ("ring, (q-1)^4 + (q-1)", qs.iter().map(|&x| (x - 1).pow(4) + (x - 1)).collect()),
        ("triangle, every colouring tried", qs.iter().map(|&x| brute(&tri, x)).collect())];
    for (lab, vals) in &tab { println!("{:<37}{}", lab, vals.iter().map(|v| format!("{:>5}", v)).collect::<String>()) }
    println!("the ring's polynomial, by recursion: {}", show(&chrom(&rg)));
    println!("{} colours: row {} = ring {} + triangle {}", q, brute(&row, q), brute(&rg, q), brute(&tri, q));
    println!("fewest colours that work, by search {:?}, off the polynomial {:?}", chis, poly_chis);
    println!("a hatch between rooms 2 and 4, {} colours: ring {} - path {} = {}, and q(q-1)(q-2)^2 = {}",
             q, brute(&rg, q), brute(&path3, q), brute(&hatch, q), hatch_closed);
    println!("rings of 3, 4 and 5 rooms: {} colours give {:?}, 2 colours give {:?}", q,
             [3, 4, 5].map(|n| brute(&ring(n), q)), [3, 4, 5].map(|n| brute(&ring(n), 2)));
    println!("mistake 1, the wall between rooms 4 and 1 ignored: {}, not {}", brute(&row, q), brute(&rg, q));
    println!("mistake 2, the recurrence read with a plus: {} + {} = {}, above the {} with no wall there at all",
             brute(&row, q), brute(&tri, q), brute(&row, q) + brute(&tri, q), brute(&row, q));
    println!("mistake 3, the contraction's count alone: {}, the colourings where 4 and 1 match", brute(&tri, q));
    assert!(tab[3].1 == tab[4].1 && tab[4].1 == tab[5].1 && tab[5].1 == tab[6].1);
    assert!(tab[1].1 == tab[2].1 && tab[1].1 == qs.iter().map(|&x| by_sets(&row, x)).collect::<Vec<i64>>());
    assert!(brute(&row, q) == brute(&rg, q) + brute(&tri, q) && chrom(&rg) == vec![0, -3, 6, -4, 1]);
    assert!(brute(&hatch, q) == brute(&rg, q) - brute(&path3, q) && brute(&hatch, q) == hatch_closed && chis == vec![2, 2, 3, 3] && poly_chis == chis);
    println!("ALL CHECKS PASS");
}
