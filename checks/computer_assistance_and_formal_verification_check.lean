-- Machines in proofs: in every finite graph the darts, the degree sum and twice the edge count agree, the wheel (a hub and a ring of 5) needs exactly four colours with k(k - 2)^5 - k(k - 2) proper k-colourings, and the card's small cases check out exactly.
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Combinatorics.SimpleGraph.Coloring.Vertex
import Mathlib.Data.Nat.Prime.Basic
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.IntervalCases
import Mathlib.Tactic.Ring
import Mathlib.Data.Fin.VecNotation

open SimpleGraph Finset

/-- The degree-sum formula, read as a double count of darts (the card's quoted Lean lemma):
in every finite graph, the number of darts (edges given a direction) equals the sum of all the
degrees, and also equals twice the number of edges: |D| = ∑ deg(v) = 2E. -/
theorem card_darts_eq_sum_degrees_eq_twice_card_edges {V : Type*} [Fintype V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    Fintype.card G.Dart = ∑ v, G.degree v ∧ ∑ v, G.degree v = 2 * #G.edgeFinset := by
  exact ⟨G.dart_card_eq_sum_degrees, G.sum_degrees_eq_twice_card_edges⟩

/-! The card's wheel: hub `0` joined to a ring of 5, rim vertices `1` to `5` in order. -/

/-- The wheel's neighbour lists. -/
def wheelNbrs : Fin 6 → List (Fin 6)
  | 0 => [1, 2, 3, 4, 5]
  | 1 => [0, 2, 5]
  | 2 => [0, 1, 3]
  | 3 => [0, 2, 4]
  | 4 => [0, 3, 5]
  | 5 => [0, 4, 1]

/-- The wheel: a hub and a ring of 5, the pattern of a region with five neighbours in a ring. -/
def wheel : SimpleGraph (Fin 6) where
  Adj u v := v ∈ wheelNbrs u
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel wheel.Adj := fun u v => inferInstanceAs (Decidable (v ∈ wheelNbrs u))

/-- The indicator of equality, as an integer. -/
def dlt {β : Type*} [DecidableEq β] (x y : β) : ℤ := if x = y then 1 else 0

/-- Summing against the equality indicator picks out one value. -/
lemma sum_dlt_mul_left {β : Type*} [Fintype β] [DecidableEq β] (x : β) (f : β → ℤ) :
    ∑ y, dlt x y * f y = f x := by
  simp [dlt]
#print axioms sum_dlt_mul_left

/-- The same, with the indicator's arguments the other way round. -/
lemma sum_dlt_mul_right {β : Type*} [Fintype β] [DecidableEq β] (x : β) (f : β → ℤ) :
    ∑ y, dlt y x * f y = f x := by
  simp [dlt]
#print axioms sum_dlt_mul_right

/-- Paths of length 2 from `a` to `c` with no repeated colour: m - 2, plus 1 when a = c. -/
lemma sum_one_sub_dlt_mul {β : Type*} [Fintype β] [DecidableEq β] (a c : β) :
    ∑ b, (1 - dlt a b) * (1 - dlt b c) = ((Fintype.card β : ℤ) - 2) + dlt a c := by
  have h : ∀ b, (1 - dlt a b) * (1 - dlt b c)
      = 1 - dlt a b * 1 - dlt b c * 1 + dlt a b * dlt b c := fun b => by ring
  simp only [h, sum_add_distrib, sum_sub_distrib, sum_dlt_mul_left, sum_dlt_mul_right]
  simp [dlt]
  ring
#print axioms sum_one_sub_dlt_mul

/-- A ring of 5 has (m - 1)^5 - (m - 1) proper colourings with m colours. -/
lemma card_cycle_five {β : Type*} [Fintype β] [DecidableEq β] :
    (Fintype.card {t : β × β × β × β × β // t.1 ≠ t.2.1 ∧ t.2.1 ≠ t.2.2.1 ∧
      t.2.2.1 ≠ t.2.2.2.1 ∧ t.2.2.2.1 ≠ t.2.2.2.2 ∧ t.2.2.2.2 ≠ t.1} : ℤ)
      = ((Fintype.card β : ℤ) - 1) ^ 5 - ((Fintype.card β : ℤ) - 1) := by
  set m : ℤ := (Fintype.card β : ℤ) with hm
  rw [Fintype.card_subtype, card_filter]
  push_cast
  simp only [Fintype.sum_prod_type]
  have key : ∀ a b c d e : β, (if a ≠ b ∧ b ≠ c ∧ c ≠ d ∧ d ≠ e ∧ e ≠ a then (1 : ℤ) else 0)
      = ((1 - dlt a b) * (1 - dlt b c)) * (((1 - dlt c d) * (1 - dlt d e)) * (1 - dlt e a)) := by
    intro a b c d e
    by_cases h1 : a = b
    · subst h1; simp [dlt]
    by_cases h2 : b = c
    · subst h2; simp [dlt]
    by_cases h3 : c = d
    · subst h3; simp [dlt]
    by_cases h4 : d = e
    · subst h4; simp [dlt]
    by_cases h5 : e = a
    · subst h5; simp [dlt]
    simp [dlt, h1, h2, h3, h4, h5]
  simp only [key]
  simp_rw [← Finset.mul_sum]
  have h2 : ∀ a c : β, ∑ d, ∑ e, ((1 - dlt c d) * (1 - dlt d e)) * (1 - dlt e a)
      = ∑ e, ((m - 2) + dlt c e) * (1 - dlt e a) := by
    intro a c
    rw [Finset.sum_comm]
    simp_rw [← Finset.sum_mul, sum_one_sub_dlt_mul]
    rfl
  simp_rw [h2]
  have h1 : ∀ a : β, ∑ b, ∑ c, ((1 - dlt a b) * (1 - dlt b c)) *
      ∑ e, ((m - 2) + dlt c e) * (1 - dlt e a)
      = ∑ c, ((m - 2) + dlt a c) * ∑ e, ((m - 2) + dlt c e) * (1 - dlt e a) := by
    intro a
    rw [Finset.sum_comm]
    simp_rw [← Finset.sum_mul, sum_one_sub_dlt_mul]
    rfl
  simp_rw [h1]
  have h3 : ∀ a c : β, ∑ e, ((m - 2) + dlt c e) * (1 - dlt e a)
      = (m - 2) * (m - 1) + (1 - dlt c a) := by
    intro a c
    have h : ∀ e, ((m - 2) + dlt c e) * (1 - dlt e a)
        = (m - 2) - (m - 2) * dlt e a + dlt c e * (1 - dlt e a) := fun e => by ring
    simp only [h, sum_add_distrib, sum_sub_distrib, sum_dlt_mul_left, ← mul_sum]
    simp [dlt, hm]
    ring
  simp_rw [h3]
  have h4 : ∀ a : β, ∑ c, ((m - 2) + dlt a c) * ((m - 2) * (m - 1) + (1 - dlt c a))
      = (m - 2) * (m * ((m - 2) * (m - 1)) + (m - 1)) + (m - 2) * (m - 1) := by
    intro a
    have h : ∀ c, ((m - 2) + dlt a c) * ((m - 2) * (m - 1) + (1 - dlt c a))
        = (m - 2) * ((m - 2) * (m - 1)) + (m - 2) - (m - 2) * dlt c a
          + dlt a c * ((m - 2) * (m - 1) + (1 - dlt c a)) := fun c => by ring
    simp only [h, sum_add_distrib, sum_sub_distrib, sum_dlt_mul_left, ← mul_sum]
    simp [dlt, hm]
    ring
  simp_rw [h4]
  simp [hm]
  ring
#print axioms card_cycle_five

/-- A colouring of the wheel is a hub colour `h` and a proper colouring of the 5-cycle rim
by colours other than `h`. -/
def wheelColoringEquiv (α : Type*) :
    wheel.Coloring α ≃ Σ h : α, {t : {x // x ≠ h} × {x // x ≠ h} × {x // x ≠ h} × {x // x ≠ h} ×
      {x // x ≠ h} // t.1 ≠ t.2.1 ∧ t.2.1 ≠ t.2.2.1 ∧ t.2.2.1 ≠ t.2.2.2.1 ∧
        t.2.2.2.1 ≠ t.2.2.2.2 ∧ t.2.2.2.2 ≠ t.1} where
  toFun C :=
    have hv : ∀ u v : Fin 6, wheel.Adj u v → C u ≠ C v := fun _ _ h => C.valid h
    ⟨C 0, ⟨(⟨C 1, hv 1 0 (by decide)⟩, ⟨C 2, hv 2 0 (by decide)⟩, ⟨C 3, hv 3 0 (by decide)⟩,
      ⟨C 4, hv 4 0 (by decide)⟩, ⟨C 5, hv 5 0 (by decide)⟩),
      fun e => hv 1 2 (by decide) (congrArg Subtype.val e),
      fun e => hv 2 3 (by decide) (congrArg Subtype.val e),
      fun e => hv 3 4 (by decide) (congrArg Subtype.val e),
      fun e => hv 4 5 (by decide) (congrArg Subtype.val e),
      fun e => hv 5 1 (by decide) (congrArg Subtype.val e)⟩⟩
  invFun p :=
    Coloring.mk ![p.1, p.2.1.1.1, p.2.1.2.1.1, p.2.1.2.2.1.1, p.2.1.2.2.2.1.1, p.2.1.2.2.2.2.1]
      (by
        obtain ⟨h, ⟨⟨a, b, c, d, e⟩, h1, h2, h3, h4, h5⟩⟩ := p
        intro u v huv
        have n1 := a.2; have n2 := b.2; have n3 := c.2; have n4 := d.2; have n5 := e.2
        have m1 : a.1 ≠ b.1 := fun x => h1 (Subtype.ext x)
        have m2 : b.1 ≠ c.1 := fun x => h2 (Subtype.ext x)
        have m3 : c.1 ≠ d.1 := fun x => h3 (Subtype.ext x)
        have m4 : d.1 ≠ e.1 := fun x => h4 (Subtype.ext x)
        have m5 : e.1 ≠ a.1 := fun x => h5 (Subtype.ext x)
        fin_cases u <;> fin_cases v <;>
          first
          | exact absurd huv (by decide)
          | simpa using n1 | simpa using n2 | simpa using n3 | simpa using n4 | simpa using n5
          | simpa using n1.symm | simpa using n2.symm | simpa using n3.symm | simpa using n4.symm
          | simpa using n5.symm
          | simpa using m1 | simpa using m2 | simpa using m3 | simpa using m4 | simpa using m5
          | simpa using m1.symm | simpa using m2.symm | simpa using m3.symm | simpa using m4.symm
          | simpa using m5.symm)
  left_inv C := by
    apply RelHom.ext
    intro v
    fin_cases v <;> rfl
  right_inv p := by
    obtain ⟨h, ⟨⟨a, b, c, d, e⟩, hc⟩⟩ := p
    rfl

/-- The wheel's colouring count: k hub colours, each with the ring count for k - 1 colours. -/
lemma wheel_card_colorings_formula (k : ℕ) :
    (Fintype.card (wheel.Coloring (Fin k)) : ℤ) = k * (((k : ℤ) - 2) ^ 5 - ((k : ℤ) - 2)) := by
  rw [Fintype.card_congr (wheelColoringEquiv (Fin k)), Fintype.card_sigma]
  push_cast
  have hR : ∀ h : Fin k, (Fintype.card {x // x ≠ h} : ℤ) = (k : ℤ) - 1 := by
    intro h
    have hk : 1 ≤ k := h.pos
    rw [Fintype.card_subtype_compl, Fintype.card_subtype_eq, Fintype.card_fin]
    push_cast [hk]
    ring
  simp only [card_cycle_five, hR]
  simp
  ring
#print axioms wheel_card_colorings_formula

/-- The wheel needs four colours: it has a proper colouring with 4 colours and none with 3
(the odd rim takes three colours and the hub, touching all five, a fourth). -/
theorem wheel_chromaticNumber_eq_four : wheel.chromaticNumber = 4 := by
  rw [show (4 : ℕ∞) = ((3 : ℕ) : ℕ∞) + 1 by norm_num, chromaticNumber_eq_iff_colorable_not_colorable]
  have h4 : (Fintype.card (wheel.Coloring (Fin 4)) : ℤ) = 120 := by
    rw [wheel_card_colorings_formula]; norm_num
  have h3 : (Fintype.card (wheel.Coloring (Fin 3)) : ℤ) = 0 := by
    rw [wheel_card_colorings_formula]; norm_num
  refine ⟨Fintype.card_pos_iff.mp ?_, ?_⟩
  · have : (0 : ℤ) < Fintype.card (wheel.Coloring (Fin 4)) := by rw [h4]; norm_num
    exact_mod_cast this
  · rw [Colorable, not_nonempty_iff]
    exact Fintype.card_eq_zero_iff.mp (by exact_mod_cast h3)

/-- The wheel's chromatic polynomial, a formula for every number of colours k at once: the
wheel has exactly P(k) = k((k - 2)^5 - (k - 2)) proper colourings with k colours. -/
theorem card_wheel_colorings (k : ℕ) :
    (Fintype.card (wheel.Coloring (Fin k)) : ℤ) = k * (((k : ℤ) - 2) ^ 5 - ((k : ℤ) - 2)) := by
  exact wheel_card_colorings_formula k

/-! The card's worked numbers. -/

/-- The card's search, as in its code: colour list number `code` gives vertex `i` the colour
`code / k^i % k`, so the codes `0` to `k^6 - 1` run through all `k^6` assignments. -/
def colourOf (k code : ℕ) (i : Fin 6) : ℕ := code / k ^ i.val % k

/-- The number of assignments of `k` colours to the 6 vertices that give the two ends of every
edge of `G` different colours, found by trying all `k^6`. -/
def searchCount (G : SimpleGraph (Fin 6)) [DecidableRel G.Adj] (k : ℕ) : ℕ :=
  ((range (k ^ 6)).filter fun code => ∀ u v, G.Adj u v → colourOf k code u ≠ colourOf k code v).card

-- Evidence: n^2 + n + 41 is prime for n = 0 to 39, checked for 40 values.
example : ∀ n < 40, Nat.Prime (n ^ 2 + n + 41) := by
  intro n hn
  interval_cases n <;> norm_num
-- What breaks: n = 40 gives 1600 + 40 + 41 = 1681 = 41 × 41, composite.
example : 40 ^ 2 + 40 + 41 = 1681 ∧ 1681 = 41 * 41 ∧ ¬ Nat.Prime 1681 := by norm_num

-- Exact computation: the two sides of the near miss, digit for digit.
example : (1782 : ℕ) ^ 12 + 1841 ^ 12 = 2541210258614589176288669958142428526657 ∧
    (1922 : ℕ) ^ 12 = 2541210259314801410819278649643651567616 := by norm_num
-- To 10 digits both are 2.541210259 × 10^39: both lie in [25412102585, 25412102595) × 10^29.
example : 25412102585 * 10 ^ 29 ≤ (1782 : ℕ) ^ 12 + 1841 ^ 12 ∧
    (1782 : ℕ) ^ 12 + 1841 ^ 12 < 25412102595 * 10 ^ 29 ∧
    25412102585 * 10 ^ 29 ≤ (1922 : ℕ) ^ 12 ∧ (1922 : ℕ) ^ 12 < 25412102595 * 10 ^ 29 := by
  norm_num
-- The exact difference, so the near miss is no counterexample to Fermat's last theorem.
example : ((1782 : ℤ) ^ 12 + 1841 ^ 12) - 1922 ^ 12 = -700212234530608691501223040959 := by
  norm_num
example : (1782 : ℕ) ^ 12 + 1841 ^ 12 ≠ 1922 ^ 12 := by norm_num
-- Parity: the left side is odd, the right side even.
example : (1782 ^ 12 + 1841 ^ 12) % 2 = 1 ∧ 1922 ^ 12 % 2 = 0 := by norm_num
-- The difference modulo 2, 3, 5, 7, 11, 13 from residues of the bases, and from the exact number.
example : [2, 3, 5, 7, 11, 13].map (fun p : ℕ => (1782 ^ 12 % p + 1841 ^ 12 % p + p - 1922 ^ 12 % p) % p)
      = [1, 0, 1, 0, 7, 1] ∧
    [2, 3, 5, 7, 11, 13].map (fun p : ℤ => (-700212234530608691501223040959 : ℤ) % p)
      = [1, 0, 1, 0, 7, 1] := by
  decide +kernel

-- Symbolic: k((k - 2)^5 - (k - 2)) expands to k^6 - 10k^5 + 40k^4 - 80k^3 + 79k^2 - 30k.
example (k : ℤ) : k * ((k - 2) ^ 5 - (k - 2)) =
    k ^ 6 - 10 * k ^ 5 + 40 * k ^ 4 - 80 * k ^ 3 + 79 * k ^ 2 - 30 * k := by ring
-- P(3) = 3 × (1 - 1) = 0, P(4) = 4 × (2^5 - 2) = 4 × 30 = 120, P(5) = 1200.
example : (3 : ℤ) * ((3 - 2) ^ 5 - (3 - 2)) = 0 ∧ (4 : ℤ) * ((4 - 2) ^ 5 - (4 - 2)) = 120 ∧
    4 * (2 ^ 5 - 2) = 4 * 30 ∧ (5 : ℤ) * ((5 - 2) ^ 5 - (5 - 2)) = 1200 := by norm_num

-- The wheel: 6 vertices, 10 edges, degrees hub 5 and rim 3.
example : wheel.edgeFinset.card = 10 ∧ wheel.degree 0 = 5 ∧
    ∀ v : Fin 6, v ≠ 0 → wheel.degree v = 3 := by
  decide
-- Exhaustive search: of 4^6 = 4,096 assignments of 4 colours, 120 are proper;
-- of 3^6 = 729 assignments of 3 colours, none is.
example : 4 ^ 6 = 4096 ∧ searchCount wheel 4 = 120 := by decide +kernel
example : 3 ^ 6 = 729 ∧ searchCount wheel 3 = 0 := by decide +kernel
-- The certificate for "four suffice": hub 3, rim 2, 1, 0, 1, 0, rechecked edge by edge.
example : ∀ u v, wheel.Adj u v → (![3, 2, 1, 0, 1, 0] : Fin 6 → ℕ) u ≠ (![3, 2, 1, 0, 1, 0] : Fin 6 → ℕ) v := by
  decide

/-- The wrong map: the wheel with the rim line 1–2 left out. -/
def holedNbrs : Fin 6 → List (Fin 6)
  | 0 => [1, 2, 3, 4, 5]
  | 1 => [0, 5]
  | 2 => [0, 3]
  | 3 => [0, 2, 4]
  | 4 => [0, 3, 5]
  | 5 => [0, 4, 1]

/-- The wheel with the rim line 1–2 left out, as a graph. -/
def holedWheel : SimpleGraph (Fin 6) where
  Adj u v := v ∈ holedNbrs u
  symm := ⟨by decide⟩
  loopless := ⟨by decide⟩

instance : DecidableRel holedWheel.Adj := fun u v =>
  inferInstanceAs (Decidable (v ∈ holedNbrs u))

-- It is the wheel minus exactly that one line.
example : holedWheel = wheel.deleteEdges {s(1, 2)} := by
  ext u v
  simp only [deleteEdges_adj, Set.mem_singleton_iff]
  revert u v
  decide
-- Searching the wrong map: 6 proper 3-colourings appear, and P = 6 there too.
example : searchCount holedWheel 3 = 6 := by decide +kernel

-- Darts on the wheel: 20 by start vertex (hub 5 + rim 5 × 3) and 20 = 2 × 10 by edge.
example : Fintype.card wheel.Dart = 20 ∧ ∑ v, wheel.degree v = 20 ∧ 5 + 5 * 3 = 20 ∧
    2 * wheel.edgeFinset.card = 20 := by
  decide +kernel

/-! The icosahedron: 12 corners, 30 edges, five edges at every corner. Corner `0` on top,
`1` to `5` an upper ring, `6` to `10` a lower ring, `11` at the bottom, as in the card's code. -/

/-- The icosahedron's 30 edges, as listed in the card's code. -/
def icoEdges : List (Fin 12 × Fin 12) :=
  [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (1, 2), (2, 3), (3, 4), (4, 5), (5, 1),
   (11, 6), (11, 7), (11, 8), (11, 9), (11, 10), (6, 7), (7, 8), (8, 9), (9, 10), (10, 6),
   (1, 6), (2, 7), (3, 8), (4, 9), (5, 10), (1, 7), (2, 8), (3, 9), (4, 10), (5, 6)]

/-- The icosahedron as a graph: two corners are joined when the pair is on the edge list. -/
def icosahedron : SimpleGraph (Fin 12) where
  Adj u v := u ≠ v ∧ ((u, v) ∈ icoEdges ∨ (v, u) ∈ icoEdges)
  symm := ⟨fun _ _ h => ⟨h.1.symm, h.2.symm⟩⟩
  loopless := ⟨fun _ h => h.1 rfl⟩

instance : DecidableRel icosahedron.Adj := fun u v =>
  inferInstanceAs (Decidable (u ≠ v ∧ ((u, v) ∈ icoEdges ∨ (v, u) ∈ icoEdges)))

-- The icosahedron: 30 edges, degree 5 everywhere, 60 darts = 12 × 5 = 2 × 30.
example : icoEdges.length = 30 ∧ icoEdges.Nodup ∧ icosahedron.edgeFinset.card = 30 ∧
    (∀ v, icosahedron.degree v = 5) := by
  decide +kernel
example : Fintype.card icosahedron.Dart = 60 ∧ ∑ v, icosahedron.degree v = 60 ∧
    12 * 5 = 60 ∧ 2 * icosahedron.edgeFinset.card = 60 := by
  decide +kernel

-- The mistake, edges counted once: degree sum 20 against 10 edges, not equal.
example : ∑ v, wheel.degree v ≠ wheel.edgeFinset.card := by decide +kernel

#print axioms card_darts_eq_sum_degrees_eq_twice_card_edges
#print axioms wheel_chromaticNumber_eq_four
#print axioms card_wheel_colorings
