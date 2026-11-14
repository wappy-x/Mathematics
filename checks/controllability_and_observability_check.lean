-- Can you steer every state, and can you see every state: for x' = Ax + Bu and y = Cx, every state can be steered to every other state exactly when [B AB … A^(n-1)B] has rank n, no nonzero start is invisible to the sensor exactly when the stacked rows C, CA, …, CA^(n-1) have rank n, the second matrix is the first one built from Aᵀ and Cᵀ, and the cart-and-rod numbers on the card check out exactly.
import Mathlib.Analysis.Normed.Algebra.MatrixExponential
import Mathlib.MeasureTheory.Integral.IntervalIntegral.Basic
import Mathlib.LinearAlgebra.Matrix.Rank
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.SpecialFunctions.Exponential
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.LinearAlgebra.Matrix.Charpoly.Coeff

open Matrix NormedSpace

/-- The controllability matrix `[B  AB  A²B  …  A^(n-1)B]`: its column `(k, j)` is column `j`
of `A^k B`, for `k = 0, …, n-1`. -/
def ctrb {K : Type*} [Field K] {n m : ℕ} (A : Matrix (Fin n) (Fin n) K)
    (B : Matrix (Fin n) (Fin m) K) : Matrix (Fin n) (Fin n × Fin m) K :=
  Matrix.of fun i kj => (A ^ (kj.1 : ℕ) * B) i kj.2

/-- The observability matrix with rows `C, CA, CA², …, CA^(n-1)`: its row `(k, i)` is row `i`
of `C A^k`, for `k = 0, …, n-1`. -/
def obsv {K : Type*} [Field K] {n p : ℕ} (A : Matrix (Fin n) (Fin n) K)
    (C : Matrix (Fin p) (Fin n) K) : Matrix (Fin n × Fin p) (Fin n) K :=
  Matrix.of fun ki j => (C * A ^ (ki.1 : ℕ)) ki.2 j

