// Adjunctions -- the same check as the Python, in Rust.  No crates.
// Free groups against forgetting: a homomorphism out of the free group on the
// letters a, b is the same thing as a choice of where a and b go.  The target
// is the tile group: the 8 ways a square tile fits its recess, written as
// permutations of the corners 0, 1, 2, 3.  Then a Galois connection on numbers.
type P = [usize; 4];
const E: P = [0, 1, 2, 3];
const R: P = [1, 2, 3, 0]; // quarter turn
const F: P = [0, 3, 2, 1]; // flip

fn compose(p: P, q: P) -> P { [p[q[0]], p[q[1]], p[q[2]], p[q[3]]] } // q first, then p

fn inverse(p: P) -> P {
    let mut out = [0; 4];
    for i in 0..4 { out[p[i]] = i }
    out
}

fn power(p: P, k: usize) -> P {
    let mut out = E;
    for _ in 0..k { out = compose(p, out) }
    out
}

fn inv(x: char) -> char { match x { 'a' => 'A', 'A' => 'a', 'b' => 'B', _ => 'b' } }

fn reduce(word: &str) -> String { // cancel neighbouring letter-undo pairs
    let mut out: Vec<char> = Vec::new();
    for x in word.chars() {
        if out.last() == Some(&inv(x)) { out.pop(); } else { out.push(x) }
    }
    out.into_iter().collect()
}

fn image(img: &(P, P), x: char) -> P {
    match x { 'a' => img.0, 'A' => inverse(img.0), 'b' => img.1, _ => inverse(img.1) }
}

fn extend(img: &(P, P), word: &str) -> P { // the counit's job: multiply the letters out
    let mut acc = E;
    for x in word.chars() { acc = compose(acc, image(img, x)) }
    acc
}

fn rebuild(w: &str) -> String { // F(unit): letter -> one-letter word; then multiply
    let mut acc = String::new();
    for x in w.chars() {
        let letter = if x == 'a' || x == 'b' { x.to_string() } else { inv(x).to_string() };
        let piece: String = if x == 'a' || x == 'b' { letter } else { letter.chars().rev().map(inv).collect() };
        acc = reduce(&(acc + &piece));
    }
    acc
}

fn yn(b: bool) -> &'static str { if b { "yes" } else { "no" } }

