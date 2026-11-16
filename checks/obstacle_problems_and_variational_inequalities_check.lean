-- The obstacle problem: on a real Hilbert space, a symmetric bounded coercive energy and a closed convex nonempty admissible set give exactly one solution of the variational inequality, and solving it is the same as having the least energy among admissible shapes.
import Mathlib.Analysis.InnerProductSpace.LaxMilgram
import Mathlib.Analysis.Convex.Basic
import Mathlib.MeasureTheory.Function.L2Space
import Mathlib.Tactic.NormNum

open MeasureTheory

theorem obstacle_energy_expand
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u)
    (f : V →L[ℝ] ℝ) (u d : V) (t : ℝ) :
    (1 / 2 : ℝ) * B (u + t • d) (u + t • d) - f (u + t • d) =
      ((1 / 2 : ℝ) * B u u - f u) + t * (B u d - f d) + t ^ 2 / 2 * B d d := by
  simp only [map_add, map_smul, add_apply, FunLike.coe_smul, Pi.smul_apply,
    smul_eq_mul]
  rw [hsymm d u]
  ring

#print axioms obstacle_energy_expand

theorem obstacle_vi_of_least_energy
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u) (hcoer : IsCoercive B)
    (f : V →L[ℝ] ℝ) (K : Set V) (hconv : Convex ℝ K) {u : V} (hu : u ∈ K)
    (hmin : ∀ v ∈ K, (1 / 2 : ℝ) * B u u - f u ≤ (1 / 2 : ℝ) * B v v - f v) :
    ∀ v ∈ K, f (v - u) ≤ B u (v - u) := by
  intro v hv
  obtain ⟨C, hC, hcoerC⟩ := hcoer
  set d := v - u with hd
  have hβ : 0 ≤ B d d := le_trans (by positivity) (hcoerC d)
  have key : ∀ t : ℝ, 0 < t → t ≤ 1 → 0 ≤ t * (B u d - f d) + t ^ 2 / 2 * B d d := by
    intro t ht0 ht1
    have hmem : u + t • d ∈ K := by
      have := hconv hu hv (by linarith : (0:ℝ) ≤ 1 - t) ht0.le (by ring)
      convert this using 1
      rw [hd]; module
    have := hmin _ hmem
    rw [obstacle_energy_expand B hsymm f u d t] at this
    linarith
  by_contra hcon
  push Not at hcon
  set c := B u d - f d with hc
  have hc0 : c < 0 := by linarith
  set β := B d d
  have hpos : 0 < β - c := by linarith
  have h := key (-c / (β - c)) (div_pos (by linarith) hpos)
    ((div_le_one hpos).2 (by linarith))
  have e : (-c / (β - c)) * c + (-c / (β - c)) ^ 2 / 2 * β =
      (-c) * (c * (β - c) - c * β / 2) / (β - c) ^ 2 := by
    field_simp
    ring
  rw [e] at h
  have : 0 ≤ (-c) * (c * (β - c) - c * β / 2) := by
    have := mul_nonneg h (sq_nonneg (β - c))
    rwa [div_mul_cancel₀ _ (by positivity)] at this
  nlinarith [mul_nonneg (sq_nonneg c) hβ, pow_pos (neg_pos.2 hc0) 3]

#print axioms obstacle_vi_of_least_energy

theorem obstacle_energy_midpoint
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u)
    (f : V →L[ℝ] ℝ) (a b : V) :
    ((1 / 2 : ℝ) * B a a - f a) + ((1 / 2 : ℝ) * B b b - f b) -
      2 * ((1 / 2 : ℝ) * B ((1 / 2 : ℝ) • a + (1 / 2 : ℝ) • b) ((1 / 2 : ℝ) • a + (1 / 2 : ℝ) • b)
        - f ((1 / 2 : ℝ) • a + (1 / 2 : ℝ) • b)) = (1 / 4 : ℝ) * B (a - b) (a - b) := by
  simp only [map_add, map_sub, map_smul, add_apply, sub_apply, FunLike.coe_smul, Pi.smul_apply,
    smul_eq_mul]
  rw [hsymm b a]
  ring

#print axioms obstacle_energy_midpoint

