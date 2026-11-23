// Universal properties -- the same check as the Python, in Rust.  No crates.
// A shirt shop: 2 colours, 3 sizes, 4 orders today.  Points are numbered: the
// pair (colour c, size s) is 3c + s.  Every claim is a count over every
// function, set against a count found another way.
use std::collections::{HashMap, HashSet};
const COLOURS: [&str; 2] = ["red", "blue"];
const SIZES: [&str; 3] = ["S", "M", "L"];
const ORDERS: [&str; 4] = ["#1", "#2", "#3", "#4"];
type M = (i64, i64, i64, i64);

fn maps(dom: usize, cod: usize) -> Vec<Vec<usize>> {   // every function, as a list of images
    let mut out: Vec<Vec<usize>> = vec![vec![]];
    for _ in 0..dom {
        out = out.iter().flat_map(|m| (0..cod).map(move |y| { let mut n = m.clone(); n.push(y); n })).collect();
    }
    out
}

// how many h: orders -> points fit each pair (f, g), for points read by pa and pb
fn counts(points: usize, pa: &dyn Fn(usize) -> usize, pb: &dyn Fn(usize) -> usize) -> Vec<usize> {
    let mut seen: HashMap<(Vec<usize>, Vec<usize>), usize> = HashMap::new();
    for h in maps(4, points) {
        let key = (h.iter().map(|&p| pa(p)).collect(), h.iter().map(|&p| pb(p)).collect());
        *seen.entry(key).or_insert(0) += 1;
    }
    let mut out = vec![];
    for f in maps(4, 2) { for g in maps(4, 3) { out.push(*seen.get(&(f.clone(), g)).unwrap_or(&0)) } }
    out
}

fn n_of(v: &[usize], x: usize) -> usize { v.iter().filter(|&&c| c == x).count() }
fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }
fn name(i: usize) -> String { format!("{} {}", COLOURS[i / 3], SIZES[i % 3]) }
fn mul(p: M, q: M) -> M {                               // 2 x 2 integer matrices, (a, b, c, d)
    (p.0 * q.0 + p.1 * q.2, p.0 * q.1 + p.1 * q.3, p.2 * q.0 + p.3 * q.2, p.2 * q.1 + p.3 * q.3)
}
fn sign(p: M) -> M {                                    // a matrix and its negative count as one
    let first = [p.0, p.1, p.2, p.3].into_iter().find(|&x| x != 0).unwrap();
    if first > 0 { p } else { (-p.0, -p.1, -p.2, -p.3) }
}
fn best(u: usize, v: usize, below: bool) -> Vec<usize> { // the bound every other bound passes through
    let sub = |a: usize, b: usize| a & !b == 0;
    let cands: Vec<usize> = (0..8).filter(|&w| if below { sub(w, u) && sub(w, v) } else { sub(u, w) && sub(v, w) }).collect();
    cands.iter().copied().filter(|&w| cands.iter().all(|&x| if below { sub(x, w) } else { sub(w, x) })).collect()
}
fn homs(cod: usize, add: &dyn Fn(usize, usize) -> usize) -> usize {
    maps(6, cod).iter().filter(|m| (0..6).all(|x| (0..6).all(|y| m[(x + y) % 6] == add(m[x], m[y])))).count()
}

