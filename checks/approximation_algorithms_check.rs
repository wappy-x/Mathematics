// Approximation algorithms -- the same check as the Python, in Rust.  No crates.
// A synthetic city: 30 bus routes.  Stations N and S are depots, A to F outer
// termini, X, Y, Z mid-route interchanges.  A route lists the stations it calls
// at: its two ends first, then any interchange.  An inspector posted at a station
// checks every route calling there.  Every promise below meets a brute-force optimum.
const NAMES: [&str; 11] = ["N", "S", "A", "B", "C", "D", "E", "F", "X", "Y", "Z"];
const T: usize = 8;                                            // stations 0-7 are termini

fn id(c: char) -> usize { NAMES.iter().position(|s| s.starts_with(c)).unwrap() }
fn names(ks: &[usize]) -> String { ks.iter().map(|&k| NAMES[k]).collect::<Vec<_>>().join(" ") }
fn nums(rs: &[usize]) -> String { rs.iter().map(|i| (i + 1).to_string()).collect::<Vec<_>>().join(" ") }
fn bits(m: usize, n: usize) -> Vec<usize> { (0..n).filter(|k| m >> k & 1 == 1).collect() }
fn unchecked(r: &[Vec<usize>], posts: &[usize]) -> Vec<usize> {
    (0..30).filter(|&i| !r[i][..2].iter().any(|s| posts.contains(s))).collect()
}
fn half(h: usize) -> String { format!("{}{}", h / 2, if h % 2 == 1 { ".5" } else { "" }) } // half-units as text

