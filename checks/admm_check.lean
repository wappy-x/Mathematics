-- ADMM: for two closed, proper, convex halves whose plain Lagrangian has a saddle point, the ADMM rounds keep the penalty's optimality condition exactly, drive the copies' gap and the penalty copy's move to zero, and bring the cost to the optimum and the price to an optimal price; and the card's five-holding lasso answer is optimal.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Analysis.Convex.Function
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Tactic.NormNum
import Mathlib.Topology.MetricSpace.Sequences

open Filter Topology RealInnerProductSpace Matrix

/-! ### How the card's objects are written here

The unknowns are lists of `n` real numbers, `EuclideanSpace ℝ (Fin n)`, with the usual length
`‖v‖` and dot product `⟪v, w⟫`.

A function that may take the value +∞ is written as a real function `f` together with the set
`Df` where it is finite. Then:
* proper: `Df` is not empty (and `f` is never −∞, automatic for a real function);
* convex: `ConvexOn ℝ Df f` (the set `Df` is convex and `f` never dips below a chord on it);
* closed: the epigraph `{(v, t) | v ∈ Df ∧ f v ≤ t}` is a closed set.

ADMM in scaled form, for `k = 0, 1, 2, …`, from any starting `x 0`, `z 0`, `u 0`:
* `x (k+1)` minimises `f v + ρ/2 ‖v - z k + u k‖²` over `v ∈ Df` (the fit half, solved exactly);
* `z (k+1)` minimises `g w + ρ/2 ‖x (k+1) - w + u k‖²` over `w ∈ Dg` (the penalty half, exactly);
* `u (k+1) = u k + x (k+1) - z (k+1)` (the reconcile step; the price is `y = ρ u`, so the price
  moves by exactly `ρ` times the gap).

The plain Lagrangian is `L₀ (x, z, y) = f x + g z + ⟪y, x - z⟫`. A saddle point `(xs, zs, ys)`
has `L₀ (xs, zs, y) ≤ L₀ (xs, zs, ys) ≤ L₀ (x, z, ys)` for every price `y` and every `x ∈ Df`,
`z ∈ Dg`. The optimal cost is then `p* = f xs + g zs`. -/

