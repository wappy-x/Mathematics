// Friends and strangers -- the same check as the Python, in Rust.  No crates.  Six guests, every
// pair labelled acquainted (1) or strangers (0): all 32768 labellings are searched for a trio all
// alike, and the card's pigeonhole route must find one in each.  Then five guests in a ring.
const NAMES: [&str; 6] = ["Ada", "Ben", "Cleo", "Dev", "Eve", "Finn"];
const RING: [(usize, usize); 5] = [(0, 1), (1, 2), (2, 3), (3, 4), (0, 4)];  // each knows two

fn pairs(n: usize) -> Vec<(usize, usize)> { (0..n).flat_map(|i| (i + 1..n).map(move |j| (i, j))).collect() }
fn triples(n: usize) -> Vec<(usize, usize, usize)> { pairs(n).into_iter().flat_map(|(i, j)| (j + 1..n).map(move |k| (i, j, k))).collect() }
fn lab(col: u32, t: &[Vec<usize>], i: usize, j: usize) -> u32 { (col >> t[i][j]) & 1 }
fn names(ps: &[(usize, usize)]) -> String { ps.iter().map(|&(i, j)| format!("{}-{}", NAMES[i], NAMES[j])).collect::<Vec<String>>().join(", ") }
fn table(n: usize) -> Vec<Vec<usize>> {          // where each pair's label sits among the bits
    let mut t = vec![vec![0usize; n]; n];
    for (b, &(i, j)) in pairs(n).iter().enumerate() { t[i][j] = b; t[j][i] = b }
    t
}
fn orders(xs: &[usize]) -> Vec<Vec<usize>> {     // every arrangement of a list, written out here
    if xs.is_empty() { return vec![vec![]] }
    (0..xs.len()).flat_map(|i| {
        let mut rest = xs.to_vec(); let x = rest.remove(i);
        orders(&rest).into_iter().map(move |mut p| { p.insert(0, x); p }).collect::<Vec<Vec<usize>>>()
    }).collect()
}
fn mono(col: u32, t: &[Vec<usize>], tris: &[(usize, usize, usize)]) -> Vec<(usize, usize, usize)> {
    tris.iter().cloned().filter(|&(i, j, k)| lab(col, t, i, j) == lab(col, t, i, k) && lab(col, t, i, k) == lab(col, t, j, k)).collect()   // road one: every trio
}
fn by_proof(col: u32, t: &[Vec<usize>], n: usize) -> Option<(usize, usize, usize)> {
    let kinds: Vec<Vec<usize>> = (0u32..2)       // road two: the card's pigeonhole route
        .map(|w| (1..n).filter(|&u| lab(col, t, 0, u) == w).collect()).collect();
    if kinds[0].len() < 3 && kinds[1].len() < 3 { return None }
    let w = if kinds[1].len() >= 3 { 1usize } else { 0usize };   // one kind holds three of the five
    let (a, b, c) = (kinds[w][0], kinds[w][1], kinds[w][2]);
    for &(x, y) in [(a, b), (a, c), (b, c)].iter() {
        if lab(col, t, x, y) == w as u32 { let mut v = vec![0, x, y]; v.sort(); return Some((v[0], v[1], v[2])) }
    }
    Some((a, b, c))
}
fn rings(n: usize) -> Vec<Vec<(usize, usize)>> {                    // road two to the 12: every guest ring, as lines
    let mut all: Vec<Vec<(usize, usize)>> = orders(&(0..n).collect::<Vec<usize>>()).iter().map(|p| {
        let mut e: Vec<(usize, usize)> = (0..n).map(|i| (p[i].min(p[(i + 1) % n]), p[i].max(p[(i + 1) % n]))).collect();
        e.sort(); e
    }).collect();
    all.sort(); all.dedup(); all
}

