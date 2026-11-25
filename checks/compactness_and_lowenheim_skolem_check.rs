// Compactness and Lowenheim-Skolem -- the check behind the card.  Rust std only.
// It runs the constructions behind the proofs; every claim about "all" is checked
// on a stated window.  The output matches the Python check line for line.
use std::collections::BTreeSet;

// ---- 1. the axioms c > 0, c > 1, c > 2, ... ----
fn first_fail(c: i64, batch: &[i64]) -> Option<i64> { batch.iter().copied().find(|&n| !(c > n)) } // first axiom c > n broken

// ---- 2. colouring an infinite board: squares touching at a side or a corner clash ----
type Grid = [[u8; 12]; 12]; // square (x, y) lives at [x + 1][y + 1]; 0 means uncoloured
fn ok(g: &Grid, x: usize, y: usize, colour: u8) -> bool { (0..3).all(|dx| (0..3).all(|dy| (dx, dy) == (1, 1) || g[x + dx][y + dy] != colour)) }
fn consistent(g: &Grid) -> bool { (1..11).all(|x| (1..11).all(|y| g[x][y] == 0 || ok(g, x - 1, y - 1, g[x][y]))) }
// count proper k-colourings of the n x n box; with `ext`, count those that extend to n + 1
fn colourings(n: usize, g: &mut Grid, k: u8, ext: bool) -> u64 {
    if !consistent(g) { return 0; }
    let cells: Vec<(usize, usize)> = (0..n).flat_map(|y| (0..n).map(move |x| (x, y))).filter(|&(x, y)| g[x + 1][y + 1] == 0).collect();
    fn go(i: usize, cells: &[(usize, usize)], g: &mut Grid, n: usize, k: u8, ext: bool) -> u64 {
        if i == cells.len() { return if !ext || colourings(n + 1, g, 4, false) > 0 { 1 } else { 0 }; }
        let ((x, y), mut total) = (cells[i], 0);
        for colour in 1..=k {
            if ok(g, x, y, colour) { g[x + 1][y + 1] = colour; total += go(i + 1, cells, g, n, k, ext); g[x + 1][y + 1] = 0; }
        }
        total
    }
    go(0, &cells, g, n, k, ext)
}

// ---- 3. the real algebraic numbers: polynomials by height ----
fn vectors(length: usize, s: i64) -> Vec<Vec<i64>> { // integer vectors, sum of |entries| = s
    if length == 0 { return if s == 0 { vec![vec![]] } else { vec![] }; }
    (-s..=s).flat_map(|a| vectors(length - 1, s - a.abs()).into_iter().map(move |r| [vec![a], r].concat())).collect()
}
fn binom(n: i64, k: i64) -> i64 { if k < 0 || k > n { 0 } else if k == 0 { 1 } else { binom(n - 1, k - 1) * n / k } }
fn n_vectors(length: i64, s: i64) -> i64 { // the same count, by a formula
    if s == 0 { 1 } else { (1..=length).map(|k| binom(length, k) * binom(s - 1, k - 1) * (1i64 << k)).sum() }
}
fn value(p: &[i64], x: f64) -> f64 { p.iter().fold(0.0, |r, &a| r * x + a as f64) } // Horner's rule
fn real_roots(p: &[i64]) -> Vec<f64> { // road 1: sign changes on a 1/64 grid, then halving
    let (bound, mut out) = (p.iter().map(|a| a.abs()).sum::<i64>() + 1, vec![]);
    for i in -64 * bound..64 * bound {
        let (mut a, mut b) = (i as f64 / 64.0, (i + 1) as f64 / 64.0);
        let fa = value(p, a);
        if fa == 0.0 { out.push(a); } else if fa * value(p, b) < 0.0 {
            for _ in 0..60 { let m = (a + b) / 2.0; if (value(p, m) < 0.0) == (fa < 0.0) { a = m; } else { b = m; } }
            out.push((a + b) / 2.0);
        }
    }
    out
}
// road 2, exact integers: Sturm's theorem counts real roots; a gcd strips roots met before
type P = Vec<i128>;
fn gcd(a: i128, b: i128) -> i128 { if b == 0 { a.abs() } else { gcd(b, a % b) } }
fn prim(p: &[i128]) -> P { // leading zeros dropped, common factor divided out
    let p: P = p.iter().copied().skip_while(|&a| a == 0).collect();
    let g = p.iter().fold(0, |g, &a| gcd(g, a)); p.iter().map(|&a| a / g).collect()
}
fn pdm(a: &[i128], b: &[i128]) -> (P, P) { // |lead of b|^k a = q b + r, all in integers
    let (mut q, mut a, s, t): (P, P, i128, i128) = (vec![], a.to_vec(), b[0].abs(), b[0].signum());
    while a.len() >= b.len() {
        q = q.iter().map(|e| s * e).chain([t * a[0]]).collect();
        a = (1..a.len()).map(|i| s * a[i] - t * a[0] * b.get(i).copied().unwrap_or(0)).collect();
    }
    (prim(&q), prim(&a))
}
fn pgcd(a: &[i128], b: &[i128]) -> P { if b.is_empty() { a.to_vec() } else { pgcd(b, &pdm(a, b).1) } }
fn deriv(p: &[i128]) -> P { prim(&(0..p.len() - 1).map(|i| p[i] * (p.len() - 1 - i) as i128).collect::<P>()) }
fn sturm(p: &[i128]) -> i64 { // real roots: sign changes at -infinity minus at +infinity
    let mut seq = vec![p.to_vec(), deriv(p)];
    loop { let r = pdm(&seq[seq.len() - 2], &seq[seq.len() - 1]).1; if r.is_empty() { break; } seq.push(r.iter().map(|a| -a).collect()); }
    let ch = |v: Vec<i128>| v.windows(2).filter(|w| w[0] * w[1] < 0).count() as i64;
    ch(seq.iter().map(|f| if f.len() % 2 == 0 { -f[0].signum() } else { f[0].signum() }).collect()) - ch(seq.iter().map(|f| f[0].signum()).collect())
}
fn wide(p: &[i64]) -> P { p.iter().map(|&a| a as i128).collect() }
fn tuple(p: &[i64]) -> String { format!("({})", p.iter().map(|a| a.to_string()).collect::<Vec<_>>().join(", ")) }