fn main() {
    let (f, g): (Vec<usize>, Vec<usize>) = (vec![0, 1, 0, 1], vec![1, 0, 2, 1]);   // colour, size of each order
    let (first, second) = (|p: usize| p / 3, |p: usize| p % 3);
    let pairs = maps(4, 2).len() * maps(4, 3).len();
    let prod_counts = counts(6, &first, &second);
    let h: Vec<usize> = (0..4).map(|i| 3 * f[i] + g[i]).collect();           // h(x) = (f(x), g(x))
    println!("colours {}, sizes {}, pairs in A x B {}, orders {}", COLOURS.len(), SIZES.len(), COLOURS.len() * SIZES.len(), ORDERS.len());
    println!("maps orders -> colours {}, -> sizes {}, pairs (f, g) {}; maps orders -> A x B {}",
             maps(4, 2).len(), maps(4, 3).len(), pairs, maps(4, 6).len());
    println!("pairs (f, g) met by exactly one h: {} of {}", n_of(&prod_counts, 1), pairs);
    let today: Vec<String> = (0..4).map(|i| format!("{} -> {}", ORDERS[i], name(h[i]))).collect();
    println!("today's h: {}", today.join(", "));
    println!("maps orders -> one-point set: {}; maps empty set -> sizes: {}", maps(4, 1).len(), maps(0, 3).len());
    let big_counts = counts(12, &|p| p / 6, &|p| (p / 2) % 3);                  // a spare bit
    let small_counts = counts(5, &first, &second);                              // blue L missing
    println!("mistake, 12-point candidate with a spare bit: {} pairs met by 16 maps each", n_of(&big_counts, 16));
    println!("mistake, 5-point candidate missing blue L: {} pairs met by no map; by subtraction {} - 5^4 = {}",
             n_of(&small_counts, 0), pairs, pairs - 625);
    let (colour_of, size_of) = (|n: usize| n / 3, |n: usize| n % 3);             // stock codes 0 to 5
    let code_counts = counts(6, &colour_of, &size_of);
    let all66 = maps(6, 6);
    let fits: Vec<&Vec<usize>> = all66.iter().filter(|u| (0..6).all(|i| colour_of(u[i]) == i / 3 && size_of(u[i]) == i % 3)).collect();
    let bij = all66.iter().filter(|u| u.iter().collect::<HashSet<_>>().len() == 6).count();
    let ends: Vec<&Vec<usize>> = all66.iter().filter(|e| (0..6).all(|i| e[i] == i)).collect();
    let ends_fit: Vec<&Vec<usize>> = all66.iter().filter(|e| (0..6).all(|i| e[i] / 3 == i / 3 && e[i] % 3 == i % 3)).collect();
    let formula_u: Vec<usize> = (0..6).map(|i| 3 * (i / 3) + i % 3).collect();
    let v: Vec<usize> = (0..6).map(|n| 3 * colour_of(n) + size_of(n)).collect(); // back again: code n -> its pair
    let u_after_v: Vec<usize> = v.iter().map(|&p| fits[0][p]).collect();          // then the code u gives that pair
    let every_code: Vec<usize> = (0..6).collect();
    println!("stock codes as a product too: {} of {} pairs met once", n_of(&code_counts, 1), pairs);
    println!("maps A x B -> codes {}, of them bijections {}, respecting both projections {}", all66.len(), bij, fits.len());
    let fit: Vec<String> = (0..6).map(|i| format!("{} -> {}", name(i), fits[0][i])).collect();
    println!("the one that fits: {}", fit.join(", "));
    println!("maps A x B -> A x B {}, respecting both projections {}", all66.len(), ends_fit.len());
    println!("codes -> pairs -> codes returns every code: {}", yn(u_after_v == every_code));
    let mut co: HashMap<(Vec<usize>, Vec<usize>), usize> = HashMap::new();
    for k in maps(5, 2) { *co.entry((k[..2].to_vec(), k[2..].to_vec())).or_insert(0) += 1 }
    let co_pairs = maps(2, 2).len() * maps(3, 2).len();
    let co_once = co.values().filter(|&&c| c == 1).count();
    println!("A + B has 5 points; maps A + B -> yes/no {}, pairs (p, q) {}, met exactly once {}", maps(5, 2).len(), co_pairs, co_once);
    println!("mistake, A x B used as the coproduct: maps A x B -> yes/no {}, not {}", maps(6, 2).len(), co_pairs);
    let meets = (0..8).flat_map(|u| (0..8).map(move |v| (u, v))).filter(|&(u, v)| best(u, v, true) == vec![u & v]).count();
    let joins = (0..8).flat_map(|u| (0..8).map(move |v| (u, v))).filter(|&(u, v)| best(u, v, false) == vec![u | v]).count();
    println!("subsets of 3 toppings 8; product = intersection in {} of 64 pairs, coproduct = union in {} of 64", meets, joins);
    let (h2, h3) = (homs(2, &|a, b| (a + b) % 2), homs(3, &|a, b| (a + b) % 3));
    let h23 = homs(6, &|p, q| ((p / 3 + q / 3) % 2) * 3 + (p % 3 + q % 3) % 3);
    println!("homomorphisms Z6 -> Z2 {}, Z6 -> Z3 {}, Z6 -> Z2 x Z3 {}", h2, h3, h23);
    let (a2, b3): (M, M) = ((0, -1, 1, 0), (0, -1, 1, 1));                     // orders 2 and 3, signs ignored
    let gens = [a2, b3, mul(b3, b3)];
    let mut level: HashSet<M> = HashSet::from([(1, 0, 0, 1)]);
    let mut seen = level.clone();
    let (mut by_matrix, mut by_words): (Vec<usize>, Vec<usize>) = (vec![1], vec![1]);
    for k in 1..5u32 {
        level = level.iter().flat_map(|&p| gens.iter().map(move |&q| sign(mul(p, q)))).filter(|x| !seen.contains(x)).collect();
        seen.extend(level.iter().copied());
        by_matrix.push(seen.len());
        by_words.push(by_words[by_words.len() - 1] + 2usize.pow(k / 2) + 2usize.pow((k + 1) / 2));
    }
    println!("Z2 * Z3, elements of word length up to 0..4: by matrices {:?}, by counting words {:?}", by_matrix, by_words);
    println!("figure, nodes: orders (210,50) | A x B (210,170) | colours (70,290) | sizes (350,290)");

    assert!(n_of(&prod_counts, 1) == pairs && pairs == 16 * 81 && pairs == maps(4, 6).len());
    let matching: Vec<Vec<usize>> = maps(4, 6).into_iter().filter(|m| (0..4).all(|i| m[i] / 3 == f[i] && m[i] % 3 == g[i])).collect();
    assert!(matching == vec![h.clone()]);
    assert!(n_of(&big_counts, 16) == pairs && n_of(&small_counts, 0) == pairs - 625);
    assert!(fits.len() == 1 && *fits[0] == formula_u && bij == 720 && ends_fit == ends);
    assert!(n_of(&code_counts, 1) == pairs && u_after_v == every_code);    // the codes are a product too
    assert!(co_once == co_pairs && co_pairs == 32 && maps(6, 2).len() == 64);
    assert!(meets == 64 && joins == 64 && (h2, h3, h23) == (2, 3, 6));
    assert!(by_matrix == by_words && by_words == vec![1, 4, 8, 14, 22]);
    println!("ALL CHECKS PASS");
}
