-- Total search problems: under Sperner's rule a triangle cut into small triangles always has an odd number of three-coloured small triangles, a finite graph has an even number of odd-degree nodes, and the shift-swap game has exactly three Nash equilibria, the mixed one at chances 2/3 and 1/3.
import Mathlib.Combinatorics.SimpleGraph.DegreeSum
import Mathlib.Data.Finset.Prod
import Mathlib.Basic.Real.Basic
import Mathlib.Order.Interval.Set.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Data.ZMod.Basic
import Mathlib.Algebra.BigOperators.Ring.Finset
import Mathlib.Tactic.LinearCombination
import Mathlib.Tactic.Ring
import Mathlib.Tactic.Linarith

/-! ## Sperner's lemma on the triangular grid

The big triangle has side `M` steps. A grid point is `(a, b)` with `a + b ≤ M`: `a` steps right
along the bottom, `b` rows up. Corner 1 is `(0, 0)`, corner 2 is `(M, 0)`, corner 3 is `(0, M)`.
The bottom side is `b = 0`, the left side is `a = 0`, the slanted side is `a + b = M`.

The grid is cut into `M ^ 2` small triangles:
* an upward triangle with corners `(a, b)`, `(a + 1, b)`, `(a, b + 1)` when `a + b + 1 ≤ M`;
* a downward triangle with corners `(a + 1, b)`, `(a + 1, b + 1)`, `(a, b + 1)` when `a + b + 2 ≤ M`.
-/

/-- Base points `(a, b)` of the upward small triangles. -/
def upBases (M : ℕ) : Finset (ℕ × ℕ) :=
  (Finset.range M ×ˢ Finset.range M).filter fun p => p.1 + p.2 + 1 ≤ M

/-- Base points `(a, b)` of the downward small triangles. -/
def downBases (M : ℕ) : Finset (ℕ × ℕ) :=
  (Finset.range M ×ˢ Finset.range M).filter fun p => p.1 + p.2 + 2 ≤ M

