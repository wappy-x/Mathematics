// Van Kampen's theorem -- the same check as the Python, in Rust.  No crates.
// A word is a string of loops: a = once round post A, b = once round post B,
// and the capitals A, B are the same loops run backwards (a^-1, b^-1).
use std::collections::BTreeSet;
type Mat = [[i64; 2]; 2];
const I2: Mat = [[1, 0], [0, 1]];

fn inv(c: char) -> char {
    match c { 'a' => 'A', 'A' => 'a', 'b' => 'B', _ => 'b' }
}

fn reduce(word: &str) -> String {               // cancel neighbours like aA until none is left
    let mut out: Vec<char> = Vec::new();
    for c in word.chars() {
        if out.last() == Some(&inv(c)) { out.pop(); } else { out.push(c); }
    }
    out.into_iter().collect()
}

fn reduced_words(n: usize) -> Vec<String> {     // road 1: build every reduced word of length n
    let mut words = vec![String::new()];
    for _ in 0..n {
        let mut next = Vec::new();
        for w in &words {
            for c in "abAB".chars() {
                if w.chars().last() != Some(inv(c)) { next.push(format!("{}{}", w, c)); }
            }
        }
        words = next;
    }
    words
}

fn letter(c: char) -> Mat {                     // road 2: each letter becomes a 2 x 2 matrix
    match c {
        'a' => [[1, 2], [0, 1]], 'A' => [[1, -2], [0, 1]],
        'b' => [[1, 0], [2, 1]], _ => [[1, 0], [-2, 1]],
    }
}

fn mul(p: Mat, q: Mat) -> Mat {
    let mut r = [[0i64; 2]; 2];
    for i in 0..2 { for j in 0..2 { for k in 0..2 { r[i][j] += p[i][k] * q[k][j]; } } }
    r
}

fn matrix(word: &str) -> Mat {
    word.chars().fold(I2, |m, c| mul(m, letter(c)))
}

fn show(m: Mat) -> String {
    format!("[[{}, {}], [{}, {}]]", m[0][0], m[0][1], m[1][0], m[1][1])
}

fn windings(word: &str) -> (i64, i64) {         // net turns round post A and round post B
    let n = |x: char| word.chars().filter(|&c| c == x).count() as i64;
    (n('a') - n('A'), n('b') - n('B'))
}

fn torus_form(word: &str) -> String {           // torus road 1: use ab = ba to move a-letters left
    let mut cs: Vec<char> = word.chars().collect();
    cs.sort_by_key(|&c| c == 'b' || c == 'B');
    reduce(&cs.into_iter().collect::<String>())
}

fn rank(vertices: &[&str], edges: &[(&str, &str)]) -> (i64, i64) {  // road 3: E - V + pieces
    let mut parent: Vec<usize> = (0..vertices.len()).collect();
    let idx = |v: &str| vertices.iter().position(|&x| x == v).unwrap();
    fn find(p: &Vec<usize>, mut v: usize) -> usize { while p[v] != v { v = p[v]; } v }
    for &(u, v) in edges {
        let (ru, rv) = (find(&parent, idx(u)), find(&parent, idx(v)));
        parent[ru] = rv;
    }
    let pieces = (0..vertices.len()).map(|v| find(&parent, v)).collect::<BTreeSet<_>>().len() as i64;
    (edges.len() as i64 - vertices.len() as i64 + pieces, pieces)
}

