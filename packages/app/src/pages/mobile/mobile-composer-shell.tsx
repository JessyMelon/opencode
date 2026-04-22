import { Show, type JSX } from "solid-js"
import { useMobileViewport } from "@/pages/mobile/use-mobile-viewport"

export function MobileComposerShell(props: { enabled: boolean; children: JSX.Element }) {
  const viewport = useMobileViewport()

  return (
    <Show when={props.enabled} fallback={props.children}>
      <div
        data-component="mobile-composer-shell"
        style={{
          "padding-bottom": `calc(max(env(safe-area-inset-bottom), 0px) + ${viewport.keyboardInset()}px)`,
        }}
      >
        {props.children}
      </div>
    </Show>
  )
}
