-- Fisher information: no estimator that is right on average for every value of the unknown has variance below one over the Fisher information, so for n coin flips no unbiased guess has variance below p(1-p)/n, and the plain fraction of heads meets that floor.
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Basic
import Mathlib.Analysis.SpecialFunctions.Log.Deriv
import Mathlib.Algebra.BigOperators.Fin
import Mathlib.Data.Fintype.BigOperators
import Mathlib.Tactic

open Finset

/-- The chance of one head-tail record `r` of `n` flips (`true` = heads) when heads has chance `p`. -/
noncomputable def coinChance (n : ℕ) (p : ℝ) (r : Fin n → Bool) : ℝ :=
  ∏ i, if r i then p else 1 - p

/-- The number of heads `K` in a record `r`. -/
def heads {n : ℕ} (r : Fin n → Bool) : ℕ :=
  (univ.filter (fun i => r i = true)).card

lemma coinChance_cons (n : ℕ) (p : ℝ) (b : Bool) (r : Fin n → Bool) :
    coinChance (n + 1) p (Fin.cons b r) = (if b then p else 1 - p) * coinChance n p r := by
  simp [coinChance, Fin.prod_univ_succ]

#print axioms coinChance_cons

lemma heads_cons (n : ℕ) (b : Bool) (r : Fin n → Bool) :
    heads (Fin.cons b r : Fin (n + 1) → Bool) = (if b then 1 else 0) + heads r := by
  simp only [heads, card_filter, Fin.sum_univ_succ, Fin.cons_zero, Fin.cons_succ]

#print axioms heads_cons

lemma coin_sum_succ (n : ℕ) (p : ℝ) (g : ℕ → ℝ) :
    ∑ r : Fin (n + 1) → Bool, coinChance (n + 1) p r * g (heads r)
      = p * ∑ r : Fin n → Bool, coinChance n p r * g (heads r + 1)
        + (1 - p) * ∑ r : Fin n → Bool, coinChance n p r * g (heads r) := by
  rw [← (Fin.consEquiv (fun _ => Bool)).sum_comp, Fintype.sum_prod_type, Fintype.sum_bool]
  simp only [Fin.consEquiv_apply, coinChance_cons, heads_cons, mul_sum]
  simp [mul_assoc, add_comm]

#print axioms coin_sum_succ

lemma coin_moment0 (n : ℕ) (p : ℝ) : ∑ r : Fin n → Bool, coinChance n p r = 1 := by
  induction n with
  | zero => simp [coinChance]
  | succ n ih =>
    have h := coin_sum_succ n p (fun _ => 1)
    simp only [mul_one] at h
    rw [h, ih]; ring

#print axioms coin_moment0

lemma coin_moment1 (n : ℕ) (p : ℝ) :
    ∑ r : Fin n → Bool, coinChance n p r * (heads r : ℝ) = n * p := by
  induction n with
  | zero => simp [coinChance, heads]
  | succ n ih =>
    have h := coin_sum_succ n p (fun k => (k : ℝ))
    simp only [Nat.cast_add, Nat.cast_one, mul_add, mul_one, sum_add_distrib] at h
    rw [h, ih, coin_moment0]; push_cast; ring

#print axioms coin_moment1

lemma coin_moment2 (n : ℕ) (p : ℝ) :
    ∑ r : Fin n → Bool, coinChance n p r * (heads r : ℝ) ^ 2 = n * p * (1 - p) + (n * p) ^ 2 := by
  induction n with
  | zero => simp [coinChance, heads]
  | succ n ih =>
    have h := coin_sum_succ n p (fun k => (k : ℝ) ^ 2)
    have e : ∀ r : Fin n → Bool, coinChance n p r * ((heads r + 1 : ℕ) : ℝ) ^ 2
        = coinChance n p r * (heads r : ℝ) ^ 2 + 2 * (coinChance n p r * (heads r : ℝ))
          + coinChance n p r := by
      intro r; push_cast; ring
    simp only [e, sum_add_distrib, ← mul_sum] at h
    rw [h, ih, coin_moment1, coin_moment0]; push_cast; ring

#print axioms coin_moment2

lemma coinChance_form (n : ℕ) (r : Fin n → Bool) (t : ℝ) :
    coinChance n t r = t ^ heads r * (1 - t) ^ (univ.filter (fun i => ¬ r i = true)).card := by
  simp [coinChance, heads, prod_ite, prod_const]

#print axioms coinChance_form

