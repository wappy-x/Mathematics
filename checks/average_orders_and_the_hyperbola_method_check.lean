-- Average orders: the divisor counts of 1 to x add to x log x + (2γ − 1)x with an error below 2√x + 5, by Dirichlet's hyperbola count, and the totients of 1 to x add to 3x²/π² with an error at most x log x + 1.5x.
import Mathlib.NumberTheory.Harmonic.EulerMascheroni
import Mathlib.NumberTheory.Divisors
import Mathlib.Data.Nat.Totient
import Mathlib.Analysis.SpecialFunctions.Pow.Real
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.NumberTheory.Harmonic.Bounds
import Mathlib.NumberTheory.ArithmeticFunction.Misc
import Mathlib.NumberTheory.LSeries.Dirichlet
import Mathlib.NumberTheory.LSeries.HurwitzZetaValues
import Mathlib.Analysis.PSeries
import Mathlib.Algebra.Order.Floor.Semifield

open Finset Real

theorem hyperbola_count (x : ℕ) :
    (∑ n ∈ Icc 1 x, (Nat.divisors n).card) + Nat.sqrt x ^ 2
      = 2 * ∑ d ∈ Icc 1 (Nat.sqrt x), x / d := by
  set m := Nat.sqrt x with hm
  have hmx : m * m ≤ x := Nat.sqrt_le x
  have hxm : x < (m + 1) * (m + 1) := Nat.lt_succ_sqrt x
  have hD : ∑ n ∈ Icc 1 x, (Nat.divisors n).card = ∑ a ∈ Icc 1 x, x / a := by
    have := ArithmeticFunction.sum_Ioc_sigma0_eq_sum_div x
    have hI : Icc 1 x = Ioc 0 x := by ext; simp only [mem_Icc, mem_Ioc]; omega
    simpa [ArithmeticFunction.sigma_zero_apply, hI] using this
  have hsplit : ∑ a ∈ Icc 1 x, x / a = ∑ a ∈ Icc 1 m, x / a + ∑ a ∈ Icc (m + 1) x, x / a := by
    have hm1 : m ≤ x := le_trans (Nat.le_mul_self m) hmx
    rw [← Finset.sum_union]
    · congr 1
      ext a; simp only [mem_Icc, mem_union]; omega
    · rw [Finset.disjoint_left]; intro a ha hb; simp only [mem_Icc] at ha hb; omega
  -- double counting
  have hswap : ∑ a ∈ Icc (m + 1) x, ∑ b ∈ Icc 1 m, (if a * b ≤ x then 1 else 0)
      = ∑ b ∈ Icc 1 m, ∑ a ∈ Icc (m + 1) x, (if a * b ≤ x then 1 else 0) := Finset.sum_comm
  have hL : ∀ a ∈ Icc (m + 1) x, ∑ b ∈ Icc 1 m, (if a * b ≤ x then 1 else 0) = x / a := by
    intro a ha
    simp only [mem_Icc] at ha
    rw [Finset.sum_boole]
    have : (Icc 1 m).filter (fun b => a * b ≤ x) = Icc 1 (x / a) := by
      ext b
      simp only [mem_filter, mem_Icc]
      have hle : x / a ≤ m := by
        have : x / a < m + 1 := by
          rw [Nat.div_lt_iff_lt_mul (by omega)]
          nlinarith
        omega
      constructor
      · rintro ⟨⟨h1, _⟩, h3⟩
        exact ⟨h1, (Nat.le_div_iff_mul_le (by omega)).2 (by rw [mul_comm]; exact h3)⟩
      · rintro ⟨h1, h2⟩
        have := (Nat.le_div_iff_mul_le (by omega)).1 h2
        exact ⟨⟨h1, le_trans h2 hle⟩, by rw [mul_comm]; exact this⟩
    rw [this]; simp
  have hR : ∀ b ∈ Icc 1 m, ∑ a ∈ Icc (m + 1) x, (if a * b ≤ x then 1 else 0) = x / b - m := by
    intro b hb
    simp only [mem_Icc] at hb
    rw [Finset.sum_boole]
    have : (Icc (m + 1) x).filter (fun a => a * b ≤ x) = Icc (m + 1) (x / b) := by
      ext a
      simp only [mem_filter, mem_Icc]
      have hle : x / b ≤ x := Nat.div_le_self x b
      constructor
      · rintro ⟨⟨h1, _⟩, h3⟩
        exact ⟨h1, (Nat.le_div_iff_mul_le (by omega)).2 h3⟩
      · rintro ⟨h1, h2⟩
        exact ⟨⟨h1, le_trans h2 hle⟩, (Nat.le_div_iff_mul_le (by omega)).1 h2⟩
    rw [this]; simp
  have hge : ∀ b ∈ Icc 1 m, m ≤ x / b := by
    intro b hb
    simp only [mem_Icc] at hb
    rw [Nat.le_div_iff_mul_le (by omega)]
    nlinarith
  rw [Finset.sum_congr rfl hL, Finset.sum_congr rfl hR] at hswap
  have key : ∑ b ∈ Icc 1 m, (x / b - m) + m * m = ∑ b ∈ Icc 1 m, x / b := by
    have : ∑ b ∈ Icc 1 m, (x / b - m) + ∑ b ∈ Icc 1 m, m = ∑ b ∈ Icc 1 m, x / b := by
      rw [← Finset.sum_add_distrib]
      exact Finset.sum_congr rfl (fun b hb => Nat.sub_add_cancel (hge b hb))
    simpa using this
  rw [hD, hsplit, hswap, sq]
  omega

