// Linear independence -- the same check as the Python, in Rust.  No crates.
// Fertiliser bag A = (10, 5), bag B = (2, 8) and a third blend C = (12, 13),
// counted in kg of nitrogen and kg of phosphorus.  Is any one of the three
// already a mix of the other two?
const A: (i64, i64) = (10, 5);
const B: (i64, i64) = (2, 8);
const C: (i64, i64) = (12, 13);

fn mix(x: i64, y: i64, z: i64) -> (i64, i64) {        // x bags of A, y of B, z of C
    (x * A.0 + y * B.0 + z * C.0, x * A.1 + y * B.1 + z * C.1)
}

fn cross(u: (i64, i64), v: (i64, i64)) -> i64 { u.0 * v.1 - v.0 * u.1 }

fn eliminate(z: i64) -> (f64, f64) {                  // road one: fix z, solve the two slots
    let f = A.1 as f64 / A.0 as f64;                  // scale the nitrogen row by this to kill x
    let (r0, r1) = ((-z * C.0) as f64, (-z * C.1) as f64);   // what the C bags leave on the right
    let y = (r1 - f * r0) / (B.1 as f64 - f * B.0 as f64);
    let x = (r0 - B.0 as f64 * y) / A.0 as f64;       // back-substitute
    (x, y)
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let t = a % b; a = b; b = t; }
    a.abs()
}

fn term(k: i64, name: &str) -> String {               // "+ 1 x B" or "- 1 x C"
    format!("{} {} x {}", if k >= 0 { "+" } else { "-" }, k.abs(), name)
}

fn tup(v: (i64, i64)) -> String { format!("({}, {})", v.0, v.1) }

fn join(vs: &[(i64, i64)], slot: usize) -> String {
    let parts: Vec<String> = vs.iter()
        .map(|v| if slot == 0 { v.0.to_string() } else { v.1.to_string() }).collect();
    parts.join(", ")
}

fn main() {
    println!("bag A = {}, bag B = {}, bag C = {}, in kg of nitrogen and kg of phosphorus",
             tup(A), tup(B), tup(C));
    println!("the cross-numbers: A with B = {}, A with C = {}, B with C = {}",
             cross(A, B), cross(A, C), cross(B, C));
    let (x1, y1) = eliminate(-1);
    println!("road one, elimination on the two slots: x = {:.4}, y = {:.4}, z = -1.0000", x1, y1);
    let (mut n, mut m, mut p) = (cross(B, C), cross(C, A), cross(A, B));  // road two: the exact relation
    let g = gcd(gcd(n, m), p);
    n /= g; m /= g; p /= g;
    if n < 0 { n = -n; m = -m; p = -p; }
    println!("road two, from the cross-numbers:       x = {}, y = {}, z = {}", n, m, p);
    let r = mix(n, m, p);
    println!("the relation rebuilt: {} x A {} {} = {} -> A, B, C are dependent",
             n, term(m, "B"), term(p, "C"), tup(r));
    println!("C is one bag of A plus one bag of B: 1 x A + 1 x B = {}", tup(mix(1, 1, 0)));
    let (x0, y0) = eliminate(0);
    println!("the pair A and B alone: cross-number {}, and the only mix landing on (0, 0) is x = {:.4}, y = {:.4}",
             cross(A, B), x0, y0);
    let trio: Vec<(i64, i64)> = (0..4).map(|t| mix(t, t, -t)).collect();
    let pair: Vec<(i64, i64)> = (0..4).map(|t| mix(t, t, 0)).collect();
    println!("left over from t bags of A, t of B and t of C taken back out, t = 0, 1, 2, 3");
    println!("  nitrogen, kg     {}", join(&trio, 0));
    println!("  phosphorus, kg   {}", join(&trio, 1));
    println!("left over from t bags of A and t of B, no C, t = 0, 1, 2, 3");
    println!("  nitrogen, kg     {}", join(&pair, 0));
    println!("  phosphorus, kg   {}", join(&pair, 1));
    println!("the two mistakes come out at {} for the all-zero mix and {} for all three added",
             tup(mix(0, 0, 0)), tup(mix(1, 1, 1)));
    println!("dropping A instead of C: the cross-number of B and C is {}, still not zero", cross(B, C));
    assert!((n, m, p) == (1, 1, -1) && r == (0, 0) && mix(1, 1, 0) == (12, 13));
    assert!((x1 - 1.0).abs() < 1e-12 && (y1 - 1.0).abs() < 1e-12 && x0 == 0.0 && y0 == 0.0);
    assert!((cross(A, B), cross(A, C), cross(B, C)) == (70, 70, -70) && mix(1, 1, 1) == (24, 26));
    assert!(join(&trio, 0) == "0, 0, 0, 0" && join(&pair, 0) == "0, 12, 24, 36");
    println!("ALL CHECKS PASS");
}
