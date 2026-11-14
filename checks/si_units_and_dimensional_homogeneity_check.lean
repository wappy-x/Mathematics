-- Units and dimensions: a sum of terms that stays zero under every rescaling of the seven base units must vanish group by group, one group per exponent list.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Data.Fin.VecNotation
import Mathlib.Analysis.SpecialFunctions.Pow.Continuity
import Mathlib.Algebra.Polynomial.Roots

open Finset

open Filter Topology in
/-- Helper: the one-variable statement over any finite set of indices, by peeling off
the largest power with a limit at zero. -/
theorem helper_finset {ι : Type*} (b : ι → ℝ) (hb : Function.Injective b) (c : ι → ℝ)
    (S : Finset ι) (h : ∀ s : ℝ, 0 < s → ∑ i ∈ S, c i * s ^ (-(b i)) = 0) :
    ∀ i ∈ S, c i = 0 := by
  classical
  induction S using Finset.strongInduction with
  | H S ih =>
    rcases S.eq_empty_or_nonempty with hS | hS
    · simp [hS]
    obtain ⟨m, hm, hmax⟩ := Finset.exists_max_image S b hS
    set g : ℝ → ℝ := fun s => ∑ i ∈ S, c i * s ^ (b m - b i) with hg
    have hpos : ∀ s : ℝ, 0 < s → g s = 0 := by
      intro s hs
      have : g s = s ^ (b m) * ∑ i ∈ S, c i * s ^ (-(b i)) := by
        rw [hg, Finset.mul_sum]
        refine Finset.sum_congr rfl fun i _ => ?_
        rw [sub_eq_add_neg, Real.rpow_add hs]
        ring
      rw [this, h s hs, mul_zero]
    have hcont : ContinuousAt g 0 := by
      have : Tendsto g (𝓝 0) (𝓝 (∑ i ∈ S, c i * (0:ℝ) ^ (b m - b i))) := by
        apply tendsto_finsetSum
        intro i hi
        exact (Real.continuousAt_rpow_const 0 _ (Or.inr (sub_nonneg.2 (hmax i hi)))).tendsto.const_mul _
      exact this
    have hg0 : g 0 = 0 := by
      have h1 : Tendsto g (𝓝[>] 0) (𝓝 (g 0)) := hcont.tendsto.mono_left nhdsWithin_le_nhds
      have h2 : Tendsto g (𝓝[>] 0) (𝓝 0) := by
        refine tendsto_const_nhds.congr' ?_
        filter_upwards [self_mem_nhdsWithin] with s hs
        exact (hpos s hs).symm
      exact tendsto_nhds_unique h1 h2
    have hcm : c m = 0 := by
      have : g 0 = c m := by
        rw [hg]
        dsimp only
        rw [Finset.sum_eq_single m]
        · simp
        · intro i hi him
          have hlt : b i < b m := lt_of_le_of_ne (hmax i hi) (fun e => him (hb e))
          rw [Real.zero_rpow (by linarith), mul_zero]
        · intro h'; exact absurd hm h'
      rw [← this, hg0]
    have hrest := ih (S.erase m) (Finset.erase_ssubset hm) (by
      intro s hs
      rw [Finset.sum_erase _ (by rw [hcm, zero_mul])]
      exact h s hs)
    intro i hi
    by_cases him : i = m
    · rw [him, hcm]
    · exact hrest i (Finset.mem_erase.2 ⟨him, hi⟩)

#print axioms helper_finset

