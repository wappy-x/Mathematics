-- Early exercise: on a recombining binomial tree with a valid up weight, the American value found by comparing exercise with holding at every node never falls below the payoff or the European value, an American call on a share with no dividend is worth exactly the European call at every node when the rate is positive, and a positive rate makes exercising an American put strictly better than holding at low enough prices.
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Tactic.NormNum

namespace AmericanTree

/-! ## The tree

* `S` is the share price today, `u` and `d` the up and down factors applied at every step.
* `r` is the riskless rate and `q` the dividend yield, both fixed and continuously compounded;
  `Δt` is the length of one step in years.
* The weight on the up branch is `p = (e^{(r-q)Δt} - d) / (u - d)`, as on the earlier tree cards.
* `g` is the payoff function: what exercising pays at a given share price.
* Values are written by the number of steps still to run, `k`, and the share price `s` at the
  node; the card's `V_n(j)` in an `N`-step tree is the value with `N - n` steps to run at the
  node price `S u^j d^(n-j)`. The payoff is read off the price, not the path. -/

/-- Share price at the node reached after `n` steps, `j` of them up moves: `S u^j d^(n-j)`. -/
noncomputable def price (S u d : ℝ) (n j : ℕ) : ℝ := S * u ^ j * d ^ (n - j)

/-- The weight on the up branch, `p = (e^{(r-q)Δt} - d) / (u - d)`. -/
noncomputable def weight (u d r q Δt : ℝ) : ℝ := (Real.exp ((r - q) * Δt) - d) / (u - d)

/-- Holding for one step at price `s`, when `f` gives the value one step later:
`e^{-rΔt} [p f(u s) + (1 - p) f(d s)]`. -/
noncomputable def hold (u d r q Δt : ℝ) (f : ℝ → ℝ) (s : ℝ) : ℝ :=
  Real.exp (-(r * Δt)) *
    (weight u d r q Δt * f (u * s) + (1 - weight u d r q Δt) * f (d * s))

/-- American value with `k` steps to run: the payoff on the last date, and before that the
larger of exercising now and holding one step. -/
noncomputable def american (g : ℝ → ℝ) (u d r q Δt : ℝ) : ℕ → ℝ → ℝ
  | 0 => g
  | k + 1 => fun s => max (g s) (hold u d r q Δt (american g u d r q Δt k) s)

/-- European value with `k` steps to run: the same walk with the comparison deleted. -/
noncomputable def european (g : ℝ → ℝ) (u d r q Δt : ℝ) : ℕ → ℝ → ℝ
  | 0 => g
  | k + 1 => fun s => hold u d r q Δt (european g u d r q Δt k) s

/-- The card's `V_n(j)` for an American option in an `N`-step tree. -/
noncomputable def V (g : ℝ → ℝ) (S u d r q Δt : ℝ) (N n j : ℕ) : ℝ :=
  american g u d r q Δt (N - n) (price S u d n j)

/-- The same node's European value. -/
noncomputable def E (g : ℝ → ℝ) (S u d r q Δt : ℝ) (N n j : ℕ) : ℝ :=
  european g u d r q Δt (N - n) (price S u d n j)

/-- A call's payoff, `max(S - K, 0)`. -/
noncomputable def callPayoff (K : ℝ) (s : ℝ) : ℝ := max (s - K) 0

/-- A put's payoff, `max(K - S, 0)`. -/
noncomputable def putPayoff (K : ℝ) (s : ℝ) : ℝ := max (K - s) 0

/-! ## Helper lemmas -/

lemma weight_nonneg {u d r q Δt : ℝ} (hdR : d < Real.exp ((r - q) * Δt))
    (hRu : Real.exp ((r - q) * Δt) < u) : 0 ≤ weight u d r q Δt := by
  unfold weight
  apply div_nonneg <;> linarith

lemma weight_le_one {u d r q Δt : ℝ} (hdR : d < Real.exp ((r - q) * Δt))
    (hRu : Real.exp ((r - q) * Δt) < u) : weight u d r q Δt ≤ 1 := by
  unfold weight
  rw [div_le_one (by linarith)]
  linarith

