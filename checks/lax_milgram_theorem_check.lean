-- Lax-Milgram: on a real Hilbert space, a bounded coercive form meets every bounded load with exactly one balancing element, whose size is at most the load's size over the coercivity constant.
import Mathlib.Analysis.InnerProductSpace.LaxMilgram
import Mathlib.Tactic.NormNum
import Mathlib.Topology.MetricSpace.Contracting

open Filter Topology
open scoped RealInnerProductSpace

/-- Lax-Milgram. Let `V` be a real Hilbert space (an inner product space that is complete) and
`a(u, v)` a form, linear in each slot, that is bounded, `|a(u, v)| ≤ C ‖u‖ ‖v‖`, and coercive,
`a(v, v) ≥ c ‖v‖²` with `c > 0`. Then for every bounded load `ℓ` there is exactly one `u` in `V`
with `a(u, v) = ℓ(v)` for every `v`, and that `u` has size `‖u‖ ≤ ‖ℓ‖ / c`. -/
theorem lax_milgram_unique_solution_with_bound {V : Type*} [NormedAddCommGroup V]
    [InnerProductSpace ℝ V] [CompleteSpace V]
    (a : V →ₗ[ℝ] V →ₗ[ℝ] ℝ) {C c : ℝ}
    (h_bounded : ∀ u v, |a u v| ≤ C * ‖u‖ * ‖v‖)
    (hc : 0 < c) (h_coercive : ∀ v, c * ‖v‖ ^ 2 ≤ a v v)
    (ℓ : V →L[ℝ] ℝ) :
    (∃! u : V, ∀ v, a u v = ℓ v) ∧ ∀ u : V, (∀ v, a u v = ℓ v) → ‖u‖ ≤ ‖ℓ‖ / c := by
  set B : V →L[ℝ] V →L[ℝ] ℝ :=
    a.mkContinuous₂ C (fun x y => by rw [Real.norm_eq_abs]; exact h_bounded x y) with hB
  have hBa : ∀ x y, B x y = a x y := fun x y => rfl
  have hcoer : IsCoercive B := ⟨c, hc, fun u => by
    rw [hBa, mul_assoc, ← sq]; exact h_coercive u⟩
  have huniq : ∀ y z : V, (∀ v, a y v = ℓ v) → (∀ v, a z v = ℓ v) → y = z := by
    intro y z hy hz
    have h0 : a (y - z) (y - z) = 0 := by
      rw [show a (y - z) = a y - a z from map_sub a y z, LinearMap.sub_apply, hy, hz, sub_self]
    have h1 := h_coercive (y - z)
    rw [h0] at h1
    have h2 : ‖y - z‖ ^ 2 ≤ 0 := by
      by_contra h; push Not at h; nlinarith
    have h3 : ‖y - z‖ = 0 := by nlinarith [norm_nonneg (y - z)]
    exact sub_eq_zero.mp (norm_eq_zero.mp h3)
  refine ⟨?_, ?_⟩
  · set E := hcoer.continuousLinearEquivOfBilin
    refine ⟨E.symm ((InnerProductSpace.toDual ℝ V).symm ℓ), ?_, ?_⟩
    · intro v
      rw [← hBa, ← IsCoercive.continuousLinearEquivOfBilin_apply hcoer]
      change ⟪E (E.symm _), v⟫ = ℓ v
      rw [ContinuousLinearEquiv.apply_symm_apply, InnerProductSpace.toDual_symm_apply]
    · intro y hy
      exact huniq y _ hy (by
        intro v
        rw [← hBa, ← IsCoercive.continuousLinearEquivOfBilin_apply hcoer]
        change ⟪E (E.symm _), v⟫ = ℓ v
        rw [ContinuousLinearEquiv.apply_symm_apply, InnerProductSpace.toDual_symm_apply])
  · intro u hu
    rw [le_div_iff₀ hc]
    have h1 : c * ‖u‖ ^ 2 ≤ ‖ℓ‖ * ‖u‖ := by
      calc c * ‖u‖ ^ 2 ≤ a u u := h_coercive u
        _ = ℓ u := hu u
        _ ≤ |ℓ u| := le_abs_self _
        _ = ‖ℓ u‖ := (Real.norm_eq_abs _).symm
        _ ≤ ‖ℓ‖ * ‖u‖ := ℓ.le_opNorm u
    rcases (norm_nonneg u).eq_or_lt with h | h
    · rw [← h]; simp [norm_nonneg]
    · have : (‖u‖ * c) * ‖u‖ ≤ ‖ℓ‖ * ‖u‖ := by nlinarith
      exact le_of_mul_le_mul_right this h