#print axioms hyperbola_count

theorem hasSum_moebius_div_sq :
    HasSum (fun n : ℕ => ((ArithmeticFunction.moebius n : ℤ) : ℝ) / (n : ℝ) ^ 2) (6 / π ^ 2) := by
  have hs : 1 < (2 : ℂ).re := by norm_num
  have h1 := LSeries_one_mul_Lseries_moebius hs
  rw [LSeries_one_eq_riemannZeta hs, riemannZeta_two] at h1
  have hL : LSeries (fun n => ((ArithmeticFunction.moebius n : ℤ) : ℂ)) 2 = ((6 / π ^ 2 : ℝ) : ℂ) := by
    have hpi : (π : ℂ) ≠ 0 := by exact_mod_cast Real.pi_ne_zero
    push_cast
    field_simp
    linear_combination 6 * h1
  have hsum := (ArithmeticFunction.LSeriesSummable_moebius_iff.mpr hs).LSeriesHasSum
  rw [hL] at hsum
  rw [← Complex.hasSum_ofReal]
  unfold LSeriesHasSum at hsum
  convert hsum using 1
  ext n
  rcases eq_or_ne n 0 with rfl | hn
  · simp
  · rw [LSeries.term_of_ne_zero hn]
    push_cast
    congr 1
    norm_cast

#print axioms hasSum_moebius_div_sq

theorem sum_Ioc_cast_id (k : ℕ) : ∑ m ∈ Ioc 0 k, (m : ℝ) = (k : ℝ) * ((k : ℝ) + 1) / 2 := by
  induction k with
  | zero => simp
  | succ k ih =>
    rw [Finset.sum_Ioc_succ_top (Nat.zero_le k), ih]
    push_cast; ring

#print axioms sum_Ioc_cast_id

theorem totient_sum_moebius (N : ℕ) :
    ∑ n ∈ Icc 1 N, (Nat.totient n : ℝ)
      = ∑ d ∈ Icc 1 N, ((ArithmeticFunction.moebius d : ℤ) : ℝ)
          * (((N / d : ℕ) : ℝ) * (((N / d : ℕ) : ℝ) + 1) / 2) := by
  have hI : Icc 1 N = Ioc 0 N := by ext; simp only [mem_Icc, mem_Ioc]; omega
  set f : ArithmeticFunction ℝ := (ArithmeticFunction.moebius : ArithmeticFunction ℝ)
  set g : ArithmeticFunction ℝ := ((ArithmeticFunction.id : ArithmeticFunction ℕ) : ArithmeticFunction ℝ)
  have hinv : ∀ n > 0, ∑ x ∈ n.divisorsAntidiagonal,
      ((ArithmeticFunction.moebius x.fst : ℤ) : ℝ) * ((x.snd : ℕ) : ℝ) = (Nat.totient n : ℝ) := by
    apply (ArithmeticFunction.sum_eq_iff_sum_mul_moebius_eq (f := fun n => (Nat.totient n : ℝ))
      (g := fun n => (n : ℝ))).1
    intro n _
    exact_mod_cast Nat.sum_totient n
  have hfg : ∀ n ∈ Ioc 0 N, (f * g) n = (Nat.totient n : ℝ) := by
    intro n hn
    rw [← hinv n (by simp only [mem_Ioc] at hn; omega), ArithmeticFunction.mul_apply]
    simp [f, g]
  have := ArithmeticFunction.sum_Ioc_mul_eq_sum_sum f g N
  rw [Finset.sum_congr rfl hfg] at this
  rw [hI, this]
  refine Finset.sum_congr rfl (fun d _ => ?_)
  rw [← sum_Ioc_cast_id]
  simp [f, g]

