-- Projective space: the standard charts cover projective n-space, each chart is a copy of n-space, what a chart misses is projective (n - 1)-space, and over the integers mod a prime p projective n-space has 1 + p + ... + p^n points.
import Mathlib.LinearAlgebra.Projectivization.Cardinality
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.Algebra.Field.ZMod
import Mathlib.Data.Fin.Tuple.Basic
import Mathlib.Algebra.BigOperators.Intervals

open scoped LinearAlgebra.Projectivization

/-- Over the integers mod a prime `p`, projective n-space `ℙ^n(𝔽_p)`, the lines through the
origin in `𝔽_p^(n+1)`, has `1 + p + ... + p^n` points, which is also `(p^(n+1) - 1)/(p - 1)`. -/
theorem card_projective_space_zmod (p n : ℕ) [Fact p.Prime] :
    Nat.card (ℙ (ZMod p) (Fin (n + 1) → ZMod p)) = ∑ i ∈ Finset.range (n + 1), p ^ i ∧
    Nat.card (ℙ (ZMod p) (Fin (n + 1) → ZMod p)) = (p ^ (n + 1) - 1) / (p - 1) := by
  have hp : (p : ℕ).Prime := Fact.out
  have hcard : Nat.card (ZMod p) = p := by simp
  constructor
  · rw [Projectivization.card_of_finrank (ZMod p) (Fin (n + 1) → ZMod p)
      (n := n + 1) (by simp), hcard]
  · rw [Projectivization.card'', hcard, Nat.card_fun, hcard]
    simp

