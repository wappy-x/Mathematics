-- Fundamental theorem of curves: a positive continuous curvature and a continuous torsion, given along a length, belong to a space curve, from any start point and start frame, and any two curves that share them differ only by a rotation followed by a shift.
import Mathlib.LinearAlgebra.CrossProduct
import Mathlib.LinearAlgebra.UnitaryGroup
import Mathlib.Analysis.Calculus.Deriv.Basic
import Mathlib.Topology.ContinuousOn
import Mathlib.Tactic.NormNum
import Mathlib.Tactic.FinCases
import Mathlib.Analysis.ODE.ExistUnique
import Mathlib.Analysis.Calculus.MeanValue
import Mathlib.Analysis.Calculus.Deriv.Prod
import Mathlib.Analysis.Calculus.Deriv.Mul
import Mathlib.Topology.Order.ProjIcc
import Mathlib.LinearAlgebra.Matrix.DotProduct

open Matrix

/-- The card's Frenet-Serret system on the run 0 ≤ s ≤ L, with s the arc length in metres.
The curve r carries the frame of unit tangent T, normal N and binormal B: T and N are
perpendicular unit vectors, B = T × N (one handedness), and per metre

  r' = T,  T' = κ N,  N' = −κ T + τ B,  B' = −τ N.

Rates are taken inside the interval, one-sided at its two ends. Because r' = T is a unit vector,
s is arc length. When κ > 0 this says exactly that r has curvature κ and torsion τ: then
‖r''‖ = κ, the normal is N = r''/κ, the binormal is T × N, and B' = −τ N defines the torsion. -/
def IsFrenetFrame (L : ℝ) (κ τ : ℝ → ℝ) (r T N B : ℝ → Fin 3 → ℝ) : Prop :=
  ∀ s ∈ Set.Icc 0 L,
    T s ⬝ᵥ T s = 1 ∧ N s ⬝ᵥ N s = 1 ∧ T s ⬝ᵥ N s = 0 ∧ B s = T s ⨯₃ N s ∧
    HasDerivWithinAt r (T s) (Set.Icc 0 L) s ∧
    HasDerivWithinAt T (κ s • N s) (Set.Icc 0 L) s ∧
    HasDerivWithinAt N (-(κ s • T s) + τ s • B s) (Set.Icc 0 L) s ∧
    HasDerivWithinAt B (-(τ s • N s)) (Set.Icc 0 L) s

/-- The curve r, travelled at unit speed on 0 ≤ s ≤ L, has curvature κ(s) and torsion τ(s):
it carries a Frenet-Serret frame with those rates. -/
def HasCurvatureTorsion (L : ℝ) (κ τ : ℝ → ℝ) (r : ℝ → Fin 3 → ℝ) : Prop :=
  ∃ T N B : ℝ → Fin 3 → ℝ, IsFrenetFrame L κ τ r T N B

