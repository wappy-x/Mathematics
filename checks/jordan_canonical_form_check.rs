// Jordan form -- the same check as the Python, in Rust.  No crates.  Ranks of the
// powers of N = A - 2I give the block sizes; the longest Jordan chain gives them again.
// A^10 four ways: A times itself, P J^10 P^-1, 2^10 I + 10 x 2^9 N, and the step rules on (a(n), a(n+1), b(n)).
type M = Vec<Vec<i64>>;

fn mul(x: &M, y: &M) -> M {
    (0..3).map(|i| (0..3).map(|j| (0..3).map(|k| x[i][k] * y[k][j]).sum()).collect()).collect()
}
fn eye() -> M { (0..3).map(|i| (0..3).map(|j| (i == j) as i64).collect()).collect() }
fn power(x: &M, k: u32) -> M { if k == 0 { eye() } else { mul(&power(x, k - 1), x) } }
fn apply(x: &M, v: &[i64]) -> Vec<i64> { (0..3).map(|i| (0..3).map(|k| x[i][k] * v[k]).sum()).collect() }
fn nonzero(v: &[i64]) -> bool { v.iter().any(|&a| a != 0) }
fn yn(c: bool) -> &'static str { if c { "yes" } else { "no" } }
fn life(nn: &M, v: &[i64]) -> usize { (0..4).find(|&k| !nonzero(&apply(&power(nn, k), v))).unwrap_or(4) as usize }   // first k with N^k v = 0

fn rank(x: &M) -> usize {                // whole-number elimination, no fractions
    let (mut m, mut r) = (x.clone(), 0);
    for c in 0..3 {
        let Some(p) = (r..3).find(|&i| m[i][c] != 0) else { continue };
        m.swap(r, p);
        for i in r + 1..3 {
            m[i] = (0..3).map(|j| m[r][c] * m[i][j] - m[i][c] * m[r][j]).collect();
        }
        r += 1;
    }
    r
}