#print axioms totient_sum_moebius

theorem moebius_tail_le (N : ℕ) :
    |∑' i : ℕ, ((ArithmeticFunction.moebius (i + (N + 1)) : ℤ) : ℝ) / (((i + (N + 1) : ℕ) : ℝ)) ^ 2|
      ≤ 2 / ((N : ℝ) + 1) := by
  set b : ℕ → ℝ := fun i => 1 / (((i + (N + 1) : ℕ) : ℝ)) ^ 2 with hbdef
  have hb : Summable b := by
    have h := (summable_nat_add_iff (N + 1)).2 (Real.summable_one_div_nat_pow.2 (by norm_num : 1 < 2))
    simpa [hbdef] using h
  have hb0 : ∀ i, 0 ≤ b i := fun i => by positivity
  have hbsum : ∑' i, b i ≤ 2 / ((N : ℝ) + 1) := by
    refine Real.tsum_le_of_sum_range_le hb0 (fun n => ?_)
    have h := sum_Ioo_inv_sq_le (α := ℝ) N (n + (N + 1))
    have heq : ∑ i ∈ range n, b i = ∑ j ∈ Ioo N (n + (N + 1)), ((j : ℝ) ^ 2)⁻¹ := by
      have hI : Ioo N (n + (N + 1)) = Ico (N + 1) (n + (N + 1)) := by
        ext; simp only [mem_Ioo, mem_Ico]; omega
      rw [hI, Finset.sum_Ico_eq_sum_range]
      refine Finset.sum_congr (by congr 1; omega) (fun i _ => ?_)
      simp only [hbdef, one_div]
      congr 2
      push_cast; ring
    rw [heq]; exact h
  have := tsum_of_norm_bounded hb.hasSum (f := fun i : ℕ =>
      ((ArithmeticFunction.moebius (i + (N + 1)) : ℤ) : ℝ) / (((i + (N + 1) : ℕ) : ℝ)) ^ 2)
    (fun i => by
      rw [Real.norm_eq_abs, abs_div, abs_of_nonneg (by positivity : (0:ℝ) ≤ (((i + (N + 1) : ℕ) : ℝ)) ^ 2)]
      simp only [hbdef]
      gcongr
      exact_mod_cast ArithmeticFunction.abs_moebius_le_one)
  rw [Real.norm_eq_abs] at this
  linarith

#print axioms moebius_tail_le

theorem floor_tri_err (N d : ℕ) (hd : 0 < d) :
    |((N / d : ℕ) : ℝ) * (((N / d : ℕ) : ℝ) + 1) / 2 - ((N : ℝ) / d) ^ 2 / 2| ≤ (N : ℝ) / d / 2 := by
  have hfl := Nat.floor_div_eq_div (K := ℝ) N d
  set y : ℝ := (N : ℝ) / d
  set k : ℝ := ((N / d : ℕ) : ℝ)
  have hy0 : 0 ≤ y := by positivity
  have hk1 : k ≤ y := by simp only [k]; rw [← hfl]; exact Nat.floor_le hy0
  have hk2 : y < k + 1 := by simp only [k]; rw [← hfl]; exact Nat.lt_floor_add_one y
  have hk0 : 0 ≤ k := by positivity
  rw [abs_le]
  constructor <;> nlinarith

