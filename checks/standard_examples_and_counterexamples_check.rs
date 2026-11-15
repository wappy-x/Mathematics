// The test spaces -- the check behind the card.  Rust std only.
// Part 1 lists every topology on a set of 1 to 4 points and tries four claims on each one.
// Part 2 works on the Cantor set through base-3 addresses that use only the digits 0 and 2.
// Every number is an exact integer; Cantor positions are counted in units of 1/1458 = 1/(2 x 3^6).
use std::collections::BTreeSet;

fn topologies(n: u32) -> Vec<Vec<u32>> { // road 1: families holding the empty and whole set, closed under pairs
    let (full, mut out) = ((1u32 << n) - 1, Vec::new());
    for fam in 0u64..(1u64 << (1u32 << n)) {
        if fam & 1 == 1 && fam >> full & 1 == 1 {
            let opens: Vec<u32> = (0..(1u32 << n)).filter(|&s| fam >> s & 1 == 1).collect();
            if opens.iter().all(|&u| opens.iter().all(|&v| fam >> (u | v) & 1 == 1 && fam >> (u & v) & 1 == 1)) { out.push(opens); }
        }
    }
    out
}
fn preorders(n: u32) -> usize { // road 2: a topology on a finite set is the same as a reflexive, transitive relation
    let mut count = 0;
    for r in 0u32..(1u32 << (n * n)) {
        let rel = |i: u32, j: u32| r >> (i * n + j) & 1 == 1;
        if (0..n).all(|i| rel(i, i)) && (0..n).all(|i| (0..n).all(|j| (0..n).all(|k| rel(i, k) || !(rel(i, j) && rel(j, k))))) { count += 1; }
    }
    count
}
fn props(n: u32, opens: &[u32]) -> [bool; 6] {
    let full = (1u32 << n) - 1;
    let closed: BTreeSet<u32> = opens.iter().map(|&u| full ^ u).collect();
    let t1 = (0..n).all(|p| closed.contains(&(1 << p))); // every single point is a closed set
    let haus = (0..n).all(|p| (0..n).all(|q| p == q || opens.iter().any(|&u| opens.iter().any(|&v| u >> p & 1 == 1 && v >> q & 1 == 1 && u & v == 0))));
    let conn = !opens.iter().any(|&u| u != 0 && u != full && opens.contains(&(full ^ u))); // no split into two open pieces
    let cc_fails = (0..(1u32 << n)).any(|s| !closed.contains(&s)); // every subset is compact: is it closed?
    let lim_fails = (0..n).any(|p| (0..n).any(|q| p != q && opens.iter().filter(|&&u| u >> q & 1 == 1).all(|&u| u >> p & 1 == 1)));
    [t1, haus, conn, cc_fails, lim_fails, opens.len() == 1usize << n]
}
fn py(b: bool) -> &'static str { if b { "True" } else { "False" } }
fn gcd(a: i64, b: i64) -> i64 { if b == 0 { a } else { gcd(b, a % b) } }
fn fr(a: i64, b: i64) -> String { if a == 0 { "0".to_string() } else if a % b == 0 { (a / b).to_string() } else { let g = gcd(a, b); format!("{}/{}", a / g, b / g) } }
const L: usize = 6;
const U: i64 = 1458;
fn val(a: &[i64]) -> i64 { a.iter().enumerate().map(|(k, &d)| 2 * d * 3i64.pow((L - 1 - k) as u32)).sum() }
fn first_diff(a: &[i64], b: &[i64]) -> usize { (0..L).find(|&k| a[k] != b[k]).unwrap() + 1 }
fn px(v: i64) -> String { let h = (2 * (3000 * U + 36000 * v) + U) / (2 * U); format!("{}.{:02}", h / 100, h % 100) } // 360 px per unit

