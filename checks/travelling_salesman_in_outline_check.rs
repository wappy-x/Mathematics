// The travelling salesman -- the same check as the Python, in Rust.  No crates.  Six
// towns, A home, and the rep's mileage chart.  The cheapest tour is found twice over:
// by listing every order of the five towns after A, and by the set-by-set method,
// which keeps the cheapest way to reach each set of towns and end at each of them.
use std::collections::HashMap;
const NAMES: [char; 6] = ['A', 'B', 'C', 'D', 'E', 'F'];
const N: usize = 6;
const D: [[i64; 6]; 6] = [[0, 34, 42, 18, 28, 19], [34, 0, 28, 51, 26, 35], [42, 28, 0, 58, 14, 54],
                          [18, 51, 58, 0, 44, 25], [28, 26, 14, 44, 0, 42], [19, 35, 54, 25, 42, 0]];
fn orders(rest: &[usize]) -> Vec<Vec<usize>> {     // every order of the towns after home
    if rest.is_empty() { return vec![Vec::new()] }
    (0..rest.len()).flat_map(|i| { let mut left = rest.to_vec(); let x = left.remove(i);
        orders(&left).into_iter().map(move |t| { let mut r = vec![x]; r.extend(t); r }).collect::<Vec<Vec<usize>>>() }).collect()
}
fn cost(t: &[usize]) -> i64 { (0..N).map(|k| D[t[k]][t[(k + 1) % N]]).sum() }   // legs, plus the drive home
fn show(t: &[usize]) -> String { t.iter().map(|&c| NAMES[c].to_string()).collect::<Vec<String>>().join("-") + "-" + &NAMES[t[0]].to_string() }
fn fact(k: i64) -> i64 { if k < 2 { 1 } else { k * fact(k - 1) } }
fn fold(t: &[usize]) -> Vec<usize> {               // one name per tour: rotations, both directions
    (0..N).flat_map(|k| { let r: Vec<usize> = (0..N).map(|i| t[(k + i) % N]).collect();
        let mut b = r.clone(); b.reverse(); vec![r, b] }).min().unwrap()
}
fn nearest(start: usize) -> Vec<usize> {           // greed: drive to the nearest town not yet seen
    let mut seen = vec![start];
    while seen.len() < N {
        let last = *seen.last().unwrap();
        seen.push((0..N).filter(|v| !seen.contains(v)).map(|v| (D[last][v], v)).min().unwrap().1);
    }
    seen
}
fn main() {
    let tours: Vec<Vec<usize>> = orders(&(1..N).collect::<Vec<usize>>()).iter().map(|p| { let mut t = vec![0]; t.extend(p); t }).collect();
    let mut ranked: Vec<(i64, Vec<usize>)> = tours.iter().map(|t| (cost(t), t.clone())).collect();
    ranked.sort();                                 // road one: every order, costed
    let (best, worst) = (ranked[0].clone(), ranked[ranked.len() - 1].clone());
    let mut names: Vec<Vec<usize>> = tours.iter().map(|t| fold(t)).collect();
    names.sort(); names.dedup();
    let distinct = names.len() as i64;
    let sym = (0..N).all(|u| (0..N).all(|v| D[u][v] == D[v][u]));
    let tri = (0..N).all(|u| (0..N).all(|v| (0..N).all(|w| D[u][v] <= D[u][w] + D[w][v])));
    let mut paths: HashMap<(u32, usize), i64> = (1..N).map(|v| ((1u32 << (v - 1), v), D[0][v])).collect();   // second road: set by set
    for _ in 0..N - 2 {
        let mut grown = paths.clone();
        for (&(s, v), &c) in paths.iter() {
            for w in (1..N).filter(|w| s >> (w - 1) & 1 == 0) {
                let key = (s | 1 << (w - 1), w);
                if c + D[v][w] < *grown.get(&key).unwrap_or(&1_000_000_000) { grown.insert(key, c + D[v][w]); }
            }
        }
        paths = grown;
    }
    let setbest = (1..N).map(|v| paths[&((1u32 << (N - 1)) - 1, v)] + D[v][0]).min().unwrap();  // all five seen
    let (mut inn, mut legs, mut tree) = (vec![0usize], Vec::new(), 0);
    while inn.len() < N {                          // the cheapest connecting tree, grown from A
        let mut pick = (i64::MAX, 0usize, 0usize);
        for &u in inn.iter() { for v in 0..N { if !inn.contains(&v) && (D[u][v], u, v) < pick { pick = (D[u][v], u, v) } } }
        inn.push(pick.2); legs.push(format!("{}-{} {}", NAMES[pick.1], NAMES[pick.2], pick.0)); tree += pick.0;
    }
    let nnt = nearest(0);
    let (nnc, nns): (i64, Vec<i64>) = (cost(&nnt), (0..N).map(|s| cost(&nearest(s))).collect());
    let low = *nns.iter().min().unwrap();
    println!("six towns, A home; the rep's mileage chart in miles, rows and columns A to F:");
    for u in 0..N { println!("  {} {}", NAMES[u], (0..N).map(|v| format!("{:>4}", D[u][v])).collect::<Vec<String>>().join("")) }
    println!("chart symmetric: {}; no detour shorter than the direct road: {}", if sym { "yes" } else { "no" }, if tri { "yes" } else { "no" });
    println!("orders of the five towns after A: 5! = {}; tours (6-1)!/2 = {}; by folding rotations and reversals: {}", tours.len(), fact(N as i64 - 1) / 2, distinct);
    println!("cheapest tour, from all {} orders: {} = {} miles", tours.len(), show(&best.1), best.0);
    println!("the same cost from the set-by-set method: {} miles, kept in {} records", setbest, paths.len());
    println!("dearest tour: {} = {} miles", show(&worst.1), worst.0);
    println!("nearest neighbour from A: {} = {} miles, {:.2}% above {}", show(&nnt), nnc, (nnc - best.0) as f64 * 100.0 / best.0 as f64, best.0);
    println!("nearest neighbour restarted at each town A to F: {:?}; cheapest of the six {}, still above {}", nns, low, best.0);
    println!("cheapest connecting tree: {} = {} miles; the bracket {} <= {} <= {}", legs.join(", "), tree, tree, best.0, 2 * tree);
    println!("tours to check as towns are added: 6 -> {}, 7 -> {}, 10 -> {}, 15 -> {}, 20 -> {}", fact(5) / 2, fact(6) / 2, fact(9) / 2, fact(14) / 2, fact(19) / 2);
    println!("records the set-by-set method keeps: 6 towns {}, 20 towns {}", paths.len(), 19 * 2i64.pow(18));
    println!("mistake, every order of six towns counted as a tour: {} instead of {}", fact(N as i64), distinct);
    println!("mistake, stopping at the nearest-neighbour route: {} miles, {} more than {}; the tree read as a route: {} miles, {} short", nnc, nnc - best.0, best.0, tree, best.0 - tree);
    assert!(best.0 == setbest && setbest == 148 && worst.0 == 267);
    assert!(distinct == fact(N as i64 - 1) / 2 && tours.len() as i64 == fact(N as i64 - 1));
    assert!(sym && tri && tree < best.0 && best.0 <= 2 * tree);
    assert!(paths.len() as i64 == (N as i64 - 1) * 2i64.pow(N as u32 - 2) && nns == vec![160, 160, 171, 170, 161, 158] && best.0 < low);
    println!("ALL CHECKS PASS");
}
