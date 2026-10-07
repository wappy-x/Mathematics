// Matchings and augmenting paths -- the same check as the Python, in Rust.  No crates.
// Five volunteers, five tasks, nine 'can do' lines.  Road one: a greedy pairing repaired
// by an alternating route.  Road two: all 512 sets of lines, for the largest and for Berge.
const TASKS: [&str; 5] = ["registration", "first aid", "water", "parking", "timing"];
const NAMES: [&str; 5] = ["Priya", "Omar", "Lena", "Sam", "Tomas"];
const CAN: [&[i32]; 5] = [&[0, 1], &[2, 3], &[1, 4], &[2, 3], &[0]];
type Pairs = [i32; 5];                           // which volunteer holds each task, -1 none
fn greedy(order: &[i32]) -> Pairs {              // each takes the first task on their list still free
    let mut owner = [-1; 5];
    for &v in order {
        if let Some(&t) = CAN[v as usize].iter().find(|&&t| owner[t as usize] < 0) { owner[t as usize] = v }
    }
    owner
}
fn route(v: i32, owner: &Pairs, seen: &mut Vec<i32>) -> Option<Vec<i32>> {  // alternating route to a free task
    for &t in CAN[v as usize] {
        if seen.contains(&t) { continue }
        seen.push(t);
        if owner[t as usize] < 0 { return Some(vec![v, t]) }
        if let Some(rest) = route(owner[t as usize], owner, seen) { return Some([vec![v, t], rest].concat()) }
    }
    None
}
fn augmenting(owner: &Pairs) -> Option<Vec<i32>> {  // the first route found from an unpaired volunteer
    (0..5).filter(|v| !owner.contains(v)).find_map(|v| route(v, owner, &mut Vec::new()))
}
fn flip(owner: &Pairs, r: &[i32]) -> Pairs {     // the route's outside lines go in, its inside lines out
    let mut out = *owner;
    for i in (0..r.len()).step_by(2) { out[r[i + 1] as usize] = r[i] }
    out
}
fn perms(xs: &[i32]) -> Vec<Vec<i32>> {          // every order of a list, written out here
    if xs.is_empty() { return vec![vec![]] }
    xs.iter().flat_map(|&x| { let rest: Vec<i32> = xs.iter().copied().filter(|&y| y != x).collect();
        perms(&rest).into_iter().map(move |p| [vec![x], p].concat()) }).collect()
}
fn size(o: &Pairs) -> usize { o.iter().filter(|&&v| v >= 0).count() }
fn show(o: &Pairs) -> String {
    (0..5).filter(|&t| o[t] >= 0).map(|t| format!("{}-{}", NAMES[o[t] as usize], TASKS[t])).collect::<Vec<_>>().join(", ")
}
fn main() {
    let lines: Vec<(i32, i32)> = (0..5).flat_map(|v| CAN[v as usize].iter().map(move |&t| (v, t))).collect();
    let g = greedy(&[0, 1, 2, 3, 4]); let r = augmenting(&g).unwrap();
    let (fixed, half) = (flip(&g, &r), flip(&g, &r[..4]));
    let (mut by_size, mut agree, mut perfect) = ([0usize; 6], 0, Vec::new());
    for mask in 0u32..(1 << lines.len()) {       // road two: every set of lines
        let pick: Vec<(i32, i32)> = (0..lines.len()).filter(|i| mask >> i & 1 == 1).map(|i| lines[i]).collect();
        let (mut vs, mut ts) = (vec![], vec![]);
        if pick.iter().any(|&(v, t)| { let clash = vs.contains(&v) || ts.contains(&t); vs.push(v); ts.push(t); clash }) { continue }
        by_size[pick.len()] += 1;
        let mut owner = [-1; 5]; for &(v, t) in &pick { owner[t as usize] = v }
        if pick.len() == 5 { perfect.push(owner) }
        if augmenting(&owner).is_some() == (pick.len() < 5) { agree += 1 }
    }
    let (best, orders) = ((0..6).filter(|&k| by_size[k] > 0).max().unwrap(), perms(&[0, 1, 2, 3, 4]));
    let census = orders.iter().filter(|p| (0..5).all(|v| CAN[v].contains(&p[v]))).count();
    let hits = orders.iter().filter(|o| size(&greedy(o)) == 5).count();
    let other = *perfect.iter().find(|&&p| p != fixed).unwrap();
    let words: Vec<&str> = r.iter().enumerate().map(|(i, &x)| if i % 2 == 0 { NAMES[x as usize] } else { TASKS[x as usize] }).collect();
    let held = |o: &Pairs, v: i32, t: i32| o[t as usize] == v;
    println!("volunteers 5, tasks 5, can-do lines {}", lines.len());
    println!("greedy, in listed order: {}; size {}", show(&g), size(&g));
    println!("augmenting route: {}; {} lines, {} out, {} in", words.join(" - "), r.len() - 1, r.len() / 2, r.len() / 2 - 1);
    println!("after the flip: {}; size {}; route left: {}", show(&fixed), size(&fixed), if augmenting(&fixed).is_some() { "yes" } else { "none" });
    println!("matchings by size 0 to 5, from all {} sets of lines: {:?}", 1 << lines.len(), by_size);
    println!("largest by brute force: {}; perfect matchings: {}; by all 120 orders of tasks: {}", best, perfect.len(), census);
    println!("Berge on every matching, route found exactly when size < 5: {} of {}", agree, by_size.iter().sum::<usize>());
    println!("greedy orders of volunteers that reach 5: {} of {}", hits, orders.len());
    println!("the other perfect matching: {}", show(&other));
    println!("lines in exactly one of greedy and it: {}, {} from it, {} from greedy",
        lines.iter().filter(|&&(v, t)| held(&g, v, t) != held(&other, v, t)).count(),
        lines.iter().filter(|&&(v, t)| held(&other, v, t) && !held(&g, v, t)).count(),
        lines.iter().filter(|&&(v, t)| held(&g, v, t) && !held(&other, v, t)).count());
    println!("mistake, flip the route only as far as Lena: {}; size {}", show(&half), size(&half));
    assert!(best == size(&fixed) && size(&g) < best);                 // two roads to 5
    assert!(agree == by_size.iter().sum::<usize>());                  // Berge on all matchings
    assert!(perfect.len() == census);                                 // two counts of perfect
    assert!(hits * 6 == orders.len());  // greedy wins only when Tomas, Priya, Lena come in that order
    println!("ALL CHECKS PASS");
}
