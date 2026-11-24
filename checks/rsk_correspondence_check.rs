// The RSK correspondence -- the same check as the Python, in Rust.  No crates.  Row insertion
// turns a shuffle into tableaux P (the numbers) and Q (when each box appeared); reverse bumping undoes it.
type Tab = Vec<Vec<usize>>;
fn rsk(w: &[usize]) -> (Tab, Tab) { rsk_by(w, false) }
fn rsk_by(w: &[usize], last: bool) -> (Tab, Tab) {  // road one: row insertion, with a recording
    let (mut p, mut q): (Tab, Tab) = (vec![], vec![]);
    for (step, &x0) in w.iter().enumerate() {
        let (mut x, mut r) = (x0, 0);
        while r < p.len() && *p[r].last().unwrap() > x {          // x bumps the first larger entry
            let j = if last { p[r].iter().rposition(|&y| y > x) } else { p[r].iter().position(|&y| y > x) }.unwrap(); std::mem::swap(&mut p[r][j], &mut x); r += 1;
        }
        if r == p.len() { p.push(vec![]); q.push(vec![]); }
        p[r].push(x); q[r].push(step + 1);                         // x lands at the end of row r
    }
    (p, q)
}
fn unrsk(p0: &Tab, q0: &Tab) -> Vec<usize> {  // reverse bumping: undo the last step first
    let (mut p, mut q, mut w) = (p0.clone(), q0.clone(), vec![]);
    for step in (1..=q.iter().map(|r| r.len()).sum::<usize>()).rev() {
        let r = q.iter().position(|row| row.last() == Some(&step)).unwrap();
        q[r].pop(); let mut x = p[r].pop().unwrap();
        for rr in (0..r).rev() {                                   // displace the largest smaller entry
            let j = p[rr].iter().rposition(|&y| y < x).unwrap(); std::mem::swap(&mut p[rr][j], &mut x); }
        w.push(x);
    }
    w.reverse(); w
}
fn shapes(n: usize, cap: usize) -> Vec<Vec<usize>> {        // partitions of n, largest part first
    if n == 0 { return vec![vec![]]; }
    (1..=n.min(cap)).rev().flat_map(|k| shapes(n - k, k).into_iter().map(move |r| [vec![k], r].concat())).collect()
}
fn f(lam: &[usize]) -> usize {             // road two: the box holding n sits at a corner
    let lam: Vec<usize> = lam.iter().copied().filter(|&p| p > 0).collect();
    if lam.is_empty() { return 1; }
    (0..lam.len()).filter(|&i| i == lam.len() - 1 || lam[i] > lam[i + 1])
        .map(|i| { let mut m = lam.clone(); m[i] -= 1; f(&m) }).sum()
}
fn run(w: &[usize], sign: i64) -> usize {   // longest rising (+1) or falling (-1) run, by DP
    let mut best: Vec<usize> = vec![];
    for j in 0..w.len() { best.push(1 + (0..j).filter(|&i| sign * (w[j] as i64 - w[i] as i64) > 0).map(|i| best[i]).max().unwrap_or(0)); }
    *best.iter().max().unwrap()
}
fn standard(p: &Tab) -> bool { p.iter().all(|r| r.windows(2).all(|x| x[0] < x[1])) && p.windows(2).all(|w| w[0].len() >= w[1].len() && w[1].iter().zip(&w[0]).all(|(b, a)| a < b)) }
fn l(xs: &[usize]) -> String { xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", ") }
fn t(p: &Tab) -> String { p.iter().filter(|r| !r.is_empty()).map(|r| r.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(" ")).collect::<Vec<_>>().join(" / ") }
fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }
fn main() {
    let w = [2, 4, 1, 3]; let (p, q) = rsk(&w); let lams = shapes(4, 99); let fs: Vec<usize> = lams.iter().map(|x| f(x)).collect();
    println!("insert {}: {}", l(&w), (1..5).map(|k| t(&rsk(&w[..k]).0)).collect::<Vec<_>>().join(" | "));
    println!("P = {}; Q = {}; shape ({}); reverse bumping gives {}", t(&p), t(&q), l(&p.iter().map(|r| r.len()).collect::<Vec<_>>()), l(&unrsk(&p, &q)));
    println!("first row {} = longest rising run {}, so 4 - {} = {} volumes move; rows {} = longest falling run {}", p[0].len(), run(&w, 1), run(&w, 1), 4 - run(&w, 1), p.len(), run(&w, -1));
    println!("n = 4 tableau counts, by corners: {}", lams.iter().zip(&fs).map(|(x, c)| format!("({}) {}", l(x), c)).collect::<Vec<_>>().join(", "));
    println!("squares {} = {} = 4!", fs.iter().map(|c| (c * c).to_string()).collect::<Vec<_>>().join(" + "), fs.iter().map(|c| c * c).sum::<usize>());
    let (mut fact, mut total, mut schensted, mut es) = (1, 0, 0, 0);
    let (mut ws, mut out4, mut ws4): (Vec<Vec<usize>>, Vec<(Tab, Tab)>, Vec<Vec<usize>>) = (vec![vec![]], vec![], vec![]);
    for n in 1..8usize {                   // every shuffle of 1..n: slot n into every shuffle of 1..n-1
        fact *= n;
        ws = ws.iter().flat_map(|v| (0..n).map(move |i| { let mut u = v.clone(); u.insert(i, n); u })).collect();
        let out: Vec<(Tab, Tab)> = ws.iter().map(|v| rsk(v)).collect();
        let mut pairs = out.clone(); pairs.sort(); pairs.dedup();
        let back = out.iter().zip(&ws).all(|((a, b), v)| unrsk(a, b) == *v);
        let tot: usize = shapes(n, 99).iter().map(|x| f(x) * f(x)).sum(); total += ws.len();
        let mut byshape: Vec<(Vec<usize>, Tab)> = out.iter().map(|(a, _)| (a.iter().map(|r| r.len()).collect(), a.clone())).collect();
        byshape.sort(); byshape.dedup();
        for ((a, _), v) in out.iter().zip(&ws) { schensted += (a[0].len() == run(v, 1) && a.len() == run(v, -1)) as usize; es += (run(v, 1) * run(v, -1) >= n) as usize; }
        if n >= 4 { println!("n = {}: {} shuffles, {} distinct (P, Q) pairs, sum of squares {}, all undone: {}", n, ws.len(), pairs.len(), tot, yn(back)); }
        assert!(pairs.len() == fact && fact == tot && back && shapes(n, 99).iter().all(|x| byshape.iter().filter(|(s, _)| s == x).count() == f(x)) && out.iter().all(|(a, b)| standard(a) && standard(b) && a.iter().map(|r| r.len()).eq(b.iter().map(|r| r.len()))));
        if n == 4 { out4 = out.clone(); ws4 = ws.clone(); }
    }
    println!("Schensted, first row = longest rising run and rows = longest falling run: {} of {} shuffles", schensted, total);
    println!("Erdos-Szekeres, rising x falling >= n: {} of {} shuffles, n = 1 to 7", es, total);
    let (inv, same) = (ws4.iter().filter(|v| (0..4).all(|i| v[v[i] - 1] == i + 1)).count(), out4.iter().filter(|(a, b)| a == b).count());
    let mut ps: Vec<Tab> = out4.iter().map(|(a, _)| a.clone()).collect(); ps.sort(); ps.dedup();
    println!("mistake 1, counts unsquared: {} = {}, the {} shuffles that are their own undo ({} with P = Q)", fs.iter().map(|c| c.to_string()).collect::<Vec<_>>().join(" + "), fs.iter().sum::<usize>(), inv, same);
    println!("mistake 2, P alone: 24 shuffles give {} tableaux; 2, 1, 4, 3 also gives {}", ps.len(), t(&rsk(&[2, 1, 4, 3]).0));
    println!("mistake 3, first row read as the run: 3, 4, 2, 1 gives first row {}, but 4 comes before 1", t(&rsk(&[3, 4, 2, 1]).0[..1].to_vec()));
    println!("mistake 4, bump the last larger entry: 2, 3, 1 gives {}, whose first row falls", t(&rsk_by(&[2, 3, 1], true).0));
    assert!(schensted == es && es == total && total == 5913 && fs.iter().sum::<usize>() == inv && inv == same && same == 10);
    println!("ALL CHECKS PASS");
}
