-- Merton's theorem: in a recombining price tree with a riskless rate not below zero and a share that pays nothing, the American call is worth exactly the European call, the call never falls below the floor S - K e^(-r tau), and an American put can be worth more than its European twin.
import Mathlib.Analysis.SpecialFunctions.Exp

open Real

namespace MertonNoEarlyExercise

/-- The pricing weight of the card's tree, p = (e^(r dt) - 1/u) / (u - 1/u). -/
noncomputable def weight (r dt u : ℝ) : ℝ :=
  (exp (r * dt) - u⁻¹) / (u - u⁻¹)

/-- European value with `m` steps left and share price `s`: the payoff at expiry, and one step
earlier the discounted weighted average of the up value (share times `u`) and the down value
(share divided by `u`). The share pays nothing along the way. -/
noncomputable def euroValue (r dt u : ℝ) (payoff : ℝ → ℝ) : ℕ → ℝ → ℝ
  | 0, s => payoff s
  | m + 1, s =>
      (weight r dt u * euroValue r dt u payoff m (s * u)
        + (1 - weight r dt u) * euroValue r dt u payoff m (s / u)) / exp (r * dt)

/-- American value with `m` steps left and share price `s`: at every node before expiry the holder
takes the larger of exercising now and waiting one more step. -/
noncomputable def amerValue (r dt u : ℝ) (payoff : ℝ → ℝ) : ℕ → ℝ → ℝ
  | 0, s => payoff s
  | m + 1, s =>
      max (payoff s)
        ((weight r dt u * amerValue r dt u payoff m (s * u)
          + (1 - weight r dt u) * amerValue r dt u payoff m (s / u)) / exp (r * dt))

/-- A call with strike `K` pays max(S - K, 0). -/
noncomputable def callPayoff (K : ℝ) : ℝ → ℝ := fun s => max (s - K) 0

/-- A put with strike `K` pays max(K - S, 0). -/
noncomputable def putPayoff (K : ℝ) : ℝ → ℝ := fun s => max (K - s) 0

/-- Helper: the tree's step factor is above one. -/
lemma one_lt_u (r dt u : ℝ) (hu : 0 < u) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    1 < u := by
  have h1 : u⁻¹ < u := hlow.trans hhigh
  have h2 : u * u⁻¹ = 1 := mul_inv_cancel₀ hu.ne'
  nlinarith

/-- Helper: the pricing weight is strictly positive. -/
lemma weight_pos (r dt u : ℝ) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    0 < weight r dt u :=
  div_pos (sub_pos.2 hlow) (sub_pos.2 (hlow.trans hhigh))

/-- Helper: the pricing weight is strictly below one. -/
lemma weight_lt_one (r dt u : ℝ) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    weight r dt u < 1 :=
  (div_lt_one (sub_pos.2 (hlow.trans hhigh))).2 (by linarith)

/-- Helper: the weighted average of the up and down factors is the growth factor e^(r dt). -/
lemma weight_identity (r dt u : ℝ) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    weight r dt u * u + (1 - weight r dt u) * u⁻¹ = exp (r * dt) := by
  have hne : u - u⁻¹ ≠ 0 := (sub_pos.2 (hlow.trans hhigh)).ne'
  have h : weight r dt u * (u - u⁻¹) = exp (r * dt) - u⁻¹ := div_mul_cancel₀ _ hne
  linear_combination h

/-- Helper: discounting over one more step. -/
lemma exp_step (r dt : ℝ) (m : ℕ) :
    exp (-(r * (((m + 1 : ℕ) : ℝ) * dt))) = exp (-(r * ((m : ℝ) * dt))) / exp (r * dt) := by
  push_cast
  rw [show -(r * (((m : ℝ) + 1) * dt)) = -(r * ((m : ℝ) * dt)) - r * dt by ring, exp_sub]

/-- Helper: the European call is never negative. -/
lemma euro_call_nonneg (r dt u K : ℝ) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    ∀ (m : ℕ) (s : ℝ), 0 ≤ euroValue r dt u (callPayoff K) m s := by
  intro m
  induction m with
  | zero => intro s; exact le_max_right _ _
  | succ m ih =>
    intro s
    have hp := weight_pos r dt u hlow hhigh
    have h1p : 0 < 1 - weight r dt u := sub_pos.2 (weight_lt_one r dt u hlow hhigh)
    simp only [euroValue]
    exact div_nonneg (add_nonneg (mul_nonneg hp.le (ih _)) (mul_nonneg h1p.le (ih _)))
      (exp_pos _).le

