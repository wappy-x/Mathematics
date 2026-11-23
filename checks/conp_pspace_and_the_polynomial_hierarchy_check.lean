-- Above NP: a sentence of alternating there-exists and for-all blocks over short bit strings is decided by depth-first search that holds one pick per level, its complement is the sentence with every quantifier swapped and the referee flipped, a sentence with k blocks also has k + 1 blocks of either starting kind, and the card's 4 by 4 sudoku counts hold.
import Mathlib.Data.List.Nodup
import Mathlib.Data.Nat.Choose.Basic
import Mathlib.Order.SetNotation
import Mathlib.Tactic.NormNum

namespace AboveNP

/-! ### Alternating sentences

A pick y is a bit string, `List Bool`. The referee V reads the picks made so far, in order, and
answers 1 (`true`) or 0 (`false`). The Boolean `q` names the first quantifier: `true` is
there-exists, `false` is for-all. Each pick has at most N bits. For a problem, N is |x|^d and the
referee is `V x`; the card also asks V to run in polynomial time, which these statements do not
need: every referee built below from V (flipped, or ignoring one pick) is as fast as V. -/

/-- The sentence Q₁ y₁ Q₂ y₂ ⋯ Q_k y_k : V(ys, y₁, …, y_k) = 1, with k alternating quantifiers
starting with there-exists when `q = true`, each over bit strings of at most N bits, after the
picks `ys` already made. -/
def Sentence (N : ℕ) (V : List (List Bool) → Bool) : ℕ → Bool → List (List Bool) → Prop
  | 0, _, ys => V ys = true
  | k + 1, true, ys => ∃ y : List Bool, y.length ≤ N ∧ Sentence N V k false (ys ++ [y])
  | k + 1, false, ys => ∀ y : List Bool, y.length ≤ N → Sentence N V k true (ys ++ [y])

/-- Every bit string of at most N bits, in a fixed order: the empty string, then each shorter
string with one bit put in front. -/
def shortStrings : ℕ → List (List Bool)
  | 0 => [[]]
  | N + 1 => [] :: (shortStrings N).flatMap fun y => [false :: y, true :: y]

/-- The card's procedure eval(i), depth first: at a there-exists level, try every short string
in turn and answer 1 when some branch answers 1; at a for-all level, answer 1 when every branch
does; with no quantifier left, ask the referee. The only thing kept from level to level is the
list of current picks, one string per level, which each new try overwrites. -/
def eval (N : ℕ) (V : List (List Bool) → Bool) : ℕ → Bool → List (List Bool) → Bool
  | 0, _, ys => V ys
  | k + 1, true, ys => (shortStrings N).any fun y => eval N V k false (ys ++ [y])
  | k + 1, false, ys => (shortStrings N).all fun y => eval N V k true (ys ++ [y])

/-- A string is in `shortStrings N` exactly when it has at most N bits. -/
theorem mem_shortStrings (N : ℕ) (y : List Bool) : y ∈ shortStrings N ↔ y.length ≤ N := by
  induction N generalizing y with
  | zero =>
    cases y with
    | nil => simp [shortStrings]
    | cons b z => simp [shortStrings]
  | succ N ih =>
    cases y with
    | nil => simp [shortStrings]
    | cons b z =>
      cases b <;> simp [shortStrings, ih]

/-- Depth-first evaluation agrees with the sentence after any picks. -/
theorem sentence_iff_eval (N : ℕ) (V : List (List Bool) → Bool) (k : ℕ) :
    ∀ (q : Bool) (ys : List (List Bool)), Sentence N V k q ys ↔ eval N V k q ys = true := by
  induction k with
  | zero => intro q ys; cases q <;> simp [Sentence, eval]
  | succ k ih =>
    intro q ys
    cases q <;> simp [Sentence, eval, List.any_eq_true, List.all_eq_true, mem_shortStrings, ih]

/-- Negating a sentence swaps every quantifier and flips the referee. -/
theorem not_sentence_iff (N : ℕ) (V : List (List Bool) → Bool) (k : ℕ) :
    ∀ (q : Bool) (ys : List (List Bool)),
      ¬ Sentence N V k q ys ↔ Sentence N (fun ys => !V ys) k (!q) ys := by
  induction k with
  | zero => intro q ys; cases q <;> simp [Sentence]
  | succ k ih =>
    intro q ys
    cases q
    · simp only [Sentence, Bool.not_false]
      push Not
      constructor
      · rintro ⟨y, hy, h⟩; exact ⟨y, hy, (ih true _).1 h⟩
      · rintro ⟨y, hy, h⟩; exact ⟨y, hy, (ih true _).2 h⟩
    · simp only [Sentence, Bool.not_true]
      push Not
      constructor
      · intro h y hy; exact (ih false _).1 (h y hy)
      · intro h y hy; exact (ih false _).2 (h y hy)

