-- The Smale horseshoe: the points of the square that stay forever under the stretch-and-fold map are a Cantor set times a Cantor set, their 0/1 codes match them one-to-one and continuously with all two-way coin-toss sequences so that one round of the map is one shift, and exactly 2^n of them come back after n rounds.
import Mathlib.Topology.Instances.CantorSet
import Mathlib.Dynamics.SymbolicDynamics.Basic
import Mathlib.Dynamics.PeriodicPts.Defs
import Mathlib.Topology.Homeomorph.Lemmas
import Mathlib.Algebra.Ring.Periodic
import Mathlib.Data.Set.Card

/-- The unit square `S`: a point is `(x, y)`, `x` across and `y` up, both from 0 to 1. -/
def unitSquare : Set (ℝ × ℝ) := Set.Icc (0 : ℝ) 1 ×ˢ Set.Icc (0 : ℝ) 1

/-- The horseshoe map `f`, as on the card: the bottom third `0 ≤ y ≤ 1/3` goes to
`(x/3, 3y)`, onto the left third; everything higher goes to `(1 - x/3, 3 - 3y)`, so the top
third `2/3 ≤ y ≤ 1` lands on the right third upside down and the middle third leaves the
square (its height becomes more than 1). -/
noncomputable def horseshoe (p : ℝ × ℝ) : ℝ × ℝ :=
  if p.2 ≤ 1 / 3 then (p.1 / 3, 3 * p.2) else (1 - p.1 / 3, 3 - 3 * p.2)

/-- A two-way orbit that never leaves the square: `γ k` is where the point is after `k`
rounds (negative `k` for the past), every place is in the square, and each round is one
step of the map. -/
def IsSquareOrbit (γ : ℤ → ℝ × ℝ) : Prop :=
  ∀ k : ℤ, γ k ∈ unitSquare ∧ horseshoe (γ k) = γ (k + 1)

/-- The invariant set `Λ`: the points of the square that stay in it forever, forward and
backward, that is, the points that sit at round 0 of a two-way orbit inside the square. -/
def horseshoeInvariantSet : Set (ℝ × ℝ) :=
  {p | ∃ γ : ℤ → ℝ × ℝ, IsSquareOrbit γ ∧ γ 0 = p}

/-! ## Helper lemmas for the proofs below -/

/-- Ternary digits (0 or 2) built from a 0/1 sequence by running parity. -/
noncomputable def hsDigit (w : ℕ → Fin 2) (n : ℕ) : Fin 3 :=
  if (∑ j ∈ Finset.range (n + 1), (w j : ℕ)) % 2 = 0 then 0 else 2

/-- The real number in the Cantor set coded by a one-way 0/1 sequence. -/
noncomputable def hsVal (w : ℕ → Fin 2) : ℝ := Real.ofDigits (hsDigit w)

lemma hs_fin_two (c : Fin 2) : c = 0 ∨ c = 1 := by
  fin_cases c <;> simp

