-- L-BFGS: the two-loop recursion returns exactly the BFGS inverse table, rebuilt from the stored step pairs, applied to the slope; when every pair has yᵀs > 0 and the start guess is positive that direction points downhill; and for a cost with curvature at least μ, every value lies within ‖∇f‖ / μ of the minimiser.
import Mathlib.Data.Matrix.Mul
import Mathlib.LinearAlgebra.Matrix.Notation
import Mathlib.Analysis.Convex.Strong
import Mathlib.Analysis.Calculus.Gradient.Basic
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Tactic.NormNum
import Mathlib.LinearAlgebra.Matrix.DotProduct
import Mathlib.Analysis.Calculus.Deriv.Slope
import Mathlib.Analysis.Calculus.Deriv.Comp
import Mathlib.Analysis.Calculus.Deriv.Mul

open Matrix

namespace LBFGS

variable {n : ℕ}

/-- `σ = 1 / (yᵀ s)` for one stored pair `(s, y)`. -/
noncomputable def sigma (s y : Fin n → ℝ) : ℝ := 1 / (y ⬝ᵥ s)

/-- One BFGS update of the inverse table:
`W' = Vᵀ W V + σ s sᵀ`, with `V = I - σ y sᵀ`. -/
noncomputable def bfgsUpdate (W : Matrix (Fin n) (Fin n) ℝ) (s y : Fin n → ℝ) :
    Matrix (Fin n) (Fin n) ℝ :=
  let V : Matrix (Fin n) (Fin n) ℝ := 1 - sigma s y • vecMulVec y s
  Vᵀ * W * V + sigma s y • vecMulVec s s

/-- The table L-BFGS never stores: start from `W₀ = γ I` and apply the BFGS update for each
stored pair `(s, y)`, oldest first. -/
noncomputable def bfgsInv (γ : ℝ) (ps : List ((Fin n → ℝ) × (Fin n → ℝ))) :
    Matrix (Fin n) (Fin n) ℝ :=
  ps.foldl (fun W p => bfgsUpdate W p.1 p.2) (γ • (1 : Matrix (Fin n) (Fin n) ℝ))

/-- The two-loop recursion on the slope `g`, with the pairs listed oldest first.
First loop, newest pair to oldest: `a = σ sᵀ q`, `q ← q - a y`.
Then `z = γ q`.
Second loop, oldest pair to newest: `b = σ yᵀ z`, `z ← z + (a - b) s`.
It returns `z`; the L-BFGS direction is `d = -z`. -/
noncomputable def twoLoop (γ : ℝ) (ps : List ((Fin n → ℝ) × (Fin n → ℝ))) (g : Fin n → ℝ) :
    Fin n → ℝ :=
  -- first loop, newest to oldest; each `a` is put in front, so `as` ends up oldest first
  let qa : (Fin n → ℝ) × List ℝ :=
    ps.reverse.foldl
      (fun acc p =>
        let a := sigma p.1 p.2 * (p.1 ⬝ᵥ acc.1)
        (acc.1 - a • p.2, a :: acc.2))
      (g, [])
  -- scale by the start guess
  let z : Fin n → ℝ := γ • qa.1
  -- second loop, oldest to newest
  (ps.zip qa.2).foldl
    (fun z pa =>
      let b := sigma pa.1.1 pa.1.2 * (pa.1.2 ⬝ᵥ z)
      z + (pa.2 - b) • pa.1.1)
    z

/-- The L-BFGS search direction `d = -z` from the two loops. -/
noncomputable def direction (γ : ℝ) (ps : List ((Fin n → ℝ) × (Fin n → ℝ))) (g : Fin n → ℝ) :
    Fin n → ℝ :=
  -twoLoop γ ps g

theorem firstLoop_append (L : List ((Fin n → ℝ) × (Fin n → ℝ))) (q : Fin n → ℝ) (l : List ℝ) :
    L.foldl
      (fun acc p =>
        let a := sigma p.1 p.2 * (p.1 ⬝ᵥ acc.1)
        (acc.1 - a • p.2, a :: acc.2)) (q, l) =
    ((L.foldl
      (fun acc p =>
        let a := sigma p.1 p.2 * (p.1 ⬝ᵥ acc.1)
        (acc.1 - a • p.2, a :: acc.2)) (q, [])).1,
     (L.foldl
      (fun acc p =>
        let a := sigma p.1 p.2 * (p.1 ⬝ᵥ acc.1)
        (acc.1 - a • p.2, a :: acc.2)) (q, [])).2 ++ l) := by
  induction L generalizing q l with
  | nil => simp
  | cons p L ih =>
    simp only [List.foldl_cons]
    rw [ih, ih (l := [_])]
    simp

#print axioms firstLoop_append