fn drop(word: &str, letters: &str) -> String {  // pull a post out: its loops become nothing
    reduce(&word.chars().filter(|&c| !letters.contains(c)).collect::<String>())
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let w = "abAB";
    let (wa, wb) = windings(w);
    println!("one post, wound then unwound: aA reduces to '{}', the lead comes free", reduce("aA"));
    println!("two posts, wound then unwound in turn: {} reduces to '{}', length {}", w, reduce(w), reduce(w).len());
    println!("{} net turns round post A and round post B: ({}, {})", w, wa, wb);
    let steps: Vec<String> = (1..5).map(|k| format!("{} {}", &w[..k], show(matrix(&w[..k])))).collect();
    println!("matrix after each letter: {}", steps.join(", "));
    println!("{} as a matrix: {}; the identity: {}", w, show(matrix(w)), yn(matrix(w) == I2));
    println!("pull post A out: {} becomes '{}'; pull post B out: '{}'", w, drop(w, "aA"), drop(w, "bB"));

    let counts: Vec<usize> = (0..5).map(|n| reduced_words(n).len()).collect();
    let formula: Vec<usize> = (1..5).map(|n| 4 * 3usize.pow(n - 1)).collect();
    let ball: Vec<String> = (0..5).flat_map(reduced_words).collect();
    let mats: BTreeSet<Mat> = ball.iter().map(|x| matrix(x)).collect();
    let ids: Vec<&String> = ball.iter().filter(|x| matrix(x) == I2).collect();
    let only_empty = ids.len() == 1 && ids[0].is_empty();
    println!("free group on a, b: reduced words of length 0 to 4: {:?}", counts);
    println!("formula 4 x 3^(L-1) for L = 1 to 4: {:?}", formula);
    println!("words of length at most 4: {}; distinct matrices: {}; only the empty word gives the identity: {}",
             ball.len(), mats.len(), yn(only_empty));

    let v8 = ["x0", "a1", "a2", "b1", "b2"];        // the figure eight as two triangles at x0
    let e8 = [("x0", "a1"), ("a1", "a2"), ("a2", "x0"), ("x0", "b1"), ("b1", "b2"), ("b2", "x0")];
    let keep = |cut: &[(&str, &str)]| -> Vec<(&str, &str)> { e8.iter().filter(|e| !cut.contains(e)).copied().collect() };
    let (rx, _) = rank(&v8, &e8);
    let (ru, _) = rank(&v8, &keep(&[("b1", "b2")]));
    let (rv, _) = rank(&v8, &keep(&[("a1", "a2")]));
    let (rw, pw) = rank(&v8, &keep(&[("a1", "a2"), ("b1", "b2")]));
    println!("figure eight as a graph: V = {}, E = {}, independent loops {}", v8.len(), e8.len(), rx);
    println!("piece U (cut q): {} loop; piece V (cut p): {} loop; overlap: {} loops in {} piece", ru, rv, rw, pw);
    println!("van Kampen: U gives {} letter, V gives {}, the overlap adds no relation: free, rank {}", ru, rv, ru + rv);

    println!("torus: overlap loop read in U = {}, read in V = '' (it bounds the disc), so {} = 1", w, w);
    let within = |n: usize| ball.iter().filter(move |x| x.len() <= n);
    let tor_swap: Vec<usize> = (0..5).map(|n| within(n).map(|x| torus_form(x)).collect::<BTreeSet<_>>().len()).collect();
    let tor_sums: Vec<usize> = (0..5).map(|n| within(n).map(|x| windings(x)).collect::<BTreeSet<_>>().len()).collect();
    let tor_formula: Vec<usize> = (0..5).map(|n| 2 * n * n + 2 * n + 1).collect();
    let free_ball: Vec<usize> = (0..5).map(|n| counts[..=n].iter().sum()).collect();
    println!("torus, {} by swaps: '{}'; abaB stays '{}' in the free group, by swaps on the torus: '{}'",
             w, torus_form(w), reduce("abaB"), torus_form("abaB"));
    println!("torus elements within L letters, L = 0 to 4, by swaps: {:?}", tor_swap);
    println!("the same, by net turns: {:?}; formula 2L^2 + 2L + 1: {:?}", tor_sums, tor_formula);
    println!("free group within L letters, L = 0 to 4: {:?}", free_ball);

    let vc = ["x0", "y", "z"];
    let ec = [("x0", "y"), ("y", "z"), ("z", "x0")];
    let (rc, _) = rank(&vc, &ec);                    // the whole circle
    let (rcu, _) = rank(&vc, &[ec[0], ec[2]]);       // U: cut a point on y-z
    let (rcv, _) = rank(&vc, &ec[..2]);              // V: cut a point on z-x0
    let (_, pc) = rank(&vc, &ec[..1]);               // overlap: both cuts
    println!("mistake 1, circle cut into two arcs: overlap in {} pieces; naive answer {} + {} = {} letters, the trivial group; true rank {}, the integers",
             pc, rcu, rcv, rcu + rcv, rc);
    println!("mistake 2, product instead of free product: {} has net turns ({}, {}) and would be 1; its matrix {} says it is not",
             w, wa, wb, show(matrix(w)));
    println!("mistake 3, torus with its relation forgotten: {} elements within 2 letters, true {}", free_ball[2], tor_swap[2]);
    println!("mistake 4, letters never cancelled: {} strings within 2 letters, true {}", 1 + 4 + 16, free_ball[2]);
    println!("figure, circles centred (120, 110) and (300, 110), radius 90, x0 = (210, 110), p = (30, 110), q = (390, 110)");
    assert!(counts[1..] == formula[..] && mats.len() == ball.len() && ball.len() == 161 && only_empty);
    assert!((wa, wb) == (0, 0) && matrix(w) != I2 && reduce(w) == w);
    assert!(rx == ru + rv && rx == 2 && rw == 0 && pw == 1);
    assert!(tor_swap == tor_sums && tor_sums == tor_formula && torus_form(w).is_empty());
    assert!(rc == 1 && rcu + rcv == 0 && pc == 2);
    println!("ALL CHECKS PASS");
}