fn main() {
    let mut r: Vec<Vec<usize>> = Vec::new();                   // routes 1-30, ends first
    for t in "DEFABCDEFABCD".chars() { r.push(vec![id('N'), id(t)]) }
    for t in "EFABCDEFABCDE".chars() { r.push(vec![id('S'), id(t)]) }
    for (a, b) in [('A', 'B'), ('B', 'C'), ('C', 'A'), ('N', 'S')] { r.push(vec![id(a), id(b)]) }
    for i in 0..30 {                                           // interchanges on the way
        if i < 8 || (13..21).contains(&i) { r[i].push(id('X')) }
        else if i < 12 || (21..25).contains(&i) { r[i].push(id('Y')) }
        else if (26..29).contains(&i) { r[i].push(id('Z')) }
    }
    let end: Vec<(usize, usize)> = r.iter().map(|x| (x[0], x[1])).collect();
    let sees: Vec<Vec<usize>> = (0..11).map(|s| (0..30).filter(|&i| r[i].contains(&s)).collect()).collect();

    // PART 1: termini only.  Every route has two ends, so this is vertex cover.
    let covers: Vec<usize> = (0..1usize << T).filter(|&m| unchecked(&r, &bits(m, T)).is_empty()).collect();
    let opt1 = covers.iter().map(|&m| bits(m, T).len()).min().unwrap();
    let best1 = *covers.iter().find(|&&m| bits(m, T).len() == opt1).unwrap();
    let (mut matched, mut posts) = (Vec::new(), Vec::new());   // the matching rule
    for (i, &(u, v)) in end.iter().enumerate() {
        if !posts.contains(&u) && !posts.contains(&v) { matched.push(i); posts.push(u); posts.push(v) }
    }
    posts.sort();
    let alg1 = posts.len();
    let mut lp: Vec<usize> = Vec::new();                       // LP: every half-step point
    for code in 0..3usize.pow(T as u32) {
        let x: Vec<usize> = (0..T).map(|k| code / 3usize.pow(k as u32) % 3).collect();
        if end.iter().all(|&(u, v)| x[u] + x[v] >= 2)
            && (lp.is_empty() || x.iter().sum::<usize>() < lp.iter().sum::<usize>()) { lp = x }
    }
    let lp2: usize = lp.iter().sum();
    let lpval = lp2 as f64 / 2.0;
    let y: Vec<usize> = (0..30).map(|i| if i == 0 || i == 13 { 2 } else if (26..29).contains(&i) { 1 } else { 0 }).collect();
    let load: Vec<usize> = (0..T).map(|k| (0..30).filter(|&i| end[i].0 == k || end[i].1 == k).map(|i| y[i]).sum()).collect();
    let rounded: Vec<usize> = (0..T).filter(|&k| lp[k] >= 1).collect();
    let floored: Vec<usize> = (0..T).filter(|&k| lp[k] == 2).collect();
    let ysum: usize = y.iter().sum();
    let maxload = *load.iter().max().unwrap();
    let mut lines: Vec<((usize, usize), usize)> = Vec::new();  // depot lines and their routes
    for &e in &end[..26] {
        match lines.iter_mut().find(|l| l.0 == e) { Some(l) => l.1 += 1, None => lines.push((e, 1)) }
    }
    let three: Vec<String> = lines.iter().filter(|l| l.1 == 3).map(|l| format!("{}-{}", NAMES[l.0 .0], NAMES[l.0 .1])).collect();
    println!("{} routes; {} termini ({}); 3 interchanges (X Y Z); {} stations; synthetic", r.len(), T, names(&(0..T).collect::<Vec<_>>()), NAMES.len());
    println!("routes 1-13 leave N, 14-26 leave S, 27-29 ring A-B-C, 30 is the N-S express; {} carry 3 routes, the other {} depot lines 2",
             three.join(" and "), lines.len() - three.len());
    println!("termini only, all {} sets of posts tried: fewest {} ({})", 1 << T, opt1, names(&bits(best1, T)));
    println!("matching rule picks routes {}, no two sharing a station: posts {} = {}", nums(&matched), names(&posts), alg1);
    println!("so every cover needs at least {}; ratio {}/{} = {:.2}, promise <= 2", matched.len(), alg1, opt1, alg1 as f64 / opt1 as f64);
    let lpw: Vec<String> = (0..T).map(|k| format!("{} {}", NAMES[k], half(lp[k]))).collect();
    println!("LP, all {} half-step points: {} at {}", 3usize.pow(T as u32), half(lp2), lpw.join(", "));
    println!("packing: routes 1, 14 weight 1, routes 27 28 29 weight 0.5; heaviest station load {}; total {}", half(maxload), half(ysum));
    println!("posts come whole, so {} means at least {}", half(lp2), (lp2 + 1) / 2);
    println!("rounding, post where x >= 0.5: {} = {} <= 2 x {} = {}; ratio {}/{} = {:.2}", names(&rounded), rounded.len(), half(lp2), half(2 * lp2), rounded.len(), opt1, rounded.len() as f64 / opt1 as f64);

    // PART 2: any station.  A route calls at up to 3 stations: set cover.
    let n2 = NAMES.len();
    let union = |m: usize| { let mut u = vec![false; 30]; for k in bits(m, n2) { for &i in &sees[k] { u[i] = true } } u.iter().all(|&b| b) };
    let full: Vec<usize> = (0..1usize << n2).filter(|&m| union(m)).collect();
    let opt2 = full.iter().map(|&m| bits(m, n2).len()).min().unwrap();
    let best2 = *full.iter().find(|&&m| bits(m, n2).len() == opt2).unwrap();
    println!("routes seen per station: {}", (0..n2).map(|k| format!("{} {}", NAMES[k], sees[k].len())).collect::<Vec<_>>().join(", "));
    let (mut left, mut picks, mut prices): (Vec<usize>, Vec<usize>, Vec<(usize, usize)>) = ((0..30).collect(), Vec::new(), Vec::new());
    while !left.is_empty() {                                   // greedy: most new routes
        let newc = |j: usize| sees[j].iter().filter(|i| left.contains(i)).count();
        let mut k = 0;
        for j in 1..n2 { if newc(j) > newc(k) { k = j } }
        let new = newc(k);
        println!("greedy pick {}: {}  {:<16} {:>2} new of {:>2} left, price 1/{} each <= OPT/left = {}/{}",
                 picks.len() + 1, NAMES[k], "#".repeat(new), new, left.len(), new, opt2, left.len());
        picks.push(k); prices.push((new, left.len()));
        left.retain(|i| !sees[k].contains(i));
    }
    let h: f64 = (1..=30).map(|k| 1.0 / k as f64).sum();
    let f = r.iter().map(|x| x.len()).max().unwrap();          // most stations on one route
    println!("any station: a route calls at up to {}; all {} sets tried: fewest {} ({})", f, 1 << n2, opt2, names(&bits(best2, n2)));
    println!("greedy: {} posts ({}); ratio {}/{} = {:.2}", picks.len(), names(&picks), picks.len(), opt2, picks.len() as f64 / opt2 as f64);
    println!("promise: H(30) x OPT = {:.3} x {} = {:.2}; 1 + ln 30 = {:.3}", h, opt2, h * opt2 as f64, 1.0 + 30f64.ln());
    println!("mistake, LP rounded down: posts {}, routes {} unchecked", names(&floored), nums(&unchecked(&r, &floored)));
    let ones: Vec<usize> = matched.iter().map(|&i| end[i].0).collect();
    println!("mistake, one end of each matched route: posts {}, route {} unchecked", names(&ones), nums(&unchecked(&r, &ones)));
    println!("mistake, LP value read as the minimum: ratio {}/{} = {:.2} claimed, true {:.2}", rounded.len(), half(lp2), rounded.len() as f64 / lpval, rounded.len() as f64 / opt1 as f64);
    println!("mistake, greedy read as the minimum: {} posts, {} more than {}", picks.len(), picks.len() - opt2, opt2);
    assert!(opt1 == 4 && alg1 <= 2 * opt1 && matched.len() <= opt1);         // 2-approximation
    assert!(matched.iter().all(|&i| matched.iter().all(|&j| i >= j || (end[i].0 != end[j].0 && end[i].0 != end[j].1 && end[i].1 != end[j].0 && end[i].1 != end[j].1))));
    assert!(maxload <= 2 && ysum == lp2 && lp2 == 7);                          // LP = 3.5 two ways
    assert!(lpval <= opt1 as f64 && unchecked(&r, &rounded).is_empty() && rounded.len() as f64 <= 2.0 * lpval);
    assert!(opt2 == 3 && f == 3 && picks.len() as f64 <= h * opt2 as f64 && picks.len() > opt2); // greedy misses here
    assert!(prices.iter().all(|&(new, l)| opt2 * new >= l));                   // price <= OPT/left
    assert!(31f64.ln() < h && h <= 1.0 + 30f64.ln());                          // integral bounds on H(30)
    assert!(unchecked(&r, &floored).len() == 3 && unchecked(&r, &ones).len() == 1 && three == ["N-D", "S-E"]);
    let fig = [("N", 40, 140), ("S", 320, 140), ("D", 180, 26), ("E", 180, 66),
               ("F", 180, 106), ("B", 180, 172), ("A", 222, 206), ("C", 138, 206)];
    println!("figure, {}", fig.iter().map(|(k, x, y)| format!("{} ({},{})", k, x, y)).collect::<Vec<_>>().join(" "));
    println!("ALL CHECKS PASS");
}