theorem firstLoop_length (L : List ((Fin n → ℝ) × (Fin n → ℝ))) (q : Fin n → ℝ) :
    (L.foldl
      (fun acc p =>
        let a := sigma p.1 p.2 * (p.1 ⬝ᵥ acc.1)
        (acc.1 - a • p.2, a :: acc.2)) (q, [])).2.length = L.length := by
  induction L generalizing q with
  | nil => simp
  | cons p L ih =>
    simp only [List.foldl_cons]
    rw [firstLoop_append, List.length_append, ih]
    simp

#print axioms firstLoop_length

theorem bfgsUpdate_mulVec (W : Matrix (Fin n) (Fin n) ℝ) (s y g : Fin n → ℝ) :
    bfgsUpdate W s y *ᵥ g =
      W *ᵥ (g - (sigma s y * (s ⬝ᵥ g)) • y) +
        (sigma s y * (s ⬝ᵥ g) - sigma s y * (y ⬝ᵥ (W *ᵥ (g - (sigma s y * (s ⬝ᵥ g)) • y)))) • s := by
  simp only [bfgsUpdate, transpose_sub, transpose_one, transpose_smul, transpose_vecMulVec,
    add_mulVec, ← mulVec_mulVec, sub_mulVec, one_mulVec, smul_mulVec, vecMulVec_mulVec]
  ext i
  simp [mulVec_sub, mulVec_smul, dotProduct_sub, dotProduct_smul]
  ring

#print axioms bfgsUpdate_mulVec

/-- The recipe gives exactly the BFGS direction: for any start guess `γ`, any stored pairs
`(s, y)` and any slope `g`, the two loops return the BFGS inverse table `W_m`, built from
`γ I` by the BFGS update pair by pair, applied to `g`; so L-BFGS never has to store the table. -/
theorem two_loop_eq_bfgs_inverse_mul (γ : ℝ) (ps : List ((Fin n → ℝ) × (Fin n → ℝ)))
    (g : Fin n → ℝ) :
    twoLoop γ ps g = bfgsInv γ ps *ᵥ g := by
  induction ps using List.reverseRecOn generalizing g with
  | nil => simp [twoLoop, bfgsInv, smul_mulVec]
  | append_singleton ps p ih =>
    have hb : bfgsInv γ (ps ++ [p]) = bfgsUpdate (bfgsInv γ ps) p.1 p.2 := by
      simp [bfgsInv, List.foldl_append]
    rw [hb, bfgsUpdate_mulVec, ← ih]
    simp only [twoLoop, List.reverse_append, List.reverse_singleton, List.singleton_append,
      List.foldl_cons]
    rw [firstLoop_append, List.zip_append (by rw [firstLoop_length, List.length_reverse]),
      List.foldl_append]
    simp

theorem bfgsUpdate_posDef (W : Matrix (Fin n) (Fin n) ℝ)
    (hW : ∀ v : Fin n → ℝ, v ≠ 0 → 0 < v ⬝ᵥ (W *ᵥ v)) (s y : Fin n → ℝ) (hys : 0 < y ⬝ᵥ s) :
    ∀ v : Fin n → ℝ, v ≠ 0 → 0 < v ⬝ᵥ (bfgsUpdate W s y *ᵥ v) := by
  intro v hv
  have hσ : 0 < sigma s y := by unfold sigma; positivity
  set a := sigma s y * (s ⬝ᵥ v) with ha
  set u := v - a • y with hu
  have key : v ⬝ᵥ (bfgsUpdate W s y *ᵥ v) = u ⬝ᵥ (W *ᵥ u) + sigma s y * (s ⬝ᵥ v) ^ 2 := by
    rw [bfgsUpdate_mulVec]
    simp only [← ha, ← hu, dotProduct_add, dotProduct_smul, smul_eq_mul]
    rw [hu]
    simp only [sub_dotProduct, smul_dotProduct, smul_eq_mul, dotProduct_comm v s]
    rw [ha]; ring
  rw [key]
  by_cases hu0 : u = 0
  · have hsv : s ⬝ᵥ v ≠ 0 := by
      intro h0
      apply hv
      have : a = 0 := by rw [ha, h0, mul_zero]
      rw [hu, this, zero_smul, sub_zero] at hu0
      exact hu0
    rw [hu0, zero_dotProduct, zero_add]
    have : 0 < (s ⬝ᵥ v) ^ 2 := by positivity
    positivity
  · have := hW u hu0
    have : 0 ≤ sigma s y * (s ⬝ᵥ v) ^ 2 := by positivity
    linarith

#print axioms bfgsUpdate_posDef