fn main() {
    let batches: Vec<(&str, Vec<i64>)> = vec![("first 10", (0..10).collect()),
        ("first 1000", (0..1000).collect()), ("scattered {3, 17, 999, 123456}", vec![3, 17, 999, 123456])];
    for (name, b) in &batches {
        let c = b.iter().max().unwrap() + 1; // one more than the largest number named
        assert!(first_fail(c, b).is_none() && first_fail(c - 1, b) == Some(c - 1));
        println!("batch {}: witness c = {}, all {} axioms hold", name, c, b.len());
    }
    for c in [0i64, 10, 1000, 123457] { // the whole list in the counting numbers
        let n = first_fail(c, &(0..c + 2).collect::<Vec<i64>>()).unwrap();
        assert_eq!(n, c);
        println!("whole list in the counting numbers: c = {} fails axiom c > {}", c, n);
    }
    // N followed by a copy of the integers Z: element (0, k), k >= 0, or (1, k), any k
    let w: i64 = 50;
    let mut window: Vec<(i64, i64)> = (0..=w).map(|k| (0, k)).collect();
    window.extend((-w..=w).map(|k| (1, k)));
    let nxt = |x: (i64, i64)| (x.0, x.1 + 1); // order: block first, then position
    let (zero, c) = ((0i64, 0i64), (1i64, 0i64));
    assert!(window.iter().all(|&x| nxt(x) != zero));
    let preds = window.iter().filter(|&&x| x != zero && x != (1, -w) // (1, -w): predecessor outside
        && window.iter().filter(|&&y| nxt(y) == x).count() == 1).count();
    assert!(preds == window.len() - 2 && !window.iter().any(|&x| window.iter().any(|&y| x < y && y < nxt(x))));
    let above: Vec<(i64, i64)> = window.iter().copied().filter(|&x| (0..=w).all(|n| (0, n) < x)).collect();
    assert!(above.contains(&c) && above.contains(&(1, -1)) && above.len() as i64 == 2 * w + 1);
    println!("N then Z, window of {} elements: 0 has no predecessor, {} others checked to have one, nothing between x and next(x)", window.len(), preds);
    println!("elements above every numeral 0..{}: {}, including c and c - 1", w, above.len());
    for n in 1..6usize {
        let (count, formula) = (colourings(n, &mut [[0; 12]; 12], 4, false),  if n == 1 { 4 } else { 24 * ((1u64 << (n - 1)) - 1) });
        assert_eq!(count, formula);
        println!("box {}x{}: {} proper 4-colourings (formula 24(2^(n-1) - 1): {})", n, n, count, formula);
    }
    for n in 2..5usize {
        let (ext, all) = (colourings(n, &mut [[0; 12]; 12], 4, true), colourings(n, &mut [[0; 12]; 12], 4, false));
        assert_eq!(ext, all);
        println!("colourings of the {}x{} box that extend to {}x{}: {} of {}", n, n, n + 1, n + 1, ext, all);
    }
    // build the colouring piece by piece: each square takes the smallest colour
    // that still extends to a proper colouring of the box one size larger
    let (big, mut board): (usize, Grid) = (8, [[0; 12]; 12]);
    for size in 1..=big { for y in 0..size { for x in 0..size {
        if board[x + 1][y + 1] != 0 { continue; }
        board[x + 1][y + 1] = (1..=4u8).find(|&k| {
            let mut t = board; t[x + 1][y + 1] = k; colourings(size + 1, &mut t, 4, false) > 0
        }).unwrap();
    } } }
    assert!(consistent(&board));
    assert!((0..big).all(|x| (0..big).all(|y| board[x + 1][y + 1] as usize == 1 + x % 2 + 2 * (y % 2))));
    for y in 0..4 { println!("row {} {}", y, (0..big).map(|x| board[x + 1][y + 1].to_string()).collect::<String>()); }
    println!("{}x{} board built square by square: proper, equal to 1 + (x mod 2) + 2(y mod 2)", big, big);
    let mut trap: Grid = [[0; 12]; 12]; trap[1][1] = 1; trap[2][1] = 2; trap[1][3] = 3;
    let mut safe = trap; safe[1][3] = 1;
    let (t, s) = (colourings(3, &mut trap, 4, false), colourings(3, &mut safe, 4, false));
    assert!(t == 0 && s > 0);
    println!("trap: corner 1, 2 and colour 3 two rows up: {} completions of the 3x3 box; with colour 1 there: {}", t, s);
    let three = colourings(2, &mut [[0; 12]; 12], 3, false); assert_eq!(three, 0);
    println!("3 colours: the 2x2 box has {} colourings, so the board has none", three);
    // height = degree + sum of |coefficients|; finitely many polynomials per height
    let hmax = 8i64;
    let (mut listing, mut found, mut kept, mut total) = (Vec::<f64>::new(), Vec::<(i64, Vec<i64>, i64, i64)>::new(), Vec::<P>::new(), 0i64);
    for h in 2..hmax {
        let mut made = 0;
        for d in 1..h {
            let ps: Vec<Vec<i64>> = vectors(d as usize + 1, h - d).into_iter().filter(|p| p[0] > 0).collect();
            assert_eq!(2 * ps.len() as i64, n_vectors(d + 1, h - d) - n_vectors(d, h - d));
            made += ps.len();
            for p in &ps {
                let mut g = pdm(&wide(p), &pgcd(&wide(p), &deriv(&wide(p)))).0; // each root once
                for k in &kept { g = pdm(&g, &pgcd(&g, k)).0; } // drop roots met before
                let n = if g.len() > 1 { sturm(&g) } else { 0 };
                total += n; if n > 0 { kept.push(g); }
                for r in real_roots(p) {
                    if listing.iter().all(|q| (r - q).abs() > 1e-9) { listing.push(r); found.push((h, p.clone(), total - n, total)); }
                }
            }
        }
        assert_eq!(listing.len() as i64, total, "decimal roots disagree with the exact count");
        println!("height {}: polynomials {}, distinct real roots so far {}", h, made, listing.len());
    }
    for (name, x, m) in [("sqrt 2", 2f64.sqrt(), vec![1i128, 0, -2]), ("golden ratio", (1.0 + 5f64.sqrt()) / 2.0, vec![1, -1, -1]),
                         ("cube root of 2", 2f64.cbrt(), vec![1, 0, 0, -2])] {
        let k = listing.iter().position(|q| (q - x).abs() < 1e-9).unwrap();
        let (h, p, lo, hi) = &found[k];
        assert!(pdm(&wide(p), &m).1.is_empty() && *lo < k as i64 + 1 && k as i64 + 1 <= *hi); // m divides p; k in p's block
        println!("{} = {:.12}: entry {}, height {}, polynomial {}", name, listing[k], k + 1, h, tuple(p));
    }
    let rationals = found.iter().filter(|f| f.1.len() == 2).count();
    let fractions: BTreeSet<(i64, i64)> = (1..hmax).flat_map(|a| (-hmax..hmax).map(move |b| (a, b)))
        .filter(|&(a, b)| a + b.abs() <= hmax - 2).map(|(a, b)| { let g = gcd(a as i128, b as i128) as i64; (-b / g, a / g) }).collect();
    assert_eq!(rationals, fractions.len(), "rational entries are the fractions -b/a with a + |b| <= H - 2");
    println!("{} entries are rational (degree 1): none squares to 2", rationals);
    println!("ALL CHECKS PASS");
}