/-- The map `M ↦ f (M *ᵥ w)` as a linear map on square matrices. -/
def evalLin {n : ℕ} (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (w : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ →ₗ[ℝ] ℝ where
  toFun M := f (M *ᵥ w)
  map_add' M N := by simp [Matrix.add_mulVec]
  map_smul' c M := by simp [Matrix.smul_mulVec]

set_option backward.isDefEq.respectTransparency false in
theorem hasDerivAt_evalLin_exp {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (w : Fin n → ℝ) (s : ℝ) :
    HasDerivAt (fun t : ℝ => f (exp (t • A) *ᵥ w)) (f (exp (s • A) *ᵥ (A *ᵥ w))) s := by
  open scoped Matrix.Norms.Operator in
  have h := HasFDerivAt.comp_hasDerivAt s
    (LinearMap.toContinuousLinearMap (evalLin f w)).hasFDerivAt
    (hasDerivAt_exp_smul_const (𝕂 := ℝ) A s)
  rw [Matrix.mulVec_mulVec]
  convert h using 1
  · funext t; rfl
  · rfl

set_option backward.isDefEq.respectTransparency false in
theorem continuous_exp_smul {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ) :
    Continuous (fun t : ℝ => exp (t • A)) := by
  open scoped Matrix.Norms.Operator in
  exact exp_continuous.comp (continuous_id.smul continuous_const)

set_option backward.isDefEq.respectTransparency false in
theorem evalLin_exp_eq_zero {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (w : Fin n → ℝ) (h : ∀ k : ℕ, f ((A ^ k) *ᵥ w) = 0) (s : ℝ) :
    f (exp (s • A) *ᵥ w) = 0 := by
  open scoped Matrix.Norms.Operator in
  have h1 := (exp_series_hasSum_exp' (𝕂 := ℝ) (s • A)).mapL
    (LinearMap.toContinuousLinearMap (evalLin f w))
  have h2 : (fun k : ℕ => (LinearMap.toContinuousLinearMap (evalLin f w))
      (((k.factorial : ℝ)⁻¹) • (s • A) ^ k)) = fun _ => 0 := by
    funext k
    simp [evalLin, smul_pow, h k]
  rw [h2] at h1
  simpa [evalLin] using h1.unique hasSum_zero

theorem evalLin_exp_pow_of_open {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (U : Set ℝ) (hU : IsOpen U) (k : ℕ) :
    ∀ w : Fin n → ℝ, (∀ s ∈ U, f (exp (s • A) *ᵥ w) = 0) →
      ∀ s ∈ U, f (exp (s • A) *ᵥ ((A ^ k) *ᵥ w)) = 0 := by
  induction k with
  | zero => intro w h; simpa using h
  | succ k ih =>
    intro w h s hs
    have h1 := ih w h
    have hd := hasDerivAt_evalLin_exp A f ((A ^ k) *ᵥ w) s
    have h0 : HasDerivAt (fun t : ℝ => f (exp (t • A) *ᵥ ((A ^ k) *ᵥ w))) 0 s := by
      apply (hasDerivAt_const s (0 : ℝ)).congr_of_eventuallyEq
      filter_upwards [hU.mem_nhds hs] with t ht using h1 t ht
    rw [pow_succ', ← Matrix.mulVec_mulVec]
    exact hd.unique h0

theorem pow_mulVec_eq_zero_of_lt {n : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (w : Fin n → ℝ) (h : ∀ k < n, f ((A ^ k) *ᵥ w) = 0) (k : ℕ) :
    f ((A ^ k) *ᵥ w) = 0 := by
  rcases Nat.eq_zero_or_pos n with rfl | hn
  · have : (A ^ k) *ᵥ w = 0 := Subsingleton.elim _ _
    rw [this, map_zero]
  have hdeg : (Polynomial.X ^ k %ₘ (Matrix.charpoly A)).natDegree < n := by
    have hne : (Matrix.charpoly A) ≠ 1 := by
      intro h1
      have := Matrix.charpoly_natDegree_eq_dim A
      rw [h1] at this
      simp at this
      omega
    simpa using Polynomial.natDegree_modByMonic_lt (Polynomial.X ^ k) (Matrix.charpoly_monic A) hne
  rw [Matrix.pow_eq_aeval_mod_charpoly, Polynomial.aeval_eq_sum_range' hdeg, Matrix.sum_mulVec,
    map_sum]
  apply Finset.sum_eq_zero
  intro i hi
  rw [Matrix.smul_mulVec, map_smul, h i (Finset.mem_range.1 hi), smul_zero]

theorem exp_mulVec_eq_zero {n : ℕ} (M : Matrix (Fin n) (Fin n) ℝ) (x : Fin n → ℝ)
    (h : exp M *ᵥ x = 0) : x = 0 := by
  have h1 : exp (-M) * exp M = 1 := by
    rw [← Matrix.exp_add_of_commute _ _ (Commute.neg_left (Commute.refl M)), neg_add_cancel,
      exp_zero]
  calc x = (exp (-M) * exp M) *ᵥ x := by rw [h1, Matrix.one_mulVec]
    _ = 0 := by rw [← Matrix.mulVec_mulVec, h, Matrix.mulVec_zero]

theorem rank_eq_iff_mulVec_injective {ι : Type*} [Fintype ι] {n : ℕ} (M : Matrix ι (Fin n) ℝ) :
    M.rank = n ↔ ∀ x : Fin n → ℝ, M *ᵥ x = 0 → x = 0 := by
  have h := M.mulVecLin.finrank_range_add_finrank_ker
  rw [Module.finrank_fin_fun] at h
  unfold Matrix.rank
  constructor
  · intro hr x hx
    have h0 : Module.finrank ℝ (LinearMap.ker M.mulVecLin) = 0 := by omega
    have hb := Submodule.finrank_eq_zero.mp h0
    have : x ∈ LinearMap.ker M.mulVecLin := by simpa using hx
    rw [hb] at this
    simpa using this
  · intro hinj
    have hb : LinearMap.ker M.mulVecLin = ⊥ := by
      rw [eq_bot_iff]
      intro x hx
      simpa using hinj x (by simpa using hx)
    rw [hb, finrank_bot] at h
    omega

theorem linear_mulVec_expand {n : ℕ} {ι : Type*} [Fintype ι] [DecidableEq ι]
    (f : (Fin n → ℝ) →ₗ[ℝ] ℝ) (M : Matrix (Fin n) ι ℝ) (y : ι → ℝ) : f (M *ᵥ y) = ∑ j, y j * f (M *ᵥ Pi.single j 1) := by
  have := (f ∘ₗ M.mulVecLin).pi_apply_eq_sum_univ y
  simp only [LinearMap.comp_apply, Matrix.mulVecLin_apply, smul_eq_mul] at this
  rw [this]
  refine Finset.sum_congr rfl fun j _ => ?_
  congr 3
  funext i
  simp [Pi.single_apply, eq_comm]

#print axioms evalLin
#print axioms hasDerivAt_evalLin_exp
#print axioms continuous_exp_smul
#print axioms evalLin_exp_eq_zero
#print axioms evalLin_exp_pow_of_open
#print axioms pow_mulVec_eq_zero_of_lt
#print axioms exp_mulVec_eq_zero
#print axioms rank_eq_iff_mulVec_injective
#print axioms linear_mulVec_expand

/-- Rank test for steering. For the linear plant `x' = Ax + Bu` with fixed matrices and an
unlimited push, the motor can steer every state: for every window `T > 0`, every start `x₀` and
every target `x_f`, some continuous push `u` carries `x₀` to `x_f` in time `T`, where the state
at time `T` is `e^(AT) x₀ + ∫₀ᵀ e^(A(T-t)) B u(t) dt`. This happens exactly when the
controllability matrix `[B AB … A^(n-1)B]` has rank `n`. -/
theorem controllable_iff_rank_ctrb_eq {n m : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (B : Matrix (Fin n) (Fin m) ℝ) :
    (ctrb A B).rank = n ↔
      ∀ T : ℝ, 0 < T → ∀ x₀ x_f : Fin n → ℝ, ∃ u : ℝ → Fin m → ℝ, Continuous u ∧
        exp (T • A) *ᵥ x₀ + ∫ t in (0 : ℝ)..T, exp ((T - t) • A) *ᵥ (B *ᵥ u t) = x_f := by
  have hcol : ∀ (k : Fin n) (j : Fin m),
      ctrb A B *ᵥ Pi.single (k, j) 1 = (A ^ (k : ℕ)) *ᵥ (B *ᵥ Pi.single j 1) := by
    intro k j
    rw [Matrix.mulVec_single_one, Matrix.mulVec_mulVec, Matrix.mulVec_single_one]
    rfl
  have hrank : (ctrb A B).rank = n ↔ LinearMap.range (ctrb A B).mulVecLin = ⊤ := by
    unfold Matrix.rank
    constructor
    · intro h
      apply Submodule.eq_top_of_finrank_eq
      rw [h, Module.finrank_fin_fun]
    · intro h
      rw [h, finrank_top, Module.finrank_fin_fun]
  have hcont : ∀ (T : ℝ) (u : ℝ → Fin m → ℝ), Continuous u →
      Continuous (fun t => exp ((T - t) • A) *ᵥ (B *ᵥ u t)) := by
    intro T u hu
    exact ((continuous_exp_smul A).comp (continuous_const.sub continuous_id)).matrix_mulVec
      (continuous_const.matrix_mulVec hu)
  rw [hrank]
  constructor
  · intro htop T hT x₀ x_f
    let L : C(ℝ, Fin m → ℝ) →ₗ[ℝ] (Fin n → ℝ) :=
      { toFun := fun u => ∫ t in (0 : ℝ)..T, exp ((T - t) • A) *ᵥ (B *ᵥ u t)
        map_add' := fun u v => by
          simp only [ContinuousMap.add_apply, Matrix.mulVec_add]
          exact intervalIntegral.integral_add ((hcont T u u.continuous).intervalIntegrable _ _)
            ((hcont T v v.continuous).intervalIntegrable _ _)
        map_smul' := fun c u => by
          simp only [ContinuousMap.smul_apply, Matrix.mulVec_smul, RingHom.id_apply]
          exact intervalIntegral.integral_smul c _ }
    have hL : LinearMap.range L = ⊤ := by
      by_contra hne
      obtain ⟨f, hf0, hle⟩ := Submodule.exists_le_ker_of_lt_top _ (lt_top_iff_ne_top.2 hne)
      have hfc : Continuous f := LinearMap.continuous_of_finiteDimensional f
      let g : Fin m → ℝ → ℝ := fun j s => f (exp (s • A) *ᵥ (B *ᵥ Pi.single j 1))
      have hgc : ∀ j, Continuous (g j) := fun j =>
        hfc.comp ((continuous_exp_smul A).matrix_mulVec continuous_const)
      let u : C(ℝ, Fin m → ℝ) := ⟨fun t j => g j (T - t),
        continuous_pi fun j => (hgc j).comp (continuous_const.sub continuous_id)⟩
      let h : ℝ → ℝ := fun t => ∑ j, g j (T - t) ^ 2
      have hhc : Continuous h := continuous_finsetSum _ fun j _ =>
        ((hgc j).comp (continuous_const.sub continuous_id)).pow 2
      have hh0 : 0 ≤ h := fun t => Finset.sum_nonneg fun j _ => sq_nonneg _
      have hint : ∫ t in (0 : ℝ)..T, h t = 0 := by
        have h1 : f (L u) = 0 := hle (LinearMap.mem_range_self L u)
        have h2 : f (L u) = ∫ t in (0 : ℝ)..T, f (exp ((T - t) • A) *ᵥ (B *ᵥ u t)) :=
          ((LinearMap.toContinuousLinearMap f).intervalIntegral_comp_comm
            ((hcont T u u.continuous).intervalIntegrable _ _)).symm
        refine (intervalIntegral.integral_congr fun t _ => ?_).trans (h2.symm.trans h1)
        simp only [h]
        rw [Matrix.mulVec_mulVec, linear_mulVec_expand f _ (u t)]
        refine Finset.sum_congr rfl fun j _ => ?_
        rw [← Matrix.mulVec_mulVec]
        simp [u, g, sq]
      have hzero : ∀ t ∈ Set.Ioo 0 T, h t = 0 := by
        intro t ht
        by_contra hne
        have hpos : 0 < h t := lt_of_le_of_ne (hh0 t) (Ne.symm hne)
        have hint_pos : 0 < ∫ t in (0 : ℝ)..T, h t := by
          rw [intervalIntegral.integral_pos_iff_support_of_nonneg_ae
            (Filter.Eventually.of_forall hh0) (hhc.intervalIntegrable _ _)]
          refine ⟨hT, ?_⟩
          have hopen : IsOpen ({s | 0 < h s} ∩ Set.Ioo 0 T) :=
            (isOpen_lt continuous_const hhc).inter isOpen_Ioo
          have hne' : ({s | 0 < h s} ∩ Set.Ioo 0 T).Nonempty := ⟨t, hpos, ht⟩
          refine lt_of_lt_of_le (hopen.measure_pos _ hne') (MeasureTheory.measure_mono ?_)
          rintro s ⟨hs1, hs2⟩
          exact ⟨ne_of_gt hs1, Set.Ioo_subset_Ioc_self hs2⟩
        linarith
      have hg0 : ∀ j, ∀ s ∈ Set.Ioo 0 T, f (exp (s • A) *ᵥ (B *ᵥ Pi.single j 1)) = 0 := by
        intro j s hs
        have hts : T - s ∈ Set.Ioo 0 T := ⟨by linarith [hs.2], by linarith [hs.1]⟩
        have h3 := hzero (T - s) hts
        simp only [h, sub_sub_cancel] at h3
        have h4 := (Finset.sum_eq_zero_iff_of_nonneg (fun j _ => sq_nonneg (g j s))).1 h3 j
          (Finset.mem_univ _)
        exact (pow_eq_zero_iff two_ne_zero).1 h4
      have hs₀ : T / 2 ∈ Set.Ioo 0 T := ⟨by positivity, by linarith⟩
      let ψ : (Fin n → ℝ) →ₗ[ℝ] ℝ := f ∘ₗ (exp ((T / 2) • A)).mulVecLin
      have hψ : ∀ v, ψ (ctrb A B *ᵥ v) = 0 := by
        intro v
        rw [linear_mulVec_expand ψ _ v]
        refine Finset.sum_eq_zero fun kj _ => ?_
        rw [hcol]
        have := evalLin_exp_pow_of_open A f (Set.Ioo 0 T) isOpen_Ioo kj.1 _ (hg0 kj.2) (T / 2) hs₀
        simp only [ψ, LinearMap.comp_apply, Matrix.mulVecLin_apply]
        rw [this, mul_zero]
      apply hf0
      apply LinearMap.ext
      intro z
      have hinv : exp ((T / 2) • A) * exp (-((T / 2) • A)) = 1 := by
        rw [← Matrix.exp_add_of_commute _ _ (Commute.refl ((T / 2) • A)).neg_right, add_neg_cancel,
          exp_zero]
      have hz : z ∈ LinearMap.range (ctrb A B).mulVecLin := htop ▸ Submodule.mem_top
      obtain ⟨v, hv⟩ := hz
      have e1 : z = exp ((T / 2) • A) *ᵥ (exp (-((T / 2) • A)) *ᵥ z) := by
        rw [Matrix.mulVec_mulVec, hinv, Matrix.one_mulVec]
      rw [LinearMap.zero_apply, e1]
      have hw : exp (-((T / 2) • A)) *ᵥ z ∈ LinearMap.range (ctrb A B).mulVecLin :=
        htop ▸ Submodule.mem_top
      obtain ⟨v', hv'⟩ := hw
      rw [← hv']
      exact hψ v'
    have hmem : x_f - exp (T • A) *ᵥ x₀ ∈ LinearMap.range L := hL ▸ Submodule.mem_top
    obtain ⟨u, hu⟩ := hmem
    refine ⟨u, u.continuous, ?_⟩
    change exp (T • A) *ᵥ x₀ + L u = x_f
    rw [hu]
    abel
  · intro H
    by_contra hne
    obtain ⟨f, hf0, hle⟩ := Submodule.exists_le_ker_of_lt_top _ (lt_top_iff_ne_top.2 hne)
    have hk : ∀ j, ∀ k < n, f ((A ^ k) *ᵥ (B *ᵥ Pi.single j 1)) = 0 := by
      intro j k hk
      have := hle (LinearMap.mem_range_self (ctrb A B).mulVecLin (Pi.single (⟨k, hk⟩, j) 1))
      rw [LinearMap.mem_ker, Matrix.mulVecLin_apply, hcol] at this
      exact this
    have hexp : ∀ (s : ℝ) (y : Fin m → ℝ), f (exp (s • A) *ᵥ (B *ᵥ y)) = 0 := by
      intro s y
      rw [Matrix.mulVec_mulVec, linear_mulVec_expand f _ y]
      refine Finset.sum_eq_zero fun j _ => ?_
      rw [← Matrix.mulVec_mulVec,
        evalLin_exp_eq_zero A f _ (pow_mulVec_eq_zero_of_lt A f _ (hk j)) s, mul_zero]
    obtain ⟨z, hz⟩ : ∃ z, f z ≠ 0 := by
      by_contra hcon
      exact hf0 (LinearMap.ext fun z => not_not.1 fun hz => hcon ⟨z, hz⟩)
    obtain ⟨u, hu, hT⟩ := H 1 one_pos 0 z
    rw [Matrix.mulVec_zero, zero_add] at hT
    apply hz
    have h2 := (LinearMap.toContinuousLinearMap f).intervalIntegral_comp_comm
      ((hcont 1 u hu).intervalIntegrable (μ := MeasureTheory.volume) 0 1)
    rw [← hT]
    change (LinearMap.toContinuousLinearMap f) _ = 0
    rw [← h2]
    simp only [LinearMap.coe_toContinuousLinearMap', hexp, intervalIntegral.integral_zero]

/-- Rank test for seeing. With no push the reading is `y(t) = C e^(At) x₀`. The sensor sees every
state (the only start whose reading stays 0 for all `t ≥ 0` is the zero state) exactly when the
observability matrix with rows `C, CA, …, CA^(n-1)` has rank `n`. -/
theorem observable_iff_rank_obsv_eq {n p : ℕ} (A : Matrix (Fin n) (Fin n) ℝ)
    (C : Matrix (Fin p) (Fin n) ℝ) :
    (obsv A C).rank = n ↔
      ∀ x₀ : Fin n → ℝ, (∀ t : ℝ, 0 ≤ t → C *ᵥ (exp (t • A) *ᵥ x₀) = 0) → x₀ = 0 := by
  rw [rank_eq_iff_mulVec_injective]
  have key : ∀ x : Fin n → ℝ, obsv A C *ᵥ x = 0 ↔ ∀ k < n, C *ᵥ ((A ^ k) *ᵥ x) = 0 := by
    intro x
    have e : ∀ ki : Fin n × Fin p,
        (obsv A C *ᵥ x) ki = (C *ᵥ ((A ^ (ki.1 : ℕ)) *ᵥ x)) ki.2 := fun ki => by
      rw [Matrix.mulVec_mulVec]; rfl
    constructor
    · intro hx k hk
      funext i
      have := congrFun hx (⟨k, hk⟩, i)
      rw [e] at this
      simpa using this
    · intro hx
      funext ki
      rw [e, hx ki.1 ki.1.2]
      rfl
  let fr : Fin p → (Fin n → ℝ) →ₗ[ℝ] ℝ := fun i => (LinearMap.proj i) ∘ₗ C.mulVecLin
  have hfr : ∀ i v, fr i v = (C *ᵥ v) i := fun i v => rfl
  constructor
  · intro hinj x₀ hx
    apply exp_mulVec_eq_zero ((1 : ℝ) • A)
    apply hinj
    rw [key]
    intro k hk
    funext i
    have h1 := evalLin_exp_pow_of_open A (fr i) (Set.Ioi 0) isOpen_Ioi k x₀
      (fun s hs => by rw [hfr, hx s (le_of_lt hs)]; rfl) 1 (by norm_num)
    rw [hfr] at h1
    have hc : Commute (exp ((1 : ℝ) • A)) (A ^ k) :=
      (((Commute.refl A).smul_left (1 : ℝ)).pow_right k).exp_left
    have he : (A ^ k) *ᵥ (exp ((1 : ℝ) • A) *ᵥ x₀) = exp ((1 : ℝ) • A) *ᵥ ((A ^ k) *ᵥ x₀) := by
      rw [Matrix.mulVec_mulVec, Matrix.mulVec_mulVec, hc.eq]
    rw [he]
    simpa using h1
  · intro H x hx
    rw [key] at hx
    apply H
    intro t _
    funext i
    have h2 := evalLin_exp_eq_zero A (fr i) x
      (pow_mulVec_eq_zero_of_lt A (fr i) x (fun k hk => by rw [hfr, hx k hk]; rfl)) t
    simpa [hfr] using h2

/-- Duality: the observability matrix of `(A, C)` is the controllability matrix of the transposed
plant `(Aᵀ, Cᵀ)`, laid on its side. So the seeing test is the steering test run on the transposed
matrices. -/
theorem obsv_eq_ctrb_transpose_transpose {K : Type*} [Field K] {n p : ℕ}
    (A : Matrix (Fin n) (Fin n) K) (C : Matrix (Fin p) (Fin n) K) :
    obsv A C = (ctrb Aᵀ Cᵀ)ᵀ := by
  ext ki j
  simp [obsv, ctrb, ← Matrix.transpose_pow, ← Matrix.transpose_mul]

/-! ### The card's cart and rod, exactly

Rod length `l = 0.613125 = 981/1600` m and `g = 9.81` m/s², so `g/l = 16` and `1/l = 1600/981`.
State `(p, v, θ, ω)`; the motor sets the cart's acceleration. -/

/-- The cart-and-rod matrix `A`: `p' = v`, `v' = u`, `θ' = ω`, `ω' = 16 θ - u/l`. -/
def cartA : Matrix (Fin 4) (Fin 4) ℚ := !![0, 1, 0, 0; 0, 0, 0, 0; 0, 0, 0, 1; 0, 0, 16, 0]
/-- The push direction `B = (0, 1, 0, -1/l)`. -/
def cartB : Matrix (Fin 4) (Fin 1) ℚ := !![0; 1; 0; -1600 / 981]
/-- The cart encoder reads `p`. -/
def cartEncoder : Matrix (Fin 1) (Fin 4) ℚ := !![1, 0, 0, 0]
/-- The tip sensor reads `p + l θ`. -/
def tipSensor : Matrix (Fin 1) (Fin 4) ℚ := !![1, 0, 981 / 1600, 0]

theorem cartA_sq : cartA ^ 2 = !![0, 0, 0, 0; 0, 0, 0, 0; 0, 0, 16, 0; 0, 0, 0, 16] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [cartA, sq, Matrix.mul_apply, Fin.sum_univ_succ]

theorem cartA_cube : cartA ^ 3 = !![0, 0, 0, 0; 0, 0, 0, 0; 0, 0, 0, 16; 0, 0, 256, 0] := by
  rw [pow_succ, cartA_sq]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [cartA, Matrix.mul_apply, Fin.sum_univ_succ]

theorem rank_eq_of_mul_right_inv {ι κ : Type*} [Fintype ι] [Fintype κ] [DecidableEq ι]
    (M : Matrix ι κ ℚ) (N : Matrix κ ι ℚ) (h : M * N = 1) : M.rank = Fintype.card ι := by
  refine le_antisymm (Matrix.rank_le_card_height M) ?_
  have := Matrix.rank_mul_le_left M N
  rwa [h, Matrix.rank_one] at this

theorem rank_eq_of_mul_left_inv {ι κ : Type*} [Fintype ι] [Fintype κ] [DecidableEq κ]
    (M : Matrix ι κ ℚ) (N : Matrix κ ι ℚ) (h : N * M = 1) : M.rank = Fintype.card κ := by
  refine le_antisymm (Matrix.rank_le_card_width M) ?_
  have := Matrix.rank_mul_le_right N M
  rwa [h, Matrix.rank_one] at this

theorem le_rank_of_mul_mul_eq_one {ι κ γ : Type*} [Fintype ι] [Fintype κ] [Fintype γ]
    [DecidableEq γ] (P : Matrix γ ι ℚ) (M : Matrix ι κ ℚ) (Q : Matrix κ γ ℚ) (h : P * M * Q = 1) :
    Fintype.card γ ≤ M.rank := by
  have h1 := (Matrix.rank_mul_le_left (P * M) Q).trans (Matrix.rank_mul_le_right P M)
  rwa [h, Matrix.rank_one] at h1

theorem cart_ctrb_eq : ctrb cartA cartB = Matrix.of fun i kj => (![![0, 1, 0, 0], ![1, 0, 0, 0],
    ![0, -1600 / 981, 0, -25600 / 981], ![-1600 / 981, 0, -25600 / 981, 0]] : Fin 4 → Fin 4 → ℚ) i kj.1 := by
  ext i ⟨k, j⟩
  fin_cases j
  fin_cases k <;> fin_cases i <;>
    simp [ctrb, cartA_sq, cartA_cube] <;>
    norm_num [cartA, cartB, Matrix.mul_apply, Fin.sum_univ_succ]

theorem cart_obsv_encoder_eq : obsv cartA cartEncoder = Matrix.of fun ki j => (![![1, 0, 0, 0],
    ![0, 1, 0, 0], ![0, 0, 0, 0], ![0, 0, 0, 0]] : Fin 4 → Fin 4 → ℚ) ki.1 j := by
  ext ⟨k, i⟩ j
  fin_cases i
  fin_cases k <;> fin_cases j <;>
    simp [obsv, cartA_sq, cartA_cube] <;>
    norm_num [cartA, cartEncoder, Matrix.mul_apply, Fin.sum_univ_succ]

theorem cart_obsv_tip_eq : obsv cartA tipSensor = Matrix.of fun ki j => (![![1, 0, 981 / 1600, 0],
    ![0, 1, 0, 981 / 1600], ![0, 0, 981 / 100, 0], ![0, 0, 0, 981 / 100]] : Fin 4 → Fin 4 → ℚ) ki.1 j := by
  ext ⟨k, i⟩ j
  fin_cases i
  fin_cases k <;> fin_cases j <;>
    simp [obsv, cartA_sq, cartA_cube] <;>
    norm_num [cartA, tipSensor, Matrix.mul_apply, Fin.sum_univ_succ]

#print axioms cartA_sq
#print axioms cartA_cube
#print axioms rank_eq_of_mul_right_inv
#print axioms rank_eq_of_mul_left_inv
#print axioms le_rank_of_mul_mul_eq_one
#print axioms cart_ctrb_eq
#print axioms cart_obsv_encoder_eq
#print axioms cart_obsv_tip_eq

-- Step 1 (Cayley–Hamilton): A⁴ = 16 A², so higher powers fold back onto the first four.
example : cartA ^ 4 = 16 • cartA ^ 2 := by
  rw [show cartA ^ 4 = cartA ^ 2 * cartA ^ 2 by rw [← pow_add], cartA_sq]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_succ]

-- Worked numbers, steps 2–4: AB, A²B, A³B (−26.0958 is −25600/981).
example : cartA * cartB = !![1; 0; -1600 / 981; 0] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [cartA, cartB, Matrix.mul_apply, Fin.sum_univ_succ]
example : cartA ^ 2 * cartB = !![0; 0; 0; -25600 / 981] := by
  rw [cartA_sq]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [cartB, Matrix.mul_apply, Fin.sum_univ_succ]
example : cartA ^ 3 * cartB = !![0; 0; -25600 / 981; 0] := by
  rw [cartA_cube]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [cartB, Matrix.mul_apply, Fin.sum_univ_succ]

-- Step 5: the one motor can steer all four numbers (rank 4).
example : (ctrb cartA cartB).rank = 4 := by
  rw [rank_eq_of_mul_right_inv _ (Matrix.of fun kj i => (![![0, 1, 0, 0], ![1, 0, 0, 0],
    ![0, -1 / 16, 0, -981 / 25600], ![-1 / 16, 0, -981 / 25600, 0]] : Fin 4 → Fin 4 → ℚ) kj.1 i),
    Fintype.card_fin]
  rw [cart_ctrb_eq]
  ext i j
  fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fintype.sum_prod_type, Fin.sum_univ_succ, Matrix.one_apply]

-- Step 6: the cart encoder's rows are (1,0,0,0), (0,1,0,0), 0, 0, so it is blind to the rod (rank 2).
example : cartEncoder * cartA = !![0, 1, 0, 0] := by
  ext i j
  fin_cases i <;> fin_cases j <;> simp [cartA, cartEncoder, Matrix.mul_apply, Fin.sum_univ_succ]
example : cartEncoder * cartA ^ 2 = 0 := by
  rw [cartA_sq]
  ext i j
  fin_cases i <;> fin_cases j <;> simp [cartEncoder, Matrix.mul_apply, Fin.sum_univ_succ]
example : (obsv cartA cartEncoder).rank = 2 := by
  refine le_antisymm ?_ ?_
  · have h : obsv cartA cartEncoder =
        (Matrix.of fun ki c => (![![1, 0], ![0, 1], ![0, 0], ![0, 0]] : Fin 4 → Fin 2 → ℚ) ki.1 c) *
        (!![1, 0, 0, 0; 0, 1, 0, 0] : Matrix (Fin 2) (Fin 4) ℚ) := by
      rw [cart_obsv_encoder_eq]
      ext ⟨k, i⟩ j
      fin_cases i
      fin_cases k <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_succ]
    rw [h]
    exact (Matrix.rank_mul_le_right _ _).trans (Matrix.rank_le_height _)
  · have h : (Matrix.of fun c ki => (![![1, 0, 0, 0], ![0, 1, 0, 0]] : Fin 2 → Fin 4 → ℚ) c ki.1 :
        Matrix (Fin 2) (Fin 4 × Fin 1) ℚ) * obsv cartA cartEncoder *
        (!![1, 0; 0, 1; 0, 0; 0, 0] : Matrix (Fin 4) (Fin 2) ℚ) = 1 := by
      rw [cart_obsv_encoder_eq]
      ext i j
      fin_cases i <;> fin_cases j <;>
        norm_num [Matrix.mul_apply, Fintype.sum_prod_type, Fin.sum_univ_succ, Matrix.one_apply]
    have h1 := le_rank_of_mul_mul_eq_one _ _ _ h
    rwa [Fintype.card_fin] at h1

-- Step 7: the tip sensor's rows are (1,0,l,0), (0,1,0,l), (0,0,16l,0), (0,0,0,16l), with 16 l = 9.81 (rank 4).
example : tipSensor * cartA ^ 2 = !![0, 0, 981 / 100, 0] := by
  rw [cartA_sq]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [tipSensor, Matrix.mul_apply, Fin.sum_univ_succ]
example : tipSensor * cartA ^ 3 = !![0, 0, 0, 981 / 100] := by
  rw [cartA_cube]
  ext i j
  fin_cases i <;> fin_cases j <;> norm_num [tipSensor, Matrix.mul_apply, Fin.sum_univ_succ]
example : (obsv cartA tipSensor).rank = 4 := by
  rw [rank_eq_of_mul_left_inv _ (Matrix.of fun j ki => (![![1, 0, -1 / 16, 0], ![0, 1, 0, -1 / 16],
    ![0, 0, 100 / 981, 0], ![0, 0, 0, 100 / 981]] : Fin 4 → Fin 4 → ℚ) j ki.1),
    Fintype.card_fin]
  rw [cart_obsv_tip_eq]
  ext i j
  fin_cases i <;> fin_cases j <;>
    norm_num [Matrix.mul_apply, Fintype.sum_prod_type, Fin.sum_univ_succ, Matrix.one_apply]

-- Steps 8–9: the bare cart's Gramian over 2 s is [[8/3, 2], [2, 2]], with determinant 4/3, and the
-- price of moving it 1 m is the top-left entry of the inverse, 3/2 = 12/T³ at T = 2.
example : (!![8 / 3, 2; 2, 2] : Matrix (Fin 2) (Fin 2) ℚ).det = 4 / 3 := by
  rw [Matrix.det_fin_two_of]; norm_num
example : (!![8 / 3, 2; 2, 2] : Matrix (Fin 2) (Fin 2) ℚ)⁻¹ 0 0 = 3 / 2 ∧ (12 : ℚ) / 2 ^ 3 = 3 / 2 := by
  refine ⟨?_, by norm_num⟩
  rw [Matrix.inv_eq_left_inv (B := !![3 / 2, -3 / 2; -3 / 2, 2])]
  · simp
  · ext i j
    fin_cases i <;> fin_cases j <;> norm_num [Matrix.mul_apply, Fin.sum_univ_succ]

#print axioms controllable_iff_rank_ctrb_eq
#print axioms observable_iff_rank_obsv_eq
#print axioms obsv_eq_ctrb_transpose_transpose