/-- A last block whose pick the referee drops changes nothing. -/
theorem sentence_dropLast_succ (N : ℕ) (V : List (List Bool) → Bool) (k : ℕ) :
    ∀ (q : Bool) (ys : List (List Bool)),
      Sentence N (fun ys => V ys.dropLast) (k + 1) q ys ↔ Sentence N V k q ys := by
  induction k with
  | zero =>
    intro q ys
    cases q
    · simp only [Sentence, List.dropLast_concat]
      exact ⟨fun h => h [] (Nat.zero_le _), fun h _ _ => h⟩
    · simp only [Sentence, List.dropLast_concat]
      exact ⟨fun ⟨_, _, h⟩ => h, fun h => ⟨[], Nat.zero_le _, h⟩⟩
  | succ k ih =>
    intro q ys
    cases q
    · simp only [Sentence] at ih ⊢
      exact forall_congr' fun y => imp_congr_right fun _ => ih true _
    · simp only [Sentence] at ih ⊢
      exact exists_congr fun y => and_congr_right fun _ => ih false _

/-- A first pick that the referee drops changes nothing. -/
theorem sentence_tail_cons (N : ℕ) (V : List (List Bool) → Bool) (y : List Bool) (k : ℕ) :
    ∀ (q : Bool) (ys : List (List Bool)),
      Sentence N (fun ys => V ys.tail) k q (y :: ys) ↔ Sentence N V k q ys := by
  induction k with
  | zero => intro q ys; cases q <;> simp [Sentence]
  | succ k ih =>
    intro q ys
    cases q
    · simp only [Sentence, List.cons_append]
      exact forall_congr' fun z => imp_congr_right fun _ => ih true _
    · simp only [Sentence, List.cons_append]
      exact exists_congr fun z => and_congr_right fun _ => ih false _

#print axioms mem_shortStrings
#print axioms sentence_iff_eval
#print axioms not_sentence_iff
#print axioms sentence_dropLast_succ
#print axioms sentence_tail_cons

/-- Step 4 of the card (every rung, and every count of blocks that grows with the input, fits in
polynomial memory): if a problem L is given by alternating blocks over picks of at most |x|^d bits,
with a number of blocks `blocks x` that may be fixed or may grow with x, then depth-first
evaluation, holding one pick per level, decides L exactly: x is a yes-input when eval answers 1. -/
theorem depth_first_search_decides_alternating_sentence (L : Set (List Bool))
    (V : List Bool → List (List Bool) → Bool) (d : ℕ) (blocks : List Bool → ℕ) (q : Bool)
    (hL : ∀ x, x ∈ L ↔ Sentence (x.length ^ d) (V x) (blocks x) q []) (x : List Bool) :
    x ∈ L ↔ eval (x.length ^ d) (V x) (blocks x) q [] = true := by
  rw [hL x]
  exact sentence_iff_eval _ _ _ _ _

/-- Step 1 of the card (a complement swaps the players): if k alternating blocks starting with
quantifier q define L, then the complement Lᶜ is defined by k alternating blocks starting with the
other quantifier, over the same short picks, with the referee's answer flipped. At k = 1 with
q = there-exists this is coNP: the complement of an NP problem is one for-all block. -/
theorem complement_swaps_every_quantifier (L : Set (List Bool))
    (V : List Bool → List (List Bool) → Bool) (d k : ℕ) (q : Bool)
    (hL : ∀ x, x ∈ L ↔ Sentence (x.length ^ d) (V x) k q []) :
    ∀ x, x ∈ Lᶜ ↔ Sentence (x.length ^ d) (fun ys => !V x ys) k (!q) [] := by
  intro x
  rw [Set.mem_compl_iff, hL x]
  exact not_sentence_iff _ _ _ _ _

/-- Step 3 of the card (the rungs nest): add a quantifier over a pick the referee ignores. If k
alternating blocks starting with q define L, then so do k + 1 blocks starting with q (the new
block at the end, its pick dropped by the referee) and k + 1 blocks starting with the other
quantifier (the new block at the front, its pick dropped by the referee). So every problem on
rung k, of either kind, is on rung k + 1 of both kinds. -/
theorem rung_k_lies_on_rung_k_succ_of_both_kinds (L : Set (List Bool))
    (V : List Bool → List (List Bool) → Bool) (d k : ℕ) (q : Bool)
    (hL : ∀ x, x ∈ L ↔ Sentence (x.length ^ d) (V x) k q []) :
    (∀ x, x ∈ L ↔ Sentence (x.length ^ d) (fun ys => V x ys.dropLast) (k + 1) q []) ∧
    (∀ x, x ∈ L ↔ Sentence (x.length ^ d) (fun ys => V x ys.tail) (k + 1) (!q) []) := by
  refine ⟨fun x => ?_, fun x => ?_⟩
  · rw [hL x]
    exact (sentence_dropLast_succ _ _ _ _ _).symm
  · rw [hL x]
    cases q
    · simp only [Bool.not_false, Sentence, List.nil_append, sentence_tail_cons]
      exact ⟨fun h => ⟨[], Nat.zero_le _, h⟩, fun ⟨_, _, h⟩ => h⟩
    · simp only [Bool.not_true, Sentence, List.nil_append, sentence_tail_cons]
      exact ⟨fun h _ _ => h, fun h => h [] (Nat.zero_le _)⟩

