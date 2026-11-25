// Erdos-Stone and Kovari-Sos-Turan -- the same check as the Python, in Rust.  No crates.  Points are
// 0 to n-1 and a network is a list of neighbour bitmasks.  Road one is the cap formula; road two scans
// every walk a-b-c-d-a; road three counts cherries two ways; road four searches up to 8 points.
type Net = Vec<u32>;
fn net(n: usize, links: &[(usize, usize)]) -> Net {
    let mut nb = vec![0u32; n]; for &(a, b) in links { nb[a] |= 1 << b; nb[b] |= 1 << a } nb
}
fn has(nb: &Net, a: usize, b: usize) -> bool { nb[a] >> b & 1 == 1 }
fn four_cycles(nb: &Net) -> usize {         // road two: a-b-c-d-a, each cycle met 8 times
    let n = nb.len();
    (0..n * n * n * n).filter(|&i| { let (a, b, c, d) = (i / (n * n * n), i / (n * n) % n, i / n % n, i % n);
        c != a && d != a && d != b && has(nb, a, b) && has(nb, b, c) && has(nb, c, d) && has(nb, d, a) }).count() / 8
}
fn cap(n: usize) -> f64 { n as f64 / 4.0 * (1.0 + ((4 * n - 3) as f64).sqrt()) }
fn links(nb: &Net) -> usize { nb.iter().map(|s| s.count_ones() as usize).sum::<usize>() / 2 }
fn go(ps: &[(usize, usize)], nb: &mut Net, i: usize, e: usize, best: &mut usize) {
    if e > *best { *best = e }
    if i == ps.len() || e + ps.len() - i <= *best { return }
    let (a, b) = ps[i];
    let blocked = (0..nb.len()).any(|x| x != a && has(nb, b, x) && nb[x] & nb[a] & !(1 << b) != 0);
    if !blocked { nb[a] |= 1 << b; nb[b] |= 1 << a; go(ps, nb, i + 1, e + 1, best); nb[a] &= !(1 << b); nb[b] &= !(1 << a) }
    go(ps, nb, i + 1, e, best);
}
fn search(n: usize) -> usize {              // road four: add pairs one by one, refuse a 4-cycle
    let ps: Vec<(usize, usize)> = (0..n).flat_map(|b| (0..b).map(move |a| (a, b))).collect();
    let mut best = 0; go(&ps, &mut vec![0u32; n], 0, 0, &mut best); best
}
fn chi(n: u32, links: &[(usize, usize)]) -> u32 {   // fewest colours, by trying every colouring
    let mut k = 1u32;
    while !(0..k.pow(n)).any(|c| links.iter().all(|&(a, b)| c / k.pow(a as u32) % k != c / k.pow(b as u32) % k)) { k += 1 }
    k
}
fn polarity(q: usize) -> Net {              // points of the plane over 0..q-1; link x, y when x.y = 0 mod q
    let mut pts: Vec<[usize; 3]> = (0..q * q).map(|i| [1, i / q, i % q]).collect();
    pts.extend((0..q).map(|z| [0, 1, z])); pts.push([0, 0, 1]);
    let l: Vec<(usize, usize)> = (0..pts.len()).flat_map(|j| (0..j).map(move |i| (i, j))).collect();
    let l: Vec<(usize, usize)> = l.into_iter().filter(|&(i, j)| (0..3).map(|t| pts[i][t] * pts[j][t]).sum::<usize>() % q == 0).collect();
    net(pts.len(), &l)
}
fn main() {
    let two: Vec<(usize, usize)> = (0..5).flat_map(|b| (0..b).map(move |a| (a, b))).collect();
    let pet_links: Vec<(usize, usize)> = (0..10).flat_map(|j| (0..j).map(move |i| (i, j)))
        .filter(|&(i, j)| ![two[i].0, two[i].1].iter().any(|&p| p == two[j].0 || p == two[j].1)).collect();
    let pet = net(10, &pet_links);
    let deg: Vec<usize> = pet.iter().map(|s| s.count_ones() as usize).collect();
    let cherries: usize = deg.iter().map(|d| d * (d - 1) / 2).sum();                   // road three, by middles
    let mut ends: Vec<(usize, usize)> = (0..10).flat_map(|v| (0..10).flat_map(move |b| (0..b).map(move |a| (a, b, v))))
        .filter(|&(a, b, v)| has(&pet, v, a) && has(&pet, v, b)).map(|(a, b, _)| (a, b)).collect();
    ends.sort(); ends.dedup();                                                              // road three, by end pairs
    let grown: Vec<usize> = (0..10).flat_map(|b| (0..b).map(move |a| (a, b))).filter(|&(a, b)| !has(&pet, a, b))
        .map(|m| { let mut l = pet_links.clone(); l.push(m); four_cycles(&net(10, &l)) }).collect();
    let found = net(10, &[(0, 1), (0, 2), (1, 2), (0, 3), (0, 4), (3, 4), (1, 5), (1, 6), (5, 6), (2, 7), (3, 8), (5, 8), (7, 8), (4, 9), (6, 9), (7, 9)]);
    let brute: Vec<usize> = (1..9).map(search).collect();
    let floors: Vec<usize> = (1..9).map(|n| cap(n) as usize).collect();
    let pol = [(2, polarity(2)), (3, polarity(3))];
    let x = [("triangle", chi(3, &[(0, 1), (1, 2), (0, 2)])), ("Petersen", chi(10, &pet_links)), ("4-cycle", chi(4, &[(0, 1), (1, 2), (2, 3), (0, 3)]))];
    let (a, tri) = ((1.0 + 37f64.sqrt()) / 2.0, 1000 * 1000 / 4);
    let mut dset = deg.clone(); dset.sort(); dset.dedup();
    println!("cap on 10 points: 2.5 x (1 + sqrt(37)) = 2.5 x {:.3} ~= {:.2}, rounded down {}; 10^1.5 / 2 = {:.2}", 1.0 + 37f64.sqrt(), cap(10), cap(10) as usize, 10f64.powf(1.5) / 2.0);
    println!("Petersen graph: {} points, {} links, degrees {:?}, 4-cycles found {}", pet.len(), links(&pet), dset, four_cycles(&pet));
    println!("cherries by middles 10 x C(3,2) = {}; distinct end pairs {} of C(10,2) = 45", cherries, ends.len());
    println!("average degree 3: 3 x 2 = 6 <= 10 - 1 = 9; at the cap a = {:.2}, a(a - 1) = {:.2}", a, a * (a - 1.0));
    println!("each of its {} missing links, added alone, makes a 4-cycle: {}", grown.len(), if *grown.iter().min().unwrap() > 0 { "yes" } else { "no" });
    println!("a network listed by hand: 10 points, {} links, 4-cycles {}", links(&found), four_cycles(&found));
    println!("most links with no 4-cycle, n = 1 to 8, by search: {:?}", brute);
    println!("cap rounded down, n = 1 to 8:                       {:?}", floors);
    for (q, g) in &pol { println!("polarity graph q = {}: {} points, {} links, q(q+1)^2/2 = {}, 4-cycles {}, cap {}", q, g.len(), links(g), q * (q + 1) * (q + 1) / 2, four_cycles(g), cap(g.len()) as usize) }
    println!("colours needed: triangle {}, Petersen {}, 4-cycle {}", x[0].1, x[1].1, x[2].1);
    println!("Erdos-Stone share 1 - 1/(chi - 1): {}", x.iter().map(|(k, v)| format!("{} {:.3}", k, 1.0 - 1.0 / (*v as f64 - 1.0))).collect::<Vec<_>>().join(", "));
    println!("n = 1000, of 499500 pairs: no triangle {} ({:.3}); no 4-cycle at most {}", tri, tri as f64 / 499500.0, cap(1000) as usize);
    println!("share of pairs at the 4-cycle cap, n = 10, 100, 1000, 10000: {}", [10usize, 100, 1000, 10000].iter().map(|&n| format!("{:.3}", (cap(n) as usize) as f64 / (n * (n - 1) / 2) as f64)).collect::<Vec<_>>().join(", "));
    println!("mistake, ends taken in order: {} > 45, yet the Petersen graph has {} 4-cycles", 2 * cherries, four_cycles(&pet));
    println!("mistake, chi in place of chi - 1, no triangle, n = 10: {:.2}, Mantel says 25", (1.0 - 1.0 / 3.0) * 50.0);
    assert!(brute == vec![0, 1, 3, 4, 6, 7, 9, 11] && brute.iter().zip(&floors).all(|(b, f)| b <= f));
    assert!((1..10001usize).all(|n| { let a = 2.0 * cap(n) / n as f64; (a * (a - 1.0) - (n - 1) as f64).abs() < 1e-6 }));   // a(a-1) = n-1
    assert!(four_cycles(&pet) == 0 && ends.len() == cherries && cherries == 30 && *grown.iter().min().unwrap() > 0);
    assert!(links(&pol[0].1) == 9 && links(&pol[1].1) == 24 && pol.iter().all(|(_, g)| four_cycles(g) == 0));
    assert!(x.iter().map(|p| p.1).collect::<Vec<_>>() == vec![3, 3, 2] && links(&found) == 16 && four_cycles(&found) == 0);
    println!("ALL CHECKS PASS");
}
