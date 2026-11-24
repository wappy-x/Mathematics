-- Dedekind cuts: a bounded collection of cuts of the fractions has their union as least upper bound, any two cuts are nested, and the cut for root 2 is a cut that no fraction gives.
import Mathlib.Algebra.Order.Field.Rat
import Mathlib.Order.Bounds.Basic
import Mathlib.Order.SetNotation
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.NormNum.IsSquare
import Mathlib.Tactic.Linarith
import Mathlib.Tactic.Positivity

namespace DedekindCuts

/-- A set of fractions is a **cut** when it passes three tests: it holds some fractions but not
all, it is closed downward (with any fraction it holds every smaller one), and it has no largest
member. -/
def IsCut (S : Set ℚ) : Prop :=
  S.Nonempty ∧ S ≠ Set.univ ∧ IsLowerSet S ∧ ∀ a ∈ S, ∃ b ∈ S, a < b

/-- The cut for the diagonal of the one-metre tile: every fraction `q` with `q < 0` or
`q × q < 2`. -/
def rootTwoCut : Set ℚ := {q | q < 0 ∨ q * q < 2}

/-- 2 is not the square of any fraction. -/
theorem two_not_square_rat : ¬ IsSquare (2 : ℚ) := by norm_num

/-- The step `q ↦ (2q + 2)/(q + 2)` moves a nonnegative fraction squaring under 2 up, and keeps
its square under 2. -/
theorem step_up (a : ℚ) (ha : 0 ≤ a) (h : a * a < 2) :
    a < (2 * a + 2) / (a + 2) ∧ (2 * a + 2) / (a + 2) * ((2 * a + 2) / (a + 2)) < 2 := by
  have hp : 0 < a + 2 := by linarith
  constructor
  · rw [lt_div_iff₀ hp]; nlinarith
  · rw [div_mul_div_comm, div_lt_iff₀ (by positivity)]; nlinarith

/-- The same step moves a nonnegative fraction squaring over 2 down, keeping it nonnegative
with square over 2. -/
theorem step_down (t : ℚ) (ht : 0 ≤ t) (h : 2 < t * t) :
    (2 * t + 2) / (t + 2) < t ∧ 2 < (2 * t + 2) / (t + 2) * ((2 * t + 2) / (t + 2)) ∧
      0 ≤ (2 * t + 2) / (t + 2) := by
  have hp : 0 < t + 2 := by linarith
  refine ⟨?_, ?_, by positivity⟩
  · rw [div_lt_iff₀ hp]; nlinarith
  · rw [div_mul_div_comm, lt_div_iff₀ (by positivity)]; nlinarith

/-- **The union is the least upper bound.** Take one or more cuts, all inside one cut `B`. Their
union `U` (every fraction in any of them) is a cut, every cut in the collection sits inside `U`,
and any set holding every cut in the collection holds `U`. Cuts are ordered by sitting inside
each other, so `U` is their least upper bound. -/
theorem union_of_bounded_cuts_is_least_upper_bound (C : Set (Set ℚ))
    (hcuts : ∀ M ∈ C, IsCut M) (hne : C.Nonempty)
    (B : Set ℚ) (hB : IsCut B) (hbound : ∀ M ∈ C, M ⊆ B) :
    IsCut (⋃₀ C) ∧ IsLUB C (⋃₀ C) := by
  obtain ⟨M0, hM0⟩ := hne
  refine ⟨⟨?_, ?_, ?_, ?_⟩, ?_, ?_⟩
  · obtain ⟨x, hx⟩ := (hcuts M0 hM0).1
    exact ⟨x, M0, hM0, hx⟩
  · intro hU
    apply hB.2.1
    apply Set.eq_univ_of_forall
    intro x
    have hx : x ∈ ⋃₀ C := hU ▸ Set.mem_univ x
    obtain ⟨M, hM, hxM⟩ := hx
    exact hbound M hM hxM
  · intro a b hba ha
    obtain ⟨M, hM, haM⟩ := ha
    exact ⟨M, hM, (hcuts M hM).2.2.1 hba haM⟩
  · intro a ha
    obtain ⟨M, hM, haM⟩ := ha
    obtain ⟨b, hbM, hab⟩ := (hcuts M hM).2.2.2 a haM
    exact ⟨b, ⟨M, hM, hbM⟩, hab⟩
  · intro M hM
    exact Set.subset_sUnion_of_mem hM
  · intro X hX
    exact Set.sUnion_subset hX

/-- **Cuts line up.** Of two cuts, one always sits inside the other. -/
theorem cuts_are_nested (M N : Set ℚ) (hM : IsCut M) (hN : IsCut N) :
    M ⊆ N ∨ N ⊆ M := by
  by_contra hcon
  rw [not_or] at hcon
  obtain ⟨hMN, hNM⟩ := hcon
  obtain ⟨a, haM, haN⟩ := Set.not_subset.mp hMN
  obtain ⟨b, hbN, hbM⟩ := Set.not_subset.mp hNM
  rcases le_total a b with hab | hba
  · exact haN (hN.2.2.1 hab hbN)
  · exact hbM (hM.2.2.1 hba haM)

