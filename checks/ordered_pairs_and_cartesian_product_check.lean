-- Ordered pairs and the Cartesian product: for finite sets A and B, the set of all ordered pairs (a, b) with a from A and b from B has exactly |A| times |B| members, two pairs are equal exactly when both slots match, and when A and B share no member, A × B and B × A share no pair.
import Mathlib.Data.Finset.Prod
import Mathlib.Data.Finset.Card
import Mathlib.Tactic.NormNum

/-- The counting rule. Pair every member of a finite set A with every member of a finite set B,
first slot from A, second slot from B: the Cartesian product A × B has as many members as the
size of A times the size of B. (An empty side gives 0.) -/
theorem card_cartesian_product_eq_mul {α β : Type*} (A : Finset α) (B : Finset β) :
    (A ×ˢ B).card = A.card * B.card := by
  exact Finset.card_product A B

/-- The slots keep their order: two ordered pairs are the same exactly when their first slots
match and their second slots match. -/
theorem ordered_pair_eq_iff {α β : Type*} (a c : α) (b d : β) :
    (a, b) = (c, d) ↔ a = c ∧ b = d := by
  simp

/-- Flip every pair and you get B × A. When A and B share no member (no suit is a rank),
A × B and B × A share no pair: their intersection is empty. -/
theorem cartesian_product_disjoint_flip {α : Type*} [DecidableEq α] (A B : Finset α)
    (h : Disjoint A B) : A ×ˢ B ∩ B ×ˢ A = ∅ := by
  ext ⟨x, y⟩
  simp only [Finset.mem_inter, Finset.mem_product, Finset.notMem_empty, iff_false]
  rintro ⟨⟨hx, hy⟩, ⟨hy', hx'⟩⟩
  exact Finset.disjoint_left.mp h hx hy'

-- The card's deck: 4 suits times 13 ranks.
def suits : Finset String := {"clubs", "diamonds", "hearts", "spades"}
def ranks : Finset String :=
  {"2", "3", "4", "5", "6", "7", "8", "9", "10", "jack", "queen", "king", "ace"}

example : suits.card = 4 := by decide
example : ranks.card = 13 := by decide
example : (suits ×ˢ ranks).card = 52 := by decide
-- The deck, a suit at a time.
example : 13 + 13 + 13 + 13 = 52 ∧ 4 * 13 = 52 := by norm_num
-- (hearts, king) is a card; (king, hearts) is not.
example : ("hearts", "king") ∈ suits ×ˢ ranks := by decide
example : ("king", "hearts") ∉ suits ×ˢ ranks := by decide
-- The deck and the flipped deck share 0 cards.
example : (suits ×ˢ ranks ∩ ranks ×ˢ suits).card = 0 := by decide
-- The cafe: 2 drinks times 3 pastries, and the six written out.
example : (({"coffee", "tea"} : Finset String) ×ˢ ({"croissant", "scone", "muffin"} : Finset String)) =
    {("coffee", "croissant"), ("coffee", "scone"), ("coffee", "muffin"),
     ("tea", "croissant"), ("tea", "scone"), ("tea", "muffin")} := by decide
example : (({"coffee", "tea"} : Finset String) ×ˢ ({"croissant", "scone", "muffin"} : Finset String)).card = 6 := by decide
-- Four suits, no ranks.
example : (suits ×ˢ (∅ : Finset String)).card = 0 := by decide
-- The mistakes: adding gives 17, a deck missing its aces gives 48.
example : 4 + 13 = 17 ∧ 4 * 12 = 48 := by norm_num

#print axioms card_cartesian_product_eq_mul
#print axioms ordered_pair_eq_iff
#print axioms cartesian_product_disjoint_flip
