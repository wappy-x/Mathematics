// Linear equations -- the same check as the Python, in Rust.  No crates.  A taxi
// charges $3 to start plus $2 a mile, so the fare in dollars is 3 + 2m.  Every
// equation here is solved by undoing: subtract the 3 from both sides, then
// halve both sides.  A second road builds an equation from an answer picked
// first, then solves it back and must land on the answer it started from.
const A: f64 = 2.0; // $2 a mile
const B: f64 = 3.0; // $3 to start: fare = A*m + B

enum Sol { One(f64), Every, None }          // what solving an equation can hand back

fn fare(m: f64) -> f64 { A * m + B }        // the recipe, run forwards

fn solve(a: f64, b: f64, c: f64) -> Sol {   // a*x + b = c, undone in reverse order
    if a == 0.0 {                           // the unknown has vanished from both sides
        if b == c { Sol::Every } else { Sol::None }
    } else {
        Sol::One((c - b) / a)               // subtract b from both sides, then divide by a
    }
}

fn x(s: Sol) -> f64 {                       // the one answer, when there is exactly one
    match s { Sol::One(v) => v, _ => panic!("expected one answer") }
}

fn n(v: f64) -> String { format!("{}", v) } // 6.0 prints as 6, 4.5 as 4.5

fn grid(name: &str, values: &[String]) {
    let mut line = format!("{:<32}", name);
    for v in values { line.push_str(&format!("{:>5}", v)); }
    println!("{}", line);
}

fn main() {
    let miles: Vec<f64> = (0..=10).map(|m| m as f64).collect();
    grid("miles m", &miles.iter().map(|m| n(*m)).collect::<Vec<String>>());
    grid("fare 3 + 2m, in dollars", &miles.iter().map(|m| n(fare(*m))).collect::<Vec<String>>());
    grid("the $15 target", &miles.iter().map(|_| n(15.0)).collect::<Vec<String>>());
    for c in [15.0, 45.0] {                 // one road: undo the two steps
        let m = x(solve(A, B, c));
        println!("2m + 3 = {}  ->  subtract 3: 2m = {},  halve: m = {},  check: 3 + 2({}) = {}",
                 n(c), n(c - B), n(m), n(m), n(fare(m)));
    }
    for want in [6.0, 21.0] {               // second road: build it from a known answer
        println!("built from a known answer: m = {} gives fare {}, solved back to m = {}",
                 n(want), n(fare(want)), n(x(solve(A, B, fare(want)))));
    }
    let limit = x(solve(A, B, 15.0));
    println!("staying under $15: 2m + 3 < 15  ->  m < {}; at m = 5 the fare is {}, at m = 7 it is {}",
             n(limit), n(fare(5.0)), n(fare(7.0)));
    let flip = x(solve(-A, 0.0, -12.0));    // 12 - 2m > 0 becomes -2m > -12
    println!("money left out of $15: 12 - 2m > 0  ->  -2m > -12  ->  m < {} after the flip", n(flip));
    let no_answer = matches!(solve(0.0, 3.0, 5.0), Sol::None);  // 3 + 2m = 5 + 2m
    let every = matches!(solve(0.0, 0.0, 0.0), Sol::Every);     // 3 + m + m = 3 + 2m
    println!("3 + 2m = 5 + 2m  ->  3 = 5, false: no answer");
    println!("3 + m + m = 3 + 2m  ->  0 = 0, true: every number works");
    let halved_first = 15.0 / A - B;        // halving before the 3 comes off
    let one_side = 15.0 / A;                // the 3 taken off the left side only
    println!("the three mistakes come out at {}, {} and m > 6", n(halved_first), n(one_side));
    assert!(x(solve(A, B, 15.0)) == 6.0 && x(solve(A, B, 45.0)) == 21.0);
    assert!(x(solve(A, B, fare(6.0))) == 6.0 && x(solve(A, B, fare(21.0))) == 21.0);
    assert!(no_answer && every && flip == 6.0);
    assert!(fare(5.0) == 13.0 && fare(7.0) == 17.0 && halved_first == 4.5 && one_side == 7.5);
    println!("ALL CHECKS PASS");
}
