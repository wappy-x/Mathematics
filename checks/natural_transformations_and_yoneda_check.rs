// Natural transformations and Yoneda -- the same check as the Python, in Rust.
// No crates.  A finite set is {0, ..., n-1}; a function between finite sets is
// a vector t, with t[i] the place member i goes.  Three roads: every naturality
// square checked by brute force; Yoneda's rebuild of a family from one value;
// a blind search over every candidate family, counted against Yoneda's count.
use std::fmt::Display;

type L = Vec<usize>;

fn fmap<A, B>(f: impl Fn(&A) -> B, xs: &[A]) -> Vec<B> {   // the list functor on arrows
    xs.iter().map(|x| f(x)).collect()
}

fn rev<T: Clone>(xs: &[T]) -> Vec<T> {                    // moves slots, never reads a value
    (0..xs.len()).map(|i| xs[xs.len() - 1 - i].clone()).collect()
}

fn pounds(p: &i64) -> String {                            // pence to price text: the arrow f
    format!("£{}.{}{}", p / 100, p / 10 % 10, p % 10)
}

fn show<T: Display>(xs: &[T]) -> String {
    format!("[{}]", xs.iter().map(|x| x.to_string()).collect::<Vec<_>>().join(", "))
}

fn yn(claim: bool) -> &'static str { if claim { "yes" } else { "no" } }

fn sorted<T: Ord + Clone>(xs: &[T]) -> Vec<T> { let mut v = xs.to_vec(); v.sort(); v }

fn functions(m: usize, n: usize) -> Vec<L> {             // every function m-set -> n-set
    let mut out: Vec<L> = vec![vec![]];
    for _ in 0..m {
        out = out.iter().flat_map(|t| (0..n).map(move |y| { let mut u = t.clone(); u.push(y); u })).collect();
    }
    out
}

fn lists(m: usize, k: usize) -> Vec<L> { functions(k, m) } // every k-list over an m-set

fn squares(eta: &dyn Fn(usize, &L) -> L, sizes: &[usize], lengths: &[usize]) -> (usize, usize) {
    let (mut checked, mut failed) = (0, 0);
    for &m in sizes {
        for &n in sizes {
            for f in functions(m, n) {
                for &k in lengths {
                    for xs in lists(m, k) {
                        checked += 1;
                        let down_then_across = fmap(|x: &usize| f[*x], &eta(m, &xs));
                        let across_then_down = eta(n, &fmap(|x: &usize| f[*x], &xs));
                        if down_then_across != across_then_down { failed += 1 }
                    }
                }
            }
        }
    }
    (checked, failed)
}

fn comp(p: &L, q: &L) -> L { (0..3).map(|i| p[q[i]]).collect() }

fn pos(set: &[L], x: &L) -> usize { set.iter().position(|y| y == x).unwrap() }

