-- Shor and Grover: an even period whose halfway power is not N - 1 splits N, a comb of period r gives r equal QFT peaks, and each Grover round turns the key's amplitude by a fixed angle.
import Mathlib.Data.ZMod.Basic
import Mathlib.GroupTheory.OrderOfElement
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Inverse
import Mathlib.Analysis.SpecialFunctions.Complex.Circle
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.RingTheory.RootsOfUnity.Complex

open Finset

/-- If 2 ≤ h ≤ N - 2 and N divides (h - 1)(h + 1), then gcd(h - 1, N) and gcd(h + 1, N) are
proper factors of N. -/
lemma split_of_sq_one (N h : ℕ) (h2 : 2 ≤ h) (hN : h + 2 ≤ N)
    (hdvd : N ∣ (h - 1) * (h + 1)) :
    1 < Nat.gcd (h - 1) N ∧ Nat.gcd (h - 1) N < N ∧
      1 < Nat.gcd (h + 1) N ∧ Nat.gcd (h + 1) N < N := by
  have hN0 : 0 < N := by omega
  refine ⟨?_, ?_, ?_, ?_⟩
  · have hpos : 0 < Nat.gcd (h - 1) N := Nat.gcd_pos_of_pos_right _ hN0
    by_contra hc
    have h1 : Nat.Coprime (h - 1) N := by unfold Nat.Coprime; omega
    have : N ∣ h + 1 := h1.symm.dvd_of_dvd_mul_left hdvd
    have := Nat.le_of_dvd (by omega) this
    omega
  · exact lt_of_le_of_lt (Nat.gcd_le_left _ (by omega)) (by omega)
  · have hpos : 0 < Nat.gcd (h + 1) N := Nat.gcd_pos_of_pos_right _ hN0
    by_contra hc
    have h1 : Nat.Coprime (h + 1) N := by unfold Nat.Coprime; omega
    have : N ∣ h - 1 := h1.symm.dvd_of_dvd_mul_right hdvd
    have := Nat.le_of_dvd (by omega) this
    omega
  · exact lt_of_le_of_lt (Nat.gcd_le_left _ (by omega)) (by omega)

#print axioms split_of_sq_one

