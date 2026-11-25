-- The Hilbert-Smith conjecture: the p-adic integers have small subgroups, each ball of radius 1/p^n round 0 is exactly the multiples of p^n, and no continuous homomorphism from the p-adic integers to the circle is one-to-one; the conjecture itself is open and not stated as proved.
import Mathlib.NumberTheory.Padics.PadicIntegers
import Mathlib.Topology.Instances.AddCircle.Real
import Mathlib.Analysis.Normed.Group.AddCircle
import Mathlib.NumberTheory.Padics.PadicVal.Basic
import Mathlib.NumberTheory.Divisors
import Mathlib.Tactic.NormNum.Prime
import Mathlib.Tactic.Simproc.Divisors

open Topology

/-- The circle has no small subgroups: if every whole-number multiple of a point of the circle
stays within a quarter turn of 0, the point is 0. -/
theorem addCircle_one_no_small_subgroups (x : AddCircle (1 : ℝ))
    (h : ∀ k : ℕ, ‖k • x‖ < 1 / 4) : x = 0 := by
  obtain ⟨s, rfl⟩ := QuotientAddGroup.mk_surjective x
  set t : ℝ := s - round s with ht_def
  have hts : (t : AddCircle (1 : ℝ)) = (s : AddCircle (1 : ℝ)) := by
    rw [ht_def, AddCircle.coe_sub, sub_eq_self, AddCircle.coe_eq_zero_iff]
    exact ⟨round s, by simp⟩
  have hnorm : ∀ k : ℕ, |(k : ℝ) * t| ≤ 1 / 2 →
      ‖k • (s : AddCircle (1 : ℝ))‖ = |(k : ℝ) * t| := by
    intro k hk
    rw [← hts, ← AddCircle.coe_nsmul, nsmul_eq_mul]
    exact (AddCircle.norm_coe_eq_abs_iff (p := (1 : ℝ)) one_ne_zero).mpr (by simpa using hk)
  have ht_half : |t| ≤ 1 / 2 := abs_sub_round s
  have ht1 : |t| < 1 / 4 := by
    have h1 := h 1
    rw [hnorm 1 (by simpa using ht_half)] at h1
    simpa using h1
  by_contra hx
  have htpos : 0 < |t| := by
    rw [abs_pos]
    intro h0
    apply hx
    rw [← hts, h0]
    rfl
  set k := ⌈1 / (4 * |t|)⌉₊ with hk_def
  have hk1 : 1 / 4 ≤ (k : ℝ) * |t| := by
    have hc := Nat.le_ceil (1 / (4 * |t|))
    calc (1 : ℝ) / 4 = (1 / (4 * |t|)) * |t| := by field_simp
      _ ≤ (k : ℝ) * |t| := mul_le_mul_of_nonneg_right hc htpos.le
  have hk2 : (k : ℝ) * |t| < 1 / 2 := by
    have hc := Nat.ceil_lt_add_one (show (0 : ℝ) ≤ 1 / (4 * |t|) by positivity)
    calc (k : ℝ) * |t| < (1 / (4 * |t|) + 1) * |t| := mul_lt_mul_of_pos_right hc htpos
      _ = 1 / 4 + |t| := by field_simp
      _ < 1 / 2 := by linarith
  have hk := h k
  rw [hnorm k (by rw [abs_mul, Nat.abs_cast]; linarith), abs_mul, Nat.abs_cast] at hk
  linarith

#print axioms addCircle_one_no_small_subgroups

/-- The p-adic integers have small subgroups: for every prime p, every neighbourhood of 0 in
the p-adic integers contains a whole additive subgroup other than {0}. -/
theorem padicInt_has_small_subgroups (p : ℕ) [Fact p.Prime] (U : Set ℤ_[p])
    (hU : U ∈ 𝓝 (0 : ℤ_[p])) :
    ∃ H : AddSubgroup ℤ_[p], H ≠ ⊥ ∧ (H : Set ℤ_[p]) ⊆ U := by
  obtain ⟨ε, hε, hball⟩ := Metric.mem_nhds_iff.mp hU
  obtain ⟨n, hn⟩ := PadicInt.exists_pow_neg_lt p hε
  have hp0 : (p : ℤ_[p]) ^ n ≠ 0 :=
    pow_ne_zero n (Nat.cast_ne_zero.mpr (Fact.out : p.Prime).ne_zero)
  refine ⟨AddSubgroup.zmultiples ((p : ℤ_[p]) ^ n), ?_, ?_⟩
  · intro h
    have hmem := AddSubgroup.mem_zmultiples ((p : ℤ_[p]) ^ n)
    rw [h, AddSubgroup.mem_bot] at hmem
    exact hp0 hmem
  · rintro x ⟨k, rfl⟩
    apply hball
    rw [Metric.mem_ball, dist_zero_right]
    show ‖k • (p : ℤ_[p]) ^ n‖ < ε
    rw [zsmul_eq_mul, norm_mul, PadicInt.norm_p_pow]
    calc ‖((k : ℤ) : ℤ_[p])‖ * (p : ℝ) ^ (-(n : ℤ)) ≤ 1 * (p : ℝ) ^ (-(n : ℤ)) :=
          mul_le_mul_of_nonneg_right (PadicInt.norm_le_one _) (zpow_nonneg (Nat.cast_nonneg _) _)
      _ < ε := by rwa [one_mul]

