-- Homotopy: the lawn (a closed disc) is homotopy equivalent to a point and the ground round the post (the disc with a smaller open disc removed) is homotopy equivalent to a ring, neither pair is homeomorphic, the ring is not homotopy equivalent to a point, and a lead wound once round the post cannot slide free.
import Mathlib.Topology.Homotopy.Equiv
import Mathlib.Topology.UnitInterval
import Mathlib.Analysis.SpecialFunctions.Exp
import Mathlib.Analysis.SpecialFunctions.Trigonometric.Basic
import Mathlib.Analysis.Complex.Basic
import Mathlib.Tactic.NormNum
import Mathlib.Analysis.Complex.CoveringMap
import Mathlib.Topology.Homotopy.Lifting
import Mathlib.Analysis.Convex.Contractible
import Mathlib.Topology.Order.IntermediateValue
import Mathlib.Analysis.SpecialFunctions.Complex.Log

open ContinuousMap unitInterval

/-! Points of the plane are complex numbers, with the post's centre at 0, so `‖z‖` is the
distance from the post's centre. The post is the closed disc of radius `p`, the lawn is the closed
disc of radius `R`, the ground is the lawn without the post, `{z | p < ‖z‖ ∧ ‖z‖ ≤ R}`, and the
ring is the circle of radius `ρ`, which lies in the ground. In the park, `p = 1/10`, `ρ = 2` and
`R = 5` (metres). A point is the one-point space `Unit`. -/

theorem exp_one_valued_const {X : Type*} [TopologicalSpace X] [PreconnectedSpace X]
    (g : X → ℂ) (hg : Continuous g) (h : ∀ x, Complex.exp (g x) = 1) (a b : X) :
    g a = g b := by
  have hne : (2 * Real.pi * Complex.I) ≠ 0 := by simp [Real.pi_ne_zero, Complex.I_ne_zero]
  set φ : X → ℝ := fun x => (g x / (2 * Real.pi * Complex.I)).re with hφdef
  have hφ : Continuous φ := by fun_prop
  have hφint : ∀ x, ∃ n : ℤ, φ x = n ∧ g x = n * (2 * Real.pi * Complex.I) := by
    intro x
    obtain ⟨n, hn⟩ := Complex.exp_eq_one_iff.mp (h x)
    refine ⟨n, ?_, hn⟩
    simp only [φ, hn, mul_div_cancel_right₀ _ hne, Complex.intCast_re]
  have half : ∀ (k n : ℤ), (k : ℝ) ≠ n + 1 / 2 := by
    intro k n hk
    have h2 : ((2 * k : ℤ) : ℝ) = ((2 * n + 1 : ℤ) : ℝ) := by push_cast; linarith
    have := Int.cast_injective h2
    omega
  obtain ⟨n, hn, hgn⟩ := hφint a
  obtain ⟨m, hm, hgm⟩ := hφint b
  rw [hgn, hgm]
  by_contra hnm
  have hnm' : n ≠ m := fun h => hnm (by rw [h])
  rcases lt_or_gt_of_ne hnm' with hlt | hlt
  · have hlt' : (n : ℝ) + 1 ≤ m := by exact_mod_cast hlt
    obtain ⟨x, hx⟩ := intermediate_value_univ a b hφ
      (show (n : ℝ) + 1 / 2 ∈ Set.Icc (φ a) (φ b) by
        rw [hn, hm]; constructor <;> linarith)
    obtain ⟨k, hk, -⟩ := hφint x
    exact half k n (hk ▸ hx)
  · have hlt' : (m : ℝ) + 1 ≤ n := by exact_mod_cast hlt
    obtain ⟨x, hx⟩ := intermediate_value_univ b a hφ
      (show (m : ℝ) + 1 / 2 ∈ Set.Icc (φ b) (φ a) by
        rw [hn, hm]; constructor <;> linarith)
    obtain ⟨k, hk, -⟩ := hφint x
    exact half k m (hk ▸ hx)

#print axioms exp_one_valued_const