#print axioms floor_tri_err

theorem divisor_poly_aux (m f : ℝ) (hm : 1 ≤ m) (hf0 : 0 ≤ f) (hf1 : f < 1) :
    2 * (m + f) ^ 2 * f < m * (2 * (m + f) + 5 - 2 * m + (m + f) ^ 2 - m ^ 2) := by
  have hm0 : 0 ≤ m := by linarith
  have hA : m * f * f ≤ m * f := by
    have := mul_le_mul_of_nonneg_left hf1.le (mul_nonneg hm0 hf0); linarith
  have hC : m * f ≤ m := by
    have := mul_le_mul_of_nonneg_left hf1.le hm0; linarith
  have hB : f * f * f ≤ 1 := by
    have h1 : f * f ≤ 1 := by nlinarith
    have h2 : f * f * f ≤ f * f := by
      have := mul_le_mul_of_nonneg_left hf1.le (mul_nonneg hf0 hf0); linarith
    linarith
  have : m * (2 * (m + f) + 5 - 2 * m + (m + f) ^ 2 - m ^ 2) - 2 * (m + f) ^ 2 * f
      = 5 * m + 2 * (m * f) - 3 * (m * f * f) - 2 * (f * f * f) := by ring
  linarith

#print axioms divisor_poly_aux

