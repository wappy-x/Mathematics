// The adjacency matrix -- the same check as the Python, in Rust.  No crates.  The
// metro: stations A to F, lines A-B B-C C-D D-E E-F F-A and the crossings B-E
// and C-F.  Walk counts come twice over: from multiplying the table of ones and
// zeros out, and from stepping along the neighbour lists, which forms no matrix.
const NAMES: [char; 6] = ['A', 'B', 'C', 'D', 'E', 'F'];
const N: usize = 6;
const EDGES: [(usize, usize); 8] = [(0, 1), (1, 2), (2, 3), (3, 4), (4, 5), (5, 0), (1, 4), (2, 5)];
type Grid = Vec<Vec<i64>>;
fn mul(p: &Grid, q: &Grid) -> Grid {     // road one: each row against each column
    (0..N).map(|i| (0..N).map(|j| (0..N).map(|h| p[i][h] * q[h][j]).sum()).collect()).collect()
}
fn tris(g: &Grid) -> i64 {               // triangles by listing, on any map
    (0..N).map(|a| (a + 1..N).map(|b| (b + 1..N).filter(|&c| g[a][b] == 1 && g[a][c] == 1 && g[b][c] == 1).count() as i64).sum::<i64>()).sum() }
fn routes(i: usize, j: usize, k: usize, nbr: &Vec<Vec<usize>>) -> Vec<String> {
    if k == 0 {                          // road two: every k-line route, written out
        return if i == j { vec![NAMES[i].to_string()] } else { Vec::new() };
    }
    let mut out: Vec<String> = Vec::new();
    for &h in &nbr[i] {
        for t in routes(h, j, k - 1, nbr) { out.push(format!("{}-{}", NAMES[i], t)) }
    }
    out
}
fn nofix(i: usize, j: usize, k: usize, seen: &Vec<usize>, nbr: &Vec<Vec<usize>>) -> i64 {
    if k == 0 { return (i == j) as i64 }         // the same, refusing a station twice
    let mut total = 0;
    for &h in &nbr[i] {
        if !seen.contains(&h) {
            let mut s = seen.clone();
            s.push(h);
            total += nofix(h, j, k - 1, &s, nbr);
        }
    }
    total
}
fn row(v: &[i64]) -> String { v.iter().map(|x| x.to_string()).collect::<Vec<String>>().join(" ") }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn main() {
    let mut a: Grid = vec![vec![0; N]; N];
    for &(u, v) in EDGES.iter() { a[u][v] = 1; a[v][u] = 1 }
    let nbr: Vec<Vec<usize>> = (0..N).map(|u| (0..N).filter(|&v| a[u][v] == 1).collect()).collect();
    let deg: Vec<i64> = (0..N).map(|u| nbr[u].len() as i64).collect();
    let a2 = mul(&a, &a);
    let a3 = mul(&a2, &a);
    let diag2: Vec<i64> = (0..N).map(|u| a2[u][u]).collect();
    let plus: Grid = (0..N).map(|u| (0..N).map(|v| (a[u][v] == 1 || (u.min(v), u.max(v)) == (0, 2)) as i64).collect()).collect();   // plus a line A-C
    let p3 = mul(&mul(&plus, &plus), &plus);
    let (tr2, tr3, tri, trp, trip): (i64, i64, i64, i64, i64) = (diag2.iter().sum(), (0..N).map(|u| a3[u][u]).sum(), tris(&a), (0..N).map(|u| p3[u][u]).sum(), tris(&plus));
    let inc: Vec<Vec<i64>> = EDGES.iter()                       // one row per line
        .map(|&(p, q)| (0..N).map(|v| (v == p || v == q) as i64).collect()).collect();
    let gram: Grid = (0..N).map(|u| (0..N).map(|v| inc.iter().map(|r| r[u] * r[v]).sum()).collect()).collect();
    let plusdeg: Grid = (0..N).map(|u| (0..N).map(|v| a[u][v] + deg[u] * (u == v) as i64).collect()).collect();
    let wait: Grid = (0..N).map(|u| (0..N).map(|v| a[u][v] + (u == v) as i64).collect()).collect();
    let wait3 = mul(&mul(&wait, &wait), &wait);
    let three = routes(0, 5, 3, &nbr);
    let agree = (1..4).all(|k| (0..N).all(|i| (0..N).all(|j|
        routes(i, j, k, &nbr).len() as i64 == [&a, &a2, &a3][k - 1][i][j])));
    println!("metro: {} stations, {} lines; the table A, rows and columns A to F, row sum at the right", N, EDGES.len());
    for u in 0..N { println!("  {}  {}   sum {}", NAMES[u], row(&a[u]), deg[u]) }
    println!("A^2 diagonal: {}, the degrees; trace {} = 2 x {} lines", row(&diag2), tr2, EDGES.len());
    println!("A^2 row A: {} -- the 0 under F is parity, not distance, since A-F is a line", row(&a2[0]));
    println!("A^3 row A: {}", row(&a3[0]));
    println!("three-line routes A to F: {} from the table, {} from the list; the two roads agree for k = 1, 2, 3: {}",
             a3[0][5], three.len(), yn(agree));
    println!("the six: {}", three.join(" "));
    println!("never repeating a station: {}, namely A-B-C-F and A-B-E-F", nofix(0, 5, 3, &vec![0], &nbr));
    println!("trace A^3 = {}, triangles = trace / 6 = {}, by listing {}; plus a line A-C: trace {}, triangles {}, by listing {}",
             tr3, tr3 / 6, tri, trp, trp / 6, trip);
    println!("line-by-station table M: {} rows x {} columns, {} ones, column sums {}",
             EDGES.len(), N, inc.iter().map(|r| r.iter().sum::<i64>()).sum::<i64>(),
             row(&(0..N).map(|v| inc.iter().map(|r| r[v]).sum()).collect::<Vec<i64>>()));
    println!("M transposed times M equals A plus the degrees down the diagonal: {}", yn(gram == plusdeg));
    println!("mistake, squaring cell by cell: (A, F) reads {}, not {}", a[0][5] * a[0][5], a2[0][5]);
    println!("mistake, a 1 down the diagonal to allow waiting: three-line A to F reads {}, not {}", wait3[0][5], a3[0][5]);
    assert!(agree);
    assert!(diag2 == deg && tr2 == 2 * EDGES.len() as i64);
    assert!(gram == plusdeg && tr3 == 6 * tri && trp == 6 * trip);
    assert!(three.len() == 6 && nofix(0, 5, 3, &vec![0], &nbr) == 2 && a2[0][5] == 0 && a[0][5] == 1);
    println!("ALL CHECKS PASS");
}
