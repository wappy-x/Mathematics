-- Hodge decomposition: on the square-lattice torus every closed 1-form A dx + B dy splits uniquely as c dz + conj(c) dz-bar with c = (A - B i)/2, and on a complex n-torus the Hodge numbers C(n,p) C(n,q) add up to the Betti numbers C(2n,k).
import Mathlib.Analysis.Complex.Basic
import Mathlib.LinearAlgebra.LinearIndependent.Lemmas
import Mathlib.LinearAlgebra.Span.Basic
import Mathlib.Data.Nat.Choose.Vandermonde
import Mathlib.Data.Fintype.Pi
import Mathlib.Tactic

open Complex ComplexConjugate

/-- A constant 1-form on the torus `ℂ / (ℤ + ℤ i)`, written by its coefficients on `dx` and `dy`
(which are also its periods round the loops `a`, from 0 to 1, and `b`, from 0 to i). -/
abbrev OneForm := Fin 2 → ℂ

/-- `dz = dx + i dy`, the form of type (1, 0). -/
def dz : OneForm := ![1, I]

/-- `dz̄ = dx - i dy`, the form of type (0, 1). -/
def dzbar : OneForm := ![1, -I]

/-- On the square-lattice torus, a closed real 1-form `A dx + B dy` is `c₁ dz + c₂ dz̄`
for exactly one pair of complex numbers: `c₁ = (A - B i)/2`, and `c₂` is the complex
conjugate of `c₁`. So the (1, 0) part and the (0, 1) part are mirror images. -/
theorem torus_one_form_splits_into_conjugate_types (A B : ℝ) (c₁ c₂ : ℂ) :
    c₁ • dz + c₂ • dzbar = ![(A : ℂ), (B : ℂ)] ↔
      c₁ = ((A : ℂ) - (B : ℂ) * I) / 2 ∧ c₂ = conj c₁ := by
  constructor
  · intro h
    have h0 := congrFun h 0
    have h1 := congrFun h 1
    simp [dz, dzbar] at h0 h1
    have e1 : c₁ = ((A : ℂ) - (B : ℂ) * I) / 2 := by
      linear_combination (1 / 2 : ℂ) * h0 - (I / 2) * h1 + (c₁ / 2 - c₂ / 2) * I_sq
    refine ⟨e1, ?_⟩
    rw [e1]
    simp only [map_div₀, map_sub, map_mul, conj_ofReal, conj_I, map_ofNat]
    linear_combination (1 / 2 : ℂ) * h0 + (I / 2) * h1 + (c₂ / 2 - c₁ / 2) * I_sq
  · rintro ⟨e1, e2⟩
    subst e2
    subst e1
    ext j
    fin_cases j
    · simp [dz, dzbar, map_div₀, conj_ofReal, map_ofNat]
      ring
    · simp [dz, dzbar, map_div₀, conj_ofReal, map_ofNat]
      linear_combination (-(B : ℂ)) * I_sq

/-- The first cohomology of the torus is the direct sum of one class of type (1, 0) and one of
type (0, 1): `dz` and `dz̄` are linearly independent and span all complex 1-forms (so
`b₁ = 2 = h^{1,0} + h^{0,1}`), and complex conjugation sends `dz` to `dz̄` and back. -/
theorem torus_first_cohomology_is_dz_plus_dzbar :
    LinearIndependent ℂ ![dz, dzbar] ∧
      Submodule.span ℂ (Set.range ![dz, dzbar]) = ⊤ ∧
      (fun j => conj (dz j)) = dzbar ∧ (fun j => conj (dzbar j)) = dz := by
  refine ⟨?_, ?_, ?_, ?_⟩
  · rw [LinearIndependent.pair_iff]
    intro s t h
    have h0 := congrFun h 0
    have h1 := congrFun h 1
    simp [dz, dzbar] at h0 h1
    have hs : s = 0 := by
      have : (2 : ℂ) * s = 0 := by
        linear_combination h0 - I * h1 + (s - t) * I_sq
      simpa using this
    refine ⟨hs, ?_⟩
    subst hs
    simpa using h0
  · rw [Matrix.range_cons_cons_empty, eq_top_iff]
    intro v _
    rw [Submodule.mem_span_pair]
    refine ⟨(v 0 - v 1 * I) / 2, (v 0 + v 1 * I) / 2, ?_⟩
    ext j
    fin_cases j
    · simp [dz, dzbar]
      ring
    · simp [dz, dzbar]
      linear_combination (-(v 1)) * I_sq
  · ext j
    fin_cases j <;> simp [dz, dzbar]
  · ext j
    fin_cases j <;> simp [dz, dzbar]

