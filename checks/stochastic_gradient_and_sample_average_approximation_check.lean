-- Stochastic gradient: a sample of n customers solved exactly misses the best fee by a mean square of at most σ²/(μ²n), which sets the sample size by Chebyshev, and stochastic gradient steps whose sum is unlimited and whose squares add to a finite total drive the mean-square error to zero.
import Mathlib.Analysis.Convex.Strong
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Analysis.Calculus.Deriv.Pow
import Mathlib.Analysis.Convex.Deriv
import Mathlib.Analysis.SpecificLimits.Basic
import Mathlib.Data.Fintype.Pi
import Mathlib.Algebra.Order.Floor.Semiring
import Mathlib.Tactic.NormNum

open Filter Topology

/-! ### How the card's objects are written here

The population is `N` customers, numbered by `Fin N`. Customer `i` has a loss `F i : ℝ → ℝ` in
the fee `p` (minus their monthly profit to the grocer), and its slope is `deriv (F i) p`. The
average loss is `f p = (∑ i, F i p) / N`, and `pstar` is a fee where it is smallest.

"Draw `n` customers at random" means: each of the `n` draws picks one of the `N` customers
uniformly, independently, with replacement. A sample is a list `s : Fin n → Fin N`, and all
`N ^ n` lists are equally likely. So the average `E[·]` over the random draws is the sum over all
lists divided by `N ^ n`, and the chance of an event is the number of lists in it divided by
`N ^ n`.

"Curves upward by at least `μ`" is Mathlib's `StrongConvexOn Set.univ μ`: for a twice
differentiable loss, the curvature is at least `μ` everywhere (here `2 b_i ≥ 0.8`).

The noise `σ²` is the average over the population of the square of each customer's slope at the
best fee, `(∑ i, (deriv (F i) pstar) ^ 2) / N`. -/

/-- The sample's average loss at the fee `q`: `f̂_n q = (∑ j, F (s j) q) / n`. -/
noncomputable def sampleLoss {N n : ℕ} (F : Fin N → ℝ → ℝ) (s : Fin n → Fin N) (q : ℝ) : ℝ :=
  (∑ j, F (s j) q) / n

theorem sc_first_order {F : ℝ → ℝ} {μ : ℝ} (hc : StrongConvexOn Set.univ μ F)
    (hd : Differentiable ℝ F) (x y : ℝ) :
    F x + deriv F x * (y - x) + μ / 2 * (y - x) ^ 2 ≤ F y := by
  have hconv := strongConvexOn_iff_convex.mp hc
  have heq : (fun x : ℝ ↦ F x - μ / (2 : ℝ) * ‖x‖ ^ 2) = fun x ↦ F x - μ / 2 * x ^ 2 := by
    funext z; simp [Real.norm_eq_abs, sq_abs]
  rw [heq] at hconv
  have hder : ∀ z, HasDerivAt (fun x : ℝ ↦ F x - μ / 2 * x ^ 2) (deriv F z - μ * z) z := by
    intro z
    have := (hd z).hasDerivAt.sub ((hasDerivAt_pow 2 z).const_mul (μ / 2))
    convert this using 1; push_cast; ring
  rcases lt_trichotomy x y with hxy | rfl | hxy
  · have h := hconv.le_slope_of_hasDerivAt (Set.mem_univ x) (Set.mem_univ y) hxy (hder x)
    rw [slope_def_field, le_div_iff₀ (by linarith)] at h
    nlinarith
  · simp
  · have h := hconv.slope_le_of_hasDerivAt (Set.mem_univ y) (Set.mem_univ x) hxy (hder x)
    rw [slope_def_field, div_le_iff₀ (by linarith)] at h
    nlinarith

#print axioms sc_first_order

