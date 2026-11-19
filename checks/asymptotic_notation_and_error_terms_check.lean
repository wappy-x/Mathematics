-- Big O and twiddle: the harmonic sum H(n) = 1 + 1/2 + … + 1/n overshoots log n + γ by more than 0 and less than 1/(2n) at every whole n ≥ 1, it climbs the four-level ladder H ~ log x, H − log x = O(1), H − log x − γ = o(1) and = O(1/x), and the divisor sum D(n) lies between n log n − n and n log n + n.
import Mathlib.NumberTheory.Harmonic.EulerMascheroni
import Mathlib.Analysis.Asymptotics.AsymptoticEquivalent
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.PrimeCounting
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.Analysis.SpecialFunctions.Trigonometric.DerivHyp
import Mathlib.Algebra.Order.Floor.Semifield

open Asymptotics Filter Real

theorem log_succ_div_lt_trapezoid (k : ℕ) :
    log (((k : ℝ) + 2) / (k + 1)) < 1 / (2 * ((k : ℝ) + 1)) + 1 / (2 * ((k : ℝ) + 2)) := by
  have hk : (0 : ℝ) < (k : ℝ) + 1 := by positivity
  have hx1 : (1 : ℝ) < ((k : ℝ) + 2) / (k + 1) := by
    rw [lt_div_iff₀ hk]; linarith
  have hpos : 0 < log (((k : ℝ) + 2) / (k + 1)) := log_pos hx1
  have h := Real.self_lt_sinh_iff.2 hpos
  rw [sinh_log (by positivity)] at h
  refine h.trans_le (le_of_eq ?_)
  field_simp
  ring

theorem harmonic_shift_strictMono :
    StrictMono (fun k : ℕ => (harmonic (k + 1) : ℝ) - log ((k : ℝ) + 1) - 1 / (2 * ((k : ℝ) + 1))) := by
  refine strictMono_nat_of_lt_succ (fun k => ?_)
  have h := log_succ_div_lt_trapezoid k
  rw [log_div (by positivity) (by positivity)] at h
  simp only [harmonic_succ (k + 1), Rat.cast_add, Rat.cast_inv, Rat.cast_natCast]
  push_cast
  have e1 : (k : ℝ) + 1 + 1 = k + 2 := by ring
  rw [e1]
  have e2 : ((k + 2 : ℝ))⁻¹ = 1 / (2 * ((k : ℝ) + 2)) + 1 / (2 * ((k : ℝ) + 2)) := by
    field_simp; ring
  rw [e2]
  linarith

theorem harmonic_shift_tendsto :
    Tendsto (fun k : ℕ => (harmonic (k + 1) : ℝ) - log ((k : ℝ) + 1) - 1 / (2 * ((k : ℝ) + 1)))
      atTop (nhds eulerMascheroniConstant) := by
  have h1 := tendsto_harmonic_sub_log.comp (tendsto_add_atTop_nat 1)
  have h2 : Tendsto (fun k : ℕ => 1 / (2 * ((k : ℝ) + 1))) atTop (nhds 0) := by
    have := (tendsto_natCast_atTop_atTop (R := ℝ))
    have h3 : Tendsto (fun k : ℕ => 2 * ((k : ℝ) + 1)) atTop atTop := by
      apply Tendsto.const_mul_atTop (by norm_num)
      exact tendsto_atTop_add_const_right _ 1 this
    refine h3.inv_tendsto_atTop.congr (fun k => ?_)
    simp [one_div]
  have := h1.sub h2
  simp only [sub_zero] at this
  refine this.congr (fun k => ?_)
  simp [Function.comp]

theorem harmonic_shift_lt (k : ℕ) :
    (harmonic (k + 1) : ℝ) - log ((k : ℝ) + 1) - 1 / (2 * ((k : ℝ) + 1)) < eulerMascheroniConstant :=
  (harmonic_shift_strictMono (Nat.lt_succ_self k)).trans_le
    (harmonic_shift_strictMono.monotone.ge_of_tendsto harmonic_shift_tendsto (k + 1))

