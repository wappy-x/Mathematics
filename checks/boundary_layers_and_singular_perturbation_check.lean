-- Boundary layers: for ε y'' + y' + y = 0 with y(0) = 0 and y(1) = 1, the composite e^(1-x) - e^(1-x/ε) is within e·ε(1 + o(1)) of the exact solution on [0, 1], and matching forces the inner constant to be e.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Order.Filter.Basic
import Mathlib.Analysis.Calculus.Deriv.MeanValue
import Mathlib.Analysis.SpecialFunctions.ExpDeriv

open Real Filter Topology Set

lemma bl_const_on_Icc (f : ℝ → ℝ) (hf : Differentiable ℝ f)
    (h : ∀ x ∈ Icc (0:ℝ) 1, deriv f x = 0) : ∀ x ∈ Icc (0:ℝ) 1, f x = f 0 := by
  intro x hx
  rcases eq_or_lt_of_le hx.1 with h0 | h0
  · rw [← h0]
  · obtain ⟨c, hc, hcd⟩ := exists_deriv_eq_slope f h0 hf.continuous.continuousOn
      (fun z _ => (hf z).differentiableWithinAt)
    rw [h c ⟨hc.1.le, hc.2.le.trans hx.2⟩] at hcd
    have : x - 0 ≠ 0 := by linarith
    rw [eq_div_iff this, zero_mul] at hcd
    linarith

#print axioms bl_const_on_Icc

lemma bl_exp_sub_one_le (u : ℝ) : exp u - 1 ≤ u * exp u := by
  have h1 := add_one_le_exp (-u)
  have h2 := exp_pos u
  have h3 : exp (-u) * exp u = 1 := by rw [← exp_add]; simp
  nlinarith

#print axioms bl_exp_sub_one_le