/-- Helper: the European call is at least S - K e^(-r tau). -/
lemma euro_call_ge (r dt u K : ℝ) (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) :
    ∀ (m : ℕ) (s : ℝ),
      s - K * exp (-(r * ((m : ℝ) * dt))) ≤ euroValue r dt u (callPayoff K) m s := by
  intro m
  induction m with
  | zero => intro s; simp [euroValue, callPayoff]
  | succ m ih =>
    intro s
    have hp := weight_pos r dt u hlow hhigh
    have h1p : 0 < 1 - weight r dt u := sub_pos.2 (weight_lt_one r dt u hlow hhigh)
    have hid := weight_identity r dt u hlow hhigh
    have he := exp_pos (r * dt)
    simp only [euroValue]
    rw [exp_step, le_div_iff₀ he]
    have h1 := mul_le_mul_of_nonneg_left (ih (s * u)) hp.le
    have h2 := mul_le_mul_of_nonneg_left (ih (s / u)) h1p.le
    have h3 : (s - K * (exp (-(r * ((m : ℝ) * dt))) / exp (r * dt))) * exp (r * dt)
        = s * exp (r * dt) - K * exp (-(r * ((m : ℝ) * dt))) := by
      field_simp
    have hs : s * (weight r dt u * u + (1 - weight r dt u) * u⁻¹) = s * exp (r * dt) := by
      rw [hid]
    rw [h3]
    have hsu : s / u = s * u⁻¹ := div_eq_mul_inv s u
    nlinarith [h1, h2, hs]

/-- Helper: K e^(-r tau) is at most K. -/
lemma disc_le (r dt K : ℝ) (hr : 0 ≤ r) (hdt : 0 < dt) (hK : 0 ≤ K) (m : ℕ) :
    K * exp (-(r * ((m : ℝ) * dt))) ≤ K := by
  apply mul_le_of_le_one_right hK
  rw [exp_le_one_iff]
  exact neg_nonpos.2 (mul_nonneg hr (mul_nonneg (Nat.cast_nonneg m) hdt.le))