theorem foldl_posDef (ps : List ((Fin n → ℝ) × (Fin n → ℝ)))
    (hps : ∀ p ∈ ps, 0 < p.2 ⬝ᵥ p.1) (W : Matrix (Fin n) (Fin n) ℝ)
    (hW : ∀ v : Fin n → ℝ, v ≠ 0 → 0 < v ⬝ᵥ (W *ᵥ v)) :
    ∀ v : Fin n → ℝ, v ≠ 0 →
      0 < v ⬝ᵥ (ps.foldl (fun W p => bfgsUpdate W p.1 p.2) W *ᵥ v) := by
  induction ps generalizing W with
  | nil => simpa using hW
  | cons p ps ih =>
    simp only [List.foldl_cons]
    apply ih (fun q hq => hps q (List.mem_cons_of_mem _ hq))
    exact bfgsUpdate_posDef W hW p.1 p.2 (hps p List.mem_cons_self)

#print axioms foldl_posDef

/-- Every rebuilt direction points downhill: if the start guess `γ` is positive and every stored
pair has `yᵀ s > 0`, then for every nonzero slope `g` the L-BFGS direction `d` has `gᵀ d < 0`. -/
theorem direction_downhill (γ : ℝ) (hγ : 0 < γ) (ps : List ((Fin n → ℝ) × (Fin n → ℝ)))
    (hps : ∀ p ∈ ps, 0 < p.2 ⬝ᵥ p.1) (g : Fin n → ℝ) (hg : g ≠ 0) :
    g ⬝ᵥ direction γ ps g < 0 := by
  have h0 : ∀ v : Fin n → ℝ, v ≠ 0 →
      0 < v ⬝ᵥ ((γ • (1 : Matrix (Fin n) (Fin n) ℝ)) *ᵥ v) := by
    intro v hv
    rw [smul_mulVec, one_mulVec, dotProduct_smul, smul_eq_mul]
    have : 0 < v ⬝ᵥ v := by
      have hn : 0 ≤ v ⬝ᵥ v := Finset.sum_nonneg fun i _ => mul_self_nonneg (v i)
      rcases lt_or_eq_of_le hn with h | h
      · exact h
      · exact absurd (dotProduct_self_eq_zero.mp h.symm) hv
    positivity
  have := foldl_posDef ps hps _ h0 g hg
  rw [direction, two_loop_eq_bfgs_inverse_mul, dotProduct_neg]
  simpa [bfgsInv] using this

