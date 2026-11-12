-- Stencils to order: on distinct offsets the moment conditions have exactly one set of weights, the first moment they fail to cancel gives the stencil's leading error and its order, and three points at uneven gaps give the curvature weights 2/(h₋(h₋+h₊)), -2/(h₋h₊), 2/(h₊(h₋+h₊)) with first-order error (h₊ - h₋)/3 · f'''.
import Mathlib.Analysis.Calculus.Taylor
import Mathlib.Analysis.Calculus.IteratedDeriv.Defs
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.LinearAlgebra.Vandermonde
import Mathlib.Data.Nat.Factorial.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.Ring
import Mathlib.Tactic.FieldSimp

open Finset Nat

/-- Taylor's theorem at one stencil point: the degree-p polynomial at x misses f(x + t h) by at
most |t|^(p+1) h^(p+1)/(p+1)! · M. -/
theorem stencil_taylor_point (f : ℝ → ℝ) (x h R M t : ℝ) (p : ℕ) (hh : 0 < h) (ht : |t| ≤ R)
    (hf : ContDiffOn ℝ (p + 1) f (Set.Icc (x - R * h) (x + R * h)))
    (hM : ∀ y ∈ Set.Ioo (x - R * h) (x + R * h), |iteratedDeriv (p + 1) f y| ≤ M) :
    |f (x + t * h) - ∑ i ∈ range (p + 1), iteratedDeriv i f x * (t * h) ^ i / (i ! : ℝ)|
      ≤ |t| ^ (p + 1) * h ^ (p + 1) / ((p + 1) ! : ℝ) * M := by
  by_cases ht0 : t = 0
  · subst ht0
    simp [Finset.sum_range_succ']
  have htpos : 0 < |t| := abs_pos.mpr ht0
  have hRpos : 0 < R := lt_of_lt_of_le htpos ht
  have hRh : 0 < R * h := mul_pos hRpos hh
  have hth : |t * h| ≤ R * h := by
    rw [abs_mul, abs_of_pos hh]
    exact mul_le_mul_of_nonneg_right ht hh.le
  obtain ⟨hth1, hth2⟩ := abs_le.mp hth
  have hne : x ≠ x + t * h := by
    intro heq
    have : t * h = 0 := by linarith
    rcases mul_eq_zero.mp this with h1 | h1
    · exact ht0 h1
    · exact hh.ne' h1
  have hxI : x ∈ Set.Icc (x - R * h) (x + R * h) := ⟨by linarith, by linarith⟩
  have hyI : x + t * h ∈ Set.Icc (x - R * h) (x + R * h) := ⟨by linarith, by linarith⟩
  have hsub : Set.uIcc x (x + t * h) ⊆ Set.Icc (x - R * h) (x + R * h) :=
    Set.uIcc_subset_Icc hxI hyI
  obtain ⟨x', hx', heq⟩ := taylor_mean_remainder_lagrange_iteratedDeriv hne (hf.mono hsub)
  have hcd : ContDiffAt ℝ (p + 1) f x :=
    hf.contDiffAt (Icc_mem_nhds (by linarith) (by linarith))
  have hu : UniqueDiffOn ℝ (Set.uIcc x (x + t * h)) := uniqueDiffOn_uIcc hne
  have hpoly : taylorWithinEval f p (Set.uIcc x (x + t * h)) x (x + t * h) =
      ∑ i ∈ range (p + 1), iteratedDeriv i f x * (t * h) ^ i / (i ! : ℝ) := by
    rw [taylor_within_apply]
    refine Finset.sum_congr rfl (fun i hi => ?_)
    have hip : i ≤ p + 1 := by
      have := Finset.mem_range.mp hi
      omega
    rw [iteratedDerivWithin_eq_iteratedDeriv hu (hcd.of_le (by exact_mod_cast hip))
      Set.left_mem_uIcc]
    simp only [smul_eq_mul, add_sub_cancel_left]
    field_simp
  rw [← hpoly, heq]
  have hx'I : x' ∈ Set.Ioo (x - R * h) (x + R * h) := by
    obtain ⟨h1, h2⟩ := hx'
    constructor
    · exact lt_of_le_of_lt (le_min (by linarith) (by linarith)) h1
    · exact lt_of_lt_of_le h2 (max_le (by linarith) (by linarith))
  have hb := hM x' hx'I
  rw [abs_div, abs_mul, add_sub_cancel_left, abs_pow, abs_mul, abs_of_pos hh,
    abs_of_pos (by positivity : (0 : ℝ) < ((p + 1) ! : ℝ)), mul_pow]
  rw [mul_div_assoc, mul_comm]
  exact mul_le_mul_of_nonneg_left hb (by positivity)

#print axioms stencil_taylor_point

/-- The weights of a stencil exist and are unique. Take n distinct offsets s₁, …, sₙ and a
derivative order k below n. Then there is exactly one list of weights c₁, …, cₙ that passes
every moment condition: for each power m = 0, 1, …, n - 1, the sum of cⱼ sⱼ^m is k! when m = k
and 0 otherwise. -/
theorem stencil_weights_exist_unique {n : ℕ} (s : Fin n → ℝ) (hs : Function.Injective s)
    (k : ℕ) (hk : k < n) :
    ∃! c : Fin n → ℝ, ∀ m : ℕ, m < n →
      ∑ j, c j * s j ^ m = if m = k then (k ! : ℝ) else 0 := by
  have hU : IsUnit (Matrix.vandermonde s) := by
    rw [Matrix.isUnit_iff_isUnit_det]
    exact isUnit_iff_ne_zero.mpr (Matrix.det_vandermonde_ne_zero_iff.mpr hs)
  have key : ∀ c : Fin n → ℝ, (∀ m : ℕ, m < n →
      ∑ j, c j * s j ^ m = if m = k then (k ! : ℝ) else 0) ↔
      Matrix.vecMul c (Matrix.vandermonde s) = fun m : Fin n => if (m : ℕ) = k then (k ! : ℝ) else 0 := by
    intro c
    constructor
    · intro h
      funext m
      simp only [Matrix.vecMul, dotProduct, Matrix.vandermonde_apply]
      exact h m m.2
    · intro h m hm
      have := congrFun h (⟨m, hm⟩ : Fin n)
      simpa [Matrix.vecMul, dotProduct, Matrix.vandermonde_apply] using this
  obtain ⟨c, hc⟩ := (Matrix.vecMul_surjective_iff_isUnit.mpr hU)
    (fun m : Fin n => if (m : ℕ) = k then (k ! : ℝ) else 0)
  refine ⟨c, (key c).mpr hc, fun d hd => ?_⟩
  exact (Matrix.vecMul_injective_iff_isUnit.mpr hU) (((key d).mp hd).trans hc.symm)

/-- The first moment not cancelled is the error, and its power of the step is the order.
Suppose the weights cⱼ on offsets sⱼ satisfy the moment conditions for every power m below p
(the k-th moment is k!, all others are 0), with k < p. Let f be p + 1 times continuously
differentiable across the whole stencil, the interval [x - R h, x + R h] with every |sⱼ| ≤ R,
and let M bound |f^(p+1)| there. Then the stencil (1/h^k) Σ cⱼ f(x + sⱼ h) equals
f^(k)(x) + E h^(p-k) f^(p)(x) with E = (1/p!) Σ cⱼ sⱼ^p, up to a remainder of at most
h^(p+1-k)/(p+1)! · Σ |cⱼ| |sⱼ|^(p+1) · M. -/
theorem stencil_error_first_uncancelled_moment {n : ℕ} (s c : Fin n → ℝ) (k p : ℕ)
    (hkp : k < p)
    (hmom : ∀ m : ℕ, m < p → ∑ j, c j * s j ^ m = if m = k then (k ! : ℝ) else 0)
    (f : ℝ → ℝ) (x h R M : ℝ) (hh : 0 < h) (hR : ∀ j, |s j| ≤ R)
    (hf : ContDiffOn ℝ (p + 1) f (Set.Icc (x - R * h) (x + R * h)))
    (hM : ∀ y ∈ Set.Ioo (x - R * h) (x + R * h), |iteratedDeriv (p + 1) f y| ≤ M) :
    |(1 / h ^ k) * ∑ j, c j * f (x + s j * h) - iteratedDeriv k f x
        - h ^ (p - k) * ((1 / (p ! : ℝ)) * ∑ j, c j * s j ^ p) * iteratedDeriv p f x|
      ≤ h ^ (p + 1 - k) / ((p + 1) ! : ℝ) * (∑ j, |c j| * |s j| ^ (p + 1)) * M := by
  set T : ℕ → ℝ := fun i => iteratedDeriv i f x with hT
  set r : Fin n → ℝ := fun j =>
    f (x + s j * h) - ∑ i ∈ range (p + 1), T i * (s j * h) ^ i / (i ! : ℝ) with hr
  have hrb : ∀ j, |r j| ≤ |s j| ^ (p + 1) * h ^ (p + 1) / ((p + 1) ! : ℝ) * M :=
    fun j => stencil_taylor_point f x h R M (s j) p hh (hR j) hf hM
  set S : ℝ := ∑ j, c j * s j ^ p with hS
  have hA : ∑ j, c j * f (x + s j * h) =
      ∑ j, c j * ∑ i ∈ range (p + 1), T i * (s j * h) ^ i / (i ! : ℝ) + ∑ j, c j * r j := by
    rw [← Finset.sum_add_distrib]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    simp only [hr]
    ring
  have hP : ∑ j, c j * ∑ i ∈ range (p + 1), T i * (s j * h) ^ i / (i ! : ℝ) =
      ∑ i ∈ range (p + 1), T i * h ^ i / (i ! : ℝ) * ∑ j, c j * s j ^ i := by
    simp_rw [Finset.mul_sum]
    rw [Finset.sum_comm]
    refine Finset.sum_congr rfl (fun i _ => Finset.sum_congr rfl (fun j _ => ?_))
    rw [mul_pow]
    ring
  have hP2 : ∑ i ∈ range (p + 1), T i * h ^ i / (i ! : ℝ) * ∑ j, c j * s j ^ i =
      T k * h ^ k + T p * h ^ p / (p ! : ℝ) * S := by
    rw [Finset.sum_range_succ]
    congr 1
    rw [Finset.sum_congr rfl (fun i hi => by rw [hmom i (Finset.mem_range.mp hi)])]
    have : ∀ i ∈ range p, T i * h ^ i / (i ! : ℝ) * (if i = k then (k ! : ℝ) else 0) =
        if i = k then T k * h ^ k else 0 := by
      intro i _
      split_ifs with hik
      · subst hik
        have : (i ! : ℝ) ≠ 0 := by positivity
        field_simp
      · simp
    rw [Finset.sum_congr rfl this, Finset.sum_ite_eq' (range p) k, ite_eq_left (Finset.mem_range.mpr hkp)]
  have hk0 : h ^ k ≠ 0 := by positivity
  have hpk : h ^ p = h ^ k * h ^ (p - k) := by
    rw [← pow_add, Nat.add_sub_cancel' hkp.le]
  have hp1k : h ^ (p + 1) = h ^ k * h ^ (p + 1 - k) := by
    rw [← pow_add, Nat.add_sub_cancel' (by omega)]
  have hpf : (p ! : ℝ) ≠ 0 := by positivity
  have hEq : (1 / h ^ k) * ∑ j, c j * f (x + s j * h) - iteratedDeriv k f x
        - h ^ (p - k) * ((1 / (p ! : ℝ)) * S) * iteratedDeriv p f x
        = (1 / h ^ k) * ∑ j, c j * r j := by
    rw [hA, hP, hP2, hpk]
    simp only [hT]
    field_simp
    ring
  rw [hEq, abs_mul, abs_of_pos (by positivity : (0 : ℝ) < 1 / h ^ k)]
  have hsum : |∑ j, c j * r j| ≤
      ∑ j, |c j| * (|s j| ^ (p + 1) * h ^ (p + 1) / ((p + 1) ! : ℝ) * M) := by
    refine (Finset.abs_sum_le_sum_abs _ _).trans (Finset.sum_le_sum (fun j _ => ?_))
    rw [abs_mul]
    exact mul_le_mul_of_nonneg_left (hrb j) (abs_nonneg _)
  have hrhs : (1 / h ^ k) * ∑ j, |c j| * (|s j| ^ (p + 1) * h ^ (p + 1) / ((p + 1) ! : ℝ) * M)
      = h ^ (p + 1 - k) / ((p + 1) ! : ℝ) * (∑ j, |c j| * |s j| ^ (p + 1)) * M := by
    rw [Finset.mul_sum, Finset.mul_sum, Finset.sum_mul]
    refine Finset.sum_congr rfl (fun j _ => ?_)
    rw [hp1k]
    field_simp
  rw [← hrhs]
  exact mul_le_mul_of_nonneg_left hsum (by positivity)

/-- Unequal gaps cost one order. Put three points at -h₋, 0 and +h₊ with both gaps positive.
The curvature weights 2/(h₋(h₋+h₊)), -2/(h₋h₊) and 2/(h₊(h₋+h₊)) pass the moment conditions
for powers 0, 1 and 2 (moments 0, 0 and 2!), and the power-3 moment over 3! is (h₊ - h₋)/3,
the constant of the first-order error (h₊ - h₋)/3 · f'''. -/
theorem uneven_curvature_weights (hm hp : ℝ) (hm0 : 0 < hm) (hp0 : 0 < hp) :
    let c₁ := 2 / (hm * (hm + hp))
    let c₂ := -2 / (hm * hp)
    let c₃ := 2 / (hp * (hm + hp))
    c₁ + c₂ + c₃ = 0 ∧
    c₁ * (-hm) + c₂ * 0 + c₃ * hp = 0 ∧
    c₁ * (-hm) ^ 2 + c₂ * 0 ^ 2 + c₃ * hp ^ 2 = 2 ∧
    (c₁ * (-hm) ^ 3 + c₂ * 0 ^ 3 + c₃ * hp ^ 3) / 3 ! = (hp - hm) / 3 := by
  intro c₁ c₂ c₃
  have h1 : hm ≠ 0 := hm0.ne'
  have h2 : hp ≠ 0 := hp0.ne'
  have h3 : hm + hp ≠ 0 := by positivity
  simp only [c₁, c₂, c₃, Nat.factorial]
  refine ⟨?_, ?_, ?_, ?_⟩ <;> field_simp <;> ring

-- Five-point slope on -2, -1, 0, 1, 2: weights 1/12, -2/3, 0, 2/3, -1/12 give moments
-- 0, 1, 0, 0, 0 for powers 0 to 4; power 5 over 5! is -1/30.
example :
    (1 : ℚ) / 12 + -2 / 3 + 0 + 2 / 3 + -1 / 12 = 0 ∧
    (1 : ℚ) / 12 * (-2) + -2 / 3 * (-1) + 0 * 0 + 2 / 3 * 1 + -1 / 12 * 2 = 1 ∧
    (1 : ℚ) / 12 * (-2) ^ 2 + -2 / 3 * (-1) ^ 2 + 2 / 3 * 1 ^ 2 + -1 / 12 * 2 ^ 2 = 0 ∧
    (1 : ℚ) / 12 * (-2) ^ 3 + -2 / 3 * (-1) ^ 3 + 2 / 3 * 1 ^ 3 + -1 / 12 * 2 ^ 3 = 0 ∧
    (1 : ℚ) / 12 * (-2) ^ 4 + -2 / 3 * (-1) ^ 4 + 2 / 3 * 1 ^ 4 + -1 / 12 * 2 ^ 4 = 0 ∧
    ((1 : ℚ) / 12 * (-2) ^ 5 + -2 / 3 * (-1) ^ 5 + 2 / 3 * 1 ^ 5 + -1 / 12 * 2 ^ 5) / 120
      = -1 / 30 := by norm_num

-- Five-point curvature: weights -1/12, 4/3, -5/2, 4/3, -1/12 give moments 0, 0, 2, 0, 0
-- for powers 0 to 4, power 5 cancels by symmetry, and power 6 over 6! is -1/90.
example :
    (-1 : ℚ) / 12 + 4 / 3 + -5 / 2 + 4 / 3 + -1 / 12 = 0 ∧
    (-1 : ℚ) / 12 * (-2) + 4 / 3 * (-1) + 4 / 3 * 1 + -1 / 12 * 2 = 0 ∧
    (-1 : ℚ) / 12 * (-2) ^ 2 + 4 / 3 * (-1) ^ 2 + 4 / 3 * 1 ^ 2 + -1 / 12 * 2 ^ 2 = 2 ∧
    (-1 : ℚ) / 12 * (-2) ^ 3 + 4 / 3 * (-1) ^ 3 + 4 / 3 * 1 ^ 3 + -1 / 12 * 2 ^ 3 = 0 ∧
    (-1 : ℚ) / 12 * (-2) ^ 4 + 4 / 3 * (-1) ^ 4 + 4 / 3 * 1 ^ 4 + -1 / 12 * 2 ^ 4 = 0 ∧
    (-1 : ℚ) / 12 * (-2) ^ 5 + 4 / 3 * (-1) ^ 5 + 4 / 3 * 1 ^ 5 + -1 / 12 * 2 ^ 5 = 0 ∧
    ((-1 : ℚ) / 12 * (-2) ^ 6 + 4 / 3 * (-1) ^ 6 + 4 / 3 * 1 ^ 6 + -1 / 12 * 2 ^ 6) / 720
      = -1 / 90 := by norm_num

-- The hand solution in Why it works: 2c₁ + 8c₂ = 2 and 2c₁ + 32c₂ = 0 give c₂ = -1/12,
-- c₁ = 4/3, and then c₀ = -2c₁ - 2c₂ = -5/2.
example :
    2 * ((4 : ℚ) / 3) + 8 * (-1 / 12) = 2 ∧ 2 * ((4 : ℚ) / 3) + 32 * (-1 / 12) = 0 ∧
    -2 * ((4 : ℚ) / 3) - 2 * (-1 / 12) = -5 / 2 := by norm_num

-- Cross term at the corners (a, b) = (+,+), (+,-), (-,+), (-,-) with weights 1/4, -1/4,
-- -1/4, 1/4: the moments of 1, a, b, a², b² and a²b² are 0, the ab moment is 1, and the
-- a³b and ab³ moments over 3! · 1! are 1/6 each.
example :
    (1 : ℚ) / 4 - 1 / 4 - 1 / 4 + 1 / 4 = 0 ∧
    (1 : ℚ) / 4 * 1 + -1 / 4 * 1 + -1 / 4 * (-1) + 1 / 4 * (-1) = 0 ∧
    (1 : ℚ) / 4 * 1 + -1 / 4 * (-1) + -1 / 4 * 1 + 1 / 4 * (-1) = 0 ∧
    (1 : ℚ) / 4 * (1 * 1) + -1 / 4 * (1 * -1) + -1 / 4 * (-1 * 1) + 1 / 4 * (-1 * -1) = 1 ∧
    (1 : ℚ) / 4 * 1 ^ 2 + -1 / 4 * 1 ^ 2 + -1 / 4 * (-1) ^ 2 + 1 / 4 * (-1) ^ 2 = 0 ∧
    (1 : ℚ) / 4 * 1 ^ 2 + -1 / 4 * (-1) ^ 2 + -1 / 4 * 1 ^ 2 + 1 / 4 * (-1) ^ 2 = 0 ∧
    (1 : ℚ) / 4 * 1 + -1 / 4 * 1 + -1 / 4 * 1 + 1 / 4 * 1 = 0 ∧
    ((1 : ℚ) / 4 * (1 ^ 3 * 1) + -1 / 4 * (1 ^ 3 * -1) + -1 / 4 * ((-1) ^ 3 * 1)
      + 1 / 4 * ((-1) ^ 3 * -1)) / 6 = 1 / 6 ∧
    ((1 : ℚ) / 4 * (1 * 1 ^ 3) + -1 / 4 * (1 * (-1) ^ 3) + -1 / 4 * (-1 * 1 ^ 3)
      + 1 / 4 * (-1 * (-1) ^ 3)) / 6 = 1 / 6 := by norm_num

-- The cross weights are the central slope -1/2, 0, 1/2 in a times the same in b.
example :
    (1 : ℚ) / 2 * (1 / 2) = 1 / 4 ∧ (1 : ℚ) / 2 * (-1 / 2) = -1 / 4 ∧
    (-1 : ℚ) / 2 * (1 / 2) = -1 / 4 ∧ (-1 : ℚ) / 2 * (-1 / 2) = 1 / 4 := by norm_num

-- Uneven -10, 0, +25 bp: weights 1/175, -1/125, 2/875 per bp², moments 0, 0, 2, and the
-- power-3 moment over 3! is the error constant 5 bp.
example :
    (2 : ℚ) / (10 * (10 + 25)) = 1 / 175 ∧ (-2 : ℚ) / (10 * 25) = -1 / 125 ∧
    (2 : ℚ) / (25 * (10 + 25)) = 2 / 875 ∧
    (1 : ℚ) / 175 + -1 / 125 + 2 / 875 = 0 ∧
    (1 : ℚ) / 175 * (-10) + 2 / 875 * 25 = 0 ∧
    (1 : ℚ) / 175 * (-10) ^ 2 + 2 / 875 * 25 ^ 2 = 2 ∧
    ((1 : ℚ) / 175 * (-10) ^ 3 + 2 / 875 * 25 ^ 3) / 6 = 5 ∧
    ((25 : ℚ) - 10) / 3 = 5 := by norm_num

-- Adding +50 bp: weights 1/140, -13/1250, 16/4375, -1/2500 on -10, 0, 25, 50 give moments
-- 0, 0, 2, 0, and the power-4 moment over 4! is the error constant -125/3 bp².
example :
    (1 : ℚ) / 140 + -13 / 1250 + 16 / 4375 + -1 / 2500 = 0 ∧
    (1 : ℚ) / 140 * (-10) + 16 / 4375 * 25 + -1 / 2500 * 50 = 0 ∧
    (1 : ℚ) / 140 * (-10) ^ 2 + 16 / 4375 * 25 ^ 2 + -1 / 2500 * 50 ^ 2 = 2 ∧
    (1 : ℚ) / 140 * (-10) ^ 3 + 16 / 4375 * 25 ^ 3 + -1 / 2500 * 50 ^ 3 = 0 ∧
    ((1 : ℚ) / 140 * (-10) ^ 4 + 16 / 4375 * 25 ^ 4 + -1 / 2500 * 50 ^ 4) / 24 = -125 / 3 := by
  norm_num

-- The three-point stencils: slope -1/2, 0, 1/2 has power-3 moment over 3! of 1/6; curvature
-- 1, -2, 1 has power-4 moment over 4! of 1/12.
example :
    ((-1 : ℚ) / 2 * (-1) ^ 3 + 1 / 2 * 1 ^ 3) / 6 = 1 / 6 ∧
    ((1 : ℚ) * (-1) ^ 4 + 1 * 1 ^ 4) / 24 = 1 / 12 := by norm_num

#print axioms stencil_weights_exist_unique
#print axioms stencil_error_first_uncancelled_moment
#print axioms uneven_curvature_weights