/-- Helper: deep in the money, the European put is K e^(-r tau) - S. -/
lemma euro_put_deep (r dt u K : ℝ) (hu : 0 < u) (hlow : u⁻¹ < exp (r * dt))
    (hhigh : exp (r * dt) < u) :
    ∀ (m : ℕ) (s : ℝ), 0 ≤ s → s * u ^ m ≤ K →
      euroValue r dt u (putPayoff K) m s = K * exp (-(r * ((m : ℝ) * dt))) - s := by
  intro m
  induction m with
  | zero =>
    intro s _ hsK
    simp only [euroValue, putPayoff, pow_zero, mul_one] at hsK ⊢
    simp only [Nat.cast_zero, zero_mul, mul_zero, neg_zero, exp_zero, mul_one]
    exact max_eq_left (by linarith)
  | succ m ih =>
    intro s hs hsK
    have hid := weight_identity r dt u hlow hhigh
    have he := exp_pos (r * dt)
    have hinv : u⁻¹ ≤ u := (hlow.trans hhigh).le
    have hsum : 0 ≤ s * u ^ m := mul_nonneg hs (pow_nonneg hu.le m)
    have e1 : euroValue r dt u (putPayoff K) m (s * u) = K * exp (-(r * ((m : ℝ) * dt))) - s * u :=
      ih (s * u) (mul_nonneg hs hu.le) (by rw [mul_assoc, ← pow_succ']; exact hsK)
    have e2 : euroValue r dt u (putPayoff K) m (s / u) = K * exp (-(r * ((m : ℝ) * dt))) - s / u := by
      apply ih (s / u) (div_nonneg hs hu.le)
      have a : s / u * u ^ m = (s * u ^ m) * u⁻¹ := by ring
      have b : s * u ^ (m + 1) = (s * u ^ m) * u := by ring
      have c := mul_le_mul_of_nonneg_left hinv hsum
      linarith
    simp only [euroValue]
    rw [e1, e2, exp_step, div_eq_iff he.ne']
    have h4 : K * (exp (-(r * ((m : ℝ) * dt))) / exp (r * dt)) * exp (r * dt)
        = K * exp (-(r * ((m : ℝ) * dt))) := by
      field_simp
    linear_combination (-s) * hid - h4

#print axioms one_lt_u
#print axioms weight_pos
#print axioms weight_lt_one
#print axioms weight_identity
#print axioms exp_step
#print axioms euro_call_nonneg
#print axioms euro_call_ge
#print axioms disc_le
#print axioms euro_put_deep

/-- Merton's theorem. On a share that pays nothing before expiry, with the riskless rate not below
zero and no riskless profit in the tree (1/u < e^(r dt) < u), the American call has the same price
as the European call, at every share price and with any number of steps left: early exercise
is never worth anything. -/
theorem american_call_eq_european_call (r dt u K : ℝ) (hr : 0 ≤ r) (hdt : 0 < dt) (hu : 0 < u)
    (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) (hK : 0 ≤ K) (m : ℕ) (s : ℝ) :
    amerValue r dt u (callPayoff K) m s = euroValue r dt u (callPayoff K) m s := by
  induction m generalizing s with
  | zero => rfl
  | succ m ih =>
    have h : amerValue r dt u (callPayoff K) (m + 1) s
        = max (callPayoff K s) (euroValue r dt u (callPayoff K) (m + 1) s) := by
      simp only [amerValue, euroValue, ih]
    rw [h, max_eq_right]
    apply max_le
    · have := euro_call_ge r dt u K hlow hhigh (m + 1) s
      have := disc_le r dt K hr hdt hK (m + 1)
      linarith
    · exact euro_call_nonneg r dt u K hlow hhigh (m + 1) s

/-- The card's chain: what exercising pays today, max(S - K, 0), is at most the floor
max(S - K e^(-r tau), 0) with tau = m dt the time left, and the floor is at most the European call. -/
theorem exercise_le_floor_le_european_call (r dt u K : ℝ) (hr : 0 ≤ r) (hdt : 0 < dt) (hu : 0 < u)
    (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) (hK : 0 ≤ K) (m : ℕ) (s : ℝ) :
    max (s - K) 0 ≤ max (s - K * exp (-(r * (m * dt)))) 0 ∧
      max (s - K * exp (-(r * (m * dt)))) 0 ≤ euroValue r dt u (callPayoff K) m s := by
  constructor
  · have := disc_le r dt K hr hdt hK m
    exact max_le_max (by linarith) le_rfl
  · exact max_le (euro_call_ge r dt u K hlow hhigh m s) (euro_call_nonneg r dt u K hlow hhigh m s)

/-- Why puts are different: with a positive rate, whenever time is left there is a share price at
which the American put is worth strictly more than the European put, so early exercise of a put
can pay even with no dividend. -/
theorem american_put_can_beat_european_put (r dt u K : ℝ) (hr : 0 < r) (hdt : 0 < dt) (hu : 0 < u)
    (hlow : u⁻¹ < exp (r * dt)) (hhigh : exp (r * dt) < u) (hK : 0 < K) (m : ℕ) (hm : 1 ≤ m) :
    ∃ s : ℝ, 0 < s ∧ euroValue r dt u (putPayoff K) m s < amerValue r dt u (putPayoff K) m s := by
  obtain ⟨n, rfl⟩ : ∃ n, m = n + 1 := ⟨m - 1, by omega⟩
  have hun : 0 < u ^ (n + 1) := pow_pos hu _
  refine ⟨K / u ^ (n + 1) / 2, by positivity, ?_⟩
  have hs0 : 0 ≤ K / u ^ (n + 1) / 2 := by positivity
  have hsK : K / u ^ (n + 1) / 2 * u ^ (n + 1) ≤ K := by
    have : K / u ^ (n + 1) / 2 * u ^ (n + 1) = K / 2 := by field_simp
    rw [this]; linarith
  rw [euro_put_deep r dt u K hu hlow hhigh (n + 1) _ hs0 hsK]
  have hE : exp (-(r * (((n + 1 : ℕ) : ℝ) * dt))) < 1 := by
    rw [Real.exp_lt_one_iff]
    have : (0 : ℝ) < ((n + 1 : ℕ) : ℝ) := Nat.cast_pos.2 (Nat.succ_pos n)
    exact neg_neg_of_pos (mul_pos hr (mul_pos this hdt))
  have hKE := mul_lt_of_lt_one_right hK hE
  have hA : putPayoff K (K / u ^ (n + 1) / 2)
      ≤ amerValue r dt u (putPayoff K) (n + 1) (K / u ^ (n + 1) / 2) := by
    simp only [amerValue]
    exact le_max_left _ _
  have hP : K - K / u ^ (n + 1) / 2 ≤ putPayoff K (K / u ^ (n + 1) / 2) := le_max_left _ _
  linarith

/-- The 2,000-step tree checks a decision at every node before expiry: 1 + 2 + ... + 2000 of them. -/
example : (Finset.range 2000).sum (fun k => k + 1) = 2001000 := by
  rw [Finset.sum_add_distrib, Finset.sum_range_id, Finset.sum_const, Finset.card_range, smul_eq_mul,
    mul_one]

/-- Exercising the call at a share price of 120 with strike 100 pays 20. -/
example : callPayoff 100 120 = 20 := by
  norm_num [callPayoff]

/-- The 5.00-dividend tree exercises only at step 1,000 of 2,000: the ex-date six months into a year. -/
example : (1000 : ℚ) / 2000 = 1 / 2 := by norm_num

#print axioms american_call_eq_european_call
#print axioms exercise_le_floor_le_european_call
#print axioms american_put_can_beat_european_put

end MertonNoEarlyExercise