theorem fsc_local_step {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    {f : ℝ → E → E} {K : NNReal}
    (hcont : ∀ x, Continuous fun t => f t x)
    (hlip : ∀ t x y, dist (f t x) (f t y) ≤ K * dist x y)
    (hbd : ∀ t x, ‖f t x‖ ≤ K * ‖x‖) (t₀ : ℝ) (x : E) :
    ∃ α : ℝ → E, α t₀ = x ∧ ∀ t ∈ Set.Icc t₀ (t₀ + 1 / (2 * K + 1)),
      HasDerivWithinAt α (f t (α t)) (Set.Icc t₀ (t₀ + 1 / (2 * K + 1))) t := by
  have hh : (0:ℝ) ≤ 1 / (2 * K + 1) := by positivity
  have hP : IsPicardLindelof f (tmin := t₀) (tmax := t₀ + 1 / (2 * K + 1))
      ⟨t₀, ⟨le_rfl, by linarith⟩⟩ x (‖x‖₊ + 1) 0 (K * (2 * ‖x‖₊ + 1)) K := by
    refine ⟨fun t _ => ?_, fun y _ => (hcont y).continuousOn, fun t _ y hy => ?_, ?_⟩
    · exact (LipschitzWith.of_dist_le_mul (hlip t)).lipschitzOnWith
    · have h1 : dist y x ≤ ((‖x‖₊ + 1 : NNReal) : ℝ) := hy
      rw [dist_eq_norm] at h1
      have h3 := norm_sub_norm_le y x
      have h2 : ‖y‖ ≤ 2 * ‖x‖ + 1 := by push_cast at h1; linarith
      calc ‖f t y‖ ≤ K * ‖y‖ := hbd t y
        _ ≤ K * (2 * ‖x‖ + 1) := by gcongr
        _ = _ := by push_cast; ring
    · push_cast
      have hK : (0:ℝ) ≤ K := K.2
      have hx : (0:ℝ) ≤ ‖x‖ := norm_nonneg x
      rw [max_eq_left (by linarith)]
      simp only [add_sub_cancel_left, sub_zero]
      rw [← mul_div_assoc, mul_one, div_le_iff₀ (by positivity)]
      nlinarith
  exact hP.exists_eq_forall_mem_Icc_hasDerivWithinAt₀

#print axioms fsc_local_step

theorem fsc_glue {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E]
    {f : ℝ → E → E} {a b c : ℝ} {α β : ℝ → E} (hab : a ≤ b) (hbc : b ≤ c)
    (hα : ∀ t ∈ Set.Icc a b, HasDerivWithinAt α (f t (α t)) (Set.Icc a b) t)
    (hβ : ∀ t ∈ Set.Icc b c, HasDerivWithinAt β (f t (β t)) (Set.Icc b c) t)
    (hb : α b = β b) :
    ∀ t ∈ Set.Icc a c, HasDerivWithinAt (fun t => if t ≤ b then α t else β t)
      (f t (if t ≤ b then α t else β t)) (Set.Icc a c) t := by
  set γ : ℝ → E := fun t => if t ≤ b then α t else β t with hγ
  have eα : ∀ t ∈ Set.Icc a b, γ t = α t := fun t ht => by simp [hγ, ht.2]
  have eβ : ∀ t ∈ Set.Icc b c, γ t = β t := fun t ht => by
    rcases eq_or_lt_of_le ht.1 with h | h
    · subst h; simp [hγ, hb]
    · simp [hγ, not_le.2 h]
  have gα : ∀ t ∈ Set.Icc a b, HasDerivWithinAt γ (f t (γ t)) (Set.Icc a b) t := fun t ht => by
    rw [eα t ht]; exact (hα t ht).congr_of_mem eα ht
  have gβ : ∀ t ∈ Set.Icc b c, HasDerivWithinAt γ (f t (γ t)) (Set.Icc b c) t := fun t ht => by
    rw [eβ t ht]; exact (hβ t ht).congr_of_mem eβ ht
  intro t ht
  show HasDerivWithinAt γ (f t (γ t)) (Set.Icc a c) t
  rcases lt_trichotomy t b with h | h | h
  · refine (gα t ⟨ht.1, h.le⟩).mono_of_mem_nhdsWithin ?_
    exact mem_nhdsWithin.2 ⟨Set.Iio b, isOpen_Iio, h, fun y hy => ⟨hy.2.1, le_of_lt hy.1⟩⟩
  · subst h
    rw [← Set.Icc_union_Icc_eq_Icc hab hbc]
    exact (gα t ⟨hab, le_rfl⟩).union (gβ t ⟨le_rfl, hbc⟩)
  · refine (gβ t ⟨h.le, ht.2⟩).mono_of_mem_nhdsWithin ?_
    exact mem_nhdsWithin.2 ⟨Set.Ioi b, isOpen_Ioi, h, fun y hy => ⟨le_of_lt hy.1, hy.2.2⟩⟩

#print axioms fsc_glue

theorem fsc_steps {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    {f : ℝ → E → E} {K : NNReal}
    (hcont : ∀ x, Continuous fun t => f t x)
    (hlip : ∀ t x y, dist (f t x) (f t y) ≤ K * dist x y)
    (hbd : ∀ t x, ‖f t x‖ ≤ K * ‖x‖) (n : ℕ) :
    ∀ (t₀ : ℝ) (x : E), ∃ α : ℝ → E, α t₀ = x ∧
      ∀ t ∈ Set.Icc t₀ (t₀ + (n + 1) * (1 / (2 * K + 1))),
      HasDerivWithinAt α (f t (α t)) (Set.Icc t₀ (t₀ + (n + 1) * (1 / (2 * K + 1)))) t := by
  have hh : (0:ℝ) ≤ 1 / (2 * K + 1) := by positivity
  induction n with
  | zero =>
    intro t₀ x
    simpa using fsc_local_step hcont hlip hbd t₀ x
  | succ n ih =>
    intro t₀ x
    obtain ⟨α, hα0, hα⟩ := fsc_local_step hcont hlip hbd t₀ x
    obtain ⟨β, hβ0, hβ⟩ := ih (t₀ + 1 / (2 * K + 1)) (α (t₀ + 1 / (2 * K + 1)))
    refine ⟨fun t => if t ≤ t₀ + 1 / (2 * K + 1) then α t else β t, by
      beta_reduce; split_ifs with h
      · exact hα0
      · exfalso; linarith, ?_⟩
    have := fsc_glue (f := f) (a := t₀) (b := t₀ + 1 / (2 * K + 1))
      (c := t₀ + 1 / (2 * K + 1) + (n + 1) * (1 / (2 * K + 1)))
      (by linarith) (by nlinarith) hα hβ hβ0.symm
    have e : t₀ + (((n + 1 : ℕ) : ℝ) + 1) * (1 / (2 * K + 1)) =
        t₀ + 1 / (2 * K + 1) + (n + 1) * (1 / (2 * K + 1)) := by push_cast; ring
    rw [e]; exact this

#print axioms fsc_steps

theorem fsc_exists {E : Type*} [NormedAddCommGroup E] [NormedSpace ℝ E] [CompleteSpace E]
    {f : ℝ → E → E} {K : NNReal}
    (hcont : ∀ x, Continuous fun t => f t x)
    (hlip : ∀ t x y, dist (f t x) (f t y) ≤ K * dist x y)
    (hbd : ∀ t x, ‖f t x‖ ≤ K * ‖x‖) (L : ℝ) (x : E) :
    ∃ α : ℝ → E, α 0 = x ∧ ∀ t ∈ Set.Icc 0 L,
      HasDerivWithinAt α (f t (α t)) (Set.Icc 0 L) t := by
  have hh : (0:ℝ) < 1 / (2 * K + 1) := by positivity
  obtain ⟨n, hn⟩ := exists_nat_gt (L / (1 / (2 * K + 1)))
  obtain ⟨α, hα0, hα⟩ := fsc_steps hcont hlip hbd n 0 x
  have hsub : Set.Icc 0 L ⊆ Set.Icc (0:ℝ) (0 + (n + 1) * (1 / (2 * K + 1))) := by
    apply Set.Icc_subset_Icc le_rfl
    rw [div_lt_iff₀ hh] at hn
    nlinarith
  exact ⟨α, hα0, fun t ht => (hα t (hsub ht)).mono hsub⟩

#print axioms fsc_exists

theorem fsc_hd_dot {u v : ℝ → Fin 3 → ℝ} {u' v' : Fin 3 → ℝ} {s : Set ℝ} {x : ℝ}
    (hu : HasDerivWithinAt u u' s x) (hv : HasDerivWithinAt v v' s x) :
    HasDerivWithinAt (fun t => u t ⬝ᵥ v t) (u' ⬝ᵥ v x + u x ⬝ᵥ v') s x := by
  have a := hasDerivWithinAt_pi.1 hu
  have b := hasDerivWithinAt_pi.1 hv
  have h := (((a 0).mul (b 0)).add ((a 1).mul (b 1))).add ((a 2).mul (b 2))
  convert h using 1
  · funext t; simp [dotProduct, Fin.sum_univ_three]
  · simp [dotProduct, Fin.sum_univ_three]; ring

#print axioms fsc_hd_dot

theorem fsc_hd_triple {u v w : ℝ → Fin 3 → ℝ} {u' v' w' : Fin 3 → ℝ} {s : Set ℝ} {x : ℝ}
    (hu : HasDerivWithinAt u u' s x) (hv : HasDerivWithinAt v v' s x)
    (hw : HasDerivWithinAt w w' s x) :
    HasDerivWithinAt (fun t => u t ⬝ᵥ (v t ⨯₃ w t))
      (u' ⬝ᵥ (v x ⨯₃ w x) + u x ⬝ᵥ (v' ⨯₃ w x) + u x ⬝ᵥ (v x ⨯₃ w')) s x := by
  have a := hasDerivWithinAt_pi.1 hu
  have b := hasDerivWithinAt_pi.1 hv
  have c := hasDerivWithinAt_pi.1 hw
  have h := (((a 0).mul (((b 1).mul (c 2)).sub ((b 2).mul (c 1)))).add
    ((a 1).mul (((b 2).mul (c 0)).sub ((b 0).mul (c 2))))).add
    ((a 2).mul (((b 0).mul (c 1)).sub ((b 1).mul (c 0))))
  convert h using 1
  · funext t; simp [dotProduct, Fin.sum_univ_three, cross_apply]
  · simp [dotProduct, Fin.sum_univ_three, cross_apply]; ring

#print axioms fsc_hd_triple

theorem fsc_hd_mulVec (M : Matrix (Fin 3) (Fin 3) ℝ) {u : ℝ → Fin 3 → ℝ} {u' : Fin 3 → ℝ}
    {s : Set ℝ} {x : ℝ} (hu : HasDerivWithinAt u u' s x) :
    HasDerivWithinAt (fun t => M *ᵥ u t) (M *ᵥ u') s x := by
  have := (LinearMap.toContinuousLinearMap (Matrix.mulVecLin M)).hasFDerivAt.comp_hasDerivWithinAt
    x hu
  exact this

#print axioms fsc_hd_mulVec

theorem fsc_gram_deriv {T N B : ℝ → Fin 3 → ℝ} {k τ : ℝ} {s : Set ℝ} {x : ℝ}
    (hT : HasDerivWithinAt T (k • N x) s x)
    (hN : HasDerivWithinAt N (-(k • T x) + τ • B x) s x)
    (hB : HasDerivWithinAt B (-(τ • N x)) s x) :
    HasDerivWithinAt (fun t => (T t ⬝ᵥ T t - 1) * (T t ⬝ᵥ T t - 1)
      + (N t ⬝ᵥ N t - 1) * (N t ⬝ᵥ N t - 1) + (B t ⬝ᵥ B t - 1) * (B t ⬝ᵥ B t - 1)
      + 2 * ((T t ⬝ᵥ N t) * (T t ⬝ᵥ N t)) + 2 * ((T t ⬝ᵥ B t) * (T t ⬝ᵥ B t))
      + 2 * ((N t ⬝ᵥ B t) * (N t ⬝ᵥ B t))) 0 s x := by
  have tt := (fsc_hd_dot hT hT).sub_const 1
  have nn := (fsc_hd_dot hN hN).sub_const 1
  have bb := (fsc_hd_dot hB hB).sub_const 1
  have tn := fsc_hd_dot hT hN
  have tb := fsc_hd_dot hT hB
  have nb := fsc_hd_dot hN hB
  have h := (((((tt.mul tt).add (nn.mul nn)).add (bb.mul bb)).add ((tn.mul tn).const_mul 2)).add
    ((tb.mul tb).const_mul 2)).add ((nb.mul nb).const_mul 2)
  convert h using 1
  simp [dotProduct, Fin.sum_univ_three]; ring

#print axioms fsc_gram_deriv

theorem fsc_triple_deriv {T N B : ℝ → Fin 3 → ℝ} {k τ : ℝ} {s : Set ℝ} {x : ℝ}
    (hT : HasDerivWithinAt T (k • N x) s x)
    (hN : HasDerivWithinAt N (-(k • T x) + τ • B x) s x)
    (hB : HasDerivWithinAt B (-(τ • N x)) s x) :
    HasDerivWithinAt (fun t => B t ⬝ᵥ (T t ⨯₃ N t)) 0 s x := by
  convert fsc_hd_triple hB hT hN using 1
  simp [dotProduct, Fin.sum_univ_three, cross_apply]; ring

#print axioms fsc_triple_deriv

theorem fsc_energy_deriv {T N B T₂ N₂ B₂ : ℝ → Fin 3 → ℝ} {k τ : ℝ} {s : Set ℝ} {x : ℝ}
    (hT : HasDerivWithinAt T (k • N x) s x)
    (hN : HasDerivWithinAt N (-(k • T x) + τ • B x) s x)
    (hB : HasDerivWithinAt B (-(τ • N x)) s x)
    (hT₂ : HasDerivWithinAt T₂ (k • N₂ x) s x)
    (hN₂ : HasDerivWithinAt N₂ (-(k • T₂ x) + τ • B₂ x) s x)
    (hB₂ : HasDerivWithinAt B₂ (-(τ • N₂ x)) s x) :
    HasDerivWithinAt (fun t => T t ⬝ᵥ T₂ t + N t ⬝ᵥ N₂ t + B t ⬝ᵥ B₂ t) 0 s x := by
  convert ((fsc_hd_dot hT hT₂).add (fsc_hd_dot hN hN₂)).add (fsc_hd_dot hB hB₂) using 1
  simp [dotProduct, Fin.sum_univ_three]; ring

#print axioms fsc_energy_deriv

theorem fsc_const {F : Type*} [NormedAddCommGroup F] [NormedSpace ℝ F] {g : ℝ → F} {L : ℝ}
    (h : ∀ s ∈ Set.Icc 0 L, HasDerivWithinAt g 0 (Set.Icc 0 L) s) :
    ∀ s ∈ Set.Icc 0 L, g s = g 0 :=
  constant_of_has_deriv_right_zero (fun s hs => (h s hs).continuousWithinAt)
    (fun s hs => (h s (Set.Ico_subset_Icc_self hs)).mono_of_mem_nhdsWithin
      (Icc_mem_nhdsGE_of_mem hs))

#print axioms fsc_const

theorem fsc_orth_dot {M : Matrix (Fin 3) (Fin 3) ℝ} (hM : Mᵀ * M = 1) (v w : Fin 3 → ℝ) :
    (M *ᵥ v) ⬝ᵥ (M *ᵥ w) = v ⬝ᵥ w := by
  rw [dotProduct_comm, dotProduct_mulVec, ← mulVec_transpose, mulVec_mulVec, hM, one_mulVec,
    dotProduct_comm]

#print axioms fsc_orth_dot

theorem fsc_cross_mulVec (M : Matrix (Fin 3) (Fin 3) ℝ) (u v : Fin 3 → ℝ) :
    Mᵀ *ᵥ ((M *ᵥ u) ⨯₃ (M *ᵥ v)) = M.det • (u ⨯₃ v) := by
  ext i
  fin_cases i <;>
  · simp [cross_apply, mulVec, dotProduct, Fin.sum_univ_three, det_fin_three]; ring

#print axioms fsc_cross_mulVec

theorem fsc_sq_nonneg (v : Fin 3 → ℝ) : 0 ≤ v ⬝ᵥ v := by
  simp only [dotProduct, Fin.sum_univ_three]
  exact add_nonneg (add_nonneg (mul_self_nonneg _) (mul_self_nonneg _)) (mul_self_nonneg _)

#print axioms fsc_sq_nonneg

theorem fsc_frame_mat {T N B : Fin 3 → ℝ} (h1 : T ⬝ᵥ T = 1) (h2 : N ⬝ᵥ N = 1) (h3 : T ⬝ᵥ N = 0)
    (hB : B = T ⨯₃ N) :
    Matrix.of ![T, N, B] * (Matrix.of ![T, N, B])ᵀ = 1 ∧
      (Matrix.of ![T, N, B]).det = 1 := by
  subst hB
  have h3' : N ⬝ᵥ T = 0 := by rw [dotProduct_comm]; exact h3
  have hBB : (T ⨯₃ N) ⬝ᵥ (T ⨯₃ N) = 1 := by rw [cross_dot_cross, h1, h2, h3, h3']; ring
  have hTB : T ⬝ᵥ (T ⨯₃ N) = 0 := dot_self_cross T N
  have hNB : N ⬝ᵥ (T ⨯₃ N) = 0 := dot_cross_self T N
  have hBT : (T ⨯₃ N) ⬝ᵥ T = 0 := by rw [dotProduct_comm]; exact hTB
  have hBN : (T ⨯₃ N) ⬝ᵥ N = 0 := by rw [dotProduct_comm]; exact hNB
  constructor
  · ext i j
    have e : (Matrix.of ![T, N, T ⨯₃ N] * (Matrix.of ![T, N, T ⨯₃ N])ᵀ) i j =
        ![T, N, T ⨯₃ N] i ⬝ᵥ ![T, N, T ⨯₃ N] j := rfl
    rw [e]
    fin_cases i <;> fin_cases j <;> simp [h1, h2, h3, h3', hBB, hTB, hNB, hBT, hBN]
  · show Matrix.det ![T, N, T ⨯₃ N] = 1
    rw [← triple_product_eq_det, triple_product_permutation, triple_product_permutation, hBB]

#print axioms fsc_frame_mat

theorem fsc_rowmap {P Q : Matrix (Fin 3) (Fin 3) ℝ} (hP : P * Pᵀ = 1) (i : Fin 3) :
    (Qᵀ * P) *ᵥ P i = Q i := by
  have e : ∀ R : Matrix (Fin 3) (Fin 3) ℝ, R i = Rᵀ *ᵥ Pi.single i 1 := fun R => by
    rw [mulVec_transpose, single_one_vecMul]; rfl
  rw [e P, e Q, mulVec_mulVec, Matrix.mul_assoc, hP, Matrix.mul_one]

#print axioms fsc_rowmap

theorem fsc_rebuild {L : ℝ} {κ τ : ℝ → ℝ}
    (hκ : ContinuousOn κ (Set.Icc 0 L)) (hτ : ContinuousOn τ (Set.Icc 0 L))
    (r₀ T₀ N₀ : Fin 3 → ℝ) (hT₀ : T₀ ⬝ᵥ T₀ = 1) (hN₀ : N₀ ⬝ᵥ N₀ = 1) (hTN₀ : T₀ ⬝ᵥ N₀ = 0) :
    ∃ r T N B : ℝ → Fin 3 → ℝ, IsFrenetFrame L κ τ r T N B ∧
      r 0 = r₀ ∧ T 0 = T₀ ∧ N 0 = N₀ := by
  by_cases hL : 0 ≤ L
  swap
  · refine ⟨fun _ => r₀, fun _ => T₀, fun _ => N₀, fun _ => T₀ ⨯₃ N₀, ?_, rfl, rfl, rfl⟩
    intro s hs; exact absurd (hs.1.trans hs.2) hL
  set k : ℝ → ℝ := fun t => κ (Set.projIcc 0 L hL t) with hk
  set w : ℝ → ℝ := fun t => τ (Set.projIcc 0 L hL t) with hw
  have kc : Continuous k := hκ.comp_continuous
    (continuous_subtype_val.comp continuous_projIcc) (fun t => (Set.projIcc 0 L hL t).2)
  have wc : Continuous w := hτ.comp_continuous
    (continuous_subtype_val.comp continuous_projIcc) (fun t => (Set.projIcc 0 L hL t).2)
  have kI : ∀ t ∈ Set.Icc 0 L, k t = κ t := fun t ht => by simp [hk, Set.projIcc_of_mem hL ht]
  have wI : ∀ t ∈ Set.Icc 0 L, w t = τ t := fun t ht => by simp [hw, Set.projIcc_of_mem hL ht]
  obtain ⟨Ck, hCk⟩ := (isCompact_Icc (a := (0:ℝ)) (b := L)).exists_bound_of_continuousOn hκ
  obtain ⟨Cw, hCw⟩ := (isCompact_Icc (a := (0:ℝ)) (b := L)).exists_bound_of_continuousOn hτ
  have kb : ∀ t, |k t| ≤ |Ck| := fun t =>
    ((Real.norm_eq_abs _).symm.le.trans (hCk _ (Set.projIcc 0 L hL t).2)).trans (le_abs_self _)
  have wb : ∀ t, |w t| ≤ |Cw| := fun t =>
    ((Real.norm_eq_abs _).symm.le.trans (hCw _ (Set.projIcc 0 L hL t).2)).trans (le_abs_self _)
  set K : NNReal := ⟨|Ck| + |Cw| + 1, by positivity⟩ with hK
  have hKr : (K : ℝ) = |Ck| + |Cw| + 1 := rfl
  set f : ℝ → (Fin 4 → Fin 3 → ℝ) → (Fin 4 → Fin 3 → ℝ) := fun t x =>
    ![x 1, k t • x 2, -(k t • x 1) + w t • x 3, -(w t • x 2)] with hf
  have flin : ∀ t x y, f t x - f t y = f t (x - y) := by
    intro t x y; ext i j; fin_cases i <;> simp [hf] <;> ring
  have fbd : ∀ t x, ‖f t x‖ ≤ K * ‖x‖ := by
    intro t x
    rw [hKr]
    have hx := norm_nonneg x
    have a0 := abs_nonneg Ck
    have a1 := abs_nonneg Cw
    have n1 := norm_le_pi_norm x 1
    have n2 := norm_le_pi_norm x 2
    have n3 := norm_le_pi_norm x 3
    have p1 : |k t| * ‖x 1‖ ≤ |Ck| * ‖x‖ :=
      mul_le_mul (kb t) n1 (norm_nonneg _) (abs_nonneg _)
    have p2 : |k t| * ‖x 2‖ ≤ |Ck| * ‖x‖ :=
      mul_le_mul (kb t) n2 (norm_nonneg _) (abs_nonneg _)
    have q2 : |w t| * ‖x 2‖ ≤ |Cw| * ‖x‖ :=
      mul_le_mul (wb t) n2 (norm_nonneg _) (abs_nonneg _)
    have q3 : |w t| * ‖x 3‖ ≤ |Cw| * ‖x‖ :=
      mul_le_mul (wb t) n3 (norm_nonneg _) (abs_nonneg _)
    refine (pi_norm_le_iff_of_nonneg (by positivity)).2 fun i => ?_
    fin_cases i
    · show ‖x 1‖ ≤ _; nlinarith
    · show ‖k t • x 2‖ ≤ _
      rw [norm_smul, Real.norm_eq_abs]; nlinarith
    · show ‖-(k t • x 1) + w t • x 3‖ ≤ _
      refine (norm_add_le _ _).trans ?_
      rw [norm_neg, norm_smul, norm_smul, Real.norm_eq_abs, Real.norm_eq_abs]; nlinarith
    · show ‖-(w t • x 2)‖ ≤ _
      rw [norm_neg, norm_smul, Real.norm_eq_abs]; nlinarith
  have fcont : ∀ x, Continuous fun t => f t x := by
    intro x
    refine continuous_pi fun i => ?_
    fin_cases i
    · exact continuous_const
    · exact kc.smul continuous_const
    · exact (kc.smul continuous_const).neg.add (wc.smul continuous_const)
    · exact (wc.smul continuous_const).neg
  have flip : ∀ t x y, dist (f t x) (f t y) ≤ K * dist x y := fun t x y => by
    rw [dist_eq_norm, dist_eq_norm, flin]; exact fbd t _
  obtain ⟨α, hα0, hα⟩ := fsc_exists fcont flip fbd L ![r₀, T₀, N₀, T₀ ⨯₃ N₀]
  set r : ℝ → Fin 3 → ℝ := fun t => α t 0 with hr
  set T : ℝ → Fin 3 → ℝ := fun t => α t 1 with hT
  set N : ℝ → Fin 3 → ℝ := fun t => α t 2 with hN
  set B : ℝ → Fin 3 → ℝ := fun t => α t 3 with hB
  have r0 : r 0 = r₀ := by simp [hr, hα0]
  have T0 : T 0 = T₀ := by simp [hT, hα0]
  have N0 : N 0 = N₀ := by simp [hN, hα0]
  have B0 : B 0 = T₀ ⨯₃ N₀ := by simp [hB, hα0]
  have hd : ∀ t ∈ Set.Icc 0 L,
      HasDerivWithinAt r (T t) (Set.Icc 0 L) t ∧
      HasDerivWithinAt T (κ t • N t) (Set.Icc 0 L) t ∧
      HasDerivWithinAt N (-(κ t • T t) + τ t • B t) (Set.Icc 0 L) t ∧
      HasDerivWithinAt B (-(τ t • N t)) (Set.Icc 0 L) t := by
    intro t ht
    have h := hasDerivWithinAt_pi.1 (hα t ht)
    refine ⟨?_, ?_, ?_, ?_⟩
    · exact h 0
    · exact (h 1).congr_deriv (show k t • α t 2 = κ t • α t 2 by rw [kI t ht])
    · exact (h 2).congr_deriv (show -(k t • α t 1) + w t • α t 3 = -(κ t • α t 1) + τ t • α t 3 by
        rw [kI t ht, wI t ht])
    · exact (h 3).congr_deriv (show -(w t • α t 2) = -(τ t • α t 2) by rw [wI t ht])
  have I0 : (0:ℝ) ∈ Set.Icc 0 L := ⟨le_rfl, hL⟩
  have hG := fsc_const (fun s hs => fsc_gram_deriv (hd s hs).2.1 (hd s hs).2.2.1 (hd s hs).2.2.2)
  have hP := fsc_const (fun s hs => fsc_triple_deriv (hd s hs).2.1 (hd s hs).2.2.1 (hd s hs).2.2.2)
  have hNT₀ : N₀ ⬝ᵥ T₀ = 0 := by rw [dotProduct_comm]; exact hTN₀
  have hBB₀ : (T₀ ⨯₃ N₀) ⬝ᵥ (T₀ ⨯₃ N₀) = 1 := by
    rw [cross_dot_cross, hT₀, hN₀, hTN₀, hNT₀]; ring
  refine ⟨r, T, N, B, ?_, r0, T0, N0⟩
  intro s hs
  have G := hG s hs
  have P := hP s hs
  simp only [T0, N0, B0, hT₀, hN₀, hTN₀, hBB₀, dot_self_cross, dot_cross_self] at G P
  have g1 := mul_self_nonneg (T s ⬝ᵥ T s - 1)
  have g2 := mul_self_nonneg (N s ⬝ᵥ N s - 1)
  have g3 := mul_self_nonneg (B s ⬝ᵥ B s - 1)
  have g4 := mul_self_nonneg (T s ⬝ᵥ N s)
  have g5 := mul_self_nonneg (T s ⬝ᵥ B s)
  have g6 := mul_self_nonneg (N s ⬝ᵥ B s)
  have e1 : (T s ⬝ᵥ T s - 1) * (T s ⬝ᵥ T s - 1) = 0 := by norm_num at G; linarith
  have e2 : (N s ⬝ᵥ N s - 1) * (N s ⬝ᵥ N s - 1) = 0 := by norm_num at G; linarith
  have e3 : (B s ⬝ᵥ B s - 1) * (B s ⬝ᵥ B s - 1) = 0 := by norm_num at G; linarith
  have e4 : (T s ⬝ᵥ N s) * (T s ⬝ᵥ N s) = 0 := by norm_num at G; linarith
  have hTT : T s ⬝ᵥ T s = 1 := sub_eq_zero.1 (mul_self_eq_zero.1 e1)
  have hNN : N s ⬝ᵥ N s = 1 := sub_eq_zero.1 (mul_self_eq_zero.1 e2)
  have hBB : B s ⬝ᵥ B s = 1 := sub_eq_zero.1 (mul_self_eq_zero.1 e3)
  have hTN : T s ⬝ᵥ N s = 0 := mul_self_eq_zero.1 e4
  have hNT : N s ⬝ᵥ T s = 0 := by rw [dotProduct_comm]; exact hTN
  have hBeq : B s = T s ⨯₃ N s := by
    have : (B s - T s ⨯₃ N s) ⬝ᵥ (B s - T s ⨯₃ N s) = 0 := by
      rw [sub_dotProduct, dotProduct_sub, dotProduct_sub, cross_dot_cross,
        dotProduct_comm (T s ⨯₃ N s) (B s), hBB, hTT, hNN, hTN, hNT]
      have P' : B s ⬝ᵥ T s ⨯₃ N s = 1 := P
      rw [P']; ring
    exact sub_eq_zero.1 (dotProduct_self_eq_zero.1 this)
  exact ⟨hTT, hNN, hTN, hBeq, hd s hs⟩

#print axioms fsc_rebuild

/-- **Bending and twisting fix the shape.** Give a curvature κ(s) > 0 and a torsion τ(s) along
the length 0 ≤ s ≤ L, both continuous. Then some unit-speed space curve has exactly that
curvature and torsion, and any two such curves differ by a rigid motion: a rotation M
(a 3 × 3 orthogonal matrix of determinant +1, so no mirror) followed by a shift p. -/
theorem curvature_and_torsion_fix_the_curve {L : ℝ} {κ τ : ℝ → ℝ}
    (hκ : ContinuousOn κ (Set.Icc 0 L)) (hτ : ContinuousOn τ (Set.Icc 0 L))
    (hpos : ∀ s ∈ Set.Icc 0 L, 0 < κ s) :
    (∃ r : ℝ → Fin 3 → ℝ, HasCurvatureTorsion L κ τ r) ∧
    ∀ r₁ r₂ : ℝ → Fin 3 → ℝ, HasCurvatureTorsion L κ τ r₁ → HasCurvatureTorsion L κ τ r₂ →
      ∃ M ∈ specialOrthogonalGroup (Fin 3) ℝ, ∃ p : Fin 3 → ℝ,
        ∀ s ∈ Set.Icc 0 L, r₂ s = M *ᵥ r₁ s + p := by
  refine ⟨?_, ?_⟩
  · obtain ⟨r, T, N, B, h, -⟩ := fsc_rebuild hκ hτ 0 ![1, 0, 0] ![0, 1, 0]
      (by simp [dotProduct, Fin.sum_univ_three]) (by simp [dotProduct, Fin.sum_univ_three])
      (by simp [dotProduct, Fin.sum_univ_three])
    exact ⟨r, T, N, B, h⟩
  · rintro r₁ r₂ ⟨T₁, N₁, B₁, h1⟩ ⟨T₂, N₂, B₂, h2⟩
    by_cases hL : 0 ≤ L
    swap
    · exact ⟨1, one_mem _, 0, fun s hs => absurd (hs.1.trans hs.2) hL⟩
    have I0 : (0:ℝ) ∈ Set.Icc 0 L := ⟨le_rfl, hL⟩
    obtain ⟨a1, b1, c1, d1, -⟩ := h1 0 I0
    obtain ⟨a2, b2, c2, d2, -⟩ := h2 0 I0
    obtain ⟨hP1, hdet1⟩ := fsc_frame_mat a1 b1 c1 d1
    obtain ⟨hP2, hdet2⟩ := fsc_frame_mat a2 b2 c2 d2
    set P₁ := Matrix.of ![T₁ 0, N₁ 0, B₁ 0] with hP₁
    set P₂ := Matrix.of ![T₂ 0, N₂ 0, B₂ 0] with hP₂
    have hP1' : P₁ᵀ * P₁ = 1 := mul_eq_one_comm.1 hP1
    set M := P₂ᵀ * P₁ with hM
    have hMM : Mᵀ * M = 1 := by
      rw [hM, transpose_mul, transpose_transpose]
      calc P₁ᵀ * P₂ * (P₂ᵀ * P₁) = P₁ᵀ * (P₂ * P₂ᵀ) * P₁ := by simp only [Matrix.mul_assoc]
        _ = 1 := by rw [hP2, Matrix.mul_one, hP1']
    have hMdet : M.det = 1 := by rw [hM, det_mul, det_transpose, hdet1, hdet2, one_mul]
    have MT0 : M *ᵥ T₁ 0 = T₂ 0 := fsc_rowmap hP1 0
    have MN0 : M *ᵥ N₁ 0 = N₂ 0 := fsc_rowmap hP1 1
    have MB0 : M *ᵥ B₁ 0 = B₂ 0 := fsc_rowmap hP1 2
    have hU : ∀ s ∈ Set.Icc 0 L, HasDerivWithinAt (fun t => M *ᵥ T₁ t)
        (κ s • (M *ᵥ N₁ s)) (Set.Icc 0 L) s := fun s hs => by
      have := fsc_hd_mulVec M (h1 s hs).2.2.2.2.2.1
      rwa [mulVec_smul] at this
    have hV : ∀ s ∈ Set.Icc 0 L, HasDerivWithinAt (fun t => M *ᵥ N₁ t)
        (-(κ s • (M *ᵥ T₁ s)) + τ s • (M *ᵥ B₁ s)) (Set.Icc 0 L) s := fun s hs => by
      have := fsc_hd_mulVec M (h1 s hs).2.2.2.2.2.2.1
      rwa [mulVec_add, mulVec_neg, mulVec_smul, mulVec_smul] at this
    have hW : ∀ s ∈ Set.Icc 0 L, HasDerivWithinAt (fun t => M *ᵥ B₁ t)
        (-(τ s • (M *ᵥ N₁ s))) (Set.Icc 0 L) s := fun s hs => by
      have := fsc_hd_mulVec M (h1 s hs).2.2.2.2.2.2.2
      rwa [mulVec_neg, mulVec_smul] at this
    have hE := fsc_const (fun s hs => fsc_energy_deriv (T := fun t => M *ᵥ T₁ t)
      (N := fun t => M *ᵥ N₁ t) (B := fun t => M *ᵥ B₁ t) (hU s hs) (hV s hs) (hW s hs)
      (h2 s hs).2.2.2.2.2.1 (h2 s hs).2.2.2.2.2.2.1 (h2 s hs).2.2.2.2.2.2.2)
    have hBB : ∀ {T N B : Fin 3 → ℝ}, T ⬝ᵥ T = 1 → N ⬝ᵥ N = 1 → T ⬝ᵥ N = 0 → B = T ⨯₃ N →
        B ⬝ᵥ B = 1 := by
      intro T N B ha hb hc hd
      rw [hd, cross_dot_cross, ha, hb, hc, dotProduct_comm N T, hc]; ring
    have bb20 := hBB a2 b2 c2 d2
    have hTeq : ∀ s ∈ Set.Icc 0 L, M *ᵥ T₁ s = T₂ s := by
      intro s hs
      have E := hE s hs
      simp only [MT0, MN0, MB0, a2, b2, bb20] at E
      obtain ⟨a1s, b1s, c1s, d1s, -⟩ := h1 s hs
      obtain ⟨a2s, b2s, c2s, d2s, -⟩ := h2 s hs
      have bb1 := hBB a1s b1s c1s d1s
      have bb2 := hBB a2s b2s c2s d2s
      have u1 : (M *ᵥ T₁ s) ⬝ᵥ (M *ᵥ T₁ s) = 1 := by rw [fsc_orth_dot hMM, a1s]
      have u2 : (M *ᵥ N₁ s) ⬝ᵥ (M *ᵥ N₁ s) = 1 := by rw [fsc_orth_dot hMM, b1s]
      have u3 : (M *ᵥ B₁ s) ⬝ᵥ (M *ᵥ B₁ s) = 1 := by rw [fsc_orth_dot hMM, bb1]
      have k1 := dotProduct_comm (T₂ s) (M *ᵥ T₁ s)
      have k2 := dotProduct_comm (N₂ s) (M *ᵥ N₁ s)
      have k3 := dotProduct_comm (B₂ s) (M *ᵥ B₁ s)
      have n1 := fsc_sq_nonneg (M *ᵥ T₁ s - T₂ s)
      have n2 := fsc_sq_nonneg (M *ᵥ N₁ s - N₂ s)
      have n3 := fsc_sq_nonneg (M *ᵥ B₁ s - B₂ s)
      simp only [sub_dotProduct, dotProduct_sub] at n1 n2 n3
      have z : (M *ᵥ T₁ s - T₂ s) ⬝ᵥ (M *ᵥ T₁ s - T₂ s) = 0 := by
        simp only [sub_dotProduct, dotProduct_sub]; linarith
      exact sub_eq_zero.1 (dotProduct_self_eq_zero.1 z)
    refine ⟨M, mem_specialOrthogonalGroup_iff.2 ⟨(mem_orthogonalGroup_iff' (Fin 3) ℝ).2 hMM, hMdet⟩,
      r₂ 0 - M *ᵥ r₁ 0, ?_⟩
    intro s hs
    have hg : ∀ t ∈ Set.Icc 0 L,
        HasDerivWithinAt (fun t => r₂ t - M *ᵥ r₁ t) 0 (Set.Icc 0 L) t := by
      intro t ht
      have := (h2 t ht).2.2.2.2.1.sub (fsc_hd_mulVec M (h1 t ht).2.2.2.2.1)
      rwa [hTeq t ht, sub_self] at this
    have := fsc_const hg s hs
    exact sub_eq_iff_eq_add'.1 this

/-- **The start only decides where the shape sits.** With the same curvature and torsion,
choose any start point r₀ and any start frame: perpendicular unit vectors T₀ (the heading)
and N₀ (the way the run turns), with B₀ = T₀ × N₀. Then the Frenet-Serret equations rebuild a
curve that starts at r₀ with exactly that frame. -/
theorem curve_rebuilt_from_any_start {L : ℝ} {κ τ : ℝ → ℝ}
    (hκ : ContinuousOn κ (Set.Icc 0 L)) (hτ : ContinuousOn τ (Set.Icc 0 L))
    (hpos : ∀ s ∈ Set.Icc 0 L, 0 < κ s)
    (r₀ T₀ N₀ : Fin 3 → ℝ) (hT₀ : T₀ ⬝ᵥ T₀ = 1) (hN₀ : N₀ ⬝ᵥ N₀ = 1) (hTN₀ : T₀ ⬝ᵥ N₀ = 0) :
    ∃ r T N B : ℝ → Fin 3 → ℝ, IsFrenetFrame L κ τ r T N B ∧
      r 0 = r₀ ∧ T 0 = T₀ ∧ N 0 = N₀ := by
  exact fsc_rebuild hκ hτ r₀ T₀ N₀ hT₀ hN₀ hTN₀

/-- **A mirror flips the twist.** A mirror M (an orthogonal 3 × 3 matrix of determinant −1)
keeps lengths and angles, so the mirrored curve s ↦ M r(s) keeps the curvature κ, but it turns
a right-handed frame into a left-handed one, so its torsion is −τ. -/
theorem mirror_flips_torsion {L : ℝ} {κ τ : ℝ → ℝ} {r : ℝ → Fin 3 → ℝ}
    {M : Matrix (Fin 3) (Fin 3) ℝ} (hM : M ∈ orthogonalGroup (Fin 3) ℝ) (hdet : M.det = -1)
    (hr : HasCurvatureTorsion L κ τ r) :
    HasCurvatureTorsion L κ (-τ) (fun s => M *ᵥ r s) := by
  obtain ⟨T, N, B, h⟩ := hr
  have hMM : M * Mᵀ = 1 := (mem_orthogonalGroup_iff (Fin 3) ℝ).1 hM
  have hMM' : Mᵀ * M = 1 := (mem_orthogonalGroup_iff' (Fin 3) ℝ).1 hM
  have cross : ∀ u v : Fin 3 → ℝ, (M *ᵥ u) ⨯₃ (M *ᵥ v) = -(M *ᵥ (u ⨯₃ v)) := fun u v => by
    have e := fsc_cross_mulVec M u v
    have : M *ᵥ (Mᵀ *ᵥ ((M *ᵥ u) ⨯₃ (M *ᵥ v))) = (M *ᵥ u) ⨯₃ (M *ᵥ v) := by
      rw [mulVec_mulVec, hMM, one_mulVec]
    rw [← this, e, hdet, mulVec_smul, neg_one_smul]
  refine ⟨fun t => M *ᵥ T t, fun t => M *ᵥ N t, fun t => -(M *ᵥ B t), fun s hs => ?_⟩
  obtain ⟨a, b, c, d, hr', hT, hN, hB⟩ := h s hs
  refine ⟨?_, ?_, ?_, ?_, fsc_hd_mulVec M hr', ?_, ?_, ?_⟩
  · show (M *ᵥ T s) ⬝ᵥ (M *ᵥ T s) = 1
    rw [fsc_orth_dot hMM', a]
  · show (M *ᵥ N s) ⬝ᵥ (M *ᵥ N s) = 1
    rw [fsc_orth_dot hMM', b]
  · show (M *ᵥ T s) ⬝ᵥ (M *ᵥ N s) = 0
    rw [fsc_orth_dot hMM', c]
  · show -(M *ᵥ B s) = (M *ᵥ T s) ⨯₃ (M *ᵥ N s)
    rw [d, cross]
  · have := fsc_hd_mulVec M hT
    rwa [mulVec_smul] at this
  · have := fsc_hd_mulVec M hN
    rw [mulVec_add, mulVec_neg, mulVec_smul, mulVec_smul] at this
    convert this using 1
    simp
  · have := (fsc_hd_mulVec M hB).neg
    rw [mulVec_neg, mulVec_smul] at this
    convert this using 1
    simp

-- The ski run's log: bend κ = 0.012 = 12/1000 per metre, twist τ = 0.0024 = 24/10000 per metre.
-- κ^2 + τ^2 = 0.00014976 = 14976/10^8 per square metre.
example : ((12 : ℚ) / 1000) ^ 2 + (24 / 10000) ^ 2 = 14976 / 10 ^ 8 := by norm_num
-- The grade is twist over bend: 0.0024 / 0.012 = 0.200 = 1/5, a 20% grade.
example : ((24 : ℚ) / 10000) / (12 / 1000) = 1 / 5 := by norm_num
-- Running the helix formulas backwards and forwards: with a = κ/(κ^2+τ^2) and
-- c = τ/(κ^2+τ^2), the helix of radius a and drop c per radian has κ = a/(a^2+c^2)
-- and τ = c/(a^2+c^2) again.
example :
    let κ : ℚ := 12 / 1000
    let τ : ℚ := 24 / 10000
    let a := κ / (κ ^ 2 + τ ^ 2)
    let c := τ / (κ ^ 2 + τ ^ 2)
    a / (a ^ 2 + c ^ 2) = κ ∧ c / (a ^ 2 + c ^ 2) = τ := by
  norm_num
-- The plan radius: the turn radius 1/κ = 83.33 m times cos^2 of the grade angle,
-- 1/(1 + 0.200^2), equals the helix radius a = κ/(κ^2+τ^2) = 80.128 m.
example : (1 / ((12 : ℚ) / 1000)) / (1 + (1 / 5) ^ 2) =
    (12 / 1000) / (((12 : ℚ) / 1000) ^ 2 + (24 / 10000) ^ 2) := by norm_num
-- The start frame, scaled to whole numbers: T along (5, 0, −1) (east, 20% down) and
-- N = (0, −1, 0) (south) are perpendicular, and B = T × N lies along (−1, 0, −5),
-- the card's (−0.20, 0.00, −0.98).
example : ![(5 : ℤ), 0, -1] ⬝ᵥ ![0, -1, 0] = 0 := by decide
example : ![(5 : ℤ), 0, -1] ⨯₃ ![0, -1, 0] = ![-1, 0, -5] := by
  rw [cross_apply]; ext i; fin_cases i <;> rfl

#print axioms curvature_and_torsion_fix_the_curve
#print axioms curve_rebuilt_from_any_start
#print axioms mirror_flips_torsion
