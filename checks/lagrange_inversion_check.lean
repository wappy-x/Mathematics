-- Lagrange inversion: if a formal power series T satisfies T = x phi(T), then for every n at least 1 its coefficient at x^n is (1/n) times the coefficient of t^(n-1) in phi(t)^n, which counts d-way merge plans as (1/n) C(dn, n - 1) and rooted labelled trees as n^(n-1).
import Mathlib.RingTheory.PowerSeries.Substitution
import Mathlib.RingTheory.PowerSeries.Exp
import Mathlib.RingTheory.PowerSeries.Derivative
import Mathlib.Combinatorics.Enumerative.Catalan.Basic
import Mathlib.Tactic.NormNum

open PowerSeries Nat

theorem lagrange_coeff_X_mul_derivative {R : Type*} [CommSemiring R] (A : R⟦X⟧) (j : ℕ) :
    coeff j (X * d⁄dX A) = (j : R) * coeff j A := by
  rcases j with _ | i
  · simp
  · rw [coeff_succ_X_mul, coeff_derivative]
    push_cast; ring

#print axioms lagrange_coeff_X_mul_derivative

theorem lagrange_weighted_sum {R : Type*} [CommSemiring R] (A B : R⟦X⟧) (m : ℕ) :
    ∑ j ∈ Finset.range (m + 1), coeff j A * ((j : R) * coeff (m - j) B) =
      coeff m (X * d⁄dX A * B) := by
  rw [coeff_mul, Finset.Nat.sum_antidiagonal_eq_sum_range_succ
    (fun i l => coeff i (X * d⁄dX A) * coeff l B)]
  refine Finset.sum_congr rfl fun j _ => ?_
  rw [lagrange_coeff_X_mul_derivative]; ring

#print axioms lagrange_weighted_sum

theorem lagrange_key_identity {R : Type*} [CommSemiring R] (φ : R⟦X⟧) (k m : ℕ) (hk : 1 ≤ k) :
    ((k + m : ℕ) : R⟦X⟧) * (X * d⁄dX (φ ^ k) * φ ^ m) = (k : R⟦X⟧) * (X * d⁄dX (φ ^ (k + m))) := by
  obtain ⟨k', rfl⟩ : ∃ k', k = k' + 1 := ⟨k - 1, by omega⟩
  rw [derivative_pow, derivative_pow, show k' + 1 + m - 1 = k' + m by omega,
    show k' + 1 - 1 = k' by omega, pow_add]
  push_cast; ring

#print axioms lagrange_key_identity