fn main() {
    // 1. The square on one real list: shelf prices in pence, f = write as text.
    let prices: Vec<i64> = vec![250, 199, 1200];
    let (route_a, route_b) = (fmap(pounds, &rev(&prices)), rev(&fmap(pounds, &prices)));
    println!("prices in pence {}, as text {}", show(&prices), show(&fmap(pounds, &prices)));
    println!("reverse, then write as text: {}", show(&route_a));
    println!("write as text, then reverse: {}", show(&route_b));
    println!("the square commutes for reversal: {}", yn(route_a == route_b));
    let (sort_a, sort_b) = (fmap(pounds, &sorted(&prices)), sorted(&fmap(pounds, &prices)));
    println!("sort, then write as text: {}", show(&sort_a));
    println!("write as text, then sort: {}", show(&sort_b));
    println!("the square commutes for sorting: {}", yn(sort_a == sort_b));
    let (neg, add1) = (|x: &i64| -x, |x: &i64| x + 1);
    println!("refunds, f = negate: sort then negate {}, negate then sort {}",
             show(&fmap(neg, &sorted(&prices))), show(&sorted(&fmap(neg, &prices))));
    let (p1, p2) = (fmap(add1, &sorted(&prices)), sorted(&fmap(add1, &prices)));
    println!("f = add 1p: sort then add {}, add then sort {}: agree {}", show(&p1), show(&p2), yn(p1 == p2));
    println!("mistake, reverse numbers but leave text alone: {} against {}",
             show(&route_a), show(&fmap(pounds, &prices)));

    // 2. Brute force: every function between sets of 1 to 3 members, every list up to length 4.
    let up_to_4: Vec<usize> = (0..5).collect();
    let (rev_checked, rev_failed) = squares(&|_m, xs| rev(xs), &[1, 2, 3], &up_to_4);
    let (sort_checked, sort_failed) = squares(&|_m, xs| sorted(xs), &[1, 2, 3], &up_to_4);
    println!("reversal: {} squares checked, {} fail", rev_checked, rev_failed);
    println!("sorting: {} squares checked, {} fail", sort_checked, sort_failed);

    // 3. Yoneda's rebuild: reversal on 3-lists is fixed by one value, its answer on [0, 1, 2].
    let generic: L = vec![0, 1, 2];
    let recipe = rev(&generic);
    let all3: Vec<L> = [1, 2, 3].iter().flat_map(|&m| lists(m, 3)).collect();
    let rebuilt = all3.iter().all(|xs| rev(xs) == fmap(|i: &usize| xs[*i], &recipe));
    println!("reversal of the generic list {} is {}", show(&generic), show(&recipe));
    println!("rev(xs) = map (slot of xs) over {}, for all {} lists of length 3: {}", show(&recipe), all3.len(), yn(rebuilt));
    let abc = ['a', 'b', 'c'];
    println!("example: [a, b, c] -> slots {} -> {}", show(&recipe), show(&fmap(|i: &usize| abc[*i], &recipe)));
    let recipes_ok = functions(3, 3).into_iter()
        .filter(|p| squares(&|_m, xs| vec![xs[p[0]], xs[p[1]], xs[p[2]]], &[1, 2, 3], &[3]).1 == 0).count();
    println!("recipes p: 3 -> 3 tried as families on 3-lists: {} of {} pass every square", recipes_ok, 27);

    // 4. Blind search on pairs: any rule pairs -> pairs at sets of 1 and 2 members.
    let pairs = lists(2, 2);                       // the 4 pairs over {0, 1}
    let mut survivors: Vec<L> = Vec::new();
    for c in functions(4, 4) {                     // 256 candidate rules at the 2-member set
        let eta = |m: usize, xs: &L| if m == 1 { xs.clone() } else { pairs[c[pos(&pairs, xs)]].clone() };
        if squares(&eta, &[1, 2], &[2]).1 == 0 { survivors.push(pairs[c[1]].clone()) }
    }
    let shown: Vec<String> = survivors.iter().map(|s| show(s)).collect();
    println!("candidate rules on pairs: {}; natural: {}", functions(4, 4).len(), survivors.len());
    println!("their answers on the generic pair [0, 1]: {}", show(&shown));
    println!("Yoneda's count, functions 2 -> 2: {}", functions(2, 2).len());

    // 5. Groups alongside: the 6 rearrangements of 3 slots, composed.
    let g: Vec<L> = functions(3, 3).into_iter().filter(|p| p[0] != p[1] && p[0] != p[2] && p[1] != p[2]).collect();
    let e: L = vec![0, 1, 2];
    let nat: Vec<L> = functions(6, 6).into_iter()      // phi(h g) = phi(h) g for every h, g
        .filter(|phi| g.iter().all(|h| g.iter().all(|x| g[phi[pos(&g, &comp(h, x))]] == comp(&g[phi[pos(&g, h)]], x))))
        .collect();
    let left = nat.iter().all(|phi| (0..6).all(|i| g[phi[i]] == comp(&g[phi[pos(&g, &e)]], &g[i])));
    println!("group of {} rearrangements; reversal is {}", g.len(), show(&g[pos(&g, &vec![2, 1, 0])]));
    println!("maps G -> G respecting composing on the right: {} of {}", nat.len(), 6usize.pow(6));
    println!("each is 'compose with phi(identity) on the left': {}", yn(left));
    let mut cayley: Vec<L> = g.iter().map(|a| g.iter().map(|h| pos(&g, &comp(a, h))).collect()).collect();
    cayley.sort();
    cayley.dedup();
    println!("Cayley: {} members give {} different rearrangements of the group", g.len(), cayley.len());

    assert!(route_a == route_b && sort_a != sort_b);                 // one square each way
    assert!(rev_failed == 0 && sort_failed > 0 && rev_checked == 4820); // brute force
    assert!(rebuilt && recipe == vec![2, 1, 0] && recipes_ok == 27);  // Yoneda's rebuild
    assert!(survivors == lists(2, 2) && survivors.len() == functions(2, 2).len()); // blind count
    assert!(nat.len() == g.len() && left && cayley.len() == g.len()); // Cayley, one object
    println!("ALL CHECKS PASS");
}
