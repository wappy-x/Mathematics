// Diagonalisation -- the same check as the Python, in Rust.  No crates.  A rental
// fleet shuffles between two cities each month under A = [[0.8, 0.3], [0.2, 0.7]]
// and 1,000 cars start in city A.  Road one multiplies A by itself, month after
// month.  Road two builds A^n as P D^n P inverse: three multiplications.  The
// hand formulas 600 + 400 x 0.5^n and 400 - 400 x 0.5^n are a third road.
type M = [[f64; 2]; 2];
type V = [f64; 2];
const A: M = [[0.8, 0.3], [0.2, 0.7]];
const P: M = [[3.0, 1.0], [2.0, -1.0]];
const PINV: M = [[0.2, 0.2], [0.4, -0.6]];
const ID: M = [[1.0, 0.0], [0.0, 1.0]];
const START: V = [1000.0, 0.0];
fn mul(m: M, k: M) -> M {                   // 2 by 2 matrix times 2 by 2 matrix
    let mut o = [[0.0; 2]; 2];
    for i in 0..2 { for j in 0..2 { o[i][j] = m[i][0] * k[0][j] + m[i][1] * k[1][j]; } }
    o
}
fn act(m: M, v: V) -> V {                   // matrix times a column of two numbers
    [m[0][0] * v[0] + m[0][1] * v[1], m[1][0] * v[0] + m[1][1] * v[1]]
}
fn dpow(n: i32) -> M { [[1.0, 0.0], [0.0, 0.5f64.powi(n)]] }  // D^n: 1 stays, 0.5 halves
fn three(p: M, d: M, q: M) -> M { mul(mul(p, d), q) }         // p times d times q
fn gap(m: M, k: M) -> f64 {                 // largest entry-by-entry difference
    let mut e = 0.0f64;
    for i in 0..2 { for j in 0..2 { e = e.max((m[i][j] - k[i][j]).abs()); } }
    e
}
fn pair(v: V) -> String { format!("({:.6}, {:.6})", v[0], v[1]) }
fn grid(name: &str, vals: &[String]) {
    let mut line = format!("{:<27}", name);
    for v in vals { line.push_str(&format!("{:>8}", v)); }
    println!("{}", line);
}
fn city(counts: &[V], j: usize) -> Vec<String> {
    (0..13).map(|n| format!("{:.2}", counts[n][j])).collect()
}
fn main() {
    let mut power = vec![ID];               // month 0: the do-nothing matrix
    for _ in 0..12 { let next = mul(A, power[power.len() - 1]); power.push(next); }
    let slow: Vec<V> = (0..13).map(|n| act(power[n], START)).collect();
    let fast: Vec<V> = (0..13).map(|n| act(three(P, dpow(n as i32), PINV), START)).collect();
    let hand: Vec<V> = (0..13)
        .map(|n| [600.0 + 400.0 * 0.5f64.powi(n), 400.0 - 400.0 * 0.5f64.powi(n)]).collect();
    let w = act(PINV, START);           // the start, read in eigenvector amounts
    let steady: V = [P[0][0] * w[0], P[1][0] * w[0]];
    let fade: V = [P[0][1] * w[1], P[1][1] * w[1]];
    let shear: M = [[1.0, 1.0], [0.0, 1.0]];
    let mut spow = ID;
    for _ in 0..12 { spow = mul(shear, spow); }   // the shear, twelve months of it
    let rows: M = [[3.0, 2.0], [1.0, -1.0]]; let rinv: M = [[0.2, 0.4], [0.2, -0.6]];
    let swap: M = [[1.0, 3.0], [-1.0, 2.0]]; let sinv: M = [[0.4, -0.6], [0.2, 0.2]];
    let wrong = [act(three(rows, dpow(12), rinv), START), act(three(P, dpow(12), P), START),
                 act(three(P, dpow(1), PINV), START), act(three(swap, dpow(12), sinv), START)];
    let labels = ["eigenvectors as rows of P", "P where P inverse belongs",
                  "D left at the first power", "P columns swapped, D not"];
    println!("fleet matrix A = [[0.8, 0.3], [0.2, 0.7]], start (1000, 0) cars");
    println!("eigenvectors (3, 2) and (1, -1); eigenvalues 1 and 0.5");
    println!("P = [[3, 1], [2, -1]], D = [[1, 0], [0, 0.5]], P inverse = [[0.2, 0.2], [0.4, -0.6]]");
    println!("P D P inverse rebuilds A: largest entry gap {:.12}", gap(three(P, dpow(1), PINV), A));
    println!("eigenvector amounts, P inverse times (1000, 0): {} = {:.0} x (3, 2) + {:.0} x (1, -1) \
              = {} + {}", pair(w), w[0], w[1], pair(steady), pair(fade));
    grid("month", &(0..13).map(|n| n.to_string()).collect::<Vec<String>>());
    grid("city A, twelve multiplies", &city(&slow, 0));
    grid("city B, twelve multiplies", &city(&slow, 1));
    grid("city A, three multiplies", &city(&fast, 0));
    grid("city B, three multiplies", &city(&fast, 1));
    println!("hand formula, city A at months 1, 6 and 12: {:.6}, {:.6}, {:.6}; \
              city B at month 12: {:.6}", hand[1][0], hand[6][0], hand[12][0], hand[12][1]);
    println!("month 12 in full: {}; city A to one decimal = {:.1} cars", pair(fast[12]), fast[12][0]);
    for (name, v) in labels.iter().zip(wrong.iter()) {
        println!("mistake, {:<26}{}", name, pair(*v));
    }
    println!("shear [[1, 1], [0, 1]] to the 12th = [[1, {:.0}], [0, 1]], \
              eigenvectors only along (1, 0)", spow[0][1]);
    assert!(gap(three(P, dpow(1), PINV), A) < 1e-12);
    assert!((0..13).all(|n| gap(three(P, dpow(n), PINV), power[n as usize]) < 1e-12));
    assert!((0..13).all(|n| (0..2).all(|j| (fast[n][j] - hand[n][j]).abs() < 1e-9)));
    assert!(spow == [[1.0, 12.0], [0.0, 1.0]] && act(shear, [1.0, 0.0]) == [1.0, 0.0] && act(shear, [1.0, 1.0]) == [2.0, 1.0]);
    println!("ALL CHECKS PASS");
}