/-! ### The card's 4 by 4 sudoku

A grid is four rows of four digits from 1 to 4, read as cells 0 to 15 row by row. -/

/-- The digits 1 to 4. -/
def digits : List ℕ := [1, 2, 3, 4]

/-- The 24 orderings of 1 2 3 4: every row of a legal grid is one of them. -/
def rows4 : List (List ℕ) :=
  (digits.flatMap fun a => digits.flatMap fun b => digits.flatMap fun c =>
    digits.map fun e => [a, b, c, e]).filter fun r => decide r.Nodup

/-- Cell i of a grid, counting row by row from 0. -/
def cell (g : List (List ℕ)) (i : ℕ) : ℕ := (g.getD (i / 4) []).getD (i % 4) 0

/-- Every column and every 2 by 2 box holds four different digits. -/
def legalGrid (g : List (List ℕ)) : Bool :=
  (List.range 4).all (fun c => decide ((List.range 4).map fun r => cell g (4 * r + c)).Nodup) &&
  [0, 2, 8, 10].all (fun s => decide [cell g s, cell g (s + 1), cell g (s + 4), cell g (s + 5)].Nodup)

/-- The code's road two: stack three orderings under the first row 1 2 3 4 and keep the legal
grids. -/
def gridsFrom1234 : List (List (List ℕ)) :=
  rows4.flatMap fun a => rows4.flatMap fun b =>
    (rows4.map fun c => [[1, 2, 3, 4], a, b, c]).filter legalGrid

/-- Each grid starting 1 2 3 4, relabelled by each of the 24 orderings (digit d becomes the d-th
entry of the ordering). Every legal grid relabels to one starting 1 2 3 4, so this lists them all. -/
def allGrids : List (List (List ℕ)) :=
  rows4.flatMap fun a => gridsFrom1234.map fun g => g.map (List.map fun d => a.getD (d - 1) 0)

/-- The grid 1234 / 3412 / 2143 / 4321. -/
def T : List (List ℕ) := [[1, 2, 3, 4], [3, 4, 1, 2], [2, 1, 4, 3], [4, 3, 2, 1]]

/-- The number of grids that agree with T on the given cells. -/
def fits (cells : List ℕ) : ℕ :=
  (allGrids.filter fun g => cells.all fun i => cell g i == cell T i).length

/-- Every choice of 3 of the 16 cells, in increasing order. -/
def choose3 : List (List ℕ) :=
  (List.range 16).flatMap fun i => (List.range 16).flatMap fun j =>
    (List.range 16).filterMap fun l => if i < j ∧ j < l then some [i, j, l] else none

/-- Every choice of 4 of the 16 cells, in increasing order. -/
def choose4 : List (List ℕ) :=
  (List.range 16).flatMap fun i => (List.range 16).flatMap fun j =>
    (List.range 16).flatMap fun l => (List.range 16).filterMap fun m =>
      if i < j ∧ j < l ∧ l < m then some [i, j, l, m] else none

-- 12 legal grids start 1 2 3 4; times 24 relabellings gives 288 distinct legal grids.
example : rows4.length = 24 := by decide +kernel
example : gridsFrom1234.length = 12 := by decide +kernel
example : 12 * 24 = 288 := by norm_num
example : (allGrids.filter legalGrid).length = 288 ∧ allGrids.Nodup := by decide +kernel
-- T is a legal grid.
example : legalGrid T = true ∧ T ∈ allGrids := by decide +kernel
-- 3 givens: 560 choices, none pins T, and the fewest grids fitting a choice is 3. So mistake 3,
-- the for-every dropped, finds T fitting all 560 choices.
example : choose3.length = 560 ∧ Nat.choose 16 3 = 560 := by decide +kernel
example : choose3.all (fun s => 3 ≤ fits s) = true ∧ choose3.any (fun s => fits s == 3) = true := by
  decide +kernel
-- 4 givens: 1820 choices, 12 of them pin T; 1820 × 288 = 524,160 grid checks.
example : choose4.length = 1820 ∧ Nat.choose 16 4 = 1820 := by decide +kernel
example : (choose4.filter fun s => fits s == 1).length = 12 := by decide +kernel
example : 1820 * 288 = 524160 := by norm_num

-- The draughts opening: 17 plies are 9 White moves and 8 Black replies; depth-first memory is
-- 24 positions of 36 squares, the table 78,763 positions of 36 squares.
example : 9 + 8 = 17 ∧ 17 / 2 + 1 = 9 ∧ 17 / 2 = 8 := by norm_num
example : (23 + 1) * (6 * 6) = 864 := by norm_num
example : 78763 * 36 = 2835468 := by norm_num

#print axioms depth_first_search_decides_alternating_sentence
#print axioms complement_swaps_every_quantifier
#print axioms rung_k_lies_on_rung_k_succ_of_both_kinds

end AboveNP