/-- The harmonic sum with an explicit error term. For every whole number n ≥ 1, the sum
H(n) = 1 + 1/2 + … + 1/n is log n plus Euler's constant γ, always too big, and wrong by less
than one over twice n: 0 < H(n) − log n − γ < 1/(2n). So H(x) = log x + γ + O(1/x) at whole
numbers, with the explicit constant C = 1/2 from x₀ = 1. -/
theorem harmonic_sub_log_sub_eulerMascheroni_bounds (n : ℕ) (hn : 1 ≤ n) :
    0 < (harmonic n : ℝ) - log n - eulerMascheroniConstant ∧
      (harmonic n : ℝ) - log n - eulerMascheroniConstant < 1 / (2 * n) := by
  constructor
  · have h := eulerMascheroniConstant_lt_eulerMascheroniSeq' n
    simp only [eulerMascheroniSeq', show n ≠ 0 by omega, ite_false] at h
    linarith
  · obtain ⟨k, rfl⟩ : ∃ k, n = k + 1 := ⟨n - 1, by omega⟩
    have h := harmonic_shift_lt k
    push_cast
    linarith

theorem harmonic_floor_error_le (x : ℝ) (hx : 2 ≤ x) :
    |(harmonic ⌊x⌋₊ : ℝ) - log x - eulerMascheroniConstant| ≤ 2 * (1 / x) := by
  set m := ⌊x⌋₊ with hm
  have hm2 : 2 ≤ m := by rw [hm]; exact Nat.le_floor (by exact_mod_cast hx)
  have hmx : (m : ℝ) ≤ x := Nat.floor_le (by linarith)
  have hxm : x < (m : ℝ) + 1 := Nat.lt_floor_add_one x
  have hm2r : (2 : ℝ) ≤ m := by exact_mod_cast hm2
  have hmpos : (0 : ℝ) < m := by linarith
  obtain ⟨he1, he2⟩ := harmonic_sub_log_sub_eulerMascheroni_bounds m (by omega)
  have hd0 : 0 ≤ log x - log m := sub_nonneg.2 (log_le_log hmpos hmx)
  have hd1 : log x - log m ≤ 1 / m := by
    rw [← log_div (by linarith) hmpos.ne']
    have := log_le_sub_one_of_pos (x := x / m) (by positivity)
    have h2 : x / m - 1 ≤ 1 / m := by
      rw [div_sub_one hmpos.ne', div_le_div_iff_of_pos_right hmpos]; linarith
    linarith
  have hmx2 : 1 / (m : ℝ) ≤ 2 * (1 / x) := by
    rw [mul_one_div, div_le_div_iff₀ hmpos (by linarith)]; linarith
  have h2m : 1 / (2 * (m : ℝ)) ≤ 1 / m := by
    apply one_div_le_one_div_of_le hmpos; linarith
  rw [abs_le]
  constructor <;> linarith

/-- The four-level ladder for the harmonic sum H(x) = ∑_{n ≤ x} 1/n, as the real size x grows
without limit:
1. twiddle: H(x) ~ log x, the ratio tends to 1;
2. big O: H(x) − log x = O(1), the difference stays bounded;
3. little o: H(x) − log x − γ = o(1), the difference settles on Euler's constant γ;
4. the error term: H(x) − log x − γ = O(1/x), what is left shrinks like 1 over the size. -/
theorem harmonic_asymptotic_ladder :
    (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ)) ~[atTop] (fun x => log x) ∧
      (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ) - log x) =O[atTop] (fun _ => (1 : ℝ)) ∧
      (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ) - log x - eulerMascheroniConstant)
        =o[atTop] (fun _ => (1 : ℝ)) ∧
      (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ) - log x - eulerMascheroniConstant)
        =O[atTop] (fun x => 1 / x) := by
  have h4 : (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ) - log x - eulerMascheroniConstant)
      =O[atTop] (fun x => 1 / x) := by
    refine IsBigO.of_bound 2 ?_
    filter_upwards [eventually_ge_atTop (2 : ℝ)] with x hx
    rw [Real.norm_eq_abs, Real.norm_eq_abs, abs_of_pos (by positivity : (0 : ℝ) < 1 / x)]
    exact harmonic_floor_error_le x hx
  have hinv : (fun x : ℝ => 1 / x) =o[atTop] (fun _ => (1 : ℝ)) := by
    rw [isLittleO_one_iff]
    simpa [one_div] using tendsto_inv_atTop_zero
  have h3 := h4.trans_isLittleO hinv
  have h2 : (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ) - log x) =O[atTop] (fun _ => (1 : ℝ)) := by
    have := h3.isBigO.add (isBigO_const_const eulerMascheroniConstant (one_ne_zero) atTop)
    refine this.congr_left (fun x => ?_)
    ring
  have h1 : (fun x : ℝ => (harmonic ⌊x⌋₊ : ℝ)) ~[atTop] (fun x => log x) :=
    h2.trans_isLittleO isLittleO_const_log_atTop
  exact ⟨h1, h2, h3, h4⟩

theorem sum_card_divisors_eq_sum_div (n : ℕ) :
    ∑ k ∈ Finset.Icc 1 n, (Nat.divisors k).card = ∑ d ∈ Finset.Icc 1 n, n / d := by
  have h1 : ∀ k ∈ Finset.Icc 1 n,
      (Nat.divisors k).card = ∑ d ∈ Finset.Icc 1 n, if d ∣ k then 1 else 0 := by
    intro k hk
    rw [Finset.mem_Icc] at hk
    rw [← Finset.card_filter]
    congr 1
    ext d
    simp only [Nat.mem_divisors, Finset.mem_filter, Finset.mem_Icc]
    constructor
    · rintro ⟨hd, hk0⟩
      exact ⟨⟨Nat.pos_of_dvd_of_pos hd (by omega), (Nat.le_of_dvd (by omega) hd).trans hk.2⟩, hd⟩
    · rintro ⟨_, hd⟩
      exact ⟨hd, by omega⟩
  rw [Finset.sum_congr rfl h1, Finset.sum_comm]
  refine Finset.sum_congr rfl (fun d _ => ?_)
  rw [← Finset.card_filter, ← Nat.Ioc_filter_dvd_card_eq_div]
  congr 2