theorem obstacle_vi_unique
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hcoer : IsCoercive B)
    (f : V →L[ℝ] ℝ) {u w : V}
    (hu : f (w - u) ≤ B u (w - u)) (hw : f (u - w) ≤ B w (u - w)) : u = w := by
  obtain ⟨C, hC, hcoerC⟩ := hcoer
  have h1 := hcoerC (w - u)
  have e1 : u - w = -(w - u) := by abel
  rw [e1, map_neg, map_neg] at hw
  have e2 : B (w - u) (w - u) = B w (w - u) - B u (w - u) := by
    simp only [map_sub, sub_apply]
    ring
  have hn : C * ‖w - u‖ * ‖w - u‖ ≤ 0 := by linarith
  have : ‖w - u‖ = 0 := by
    by_contra h
    have hp : 0 < ‖w - u‖ := lt_of_le_of_ne (norm_nonneg _) (Ne.symm h)
    nlinarith [mul_pos (mul_pos hC hp) hp]
  have := norm_eq_zero.1 this
  exact (sub_eq_zero.1 this).symm

#print axioms obstacle_vi_unique

theorem obstacle_exists_least_energy
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [CompleteSpace V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u) (hcoer : IsCoercive B)
    (f : V →L[ℝ] ℝ) (K : Set V) (hconv : Convex ℝ K) (hclosed : IsClosed K)
    (hne : K.Nonempty) :
    ∃ u ∈ K, ∀ v ∈ K, (1 / 2 : ℝ) * B u u - f u ≤ (1 / 2 : ℝ) * B v v - f v := by
  set E : V → ℝ := fun w => (1 / 2 : ℝ) * B w w - f w with hE
  obtain ⟨C, hC, hcoerC⟩ := hcoer
  have hlow : ∀ w, -(‖f‖ ^ 2 / (2 * C)) ≤ E w := by
    intro w
    have hf : f w ≤ ‖f‖ * ‖w‖ := le_trans (le_abs_self _) (f.le_opNorm w)
    have hB := hcoerC w
    have key : -(‖f‖ ^ 2) ≤ 2 * C * E w := by
      simp only [hE]
      nlinarith [sq_nonneg (C * ‖w‖ - ‖f‖)]
    rw [neg_le, le_div_iff₀ (by positivity)]
    linarith
  have hbdd : BddBelow (E '' K) := ⟨_, by rintro _ ⟨w, -, rfl⟩; exact hlow w⟩
  have hne' : (E '' K).Nonempty := hne.image E
  set m := sInf (E '' K) with hm
  have hmle : ∀ v ∈ K, m ≤ E v := fun v hv => csInf_le hbdd ⟨v, hv, rfl⟩
  have hseq : ∀ n : ℕ, ∃ w ∈ K, E w < m + 1 / ((n : ℝ) + 1) := by
    intro n
    obtain ⟨_, ⟨w, hw, rfl⟩, hlt⟩ := exists_lt_of_csInf_lt hne'
      (lt_add_of_pos_right m (by positivity : (0 : ℝ) < 1 / ((n : ℝ) + 1)))
    exact ⟨w, hw, hlt⟩
  choose w hwK hwE using hseq
  have hdist : ∀ n k N : ℕ, N ≤ n → N ≤ k →
      dist (w n) (w k) ≤ Real.sqrt (8 / C * (1 / ((N : ℝ) + 1))) := by
    intro n k N hn hk
    rw [dist_eq_norm]
    apply Real.le_sqrt_of_sq_le
    have hmid := hmle _ (hconv (hwK n) (hwK k) (by norm_num : (0 : ℝ) ≤ 1 / 2)
      (by norm_num : (0 : ℝ) ≤ 1 / 2) (by norm_num))
    have hid := obstacle_energy_midpoint B hsymm f (w n) (w k)
    have hc := hcoerC (w n - w k)
    have hn' : 1 / ((n : ℝ) + 1) ≤ 1 / ((N : ℝ) + 1) :=
      one_div_le_one_div_of_le (by positivity) (by exact_mod_cast Nat.add_le_add_right hn 1)
    have hk' : 1 / ((k : ℝ) + 1) ≤ 1 / ((N : ℝ) + 1) :=
      one_div_le_one_div_of_le (by positivity) (by exact_mod_cast Nat.add_le_add_right hk 1)
    have h1 := hwE n
    have h2 := hwE k
    simp only [hE] at hmid h1 h2
    have hb : C * ‖w n - w k‖ ^ 2 ≤ 8 * (1 / ((N : ℝ) + 1)) := by nlinarith
    rw [div_mul_eq_mul_div, le_div_iff₀ hC]
    linarith
  have hcauchy : CauchySeq w := by
    refine cauchySeq_of_le_tendsto_0 _ hdist ?_
    have := (tendsto_one_div_add_atTop_nhds_zero_nat.const_mul (8 / C)).sqrt
    simpa using this
  obtain ⟨u, hlim⟩ := cauchySeq_tendsto_of_complete hcauchy
  have huK : u ∈ K := hclosed.mem_of_tendsto hlim (Filter.Eventually.of_forall hwK)
  have hEcont : Continuous E := by
    simp only [hE]
    fun_prop
  have hEu : Filter.Tendsto (fun n => E (w n)) Filter.atTop (nhds (E u)) := (hEcont.tendsto u).comp hlim
  have hEm : Filter.Tendsto (fun n => E (w n)) Filter.atTop (nhds m) := by
    refine tendsto_of_tendsto_of_tendsto_of_le_of_le tendsto_const_nhds ?_
      (fun n => hmle _ (hwK n)) (fun n => (hwE n).le)
    have := (tendsto_one_div_add_atTop_nhds_zero_nat).const_add m
    simpa using this
  have : E u = m := tendsto_nhds_unique hEu hEm
  refine ⟨u, huK, fun v hv => ?_⟩
  have := hmle v hv
  simp only [hE] at *
  linarith

