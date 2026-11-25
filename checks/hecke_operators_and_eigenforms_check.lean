-- Hecke operators: on q-expansion coefficients the Hecke operators satisfy T_m T_n = T_mn for coprime m and n and the prime-power rule, and an eigenform scaled to a_1 = 1 has multiplicative coefficients.
import Mathlib.NumberTheory.Divisors
import Mathlib.Algebra.BigOperators.Group.Finset.Basic
import Mathlib.Tactic.NormNum
import Mathlib

open Finset

/-- The Hecke operator `T_n` of weight `k` and level `N` on the coefficients of a q-series
`f = ∑ a_m q^m`: `a_l(T_n f) = ∑ u^(k-1) a_(l n / u²)`, the sum over the divisors `u` of
`gcd(l, n)` that share no factor with `N`. -/
def heckeCoeff {R : Type*} [CommRing R] (N k n : ℕ) (a : ℕ → R) : ℕ → R :=
  fun l => ∑ u ∈ (Nat.gcd l n).divisors with Nat.Coprime u N, (u : R) ^ (k - 1) * a (l * n / u ^ 2)

/-- `T_1` is the identity. -/
theorem heckeCoeff_one {R : Type*} [CommRing R] (N k : ℕ) (a : ℕ → R) :
    heckeCoeff N k 1 a = a := by
  funext l
  simp [heckeCoeff, Finset.filter_singleton]

/-- The coefficient `q^1` of `T_n f` is `a_n`. -/
theorem heckeCoeff_at_one {R : Type*} [CommRing R] (N k n : ℕ) (a : ℕ → R) :
    heckeCoeff N k n a 1 = a n := by
  simp [heckeCoeff, Finset.filter_singleton]

/-- When `gcd(l, n)` is a power `p^t` of a prime not dividing `N`, the sum runs over `p^i`, `i ≤ t`. -/
theorem heckeCoeff_of_gcd_eq_pow {R : Type*} [CommRing R] (N k : ℕ) {p : ℕ} (hp : p.Prime)
    (hpN : ¬ p ∣ N) (a : ℕ → R) {n l t : ℕ} (h : Nat.gcd l n = p ^ t) :
    heckeCoeff N k n a l =
      ∑ i ∈ range (t + 1), ((p ^ i : ℕ) : R) ^ (k - 1) * a (l * n / (p ^ i) ^ 2) := by
  have hcop : p.Coprime N := (Nat.Prime.coprime_iff_not_dvd hp).2 hpN
  unfold heckeCoeff
  rw [h, Finset.filter_true_of_mem, Nat.sum_divisors_prime_pow hp]
  intro x hx
  exact Nat.Coprime.coprime_dvd_left (Nat.dvd_of_mem_divisors hx) (Nat.Coprime.pow_left t hcop)

