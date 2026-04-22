import { IconButton } from "@opencode-ai/ui/icon-button"
import { Show, type JSX } from "solid-js"
import { useMobileViewport } from "@/pages/mobile/use-mobile-viewport"

export function MobileReviewSheet(props: {
  opened: boolean
  title: string
  closeLabel: string
  onClose: () => void
  children: JSX.Element
}) {
  const viewport = useMobileViewport()

  return (
    <Show when={props.opened}>
      <div
        data-component="mobile-review-sheet"
        class="absolute inset-0 z-30 flex min-h-0 flex-col bg-background-base md:hidden"
        style={{ height: `${viewport.viewportHeight()}px` }}
      >
        <div
          class="flex h-11 shrink-0 items-center gap-1 border-b border-border-weak-base px-2"
          style={{ "padding-top": "max(env(safe-area-inset-top), 0px)" }}
        >
          <IconButton icon="chevron-left" variant="ghost" onClick={props.onClose} aria-label={props.closeLabel} />
          <div class="min-w-0 text-13-medium text-text-strong truncate">{props.title}</div>
        </div>
        <div
          class="flex-1 min-h-0 overflow-hidden"
          style={{ "padding-bottom": `calc(max(env(safe-area-inset-bottom), 0px) + ${viewport.keyboardInset()}px)` }}
        >
          {props.children}
        </div>
      </div>
    </Show>
  )
}
