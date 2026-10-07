// Linear combinations and span -- the same check as the Python, in Rust.  No
// crates.  Fertiliser bag A = (10, 5) and bag B = (2, 8), counted in kg of
// nitrogen and kg of phosphorus.  Which targets can a mix of the two bags hit?
const A: (i64, i64) = (10, 5);
const B: (i64, i64) = (2, 8);
const C: (i64, i64) = (20, 10);         // C is two bags of A, so no new direction

fn mix_i(x: i64, y: i64) -> (i64, i64) { (x * A.0 + y * B.0, x * A.1 + y * B.1) }

fn mix_f(x: f64, y: f64) -> (f64, f64) {          // x bags of A plus y bags of B
    (x * A.0 as f64 + y * B.0 as f64, x * A.1 as f64 + y * B.1 as f64)
}

fn cross(u: (i64, i64), v: (i64, i64)) -> i64 { u.0 * v.1 - v.0 * u.1 }

fn eliminate(t: (i64, i64)) -> (f64, f64) {       // road one: elimination, in decimals
    let f = A.1 as f64 / A.0 as f64;              // scale the nitrogen row by this to kill x
    let y = (t.1 as f64 - f * t.0 as f64) / (B.1 as f64 - f * B.0 as f64);
    let x = (t.0 as f64 - B.0 as f64 * y) / A.0 as f64;   // back-substitute
    (x, y)
}

fn gcd(mut a: i64, mut b: i64) -> i64 {
    while b != 0 { let t = a % b; a = b; b = t; }
    a.abs()
}

fn frac(n: i64, d: i64) -> String {               // a whole-number fraction, tidied
    let g = gcd(n, d);
    let (n, d) = (n / g, d / g);
    if d == 1 { format!("{}", n) } else { format!("{}/{}", n, d) }
}

fn rule(t: (i64, i64)) -> (i64, i64) { (cross(t, B), cross(A, t)) }   // over cross(A, B)

fn tup(v: (i64, i64)) -> String { format!("({}, {})", v.0, v.1) }

fn main() {
    let d = cross(A, B);
    println!("bag A = {} and bag B = {}, in kg of nitrogen and kg of phosphorus", tup(A), tup(B));
    println!("{:<52}{:>10}", "the cross-number of A and B", d);
    for t in [(14_i64, 21_i64), (14, 22)] {
        let (x, y) = eliminate(t);
        let (nx, ny) = rule(t);
        let g = mix_f(x, y);
        println!("target {}: elimination gives x = {:.4}, y = {:.4}", tup(t), x, y);
        println!("target {}: the cross-number rule gives x = {}, y = {}", tup(t), frac(nx, d), frac(ny, d));
        println!("target {}: rebuilt, {:.4} x A + {:.4} x B = ({:.4}, {:.4}) -> in the span",
                 tup(t), x, y, g.0, g.1);
    }
    let grid: Vec<(i64, i64)> = (0..4).map(|b| mix_i(1, b)).collect();
    println!("one bag of A with 0, 1, 2 and 3 bags of B");
    let n: Vec<String> = grid.iter().map(|p| p.0.to_string()).collect();
    let p: Vec<String> = grid.iter().map(|p| p.1.to_string()).collect();
    println!("  nitrogen, kg    {}", n.join(", "));
    println!("  phosphorus, kg  {}", p.join(", "));
    println!("bag C = {} is two bags of A: the cross-number of A and C is {}", tup(C), cross(A, C));
    let (m1, m2, m3) = (mix_f(1.4, 0.0), mix_i(1, 1), mix_i(2, 1));
    println!("the three mistakes come out at ({:.4}, {:.4}), {} and {}", m1.0, m1.1, tup(m2), tup(m3));
    assert!(rule((14, 21)) == (70, 140) && d == 70);   // 14x8-2x21, 10x21-14x5, 10x8-2x5
    assert!(rule((14, 22)) == (68, 150) && cross(A, C) == 0);
    assert!((eliminate((14, 21)).0 - 1.0).abs() < 1e-12 && (eliminate((14, 21)).1 - 2.0).abs() < 1e-12);
    assert!(m2 == (12, 13) && m3 == (22, 18) && (m1.0 - 14.0).abs() < 1e-9 && (m1.1 - 7.0).abs() < 1e-9);
    println!("ALL CHECKS PASS");
}