theorem sum_sq_sample {N : ℕ} (g : Fin N → ℝ) (hg : ∑ i, g i = 0) (n : ℕ) :
    ∑ s : Fin n → Fin N, (∑ j, g (s j)) ^ 2 = n * (N : ℝ) ^ (n - 1) * ∑ i, g i ^ 2 := by
  induction n with
  | zero => simp
  | succ n ih =>
    rw [← (Fin.snocEquiv (fun _ => Fin N)).sum_comp, Fintype.sum_prod_type]
    simp only [Fin.snocEquiv_apply, Fin.sum_univ_castSucc, Fin.snoc_castSucc, Fin.snoc_last]
    have h1 : ∀ a : Fin N, ∑ t : Fin n → Fin N, (∑ j, g (t j) + g a) ^ 2
        = ∑ t : Fin n → Fin N, (∑ j, g (t j)) ^ 2
          + 2 * g a * ∑ t : Fin n → Fin N, ∑ j, g (t j) + (N : ℝ) ^ n * g a ^ 2 := by
      intro a
      have : ∀ t : Fin n → Fin N, (∑ j, g (t j) + g a) ^ 2
          = (∑ j, g (t j)) ^ 2 + 2 * g a * (∑ j, g (t j)) + g a ^ 2 := fun t => by ring
      simp only [this, Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_const,
        Finset.card_univ, Fintype.card_fun, Fintype.card_fin, nsmul_eq_mul]
      push_cast; ring
    simp only [h1, Finset.sum_add_distrib, ← Finset.sum_mul, ih, hg, ← Finset.mul_sum]
    simp only [Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul,
      Nat.add_sub_cancel]
    rcases n with _ | n
    · simp
    · simp only [Nat.add_sub_cancel]; push_cast; ring

#print axioms sum_sq_sample

theorem saa_pointwise {N n : ℕ} (F : Fin N → ℝ → ℝ) (μ : ℝ) (hμ : 0 < μ)
    (hconvex : ∀ i, StrongConvexOn Set.univ μ (F i)) (hslope : ∀ i, Differentiable ℝ (F i))
    (pstar : ℝ) (hn : 0 < n) (s : Fin n → Fin N) (ph : ℝ)
    (hph : ∀ q, sampleLoss F s ph ≤ sampleLoss F s q) :
    (n * μ * (ph - pstar)) ^ 2 ≤ (∑ j, deriv (F (s j)) pstar) ^ 2 := by
  have hnr : (0 : ℝ) < n := by exact_mod_cast hn
  have hmin : IsLocalMin (fun q => ∑ j, F (s j) q) ph := by
    refine Filter.Eventually.of_forall (fun q => ?_)
    have := hph q
    unfold sampleLoss at this
    exact (div_le_div_iff_of_pos_right hnr).mp this
  have hd0 := hmin.deriv_eq_zero
  rw [deriv_fun_sum (fun j _ => (hslope (s j)) ph)] at hd0
  have h1 : ∀ j, F (s j) pstar + deriv (F (s j)) pstar * (ph - pstar) + μ / 2 * (ph - pstar) ^ 2
      ≤ F (s j) ph := fun j => sc_first_order (hconvex _) (hslope _) _ _
  have h2 : ∀ j, F (s j) ph + deriv (F (s j)) ph * (pstar - ph) + μ / 2 * (pstar - ph) ^ 2
      ≤ F (s j) pstar := fun j => sc_first_order (hconvex _) (hslope _) _ _
  have s1 := Finset.sum_le_sum (fun j (_ : j ∈ Finset.univ) => h1 j)
  have s2 := Finset.sum_le_sum (fun j (_ : j ∈ Finset.univ) => h2 j)
  simp only [Finset.sum_add_distrib, ← Finset.sum_mul, Finset.sum_const, Finset.card_univ,
    Fintype.card_fin, nsmul_eq_mul, hd0] at s1 s2
  set T := ∑ j, deriv (F (s j)) pstar
  set d := ph - pstar
  have key : (n : ℝ) * μ * d ^ 2 ≤ - (T * d) := by
    have : (pstar - ph) ^ 2 = d ^ 2 := by simp only [d]; ring
    rw [this] at s2
    nlinarith
  have hc : 0 < (n : ℝ) * μ := mul_pos hnr hμ
  nlinarith [sq_nonneg (T + n * μ * d), mul_nonneg hc.le (sq_nonneg d)]

