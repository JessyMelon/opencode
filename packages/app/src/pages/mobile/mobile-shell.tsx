import { Show, type JSX } from "solid-js"

export function MobileShell(props: {
  enabled: boolean
  header?: JSX.Element
  footer?: JSX.Element
  children: JSX.Element
}) {
  return (
    <Show when={props.enabled} fallback={props.children}>
      <div data-component="mobile-shell" class="flex flex-1 min-h-0 flex-col">
        {props.header}
        <div class="flex-1 min-h-0">{props.children}</div>
        {props.footer}
      </div>
    </Show>
  )
}