theorem dist_le_grad_div {E : Type*} [NormedAddCommGroup E] [InnerProductSpace ℝ E]
    [CompleteSpace E] (f : E → ℝ) (μ : ℝ) (hμ : 0 < μ)
    (hf : StrongConvexOn Set.univ μ f) (cstar : E)
    (hmin : ∀ c, f cstar ≤ f c) (c G : E) (hG : HasGradientAt f G c) :
    ‖c - cstar‖ ≤ ‖G‖ / μ := by
  set d := cstar - c with hd
  set K := μ / 2 * ‖d‖ ^ 2 with hK
  -- the line through c towards cstar
  set φ : ℝ → ℝ := fun t => f (c + t • d) with hφ
  have hφd : HasDerivAt φ (inner ℝ G d) 0 := by
    have h1 : HasDerivAt (fun t : ℝ => c + t • d) d 0 := by
      simpa using ((hasDerivAt_id (0 : ℝ)).smul_const d).const_add c
    have h2 : HasFDerivAt f (InnerProductSpace.toDual ℝ E G) (c + (0 : ℝ) • d) := by
      simpa using hG.hasFDerivAt
    have := h2.comp_hasDerivAt (0 : ℝ) h1
    simpa [Function.comp_def, InnerProductSpace.toDual_apply_apply] using this
  -- slope bound for t ∈ (0, 1)
  have hbound : ∀ t : ℝ, 0 < t → t < 1 → t⁻¹ • (φ (0 + t) - φ 0) ≤ -(2 * ((1 - t) * K)) := by
    intro t ht0 ht1
    have hA := hf.2 (Set.mem_univ cstar) (Set.mem_univ c) ht0.le (by linarith : (0 : ℝ) ≤ 1 - t)
      (by ring)
    have hB := hf.2 (Set.mem_univ c) (Set.mem_univ cstar) ht0.le (by linarith : (0 : ℝ) ≤ 1 - t)
      (by ring)
    have hm := hmin (t • c + (1 - t) • cstar)
    have hpt : t • cstar + (1 - t) • c = c + t • d := by
      rw [hd, smul_sub, sub_smul, one_smul]; abel
    rw [hpt] at hA
    have hn : ‖c - cstar‖ = ‖d‖ := by rw [hd, norm_sub_rev]
    have hn' : ‖cstar - c‖ = ‖d‖ := by rw [hd]
    rw [hn] at hB
    rw [hn'] at hA
    simp only [smul_eq_mul] at hA hB
    simp only [hφ, zero_add, zero_smul, add_zero, smul_eq_mul]
    rw [inv_mul_le_iff₀ ht0]
    have hB' : t * f cstar ≤ t * f c - t * (1 - t) * K := by rw [hK]; nlinarith
    have hB'' : f cstar ≤ f c - (1 - t) * K := by
      have : t * f cstar ≤ t * (f c - (1 - t) * K) := by nlinarith
      exact le_of_mul_le_mul_left this ht0
    rw [hK]; rw [hK] at hB''
    nlinarith
  have hlim : inner ℝ G d ≤ -(2 * ((1 - 0) * K)) := by
    have hT := hφd.tendsto_slope_zero_right
    have hR : Filter.Tendsto (fun t : ℝ => -(2 * ((1 - t) * K))) (nhdsWithin 0 (Set.Ioi 0))
        (nhds (-(2 * ((1 - 0) * K)))) := by
      apply Filter.Tendsto.mono_left _ nhdsWithin_le_nhds
      exact ((continuous_const.sub continuous_id).mul continuous_const).const_mul 2 |>.neg
        |>.tendsto 0
    apply le_of_tendsto_of_tendsto hT hR
    have hev : ∀ᶠ t in nhdsWithin (0 : ℝ) (Set.Ioi 0), t ∈ Set.Ioo (0 : ℝ) 1 :=
      Ioo_mem_nhdsGT (by norm_num)
    filter_upwards [hev] with t ht
    exact hbound t ht.1 ht.2
  have hcs : -(inner ℝ G d) ≤ ‖G‖ * ‖d‖ := by
    have := abs_real_inner_le_norm G d
    linarith [neg_abs_le (inner ℝ G d), le_abs_self (-(inner ℝ G d)), abs_neg (inner ℝ G d)]
  have hmain : μ * ‖d‖ ^ 2 ≤ ‖G‖ * ‖d‖ := by
    rw [hK] at hlim; nlinarith
  have hn : ‖c - cstar‖ = ‖d‖ := by rw [hd, norm_sub_rev]
  rw [hn, le_div_iff₀ hμ]
  rcases eq_or_lt_of_le (norm_nonneg d) with h | h
  · rw [← h]; simp
  · have : μ * ‖d‖ * ‖d‖ ≤ ‖G‖ * ‖d‖ := by nlinarith
    have := le_of_mul_le_mul_right this h
    linarith

#print axioms dist_le_grad_div

/-- The certificate: if the cost's curvature is at least `μ > 0` everywhere (it is `μ`-strongly
convex), `cstar` is a lowest point and `G` is the gradient at `c`, then every value `c i` lies
within `‖G‖ / μ` of `cstar i`. -/
theorem certificate_from_gradient_length (f : EuclideanSpace ℝ (Fin n) → ℝ) (μ : ℝ) (hμ : 0 < μ)
    (hf : StrongConvexOn Set.univ μ f) (cstar : EuclideanSpace ℝ (Fin n))
    (hmin : ∀ c, f cstar ≤ f c) (c G : EuclideanSpace ℝ (Fin n)) (hG : HasGradientAt f G c) :
    ∀ i, |c i - cstar i| ≤ ‖G‖ / μ := by
  intro i
  have h := dist_le_grad_div f μ hμ hf cstar hmin c G hG
  have h2 := PiLp.norm_apply_le (c - cstar) i
  simp only [PiLp.sub_apply, Real.norm_eq_abs] at h2
  linarith

/-! The card's bill for one direction, on the 50,000-reading fit with ten pairs. -/

-- entries in a stored BFGS table, and the multiply-adds of table times slope
example : 50000 * 50000 = 2500000000 := by norm_num
-- its memory at 8 bytes per number: 20.0 GB
example : 2500000000 * 8 = 20 * 10 ^ 9 := by norm_num
-- numbers in ten pairs, and their memory: 8.0 MB
example : 2 * 10 * 50000 = 1000000 := by norm_num
example : 1000000 * 8 = 8 * 10 ^ 6 := by norm_num
-- multiply-adds for the two loops, 4mn + n
example : 4 * 10 * 50000 + 50000 = 2050000 := by norm_num
-- the memory sweep: one pair 0.8 MB, twenty pairs 16.0 MB
example : 2 * 1 * 50000 * 8 = 8 * 10 ^ 5 := by norm_num
example : 2 * 20 * 50000 * 8 = 16 * 10 ^ 6 := by norm_num
-- greatest curvature of the fit, L = 2 + 8 λ with λ = 100
example : 2 + 8 * 100 = 802 := by norm_num

#print axioms two_loop_eq_bfgs_inverse_mul
#print axioms direction_downhill
#print axioms certificate_from_gradient_length

end LBFGS
