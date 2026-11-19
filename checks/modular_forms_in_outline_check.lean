-- Modular forms: every space of level-1 modular forms of even weight k is finite-dimensional with dimension floor(k/12), plus 1 unless k is 2 mod 12, and a form is fixed by its first floor(k/12) + 1 coefficients.
import Mathlib.NumberTheory.ModularForms.LevelOne.DimensionFormula
import Mathlib.NumberTheory.ArithmeticFunction.Misc

open ModularForm UpperHalfPlane
open scoped MatrixGroups ArithmeticFunction.sigma

/-- The dimension of level-1 modular forms: for every even weight `k ≥ 0`, the space `M_k` of
holomorphic functions on the upper half plane with `f((az + b)/(cz + d)) = (cz + d)^k f(z)` for
every matrix in `SL₂(ℤ)` and bounded at the cusp is finite-dimensional, and its dimension is
`⌊k/12⌋`, plus 1 unless `k ≡ 2 (mod 12)`. -/
theorem dim_modular_forms_level_one (k : ℕ) (hk : Even k) :
    FiniteDimensional ℂ (ModularForm 𝒮ℒ (k : ℤ)) ∧
      Module.finrank ℂ (ModularForm 𝒮ℒ (k : ℤ)) = k / 12 + if k % 12 = 2 then 0 else 1 := by
  refine ⟨inferInstance, Module.finrank_eq_of_rank_eq ?_⟩
  rw [dimension_level_one k hk]
  by_cases h : k % 12 = 2
  · have h' : k ≡ 2 [MOD 12] := h
    simp [h, h']
  · have h' : ¬ k ≡ 2 [MOD 12] := h
    simp [h, h']

/-- A few coefficients fix the form: if a level-1 modular form of weight `k` has
`a_0 = a_1 = ⋯ = a_m = 0` in its q-expansion, where `m = ⌊k/12⌋`, then the form is 0. -/
theorem modular_form_eq_zero_of_first_coeffs_zero (k : ℕ) (f : ModularForm 𝒮ℒ (k : ℤ))
    (h : ∀ n ≤ k / 12, (qExpansion 1 f).coeff n = 0) : f = 0 := by
  refine sturm_bound_levelOne_nat ?_
  have hle : ((k / 12 + 1 : ℕ) : ℕ∞) ≤ (qExpansion 1 f).order := by
    refine PowerSeries.le_order _ _ fun i hi => h i ?_
    have : i < k / 12 + 1 := by exact_mod_cast hi
    omega
  refine lt_of_lt_of_le ?_ hle
  exact_mod_cast Nat.lt_succ_self _

/-- Every cusp form of weight 12 and level 1 is a constant times `Δ`. -/
theorem cusp_form_weight_twelve_eq_smul_discriminant (f : CuspForm 𝒮ℒ 12) :
    ∃ c : ℂ, f = c • CuspForm.discriminant := by
  obtain ⟨c, hc⟩ := CuspForm.exists_smul_discriminant_of_weight_eq_twelve f
  exact ⟨c, hc.symm⟩

-- The dimensions for k = 0, 2, ..., 36, as printed by the card's run.
example : (List.range 19).map (fun i => 2 * i / 12 + if 2 * i % 12 = 2 then 0 else 1) =
    [1, 0, 1, 1, 1, 1, 2, 1, 2, 2, 2, 2, 3, 2, 3, 3, 3, 3, 4] := by decide

-- The q coefficients of E₄³ and E₆²: 3 × 240 and 2 × (−504); their difference over 1728 is τ(1).
example : (3 * 240 : ℤ) = 720 ∧ (2 * (-504) : ℤ) = -1008 ∧ (720 - (-1008) : ℤ) / 1728 = 1 := by
  norm_num

-- τ(2) by Eisenstein series: (179280 − 220752)/1728 = −24.
example : ((179280 - 220752 : ℤ)) = -24 * 1728 := by norm_num

-- Multiplicativity: τ(6) = τ(2) τ(3) = −24 × 252 = −6048.
example : (-24 : ℤ) * 252 = -6048 := by norm_num

-- The 691 rule at n = 2: σ₁₁(2) − τ(2) = 2049 − (−24) = 2073 = 3 × 691.
example : σ 11 2 = 2049 ∧ ((2049 : ℤ) - (-24) = 3 * 691) := by
  refine ⟨by decide, by norm_num⟩

-- The E₈ lattice counts 240 σ₃(n) for n = 1, 2, 3: 240, 2160, 6720.
example : 240 * σ 3 1 = 240 ∧ 240 * σ 3 2 = 2160 ∧ 240 * σ 3 3 = 6720 := by decide

#print axioms dim_modular_forms_level_one
#print axioms modular_form_eq_zero_of_first_coeffs_zero
#print axioms cusp_form_weight_twelve_eq_smul_discriminant
