// Indexed families -- the same check as the Python, in Rust.  No crates.  The
// deck indexed by rank and by suit, then the intervals [0, 1/n) and [1/n, 1].
const SUITS: [&str; 4] = ["clubs", "diamonds", "hearts", "spades"];
const RANKS: [&str; 13] = ["2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"];
type Card = (&'static str, &'static str);
fn main() {
    let deck: Vec<Card> = SUITS.iter().flat_map(|s| RANKS.iter().map(move |r| (*s, *r))).collect();
    let fam = |r: &str| -> Vec<Card> { deck.iter().copied().filter(|c| c.1 == r).collect() };
    let suit = |s: &str| -> Vec<Card> { deck.iter().copied().filter(|c| c.0 == s).collect() };
    let a: Vec<Vec<Card>> = RANKS.iter().map(|r| fam(r)).collect();   // rank -> its 4 cards
    let union: Vec<Card> = deck.iter().copied().filter(|c| a.iter().any(|x| x.contains(c))).collect();
    let inter: Vec<Card> = deck.iter().copied().filter(|c| a.iter().all(|x| x.contains(c))).collect();
    let hb = suit("hearts");                             // the distributive law, both sides
    let hearts: Vec<Card> = union.iter().copied().filter(|c| hb.contains(c)).collect();
    let by_rank: Vec<Card> = a.iter().flatten().copied().filter(|c| hb.contains(c)).collect();
    let mut picks: Vec<Vec<Card>> = vec![vec![]];       // one card from each suit, a suit at a time
    for s in SUITS {
        picks = picks.iter().flat_map(|p| suit(s).into_iter().map(move |c| { let mut q = p.clone(); q.push(c); q })).collect();
    }
    let g: u64 = 60;                                     // points k/60, k = 0..60; sets n = 1..60
    let pts: Vec<u64> = (0..=g).collect();
    let in_every: Vec<u64> = pts.iter().copied().filter(|k| (1..=g).all(|n| k * n < g)).collect();
    let in_some: Vec<u64> = pts.iter().copied().filter(|k| (1..=g).any(|n| k * n >= g)).collect();
    let outside: Vec<u64> = pts.iter().copied().filter(|k| !in_some.contains(k)).collect();
    let no_flip: Vec<u64> = pts.iter().copied().filter(|k| (1..=g).any(|n| k * n < g)).collect();
    let drop = (1u64..1_000_000).find(|n| !(1 * n < 1000)).unwrap();   // 1/1000 is in [0, 1/n) while 1*n < 1000
    println!("rank family: {} sets of {} cards; union {}, intersection {}", a.len(), a[12].len(), union.len(), inter.len());
    println!("distributive law: hearts in the union {}; union of the hearts in each pile {}", hearts.len(), by_rank.len());
    println!("one card from each suit: {} picks, by formula 13^4 = {}", picks.len(), 13u64.pow(4));
    println!("points tested: {}; in every [0, 1/n): {}, at x = {}", pts.len(), in_every.len(), in_every[0]);
    println!("in some [1/n, 1]: {}; outside that union: {}, at x = {}", in_some.len(), outside.len(), outside[0]);
    println!("0.001 drops out of [0, 1/n) at n = {}", drop);
    println!("the three mistakes come out at {}, {} and {}", union.len(), 4u64.pow(13), no_flip.len());
    assert!(union.len() == 13 * 4 && inter.is_empty() && hearts == by_rank && hearts.len() == 13 && deck.len() == 52);
    assert!(picks.len() == 13usize.pow(4) && picks.iter().all(|p| (0..4).all(|i| p[i].0 == SUITS[i])));
    assert!(outside == in_every && in_every == vec![0] && in_some.len() == 60 && no_flip.len() == 60); // De Morgan
    println!("ALL CHECKS PASS");
}