/-- `a_(p l)(T_(p^(s+1)) f) = a_(p l p^(s+1)) + p^(k-1) a_l(T_(p^s) f)`. -/
theorem heckeCoeff_pow_succ_mul {R : Type*} [CommRing R] (N k : ℕ) {p : ℕ} (hp : p.Prime)
    (hpN : ¬ p ∣ N) (s : ℕ) (a : ℕ → R) (l : ℕ) :
    heckeCoeff N k (p ^ (s + 1)) a (p * l) =
      a (p * l * p ^ (s + 1)) + (p : R) ^ (k - 1) * heckeCoeff N k (p ^ s) a l := by
  obtain ⟨t, -, ht⟩ := (Nat.dvd_prime_pow hp).1 (Nat.gcd_dvd_right l (p ^ s))
  have ht' : Nat.gcd (p * l) (p ^ (s + 1)) = p ^ (t + 1) := by
    rw [pow_succ', Nat.gcd_mul_left, ht, pow_succ']
  rw [heckeCoeff_of_gcd_eq_pow N k hp hpN a ht', heckeCoeff_of_gcd_eq_pow N k hp hpN a ht,
    Finset.sum_range_succ', Finset.mul_sum, add_comm]
  congr 1
  · simp
  · apply Finset.sum_congr rfl
    intro i _
    have hp0 : 0 < p := hp.pos
    rw [show p * l * p ^ (s + 1) = (p * p) * (l * p ^ s) by ring,
      show (p ^ (i + 1)) ^ 2 = (p * p) * (p ^ i) ^ 2 by ring,
      Nat.mul_div_mul_left _ _ (Nat.mul_pos hp0 hp0)]
    push_cast
    ring

/-- If `p ∤ l` then `a_l(T_(p^s) f) = a_(l p^s)`. -/
theorem heckeCoeff_pow_of_not_dvd {R : Type*} [CommRing R] (N k : ℕ) {p : ℕ} (hp : p.Prime)
    (hpN : ¬ p ∣ N) (s : ℕ) (a : ℕ → R) {l : ℕ} (hl : ¬ p ∣ l) :
    heckeCoeff N k (p ^ s) a l = a (l * p ^ s) := by
  have h : Nat.gcd l (p ^ s) = p ^ 0 := by
    rw [pow_zero]
    exact Nat.Coprime.pow_right s
      (Nat.coprime_comm.1 ((Nat.Prime.coprime_iff_not_dvd hp).2 hl))
  rw [heckeCoeff_of_gcd_eq_pow N k hp hpN a h]
  simp

/-- Hecke operators multiply like their indices: for coprime `m` and `n`, at any weight `k` and
level `N`, applying `T_n` and then `T_m` to any q-series gives `T_(mn)` of it. -/
theorem hecke_mul_of_coprime {R : Type*} [CommRing R] (N k : ℕ) {m n : ℕ}
    (hmn : Nat.Coprime m n) (a : ℕ → R) :
    heckeCoeff N k m (heckeCoeff N k n a) = heckeCoeff N k (m * n) a := by
  funext l
  rcases Nat.eq_zero_or_pos m with rfl | hm
  · have : n = 1 := by simpa using hmn
    subst this
    simp [heckeCoeff_one]
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · have : m = 1 := by simpa using hmn
    subst this
    simp [heckeCoeff_one]
  unfold heckeCoeff
  rw [Finset.sum_congr rfl (g := fun u => ∑ v ∈ (Nat.gcd l n).divisors with Nat.Coprime v N,
      ((u * v : ℕ) : R) ^ (k - 1) * a (l * (m * n) / (u * v) ^ 2))]
  · rw [← Finset.sum_product' (f := fun u v => ((u * v : ℕ) : R) ^ (k - 1) *
      a (l * (m * n) / (u * v) ^ 2))]
    apply Finset.sum_nbij' (fun x => x.1 * x.2) (fun w => (Nat.gcd w m, Nat.gcd w n))
    · rintro ⟨u, v⟩ hx
      simp only [Finset.mem_product, Finset.mem_filter, Nat.mem_divisors] at hx ⊢
      obtain ⟨⟨⟨hu, -⟩, huN⟩, ⟨⟨hv, -⟩, hvN⟩⟩ := hx
      have huv : u.Coprime v :=
        (hmn.coprime_dvd_left (hu.trans (Nat.gcd_dvd_right _ _))).coprime_dvd_right
          (hv.trans (Nat.gcd_dvd_right _ _))
      refine ⟨⟨Nat.dvd_gcd (huv.mul_dvd_of_dvd_of_dvd (hu.trans (Nat.gcd_dvd_left _ _))
        (hv.trans (Nat.gcd_dvd_left _ _))) (Nat.mul_dvd_mul (hu.trans (Nat.gcd_dvd_right _ _))
        (hv.trans (Nat.gcd_dvd_right _ _))), (Nat.gcd_pos_of_pos_right l (Nat.mul_pos hm hn)).ne'⟩,
        Nat.Coprime.mul_left huN hvN⟩
    · intro w hw
      simp only [Finset.mem_product, Finset.mem_filter, Nat.mem_divisors] at hw ⊢
      obtain ⟨⟨hw, -⟩, hwN⟩ := hw
      have hwl : w ∣ l := hw.trans (Nat.gcd_dvd_left _ _)
      exact ⟨⟨⟨Nat.gcd_dvd_gcd_of_dvd_left m hwl, (Nat.gcd_pos_of_pos_right l hm).ne'⟩,
          Nat.Coprime.coprime_dvd_left (Nat.gcd_dvd_left w m) hwN⟩,
        ⟨⟨Nat.gcd_dvd_gcd_of_dvd_left n hwl, (Nat.gcd_pos_of_pos_right l hn).ne'⟩,
          Nat.Coprime.coprime_dvd_left (Nat.gcd_dvd_left w n) hwN⟩⟩
    · rintro ⟨u, v⟩ hx
      simp only [Finset.mem_product, Finset.mem_filter, Nat.mem_divisors] at hx
      obtain ⟨⟨⟨hu, -⟩, -⟩, ⟨⟨hv, -⟩, -⟩⟩ := hx
      have hum : u ∣ m := hu.trans (Nat.gcd_dvd_right _ _)
      have hvn : v ∣ n := hv.trans (Nat.gcd_dvd_right _ _)
      have hvm : v.Coprime m := (hmn.coprime_dvd_right hvn).symm
      have hun : u.Coprime n := hmn.coprime_dvd_left hum
      simp only [Prod.mk.injEq]
      exact ⟨by rw [hvm.gcd_mul_right_cancel u, Nat.gcd_eq_left hum],
        by rw [hun.gcd_mul_left_cancel v, Nat.gcd_eq_left hvn]⟩
    · intro w hw
      simp only [Finset.mem_filter, Nat.mem_divisors] at hw
      obtain ⟨⟨hw, -⟩, -⟩ := hw
      show Nat.gcd w m * Nat.gcd w n = w
      rw [← Nat.Coprime.gcd_mul w hmn, Nat.gcd_eq_left (hw.trans (Nat.gcd_dvd_right _ _))]
    · intro x _
      rfl
  · intro u hu
    simp only [Finset.mem_filter, Nat.mem_divisors] at hu
    obtain ⟨⟨hu, -⟩, -⟩ := hu
    have hum : u ∣ m := hu.trans (Nat.gcd_dvd_right _ _)
    have hun : u.Coprime n := hmn.coprime_dvd_left hum
    have hu0 : 0 < u := Nat.pos_of_dvd_of_pos hum hm
    obtain ⟨l1, rfl⟩ := hu.trans (Nat.gcd_dvd_left _ _)
    obtain ⟨m1, rfl⟩ := hum
    have hm1 : m1.Coprime n := hmn.coprime_dvd_left (dvd_mul_left m1 u)
    have hdiv : u * l1 * (u * m1) / u ^ 2 = l1 * m1 := by
      rw [show u * l1 * (u * m1) = u ^ 2 * (l1 * m1) by ring,
        Nat.mul_div_cancel_left _ (by positivity)]
    rw [hdiv, hm1.gcd_mul_right_cancel l1, hun.gcd_mul_left_cancel l1, Finset.mul_sum]
    apply Finset.sum_congr rfl
    intro v hv
    simp only [Finset.mem_filter, Nat.mem_divisors] at hv
    obtain ⟨⟨hv, -⟩, -⟩ := hv
    have hv0 : 0 < v := Nat.pos_of_ne_zero (by rintro rfl; simp at hv; omega)
    obtain ⟨l2, rfl⟩ := hv.trans (Nat.gcd_dvd_left _ _)
    obtain ⟨n2, rfl⟩ := hv.trans (Nat.gcd_dvd_right _ _)
    rw [show v * l2 * m1 * (v * n2) = v ^ 2 * (l2 * m1 * n2) by ring,
      show u * (v * l2) * (u * m1 * (v * n2)) = (u * v) ^ 2 * (l2 * m1 * n2) by ring,
      Nat.mul_div_cancel_left _ (by positivity), Nat.mul_div_cancel_left _ (by positivity)]
    push_cast
    ring

