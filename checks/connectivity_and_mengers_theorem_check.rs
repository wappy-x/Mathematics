// Menger's theorem on an 8-station rail network -- the same check as the Python, in Rust.  No crates.
// Road one: brute force as in the Python.  Road two: max flow, each station an in-node and an out-node.
type L = (&'static str, &'static str);
const NET: [L; 9] = [("S", "A"), ("S", "B"), ("A", "J"), ("B", "J"), ("J", "C"), ("C", "T"), ("J", "D"), ("D", "E"), ("E", "T")];
fn at(st: &[&str], x: &str) -> Option<usize> { st.iter().position(|&y| y == x) }
fn label(st: &[&str], lines: &[L]) -> Vec<usize> {   // depth-first search: a piece number per station
    let mut lab = vec![usize::MAX; st.len()];
    for s in 0..st.len() {
        if lab[s] != usize::MAX { continue }
        let mut stack = vec![s]; lab[s] = s;
        while let Some(u) = stack.pop() {
            for (i, j) in lines.iter().filter_map(|&(a, b)| Some((at(st, a)?, at(st, b)?))) {
                for (p, q) in [(i, j), (j, i)] { if p == u && lab[q] == usize::MAX { lab[q] = s; stack.push(q) } }
            }
        }
    }
    lab
}
fn count(st: &[&str], lines: &[L]) -> usize { let mut l = label(st, lines); l.sort(); l.dedup(); l.len() }
fn apart(st: &[&str], lines: &[L]) -> bool { let l = label(st, lines); l[at(st, "S").unwrap()] != l[at(st, "T").unwrap()] }
fn flow(st: &[&str], lines: &[L], big: i32, split: &[&str], off: &str, s: &str, t: &str) -> i32 {
    let (n, p) = (2 * st.len(), |x: &str| at(st, x).unwrap());
    let mut cap = vec![vec![0i32; n]; n];
    for k in 0..st.len() { cap[2 * k][2 * k + 1] = if split.contains(&st[k]) { 1 } else { 1000 } }
    for &(a, b) in lines.iter().filter(|l| l.0 != off && l.1 != off) { cap[2 * p(a) + 1][2 * p(b)] = big; cap[2 * p(b) + 1][2 * p(a)] = big }
    let (src, snk, mut total) = (2 * p(s) + 1, 2 * p(t), 0);
    loop {
        let (mut prev, mut todo, mut h) = (vec![usize::MAX; n], vec![src], 0); prev[src] = src;
        while h < todo.len() {
            let u = todo[h]; h += 1;
            for v in 0..n { if cap[u][v] > 0 && prev[v] == usize::MAX { prev[v] = u; todo.push(v) } }
        }
        if prev[snk] == usize::MAX { return total }
        let mut v = snk; while v != src { let u = prev[v]; cap[u][v] -= 1; cap[v][u] += 1; v = u }
        total += 1;
    }
}
fn routes(lines: &[L], path: Vec<&'static str>, out: &mut Vec<Vec<&'static str>>) {   // every S-T route, no repeats
    let here = *path.last().unwrap();
    if here == "T" { out.push(path); return }
    for &(a, b) in lines { for (u, v) in [(a, b), (b, a)] { if u == here && !path.contains(&v) { let mut q = path.clone(); q.push(v); routes(lines, q, out) } } }
}
fn most_apart(keys: &[Vec<String>]) -> usize {         // the largest family of routes sharing no key
    (0..1usize << keys.len()).filter(|m| {
        let f: Vec<&String> = (0..keys.len()).filter(|i| m >> i & 1 == 1).flat_map(|i| keys[i].iter()).collect();
        f.iter().enumerate().all(|(i, k)| !f[..i].contains(k))
    }).map(|m| m.count_ones() as usize).max().unwrap()
}
fn main() {
    let closed: Vec<L> = NET.iter().copied().filter(|&l| l != ("C", "T")).collect();
    for (name, lines) in [("full network", NET.to_vec()), ("line C-T closed", closed)] {
        let mut st: Vec<&str> = lines.iter().flat_map(|&(a, b)| [a, b]).collect(); st.sort(); st.dedup();
        let mid: Vec<&str> = st.iter().copied().filter(|&x| x != "S" && x != "T").collect();
        let cuts: Vec<u32> = (0..1u32 << lines.len()).filter(|m| apart(&st, &(0..lines.len()).filter(|i| m >> i & 1 == 0).map(|i| lines[i]).collect::<Vec<L>>())).map(|m| m.count_ones()).collect();
        let k = *cuts.iter().min().unwrap();
        let vk = (0..1u32 << mid.len()).filter(|m| apart(&st.iter().copied().filter(|x| !(0..mid.len()).any(|i| m >> i & 1 == 1 && mid[i] == *x)).collect::<Vec<&str>>(), &lines)).map(|m| m.count_ones()).min().unwrap();
        let (lam, kap) = (flow(&st, &lines, 1, &[], "", "S", "T"), flow(&st, &lines, st.len() as i32, &mid, "", "S", "T"));
        let whole = count(&st, &lines);
        let br1: Vec<String> = lines.iter().filter(|&&l| count(&st, &lines.iter().copied().filter(|&m| m != l).collect::<Vec<L>>()) > whole).map(|l| format!("{}-{}", l.0, l.1)).collect();
        let br2: Vec<String> = lines.iter().filter(|&&l| flow(&st, &lines.iter().copied().filter(|&m| m != l).collect::<Vec<L>>(), 1, &[], "", l.0, l.1) == 0).map(|l| format!("{}-{}", l.0, l.1)).collect();
        let cv1: Vec<String> = st.iter().map(|x| x.to_string()).filter(|x| count(&st.iter().copied().filter(|&y| y != x.as_str()).collect::<Vec<&str>>(), &lines) > whole).collect();
        let nb = |x: &str| -> Vec<&str> { lines.iter().filter_map(|&(a, b)| if a == x { Some(b) } else if b == x { Some(a) } else { None }).collect() };
        let cv2: Vec<String> = st.iter().map(|x| x.to_string()).filter(|x| nb(x).iter().any(|&a| nb(x).iter().any(|&b| a < b && flow(&st, &lines, 1, &[], x.as_str(), a, b) == 0))).collect();
        let mut rs = Vec::new(); routes(&lines, vec!["S"], &mut rs);
        let on_lines: Vec<Vec<String>> = rs.iter().map(|r| r.windows(2).map(|w| if w[0] < w[1] { format!("{}{}", w[0], w[1]) } else { format!("{}{}", w[1], w[0]) }).collect()).collect();
        let on_stations: Vec<Vec<String>> = rs.iter().map(|r| r[1..r.len() - 1].iter().map(|s| s.to_string()).collect()).collect();
        let (ld, sd) = (most_apart(&on_lines), most_apart(&on_stations));
        let show = |v: &[String]| if v.is_empty() { "none".to_string() } else { v.join(", ") };
        println!("{}: {} stations, {} lines, {} S-T routes in all", name, st.len(), lines.len(), rs.len());
        println!("  fewest lines to separate S from T: {} (brute force), {} (flow); {} such sets", k, lam, cuts.iter().filter(|&&c| c == k).count());
        println!("  most line-disjoint routes: {} (brute force), {} (flow)", ld, lam);
        println!("  fewest stations to separate: {} (brute force), {} (split flow); station-disjoint routes {}", vk, kap, sd);
        println!("  bridges: {} (pieces); {} (flow)", show(&br1), show(&br2));
        println!("  cut vertices: {} (pieces); {} (flow)", show(&cv1), show(&cv2));
        assert!(k as i32 == lam && lam as usize == ld);     // Menger, line form: brute cut, flow, brute routes
        assert!(vk as i32 == kap && kap as usize == sd);    // Menger, station form: brute cut, split flow, brute routes
        assert!(br1 == br2 && cv1 == cv2);                  // weak spots: counting pieces against flow
    }
    println!("ALL CHECKS PASS");
}
