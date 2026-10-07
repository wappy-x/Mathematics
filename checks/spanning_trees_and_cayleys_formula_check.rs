// Spanning trees and Cayley's formula -- the same check as the Python, in Rust.  No crates.  Villages
// Ayle, Brook, Crag, Dale, then Ember.  A layout reaches every village and holds no loop.  Counted twice,
// by every choice of roads and by decoding every Prufer word, a determinant third; flood gives each ring.
type Edge = (usize, usize);
const NAMES: [&str; 5] = ["Ayle", "Brook", "Crag", "Dale", "Ember"];
const SPARSE: [Edge; 6] = [(0, 1), (0, 2), (1, 2), (1, 3), (2, 3), (3, 4)];
const FULL4: [Edge; 6] = [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)];
const FULL5: [Edge; 10] = [(0, 1), (0, 2), (0, 3), (0, 4), (1, 2), (1, 3), (1, 4), (2, 3), (2, 4), (3, 4)];

fn flood(n: usize, edges: &[Edge]) -> (Vec<usize>, Vec<Edge>) {
    let (mut ring, mut kept) = ({ let mut r = vec![usize::MAX; n]; r[0] = 0; r }, Vec::new());
    for r in 0..n {                       // rings out from Ayle; each village keeps the road in
        for v in (0..n).filter(|&v| ring[v] == r).collect::<Vec<usize>>() {
            for (x, w) in edges.iter().flat_map(|&(a, b)| [(a, b), (b, a)]) {
                if x == v && ring[w] == usize::MAX { ring[w] = r + 1; kept.push((v.min(w), v.max(w))) }
            }
        }
    }
    kept.sort(); (ring, kept)
}
fn is_tree(n: usize, edges: &[Edge]) -> bool {    // n-1 roads, and the flood reaches every village
    edges.len() == n - 1 && flood(n, edges).0.iter().all(|&r| r != usize::MAX)
}
fn by_listing(n: usize, roads: &[Edge]) -> (usize, Vec<Vec<Edge>>) {   // road one: every choice of n-1
    let tried: Vec<Vec<Edge>> = (0..1u32 << roads.len()).map(|m| roads.iter().enumerate()
        .filter(|(i, _)| m >> i & 1 == 1).map(|(_, &r)| r).collect::<Vec<Edge>>())
        .filter(|s| s.len() == n - 1).collect();
    let mut out: Vec<Vec<Edge>> = tried.iter().filter(|s| is_tree(n, s)).cloned().collect();
    out.sort(); (tried.len(), out)
}
fn decode(n: usize, word: &[usize]) -> Vec<Edge> {   // road two: a word of n-2 names into a layout
    let mut deg: Vec<usize> = (0..n).map(|v| 1 + word.iter().filter(|&&a| a == v).count()).collect();
    let mut edges: Vec<Edge> = Vec::new();
    for &letter in word {
        let leaf = (0..n).find(|&v| deg[v] == 1).unwrap();
        edges.push((leaf.min(letter), leaf.max(letter))); deg[leaf] -= 1; deg[letter] -= 1;
    }
    let last: Vec<usize> = (0..n).filter(|&v| deg[v] == 1).collect();
    edges.push((last[0], last[1])); edges.sort(); edges
}
fn det3(m: &[[i64; 3]; 3]) -> i64 {       // road three: a 3-by-3 determinant, multiplied out here
    m[0][0] * (m[1][1] * m[2][2] - m[1][2] * m[2][1]) - m[0][1] * (m[1][0] * m[2][2] - m[1][2] * m[2][0])
        + m[0][2] * (m[1][0] * m[2][1] - m[1][1] * m[2][0])
}
fn show(e: &[Edge]) -> String { e.iter().map(|&(u, v)| format!("{}-{}", NAMES[u], NAMES[v])).collect::<Vec<_>>().join(" ") }
fn say(vs: &[usize]) -> String { vs.iter().map(|&v| NAMES[v]).collect::<Vec<_>>().join(" ") }

fn main() {
    println!("four villages {}; roads possible {}; each layout uses 3 roads", say(&[0, 1, 2, 3]), FULL4.len());
    let (mut counts, mut listed, mut four) = (Vec::new(), Vec::new(), Vec::new());
    for (label, n, roads) in [("all 6 roads", 4usize, FULL4.to_vec()), ("all 10 roads", 5, FULL5.to_vec()),
                              ("6 of the 10", 5, SPARSE.to_vec())] {
        let (tried, found) = by_listing(n, &roads);
        let total = n.pow((n - 2) as u32);
        let mut words: Vec<Vec<Edge>> = (0..total).map(|m| decode(n,
            &(0..n - 2).map(|i| m / n.pow(i as u32) % n).collect::<Vec<usize>>())).collect();
        words.sort(); words.dedup();
        let fit: Vec<Vec<Edge>> = words.iter().filter(|t| t.iter().all(|e| roads.contains(e))).cloned().collect();
        println!("{} villages, {}: {} choices of {} roads tried, layouts by listing {}, from the {} words {}",
                 n, label, tried, n - 1, found.len(), words.len(), fit.len());
        assert!(found == fit && words.len() == total);
        counts.push(found.len()); if n == 4 { four = found.clone() } listed = found;
    }
    let stars = four.iter().filter(|t| (0..4).any(|v| t.iter().filter(|e| e.0 == v || e.1 == v).count() == 3)).count();
    let (ring, tree) = flood(5, &SPARSE);
    println!("the flood from Ayle over the sparse map, rings: {}", (0..=*ring.iter().max().unwrap())
        .map(|r| format!("{} {}", r, say(&(0..5).filter(|&v| ring[v] == r).collect::<Vec<usize>>())))
        .collect::<Vec<String>>().join(" | "));
    println!("  the layout it keeps: {}; roads {}; a tree: {}", show(&tree), tree.len(),
             if is_tree(5, &tree) { "yes" } else { "no" });
    println!("the word {} decodes to {}, and {} to {}", say(&[1, 2]), show(&decode(4, &[1, 2])), say(&[0, 0]), show(&decode(4, &[0, 0])));
    let k4tab = [[3i64, -1, -1], [-1, 3, -1], [-1, -1, 3]];
    println!("the four-village table, one row and column cut, has determinant {}", det3(&k4tab));
    println!("Cayley 4^2 = {} and 5^3 = {}; the 16 plans are {} stars and {} lines; 6 of the 10 roads allow {}",
             4usize.pow(2), 5usize.pow(3), stars, counts[0] - stars, counts[2]);
    assert!(counts == vec![4usize.pow(2), 5usize.pow(3), 8] && det3(&k4tab) == counts[0] as i64 && stars == 4);
    assert!(listed.contains(&tree) && decode(4, &[1, 2]) == vec![(0, 1), (1, 2), (2, 3)]
        && decode(4, &[0, 0]) == vec![(0, 1), (0, 2), (0, 3)]);
    println!("ALL CHECKS PASS");
}