lemma hold_mono {u d r q Δt : ℝ} (hdR : d < Real.exp ((r - q) * Δt))
    (hRu : Real.exp ((r - q) * Δt) < u) {f g : ℝ → ℝ} {s : ℝ}
    (hu : f (u * s) ≤ g (u * s)) (hd : f (d * s) ≤ g (d * s)) :
    hold u d r q Δt f s ≤ hold u d r q Δt g s := by
  unfold hold
  have hp0 := weight_nonneg hdR hRu
  have hp1 := weight_le_one hdR hRu
  have h1 : 0 ≤ 1 - weight u d r q Δt := by linarith
  apply mul_le_mul_of_nonneg_left _ (Real.exp_pos _).le
  nlinarith [mul_le_mul_of_nonneg_left hu hp0, mul_le_mul_of_nonneg_left hd h1]

lemma american_ge_payoff (g : ℝ → ℝ) (u d r q Δt : ℝ) :
    ∀ k s, g s ≤ american g u d r q Δt k s
  | 0, _ => le_rfl
  | _ + 1, _ => le_max_left _ _

lemma european_le_american (g : ℝ → ℝ) {u d r q Δt : ℝ} (hdR : d < Real.exp ((r - q) * Δt))
    (hRu : Real.exp ((r - q) * Δt) < u) :
    ∀ k s, european g u d r q Δt k s ≤ american g u d r q Δt k s
  | 0, _ => le_rfl
  | k + 1, s => by
      show hold u d r q Δt (european g u d r q Δt k) s ≤
        max (g s) (hold u d r q Δt (american g u d r q Δt k) s)
      exact le_max_of_le_right
        (hold_mono hdR hRu (european_le_american g hdR hRu k _)
          (european_le_american g hdR hRu k _))

lemma hold_affine {u d r Δt : ℝ} (hdR : d < Real.exp (r * Δt))
    (hRu : Real.exp (r * Δt) < u) (c s : ℝ) :
    hold u d r 0 Δt (fun x => x - c) s = s - c * Real.exp (-(r * Δt)) := by
  have hud : u - d ≠ 0 := by intro h; linarith
  have key : weight u d r 0 Δt * u + (1 - weight u d r 0 Δt) * d = Real.exp (r * Δt) := by
    unfold weight
    rw [sub_zero]
    field_simp
    ring
  unfold hold
  have e : weight u d r 0 Δt * (u * s - c) + (1 - weight u d r 0 Δt) * (d * s - c)
      = s * (weight u d r 0 Δt * u + (1 - weight u d r 0 Δt) * d) - c := by ring
  rw [e, key, Real.exp_neg]
  have := (Real.exp_pos (r * Δt)).ne'
  field_simp

lemma european_call_lower {u d r Δt K : ℝ} (hdR : d < Real.exp (r * Δt))
    (hRu : Real.exp (r * Δt) < u) :
    ∀ (k : ℕ) (s : ℝ), s - K * Real.exp (-(r * Δt * k)) ≤ european (callPayoff K) u d r 0 Δt k s ∧
      0 ≤ european (callPayoff K) u d r 0 Δt k s
  | 0, s => by
      show s - K * Real.exp (-(r * Δt * ((0 : ℕ) : ℝ))) ≤ max (s - K) 0 ∧ 0 ≤ max (s - K) 0
      simp only [Nat.cast_zero, mul_zero, neg_zero, Real.exp_zero, mul_one]
      exact ⟨le_max_left _ _, le_max_right _ _⟩
  | k + 1, s => by
      have hdR' : d < Real.exp ((r - 0) * Δt) := by rw [sub_zero]; exact hdR
      have hRu' : Real.exp ((r - 0) * Δt) < u := by rw [sub_zero]; exact hRu
      show s - K * Real.exp (-(r * Δt * ((k + 1 : ℕ) : ℝ))) ≤
          hold u d r 0 Δt (european (callPayoff K) u d r 0 Δt k) s ∧
        0 ≤ hold u d r 0 Δt (european (callPayoff K) u d r 0 Δt k) s
      constructor
      · have h1 := hold_mono (f := fun x => x - K * Real.exp (-(r * Δt * k)))
          (g := european (callPayoff K) u d r 0 Δt k) (s := s) hdR' hRu'
          (european_call_lower hdR hRu k _).1 (european_call_lower hdR hRu k _).1
        rw [hold_affine hdR hRu, mul_assoc, ← Real.exp_add] at h1
        convert h1 using 4
        push_cast
        ring
      · have h1 := hold_mono (f := fun _ => 0)
          (g := european (callPayoff K) u d r 0 Δt k) (s := s) hdR' hRu'
          (european_call_lower hdR hRu k _).2 (european_call_lower hdR hRu k _).2
        simpa [hold] using h1