lemma hs_ofDigits_add (a b : ℕ → Fin 3) (h : ∀ i, ((a i : ℕ) : ℝ) + ((b i : ℕ) : ℝ) = 2) :
    Real.ofDigits a + Real.ofDigits b = 1 := by
  rw [← Real.ofDigits_const_last_eq_one' (b := 3) (by norm_num)]
  unfold Real.ofDigits
  rw [← Summable.tsum_add Real.summable_ofDigitsTerm Real.summable_ofDigitsTerm]
  congr 1
  funext i
  simp only [Real.ofDigitsTerm]
  rw [← add_mul, h i]
  norm_num

lemma hs_val_nonneg (w : ℕ → Fin 2) : 0 ≤ hsVal w := Real.ofDigits_nonneg _

lemma hs_val_le_one (w : ℕ → Fin 2) : hsVal w ≤ 1 := Real.ofDigits_le_one _

lemma hs_val_mem_cantor (w : ℕ → Fin 2) : hsVal w ∈ cantorSet :=
  ofDigits_zero_two_sequence_mem_cantorSet (fun n => by unfold hsDigit; split_ifs <;> decide)

lemma hs_continuous_val : Continuous hsVal := by
  refine Real.continuous_ofDigits.comp (continuous_pi fun n => ?_)
  have h1 : Continuous (fun w : ℕ → Fin 2 => ∑ j ∈ Finset.range (n + 1), (w j : ℕ)) :=
    continuous_finsetSum _ fun j _ => continuous_of_discreteTopology.comp (continuous_apply j)
  exact (continuous_of_discreteTopology
    (f := fun m : ℕ => if m % 2 = 0 then (0 : Fin 3) else 2)).comp h1

lemma hs_val_cons (w : ℕ → Fin 2) :
    hsVal w = if w 0 = 0 then hsVal (fun n => w (n + 1)) / 3
      else 1 - hsVal (fun n => w (n + 1)) / 3 := by
  unfold hsVal
  rw [Real.ofDigits_eq_sum_add_ofDigits _ 1]
  simp only [Finset.range_one, Finset.sum_singleton, Real.ofDigitsTerm]
  have hsucc : ∀ i, (∑ j ∈ Finset.range (i + 1 + 1), (w j : ℕ)) =
      (∑ j ∈ Finset.range (i + 1), (w (j + 1) : ℕ)) + (w 0 : ℕ) :=
    fun i => Finset.sum_range_succ' _ _
  rcases hs_fin_two (w 0) with h0 | h0
  · have hd : (fun i => hsDigit w (i + 1)) = hsDigit (fun n => w (n + 1)) := by
      funext i
      simp only [hsDigit, hsucc, h0, Fin.val_zero, add_zero]
    have h00 : hsDigit w 0 = 0 := by simp [hsDigit, h0]
    rw [hd, h00]; simp only [h0, ite_true]
    simp
    ring
  · have hd : ∀ i, ((hsDigit w (i + 1) : ℕ) : ℝ) + ((hsDigit (fun n => w (n + 1)) i : ℕ) : ℝ) = 2 := by
      intro i
      simp only [hsDigit, hsucc, h0, Fin.val_one]
      split_ifs with h1 h2 h2 <;> first | (norm_num; done) | (exfalso; omega)
    have hc := hs_ofDigits_add _ _ hd
    have h02 : hsDigit w 0 = 2 := by simp [hsDigit, h0]
    rw [h02]; simp only [h0, show (1 : Fin 2) ≠ 0 by decide, ite_false]
    have : ((2 : Fin 3) : ℕ) = 2 := rfl
    simp only [this]
    push_cast
    linarith

/-- The forward half of a two-way sequence (rounds 0, 1, 2, ...). -/
def hsFwd (s : ℤ → Fin 2) : ℕ → Fin 2 := fun n => s n

/-- The backward half of a two-way sequence (rounds -1, -2, ...). -/
def hsBwd (s : ℤ → Fin 2) : ℕ → Fin 2 := fun n => s (-(n : ℤ) - 1)

/-- The point of the square coded by a two-way sequence. -/
noncomputable def hsPt (s : ℤ → Fin 2) : ℝ × ℝ := (hsVal (hsBwd s), hsVal (hsFwd s))

/-- The orbit of the coded point: round `k` is the point coded by the sequence shifted `k`. -/
noncomputable def hsOrbit (s : ℤ → Fin 2) (k : ℤ) : ℝ × ℝ := hsPt (fun j => s (j + k))

lemma hs_pt_mem (s : ℤ → Fin 2) : hsPt s ∈ unitSquare :=
  ⟨⟨hs_val_nonneg _, hs_val_le_one _⟩, ⟨hs_val_nonneg _, hs_val_le_one _⟩⟩

lemma hs_pt_snd (s : ℤ → Fin 2) :
    (hsPt s).2 = if s 0 = 0 then hsVal (hsFwd (fun j => s (j + 1))) / 3
      else 1 - hsVal (hsFwd (fun j => s (j + 1))) / 3 := by
  have e3 : hsFwd s 0 = s 0 := by simp [hsFwd]
  have e4 : (fun n => hsFwd s (n + 1)) = hsFwd (fun j => s (j + 1)) := by
    funext n; simp only [hsFwd]; push_cast; rfl
  have hy := hs_val_cons (hsFwd s)
  rw [e3, e4] at hy
  exact hy

lemma hs_symbol (s : ℤ → Fin 2) :
    (s 0 = 1 ↔ 2 / 3 ≤ (hsPt s).2) ∧ (s 0 = 0 ↔ (hsPt s).2 ≤ 1 / 3) := by
  rw [hs_pt_snd]
  have b0 := hs_val_nonneg (hsFwd (fun j => s (j + 1)))
  have b1 := hs_val_le_one (hsFwd (fun j => s (j + 1)))
  rcases hs_fin_two (s 0) with h | h
  · simp only [h, ite_true]
    constructor
    · constructor
      · intro h'; exact absurd h' (by decide)
      · intro h'; linarith
    · constructor
      · intro _; linarith
      · intro _; trivial
  · simp only [h, show (1 : Fin 2) ≠ 0 by decide, ite_false]
    constructor
    · constructor
      · intro _; linarith
      · intro _; trivial
    · constructor
      · intro h'; exact absurd h' (by decide)
      · intro h'; linarith

lemma hs_horseshoe_pt (s : ℤ → Fin 2) : horseshoe (hsPt s) = hsPt (fun j => s (j + 1)) := by
  have e1 : hsBwd (fun j => s (j + 1)) 0 = s 0 := by simp [hsBwd]
  have e2 : (fun n => hsBwd (fun j => s (j + 1)) (n + 1)) = hsBwd s := by
    funext n; simp only [hsBwd]; congr 1; push_cast; ring
  have hx := hs_val_cons (hsBwd (fun j => s (j + 1)))
  rw [e1, e2] at hx
  have hy := hs_pt_snd s
  have b0 := hs_val_nonneg (hsFwd (fun j => s (j + 1)))
  have b1 := hs_val_le_one (hsFwd (fun j => s (j + 1)))
  rcases hs_fin_two (s 0) with h | h
  · simp only [h, ite_true] at hx hy
    have hle : (hsPt s).2 ≤ 1 / 3 := by rw [hy]; linarith
    unfold horseshoe
    rw [ite_eq_left hle]
    ext
    · simp only [hsPt] at hx ⊢; rw [hx]
    · simp only [hsPt] at hy ⊢; rw [hy]; ring
  · simp only [h, show (1 : Fin 2) ≠ 0 by decide, ite_false] at hx hy
    have hle : ¬ (hsPt s).2 ≤ 1 / 3 := by rw [hy]; linarith
    unfold horseshoe
    rw [ite_eq_right hle]
    ext
    · simp only [hsPt] at hx ⊢; rw [hx]
    · simp only [hsPt] at hy ⊢; rw [hy]; ring

lemma hs_orbit_zero (s : ℤ → Fin 2) : hsOrbit s 0 = hsPt s := by
  simp [hsOrbit]

lemma hs_orbit_isSquareOrbit (s : ℤ → Fin 2) : IsSquareOrbit (hsOrbit s) := by
  intro k
  refine ⟨hs_pt_mem _, ?_⟩
  rw [hsOrbit, hs_horseshoe_pt, hsOrbit]
  congr 1
  funext j
  congr 1
  ring

lemma hs_orbit_symbol (s : ℤ → Fin 2) (k : ℤ) :
    (s k = 1 ↔ 2 / 3 ≤ (hsOrbit s k).2) ∧ (s k = 0 ↔ (hsOrbit s k).2 ≤ 1 / 3) := by
  have := hs_symbol (fun j => s (j + k))
  simpa [hsOrbit] using this

lemma hs_horseshoe_injOn {a b : ℝ × ℝ} (ha : a ∈ unitSquare) (hb : b ∈ unitSquare)
    (h : horseshoe a = horseshoe b) : a = b := by
  simp only [unitSquare, Set.mem_prod, Set.mem_Icc] at ha hb
  unfold horseshoe at h
  split_ifs at h with h1 h2 h2 <;> simp only [Prod.mk.injEq] at h <;> obtain ⟨e1, e2⟩ := h <;>
    ext <;> linarith

lemma hs_orbit_unique {γ γ' : ℤ → ℝ × ℝ} (hγ : IsSquareOrbit γ) (hγ' : IsSquareOrbit γ')
    (h0 : γ 0 = γ' 0) (k : ℤ) : γ k = γ' k := by
  induction k using Int.induction_on with
  | zero => exact h0
  | succ i ih => rw [← (hγ i).2, ← (hγ' i).2, ih]
  | pred i ih =>
    apply hs_horseshoe_injOn (hγ _).1 (hγ' _).1
    rw [(hγ _).2, (hγ' _).2]
    simpa using ih

lemma hs_branch {γ : ℤ → ℝ × ℝ} (hγ : IsSquareOrbit γ) (k : ℤ) :
    (γ k).2 ≤ 1 / 3 ∨ 2 / 3 ≤ (γ k).2 := by
  have h1 := (hγ (k + 1)).1
  rw [← (hγ k).2] at h1
  by_cases h : (γ k).2 ≤ 1 / 3
  · exact Or.inl h
  · right
    unfold horseshoe at h1
    rw [ite_eq_right h] at h1
    simp only [unitSquare, Set.mem_prod, Set.mem_Icc] at h1
    linarith [h1.2.2]

lemma hs_step {p q : ℝ × ℝ} (hb : p.2 ≤ 1 / 3 ↔ q.2 ≤ 1 / 3) :
    |(horseshoe p).1 - (horseshoe q).1| = |p.1 - q.1| / 3 ∧
      |(horseshoe p).2 - (horseshoe q).2| = 3 * |p.2 - q.2| := by
  unfold horseshoe
  by_cases hp : p.2 ≤ 1 / 3
  · have hq := hb.mp hp
    rw [ite_eq_left hp, ite_eq_left hq]
    constructor
    · rw [show p.1 / 3 - q.1 / 3 = (p.1 - q.1) / 3 by ring, abs_div]; norm_num
    · rw [show 3 * p.2 - 3 * q.2 = 3 * (p.2 - q.2) by ring, abs_mul]; norm_num
  · have hq : ¬ q.2 ≤ 1 / 3 := fun h => hp (hb.mpr h)
    rw [ite_eq_right hp, ite_eq_right hq]
    constructor
    · rw [show 1 - p.1 / 3 - (1 - q.1 / 3) = -((p.1 - q.1) / 3) by ring, abs_neg, abs_div]
      norm_num
    · rw [show 3 - 3 * p.2 - (3 - 3 * q.2) = -(3 * (p.2 - q.2)) by ring, abs_neg, abs_mul]
      norm_num

lemma hs_eq_of_abs_le {a b : ℝ} (h : ∀ n : ℕ, |a - b| ≤ (1 / 3) ^ n) : a = b := by
  by_contra hne
  have hpos : 0 < |a - b| := abs_pos.mpr (sub_ne_zero.mpr hne)
  obtain ⟨n, hn⟩ := exists_pow_lt_of_lt_one hpos (by norm_num : (1 / 3 : ℝ) < 1)
  linarith [h n]

lemma hs_code_unique {γ γ' : ℤ → ℝ × ℝ} (hγ : IsSquareOrbit γ) (hγ' : IsSquareOrbit γ')
    (hc : ∀ k, (2 / 3 ≤ (γ k).2 ↔ 2 / 3 ≤ (γ' k).2)) : γ 0 = γ' 0 := by
  have hb : ∀ k, ((γ k).2 ≤ 1 / 3 ↔ (γ' k).2 ≤ 1 / 3) := by
    intro k
    have h1 := hs_branch hγ k
    have h2 := hs_branch hγ' k
    have h3 := hc k
    constructor
    · intro h
      rcases h2 with h2 | h2
      · exact h2
      · have := h3.mpr h2; linarith
    · intro h
      rcases h1 with h1 | h1
      · exact h1
      · have := h3.mp h1; linarith
  have key : ∀ n : ℕ, ∀ k : ℤ,
      |(γ k).1 - (γ' k).1| ≤ (1 / 3) ^ n ∧ |(γ k).2 - (γ' k).2| ≤ (1 / 3) ^ n := by
    intro n
    induction n with
    | zero =>
      intro k
      have ha := (hγ k).1
      have hb' := (hγ' k).1
      simp only [unitSquare, Set.mem_prod, Set.mem_Icc] at ha hb'
      simp only [pow_zero]
      constructor <;> rw [abs_le] <;> constructor <;> linarith
    | succ n ih =>
      intro k
      constructor
      · have hs := (hs_step (hb (k - 1))).1
        have ek := (hγ (k - 1)).2
        have ek' := (hγ' (k - 1)).2
        rw [sub_add_cancel] at ek ek'
        rw [ek, ek'] at hs
        rw [hs, pow_succ]
        have := (ih (k - 1)).1
        linarith
      · have hs := (hs_step (hb k)).2
        rw [(hγ k).2, (hγ' k).2] at hs
        have := (ih (k + 1)).2
        rw [pow_succ]
        linarith
  exact Prod.ext (hs_eq_of_abs_le fun n => (key n 0).1) (hs_eq_of_abs_le fun n => (key n 0).2)

/-- The coded point, as a point of the invariant set. -/
noncomputable def hsPsi (s : ℤ → Fin 2) : horseshoeInvariantSet :=
  ⟨hsPt s, hsOrbit s, hs_orbit_isSquareOrbit s, hs_orbit_zero s⟩

lemma hs_psi_continuous : Continuous hsPsi := by
  apply Continuous.subtype_mk
  unfold hsPt
  refine Continuous.prodMk (hs_continuous_val.comp ?_) (hs_continuous_val.comp ?_)
  · exact continuous_pi fun n => continuous_apply _
  · exact continuous_pi fun n => continuous_apply _

lemma hs_psi_injective : Function.Injective hsPsi := by
  intro s s' h
  have h0 : hsPt s = hsPt s' := congrArg Subtype.val h
  have hk := hs_orbit_unique (hs_orbit_isSquareOrbit s) (hs_orbit_isSquareOrbit s')
    (by rw [hs_orbit_zero, hs_orbit_zero, h0])
  funext k
  have a := hs_orbit_symbol s k
  have b := hs_orbit_symbol s' k
  rw [hk k] at a
  rcases hs_fin_two (s k) with e | e <;> rcases hs_fin_two (s' k) with e' | e'
  · rw [e, e']
  · have h1 := a.2.mp e
    have h2 := b.1.mp e'
    linarith
  · have h1 := a.1.mp e
    have h2 := b.2.mp e'
    linarith
  · rw [e, e']

lemma hs_psi_surjective : Function.Surjective hsPsi := by
  rintro ⟨p, γ, hγ, rfl⟩
  classical
  let s : ℤ → Fin 2 := fun k => if 2 / 3 ≤ (γ k).2 then 1 else 0
  refine ⟨s, Subtype.ext ?_⟩
  show hsPt s = γ 0
  rw [← hs_orbit_zero s]
  apply hs_code_unique (hs_orbit_isSquareOrbit s) hγ
  intro k
  rw [← (hs_orbit_symbol s k).1]
  by_cases h : 2 / 3 ≤ (γ k).2
  · simp [s, h]
  · simp [s, h]

/-- The coding as an equivalence (inverse direction). -/
noncomputable def hsEquiv : (ℤ → Fin 2) ≃ horseshoeInvariantSet :=
  Equiv.ofBijective hsPsi ⟨hs_psi_injective, hs_psi_surjective⟩

/-- The coding homeomorphism. -/
noncomputable def hsHomeo : horseshoeInvariantSet ≃ₜ (ℤ → Fin 2) :=
  (Continuous.homeoOfEquivCompactToT2 (f := hsEquiv) hs_psi_continuous).symm

lemma hs_psi_homeo (p : horseshoeInvariantSet) : hsPsi (hsHomeo p) = p :=
  hsEquiv.apply_symm_apply p

lemma hs_homeo_psi (s : ℤ → Fin 2) : hsHomeo (hsPsi s) = s :=
  hsEquiv.symm_apply_apply s

lemma hs_pt_injective : Function.Injective hsPt := fun _ _ h =>
  hs_psi_injective (Subtype.ext h)

lemma hs_iterate_pt (s : ℤ → Fin 2) (m : ℕ) :
    horseshoe^[m] (hsPt s) = hsPt (fun j => s (j + m)) := by
  induction m with
  | zero => simp
  | succ m ih =>
    rw [Function.iterate_succ_apply', ih, hs_horseshoe_pt]
    congr 1
    funext j
    congr 1
    push_cast
    ring

/-- From a 0/2 ternary digit sequence (as bits `b n ∈ {0, 1}`) to the 0/1 code. -/
def hsFromBits (b : ℕ → ℕ) : ℕ → Fin 2
  | 0 => ⟨b 0 % 2, Nat.mod_lt _ (by norm_num)⟩
  | n + 1 => ⟨(b (n + 1) + b n) % 2, Nat.mod_lt _ (by norm_num)⟩

lemma hs_fromBits_sum (b : ℕ → ℕ) (hb : ∀ n, b n ≤ 1) (n : ℕ) :
    (∑ j ∈ Finset.range (n + 1), (hsFromBits b j : ℕ)) % 2 = b n := by
  induction n with
  | zero =>
    simp only [zero_add, Finset.range_one, Finset.sum_singleton, hsFromBits]
    have := hb 0
    omega
  | succ n ih =>
    rw [Finset.sum_range_succ]
    have e : (hsFromBits b (n + 1) : ℕ) = (b (n + 1) + b n) % 2 := rfl
    rw [e]
    have := hb n
    have := hb (n + 1)
    omega

lemma hs_val_surj {x : ℝ} (hx : x ∈ cantorSet) : ∃ w : ℕ → Fin 2, hsVal w = x := by
  rw [cantorSet_eq_zero_two_ofDigits] at hx
  obtain ⟨a, ha, rfl⟩ := hx
  refine ⟨hsFromBits (fun n => (a n : ℕ) / 2), ?_⟩
  unfold hsVal
  congr 1
  funext n
  have hs := hs_fromBits_sum (fun n => (a n : ℕ) / 2) (fun n => by have := (a n).2; omega) n
  have h1 : (a n : ℕ) ≠ 1 := fun h => ha n (Fin.ext h)
  have h3 := (a n).2
  unfold hsDigit
  rw [hs]
  split_ifs with h
  · apply Fin.ext; simp only [Fin.val_zero]; omega
  · apply Fin.ext; show 2 = _; omega

lemma hs_invariant_eq_range : horseshoeInvariantSet = Set.range hsPt := by
  ext p
  constructor
  · intro hp
    obtain ⟨s, hs⟩ := hs_psi_surjective ⟨p, hp⟩
    exact ⟨s, congrArg Subtype.val hs⟩
  · rintro ⟨s, rfl⟩
    exact (hsPsi s).2

#print axioms hs_fin_two
#print axioms hs_ofDigits_add
#print axioms hs_val_nonneg
#print axioms hs_val_le_one
#print axioms hs_val_mem_cantor
#print axioms hs_continuous_val
#print axioms hs_val_cons
#print axioms hs_pt_mem
#print axioms hs_pt_snd
#print axioms hs_symbol
#print axioms hs_horseshoe_pt
#print axioms hs_orbit_zero
#print axioms hs_orbit_isSquareOrbit
#print axioms hs_orbit_symbol
#print axioms hs_horseshoe_injOn
#print axioms hs_orbit_unique
#print axioms hs_branch
#print axioms hs_step
#print axioms hs_eq_of_abs_le
#print axioms hs_code_unique
#print axioms hs_psi_continuous
#print axioms hs_psi_injective
#print axioms hs_psi_surjective
#print axioms hs_psi_homeo
#print axioms hs_homeo_psi
#print axioms hs_pt_injective
#print axioms hs_iterate_pt
#print axioms hs_fromBits_sum
#print axioms hs_val_surj
#print axioms hs_invariant_eq_range

/-- The card's main theorem. The map sends the invariant set `Λ` into itself, and the code
`h` is a homeomorphism (one-to-one, onto, and continuous both ways) from `Λ` to the two-way
endless 0/1 sequences with the product topology. The code of a point lists, for each round
`k`, the symbol 1 when the point is in the top third after `k` rounds and 0 when it is in the
bottom third; and the code of `f(point)` is the code of the point shifted one place left. -/
theorem horseshoe_coding_conjugates_to_shift :
    Set.MapsTo horseshoe horseshoeInvariantSet horseshoeInvariantSet ∧
    ∃ h : horseshoeInvariantSet ≃ₜ (ℤ → Fin 2),
      (∀ (p : horseshoeInvariantSet) (γ : ℤ → ℝ × ℝ), IsSquareOrbit γ → γ 0 = p →
        ∀ k : ℤ, (h p k = 1 ↔ 2 / 3 ≤ (γ k).2) ∧ (h p k = 0 ↔ (γ k).2 ≤ 1 / 3)) ∧
      ∀ (p : horseshoeInvariantSet) (hfp : horseshoe p ∈ horseshoeInvariantSet),
        h ⟨horseshoe p, hfp⟩ = SymbolicDynamics.FullShift.shift 1 (h p) := by
  refine ⟨?_, hsHomeo, ?_, ?_⟩
  · rintro p ⟨γ, hγ, rfl⟩
    exact ⟨fun k => γ (k + 1), fun k => hγ (k + 1), by simpa using ((hγ 0).2).symm⟩
  · intro p γ hγ hp k
    have hpt : hsPt (hsHomeo p) = (p : ℝ × ℝ) := congrArg Subtype.val (hs_psi_homeo p)
    have hk := hs_orbit_unique (hs_orbit_isSquareOrbit (hsHomeo p)) hγ
      (by rw [hs_orbit_zero, hpt, hp]) k
    have := hs_orbit_symbol (hsHomeo p) k
    rw [hk] at this
    exact this
  · intro p hfp
    have hpt : hsPt (hsHomeo p) = (p : ℝ × ℝ) := congrArg Subtype.val (hs_psi_homeo p)
    have e : (⟨horseshoe p, hfp⟩ : horseshoeInvariantSet) =
        hsPsi (SymbolicDynamics.FullShift.shift 1 (hsHomeo p)) := by
      apply Subtype.ext
      show horseshoe p = hsPt _
      rw [← hpt, hs_horseshoe_pt]
      congr 1
      funext j
      simp [SymbolicDynamics.FullShift.shift_apply, add_comm]
    rw [e, hs_homeo_psi]

/-- The points that stay forever are the middle-thirds Cantor set across times the
middle-thirds Cantor set up: `Λ = C × C`. -/
theorem horseshoe_invariant_set_eq_cantor_prod :
    horseshoeInvariantSet = cantorSet ×ˢ cantorSet := by
  rw [hs_invariant_eq_range]
  ext ⟨x, y⟩
  constructor
  · rintro ⟨s, hs⟩
    rw [← hs]
    exact ⟨hs_val_mem_cantor _, hs_val_mem_cantor _⟩
  · rintro ⟨hx, hy⟩
    obtain ⟨wx, rfl⟩ := hs_val_surj hx
    obtain ⟨wy, rfl⟩ := hs_val_surj hy
    classical
    refine ⟨fun k => if 0 ≤ k then wy k.toNat else wx (-k - 1).toNat, ?_⟩
    have e1 : hsFwd (fun k => if 0 ≤ k then wy k.toNat else wx (-k - 1).toNat) = wy := by
      funext n
      simp [hsFwd]
    have e2 : hsBwd (fun k => if 0 ≤ k then wy k.toNat else wx (-k - 1).toNat) = wx := by
      funext n
      simp only [hsBwd]
      rw [ite_eq_right (by omega)]
      congr 1
      omega
    simp only [hsPt, e1, e2]

/-- For every `n ≥ 1`, exactly `2^n` points of `Λ` come back to themselves after `n` rounds
(`f^n(point) = point`). -/
theorem horseshoe_periodic_points_ncard (n : ℕ) (hn : 1 ≤ n) :
    {p ∈ horseshoeInvariantSet | Function.IsPeriodicPt horseshoe n p}.ncard = 2 ^ n := by
  have hn0 : (0 : ℤ) < n := by exact_mod_cast hn
  let P : Set (ℤ → Fin 2) := {s | ∀ j, s (j + n) = s j}
  have hS : {p ∈ horseshoeInvariantSet | Function.IsPeriodicPt horseshoe n p} = hsPt '' P := by
    ext p
    constructor
    · rintro ⟨hp, hper⟩
      obtain ⟨s, hs⟩ := hs_psi_surjective ⟨p, hp⟩
      have hps : hsPt s = p := congrArg Subtype.val hs
      refine ⟨s, ?_, hps⟩
      have h1 : horseshoe^[n] (hsPt s) = hsPt s := by rw [hps]; exact hper
      rw [hs_iterate_pt] at h1
      intro j
      exact congrFun (hs_pt_injective h1) j
    · rintro ⟨s, hs, rfl⟩
      refine ⟨(hsPsi s).2, ?_⟩
      show horseshoe^[n] (hsPt s) = hsPt s
      rw [hs_iterate_pt]
      congr 1
      funext j
      exact hs j
  rw [hS, Set.ncard_image_of_injective P hs_pt_injective, ← Nat.card_coe_set_eq]
  have e : P ≃ (Fin n → Fin 2) :=
    { toFun := fun s i => s.1 i
      invFun := fun r => ⟨fun j => r ⟨(j % n).toNat, by
          have h1 := Int.emod_nonneg j hn0.ne'
          have h2 := Int.emod_lt_of_pos j hn0
          omega⟩, fun j => by simp [Int.add_emod_right]⟩
      left_inv := fun s => by
        apply Subtype.ext
        funext j
        have hper : Function.Periodic s.1 (n : ℤ) := s.2
        have h1 := Int.emod_nonneg j hn0.ne'
        simp only
        rw [Int.toNat_of_nonneg h1]
        rw [show j % (n : ℤ) = j - (j / n) * n by rw [Int.emod_def]; ring]
        exact hper.sub_int_mul_eq (j / n)
      right_inv := fun r => by
        funext i
        simp only
        congr 1
        apply Fin.ext
        simp only
        rw [Int.emod_eq_of_lt (by positivity) (by exact_mod_cast i.2)]
        simp }
  rw [Nat.card_congr e]
  simp

-- The fixed point in the bottom third is (0, 0); the one in the top third is (3/4, 3/4).
example : horseshoe (0, 0) = (0, 0) := by norm_num [horseshoe]
example : horseshoe (3 / 4, 3 / 4) = (3 / 4, 3 / 4) := by norm_num [horseshoe]

-- The 2-cycle: f(9/10, 3/10) = (3/10, 9/10) and back, so (9/10, 3/10) returns after 2 rounds.
example : horseshoe (9 / 10, 3 / 10) = (3 / 10, 9 / 10) := by norm_num [horseshoe]
example : horseshoe (3 / 10, 9 / 10) = (9 / 10, 3 / 10) := by norm_num [horseshoe]
example : Function.IsPeriodicPt horseshoe 2 (9 / 10, 3 / 10) := by
  norm_num [Function.IsPeriodicPt, Function.IsFixedPt, horseshoe]

-- Points back after n rounds, n = 1..5: 2, 4, 8, 16, 32; of exact period n: 2, 2, 6, 12, 30.
example : [2 ^ 1, 2 ^ 2, 2 ^ 3, 2 ^ 4, 2 ^ 5] = [2, 4, 8, 16, 32] := by decide
example : [2 ^ 1, 2 ^ 2 - 2 ^ 1, 2 ^ 3 - 2 ^ 1, 2 ^ 4 - 2 ^ 2, 2 ^ 5 - 2 ^ 1]
    = [2, 2, 6, 12, 30] := by decide

-- The usual mistake: at period 4, 12 points of exact period 4 make 3 cycles, but 16 points
-- come back after 4 rounds.
example : (2 ^ 4 - 2 ^ 2) / 4 = 3 ∧ 2 ^ 4 = 16 := by decide

-- Strips kept for 5 rounds: 32 strips of height 1/243, total height (2/3)^5 = 32/243.
example : (2 : ℚ) ^ 5 * (1 / 3 ^ 5) = 32 / 243 ∧ ((2 : ℚ) / 3) ^ 5 = 32 / 243 := by norm_num

-- Box count: the 1024 points of period 10 in squares of side 1/243 give log 1024 / log 243,
-- which is log 4 / log 3 since 1024 = 4^5 and 243 = 3^5.
example : (2 : ℕ) ^ 10 = 4 ^ 5 ∧ (243 : ℕ) = 3 ^ 5 := by decide

-- The word 0000100110101111, read round the end, holds all 16 blocks of 4 symbols.
example :
    let w : List ℕ := [0, 0, 0, 0, 1, 0, 0, 1, 1, 0, 1, 0, 1, 1, 1, 1]
    ((List.range 16).map (fun i => (List.range 4).map (fun j => w.getD ((i + j) % 16) 0))).dedup.length
      = 16 := by decide

#print axioms horseshoe_coding_conjugates_to_shift
#print axioms horseshoe_invariant_set_eq_cantor_prod
#print axioms horseshoe_periodic_points_ncard
