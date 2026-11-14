-- EM: one round of EM on a two-bell (two-normal) mixture never lowers the log-likelihood, and the lower bound behind it never sits above ln(a + b) and touches it exactly at the E-step's responsibilities.
import Mathlib.Probability.Distributions.Gaussian.Real

open Real ProbabilityTheory
open scoped NNReal

namespace EMCard

lemma log_gauss_eq (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0) (x : ℝ) :
    Real.log (gaussianPDFReal μ v x) =
      -(1 / 2) * Real.log (2 * π) - (1 / 2) * Real.log (v : ℝ) - (x - μ) ^ 2 / (2 * v) := by
  have hv' : (0 : ℝ) < v := NNReal.coe_pos.2 (pos_iff_ne_zero.2 hv)
  have h2 : (0 : ℝ) < 2 * π := by positivity
  rw [gaussianPDFReal, Real.log_mul (inv_ne_zero (Real.sqrt_ne_zero'.2 (by positivity)))
    (Real.exp_pos _).ne', Real.log_inv, Real.log_exp, Real.log_sqrt (by positivity),
    Real.log_mul h2.ne' hv'.ne']
  ring

#print axioms log_gauss_eq

lemma fit_var_pos {n : ℕ} (w x : Fin n → ℝ) (hw : ∀ i, 0 < w i) (hx : ∃ i j, x i ≠ x j) :
    0 < (∑ i, w i * (x i - (∑ i, w i * x i) / ∑ i, w i) ^ 2) / ∑ i, w i := by
  obtain ⟨i₀, j₀, hij⟩ := hx
  have hW : 0 < ∑ i, w i := Finset.sum_pos (fun i _ => hw i) ⟨i₀, Finset.mem_univ _⟩
  apply div_pos _ hW
  set m := (∑ i, w i * x i) / ∑ i, w i
  have hnn : ∀ i ∈ (Finset.univ : Finset (Fin n)), 0 ≤ w i * (x i - m) ^ 2 :=
    fun i _ => mul_nonneg (hw i).le (sq_nonneg _)
  have key : ∀ k, x k ≠ m → 0 < ∑ i, w i * (x i - m) ^ 2 := by
    intro k hk
    calc 0 < w k * (x k - m) ^ 2 := mul_pos (hw k) (by
            have : x k - m ≠ 0 := sub_ne_zero.2 hk
            positivity)
      _ ≤ ∑ i, w i * (x i - m) ^ 2 :=
          Finset.single_le_sum (f := fun i => w i * (x i - m) ^ 2) hnn (Finset.mem_univ k)
  by_cases h : x i₀ = m
  · exact key j₀ (fun h' => hij (h.trans h'.symm))
  · exact key i₀ h

#print axioms fit_var_pos

lemma fit_var_ne_zero {n : ℕ} (w x : Fin n → ℝ) (hw : ∀ i, 0 < w i) (hx : ∃ i j, x i ≠ x j) :
    Real.toNNReal ((∑ i, w i * (x i - (∑ i, w i * x i) / ∑ i, w i) ^ 2) / ∑ i, w i) ≠ 0 := by
  have := fit_var_pos w x hw hx
  simpa [Real.toNNReal_eq_zero, not_le] using this

#print axioms fit_var_ne_zero

lemma gauss_fit_le {n : ℕ} (w x : Fin n → ℝ) (hw : ∀ i, 0 < w i) (hx : ∃ i j, x i ≠ x j)
    (μ : ℝ) (v : ℝ≥0) (hv : v ≠ 0) :
    ∑ i, w i * Real.log (gaussianPDFReal μ v (x i)) ≤
      ∑ i, w i * Real.log (gaussianPDFReal ((∑ i, w i * x i) / ∑ i, w i)
        (Real.toNNReal ((∑ i, w i * (x i - (∑ i, w i * x i) / ∑ i, w i) ^ 2) / ∑ i, w i))
        (x i)) := by
  have hvsNN := fit_var_ne_zero w x hw hx
  have hvs_pos := fit_var_pos w x hw hx
  obtain ⟨i₀, -, -⟩ := hx
  have hW : 0 < ∑ i, w i := Finset.sum_pos (fun i _ => hw i) ⟨i₀, Finset.mem_univ _⟩
  have hvpos : (0 : ℝ) < v := NNReal.coe_pos.2 (pos_iff_ne_zero.2 hv)
  simp only [log_gauss_eq _ _ hv, log_gauss_eq _ _ hvsNN, Real.coe_toNNReal _ hvs_pos.le]
  set W := ∑ i, w i with hWdef
  set m := (∑ i, w i * x i) / W with hm
  set S0 := ∑ i, w i * (x i - m) ^ 2 with hS0
  set vs := S0 / W with hvs
  have key : ∀ (μ' : ℝ) (v' : ℝ), ∑ i, w i * (-(1 / 2) * Real.log (2 * π) - (1 / 2) *
      Real.log v' - (x i - μ') ^ 2 / (2 * v')) =
      W * (-(1 / 2) * Real.log (2 * π) - (1 / 2) * Real.log v') -
        (∑ i, w i * (x i - μ') ^ 2) / (2 * v') := by
    intro μ' v'
    rw [hWdef, Finset.sum_mul, Finset.sum_div, ← Finset.sum_sub_distrib]
    refine Finset.sum_congr rfl (fun i _ => ?_)
    ring
  have hsum : ∑ i, w i * x i = m * W := by rw [hm]; field_simp
  have hSμ : ∑ i, w i * (x i - μ) ^ 2 = S0 + W * (m - μ) ^ 2 := by
    have : ∀ i, w i * (x i - μ) ^ 2 = w i * (x i - m) ^ 2 + 2 * (m - μ) * (w i * x i)
        - 2 * (m - μ) * m * w i + (m - μ) ^ 2 * w i := fun i => by ring
    simp only [this, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      hsum]
    rw [← hWdef, ← hS0]
    ring
  rw [key, key, hSμ]
  have hS0eq : S0 = W * vs := by rw [hvs]; field_simp
  have hlog : Real.log (vs / v) ≤ vs / v - 1 :=
    Real.log_le_sub_one_of_pos (div_pos hvs_pos hvpos)
  rw [Real.log_div hvs_pos.ne' hvpos.ne'] at hlog
  rw [← hS0, hS0eq]
  have h1 : W * vs / (2 * v) ≤ (W * vs + W * (m - μ) ^ 2) / (2 * v) := by
    apply div_le_div_of_nonneg_right _ (by positivity)
    nlinarith [sq_nonneg (m - μ)]
  have h2 : W * vs / (2 * vs) = W / 2 := by field_simp
  have h3 : W * vs / (2 * v) = W / 2 * (vs / v) := by ring
  rw [h2]
  rw [h3] at h1
  nlinarith [mul_le_mul_of_nonneg_left hlog hW.le]

#print axioms gauss_fit_le

lemma mix_le {n₁ n₂ a : ℝ} (h₁ : 0 < n₁) (h₂ : 0 < n₂) (ha₀ : 0 < a) (ha₁ : a < 1) :
    n₁ * Real.log (1 - a) + n₂ * Real.log a ≤
      n₁ * Real.log (n₁ / (n₁ + n₂)) + n₂ * Real.log (n₂ / (n₁ + n₂)) := by
  have hN : 0 < n₁ + n₂ := by linarith
  have h1a : 0 < 1 - a := by linarith
  have e1 := Real.log_le_sub_one_of_pos (show 0 < (1 - a) * (n₁ + n₂) / n₁ by positivity)
  have e2 := Real.log_le_sub_one_of_pos (show 0 < a * (n₁ + n₂) / n₂ by positivity)
  rw [Real.log_div (by positivity) h₁.ne', Real.log_mul h1a.ne' hN.ne'] at e1
  rw [Real.log_div (by positivity) h₂.ne', Real.log_mul ha₀.ne' hN.ne'] at e2
  rw [Real.log_div h₁.ne' hN.ne', Real.log_div h₂.ne' hN.ne']
  have hz : n₁ * ((1 - a) * (n₁ + n₂) / n₁ - 1) + n₂ * (a * (n₁ + n₂) / n₂ - 1) = 0 := by
    field_simp; ring
  nlinarith [mul_le_mul_of_nonneg_left e1 h₁.le, mul_le_mul_of_nonneg_left e2 h₂.le]

#print axioms mix_le

lemma two_point_jensen {a b r₁ r₂ : ℝ} (ha : 0 < a) (hb : 0 < b)
    (hr₁ : 0 < r₁) (hr₂ : 0 < r₂) (hr : r₁ + r₂ = 1) :
    r₁ * Real.log (a / r₁) + r₂ * Real.log (b / r₂) ≤ Real.log (a + b) := by
  have h := strictConcaveOn_log_Ioi.concaveOn.2 (Set.mem_Ioi.2 (div_pos ha hr₁))
    (Set.mem_Ioi.2 (div_pos hb hr₂)) hr₁.le hr₂.le hr
  simp only [smul_eq_mul] at h
  have e : r₁ * (a / r₁) + r₂ * (b / r₂) = a + b := by field_simp
  rwa [e] at h

#print axioms two_point_jensen

lemma em_step_term {A B A' B' : ℝ} (hA : 0 < A) (hB : 0 < B) (hA' : 0 < A') (hB' : 0 < B') :
    (1 - B / (A + B)) * (Real.log A' - Real.log A) + B / (A + B) * (Real.log B' - Real.log B) ≤
      Real.log (A' + B') - Real.log (A + B) := by
  have hs : 0 < A + B := by linarith
  have h := two_point_jensen hA' hB' (div_pos hA hs) (div_pos hB hs) (by field_simp)
  rw [Real.log_div hA'.ne' (div_pos hA hs).ne', Real.log_div hA.ne' hs.ne',
    Real.log_div hB'.ne' (div_pos hB hs).ne', Real.log_div hB.ne' hs.ne'] at h
  have e1 : 1 - B / (A + B) = A / (A + B) := by field_simp; ring
  have e2 : A / (A + B) + B / (A + B) = 1 := by field_simp
  rw [e1]
  linear_combination h - Real.log (A + B) * e2

#print axioms em_step_term


/-- The five numbers of a two-bell fit: the weekly share `α` (so the top-up share is `1 - α`),
the top-up bell's mean `μ₁` and variance `v₁ = σ₁²`, and the weekly bell's mean `μ₂` and
variance `v₂ = σ₂²`. -/
structure Params where
  α : ℝ
  μ₁ : ℝ
  v₁ : ℝ≥0
  μ₂ : ℝ
  v₂ : ℝ≥0

/-- The log-likelihood `ℓ(θ) = Σᵢ ln(α₁ f(xᵢ; μ₁, σ₁) + α₂ f(xᵢ; μ₂, σ₂))`, with Mathlib's normal
density `gaussianPDFReal` (mean, variance) as the bell height `f`. -/
noncomputable def loglik {n : ℕ} (x : Fin n → ℝ) (θ : Params) : ℝ :=
  ∑ i, Real.log ((1 - θ.α) * gaussianPDFReal θ.μ₁ θ.v₁ (x i) +
    θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i))

/-- E-step: the responsibility `rᵢ₂`, the chance under `θ` that order `i` came from the weekly
bell (Bayes' rule: share times height over the total). The top-up responsibility is `1 - rᵢ₂`. -/
noncomputable def resp {n : ℕ} (x : Fin n → ℝ) (θ : Params) (i : Fin n) : ℝ :=
  θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i) /
    ((1 - θ.α) * gaussianPDFReal θ.μ₁ θ.v₁ (x i) + θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i))

/-- One EM round: the E-step responsibilities, then the M-step
`n_k = Σ r_ik`, `α_k = n_k / n`, `μ_k = Σ r_ik xᵢ / n_k`, `σ_k² = Σ r_ik (xᵢ - μ_k)² / n_k`. -/
noncomputable def emRound {n : ℕ} (x : Fin n → ℝ) (θ : Params) : Params :=
  let r := resp x θ
  let n₂ := ∑ i, r i
  let n₁ := ∑ i, (1 - r i)
  let μ₁ := (∑ i, (1 - r i) * x i) / n₁
  let μ₂ := (∑ i, r i * x i) / n₂
  { α := n₂ / n
    μ₁ := μ₁
    v₁ := Real.toNNReal ((∑ i, (1 - r i) * (x i - μ₁) ^ 2) / n₁)
    μ₂ := μ₂
    v₂ := Real.toNNReal ((∑ i, r i * (x i - μ₂) ^ 2) / n₂) }

/-- EM climbs: for any spends `x₁, …, xₙ` and any current fit with both shares positive and both
spreads positive, one EM round (E-step, then M-step) gives a log-likelihood at least as high as
before. The one hypothesis on the data, that not every order has the same spend, is the card's
"no bell may shrink onto a single order": without it the M-step's spreads come out zero. -/
theorem em_round_never_lowers_loglik {n : ℕ} (x : Fin n → ℝ) (θ : Params)
    (hα₀ : 0 < θ.α) (hα₁ : θ.α < 1) (hv₁ : θ.v₁ ≠ 0) (hv₂ : θ.v₂ ≠ 0)
    (hx : ∃ i j, x i ≠ x j) :
    loglik x θ ≤ loglik x (emRound x θ) := by
  have hx' := hx
  classical
  set r := resp x θ with hr_def
  have hf₁ : ∀ i, 0 < gaussianPDFReal θ.μ₁ θ.v₁ (x i) := fun i => gaussianPDFReal_pos _ _ _ hv₁
  have hf₂ : ∀ i, 0 < gaussianPDFReal θ.μ₂ θ.v₂ (x i) := fun i => gaussianPDFReal_pos _ _ _ hv₂
  have h1α : 0 < 1 - θ.α := by linarith
  have hA : ∀ i, 0 < (1 - θ.α) * gaussianPDFReal θ.μ₁ θ.v₁ (x i) := fun i => mul_pos h1α (hf₁ i)
  have hB : ∀ i, 0 < θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i) := fun i => mul_pos hα₀ (hf₂ i)
  have hr_eq : ∀ i, r i = θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i) /
      ((1 - θ.α) * gaussianPDFReal θ.μ₁ θ.v₁ (x i) + θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i)) :=
    fun i => rfl
  have hr0 : ∀ i, 0 < r i := fun i => by
    rw [hr_eq]; exact div_pos (hB i) (by linarith [hA i, hB i])
  have hr1 : ∀ i, r i < 1 := fun i => by
    rw [hr_eq, div_lt_one (by linarith [hA i, hB i])]; linarith [hA i]
  have hw₁ : ∀ i, 0 < 1 - r i := fun i => by linarith [hr1 i]
  obtain ⟨i₀, -, -⟩ := hx
  have hn₂ : 0 < ∑ i, r i := Finset.sum_pos (fun i _ => hr0 i) ⟨i₀, Finset.mem_univ _⟩
  have hn₁ : 0 < ∑ i, (1 - r i) := Finset.sum_pos (fun i _ => hw₁ i) ⟨i₀, Finset.mem_univ _⟩
  have hN : ∑ i, (1 - r i) + ∑ i, r i = (n : ℝ) := by
    rw [← Finset.sum_add_distrib]; simp
  have hnpos : (0 : ℝ) < n := by rw [← hN]; linarith
  set θ' := emRound x θ with hθ'
  have hα' : θ'.α = (∑ i, r i) / n := rfl
  have hα'pos : 0 < θ'.α := by rw [hα']; exact div_pos hn₂ hnpos
  have h1α' : 1 - θ'.α = (∑ i, (1 - r i)) / n := by
    rw [hα']; field_simp; linarith
  have h1α'pos : 0 < 1 - θ'.α := by rw [h1α']; exact div_pos hn₁ hnpos
  have hv₁' : θ'.v₁ ≠ 0 := fit_var_ne_zero (fun i => 1 - r i) x hw₁ hx'
  have hv₂' : θ'.v₂ ≠ 0 := fit_var_ne_zero r x hr0 hx'
  have hf₁' : ∀ i, 0 < gaussianPDFReal θ'.μ₁ θ'.v₁ (x i) := fun i => gaussianPDFReal_pos _ _ _ hv₁'
  have hf₂' : ∀ i, 0 < gaussianPDFReal θ'.μ₂ θ'.v₂ (x i) := fun i => gaussianPDFReal_pos _ _ _ hv₂'
  have hA' : ∀ i, 0 < (1 - θ'.α) * gaussianPDFReal θ'.μ₁ θ'.v₁ (x i) :=
    fun i => mul_pos h1α'pos (hf₁' i)
  have hB' : ∀ i, 0 < θ'.α * gaussianPDFReal θ'.μ₂ θ'.v₂ (x i) := fun i => mul_pos hα'pos (hf₂' i)
  -- the three M-step gains
  have hQ₁ : ∑ i, (1 - r i) * Real.log (gaussianPDFReal θ.μ₁ θ.v₁ (x i)) ≤
      ∑ i, (1 - r i) * Real.log (gaussianPDFReal θ'.μ₁ θ'.v₁ (x i)) :=
    gauss_fit_le (fun i => 1 - r i) x hw₁ hx' θ.μ₁ θ.v₁ hv₁
  have hQ₂ : ∑ i, r i * Real.log (gaussianPDFReal θ.μ₂ θ.v₂ (x i)) ≤
      ∑ i, r i * Real.log (gaussianPDFReal θ'.μ₂ θ'.v₂ (x i)) :=
    gauss_fit_le r x hr0 hx' θ.μ₂ θ.v₂ hv₂
  have hQ₀ : (∑ i, (1 - r i)) * Real.log (1 - θ.α) + (∑ i, r i) * Real.log θ.α ≤
      (∑ i, (1 - r i)) * Real.log (1 - θ'.α) + (∑ i, r i) * Real.log θ'.α := by
    have := mix_le hn₁ hn₂ hα₀ hα₁
    rw [hN] at this
    rw [h1α', hα']
    exact this
  -- the E-step bound, term by term
  have hstep : ∀ i,
      (1 - r i) * Real.log (1 - θ'.α) + r i * Real.log θ'.α
        - ((1 - r i) * Real.log (1 - θ.α) + r i * Real.log θ.α)
      + ((1 - r i) * Real.log (gaussianPDFReal θ'.μ₁ θ'.v₁ (x i))
        - (1 - r i) * Real.log (gaussianPDFReal θ.μ₁ θ.v₁ (x i)))
      + (r i * Real.log (gaussianPDFReal θ'.μ₂ θ'.v₂ (x i))
        - r i * Real.log (gaussianPDFReal θ.μ₂ θ.v₂ (x i))) ≤
      Real.log ((1 - θ'.α) * gaussianPDFReal θ'.μ₁ θ'.v₁ (x i) +
          θ'.α * gaussianPDFReal θ'.μ₂ θ'.v₂ (x i)) -
        Real.log ((1 - θ.α) * gaussianPDFReal θ.μ₁ θ.v₁ (x i) +
          θ.α * gaussianPDFReal θ.μ₂ θ.v₂ (x i)) := by
    intro i
    have h := em_step_term (hA i) (hB i) (hA' i) (hB' i)
    rw [← hr_eq i] at h
    rw [Real.log_mul h1α'pos.ne' (hf₁' i).ne', Real.log_mul hα'pos.ne' (hf₂' i).ne',
      Real.log_mul h1α.ne' (hf₁ i).ne', Real.log_mul hα₀.ne' (hf₂ i).ne'] at h
    linarith
  have hsum := Finset.sum_le_sum (fun i (_ : i ∈ (Finset.univ : Finset (Fin n))) => hstep i)
  simp only [Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.sum_mul] at hsum
  simp only [Finset.sum_sub_distrib] at hQ₀
  unfold loglik
  linarith

/-- The lower bound (Jensen for the logarithm): for positive parts `a`, `b` and any two positive
weights `r₁`, `r₂` that add to 1, `ln(a + b) ≥ r₁ ln(a / r₁) + r₂ ln(b / r₂)`. -/
theorem log_add_ge_weighted_bound {a b r₁ r₂ : ℝ} (ha : 0 < a) (hb : 0 < b)
    (hr₁ : 0 < r₁) (hr₂ : 0 < r₂) (hr : r₁ + r₂ = 1) :
    r₁ * Real.log (a / r₁) + r₂ * Real.log (b / r₂) ≤ Real.log (a + b) := by
  exact two_point_jensen ha hb hr₁ hr₂ hr

/-- The bound touches the curve exactly at the E-step's responsibilities: equality holds in
`ln(a + b) ≥ r₁ ln(a / r₁) + r₂ ln(b / r₂)` exactly when `r₁ = a / (a + b)` and `r₂ = b / (a + b)`. -/
theorem weighted_bound_eq_iff_responsibilities {a b r₁ r₂ : ℝ} (ha : 0 < a) (hb : 0 < b)
    (hr₁ : 0 < r₁) (hr₂ : 0 < r₂) (hr : r₁ + r₂ = 1) :
    r₁ * Real.log (a / r₁) + r₂ * Real.log (b / r₂) = Real.log (a + b) ↔
      r₁ = a / (a + b) ∧ r₂ = b / (a + b) := by
  have hs : 0 < a + b := by linarith
  constructor
  · intro heq
    have hxy : a / r₁ = b / r₂ := by
      by_contra hne
      have h := strictConcaveOn_log_Ioi.2 (Set.mem_Ioi.2 (div_pos ha hr₁))
        (Set.mem_Ioi.2 (div_pos hb hr₂)) hne hr₁ hr₂ hr
      simp only [smul_eq_mul] at h
      have e : r₁ * (a / r₁) + r₂ * (b / r₂) = a + b := by field_simp
      rw [e] at h
      linarith
    have ha' : a = (a / r₁) * r₁ := by field_simp
    have hb' : b = (a / r₁) * r₂ := by rw [hxy]; field_simp
    have hab : a + b = a / r₁ := by
      calc a + b = (a / r₁) * (r₁ + r₂) := by rw [mul_add, ← ha', ← hb']
        _ = a / r₁ := by rw [hr, mul_one]
    have ht : 0 < a / r₁ := div_pos ha hr₁
    constructor
    · rw [hab]; field_simp
    · rw [hab, hb']; field_simp
  · rintro ⟨h₁, h₂⟩
    have e₁ : a / r₁ = a + b := by rw [h₁]; field_simp
    have e₂ : b / r₂ = a + b := by rw [h₂]; field_simp
    rw [e₁, e₂, ← add_mul, hr, one_mul]

-- Worked numbers from the card's six orders (£15, £22, £28, £40, £60, £75; centres £20 and £60).
-- The gap in squared distances behind the odds: (x - 20)² - (x - 60)² = 80x - 3200.
example (x : ℝ) : (x - 20) ^ 2 - (x - 60) ^ 2 = 80 * x - 3200 := by ring
-- Divided by 2σ² = 200, that is 0.4 (x - 40), so the odds are e^(0.4 (x - 40)).
example (x : ℝ) : (80 * x - 3200) / 200 = 2 / 5 * (x - 40) := by ring
-- At £40 the odds are e⁰ = 1, so r = 1 / (1 + 1) = 1/2: the order is split evenly.
example : Real.exp (2 / 5 * ((40 : ℝ) - 40)) / (1 + Real.exp (2 / 5 * ((40 : ℝ) - 40))) = 1 / 2 := by
  norm_num
-- The six spends add to £240, which the M-step splits as £155.225462 weekly and £84.774538 top-up.
example : (15 : ℕ) + 22 + 28 + 40 + 60 + 75 = 240 := by decide
example : (155225462 : ℕ) + 84774538 = 240 * 10 ^ 6 := by decide

#print axioms em_round_never_lowers_loglik
#print axioms log_add_ge_weighted_bound
#print axioms weighted_bound_eq_iff_responsibilities

end EMCard