lemma american_call_eq_european {u d r Δt K : ℝ} (hΔt : 0 < Δt) (hr : 0 < r) (hK : 0 < K)
    (hdR : d < Real.exp (r * Δt)) (hRu : Real.exp (r * Δt) < u) :
    ∀ k s, american (callPayoff K) u d r 0 Δt k s = european (callPayoff K) u d r 0 Δt k s
  | 0, _ => rfl
  | k + 1, s => by
      show max (callPayoff K s) (hold u d r 0 Δt (american (callPayoff K) u d r 0 Δt k) s) =
        hold u d r 0 Δt (european (callPayoff K) u d r 0 Δt k) s
      have hfun : american (callPayoff K) u d r 0 Δt k = european (callPayoff K) u d r 0 Δt k :=
        funext (american_call_eq_european hΔt hr hK hdR hRu k)
      rw [hfun]
      apply max_eq_right
      obtain ⟨h1, h2⟩ := european_call_lower (K := K) hdR hRu (k + 1) s
      change _ ≤ hold u d r 0 Δt (european (callPayoff K) u d r 0 Δt k) s at h1 h2
      have hexp : Real.exp (-(r * Δt * ((k + 1 : ℕ) : ℝ))) ≤ 1 := by
        rw [Real.exp_le_one_iff, neg_nonpos]
        positivity
      unfold callPayoff
      apply max_le _ h2
      nlinarith

lemma american_put_le {u d r q Δt K : ℝ} (hΔt : 0 < Δt) (hr : 0 < r) (hK : 0 < K)
    (hd : 0 < d) (hdR : d < Real.exp ((r - q) * Δt)) (hRu : Real.exp ((r - q) * Δt) < u) :
    ∀ k s, 0 < s → american (putPayoff K) u d r q Δt k s ≤ K
  | 0, s, hs => by
      show max (K - s) 0 ≤ K
      exact max_le (by linarith) hK.le
  | k + 1, s, hs => by
      show max (putPayoff K s) (hold u d r q Δt (american (putPayoff K) u d r q Δt k) s) ≤ K
      have hu : 0 < u := by linarith [Real.exp_pos ((r - q) * Δt)]
      have h1 := hold_mono (f := american (putPayoff K) u d r q Δt k) (g := fun _ => K) (s := s)
        hdR hRu (american_put_le hΔt hr hK hd hdR hRu k _ (by positivity))
        (american_put_le hΔt hr hK hd hdR hRu k _ (by positivity))
      have h2 : hold u d r q Δt (fun _ => K) s = Real.exp (-(r * Δt)) * K := by
        unfold hold; ring
      have hexp : Real.exp (-(r * Δt)) ≤ 1 := by
        rw [Real.exp_le_one_iff, neg_nonpos]
        positivity
      apply max_le
      · unfold putPayoff; exact max_le (by linarith) hK.le
      · rw [h2] at h1; nlinarith

#print axioms weight_nonneg
#print axioms weight_le_one
#print axioms hold_mono
#print axioms american_ge_payoff
#print axioms european_le_american
#print axioms hold_affine
#print axioms european_call_lower
#print axioms american_call_eq_european
#print axioms american_put_le

