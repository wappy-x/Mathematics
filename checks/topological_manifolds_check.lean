-- Topological manifold: the sphere of radius R in flat (n+1)-space is a topological n-manifold whose two polar maps are charts, their transition map is u ↦ R²u/|u|², and no single chart covers the sphere.
import Mathlib.Analysis.InnerProductSpace.PiL2
import Mathlib.Topology.OpenPartialHomeomorph.Defs
import Mathlib.Topology.MetricSpace.Basic
import Mathlib.Topology.Bases
import Mathlib.Data.Finset.Powerset
import Mathlib

lemma mem_sphere_iff_sum_sq (m : ℕ) (R : ℝ) (hR : 0 < R) (x : EuclideanSpace ℝ (Fin m)) :
    x ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin m)) R ↔ ∑ i, x i ^ 2 = R ^ 2 := by
  rw [mem_sphere_zero_iff_norm, ← EuclideanSpace.real_norm_sq_eq]
  constructor
  · rintro h; rw [h]
  · intro h
    have := norm_nonneg x
    nlinarith [sq_nonneg (‖x‖ - R), sq_nonneg (‖x‖ + R)]

#print axioms mem_sphere_iff_sum_sq

lemma stereo_chart_exists (n : ℕ) (R : ℝ) (hR : 0 < R) (s : ℝ) (hs : s * s = 1) :
    ∃ φ : OpenPartialHomeomorph (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R)
        (EuclideanSpace ℝ (Fin n)),
      φ.source = {p : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R | R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ 0} ∧
      φ.target = Set.univ ∧
      ∀ p ∈ φ.source, ∀ i : Fin n,
        φ p i = R * (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc /
          (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) := by
  have hR0 : R ≠ 0 := hR.ne'
  set S : Set (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R) :=
    {p | R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ 0} with hS
  let F : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R → EuclideanSpace ℝ (Fin n) :=
    fun p => WithLp.toLp 2 (fun i => R * (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc /
      (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)))
  let N : EuclideanSpace ℝ (Fin n) → ℝ := fun u => ∑ i, u i ^ 2
  have hN0 : ∀ u, 0 ≤ N u := fun u => Finset.sum_nonneg (fun i _ => sq_nonneg _)
  have hD : ∀ u, R ^ 2 + N u ≠ 0 := fun u => by have := hN0 u; positivity
  let g : EuclideanSpace ℝ (Fin n) → EuclideanSpace ℝ (Fin (n + 1)) := fun u =>
    WithLp.toLp 2 (Fin.snoc (fun i => 2 * R ^ 2 * u i / (R ^ 2 + N u))
      (s * R * (R ^ 2 - N u) / (R ^ 2 + N u)))
  have hg : ∀ u, g u ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R := by
    intro u
    rw [mem_sphere_iff_sum_sq _ _ hR, Fin.sum_univ_castSucc]
    simp only [g, Fin.snoc_castSucc, Fin.snoc_last]
    have h1 : ∑ i : Fin n, (2 * R ^ 2 * u i / (R ^ 2 + N u)) ^ 2
        = (2 * R ^ 2) ^ 2 * N u / (R ^ 2 + N u) ^ 2 := by
      simp only [N, div_pow, mul_pow, Finset.mul_sum, Finset.sum_div]
    rw [h1]
    have := hD u
    field_simp
    linear_combination (R ^ 2 * (R ^ 2 - N u) ^ 2 - (2*R^2*N u + R^2*N u^2 - R^4 - 2*R^4*N u + R^6 - N u^2)) * hs
  let G : EuclideanSpace ℝ (Fin n) → Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R :=
    fun u => ⟨g u, hg u⟩
  have hlast : ∀ u, R + s * (s * R * (R ^ 2 - N u) / (R ^ 2 + N u)) = 2 * R ^ 3 / (R ^ 2 + N u) := by
    intro u
    have := hD u
    field_simp
    linear_combination (R * (R ^ 2 - N u) - (-R*N u - R^2 + R^3 + N u)) * hs
  have hNF : ∀ p ∈ S, N (F p) = R ^ 2 * (R - s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) /
      (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) := by
    intro p hp
    have hsum := (mem_sphere_iff_sum_sq _ _ hR _).1 p.2
    rw [Fin.sum_univ_castSucc] at hsum
    have hp' : R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ 0 := hp
    have h1 : N (F p) = R ^ 2 * (∑ i : Fin n, (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc ^ 2) /
        (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) ^ 2 := by
      simp only [N, F, div_pow, mul_pow, Finset.mul_sum, Finset.sum_div]
    have hT : ∑ i : Fin n, (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc ^ 2
        = (R - s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) *
          (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) := by
      linear_combination hsum + ((p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) ^ 2 * hs
    rw [h1, hT]
    field_simp
  have hGS : ∀ u, G u ∈ S := by
    intro u
    show R + s * (g u) (Fin.last n) ≠ 0
    simp only [g, Fin.snoc_last]
    rw [hlast u]
    have := hD u
    positivity
  have hleft : ∀ p ∈ S, G (F p) = p := by
    intro p hp
    have hp' : R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ 0 := hp
    have hRm : R - s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) + 
        (R + s * (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n)) ≠ 0 := by
      ring_nf; positivity
    set z := (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) with hz
    have hden : R ^ 2 + R ^ 2 * (R - s * z) / (R + s * z) = 2 * R ^ 3 / (R + s * z) := by
      field_simp; ring
    have hnum : R ^ 2 - R ^ 2 * (R - s * z) / (R + s * z) = 2 * R ^ 2 * s * z / (R + s * z) := by
      field_simp; ring
    apply Subtype.ext
    ext j
    simp only [G, g]
    rw [hNF p hp, hden, hnum]
    refine Fin.lastCases ?_ (fun i => ?_) j
    · simp only [Fin.snoc_last]
      field_simp
      linear_combination z * hs
    · simp only [Fin.snoc_castSucc, F]
      rw [← hz]
      field_simp
  have hright : ∀ u, F (G u) = u := by
    intro u
    ext i
    simp only [F, G, g, Fin.snoc_last, Fin.snoc_castSucc]
    rw [hlast u]
    have := hD u
    field_simp
  let e : PartialEquiv (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R)
      (EuclideanSpace ℝ (Fin n)) :=
    { toFun := F
      invFun := G
      source := S
      target := Set.univ
      map_source' := fun _ _ => Set.mem_univ _
      map_target' := fun u _ => hGS u
      left_inv' := hleft
      right_inv' := fun u _ => hright u }
  have hcoord : ∀ j : Fin (n + 1), Continuous
      (fun p : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R =>
        (p : EuclideanSpace ℝ (Fin (n + 1))) j) :=
    fun j => (continuous_apply j).comp ((PiLp.continuous_ofLp 2 _).comp continuous_subtype_val)
  have hFc : ContinuousOn F S := by
    refine (PiLp.continuous_toLp 2 _).comp_continuousOn ?_
    refine continuousOn_pi.2 fun i => ?_
    refine ContinuousOn.div ?_ ?_ (fun p hp => hp)
    · exact (continuous_const.mul (hcoord _)).continuousOn
    · exact (continuous_const.add (continuous_const.mul (hcoord _))).continuousOn
  have hNc : Continuous N := by
    refine continuous_finsetSum _ fun i _ => ?_
    exact ((continuous_apply i).comp (PiLp.continuous_ofLp 2 _)).pow 2
  have hgc : Continuous g := by
    refine (PiLp.continuous_toLp 2 _).comp (continuous_pi fun j => ?_)
    refine Fin.lastCases ?_ (fun i => ?_) j
    · simp only [Fin.snoc_last]
      exact (continuous_const.mul (continuous_const.sub hNc)).div
        (continuous_const.add hNc) hD
    · simp only [Fin.snoc_castSucc]
      exact (continuous_const.mul ((continuous_apply i).comp (PiLp.continuous_ofLp 2 _))).div
        (continuous_const.add hNc) hD
  have hGc : Continuous G := hgc.subtype_mk hg
  have hSo : IsOpen S :=
    isOpen_ne_fun (continuous_const.add (continuous_const.mul (hcoord _))) continuous_const
  refine ⟨{ toPartialEquiv := e
            continuousOn_toFun := hFc
            continuousOn_invFun := hGc.continuousOn
            open_source := hSo
            open_target := isOpen_univ }, rfl, rfl, fun p _ i => rfl⟩

#print axioms stereo_chart_exists

/-- The sphere is a topological manifold, covered by the two polar maps. Take the sphere of
radius R > 0 about the origin in flat (n+1)-space, with its last coordinate as the height z.
It is Hausdorff and second countable, and it has an atlas of two charts (homeomorphisms from
an open patch onto an open set of flat n-space): the north map, which sends a point to its
first n coordinates times R / (R + z) and covers everything except the South Pole (z = -R),
and the south map, which uses R / (R - z) and covers everything except the North Pole
(z = R). Each one matches its patch with the whole of flat n-space. For the Earth, n = 2. -/
theorem sphere_is_topological_manifold (n : ℕ) (R : ℝ) (hR : 0 < R) :
    T2Space (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R) ∧
    SecondCountableTopology (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R) ∧
    ∃ φ₁ φ₂ : OpenPartialHomeomorph (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R)
        (EuclideanSpace ℝ (Fin n)),
      φ₁.source = {p : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R |
        (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ -R} ∧
      φ₂.source = {p : Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R |
        (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n) ≠ R} ∧
      φ₁.target = Set.univ ∧ φ₂.target = Set.univ ∧
      (∀ p ∈ φ₁.source, ∀ i : Fin n,
        φ₁ p i = R * (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc /
          (R + (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n))) ∧
      (∀ p ∈ φ₂.source, ∀ i : Fin n,
        φ₂ p i = R * (p : EuclideanSpace ℝ (Fin (n + 1))) i.castSucc /
          (R - (p : EuclideanSpace ℝ (Fin (n + 1))) (Fin.last n))) ∧
      φ₁.source ∪ φ₂.source = Set.univ := by
  obtain ⟨φ₁, hs₁, ht₁, hf₁⟩ := stereo_chart_exists n R hR 1 (by norm_num)
  obtain ⟨φ₂, hs₂, ht₂, hf₂⟩ := stereo_chart_exists n R hR (-1) (by norm_num)
  refine ⟨inferInstance, inferInstance, φ₁, φ₂, ?_, ?_, ht₁, ht₂, ?_, ?_, ?_⟩
  · rw [hs₁]; ext p; simp only [Set.mem_ofPred_eq, one_mul, ne_eq]
    constructor <;> intro h h' <;> apply h <;> linarith
  · rw [hs₂]; ext p; simp only [Set.mem_ofPred_eq, ne_eq]
    constructor <;> intro h h' <;> apply h <;> linarith
  · intro p hp i; rw [hf₁ p hp i, one_mul]
  · intro p hp i; rw [hf₂ p hp i]; ring
  · rw [hs₁, hs₂]; ext p
    simp only [Set.mem_union, Set.mem_ofPred_eq, Set.mem_univ, iff_true]
    by_contra h; push Not at h; linarith [h.1, h.2]

/-- The transition map is R² u / |u|². Take a point of the sphere of radius R > 0 in flat
(n+1)-space that is neither pole, so both polar maps see it. If the north map puts it at u,
then the south map puts it at R² u / |u|²: the same direction from the centre, at distance
R² over |u|. -/
theorem polar_transition_map (n : ℕ) (R : ℝ) (hR : 0 < R)
    (p : EuclideanSpace ℝ (Fin (n + 1))) (hp : p ∈ Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R)
    (hN : p (Fin.last n) ≠ R) (hS : p (Fin.last n) ≠ -R) (i : Fin n) :
    R * p i.castSucc / (R - p (Fin.last n)) =
      R ^ 2 * (R * p i.castSucc / (R + p (Fin.last n))) /
        ∑ j : Fin n, (R * p j.castSucc / (R + p (Fin.last n))) ^ 2 := by
  have hR0 : R ≠ 0 := hR.ne'
  have h1 : R - p (Fin.last n) ≠ 0 := sub_ne_zero.mpr (Ne.symm hN)
  have h2 : R + p (Fin.last n) ≠ 0 := fun h => hS (by linarith)
  have hsum := (mem_sphere_iff_sum_sq _ _ hR _).1 hp
  rw [Fin.sum_univ_castSucc] at hsum
  have hT : ∑ j : Fin n, p j.castSucc ^ 2 = (R - p (Fin.last n)) * (R + p (Fin.last n)) := by
    linear_combination hsum
  have hE : ∑ j : Fin n, (R * p j.castSucc / (R + p (Fin.last n))) ^ 2
      = R ^ 2 * (∑ j : Fin n, p j.castSucc ^ 2) / (R + p (Fin.last n)) ^ 2 := by
    simp only [div_pow, mul_pow, Finset.mul_sum, Finset.sum_div]
  rw [hE, hT]
  field_simp

/-- One chart cannot cover the sphere. For dimension n of 1 or more and radius R > 0, no chart
of the sphere onto an open set of flat n-space has the whole sphere as its patch, so every
atlas of the sphere needs at least two charts. -/
theorem sphere_not_covered_by_one_chart (n : ℕ) (hn : 1 ≤ n) (R : ℝ) (hR : 0 < R)
    (φ : OpenPartialHomeomorph (Metric.sphere (0 : EuclideanSpace ℝ (Fin (n + 1))) R)
      (EuclideanSpace ℝ (Fin n))) :
    φ.source ≠ Set.univ := by
  intro h
  obtain ⟨m, rfl⟩ : ∃ m, n = m + 1 := ⟨n - 1, by omega⟩
  have hK : IsCompact (Set.univ : Set (Metric.sphere (0 : EuclideanSpace ℝ (Fin (m + 1 + 1))) R)) :=
    isCompact_iff_isCompact_univ.mp (isCompact_sphere _ _)
  have hT : IsCompact φ.target := by
    rw [← φ.image_source_eq_target, h]
    exact hK.image_of_continuousOn (h ▸ φ.continuousOn)
  obtain ⟨x, hx⟩ := (NormedSpace.sphere_nonempty (E := EuclideanSpace ℝ (Fin (m + 1 + 1)))
    (x := 0) (r := R)).mpr hR.le
  have hne : φ.target.Nonempty := ⟨φ ⟨x, hx⟩, φ.map_source (by rw [h]; trivial)⟩
  have huniv : φ.target = Set.univ := IsClopen.eq_univ ⟨hT.isClosed, φ.open_target⟩ hne
  exact noncompact_univ (EuclideanSpace ℝ (Fin (m + 1))) (huniv ▸ hT)

-- Unit circle, south map u = 1/2: the inverse formula (2u, |u|² - 1)/(|u|² + 1) lifts it to (4/5, -3/5).
example : 2 * (1 / 2 : ℚ) / ((1 / 2) ^ 2 + 1) = 4 / 5 ∧
    ((1 / 2 : ℚ) ^ 2 - 1) / ((1 / 2) ^ 2 + 1) = -3 / 5 := by norm_num
-- (4/5, -3/5) lies on the circle, and the north map sends it to 2 = 1/u.
example : (4 / 5 : ℚ) ^ 2 + (-3 / 5) ^ 2 = 1 := by norm_num
example : (4 / 5 : ℚ) / (1 + (-3 / 5)) = 2 ∧ (2 : ℚ) = 1 / (1 / 2) := by norm_num
-- Unit sphere, south map u = (1/2, 1/2), |u|² = 1/2: it lifts to (2/3, 2/3, -1/3), on the sphere.
example : 2 * (1 / 2 : ℚ) / (1 / 2 + 1) = 2 / 3 ∧ ((1 / 2 : ℚ) - 1) / (1 / 2 + 1) = -1 / 3 ∧
    (2 / 3 : ℚ) ^ 2 + (2 / 3) ^ 2 + (-1 / 3) ^ 2 = 1 := by norm_num
-- The north map sends (2/3, 2/3, -1/3) to (1, 1) = u / |u|².
example : (2 / 3 : ℚ) / (1 + (-1 / 3)) = 1 ∧ (1 / 2 : ℚ) / (1 / 2) = 1 := by norm_num
-- London: the product of its two chart distances is R² = 6371 × 6371 km².
example : (6371 : ℕ) * 6371 = 40589641 := by norm_num
-- The octahedron (North Pole 0, South Pole 5, equator 1, 2, 3, 4): 8 faces, 12 edges, and every
-- edge lies in exactly two faces; the 3 other vertex pairs (opposite corners) lie in none.
example :
    let faces : List (Finset (Fin 6)) :=
      [{0, 1, 2}, {0, 2, 3}, {0, 3, 4}, {0, 4, 1}, {5, 1, 2}, {5, 2, 3}, {5, 3, 4}, {5, 4, 1}]
    let pairs := (Finset.univ : Finset (Fin 6)).powersetCard 2
    faces.length = 8 ∧
      (pairs.filter fun e => (faces.filter fun f => decide (e ⊆ f)).length = 2).card = 12 ∧
      (pairs.filter fun e => (faces.filter fun f => decide (e ⊆ f)).length = 0).card = 3 := by
  decide

#print axioms sphere_is_topological_manifold
#print axioms polar_transition_map
#print axioms sphere_not_covered_by_one_chart
