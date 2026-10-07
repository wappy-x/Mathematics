// Groups -- the same check as the Python, in Rust.  No crates.  A square tile
// sits eight ways.  A move is a pair (sign, shift): it sends corner i to
// sign*i + shift, wrapped at 4, with sign 1 for a turn and sign -1 for a flip.
// Road one combines two moves by that arithmetic; road two pushes each corner
// through the two moves one after the other.  Road two never uses road one's formula.
const TURNS: i32 = 4;
type Move = (i32, i32);

fn compose(a: Move, b: Move) -> Move {      // road one: arithmetic on the pairs, b first
    (a.0 * b.0, (a.0 * b.1 + a.1).rem_euclid(TURNS))
}

fn homes(a: Move) -> Vec<i32> {             // where move a sends corners 0, 1, 2, 3
    (0..TURNS).map(|i| (a.0 * i + a.1).rem_euclid(TURNS)).collect()
}

fn through(a: Move, b: Move) -> Vec<i32> {   // road two: corner by corner, b first
    let landing = homes(a);
    homes(b).iter().map(|&j| landing[j as usize]).collect()
}

fn name(a: Move) -> String {                // r2f means flip first, then two turns
    format!("r{}{}", a.1, if a.0 == -1 { "f" } else { "" })
}

fn row(values: &[i32]) -> String {
    values.iter().map(|v| v.to_string()).collect::<Vec<String>>().join(" ")
}

fn main() {
    let moves: Vec<Move> = [1, -1].iter().flat_map(|&s| (0..TURNS).map(move |k| (s, k))).collect();
    let (e, r, f) = ((1, 0), (1, 1), (-1, 0));
    for &a in &moves {
        println!("move {:<3} is (sign {:>2}, shift {}) and sends corners 0 1 2 3 to: {}",
                 name(a), a.0, a.1, row(&homes(a)));
    }
    let (mut inside, mut agree) = (0, 0);
    for &a in &moves {
        for &b in &moves {
            if moves.contains(&compose(a, b)) { inside += 1; }
            if homes(compose(a, b)) == through(a, b) { agree += 1; }
        }
    }
    println!("closure: of {} pairs of the {} moves, {} land inside and {} agree with the \
              corner-by-corner road", moves.len() * moves.len(), moves.len(), inside, agree);
    let mut triples = 0;
    let mut same = 0;
    for &a in &moves {
        for &b in &moves {
            for &c in &moves {
                triples += 1;
                if compose(compose(a, b), c) == compose(a, compose(b, c)) { same += 1; }
            }
        }
    }
    println!("associativity: of {} triples, {} regroup to the same move", triples, same);
    let (tf, ft) = (compose(f, r), compose(r, f));
    println!("turn then flip: {}, sending corner 0 to {}", name(tf), homes(tf)[0]);
    println!("flip then turn: {}, sending corner 0 to {}", name(ft), homes(ft)[0]);
    let undo_r = *moves.iter().find(|&&b| compose(r, b) == e && compose(b, r) == e).unwrap();
    println!("undo of one quarter turn: {}; flip twice: {}", name(undo_r), name(compose(f, f)));
    let undo_7 = (0..12).find(|b| (7 + b) % 12 == 0).unwrap();
    println!("integers: 3 + (-3) = {}; clock: 9 + 5 on a 12-hour clock = {}, and the undo \
              of 7 is {}", 3 + (-3), (9 + 5) % 12, undo_7);
    let inv7: Vec<i32> = (1..7).map(|a| (1..7).find(|b| a * b % 7 == 1).unwrap()).collect();
    println!("mod 7 undo list for 1 2 3 4 5 6: {}", row(&inv7));
    let zeros: Vec<i32> = (0..7).map(|b| (0 * b) % 7).collect();
    println!("mod 7 with 0 kept: 0 times 0 1 2 3 4 5 6 gives {}, never 1", row(&zeros));
    let leak: Vec<Move> = (1..6).flat_map(|a| (1..6).map(move |b| (a, b)))
        .filter(|(a, b)| a * b % 6 == 0).collect();
    println!("mod 6 without 0: {} times {} = {}, outside the set",
             leak[0].0, leak[0].1, leak[0].0 * leak[0].1 % 6);
    let shapes: std::collections::HashSet<Vec<i32>> = moves.iter().map(|&a| homes(a)).collect();
    assert!(homes(r) == vec![1, 2, 3, 0] && homes(f) == vec![0, 3, 2, 1]);
    assert!(shapes.len() == 8 && inside == 64 && agree == 64 && same == 512);
    assert!(moves.iter().all(|&a| compose(e, a) == a && compose(a, e) == a)
        && moves.iter().all(|&a| moves.iter().any(|&b| compose(a, b) == e && compose(b, a) == e)));
    assert!(tf == (-1, 3) && ft == (-1, 1) && inv7 == vec![1, 4, 5, 2, 3, 6] && leak[0] == (2, 3));
    println!("ALL CHECKS PASS");
}
