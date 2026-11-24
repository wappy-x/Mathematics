-- Boosting: for any ±1 labels and any ±1 rules whose weighted errors lie strictly between 0 and one half, AdaBoost's training error is at most the product of its rescaling factors, which equals the product of 2 sqrt(ε_t (1 - ε_t)) and is at most exp(-2 Σ γ_t²), and the say α_t is the one that makes each factor smallest.
import Mathlib.Algebra.BigOperators.Field
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Sqrt
import Mathlib.Tactic.NormNum

open Finset Real

/-- Helper: at the say a = ½ ln((1 - ε)/ε), ε e^a equals (1 - ε) e^(-a), equals √(ε(1 - ε)),
and ε e^a e^a = 1 - ε. -/
theorem say_facts (ε : ℝ) (h0 : 0 < ε) (h1 : ε < 1) :
    let a := 1 / 2 * log ((1 - ε) / ε)
    ε * exp a = (1 - ε) * exp (-a) ∧ ε * exp a = √(ε * (1 - ε)) ∧
      ε * exp a * exp a = 1 - ε := by
  intro a
  have hu : 0 < exp a := exp_pos a
  have hsq : exp a * exp a = (1 - ε) / ε := by
    rw [← exp_add, show a + a = log ((1 - ε) / ε) by simp only [a]; ring]
    exact exp_log (div_pos (by linarith) h0)
  have h3 : ε * exp a * exp a = 1 - ε := by
    rw [mul_assoc, hsq]; field_simp
  refine ⟨?_, ?_, h3⟩
  · rw [exp_neg, ← h3]; field_simp
  · symm
    rw [Real.sqrt_eq_iff_mul_self_eq (by nlinarith) (by positivity)]
    nlinarith [h3]

/-- Helper: the content of `adaboost_say_minimizes_Z`, stated above the main theorem so it can use it. -/
theorem say_minimizes_Z_helper
    (ε : ℝ) (h0 : 0 < ε) (h1 : ε < 1) :
    let a := 1 / 2 * log ((1 - ε) / ε)
    (1 - ε) * exp (-a) + ε * exp a = 2 * √(ε * (1 - ε)) ∧
      (∀ b : ℝ, (1 - ε) * exp (-a) + ε * exp a ≤ (1 - ε) * exp (-b) + ε * exp b) ∧
      ε * exp a = (1 - ε) * exp (-a) := by
  intro a
  obtain ⟨hA, hB, hC⟩ := say_facts ε h0 h1
  refine ⟨by rw [← hA, ← hB]; ring, ?_, hA⟩
  intro b
  rw [← hA]
  have hw : exp (-b) * exp b = 1 := by rw [← exp_add]; simp
  have hwp := exp_pos (-b)
  have hsq : (1 - ε) * exp (-b) + ε * exp b - 2 * (ε * exp a) =
      ε * exp (-b) * (exp a - exp b) ^ 2 := by
    linear_combination (2 * ε * exp a - ε * exp b) * hw - exp (-b) * hC
  nlinarith [mul_nonneg (mul_nonneg h0.le hwp.le) (sq_nonneg (exp a - exp b))]