/-- Shor's classical step. Let a share no factor with N and let r be the period of a on the
N-clock (Mathlib's `orderOf` of a in `ZMod N`). If r is even and the halfway power
a^(r/2) mod N is not N - 1, then with h = a^(r/2) mod N both gcd(h - 1, N) and gcd(h + 1, N)
are factors of N other than 1 and N. -/
theorem even_period_splits_number (N a r : ℕ) (hcop : Nat.Coprime a N)
    (hr : orderOf (a : ZMod N) = r) (heven : Even r) (hhalf : a ^ (r / 2) % N ≠ N - 1) :
    1 < Nat.gcd (a ^ (r / 2) % N - 1) N ∧ Nat.gcd (a ^ (r / 2) % N - 1) N < N ∧
      1 < Nat.gcd (a ^ (r / 2) % N + 1) N ∧ Nat.gcd (a ^ (r / 2) % N + 1) N < N := by
  rcases Nat.lt_or_ge N 2 with hN | hN
  · exfalso
    obtain rfl | rfl : N = 0 ∨ N = 1 := by omega
    · have ha : a = 1 := Nat.coprime_zero_right _ |>.mp hcop
      subst ha
      simp at hr
      subst hr
      exact (Nat.not_even_one) heven
    · have : orderOf (a : ZMod 1) = 1 := orderOf_eq_one_iff.mpr (Subsingleton.elim _ _)
      rw [this] at hr
      subst hr
      exact (Nat.not_even_one) heven
  have : NeZero N := ⟨by omega⟩
  have hunit : orderOf (a : ZMod N) = orderOf (ZMod.unitOfCoprime a hcop) := by
    rw [← orderOf_units, ZMod.coe_unitOfCoprime]
  have hrpos : 0 < r := by rw [← hr, hunit]; exact orderOf_pos _
  obtain ⟨m, hm⟩ := heven
  have hr2 : r / 2 = m := by omega
  rw [hr2] at hhalf ⊢
  have hm0 : m ≠ 0 := by omega
  have hmr : m < orderOf (a : ZMod N) := by omega
  have hne : (a : ZMod N) ^ m ≠ 1 := pow_ne_one_of_lt_orderOf hm0 hmr
  have hsq : ((a : ZMod N) ^ m) ^ 2 = 1 := by
    rw [← pow_mul, show m * 2 = r by omega, ← hr]; exact pow_orderOf_eq_one _
  generalize hh : a ^ m % N = h at hhalf ⊢
  have hcast : (h : ZMod N) = (a : ZMod N) ^ m := by
    rw [← hh, ZMod.natCast_mod]; push_cast; rfl
  have hlt : h < N := by rw [← hh]; exact Nat.mod_lt _ (by omega)
  have hsqN : ((h ^ 2 : ℕ) : ZMod N) = ((1 : ℕ) : ZMod N) := by
    push_cast; rw [hcast]; exact hsq
  rw [ZMod.natCast_eq_natCast_iff', Nat.one_mod_eq_one.mpr (by omega)] at hsqN
  have h0 : h ≠ 0 := by
    rintro rfl; simp at hsqN
  have h1 : h ≠ 1 := by
    rintro rfl; apply hne; rw [← hcast, Nat.cast_one]
  have hdvd : N ∣ (h - 1) * (h + 1) := by
    have : (h - 1) * (h + 1) = h ^ 2 - 1 := by
      obtain ⟨g, rfl⟩ : ∃ g, h = g + 1 := ⟨h - 1, by omega⟩
      simp only [Nat.add_sub_cancel]; ring_nf; omega
    rw [this]
    exact (Nat.modEq_iff_dvd' (Nat.one_le_pow _ _ (by omega))).mp (by
      unfold Nat.ModEq; rw [hsqN, Nat.one_mod_eq_one.mpr (by omega)])
  exact split_of_sq_one N h (by omega) (by omega) hdvd

/-- The QFT peaks. Take a counting register of Q = 2^t values and a period r dividing Q, so each
comb x₀, x₀ + r, x₀ + 2r, ... holds L = Q/r teeth, each of amplitude 1/√Q. After the QFT, the
r combs together give the outcome y probability 1/r when y is a multiple of Q/r, and 0
otherwise. -/
theorem comb_qft_peaks (t r y : ℕ) (hr : 0 < r) (hdiv : r ∣ 2 ^ t) :
    ∑ x₀ ∈ range r,
        ‖(1 / (2 ^ t : ℂ)) * ∑ j ∈ range (2 ^ t / r),
            Complex.exp (2 * Real.pi * Complex.I * (((x₀ + j * r : ℕ) : ℂ) * y) / 2 ^ t)‖ ^ 2 =
      if 2 ^ t / r ∣ y then 1 / (r : ℝ) else 0 := by
  generalize hL : 2 ^ t / r = L
  have hQ : 2 ^ t = r * L := by rw [← hL]; exact (Nat.mul_div_cancel' hdiv).symm
  have hLpos : 0 < L := by
    rcases Nat.eq_zero_or_pos L with h | h
    · rw [h, mul_zero] at hQ; exact absurd hQ (by positivity)
    · exact h
  have hQC : (2 : ℂ) ^ t = (r : ℂ) * (L : ℂ) := by exact_mod_cast hQ
  have hrC : (r : ℂ) ≠ 0 := by exact_mod_cast hr.ne'
  have hLC : (L : ℂ) ≠ 0 := by exact_mod_cast hLpos.ne'
  set ζ := Complex.exp (2 * Real.pi * Complex.I / L) with hζ
  have hprim : IsPrimitiveRoot ζ L := Complex.isPrimitiveRoot_exp L hLpos.ne'
  have hterm : ∀ x₀ j : ℕ,
      Complex.exp (2 * Real.pi * Complex.I * (((x₀ + j * r : ℕ) : ℂ) * y) / 2 ^ t) =
        Complex.exp (2 * Real.pi * Complex.I * ((x₀ : ℂ) * y) / 2 ^ t) * (ζ ^ y) ^ j := by
    intro x₀ j
    rw [← pow_mul, hζ, ← Complex.exp_nat_mul, ← Complex.exp_add]
    congr 1
    rw [hQC]
    push_cast
    field_simp
  have hnorm : ∀ x₀ : ℕ, ‖Complex.exp (2 * Real.pi * Complex.I * ((x₀ : ℂ) * y) / 2 ^ t)‖ = 1 := by
    intro x₀
    have : 2 * Real.pi * Complex.I * ((x₀ : ℂ) * y) / 2 ^ t =
        ((2 * Real.pi * x₀ * y / 2 ^ t : ℝ) : ℂ) * Complex.I := by
      push_cast; ring
    rw [this, Complex.norm_exp_ofReal_mul_I]
  have hinner : ∀ x₀ : ℕ,
      ‖(1 / (2 ^ t : ℂ)) * ∑ j ∈ range L,
          Complex.exp (2 * Real.pi * Complex.I * (((x₀ + j * r : ℕ) : ℂ) * y) / 2 ^ t)‖ =
        ‖∑ j ∈ range L, (ζ ^ y) ^ j‖ / 2 ^ t := by
    intro x₀
    simp_rw [hterm]
    rw [← mul_sum, norm_mul, norm_mul, hnorm, norm_div, norm_one, norm_pow]
    simp
    ring
  simp_rw [hinner]
  have hQR : (2 : ℝ) ^ t = (r : ℝ) * (L : ℝ) := by exact_mod_cast hQ
  have hrR : (r : ℝ) ≠ 0 := by exact_mod_cast hr.ne'
  have hLR : (L : ℝ) ≠ 0 := by exact_mod_cast hLpos.ne'
  split_ifs with hy
  · have h1 : ζ ^ y = 1 := (hprim.pow_eq_one_iff_dvd y).mpr hy
    rw [h1]
    simp only [one_pow, sum_const, card_range, nsmul_eq_mul, mul_one, Complex.norm_natCast]
    rw [hQR]
    field_simp
  · have h1 : ζ ^ y ≠ 1 := fun h => hy ((hprim.pow_eq_one_iff_dvd y).mp h)
    have h2 : (ζ ^ y) ^ L = 1 := by
      rw [← pow_mul, mul_comm, pow_mul, hprim.pow_eq_one, one_pow]
    rw [geom_sum_eq h1, h2]
    simp

lemma grover_sum_update {M : ℕ} (v : Fin M → ℝ) (key : Fin M) :
    ∑ j, Function.update v key (-v key) j = ∑ j, v j - 2 * v key := by
  rw [Finset.sum_update_of_mem (Finset.mem_univ _), Finset.sdiff_singleton_eq_erase,
    ← Finset.add_sum_erase _ _ (Finset.mem_univ key)]
  ring

#print axioms grover_sum_update

lemma grover_step_key {M : ℕ} (v : Fin M → ℝ) (key : Fin M) :
    (fun i => 2 * (∑ j, Function.update v key (-v key) j) / M - Function.update v key (-v key) i)
      key = 2 * (∑ j, v j - 2 * v key) / M + v key := by
  simp only [grover_sum_update, Function.update_self]
  ring

#print axioms grover_step_key

lemma grover_step_sum {M : ℕ} (v : Fin M → ℝ) (key : Fin M) :
    ∑ i, (fun i => 2 * (∑ j, Function.update v key (-v key) j) / M
      - Function.update v key (-v key) i) i = ∑ j, v j - 2 * v key := by
  have hM : (M : ℝ) ≠ 0 := by
    have : 0 < M := Fin.pos key
    exact_mod_cast this.ne'
  simp only
  rw [Finset.sum_sub_distrib, grover_sum_update, Finset.sum_const, Finset.card_univ,
    Fintype.card_fin, nsmul_eq_mul]
  field_simp
  ring

#print axioms grover_step_sum

/-- Grover's angle law. Search M items with exactly one key. Start every amplitude at 1/√M; one
round flips the sign of the key's amplitude (the oracle), then replaces every amplitude by twice
the mean minus itself (diffusion). After k rounds the key's amplitude is sin((2k + 1)θ), where
sin θ = 1/√M, so the chance of measuring the key is sin²((2k + 1)θ). -/
theorem grover_key_amplitude (M : ℕ) (key : Fin M) (k : ℕ) :
    ((fun v : Fin M → ℝ => fun i =>
        2 * (∑ j, Function.update v key (-v key) j) / M - Function.update v key (-v key) i)^[k]
      (fun _ => 1 / Real.sqrt M)) key =
      Real.sin ((2 * k + 1) * Real.arcsin (1 / Real.sqrt M)) := by
  set G := (fun v : Fin M → ℝ => fun i =>
        2 * (∑ j, Function.update v key (-v key) j) / M - Function.update v key (-v key) i)
  have hMpos : 0 < M := Fin.pos key
  have hM1 : (1 : ℝ) ≤ M := by exact_mod_cast hMpos
  set m := Real.sqrt M with hm
  have hm0 : 0 < m := Real.sqrt_pos.mpr (by linarith)
  have hmm : m ^ 2 = M := Real.sq_sqrt (by linarith)
  set θ := Real.arcsin (1 / m)
  have hle : 1 / m ≤ 1 := by
    rw [div_le_one hm0]; rw [hm]; exact Real.one_le_sqrt.mpr hM1
  have hs : Real.sin θ = 1 / m := Real.sin_arcsin (by
    have : 0 ≤ 1 / m := by positivity
    linarith) hle
  set co := Real.cos θ
  have hco : Real.sin θ ^ 2 + co ^ 2 = 1 := Real.sin_sq_add_cos_sq θ
  rw [hs] at hco
  have key_claim : ∀ k : ℕ, (G^[k] (fun _ => 1 / m)) key = Real.sin ((2 * k + 1) * θ) ∧
      ∑ j, (G^[k] (fun _ => 1 / m)) j - (G^[k] (fun _ => 1 / m)) key =
        m * co * Real.cos ((2 * k + 1) * θ) := by
    intro k
    induction k with
    | zero =>
      simp only [Function.iterate_zero, id, Nat.cast_zero, mul_zero, zero_add, one_mul]
      refine ⟨hs.symm, ?_⟩
      rw [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
      rw [← hmm]
      field_simp
      field_simp at hco
      nlinarith [hco]
    | succ n ih =>
      obtain ⟨h1, h2⟩ := ih
      rw [Function.iterate_succ_apply']
      generalize G^[n] (fun _ => 1 / m) = w at *
      have hk : G w key = 2 * (∑ j, w j - 2 * w key) / M + w key := grover_step_key w key
      have hsum : ∑ i, G w i = ∑ j, w j - 2 * w key := grover_step_sum w key
      have e1 : (2 * ((n + 1 : ℕ) : ℝ) + 1) * θ = (2 * n + 1) * θ + 2 * θ := by push_cast; ring
      rw [e1, Real.sin_add, Real.cos_add, Real.sin_two_mul, Real.cos_two_mul, hs]
      have hR : ∑ j, w j = m * co * Real.cos ((2 * n + 1) * θ) + Real.sin ((2 * n + 1) * θ) := by
        linarith
      have hco' : co ^ 2 * m ^ 2 = m ^ 2 - 1 := by
        field_simp at hco; linarith
      refine ⟨?_, ?_⟩
      · rw [hk, hR, h1, ← hmm]
        field_simp
        linear_combination (-2 * Real.sin ((2 * n + 1) * θ)) * hco'
      · rw [hsum, hk, hR, h1, ← hmm]
        field_simp
        linear_combination (2 * Real.sin ((2 * n + 1) * θ) - 2 * m * co * Real.cos ((2 * n + 1) * θ)) * hco'
  simpa using (key_claim k).1

-- Powers of 7 on the 15-clock: 7, 4, 13, 1, so the period is 4.
example : (List.range 4).map (fun e => 7 ^ (e + 1) % 15) = [7, 4, 13, 1] := by decide
example : ∀ s ∈ [1, 2, 3], 7 ^ s % 15 ≠ 1 := by decide
-- Half the period: 7^2 mod 15 = 4, and gcd(3, 15) = 3, gcd(5, 15) = 5, with 3 × 5 = 15.
example : 7 ^ 2 % 15 = 4 := by norm_num
example : Nat.gcd 3 15 = 3 ∧ Nat.gcd 5 15 = 5 ∧ 3 * 5 = 15 := by decide
-- What breaks: a = 14 has period 2, its halfway power is 14 = 15 - 1, and the gcds are 1 and 15.
example : 14 ^ 2 % 15 = 1 ∧ 14 ^ 1 % 15 = 15 - 1 ∧ Nat.gcd 13 15 = 1 ∧ Nat.gcd 15 15 = 15 := by
  decide
-- Reading y = 128 as 1/2 fails the check: 7^2 mod 15 = 4, not 1.
example : 7 ^ 2 % 15 ≠ 1 := by decide
-- QFT peaks for 15: multiples of 256/4 = 64.
example : 256 / 4 = 64 ∧ [0, 64, 128, 192] = (List.range 4).map (· * 64) := by decide
-- N = 21, a = 2: powers 2, 4, 8, 16, 11, 1, so the period is 6; 2^3 mod 21 = 8,
-- gcd(7, 21) = 7 and gcd(9, 21) = 3.
example : (List.range 6).map (fun e => 2 ^ (e + 1) % 21) = [2, 4, 8, 16, 11, 1] := by decide
example : 2 ^ 3 % 21 = 8 ∧ Nat.gcd 7 21 = 7 ∧ Nat.gcd 9 21 = 3 := by decide
-- Try changing: a = 5 on 21 has 5^3 mod 21 = 20 = 21 - 1.
example : 5 ^ 6 % 21 = 1 ∧ 5 ^ 3 % 21 = 21 - 1 := by decide
-- The QFT on 8 qubits: 8 Hadamards and 8 × 7 / 2 = 28 phase gates.
example : 8 * 7 / 2 = 28 := by norm_num

#print axioms even_period_splits_number
#print axioms comb_qft_peaks
#print axioms grover_key_amplitude