/-- First-order condition for an exact proximal step on a convex function. -/
theorem admm_prox_first_order {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (h : E → ℝ) (D : Set E) (hconv : ConvexOn ℝ D h) (ρ : ℝ) (hρ : 0 < ρ) (c p : E)
    (hc : c ∈ D) (hmin : ∀ v ∈ D, h c + ρ / 2 * ‖c - p‖ ^ 2 ≤ h v + ρ / 2 * ‖v - p‖ ^ 2) :
    ∀ v ∈ D, h c - ρ * ⟪c - p, v - c⟫ ≤ h v := by
  intro v hv
  apply le_of_forall_pos_lt_add
  intro ε hε
  set M := ρ / 2 * ‖v - c‖ ^ 2 with hM
  have hM0 : 0 ≤ M := by positivity
  set t := min 1 (ε / (M + 1)) with ht
  have ht0 : 0 < t := lt_min one_pos (by positivity)
  have ht1 : t ≤ 1 := min_le_left _ _
  have ht2 : t ≤ ε / (M + 1) := min_le_right _ _
  have htM : t * M < ε := by
    have : t * (M + 1) ≤ ε := by
      rw [le_div_iff₀ (by positivity)] at ht2; linarith
    nlinarith
  have hmem : (1 - t) • c + t • v ∈ D := hconv.1 hc hv (by linarith) ht0.le (by ring)
  have hcv : h ((1 - t) • c + t • v) ≤ (1 - t) • h c + t • h v :=
    hconv.2 hc hv (by linarith) ht0.le (by ring)
  simp only [smul_eq_mul] at hcv
  have hpt : (1 - t) • c + t • v - p = (c - p) + t • (v - c) := by
    simp only [sub_smul, one_smul, smul_sub]; abel
  have key := hmin _ hmem
  rw [hpt, norm_add_sq_real, inner_smul_right, norm_smul, mul_pow, Real.norm_eq_abs, sq_abs]
    at key
  have : t * (h c - ρ * ⟪c - p, v - c⟫ - h v - t * M) ≤ 0 := by
    rw [hM]; nlinarith
  have : h c - ρ * ⟪c - p, v - c⟫ - h v - t * M ≤ 0 := by
    by_contra hcon
    rw [not_le] at hcon
    have := mul_pos ht0 hcon
    linarith
  linarith

/-- The optimality conditions after one ADMM round. -/
theorem admm_round_conditions {n : ℕ}
    (f g : EuclideanSpace ℝ (Fin n) → ℝ) (Df Dg : Set (EuclideanSpace ℝ (Fin n)))
    (hf_convex : ConvexOn ℝ Df f) (hg_convex : ConvexOn ℝ Dg g)
    (ρ : ℝ) (hρ : 0 < ρ) (x z u : ℕ → EuclideanSpace ℝ (Fin n))
    (hx_mem : ∀ k, x (k + 1) ∈ Df)
    (hx_min : ∀ k, ∀ v ∈ Df,
      f (x (k + 1)) + ρ / 2 * ‖x (k + 1) - z k + u k‖ ^ 2 ≤ f v + ρ / 2 * ‖v - z k + u k‖ ^ 2)
    (hz_mem : ∀ k, z (k + 1) ∈ Dg)
    (hz_min : ∀ k, ∀ w ∈ Dg,
      g (z (k + 1)) + ρ / 2 * ‖x (k + 1) - z (k + 1) + u k‖ ^ 2 ≤
        g w + ρ / 2 * ‖x (k + 1) - w + u k‖ ^ 2)
    (hu : ∀ k, u (k + 1) = u k + x (k + 1) - z (k + 1)) (k : ℕ) :
    (∀ w ∈ Dg, g (z (k + 1)) + ⟪ρ • u (k + 1), w - z (k + 1)⟫ ≤ g w) ∧
      (∀ v ∈ Df, f (x (k + 1)) +
        ⟪-(ρ • u (k + 1)) - ρ • (z (k + 1) - z k), v - x (k + 1)⟫ ≤ f v) := by
  constructor
  · have hn : ∀ w, ‖x (k + 1) - w + u k‖ = ‖w - (x (k + 1) + u k)‖ := by
      intro w; rw [← norm_neg]; congr 1; abel
    have H := admm_prox_first_order g Dg hg_convex ρ hρ (z (k + 1)) (x (k + 1) + u k)
      (hz_mem k) (by intro w hw; have := hz_min k w hw; rwa [hn, hn] at this)
    intro w hw
    have H1 := H w hw
    have he : z (k + 1) - (x (k + 1) + u k) = -u (k + 1) := by rw [hu k]; abel
    rw [he, inner_neg_left] at H1
    rw [real_inner_smul_left]; linarith
  · have hn : ∀ v, ‖v - z k + u k‖ = ‖v - (z k - u k)‖ := by
      intro v; congr 1; abel
    have H := admm_prox_first_order f Df hf_convex ρ hρ (x (k + 1)) (z k - u k)
      (hx_mem k) (by intro v hv; have := hx_min k v hv; rwa [hn, hn] at this)
    intro v hv
    have H1 := H v hv
    have he : -(ρ • u (k + 1)) - ρ • (z (k + 1) - z k) = (-ρ) • (x (k + 1) - (z k - u k)) := by
      rw [hu k]; module
    rw [he, real_inner_smul_left]; linarith

/-- One round of ADMM shrinks the distance to a solution pair. -/
theorem admm_lyapunov_step {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    (f g : E → ℝ) (ρ : ℝ) (hρ : 0 < ρ) (u0 u1 x1 z0 z1 a us : E)
    (hu : u1 = u0 + x1 - z1)
    (hG1 : g z1 + ⟪ρ • u1, a - z1⟫ ≤ g a)
    (hF1 : f x1 + ⟪-(ρ • u1) - ρ • (z1 - z0), a - x1⟫ ≤ f a)
    (hS : f a + g a ≤ f x1 + g z1 + ρ * ⟪us, x1 - z1⟫)
    (hG0 : g z0 + ⟪ρ • u0, z1 - z0⟫ ≤ g z1)
    (hG10 : g z1 + ⟪ρ • u1, z0 - z1⟫ ≤ g z0) :
    ‖u1 - us‖ ^ 2 + ‖z1 - a‖ ^ 2 ≤
      ‖u0 - us‖ ^ 2 + ‖z0 - a‖ ^ 2 - ‖u1 - u0‖ ^ 2 - ‖z1 - z0‖ ^ 2 := by
  subst hu
  refine le_of_mul_le_mul_left ?_ hρ
  simp only [← real_inner_self_eq_norm_sq]
  simp only [inner_add_left, inner_add_right, inner_sub_left, inner_sub_right, inner_neg_left,
    real_inner_smul_left] at *
  simp only [real_inner_comm] at *
  linarith

/-- From squares to values. -/
theorem admm_tendsto_of_sq {a : ℕ → ℝ} (ha : ∀ j, 0 ≤ a j)
    (h : Tendsto (fun j => a j ^ 2) atTop (𝓝 0)) : Tendsto a atTop (𝓝 0) := by
  have h2 := h.sqrt
  have e : (fun j => √(a j ^ 2)) = a := funext fun j => Real.sqrt_sq (ha j)
  rw [e, Real.sqrt_zero] at h2
  exact h2

/-- Squeeze towards zero. -/
theorem admm_squeeze {a b : ℕ → ℝ} (ha : ∀ j, 0 ≤ a j) (hab : ∀ j, a j ≤ b j)
    (hb : Tendsto b atTop (𝓝 0)) : Tendsto a atTop (𝓝 0) :=
  tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds hb ha hab

/-- A nonnegative sequence that drops by at least `e j` each step converges, and `e j → 0`. -/
theorem admm_antitone_lim {V e : ℕ → ℝ} (hV0 : ∀ j, 0 ≤ V j) (he0 : ∀ j, 0 ≤ e j)
    (hdec : ∀ j, V (j + 1) ≤ V j - e j) :
    Tendsto e atTop (𝓝 0) ∧ ∃ L, Tendsto V atTop (𝓝 L) := by
  have anti : Antitone V := antitone_nat_of_succ_le fun j => by linarith [hdec j, he0 j]
  have hL := tendsto_atTop_ciInf anti ⟨0, by rintro _ ⟨j, rfl⟩; exact hV0 j⟩
  refine ⟨?_, _, hL⟩
  have hd := hL.sub (hL.comp (tendsto_add_atTop_nat 1))
  rw [sub_self] at hd
  exact admm_squeeze he0 (fun j => by have := hdec j; simp only [Function.comp]; linarith) hd

/-- The card's convergence theorem (Gabay and Mercier 1976; Boyd and co-authors 2011, section 3.2).
Minimise `f x + g z` subject to `x = z`, with `f` and `g` closed, proper and convex, and suppose
the plain Lagrangian has a saddle point `(xs, zs, ys)`. Run ADMM with any agreement weight
`ρ > 0`, each half solved exactly, the price moved by exactly `ρ` times the gap. Then the primal
residual `‖x k - z k‖` falls to zero, the dual residual `ρ ‖z (k+1) - z k‖` falls to zero, the
cost `f (x k) + g (z k)` tends to the optimal cost `f xs + g zs`, and the price `ρ u k` tends to
an optimal price: a price `ybar` that makes `(xs, zs, ybar)` a saddle point too. -/
theorem admm_converges_for_two_convex_halves {n : ℕ}
    (f g : EuclideanSpace ℝ (Fin n) → ℝ) (Df Dg : Set (EuclideanSpace ℝ (Fin n)))
    (hf_proper : Df.Nonempty) (hg_proper : Dg.Nonempty)
    (hf_convex : ConvexOn ℝ Df f) (hg_convex : ConvexOn ℝ Dg g)
    (hf_closed : IsClosed {p : EuclideanSpace ℝ (Fin n) × ℝ | p.1 ∈ Df ∧ f p.1 ≤ p.2})
    (hg_closed : IsClosed {p : EuclideanSpace ℝ (Fin n) × ℝ | p.1 ∈ Dg ∧ g p.1 ≤ p.2})
    (xs zs ys : EuclideanSpace ℝ (Fin n)) (hxs : xs ∈ Df) (hzs : zs ∈ Dg)
    (h_saddle_price : ∀ y, f xs + g zs + ⟪y, xs - zs⟫ ≤ f xs + g zs + ⟪ys, xs - zs⟫)
    (h_saddle_weights : ∀ x ∈ Df, ∀ z ∈ Dg,
      f xs + g zs + ⟪ys, xs - zs⟫ ≤ f x + g z + ⟪ys, x - z⟫)
    (ρ : ℝ) (hρ : 0 < ρ) (x z u : ℕ → EuclideanSpace ℝ (Fin n))
    (hx_mem : ∀ k, x (k + 1) ∈ Df)
    (hx_min : ∀ k, ∀ v ∈ Df,
      f (x (k + 1)) + ρ / 2 * ‖x (k + 1) - z k + u k‖ ^ 2 ≤ f v + ρ / 2 * ‖v - z k + u k‖ ^ 2)
    (hz_mem : ∀ k, z (k + 1) ∈ Dg)
    (hz_min : ∀ k, ∀ w ∈ Dg,
      g (z (k + 1)) + ρ / 2 * ‖x (k + 1) - z (k + 1) + u k‖ ^ 2 ≤
        g w + ρ / 2 * ‖x (k + 1) - w + u k‖ ^ 2)
    (hu : ∀ k, u (k + 1) = u k + x (k + 1) - z (k + 1)) :
    Tendsto (fun k => ‖x k - z k‖) atTop (𝓝 0) ∧
      Tendsto (fun k => ρ * ‖z (k + 1) - z k‖) atTop (𝓝 0) ∧
      Tendsto (fun k => f (x k) + g (z k)) atTop (𝓝 (f xs + g zs)) ∧
      ∃ ybar : EuclideanSpace ℝ (Fin n),
        Tendsto (fun k => ρ • u k) atTop (𝓝 ybar) ∧
        (∀ y, f xs + g zs + ⟪y, xs - zs⟫ ≤ f xs + g zs + ⟪ybar, xs - zs⟫) ∧
        ∀ x' ∈ Df, ∀ z' ∈ Dg, f xs + g zs + ⟪ybar, xs - zs⟫ ≤ f x' + g z' + ⟪ybar, x' - z'⟫ := by
  classical
  have hxz : xs = zs := by
    have h := h_saddle_price (ys + (xs - zs))
    rw [inner_add_left, real_inner_self_eq_norm_sq] at h
    have h3 : ‖xs - zs‖ = 0 := by nlinarith [norm_nonneg (xs - zs)]
    exact sub_eq_zero.mp (norm_eq_zero.mp h3)
  subst hxz
  have hround := admm_round_conditions f g Df Dg hf_convex hg_convex ρ hρ x z u hx_mem hx_min
    hz_mem hz_min hu
  have hx_eq : ∀ k, x (k + 1) = z (k + 1) + (u (k + 1) - u k) := by
    intro k; rw [hu k]; abel
  have lyap : ∀ a us : EuclideanSpace ℝ (Fin n), a ∈ Df → a ∈ Dg →
      (∀ v ∈ Df, ∀ w ∈ Dg, f a + g a ≤ f v + g w + ρ * ⟪us, v - w⟫) → ∀ k,
      ‖u (k + 1 + 1) - us‖ ^ 2 + ‖z (k + 1 + 1) - a‖ ^ 2 ≤
        ‖u (k + 1) - us‖ ^ 2 + ‖z (k + 1) - a‖ ^ 2 - ‖u (k + 1 + 1) - u (k + 1)‖ ^ 2 -
          ‖z (k + 1 + 1) - z (k + 1)‖ ^ 2 := by
    intro a us haf hag hS k
    exact admm_lyapunov_step f g ρ hρ (u (k + 1)) (u (k + 1 + 1)) (x (k + 1 + 1)) (z (k + 1))
      (z (k + 1 + 1)) a us (hu (k + 1)) ((hround (k + 1)).1 a hag) ((hround (k + 1)).2 a haf)
      (hS _ (hx_mem _) _ (hz_mem _)) ((hround k).1 _ (hz_mem _))
      ((hround (k + 1)).1 _ (hz_mem _))
  have hS0 : ∀ v ∈ Df, ∀ w ∈ Dg, f xs + g xs ≤ f v + g w + ρ * ⟪ρ⁻¹ • ys, v - w⟫ := by
    intro v hv w hw
    have h := h_saddle_weights v hv w hw
    rw [sub_self, inner_zero_right, add_zero] at h
    rw [real_inner_smul_left, ← mul_assoc, mul_inv_cancel₀ hρ.ne', one_mul]
    exact h
  obtain ⟨he0, -⟩ := admm_antitone_lim
    (V := fun j => ‖u (j + 1) - ρ⁻¹ • ys‖ ^ 2 + ‖z (j + 1) - xs‖ ^ 2)
    (e := fun j => ‖u (j + 1 + 1) - u (j + 1)‖ ^ 2 + ‖z (j + 1 + 1) - z (j + 1)‖ ^ 2)
    (fun j => by positivity) (fun j => by positivity)
    (fun j => by have := lyap xs (ρ⁻¹ • ys) hxs hzs hS0 j; linarith)
  have hdu : Tendsto (fun k => u (k + 1) - u k) atTop (𝓝 0) := by
    rw [← tendsto_add_atTop_iff_nat 1, tendsto_zero_iff_norm_tendsto_zero]
    exact admm_tendsto_of_sq (fun j => norm_nonneg _)
      (admm_squeeze (fun j => sq_nonneg _) (fun j => le_add_of_nonneg_right (sq_nonneg _)) he0)
  have hdz : Tendsto (fun k => z (k + 1) - z k) atTop (𝓝 0) := by
    rw [← tendsto_add_atTop_iff_nat 1, tendsto_zero_iff_norm_tendsto_zero]
    exact admm_tendsto_of_sq (fun j => norm_nonneg _)
      (admm_squeeze (fun j => sq_nonneg _) (fun j => le_add_of_nonneg_left (sq_nonneg _)) he0)
  set V0 := ‖u (0 + 1) - ρ⁻¹ • ys‖ ^ 2 + ‖z (0 + 1) - xs‖ ^ 2 with hV0
  have hbound : ∀ j, ‖u (j + 1) - ρ⁻¹ • ys‖ ^ 2 + ‖z (j + 1) - xs‖ ^ 2 ≤ V0 := by
    intro j
    induction j with
    | zero => exact le_refl _
    | succ j ih =>
      have := lyap xs (ρ⁻¹ • ys) hxs hzs hS0 j
      nlinarith [sq_nonneg ‖u (j + 1 + 1) - u (j + 1)‖, sq_nonneg ‖z (j + 1 + 1) - z (j + 1)‖]
  obtain ⟨⟨ubar, zbar⟩, -, φ, hφ, hlim⟩ := tendsto_subseq_of_bounded
    (Metric.isBounded_closedBall (x := (ρ⁻¹ • ys, xs)) (r := V0 + 1))
    (x := fun j => (u (j + 1), z (j + 1))) (fun j => by
      rw [Metric.mem_closedBall, Prod.dist_eq, dist_eq_norm, dist_eq_norm]
      have := hbound j
      refine max_le ?_ ?_
      · nlinarith [norm_nonneg (u (j + 1) - ρ⁻¹ • ys), norm_nonneg (z (j + 1) - xs),
          sq_nonneg (‖u (j + 1) - ρ⁻¹ • ys‖ - 1 / 2), sq_nonneg ‖z (j + 1) - xs‖]
      · nlinarith [norm_nonneg (u (j + 1) - ρ⁻¹ • ys), norm_nonneg (z (j + 1) - xs),
          sq_nonneg (‖z (j + 1) - xs‖ - 1 / 2), sq_nonneg ‖u (j + 1) - ρ⁻¹ • ys‖])
  have hu_sub : Tendsto (fun j => u (φ j + 1)) atTop (𝓝 ubar) :=
    (continuous_fst.tendsto _).comp hlim
  have hz_sub : Tendsto (fun j => z (φ j + 1)) atTop (𝓝 zbar) :=
    (continuous_snd.tendsto _).comp hlim
  have hz_sub0 : Tendsto (fun j => z (φ j)) atTop (𝓝 zbar) := by
    have h := hz_sub.sub (hdz.comp hφ.tendsto_atTop)
    rw [sub_zero] at h
    exact h.congr fun j => by simp
  have hx_sub : Tendsto (fun j => x (φ j + 1)) atTop (𝓝 zbar) := by
    have h := hz_sub.add (hdu.comp hφ.tendsto_atTop)
    rw [add_zero] at h
    exact h.congr fun j => (hx_eq (φ j)).symm
  have hFlim : ∀ v ∈ Df, zbar ∈ Df ∧ f zbar - ρ * ⟪ubar, v - zbar⟫ ≤ f v := by
    intro v hv
    have hc : Tendsto (fun j => (x (φ j + 1), f v -
        ⟪-(ρ • u (φ j + 1)) - ρ • (z (φ j + 1) - z (φ j)), v - x (φ j + 1)⟫)) atTop
        (𝓝 (zbar, f v - ⟪-(ρ • ubar) - ρ • (zbar - zbar), v - zbar⟫)) := by
      refine hx_sub.prodMk_nhds ?_
      refine tendsto_const_nhds.sub (Tendsto.inner ?_ (tendsto_const_nhds.sub hx_sub))
      exact ((hu_sub.const_smul ρ).neg).sub ((hz_sub.sub hz_sub0).const_smul ρ)
    have hmem := hf_closed.mem_of_tendsto hc (Eventually.of_forall fun j => by
      refine ⟨hx_mem _, ?_⟩
      have := (hround (φ j)).2 v hv
      simp only
      linarith)
    obtain ⟨h1, h2⟩ := hmem
    refine ⟨h1, ?_⟩
    simp only [sub_self, smul_zero, sub_zero, inner_neg_left, real_inner_smul_left] at h2
    linarith
  have hGlim : ∀ w ∈ Dg, zbar ∈ Dg ∧ g zbar + ρ * ⟪ubar, w - zbar⟫ ≤ g w := by
    intro w hw
    have hc : Tendsto (fun j => (z (φ j + 1), g w - ⟪ρ • u (φ j + 1), w - z (φ j + 1)⟫)) atTop
        (𝓝 (zbar, g w - ⟪ρ • ubar, w - zbar⟫)) :=
      hz_sub.prodMk_nhds (tendsto_const_nhds.sub
        ((hu_sub.const_smul ρ).inner (tendsto_const_nhds.sub hz_sub)))
    have hmem := hg_closed.mem_of_tendsto hc (Eventually.of_forall fun j => by
      refine ⟨hz_mem _, ?_⟩
      have := (hround (φ j)).1 w hw
      simp only
      linarith)
    obtain ⟨h1, h2⟩ := hmem
    refine ⟨h1, ?_⟩
    rw [real_inner_smul_left] at h2
    linarith
  have hzbar_f : zbar ∈ Df := (hFlim xs hxs).1
  have hzbar_g : zbar ∈ Dg := (hGlim xs hzs).1
  have hSbar : ∀ v ∈ Df, ∀ w ∈ Dg, f zbar + g zbar ≤ f v + g w + ρ * ⟪ubar, v - w⟫ := by
    intro v hv w hw
    have h1 := (hFlim v hv).2
    have h2 := (hGlim w hw).2
    have e : ⟪ubar, v - w⟫ = ⟪ubar, v - zbar⟫ - ⟪ubar, w - zbar⟫ := by
      simp only [inner_sub_right]; ring
    rw [e]; linarith
  obtain ⟨-, L, hL⟩ := admm_antitone_lim
    (V := fun j => ‖u (j + 1) - ubar‖ ^ 2 + ‖z (j + 1) - zbar‖ ^ 2)
    (e := fun j => ‖u (j + 1 + 1) - u (j + 1)‖ ^ 2 + ‖z (j + 1 + 1) - z (j + 1)‖ ^ 2)
    (fun j => by positivity) (fun j => by positivity)
    (fun j => by have := lyap zbar ubar hzbar_f hzbar_g hSbar j; linarith)
  have hL0 : L = 0 := by
    have h1 : Tendsto (fun j => ‖u (φ j + 1) - ubar‖ ^ 2 + ‖z (φ j + 1) - zbar‖ ^ 2) atTop
        (𝓝 (‖ubar - ubar‖ ^ 2 + ‖zbar - zbar‖ ^ 2)) :=
      (((hu_sub.sub tendsto_const_nhds).norm).pow 2).add
        (((hz_sub.sub tendsto_const_nhds).norm).pow 2)
    simp only [sub_self, norm_zero] at h1
    norm_num at h1
    exact tendsto_nhds_unique (hL.comp hφ.tendsto_atTop) h1
  rw [hL0] at hL
  have hu_lim : Tendsto u atTop (𝓝 ubar) := by
    rw [← tendsto_add_atTop_iff_nat 1, tendsto_iff_norm_sub_tendsto_zero]
    exact admm_tendsto_of_sq (fun j => norm_nonneg _)
      (admm_squeeze (fun j => sq_nonneg _) (fun j => le_add_of_nonneg_right (sq_nonneg _)) hL)
  have hz_lim : Tendsto z atTop (𝓝 zbar) := by
    rw [← tendsto_add_atTop_iff_nat 1, tendsto_iff_norm_sub_tendsto_zero]
    exact admm_tendsto_of_sq (fun j => norm_nonneg _)
      (admm_squeeze (fun j => sq_nonneg _) (fun j => le_add_of_nonneg_left (sq_nonneg _)) hL)
  have hz1 : Tendsto (fun k => z (k + 1)) atTop (𝓝 zbar) := hz_lim.comp (tendsto_add_atTop_nat 1)
  have hu1 : Tendsto (fun k => u (k + 1)) atTop (𝓝 ubar) := hu_lim.comp (tendsto_add_atTop_nat 1)
  have hx_lim : Tendsto (fun k => x (k + 1)) atTop (𝓝 zbar) := by
    have h := hz1.add hdu
    rw [add_zero] at h
    exact h.congr fun k => (hx_eq k).symm
  refine ⟨?_, ?_, ?_, ρ • ubar, hu_lim.const_smul ρ, ?_, ?_⟩
  · rw [← tendsto_add_atTop_iff_nat 1]
    have h := hdu.norm
    rw [norm_zero] at h
    exact h.congr fun k => by rw [hu k]; congr 1; abel
  · have h := hdz.norm.const_mul ρ
    rw [norm_zero, mul_zero] at h
    exact h
  · rw [← tendsto_add_atTop_iff_nat 1]
    have hlow : Tendsto (fun k => f xs + g xs - ⟪ys, x (k + 1) - z (k + 1)⟫) atTop
        (𝓝 (f xs + g xs)) := by
      have h := (tendsto_const_nhds (x := f xs + g xs)).sub
        ((tendsto_const_nhds (x := ys)).inner (hx_lim.sub hz1))
      rw [sub_self, inner_zero_right, sub_zero] at h
      exact h
    have hup : Tendsto (fun k => f xs + g xs - ⟪ρ • u (k + 1), xs - z (k + 1)⟫ -
        ⟪-(ρ • u (k + 1)) - ρ • (z (k + 1) - z k), xs - x (k + 1)⟫) atTop
        (𝓝 (f xs + g xs)) := by
      have h := ((tendsto_const_nhds (x := f xs + g xs)).sub
        ((hu1.const_smul ρ).inner ((tendsto_const_nhds (x := xs)).sub hz1))).sub
        ((((hu1.const_smul ρ).neg).sub ((hz1.sub hz_lim).const_smul ρ)).inner
          ((tendsto_const_nhds (x := xs)).sub hx_lim))
      have e : f xs + g xs - ⟪ρ • ubar, xs - zbar⟫ -
          ⟪-(ρ • ubar) - ρ • (zbar - zbar), xs - zbar⟫ = f xs + g xs := by
        simp only [sub_self, smul_zero, sub_zero, inner_neg_left]; ring
      rw [e] at h
      exact h
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le hlow hup (fun k => ?_) (fun k => ?_)
    · have h := h_saddle_weights (x (k + 1)) (hx_mem k) (z (k + 1)) (hz_mem k)
      rw [sub_self, inner_zero_right, add_zero] at h
      simp only
      linarith
    · have h1 := (hround k).1 xs hzs
      have h2 := (hround k).2 xs hxs
      simp only
      linarith
  · intro y
    rw [sub_self, inner_zero_right, inner_zero_right]
  · intro x' hx' z' hz'
    rw [sub_self, inner_zero_right, add_zero, real_inner_smul_left]
    have h1 := h_saddle_weights zbar hzbar_f zbar hzbar_g
    simp only [sub_self, inner_zero_right, add_zero] at h1
    have h2 := hSbar x' hx' z' hz'
    linarith

/-- Step 3, why the stopping test is right. With `f` and `g` convex, each half solved exactly and
the price `y = ρ u` moved by exactly `ρ` times the gap, after every round `k + 1`:
* the penalty's condition holds exactly: the price `ρ u (k+1)` is a slope of `g` at `z (k+1)`;
* the fit's condition is off by the dual residual: `-(ρ u (k+1)) - ρ (z (k+1) - z k)` is a slope
  of `f` at `x (k+1)`;
* so when both residuals are zero (`x (k+1) = z (k+1)` and `z (k+1) = z k`), `x (k+1)` is
  optimal: no `w` where both halves are finite gives a lower `f w + g w`. -/
theorem admm_residuals_measure_optimality {n : ℕ}
    (f g : EuclideanSpace ℝ (Fin n) → ℝ) (Df Dg : Set (EuclideanSpace ℝ (Fin n)))
    (hf_convex : ConvexOn ℝ Df f) (hg_convex : ConvexOn ℝ Dg g)
    (ρ : ℝ) (hρ : 0 < ρ) (x z u : ℕ → EuclideanSpace ℝ (Fin n))
    (hx_mem : ∀ k, x (k + 1) ∈ Df)
    (hx_min : ∀ k, ∀ v ∈ Df,
      f (x (k + 1)) + ρ / 2 * ‖x (k + 1) - z k + u k‖ ^ 2 ≤ f v + ρ / 2 * ‖v - z k + u k‖ ^ 2)
    (hz_mem : ∀ k, z (k + 1) ∈ Dg)
    (hz_min : ∀ k, ∀ w ∈ Dg,
      g (z (k + 1)) + ρ / 2 * ‖x (k + 1) - z (k + 1) + u k‖ ^ 2 ≤
        g w + ρ / 2 * ‖x (k + 1) - w + u k‖ ^ 2)
    (hu : ∀ k, u (k + 1) = u k + x (k + 1) - z (k + 1)) (k : ℕ) :
    (∀ w ∈ Dg, g (z (k + 1)) + ⟪ρ • u (k + 1), w - z (k + 1)⟫ ≤ g w) ∧
      (∀ v ∈ Df, f (x (k + 1)) +
        ⟪-(ρ • u (k + 1)) - ρ • (z (k + 1) - z k), v - x (k + 1)⟫ ≤ f v) ∧
      (x (k + 1) = z (k + 1) → z (k + 1) = z k →
        ∀ w ∈ Df ∩ Dg, f (x (k + 1)) + g (x (k + 1)) ≤ f w + g w) := by
  obtain ⟨hG, hF⟩ := admm_round_conditions f g Df Dg hf_convex hg_convex ρ hρ x z u hx_mem
    hx_min hz_mem hz_min hu k
  refine ⟨hG, hF, ?_⟩
  intro hxz hzz w hw
  have h1 := hG w hw.2
  have h2 := hF w hw.1
  rw [hzz, sub_self, smul_zero, sub_zero, inner_neg_left] at h2
  rw [hxz] at h2 ⊢
  linarith

/-! ### The card's five-holding lasso

Eight months of returns (percent a month) for UK shares, US shares, UK gilts, gold and property,
and the index `b = (1.8, 0.1, 1.6, 0.3, -0.6, 0.5, 0.9, 1.1)`, written as exact fractions. -/

/-- The holdings' monthly returns: 8 months, 5 holdings. -/
def lassoA : Matrix (Fin 8) (Fin 5) ℝ :=
  !![2, 3, -1, 1, 2; -1, 1, 2, 0, -2; 3, 2, -2, 2, 1; 1, -2, 1, -1, 3;
     -2, -1, 3, 1, -1; 0, 2, 0, -2, 1; 2, 0, -1, 3, 0; 1, 1, 1, 0, 2]

/-- The index's monthly returns. -/
noncomputable def lassoB : Fin 8 → ℝ :=
  ![18 / 10, 1 / 10, 16 / 10, 3 / 10, -6 / 10, 5 / 10, 9 / 10, 11 / 10]

/-- The lasso cost with weight `λ = 2`: half the sum of squared monthly gaps plus 2 times the sum
of the weights' sizes. -/
noncomputable def lassoCost (w : Fin 5 → ℝ) : ℝ :=
  (1 / 2) * ∑ t, ((lassoA *ᵥ w) t - lassoB t) ^ 2 + 2 * ∑ i, |w i|

/-- The card's answer, certified: the weights `(0.3125, 0.2, 0, 0, 0.05)` (UK shares, US shares,
nothing in gilts or gold, property) cost exactly `p* = 1.533125`, and no other weights cost
less. -/
theorem lasso_answer_is_optimal :
    lassoCost ![5 / 16, 1 / 5, 0, 0, 1 / 20] = 2453 / 1600 ∧
      ∀ w : Fin 5 → ℝ, lassoCost ![5 / 16, 1 / 5, 0, 0, 1 / 20] ≤ lassoCost w := by
  have hval : lassoCost ![5 / 16, 1 / 5, 0, 0, 1 / 20] = 2453 / 1600 := by
    simp [lassoCost, lassoA, lassoB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ]
    norm_num [abs_of_pos]
  refine ⟨hval, fun w => ?_⟩
  rw [hval]
  simp only [lassoCost, lassoA, lassoB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ,
    Fin.sum_univ_zero]
  simp
  have a0 := le_abs_self (w 0)
  have a1 := le_abs_self (w 1)
  have a4 := le_abs_self (w 4)
  have a2 := le_abs_self (w 2)
  have b2 := neg_abs_le (w 2)
  have a3 := le_abs_self (w 3)
  have b3 := neg_abs_le (w 3)
  linarith [sq_nonneg (2*(w 0 - 5/16) + 3*(w 1 - 1/5) - w 2 + w 3 + 2*(w 4 - 1/20)),
    sq_nonneg (-(w 0 - 5/16) + (w 1 - 1/5) + 2*w 2 - 2*(w 4 - 1/20)),
    sq_nonneg (3*(w 0 - 5/16) + 2*(w 1 - 1/5) - 2*w 2 + 2*w 3 + (w 4 - 1/20)),
    sq_nonneg ((w 0 - 5/16) - 2*(w 1 - 1/5) + w 2 - w 3 + 3*(w 4 - 1/20)),
    sq_nonneg (-2*(w 0 - 5/16) - (w 1 - 1/5) + 3*w 2 + w 3 - (w 4 - 1/20)),
    sq_nonneg (2*(w 1 - 1/5) - 2*w 3 + (w 4 - 1/20)),
    sq_nonneg (2*(w 0 - 5/16) - w 2 + 3*w 3),
    sq_nonneg ((w 0 - 5/16) + (w 1 - 1/5) + w 2 + 2*(w 4 - 1/20))]

/-! ### The card's worked numbers, checked exactly -/

/-- `AᵀA` and `Aᵀb`, the data the fit sees (`Aᵀb = (12.7, 10.8, -6.1, 5.8, 9.2)`). -/
example :
    lassoAᵀ * lassoA = !![24, 12, -16, 11, 16; 12, 24, -9, 4, 5; -16, -9, 21, -6, -6;
      11, 4, -6, 20, -2; 16, 5, -6, -2, 24] ∧
    lassoAᵀ *ᵥ lassoB = ![127 / 10, 108 / 10, -61 / 10, 58 / 10, 92 / 10] := by
  constructor
  · ext i j
    fin_cases i <;> fin_cases j <;>
      simp [lassoA, Matrix.mul_apply, Fin.sum_univ_succ] <;> norm_num
  · ext i
    fin_cases i <;>
      simp [lassoA, lassoB, Matrix.mulVec, dotProduct, Fin.sum_univ_succ] <;> norm_num

/-- Certificate, the three holdings: each row of `AᵀA z` equals that row of `Aᵀb` minus `λ = 2`. -/
example :
    (24 * (5 / 16) + 12 * (1 / 5) + 16 * (1 / 20) : ℚ) = 127 / 10 - 2 ∧
    (12 * (5 / 16) + 24 * (1 / 5) + 5 * (1 / 20) : ℚ) = 108 / 10 - 2 ∧
    (16 * (5 / 16) + 5 * (1 / 5) + 24 * (1 / 20) : ℚ) = 92 / 10 - 2 := by
  norm_num

/-- Certificate, gilts and gold: the pull `-∇f` is 1 and 1.6625, both inside `[-2, 2]`. -/
example :
    (-61 / 10 - (-16) * (5 / 16) - (-9) * (1 / 5) - (-6) * (1 / 20) : ℚ) = 1 ∧
    (58 / 10 - 11 * (5 / 16) - 4 * (1 / 5) - (-2) * (1 / 20) : ℚ) = 133 / 80 ∧
    |(1 : ℚ)| ≤ 2 ∧ |(133 / 80 : ℚ)| ≤ 2 := by
  norm_num

/-- The cost splits as fit 0.408125 plus penalty 1.125, and per £1,000,000 the answer is
£312,500 UK shares, £200,000 US shares, £50,000 property and £437,500 cash. -/
example :
    (2 * (5 / 16 + 1 / 5 + 1 / 20) : ℚ) = 1125 / 1000 ∧
    (653 / 1600 + 1125 / 1000 : ℚ) = 2453 / 1600 ∧
    (1000000 * (5 / 16) : ℚ) = 312500 ∧ (1000000 * (1 / 5) : ℚ) = 200000 ∧
    (1000000 * (1 / 20) : ℚ) = 50000 ∧
    (1000000 * (1 - (5 / 16 + 1 / 5 + 1 / 20)) : ℚ) = 437500 := by
  norm_num

#print axioms admm_prox_first_order
#print axioms admm_round_conditions
#print axioms admm_lyapunov_step
#print axioms admm_tendsto_of_sq
#print axioms admm_squeeze
#print axioms admm_antitone_lim
#print axioms admm_converges_for_two_convex_halves
#print axioms admm_residuals_measure_optimality
#print axioms lasso_answer_is_optimal