/-- Dirichlet's divisor theorem with an explicit constant: for every real x ≥ 1, the divisor
counts τ(1) + … + τ(x) (all whole n up to x) differ from x log x + (2γ − 1)x, with γ Euler's
constant, by less than 2√x + 5. -/
theorem divisor_sum_error_lt_two_sqrt_add_five (x : ℝ) (hx : 1 ≤ x) :
    |(∑ n ∈ Icc 1 ⌊x⌋₊, ((Nat.divisors n).card : ℝ))
        - (x * Real.log x + (2 * Real.eulerMascheroniConstant - 1) * x)|
      < 2 * Real.sqrt x + 5 := by
  set N := ⌊x⌋₊ with hNdef
  have hx0 : (0 : ℝ) ≤ x := by linarith
  have hN1 : 1 ≤ N := Nat.le_floor (by simpa using hx)
  have hNx : (N : ℝ) ≤ x := Nat.floor_le hx0
  have hxN : x < N + 1 := Nat.lt_floor_add_one x
  set m := Nat.sqrt N with hmdef
  have hm1 : 1 ≤ m := Nat.le_sqrt.2 (by omega)
  have hmN : m * m ≤ N := Nat.sqrt_le N
  have hNm : N < (m + 1) * (m + 1) := Nat.lt_succ_sqrt N
  have hmNr : (m : ℝ) * m ≤ N := by exact_mod_cast hmN
  have hNmr : (N : ℝ) + 1 ≤ ((m : ℝ) + 1) * ((m : ℝ) + 1) := by exact_mod_cast hNm
  have hm1r : (1 : ℝ) ≤ m := by exact_mod_cast hm1
  set s := Real.sqrt x with hsdef
  have hs0 : 0 ≤ s := Real.sqrt_nonneg x
  have hs2 : s ^ 2 = x := Real.sq_sqrt hx0
  have hms : (m : ℝ) ≤ s := by
    by_contra h; have h := lt_of_not_ge h; nlinarith
  have hsm : s < m + 1 := by
    by_contra h; have h := le_of_not_gt h; nlinarith
  have hspos : 0 < s := by linarith
  -- hyperbola identity in ℝ
  have hD : (∑ n ∈ Icc 1 N, ((Nat.divisors n).card : ℝ)) + (m : ℝ) ^ 2
      = 2 * ∑ d ∈ Icc 1 m, ((N / d : ℕ) : ℝ) := by
    have := hyperbola_count N
    rw [← hmdef] at this
    exact_mod_cast this
  set H := ∑ d ∈ Icc 1 m, ((d : ℕ) : ℝ)⁻¹ with hHdef
  have hdiv : ∀ d ∈ Icc 1 m, ((N / d : ℕ) : ℝ) ≤ x / d ∧ x / d - 1 < ((N / d : ℕ) : ℝ) := by
    intro d hd
    rw [hNdef, ← Nat.floor_div_natCast]
    exact ⟨Nat.floor_le (by positivity), by linarith [Nat.lt_floor_add_one (x / d)]⟩
  have hne : (Icc 1 m).Nonempty := ⟨1, by simp only [mem_Icc]; omega⟩
  have hSle : ∑ d ∈ Icc 1 m, ((N / d : ℕ) : ℝ) ≤ x * H := by
    rw [hHdef, Finset.mul_sum]
    refine Finset.sum_le_sum (fun d hd => ?_)
    rw [← div_eq_mul_inv]; exact (hdiv d hd).1
  have hSgt : x * H - m < ∑ d ∈ Icc 1 m, ((N / d : ℕ) : ℝ) := by
    have : x * H - m = ∑ d ∈ Icc 1 m, (x / d - 1) := by
      rw [Finset.sum_sub_distrib, hHdef, Finset.mul_sum]
      simp [div_eq_mul_inv]
    rw [this]
    exact Finset.sum_lt_sum_of_nonempty hne (fun d hd => (hdiv d hd).2)
  have hHc : ((harmonic m : ℚ) : ℝ) = H := by
    rw [harmonic_eq_sum_Icc]; push_cast; rfl
  have hγ1 : H - Real.log ((m : ℝ) + 1) < Real.eulerMascheroniConstant := by
    have := Real.eulerMascheroniSeq_lt_eulerMascheroniConstant m
    rw [Real.eulerMascheroniSeq, hHc] at this
    exact this
  have hγ2 : Real.eulerMascheroniConstant < H - Real.log m := by
    have := Real.eulerMascheroniConstant_lt_eulerMascheroniSeq' m
    rw [Real.eulerMascheroniSeq', ite_eq_right (by omega), hHc] at this
    exact this
  have hlogx : Real.log x = 2 * Real.log s := by
    rw [hsdef, Real.log_sqrt hx0]; ring
  have hmpos : (0 : ℝ) < m := by linarith
  have hU : Real.log ((m : ℝ) + 1) - Real.log s ≤ ((m : ℝ) + 1) / s - 1 := by
    rw [← Real.log_div (by positivity) hspos.ne']
    exact Real.log_le_sub_one_of_pos (by positivity)
  have hLo : Real.log s - Real.log m ≤ s / m - 1 := by
    rw [← Real.log_div hspos.ne' hmpos.ne']
    exact Real.log_le_sub_one_of_pos (by positivity)
  have hU' : x * (Real.log ((m : ℝ) + 1) - Real.log s) ≤ s * ((m : ℝ) + 1) - s ^ 2 := by
    have h := mul_le_mul_of_nonneg_left hU hx0
    have : x * (((m : ℝ) + 1) / s - 1) = s * ((m : ℝ) + 1) - s ^ 2 := by
      rw [← hs2]; field_simp
    linarith
  have hL' : x * (Real.log s - Real.log m) ≤ s ^ 2 * (s - m) / m := by
    have h := mul_le_mul_of_nonneg_left hLo hx0
    have : x * (s / m - 1) = s ^ 2 * (s - m) / m := by
      rw [← hs2]; field_simp
    linarith
  have hpoly : 2 * (s ^ 2 * (s - m) / m) < 2 * s + 5 - 2 * m + s ^ 2 - (m : ℝ) ^ 2 := by
    rw [show 2 * (s ^ 2 * (s - m) / m) = 2 * s ^ 2 * (s - m) / m by ring,
      div_lt_iff₀ hmpos]
    have h := divisor_poly_aux (m : ℝ) (s - m) hm1r (by linarith) (by linarith)
    have e1 : ((m : ℝ) + (s - m)) = s := by ring
    rw [e1] at h
    linarith
  have hx1 : 0 < x := by linarith
  have hg1 := mul_lt_mul_of_pos_left hγ1 hx1
  have hg2 := mul_lt_mul_of_pos_left hγ2 hx1
  rw [hlogx, abs_lt]
  constructor
  · -- lower
    linarith
  · -- upper
    nlinarith [sq_nonneg (s - m)]

/-- Dirichlet's hyperbola identity: with m = ⌊√x⌋, the divisor counts of 1 to x add to twice the
sum of ⌊x/d⌋ for d from 1 to m, minus m². Stated as D(x) + m² = 2 (⌊x/1⌋ + … + ⌊x/m⌋). -/
theorem divisor_sum_hyperbola_identity (x : ℕ) :
    (∑ n ∈ Icc 1 x, (Nat.divisors n).card) + Nat.sqrt x ^ 2
      = 2 * ∑ d ∈ Icc 1 (Nat.sqrt x), x / d := by
  exact hyperbola_count x

/-- The totient's average order: for every whole x ≥ 1, the totients φ(1) + … + φ(x) differ from
3x²/π² by at most x log x + 1.5x. -/
theorem totient_sum_error_le (x : ℕ) (hx : 1 ≤ x) :
    |(∑ n ∈ Icc 1 x, (Nat.totient n : ℝ)) - 3 * (x : ℝ) ^ 2 / Real.pi ^ 2|
      ≤ (x : ℝ) * Real.log x + 3 / 2 * (x : ℝ) := by
  set a : ℕ → ℝ := fun n => ((ArithmeticFunction.moebius n : ℤ) : ℝ) / (n : ℝ) ^ 2 with hadef
  have hS := hasSum_moebius_div_sq
  have hsplit := hS.summable.sum_add_tsum_nat_add (x + 1)
  rw [hS.tsum_eq] at hsplit
  set T := ∑' i, a (i + (x + 1)) with hT
  have hTb : |T| ≤ 2 / ((x : ℝ) + 1) := by
    have := moebius_tail_le x
    simpa [hT, hadef] using this
  have hrange : ∑ i ∈ range (x + 1), a i = ∑ d ∈ Icc 1 x, a d := by
    rw [Finset.range_eq_Ico, Finset.sum_eq_sum_Ico_succ_bot (by omega)]
    have : Ico (0 + 1) (x + 1) = Icc 1 x := by ext; simp only [mem_Ico, mem_Icc]; omega
    rw [this]
    simp [hadef]
  rw [hrange] at hsplit
  have hpi : (Real.pi : ℝ) ≠ 0 := Real.pi_ne_zero
  have hmain : (∑ n ∈ Icc 1 x, (Nat.totient n : ℝ)) - 3 * (x : ℝ) ^ 2 / Real.pi ^ 2
      = ∑ d ∈ Icc 1 x, ((ArithmeticFunction.moebius d : ℤ) : ℝ) *
          (((x / d : ℕ) : ℝ) * (((x / d : ℕ) : ℝ) + 1) / 2 - ((x : ℝ) / d) ^ 2 / 2)
        - (x : ℝ) ^ 2 / 2 * T := by
    have h3 : 3 * (x : ℝ) ^ 2 / Real.pi ^ 2 = (x : ℝ) ^ 2 / 2 * (6 / Real.pi ^ 2) := by
      field_simp; ring
    rw [totient_sum_moebius, h3, ← hsplit, mul_add, Finset.mul_sum]
    simp only [mul_sub, Finset.sum_sub_distrib, hadef]
    have : ∑ i ∈ Icc 1 x, ((ArithmeticFunction.moebius i : ℤ) : ℝ) * (((x : ℝ) / i) ^ 2 / 2)
        = ∑ i ∈ Icc 1 x, (x : ℝ) ^ 2 / 2 * (((ArithmeticFunction.moebius i : ℤ) : ℝ) / (i : ℝ) ^ 2) := by
      refine Finset.sum_congr rfl (fun i _ => ?_)
      ring
    rw [this]; ring
  have hsum : |∑ d ∈ Icc 1 x, ((ArithmeticFunction.moebius d : ℤ) : ℝ) *
          (((x / d : ℕ) : ℝ) * (((x / d : ℕ) : ℝ) + 1) / 2 - ((x : ℝ) / d) ^ 2 / 2)|
        ≤ (x : ℝ) / 2 * (1 + Real.log x) := by
    refine (Finset.abs_sum_le_sum_abs _ _).trans ?_
    have hH := harmonic_le_one_add_log x
    rw [harmonic_eq_sum_Icc] at hH
    push_cast at hH
    calc ∑ d ∈ Icc 1 x, |((ArithmeticFunction.moebius d : ℤ) : ℝ) *
          (((x / d : ℕ) : ℝ) * (((x / d : ℕ) : ℝ) + 1) / 2 - ((x : ℝ) / d) ^ 2 / 2)|
        ≤ ∑ d ∈ Icc 1 x, (x : ℝ) / 2 * (d : ℝ)⁻¹ := by
          refine Finset.sum_le_sum (fun d hd => ?_)
          have hd0 : 0 < d := by simp only [mem_Icc] at hd; omega
          rw [abs_mul]
          have h1 : |((ArithmeticFunction.moebius d : ℤ) : ℝ)| ≤ 1 := by
            exact_mod_cast ArithmeticFunction.abs_moebius_le_one
          have h2 := floor_tri_err x d hd0
          have h3 : (x : ℝ) / d / 2 = (x : ℝ) / 2 * (d : ℝ)⁻¹ := by ring
          rw [← h3]
          calc _ ≤ 1 * ((x : ℝ) / d / 2) := by
                apply mul_le_mul h1 h2 (abs_nonneg _) (by norm_num)
            _ = _ := one_mul _
      _ = (x : ℝ) / 2 * ∑ d ∈ Icc 1 x, (d : ℝ)⁻¹ := by rw [Finset.mul_sum]
      _ ≤ (x : ℝ) / 2 * (1 + Real.log x) := by gcongr
  have hx0 : (1 : ℝ) ≤ x := by exact_mod_cast hx
  have hlog : 0 ≤ Real.log x := Real.log_nonneg hx0
  have htail : |(x : ℝ) ^ 2 / 2 * T| ≤ (x : ℝ) := by
    rw [abs_mul, abs_of_nonneg (by positivity : (0:ℝ) ≤ (x : ℝ) ^ 2 / 2)]
    calc (x : ℝ) ^ 2 / 2 * |T| ≤ (x : ℝ) ^ 2 / 2 * (2 / ((x : ℝ) + 1)) := by gcongr
      _ ≤ (x : ℝ) := by
        rw [show (x : ℝ) ^ 2 / 2 * (2 / ((x : ℝ) + 1)) = (x : ℝ) ^ 2 / ((x : ℝ) + 1) by
          field_simp]
        rw [div_le_iff₀ (by positivity)]
        nlinarith
  rw [hmain]
  calc _ ≤ |∑ d ∈ Icc 1 x, ((ArithmeticFunction.moebius d : ℤ) : ℝ) *
          (((x / d : ℕ) : ℝ) * (((x / d : ℕ) : ℝ) + 1) / 2 - ((x : ℝ) / d) ^ 2 / 2)|
        + |(x : ℝ) ^ 2 / 2 * T| := abs_sub _ _
    _ ≤ _ := by nlinarith

-- The number 12 has six divisors: 1, 2, 3, 4, 6 and 12.
example : (Nat.divisors 12).card = 6 := by decide

-- The divisor counts of 1 to 10 add to 27.
example : ∑ n ∈ Icc 1 10, (Nat.divisors n).card = 27 := by decide

-- At x = 10, m = 3 and the hyperbola gives 2 × (10 + 5 + 3) − 3 × 3 = 27.
example : Nat.sqrt 10 = 3 ∧ 2 * ∑ d ∈ Icc 1 3, 10 / d - 3 * 3 = 27 :=
  ⟨(Nat.eq_sqrt.2 (by norm_num)).symm, by decide⟩

-- At x = 10^6, m = 1,000, the first 1,000 columns hold 7,485,017 points and the hyperbola gives 13,970,034.
example : Nat.sqrt (10 ^ 6) = 1000 ∧ ∑ d ∈ Icc 1 1000, 10 ^ 6 / d = 7485017 ∧
    2 * 7485017 - 1000 * 1000 = 13970034 :=
  ⟨(Nat.eq_sqrt.2 (by norm_num)).symm, by decide +kernel, by norm_num⟩

#print axioms divisor_sum_error_lt_two_sqrt_add_five
#print axioms divisor_sum_hyperbola_identity
#print axioms totient_sum_error_le
