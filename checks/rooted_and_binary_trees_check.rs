// Rooted trees -- the same check as the Python, in Rust.  No crates.  A 16-team knockout drawn as a binary tree:
// the final is the root, the 15 matches are the inner vertices, the 16 teams are the leaves.  Counts come by two
// roads sharing no arithmetic -- the tree built and scanned, and left/right addresses listed with no tree at all.
const HEIGHT: usize = 4;
struct T { v: String, k: Option<(Box<T>, Box<T>)> }
fn leaf(v: &str) -> T { T { v: v.to_string(), k: None } }
fn node(v: &str, l: T, r: T) -> T { T { v: v.to_string(), k: Some((Box::new(l), Box::new(r))) } }
fn full(h: usize, a: &str) -> T {           // road one: the bracket, each vertex labelled by its address
    if h == 0 { leaf(a) } else { node(a, full(h - 1, &format!("{}L", a)), full(h - 1, &format!("{}R", a))) }
}
fn addresses(h: usize) -> Vec<String> {     // road two: every address of length 0 to h, no tree at all
    let mut out = vec![String::new()];
    for k in 0..h { let n: Vec<String> = out.iter().filter(|a| a.len() == k).flat_map(|a| [format!("{}L", a), format!("{}R", a)]).collect(); out.extend(n) }
    out
}
fn walk(t: &T, order: &str) -> Vec<String> {  // the card's three rules, each calling itself on a subtree
    let (l, r) = match &t.k { None => return vec![t.v.clone()], Some((l, r)) => (l, r) };
    let (a, b, v) = (walk(l, order), walk(r, order), vec![t.v.clone()]);
    match order { "pre" => [v, a, b].concat(), "in" => [a, v, b].concat(), _ => [a, b, v].concat() }
}
fn mirror(t: &T) -> T { match &t.k { None => leaf(&t.v), Some((l, r)) => node(&t.v, mirror(r), mirror(l)) } }
fn scan(t: &T, d: i64, out: &mut Vec<(String, i64, bool)>) {   // label, depth, and leaf or not
    out.push((t.v.clone(), d, t.k.is_none()));
    if let Some((l, r)) = &t.k { scan(l, d + 1, out); scan(r, d + 1, out) }
}
fn size(v: &str, sizes: &[(&str, i64)]) -> i64 { sizes.iter().find(|p| p.0 == v).unwrap().1 }
fn total(t: &T, sizes: &[(&str, i64)], out: &mut Vec<String>) -> i64 {   // post-order: contents first
    let (l, r) = match &t.k { None => return size(&t.v, sizes), Some((l, r)) => (l, r) };
    let mb = total(l, sizes, out) + total(r, sizes, out); out.push(format!("{} {} MB", t.v, mb)); mb
}
fn direct(t: &T, sizes: &[(&str, i64)], out: &mut Vec<String>) {   // the mistake: loose files only
    let (l, r) = match &t.k { None => return, Some((l, r)) => (l, r) };
    let mb: i64 = [l, r].iter().filter(|c| c.k.is_none()).map(|c| size(&c.v, sizes)).sum();
    out.push(format!("{} {} MB", t.v, mb)); direct(l, sizes, out); direct(r, sizes, out);
}
fn dist(a: &str, b: &str) -> usize {        // steps between two vertices, read off their addresses
    a.len() + b.len() - 2 * (0..a.len().min(b.len())).filter(|&i| a[..i + 1] == b[..i + 1]).count()
}
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let sizes = [("jan.jpg", 4), ("feb.jpg", 2), ("mar.jpg", 5), ("apr.jpg", 3)];
    let folder = node("photos", node("2025", leaf("jan.jpg"), leaf("feb.jpg")), node("2026", leaf("mar.jpg"), leaf("apr.jpg")));
    let keys = node("4", node("2", leaf("1"), leaf("3")), node("6", leaf("5"), leaf("7")));
    let (bracket, addrs, closed) = (full(HEIGHT, ""), addresses(HEIGHT), 2i64.pow(HEIGHT as u32 + 1) - 1);
    let (mut s, mut ls, mut fs) = (Vec::new(), Vec::new(), Vec::new());
    scan(&bracket, 0, &mut s);
    let level: Vec<i64> = (0..=HEIGHT as i64).map(|k| s.iter().filter(|x| x.1 == k).count() as i64).collect();
    let (teams, matches) = (s.iter().filter(|x| x.2).count(), s.iter().filter(|x| !x.2).count());
    let mut lad = leaf("team 1");
    for i in 2..=16 { lad = node(&format!("match {}", i - 1), lad, leaf(&format!("team {}", i))) }
    scan(&lad, 0, &mut ls); scan(&folder, 0, &mut fs);
    let (mut tot, mut early) = (Vec::new(), Vec::new());
    total(&folder, &sizes, &mut tot); direct(&folder, &sizes, &mut early);
    let (mut sorted_addrs, lad_deep) = (addrs.clone(), ls.iter().map(|x| x.1).max().unwrap());
    let lad_matches = ls.iter().filter(|x| !x.2).count();
    let back = |o: &str| walk(&mirror(&folder), o).into_iter().rev().collect::<Vec<String>>();
    let swaps = back("pre") == walk(&folder, "post") && back("post") == walk(&folder, "pre") && back("in") == walk(&folder, "in");
    let (mut keyed, two) = (walk(&keys, "pre"), 2i64.pow(HEIGHT as u32));
    sorted_addrs.sort(); keyed.sort();
    println!("bracket rooted at the final: height {}, {} vertices, {} edges", s.iter().map(|x| x.1).max().unwrap(), s.len(), s.len() - 1);
    println!("vertices at depths 0 to {}: {}, adding to {}", HEIGHT, level.iter().map(|c| c.to_string()).collect::<Vec<String>>().join(" "), level.iter().sum::<i64>());
    println!("the same total by doubling: 2^{} - 1 = {}, leaves 2^{} = {}, inner 2^{} - 1 = {}", HEIGHT + 1, closed, HEIGHT, two, HEIGHT, two - 1);
    println!("the tree walked instead: {} teams at the leaves, {} matches inside, so matches = teams - 1 = {}", teams, matches, teams - 1);
    println!("addresses of length 0 to {}, listed with no tree: {}; sorted, they are the pre-order: {}", HEIGHT, addrs.len(), yn(sorted_addrs == walk(&bracket, "pre")));
    println!("the same {} vertices rooted at one team instead: height {}", s.len(), addrs.iter().map(|a| dist(&"L".repeat(HEIGHT), a)).max().unwrap());
    println!("folder tree: {} vertices, height {}, {} folders, {} edges, files {}", fs.len(), fs.iter().map(|x| x.1).max().unwrap(), fs.len() - sizes.len(), fs.len() - 1,
             sizes.iter().map(|p| format!("{} {} MB", p.0, p.1)).collect::<Vec<String>>().join(", "));
    for (label, rule) in [("pre-order,  the folder before its contents:", "pre"), ("in-order,   left, the folder, right:", "in"), ("post-order, the contents before the folder:", "post")] { println!("  {:<43} {}", label, walk(&folder, rule).join(" ")) }
    println!("mirrored, then read backwards: pre-order swaps with post-order and in-order is unchanged: {}", yn(swaps));
    println!("megabytes finished in post-order: {}", tot.join(", "));
    println!("keys 1 to 7 set smaller-left, read in-order: {}", walk(&keys, "in").join(" "));
    println!("mistake 1, five levels read as the height: 2^{} - 1 = {}, not {}", HEIGHT + 2, 2i64.pow(HEIGHT as u32 + 2) - 1, closed);
    println!("mistake 2, that formula on a knockout with byes: the ladder stands {} deep, so 2^16 - 1 = {}, where it holds {} vertices and {} matches", lad_deep, 2i64.pow(16) - 1, ls.len(), lad_matches);
    println!("mistake 3, folders totalled on the way in: {}", early.join(", "));
    assert!(sorted_addrs == walk(&bracket, "pre") && addrs.len() as i64 == closed && closed == level.iter().sum::<i64>() && addrs.iter().map(|a| dist(&"L".repeat(HEIGHT), a)).max().unwrap() == 2 * HEIGHT && dist("LLLL", "LLLR") == 2);
    assert!(level == (0..=HEIGHT as u32).map(|k| 2i64.pow(k)).collect::<Vec<i64>>() && matches == teams - 1 && teams == 16);
    assert!(walk(&keys, "in") == keyed && swaps);
    assert!(lad_matches == matches && lad_deep == 15 && tot == vec!["2025 6 MB", "2026 8 MB", "photos 14 MB"]);
    println!("ALL CHECKS PASS");
}