#print axioms obstacle_exists_least_energy


/-- **Stampacchia's theorem, the obstacle problem's existence and uniqueness.** Let `V` be a real
Hilbert space (for the sheet, `H^1_0(Ω)`), `B(u, v)` a bounded bilinear form that is symmetric and
coercive, `B(v, v) ≥ α ‖v‖²` with `α > 0` (for the sheet, `∫ ∇u · ∇v dA`, coercive by Poincaré),
`f` a bounded load, and `𝒦` an admissible set that is convex, closed and not empty (for the sheet,
the finite-energy sheets clamped at 0 that clear the obstacle `ψ`). Then exactly one `u` in `𝒦`
satisfies the variational inequality `B(u, v − u) ≥ f(v − u)` for every `v` in `𝒦`. -/
theorem stampacchia_exists_unique_variational_inequality
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [CompleteSpace V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u) (hcoer : IsCoercive B)
    (f : V →L[ℝ] ℝ) (K : Set V) (hconv : Convex ℝ K) (hclosed : IsClosed K)
    (hne : K.Nonempty) :
    ∃! u : V, u ∈ K ∧ ∀ v ∈ K, f (v - u) ≤ B u (v - u) := by
  obtain ⟨u, huK, hmin⟩ := obstacle_exists_least_energy B hsymm hcoer f K hconv hclosed hne
  refine ⟨u, ⟨huK, obstacle_vi_of_least_energy B hsymm hcoer f K hconv huK hmin⟩, ?_⟩
  rintro w ⟨hwK, hw⟩
  exact (obstacle_vi_unique B hcoer f
    (obstacle_vi_of_least_energy B hsymm hcoer f K hconv huK hmin w hwK) (hw u huK)).symm