lemma bl_solution_form (ε a b : ℝ) (hε : 0 < ε) (hsum : ε * (a + b) = 1)
    (hprod : ε * (a * b) = 1) (hab : a < b) (y : ℝ → ℝ) (hy : Differentiable ℝ y)
    (hy' : Differentiable ℝ (deriv y))
    (hode : ∀ x ∈ Icc (0 : ℝ) 1, ε * deriv (deriv y) x + deriv y x + y x = 0)
    (h0 : y 0 = 0) (h1 : y 1 = 1) :
    ∀ x ∈ Icc (0 : ℝ) 1, y x = (exp (-a * x) - exp (-b * x)) / (exp (-a) - exp (-b)) := by
  set K := deriv y 0 + a * y 0 with hK
  have hd : ∀ x, HasDerivAt (fun x => (deriv y x + a * y x) * exp (b * x))
      ((deriv (deriv y) x + a * deriv y x) * exp (b * x)
        + (deriv y x + a * y x) * (exp (b * x) * (b * 1))) x := by
    intro x
    have e1 : HasDerivAt (deriv y) (deriv (deriv y) x) x := (hy' x).hasDerivAt
    have e2 : HasDerivAt y (deriv y x) x := (hy x).hasDerivAt
    exact (e1.add (e2.const_mul a)).mul ((hasDerivAt_id' x).const_mul b).exp
  have hw0 := bl_const_on_Icc (fun x => (deriv y x + a * y x) * exp (b * x))
    (fun x => (hd x).differentiableAt) (by
      intro x hx
      rw [(hd x).deriv]
      have hx' := hode x hx
      have hm : ε * ((deriv (deriv y) x + a * deriv y x) * exp (b * x)
          + (deriv y x + a * y x) * (exp (b * x) * (b * 1))) = 0 := by
        linear_combination (exp (b * x)) * hx' + (exp (b * x) * deriv y x) * hsum
          + (exp (b * x) * y x) * hprod
      exact (mul_eq_zero.mp hm).resolve_left hε.ne')
  have hv : ∀ x ∈ Icc (0:ℝ) 1, deriv y x + a * y x = K * exp (-b * x) := by
    intro x hx
    have hw := hw0 x hx
    simp only [mul_zero, exp_zero, mul_one] at hw
    have hEE : exp (b * x) * exp (-b * x) = 1 := by rw [← exp_add]; simp
    linear_combination (exp (-b * x)) * hw - (deriv y x + a * y x) * hEE
  have hab' : a - b ≠ 0 := by linarith
  set L := K / (a - b) with hLdef
  have hL : L * (a - b) = K := by rw [hLdef]; field_simp
  have hd2 : ∀ x, HasDerivAt (fun x => y x * exp (a * x) - L * exp ((a - b) * x))
      (deriv y x * exp (a * x) + y x * (exp (a * x) * (a * 1))
        - L * (exp ((a - b) * x) * ((a - b) * 1))) x := by
    intro x
    have e2 : HasDerivAt y (deriv y x) x := (hy x).hasDerivAt
    exact (e2.mul ((hasDerivAt_id' x).const_mul a).exp).sub
      (((hasDerivAt_id' x).const_mul (a - b)).exp.const_mul L)
  have hu0 := bl_const_on_Icc (fun x => y x * exp (a * x) - L * exp ((a - b) * x))
    (fun x => (hd2 x).differentiableAt) (by
      intro x hx
      rw [(hd2 x).deriv]
      have hvx := hv x hx
      have hE : exp (a * x) * exp (-b * x) = exp ((a - b) * x) := by
        rw [← exp_add]; congr 1; ring
      linear_combination (exp (a * x)) * hvx + K * hE - (exp ((a - b) * x)) * hL)
  have hyx : ∀ x ∈ Icc (0:ℝ) 1, y x = L * (exp (-b * x) - exp (-a * x)) := by
    intro x hx
    have hu := hu0 x hx
    simp only [mul_zero, exp_zero, mul_one, h0, zero_sub] at hu
    have e1 : exp (a * x) * exp (-a * x) = 1 := by rw [← exp_add]; simp
    have e2 : exp ((a - b) * x) * exp (-a * x) = exp (-b * x) := by
      rw [← exp_add]; congr 1; ring
    linear_combination (exp (-a * x)) * hu - y x * e1 + L * e2
  have hD : 0 < exp (-a) - exp (-b) := by
    have : exp (-b) < exp (-a) := exp_lt_exp.mpr (by linarith)
    linarith
  intro x hx
  rw [eq_div_iff hD.ne']
  have hL1 := hyx 1 ⟨zero_le_one, le_refl _⟩
  rw [h1, mul_one, mul_one] at hL1
  linear_combination (exp (-a) - exp (-b)) * hyx x hx + (exp (-b * x) - exp (-a * x)) * hL1

#print axioms bl_solution_form

set_option maxHeartbeats 4000000 in
lemma bl_gap_bounds (ε a x : ℝ) (hε : 0 < ε) (hε8 : ε < 1 / 8) (ha1 : 1 ≤ a) (ha2 : a ≤ 2)
    (haq : a - 1 = ε * a ^ 2) (hx0 : 0 ≤ x) (hx1 : x ≤ 1) :
    -(exp 1 * exp (ε * a ^ 2) * a ^ 2 / (1 - a * ε) * ε) ≤
      (exp (-a * x) - exp (-(1 / ε - a) * x)) / (exp (-a) - exp (-(1 / ε - a)))
        - (exp (1 - x) - exp (1 - x / ε)) ∧
    (exp (-a * x) - exp (-(1 / ε - a) * x)) / (exp (-a) - exp (-(1 / ε - a)))
        - (exp (1 - x) - exp (1 - x / ε))
      ≤ exp 1 * exp (ε * a ^ 2) * a ^ 2 / (1 - a * ε) * ε + 4 * exp 6 * ε ^ 2 ∧
    (0 < x → exp 1 * ε * (1 - x) ^ 2 - 2 * exp 4 * ε ^ 2 / x ^ 2 ≤
      (exp (-a * x) - exp (-(1 / ε - a) * x)) / (exp (-a) - exp (-(1 / ε - a)))
        - (exp (1 - x) - exp (1 - x / ε))) := by
  set b := 1 / ε - a with hb
  have hinv : 8 < 1 / ε := by rw [lt_div_iff₀ hε]; linarith
  have hab : a + 4 ≤ b := by rw [hb]; linarith
  have hκ : 0 < 1 - a * ε := by nlinarith
  have hκ1 : 1 - a * ε ≤ 1 := by nlinarith
  have hεa : 0 ≤ ε * a ^ 2 := by positivity
  -- the three pieces
  set N := exp (-a * x) - exp (-b * x) with hN
  set D := exp (-a) - exp (-b) with hD
  have hN0 : 0 ≤ N := by
    have : exp (-b * x) ≤ exp (-a * x) := exp_le_exp.mpr (by nlinarith)
    linarith
  have hN1 : N ≤ 1 := by
    have : exp (-a * x) ≤ 1 := exp_le_one_iff.mpr (by nlinarith)
    have := exp_pos (-b * x)
    linarith
  have hDpos : 0 < D := by
    have : exp (-b) < exp (-a) := exp_lt_exp.mpr (by linarith)
    linarith
  set q := exp (a - b) with hq
  have hDq : D * exp a = 1 - q := by
    rw [hD, sub_mul, ← exp_add, ← exp_add]
    simp only [neg_add_cancel, exp_zero]
    congr 2; ring
  have hq0 : 0 < q := exp_pos _
  have hq5 : q ≤ 1 / 5 := by
    have h1 : exp (a - b) * exp (b - a) = 1 := by rw [← exp_add]; simp
    have h2 := add_one_le_exp (b - a)
    nlinarith
  -- tiny correction C
  have hqa : q * exp a = exp (3 * a - 1 / ε) := by
    rw [hq, ← exp_add]; congr 1; rw [hb]; ring
  have hW := quadratic_le_exp_of_nonneg (le_of_lt (lt_trans (by norm_num) hinv))
  have hW2 : 1 ≤ exp (1 / ε) * (2 * ε ^ 2) := by
    have : (1 / ε) ^ 2 / 2 * (2 * ε ^ 2) = 1 := by field_simp
    have h3 : 0 ≤ 1 + 1 / ε := by linarith
    nlinarith
  have hw6 : exp (3 * a - 1 / ε) ≤ 2 * exp 6 * ε ^ 2 := by
    have h1 : exp (3 * a - 1 / ε) * exp (1 / ε) = exp (3 * a) := by
      rw [← exp_add]; congr 1; ring
    have h2 : exp (3 * a) ≤ exp 6 := exp_le_exp.mpr (by linarith)
    have h3 := exp_pos (3 * a - 1 / ε)
    have h4 := exp_pos (6 : ℝ)
    nlinarith
  have hCeq : N / D - N * exp a = N * q / D := by
    rw [eq_div_iff hDpos.ne', sub_mul, div_mul_cancel₀ _ hDpos.ne']
    linear_combination (-N) * hDq
  have hC0 : 0 ≤ N / D - N * exp a := by
    rw [hCeq]; exact div_nonneg (mul_nonneg hN0 hq0.le) hDpos.le
  have hC1 : N / D - N * exp a ≤ 4 * exp 6 * ε ^ 2 := by
    rw [hCeq, div_le_iff₀ hDpos]
    have hM : q * exp a ≤ 4 * exp 6 * ε ^ 2 * D * exp a := by
      rw [mul_assoc (4 * exp 6 * ε ^ 2), hDq, hqa]
      have : 0 ≤ exp 6 * ε ^ 2 := by positivity
      nlinarith
    have hM' : q ≤ 4 * exp 6 * ε ^ 2 * D := le_of_mul_le_mul_right hM (exp_pos a)
    nlinarith
  -- outer piece A
  have hNa : N * exp a = exp (a * (1 - x)) - exp (a - b * x) := by
    rw [hN, sub_mul, ← exp_add, ← exp_add]
    congr 2 <;> ring
  set u := (a - 1) * (1 - x) with hu
  have hu0 : 0 ≤ u := mul_nonneg (by linarith) (by linarith)
  have hu1 : u ≤ ε * a ^ 2 := by rw [hu, ← haq]; nlinarith
  have hE1 : exp (a * (1 - x)) = exp (1 - x) * exp u := by
    rw [← exp_add]; congr 1; ring
  have hA0 : 0 ≤ exp (a * (1 - x)) - exp (1 - x) := by
    rw [hE1, show exp (1 - x) * exp u - exp (1 - x) = exp (1 - x) * (exp u - 1) by ring]
    exact mul_nonneg (exp_pos _).le (by linarith [one_le_exp hu0])
  set P := exp 1 * exp (ε * a ^ 2) * a ^ 2 with hP
  have hP0 : 0 ≤ P := by positivity
  have hPκ : P ≤ P / (1 - a * ε) := by
    rw [le_div_iff₀ hκ]; nlinarith
  have hA1 : exp (a * (1 - x)) - exp (1 - x) ≤ P / (1 - a * ε) * ε := by
    rw [hE1]
    have h1 : exp (1 - x) ≤ exp 1 := exp_le_exp.mpr (by linarith)
    have h2 := bl_exp_sub_one_le u
    have h3 : u * exp u ≤ ε * a ^ 2 * exp (ε * a ^ 2) :=
      mul_le_mul hu1 (exp_le_exp.mpr hu1) (exp_pos _).le hεa
    have h4 : 0 ≤ exp u - 1 := by linarith [one_le_exp hu0]
    have h5 : exp (1 - x) * (exp u - 1) ≤ exp 1 * (ε * a ^ 2 * exp (ε * a ^ 2)) :=
      mul_le_mul h1 (h2.trans h3) h4 (exp_pos 1).le
    have h6 : exp 1 * (ε * a ^ 2 * exp (ε * a ^ 2)) = P * ε := by rw [hP]; ring
    have h7 : P * ε ≤ P / (1 - a * ε) * ε := mul_le_mul_of_nonneg_right hPκ hε.le
    linarith
  -- inner piece B
  set v := (a - 1) + a * x with hv
  have hv0 : 0 ≤ v := by nlinarith
  have hE3 : exp (a - b * x) = exp (1 - x / ε) * exp v := by
    rw [← exp_add]; congr 1; rw [hb, hv]; ring
  have hB0 : 0 ≤ exp (a - b * x) - exp (1 - x / ε) := by
    rw [hE3, show exp (1 - x / ε) * exp v - exp (1 - x / ε)
      = exp (1 - x / ε) * (exp v - 1) by ring]
    exact mul_nonneg (exp_pos _).le (by linarith [one_le_exp hv0])
  set Z := x / ε - a * x with hZ
  have hZ0 : 0 ≤ Z := by
    have : 8 * x ≤ x / ε := by
      rw [div_eq_mul_one_div]; nlinarith
    nlinarith
  have hE4v : exp (1 - x / ε) * exp v = exp 1 * exp (ε * a ^ 2) * exp (-Z) := by
    rw [← exp_add, ← exp_add, ← exp_add]
    congr 1; rw [hv, hZ]; linear_combination haq
  have hZe : (1 + Z) * exp (-Z) ≤ 1 := by
    have h1 := add_one_le_exp Z
    have h2 : exp Z * exp (-Z) = 1 := by rw [← exp_add]; simp
    have h3 := exp_pos (-Z)
    nlinarith
  have hvZ : v ≤ ε * a ^ 2 / (1 - a * ε) * (1 + Z) := by
    have e1 : ε * (x / ε) = x := mul_div_cancel₀ x hε.ne'
    have e2 : ε * a ^ 2 * Z = a ^ 2 * x * (1 - a * ε) := by
      rw [hZ]; linear_combination a ^ 2 * e1
    have h1 : ε * a ^ 2 / (1 - a * ε) * (1 + Z) = ε * a ^ 2 / (1 - a * ε) + a ^ 2 * x := by
      calc ε * a ^ 2 / (1 - a * ε) * (1 + Z)
          = ε * a ^ 2 / (1 - a * ε) + ε * a ^ 2 * Z / (1 - a * ε) := by ring
        _ = ε * a ^ 2 / (1 - a * ε) + a ^ 2 * x * (1 - a * ε) / (1 - a * ε) := by rw [e2]
        _ = ε * a ^ 2 / (1 - a * ε) + a ^ 2 * x := by rw [mul_div_cancel_right₀ _ hκ.ne']
    have h2 : ε * a ^ 2 ≤ ε * a ^ 2 / (1 - a * ε) := by rw [le_div_iff₀ hκ]; nlinarith
    rw [h1, hv, haq]
    nlinarith
  have hB1 : exp (a - b * x) - exp (1 - x / ε) ≤ P / (1 - a * ε) * ε := by
    rw [hE3]
    have h1 : exp (1 - x / ε) * exp v - exp (1 - x / ε)
        = exp (1 - x / ε) * (exp v - 1) := by ring
    have h2 := bl_exp_sub_one_le v
    have h3 : exp (1 - x / ε) * (exp v - 1) ≤ exp (1 - x / ε) * (v * exp v) :=
      mul_le_mul_of_nonneg_left h2 (exp_pos _).le
    have h4 : exp (1 - x / ε) * (v * exp v) = exp 1 * exp (ε * a ^ 2) * (v * exp (-Z)) := by
      calc exp (1 - x / ε) * (v * exp v) = (exp (1 - x / ε) * exp v) * v := by ring
        _ = exp 1 * exp (ε * a ^ 2) * (v * exp (-Z)) := by rw [hE4v]; ring
    have hPa : 0 ≤ exp 1 * exp (ε * a ^ 2) := by positivity
    have h5 : v * exp (-Z) ≤ ε * a ^ 2 / (1 - a * ε) := by
      have h6 : v * exp (-Z) ≤ ε * a ^ 2 / (1 - a * ε) * (1 + Z) * exp (-Z) :=
        mul_le_mul_of_nonneg_right hvZ (exp_pos _).le
      have h7 : 0 ≤ ε * a ^ 2 / (1 - a * ε) := by positivity
      have h8 : ε * a ^ 2 / (1 - a * ε) * (1 + Z) * exp (-Z) ≤ ε * a ^ 2 / (1 - a * ε) := by
        rw [mul_assoc]; nlinarith
      linarith
    have h9 : exp 1 * exp (ε * a ^ 2) * (v * exp (-Z))
        ≤ exp 1 * exp (ε * a ^ 2) * (ε * a ^ 2 / (1 - a * ε)) :=
      mul_le_mul_of_nonneg_left h5 hPa
    have h10 : exp 1 * exp (ε * a ^ 2) * (ε * a ^ 2 / (1 - a * ε)) = P / (1 - a * ε) * ε := by
      rw [hP]; ring
    linarith
  -- assemble
  have hg : N / D - (exp (1 - x) - exp (1 - x / ε))
      = (N / D - N * exp a) + (exp (a * (1 - x)) - exp (1 - x))
        - (exp (a - b * x) - exp (1 - x / ε)) := by rw [hNa]; ring
  refine ⟨?_, ?_, ?_⟩
  · rw [hg]; linarith
  · rw [hg]; linarith
  · intro hxpos
    rw [hg]
    -- lower bound for A at x
    have hA2 : exp 1 * ε * (1 - x) ^ 2 ≤ exp (a * (1 - x)) - exp (1 - x) := by
      rw [hE1]
      have h1 : exp 1 * (1 - x) ≤ exp (1 - x) := by
        have : exp (1 - x) = exp 1 * exp (-x) := by rw [← exp_add]; ring_nf
        rw [this]
        have := add_one_le_exp (-x)
        have := exp_pos 1
        nlinarith
      have h2 : ε * (1 - x) ≤ exp u - 1 := by
        have := add_one_le_exp u
        have : ε * (1 - x) ≤ u := by rw [hu, haq]; nlinarith
        linarith
      have h3 : exp 1 * (1 - x) * (ε * (1 - x)) ≤ exp (1 - x) * (exp u - 1) :=
        mul_le_mul h1 h2 (by nlinarith) (exp_pos _).le
      nlinarith
    have hB2 : exp (a - b * x) - exp (1 - x / ε) ≤ 2 * exp 4 * ε ^ 2 / x ^ 2 := by
      have h1 : exp (a - b * x) ≤ exp (4 - x / ε) := exp_le_exp.mpr (by
        rw [hb]
        have : a - (1 / ε - a) * x = a - x / ε + a * x := by ring
        rw [this]; nlinarith)
      have h2 : exp (4 - x / ε) * exp (x / ε) = exp 4 := by rw [← exp_add]; ring_nf
      have h3 := quadratic_le_exp_of_nonneg (div_nonneg hx0 hε.le)
      have h4 : (x / ε) ^ 2 / 2 * (2 * ε ^ 2 / x ^ 2) = 1 := by field_simp
      have h5 : 0 ≤ x / ε := div_nonneg hx0 hε.le
      have h6 : 1 ≤ exp (x / ε) * (2 * ε ^ 2 / x ^ 2) := by
        have : 0 ≤ 2 * ε ^ 2 / x ^ 2 := by positivity
        nlinarith
      have h7 := exp_pos (4 - x / ε)
      have h8 : exp (4 - x / ε) ≤ 2 * exp 4 * ε ^ 2 / x ^ 2 := by
        have : 2 * exp 4 * ε ^ 2 / x ^ 2 = exp 4 * (2 * ε ^ 2 / x ^ 2) := by ring
        rw [this, ← h2]
        nlinarith
      have := exp_pos (1 - x / ε)
      linarith
    linarith

#print axioms bl_gap_bounds

lemma bl_root_facts (ε : ℝ) (hε : 0 < ε) (hε8 : ε < 1 / 8) :
    1 ≤ 2 / (1 + √(1 - 4 * ε)) ∧ 2 / (1 + √(1 - 4 * ε)) ≤ 2 ∧
      2 / (1 + √(1 - 4 * ε)) - 1 = ε * (2 / (1 + √(1 - 4 * ε))) ^ 2 := by
  set s := √(1 - 4 * ε) with hs
  have hs0 : 0 ≤ s := Real.sqrt_nonneg _
  have hs2 : s ^ 2 = 1 - 4 * ε := Real.sq_sqrt (by linarith)
  have hs1 : s ≤ 1 := by nlinarith
  have hpos : 0 < 1 + s := by linarith
  refine ⟨?_, ?_, ?_⟩
  · rw [le_div_iff₀ hpos]; linarith
  · rw [div_le_iff₀ hpos]; linarith
  · field_simp
    linear_combination -hs2

#print axioms bl_root_facts

lemma bl_h_tendsto :
    Tendsto (fun ε : ℝ => exp 1 * exp (ε * (2 / (1 + √(1 - 4 * ε))) ^ 2)
      * (2 / (1 + √(1 - 4 * ε))) ^ 2 / (1 - (2 / (1 + √(1 - 4 * ε))) * ε))
      (𝓝[>] 0) (𝓝 (exp 1)) := by
  have ha : ContinuousAt (fun ε : ℝ => 2 / (1 + √(1 - 4 * ε))) 0 := by
    apply ContinuousAt.div continuousAt_const (by fun_prop)
    norm_num
  have hh : ContinuousAt (fun ε : ℝ => exp 1 * exp (ε * (2 / (1 + √(1 - 4 * ε))) ^ 2)
      * (2 / (1 + √(1 - 4 * ε))) ^ 2 / (1 - (2 / (1 + √(1 - 4 * ε))) * ε)) 0 := by
    apply ContinuousAt.div (by fun_prop) (by fun_prop)
    norm_num
  have := hh.tendsto
  norm_num at this
  exact this.mono_left nhdsWithin_le_nhds

#print axioms bl_h_tendsto


/-- The composite is right to order ε everywhere, with the sharp constant e: as ε shrinks to 0,
the worst gap on [0, 1] between the composite e^(1-x) - e^(1-x/ε) and the exact solution of
ε y'' + y' + y = 0, y(0) = 0, y(1) = 1, divided by ε, tends to e. Stated without a supremum:
for every δ > 0 and every small enough ε > 0, the gap is at most (e + δ)ε at every x in [0, 1]
and at least (e - δ)ε at some x in [0, 1]. -/
theorem composite_worst_error_over_eps_tendsto_e :
    ∀ δ > 0, ∀ᶠ ε in 𝓝[>] (0 : ℝ), ∀ y : ℝ → ℝ,
      Differentiable ℝ y → Differentiable ℝ (deriv y) →
      (∀ x ∈ Icc (0 : ℝ) 1, ε * deriv (deriv y) x + deriv y x + y x = 0) →
      y 0 = 0 → y 1 = 1 →
      (∀ x ∈ Icc (0 : ℝ) 1, |y x - (exp (1 - x) - exp (1 - x / ε))| ≤ (exp 1 + δ) * ε) ∧
      (∃ x ∈ Icc (0 : ℝ) 1, (exp 1 - δ) * ε ≤ |y x - (exp (1 - x) - exp (1 - x / ε))|) := by
  intro δ hδ
  set t := δ / (δ + 4 * exp 1) with ht
  have he := exp_pos 1
  have ht0 : 0 < t := by positivity
  have htt : t * (δ + 4 * exp 1) = δ := by rw [ht]; field_simp
  have ht1 : t < 1 := by rw [ht, div_lt_one (by positivity)]; linarith
  have h4t : 4 * exp 1 * t ≤ δ := by nlinarith
  filter_upwards [Ioo_mem_nhdsGT (show (0:ℝ) < 1 / 8 by norm_num),
    bl_h_tendsto.eventually_lt_const (show exp 1 < exp 1 + δ / 2 by linarith),
    Ioo_mem_nhdsGT (show (0:ℝ) < δ / (8 * exp 6) by positivity),
    Ioo_mem_nhdsGT (show (0:ℝ) < δ * t ^ 2 / (4 * exp 4) by positivity)]
    with ε hε hhε hε2 hε3
  intro y hy hy' hode h0 h1
  obtain ⟨hε0, hε8⟩ := hε
  obtain ⟨ha1, ha2, haq⟩ := bl_root_facts ε hε0 hε8
  set a := 2 / (1 + √(1 - 4 * ε)) with ha
  have hinv : 8 < 1 / ε := by rw [lt_div_iff₀ hε0]; linarith
  have hsum : ε * (a + (1 / ε - a)) = 1 := by field_simp; ring
  have hprod : ε * (a * (1 / ε - a)) = 1 := by
    have : ε * (a * (1 / ε - a)) = a - ε * a ^ 2 := by field_simp
    rw [this]; linarith
  have hsol := bl_solution_form ε a (1 / ε - a) hε0 hsum hprod (by linarith) y hy hy' hode h0 h1
  set h := exp 1 * exp (ε * a ^ 2) * a ^ 2 / (1 - a * ε) with hh
  have hhe : h * ε ≤ (exp 1 + δ / 2) * ε := mul_le_mul_of_nonneg_right hhε.le hε0.le
  have hε2' : ε * (8 * exp 6) < δ := by
    have := hε2.2; rwa [lt_div_iff₀ (by positivity)] at this
  have hε3' : ε * (4 * exp 4) < δ * t ^ 2 := by
    have := hε3.2; rwa [lt_div_iff₀ (by positivity)] at this
  refine ⟨?_, ?_⟩
  · intro x hx
    obtain ⟨l, u, -⟩ := bl_gap_bounds ε a x hε0 hε8 ha1 ha2 haq hx.1 hx.2
    rw [hsol x hx, abs_le]
    have hC : 4 * exp 6 * ε ^ 2 ≤ δ / 2 * ε := by nlinarith
    constructor <;> nlinarith
  · refine ⟨t, ⟨ht0.le, ht1.le⟩, ?_⟩
    obtain ⟨-, -, w⟩ := bl_gap_bounds ε a t hε0 hε8 ha1 ha2 haq ht0.le ht1.le
    have w' := w ht0
    rw [hsol t ⟨ht0.le, ht1.le⟩]
    refine le_trans ?_ (le_abs_self _)
    have hB : 2 * exp 4 * ε ^ 2 / t ^ 2 ≤ δ / 2 * ε := by
      rw [div_le_iff₀ (by positivity)]
      nlinarith
    have hA : (exp 1 - δ / 2) * ε ≤ exp 1 * ε * (1 - t) ^ 2 := by
      have : exp 1 * ε * (1 - t) ^ 2 = exp 1 * ε * (1 - 2 * t) + exp 1 * ε * t ^ 2 := by ring
      have h2 : 0 ≤ exp 1 * ε * t ^ 2 := by positivity
      nlinarith
    linarith

/-- The exact answer the composite is checked against: for 0 < ε < 1/4, with r₁, r₂ the two roots
of ε r^2 + r + 1 = 0, the function (e^(r₁x) - e^(r₂x)) / (e^(r₁) - e^(r₂)) solves
ε y'' + y' + y = 0 with y(0) = 0 and y(1) = 1. -/
theorem exact_solution_solves_model_problem (ε : ℝ) (hε : 0 < ε) (hε' : ε < 1 / 4) :
    let r₁ := (-1 + √(1 - 4 * ε)) / (2 * ε)
    let r₂ := (-1 - √(1 - 4 * ε)) / (2 * ε)
    let y : ℝ → ℝ := fun x => (exp (r₁ * x) - exp (r₂ * x)) / (exp r₁ - exp r₂)
    Differentiable ℝ y ∧ Differentiable ℝ (deriv y) ∧
      (∀ x, ε * deriv (deriv y) x + deriv y x + y x = 0) ∧ y 0 = 0 ∧ y 1 = 1 := by
  intro r₁ r₂ y
  set s := √(1 - 4 * ε) with hs
  have hs0 : 0 < s := Real.sqrt_pos.mpr (by linarith)
  have hs2 : s ^ 2 = 1 - 4 * ε := Real.sq_sqrt (by linarith)
  have hr : r₂ < r₁ := by
    simp only [r₁, r₂]
    apply div_lt_div_of_pos_right _ (by linarith)
    linarith
  have hD : exp r₁ - exp r₂ ≠ 0 := by
    have := exp_lt_exp.mpr hr
    linarith
  have hq1 : ε * r₁ ^ 2 + r₁ + 1 = 0 := by
    show ε * ((-1 + s) / (2 * ε)) ^ 2 + (-1 + s) / (2 * ε) + 1 = 0
    field_simp
    linear_combination hs2
  have hq2 : ε * r₂ ^ 2 + r₂ + 1 = 0 := by
    show ε * ((-1 - s) / (2 * ε)) ^ 2 + (-1 - s) / (2 * ε) + 1 = 0
    field_simp
    linear_combination hs2
  set D := exp r₁ - exp r₂ with hDdef
  have hd1 : ∀ x, HasDerivAt y ((exp (r₁ * x) * (r₁ * 1) - exp (r₂ * x) * (r₂ * 1)) / D) x := by
    intro x
    exact ((((hasDerivAt_id' x).const_mul r₁).exp).sub
      (((hasDerivAt_id' x).const_mul r₂).exp)).div_const D
  have hdy : deriv y = fun x => (exp (r₁ * x) * (r₁ * 1) - exp (r₂ * x) * (r₂ * 1)) / D := by
    funext x; exact (hd1 x).deriv
  have hd2 : ∀ x, HasDerivAt (deriv y)
      (((exp (r₁ * x) * (r₁ * 1)) * (r₁ * 1) - (exp (r₂ * x) * (r₂ * 1)) * (r₂ * 1)) / D) x := by
    intro x
    rw [hdy]
    exact (((((hasDerivAt_id' x).const_mul r₁).exp).mul_const (r₁ * 1)).sub
      ((((hasDerivAt_id' x).const_mul r₂).exp).mul_const (r₂ * 1))).div_const D
  refine ⟨fun x => (hd1 x).differentiableAt, fun x => (hd2 x).differentiableAt, ?_, ?_, ?_⟩
  · intro x
    rw [(hd2 x).deriv, (hd1 x).deriv]
    have hyx : y x = (exp (r₁ * x) - exp (r₂ * x)) / D := rfl
    rw [hyx, mul_div_assoc', ← add_div, ← add_div, div_eq_zero_iff]
    left
    linear_combination (exp (r₁ * x)) * hq1 - (exp (r₂ * x)) * hq2
  · simp [y]
  · simp only [y, mul_one]
    exact div_self hD

/-- Matching fixes the last constant: the outer solution e^(1-x) tends to e at the wall, and the
inner solution A(1 - e^(-X)) tends to that same value far out exactly when A = e. -/
theorem matching_fixes_inner_constant (A : ℝ) :
    Tendsto (fun x : ℝ => exp (1 - x)) (𝓝 0) (𝓝 (exp 1)) ∧
      (Tendsto (fun X : ℝ => A * (1 - exp (-X))) atTop (𝓝 (exp 1)) ↔ A = exp 1) := by
  have hlim : Tendsto (fun X : ℝ => A * (1 - exp (-X))) atTop (𝓝 A) := by
    have := (tendsto_exp_neg_atTop_nhds_zero.const_sub 1).const_mul A
    simpa using this
  refine ⟨?_, ?_, ?_⟩
  · have : Continuous (fun x : ℝ => exp (1 - x)) := by fun_prop
    simpa using this.tendsto 0
  · intro h
    exact tendsto_nhds_unique hlim h
  · intro h
    rw [← h]
    exact hlim

#print axioms composite_worst_error_over_eps_tendsto_e
#print axioms exact_solution_solves_model_problem
#print axioms matching_fixes_inner_constant