/-- Helper: the content of `two_sqrt_err_mul_le_exp_neg_two_edge_sq`, stated above the main theorem. -/
theorem two_sqrt_le_exp_helper (ε : ℝ) :
    2 * √(ε * (1 - ε)) ≤ exp (-2 * (1 / 2 - ε) ^ 2) := by
  rcases le_or_gt 0 (ε * (1 - ε)) with hx | hx
  · have hs := Real.sq_sqrt hx
    have hsn := Real.sqrt_nonneg (ε * (1 - ε))
    have hE := exp_pos (-2 * (1 / 2 - ε) ^ 2)
    have hE2 : exp (-2 * (1 / 2 - ε) ^ 2) ^ 2 = exp (-4 * (1 / 2 - ε) ^ 2) := by
      rw [← exp_nat_mul]; congr 1; push_cast; ring
    have hle := add_one_le_exp (-4 * (1 / 2 - ε) ^ 2)
    have key : (2 * √(ε * (1 - ε))) ^ 2 ≤ exp (-2 * (1 / 2 - ε) ^ 2) ^ 2 := by
      rw [hE2, mul_pow, hs]; nlinarith
    exact (pow_le_pow_iff_left₀ (by positivity) hE.le (by norm_num)).1 key
  · rw [Real.sqrt_eq_zero'.2 hx.le]; simp; exact (exp_pos _).le

#print axioms say_facts
#print axioms say_minimizes_Z_helper
#print axioms two_sqrt_le_exp_helper

/-- The AdaBoost training-error bound (the card's theorem, Steps 0 to 5). Take n training
orders with labels y_i = +1 or -1, and in each round t a rule h_t that answers +1 or -1.
The weights start at D_0(i) = 1/n. In round t the weighted error ε_t is the weight on the orders
h_t gets wrong, the say is α_t = ½ ln((1 - ε_t)/ε_t), the rescaling factor is
Z_t = Σ_i D_t(i) e^(-α_t y_i h_t(x_i)), and the new weights are D_t(i) e^(-α_t y_i h_t(x_i)) / Z_t.
After T rounds the committee's score is F(x_i) = Σ_t α_t h_t(x_i). If in every round the rule
beats a coin flip (0 < ε_t < ½), then the fraction of training orders with margin y_i F(x_i) ≤ 0
is at most Π Z_t, this product equals Π 2√(ε_t(1 - ε_t)), and that is at most
exp(-2 Σ γ_t²) with the edge γ_t = ½ - ε_t. -/
theorem adaboost_training_error_le_prod_Z_le_exp
    {n : ℕ} (T : ℕ) (y : Fin n → ℝ) (h : ℕ → Fin n → ℝ)
    (D : ℕ → Fin n → ℝ) (ε α Z : ℕ → ℝ) (F : Fin n → ℝ)
    (hy : ∀ i, y i = 1 ∨ y i = -1)
    (hh : ∀ t i, h t i = 1 ∨ h t i = -1)
    (hD0 : ∀ i, D 0 i = 1 / n)
    (hε : ∀ t, ε t = ∑ i ∈ univ.filter (fun i => h t i ≠ y i), D t i)
    (hα : ∀ t, α t = 1 / 2 * log ((1 - ε t) / ε t))
    (hZ : ∀ t, Z t = ∑ i, D t i * exp (-(α t * y i * h t i)))
    (hD : ∀ t i, D (t + 1) i = D t i * exp (-(α t * y i * h t i)) / Z t)
    (hF : ∀ i, F i = ∑ t ∈ range T, α t * h t i)
    (hweak : ∀ t < T, 0 < ε t ∧ ε t < 1 / 2) :
    ((univ.filter (fun i => y i * F i ≤ 0)).card : ℝ) / n ≤ ∏ t ∈ range T, Z t ∧
      ∏ t ∈ range T, Z t = ∏ t ∈ range T, 2 * √(ε t * (1 - ε t)) ∧
      ∏ t ∈ range T, 2 * √(ε t * (1 - ε t)) ≤ exp (-2 * ∑ t ∈ range T, (1 / 2 - ε t) ^ 2) := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    cases T with
    | zero => simp
    | succ T =>
      exfalso
      have := (hweak 0 (Nat.succ_pos _)).1
      rw [hε 0] at this
      simp at this
  have hnR : (0 : ℝ) < n := by exact_mod_cast hn
  have : Nonempty (Fin n) := ⟨⟨0, hn⟩⟩
  -- weights stay positive and sum to one
  have key : ∀ t, (∀ i, 0 < D t i) ∧ ∑ i, D t i = 1 := by
    intro t
    induction t with
    | zero =>
      refine ⟨fun i => by rw [hD0]; positivity, ?_⟩
      simp only [hD0, sum_const, card_univ, Fintype.card_fin, nsmul_eq_mul]
      field_simp
    | succ t ih =>
      have hZpos : 0 < Z t := by
        rw [hZ]
        exact Finset.sum_pos (fun i _ => mul_pos (ih.1 i) (exp_pos _)) univ_nonempty
      refine ⟨fun i => by rw [hD]; exact div_pos (mul_pos (ih.1 i) (exp_pos _)) hZpos, ?_⟩
      simp_rw [hD]
      rw [← Finset.sum_div, ← hZ]
      exact div_self hZpos.ne'
  have hZpos : ∀ t, 0 < Z t := fun t => by
    rw [hZ]
    exact Finset.sum_pos (fun i _ => mul_pos ((key t).1 i) (exp_pos _)) univ_nonempty
  -- unrolled weights
  have unroll : ∀ S i, D S i * ∏ t ∈ range S, Z t =
      D 0 i * exp (-(∑ t ∈ range S, α t * y i * h t i)) := by
    intro S i
    induction S with
    | zero => simp
    | succ S ih =>
      rw [prod_range_succ, sum_range_succ, hD, neg_add, exp_add, ← mul_assoc (D 0 i), ← ih]
      field_simp [(hZpos S).ne']
  -- Z in terms of ε
  have hZε : ∀ t, Z t = (1 - ε t) * exp (-α t) + ε t * exp (α t) := by
    intro t
    have hsplit : ∀ i, D t i * exp (-(α t * y i * h t i)) =
        if h t i ≠ y i then D t i * exp (α t) else D t i * exp (-α t) := by
      intro i
      rcases hy i with h1 | h1 <;> rcases hh t i with h2 | h2 <;> simp [h1, h2] <;> norm_num
    have hsum := Finset.sum_filter_add_sum_filter_not univ (fun i => h t i ≠ y i) (D t)
    rw [(key t).2, ← hε] at hsum
    rw [hZ, sum_congr rfl (fun i _ => hsplit i), sum_ite, ← sum_mul, ← sum_mul, ← hε]
    have : ∑ x ∈ univ.filter (fun i => ¬h t i ≠ y i), D t x = 1 - ε t := by linarith
    rw [this]; ring
  refine ⟨?_, ?_, ?_⟩
  · -- training error bound
    have hcard : ((univ.filter (fun i => y i * F i ≤ 0)).card : ℝ) ≤
        ∑ i, exp (-(y i * F i)) := by
      rw [natCast_card_filter]
      refine sum_le_sum (fun i _ => ?_)
      split_ifs with hc
      · exact one_le_exp (by linarith)
      · exact (exp_pos _).le
    have hyF : ∀ i, y i * F i = ∑ t ∈ range T, α t * y i * h t i := by
      intro i; rw [hF, mul_sum]; exact sum_congr rfl (fun t _ => by ring)
    calc ((univ.filter (fun i => y i * F i ≤ 0)).card : ℝ) / n
        ≤ (∑ i, exp (-(y i * F i))) / n := div_le_div_of_nonneg_right hcard hnR.le
      _ = ∑ i, D T i * ∏ t ∈ range T, Z t := by
          rw [sum_div]
          refine sum_congr rfl (fun i _ => ?_)
          rw [unroll, hD0, hyF]; ring
      _ = ∏ t ∈ range T, Z t := by rw [← sum_mul, (key T).2, one_mul]
  · refine prod_congr rfl (fun t ht => ?_)
    have ⟨e0, e1⟩ := hweak t (mem_range.1 ht)
    rw [hZε, hα]
    exact (say_minimizes_Z_helper (ε t) e0 (by linarith)).1
  · rw [mul_sum, exp_sum]
    refine Finset.prod_le_prod₀ (fun t _ => by positivity) (fun t _ => ?_)
    exact two_sqrt_le_exp_helper (ε t)

/-- The say that makes Z smallest (Step 4). For a weighted error 0 < ε < 1, the rescaling
factor as a function of the say, Z(α) = (1 - ε) e^(-α) + ε e^(α), is smallest at
α = ½ ln((1 - ε)/ε), where it equals 2√(ε(1 - ε)); and there the wrong orders' new weight
ε e^(α) equals the right orders' (1 - ε) e^(-α), so after the update the wrong orders hold
exactly half the weight. -/
theorem adaboost_say_minimizes_Z
    (ε : ℝ) (h0 : 0 < ε) (h1 : ε < 1) :
    let a := 1 / 2 * log ((1 - ε) / ε)
    (1 - ε) * exp (-a) + ε * exp a = 2 * √(ε * (1 - ε)) ∧
      (∀ b : ℝ, (1 - ε) * exp (-a) + ε * exp a ≤ (1 - ε) * exp (-b) + ε * exp b) ∧
      ε * exp a = (1 - ε) * exp (-a) := by
  exact say_minimizes_Z_helper ε h0 h1

/-- Each round's shrink factor is at most an exponential in the edge (Step 5): writing
γ = ½ - ε, 2√(ε(1 - ε)) = √(1 - 4γ²) ≤ e^(-2γ²), because 1 + u ≤ e^u for every number u. -/
theorem two_sqrt_err_mul_le_exp_neg_two_edge_sq (ε : ℝ) :
    2 * √(ε * (1 - ε)) ≤ exp (-2 * (1 / 2 - ε) ^ 2) := by
  exact two_sqrt_le_exp_helper ε

-- Round 1 on the ten toy orders, ε₁ = 3/10 and edge γ₁ = 1/5: 4 ε(1 - ε) = 1 - 4γ², the
-- quantity under the square root in Z₁ = 2√(0.21).
example : 4 * ((3 : ℚ) / 10) * (1 - 3 / 10) = 1 - 4 * (1 / 2 - 3 / 10) ^ 2 := by
  norm_num

-- After round 1 each wrong order's weight 1/10 becomes 1/6 and each right one's becomes 1/14
-- (the update divides by 2ε and 2(1 - ε)), so the three wrong orders C, D, H hold half.
example : (1 : ℚ) / 10 / (2 * (3 / 10)) = 1 / 6 ∧ (1 : ℚ) / 10 / (2 * (7 / 10)) = 1 / 14 ∧
    3 * ((1 : ℚ) / 6) = 1 / 2 := by
  norm_num

-- Rounds 2 and 3: the round-2 stump is wrong on F, G, I, J, so ε₂ = 4 × 1/14 = 2/7; after its
-- update A, B, E weigh 1/20 each and H weighs 7/60, so the round-3 stump, wrong on A, B, E, H,
-- has ε₃ = 3/20 + 7/60 = 4/15.
example : 4 * ((1 : ℚ) / 14) = 2 / 7 ∧ (1 : ℚ) / 14 / (2 * (5 / 7)) = 1 / 20 ∧
    (1 : ℚ) / 6 / (2 * (5 / 7)) = 7 / 60 ∧ 3 * ((1 : ℚ) / 20) + 7 / 60 = 4 / 15 := by
  norm_num

-- The ceiling after 3 rounds, squared: (Z₁ Z₂ Z₃)² = 1408/2625, so Z₁ Z₂ Z₃ = 0.7324.
example : (4 * ((3 : ℚ) / 10 * (7 / 10))) * (4 * ((2 : ℚ) / 7 * (5 / 7))) *
    (4 * ((4 : ℚ) / 15 * (11 / 15))) = 1408 / 2625 := by
  norm_num

-- At ε = 0.3 every round, Z = 2√0.21 and Z^T < 1/16000 first holds at T = 112:
-- (Z²)^112 = 0.84^112 < 1/16000² but 0.84^111 ≥ 1/16000².
example : ((21 : ℚ) / 25) ^ 112 * 16000 ^ 2 < 1 ∧ 1 ≤ ((21 : ℚ) / 25) ^ 111 * 16000 ^ 2 := by
  norm_num

#print axioms adaboost_training_error_le_prod_Z_le_exp
#print axioms adaboost_say_minimizes_Z
#print axioms two_sqrt_err_mul_le_exp_neg_two_edge_sq