fn main() {
    let (a, s): (M, Vec<i64>) = (vec![vec![0, 1, 0], vec![-4, 4, 0], vec![0, 0, 2]], vec![1, 6, 1]);
    let (l, n, id): (i64, u32, M) = (2, 10, eye());
    let nn: M = (0..3).map(|i| (0..3).map(|j| a[i][j] - l * id[i][j]).collect()).collect();
    let trace: i64 = (0..3).map(|i| a[i][i]).sum();
    let mut minors = 0;
    for i in 0..3 { for j in i + 1..3 { minors += a[i][i] * a[j][j] - a[i][j] * a[j][i] } }
    let det: i64 = (0..3).map(|j| a[0][j] * (a[1][(j + 1) % 3] * a[2][(j + 2) % 3]
        - a[1][(j + 2) % 3] * a[2][(j + 1) % 3])).sum();
    let ranks: Vec<usize> = (0..4).map(|k| rank(&power(&nn, k))).collect();
    let mut at_least: Vec<usize> = (0..3).map(|k| ranks[k] - ranks[k + 1]).collect();
    at_least.push(0);                    // blocks of size > k
    let sizes: Vec<usize> = [2, 1, 0].iter().flat_map(|&k| vec![k + 1; at_least[k] - at_least[k + 1]]).collect();
    let top = id.iter().max_by_key(|e| life(&nn, e)).unwrap().clone();   // a basis vector with the longest chain (a tie goes to the later one)
    let low = apply(&nn, &top);
    let extra = id.iter().find(|e| !nonzero(&apply(&nn, e))).cloned().unwrap_or(vec![0, 0, 0]);
    let mut lengths = vec![life(&nn, &top)];
    lengths.extend(vec![1; 3usize.saturating_sub(life(&nn, &top))]);   // the other dimensions: lone eigenvectors
    let p: M = (0..3).map(|i| vec![low[i], top[i], extra[i]]).collect();
    let pinv: M = vec![vec![1, 0, 0], vec![-2, 1, 0], vec![0, 0, 1]];   // by hand, checked below
    let j = mul(&pinv, &mul(&a, &p));
    let road1 = power(&a, n);
    let (big, step) = (l.pow(n), n as i64 * l.pow(n - 1));
    let road2 = mul(&p, &mul(&vec![vec![big, step, 0], vec![0, big, 0], vec![0, 0, big]], &pinv));
    let road3: M = (0..3).map(|r| (0..3).map(|c| big * id[r][c] + step * nn[r][c]).collect()).collect();
    let (mut walk, c, an) = (s.clone(), apply(&pinv, &s), apply(&road1, &s));   // the start, in the chain basis, and A^10 on it
    for _ in 0..n { walk = vec![walk[1], 4 * walk[1] - 4 * walk[0], 2 * walk[2]] }   // a(n+2) = 4a(n+1) - 4a(n), b(n+1) = 2b(n)
    println!("A = {:?}; trace {}, 2 by 2 minors {}, det {}: (x - 2)^3", a, trace, minors, det);
    println!("N = A - 2I = {:?}", nn);
    println!("ranks of N^0, N^1, N^2, N^3: {:?}", ranks);
    println!("blocks of size at least 1, 2, 3: {:?}; block sizes {:?}", &at_least[..3], sizes);
    println!("independent eigenvectors: 3 - rank N = {}", 3 - ranks[1]);
    println!("chain: top {:?} -> N top {:?} -> 0; extra eigenvector {:?}", top, low, extra);
    println!("chain lengths from the vectors: {:?}", lengths);
    println!("P = {:?}; P^-1 P = I: {}", p, yn(mul(&pinv, &p) == id));
    println!("J = P^-1 A P = {:?}", j);
    println!("road 1, A times itself {} times: {:?}", n, road1);
    println!("road 2, P J^{} P^-1 with J^{} from the block formula, same matrix: {}", n, n, yn(road2 == road1));
    println!("road 3, 2^{} I + {} x 2^{} N, same matrix: {}", n, n, n - 1, yn(road3 == road1));
    println!("start {:?} = {} x {:?} + {} x {:?} + {} x {:?}, so a({}) = 2^{} + {} x {} x 2^{} = {} + {} = {}", s, c[0], low, c[1], top, c[2], extra, n, n, c[1], n, n - 1, big, c[1] * step, an[0]);
    println!("step rules run {} times from {:?}: {:?}; A^{} on {:?}, same: {}", n, s, walk, n, s, yn(an == walk));
    println!("a(n), n = 0 to 6: {:?}", (0..7).map(|k| apply(&power(&a, k), &s)[0]).collect::<Vec<i64>>());
    println!("mistake 1, each entry to the 10th power: a(10) = {}\nmistake 2, the diagonal of J only: a(10) = 2^10 = {}",
        apply(&a.iter().map(|row| row.iter().map(|&x| x.pow(n)).collect()).collect::<M>(), &s)[0], c[0] * big);
    println!("mistake 3, 2^10 in the extra term: 2^10 + {} x 10 x 2^10 = {} + {} = {}", c[1], big, c[1] * n as i64 * big, big + c[1] * n as i64 * big);
    println!("mistake 4, blocks counted as rank N: {} block, not {}", ranks[1], at_least[0]);
    assert!((trace, minors, det) == (3 * l, 3 * l * l, l.pow(3)));        // (x - 2)^3
    assert!(sizes == lengths && mul(&a, &p) == mul(&p, &j));               // ranks against the chain
    assert!(j == vec![vec![2, 1, 0], vec![0, 2, 0], vec![0, 0, 2]] && mul(&pinv, &p) == id);
    assert!(road1 == road2 && road2 == road3 && an == walk && walk[0] == 21504);   // A^10 four ways
    println!("ALL CHECKS PASS");
}
