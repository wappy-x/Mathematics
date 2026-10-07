// Why some graphs cannot be drawn flat -- the same check as the Python, in Rust.  No crates.  Road one
// is the Euler ceiling: a flat drawing of a simple graph on three dots or more holds at most 3V - 6
// lines, and at most 2V - 4 when no three dots form a ring of three.  Road two never counts lines: it
// tries every cyclic order of lines round every dot, walks each order to count the regions, and a
// flat drawing is one whose regions reach E - V + 2.
use std::collections::BTreeSet;
type Edges = Vec<(usize, usize)>;
fn complete(n: usize) -> Edges { (0..n).flat_map(|u| (u + 1..n).map(move |v| (u, v))).collect() }
fn utilities(a: usize, b: usize) -> Edges { (0..a).flat_map(|u| (0..b).map(move |v| (u, a + v))).collect() }
fn adj(n: usize, es: &Edges) -> Vec<Vec<usize>> {
    (0..n).map(|u| es.iter().filter(|e| e.0 == u || e.1 == u).map(|e| if e.0 == u { e.1 } else { e.0 }).collect()).collect()
}
fn degrees(n: usize, es: &Edges) -> Vec<usize> { let mut d: Vec<usize> = adj(n, es).iter().map(|ns| ns.len()).collect(); d.sort(); d }
fn perms(xs: &[usize]) -> Vec<Vec<usize>> {
    if xs.is_empty() { return vec![vec![]] }
    (0..xs.len()).flat_map(|i| { let mut r = xs.to_vec(); let x = r.remove(i);
        perms(&r).into_iter().map(move |p| { let mut o = vec![x]; o.extend(p); o }).collect::<Vec<_>>() }).collect()
}
fn ring_free(n: usize, es: &Edges) -> bool {         // no three dots joined in a ring of three
    let a = adj(n, es); !es.iter().any(|&(u, v)| a[u].iter().any(|w| a[v].contains(w)))
}
fn trace(rot: &[Vec<usize>]) -> Vec<usize> {         // one closed walk of the orders is one region
    let mut darts: Vec<(usize, usize)> = rot.iter().enumerate().flat_map(|(u, ns)| ns.iter().map(move |&v| (u, v))).collect();
    darts.sort(); let (mut used, mut faces): (BTreeSet<(usize, usize)>, Vec<usize>) = (BTreeSet::new(), Vec::new());
    for &start in &darts {
        if used.contains(&start) { continue }
        let ((mut u, mut v), mut sides) = (start, 0);
        while (u, v) != start || sides == 0 {
            used.insert((u, v)); sides += 1; let i = rot[v].iter().position(|&w| w == u).unwrap();
            (u, v) = (v, rot[v][if i == 0 { rot[v].len() - 1 } else { i - 1 }]);
        }
        faces.push(sides);
    }
    faces.sort(); faces
}
fn hunt(n: usize, es: &Edges) -> (u64, Vec<usize>) { // road two: every cyclic order round every dot
    let choices: Vec<Vec<Vec<usize>>> = adj(n, es).iter().map(|ns| perms(&ns[1..]).into_iter()
        .map(|p| { let mut o = vec![ns[0]]; o.extend(p); o }).collect()).collect();
    let total: u64 = choices.iter().map(|c| c.len() as u64).product();
    let mut best: Vec<usize> = Vec::new();
    for k in 0..total {
        let mut m = k;
        let rot: Vec<Vec<usize>> = choices.iter().map(|c| { let o = c[(m % c.len() as u64) as usize].clone(); m /= c.len() as u64; o }).collect();
        let f = trace(&rot);
        if f.len() > best.len() { best = f }
    }
    (total, best)
}
fn main() {
    let ring: Edges = (0..5).map(|i| (i, (i + 1) % 5)).collect();            // a pentagon of five dots
    let k5e: Edges = complete(5).into_iter().filter(|&e| e != (3, 4)).collect();
    let pet: Edges = ring.iter().copied().chain((0..5).map(|i| (5 + i, 5 + (i + 2) % 5))).chain((0..5).map(|i| (i, 5 + i))).collect();
    let ico: Edges = ring.iter().copied().chain((0..5).map(|i| (5 + i, 5 + (i + 1) % 5))).chain((0..5).map(|i| (10, i)))
        .chain((0..5).map(|i| (11, 5 + i))).chain((0..5).map(|i| (i, 5 + i))).chain((0..5).map(|i| (i, 5 + (i + 1) % 5))).collect();
    let graphs: Vec<(&str, usize, Edges)> = vec![("K(3,3), the utilities", 6, utilities(3, 3)),
        ("K(5)", 5, complete(5)), ("K(5) minus one line", 5, k5e.clone()), ("Petersen", 10, pet)];
    println!("{:<22}{:>3}{:>4}{:>6}{:>6}{:>7}{:>8}{:>8}{:>8}{:>7}", "graph", "V", "E", "3V-6", "2V-4", "over?", "orders", "best F", "target", "flat?");
    let mut rows: Vec<(usize, usize, bool, u64, Vec<usize>, usize)> = Vec::new();
    for (name, n, es) in &graphs {
        let (n, e) = (*n, es.len()); let (c3, c4, free) = (3 * n - 6, 2 * n - 4, ring_free(n, es));
        let (total, best) = hunt(n, es); let (over, target) = (e > c3 || (free && e > c4), e - n + 2);
        println!("{:<22}{:>3}{:>4}{:>6}{:>6}{:>7}{:>8}{:>8}{:>8}{:>7}", name, n, e, c3, if free { c4.to_string() } else { "-".to_string() }, if over { "yes" } else { "no" }, total, best.len(), target, if best.len() == target { "yes" } else { "no" });
        rows.push((n, e, over, total, best, target));
    }
    let ((hv, he), flat, pet_r) = ((6usize, 9usize), &rows[2], &rows[3]);
    println!("the three houses: dots {}, pipes wanted {}, regions if it could be drawn {}, pipe-sides {}, sides the regions need {}", hv, he, he - hv + 2, 2 * he, 4 * (he - hv + 2));
    println!("no ring of three, so the ceiling is 2 x {} - 4 = {}: {} pipes is one too many", hv, 2 * hv - 4, he);
    println!("the drawing found for K(5) minus one line: {} regions, sides {}, adding to 2E = {}", flat.4.len(), flat.4.iter().map(|s| s.to_string()).collect::<Vec<String>>().join(" "), flat.4.iter().sum::<usize>());
    println!("a dot of small degree: the degrees add to 2E, so a flat drawing averages under 6");
    println!("  K(5) minus one line: V = {}, E = {}, average degree {:.2}, degrees {:?}", flat.0, flat.1, 2.0 * flat.1 as f64 / flat.0 as f64, degrees(5, &k5e));
    println!("  icosahedron: V = 12, E = {} = 3V - 6 = {}, average degree {:.2}, every degree {}, regions {}", ico.len(), 3 * 12 - 6, 2.0 * ico.len() as f64 / 12.0, degrees(12, &ico)[0], ico.len() - 12 + 2);
    println!("mistake 1, the ring-of-three ceiling on the utilities: {} <= {} says it fits, and the right ceiling is {}", he, 3 * hv - 6, 2 * hv - 4);
    println!("mistake 2, the ceiling read as permission: Petersen {} <= {} and <= {}, yet {} orders reach only {} regions, not {}", pet_r.1, 3 * 10 - 6, 2 * 10 - 4, pet_r.3, pet_r.4.len(), pet_r.5);
    println!("mistake 3, the ceiling on two dots and one line: 1 > 3 x 2 - 6 = {} calls one line impossible", 3 * 2 - 6);
    assert!(rows.iter().map(|r| r.4.len()).collect::<Vec<usize>>() == vec![3, 5, 6, 5] && rows.iter().map(|r| r.3).collect::<Vec<u64>>() == vec![64, 7776, 864, 1024]);
    assert!(rows.iter().map(|r| r.2).collect::<Vec<bool>>() == vec![true, true, false, false]);   // silent on Petersen
    assert!(rows.iter().map(|r| r.4.len() == r.5).collect::<Vec<bool>>() == vec![false, false, true, false]);
    assert!(flat.4.iter().sum::<usize>() == 2 * flat.1 && *flat.4.iter().min().unwrap() >= 3 && degrees(12, &ico) == vec![5; 12]);
    println!("ALL CHECKS PASS");
}
