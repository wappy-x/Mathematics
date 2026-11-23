-- The continuum hypothesis: the card's two forms of CH agree, CH holds for closed sets of reals, and the line is at least aleph one but never aleph omega.
import Mathlib.Analysis.Real.Cardinality
import Mathlib.SetTheory.Cardinal.Continuum
import Mathlib.SetTheory.Cardinal.Regular
import Mathlib.Topology.MetricSpace.Perfect

open Cardinal

/-- The continuum hypothesis in its two forms says the same thing (with choice, which Lean
assumes): the number of points on the line, two to the aleph nought, is aleph one exactly when
every set of points of the line is either listable or as big as the line. -/
theorem continuum_hypothesis_iff_every_set_of_reals_listable_or_full_size :
    (2 : Cardinal.{0}) ^ ℵ₀ = ℵ₁ ↔ ∀ S : Set ℝ, S.Countable ∨ #S = #ℝ := by
  rw [← Cardinal.continuum, ← mk_real]
  constructor
  · intro h S
    by_cases hS : S.Countable
    · exact Or.inl hS
    · right
      have h1 : ℵ₁ ≤ #S := by
        rw [aleph_one_le_iff, lt_iff_not_ge, le_aleph0_iff_set_countable]
        exact hS
      have h2 : #S ≤ #ℝ := mk_set_le S
      rw [h] at h2 ⊢
      exact le_antisymm h2 h1
  · intro h
    have hle : ℵ₁ ≤ #(Set.univ : Set ℝ) := by
      rw [mk_univ, mk_real]; exact aleph_one_le_continuum
    obtain ⟨S, -, hS⟩ := le_mk_iff_exists_subset.1 hle
    have hnc : ¬ S.Countable := by
      rw [← le_aleph0_iff_set_countable, hS, not_le]
      exact aleph0_lt_aleph_one
    rcases h S with h' | h'
    · exact absurd h' hnc
    · rw [← h', hS]

/-- For closed sets of reals ZFC settles the question: every closed set of points of the line
that cannot be listed is as big as the line (the Cantor–Bendixson theorem). -/
theorem uncountable_closed_set_of_reals_has_full_size (C : Set ℝ) (hC : IsClosed C)
    (hunc : ¬ C.Countable) : #C = #ℝ := by
  obtain ⟨f, hfC, -, hf⟩ := hC.exists_nat_bool_injection_of_not_countable hunc
  refine le_antisymm (mk_set_le C) ?_
  rw [mk_real, ← two_power_aleph0]
  have hinj : Function.Injective (fun x : ℕ → Bool => (⟨f x, hfC ⟨x, rfl⟩⟩ : C)) := by
    intro x y hxy
    exact hf (congrArg Subtype.val hxy)
  have := mk_le_of_injective hinj
  simpa using this

/-- Cantor's gap and König's bound: the number of points on the line is at least aleph one,
and it is never aleph omega, the first aleph after aleph one, aleph two, aleph three, and so on. -/
theorem aleph_one_le_two_pow_aleph0_and_ne_aleph_omega :
    ℵ₁ ≤ (2 : Cardinal.{0}) ^ ℵ₀ ∧ (2 : Cardinal.{0}) ^ ℵ₀ ≠ ℵ_ Ordinal.omega0 := by
  refine ⟨aleph_one_le_continuum, fun h => ?_⟩
  have hk := lt_cof_ord_power (a := ℵ₀) (b := (2 : Cardinal.{0})) le_rfl one_lt_two
  rw [h, ord_aleph, Ordinal.cof_omega Ordinal.isSuccLimit_omega0, Ordinal.cof_omega0] at hk
  exact lt_irrefl _ hk

-- Finite sizes strictly between n and 2^n, for n = 0 to 6, counted and by 2^n - n - 1.
example : (List.range 7).map (fun n => (Finset.Ioo n (2 ^ n)).card) = [0, 0, 1, 4, 11, 26, 57] := by
  decide
example : (List.range 7).map (fun n => 2 ^ n - n - 1) = [0, 0, 1, 4, 11, 26, 57] := by
  decide

-- The ground list's first 12 binary digits: 1/3, 1/7 and 2/5 by one division.
example : 1 * 4096 / 3 = 0b010101010101 ∧ 1 * 4096 / 7 = 0b001001001001 ∧
    2 * 4096 / 5 = 0b011001100110 := by
  norm_num

-- sqrt 2 - 1 and sqrt 3 - 1: squaring the 12-digit prefix brackets 2 * 4^12 and 3 * 4^12.
example : (4096 + 0b011010100000) ^ 2 ≤ 2 * 4 ^ 12 ∧ 2 * 4 ^ 12 < (4096 + 0b011010100000 + 1) ^ 2 := by
  norm_num
example : (4096 + 0b101110110110) ^ 2 ≤ 3 * 4 ^ 12 ∧ 3 * 4 ^ 12 < (4096 + 0b101110110110 + 1) ^ 2 := by
  norm_num

-- Conditions of length 12 that dodge all six listed reals: the six starts are 6 different
-- strings of 12 digits (numbers below 4096), so 4096 minus 6 = 4090 conditions dodge them.
example : (∀ v ∈ [0, 0b010101010101, 0b001001001001, 0b011001100110, 0b011010100000,
      0b101110110110], v < 4096) ∧
    4096 - [0, 0b010101010101, 0b001001001001, 0b011001100110, 0b011010100000,
      0b101110110110].toFinset.card = 4090 := by
  decide

-- The generic 0.11... already differs from every listed real in its first two digits.
example : 0b11 ∉ [0, 0b010101010101, 0b001001001001, 0b011001100110, 0b011010100000,
    0b101110110110].map (· / 1024) := by
  decide

-- Four new reals: 4 × 6 list dense sets plus 6 pair dense sets make 30.
example : 4 * 6 + Nat.choose 4 2 = 30 := by
  decide

-- Gödel's finite levels: 0, 1, 2, 4, 16, 65536 sets, each two to the power of the one before.
example : (List.range 6).map (fun n => (fun k => 2 ^ k)^[n] 0) = [0, 1, 2, 4, 16, 65536] := by
  decide

#print axioms continuum_hypothesis_iff_every_set_of_reals_listable_or_full_size
#print axioms uncountable_closed_set_of_reals_has_full_size
#print axioms aleph_one_le_two_pow_aleph0_and_ne_aleph_omega
