// Vertex colouring and the chromatic number -- the same check as the Python, in Rust.  No crates.
// Six exams clash when one student sits both, and the fewest sessions is reached twice: by trying
// every colouring, and by a floor from mutual clashes meeting the ceiling Brooks allows.
const EXAMS: [&str; 6] = ["Algebra", "Biology", "Chemistry", "Drama", "Economics", "French"];
fn clash_graph(groups: &[Vec<usize>], n: usize) -> Vec<Vec<bool>> {   // a line per co-sat pair
    let mut adj = vec![vec![false; n]; n];
    for g in groups { for &a in g { for &b in g { if a != b { adj[a][b] = true } } } }
    adj
}
fn nbrs(adj: &[Vec<bool>], v: usize) -> Vec<usize> { (0..adj.len()).filter(|&w| adj[v][w]).collect() }
fn biggest(adj: &[Vec<bool>], joined: bool) -> Vec<usize> {   // every pair joined, or none joined
    let n = adj.len(); let mut best: Vec<usize> = Vec::new();
    for m in 0..(1usize << n) {
        let s: Vec<usize> = (0..n).filter(|i| m >> i & 1 == 1).collect();
        if s.len() > best.len() && s.iter().all(|&a| s.iter().all(|&b| a == b || adj[a][b] == joined)) { best = s }
    }
    best
}
fn greedy(adj: &[Vec<bool>], order: &[usize]) -> Vec<usize> {   // lowest colour left free
    let mut colour = vec![0usize; adj.len()];
    for &v in order {
        let used: Vec<usize> = nbrs(adj, v).iter().map(|&w| colour[w]).collect();
        colour[v] = (1..adj.len() + 2).find(|c| !used.contains(c)).unwrap()
    }
    colour
}
fn fewest(adj: &[Vec<bool>]) -> usize {   // exhaustive: every assignment of k colours, k counting up
    let n = adj.len();
    let ok = |c: &Vec<usize>| (0..n).all(|v| (0..n).all(|w| !adj[v][w] || c[v] != c[w]));
    (1..=n).find(|&k| (0..k.pow(n as u32)).any(|m|
        ok(&(0..n).map(|i| m / k.pow(i as u32) % k + 1).collect()))).unwrap()
}

fn main() {
    let students: Vec<Vec<usize>> = vec![vec![0, 1, 2], vec![3, 4, 5], vec![0, 3], vec![1, 4], vec![2, 5]];
    let ring_pairs: Vec<Vec<usize>> = vec![vec![0, 1], vec![1, 2], vec![2, 3], vec![3, 4], vec![4, 0]];
    let (good_order, listed) = ([0usize, 5, 1, 3, 2, 4], [0usize, 1, 2, 3, 4, 5]);
    let n = EXAMS.len();
    let adj = clash_graph(&students, n);
    let mut edges: Vec<(usize, usize)> = Vec::new();
    for a in 0..n { for b in a + 1..n { if adj[a][b] { edges.push((a, b)) } } }
    let deg: Vec<usize> = (0..n).map(|v| nbrs(&adj, v).len()).collect();
    let (clique, free) = (biggest(&adj, true), biggest(&adj, false));
    let (omega, alpha, delta) = (clique.len(), free.len(), *deg.iter().max().unwrap());
    let by_free = (n + alpha - 1) / alpha; let floor = omega.max(by_free);   // n/alpha, rounded up
    let (gcol, lcol) = (greedy(&adj, &good_order), greedy(&adj, &listed));
    let (gmax, lmax) = (*gcol.iter().max().unwrap(), *lcol.iter().max().unwrap());
    let (ring, tri) = (clash_graph(&ring_pairs, 5), clash_graph(&[vec![0, 1, 2]], 3));
    let tri_d = (0..3).map(|v| nbrs(&tri, v).len()).max().unwrap();
    let reach: Vec<usize> = (0..n).filter(|&w| w == 0 || adj[0][w] || (0..n).any(|v| adj[0][v] && adj[v][w])).collect();
    let proper = |c: &Vec<usize>| (0..n).all(|v| (0..n).all(|w| !adj[v][w] || c[v] != c[w]));
    let names = |s: &[usize]| s.iter().map(|&i| EXAMS[i]).collect::<Vec<&str>>().join(", ");
    let inits = |s: &[usize]| s.iter().map(|&i| &EXAMS[i][0..1]).collect::<Vec<&str>>().join("");
    let y = |t: bool| if t { "yes" } else { "no" };
    println!("exams {}, students {}, clashing pairs {}", n, students.len(), edges.len());
    println!("clashes by initial: {}", edges.iter().map(|&(a, b)| inits(&[a, b])).collect::<Vec<String>>().join(" "));
    println!("clashes at each exam: {:?}, busiest count Delta = {}", deg, delta);
    println!("largest all-clashing set: {} -> omega = {}", names(&clique), omega);
    println!("largest clash-free set: {} -> alpha = {}, so {} exams need at least {} sessions",
             names(&free), alpha, n, by_free);
    println!("greedy in the listed order {}: {:?} -> {} sessions", inits(&listed), lcol, lmax);
    println!("greedy in the order {}: {:?} -> {} sessions", inits(&good_order), gcol, gmax);
    println!("Brooks test: one piece {}, every pair clashing {}, a ring {}", y(reach.len() == n),
             y(*deg.iter().min().unwrap() == n - 1), y(delta == 2));
    println!("floor {} meets Brooks ceiling {}, so chi = {}, no search", floor, delta, floor);
    println!("every colouring tried, no bounds used: chi = {}", fewest(&adj));
    for c in 1..=gmax {
        println!("session {}: {}", c, names(&(0..n).filter(|&i| gcol[i] == c).collect::<Vec<usize>>()));
    }
    println!("no clash inside a session, over all {} clashes: {}", edges.len(), y(proper(&gcol)));
    println!("mistake 1, the greedy count read as the answer: {} sessions, not {}", lmax, fewest(&adj));
    println!("mistake 2, Brooks on the {} triangle alone: every pair clashes, so it is an exception; \
              it would claim {}, and chi = {}", inits(&[0, 1, 2]), tri_d, fewest(&tri));
    println!("mistake 3, the five-exam ring: omega = {}, chi = {}", biggest(&ring, true).len(), fewest(&ring));
    assert!(fewest(&adj) == omega && omega == gmax && proper(&gcol));
    assert!(lmax == 4 && lmax <= delta + 1 && proper(&lcol));
    assert!(alpha == 2 && by_free == fewest(&adj) && reach.len() == n);
    assert!(fewest(&ring) == 3 && biggest(&ring, true).len() == 2 && fewest(&tri) == 3);
    println!("ALL CHECKS PASS");
}