theorem lagrange_core {R : Type*} [CommSemiring R]
    (hcancel : ∀ (m : ℕ) (a b : R), m ≠ 0 → (m : R) * a = m * b → a = b)
    (φ T : R⟦X⟧)
    (hrec : ∀ n k : ℕ, 1 ≤ k → k ≤ n → coeff n (T ^ k) =
      ∑ j ∈ Finset.range (n - k + 1), coeff j (φ ^ k) * coeff (n - k) (T ^ j)) :
    ∀ n k : ℕ, k ≤ n → (n : R) * coeff n (T ^ k) = k * coeff (n - k) (φ ^ n) := by
  intro n
  induction n using Nat.strong_induction_on with
  | _ n ih =>
  intro k hk
  rcases Nat.eq_zero_or_pos k with rfl | hk1
  · rcases Nat.eq_zero_or_pos n with rfl | hn
    · simp
    · simp [coeff_one, hn.ne']
  obtain ⟨m, rfl⟩ : ∃ m, n = k + m := ⟨n - k, by omega⟩
  rw [hrec _ _ hk1 hk, show k + m - k = m by omega]
  rcases Nat.eq_zero_or_pos m with rfl | hm
  · simp
  apply hcancel m _ _ hm.ne'
  have hsum : (m : R) * ∑ j ∈ Finset.range (m + 1), coeff j (φ ^ k) * coeff m (T ^ j) =
      ∑ j ∈ Finset.range (m + 1), coeff j (φ ^ k) * ((j : R) * coeff (m - j) (φ ^ m)) := by
    rw [Finset.mul_sum]
    refine Finset.sum_congr rfl fun j hj => ?_
    have hj' : j ≤ m := Nat.lt_succ_iff.mp (Finset.mem_range.mp hj)
    rw [← ih m (by omega) j hj']; ring
  have hkey := congrArg (coeff m) (lagrange_key_identity φ k m hk1)
  rw [← map_natCast (C (R := R)), ← map_natCast (C (R := R)), coeff_C_mul, coeff_C_mul,
    lagrange_coeff_X_mul_derivative] at hkey
  calc (m : R) * (((k + m : ℕ) : R) * ∑ j ∈ Finset.range (m + 1), coeff j (φ ^ k) * coeff m (T ^ j))
      = ((k + m : ℕ) : R) * ((m : R) * ∑ j ∈ Finset.range (m + 1), coeff j (φ ^ k) * coeff m (T ^ j)) := by ring
    _ = ((k + m : ℕ) : R) * coeff m (X * d⁄dX (φ ^ k) * φ ^ m) := by
        rw [hsum, lagrange_weighted_sum]
    _ = (k : R) * ((m : R) * coeff m (φ ^ (k + m))) := hkey
    _ = (m : R) * ((k : R) * coeff m (φ ^ (k + m))) := by ring

#print axioms lagrange_core

theorem lagrange_coeff_pow_vanish {R : Type*} [CommSemiring R] (T : R⟦X⟧)
    (h0 : constantCoeff T = 0) (m j : ℕ) (hmj : m < j) : coeff m (T ^ j) = 0 := by
  obtain ⟨U, hU⟩ := X_dvd_iff.mpr h0
  rw [hU, mul_pow, coeff_X_pow_mul', ite_eq_right (by omega)]

#print axioms lagrange_coeff_pow_vanish

/-- Lagrange inversion. Let `φ` be any formal power series over a field of characteristic zero
(its coefficients may be fractions) and let `T` be a formal power series fixed by the equation
`T = x φ(T)`. Then for every `n ≥ 1` the coefficient of `x ^ n` in `T` is the coefficient of
`t ^ (n - 1)` in `φ(t) ^ n`, divided by `n`. -/
theorem lagrange_inversion {K : Type*} [Field K] [CharZero K] (φ T : K⟦X⟧)
    (hT : T = X * PowerSeries.subst T φ) (n : ℕ) (hn : 1 ≤ n) :
    coeff n T = (1 / (n : K)) * coeff (n - 1) (φ ^ n) := by
  have h0 : constantCoeff T = 0 := by rw [hT]; simp
  have hS : HasSubst T := HasSubst.of_constantCoeff_zero' h0
  have hsub : ∀ (ψ : K⟦X⟧) (m : ℕ), coeff m (subst T ψ) =
      ∑ j ∈ Finset.range (m + 1), coeff j ψ * coeff m (T ^ j) := by
    intro ψ m
    rw [coeff_subst' hS, finsum_eq_sum_of_support_subset (s := Finset.range (m + 1))]
    · simp only [smul_eq_mul]
    · intro j hj
      rw [Function.mem_support] at hj
      simp only [Finset.coe_range, Set.mem_Iio]
      by_contra hc
      exact hj (by rw [lagrange_coeff_pow_vanish T h0 m j (by omega), smul_zero])
  have hrec : ∀ n k : ℕ, 1 ≤ k → k ≤ n → coeff n (T ^ k) =
      ∑ j ∈ Finset.range (n - k + 1), coeff j (φ ^ k) * coeff (n - k) (T ^ j) := by
    intro n k _ hkn
    have hTk : T ^ k = X ^ k * subst T (φ ^ k) := by
      rw [subst_pow hS]
      conv_lhs => rw [hT]
      rw [mul_pow]
    rw [hTk, coeff_X_pow_mul', ite_eq_left hkn, hsub]
  have hcancel : ∀ (m : ℕ) (a b : K), m ≠ 0 → (m : K) * a = m * b → a = b :=
    fun m a b hm h => mul_left_cancel₀ (Nat.cast_ne_zero.mpr hm) h
  have h := lagrange_core hcancel φ T hrec n 1 hn
  rw [pow_one, Nat.cast_one, one_mul] at h
  have hn' : (n : K) ≠ 0 := Nat.cast_ne_zero.mpr (by omega)
  rw [← h]; field_simp

/-- Merge plans. A machine merges `d` neighbouring stacks, so a merge has `d` sides, each a bare
stack or another merge, and the plan series satisfies `T = x (1 + T) ^ d`. Then the number of plans
with `n ≥ 1` merges is `(1/n) C(dn, n - 1)`: `n` times the coefficient of `x ^ n` in `T` is the
binomial coefficient `C(dn, n - 1)`. At `d = 2` this is 14 at four merges; at `d = 3` it is 55. -/
theorem merge_plans_lagrange (d : ℕ) (T : ℕ⟦X⟧) (hT : T = X * (1 + T) ^ d) (n : ℕ) (hn : 1 ≤ n) :
    n * coeff n T = (d * n).choose (n - 1) := by
  have h0 : constantCoeff T = 0 := by rw [hT]; simp
  have hcoefX : ∀ N j : ℕ, coeff j (((1 : ℕ⟦X⟧) + X) ^ N) = N.choose j := by
    intro N j
    rw [add_comm, add_pow, map_sum]
    simp only [one_pow, mul_one, coeff_mul_natCast, coeff_X_pow]
    rw [Finset.sum_eq_single j]
    · simp
    · intro b _ hb; simp [Ne.symm hb]
    · intro hj; simp only [Finset.mem_range, not_lt] at hj
      simp [Nat.choose_eq_zero_of_lt (by omega : N < j)]
  have hpow : ∀ N m : ℕ, coeff m ((1 + T) ^ N) =
      ∑ j ∈ Finset.range (m + 1), coeff j (((1 : ℕ⟦X⟧) + X) ^ N) * coeff m (T ^ j) := by
    intro N m
    simp only [hcoefX]
    rw [add_comm, add_pow, map_sum]
    simp only [one_pow, mul_one, coeff_mul_natCast, Nat.cast_id]
    have e1 : ∑ j ∈ Finset.range (N + 1), coeff m (T ^ j) * N.choose j =
        ∑ j ∈ Finset.range (N + m + 1), coeff m (T ^ j) * N.choose j := by
      apply Finset.sum_subset
      · intro j hj; simp only [Finset.mem_range] at hj ⊢; omega
      · intro j _ hj; simp only [Finset.mem_range, not_lt] at hj
        simp [Nat.choose_eq_zero_of_lt (by omega : N < j)]
    have e2 : ∑ j ∈ Finset.range (m + 1), N.choose j * coeff m (T ^ j) =
        ∑ j ∈ Finset.range (N + m + 1), coeff m (T ^ j) * N.choose j := by
      simp only [mul_comm (N.choose _ : ℕ)]
      apply Finset.sum_subset
      · intro j hj; simp only [Finset.mem_range] at hj ⊢; omega
      · intro j _ hj; simp only [Finset.mem_range, not_lt] at hj
        simp [lagrange_coeff_pow_vanish T h0 m j (by omega)]
    rw [e1, e2]
  have hrec : ∀ n k : ℕ, 1 ≤ k → k ≤ n → coeff n (T ^ k) =
      ∑ j ∈ Finset.range (n - k + 1), coeff j ((((1 : ℕ⟦X⟧) + X) ^ d) ^ k) * coeff (n - k) (T ^ j) := by
    intro n k _ hkn
    have hTk : T ^ k = X ^ k * (1 + T) ^ (d * k) := by
      conv_lhs => rw [hT]
      rw [mul_pow, pow_mul]
    rw [hTk, coeff_X_pow_mul', ite_eq_left hkn, hpow, ← pow_mul]
  have hcancel : ∀ (m : ℕ) (a b : ℕ), m ≠ 0 → (m : ℕ) * a = m * b → a = b :=
    fun m a b hm h => Nat.eq_of_mul_eq_mul_left (Nat.pos_of_ne_zero hm) h
  have h := lagrange_core hcancel _ T hrec n 1 hn
  rw [pow_one, Nat.cast_one, one_mul, ← pow_mul, hcoefX] at h
  simpa using h

/-- Rooted labelled trees. If `T` is the exponential series fixed by `T = x e^T`, then for every
`n ≥ 1` the number `n! [x^n] T` of rooted trees on `n` labelled vertices is `n ^ (n - 1)`. -/
theorem rooted_labelled_trees_lagrange (T : ℚ⟦X⟧) (hT : T = X * PowerSeries.subst T (exp ℚ))
    (n : ℕ) (hn : 1 ≤ n) :
    (n ! : ℚ) * coeff n T = (n : ℚ) ^ (n - 1) := by
  rw [lagrange_inversion (exp ℚ) T hT n hn, exp_pow_eq_rescale_exp, coeff_rescale, coeff_exp]
  obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
  rw [Nat.add_sub_cancel, Nat.factorial_succ]
  simp only [Algebra.algebraMap_self, RingHom.id_apply]
  have : (k ! : ℚ) ≠ 0 := by positivity
  push_cast
  field_simp

-- Two-way merges, four merges: (1 + t)^8 has C(8, 3) = 56 at t^3, and 56 / 4 = 14, the Catalan number.
example : Nat.choose 8 3 = 56 ∧ 56 / 4 = 14 ∧ 4 * 14 = 56 := by decide

example : catalan 4 = 14 := by
  simp only [catalan_eq_centralBinom_div, Nat.centralBinom]
  decide

-- The general two-way count (1/n) C(2n, n - 1) agrees with the Catalan card's C(2n, n)/(n + 1) at n = 4.
example : Nat.choose 8 3 / 4 = Nat.choose 8 4 / (4 + 1) := by decide

-- Three-way merges, four merges: (1 + t)^12 has C(12, 3) = 220 at t^3, and 220 / 4 = 55.
example : Nat.choose 12 3 = 220 ∧ 220 / 4 = 55 ∧ 4 * 55 = 220 := by decide

-- Rooted labelled trees on 4 vertices: e^(4t) has 4^3/3! = 64/6 at t^3, and 4! x (1/4) x 64/6 = 64.
example : (4 : ℚ) ^ 3 / (3 ! : ℚ) = 64 / 6 := by norm_num [Nat.factorial]

example : (4 ! : ℚ) * (1 / 4) * (64 / 6) = 64 ∧ (4 : ℚ) ^ 3 = 64 := by norm_num [Nat.factorial]

-- Dropping the depot: 64 / 4 = 16 = 4^2 road layouts on four villages.
example : 4 ^ 3 / 4 = 16 ∧ 4 ^ 2 = 16 := by decide

-- The mistakes: no 1/n gives 56; reading t^4 gives C(8, 4) / 4 = 70/4, not whole.
example : Nat.choose 8 4 = 70 ∧ 70 % 4 ≠ 0 := by decide

#print axioms lagrange_inversion
#print axioms merge_plans_lagrange
#print axioms rooted_labelled_trees_lagrange