fn main() {
    let mut tile: Vec<P> = Vec::new();
    let mut names: Vec<String> = Vec::new();
    for j in 0..2 {
        for k in 0..4 {
            tile.push(compose(power(R, k), power(F, j)));
            let s = format!("{}{}", ["", "r", "r2", "r3"][k], if j == 1 { "f" } else { "" });
            names.push(if s.is_empty() { "e".to_string() } else { s });
        }
    }
    let name = |p: P| names[tile.iter().position(|&q| q == p).unwrap()].clone();
    let mut words: Vec<String> = vec![String::new()];
    for n in 0..4 {
        let mut add = Vec::new();
        for w in words.iter().filter(|w| w.len() == n) {
            for x in "abAB".chars() {
                let wx = format!("{}{}", w, x);
                if reduce(&wx) == wx { add.push(wx) }
            }
        }
        words.extend(add);
    }
    let short: Vec<&String> = words.iter().filter(|w| w.len() <= 2).collect();
    let law_holds = |img: &(P, P)| short.iter().all(|u| short.iter().all(|v|
        extend(img, &reduce(&format!("{}{}", u, v))) == compose(extend(img, u), extend(img, v))));
    let mut choices: Vec<(P, P)> = Vec::new();
    for &x in &tile { for &y in &tile { choices.push((x, y)) } }
    let homs = choices.iter().filter(|c| law_holds(c) && extend(c, "a") == c.0 && extend(c, "b") == c.1).count();
    let commuting = choices.iter().filter(|c| compose(c.0, c.1) == compose(c.1, c.0)).count();
    let killed = choices.iter().filter(|c| extend(c, "abAB") == E).count();
    let mut classes: Vec<Vec<P>> = Vec::new();
    for &x in &tile {
        let mut c: Vec<P> = tile.iter().map(|&g| compose(compose(g, x), inverse(g))).collect();
        c.sort();
        if !classes.contains(&c) { classes.push(c) }
    }
    let ex = (R, F);
    println!("== the tile group: 8 moves of a square tile ==");
    println!("moves: {}", names.join(" "));
    let counts: Vec<usize> = (1..5).map(|n| words.iter().filter(|w| w.len() == n).count()).collect();
    println!("reduced words of length 1 to 4: {:?}", counts);
    println!("== the correspondence: a homomorphism out of the free group <-> where a and b go ==");
    println!("functions from {{a, b}} to the tile: 8 x 8 = {}", choices.len());
    println!("their extensions passing the law on all {} x {} short pairs: {}", short.len(), short.len(), homs);
    println!("example a -> r, b -> f: ab -> {}, aab -> {}, abAB -> {}",
             name(extend(&ex, "ab")), name(extend(&ex, "aab")), name(extend(&ex, "abAB")));
    let unit_ok = tile.iter().filter(|&&g| extend(&(g, g), "a") == g).count();
    let upto3 = words.iter().filter(|w| w.len() <= 3).count();
    let back = words.iter().filter(|w| w.len() <= 3 && rebuild(w) == **w).count();
    println!("triangle 1, counit after unit on each move: {} of 8 come back unchanged", unit_ok);
    println!("triangle 2, each reduced word up to length 3 rebuilt letter by letter: {} of {}", back, upto3);
    println!("== moving a problem across: homomorphisms from <a, b | ab = ba> to the tile ==");
    println!("pairs (p, q) with pq = qp, counted directly: {}", commuting);
    println!("extensions sending abAB to e: {}", killed);
    println!("conjugacy classes: {}; 8 moves x {} classes = {}", classes.len(), classes.len(), 8 * classes.len());
    println!("pairs in tile x tile, the product the forgetful side keeps: {}", tile.len() * tile.len());
    println!("== a Galois connection: 3x <= y exactly when x <= floor(y / 3) ==");
    let mut grid: Vec<(i64, i64)> = Vec::new();
    for x in -30..31 { for y in -30..31 { grid.push((x, y)) } }
    let agree = grid.iter().filter(|&&(x, y)| (3 * x <= y) == (x <= y.div_euclid(3))).count();
    let searched: Vec<i64> = (-30..31).map(|y: i64| (-30..31).filter(|x| 3 * x <= y).max().unwrap()).collect();
    let same = searched == (-30..31).map(|y: i64| y.div_euclid(3)).collect::<Vec<i64>>();
    println!("pairs from -30 to 30 where the two sides agree: {} of {}", agree, grid.len());
    println!("right side found by search equals floor division: {}", yn(same));
    println!("van holds 20 boxes, packs of 3: at most {} packs", 20 / 3);
    let rounded = grid.iter().filter(|&&(x, y)| (3 * x <= y) != (x <= (y + 1).div_euclid(3))).count();
    println!("mistake, rounding instead of floor: 20 -> {} packs = {} boxes; {} pairs disagree",
             (20 + 1) / 3, 3 * ((20 + 1) / 3), rounded);
    let z3: Vec<String> = tile.iter().filter(|&&x| power(x, 3) == E).map(|&x| name(x)).collect();
    println!("mistake, one-generator group of order 3 (not free): 8 choices, {} extend: {}", z3.len(), z3.join(" "));
    let fin = words.iter().filter(|w| !w.is_empty() && reduce(&w.repeat(4)).is_empty()).count();
    let lift = |p: P, w1: &str, w2: &str| { // r^k f^j -> w1^k w2^j: a candidate map tile -> words
        let i = tile.iter().position(|&q| q == p).unwrap();
        reduce(&(w1.repeat(i % 4) + &w2.repeat(i / 4)))
    };
    let swapped: usize = words.iter().map(|w1| words.iter().filter(|w2| tile.iter().all(|&p| tile.iter().all(|&q|
        lift(compose(p, q), w1, w2) == reduce(&(lift(p, w1, w2) + &lift(q, w1, w2)))))).count()).sum();
    println!("mistake, sides swapped: 2^8 = {} functions from tile to {{a, b}}; non-empty words up to length 4 with w^4 = 1: {}",
             1 << 8, if fin == 0 { "none".to_string() } else { fin.to_string() });
    println!("  homomorphisms tile -> free group sending r and f to words up to length 4: {}", swapped);
    println!("mistake, relation forgotten: {} pairs counted, {} are homomorphisms", choices.len(), commuting);
    assert!(tile.iter().all(|&p| tile.iter().all(|&q| tile.contains(&compose(p, q)))) && classes.len() == 5);
    assert!(homs == choices.len() && homs == 64); // every choice extends: the bijection
    assert!(commuting == killed && killed == 8 * classes.len() && commuting == 40); // three counts
    assert!(agree == grid.len() && same);
    assert!(unit_ok == tile.len() && back == 1 + (1..4u32).map(|n| 4 * 3usize.pow(n - 1)).sum::<usize>()); // both triangles
    assert!(rounded > 0 && z3.len() == 1 && fin == 0 && swapped == 1);
    println!("ALL CHECKS PASS");
}
