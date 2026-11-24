// Schur and van der Waerden -- the same check as the Python, in Rust.  No crates.  Cells count from 0; col[i] is
// cell i's colour; a "triple" lists cells that must not all share one colour.  Road one tries every colouring;
// road two grows colourings one cell at a time, keeping those that dodge.
type T = Vec<[usize; 3]>;
fn every(m: usize, r: usize) -> Vec<Vec<usize>> {                 // all colourings of m cells with r colours
    (0..m).fold(vec![vec![]], |out, _| out.iter().flat_map(|c: &Vec<usize>| (0..r).map(move |k| [c.clone(), vec![k]].concat())).collect())
}
fn mono(col: &[usize], t: &T) -> usize { t.iter().filter(|s| col[s[0]] == col[s[1]] && col[s[1]] == col[s[2]]).count() }
fn brute(m: usize, r: usize, t: &T) -> Vec<usize> {
    (1..=m).map(|n| { let u: T = t.iter().filter(|s| *s.iter().max().unwrap() < n).cloned().collect();
                      every(n, r).iter().filter(|c| mono(c, &u) == 0).count() }).collect()
}
fn go(col: &mut Vec<usize>, m: usize, r: usize, by: &Vec<T>, counts: &mut Vec<usize>) {
    let i = col.len();
    for k in 0..if i < m { r } else { 0 } {
        if !by[i].iter().any(|s| col[s[0]] == k && col[s[1]] == k) { counts[i] += 1; col.push(k); go(col, m, r, by, counts); col.pop(); }
    }
}
fn grow(m: usize, r: usize, t: &T) -> Vec<usize> {               // road two: dodging colourings of cells 0..n-1
    let (mut by, mut counts): (Vec<T>, Vec<usize>) = (vec![vec![]; m], vec![0; m]);
    for s in t { let mut u = *s; u.sort(); by[u[2]].push(u) }
    go(&mut vec![], m, r, &by, &mut counts);
    counts
}
fn schur(m: usize, strict: bool) -> T {
    (1..m).flat_map(|x| (x + strict as usize..=m - x).map(move |y| [x - 1, y - 1, x + y - 1])).collect()
}
fn ap(m: usize) -> T { let mut v = vec![]; for a in 0..m { for d in 1..m { if a + 2 * d < m { v.push([a, a + d, a + 2 * d]) } } } v }
fn lines(n: u32, geo: bool) -> T {                                // 0, 1, 2 fixed; 3 runs 0,1,2; 4 runs 2,1,0
    let (w, mut out): (usize, T) = (if geo { 5 } else { 4 }, vec![]);
    for code in 0..w.pow(n) {
        let p: Vec<usize> = (0..n).map(|i| code / w.pow(i) % w).collect();
        if p.iter().find(|&&o| o > 2) != Some(&3) { continue }     // a line and its reverse are counted once
        let cell = |j: usize| p.iter().enumerate().map(|(i, &o)| 3usize.pow(i as u32) * match o { 3 => j, 4 => 2 - j, _ => o }).sum::<usize>();
        out.push([cell(0), cell(1), cell(2)]);
    }
    out
}
fn last(c: &[usize]) -> usize { (0..c.len()).filter(|&n| c[n] > 0).max().unwrap() + 1 }
fn triangle(col: &[usize]) -> Vec<(usize, usize, usize)> {        // road three: points 0..5, side i-j coloured by j - i
    (0..6).flat_map(|i| (i + 1..6).flat_map(move |j| (j + 1..6).map(move |k| (j - i, k - j, k - i))))
        .filter(|&(x, y, z)| col[x - 1] == col[y - 1] && col[y - 1] == col[z - 1]).collect()
}
fn main() {
    let (col4, cv) = (vec![0, 1, 1, 0], vec![0, 0, 1, 1, 0, 0, 1, 1]);
    println!("Schur: red [1, 4], blue [2, 3]: single-coloured x + y = z on 1..4: {}", mono(&col4, &schur(4, false)));
    let (s_b, s_g) = (brute(5, 2, &schur(5, false)), grow(5, 2, &schur(5, false)));
    println!("2-colourings of 1..n dodging x + y = z, n = 1..5, every colouring tried: {:?}", s_b);
    println!("the same, grown one number at a time: {:?}", s_g);
    let tri = every(5, 2).iter().filter(|c| { let t = triangle(c); !t.is_empty() && t.iter().all(|&(x, y, z)| c[x - 1] == c[y - 1] && c[y - 1] == c[z - 1]) }).count();
    println!("Ramsey road: colourings of 1..5 whose 6 points hold a single-coloured triangle: {} of 32", tri);
    for (k, name) in [(0, "red"), (1, "blue")] {
        let (x, y, z) = triangle(&[col4.clone(), vec![k]].concat())[0];
        println!("add 5 as {}: the triangle gives {} + {} = {}, all {}", name, x, y, z, name);
    }
    let s3 = grow(14, 3, &schur(14, false));
    println!("three colours: longest dodge 1..{}; Ramsey ceiling R(3,3,3) - 2 = 17 - 2 = {}", last(&s3), 17 - 2);
    println!("van der Waerden: red [1, 2, 5, 6], blue [3, 4, 7, 8]: single-coloured progressions on 1..8: {}", mono(&cv, &ap(8)));
    let (w_b, w_g) = (brute(9, 2, &ap(9)), grow(9, 2, &ap(9)));
    println!("2-colourings of 1..n dodging 3-term progressions, n = 1..9, every colouring tried: {:?}", w_b);
    println!("the same, grown one number at a time: {:?}; so W(3; 2) = {}", w_g, w_b.iter().position(|&x| x == 0).unwrap() + 1);
    let (g2, c2, g3, c3) = (lines(2, true), lines(2, false), lines(3, true), lines(3, false));
    let draws = every(9, 2).iter().filter(|c| c.iter().sum::<usize>() == 5 && mono(c, &g2) == 0).count();
    println!("noughts and crosses: lines {}, Hales-Jewett lines {} = 4^2 - 3^2; drawn full boards (5 X, 4 O): {}", g2.len(), c2.len(), draws);
    let (cube_g, cube_c) = (grow(27, 2, &g3)[26], grow(27, 2, &c3)[26]);
    println!("3 x 3 x 3 cube: lines {} = (5^3 - 3^3)/2, 2-colourings dodging them all: {}", g3.len(), cube_g);
    println!("cube: Hales-Jewett lines {} = 4^3 - 3^3, 2-colourings dodging them all: {}", c3.len(), cube_c);
    let sums: Vec<Vec<usize>> = c3.iter().map(|t| t.iter().map(|&c| (0..3).map(|i| c / 3usize.pow(i) % 3).sum()).collect()).collect();
    let ok = sums.iter().filter(|s| s[1] > s[0] && s[1] - s[0] + s[1] == s[2]).count();
    let e = &sums[c3.iter().position(|t| *t == [3, 13, 23]).unwrap()];
    println!("Hales-Jewett lines whose digit sums form a 3-term progression: {} of {}; line (j, 1, j): {:?}", ok, c3.len(), e);
    let weak = grow(10, 2, &schur(10, true));
    println!("mistake, demanding x different from y: longest dodge 1..{}", last(&weak));
    assert!(s_b == s_g && s_b[4] == 0 && s_b[3] == 2 && tri == 32);            // Schur on 1..5: three roads agree
    assert!(w_b == w_g && w_b[8] == 0 && w_b[7] == 6 && mono(&cv, &ap(8)) == 0); // W(3; 2) = 9: two roads agree
    assert!(last(&s3) == 13 && c2.len() == 16 - 9 && g3.len() == (125 - 27) / 2 && cube_g == 0);
    assert!(draws == 16 && cube_c > 0 && ok == c3.len() && last(&weak) == 8);
    println!("ALL CHECKS PASS");
}
