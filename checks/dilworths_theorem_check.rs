// Dilworth's theorem -- the same check as the Python, in Rust.  No crates.  Three orders: the divisors of 12
// under "divides", ten closing prices (day i below day j when earlier and cheaper), the subsets of {1, 2, 3, 4}
// under "inside".  Road one: a largest matching, then Konig's cover.  Road two: every set, every dealing.
const D: [usize; 6] = [1, 2, 3, 4, 6, 12];
const CENTS: [u32; 10] = [4320, 4210, 4460, 4165, 4395, 4630, 4288, 4515, 4705, 4570];
type Below = fn(usize, usize) -> bool;
fn div(i: usize, j: usize) -> bool { i != j && D[j] % D[i] == 0 }
fn day(i: usize, j: usize) -> bool { i < j && CENTS[i] < CENTS[j] }
fn sub(a: usize, b: usize) -> bool { a != b && a & b == a }   // subsets of {1, 2, 3, 4} as 4-bit numbers
fn grow(i: usize, n: usize, below: Below, mate: &mut Vec<Option<usize>>, seen: &mut Vec<bool>) -> bool {
    for j in 0..n {                    // an alternating walk from i, as on the Konig card
        if !below(i, j) || seen[j] { continue }
        seen[j] = true;
        if mate[j].is_none() || grow(mate[j].unwrap(), n, below, mate, seen) { mate[j] = Some(i); return true }
    }
    false
}
fn matching(n: usize, below: Below) -> Vec<Option<usize>> {   // mate[j] = i: i sits just under j in one chain
    (0..n).fold(vec![None; n], |mut mate, i| { grow(i, n, below, &mut mate, &mut vec![false; n]); mate })
}
fn chains(n: usize, mate: &[Option<usize>]) -> Vec<Vec<usize>> {   // climb the links from every unlinked bottom
    let mut up = vec![None; n];
    for j in 0..n { if let Some(i) = mate[j] { up[i] = Some(j) } }
    (0..n).filter(|&s| mate[s].is_none()).map(|s| { let mut c = vec![s]; while let Some(j) = up[c[c.len() - 1]] { c.push(j) } c }).collect()
}
fn konig_antichain(n: usize, below: Below, mate: &[Option<usize>]) -> Vec<usize> {
    let (mut zl, mut zr) = (vec![false; n], vec![false; n]);   // walk from unlinked left copies
    let mut todo: Vec<usize> = (0..n).filter(|&i| !mate.contains(&Some(i))).collect();
    while let Some(i) = todo.pop() {
        zl[i] = true; for j in 0..n { if below(i, j) && !zr[j] { zr[j] = true; if let Some(k) = mate[j] { if !zl[k] { todo.push(k) } } } }
    }
    (0..n).filter(|&x| zl[x] && !zr[x]).collect()   // keep items reached on the left only
}
fn best_antichains(n: usize, below: Below) -> Vec<Vec<usize>> {   // road two: every set of items
    let comp: Vec<u32> = (0..n).map(|x| (0..n).filter(|&y| below(x, y) || below(y, x)).map(|y| 1 << y).sum()).collect();
    let ok: Vec<u32> = (0..1u32 << n).filter(|&s| (0..n).all(|x| s >> x & 1 == 0 || comp[x] & s == 0)).collect();
    let top = ok.iter().map(|s| s.count_ones()).max().unwrap();
    ok.iter().filter(|s| s.count_ones() == top).map(|&s| (0..n).filter(|&x| s >> x & 1 == 1).collect()).collect()
}
fn fewest_dealing(n: usize, below: Below) -> (usize, usize) {   // road two: deal into k unlabelled piles
    for k in 1..4usize {
        let lab = |c: usize, x: usize| c / k.pow(x as u32) % k;
        let ways = (0..k.pow(n as u32)).filter(|&c| (0..n).all(|x| (0..x).all(|y| lab(c, x) != lab(c, y) || below(x, y) || below(y, x)))).count();
        if ways > 0 { return (k, ways / [1, 1, 2, 6][k]) }
    }
    (0, 0)
}
fn layers(n: usize, below: Below) -> Vec<Vec<usize>> {   // Mirsky: height = longest chain ending at an item
    let mut h = vec![0usize; n];
    for y in 0..n { h[y] = 1 + (0..y).filter(|&x| below(x, y)).map(|x| h[x]).max().unwrap_or(0) }
    (1..=*h.iter().max().unwrap()).map(|t| (0..n).filter(|&x| h[x] == t).collect()).collect()
}
fn nm(grp: &[Vec<usize>], xs: &[usize]) -> Vec<Vec<usize>> { grp.iter().map(|c| c.iter().map(|&x| xs[x]).collect()).collect() }
fn main() {
    let (days, m, mh, ms): (Vec<usize>, _, _, _) = ((1..11).collect(), matching(6, div), matching(10, day), matching(16, sub));
    let size = |m: &[Option<usize>]| m.iter().filter(|x| x.is_some()).count();
    let (cd, ad, bd, ld) = (chains(6, &m), konig_antichain(6, div, &m), best_antichains(6, div), layers(6, div));
    let (ch, ah, bh, lh) = (chains(10, &mh), konig_antichain(10, day, &mh), best_antichains(10, day), layers(10, day));
    let (cs, as_, bs) = (chains(16, &ms), konig_antichain(16, sub, &ms), best_antichains(16, sub));
    let ((kd, wd), (kh, _)) = (fewest_dealing(6, div), fewest_dealing(10, day));
    let mut g: Vec<Option<usize>> = vec![None; 6];   // mistake 1: link each divisor to its largest free multiple
    for i in 0..6 { if let Some(j) = (0..6).filter(|&j| div(i, j) && g[j].is_none()).max() { g[j] = Some(i) } }
    println!("divisors of 12: 6 items, {} comparable pairs, largest matching {}", (0..6).map(|i| (0..6).filter(|&j| div(i, j)).count()).sum::<usize>(), size(&m));
    println!("road one: chains 6 - {} = {}: {:?}; Konig antichain {:?}", size(&m), cd.len(), nm(&cd, &D), nm(&[ad.clone()], &D)[0]);
    println!("road two: largest antichains {:?}; fewest chains {}, in {} ways", nm(&bd, &D), kd, wd);
    println!("Mirsky: longest chain {}, height layers {:?}", ld.len(), nm(&ld, &D));
    println!("prices: matching {}, rising runs {}: {:?}", size(&mh), ch.len(), nm(&ch, &days));
    println!("falling run from the cover: days {:?} at {}; every set: {}, dealing: {}", nm(&[ah.clone()], &days)[0], ah.iter().map(|&x| format!("{}.{:02}", CENTS[x] / 100, CENTS[x] % 100)).collect::<Vec<_>>().join(", "), bh[0].len(), kh);
    println!("longest rising run {}; 10 days <= {} runs x {} = {}", lh.len(), ch.len(), lh.len(), ch.len() * lh.len());
    println!("16 subsets: matching {}, chains {}, antichain {}; every set: {}, found {} time", size(&ms), cs.len(), as_.len(), bs[0].len(), bs.len());
    println!("mistake 1, greedy links (1 to 12 first): matching {}, chains {}", size(&g), 6 - size(&g));
    println!("mistake 2, longest chain taken as the count: {}, not {}", ld.len(), cd.len());
    println!("mistake 3, rising stretches of days in a row: {}, not {}", 1 + (0..9).filter(|&i| CENTS[i + 1] < CENTS[i]).count(), ch.len());
    let mut all: Vec<usize> = cd.concat(); all.sort();
    assert!(cd.len() == kd && kd == ad.len() && ad.len() == bd[0].len() && bd[0].len() == 2 && all == (0..6).collect::<Vec<usize>>() && cd.iter().all(|c| c.windows(2).all(|w| div(w[0], w[1]))));
    assert!(ch.len() == kh && kh == ah.len() && ah.len() == bh[0].len() && bh[0].len() == 3 && ch.iter().all(|c| c.windows(2).all(|w| day(w[0], w[1]))));
    assert!(cs.len() == as_.len() && as_.len() == bs[0].len() && bs[0].len() == 6 && bs.len() == 1 && cs.iter().all(|c| c.windows(2).all(|w| sub(w[0], w[1]))) && ld.len() == 4 && lh.len() == 4 && size(&g) == 2);
    assert!(ad.iter().all(|&x| ad.iter().all(|&y| !div(x, y))) && ah.iter().all(|&x| ah.iter().all(|&y| !day(x, y))) && as_.iter().all(|&x| as_.iter().all(|&y| !sub(x, y))));
    println!("ALL CHECKS PASS");
}
