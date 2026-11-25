-- Cheeger's inequality: this file proves the card's exact whole-number spectral counts (the unit sphere's eigenvalue count against Weyl's law, the multiplicity 2k + 1, the torus count 317) and the closing algebra of Cheeger's proof that turns the co-area and Cauchy-Schwarz bounds into λ₁ ≥ h²/4.
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Algebra.BigOperators.Intervals
import Mathlib.Data.Int.Interval

open Finset

/-- Weyl's law is exact at the top of each level on the unit sphere. The sphere's eigenvalues
are k(k + 1), each repeated 2k + 1 times. At the level λ = K(K + 1), the number of eigenvalues
at or below λ, counted with multiplicity, is (K + 1)², and Weyl's prediction
ω₂ · vol(S²) · λ / (2π)² = π · 4π · K(K + 1) / (2π)² is exactly K(K + 1).
(Every degree k with k(k + 1) ≤ λ is at most λ, so summing over k ≤ λ misses none.) -/
theorem sphere_eigenvalue_count_and_weyl (K : ℕ) :
    (∑ k ∈ (range (K * (K + 1) + 1)).filter (fun k => k * (k + 1) ≤ K * (K + 1)), (2 * k + 1))
        = (K + 1) ^ 2 ∧
      Real.pi * (4 * Real.pi) * ((K : ℝ) * (K + 1)) / (2 * Real.pi) ^ 2 = (K : ℝ) * (K + 1) := by
  have hf : (range (K * (K + 1) + 1)).filter (fun k => k * (k + 1) ≤ K * (K + 1))
      = range (K + 1) := by
    ext k
    simp only [mem_filter, mem_range]
    constructor
    · rintro ⟨_, h⟩
      by_contra hk
      replace hk := Nat.lt_of_not_le hk
      have : (K + 1) * (K + 2) ≤ k * (k + 1) := Nat.mul_le_mul (by omega) (by omega)
      nlinarith
    · intro hk
      refine ⟨?_, Nat.mul_le_mul (by omega) (by omega)⟩
      nlinarith
  refine ⟨?_, ?_⟩
  · rw [hf]
    clear hf
    induction K with
    | zero => simp
    | succ n ih => rw [sum_range_succ, ih]; ring
  · have hpi : Real.pi ≠ 0 := Real.pi_ne_zero
    field_simp
    ring

/-- The multiplicity of the sphere eigenvalue k(k + 1). Degree-k polynomials in x, y, z number
C(k + 2, 2); the flat Laplacian maps them onto degree k − 2, which number C(k, 2); what is left,
the harmonic ones, number C(k + 2, 2) − C(k, 2) = 2k + 1. -/
theorem sphere_multiplicity_count (k : ℕ) :
    ((k + 2).choose 2 : ℤ) - (k.choose 2 : ℤ) = 2 * k + 1 := by
  simp [Nat.choose_succ_succ]
  ring

/-- The last step of Cheeger's proof. Write a = ∫ u² > 0, E = ∫ |grad u|² ≥ 0 and
G = ∫ |grad w| for w = u². If the energy identity E = λ₁ a holds, the co-area bound gives
h a ≤ G with h ≥ 0, and Cauchy-Schwarz gives G ≤ 2 √(a E), then λ₁ ≥ h² / 4. -/
theorem cheeger_bound_from_coarea_and_cauchy_schwarz {a E G h lam : ℝ}
    (ha : 0 < a) (hE : 0 ≤ E) (hh : 0 ≤ h)
    (henergy : E = lam * a) (hcoarea : h * a ≤ G) (hcs : G ≤ 2 * Real.sqrt (a * E)) :
    h ^ 2 / 4 ≤ lam := by
  have hlam : 0 ≤ lam := by
    by_contra hneg
    replace hneg := lt_of_not_ge hneg
    nlinarith
  have h1 : h * a ≤ 2 * Real.sqrt (a * E) := le_trans hcoarea hcs
  have hpos : 0 ≤ h * a := by positivity
  have hsq := Real.sq_sqrt (show 0 ≤ a * E by positivity)
  have h2 : (h * a) ^ 2 ≤ 4 * (a * E) := by
    have := pow_le_pow_left₀ hpos h1 2
    rw [mul_pow, mul_pow, hsq] at this
    linarith
  subst henergy
  have ha2 : 0 < a ^ 2 := by positivity
  by_contra hc
  replace hc := lt_of_not_ge hc
  nlinarith

-- Torus 2π × 2π: the whole-number points (m, n) with m² + n² ≤ 100 number 317.
set_option maxRecDepth 100000 in
example : ((Icc (-10 : ℤ) 10 ×ˢ Icc (-10 : ℤ) 10).filter
    (fun p => p.1 ^ 2 + p.2 ^ 2 ≤ 100)).card = 317 := by decide

-- The chart: the torus count at λ = 10, 20, ..., 100.
example : (List.range 10).map (fun i => ((Icc (-10 : ℤ) 10 ×ˢ Icc (-10 : ℤ) 10).filter
    (fun p => p.1 ^ 2 + p.2 ^ 2 ≤ 10 * ((i : ℤ) + 1))).card)
      = [37, 69, 97, 129, 161, 185, 221, 249, 293, 317] := by decide +kernel

-- Mistake 2: counting the torus with m, n ≥ 0 only gives 90.
example : ((range 11 ×ˢ range 11).filter
    (fun p : ℕ × ℕ => p.1 ^ 2 + p.2 ^ 2 ≤ 100)).card = 90 := by decide

-- Sphere: K = 10 gives level 10 × 11 = 110 and count 1 + 3 + ... + 21 = 121.
example : 10 * 11 = 110 := by norm_num
example : ∑ k ∈ (range 111).filter (fun k => k * (k + 1) ≤ 110), (2 * k + 1) = 121 := by decide
example : (List.range 11).map (fun k => 2 * k + 1) = [1, 3, 5, 7, 9, 11, 13, 15, 17, 19, 21] := by
  decide

-- Mistake 1: the sphere's distinct eigenvalues at or below 110 number only 11.
example : ((range 111).filter (fun k => k * (k + 1) ≤ 110)).card = 11 := by decide

-- Equator cut: h = 2π / 2π = 1, and the first note 2 = 1 × 2 clears the floor 1² / 4.
example : (1 : ℚ) ^ 2 / 4 ≤ 1 * 2 := by norm_num

#print axioms sphere_eigenvalue_count_and_weyl
#print axioms sphere_multiplicity_count
#print axioms cheeger_bound_from_coarea_and_cauchy_schwarz