/-- **No dividend, no early exercise for a call.** On a tree whose up weight is a weight
(`d < e^{(r-q)Δt} < u`), with a rate above zero, a positive strike and no dividend (`q = 0`),
the American call is worth exactly the European call at every node, root included. -/
theorem american_call_eq_european_call_without_dividend
    (S u d r Δt K : ℝ) (hΔt : 0 < Δt) (hr : 0 < r) (hK : 0 < K)
    (hdR : d < Real.exp (r * Δt)) (hRu : Real.exp (r * Δt) < u)
    (N n j : ℕ) (hn : n ≤ N) (hj : j ≤ n) :
    V (callPayoff K) S u d r 0 Δt N n j = E (callPayoff K) S u d r 0 Δt N n j := by
  unfold V E
  exact american_call_eq_european hΔt hr hK hdR hRu _ _

/-- **Never below the payoff, never below the European.** For any payoff read off the price,
on a tree whose up weight is a weight, the American value at every node is at least what
exercising pays there and at least the European value there. -/
theorem american_ge_payoff_and_european
    (g : ℝ → ℝ) (S u d r q Δt : ℝ) (hΔt : 0 < Δt)
    (hdR : d < Real.exp ((r - q) * Δt)) (hRu : Real.exp ((r - q) * Δt) < u)
    (N n j : ℕ) (hn : n ≤ N) (hj : j ≤ n) :
    g (price S u d n j) ≤ V g S u d r q Δt N n j ∧
      E g S u d r q Δt N n j ≤ V g S u d r q Δt N n j := by
  unfold V E
  exact ⟨american_ge_payoff g u d r q Δt _ _, european_le_american g hdR hRu _ _⟩

/-- **A put wants the cash early.** With a rate above zero and a positive strike, on a tree
with a positive down factor whose up weight is a weight, at every date before expiry there
is a band of low share prices where exercising the American put pays strictly more than
holding it one more step. -/
theorem american_put_exercise_region_nonempty
    (u d r q Δt K : ℝ) (hΔt : 0 < Δt) (hr : 0 < r) (hK : 0 < K) (hd : 0 < d)
    (hdR : d < Real.exp ((r - q) * Δt)) (hRu : Real.exp ((r - q) * Δt) < u) (k : ℕ) :
    ∃ ε > 0, ∀ s : ℝ, 0 < s → s < ε →
      hold u d r q Δt (american (putPayoff K) u d r q Δt k) s < putPayoff K s := by
  have hx : 0 < 1 - Real.exp (-(r * Δt)) := by
    have : Real.exp (-(r * Δt)) < 1 := by
      rw [Real.exp_lt_one_iff, neg_lt_zero]
      positivity
    linarith
  refine ⟨K * (1 - Real.exp (-(r * Δt))), by positivity, ?_⟩
  intro s hs hsε
  have hu : 0 < u := by linarith [Real.exp_pos ((r - q) * Δt)]
  have h1 := hold_mono (f := american (putPayoff K) u d r q Δt k) (g := fun _ => K) (s := s)
    hdR hRu (american_put_le hΔt hr hK hd hdR hRu k _ (by positivity))
    (american_put_le hΔt hr hK hd hdR hRu k _ (by positivity))
  have h2 : hold u d r q Δt (fun _ => K) s = Real.exp (-(r * Δt)) * K := by
    unfold hold; ring
  rw [h2] at h1
  have h3 : K - s ≤ putPayoff K s := le_max_left _ _
  nlinarith

-- The chart's exercise line for the put struck at $100: 40 at $60, 25 at $75, 0 at $100.
example : putPayoff 100 60 = 40 := by norm_num [putPayoff]
example : putPayoff 100 75 = 25 := by norm_num [putPayoff]
example : putPayoff 100 80 = 20 := by norm_num [putPayoff]
example : putPayoff 100 100 = 0 := by norm_num [putPayoff]

-- On the last date the option is worth its payoff: at $75 with nothing left to run, 25.
example (u d r q Δt : ℝ) : american (putPayoff 100) u d r q Δt 0 75 = 25 := by
  norm_num [american, putPayoff]

#print axioms american_call_eq_european_call_without_dividend
#print axioms american_ge_payoff_and_european
#print axioms american_put_exercise_region_nonempty

end AmericanTree