/-- The standard charts: every point `(x_0 : ... : x_n)` has some coordinate `x_i ≠ 0`, so the
`n + 1` charts `U_i = {x_i ≠ 0}` cover projective n-space; and for each `i`, putting a 1 in
place `i`, `a ↦ (a_0 : ... : 1 : ... : a_{n-1})`, is a one-to-one map from affine n-space
onto exactly the chart `U_i`. -/
theorem standard_charts_cover_and_are_affine_space (K : Type*) [Field K] (n : ℕ) :
    (∀ x : ℙ K (Fin (n + 1) → K), ∃ i, x.rep i ≠ 0) ∧
    ∀ i : Fin (n + 1),
      Function.Injective (fun a : Fin n → K =>
        Projectivization.mk K (Fin.insertNth (α := fun _ => K) i 1 a)
          (fun h => (one_ne_zero : (1 : K) ≠ 0) (by simpa using congrFun h i))) ∧
      Set.range (fun a : Fin n → K =>
        Projectivization.mk K (Fin.insertNth (α := fun _ => K) i 1 a)
          (fun h => (one_ne_zero : (1 : K) ≠ 0) (by simpa using congrFun h i))) =
        {x : ℙ K (Fin (n + 1) → K) | x.rep i ≠ 0} := by
  refine ⟨fun x => ?_, fun i => ⟨?_, ?_⟩⟩
  · by_contra h
    push Not at h
    exact x.rep_ne_zero (funext h)
  · intro a b hab
    simp only at hab
    rw [Projectivization.mk_eq_mk_iff'] at hab
    obtain ⟨c, hc⟩ := hab
    have hi := congrFun hc i
    simp only [Pi.smul_apply, Fin.insertNth_apply_same, smul_eq_mul, mul_one] at hi
    subst hi
    funext j
    have := congrFun hc (i.succAbove j)
    simpa [Fin.insertNth_apply_succAbove] using this.symm
  · ext x
    simp only [Set.mem_range, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨a, rfl⟩
      obtain ⟨c, hc⟩ := Projectivization.exists_smul_eq_mk_rep K
        (Fin.insertNth (α := fun _ => K) i 1 a)
        (fun h => (one_ne_zero : (1 : K) ≠ 0) (by simpa using congrFun h i))
      rw [← hc]
      simp [Fin.insertNth_apply_same, Units.smul_def]
    · intro hx
      refine ⟨fun j => (x.rep i)⁻¹ * x.rep (i.succAbove j), ?_⟩
      conv_rhs => rw [← Projectivization.mk_rep x]
      rw [Projectivization.mk_eq_mk_iff']
      refine ⟨(x.rep i)⁻¹, ?_⟩
      funext j
      cases j using Fin.succAboveCases i with
      | x => simp [Fin.insertNth_apply_same, hx]
      | p j =>
        simp [Fin.insertNth_apply_succAbove]

/-- What chart `U_i` misses is projective space one dimension down: putting a 0 in place `i`,
`(y_0 : ... : y_{n-1}) ↦ (y_0 : ... : 0 : ... : y_{n-1})`, is a one-to-one map from
projective (n - 1)-space onto exactly the points with `x_i = 0`, the chart's hyperplane at
infinity. -/
theorem chart_complement_is_projective_space (K : Type*) [Field K] (n : ℕ) (i : Fin (n + 1)) :
    Function.Injective (fun y : ℙ K (Fin n → K) =>
        Projectivization.mk K (Fin.insertNth (α := fun _ => K) i 0 y.rep)
          (fun h => y.rep_ne_zero (funext fun j => by
            simpa using congrFun h (i.succAbove j)))) ∧
    Set.range (fun y : ℙ K (Fin n → K) =>
        Projectivization.mk K (Fin.insertNth (α := fun _ => K) i 0 y.rep)
          (fun h => y.rep_ne_zero (funext fun j => by
            simpa using congrFun h (i.succAbove j)))) =
      {x : ℙ K (Fin (n + 1) → K) | x.rep i = 0} := by
  refine ⟨?_, ?_⟩
  · intro y z hyz
    simp only at hyz
    rw [Projectivization.mk_eq_mk_iff'] at hyz
    obtain ⟨c, hc⟩ := hyz
    rw [← Projectivization.mk_rep y, ← Projectivization.mk_rep z,
      Projectivization.mk_eq_mk_iff']
    refine ⟨c, funext fun j => ?_⟩
    have := congrFun hc (i.succAbove j)
    simpa [Fin.insertNth_apply_succAbove] using this
  · ext x
    simp only [Set.mem_range, Set.mem_ofPred_eq]
    constructor
    · rintro ⟨y, rfl⟩
      obtain ⟨c, hc⟩ := Projectivization.exists_smul_eq_mk_rep K
        (Fin.insertNth (α := fun _ => K) i 0 y.rep)
        (fun h => y.rep_ne_zero (funext fun j => by
            simpa using congrFun h (i.succAbove j)))
      rw [← hc]
      simp [Fin.insertNth_apply_same]
    · intro hx
      have hne : (fun j => x.rep (i.succAbove j)) ≠ 0 := by
        intro h
        apply x.rep_ne_zero
        funext k
        cases k using Fin.succAboveCases i with
        | x => exact hx
        | p k => exact congrFun h k
      refine ⟨Projectivization.mk K _ hne, ?_⟩
      obtain ⟨c, hc⟩ := Projectivization.exists_smul_eq_mk_rep K _ hne
      conv_rhs => rw [← Projectivization.mk_rep x]
      rw [Projectivization.mk_eq_mk_iff']
      refine ⟨(c : K), funext fun k => ?_⟩
      cases k using Fin.succAboveCases i with
      | x => simp [Fin.insertNth_apply_same, hx]
      | p k =>
        rw [← hc]
        simp [Fin.insertNth_apply_succAbove, Units.smul_def]

-- The line (3 : 4 : -5) lies on the cone x^2 + y^2 = z^2, and so does its multiple by 2.
example : (3 : ℤ) ^ 2 + 4 ^ 2 - (-5) ^ 2 = 0 := by norm_num
example : (6 : ℤ) ^ 2 + 8 ^ 2 - (-10) ^ 2 = 0 := by norm_num

-- Ceiling chart (divide by z = -5) and wall chart (divide by x = 3).
example : ((3 : ℚ) / -5, (4 : ℚ) / -5) = (-3 / 5, -4 / 5) := by norm_num
example : (-3 / 5 : ℚ) ^ 2 + (-4 / 5) ^ 2 = 1 := by norm_num
example : ((4 : ℚ) / 3, (-5 : ℚ) / 3) = (4 / 3, -5 / 3) := by norm_num
example : (-5 / 3 : ℚ) ^ 2 - (4 / 3) ^ 2 = 1 := by norm_num

-- Ceiling to wall, (u, v) ↦ (v/u, 1/u), sends (-3/5, -4/5) to (4/3, -5/3).
example : ((-4 / 5 : ℚ) / (-3 / 5), 1 / (-3 / 5 : ℚ)) = (4 / 3, -5 / 3) := by norm_num

-- The slope formula (1 - m^2 : 2m : 1 + m^2) at m = -2 gives (-3 : -4 : 5).
example : ((1 : ℤ) - (-2) ^ 2, 2 * (-2 : ℤ), (1 : ℤ) + (-2) ^ 2) = (-3, -4, 5) := by norm_num

-- The parallel tangents y - z = 0 and y + z = 0 meet at (2, 0, 0), that is (1 : 0 : 0).
example : crossProduct ![(0 : ℤ), 1, -1] ![0, 1, 1] = ![2, 0, 0] := by
  simp [crossProduct]

-- x^2 + y^2 - z is not of one degree: 0 at (1, 0, 1) but 2 at (2, 0, 2).
example : (1 : ℤ) ^ 2 + 0 ^ 2 - 1 = 0 ∧ (2 : ℤ) ^ 2 + 0 ^ 2 - 2 = 2 := by norm_num

-- Counts 1 + p + ... + p^n for p = 2, 3, 5, 7 and n = 1, 2, 3.
example : [2, 3, 5, 7].map (fun p => ∑ i ∈ Finset.range 2, p ^ i) = [3, 4, 6, 8] := by decide
example : [2, 3, 5, 7].map (fun p => ∑ i ∈ Finset.range 3, p ^ i) = [7, 13, 31, 57] := by decide
example : [2, 3, 5, 7].map (fun p => ∑ i ∈ Finset.range 4, p ^ i) = [15, 40, 156, 400] := by
  decide

-- Over 𝔽_7: 342 nonzero triples, 6 scalings each, 57 points; keeping (0, 0, 0) gives 343,
-- which 6 does not divide.
example : 7 ^ 3 - 1 = 342 ∧ 342 / 6 = 57 ∧ 342 % 6 = 0 ∧ ¬ (6 ∣ 343) := by decide

-- The ceiling chart u^2 + v^2 = 1 holds 8 points over 𝔽_7 and 4 over 𝔽_5.
example : (Finset.univ.filter fun q : ZMod 7 × ZMod 7 => q.1 ^ 2 + q.2 ^ 2 = 1).card = 8 := by
  decide
example : (Finset.univ.filter fun q : ZMod 5 × ZMod 5 => q.1 ^ 2 + q.2 ^ 2 = 1).card = 4 := by
  decide

#print axioms card_projective_space_zmod
#print axioms standard_charts_cover_and_are_affine_space
#print axioms chart_complement_is_projective_space