/-- **Root 2 arrives as a theorem.** The set of fractions below 0 or squaring under 2 is a cut,
and it is not the cut at any fraction `t` (the fractions below `t`). -/
theorem root_two_cut_is_a_cut_no_fraction_gives :
    IsCut rootTwoCut ∧ ∀ t : ℚ, rootTwoCut ≠ Set.Iio t := by
  have hcut : IsCut rootTwoCut := by
    refine ⟨⟨0, Or.inr (by norm_num)⟩, ?_, ?_, ?_⟩
    · intro h
      have h2 : (2 : ℚ) ∈ rootTwoCut := h ▸ Set.mem_univ _
      rcases h2 with h2 | h2 <;> norm_num at h2
    · intro b a hab hb
      rcases le_or_gt 0 a with ha | ha
      · rcases hb with hb | hb
        · exact absurd (lt_of_le_of_lt hab hb) (not_lt.mpr ha)
        · exact Or.inr (lt_of_le_of_lt (mul_le_mul hab hab ha (le_trans ha hab)) hb)
      · exact Or.inl ha
    · intro a ha
      rcases le_or_gt 0 a with h0 | h0
      · have ha2 : a * a < 2 := by
          rcases ha with ha | ha
          · exact absurd ha (not_lt.mpr h0)
          · exact ha
        obtain ⟨h1, h2⟩ := step_up a h0 ha2
        exact ⟨_, Or.inr h2, h1⟩
      · exact ⟨0, Or.inr (by norm_num), h0⟩
  refine ⟨hcut, ?_⟩
  intro t ht
  have htnot : t ∉ rootTwoCut := by
    rw [ht]; exact lt_irrefl t
  have ht0 : 0 ≤ t := by
    by_contra h; exact htnot (Or.inl (not_le.mp h))
  have ht2 : 2 ≤ t * t := by
    by_contra h; exact htnot (Or.inr (not_le.mp h))
  have ht2' : 2 < t * t := by
    rcases lt_or_eq_of_le ht2 with h | h
    · exact h
    · exact absurd ⟨t, h⟩ two_not_square_rat
  obtain ⟨h1, h2, h3⟩ := step_down t ht0 ht2'
  have hq : (2 * t + 2) / (t + 2) ∈ rootTwoCut := by
    rw [ht]; exact h1
  rcases hq with hq | hq
  · exact absurd hq (not_lt.mpr h3)
  · exact absurd (lt_trans hq h2) (lt_irrefl _)

/-! ### The card's worked numbers, as exact fractions -/

/-- 1.4 and 1.41 are in L (1.96 and 1.9881 are under 2); 1.42 is not (2.0164). -/
example : (140 / 100 : ℚ) ∈ rootTwoCut ∧ (141 / 100 : ℚ) ∈ rootTwoCut ∧
    (142 / 100 : ℚ) ∉ rootTwoCut := by
  norm_num [rootTwoCut]

/-- The squares behind those answers: 140² = 19600, 141² = 19881, 142² = 20164. -/
example : 140 * 140 = 19600 ∧ 141 * 141 = 19881 ∧ 142 * 142 = 20164 := by
  norm_num [rootTwoCut]

/-- No largest member: (2q + 2) ÷ (q + 2) takes 7/5 to 24/17, then 41/29, then 140/99. -/
example : (2 * (7 / 5) + 2) / (7 / 5 + 2 : ℚ) = 24 / 17 ∧
    (2 * (24 / 17) + 2) / (24 / 17 + 2 : ℚ) = 41 / 29 ∧
    (2 * (41 / 29) + 2) / (41 / 29 + 2 : ℚ) = 140 / 99 := by
  norm_num [rootTwoCut]

/-- Each step of that chain is bigger and still in L. -/
example : (7 / 5 : ℚ) < 24 / 17 ∧ (24 / 17 : ℚ) < 41 / 29 ∧ (41 / 29 : ℚ) < 140 / 99 ∧
    (24 / 17 : ℚ) ∈ rootTwoCut ∧ (41 / 29 : ℚ) ∈ rootTwoCut ∧ (140 / 99 : ℚ) ∈ rootTwoCut := by
  norm_num [rootTwoCut]

/-- L + L: 2.828 is a sum of members (1.414 + 1.414), but 2.829 is not, since its half, 1.4145,
squares to 2.00081025. -/
example : (1414 / 1000 : ℚ) ∈ rootTwoCut ∧ (1414 / 1000 + 1414 / 1000 : ℚ) = 2828 / 1000 ∧
    (2829 / 1000 / 2 : ℚ) = 14145 / 10000 ∧ (14145 / 10000 : ℚ) ∉ rootTwoCut ∧
    14145 * 14145 = 200081025 := by
  norm_num [rootTwoCut]

/-- L × L from 1.414: 1.414 × 1.414 = 1.999396; and 1.41421 × 1.41421 = 1.9999899241. -/
example : (1414 / 1000 : ℚ) * (1414 / 1000) = 1999396 / 1000000 ∧
    (141421 / 100000 : ℚ) * (141421 / 100000) = 19999899241 / 10000000000 := by
  norm_num [rootTwoCut]

/-- What breaks: −5 squares to 25, yet it is in L because it is below 0; and the cut at
1.41421356 misses 1.414213562, which is in L (1.41421356 squares to 1.9999999932878736). -/
example : (-5 : ℚ) * (-5) = 25 ∧ (-5 : ℚ) ∈ rootTwoCut ∧
    (141421356 : ℕ) * 141421356 = 19999999932878736 ∧
    (1414213562 / 1000000000 : ℚ) ∈ rootTwoCut ∧
    (1414213562 / 1000000000 : ℚ) ∉ Set.Iio (141421356 / 100000000 : ℚ) := by
  norm_num [rootTwoCut]

#print axioms two_not_square_rat
#print axioms step_up
#print axioms step_down
#print axioms union_of_bounded_cuts_is_least_upper_bound
#print axioms cuts_are_nested
#print axioms root_two_cut_is_a_cut_no_fraction_gives

end DedekindCuts