/-- The ball of radius 1/p^n round 0 is a subgroup: the p-adic integers of size at most 1/p^n
are exactly the multiples of p^n. -/
theorem padicInt_closedBall_eq_multiples (p : ℕ) [Fact p.Prime] (n : ℕ) :
    Metric.closedBall (0 : ℤ_[p]) ((p : ℝ) ^ (-(n : ℤ))) = {x : ℤ_[p] | (p : ℤ_[p]) ^ n ∣ x} := by
  ext x
  rw [Metric.mem_closedBall, dist_zero_right, Set.mem_ofPred_eq,
    PadicInt.norm_le_pow_iff_mem_span_pow, Ideal.mem_span_singleton]

/-- The p-adic integers never sit inside the circle: no continuous homomorphism from the
p-adic integers to the circle's turns (the reals modulo 1) is one-to-one. -/
theorem padicInt_to_circle_not_injective (p : ℕ) [Fact p.Prime]
    (f : ℤ_[p] →+ AddCircle (1 : ℝ)) (hf : Continuous f) :
    ¬ Function.Injective f := by
  intro hinj
  have hV : f ⁻¹' {y | ‖y‖ < 1 / 4} ∈ 𝓝 (0 : ℤ_[p]) := by
    apply hf.continuousAt.preimage_mem_nhds
    rw [map_zero]
    exact (isOpen_lt continuous_norm continuous_const).mem_nhds (by norm_num)
  obtain ⟨H, hH, hHV⟩ := padicInt_has_small_subgroups p _ hV
  obtain ⟨h, hh, hne⟩ := (AddSubgroup.bot_or_exists_ne_zero H).resolve_left hH
  have hfh : f h = 0 := addCircle_one_no_small_subgroups (f h) (fun k => by
    have hk := hHV (H.nsmul_mem hh k)
    rw [Set.mem_preimage, map_nsmul] at hk
    exact hk)
  exact hne (hinj (hfh.trans (map_zero f).symm))

-- 1/2 is ...111112 in base 3: 2 × 365 = 730 = 1 + 729, and 729 = 3^6.
example : 2 * 365 = 1 + 729 ∧ (3 : ℕ) ^ 6 = 729 := by norm_num

-- 3-adic sizes: 81 and 162 are each divisible by exactly four 3s, so each has size 1/81.
example : padicValNat 3 81 = 4 ∧ padicValNat 3 162 = 4 := by
  constructor
  · rw [show (81 : ℕ) = 3 ^ 4 by norm_num, padicValNat.prime_pow]
  · rw [show (162 : ℕ) = 2 * 3 ^ 4 by norm_num, padicValNat.mul (by norm_num) (by norm_num),
      padicValNat.prime_pow, padicValNat_primes (by norm_num)]

-- Cantor row 3: 27 pieces, each 1/125 long.
example : (3 : ℕ) ^ 3 = 27 ∧ (5 : ℕ) ^ 3 = 125 := by norm_num

-- The model Z/729 has 7 subgroups, one per divisor of 729: 1, 3, 9, 27, 81, 243, 729.
example : Nat.divisors 729 = {1, 3, 9, 27, 81, 243, 729} := by
  simp [Nat.divisors_ofNat]

-- The ball of radius 1/81 in the model: 9 of the 729 points are multiples of 81.
example : ((Finset.range 729).filter (fun x => 81 ∣ x)).card = 9 := by decide +kernel

-- Dropping "faithful": 27 of the 729 points are multiples of 27 and act as no turn.
example : ((Finset.range 729).filter (fun x => 27 ∣ x)).card = 27 := by decide +kernel

-- The order of 81 in Z/3^6, Z/3^7, Z/3^8 is 9, 27, 81.
example : 9 * 81 = 3 ^ 6 ∧ ∀ k < 9, 0 < k → ¬ 3 ^ 6 ∣ 81 * k := by
  decide +kernel
example : 27 * 81 = 3 ^ 7 ∧ ∀ k < 27, 0 < k → ¬ 3 ^ 7 ∣ 81 * k := by
  decide +kernel
example : 81 * 81 = 3 ^ 8 ∧ ∀ k < 81, 0 < k → ¬ 3 ^ 8 ∣ 81 * k := by
  decide +kernel

-- Escaping the quarter-turn ball of 9000 hundredths of a degree: 1 degree (100 hundredths)
-- after 90 steps, 0.01 degrees (1 hundredth) after 9,000 steps (9000 ÷ angle, rounded up).
example : (9000 + 100 - 1) / 100 = 90 ∧ (9000 + 1 - 1) / 1 = 9000 := by norm_num

-- Homomorphisms x ↦ jx/729 of a turn against subgroups 3^n Z: 1,093 pairs (j, n) with
-- j < 729 and n ≤ 6 send the subgroup to 0.
example : ((Finset.range 729 ×ˢ Finset.range 7).filter
    (fun q : ℕ × ℕ => 729 ∣ q.1 * 3 ^ q.2)).card = 1093 := by decide +kernel

#print axioms padicInt_has_small_subgroups
#print axioms padicInt_closedBall_eq_multiples
#print axioms padicInt_to_circle_not_injective