#print axioms saa_pointwise

/-- **Sample average approximation, the card's bound (Step 5).** Every customer's loss curves
upward by at least `μ > 0` and has a slope, `pstar` is the best fee for the whole population,
and for each sample `s` of `n ≥ 1` customers drawn at random, `phat s` is a best fee for the
sample's average loss. Then the sample's fee misses the best fee by a mean square of at most the
noise over `μ²` times `n`: `E[(p̂_n - p*)²] ≤ σ² / (μ² n)`. -/
theorem saa_mean_square_error_le {N n : ℕ} (F : Fin N → ℝ → ℝ) (μ : ℝ) (hμ : 0 < μ)
    (hconvex : ∀ i, StrongConvexOn Set.univ μ (F i)) (hslope : ∀ i, Differentiable ℝ (F i))
    (pstar : ℝ) (hpstar : ∀ q, (∑ i, F i pstar) / N ≤ (∑ i, F i q) / N)
    (hn : 0 < n) (phat : (Fin n → Fin N) → ℝ)
    (hphat : ∀ s q, sampleLoss F s (phat s) ≤ sampleLoss F s q) :
    (∑ s : Fin n → Fin N, (phat s - pstar) ^ 2) / (N : ℝ) ^ n ≤
      ((∑ i, (deriv (F i) pstar) ^ 2) / N) / (μ ^ 2 * n) := by
  rcases Nat.eq_zero_or_pos N with hN | hN
  · subst hN
    simp [zero_pow hn.ne']
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have hnr : (0 : ℝ) < n := by exact_mod_cast hn
  have hg : ∑ i, deriv (F i) pstar = 0 := by
    have hmin : IsLocalMin (fun q => ∑ i, F i q) pstar := by
      refine Filter.Eventually.of_forall (fun q => ?_)
      exact (div_le_div_iff_of_pos_right hNr).mp (hpstar q)
    have := hmin.deriv_eq_zero
    rwa [deriv_fun_sum (fun i _ => (hslope i) pstar)] at this
  have hb : ∀ s : Fin n → Fin N, (phat s - pstar) ^ 2
      ≤ (∑ j, deriv (F (s j)) pstar) ^ 2 / (n * μ) ^ 2 := by
    intro s
    rw [le_div_iff₀ (by positivity)]
    have := saa_pointwise F μ hμ hconvex hslope pstar hn s (phat s) (hphat s)
    nlinarith [this]
  have hsum := Finset.sum_le_sum (fun s (_ : s ∈ Finset.univ) => hb s)
  rw [← Finset.sum_div, sum_sq_sample (fun i => deriv (F i) pstar) hg n] at hsum
  have hpow : (N : ℝ) ^ n = N * N ^ (n - 1) := by
    rw [← pow_succ']; congr 1; omega
  rw [div_le_iff₀ (by positivity)]
  calc ∑ s : Fin n → Fin N, (phat s - pstar) ^ 2
      ≤ n * (N : ℝ) ^ (n - 1) * (∑ i, deriv (F i) pstar ^ 2) / (n * μ) ^ 2 := hsum
    _ = ((∑ i, (deriv (F i) pstar) ^ 2) / N) / (μ ^ 2 * n) * (N : ℝ) ^ n := by
      rw [hpow]; field_simp

/-- **Sample average approximation, the sample size (Step 5, by Chebyshev).** Under the same
conditions, take a tolerance `ε > 0` on the fee and an allowed chance `δ > 0` of missing it. If
the sample has `n ≥ σ² / (μ² ε² δ)` customers, then the chance that the sample's best fee misses
the best fee by `ε` or more is at most `δ`. (With `σ² = 3.3495`, `μ = 0.8`, `ε = £0.10` and
`δ = 0.05` this is the card's 10,468 customers.) -/
theorem saa_sample_size_guarantee {N n : ℕ} (F : Fin N → ℝ → ℝ) (μ : ℝ) (hμ : 0 < μ)
    (hconvex : ∀ i, StrongConvexOn Set.univ μ (F i)) (hslope : ∀ i, Differentiable ℝ (F i))
    (pstar : ℝ) (hpstar : ∀ q, (∑ i, F i pstar) / N ≤ (∑ i, F i q) / N)
    (hn : 0 < n) (phat : (Fin n → Fin N) → ℝ)
    (hphat : ∀ s q, sampleLoss F s (phat s) ≤ sampleLoss F s q)
    (ε δ : ℝ) (hε : 0 < ε) (hδ : 0 < δ)
    (hsize : ((∑ i, (deriv (F i) pstar) ^ 2) / N) / (μ ^ 2 * ε ^ 2 * δ) ≤ n) :
    ((Finset.univ.filter (fun s : Fin n → Fin N => ε ≤ |phat s - pstar|)).card : ℝ) /
      (N : ℝ) ^ n ≤ δ := by
  rcases Nat.eq_zero_or_pos N with hN | hN
  · subst hN
    simp [zero_pow hn.ne', hδ.le]
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have hnr : (0 : ℝ) < n := by exact_mod_cast hn
  have h1 := saa_mean_square_error_le F μ hμ hconvex hslope pstar hpstar hn phat hphat
  set σ := (∑ i, (deriv (F i) pstar) ^ 2) / N with hσ
  set S := ∑ s : Fin n → Fin N, (phat s - pstar) ^ 2
  set C := ((Finset.univ.filter (fun s : Fin n → Fin N => ε ≤ |phat s - pstar|)).card : ℝ)
  have hcheb : C * ε ^ 2 ≤ S := by
    calc C * ε ^ 2
        = ∑ s ∈ Finset.univ.filter (fun s : Fin n → Fin N => ε ≤ |phat s - pstar|), ε ^ 2 := by
          simp [C, Finset.sum_const, nsmul_eq_mul]
      _ ≤ ∑ s ∈ Finset.univ.filter (fun s : Fin n → Fin N => ε ≤ |phat s - pstar|),
            (phat s - pstar) ^ 2 := by
          apply Finset.sum_le_sum
          intro s hs
          rw [Finset.mem_filter] at hs
          have := pow_le_pow_left₀ hε.le hs.2 2
          rwa [sq_abs] at this
      _ ≤ S := Finset.sum_le_sum_of_subset_of_nonneg (Finset.filter_subset _ _)
            (fun _ _ _ => sq_nonneg _)
  have hpos : (0 : ℝ) < (N : ℝ) ^ n := by positivity
  have hS : S ≤ σ / (μ ^ 2 * n) * (N : ℝ) ^ n := (div_le_iff₀ hpos).mp h1
  have hsz : σ ≤ n * (μ ^ 2 * ε ^ 2 * δ) := (div_le_iff₀ (by positivity)).mp hsize
  rw [div_le_iff₀ hpos]
  have hε2 : 0 < ε ^ 2 := by positivity
  have : C * ε ^ 2 ≤ δ * (N : ℝ) ^ n * ε ^ 2 := by
    calc C * ε ^ 2 ≤ S := hcheb
      _ ≤ σ / (μ ^ 2 * n) * (N : ℝ) ^ n := hS
      _ ≤ (n * (μ ^ 2 * ε ^ 2 * δ)) / (μ ^ 2 * n) * (N : ℝ) ^ n := by
          gcongr
      _ = δ * (N : ℝ) ^ n * ε ^ 2 := by field_simp
  exact le_of_mul_le_mul_right this hε2

/-- The stochastic gradient fee after `k` steps, when the customers drawn at steps
`0, 1, …, k - 1` are `s 0, s 1, …, s (k - 1)`: start at `p₀`, and at step `k` move the fee by
`p_{k+1} = p_k - α_k g_k`, where `g_k = G (s k) p_k` is the drawn customer's slope at `p_k`. -/
noncomputable def sgdFee {N : ℕ} (G : Fin N → ℝ → ℝ) (α : ℕ → ℝ) (p₀ : ℝ) :
    (k : ℕ) → (Fin k → Fin N) → ℝ
  | 0, _ => p₀
  | k + 1, s =>
    let q := sgdFee G α p₀ k (fun j => s j.castSucc)
    q - α k * G (s (Fin.last k)) q

theorem det_upper {E α : ℕ → ℝ} {μ A : ℝ} (hμ : 0 < μ) (hE : ∀ k, 0 ≤ E k)
    (hα : ∀ k, 0 < α k)
    (hrec : ∀ k, E (k + 1) ≤ E k - μ * α k * E k + A * α k ^ 2) (k m : ℕ) :
    E (k + m) ≤ E k + A * ∑ j ∈ Finset.range m, α (j + k) ^ 2 := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Finset.sum_range_succ, ← add_assoc]
    have := hrec (k + m)
    have h2 : 0 ≤ μ * α (k + m) * E (k + m) := by
      have := hα (k + m); have := hE (k + m); positivity
    rw [add_comm m k]
    nlinarith

#print axioms det_upper

theorem det_frequently {E α : ℕ → ℝ} {μ A : ℝ} (hμ : 0 < μ) (hA : 0 ≤ A) (hE : ∀ k, 0 ≤ E k)
    (hα : ∀ k, 0 < α k) (hsum : ¬ Summable α) (hsq : Summable (fun k => α k ^ 2))
    (hrec : ∀ k, E (k + 1) ≤ E k - μ * α k * E k + A * α k ^ 2) (ε : ℝ) (hε : 0 < ε) (K : ℕ) :
    ∃ k, K ≤ k ∧ E k < ε := by
  by_contra hcon
  push Not at hcon
  apply hsum
  rw [← summable_nat_add_iff K]
  have hsq' : Summable (fun j => α (j + K) ^ 2) := (summable_nat_add_iff K).mpr hsq
  set T := ∑' j, α (j + K) ^ 2
  have step : ∀ j, α (j + K) * (μ * ε) ≤ E (j + K) - E (j + 1 + K) + A * α (j + K) ^ 2 := by
    intro j
    have h1 := hrec (j + K)
    have h2 := hcon (j + K) (by omega)
    have h3 := hα (j + K)
    rw [show j + 1 + K = j + K + 1 by omega]
    nlinarith [mul_le_mul_of_nonneg_left h2 (mul_pos hμ h3).le]
  refine summable_of_sum_range_le (c := (E K + A * T) / (μ * ε)) (fun j => (hα _).le) ?_
  intro m
  rw [le_div_iff₀ (mul_pos hμ hε), Finset.sum_mul]
  have hs := Finset.sum_le_sum (fun j (_ : j ∈ Finset.range m) => step j)
  rw [Finset.sum_add_distrib, Finset.sum_range_sub' (fun j => E (j + K)), ← Finset.mul_sum] at hs
  have hT : ∑ j ∈ Finset.range m, α (j + K) ^ 2 ≤ T :=
    hsq'.sum_le_tsum _ (fun j _ => sq_nonneg _)
  have := hE (m + K)
  simp only [zero_add] at hs
  nlinarith [mul_le_mul_of_nonneg_left hT hA]

#print axioms det_frequently

theorem det_tendsto {E α : ℕ → ℝ} {μ A : ℝ} (hμ : 0 < μ) (hA : 0 ≤ A) (hE : ∀ k, 0 ≤ E k)
    (hα : ∀ k, 0 < α k) (hsum : ¬ Summable α) (hsq : Summable (fun k => α k ^ 2))
    (hrec : ∀ k, E (k + 1) ≤ E k - μ * α k * E k + A * α k ^ 2) :
    Tendsto E atTop (𝓝 0) := by
  rw [Metric.tendsto_atTop]
  intro ε hε
  have htail := tendsto_sum_nat_add (fun j => α j ^ 2)
  have hev : ∀ᶠ k in atTop, A * ∑' j, α (j + k) ^ 2 < ε / 2 := by
    have : Tendsto (fun k => A * ∑' j, α (j + k) ^ 2) atTop (𝓝 (A * 0)) :=
      htail.const_mul A
    rw [mul_zero] at this
    exact this.eventually (gt_mem_nhds (by linarith))
  obtain ⟨K, hK⟩ := eventually_atTop.mp hev
  obtain ⟨k, hkK, hk⟩ := det_frequently hμ hA hE hα hsum hsq hrec (ε / 2) (by linarith) K
  refine ⟨k, fun m hm => ?_⟩
  have hup := det_upper hμ hE hα hrec k (m - k)
  rw [show k + (m - k) = m by omega] at hup
  have hsq' : Summable (fun j => α (j + k) ^ 2) := (summable_nat_add_iff k).mpr hsq
  have hT : ∑ j ∈ Finset.range (m - k), α (j + k) ^ 2 ≤ ∑' j, α (j + k) ^ 2 :=
    hsq'.sum_le_tsum _ (fun j _ => sq_nonneg _)
  have h3 := hK k hkK
  rw [Real.dist_eq, sub_zero, abs_of_nonneg (hE m)]
  nlinarith [mul_le_mul_of_nonneg_left hT hA]

#print axioms det_tendsto

theorem sgd_sum_succ {N : ℕ} (G : Fin N → ℝ → ℝ) (α : ℕ → ℝ) (p₀ pstar : ℝ) (k : ℕ) :
    ∑ s : Fin (k + 1) → Fin N, (sgdFee G α p₀ (k + 1) s - pstar) ^ 2 =
      ∑ t : Fin k → Fin N, ∑ a : Fin N,
        (sgdFee G α p₀ k t - α k * G a (sgdFee G α p₀ k t) - pstar) ^ 2 := by
  rw [← (Fin.snocEquiv (fun _ => Fin N)).sum_comp, Fintype.sum_prod_type, Finset.sum_comm]
  simp [sgdFee, Fin.snoc_castSucc, Fin.snoc_last]

#print axioms sgd_sum_succ

theorem sgd_inner {N : ℕ} (G : Fin N → ℝ → ℝ) (f : ℝ → ℝ)
    (pstar μf A B : ℝ)
    (hunbiased : ∀ p, (∑ i, G i p) / N = deriv f p)
    (hpull : ∀ p, μf * (p - pstar) ^ 2 ≤ deriv f p * (p - pstar))
    (hnoise : ∀ p, (∑ i, (G i p) ^ 2) / N ≤ A + B * (p - pstar) ^ 2)
    (hN : 0 < N) (a q : ℝ) (ha : 0 < a) :
    ∑ i : Fin N, (q - a * G i q - pstar) ^ 2 ≤
      N * ((1 - 2 * a * μf + a ^ 2 * max B 0) * (q - pstar) ^ 2 + a ^ 2 * A) := by
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have h1 : ∑ i, G i q = N * deriv f q := by
    have := hunbiased q; field_simp at this; linarith
  have h2 : ∑ i, (G i q) ^ 2 ≤ N * (A + B * (q - pstar) ^ 2) := by
    have := hnoise q; rw [div_le_iff₀ hNr] at this; linarith
  have h3 := hpull q
  have hexp : ∑ i : Fin N, (q - a * G i q - pstar) ^ 2 =
      N * (q - pstar) ^ 2 - 2 * a * (q - pstar) * ∑ i, G i q + a ^ 2 * ∑ i, (G i q) ^ 2 := by
    have : ∀ i : Fin N, (q - a * G i q - pstar) ^ 2 =
        (q - pstar) ^ 2 - 2 * a * (q - pstar) * G i q + a ^ 2 * (G i q) ^ 2 := fun i => by ring
    simp only [this, Finset.sum_add_distrib, Finset.sum_sub_distrib, ← Finset.mul_sum,
      Finset.sum_const, Finset.card_univ, Fintype.card_fin, nsmul_eq_mul]
  rw [hexp, h1]
  have hB : B * (q - pstar) ^ 2 ≤ max B 0 * (q - pstar) ^ 2 :=
    mul_le_mul_of_nonneg_right (le_max_left _ _) (sq_nonneg _)
  have ha2 : 0 ≤ a ^ 2 := sq_nonneg a
  nlinarith [mul_le_mul_of_nonneg_left h3 (mul_pos hNr ha).le, mul_le_mul_of_nonneg_left h2 ha2,
    mul_le_mul_of_nonneg_left hB (mul_nonneg hNr.le ha2)]

#print axioms sgd_inner

/-- **Robbins-Monro, mean-square form (Step 4).** Each step draws one of `N` customers uniformly
at random, independently, and `G i p` is customer `i`'s slope at the fee `p`. Suppose:
* the slope drawn is unbiased: its average over the customers is the slope `f' p` of the
  average loss `f`;
* the average loss pulls the error in at a rate at least `μf > 0`:
  `f' p · (p - p*) ≥ μf (p - p*)²`;
* the drawn slope's mean square is at most `A + B (p - p*)²`;
* the steps are positive, add up to an unlimited distance (`∑ α_k = ∞`, so not summable), and
  their squares add up to a finite total.
Then from any starting fee `p₀`, the mean-square error `E[(p_k - p*)²]`, averaged over all
`N ^ k` equally likely lists of the first `k` draws, tends to zero. -/
theorem robbins_monro_mean_square_tendsto_zero {N : ℕ} (G : Fin N → ℝ → ℝ) (f : ℝ → ℝ)
    (pstar μf A B : ℝ) (hμf : 0 < μf)
    (hunbiased : ∀ p, (∑ i, G i p) / N = deriv f p)
    (hpull : ∀ p, μf * (p - pstar) ^ 2 ≤ deriv f p * (p - pstar))
    (hnoise : ∀ p, (∑ i, (G i p) ^ 2) / N ≤ A + B * (p - pstar) ^ 2)
    (α : ℕ → ℝ) (hpos : ∀ k, 0 < α k) (hsum : ¬ Summable α)
    (hsq : Summable (fun k => α k ^ 2)) (p₀ : ℝ) :
    Tendsto (fun k => (∑ s : Fin k → Fin N, (sgdFee G α p₀ k s - pstar) ^ 2) / (N : ℝ) ^ k)
      atTop (𝓝 0) := by
  have hN : 0 < N := by
    rcases Nat.eq_zero_or_pos N with h | h
    · subst h
      have h1 := hunbiased (pstar + 1)
      have h2 := hpull (pstar + 1)
      simp at h1
      rw [← h1] at h2
      norm_num at h2
      linarith
    · exact h
  have hNr : (0 : ℝ) < N := by exact_mod_cast hN
  have hA : 0 ≤ A := by
    have h := hnoise pstar
    simp only [sub_self, ne_eq, OfNat.ofNat_ne_zero, not_false_eq_true, zero_pow, mul_zero,
      add_zero] at h
    exact le_trans (by positivity) h
  set E : ℕ → ℝ := fun k =>
    (∑ s : Fin k → Fin N, (sgdFee G α p₀ k s - pstar) ^ 2) / (N : ℝ) ^ k with hEdef
  set B' := max B 0 with hB'
  have hB'0 : 0 ≤ B' := le_max_right _ _
  have hE0 : ∀ k, 0 ≤ E k := fun k => by
    simp only [hEdef]; positivity
  have hrec : ∀ k, E (k + 1) ≤ (1 - 2 * α k * μf + α k ^ 2 * B') * E k + α k ^ 2 * A := by
    intro k
    simp only [hEdef]
    rw [sgd_sum_succ]
    have hin := fun t : Fin k → Fin N =>
      sgd_inner G f pstar μf A B hunbiased hpull hnoise hN (α k) (sgdFee G α p₀ k t) (hpos k)
    have hs := Finset.sum_le_sum (fun t (_ : t ∈ Finset.univ) => hin t)
    rw [← Finset.mul_sum, Finset.sum_add_distrib, ← Finset.mul_sum, Finset.sum_const,
      Finset.card_univ, Fintype.card_fun, Fintype.card_fin, nsmul_eq_mul] at hs
    have hpk : (0 : ℝ) < (N : ℝ) ^ k := by positivity
    rw [div_le_iff₀ (by positivity)]
    simp only [Fintype.card_fin, ← hB'] at hs
    generalize (∑ s : Fin k → Fin N, (sgdFee G α p₀ k s - pstar) ^ 2) = S at hs ⊢
    calc _ ≤ _ := hs
      _ = _ := by push_cast; field_simp; ring
  -- eventually the step is small
  have hev : ∀ᶠ k in atTop, α k ^ 2 < μf ^ 2 / (B' + 1) ^ 2 :=
    hsq.tendsto_atTop_zero.eventually (gt_mem_nhds (by positivity))
  obtain ⟨K, hK⟩ := eventually_atTop.mp hev
  have hsmall : ∀ k, K ≤ k → α k * B' ≤ μf := by
    intro k hk
    have h := hK k hk
    rw [lt_div_iff₀ (by positivity)] at h
    have hak := hpos k
    have : α k * (B' + 1) < μf := by nlinarith [mul_pos hak (by linarith : (0:ℝ) < B' + 1)]
    nlinarith
  rw [← tendsto_add_atTop_iff_nat K]
  refine det_tendsto (E := fun j => E (j + K)) (α := fun j => α (j + K)) (μ := μf) (A := A)
    hμf hA (fun j => hE0 _) (fun j => hpos _) ?_ ?_ ?_
  · rwa [summable_nat_add_iff K]
  · exact (summable_nat_add_iff K).mpr hsq
  · intro j
    have h1 := hrec (j + K)
    have h2 := hsmall (j + K) (by omega)
    have h3 := hE0 (j + K)
    have h4 := hpos (j + K)
    rw [show j + 1 + K = j + K + 1 by omega]
    have : α (j + K) ^ 2 * B' * E (j + K) ≤ α (j + K) * μf * E (j + K) := by
      have := mul_le_mul_of_nonneg_left h2 (mul_nonneg h4.le h3)
      nlinarith
    nlinarith

/-! ### The card's worked numbers, checked exactly

The card's inputs `σ² = 3.3495`, `μ = 0.8`, `ε = £0.10`, `δ = 0.05` are written as exact
fractions. -/

/-- The SAA bound at `n = 1,000`: `3.3495 ÷ (0.8² × 1,000) = 0.0052336 (to 7 places)`, which the
card rounds to 0.005234. -/
example : (33495 / 10000 : ℚ) / ((8 / 10) ^ 2 * 1000) = 33495 / 6400000 ∧
    (33495 / 6400000 : ℚ) - 5234 / 1000000 < 1 / 2000000 ∧
    5234 / 1000000 - (33495 / 6400000 : ℚ) < 1 / 2000000 := by
  norm_num

/-- Customers for ±£0.10 with 95%: `3.3495 ÷ (0.64 × 0.01 × 0.05) = 10,467.1875`, rounded up to
10,468. -/
example : (33495 / 10000 : ℚ) / ((8 / 10) ^ 2 * (1 / 10) ^ 2 * (5 / 100)) = 167475 / 16 ∧
    ⌈(33495 / 10000 : ℚ) / ((8 / 10) ^ 2 * (1 / 10) ^ 2 * (5 / 100))⌉ = 10468 := by
  norm_num [Int.ceil_eq_iff]

/-- Try changing: with `μ = 0.4`, or with `ε = £0.05`, the sample size grows to 41,869. -/
example : ⌈(33495 / 10000 : ℚ) / ((4 / 10) ^ 2 * (1 / 10) ^ 2 * (5 / 100))⌉ = 41869 ∧
    ⌈(33495 / 10000 : ℚ) / ((8 / 10) ^ 2 * (5 / 100) ^ 2 * (5 / 100))⌉ = 41869 := by
  norm_num [Int.ceil_eq_iff]

#print axioms saa_mean_square_error_le
#print axioms saa_sample_size_guarantee
#print axioms robbins_monro_mean_square_tendsto_zero