/-- The number of three-coloured small triangles: those whose corners carry colours 1, 2 and 3. -/
def threeColouredCount (M : ℕ) (c : ℕ × ℕ → ℕ) : ℕ :=
  ((upBases M).filter fun p =>
      ({c p, c (p.1 + 1, p.2), c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2, 3}).card +
  ((downBases M).filter fun p =>
      ({c (p.1 + 1, p.2), c (p.1 + 1, p.2 + 1), c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2, 3}).card

/-- Helper: a three-coloured triangle has exactly one edge with colours 1 and 2; any other
triangle coloured from {1, 2, 3} has zero or two such edges. -/
lemma sperner_tri_parity (x y z : ℕ) (hx : x ∈ ({1, 2, 3} : Finset ℕ))
    (hy : y ∈ ({1, 2, 3} : Finset ℕ)) (hz : z ∈ ({1, 2, 3} : Finset ℕ)) :
    (if ({x, y, z} : Finset ℕ) = {1, 2, 3} then (1 : ZMod 2) else 0) =
      (if ({x, y} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0) +
      (if ({y, z} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0) +
      (if ({x, z} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0) := by
  simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy hz
  rcases hx with rfl | rfl | rfl <;> rcases hy with rfl | rfl | rfl <;>
    rcases hz with rfl | rfl | rfl <;> decide

#print axioms sperner_tri_parity

/-- Helper: an edge whose two ends both avoid colour 1, or both avoid colour 2, is not a 1-2 edge. -/
lemma sperner_pair_ne (x y : ℕ) (h : (x ≠ 1 ∧ y ≠ 1) ∨ (x ≠ 2 ∧ y ≠ 2)) :
    ({x, y} : Finset ℕ) ≠ {1, 2} := by
  intro h'
  have h1 : (1 : ℕ) ∈ ({x, y} : Finset ℕ) := by rw [h']; simp
  have h2 : (2 : ℕ) ∈ ({x, y} : Finset ℕ) := by rw [h']; simp
  simp only [Finset.mem_insert, Finset.mem_singleton] at h1 h2
  omega

#print axioms sperner_pair_ne

/-- Helper: along a path coloured 1 and 2 that starts at 1 and ends at 2, the number of
1-2 steps is odd. -/
lemma sperner_path_odd (M : ℕ) (f : ℕ → ℕ) (hf : ∀ a, a ≤ M → f a ∈ ({1, 2} : Finset ℕ))
    (h0 : f 0 = 1) (hM : f M = 2) :
    ∑ a ∈ Finset.range M,
      (if ({f a, f (a + 1)} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0) = 1 := by
  have key : ∀ a ∈ Finset.range M,
      (if ({f a, f (a + 1)} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0) =
        (fun x : ℕ => if f x = 2 then (1 : ZMod 2) else 0) (a + 1) -
        (fun x : ℕ => if f x = 2 then (1 : ZMod 2) else 0) a := by
    intro a ha
    rw [Finset.mem_range] at ha
    have hx := hf a (by omega)
    have hy := hf (a + 1) (by omega)
    simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy
    simp only
    rcases hx with hx | hx <;> rcases hy with hy | hy <;> rw [hx, hy] <;> decide
  rw [Finset.sum_congr rfl key,
    Finset.sum_range_sub (fun x : ℕ => if f x = 2 then (1 : ZMod 2) else 0)]
  simp [h0, hM]

#print axioms sperner_path_odd

/-- Helper: the edge sum over all small triangles telescopes to the bottom side, because every
inside edge is counted twice and the left and slanted sides carry no 1-2 edges. -/
lemma sperner_cancel (M : ℕ) (H V D : ℕ × ℕ → ZMod 2)
    (hV0 : ∀ b, b + 1 ≤ M → V (0, b) = 0)
    (hD : ∀ a b, a + b + 1 = M → D (a, b) = 0) :
    ∑ p ∈ upBases M, (H p + V p + D p) +
      ∑ p ∈ downBases M, (H (p.1, p.2 + 1) + V (p.1 + 1, p.2) + D p) =
      ∑ a ∈ Finset.range M, H (a, 0) := by
  have two : ∀ x : ZMod 2, x + x = 0 := by decide
  simp only [Finset.sum_add_distrib]
  -- horizontal edges
  have e1 := Finset.sum_filter_add_sum_filter_not (upBases M) (fun p => p.2 = 0) H
  have e2 : ∑ p ∈ (upBases M).filter (fun p => p.2 = 0), H p = ∑ a ∈ Finset.range M, H (a, 0) := by
    apply Finset.sum_nbij' Prod.fst (fun a => (a, 0))
    · intro p hp
      simp [upBases] at hp ⊢
      omega
    · intro a ha
      simp [upBases] at ha ⊢
      omega
    · intro p hp
      simp [upBases] at hp
      ext <;> simp [hp.2]
    · intro a _; rfl
    · intro p hp
      simp [upBases] at hp
      rw [← hp.2]
  have e3 : ∑ p ∈ downBases M, H (p.1, p.2 + 1) =
      ∑ p ∈ (upBases M).filter (fun p => ¬ p.2 = 0), H p := by
    apply Finset.sum_nbij' (fun p => (p.1, p.2 + 1)) (fun p => (p.1, p.2 - 1))
    · intro p hp
      simp [upBases, downBases] at hp ⊢
      omega
    · intro p hp
      simp [upBases, downBases] at hp ⊢
      omega
    · intro p _; simp
    · intro p hp
      simp [upBases] at hp
      ext
      · rfl
      · simp only; omega
    · intro p _; rfl
  -- vertical edges
  have v1 := Finset.sum_filter_add_sum_filter_not (upBases M) (fun p => p.1 = 0) V
  have v2 : ∑ p ∈ (upBases M).filter (fun p => p.1 = 0), V p = 0 := by
    apply Finset.sum_eq_zero
    intro p hp
    simp only [upBases, Finset.mem_filter, Finset.mem_product, Finset.mem_range] at hp
    obtain ⟨a, b⟩ := p
    simp only at hp
    rw [hp.2]
    exact hV0 b (by omega)
  have v3 : ∑ p ∈ downBases M, V (p.1 + 1, p.2) =
      ∑ p ∈ (upBases M).filter (fun p => ¬ p.1 = 0), V p := by
    apply Finset.sum_nbij' (fun p => (p.1 + 1, p.2)) (fun p => (p.1 - 1, p.2))
    · intro p hp
      simp [upBases, downBases] at hp ⊢
      omega
    · intro p hp
      simp [upBases, downBases] at hp ⊢
      omega
    · intro p _; simp
    · intro p hp
      simp [upBases] at hp
      ext
      · simp only; omega
      · rfl
    · intro p _; rfl
  -- diagonal edges
  have d1 := Finset.sum_filter_add_sum_filter_not (upBases M) (fun p => p.1 + p.2 + 2 ≤ M) D
  have d2 : (upBases M).filter (fun p => p.1 + p.2 + 2 ≤ M) = downBases M := by
    ext p
    simp only [upBases, downBases, Finset.mem_filter, Finset.mem_product, Finset.mem_range]
    omega
  have d3 : ∑ p ∈ (upBases M).filter (fun p => ¬ p.1 + p.2 + 2 ≤ M), D p = 0 := by
    apply Finset.sum_eq_zero
    intro p hp
    simp only [upBases, Finset.mem_filter, Finset.mem_product, Finset.mem_range] at hp
    obtain ⟨a, b⟩ := p
    exact hD a b (by simp only at hp; omega)
  rw [d2] at d1
  rw [← e1, ← d1, ← v1, e3, v3, v2, d3, ← e2]
  linear_combination two (∑ p ∈ (upBases M).filter (fun p => ¬ p.2 = 0), H p) +
    two (∑ p ∈ (upBases M).filter (fun p => ¬ p.1 = 0), V p) +
    two (∑ p ∈ downBases M, D p)

#print axioms sperner_cancel

/-- Sperner's lemma, the card's main exact claim: colour every grid point of a triangle cut into
small triangles with 1, 2 or 3, so that corner 1 gets colour 1, corner 2 gets 2, corner 3 gets 3,
and a point on a side uses only the colours of that side's two corners (inside, anything goes).
Then the number of three-coloured small triangles is odd; in particular at least one exists. -/
theorem sperner_three_coloured_count_odd (M : ℕ) (c : ℕ × ℕ → ℕ)
    (hcol : ∀ a b, a + b ≤ M → c (a, b) ∈ ({1, 2, 3} : Finset ℕ))
    (h1 : c (0, 0) = 1) (h2 : c (M, 0) = 2) (h3 : c (0, M) = 3)
    (hbottom : ∀ a, a ≤ M → c (a, 0) ∈ ({1, 2} : Finset ℕ))
    (hleft : ∀ b, b ≤ M → c (0, b) ∈ ({1, 3} : Finset ℕ))
    (hslant : ∀ a b, a + b = M → c (a, b) ∈ ({2, 3} : Finset ℕ)) :
    Odd (threeColouredCount M c) := by
  rcases Nat.eq_zero_or_pos M with rfl | hM
  · rw [h1] at h2; exact absurd h2 (by decide)
  have hV0 : ∀ b, b + 1 ≤ M →
      (fun p : ℕ × ℕ => if ({c p, c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2} then (1 : ZMod 2)
        else 0) (0, b) = 0 := by
    intro b hb
    have hx := hleft b (by omega)
    have hy := hleft (b + 1) hb
    simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy
    simp only
    exact ite_eq_right_iff.mpr fun h => absurd h (sperner_pair_ne _ _ (Or.inr ⟨by omega, by omega⟩))
  have hD : ∀ a b, a + b + 1 = M →
      (fun p : ℕ × ℕ => if ({c (p.1 + 1, p.2), c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2}
        then (1 : ZMod 2) else 0) (a, b) = 0 := by
    intro a b hab
    have hx := hslant (a + 1) b (by omega)
    have hy := hslant a (b + 1) (by omega)
    simp only [Finset.mem_insert, Finset.mem_singleton] at hx hy
    simp only
    exact ite_eq_right_iff.mpr fun h => absurd h (sperner_pair_ne _ _ (Or.inl ⟨by omega, by omega⟩))
  have key := sperner_cancel M
    (fun p => if ({c p, c (p.1 + 1, p.2)} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0)
    (fun p => if ({c p, c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2} then (1 : ZMod 2) else 0)
    (fun p => if ({c (p.1 + 1, p.2), c (p.1, p.2 + 1)} : Finset ℕ) = {1, 2}
      then (1 : ZMod 2) else 0) hV0 hD
  have bottom := sperner_path_odd M (fun a => c (a, 0)) hbottom h1 h2
  dsimp only at key bottom
  rw [← ZMod.natCast_eq_one_iff_odd, threeColouredCount, Nat.cast_add,
    Finset.natCast_card_filter, Finset.natCast_card_filter]
  refine Eq.trans ?_ (key.trans bottom)
  congr 1
  · apply Finset.sum_congr rfl
    rintro ⟨a, b⟩ hp
    simp only [upBases, Finset.mem_filter, Finset.mem_product, Finset.mem_range] at hp
    rw [sperner_tri_parity _ _ _ (hcol _ _ (by omega)) (hcol _ _ (by omega))
      (hcol _ _ (by omega))]
    ring
  · apply Finset.sum_congr rfl
    rintro ⟨a, b⟩ hp
    simp only [downBases, Finset.mem_filter, Finset.mem_product, Finset.mem_range] at hp
    rw [sperner_tri_parity _ _ _ (hcol _ _ (by omega)) (hcol _ _ (by omega))
      (hcol _ _ (by omega)), Finset.pair_comm (c (a + 1, b + 1)) (c (a, b + 1))]
    ring

/-! ## The parity argument behind PPA -/

/-- The parity argument (Step 1): in any finite graph the number of nodes with an odd number of
edges is even. -/
theorem even_card_odd_degree_nodes {V : Type*} [Fintype V] [DecidableEq V]
    (G : SimpleGraph V) [DecidableRel G.Adj] :
    Even (Finset.univ.filter fun v => Odd (G.degree v)).card := by
  exact G.even_card_odd_degree_vertices

/-! ## The shift-swap game

Two staff, A and B, each choose Early or Late. Payoffs (A, B): both Early (2, 1), both Late
(1, 2), different shifts (0, 0). `p` is A's chance of Early and `r` is B's chance of Early. -/

/-- A's expected payoff when A takes Early with chance `p` and B with chance `r`. -/
def payoffA (p r : ℝ) : ℝ :=
  2 * p * r + 0 * p * (1 - r) + 0 * (1 - p) * r + 1 * (1 - p) * (1 - r)

/-- B's expected payoff when A takes Early with chance `p` and B with chance `r`. -/
def payoffB (p r : ℝ) : ℝ :=
  1 * p * r + 0 * p * (1 - r) + 0 * (1 - p) * r + 2 * (1 - p) * (1 - r)

/-- A Nash equilibrium in mixed choices: both chances lie in [0, 1], and neither player can raise
their expected payoff by changing their own chance alone. -/
def IsShiftSwapEquilibrium (p r : ℝ) : Prop :=
  p ∈ Set.Icc (0 : ℝ) 1 ∧ r ∈ Set.Icc (0 : ℝ) 1 ∧
  (∀ p' ∈ Set.Icc (0 : ℝ) 1, payoffA p' r ≤ payoffA p r) ∧
  (∀ r' ∈ Set.Icc (0 : ℝ) 1, payoffB p r' ≤ payoffB p r)

/-- The shift-swap game has exactly three Nash equilibria, an odd number: both Early, both Late,
and the mix in which A takes Early with chance 2/3 and B takes Early with chance 1/3, so each
takes their favourite shift with chance 2/3. -/
theorem shift_swap_equilibria (p r : ℝ) :
    IsShiftSwapEquilibrium p r ↔
      (p = 1 ∧ r = 1) ∨ (p = 0 ∧ r = 0) ∨ (p = 2 / 3 ∧ r = 1 / 3) := by
  unfold IsShiftSwapEquilibrium payoffA payoffB
  simp only [Set.mem_Icc]
  constructor
  · rintro ⟨⟨hp0, hp1⟩, ⟨hr0, hr1⟩, hA, hB⟩
    have a0 := hA 0 ⟨le_refl _, zero_le_one⟩
    have a1 := hA 1 ⟨zero_le_one, le_refl _⟩
    have b0 := hB 0 ⟨le_refl _, zero_le_one⟩
    have b1 := hB 1 ⟨zero_le_one, le_refl _⟩
    rcases lt_trichotomy r (1 / 3) with h | h | h
    · have hp : p = 0 := by nlinarith
      subst hp
      exact Or.inr (Or.inl ⟨rfl, by nlinarith⟩)
    · subst h
      exact Or.inr (Or.inr ⟨by nlinarith, rfl⟩)
    · have hp : p = 1 := by nlinarith
      subst hp
      exact Or.inl ⟨rfl, by nlinarith⟩
  · rintro (⟨rfl, rfl⟩ | ⟨rfl, rfl⟩ | ⟨rfl, rfl⟩) <;>
      refine ⟨⟨by norm_num, by norm_num⟩, ⟨by norm_num, by norm_num⟩, ?_, ?_⟩ <;>
      rintro x ⟨hx0, hx1⟩ <;> nlinarith

/-! ## The card's worked examples -/

/-- The card's colouring of the side-4 triangle. -/
def cardColouring : ℕ × ℕ → ℕ
  | (0, 0) => 1 | (1, 0) => 2 | (2, 0) => 2 | (3, 0) => 2 | (4, 0) => 2
  | (0, 1) => 1 | (1, 1) => 1 | (2, 1) => 1 | (3, 1) => 2
  | (0, 2) => 3 | (1, 2) => 2 | (2, 2) => 2
  | (0, 3) => 1 | (1, 3) => 3
  | (0, 4) => 3
  | _ => 0

-- The card's colouring obeys Sperner's rule.
example : ∀ a ∈ Finset.range 5, ∀ b ∈ Finset.range 5, a + b ≤ 4 →
    cardColouring (a, b) ∈ ({1, 2, 3} : Finset ℕ) ∧
    (b = 0 → cardColouring (a, b) ∈ ({1, 2} : Finset ℕ)) ∧
    (a = 0 → cardColouring (a, b) ∈ ({1, 3} : Finset ℕ)) ∧
    (a + b = 4 → cardColouring (a, b) ∈ ({2, 3} : Finset ℕ)) := by decide

-- 16 small triangles: 10 upward and 6 downward.
example : (upBases 4).card = 10 ∧ (downBases 4).card = 6 := by decide

-- The scan of all 16 triangles finds 3 three-coloured ones.
example : threeColouredCount 4 cardColouring = 3 := by decide

-- Breaking the rule (top corner coloured 2) gives 4, an even count.
example : threeColouredCount 4 (Function.update cardColouring (0, 4) 2) = 4 := by decide

-- Legal colourings: 9 side points with 2 choices, 3 inside points with 3 choices.
example : 2 ^ 9 * 3 ^ 3 = 13824 := by norm_num

-- The tally of three-coloured counts over all legal colourings adds up to 13,824.
example : 2920 + 6192 + 3840 + 848 + 24 = 13824 := by norm_num

-- Lines of 2^n nodes walked in 2^n - 1 steps.
example : 2 ^ 8 - 1 = 255 ∧ 2 ^ 12 - 1 = 4095 ∧ 2 ^ 16 - 1 = 65535 := by norm_num
example : 2 ^ 40 - 1 = 1099511627775 := by norm_num

-- Staff pigeonhole: 1,024 groups but only 481 totals, and 33 = 12 + 21.
example : 2 ^ 10 = 1024 ∧ 10 * 48 + 1 = 481 ∧ 481 < 1024 ∧ 12 + 21 = 33 := by norm_num

-- Each staff member expects 2/3 at the mixed equilibrium.
example : payoffA (2 / 3) (1 / 3) = 2 / 3 ∧ payoffB (2 / 3) (1 / 3) = 2 / 3 := by
  norm_num [payoffA, payoffB]

-- The usual mistake: A mixes at 1/3 from A's own payoffs; B then gets 1/3 from Early, 4/3 from Late.
example : payoffB (1 / 3) 1 = 1 / 3 ∧ payoffB (1 / 3) 0 = 4 / 3 := by
  norm_num [payoffB]

#print axioms sperner_three_coloured_count_odd
#print axioms even_card_odd_degree_nodes
#print axioms shift_swap_equilibria