lemma heads_add_tails (n : ℕ) (r : Fin n → Bool) :
    ((univ.filter (fun i => ¬ r i = true)).card : ℝ) = n - heads r := by
  have := card_filter_add_card_filter_not (s := (univ : Finset (Fin n))) (fun i => r i = true)
  rw [card_univ, Fintype.card_fin] at this
  have h := congrArg (Nat.cast (R := ℝ)) this
  push_cast at h
  unfold heads
  linarith

#print axioms heads_add_tails

lemma coin_score (n : ℕ) (r : Fin n → Bool) (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    deriv (fun t => Real.log (coinChance n t r)) p = (heads r : ℝ) / p - ((n : ℝ) - heads r) / (1 - p) := by
  set m := (univ.filter (fun i => ¬ r i = true)).card with hmdef
  have heq : (fun t => Real.log (coinChance n t r))
      =ᶠ[nhds p] (fun t => (heads r : ℝ) * Real.log t + (m : ℝ) * Real.log (1 - t)) := by
    filter_upwards [Ioo_mem_nhds hp0 hp1] with t ht
    have h1 : t ≠ 0 := ht.1.ne'
    have h2 : 1 - t ≠ 0 := by linarith [ht.2]
    rw [coinChance_form, Real.log_mul (pow_ne_zero _ h1) (pow_ne_zero _ h2), Real.log_pow,
      Real.log_pow]
  rw [heq.deriv_eq]
  have h2 : (1 - p) ≠ 0 := by linarith
  have hd : HasDerivAt (fun t => (heads r : ℝ) * Real.log t + (m : ℝ) * Real.log (1 - t))
      ((heads r : ℝ) * p⁻¹ + (m : ℝ) * ((-1) / (1 - p))) p := by
    have a := (Real.hasDerivAt_log hp0.ne').const_mul (heads r : ℝ)
    have b := (((hasDerivAt_id' p).const_sub 1).log h2).const_mul (m : ℝ)
    exact a.add b
  rw [hd.deriv, hmdef, heads_add_tails]
  field_simp
  ring

#print axioms coin_score

lemma coin_info (n : ℕ) (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    ∑ r, coinChance n p r * (deriv (fun t => Real.log (coinChance n t r)) p) ^ 2
      = n / (p * (1 - p)) := by
  have h2 : (1 - p) ≠ 0 := by linarith
  have hp : p ≠ 0 := hp0.ne'
  have e : ∀ r : Fin n → Bool,
      coinChance n p r * (deriv (fun t => Real.log (coinChance n t r)) p) ^ 2
        = 1 / (p * (1 - p)) ^ 2 * (coinChance n p r * (heads r : ℝ) ^ 2)
          + (-2 * n * p / (p * (1 - p)) ^ 2) * (coinChance n p r * (heads r : ℝ))
          + ((n * p) ^ 2 / (p * (1 - p)) ^ 2) * coinChance n p r := by
    intro r
    rw [coin_score n r p hp0 hp1]
    field_simp
    ring
  simp only [e, sum_add_distrib, ← mul_sum, coin_moment0, coin_moment1, coin_moment2]
  field_simp
  ring

#print axioms coin_info

/-- Cramér–Rao bound. A model gives each record `r` (from a finite list that does not move with
the unknown) a chance `P θ r`, positive for every `θ` in an open range `U`, adding to 1, with a
slope in `θ`. The score is the slope of `log P`, and the Fisher information is the average squared
score. If an estimator `T` is unbiased at every value in `U` and the information at `θ` is positive,
then its variance at `θ` is at least one over the information. -/
theorem cramer_rao_bound {R : Type*} [Fintype R] (P : ℝ → R → ℝ) (T : R → ℝ)
    (U : Set ℝ) (hU : IsOpen U) (θ : ℝ) (hθ : θ ∈ U)
    (hpos : ∀ t ∈ U, ∀ r, 0 < P t r)
    (hsum : ∀ t ∈ U, ∑ r, P t r = 1)
    (hdiff : ∀ r, DifferentiableAt ℝ (fun t => P t r) θ)
    (hunb : ∀ t ∈ U, ∑ r, P t r * T r = t)
    (hinfo : 0 < ∑ r, P θ r * (deriv (fun t => Real.log (P t r)) θ) ^ 2) :
    1 / (∑ r, P θ r * (deriv (fun t => Real.log (P t r)) θ) ^ 2)
      ≤ ∑ r, P θ r * (T r - ∑ s, P θ s * T s) ^ 2 := by
  set I := ∑ r, P θ r * (deriv (fun t => Real.log (P t r)) θ) ^ 2 with hI
  set m := ∑ s, P θ s * T s with hm
  set D : R → ℝ := fun r => deriv (fun t => P t r) θ with hD
  set S : R → ℝ := fun r => deriv (fun t => Real.log (P t r)) θ with hS
  have hnhds : U ∈ nhds θ := hU.mem_nhds hθ
  have hSD : ∀ r, S r = D r / P θ r := fun r =>
    deriv.log (hdiff r) (hpos θ hθ r).ne'
  have hD0 : ∑ r, D r = 0 := by
    have h1 : (fun t => ∑ r, P t r) =ᶠ[nhds θ] (fun _ => (1 : ℝ)) :=
      Filter.eventually_of_mem hnhds (fun t ht => hsum t ht)
    have h2 := h1.deriv_eq
    rw [deriv_fun_sum (A := fun r t => P t r) (fun r _ => hdiff r)] at h2
    simpa using h2
  have hD1 : ∑ r, D r * T r = 1 := by
    have h1 : (fun t => ∑ r, P t r * T r) =ᶠ[nhds θ] (fun t => t) :=
      Filter.eventually_of_mem hnhds (fun t ht => hunb t ht)
    have h2 := h1.deriv_eq
    rw [deriv_fun_sum (A := fun r t => P t r * T r) (fun r _ => (hdiff r).mul_const (T r))] at h2
    simp only [deriv_mul_const (hdiff _), deriv_id''] at h2
    simpa [hD] using h2
  have hX : ∑ r, P θ r * S r * (T r - m) = 1 := by
    have : ∀ r, P θ r * S r * (T r - m) = D r * T r - m * D r := by
      intro r
      rw [hSD r]
      have := (hpos θ hθ r).ne'
      field_simp
    simp only [this, sum_sub_distrib, ← mul_sum, hD0, hD1]
    ring
  have hI' : I = ∑ r, P θ r * S r ^ 2 := rfl
  have key : ∑ r, P θ r * (T r - m - S r / I) ^ 2
      = ∑ r, P θ r * (T r - m) ^ 2 - 2 / I * (∑ r, P θ r * S r * (T r - m))
        + 1 / I ^ 2 * (∑ r, P θ r * S r ^ 2) := by
    rw [mul_sum, mul_sum, ← sum_sub_distrib, ← sum_add_distrib]
    refine sum_congr rfl (fun r _ => ?_)
    field_simp
    ring
  have hnn : 0 ≤ ∑ r, P θ r * (T r - m - S r / I) ^ 2 :=
    sum_nonneg (fun r _ => mul_nonneg (hpos θ hθ r).le (sq_nonneg _))
  rw [key, hX, ← hI'] at hnn
  have : 1 / I ^ 2 * I = 1 / I := by field_simp
  rw [this] at hnn
  have h2 : 2 / I * 1 = 2 * (1 / I) := by ring
  rw [h2] at hnn
  linarith

/-- The coin's floor. For `n` flips of a coin with chance `p` strictly between 0 and 1, any rule
`T` from records to guesses that is right on average for every chance strictly between 0 and 1
has variance at least `p(1-p)/n`. -/
theorem coin_cramer_rao_floor (n : ℕ) (T : (Fin n → Bool) → ℝ)
    (hunb : ∀ q : ℝ, 0 < q → q < 1 → ∑ r, coinChance n q r * T r = q)
    (p : ℝ) (hp0 : 0 < p) (hp1 : p < 1) :
    p * (1 - p) / n ≤ ∑ r, coinChance n p r * (T r - ∑ s, coinChance n p s * T s) ^ 2 := by
  rcases Nat.eq_zero_or_pos n with hn | hn
  · subst hn
    simp only [Nat.cast_zero, div_zero]
    refine sum_nonneg (fun r _ => mul_nonneg ?_ (sq_nonneg _))
    simp [coinChance]
  have hpos : ∀ t ∈ Set.Ioo (0 : ℝ) 1, ∀ r, 0 < coinChance n t r := by
    intro t ht r
    refine prod_pos (fun i _ => ?_)
    split_ifs
    · exact ht.1
    · linarith [ht.2]
  have hdiff : ∀ r, DifferentiableAt ℝ (fun t => coinChance n t r) p := by
    intro r
    rw [show (fun t => coinChance n t r) = fun t => t ^ heads r *
        (1 - t) ^ (univ.filter (fun i => ¬ r i = true)).card from funext (coinChance_form n r)]
    fun_prop
  have hinfo : 0 < ∑ r, coinChance n p r * (deriv (fun t => Real.log (coinChance n t r)) p) ^ 2 := by
    rw [coin_info n p hp0 hp1]
    have : (0 : ℝ) < n := by exact_mod_cast hn
    have : 0 < 1 - p := by linarith
    positivity
  have h := cramer_rao_bound (coinChance n) T (Set.Ioo 0 1) isOpen_Ioo p ⟨hp0, hp1⟩ hpos
    (fun t _ => coin_moment0 n t) hdiff (fun t ht => hunb t ht.1 ht.2) hinfo
  rw [coin_info n p hp0 hp1, one_div_div] at h
  exact h

/-- The plain fraction of heads `K/n` is right on average, and its variance is exactly
`p(1-p)/n`: it sits on the floor. -/
theorem sample_proportion_meets_floor (n : ℕ) (hn : 0 < n) (p : ℝ) :
    (∑ r, coinChance n p r * ((heads r : ℝ) / n) = p) ∧
      ∑ r, coinChance n p r * ((heads r : ℝ) / n - p) ^ 2 = p * (1 - p) / n := by
  have hn' : (n : ℝ) ≠ 0 := by exact_mod_cast hn.ne'
  constructor
  · have e : ∀ r : Fin n → Bool, coinChance n p r * ((heads r : ℝ) / n)
        = 1 / n * (coinChance n p r * (heads r : ℝ)) := by
      intro r; field_simp
    simp only [e, ← mul_sum, coin_moment1]
    field_simp
  · have e : ∀ r : Fin n → Bool, coinChance n p r * ((heads r : ℝ) / n - p) ^ 2
        = 1 / (n : ℝ) ^ 2 * (coinChance n p r * (heads r : ℝ) ^ 2)
          + (-2 * p / n) * (coinChance n p r * (heads r : ℝ))
          + p ^ 2 * coinChance n p r := by
      intro r; field_simp; ring
    simp only [e, sum_add_distrib, ← mul_sum, coin_moment0, coin_moment1, coin_moment2]
    field_simp
    ring

-- The bent coin, p = 1/4, four flips: information 64/3, floor 3/64.
example : (4 : ℚ) / ((1 / 4) * (1 - 1 / 4)) = 64 / 3 := by norm_num
example : (1 / 4 : ℚ) * (1 - 1 / 4) / 4 = 3 / 64 := by norm_num
-- Check by squared scores: chances of 0, 2, 3, 4 heads times squared scores (-16/3, 16/3, 32/3, 16).
example : (81 / 256 : ℚ) * (16 / 3) ^ 2 + 54 / 256 * (16 / 3) ^ 2 + 12 / 256 * (32 / 3) ^ 2
    + 1 / 256 * 16 ^ 2 = 64 / 3 := by norm_num
-- Weights 4/10, 3/10, 2/10, 1/10: variance 9/160.
example : (1 / 4 : ℚ) * (3 / 4) * ((4 / 10) ^ 2 + (3 / 10) ^ 2 + (2 / 10) ^ 2 + (1 / 10) ^ 2)
    = 9 / 160 := by norm_num
-- Laplace's rule (K+1)/6 with four flips: mean squared error 1/36 at every p.
example (p : ℝ) : 4 * p * (1 - p) / 36 + ((4 * p + 1) / 6 - p) ^ 2 = 1 / 36 := by ring
-- Stopped clock at p = 3/5: mean squared error 49/400; the floor there is 3/50.
example : ((3 / 5 : ℚ) - 1 / 4) ^ 2 = 49 / 400 := by norm_num
example : (3 / 5 : ℚ) * (1 - 3 / 5) / 4 = 3 / 50 := by norm_num
-- Moving edge, theta = 2, four draws: corrected maximum 1/6, naive "floor" 1/4.
example : (2 : ℚ) ^ 2 / (4 * (4 + 2)) = 1 / 6 := by norm_num
example : (1 : ℚ) / (4 * (-1 / 2)) ^ 2 = 1 / 4 := by norm_num
-- The poll: 1,000 voters, p = 52/100: floor 156/625000.
example : (52 / 100 : ℚ) * (48 / 100) / 1000 = 156 / 625000 := by norm_num

#print axioms cramer_rao_bound
#print axioms coin_cramer_rao_floor
#print axioms sample_proportion_meets_floor