theorem no_free_unwinding (ρ : ℝ) (hρ : 0 < ρ) (c : ℂ) (H : C(I × I, ℂ)) (h0 : ∀ x, H x ≠ 0)
    (hs : ∀ s : I, H (s, 0) = (ρ : ℂ) * Complex.exp (2 * Real.pi * Complex.I * (s : ℝ)))
    (h1 : ∀ s : I, H (s, 1) = c) (hper : ∀ t : I, H (0, t) = H (1, t)) : False := by
  have cov := Complex.isCoveringMap_exp
  let K : C(I × I, {z : ℂ // z ≠ 0}) :=
    ⟨fun x => ⟨H (x.2, x.1), h0 _⟩, by fun_prop⟩
  let f : C(I, ℂ) :=
    ⟨fun s => (Real.log ρ : ℂ) + 2 * Real.pi * Complex.I * (s : ℝ), by fun_prop⟩
  have hK0 : ∀ s, K (0, s) = ⟨Complex.exp (f s), Complex.exp_ne_zero _⟩ := by
    intro s
    apply Subtype.ext
    simp only [K, f, ContinuousMap.coe_mk, hs, Complex.exp_add, ← Complex.ofReal_exp,
      Real.exp_log hρ]
  let L := cov.liftHomotopy K f hK0
  have hL : ∀ t s, Complex.exp (L (t, s)) = H (s, t) := by
    intro t s
    have := congrArg Subtype.val (congr_fun (cov.liftHomotopy_lifts K f hK0) (t, s))
    exact this
  have hL0 : ∀ s, L (0, s) = f s := cov.liftHomotopy_zero K f hK0
  have hc : c ≠ 0 := by rw [← h1 0]; exact h0 _
  -- the change of the lift round each frame
  have hD := exp_one_valued_const (fun t : I => L (t, 1) - L (t, 0)) (by fun_prop)
    (fun t => by
      simp only [Complex.exp_sub, hL, ← hper t]
      exact div_self (h0 _)) 0 1
  have hE := exp_one_valued_const (fun s : I => L (1, s) - L (1, 0)) (by fun_prop)
    (fun s => by
      simp only [Complex.exp_sub, hL, h1]
      exact div_self hc) 0 1
  simp only [hL0, f, ContinuousMap.coe_mk, sub_self] at hD hE
  rw [← hE] at hD
  have : (2 * Real.pi * Complex.I) = 0 := by
    simpa using hD.symm
  simp [Real.pi_ne_zero, Complex.I_ne_zero] at this

#print axioms no_free_unwinding

theorem norm_wound_loop (ρ : ℝ) (hρ : 0 < ρ) (s : ℝ) :
    ‖(ρ : ℂ) * Complex.exp (2 * Real.pi * Complex.I * s)‖ = ρ := by
  have : (2 * Real.pi * Complex.I * s) = ((2 * Real.pi * s : ℝ) : ℂ) * Complex.I := by
    push_cast; ring
  rw [norm_mul, this, Complex.norm_exp_ofReal_mul_I, Complex.norm_real, Real.norm_eq_abs,
    abs_of_pos hρ, mul_one]

#print axioms norm_wound_loop

theorem annulus_hequiv_sphere (p ρ R : ℝ) (hp : 0 < p) (hpρ : p < ρ) (hρR : ρ ≤ R) :
    Nonempty ({z : ℂ | p < ‖z‖ ∧ ‖z‖ ≤ R} ≃ₕ Metric.sphere (0 : ℂ) ρ) := by
  set A := {z : ℂ | p < ‖z‖ ∧ ‖z‖ ≤ R}
  have hA : ∀ z : A, 0 < ‖(z : ℂ)‖ := fun z => hp.trans z.2.1
  have hscale : ∀ (a : ℝ) (z : ℂ), 0 ≤ a → ‖((a : ℝ) : ℂ) * z‖ = a * ‖z‖ := by
    intro a z ha
    rw [norm_mul, Complex.norm_real, Real.norm_eq_abs, abs_of_nonneg ha]
  let r : C(A, Metric.sphere (0 : ℂ) ρ) :=
    ⟨fun z => ⟨((ρ / ‖(z : ℂ)‖ : ℝ) : ℂ) * z, by
      rw [mem_sphere_zero_iff_norm, hscale _ _ (div_nonneg (hp.trans hpρ).le (hA z).le),
        div_mul_cancel₀ _ (hA z).ne']⟩, by
      apply Continuous.subtype_mk
      apply Continuous.mul _ continuous_subtype_val
      apply Complex.continuous_ofReal.comp
      exact continuous_const.div (continuous_norm.comp continuous_subtype_val)
        (fun z => (hA z).ne')⟩
  let i : C(Metric.sphere (0 : ℂ) ρ, A) :=
    ⟨fun z => ⟨z, by
      have := mem_sphere_zero_iff_norm.mp z.2
      change p < _ ∧ _ ≤ R
      rw [this]
      exact ⟨hpρ, hρR⟩⟩, by fun_prop⟩
  refine ⟨⟨r, i, ?_, ?_⟩⟩
  · refine ⟨⟨⟨fun x => ⟨((((1 - (x.1 : ℝ)) * (ρ / ‖(x.2 : ℂ)‖) + x.1 : ℝ)) : ℂ) * x.2, ?_⟩,
      ?_⟩, ?_, ?_⟩⟩
    · have hz := x.2.2
      have ht0 := x.1.2.1
      have ht1 := x.1.2.2
      have hzpos := hA x.2
      have hcoef : 0 ≤ (1 - (x.1 : ℝ)) * (ρ / ‖(x.2 : ℂ)‖) + x.1 :=
        add_nonneg (mul_nonneg (by linarith) (div_nonneg (by linarith) hzpos.le)) ht0
      have hn : ‖((((1 - (x.1 : ℝ)) * (ρ / ‖(x.2 : ℂ)‖) + x.1 : ℝ)) : ℂ) * x.2‖
          = (1 - (x.1 : ℝ)) * ρ + x.1 * ‖(x.2 : ℂ)‖ := by
        rw [hscale _ _ hcoef, add_mul, mul_assoc, div_mul_cancel₀ _ hzpos.ne']
      change p < _ ∧ _ ≤ R
      rw [hn]
      obtain ⟨hz1, hz2⟩ := hz
      rcases le_total ρ ‖(x.2 : ℂ)‖ with hle | hle
      · constructor <;> nlinarith [mul_nonneg ht0 (sub_nonneg.mpr hle)]
      · constructor <;> nlinarith [mul_nonneg (sub_nonneg.mpr ht1) (sub_nonneg.mpr hle)]
    · apply Continuous.subtype_mk
      apply Continuous.mul _ (continuous_subtype_val.comp continuous_snd)
      apply Complex.continuous_ofReal.comp
      refine Continuous.add (Continuous.mul ?_ ?_) (continuous_subtype_val.comp continuous_fst)
      · exact continuous_const.sub (continuous_subtype_val.comp continuous_fst)
      · exact continuous_const.div
          (continuous_norm.comp (continuous_subtype_val.comp continuous_snd))
          (fun x => (hA x.2).ne')
    · intro z
      apply Subtype.ext
      simp [r, i]
    · intro z
      apply Subtype.ext
      simp
  · have : r.comp i = ContinuousMap.id _ := by
      ext z
      have := mem_sphere_zero_iff_norm.mp z.2
      simp only [r, i, ContinuousMap.comp_apply, ContinuousMap.coe_mk, ContinuousMap.id_apply]
      rw [this, div_self (hp.trans hpρ).ne']
      simp
    rw [this]

#print axioms annulus_hequiv_sphere

/-- The card's main claim. Two spaces are homotopy equivalent when maps each way undo each other
up to a homotopy. The lawn squashes to a point and the ground round the post squashes onto the
ring, so lawn ≃ point and ground ≃ ring; but neither pair is homeomorphic (no one-for-one pairing
that is continuous both ways exists). -/
theorem lawn_squashes_to_point_and_ground_onto_ring_without_homeomorphism
    (p ρ R : ℝ) (hp : 0 < p) (hpρ : p < ρ) (hρR : ρ ≤ R) :
    Nonempty (Metric.closedBall (0 : ℂ) R ≃ₕ Unit) ∧
    IsEmpty (Metric.closedBall (0 : ℂ) R ≃ₜ Unit) ∧
    Nonempty ({z : ℂ | p < ‖z‖ ∧ ‖z‖ ≤ R} ≃ₕ Metric.sphere (0 : ℂ) ρ) ∧
    IsEmpty ({z : ℂ | p < ‖z‖ ∧ ‖z‖ ≤ R} ≃ₜ Metric.sphere (0 : ℂ) ρ) := by
  have hR : 0 < R := by linarith
  refine ⟨?_, ?_, annulus_hequiv_sphere p ρ R hp hpρ hρR, ?_⟩
  · have : ContractibleSpace (Metric.closedBall (0 : ℂ) R) :=
      (convex_closedBall (0 : ℂ) R).contractibleSpace ⟨0, Metric.mem_closedBall_self hR.le⟩
    exact ContractibleSpace.hequiv_unit _
  · refine ⟨fun e => ?_⟩
    have h0 : (0 : ℂ) ∈ Metric.closedBall (0 : ℂ) R := Metric.mem_closedBall_self hR.le
    have h1 : ((R : ℝ) : ℂ) ∈ Metric.closedBall (0 : ℂ) R := by
      rw [mem_closedBall_zero_iff, Complex.norm_real, Real.norm_eq_abs, abs_of_pos hR]
    have := e.injective (Subsingleton.elim (e ⟨0, h0⟩) (e ⟨(R : ℂ), h1⟩))
    have := congrArg Subtype.val this
    simp only at this
    have := congrArg Complex.re this
    simp at this
    linarith
  · refine ⟨fun e => ?_⟩
    set A := {z : ℂ | p < ‖z‖ ∧ ‖z‖ ≤ R}
    have : CompactSpace A := e.symm.compactSpace
    have hcomp : IsCompact A := isCompact_iff_compactSpace.mpr this
    have hρA : ((ρ : ℝ) : ℂ) ∈ A := by
      change p < _ ∧ _ ≤ R
      rw [Complex.norm_real, Real.norm_eq_abs, abs_of_pos (hp.trans hpρ)]
      exact ⟨hpρ, hρR⟩
    obtain ⟨z, hzA, hmin⟩ := hcomp.exists_isMinOn ⟨_, hρA⟩ continuous_norm.continuousOn
    have hz : p < ‖z‖ ∧ ‖z‖ ≤ R := hzA
    have hzpos : 0 < ‖z‖ := hp.trans hz.1
    set w : ℂ := (((p + ‖z‖) / 2 / ‖z‖ : ℝ) : ℂ) * z
    have hw : ‖w‖ = (p + ‖z‖) / 2 := by
      simp only [w]
      rw [norm_mul, Complex.norm_real, Real.norm_eq_abs,
        abs_of_pos (div_pos (by linarith) hzpos), div_mul_cancel₀ _ hzpos.ne']
    have hwA : w ∈ A := by
      change p < _ ∧ _ ≤ R
      rw [hw]; constructor <;> linarith
    have := hmin hwA
    simp only [Set.mem_ofPred_eq, hw] at this
    linarith

/-- Wound once, the lead cannot slide free. The walk wound once round the post on the ring,
`s ↦ ρ e^(2πis)`, is not homotopic in the ground to the owner standing still at any point `c` of
the ground: no continuous film `H(s, t)` of closed walks (each frame ends where it starts, though
the start may move from frame to frame) stays in the ground, starts at the wound walk and ends at
the constant walk at `c`. -/
theorem wound_walk_cannot_slide_free
    (p ρ R : ℝ) (hp : 0 < p) (hpρ : p < ρ) (hρR : ρ ≤ R)
    (c : ℂ) (hc : p < ‖c‖ ∧ ‖c‖ ≤ R) :
    ¬ ∃ H : C(I × I, ℂ),
      (∀ x, p < ‖H x‖ ∧ ‖H x‖ ≤ R) ∧
      (∀ s : I, H (s, 0) = (ρ : ℂ) * Complex.exp (2 * Real.pi * Complex.I * (s : ℝ))) ∧
      (∀ s : I, H (s, 1) = c) ∧
      (∀ t : I, H (0, t) = H (1, t)) := by
  rintro ⟨H, hH, hs, h1, hper⟩
  exact no_free_unwinding ρ (hp.trans hpρ) c H
    (fun x => norm_pos_iff.mp (hp.trans (hH x).1)) hs h1 hper

/-- The ring is not homotopy equivalent to a point: going ring → point → ring is never homotopic
to the identity of the ring. -/
theorem ring_not_homotopy_equivalent_to_point (ρ : ℝ) (hρ : 0 < ρ) :
    IsEmpty (Metric.sphere (0 : ℂ) ρ ≃ₕ Unit) := by
  refine ⟨fun e => ?_⟩
  obtain ⟨F⟩ := e.left_inv
  let γ : C(I, Metric.sphere (0 : ℂ) ρ) :=
    ⟨fun s => ⟨(ρ : ℂ) * Complex.exp (2 * Real.pi * Complex.I * (s : ℝ)), by
      rw [mem_sphere_zero_iff_norm]; exact norm_wound_loop ρ hρ s⟩, by fun_prop⟩
  let H : C(I × I, ℂ) :=
    ⟨fun x => (F.symm (x.2, γ x.1) : ℂ), by fun_prop⟩
  refine no_free_unwinding ρ hρ (e.invFun () : ℂ) H ?_ ?_ ?_ ?_
  · intro x
    have := mem_sphere_zero_iff_norm.mp (F.symm (x.2, γ x.1)).2
    exact norm_pos_iff.mp (this ▸ hρ)
  · intro s
    simp [H, γ]
  · intro s
    simp [H]
  · intro t
    simp only [H, ContinuousMap.coe_mk]
    congr 3
    apply Subtype.ext
    simp [γ]

-- The straight slide of the wound walk: gamma_1(1/2) = (-2, 0) goes to 1/2 (-2, 0) + 1/2 (2, 0) = (0, 0), inside the post.
example : (1 / 2 : ℚ) * (-2) + (1 / 2) * 2 = 0 ∧ (1 / 2 : ℚ) * 0 + (1 / 2) * 0 = 0 := by norm_num
-- The wound walk's nearest approach to the post in frame t is |2 - 4t|: 2 at t = 0, 0 at t = 1/2, 4/5 at t = 3/10.
example : |(2 : ℚ) - 4 * 0| = 2 ∧ |(2 : ℚ) - 4 * (1 / 2)| = 0 ∧ |(2 : ℚ) - 4 * (3 / 10)| = 4 / 5 := by
  norm_num [abs_of_pos]
-- The bench walk's frame t is the circle of radius 1 - t round (3 - t, 0): nearest the post 2 m away in every frame.
example (t : ℝ) : (3 - t) - (1 - t) = 2 := by ring
-- The lawn squash at t = 1/2 takes (3, 4) to (3/2, 2); (3, 4) is on the lawn's edge, 5 m out.
example : (1 - 1 / 2 : ℚ) * 3 = 3 / 2 ∧ (1 - 1 / 2 : ℚ) * 4 = 2 ∧ (3 : ℤ) ^ 2 + 4 ^ 2 = 5 ^ 2 := by norm_num
-- The ground squash: (3/10, 4/10) is 1/2 m out; at t = 1 it goes to 2 x / |x| = (6/5, 8/5), at t = 1/2 to (3/4, 1).
example : (3 / 10 : ℚ) ^ 2 + (4 / 10) ^ 2 = (1 / 2) ^ 2 ∧
    2 * (3 / 10 : ℚ) / (1 / 2) = 6 / 5 ∧ 2 * (4 / 10 : ℚ) / (1 / 2) = 8 / 5 ∧
    (1 / 2 : ℚ) * (3 / 10) + (1 / 2) * (6 / 5) = 3 / 4 ∧ (1 / 2 : ℚ) * (4 / 10) + (1 / 2) * (8 / 5) = 1 := by
  norm_num
-- The lawn's integer grid: 81 points (a, b) with a^2 + b^2 ≤ 25.
example : ((Finset.range 11 ×ˢ Finset.range 11).filter
    (fun q : ℕ × ℕ => ((q.1 : ℤ) - 5) ^ 2 + ((q.2 : ℤ) - 5) ^ 2 ≤ 25)).card = 81 := by decide

#print axioms lawn_squashes_to_point_and_ground_onto_ring_without_homeomorphism
#print axioms wound_walk_cannot_slide_free
#print axioms ring_not_homotopy_equivalent_to_point