fn main() {
    let (p6, t6, p5, t5) = (pairs(6), triples(6), pairs(5), triples(5));
    let (i6, i5) = (table(6), table(5));
    let tx: Vec<(usize, usize, usize)> = t6.iter().cloned().filter(|&(i, j, k)| !([i, j, k].contains(&4) && [i, j, k].contains(&5))).collect();   // trios avoiding one dropped pair
    let (all6, all5) = (1u32 << p6.len(), 1u32 << p5.len());
    let (mut counts, mut proved, mut agreed, mut dropped) = (Vec::new(), 0usize, 0usize, 0usize);
    for col in 0..all6 {
        let (ms, w) = (mono(col, &i6, &t6), by_proof(col, &i6, 6));
        counts.push(ms.len()); if w.is_some() { proved += 1 }
        if let Some(tr) = w { if ms.contains(&tr) { agreed += 1 } }
        if lab(col, &i6, 4, 5) == 0 && mono(col, &i6, &tx).is_empty() { dropped += 1 }
    }
    let ring: u32 = RING.iter().map(|&(i, j)| 1u32 << i5[i][j]).sum();
    let free5: Vec<u32> = (0..all5).filter(|&c| mono(c, &i5, &t5).is_empty()).collect();
    let blind = free5.iter().filter(|&&c| by_proof(c, &i5, 5).is_none()).count();
    let teams: u32 = p6.iter().filter(|&&(i, j)| (i < 3) != (j < 3)).map(|&(i, j)| 1u32 << i6[i][j]).sum();
    let tmono = mono(teams, &i6, &t6);
    let friends = tmono.iter().filter(|&&(i, j, _)| lab(teams, &i6, i, j) == 1).count();
    let (hold, forced, fewest, most) = (counts.iter().filter(|&&c| c > 0).count(), (5 + 2 - 1) / 2, *counts.iter().min().unwrap(), *counts.iter().max().unwrap());
    let strangers: Vec<(usize, usize)> = p5.iter().cloned().filter(|p| !RING.contains(p)).collect();
    let (orders5, r5) = (orders(&(0..5).collect::<Vec<usize>>()).len(), rings(5));
    let (rings5, esc) = (r5.len(), free5.iter().filter(|&&c| r5.contains(&p5.iter().cloned().filter(|&(i, j)| lab(c, &i5, i, j) == 1).collect::<Vec<(usize, usize)>>())).count());
    println!("six guests {}: pairs C(6,2) = {}, labellings 2^{} = {}, trios C(6,3) = {}\none guest faces {} others; 5 relationships into 2 kinds, rounded up: {} alike; pairs among those three: {}", NAMES.join(", "), p6.len(), p6.len(), all6, t6.len(), NAMES.len() - 1, forced, pairs(3).len());
    println!("all {} labellings searched: {} hold a trio all alike, {} do not\ntrios all alike in one labelling: fewest {}, most {}", all6, hold, all6 as usize - hold, fewest, most);
    println!("the pigeonhole route finds a trio in {} of {} labellings, and the search holds it every time: {}", proved, all6, agreed);
    println!("five guests {} in a ring, each knowing only the two beside them\nacquainted: {}\nstrangers: {}", NAMES[..5].join(", "), names(&RING), names(&strangers));
    println!("the {} trios of five guests: {} all alike -- every trio mixes the two kinds\nall {} labellings of five guests: {} hold no trio at all\nthe same {}, by counting five-guest rings: {} orders / (5 starts x 2 directions) = {}; escapes that are rings: {}", t5.len(), mono(ring, &i5, &t5).len(), all5, free5.len(), free5.len(), orders5, rings5, esc);
    println!("the route on five guests: among those {}, no kind holds three, so it reports nothing {} times", free5.len(), blind);
    println!("mistake 1, 5 into 2 kinds rounded down: {}, not {}\nmistake 2, five guests taken as enough: {} of the {} labellings dodge a trio\nmistake 3, two teams of three, every cross pair acquainted: {} trios of friends, {} of strangers", 5 / 2, forced, free5.len(), all5, friends, tmono.len() - friends);
    println!("one pair left undecided: {} of the {} labellings of the other {} pairs hold no trio", dropped, 1u32 << (p6.len() - 1), p6.len() - 1);
    assert!(hold == all6 as usize && fewest == 2 && most == t6.len());
    assert!(proved == agreed && agreed == all6 as usize);
    assert!(free5.len() == rings5 && rings5 == esc && esc == 12 && blind == free5.len() && mono(ring, &i5, &t5).is_empty());
    assert!(friends == 0 && tmono.len() == 2 && dropped == 12);
    println!("ALL CHECKS PASS");
}
