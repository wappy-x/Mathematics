-- The unit theorem: every unit of a number field's ring of integers is, in exactly one way, a root of unity times whole powers of r₁ + r₂ − 1 fundamental units.
import Mathlib.NumberTheory.NumberField.Units.DirichletTheorem
import Mathlib.NumberTheory.Zsqrtd.Basic

open NumberField NumberField.InfinitePlace NumberField.Units

/-- Helper: the unit theorem for any index count `n` equal to Mathlib's `rank K`. -/
theorem unit_theorem_of_rank_eq (K : Type*) [Field K] [NumberField K] (n : ℕ)
    (hn : NumberField.Units.rank K = n) :
    ∃ ε : Fin n → (𝓞 K)ˣ,
      ∀ u : (𝓞 K)ˣ, ∃! ζm : torsion K × (Fin n → ℤ),
        u = (ζm.1 : (𝓞 K)ˣ) * ∏ j, ε j ^ ζm.2 j := by
  subst hn
  exact ⟨fundSystem K, fun u => exist_unique_eq_mul_prod K u⟩

#print axioms unit_theorem_of_rank_eq

/-- Dirichlet's unit theorem. Let K be a number field, r₁ its number of real embeddings and
r₂ its number of pairs of complex embeddings. Then there are r = r₁ + r₂ − 1 fundamental
units ε₁, …, ε_r of the ring of integers O_K such that every unit u is, in exactly one way,
a root of unity ζ in O_K times whole powers of them: u = ζ · ε₁^m₁ ⋯ ε_r^m_r. -/
theorem units_eq_root_of_unity_mul_fundamental_units (K : Type*) [Field K] [NumberField K] :
    ∃ ε : Fin (nrRealPlaces K + nrComplexPlaces K - 1) → (𝓞 K)ˣ,
      ∀ u : (𝓞 K)ˣ, ∃! ζm : torsion K × (Fin (nrRealPlaces K + nrComplexPlaces K - 1) → ℤ),
        u = (ζm.1 : (𝓞 K)ˣ) * ∏ j, ε j ^ ζm.2 j := by
  apply unit_theorem_of_rank_eq
  rw [NumberField.Units.rank, card_eq_nrRealPlaces_add_nrComplexPlaces]

/-- The roots of unity in O_K form a finite cyclic group with w_K members, and a unit is one
of them exactly when its w_K-th power is 1. -/
theorem roots_of_unity_finite_cyclic (K : Type*) [Field K] [NumberField K] :
    Finite (torsion K) ∧ IsCyclic (torsion K) ∧
      ∀ ζ : (𝓞 K)ˣ, ζ ∈ torsion K ↔ ζ ^ torsionOrder K = 1 := by
  refine ⟨inferInstance, inferInstance, fun ζ => ⟨pow_torsionOrder_eq_one K, fun h => ?_⟩⟩
  rw [torsion, CommGroup.mem_torsion]
  exact isOfFinOrder_iff_pow_eq_one.2 ⟨torsionOrder K, torsionOrder_pos K, h⟩

/-- Step 1: a member of O_K is a unit exactly when its norm is +1 or −1. -/
theorem isUnit_iff_norm_eq_pm_one (K : Type*) [Field K] [NumberField K] (x : 𝓞 K) :
    IsUnit x ↔ (RingOfIntegers.norm ℚ x : ℚ) = 1 ∨ (RingOfIntegers.norm ℚ x : ℚ) = -1 := by
  rw [NumberField.isUnit_iff_norm, abs_eq zero_le_one]

-- Z[√2]: (1 + √2)(√2 − 1) = 1, so 1 + √2 is a unit.
example : (⟨1, 1⟩ : ℤ√2) * ⟨-1, 1⟩ = 1 := by decide
-- Its square is 3 + 2√2 and its cube is 7 + 5√2.
example : (⟨1, 1⟩ : ℤ√2) ^ 2 = ⟨3, 2⟩ := by decide
example : (⟨1, 1⟩ : ℤ√2) ^ 3 = ⟨7, 5⟩ := by decide
-- Norms a² − 2b² of the first five units above 1: −1, +1, −1, +1, −1.
example : Zsqrtd.norm (⟨1, 1⟩ : ℤ√2) = -1 := by decide
example : Zsqrtd.norm (⟨3, 2⟩ : ℤ√2) = 1 := by decide
example : Zsqrtd.norm (⟨7, 5⟩ : ℤ√2) = -1 := by decide
example : Zsqrtd.norm (⟨17, 12⟩ : ℤ√2) = 1 := by decide
example : Zsqrtd.norm (⟨41, 29⟩ : ℤ√2) = -1 := by decide
-- Q(∛2): the norm a³ + 2b³ + 4c³ − 6abc of 1 + θ + θ² is 1.
example : (1 : ℤ) ^ 3 + 2 * 1 ^ 3 + 4 * 1 ^ 3 - 6 * 1 * 1 * 1 = 1 := by norm_num
-- Ranks r₁ + r₂ − 1: Q(√2) has 2 + 0 − 1 = 1, Q(√−5) has 0 + 1 − 1 = 0,
-- Q(∛2) has 1 + 1 − 1 = 1, and the totally real cubic x³ + x² − 2x − 1 has 3 + 0 − 1 = 2.
example : (2 + 0 - 1 : ℕ) = 1 ∧ (0 + 1 - 1 : ℕ) = 0 ∧ (1 + 1 - 1 : ℕ) = 1 ∧ (3 + 0 - 1 : ℕ) = 2 := by
  decide

#print axioms units_eq_root_of_unity_mul_fundamental_units
#print axioms roots_of_unity_finite_cyclic
#print axioms isUnit_iff_norm_eq_pm_one