fn main() {
    let mut total = 0;
    println!("points  topologies  preorders  T1  Hausdorff  discrete  connected  compact-not-closed  two-limits  T1-not-Hausdorff");
    for n in 1..5u32 {
        let tops = topologies(n);
        let p: Vec<[bool; 6]> = tops.iter().map(|t| props(n, t)).collect();
        let c: Vec<usize> = (0..6).map(|i| p.iter().filter(|x| x[i]).count()).collect();
        let bad = p.iter().filter(|x| x[0] && !x[1]).count();
        println!("{:>6}  {:>10}  {:>9}  {:>2}  {:>9}  {:>8}  {:>9}  {:>18}  {:>10}  {:>16}", n, tops.len(), preorders(n), c[0], c[1], c[5], c[2], c[3], c[4], bad);
        assert!(tops.len() == preorders(n) && bad == 0 && p.iter().all(|x| x[0] == x[5] && x[1] == x[5]));
        assert!(c[2] == [1, 3, 19, 233][n as usize - 1] && c[3] == tops.len() - 1 && c[4] == tops.len() - 1); // known connected counts; all but discrete fail
        total += tops.len();
    }
    println!("T1 but not Hausdorff, searched over all {} topologies on 1 to 4 points: none", total);
    let ind = props(2, &[0, 3]);
    println!("indiscrete on 2 points: open sets {{}} {{a,b}}; {{a}} compact and closed {}; a,a,a,... also converges to b {}; connected {}", py(!ind[3]), py(ind[4]), py(ind[2]));
    assert!(ind[3] && ind[4] && ind[2]);

    let cover: Vec<String> = [10usize, 100, 1000].iter().map(|&n| {
        let balls: BTreeSet<Vec<usize>> = (0..n).map(|k| (0..n).filter(|&m| 2 * ((m != k) as i32) < 1).collect()).collect();
        format!("N={}: {}", n, balls.len())
    }).collect();
    println!("discrete N, d = 1 between different points: balls of radius 1/2 needed to cover the first N points: {}", cover.join(", "));
    let first: Vec<u32> = (0..64u32).flat_map(|f| (0..64u32).map(move |g| (0..8).find(|&k| (f | g) >> k & 1 == 0).unwrap())).collect();
    let inside = (0..64u32).flat_map(|f| (0..64u32).map(move |g| (f, g))).zip(&first)
        .all(|((f, g), &k)| f >> k & 1 == 0 && g >> k & 1 == 0 && k <= f.count_ones() + g.count_ones()); // in both, by |F| + |G|
    println!("cofinite N: {} pairs of open sets missing parts of {{0..5}}, all overlap {}, first shared point at most {}", first.len(), py(inside), first.iter().max().unwrap());
    assert!(inside && *first.iter().max().unwrap() == 6);
    let fs: Vec<u32> = (0..64u32).filter(|&f| f >> 3 & 1 == 0).collect();
    let tails: Vec<u32> = fs.iter().map(|&f| (0..6).filter(|&k| f >> k & 1 == 1).max().map_or(0, |k| k + 1)).collect();
    println!("cofinite N: 0,1,2,... enters each of the {} open sets round 3 that miss part of {{0..5}} by term {}", tails.len(), tails.iter().max().unwrap());
    assert!(fs.iter().zip(&tails).all(|(&f, &t)| (t..100).all(|k| k >= 32 || f >> k & 1 == 0)));

    let pts: Vec<Vec<i64>> = (0..(1usize << L)).map(|i| (0..L).map(|k| 2 * ((i >> (L - 1 - k)) & 1) as i64).collect()).collect();
    let m = pts.len();
    let v: Vec<i64> = pts.iter().map(|a| val(a)).collect();
    let d: Vec<Vec<i64>> = pts.iter().map(|a| pts.iter().map(|b| if a == b { 0 } else { U / 3i64.pow(first_diff(a, b) as u32) }).collect()).collect(); // address distance
    let o: Vec<Vec<i64>> = v.iter().map(|&x| v.iter().map(|&y| (x - y).abs()).collect()).collect(); // ordinary distance
    let (mut strong, mut plain) = (0, 0);
    for i in 0..m { for j in 0..m { for k in 0..m {
        if d[i][k] > d[i][j].max(d[j][k]) { strong += 1; }
        if o[i][k] > o[i][j].max(o[j][k]) { plain += 1; }
    } } }
    println!("Cantor level {}: {} points, {} triples; strong triangle fails for address distance {}, for ordinary distance {}", L, m, m * m * m, strong, plain);
    assert!(strong == 0 && plain > 0);
    let sand = (0..m).all(|i| (0..m).all(|j| i == j || (d[i][j] <= o[i][j] && o[i][j] <= 3 * d[i][j])));
    println!("sandwich d <= |x - y| <= 3d on all {} ordered pairs: {}", m * (m - 1), py(sand));
    assert!(sand);
    let mut ok = 0;
    for i in 0..m { for j in (i + 1)..m {
        let n = first_diff(&pts[i], &pts[j]);
        let mut a = pts[i][..n - 1].to_vec();
        a.resize(L, 0);
        let (pre, t) = (val(&a), 3i64.pow(n as u32));
        let (lo, g, hi) = (pre + U / t, pre + 3 * U / (2 * t), pre + 2 * U / t);
        if v[i] < lo && lo < g && g < hi && hi <= v[j] { ok += 1; }
    } }
    println!("gap between: every one of {} pairs has a deleted gap strictly between its points: {}", m * (m - 1) / 2, py(ok == m * (m - 1) / 2));
    assert!(ok == m * (m - 1) / 2);
    let (x, y, z) = (&pts[0], &pts[16], &pts[24]);
    println!("worked: x={} y={} z={}; first differences n(x,y)={} n(y,z)={} n(x,z)={}", fr(val(x), U), fr(val(y), U), fr(val(z), U), first_diff(x, y), first_diff(y, z), first_diff(x, z));
    println!("worked: d(x,y)={} d(y,z)={} d(x,z)={}; |x-y|={} |y-z|={} |x-z|={}", fr(d[0][16], U), fr(d[16][24], U), fr(d[0][24], U), fr(o[0][16], U), fr(o[16][24], U), fr(o[0][24], U));
    assert!((d[0][24], o[0][24]) == (U / 9, 8 * U / 27) && d[0][24] <= d[0][16].max(d[16][24]) && o[0][24] > o[0][16].max(o[16][24]));
    let g = 3 * U / (2 * 9);
    let left = v.iter().filter(|&&w| w < g).count();
    println!("worked: gap point g={}; level-{} points left of g {}, right of g {}", fr(g, U), L, left, m - left);
    assert!(left == 16 && fr(g, U) == "1/6");
    let near: Vec<String> = (0..L).map(|n| fr(val(&(0..L).map(|k| if k == n { 2 } else { 0 }).collect::<Vec<i64>>()), U)).collect();
    let flip = (0..m).all(|i| o[i][i ^ 1] == 4); // change the last digit: another point 2/729 away
    println!("no isolated point: from 0 the points {}; every level-{} point has another at {}: {}", near.join(" "), L, fr(4, U), py(flip));
    assert!(flip && near[1] == "2/9");

    let (mut state, mut raw) = (2026u64, Vec::new()); // 1000 points of C, 12 digits each, from a 64-bit linear congruential generator
    for _ in 0..12000 {
        state = state.wrapping_mul(6364136223846793005).wrapping_add(1442695040888963407);
        raw.push(2 * (state >> 63) as i64);
    }
    let seq: Vec<&[i64]> = raw.chunks(12).collect();
    let (mut kept, mut sizes, mut prefix): (Vec<usize>, Vec<usize>, Vec<i64>) = ((0..1000).collect(), vec![1000], vec![]);
    for r in 0..8 { // pigeonhole: keep the digit that more terms share
        let zeros: Vec<usize> = kept.iter().copied().filter(|&k| seq[k][r] == 0).collect();
        let twos: Vec<usize> = kept.iter().copied().filter(|&k| seq[k][r] == 2).collect();
        let dig = if zeros.len() >= twos.len() { kept = zeros; 0 } else { kept = twos; 2 };
        prefix.push(dig);
        sizes.push(kept.len());
        assert!(2 * kept.len() >= sizes[sizes.len() - 2] && kept.iter().all(|&k| seq[k][..r + 1] == prefix[..]));
    }
    let v12: Vec<i64> = kept.iter().map(|&k| seq[k].iter().enumerate().map(|(j, &dg)| dg * 3i64.pow(11 - j as u32)).sum()).collect();
    let spread = v12.iter().max().unwrap() - v12.iter().min().unwrap();
    let s: Vec<String> = sizes.iter().map(|x| x.to_string()).collect();
    let p: String = prefix.iter().map(|x| x.to_string()).collect();
    println!("compact by pigeonhole: terms kept {}; shared address 0.{}; kept terms spread {}, bound {}", s.join(" "), p, fr(spread, 3i64.pow(12)), fr(81, 3i64.pow(12)));
    assert!(0 < spread && spread <= 81);

    for lev in 0..4usize {
        let ends: BTreeSet<i64> = (0..(1usize << lev)).map(|i| (0..lev).map(|k| 2 * ((i >> (lev - 1 - k)) & 1) as i64 * 3i64.pow((L - 1 - k) as u32) * 2).sum()).collect();
        let parts: Vec<String> = ends.iter().map(|&e| format!("{}-{}", px(e), px(e + U / 3i64.pow(lev as u32)))).collect();
        println!("figure,level {}, {} pieces of length {}: {}", lev, ends.len(), fr(U / 3i64.pow(lev as u32), U), parts.join(" "));
    }
    println!("figure,x {} y {} z {} g {}", px(val(x)), px(val(y)), px(val(z)), px(g));
    println!("ALL CHECKS PASS");
}
