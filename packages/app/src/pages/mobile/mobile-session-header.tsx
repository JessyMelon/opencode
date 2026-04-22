import { Button } from "@opencode-ai/ui/button"

export function MobileSessionHeader(props: {
  title: string
  changesLabel: string
  onOpenChanges: () => void
}) {
  return (
    <div data-component="mobile-session-header" class="flex h-11 shrink-0 items-center justify-between border-b border-border-weak-base px-3 md:hidden">
      <div class="min-w-0 text-13-medium text-text-strong truncate">{props.title}</div>
      <Button variant="ghost" size="small" onClick={props.onOpenChanges}>
        {props.changesLabel}
      </Button>
    </div>
  )
}