/-- **Least energy is the same as the inequality.** With the energy
`E(w) = ½ B(w, w) − f(w)`, a symmetric coercive form and a convex admissible set `𝒦`, a member `u`
of `𝒦` has the least energy over `𝒦` exactly when every allowed move costs energy at the first
step: `B(u, v − u) ≥ f(v − u)` for every `v` in `𝒦`. -/
theorem least_energy_iff_variational_inequality
    {V : Type*} [NormedAddCommGroup V] [InnerProductSpace ℝ V] [CompleteSpace V]
    (B : V →L[ℝ] V →L[ℝ] ℝ) (hsymm : ∀ u v, B u v = B v u) (hcoer : IsCoercive B)
    (f : V →L[ℝ] ℝ) (K : Set V) (hconv : Convex ℝ K) {u : V} (hu : u ∈ K) :
    (∀ v ∈ K, (1 / 2 : ℝ) * B u u - f u ≤ (1 / 2 : ℝ) * B v v - f v) ↔
      ∀ v ∈ K, f (v - u) ≤ B u (v - u) := by
  refine ⟨obstacle_vi_of_least_energy B hsymm hcoer f K hconv hu, fun h v hv => ?_⟩
  have hvi := h v hv
  obtain ⟨C, hC, hc⟩ := hcoer
  have e := obstacle_energy_expand B hsymm f u (v - u) 1
  rw [one_smul, add_sub_cancel] at e
  have hβ : 0 ≤ B (v - u) (v - u) := le_trans (by positivity) (hc (v - u))
  rw [e]
  nlinarith

/-- **The obstacle set qualifies.** The functions that stay above an obstacle `ψ` at almost every
point, `{v : v ≥ ψ}`, form a convex and closed set among the square-integrable functions: any mix
of two allowed functions is allowed, and a mean-square limit of allowed functions is allowed. -/
theorem obstacle_set_convex_and_closed {X : Type*} [MeasurableSpace X] (μ : Measure X)
    (ψ : X → ℝ) :
    Convex ℝ {v : Lp ℝ 2 μ | ∀ᵐ x ∂μ, ψ x ≤ (v : X → ℝ) x} ∧
      IsClosed {v : Lp ℝ 2 μ | ∀ᵐ x ∂μ, ψ x ≤ (v : X → ℝ) x} := by
  constructor
  · intro v hv w hw a b ha hb hab
    simp only [Set.mem_ofPred_eq] at *
    filter_upwards [hv, hw, Lp.coeFn_add (a • v) (b • w), Lp.coeFn_smul a v,
      Lp.coeFn_smul b w] with x h1 h2 h3 h4 h5
    rw [h3, Pi.add_apply, h4, h5, Pi.smul_apply, Pi.smul_apply, smul_eq_mul, smul_eq_mul]
    calc ψ x = a * ψ x + b * ψ x := by rw [← add_mul, hab, one_mul]
      _ ≤ a * v x + b * w x := by nlinarith [mul_le_mul_of_nonneg_left h1 ha,
          mul_le_mul_of_nonneg_left h2 hb]
  · rw [← isSeqClosed_iff_isClosed]
    intro v g hv hlim
    have h1 := (Lp.tendsto_Lp_iff_tendsto_eLpNorm' v g).1 hlim
    have hm := tendstoInMeasure_of_tendsto_eLpNorm (by norm_num) h1
    obtain ⟨ns, -, hae⟩ := hm.exists_seq_tendsto_ae
    have hall : ∀ᵐ x ∂μ, ∀ n, ψ x ≤ (v n : X → ℝ) x := ae_all_iff.2 hv
    show ∀ᵐ x ∂μ, ψ x ≤ (g : X → ℝ) x
    filter_upwards [hae, hall] with x hx hx2
    exact ge_of_tendsto' hx (fun i => hx2 (ns i))

-- Step 0, the fenced bowl: (x − 1)² at the fence x = 3 is 4, and its slope 2 (x − 1) there is 4, not 0.
example : ((3 : ℤ) - 1) ^ 2 = 4 ∧ 2 * ((3 : ℤ) - 1) = 4 := by norm_num
-- The stone (radius 10 cm, centre 8 cm below the hoop plane) has its top 10 − 8 = 2 cm above the hoop.
example : (10 : ℤ) - 8 = 2 := by norm_num
-- The stone crosses the hoop plane at 6 cm from the centre: 6² + 8² = 10².
example : (6 : ℕ) ^ 2 + 8 ^ 2 = 10 ^ 2 := by norm_num
-- Pressure at the top: T × 2/ρ = 50 N/m × 20 per m = 1000 Pa.
example : (50 : ℕ) * 20 = 1000 := by norm_num

#print axioms stampacchia_exists_unique_variational_inequality
#print axioms least_energy_iff_variational_inequality
#print axioms obstacle_set_convex_and_closed