/-- The prime-power rule: for a prime `p` not dividing the level `N`,
`T_p T_(p^(r+1)) = T_(p^(r+2)) + p^(k-1) T_(p^r)` on every q-series. -/
theorem hecke_prime_pow_rule {R : Type*} [CommRing R] (N k : ℕ) {p : ℕ} (hp : p.Prime)
    (hpN : ¬ p ∣ N) (r : ℕ) (a : ℕ → R) :
    heckeCoeff N k p (heckeCoeff N k (p ^ (r + 1)) a) =
      heckeCoeff N k (p ^ (r + 2)) a + (p : R) ^ (k - 1) • heckeCoeff N k (p ^ r) a := by
  have hT := heckeCoeff_pow_succ_mul (R := R) N k hp hpN
  have hp1 : ∀ (b : ℕ → R) (l : ℕ), heckeCoeff N k p b (p * l) = b (p * l * p) +
      (p : R) ^ (k - 1) * b l := by
    intro b l
    have h := hT 0 b l
    rw [pow_zero, heckeCoeff_one, zero_add, pow_one] at h
    exact h
  have hp2 : ∀ (b : ℕ → R) (l : ℕ), ¬ p ∣ l → heckeCoeff N k p b l = b (l * p) := by
    intro b l hl
    have h := heckeCoeff_pow_of_not_dvd N k hp hpN 1 b hl
    rw [pow_one] at h
    exact h
  funext l
  simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul]
  by_cases hl : p ∣ l
  · obtain ⟨l', rfl⟩ := hl
    have h2 : heckeCoeff N k (p ^ (r + 2)) a (p * l') =
        a (p * l' * p ^ (r + 2)) + (p : R) ^ (k - 1) * heckeCoeff N k (p ^ (r + 1)) a l' :=
      hT (r + 1) a l'
    rw [hp1, show p * l' * p = p * (p * l') by ring, hT r a (p * l'), h2,
      show p * (p * l') * p ^ (r + 1) = p * l' * p ^ (r + 2) by ring]
    ring
  · rw [hp2 _ _ hl, mul_comm l p, hT r a l, heckeCoeff_pow_of_not_dvd N k hp hpN _ a hl,
      heckeCoeff_pow_of_not_dvd N k hp hpN _ a hl,
      show p * l * p ^ (r + 1) = l * p ^ (r + 2) by ring]

/-- An eigenform has multiplicative coefficients: if `T_n f = λ_n f` for every `n ≥ 1` and
`a_1 = 1`, then `a_(mn) = a_m a_n` for coprime `m, n`, and
`a_(p^(r+2)) = a_p a_(p^(r+1)) - p^(k-1) a_(p^r)` for each prime `p` not dividing `N`. -/
theorem eigenform_coeff_multiplicative {R : Type*} [CommRing R] (N k : ℕ) (a : ℕ → R)
    (lam : ℕ → R) (heig : ∀ n, 0 < n → heckeCoeff N k n a = lam n • a) (h1 : a 1 = 1) :
    (∀ m n, Nat.Coprime m n → a (m * n) = a m * a n) ∧
      (∀ p, p.Prime → ¬ p ∣ N → ∀ r, a (p ^ (r + 2)) =
        a p * a (p ^ (r + 1)) - (p : R) ^ (k - 1) * a (p ^ r)) := by
  have hlam : ∀ n, 0 < n → lam n = a n := by
    intro n hn
    have h := congrFun (heig n hn) 1
    rw [heckeCoeff_at_one, Pi.smul_apply, smul_eq_mul, h1, mul_one] at h
    exact h.symm
  have hval : ∀ n, 0 < n → ∀ l, heckeCoeff N k n a l = a n * a l := by
    intro n hn l
    rw [heig n hn, Pi.smul_apply, smul_eq_mul, hlam n hn]
  refine ⟨fun m n hmn => ?_, fun p hp hpN r => ?_⟩
  · rcases Nat.eq_zero_or_pos n with rfl | hn
    · have : m = 1 := by simpa using hmn
      subst this
      simp [h1]
    rw [← heckeCoeff_at_one N k (m * n) a, ← hecke_mul_of_coprime N k hmn a,
      heckeCoeff_at_one, hval n hn]
    ring
  · have h := congrFun (hecke_prime_pow_rule N k hp hpN r a) 1
    simp only [Pi.add_apply, Pi.smul_apply, smul_eq_mul, heckeCoeff_at_one] at h
    rw [hval _ (pow_pos hp.pos _)] at h
    linear_combination -h

/-! ### The card's worked numbers, computed exactly -/

/-- Multiply a truncated series (a list of coefficients) by `1 - q^n`. -/
def mulOneSub (n : ℕ) (P : List ℤ) : List ℤ :=
  (List.range P.length).map fun i => P.getD i 0 - if n ≤ i then P.getD (i - n) 0 else 0

/-- The coefficients of `q ∏ (1 - q^(c j))^e` over the given pairs `(c, e)`, for `q^0` to `q^L`. -/
def etaProduct (L : ℕ) (parts : List (ℕ × ℕ)) : List ℤ :=
  0 :: parts.foldl (fun P ce => (List.range L).foldl
    (fun Q j => (List.range ce.2).foldl (fun S _ => mulOneSub (ce.1 * (j + 1)) S) Q) P)
    (1 :: List.replicate (L - 1) 0)

/-- Ramanujan's `τ(0..6)`, the coefficients of `Δ = q ∏ (1 - q^n)^24`. -/
example : etaProduct 6 [(1, 24)] = [0, 1, -24, 252, -1472, 4830, -6048] := by decide +kernel

/-- `τ(6) = τ(2) τ(3)` and `τ(4) = τ(2)² - 2^11`. -/
example : (-6048 : ℤ) = (-24) * 252 ∧ (-1472 : ℤ) = (-24) ^ 2 - 2 ^ 11 := by norm_num

/-- `T_2 Δ = -24 Δ` on the coefficients `q^1` to `q^3`, from the coefficient formula. -/
example : (List.range 3).map (fun m => heckeCoeff 1 12 2
    (fun i => (etaProduct 6 [(1, 24)]).getD i 0) (m + 1)) = [-24, 576, -6048] := by decide +kernel

/-- Level 11: `η(z)² η(11z)² = q - 2q² - q³ + 2q⁴ + q⁵ + 2q⁶ - 2q⁷ + 0q⁸ - 2q⁹ + ⋯`. -/
example : etaProduct 9 [(1, 2), (11, 2)] = [0, 1, -2, -1, 2, 1, 2, -2, 0, -2] := by decide +kernel

/-- Level 11: `a_6 = a_2 a_3 = 2`, `a_4 = a_2² - 2 = 2`, `a_9 = a_3² - 3 = -2`. -/
example : (2 : ℤ) = (-2) * (-1) ∧ (2 : ℤ) = (-2) ^ 2 - 2 ∧ (-2 : ℤ) = (-1) ^ 2 - 3 := by norm_num

#print axioms heckeCoeff_one
#print axioms heckeCoeff_at_one
#print axioms heckeCoeff_of_gcd_eq_pow
#print axioms heckeCoeff_pow_succ_mul
#print axioms heckeCoeff_pow_of_not_dvd
#print axioms hecke_mul_of_coprime
#print axioms hecke_prime_pow_rule
#print axioms eigenform_coeff_multiplicative
