// Lattice paths -- the same check as the Python, in Rust.  No crates.  A museum stands 7 blocks
// east and 4 blocks north of a hotel, and a walk steps east or north only.  The 330 routes are
// counted three ways that share no arithmetic: a choose formula, a listing of every order of the
// steps, and a map of corner counts built by addition alone.
const EAST: i64 = 7;
const NORTH: i64 = 4;
const CAFE: (i64, i64) = (3, 2);
const STEPS: i64 = EAST + NORTH;
const CUT: i64 = CAFE.0 + CAFE.1;           // CUT: blocks walked to the cafe
fn choose(n: i64, k: i64) -> i64 {          // C(n, k), built from a running product
    let mut out: i64 = if 0 <= k && k <= n { 1 } else { 0 };
    for i in 0..k.max(0) { out = out * (n - i) / (i + 1) }
    out
}
fn every_walk(east: i64, north: i64) -> Vec<Vec<i64>> {   // road two: every order of the steps
    let steps = east + north;                             // bit set = north, bit clear = east
    let mut out = Vec::new();
    for c in 0..(1i64 << steps) {
        let walk: Vec<i64> = (0..steps).map(|i| (c >> i) & 1).collect();
        if walk.iter().sum::<i64>() == north { out.push(walk) }
    }
    out
}
fn corners(walk: &[i64]) -> Vec<(i64, i64)> {   // the corners one route stands on
    let (mut e, mut n, mut out) = (0, 0, vec![(0, 0)]);
    for &s in walk { if s == 1 { n += 1 } else { e += 1 }; out.push((e, n)) }
    out
}
fn by_addition(east: i64, north: i64) -> Vec<Vec<i64>> {  // west neighbour plus south neighbour
    let mut g = vec![vec![1i64; (east + 1) as usize]; (north + 1) as usize];
    for b in 1..=north as usize {
        for a in 1..=east as usize { g[b][a] = g[b][a - 1] + g[b - 1][a] }
    }
    g
}
fn main() {
    let routes = every_walk(EAST, NORTH);
    let (listed, formula) = (routes.len() as i64, choose(STEPS, NORTH));
    let grid = by_addition(EAST, NORTH);
    let grid_f: Vec<Vec<i64>> = (0..=NORTH).map(|b| (0..=EAST).map(|a| choose(a + b, b)).collect()).collect();
    let (west_in, south_in) = (grid[NORTH as usize][(EAST - 1) as usize], grid[(NORTH - 1) as usize][EAST as usize]);
    let (to_cafe, from_cafe) = (choose(CUT, CAFE.1), choose(STEPS - CUT, NORTH - CAFE.1));
    let product = to_cafe * from_cafe;
    let through = routes.iter().filter(|w| corners(w).contains(&CAFE)).count() as i64;
    let avoid = routes.iter().filter(|w| !corners(w).contains(&CAFE)).count() as i64;
    let diag: Vec<(i64, i64)> = (0..=NORTH).map(|b| (CUT - b, b)).collect();
    let terms: Vec<i64> = (0..=NORTH).map(|b| choose(CUT, b) * choose(STEPS - CUT, NORTH - b)).collect();
    let seen_diag: Vec<i64> = diag.iter().map(|c| routes.iter().filter(|w| corners(w).contains(c)).count() as i64).collect();
    let whole_map: i64 = (0..=NORTH).map(|b| (0..=EAST)
        .map(|a| choose(a + b, b) * choose(STEPS - a - b, NORTH - b)).sum::<i64>()).sum();
    let ordered = { let mut p = 1i64; for i in 0..NORTH { p *= STEPS - i } p };   // north steps labelled
    let (square, sq) = (every_walk(5, 5), choose(10, 5));
    let never = square.iter().filter(|w| corners(w).iter().all(|&(e, n)| e >= n)).count() as i64;
    println!("hotel to museum: {} blocks east, {} north, {} steps in all", EAST, NORTH, STEPS);
    println!("routes: formula C({},{}) = {}; listing {} of {} step orders", STEPS, NORTH, formula, listed, 1i64 << STEPS);
    println!("routes to each corner, by addition alone (east 0 at the left):");
    for b in (0..=NORTH as usize).rev() {
        let mut line = format!("n={} |", b);
        for v in &grid[b] { line.push_str(&format!("{:>7}", v)) }
        println!("{}", line);
    }
    println!("the same map from the formula: {}", if grid == grid_f { "yes" } else { "no" });
    println!("last step into the museum: {} from the west + {} from the south = {}", west_in, south_in, formula);
    println!("the cafe at ({},{}): {} routes to it x {} on = {}; by listing: {}", CAFE.0, CAFE.1, to_cafe, from_cafe, product, through);
    println!("routes avoiding the cafe: {} - {} = {}; by listing: {}", formula, product, formula - product, avoid);
    let cells: Vec<String> = diag.iter().zip(&terms).map(|(&(a, b), t)| format!("({},{}) {}", a, b, t)).collect();
    println!("the diagonal {} blocks out: {}", CUT, cells.join(", "));
    let counted: Vec<String> = seen_diag.iter().map(|c| c.to_string()).collect();
    println!("those five add to {}; by listing: {}", terms.iter().sum::<i64>(), counted.join(", "));
    println!("mistake 1, the north steps taken as ordered picks: {}, not {}", ordered, formula);
    println!("mistake 2, the cafe halves added: {} + {} = {}, not {}", to_cafe, from_cafe, to_cafe + from_cafe, product);
    println!("mistake 3, through-counts added over all {} corners: {} = {} x {}", (EAST+1)*(NORTH+1), whole_map, STEPS + 1, formula);
    println!("a square grid, 5 by 5: C(10,5) = {}, by listing {}; {} never cross the diagonal", sq, square.len(), never);
    assert!(formula == listed && sq == square.len() as i64 && never == sq - choose(10, 4));   // listings vs formulas
    assert!(grid == grid_f);                                   // addition against the formula
    assert!(through == product && avoid == formula - product);
    assert!(seen_diag == terms && terms.iter().sum::<i64>() == listed);
    println!("ALL CHECKS PASS");
}
