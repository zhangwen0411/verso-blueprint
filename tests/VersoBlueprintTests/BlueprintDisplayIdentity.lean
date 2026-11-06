import VersoBlueprintTests.Blueprint.Support

namespace Verso.VersoBlueprintTests.BlueprintDisplayIdentity

open Lean Verso Doc Elab
open Verso.Genre.Manual
open Informal
open Verso.VersoBlueprintTests.Blueprint.Support

/-- Fixture command exercising the public API from a node body. -/
@[block_command]
def readerName : BlockCommandOf Unit
  | () => do
    Environment.setDisplayIdentity "Definition 3.1 · Reader identity"
    ``(Verso.Doc.Block.concat #[])

/-- A second identity for relation and reference coverage. -/
@[block_command]
def readerLemma : BlockCommandOf Unit
  | () => do
    Environment.setDisplayIdentity "Lemma 6.4"
    ``(Verso.Doc.Block.concat #[])

/-- An invalid empty identity, for the elaboration diagnostic check. -/
@[block_command]
def emptyIdentity : BlockCommandOf Unit
  | () => do
    Environment.setDisplayIdentity "   "
    ``(Verso.Doc.Block.concat #[])

set_option doc.verso true

#docs (Genre.Manual) identityDoc "Display identities" :=
:::::::
:::definition "identity.base" (lean := "Nat.add")
{readerName}
Base statement.
:::

:::lemma_ "identity.next" (lean := "Nat.add_comm")
{readerLemma}
Depends on {uses "identity.base"}[] and {uses "identity.ordinary"}[].
:::

:::definition "identity.ordinary"
Ordinary statement using {uses "identity.base"}[].
:::

:::proof "identity.next"
A proof for the same reader identity.
:::

{blueprint_graph}

{blueprint_summary}
:::::::

private def impls : ExtensionImpls := extension_impls%

/-- info: true -/
#guard_msgs in
#eval show IO Bool from do
  let (html, state) ← renderManualDocHtmlStringAndState impls identityDoc
  let files ← buildManualPreviewDataFiles impls identityDoc
  let some base := files.manifest.findPrimaryBlockEntry? "identity.base" | return false
  let some next := files.manifest.findPrimaryBlockEntry? "identity.next" | return false
  let some ordinary := files.manifest.findPrimaryBlockEntry? "identity.ordinary" | return false
  let identity := "Definition 3.1 · Reader identity"
  let some graph := files.manifest.graphs[0]? | return false
  let some node := graph.nodes.find? (·.label == Name.mkSimple "identity.base") | return false
  pure <| base.title == identity && base.displayCaption == some identity &&
    base.displayLabel == some "" && base.displayIdentity == some identity &&
    (next.uses.any (fun entry => entry.title == identity)) &&
    (base.usedBy.any (fun entry => entry.title == "Lemma 6.4")) &&
    ordinary.displayIdentity.isNone && ordinary.displayCaption == some "Definition" &&
    ordinary.displayLabel == some "3" && ordinary.title == "Definition 3" &&
    node.title == identity && node.displayLabel == identity &&
    graph.variants.all (fun variant => hasSubstr variant.dot s!"label=\"{identity}\"") &&
    hasSubstr html s!"title=\"{identity}\"" &&
    hasSubstr html s!"Lean code for {identity}" &&
    hasSubstr html s!"aria-label=\"Lean code for {identity}\"" &&
    hasSubstr html s!"Statement dependencies of {identity}" &&
    hasSubstr html s!"Used by {identity}" &&
    hasSubstr html s!"<code>{identity}</code>" &&
    hasSubstr html "Proof for Lemma 6.4" &&
    hasSubstr html "bp_heading_title_row_identity" &&
    !hasSubstr html "bp_code_summary_label" &&
    hasExtraCss state ".bp_heading_title_row_identity"

/-- info: true -/
#guard_msgs in
#eval
  let data : BlockData := {
    label := Name.mkSimple "identity.shell"
    kind := .definition
    displayIdentity := some "Definition 3.1 · Reader identity"
    count := 1 }
  let context := InformalBlockRenderContext.forBlock data "1"
  let identityHtml := (renderInformalBlockHtml data context #[]).asString
  let ordinaryHtml := (renderInformalBlockHtml { data with displayIdentity := none } context #[]).asString
  let display : NodeDisplay := {
    label := data.label
    kind := .definition
    number? := some "1"
    identity? := data.displayIdentity }
  !hasSubstr identityHtml "bp_label" && hasSubstr ordinaryHtml "bp_label" &&
    (codePanelHeader display).number?.isNone

/-- error: display identity outside an informal environment -/
#guard_msgs in
#docs (Genre.Manual) outsideDoc "Outside" :=
:::::::
{readerName}
:::::::

/-- error: display identity must be nonempty -/
#guard_msgs in
#docs (Genre.Manual) emptyDoc "Empty" :=
:::::::
:::definition "identity.empty"
{emptyIdentity}
:::
:::::::

/-- error: display identity already set for «identity.twice» -/
#guard_msgs in
#docs (Genre.Manual) duplicateDoc "Duplicate" :=
:::::::
:::definition "identity.twice"
{readerName}
{readerName}
:::
:::::::

/-- error: display identity already set for «identity.base» -/
#guard_msgs in
#docs (Genre.Manual) repeatedDoc "Repeated" :=
:::::::
:::proof "identity.base"
{readerName}
:::
:::::::

end Verso.VersoBlueprintTests.BlueprintDisplayIdentity