/-- Helper: a weight vector that separates finitely many distinct exponent lists. -/
theorem helper_weights {k n : ℕ} (d : Fin k → Fin n → ℝ) (hd : Function.Injective d) :
    ∃ w : Fin n → ℝ, Function.Injective (fun i => ∑ j, w j * d i j) := by
  classical
  open Polynomial in
  let P : Fin k × Fin k → ℝ[X] := fun p => ∑ j : Fin n, C (d p.1 j - d p.2 j) * X ^ (j : ℕ)
  have hcoeff : ∀ p (j : Fin n), (P p).coeff (j : ℕ) = d p.1 j - d p.2 j := by
    intro p j
    simp only [P]
    rw [Polynomial.finsetSum_coeff]
    simp only [Polynomial.coeff_C_mul_X_pow, Fin.val_inj]
    simp
  have hP : ∀ p ∈ (univ ×ˢ univ : Finset (Fin k × Fin k)).filter (fun p => p.1 ≠ p.2),
      P p ≠ 0 := by
    intro p hp hP0
    simp only [Finset.mem_filter] at hp
    apply hp.2
    apply hd
    funext j
    have := hcoeff p j
    rw [hP0, Polynomial.coeff_zero] at this
    linarith
  set Q := ∏ p ∈ (univ ×ˢ univ : Finset (Fin k × Fin k)).filter (fun p => p.1 ≠ p.2), P p
  have hQ : Q ≠ 0 := Finset.prod_ne_zero_iff.2 hP
  obtain ⟨t, ht⟩ : ∃ t : ℝ, Q.eval t ≠ 0 := by
    by_contra hcon
    push Not at hcon
    exact hQ (Polynomial.funext (by simpa using hcon))
  refine ⟨fun j => t ^ (j : ℕ), ?_⟩
  intro i i' hii'
  by_contra hne
  apply ht
  rw [Polynomial.eval_prod]
  apply Finset.prod_eq_zero (i := (i, i'))
  · simp [hne]
  · simp only [P]
    rw [Polynomial.eval_finsetSum]
    simp only [Polynomial.eval_mul, Polynomial.eval_C, Polynomial.eval_pow, Polynomial.eval_X]
    simp only at hii'
    rw [← sub_eq_zero] at hii'
    rw [← hii', ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl fun j _ => ?_
    ring

#print axioms helper_weights

/-- Dimensional homogeneity. Group the terms of a law by their exponent lists over the
seven base quantities, with distinct lists `d i` and group sums `c i` in the old units.
Changing the base units by factors `s j > 0` multiplies a term with exponent list `d i`
by `∏ j, (s j) ^ (-(d i j))`. If the law stays true for every choice of the seven new
units, then every group sums to zero on its own: the law balances group by group.
Powers may be whole numbers or fractions, so they are real numbers here. -/
theorem dimensional_homogeneity {k : ℕ} (d : Fin k → Fin 7 → ℝ)
    (hd : Function.Injective d) (c : Fin k → ℝ)
    (h : ∀ s : Fin 7 → ℝ, (∀ j, 0 < s j) →
      ∑ i, c i * ∏ j, (s j) ^ (-(d i j)) = 0) :
    ∀ i, c i = 0 := by
  obtain ⟨w, hw⟩ := helper_weights d hd
  intro i
  refine helper_finset (fun i => ∑ j, w j * d i j) hw c univ ?_ i (mem_univ i)
  intro s hs
  have := h (fun j => s ^ (w j)) (fun j => Real.rpow_pos_of_pos hs _)
  rw [← this]
  refine Finset.sum_congr rfl fun i _ => ?_
  congr 1
  simp only [← Real.rpow_mul hs.le]
  rw [← Real.rpow_sum_of_pos hs]
  congr 1
  simp [mul_neg, Finset.sum_neg_distrib]

/-- One base at a time (the card's detailed proof). If numbers `c 1, …, c k` satisfy
`c 1 λ^(-b 1) + … + c k λ^(-b k) = 0` for every `λ > 0`, with distinct powers `b i`,
then every `c i` is zero. -/
theorem coeffs_zero_of_sum_rpow_eq_zero {k : ℕ} (b : Fin k → ℝ)
    (hb : Function.Injective b) (c : Fin k → ℝ)
    (h : ∀ s : ℝ, 0 < s → ∑ i, c i * s ^ (-(b i)) = 0) :
    ∀ i, c i = 0 := by
  intro i
  exact helper_finset b hb c univ h i (mem_univ i)

/-- In a product, the powers add: if two quantities with length powers `b₁` and `b₂`
have their numbers rescaled by `λ^(-b₁)` and `λ^(-b₂)`, their product is rescaled by
`λ^(-(b₁ + b₂))`, for every unit size `λ > 0`. -/
theorem rescale_mul_adds_powers (s b₁ b₂ : ℝ) (hs : 0 < s) :
    s ^ (-b₁) * s ^ (-b₂) = s ^ (-(b₁ + b₂)) := by
  rw [neg_add, Real.rpow_add hs]

-- Step 4: exponent lists (M, L, T). Viscosity (1,-1,-1), length (0,1,0), flow (0,3,-1).
-- The quoted formula 32 μ ℓ Q / D^2 comes out as (1, 1, -2), a force.
example : (![1, -1, -1] + ![0, 1, 0] + ![0, 3, -1] - 2 • ![0, 1, 0] : Fin 3 → ℤ)
    = ![1, 1, -2] := by decide

-- ... which is not the pressure list (1, -1, -2): rejected.
example : (![1, 1, -2] : Fin 3 → ℤ) ≠ ![1, -1, -2] := by decide

-- The right formula 128 μ ℓ Q / (π D^4) comes out as (1, -1, -2), a pressure.
example : (![1, -1, -1] + ![0, 1, 0] + ![0, 3, -1] - 4 • ![0, 1, 0] : Fin 3 → ℤ)
    = ![1, -1, -2] := by decide

-- Viscosity is a pressure times a time: (1, -1, -2) + (0, 0, 1) = (1, -1, -1).
example : (![1, -1, -2] + ![0, 0, 1] : Fin 3 → ℤ) = ![1, -1, -1] := by decide

-- Step 5: in centimetres (λ = 1/100) the wrong formula's answer moves by λ^(-2) = 10,000.
example : ((1 : ℚ) / 100) ^ (-2 : ℤ) = 10000 := by norm_num

#print axioms dimensional_homogeneity
#print axioms coeffs_zero_of_sum_rpow_eq_zero
#print axioms rescale_mul_adds_powers