/-- The divisor sum with an explicit O(x) error. Let τ(k) be the number of divisors of k and
D(n) = τ(1) + τ(2) + … + τ(n) their running total. For every whole number n ≥ 1,
n log n − n < D(n) ≤ n log n + n, so D(x) = x log x + O(x) with constant 1. -/
theorem divisor_sum_sandwich (n : ℕ) (hn : 1 ≤ n) :
    (n : ℝ) * log n - n < ((∑ k ∈ Finset.Icc 1 n, (Nat.divisors k).card : ℕ) : ℝ) ∧
      ((∑ k ∈ Finset.Icc 1 n, (Nat.divisors k).card : ℕ) : ℝ) ≤ (n : ℝ) * log n + n := by
  rw [sum_card_divisors_eq_sum_div, Nat.cast_sum]
  have hH : (harmonic n : ℝ) = ∑ d ∈ Finset.Icc 1 n, (1 / (d : ℝ)) := by
    simp [harmonic_eq_sum_Icc]
  have hnH : ∑ d ∈ Finset.Icc 1 n, ((n : ℝ) / d) = n * harmonic n := by
    rw [hH, Finset.mul_sum]
    refine Finset.sum_congr rfl (fun d _ => ?_)
    ring
  have hnpos : (0 : ℝ) < n := by exact_mod_cast hn
  have hfl : ∀ d : ℕ, (((n / d : ℕ)) : ℝ) = (⌊(n : ℝ) / d⌋₊ : ℝ) := by
    intro d; rw [Nat.floor_div_eq_div]
  constructor
  · have hlow : ∑ d ∈ Finset.Icc 1 n, ((n : ℝ) / d - 1) < ∑ d ∈ Finset.Icc 1 n, (((n / d : ℕ)) : ℝ) := by
      apply Finset.sum_lt_sum_of_nonempty ⟨1, by simp [hn]⟩
      intro d _
      rw [hfl d]
      linarith [Nat.lt_floor_add_one ((n : ℝ) / d)]
    rw [Finset.sum_sub_distrib, hnH] at hlow
    simp only [Finset.sum_const, Nat.card_Icc, add_tsub_cancel_right, nsmul_eq_mul, mul_one] at hlow
    have h1 := log_add_one_le_harmonic n
    have h2 : log n < log ((n + 1 : ℕ) : ℝ) := by
      apply log_lt_log hnpos; push_cast; linarith
    nlinarith
  · have hup : ∑ d ∈ Finset.Icc 1 n, (((n / d : ℕ)) : ℝ) ≤ ∑ d ∈ Finset.Icc 1 n, ((n : ℝ) / d) := by
      apply Finset.sum_le_sum
      intro d _
      exact Nat.cast_div_le
    rw [hnH] at hup
    have h1 := harmonic_le_one_add_log n
    nlinarith

-- τ(720720) = 240: 720720 = 2^4 · 3^2 · 5 · 7 · 11 · 13, the largest divisor count up to a million.
example : (2 : ℕ) ^ 4 * 3 ^ 2 * 5 * 7 * 11 * 13 = 720720 := by norm_num
example : (Nat.divisors 720720).card = 240 := by
  rw [show 720720 = 16 * (9 * (5 * (7 * (11 * 13)))) by norm_num,
    Nat.Coprime.card_divisors_mul (by decide), Nat.Coprime.card_divisors_mul (by decide),
    Nat.Coprime.card_divisors_mul (by decide), Nat.Coprime.card_divisors_mul (by decide),
    Nat.Coprime.card_divisors_mul (by decide)]
  decide

-- The Rosser–Schoenfeld bound starts at x = 59; at x = 58 the prime count is π(58) = 16.
example : Nat.primeCounting 58 = 16 := by
  simp [Nat.primeCounting, Nat.primeCounting', Nat.count_eq_card_filter_range]
  decide

#print axioms harmonic_sub_log_sub_eulerMascheroni_bounds
#print axioms harmonic_asymptotic_ladder
#print axioms divisor_sum_sandwich
#print axioms log_succ_div_lt_trapezoid
#print axioms harmonic_shift_strictMono
#print axioms harmonic_shift_tendsto
#print axioms harmonic_shift_lt
#print axioms harmonic_floor_error_le
#print axioms sum_card_divisors_eq_sum_div
