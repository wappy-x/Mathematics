-- The class number formula: for an imaginary quadratic field the Dedekind zeta function has residue 2π·h_K/(w_K·√|d_K|) at s = 1, the ideals of norm up to X number about that residue times X, and for every number field the residue is 2^r₁·(2π)^r₂·h_K·R_K/(w_K·√|d_K|).
import Mathlib.NumberTheory.NumberField.DedekindZeta
import Mathlib.NumberTheory.LegendreSymbol.JacobiSymbol

open Filter Topology NumberField NumberField.InfinitePlace NumberField.Units Ideal
open scoped Real

theorem nrComplexPlaces_eq_one_of_imagQuad
    (K : Type*) [Field K] [NumberField K] [IsTotallyComplex K]
    (hK : Module.finrank ℚ K = 2) : nrComplexPlaces K = 1 := by
  have h := card_add_two_mul_card_eq_rank K
  rw [IsTotallyComplex.nrRealPlaces_eq_zero K, hK] at h
  omega

theorem regulator_eq_one_of_imagQuad
    (K : Type*) [Field K] [NumberField K] [IsTotallyComplex K]
    (hK : Module.finrank ℚ K = 2) : regulator K = 1 := by
  classical
  have hc : Fintype.card (InfinitePlace K) = 1 := by
    rw [card_eq_nrRealPlaces_add_nrComplexPlaces, IsTotallyComplex.nrRealPlaces_eq_zero K,
      nrComplexPlaces_eq_one_of_imagQuad K hK]
  have hs : ∀ a b : InfinitePlace K, a = b := Fintype.card_le_one_iff.mp hc.le
  have : ∀ w' : InfinitePlace K, IsEmpty {w // w ≠ w'} :=
    fun w' ↦ ⟨fun w ↦ w.2 (hs _ _)⟩
  rw [regulator_eq_det', Matrix.det_isEmpty, abs_one]

theorem dedekindZeta_residue_imagQuad
    (K : Type*) [Field K] [NumberField K] [IsTotallyComplex K]
    (hK : Module.finrank ℚ K = 2) :
    dedekindZeta_residue K =
      (2 * π * classNumber K) / (torsionOrder K * Real.sqrt |(discr K : ℝ)|) := by
  rw [dedekindZeta_residue_def, IsTotallyComplex.nrRealPlaces_eq_zero K,
    nrComplexPlaces_eq_one_of_imagQuad K hK, regulator_eq_one_of_imagQuad K hK]
  simp

#print axioms nrComplexPlaces_eq_one_of_imagQuad
#print axioms regulator_eq_one_of_imagQuad
#print axioms dedekindZeta_residue_imagQuad

/-- **The class number formula, imaginary quadratic case.** Let K be an imaginary quadratic
field: degree 2 over ℚ with no real embedding. Then (s − 1)·ζ_K(s) tends to
2π·h_K / (w_K·√|d_K|) as s comes down to 1, where ζ_K(s) adds 1/N(𝔞)^s over the ideals of the
full ring of integers O_K, h_K is the class number, w_K the number of roots of unity in O_K and
d_K the discriminant. -/
theorem residue_dedekindZeta_imaginary_quadratic
    (K : Type*) [Field K] [NumberField K] [IsTotallyComplex K]
    (hK : Module.finrank ℚ K = 2) :
    Tendsto (fun s : ℝ ↦ ((s : ℂ) - 1) * dedekindZeta K s) (𝓝[>] 1)
      (𝓝 (((2 * π * classNumber K) / (torsionOrder K * Real.sqrt |(discr K : ℝ)|) : ℝ) : ℂ)) := by
  rw [← dedekindZeta_residue_imagQuad K hK]
  exact tendsto_sub_one_mul_dedekindZeta_nhdsGT K

/-- **Ideals per unit of norm.** In an imaginary quadratic field, the number A(X) of ideals of
O_K with norm at most X, divided by X, tends to 2π·h_K / (w_K·√|d_K|): every ideal class adds
the same share 2π/(w_K·√|d_K|) per unit of norm. -/
theorem ideal_count_div_tendsto_imaginary_quadratic
    (K : Type*) [Field K] [NumberField K] [IsTotallyComplex K]
    (hK : Module.finrank ℚ K = 2) :
    Tendsto (fun X : ℝ ↦ (Nat.card {I : Ideal (𝓞 K) // absNorm I ≤ X} : ℝ) / X) atTop
      (𝓝 ((2 * π * classNumber K) / (torsionOrder K * Real.sqrt |(discr K : ℝ)|))) := by
  rw [← dedekindZeta_residue_imagQuad K hK]
  exact Ideal.tendsto_norm_le_div_atTop K

/-- **The formula for every number field (carry the regulator).** For any number field K,
(s − 1)·ζ_K(s) tends to 2^r₁·(2π)^r₂·h_K·R_K / (w_K·√|d_K|) as s comes down to 1, where r₁
counts the real embeddings, r₂ the pairs of complex ones and R_K is the regulator. -/
theorem residue_dedekindZeta_general (K : Type*) [Field K] [NumberField K] :
    Tendsto (fun s : ℝ ↦ ((s : ℂ) - 1) * dedekindZeta K s) (𝓝[>] 1)
      (𝓝 (((2 ^ nrRealPlaces K * (2 * π) ^ nrComplexPlaces K * regulator K * classNumber K) /
        (torsionOrder K * Real.sqrt |(discr K : ℝ)|) : ℝ) : ℂ)) := by
  exact tendsto_sub_one_mul_dedekindZeta_nhdsGT K

/-! ### The card's whole-number worked examples for ℚ(√−5), d_K = −20, w_K = 2 -/

/-- The Kronecker symbol χ(n) = (−20/n): 0 at even n (2 divides 20), the Jacobi symbol at odd n. -/
def chi20 (n : ℕ) : ℤ := if n % 2 = 0 then 0 else jacobiSym (-20) n

/-- a_n, the number of ideals of norm n: the sum of χ(e) over the divisors e of n. -/
def idealCount20 (n : ℕ) : ℤ := ∑ e ∈ n.divisors, chi20 e

-- χ(a) for a = 1 to 20: +1 at 1, 3, 7, 9; −1 at 11, 13, 17, 19; 0 elsewhere.
example : (List.range 20).map (fun a ↦ chi20 (a + 1)) =
    [1, 0, 1, 0, 0, 0, 1, 0, 1, 0, -1, 0, -1, 0, 0, 0, -1, 0, -1, 0] := by
  decide +kernel

-- The finite sum: Σ χ(a)·a over a = 1 to 20 is (1 + 3 + 7 + 9) − (11 + 13 + 17 + 19) = −40.
example : ∑ a ∈ Finset.Icc 1 20, chi20 a * (a : ℤ) = -40 := by
  decide +kernel

-- h = −(w/(2|d|))·Σ χ(a)·a = −(2/40)·(−40) = 2.
example : -((2 : ℚ) / (2 * 20)) * (-40) = 2 := by norm_num

-- Ideals of norm n for n = 1 to 20: [1, 1, 2, 1, 1, 2, 2, 1, 3, 1, 0, 2, 0, 2, 2, 1, 0, 3, 0, 1].
example : (List.range 20).map (fun n ↦ idealCount20 (n + 1)) =
    [1, 1, 2, 1, 1, 2, 2, 1, 3, 1, 0, 2, 0, 2, 2, 1, 0, 3, 0, 1] := by
  decide +kernel

-- Norm 6: the four numbers ±1 ± √−5, solutions of x² + 5y² = 6 (all lie in |x|, |y| ≤ 3).
example : ((Finset.Icc (-3 : ℤ) 3 ×ˢ Finset.Icc (-3 : ℤ) 3).filter
    (fun p ↦ p.1 ^ 2 + 5 * p.2 ^ 2 = 6)) = {(-1, -1), (-1, 1), (1, -1), (1, 1)} := by
  decide

-- x² + 5y² never equals 2 or 3, so the ideals of norm 2 and 3 are not principal.
example : ∀ x ∈ Finset.Icc (-2 : ℤ) 2, ∀ y ∈ Finset.Icc (-1 : ℤ) 1,
    x ^ 2 + 5 * y ^ 2 ≠ 2 ∧ x ^ 2 + 5 * y ^ 2 ≠ 3 := by
  decide

#print axioms residue_dedekindZeta_imaginary_quadratic
#print axioms ideal_count_div_tendsto_imaginary_quadratic
#print axioms residue_dedekindZeta_general
