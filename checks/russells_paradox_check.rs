// Russell's paradox -- the same check as the Python one, in Rust.  No crates.
// Three villagers: Ada shaves herself, Ben does not, Cyd is the barber who
// shaves the villagers who do not shave themselves.  Then the trap for sets.
const VILLAGERS: [&str; 3] = ["Ada", "Ben", "Cyd"];

#[derive(Clone, PartialEq)]
enum Item { Villager(&'static str), Set(Vec<Item>) }   // a member may be a set

fn list_of(n: usize) -> Vec<&'static str> { (0..3).filter(|i| n >> i & 1 == 1).map(|i| VILLAGERS[i]).collect() }
fn as_set(l: &[&'static str]) -> Item { Item::Set(l.iter().map(|v| Item::Villager(v)).collect()) }
fn holds(s: &Item, m: &Item) -> bool { matches!(s, Item::Set(ms) if ms.contains(m)) }
fn size(s: &Item) -> usize { match s { Item::Set(ms) => ms.len(), _ => 0 } }
fn shaves_self(v: &str, l: &[&str]) -> bool { v == "Ada" || (v == "Cyd" && l.contains(&"Cyd")) }
fn promise_ok(v: &str, l: &[&str]) -> bool { l.contains(&v) == !shaves_self(v, l) }
fn row(name: &str, value: usize) { println!("{:<46}{:>2}", name, value); }

fn main() {
    let lists: Vec<Vec<&str>> = (0..8).map(list_of).collect();
    let sets: Vec<Item> = lists.iter().map(|l| as_set(l)).collect();
    let kept = lists.iter().filter(|l| VILLAGERS.iter().all(|v| promise_ok(v, l))).count();
    let others = lists.iter().filter(|l| promise_ok("Ada", l) && promise_ok("Ben", l)).count();
    let broken = lists.iter().filter(|l| !promise_ok("Cyd", l)).count();
    let holders = sets.iter().filter(|&s| holds(s, s)).count();
    let russell = Item::Set(sets.iter().filter(|&s| !holds(s, s)).cloned().collect());
    let biggest = sets.iter().map(size).max().unwrap();
    row("villagers in the village", VILLAGERS.len());
    row("lists of villagers there are, in all", lists.len());
    row("lists that get Ada and Ben right", others);
    row("lists that keep the barber's whole promise", kept);
    row("lists that break it at the barber himself", broken);
    row("of the eight sets, ones that hold themselves", holders);
    row("the Russell set, how many it holds", size(&russell));
    row("the most members any one of the eight holds", biggest);
    row("how many of the eight hold eight", sets.iter().filter(|&s| size(s) == 8).count());
    row("the Russell set found among the eight", sets.contains(&russell) as usize);
    assert!(lists.len() == 8 && others == 2 && kept == 0 && broken == 8);
    assert!(holders == 0 && size(&russell) == 8 && biggest == 3 && !sets.contains(&russell));
    println!("ALL CHECKS PASS");
}