/-- The shrink factor of one step of the recipe. Let `A` be the form written as an operator,
`a(u, v) = ⟨Au, v⟩`, with `⟨Ae, e⟩ ≥ c ‖e‖²` and `‖Ae‖ ≤ C ‖e‖`. With step size `ρ = c / C²`,
one step maps a gap `e` to `e - ρ Ae`, and `‖e - ρ Ae‖² ≤ (1 - c² / C²) ‖e‖²`. -/
theorem lax_milgram_step_shrinks {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (A : V →L[ℝ] V) {C c : ℝ} (hc : 0 < c)
    (h_coercive : ∀ e, c * ‖e‖ ^ 2 ≤ ⟪A e, e⟫)
    (h_bounded : ∀ e, ‖A e‖ ≤ C * ‖e‖) (e : V) :
    ‖e - (c / C ^ 2) • A e‖ ^ 2 ≤ (1 - c ^ 2 / C ^ 2) * ‖e‖ ^ 2 := by
  by_cases he : e = 0
  · subst he; simp
  have hn : 0 < ‖e‖ := norm_pos_iff.mpr he
  have hin : ⟪A e, e⟫ ≤ ‖A e‖ * ‖e‖ := real_inner_le_norm _ _
  have hAe := h_bounded e
  have hcC : c ≤ C := by
    have : c * ‖e‖ * ‖e‖ ≤ C * ‖e‖ * ‖e‖ := by
      have h3 := mul_le_mul_of_nonneg_right hAe (norm_nonneg e)
      have h4 := h_coercive e
      have h5 : c * ‖e‖ ^ 2 = c * ‖e‖ * ‖e‖ := by ring
      linarith
    exact le_of_mul_le_mul_right (le_of_mul_le_mul_right this hn) hn
  have hC : 0 < C := lt_of_lt_of_le hc hcC
  have hAe2 : ‖A e‖ ^ 2 ≤ C ^ 2 * ‖e‖ ^ 2 := by
    rw [← mul_pow]; exact pow_le_pow_left₀ (norm_nonneg _) hAe 2
  have hco := h_coercive e
  rw [norm_sub_sq_real, inner_smul_right, norm_smul, mul_pow, Real.norm_eq_abs,
    abs_of_pos (by positivity : 0 < c / C ^ 2), real_inner_comm]
  set ρ := c / C ^ 2 with hρ
  have hρpos : 0 < ρ := by positivity
  have hρC : ρ * C ^ 2 = c := by rw [hρ]; field_simp
  have key : ‖e‖ ^ 2 - 2 * (ρ * ⟪A e, e⟫) + ρ ^ 2 * ‖A e‖ ^ 2
      ≤ ‖e‖ ^ 2 - 2 * (ρ * (c * ‖e‖ ^ 2)) + ρ ^ 2 * (C ^ 2 * ‖e‖ ^ 2) := by
    have := mul_le_mul_of_nonneg_left hco hρpos.le
    have := mul_le_mul_of_nonneg_left hAe2 (sq_nonneg ρ)
    linarith
  refine key.trans (le_of_eq ?_)
  rw [hρ]; field_simp; ring

/-- The second proof, as a recipe. On a real Hilbert space, with `A` coercive and bounded as
above, start from any `u₀` and repeat `u ↦ u - ρ (Au - f)` with `ρ = c / C²`. The shapes
converge (in the norm of `V`) to a solution of `Au = f`, and that solution is the only one. -/
theorem lax_milgram_recipe_converges {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    [CompleteSpace V] (A : V →L[ℝ] V) {C c : ℝ} (hc : 0 < c)
    (h_coercive : ∀ e, c * ‖e‖ ^ 2 ≤ ⟪A e, e⟫)
    (h_bounded : ∀ e, ‖A e‖ ≤ C * ‖e‖) (f u₀ : V) :
    ∃! u : V, A u = f ∧
      Tendsto (fun n : ℕ => (fun x => x - (c / C ^ 2) • (A x - f))^[n] u₀) atTop (𝓝 u) := by
  by_cases hV : ∀ x : V, x = 0
  · refine ⟨0, ⟨(hV _).trans (hV _).symm, ?_⟩, fun y _ => hV y⟩
    have : (fun n : ℕ => (fun x => x - (c / C ^ 2) • (A x - f))^[n] u₀) = fun _ => 0 :=
      funext fun n => hV _
    rw [this]; exact tendsto_const_nhds
  push Not at hV
  obtain ⟨e, he⟩ := hV
  have hn : 0 < ‖e‖ := norm_pos_iff.mpr he
  have hcC : c ≤ C := by
    have hin : ⟪A e, e⟫ ≤ ‖A e‖ * ‖e‖ := real_inner_le_norm _ _
    have hAe := h_bounded e
    have hco := h_coercive e
    have : c * ‖e‖ * ‖e‖ ≤ C * ‖e‖ * ‖e‖ := by nlinarith
    exact le_of_mul_le_mul_right (le_of_mul_le_mul_right this hn) hn
  have hC : 0 < C := lt_of_lt_of_le hc hcC
  set ρ := c / C ^ 2 with hρ
  have hρpos : 0 < ρ := by positivity
  set q := 1 - c ^ 2 / C ^ 2 with hq
  have hq0 : 0 ≤ q := by
    rw [hq, sub_nonneg, div_le_one (by positivity)]
    exact pow_le_pow_left₀ hc.le hcC 2
  have hq1 : q < 1 := by
    rw [hq]; have : 0 < c ^ 2 / C ^ 2 := by positivity
    linarith
  set T : V → V := fun x => x - ρ • (A x - f) with hT
  have hTd : ∀ x y, T x - T y = (x - y) - ρ • A (x - y) := by
    intro x y; simp only [hT, map_sub, smul_sub]; abel
  set K : NNReal := ⟨Real.sqrt q, Real.sqrt_nonneg _⟩ with hK
  have hK1 : K < 1 := by
    rw [← NNReal.coe_lt_coe]
    change Real.sqrt q < 1
    rw [Real.sqrt_lt' one_pos]; simpa using hq1
  have hLip : LipschitzWith K T := by
    refine LipschitzWith.of_dist_le_mul fun x y => ?_
    rw [dist_eq_norm, dist_eq_norm, hTd]
    have h := lax_milgram_step_shrinks A hc h_coercive h_bounded (x - y)
    change ‖(x - y) - ρ • A (x - y)‖ ≤ Real.sqrt q * ‖x - y‖
    calc ‖(x - y) - ρ • A (x - y)‖ = Real.sqrt (‖(x - y) - ρ • A (x - y)‖ ^ 2) :=
          (Real.sqrt_sq (norm_nonneg _)).symm
      _ ≤ Real.sqrt (q * ‖x - y‖ ^ 2) := Real.sqrt_le_sqrt h
      _ = Real.sqrt q * ‖x - y‖ := by
          rw [Real.sqrt_mul hq0, Real.sqrt_sq (norm_nonneg _)]
  have hcon : ContractingWith K T := ⟨hK1, hLip⟩
  set u := ContractingWith.fixedPoint T hcon
  have hfix : T u = u := ContractingWith.fixedPoint_isFixedPt hcon
  have hAu : A u = f := by
    have h1 : ρ • (A u - f) = 0 := by
      have : u - ρ • (A u - f) = u := hfix
      simpa using this
    rcases smul_eq_zero.mp h1 with h | h
    · exact absurd h hρpos.ne'
    · exact sub_eq_zero.mp h
  have hlim : Tendsto (fun n : ℕ => T^[n] u₀) atTop (𝓝 u) :=
    ContractingWith.tendsto_iterate_fixedPoint hcon u₀
  exact ⟨u, ⟨hAu, hlim⟩, fun y hy => tendsto_nhds_unique hy.2 hlim⟩

-- Four elements of 1/4 m, T = 500 N, k = 2000 N/m²: the diagonal entry 2T/h + 4kh/6 is 13000/3.
example : (2 * 500 / (1 / 4 : ℚ) + 4 * 2000 * (1 / 4) / 6) = 13000 / 3 := by norm_num

-- The entry beside it, -T/h + kh/6, is -5750/3.
example : (-500 / (1 / 4 : ℚ) + 2000 * (1 / 4) / 6) = -5750 / 3 := by norm_num

-- The load per node, q h with q = 40 N/m, is 10 N.
example : (40 : ℚ) * (1 / 4) = 10 := by norm_num

-- The three node sags 9/1646, 147/20575, 9/1646 m (0.546780, 0.714459, 0.546780 cm)
-- solve the four-element system exactly.
example : (13000 / 3 : ℚ) * (9 / 1646) + (-5750 / 3) * (147 / 20575) = 10 ∧
    (-5750 / 3 : ℚ) * (9 / 1646) + 13000 / 3 * (147 / 20575) + (-5750 / 3) * (9 / 1646) = 10 ∧
    (-5750 / 3 : ℚ) * (147 / 20575) + 13000 / 3 * (9 / 1646) = 10 := by norm_num

-- The ceiling on the size of the sag, with c = T = 500 N: the load size squared
-- is q² / 12 = 400 / 3, so the ceiling squared (|l| / c)² is 1 / 1875.
example : ((40 : ℚ) ^ 2 / 12) / 500 ^ 2 = 1 / 1875 := by norm_num

#print axioms lax_milgram_unique_solution_with_bound
#print axioms lax_milgram_step_shrinks
#print axioms lax_milgram_recipe_converges