/-- On a complex torus of dimension `n` the type-(p, q) wedges number `h^{p,q} = C(n,p) C(n,q)`.
These satisfy Hodge symmetry `h^{p,q} = h^{q,p}`, and on each row they add up to the Betti
number: `b_k = C(2n, k) = ∑_{p + q = k} h^{p,q}`. -/
theorem complex_torus_hodge_numbers_sum_to_betti (n k : ℕ) :
    (∑ pq ∈ Finset.antidiagonal k, n.choose pq.1 * n.choose pq.2) = (2 * n).choose k ∧
      ∀ p q : ℕ, n.choose p * n.choose q = n.choose q * n.choose p := by
  refine ⟨?_, fun p q => Nat.mul_comm _ _⟩
  rw [two_mul, Nat.add_choose_eq]

-- The worked torus split: 3 dx + 5 dy = (3/2 - 5/2 i) dz + (3/2 + 5/2 i) dz-bar.
example : ((3 / 2 - 5 / 2 * I : ℂ)) • dz + ((3 / 2 + 5 / 2 * I : ℂ)) • dzbar = ![(3 : ℂ), 5] := by
  ext j; fin_cases j <;> simp [dz, dzbar, Complex.ext_iff]

-- The period determinant: 1 · (-i) - 1 · i = -2i.
example : (1 : ℂ) * (-I) - 1 * I = -2 * I := by ring

-- Torus of dimension 2: rows 1; 2 + 2; 1 + 4 + 1; 2 + 2; 1.
example : (List.range 5).map (fun k => ((List.range (k + 1)).filter (fun p => p ≤ 2 ∧ k - p ≤ 2)).map
    (fun p => Nat.choose 2 p * Nat.choose 2 (k - p))) = [[1], [2, 2], [1, 4, 1], [2, 2], [1]] := by
  decide

-- Quartic surface, Jacobian ring of the Fermat quartic: monomials in 4 variables with every
-- exponent at most 2, of degrees 0, 4 and 8, number 1, 19 and 1.
example : ((Finset.univ : Finset (Fin 4 → Fin 3)).filter (fun e => ∑ i, (e i : ℕ) = 0)).card = 1 := by
  decide
example : ((Finset.univ : Finset (Fin 4 → Fin 3)).filter (fun e => ∑ i, (e i : ℕ) = 4)).card = 19 := by
  decide
example : ((Finset.univ : Finset (Fin 4 → Fin 3)).filter (fun e => ∑ i, (e i : ℕ) = 8)).card = 1 := by
  decide

-- Quartic surface, topology: χ = 4 (C(4,2) - 4 C(4,1) + 16 C(4,0)) = 24, b₂ = 24 - 2 = 22 = 1 + 20 + 1,
-- p_g = C(3,3) = 1, and Noether: (K² + χ)/12 = (0 + 24)/12 = 2 = 1 + p_g.
example : (4 : ℤ) * ∑ j ∈ Finset.range 3, ((Nat.choose 4 (2 - j) : ℤ) * (-4) ^ j) = 24 := by decide
example : (24 - 2 : ℤ) = 1 + (19 + 1) + 1 ∧ Nat.choose 3 3 = 1 ∧ (0 + 24) / 12 = 1 + 1 := by decide

-- Quintic threefold: χ = 5 (C(5,3) - 5 C(5,2) + 25 C(5,1) - 125 C(5,0)) = -200, so b₃ = 4 - χ = 204.
example : (5 : ℤ) * ∑ j ∈ Finset.range 4, ((Nat.choose 5 (3 - j) : ℤ) * (-5) ^ j) = -200 := by decide
example : (4 : ℤ) - (-200) = 1 + 101 + 101 + 1 := by decide

#print axioms torus_one_form_splits_into_conjugate_types
#print axioms torus_first_cohomology_is_dz_plus_dzbar
#print axioms complex_torus_hodge_numbers_sum_to_betti
